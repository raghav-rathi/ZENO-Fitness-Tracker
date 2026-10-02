#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Home's own snapshot (group "home")
//
// `HomeSnapshot` (Model/) carries what every shell shows for a day: the dials, the activities, tonight's
// plan, the vitals. `HomeExtrasSnapshot` carries the facts only Home's rebuilt sections need, built off the
// main actor for the same request and day by `PulseSnapshotBuilder.homeExtras(_:home:items:)`. It reuses the
// HomeSnapshot it was built beside for every figure the two share, so a dashboard row and a dial can never
// show one number two ways.

/// One My Dashboard row, resolved and formatted for a day.
struct PulseDashboardValue: Equatable {
    /// The figure ("0:28", "51", "10,325"); nil while there is nothing to show (the row reads label + "›").
    var value: String?
    /// A unit printed small after it ("%", "kg", "Δ°C"); WHOOP prints none for counts and heart rates.
    var unit: String?
    /// ▲ / ▼ / ● against the 30-day baseline, coloured by good / bad.
    var trend: PulseTrend?
    /// The 30-day baseline printed under the value, or a short note in its place ("So far today").
    var baseline: String?
    /// Whose day the value is, when it is not the shown day's own ("From 28 Sep").
    var caption: String?
    /// The screen the row opens until the Trend View is rebuilt.
    var fallback: PulseRoute
    /// A sleep figure carried from an earlier night: that night's wake day. Its caption ("Last night ·
    /// 28 Sep") is worded on the main actor by the Liquid Today's own rule (`captionText(dayKey:)`).
    var carriedNight: String? = nil

    /// A row with nothing to show yet.
    static func empty(_ fallback: PulseRoute) -> PulseDashboardValue {
        PulseDashboardValue(value: nil, unit: nil, trend: nil, baseline: nil, caption: nil, fallback: fallback)
    }

    /// The line under the row's name for the day `dayKey`: the value's own caption, or whose night a
    /// carried sleep figure is.
    @MainActor
    func captionText(dayKey: String) -> String? {
        caption ?? carriedNight.map { TodayView.carriedCaption(priorDayKey: $0, todayKey: dayKey) }
    }
}

/// What the new-member Home and Looking Ahead need (§3.1 items 10, 11; §2.9 "New member", "Calibrating").
struct PulseGetStartedFacts: Equatable {
    /// No Recovery has ever scored: "Get Started" takes My Day's place.
    let isNewMember: Bool
    /// Looking Ahead's counter: nights banked of the 4 Recovery needs, then scored days of the 7 the weekly
    /// features need; nil once past both.
    let calibration: Progress?
    /// Fewer than 7 scored days: My Dashboard says it is personalizing and hides CUSTOMIZE (as WHOOP does).
    let personalizing: Bool
    /// The Get Started cards' "done" signals: a card whose step is done leaves the list.
    let hasWorkout: Bool
    let hasJournal: Bool
    let hasHistoryImport: Bool
    let sleepScheduled: Bool

    struct Progress: Equatable {
        let done: Int
        let of: Int
    }
}

/// The store-side facts the Daily Outlook / Day in Review template reads beside `HomeSnapshot` (§3.15 [Z]).
struct PulseOutlookFacts: Equatable {
    /// The mean scored Recovery over the 7 days before the day (3 days at least), whole percent.
    let recoveryAverage7: Int?
    /// Consecutive days with a journal entry, ending today (or yesterday while today is not logged).
    let journalStreak: Int
    let journalLoggedToday: Bool
    /// Minutes in heart-rate zones 1-5, and in zones 4-5, across the last 7 days' activities.
    let zoneMinutesWeek: Double?
    let highZoneMinutesWeek: Double?
    let activitiesThisWeek: Int
}

/// Everything Home's own sections draw for one day, beside `HomeSnapshot`.
struct HomeExtrasSnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    /// The rows the dashboard shows, resolved for the day.
    let dashboard: [PulseDashboardItem: PulseDashboardValue]
    /// The coaching rules' store inputs, today only; the view adds the app state (illness, alarm, release
    /// notes) and evaluates `HomeCoachingRules.cards`.
    let coaching: HomeCoachingRules.Inputs?
    /// The local Daily Outlook's facts, today only.
    let outlook: PulseOutlookFacts?
    let start: PulseGetStartedFacts
}
#endif
