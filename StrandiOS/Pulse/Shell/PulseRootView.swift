#if os(iOS)
import SwiftUI
import Combine
import StrandDesign
import StrandAnalytics

// MARK: - Shell presentations

/// What the shell's ONE sheet slot can hold, so two sheets never race.
enum PulseShellSheet: Identifiable {
    /// The ＋ menu.
    case actionMenu
    /// A route presented as a sheet (its own stack; "✕" at a Pulse root, "Done" on a classic screen).
    case route(PulseRoute)
    /// The Coach sheet, or Coach setup while no provider is configured.
    case coach(seed: String?)

    var id: String {
        switch self {
        case .actionMenu: return "action-menu"
        case .route(let route): return "route-\(String(describing: route))"
        case .coach: return "coach"
        }
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
    @State private var sheet: PulseShellSheet?
    /// The one full-screen slot (Start Activity, Journal, Device Settings, the guided session…).
    @State private var cover: PulseModal?
    /// Mirrors `AICoachEngine.isConfigured`, maintained by `PulseCoachProbe`.
    @State private var coachConfigured = false
    /// The bottom safe-area inset, measured, so the floating chrome sits right on every device.
    @State private var bottomSafeArea: CGFloat = 34
    #if DEBUG
    /// DEBUG `--pulse-gallery`.
    @State private var showGallery = false
    #endif

    private var coachAvailability: PulseCoachAvailability {
        guard coachEnabled else { return .off }
        return coachConfigured ? .ready : .needsSetup
    }

    private var coachContext: PulseCoachContext {
        PulseCoachContext(availability: coachAvailability, open: { seed in openCoach(seed: seed) })
    }

    /// How screens open routes: pushes go onto the selected tab's path, modal routes into the shell's
    /// sheet or cover slot.
    private var navigator: PulseNavigator {
        PulseNavigator(open: { open($0) }, push: { push($0) }, present: { present($0) },
                       quickAction: { perform($0) })
    }

    /// The capsule's bottom edge above the screen's bottom edge.
    private var barBottomFromScreenBottom: CGFloat {
        PulseTheme.TabBarMetrics.bottomOffset(safeAreaBottom: bottomSafeArea)
    }

    /// The capsule's top edge above the screen's bottom edge.
    private var barTopFromScreenBottom: CGFloat {
        barBottomFromScreenBottom + PulseTheme.TabBarMetrics.height
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
        .overlay {
            if selectedTabAtRoot {
                // A flexible column, so ignoring the bottom safe area really reaches the screen's edge
                // (a fixed-height view only rests on the safe-area edge).
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    PulseBottomChrome(tabs: PulseTab.allCases, selection: selectedTab, coach: coachAvailability,
                                      onSelect: select, onCoach: { openCoach(seed: nil) })
                        .padding(.bottom, barBottomFromScreenBottom)
                }
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
        #if DEBUG
        .background(
            Color.clear.fullScreenCover(isPresented: $showGallery) { PulseComponentGallery() })
        #endif
        .environment(\.pulseChrome, chromeMetrics)
        .environment(\.pulseCoach, coachContext)
        .environment(\.pulseNavigator, navigator)
        .tint(PulseTheme.chromeTint)
        .environment(model)
        .background(PulseAttacher(model: model))
        .background(PulseCoachProbe(configured: $coachConfigured))
        // A closed sheet may have changed what Home shows without a refresh (a journal entry, a logged
        // workout), so Home rebuilds on the way back.
        .sheet(item: $sheet, onDismiss: { model.homeMayHaveChanged() }) { sheetContent($0) }
        .fullScreenCover(item: $cover, onDismiss: { model.homeMayHaveChanged() }) { modal in
            PulseModalHost(route: modal.route)
                .environment(\.pulseNavigator, navigator)
        }
        .onChange(of: router.requestedDestination) { _, dest in handle(dest) }
        .onChange(of: router.quickActionsRequested) { _, requested in
            guard requested else { return }
            presentSheet(.actionMenu)
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
            PulseHomeView()
        case .health:
            PulseHealthTabView()
        case .trends:
            PulseTrendsTabView()
        case .more:
            PulseMoreView()
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

    // MARK: Opening routes

    private func open(_ route: PulseRoute) {
        switch route {
        case .coach(let seed):
            openCoach(seed: seed)
        default:
            if route.presentation == .push { push(route) } else { present(route) }
        }
    }

    private func push(_ route: PulseRoute) {
        path(selectedTab).wrappedValue.append(route)
    }

    /// Present `route` in its own stack: full-screen routes in the cover slot, everything else as a sheet.
    private func present(_ route: PulseRoute) {
        switch route {
        case .coach(let seed):
            openCoach(seed: seed)
        default:
            if route.presentation == .fullScreen {
                cover = PulseModal(route: route)
            } else {
                presentSheet(.route(route))
            }
        }
    }

    /// A ＋ action: the menu itself, or the screen it opens (presented, as the classic shell does).
    private func perform(_ action: PulseQuickAction) {
        if let route = action.route {
            present(route)
        } else {
            presentSheet(.actionMenu)
        }
    }

    private func presentSheet(_ new: PulseShellSheet) {
        withAnimation(PulseMotion.sheet) { sheet = new }
    }

    /// The Coach button and every coach entry point: the Coach sheet when a provider is configured, Coach
    /// setup when it is not, nothing when Coach is switched off.
    private func openCoach(seed: String?) {
        guard coachAvailability != .off else { return }
        presentSheet(.coach(seed: seed))
    }

    @ViewBuilder
    private func sheetContent(_ s: PulseShellSheet) -> some View {
        switch s {
        case .actionMenu:
            PulseActionSheet(
                onPick: { picked in
                    // Swap the menu for the chosen screen on the next runloop so the sheet re-presents
                    // cleanly rather than racing its own dismissal (the classic shell's idiom).
                    sheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { perform(picked) }
                },
                onGuidedSession: {
                    sheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { present(.guidedSession) }
                },
                onClose: { sheet = nil })
        case .route(let route):
            PulseModalHost(route: route)
                .environment(\.pulseNavigator, navigator)
        case .coach(let seed):
            PulseCoachSheet(seed: seed)
        }
    }

    // MARK: Router

    /// Every NavRouter request. Each opens what it opened before (a classic sheet) until the screen that
    /// replaces it is rebuilt, then the rebuilt route (`forExistingEntryPoint`).
    private func handle(_ dest: NavRouter.Destination?) {
        guard let dest else { return }
        defer { router.requestedDestination = nil }
        switch dest {
        case .devices:
            present(PulseRoute.deviceSettings.forExistingEntryPoint)
        case .insightsHub:
            present(.classic(.insightsHub))
        case .labBook:
            present(.classic(.labBook))
        case .fusedRecord:
            present(.classic(.fusedRecord))
        case .rhythm:
            present(.classic(.rhythm))
        case .alarms:
            present(PulseRoute.sleepPlanner.forExistingEntryPoint)
        case .coach:
            // On with a provider: the Coach sheet. On without one: Coach setup. Off: drop the request,
            // the honest answer for a feature the wearer turned off.
            openCoach(seed: nil)
        case .trends:
            // The Trends tab; until it is rebuilt, with the full Trends screen pushed (where a "new data"
            // reading deep-links).
            selectedTab = .trends
            trendsPath = NavigationPath()
            if !PulseTrendsTabView.isRebuilt { trendsPath.append(PulseRoute.classic(.trends)) }
        case .activeWorkout:
            // LiveView consumes the router's one-shot flag and opens the running workout.
            present(.classic(.live))
        case .liveSession:
            present(.guidedSession)
        case .journal:
            // The classic journal reads `router.pendingJournalDayOffset` itself; the rebuilt one gets it here.
            present(PulseRoute.journal(dayOffset: router.pendingJournalDayOffset).forExistingEntryPoint)
        }
    }

    /// DEBUG `--pulse-tab` / `--pulse-route` / `--pulse-push` / `--pulse-sheet` (see `PulseDebugLaunch`).
    /// No-op in Release.
    private func applyDebugLaunchState() {
        #if DEBUG
        if let route = PulseDebugLaunch.route {
            selectedTab = PulseDebugLaunch.tab ?? route.debugTab
            open(route)
        } else if let tab = PulseDebugLaunch.tab {
            selectedTab = tab
        }
        if let route = PulseDebugLaunch.push { homePath.append(route) }
        if PulseDebugLaunch.showsGallery { showGallery = true }
        switch PulseDebugLaunch.sheet {
        case "actions": sheet = .actionMenu
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
        perform(destination)
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
