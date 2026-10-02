#if os(iOS)
import SwiftUI

/// Levels (WHOOP_UI_SPEC §3.30), pushed.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it.
struct PulseLevelsView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Levels"),
            symbol: "chart.bar.xaxis",
            summary: String(localized: "Your level, its tier and what is left to reach the next one."),
            spec: "§3.30",
            group: "more-profile")
    }
}
#endif
