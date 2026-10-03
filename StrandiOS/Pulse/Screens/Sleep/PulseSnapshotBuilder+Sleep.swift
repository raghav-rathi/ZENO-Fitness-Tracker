#if os(iOS)
import Foundation
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore
import WhoopProtocol

// MARK: - Sleep group builds (WHOOP_UI_SPEC §3.3, §3.11)
//
// All of this runs on the builder actor (`PulseModel.build`), off the main actor. A night is the SAME night
// everywhere: the Sleep tab's wake-day grouping (`nightGroups`) merged by `SleepModel.mergeDay`, its Sleep
// Performance through the ONE resolver Home's dial reads (`sleepPerformance`), its need and consistency
// through the ONE per-night read (`Repository.resolvedNightSleep`), its efficiency through the ONE series the
// classic Sleep Efficiency page reads (`Repository.exploreSeries`). Every "vs. prior 30 days" figure is the
// mean of the same quantity over the nights that ended in the 30 calendar days before this one, read the
// same way, so the value, its baseline and the Weekly Trends point for the same night cannot disagree.

extension PulseSnapshotBuilder {

    /// One merged night and the figures the dive compares across nights.
    struct SleepNightFacts {
        let key: String
        let night: Night
        let onsetTs: Int
        let wakeTs: Int
        let resolved: ResolvedNightSleep
        let performance: Double?
        /// SLEEP EFFICIENCY as stored for the night (spec §3.3 "Efficiency, Consistency: stored"), in percent:
        /// the figure the classic Sleep Efficiency page prints. The merged night only draws its barcode.
        let efficiency: Double?

        var asleep: Double { night.stages.asleep }
        var inBed: Double { night.stages.total }
        var restorative: Double { night.stages.deep + night.stages.rem }
        var need: Double? { resolved.needMin.flatMap { $0 > 0 ? $0 : nil } }
        /// Asleep ÷ need, capped at 100 (the merged night against the resolved need, as the dive has always
        /// divided it, so the percent and its "x of y" can never disagree).
        var hoursPct: Double? {
            guard let need, asleep > 0 else { return nil }
            return min(100, asleep / need * 100)
        }
        var consistency: Double? { resolved.consistencyPct }

        func share(_ stage: SleepStage) -> Double? {
            guard inBed > 0 else { return nil }
            switch stage {
            case .awake: return night.stages.awake / inBed
            case .light: return night.stages.light / inBed
            case .deep: return night.stages.deep / inBed
            case .rem: return night.stages.rem / inBed
            }
        }
    }

    /// NOOP's stored per-night figures (need, its parts, consistency), read once per refresh in one hop.
    func sleepComputedFigures() async -> [String: ComputedSleepFigures] {
        await cached("sleep.computed") { await repo.computedSleep }
    }

    /// Each night's stored SLEEP EFFICIENCY in percent, by wake day, read once per refresh through the
    /// series the classic Sleep Efficiency page draws (`Repository.exploreSeries`: an import over NOOP's own
    /// computed value over the day's stored column). The stored column is a 0–1 fraction where an import
    /// writes 0–100; anything over 1.5 is already a percent, the classic Sleep screen's own test.
    func sleepEfficiencyByNight() async -> [String: Double] {
        await cached("sleep.efficiency") {
            let series = await repo.exploreSeries(key: "sleep_efficiency", source: "my-whoop")
            var out: [String: Double] = [:]
            for point in series where point.value.isFinite && point.value > 0 {
                out[point.day] = min(100, point.value > 1.5 ? point.value : point.value * 100)
            }
            return out
        }
    }

    /// The sleep metrics whose classic detail page holds at least one reading (the question the Explore
    /// list asks for its "no data" dot), so a card is never routed to an empty page while Trend View is
    /// being rebuilt. Read once per refresh.
    func sleepMetricPagesWithData() async -> Set<String> {
        await cached("sleep.metricPages") {
            let keys = Set(PulseSleepRoutes.metricKeys)
            let descriptors = MetricCatalog.all.filter { keys.contains($0.key) && $0.source == "my-whoop" }
            let ids = await repo.nonEmptyMetricIDs(descriptors)
            return Set(descriptors.filter { ids.contains($0.id) }.map(\.key))
        }
    }

    // MARK: - The dive

    /// The Sleep dive for the night that ended on `anchorKey` (a wake day key the wearer stepped to), or on
    /// Home's day when nil. A day with no banked night is that day's empty night ("No sleep was recorded"),
    /// never an older night under the day's title (§1.7: the dive mirrors Home's day); ‹ › step to the
    /// nearest banked nights either side. Nights are addressed by wake day, never by position, so a night
    /// banked while the screen is open cannot swap what it shows.
    func sleepDive(_ r: PulseRequest, onOrBefore anchorKey: String?) async -> SleepDiveSnapshot? {
        begin(r.seq)
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let rest = await restSeries()
        let computed = await sleepComputedFigures()
        let efficiencies = await sleepEfficiencyByNight()
        let metricPages = await sleepMetricPagesWithData()
        guard isCurrent(r) else { return nil }

        // `navDays` groups blocks by the local day they END on, newest first.
        var keys: [String] = []
        var groupByKey: [String: [CachedSleepSession]] = [:]
        for group in groups {
            let key = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(group.first?.endTs ?? 0)))
            guard groupByKey[key] == nil else { continue }
            groupByKey[key] = group
            keys.append(key)
        }
        keys.sort(by: >)
        #if DEBUG
        // `--sleep-drop-night`: capture Home's day as a day whose night was never recorded (the demo seed
        // banks a night every day). Nothing is invented: the night is only left out.
        if PulseSleepDebug.dropsHomeNight {
            groupByKey[r.day.key] = nil
            keys.removeAll { $0 == r.day.key }
        }
        #endif
        let daysByKey = Dictionary(r.days.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })

        #if DEBUG
        let debugTimeline: SleepNeedTimeline? = PulseSleepDebug.computedNeed
            ? SleepNeed.timeline(days: r.days.map { SleepNeedDay(day: $0.day, mainSleepMin: $0.totalSleepMin,
                                                                  effort: $0.strain) }, age: nil)
            : nil
        #endif
        var memo: [String: SleepNightFacts?] = [:]
        func facts(_ key: String) -> SleepNightFacts? {
            if let hit = memo[key] { return hit }
            var out: SleepNightFacts?
            if let group = groupByKey[key],
               let night = SleepModel.mergeDay(group, habitualMidsleepSec: habitual, motionByStart: [:]) {
                var resolved = Repository.resolvedNightSleep(day: key, daily: daysByKey[key],
                                                             imported: r.importedSleep, computed: computed)
                #if DEBUG
                // `--sleep-computed-need`: the demo seed writes an export's need (a total, no parts) and has
                // no strap nights for the engine to store a breakdown for, so a capture can ask for the
                // unified model's own need and parts, resolved over the same history the engine would use
                // (`SleepNeed.timeline`). DEBUG only; a real night shows only what the engine stored.
                if PulseSleepDebug.computedNeed, let b = computed[key]?.needBreakdown ?? debugTimeline?.need(forNightEnding: key) {
                    resolved = ResolvedNightSleep(day: key, restScore: resolved.restScore, needMin: b.totalMin,
                                                  needBreakdown: b, consistencyPct: resolved.consistencyPct,
                                                  hoursVsNeededPct: resolved.hoursVsNeededPct,
                                                  debtMin: resolved.debtMin, restIsImported: resolved.restIsImported)
                }
                #endif
                out = SleepNightFacts(key: key, night: night, onsetTs: night.session.effectiveStartTs,
                                      wakeTs: night.session.endTs, resolved: resolved,
                                      performance: sleepPerformance(dayKey: key, rest: rest, days: r.days),
                                      efficiency: efficiencies[key])
            }
            memo[key] = .some(out)
            return out
        }

        let key = anchorKey ?? r.day.key
        let group = groupByKey[key] ?? []
        let tonight = facts(key)
        // The dial is Home's own resolver for the day, so the two always agree (a day with a score but no
        // night to break down shows the score over empty cards).
        var perf = sleepPerformance(dayKey: key, rest: rest, days: r.days)
        #if DEBUG
        if PulseSleepDebug.dropsHomeNight && key == r.day.key { perf = nil }
        #endif
        let dial = PulseDialData(score: .sleep, value: perf, state: perf == nil ? .noData : .scored)

        // The 30 calendar days before the night, oldest first, and the nights that ended on them.
        let window = PulseDisplay.trailingDayKeys(endingOn: key, count: 31)
        let priorKeys = Array(window.dropLast())
        let prior = priorKeys.compactMap { facts($0) }

        // MARK: Contributors
        let consistencyCalibrating = tonight != nil && tonight?.consistency == nil
        let contributors = [
            SleepContributorRow(kind: .hours, title: String(localized: "Hours vs. needed"),
                                percent: tonight?.hoursPct, calibrating: false,
                                band: Self.sleepBand(.hours, tonight?.hoursPct), metric: "hours_vs_needed_pct"),
            SleepContributorRow(kind: .consistency, title: String(localized: "Sleep consistency"),
                                percent: tonight?.consistency, calibrating: consistencyCalibrating,
                                band: Self.sleepBand(.consistency, tonight?.consistency), metric: "sleep_consistency"),
            SleepContributorRow(kind: .efficiency, title: String(localized: "Sleep efficiency"),
                                percent: tonight?.efficiency, calibrating: false,
                                band: Self.sleepBand(.efficiency, tonight?.efficiency), metric: "sleep_efficiency"),
            // Filled in by the stress build that follows this one.
            SleepContributorRow(kind: .stress, title: String(localized: "High sleep stress"), percent: nil,
                                calibrating: false, band: nil, metric: "sleep_stress"),
        ]

        // MARK: Last Night's Sleep
        var lastNight: SleepLastNight?
        var sleepingHR: Int?
        var lowestHR: Int?
        if let tonight {
            let span = max(tonight.wakeTs - tonight.onsetTs, 60)
            let pad = max(15 * 60, Int(Double(span) * 0.1))
            let chartFrom = tonight.onsetTs - pad
            let chartTo = tonight.wakeTs + pad
            let buckets = await repo.hrBuckets(from: chartFrom, to: chartTo, bucketSeconds: 60)
            guard isCurrent(r) else { return nil }
            let runs = hrGapSegments(bucketTs: buckets.map(\.ts), bucketSeconds: 60)
            let hr = buckets.enumerated().map { i, b in
                SleepHRPoint(date: Date(timeIntervalSince1970: TimeInterval(b.ts)), bpm: b.bpm,
                             run: runs.indices.contains(i) ? runs[i] : "a")
            }
            let inside = buckets.filter { $0.ts >= tonight.onsetTs && $0.ts <= tonight.wakeTs }.map(\.bpm)
            if !inside.isEmpty {
                sleepingHR = Int((inside.reduce(0, +) / Double(inside.count)).rounded())
                lowestHR = inside.min().map { Int($0.rounded()) }
            }
            lastNight = Self.lastNight(tonight, prior: prior, hr: hr, chartFrom: chartFrom, chartTo: chartTo)
        }

        // MARK: Detail cards
        let hoursVsNeeded = tonight.map { Self.hoursVsNeeded($0, prior: prior) }
        let consistency = tonight.map { night -> SleepConsistencyCard in
            let fiveKeys = Array(window.suffix(5))
            let nineKeys = PulseDisplay.trailingDayKeys(endingOn: key, count: 9)
            return Self.consistencyCard(night, prior: prior, fiveKeys: fiveKeys,
                                        timingNights: nineKeys.compactMap { facts($0) })
        }
        let efficiency = tonight.map { night in
            Self.efficiencyCard(night, prior: prior, wakeEvents: daysByKey[key]?.disturbances)
        }

        // MARK: Weekly Trends: the seven days ending on the night's wake day, a night or not.
        let weekKeys = PulseDisplay.trailingDayKeys(endingOn: key, count: 7)
        let weekly = weekKeys.map { day -> SleepWeekNight in
            // The night shown takes the dial's own figure, so its bar and the ring cannot differ.
            Self.weekNight(day, facts: facts(day),
                           performance: day == key ? perf : sleepPerformance(dayKey: day, rest: rest, days: r.days))
        }

        let napList = tonight == nil ? [] : naps(in: group, night: tonight?.night)
        let summary = Self.sleepSummary(perf: perf, night: tonight, contributors: contributors)
        let stress = tonight.map { night in
            SleepStressRequest(nightKey: key, onset: Date(timeIntervalSince1970: TimeInterval(night.onsetTs)),
                               wake: Date(timeIntervalSince1970: TimeInterval(night.wakeTs)),
                               prior: prior.reversed().map {
                                   SleepStressNight(key: $0.key, onsetTs: $0.onsetTs, wakeTs: $0.wakeTs)
                               })
        }
        let edit = tonight?.night.editTarget.map(SleepTimeEdit.init(night:))
        let addWindow = edit == nil ? Self.addNightWindow(endingOn: key, prior: prior, now: r.now) : nil
        guard isCurrent(r) else { return nil }
        return SleepDiveSnapshot(
            seq: r.seq, requestDayKey: r.day.key, todayKey: Repository.localDayKey(r.now), nightKeys: keys,
            wakeDayKey: key, hasNight: tonight != nil, olderKey: keys.first { $0 < key },
            newerKey: keys.last { $0 > key }, dial: dial, contributors: contributors, summary: summary,
            lastNight: lastNight, edit: edit, addWindow: addWindow,
            hoursVsNeeded: hoursVsNeeded, consistency: consistency, efficiency: efficiency,
            stress: stress, weekly: weekly, naps: napList, sleepingHR: sleepingHR, lowestHR: lowestHR,
            respRate: tonight == nil ? nil : daysByKey[key]?.respRateBpm, metricPages: metricPages)
    }

    /// The night ADD ACTIVITY opens on from EDIT when there is nothing to edit, the one that ends on `key`:
    /// from when the wearer usually falls asleep to when they usually wake, the medians (on `PulseDisplay`'s
    /// noon clock) of the last `TonightSleepPlan.habitNights` nights before it once there are `minHabitNights`
    /// of them, else 23:00 to 07:00, cut off at `now`. nil when that is not a sleep the form can save (under
    /// 10 minutes so far, or over 18 hours), so the form opens on its own default.
    static func addNightWindow(endingOn key: String, prior: [SleepNightFacts], now: Date,
                               calendar cal: Calendar = .current) -> ClosedRange<Date>? {
        let recent = prior.suffix(TonightSleepPlan.habitNights)
        let habit = recent.count >= TonightSleepPlan.minHabitNights
        func minute(_ ts: Int) -> Int {
            let c = cal.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: TimeInterval(ts)))
            return (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
        let bedMinute = (habit ? PulseDisplay.medianClockMinute(recent.map { minute($0.onsetTs) }) : nil) ?? 23 * 60
        let wakeMinute = (habit ? PulseDisplay.medianClockMinute(recent.map { minute($0.wakeTs) }) : nil)
            ?? TonightSleepPlan.typicalWakeMinute
        let day = key.split(separator: "-").compactMap { Int($0) }
        guard day.count == 3,
              let wake = cal.date(from: DateComponents(year: day[0], month: day[1], day: day[2],
                                                       hour: wakeMinute / 60, minute: wakeMinute % 60))
        else { return nil }
        let bed = TonightSleepPlan.occurrence(ofMinute: Double(bedMinute), before: wake, calendar: cal)
        let end = min(wake, now)
        let span = end.timeIntervalSince(bed)
        guard span >= 10 * 60, span <= 18 * 3600 else { return nil }
        return bed...end
    }

    // MARK: Contributor bands (§3.3 item 3 thresholds)

    /// 0 Poor / 1 Sufficient / 2 Optimal, judged on the whole percent the row prints.
    static func sleepBand(_ kind: SleepContributorRow.Kind, _ percent: Double?) -> Int? {
        guard let percent else { return nil }
        let shown = PulseDisplay.displayedPercent(percent)
        switch kind {
        case .hours: return shown >= 85 ? 2 : (shown >= 70 ? 1 : 0)
        case .consistency: return shown >= 80 ? 2 : (shown >= 70 ? 1 : 0)
        case .efficiency: return shown >= 90 ? 2 : (shown >= 80 ? 1 : 0)
        // Lower is better: under 1% Optimal, 1–5% Sufficient, over 5% Poor.
        case .stress: return shown < 1 ? 2 : (shown <= 5 ? 1 : 0)
        }
    }

    // MARK: Figures

    /// A value against the mean of `history` (five or more prior nights), trend judged on the printed
    /// figures: a grey dot only when the two print the same.
    static func sleepFigure(_ value: Double?, history: [Double], polarity: PulseMetricPolarity, unit: String?,
                            name: String, format: (Double) -> String) -> SleepFigure {
        guard let value, value.isFinite else {
            return SleepFigure(value: unit == "%" ? "--" : "-:--", unit: unit == "%" ? "%" : nil, baseline: nil,
                               trend: nil, spoken: String(localized: "\(name), no data"))
        }
        let shown = format(value)
        let reference = history.count >= 5 ? history.reduce(0, +) / Double(history.count) : nil
        let baseline = reference.map(format)
        let trend = reference.map { ref in
            PulseTrend(delta: shown == format(ref) ? 0 : value - ref, polarity: polarity)
        }
        let printed = unit.map { shown + $0 } ?? shown
        var spoken = "\(name), \(printed)"
        if let baseline {
            spoken += ", " + String(localized: "prior 30 days \(unit.map { baseline + $0 } ?? baseline)")
        }
        if let trend { spoken += ", " + trend.accessibilityDescription }
        let printedBaseline = baseline.map { b -> String in unit.map { b + $0 } ?? b }
        return SleepFigure(value: shown, unit: unit, baseline: printedBaseline, trend: trend, spoken: spoken)
    }

    static func percentText(_ v: Double) -> String { "\(PulseDisplay.displayedPercent(v))" }

    // MARK: HOURS OF SLEEP

    static func lastNight(_ t: SleepNightFacts, prior: [SleepNightFacts], hr: [SleepHRPoint], chartFrom: Int,
                          chartTo: Int) -> SleepLastNight {
        let onset = Date(timeIntervalSince1970: TimeInterval(t.onsetTs))
        let wake = Date(timeIntervalSince1970: TimeInterval(t.wakeTs))
        let span = Double(max(t.wakeTs - t.onsetTs, 1))
        let real = t.night.realSegments != nil
        let intervals = real ? t.night.intervals : []

        let order: [(SleepStage, String)] = [
            (.awake, String(localized: "Awake")), (.light, String(localized: "Light")),
            (.deep, String(localized: "SWS (Deep)")), (.rem, String(localized: "REM")),
        ]
        let stages = order.map { stage, title -> SleepStageLine in
            let share = t.share(stage) ?? 0
            let minutes: Double
            switch stage {
            case .awake: minutes = t.night.stages.awake
            case .light: minutes = t.night.stages.light
            case .deep: minutes = t.night.stages.deep
            case .rem: minutes = t.night.stages.rem
            }
            let shares = prior.compactMap { $0.share(stage) }.sorted()
            let typical: ClosedRange<Double>? = shares.count >= 5
                ? quantile(shares, 0.25)...quantile(shares, 0.75) : nil
            let segments = mergedRuns(intervals.filter { $0.stage == stage }, span: span)
            return SleepStageLine(stage: stage, title: title, share: share,
                                  percentText: "\(Int((share * 100).rounded()))%",
                                  durationText: PulseFormat.hoursMinutes(minutes), typical: typical,
                                  segments: segments)
        }
        let spans = intervals.map {
            SleepStageSpan(stage: $0.stage, start: onset.addingTimeInterval($0.start),
                           end: onset.addingTimeInterval($0.end))
        }

        // The y axis WHOOP prints: 30 / 50 / 70 / 90 … in 20 bpm steps from 30, the last label at or under
        // the highest bucket, the plot running a little past it (deep-dives-2026/12, 15).
        let bpms = hr.map(\.bpm)
        let low = bpms.min() ?? 50
        let high = bpms.max() ?? 90
        let start = low < 32 ? floor((low - 2) / 20) * 20 + 10 : 30
        var yValues: [Double] = [start]
        while let last = yValues.last, last + 20 <= max(high, start + 60) { yValues.append(last + 20) }
        let yDomain = (start - 4)...max(high + 6, (yValues.last ?? 90) + 8)

        // Latency only for a night whose bounds were set by hand: a detected night has none to show. The
        // night's own blocks are the ones overlapping it (a nap on the same day is not).
        var latency: String?
        let edited = t.night.sourceBlocks.contains {
            $0.userEdited && $0.effectiveStartTs < t.wakeTs && $0.endTs > t.onsetTs
        }
        if edited, real {
            let firstAsleep = intervals.first { $0.stage != .awake }?.start ?? 0
            latency = PulseFormat.hoursMinutes(max(0, firstAsleep) / 60)
        }

        let hours = sleepFigure(t.asleep, history: prior.map(\.asleep), polarity: .higherIsBetter, unit: nil,
                                name: String(localized: "Hours of sleep"), format: PulseFormat.hoursMinutes)
        let restorative = sleepFigure(t.restorative, history: prior.map(\.restorative), polarity: .higherIsBetter,
                                      unit: nil, name: String(localized: "Restorative sleep"),
                                      format: PulseFormat.hoursMinutes)
        return SleepLastNight(
            hours: hours, hr: hr, onset: onset, wake: wake,
            chartStart: Date(timeIntervalSince1970: TimeInterval(chartFrom)),
            chartEnd: Date(timeIntervalSince1970: TimeInterval(chartTo)),
            onsetLabel: PulseFormat.clock(onset), wakeLabel: PulseFormat.clock(wake),
            yDomain: yDomain, yValues: yValues, durationText: PulseFormat.hoursMinutes(t.inBed),
            stages: stages, spans: spans, restorative: restorative, latency: latency, hasTimeline: real)
    }

    /// Linear-interpolated quantile of an already-sorted, non-empty array (the typical-range box).
    private static func quantile(_ sorted: [Double], _ q: Double) -> Double {
        guard sorted.count > 1 else { return sorted.first ?? 0 }
        let pos = q * Double(sorted.count - 1)
        let lo = Int(pos)
        let hi = min(lo + 1, sorted.count - 1)
        return sorted[lo] + (pos - Double(lo)) * (sorted[hi] - sorted[lo])
    }

    /// Stage intervals (seconds from the night's start) as merged fractions of the night.
    static func mergedRuns(_ intervals: [SleepInterval], span: Double) -> [ClosedRange<Double>] {
        guard span > 0 else { return [] }
        var out: [ClosedRange<Double>] = []
        for iv in intervals.sorted(by: { $0.start < $1.start }) where iv.end > iv.start {
            let lo = max(0, min(1, iv.start / span))
            let hi = max(0, min(1, iv.end / span))
            guard hi > lo else { continue }
            if let last = out.last, lo <= last.upperBound + 0.0005 {
                out[out.count - 1] = last.lowerBound...max(last.upperBound, hi)
            } else {
                out.append(lo...hi)
            }
        }
        return out
    }

    // MARK: HOURS VS. NEEDED

    static func hoursVsNeeded(_ t: SleepNightFacts, prior: [SleepNightFacts]) -> SleepHoursVsNeeded {
        let figure = sleepFigure(t.hoursPct, history: prior.compactMap(\.hoursPct), polarity: .higherIsBetter,
                                 unit: "%", name: String(localized: "Hours vs. needed"), format: percentText)
        var rows: [SleepHoursVsNeeded.Row] = []
        var minimum = t.need ?? 0
        var strain = 0.0
        var debt = 0.0
        if let b = t.resolved.needBreakdown {
            minimum = max(0, b.baselineMin - b.napCreditMin)
            strain = b.strainMin
            debt = b.debtMin
            rows.append(.init(id: "minimum", swatch: .minimum, title: String(localized: "Healthy Minimum"),
                              value: PulseFormat.hoursMinutes(b.baselineMin), dimmed: true))
            if b.napCreditMin >= 0.5 {
                rows.append(.init(id: "naps", swatch: .none, title: String(localized: "Recent Naps"),
                                  value: signed(-b.napCreditMin), dimmed: false))
            }
            rows.append(.init(id: "strain", swatch: .strain, title: String(localized: "Recent Strain"),
                              value: signed(b.strainMin), dimmed: false))
            rows.append(.init(id: "debt", swatch: .debt, title: String(localized: "Sleep Debt"),
                              value: signed(b.debtMin), dimmed: false))
        }
        return SleepHoursVsNeeded(figure: figure, hoursMin: t.asleep, needMin: t.need,
                                  hoursText: PulseFormat.hoursMinutes(t.asleep),
                                  needText: t.need.map(PulseFormat.hoursMinutes),
                                  minimumMin: minimum, strainMin: strain, debtMin: debt, rows: rows)
    }

    /// "+0:35" / "-2:07".
    static func signed(_ minutes: Double) -> String {
        let total = Int(minutes.rounded())
        return (total < 0 ? "-" : "+") + PulseFormat.hoursMinutes(Double(abs(total)))
    }

    // MARK: SLEEP CONSISTENCY

    /// A night's bed and wake on the chart's clock: minutes after noon of the evening the night began.
    static func clockPosition(_ ts: Int, wakeTs: Int) -> Double {
        let cal = Calendar.current
        let wakeDay = cal.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(wakeTs)))
        let noon = cal.date(byAdding: .hour, value: -12, to: wakeDay) ?? wakeDay
        return (Double(ts) - noon.timeIntervalSince1970) / 60
    }

    /// A target minute of the local day on the same clock: an evening bed before midnight, a bed after it
    /// and every wake on the next morning.
    static func clockPosition(bedMinute m: Double) -> Double { m >= 720 ? m - 720 : m + 720 }
    static func clockPosition(wakeMinute m: Double) -> Double { m + 720 }

    static func timing(_ f: SleepNightFacts) -> SleepConsistency.NightTiming {
        let zone = TimeZone.current
        return SleepConsistency.NightTiming(
            day: f.key, bedTs: f.onsetTs, wakeTs: f.wakeTs,
            bedOffsetSec: zone.secondsFromGMT(for: Date(timeIntervalSince1970: TimeInterval(f.onsetTs))),
            wakeOffsetSec: zone.secondsFromGMT(for: Date(timeIntervalSince1970: TimeInterval(f.wakeTs))))
    }

    static func consistencyCard(_ t: SleepNightFacts, prior: [SleepNightFacts], fiveKeys: [String],
                                timingNights: [SleepNightFacts]) -> SleepConsistencyCard {
        let figure = t.consistency.map { _ in
            sleepFigure(t.consistency, history: prior.compactMap(\.consistency), polarity: .higherIsBetter,
                        unit: "%", name: String(localized: "Sleep consistency"), format: percentText)
        }
        let byKey = Dictionary(timingNights.map { ($0.key, $0) }, uniquingKeysWith: { _, last in last })
        let nights = fiveKeys.compactMap { key -> SleepConsistencyCard.Night? in
            guard let f = byKey[key] else { return nil }
            return .init(id: key, label: PulseFormat.dayLabel(key, template: "EEE"),
                         bed: clockPosition(f.onsetTs, wakeTs: f.wakeTs),
                         wake: clockPosition(f.wakeTs, wakeTs: f.wakeTs), isLast: key == t.key)
        }
        let targets = SleepConsistencyTarget.targets(timingNights.map(timing))
        let optimal = fiveKeys.compactMap { key -> SleepConsistencyCard.Optimal? in
            guard let target = targets[key] else { return nil }
            return .init(id: key, bed: clockPosition(bedMinute: target.bedMinute),
                         wake: clockPosition(wakeMinute: target.wakeMinute))
        }
        let positions = nights.flatMap { [$0.bed, $0.wake] } + optimal.flatMap { [$0.bed, $0.wake] }
        let lo = (positions.min() ?? 600) - 25
        let hi = (positions.max() ?? 1_200) + 25
        // Gridlines every four hours on the hour, covering every bar and curve.
        var first = floor(lo / 60) * 60
        let span = max(hi - first, 240)
        let steps = Int(ceil(span / 240))
        if first + Double(steps) * 240 < hi { first -= 60 }
        let lines = (0...steps).map { i -> SleepConsistencyCard.Line in
            let position = first + Double(i) * 240
            return .init(position: position, label: hourLabel(position: position, wakeTs: t.wakeTs))
        }
        let domain = (lines.first?.position ?? lo)...(lines.last?.position ?? hi)
        return SleepConsistencyCard(
            figure: figure, nights: nights, optimal: optimal,
            lastBedText: PulseFormat.clock(Date(timeIntervalSince1970: TimeInterval(t.onsetTs))),
            lastWakeText: PulseFormat.clock(Date(timeIntervalSince1970: TimeInterval(t.wakeTs))),
            lines: lines, domain: domain)
    }

    /// "8PM" / "12AM" (or "20:00") for a position on the chart's clock.
    static func hourLabel(position: Double, wakeTs: Int) -> String {
        let cal = Calendar.current
        let wakeDay = cal.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(wakeTs)))
        let noon = cal.date(byAdding: .hour, value: -12, to: wakeDay) ?? wakeDay
        let date = noon.addingTimeInterval(position * 60)
        return hourFormatter().string(from: date).replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
    }

    private static let hourFormatterLock = NSLock()
    private static var hourFormatterCache: (key: String, formatter: DateFormatter)?

    /// The hour formatter for the reader's locale and clock, made once rather than per gridline.
    private static func hourFormatter() -> DateFormatter {
        let locale = AppClock.formattingLocale
        let use24 = AppClock.uses24Hour
        let key = "\(locale.identifier)|\(use24)"
        hourFormatterLock.lock(); defer { hourFormatterLock.unlock() }
        if let cached = hourFormatterCache, cached.key == key { return cached.formatter }
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate(use24 ? "HHmm" : "ha")
        hourFormatterCache = (key, f)
        return f
    }

    // MARK: SLEEP EFFICIENCY

    static func efficiencyCard(_ t: SleepNightFacts, prior: [SleepNightFacts], wakeEvents: Int?) -> SleepEfficiencyCard {
        let figure = sleepFigure(t.efficiency, history: prior.compactMap(\.efficiency), polarity: .higherIsBetter,
                                 unit: "%", name: String(localized: "Sleep efficiency"), format: percentText)
        let span = Double(max(t.wakeTs - t.onsetTs, 1))
        var asleepRuns: [ClosedRange<Double>] = []
        var awakeRuns: [SleepEfficiencyCard.AwakeRun] = []
        if t.night.realSegments != nil {
            let intervals = t.night.intervals
            asleepRuns = mergedRuns(intervals.filter { $0.stage != .awake }, span: span)
            awakeRuns = mergedRuns(intervals.filter { $0.stage == .awake }, span: span).map { run in
                // Five minutes or more is a block; anything shorter a tick.
                .init(range: run, isLong: (run.upperBound - run.lowerBound) * span >= 5 * 60)
            }
        }
        return SleepEfficiencyCard(figure: figure, asleepText: PulseFormat.hoursMinutes(t.asleep),
                                   awakeText: PulseFormat.hoursMinutes(t.night.stages.awake),
                                   asleepRuns: asleepRuns, awakeRuns: awakeRuns, wakeEvents: wakeEvents)
    }

    // MARK: Weekly Trends

    static func weekNight(_ key: String, facts f: SleepNightFacts?, performance: Double?) -> SleepWeekNight {
        let bed = f.map { clockPosition($0.onsetTs, wakeTs: $0.wakeTs) }
        let wake = f.map { clockPosition($0.wakeTs, wakeTs: $0.wakeTs) }
        return SleepWeekNight(
            id: key, label: PulseFormat.dayLabel(key, template: "EEE"), sublabel: PulseFormat.dayLabel(key, template: "d"),
            performance: performance, hoursMin: f?.asleep, needMin: f?.need, hoursPct: f?.hoursPct,
            deepMin: f?.night.stages.deep, remMin: f?.night.stages.rem, consistency: f?.consistency,
            bed: bed, wake: wake,
            bedText: f.map { PulseFormat.clockNoMeridiem(Date(timeIntervalSince1970: TimeInterval($0.onsetTs))) },
            wakeText: f.map { PulseFormat.clockNoMeridiem(Date(timeIntervalSince1970: TimeInterval($0.wakeTs))) },
            efficiency: f?.efficiency)
    }

    // MARK: The coach summary pill's local sentence

    static func sleepSummary(perf: Double?, night: SleepNightFacts?, contributors: [SleepContributorRow]) -> String? {
        guard let night else {
            if let perf {
                let word = PulseSleepBand.name(PulseSleepBand.index(percent: perf) ?? 0).lowercased()
                return String(localized: "Your sleep was \(word) at **\(PulseDisplay.displayedPercent(perf))%**. This night has no sleep details to break it down.")
            }
            return String(localized: "No sleep was recorded for this night. Wear your strap to bed to see your Sleep Performance.")
        }
        guard let perf else {
            return String(localized: "This night has no Sleep Performance score yet.")
        }
        let shown = PulseDisplay.displayedPercent(perf)
        let word = PulseSleepBand.name(PulseSleepBand.index(percent: perf) ?? 0).lowercased()
        // The pill shows two lines: name a poor contributor when there is one, else the hours.
        if let weakest = contributors.first(where: { $0.band == 0 && $0.kind != .stress }),
           let pct = weakest.percent {
            return String(localized: "Your sleep was \(word) at **\(shown)%**. **\(weakest.kind.sentenceName)** was poor at \(PulseDisplay.displayedPercent(pct))%.")
        }
        if let need = night.need {
            return String(localized: "Your sleep was \(word) at **\(shown)%**: \(PulseFormat.duration(minutes: night.asleep)) asleep against the \(PulseFormat.duration(minutes: need)) you needed.")
        }
        return String(localized: "Your sleep was \(word) at **\(shown)%**.")
    }

    // MARK: - The night's stress (a second build: raw heart rate and R-R)

    /// One night's stress, or why there is none.
    enum NightStress {
        /// No waking heart rate before the night to compare it against.
        case noReference
        /// Too little heart rate during the night.
        case noHeartRate
        case scored(SleepStress.Result)
    }

    /// Scores the night from `onset` to `wake` (its curve from `chartFrom` to `chartTo`) with `SleepStress`,
    /// against the waking hours before it. nil when a newer refresh superseded the reads.
    func nightStress(_ r: PulseRequest, onset: Int, wake: Int, chartFrom: Int, chartTo: Int) async -> NightStress? {
        // The waking day the night is compared with: the 18 hours before it (the Stress Monitor's 06–22
        // waking window always falls inside them, whenever the night began).
        let referenceFrom = onset - 18 * 3_600
        let hr = await repo.hrSamples(from: referenceFrom, to: chartTo, limit: 300_000)
        guard isCurrent(r) else { return nil }
        let rr = await repo.rrIntervals(from: referenceFrom, to: chartTo, limit: 300_000)
        guard isCurrent(r) else { return nil }
        let gravity = await repo.gravitySamplesUnion(from: referenceFrom, to: onset, limit: 200_000)
        guard isCurrent(r) else { return nil }

        let tz = TimeZone.current.secondsFromGMT(for: Date(timeIntervalSince1970: TimeInterval(onset)))
        let day = DaytimeStress.analyze(hr: hr.filter { $0.ts < onset }, rr: rr.filter { $0.ts < onset },
                                        gravity: gravity, tzOffsetSeconds: tz)
        guard let reference = SleepStress.reference(wakingHours: day.hours, endingBy: onset) else { return .noReference }
        let res = SleepStress.analyze(hr: hr.filter { $0.ts >= chartFrom }, rr: rr.filter { $0.ts >= chartFrom },
                                      sleepStart: onset, sleepEnd: wake, reference: reference,
                                      chartStart: chartFrom, chartEnd: chartTo)
        return res.hasScore ? .scored(res) : .noHeartRate
    }

    /// HIGH / MEDIUM / LOW for the night in `q`, scored by `SleepStress` against the waking hours before it.
    func sleepStress(_ r: PulseRequest, request q: SleepStressRequest) async -> SleepStressSnapshot? {
        begin(r.seq)
        let onset = Int(q.onset.timeIntervalSince1970)
        let wake = Int(q.wake.timeIntervalSince1970)
        let chartFrom = onset - 45 * 60
        let chartTo = wake + 30 * 60
        let chartEnd = Date(timeIntervalSince1970: TimeInterval(chartTo))
        guard let scored = await nightStress(r, onset: onset, wake: wake, chartFrom: chartFrom, chartTo: chartTo)
        else { return nil }
        let res: SleepStress.Result
        switch scored {
        case .noReference, .noHeartRate:
            return SleepStressSnapshot(nightKey: q.nightKey, state: scored.isNoReference ? .noReference : .noHeartRate,
                                       highPercent: nil, figure: nil, levels: [], points: [], sleepStart: q.onset,
                                       sleepEnd: q.wake, chartEnd: chartEnd, xTicks: [], lastLevel: nil)
        case .scored(let result):
            res = result
        }
        let order: [(SleepStress.Band, String)] = [
            (.high, String(localized: "High")), (.medium, String(localized: "Medium")), (.low, String(localized: "Low")),
        ]
        let levels = order.map { band, title -> SleepStressSnapshot.Level in
            let pct = res.percent(band) ?? 0
            return .init(band: band, title: title, share: pct / 100, percentText: "\(Int(pct.rounded()))%",
                         durationText: PulseFormat.hoursMinutes(Double(res.seconds(band)) / 60))
        }
        let points = res.windows.map { w in
            PulseTimeValue(date: Date(timeIntervalSince1970: TimeInterval(w.startTs) + TimeInterval(w.seconds) / 2),
                           value: w.level)
        }
        let dates = points.map(\.date) + [q.onset, q.wake, chartEnd]
        let ticks = Self.stressTicks(from: dates.min() ?? q.onset, to: dates.max() ?? chartEnd)
        let figure = Self.sleepFigure(res.highPercent, history: [], polarity: .lowerIsBetter, unit: "%",
                                      name: String(localized: "High sleep stress"), format: Self.percentText)
        return SleepStressSnapshot(nightKey: q.nightKey, state: .scored, highPercent: res.highPercent,
                                   figure: figure, levels: levels, points: points, sleepStart: q.onset,
                                   sleepEnd: q.wake, chartEnd: chartEnd, xTicks: ticks,
                                   lastLevel: res.windows.last(where: { $0.level != nil })?.level)
    }

    /// The chart's times: its start and its end (bold), and between them the two half hours nearest a third
    /// and two thirds of the way along, each placed at its own time (deep-dives-2026/19b: "1:30 AM",
    /// "4:30 AM"). `from` / `to` are the span `PulseStressChart` plots.
    static func stressTicks(from: Date, to: Date, calendar cal: Calendar = .current) -> [SleepStressSnapshot.XTick] {
        let span = to.timeIntervalSince(from)
        guard span > 0 else { return [] }
        var ticks = [SleepStressSnapshot.XTick(fraction: 0, text: PulseFormat.clock(from), isEnd: false)]
        var used = Set<Int>()
        for third in [1.0 / 3, 2.0 / 3] {
            let target = from.addingTimeInterval(span * third)
            let offset = Double(cal.timeZone.secondsFromGMT(for: target))
            let local = target.timeIntervalSince1970 + offset
            let snapped = Date(timeIntervalSince1970: (local / 1_800).rounded() * 1_800 - offset)
            let fraction = snapped.timeIntervalSince(from) / span
            let id = Int(snapped.timeIntervalSince1970)
            guard fraction > 0.15, fraction < 0.85, !used.contains(id) else { continue }
            used.insert(id)
            ticks.append(.init(fraction: fraction, text: PulseFormat.clock(snapped), isEnd: false))
        }
        ticks.append(.init(fraction: 1, text: PulseFormat.clock(to), isEnd: true))
        return ticks
    }

    /// SLEEP STRESS against the prior 30 nights: the mean HIGH share over the prior nights that score (at
    /// least five, as every other "vs. prior 30 days" figure asks), with the trend lower-is-better. A past
    /// night's score is kept (`PulseSleepStressHistory`), keyed on its window and its heart-rate coverage,
    /// so it is scored once unless more of its data arrives. nil when a newer refresh superseded the build.
    func sleepStressBaseline(_ r: PulseRequest, request q: SleepStressRequest,
                             highPercent: Double) async -> SleepStressBaseline? {
        begin(r.seq)
        var history: [Double] = []
        for night in q.prior {
            let chartFrom = night.onsetTs - 45 * 60
            let chartTo = night.wakeTs + 30 * 60
            let coverage = await repo.hrFingerprint(from: night.onsetTs - 18 * 3_600, to: chartTo)
            guard isCurrent(r) else { return nil }
            let cacheKey = "\(night.key)|\(night.onsetTs)|\(night.wakeTs)|\(coverage?.count ?? 0)|\(coverage?.maxTs ?? 0)"
            if let kept = await PulseSleepStressHistory.shared.lookup(cacheKey) {
                if let kept { history.append(kept) }
                continue
            }
            guard (coverage?.count ?? 0) > 0 else { continue }
            guard let scored = await nightStress(r, onset: night.onsetTs, wake: night.wakeTs, chartFrom: chartFrom,
                                                 chartTo: chartTo) else { return nil }
            var high: Double?
            if case .scored(let res) = scored { high = res.highPercent }
            await PulseSleepStressHistory.shared.keep(cacheKey, high: high)
            if let high { history.append(high) }
        }
        guard isCurrent(r) else { return nil }
        let figure = Self.sleepFigure(highPercent, history: history, polarity: .lowerIsBetter, unit: "%",
                                      name: String(localized: "High sleep stress"), format: Self.percentText)
        return SleepStressBaseline(nightKey: q.nightKey, figure: figure, scoredNights: history.count)
    }

    // MARK: - Tonight's plan (Sleep Planner, Home's TONIGHT'S SLEEP)

    /// Tonight's need with its parts, the recent nights' wake minutes and their timing, and the end of the
    /// night ending today (§3.11).
    func sleepPlanner(_ r: PulseRequest) async -> SleepPlannerSnapshot? {
        begin(r.seq)
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let need = await repo.sleepNeedTonight(now: r.now)
        guard isCurrent(r) else { return nil }
        let todayKey = Repository.localDayKey(r.now)
        // The nights ending on the last eight days: tonight's four prior calendar nights with room to spare.
        let recentKeys = Set(PulseDisplay.trailingDayKeys(endingOn: todayKey, count: 8))
        var timings: [SleepConsistency.NightTiming] = []
        for g in groups {
            guard let end = g.first?.endTs else { continue }
            let key = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(end)))
            guard recentKeys.contains(key), !timings.contains(where: { $0.day == key }),
                  let shape = SleepNeedInputs.dayShape(g, habitualMidsleepSec: habitual) else { continue }
            let zone = TimeZone.current
            timings.append(SleepConsistency.NightTiming(
                day: key, bedTs: shape.bedTs, wakeTs: shape.wakeTs,
                bedOffsetSec: zone.secondsFromGMT(for: Date(timeIntervalSince1970: TimeInterval(shape.bedTs))),
                wakeOffsetSec: zone.secondsFromGMT(for: Date(timeIntervalSince1970: TimeInterval(shape.wakeTs)))))
        }
        // The night Home shows as last night: the merged main night of the group ending on the request's day
        // (today's logical day, as the planner and Home's card build with day offset 0).
        let nightEnded = group(endingOn: r.day.key, in: groups)
            .flatMap { SleepModel.mergeDay($0, habitualMidsleepSec: habitual, motionByStart: [:]) }
            .map { Date(timeIntervalSince1970: TimeInterval($0.session.endTs)) }
        return SleepPlannerSnapshot(seq: r.seq, need: need,
                                    recentWakeMinutes: Self.recentWakeMinutes(groups, habitual: habitual),
                                    timings: timings.sorted { $0.day < $1.day }, nightEnded: nightEnded)
    }

    /// The main night's wake minute for the most recent `TonightSleepPlan.habitNights` night groups, newest
    /// first: exactly the window and main-night pick Home's card has always taken its usual wake from.
    static func recentWakeMinutes(_ groups: [[CachedSleepSession]], habitual: Int?) -> [Int] {
        let cal = Calendar.current
        return groups.prefix(TonightSleepPlan.habitNights).compactMap { g -> Int? in
            guard let end = SleepView.mainNightGroup(g, habitualMidsleepSec: habitual).last?.endTs else { return nil }
            let c = cal.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: TimeInterval(end)))
            return (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
    }

    /// Tonight's plan for Home's TONIGHT'S SLEEP card (`PulseSnapshotBuilder.tonightPlan`), through the
    /// planner's own resolver (`PulseSleepPlan.resolve`): given the planner's stored goal
    /// (`PulseSleepGoal.storageKey`) and the running Weekly Plan's sleep goals, the card shows the wake and
    /// bedtime the planner it opens shows. `settings`, `goal` and `weeklyPlan` are read on the main actor
    /// (`PulseSleepPlanSettings.current`, `PulseSleepGoal(storageValue:)`, `PulseWeeklyPlanSleepGoals.current`)
    /// and come with the request (`PulsePrefs`).
    func tonightSleepPlan(_ r: PulseRequest, settings: PulseSleepPlanSettings, goal: PulseSleepGoal = .default,
                          weeklyPlan: PulseWeeklyPlanSleepGoals? = nil) async -> PulseSleepPlan? {
        guard let s = await sleepPlanner(r) else { return nil }
        return PulseSleepPlan.resolve(now: r.now, goal: goal, needMin: s.need.totalMin, settings: settings,
                                      recentWakeMinutes: s.recentWakeMinutes, timings: s.timings,
                                      weeklyPlan: weeklyPlan, nightEnded: s.nightEnded)
    }
}

extension PulseSnapshotBuilder.NightStress {
    var isNoReference: Bool {
        if case .noReference = self { return true }
        return false
    }
}

/// Past nights' HIGH SLEEP STRESS, kept for the app's life: a past night's heart rate does not change, so
/// the dive's baseline scores each night once (its key carries the night's window and heart-rate coverage,
/// so a night whose data arrives later is scored again).
actor PulseSleepStressHistory {
    static let shared = PulseSleepStressHistory()
    /// HIGH SLEEP STRESS by night key; nil for a night that does not score.
    private var byNight: [String: Double?] = [:]

    /// The kept score (nil inside when the night does not score), or nil when the night was never scored.
    func lookup(_ key: String) -> Double?? { byNight[key] }

    func keep(_ key: String, high: Double?) {
        if byNight.count > 400 { byNight.removeAll() }
        byNight[key] = .some(high)
    }
}
#endif
