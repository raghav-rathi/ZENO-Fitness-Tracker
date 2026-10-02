#if os(iOS)
import SwiftUI

// MARK: - Tabs and the floating tab capsule (WHOOP_UI_SPEC §1.1)
//
// WHOOP floats a glass capsule of four tabs (Home · Health · Community · More) with a separate Coach
// button to its right. ZENO swaps Community, which needs a server and other people, for Trends. The
// capsule is 64 pt tall, 12 pt from the screen sides, 12 pt from the Coach button and 21 pt above the
// screen's bottom edge; with Coach switched off it stretches to full width with 16 pt margins. iOS 26's
// Liquid Glass is not available to this toolchain, so it uses the spec's material fallback: a #252A30 →
// #191E23 vertical fill at 92% with a top-lit rim. The selected item is white over a soft glow; the
// others are white 50%.

/// Pulse's four tabs, in capsule order. The app always launches on Home.
enum PulseTab: String, CaseIterable, Identifiable, Hashable {
    case home, health, trends, more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return String(localized: "Home")
        case .health: return String(localized: "Health")
        case .trends: return String(localized: "Trends")
        case .more: return String(localized: "More")
        }
    }

    /// Outline SF Symbols, monochrome (WHOOP's glyphs are its own; these are the spec's stand-ins).
    var symbol: String {
        switch self {
        case .home: return "house"
        case .health: return "heart.text.square"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .more: return "line.3.horizontal"
        }
    }
}

/// The floating capsule of tabs.
struct PulseTabBar: View {
    let tabs: [PulseTab]
    let selection: PulseTab
    let onSelect: (PulseTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                item(tab)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: PulseTheme.TabBarMetrics.height)
        .background(
            LinearGradient(gradient: PulseTheme.TabBar.fill, startPoint: .top, endPoint: .bottom)
                .opacity(PulseTheme.TabBar.fillOpacity))
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(LinearGradient(gradient: PulseTheme.TabBar.rim, startPoint: .top, endPoint: .bottom),
                              lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private func item(_ tab: PulseTab) -> some View {
        let selected = tab == selection
        return Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 20, weight: .regular))
                    .frame(height: PulseTheme.TabBarMetrics.iconSize)
                Text(tab.title)
                    .pulseText(.tabLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? PulseTheme.TabBar.selected : PulseTheme.TabBar.unselected)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(alignment: .bottom) {
                if selected {
                    // The soft blob under the selected item, brightest at the capsule's bottom edge.
                    RadialGradient(colors: [PulseTheme.TabBar.selectedGlow, PulseTheme.TabBar.selectedGlow.opacity(0)],
                                   center: .bottom, startRadius: 0, endRadius: 34)
                        .scaleEffect(x: 1.4, y: 1, anchor: .bottom)
                        .frame(height: PulseTheme.TabBarMetrics.height)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// The bottom row of a tab root: the capsule plus, while Coach is on, the Coach button to its right.
struct PulseBottomChrome: View {
    let tabs: [PulseTab]
    let selection: PulseTab
    let coach: PulseCoachAvailability
    let onSelect: (PulseTab) -> Void
    let onCoach: () -> Void

    var body: some View {
        HStack(spacing: PulseTheme.TabBarMetrics.coachGap) {
            PulseTabBar(tabs: tabs, selection: selection, onSelect: onSelect)
            if coach != .off {
                PulseCoachButton(action: onCoach)
            }
        }
        .padding(.horizontal, coach == .off ? PulseTheme.TabBarMetrics.stretchedMargin : PulseTheme.TabBarMetrics.sideMargin)
    }
}
#endif
