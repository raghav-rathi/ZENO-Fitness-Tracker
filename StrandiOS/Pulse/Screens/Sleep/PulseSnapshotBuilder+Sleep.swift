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
// through the ONE per-night read (`Repository.resolvedNightSleep`). Every "vs. prior 30 days" figure is the
// mean of the same quantity over the nights that ended in the 30 calendar days before this one, computed
// the same way, so the value, its baseline and the Weekly Trends bar for the same night cannot disagree.

extension PulseSnapshotBuilder {

    /// One merged night and the figures the dive compares across nights.
    struct SleepNightFacts {
        let key: String
        let night: Night
        let onsetTs: Int
        let wakeTs: Int
        let resolved: ResolvedNightSleep
        let performance: Double?

        var asleep: Double { night.stages.asleep }
        var inBed: Double { night.stages.total }
        var restorative: Double { night.stages.deep + night.stages.rem }
        var efficiency: Double? { inBed > 0 ? asleep / inBed * 100 : nil }
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

    // MARK: - The dive

    /// The Sleep dive for the newest night that ended on or before `anchorKey` (a wake day key; Home's day
    /// when nil). Nights are addressed by wake day, never by position, so a night banked while the screen is
    /// open cannot swap what it shows.
    func sleepDive(_ r: PulseRequest, onOrBefore anchorKey: String?) async -> SleepDiveSnapshot? {
        begin(r.seq)
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let rest = await restSeries()
        let computed = await sleepComputedFigures()
        guard isCurrent(r) else { return nil }

        let anchor = anchorKey ?? r.day.key
        // `navDays` groups blocks by the local day they END on, newest first.
        let keys = groups.map { g in
            Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(g.first?.endTs ?? 0)))
        }
        var groupByKey: [String: [CachedSleepSession]] = [:]
        for (key, group) in zip(keys, groups) where groupByKey[key] == nil { groupByKey[key] = group }
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
                                      performance: sleepPerformance(dayKey: key, rest: rest, days: r.days))
            }
            memo[key] = .some(out)
            return out
        }

        guard !keys.isEmpty else {
            return Self.emptySleepDive(seq: r.seq, requestDayKey: r.day.key)
        }
        // A day older than every banked night opens on the oldest night, the nearest one there is.
        let index = keys.firstIndex { $0 <= anchor } ?? keys.count - 1
        let key = keys[index]
        let group = groupByKey[key] ?? []
        let tonight = facts(key)
        let perf = sleepPerformance(dayKey: key, rest: rest, days: r.days)
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

        // MARK: Weekly Trends: the seven days ending on the night's wake day.
        let weekKeys = PulseDisplay.trailingDayKeys(endingOn: key, count: 7)
        let weekly = weekKeys.map { day -> SleepWeekNight in
            Self.weekNight(day, facts: facts(day), performance: sleepPerformance(dayKey: day, rest: rest, days: r.days))
        }

        let napList = naps(in: group, night: tonight?.night)
        let summary = Self.sleepSummary(perf: perf, night: tonight, contributors: contributors)
        let stress = tonight.map {
            SleepStressRequest(nightKey: key, onset: Date(timeIntervalSince1970: TimeInterval($0.onsetTs)),
                               wake: Date(timeIntervalSince1970: TimeInterval($0.wakeTs)))
        }
        guard isCurrent(r) else { return nil }
        return SleepDiveSnapshot(
            seq: r.seq, requestDayKey: r.day.key, nightKeys: keys, nightIndex: index, wakeDayKey: key,
            dial: dial, contributors: contributors, summary: summary, lastNight: lastNight,
            hoursVsNeeded: hoursVsNeeded, consistency: consistency, efficiency: efficiency, stress: stress,
            weekly: weekly, naps: napList, sleepingHR: sleepingHR, lowestHR: lowestHR,
            respRate: daysByKey[key]?.respRateBpm)
    }

    /// The dive with nothing banked at all.
    static func emptySleepDive(seq: Int, requestDayKey: String) -> SleepDiveSnapshot {
        let rows: [(SleepContributorRow.Kind, String, String)] = [
            (.hours, String(localized: "Hours vs. needed"), "hours_vs_needed_pct"),
            (.consistency, String(localized: "Sleep consistency"), "sleep_consistency"),
            (.efficiency, String(localized: "Sleep efficiency"), "sleep_efficiency"),
            (.stress, String(localized: "High sleep stress"), "sleep_stress"),
        ]
        return SleepDiveSnapshot(
            seq: seq, requestDayKey: requestDayKey, nightKeys: [], nightIndex: 0, wakeDayKey: nil,
            dial: PulseDialData(score: .sleep, value: nil, state: .noData),
            contributors: rows.map { SleepContributorRow(kind: $0.0, title: $0.1, percent: nil, calibrating: false,
                                                         band: nil, metric: $0.2) },
            summary: sleepSummary(perf: nil, night: nil, contributors: []), lastNight: nil, hoursVsNeeded: nil,
            consistency: nil, efficiency: nil, stress: nil, weekly: [], naps: [], sleepingHR: nil, lowestHR: nil,
            respRate: nil)
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
    static func quantile(_ sorted: [Double], _ q: Double) -> Double {
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
        let f = DateFormatter()
        f.locale = AppClock.formattingLocale
        f.setLocalizedDateFormatFromTemplate(AppClock.uses24Hour ? "HHmm" : "ha")
        return f.string(from: date).replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
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
            return String(localized: "No sleep was recorded for this night. Wear your strap to bed to see your Sleep Performance.")
        }
        guard let perf else {
            return String(localized: "This night has no Sleep Performance score yet.")
        }
        let shown = PulseDisplay.displayedPercent(perf)
        let word = PulseSleepBand.name(PulseSleepBand.index(percent: perf) ?? 0).lowercased()
        var text = String(localized: "Your sleep was \(word) at **\(shown)%**")
        if let need = night.need {
            text += ": " + String(localized: "\(PulseFormat.duration(minutes: night.asleep)) asleep against the \(PulseFormat.duration(minutes: need)) you needed.")
        } else {
            text += "."
        }
        let weakest = contributors.filter { $0.band == 0 && $0.kind != .stress }.map { $0.title.lowercased() }
        if let first = weakest.first {
            text += " " + String(localized: "\(first.prefix(1).uppercased() + first.dropFirst()) held it back.")
        }
        return text
    }

    // MARK: - The night's stress (a second build: raw heart rate and R-R)

    /// HIGH / MEDIUM / LOW for the night in `q`, scored by `SleepStress` against the waking hours before it.
    func sleepStress(_ r: PulseRequest, request q: SleepStressRequest) async -> SleepStressSnapshot? {
        begin(r.seq)
        let onset = Int(q.onset.timeIntervalSince1970)
        let wake = Int(q.wake.timeIntervalSince1970)
        let chartFrom = onset - 45 * 60
        let chartTo = wake + 30 * 60
        // The waking day the night is compared with: the 18 hours before it (the Stress Monitor's 06–22
        // waking window always falls inside them, whenever the night began).
        let referenceFrom = onset - 18 * 3_600
        let hr = await repo.hrSamples(from: referenceFrom, to: chartTo, limit: 300_000)
        guard isCurrent(r) else { return nil }
        let rr = await repo.rrIntervals(from: referenceFrom, to: chartTo, limit: 300_000)
        guard isCurrent(r) else { return nil }
        let gravity = await repo.gravitySamplesUnion(from: referenceFrom, to: onset, limit: 200_000)
        guard isCurrent(r) else { return nil }

        let tz = TimeZone.current.secondsFromGMT(for: q.onset)
        let day = DaytimeStress.analyze(hr: hr.filter { $0.ts < onset }, rr: rr.filter { $0.ts < onset },
                                        gravity: gravity, tzOffsetSeconds: tz)
        let empty = SleepStressSnapshot(nightKey: q.nightKey, state: .noReference, highPercent: nil, levels: [],
                                        points: [], sleepStart: q.onset, sleepEnd: q.wake,
                                        chartEnd: Date(timeIntervalSince1970: TimeInterval(chartTo)),
                                        xLabels: [], lastLevel: nil)
        guard let reference = SleepStress.reference(wakingHours: day.hours, endingBy: onset) else { return empty }
        let res = SleepStress.analyze(hr: hr.filter { $0.ts >= chartFrom }, rr: rr.filter { $0.ts >= chartFrom },
                                      sleepStart: onset, sleepEnd: wake, reference: reference,
                                      chartStart: chartFrom, chartEnd: chartTo)
        guard res.hasScore else {
            return SleepStressSnapshot(nightKey: q.nightKey, state: .noHeartRate, highPercent: nil, levels: [],
                                       points: [], sleepStart: q.onset, sleepEnd: q.wake,
                                       chartEnd: empty.chartEnd, xLabels: [], lastLevel: nil)
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
        let labels = (0...3).map { i -> String in
            let ts = chartFrom + (chartTo - chartFrom) * i / 3
            return PulseFormat.clock(Date(timeIntervalSince1970: TimeInterval(ts)))
        }
        return SleepStressSnapshot(nightKey: q.nightKey, state: .scored, highPercent: res.highPercent,
                                   levels: levels, points: points, sleepStart: q.onset, sleepEnd: q.wake,
                                   chartEnd: empty.chartEnd, xLabels: labels,
                                   lastLevel: res.windows.last(where: { $0.level != nil })?.level)
    }

    // MARK: - Sleep Planner

    /// Tonight's need with its parts, and the recent nights' timing (§3.11).
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
        return SleepPlannerSnapshot(seq: r.seq, need: need, timings: timings.sorted { $0.day < $1.day },
                                    planDayKey: todayKey)
    }
}
#endif
