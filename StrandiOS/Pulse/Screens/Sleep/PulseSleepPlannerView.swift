#if os(iOS)
import SwiftUI

/// Sleep Planner (WHOOP_UI_SPEC §3.11), presented as a modal sheet.
///
/// Owned by group "sleep". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Alarms screen.
struct PulseSleepPlannerView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Sleep Planner"),
            symbol: "bed.double",
            summary: String(localized: "Tonight's recommended bedtime, your wake time and the strap alarm in one place."),
            spec: "§3.11",
            group: "sleep",
            links: [
                .init(title: String(localized: "Alarms"), symbol: "alarm", route: .classic(.alarms))])
    }
}
#endif
