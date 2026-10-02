#if os(iOS) && DEBUG
import SwiftUI

/// DEBUG `--pulse-gallery`: every shared component on one scrolling page with sample data, so a change to
/// Theme/ or Components/ can be checked at a glance and the next wave can see what exists. Not in Release.
struct PulseComponentGallery: View {
    @State private var range: PulseRange = .week
    @State private var tab = "STATUS"
    @State private var toggle = true

    var body: some View {
        NavigationStack {
            PulseScreenScaffold(title: "Component gallery", spacing: 24) {
                // `--pulse-scroll gallery-<section>` jumps to a section.
                dials.id("pulse.gallery-dials")
                surfaces.id("pulse.gallery-cards")
                headers.id("pulse.gallery-headers")
                rows.id("pulse.gallery-rows")
                trendsAndStatus.id("pulse.gallery-status")
                banners.id("pulse.gallery-banners")
                callout.id("pulse.gallery-callout")
                controls.id("pulse.gallery-controls")
                buttons.id("pulse.gallery-buttons")
                charts.id("pulse.gallery-charts")
                coach.id("pulse.gallery-coach")
            }
            .environment(\.pulseModalRoot, true)
        }
        .tint(PulseTheme.chromeTint)
    }

    private func title(_ text: String) -> some View {
        PulseListSectionHeader(text).padding(.top, 8)
    }

    // MARK: Dials

    private var dials: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("Dials · 88 / 6")
            HStack(alignment: .top, spacing: 12) {
                PulseScoreDial(content: .percent(label: "Sleep", percent: 81, color: PulseTheme.sleep))
                PulseScoreDial(content: .percent(label: "Recovery", percent: 51, color: PulseTheme.recoveryMid))
                // Below the range: the band floats apart from the arc, the tick sits at the midpoint.
                PulseScoreDial(content: .strain(label: "Strain", value: 4.3, optimalRange: 8.3...12.3, target: 10.3))
            }
            HStack(alignment: .top, spacing: 12) {
                PulseScoreDial(content: .percent(label: "Recovery", percent: nil, color: PulseTheme.textTertiary,
                                                 caption: "Calibrating"))
                PulseScoreDial(content: .strain(label: "Strain", value: 0.2, optimalRange: 9.1...13.1, target: 11.1))
                PulseScoreDial(content: .strain(label: "Strain", value: 16.8, optimalRange: 14...18, target: 16))
            }
            .frame(maxWidth: .infinity)
            title("Deep-dive ring · 260 / 15")
            PulseHeroRing(content: .percent(label: "Sleep performance", percent: 100, color: PulseTheme.sleep)) {
                PulseMiniSegments(active: 2)
            }
            .frame(maxWidth: .infinity)
            title("Mini rings · 24 / 2")
            PulseMiniRingRow(items: [
                .init(id: "s", content: .percent(label: "Sleep", percent: 71, color: PulseTheme.sleep), action: {}),
                .init(id: "r", content: .percent(label: "Recovery", percent: 24, color: PulseTheme.recoveryLow), action: {}),
                .init(id: "t", content: .strain(label: "Strain", value: 4.3, optimalRange: nil, target: nil), action: {}),
            ])
            .padding(.horizontal, -16)
            title("Brand")
            HStack(spacing: 24) {
                PulseZenoWordmark()
                PulseCoachAvatar()
                PulseStrapGlyph(connected: true)
                PulseStrapGlyph(connected: false)
            }
        }
    }

    // MARK: Surfaces

    private var surfaces: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Cards")
            ForEach(Array(cardStyles.enumerated()), id: \.offset) { _, item in
                PulseCard(item.1) {
                    Text(item.0).pulseText(.cardTitle).foregroundStyle(PulseTheme.textPrimary)
                }
            }
        }
    }

    private var cardStyles: [(String, PulseCardStyle)] {
        [("standard · white 10%", .standard), ("detail · white 4.5%", .detail), ("coaching · white 7.5%", .coaching),
         ("well · black 50%", .well), ("banner well · black", .banner), ("row card", .rowCard), ("outlined", .outlined)]
    }

    // MARK: Headers

    private var headers: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Headers")
            PulseSectionHeader("My Day", accessory: .plus("Add") {})
            PulseSectionHeader("My Dashboard", accessory: .customize {})
            PulseSectionHeader("Last Night's Sleep", accessory: .edit {})
            PulseSectionHeader("Achievements", count: 34, style: .pageTitle, accessory: .viewAll {})
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    PulseCardTitle("Health Monitor", accessory: .chevron)
                    PulseCardTitle("Today's Activities", accessory: .expand)
                    PulseCardTitle("Strain & Recovery", accessory: .info)
                }
            }
            PulseListSectionHeader("Account & Settings")
        }
    }

    // MARK: Rows

    private var rows: some View {
        VStack(alignment: .leading, spacing: 10) {
            title("Rows")
            PulseListRow(symbol: "gearshape", title: "App Settings")
            PulseListRow(symbol: "person.crop.circle", title: "Membership", subtitle: "Manage your plan")
            PulseListRow(symbol: "rectangle.stack", title: "Classic interface", trailing: .toggle($toggle))
            PulseMetricRow(symbol: "waveform.path.ecg", title: "Heart rate variability", value: "51",
                           trend: PulseTrend(direction: .up, polarity: .higherIsBetter), baseline: "46")
            PulseMetricRow(symbol: "heart", title: "Resting heart rate", value: "60", unit: "bpm",
                           trend: PulseTrend(direction: .up, polarity: .lowerIsBetter), baseline: "58")
            PulseMetricRow(symbol: "scalemass", title: "Weight", value: "88.5",
                           trend: PulseTrend(direction: .up, polarity: .neutral), baseline: "88.3")
            PulseMetricRow(symbol: "flame", title: "Calories")
            PulseCard {
                VStack(spacing: 12) {
                    PulseActivityRow(chip: PulseActivityChip(kind: .sleep, symbol: "moon.fill", value: "6:41"),
                                     name: "Sleep", start: "[Wed] 11:03 PM", end: "6:21 AM", barColor: .white)
                    PulseActivityRow(chip: PulseActivityChip(kind: .strain, symbol: "figure.run", value: "5.4"),
                                     name: "Running", start: "7:12 AM", end: "7:58 AM")
                    PulseActivityRow(chip: PulseActivityChip(kind: .recovery, symbol: "flame", value: "0:20"),
                                     name: "Sauna", start: "6:00 PM", end: "6:20 PM", barColor: PulseTheme.recoveryActivityChip)
                    PulseActivityRow(chip: PulseActivityChip(kind: .unscoredSleep, symbol: "moon.fill"),
                                     name: "Sleep", start: "1:25 AM", end: "8:27 AM", barColor: .white)
                    PulseActivityRow(chip: PulseActivityChip(kind: .pending, symbol: "dumbbell"),
                                     name: "Strength Trainer", start: "5:00 PM", end: "5:45 PM")
                    PulseActivityRow(chip: PulseActivityChip(kind: .preAdded, symbol: "bicycle"),
                                     name: "Cycling", start: "7:00 PM", end: "8:00 PM", dottedBar: true)
                }
            }
            PulseSubtitleRowCard(symbol: "lightbulb", title: "Behavior Insights",
                                 subtitle: "Log 3 more days to see what moves your Recovery")
        }
    }

    // MARK: Trends and status

    private var trendsAndStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Trend glyphs and delta chips")
            HStack(spacing: 18) {
                PulseTrendGlyph(trend: PulseTrend(direction: .up, polarity: .higherIsBetter))
                PulseTrendGlyph(trend: PulseTrend(direction: .down, polarity: .higherIsBetter))
                PulseTrendGlyph(trend: PulseTrend(direction: .down, polarity: .lowerIsBetter))
                PulseTrendGlyph(trend: PulseTrend(direction: .up, polarity: .neutral))
                PulseTrendGlyph(trend: PulseTrend(direction: .flat, polarity: .higherIsBetter))
            }
            HStack(spacing: 8) {
                PulseDeltaChip(text: "12%", trend: PulseTrend(direction: .up, polarity: .higherIsBetter))
                PulseDeltaChip(text: "8%", trend: PulseTrend(direction: .up, polarity: .lowerIsBetter))
                PulseDeltaChip(text: "2.6", trend: PulseTrend(direction: .up, polarity: .neutral))
                PulseDeltaChip(text: "0%", trend: PulseTrend(direction: .flat, polarity: .neutral))
            }
            title("Status")
            HStack(spacing: 8) {
                PulseStatusBadge(.check, tint: .teal)
                PulseStatusBadge(.alert, tint: .red)
                PulseStatusBadge(.alert, tint: .orange)
                PulseStatusBadge(.pending, tint: .grey)
                PulseStatusBadge(.value("1.5"), tint: PulseTheme.Stress.Level(value: 1.5).tint)
                PulseStatusBadge(.value("2.4"), tint: PulseTheme.Stress.Level(value: 2.4).tint)
                PulseStatusBadge(.value("0.7"), tint: PulseTheme.Stress.Level(value: 0.7).tint)
            }
            HStack(spacing: 8) {
                PulseStatusChip("Optimal", kind: .positive)
                PulseStatusChip("Out of Range", kind: .negative)
                PulseStatusChip("Sufficient", kind: .neutral)
            }
            HStack(spacing: 8) {
                PulseTag("Beta")
                PulseTag("New", outlined: true)
                PulseMiniSegments(active: 0)
                PulseMiniSegments(active: 1)
                PulseMiniSegments(active: 2)
            }
            HStack(spacing: 8) {
                PulseAchievementChip(symbol: "hexagon.fill", tint: PulseTheme.sleep, count: 796)
                PulseAchievementChip(symbol: "shield.fill", tint: PulseTheme.recoveryHigh, count: 38)
                PulseAchievementChip(symbol: "diamond.fill", tint: PulseTheme.strain, count: 6)
            }
            HStack(spacing: 8) {
                PulseFilterChip(title: "All", isSelected: true) {}
                PulseFilterChip(title: "Sleep", isSelected: false) {}
                PulseFilterChip(title: "Strain", isSelected: false) {}
            }
        }
    }

    // MARK: Banners

    private var banners: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Banners")
            PulseStatusBanner(.caughtUp(syncedTo: "7:32AM"))
            PulseStatusBanner(.catchingUp(progress: 0.42))
            PulseStatusBanner(.offWrist)
            PulseStatusBanner(.lowBattery(percent: 12), onDismiss: {})
        }
    }

    // MARK: Callout

    private var callout: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Callout, legend and notched well")
            PulseCallout {
                PulseCalloutRow(symbol: "waveform.path.ecg", title: "Heart rate variability", value: "124",
                                baseline: "98", trend: PulseTrend(direction: .up, polarity: .higherIsBetter))
                PulseDivider(leadingInset: 16, trailingInset: 16)
                PulseCalloutRow(symbol: "heart", title: "Resting heart rate", value: "49",
                                baseline: "47", trend: PulseTrend(direction: .up, polarity: .lowerIsBetter))
                PulseDivider(leadingInset: 16, trailingInset: 16)
                PulseCalloutRow(symbol: "moon", title: "Sleep performance", value: "74", unit: "%",
                                baseline: "74%", trend: PulseTrend(direction: .flat, polarity: .higherIsBetter))
                PulseDivider(leadingInset: 16, trailingInset: 16)
                PulseCalloutRow(symbol: "moon.zzz", title: "Hours vs. needed", value: "100", unit: "%", segments: 2)
                PulseLegendWell { PulseLegendTodayVsBaseline() }
                PulseLegendWell { PulseLegendPoorSufficientOptimal() }
            }
            PulseCard(.solid(PulseTheme.SleepDetail.needWellCard)) {
                PulseNotchedWell(notchPosition: 0.15) {
                    PulseNotchedWellRow(swatch: PulseTheme.SleepDetail.healthyMinimum, title: "Baseline", value: "7:21")
                    PulseNotchedWellRow(swatch: PulseTheme.strain, title: "Recent strain", value: "+0:12")
                    PulseNotchedWellRow(swatch: PulseTheme.SleepDetail.sleepDebt, title: "Sleep debt", value: "+0:28")
                }
            }
        }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Controls")
            PulseSegmentedControl(options: PulseRange.allCases, selection: $range) { $0.title }
            PulseSegmentedControl(options: ["STATUS", "ADVANCED"], selection: $tab, style: .underline) { $0 }
            HStack {
                Spacer()
                PulseDayPager(title: "Today", canGoBack: true, canGoForward: false, onBack: {}, onForward: {}, onTitleTap: {})
                Spacer()
            }
            PulseDayPager(title: "Wed, May 27", canGoBack: true, canGoForward: true, onBack: {}, onForward: {})
            PulseRangePager(title: "May 9 - May 15, 26", canGoBack: true, canGoForward: false, onBack: {}, onForward: {})
        }
    }

    // MARK: Buttons

    private var buttons: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Buttons")
            HStack(spacing: 12) {
                Button {} label: { Label("Add activity", systemImage: "plus") }.buttonStyle(.pulseNested)
                Button {} label: { Label("Start activity", systemImage: "stopwatch") }.buttonStyle(.pulseNested)
            }
            Button("Save") {}.buttonStyle(.pulseOutline())
            Button("Add sleep") {}.buttonStyle(.pulseOutlineWhite)
            Button("Save journal") {}.buttonStyle(.pulseFilledWhite)
            Button("Start activity") {}.buttonStyle(.pulseFilledBlue)
            PulseTextCTA(title: "Break down my recovery", tint: .ai) {}
            PulseTextCTA(title: "Explore plans", tint: .color(PulseTheme.Plan.exploreCTA)) {}
            PulsePlusButton {}
        }
    }

    // MARK: Charts

    private var week: [PulseChartDatum] {
        let values: [Double?] = [9.8, 13.2, 13.7, 13.8, 11.3, nil, 2.7]
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return values.enumerated().map { i, v in
            PulseChartDatum(id: "d\(i)", label: days[i], sublabel: "\(26 + i)", value: v, color: PulseTheme.strain,
                            valueLabel: v.map { String(format: "%.1f", $0) })
        }
    }

    private var charts: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Charts")
            PulseChartCard("Day Strain", accessory: .chevron) {
                PulseBarChart(data: week, yDomain: 0...21, highlightID: "d6")
            }
            PulseChartCard("Heart Rate Variability", accessory: .info) {
                PulseLineChart(data: week.map { PulseChartDatum(id: $0.id, label: $0.label, sublabel: $0.sublabel,
                                                                value: $0.value.map { $0 * 4 + 20 },
                                                                color: PulseTheme.recoveryBlue,
                                                                valueLabel: $0.value.map { "\(Int($0 * 4 + 20))" }) },
                               color: PulseTheme.recoveryBlue, typicalRange: 55...75, average: 62, highlightID: "d6")
            }
            PulseChartCard("HR Zones 1-3") {
                PulseStackedBarChart(columns: (0..<7).map { i in
                    PulseStackedBarChart.Column(id: "c\(i)", label: ["S", "M", "T", "W", "T", "F", "S"][i],
                                                segments: [
                                                    .init(id: "z1-\(i)", value: Double(20 + i * 3), color: PulseTheme.zone(1)),
                                                    .init(id: "z2-\(i)", value: Double(10 + i), color: PulseTheme.zone(2)),
                                                    .init(id: "z3-\(i)", value: Double(5 + i * 2), color: PulseTheme.zone(3)),
                                                ],
                                                totalLabel: "0:\(35 + i * 6)")
                }, highlightID: "c6")
            }
            PulseHatchedTrack().frame(height: 14)
        }
    }

    // MARK: Coach

    private var coach: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Coach")
            HStack(spacing: 16) {
                PulseCoachButton {}
                PulseCoachButton(size: PulseTheme.TabBarMetrics.floatingCoachSize) {}
                PulseCoachAnalyzingPill()
            }
            PulseCoachSummaryPill(summary: "Your sleep was strong because the basics lined up: **87% performance** with 7:41 asleep.") {}
            PulseTabBar(tabs: PulseTab.allCases, selection: .home, onSelect: { _ in })
        }
    }
}
#endif
