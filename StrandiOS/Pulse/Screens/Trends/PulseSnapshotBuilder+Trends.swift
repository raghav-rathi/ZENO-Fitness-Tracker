#if os(iOS)
import Foundation
import SwiftUI
import StrandAnalytics
import WhoopStore

// MARK: - Trends group builds (WHOOP_UI_SPEC §3.12, §3.35, §3.40)
//
// Off the main actor, like every Pulse build. A metric's whole daily history is resolved ONCE per refresh
// (`trendSeries`, cached under "trends.series.<key>.<units>.<day>") and every Trend View page, the Trends
// tab's rows and the picker read that one copy, so stepping the pager or switching W / M / 6M re-reads
// nothing. Only today's live readings (Day Stress's and Day Strain's) are laid over it per call, each from
// the funnel Home reads.
//
// Each metric resolves through the reader the rest of Pulse uses for the same fact, so a Trend View can
// never print a different number from the row or dial that opened it: Recovery, HRV, resting HR,
// respiratory rate and blood oxygen from the merged daily rows (Home, the Recovery dive), Sleep
// Performance through the Sleep dial's resolver, need / consistency / debt through
// `Repository.resolvedNightSleep`, steps through the one `StepsResolver`, calories through Home's tile
// resolver (`caloriesResolution`), stress from its stored daily score (today's from the Stress Monitor's
// own reading), and anything else through the Explore read path.

extension PulseSnapshotBuilder {

    // MARK: Trend View

    /// One Trend View page for `key`. The series runs through `r`'s day (today); the latest window ends
    /// `anchorOffset` days earlier (0 = today, more when the page was opened from a past day's Home). nil
    /// when superseded or for an unknown key.
    func trendView(_ r: PulseRequest, key: String, range: PulseTrendMath.Range, page: Int,
                   units: PulseTrendUnits, cycleOverlay: Bool, anchorOffset: Int = 0) async -> TrendViewSnapshot? {
        begin(r.seq)
        guard let metric = PulseTrendMetric.resolve(key) else { return nil }
        let series = await trendSeries(r, metric: metric, units: units)
        guard isCurrent(r) else { return nil }
        var phases = cycleOverlay ? await trendCyclePhases(r) : [:]
        guard isCurrent(r) else { return nil }
        #if DEBUG
        if cycleOverlay && phases.isEmpty, let demo = PulseTrendDebugLaunch.cycleDemoPhases(endingOn: r.day.key) {
            phases = demo
        }
        #endif
        var snapshot = PulseTrendPageBuilder.page(seq: r.seq, metric: metric, series: series, today: r.day.key,
                                                  anchor: PulseTrendMath.addDays(r.day.key, -max(0, anchorOffset)),
                                                  range: range, page: page, phases: phases)
        if metric.source == .vo2Estimate {
            snapshot.cardioFitness = await trendCardioFitness(r, estimates: series.points)
            guard isCurrent(r) else { return nil }
        }
        return snapshot
    }

    /// YOUR CARDIO FITNESS LEVEL under the VO₂ Max chart (§3.12 item 13, §3.28; reviews/83): the newest
    /// weekly estimate of the series the chart draws, whatever window is shown, against the estimates of
    /// the 90 days before it. ZENO has no age and sex norms ([POP]), so it names no population category or
    /// percentile. Before the first estimate it counts the sleeps VO₂ max waits for, then says what is
    /// missing, in Healthspan's VO₂ MAX row's own words.
    func trendCardioFitness(_ r: PulseRequest, estimates points: [PulseTrendMath.Point]) async -> HealthVO2MaxCard.State {
        let estimates = points.filter { $0.value.isFinite && $0.value > 0 }
        guard let latest = estimates.last else {
            let nights = await nightGroups(r).count
            let needed = Self.vo2UnlockNights
            return nights < needed ? .locked(nights: nights, needed: needed) : .missing(Self.vo2WaitingSentence)
        }
        var note: String?
        let from = PulseTrendMath.addDays(latest.day, -89)
        let before = estimates.filter { $0.day >= from && $0.day < latest.day }.map(\.value)
        if !before.isEmpty {
            // Judged on the whole numbers the card prints, so "Up 1" never sits between two equal figures.
            let delta = latest.value.rounded() - (before.reduce(0, +) / Double(before.count)).rounded()
            let amount = PulseFormat.whole(abs(delta))
            if delta == 0 {
                note = String(localized: "In line with your 90-day average.")
            } else if delta > 0 {
                note = String(localized: "Up \(amount) on your 90-day average.")
            } else {
                note = String(localized: "Down \(amount) on your 90-day average.")
            }
        }
        let week = PulseFormat.dayLabel(latest.day, template: "MMMd")
        return .value(latest.value, updated: String(localized: "Estimated for the week of \(week)"), note: note)
    }

    /// WHAT CORRELATES for one Trend View page: the other metrics whose days move with this one's over the
    /// same period (W: the 30 days to its end), by Pearson r (|r| ≥ 0.30 on at least 10 shared days, the
    /// classic card's rule), leaving out the metrics computed from it.
    func trendCorrelations(_ r: PulseRequest, key: String, range: PulseTrendMath.Range, page: Int,
                           units: PulseTrendUnits, anchorOffset: Int = 0) async -> PulseTrendCorrelations? {
        begin(r.seq)
        guard let metric = PulseTrendMetric.resolve(key) else { return nil }
        let own = await trendSeries(r, metric: metric, units: units)
        var others: [(PulseTrendMetric, PulseTrendSeries)] = []
        for other in PulseTrendMetric.curated where other.key != metric.key {
            others.append((other, await trendSeries(r, metric: other, units: units)))
            guard isCurrent(r) else { return nil }
        }
        return PulseTrendPageBuilder.correlations(metric: metric, series: own, others: others, today: r.day.key,
                                                  anchor: PulseTrendMath.addDays(r.day.key, -max(0, anchorOffset)),
                                                  range: range, page: page)
    }

    /// Every curated metric with whether it holds a reading, for the metric picker.
    func trendPicker(_ r: PulseRequest, units: PulseTrendUnits) async -> [PulseTrendPickerItem]? {
        begin(r.seq)
        var items: [PulseTrendPickerItem] = []
        for metric in PulseTrendMetric.curated {
            let series = await trendSeries(r, metric: metric, units: units)
            guard isCurrent(r) else { return nil }
            items.append(PulseTrendPickerItem(id: metric.key, title: metric.title, symbol: metric.symbol,
                                              pillar: metric.pillar, hasData: series.hasData))
        }
        return items
    }

    // MARK: Trends tab

    /// The Trends tab: THIS WEEK and every pillar's rows, from the same series the Trend View reads.
    func trendsTab(_ r: PulseRequest, units: PulseTrendUnits) async -> TrendsTabSnapshot? {
        begin(r.seq)
        var series: [String: PulseTrendSeries] = [:]
        for metric in PulseTrendMetric.curated {
            series[metric.key] = await trendSeries(r, metric: metric, units: units)
            guard isCurrent(r) else { return nil }
        }
        return PulseDigestBuilder.tab(seq: r.seq, today: r.day.key, series: series)
    }

    // MARK: Weekly Digest

    /// The Weekly Digest (or the monthly one) `page` periods back from the current one. With an active
    /// `plan`, a week the plan covered carries the plan's week, measured by Plan Overview's own resolver
    /// (`planWeek`) for that same Monday, so the digest and Plan Overview print the same numbers.
    func weeklyDigest(_ r: PulseRequest, mode: WeeklyDigestSnapshot.Mode, page: Int,
                      units: PulseTrendUnits, plan: PulsePlan? = nil) async -> WeeklyDigestSnapshot? {
        begin(r.seq)
        let sleep = await trendSeries(r, metric: .sleepPerformance, units: units)
        let recovery = await trendSeries(r, metric: .recovery, units: units)
        let strain = await trendSeries(r, metric: .dayStrain, units: units)
        let hours = await trendSeries(r, metric: .hoursVsNeed, units: units)
        let zones13 = await trendSeries(r, metric: .zones13, units: units)
        let zones45 = await trendSeries(r, metric: .zones45, units: units)
        guard isCurrent(r) else { return nil }
        // The behaviours read Behavior Insights' own analysis (fresh each build: logging a journal entry
        // does not bump the refresh), so "Behaviors this week" says what that page says.
        guard let insights = await behaviorData(r) else { return nil }
        let imported = await importedJournalQuestions()
        guard isCurrent(r) else { return nil }
        guard var digest = PulseDigestBuilder.digest(
            seq: r.seq, today: r.day.key, mode: mode, page: page,
            inputs: .init(sleep: sleep, recovery: recovery, strain: strain, hours: hours, zones13: zones13,
                          zones45: zones45, behaviorAnalysis: insights.analysis,
                          behaviorAnswers: insights.answers)) else { return nil }
        digest.behaviorNames = BehaviorNameSources(imported: imported, questions: insights.questions)
        // The digest's week and the plan's are both Monday to Sunday around the same day; the block shows
        // only when they are the same week and the plan had begun by its Sunday.
        if let plan, mode == .week,
           let window = PulseTrendMath.weekWindow(containing: r.day.key, weeksBack: digest.page),
           plan.startedOn <= window.end,
           let week = await planWeek(r, plan: plan, weekOffset: -digest.page), week.weekStart == window.start {
            digest.plan = WeeklyDigestSnapshot.Plan(title: plan.cardTitle, week: week)
        }
        guard isCurrent(r) else { return nil }
        return digest
    }

    // MARK: Training Load

    /// Fitness, fatigue and form over `range` (M, 6M, 1Y or ALL), from the model the classic card draws.
    func trainingLoad(_ r: PulseRequest, range: PulseTrendMath.Range) async -> TrainingLoadSnapshot? {
        begin(r.seq)
        let result = await cached("trends.trainingLoad") { () async -> TrainingLoadEngine.Result in
            TrainingLoadEngine.evaluate(days: ReadinessEngine.trainingLoadDays(r.days))
        }
        guard isCurrent(r) else { return nil }
        return PulseTrainingLoadBuilder.snapshot(seq: r.seq, result: result, today: r.day.key, range: range)
    }

    // MARK: Series

    /// `metric`'s daily series: its history read once per refresh and shared (keyed by the request's day
    /// too, as the series stops at that day), with today's live reading laid over it on every call
    /// (`withLiveToday`).
    func trendSeries(_ r: PulseRequest, metric: PulseTrendMetric, units: PulseTrendUnits) async -> PulseTrendSeries {
        let history = await cached("trends.series.\(metric.key).\(units.id).\(r.day.key)") {
            await self.resolveTrendSeries(r, metric: metric, units: units)
        }
        return await withLiveToday(r, metric: metric, history: history)
    }

    /// Today's point where it is a live reading rather than a stored row, laid over the refresh's history on
    /// every call instead of being cached with it. Both readings move within a refresh (today's heart rate
    /// is re-read every five minutes) and with settings that rebuild without a new refresh (the stress lens;
    /// Effort's HR max, method and day window), and the screens that print them resolve them on every
    /// build, so the Trends rows, their captions and today's bars do too:
    ///
    /// - Day Stress: the Stress Monitor's own reading (`stressDay`, the funnel Home's tile, the Health tab's
    ///   card and the monitor read): the curve's latest scored hour, the evening before until today's first,
    ///   else today's daily score, with when it was read. Without either, today has no point.
    /// - Day Strain: Home's resolver (`strainValue`), the live score over the day window floored at the
    ///   stored row, so today's bar is the dial's number, not the last stored one.
    private func withLiveToday(_ r: PulseRequest, metric: PulseTrendMetric,
                               history: PulseTrendSeries) async -> PulseTrendSeries {
        guard r.day.isToday else { return history }
        let today = r.day.key
        var series = history
        let live: Double?
        switch metric.source {
        case .stress:
            let day = await stressDay(r)
            live = day?.gaugeLevel.map { HealthStressGauge.printed($0.level) }
            if let day, live != nil {
                series.todayReading = PulseTrendTodayReading(time: PulseStressDay.readingTime(day.latest?.at,
                                                                                              dayKey: day.dayKey))
            }
        case .daily(.strain):
            let window = await dayWindow(r)
            let hr = await heartRate(dayKey: today, from: window.from, to: window.to, isToday: true)
            guard let value = strainValue(r, row: displayRow(r), hr: hr) else { return history }
            live = value
        default:
            return history
        }
        var rows = history.points.filter { $0.day != today }.map { ($0.day, $0.value) }
        if let live { rows.append((today, live)) }
        series.points = Self.points(rows, through: today)
        return series
    }

    private func resolveTrendSeries(_ r: PulseRequest, metric m: PulseTrendMetric,
                                    units: PulseTrendUnits) async -> PulseTrendSeries {
        let today = r.day.key
        switch m.source {
        case .daily(let field):
            let pick: (DailyMetric) -> Double?
            switch field {
            case .recovery: pick = { $0.recovery }
            case .hrv: pick = { $0.avgHrv }
            case .rhr: pick = { $0.restingHr.map(Double.init) }
            case .resp: pick = { $0.respRateBpm }
            case .spo2: pick = { $0.spo2Pct }
            case .strain: pick = { $0.strain.map { UnitFormatter.effortValue($0, scale: .whoop) } }
            }
            // The stored rows; today's Strain is Home's live score, laid over these on every call
            // (`withLiveToday`).
            let rows = r.days.compactMap { d in pick(d).map { (d.day, $0) } }
            return PulseTrendSeries(points: Self.points(rows, through: today))

        case .sleepPerformance:
            // `sleepPerformance(dayKey:rest:days:)` for every day: the stored point, else the night's Rest
            // composite, the Sleep dial's own order.
            let rest = await restSeries()
            let restByDay = Dictionary(rest.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
            let rowByDay = Self.rowsByDay(r.days)
            let keys = Set(restByDay.keys).union(rowByDay.keys)
            let rows = keys.compactMap { k -> (String, Double)? in
                let v = restByDay[k] ?? rowByDay[k].flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
                return v.map { (k, $0) }
            }
            return PulseTrendSeries(points: Self.points(rows, through: today))

        case .night(let field):
            let rows = await nightFigures(r).compactMap { night -> (String, Double)? in
                let v: Double?
                switch field {
                case .need: v = night.needMin
                case .consistency: v = night.consistencyPct
                case .debt: v = night.debtMin
                case .hoursVsNeeded: v = night.hoursVsNeededPct.map { min(100, $0) }
                }
                return v.map { (night.day, $0) }
            }
            return PulseTrendSeries(points: Self.points(rows, through: today))

        case .timeInBed:
            return await timeInBedSeries(r)

        case .hoursVsNeed:
            let asleep = await repo.exploreSeries(key: "sleep_total_min", source: "my-whoop")
            let need = await nightFigures(r).compactMap { n in n.needMin.map { (n.day, $0) } }
            return PulseTrendSeries(points: Self.points(asleep.map { ($0.day, $0.value) }, through: today),
                                    secondary: Self.points(need, through: today))

        case .restorative(let percent):
            async let deepRows = repo.exploreSeries(key: "sleep_deep_min", source: "my-whoop")
            async let remRows = repo.exploreSeries(key: "sleep_rem_min", source: "my-whoop")
            async let totalRows = repo.exploreSeries(key: "sleep_total_min", source: "my-whoop")
            let deep = Self.byDay(await deepRows)
            let rem = Self.byDay(await remRows)
            let total = Self.byDay(await totalRows)
            var values: [(String, Double)] = []
            var remPart: [(String, Double)] = []
            var deepPart: [(String, Double)] = []
            for (day, d) in deep {
                guard let rm = rem[day] else { continue }
                if percent {
                    guard let t = total[day], t > 0 else { continue }
                    values.append((day, min(100, (d + rm) / t * 100)))
                } else {
                    values.append((day, d + rm))
                    remPart.append((day, rm))
                    deepPart.append((day, d))
                }
            }
            return PulseTrendSeries(points: Self.points(values, through: today),
                                    parts: percent ? [] : [Self.points(remPart, through: today),
                                                           Self.points(deepPart, through: today)])

        case .steps:
            let from = PulseTrendMath.addDays(today, -3_650)
            let resolved = await repo.resolvedStepDays(from: from, to: today).days
            return PulseTrendSeries(points: Self.points(resolved.map { ($0.day, Double($0.steps)) }, through: today))

        case .calories:
            // The one resolver Home's CALORIES tile and the Strain dive read (`caloriesResolution`): Apple
            // Health's imported active calories first, else the strap's on-device estimate.
            let calories = await caloriesResolution(r)
            return PulseTrendSeries(points: Self.points(calories.history.map { ($0.day, $0.value) }, through: today))

        case .zones(let zones):
            let rows = await workoutRows()
            var perZone: [Int: [String: Double]] = [:]
            var firstDay: String?
            // A day with an activity that carries no zones has UNKNOWN zone time, not zero: it is left out.
            var unknown = Set<String>()
            for w in rows {
                let minutes = (w.durationS ?? Double(w.endTs - w.startTs)) / 60
                guard minutes > 0 else { continue }
                let day = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(w.startTs)))
                guard let pct = WorkoutZones.percents(w.zonesJSON) else {
                    unknown.insert(day)
                    continue
                }
                firstDay = min(firstDay ?? day, day)
                for z in zones where (1...5).contains(z) {
                    perZone[z, default: [:]][day, default: 0] += minutes * pct[z - 1] / 100
                }
            }
            var filled = Self.zeroFilled(parts: zones.map { perZone[$0] ?? [:] }, firstDay: firstDay, r: r,
                                         unknown: unknown)
            if let first = filled.earliest {
                filled.unknownDays = unknown.filter { $0 >= first && $0 <= today }
            }
            return filled

        case .strength:
            let rows = await workoutRows()
            var minutesByDay: [String: Double] = [:]
            var firstDay: String?
            for w in rows {
                let sport = w.sport.lowercased()
                guard sport.contains("strength") || sport.contains("weight") else { continue }
                let minutes = (w.durationS ?? Double(w.endTs - w.startTs)) / 60
                guard minutes > 0 else { continue }
                let day = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(w.startTs)))
                firstDay = min(firstDay ?? day, day)
                minutesByDay[day, default: 0] += minutes
            }
            var filled = Self.zeroFilled(parts: [minutesByDay], firstDay: firstDay, r: r)
            filled.parts = []
            return filled

        case .stress:
            // Each day's stored daily score, printed as the Stress Monitor's gauge prints a level (cut to one
            // decimal, `HealthStressGauge.printed`), so a bar and its breakdown band never round into a band
            // the level is not in. Today's point is the monitor's own reading, laid over these on every call
            // (`withLiveToday`).
            let stored = await stressStoredSeries()
            return PulseTrendSeries(points: Self.points(stored.map { ($0.day, HealthStressGauge.printed($0.value)) },
                                                        through: today))

        case .vo2Estimate:
            let resolved = await repo.resolvedSeries(key: "vo2max_est", source: "my-whoop")
            return PulseTrendSeries(points: Self.points(resolved.points.map { ($0.day, $0.value) }, through: today))

        case .skinTemp:
            return Self.skinTemperature(r.days, fahrenheit: units.fahrenheit, through: today)

        case .explore(let key, let source):
            let rows = await repo.exploreSeries(key: key, source: source)
            var series = PulseTrendSeries(points: Self.points(rows.map { ($0.day, $0.value) }, through: today))
            if m.unit == "kg" && units.imperialMass {
                series.points = series.points.map { .init(day: $0.day, value: UnitFormatter.kgToPounds($0.value)) }
                series.unit = "lb"
            }
            return series
        }
    }

    /// TIME IN BED per night: the merged main night the Sleep dive and Home print (`SleepModel.mergeDay` over
    /// the same night groups, its `timeInBed`), with its bedtime and wake as minutes from the wake day's
    /// local midnight for the floating bars. A strap-only member has every night here; an imported in-bed
    /// figure (the WHOOP export's) wins its day's value.
    private func timeInBedSeries(_ r: PulseRequest) async -> PulseTrendSeries {
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let imported = await repo.exploreSeries(key: "in_bed_min", source: "my-whoop")
        let calendar = Calendar.current
        var minutes: [String: Double] = [:]
        var spans: [String: PulseTrendSpan] = [:]
        for g in groups {
            guard let night = SleepModel.mergeDay(g, habitualMidsleepSec: habitual, motionByStart: [:]) else { continue }
            let wake = Date(timeIntervalSince1970: TimeInterval(night.session.endTs))
            let key = Repository.localDayKey(wake)
            let midnight = calendar.startOfDay(for: wake)
            let bed = night.onsetDate.timeIntervalSince(midnight) / 60
            let up = wake.timeIntervalSince(midnight) / 60
            if up > bed { spans[key] = PulseTrendSpan(bed: bed, wake: up) }
            if night.timeInBed > 0 { minutes[key] = night.timeInBed }
        }
        for row in imported where row.value > 0 { minutes[row.day] = row.value }
        return PulseTrendSeries(points: Self.points(minutes.map { ($0.key, $0.value) }, through: r.day.key),
                                spans: spans.filter { $0.key <= r.day.key })
    }

    /// Every night's resolved sleep figures (need, consistency, debt, hours vs needed), the per-night read
    /// the Sleep tab and the stored Rest share.
    private func nightFigures(_ r: PulseRequest) async -> [ResolvedNightSleep] {
        await cached("trends.nights") { () async -> [ResolvedNightSleep] in
            let computed = await self.repo.computedSleep
            let rows = Self.rowsByDay(r.days)
            let keys = Set(rows.keys).union(computed.keys).union(r.importedSleep.keys)
            return keys.sorted().map { k in
                Repository.resolvedNightSleep(day: k, daily: rows[k], imported: r.importedSleep, computed: computed)
            }
        }
    }

    /// The cycle strip's phase per day (cycle awareness on), from the same model the cycle card reads.
    private func trendCyclePhases(_ r: PulseRequest) async -> [String: PulseTrendCyclePhase] {
        await cached("trends.cycle") { () async -> [String: PulseTrendCyclePhase] in
            let readings = r.days.map { d in
                PulseCycleOverlay.Reading(day: d.day, skinTempDevC: d.skinTempDevC,
                                          restingHR: d.restingHr.map(Double.init), hrv: d.avgHrv)
            }
            let built = PulseCycleOverlay.nights(readings)
            let starts = await self.repo.periodStarts()
            let phases = PulseCycleOverlay.phases(nights: built.nights, baselineUsable: built.baselineUsable,
                                                  loggedPeriodStarts: starts)
            return phases.mapValues { PulseTrendCyclePhase($0) }
        }
    }

    // MARK: Helpers

    /// Sorted points up to and including `today`, finite values only, one per day (the last wins).
    static func points(_ rows: [(String, Double)], through today: String) -> [PulseTrendMath.Point] {
        var byDay: [String: Double] = [:]
        for (day, value) in rows where day <= today && value.isFinite { byDay[day] = value }
        return byDay.keys.sorted().map { PulseTrendMath.Point(day: $0, value: byDay[$0] ?? 0) }
    }

    static func byDay(_ rows: [(day: String, value: Double)]) -> [String: Double] {
        Dictionary(rows.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
    }

    static func rowsByDay(_ days: [DailyMetric]) -> [String: DailyMetric] {
        Dictionary(days.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
    }

    /// Minutes derived from logged activities, one value for EVERY day from the history's first day to
    /// today: a day without an activity has no zone or strength time (WHOOP prints "0:00"), a true zero
    /// rather than a missing reading. The total is the headline; `parts` keeps each zone.
    static func zeroFilled(parts: [[String: Double]], firstDay: String?, r: PulseRequest,
                           unknown: Set<String> = []) -> PulseTrendSeries {
        let today = r.day.key
        let firstRow = r.days.map(\.day).min()
        guard let start = [firstDay, firstRow].compactMap({ $0 }).min(), start <= today,
              let count = PulseTrendMath.daysBetween(start, today) else { return PulseTrendSeries() }
        let keys = (0...count).map { PulseTrendMath.addDays(start, $0) }.filter { !unknown.contains($0) }
        let partPoints = parts.map { part in keys.map { PulseTrendMath.Point(day: $0, value: part[$0] ?? 0) } }
        let totals = keys.enumerated().map { i, k in
            PulseTrendMath.Point(day: k, value: partPoints.reduce(0) { $0 + $1[i].value })
        }
        return PulseTrendSeries(points: totals, parts: partPoints)
    }

    /// Skin temperature on ONE scale: the deviation from baseline when the newest reading has one (the
    /// My Dashboard row's rule), else the absolute reading; converted to °F when that is the setting.
    static func skinTemperature(_ days: [DailyMetric], fahrenheit: Bool, through today: String) -> PulseTrendSeries {
        func deviation(_ d: DailyMetric) -> Double? {
            d.skinTempDevC.flatMap { SkinTempDisplay.kind(of: $0) == .deviation ? $0 : nil }
        }
        func absolute(_ d: DailyMetric) -> Double? {
            d.skinTempC ?? d.skinTempDevC.flatMap { SkinTempDisplay.kind(of: $0) == .absolute ? $0 : nil }
        }
        let sorted = days.filter { $0.day <= today }.sorted { $0.day < $1.day }
        guard let latest = sorted.last(where: { deviation($0) != nil || absolute($0) != nil }),
              let lead = SkinTempDisplay.leadReading(absC: absolute(latest), devC: deviation(latest),
                                                     prefer: .deviation) else { return PulseTrendSeries() }
        let isDeviation = lead.kind == .deviation
        let rows = sorted.compactMap { d -> (String, Double)? in
            guard let c = isDeviation ? deviation(d) : absolute(d) else { return nil }
            let shown = fahrenheit ? (isDeviation ? c * 9 / 5 : c * 9 / 5 + 32) : c
            return (d.day, shown)
        }
        return PulseTrendSeries(points: points(rows, through: today),
                                unit: SkinTempDisplay.unitSymbol(kind: lead.kind, fahrenheit: fahrenheit),
                                signed: isDeviation)
    }
}

// MARK: - Cycle phases

/// A cycle phase as the Trend View's strip and legend draw it (§3.12 item 11), in `PulseTheme.Menstrual`'s
/// legend colours.
enum PulseTrendCyclePhase: String, CaseIterable, Hashable, Sendable {
    case menstrual, follicular, ovulatory, luteal

    init(_ phase: PulseCycleOverlay.Phase) {
        switch phase {
        case .menstrual: self = .menstrual
        case .follicular: self = .follicular
        case .ovulatory: self = .ovulatory
        case .luteal: self = .luteal
        }
    }

    var color: Color {
        switch self {
        case .menstrual: return PulseTheme.Menstrual.Phase.menstrual.dot
        case .follicular: return PulseTheme.Menstrual.Phase.follicular.dot
        case .ovulatory: return PulseTheme.Menstrual.Phase.ovulatory.dot
        case .luteal: return PulseTheme.Menstrual.Phase.luteal.dot
        }
    }

    var title: String {
        switch self {
        case .menstrual: return String(localized: "Menstrual")
        case .follicular: return String(localized: "Follicular")
        case .ovulatory: return String(localized: "Ovulatory")
        case .luteal: return String(localized: "Luteal")
        }
    }
}
#endif
