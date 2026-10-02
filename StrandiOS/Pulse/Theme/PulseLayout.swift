#if os(iOS)
import SwiftUI

// MARK: - Spacing, radii and geometry (WHOOP_UI_SPEC §2.3–2.5, §1.1; DR §3–5)
//
// Reference device 393 × 852 pt. Everything aligns to the 16 pt page margin and the 12 / 16 pt gaps.

extension PulseTheme {

    /// The spacing scale: 4 · 8 · 12 · 16 · 24 · 32 · 40.
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    /// Corner radii. A child's radius is never larger than its parent's.
    enum Radius {
        /// Cards, tiles, pills, the "+" square, the date pager's inner pill, row lists. `.circular`.
        static let card: CGFloat = 12
        /// Nested buttons, the segmented control, onboarding fields.
        static let control: CGFloat = 10
        /// Legend wells, chips, activity score chips; the selected segment.
        static let well: CGFloat = 8
        /// Journal ✕ / ✓ squares, plan day buttons, status pills.
        static let toggle: CGFloat = 6
        /// 24 pt status squares, delta chips.
        static let badge: CGFloat = 4
        /// The action popover, the Smart log card, the coach summary pill, wheel-sheet tops.
        static let menu: CGFloat = 20
        /// Centred dialog cards.
        static let dialog: CGFloat = 15
        /// The floating Coach button's squircle (unconfirmed ≈22).
        static let coachButton: CGFloat = 22
    }

    /// Page and section rhythm.
    enum Layout {
        /// Left and right page margin.
        static let pageMargin: CGFloat = 16
        /// Between side-by-side cards and between stacked tiles or rows.
        static let gridGap: CGFloat = 12
        /// Between different cards inside one section.
        static let stackGap: CGFloat = 16
        /// The 2026 Health tab stacks its cards further apart.
        static let healthStackGap: CGFloat = 24
        /// Inside a card, on every side.
        static let cardPadding: CGFloat = 16
        /// Above a section header (previous block → header).
        static let sectionGap: CGFloat = 32
        /// From a section header to its first card.
        static let headerGap: CGFloat = 12
        /// The bottom content inset on every screen that shows the floating tab bar, the Coach button
        /// or the coach summary pill, so nothing important sits under them (§1.2).
        static let floatingChromeInset: CGFloat = 80
        /// Bottom content inset on a pushed screen with no floating chrome.
        static let plainBottomInset: CGFloat = 32
        /// The scrim above the floating tab bar: content fades to black over this height.
        static let scrimHeight: CGFloat = 28
        /// Hit targets are at least this big; whole cards are tappable.
        static let minTapTarget: CGFloat = 44
    }

    /// Score-dial geometry (§2.5). Stroke = arc = track width; flat ends with ≈1/5-stroke rounding.
    enum Dial {
        /// Home: three 88 pt dials, 6 pt stroke, `HStack(spacing: 33)`.
        static let homeDiameter: CGFloat = 88
        static let homeStroke: CGFloat = 6
        static let homeSpacing: CGFloat = 33
        /// The gap between a Home dial's ring and its "LABEL ›" caption's text frame. The frame starts
        /// ≈2.5 pt above the caps, so the caps land ≈12.5 pt under the ring (spec: 12–13 pt).
        static let labelGap: CGFloat = 10
        /// Deep dive: one 260 pt ring, 15 pt stroke.
        static let heroDiameter: CGFloat = 260
        static let heroStroke: CGFloat = 15
        /// The sticky header's mini rings: 24 pt, 2 pt stroke.
        static let miniDiameter: CGFloat = 24
        static let miniStroke: CGFloat = 2
        /// Corner rounding of the arc's flat ends, as a fraction of the stroke.
        static let cornerFraction: CGFloat = 0.2
        /// The shortest arc drawn for a non-zero value, so a 0.2 strain still shows a sliver.
        static let minimumArc: CGFloat = 2
        /// The Strain target tick's width.
        static let tickWidth: CGFloat = 1
    }

    /// The floating tab capsule and the Coach button (§1.1).
    enum TabBarMetrics {
        static let height: CGFloat = 64
        /// Capsule and Coach button inset from the screen sides.
        static let sideMargin: CGFloat = 12
        /// The capsule's side margins when Coach is off and it stretches to full width.
        static let stretchedMargin: CGFloat = 16
        /// Between the capsule and the Coach button.
        static let coachGap: CGFloat = 12
        static let coachSize: CGFloat = 64
        /// The capsule's bottom edge sits this far BELOW the bottom safe-area edge on Face ID iPhones:
        /// 29 pt above the screen edge on the 393 × 852 reference capture (reviews/02) and 28 pt on a
        /// 2026 Pro Max capture. (The spec's "≈21 pt" matches neither capture.)
        static let belowSafeArea: CGFloat = 5
        /// The capsule's bottom edge above the screen edge on iPhones without a home indicator.
        static let bottomOffsetWithoutIndicator: CGFloat = 12
        /// The capsule's bottom edge above the screen edge for a given bottom safe-area inset.
        static func bottomOffset(safeAreaBottom: CGFloat) -> CGFloat {
            safeAreaBottom > 0 ? max(bottomOffsetWithoutIndicator, safeAreaBottom - belowSafeArea)
                               : bottomOffsetWithoutIndicator
        }
        static let iconSize: CGFloat = 22
        /// The ring around the coach monogram.
        static let coachRing: CGFloat = 32
        /// The Coach button on a pushed screen, inset from the right and bottom safe edges.
        static let floatingCoachSize: CGFloat = 60
        static let floatingCoachInset: CGFloat = 16
    }

    /// Row and tile heights (§2.3).
    enum Row {
        /// More / settings rows, and with a sub-line.
        static let list: CGFloat = 56
        static let listWithSubline: CGFloat = 64
        /// Between More rows.
        static let listGap: CGFloat = 10
        /// Contributor rows inside a callout.
        static let contributorPitch: CGFloat = 53
        /// Time-of-day pills.
        static let pill: CGFloat = 48
        /// Today's Activities rows and dashboard rows.
        static let activity: CGFloat = 56
        static let dashboard: CGFloat = 58
        /// The status / sync banner.
        static let banner: CGFloat = 44
        /// The segmented control.
        static let segmented: CGFloat = 36
        /// In-card buttons.
        static let nestedButton: CGFloat = 44
        /// The legend well under a callout.
        static let legendWell: CGFloat = 31
    }

    // MARK: Compatibility names (the first Pulse screens)

    static let pagePadding: CGFloat = Layout.pageMargin
    static let cardPadding: CGFloat = Layout.cardPadding
    static let cardRadius: CGFloat = Radius.card
    static let sectionSpacing: CGFloat = 24
    static let minTapTarget: CGFloat = Layout.minTapTarget
}
#endif
