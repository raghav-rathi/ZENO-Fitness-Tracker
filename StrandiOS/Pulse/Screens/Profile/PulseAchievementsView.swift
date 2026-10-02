#if os(iOS)
import SwiftUI

/// Achievements (WHOOP_UI_SPEC §3.30), pushed.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it.
struct PulseAchievementsView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Achievements"),
            symbol: "rosette",
            summary: String(localized: "Every badge family, what you have unlocked and what comes next."),
            spec: "§3.30",
            group: "more-profile")
    }
}
#endif
