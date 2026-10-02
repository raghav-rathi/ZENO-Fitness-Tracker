#if os(iOS)
import SwiftUI

/// Customize Dashboard (WHOOP_UI_SPEC §3.13), presented as a full-screen modal with a pinned SAVE.
///
/// Owned by group "home". A placeholder until the group rebuilds it.
struct PulseCustomizeDashboardView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Customize Dashboard"),
            symbol: "slider.horizontal.3",
            summary: String(localized: "Choose, add and reorder the metric rows and charts in My Dashboard, then save."),
            spec: "§3.13",
            group: "home")
    }
}
#endif
