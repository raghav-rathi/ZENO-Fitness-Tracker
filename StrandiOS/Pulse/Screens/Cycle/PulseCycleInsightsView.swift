#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Menstrual Cycle Insights (WHOOP_UI_SPEC §3.24), pushed from the Health tab card, the Home card and
/// App Settings › Hormonal Insights.
///
/// Top to bottom (appstore/ios69-09, help-center/10, 12, 85, health-more-2026/07, 11): the phase-tinted
/// header with "Cycle Day 3 | Menstrual Phase" and the next-period window; the month calendar with its phase
/// bands and legend; POSSIBLE SYMPTOMS TODAY; the Cycle Journal; <PHASE> PHASE COACHING; Your Current Cycle;
/// Your Cycle Patterns; YOUR SYMPTOMS; the disclaimer. WHOOP's "Learn More" articles are omitted [Z].
///
/// Everything is offline: `MenstrualCycleModel` over the period starts, flow and symptoms logged on this
/// iPhone (`PulseCycleLog`), the wearer's own nights for the metric patterns, and the skin-temperature
/// `CyclePhaseEngine` only where there are no usable logs. Never contraception, never a fertility window.
struct PulseCycleInsightsView: View {
    /// Rebuilt: entry points open this screen.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @AppStorage(AppModel.cycleAwarenessKey) private var enabled = false
    @AppStorage(PulseCycleLog.Mode.storageKey) private var modeRaw = PulseCycleLog.Mode.menstruating.rawValue
    @AppStorage(PulseCycleLog.Contraception.storageKey) private var contraceptionRaw = PulseCycleLog.Contraception.none.rawValue

    @State private var snapshot: CycleInsightsSnapshot?
    @State private var monthIndex = 0
    @State private var monthIndexSet = false
    @State private var logTarget: PulseCycleLogTarget?
    /// Mirrors `Repository.cycleTrackingSeq` and `AppModel.cyclePhase` (`PulseCycleProbe`).
    @State private var logSeq = 0
    @State private var engine: CyclePhaseEngine.Result?
    @State private var engineRefresh = 0

    private var mode: PulseCycleLog.Mode { PulseCycleLog.Mode(rawValue: modeRaw) ?? .menstruating }
    private var contraception: PulseCycleLog.Contraception {
        PulseCycleLog.Contraception(rawValue: contraceptionRaw) ?? .none
    }

    private struct LoadKey: Equatable {
        let health: String
        let logSeq: Int
        let mode: String
        let contraception: String
        let engine: CyclePhaseEngine.Result?
    }

    private var loadKey: LoadKey {
        LoadKey(health: model.healthKey, logSeq: logSeq, mode: modeRaw, contraception: contraceptionRaw,
                engine: engine)
    }

    var body: some View {
        PulseCyclePage(title: String(localized: "Menstrual Cycle Insights"),
                       tint: enabled ? snapshot?.tintPhase : nil,
                       trailing: .symbol("gearshape", accessibilityLabel: String(localized: "Hormonal Insights settings")) {
                           navigator.push(PulseCycleSettingsRoute().route)
                       },
                       coachSeed: enabled ? snapshot?.header.accessibility : nil,
                       ready: snapshot != nil) {
            if enabled {
                PulseLoadingGate(isLoading: snapshot == nil) {
                    if let snapshot { content(snapshot) }
                } skeleton: {
                    VStack(alignment: .leading, spacing: 16) {
                        PulseSkeletonBlock(height: 52, width: 260, radius: PulseTheme.Radius.well)
                            .padding(.top, 18)
                        PulseSkeleton.cards([340, 120, 128])
                    }
                }
            } else {
                PulseCycleSetupView(hasLogs: snapshot?.hasLogs ?? false, onStart: start)
            }
        }
        .background(PulseCycleProbe(logSeq: $logSeq, engine: $engine, refreshRequest: engineRefresh))
        .task(id: loadKey) { await load() }
        .sheet(item: $logTarget, onDismiss: { engineRefresh += 1 }) { target in
            PulseCycleLogSheet(initial: target, earliestDay: snapshot?.earliestLogDay ?? target.day,
                               today: snapshot?.today ?? target.day)
        }
        #if DEBUG
        .task(id: snapshot != nil) { openDebugLogIfAsked() }
        #endif
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ s: CycleInsightsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(s.header)
                .padding(.top, 30)

            PulseCycleCalendar(months: s.months, monthIndex: $monthIndex) { day in
                logTarget = PulseCycleLogTarget(day: day)
            }
            .padding(.top, 16)
            .id("pulse.calendar")

            PulseCycleLegend(showsPhases: s.showsPhaseLegend, showsPrediction: s.showsPredictionLegend)
                .padding(.top, 4)

            predictionNote(s.header)
                .padding(.top, 16)

            if s.symptomsToday != .unavailable {
                PulseCycleSymptomsTodayCard(state: s.symptomsToday) {
                    logTarget = PulseCycleLogTarget(day: s.today, focus: .pain)
                }
                .padding(.top, 24)
                .id("pulse.symptoms")
            }

            PulseSectionHeader(String(localized: "Cycle Journal"),
                               accessory: .caption(PulseFormat.dayLabel(s.today, template: "EEEMMMd")))
                .padding(.top, PulseTheme.Layout.sectionGap)
                .id("pulse.journal")
            PulseCycleJournalCard(journal: s.journal,
                                  onLogPeriod: { logTarget = PulseCycleLogTarget(day: s.today) },
                                  onLogSymptoms: { logTarget = PulseCycleLogTarget(day: s.today, focus: .pain) })
                .padding(.top, PulseTheme.Layout.headerGap)

            if let coaching = s.coaching {
                PulseCycleCoachingCard(coaching: coaching)
                    .padding(.top, PulseTheme.Layout.stackGap)
                    .id("pulse.coaching")
            }

            if let cycle = s.currentCycle {
                PulseSectionHeader(String(localized: "Your Current Cycle"))
                    .padding(.top, PulseTheme.Layout.sectionGap)
                    .id("pulse.current")
                PulseCycleCurrentChart(cycle: cycle)
                    .padding(.top, PulseTheme.Layout.headerGap)
            }

            if let patterns = s.patterns {
                PulseSectionHeader(String(localized: "Your Cycle Patterns"))
                    .padding(.top, PulseTheme.Layout.sectionGap)
                    .id("pulse.patterns")
                PulseCyclePatternsSection(patterns: patterns)
                    .padding(.top, PulseTheme.Layout.headerGap)
            }

            PulseCycleSymptomSummaryCard(rows: s.symptomSummary) {
                logTarget = PulseCycleLogTarget(day: s.today, focus: .pain)
            }
            .padding(.top, s.patterns == nil ? PulseTheme.Layout.sectionGap : PulseTheme.Layout.stackGap)
            .id("pulse.yoursymptoms")

            PulseCycleDisclaimerCard()
                .padding(.top, PulseTheme.Layout.healthStackGap)
                .id("pulse.disclaimer")
        }
        .onAppear {
            guard !monthIndexSet else { return }
            monthIndexSet = true
            monthIndex = s.initialMonth
        }
    }

    /// "Cycle Day 3 | Menstrual Phase" (the phase in its colour) over the next-period line.
    private func header(_ h: CycleInsightsSnapshot.Header) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 10) { titleParts(h) }
                VStack(alignment: .leading, spacing: 2) { titleParts(h, separator: false) }
            }
            if !h.subtitle.isEmpty {
                Text(h.subtitle)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(h.accessibility)
        .accessibilityAddTraits(.isHeader)
    }

    /// Under the legend: where the prediction comes from, and any caveat (a log the temperature disagrees
    /// with, hormonal contraception). WHOOP prints neither; ZENO says what its estimate rests on.
    @ViewBuilder
    private func predictionNote(_ h: CycleInsightsSnapshot.Header) -> some View {
        if h.basis != nil || h.caveat != nil {
            VStack(alignment: .leading, spacing: 6) {
                if let basis = h.basis {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .semibold))
                        Text(basis)
                            .pulseText(.legend)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(PulseTheme.textTertiary)
                }
                if let caveat = h.caveat {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 12, weight: .semibold))
                        Text(caveat)
                            .pulseText(.legend)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(PulseTheme.negative)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func titleParts(_ h: CycleInsightsSnapshot.Header, separator: Bool = true) -> some View {
        if let day = h.cycleDay {
            Text(day)
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
        }
        if h.cycleDay != nil, h.title != nil, separator {
            Rectangle()
                .fill(PulseTheme.textPrimary.opacity(0.3))
                .frame(width: 1, height: 20)
                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 3 }
        }
        if let title = h.title {
            Text(title)
                .pulseText(.cardHeadline)
                .foregroundStyle(h.phase?.dot ?? PulseTheme.textPrimary)
                .lineLimit(1)
        }
    }

    // MARK: Data

    private func load() async {
        #if DEBUG
        if PulseCycleDemo.requested {
            let today = Repository.localDayKey(Date())
            _ = await model.build(dayOffset: 0) { builder, _ -> Bool? in
                await PulseCycleDemo.seedIfRequested(repo: builder.repo, today: today)
            }
        }
        #endif
        let inputs = PulseCycleInputs(today: Repository.localDayKey(Date()), logs: PulseCycleLog.Logs(),
                                      engine: engine, mode: mode, contraception: contraception)
        if let s = await model.build(dayOffset: 0, { builder, request in
            let logs = await builder.repo.cycleLogs()
            let full = PulseCycleInputs(today: inputs.today, logs: logs, engine: inputs.engine, mode: inputs.mode,
                                        contraception: inputs.contraception)
            return builder.cycleInsights(request, inputs: full)
        }) {
            snapshot = s
        }
    }

    /// Setup: switch the insights on and, when the wearer knows it, log the last period start.
    private func start(_ lastPeriod: Date?) {
        enabled = true
        let day = lastPeriod.map { Repository.localDayKey($0) }
        Task {
            if let day {
                // Through the builder, like every store access on this page (the page never holds the store).
                _ = await model.build(dayOffset: 0) { builder, _ -> Bool? in
                    await builder.repo.logPeriodStart(day: day)
                    return true
                }
            }
            engineRefresh += 1
        }
    }

    #if DEBUG
    /// `--cycle-log`: open the log sheet once the page has loaded; `--cycle-settings`: push the settings.
    /// For captures only.
    private func openDebugLogIfAsked() {
        guard let s = snapshot, logTarget == nil else { return }
        let args = CommandLine.arguments
        if args.contains("--cycle-log") {
            logTarget = PulseCycleLogTarget(day: s.today, focus: args.contains("--cycle-log-symptoms") ? .pain : .flow)
        } else if args.contains("--cycle-settings") {
            navigator.push(PulseCycleSettingsRoute().route)
        }
    }
    #endif
}

/// Observes the two noisy objects the page needs one value each from, so the page itself observes neither:
/// `Repository.cycleTrackingSeq` (a log changed) and `AppModel.cyclePhase` (the temperature engine ran), and
/// re-runs the engine when `refreshRequest` changes.
private struct PulseCycleProbe: View {
    @Binding var logSeq: Int
    @Binding var engine: CyclePhaseEngine.Result?
    let refreshRequest: Int

    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Color.clear
            .onAppear {
                logSeq = repo.cycleTrackingSeq
                engine = appModel.cyclePhase
                if appModel.cycleAwarenessEnabled, appModel.cyclePhase == nil {
                    Task { await appModel.refreshV5Signals() }
                }
            }
            .onReceive(repo.$cycleTrackingSeq) { seq in
                if seq != logSeq { logSeq = seq }
            }
            .onReceive(appModel.$cyclePhase) { result in
                if result != engine { engine = result }
            }
            .onChange(of: refreshRequest) { _, _ in
                Task { await appModel.refreshV5Signals() }
            }
            .accessibilityHidden(true)
    }
}
#endif
