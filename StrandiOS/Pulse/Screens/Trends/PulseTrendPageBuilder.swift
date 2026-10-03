#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Turns one metric's resolved series into a Trend View page (WHOOP_UI_SPEC §3.12): the window and its
/// pager, the headline with its chip, the sentence, the chart model, the breakdown and the footnotes.
///
/// Pure: everything comes in as values, so it runs inside the snapshot builder's actor and its rules are
/// the same for every metric. The arithmetic itself is `PulseTrendMath` (StrandAnalytics, tested); this
/// decides what to say and draw with it. The chip and the sentence judge a change by ONE rule
/// (`PulseTrendMath.compare`), so a "● 0%" chip never sits over "above" and a "▼ 2%" never over
/// "consistent with".
enum PulseTrendPageBuilder {

    /// `today` is the newest day the series holds (its running totals' still-counting day); `anchor` is
    /// the day the latest window ends on, today unless the page was opened from an earlier day.
    static func page(seq: Int, metric: PulseTrendMetric, series: PulseTrendSeries, today: String,
                     anchor requestedAnchor: String? = nil, range requested: PulseTrendMath.Range,
                     page requestedPage: Int, phases: [String: PulseTrendCyclePhase] = [:]) -> TrendViewSnapshot {
        let anchor = min(requestedAnchor ?? today, today)
        let range = metric.ranges.contains(requested) ? requested : (metric.ranges.first ?? .week)
        let earliest = series.earliest
        let lastPage = PulseTrendMath.lastPage(range, anchor: anchor, earliest: earliest)
        let page = max(0, min(requestedPage, lastPage))
        let window = PulseTrendMath.window(range, anchor: anchor, page: page, earliest: earliest)
            ?? PulseTrendMath.Window(start: anchor, end: anchor, page: 0, dayCount: 1, hasOlder: false)
        let ctx = Context(metric: metric, series: series, today: today, range: range, window: window)

        let headline = ctx.headline()
        let chart = ctx.chart(average: headline.chartAverage, phases: phases)
        return TrendViewSnapshot(
            seq: seq, metric: metric, range: range, page: page,
            pager: PulseTrendPager(title: pagerTitle(window), canGoBack: window.hasOlder, canGoForward: window.hasNewer,
                                   accessibility: pagerAccessibility(window)),
            headlines: headline.items,
            insight: ctx.insight(headline),
            legend: ctx.legend(chart: chart),
            chart: chart,
            footnotes: ctx.footnotes(excludedDay: headline.excludedDay),
            breakdown: ctx.breakdown(),
            hasData: series.hasData,
            showsCycleNote: !chart.phases.isEmpty)
    }

    // MARK: What correlates

    /// The metrics whose daily values move with `metric`'s over the page's window, strongest first. W's
    /// seven days are too few for a correlation, so W scans the 30 days that end with its week. Pairs where
    /// one metric is computed from the other (Recovery from HRV, Sleep Performance from hours vs needed)
    /// are left out: they move together by construction.
    static func correlations(metric: PulseTrendMetric, series: PulseTrendSeries,
                             others: [(PulseTrendMetric, PulseTrendSeries)], today: String,
                             anchor requestedAnchor: String? = nil, range requested: PulseTrendMath.Range,
                             page: Int) -> PulseTrendCorrelations {
        let anchor = min(requestedAnchor ?? today, today)
        let range = metric.ranges.contains(requested) ? requested : (metric.ranges.first ?? .week)
        let earliest = series.earliest
        let clamped = max(0, min(page, PulseTrendMath.lastPage(range, anchor: anchor, earliest: earliest)))
        let thisPeriod = String(localized: "this period")
        guard let window = PulseTrendMath.window(range, anchor: anchor, page: clamped, earliest: earliest) else {
            return PulseTrendCorrelations(period: thisPeriod, rows: [], hasEnoughDays: false)
        }
        let scan: PulseTrendMath.Window
        let period: String
        if range == .week {
            scan = PulseTrendMath.Window(start: PulseTrendMath.addDays(window.end, -29), end: window.end, page: 0,
                                         dayCount: 30, hasOlder: false)
            period = String(localized: "the 30 days to \(PulseFormat.dayLabel(window.end, template: "MMMd"))")
        } else {
            scan = window
            period = thisPeriod
        }
        let mine = PulseTrendMath.points(series.points, in: scan).map { (day: $0.day, value: $0.value) }
        guard mine.count >= minimumCorrelationDays else {
            return PulseTrendCorrelations(period: period, rows: [], hasEnoughDays: false)
        }
        var rows: [PulseTrendCorrelation] = []
        for (other, otherSeries) in others where !PulseTrendMetric.derived(metric.key, other.key) {
            let theirs = PulseTrendMath.points(otherSeries.points, in: scan).map { (day: $0.day, value: $0.value) }
            let pairs = CorrelationEngine.alignByDay(mine, theirs)
            guard pairs.count >= minimumCorrelationDays, let c = CorrelationEngine.pearson(pairs),
                  abs(c.r) >= 0.3 else { continue }
            rows.append(PulseTrendCorrelation(id: other.key, title: other.rowTitle, symbol: other.symbol, r: c.r, n: c.n))
        }
        return PulseTrendCorrelations(period: period, rows: Array(rows.sorted { abs($0.r) > abs($1.r) }.prefix(5)),
                                      hasEnoughDays: true)
    }

    /// Shared days below which a correlation is not shown (the classic card's n ≥ 10).
    static let minimumCorrelationDays = 10

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
        /// The period's only reading is today's, still counting (Day Stress: its latest reading): nothing to
        /// average or compare yet.
        var todayOnly = false
        /// W of a minute metric holds a day of unknown zone time: its total is a lower bound.
        var partialWeek = false
    }

    private struct Context {
        let metric: PulseTrendMetric
        let series: PulseTrendSeries
        let today: String
        let range: PulseTrendMath.Range
        let window: PulseTrendMath.Window

        var format: PulseTrendValueFormat { series.signed ? .signedOneDecimal : metric.format }
        var unit: String { series.unit ?? metric.unit }
        /// Today, while a running total is still counting it and it is on this page.
        var inProgressDay: String? { metric.isRunningTotal && window.contains(today) ? today : nil }
        var isWeeklyTotal: Bool { metric.aggregation == .weeklyTotal }
        var unknown: Set<String> { series.unknownDays }
        /// The printed step a change is judged at: "15.5" moves in tenths, "74" and "7:40" in ones.
        var step: Double { format == .oneDecimal || format == .signedOneDecimal ? 0.1 : 1 }

        /// "74%", "4:30", "50": a value inside a sentence (only "%" is written out, as WHOOP writes them).
        func spoken(_ v: Double) -> String {
            let text = format.text(v)
            return unit == "%" ? text + "%" : text
        }

        /// The ONE judgement of a change the chip and the sentence share. Day Strain's is in points
        /// ("▲ 2.6"), every other metric's in percent.
        func compare(_ current: Double?, _ reference: Double?) -> PulseTrendMath.Comparison? {
            guard let current, let reference else { return nil }
            return PulseTrendMath.compare(current, with: reference, step: step, absolute: metric.key == "strain")
        }

        // MARK: Headline

        func headline() -> Headline {
            if case .hoursVsNeed = metric.chart { return hoursVsNeedHeadline() }
            var h = Headline(items: [])
            switch metric.aggregation {
            case .average:
                let avg = PulseTrendMath.average(series.points, in: window, inProgressDay: inProgressDay)
                h.current = avg?.value
                h.excludedDay = avg?.excludedDay
                if let day = inProgressDay, avg?.count == 1, avg?.excludedDay == nil,
                   PulseTrendMath.points(series.points, in: window).first?.day == day {
                    h.todayOnly = true
                }
                h.previous = range == .all ? nil : PulseTrendMath.average(series.points, in: window.previous)?.value
            case .weeklyTotal:
                if range == .week {
                    // W is one week: its total, a lower bound when a day's zone time is unknown, so it is
                    // compared only when both weeks are whole.
                    let inside = PulseTrendMath.points(series.points, in: window)
                    h.current = inside.isEmpty ? nil : inside.reduce(0) { $0 + $1.value }
                    h.partialWeek = holdsUnknown(window)
                    let before = PulseTrendMath.points(series.points, in: window.previous)
                    h.previous = h.partialWeek || before.isEmpty || holdsUnknown(window.previous)
                        ? nil : before.reduce(0) { $0 + $1.value }
                } else {
                    // Past W: the average of the COMPLETE weeks; a week holding an unknown day is left out.
                    h.current = PulseTrendMath.averageWeeklyTotal(series.points, in: window, unknownDays: unknown)
                    h.previous = range == .all ? nil
                        : PulseTrendMath.averageWeeklyTotal(series.points, in: window.previous, unknownDays: unknown)
                }
            }
            // Today alone, when it is a reading rather than a total still counting (Day Stress: the Stress
            // Monitor's gauge), is named as that reading, with when it was read under it.
            let reading = h.todayOnly ? series.todayReading : nil
            let label: String
            if let reading {
                label = reading.time == nil ? String(localized: "Daily score") : String(localized: "Latest reading")
            } else if h.todayOnly {
                label = String(localized: "Today so far")
            } else if isWeeklyTotal {
                label = range == .week ? String(localized: "Weekly total") : String(localized: "Avg. weekly total")
            } else {
                label = String(localized: "Average")
            }
            let valueText = h.current.map(format.text) ?? "--"
            var spokenHeadline = h.current.map { "\(label), \(format.text($0)) \(unit)" }
                ?? String(localized: "\(label), no readings")
            if let time = reading?.time { spokenHeadline += ", \(time)" }
            h.items = [PulseTrendHeadline(
                id: "main", label: label, value: valueText, unit: h.current == nil ? "" : unit,
                chip: h.todayOnly ? nil : chip(compare(h.current, h.previous)),
                accessibility: spokenHeadline, caption: reading?.time)]
            h.chartAverage = h.todayOnly ? nil : h.current
            return h
        }

        /// True when `w` holds a day whose value is unknown (an activity logged without zones).
        func holdsUnknown(_ w: PulseTrendMath.Window) -> Bool {
            !unknown.isEmpty && w.dayKeys.contains(where: unknown.contains)
        }

        /// HOURS VS. NEEDED (HOURS): the average need (teal) over the average hours (sleep blue), each with a
        /// mini chip against the period before, stacked tight and without a unit (deep-dives-2026/21, 48).
        private func hoursVsNeedHeadline() -> Headline {
            let hours = PulseTrendMath.average(series.points, in: window)?.value
            let need = PulseTrendMath.average(series.secondary, in: window)?.value
            let hoursBefore = range == .all ? nil : PulseTrendMath.average(series.points, in: window.previous)?.value
            let needBefore = range == .all ? nil : PulseTrendMath.average(series.secondary, in: window.previous)?.value
            // The spec's table calls a lower need favourable, but deep-dives-2026/21 colours the need's
            // "▼ 1%" orange, as it colours the hours: both chips read with the hours' polarity.
            let needItem = PulseTrendHeadline(
                id: "need", label: String(localized: "Avg. need"), value: need.map(format.text) ?? "--",
                unit: "", valueColor: PulseTheme.positive,
                chip: chip(compare(need, needBefore), polarity: .higherIsBetter, compact: true),
                compact: true,
                accessibility: need.map { String(localized: "Average need, \(format.text($0)) hours") }
                    ?? String(localized: "Average need, no readings"))
            let hoursItem = PulseTrendHeadline(
                id: "hours", label: String(localized: "Avg. hours"), value: hours.map(format.text) ?? "--",
                unit: "", valueColor: PulseTheme.sleep,
                chip: chip(compare(hours, hoursBefore), compact: true), compact: true,
                accessibility: hours.map { String(localized: "Average hours of sleep, \(format.text($0))") }
                    ?? String(localized: "Average hours of sleep, no readings"))
            return Headline(items: [needItem, hoursItem], current: hours, previous: hoursBefore,
                            excludedDay: nil, chartAverage: nil)
        }

        /// "▲ 45% vs. prior week", or Strain's absolute "▲ 2.6 vs. prior week"; "● 0%" ("● 0.0") when the
        /// comparison is unchanged. Coloured by the metric's chip polarity (grey for Recovery, Day Strain
        /// and Calories).
        func chip(_ c: PulseTrendMath.Comparison?, polarity: PulseMetricPolarity? = nil,
                  compact: Bool = false) -> PulseTrendChip? {
            guard let c, let phrase = range.priorPhrase else { return nil }
            let magnitude: String
            if let percent = c.percent {
                magnitude = "\(percent)%"
            } else {
                magnitude = format == .duration ? format.text(c.magnitude) : PulseFormat.oneDecimal(c.magnitude)
            }
            let text = compact ? magnitude : "\(magnitude) \(phrase)"
            return PulseTrendChip(text: text, trend: PulseTrend(delta: c.delta, polarity: polarity ?? metric.chipPolarity))
        }

        // MARK: Sentence

        func insight(_ h: Headline) -> String? {
            let name = metric.sentenceName
            guard let current = h.current else {
                guard series.hasData else { return emptyHint }
                if isWeeklyTotal && range != .week && holdsUnknown(window) {
                    return String(localized: "Every week in this period has an activity logged without heart-rate zones, so there is no whole week to average.")
                }
                return String(localized: "No \(name) readings in this period.")
            }
            let value = spoken(current)
            if h.todayOnly {
                // A reading (Day Stress's) is not still counting: say what it is and when it was read, the
                // evening before's included.
                if let reading = series.todayReading {
                    if let time = reading.time {
                        return String(localized: "Today shows your latest \(name) reading, \(value) at \(time). No other day in this period has one.")
                    }
                    return String(localized: "Today shows your daily \(name) score from your vitals, \(value). No other day in this period has one.")
                }
                return String(localized: "Only today has a \(name) reading in this period so far: \(value), still counting.")
            }
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
                // A signed range reads badly with a dash between the signs ("-0.2 - +0.2").
                let span = typical.lowerBound < 0 ? String(localized: "\(lo) to \(hi)") : "\(lo) - \(hi)"
                switch PulseTrendMath.relation(format.printed(current), to: format.printed(typical.lowerBound)...format.printed(typical.upperBound)) {
                case .above:
                    return String(localized: "Your average \(name) during this 7-day period was above its typical range (\(span)) at the time.")
                case .within:
                    return String(localized: "Your average \(name) during this 7-day period was within its typical range (\(span)) at the time.")
                case .below:
                    return String(localized: "Your average \(name) during this 7-day period was below its typical range (\(span)) at the time.")
                }
            }
            if isWeeklyTotal { return weeklyTotalInsight(h, current: current, value: value) }
            if range == .week {
                // The chip already says how the week compares with the one before; the sentence sets it
                // against the month before, as WHOOP's Recovery week does ("its prior 30-day average"),
                // judged by the chip's own rule.
                let monthBefore = PulseTrendMath.Window(start: PulseTrendMath.addDays(window.start, -30),
                                                        end: PulseTrendMath.addDays(window.start, -1), page: 0,
                                                        dayCount: 30, hasOlder: false)
                guard let ref = PulseTrendMath.average(series.points, in: monthBefore)?.value,
                      let relation = compare(current, ref)?.relation else {
                    return String(localized: "Your average \(name) over this 7-day period was \(value).")
                }
                let r = spoken(ref)
                switch relation {
                case .above: return String(localized: "Over this 7-day period, your average \(name) (\(value)) was higher than its prior 30-day average (\(r)).")
                case .below: return String(localized: "Over this 7-day period, your average \(name) (\(value)) was lower than its prior 30-day average (\(r)).")
                case .within: return String(localized: "Over this 7-day period, your average \(name) (\(value)) was consistent with its prior 30-day average (\(r)).")
                }
            }
            guard let previous = h.previous, let relation = compare(current, previous)?.relation else {
                return String(localized: "Your average \(name) over this period was \(value). There is no earlier period to compare it with yet.")
            }
            let r = spoken(previous)
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

        /// A minute metric's sentence: W's total against the week before, the longer ranges' average of
        /// whole weeks against the period before, each naming what it leaves out.
        private func weeklyTotalInsight(_ h: Headline, current: Double, value: String) -> String {
            let name = metric.sentenceName
            if range == .week {
                if h.partialWeek {
                    let known = PulseTrendMath.points(series.points, in: window).count
                    let unknownCount = window.dayKeys.filter(unknown.contains).count
                    if format.printed(current) <= 0 {
                        return String(localized: "The \(known) days with zone data in this period had no time in \(name); the other \(unknownCount) had an activity logged without heart-rate zones.")
                    }
                    return String(localized: "During this 7-day period, your time in \(name) was at least \(value), from the \(known) days with zone data.")
                }
                guard let previous = h.previous, let relation = compare(current, previous)?.relation else {
                    return String(localized: "During this 7-day period, your total time in \(name) was \(value).")
                }
                let ref = spoken(previous)
                switch relation {
                case .above: return String(localized: "During this 7-day period, your total time in \(name) (\(value)) was above your previous 7-day total of \(ref).")
                case .below: return String(localized: "During this 7-day period, your total time in \(name) (\(value)) was below your previous 7-day total of \(ref).")
                case .within: return String(localized: "During this 7-day period, your total time in \(name) (\(value)) was in line with your previous 7-day total of \(ref).")
                }
            }
            // Weeks holding a day of unknown zone time are already out of both averages; the footnote under
            // the chart says so.
            guard let previous = h.previous, let relation = compare(current, previous)?.relation else {
                return String(localized: "Over this period, your average weekly time in \(name) was \(value).")
            }
            let ref = spoken(previous)
            switch relation {
            case .above: return String(localized: "Your average weekly time in \(name) over this period (\(value)) was above your weekly average over the period before (\(ref)).")
            case .below: return String(localized: "Your average weekly time in \(name) over this period (\(value)) was below your weekly average over the period before (\(ref)).")
            case .within: return String(localized: "Your average weekly time in \(name) over this period (\(value)) was in line with your weekly average over the period before (\(ref)).")
            }
        }

        /// What to say before a metric has any reading, naming where its readings come from.
        private var emptyHint: String {
            let name = metric.sentenceName
            switch metric.source {
            case .explore(_, let source) where source == "apple-health":
                return String(localized: "No \(name) readings yet. They appear here once Apple Health shares them with ZENO.")
            case .explore(_, let source) where source != "my-whoop":
                return String(localized: "No \(name) readings yet. They appear here once they are imported.")
            case .zones, .strength:
                return String(localized: "No \(name) yet. It appears here once you log an activity.")
            case .steps:
                return String(localized: "No steps yet. They appear here once your iPhone, Apple Health or your strap counts them.")
            case .timeInBed:
                return String(localized: "No nights yet. Your time in bed appears here once your strap records a night's sleep.")
            default:
                return String(localized: "No \(name) readings yet. They appear here once your strap or an import records them.")
            }
        }

        // MARK: Chart

        func chart(average: Double?, phases: [String: PulseTrendCyclePhase]) -> PulseTrendChartModel {
            if isWeeklyTotal && range != .week { return weeklyChart(average: average) }
            if case .floating = metric.chart, !range.drawsSegments { return floatingChart(phases: phases) }
            return dailyChart(average: average, phases: phases)
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
            case .bars, .floating: mode = isLong ? .line : .bars
            case .line: mode = .line
            case .stacked: mode = isLong ? .line : .stacked
            // HOURS VS. NEEDED keeps both lines at every range, faint past M (deep-dives-2026/48).
            case .hoursVsNeed: mode = .dualLine
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
            // An M line marks and labels its newest point only (deep-dives-2026/54: "32"). VO₂ max is a weekly
            // estimate: its M marks and labels every reading (reviews/83: "55 55 53 43"), so four or five
            // estimates never read as a daily line.
            let marksEvery = range == .month && mode == .line && metric.source == .vo2Estimate
            if marksEvery {
                for i in columns.indices {
                    if let v = columns[i].value { columns[i].label = columnLabel(v) }
                }
            } else if range == .month && mode == .line,
                      let last = columns.lastIndex(where: { $0.value != nil }), let v = columns[last].value {
                columns[last].label = columnLabel(v)
            }
            let typical = metric.showsTypicalRange && !isLong
                ? PulseTrendMath.typicalRange(series.points, before: window.start) : nil
            let showsAverage = range == .month && (metric.chart == .bars || isStacked) && average != nil
            var visible = columns.compactMap(\.value)
            visible += columns.compactMap(\.secondary)
            var segs: [PulseTrendChartModel.Segment] = []
            if isLong {
                if case .hoursVsNeed = metric.chart {
                    // Two segment sets in their series colours, values only: the need above its line, the
                    // hours below theirs (deep-dives-2026/48: "10:20" teal over "6:49" slate).
                    segs = segments(series.secondary, id: "need", style: .series(PulseTheme.positive, below: false))
                        + segments(series.points, id: "hours", style: .series(PulseTheme.sleep, below: true))
                } else {
                    segs = segments(series.points, id: "main")
                }
            }
            visible += segs.map(\.value)
            let scale = yScale(values: visible, typical: typical, average: showsAverage ? average : nil)
            // Recovery and stress colour each bar by its band; their faint long-range line is neutral.
            let perValueColour = metric.key == "recovery" || metric.key == "stress"
            return PulseTrendChartModel(
                mode: mode, columns: columns, yDomain: scale.domain, yTicks: scale.ticks,
                xLabels: dayLabels(keys),
                barWidth: isWeek ? 16 : 7,
                barFraction: range == .month ? PulseTheme.Trends.monthBarFraction : nil,
                partColors: partColors, lineColor: perValueColour ? PulseTheme.textSecondary : metric.color,
                secondaryColor: mode == .dualLine ? PulseTheme.positive : nil,
                average: showsAverage ? average : nil, typical: typical,
                segments: segs, dimmed: isLong,
                showsMarkers: isWeek || marksEvery, marksLastPointOnly: range == .month && mode == .line && !marksEvery,
                phases: phaseSpans(keys, phases: phases),
                emptyMessage: columns.contains { $0.value != nil } ? nil : emptyMessage,
                accessibilitySummary: accessibility(columns: columns, average: average))
        }

        /// TIME IN BED for W and M: each night a bar from bedtime down to wake on a clock axis that runs
        /// downward. W labels each end ("10:28" over "6:25", deep-dives-2026/10); M draws the average
        /// bedtime and wake as dashed lines with white pills ("20:32" / "04:36", /20).
        private func floatingChart(phases: [String: PulseTrendCyclePhase]) -> PulseTrendChartModel {
            let keys = window.dayKeys
            let byDay = lookup(series.points)
            let isWeek = range == .week
            let columns: [PulseTrendChartModel.Column] = keys.map { key in
                let span = series.spans[key]
                return PulseTrendChartModel.Column(
                    id: key, value: byDay[key], range: span.map { $0.bed...$0.wake }, color: metric.color,
                    label: isWeek ? span.map { PulseTrendClock.timeNoMeridiem($0.bed) } : nil,
                    secondaryLabel: isWeek ? span.map { PulseTrendClock.timeNoMeridiem($0.wake) } : nil)
            }
            let spans = keys.compactMap { series.spans[$0] }
            var markers: [PulseTrendChartModel.Marker] = []
            if range == .month, !spans.isEmpty {
                let bed = spans.map(\.bed).reduce(0, +) / Double(spans.count)
                let wake = spans.map(\.wake).reduce(0, +) / Double(spans.count)
                markers = [.init(id: "bed", value: bed, pill: PulseTrendClock.time(bed)),
                           .init(id: "wake", value: wake, pill: PulseTrendClock.time(wake))]
            }
            let scale = clockScale(spans, labelled: isWeek)
            var summary = accessibility(columns: columns, average: nil)
            if let bed = markers.first, let wake = markers.last {
                summary += ". " + String(localized: "Average bedtime \(bed.pill), average wake \(wake.pill)")
            }
            return PulseTrendChartModel(
                mode: .floating, columns: columns, yDomain: scale.domain, yTicks: scale.ticks,
                xLabels: dayLabels(keys), barWidth: isWeek ? 16 : 7,
                barFraction: range == .month ? PulseTheme.Trends.monthBarFraction : nil,
                lineColor: metric.color, secondaryColor: nil, average: nil, typical: nil,
                showsMarkers: false, marksLastPointOnly: false, phases: phaseSpans(keys, phases: phases),
                emptyMessage: columns.contains { $0.range != nil } ? nil : emptyMessage,
                accessibilitySummary: summary, markers: markers, invertedY: true)
        }

        /// The clock axis around the nights: four intervals of whole hours (1, 2, 3, 4, 5, 6, 8, 9 or 12),
        /// the first whose span covers every bed and wake, starting on a multiple of the step from midnight
        /// (deep-dives-2026/20b: 2PM / 7PM / 12AM / 5AM / 10AM). W keeps room for the labels at both ends.
        private func clockScale(_ spans: [PulseTrendSpan], labelled: Bool)
            -> (domain: ClosedRange<Double>, ticks: [PulseTrendChartModel.Tick]) {
            guard let earliest = spans.map(\.bed).min(), let latest = spans.map(\.wake).max() else {
                // No night yet: an evening-to-morning frame for the empty grid.
                let ticks = stride(from: -360.0, through: 600, by: 240).map {
                    PulseTrendChartModel.Tick(value: $0, label: PulseTrendClock.hour($0))
                }
                return (-360...600, ticks)
            }
            let pad = labelled ? max(latest - earliest, 60) * 0.12 : 0
            let lo = earliest - pad, hi = latest + pad
            let steps: [Double] = [1, 2, 3, 4, 5, 6, 8, 9, 12].map { $0 * 60 }
            var step = steps.last ?? 720
            var top = (lo / step).rounded(.down) * step
            for s in steps {
                let t = (lo / s).rounded(.down) * s
                if t + 4 * s >= hi {
                    step = s
                    top = t
                    break
                }
            }
            let ticks = (0...4).map { i -> PulseTrendChartModel.Tick in
                let v = top + Double(i) * step
                return PulseTrendChartModel.Tick(value: v, label: PulseTrendClock.hour(v))
            }
            return (top...(top + 4 * step), ticks)
        }

        /// M and the long ranges of a minute metric: one stacked column per complete week. A week holding a
        /// day of unknown zone time is drawn faint and labelled "Partial", and nothing averages it.
        private func weeklyChart(average: Double?) -> PulseTrendChartModel {
            // Every complete week of the window, counted back from its end, so the axis spans the whole
            // window; a week without a reading is a gap.
            let totals = PulseTrendMath.weeklyTotals(series.points, in: window, unknownDays: unknown)
            let partWeeks = series.parts.map { PulseTrendMath.weeklyTotals($0, in: window) }
            let isLong = range.drawsSegments
            let weekCount = window.dayCount / 7
            let weeks: [PulseTrendMath.WeekTotal] = (0..<weekCount).reversed().map { k in
                let end = PulseTrendMath.addDays(window.end, -7 * k)
                return totals.first { $0.end == end }
                    ?? PulseTrendMath.WeekTotal(start: PulseTrendMath.addDays(end, -6), end: end, total: 0, count: 0)
            }
            let columns: [PulseTrendChartModel.Column] = weeks.map { week in
                let parts = partWeeks.map { pw in pw.first(where: { $0.end == week.end })?.total ?? 0 }
                let value: Double? = week.count > 0 ? week.total : nil
                var label: String?
                if range == .month, let value {
                    label = week.isPartial ? String(localized: "Partial") : columnLabel(value)
                }
                return PulseTrendChartModel.Column(
                    id: week.end, value: value, parts: isStacked ? parts : [],
                    color: metric.color, label: label, isPartial: week.isPartial)
            }
            let segs = isLong ? segments(series.points, id: "main", weekColumns: weeks) : []
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

        /// How a segment set is coloured: by its change (white, then teal or orange with "+12%"), or in
        /// one series colour with its value only (HOURS VS. NEEDED's two sets).
        enum SegmentStyle {
            case changes
            case series(Color, below: Bool)
        }

        /// The long ranges' segments over day columns (or week columns for a minute metric).
        private func segments(_ points: [PulseTrendMath.Point], id: String,
                              weekColumns: [PulseTrendMath.WeekTotal]? = nil,
                              style: SegmentStyle = .changes) -> [PulseTrendChartModel.Segment] {
            let blockDays = PulseTrendMath.segmentDays(range, dayCount: window.dayCount)
            // A running total's still-counting day would drag its segment down: leave it out.
            let source = inProgressDay.map { skip in points.filter { $0.day != skip } } ?? points
            let segs = PulseTrendMath.segments(source, in: window, blockDays: blockDays,
                                               aggregation: isWeeklyTotal ? .weeklyTotal : .mean,
                                               unknownDays: unknown)
            var out: [PulseTrendChartModel.Segment] = []
            var previous: Double?
            for (i, s) in segs.enumerated() {
                guard let value = s.value else { continue }
                defer { previous = value }
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
                if case .series(let color, let below) = style {
                    out.append(PulseTrendChartModel.Segment(
                        id: "\(id)-\(i)-\(s.start)", startIndex: start, endIndex: end, value: value,
                        valueLabel: spoken(value), changeLabel: nil, color: color, changeColor: color,
                        labelColor: color, labelBelow: below))
                    continue
                }
                // A change that rounds to 0%, or values that print the same, is no change: the segment
                // stays white with no label under it (deep-dives-2026/27: "58" then "58").
                var changeLabel: String?
                var color = PulseTheme.textPrimary
                var changeColor = PulseTheme.textSecondary
                if let previous, let c = PulseTrendMath.compare(value, with: previous, step: step),
                   !c.isUnchanged, let percent = c.percent {
                    changeLabel = c.delta > 0 ? "+\(percent)%" : "-\(percent)%"
                    switch PulseTrend(delta: c.delta, polarity: metric.chipPolarity).judgement {
                    case .favourable:
                        color = PulseTheme.Delta.favourableText
                        changeColor = PulseTheme.Delta.favourableText
                    case .unfavourable:
                        color = PulseTheme.Delta.unfavourableText
                        changeColor = PulseTheme.Delta.unfavourableText
                    case .neutral, .unchanged:
                        changeColor = PulseTheme.Delta.neutralText
                    }
                }
                out.append(PulseTrendChartModel.Segment(
                    id: "\(id)-\(i)-\(s.start)", startIndex: start, endIndex: end, value: value,
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
                if case .hoursVsNeed = metric.chart { return hoursScale(values) }
                return zeroBasedScale(values + [average].compactMap { $0 })
            case .dynamic, .dynamicPercent:
                var all = values
                if let typical { all += [typical.lowerBound, typical.upperBound] }
                if let average { all.append(average) }
                return dynamicScale(all, capAt100: metric.scale == .dynamicPercent)
            }
        }

        /// 0 to the first round number at or above the largest value: a nice step for a quarter of it, then
        /// as many steps (two to five) as reach the top, so the tallest column fills most of the plot
        /// (deep-dives-2026/26: 15,000 over ~14.3k; /34: 20,000 over 18,444; /45: 1:00 over 0:52). The
        /// headroom above the top gridline holds the tallest column's label.
        private func zeroBasedScale(_ values: [Double]) -> (domain: ClosedRange<Double>, ticks: [PulseTrendChartModel.Tick]) {
            let top = max(values.max() ?? 0, 0)
            var step: Double
            if format == .duration {
                // Minutes: steps of 5, 10, 15, 30 minutes or whole hours, labelled "0:30" or "2".
                let raw = max(top, 1) / 4
                let options: [Double] = [5, 10, 15, 30, 60, 120, 180, 240, 360, 480, 720]
                step = options.first { $0 >= raw } ?? (raw / 60).rounded(.up) * 60
            } else {
                step = Self.niceStep(max(top, 1) / 4)
                if format == .whole || format == .grouped { step = max(step, 1) }
            }
            let intervals = max(2, min(5, Int((top / step - 1e-9).rounded(.up))))
            let ticks = (0...intervals).map { Double($0) * step }
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
            return (0...(Double(intervals) * step), labels)
        }

        /// HOURS VS. NEEDED keeps a 0–12 h axis in 3 h steps whatever the nights hold (deep-dives-2026/21
        /// tops at 12 over an 8:12 maximum, /48 over 10:29), growing in 3 h steps only past 12 hours.
        private func hoursScale(_ values: [Double]) -> (domain: ClosedRange<Double>, ticks: [PulseTrendChartModel.Tick]) {
            let step: Double = 180
            let intervals = max(4, Int(((values.max() ?? 0) / step - 1e-9).rounded(.up)))
            let ticks = (0...intervals).map { i -> PulseTrendChartModel.Tick in
                let v = Double(i) * step
                return PulseTrendChartModel.Tick(value: v, label: PulseFormat.whole(v / 60))
            }
            return (0...(Double(intervals) * step), ticks)
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
                // The swatch is the band's own colour (deep-dives-2026/37, 38).
                items.append(.init(id: "typical", title: String(localized: "Typical range"),
                                   color: PulseTheme.Trends.typicalBand))
            }
            // The parts are named while they are drawn in full; faint under the long ranges' segments they
            // go unlabelled, as on deep-dives-2026/45.
            if chart.mode == .stacked, !chart.dimmed, case .stacked(let parts) = metric.chart {
                let ordered = metric.key == "restorative_min" ? parts.reversed() : parts
                items += ordered.map { .init(id: $0.id, title: $0.title, color: $0.color) }
            }
            // VO₂ max's hollow markers are ZENO's weekly estimates (reviews/83's "○ WHOOP ESTIMATE").
            if metric.source == .vo2Estimate && chart.showsMarkers {
                items.append(.init(id: "estimate", title: String(localized: "ZENO estimate"),
                                   color: metric.color, swatch: .ring))
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
                // Today's point beside the others, when it is a reading (Day Stress's): which, and when.
                if let reading = series.todayReading {
                    let name = metric.sentenceName
                    notes.append(reading.time.map { String(localized: "Today shows your latest \(name) reading (\($0))") }
                                 ?? String(localized: "Today shows your daily \(name) score from your vitals"))
                }
            }
            if let note = metric.note { notes.append(note) }
            if case .zones = metric.source, holdsUnknown(window) {
                notes.append(range == .week
                             ? String(localized: "Days with an activity logged without heart-rate zones are left out")
                             : String(localized: "Weeks with an activity logged without heart-rate zones are left out of the average"))
            }
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
                        : (PulseTrendMath.averageWeeklyTotal(part, in: window, unknownDays: unknown) ?? 0)
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
                let days = columns.compactMap { c -> String? in
                    let day = PulseFormat.dayLabel(c.id, template: "EEEE")
                    if let r = c.range {
                        return String(localized: "\(day) \(PulseTrendClock.time(r.lowerBound)) to \(PulseTrendClock.time(r.upperBound))")
                    }
                    return c.value.map { "\(day) \(spoken($0))" }
                }
                parts.append(days.joined(separator: ", "))
            }
            if columns.contains(where: \.isPartial) {
                parts.append(String(localized: "weeks with unknown zone time are marked partial"))
            }
            return parts.joined(separator: ". ")
        }

        private func lookup(_ points: [PulseTrendMath.Point]) -> [String: Double] {
            Dictionary(points.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        }
    }
}

// MARK: - Clock labels

/// Wall-clock labels for TIME IN BED's axis, pills and bar ends, from minutes after a local midnight
/// (negative for the evening before). Formatted through the app's clock setting, on a fixed winter day so
/// a daylight-saving change never shifts them.
enum PulseTrendClock {
    /// "9:25 PM", "21:25".
    static func time(_ minutes: Double) -> String { PulseFormat.clock(date(minutes)) }

    /// "10:28", "22:28": the bar-end labels, without AM / PM (deep-dives-2026/10).
    static func timeNoMeridiem(_ minutes: Double) -> String { PulseFormat.clockNoMeridiem(date(minutes)) }

    /// "9 PM", "21:00": the axis labels (deep-dives-2026/20, 20b).
    static func hour(_ minutes: Double) -> String {
        lock.lock(); defer { lock.unlock() }
        let use24 = AppClock.uses24Hour
        let formatter: DateFormatter
        if let cached = hourFormatter, cached.uses24 == use24 {
            formatter = cached.formatter
        } else {
            let f = DateFormatter()
            f.locale = AppClock.formattingLocale
            f.setLocalizedDateFormatFromTemplate(use24 ? "HHmm" : "ha")
            hourFormatter = (use24, f)
            formatter = f
        }
        return formatter.string(from: date(minutes))
    }

    private static let lock = NSLock()
    private static var hourFormatter: (uses24: Bool, formatter: DateFormatter)?

    private static func date(_ minutes: Double) -> Date {
        let m = ((Int(minutes.rounded()) % 1440) + 1440) % 1440
        return referenceMidnight.addingTimeInterval(TimeInterval(m * 60))
    }

    /// Local midnight of 15 Jan 2001, a day with no clock change anywhere.
    private static let referenceMidnight: Date = {
        var c = DateComponents()
        c.year = 2001
        c.month = 1
        c.day = 15
        return Calendar.current.date(from: c) ?? Date(timeIntervalSinceReferenceDate: 0)
    }()
}
#endif
