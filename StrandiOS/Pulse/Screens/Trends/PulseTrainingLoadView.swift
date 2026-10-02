#if os(iOS)
import SwiftUI

/// Training Load (WHOOP_UI_SPEC §1.8, §3.35), pushed from Trends › INSIGHTS: fitness (CTL), fatigue (ATL)
/// and form (TSB) over time.
///
/// Owned by group "trends". A placeholder until the group rebuilds it. Until then, the shell's existing entry
/// points keep opening the classic Trends screen, which carries the training-load card.
struct PulseTrainingLoadView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Training Load"),
            symbol: "chart.line.uptrend.xyaxis",
            summary: String(localized: "Fitness, fatigue and form from your daily Strain, and how they are moving."),
            spec: "§3.35",
            group: "trends",
            links: [
                .init(title: String(localized: "Trends"), symbol: "chart.line.uptrend.xyaxis", route: .classic(.trends))],
            coach: .button)
    }
}
#endif
