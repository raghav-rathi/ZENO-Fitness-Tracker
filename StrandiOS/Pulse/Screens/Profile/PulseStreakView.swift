#if os(iOS)
import SwiftUI

/// Day Streak (WHOOP_UI_SPEC §3.30), pushed.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it.
struct PulseStreakView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Day Streak"),
            symbol: "flame",
            summary: String(localized: "Your day streak, its tiers and the days behind it."),
            spec: "§3.30",
            group: "more-profile")
    }
}
#endif
