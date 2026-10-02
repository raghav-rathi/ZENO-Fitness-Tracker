#if os(iOS)
import SwiftUI

/// Stress Monitor (WHOOP_UI_SPEC §3.22), pushed.
///
/// Owned by group "health". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Stress screen.
struct PulseStressMonitorView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Stress Monitor"),
            symbol: "gauge.with.dots.needle.33percent",
            summary: String(localized: "Stress through the day on the 0 to 3 scale, with your calm and active periods."),
            spec: "§3.22",
            group: "health",
            links: [
                .init(title: String(localized: "Stress"), symbol: "gauge.with.dots.needle.33percent", route: .classic(.stress))],
            coach: .button)
    }
}
#endif
