#if os(iOS)
import SwiftUI
import Combine
import StrandDesign
import StrandAnalytics

// MARK: - Routes

/// Pulse's tabs. Coach exists only while the AI Coach is switched on AND a provider is configured.
enum PulseTab: Hashable {
    case home, health, coach, more
}

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

    var id: String {
        switch self {
        case .quick(let a): return "quick-\(a.rawValue)"
        case .devices: return "devices"
        case .settings: return "settings"
        case .pillar(let d): return "pillar-\(d.rawValue)"
        }
    }
}

extension View {
    /// Register every value push a Pulse tab stack can carry: Pulse's own routes and the shared
    /// `TabRoute` metric details. Once per stack, never twice (a second registration double-pushes, #38).
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

/// The Pulse shell: Home · Health · Coach · More, one NavigationStack per tab.
///
/// Mirrors what `RootTabView` provides the rest of the app: pop-to-root and scroll-to-top on a tab
/// re-tap, every `NavRouter` request, the Home Screen quick actions (held until the launch gates clear),
/// the gym-session bar and sheet, the launch refresh and the backup catch-up. It observes only the router,
/// the quick-action delegate and two settings; the repository, the live strap state, the Coach engine and
/// the gym session are each observed by a small leaf so their frequent publishes never re-render the
/// TabView.
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
    @State private var coachPath = NavigationPath()
    @State private var morePath = NavigationPath()
    @State private var scrollTop: [PulseTab: Int] = [:]
    @State private var sheet: PulseSheet?
    @State private var showLiveSession = false
    /// Mirrors `AICoachEngine.isConfigured`, maintained by `PulseCoachProbe`.
    @State private var coachConfigured = false

    private var coachAvailable: Bool { coachEnabled && coachConfigured }

    /// Calm easing at the sheet-present duration the classic shell uses.
    private static let sheetEase = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.42)

    /// Taps on the already-selected tab arrive through the setter, which is what lets the native tab bar
    /// keep the pop-to-root / scroll-to-top convention with no custom hit-testing over it.
    private var tabSelection: Binding<PulseTab> {
        Binding(
            get: { selectedTab },
            set: { tag in
                if tag == selectedTab { reselect(tag) } else { selectedTab = tag }
            })
    }

    var body: some View {
        TabView(selection: tabSelection) {
            tab(.home, "Home", "house.fill", path: $homePath) {
                PulseHomeView(onAction: present, onSettings: { presentSheet(.settings) })
            }
            tab(.health, "Health", "heart.text.square.fill", path: $healthPath) {
                PulseHealthView(onAction: present)
            }
            if coachAvailable {
                tab(.coach, "Coach", "sparkles", path: $coachPath) {
                    CoachView()
                        .background(StrandPalette.surfaceBase.ignoresSafeArea())
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
            tab(.more, "More", "ellipsis", path: $morePath) {
                PulseMoreView(showsCoachSetup: coachEnabled && !coachConfigured)
            }
        }
        .tint(PulseTheme.accent)
        .environment(model)
        .background(PulseAttacher(model: model))
        .background(PulseCoachProbe(configured: $coachConfigured))
        .modifier(PulseLiftSessionChrome())
        .sheet(item: $sheet) { sheetContent($0) }
        .fullScreenCover(isPresented: $showLiveSession) {
            LiveSessionView(onClose: { showLiveSession = false })
        }
        // Switching Coach off (or losing its key) while standing on it would leave the selection on a
        // tag no tab claims, which renders as an empty tab. Send that wearer Home, only in that case.
        .onChange(of: coachAvailable) { _, available in
            if !available && selectedTab == .coach { selectedTab = .home }
        }
        .onChange(of: router.requestedDestination) { _, dest in handle(dest) }
        .onChange(of: router.quickActionsRequested) { _, requested in
            guard requested else { return }
            presentSheet(.quick(.menu))
            router.quickActionsRequested = false
        }
        // A cold-launch Home Screen action is already pending when the shell appears; a warm one arrives
        // through the change callback. Both open the same screens as the ＋ menu.
        .onAppear { presentPendingHomeScreenQuickActionIfPossible() }
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

    private func tab<Content: View>(_ tag: PulseTab, _ title: LocalizedStringKey, _ icon: String,
                                    path: Binding<NavigationPath>,
                                    @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: path) {
            content()
                .pulseDestinations()
        }
        // Only THIS tab's token changes on its re-tap, so the other tabs keep their scroll positions.
        .environment(\.scrollToTopSignal, scrollTop[tag, default: 0])
        .toolbarBackground(PulseTheme.backgroundBottom, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tabItem { Label(title, systemImage: icon) }
        .tag(tag)
    }

    /// A re-tap refreshes, then pops a pushed stack to its root, or scrolls a root already there to the top.
    private func reselect(_ tag: PulseTab) {
        Task { await model.refresh() }
        switch tag {
        case .home: popOrScroll(&homePath, tag)
        case .health: popOrScroll(&healthPath, tag)
        case .coach: popOrScroll(&coachPath, tag)
        case .more: popOrScroll(&morePath, tag)
        }
    }

    private func popOrScroll(_ path: inout NavigationPath, _ tag: PulseTab) {
        if !path.isEmpty {
            path = NavigationPath()
        } else {
            scrollTop[tag, default: 0] += 1
        }
    }

    // MARK: Sheets

    private func present(_ action: PulseQuickAction) {
        presentSheet(.quick(action))
    }

    private func presentSheet(_ new: PulseSheet) {
        withAnimation(Self.sheetEase) { sheet = new }
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
        }
    }

    /// A presented screen in its own stack with a Done button, the chrome the classic shell gives the
    /// same screens. The pillar hosts also register `TabRoute` (their fallbacks push those values).
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
        // These three are routed elsewhere by `handle(_:)`; the cases keep the switch exhaustive.
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
            if coachAvailable {
                selectedTab = .coach
            } else if coachEnabled {
                // Switched on but not set up yet: open Coach where it can be configured.
                presentSheet(.pillar(.coach))
            }
            // Switched off: drop the request, the honest answer for a feature the wearer turned off.
        case .trends:
            // Trends lives in More here, not in its own tab.
            selectedTab = .more
            morePath = NavigationPath()
            morePath.append(PulseMoreDestination.trends)
        case .activeWorkout:
            // LiveView consumes the router's one-shot flag and opens the running workout.
            presentSheet(.quick(.live))
        case .liveSession:
            showLiveSession = true
        case .journal:
            presentSheet(.quick(.journal))
        }
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

/// The running gym session, reachable from any tab: its bar above the tab bar and its sheet. A modifier
/// so the session's frequent publishes re-render this chrome, not the tabs inside it.
private struct PulseLiftSessionChrome: ViewModifier {
    @EnvironmentObject private var liftSession: LiftSessionController

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if liftSession.isActive {
                    LiftSessionBar()
                        .padding(.horizontal, 14)
                        // Clear the tab bar with the same constant every classic screen uses.
                        .padding(.bottom, NoopMetrics.tabBarClearance)
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
