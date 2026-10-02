#if os(iOS)
import SwiftUI

/// Menstrual Cycle Insights (WHOOP_UI_SPEC §3.24), pushed.
///
/// Owned by group "cycle-coach". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Classic Health screen.
struct PulseCycleInsightsView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Menstrual Cycle Insights"),
            symbol: "circle.dotted",
            summary: String(localized: "Your cycle phase and predictions, and how the cycle shapes your scores."),
            spec: "§3.24",
            group: "cycle-coach",
            links: [
                .init(title: String(localized: "Classic Health"), symbol: "heart.text.square", route: .classic(.classicHealth))])
    }
}
#endif
