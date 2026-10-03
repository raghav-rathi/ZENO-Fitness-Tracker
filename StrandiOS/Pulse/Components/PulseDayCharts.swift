#if os(iOS)
import SwiftUI
import Charts
import StrandAnalytics

// MARK: - Day and week charts several groups share (WHOOP_UI_SPEC §2.7)
//
// Real instants (a heart-rate sample, a stress hour) are `Date`s and their axis labels are formatted in the
// device zone by the caller; day-keyed weeks take labels already formatted at UTC (`PulseFormat.dayLabel`).
// Missing data is skipped, never drawn as zero.

/// A shaded period behind a time chart (sleep or an activity) with its glyph above the plot.
struct PulseChartPeriod: Identifiable, Equatable {
    enum Kind: Equatable {
        case sleep, activity, breathwork

        var color: Color {
            switch self {
            case .sleep: return PulseTheme.sleep
            case .activity: return PulseTheme.strain
            case .breathwork: return PulseTheme.recoveryBlue
            }
        }
    }

    let id: String
    let start: Date
    let end: Date
    let kind: Kind
    /// The glyph above it ("moon.fill", a sport symbol).
    var symbol: String?
}

/// A timestamped value.
struct PulseTimeValue: Identifiable, Equatable {
    let date: Date
    /// nil is a gap (no reading), never zero.
    let value: Double?
    var id: Date { date }
}

// MARK: Heart-rate area (sleep or activity)

/// Heart rate over an activity or a night: a 1.5 pt line in the series colour over a vertical gradient fill
/// (35% → 0), dashed vertical rules at the window's start and end with a 4 pt dot at their foot, heart
/// rate outside the window dimmer, and the start / end time under each rule (12 pt Bold condensed, 70%).
///
///     PulseHRAreaChart(points: hr, window: start...end, color: PulseTheme.strain,
///                      startLabel: "10:02 PM", endLabel: "6:41 AM", startSymbol: "sunset.fill")
struct PulseHRAreaChart: View {
    let points: [PulseTimeValue]
    var window: ClosedRange<Date>?
    var color: Color = PulseTheme.strain
    var startLabel: String?
    var endLabel: String?
    var startSymbol: String?
    var endSymbol: String?
    var yValues: [Double]?
    var height: CGFloat = 180

    private var domain: ClosedRange<Double> {
        let values = points.compactMap(\.value)
        guard let lo = values.min(), let hi = values.max() else { return 40...100 }
        return (floor((lo - 5) / 10) * 10)...(ceil((hi + 5) / 10) * 10)
    }

    var body: some View {
        let yDomain = domain
        VStack(spacing: 6) {
            Chart {
                ForEach(segments, id: \.0) { index, run in
                    ForEach(run) { p in
                        if let v = p.value {
                            AreaMark(x: .value("Time", p.date), yStart: .value("Base", yDomain.lowerBound),
                                     yEnd: .value("BPM", v), series: .value("Run", index))
                                .foregroundStyle(LinearGradient(colors: [color.opacity(0.35), color.opacity(0)],
                                                                startPoint: .top, endPoint: .bottom))
                                .opacity(inWindow(p.date) ? 1 : 0.4)
                            LineMark(x: .value("Time", p.date), y: .value("BPM", v), series: .value("Run", index))
                                .foregroundStyle(color.opacity(inWindow(p.date) ? 1 : 0.4))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
                if let window {
                    ForEach([window.lowerBound, window.upperBound], id: \.self) { edge in
                        RuleMark(x: .value("Edge", edge))
                            .foregroundStyle(PulseTheme.textTertiary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        PointMark(x: .value("Edge", edge), y: .value("Foot", yDomain.lowerBound))
                            .symbolSize(16)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: yValues ?? PulseChartAxis.gridValues(yDomain, count: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                    AxisValueLabel().font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
                }
            }
            .frame(height: height)
            if startLabel != nil || endLabel != nil {
                HStack {
                    edgeLabel(startSymbol, startLabel)
                    Spacer(minLength: 8)
                    edgeLabel(endSymbol, endLabel)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart rate"))
        .accessibilityValue(summary)
    }

    /// Contiguous runs, so a gap in wear is drawn as a gap rather than a straight line.
    private var segments: [(Int, [PulseTimeValue])] {
        var out: [[PulseTimeValue]] = [[]]
        for p in points {
            if p.value == nil {
                if !(out.last?.isEmpty ?? true) { out.append([]) }
            } else {
                out[out.count - 1].append(p)
            }
        }
        return out.filter { !$0.isEmpty }.enumerated().map { ($0.offset, $0.element) }
    }

    private func inWindow(_ date: Date) -> Bool {
        guard let window else { return true }
        return window.contains(date)
    }

    private func edgeLabel(_ symbol: String?, _ text: String?) -> some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 11, weight: .semibold))
            }
            if let text { Text(text).font(PulseType.numeral(12)) }
        }
        .foregroundStyle(PulseTheme.textSecondary)
    }

    private var summary: String {
        let values = points.compactMap(\.value)
        guard let lo = values.min(), let hi = values.max() else { return String(localized: "No data") }
        return String(localized: "\(Int(lo.rounded())) to \(Int(hi.rounded())) beats per minute")
    }
}

// MARK: Stress, 24 h

/// The 24 h stress chart: the line coloured by its own value along the stress scale, sleep and activity
/// periods as 12% bands with a 3 pt cap on the top gridline and a glyph above, a dashed white-70% now-line
/// ending in a 6 pt dot in the current level's colour, y labels 0.0 / 1.0 / 2.0 / 3.0 on the left and the
/// rolling x labels under it (the last one white).
///
/// With no readings, today keeps its periods and says the day fills in; a past day (`now` nil) has nothing
/// to fill in, so it draws only the empty grid and "No stress curve for this day", without periods or x
/// labels (a lone workout would otherwise stretch across the whole chart as if it were the day).
struct PulseStressChart: View {
    let points: [PulseTimeValue]
    var periods: [PulseChartPeriod] = []
    /// The "now" line's instant, today only.
    var now: Date?
    /// The level the headline shows, which colours the now-line's dot (the latest reading otherwise).
    var currentLevel: Double?
    /// Four x labels already formatted in the device zone, oldest first ("3:29 PM" … "8:29 AM").
    var xLabels: [String] = []
    var height: CGFloat = 150

    private var hasReadings: Bool { points.contains { $0.value != nil } }

    /// A past day without a single reading: no curve will ever arrive, so periods and times are left out.
    private var isEmptyPastDay: Bool { now == nil && !hasReadings }

    private var shownPeriods: [PulseChartPeriod] { isEmptyPastDay ? [] : periods }

    private var range: ClosedRange<Date>? {
        let dates = points.map(\.date) + shownPeriods.flatMap { [$0.start, $0.end] } + (now.map { [$0] } ?? [])
        guard let lo = dates.min(), let hi = dates.max(), hi > lo else { return nil }
        return lo...hi
    }

    var body: some View {
        VStack(spacing: 6) {
            Chart {
                ForEach(shownPeriods) { period in
                    RectangleMark(xStart: .value("Start", period.start), xEnd: .value("End", period.end),
                                  yStart: .value("Low", 0), yEnd: .value("High", 3))
                        .foregroundStyle(period.kind.color.opacity(0.12))
                    RectangleMark(xStart: .value("Start", period.start), xEnd: .value("End", period.end),
                                  yStart: .value("Cap", 2.97), yEnd: .value("Top", 3.0))
                        .foregroundStyle(period.kind.color)
                        .annotation(position: .top, spacing: 2) {
                            if let symbol = period.symbol {
                                Image(systemName: symbol)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(PulseTheme.textPrimary)
                            }
                        }
                }
                // One short segment per pair of readings, each in its own value's colour.
                ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                    ForEach([pair.0, pair.1], id: \.date) { p in
                        LineMark(x: .value("Time", p.date), y: .value("Stress", p.value ?? 0),
                                 series: .value("Segment", index))
                            .foregroundStyle(PulseTheme.Stress.color(for: ((pair.0.value ?? 0) + (pair.1.value ?? 0)) / 2))
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                            .interpolationMethod(.monotone)
                    }
                }
                ForEach(singles) { p in
                    PointMark(x: .value("Time", p.date), y: .value("Stress", p.value ?? 0))
                        .symbolSize(10)
                        .foregroundStyle(PulseTheme.Stress.color(for: p.value ?? 0))
                }
                if let now, let level = currentLevel ?? points.last(where: { $0.value != nil })?.value {
                    RuleMark(x: .value("Now", now))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Now", now), y: .value("Foot", 0))
                        .symbolSize(36)
                        .foregroundStyle(PulseTheme.Stress.Level(value: level).color)
                }
            }
            .chartYScale(domain: 0...3)
            .chartXScale(domain: range ?? Date()...Date().addingTimeInterval(3600))
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.0, 1.0, 2.0, 3.0]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(String(format: "%.1f", v)).font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                }
            }
            .frame(height: height)
            // Room above the plot for the period glyphs.
            .padding(.top, 16)
            .overlay {
                if !hasReadings {
                    Text(isEmptyPastDay ? String(localized: "No stress curve for this day.")
                         : String(localized: "The day's stress fills in as your strap records heart rate."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            if !xLabels.isEmpty && !isEmptyPastDay {
                HStack {
                    ForEach(Array(xLabels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(PulseType.font(.axis))
                            .foregroundStyle(index == xLabels.count - 1 ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                        if index < xLabels.count - 1 { Spacer(minLength: 4) }
                    }
                }
                .padding(.leading, 28)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Stress through the day"))
        .accessibilityValue(summary)
    }

    /// Consecutive readings with no gap between them.
    private var pairs: [(PulseTimeValue, PulseTimeValue)] {
        guard points.count > 1 else { return [] }
        return (1..<points.count).compactMap { i in
            points[i - 1].value != nil && points[i].value != nil ? (points[i - 1], points[i]) : nil
        }
    }

    /// Readings with no neighbour, drawn as dots so a lone hour still shows.
    private var singles: [PulseTimeValue] {
        points.indices.compactMap { i in
            guard points[i].value != nil else { return nil }
            let before = i > 0 && points[i - 1].value != nil
            let after = i + 1 < points.count && points[i + 1].value != nil
            return before || after ? nil : points[i]
        }
    }

    /// The latest level (the headline's, else the last reading) and the peak, printed as the Stress
    /// Monitor's gauge and Home print a level: cut to one decimal (`HealthStressGauge.printed`), so VoiceOver
    /// never reads 2.0 where the screen shows 1.9.
    private var summary: String {
        let values = points.compactMap(\.value)
        guard let last = values.last else { return String(localized: "No data") }
        let latest = HealthStressGauge.printed(currentLevel ?? last)
        let peak = HealthStressGauge.printed(values.max() ?? last)
        return String(localized: "Latest \(PulseFormat.oneDecimal(latest)) of 3, peak \(PulseFormat.oneDecimal(peak))")
    }
}

// MARK: Strain & Recovery, a week

/// The STRAIN & RECOVERY card's chart (reviews/06, completeness-critic/13): Strain on the left axis
/// (0 / 7 / 14 / 21 in strain blue) as a 50% blue line with hollow markers and blue labels; Recovery on the
/// right axis (0% / 33% / 66% / 100%, coloured red / red / yellow / green) as a white-25% line with markers
/// and labels coloured by zone. A day's two labels point away from each other: the higher marker's label
/// above it, the lower one's below (Recovery above when they tie, or a day has one marker). Missing days are
/// skipped and the lines connect across them; the selected day's column is highlighted.
struct PulseStrainRecoveryChart: View {
    struct Day: Identifiable, Equatable {
        /// The day key.
        let id: String
        /// "Wed".
        let label: String
        /// "27".
        let sublabel: String
        /// 0–21.
        let strain: Double?
        /// 0–100.
        let recovery: Double?
    }

    let days: [Day]
    var highlightID: String?
    var height: CGFloat = 200

    var body: some View {
        Chart {
            ForEach(days.filter { $0.strain != nil }) { day in
                LineMark(x: .value("Day", day.id), y: .value("Strain", day.strain ?? 0), series: .value("S", "strain"))
                    .foregroundStyle(PulseTheme.strain.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("Day", day.id), y: .value("Strain", day.strain ?? 0))
                    .symbol { marker(PulseTheme.strain) }
                    .annotation(position: strainPlotsHigher(day) ? .top : .bottom, spacing: 3) {
                        Text(PulseFormat.oneDecimal(day.strain ?? 0))
                            .font(PulseType.numeral(12))
                            .foregroundStyle(PulseTheme.strain)
                    }
            }
            ForEach(days.filter { $0.recovery != nil }) { day in
                let r = day.recovery ?? 0
                LineMark(x: .value("Day", day.id), y: .value("Recovery", r * 0.21), series: .value("S", "recovery"))
                    .foregroundStyle(PulseTheme.dash)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("Day", day.id), y: .value("Recovery", r * 0.21))
                    .symbol { marker(PulseTheme.recovery(percent: r)) }
                    .annotation(position: strainPlotsHigher(day) ? .bottom : .top, spacing: 3) {
                        Text("\(PulseDisplay.displayedPercent(r))%")
                            .font(PulseType.numeral(12))
                            .foregroundStyle(PulseTheme.recoveryText(PulseDisplay.recoveryBand(percent: r)))
                    }
            }
        }
        .chartXScale(domain: days.map(\.id))
        .chartYScale(domain: 0...21)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0.0, 7.0, 14.0, 21.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))").font(PulseType.font(.axis)).foregroundStyle(PulseTheme.strain)
                    }
                }
            }
            AxisMarks(position: .trailing, values: [0.0, 6.93, 13.86, 21.0]) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        let pct = Int((v / 0.21).rounded())
                        Text("\(pct)%")
                            .font(PulseType.font(.axis))
                            .foregroundStyle(pct >= 100 ? PulseTheme.recoveryHigh
                                             : pct >= 66 ? PulseTheme.recoveryMid : PulseTheme.recoveryLowText)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: days.map(\.id)) { value in
                AxisValueLabel(centered: true) {
                    if let id = value.as(String.self), let day = days.first(where: { $0.id == id }) {
                        PulseChartAxis.xLabel((day.label, day.sublabel), highlighted: id == highlightID)
                    }
                }
            }
        }
        .chartBackground { proxy in
            GeometryReader { geo in
                if let id = highlightID, let anchor = proxy.plotFrame, let x = proxy.position(forX: id) {
                    let plot = geo[anchor]
                    RoundedRectangle(cornerRadius: 6, style: .circular)
                        .fill(PulseTheme.chartHighlight)
                        .frame(width: 29, height: geo.size.height)
                        .position(x: plot.minX + x, y: geo.size.height / 2)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Strain and Recovery, last 7 days"))
        .accessibilityValue(days.map { day in
            let s = day.strain.map { String(localized: "Strain \(PulseFormat.oneDecimal($0))") } ?? String(localized: "no strain")
            let r = day.recovery.map { String(localized: "Recovery \(PulseDisplay.displayedPercent($0)) percent") }
                ?? String(localized: "no recovery")
            return "\(day.label) \(day.sublabel): \(s), \(r)"
        }.joined(separator: "; "))
    }

    private func marker(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: 2)
            .background(Circle().fill(PulseTheme.lineMarkerCore))
            .frame(width: 9, height: 9)
    }

    /// Whether the day's Strain marker sits above its Recovery marker (both on the 0–21 scale). Only then
    /// does the Strain label go on top and the Recovery label underneath; labels placed by series alone
    /// ran into each other wherever Strain crossed above Recovery ("15.0" under "50%").
    private func strainPlotsHigher(_ day: Day) -> Bool {
        guard let strain = day.strain, let recovery = day.recovery else { return false }
        return strain > recovery * 0.21
    }
}
#endif
