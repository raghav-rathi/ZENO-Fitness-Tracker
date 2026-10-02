#if os(iOS)
import SwiftUI

// MARK: - Tabs and the floating tab capsule (WHOOP_UI_SPEC §1.1)
//
// WHOOP floats a glass capsule of four tabs (Home · Health · Community · More) with a separate Coach
// button to its right. ZENO swaps Community, which needs a server and other people, for Trends. The
// capsule is 64 pt tall, 12 pt from the screen sides, 12 pt from the Coach button and 28 pt above the
// screen's bottom edge (6 pt below the bottom safe area); with Coach switched off it stretches to full
// width with 16 pt margins. iOS 26's Liquid Glass is not available to this toolchain, so it uses the
// spec's material fallback: an opaque #252A30 → #191E23 vertical fill with no outline rim, lit only by a
// specular highlight at its leading end. Items are a 22 pt glyph over an 11 pt label; the selected one is
// white over a soft glow, the others white 55%.

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
            // The glass's specular edge: lit at the leading end and along the top-left only.
            Capsule(style: .continuous)
                .strokeBorder(LinearGradient(gradient: PulseTheme.TabBar.highlight, startPoint: .leading,
                                             endPoint: .trailing), lineWidth: 1)
                .mask(LinearGradient(colors: [Color.black, Color.black.opacity(0.6), Color.clear],
                                     startPoint: .top, endPoint: .bottom))
                .allowsHitTesting(false))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .contain)
    }

    private func item(_ tab: PulseTab) -> some View {
        let selected = tab == selection
        return Button {
            onSelect(tab)
        } label: {
            VStack(spacing: 5) {
                PulseTabGlyph(tab: tab)
                    .frame(height: PulseTheme.TabBarMetrics.iconSize)
                Text(tab.title)
                    .pulseText(.tabLabel)
                    .lineLimit(1)
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
        // The capsule stops growing at xxxLarge; a long press shows the item large for low vision.
        .accessibilityShowsLargeContentViewer {
            Label(tab.title, systemImage: tab.symbol)
        }
    }
}

/// A tab's 22 pt glyph. More is drawn: three 1.3 pt lines on a 7 pt pitch, 22 × 15 pt (2026 captures),
/// where `line.3.horizontal` is squat (≈20 × 10).
private struct PulseTabGlyph: View {
    let tab: PulseTab

    var body: some View {
        if tab == .more {
            Canvas { context, size in
                var p = Path()
                for i in 0..<3 {
                    let y = 0.65 + CGFloat(i) * 7
                    p.move(to: CGPoint(x: 0.65, y: y))
                    p.addLine(to: CGPoint(x: size.width - 0.65, y: y))
                }
                context.stroke(p, with: .foreground, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            }
            .frame(width: 22, height: 15.3)
        } else {
            Image(systemName: tab.symbol)
                .font(.system(size: PulseTheme.TabBarMetrics.iconSize, weight: .light))
        }
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
