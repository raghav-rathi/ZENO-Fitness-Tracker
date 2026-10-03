import Foundation

// MenstrualCycleModel.swift — the LOGGED-period side of Menstrual Cycle Insights. Pure, deterministic,
// DB-free, UTC "yyyy-MM-dd" day keys throughout.
//
// From the period starts and per-day flow the user logged on this device it derives: the cycles between
// starts, the user's own typical cycle and period length (mean, sample SD, range), today's cycle day and
// phase, a next-period WINDOW, and a per-day phase calendar for any span (past cycles from what was logged,
// the current cycle and the next few from the typical lengths, marked as predictions).
//
// Phases inside a cycle use the standard physiological layout: the bleed (menstrual), then follicular, a
// short ovulatory span ending `lutealLength` days before the next period, then luteal. The ovulatory span is
// an ESTIMATE from cycle length alone, as every surface that shows it says. Until a second period is logged
// the cycle length falls back to the skin-temperature engine's estimate when it has one, then to a textbook
// 28 days; `PredictionBasis` names which, so the screen can say so.
//
// WELLNESS / AWARENESS ONLY. Not contraception, not a fertility or ovulation predictor, not a diagnosis.
// It never emits a single confident period date: the next period is always a window.
public enum MenstrualCycleModel {

    // MARK: - Constants (pinned by tests)

    /// Cycle length assumed until the user's own cycles or the temperature engine say otherwise. The same
    /// textbook prior `CyclePhaseEngine.defaultCycleDays` uses, not a claim about this user.
    public static let defaultCycleLength = CyclePhaseEngine.defaultCycleDays
    /// Bleed length assumed until a period's flow has been logged.
    public static let defaultPeriodLength = 5
    /// Days from the estimated ovulation to the next period (the luteal phase is the stable part).
    public static let lutealLength = 14
    /// The ovulatory span: the estimated ovulation day and the day before it.
    public static let ovulatoryDays = 2
    /// Completed cycles outside this range (a missed or a doubled log) stay in the history but are left
    /// out of the typical lengths and the prediction.
    public static let plausibleCycleLengths = 15...60
    /// How many of the most recent plausible cycles the typical lengths average.
    public static let recentCyclesForStats = 6
    /// No phase is predicted once the latest logged start is at least this many days old.
    public static let staleAfterDays = 90
    /// A gap of up to this many days between two flow days keeps them in one period.
    public static let periodRunGapTolerance = 1
    /// The longest run of flow days counted as one period.
    public static let periodRunMaxDays = 10
    /// Predicted cycles drawn after the current one.
    public static let predictionHorizonCycles = 3

    // MARK: - Types

    public enum Phase: String, CaseIterable, Sendable, Codable {
        case menstrual, follicular, ovulatory, luteal
    }

    /// A day's logged flow. "No flow" is a real answer (it ends a period), unlike a day with nothing logged.
    public enum Flow: Int, CaseIterable, Sendable, Codable, Comparable {
        case noFlow = 0
        case spotting = 1
        case light = 2
        case medium = 3
        case heavy = 4

        public static func < (lhs: Flow, rhs: Flow) -> Bool { lhs.rawValue < rhs.rawValue }

        /// Light flow or heavier is a period day; spotting and "no flow" are not.
        public var isPeriod: Bool { self >= .light }
    }

    /// One cycle: a logged start and, once the next start is logged, its length.
    public struct Cycle: Equatable, Sendable {
        public let start: String
        /// Days to the next logged start; nil for the open (current) cycle.
        public let length: Int?
        /// The logged bleed from `start` (flow light or heavier, gaps of at most a day); nil when no flow
        /// was logged for it.
        public let periodLength: Int?

        public init(start: String, length: Int?, periodLength: Int?) {
            self.start = start
            self.length = length
            self.periodLength = periodLength
        }

        /// A completed cycle whose length is plausible enough to average.
        public var isPlausible: Bool { length.map { plausibleCycleLengths.contains($0) } ?? false }
    }

    /// What the cycle length behind a prediction comes from.
    public enum PredictionBasis: Equatable, Sendable {
        /// The user's own completed cycles (how many).
        case personal(cycles: Int)
        /// The skin-temperature engine's estimate.
        case temperature
        /// A textbook 28-day cycle, until a second period is logged.
        case typical
    }

    /// The user's typical cycle, from their own logs only (nil until there is enough to say).
    public struct Typical: Equatable, Sendable {
        /// Mean of the recent plausible cycles, rounded.
        public let cycleLength: Int?
        /// Sample standard deviation of those cycles (two or more).
        public let cycleSD: Double?
        /// Longest minus shortest of those cycles (two or more).
        public let cycleVariation: Int?
        /// Mean logged bleed length, rounded.
        public let periodLength: Int?
        /// How many cycles `cycleLength` averages.
        public let cyclesUsed: Int

        public init(cycleLength: Int?, cycleSD: Double?, cycleVariation: Int?, periodLength: Int?, cyclesUsed: Int) {
            self.cycleLength = cycleLength
            self.cycleSD = cycleSD
            self.cycleVariation = cycleVariation
            self.periodLength = periodLength
            self.cyclesUsed = cyclesUsed
        }
    }

    /// An inclusive span of day keys.
    public struct Window: Equatable, Sendable {
        public let earliest: String
        public let latest: String

        public init(earliest: String, latest: String) {
            self.earliest = earliest
            self.latest = latest
        }
    }

    public enum Status: Equatable, Sendable {
        /// No period start logged yet.
        case noLogs
        /// The latest logged start is too old to predict from.
        case stale(lastStart: String)
        /// A current cycle is running from the latest logged start.
        case active
    }

    /// Everything the screen states about the cycle today, from one pass over the logs.
    public struct Summary: Equatable, Sendable {
        public let status: Status
        /// Oldest → newest. While `active`, the last one is the open current cycle.
        public let cycles: [Cycle]
        public let typical: Typical
        /// Today's cycle day (active only).
        public let cycleDay: Int?
        /// Today's phase (active and phases apply only).
        public let phase: Phase?
        /// Today falls in the current period, logged or still expected.
        public let isPeriodDay: Bool
        /// The next period's start window (active only).
        public let nextPeriod: Window?
        public let basis: PredictionBasis?
        /// Days today is past the window's latest day, when the period is late.
        public let daysLate: Int?
        /// The cycle and bleed lengths the current cycle's phases are laid out with.
        public let modelCycleLength: Int
        public let modelPeriodLength: Int
    }

    /// One calendar day.
    public struct DayInfo: Equatable, Sendable {
        public let day: String
        /// The day's phase, or nil before the first logged start, after the prediction horizon, or where
        /// phases do not apply.
        public let phase: Phase?
        /// The phase comes from a prediction (a day after today) rather than from what was logged.
        public let isPredicted: Bool
        /// A logged period day: a logged start or flow light or heavier.
        public let isLoggedPeriodDay: Bool
        /// An expected, not yet logged, period day after today.
        public let isPredictedPeriodDay: Bool
        public let flow: Flow?
        /// The day's cycle day, when it falls in a known or predicted cycle.
        public let cycleDay: Int?
    }

    // MARK: - Summary

    /// Summarise the logs as of `today`.
    ///
    /// - Parameters:
    ///   - periodStarts: logged period-start day keys, any order (duplicates ignored).
    ///   - flow: logged flow by day key.
    ///   - today: today's day key.
    ///   - temperatureCycleLength: the skin-temperature engine's cycle length, when it has one.
    ///   - phasesApply: false under hormonal contraception or in menopause, where only bleeding is laid out.
    public static func summarize(periodStarts: [String], flow: [String: Flow], today: String,
                                 temperatureCycleLength: Int? = nil, phasesApply: Bool = true) -> Summary {
        let starts = Array(Set(periodStarts.filter { $0 <= today })).sorted()
        let cycles = buildCycles(starts: starts, flow: flow, today: today)

        guard let last = starts.last else {
            let typical = typicalCycle(cycles)
            return Summary(status: .noLogs, cycles: cycles, typical: typical, cycleDay: nil, phase: nil,
                           isPeriodDay: false, nextPeriod: nil, basis: nil, daysLate: nil,
                           modelCycleLength: typical.cycleLength ?? defaultCycleLength,
                           modelPeriodLength: typical.periodLength ?? defaultPeriodLength)
        }
        let daysSince = days(from: last, to: today) ?? 0
        let cycleDay = daysSince + 1
        if daysSince >= staleAfterDays {
            let typical = typicalCycle(cycles)
            return Summary(status: .stale(lastStart: last), cycles: cycles, typical: typical, cycleDay: nil,
                           phase: nil, isPeriodDay: false, nextPeriod: nil, basis: nil, daysLate: nil,
                           modelCycleLength: typical.cycleLength ?? defaultCycleLength,
                           modelPeriodLength: typical.periodLength ?? defaultPeriodLength)
        }

        // The current bleed counts towards the typical bleed only once it is over.
        let bleed = currentBleed(start: last, flow: flow, today: today)
        let typical = typicalCycle(cycles, currentFinishedBleed: bleed.ended ? bleed.run : nil)
        let (length, basis) = predictionLength(typical: typical, temperatureCycleLength: temperatureCycleLength)
        let spread = predictionSpread(typical: typical, basis: basis)
        let periodLength: Int = {
            if bleed.ended, let run = bleed.run { return run }
            return max(bleed.run ?? 0, typical.periodLength ?? defaultPeriodLength)
        }()

        let window: Window? = {
            guard let earliest = CyclePhaseEngine.shiftDay(last, by: length - spread),
                  let latest = CyclePhaseEngine.shiftDay(last, by: length + spread) else { return nil }
            return Window(earliest: earliest, latest: latest)
        }()
        let late: Int? = window.flatMap { w in
            guard let d = days(from: w.latest, to: today), d > 0 else { return nil }
            return d
        }
        let todayIsPeriod = cycleDay <= periodLength
        let phase: Phase? = phasesApply
            ? phaseFor(cycleDay: cycleDay, cycleLength: length, periodLength: periodLength)
            : (todayIsPeriod ? .menstrual : nil)

        return Summary(status: .active, cycles: cycles, typical: typical, cycleDay: cycleDay, phase: phase,
                       isPeriodDay: todayIsPeriod, nextPeriod: window, basis: basis, daysLate: late,
                       modelCycleLength: length, modelPeriodLength: periodLength)
    }

    /// The cycles between consecutive starts, oldest first; the last one is open.
    static func buildCycles(starts: [String], flow: [String: Flow], today: String) -> [Cycle] {
        var out: [Cycle] = []
        for (i, start) in starts.enumerated() {
            let next = i + 1 < starts.count ? starts[i + 1] : nil
            let length = next.flatMap { days(from: start, to: $0) }
            // A bleed never runs into the next cycle.
            let limit = next.flatMap { CyclePhaseEngine.shiftDay($0, by: -1) } ?? today
            out.append(Cycle(start: start, length: length,
                             periodLength: loggedRun(from: start, flow: flow, through: limit)))
        }
        return out
    }

    /// The logged bleed from `start`: consecutive flow days (light or heavier) with gaps of at most
    /// `periodRunGapTolerance` days, no further than `limit`. A logged "no flow" day ends it. nil when no
    /// period flow is logged in the first `periodRunGapTolerance + 1` days.
    static func loggedRun(from start: String, flow: [String: Flow], through limit: String) -> Int? {
        var lastFlowOffset: Int?
        var offset = 0
        while offset < periodRunMaxDays {
            guard let day = CyclePhaseEngine.shiftDay(start, by: offset), day <= limit else { break }
            if let f = flow[day] {
                if f.isPeriod {
                    lastFlowOffset = offset
                } else if f == .noFlow, lastFlowOffset != nil {
                    break
                }
            }
            let gapSinceFlow = offset - (lastFlowOffset ?? -1)
            if gapSinceFlow > periodRunGapTolerance + 1 { break }
            offset += 1
        }
        return lastFlowOffset.map { $0 + 1 }
    }

    /// Typical lengths from the most recent plausible completed cycles and their logged bleeds (plus the
    /// current bleed once it is over).
    static func typicalCycle(_ cycles: [Cycle], currentFinishedBleed: Int? = nil) -> Typical {
        let completed = cycles.filter { $0.length != nil }
        let lengths = completed.filter(\.isPlausible).compactMap(\.length).suffix(recentCyclesForStats)
        let mean = lengths.isEmpty ? nil : Double(lengths.reduce(0, +)) / Double(lengths.count)
        let sd: Double? = {
            guard lengths.count >= 2, let mean else { return nil }
            let ss = lengths.reduce(0.0) { $0 + pow(Double($1) - mean, 2) }
            return (ss / Double(lengths.count - 1)).squareRoot()
        }()
        let variation: Int? = lengths.count >= 2 ? (lengths.max()! - lengths.min()!) : nil
        var bleeds = completed.compactMap(\.periodLength)
        if let current = currentFinishedBleed { bleeds.append(current) }
        let recentBleeds = bleeds.suffix(recentCyclesForStats)
        let periodMean = recentBleeds.isEmpty ? nil : Double(recentBleeds.reduce(0, +)) / Double(recentBleeds.count)
        return Typical(cycleLength: mean.map { Int($0.rounded()) }, cycleSD: sd, cycleVariation: variation,
                       periodLength: periodMean.map { Int($0.rounded()) }, cyclesUsed: lengths.count)
    }

    /// The cycle length a prediction uses and where it comes from.
    static func predictionLength(typical: Typical, temperatureCycleLength: Int?) -> (Int, PredictionBasis) {
        if let own = typical.cycleLength { return (own, .personal(cycles: typical.cyclesUsed)) }
        if let temp = temperatureCycleLength, plausibleCycleLengths.contains(temp) { return (temp, .temperature) }
        return (defaultCycleLength, .typical)
    }

    /// Half-width of the next-period window: the user's own spread (at least a day) once two cycles are
    /// in, two days with one, three on a prior.
    static func predictionSpread(typical: Typical, basis: PredictionBasis) -> Int {
        switch basis {
        case .personal(let n):
            if n >= 2, let sd = typical.cycleSD { return max(1, Int(sd.rounded())) }
            return 2
        case .temperature, .typical:
            return 3
        }
    }

    /// The current cycle's logged bleed and whether it is over: a "no flow" day logged after it, or more
    /// than `periodRunGapTolerance` days without flow since its last flow day.
    static func currentBleed(start: String, flow: [String: Flow], today: String) -> (run: Int?, ended: Bool) {
        guard let run = loggedRun(from: start, flow: flow, through: today) else { return (nil, false) }
        let lastFlow = CyclePhaseEngine.shiftDay(start, by: run - 1) ?? start
        let daysSinceLastFlow = days(from: lastFlow, to: today) ?? 0
        let endedByNoFlow = (1...periodRunGapTolerance + 1).contains { k in
            CyclePhaseEngine.shiftDay(lastFlow, by: k).map { flow[$0] == .noFlow && $0 <= today } ?? false
        }
        return (run, endedByNoFlow || daysSinceLastFlow > periodRunGapTolerance)
    }

    // MARK: - Phases

    /// The phase of `cycleDay` in a cycle of `cycleLength` days whose bleed lasts `periodLength` days.
    /// Days past the cycle's length (a late period) stay luteal.
    public static func phaseFor(cycleDay: Int, cycleLength: Int, periodLength: Int) -> Phase {
        let spans = phaseSpans(cycleLength: cycleLength, periodLength: periodLength)
        for span in spans where span.days.contains(cycleDay) { return span.phase }
        return cycleDay <= periodLength ? .menstrual : .luteal
    }

    /// The four phases as inclusive cycle-day ranges. Follicular keeps at least one day, so a short cycle
    /// or a long bleed squeezes the ovulatory span later rather than overlapping the bleed.
    public static func phaseSpans(cycleLength: Int, periodLength: Int) -> [(phase: Phase, days: ClosedRange<Int>)] {
        let length = max(cycleLength, periodLength + ovulatoryDays + 2)
        let bleed = max(1, min(periodLength, length - ovulatoryDays - 2))
        let ovulation = max(bleed + ovulatoryDays + 1, length - lutealLength)
        let ovulatoryStart = ovulation - ovulatoryDays + 1
        return [
            (.menstrual, 1...bleed),
            (.follicular, (bleed + 1)...(ovulatoryStart - 1)),
            (.ovulatory, ovulatoryStart...ovulation),
            (.luteal, (ovulation + 1)...length),
        ]
    }

    /// Phase lengths for the phase bar (M, F, O, L), proportional to the current model.
    public static func phaseLengths(cycleLength: Int, periodLength: Int) -> [(phase: Phase, days: Int)] {
        phaseSpans(cycleLength: cycleLength, periodLength: periodLength).map { ($0.phase, $0.days.count) }
    }

    // MARK: - Calendar

    /// Every day from `from` to `to` (inclusive) with its phase, period marks and cycle day.
    public static func calendar(from: String, to: String, summary: Summary, flow: [String: Flow],
                                today: String, phasesApply: Bool = true) -> [DayInfo] {
        guard let span = days(from: from, to: to), span >= 0 else { return [] }
        let starts = Set(summary.cycles.map(\.start))
        let layouts = cycleLayouts(summary: summary, flow: flow, today: today)
        var out: [DayInfo] = []
        out.reserveCapacity(span + 1)
        for offset in 0...span {
            guard let day = CyclePhaseEngine.shiftDay(from, by: offset) else { continue }
            let logged = flow[day]
            let loggedPeriod = starts.contains(day) || (logged?.isPeriod ?? false)
            var phase: Phase?
            var cycleDay: Int?
            var predictedPeriod = false
            if let layout = layouts.last(where: { $0.start <= day }),
               let d = days(from: layout.start, to: day),
               d < layout.length || (layout.isOpenEnded && day <= today) {
                let cd = d + 1
                cycleDay = cd
                let p = phaseFor(cycleDay: cd, cycleLength: layout.length, periodLength: layout.periodLength)
                // Only the bleed is laid out where phases do not apply, or for a cycle too long or too
                // short to be one (a missed or a doubled log).
                phase = phasesApply && layout.phasesKnown ? p : (p == .menstrual ? .menstrual : nil)
                predictedPeriod = day > today && p == .menstrual && !loggedPeriod
            }
            out.append(DayInfo(day: day, phase: phase, isPredicted: day > today,
                               isLoggedPeriodDay: loggedPeriod, isPredictedPeriodDay: predictedPeriod,
                               flow: logged, cycleDay: cycleDay))
        }
        return out
    }

    /// A cycle as the calendar lays it out.
    struct Layout {
        let start: String
        let length: Int
        let periodLength: Int
        /// The current cycle when its period is late: its days up to today run on past `length` (luteal).
        let isOpenEnded: Bool
        /// False for a completed cycle outside `plausibleCycleLengths`: only its bleed is laid out.
        var phasesKnown = true
    }

    /// Completed cycles as logged, the current one and `predictionHorizonCycles` predicted ones.
    static func cycleLayouts(summary: Summary, flow: [String: Flow], today: String) -> [Layout] {
        let fallbackPeriod = summary.typical.periodLength ?? defaultPeriodLength
        var out: [Layout] = []
        for cycle in summary.cycles {
            if let length = cycle.length {
                // A completed cycle: its own length. An implausible one (a missed or a doubled log) lays out
                // only its bleed, never weeks of an invented luteal phase.
                out.append(Layout(start: cycle.start, length: length,
                                  periodLength: cycle.periodLength ?? fallbackPeriod, isOpenEnded: false,
                                  phasesKnown: cycle.isPlausible))
            }
        }
        guard summary.status == .active, let current = summary.cycles.last else { return out }
        let late = summary.daysLate != nil
        out.append(Layout(start: current.start, length: summary.modelCycleLength,
                          periodLength: summary.modelPeriodLength, isOpenEnded: late))
        // Predicted cycles only while the period is not late: a late period has no honest next start.
        guard !late else { return out }
        var start = current.start
        for _ in 0..<predictionHorizonCycles {
            guard let next = CyclePhaseEngine.shiftDay(start, by: summary.modelCycleLength) else { break }
            out.append(Layout(start: next, length: summary.modelCycleLength, periodLength: fallbackPeriod,
                              isOpenEnded: false))
            start = next
        }
        return out
    }

    // MARK: - Day helpers

    /// Calendar days from `a` to `b` (b − a), or nil when either key is malformed. UTC.
    public static func days(from a: String, to b: String) -> Int? {
        CyclePhaseEngine.daysBetween(a, b)
    }

    /// `day` shifted by `delta` days. UTC.
    public static func shift(_ day: String, by delta: Int) -> String? {
        CyclePhaseEngine.shiftDay(day, by: delta)
    }
}
