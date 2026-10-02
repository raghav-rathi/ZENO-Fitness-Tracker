#if os(iOS)
import SwiftUI

// MARK: - Screen scaffold (WHOOP_UI_SPEC §1.1, §1.2, §1.5, §2.1; DR §1.1)
//
// Every Pulse screen is a scroll view of cards on the fixed slate gradient. The scaffold owns the parts
// that must be identical everywhere:
//   - the viewport-fixed gradient BEHIND the scroll view;
//   - 16 pt page margins;
//   - the navigation header (centred UPPERCASE title, "‹" or "✕", one trailing accessory), or none (Home);
//   - once content scrolls under the bar (or the status bar), the page gradient behind it with a soft
//     fade below, never a flat band (`PulseTopBackdrop`);
//   - on a tab root: the bottom scrim (content fades to black 60% over 28 pt above the floating tab bar,
//     the strip under the bar solid #010101) and enough bottom inset that the last card clears the bar;
//   - on a pushed screen: the floating Coach button or summary pill, in the tab root's exact spot, and the
//     80 pt bottom inset rule (every screen that shows them keeps 80 pt clear, so they never cover a row's
//     accessory);
//   - pull to refresh, scroll-to-top on a tab re-tap, and the DEBUG `--pulse-scroll` anchors.
//
//     PulseScreenScaffold(title: "HEALTH MONITOR", coach: .button) {
//         PulseCard { … }
//     }

/// Where a screen sits, which decides its chrome.
enum PulseScreenRole: Equatable {
    /// The root of a tab: floating tab bar below, bottom scrim, no back button.
    case tabRoot
    /// Pushed (or a modal flow's root): back or close at the left, optional floating coach.
    case pushed
}

/// Measurements the shell publishes so scaffolds clear the floating chrome on every device.
struct PulseChromeMetrics: Equatable {
    /// The bottom content inset a tab root needs to clear the floating tab bar and its scrim, measured
    /// from the bottom safe-area edge.
    var tabRootBottomInset: CGFloat = PulseTheme.Layout.floatingChromeInset
    /// The distance from the screen's bottom edge to the capsule's top edge (where the scrim ends).
    var barTopFromScreenBottom: CGFloat = PulseTheme.TabBarMetrics.bottomOffset(safeAreaBottom: 34)
        + PulseTheme.TabBarMetrics.height
    /// The distance from the screen's bottom edge to the capsule's bottom edge: the floating Coach button
    /// and summary pill on a pushed screen sit on the same line.
    var barBottomFromScreenBottom: CGFloat = PulseTheme.TabBarMetrics.bottomOffset(safeAreaBottom: 34)
}

private struct PulseChromeMetricsKey: EnvironmentKey {
    static let defaultValue = PulseChromeMetrics()
}

extension EnvironmentValues {
    var pulseChrome: PulseChromeMetrics {
        get { self[PulseChromeMetricsKey.self] }
        set { self[PulseChromeMetricsKey.self] = newValue }
    }
}

/// The named coordinate space of a scaffold's scroll view (for sticky headers).
enum PulseScrollSpace {
    static let name = "pulse.scroll"
}

/// How far the page gradient behind a pinned top reaches once content scrolls under it.
enum PulseTopBackdropStyle: Equatable {
    /// To the bar's bottom (or the status bar's), then a 24 pt fade.
    case automatic
    /// A pinned row below the bar: opaque `extra` further, then fading over `fade` (Home's sticky rings).
    case extended(extra: CGFloat, fade: CGFloat)
}

private struct PulseScrollTopKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

struct PulseScreenScaffold<Content: View>: View {
    let title: String?
    let titlePager: PulseNavTitlePager?
    let role: PulseScreenRole
    let trailing: PulseNavTrailing
    let coach: PulseCoachAccessory
    let coachSeed: String?
    let background: PulseBackground.Style
    let showsNavigationBar: Bool
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let refresh: (() async -> Void)?
    let ready: Bool
    let topBackdrop: PulseTopBackdropStyle
    @ViewBuilder let content: () -> Content

    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    @Environment(\.pulseChrome) private var chrome
    @Environment(\.pulseCoach) private var coachContext
    /// The content's top edge at rest, in the scroll view's space (its first reported position).
    @State private var restTop: CGFloat?
    /// True while content sits under the bar (or the status bar on Home): the top backdrop shows.
    @State private var scrolledUnder = false

    private static var topID: String { "pulse.top" }

    /// - Parameters:
    ///   - title: the centred UPPERCASE navigation title; nil shows no title.
    ///   - titlePager: "‹ TITLE ›" in the bar's centre instead of a plain title (the Sleep dive's nights).
    ///   - role: `.tabRoot` or `.pushed`.
    ///   - trailing: the navigation bar's right accessory (ⓘ, achievement chip, ⚙ …).
    ///   - coach: what floats at the bottom of a pushed screen (`.button`, `.pill(summary:)`).
    ///   - coachSeed: the page context handed to the Coach when it opens from here.
    ///   - background: the slate gradient, or near-black for orb pages.
    ///   - showsNavigationBar: false hides the bar entirely (Home).
    ///   - spacing: the gap between top-level blocks.
    ///   - refresh: pull-to-refresh action, if the screen supports it.
    ///   - ready: whether the content has loaded (gates the DEBUG `--pulse-scroll` jump).
    ///   - topBackdrop: how far the page gradient behind the top reaches once content scrolls under it.
    init(title: String? = nil,
         titlePager: PulseNavTitlePager? = nil,
         role: PulseScreenRole = .pushed,
         trailing: PulseNavTrailing = .none,
         coach: PulseCoachAccessory = .none,
         coachSeed: String? = nil,
         background: PulseBackground.Style = .gradient,
         showsNavigationBar: Bool = true,
         spacing: CGFloat = PulseTheme.Layout.stackGap,
         horizontalPadding: CGFloat = PulseTheme.Layout.pageMargin,
         topPadding: CGFloat = PulseTheme.Layout.stackGap,
         refresh: (() async -> Void)? = nil,
         ready: Bool = true,
         topBackdrop: PulseTopBackdropStyle = .automatic,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.titlePager = titlePager
        self.role = role
        self.trailing = trailing
        self.coach = coach
        self.coachSeed = coachSeed
        self.background = background
        self.showsNavigationBar = showsNavigationBar
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.refresh = refresh
        self.ready = ready
        self.topBackdrop = topBackdrop
        self.content = content
    }

    /// The bottom inset rule: clear the tab bar on a root, 80 pt under a floating coach, else a margin.
    private var bottomInset: CGFloat {
        switch role {
        case .tabRoot:
            return max(PulseTheme.Layout.floatingChromeInset, chrome.tabRootBottomInset)
        case .pushed:
            let floats = coach != .none && coachContext.availability != .off
            return floats ? PulseTheme.Layout.floatingChromeInset : PulseTheme.Layout.plainBottomInset
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // The top marker: the scroll-to-top target, and where the content's top edge is.
                    Color.clear
                        .frame(height: 0)
                        .id(Self.topID)
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: PulseScrollTopKey.self,
                                                   value: geo.frame(in: .named(PulseScrollSpace.name)).minY)
                        })
                    VStack(alignment: .leading, spacing: spacing) {
                        content()
                        Color.clear.frame(height: max(0, bottomInset - spacing)).id("pulse.bottom")
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, topPadding)
                }
            }
            .coordinateSpace(name: PulseScrollSpace.name)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .modifier(PulseRefreshModifier(refresh: refresh))
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(Self.topID, anchor: .top) }
            }
            .onPreferenceChange(PulseScrollTopKey.self) { top in
                guard let top else { return }
                if restTop == nil { restTop = top }
                let under = top < (restTop ?? top) - 1
                if under != scrolledUnder { scrolledUnder = under }
            }
            .pulseDebugScroll(proxy, ready: ready)
        }
        .background(PulseBackground(style: background))
        .overlay(alignment: .top) {
            backdrop
                .opacity(scrolledUnder || topBackdrop != .automatic ? 1 : 0)
                .animation(PulseMotion.chrome, value: scrolledUnder)
        }
        .overlay {
            if role == .tabRoot { PulseTabBarScrim() }
        }
        .overlay {
            if role == .pushed { PulseFloatingCoach(accessory: coach, seed: coachSeed) }
        }
        .modifier(PulseScaffoldChrome(title: title, titlePager: titlePager, trailing: trailing,
                                      showsNavigationBar: showsNavigationBar, showsBack: role == .pushed))
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var backdrop: some View {
        switch topBackdrop {
        case .automatic:
            PulseTopBackdrop(style: background)
        case .extended(let extra, let fade):
            PulseTopBackdrop(style: background, extra: extra, fade: fade)
        }
    }
}

private struct PulseRefreshModifier: ViewModifier {
    let refresh: (() async -> Void)?

    func body(content: Content) -> some View {
        if let refresh {
            content.refreshable { await refresh() }
        } else {
            content
        }
    }
}

private struct PulseScaffoldChrome: ViewModifier {
    let title: String?
    let titlePager: PulseNavTitlePager?
    let trailing: PulseNavTrailing
    let showsNavigationBar: Bool
    let showsBack: Bool

    func body(content: Content) -> some View {
        if showsNavigationBar {
            content.pulseNavHeader(title, titlePager: titlePager, trailing: trailing, showsBack: showsBack)
        } else {
            content.toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Bottom scrim

/// The scrim under the floating tab bar: clear → black 60% over the 28 pt above the capsule, then the solid
/// #010101 strip beside and below it, down to the screen's bottom edge (DR §1.1). It never takes touches.
struct PulseTabBarScrim: View {
    @Environment(\.pulseChrome) private var chrome

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LinearGradient(colors: [PulseTheme.scrim.opacity(0), PulseTheme.scrim], startPoint: .top, endPoint: .bottom)
                .frame(height: PulseTheme.Layout.scrimHeight)
            PulseTheme.barStrip
                .frame(height: chrome.barTopFromScreenBottom)
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Add the tab-bar scrim to a tab root that does not use `PulseScreenScaffold`.
    func pulseTabBarScrim() -> some View {
        overlay { PulseTabBarScrim() }
    }
}

// MARK: - Scroll tracking (sticky headers)

private struct PulseScrolledPastKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    /// Reports whether this view's bottom edge has scrolled above `threshold` in the enclosing scaffold's
    /// scroll view, e.g. to pin the mini-ring header once the Home dials scroll off. One per screen.
    func pulseScrolledPast(_ isPast: Binding<Bool>, threshold: CGFloat = 0) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: PulseScrolledPastKey.self,
                                       value: geo.frame(in: .named(PulseScrollSpace.name)).maxY < threshold)
            }
        )
        .onPreferenceChange(PulseScrolledPastKey.self) { past in
            if isPast.wrappedValue != past { isPast.wrappedValue = past }
        }
    }
}
#endif
