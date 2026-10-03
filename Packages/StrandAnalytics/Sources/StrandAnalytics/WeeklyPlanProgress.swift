import Foundation

// WeeklyPlanProgress.swift — the arithmetic behind a Weekly Plan (WHOOP_UI_SPEC §3.19).
//
// Pure, deterministic, DB-free. A plan week runs Monday to Sunday (WHOOP's Friday check-in and Monday
// "My Week Recap" assume that week). Three kinds of goal:
//
//   - count:   "7,000+ Steps 5/7", "Any Strength Training Activity 2/3", "Avoid Late Meal 4/5": how many
//              days of the week met a condition, against a target number of days;
//   - average: "85%+ Sleep Performance, Avg. 82%": the week's mean against a threshold;
//   - total:   "0:45+ HR Zones 4-5 Time": a weekly sum against a target.
//
// Each goal's progress is a fraction capped at 1; the plan's "27% ACCOMPLISHED" is the equal-weight mean of
// those fractions (spec: "Overall % = equal-weight average"). A plan that starts part-way through a week
// is not asked for more days than the week has left (`proratedTarget`, `proratedTotal`).
//
// Day keys are calendar days ("yyyy-MM-dd"); weekday arithmetic runs on the key itself (proleptic
// Gregorian, no time zone), so a week never shifts by a day west of UTC.

public enum WeeklyPlanProgress {

    /// ISO weekday of a day key: 1 = Monday … 7 = Sunday; nil for a malformed key.
    public static func isoWeekday(_ dayKey: String) -> Int? {
        guard let days = daysSinceEpoch(dayKey) else { return nil }
        let sundayZero = ((days + 4) % 7 + 7) % 7   // 1970-01-01 was a Thursday
        return sundayZero == 0 ? 7 : sundayZero
    }

    /// The Monday on or before `dayKey`.
    public static func weekStart(of dayKey: String) -> String? {
        guard let weekday = isoWeekday(dayKey) else { return nil }
        return PulseDisplay.dayKey(dayKey, offsetBy: -(weekday - 1))
    }

    /// The seven day keys of the week beginning `monday`.
    public static func days(ofWeekStarting monday: String) -> [String] {
        (0..<7).compactMap { PulseDisplay.dayKey(monday, offsetBy: $0) }
    }

    /// Days left in `today`'s week, today included: Monday 7 … Sunday 1.
    public static func daysLeft(today: String) -> Int {
        guard let weekday = isoWeekday(today) else { return 0 }
        return 8 - weekday
    }

    /// A goal's standing this week.
    public struct Progress: Equatable, Sendable {
        /// 0...1, capped (an over-achieved goal counts as complete, never more).
        public let fraction: Double
        public let met: Bool

        public init(fraction: Double, met: Bool) {
            self.fraction = fraction.isFinite ? max(0, min(1, fraction)) : 0
            self.met = met
        }
    }

    /// `done` days of `target`.
    public static func count(done: Int, target: Int) -> Progress {
        guard target > 0 else { return Progress(fraction: 1, met: true) }
        return Progress(fraction: Double(done) / Double(target), met: done >= target)
    }

    /// The week's average of `values` against a `target` threshold; the average is nil with no values,
    /// and then nothing is met.
    public static func average(_ values: [Double], target: Double) -> (average: Double?, progress: Progress) {
        let finite = values.filter(\.isFinite)
        guard !finite.isEmpty else { return (nil, Progress(fraction: 0, met: false)) }
        let mean = finite.reduce(0, +) / Double(finite.count)
        guard target > 0 else { return (mean, Progress(fraction: 1, met: true)) }
        return (mean, Progress(fraction: mean / target, met: mean >= target))
    }

    /// A weekly `total` against a `target` sum.
    public static func total(_ total: Double, target: Double) -> Progress {
        guard target > 0 else { return Progress(fraction: 1, met: true) }
        return Progress(fraction: total / target, met: total >= target)
    }

    /// The plan's overall percentage: the rounded equal-weight mean of the goals' capped fractions; nil
    /// for a plan with no goals.
    public static func overallPercent(_ progress: [Progress]) -> Int? {
        guard !progress.isEmpty else { return nil }
        let mean = progress.map(\.fraction).reduce(0, +) / Double(progress.count)
        return Int((mean * 100).rounded())
    }

    /// A days-per-week target in a week the plan covers only `countedDays` of (it began part-way through):
    /// never more days than there are, never fewer than one.
    public static func proratedTarget(_ target: Int, countedDays: Int) -> Int {
        guard countedDays < 7 else { return target }
        return max(1, min(target, max(0, countedDays)))
    }

    /// A weekly total scaled to the `countedDays` the plan covers, rounded up to `step`.
    public static func proratedTotal(_ target: Double, countedDays: Int, step: Double = 5) -> Double {
        guard countedDays < 7, target > 0 else { return target }
        let scaled = target * Double(max(1, countedDays)) / 7
        guard step > 0 else { return scaled }
        return (scaled / step).rounded(.up) * step
    }

    /// Days since 1970-01-01 for a "yyyy-MM-dd" key (Howard Hinnant's days_from_civil).
    static func daysSinceEpoch(_ dayKey: String) -> Int? {
        let parts = dayKey.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, var y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              (1...12).contains(m), (1...31).contains(d) else { return nil }
        y -= m <= 2 ? 1 : 0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }
}
