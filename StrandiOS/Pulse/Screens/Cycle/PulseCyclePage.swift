#if os(iOS)
import SwiftUI

// MARK: - The cycle page's frame (WHOOP_UI_SPEC §3.24 item 1, §2.1 "Menstrual header")
//
// `PulseScreenScaffold` with one difference the shared scaffold has no slot for: the viewport-fixed page
// gradient is TINTED BY THE CURRENT PHASE at the top (warm brown in the menstrual phase, purple in the luteal
// phase; appstore/ios69-09, help-center/10, 12, health-more-2026/07), fading into the slate page by ≈45% of
// the screen. Everything else is the scaffold's: Pulse's bar with ⚙, 16 pt margins, the page backdrop
// behind the bar once content scrolls under it, the floating Coach button with the 80 pt bottom inset,
// scroll-to-top and the DEBUG `--pulse-scroll` anchors.

struct PulseCyclePage<Content: View>: View {
    let title: String
    /// The phase the header is tinted by (nil: the plain slate page).
    let tint: PulseCyclePhase?
    var trailing: PulseNavTrailing = .none
    var coachSeed: String?
    var ready = true
    @ViewBuilder let content: () -> Content

    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    @Environment(\.pulseCoach) private var coach
    @State private var restTop: CGFloat?
    @State private var scrolledUnder = false

    private var bottomInset: CGFloat {
        coach.availability == .off ? PulseTheme.Layout.plainBottomInset : PulseTheme.Layout.floatingChromeInset
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("pulse.top")
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: PulseCycleScrollTopKey.self,
                                                   value: geo.frame(in: .named(PulseScrollSpace.name)).minY)
                        })
                    VStack(alignment: .leading, spacing: 0) {
                        content()
                        Color.clear.frame(height: bottomInset).id("pulse.bottom")
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                }
            }
            .coordinateSpace(name: PulseScrollSpace.name)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("pulse.top", anchor: .top) }
            }
            .onPreferenceChange(PulseCycleScrollTopKey.self) { top in
                guard let top else { return }
                if restTop == nil { restTop = top }
                let under = top < (restTop ?? top) - 1
                if under != scrolledUnder { scrolledUnder = under }
            }
            .pulseDebugScroll(proxy, ready: ready)
        }
        .background(PulseCycleBackground(tint: tint))
        .overlay(alignment: .top) {
            PulseCycleTopBackdrop(tint: tint)
                .opacity(scrolledUnder ? 1 : 0)
                .animation(PulseMotion.chrome, value: scrolledUnder)
        }
        .overlay { PulseFloatingCoach(accessory: .button, seed: coachSeed) }
        .pulseNavHeader(title, trailing: trailing)
        .environment(\.colorScheme, .dark)
    }
}

private struct PulseCycleScrollTopKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

/// The page gradient with the phase tint over its top: the sampled menstrual and luteal header tokens, and
/// the follicular and ovulatory calendar bands at the same weight, each fading out by 45% of the screen.
struct PulseCycleBackground: View {
    let tint: PulseCyclePhase?

    var body: some View {
        ZStack {
            PulseBackground()
            if let tint {
                LinearGradient(stops: Self.stops(tint), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
        }
        .accessibilityHidden(true)
    }

    static func stops(_ phase: PulseCyclePhase) -> [Gradient.Stop] {
        switch phase {
        case .menstrual:
            let c = PulseTheme.Menstrual.headerMenstrual
            return [.init(color: c[0], location: 0), .init(color: c[1], location: 0.14),
                    .init(color: c[2].opacity(0.85), location: 0.3), .init(color: c[2].opacity(0), location: 0.45)]
        case .luteal:
            let c = PulseTheme.Menstrual.headerLuteal
            return [.init(color: c[0], location: 0), .init(color: c[1].opacity(0.9), location: 0.28),
                    .init(color: c[1].opacity(0), location: 0.45)]
        case .follicular, .ovulatory:
            return [.init(color: phase.band.opacity(0.62), location: 0),
                    .init(color: phase.band.opacity(0.3), location: 0.25),
                    .init(color: phase.band.opacity(0), location: 0.45)]
        }
    }
}

/// Behind the bar once content scrolls under it: the tinted page, opaque to the bar's bottom, then a
/// 24 pt fade (the scaffold's `PulseTopBackdrop`, on this page's background).
private struct PulseCycleTopBackdrop: View {
    let tint: PulseCyclePhase?

    var body: some View {
        GeometryReader { geo in
            PulseCycleBackground(tint: tint)
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        Rectangle().frame(height: max(0, geo.safeAreaInsets.top))
                        LinearGradient(colors: [Color.black, Color.black.opacity(0)], startPoint: .top,
                                       endPoint: .bottom)
                            .frame(height: PulseTheme.Header.barFade)
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
