#if os(iOS)
import SwiftUI
import UIKit

// MARK: - Navigation header (WHOOP_UI_SPEC §1.5)
//
// No large titles and no system bar. Pulse draws its own 44 pt row, centred 23.5 pt below the safe-area
// top (deep-dives-2026/56, 17b): a thin white "‹" (12 × 22 pt, its left edge 32 pt from the screen edge, in
// a 44 pt frame at the 16 pt margin), a centred UPPERCASE 12 pt Bold title tracked 1.2 ("TODAY",
// "WED, JUN 4", "HEALTH MONITOR"), and one trailing accessory in a 44 pt frame at the right margin. A modal
// flow's root shows "✕" in the back button's place. The interactive swipe-back keeps working
// (`PulseSwipeBackEnabler`).
//
// The bar has no fill of its own. While content scrolls under it, the scaffold draws the viewport-fixed
// page gradient behind it and lets content fade in over 24 pt below it (`PulseTopBackdrop`), as WHOOP
// does; there is never a flat band with a hard edge.

/// What sits at the right of a Pulse navigation bar.
enum PulseNavTrailing {
    case none
    /// The outlined ⓘ (27.5 pt, white 50%) that opens an explainer sheet.
    case info(() -> Void)
    /// The pillar's achievement chip: badge glyph, tint and count, and what VoiceOver says for it (the badge
    /// and what its count counts, "Green Light: 3 Green Recoveries"), in place of the chip's bare count.
    case achievement(symbol: String, tint: Color, count: Int, accessibilityLabel: String, action: () -> Void)
    /// A plain glyph: ⚙ (Stress Monitor, Menstrual), a history clock (Coach), "?" (Sleep Planner), "•••".
    case symbol(String, accessibilityLabel: String, action: () -> Void)
    /// A glyph of the screen's own that no symbol draws (WHOOP's outlined "ooo"): `draw` paints it into the
    /// 44 pt slot (its size), stroking or filling with `.foreground`, which is the bar's white.
    case custom(accessibilityLabel: String, action: () -> Void, draw: (inout GraphicsContext, CGSize) -> Void)

    var isNone: Bool {
        if case .none = self { return true }
        return false
    }
}

private struct PulseModalRootKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True for the root view of a modally presented Pulse flow: its header shows "✕", not "‹". The shell's
    /// modal host sets it; every pushed destination resets it.
    var pulseModalRoot: Bool {
        get { self[PulseModalRootKey.self] }
        set { self[PulseModalRootKey.self] = newValue }
    }
}

/// The outlined ⓘ circle (27.5 pt, white 50%).
struct PulseInfoButton: View {
    var accessibilityLabel: String = String(localized: "How it's calculated")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().strokeBorder(PulseTheme.textTertiary, lineWidth: 1.5)
                Image(systemName: "info")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            .frame(width: 27.5, height: 27.5)
            .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// "✕", white, for a modal flow's root: WHOOP's bold cross, ≈17 pt across with a ≈2.5 pt stroke
/// (reviews/r134, profile-community-2026/55: 51–52 px at 3x), in a 44 pt frame. A `compact` one keeps the
/// lighter 17 pt Regular cross (≈13 pt across) for a dialog card's corner, where WHOOP's is smaller still
/// (onboarding/41).
struct PulseCloseButton: View {
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(compact ? .system(size: 17, weight: .regular) : .system(size: 22, weight: .semibold))
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Close"))
    }
}

/// The thin "‹" WHOOP draws: 12 × 22 pt, two strokes meeting at the left.
struct PulseBackChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

/// "‹" in its 44 pt frame.
struct PulseBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PulseBackChevronShape()
                .stroke(PulseTheme.textPrimary, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .frame(width: PulseTheme.Header.backChevron.width - 2.2,
                       height: PulseTheme.Header.backChevron.height - 2.2)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Back"))
    }
}

/// A title that steps through days or nights: "‹ TODAY ›" in the bar's centre (the Sleep dive's nights).
struct PulseNavTitlePager {
    let title: String
    var canGoBack: Bool = true
    var canGoForward: Bool = false
    let onBack: () -> Void
    let onForward: () -> Void
}

/// What sits at the left of a Pulse bar.
enum PulseNavLeading: Equatable {
    /// Nothing: a tab root.
    case none
    /// "‹": a pushed screen.
    case back
    /// "✕": a modal flow's root.
    case close
}

/// The bar itself: leading control, centred title (or title pager), trailing accessory.
struct PulseNavBar: View {
    var title: String?
    var titlePager: PulseNavTitlePager?
    var leading: PulseNavLeading = .back
    var trailing: PulseNavTrailing = .none
    let onLeading: () -> Void

    var body: some View {
        ZStack {
            titleView
                .padding(.horizontal, PulseTheme.Layout.pageMargin + PulseTheme.Layout.minTapTarget + 8)
            HStack(spacing: 0) {
                switch leading {
                case .none: EmptyView()
                case .back: PulseBackButton(action: onLeading)
                case .close: PulseCloseButton(action: onLeading)
                }
                Spacer(minLength: 0)
                trailingView
                    .frame(minWidth: PulseTheme.Layout.minTapTarget, minHeight: PulseTheme.Layout.minTapTarget,
                           alignment: .trailing)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .frame(height: PulseTheme.Header.navBar)
        .padding(.top, PulseTheme.Header.navBarTop)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    @ViewBuilder
    private var titleView: some View {
        if let pager = titlePager {
            HStack(spacing: 0) {
                pagerChevron("chevron.left", enabled: pager.canGoBack, label: String(localized: "Previous"),
                             action: pager.onBack)
                Text(pager.title)
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                pagerChevron("chevron.right", enabled: pager.canGoForward, label: String(localized: "Next"),
                             action: pager.onForward)
            }
        } else if let title {
            Text(title)
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func pagerChevron(_ symbol: String, enabled: Bool, label: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: 32, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .none:
            EmptyView()
        case .info(let action):
            PulseInfoButton(action: action)
        case .achievement(let symbol, let tint, let count, let label, let action):
            Button(action: action) {
                PulseAchievementChip(symbol: symbol, tint: tint, count: count)
                    .frame(minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(label)
        case .symbol(let symbol, let label, let action):
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(label)
        case .custom(let label, let action, let draw):
            Button(action: action) {
                Canvas(renderer: draw)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(label)
        }
    }
}

/// Applies the Pulse navigation header to a screen: the system bar hidden, Pulse's bar in the top safe-area
/// inset (content scrolls under it), and the interactive swipe-back kept.
private struct PulseNavHeaderModifier: ViewModifier {
    let title: String?
    let titlePager: PulseNavTitlePager?
    let trailing: PulseNavTrailing
    let showsBack: Bool

    @Environment(\.pulseModalRoot) private var modalRoot
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationTitle(title ?? "")
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                PulseNavBar(title: title, titlePager: titlePager,
                            leading: modalRoot ? .close : (showsBack ? .back : .none),
                            trailing: trailing, onLeading: { dismiss() })
            }
            .background(PulseSwipeBackEnabler())
    }
}

extension View {
    /// The Pulse navigation header: centred UPPERCASE `title` (or a `titlePager`), "‹" (or "✕" at a modal
    /// root, nothing when `showsBack` is false), and one `trailing` accessory. Content scrolls under it.
    func pulseNavHeader(_ title: String?, titlePager: PulseNavTitlePager? = nil,
                        trailing: PulseNavTrailing = .none, showsBack: Bool = true) -> some View {
        modifier(PulseNavHeaderModifier(title: title, titlePager: titlePager, trailing: trailing,
                                        showsBack: showsBack))
    }
}

// MARK: - Swipe back without the system bar

/// Keeps the interactive pop gesture alive on a stack whose bar Pulse hides. UIKit's own delegate refuses
/// the swipe once the bar or its back button is hidden; this installs one that allows it whenever there is
/// something to pop (never at a root, where a stray swipe could wedge the stack).
struct PulseSwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) { controller.install() }

    final class Controller: UIViewController {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            install()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            install()
        }

        func install() {
            guard let nav = navigationController, let pop = nav.interactivePopGestureRecognizer else { return }
            if !(pop.delegate is PulsePopGestureDelegate) {
                let delegate = PulsePopGestureDelegate(navigationController: nav)
                objc_setAssociatedObject(nav, &PulsePopGestureDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                pop.delegate = delegate
            }
            pop.isEnabled = true
        }
    }
}

private final class PulsePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static var key: UInt8 = 0
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = navigationController else { return false }
        return nav.viewControllers.count > 1 && nav.transitionCoordinator == nil
    }
}

// MARK: - Top backdrop

/// Behind a pinned bar or row once content scrolls under it: the viewport-fixed page gradient, opaque from
/// the screen's top to the top safe-area edge (which, inside a scaffold, is the bar's bottom) plus `extra`,
/// then fading to clear over `fade`. Clear at rest, because the gradient is the page's own.
struct PulseTopBackdrop: View {
    var style: PulseBackground.Style = .gradient
    /// Extra opaque height below the safe-area edge (Home's sticky mini-ring row).
    var extra: CGFloat = 0
    var fade: CGFloat = PulseTheme.Header.barFade

    var body: some View {
        // The insets are read OUTSIDE the safe-area-ignoring content: a view that ignores the safe area
        // sees none.
        GeometryReader { geo in
            let solid = max(0, geo.safeAreaInsets.top + extra)
            PulseBackground(style: style)
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
