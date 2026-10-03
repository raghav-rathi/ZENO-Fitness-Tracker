#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The Sleep deep dive (WHOOP_UI_SPEC §3.3), pushed from the Sleep dial, the sleep rows and the sticky
/// header's mini ring.
///
/// Top to bottom: "‹ TODAY ›" with the Restful Nights achievement chip (§1.5 [Z], `PulseDiveAchievement`;
/// the nights step in the bar's title, ARCHITECTURE §9); the 260 / 15 Sleep Performance ring with its Poor /
/// Sufficient / Optimal dashes; the notched callout with HOURS VS. NEEDED, SLEEP CONSISTENCY, SLEEP
/// EFFICIENCY and HIGH SLEEP STRESS, each on its own thresholds, and the legend well; "Last Night's Sleep"
/// with EDIT and "Today vs. prior 30 days"; HOURS OF SLEEP (heart rate, stages, restorative, latency); the
/// four detail cards; the seven Weekly Trends cards; ZENO's naps and sleeping heart rate; then HOW IT'S
/// CALCULATED. The coach summary pill floats at the bottom with a local sentence until the Coach writes one
/// (§1.2 [Z]).
///
/// It opens on Home's day: a day with no recorded night is that day's empty night (the ring "--%", the
/// rows "--", every card its dash, the trends still up), never an older night under the day's title. ‹ ›
/// rebuild EVERYTHING on the page from the nearest banked night either side, in one snapshot. The night's
/// stress is scored in a second build (it reads the night's raw heart rate and R-R and the waking hours
/// before it) and its 30-night baseline in a third, so SLEEP STRESS and its contributor fill in a moment
/// after the rest, never showing another night's figures meanwhile.
struct PulseSleepDiveView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var intelligence: IntelligenceEngine

    /// The night the wearer stepped to, by wake day; nil means Home's night.
    @State private var nightKey: String?
    @State private var snapshot: SleepDiveSnapshot?
    @State private var stress: SleepStressSnapshot?
    @State private var stressBaseline: SleepStressBaseline?
    @State private var selectedStage: SleepStage?
    /// The night open in the sleep-time editor (EDIT on Last Night's Sleep).
    @State private var editing: SleepTimeEdit?
    /// A night with nothing recorded, being added as a Sleep or nap, from the times it opens on
    /// (`SleepDiveSnapshot.addWindow`, kept from the tap that opened it).
    @State private var addingNight = false
    @State private var addWindow: ClosedRange<Date>?
    /// The night just deleted, undoable for a few seconds (#65).
    @State private var undo: PulseSleepUndo?
    @State private var undoDismiss: Task<Void, Never>?
    /// The badges, for the bar's achievement chip.
    @State private var profile: ProfileSnapshot?
    #if DEBUG
    @State private var debugApplied = false
    #endif

    // MARK: Title and pager

    /// Home's day, which the title mirrors for its own night.
    private var homeTitle: String {
        PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate)
    }

    /// TODAY for today's night wherever the wearer stepped from, Home's own title for Home's night, else
    /// the night's wake day (a DAY KEY, so formatted at UTC).
    private func title(_ s: SleepDiveSnapshot) -> String {
        if s.wakeDayKey == s.todayKey { return String(localized: "Today") }
        if s.wakeDayKey == s.requestDayKey { return homeTitle }
        return PulseFormat.navDayTitle(dayKey: s.wakeDayKey)
    }

    private var pager: PulseNavTitlePager? {
        guard let s = snapshot, s.olderKey != nil || s.newerKey != nil else { return nil }
        return PulseNavTitlePager(title: title(s), canGoBack: s.olderKey != nil, canGoForward: s.newerKey != nil,
                                  onBack: { if let key = s.olderKey { nightKey = key } },
                                  onForward: { if let key = s.newerKey { nightKey = key } })
    }

    /// The night's stress, only when it is this night's.
    private var currentStress: SleepStressSnapshot? {
        guard let stress, stress.nightKey == snapshot?.wakeDayKey else { return nil }
        return stress
    }

    /// Its 30-night baseline, only when it is this night's.
    private var currentBaseline: SleepStressBaseline? {
        guard let stressBaseline, stressBaseline.nightKey == snapshot?.wakeDayKey else { return nil }
        return stressBaseline
    }

    private var coachAccessory: PulseCoachAccessory {
        guard let summary = snapshot?.summary else { return .button }
        return .pill(summary: summary)
    }

    /// Ready for the DEBUG scroll once the page and (when there is a night) its stress have landed.
    private var isReady: Bool {
        guard let snapshot else { return false }
        return snapshot.stress == nil || currentStress != nil
    }

    // MARK: Body

    var body: some View {
        PulseScreenScaffold(title: snapshot.map(title) ?? homeTitle, titlePager: pager,
                            trailing: PulseDiveAchievement.sleep.trailing(profile, open: navigator.open),
                            coach: coachAccessory, coachSeed: snapshot?.summary, ready: isReady) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot {
                    content(snapshot)
                }
            } skeleton: {
                PulseSkeleton.dive
            }
        }
        .task(id: "\(model.detailKey)|\(nightKey ?? "-")") {
            await load()
        }
        // Keyed on the night's window, not on every refresh: a past night's heart rate does not change, and
        // re-reading a night and the day before it on each sync would be work for nothing.
        .task(id: snapshot?.stress) {
            await loadStress()
        }
        .profileSnapshot($profile)
        .sheet(item: $editing) { edit in
            SleepTimeEditor(edit: edit, onSave: { bed, wake in
                await SleepEditActions.save(edit, bedTs: bed, wakeTs: wake, repo: repo, intelligence: intelligence)
            }, onDelete: {
                if let snapshot = await SleepEditActions.delete(edit, repo: repo, intelligence: intelligence) {
                    offerUndo(snapshot, edit: edit)
                }
            })
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $addingNight) {
            PulseActivityFormSheet(mode: .add(preset: PulseActivityCatalog.sleepKinds.first, window: addWindow),
                                   onDone: { _ in })
        }
    }

    /// EDIT: the night's own editor, the classic Sleep screen's (its #940 guards, its delete confirm, an
    /// undo after a delete); a night with nothing recorded is added instead, as ADD ACTIVITY's Sleep or nap
    /// opened on that night's usual times.
    private func edit(_ s: SleepDiveSnapshot) {
        if let edit = s.edit {
            editing = edit
        } else {
            addWindow = s.addWindow
            addingNight = true
        }
    }

    /// Show UNDO for a delete for seven seconds, as the classic Sleep screen does; a later delete replaces it.
    private func offerUndo(_ snapshot: SleepDeletionSnapshot, edit: SleepTimeEdit) {
        undoDismiss?.cancel()
        let shown = PulseSleepUndo(snapshot: snapshot, bedTs: edit.bedTs, wakeTs: edit.wakeTs)
        undo = shown
        undoDismiss = Task {
            try? await Task.sleep(nanoseconds: 7_000_000_000)
            guard !Task.isCancelled, undo == shown else { return }
            undo = nil
        }
    }

    private func undoDelete(_ shown: PulseSleepUndo) {
        undoDismiss?.cancel()
        undo = nil
        Task { await SleepEditActions.undo(shown.snapshot, repo: repo, intelligence: intelligence) }
    }

    private func load() async {
        let key = nightKey
        guard let s = await model.build({ builder, request in await builder.sleepDive(request, onOrBefore: key) })
        else { return }
        if s.wakeDayKey != snapshot?.wakeDayKey { selectedStage = nil }
        snapshot = s
        #if DEBUG
        applyDebugLaunch(s)
        #endif
    }

    private func loadStress() async {
        guard let request = snapshot?.stress else {
            stress = nil
            stressBaseline = nil
            return
        }
        // A refresh landing mid-build supersedes it (nil); this task is keyed on the night, not the refresh,
        // so it tries again rather than leaving the card loading.
        var night: SleepStressSnapshot?
        for _ in 0..<3 where night == nil {
            night = await model.build({ builder, r in await builder.sleepStress(r, request: request) })
            if Task.isCancelled { return }
        }
        guard let night else { return }
        stress = night
        guard night.state == .scored, let high = night.highPercent else { return }
        // Then the prior nights it is compared with: each is scored once and kept, so a retry resumes.
        for _ in 0..<3 {
            if let baseline = await model.build({ builder, r in
                await builder.sleepStressBaseline(r, request: request, highPercent: high)
            }) {
                stressBaseline = baseline
                return
            }
            if Task.isCancelled { return }
        }
    }

    #if DEBUG
    /// `--pulse-night N` lands on banked night N once; `--sleep-stage awake|light|deep|rem` preselects a stage.
    private func applyDebugLaunch(_ s: SleepDiveSnapshot) {
        guard !debugApplied else { return }
        debugApplied = true
        if let n = PulseDebugLaunch.nightIndex, s.nightKeys.indices.contains(n), s.nightKeys[n] != s.wakeDayKey {
            nightKey = s.nightKeys[n]
            debugApplied = false
            return
        }
        if let raw = PulseSleepDebug.stage, let stage = SleepStage(rawValue: raw) { selectedStage = stage }
        if PulseSleepDebug.opensEditor { edit(s) }
    }
    #endif

    // MARK: Content

    @ViewBuilder
    private func content(_ s: SleepDiveSnapshot) -> some View {
        if let undo {
            PulseSleepUndoBanner(undo: undo) { undoDelete(undo) }
        }
        let scored = s.dial.value != nil
        let band = PulseSleepBand.index(percent: s.dial.value)
        // An unscored night has no level to light (deep-dives-2026/19f: no dashes under the ring).
        PulseHeroRing(content: s.dial.dialContent(label: String(localized: "Sleep performance")),
                      accessoryAccessibility: band.map(PulseSleepBand.name)) {
            if scored {
                PulseMiniSegments(active: band)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)

        PulseSleepContributorCallout(rows: contributors(s), showsLegend: scored, metricPages: s.metricPages)
            .padding(.top, 5)
            .id("pulse.contributors")

        lastNightHeader(s)
            .id("pulse.last-night")

        if let night = s.lastNight {
            PulseSleepLastNightCard(night: night, selected: $selectedStage) { explain(.hoursOfSleep) }
                .id("pulse.hr")
        } else {
            PulseSleepEmptyCard(title: String(localized: "Hours of sleep"), dash: SleepFigure.durationDash) {
                explain(.hoursOfSleep)
            }
        }

        // Empty cards print WHOOP's dashes: "-:--" for each, "--%" for consistency (deep-dives-2026/01, 19f).
        Group {
            if let card = s.hoursVsNeeded {
                PulseSleepHoursVsNeededCard(card: card) { explain(.hoursVsNeeded) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Hours vs. needed"), dash: SleepFigure.durationDash) {
                    explain(.hoursVsNeeded)
                }
            }
        }
        .id("pulse.hours-vs-needed")

        Group {
            if let card = s.consistency {
                PulseSleepConsistencyCard(card: card) { explain(.consistency) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Sleep consistency"), dash: SleepFigure.percentDash) {
                    explain(.consistency)
                }
            }
        }
        .id("pulse.consistency")

        Group {
            if let card = s.efficiency {
                PulseSleepEfficiencyCard(card: card) { explain(.efficiency) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Sleep efficiency"), dash: SleepFigure.durationDash) {
                    explain(.efficiency)
                }
            }
        }
        .id("pulse.efficiency")

        Group {
            if s.stress != nil {
                PulseSleepStressCard(stress: currentStress, baseline: currentBaseline) { explain(.stress) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Sleep stress"), dash: SleepFigure.durationDash) {
                    explain(.stress)
                }
            }
        }
        .id("pulse.sleep-stress")

        if !s.weekly.isEmpty {
            Text(String(localized: "Weekly Trends"))
                .pulseText(.weeklyTrendsTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 4)
                .padding(.top, PulseTheme.Layout.sectionGap - PulseTheme.Layout.stackGap)
                .id("pulse.weekly-trends")
            PulseSleepWeeklyTrends(week: s.weekly, metricPages: s.metricPages)
        }

        extras(s)

        // A card's gap under the last card (the page's own spacing), as on the Recovery and Strain dives.
        PulseDiveExplainerRow()
            .id("pulse.explainer")
    }

    /// The four contributors, the stress row filled from the night's stress once it lands.
    private func contributors(_ s: SleepDiveSnapshot) -> [SleepContributorRow] {
        s.contributors.map { row in
            guard row.kind == .stress else { return row }
            let pct = currentStress?.state == .scored ? currentStress?.highPercent : nil
            return SleepContributorRow(kind: .stress, title: row.title, percent: pct, calibrating: false,
                                       band: PulseSnapshotBuilder.sleepBand(.stress, pct), metric: row.metric)
        }
    }

    /// "Last Night's Sleep" with EDIT ✎ (always: a night with nothing recorded is one to add, `edit(_:)`) and
    /// "Today vs. prior 30 days" under it.
    private func lastNightHeader(_ s: SleepDiveSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            PulseSectionHeader(String(localized: "Last Night's Sleep"),
                               accessory: .edit { edit(s) })
            Group {
                if s.wakeDayKey == s.todayKey {
                    Text(String(localized: "Today")).fontWeight(.semibold).foregroundColor(PulseTheme.textPrimary)
                        + Text(" ") + Text(String(localized: "vs. prior 30 days")).foregroundColor(PulseTheme.textSecondary)
                } else {
                    Text(PulseFormat.dayLabel(s.wakeDayKey, template: "MMMd")).fontWeight(.semibold)
                        .foregroundColor(PulseTheme.textPrimary)
                        + Text(" ") + Text(String(localized: "vs. prior 30 days")).foregroundColor(PulseTheme.textSecondary)
                }
            }
            .pulseText(.secondary)
            .padding(.horizontal, 4)
        }
        // The title centres 44–46 pt under the legend well (deep-dives-2026/56, 56b): the callout's own
        // bottom padding and the page's gap already make that.
        .padding(.top, 2)
    }

    /// ZENO's extras after Weekly Trends (§3.3 item 9): naps, then sleeping heart rate and breathing.
    @ViewBuilder
    private func extras(_ s: SleepDiveSnapshot) -> some View {
        if !s.naps.isEmpty {
            VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
                PulseSectionHeader(String(localized: "Naps"))
                VStack(spacing: PulseTheme.Layout.gridGap) {
                    ForEach(s.naps) { nap in
                        PulseActivityRow(chip: PulseActivityChip(kind: .sleep, symbol: "powersleep",
                                                                 value: PulseFormat.hoursMinutes(nap.asleepMin)),
                                         name: String(localized: "Nap"),
                                         start: PulseFormat.clock(nap.start), end: PulseFormat.clock(nap.end),
                                         barColor: PulseTheme.textPrimary)
                    }
                }
                .padding(PulseTheme.Layout.gridGap)
                .pulseCardBackground()
            }
            .padding(.top, PulseTheme.Layout.sectionGap - PulseTheme.Layout.stackGap)
        }
        if s.sleepingHR != nil || s.lowestHR != nil || s.respRate != nil {
            // One card, three columns: an 11 pt caps label over a 17 pt value (§3.3 item 9).
            PulseCard {
                HStack(alignment: .top, spacing: PulseTheme.Layout.gridGap) {
                    extraStat(String(localized: "Sleeping HR"), value: s.sleepingHR.map { "\($0)" }, unit: "bpm")
                    extraStat(String(localized: "Lowest HR"), value: s.lowestHR.map { "\($0)" }, unit: "bpm")
                    extraStat(String(localized: "Breathing"), value: s.respRate.map { PulseFormat.oneDecimal($0) },
                              unit: "rpm")
                }
            }
            .padding(.top, s.naps.isEmpty ? PulseTheme.Layout.sectionGap - PulseTheme.Layout.stackGap : 0)
        }
    }

    /// One of the 3-up extras, from the catalogue (`PulseLabel`, `PulseValueText`).
    private func extraStat(_ title: String, value: String?, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PulseLabel(title)
            PulseValueText(value: value ?? "--", unit: value == nil ? nil : unit, style: .rowValue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func explain(_ topic: PulseSleepExplainerTopic) {
        navigator.open(PulseSleepExplainerRoute(topic: topic).route)
    }
}

// MARK: - Undo after a delete (#65)

/// A deleted night that can still be restored, and the window its banner names.
struct PulseSleepUndo: Equatable {
    let snapshot: SleepDeletionSnapshot
    let bedTs: Int
    let wakeTs: Int

    /// The classic banner's honesty rule (#65): only a DETECTED night is tombstoned, so only its message
    /// promises the window will not be detected again.
    var message: String {
        if snapshot.session.userEdited { return String(localized: "Sleep deleted.") }
        let bed = PulseFormat.clock(Date(timeIntervalSince1970: TimeInterval(bedTs)))
        let wake = PulseFormat.clock(Date(timeIntervalSince1970: TimeInterval(wakeTs)))
        return String(localized: "Sleep deleted. ZENO won't detect sleep between \(bed) and \(wake) again.")
    }
}

/// "Sleep deleted." over UNDO, in a card at the top of the dive while the delete can be taken back.
struct PulseSleepUndoBanner: View {
    let undo: PulseSleepUndo
    let onUndo: () -> Void

    var body: some View {
        PulseCard {
            HStack(spacing: PulseTheme.Layout.gridGap) {
                Text(undo.message)
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button(String(localized: "Undo"), action: onUndo)
                    .buttonStyle(.pulseNested)
                    .accessibilityLabel(String(localized: "Undo sleep deletion"))
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Where a figure opens

/// Where a Sleep dive figure opens. WHOOP opens Trend View for its metric; until the trends group's Trend
/// View is rebuilt, a metric whose classic detail page has data opens that page, one whose page would be
/// empty opens the classic Sleep screen (which shows it), and HIGH SLEEP STRESS always opens the Stress
/// Monitor: no nightly stress series is stored for a Trend View to draw.
enum PulseSleepRoutes {
    /// The metrics the contributors and the Weekly Trends cards open.
    static let metricKeys = ["sleep_performance", "sleep_total_min", "hours_vs_needed_pct", "restorative_min",
                             "sleep_consistency", "in_bed_min", "sleep_efficiency"]

    static func route(metric: String, pagesWithData: Set<String>) -> PulseRoute {
        if metric == "sleep_stress" { return PulseRoute.stressMonitor.forExistingEntryPoint }
        if PulseTrendView.isRebuilt { return .trendView(metric: metric) }
        return pagesWithData.contains(metric) ? .tab(.metric(metric)) : .tab(.sleep)
    }

    /// VoiceOver's hint, naming the screen the route really opens.
    static func hint(_ route: PulseRoute) -> String {
        switch route {
        case .trendView: return String(localized: "Opens Trend View")
        case .stressMonitor, .classic(.stress): return String(localized: "Opens Stress Monitor")
        case .tab(.sleep): return String(localized: "Opens the Sleep screen")
        case .tab(.metric): return String(localized: "Opens its history")
        default: return String(localized: "Opens details")
        }
    }
}

// MARK: - Contributor callout (§3.3 item 3)

/// The four contributors in the notched callout under the ring, each opening its metric (`PulseSleepRoutes`),
/// then the Poor / Sufficient / Optimal legend while the night has a score.
struct PulseSleepContributorCallout: View {
    let rows: [SleepContributorRow]
    var showsLegend = true
    var metricPages: Set<String> = []

    var body: some View {
        PulseCallout {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    let route = PulseSleepRoutes.route(metric: row.metric, pagesWithData: metricPages)
                    PulseLink(route) {
                        PulseSleepContributorRowView(row: row, hint: PulseSleepRoutes.hint(route))
                    }
                    .buttonStyle(PulsePressStyle())
                    if index < rows.count - 1 {
                        PulseDivider(leadingInset: 16, trailingInset: 16)
                    }
                }
            }
            if showsLegend {
                // The well sits right under the last row (deep-dives-2026/56: ≈3 pt), not the shared 12.
                PulseLegendWell { PulseLegendPoorSufficientOptimal() }
                    .padding(.top, -9)
            }
        }
    }
}

/// One contributor row (66 pt pitch, 2026): a 20 pt icon at 50%, the UPPERCASE label, then at the right the
/// Poor / Sufficient / Optimal dashes in a fixed column and the value (21 pt Bold condensed) right-aligned in
/// its own, so the dashes line up down the callout whatever the values' widths (deep-dives-2026/56). A row
/// that cannot be scored yet says "Calibrating" in place of both; one with nothing to show, a bare "--"
/// (deep-dives-2026/19f).
struct PulseSleepContributorRowView: View {
    let row: SleepContributorRow
    var hint = String(localized: "Opens Trend View")

    private var symbol: String {
        switch row.kind {
        case .hours: return "moon.circle"
        case .consistency: return "circle.lefthalf.filled"
        case .efficiency: return "bed.double"
        case .stress: return "gauge.with.needle"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: symbol)
                .pulseText(.subsectionTitle)
                .fontWeight(.regular)
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: 20)
                .padding(.trailing, 9)
                .accessibilityHidden(true)
            PulseWordWrapText(row.title, style: .label)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            if row.calibrating {
                Text(String(localized: "Calibrating"))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
            } else if let percent = row.percent {
                PulseMiniSegments(active: row.band)
                Text("\(PulseDisplay.displayedPercent(percent))%")
                    .pulseText(.calloutValue)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .frame(minWidth: 56, alignment: .trailing)
                    .padding(.leading, 12)
            } else {
                Text(verbatim: "--")
                    .pulseText(.calloutValue)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
        // 65.5 pt from row to row with the hairline between (deep-dives-2026/56).
        .frame(minHeight: PulseTheme.Row.contributorPitch - 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.title)
        .accessibilityValue(accessibility)
        .accessibilityHint(hint)
    }

    private var accessibility: String {
        if row.calibrating { return String(localized: "Calibrating") }
        guard let percent = row.percent else { return String(localized: "No data") }
        let band = row.band.map { ", " + PulseSleepBand.name($0) } ?? ""
        return String(localized: "\(PulseDisplay.displayedPercent(percent)) percent") + band
    }
}

#if DEBUG
/// The Sleep group's own DEBUG launch arguments, for captures (`simctl` cannot tap):
///   `--sleep-stage awake|light|deep|rem`   preselect a stage on the Sleep dive
///   `--sleep-computed-need`                prefer NOOP's computed need (and its breakdown) on a demo store
///   `--sleep-schedule`                     open My Schedule over the Sleep Planner
///   `--sleep-sheet goal|alarm|wake`        open one of the planner's sheets
///   `--sleep-drop-night`                   show Home's day on the dive as a day with no recorded night
///   `--sleep-edit`                         open EDIT (the night's editor, or adding one) once the dive loads
enum PulseSleepDebug {
    private static func value(_ flag: String) -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var stage: String? { value("--sleep-stage") }
    /// `--sleep-computed-need`: the dive shows NOOP's computed need and its breakdown on a demo store, whose
    /// seed writes an export's need (a total without parts).
    static var computedNeed: Bool { CommandLine.arguments.contains("--sleep-computed-need") }
    static var showsSchedule: Bool { CommandLine.arguments.contains("--sleep-schedule") }
    static var sheet: String? { value("--sleep-sheet") }
    static var dropsHomeNight: Bool { CommandLine.arguments.contains("--sleep-drop-night") }
    static var opensEditor: Bool { CommandLine.arguments.contains("--sleep-edit") }
}
#endif
#endif
