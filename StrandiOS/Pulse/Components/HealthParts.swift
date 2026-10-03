#if os(iOS)
import SwiftUI

// MARK: - Small pieces the health screens share

/// "‹ TODAY ›" / "‹ JUL 19 - JUL 25 ›": a centred caps title with its chevrons hugging it, no capsule (the
/// Stress Monitor's day pager and Healthspan's week pager, completeness-critic/14, reviews/r119). 13 pt
/// Bold caps; "›" white 40% and disabled at the newest page.
struct HealthPager: View {
    let title: String
    var canGoBack: Bool = true
    var canGoForward: Bool = false
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            chevron("chevron.left", enabled: canGoBack, label: String(localized: "Previous"), action: onBack)
            Text(title)
                .pulseText(.menuLabel)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            chevron("chevron.right", enabled: canGoForward, label: String(localized: "Next"), action: onForward)
        }
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func chevron(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .healthGlyph(.pagerChevron)
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: PulseTheme.Layout.minTapTarget, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// A navigation bar with a second line hanging under the title ("HEALTHSPAN" over "FINAL IN 3 DAYS",
/// reviews/r119), otherwise Pulse's own bar: "‹" (or "✕" at a modal root) and one trailing accessory,
/// centred 23.5 pt under the safe top. The title sits on the bar's centre line like every other title (the
/// subtitle hangs below it, 11 pt Bold caps at 50%, scaling with the text); `showsTitle` false hides both
/// while a compact header takes the bar's place. `PulseNavBar` has no subtitle, so this wraps its pieces.
struct HealthNavBar: View {
    let title: String
    var subtitle: String?
    var showsTitle = true
    var trailing: PulseNavTrailing = .none
    let leading: PulseNavLeading
    let onLeading: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .overlay(alignment: .bottom) {
                    if let subtitle {
                        Text(subtitle)
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .lineLimit(1)
                            .fixedSize()
                            .offset(y: 15)
                    }
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin + PulseTheme.Layout.minTapTarget + 8)
                .opacity(showsTitle ? 1 : 0)
                .accessibilityHidden(!showsTitle)
            HStack(spacing: 0) {
                switch leading {
                case .none: EmptyView()
                case .back: PulseBackButton(action: onLeading)
                case .close: PulseCloseButton(action: onLeading)
                }
                Spacer(minLength: 0)
                switch trailing {
                case .info(let action):
                    PulseInfoButton(action: action)
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .frame(height: PulseTheme.Header.navBar)
        .padding(.top, PulseTheme.Header.navBarTop)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// The "how it's calculated" sheet behind a health screen's ⓘ: a title and plain paragraphs, dark, with
/// "Done". ZENO keeps WHOOP's light ⓘ sheets dark (§1.5 [Z]).
struct HealthInfoSheet: View {
    let title: String
    let paragraphs: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, text in
                        Text(text)
                            .pulseText(.trendInsight)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(PulseTheme.Layout.pageMargin)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .pulsePage()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// A row of `count` equal segments, the first `filled` lit: the Health Monitor's "N more nights" banner
/// (onboarding/32b: 7 segments).
struct HealthSegmentBar: View {
    let count: Int
    let filled: Int
    var fill: Color = Color.white.opacity(0.85)
    var empty: Color = HealthPalette.monitorBannerSegment

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<max(1, count), id: \.self) { i in
                Capsule(style: .circular)
                    .fill(i < filled ? fill : empty)
                    .frame(height: 4)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A sentence-case section header ("More from ZENO", "Sessions", "Trend View"), 20 pt Semibold.
struct HealthSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .pulseText(.sectionTitle)
            .foregroundStyle(PulseTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The wellness disclaimer under a hairline (§3.20 item 10).
struct HealthDisclaimer: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PulseDivider()
            Text(text)
                .pulseText(.rowSubline)
                .foregroundStyle(HealthPalette.disclaimer)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
// MARK: - The Health tab and Healthspan page

/// The Health tab's page: near-black at the top opening into the standard slate by ≈450 pt, with a glow in
/// the orb's hue blooming from the top-right corner (§3.20 item 1; reviews/r44 and health-more-2026/16 keep
/// the left edge near-black, #0B0B0B at y = 60, while the top-right reads #5F4014 under amber and #4B2151
/// while unlocking). Viewport-fixed: draw it behind the scroll view.
struct HealthPageBackground: View {
    let hue: HealthAgeHue

    var body: some View {
        let glow = HealthPalette.orb(hue).glow
        ZStack {
            LinearGradient(stops: HealthPalette.tabPageStops, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [glow, glow.opacity(0.5), glow.opacity(0)],
                           center: UnitPoint(x: 1, y: 0), startRadius: 0, endRadius: 380)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Behind the pinned title once content scrolls under it: the same glowing page, opaque to ≈12 pt under
/// the title's baseline and fading out over 12 pt, so the orb turns into the half sphere WHOOP shows when
/// scrolled, cut just under the title (reviews/r44: the cut 12.7 pt below the baseline), and cards slide
/// under the title instead of over it.
struct HealthTopBackdrop: View {
    let hue: HealthAgeHue
    /// How far above the bar's foot the opaque part stops.
    var trim: CGFloat = 14
    var fade: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let solid = max(0, geo.safeAreaInsets.top - trim)
            HealthPageBackground(hue: hue)
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        Rectangle().frame(height: solid)
                        LinearGradient(colors: [Color.black, Color.black.opacity(0)], startPoint: .top,
                                       endPoint: .bottom)
                            .frame(height: fade)
                        Spacer(minLength: 0)
                    }
                    .ignoresSafeArea()
                }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A caps label with its own tracking, on one line when it fits and wrapped between words when it does
/// not (never inside one). The Health Monitor tiles track their caps at 0.3 and let a label that misses one
/// line by a few points shrink to fit it (to 0.94), so "BLOOD OXYGEN (SPO₂)" keeps to one line as WHOOP
/// sets it (help-center/87, reviews/33); SF Pro runs wider than WHOOP's face, so 11 pt with the shared
/// label's 1.0 tracking wrapped it.
struct HealthTrackedLabel: View {
    let text: String
    var tracking: CGFloat = 0.3
    /// The smallest scale the one-line form may shrink to before the label wraps instead.
    var minimumScale: CGFloat = 0.94

    @ScaledMetric(relativeTo: .caption2) private var size: CGFloat = PulseTextStyle.label.spec.size
    @State private var available: CGFloat = 0

    init(_ text: String, tracking: CGFloat = 0.3, minimumScale: CGFloat = 0.94) {
        self.text = text
        self.tracking = tracking
        self.minimumScale = minimumScale
    }

    private var pointSize: CGFloat { max(PulseTextStyle.label.spec.size, size) }
    private var kern: CGFloat { tracking * pointSize / PulseTextStyle.label.spec.size }

    private var words: [String] {
        text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    /// The one-line width at full size, measured with the face the label renders in.
    private var naturalWidth: CGFloat {
        let font = UIFont.systemFont(ofSize: pointSize, weight: .bold)
        return ceil((text.uppercased() as NSString).size(withAttributes: [.font: font, .kern: kern]).width)
    }

    var body: some View {
        let font = PulseTextStyle.label.spec.font(size: pointSize)
        Group {
            if available > 0 && naturalWidth * minimumScale <= available {
                styled(Text(text), font: font)
                    .lineLimit(1)
                    .minimumScaleFactor(minimumScale)
            } else {
                PulseWordFlow(alignment: .leading, spacing: pointSize * 0.28 + kern, lineSpacing: 2) {
                    ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                        styled(Text(word), font: font)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { available = geo.size.width }
                .onChange(of: geo.size.width) { _, width in available = width }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func styled(_ text: Text, font: Font) -> some View {
        text.font(font)
            .tracking(kern)
            .textCase(.uppercase)
    }
}

/// Healthspan's page: flat slate (#111518; reviews/29 and r119 below the orb), viewport-fixed. The black
/// behind the orb belongs to the content and scrolls away with it (`HealthspanTopShade`): scrolled, WHOOP's
/// Healthspan is slate to the top of the screen (reviews/29, middle panel, behind the compact header).
struct HealthspanPageBackground: View {
    var body: some View {
        HealthPalette.healthspanSlate
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// The black behind Healthspan's orb, attached to the orb so it scrolls away with it: from far above (the
/// pager, the bar, an overscroll) to 0.53 of the orb down, then fading into the slate page by 0.85 of it
/// (reviews/r119 at rest: black to ≈350 pt, slate from ≈450 pt, with the 312 pt orb's top at 186 pt). Put it
/// behind the orb with `.background(alignment: .top)`.
struct HealthspanTopShade: View {
    let diameter: CGFloat
    var above: CGFloat = 900

    var body: some View {
        let blackEnd = diameter * 0.53
        let clearAt = diameter * 0.85
        let total = above + clearAt
        LinearGradient(stops: [
            .init(color: HealthPalette.healthspanTop, location: 0),
            .init(color: HealthPalette.healthspanTop, location: (above + blackEnd) / total),
            .init(color: HealthPalette.healthspanTop.opacity(0), location: 1),
        ], startPoint: .top, endPoint: .bottom)
            .frame(width: 1200, height: total)
            .offset(y: -above)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Behind Healthspan's pinned bar once content scrolls under it: `colour` (the black of the orb's top, or
/// the slate under the compact header) from the screen's top to `extra` below the bar, fading over `fade`.
struct HealthspanBarBackdrop: View {
    let colour: Color
    var extra: CGFloat = 0
    var fade: CGFloat = PulseTheme.Header.barFade

    var body: some View {
        GeometryReader { geo in
            let solid = max(0, geo.safeAreaInsets.top + extra)
            colour
                .ignoresSafeArea()
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        Rectangle().frame(height: solid)
                        LinearGradient(colors: [Color.black, Color.black.opacity(0)], startPoint: .top,
                                       endPoint: .bottom)
                            .frame(height: fade)
                        Spacer(minLength: 0)
                    }
                    .ignoresSafeArea()
                }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// How the health screens print stress time. ZENO scores stress by the hour (`DaytimeStress.bucketSeconds`
/// is 3600), so a duration prints in hours ("4 h"), never as an h:mm that would claim WHOOP's minute
/// precision ("0:44"; ARCHITECTURE §9). A finer curve would print its own fraction ("1.5 h").
enum HealthFormat {
    /// "4" with "h", or with "hrs" / "hr" in the `long` form the Health tab's card prints.
    static func stressHours(minutes: Int, long: Bool = false) -> (value: String, unit: String) {
        let value = minutes % 60 == 0 ? "\(minutes / 60)" : PulseFormat.oneDecimal(Double(minutes) / 60)
        guard long else { return (value, String(localized: "h")) }
        return (value, minutes == 60 ? String(localized: "hr") : String(localized: "hrs"))
    }

    /// "4 hours", "1 hour", "3 hr 30 min", "40 min": stress time in a sentence or for VoiceOver.
    static func spokenHours(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return String(localized: "\(m) min") }
        if m == 0 { return h == 1 ? String(localized: "1 hour") : String(localized: "\(h) hours") }
        return String(localized: "\(h) hr \(m) min")
    }
}
#endif
