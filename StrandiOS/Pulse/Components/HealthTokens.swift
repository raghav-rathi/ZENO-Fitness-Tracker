#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Health group tokens (WHOOP_UI_SPEC §2.1 "Healthspan orb", "Health unlock", §3.20–3.23, §3.28)
//
// The colours only the Health tab, Health Monitor, Stress Monitor and Healthspan draw with, kept in the
// health group's own file so the shared Theme/ stays the foundation's. Every value is the spec's or was
// sampled on the cited capture; nothing here is a WHOOP asset.

/// Which way ZENO Age sits from the calendar, which picks the orb's hue and the page glow behind it.
enum HealthAgeHue: Equatable {
    /// At least a year younger than your age: green.
    case younger
    /// Within a year of your age: teal.
    case steady
    /// At least a year older: amber.
    case older
    /// ZENO Age is still unlocking: the dormant grey orb with magenta speckles.
    case unlocking

    /// The hue for a ZENO Age `yearsYounger` years under the chronological age (negative = older).
    static func forYearsYounger(_ years: Double) -> HealthAgeHue {
        if years >= 1 { return .younger }
        if years <= -1 { return .older }
        return .steady
    }
}

enum HealthPalette {

    /// One orb hue: its particles, rim, dark interior, the page glow behind it and the text line in it.
    struct Orb: Equatable {
        let particles: Color
        let rim: Color
        let interior: Color
        /// The page glow over the Health tab's and Healthspan's top.
        let glow: Color
        /// "7.2 years younger": the hue as text.
        let text: Color
    }

    /// Green (spec: particles #00ECAE, rim #05B576, interior #005434, glow #0B4E2F–#185B3C), amber
    /// (sampled on reviews/r44: rim #A88124, glow #634312; the "older" text is the spec's #FFA722), teal
    /// for about zero (no spec value: ZENO's own, between the two), and the unlocking magenta.
    static func orb(_ hue: HealthAgeHue) -> Orb {
        switch hue {
        case .younger:
            return Orb(particles: Color(hex: "#00ECAE"), rim: Color(hex: "#05B576"),
                       interior: Color(hex: "#005434"), glow: Color(hex: "#185B3C"),
                       text: Color(hex: "#00ECAE"))
        case .steady:
            return Orb(particles: Color(hex: "#6FDCEB"), rim: Color(hex: "#2FA4BA"),
                       interior: Color(hex: "#0B3E49"), glow: Color(hex: "#15495A"),
                       text: Color(hex: "#6FDCEB"))
        case .older:
            return Orb(particles: Color(hex: "#F2C24E"), rim: Color(hex: "#C99A2E"),
                       interior: Color(hex: "#4A350D"), glow: Color(hex: "#634312"),
                       text: PulseTheme.negative)
        case .unlocking:
            return Orb(particles: PulseTheme.Healthspan.unlockingParticles,
                       rim: PulseTheme.Healthspan.unlockingRim,
                       interior: PulseTheme.Healthspan.unlockingInterior,
                       glow: PulseTheme.Gradients.healthUnlockGlow, text: PulseTheme.textSecondary)
        }
    }

    // MARK: Page

    /// The Health tab's page under the glow (reviews/r44, health-more-2026/16): near-black #0B0B0D at the
    /// top, opening into the standard slate by ≈450 pt (#13181C at 0.53 of the page), then DR's stops.
    static let tabPageStops: [Gradient.Stop] = [
        .init(color: Color(hex: "#0B0B0D"), location: 0),
        .init(color: Color(hex: "#13181C"), location: 0.53),
        .init(color: Color(hex: "#101518"), location: 0.76),
        .init(color: Color(hex: "#0E1213"), location: 1),
    ]
    /// Healthspan's page (reviews/r119 at rest, sampled at x = 8 pt; reviews/29 scrolled): pure black behind
    /// the orb, which scrolls away with it, over a flat slate page (#111518 from ≈0.53 of the screen down,
    /// and to the top once scrolled).
    static let healthspanTop = Color.black
    static let healthspanSlate = Color(hex: "#111518")

    // MARK: Cards and banners

    /// The calibrating note's blue-tinted fill (§3.20 item 2: #67AEE6 at 20%) and its text.
    static let calibratingFill = PulseTheme.recoveryBlue.opacity(0.20)
    static let calibratingText = Color(hex: "#B5D8F5")
    /// The HEALTH MONITOR card's footer well (reviews/r100: #212527 on the #292E31 card, black ≈20%).
    static let monitorFooterWell = Color.black.opacity(0.2)
    /// The Health Monitor's violet "N more nights" banner (onboarding/32b: #372942) and its empty segments.
    static let monitorBannerFill = Color(hex: "#372942")
    static let monitorBannerSegment = Color.white.opacity(0.22)
    /// The Pace of Aging card's 1 pt rim, lit at its foot and gone at its top (reviews/r44).
    static let paceCardRim = Color.white.opacity(0.13)
    /// The disclaimer under the Health tab (§3.20 item 10: #B4B4B8).
    static let disclaimer = Color(hex: "#B4B4B8")
    /// The unlock card's body text (#B8B8BC).
    static let unlockBody = Color(hex: "#B8B8BC")
    /// "Slow" orb glyph beside the ruler.
    static let slowGlyph = Color(hex: "#5C5D60")
    /// The Lab Book promo card (§3.20 item 4, empty state): #2B2F32 → #23735A.
    static let labsPromo = Gradient(colors: [Color(hex: "#2B2F32"), Color(hex: "#23735A")])
    /// The darker TOTAL DAY card (completeness-critic/14: #1C2023 on #111518, white ≈4.5%).
    static let totalDayCard = PulseTheme.detail
    /// The menstrual card's phase bar, coral to lavender (§3.20 item 6).
    static let cycleBar = Gradient(colors: [PulseTheme.Menstrual.Phase.menstrual.dot,
                                            PulseTheme.Menstrual.Phase.follicular.dot,
                                            PulseTheme.Menstrual.Phase.luteal.dot])
    /// The illness heads-up card's orange tint border.
    static let illnessBorder = PulseTheme.negative.opacity(0.55)

    // MARK: Stress

    /// TOTAL DAY's bars: today LOW / MEDIUM / HIGH in the stress level colours the gauge and the chart use,
    /// so the screen has one "medium" green, and the typical day under it in the same hues at 50% (§3.22
    /// item 6). completeness-critic/14's softer-looking tints are those same colours in a Display P3
    /// screenshot read as sRGB (#67AEE6 / #00F19F / #FFA722 encode as 119,172,224 / 110,238,164 /
    /// 243,171,69 in P3), not different hues.
    static let totalLow = PulseTheme.Stress.low
    static let totalMedium = PulseTheme.Stress.medium
    static let totalHigh = PulseTheme.Stress.high
    static let typicalLow = Color(hex: "#426885")
    static let typicalMedium = Color(hex: "#0E8962")
    static let typicalHigh = Color(hex: "#8D6423")
    /// The stress chart's zoom button (a black rounded square, §2.7 "Stress 24 h").
    static let zoomButton = Color.black.opacity(0.85)

    // MARK: VO₂ max scale (§3.28: <35 grey, 35 #ADC2CD, 40 #67AEE6, 45 #A4A3F1, 50+ purple)

    static let vo2Segments: [Color] = [
        Color(hex: "#8A8E93"),
        Color(hex: "#ADC2CD"),
        Color(hex: "#67AEE6"),
        Color(hex: "#A4A3F1"),
        Color(hex: "#B67CF2"),
    ]
    /// The scale's cut-offs between those segments, ml/kg/min.
    static let vo2CutOffs: [Double] = [35, 40, 45, 50]
    /// The dark well each segment sits on.
    static let vo2SegmentWell = Color.white.opacity(0.07)

    // MARK: Healthspan range bars (§2.7 "Range bars"; reviews/29 rows 370-375)

    /// A range-bar segment's colour: its tone lightened at the bar's ends (end segments ≈80% colour + 20%
    /// white, #8DE9BA / #E3AF64) and dimmed toward the middle (#5D4C38), as reviews/29 grades them.
    /// `emphasis` runs 1 at an end segment to 0 at the middle.
    static func rangeSegment(_ tone: HealthspanRow.Tone?, emphasis: Double) -> Color {
        let e = min(1, max(0, emphasis))
        switch tone {
        case .helps?: return mix(Color(hex: "#2F5A47"), Color(hex: "#8DE9BA"), e)
        case .hurts?: return mix(Color(hex: "#5D4C38"), Color(hex: "#E3AF64"), e)
        case .neutral?: return mix(Color(hex: "#55585A"), Color(hex: "#8A8C8E"), e)
        case nil: return Color.white.opacity(0.22)
        }
    }

    /// The end label's colour: its end segment's tone at full emphasis, grey on a bar without tones.
    static func rangeLabel(_ tone: HealthspanRow.Tone?) -> Color {
        tone == nil || tone == .neutral ? PulseTheme.textTertiary : rangeSegment(tone, emphasis: 1)
    }

    private static func mix(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ca = UIColor(a), cb = UIColor(b)
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        ca.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        cb.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = CGFloat(t)
        return Color(.sRGB, red: Double(r1 + (r2 - r1) * k), green: Double(g1 + (g2 - g1) * k),
                     blue: Double(b1 + (b2 - b1) * k), opacity: Double(a1 + (a2 - a1) * k))
    }

    // MARK: Live heart rate (§3.21 item 3)

    static let liveHeart = PulseTheme.strain
    static let liveLine = PulseTheme.strain
    static let liveGrid = Color.white.opacity(0.06)
}

// MARK: - Glyph sizes

/// The SF Symbol sizes the health screens draw, so no screen writes a font size (ARCHITECTURE §1). A glyph
/// that sits beside text scales with it (`@ScaledMetric` relative to `relativeTo`); one inside a fixed frame
/// (the Health Monitor card's columns, the chart's zoom button) keeps its size.
enum HealthGlyph {
    /// 22 Light: the HEALTH MONITOR card's column icons and the Rhythm card's waveform.
    case columnIcon
    /// 15 Light: a Health Monitor tile's icon.
    case tileIcon
    /// 20 Light: SHARE YOUR HEALTH REPORT.
    case rowIcon
    /// 30 Light: the Lab Book promo's test tubes.
    case promoArt
    /// 18 Light: a Sessions card's glyph.
    case sessionIcon
    /// 13 Semibold: a pillar row's ⌄ / ⌃.
    case disclosure
    /// 14 Semibold: the calibrating note's ✕ and the illness card's glyph.
    case control
    /// 15 Semibold: the calibrating note's hourglass.
    case noteIcon
    /// 12 Semibold: the arrow after an inline CTA ("ADD RESULTS →").
    case inlineArrow
    /// 13 Regular: TOTAL DAY's gauge glyph.
    case cardIcon
    /// 15 Bold: a pager's ‹ ›.
    case pagerChevron
    /// 17 Regular: the stress chart's zoom glyph.
    case zoom
    /// 17 Semibold: the sleep and activity glyphs above the stress chart (completeness-critic/14 ≈17–18 pt).
    case periodGlyph
    /// 15 Regular: an inline ⓘ.
    case info
    /// 11 Heavy: a status chip's ✓ / "!".
    case chipMark
    /// 8 Heavy: a grey chip's ●.
    case chipDot
    /// 12 Heavy: the ✓ / "!" in the HEALTH MONITOR footer's 16 pt square.
    case footerMark

    fileprivate var spec: (size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle?) {
        switch self {
        case .columnIcon: return (22, .light, nil)
        case .tileIcon: return (15, .light, .subheadline)
        case .rowIcon: return (20, .light, .title3)
        case .promoArt: return (30, .light, nil)
        case .sessionIcon: return (18, .light, .headline)
        case .disclosure: return (13, .semibold, .footnote)
        case .control: return (14, .semibold, .subheadline)
        case .noteIcon: return (15, .semibold, .subheadline)
        case .inlineArrow: return (12, .semibold, .caption)
        case .cardIcon: return (13, .regular, .footnote)
        case .pagerChevron: return (15, .bold, nil)
        case .zoom: return (17, .regular, nil)
        case .periodGlyph: return (17, .semibold, nil)
        case .info: return (15, .regular, .subheadline)
        case .chipMark: return (11, .heavy, .caption2)
        case .chipDot: return (8, .heavy, .caption2)
        case .footerMark: return (11, .heavy, nil)
        }
    }

    /// The glyph's font at its base size (for a fixed frame or a Canvas annotation).
    var font: Font {
        let s = spec
        return .system(size: s.size, weight: s.weight)
    }
}

private struct HealthGlyphModifier: ViewModifier {
    let weight: Font.Weight
    let fixed: CGFloat?
    @ScaledMetric private var scaled: CGFloat

    init(_ glyph: HealthGlyph) {
        let spec = glyph.spec
        weight = spec.weight
        fixed = spec.relativeTo == nil ? spec.size : nil
        _scaled = ScaledMetric(wrappedValue: spec.size, relativeTo: spec.relativeTo ?? .body)
    }

    func body(content: Content) -> some View {
        content.font(.system(size: fixed ?? scaled, weight: weight))
    }
}

extension View {
    /// Size an SF Symbol with a health glyph token.
    func healthGlyph(_ glyph: HealthGlyph) -> some View {
        modifier(HealthGlyphModifier(glyph))
    }
}
#endif
