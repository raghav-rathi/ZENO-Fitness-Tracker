#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Sleep group tokens (WHOOP_UI_SPEC §3.3, §3.11)
//
// The few surfaces, shapes and sizes the Sleep screens draw that no shared token covers yet, kept in ONE
// place in the group's folder so the views themselves write no colour, radius or font size of their own
// (ARCHITECTURE §3: a group extends, it never edits Theme/). They are asked of the foundation to hoist
// into Theme/ unchanged; until then nothing else in the folder spells a value out.

extension PulseTheme {
    /// The Sleep Planner (§3.11).
    enum Planner {
        /// The upper zone's lighter slate over the page gradient: #2F3C44 at the top and #242B33 lower down
        /// on reviews/r134 and r135, the page's own #2A3139 / #22282F plus ≈2.5% white.
        static let upperZone = Color.white.opacity(0.025)
        /// The goal capsule's fill, opaque so the zone's edge does not show through it (#1D2528 inside the
        /// capsule on reviews/r134, the zone's own colour at that height).
        static let capsuleFill = Color(hex: "#1D2528")
        /// The full-width strip the TIME IN BED bar sits in: DARKER than the page (#0C0D11 on #0F1316 at
        /// reviews/r134, #0B0C10 on #0F1316 at r135).
        static let barStrip = Color.black.opacity(0.25)
        /// The hatch between the bed and wake ticks: brighter than a track's (reviews/r134).
        static let barHatch = Color.white.opacity(0.32)
        /// The black capsule holding the time in bed, and its outline.
        static let timeCapsule = Color.black
        /// The drop lines from the two times to the bar, and the optimal bracket.
        static let dropLine = Color.white.opacity(0.5)
        /// "OPTIMAL": recovery blue, greyed (§3.11 item 7).
        static let optimalLabel = PulseTheme.recoveryBlue.opacity(0.8)
        /// My Schedule's ON / OFF chip: white 20% in both states (§3.11 item 1).
        static let scheduleChip = Color.white.opacity(0.20)
        /// The pinned alarm panel, a blue-grey slate lighter at its top (sampled #3A454B → #303B41 on
        /// reviews/r134 and r135); opaque, so the page scrolls under it cleanly.
        static let panelTop = Color(hex: "#38434A")
        static let panelBottom = Color(hex: "#2F3940")
        /// The panel's two tiles: lighter than the panel (#495257) inside a dark hairline.
        static let tileFill = Color.white.opacity(0.09)
        static let tileBorder = Color.black.opacity(0.45)
        /// The panel's top corners: the wheel-sheet tops' radius.
        static let panelRadius: CGFloat = PulseTheme.Radius.menu
        /// The wheel sheet's CANCEL / SAVE buttons (§2.6 item 36: radius 14).
        static let wheelButtonRadius: CGFloat = 14
        /// The corners of My Schedule's calendar glyph.
        static let glyphRadius: CGFloat = 3
    }

    /// The Sleep dive's own shapes and fills (§3.3).
    enum SleepDive {
        /// The 30-night typical-range box over a stage or level bar: a lighter block than the track, under
        /// its dashed sides (#35393C with a #43474A–#494D50 hatch on the #1E2225 card, deep-dives-2026/12).
        static let typicalBoxFill = Color.white.opacity(0.12)
        static let typicalBoxHatch = Color.white.opacity(0.10)
        /// Legend and breakdown swatches.
        static let swatchRadius: CGFloat = 2
        /// The floating bed → wake bars (SLEEP CONSISTENCY, TIME IN BED) and the stacked restorative bars.
        static let rangeBarRadius: CGFloat = 3
        /// The ASLEEP track's ends (SLEEP EFFICIENCY).
        static let asleepTrackRadius: CGFloat = PulseTheme.Radius.toggle
        /// The gap between a stacked bar's REM and Deep segments (deep-dives-2026/08: 1–2 pt, card colour).
        static let segmentGap: CGFloat = 1.5
        /// Where the stress chart's plot starts, past its 0.0–3.0 labels (the shared chart's own label row
        /// starts there too), for the times placed along it.
        static let stressPlotInset: CGFloat = 28
    }
}
#endif
