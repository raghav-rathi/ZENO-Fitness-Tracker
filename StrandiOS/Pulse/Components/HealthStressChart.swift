#if os(iOS)
import SwiftUI
import Charts

// MARK: - The Stress Monitor's day chart and the Health tab's stress sparkline (WHOOP_UI_SPEC §2.7, §3.22)

/// The day's stress on the page (no card), over an explicit window: the line coloured by its own value
/// along the stress scale, sleep and activity periods as faint bands with a 3 pt cap on the 3.0 gridline
/// and a glyph above, faint verticals at the two inner times, a dashed now-line ending in a dot in the
/// current level's colour, y labels 0.0–3.0 on the left and four times under it, the last one white
/// (completeness-critic/14, 15). The black zoom button inside the plot's bottom-right corner narrows the
/// window to its last six hours and back.
///
/// The window is explicit, unlike `PulseStressChart`'s, so a rolling 24 h view keeps its span even when
/// the readings start late in it. Missing readings are gaps, never zero.
struct HealthStressDayChart: View {
    let points: [PulseTimeValue]
    var periods: [PulseChartPeriod] = []
    let window: ClosedRange<Date>
    /// Today's "now"; nil on a past day (the window's end is then the day's end, with no now-line).
    var now: Date?
    /// The level the gauge shows, which colours the now-line's dot.
    var currentLevel: Double?
    var height: CGFloat = 230
    /// Shown over the empty plot when there is no reading in the window.
    var emptyMessage: String = String(localized: "No stress readings for this day.")

    @State private var zoomed = false

    private static let zoomSpan: TimeInterval = 6 * 3600
    private static let yAxisWidth: CGFloat = 30

    private var shown: ClosedRange<Date> {
        guard zoomed else { return window }
        let end = window.upperBound
        return max(window.lowerBound, end.addingTimeInterval(-Self.zoomSpan))...end
    }

    private var shownPoints: [PulseTimeValue] {
        points.filter { shown.contains($0.date) }
    }

    private var shownPeriods: [PulseChartPeriod] {
        periods.compactMap { p in
            let start = max(p.start, shown.lowerBound)
            let end = min(p.end, shown.upperBound)
            guard end > start else { return nil }
            return PulseChartPeriod(id: p.id, start: start, end: end, kind: p.kind, symbol: p.symbol)
        }
    }

    private var hasReadings: Bool { shownPoints.contains { $0.value != nil } }

    /// Four instants across the window: its start, two inner thirds and its end.
    private var ticks: [Date] {
        let span = shown.upperBound.timeIntervalSince(shown.lowerBound)
        return (0...3).map { shown.lowerBound.addingTimeInterval(span * Double($0) / 3) }
    }

    var body: some View {
        VStack(spacing: 8) {
            chart
                .frame(height: height)
                .padding(.top, 22)
            HStack(spacing: 4) {
                ForEach(Array(ticks.enumerated()), id: \.offset) { index, date in
                    Text(PulseFormat.clock(date))
                        .font(index == 3 ? PulseType.numeral(12) : PulseType.font(.axis))
                        .foregroundStyle(index == 3 ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if index < 3 { Spacer(minLength: 2) }
                }
            }
            .padding(.leading, Self.yAxisWidth - 8)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Stress through the day"))
        .accessibilityValue(summary)
        .accessibilityAction(named: zoomed ? String(localized: "Show the whole window")
                                           : String(localized: "Zoom to the last six hours")) {
            zoomed.toggle()
        }
    }

    private var chart: some View {
        Chart {
            ForEach(shownPeriods) { period in
                RectangleMark(xStart: .value("Start", period.start), xEnd: .value("End", period.end),
                              yStart: .value("Low", 0), yEnd: .value("High", 3))
                    .foregroundStyle(period.kind.color.opacity(0.10))
                RectangleMark(xStart: .value("Start", period.start), xEnd: .value("End", period.end),
                              yStart: .value("Cap", 2.96), yEnd: .value("Top", 3.0))
                    .foregroundStyle(period.kind.color)
                    .annotation(position: .top, spacing: 4) {
                        if let symbol = period.symbol {
                            Image(systemName: symbol)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(PulseTheme.textPrimary)
                        }
                    }
            }
            ForEach(Array(ticks.dropFirst().dropLast().enumerated()), id: \.offset) { _, tick in
                RuleMark(x: .value("Tick", tick))
                    .foregroundStyle(PulseTheme.gridOnPage)
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            // One short segment per pair of neighbouring readings, each in its own value's colour.
            ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                ForEach([pair.0, pair.1], id: \.date) { p in
                    LineMark(x: .value("Time", p.date), y: .value("Stress", p.value ?? 0),
                             series: .value("Segment", index))
                        .foregroundStyle(PulseTheme.Stress.color(for: ((pair.0.value ?? 0) + (pair.1.value ?? 0)) / 2))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            ForEach(singles) { p in
                PointMark(x: .value("Time", p.date), y: .value("Stress", p.value ?? 0))
                    .symbolSize(14)
                    .foregroundStyle(PulseTheme.Stress.color(for: p.value ?? 0))
            }
            if let now, shown.contains(now) {
                RuleMark(x: .value("Now", now))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(x: .value("Now", now), y: .value("Foot", 0))
                    .symbolSize(30)
                    .foregroundStyle(currentLevel.map { PulseTheme.Stress.Level(value: $0).color } ?? PulseTheme.textPrimary)
            }
        }
        .chartXScale(domain: shown)
        .chartYScale(domain: 0...3)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.0, 1.0, 2.0, 3.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnPage)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(PulseFormat.oneDecimal(v))
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let anchor = proxy.plotFrame {
                    let plot = geo[anchor]
                    if !hasReadings {
                        Text(emptyMessage)
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(width: plot.width - 24)
                            .position(x: plot.midX, y: plot.midY)
                    }
                    if window.upperBound.timeIntervalSince(window.lowerBound) > Self.zoomSpan + 60 {
                        zoomButton
                            .position(x: plot.maxX - 24, y: plot.maxY - 24)
                    }
                }
            }
        }
    }

    private var zoomButton: some View {
        Button {
            zoomed.toggle()
        } label: {
            Image(systemName: zoomed ? "minus.magnifyingglass" : "plus.magnifyingglass")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    .fill(HealthPalette.zoomButton))
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(zoomed ? String(localized: "Show the whole window")
                                   : String(localized: "Zoom to the last six hours"))
    }

    /// Neighbouring readings with no gap between them.
    private var pairs: [(PulseTimeValue, PulseTimeValue)] {
        let pts = shownPoints
        guard pts.count > 1 else { return [] }
        return (1..<pts.count).compactMap { i in
            pts[i - 1].value != nil && pts[i].value != nil ? (pts[i - 1], pts[i]) : nil
        }
    }

    /// Readings with no neighbour, drawn as dots so a lone half hour still shows.
    private var singles: [PulseTimeValue] {
        let pts = shownPoints
        return pts.indices.compactMap { i in
            guard pts[i].value != nil else { return nil }
            let before = i > 0 && pts[i - 1].value != nil
            let after = i + 1 < pts.count && pts[i + 1].value != nil
            return before || after ? nil : pts[i]
        }
    }

    private var summary: String {
        let values = shownPoints.compactMap(\.value)
        guard let last = values.last else { return emptyMessage }
        return String(localized: "Latest \(PulseFormat.oneDecimal(last)) of 3, peak \(PulseFormat.oneDecimal(values.max() ?? last))")
    }
}

/// The Health tab's STRESS MONITOR sparkline: the day so far, coloured by value, with a white dot on the
/// latest reading (health-more-2026/03 frame 121). No axes.
struct HealthStressSparkline: View {
    let points: [PulseTimeValue]
    var height: CGFloat = 64

    var body: some View {
        let pts = points
        let pairs: [(PulseTimeValue, PulseTimeValue)] = pts.count > 1 ? (1..<pts.count).compactMap { i in
            pts[i - 1].value != nil && pts[i].value != nil ? (pts[i - 1], pts[i]) : nil
        } : []
        let last = pts.last { $0.value != nil }
        Chart {
            ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                ForEach([pair.0, pair.1], id: \.date) { p in
                    LineMark(x: .value("Time", p.date), y: .value("Stress", p.value ?? 0),
                             series: .value("Segment", index))
                        .foregroundStyle(PulseTheme.Stress.color(for: ((pair.0.value ?? 0) + (pair.1.value ?? 0)) / 2))
                        .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                }
            }
            if let last {
                PointMark(x: .value("Time", last.date), y: .value("Stress", last.value ?? 0))
                    .symbolSize(40)
                    .foregroundStyle(Color.white)
            }
        }
        .chartYScale(domain: 0...3)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
#endif
