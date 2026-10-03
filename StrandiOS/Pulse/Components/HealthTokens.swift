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

    /// The Health tab and Healthspan page under the glow: near-black slate (reviews/r44 #110D0A at the
    /// top left, #0E0F11–#14181B lower down).
    static let pageTop = Color(hex: "#0D0E10")
    static let pageBottom = Color(hex: "#111518")

    // MARK: Cards and banners

    /// The calibrating note's blue-tinted fill (§3.20 item 2: #67AEE6 at 20%) and its text.
    static let calibratingFill = PulseTheme.recoveryBlue.opacity(0.20)
    static let calibratingText = Color(hex: "#B5D8F5")
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

    /// TOTAL DAY's "typical" bar: the level hues at half strength (§3.22 item 6).
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

    // MARK: Live heart rate (§3.21 item 3)

    static let liveHeart = PulseTheme.strain
    static let liveLine = PulseTheme.strain
    static let liveGrid = Color.white.opacity(0.06)
}
#endif
