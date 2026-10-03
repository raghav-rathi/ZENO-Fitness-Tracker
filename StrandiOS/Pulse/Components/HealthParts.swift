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
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: PulseTheme.Layout.minTapTarget, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// A navigation bar with a second line under the title ("HEALTHSPAN" over "THIS WEEK SO FAR", 10 pt Bold
/// caps at 50%, reviews/r119), otherwise Pulse's own bar: "‹" (or "✕" at a modal root) and one trailing
/// accessory, centred 23.5 pt under the safe top. `PulseNavBar` has no subtitle, so this wraps its pieces.
struct HealthNavBar: View {
    let title: String
    var subtitle: String?
    var trailing: PulseNavTrailing = .none
    let leading: PulseNavLeading
    let onLeading: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title)
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.9)
                        .textCase(.uppercase)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin + PulseTheme.Layout.minTapTarget + 8)
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

private struct HealthNavHeaderModifier: ViewModifier {
    let title: String
    let subtitle: String?
    let trailing: PulseNavTrailing

    @Environment(\.pulseModalRoot) private var modalRoot
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HealthNavBar(title: title, subtitle: subtitle, trailing: trailing,
                             leading: modalRoot ? .close : .back, onLeading: { dismiss() })
            }
            .background(PulseSwipeBackEnabler())
    }
}

extension View {
    /// Pulse's navigation header with a subtitle line, for a scaffold built with `showsNavigationBar: false`.
    func healthNavHeader(_ title: String, subtitle: String?, trailing: PulseNavTrailing = .none) -> some View {
        modifier(HealthNavHeaderModifier(title: title, subtitle: subtitle, trailing: trailing))
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

/// A sentence-case section header ("More from ZENO", "Sessions", "Sleep"), 20 pt Semibold, with an
/// optional caption at the right.
struct HealthSectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .pulseText(.sectionTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
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

/// The near-black page with a soft glow in the orb's hue over its top (§3.20 item 1; reviews/r44: strongest
/// at the top right, #634312 under amber, gone by the left edge and ≈300 pt down). Viewport-fixed: draw it
/// behind the scroll view.
struct HealthPageBackground: View {
    let hue: HealthAgeHue

    var body: some View {
        let glow = HealthPalette.orb(hue).glow
        ZStack {
            LinearGradient(colors: [HealthPalette.pageTop, HealthPalette.pageBottom], startPoint: .top,
                           endPoint: .bottom)
            RadialGradient(colors: [glow.opacity(0.95), glow.opacity(0.45), glow.opacity(0)],
                           center: UnitPoint(x: 0.82, y: -0.02), startRadius: 0, endRadius: 430)
            LinearGradient(stops: [
                .init(color: glow.opacity(0.35), location: 0),
                .init(color: glow.opacity(0.12), location: 0.22),
                .init(color: glow.opacity(0), location: 0.42),
            ], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Behind the pinned title once content scrolls under it: the same glowing page, opaque to the bar's foot
/// and fading out over 24 pt, so the orb turns into the half sphere WHOOP shows when scrolled (reviews/r44)
/// and cards slide under the title instead of over it.
struct HealthTopBackdrop: View {
    let hue: HealthAgeHue
    var fade: CGFloat = PulseTheme.Header.barFade

    var body: some View {
        GeometryReader { geo in
            let solid = geo.safeAreaInsets.top
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
#endif
