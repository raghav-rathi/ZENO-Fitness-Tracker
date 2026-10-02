import Foundation

// HomeCoachingRules.swift - which coaching cards the Pulse Home stack shows for a day, and in what order
// (WHOOP_UI_SPEC §3.14 [Z], the on-device stand-in for WHOOP's server notification feed).
//
// Pure, deterministic, DB-free. The caller resolves every input from the readers Home already uses (the
// day's own scored Recovery, the live Strain, the optimal range the Strain dial draws, HRV against the
// recovery engine's folded baseline, per-night Sleep Performance, the sleep-debt series) and this decides
// which cards trigger. It returns kinds and the figures each card prints, never sentences: the copy is
// the app's, localized there.
//
// Recovery is judged on the WHOLE percent a dial prints (`PulseDisplay.displayedPercent`), so a card can
// never call a day red while the dial beside it prints a yellow 34%.
//
// Display-only: nothing here is persisted, fed back into an engine or sent across the .noopbak boundary,
// and only the Pulse iPhone interface shows these cards, so there is no Kotlin twin to keep in step.

public enum HomeCoachingRules {

    // MARK: - Thresholds (pinned by HomeCoachingRulesTests)

    /// A Recovery at or below this displayed percent always counts as the lowest in a while.
    public static let lowestFloor = 5
    /// The window a Recovery must be the lowest of (days before the day itself).
    public static let lowestWindowDays = 90
    /// Scored days the window needs before "lowest in 90 days" means anything.
    public static let lowestMinHistory = 14
    /// A near-perfect day (WHOOP's "99% Club").
    public static let nearPerfect = 99
    /// HRV this many baseline spreads under the personal baseline is a Low HRV card.
    public static let lowHRVZ = -1.0
    /// Sleep Performance under this displayed percent counts towards a rough-sleep streak...
    public static let roughSleepBelow = 70
    /// ...and this many consecutive nights of it, ending last night, make the card.
    public static let roughSleepNights = 3
    /// Sleep debt above this many minutes, and higher than the night before, is "rising".
    public static let sleepDebtRisingMin = 120.0

    // MARK: - Inputs

    /// One day's value, as `yyyy-MM-dd` and a number.
    public struct DayValue: Equatable, Sendable {
        public let day: String
        public let value: Double

        public init(day: String, value: Double) {
            self.day = day
            self.value = value
        }
    }

    /// An alarm armed for the day, checked against when the wearer actually woke. All three are minutes
    /// after local midnight on the day.
    public struct AlarmCheck: Equatable, Sendable {
        /// The strap alarm set for this morning.
        public let alarmMinute: Int
        /// When the night's main sleep ended, if it ended this morning.
        public let wokeMinute: Int?
        /// The time now.
        public let nowMinute: Int

        public init(alarmMinute: Int, wokeMinute: Int?, nowMinute: Int) {
            self.alarmMinute = alarmMinute
            self.wokeMinute = wokeMinute
            self.nowMinute = nowMinute
        }
    }

    /// Recovery's baseline still learning: nights banked so far and the nights it needs.
    public struct Calibration: Equatable, Sendable {
        public let nights: Int
        public let of: Int

        public init(nights: Int, of: Int) {
            self.nights = nights
            self.of = of
        }
    }

    public struct Inputs: Equatable, Sendable {
        /// The day the cards are for (`yyyy-MM-dd`).
        public var dayKey: String
        /// The day's OWN scored Recovery, 0-100. nil when the day has not scored (a value carried from
        /// an earlier night never drives a card about today).
        public var recovery: Double?
        /// Earlier scored Recoveries, oldest first, every day strictly before `dayKey`.
        public var recoveryHistory: [DayValue]
        /// Recovery's baseline is still learning.
        public var calibration: Calibration?
        /// The day's Strain so far, 0-21.
        public var strain: Double?
        /// The optimal Strain range the dial draws, only when Recovery scored for the day itself.
        public var optimalRange: ClosedRange<Double>?
        /// The night's HRV (ms) and the recovery engine's baseline folded from the nights before it.
        public var hrv: Double?
        public var hrvBaseline: BaselineState?
        /// Sleep Performance per wake day (0-100), oldest first, ending on `dayKey` at the latest.
        public var sleepPerformance: [DayValue]
        /// The sleep debt the day carries into tonight and the one the day before carried (minutes).
        public var sleepDebtMin: Double?
        public var previousSleepDebtMin: Double?
        /// The illness heads-up is raised (the engine's own gate; the copy is the app's).
        public var illness: Bool
        /// The strap alarm armed for this morning, if any.
        public var alarm: AlarmCheck?
        /// Monday with a week behind it: the week-in-review card.
        public var weekInReview: Bool
        /// A version of ZENO the wearer has not seen the notes for.
        public var whatsNew: Bool

        public init(dayKey: String, recovery: Double? = nil, recoveryHistory: [DayValue] = [],
                    calibration: Calibration? = nil, strain: Double? = nil,
                    optimalRange: ClosedRange<Double>? = nil, hrv: Double? = nil,
                    hrvBaseline: BaselineState? = nil, sleepPerformance: [DayValue] = [],
                    sleepDebtMin: Double? = nil, previousSleepDebtMin: Double? = nil, illness: Bool = false,
                    alarm: AlarmCheck? = nil, weekInReview: Bool = false, whatsNew: Bool = false) {
            self.dayKey = dayKey
            self.recovery = recovery
            self.recoveryHistory = recoveryHistory
            self.calibration = calibration
            self.strain = strain
            self.optimalRange = optimalRange
            self.hrv = hrv
            self.hrvBaseline = hrvBaseline
            self.sleepPerformance = sleepPerformance
            self.sleepDebtMin = sleepDebtMin
            self.previousSleepDebtMin = previousSleepDebtMin
            self.illness = illness
            self.alarm = alarm
            self.weekInReview = weekInReview
            self.whatsNew = whatsNew
        }
    }

    // MARK: - Cards

    public enum Card: Equatable, Sendable {
        /// The illness heads-up engine raised.
        case illness
        /// The alarm armed for this morning has not rung, but the wearer is already up.
        case alarmWhileAwake(alarmMinute: Int)
        /// Recovery is still calibrating: `nights` of `of` banked.
        case calibrating(nights: Int, of: Int)
        /// The lowest Recovery in a while. `lowestInWindow`: under every scored day of the last 90, and
        /// `sinceDay` is the last day at or below it (nil when none is on record); otherwise the figure
        /// is at or below `lowestFloor` and `sinceDay` is nil.
        case lowestInAWhile(recovery: Int, sinceDay: String?, lowestInWindow: Bool)
        /// Recovery dropped into the red after a day that was not.
        case newlyRed(recovery: Int, previous: Int)
        /// A near-perfect Recovery.
        case nearPerfect(recovery: Int)
        /// HRV well under the personal baseline.
        case lowHRV(hrv: Int, baseline: Int)
        /// Sleep Performance under 70% for `nights` nights running, ending last night.
        case roughSleepStreak(nights: Int)
        /// Strain is past the top of the optimal range.
        case pushingLimits(strain: Double, rangeHigh: Double)
        /// Strain reached the target (the range's midpoint, the dial's tick).
        case strainTargetReached(target: Double)
        /// Strain is inside the optimal range, short of the target.
        case buildingFitness(target: Double)
        /// A green Recovery with Strain still under the range: room for a hard day.
        case optimalHealth(target: Double)
        /// A red Recovery with Strain under the range: keep it under the range's top.
        case recoveringFromStrain(rangeHigh: Double)
        /// Sleep debt over two hours and growing.
        case sleepDebtRising(debtMin: Int)
        /// Monday's look back at the week.
        case weekInReview
        /// Release notes the wearer has not seen.
        case whatsNew

        /// A stable identity for one card on one day (for dismissing it).
        public var id: String {
            switch self {
            case .illness: return "illness"
            case .alarmWhileAwake: return "alarm-awake"
            case .calibrating: return "calibrating"
            case .lowestInAWhile: return "lowest"
            case .newlyRed: return "newly-red"
            case .nearPerfect: return "near-perfect"
            case .lowHRV: return "low-hrv"
            case .roughSleepStreak: return "rough-sleep"
            case .pushingLimits: return "pushing-limits"
            case .strainTargetReached: return "target-reached"
            case .buildingFitness: return "building-fitness"
            case .optimalHealth: return "optimal-health"
            case .recoveringFromStrain: return "recovering"
            case .sleepDebtRising: return "sleep-debt"
            case .weekInReview: return "week-review"
            case .whatsNew: return "whats-new"
            }
        }
    }

    // MARK: - Evaluate

    /// The cards that trigger for the day, most important first. The stack shows the first and peeks the
    /// second; at most one card comes from the Strain-progress family.
    public static func cards(_ inputs: Inputs) -> [Card] {
        var out: [Card] = []
        if inputs.illness { out.append(.illness) }
        if let alarm = alarmWhileAwake(inputs.alarm) { out.append(alarm) }
        if let c = inputs.calibration, c.of > 0, c.nights < c.of {
            out.append(.calibrating(nights: max(0, c.nights), of: c.of))
        }
        if let lowest = lowestInAWhile(inputs) {
            out.append(lowest)
        } else if let red = newlyRed(inputs) {
            out.append(red)
        }
        if let r = inputs.recovery, PulseDisplay.displayedPercent(r) >= nearPerfect {
            out.append(.nearPerfect(recovery: PulseDisplay.displayedPercent(r)))
        }
        if let low = lowHRV(inputs) { out.append(low) }
        if let rough = roughSleepStreak(inputs) { out.append(rough) }
        if let strain = strainProgress(inputs) { out.append(strain) }
        if let debt = sleepDebtRising(inputs) { out.append(debt) }
        if inputs.weekInReview { out.append(.weekInReview) }
        if inputs.whatsNew { out.append(.whatsNew) }
        return out
    }

    /// The lowest Recovery in a while: at or below `lowestFloor`, or under every scored day in the
    /// `lowestWindowDays` before it (with at least `lowestMinHistory` of them to judge by).
    static func lowestInAWhile(_ inputs: Inputs) -> Card? {
        guard let r = inputs.recovery else { return nil }
        let shown = PulseDisplay.displayedPercent(r)
        let prior = inputs.recoveryHistory.filter { $0.day < inputs.dayKey }
        if let cutoff = PulseDisplay.dayKey(inputs.dayKey, offsetBy: -lowestWindowDays) {
            let window = prior.filter { $0.day >= cutoff }
            if window.count >= lowestMinHistory,
               window.allSatisfy({ PulseDisplay.displayedPercent($0.value) > shown }) {
                // The most recent earlier day at or below today's figure: what "since" names.
                let since = prior.last { PulseDisplay.displayedPercent($0.value) <= shown }?.day
                return .lowestInAWhile(recovery: shown, sinceDay: since, lowestInWindow: true)
            }
        }
        guard shown <= lowestFloor else { return nil }
        return .lowestInAWhile(recovery: shown, sinceDay: nil, lowestInWindow: false)
    }

    /// Red today after a scored day that was not red.
    static func newlyRed(_ inputs: Inputs) -> Card? {
        guard let r = inputs.recovery, PulseDisplay.recoveryBand(percent: r) == .red,
              let previous = inputs.recoveryHistory.last(where: { $0.day < inputs.dayKey }),
              PulseDisplay.recoveryBand(percent: previous.value) != .red else { return nil }
        return .newlyRed(recovery: PulseDisplay.displayedPercent(r),
                         previous: PulseDisplay.displayedPercent(previous.value))
    }

    /// HRV more than one baseline spread under a usable personal baseline.
    static func lowHRV(_ inputs: Inputs) -> Card? {
        guard let hrv = inputs.hrv, hrv.isFinite, let baseline = inputs.hrvBaseline, baseline.usable else {
            return nil
        }
        guard Baselines.deviation(hrv, state: baseline).z < lowHRVZ else { return nil }
        return .lowHRV(hrv: Int(hrv.rounded()), baseline: Int(baseline.baseline.rounded()))
    }

    /// Consecutive nights of Sleep Performance under `roughSleepBelow`, ending on the day itself; a night
    /// missing from the run ends it.
    static func roughSleepStreak(_ inputs: Inputs) -> Card? {
        let nights = inputs.sleepPerformance.filter { $0.day <= inputs.dayKey }
        guard let last = nights.last, last.day == inputs.dayKey else { return nil }
        var count = 0
        var expected = inputs.dayKey
        for night in nights.reversed() {
            guard night.day == expected, PulseDisplay.displayedPercent(night.value) < roughSleepBelow else { break }
            count += 1
            guard let previous = PulseDisplay.dayKey(expected, offsetBy: -1) else { break }
            expected = previous
        }
        return count >= roughSleepNights ? .roughSleepStreak(nights: count) : nil
    }

    /// Where the day's Strain sits against the optimal range the dial draws. Only when Recovery scored for
    /// the day itself (the range comes from it); a day with no Strain yet counts as 0.
    static func strainProgress(_ inputs: Inputs) -> Card? {
        guard let recovery = inputs.recovery, let range = inputs.optimalRange,
              range.upperBound > range.lowerBound else { return nil }
        let strain = max(0, inputs.strain ?? 0)
        let target = (range.lowerBound + range.upperBound) / 2
        if strain > range.upperBound { return .pushingLimits(strain: strain, rangeHigh: range.upperBound) }
        if strain >= target { return .strainTargetReached(target: target) }
        if strain >= range.lowerBound { return .buildingFitness(target: target) }
        switch PulseDisplay.recoveryBand(percent: recovery) {
        case .green: return .optimalHealth(target: target)
        case .red: return .recoveringFromStrain(rangeHigh: range.upperBound)
        case .yellow: return nil
        }
    }

    /// Debt over `sleepDebtRisingMin` and above the day before's.
    static func sleepDebtRising(_ inputs: Inputs) -> Card? {
        guard let debt = inputs.sleepDebtMin, debt > sleepDebtRisingMin else { return nil }
        if let previous = inputs.previousSleepDebtMin, debt <= previous { return nil }
        return .sleepDebtRising(debtMin: Int(debt.rounded()))
    }

    /// Up before an alarm that has not rung yet.
    static func alarmWhileAwake(_ alarm: AlarmCheck?) -> Card? {
        guard let alarm, let woke = alarm.wokeMinute, woke < alarm.alarmMinute,
              alarm.nowMinute >= woke, alarm.nowMinute < alarm.alarmMinute else { return nil }
        return .alarmWhileAwake(alarmMinute: alarm.alarmMinute)
    }
}
