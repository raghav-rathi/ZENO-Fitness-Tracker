#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Turns one metric's resolved series into a Trend View page (WHOOP_UI_SPEC §3.12): the window and its
/// pager, the headline with its chip, the sentence, the chart model, the breakdown and the footnotes.
///
/// Pure: everything comes in as values, so it runs inside the snapshot builder's actor and its rules are
/// the same for every metric. The arithmetic itself is `PulseTrendMath` (StrandAnalytics, tested); this
/// decides what to say and draw with it.
enum PulseTrendPageBuilder {

    static func page(seq: Int, metric: PulseTrendMetric, series: PulseTrendSeries, anchor: String,
                     range requested: PulseTrendMath.Range, page requestedPage: Int,
                     phases: [String: PulseTrendCyclePhase] = [:]) -> TrendViewSnapshot {
        let range = metric.ranges.contains(requested) ? requested : (metric.ranges.first ?? .week)
        let earliest = series.earliest
        let lastPage = PulseTrendMath.lastPage(range, anchor: anchor, earliest: earliest)
        let page = max(0, min(requestedPage, lastPage))
        let window = PulseTrendMath.window(range, anchor: anchor, page: page, earliest: earliest)
            ?? PulseTrendMath.Window(start: anchor, end: anchor, page: 0, dayCount: 1, hasOlder: false)
        let ctx = Context(metric: metric, series: series, anchor: anchor, range: range, window: window)

        let headline = ctx.headline()
        let chart = ctx.chart(average: headline.chartAverage, phases: phases)
        return TrendViewSnapshot(
            seq: seq, metric: metric, range: range, page: page,
            pager: PulseTrendPager(title: pagerTitle(window), canGoBack: window.hasOlder, canGoForward: window.hasNewer,
                                   accessibility: pagerAccessibility(window)),
            headlines: headline.items,
            insight: ctx.insight(current: headline.current, previous: headline.previous),
            legend: ctx.legend(chart: chart),
            chart: chart,
            footnotes: ctx.footnotes(excludedDay: headline.excludedDay),
            breakdown: ctx.breakdown(),
            hasData: series.hasData,
            showsCycleNote: !chart.phases.isEmpty)
    }

    // MARK: Pager

    /// "Sep 19 - Sep 25, 26"; both years once the window crosses one ("Sep 3, 23 - Feb 29, 24"). Day keys,
    /// so formatted at UTC.
    static func pagerTitle(_ w: PulseTrendMath.Window) -> String {
        let startYear = PulseFormat.dayLabel(w.start, template: "yy")
        let endYear = PulseFormat.dayLabel(w.end, template: "yy")
        let start = PulseFormat.dayLabel(w.start, template: "MMMd")
        let end = PulseFormat.dayLabel(w.end, template: "MMMd")
        if w.start == w.end { return "\(end), \(endYear)" }
        if startYear == endYear { return "\(start) - \(end), \(endYear)" }
        return "\(start), \(startYear) - \(end), \(endYear)"
    }

    static func pagerAccessibility(_ w: PulseTrendMath.Window) -> String {
        let start = PulseFormat.dayLabel(w.start, template: "yMMMMd")
        let end = PulseFormat.dayLabel(w.end, template: "yMMMMd")
        return String(localized: "\(start) to \(end)")
    }

    // MARK: - Per-page context

    private struct Headline {
        var items: [PulseTrendHeadline]
        var current: Double?
        var previous: Double?
        var excludedDay: String?
        /// The value the M chart's dashed AVG. line sits at.
        var chartAverage: Double?
    }

    private struct Context {
        let metric: PulseTrendMetric
        let series: PulseTrendSeries
        let anchor: String
        let range: PulseTrendMath.Range
        let window: PulseTrendMath.Window

        var format: PulseTrendValueFormat { series.signed ? .signedOneDecimal : metric.format }
        var unit: String { series.unit ?? metric.unit }
        /// Today, while a running total is still counting it and it is on this page.
        var inProgressDay: String? { metric.isRunningTotal && window.contains(anchor) ? anchor : nil }
        var isWeeklyTotal: Bool { metric.aggregation == .weeklyTotal }

        /// "74%", "4:30", "50": a value inside a sentence (only "%" is written out, as WHOOP writes them).
        func spoken(_ v: Double) -> String {
            let text = format.text(v)
            return unit == "%" ? text + "%" : text
        }

        // MARK: Headline

        func headline() -> Headline {
            if case .hoursVsNeed = metric.chart { return hoursVsNeedHeadline() }
            let current: Double?
            let previous: Double?
            var excluded: String?
            switch metric.aggregation {
            case .average:
                let avg = PulseTrendMath.average(series.points, in: window, inProgressDay: inProgressDay)
                current = avg?.value
                excluded = avg?.excludedDay
                previous = range == .all ? nil : PulseTrendMath.average(series.points, in: window.previous)?.value
            case .weeklyTotal:
                current = PulseTrendMath.averageWeeklyTotal(series.points, in: window)
                previous = range == .all ? nil : PulseTrendMath.averageWeeklyTotal(series.points, in: window.previous)
            }
            let label: String
            if isWeeklyTotal {
                label = range == .week ? String(localized: "Weekly total") : String(localized: "Avg. weekly total")
            } else {
                label = String(localized: "Average")
            }
            let valueText = current.map(format.text) ?? "--"
            let item = PulseTrendHeadline(
                id: "main", label: label, value: valueText, unit: current == nil ? "" : unit,
                chip: chip(current: current, previous: previous),
                accessibility: current.map { "\(label), \(format.text($0)) \(unit)" }
                    ?? String(localized: "\(label), no readings"))
            return Headline(items: [item], current: current, previous: previous, excludedDay: excluded,
                            chartAverage: current)
        }

        /// HOURS VS. NEEDED (HOURS): the average need (teal) over the average hours (sleep blue), each with a
        /// mini chip against the period before.
        private func hoursVsNeedHeadline() -> Headline {
            let hours = PulseTrendMath.average(series.points, in: window)?.value
            let need = PulseTrendMath.average(series.secondary, in: window)?.value
            let hoursBefore = range == .all ? nil : PulseTrendMath.average(series.points, in: window.previous)?.value
            let needBefore = range == .all ? nil : PulseTrendMath.average(series.secondary, in: window.previous)?.value
            let needItem = PulseTrendHeadline(
                id: "need", label: String(localized: "Avg. need"), value: need.map(format.text) ?? "--",
                unit: need == nil ? "" : unit, valueColor: PulseTheme.positive,
                chip: chip(current: need, previous: needBefore, polarity: .lowerIsBetter, compact: true),
                compact: true,
                accessibility: need.map { String(localized: "Average need, \(format.text($0)) hours") }
                    ?? String(localized: "Average need, no readings"))
            let hoursItem = PulseTrendHeadline(
                id: "hours", label: String(localized: "Avg. hours"), value: hours.map(format.text) ?? "--",
                unit: hours == nil ? "" : unit, valueColor: PulseTheme.sleep,
                chip: chip(current: hours, previous: hoursBefore, compact: true), compact: true,
                accessibility: hours.map { String(localized: "Average hours of sleep, \(format.text($0))") }
                    ?? String(localized: "Average hours of sleep, no readings"))
            return Headline(items: [needItem, hoursItem], current: hours, previous: hoursBefore,
                            excludedDay: nil, chartAverage: nil)
        }

        /// "▲ 45% vs. prior week", or Strain's absolute "▲ 2.6 vs. prior week"; "● 0%" when the two print
        /// the same. Coloured by the metric's chip polarity (grey for Recovery, Day Strain and Calories).
        func chip(current: Double?, previous: Double?, polarity: PulseMetricPolarity? = nil,
                  compact: Bool = false) -> PulseTrendChip? {
            guard let current, let previous, let phrase = range.priorPhrase,
                  let change = PulseTrendMath.change(current: current, previous: previous) else { return nil }
            let polarity = polarity ?? metric.chipPolarity
            let samePrinted = format.printed(current) == format.printed(previous)
            let absolute = metric.key == "strain" || change.percent == nil
            let magnitude: String
            let delta: Double
            if absolute {
                let shown = format == .duration ? format.text(abs(change.delta)) : PulseFormat.oneDecimal(abs(change.delta))
                magnitude = shown
                delta = samePrinted || shown == PulseFormat.oneDecimal(0) ? 0 : change.delta
            } else {
                let pct = Int(abs(change.percent ?? 0).rounded())
                magnitude = "\(pct)%"
                delta = samePrinted || pct == 0 ? 0 : change.delta
            }
            let text = compact ? magnitude : "\(magnitude) \(phrase)"
            return PulseTrendChip(text: text, trend: PulseTrend(delta: delta, polarity: polarity))
        }

        // MARK: Sentence

        func insight(current: Double?, previous: Double?) -> String? {
            let name = metric.sentenceName
            guard let current else {
                return series.hasData
                    ? String(localized: "No \(name) readings in this period.")
                    : String(localized: "No \(name) readings yet. They appear here once your strap or an import records them.")
            }
            let value = spoken(current)
            if case .hoursVsNeed = metric.chart {
                let need = PulseTrendMath.average(series.secondary, in: window)?.value
                guard let need else {
                    return String(localized: "You averaged \(value) of sleep over this period.")
                }
                switch PulseTrendMath.relation(current, reference: need, tolerancePercent: 3) {
                case .within:
                    return String(localized: "You slept about as much as you needed over this period: \(value) against a need of \(spoken(need)).")
                case .below:
                    return String(localized: "You slept less than you needed over this period: \(value) against a need of \(spoken(need)).")
                case .above:
                    return String(localized: "You slept more than you needed over this period: \(value) against a need of \(spoken(need)).")
                }
            }
            if range == .all {
                let days = PulseTrendMath.points(series.points, in: window).count
                return String(localized: "Across all \(days) days with readings, your average \(name) is \(value).")
            }
            if metric.showsTypicalRange && range == .week {
                guard let typical = PulseTrendMath.typicalRange(series.points, before: window.start) else {
                    return String(localized: "Your average \(name) during this 7-day period was \(value). Its typical range needs a week of readings from the month before.")
                }
                let lo = format.text(typical.lowerBound), hi = format.text(typical.upperBound)
                switch PulseTrendMath.relation(format.printed(current), to: format.printed(typical.lowerBound)...format.printed(typical.upperBound)) {
                case .above:
                    return String(localized: "Your average \(name) during this 7-day period was above its typical range (\(lo) - \(hi)) at the time.")
                case .within:
                    return String(localized: "Your average \(name) during this 7-day period was within its typical range (\(lo) - \(hi)) at the time.")
                case .below:
                    return String(localized: "Your average \(name) during this 7-day period was below its typical range (\(lo) - \(hi)) at the time.")
                }
            }
            if isWeeklyTotal {
                guard let previous else {
                    return range == .week
                        ? String(localized: "During this 7-day period, your total time in \(name) was \(value).")
                        : String(localized: "Over this period, your average weekly time in \(name) was \(value).")
                }
                let relation = PulseTrendMath.relation(format.printed(current), reference: format.printed(previous))
                let ref = spoken(previous)
                if range == .week {
                    switch relation {
                    case .above: return String(localized: "During this 7-day period, your total time in \(name) (\(value)) was above your previous 7-day total of \(ref).")
                    case .below: return String(localized: "During this 7-day period, your total time in \(name) (\(value)) was below your previous 7-day total of \(ref).")
                    case .within: return String(localized: "During this 7-day period, your total time in \(name) (\(value)) was in line with your previous 7-day total of \(ref).")
                    }
                }
                switch relation {
                case .above: return String(localized: "Your average weekly time in \(name) over this period (\(value)) was above your weekly average over the period before (\(ref)).")
                case .below: return String(localized: "Your average weekly time in \(name) over this period (\(value)) was below your weekly average over the period before (\(ref)).")
                case .within: return String(localized: "Your average weekly time in \(name) over this period (\(value)) was in line with your weekly average over the period before (\(ref)).")
                }
            }
            if range == .week {
                // The chip already says how the week compares with the one before; the sentence sets it
                // against the month before, as WHOOP's Recovery week does ("its prior 30-day average").
                let monthBefore = PulseTrendMath.Window(start: PulseTrendMath.addDays(window.start, -30),
                                                        end: PulseTrendMath.addDays(window.start, -1), page: 0,
                                                        dayCount: 30, hasOlder: false)
                guard let ref = PulseTrendMath.average(series.points, in: monthBefore)?.value else {
                    return String(localized: "Your average \(name) over this 7-day period was \(value).")
                }
                let r = spoken(ref)
                switch PulseTrendMath.relation(format.printed(current), reference: format.printed(ref)) {
                case .above: return String(localized: "Over this 7-day period, your average \(name) (\(value)) was higher than its prior 30-day average (\(r)).")
                case .below: return String(localized: "Over this 7-day period, your average \(name) (\(value)) was lower than its prior 30-day average (\(r)).")
                case .within: return String(localized: "Over this 7-day period, your average \(name) (\(value)) was consistent with its prior 30-day average (\(r)).")
                }
            }
            guard let previous else {
                return String(localized: "Your average \(name) over this period was \(value). There is no earlier period to compare it with yet.")
            }
            let r = spoken(previous)
            let relation = PulseTrendMath.relation(format.printed(current), reference: format.printed(previous))
            switch (range, relation) {
            case (.month, .above): return String(localized: "Your average \(name) over these 30 days (\(value)) was above your previous 30-day average of \(r).")
            case (.month, .below): return String(localized: "Your average \(name) over these 30 days (\(value)) was below your previous 30-day average of \(r).")
            case (.month, .within): return String(localized: "Your average \(name) over these 30 days (\(value)) was consistent with your previous 30-day average of \(r).")
            case (.sixMonths, .above): return String(localized: "Your average \(name) over this period (\(value)) was above your previous 6-month average of \(r).")
            case (.sixMonths, .below): return String(localized: "Your average \(name) over this period (\(value)) was below your previous 6-month average of \(r).")
            case (.sixMonths, .within): return String(localized: "Your average \(name) over this period (\(value)) was consistent with your previous 6-month average of \(r).")
            case (_, .above): return String(localized: "Your average \(name) over this period (\(value)) was above your previous 12-month average of \(r).")
            case (_, .below): return String(localized: "Your average \(name) over this period (\(value)) was below your previous 12-month average of \(r).")
            case (_, .within): return String(localized: "Your average \(name) over this period (\(value)) was consistent with your previous 12-month average of \(r).")
            }
        }

        // MARK: Chart

        func chart(average: Double?, phases: [String: PulseTrendCyclePhase]) -> PulseTrendChartModel {
            let weekly = isWeeklyTotal && range != .week
            return weekly ? weeklyChart(average: average) : dailyChart(average: average, phases: phases)
        }

        private func columnColor(_ v: Double?) -> Color {
            guard let v else { return metric.color }
            switch metric.key {
            case "recovery": return PulseTheme.recovery(percent: v)
            case "stress": return PulseTheme.Stress.Level(value: v).color
            default: return metric.color
            }
        }

        /// Value labels over W's columns: "64%", "13.2", "7:41", "2,386".
        private func columnLabel(_ v: Double) -> String { spoken(v) }

        private func dailyChart(average: Double?, phases: [String: PulseTrendCyclePhase]) -> PulseTrendChartModel {
            let keys = window.dayKeys
            let byDay = lookup(series.points)
            let parts = series.parts.map(lookup)
            let secondary = lookup(series.secondary)
            let isWeek = range == .week
            let isLong = range.drawsSegments
            let mode: PulseTrendChartModel.Mode
            switch metric.chart {
            case .bars: mode = isLong ? .line : .bars
            case .line: mode = .line
            case .stacked: mode = isLong ? .line : .stacked
            case .hoursVsNeed: mode = isLong ? .line : .dualLine
            }
            var columns: [PulseTrendChartModel.Column] = keys.map { key in
                let v = byDay[key]
                return PulseTrendChartModel.Column(
                    id: key, value: v, parts: mode == .stacked ? parts.map { $0[key] ?? 0 } : [],
                    secondary: mode == .dualLine ? secondary[key] : nil,
                    color: columnColor(v),
                    label: isWeek ? v.map(columnLabel) : nil,
                    secondaryLabel: isWeek && mode == .dualLine ? secondary[key].map(columnLabel) : nil)
            }
            // An M line marks and labels its newest point only (deep-dives-2026/54: "32").
            if range == .month && mode == .line,
               let last = columns.lastIndex(where: { $0.value != nil }), let v = columns[last].value {
                columns[last].label = columnLabel(v)
            }
            let typical = metric.showsTypicalRange && !isLong
                ? PulseTrendMath.typicalRange(series.points, before: window.start) : nil
            let showsAverage = range == .month && (metric.chart == .bars || isStacked) && average != nil
            var visible = columns.compactMap(\.value)
            visible += columns.compactMap(\.secondary)
            let segs = isLong ? segments() : []
            visible += segs.map(\.value)
            let scale = yScale(values: visible, typical: typical, average: showsAverage ? average : nil)
            return PulseTrendChartModel(
                mode: mode, columns: columns, yDomain: scale.domain, yTicks: scale.ticks,
                xLabels: dayLabels(keys),
                barWidth: isWeek ? 16 : 7,
                partColors: partColors, lineColor: metric.color,
                secondaryColor: mode == .dualLine ? PulseTheme.positive : nil,
                average: showsAverage ? average : nil, typical: typical,
                segments: segs, dimmed: isLong,
                showsMarkers: isWeek, marksLastPointOnly: range == .month && mode == .line,
                phases: phaseSpans(keys, phases: phases),
                emptyMessage: columns.contains { $0.value != nil } ? nil : emptyMessage,
                accessibilitySummary: accessibility(columns: columns, average: average))
        }

        /// M and the long ranges of a minute metric: one stacked column per complete week.
        private func weeklyChart(average: Double?) -> PulseTrendChartModel {
            let weeks = PulseTrendMath.weeklyTotals(series.points, in: window)
            let partWeeks = series.parts.map { PulseTrendMath.weeklyTotals($0, in: window) }
            let isLong = range.drawsSegments
            let columns: [PulseTrendChartModel.Column] = weeks.map { week in
                let parts = partWeeks.map { pw in pw.first(where: { $0.end == week.end })?.total ?? 0 }
                return PulseTrendChartModel.Column(
                    id: week.end, value: week.total, parts: isStacked ? parts : [],
                    color: metric.color, label: range == .month ? columnLabel(week.total) : nil)
            }
            let segs = isLong ? segments(weekColumns: weeks) : []
            let visible = columns.compactMap(\.value) + segs.map(\.value)
            let scale = yScale(values: visible, typical: nil, average: range == .month ? average : nil)
            var labels: [PulseTrendChartModel.XLabel] = []
            if range == .month {
                labels = weeks.enumerated().map { i, w in
                    PulseTrendChartModel.XLabel(index: i, line1: PulseFormat.dayLabel(w.end, template: "MMM"),
                                                line2: PulseFormat.dayLabel(w.end, template: "d"))
                }
            } else {
                var lastMonth = ""
                for (i, w) in weeks.enumerated() {
                    let month = String(w.end.prefix(7))
                    if month != lastMonth && i > 0 {
                        labels.append(PulseTrendChartModel.XLabel(index: i, line1: PulseFormat.dayLabel(w.end, template: "MMM")))
                    }
                    lastMonth = month
                }
                labels = thinned(labels)
            }
            return PulseTrendChartModel(
                mode: isStacked ? .stacked : .bars, columns: columns, yDomain: scale.domain, yTicks: scale.ticks,
                xLabels: labels, barWidth: range == .month ? 24 : 7, partColors: partColors,
                lineColor: metric.color, secondaryColor: nil,
                average: range == .month ? average : nil, typical: nil, segments: segs, dimmed: isLong,
                showsMarkers: false, marksLastPointOnly: false, phases: [],
                emptyMessage: columns.contains { ($0.value ?? 0) > 0 } ? nil : emptyMessage,
                accessibilitySummary: accessibility(columns: columns, average: average))
        }

        private var isStacked: Bool {
            if case .stacked = metric.chart { return true }
            return false
        }

        private var partColors: [Color] {
            if case .stacked(let parts) = metric.chart { return parts.map(\.color) }
            return []
        }

        private var emptyMessage: String {
            series.hasData ? String(localized: "No readings in this period") : String(localized: "No readings yet")
        }

        /// The long ranges' segments over day columns (or week columns for a minute metric).
        private func segments(weekColumns: [PulseTrendMath.WeekTotal]? = nil) -> [PulseTrendChartModel.Segment] {
            let blockDays = PulseTrendMath.segmentDays(range, dayCount: window.dayCount)
            // A running total's still-counting day would drag its segment down: leave it out.
            let points = inProgressDay.map { skip in series.points.filter { $0.day != skip } } ?? series.points
            let segs = PulseTrendMath.segments(points, in: window, blockDays: blockDays,
                                               aggregation: isWeeklyTotal ? .weeklyTotal : .mean)
            var out: [PulseTrendChartModel.Segment] = []
            for (i, s) in segs.enumerated() {
                guard let value = s.value else { continue }
                let span: (Int, Int)?
                if let weeks = weekColumns {
                    let inside = weeks.indices.filter { weeks[$0].end >= s.start && weeks[$0].end <= s.end }
                    span = inside.first.map { ($0, inside.last ?? $0) }
                } else {
                    let a = PulseTrendMath.daysBetween(window.start, s.start) ?? 0
                    let b = PulseTrendMath.daysBetween(window.start, s.end) ?? a
                    span = (a, b)
                }
                guard let (start, end) = span else { continue }
                var changeLabel: String?
                var color = PulseTheme.textPrimary
                var changeColor = PulseTheme.textSecondary
                if let pct = s.changePercent {
                    let n = Int(pct.rounded())
                    changeLabel = n > 0 ? "+\(n)%" : "\(n)%"
                    let trend = PulseTrend(delta: n == 0 ? 0 : pct, polarity: metric.chipPolarity)
                    switch trend.judgement {
                    case .favourable:
                        color = PulseTheme.Delta.favourableText
                        changeColor = PulseTheme.Delta.favourableText
                    case .unfavourable:
                        color = PulseTheme.Delta.unfavourableText
                        changeColor = PulseTheme.Delta.unfavourableText
                    case .neutral, .unchanged:
                        color = PulseTheme.textPrimary
                        changeColor = PulseTheme.Delta.neutralText
                    }
                }
                out.append(PulseTrendChartModel.Segment(
                    id: "\(i)-\(s.start)", startIndex: start, endIndex: end, value: value,
                    valueLabel: spoken(value), changeLabel: changeLabel, color: color, changeColor: changeColor))
            }
            return out
        }

        /// The x labels: every day for W ("Sat" over "19"); every seventh day back from the end for M ("Aug"
        /// over "6"); month starts for the long ranges ("Mar"), thinned to fit.
        private func dayLabels(_ keys: [String]) -> [PulseTrendChartModel.XLabel] {
            switch range {
            case .week:
                return keys.enumerated().map { i, k in
                    PulseTrendChartModel.XLabel(index: i, line1: PulseFormat.dayLabel(k, template: "EEE"),
                                                line2: PulseFormat.dayLabel(k, template: "d"))
                }
            case .month:
                return keys.enumerated().compactMap { i, k in
                    (keys.count - 1 - i) % 7 == 0
                        ? PulseTrendChartModel.XLabel(index: i, line1: PulseFormat.dayLabel(k, template: "MMM"),
                                                      line2: PulseFormat.dayLabel(k, template: "d"))
                        : nil
                }
            case .sixMonths, .year, .all:
                let spansYears = window.dayCount > 366
                let labels = keys.enumerated().compactMap { i, k -> PulseTrendChartModel.XLabel? in
                    guard k.hasSuffix("-01"), i > 0 || keys.count == 1 else { return nil }
                    let january = k.dropFirst(5).hasPrefix("01")
                    return PulseTrendChartModel.XLabel(
                        index: i, line1: PulseFormat.dayLabel(k, template: "MMM"),
                        line2: spansYears && january ? PulseFormat.dayLabel(k, template: "y") : nil)
                }
                return thinned(labels)
            }
        }

        /// At most seven labels, keeping every n-th so they stay evenly spaced.
        private func thinned(_ labels: [PulseTrendChartModel.XLabel]) -> [PulseTrendChartModel.XLabel] {
            guard labels.count > 7 else { return labels }
            let step = Int((Double(labels.count) / 7).rounded(.up))
            return labels.enumerated().compactMap { $0.offset % step == 0 ? $0.element : nil }
        }

        private func phaseSpans(_ keys: [String], phases: [String: PulseTrendCyclePhase]) -> [PulseTrendChartModel.PhaseSpan] {
            guard !phases.isEmpty, range != .all else { return [] }
            var spans: [PulseTrendChartModel.PhaseSpan] = []
            var current: (phase: PulseTrendCyclePhase, start: Int)?
            for (i, k) in keys.enumerated() {
                let p = phases[k]
                if p != current?.phase {
                    if let c = current {
                        spans.append(.init(id: "\(c.start)", startIndex: c.start, endIndex: i - 1, phase: c.phase))
                    }
                    current = p.map { ($0, i) }
                }
            }
            if let c = current {
                spans.append(.init(id: "\(c.start)", startIndex: c.start, endIndex: keys.count - 1, phase: c.phase))
            }
            return spans
        }

        // MARK: Y scale

        private func yScale(values: [Double], typical: ClosedRange<Double>?,
                            average: Double?) -> (domain: ClosedRange<Double>, ticks: [PulseTrendChartModel.Tick]) {
            func percentTicks(_ values: [Double]) -> [PulseTrendChartModel.Tick] {
                values.map { PulseTrendChartModel.Tick(value: $0, label: "\(Int($0))%") }
            }
            switch metric.scale {
            case .percent:
                let top = max(100, (values.max() ?? 0).rounded(.up))
                return (0...top, percentTicks([0, 25, 50, 75, 100]))
            case .recovery:
                return (0...100, [
                    .init(value: 0, label: "0%", color: PulseTheme.recoveryLowText),
                    .init(value: 33, label: "33%", color: PulseTheme.recoveryLowText),
                    .init(value: 66, label: "66%", color: PulseTheme.recoveryMid),
                    .init(value: 100, label: "100%", color: PulseTheme.recoveryHigh)
                ])
            case .strain:
                return (0...21, [0, 5, 10, 15, 21].map { .init(value: $0, label: PulseFormat.whole($0)) })
            case .stress:
                return (0...3, [0, 1, 2, 3].map { .init(value: $0, label: PulseFormat.oneDecimal($0)) })
            case .zeroBased:
                return zeroBasedScale(values + [average].compactMap { $0 })
            case .dynamic, .dynamicPercent:
                var all = values
                if let typical { all += [typical.lowerBound, typical.upperBound] }
                if let average { all.append(average) }
                return dynamicScale(all, capAt100: metric.scale == .dynamicPercent)
            }
        }

        /// 0 to a round number above the largest value, four intervals (steps 0 / 5,000 / … / 20,000).
        private func zeroBasedScale(_ values: [Double]) -> (domain: ClosedRange<Double>, ticks: [PulseTrendChartModel.Tick]) {
            let top = max(values.max() ?? 0, 0)
            let step: Double
            if format == .duration {
                // Minutes: steps of 5, 10, 15, 30 minutes or whole hours, labelled "0:30" or "2".
                let raw = max(top, 1) / 4
                let options: [Double] = [5, 10, 15, 30, 60, 120, 180, 240, 360, 480, 720]
                step = options.first { $0 >= raw } ?? (raw / 60).rounded(.up) * 60
            } else {
                step = Self.niceStep(max(top, 1) / 4)
            }
            let ticks = (0...4).map { Double($0) * step }
            let labels: [PulseTrendChartModel.Tick] = ticks.map { v in
                let label: String
                if format == .duration {
                    label = step.truncatingRemainder(dividingBy: 60) == 0 ? PulseFormat.whole(v / 60) : PulseFormat.hoursMinutes(v)
                } else if unit == "%" {
                    label = "\(PulseFormat.whole(v))%"
                } else {
                    label = format == .oneDecimal ? PulseFormat.oneDecimal(v) : PulseFormat.grouped(v)
                }
                return PulseTrendChartModel.Tick(value: v, label: label)
            }
            return (0...(4 * step), labels)
        }

        /// Around the data, four even intervals on the metric's precision, never from zero (HR, HRV).
        private func dynamicScale(_ values: [Double], capAt100: Bool) -> (domain: ClosedRange<Double>, ticks: [PulseTrendChartModel.Tick]) {
            let precision: Double = (format == .whole || format == .grouped || format == .duration) ? 1 : 0.5
            guard let lo = values.min(), let hi = values.max() else {
                return (0...1, [])
            }
            let span = max(hi - lo, precision * 4)
            var bottom = ((lo - span * 0.3) / precision).rounded(.down) * precision
            var step = (((hi + span * 0.35) - bottom) / 4 / precision).rounded(.up) * precision
            step = max(step, precision)
            if capAt100 && bottom + 4 * step > 100 {
                bottom = max(0, 100 - 4 * step)
            }
            if bottom < 0 && lo >= 0 { bottom = 0 }
            let ticks = (0...4).map { bottom + Double($0) * step }
            let labels = ticks.map { v -> PulseTrendChartModel.Tick in
                let text = precision < 1 ? PulseFormat.oneDecimal(v) : format.text(v)
                return PulseTrendChartModel.Tick(value: v, label: unit == "%" ? text + "%" : text)
            }
            return (bottom...(bottom + 4 * step), labels)
        }

        static func niceStep(_ raw: Double) -> Double {
            guard raw > 0 else { return 1 }
            let magnitude = pow(10, (log10(raw)).rounded(.down))
            let normalised = raw / magnitude
            let nice: Double = [1, 2, 2.5, 5, 10].first { $0 >= normalised - 1e-9 } ?? 10
            return nice * magnitude
        }

        // MARK: Legend, footnotes, breakdown

        func legend(chart: PulseTrendChartModel) -> [PulseTrendLegendItem] {
            var items: [PulseTrendLegendItem] = []
            if chart.typical != nil {
                items.append(.init(id: "typical", title: String(localized: "Typical range"), color: PulseTheme.typicalSwatch))
            }
            if chart.mode == .stacked, case .stacked(let parts) = metric.chart {
                let ordered = metric.key == "restorative_min" ? parts.reversed() : parts
                items += ordered.map { .init(id: $0.id, title: $0.title, color: $0.color) }
            }
            if chart.mode == .dualLine {
                items.append(.init(id: "hours", title: String(localized: "Hours of sleep"), color: PulseTheme.sleep, swatch: .ring))
                items.append(.init(id: "need", title: String(localized: "Sleep needed"), color: PulseTheme.positive, swatch: .ring))
            }
            let shown = Set(chart.phases.map(\.phase))
            for phase in PulseTrendCyclePhase.allCases where shown.contains(phase) {
                items.append(.init(id: "phase-\(phase.rawValue)", title: phase.title, color: phase.color, swatch: .dot))
            }
            return items
        }

        func footnotes(excludedDay: String?) -> [String] {
            var notes: [String] = []
            if let excludedDay {
                notes.append(String(localized: "Average does not include today (\(PulseFormat.dayLabel(excludedDay, template: "MMMd")))"))
            }
            if let note = metric.note { notes.append(note) }
            if series.signed {
                notes.append(String(localized: "Shown as the change from your personal baseline"))
            }
            if range == .year || range == .all {
                let days = PulseTrendMath.segmentDays(range, dayCount: window.dayCount)
                notes.append(String(localized: "Each segment shows a \(days)-day average"))
            }
            return notes
        }

        func breakdown() -> PulseTrendBreakdown? {
            if isWeeklyTotal, case .stacked(let parts) = metric.chart {
                let totals: [Double] = series.parts.map { part in
                    range == .week
                        ? PulseTrendMath.points(part, in: window).reduce(0) { $0 + $1.value }
                        : (PulseTrendMath.averageWeeklyTotal(part, in: window) ?? 0)
                }
                let sum = totals.reduce(0, +)
                guard sum > 0, totals.count == parts.count else { return nil }
                return PulseTrendBreakdown(
                    title: String(localized: "HR zones breakdown"),
                    unitNote: range == .week ? String(localized: "(Weekly total)") : String(localized: "(Avg. weekly total)"),
                    rows: zip(parts, totals).map { part, total in
                        .init(id: part.id, amount: PulseFormat.hoursMinutes(total), name: part.title, range: "",
                              color: part.color, share: total / sum)
                    })
            }
            guard let spec = metric.breakdown else { return nil }
            let values = PulseTrendMath.points(series.points, in: window).map { format.printed($0.value) }
            guard !values.isEmpty else { return nil }
            let counts = PulseTrendMath.breakdown(values, lowerBounds: spec.lowerBounds)
            let total = Double(values.count)
            return PulseTrendBreakdown(
                title: spec.title, unitNote: String(localized: "(Days)"),
                rows: zip(spec.bands, counts).enumerated().map { i, pair in
                    .init(id: "\(i)", amount: "\(pair.1)x", name: pair.0.name, range: pair.0.range,
                          color: pair.0.color, share: Double(pair.1) / total)
                })
        }

        // MARK: Accessibility

        private func accessibility(columns: [PulseTrendChartModel.Column], average: Double?) -> String {
            let readings = columns.compactMap(\.value)
            guard !readings.isEmpty else { return String(localized: "\(metric.title), no readings in this period") }
            var parts = [String(localized: "\(metric.title), \(range.spokenName), \(pagerAccessibility(window))")]
            if let lo = readings.min(), let hi = readings.max() {
                parts.append(String(localized: "lowest \(spoken(lo)), highest \(spoken(hi))"))
            }
            if let average { parts.append(String(localized: "average \(spoken(average))")) }
            if range == .week {
                let days = columns.compactMap { c in
                    c.value.map { "\(PulseFormat.dayLabel(c.id, template: "EEEE")) \(spoken($0))" }
                }
                parts.append(days.joined(separator: ", "))
            }
            return parts.joined(separator: ". ")
        }

        private func lookup(_ points: [PulseTrendMath.Point]) -> [String: Double] {
            Dictionary(points.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        }
    }
}
#endif
