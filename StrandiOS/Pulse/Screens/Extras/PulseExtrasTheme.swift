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
        /// Heart rate while awake: the brightest pixel per column of the line measures #63676A on r132 and
        /// #606367 on e04, white ≈30% on the plot (the spec's text says 50%, which renders #7D8081).
        static let awakeLine = Color.white.opacity(0.30)
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
        /// The bar's content (✕, HEART RATE, ‹ TODAY ›, the sync line) centres this far below its top, not at
        /// its middle: HEART RATE's caps sit at 11.3–19.7 pt on r132 and e04.
        static let barContentCentre: CGFloat = 15.5
        /// The label strip's height (43 → 97), then a 1 pt hairline.
        static let stripHeight: CGFloat = 54
        /// The bar's "✕" and pager chevrons, heavier than a nav bar's (r132: ✕ ≈15 pt across, ‹ ≈16 pt tall).
        static let barCloseSize: CGFloat = 19
        static let barChevronSize: CGFloat = 17
        /// The pager's label sits this far from each chevron's 36 pt frame (r132: 19.4 pt from ‹ to TODAY).
        static let pagerLabelPadding: CGFloat = 3.5
        static let pagerChevronWidth: CGFloat = 36
        /// A pager chevron with nowhere to go (r132's "›" on today: #505559 on the bar, white ≈20%).
        static let pagerDisabled = Color.white.opacity(0.20)
        /// The portrait stack's pager chevrons, the nav bar's weight.
        static let portraitChevronSize: CGFloat = 14
        /// "✕" centres this far inside the side safe-area edge; the title starts 32 pt after it.
        static let closeCentre: CGFloat = 48
        static let titleGap: CGFloat = 32
        /// "Data synced to …" ends this far inside the trailing safe-area edge.
        static let syncTrailing: CGFloat = 33
        /// The y labels end this far before the plot (18 pt inside the leading safe-area edge in landscape),
        /// right-aligned in a frame this wide.
        static let yLabelGap: CGFloat = 4
        static let yLabelWidth: CGFloat = 40
        static let plotLeading: CGFloat = 22
        /// The day's first instant sits this far into the plot, so its time label clears the y labels.
        static let dataInset: CGFloat = 20
        /// The plot ends this far inside the trailing safe-area edge; the zoom button centres 13 pt in.
        static let plotTrailing: CGFloat = 56
        static let zoomCentre: CGFloat = 13
        /// ⊕ / ⊖ (e04: ≈21 pt across).
        static let zoomGlyphSize: CGFloat = 21
        /// The x labels centre this far above the bottom safe-area edge; the plot ends 18 pt above them.
        static let xLabelCentre: CGFloat = 12
        static let xLabelGap: CGFloat = 18
        /// Text in the strip and under the plot keeps this far inside the screen's side safe-area edges, so no
        /// label is ever cut by the edge (DR §9).
        static let labelInset: CGFloat = 16
        /// The two label rows in the strip, from its top: a marker's caption, then the values.
        static let stripRow1: CGFloat = 21
        static let stripRow2: CGFloat = 39
        /// A period's glyph sits higher than a marker's caption, its foot on the caption's baseline (r132: the
        /// moon is 15 pt tall at 50.3–65.3 pt, 15 pt below the strip's top).
        static let stripGlyphCentre: CGFloat = 15
        static let stripGlyphSize: CGFloat = 17
        /// The strip's values: 15 pt Bold condensed (r132: "7:29", "65%", "4.2" caps 10.3 pt tall).
        static let stripValueSize: CGFloat = 15
        /// Two strip labels keep at least this far apart.
        static let stripLabelGap: CGFloat = 10
        /// The scrub readout's frame width, and its "bpm" (e04: "115 bpm" with a smaller unit).
        static let readoutWidth: CGFloat = 90
        static let readoutUnitSize: CGFloat = 12
        /// Hour labels keep at least this far apart; the day's start and end labels win a collision.
        static let xLabelSpacing: CGFloat = 100
        /// Any two time labels keep at least this far apart, edge to edge.
        static let xLabelMinimumGap: CGFloat = 12
        /// The portrait page's nudge to turn the phone: its glyph.
        static let hintGlyphSize: CGFloat = 15
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
        static let shieldStroke: CGFloat = 4.5

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
        /// The tick gauge, measured at 3x on profile-community-2026/13, 76 and 84 (all 402 pt wide): a comb
        /// 290 pt across sweeping 250°, its ends at ±125° (its lowest tick 229.5 pt below its top), of 110
        /// radial ticks ≈4.5 pt wide with ≈1 pt gaps.
        static let gaugeDiameter: CGFloat = 290
        static let gaugeSweep: Double = 250
        /// The share of the circle's height the comb reaches down to (its ends at 125°): 1/2 + cos 55°/2.
        static let gaugeVisibleHeight: CGFloat = 0.787
        static let tickCount = 110
        static let tickWidth: CGFloat = 4.5
        /// Each tick is a bright 10 pt head at the rim over a 30 pt tail that fades out toward the centre (13:
        /// head 56–65 pt, tail to ≈96 pt along the gauge's centre line); the tail starts at this share of its
        /// head's opacity.
        static let tickHead: CGFloat = 10
        static let tickTail: CGFloat = 30
        static let tailStart = 0.45
        /// Lit ticks run from the challenge's colour at the start toward white at the progress head (76, 13).
        static let litWhiteStart = 0.15
        static let litWhiteEnd = 0.85
        /// Ticks not lit yet: white 20%.
        static let unlitTick = Color.white.opacity(0.20)
        /// The join page previews the whole comb in grey (84: heads #818588–#9A9EA2 over its top light,
        /// luminance ≈130 against the in-progress page's unlit ≈77): white 50% heads, tails from 15%.
        static let previewTick = Color.white.opacity(0.50)
        static let previewTail = Color.white.opacity(0.15)
        /// A soft light behind the gauge's centre (#7A7E81 at the top of /76's gauge).
        static let gaugeGlow = Color.white.opacity(0.07)
        /// The value in the gauge: 66 pt Bold condensed over "/250" at 28; the group sits this far above the
        /// circle's centre (13: "460" cap top at 223 pt, ≈13 pt above the centre).
        static let valueSize: CGFloat = 66
        static let targetSize: CGFloat = 28
        static let numberLift: CGFloat = 18
        /// The page's top light (84 and 76: #93979A at the top centre, white ≈46% over the page, flat for
        /// ≈100 pt then falling to ≈20% by 200 pt and narrower across than down, with the challenge's colour
        /// at the sides): an ellipse this wide and tall centred this far above the gauge's top (about the
        /// screen's top edge), solid to `topLightSolid` of its radius.
        static let topLight = Color.white.opacity(0.46)
        static let topLightSize = CGSize(width: 340, height: 560)
        static let topLightSolid = 0.35
        static let lightCentreAboveGauge: CGFloat = 150
        /// The challenge's colour at the sides of the top light.
        static let topTint = 0.32
        static let topTintRadius: CGFloat = 320
        static let topTintSize = CGSize(width: 700, height: 420)
        /// The headline sits this far under the days-left line (13: 438 pt against 370 pt).
        static let headlineGap: CGFloat = 47
        /// The day list's card (13, 76: #2A2E31 on the page, white ≈10%) with a 1 pt rim lit along its top
        /// (#3E4245, white ≈12%) and its pointer.
        static let listCard = Color.white.opacity(0.10)
        static let listCardRim = Color.white.opacity(0.12)
        static let pointer = CGSize(width: 18, height: 9)
        /// The bottom button (84, 13): a white rounded rectangle, 8 pt corners, 48 pt tall, from 20 pt in to
        /// 16 pt short of the floating Coach button (or the right margin when Coach is off); its label 11 pt
        /// Bold caps in black (caps 7.0 pt), with no glyph.
        static let buttonHeight: CGFloat = 48
        static let buttonRadius: CGFloat = 8
        static let buttonLeading: CGFloat = 20
        static let buttonCoachGap: CGFloat = 16
        /// Its centre sits this far above the Coach button's (84: 809.9 against 814.5 pt).
        static let buttonLift: CGFloat = 4.5
        static let buttonFill = Color.white
        static let buttonText = Color.black
        /// The trailing "ooo" (84, 76, 13): three outlined circles, 6 pt across, 4 pt apart, 1.3 pt strokes.
        static let moreDot: CGFloat = 6
        static let moreDotGap: CGFloat = 4
        static let moreDotStroke: CGFloat = 1.3
        /// The list's small gauge and its kind glyph; a template card's glyph in its tinted circle.
        static let cardGauge: CGFloat = 72
        static let cardGlyphSize: CGFloat = 18
        static let templateGlyphFrame: CGFloat = 40
        static let templateGlyphTint = 0.16
        /// The goal stepper's buttons and the check in "✓ Complete".
        static let stepGlyphSize: CGFloat = 14
        static let stepButton: CGFloat = 36
        static let stepValueWidth: CGFloat = 76
        static let checkSize: CGFloat = 15
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
