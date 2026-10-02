#if os(iOS)
import SwiftUI

/// Weekly Digest (WHOOP_UI_SPEC §3.40), pushed.
///
/// Owned by group "trends". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Weekly digest screen.
struct PulseWeeklyDigestView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Weekly Digest"),
            symbol: "calendar",
            summary: String(localized: "Your week at a glance: each pillar against last week, and the days that stood out."),
            spec: "§3.40",
            group: "trends",
            links: [
                .init(title: String(localized: "Weekly digest"), symbol: "calendar", route: .classic(.weeklyDigest))])
    }
}
#endif
