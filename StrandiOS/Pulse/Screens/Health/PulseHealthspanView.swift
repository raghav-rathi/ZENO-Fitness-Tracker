#if os(iOS)
import SwiftUI

/// Healthspan (WHOOP_UI_SPEC §3.23), pushed.
///
/// Owned by group "health". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Classic Health screen.
struct PulseHealthspanView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Healthspan"),
            symbol: "hourglass",
            summary: String(localized: "ZENO Age, your Pace of Aging and the pillars behind them."),
            spec: "§3.23",
            group: "health",
            links: [
                .init(title: String(localized: "Classic Health"), symbol: "heart.text.square", route: .classic(.classicHealth))],
            coach: .button)
    }
}
#endif
