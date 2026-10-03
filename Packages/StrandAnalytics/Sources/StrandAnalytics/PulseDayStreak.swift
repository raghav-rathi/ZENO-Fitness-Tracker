import Foundation

// PulseDayStreak.swift - everything the Pulse Day Streak page shows around the streak count itself.
//
// The count is NOT decided here: it is `StreakCalculator`'s current run (days with a scored Recovery,
// with today's grace before the night is scored), the same rule the Home streak pill and the classic
// Settings card read, so the three can never disagree. These helpers add what the page draws around that
// number (WHOOP_UI_SPEC §3.30 "Day Streak page", §1.4): the run's first day, the Monday-to-Sunday week
// with a state per day, the milestone ladder and the flame tier.
//
// Day keys are civil "yyyy-MM-dd" days. All arithmetic is on civil epoch days (`Baselines.isoEpochDay`,
// `ActivityHeatmap.civilDay`), so the result is the same in every time zone: a key never moves to the
// previous day west of UTC.
//
// Display-only by design: nothing here is persisted or crosses the .noopbak boundary, so there is no
// Kotlin twin to keep byte-identical (the same rule as `PulseDisplay`). Pure, no clock, no I/O.

public enum PulseDayStreak {

    // MARK: - Tiers

    /// The flame's tier by streak length (spec §1.4). The cut-offs match `PulseTheme.Streak.flame(days:)`
    /// on iOS, which colours the same flame: 1–99, 100–179, 180–364, 365–999, 1000–1999, 2000+.
    public enum Tier: Int, CaseIterable, Equatable, Sendable {
        /// 1–99 days: yellow.
        case spark
        /// 100–179 days: orange.
        case flame
        /// 180–364 days: red with a blue core.
        case blaze
        /// 365–999 days: magenta-red.
        case inferno
        /// 1000–1999 days: blue.
        case legend
        /// 2000 days and more: gold.
        case legacy
    }

    /// The tier a streak of `days` burns at (0 or less reads as the first tier).
    public static func tier(days: Int) -> Tier {
        switch days {
        case ..<100: return .spark
        case ..<180: return .flame
        case ..<365: return .blaze
        case ..<1000: return .inferno
        case ..<2000: return .legend
        default: return .legacy
        }
    }

    // MARK: - Milestones

    /// The milestone ladder up to 1000 days. Past 1000 a milestone falls every 50 days (1050, 1100, …),
    /// as WHOOP's August 2026 build steps them (1300 → 1350, 2000 → 2050). Between 7 and 100 WHOOP's own
    /// steps were never seen; 14, 30 and 60 are ZENO's.
    public static let ladder: [Int] = [1, 7, 14, 30, 60, 100, 180, 365, 730, 1000]

    /// The step between milestones above the ladder's last rung.
    public static let stepAboveLadder = 50

    /// Where a streak sits between two milestones.
    public struct MilestoneProgress: Equatable, Sendable {
        /// The milestone already reached, or nil before the first day.
        public let last: Int?
        /// The next milestone.
        public let next: Int
        /// The streak counted.
        public let days: Int

        /// Days still to go to `next`.
        public var remaining: Int { max(0, next - days) }
        /// How far from `last` (or zero) toward `next`, 0...1.
        public var fraction: Double {
            let from = last ?? 0
            guard next > from else { return 1 }
            return min(1, max(0, Double(days - from) / Double(next - from)))
        }
    }

    /// The highest milestone at or below `days`, or nil when `days` is below the first one.
    public static func lastMilestone(atOrBelow days: Int) -> Int? {
        guard days >= 1 else { return nil }
        let top = ladder[ladder.count - 1]
        if days < top { return ladder.last(where: { $0 <= days }) }
        return top + (days - top) / stepAboveLadder * stepAboveLadder
    }

    /// The lowest milestone strictly above `days`.
    public static func nextMilestone(after days: Int) -> Int {
        let top = ladder[ladder.count - 1]
        if days < top { return ladder.first(where: { $0 > days }) ?? top }
        return top + ((days - top) / stepAboveLadder + 1) * stepAboveLadder
    }

    /// The milestone card's values for a streak of `days`.
    public static func milestoneProgress(days: Int) -> MilestoneProgress {
        let count = max(0, days)
        return MilestoneProgress(last: lastMilestone(atOrBelow: count), next: nextMilestone(after: count),
                                 days: count)
    }

    // MARK: - The current run

    /// The streak's run of qualifying days.
    public struct Run: Equatable, Sendable {
        /// How many days, the same number as `StreakCalculator.streaks(…).current`.
        public let length: Int
        /// Its first and last day keys.
        public let startDay: String
        public let endDay: String
    }

    /// The current run, anchored exactly as `StreakCalculator` anchors it: at `today` when today
    /// qualifies, else at yesterday (today is not scored until its night is), else none.
    public static func currentRun(dayKeys: [String], qualified: [Bool], today: String) -> Run? {
        let days = qualifiedEpochDays(dayKeys: dayKeys, qualified: qualified)
        guard let t = Baselines.isoEpochDay(today) else { return nil }
        let anchor: Int
        if days.contains(t) { anchor = t } else if days.contains(t - 1) { anchor = t - 1 } else { return nil }
        var start = anchor
        while days.contains(start - 1) { start -= 1 }
        return Run(length: anchor - start + 1, startDay: ActivityHeatmap.civilDay(start),
                   endDay: ActivityHeatmap.civilDay(anchor))
    }

    // MARK: - This week

    /// One day of the THIS WEEK row.
    public enum DayState: String, Equatable, Sendable {
        /// The day qualified: a flame.
        case kept
        /// A past day that did not: ✕.
        case missed
        /// Today, not scored yet: a dashed circle, never a ✕ (its night may still be scored).
        case pending
        /// A day still to come: a dashed circle.
        case upcoming
    }

    public struct WeekDay: Equatable, Sendable {
        /// The civil day key.
        public let day: String
        /// 1 = Monday … 7 = Sunday.
        public let weekday: Int
        public let state: DayState
        public let isToday: Bool
    }

    /// Monday to Sunday of the week holding `today`, each with its state; empty for a malformed `today`.
    public static func week(dayKeys: [String], qualified: [Bool], today: String) -> [WeekDay] {
        guard let t = Baselines.isoEpochDay(today) else { return [] }
        let days = qualifiedEpochDays(dayKeys: dayKeys, qualified: qualified)
        let monday = t - ActivityHeatmap.mondayFirstWeekday(t)
        return (0..<7).map { offset in
            let d = monday + offset
            let state: DayState
            if days.contains(d) {
                state = .kept
            } else if d < t {
                state = .missed
            } else if d == t {
                state = .pending
            } else {
                state = .upcoming
            }
            return WeekDay(day: ActivityHeatmap.civilDay(d), weekday: offset + 1, state: state, isToday: d == t)
        }
    }

    // MARK: - Unlocks

    /// The milestone a streak of `days` has newly reached since `acknowledged` (the last milestone the
    /// wearer was shown), or nil when there is nothing new. A first look (`acknowledged` nil) is a
    /// baseline, never an unlock, so opening the page on a long-standing streak does not announce it.
    public static func newMilestone(days: Int, acknowledged: Int?) -> Int? {
        guard let acknowledged, let reached = lastMilestone(atOrBelow: days), reached > acknowledged else {
            return nil
        }
        return reached
    }

    // MARK: - Helpers

    private static func qualifiedEpochDays(dayKeys: [String], qualified: [Bool]) -> Set<Int> {
        var days = Set<Int>()
        for i in 0..<Swift.min(dayKeys.count, qualified.count) where qualified[i] {
            if let e = Baselines.isoEpochDay(dayKeys[i]) { days.insert(e) }
        }
        return days
    }
}
