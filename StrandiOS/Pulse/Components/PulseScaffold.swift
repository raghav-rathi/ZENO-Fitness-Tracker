#if os(iOS)
import SwiftUI

// MARK: - Screen scaffold (WHOOP_UI_SPEC §1.1, §1.2, §1.5, §2.1; DR §1.1)
//
// Every Pulse screen is a scroll view of cards on the fixed slate gradient. The scaffold owns the parts
// that must be identical everywhere:
//   - the viewport-fixed gradient BEHIND the scroll view;
//   - 16 pt page margins;
//   - the navigation header (centred UPPERCASE title, "‹" or "✕", one trailing accessory), or none (Home);
//   - on a tab root: the bottom scrim (content fades to black over 28 pt above the floating tab bar, the
//     strip under the bar near-black) and enough bottom inset that the last card clears the bar;
//   - on a pushed screen: the floating Coach button or summary pill, and the 80 pt bottom inset rule
//     (every screen that shows them keeps 80 pt clear, so they never cover a row's accessory);
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

struct PulseScreenScaffold<Content: View>: View {
    let title: String?
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
    @ViewBuilder let content: () -> Content

    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    @Environment(\.pulseChrome) private var chrome
    @Environment(\.pulseCoach) private var coachContext

    private static var topID: String { "pulse.top" }

    /// - Parameters:
    ///   - title: the centred UPPERCASE navigation title; nil shows no title.
    ///   - role: `.tabRoot` or `.pushed`.
    ///   - trailing: the navigation bar's right accessory (ⓘ, achievement chip, ⚙ …).
    ///   - coach: what floats at the bottom of a pushed screen (`.button`, `.pill(summary:)`).
    ///   - coachSeed: the page context handed to the Coach when it opens from here.
    ///   - background: the slate gradient, or near-black for orb pages.
    ///   - showsNavigationBar: false hides the bar entirely (Home).
    ///   - spacing: the gap between top-level blocks.
    ///   - refresh: pull-to-refresh action, if the screen supports it.
    ///   - ready: whether the content has loaded (gates the DEBUG `--pulse-scroll` jump).
    init(title: String? = nil,
         role: PulseScreenRole = .pushed,
         trailing: PulseNavTrailing = .none,
         coach: PulseCoachAccessory = .none,
         coachSeed: String? = nil,
         background: PulseBackground.Style = .gradient,
         showsNavigationBar: Bool = true,
         spacing: CGFloat = PulseTheme.Layout.stackGap,
         horizontalPadding: CGFloat = PulseTheme.Layout.pageMargin,
         topPadding: CGFloat = 8,
         refresh: (() async -> Void)? = nil,
         ready: Bool = true,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
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
                VStack(alignment: .leading, spacing: spacing) {
                    Color.clear.frame(height: 0).id(Self.topID)
                    content()
                    Color.clear.frame(height: max(0, bottomInset - spacing)).id("pulse.bottom")
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
            }
            .coordinateSpace(name: PulseScrollSpace.name)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .modifier(PulseRefreshModifier(refresh: refresh))
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(Self.topID, anchor: .top) }
            }
            .pulseDebugScroll(proxy, ready: ready)
        }
        .background(PulseBackground(style: background))
        .overlay {
            if role == .tabRoot { PulseTabBarScrim() }
        }
        .overlay(alignment: .bottom) {
            if role == .pushed { PulseFloatingCoach(accessory: coach, seed: coachSeed) }
        }
        .modifier(PulseScaffoldChrome(title: title, trailing: trailing, showsNavigationBar: showsNavigationBar))
        .environment(\.colorScheme, .dark)
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
    let trailing: PulseNavTrailing
    let showsNavigationBar: Bool

    func body(content: Content) -> some View {
        if showsNavigationBar {
            content.pulseNavHeader(title, trailing: trailing)
        } else {
            content.toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Bottom scrim

/// The scrim under the floating tab bar: clear → black 95% over the 28 pt above the capsule, then a
/// near-black strip down to the screen's bottom edge. It never takes touches.
struct PulseTabBarScrim: View {
    @Environment(\.pulseChrome) private var chrome

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LinearGradient(colors: [PulseTheme.scrim.opacity(0), PulseTheme.scrim], startPoint: .top, endPoint: .bottom)
                .frame(height: PulseTheme.Layout.scrimHeight)
            PulseTheme.barStrip.opacity(0.97)
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
