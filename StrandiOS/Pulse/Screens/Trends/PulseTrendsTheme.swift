#if os(iOS)
import SwiftUI

// MARK: - Trends tokens (group "trends")
//
// The few values the Trend View, the Trends tab and the Weekly Digest draw with that the shared theme does
// not carry yet. They live here, in the group's folder, because Theme/ is the foundation's; each names the
// capture it was sampled on so the foundation can promote it unchanged. Everything else these screens draw
// comes from Theme/.

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

        /// The breakdown bar's height and the gap between its parts (deep-dives-2026/46, 47: ≈12 / 3 pt).
        static let breakdownBarHeight: CGFloat = 12
        static let breakdownBarGap: CGFloat = 3
        /// The breakdown rows' square swatch (≈9 pt) and pitch (≈27 pt).
        static let breakdownSwatch: CGFloat = 9
        static let breakdownRowPitch: CGFloat = 27

        /// The dropdown's height (≈56 pt, §3.12 item 2) and the CTA row's (≈56 pt, item 10).
        static let dropdownHeight: CGFloat = 54
        static let ctaRowHeight: CGFloat = 56

        /// The width the header's range control and pager take at the right (deep-dives-2026/47: the
        /// three-segment control is ≈191 pt; five segments need a little more).
        static let rangeColumnWidth: CGFloat = 206
    }
}
#endif
