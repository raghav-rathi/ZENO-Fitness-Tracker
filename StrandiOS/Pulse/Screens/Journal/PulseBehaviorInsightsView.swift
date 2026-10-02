#if os(iOS)
import SwiftUI

/// Behavior Insights (WHOOP_UI_SPEC §3.18), pushed.
///
/// Owned by group "journal-plan". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic What moves you screen.
struct PulseBehaviorInsightsView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Behavior Insights"),
            symbol: "lightbulb",
            summary: String(localized: "How each behaviour you log moves your Recovery and Sleep."),
            spec: "§3.18",
            group: "journal-plan",
            links: [
                .init(title: String(localized: "What moves you"), symbol: "wand.and.sparkles", route: .classic(.insightsHub))],
            coach: .button)
    }
}
#endif
