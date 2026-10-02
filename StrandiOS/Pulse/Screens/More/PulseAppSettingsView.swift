#if os(iOS)
import SwiftUI

/// App Settings (WHOOP_UI_SPEC §3.33), presented as a modal sheet.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Settings screen.
struct PulseAppSettingsView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "App Settings"),
            symbol: "gearshape",
            summary: String(localized: "Units, notifications, privacy and the rest of the app's settings."),
            spec: "§3.33",
            group: "more-profile",
            links: [
                .init(title: String(localized: "Settings"), symbol: "gearshape", route: .classic(.settings))])
    }
}
#endif
