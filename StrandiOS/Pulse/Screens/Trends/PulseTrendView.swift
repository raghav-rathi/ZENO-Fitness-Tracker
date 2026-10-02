#if os(iOS)
import SwiftUI

/// Trend View (WHOOP_UI_SPEC §3.12), pushed.
///
/// Owned by group "trends". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Metric detail screen.
struct PulseTrendView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false
    /// The `MetricCatalog` key of the metric to chart.
    let metric: String

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Trend View"),
            symbol: "chart.xyaxis.line",
            summary: String(localized: "One metric over W, M, 6M, 1Y and ALL, with its average, typical range and what changed."),
            spec: "§3.12",
            group: "trends",
            links: [
                .init(title: String(localized: "Metric detail"), symbol: "chart.line.uptrend.xyaxis", route: .tab(.metric(metric)))],
            coach: .button)
    }
}
#endif
