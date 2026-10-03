#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The Health tab root ("HEALTH", WHOOP_UI_SPEC §3.20): the ZENO Age orb (whole at rest, a half sphere
/// under the title once scrolled) or the unlock card, the calibrating note, PACE OF AGING, the Lab Book,
/// the Health Monitor, Rhythm and the cycle card when switched on, the Stress Monitor, ZENO's extras
/// (illness heads-up, steps) and the disclaimer. Always "now", whatever day Home shows.
///
/// Not built on `PulseScreenScaffold`: the page is near-black with a glow in the orb's hue, and the part
/// behind the pinned title has to be that same glowing page (the scaffold's backdrop is the plain one), so
/// the tab carries the scaffold's root duties itself: the tab-bar scrim and inset, pull to refresh,
/// scroll to top on a tab re-tap and the DEBUG `--pulse-scroll` anchors.
struct PulseHealthTabView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    @Environment(\.pulseChrome) private var chrome
    @EnvironmentObject private var profile: ProfileStore

    @State private var snapshot: HealthTabSnapshot?
    /// The typical weekday's HIGH minutes, for the day it was built for (the chip checks the day).
    @State private var typicalHigh: HealthTypicalHigh?
    @State private var restTop: CGFloat?
    @State private var scrolledUnder = false

    private var hue: HealthAgeHue {
        guard let snapshot else { return .steady }
        switch snapshot.age {
        case .unlocking: return .unlocking
        case .ready(let summary): return summary.week.hue
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("pulse.top")
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: HealthScrollTopKey.self,
                                                   value: geo.frame(in: .named(PulseScrollSpace.name)).minY)
                        })
                    PulseLoadingGate(isLoading: snapshot == nil) {
                        if let snapshot {
                            PulseHealthTabContent(snapshot: snapshot, typicalHigh: typicalHigh)
                        }
                    } skeleton: {
                        VStack(spacing: PulseTheme.Layout.healthStackGap) {
                            Circle()
                                .strokeBorder(PulseTheme.skeleton, lineWidth: 10)
                                .frame(width: 200, height: 200)
                                .frame(maxWidth: .infinity)
                            PulseSkeleton.cards([200, 240, 180])
                        }
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.top, 12)
                    Color.clear
                        .frame(height: max(PulseTheme.Layout.floatingChromeInset, chrome.tabRootBottomInset))
                        .id("pulse.bottom")
                }
            }
            .coordinateSpace(name: PulseScrollSpace.name)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .refreshable { await model.pullToRefresh() }
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("pulse.top", anchor: .top) }
            }
            .onPreferenceChange(HealthScrollTopKey.self) { top in
                guard let top else { return }
                if restTop == nil { restTop = top }
                let under = top < (restTop ?? top) - 1
                if under != scrolledUnder { scrolledUnder = under }
            }
            .pulseDebugScroll(proxy, ready: snapshot != nil)
        }
        .background(HealthPageBackground(hue: hue))
        .overlay(alignment: .top) {
            HealthTopBackdrop(hue: hue)
                .opacity(scrolledUnder ? 1 : 0)
                .animation(PulseMotion.chrome, value: scrolledUnder)
        }
        .pulseTabBarScrim()
        .navigationTitle(String(localized: "Health"))
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            PulseNavBar(title: String(localized: "Health"), leading: .none, onLeading: {})
        }
        .environment(\.colorScheme, .dark)
        .task(id: model.healthKey) { await load() }
        .task(id: "\(model.healthKey)|typical|\(snapshot?.seq ?? -1)") { await loadTypical() }
    }

    private func load() async {
        let dob = profile.dateOfBirth
        if let s = await model.build(dayOffset: 0, { builder, request in
            await builder.healthTab(request, dateOfBirth: dob)
        }) {
            // A new day drops the previous day's typical figure before its own arrives.
            if let held = typicalHigh, held.dayKey != s.stress?.dayKey { typicalHigh = nil }
            if snapshot != s { snapshot = s }
        }
    }

    /// The typical weekday reads six earlier days of heart rate, so it lands after the page has drawn. Every
    /// result is kept, "no typical day" included; only a superseded build (nil) leaves the value alone.
    private func loadTypical() async {
        guard let snapshot, snapshot.stress != nil else { return }
        if let value = await model.build(dayOffset: 0, { builder, request in
            await builder.healthTypicalHigh(request)
        }) {
            if typicalHigh != value { typicalHigh = value }
        }
    }
}

private struct HealthScrollTopKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

/// The tab's cards, top to bottom, 24 pt apart (§2.3: the 2026 Health tab's rhythm).
///
/// It reads nothing from `AppModel`, which publishes the live heart rate about once a second: the two
/// facts it needs from there (the cycle phase, the illness watch) are read by the small slots that show
/// them, so a streaming strap re-renders those slots and not the orb, the ruler and the Lab ring.
private struct PulseHealthTabContent: View {
    let snapshot: HealthTabSnapshot
    let typicalHigh: HealthTypicalHigh?

    @AppStorage(AppModel.cycleAwarenessKey) private var cycleEnabled = false
    @AppStorage(AppModel.cycleAwarenessHiddenKey) private var cycleHidden = false
    @AppStorage(RhythmConsent.enabledKey) private var rhythmEnabled = false
    @AppStorage("pulse.health.calibratingDismissed") private var calibratingDismissedWeek = ""

    /// DEBUG `--pulse-health-calibrating`: show the calibrating note on a settled history, for captures.
    private static var forcesCalibratingNote: Bool {
        #if DEBUG
        return CommandLine.arguments.contains("--pulse-health-calibrating")
        #else
        return false
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.healthStackGap) {
            switch snapshot.age {
            case .unlocking(let nights, let needed):
                HealthUnlockHero(nights: nights, needed: needed)
            case .ready(let summary):
                let showsNote = (summary.settling || Self.forcesCalibratingNote)
                    && calibratingDismissedWeek != summary.week.id
                // The Pace card's open top tucks under the orb; the calibrating note has a fill, so it keeps
                // its distance.
                HealthAgeHero(summary: summary, tucksNextCard: !showsNote)
                if showsNote {
                    HealthCalibratingNote { calibratingDismissedWeek = summary.week.id }
                }
                HealthPaceCard(summary: summary)
                    .id("pulse.pace")
            }
            HealthLabBookCard(labs: snapshot.labs)
                .id("pulse.labs")
            HealthMonitorCard(vitals: snapshot.vitals)
                .id("pulse.monitor")
            if rhythmEnabled {
                HealthRhythmCard()
            }
            if cycleEnabled && !cycleHidden {
                HealthCycleSlot()
                    .id("pulse.cycle")
            }
            HealthStressCardView(card: snapshot.stress, typicalHigh: typicalHigh)
                .id("pulse.stress")
            HealthExtras(stepsToday: snapshot.stepsToday, stepsRoute: snapshot.stepsRoute)
                .padding(.top, PulseTheme.Space.s)
                .id("pulse.extras")
            HealthDisclaimer(text: String(localized: "ZENO is not a medical device. Health Monitor, Stress Monitor and Healthspan are wellness estimates from your own data; they cannot diagnose or manage any medical condition. Talk to a doctor about anything that worries you."))
                .padding(.top, PulseTheme.Space.xs)
        }
    }
}
#endif
