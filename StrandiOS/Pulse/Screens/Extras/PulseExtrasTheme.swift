#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Tokens the extras screens add (group "extras")
//
// The day heart-rate timeline (§3.7), Year in Review (§3.39) and Challenges (§3.41) draw a few surfaces the
// shared theme does not carry yet. Each value is sampled on the reference capture it names, and lives
// here, in the group's own folder, so the screens still never write a hex value inline. The foundation can
// hoist any of them into Theme/ later without the screens changing shape.

enum PulseExtrasTheme {

    /// The expanded day heart-rate timeline (help-center/106, reviews/r132, activity-flows-2026/e04,
    /// all sampled at full resolution).
    enum Timeline {
        /// The top bar ("✕ HEART RATE · ‹ TODAY › · Data synced to 07:44"): #232730 → #21252B.
        static let barTop = Color(hex: "#232730")
        static let barBottom = Color(hex: "#21252B")
        /// The near-black hairlines under the bar and under the label strip.
        static let hairline = Color(hex: "#05070A")
        /// The label strip between the bar and the plot (moon, RECOVERY, STRAIN, the scrub readout).
        static let strip = Color(hex: "#16191E")
        /// The strip fades in from the page over its first 60 pt (r132, e04: #20242D → #16191E).
        static let stripFade: CGFloat = 60
        /// Horizontal gridlines at 40 / 80 / 120 / 160 / 200 (#292D36 on #1D212A: white ≈6%).
        static let grid = Color.white.opacity(0.06)
        /// Heart rate while awake (≈#64676B–#8E9295 on the page).
        static let awakeLine = Color.white.opacity(0.45)
        /// Heart rate during sleep: a lighter sleep blue (#98AFC3).
        static let sleepLine = Color(hex: "#98AFC3")
        /// The sleep band's 2 pt top cap (#86A0B6).
        static let sleepCap = Color(hex: "#86A0B6")
        /// Heart rate inside an activity, and the activity under the cursor (#7CB0E7, lighter).
        static let activityLine = PulseTheme.strain
        static let selectedLine = Color(hex: "#7CB0E7")
        /// An activity band's 2 pt top cap, and the cap of the one under the cursor.
        static let activityCap = Color(hex: "#4091E0")
        static let selectedCap = Color(hex: "#78ADE3")
        /// The bands fade from their top (sleep ≈10%, activity ≈8% of the hue) to ≈2% at the plot's foot.
        static let sleepBandTop = 0.10
        static let activityBandTop = 0.08
        static let bandFoot = 0.02
        /// The column of the activity under the cursor is lit another white ≈4%.
        static let selectedLift = Color.white.opacity(0.04)
        /// The scrub cursor: a white dashed rule and a white dot with a dark ring.
        static let cursor = Color.white
        static let cursorRing = Color(hex: "#14181D")
        /// The y axis WHOOP draws: 0–220 bpm with gridlines every 40 from 40.
        static let bpmDomain: ClosedRange<Double> = 0...220
        static let gridValues: [Double] = [40, 80, 120, 160, 200]

        // Geometry, measured on the landscape captures (r132 on an 844 × 390 screen, e04 on 956 × 440).

        /// The top bar's height, then a 1 pt hairline.
        static let barHeight: CGFloat = 42
        /// The label strip's height (43 → 97), then a 1 pt hairline.
        static let stripHeight: CGFloat = 54
        /// "✕" centres this far inside the side safe-area edge; the title starts 32 pt after it.
        static let closeCentre: CGFloat = 48
        static let titleGap: CGFloat = 32
        /// "Data synced to …" ends this far inside the trailing safe-area edge.
        static let syncTrailing: CGFloat = 33
        /// The y labels end this far inside the leading safe-area edge; the gridlines start 4 pt later.
        static let yLabelTrailing: CGFloat = 18
        static let plotLeading: CGFloat = 22
        /// The day's first instant sits this far into the plot, so its time label clears the y labels.
        static let dataInset: CGFloat = 20
        /// The plot ends this far inside the trailing safe-area edge; the zoom button centres 13 pt in.
        static let plotTrailing: CGFloat = 56
        static let zoomCentre: CGFloat = 13
        /// The x labels centre this far above the bottom safe-area edge; the plot ends 18 pt above them.
        static let xLabelCentre: CGFloat = 12
        static let xLabelGap: CGFloat = 18
        /// The two label rows in the strip, from its top: title / glyph, then value.
        static let stripRow1: CGFloat = 21
        static let stripRow2: CGFloat = 39
        /// Hour labels keep at least this far apart; the day's start and end labels win a collision.
        static let xLabelSpacing: CGFloat = 100
        /// How far ⊕ zooms in: the visible span shrinks to a third (at least two hours stay in view).
        static let zoomFactor: CGFloat = 3
        static let minimumZoomedSpan: TimeInterval = 2 * 3_600
    }
}
#endif
