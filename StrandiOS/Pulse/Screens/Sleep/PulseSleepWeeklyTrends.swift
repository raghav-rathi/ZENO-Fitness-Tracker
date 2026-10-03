#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics

// MARK: - Weekly Trends (WHOOP_UI_SPEC §3.3 item 8, §2.7 "Weekly Trends card chart")
//
// Seven cards on the standard card fill, each "TITLE ›" opening its metric (`PulseSleepRoutes`: Trend View
// once rebuilt, else the classic page when it has data, else the classic Sleep screen), in WHOOP's order:
// SLEEP PERFORMANCE, HOURS VS. NEEDED (HOURS), HOURS VS. NEEDED (%), RESTORATIVE SLEEP (HOURS), SLEEP
// CONSISTENCY, TIME IN BED, SLEEP EFFICIENCY. Each plots the seven days ending on the night shown (the
// latest highlighted); a day without a night is a gap, never a zero. Every chart is `PulseWeeklyChart.height`
// tall, a ≈197 pt plot over its two-line day labels as the Recovery and Strain dives draw it (WHOOP's
// gridlines run 202 pt on deep-dives-2026/13).

struct PulseSleepWeeklyTrends: View {
    let week: [SleepWeekNight]
    /// The metrics whose classic page has data.
    var metricPages: Set<String> = []

    private var highlightID: String? { week.last?.id }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.stackGap) {
            card(String(localized: "Sleep performance"), metric: "sleep_performance") {
                PulseBarChart(data: percentData(\.performance), yDomain: 0...100, gridValues: [0, 25, 50, 75, 100],
                              highlightID: highlightID, height: PulseWeeklyChart.height)
                    .padding(.top, 10)
            }
            card(String(localized: "Hours vs. needed (hours)"), metric: "sleep_total_min", legend: AnyView(hoursNeedLegend)) {
                PulseSleepHoursNeedChart(week: week, highlightID: highlightID)
            }
            card(String(localized: "Hours vs. needed (%)"), metric: "hours_vs_needed_pct") {
                PulseBarChart(data: percentData(\.hoursPct), yDomain: 0...100, gridValues: [0, 25, 50, 75, 100],
                              highlightID: highlightID, height: PulseWeeklyChart.height)
                    .padding(.top, 10)
            }
            .id("pulse.trend-hours-pct")
            card(String(localized: "Restorative sleep (hours)"), metric: "restorative_min",
                 legend: AnyView(restorativeLegend)) {
                PulseSleepRestorativeChart(week: week, highlightID: highlightID)
                    .padding(.top, 10)
            }
            .id("pulse.trend-restorative")
            card(String(localized: "Sleep consistency"), metric: "sleep_consistency") {
                PulseBarChart(data: percentData(\.consistency), yDomain: 0...100, gridValues: [0, 25, 50, 75, 100],
                              highlightID: highlightID, height: PulseWeeklyChart.height)
                    .padding(.top, 10)
            }
            card(String(localized: "Time in bed"), metric: "in_bed_min") {
                PulseSleepTimeInBedChart(week: week, highlightID: highlightID)
            }
            .id("pulse.trend-time-in-bed")
            card(String(localized: "Sleep efficiency"), metric: "sleep_efficiency") {
                PulseLineChart(data: percentData(\.efficiency), color: PulseTheme.sleep, highlightID: highlightID,
                               showsArea: true, height: PulseWeeklyChart.height)
                    .padding(.top, 6)
            }
            .id("pulse.trend-efficiency")
        }
    }

    // MARK: Data

    private func percentData(_ key: KeyPath<SleepWeekNight, Double?>) -> [PulseChartDatum] {
        week.map { day in
            let v = day[keyPath: key]
            return PulseChartDatum(id: day.id, label: day.label, sublabel: day.sublabel, value: v,
                                   color: PulseTheme.sleep,
                                   valueLabel: v.map { "\(PulseDisplay.displayedPercent($0))%" })
        }
    }

    // MARK: Legends

    private var hoursNeedLegend: some View {
        HStack(spacing: 14) {
            legendRing(PulseTheme.sleep, String(localized: "Hours of sleep"))
            legendRing(PulseTheme.positive, String(localized: "Sleep needed"))
        }
    }

    private var restorativeLegend: some View {
        HStack(spacing: 14) {
            legendSquare(PulseTheme.Stage.deep, String(localized: "Deep sleep"))
            legendSquare(PulseTheme.Stage.rem, String(localized: "REM sleep"))
        }
    }

    private func legendRing(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            Circle().strokeBorder(color, lineWidth: 1.5).frame(width: 8, height: 8)
            Text(title).pulseText(.label).foregroundStyle(PulseTheme.textPrimary).lineLimit(1)
        }
    }

    private func legendSquare(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            SleepSwatch(color: color, size: 9)
            Text(title).pulseText(.label).foregroundStyle(PulseTheme.textPrimary).lineLimit(1)
        }
    }

    // MARK: Card

    /// A Weekly Trends card: the whole card opens its metric (`PulseSleepRoutes`), and VoiceOver names
    /// where.
    private func card<Content: View>(_ title: String, metric: String, legend: AnyView? = nil,
                                     @ViewBuilder content: () -> Content) -> some View {
        let chart = content()
        let route = PulseSleepRoutes.route(metric: metric, pagesWithData: metricPages)
        return PulseLink(route) {
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    PulseCardTitle(title, accessory: .trailingChevron)
                    if let legend {
                        legend
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .minimumScaleFactor(0.8)
                    }
                    chart
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(PulseSleepRoutes.hint(route))
    }

    /// A duration chart's top: whole two-hour steps, never under `floor` minutes (WHOOP's 0–6 h for
    /// restorative sleep, 0–12 h for hours and need; deep-dives-2026/07, 08, 13).
    static func durationTop(_ values: [Double], floor: Double) -> Double {
        max(floor, ((values.max() ?? 0) / 120).rounded(.up) * 120)
    }
}

// MARK: - The highlight column

/// The rounded column behind the newest day, spanning the plot and its x labels (§2.7).
private struct SleepChartHighlight: View {
    let proxy: ChartProxy
    let id: String?

    var body: some View {
        GeometryReader { geo in
            if let id, let anchor = proxy.plotFrame, let x = proxy.position(forX: id) {
                let plot = geo[anchor]
                RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                    .fill(PulseTheme.chartHighlight)
                    .frame(width: 29, height: geo.size.height)
                    .position(x: plot.minX + x, y: geo.size.height / 2)
            }
        }
    }
}

/// The two-line x label under a column ("Wed" over "5"), white for the newest day: the shared charts' own
/// label (`PulseChartAxis.xLabel`), so the cards drawn here and the shared bar and line cards print one face.
private func sleepXLabel(_ day: SleepWeekNight?, highlighted: Bool) -> some View {
    PulseChartAxis.xLabel(day.map { (label: $0.label, sublabel: Optional($0.sublabel)) }, highlighted: highlighted)
}

// MARK: - HOURS VS. NEEDED (HOURS): two lines

/// Hours of sleep (sleep blue) and sleep needed (teal), each a line with hollow markers; on each day the
/// higher series' label sits above its marker and the lower one's below (deep-dives-2026/07, 13).
struct PulseSleepHoursNeedChart: View {
    let week: [SleepWeekNight]
    let highlightID: String?
    var height: CGFloat = PulseWeeklyChart.height

    /// 0–12 h, as WHOOP fixes it (deep-dives-2026/07, 13), in two-hour steps past it.
    private var top: Double {
        PulseSleepWeeklyTrends.durationTop(week.flatMap { [$0.hoursMin, $0.needMin].compactMap { $0 } },
                                           floor: 12 * 60)
    }

    var body: some View {
        let byID = Dictionary(week.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        Chart {
            ForEach(week.filter { $0.hoursMin != nil }) { day in
                LineMark(x: .value("Day", day.id), y: .value("Hours", day.hoursMin ?? 0), series: .value("S", "hours"))
                    .foregroundStyle(PulseTheme.sleep.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("Day", day.id), y: .value("Hours", day.hoursMin ?? 0))
                    .symbol { marker(PulseTheme.sleep) }
                    .annotation(position: hoursOnTop(day) ? .top : .bottom, spacing: 3) {
                        label(day.hoursMin, color: PulseTheme.sleep)
                    }
            }
            ForEach(week.filter { $0.needMin != nil }) { day in
                LineMark(x: .value("Day", day.id), y: .value("Need", day.needMin ?? 0), series: .value("S", "need"))
                    .foregroundStyle(PulseTheme.positive.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("Day", day.id), y: .value("Need", day.needMin ?? 0))
                    .symbol { marker(PulseTheme.positive) }
                    .annotation(position: hoursOnTop(day) ? .bottom : .top, spacing: 3) {
                        label(day.needMin, color: PulseTheme.positive)
                    }
            }
        }
        .chartXScale(domain: week.map(\.id))
        .chartYScale(domain: 0...top)
        .chartYAxis {
            AxisMarks(position: .leading, values: PulseChartAxis.gridValues(0...top, count: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
            }
        }
        .chartXAxis {
            AxisMarks(values: week.map(\.id)) { value in
                AxisValueLabel(centered: true) {
                    let id = value.as(String.self)
                    sleepXLabel(id.flatMap { byID[$0] }, highlighted: id != nil && id == highlightID)
                }
            }
        }
        .chartBackground { proxy in SleepChartHighlight(proxy: proxy, id: highlightID) }
        .frame(height: height)
        .overlay {
            if week.allSatisfy({ $0.hoursMin == nil }) {
                Text(String(localized: "No data yet")).pulseText(.body).foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Hours of sleep and sleep needed, last 7 days"))
        .accessibilityValue(week.compactMap { day -> String? in
            guard let h = day.hoursMin else { return nil }
            let need = day.needMin.map { String(localized: "needed \(PulseFormat.hoursMinutes($0))") } ?? ""
            return "\(day.label) \(day.sublabel): \(PulseFormat.hoursMinutes(h)) \(need)"
        }.joined(separator: "; "))
    }

    /// Hours sits above need on the day (or alone).
    private func hoursOnTop(_ day: SleepWeekNight) -> Bool {
        guard let h = day.hoursMin, let n = day.needMin else { return false }
        return h >= n
    }

    private func marker(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .background(Circle().fill(PulseTheme.cardSolidMiddle))
            .frame(width: 9, height: 9)
    }

    @ViewBuilder
    private func label(_ minutes: Double?, color: Color) -> some View {
        if let minutes {
            Text(PulseFormat.hoursMinutes(minutes))
                .font(PulseType.font(.baseline))
                .foregroundStyle(color)
        }
    }
}

// MARK: - RESTORATIVE SLEEP (HOURS): stacked bars

/// REM at the bottom and deep (SWS) on top, a sliver of card between them, the night's total above in
/// white, on 0–6 h in two-hour steps (deep-dives-2026/08, 30). A day without a night is left out.
struct PulseSleepRestorativeChart: View {
    let week: [SleepWeekNight]
    let highlightID: String?
    var height: CGFloat = PulseWeeklyChart.height

    private var nights: [SleepWeekNight] { week.filter { $0.remMin != nil || $0.deepMin != nil } }

    private var top: Double {
        PulseSleepWeeklyTrends.durationTop(nights.map { ($0.remMin ?? 0) + ($0.deepMin ?? 0) }, floor: 6 * 60)
    }

    var body: some View {
        let byID = Dictionary(week.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        // The gap in minutes: the segment gap over the plot's height (the chart less its day labels).
        let gap = top / Double(max(height - 30, 1)) * Double(PulseTheme.SleepDive.segmentGap)
        Chart {
            ForEach(nights) { day in
                let rem = day.remMin ?? 0
                let deep = day.deepMin ?? 0
                if rem > 0 {
                    RectangleMark(x: .value("Day", day.id), yStart: .value("Start", 0),
                                  yEnd: .value("REM", max(0, rem - (deep > 0 ? gap : 0))), width: .fixed(14))
                        .foregroundStyle(PulseTheme.Stage.rem)
                        .cornerRadius(PulseTheme.SleepDive.rangeBarRadius)
                }
                RectangleMark(x: .value("Day", day.id), yStart: .value("REM", rem),
                              yEnd: .value("Total", rem + deep), width: .fixed(14))
                    .foregroundStyle(PulseTheme.Stage.deep)
                    .cornerRadius(PulseTheme.SleepDive.rangeBarRadius)
                    .annotation(position: .top, spacing: 4) {
                        Text(PulseFormat.hoursMinutes(rem + deep))
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
            }
        }
        .chartXScale(domain: week.map(\.id))
        .chartYScale(domain: 0...top)
        .chartYAxis {
            AxisMarks(position: .leading, values: Array(stride(from: 0.0, through: top, by: 120))) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
            }
        }
        .chartXAxis {
            AxisMarks(values: week.map(\.id)) { value in
                AxisValueLabel(centered: true) {
                    let id = value.as(String.self)
                    sleepXLabel(id.flatMap { byID[$0] }, highlighted: id != nil && id == highlightID)
                }
            }
        }
        .chartBackground { proxy in SleepChartHighlight(proxy: proxy, id: highlightID) }
        .frame(height: height)
        .overlay {
            if nights.isEmpty {
                Text(String(localized: "No data yet")).pulseText(.body).foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Restorative sleep, last 7 days"))
        .accessibilityValue(nights.map { day in
            "\(day.label) \(day.sublabel): \(PulseFormat.hoursMinutes((day.remMin ?? 0) + (day.deepMin ?? 0)))"
        }.joined(separator: "; "))
    }
}

// MARK: - TIME IN BED: floating bars

/// Bed → wake as a floating bar per night on an inverted clock (earlier at the top), the bedtime above it
/// and the wake time below, 12 h without AM / PM (deep-dives-2026/10, 19d).
struct PulseSleepTimeInBedChart: View {
    let week: [SleepWeekNight]
    let highlightID: String?
    var height: CGFloat = PulseWeeklyChart.height

    private var nights: [SleepWeekNight] { week.filter { $0.bed != nil && $0.wake != nil } }

    /// The nights' span with two hours either side, so the bedtime above the earliest bar and the wake
    /// time below the latest clear the plot's edges and the day labels (deep-dives-2026/10).
    private var domain: ClosedRange<Double> {
        let values: [Double] = nights.flatMap { night -> [Double] in [night.bed ?? 0, night.wake ?? 0] }
        let lo: Double = (values.min() ?? 600) - 120
        let hi: Double = (values.max() ?? 1_200) + 120
        return (-hi)...(-lo)
    }

    var body: some View {
        let byID = Dictionary(week.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        Chart {
            ForEach(nights) { day in
                RectangleMark(x: .value("Day", day.id), yStart: .value("Bed", -(day.bed ?? 0)),
                              yEnd: .value("Wake", -(day.wake ?? 0)), width: .fixed(14))
                    .foregroundStyle(PulseTheme.sleep)
                    .cornerRadius(PulseTheme.SleepDive.rangeBarRadius)
                    .annotation(position: .top, spacing: 3) {
                        Text(day.bedText ?? "").font(PulseType.font(.baseline)).foregroundStyle(PulseTheme.sleep)
                    }
                    .annotation(position: .bottom, spacing: 3) {
                        Text(day.wakeText ?? "").font(PulseType.font(.baseline)).foregroundStyle(PulseTheme.sleep)
                    }
            }
        }
        .chartXScale(domain: week.map(\.id))
        .chartYScale(domain: domain)
        .chartYAxis {
            AxisMarks(position: .leading, values: PulseChartAxis.gridValues(domain, count: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
            }
        }
        .chartXAxis {
            AxisMarks(values: week.map(\.id)) { value in
                AxisValueLabel(centered: true) {
                    let id = value.as(String.self)
                    sleepXLabel(id.flatMap { byID[$0] }, highlighted: id != nil && id == highlightID)
                }
            }
        }
        .chartBackground { proxy in SleepChartHighlight(proxy: proxy, id: highlightID) }
        .frame(height: height)
        .overlay {
            if nights.isEmpty {
                Text(String(localized: "No data yet")).pulseText(.body).foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Time in bed, last 7 days"))
        .accessibilityValue(nights.map { "\($0.label) \($0.sublabel): \($0.bedText ?? "") – \($0.wakeText ?? "")" }
            .joined(separator: "; "))
    }
}
#endif
