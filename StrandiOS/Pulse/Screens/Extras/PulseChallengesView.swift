#if os(iOS)
import SwiftUI

/// Challenges (WHOOP_UI_SPEC §3.41), pushed.
///
/// Owned by group "extras". A placeholder until the group rebuilds it.
struct PulseChallengesView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Challenges"),
            symbol: "flag.checkered",
            summary: String(localized: "Personal challenges you set and track against your own data."),
            spec: "§3.41",
            group: "extras")
    }
}
#endif
