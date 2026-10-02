#if os(iOS)
import SwiftUI

/// Activity Details (WHOOP_UI_SPEC §3.6), pushed (Home may present it).
///
/// Owned by group "activity". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Workout detail screen.
struct PulseActivityDetailView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false
    /// The activity to show.
    let workout: PulseWorkoutRoute

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Activity Details"),
            symbol: "figure.run",
            summary: String(localized: "Strain, heart-rate zones, calories and the heart-rate chart for one activity."),
            spec: "§3.6",
            group: "activity",
            links: [
                .init(title: String(localized: "Workout detail"), symbol: "figure.run", route: .classic(.workoutDetail(workout)))],
            coach: .button)
    }
}
#endif
