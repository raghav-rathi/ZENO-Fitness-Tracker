#if os(iOS)
import SwiftUI

/// The Stress Monitor's ⚙ (§3.22 item 1), pushed from its bar.
struct HealthStressSettingsRoute: PulseScreenRoute {
    var view: some View { PulseStressSettingsView() }
}

/// What ZENO's stress features can be set to. STRESS CHECK-INS are the haptic one-minute breath the strap
/// offers on a fresh HRV dip while you are still: the classic Automations' switches, on the `BehaviorStore`
/// keys the detector reads (`BiofeedbackPrefs`), so the two screens set the same thing. SCORING is the lens
/// the monitor's ⓘ names: each hour against the day's calmest hours, or against your own usual days
/// (`PuffinExperiment.stressPersonalBaselineKey`, which `PulseRootView` feeds into the builds' preferences,
/// so the monitor rescores when it changes).
struct PulseStressSettingsView: View {
    @EnvironmentObject private var behavior: BehaviorStore
    @AppStorage(PuffinExperiment.stressPersonalBaselineKey) private var personalBaseline = false

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Stress Monitor"), spacing: MoreLayout.sectionGap) {
            MoreSection(String(localized: "Stress check-ins")) {
                MoreToggleRow(title: String(localized: "Stress check-ins"), isOn: $behavior.stressCheckIn,
                              help: String(localized: "When a fresh, non-exercise HRV dip is detected while you're still, ZENO offers a one-minute guided breath: a single confirming buzz and a dismissible card. Never an alarm, never a diagnosis."),
                              separator: behavior.stressCheckIn)
                if behavior.stressCheckIn {
                    MoreToggleRow(title: String(localized: "Auto-nudge"), isOn: $behavior.stressAutoNudge,
                                  help: String(localized: "Let the check-in fire on its own. Off keeps it manual: you start a breath from Breathe yourself."))
                    MoreToggleRow(title: String(localized: "Respect quiet hours"), isOn: $behavior.stressQuietHours,
                                  help: String(localized: "Suppress auto-nudges overnight (10pm-7am)."))
                    MoreToggleRow(title: String(localized: "Use my resonance pace"),
                                  isOn: $behavior.stressUseResonancePace,
                                  help: String(localized: "Breathe at the pace your last \u{201C}find my pace\u{201D} sweep locked in, if you have one. Otherwise a calm 5.5 breaths/min."),
                                  separator: false)
                }
            }
            MoreSection(String(localized: "Scoring")) {
                MoreToggleRow(title: String(localized: "Personal baseline"), isOn: $personalBaseline,
                              help: String(localized: "Score each hour against how your own days usually run, not the day's calmest hours. Experimental."),
                              separator: false)
            }
        }
    }
}
#endif
