import Foundation

/// Where one day's step count came from, declared in the order `StepsResolver` prefers them.
///
/// WHY THIS ORDER. A WHOOP 4.0 has no step counter on the wire, so on that strap every real count is a
/// phone-side one and the strap can only offer a motion estimate. Of the phone-side counts, Apple Health's
/// merged `stepCount` wins because it is the one figure that already combines the iPhone with an Apple Watch
/// (and any other writer) WITHOUT double counting: HealthKit de-duplicates overlapping samples by source
/// priority. The iPhone's own pedometer comes next; it only counts while the phone is carried, but it needs
/// no Health permission and is what a sideloaded build without HealthKit still has. A strap hardware counter
/// (WHOOP 5.0/MG, or an imported activity file's daily total) follows: `docs/PROTOCOL_SENSORS.md` records
/// that neither strap counter is established as equal to the official app's aggregated step count. The
/// motion estimate is last because it is exactly that, an estimate from a per-user calibration.
public enum StepSource: String, CaseIterable, Sendable, Codable {
    /// Apple Health's merged `stepCount`, imported by the Health bridge (or a Health export on macOS).
    case healthKit
    /// The iPhone's motion coprocessor, read directly through CoreMotion's `CMPedometer`.
    case phonePedometer
    /// A hardware counter on the strap (WHOOP 5.0/MG) or an imported activity file's day total.
    case strapCounter
    /// The WHOOP 4.0 motion-volume estimate (`StepsEstimateEngine`), calibrated against phone steps.
    case strapEstimate

    /// Position in the precedence order; lower wins.
    public var rank: Int { StepSource.allCases.firstIndex(of: self) ?? StepSource.allCases.count }

    /// False only for the motion estimate, the one source that never counted a footfall.
    public var isMeasured: Bool { self != .strapEstimate }
}

/// Every candidate count one calendar day has, one slot per `StepSource`. A nil slot means that source has
/// nothing for the day; a negative value is treated as nil (it cannot be a count).
public struct StepDayCandidates: Equatable, Sendable {
    public var healthKit: Int?
    public var phonePedometer: Int?
    public var strapCounter: Int?
    public var strapEstimate: Int?
    /// Steps the band's estimate adds for the hours the phone missed (`StepsHourMerge`). Not a source of its
    /// own: it tops up a day Apple Health or the iPhone counted, and nothing else.
    public var bandFill: Int?

    public init(healthKit: Int? = nil, phonePedometer: Int? = nil,
                strapCounter: Int? = nil, strapEstimate: Int? = nil, bandFill: Int? = nil) {
        self.healthKit = healthKit
        self.phonePedometer = phonePedometer
        self.strapCounter = strapCounter
        self.strapEstimate = strapEstimate
        self.bandFill = bandFill
    }

    /// The (validated) count one source holds for the day.
    public func count(for source: StepSource) -> Int? {
        let raw: Int?
        switch source {
        case .healthKit: raw = healthKit
        case .phonePedometer: raw = phonePedometer
        case .strapCounter: raw = strapCounter
        case .strapEstimate: raw = strapEstimate
        }
        guard let raw, raw >= 0 else { return nil }
        return raw
    }

    /// Set one source's slot.
    public mutating func set(_ value: Int?, for source: StepSource) {
        switch source {
        case .healthKit: healthKit = value
        case .phonePedometer: phonePedometer = value
        case .strapCounter: strapCounter = value
        case .strapEstimate: strapEstimate = value
        }
    }

    /// True when no source holds a usable count.
    public var isEmpty: Bool { StepSource.allCases.allSatisfy { count(for: $0) == nil } }
}

/// The count a day resolved to, and the one source that supplied it.
public struct ResolvedStepDay: Equatable, Sendable {
    public let day: String
    /// The day's total, including `bandSteps`.
    public let steps: Int
    public let source: StepSource
    /// Steps the band added for hours the phone missed, already inside `steps`. 0 on a day the phone covered.
    public let bandSteps: Int

    public init(day: String, steps: Int, source: StepSource, bandSteps: Int = 0) {
        self.day = day
        self.steps = steps
        self.source = source
        self.bandSteps = bandSteps
    }

    /// The source's own count, without the band's additions.
    public var sourceSteps: Int { steps - bandSteps }
}

/// THE step resolver. Every surface that shows a daily step count (Today's tile and card, the Steps screen
/// and card, the rolling average, the combined Explore detail) resolves through here, so two readouts of one
/// day cannot pick different sources.
///
/// Per day: HealthKit > phone pedometer > strap counter > strap estimate, where a source only "has" the day
/// when its count is above zero. A zero is kept as a last resort (a day whose only reading is an explicit
/// zero shows 0, not a blank), but it never beats a positive reading from a lower-ranked source: a phone
/// that recorded nothing all day was almost always left behind, and the strap's reading of that day is the
/// better answer.
///
/// THE BAND FILL. A day Apple Health or the iPhone counted also takes `bandFill`, the steps the band's estimate
/// adds for the hours the phone missed (`StepsHourMerge`). The day keeps its source; `bandSteps` says how much
/// of the total came from the band. A strap counter or a strap-estimate day takes no fill: neither depends on
/// the phone being carried.
///
/// THE IN-PROGRESS DAY is the one exception. HealthKit's figure for today is an import taken at the bridge's
/// last sync, while the pedometer can be read live, so during the day the Health total routinely trails the
/// phone. It cannot legitimately be lower for long: Health's total already CONTAINS the phone's own steps.
/// So for the in-progress day only, a phone count above the Health count wins, and a Health count at or
/// above it (steps the Watch saw while the phone sat on a desk) still wins. Past days keep strict precedence,
/// because the bridge re-reads them in full on every foreground sync.
public enum StepsResolver {

    /// Resolve one day, or nil when no source has a reading.
    public static func resolve(day: String, candidates: StepDayCandidates,
                               isInProgressDay: Bool) -> ResolvedStepDay? {
        guard let base = resolveSource(day: day, candidates: candidates, isInProgressDay: isInProgressDay) else {
            return nil
        }
        return addingBandFill(candidates.bandFill, to: base)
    }

    /// A phone-side day plus the band's additions for the hours the phone missed.
    static func addingBandFill(_ fill: Int?, to base: ResolvedStepDay) -> ResolvedStepDay {
        guard let fill, fill > 0, base.source == .healthKit || base.source == .phonePedometer else { return base }
        return ResolvedStepDay(day: base.day, steps: base.steps + fill, source: base.source, bandSteps: fill)
    }

    /// The precedence rules alone: which source has the day, and its count.
    static func resolveSource(day: String, candidates: StepDayCandidates,
                              isInProgressDay: Bool) -> ResolvedStepDay? {
        if isInProgressDay,
           let phone = candidates.count(for: .phonePedometer), phone > 0,
           let health = candidates.count(for: .healthKit), phone > health {
            return ResolvedStepDay(day: day, steps: phone, source: .phonePedometer)
        }
        for source in StepSource.allCases {
            if let steps = candidates.count(for: source), steps > 0 {
                return ResolvedStepDay(day: day, steps: steps, source: source)
            }
        }
        for source in StepSource.allCases where candidates.count(for: source) == 0 {
            return ResolvedStepDay(day: day, steps: 0, source: source)
        }
        return nil
    }

    /// Resolve a window of days, oldest first. `inProgressDay` is the calendar day still being counted
    /// (the device's local today); every other day resolves with strict precedence.
    public static func resolve(_ candidatesByDay: [String: StepDayCandidates],
                               inProgressDay: String?) -> [ResolvedStepDay] {
        candidatesByDay.keys.sorted().compactMap { day in
            candidatesByDay[day].flatMap {
                resolve(day: day, candidates: $0, isInProgressDay: day == inProgressDay)
            }
        }
    }

    /// Which source an hour-by-hour chart of a day should draw.
    ///
    /// The day's own source when it has hourly rows, so the bars add up to the headline. Otherwise the best
    /// measured source that does have hours (a strap-resolved day can still show the phone's shape), which
    /// the caller must then label, since those bars will not sum to the headline. The strap counter has no
    /// hourly series; the strap estimate's hours are the band's hourly estimate (`StepsHourMerge`), drawn
    /// only for a day the estimate itself resolved.
    public static func hourlySource(daySource: StepSource?, sourcesWithHours: Set<StepSource>) -> StepSource? {
        if let daySource, sourcesWithHours.contains(daySource) { return daySource }
        return StepSource.allCases.first { $0.isMeasured && sourcesWithHours.contains($0) }
    }
}
