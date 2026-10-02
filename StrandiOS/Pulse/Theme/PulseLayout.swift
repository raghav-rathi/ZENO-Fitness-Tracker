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
        /// The floating Coach button's squircle: the corner insets measured 2 / 6 / 10 pt above the
        /// bottom edge (14.0–14.7 / 8.0–8.3 / 4.7 pt on 2026 captures) fit r ≈ 24.
        static let coachButton: CGFloat = 24
        /// The floating coach summary pill (deep-dives-2026/56: ≈22–24).
        static let coachPill: CGFloat = 22
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
        /// Above a section header's TEXT FRAME, so its caps land 40 pt below the previous block
        /// (DR §3): a 20 pt title's caps start ≈5 pt into its frame. `PulseSectionHeader` hugs its title,
        /// so this holds whatever accessory it carries.
        static let sectionGap: CGFloat = 35
        /// From a section header's text frame to its first card, so the card starts 24 pt below the
        /// title's baseline (DR §3): the frame ends ≈4.5 pt under the baseline.
        static let headerGap: CGFloat = 19
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
        /// Home: three 88 pt dials, 6 pt stroke, each centred in one of three EQUAL columns between the
        /// page margins (WHOOP's row: the gap is 33.7 pt on a 393 pt screen, 36.3 on 402, 49 on 440).
        static let homeDiameter: CGFloat = 88
        static let homeStroke: CGFloat = 6
        /// The gap between rings on the 393 pt reference screen; layout uses equal columns, not this.
        static let homeSpacing: CGFloat = 33
        /// A dial's column on the reference screen (ring + gap): the label never grows wider.
        static let homeColumn: CGFloat = homeDiameter + homeSpacing
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
        /// The Strain Target tick's width (FWHM 1.9–2.3 pt on 2026 captures).
        static let tickWidth: CGFloat = 2
        /// The hero ring's label: 12.5 pt caps, wrapping onto two lines past this width
        /// ("SLEEP / PERFORMANCE", deep-dives-2026/56).
        static let heroLabelMaxWidth: CGFloat = 116
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
        /// 28 pt above the screen edge on 2026 captures (reviews/r02, completeness-critic/13).
        /// (The spec's "≈21 pt" matches no capture.)
        static let belowSafeArea: CGFloat = 6
        /// The capsule's bottom edge above the screen edge on iPhones without a home indicator.
        static let bottomOffsetWithoutIndicator: CGFloat = 12
        /// The capsule's bottom edge above the screen edge for a given bottom safe-area inset.
        static func bottomOffset(safeAreaBottom: CGFloat) -> CGFloat {
            safeAreaBottom > 0 ? max(bottomOffsetWithoutIndicator, safeAreaBottom - belowSafeArea)
                               : bottomOffsetWithoutIndicator
        }
        static let iconSize: CGFloat = 22
        /// The ring around the coach monogram, and its stroke (1.33 pt on 2026 captures).
        static let coachRing: CGFloat = 32
        static let coachRingWidth: CGFloat = 1.33
        /// The Coach button on a pushed screen: the SAME 64 pt button in the same place as on a tab
        /// root (12 pt from the right edge, its bottom `bottomOffset` above the screen edge), so it never
        /// jumps on push (deep-dives-2026/57, reviews/r119).
        static let floatingCoachSize: CGFloat = 64
        static let floatingCoachInset: CGFloat = 12
        /// The coach summary pill's side margins (deep-dives-2026/56: x 11.7–389.7 on 402 pt).
        static let pillSideMargin: CGFloat = 12
    }

    /// Row and tile heights (§2.3).
    enum Row {
        /// More / settings rows, and with a sub-line.
        static let list: CGFloat = 56
        static let listWithSubline: CGFloat = 64
        /// Between More rows.
        static let listGap: CGFloat = 10
        /// Contributor rows inside a callout: 66 pt on every 2026 capture (deep-dives-2026/17b, 56, 57;
        /// the 2025 App Store mock's 53 is the old build).
        static let contributorPitch: CGFloat = 66
        /// Time-of-day pills.
        static let pill: CGFloat = 48
        /// Today's Activities rows and dashboard rows.
        static let activity: CGFloat = 56
        static let dashboard: CGFloat = 58
        /// The status / sync banner.
        static let banner: CGFloat = 44
        /// The segmented control.
        static let segmented: CGFloat = 36
        /// In-card buttons: drawn 40 pt tall (completeness-critic/25), hit-tested at 44.
        static let nestedButton: CGFloat = 40
        /// The legend well under a callout.
        static let legendWell: CGFloat = 31
    }

    /// The Home header and the navigation bar (§1.4, §1.5), measured on 2026 captures.
    enum Header {
        /// Home's header row: 32 pt from the safe-area top, so the row centres at safe top + 16
        /// (reviews/r41: avatar, streak pill and pager all centre at 77.5–78 on a 62 pt safe top).
        static let homeRow: CGFloat = 32
        /// From the header row to the wordmark, so the wordmark centres at safe top + 69.
        static let wordmarkTop: CGFloat = 31
        /// From the wordmark to the rings: their top lands at safe top + 99.
        static let dialsTop: CGFloat = 24
        /// The avatar and the streak pill's height.
        static let avatar: CGFloat = 31
        /// The strap glyph's right edge from the screen edge (reviews/r41: 23 pt).
        static let strapTrailing: CGFloat = 23
        /// A pushed screen's bar: a 44 pt row whose centre sits 23.5 pt below the safe-area top
        /// (deep-dives-2026/56, 17b: the title centres at 85.5 on a 62 pt safe top).
        static let navBar: CGFloat = 44
        static let navBarTop: CGFloat = 1.5
        /// The back chevron's glyph: thin, 12 × 22 pt, its left edge 32 pt from the screen edge.
        static let backChevron = CGSize(width: 12, height: 22)
        /// The sticky mini-ring row centres this far below the safe-area top (journal-plan-2026/32).
        static let stickyRowCentre: CGFloat = 19.5
        /// Below a pinned bar or row, content fades in over this height rather than meeting a hard edge
        /// (deep-dives-2026/18: ≈20 pt under the nav bar; journal-plan-2026/32: ≈56 pt under the
        /// sticky rings).
        static let barFade: CGFloat = 24
        static let stickyFade: CGFloat = 48
    }

    // MARK: Compatibility names (the first Pulse screens)

    static let pagePadding: CGFloat = Layout.pageMargin
    static let cardPadding: CGFloat = Layout.cardPadding
    static let cardRadius: CGFloat = Radius.card
    static let sectionSpacing: CGFloat = 24
    static let minTapTarget: CGFloat = Layout.minTapTarget
}
#endif
