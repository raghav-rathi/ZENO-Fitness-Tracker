#if os(iOS)
import SwiftUI

/// The Trends tab ("TRENDS"), ZENO's replacement for WHOOP's Community tab (WHOOP_UI_SPEC §1.1, §3.35):
/// a THIS WEEK summary, metric rows by pillar opening the Trend View, and the analysis extras.
///
/// Owned by group "trends". Until it is rebuilt it shows the placeholder body and links to the screens
/// that already cover this ground, so the tab never dead-ends.
struct PulseTrendsTabView: View {
    /// Flip to true once the tab is rebuilt; NavRouter's "open Trends" then lands on the tab itself
    /// instead of pushing the classic Trends screen onto it.
    static let isRebuilt = false

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Trends"), role: .tabRoot,
                            refresh: { await model.refresh() }) {
            PulseCard {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .accessibilityHidden(true)
                    Text(String(localized: "Trends is being rebuilt"))
                        .pulseText(.cardHeadline)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "This tab will gather your week, every metric's Trend View and ZENO's analysis tools. Until then, the current screens are one tap away."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            PulseListSectionHeader(String(localized: "Insights"))
                .padding(.top, 8)
            VStack(spacing: PulseTheme.Row.listGap) {
                link(String(localized: "Weekly Digest"), "calendar", .weeklyDigest)
                link(String(localized: "Trend View"), "chart.xyaxis.line", .trendView(metric: "hrv"))
                link(String(localized: "Trends"), "chart.line.uptrend.xyaxis", .classic(.trends))
                link(String(localized: "What moves you"), "wand.and.sparkles", .classic(.insightsHub))
                link(String(localized: "Explore"), "square.grid.2x2", .classic(.explore))
                link(String(localized: "Compare"), "rectangle.split.2x1", .classic(.compare))
                link(String(localized: "Training load"), "chart.line.uptrend.xyaxis", .trainingLoad)
                link(String(localized: "Tomorrow's Recovery"), "brain.head.profile", .classic(.intelligence))
                Button { navigator.present(.classic(.report)) } label: {
                    PulseListRow(symbol: "doc.richtext", title: String(localized: "Report"))
                }
                .buttonStyle(PulsePressStyle())
            }
        }
    }

    private func link(_ title: String, _ symbol: String, _ route: PulseRoute) -> some View {
        PulseLink(route) {
            PulseListRow(symbol: symbol, title: title)
        }
        .buttonStyle(PulsePressStyle())
    }
}
#endif
