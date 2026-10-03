#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - The onboarding step template (WHOOP_UI_SPEC §3.38 "Shared step template", §2.1 onboarding tokens,
// §2.5 "Onboarding ring CTA"; gap-3 §2–3, measured on onboarding/15b, 20d, 22b, 22d)
//
// Every account and profile step shares one page:
//   - a full-screen gradient and NO navigation bar: a thin "‹" at the top-left (centred 23.5 pt under the
//     safe-area top, as Pulse's own bar) and an optional "SKIP" at the top-right;
//   - content anchored to the BOTTOM: a ≈90 pt left-aligned illustration, then the title (25 pt
//     Semibold), the subtitle (16 pt, #BEC0C2, 14 pt below) and the step's fields, all stacking upward
//     from the CTA row with ≈39 pt to spare. A step too long for the screen drops its illustration
//     first, and scrolls only if it still does not fit (the largest text sizes);
//   - the 78 pt ring CTA at the bottom-right, its label to the left, its arc showing progress through
//     the flow.
// Pairing and status screens use `PulseOnboardingStatusPage` instead: a centred caps title and
// full-width pills at the bottom.

/// Onboarding's own measurements, from the 2026 captures (gap-3 §2–3).
enum PulseOnboardingMetrics {
    /// The ring CTA: 78 pt outside, a 36 pt centreline radius and a 5.6 pt stroke.
    static let ringDiameter: CGFloat = 78
    static let ringStroke: CGFloat = 5.6
    /// Where the arc's gradient stops sit around the ring (`PulseTheme.Onboarding.ringArc`'s colours,
    /// sampled on 15b and 22d: the light blue fades to the darker one within the first half turn).
    static let ringArcLocations: [CGFloat] = [0, 0.25, 0.56]
    /// The ring's outer edge sits 29 pt from the screen's right edge.
    static let ringTrailing: CGFloat = 29
    /// The ring's centre sits ≈86 pt above the screen's bottom edge: 52 pt above a 34 pt home-indicator
    /// inset, so its bottom edge is 13 pt above the safe area.
    static let ringBottom: CGFloat = 13
    /// The filled commit / finish circle that replaces the ring on a few steps.
    static let filledDiameter: CGFloat = 72
    /// From the label's right end to the ring.
    static let labelGap: CGFloat = 15
    /// From the last content to the top of the CTA row (Welcome 39 pt, Privacy 43 pt).
    static let contentToCTA: CGFloat = 39
    /// The scroll content's top inset under the top bar.
    static let contentTop: CGFloat = 16
    /// From the illustration's lowest ink to the title's caps (15b: 40.3 pt; 22d: 45.3 pt).
    static let illustrationToTitle: CGFloat = 40
    /// From the 25 pt title's text frame to its caps: the part of `illustrationToTitle` the title's own
    /// line box already supplies.
    static let titleCapInset: CGFloat = 6
    static let illustrationHeight: CGFloat = 90
    /// The device steps' strap drawing (the 290 pt WHOOP renders push their fields under the CTA).
    static let deviceArtHeight: CGFloat = 200
    /// From a large drawing's bottom to the title's text frame.
    static let largeArtToTitle: CGFloat = 24
    /// The page gradient's stops (`PulseTheme.Onboarding.page`'s four colours): sampled at x = 12 pt on
    /// 15b, 20d, 22b and 22d, the page is already #171C20 by 30% of the height and #14171C by 45%.
    static let pageStopLocations: [CGFloat] = [0, 0.2, 0.45, 1.0]
    /// From the title to the subtitle.
    static let titleToSubtitle: CGFloat = 14
    /// From the subtitle to the step's first field or row.
    static let subtitleToContent: CGFloat = 28
    /// Text fields: 44–45 pt tall, radius 10–12.
    static let fieldHeight: CGFloat = 45
    static let fieldRadius: CGFloat = 11
    /// A field's caps label sits 10 pt above it; the next label starts ≈34 pt under a field.
    static let labelToField: CGFloat = 10
    static let fieldToNextLabel: CGFloat = 34
    /// Checkboxes: 30 pt, radius 8.5, a 2 pt white stroke; their text starts 18 pt after the box.
    static let checkbox: CGFloat = 30
    static let checkboxRadius: CGFloat = 8.5
    static let checkboxGap: CGFloat = 18
    /// Pills on the pairing and status screens: 50 pt, radius 19 (2026), 23 pt from each screen edge
    /// (13d: RETRY spans x 23.0–378.7 on a 402 pt screen).
    static let pillHeight: CGFloat = 50
    static let pillRadius: CGFloat = 19
    static let pillSideMargin: CGFloat = 23
    /// A status page's centred title when it leads the page: 32 pt under the top bar (09b: the HELP
    /// pill's centre to the title's caps is ≈59.5 pt).
    static let statusTitleTop: CGFloat = 32
    /// Option rows (country, gender, strap): 52 pt cards.
    static let optionHeight: CGFloat = 52
    /// The top bar's height under the safe-area top (44 pt row + 1.5 pt).
    static let topBarHeight: CGFloat = 45.5
    /// The CTA row's height above the safe-area bottom (the 78 pt ring + 13 pt below it).
    static let ctaHeight: CGFloat = 91
}

/// Onboarding's colours that are not in the shared token set: the dark secondary pill and its border,
/// the field placeholder and the blue accents the 2026 screens use.
enum PulseOnboardingColors {
    /// The dark second pill under a white one ("NEED MORE HELP?", "CONTINUE WITHOUT A STRAP").
    static let secondaryFill = Color(hex: "#0B1013")
    static let secondaryBorder = Color(hex: "#3D4144")
    /// A field's placeholder text.
    static let placeholder = Color(hex: "#8A8B8E")
    /// The HELP pill's outline and text (09b).
    static let helpBlue = Color(hex: "#118DD6")
    /// The illustrations' one blue accent (the padlock's keyhole on 22b).
    static let accentBlue = Color(hex: "#049AF1")
    /// The serial highlight and dotted leader on the strap drawing (09b).
    static let serialBlue = Color(hex: "#258ACB")
    /// The illustrations' grey body, lighter at the top like WHOOP's clay renders.
    static let illustrationTop = Color(hex: "#8E9398")
    static let illustrationBottom = Color(hex: "#55595E")
    /// An unchecked row's text.
    static let uncheckedText = Color(hex: "#C0C1C4")
    /// An option row's fill (country and gender rows).
    static let optionFill = Color(hex: "#2D3236")
    /// The filled commit circle ("START PAIRING") and the finish circle's dark ✓ (08c, 29b).
    static let commitBlue = Color(hex: "#4E9EEA")
    static let finishGlyph = Color(hex: "#07140F")
    /// Apple Health's heart on its white tile (Connect To Apple Health).
    static let healthHeart = Color(hex: "#FF3B5C")

    // ZENO's own drawings (PulseOnboardingArt), never WHOOP's renders.

    /// The strap's knit band, lit from the left.
    static let strapBand = [Color(hex: "#2A2F35"), Color(hex: "#1B1F23")]
    /// The strap's pod, lit from the top.
    static let strapPod = [Color(hex: "#4A5057"), Color(hex: "#25292E"), Color(hex: "#1A1D21")]
    /// The pod's status light.
    static let strapLight = Color(hex: "#7CC4FF")
    /// The charger seated on the pod.
    static let charger = [Color(hex: "#5A6068"), Color(hex: "#30343A")]
    /// The phone at the left edge of the connection drawing.
    static let phone = [Color(hex: "#0A0B0D"), Color(hex: "#15171A")]
    /// The connection drawing's status disc while connecting, and behind the failure ✕.
    static let connectingDisc = Color(hex: "#151A1F")
    static let failedDisc = Color(hex: "#1A1D21")
    /// The calibration wheel: its track, the first-calibration span, an unlit milestone's disc and a lit
    /// milestone's glyph.
    static let wheelTrack = Color(hex: "#1E2328")
    static let wheelSpan = [Color(hex: "#2F86E0"), Color(hex: "#4FC3F2")]
    static let milestoneOff = Color(hex: "#2C3238")
    static let milestoneGlyph = Color(hex: "#1C5E9E")
}

/// Onboarding's own type sizes (gap-3 §2): the 16 pt Regular subtitle, the 12 pt Bold field label
/// tracked +1.5, the centred caps titles of the pairing screens, the pills' 13 pt caps and a field's
/// 17 pt value. Each scales with Dynamic Type from the text style named beside it.
enum PulseOnboardingTextStyle {
    case subtitle
    case fieldLabel
    case fieldValue
    case statusTitle
    case statusBody
    case checkLine
    case pill

    fileprivate var size: CGFloat {
        switch self {
        case .subtitle: return 16
        case .fieldLabel: return 12
        case .fieldValue: return 17
        case .statusTitle: return 16
        case .statusBody: return 14.5
        case .checkLine: return 15
        case .pill: return 13
        }
    }

    fileprivate var weight: Font.Weight {
        switch self {
        case .fieldLabel, .statusTitle, .pill: return .bold
        default: return .regular
        }
    }

    fileprivate var tracking: CGFloat {
        switch self {
        case .fieldLabel: return 1.5
        case .statusTitle: return 1.6
        case .pill: return 1.3
        default: return 0
        }
    }

    fileprivate var uppercase: Bool {
        switch self {
        case .fieldLabel, .statusTitle, .pill: return true
        default: return false
        }
    }

    fileprivate var relativeTo: Font.TextStyle {
        switch self {
        case .subtitle, .fieldValue: return .body
        case .fieldLabel: return .caption
        case .statusTitle: return .headline
        case .statusBody, .checkLine: return .subheadline
        case .pill: return .footnote
        }
    }
}

private struct PulseOnboardingTextModifier: ViewModifier {
    let style: PulseOnboardingTextStyle
    @ScaledMetric private var size: CGFloat

    init(_ style: PulseOnboardingTextStyle) {
        self.style = style
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: style.weight))
            .tracking(style.tracking * size / style.size)
            .textCase(style.uppercase ? .uppercase : nil)
    }
}

extension View {
    /// Style text with one of onboarding's own sizes (scaled with Dynamic Type).
    func pulseOnboardingText(_ style: PulseOnboardingTextStyle) -> some View {
        modifier(PulseOnboardingTextModifier(style))
    }
}

// MARK: - Page

/// The onboarding page background: #262D33 → #1F2428 → #14171C → #111518, edge to edge, with the stops
/// where the captures put them (0 / 0.20 / 0.45 / 1; evenly spaced, the middle of the page read 5–8
/// levels too light).
struct PulseOnboardingBackground: View {
    static let gradient = Gradient(stops: zip(PulseTheme.Onboarding.page.stops.map(\.color),
                                              PulseOnboardingMetrics.pageStopLocations)
        .map { Gradient.Stop(color: $0, location: $1) })

    var body: some View {
        LinearGradient(gradient: Self.gradient, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// What the top-right of a step shows.
enum PulseOnboardingTrailing {
    case none
    /// Small white caps: optional steps ("SKIP").
    case text(String, () -> Void)
    /// The outlined blue "HELP" pill of the pairing screens.
    case help(() -> Void)
}

/// The top row of every onboarding page: "‹" (or "✕" in a circle on an error page), an optional
/// trailing control, both 44 pt tall and centred 23.5 pt below the safe-area top.
struct PulseOnboardingTopBar: View {
    enum Leading { case none, back, closeCircle }

    var leading: Leading = .back
    var trailing: PulseOnboardingTrailing = .none
    var onLeading: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            switch leading {
            case .none:
                Color.clear.frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
            case .back:
                PulseBackButton(action: onLeading)
            case .closeCircle:
                Button(action: onLeading) {
                    ZStack {
                        Circle().strokeBorder(Color.white, lineWidth: 1.5)
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                    .frame(width: 36, height: 36)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Close"))
            }
            Spacer(minLength: 0)
            trailingView
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .frame(height: PulseTheme.Header.navBar)
        .padding(.top, PulseTheme.Header.navBarTop)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .none:
            EmptyView()
        case .text(let title, let action):
            Button(action: action) {
                Text(title)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(minWidth: PulseTheme.Layout.minTapTarget, minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        case .help(let action):
            Button(action: action) {
                Text(String(localized: "Help"))
                    .pulseText(.label)
                    .foregroundStyle(PulseOnboardingColors.helpBlue)
                    .frame(width: 80, height: 30)
                    .background(Capsule(style: .circular).strokeBorder(PulseOnboardingColors.helpBlue, lineWidth: 1.5))
                    .frame(minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }
    }
}

/// A phrase in a step's subtitle that opens something (the Privacy step's "Terms of Use"), drawn as
/// WHOOP draws its "Privacy Policy" and "Terms of Use" links on 22d: white and underlined, inside the
/// sentence. VoiceOver gets it as a named action on the subtitle.
struct PulseOnboardingLink {
    let phrase: String
    let action: () -> Void

    /// The link's address inside the subtitle; never opened, the step handles it.
    static let url = URL(string: "zeno-onboarding://subtitle-link")!
}

/// A template step: top bar, bottom-anchored content (illustration, title, subtitle, fields), and the CTA
/// row pinned at the bottom (it rides above the keyboard). A step too tall for the screen shrinks, then
/// drops, its illustration rather than running its fields under the CTA, and scrolls only if it still
/// does not fit.
struct PulseOnboardingStepPage<Illustration: View, Content: View, CTA: View>: View {
    let title: String
    var subtitle: String?
    var subtitleLink: PulseOnboardingLink?
    var showsBack = true
    var trailing: PulseOnboardingTrailing = .none
    /// The illustration slot: ≈90 pt and left-aligned on the account steps, a large centred drawing on
    /// the device steps (WHOOP's strap renders fill the top of those pages).
    var art: PulseOnboardingArtSlot = .small
    let onBack: () -> Void
    @ViewBuilder let illustration: () -> Illustration
    @ViewBuilder let content: () -> Content
    @ViewBuilder let cta: () -> CTA

    /// The title, subtitle and fields' height, measured without the illustration, so whether the
    /// illustration fits never depends on itself.
    @State private var textHeight: CGFloat = 0

    init(title: String,
         subtitle: String? = nil,
         subtitleLink: PulseOnboardingLink? = nil,
         showsBack: Bool = true,
         trailing: PulseOnboardingTrailing = .none,
         art: PulseOnboardingArtSlot = .small,
         onBack: @escaping () -> Void,
         @ViewBuilder illustration: @escaping () -> Illustration,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder cta: @escaping () -> CTA) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleLink = subtitleLink
        self.showsBack = showsBack
        self.trailing = trailing
        self.art = art
        self.onBack = onBack
        self.illustration = illustration
        self.content = content
        self.cta = cta
    }

    var body: some View {
        ZStack {
            PulseOnboardingBackground()
            GeometryReader { outer in
                let room = outer.size.height - PulseOnboardingMetrics.contentTop - PulseOnboardingMetrics.contentToCTA
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer(minLength: 0)
                        if let shown = art.fittedHeight(textHeight: textHeight, room: room) {
                            illustration()
                                .frame(maxWidth: art.isLarge ? .infinity : nil,
                                       minHeight: art.height, maxHeight: art.height,
                                       alignment: art.isLarge ? .center : .bottomLeading)
                                .scaleEffect(shown / art.height, anchor: art.isLarge ? .bottom : .bottomLeading)
                                .frame(height: shown, alignment: art.isLarge ? .bottom : .bottomLeading)
                                .padding(.bottom, art.gapToTitle)
                                .accessibilityHidden(true)
                        }
                        textAndFields
                            // Only a full-width measurement counts: a presentation lays the page out at
                            // zero size first, where the text wraps to a column a few words wide.
                            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                                if size.width >= outer.size.width - 2 * PulseTheme.Layout.pageMargin - 1 {
                                    textHeight = size.height
                                }
                            }
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.top, PulseOnboardingMetrics.contentTop)
                    .padding(.bottom, PulseOnboardingMetrics.contentToCTA)
                    .frame(maxWidth: .infinity, minHeight: outer.size.height, alignment: .bottomLeading)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: PulseOnboardingMetrics.topBarHeight)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: PulseOnboardingMetrics.ctaHeight)
            }
            PulseOnboardingEdgeFades()
            VStack(spacing: 0) {
                PulseOnboardingTopBar(leading: showsBack ? .back : .none, trailing: trailing, onLeading: onBack)
                Spacer(minLength: 0)
                cta()
            }
        }
    }

    private var textAndFields: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .pulseText(.onboardingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                subtitleText(subtitle)
                    .pulseOnboardingText(.subtitle)
                    .foregroundStyle(PulseTheme.Onboarding.subtitle)
                    .tint(PulseTheme.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, PulseOnboardingMetrics.titleToSubtitle - 6)
                    .environment(\.openURL, OpenURLAction { url in
                        guard url == PulseOnboardingLink.url, let subtitleLink else { return .systemAction }
                        subtitleLink.action()
                        return .handled
                    })
                    .accessibilityActions {
                        if let subtitleLink {
                            Button(subtitleLink.phrase, action: subtitleLink.action)
                        }
                    }
            }
            content()
                .padding(.top, PulseOnboardingMetrics.subtitleToContent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The subtitle, its link phrase (if any) white and underlined.
    private func subtitleText(_ subtitle: String) -> Text {
        var text = AttributedString(subtitle)
        if let subtitleLink, let range = text.range(of: subtitleLink.phrase) {
            text[range].link = PulseOnboardingLink.url
            text[range].underlineStyle = .single
            text[range].foregroundColor = PulseTheme.textPrimary
        }
        return Text(text)
    }
}

/// Behind the pinned top bar and CTA row, so content scrolling under them fades out instead of running
/// into the arrow: the page's own gradient, opaque from each edge to the bar's bottom and the ring's top,
/// fading over the 16–24 pt beyond (Pulse's `PulseTopBackdrop` rule). The fades sit inside the 39 pt the
/// template keeps above the CTA, so over a page at rest they are invisible, being the page itself.
struct PulseOnboardingEdgeFades: View {
    var body: some View {
        GeometryReader { geo in
            PulseOnboardingBackground()
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        Rectangle().frame(height: geo.safeAreaInsets.top + PulseOnboardingMetrics.topBarHeight)
                        LinearGradient(colors: [Color.black, Color.black.opacity(0)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 16)
                        Spacer(minLength: 0)
                        LinearGradient(colors: [Color.black.opacity(0), Color.black], startPoint: .top, endPoint: .bottom)
                            .frame(height: 24)
                        Rectangle().frame(height: geo.safeAreaInsets.bottom + PulseOnboardingMetrics.ctaHeight)
                    }
                    .ignoresSafeArea()
                }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension PulseOnboardingStepPage where Content == EmptyView {
    init(title: String, subtitle: String? = nil, showsBack: Bool = true,
         trailing: PulseOnboardingTrailing = .none, art: PulseOnboardingArtSlot = .small,
         onBack: @escaping () -> Void,
         @ViewBuilder illustration: @escaping () -> Illustration, @ViewBuilder cta: @escaping () -> CTA) {
        self.init(title: title, subtitle: subtitle, showsBack: showsBack, trailing: trailing, art: art,
                  onBack: onBack, illustration: illustration, content: { EmptyView() }, cta: cta)
    }
}

/// How much room a step gives its illustration.
enum PulseOnboardingArtSlot: Equatable {
    /// The ≈90 pt, left-aligned slot of the account steps.
    case small
    /// A large centred drawing of this height (the device steps, the calibration wheel).
    case large(height: CGFloat)

    /// The device steps' strap drawing.
    static let device = PulseOnboardingArtSlot.large(height: PulseOnboardingMetrics.deviceArtHeight)

    var height: CGFloat {
        switch self {
        case .small: return PulseOnboardingMetrics.illustrationHeight
        case .large(let height): return height
        }
    }

    var isLarge: Bool { self != .small }

    /// From the drawing's bottom edge to the title's text frame. The small slot's glyphs sit on the slot's
    /// bottom edge, so the title's own cap inset makes up the rest of the 40 pt to its caps.
    var gapToTitle: CGFloat {
        switch self {
        case .small: return PulseOnboardingMetrics.illustrationToTitle - PulseOnboardingMetrics.titleCapInset
        case .large: return PulseOnboardingMetrics.largeArtToTitle
        }
    }

    /// The illustration's height on screen when the step's text and fields take `textHeight` of the
    /// `room` above the CTA: the slot's own, smaller when the step would otherwise run under the CTA (down
    /// to 60% of it), or nil to drop the illustration, which is decoration (a 6.1–6.3" phone cannot hold
    /// the four attestations under a full-size padlock; a Pro Max can).
    func fittedHeight(textHeight: CGFloat, room: CGFloat) -> CGFloat? {
        guard textHeight > 0 else { return height }
        let available = room - textHeight - gapToTitle
        if available >= height { return height }
        return available >= height * 0.6 ? available : nil
    }
}

// MARK: - The ring CTA

private struct PulseOnboardingRingStartKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}

extension EnvironmentValues {
    /// Where a step's ring arc starts as the step appears: the progress of the step being left, so the arc
    /// moves from there to this step's value instead of sweeping up from zero on every step. Nil (the
    /// first step shown) draws the step's value at once.
    var pulseOnboardingRingStart: Double? {
        get { self[PulseOnboardingRingStartKey.self] }
        set { self[PulseOnboardingRingStartKey.self] = newValue }
    }
}

/// The bottom-right control that advances a step: an UPPERCASE label, then a 78 pt ring whose arc shows
/// progress through the flow, round-capped, in the light-blue angular gradient, around a white "→".
/// Disabled, the label and arrow turn grey and the arc still shows (gap-3 §3).
struct PulseOnboardingRingButton: View {
    let title: String
    /// Progress through the flow, 0...1.
    let progress: Double
    var enabled = true
    let action: () -> Void

    @Environment(\.pulseOnboardingRingStart) private var start
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PulseOnboardingRingButtonBody(title: title, progress: progress,
                                      start: reduceMotion ? progress : (start ?? progress),
                                      enabled: enabled, action: action)
    }
}

/// The ring button itself; `start` seeds the arc once, when the step appears.
private struct PulseOnboardingRingButtonBody: View {
    let title: String
    let progress: Double
    let enabled: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The arc on screen: the previous step's value as the step appears, then this step's (0.3 s, spec
    /// §2.8), and only ever animated when the value changes.
    @State private var shown: Double

    init(title: String, progress: Double, start: Double, enabled: Bool, action: @escaping () -> Void) {
        self.title = title
        self.progress = progress
        self.enabled = enabled
        self.action = action
        _shown = State(initialValue: start)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: PulseOnboardingMetrics.labelGap) {
                Text(title)
                    .pulseText(.label)
                    .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.Onboarding.ringDisabledLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                PulseOnboardingRing(progress: shown, enabled: enabled)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .padding(.trailing, PulseOnboardingMetrics.ringTrailing - PulseTheme.Layout.pageMargin)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.bottom, PulseOnboardingMetrics.ringBottom)
        .onAppear { move(to: progress) }
        .onChange(of: progress) { _, new in move(to: new) }
        .accessibilityLabel(title)
        .accessibilityValue(String(localized: "\(Int((progress * 100).rounded())) percent through setup"))
    }

    private func move(to value: Double) {
        guard shown != value else { return }
        if reduceMotion {
            shown = value
        } else {
            withAnimation(.easeOut(duration: 0.3)) { shown = value }
        }
    }
}

/// The ring itself: a #282D30 track and the progress arc from 12 o'clock, clockwise, round caps.
struct PulseOnboardingRing: View {
    let progress: Double
    var enabled = true

    /// `PulseTheme.Onboarding.ringArc`'s colours at the sampled stops.
    private static let arc = Gradient(stops: zip(PulseTheme.Onboarding.ringArc.stops.map(\.color),
                                                 PulseOnboardingMetrics.ringArcLocations)
        .map { Gradient.Stop(color: $0, location: $1) })

    var body: some View {
        let d = PulseOnboardingMetrics.ringDiameter
        let stroke = PulseOnboardingMetrics.ringStroke
        ZStack {
            Circle()
                .stroke(PulseTheme.Onboarding.ringTrack, lineWidth: stroke)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(AngularGradient(gradient: Self.arc, center: .center, startAngle: .degrees(0),
                                        endAngle: .degrees(360)),
                        style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0.001 ? 1 : 0)
            Image(systemName: "arrow.right")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.Onboarding.ringDisabledArrow)
        }
        .padding(stroke / 2)
        .frame(width: d, height: d)
        .accessibilityHidden(true)
    }
}

/// The filled circle that replaces the ring on a commit step ("START PAIRING", blue) or the last step
/// ("DONE", green with a dark ✓): ≈72 pt, its label to the left.
struct PulseOnboardingFilledButton: View {
    enum Kind { case commit, finish }

    let title: String
    var kind: Kind = .commit
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PulseOnboardingMetrics.labelGap) {
                Text(title)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                ZStack {
                    Circle().fill(kind == .finish ? PulseTheme.Onboarding.commitGreen : PulseOnboardingColors.commitBlue)
                    Image(systemName: kind == .finish ? "checkmark" : "arrow.right")
                        .font(.system(size: 24, weight: kind == .finish ? .semibold : .regular))
                        .foregroundStyle(kind == .finish ? PulseOnboardingColors.finishGlyph : Color.white)
                }
                .frame(width: PulseOnboardingMetrics.filledDiameter, height: PulseOnboardingMetrics.filledDiameter)
                .frame(width: PulseOnboardingMetrics.ringDiameter, height: PulseOnboardingMetrics.ringDiameter)
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .padding(.trailing, PulseOnboardingMetrics.ringTrailing - PulseTheme.Layout.pageMargin)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.bottom, PulseOnboardingMetrics.ringBottom)
        .accessibilityLabel(title)
    }
}

// MARK: - Pills (pairing and status screens)

/// A full-width pill: white with black caps (the 2026 primary), or dark with a thin grey border.
struct PulseOnboardingPillStyle: ButtonStyle {
    enum Kind { case white, dark, outlineWhite }
    var kind: Kind = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pulseOnboardingText(.pill)
            .foregroundStyle(kind == .white ? Color.black : Color.white)
            // Two lines at the largest text sizes rather than a cut-off label; the pill grows to fit.
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: PulseOnboardingMetrics.pillHeight)
            .background(background)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(configuration.isPressed ? nil : PulseMotion.pressRelease, value: configuration.isPressed)
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: PulseOnboardingMetrics.pillRadius, style: .continuous)
        switch kind {
        case .white:
            shape.fill(Color.white)
        case .dark:
            shape.fill(PulseOnboardingColors.secondaryFill)
                .overlay(shape.strokeBorder(PulseOnboardingColors.secondaryBorder, lineWidth: 1))
        case .outlineWhite:
            // A full capsule, as 09b draws "DON'T SEE YOUR DEVICE?" (the filled 2026 pills keep radius 19).
            Capsule(style: .continuous).strokeBorder(Color.white, lineWidth: 1.5)
        }
    }
}

/// A pairing or status screen: top bar, an illustration band, a centred UPPERCASE title and grey
/// subtitle, and full-width pills at the bottom.
struct PulseOnboardingStatusPage<Art: View, Middle: View, Buttons: View>: View {
    let title: String
    var subtitle: String?
    var leading: PulseOnboardingTopBar.Leading = .back
    var trailing: PulseOnboardingTrailing = .none
    /// True when the title sits above the art (SEARCHING, SELECT YOUR DEVICE), false when the art leads
    /// and the title follows it (CONNECTING, CONNECTED, CONNECTION FAILED).
    var titleFirst = false
    let onLeading: () -> Void
    @ViewBuilder let art: () -> Art
    @ViewBuilder let middle: () -> Middle
    @ViewBuilder let buttons: () -> Buttons

    var body: some View {
        VStack(spacing: 0) {
            if titleFirst {
                titleBlock.padding(.top, PulseOnboardingMetrics.statusTitleTop)
                art()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                middle()
            } else {
                art()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                titleBlock
                middle()
                Spacer(minLength: 24).frame(maxHeight: 64)
            }
            // The pills' room is kept even on a screen without them (CONNECTING), so the title sits where
            // it does on every other status screen.
            VStack(spacing: 12) { buttons() }
                .frame(minHeight: 112, alignment: .bottom)
                .padding(.horizontal, PulseOnboardingMetrics.pillSideMargin)
                .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            PulseOnboardingTopBar(leading: leading, trailing: trailing, onLeading: onLeading)
        }
        .background(PulseOnboardingBackground())
    }

    private var titleBlock: some View {
        VStack(spacing: 10) {
            Text(title)
                .pulseOnboardingText(.statusTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .pulseOnboardingText(.statusBody)
                    .foregroundStyle(PulseTheme.Onboarding.subtitle.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 36)
    }
}

// MARK: - Fields and rows

/// A field's caps label: 12 pt Bold, tracked +1.5, #C0C1C5, inset 4 pt.
struct PulseOnboardingFieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .pulseOnboardingText(.fieldLabel)
            .foregroundStyle(PulseTheme.Onboarding.fieldLabel)
            .padding(.leading, 4)
            .accessibilityHidden(true)
    }
}

/// The inset field box: darker than the page (#0C1013), a 1 pt #2B3034 border, radius 11, 45 pt.
struct PulseOnboardingFieldBox<Content: View>: View {
    var invalid = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: PulseOnboardingMetrics.fieldHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: PulseOnboardingMetrics.fieldRadius, style: .circular)
                    .fill(PulseTheme.Onboarding.fieldFill))
            .overlay(
                RoundedRectangle(cornerRadius: PulseOnboardingMetrics.fieldRadius, style: .circular)
                    .strokeBorder(invalid ? PulseTheme.Onboarding.validationBorder : PulseTheme.Onboarding.fieldBorder,
                                  lineWidth: 1))
    }
}

/// The 30 pt checkbox: a 2 pt white outline, or white with a black ✓ when checked.
struct PulseOnboardingCheckbox: View {
    let checked: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PulseOnboardingMetrics.checkboxRadius, style: .continuous)
        ZStack {
            if checked {
                shape.fill(Color.white)
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)
            } else {
                shape.strokeBorder(Color.white, lineWidth: 2)
            }
        }
        .frame(width: PulseOnboardingMetrics.checkbox, height: PulseOnboardingMetrics.checkbox)
        .accessibilityHidden(true)
    }
}

/// A selectable option row (country, gender, strap model): a slate card that turns white with dark text
/// when chosen, as WHOOP's country list does (onboarding/16a).
struct PulseOnboardingOptionRow<Leading: View>: View {
    let title: String
    var subtitle: String?
    let selected: Bool
    var centred = false
    let action: () -> Void
    @ViewBuilder let leading: () -> Leading

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leading()
                VStack(alignment: centred ? .center : .leading, spacing: 2) {
                    Text(title)
                        .pulseText(.cardTitle)
                        .foregroundStyle(selected ? Color.black : PulseTheme.textPrimary)
                        .multilineTextAlignment(centred ? .center : .leading)
                    if let subtitle {
                        Text(subtitle)
                            .pulseText(.secondary)
                            .foregroundStyle(selected ? Color.black.opacity(0.6) : PulseTheme.textSecondary)
                            .multilineTextAlignment(centred ? .center : .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: centred ? .center : .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: PulseOnboardingMetrics.optionHeight)
            .background(
                RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                    .fill(selected ? Color.white : PulseOnboardingColors.optionFill))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

extension PulseOnboardingOptionRow where Leading == EmptyView {
    init(title: String, subtitle: String? = nil, selected: Bool, centred: Bool = false, action: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, selected: selected, centred: centred, action: action,
                  leading: { EmptyView() })
    }
}

/// A check line: a small teal ✓ and secondary text (the device steps' instructions).
struct PulseOnboardingCheckLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PulseTheme.positive)
                .accessibilityHidden(true)
            Text(text)
                .pulseOnboardingText(.checkLine)
                .foregroundStyle(PulseTheme.Onboarding.subtitle)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Where in the flow the arc stands: step `index` (1-based) of `count`.
func pulseOnboardingProgress(_ index: Int, of count: Int) -> Double {
    guard count > 0 else { return 0 }
    return min(1, max(0, Double(index) / Double(count)))
}
#endif
