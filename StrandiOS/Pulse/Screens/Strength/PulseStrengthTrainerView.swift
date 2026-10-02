#if os(iOS)
import SwiftUI

/// Strength Trainer (WHOOP_UI_SPEC §3.29), presented as a full-screen modal.
///
/// Owned by group "onboarding-strength". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Lift Log screen.
struct PulseStrengthTrainerView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Strength Trainer"),
            symbol: "dumbbell",
            summary: String(localized: "Build a workout, log your sets and see your muscular load."),
            spec: "§3.29",
            group: "onboarding-strength",
            links: [
                .init(title: String(localized: "Lift Log"), symbol: "dumbbell", route: .classic(.liftLog))])
    }
}
#endif
