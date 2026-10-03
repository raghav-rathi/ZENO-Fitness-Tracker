#if os(iOS)
import SwiftUI

// MARK: - The activity group's own style constants (interim; WHOOP_UI_SPEC §2.1 "Activity-flow tokens")
//
// ARCHITECTURE §2: screens never write a colour, a font size or a radius of their own. The activity
// screens need a handful the theme does not have yet (the light Strain Target panel's ink, a few overlays
// on the map and the live pages, the route card's radius, the panel's type), so they are collected HERE,
// named, in one place, instead of being written inline across the group. Each is a candidate for
// `PulseTheme.Activity` once the foundation adopts it; until then nothing outside Screens/Activity reads
// this file.

enum PulseActivityStyle {

    // MARK: The light panel (§2.6 item 29: black ink on #FFFFFF / #F5F5F5)

    /// Titles, values, the sentence, the bar's cap tick.
    static let panelInk = Color.black
    /// The "nothing to show" sentence.
    static let panelInkSecondary = Color.black.opacity(0.70)
    /// The ring's state word ("OPTIMAL"), a disabled reset glyph's ring, captions under a value.
    static let panelInkMuted = Color.black.opacity(0.45)
    /// The legend captions ("CURRENT DAY STRAIN") and the footnote.
    static let panelInkLegend = Color.black.opacity(0.50)
    /// "OPTIMAL TRAINING" across the band on the DAY STRAIN chart.
    static let panelInkFaint = Color.black.opacity(0.32)
    /// The thin ring around "?" and the reset glyph.
    static let panelOutline = Color.black.opacity(0.30)
    static let panelOutlineFaint = Color.black.opacity(0.15)
    /// The DAY STRAIN chart's grid and the small glyph's empty track.
    static let panelGrid = Color.black.opacity(0.07)
    static let panelGlyphTrack = Color.black.opacity(0.10)
    /// The estimate's dashed line on the chart.
    static let panelDash = Color.black.opacity(0.35)
    /// The dashed OPTIMAL arc outside the ring.
    static let panelArc = Color.black.opacity(0.75)
    /// The page dots under the two views.
    static let panelDotOn = Color.black.opacity(0.75)
    static let panelDotOff = Color.black.opacity(0.18)
    /// A white knob's 1 pt rim on the light track, in place of a drop shadow (DR §9: no shadows).
    static let panelKnobRim = Color.black.opacity(0.14)
    /// The hatched part of the chart's bar and its swatch: strain blue, faint, under 1 pt stripes.
    static let panelHatchFill = PulseTheme.strain.opacity(0.17)
    static let panelHatchStripe = PulseTheme.strain.opacity(0.55)

    /// SAVE's white capsule and its black label (§2.6 item 16c), and ink on the green active time pill.
    static let capsuleFill = Color.white
    static let capsuleInk = Color.black

    // MARK: Dark surfaces

    /// The current activity's row in the pre-start list (completeness-critic/05: white ≈8%).
    static let selectedRow = Color.white.opacity(0.08)
    /// The pre-start list's backdrop over the map.
    static let pickerBackdrop = Color.black.opacity(0.92)
    /// The Track Route switch's track on the dark header.
    static let toggleTrackOnDark = Color.white.opacity(0.22)
    /// The outer halo round the pre-start heart-rate circle (a07).
    static let preStartOuterHalo = Color.white.opacity(0.035)
    /// Ink inside the pre-start circle: the battery row and "No strap".
    static let circleInkMuted = Color.black.opacity(0.55)
    /// The live ring's empty track (b01: #2B3036 on the live page).
    static let liveRingEmpty = Color.white.opacity(0.045)
    /// The ❚❚ / ▶ disc in the live band.
    static let bandControl = Color.white.opacity(0.22)
    /// "PAUSED" under the live band's clock.
    static let bandCaption = Color.white.opacity(0.85)
    /// The Heart Rate page's disc.
    static let liveHRDisc = Color.black
    /// The Edit scrubber's lit window and its handles.
    static let scrubberWindow = Color.white.opacity(0.06)
    static let scrubberHandle = Color.white.opacity(0.85)

    // MARK: Maps

    /// "ROUTE" on the light map, and the finish marker's glyph.
    static let mapInk = Color.black
    /// The start dot's ring and the finish marker's disc.
    static let mapMarker = Color.white
    /// The route card's stats panel: units and labels over #171717.
    static let mapStatUnit = Color.white.opacity(0.80)
    static let mapStatLabel = Color.white.opacity(0.60)
    /// The live map's "Waiting for a GPS fix…" capsule.
    static let mapNoticeFill = Color.white.opacity(0.90)
    static let mapNoticeInk = Color.black.opacity(0.70)

    // MARK: Radii and sizes

    /// The ROUTE card (§3.6 item 12: "radius ≈14", f02, f06).
    static let routeCardRadius: CGFloat = 14
    /// The Strain Target ring (§2.5, a05: 285 pt across a 375 pt panel with a 16 pt stroke): its frame, its
    /// stroke and the gap from the frame's edge to the stroke's centre line, so the ring measures
    /// 330 − 2 × 25 + 16 = 296 pt across and the dashed OPTIMAL arc and its label fit outside it.
    static let targetRingFrame: CGFloat = 330
    static let targetRingStroke: CGFloat = 16
    static let targetRingInset: CGFloat = 25
    /// The dashed OPTIMAL arc's distance outside the ring's outer edge, and its label's beyond the arc.
    static let targetArcGap: CGFloat = 13
    static let targetArcLabelGap: CGFloat = 11

    /// SF Symbol sizes (glyphs sit in fixed slots: bars, circles, rows). Text never uses these.
    enum Glyph {
        static let header: CGFloat = 22
        static let preStartHeader: CGFloat = 24
        static let close: CGFloat = 19
        static let headerChevron: CGFloat = 17
        static let chip: CGFloat = 12
        static let tile: CGFloat = 17
        static let row: CGFloat = 21
        static let formRow: CGFloat = 20
        static let chevron: CGFloat = 16
        static let search: CGFloat = 16
        static let banner: CGFloat = 15
        static let share: CGFloat = 15
        static let mapMarker: CGFloat = 11
        static let liftIcon: CGFloat = 26
        static let arrow: CGFloat = 13
        static let circleHeart: CGFloat = 22
        static let circleBattery: CGFloat = 13
        static let bandControl: CGFloat = 14
        static let flag: CGFloat = 18
        static let stat: CGFloat = 20
        static let mapStat: CGFloat = 18
        static let liveHeart: CGFloat = 17
        static let panelEmpty: CGFloat = 34
        static let panelReset: CGFloat = 17
        static let panelCheck: CGFloat = 20
        static let ringCheck: CGFloat = 52
        static let legendChevron: CGFloat = 15
        static let help: CGFloat = 15
    }
}

// MARK: - Type the theme has no style for yet

/// The activity group's text styles beyond `PulseTextStyle`: the light panel, the live pages, the search
/// field. Like the theme's own, prose and labels scale with Dynamic Type (relative to `relativeTo`), up to
/// `maxScale` where they sit in a fixed shape (a ring, a fixed-height row); `relativeTo: nil` is fixed.
enum PulseActivityTextStyle {
    /// "STRAIN TARGET" in the panel's white header row.
    case panelTitle
    /// "Based on your 78% Recovery, build a 13.2 Activity Strain…" (a05: black ≈20 pt).
    case panelSentence
    /// The panel's "switch it on" / "appears once" sentences.
    case panelBody
    /// "GUIDED SESSION (BETA) →".
    case panelLink
    /// "ACTIVITY STRAIN" and the state word inside the light ring.
    case panelRingLabel
    /// "OPTIMAL" along the dashed arc.
    case panelArcLabel
    /// "TRAINING STATE: OPTIMAL".
    case panelHeading
    /// "DAY STRAIN" over the chart.
    case panelChartTitle
    /// "*If this activity builds the target Strain." and captions under a value.
    case panelFootnote
    /// "CURRENT DAY STRAIN" and the other legend captions.
    case panelLegend
    /// "OPTIMAL TRAINING" across the band.
    case panelBandLabel
    /// "?" in its thin circle (fixed: it sits in a 30 pt circle).
    case panelHelpGlyph
    /// "Track Route" under the pre-start header.
    case trackRoute
    /// The activity search field.
    case searchField
    /// The amber banner's "!".
    case bannerBang
    /// "ACTIVITY STRAIN" inside the live ring.
    case liveRingLabel
    /// The intensity word under the live value ("MODERATE").
    case liveRingState
    /// "Zone 0" … "Zone 5" under the live zone bar, and the current zone's (bold).
    case liveZoneLabel
    case liveZoneLabelCurrent
    /// "Zone 2" under the Heart Rate page's bpm (fixed: it sits in a 132 pt disc).
    case liveDiscCaption
    /// "← Heart Rate" · "Map →".
    case liveFooter
    /// A live stat's unit ("mi", "/mi").
    case statUnit
    /// The pre-start circle's battery figure and "No strap" (fixed: they sit in a 181 pt circle).
    case circleCaption

    struct Spec {
        let size: CGFloat
        let weight: Font.Weight
        let uppercase: Bool
        let tracking: CGFloat
        let relativeTo: Font.TextStyle?
        /// The largest scale this style grows to (1 = fixed at the base size).
        let maxScale: CGFloat
    }

    var spec: Spec {
        switch self {
        case .panelTitle: return Spec(size: 14, weight: .bold, uppercase: true, tracking: 1.4, relativeTo: .subheadline, maxScale: 1.4)
        case .panelSentence: return Spec(size: 18, weight: .medium, uppercase: false, tracking: 0, relativeTo: .body, maxScale: 2.2)
        case .panelBody: return Spec(size: 17, weight: .regular, uppercase: false, tracking: 0, relativeTo: .body, maxScale: 2.2)
        case .panelLink: return Spec(size: 12, weight: .bold, uppercase: true, tracking: 1.0, relativeTo: .caption, maxScale: 1.8)
        case .panelRingLabel: return Spec(size: 15, weight: .bold, uppercase: true, tracking: 1.2, relativeTo: .subheadline, maxScale: 1.25)
        case .panelArcLabel: return Spec(size: 11, weight: .bold, uppercase: true, tracking: 1.2, relativeTo: .caption2, maxScale: 1.3)
        case .panelHeading: return Spec(size: 16, weight: .bold, uppercase: true, tracking: 1.4, relativeTo: .callout, maxScale: 1.5)
        case .panelChartTitle: return Spec(size: 14, weight: .bold, uppercase: true, tracking: 1.0, relativeTo: .subheadline, maxScale: 1.5)
        case .panelFootnote: return Spec(size: 12, weight: .regular, uppercase: false, tracking: 0, relativeTo: .caption, maxScale: 2.0)
        case .panelLegend: return Spec(size: 12, weight: .bold, uppercase: true, tracking: 0.8, relativeTo: .caption, maxScale: 1.5)
        case .panelBandLabel: return Spec(size: 13, weight: .bold, uppercase: true, tracking: 1.2, relativeTo: .footnote, maxScale: 1.3)
        case .panelHelpGlyph: return Spec(size: 15, weight: .medium, uppercase: false, tracking: 0, relativeTo: nil, maxScale: 1)
        case .trackRoute: return Spec(size: 13, weight: .medium, uppercase: false, tracking: 0.6, relativeTo: .footnote, maxScale: 1.4)
        case .searchField: return Spec(size: 17, weight: .regular, uppercase: false, tracking: 0, relativeTo: .body, maxScale: 1.8)
        case .bannerBang: return Spec(size: 17, weight: .heavy, uppercase: false, tracking: 0, relativeTo: .body, maxScale: 2.0)
        case .liveRingLabel: return Spec(size: 15, weight: .bold, uppercase: true, tracking: 1.2, relativeTo: .subheadline, maxScale: 1.25)
        case .liveRingState: return Spec(size: 13, weight: .bold, uppercase: true, tracking: 1.3, relativeTo: .footnote, maxScale: 1.25)
        case .liveZoneLabel: return Spec(size: 13, weight: .semibold, uppercase: false, tracking: 0, relativeTo: .footnote, maxScale: 1.3)
        case .liveZoneLabelCurrent: return Spec(size: 13, weight: .bold, uppercase: false, tracking: 0, relativeTo: .footnote, maxScale: 1.3)
        case .liveDiscCaption: return Spec(size: 13, weight: .semibold, uppercase: false, tracking: 0, relativeTo: nil, maxScale: 1)
        case .liveFooter: return Spec(size: 16, weight: .regular, uppercase: false, tracking: 0, relativeTo: .callout, maxScale: 1.5)
        case .statUnit: return Spec(size: 15, weight: .semibold, uppercase: false, tracking: 0, relativeTo: .subheadline, maxScale: 1.3)
        case .circleCaption: return Spec(size: 14, weight: .medium, uppercase: false, tracking: 0, relativeTo: nil, maxScale: 1)
        }
    }
}

extension PulseActivityTextStyle.Spec {
    /// The size for a Dynamic Type `scaled` value: fixed styles keep their base size, the rest grow up to
    /// `maxScale` and never fall under the 11 pt floor.
    func size(scaled: CGFloat) -> CGFloat {
        guard relativeTo != nil else { return size }
        return min(max(11, scaled), size * maxScale)
    }

    func font(size: CGFloat) -> Font { .system(size: size, weight: weight) }
}

private struct PulseActivityTextModifier: ViewModifier {
    private let spec: PulseActivityTextStyle.Spec
    @ScaledMetric private var scaled: CGFloat

    init(_ style: PulseActivityTextStyle) {
        let spec = style.spec
        self.spec = spec
        _scaled = ScaledMetric(wrappedValue: spec.size, relativeTo: spec.relativeTo ?? .body)
    }

    func body(content: Content) -> some View {
        let size = spec.size(scaled: scaled)
        content
            .font(spec.font(size: size))
            .tracking(spec.tracking * size / spec.size)
            .textCase(spec.uppercase ? .uppercase : nil)
    }
}

/// A numeral (Bold condensed, tabular digits) that scales with Dynamic Type relative to `relativeTo`, up to
/// `maxScale`: the zone rows' share and time, the panel chart's axis. Ring and hero numerals stay fixed.
private struct PulseActivityNumeralModifier: ViewModifier {
    let base: CGFloat
    let maxScale: CGFloat
    @ScaledMetric private var scaled: CGFloat

    init(_ base: CGFloat, relativeTo: Font.TextStyle, maxScale: CGFloat) {
        self.base = base
        self.maxScale = maxScale
        _scaled = ScaledMetric(wrappedValue: base, relativeTo: relativeTo)
    }

    func body(content: Content) -> some View {
        content.font(PulseType.numeral(min(max(11, scaled), base * maxScale)))
    }
}

extension View {
    /// Style text with one of the activity group's own text styles.
    func activityText(_ style: PulseActivityTextStyle) -> some View {
        modifier(PulseActivityTextModifier(style))
    }

    /// A Bold condensed numeral of `size` that grows with Dynamic Type (relative to `relativeTo`) up to
    /// `maxScale`.
    func activityNumeral(_ size: CGFloat, relativeTo: Font.TextStyle = .footnote, maxScale: CGFloat = 1.6) -> some View {
        modifier(PulseActivityNumeralModifier(size, relativeTo: relativeTo, maxScale: maxScale))
    }
}
#endif
