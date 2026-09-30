import Foundation

/// Calendar arithmetic on "yyyy-MM-dd" day keys.
///
/// A day key names a civil date, not an instant, so stepping it forward or back must not depend on the
/// device zone: this works in UTC throughout, the convention the rest of the app parses keys in (a key
/// parsed at UTC midnight and then shifted in a zone west of UTC lands on the previous day). Hand-parsed
/// rather than through a `DateFormatter`, so it is allocation-light and has no shared mutable state.
public enum StepsDayKeys {
    private static let utcCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0) ?? c.timeZone
        return c
    }()

    /// (year, month, day) for a well-formed key naming a real date, else nil.
    public static func components(_ day: String) -> (Int, Int, Int)? {
        let parts = day.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              let date = utcCalendar.date(from: DateComponents(year: y, month: m, day: d)) else { return nil }
        // `Calendar` is lenient ("2026-02-31" becomes 3 March), so a key only counts if it round-trips.
        let back = utcCalendar.dateComponents([.year, .month, .day], from: date)
        guard back.year == y, back.month == m, back.day == d else { return nil }
        return (y, m, d)
    }

    /// The key's date at UTC midnight. Format it with a UTC formatter, never the device zone.
    public static func utcMidnight(_ day: String) -> Date? {
        guard let (y, m, d) = components(day) else { return nil }
        return utcCalendar.date(from: DateComponents(year: y, month: m, day: d))
    }

    /// The key `offset` calendar days from `day` (negative steps back).
    public static func adding(_ offset: Int, to day: String) -> String? {
        guard let start = utcMidnight(day),
              let moved = utcCalendar.date(byAdding: .day, value: offset, to: start) else { return nil }
        let c = utcCalendar.dateComponents([.year, .month, .day], from: moved)
        guard let y = c.year, let m = c.month, let d = c.day else { return nil }
        return padded(y, 4) + "-" + padded(m, 2) + "-" + padded(d, 2)
    }

    /// Zero-padded decimal, locale-free (a formatted number could pick up a locale's digits).
    private static func padded(_ n: Int, _ width: Int) -> String {
        let s = String(n)
        return String(repeating: "0", count: max(0, width - s.count)) + s
    }

    /// The `count` consecutive keys ending on `day` inclusive, oldest first.
    public static func window(endingOn day: String, count: Int) -> [String] {
        guard count > 0 else { return [] }
        return (0..<count).reversed().compactMap { adding(-$0, to: day) }
    }
}

/// The daily step goal and what follows from it.
public enum StepGoal {
    /// The goal a fresh install starts with.
    public static let defaultGoal = 10_000
    /// The goals the editor offers. Below 1,000 a goal is met by getting out of bed; above 30,000 it stops
    /// being a daily target for almost anyone.
    public static let range: ClosedRange<Int> = 1_000...30_000
    /// One editor step.
    public static let increment = 500

    /// Pull a stored or typed goal into `range` (a hand-edited default can hold anything).
    public static func clamp(_ goal: Int) -> Int { min(max(goal, range.lowerBound), range.upperBound) }

    /// Steps as a fraction of the goal: 0 up, unbounded above (1.25 is 125%).
    public static func progress(steps: Int, goal: Int) -> Double {
        Double(max(0, steps)) / Double(clamp(goal))
    }

    /// The fill of a progress ring: `progress` capped at one full turn.
    public static func ringFraction(steps: Int, goal: Int) -> Double { min(1, progress(steps: steps, goal: goal)) }

    /// Whole percent of the goal, rounded down so "100%" is never shown a step short of it.
    public static func percent(steps: Int, goal: Int) -> Int {
        Int((progress(steps: steps, goal: goal) * 100).rounded(.down))
    }

    /// Steps still to go, never negative.
    public static func remaining(steps: Int, goal: Int) -> Int { max(0, clamp(goal) - max(0, steps)) }

    public static func isMet(steps: Int, goal: Int) -> Bool { steps >= clamp(goal) }

    /// The goal-reached notification policy: enabled, today's count known and at or over the goal, and not
    /// already posted for `today`. The caller only ever passes the in-progress day, so a backfilled past day
    /// can never fire a stale "you did it". Same crossing-dedupe shape as `StrainTargetNotifier`.
    public static func shouldNotify(enabled: Bool, steps: Int?, goal: Int,
                                    lastNotifiedDay: String?, today: String) -> Bool {
        guard enabled, let steps else { return false }
        return isMet(steps: steps, goal: goal) && lastNotifiedDay != today
    }
}

/// Mean steps over a calendar window.
public struct StepsAverage: Equatable, Sendable {
    /// nil when the window holds no reading at all.
    public let mean: Double?
    /// Days in the window that had a reading (the denominator).
    public let observedDays: Int

    public init(mean: Double?, observedDays: Int) {
        self.mean = mean
        self.observedDays = observedDays
    }
}

/// History statistics over resolved daily counts.
public enum StepsStats {

    /// Mean over the `days` calendar days ending on `day` inclusive, counting ONLY days with a reading: a
    /// missing day is not a zero (the phone may simply not have been carried), while a recorded zero is. A
    /// duplicate day keeps its last reading; negative and non-finite values are ignored. The in-progress day
    /// is included, as the rolling-average card has always done, so the two cannot disagree.
    public static func average(readings: [(day: String, value: Double)], endingOn day: String,
                               days: Int) -> StepsAverage {
        guard days > 0, let start = StepsDayKeys.adding(-(days - 1), to: day) else {
            return StepsAverage(mean: nil, observedDays: 0)
        }
        var byDay: [String: Double] = [:]
        for reading in readings where reading.day >= start && reading.day <= day
            && reading.value.isFinite && reading.value >= 0 {
            byDay[reading.day] = reading.value
        }
        guard !byDay.isEmpty else { return StepsAverage(mean: nil, observedDays: 0) }
        return StepsAverage(mean: byDay.values.reduce(0, +) / Double(byDay.count), observedDays: byDay.count)
    }

    /// Consecutive days at or over the goal, counted back from `today`. Today joins the streak once it is met;
    /// until then it is still in play, so it neither counts nor breaks it and the run is counted from
    /// yesterday. A day with no reading ends the streak, as a day under the goal does.
    public static func currentStreak(stepsByDay: [String: Int], goal: Int, today: String) -> Int {
        let target = StepGoal.clamp(goal)
        var streak = (stepsByDay[today] ?? 0) >= target ? 1 : 0
        var cursor = StepsDayKeys.adding(-1, to: today)
        while let day = cursor, let steps = stepsByDay[day], steps >= target {
            streak += 1
            cursor = StepsDayKeys.adding(-1, to: day)
        }
        return streak
    }

    /// The highest-count day; on a tie, the more recent one.
    public static func bestDay(_ days: [ResolvedStepDay]) -> ResolvedStepDay? {
        days.max { a, b in a.steps != b.steps ? a.steps < b.steps : a.day < b.day }
    }

    /// The top of a bar chart's value axis: the larger of the goal and the tallest bar, so the goal line is
    /// always on the chart and an over-goal day never clips, plus a little headroom.
    public static func chartCeiling(values: [Int], goal: Int) -> Int {
        let top = max(StepGoal.clamp(goal), values.max() ?? 0)
        return Int((Double(top) * 1.08).rounded(.up))
    }
}
