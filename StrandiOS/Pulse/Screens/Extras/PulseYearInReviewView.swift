#if os(iOS)
import SwiftUI

/// Year in Review (WHOOP_UI_SPEC §3.39), presented as a full-screen story.
///
/// Owned by group "extras". A placeholder until the group rebuilds it.
struct PulseYearInReviewView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Year in Review"),
            symbol: "sparkles",
            summary: String(localized: "Your year as a story: best days, totals and records."),
            spec: "§3.39",
            group: "extras")
    }
}
#endif
