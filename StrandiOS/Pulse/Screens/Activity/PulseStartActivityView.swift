#if os(iOS)
import SwiftUI

/// Start Activity (WHOOP_UI_SPEC §3.8), presented as a full-screen modal.
///
/// Owned by group "activity". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Workouts screen.
struct PulseStartActivityView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Start Activity"),
            symbol: "stopwatch",
            summary: String(localized: "Pick an activity, set a Strain Target and start a live session."),
            spec: "§3.8",
            group: "activity",
            links: [
                .init(title: String(localized: "Workouts"), symbol: "figure.run", route: .classic(.workouts)),
                .init(title: String(localized: "Interval timer"), symbol: "timer", route: .classic(.intervals))])
    }
}
#endif
