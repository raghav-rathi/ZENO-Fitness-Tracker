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

    /// Year in Review (completeness-critic/08-11, profile-community-2026/45-53, sampled at full size).
    enum Story {
        /// The near-black page every slide sits on (#07080D).
        static let page = PulseTheme.Gradients.yearInReviewPage
        /// The glows rising from the foot of a slide: red (#5C1118 at the foot of /10), indigo (#3E3F5D,
        /// /45), green (#2B5338, /47) from the theme, and three more sampled here: the steps slide's blue
        /// (#013F64, /50), the second persona's purple (#563A66, /48) and the behaviour slide's slate
        /// (#141D23, /11).
        static let glowRed = PulseTheme.Gradients.yearInReviewGlowRed
        static let glowIndigo = PulseTheme.Gradients.yearInReviewGlowIndigo
        static let glowGreen = PulseTheme.Gradients.yearInReviewGlowGreen
        static let glowBlue = Color(hex: "#0B3D60")
        static let glowPurple = Color(hex: "#4E3560")
        static let glowSlate = Color(hex: "#141D23")
        /// The glow starts rising at this fraction of the height.
        static let glowStart = 0.5
        /// The year beside the wordmark: italic Bold, #758FFE → #5CBEFF.
        static let year = PulseTheme.Gradients.yearInReviewYear
        static let yearSize: CGFloat = 20
        static let wordmark = CGSize(width: 84, height: 14)

        /// The progress segments at the foot: done and current white, upcoming white 30%; the current one
        /// is long (the story does not auto-advance, so it is shown full rather than filling).
        static let segmentDone = Color.white
        static let segmentUpcoming = Color.white.opacity(0.30)
        static let segmentHeight: CGFloat = 3
        static let segmentWidth: CGFloat = 8
        static let segmentCurrentWidth: CGFloat = 26
        static let segmentGap: CGFloat = 4

        /// The month ruler (a comb of ticks with an orb on the month) and the orb.
        static let rulerTick = Color.white.opacity(0.22)
        static let rulerMajorTick = Color.white.opacity(0.40)
        static let orbFill = Color(hex: "#0B0C11")
        static let orbRing = Color.white.opacity(0.85)
        static let orbSize: CGFloat = 44

        /// The moment card: a dark outer frame around a stroked shield (/10: #0B0C11 frame, 3 pt rim).
        static let cardFill = Color(hex: "#111216")
        static let cardRim = Color.white.opacity(0.08)
        static let cardSize = CGSize(width: 236, height: 258)
        static let cardTopRadius: CGFloat = 36
        static let cardBottomRadius: CGFloat = 112
        static let shieldInset: CGFloat = 13
        static let shieldStroke: CGFloat = 3

        /// Type sizes (they scale with Dynamic Type from these): the sentence at the foot of a slide
        /// (≈26 pt in WHOOP's face, 24 Medium in SF Pro), a slide's title, its caption.
        static let sentenceSize: CGFloat = 24
        static let titleSize: CGFloat = 22
        static let headlineSize: CGFloat = 26
        static let bigNumberSize: CGFloat = 96
        static let stepsNumberSize: CGFloat = 104
        static let momentValueSize: CGFloat = 58

        /// The steps figure's blue (/50: #1A6EB0 at the top of the digits to #0B4C7C at their foot).
        static let stepsTop = Color(hex: "#2A7CC0")
        static let stepsBottom = Color(hex: "#0B4C7C")
        static let mountain = Color(hex: "#8C8F95")

        /// Behaviour bars (/11): helps teal, hurts orange, brightest for the largest effect; tall for
        /// large effects, short for small ones; labels 11 pt Bold caps inside, values at the right.
        static let barTall: CGFloat = 84
        static let barShort: CGFloat = 42
        static let barRadius: CGFloat = 10
        static let barMinimumWidth = 0.32

        /// Persona titles (/47 #73F88B green, /48 #D87DF6 purple) and the card's frame.
        static let personaGreen = Color(hex: "#73F88B")
        static let personaPurple = Color(hex: "#D87DF6")
        static let personaCardRim = Color.white.opacity(0.10)
        /// The card's height and side margins (/47: 323 × 486 pt on a 393 pt screen).
        static let personaCardHeight: CGFloat = 480
        static let personaCardMargin: CGFloat = 34
        static let personaCardFill = Color(hex: "#0C1012")
        static let personaWave = Color.white.opacity(0.07)

        /// The summary share card's surfaces (/09): the stat card and the row cards.
        static let summaryCard = Color.white.opacity(0.06)
        static let summaryRow = Color.white.opacity(0.07)
        static let summaryRowIcon = Color(hex: "#C9A15A")
    }

    /// Challenges (profile-community-2026/13, 42, 76, 84, sampled at full size).
    enum Challenge {
        /// The tick gauge: 292 pt across, 270° from the lower left to the lower right, 120 radial ticks
        /// 20 pt long; lit ticks run from the challenge's colour to white at the head, unlit ones are grey.
        static let gaugeDiameter: CGFloat = 292
        static let gaugeSweep: Double = 270
        static let tickCount = 120
        static let tickLength: CGFloat = 20
        static let tickWidth: CGFloat = 2.6
        static let unlitTick = Color.white.opacity(0.20)
        static let unlitTickInner = Color.white.opacity(0.05)
        /// A soft light behind the gauge's centre (#7A7E81 at the top of /76's gauge).
        static let gaugeGlow = Color.white.opacity(0.07)
        /// The value in the gauge: 66 pt Bold condensed over "/250" at 28.
        static let valueSize: CGFloat = 66
        static let targetSize: CGFloat = 28
        /// The page's top light (/76: #929699 at the top centre, tinted by the challenge's colour at the sides).
        static let topLight = Color.white.opacity(0.32)
        static let topTint = 0.32
        /// The day list's card (#282C2F on the page, white ≈8%) with its pointer, and its rows (+10%).
        static let listCard = Color.white.opacity(0.08)
        static let pointer = CGSize(width: 18, height: 9)
        /// The pinned button's line: it shares the floating Coach button's row.
        static let buttonHeight: CGFloat = 50
    }
}

/// A Dynamic Type-scaled SF Pro font for the extras screens' story sizes, which the shared type scale
/// does not carry (`PulseTextStyle` covers everything else).
struct ExtrasScaledFont: ViewModifier {
    let weight: Font.Weight
    let italic: Bool
    let condensed: Bool
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle, italic: Bool = false,
         condensed: Bool = false) {
        self.weight = weight
        self.italic = italic
        self.condensed = condensed
        _size = ScaledMetric(wrappedValue: size, relativeTo: relativeTo)
    }

    func body(content: Content) -> some View {
        var font = Font.system(size: size, weight: weight)
        if condensed { font = font.width(.condensed).monospacedDigit() }
        if italic { font = font.italic() }
        return content.font(font)
    }
}

extension View {
    /// SF Pro at `size`, scaling with Dynamic Type relative to `relativeTo`.
    func extrasFont(_ size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle = .body,
                    italic: Bool = false, condensed: Bool = false) -> some View {
        modifier(ExtrasScaledFont(size: size, weight: weight, relativeTo: relativeTo, italic: italic,
                                  condensed: condensed))
    }
}
#endif
