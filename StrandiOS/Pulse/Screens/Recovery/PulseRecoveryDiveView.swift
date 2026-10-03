#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The Recovery deep dive (WHOOP_UI_SPEC §3.4), pushed from the Recovery dial and the sticky header.
///
/// Top to bottom, as the Sep 2026 captures lay it out (deep-dives-2026/17b, 17c, 16): the 260 pt ring in
/// the band colour, the contributor callout (heart rate variability, resting heart rate, respiratory rate
/// and sleep performance against their 30-day averages), BEHAVIOR INSIGHTS (the day's behaviour chips, or
/// the compact row), Weekly Trends (Recovery, HRV, resting heart rate, respiratory rate, each opening its
/// Trend View), then ZENO's "What shaped it". The inline insight card WHOOP dropped by Sep 2026 is gone;
/// the floating coach summary pill carries the summary.
///
/// Owned by group "recovery-strain".
struct PulseRecoveryDiveView: View {
    /// Rebuilt: the dial and the sticky header route here (`PulseRoute.isRebuilt` already treats the
    /// dives as working screens with no classic fallback).
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var snapshot: RecoveryDiveSnapshot?

    /// The snapshot, only while it is for the day Home is on (a day change shows the skeleton, never the
    /// previous day's figures under the new day's title).
    private var current: RecoveryDiveSnapshot? {
        guard let snapshot, snapshot.day.offset == model.dayOffset else { return nil }
        return snapshot
    }

    var body: some View {
        PulseScreenScaffold(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                            trailing: .info { navigator.open(.classic(.scoringGuide)) },
                            coach: current.map { PulseCoachAccessory.pill(summary: $0.summary) } ?? .button,
                            coachSeed: current?.coachSeed,
                            spacing: 0,
                            ready: current != nil) {
            PulseLoadingGate(isLoading: current == nil) {
                if let s = current { PulseRecoveryDiveContent(snapshot: s) }
            } skeleton: {
                PulseSkeleton.dive
            }
        }
        .task(id: model.detailKey) {
            if let s = await model.build({ builder, request in await builder.recoveryDive(request) }) {
                snapshot = s
            }
        }
    }
}

/// The dive's content for one snapshot.
private struct PulseRecoveryDiveContent: View {
    let snapshot: RecoveryDiveSnapshot

    private var s: RecoveryDiveSnapshot { snapshot }

    /// The dial with its state line: "CALIBRATING" inside the ring; a carried night is named under the bar
    /// instead, so it is not said twice.
    private var hero: PulseDialContent {
        var content = s.dial.dialContent()
        if s.carriedCaption != nil { content.caption = nil }
        return content
    }

    /// The night the callout's values are from: "Today", the day itself on a past day ("Wed, Aug 19 vs.
    /// last 30 days"), or a carried night's own date, so the legend never calls an earlier night today.
    private var legendDay: String {
        if s.carriedCaption != nil, let key = s.sourceDayKey { return PulseFormat.navDayTitle(dayKey: key) }
        return s.day.isToday ? String(localized: "Today") : PulseFormat.navDayTitle(offset: s.day.offset, date: s.day.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let carried = s.carriedCaption {
                PulseDiveCarriedLine(text: carried)
                    .padding(.bottom, 8)
            }
            PulseHeroRing(content: hero)
                .frame(maxWidth: .infinity)
                .padding(.top, 5)

            PulseDiveCallout(rows: s.contributors, dayLabel: legendDay)
                .padding(.top, 22)
                .id("pulse.contributors")

            if case .calibrating(let nights, let of) = s.dial.state {
                PulseRecoveryCalibrationCard(nights: nights, of: of)
                    .padding(.top, PulseTheme.Layout.stackGap)
            }

            PulseRecoveryBehaviorCard(behaviors: s.behaviors)
                .padding(.top, PulseTheme.Layout.stackGap)
                .id("pulse.behavior")

            PulseRecoveryWeeklyTrends(week: s.week)
                .padding(.top, PulseTheme.Layout.sectionGap)
                .id("pulse.weekly")

            if let shaped = s.shaped {
                PulseRecoveryShapedCard(shaped: shaped)
                    .padding(.top, PulseTheme.Layout.stackGap)
                    .id("pulse.shaped")
            }
        }
    }
}

// MARK: - Calibrating

/// While the baseline learns (fewer than four nights): how far along it is, in Recovery's own words.
private struct PulseRecoveryCalibrationCard: View {
    let nights: Int
    let of: Int

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                PulseCardTitle(String(localized: "Calibrating"))
                Text(String(localized: "Recovery needs \(of) nights of wear to learn your baseline. \(nights) of \(of) nights recorded."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    ForEach(0..<max(1, of), id: \.self) { i in
                        Capsule().fill(i < nights ? PulseTheme.recoveryBlue : PulseTheme.track)
                    }
                }
                .frame(height: 6)
                .accessibilityHidden(true)
                if let restart = ChargeBreakdownFormat.currentCalibrationRestartCause() {
                    Text(restart)
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Behavior Insights

/// BEHAVIOR INSIGHTS (§3.4 item 5): the expanded card with the day's behaviour chips when at least one
/// logged behaviour has a measurable effect on Recovery (deep-dives-2026/17b; grey chips may sit beside
/// it), else the compact row (deep-dives-2026/17c), so the card never says behaviours "may have affected"
/// the score above chips that all read "no clear effect". Both open Behavior Insights.
private struct PulseRecoveryBehaviorCard: View {
    let behaviors: [RecoveryDiveSnapshot.Behavior]

    var body: some View {
        PulseLink(PulseRoute.behaviorInsights.forExistingEntryPoint) {
            if behaviors.contains(where: { $0.effect != .neutral }) {
                expanded
            } else {
                compact
            }
        }
        .buttonStyle(PulsePressStyle())
    }

    /// The outlined bulb, at the subsection title's size (light, as the captures draw it).
    private var bulb: some View {
        Image(systemName: "lightbulb.max")
            .font(PulseType.font(.subsectionTitle).weight(.light))
            .foregroundStyle(PulseTheme.subtitleRowIcon)
            .accessibilityHidden(true)
    }

    /// The compact row (deep-dives-2026/17c): 64 pt, the bulb 19 pt in from the edge, the title's caps
    /// centred 22 pt down with the 12 pt subtitle under it on one line, "›" at the right.
    private var compact: some View {
        HStack(spacing: 8) {
            bulb
                .frame(width: 19)
            VStack(alignment: .leading, spacing: 4) {
                PulseWordWrapText(String(localized: "Behavior Insights"), style: .cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "See how your behaviors impact your recovery."))
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.subtitleRowText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            PulseChevron(color: PulseTheme.textSecondary, size: 14)
        }
        .padding(.leading, 18)
        .padding(.trailing, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .pulseCardBackground(.solid(PulseTheme.subtitleRowCard))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// Measured on deep-dives-2026/17b (the same 402 pt screen): the title's caps 8 pt tall and centred
    /// 26 pt under the card's top, the 13 pt body's lines 17.5 pt apart from 57 pt down, the chips 15 pt
    /// under it.
    private var expanded: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                bulb
                    .frame(width: 19, height: 20)
                PulseWordWrapText(String(localized: "Behavior Insights"), style: .cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                PulseChevron()
            }
            Text(String(localized: "Some of your behaviors from yesterday may have affected your Recovery score today."))
                .pulseText(.rowSubline)
                .lineSpacing(2)
                .foregroundStyle(PulseTheme.subtitleRowText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 13)
            PulseChipFlow(spacing: 8, lineSpacing: 8) {
                ForEach(behaviors) { behavior in
                    PulseBehaviorChip(title: behavior.title, effect: behavior.effect)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(behavior.spoken)
                }
            }
            .padding(.top, 15)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .contentShape(Rectangle())
    }
}

// MARK: - Weekly Trends

/// "Weekly Trends" (§3.4 item 6, deep-dives-2026/16): Recovery bars in their band colours, then heart rate
/// variability, resting heart rate and respiratory rate as lines (no typical band on the weekly card).
private struct PulseRecoveryWeeklyTrends: View {
    let week: RecoveryDiveSnapshot.Week

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(String(localized: "Weekly Trends"), style: .weeklyTrendsTitle)
            VStack(spacing: PulseTheme.Layout.stackGap) {
                PulseWeeklyTrendCard(String(localized: "Recovery"), route: PulseDiveRoutes.trend("recovery")) {
                    PulseBarChart(data: week.recovery, yDomain: 0...100, gridValues: [0, 33, 66, 100],
                                  highlightID: week.highlightID, height: PulseWeeklyChart.height,
                                  emptyMessage: String(localized: "No Recovery scored this week"))
                }
                PulseWeeklyTrendCard(String(localized: "Heart rate variability"), route: PulseDiveRoutes.trend("hrv")) {
                    line(week.hrv, empty: String(localized: "No heart rate variability this week"))
                }
                PulseWeeklyTrendCard(String(localized: "Resting heart rate"), route: PulseDiveRoutes.trend("rhr")) {
                    line(week.rhr, empty: String(localized: "No resting heart rate this week"))
                }
                .id("pulse.weekly-rhr")
                PulseWeeklyTrendCard(String(localized: "Respiratory rate"), route: PulseDiveRoutes.trend("resp_rate")) {
                    line(week.resp, empty: String(localized: "No respiratory rate this week"))
                }
            }
        }
    }

    private func line(_ data: [PulseChartDatum], empty: String) -> some View {
        PulseLineChart(data: data, color: PulseTheme.recoveryBlue, highlightID: week.highlightID,
                       height: PulseWeeklyChart.height, emptyMessage: empty)
    }
}

// MARK: - What shaped it

/// "WHAT SHAPED IT" (§3.4 item 7, ZENO): the points each input added to or took from the score against
/// the personal baseline the engine scored it with, biggest mover first, with the score's confidence.
private struct PulseRecoveryShapedCard: View {
    let shaped: RecoveryDiveSnapshot.Shaped

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                PulseCardTitle(String(localized: "What shaped it"))
                PulseConfidenceChip(confidence: shaped.confidence)
            }
            .padding(.bottom, 4)
            ForEach(Array(shaped.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { PulseDivider() }
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        PulseWordWrapText(row.title, style: .label)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Text(row.detail)
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    PulsePointsChip(points: row.points)
                }
                .padding(.vertical, 12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.spoken)
            }
            Text(String(localized: "Points each input added to or took from Recovery, against the personal baseline it scores with."))
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
    }
}
#endif
