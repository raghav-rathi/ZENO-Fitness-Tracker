#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The DEBUG `--demo-screen pulsesleep` host (Debug/PulseDemo.swift) still names the dive's first type.
typealias PulseSleepView = PulseSleepDiveView

/// The Sleep deep dive (WHOOP_UI_SPEC §3.3), pushed from the Sleep dial, the sleep rows and the sticky
/// header's mini ring.
///
/// Top to bottom: "‹ TODAY ›" with ⓘ (the nights step in the bar's title, ARCHITECTURE §9); the 260 / 15
/// Sleep Performance ring with its Poor / Sufficient / Optimal dashes; the notched callout with HOURS VS.
/// NEEDED, SLEEP CONSISTENCY, SLEEP EFFICIENCY and HIGH SLEEP STRESS, each on its own thresholds, and the
/// legend well; "Last Night's Sleep" with EDIT and "Today vs. prior 30 days"; HOURS OF SLEEP (heart rate,
/// stages, restorative, latency); the four detail cards; the seven Weekly Trends cards; then ZENO's naps and
/// sleeping heart rate. The coach summary pill floats at the bottom with a local sentence until the Coach
/// writes one (§1.2 [Z]).
///
/// ‹ › rebuild EVERYTHING on the page from that night, in one snapshot: the ring, the callout, every card
/// and the week the trends end on. The night's stress is scored in a second build (it reads the night's raw
/// heart rate and R-R and the waking hours before it), so the SLEEP STRESS card and its contributor fill in
/// a moment after the rest, never showing another night's figures meanwhile.
struct PulseSleepDiveView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator

    /// The night the wearer stepped to, by wake day; nil means Home's night.
    @State private var nightKey: String?
    @State private var snapshot: SleepDiveSnapshot?
    @State private var stress: SleepStressSnapshot?
    @State private var selectedStage: SleepStage?
    #if DEBUG
    @State private var debugApplied = false
    #endif

    // MARK: Title and pager

    /// Home's day, which the title mirrors for its own night.
    private var homeTitle: String {
        PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate)
    }

    private var pager: PulseNavTitlePager? {
        guard let s = snapshot, !s.nightKeys.isEmpty else { return nil }
        let title: String
        if let key = s.wakeDayKey, key != s.requestDayKey {
            // A night is named by the day it ended on: a DAY KEY, so it is formatted at UTC.
            title = PulseFormat.navDayTitle(dayKey: key)
        } else {
            title = homeTitle
        }
        return PulseNavTitlePager(title: title, canGoBack: s.hasOlder, canGoForward: s.hasNewer,
                                  onBack: { step(1) }, onForward: { step(-1) })
    }

    private func step(_ delta: Int) {
        guard let s = snapshot else { return }
        let target = s.nightIndex + delta
        guard s.nightKeys.indices.contains(target) else { return }
        nightKey = s.nightKeys[target]
    }

    /// The night's stress, only when it is this night's.
    private var currentStress: SleepStressSnapshot? {
        guard let stress, stress.nightKey == snapshot?.wakeDayKey else { return nil }
        return stress
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
        PulseScreenScaffold(title: homeTitle, titlePager: pager,
                            trailing: .info { navigator.open(.classic(.scoringGuide)) },
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
            return
        }
        // A refresh landing mid-build supersedes it (nil); this task is keyed on the night, not the refresh,
        // so it tries again rather than leaving the card loading.
        for _ in 0..<3 {
            if let s = await model.build({ builder, r in await builder.sleepStress(r, request: request) }) {
                stress = s
                return
            }
            if Task.isCancelled { return }
        }
    }

    #if DEBUG
    /// `--pulse-night N` lands on night N once; `--sleep-stage awake|light|deep|rem` preselects a stage.
    private func applyDebugLaunch(_ s: SleepDiveSnapshot) {
        guard !debugApplied else { return }
        debugApplied = true
        if let n = PulseDebugLaunch.nightIndex, s.nightKeys.indices.contains(n), s.nightKeys[n] != s.wakeDayKey {
            nightKey = s.nightKeys[n]
            debugApplied = false
            return
        }
        if let raw = PulseSleepDebug.stage, let stage = SleepStage(rawValue: raw) { selectedStage = stage }
    }
    #endif

    // MARK: Content

    @ViewBuilder
    private func content(_ s: SleepDiveSnapshot) -> some View {
        let band = PulseSleepBand.index(percent: s.dial.value)
        PulseHeroRing(content: s.dial.dialContent(label: String(localized: "Sleep performance")),
                      accessoryAccessibility: band.map(PulseSleepBand.name)) {
            PulseMiniSegments(active: band)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)

        PulseSleepContributorCallout(rows: contributors(s))
            .padding(.top, 5)
            .id("pulse.contributors")

        lastNightHeader(s)
            .id("pulse.last-night")

        if let night = s.lastNight {
            PulseSleepLastNightCard(night: night, selected: $selectedStage) { explain(.hoursOfSleep) }
                .id("pulse.hr")
        } else {
            PulseSleepEmptyCard(title: String(localized: "Hours of sleep"), dash: "-:--") { explain(.hoursOfSleep) }
        }

        Group {
            if let card = s.hoursVsNeeded {
                PulseSleepHoursVsNeededCard(card: card) { explain(.hoursVsNeeded) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Hours vs. needed"), dash: "--%") { explain(.hoursVsNeeded) }
            }
        }
        .id("pulse.hours-vs-needed")

        Group {
            if let card = s.consistency {
                PulseSleepConsistencyCard(card: card) { explain(.consistency) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Sleep consistency"), dash: "--%") { explain(.consistency) }
            }
        }
        .id("pulse.consistency")

        Group {
            if let card = s.efficiency {
                PulseSleepEfficiencyCard(card: card) { explain(.efficiency) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Sleep efficiency"), dash: "--%") { explain(.efficiency) }
            }
        }
        .id("pulse.efficiency")

        Group {
            if s.stress != nil {
                PulseSleepStressCard(stress: currentStress) { explain(.stress) }
            } else {
                PulseSleepEmptyCard(title: String(localized: "Sleep stress"), dash: "--%") { explain(.stress) }
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
            PulseSleepWeeklyTrends(week: s.weekly)
        }

        extras(s)
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

    /// "Last Night's Sleep" with EDIT ✎ and "Today vs. prior 30 days" under it.
    private func lastNightHeader(_ s: SleepDiveSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            PulseSectionHeader(String(localized: "Last Night's Sleep"),
                               accessory: s.lastNight == nil ? .none : .edit { navigator.present(.tab(.sleep)) })
            Group {
                if let key = s.wakeDayKey, !(s.isLatest && key == s.requestDayKey) {
                    Text(PulseFormat.dayLabel(key, template: "MMMd")).fontWeight(.semibold)
                        .foregroundColor(PulseTheme.textPrimary)
                        + Text(" ") + Text(String(localized: "vs. prior 30 days")).foregroundColor(PulseTheme.textSecondary)
                } else {
                    Text(String(localized: "Today")).fontWeight(.semibold).foregroundColor(PulseTheme.textPrimary)
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
            HStack(spacing: PulseTheme.Layout.gridGap) {
                PulseMiniStat(title: String(localized: "Sleeping HR"), value: s.sleepingHR.map { "\($0)" }, unit: "bpm")
                PulseMiniStat(title: String(localized: "Lowest HR"), value: s.lowestHR.map { "\($0)" }, unit: "bpm")
                PulseMiniStat(title: String(localized: "Breathing"), value: s.respRate.map { PulseFormat.oneDecimal($0) },
                              unit: "rpm")
            }
            .padding(.top, s.naps.isEmpty ? PulseTheme.Layout.sectionGap - PulseTheme.Layout.stackGap : 0)
        }
    }

    private func explain(_ topic: PulseSleepExplainerTopic) {
        navigator.open(PulseSleepExplainerRoute(topic: topic).route)
    }
}

// MARK: - Contributor callout (§3.3 item 3)

/// The four contributors in the notched callout under the ring, each opening Trend View for its metric,
/// then the Poor / Sufficient / Optimal legend.
struct PulseSleepContributorCallout: View {
    let rows: [SleepContributorRow]

    var body: some View {
        PulseCallout {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    PulseLink(Self.route(row)) {
                        PulseSleepContributorRowView(row: row)
                    }
                    .buttonStyle(PulsePressStyle())
                    if index < rows.count - 1 {
                        PulseDivider(leadingInset: 16, trailingInset: 16)
                    }
                }
            }
            // The well sits right under the last row (deep-dives-2026/56: ≈3 pt), not the shared 12.
            PulseLegendWell { PulseLegendPoorSufficientOptimal() }
                .padding(.top, -9)
        }
    }

    /// Trend View for the row's metric (the classic metric detail until Trend View is rebuilt). Sleep stress
    /// has no classic detail, so until Trend View can chart it the row opens the Stress Monitor.
    static func route(_ row: SleepContributorRow) -> PulseRoute {
        if row.kind == .stress && !PulseTrendView.isRebuilt {
            return PulseRoute.stressMonitor.forExistingEntryPoint
        }
        return PulseRoute.trendView(metric: row.metric).forExistingEntryPoint
    }
}

/// One contributor row (66 pt pitch, 2026): a 20 pt icon at 50%, the UPPERCASE label, then at the right the
/// Poor / Sufficient / Optimal dashes in a fixed column and the value (21 pt Bold condensed) right-aligned in
/// its own, so the dashes line up down the callout whatever the values' widths (deep-dives-2026/56). A row
/// that cannot be scored yet says "Calibrating" in place of both.
struct PulseSleepContributorRowView: View {
    let row: SleepContributorRow

    private var symbol: String {
        switch row.kind {
        case .hours: return "moon.circle"
        case .consistency: return "clock.arrow.circlepath"
        case .efficiency: return "bed.double"
        case .stress: return "gauge.with.needle"
        }
    }

    private var valueText: String {
        row.percent.map { "\(PulseDisplay.displayedPercent($0))%" } ?? "--%"
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .regular))
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
            } else {
                PulseMiniSegments(active: row.band)
                Text(valueText)
                    .pulseText(.calloutValue)
                    .foregroundStyle(row.percent == nil ? PulseTheme.textDisabled : PulseTheme.textPrimary)
                    .lineLimit(1)
                    .frame(minWidth: 56, alignment: .trailing)
                    .padding(.leading, 12)
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
        .accessibilityHint(String(localized: "Opens Trend View"))
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
}
#endif
#endif
