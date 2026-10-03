#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The Strain deep dive (WHOOP_UI_SPEC §3.5), pushed from the Strain dial and the sticky header.
///
/// Top to bottom, as the 2026 captures lay it out (deep-dives-2026/57, help-center/72, the 2026-04
/// storyboard deep-dives-2026/41): the 260 pt ring on 0–21 with the day's optimal range as a light band and
/// the Strain Target tick at its middle, the contributor callout (heart-rate zones 1-3 and 4-5, Strength
/// Activity Time, steps, each against its 30-day average), the inline insight (the band's meaning, or where
/// the day stands against its optimal range), Today's Activities, Weekly Trends (Strain, the two zone
/// groups stacked by zone, steps, calories, each opening its Trend View once that is rebuilt; steps opens
/// the Steps screen until then), then ZENO's day details and HOW IT'S CALCULATED. The bar carries the Big
/// Days achievement chip (§1.5 [Z], `PulseDiveAchievement`).
///
/// Owned by group "recovery-strain".
struct PulseStrainDiveView: View {
    /// Rebuilt: the dial and the sticky header route here (`PulseRoute.isRebuilt` already treats the
    /// dives as working screens with no classic fallback).
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var snapshot: StrainDiveSnapshot?
    /// The badges, for the bar's achievement chip.
    @State private var profile: ProfileSnapshot?

    /// The snapshot, only while it is for the day Home is on.
    private var current: StrainDiveSnapshot? {
        guard let snapshot, snapshot.day.offset == model.dayOffset else { return nil }
        return snapshot
    }

    var body: some View {
        PulseScreenScaffold(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                            trailing: PulseDiveAchievement.strain.trailing(profile, open: navigator.open),
                            coach: current.map { PulseCoachAccessory.pill(summary: $0.summary) } ?? .button,
                            coachSeed: current?.coachSeed,
                            spacing: 0,
                            ready: current != nil) {
            PulseLoadingGate(isLoading: current == nil) {
                if let s = current { PulseStrainDiveContent(snapshot: s) }
            } skeleton: {
                PulseSkeleton.dive
            }
        }
        .task(id: model.detailKey) {
            if let s = await model.build({ builder, request in await builder.strainDive(request) }) {
                snapshot = s
            }
        }
        .profileSnapshot($profile)
    }
}

/// The dive's content for one snapshot.
private struct PulseStrainDiveContent: View {
    let snapshot: StrainDiveSnapshot

    private var s: StrainDiveSnapshot { snapshot }

    private var legendDay: String {
        s.day.isToday ? String(localized: "Today") : PulseFormat.navDayTitle(offset: s.day.offset, date: s.day.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PulseHeroRing(content: s.base.dial.dialContent(target: s.base.target))
                .frame(maxWidth: .infinity)
                .padding(.top, 5)

            PulseDiveCallout(rows: s.contributors, dayLabel: legendDay)
                .padding(.top, 22)
                .id("pulse.contributors")

            // deep-dives-2026/57: the insight card sits 19 pt under the legend well, the callout's own
            // 16 pt bottom inset plus 3.
            PulseDiveInsight(text: s.insight, cta: String(localized: "Explore your strain insights"),
                             seed: s.coachSeed)
                .padding(.top, 3)

            PulseStrainActivitiesSection(activities: s.activities, isToday: s.day.isToday)
                .padding(.top, PulseTheme.Layout.sectionGap)
                .id("pulse.activities")

            PulseStrainWeeklyTrends(week: s.week)
                .padding(.top, PulseTheme.Layout.sectionGap)
                .id("pulse.weekly")

            PulseStrainDayDetails(snapshot: s)
                .padding(.top, PulseTheme.Layout.sectionGap)

            PulseDiveExplainerRow()
                .padding(.top, PulseTheme.Layout.stackGap)
                .id("pulse.explainer")
        }
    }
}

// MARK: - Today's Activities

/// "Today's Activities" (§3.5 item 5; "Activities" on a past day): the day's workouts as activity rows in
/// one card, each opening Activity Details, then "+ ADD ACTIVITY" and, today, "START ACTIVITY". Empty:
/// "No activities yet" and the add button.
private struct PulseStrainActivitiesSection: View {
    let activities: [StrainDiveSnapshot.Activity]
    let isToday: Bool

    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(isToday ? String(localized: "Today's Activities") : String(localized: "Activities"))
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: PulseTheme.Layout.gridGap) {
                    if activities.isEmpty {
                        Text(String(localized: "No activities yet"))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    ForEach(activities) { activity in
                        PulseLink(activity.route) {
                            PulseActivityRow(chip: PulseActivityChip(kind: activity.chip, symbol: activity.symbol,
                                                                     value: activity.chipValue),
                                             name: activity.name, start: PulseFormat.clock(activity.start),
                                             end: PulseFormat.clock(activity.end), barColor: PulseTheme.strain)
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
                PulseButtonRow {
                    Button { navigator.quickAction(.addActivity) } label: {
                        Label(String(localized: "Add activity"), systemImage: "plus")
                    }
                    .buttonStyle(.pulseNested)
                    if isToday && !activities.isEmpty {
                        Button { navigator.quickAction(.workout) } label: {
                            Label(String(localized: "Start activity"), systemImage: "stopwatch")
                        }
                        .buttonStyle(.pulseNested)
                    }
                }
                .padding(.top, activities.isEmpty ? 16 : 20)
            }
            .padding(12)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulseCardBackground()
        }
    }
}

// MARK: - Weekly Trends

/// "Weekly Trends" (§3.5 item 6, the 2026-04 storyboard): Strain bars with one-decimal labels, heart-rate
/// zones 1-3 and 4-5 stacked by zone with h:mm totals, then steps and calories.
private struct PulseStrainWeeklyTrends: View {
    let week: StrainDiveSnapshot.Week

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(String(localized: "Weekly Trends"), style: .weeklyTrendsTitle)
            VStack(spacing: PulseTheme.Layout.stackGap) {
                PulseWeeklyTrendCard(String(localized: "Strain"), route: PulseDiveRoutes.trend("strain")) {
                    PulseBarChart(data: week.strain, yDomain: 0...21, gridValues: [0, 7, 14, 21],
                                  highlightID: week.highlightID, height: PulseWeeklyChart.height,
                                  emptyMessage: String(localized: "No Strain recorded this week"))
                }
                PulseWeeklyTrendCard(String(localized: "HR zones 1-3"), route: PulseDiveRoutes.trend("hr_zones13_min"),
                                     legend: legend([1, 2, 3])) {
                    zones(week.lowerZones)
                }
                PulseWeeklyTrendCard(String(localized: "HR zones 4-5"), route: PulseDiveRoutes.trend("hr_zones45_min"),
                                     legend: legend([4, 5])) {
                    zones(week.upperZones)
                }
                .id("pulse.weekly-upper")
                PulseWeeklyTrendCard(String(localized: "Steps"), route: week.stepsRoute) {
                    PulseBarChart(data: week.steps, highlightID: week.highlightID, height: PulseWeeklyChart.height,
                                  emptyMessage: String(localized: "No steps this week"))
                }
                .id("pulse.weekly-steps")
                PulseWeeklyTrendCard(String(localized: "Calories"), route: PulseDiveRoutes.trend(week.caloriesMetric)) {
                    PulseBarChart(data: week.calories, highlightID: week.highlightID, height: PulseWeeklyChart.height,
                                  emptyMessage: String(localized: "No calories this week"))
                }
            }
        }
    }

    private func legend(_ zones: [Int]) -> [PulseWeeklyLegendItem] {
        zones.map { PulseWeeklyLegendItem(title: String(localized: "Zone \($0)"), color: PulseTheme.Zone.color($0)) }
    }

    @ViewBuilder
    private func zones(_ columns: [PulseStackedBarChart.Column]) -> some View {
        if columns.contains(where: { !$0.segments.isEmpty }) {
            PulseStackedBarChart(columns: columns, highlightID: week.highlightID, height: PulseWeeklyChart.height)
                .accessibilityLabel(columns.compactMap { column in
                    column.totalLabel.map { "\(column.label) \(column.sublabel ?? ""): \($0)" }
                }.joined(separator: ", "))
        } else {
            Text(String(localized: "No heart rate recorded this week"))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: PulseWeeklyChart.height)
        }
    }
}
#endif
