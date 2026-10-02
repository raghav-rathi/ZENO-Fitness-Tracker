#if os(iOS)
import SwiftUI
import StrandDesign

/// Every screen More links to, as a `Hashable` value the tab's bound path can carry (so a re-tap pops).
enum PulseMoreDestination: Hashable {
    // Performance
    case trends, weeklyDigest
    // Insights
    case insightsHub, explore, compare, journal, coach
    // Activity
    case workouts, liftLog, live, breathe, intervals
    // Devices, alarms
    case devices, alarms
    // Data
    case dataSources, appleHealth, backupSync, shortcutsExport
    // Settings
    case settings
    // Advanced
    case testCentre, limitations, miBand, rhythm, intelligence, fusedRecord, powerSaving, siriShortcuts
    case automations, classicHealth, stress, labBook

    @ViewBuilder var destination: some View {
        switch self {
        case .trends: TrendsView()
        case .weeklyDigest: WeeklyDigestView()
        case .insightsHub: InsightsHubView()
        case .explore: MetricExplorerView()
        case .compare: CompareView()
        case .journal: InsightsView()
        case .coach: CoachView()
        case .workouts: WorkoutsView()
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

/// More: the rest of the app in standard grouped rows. Every screen the classic More list reached is
/// still here, plus Devices (which the classic list never had a row for).
struct PulseMoreView: View {
    /// Coach is switched on but has no provider yet, so it has no tab: offer the setup screen here.
    let showsCoachSetup: Bool

    @EnvironmentObject private var repo: Repository
    @AppStorage("pulse.enabled") private var pulseEnabled = true
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    @Environment(\.pulseChrome) private var chrome
    @State private var showReport = false
    @State private var confirmClassic = false
    private static let topID = "pulse.more.top"

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    row(String(localized: "Trends"), "chart.line.uptrend.xyaxis", .trends)
                        .id(Self.topID)
                    row(String(localized: "Weekly digest"), "calendar", .weeklyDigest)
                    Button { showReport = true } label: {
                        label(String(localized: "Report"), "doc.richtext", chevron: true)
                    }
                    .listRowBackground(PulseTheme.card)
                } header: { header(String(localized: "Performance")) }

                Section {
                    row(String(localized: "What moves you"), "wand.and.sparkles", .insightsHub)
                    row(String(localized: "Explore"), "square.grid.2x2.fill", .explore)
                    row(String(localized: "Compare"), "rectangle.split.2x1.fill", .compare)
                    row(String(localized: "Journal"), "square.and.pencil", .journal)
                    if showsCoachSetup {
                        row(String(localized: "Set up AI Coach"), "sparkles", .coach)
                    }
                } header: { header(String(localized: "Insights")) }

                Section {
                    row(String(localized: "Workouts"), "figure.run", .workouts)
                    row(String(localized: "Lift Log"), "dumbbell.fill", .liftLog)
                    row(String(localized: "Live"), "waveform.path.ecg", .live)
                    row(String(localized: "Breathe"), "wind", .breathe)
                    row(String(localized: "Intervals"), "timer", .intervals)
                } header: { header(String(localized: "Activity")) }

                Section {
                    row(String(localized: "Devices"), "sensor.tag.radiowaves.forward.fill", .devices)
                    row(String(localized: "Alarms"), "alarm.fill", .alarms)
                } header: { header(String(localized: "Strap & alarms")) }

                Section {
                    row(String(localized: "Data Sources"), "externaldrive.fill", .dataSources)
                    row(String(localized: "Apple Health"), "heart.fill", .appleHealth)
                    row(String(localized: "Backup & Sync"), "externaldrive.fill.badge.icloud", .backupSync)
                    row(String(localized: "Shortcuts Export"), "square.and.arrow.up.fill", .shortcutsExport)
                } header: { header(String(localized: "Data")) }

                Section {
                    row(String(localized: "Settings"), "gearshape.fill", .settings)
                } header: { header(String(localized: "Settings")) }

                Section {
                    row(String(localized: "Test Centre"), "stethoscope", .testCentre)
                        .id("pulse.advanced")
                    row(String(localized: "Limitations"), "list.bullet.rectangle", .limitations)
                    row(String(localized: "Mi Band"), "figure.walk.motion", .miBand)
                    row(String(localized: "Rhythm"), "waveform.path", .rhythm)
                    row(String(localized: "Intelligence"), "brain.head.profile", .intelligence)
                    row(String(localized: "Your Data, Fused"), "square.stack.3d.up.fill", .fusedRecord)
                    row(String(localized: "Automations"), "wand.and.stars", .automations)
                    row(String(localized: "Power saving"), "battery.25", .powerSaving)
                    row(String(localized: "Siri & Shortcuts"), "mic.fill", .siriShortcuts)
                    row(String(localized: "Classic Health"), "heart.text.square", .classicHealth)
                } header: { header(String(localized: "Advanced")) }

                Section {
                    Toggle(isOn: Binding(get: { !pulseEnabled }, set: { if $0 { confirmClassic = true } })) {
                        label(String(localized: "Classic interface"), "rectangle.stack", chevron: false)
                    }
                    .tint(PulseTheme.accent)
                    .listRowBackground(PulseTheme.card)
                    .id("pulse.bottom")
                } header: {
                    header(String(localized: "Interface"))
                } footer: {
                    Text(String(localized: "Switches to the classic tabs. Settings › WHOOP-style interface brings this one back."))
                        .font(.caption)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            // Clear the floating tab bar: the list scrolls under it and its scrim.
            .contentMargins(.bottom, chrome.tabRootBottomInset, for: .scrollContent)
            .navigationTitle(String(localized: "More"))
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(Self.topID, anchor: .top) }
            }
            .pulseDebugScroll(proxy, ready: true)
        }
        .refreshable { await repo.refresh() }
        .sheet(isPresented: $showReport) {
            TrendsReportSheet(days: repo.days)
        }
        .confirmationDialog(String(localized: "Switch to the classic interface?"),
                            isPresented: $confirmClassic, titleVisibility: .visible) {
            Button(String(localized: "Switch")) { pulseEnabled = false }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Your data and settings stay as they are. You can switch back from Settings."))
        }
        .background(PulseBackground())
        .pulseTabBarScrim()
        .toolbarBackground(PulseTheme.backgroundTop, for: .navigationBar)
        .environment(\.colorScheme, .dark)
    }

    private func header(_ text: String) -> some View {
        PulseLabel(text, color: PulseTheme.textSecondary)
    }

    private func row(_ title: String, _ symbol: String, _ destination: PulseMoreDestination) -> some View {
        NavigationLink(value: destination) {
            label(title, symbol, chevron: false)
        }
        .listRowBackground(PulseTheme.card)
    }

    private func label(_ title: String, _ symbol: String, chevron: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(PulseTheme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(title)
                .font(.body)
                .foregroundStyle(PulseTheme.textPrimary)
            if chevron {
                Spacer(minLength: 8)
                // The List's own disclosure colour, so this button row matches its NavigationLink
                // neighbours rather than standing out brighter.
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .accessibilityHidden(true)
            }
        }
        // A list row is already at least 44 pt tall; padding it further made each row read oversized.
        .padding(.vertical, 2)
    }
}
#endif
