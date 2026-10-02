#if os(iOS)
import SwiftUI

/// First Week with ZENO (WHOOP_UI_SPEC §1.8, §3.31), pushed from More: a checklist of first steps, each row
/// with its check state (track an activity, analyze your Sleep Performance, view your activity details, set
/// up your strap alarm, set up your daily journal, import your history).
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it. Until then, the shell's existing
/// entry points keep opening the classic scoring guide.
struct PulseFirstWeekView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "First Week with ZENO"),
            symbol: "graduationcap",
            summary: String(localized: "A short checklist that walks you through your first week with ZENO."),
            spec: "§3.31",
            group: "more-profile",
            links: [
                .init(title: String(localized: "How ZENO works"), symbol: "questionmark.circle",
                      route: .classic(.scoringGuide)),
                .init(title: String(localized: "What's new"), symbol: "sparkles", route: .classic(.whatsNew))])
    }
}
#endif
