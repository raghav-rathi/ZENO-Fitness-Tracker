#if os(iOS)
import SwiftUI
import Combine
import StrandDesign
import StrandAnalytics

// MARK: - Routes

/// Pulse's own first-hop pushes. Values, not closure links, so a tab re-tap can pop them off the tab's
/// bound path (the #135/#198 convention the classic shell keeps).
enum PulseRoute: Hashable {
    case score(PulseScore)
    case workout(PulseWorkoutRoute)
    /// The wake alarm and wind-down planner.
    case alarms
    case labBook
}

/// The ＋ actions and the screens they open.
enum PulseQuickAction: String, Identifiable {
    case menu, live, workout, liftLog, intervals, breathe, journal
    var id: String { rawValue }
}

/// Every sheet the shell presents, through ONE `.sheet(item:)` so two can never race.
enum PulseSheet: Identifiable {
    case quick(PulseQuickAction)
    case devices
    case settings
    case pillar(NavRouter.Destination)
    /// The Coach sheet, or Coach setup while no provider is configured.
    case coach(seed: String?)

    var id: String {
        switch self {
        case .quick(let a): return "quick-\(a.rawValue)"
        case .devices: return "devices"
        case .settings: return "settings"
        case .pillar(let d): return "pillar-\(d.rawValue)"
        case .coach: return "coach"
        }
    }
}

extension View {
    /// Register every value push a Pulse stack can carry: Pulse's own routes, the classic screens More
    /// links to, and the shared `TabRoute` metric details. Once per stack, never twice (a second
    /// registration double-pushes, #38).
    func pulseDestinations() -> some View {
        self
            .tabRouteDestinations()
            .navigationDestination(for: PulseRoute.self) { route in
                switch route {
                case .score(.recovery): PulseRecoveryView()
                case .score(.strain): PulseStrainView()
                case .score(.sleep): PulseSleepView()
                case .workout(let w): PulseClassicScreen { WorkoutDetailView(row: w.row) }
                case .alarms: PulseClassicScreen { SmartAlarmView() }
                case .labBook: PulseClassicScreen { LabBookView() }
                }
            }
            .navigationDestination(for: PulseMoreDestination.self) { route in
                PulseClassicScreen { route.destination }
            }
    }
}

/// A classic screen pushed inside Pulse: its own canvas behind it, an inline transparent bar.
struct PulseClassicScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(StrandPalette.surfaceBase.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Root

/// The Pulse shell: Home · Health · Trends · More in a floating capsule, the Coach button beside it, one
/// NavigationStack per tab.
///
/// A native `TabView` with its system bar hidden keeps each tab's lifecycle (a tab that is not showing
/// gets onDisappear, so a screen that streams while visible stops), and the capsule is drawn over it.
/// The capsule and the Coach button show on a tab's root and leave when something is pushed; a pushed
/// screen floats its own Coach button through `PulseScreenScaffold(coach:)`.
///
/// Everything the classic `RootTabView` gives the rest of the app is kept: pop-to-root then scroll-to-top
/// on a tab re-tap, every `NavRouter` request, the Home Screen quick actions (held until the launch gates
/// clear), the gym-session bar and sheet, the launch refresh and the backup catch-up. It observes only the
/// router, the quick-action delegate, the scene phase and the Coach switch; the repository, the live strap
/// state, the Coach engine and the gym session are each observed by a small leaf so their frequent
/// publishes never re-render the shell.
struct PulseRootView: View {
    /// External entry points wait until the mandatory first-run gates have completed (see RootTabView).
    let homeScreenQuickActionsEnabled: Bool

    @EnvironmentObject private var router: NavRouter
    @EnvironmentObject private var homeScreenQuickActions: HomeScreenQuickActionSceneDelegate
    @AppStorage("noop.coachEnabled") private var coachEnabled = true
    @Environment(\.scenePhase) private var scenePhase

    @State private var model = PulseModel()
    @State private var selectedTab: PulseTab = .home
    @State private var homePath = NavigationPath()
    @State private var healthPath = NavigationPath()
    @State private var trendsPath = NavigationPath()
    @State private var morePath = NavigationPath()
    @State private var scrollTop: [PulseTab: Int] = [:]
    @State private var sheet: PulseSheet?
    @State private var showLiveSession = false
    /// Mirrors `AICoachEngine.isConfigured`, maintained by `PulseCoachProbe`.
    @State private var coachConfigured = false
    /// The bottom safe-area inset, measured, so the floating chrome sits right on every device.
    @State private var bottomSafeArea: CGFloat = 34

    private var coachAvailability: PulseCoachAvailability {
        guard coachEnabled else { return .off }
        return coachConfigured ? .ready : .needsSetup
    }

    private var coachContext: PulseCoachContext {
        PulseCoachContext(availability: coachAvailability, open: { seed in openCoach(seed: seed) })
    }

    /// The capsule's top edge above the screen's bottom edge.
    private var barTopFromScreenBottom: CGFloat {
        PulseTheme.TabBarMetrics.bottomOffset + PulseTheme.TabBarMetrics.height
    }

    private var chromeMetrics: PulseChromeMetrics {
        PulseChromeMetrics(
            tabRootBottomInset: max(0, barTopFromScreenBottom + PulseTheme.Layout.scrimHeight - bottomSafeArea),
            barTopFromScreenBottom: barTopFromScreenBottom)
    }

    /// True while the selected tab shows its root, which is when the capsule and Coach button show.
    private var selectedTabAtRoot: Bool {
        switch selectedTab {
        case .home: return homePath.isEmpty
        case .health: return healthPath.isEmpty
        case .trends: return trendsPath.isEmpty
        case .more: return morePath.isEmpty
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(PulseTab.allCases) { tab in
                NavigationStack(path: path(tab)) {
                    root(tab)
                        .pulseDestinations()
                }
                // Only THIS tab's token changes on its re-tap, so the other tabs keep their positions.
                .environment(\.scrollToTopSignal, scrollTop[tab, default: 0])
                .toolbar(.hidden, for: .tabBar)
                .tag(tab)
            }
        }
        .modifier(PulseLiftSessionChrome(
            bottomPadding: selectedTabAtRoot ? max(8, barTopFromScreenBottom - bottomSafeArea + 8) : 8))
        .overlay(alignment: .bottom) {
            if selectedTabAtRoot {
                PulseBottomChrome(tabs: PulseTab.allCases, selection: selectedTab, coach: coachAvailability,
                                  onSelect: select, onCoach: { openCoach(seed: nil) })
                    .padding(.bottom, PulseTheme.TabBarMetrics.bottomOffset)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(PulseMotion.chrome, value: selectedTabAtRoot)
        .animation(PulseMotion.chrome, value: coachAvailability)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: PulseBottomSafeAreaKey.self, value: geo.safeAreaInsets.bottom)
            })
        .onPreferenceChange(PulseBottomSafeAreaKey.self) { inset in
            if bottomSafeArea != inset { bottomSafeArea = inset }
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
        .environment(\.pulseChrome, chromeMetrics)
        .environment(\.pulseCoach, coachContext)
        .tint(PulseTheme.chromeTint)
        .environment(model)
        .background(PulseAttacher(model: model))
        .background(PulseCoachProbe(configured: $coachConfigured))
        // A closed sheet may have changed what Home shows without a refresh (a journal entry, a logged
        // workout), so Home rebuilds on the way back.
        .sheet(item: $sheet, onDismiss: { model.homeMayHaveChanged() }) { sheetContent($0) }
        .fullScreenCover(isPresented: $showLiveSession) {
            LiveSessionView(onClose: { showLiveSession = false })
        }
        .onChange(of: router.requestedDestination) { _, dest in handle(dest) }
        .onChange(of: router.quickActionsRequested) { _, requested in
            guard requested else { return }
            presentSheet(.quick(.menu))
            router.quickActionsRequested = false
        }
        // A cold-launch Home Screen action is already pending when the shell appears; a warm one arrives
        // through the change callback. Both open the same screens as the ＋ menu.
        .onAppear {
            presentPendingHomeScreenQuickActionIfPossible()
            applyDebugLaunchState()
        }
        .onChange(of: homeScreenQuickActions.pendingAction) { _, _ in
            presentPendingHomeScreenQuickActionIfPossible()
        }
        .onChange(of: homeScreenQuickActionsEnabled) { _, _ in
            presentPendingHomeScreenQuickActionIfPossible()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.sceneBecameActive() }
        }
    }

    // MARK: Tabs

    private func path(_ tab: PulseTab) -> Binding<NavigationPath> {
        switch tab {
        case .home: return $homePath
        case .health: return $healthPath
        case .trends: return $trendsPath
        case .more: return $morePath
        }
    }

    @ViewBuilder
    private func root(_ tab: PulseTab) -> some View {
        switch tab {
        case .home:
            PulseHomeView(onAction: present, onSettings: { presentSheet(.settings) })
        case .health:
            PulseHealthView(onAction: present)
        case .trends:
            PulseTrendsTabView()
        case .more:
            PulseMoreView(showsCoachSetup: coachAvailability == .needsSetup)
        }
    }

    /// A tap on a tab: switch to it, or, on the tab already showing, refresh and then pop to its root or
    /// scroll a root already there back to the top.
    private func select(_ tab: PulseTab) {
        if tab == selectedTab {
            reselect(tab)
        } else {
            selectedTab = tab
        }
    }

    private func reselect(_ tab: PulseTab) {
        Task { await model.refresh() }
        if path(tab).wrappedValue.isEmpty {
            scrollTop[tab, default: 0] += 1
        } else {
            path(tab).wrappedValue = NavigationPath()
        }
    }

    // MARK: Sheets

    private func present(_ action: PulseQuickAction) {
        presentSheet(.quick(action))
    }

    private func presentSheet(_ new: PulseSheet) {
        withAnimation(PulseMotion.sheet) { sheet = new }
    }

    /// The Coach button and every coach entry point: the Coach sheet when a provider is configured, Coach
    /// setup when it is not, nothing when Coach is switched off.
    private func openCoach(seed: String?) {
        guard coachAvailability != .off else { return }
        presentSheet(.coach(seed: seed))
    }

    @ViewBuilder
    private func sheetContent(_ s: PulseSheet) -> some View {
        switch s {
        case .quick(.menu):
            PulseActionSheet(
                onPick: { picked in
                    // Swap the menu for the chosen screen on the next runloop so the sheet re-presents
                    // cleanly rather than racing its own dismissal (the classic shell's idiom).
                    sheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        presentSheet(.quick(picked))
                    }
                },
                onGuidedSession: {
                    sheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { showLiveSession = true }
                },
                onClose: { sheet = nil })
        case .quick(.live): sheetScreen { LiveView() }
        case .quick(.workout): sheetScreen { WorkoutsView() }
        case .quick(.liftLog): sheetScreen { LiftLogView() }
        case .quick(.intervals): sheetScreen { IntervalTimerView() }
        case .quick(.breathe): sheetScreen { BreathingView() }
        case .quick(.journal): sheetScreen { InsightsView() }
        case .devices: sheetScreen { DevicesView() }
        case .settings: sheetScreen { SettingsView() }
        case .pillar(let dest):
            sheetScreen(registersTabRoutes: true) { pillarScreen(dest) }
        case .coach(let seed):
            PulseCoachSheet(seed: seed)
        }
    }

    /// A presented classic screen in its own stack with a Done button, the chrome the classic shell gives
    /// the same screens. The pillar hosts also register `TabRoute` (their fallbacks push those values).
    private func sheetScreen<V: View>(registersTabRoutes: Bool = false,
                                      @ViewBuilder _ view: () -> V) -> some View {
        NavigationStack {
            Group {
                if registersTabRoutes {
                    view().tabRouteDestinations()
                } else {
                    view()
                }
            }
            .background(StrandPalette.surfaceBase.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            // #1027: these screens draw a full-bleed sky under a transparent bar; an opaque bar clips it.
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) { sheet = nil }
                        .foregroundStyle(PulseTheme.accent)
                }
            }
        }
    }

    @ViewBuilder
    private func pillarScreen(_ dest: NavRouter.Destination) -> some View {
        switch dest {
        case .insightsHub: InsightsHubView()
        case .labBook: LabBookView()
        case .fusedRecord: FusedRecordHost()
        case .rhythm: RhythmHost(onClose: { sheet = nil })
        case .devices: DevicesView()
        case .trends: TrendsView()
        // These are routed elsewhere by `handle(_:)`; the cases keep the switch exhaustive.
        case .activeWorkout: LiveView()
        case .liveSession: LiveView()
        case .journal: InsightsView()
        case .coach: CoachView()
        case .alarms: SmartAlarmView()
        }
    }

    // MARK: Router

    private func handle(_ dest: NavRouter.Destination?) {
        guard let dest else { return }
        defer { router.requestedDestination = nil }
        switch dest {
        case .devices:
            presentSheet(.devices)
        case .insightsHub, .labBook, .fusedRecord, .rhythm, .alarms:
            presentSheet(.pillar(dest))
        case .coach:
            // On with a provider: the Coach sheet. On without one: Coach setup. Off: drop the request,
            // the honest answer for a feature the wearer turned off.
            openCoach(seed: nil)
        case .trends:
            // The Trends tab, with the full Trends screen pushed (where a "new data" reading deep-links).
            selectedTab = .trends
            trendsPath = NavigationPath()
            trendsPath.append(PulseMoreDestination.trends)
        case .activeWorkout:
            // LiveView consumes the router's one-shot flag and opens the running workout.
            presentSheet(.quick(.live))
        case .liveSession:
            showLiveSession = true
        case .journal:
            presentSheet(.quick(.journal))
        }
    }

    /// DEBUG `--pulse-tab` / `--pulse-push` / `--pulse-sheet` (see `PulseDebugLaunch`). No-op in Release.
    private func applyDebugLaunchState() {
        #if DEBUG
        if let tab = PulseDebugLaunch.tab { selectedTab = tab }
        if let route = PulseDebugLaunch.push { homePath.append(route) }
        switch PulseDebugLaunch.sheet {
        case "actions": sheet = .quick(.menu)
        case "coach": openCoach(seed: nil)
        default: break
        }
        #endif
    }

    // MARK: Home Screen quick actions

    private func presentPendingHomeScreenQuickActionIfPossible() {
        guard homeScreenQuickActionsEnabled, let action = homeScreenQuickActions.pendingAction else { return }
        let destination: PulseQuickAction = switch action {
        case .liveHeartRate: .live
        case .startWorkout: .workout
        case .logJournal: .journal
        case .breathe: .breathe
        }
        homeScreenQuickActions.consume(action)
        presentSheet(.quick(destination))
    }
}

private struct PulseBottomSafeAreaKey: PreferenceKey {
    static var defaultValue: CGFloat = 34
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Leaves that own the noisy observations

/// Wires the model to the repository and keeps its display preferences current, and runs the launch
/// work. It observes the repository and the preferences so the shell above it does not.
struct PulseAttacher: View {
    let model: PulseModel

    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var ble: BLEManager

    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.temperatureKey) private var temperatureRaw = ""
    @AppStorage(UnitPrefs.skinTempDisplayKey) private var skinTempDisplayRaw = ""
    @AppStorage(DayCycleMode.storageKey) private var dayCycleModeRaw = DayCycleMode.sleepOnset.rawValue
    @AppStorage(PuffinExperiment.banisterEffortKey) private var banisterEffort = false
    @AppStorage(PuffinExperiment.stressPersonalBaselineKey) private var stressPersonalBaseline = false
    @AppStorage(PuffinExperiment.journalReminderKey) private var journalReminder = true
    // The wind-down reminder's own keys (WindDownNudge). The two wake keys are never read here: they
    // are declared so that editing a wake time invalidates this view and Tonight is rebuilt.
    @AppStorage("windDown.enabled") private var windDownEnabled = false
    @AppStorage("windDown.wakeMinutes") private var windDownWake = 7 * 60
    @AppStorage("windDown.perDayWakeMinutes") private var windDownPerDay = Data()

    private var prefs: PulsePrefs {
        let system = UnitSystem(rawValue: unitSystemRaw) ?? .metric
        var p = PulsePrefs()
        p.fahrenheit = UnitPrefs.resolveTemperature(system: system, override: temperatureRaw) == .fahrenheit
        p.skinTempPreferred = SkinTempDisplay.Kind(rawValue: skinTempDisplayRaw) ?? .absolute
        p.sleepOnsetDayCycle = DayCycleMode.persisted(dayCycleModeRaw) == .sleepOnset
        p.effortMethod = banisterEffort ? .banister : .edwards
        p.stressPersonalBaseline = stressPersonalBaseline
        p.journalReminder = journalReminder
        if windDownEnabled {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            p.alarmWakeMinute = WindDownNudge.wakeMinutes(
                forWeekday: Calendar.current.component(.weekday, from: tomorrow))
        }
        return p
    }

    var body: some View {
        Color.clear
            .onAppear {
                model.attach(repo: repo, profile: profile, ble: ble)
                model.updatePrefs(prefs)
            }
            .onChange(of: prefs) { _, new in model.updatePrefs(new) }
            .task {
                await repo.refresh()
                // Backup & Sync's launch catch-up (see RootView): detached at utility priority so a large
                // whole-database archive never blocks startup; gated inside on the auto toggle.
                let backupRepo = repo
                Task.detached(priority: .utility) {
                    await FolderBackup.catchUpIfDue(checkpoint: { await backupRepo.checkpointForBackup() })
                }
                #if DEBUG
                if await PulseDemo.seedHeartRateIfRequested(repo: repo) { model.sceneBecameActive() }
                #endif
            }
            .accessibilityHidden(true)
    }
}

/// Tracks whether the AI Coach has a provider configured. `AICoachEngine` publishes on every streamed
/// token, and `isConfigured` reads the Keychain, so this answers on a debounce rather than per publish.
private struct PulseCoachProbe: View {
    @Binding var configured: Bool
    @EnvironmentObject private var coach: AICoachEngine

    var body: some View {
        Color.clear
            .onAppear { configured = coach.isConfigured }
            .onReceive(coach.objectWillChange.debounce(for: .milliseconds(400), scheduler: RunLoop.main)) { _ in
                let now = coach.isConfigured
                if now != configured { configured = now }
            }
            .accessibilityHidden(true)
    }
}

/// The running gym session, reachable from any tab: its bar above the floating tab bar and its sheet. A
/// modifier so the session's frequent publishes re-render this chrome, not the tabs inside it.
private struct PulseLiftSessionChrome: ViewModifier {
    /// Room under the bar: the capsule's height above the bottom safe edge while it shows.
    let bottomPadding: CGFloat
    @EnvironmentObject private var liftSession: LiftSessionController

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if liftSession.isActive {
                    LiftSessionBar()
                        .padding(.horizontal, 14)
                        .padding(.bottom, bottomPadding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: liftSession.isActive)
            // A session left running by a previous launch comes back as the BAR, not a sheet in the face.
            .sheet(isPresented: $liftSession.isPresented) {
                LiftSessionView { }
            }
    }
}
#endif
