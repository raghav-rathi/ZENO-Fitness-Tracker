#if os(iOS)
import SwiftUI

// MARK: - ⓘ explainers for the Sleep group (WHOOP_UI_SPEC §3.3 "Interactions", §3.11 nav "?")
//
// Each detail card's ⓘ, and the Sleep Planner's "?", open a short sheet saying what the figure is and where
// ZENO gets it from. Dark like every Pulse sheet (§1.5 [Z]: WHOOP's light ⓘ sheets are not copied).

/// What an explainer covers.
enum PulseSleepExplainerTopic: String, Hashable, CaseIterable {
    case hoursOfSleep, hoursVsNeeded, consistency, efficiency, stress, planner

    var title: String {
        switch self {
        case .hoursOfSleep: return String(localized: "Hours of sleep")
        case .hoursVsNeeded: return String(localized: "Hours vs. needed")
        case .consistency: return String(localized: "Sleep consistency")
        case .efficiency: return String(localized: "Sleep efficiency")
        case .stress: return String(localized: "Sleep stress")
        case .planner: return String(localized: "Sleep planner")
        }
    }

    /// The explanation, a paragraph at a time.
    var paragraphs: [String] {
        switch self {
        case .hoursOfSleep:
            return [
                String(localized: "Time asleep in your main sleep, from your strap's sleep staging. The figure under it is your average over the 30 nights before, and the arrow is coloured by whether the change is good for you."),
                String(localized: "The chart is your heart rate through the night; the dashed lines mark when you fell asleep and when you woke. Each stage's bar is its share of your time in bed, and the box marks your typical range, the middle half of your last 30 nights."),
                String(localized: "Tap a stage to see when it happened through the night. Restorative sleep is deep (SWS) and REM together."),
            ]
        case .hoursVsNeeded:
            return [
                String(localized: "Your hours of sleep against the sleep you needed, as a percentage."),
                String(localized: "Your need is ZENO's sleep need: a healthy minimum learned from your recent nights, more after a harder day than usual (recent strain), part of any recent shortfall (sleep debt), and less after a nap. The well shows each part, and they add up to the need."),
            ]
        case .consistency:
            return [
                String(localized: "How closely your bed and wake times matched the four nights before. Within a quarter of an hour counts as a match; three hours apart scores zero."),
                String(localized: "The dashed lines are the times that would have scored highest: the middle of those nights' bed and wake times. It needs three of the four nights before, so a new routine shows Calibrating for a few days."),
            ]
        case .efficiency:
            return [
                String(localized: "Time asleep as a share of your time in bed. The tracks show when you were asleep and awake through the night: a tick is a short wake, a block a longer one."),
                String(localized: "Wake events count the times you woke during the night."),
            ]
        case .stress:
            return [
                String(localized: "Your heart rate and heart-rate variability through the night, scored on the same 0 to 3 scale as the Stress Monitor and measured against how calm you were while awake the day before."),
                String(localized: "High sleep stress is the share of the night that read 2.0 or above. A settled night stays low; a wake-up or a restless stretch shows as a spike. It is an approximate read, not a medical one."),
                String(localized: "The figure under it is your average over the 30 nights before, once five of them could be scored, and the arrow is coloured by whether the change is good for you."),
            ]
        case .planner:
            return [
                String(localized: "Your wake time is your strap alarm's when it will buzz that morning; otherwise the wake time of your wind-down reminder while it is on; otherwise the wake time you set here, even with the alarm off. Until you set one, it is your usual wake, the middle of your last two weeks of nights, or with too few nights, a typical 7:00 AM. Home's Tonight's Sleep plans for the same wake."),
                String(localized: "Reach my sleep need plans for 100%, 85% or 70% of tonight's need from ZENO's sleep need model, the same need Hours vs. needed measures against. The suggested time to bed leaves that much sleep before your wake time, plus 15 minutes to fall asleep."),
                String(localized: "Improve my sleep plans for consistency instead: asleep at the middle of your last four nights' bedtimes, which keeps tomorrow's Sleep Consistency highest for your wake time. The percentage is the score that night would get."),
                String(localized: "The optimal window is the bed and wake time that would keep your Sleep Consistency highest. ZENO never suggests a bedtime before 8 PM unless you wake before 5 AM."),
                String(localized: "The alarm is your strap's silent buzz, armed on the strap itself. Keep a phone alarm as a backup for anything you cannot miss."),
            ]
        }
    }
}

/// An explainer, presented as a sheet by the shell (`navigator.open(PulseSleepExplainerRoute(topic:).route)`).
struct PulseSleepExplainerRoute: PulseScreenRoute {
    let topic: PulseSleepExplainerTopic
    var presentation: PulsePresentation { .sheet }
    var view: some View { PulseSleepExplainerView(topic: topic) }
}

struct PulseSleepExplainerView: View {
    let topic: PulseSleepExplainerTopic

    var body: some View {
        PulseScreenScaffold(title: topic.title) {
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(topic.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
#endif
