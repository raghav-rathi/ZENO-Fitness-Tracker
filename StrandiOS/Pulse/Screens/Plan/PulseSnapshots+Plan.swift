#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Weekly Plan snapshots (WHOOP_UI_SPEC §3.19)
//
// One plan week (Monday to Sunday) judged from ZENO's own data, built off the main actor by
// `PulseSnapshotBuilder+Plan.swift`. Every figure is measured; a goal with nothing to measure yet says so
// rather than counting as missed.

/// A plan week: its days, how many are left, the overall percentage and each goal's standing.
struct PlanWeekSnapshot: Equatable {
    let seq: Int
    /// The week's Monday, and its seven day keys.
    let weekStart: String
    let days: [String]
    let today: String
    /// Days left including today (Monday 7 … Sunday 1); 0 for a finished week.
    let daysLeft: Int
    /// "27% ACCOMPLISHED": the equal-weight mean of the goals' capped progress; nil without goals.
    let percent: Int?
    let goals: [PlanGoalProgress]

    var finished: [PlanGoalProgress] { goals.filter(\.met) }
    var unfinished: [PlanGoalProgress] { goals.filter { !$0.met } }
}

/// One goal's week.
struct PlanGoalProgress: Equatable, Identifiable {
    enum Style: Equatable {
        /// A metric card: day marks, a 7-day bar chart with a dashed GOAL line (Sleep, Strain, Steps).
        case metric
        /// A time card: the weekly total against its target on a thick bar, with the activities behind it.
        case time
        /// A count card: the MON–SUN circles (activities, behaviours).
        case count
    }

    /// The minutes one kind of activity contributed to a time goal ("0:56:23 RUNNING").
    struct ActivityLine: Equatable, Identifiable {
        let id: String
        let minutes: Double
        let sport: String
        let symbol: String
    }

    let goal: PulsePlanGoal
    var id: String { goal.id }
    /// The goal as WHOOP writes it in a list ("0:45+ HR Zones 4-5 Time", Home's card and the recap).
    let title: String
    /// Its title on a Plan Overview card: a time goal by its kind alone ("HR Zones 4-5 Time"), since the
    /// card prints the target at the end of its bar (completeness-critic/23).
    let cardTitle: String
    let section: PulsePlanSection
    let style: Style
    let ring: PulseGoalRing.Kind
    let met: Bool
    let fraction: Double
    /// MON–SUN.
    let dayStates: [PulseDayCircleRow.State]
    /// A metric card's daily values (nil = nothing measured that day).
    let dayValues: [Double?]
    /// A metric card's GOAL line, on the bars' own axis.
    let goalLine: Double?
    /// "Avg. 82%".
    let averageText: String?
    /// A time card's total and target ("0:57:01", "0:58:00").
    let progressText: String?
    let targetText: String?
    let activities: [ActivityLine]
    /// The goal's rule or what is left ("Get 1 min more of Zone 4-5 training during activities this week to
    /// hit your goal.").
    let footer: String
    /// What the measurement had to leave out ("2 activities this week have no heart-rate zone data.").
    let note: String?
    /// The target the week is held to (pro-rated in the week a plan starts).
    let targetDays: Int?
}
#endif
