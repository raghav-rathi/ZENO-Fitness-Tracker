#if os(iOS)
import SwiftUI

// MARK: - Sleep Planner tokens (WHOOP_UI_SPEC §3.11)
//
// The planner's few surfaces that no shared token covers, kept in ONE place in the Sleep group's folder so
// its views write no colour of their own (ARCHITECTURE §3: a group extends, it never edits Theme/). The
// foundation can hoist these into Theme/ unchanged if another group needs them.

extension PulseTheme {
    enum Planner {
        /// The upper zone's lighter slate: white ≈6% over the page gradient (reviews/r134, help-center/86).
        static let upperZone = Color.white.opacity(0.06)
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
        /// The pinned alarm panel (opaque, so the page scrolls under it cleanly).
        static let panel = PulseTheme.cardSolidMiddle
        /// The panel's two tiles: the nested fill and a hairline outline.
        static let tileFill = PulseTheme.nested
        static let tileBorder = Color.white.opacity(0.18)
        /// The panel's top corners.
        static let panelRadius: CGFloat = 20
    }
}
#endif
