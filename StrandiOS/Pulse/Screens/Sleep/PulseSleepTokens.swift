#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Sleep Planner tokens (WHOOP_UI_SPEC §3.11)
//
// The planner's few surfaces that no shared token covers, kept in ONE place in the Sleep group's folder so
// its views write no colour of their own (ARCHITECTURE §3: a group extends, it never edits Theme/). The
// foundation can hoist these into Theme/ unchanged if another group needs them.

extension PulseTheme {
    enum Planner {
        /// The upper zone's lighter slate over the page gradient: #2F3C44 at the top and #242B33 lower down
        /// on reviews/r134 and r135, the page's own #2A3139 / #22282F plus ≈2.5% white.
        static let upperZone = Color.white.opacity(0.025)
        /// The goal capsule's fill, so the zone's edge does not show through it (sampled ≈#23282C).
        static let capsuleFill = PulseTheme.cardSolidBottom
        /// The full-width strip the TIME IN BED bar sits in (a faint band across the screen).
        static let barStrip = Color.white.opacity(0.04)
        /// The hatch between the bed and wake ticks: brighter than a track's (reviews/r134).
        static let barHatch = Color.white.opacity(0.32)
        /// The black capsule holding the time in bed, and its outline.
        static let timeCapsule = Color.black
        /// The drop lines from the two times to the bar, and the optimal bracket.
        static let dropLine = Color.white.opacity(0.5)
        /// "OPTIMAL": recovery blue, greyed (§3.11 item 7).
        static let optimalLabel = PulseTheme.recoveryBlue.opacity(0.8)
        /// The pinned alarm panel, a blue-grey slate lighter at its top (sampled #3A454B → #303B41 on
        /// reviews/r134 and r135); opaque, so the page scrolls under it cleanly.
        static let panelTop = Color(hex: "#38434A")
        static let panelBottom = Color(hex: "#2F3940")
        /// The panel's two tiles: lighter than the panel (#495257) inside a dark hairline.
        static let tileFill = Color.white.opacity(0.09)
        static let tileBorder = Color.black.opacity(0.45)
        /// The panel's top corners.
        static let panelRadius: CGFloat = 20
    }
}
#endif
