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
    /// What the baseline under a value averages.
    enum BaselineKind: Equatable {
        /// The mean of the 30 days before the value's day.
        case thirtyDays
        /// A weekly total's mean week over the four weeks before it.
        case fourWeeks
    }

    /// The figure ("0:28", "51", "10,325"); nil while there is nothing to show (the row reads label + "›").
    var value: String?
    /// A unit printed small after it ("%", "Δ°C"); WHOOP prints none for counts, heart rates and weight.
    var unit: String?
    /// ▲ / ▼ / ● against the baseline, coloured by good / bad.
    var trend: PulseTrend?
    /// The baseline printed under the value, always a figure ("7,466", "46", "42%").
    var baseline: String?
    /// Whose day the value is, when it is not the shown day's own ("From 28 Sep").
    var caption: String?
    /// The screen the row opens until the Trend View is rebuilt.
    var fallback: PulseRoute
    /// A sleep figure carried from an earlier night: that night's wake day. Its caption ("Last night ·
    /// 28 Sep") is worded on the main actor by the Liquid Today's own rule (`captionText(dayKey:)`).
    var carriedNight: String? = nil
    var baselineKind: BaselineKind = .thirtyDays
    /// Today's still-growing total (steps, calories, Day Strain): compared like any day, as WHOOP does,
    /// and said "so far today" to VoiceOver.
    var isRunningTotal = false
    /// The unit VoiceOver hears where none is printed ("kg" after a weight).
    var spokenUnit: String? = nil

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

    /// A past day: no Get Started, Looking Ahead or personalizing state (they are today's).
    static let pastDay = PulseGetStartedFacts(isNewMember: false, calibration: nil, personalizing: false,
                                              hasWorkout: false, hasJournal: false, hasHistoryImport: false,
                                              sleepScheduled: false)
}

/// The store-side facts the Daily Outlook / Day in Review template reads beside `HomeSnapshot` (§3.15 [Z]).
struct PulseOutlookFacts: Equatable {
    /// The mean scored Recovery over the 7 days before the day (3 days at least), whole percent.
    let recoveryAverage7: Int?
    /// Consecutive days with a journal entry, ending today (or yesterday while today is not logged).
    let journalStreak: Int
    let journalLoggedToday: Bool
    /// Minutes in heart-rate zones 1-5, and in zones 4-5, over the 7 days ending today: the same weekly
    /// totals the HR ZONES (WEEKLY) rows print (one resolver, `zoneDays`).
    let zoneMinutesWeek: Double?
    let highZoneMinutesWeek: Double?
    /// The activities those minutes came from (the ones with a zone split or heart rate to bin).
    let zoneActivitiesWeek: Int
}

/// The Health Monitor tile for today (§3.1 item 6): the vitals judged, and for each one out of its range,
/// which way and how far, as the Health Monitor grades it (`HealthVital`).
struct PulseMonitorGrades: Equatable {
    struct Flag: Equatable {
        /// The vital's name ("Skin temperature").
        let name: String
        /// Where the Health Monitor says "very high" / "very low" (VERY ELEVATED / VERY LOW), else just past
        /// its range (ELEVATED / LOW).
        let strong: Bool
        /// Above or below its range; nil when the grade could not say, and the tile reads OUT OF RANGE.
        let high: Bool?
    }

    let judged: Int
    /// The vitals out of range, in the Health tab's order.
    let out: [Flag]

    var inRange: Int { judged - out.count }
    /// Nothing judged yet (calibrating, no readings): the tile shows "Pending".
    var isPending: Bool { judged == 0 }
}

/// The opt-in auto-detected workout for Home's coaching stack (§3.14 [Z]); `workout` is nil when there is none
/// to suggest.
struct HomeDetectedWorkout: Equatable {
    let workout: DetectedWorkout?
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
    /// The Health Monitor tile's grades, today only (the Health Monitor's own vitals, `healthVitals`).
    let monitor: PulseMonitorGrades?
    let start: PulseGetStartedFacts
    /// The day's stress, for the STRESS MONITOR tile (today) and the dashboard's STRESS MONITOR card, when
    /// either shows (`PulseSnapshotBuilder.stressSummary`, the Stress Monitor's own day).
    let stress: PulseStressSummary?
}
#endif
