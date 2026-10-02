#if os(iOS)
import SwiftUI

/// Profile (WHOOP_UI_SPEC §3.30), pushed.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Settings screen.
struct PulseProfileView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Profile"),
            symbol: "person.crop.circle",
            summary: String(localized: "Your avatar, level, ZENO Age, day streak, memory, achievements and highlights."),
            spec: "§3.30",
            group: "more-profile",
            links: [
                .init(title: String(localized: "Settings"), symbol: "gearshape", route: .classic(.settings))])
    }
}
#endif
