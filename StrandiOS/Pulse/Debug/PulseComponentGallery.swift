#if os(iOS) && DEBUG
import SwiftUI

/// DEBUG `--pulse-gallery`: every shared component on one scrolling page with sample data, so a change to
/// Theme/ or Components/ can be checked at a glance and the next wave can see what exists. Not in Release.
struct PulseComponentGallery: View {
    @State private var range: PulseRange = .week
    @State private var tab = "STATUS"
    @State private var toggle = true
    @State private var wheel = 7

    var body: some View {
        NavigationStack {
            PulseScreenScaffold(title: "Component gallery", spacing: 24) {
                // `--pulse-scroll gallery-<section>` jumps to a section.
                dials.id("pulse.gallery-dials")
                header.id("pulse.gallery-header")
                surfaces.id("pulse.gallery-cards")
                headers.id("pulse.gallery-headers")
                rows.id("pulse.gallery-rows")
                trendsAndStatus.id("pulse.gallery-status")
                banners.id("pulse.gallery-banners")
                featureCards.id("pulse.gallery-feature")
                callout.id("pulse.gallery-callout")
                controls.id("pulse.gallery-controls")
                buttons.id("pulse.gallery-buttons")
                charts.id("pulse.gallery-charts")
                dayCharts.id("pulse.gallery-daycharts")
                overlays.id("pulse.gallery-overlays")
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
            // Below the range the band floats apart from the arc; the tick sits at the midpoint.
            PulseDialColumns(contents: [
                .percent(label: "Sleep", percent: 81, color: PulseTheme.sleep),
                .percent(label: "Recovery", percent: 51, color: PulseTheme.recoveryMid),
                .strain(label: "Strain", value: 4.3, optimalRange: 8.3...12.3, target: 10.3),
            ])
            PulseDialColumns(contents: [
                // Through the model's mapping, exactly as Home draws a calibrating Recovery.
                PulseDialData(score: .recovery, value: nil, state: .calibrating(nights: 2, of: 4)).dialContent(),
                .strain(label: "Strain", value: 0.2, optimalRange: 9.1...13.1, target: 11.1),
                .strain(label: "Strain", value: 16.8, optimalRange: 14...18, target: 16),
            ])
            title("Deep-dive ring · 260 / 15")
            PulseHeroRing(content: .percent(label: "Sleep performance", percent: 100, color: PulseTheme.sleep),
                          accessoryAccessibility: "Optimal") {
                PulseMiniSegments(active: 2)
            }
            .frame(maxWidth: .infinity)
            PulseHeroRing(content: .strain(label: "Strain", value: 20.7, optimalRange: 14...18, target: 16))
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
                PulseStrapVibrateGlyph().foregroundStyle(PulseTheme.textSecondary)
            }
        }
    }

    // MARK: Header pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Header · avatar, streak, pager")
            HStack(spacing: 16) {
                ZStack(alignment: .leading) {
                    PulseStreakPill(days: 105).padding(.leading, PulseTheme.Header.avatar / 2)
                    PulseAvatar(imageData: nil, name: nil)
                        .background(Circle().fill(PulseTheme.pageTop).padding(-1.5))
                }
                PulseAvatar(imageData: nil, name: "Iris Wong")
                PulseStreakPill(days: 372)
                PulseStreakPill(days: 1607)
            }
            HStack {
                Spacer()
                PulseDayPager(title: "Today", canGoBack: true, canGoForward: false, onBack: {}, onForward: {}, onTitleTap: {})
                Spacer()
            }
            title("Navigation bar")
            PulseNavBar(title: "Today", leading: .back, trailing: .info {}, onLeading: {})
                .padding(.horizontal, -16)
            PulseNavBar(title: nil, titlePager: PulseNavTitlePager(title: "Wed, Sep 30", canGoBack: true,
                                                                   canGoForward: true, onBack: {}, onForward: {}),
                        leading: .back,
                        trailing: .achievement(symbol: "hexagon.fill", tint: PulseTheme.sleep, count: 796,
                                               accessibilityLabel: "Restful Nights: 796 Nights of 85%+ Sleep Performance",
                                               action: {}),
                        onLeading: {})
                .padding(.horizontal, -16)
        }
    }

    // MARK: Feature cards

    private var featureCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Monitor tiles")
            HStack(alignment: .top, spacing: 12) {
                PulseMonitorTile(title: "Health Monitor",
                                 status: .init(badge: .check, tint: .teal, word: "Within range",
                                               wordColor: PulseTheme.positive, detail: "5/5 Metrics"))
                PulseMonitorTile(title: "Stress Monitor",
                                 status: .init(badge: .value("1.0"), tint: .teal, word: "Medium",
                                               wordColor: PulseTheme.Stress.medium, detail: "9:14 PM"))
            }
            .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 12) {
                PulseMonitorTile(title: "Health Monitor",
                                 status: .init(badge: .alert, tint: .orange, word: "Out of range",
                                               wordColor: PulseTheme.negative, detail: "Skin temperature"))
                PulseMonitorTile(title: "Stress Monitor", status: .pending)
            }
            .fixedSize(horizontal: false, vertical: true)
            title("Coach pill and Ask row")
            PulseCoachPill(kind: .morning, title: "Your Daily Outlook") {}
            PulseCoachPill(kind: .evening, title: "Your Day In Review") {}
            PulseCoachPill(kind: .morning, title: "Your Daily Outlook", isRead: true) {}
            PulseAskRow {}
            title("Insight card")
            PulseInsightCard(text: "You've worked extra hard today and have exceeded a balanced level of Strain.",
                             cta: "Break down my strain") {}
            title("Zone rows")
            PulseZoneRowCard(zone: 4, range: "162-171 BPM", share: 0.22, duration: "0:12:48", typical: 0.1...0.3)
            PulseZoneRowCard(zone: 5, range: "172+ BPM", share: 0, duration: "0:00:00")
            title("Impact bars")
            PulseImpactBar(fraction: 0.6, effect: .helps, valueText: "+8%")
            PulseImpactBar(fraction: -0.35, effect: .hurts, valueText: "-3%")
            PulseImpactBar(fraction: 0.15, effect: .notSignificant, valueText: "+2%", large: true)
            title("Day circles and goal rings")
            PulseCard {
                PulseDayCircleRow(days: [
                    .init(id: "1", label: "Thu", state: .logged), .init(id: "2", label: "Fri", state: .logged),
                    .init(id: "3", label: "Sat", state: .notLogged), .init(id: "4", label: "Sun", state: .logged),
                    .init(id: "5", label: "Mon", state: .notLogged), .init(id: "6", label: "Tue", state: .logged),
                    .init(id: "7", label: "Wed", state: .pending, isCurrent: true),
                ])
            }
            PulseCard {
                PulseDayCircleRow(days: [
                    .init(id: "1", label: "Mon", state: .done), .init(id: "2", label: "Tue", state: .rest),
                    .init(id: "3", label: "Wed", state: .done, isCurrent: true), .init(id: "4", label: "Thu", state: .future),
                    .init(id: "5", label: "Fri", state: .future), .init(id: "6", label: "Sat", state: .future),
                    .init(id: "7", label: "Sun", state: .future),
                ])
            }
            HStack(spacing: 16) {
                PulseGoalRing(kind: .count(done: 5, target: 7))
                PulseGoalRing(kind: .count(done: 4, target: 4))
                PulseGoalRing(kind: .value(text: "0:27", fraction: 0.6))
                PulseGoalRing(kind: .value(text: "269.4", fraction: 1))
            }
            title("Skeleton")
            VStack(spacing: 12) {
                PulseSkeletonBlock(height: 88)
                HStack(spacing: 12) {
                    PulseSkeletonBlock(height: 48)
                    PulseSkeletonBlock(height: 48)
                }
            }
        }
    }

    // MARK: Day charts

    private var dayCharts: some View {
        let start = Calendar.current.startOfDay(for: Date())
        let hr = (0..<60).map { i -> PulseTimeValue in
            let t = start.addingTimeInterval(TimeInterval(7 * 3600 + i * 60))
            let v = i == 30 ? nil : 110 + 40 * sin(Double(i) / 9)
            return PulseTimeValue(date: t, value: v)
        }
        let stress = (0..<24).map { i -> PulseTimeValue in
            PulseTimeValue(date: start.addingTimeInterval(TimeInterval(i * 3600 + 1800)),
                           value: i == 6 ? nil : 1.2 + 0.9 * sin(Double(i) / 3.2))
        }
        let week = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].enumerated().map { i, label in
            PulseStrainRecoveryChart.Day(id: "d\(i)", label: label, sublabel: "\(26 + i)",
                                         strain: [4.0, 13.2, 13.7, 13.8, 11.3, nil, 2.7][i],
                                         recovery: [85, 82, 76, 48, 25, nil, 24][i])
        }
        return VStack(alignment: .leading, spacing: 12) {
            title("Heart-rate area")
            PulseCard {
                PulseHRAreaChart(points: hr, window: hr[5].date...hr[54].date, color: PulseTheme.strain,
                                 startLabel: "7:05 AM", endLabel: "7:54 AM", startSymbol: "play.fill",
                                 endSymbol: "stop.fill")
            }
            title("Stress · 24 h")
            PulseCard {
                PulseStressChart(points: stress,
                                 periods: [PulseChartPeriod(id: "s", start: start, end: start.addingTimeInterval(7 * 3600),
                                                            kind: .sleep, symbol: "moon.fill"),
                                           PulseChartPeriod(id: "a", start: start.addingTimeInterval(17.5 * 3600),
                                                            end: start.addingTimeInterval(18.3 * 3600),
                                                            kind: .activity, symbol: "figure.run")],
                                 now: start.addingTimeInterval(23.5 * 3600),
                                 xLabels: ["12:00 AM", "8:00 AM", "4:00 PM", "11:30 PM"])
            }
            title("Strain & Recovery")
            PulseChartCard("Strain & Recovery", accessory: .info) {
                PulseStrainRecoveryChart(days: week, highlightID: "d6")
            }
        }
    }

    // MARK: Overlays (drawn inline here)

    private var overlays: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("Action menu rows")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(PulseActionMenuItem.allCases) { item in
                    PulseActionMenuRowLabel(title: item.title, symbol: item.symbol)
                }
            }
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.menu, style: .continuous)
                .fill(LinearGradient(colors: [PulseTheme.menuTop, PulseTheme.menuBottom], startPoint: .top, endPoint: .bottom)))
            HStack(spacing: 16) {
                PulsePlusSquare()
                PulsePlusSquare(isClose: true)
            }
            title("Dialog card")
            PulseDialogCard(title: "Overlapping activities",
                            message: "This activity overlaps another one. Edit the times and try again.",
                            primaryTitle: "Got it", primary: {}, secondaryTitle: "Try again", secondary: {},
                            onClose: {})
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            title("Error page")
            PulseErrorPage(message: "Something went wrong. Check your strap and try again.", onRetry: {}, onClose: {})
                .frame(height: 420)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            title("Wheel picker sheet")
            PulseWheelPickerSheet(title: "Days per week", options: Array(1...7), selection: $wheel,
                                  label: { "\($0) days" }, onConfirm: {}, onCancel: {})
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 20))
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
            PulseButtonRow {
                Button {} label: { Label("Add activity", systemImage: "plus") }.buttonStyle(.pulseNested)
                Button {} label: { Label("Start activity", systemImage: "stopwatch") }.buttonStyle(.pulseNested)
            }
            Button {} label: { Label("Behavior insights", systemImage: "lightbulb") }
                .buttonStyle(.pulseNested(fill: PulseTheme.Journal.insightsButton))
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
