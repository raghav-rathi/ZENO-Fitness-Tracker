#if os(iOS)
import SwiftUI
import Charts

// MARK: - The Stress Monitor's day chart and the Health tab's stress sparkline (WHOOP_UI_SPEC §2.7, §3.22)

/// The day's stress over an explicit window: the line coloured by its own value along the stress scale,
/// sleep and activity periods as faint bands with a 3 pt cap on the 3.0 gridline and a 17 pt glyph above,
/// faint verticals at the two inner times, a dashed line at the window's end with a white dot at its foot,
/// y labels 0.0–3.0 on the left and four times under it, the last one white (completeness-critic/14, 15;
/// reviews/33 draws the dot white today too). On the Stress Monitor's page, the black zoom button inside the
/// plot's bottom-right corner narrows the window to its last six hours and back; a card (Home's STRESS
/// MONITOR, which opens the monitor) turns the zoom off and draws its gridlines in the card's tone.
///
/// The window is explicit, unlike `PulseStressChart`'s, so a rolling 24 h view keeps its span even when
/// the readings start late in it. Missing readings are gaps, never zero.
struct HealthStressDayChart: View {
    let points: [PulseTimeValue]
    var periods: [PulseChartPeriod] = []
    let window: ClosedRange<Date>
    /// Where the window ends with the dashed line and dot: now today, the last reading's end on a past day;
    /// nil for a past day with no reading (the window is then the calendar day, with no end line).
    var now: Date?
    /// The plot's height (completeness-critic/14: ≈157 pt of plot, ≈210 pt with the glyphs and the times).
    var height: CGFloat = 160
    /// Shown over the empty plot when there is no reading in the window.
    var emptyMessage: String = String(localized: "No stress readings for this day.")
    /// The zoom button and its VoiceOver action (off inside a card that is itself a link).
    var showsZoom = true
    /// The gridlines' and inner verticals' colour: the page's, or a card's.
    var grid: Color = PulseTheme.gridOnPage

    @State private var zoomed = false

    private static let zoomSpan: TimeInterval = 6 * 3600

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

    /// Four instants across the window: its start, its end, and between them the whole hours nearest its
    /// thirds ("11:02 PM · 7:00 AM · 3:00 PM · 10:49 PM", completeness-critic/14).
    private var ticks: [Date] {
        let span = shown.upperBound.timeIntervalSince(shown.lowerBound)
        let cal = Calendar.current
        let inner = [1.0, 2.0].map { third -> Date in
            let t = shown.lowerBound.addingTimeInterval(span * third / 3)
            guard span >= 3 * 3600, let hour = cal.dateInterval(of: .hour, for: t)?.start else { return t }
            return t.timeIntervalSince(hour) >= 1800 ? hour.addingTimeInterval(3600) : hour
        }
        return [shown.lowerBound] + inner + [shown.upperBound]
    }

    var body: some View {
        let plot = chart
            .frame(height: height + 22)
            .padding(.top, 22)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Stress through the day"))
            .accessibilityValue(summary)
        if showsZoom {
            plot.accessibilityAction(named: zoomed ? String(localized: "Show the whole window")
                                                   : String(localized: "Zoom to the last six hours")) {
                zoomed.toggle()
            }
        } else {
            plot
        }
    }

    private var chart: some View {
        Chart {
            ForEach(shownPeriods) { period in
                RectangleMark(xStart: .value("Start", period.start), xEnd: .value("End", period.end),
                              yStart: .value("Low", 0), yEnd: .value("High", 3))
                    .foregroundStyle(period.kind.color.opacity(0.10))
                // A 3 pt cap: 3 pt of the 0–3 axis is 9 / height of a unit.
                RectangleMark(xStart: .value("Start", period.start), xEnd: .value("End", period.end),
                              yStart: .value("Cap", 3.0 - 9.0 / Double(height)), yEnd: .value("Top", 3.0))
                    .foregroundStyle(period.kind.color)
                    .annotation(position: .top, spacing: 4) {
                        if let symbol = period.symbol {
                            Image(systemName: symbol)
                                .font(HealthGlyph.periodGlyph.font)
                                .foregroundStyle(PulseTheme.textPrimary)
                        }
                    }
            }
            ForEach(Array(ticks.dropFirst().dropLast().enumerated()), id: \.offset) { _, tick in
                RuleMark(x: .value("Tick", tick))
                    .foregroundStyle(grid)
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
                    .foregroundStyle(Color.white)
            }
        }
        .chartXScale(domain: shown)
        .chartYScale(domain: 0...3)
        .chartXAxis {
            // The start and end labels sit inside the plot's edges; the two inner ones centre on their hour.
            AxisMarks(values: ticks) { value in
                if let date = value.as(Date.self) {
                    let index = ticks.firstIndex(of: date) ?? 1
                    AxisValueLabel(anchor: index == 0 ? .topLeading : (index == 3 ? .topTrailing : .top),
                                   collisionResolution: .disabled) {
                        Text(PulseFormat.clock(date))
                            .font(index == 3 ? PulseType.numeral(12) : PulseType.font(.axis))
                            .foregroundStyle(index == 3 ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.0, 1.0, 2.0, 3.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(grid)
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
                    if showsZoom, hasReadings || zoomed,
                       window.upperBound.timeIntervalSince(window.lowerBound) > Self.zoomSpan + 60 {
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
                .healthGlyph(.zoom)
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

/// The Health tab's STRESS MONITOR sparkline: the day so far across today's whole span (midnight to now),
/// coloured by value, over faint gridlines at 0, 1, 2 and 3, with a dashed line at now and a white dot where
/// the line ends (reviews/r100: four lines 25 pt apart in its 74 pt; health-more-2026/03 frame 121;
/// whoop-site/11n). No axes.
struct HealthStressSparkline: View {
    let points: [PulseTimeValue]
    /// Today's start to the dashed line.
    let span: ClosedRange<Date>
    /// When the latest reading was read (the end of its hour window, now at most). The line runs on flat
    /// from that reading's point, which sits mid-window, to here, and ends in the dot; nil ends it on the
    /// point itself.
    var endAt: Date? = nil
    var height: CGFloat = 64

    /// The points in the span, the flat run to `endAt` appended, and the one the dot sits on.
    private var plotted: (points: [PulseTimeValue], last: PulseTimeValue?) {
        var pts = points.filter { span.contains($0.date) }
        guard let reading = pts.last(where: { $0.value != nil }) else { return (pts, nil) }
        guard pts.last?.date == reading.date, let endAt, span.contains(endAt), endAt > reading.date else {
            return (pts, reading)
        }
        let end = PulseTimeValue(date: min(endAt, span.upperBound), value: reading.value)
        pts.append(end)
        return (pts, end)
    }

    var body: some View {
        let (pts, last) = plotted
        let pairs: [(PulseTimeValue, PulseTimeValue)] = pts.count > 1 ? (1..<pts.count).compactMap { i in
            pts[i - 1].value != nil && pts[i].value != nil ? (pts[i - 1], pts[i]) : nil
        } : []
        Chart {
            ForEach([0.0, 1.0, 2.0, 3.0], id: \.self) { y in
                RuleMark(y: .value("Grid", y))
                    .foregroundStyle(PulseTheme.gridOnCard)
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            RuleMark(x: .value("Now", span.upperBound))
                .foregroundStyle(PulseTheme.textSecondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
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
        .chartXScale(domain: span)
        .chartYScale(domain: 0...3)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
#endif
