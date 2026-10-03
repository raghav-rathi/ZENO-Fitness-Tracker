#if os(iOS)
import SwiftUI

// MARK: - Home's measured sizes (group "home")
//
// The spacings Home measured on WHOOP's captures that the token scale (4 … 40) does not hold, and the SF
// Symbol sizes Home's glyphs use, in one place with where each came from. Glyphs beside text scale with
// Dynamic Type like the text; the art at a card's right is a fixed illustration, like the dials.

/// Home's measured spacings and frames.
enum PulseHomeMetrics {
    /// Today's Activities: the rows 13 pt under the title, the buttons 20 pt under the last row
    /// (help-center/91).
    static let activitiesRowsTop: CGFloat = 13
    static let activitiesButtonsTop: CGFloat = 20
    /// NO SLEEP's outlined ADD SLEEP button (help-center/68).
    static let addSleepHeight: CGFloat = 36

    /// Tonight's Sleep (reviews/r41): the times' row 26 pt tall and 8 pt further from the title than the
    /// card's 14 pt rhythm, SET ALARM 2 pt further from the captions, the dashed connector at most 60 pt.
    static let tonightTimeRow: CGFloat = 26
    static let tonightTimesTop: CGFloat = 8
    static let tonightButtonTop: CGFloat = 2
    static let tonightConnector: CGFloat = 60

    /// My Journal (completeness-critic/16, reviews/r113): 22 pt circles, the strip 20 pt and BEHAVIOR
    /// INSIGHTS 14 pt further down than the card's 14 pt rhythm.
    static let journalCircle: CGFloat = 22
    static let journalStripTop: CGFloat = 20
    static let journalButtonTop: CGFloat = 14

    /// The coaching card's least height (profile-community-2026/34) and its art column.
    static let coachingCardMinHeight: CGFloat = 124
    static let coachingArtWidth: CGFloat = 72
    /// The ✓ counter chip: 24 × 46 pt, 8 pt in from the card's corner (profile-community-2026/34).
    static let counterChip = CGSize(width: 24, height: 46)

    /// A Get Started card's least height (onboarding/31a, §2.6 item 34) and its art column.
    static let getStartedMinHeight: CGFloat = 132
    static let getStartedArtWidth: CGFloat = 76

    /// The STRAIN & RECOVERY chart with its axis labels: a ≈191 pt plot (completeness-critic/13).
    static let strainRecoveryChart: CGFloat = 228

    /// A Customize row's least height (reviews/04).
    static let customizeRow: CGFloat = 57
}

/// Home's SF Symbol sizes.
enum PulseHomeGlyph {
    /// Tonight's sunset / sunrise beside the 22 pt times.
    case tonightSun
    /// The ✓ on the coaching counter chip.
    case counterCheck
    /// A dashboard row's leading icon.
    case dashboardIcon
    /// A Customize row's leading icon.
    case customizeIcon
    /// Customize's "–" and "+" controls.
    case customizeControl
    /// The bar-chart mark on Customize's chart items.
    case chartMark
    /// A Get Started card's "✕".
    case dismiss
    /// The mark leading a My Day pill row (the Year in Review promo), the coach pill's size.
    case pillMark

    private var spec: (size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle) {
        switch self {
        case .tonightSun: return (17, .regular, .body)
        case .counterCheck: return (15, .semibold, .subheadline)
        case .dashboardIcon: return (18, .light, .body)
        case .customizeIcon: return (17, .light, .body)
        case .customizeControl: return (20, .regular, .title3)
        case .chartMark: return (15, .regular, .subheadline)
        case .dismiss: return (12, .bold, .caption)
        case .pillMark: return (18, .light, .body)
        }
    }

    fileprivate var size: CGFloat { spec.size }
    fileprivate var weight: Font.Weight { spec.weight }
    fileprivate var relativeTo: Font.TextStyle { spec.relativeTo }

    /// A fixed illustration glyph (a card's art), which does not scale: it sits in a fixed slot.
    static func art(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }
}

private struct PulseHomeGlyphModifier: ViewModifier {
    let glyph: PulseHomeGlyph
    @ScaledMetric private var size: CGFloat

    init(_ glyph: PulseHomeGlyph) {
        self.glyph = glyph
        _size = ScaledMetric(wrappedValue: glyph.size, relativeTo: glyph.relativeTo)
    }

    func body(content: Content) -> some View {
        content.font(PulseHomeGlyph.art(size, weight: glyph.weight))
    }
}

extension View {
    /// Size an SF Symbol as Home's `glyph`, scaling with Dynamic Type like the text beside it.
    func pulseHomeGlyph(_ glyph: PulseHomeGlyph) -> some View {
        modifier(PulseHomeGlyphModifier(glyph))
    }

    /// A short tappable title row's hit area grown to the 44 pt minimum (DR §3) without moving anything:
    /// the extra reaches into the space around the row, not the layout.
    func pulseHomeHitArea() -> some View {
        let extra = (PulseTheme.Layout.minTapTarget - PulseTextStyle.cardTitle.spec.size * 1.4) / 2
        return padding(.vertical, extra)
            .contentShape(Rectangle())
            .padding(.vertical, -extra)
    }
}
#endif
