import Foundation

// PaceOfAging.swift — the Healthspan "Pace of Aging", read from ZENO's weekly ZENO Age.
//
// ZENO Age is the VitalityEngine Body Age the weekly scoring pass stores under each week's Saturday
// key ("body_age"). Pace of Aging says how fast that age is moving per calendar year: 1.0x keeps pace
// with the calendar, below 1.0x is slower, above is faster. WHOOP_UI_SPEC §3.23 [Z] defines it as
//
//     pace = 1 + slope of (ZENO Age − chronological age) over the last 6 months, in years per year,
//
// clamped to −1.0…3.0 and updated weekly. The gap (ZENO Age − chronological age) is the engine's own
// Δage, so a gap that holds steady reads exactly 1.0x and a gap closing by a year per year reads 0.0x.
//
// The chronological age of each week must be the one the engine scored that week with (the profile's
// whole-year age at the time). Subtracting it removes the one-year step a birthday puts into the stored
// ZENO Age; using a fractional age instead would read a steady gap as a 0.0x pace between birthdays.
//
// Pure, database-free and deterministic: weeks are addressed by their "yyyy-MM-dd" key and the
// arithmetic counts whole calendar days at UTC, so every time zone gets the same answer. Wellness
// estimate, never a clinical measure.
public enum PaceOfAging {

    /// One week's ZENO Age, as the weekly VitalityEngine pass stored it.
    public struct Week: Equatable, Sendable {
        /// The week's key, "yyyy-MM-dd" (the Saturday the pass stamps).
        public let day: String
        /// ZENO Age (the VitalityEngine Body Age), years.
        public let bodyAge: Double
        /// The chronological age the engine scored the week with, years.
        public let chronoAge: Double

        public init(day: String, bodyAge: Double, chronoAge: Double) {
            self.day = day
            self.bodyAge = bodyAge
            self.chronoAge = chronoAge
        }

        /// ZENO Age minus chronological age: negative is younger than your age.
        public var gapYears: Double { bodyAge - chronoAge }
    }

    /// The trailing window the slope is fitted over: the last 6 months.
    public static let windowDays = 182
    /// Fewer weekly points than this in the window: no pace (a slope through two or three weeks is noise
    /// multiplied by 52).
    public static let minWeeks = 4
    /// The window's points must span at least three weeks.
    public static let minSpanDays = 21
    /// While the window holds fewer weekly points than this, the pace is still settling: the Health tab
    /// shows its "calibrating" note (§3.20 item 2).
    public static let settledWeeks = 8
    /// The scale the ruler draws and the value is clamped to.
    public static let range: ClosedRange<Double> = -1.0...3.0

    private static let daysPerYear = 365.2425

    /// Pace of Aging as of the week keyed `day` (inclusive), from the weeks in the `windowDays` ending on
    /// it. nil when the window has fewer than `minWeeks` points or spans less than `minSpanDays`.
    /// Malformed keys are skipped; a key that appears twice keeps its last entry.
    public static func pace(_ weeks: [Week], asOf day: String) -> Double? {
        guard let end = dayNumber(day) else { return nil }
        let points = window(weeks, endingOn: end)
        guard points.count >= minWeeks,
              let first = points.first?.day, let last = points.last?.day,
              last - first >= minSpanDays else { return nil }
        let xs = points.map { Double($0.day - first) / daysPerYear }
        let ys = points.map(\.gap)
        let n = Double(points.count)
        let mx = xs.reduce(0, +) / n
        let my = ys.reduce(0, +) / n
        var sxy = 0.0
        var sxx = 0.0
        for (x, y) in zip(xs, ys) {
            sxy += (x - mx) * (y - my)
            sxx += (x - mx) * (x - mx)
        }
        guard sxx > 0 else { return nil }
        return clamp(1 + sxy / sxx)
    }

    /// The pace for every week that has one, oldest first: the PACE OF AGING TREND, and the previous week
    /// a "vs. last week" chip compares against.
    public static func series(_ weeks: [Week]) -> [(day: String, pace: Double)] {
        let keys = Set(weeks.compactMap { dayNumber($0.day) != nil ? $0.day : nil }).sorted()
        return keys.compactMap { key in pace(weeks, asOf: key).map { (day: key, pace: $0) } }
    }

    /// How many weekly points the window ending on `day` holds (the settling check).
    public static func weeksInWindow(_ weeks: [Week], endingOn day: String) -> Int {
        guard let end = dayNumber(day) else { return 0 }
        return window(weeks, endingOn: end).count
    }

    /// This week's pace against last week's, judged on the figures as they print (one decimal): equal
    /// figures are "no change", whatever the hidden digits say.
    public enum Change: String, Equatable, Sendable {
        case slower, same, faster
    }

    public static func change(current: Double, previous: Double) -> Change {
        let now = (current * 10).rounded()
        let before = (previous * 10).rounded()
        if now == before { return .same }
        return now < before ? .slower : .faster
    }

    /// Where `pace` sits along the −1.0…3.0 ruler, 0…1 (1.0x is at 0.5).
    public static func rulerFraction(_ pace: Double) -> Double {
        (clamp(pace) - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    // MARK: - Internals

    private struct Point {
        let day: Int
        let gap: Double
    }

    /// The weeks within the window ending on day number `end`, oldest first, one per day.
    private static func window(_ weeks: [Week], endingOn end: Int) -> [Point] {
        var byDay: [Int: Double] = [:]
        for week in weeks {
            guard let d = dayNumber(week.day), d <= end, d > end - windowDays,
                  week.bodyAge.isFinite, week.chronoAge.isFinite else { continue }
            byDay[d] = week.gapYears
        }
        return byDay.keys.sorted().map { Point(day: $0, gap: byDay[$0] ?? 0) }
    }

    private static func clamp(_ v: Double) -> Double {
        min(range.upperBound, max(range.lowerBound, v))
    }

    /// Days since 1970-01-01 for a "yyyy-MM-dd" key, counted on the proleptic Gregorian calendar
    /// (Hinnant's days-from-civil), or nil for a malformed key. No Calendar or DateFormatter, so it is
    /// thread-safe and identical everywhere.
    public static func dayNumber(_ key: String) -> Int? {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y0 = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              (1...12).contains(m), (1...31).contains(d) else { return nil }
        let y = m <= 2 ? y0 - 1 : y0
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (m + 9) % 12
        let doy = (153 * mp + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }
}

extension VitalityEngine {
    /// One factor's share of the ZENO Age gap, in years: its log-hazard through the same overlap shrink
    /// and Gompertz conversion `compute` applies to their sum, so the factors of one result add up to
    /// `bodyAge − chronoAge` (before the age clamp). Positive ages you; negative is protective. This is the
    /// "-3.2 years" a Healthspan pillar row prints (WHOOP_UI_SPEC §3.23 [Z]).
    public static func years(for contribution: Contribution) -> Double {
        contribution.lnHazard * overlapShrink / lnHazardPerYear
    }
}
