#if os(iOS)
import SwiftUI
import StrandAnalytics
import WhoopStore

/// The Trends tab and the Weekly Digest from resolved trend series (WHOOP_UI_SPEC §3.35, §3.40). Pure, so it
/// runs inside the snapshot builder's actor.
///
/// A week is Monday to Sunday and its averages and week-over-week changes come from `WeeklyDigestEngine`,
/// the classic digest's engine; a month is a calendar month compared with the one before through the same
/// `ComparisonEngine`. The Trends tab's THIS WEEK card and the digest it opens read the SAME period, so they
/// print the same three numbers. Strain's still-counting today is left out of a period that has other
/// Strain days, as the Trend View leaves it out of its averages.
enum PulseDigestBuilder {

    // MARK: Periods

    /// One pillar's average over a period and the period before.
    struct Pair: Equatable {
        let current: Double?
        let previous: Double?
    }

    struct Period: Equatable {
        let window: PulseTrendMath.Window
        let previous: PulseTrendMath.Window
        let sleep: Pair
        let recovery: Pair
        let strain: Pair
        /// Today's Strain was left out (it is still counting).
        let strainSkipsToday: Bool
    }

    static func window(_ mode: WeeklyDigestSnapshot.Mode, today: String, page: Int,
                       earliest: String?) -> (current: PulseTrendMath.Window, previous: PulseTrendMath.Window)? {
        switch mode {
        case .week:
            guard let w = PulseTrendMath.weekWindow(containing: today, weeksBack: page, earliest: earliest),
                  let p = PulseTrendMath.weekWindow(containing: today, weeksBack: page + 1) else { return nil }
            return (w, p)
        case .month:
            guard let w = PulseTrendMath.monthWindow(containing: today, monthsBack: page, earliest: earliest),
                  let p = PulseTrendMath.monthWindow(containing: today, monthsBack: page + 1) else { return nil }
            return (w, p)
        }
    }

    static func period(_ mode: WeeklyDigestSnapshot.Mode, today: String, page: Int, sleep: PulseTrendSeries,
                       recovery: PulseTrendSeries, strain: PulseTrendSeries) -> Period? {
        let earliest = [sleep.earliest, recovery.earliest, strain.earliest].compactMap { $0 }.min()
        guard let (w, prev) = window(mode, today: today, page: page, earliest: earliest) else { return nil }
        var strainPoints = strain.points
        var skipsToday = false
        if w.contains(today), strainPoints.contains(where: { $0.day == today }),
           strainPoints.contains(where: { $0.day != today && w.contains($0.day) }) {
            strainPoints.removeAll { $0.day == today }
            skipsToday = true
        }
        func map(_ points: [PulseTrendMath.Point]) -> [String: Double] {
            Dictionary(points.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        }
        switch mode {
        case .week:
            // The classic digest's engine, on Pulse's resolved series (Strain already on 0–21, which only
            // the engine's unused balance read and focal sentences would care about).
            let digest = WeeklyDigestEngine.build(byMetric: [.charge: map(recovery.points),
                                                             .effort: map(strainPoints),
                                                             .rest: map(sleep.points)],
                                                  anchorDay: w.start)
            func pair(_ metric: WeeklyMetric) -> Pair {
                guard let s = digest.summary(metric) else { return Pair(current: nil, previous: nil) }
                return Pair(current: s.thisWeek.n > 0 ? s.thisWeek.mean : nil,
                            previous: s.weekOverWeek.previous.n > 0 ? s.weekOverWeek.previous.mean : nil)
            }
            return Period(window: w, previous: prev, sleep: pair(.rest), recovery: pair(.charge),
                          strain: pair(.effort), strainSkipsToday: skipsToday)
        case .month:
            func pair(_ points: [PulseTrendMath.Point]) -> Pair {
                let c = ComparisonEngine.compare(current: PulseTrendMath.points(points, in: w).map(\.value),
                                                 previous: PulseTrendMath.points(points, in: prev).map(\.value))
                return Pair(current: c.current.n > 0 ? c.current.mean : nil,
                            previous: c.previous.n > 0 ? c.previous.mean : nil)
            }
            return Period(window: w, previous: prev, sleep: pair(sleep.points), recovery: pair(recovery.points),
                          strain: pair(strainPoints), strainSkipsToday: skipsToday)
        }
    }

    /// "▲ 4% vs. last week": a percent for Sleep and Recovery, absolute points for Strain; grey for Recovery
    /// and Strain as on the Trend View, "● 0%" when the two print the same.
    static func chip(_ score: PulseScore, _ pair: Pair, mode: WeeklyDigestSnapshot.Mode,
                     compact: Bool = false) -> PulseTrendChip? {
        guard let current = pair.current, let previous = pair.previous,
              let change = PulseTrendMath.change(current: current, previous: previous) else { return nil }
        let phrase = mode == .week ? String(localized: "vs. last week") : String(localized: "vs. last month")
        let magnitude: String
        let delta: Double
        switch score {
        case .strain:
            let shown = PulseFormat.oneDecimal(abs(change.delta))
            magnitude = shown
            delta = shown == PulseFormat.oneDecimal(0) ? 0 : change.delta
        case .sleep, .recovery:
            let pct = Int(abs(change.percent ?? 0).rounded())
            magnitude = "\(pct)%"
            delta = pct == 0 || PulseFormat.whole(current) == PulseFormat.whole(previous) ? 0 : change.delta
        }
        let polarity: PulseMetricPolarity = score == .sleep ? .higherIsBetter : .neutral
        return PulseTrendChip(text: compact ? magnitude : "\(magnitude) \(phrase)",
                              trend: PulseTrend(delta: delta, polarity: polarity))
    }

    /// A pillar's ring content: Sleep and Recovery in percent (Recovery in its band colour), Strain on 0–21.
    static func ring(_ score: PulseScore, value: Double?, label: String? = nil) -> PulseDialContent {
        let name = label ?? score.displayName
        switch score {
        case .sleep: return .percent(label: name, percent: value, color: PulseTheme.sleep)
        case .recovery:
            return .percent(label: name, percent: value,
                            color: value.map { PulseTheme.recovery(percent: $0) } ?? PulseTheme.textTertiary)
        case .strain: return .strain(label: name, value: value, optimalRange: nil, target: nil)
        }
    }

    static func valueText(_ score: PulseScore, _ value: Double?) -> String {
        guard let value else { return "--" }
        return score == .strain ? PulseFormat.oneDecimal(value) : "\(PulseDisplay.displayedPercent(value))%"
    }

    /// "Sep 28 - Oct 4" for a week (both years once it crosses one), "October 2026" for a month.
    static func title(_ mode: WeeklyDigestSnapshot.Mode, _ w: PulseTrendMath.Window) -> String {
        switch mode {
        case .month:
            return PulseFormat.dayLabel(w.start, template: "MMMMy")
        case .week:
            let startYear = PulseFormat.dayLabel(w.start, template: "yy")
            let endYear = PulseFormat.dayLabel(w.end, template: "yy")
            let start = PulseFormat.dayLabel(w.start, template: "MMMd")
            let end = PulseFormat.dayLabel(w.end, template: "MMMd")
            return startYear == endYear ? "\(start) - \(end)" : "\(start), \(startYear) - \(end), \(endYear)"
        }
    }

    // MARK: Trends tab

    /// The metrics every Trends tab shows, with or without readings; the others appear once they have one.
    static let coreMetrics: Set<String> = ["sleep_performance", "sleep_total_min", "recovery", "hrv", "rhr",
                                           "strain", "steps", "stress"]

    static func tab(seq: Int, today: String, series: [String: PulseTrendSeries]) -> TrendsTabSnapshot {
        let empty = PulseTrendSeries()
        let sleep = series[PulseTrendMetric.sleepPerformance.key] ?? empty
        let recovery = series[PulseTrendMetric.recovery.key] ?? empty
        let strain = series[PulseTrendMetric.dayStrain.key] ?? empty
        let period = Self.period(.week, today: today, page: 0, sleep: sleep, recovery: recovery, strain: strain)
        var week: [TrendsTabSnapshot.WeekLine] = []
        if let period {
            for (score, pair) in [(PulseScore.sleep, period.sleep), (.recovery, period.recovery), (.strain, period.strain)] {
                let chip = Self.chip(score, pair, mode: .week)
                let value = valueText(score, pair.current)
                week.append(.init(score: score, ring: ring(score, value: pair.current), value: value, chip: chip,
                                  accessibility: String(localized: "\(score.displayName) this week, \(value)")
                                      + (chip.map { ", \($0.text), \($0.trend.accessibilityDescription)" } ?? "")))
            }
        }
        var sections: [TrendsTabSnapshot.Section] = []
        for pillar in PulseTrendPillar.allCases {
            let rows = PulseTrendMetric.curated.filter { $0.pillar == pillar }.compactMap { m in
                row(m, series[m.key] ?? empty, today: today)
            }
            if !rows.isEmpty { sections.append(.init(pillar: pillar, rows: rows)) }
        }
        return TrendsTabSnapshot(
            seq: seq, weekTitle: period.map { title(.week, $0.window) } ?? "", week: week,
            weekNote: period?.strainSkipsToday == true ? String(localized: "Strain leaves out today until it ends") : nil,
            sections: sections)
    }

    /// One metric's row, or nil for a metric outside the core set that has no reading.
    static func row(_ m: PulseTrendMetric, _ s: PulseTrendSeries, today: String) -> TrendsTabSnapshot.Row? {
        let format: PulseTrendValueFormat = s.signed ? .signedOneDecimal : m.format
        let unit = s.unit ?? m.unit
        let byDay = Dictionary(s.points.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let spark = PulseDisplay.trailingDayKeys(endingOn: today, count: 7).map { byDay[$0] }
        let color: Color = m.key == "recovery" ? PulseTheme.recoveryBlue : (m.key == "stress" ? PulseTheme.Stress.medium : m.color)
        func text(_ v: Double) -> String { format.text(v) }
        func spokenValue(_ v: Double) -> String { "\(format.text(v)) \(unit)" }
        guard let latest = s.points.last else {
            guard coreMetrics.contains(m.key) else { return nil }
            return .init(id: m.key, title: m.rowTitle, symbol: m.symbol, value: nil, unit: "",
                         caption: String(localized: "No readings yet"), trend: nil, baseline: nil, spark: spark,
                         color: color, accessibility: String(localized: "\(m.rowTitle), no readings yet"))
        }
        let history = s.points.map { (day: $0.day, value: $0.value) }

        if m.aggregation == .weeklyTotal {
            // Minutes from logged activities: the last seven days' total against the four weeks before.
            guard let w = PulseTrendMath.window(.week, anchor: today, earliest: s.earliest) else { return nil }
            let total = PulseTrendMath.points(s.points, in: w).reduce(0) { $0 + $1.value }
            let before = PulseTrendMath.Window(start: PulseTrendMath.addDays(w.start, -28),
                                               end: PulseTrendMath.addDays(w.start, -1), page: 0, dayCount: 28,
                                               hasOlder: false)
            let reference = PulseTrendMath.averageWeeklyTotal(s.points, in: before)
            let trend = reference.map { ref in
                PulseTrend(delta: format.text(total) == format.text(ref) ? 0 : total - ref, polarity: m.polarity)
            }
            return .init(id: m.key, title: m.rowTitle, symbol: m.symbol, value: text(total), unit: unit,
                         caption: String(localized: "Last 7 days"), trend: trend, baseline: reference.map(text),
                         spark: spark, color: color,
                         accessibility: String(localized: "\(m.rowTitle), \(spokenValue(total)) in the last 7 days"))
        }

        let comparison = PulseDisplay.compare(value: latest.value, history: history, dayKey: latest.day)
        let baseline = comparison.map { text($0.reference) }
        if m.isRunningTotal && latest.day == today {
            // Still counting: no arrow against full days, as Home's tiles say "So far today".
            return .init(id: m.key, title: m.rowTitle, symbol: m.symbol, value: text(latest.value), unit: unit,
                         caption: String(localized: "So far today"), trend: nil, baseline: baseline, spark: spark,
                         color: color,
                         accessibility: String(localized: "\(m.rowTitle), \(spokenValue(latest.value)) so far today"))
        }
        let trend = comparison.map { c in
            PulseTrend(delta: text(latest.value) == text(c.reference) ? 0 : latest.value - c.reference,
                       polarity: m.polarity)
        }
        let caption = latest.day == today ? nil : PulseFormat.dayLabel(latest.day, template: "MMMd")
        var spoken = "\(m.rowTitle), \(spokenValue(latest.value))"
        if let caption { spoken += ", \(caption)" }
        if let trend { spoken += ", \(trend.accessibilityDescription)" }
        if let baseline { spoken += ", " + String(localized: "30-day average \(baseline)") }
        return .init(id: m.key, title: m.rowTitle, symbol: m.symbol, value: text(latest.value), unit: unit,
                     caption: caption, trend: trend, baseline: baseline, spark: spark, color: color,
                     accessibility: spoken)
    }

    // MARK: Weekly Digest

    struct DigestInputs {
        let sleep: PulseTrendSeries
        let recovery: PulseTrendSeries
        let strain: PulseTrendSeries
        let hours: PulseTrendSeries
        let zones13: PulseTrendSeries
        let zones45: PulseTrendSeries
        let journal: [JournalEntry]
    }

    static func digest(seq: Int, today: String, mode: WeeklyDigestSnapshot.Mode, page requested: Int,
                       inputs: DigestInputs) -> WeeklyDigestSnapshot? {
        let earliest = [inputs.sleep.earliest, inputs.recovery.earliest, inputs.strain.earliest].compactMap { $0 }.min()
        // Clamp the page to the history: no page before the first reading.
        var page = max(0, requested)
        while page > 0, let w = window(mode, today: today, page: page, earliest: earliest)?.current,
              let e = earliest, w.end < e {
            page -= 1
        }
        guard let period = period(mode, today: today, page: page, sleep: inputs.sleep, recovery: inputs.recovery,
                                  strain: inputs.strain) else { return nil }
        let w = period.window
        let pillars: [WeeklyDigestSnapshot.Pillar] = [
            (PulseScore.sleep, period.sleep, PulseTrendMetric.sleepPerformance.key),
            (.recovery, period.recovery, PulseTrendMetric.recovery.key),
            (.strain, period.strain, PulseTrendMetric.dayStrain.key)
        ].map { score, pair, key in
            .init(score: score, content: ring(score, value: pair.current), chip: chip(score, pair, mode: mode, compact: true),
                  route: .trendView(metric: key))
        }
        let hasData = pillars.contains { !$0.content.isPlaceholder }
        let cards = [
            card(PulseTrendMetric.recovery, inputs.recovery, window: w, today: today, mode: mode),
            card(PulseTrendMetric.dayStrain, inputs.strain, window: w, today: today, mode: mode),
            card(PulseTrendMetric.sleepPerformance, inputs.sleep, window: w, today: today, mode: mode)
        ]
        return WeeklyDigestSnapshot(
            seq: seq, mode: mode, page: page,
            pager: PulseTrendPager(title: title(mode, w), canGoBack: w.hasOlder, canGoForward: page > 0,
                                   accessibility: PulseTrendPageBuilder.pagerAccessibility(w)),
            hasData: hasData, pillars: pillars,
            note: period.strainSkipsToday ? String(localized: "Strain leaves out today until it ends") : nil,
            cards: cards, highlights: highlights(inputs, window: w),
            behaviors: behaviors(inputs, window: w, today: today),
            insight: insight(period, mode: mode, inputs: inputs))
    }

    /// A Weekly Trends card (the deep dives' look): the period's days as bars, value labels on a week.
    private static func card(_ m: PulseTrendMetric, _ s: PulseTrendSeries, window w: PulseTrendMath.Window,
                             today: String, mode: WeeklyDigestSnapshot.Mode) -> WeeklyDigestSnapshot.TrendCard {
        let byDay = Dictionary(s.points.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let keys = w.dayKeys
        let data: [PulseChartDatum] = keys.enumerated().map { i, k in
            let v = byDay[k]
            let color: Color = m.key == "recovery" ? (v.map { PulseTheme.recovery(percent: $0) } ?? m.color) : m.color
            let label: String
            let sub: String?
            if mode == .week {
                label = PulseFormat.dayLabel(k, template: "EEE")
                sub = PulseFormat.dayLabel(k, template: "d")
            } else {
                // The date alone on every seventh day from the 1st (1, 8, 15, 22, 29): the pager already names
                // the month, and a one- or two-digit label fits even the edge columns.
                label = i % 7 == 0 ? PulseFormat.dayLabel(k, template: "d") : ""
                sub = nil
            }
            let valueLabel: String? = mode == .week ? v.map { m.unit == "%" ? "\(PulseDisplay.displayedPercent($0))%" : m.format.text($0) } : nil
            return PulseChartDatum(id: k, label: label, sublabel: sub, value: v, color: color, valueLabel: valueLabel)
        }
        let domain: ClosedRange<Double> = m.key == "strain" ? 0...21 : 0...100
        let grid: [Double] = m.key == "strain" ? [0, 5.25, 10.5, 15.75, 21] : [0, 25, 50, 75, 100]
        let highlight = w.contains(today) ? today : keys.last(where: { byDay[$0] != nil })
        return .init(id: m.key, title: m.title, data: data, yDomain: domain, gridValues: grid, highlightID: highlight,
                     route: .trendView(metric: m.key))
    }

    /// Best Recovery, max Strain, longest sleep and most zone time in the period, each with its day.
    private static func highlights(_ inputs: DigestInputs, window w: PulseTrendMath.Window) -> [WeeklyDigestSnapshot.Highlight] {
        func best(_ s: PulseTrendSeries) -> PulseTrendMath.Point? {
            PulseTrendMath.points(s.points, in: w).max { $0.value < $1.value }
        }
        func day(_ key: String) -> String { PulseFormat.dayLabel(key, template: "EEEMMMd") }
        var out: [WeeklyDigestSnapshot.Highlight] = []
        if let r = best(inputs.recovery) {
            out.append(.init(id: "recovery", symbol: "heart.circle", title: String(localized: "Best Recovery"), day: day(r.day),
                             value: "\(PulseDisplay.displayedPercent(r.value))", unit: "%"))
        }
        if let s = best(inputs.strain) {
            out.append(.init(id: "strain", symbol: "speedometer", title: String(localized: "Max Strain"), day: day(s.day),
                             value: PulseFormat.oneDecimal(s.value), unit: ""))
        }
        if let h = best(inputs.hours) {
            out.append(.init(id: "sleep", symbol: "moon.zzz", title: String(localized: "Longest sleep"), day: day(h.day),
                             value: PulseFormat.hoursMinutes(h.value), unit: String(localized: "hr")))
        }
        let zone13 = Dictionary(PulseTrendMath.points(inputs.zones13.points, in: w).map { ($0.day, $0.value) }, uniquingKeysWith: { _, l in l })
        let zone45 = Dictionary(PulseTrendMath.points(inputs.zones45.points, in: w).map { ($0.day, $0.value) }, uniquingKeysWith: { _, l in l })
        let zoneDays = Set(zone13.keys).union(zone45.keys)
        if let top = zoneDays.map({ ($0, (zone13[$0] ?? 0) + (zone45[$0] ?? 0)) }).max(by: { $0.1 < $1.1 }), top.1 >= 1 {
            out.append(.init(id: "zones", symbol: "heart.text.square", title: String(localized: "Most time in HR zones"),
                             day: day(top.0), value: PulseFormat.hoursMinutes(top.1), unit: String(localized: "hr")))
        }
        return out
    }

    /// Journal behaviours answered "yes" in the period, most logged first, each with its effect on Recovery
    /// over the last 90 days (`EffectRanker`, the "What moves you" ranker: lag-aware, 5 yes and 5 no days,
    /// false-discovery corrected).
    private static func behaviors(_ inputs: DigestInputs, window w: PulseTrendMath.Window,
                                  today: String) -> [WeeklyDigestSnapshot.Behavior] {
        var loggedInPeriod: [String: Int] = [:]
        for e in inputs.journal where e.answeredYes && w.contains(e.day) {
            loggedInPeriod[e.question, default: 0] += 1
        }
        guard !loggedInPeriod.isEmpty else { return [] }
        let from = PulseTrendMath.addDays(today, -89)
        var yes: [String: Set<String>] = [:]
        var no: [String: Set<String>] = [:]
        for e in inputs.journal where e.day >= from && e.day <= today {
            if e.answeredYes { yes[e.question, default: []].insert(e.day) } else { no[e.question, default: []].insert(e.day) }
        }
        var recovery: [String: Double] = [:]
        for p in inputs.recovery.points where p.day >= from { recovery[p.day] = p.value }
        let label = PulseScore.recovery.displayName
        let ranked = EffectRanker.rankAll(behaviors: yes, controls: no, outcomes: [label: recovery])[label] ?? []
        let byBehavior = Dictionary(ranked.map { ($0.behavior, $0) }, uniquingKeysWith: { first, _ in first })
        return loggedInPeriod.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.prefix(6).map { question, count in
            let logged = count == 1 ? String(localized: "Logged 1 day") : String(localized: "Logged \(count) days")
            guard let r = byBehavior[question], let pct = r.effect.pctChange else {
                return .init(id: question, title: question, logged: logged, effect: nil, fraction: 0, valueText: "",
                             note: String(localized: "Needs 5 yes and 5 no days in 90 to measure"))
            }
            let effect: PulseImpactBar.Effect = r.effect.significant ? (r.effect.delta > 0 ? .helps : .hurts) : .notSignificant
            let n = Int(pct.rounded())
            return .init(id: question, title: question, logged: logged, effect: effect,
                         fraction: max(-1, min(1, pct / 20)), valueText: n > 0 ? "+\(n)%" : "\(n)%", note: nil)
        }
    }

    /// A plain summary of the period (local text, never dressed as the Coach's).
    private static func insight(_ p: Period, mode: WeeklyDigestSnapshot.Mode, inputs: DigestInputs) -> String {
        let span = mode == .week ? String(localized: "this week") : String(localized: "this month")
        var parts: [String] = []
        let named: [(PulseScore, Pair)] = [(.recovery, p.recovery), (.sleep, p.sleep), (.strain, p.strain)]
        let shown = named.compactMap { score, pair in pair.current.map { (score, $0) } }
        guard !shown.isEmpty else {
            return mode == .week
                ? String(localized: "No Recovery, Sleep or Strain readings this week yet.")
                : String(localized: "No Recovery, Sleep or Strain readings this month yet.")
        }
        let list = shown.map { score, v in "\(score.displayName) \(valueText(score, v))" }
        parts.append(String(localized: "Your averages \(span): \(list.joined(separator: ", "))."))
        if let c = p.recovery.current, let b = p.recovery.previous {
            switch PulseTrendMath.relation(c.rounded(), reference: b.rounded()) {
            case .above: parts.append(String(localized: "Recovery ran higher than the period before (\(valueText(.recovery, b)))."))
            case .below: parts.append(String(localized: "Recovery ran lower than the period before (\(valueText(.recovery, b)))."))
            case .within: parts.append(String(localized: "Recovery held level with the period before."))
            }
        }
        if let top = PulseTrendMath.points(inputs.recovery.points, in: p.window).max(by: { $0.value < $1.value }) {
            parts.append(String(localized: "Your best Recovery came on \(PulseFormat.dayLabel(top.day, template: "EEEE")) (\(valueText(.recovery, top.value)))."))
        }
        return parts.joined(separator: " ")
    }
}
#endif
