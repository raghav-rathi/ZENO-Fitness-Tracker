#if os(iOS)
import SwiftUI

// MARK: - Trends tokens (group "trends")
//
// The few values the Trend View, the Trends tab and the Weekly Digest draw with that the shared theme does
// not carry yet. They live here, in the group's folder, because Theme/ is the foundation's; each names the
// capture it was sampled on so the foundation can promote it unchanged. Everything else these screens draw
// comes from Theme/. Pixel positions are @3x on a 402 pt iPhone (deep-dives-2026/37, 45, 47 are 1206 px
// wide), so 3 px = 1 pt.

extension PulseTheme {
    enum Trends {
        /// The Trend View's metric dropdown card: white ≈7.5% on the page (#363D45 over the page's #262D35,
        /// deep-dives-2026/46, 47; #4C5357 on the brighter Android page of /44).
        static let dropdown = Color.white.opacity(0.075)

        /// The strain breakdown's four shades, All Out (0) to Light (3): strain blue fading toward the page,
        /// as WHOOP steps them (deep-dives-2026/44: #4091E0, #397EC3, #2F6CA3 on an Android capture).
        static func strainShade(_ index: Int) -> Color {
            let opacities: [Double] = [1.0, 0.78, 0.58, 0.4]
            return PulseTheme.strain.opacity(opacities[max(0, min(opacities.count - 1, index))])
        }

        /// How strongly a long range's daily data is drawn under its segments (≈25–30%, §2.7 "6M").
        static let dimmedData: Double = 0.28
        /// A partial week's column (a day of unknown zone time inside it) against a whole week's.
        static let partialOpacity: Double = 0.35

        /// The TYPICAL RANGE band and its legend swatch: #2A2F33 over the page's #14191D–#11161A at the band's
        /// height (deep-dives-2026/37, y 1938–1971 px), white 10.4–10.8% over the page; the swatch is the
        /// band's own colour (#303539, white ≈10% over the page beside it), an 8 pt square 10 pt from its
        /// title (830–853 px, text from 885 px).
        static let typicalBand = Color.white.opacity(0.10)
        static let legendSwatch: CGFloat = 8
        static let legendSwatchGap: CGFloat = 10
        /// A right-aligned legend ends with the band, 6 pt inside the page margin (deep-dives-2026/37: the
        /// legend's text and the band both end at 1140 px).
        static let legendTrailing: CGFloat = 6
        /// The band reaches under the y labels and stops short of the gridlines' end: 25 pt from the left
        /// screen edge to 10 pt before the gridlines end (deep-dives-2026/37: 76 → 1141 px; gridlines
        /// 160 → 1169 px).
        static let typicalBandLeading: CGFloat = 25
        static let typicalBandTrailing: CGFloat = 10

        // MARK: Header

        /// The dropdown's height (deep-dives-2026/47: y 420 → 588 px, 56 pt) and the CTA row's (≈56 pt,
        /// §3.12 item 10).
        static let dropdownHeight: CGFloat = 56
        static let ctaRowHeight: CGFloat = 56

        /// The width the header's range control and pager take at the right: WHOOP's control is 191 pt
        /// (deep-dives-2026/37, 47: 558 → 1134 px), and its five ZENO segments fit it at ≈38 pt each, which
        /// leaves a long headline ("52.0 mL/kg/min") its one row.
        static let rangeColumnWidth: CGFloat = 191
        /// The range column ends 24 pt from the screen edge, 8 pt inside the page margin (deep-dives-2026/37,
        /// 46, 47: the control's and the pager's right edge at 1134 px).
        static let rangeColumnTrailing: CGFloat = 8

        /// The insight sentence starts ≈20 pt from the screen edge (61 px on deep-dives-2026/45, 46, 47).
        static let insightLeading: CGFloat = 4
        /// A footnote's "i" and its text: the glyph centred ≈23.5 pt and the text starting ≈36 pt from the
        /// screen edge (deep-dives-2026/45: "i" at 64–78 px, text from 109 px), so a 15 pt glyph column at
        /// the page margin with 5 pt to the text.
        static let footnoteGlyphColumn: CGFloat = 15
        static let footnoteGap: CGFloat = 5

        // MARK: Chart

        /// The y labels end 33 pt from the screen edge, right-aligned (deep-dives-2026/47: "100%" … "0%" end
        /// at 100–101 px; /37 at 97–101 px), and the plot starts at a FIXED 53 pt for every metric (both
        /// captures' gridlines start at 160 px), so the plot never moves with the width of its labels.
        /// Both are measured from the screen edge; the chart's canvas bleeds into the page margin to draw them.
        /// (The labels' frames end 1.5 pt past their ink, so the frame's edge is 35 for ink at 33.5.)
        static let yLabelTrailing: CGFloat = 35
        static let plotLeading: CGFloat = 53
        /// The gridlines run to 12 pt from the right screen edge (deep-dives-2026/37: 389.7 of 402 pt), 4 pt
        /// past the page margin.
        static let plotTrailingBleed: CGFloat = 4
        /// The columns sit 9 pt inside the gridlines at both ends, W and M alike (deep-dives-2026/47: the
        /// W bars centre on a 45.4 pt pitch with their slots 9.3 and 8.8 pt in; /46: the first M bar's slot
        /// starts 62 pt, 9 pt in, on a 10.35 pt pitch).
        static let columnInset: CGFloat = 9
        /// M's thirty bars are three quarters of their pitch (deep-dives-2026/46: 7.7 pt on a 10.35 pt pitch).
        static let monthBarFraction: CGFloat = 0.75

        /// Corner radii the chart draws with: a bar's rounded top, the AVG. pill and a label's dark plate,
        /// the cycle strip (deep-dives-2026/46, 47, 38).
        static let barTopRadius: CGFloat = 2
        static let pillRadius: CGFloat = 3
        static let phaseStripRadius: CGFloat = 2

        // MARK: Breakdown

        /// The breakdown bar's height and the gap between its parts (deep-dives-2026/46, 47: ≈12 / 3 pt).
        static let breakdownBarHeight: CGFloat = 12
        static let breakdownBarGap: CGFloat = 3
        /// The whole block sits 8 pt inside the page margin (deep-dives-2026/44–47: title, bar and swatches
        /// start at 72 px, the bar ends 20–24 pt from the right).
        static let breakdownInset: CGFloat = 8
        /// The rows' square swatch (deep-dives-2026/47: 72–95 px, 8 pt), the swatch-to-amount gap and the gap
        /// from the widest amount to the band's name ("3x" inks 122–165 px, "Green" from 223 px; the text
        /// frames start ≈1.3 pt before their ink, so 8 and 18 pt) and the rows' pitch (≈27 pt).
        static let breakdownSwatch: CGFloat = 8
        static let breakdownSwatchGap: CGFloat = 8
        static let breakdownNameGap: CGFloat = 18
        static let breakdownRowPitch: CGFloat = 27

        // MARK: Cycle overlay

        /// The overlay's info card: #1D2B36 under recovery blue text and "i" (deep-dives-2026/38: card
        /// #1D2B36, text #63B1FF).
        static let cycleNoteFill = Color(hex: "#1D2B36")

        // MARK: Glyphs (base sizes; views scale them with Dynamic Type through @ScaledMetric)

        /// The dropdown's and the picker's metric icon (≈19 pt light), and the dropdown's "⌄" (15 pt bold).
        static let metricIcon: CGFloat = 19
        static let dropdownChevron: CGFloat = 15
        /// A list row's icon (the Trends rows, the digest's highlights, WHAT CORRELATES): 18 pt.
        static let rowIcon: CGFloat = 18
        /// A CTA row's icon: 20 pt light.
        static let ctaIcon: CGFloat = 20
        /// A footnote's "i" (15 pt) and the cycle card's (17 pt).
        static let footnoteGlyph: CGFloat = 15
        static let cycleNoteGlyph: CGFloat = 17
        /// The range pager's chevrons: 16 pt bold.
        static let pagerChevron: CGFloat = 16
        /// The picker's tick: 15 pt bold.
        static let pickerTick: CGFloat = 15
    }
}
#endif
