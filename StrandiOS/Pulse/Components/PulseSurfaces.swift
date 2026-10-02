#if os(iOS)
import SwiftUI

// MARK: - Page and card surfaces (WHOOP_UI_SPEC §2.1, §2.6 item 1)

/// The page background: the slate gradient, viewport-fixed and edge to edge. Put it BEHIND a scroll view
/// (`.background(PulseBackground())`), never inside one.
struct PulseBackground: View {
    enum Style {
        /// The standard slate gradient.
        case gradient
        /// Near-black, for the Healthspan detail and the Health tab top, where an orb's glow must read.
        case nearBlack
    }

    var style: Style = .gradient

    var body: some View {
        Group {
            switch style {
            case .gradient:
                LinearGradient(stops: PulseTheme.pageStops, startPoint: .top, endPoint: .bottom)
            case .nearBlack:
                PulseTheme.pageNearBlack
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Which surface a card is drawn with. All are white or black overlays, never solid greys.
enum PulseCardStyle: Equatable {
    /// White 10%: cards, tiles, rows.
    case standard
    /// White ≈4.5%: the "Last Night's Sleep" group only.
    case detail
    /// White ≈7.5%: the coaching card.
    case coaching
    /// Another 10% on top of a card: in-card buttons, activity rows, a selected segment.
    case nested
    /// Black 50%: legend wells, segmented troughs.
    case well
    /// Black 100%: the status banners and the "Ask a question" well.
    case banner
    /// The More / settings row card (a faint vertical gradient).
    case rowCard
    /// Transparent with a 1 pt grey border: a locked card.
    case outlined
    /// An explicit fill, for the few spec'd one-offs (`PulseTheme.Plan.collapsedCard`, …).
    case solid(Color)
}

/// A card's fill (and, for `.outlined`, its border) on its own, for rows that are buttons themselves.
struct PulseCardSurface: View {
    var style: PulseCardStyle = .standard
    var radius: CGFloat = PulseTheme.Radius.card

    init(_ style: PulseCardStyle = .standard, radius: CGFloat = PulseTheme.Radius.card) {
        self.style = style
        self.radius = radius
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .circular)
        switch style {
        case .standard: shape.fill(PulseTheme.card)
        case .detail: shape.fill(PulseTheme.detail)
        case .coaching: shape.fill(PulseTheme.coachingCard)
        case .nested: shape.fill(PulseTheme.nested)
        case .well: shape.fill(PulseTheme.well)
        case .banner: shape.fill(PulseTheme.bannerWell)
        case .rowCard:
            shape.fill(LinearGradient(colors: [PulseTheme.rowCardTop, PulseTheme.rowCardBottom],
                                      startPoint: .top, endPoint: .bottom))
        case .outlined: shape.strokeBorder(PulseTheme.outlinedBorder, lineWidth: 1)
        case .solid(let color): shape.fill(color)
        }
    }
}

/// A card: white 10% on the page gradient, 12 pt circular corners, 16 pt padding, no border, no shadow.
///
///     PulseCard { Text("…") }
///     PulseCard(.detail, padding: 0) { rows }
struct PulseCard<Content: View>: View {
    var style: PulseCardStyle = .standard
    var padding: CGFloat = PulseTheme.Layout.cardPadding
    var radius: CGFloat = PulseTheme.Radius.card
    @ViewBuilder var content: () -> Content

    init(_ style: PulseCardStyle = .standard,
         padding: CGFloat = PulseTheme.Layout.cardPadding,
         radius: CGFloat = PulseTheme.Radius.card,
         @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.padding = padding
        self.radius = radius
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PulseCardSurface(style, radius: radius))
    }
}

extension View {
    /// Draw this view on a card surface (no padding added).
    func pulseCardBackground(_ style: PulseCardStyle = .standard,
                             radius: CGFloat = PulseTheme.Radius.card) -> some View {
        background(PulseCardSurface(style, radius: radius))
    }
}

/// A 1 pt divider (white 10%), optionally inset from the leading edge.
struct PulseDivider: View {
    var leadingInset: CGFloat = 0
    var trailingInset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(PulseTheme.divider)
            .frame(height: 1)
            .padding(.leading, leadingInset)
            .padding(.trailing, trailingInset)
            .accessibilityHidden(true)
    }
}

/// Instant press feedback with no animation loop: content dims to 70% on touch-down and returns over
/// 0.15 s (DR §8). The whole label is the hit area.
struct PulsePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(configuration.isPressed ? nil : PulseMotion.pressRelease, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
#endif
