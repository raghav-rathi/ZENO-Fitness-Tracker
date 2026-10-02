#if os(iOS)
import SwiftUI

/// Add Activity (WHOOP_UI_SPEC §3.9), presented as a sheet.
///
/// Owned by group "activity". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Workouts screen.
struct PulseAddActivityView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Add Activity"),
            symbol: "plus.circle",
            summary: String(localized: "Log an activity, a sleep or a nap that you did without recording it live."),
            spec: "§3.9",
            group: "activity",
            links: [
                .init(title: String(localized: "Workouts"), symbol: "figure.run", route: .classic(.workouts))])
    }
}
#endif
