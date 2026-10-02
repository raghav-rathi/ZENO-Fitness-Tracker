#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

// MARK: - Routes (WHOOP_UI_SPEC §1.6, §1.8)
//
// Every screen Pulse can open is ONE case of `PulseRoute`, and `destination` is the ONE place a route
// becomes a view. Each route names the type its group owns (Screens/<Area>/…); until a group rebuilds a
// screen, that type is a themed "being rebuilt" placeholder that links to the classic screen doing the
// job today, so nothing dead-ends and nothing is lost.
//
// Open a route with `PulseLink(route) { label }` or `@Environment(\.pulseNavigator)`'s `open(_:)`: a push
// route is appended to the current tab's path (so a tab re-tap pops it), a sheet or full-screen route is
// presented by the shell in its own stack, whose root shows "✕". `presentation` follows the spec's
// presentation catalogue.
//
// Existing entry points (NavRouter requests, Home Screen quick actions, the old Home rows) keep opening the
// classic screen they opened before until the owning group flips its screen's `isRebuilt` flag, then they
// open the rebuilt route: `PulseRoute.forExistingEntryPoint`. Groups never edit this file.

/// How a destination is presented (§1.6).
enum PulsePresentation: Equatable {
    /// Pushed onto the current tab's stack, "‹" back.
    case push
    /// A sheet with its own stack, "✕" (or "Done" for a classic screen).
    case sheet
    /// A full-screen modal with its own stack, "✕".
    case fullScreen
}

/// Every destination in Pulse.
enum PulseRoute: Hashable {
    // MARK: Score deep dives (groups "sleep" and "recovery-strain")
    case sleepDive
    case recoveryDive
    case strainDive

    // MARK: Home (group "home")
    case customizeDashboard
    /// Looking Ahead › CALIBRATION TIMELINE (new members).
    case calibrationTimeline

    // MARK: Sleep (group "sleep")
    case sleepPlanner

    // MARK: Trends (group "trends")
    /// The reusable Trend View for one metric (a `MetricCatalog` key).
    case trendView(metric: String)
    case weeklyDigest

    // MARK: Activity (group "activity")
    case activityDetail(PulseWorkoutRoute)
    case startActivity
    case addActivity
    case activityPicker

    // MARK: Health (group "health")
    case healthspan
    case healthMonitor
    case stressMonitor

    // MARK: More and Profile (group "more-profile")
    case appSettings
    case deviceSettings
    case profile
    case levels
    case achievements
    case dayStreak

    // MARK: Journal and Plan (group "journal-plan")
    /// The Journal for a day, `dayOffset` days back (nil = today).
    case journal(dayOffset: Int?)
    case behaviorInsights
    /// Plan Overview, or the Edit Plan modal.
    case weeklyPlan(editing: Bool)

    // MARK: Cycle and Coach (group "cycle-coach")
    case cycleInsights
    /// The Coach sheet, optionally seeded with the page's context. Opening it goes through the Coach's
    /// availability (setup when unconfigured, nothing when switched off).
    case coach(seed: String?)
    case memory

    // MARK: Onboarding and Strength (group "onboarding-strength")
    case onboarding
    case strengthTrainer

    // MARK: Extras (group "extras")
    case yearInReview
    case challenges
    /// The expanded day heart-rate timeline (⤢ on TODAY'S ACTIVITIES).
    case dayTimeline

    // MARK: Existing screens
    /// The silent-guardian Live Session (beta), full screen.
    case guidedSession
    /// A classic screen, in its classic look.
    case classic(PulseClassicDestination)
    /// A shared metric-detail route (the classic shell's first-hop values).
    case tab(TabRoute)

    /// The deep dive behind a score's dial.
    static func dive(_ score: PulseScore) -> PulseRoute {
        switch score {
        case .sleep: return .sleepDive
        case .recovery: return .recoveryDive
        case .strain: return .strainDive
        }
    }

    /// How WHOOP presents it (§1.6).
    var presentation: PulsePresentation {
        switch self {
        case .customizeDashboard, .startActivity, .deviceSettings, .journal, .onboarding, .strengthTrainer,
             .yearInReview, .dayTimeline, .guidedSession:
            return .fullScreen
        case .sleepPlanner, .addActivity, .appSettings, .coach:
            return .sheet
        case .weeklyPlan(let editing):
            return editing ? .sheet : .push
        default:
            return .push
        }
    }

    /// True for the screens that keep their classic look.
    var isClassic: Bool {
        switch self {
        case .classic, .tab, .guidedSession: return true
        default: return false
        }
    }

    // MARK: The one mapping

    /// The view a route shows. Pushed and presented routes both come through here.
    @ViewBuilder
    var destination: some View {
        switch self {
        case .sleepDive: PulseSleepDiveView()
        case .recoveryDive: PulseRecoveryDiveView()
        case .strainDive: PulseStrainDiveView()
        case .customizeDashboard: PulseCustomizeDashboardView()
        case .calibrationTimeline: PulseCalibrationTimelineView()
        case .sleepPlanner: PulseSleepPlannerView()
        case .trendView(let metric): PulseTrendView(metric: metric)
        case .weeklyDigest: PulseWeeklyDigestView()
        case .activityDetail(let workout): PulseActivityDetailView(workout: workout)
        case .startActivity: PulseStartActivityView()
        case .addActivity: PulseAddActivityView()
        case .activityPicker: PulseActivityPickerView()
        case .healthspan: PulseHealthspanView()
        case .healthMonitor: PulseHealthMonitorView()
        case .stressMonitor: PulseStressMonitorView()
        case .appSettings: PulseAppSettingsView()
        case .deviceSettings: PulseDeviceSettingsView()
        case .profile: PulseProfileView()
        case .levels: PulseLevelsView()
        case .achievements: PulseAchievementsView()
        case .dayStreak: PulseStreakView()
        case .journal(let dayOffset): PulseJournalView(dayOffset: dayOffset)
        case .behaviorInsights: PulseBehaviorInsightsView()
        case .weeklyPlan(let editing): PulseWeeklyPlanView(editing: editing)
        case .cycleInsights: PulseCycleInsightsView()
        case .coach(let seed): PulseCoachSheet(seed: seed)
        case .memory: PulseMemoryView()
        case .onboarding: PulseOnboardingView()
        case .strengthTrainer: PulseStrengthTrainerView()
        case .yearInReview: PulseYearInReviewView()
        case .challenges: PulseChallengesView()
        case .dayTimeline: PulseDayTimelineView()
        case .guidedSession: PulseGuidedSessionHost()
        case .classic(let screen): PulseClassicScreen { screen.view }
        case .tab(let route): PulseClassicScreen { route.pulseView }
        }
    }

    // MARK: Existing entry points

    /// Whether the screen behind this route has been rebuilt. Each group flips the static `isRebuilt` on
    /// its own screen type; routes without a classic fallback are always "rebuilt".
    var isRebuilt: Bool {
        switch self {
        case .sleepPlanner: return PulseSleepPlannerView.isRebuilt
        case .trendView: return PulseTrendView.isRebuilt
        case .weeklyDigest: return PulseWeeklyDigestView.isRebuilt
        case .activityDetail: return PulseActivityDetailView.isRebuilt
        case .startActivity: return PulseStartActivityView.isRebuilt
        case .stressMonitor: return PulseStressMonitorView.isRebuilt
        case .appSettings: return PulseAppSettingsView.isRebuilt
        case .deviceSettings: return PulseDeviceSettingsView.isRebuilt
        case .profile: return PulseProfileView.isRebuilt
        case .journal: return PulseJournalView.isRebuilt
        case .behaviorInsights: return PulseBehaviorInsightsView.isRebuilt
        case .strengthTrainer: return PulseStrengthTrainerView.isRebuilt
        case .dayTimeline: return PulseDayTimelineView.isRebuilt
        default: return true
        }
    }

    /// The classic screen that covers this route's job today, if any. Placeholders link to it, and
    /// existing entry points open it until the route is rebuilt.
    var classicFallback: PulseRoute? {
        switch self {
        case .sleepPlanner: return .classic(.alarms)
        case .trendView(let metric): return .tab(.metric(metric))
        case .weeklyDigest: return .classic(.weeklyDigest)
        case .activityDetail(let workout): return .classic(.workoutDetail(workout))
        case .startActivity: return .classic(.workouts)
        case .addActivity: return .classic(.workouts)
        case .healthspan, .healthMonitor: return .classic(.classicHealth)
        case .stressMonitor: return .classic(.stress)
        case .appSettings: return .classic(.settings)
        case .deviceSettings: return .classic(.devices)
        case .profile: return .classic(.settings)
        case .journal: return .classic(.journal)
        case .behaviorInsights: return .classic(.insightsHub)
        case .strengthTrainer: return .classic(.liftLog)
        case .dayTimeline: return .tab(.fullDayChart)
        default: return nil
        }
    }

    /// What an EXISTING entry point opens: this route once its screen is rebuilt, otherwise the classic
    /// screen it has always opened, so the next wave can land screen by screen without regressions.
    var forExistingEntryPoint: PulseRoute {
        guard !isRebuilt, let fallback = classicFallback else { return self }
        return fallback
    }
}

// MARK: - Classic screens

/// Every classic screen Pulse links to. They keep their classic look (`PulseClassicScreen`).
enum PulseClassicDestination: Hashable {
    // Performance and insights
    case trends, weeklyDigest, report, insightsHub, explore, compare, journal, coach
    // Activity
    case workouts, workoutDetail(PulseWorkoutRoute), liftLog, live, breathe, intervals
    // Strap and alarms
    case devices, alarms
    // Data
    case dataSources, appleHealth, backupSync, shortcutsExport
    // Settings and support
    case settings, scoringGuide, whatsNew
    // Advanced
    case testCentre, limitations, miBand, rhythm, intelligence, fusedRecord, powerSaving, siriShortcuts
    case automations, classicHealth, stress, labBook

    @ViewBuilder var view: some View {
        switch self {
        case .trends: TrendsView()
        case .weeklyDigest: WeeklyDigestView()
        case .report: PulseTrendsReportHost()
        case .insightsHub: InsightsHubView()
        case .explore: MetricExplorerView()
        case .compare: CompareView()
        case .journal: InsightsView()
        case .coach: CoachView()
        case .workouts: WorkoutsView()
        case .workoutDetail(let workout): WorkoutDetailView(row: workout.row)
        case .liftLog: LiftLogView()
        case .live: LiveView()
        case .breathe: BreathingView()
        case .intervals: IntervalTimerView()
        case .devices: DevicesView()
        case .alarms: SmartAlarmView()
        case .dataSources: DataSourcesView()
        case .appleHealth: AppleHealthView()
        case .backupSync: BackupSyncView()
        case .shortcutsExport: ShortcutExportSettingsView()
        case .settings: SettingsView()
        case .scoringGuide: PulseDismissHost { dismiss in ScoringGuideView(onClose: dismiss) }
        case .whatsNew: PulseDismissHost { dismiss in WhatsNewView(onClose: dismiss) }
        case .testCentre: TestCentreView()
        case .limitations: NoopLimitationsView()
        case .miBand: XiaomiBandView()
        case .rhythm: RhythmHost()
        case .intelligence: IntelligenceView()
        case .fusedRecord: FusedRecordHost()
        case .powerSaving: PowerSavingView()
        case .siriShortcuts: SiriShortcutsSettingsView()
        case .automations: AutomationsView()
        case .classicHealth: HealthView()
        case .stress: StressView()
        case .labBook: LabBookView()
        }
    }
}

extension TabRoute {
    /// The view the classic shell maps this route to (`tabRouteDestinations()`), for `PulseRoute.tab`.
    @ViewBuilder var pulseView: some View {
        switch self {
        case .fullDayChart: FullDayChartView()
        case .metric(let key):
            if let m = MetricCatalog.all.first(where: { $0.key == key }) {
                MetricDetailView(metric: m)
            } else {
                HealthView()
            }
        case .metricSourced(let key, let source):
            if let m = MetricCatalog.metric(key: key, source: source) ?? MetricCatalog.all.first(where: { $0.key == key }) {
                MetricDetailView(metric: m)
            } else {
                HealthView()
            }
        case .metricExplorer: MetricExplorerView()
        case .workouts: WorkoutsView()
        case .dataSources: DataSourcesView()
        case .stress: StressView()
        case .sleep: SleepView()
        case .health: HealthView()
        case .hydration: HydrationView()
        case .coupled: CoupledView()
        case .steps(let day): StepsView(day: day)
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

/// Hands a classic screen that wants an `onClose` the environment's dismiss.
private struct PulseDismissHost<Content: View>: View {
    @ViewBuilder let content: (@escaping () -> Void) -> Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        content { dismiss() }
    }
}

/// The trends report, which needs the repository's day list.
private struct PulseTrendsReportHost: View {
    @EnvironmentObject private var repo: Repository

    var body: some View {
        TrendsReportSheet(days: repo.days)
    }
}

/// The guided Live Session, closed through the environment's dismiss.
private struct PulseGuidedSessionHost: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        LiveSessionView(onClose: { dismiss() })
            .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    /// Register every value push a Pulse stack can carry: every `PulseRoute`, and the shared `TabRoute`
    /// values classic screens push themselves. Once per stack, never twice (a second registration
    /// double-pushes, #38). A pushed destination is never a modal root.
    func pulseDestinations() -> some View {
        self
            .tabRouteDestinations()
            .navigationDestination(for: PulseRoute.self) { route in
                route.destination
                    .environment(\.pulseModalRoot, false)
            }
    }
}

// MARK: - DEBUG names (`--pulse-route <name>`)

#if DEBUG
extension PulseRoute {
    /// Every route by its `--pulse-route` name. Names are kebab-case; "trend-view:<metric>" picks a metric,
    /// "classic-<screen>" opens a classic screen, "tab-<route>" a shared metric route.
    static var debugCatalog: [(name: String, route: PulseRoute)] {
        var all: [(String, PulseRoute)] = [
            ("sleep-dive", .sleepDive), ("recovery-dive", .recoveryDive), ("strain-dive", .strainDive),
            ("customize-dashboard", .customizeDashboard), ("calibration-timeline", .calibrationTimeline),
            ("sleep-planner", .sleepPlanner), ("trend-view", .trendView(metric: "hrv")),
            ("weekly-digest", .weeklyDigest), ("activity-detail", .activityDetail(debugWorkout)),
            ("start-activity", .startActivity), ("add-activity", .addActivity),
            ("activity-picker", .activityPicker), ("healthspan", .healthspan),
            ("health-monitor", .healthMonitor), ("stress-monitor", .stressMonitor),
            ("app-settings", .appSettings), ("device-settings", .deviceSettings), ("profile", .profile),
            ("levels", .levels), ("achievements", .achievements), ("day-streak", .dayStreak),
            ("journal", .journal(dayOffset: nil)), ("behavior-insights", .behaviorInsights),
            ("weekly-plan", .weeklyPlan(editing: false)), ("edit-plan", .weeklyPlan(editing: true)),
            ("cycle-insights", .cycleInsights), ("coach", .coach(seed: nil)), ("memory", .memory),
            ("onboarding", .onboarding), ("strength-trainer", .strengthTrainer),
            ("year-in-review", .yearInReview), ("challenges", .challenges), ("day-timeline", .dayTimeline),
            ("guided-session", .guidedSession),
        ]
        let classic: [(String, PulseClassicDestination)] = [
            ("trends", .trends), ("weekly-digest", .weeklyDigest), ("report", .report),
            ("insights-hub", .insightsHub), ("explore", .explore), ("compare", .compare), ("journal", .journal),
            ("coach", .coach), ("workouts", .workouts), ("workout-detail", .workoutDetail(debugWorkout)),
            ("lift-log", .liftLog), ("live", .live), ("breathe", .breathe), ("intervals", .intervals),
            ("devices", .devices), ("alarms", .alarms), ("data-sources", .dataSources),
            ("apple-health", .appleHealth), ("backup-sync", .backupSync), ("shortcuts-export", .shortcutsExport),
            ("settings", .settings), ("scoring-guide", .scoringGuide), ("whats-new", .whatsNew),
            ("test-centre", .testCentre), ("limitations", .limitations), ("mi-band", .miBand),
            ("rhythm", .rhythm), ("intelligence", .intelligence), ("fused-record", .fusedRecord),
            ("power-saving", .powerSaving), ("siri-shortcuts", .siriShortcuts), ("automations", .automations),
            ("classic-health", .classicHealth), ("stress", .stress), ("lab-book", .labBook),
        ]
        all += classic.map { ("classic-\($0.0)", PulseRoute.classic($0.1)) }
        let tabs: [(String, TabRoute)] = [
            ("full-day-chart", .fullDayChart), ("metric-explorer", .metricExplorer), ("sleep", .sleep),
            ("stress", .stress), ("health", .health), ("hydration", .hydration), ("coupled", .coupled),
            ("steps", .steps(day: nil)),
        ]
        all += tabs.map { ("tab-\($0.0)", PulseRoute.tab($0.1)) }
        return all.map { (name: $0.0, route: $0.1) }
    }

    /// The route named `name` ("trend-view:rhr" picks the Trend View's metric; "tab-metric:<key>" a metric).
    static func debugNamed(_ name: String) -> PulseRoute? {
        if name.hasPrefix("trend-view:") { return .trendView(metric: String(name.dropFirst("trend-view:".count))) }
        if name.hasPrefix("tab-metric:") { return .tab(.metric(String(name.dropFirst("tab-metric:".count)))) }
        return debugCatalog.first { $0.name == name }?.route
    }

    /// The tab a launch-time route opens on, so it sits where a person would reach it.
    var debugTab: PulseTab {
        switch self {
        case .healthspan, .healthMonitor, .stressMonitor, .cycleInsights:
            return .health
        case .trendView, .weeklyDigest:
            return .trends
        case .appSettings, .deviceSettings, .profile, .levels, .achievements, .dayStreak, .memory, .classic,
             .challenges, .yearInReview:
            return .more
        default:
            return .home
        }
    }

    /// A stand-in workout for the routes that need one at launch (the placeholder does not read it).
    private static var debugWorkout: PulseWorkoutRoute {
        let end = Int(Date().timeIntervalSince1970) - 3_600
        return PulseWorkoutRoute(row: WorkoutRow(startTs: end - 2_700, endTs: end, sport: "running", source: "demo",
                                                 durationS: 2_700, energyKcal: 412, avgHr: 141, maxHr: 172,
                                                 strain: 11.4, distanceM: 7_400, zonesJSON: nil, notes: nil,
                                                 steps: nil))
    }
}
#endif
#endif
