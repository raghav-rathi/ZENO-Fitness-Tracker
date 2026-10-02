#if os(iOS)
import SwiftUI
import Charts

// MARK: - Chart primitives (WHOOP_UI_SPEC §2.7, DR §7)
//
// Swift Charts with the spec's look: horizontal gridlines only (white 5% on a card), axis labels 11 pt
// Bold condensed at 50%, a rounded "today" column behind the current x (spanning the plot AND its x
// labels), value labels above bars in the series colour, and missing data SKIPPED, never drawn as zero.
//
// The x axis is categorical: each datum's `id` is unique (a day key works) and its two-line label is
// passed in already formatted. Day keys are formatted at UTC by the caller (`PulseFormat.dayLabel`),
// so a chart never re-derives a date in the device zone.

/// One value on a categorical axis.
struct PulseChartDatum: Identifiable, Equatable {
    /// Unique x key, e.g. a day key "2026-10-01".
    let id: String
    /// The x label's first line ("Wed").
    let label: String
    /// The x label's second line ("5"), optional.
    var sublabel: String?
    /// The value, or nil for a missing day (skipped).
    let value: Double?
    /// The bar's or point's colour (series colour, or by zone for Recovery).
    var color: Color = PulseTheme.strain
    /// Printed above the bar or point ("64%", "13.2", "7:41").
    var valueLabel: String?

    init(id: String, label: String, sublabel: String? = nil, value: Double?, color: Color = PulseTheme.strain,
         valueLabel: String? = nil) {
        self.id = id
        self.label = label
        self.sublabel = sublabel
        self.value = value
        self.color = color
        self.valueLabel = valueLabel
    }
}

/// A chart in its card: UPPERCASE title at the top-left, an optional ⓘ or "›" at the right.
struct PulseChartCard<Content: View>: View {
    let title: String
    var accessory: PulseCardTitle.Accessory = .none
    var style: PulseCardStyle = .standard
    @ViewBuilder var content: () -> Content

    init(_ title: String, accessory: PulseCardTitle.Accessory = .none, style: PulseCardStyle = .standard,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.accessory = accessory
        self.style = style
        self.content = content
    }

    var body: some View {
        PulseCard(style) {
            VStack(alignment: .leading, spacing: 16) {
                PulseCardTitle(title, accessory: accessory)
                content()
            }
        }
    }
}

/// Shared pieces of the chart look.
enum PulseChartAxis {
    /// Evenly spaced gridline values across `domain` (5 lines including the baseline by default).
    static func gridValues(_ domain: ClosedRange<Double>, count: Int = 5) -> [Double] {
        guard count > 1, domain.upperBound > domain.lowerBound else { return [domain.lowerBound] }
        let step = (domain.upperBound - domain.lowerBound) / Double(count - 1)
        return (0..<count).map { domain.lowerBound + Double($0) * step }
    }

    /// A domain from zero to just above the largest value, so value labels fit above the bars.
    static func zeroBased(_ values: [Double], headroom: Double = 1.18) -> ClosedRange<Double> {
        let top = values.max() ?? 1
        return 0...max(top * headroom, 0.0001)
    }

    /// A padded min…max domain for dynamic ranges (heart rate, HRV); never starts at zero.
    static func dynamic(_ values: [Double], padding: Double = 0.15) -> ClosedRange<Double> {
        guard let lo = values.min(), let hi = values.max() else { return 0...1 }
        let span = max(hi - lo, abs(hi) * 0.1, 1)
        return (lo - span * padding)...(hi + span * padding * 1.6)
    }

    /// The two-line x label, white for the highlighted column and 50% otherwise.
    @ViewBuilder
    static func xLabel(_ datum: (label: String, sublabel: String?)?, highlighted: Bool) -> some View {
        if let datum {
            VStack(spacing: 1) {
                Text(datum.label)
                if let sub = datum.sublabel { Text(sub) }
            }
            .font(PulseType.font(.axis))
            .foregroundStyle(highlighted ? PulseTheme.textPrimary : PulseTheme.textTertiary)
        }
    }
}

/// The rounded column behind the highlighted x, spanning the plot and the x labels.
private struct PulseChartHighlight: View {
    let proxy: ChartProxy
    let id: String?
    var width: CGFloat = 29

    var body: some View {
        GeometryReader { geo in
            if let id, let anchor = proxy.plotFrame, let x = proxy.position(forX: id) {
                let plot = geo[anchor]
                RoundedRectangle(cornerRadius: 6, style: .circular)
                    .fill(PulseTheme.chartHighlight)
                    .frame(width: width, height: geo.size.height)
                    .position(x: plot.minX + x, y: geo.size.height / 2)
            }
        }
    }
}

// MARK: - Bars

/// Rounded-top bars, one per category, each in its own colour (series colour, or by zone/band), with an
/// optional value label above. Weekly Trends cards use the defaults: 5 gridlines, no y labels, 14 pt
/// bars and the last day highlighted.
///
///     PulseBarChart(data: week, highlightID: week.last?.id)
struct PulseBarChart: View {
    let data: [PulseChartDatum]
    var yDomain: ClosedRange<Double>?
    /// Explicit gridline values (strain 0/7/14/21, recovery 0/33/66/100); otherwise evenly spaced.
    var gridValues: [Double]?
    var gridlineCount: Int = 5
    var showsYAxisLabels = false
    var highlightID: String?
    var barWidth: CGFloat = 14
    var height: CGFloat = 197
    /// Shown centred when no datum has a value.
    var emptyMessage: String = String(localized: "No data yet")

    init(data: [PulseChartDatum], yDomain: ClosedRange<Double>? = nil, gridValues: [Double]? = nil,
         gridlineCount: Int = 5, showsYAxisLabels: Bool = false, highlightID: String? = nil,
         barWidth: CGFloat = 14, height: CGFloat = 197, emptyMessage: String = String(localized: "No data yet")) {
        self.data = data
        self.yDomain = yDomain
        self.gridValues = gridValues
        self.gridlineCount = gridlineCount
        self.showsYAxisLabels = showsYAxisLabels
        self.highlightID = highlightID
        self.barWidth = barWidth
        self.height = height
        self.emptyMessage = emptyMessage
    }

    private var plotted: [(id: String, value: Double, color: Color, label: String?)] {
        data.compactMap { d in d.value.map { (d.id, $0, d.color, d.valueLabel) } }
    }

    var body: some View {
        let values = plotted
        let domain = yDomain ?? PulseChartAxis.zeroBased(values.map(\.value))
        let grid = gridValues ?? PulseChartAxis.gridValues(domain, count: gridlineCount)
        let labels = Dictionary(data.map { ($0.id, (label: $0.label, sublabel: $0.sublabel)) },
                                uniquingKeysWith: { first, _ in first })
        Chart {
            ForEach(values, id: \.id) { v in
                BarMark(x: .value("Category", v.id), y: .value("Value", v.value), width: .fixed(barWidth))
                    .foregroundStyle(v.color)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 3, topTrailingRadius: 3, style: .circular))
                    .annotation(position: .top, spacing: 4) {
                        if let label = v.label {
                            Text(label)
                                .font(PulseType.numeral(12))
                                .foregroundStyle(v.color)
                        }
                    }
            }
        }
        .chartXScale(domain: data.map(\.id))
        .chartYScale(domain: domain)
        .chartYAxis {
            AxisMarks(position: .leading, values: grid) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                if showsYAxisLabels {
                    AxisValueLabel().font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: data.map(\.id)) { value in
                AxisValueLabel(centered: true) {
                    let id = value.as(String.self)
                    PulseChartAxis.xLabel(id.flatMap { labels[$0] }, highlighted: id != nil && id == highlightID)
                }
            }
        }
        .chartBackground { proxy in PulseChartHighlight(proxy: proxy, id: highlightID) }
        .frame(height: height)
        .overlay {
            if values.isEmpty {
                Text(emptyMessage)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PulseChartAccessibility.summary(data))
    }
}

// MARK: - Line with typical band

/// A line through the values (series colour at 70%, 2 pt) with hollow 9 pt markers, value labels above,
/// a faint area fill, and optionally the typical range as a white-8% band with a "■ TYPICAL RANGE" chip
/// and a dashed white average line with an "AVG." pill. Missing days are skipped and the line connects
/// across them. With no `yDomain` the range is dynamic (heart rate, HRV); pass a fixed one for percents.
struct PulseLineChart: View {
    let data: [PulseChartDatum]
    var color: Color
    var typicalRange: ClosedRange<Double>?
    var average: Double?
    var yDomain: ClosedRange<Double>?
    var gridlineCount: Int = 5
    var showsYAxisLabels = false
    var highlightID: String?
    var showsArea = true
    var showsValueLabels = true
    var height: CGFloat = 197
    var emptyMessage: String = String(localized: "No data yet")

    init(data: [PulseChartDatum], color: Color, typicalRange: ClosedRange<Double>? = nil, average: Double? = nil,
         yDomain: ClosedRange<Double>? = nil, gridlineCount: Int = 5, showsYAxisLabels: Bool = false,
         highlightID: String? = nil, showsArea: Bool = true, showsValueLabels: Bool = true,
         height: CGFloat = 197, emptyMessage: String = String(localized: "No data yet")) {
        self.data = data
        self.color = color
        self.typicalRange = typicalRange
        self.average = average
        self.yDomain = yDomain
        self.gridlineCount = gridlineCount
        self.showsYAxisLabels = showsYAxisLabels
        self.highlightID = highlightID
        self.showsArea = showsArea
        self.showsValueLabels = showsValueLabels
        self.height = height
        self.emptyMessage = emptyMessage
    }

    private var plotted: [(id: String, value: Double, label: String?)] {
        data.compactMap { d in d.value.map { (d.id, $0, d.valueLabel) } }
    }

    var body: some View {
        let values = plotted
        var everything = values.map(\.value)
        if let typicalRange { everything += [typicalRange.lowerBound, typicalRange.upperBound] }
        if let average { everything.append(average) }
        let domain = yDomain ?? PulseChartAxis.dynamic(everything)
        let labels = Dictionary(data.map { ($0.id, (label: $0.label, sublabel: $0.sublabel)) },
                                uniquingKeysWith: { first, _ in first })
        return VStack(alignment: .trailing, spacing: 8) {
            if typicalRange != nil {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.25)).frame(width: 10, height: 10)
                    Text(String(localized: "Typical range")).pulseText(.label).foregroundStyle(PulseTheme.textSecondary)
                }
            }
            Chart {
                if let average {
                    RuleMark(y: .value("Average", average))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(position: .overlay, alignment: .leading) {
                            Text(String(localized: "Avg."))
                                .font(.system(size: 11, weight: .bold))
                                .textCase(.uppercase)
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.white))
                        }
                }
                ForEach(values, id: \.id) { v in
                    if showsArea {
                        AreaMark(x: .value("Category", v.id), yStart: .value("Base", domain.lowerBound),
                                 yEnd: .value("Value", v.value))
                            .foregroundStyle(LinearGradient(colors: [color.opacity(0.12), color.opacity(0)],
                                                            startPoint: .top, endPoint: .bottom))
                    }
                    LineMark(x: .value("Category", v.id), y: .value("Value", v.value))
                        .foregroundStyle(color.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    PointMark(x: .value("Category", v.id), y: .value("Value", v.value))
                        .symbol {
                            Circle()
                                .strokeBorder(color, lineWidth: 2)
                                .background(Circle().fill(PulseTheme.cardSolidMiddle))
                                .frame(width: 9, height: 9)
                        }
                        .annotation(position: .top, spacing: 4) {
                            if showsValueLabels, let label = v.label {
                                Text(label).font(PulseType.numeral(13)).foregroundStyle(color)
                            }
                        }
                }
            }
            // With an average, the first column moves right to leave the "AVG." pill its own room.
            .chartXScale(domain: data.map(\.id), range: .plotDimension(startPadding: average == nil ? 0 : 30))
            .chartYScale(domain: domain)
            .chartYAxis {
                AxisMarks(position: .leading, values: PulseChartAxis.gridValues(domain, count: gridlineCount)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                    if showsYAxisLabels {
                        AxisValueLabel().font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: data.map(\.id)) { value in
                    AxisValueLabel(centered: true) {
                        let id = value.as(String.self)
                        PulseChartAxis.xLabel(id.flatMap { labels[$0] }, highlighted: id != nil && id == highlightID)
                    }
                }
            }
            .chartBackground { proxy in
                ZStack {
                    PulseChartHighlight(proxy: proxy, id: highlightID)
                    if let typicalRange {
                        PulseChartBand(proxy: proxy, range: typicalRange)
                    }
                }
            }
            .frame(height: height)
            .overlay {
                if values.isEmpty {
                    Text(emptyMessage).pulseText(.body).foregroundStyle(PulseTheme.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PulseChartAccessibility.summary(data))
    }
}

/// A horizontal band across the plot between two y values (the typical range).
private struct PulseChartBand: View {
    let proxy: ChartProxy
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            if let anchor = proxy.plotFrame,
               let top = proxy.position(forY: range.upperBound),
               let bottom = proxy.position(forY: range.lowerBound) {
                let plot = geo[anchor]
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: plot.width, height: max(1, bottom - top))
                    .position(x: plot.midX, y: plot.minY + (top + bottom) / 2)
            }
        }
    }
}

// MARK: - Stacked bars

/// Stacked bars (HR ZONES 1-3, HR ZONES 4-5, RESTORATIVE SLEEP; 100%-stacked stress levels): segments
/// bottom to top in the order given, with a white total above each column ("0:00" on empty days).
struct PulseStackedBarChart: View {
    struct Segment: Identifiable, Equatable {
        let id: String
        let value: Double
        let color: Color
    }

    struct Column: Identifiable, Equatable {
        let id: String
        let label: String
        var sublabel: String?
        let segments: [Segment]
        var totalLabel: String?

        var total: Double { segments.reduce(0) { $0 + max(0, $1.value) } }
    }

    let columns: [Column]
    var yDomain: ClosedRange<Double>?
    var gridlineCount: Int = 5
    var highlightID: String?
    var barWidth: CGFloat = 14
    var height: CGFloat = 197

    init(columns: [Column], yDomain: ClosedRange<Double>? = nil, gridlineCount: Int = 5,
         highlightID: String? = nil, barWidth: CGFloat = 14, height: CGFloat = 197) {
        self.columns = columns
        self.yDomain = yDomain
        self.gridlineCount = gridlineCount
        self.highlightID = highlightID
        self.barWidth = barWidth
        self.height = height
    }

    var body: some View {
        let domain = yDomain ?? PulseChartAxis.zeroBased(columns.map(\.total))
        let labels = Dictionary(columns.map { ($0.id, (label: $0.label, sublabel: $0.sublabel)) },
                                uniquingKeysWith: { first, _ in first })
        Chart {
            ForEach(columns) { column in
                let parts = column.segments.isEmpty
                    ? [Segment(id: "\(column.id)-empty", value: 0, color: .clear)]
                    : column.segments
                ForEach(Array(parts.enumerated()), id: \.element.id) { index, segment in
                    BarMark(x: .value("Category", column.id), y: .value("Value", max(0, segment.value)),
                            width: .fixed(barWidth))
                        .foregroundStyle(segment.color)
                        .annotation(position: .top, spacing: 4) {
                            if index == parts.count - 1, let total = column.totalLabel {
                                Text(total).font(PulseType.numeral(12)).foregroundStyle(PulseTheme.textPrimary)
                            }
                        }
                }
            }
        }
        .chartXScale(domain: columns.map(\.id))
        .chartYScale(domain: domain)
        .chartYAxis {
            AxisMarks(position: .leading, values: PulseChartAxis.gridValues(domain, count: gridlineCount)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
            }
        }
        .chartXAxis {
            AxisMarks(values: columns.map(\.id)) { value in
                AxisValueLabel(centered: true) {
                    let id = value.as(String.self)
                    PulseChartAxis.xLabel(id.flatMap { labels[$0] }, highlighted: id != nil && id == highlightID)
                }
            }
        }
        .chartBackground { proxy in PulseChartHighlight(proxy: proxy, id: highlightID) }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(columns.count) columns"))
    }
}

// MARK: - Hatched track (§2.6 item 17)

/// 45° lines, 1 pt, every 4 pt, white 7%: the empty part of zone, stage, stress-level and impact bars.
struct PulseHatchedTrack: View {
    var color: Color = Color.white.opacity(0.07)
    var spacing: CGFloat = 4
    var cornerRadius: CGFloat = PulseTheme.Radius.badge

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += spacing
            }
            context.stroke(path, with: .color(color), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .circular))
        .accessibilityHidden(true)
    }
}

/// A one-line VoiceOver summary of a chart's values.
enum PulseChartAccessibility {
    static func summary(_ data: [PulseChartDatum]) -> String {
        let shown = data.compactMap { d -> String? in
            guard d.value != nil else { return nil }
            return "\(d.label)\(d.sublabel.map { " \($0)" } ?? ""): \(d.valueLabel ?? d.value.map { String(format: "%.1f", $0) } ?? "")"
        }
        return shown.isEmpty ? String(localized: "No data") : shown.joined(separator: ", ")
    }
}
#endif
