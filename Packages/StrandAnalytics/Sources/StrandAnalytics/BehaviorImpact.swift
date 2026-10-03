import Foundation

// BehaviorImpact.swift — the Recovery Impact Analysis behind Behavior Insights (WHOOP_UI_SPEC §3.18).
//
// Pure, deterministic, DB-free. For every behaviour a person logs, split the last 90 days into the days
// it was answered YES and the days it was answered NO, and compare Recovery between the two:
//
//   % impact = (mean Recovery on yes-days − mean Recovery on no-days) ÷ mean Recovery on no-days × 100
//
// which is exactly `BehaviorEffect.pctChange`. The statistics are `BehaviorInsights.rankAll`'s, unchanged:
// a behaviour is TESTED only with at least 5 yes-days and 5 no-days that carry a Recovery (WHOOP's rule),
// every test on the page is Benjamini–Hochberg corrected as one family, and a row is significant only when
// its q-value is under `BehaviorInsights.fdrThreshold`. Nothing is tested before the wearer has 10
// Recoveries at all (WHOOP's unlock threshold, calibration article 4/23/2026).
//
// A day with no answer is neither yes nor no (see `BehaviorInsights.effect`), so "never logged" is never
// read as "logged no". The page orders tested rows the way WHOOP does: significant positives (largest
// first), then the non-significant (grey) ones, then significant negatives (the largest harm last).
//
// The same comparison runs over a numeric follow-up's buckets ("1 Drinks", "2-6 Drinks"): each bucket's
// yes-days against all the no-days, the buckets corrected together (`buckets`).

public enum BehaviorImpact {

    /// Days of history the analysis reads, ending today ("over the past 90 days").
    public static let windowDays = 90
    /// Recoveries a wearer needs before any behaviour is tested.
    public static let recoveriesToUnlock = 10
    /// Yes-days and no-days (with a Recovery) each side needs before it is tested.
    public static var minAnswers: Int { BehaviorInsights.minGroupForSignificance }
    /// The outcome label carried on every effect.
    public static let outcome = "Recovery"

    /// One behaviour's answers: the day keys ("yyyy-MM-dd") it was logged yes, and logged no.
    public struct Answers: Equatable, Sendable {
        public var yes: Set<String>
        public var no: Set<String>

        public init(yes: Set<String> = [], no: Set<String> = []) {
            self.yes = yes
            self.no = no
        }

        /// The answers on days inside [from, to] (inclusive; day keys compare chronologically as text).
        public func within(_ from: String, _ to: String) -> Answers {
            Answers(yes: yes.filter { $0 >= from && $0 <= to }, no: no.filter { $0 >= from && $0 <= to })
        }
    }

    /// Why a behaviour is not tested yet.
    public enum Lock: Equatable, Sendable {
        /// The wearer has fewer than `recoveriesToUnlock` Recoveries in all.
        case calibrating
        /// Fewer than `minAnswers` yes or no answers in the window.
        case needsAnswers
        /// Enough answers, but fewer than `minAnswers` of one side fall on a day with a Recovery.
        case needsRecoveryDays
    }

    /// One behaviour on the page.
    public struct Row: Equatable, Sendable {
        public let behavior: String
        /// Answers logged yes / no inside the window (whether or not the day has a Recovery).
        public let yesCount: Int
        public let noCount: Int
        /// The measured effect, for a tested behaviour; nil while locked.
        public let effect: BehaviorEffect?
        /// Why it is locked; nil once tested.
        public let lock: Lock?

        public init(behavior: String, yesCount: Int, noCount: Int, effect: BehaviorEffect?, lock: Lock?) {
            self.behavior = behavior
            self.yesCount = yesCount
            self.noCount = noCount
            self.effect = effect
            self.lock = lock
        }

        /// % impact on Recovery, for a tested behaviour.
        public var impactPercent: Double? { effect?.pctChange }
        /// Significant after the page's false-discovery correction.
        public var isSignificant: Bool { effect?.significant ?? false }
    }

    /// The whole page.
    public struct Analysis: Equatable, Sendable {
        /// Tested behaviours, in display order.
        public let unlocked: [Row]
        /// Behaviours not tested yet, by name.
        public let locked: [Row]
        /// Days with a Recovery in all of history.
        public let recoveries: Int
        /// The window's first and last day keys.
        public let from: String
        public let to: String

        /// True until the wearer has enough Recoveries for anything to be tested.
        public var isCalibrating: Bool { recoveries < BehaviorImpact.recoveriesToUnlock }
    }

    /// Analyse every behaviour in `answers` against Recovery over the `windowDays` ending on `today`.
    ///
    /// - Parameters:
    ///   - answers: per behaviour (its stable key), the days it was logged yes and no. A behaviour with no
    ///     answers at all is still listed (locked), so pass every behaviour the page should show.
    ///   - recoveryByDay: Recovery (0–100) by day key, all of history (the unlock gate counts all of it).
    ///   - today: the window's last day key.
    public static func analyze(answers: [String: Answers],
                               recoveryByDay: [String: Double],
                               today: String,
                               windowDays: Int = windowDays,
                               recoveriesToUnlock: Int = recoveriesToUnlock) -> Analysis {
        let from = PulseDisplay.dayKey(today, offsetBy: -(max(1, windowDays) - 1)) ?? today
        let recoveries = recoveryByDay.values.filter(\.isFinite).count
        let windowRecovery = recoveryByDay.filter { $0.key >= from && $0.key <= today && $0.value.isFinite }
        let windowed = answers.mapValues { $0.within(from, today) }

        var effects: [String: BehaviorEffect] = [:]
        if recoveries >= recoveriesToUnlock {
            let ranked = BehaviorInsights.rankAll(behaviors: windowed.mapValues(\.yes),
                                                  controls: windowed.mapValues(\.no),
                                                  outcomes: [outcome: windowRecovery])[outcome] ?? []
            for effect in ranked where effect.pctChange?.isFinite == true {
                effects[effect.behavior] = effect
            }
        }

        var unlocked: [Row] = []
        var locked: [Row] = []
        for name in windowed.keys.sorted() {
            let a = windowed[name] ?? Answers()
            if let effect = effects[name] {
                unlocked.append(Row(behavior: name, yesCount: a.yes.count, noCount: a.no.count,
                                    effect: effect, lock: nil))
            } else {
                let lock: Lock
                if recoveries < recoveriesToUnlock {
                    lock = .calibrating
                } else if a.yes.count < minAnswers || a.no.count < minAnswers {
                    lock = .needsAnswers
                } else {
                    lock = .needsRecoveryDays
                }
                locked.append(Row(behavior: name, yesCount: a.yes.count, noCount: a.no.count,
                                  effect: nil, lock: lock))
            }
        }
        return Analysis(unlocked: displayOrder(unlocked),
                        locked: locked.sorted { $0.behavior.localizedCaseInsensitiveCompare($1.behavior) == .orderedAscending },
                        recoveries: recoveries, from: from, to: today)
    }

    /// WHOOP's order: significant positives (largest first), then the non-significant rows (highest first),
    /// then significant negatives (the largest harm last); ties by name.
    public static func displayOrder(_ rows: [Row]) -> [Row] {
        func group(_ r: Row) -> Int {
            guard r.isSignificant else { return 1 }
            return (r.impactPercent ?? 0) >= 0 ? 0 : 2
        }
        return rows.sorted { a, b in
            let ga = group(a), gb = group(b)
            if ga != gb { return ga < gb }
            let ia = a.impactPercent ?? 0, ib = b.impactPercent ?? 0
            if ia != ib { return ia > ib }
            return a.behavior < b.behavior
        }
    }

    /// The bar scale for a page: the largest |impact| shown, but never under `floor`, so a lone small
    /// effect does not fill the track.
    public static func barScale(_ impacts: [Double], floor: Double = 10) -> Double {
        max(floor, impacts.map(abs).filter(\.isFinite).max() ?? 0)
    }

    // MARK: - Buckets of a numeric follow-up

    /// One bucket of a follow-up amount, e.g. [2, 7) drinks.
    public struct Bucket: Equatable, Sendable {
        /// Inclusive lower bound.
        public let lower: Double
        /// Exclusive upper bound; nil for the open-ended last bucket.
        public let upper: Double?
        /// Yes-days in this bucket that carry a Recovery.
        public let days: Int
        /// The bucket against the no-days; nil while either side has fewer than `minAnswers` days.
        public let effect: BehaviorEffect?

        public init(lower: Double, upper: Double?, days: Int, effect: BehaviorEffect?) {
            self.lower = lower
            self.upper = upper
            self.days = days
            self.effect = effect
        }

        public var impactPercent: Double? { effect?.pctChange }
        public var isSignificant: Bool { effect?.significant ?? false }

        /// Whether `value` falls in this bucket.
        public func contains(_ value: Double) -> Bool {
            value >= lower && (upper.map { value < $0 } ?? true)
        }
    }

    /// Split the yes-days by their logged amount into buckets [e0, e1), [e1, e2), …, [eN, ∞) and measure each
    /// against the no-days. A bucket is tested with at least `minAnswers` days on both sides; the tested
    /// buckets are Benjamini–Hochberg corrected together. Amounts below the first edge are left out.
    ///
    /// - Parameters:
    ///   - amounts: the yes-days' amounts, by day key.
    ///   - noDays: the days logged no.
    ///   - recoveryByDay: Recovery by day key (pass the same window the page uses).
    ///   - edges: ascending bucket lower bounds.
    public static func buckets(amounts: [String: Double],
                               noDays: Set<String>,
                               recoveryByDay: [String: Double],
                               edges: [Double]) -> [Bucket] {
        let sortedEdges = Array(Set(edges.filter(\.isFinite))).sorted()
        guard !sortedEdges.isEmpty else { return [] }
        var shells: [(lower: Double, upper: Double?, days: Set<String>)] = []
        for (i, lower) in sortedEdges.enumerated() {
            let upper = i + 1 < sortedEdges.count ? sortedEdges[i + 1] : nil
            let days = Set(amounts.compactMap { day, value -> String? in
                guard value.isFinite, value >= lower, upper.map({ value < $0 }) ?? true else { return nil }
                return day
            })
            shells.append((lower, upper, days))
        }
        // Test the buckets with enough days on both sides, then correct those tests together.
        var tested: [(index: Int, effect: BehaviorEffect)] = []
        for (i, shell) in shells.enumerated() {
            guard let e = BehaviorInsights.effect(behaviorDays: shell.days, controlDays: noDays,
                                                  outcomeByDay: recoveryByDay,
                                                  behavior: bucketName(shell.lower, shell.upper),
                                                  outcome: outcome),
                  BehaviorInsights.meetsGroupRule(e), e.pctChange?.isFinite == true else { continue }
            tested.append((i, e))
        }
        let q = MultipleTesting.benjaminiHochberg(tested.map { $0.effect.pApprox })
        var flagged: [Int: BehaviorEffect] = [:]
        for (k, t) in tested.enumerated() { flagged[t.index] = t.effect.withFalseDiscoveryRate(q: q[k]) }
        return shells.enumerated().map { i, shell in
            Bucket(lower: shell.lower, upper: shell.upper,
                   days: shell.days.filter { recoveryByDay[$0]?.isFinite == true }.count,
                   effect: flagged[i])
        }
    }

    /// Two buckets split at the median amount, for a custom numeric behaviour with no predefined bins:
    /// [smallest, median) and [median, ∞). Empty with fewer than two distinct amounts.
    public static func medianEdges(_ values: [Double]) -> [Double] {
        let v = values.filter(\.isFinite).sorted()
        guard let lo = v.first, let hi = v.last, lo < hi else { return [] }
        let mid = v.count / 2
        let median = v.count % 2 == 1 ? v[mid] : (v[mid - 1] + v[mid]) / 2
        return median > lo ? [lo, median] : [lo, hi]
    }

    private static func bucketName(_ lower: Double, _ upper: Double?) -> String {
        upper.map { "\(lower)..<\($0)" } ?? "\(lower)+"
    }
}

// MARK: - Logging history (§2.7 "Logging History calendar")

/// A behaviour's answers laid out by calendar month: one mark per day (yes, no, missing, or still to come),
/// on a Sunday-first grid. Day keys are calendar days; the arithmetic runs at UTC on a Gregorian calendar,
/// so a month never shifts by a day west of UTC.
public enum BehaviorLoggingHistory {

    public enum Mark: Equatable, Sendable {
        case yes, no, missing
        /// After today: drawn faintly, never counted as missing.
        case future
    }

    public struct Month: Equatable, Sendable {
        public let year: Int
        public let month: Int
        /// Blank cells before the 1st on a Sunday-first week (0 = the 1st is a Sunday).
        public let leadingBlanks: Int
        /// One mark per day of the month, the 1st first.
        public let marks: [Mark]

        public var yesCount: Int { marks.filter { $0 == .yes }.count }
        public var noCount: Int { marks.filter { $0 == .no }.count }
        public var missingCount: Int { marks.filter { $0 == .missing }.count }
    }

    /// The month's marks. A day answered both ways counts as yes (callers merge sources first).
    public static func month(year: Int, month: Int, yes: Set<String>, no: Set<String>, today: String) -> Month {
        let count = daysIn(year: year, month: month)
        let marks: [Mark] = (1...max(1, count)).map { day in
            let key = String(format: "%04d-%02d-%02d", year, month, day)
            if key > today { return .future }
            if yes.contains(key) { return .yes }
            if no.contains(key) { return .no }
            return .missing
        }
        return Month(year: year, month: month, leadingBlanks: weekdayOfFirst(year: year, month: month),
                     marks: count > 0 ? marks : [])
    }

    /// `count` consecutive (year, month) pairs ending with the month of `dayKey`, oldest first, shifted
    /// back `pagesBack` × `count` months.
    public static func months(endingAt dayKey: String, count: Int, pagesBack: Int = 0) -> [(year: Int, month: Int)] {
        let parts = dayKey.split(separator: "-")
        guard parts.count == 3, let y = Int(parts[0]), let m = Int(parts[1]), count > 0 else { return [] }
        let lastIndex = y * 12 + (m - 1) - pagesBack * count
        return (0..<count).reversed().map { back in
            let index = lastIndex - back
            return (year: index / 12, month: index % 12 + 1)
        }
    }

    /// Days in a Gregorian month.
    public static func daysIn(year: Int, month: Int) -> Int {
        guard (1...12).contains(month) else { return 0 }
        switch month {
        case 2:
            let leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
            return leap ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    /// 0 = Sunday … 6 = Saturday for the 1st of the month (Zeller's congruence, Gregorian).
    public static func weekdayOfFirst(year: Int, month: Int) -> Int {
        var y = year
        var m = month
        if m < 3 { m += 12; y -= 1 }
        let k = y % 100, j = y / 100
        let h = (1 + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 + 5 * j) % 7   // 0 = Saturday
        return (h + 6) % 7
    }
}
