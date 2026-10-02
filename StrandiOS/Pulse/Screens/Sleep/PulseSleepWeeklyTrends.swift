#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics

// MARK: - Weekly Trends (WHOOP_UI_SPEC §3.3 item 8, §2.7 "Weekly Trends card chart")
//
// Seven cards on the standard card fill, each "TITLE ›" opening Trend View for its metric, in WHOOP's order:
// SLEEP PERFORMANCE, HOURS VS. NEEDED (HOURS), HOURS VS. NEEDED (%), RESTORATIVE SLEEP (HOURS), SLEEP
// CONSISTENCY, TIME IN BED, SLEEP EFFICIENCY. Each plots the seven days ending on the night shown (the
// latest highlighted); a day without a night is a gap, never a zero.

struct PulseSleepWeeklyTrends: View {
    let week: [SleepWeekNight]

    private var highlightID: String? { week.last?.id }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.stackGap) {
            card(String(localized: "Sleep performance"), metric: "sleep_performance") {
                PulseBarChart(data: percentData(\.performance), yDomain: 0...100, gridValues: [0, 25, 50, 75, 100],
                              highlightID: highlightID)
                    .padding(.top, 10)
            }
            card(String(localized: "Hours vs. needed (hours)"), metric: "sleep_total_min", legend: AnyView(hoursNeedLegend)) {
                PulseSleepHoursNeedChart(week: week, highlightID: highlightID)
            }
            card(String(localized: "Hours vs. needed (%)"), metric: "hours_vs_needed_pct") {
                PulseBarChart(data: percentData(\.hoursPct), yDomain: 0...100, gridValues: [0, 25, 50, 75, 100],
                              highlightID: highlightID)
                    .padding(.top, 10)
            }
            .id("pulse.trend-hours-pct")
            card(String(localized: "Restorative sleep (hours)"), metric: "restorative_min",
                 legend: AnyView(restorativeLegend)) {
                PulseStackedBarChart(columns: restorativeColumns, highlightID: highlightID)
                    .padding(.top, 10)
            }
            .id("pulse.trend-restorative")
            card(String(localized: "Sleep consistency"), metric: "sleep_consistency") {
                PulseBarChart(data: percentData(\.consistency), yDomain: 0...100, gridValues: [0, 25, 50, 75, 100],
                              highlightID: highlightID)
                    .padding(.top, 10)
            }
            card(String(localized: "Time in bed"), metric: "in_bed_min") {
                PulseSleepTimeInBedChart(week: week, highlightID: highlightID)
            }
            .id("pulse.trend-time-in-bed")
            card(String(localized: "Sleep efficiency"), metric: "sleep_efficiency") {
                PulseLineChart(data: percentData(\.efficiency), color: PulseTheme.sleep, highlightID: highlightID,
                               showsArea: true)
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

    private var restorativeColumns: [PulseStackedBarChart.Column] {
        week.map { day in
            let rem = day.remMin
            let deep = day.deepMin
            let has = rem != nil || deep != nil
            return PulseStackedBarChart.Column(
                id: day.id, label: day.label, sublabel: day.sublabel,
                segments: has ? [
                    .init(id: "\(day.id)-rem", value: rem ?? 0, color: PulseTheme.Stage.rem),
                    .init(id: "\(day.id)-deep", value: deep ?? 0, color: PulseTheme.Stage.deep),
                ] : [],
                totalLabel: has ? PulseFormat.hoursMinutes((rem ?? 0) + (deep ?? 0)) : nil)
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

    /// A Weekly Trends card: the whole card opens Trend View for `metric` (the classic metric detail until
    /// the trends group's Trend View lands, through `forExistingEntryPoint`).
    private func card<Content: View>(_ title: String, metric: String, legend: AnyView? = nil,
                                     @ViewBuilder content: () -> Content) -> some View {
        let chart = content()
        return PulseLink(PulseRoute.trendView(metric: metric).forExistingEntryPoint) {
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
        .accessibilityHint(String(localized: "Opens Trend View"))
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
                RoundedRectangle(cornerRadius: 6, style: .circular)
                    .fill(PulseTheme.chartHighlight)
                    .frame(width: 29, height: geo.size.height)
                    .position(x: plot.minX + x, y: geo.size.height / 2)
            }
        }
    }
}

/// The two-line x label under a column ("Wed" over "5"), white for the newest day.
private func sleepXLabel(_ day: SleepWeekNight?, highlighted: Bool) -> some View {
    VStack(spacing: 1) {
        Text(day?.label ?? "")
        Text(day?.sublabel ?? "")
    }
    .font(PulseType.font(.axis))
    .foregroundStyle(highlighted ? PulseTheme.textPrimary : PulseTheme.textTertiary)
}

// MARK: - HOURS VS. NEEDED (HOURS): two lines

/// Hours of sleep (sleep blue) and sleep needed (teal), each a line with hollow markers; on each day the
/// higher series' label sits above its marker and the lower one's below (deep-dives-2026/07, 13).
struct PulseSleepHoursNeedChart: View {
    let week: [SleepWeekNight]
    let highlightID: String?
    var height: CGFloat = 197

    private var top: Double {
        let values = week.flatMap { [$0.hoursMin, $0.needMin].compactMap { $0 } }
        return max((values.max() ?? 480) * 1.18, 60)
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
                .font(PulseType.numeral(13))
                .foregroundStyle(color)
        }
    }
}

// MARK: - TIME IN BED: floating bars

/// Bed → wake as a floating bar per night on an inverted clock (earlier at the top), the bedtime above it
/// and the wake time below, 12 h without AM / PM (deep-dives-2026/10, 19d).
struct PulseSleepTimeInBedChart: View {
    let week: [SleepWeekNight]
    let highlightID: String?
    var height: CGFloat = 197

    private var nights: [SleepWeekNight] { week.filter { $0.bed != nil && $0.wake != nil } }

    private var domain: ClosedRange<Double> {
        let values: [Double] = nights.flatMap { night -> [Double] in [night.bed ?? 0, night.wake ?? 0] }
        let lo: Double = (values.min() ?? 600) - 70
        let hi: Double = (values.max() ?? 1_200) + 70
        return (-hi)...(-lo)
    }

    var body: some View {
        let byID = Dictionary(week.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        Chart {
            ForEach(nights) { day in
                RectangleMark(x: .value("Day", day.id), yStart: .value("Bed", -(day.bed ?? 0)),
                              yEnd: .value("Wake", -(day.wake ?? 0)), width: .fixed(14))
                    .foregroundStyle(PulseTheme.sleep)
                    .cornerRadius(3)
                    .annotation(position: .top, spacing: 3) {
                        Text(day.bedText ?? "").font(PulseType.numeral(13)).foregroundStyle(PulseTheme.sleep)
                    }
                    .annotation(position: .bottom, spacing: 3) {
                        Text(day.wakeText ?? "").font(PulseType.numeral(13)).foregroundStyle(PulseTheme.sleep)
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
