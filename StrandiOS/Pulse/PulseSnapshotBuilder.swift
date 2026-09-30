#if os(iOS)
import Foundation
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore
import WhoopProtocol

// MARK: - Request

/// Everything a build reads from the main actor, captured once in one main-actor hop so the build itself
/// never touches `Repository`'s published caches. The arrays are copy-on-write, so capturing them costs
/// nothing until something mutates the originals.
struct PulseRequest {
    let seq: Int
    let day: PulseDay
    let now: Date
    let days: [DailyMetric]
    let sleeps: [CachedSleepSession]
    let importedSleep: [String: ImportedSleepFigures]
    let vitalRows: [SourcedDailyMetric]
    let prefs: PulsePrefs
    let profile: PulseProfile
}

/// The display preferences a build formats with. Part of the model's rebuild key, so changing one of
/// them in Settings rebuilds the snapshots rather than leaving a stale unit on screen.
struct PulsePrefs: Equatable {
    var fahrenheit = false
    var skinTempPreferred: SkinTempDisplay.Kind = .absolute
    /// The day-cycle setting: a day's Effort window runs from sleep onset rather than midnight.
    var sleepOnsetDayCycle = true
    var effortMethod: StrainScorer.Method = .edwards
    var stressPersonalBaseline = false
    /// Tomorrow's wake time from the wind-down reminder when it is on, minutes after midnight.
    var alarmWakeMinute: Int?
}

/// The profile values scoring needs.
struct PulseProfile: Equatable {
    var effortHRmax: Double?
    var sex: String
    var zoneSet: HRZoneSet
}

// MARK: - Builder

/// Builds Pulse's snapshots OFF the main actor.
///
/// An actor, so its work runs on the cooperative pool rather than the main thread: the day's heart-rate
/// read, `StrainScorer` over it (the classic Today runs that on the main actor on every swipe), the
/// cumulative-strain prefixes, the sleep-night merge, the baselines and the 30-day comparisons all happen
/// here. `Repository`'s async reads still hop to the main actor for their own bookkeeping, but the rows
/// they return are processed here.
///
/// History-wide reads (series, workouts, sleep blocks) are cached per `refreshSeq`: swiping between days
/// re-reads nothing that a refresh has not changed. A build checks for cancellation after each await and
/// returns nil when superseded, so a fast run of swipes does not queue a build per day.
actor PulseSnapshotBuilder {
    private let repo: Repository

    init(repo: Repository) {
        self.repo = repo
    }

    // MARK: Per-refresh cache

    private struct Cache {
        var rest: [(day: String, value: Double)]?
        var stressStored: [(day: String, value: Double)]?
        var stepsEst: [(day: String, value: Double)]?
        var markers: [(day: String, value: Double)]?
        var apple: [AppleDaily]?
        var workouts: [WorkoutRow]?
        var sessions: [CachedSleepSession]?
        var habitual: Int?
        var habitualLoaded = false
        var nights: [[CachedSleepSession]]?
        var napMinByDay: [String: Double]?
        var todayStressScore: Double??
        var weekly: Weekly?
        /// Heart rate for a day window, keyed "dayKey|from". At most a few entries.
        var hr: [String: [HRSample]] = [:]
    }

    private struct Weekly {
        let fitnessAge: Double?
        let bodyAge: Double?
        let vitality: Double?
        let vo2max: Double?
    }

    private var cacheSeq = Int.min
    private var cache = Cache()

    private func begin(_ seq: Int) {
        guard seq != cacheSeq else { return }
        cacheSeq = seq
        cache = Cache()
    }

    private func restSeries() async -> [(day: String, value: Double)] {
        if let v = cache.rest { return v }
        let seq = cacheSeq
        let v = await repo.exploreSeries(key: "sleep_performance", source: "my-whoop")
        if seq == cacheSeq { cache.rest = v }
        return v
    }

    private func stressStoredSeries() async -> [(day: String, value: Double)] {
        if let v = cache.stressStored { return v }
        let seq = cacheSeq
        let v = await repo.series(key: "stress", source: "my-whoop")
        if seq == cacheSeq { cache.stressStored = v }
        return v
    }

    private func stepsEstSeries() async -> [(day: String, value: Double)] {
        if let v = cache.stepsEst { return v }
        let seq = cacheSeq
        let v = await repo.exploreSeries(key: "steps_est", source: "my-whoop")
        if seq == cacheSeq { cache.stepsEst = v }
        return v
    }

    private func onsetMarkers() async -> [(day: String, value: Double)] {
        if let v = cache.markers { return v }
        let seq = cacheSeq
        let v = await repo.exploreSeries(key: DayCycleIntelligenceIntegration.onsetKey, source: "my-whoop")
        if seq == cacheSeq { cache.markers = v }
        return v
    }

    private func appleRows() async -> [AppleDaily] {
        if let v = cache.apple { return v }
        let seq = cacheSeq
        let v = await repo.appleDailyRows()
        if seq == cacheSeq { cache.apple = v }
        return v
    }

    private func workoutRows() async -> [WorkoutRow] {
        if let v = cache.workouts { return v }
        let seq = cacheSeq
        let v = await repo.workoutRows()
        if seq == cacheSeq { cache.workouts = v }
        return v
    }

    private func habitualMidsleep() async -> Int? {
        if cache.habitualLoaded { return cache.habitual }
        let seq = cacheSeq
        let v = await repo.habitualMidsleepSec()
        if seq == cacheSeq { cache.habitual = v; cache.habitualLoaded = true }
        return v
    }

    /// Every sleep block grouped by the local day it ends on, newest day first: the SAME grouping the
    /// Sleep tab browses (`SleepModel.navDays`), so a night here is the night there.
    private func nightGroups(_ r: PulseRequest) async -> [[CachedSleepSession]] {
        if let v = cache.nights { return v }
        let seq = cacheSeq
        var sessions = cache.sessions
        if sessions == nil {
            let read = await repo.allSleepSessions()
            sessions = read
            if seq == cacheSeq { cache.sessions = read }
        }
        let all = (sessions ?? []).isEmpty ? r.sleeps : (sessions ?? [])
        let groups = SleepModel.navDays(navSessions: all)
        if seq == cacheSeq { cache.nights = groups }
        return groups
    }

    private func napMinutesByDay(_ r: PulseRequest) async -> [String: Double] {
        if let v = cache.napMinByDay { return v }
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let v = SleepModel.napSleepMinutesByDay(navDays: groups, habitualMidsleepSec: habitual)
        cache.napMinByDay = v
        return v
    }

    private func weekly() async -> Weekly {
        if let v = cache.weekly { return v }
        let seq = cacheSeq
        async let fit = repo.exploreSeries(key: "fitness_age", source: "my-whoop")
        async let body = repo.exploreSeries(key: "body_age", source: "my-whoop")
        async let vit = repo.exploreSeries(key: "vitality", source: "my-whoop")
        async let vo2 = repo.resolvedSeries(key: "vo2max_est", source: "my-whoop")
        let v = Weekly(fitnessAge: (await fit).last?.value,
                       bodyAge: (await body).last?.value,
                       vitality: (await vit).last?.value,
                       vo2max: (await vo2).points.last?.value)
        if seq == cacheSeq { cache.weekly = v }
        return v
    }

    /// The day window's heart rate, read once per refresh and shared by Home and the Strain dive.
    private func heartRate(dayKey: String, from: Int, to: Int) async -> [HRSample] {
        let key = "\(dayKey)|\(from)"
        if let v = cache.hr[key] { return v }
        let seq = cacheSeq
        // An explicit whole-window limit: the 8000 default is chart-sized and `hrSamples` truncates the
        // NEWEST rows, which would freeze the live score part-way through a real day (see LiquidTodayView).
        let v = await repo.hrSamples(from: from, to: to, limit: 200_000)
        if seq == cacheSeq {
            if cache.hr.count >= 3 { cache.hr.removeAll() }
            cache.hr[key] = v
        }
        return v
    }

    // MARK: Shared day resolution

    /// The day's row: today prefers the repository's resolved today row (its pre-04:00 local-day
    /// carve-out included), a past day reads its own row.
    private func displayRow(_ r: PulseRequest) -> DailyMetric? {
        r.days.last(where: { $0.day == r.day.key })
    }

    /// The window a day's Effort is scored over, resolved exactly as the Liquid Today resolves it: the
    /// day-cycle onset markers when that mode is on, else calendar midnight to now (today) or to the
    /// next midnight (a past day).
    private func dayWindow(_ r: PulseRequest) async -> (from: Int, to: Int) {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: r.day.date)
        let nextStart = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let calendarFrom = Int(dayStart.timeIntervalSince1970)
        let calendarTo = r.day.isToday ? Int(r.now.timeIntervalSince1970) : Int(nextStart.timeIntervalSince1970)
        let nextKey = Repository.localDayKey(nextStart)
        let markers = r.prefs.sleepOnsetDayCycle ? await onsetMarkers() : []
        let from = markers.last(where: { $0.day == r.day.key }).map { Int($0.value) } ?? calendarFrom
        let toExclusive = markers.last(where: { $0.day == nextKey }).map { Int($0.value) } ?? calendarTo
        return (from, max(from, toExclusive - 1))
    }

    /// Recovery for the day, through the SAME resolver the Liquid Today hero uses (#543 carry, the honest
    /// calibrating state), so the two shells cannot show different recoveries for one morning.
    private func chargeDisplay(_ r: PulseRequest, row: DailyMetric?) -> (LiquidTodayView.ChargeDisplay, DailyMetric?) {
        let tkey = row?.day ?? r.day.key
        let calibration = r.day.isToday
            ? RecoveryScorer.calibrationNights(nightlyHrv: r.days.map(\.avgHrv),
                                               dayKeys: r.days.map(\.day),
                                               hasRecovery: row?.recovery != nil)
            : nil
        let prior = TodayView.lastScoredRecoveryDay(days: r.days, selectedDayKey: tkey,
                                                    isToday: r.day.isToday,
                                                    todayScored: row?.recovery != nil,
                                                    isCalibrating: calibration != nil)
        let display = LiquidTodayView.ChargeDisplay.resolve(todayRecovery: row?.recovery, priorScored: prior,
                                                            calibrationNights: calibration, todayKey: tkey)
        // The row the dial's number came from: the day's own, or the carried night's.
        let source: DailyMetric?
        switch display {
        case .scored: source = row
        case .carried: source = prior
        default: source = nil
        }
        return (display, source)
    }

    private func recoveryDial(_ display: LiquidTodayView.ChargeDisplay) -> PulseDialData {
        switch display {
        case .scored(let pct):
            return PulseDialData(score: .recovery, value: pct, state: .scored,
                                 band: PulseDisplay.recoveryBand(percent: pct))
        case .carried(let pct, let caption):
            return PulseDialData(score: .recovery, value: pct, state: .carried(caption: caption),
                                 band: PulseDisplay.recoveryBand(percent: pct))
        case .calibrating(let nights):
            return PulseDialData(score: .recovery, value: nil,
                                 state: .calibrating(nights: nights, of: Baselines.minNightsSeed))
        case .noData:
            return PulseDialData(score: .recovery, value: nil, state: .noData)
        }
    }

    /// Sleep performance for the day: the night that ENDED on it, from the same `sleep_performance`
    /// series and freshness rule the Liquid Today reads.
    private func sleepDial(_ r: PulseRequest, rest: [(day: String, value: Double)]) -> PulseDialData {
        let own = rest.last(where: { $0.day == r.day.key })?.value
        if let own { return PulseDialData(score: .sleep, value: own, state: .scored) }
        let shown = TodayView.freshRestScore(todayValue: nil, lastDay: rest.last?.day,
                                             lastValue: rest.last?.value,
                                             isTodaySelected: r.day.isToday, todayKey: r.day.key)
        if let shown, let lastDay = rest.last?.day {
            return PulseDialData(score: .sleep, value: shown,
                                 state: .carried(caption: TodayView.carriedCaption(priorDayKey: lastDay,
                                                                                   todayKey: r.day.key)))
        }
        return PulseDialData(score: .sleep, value: nil, state: .noData)
    }

    /// The day's Effort on the WHOOP 0-21 axis: today's live score over the day window floored at the
    /// stored row (`StrainScorer.effectiveEffort`, the shared never-drop rule), a past day's stored row.
    private func strainValue(_ r: PulseRequest, row: DailyMetric?, hr: [HRSample]?) -> Double? {
        var live: Double?
        if r.day.isToday, let hr {
            // #2460: the manual HR-max override, then Tanaka, exactly as the stored day is scored.
            live = StrainScorer.strain(hr, maxHR: r.profile.effortHRmax,
                                       restingHR: row?.restingHr.map(Double.init) ?? StrainScorer.defaultRestingHR,
                                       method: r.prefs.effortMethod, sex: r.profile.sex)
        }
        return StrainScorer.effectiveEffort(live: live, stored: row?.strain)
            .map { UnitFormatter.effortValue($0, scale: .whoop) }
    }

    private func strainDial(_ value: Double?) -> PulseDialData {
        PulseDialData(score: .strain, value: value, state: value == nil ? .noData : .scored)
    }

    /// The recommended range for the day from the recovery the dial shows, through CoupledView's
    /// approved recovery-to-strain bands. Judged on the whole percent the dial prints.
    private func strainTarget(_ display: LiquidTodayView.ChargeDisplay, strain: Double?) -> PulseStrainTarget? {
        guard let pct = display.pct else { return nil }
        let shown = Double(PulseDisplay.displayedPercent(pct))
        guard let band = CoupledView.optimalStrainRange(recovery: shown) else { return nil }
        let carried: Bool
        if case .carried = display { carried = true } else { carried = false }
        return PulseStrainTarget(range: Double(band.lowerBound)...Double(band.upperBound),
                                 intent: PulseDisplay.strainIntent(recoveryPercent: shown),
                                 band: PulseDisplay.recoveryBand(percent: shown),
                                 current: strain, fromCarriedRecovery: carried)
    }

    private func workoutItems(_ rows: [WorkoutRow], window: (from: Int, to: Int)) -> [PulseWorkoutItem] {
        rows.filter { $0.startTs >= window.from && $0.startTs < window.to }
            .sorted { $0.startTs < $1.startTs }
            .map { w in
                let seconds = w.durationS ?? Double(max(w.endTs - w.startTs, 0))
                return PulseWorkoutItem(
                    id: "\(w.startTs)|\(w.sport)|\(w.source)",
                    title: WorkoutSource.displaySport(w.sport),
                    sport: w.sport,
                    start: Date(timeIntervalSince1970: TimeInterval(w.startTs)),
                    durationMin: Int((seconds / 60).rounded()),
                    strain: w.strain.map { UnitFormatter.effortValue($0, scale: .whoop) },
                    kcal: w.energyKcal,
                    route: PulseWorkoutRoute(row: w))
            }
    }

    /// The group of sleep blocks that ended on `dayKey`, if any.
    private func group(endingOn dayKey: String, in groups: [[CachedSleepSession]]) -> [CachedSleepSession]? {
        groups.first { g in
            guard let end = g.first?.endTs else { return false }
            return Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(end))) == dayKey
        }
    }

    /// Blocks outside the main-night group, up to the Sleep tab's nap ceiling.
    private func naps(in group: [CachedSleepSession], night: Night?) -> [PulseNap] {
        let main = night?.mainGroupStarts ?? []
        return group.filter { !main.contains($0.startTs) }.compactMap { b -> PulseNap? in
            let spanMin = Double(b.endTs - b.effectiveStartTs) / 60
            guard spanMin > 0, spanMin <= SleepView.napMaxHours * 60 else { return nil }
            let asleep = SleepView.decodedAsleepMinutes(b.stagesJSON, effectiveStartTs: b.effectiveStartTs)
            return PulseNap(id: b.startTs,
                            start: Date(timeIntervalSince1970: TimeInterval(b.effectiveStartTs)),
                            end: Date(timeIntervalSince1970: TimeInterval(b.endTs)),
                            asleepMin: asleep > 0 ? asleep : spanMin)
        }
        .sorted { $0.start < $1.start }
    }

    // MARK: - Home

    func home(_ r: PulseRequest) async -> HomeSnapshot? {
        begin(r.seq)
        let row = displayRow(r)
        let rest = await restSeries()
        guard !Task.isCancelled else { return nil }

        let (charge, _) = chargeDisplay(r, row: row)
        let window = await dayWindow(r)
        let hr: [HRSample]? = r.day.isToday
            ? await heartRate(dayKey: r.day.key, from: window.from, to: window.to)
            : nil
        guard !Task.isCancelled else { return nil }
        let strain = strainValue(r, row: row, hr: hr)
        let sleep = sleepDial(r, rest: rest)

        // My Day.
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let rows = await workoutRows()
        guard !Task.isCancelled else { return nil }
        var lastNight: PulseNightSummary?
        var napList: [PulseNap] = []
        if let g = group(endingOn: r.day.key, in: groups) {
            let night = SleepModel.mergeDay(g, habitualMidsleepSec: habitual, motionByStart: [:])
            if let night {
                lastNight = PulseNightSummary(
                    onset: night.onsetDate,
                    wake: Date(timeIntervalSince1970: TimeInterval(night.session.endTs)),
                    asleepMin: night.stages.asleep,
                    inBedMin: night.timeInBed,
                    performance: rest.last(where: { $0.day == r.day.key })?.value)
            }
            napList = naps(in: g, night: night)
        }
        let tonight = r.day.isToday ? await tonightPlan(r, groups: groups, habitual: habitual) : nil
        let stats = await keyStats(r, row: row)
        let stress = await stressSummary(r)
        guard !Task.isCancelled else { return nil }

        return HomeSnapshot(
            seq: r.seq,
            day: r.day,
            sleep: sleep,
            recovery: recoveryDial(charge),
            strain: strainDial(strain),
            target: strainTarget(charge, strain: strain),
            lastNight: lastNight,
            naps: napList,
            workouts: workoutItems(rows, window: window),
            tonight: tonight,
            stats: stats,
            stress: stress)
    }

    /// Tonight's need and bedtime from the existing personalized need and the debt ledger.
    private func tonightPlan(_ r: PulseRequest, groups: [[CachedSleepSession]], habitual: Int?) async -> PulseTonight? {
        let napMin = await napMinutesByDay(r)
        // TODO(analytics-merge): replace base need + debt with the unified sleep-need breakdown
        // (baseline + strain + debt - naps) once the analytics branch lands; keep this row's shape.
        let baseNeed = SleepModel.debtNeedMin(days: r.days)
        let ledger = SleepModel.debtLedger(days: r.days, napSleepMinByDay: napMin)
        let debt = ledger.isDebt ? ledger.magnitudeMin : 0
        let need = baseNeed + debt
        guard need > 0 else { return nil }

        let cal = Calendar.current
        let wakeMinute: Int
        let source: PulseTonight.WakeSource
        if let alarm = r.prefs.alarmWakeMinute {
            wakeMinute = alarm
            source = .alarm
        } else {
            let recent = groups.prefix(14).compactMap { g -> Int? in
                guard let end = SleepView.mainNightGroup(g, habitualMidsleepSec: habitual).last?.endTs else { return nil }
                let c = cal.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: TimeInterval(end)))
                return (c.hour ?? 0) * 60 + (c.minute ?? 0)
            }
            if recent.count >= 3, let median = PulseDisplay.medianClockMinute(recent) {
                wakeMinute = median
                source = .habit
            } else {
                wakeMinute = 7 * 60
                source = .fallback
            }
        }
        let bedMinute = PulseDisplay.bedtimeMinute(wakeMinute: wakeMinute, needMinutes: need)
        // Tonight: a bedtime after noon is this evening, one before noon is after midnight.
        let base = cal.startOfDay(for: r.now)
        let bedDay = bedMinute >= 12 * 60 ? base : (cal.date(byAdding: .day, value: 1, to: base) ?? base)
        let bedtime = bedDay.addingTimeInterval(TimeInterval(bedMinute * 60))
        return PulseTonight(baseNeedMin: baseNeed, debtMin: debt, needMin: need, bedtime: bedtime,
                            wake: bedtime.addingTimeInterval(need * 60), wakeSource: source)
    }

    // MARK: Key stats

    private struct StatValue {
        let value: Double
        let day: String
    }

    /// One tile's value vs its 30-day average plus its 14-day spark, all from `history`.
    private func stat(id: String, title: String, icon: String, value: StatValue?, text: (Double) -> String,
                      unit: String, history: [(day: String, value: Double)], route: TabRoute,
                      dayKey: String, flatPercent: Double = 2) -> PulseKeyStat {
        let comparison = value.flatMap { v in
            PulseDisplay.compare(value: v.value, history: history, dayKey: v.day, flatPercent: flatPercent)
        }.map { PulseStatText.comparison($0, unit: unit, absoluteText: text) }
        let byDay = Dictionary(history.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let spark = PulseDisplay.trailingDayKeys(endingOn: dayKey, count: 14).compactMap { byDay[$0] }
        let caption = value.flatMap { v in
            v.day == dayKey ? nil : TodayView.carriedCaption(priorDayKey: v.day, todayKey: dayKey)
        }
        return PulseKeyStat(id: id, title: title, icon: icon,
                            value: value.map { text($0.value) } ?? "–",
                            unit: value == nil ? "" : unit,
                            caption: caption, comparison: comparison, spark: spark, route: route)
    }

    private func keyStats(_ r: PulseRequest, row: DailyMetric?) async -> [PulseKeyStat] {
        let d = r.day
        let days = r.days
        let tkey = row?.day ?? d.key
        // Today's vitals carry per field from the last night that recorded each (#1842); a past day's
        // own row is the whole story. The same selectors the Liquid Today uses.
        let hrvRow = d.isToday ? Repository.lastHrvDay(days: days, todayKey: tkey) : nil
        let rhrRow = d.isToday ? Repository.lastRestingHrDay(days: days, todayKey: tkey) : nil
        let vitalsRow = d.isToday ? Repository.lastVitalsDay(days: days, todayKey: tkey) : nil
        let respRow = d.isToday ? Repository.lastRespDay(days: days, todayKey: tkey) : nil
        let skinRow = d.isToday ? Repository.lastSkinTempReadingDay(days: days, todayKey: tkey) : nil

        func pick(_ own: Double?, _ carries: [(DailyMetric?, Double?)]) -> StatValue? {
            if let own { return StatValue(value: own, day: tkey) }
            for (carryRow, v) in carries {
                if let carryRow, let v { return StatValue(value: v, day: carryRow.day) }
            }
            return nil
        }
        func series(_ f: (DailyMetric) -> Double?) -> [(day: String, value: Double)] {
            days.compactMap { m in f(m).map { (day: m.day, value: $0) } }
        }

        var out: [PulseKeyStat] = []

        out.append(stat(id: "hrv", title: String(localized: "HRV"), icon: "waveform.path.ecg",
                        value: pick(row?.avgHrv, [(hrvRow, hrvRow?.avgHrv)]),
                        text: PulseFormat.whole, unit: "ms", history: series(\.avgHrv),
                        route: .metric("hrv"), dayKey: d.key))
        out.append(stat(id: "rhr", title: String(localized: "Resting HR"), icon: "heart.fill",
                        value: pick(row?.restingHr.map(Double.init),
                                    [(rhrRow, rhrRow?.restingHr.map(Double.init))]),
                        text: PulseFormat.whole, unit: "bpm", history: series { $0.restingHr.map(Double.init) },
                        route: .metric("rhr"), dayKey: d.key))
        out.append(stat(id: "resp", title: String(localized: "Respiratory rate"), icon: "lungs.fill",
                        value: pick(row?.respRateBpm, [(vitalsRow, vitalsRow?.respRateBpm),
                                                      (respRow, respRow?.respRateBpm)]),
                        text: PulseFormat.oneDecimal, unit: "rpm", history: series(\.respRateBpm),
                        route: .metric("resp_rate"), dayKey: d.key))
        out.append(skinStat(r, row: row, carry: skinRow, dayKey: d.key))

        // SpO₂ only when a REAL percentage exists (an import or Apple Health): the strap estimate stays
        // behind its experimental toggle on the classic screens.
        if let spo2 = pick(row?.spo2Pct, [(vitalsRow, vitalsRow?.spo2Pct)]) {
            out.append(stat(id: "spo2", title: String(localized: "Blood Oxygen"), icon: "drop.fill",
                            value: spo2, text: PulseFormat.whole, unit: "%", history: series(\.spo2Pct),
                            route: .metric("spo2"), dayKey: d.key, flatPercent: 1))
        }

        let apple = await appleRows()
        let stepsEst = await stepsEstSeries()
        out.append(stepsStat(r, apple: apple, estimate: stepsEst))
        out.append(caloriesStat(r, row: row, apple: apple))
        return out
    }

    /// Skin temperature as a deviation from baseline when the night has one (the brief's read), else
    /// the night's absolute against its own 30-day average.
    private func skinStat(_ r: PulseRequest, row: DailyMetric?, carry: DailyMetric?, dayKey: String) -> PulseKeyStat {
        let source = [row, carry].compactMap { $0 }.first { $0.skinTempC != nil || $0.skinTempDevC != nil }
        // `skinTempDevC` is bimodal (#622): a CSV import writes an absolute there.
        let devC = source?.skinTempDevC.flatMap { SkinTempDisplay.kind(of: $0) == .deviation ? $0 : nil }
        let absC = source?.skinTempC
            ?? source?.skinTempDevC.flatMap { SkinTempDisplay.kind(of: $0) == .absolute ? $0 : nil }
        let reading = SkinTempDisplay.leadReading(absC: absC, devC: devC, prefer: .deviation)
        let f = r.prefs.fahrenheit
        let title = String(localized: "Skin temp")
        let route = TabRoute.metric("skin_temp")
        let history = r.days.compactMap { m -> (day: String, value: Double)? in
            guard let reading else { return nil }
            let v: Double?
            switch reading.kind {
            case .deviation: v = m.skinTempDevC.flatMap { SkinTempDisplay.kind(of: $0) == .deviation ? $0 : nil }
            case .absolute: v = m.skinTempC ?? m.skinTempDevC.flatMap { SkinTempDisplay.kind(of: $0) == .absolute ? $0 : nil }
            }
            return v.map { (day: m.day, value: $0) }
        }
        let byDay = Dictionary(history.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let spark = PulseDisplay.trailingDayKeys(endingOn: dayKey, count: 14).compactMap { byDay[$0] }
        guard let reading, let source else {
            return PulseKeyStat(id: "skin", title: title, icon: "thermometer.medium", value: "–", unit: "",
                                caption: nil, comparison: nil, spark: spark, route: route)
        }
        let unit = SkinTempDisplay.unitSymbol(kind: reading.kind, fahrenheit: f)
        let number = SkinTempDisplay.numberString(reading.value, kind: reading.kind, fahrenheit: f)
        let caption = source.day == dayKey ? nil
            : TodayView.carriedCaption(priorDayKey: source.day, todayKey: dayKey)
        let comparison: PulseComparison?
        switch reading.kind {
        case .deviation:
            // The number IS the comparison: a deviation from the personal baseline.
            let flat = abs(reading.value) < 0.1
            comparison = PulseComparison(
                direction: flat ? .flat : (reading.value > 0 ? .up : .down),
                text: flat ? String(localized: "Typical") : "\(number) \(unit)",
                caption: String(localized: "vs baseline"),
                accessibility: flat
                    ? String(localized: "in line with your baseline")
                    : (reading.value > 0
                       ? String(localized: "\(number) \(unit) above your baseline")
                       : String(localized: "\(number) \(unit) below your baseline")))
        case .absolute:
            // The gap to the average is a DIFFERENCE, so it converts ×9/5 with no +32 and carries Δ.
            let deltaUnit = SkinTempDisplay.unitSymbol(kind: .deviation, fahrenheit: f)
            comparison = PulseDisplay.compare(value: reading.value, history: history, dayKey: source.day,
                                              flatPercent: 0.5)
                .map { PulseStatText.comparison($0, unit: deltaUnit, absoluteText: { v in
                    PulseFormat.oneDecimal(f ? v * 9.0 / 5.0 : v)
                }) }
        }
        return PulseKeyStat(id: "skin", title: title, icon: "thermometer.medium", value: number, unit: unit,
                            caption: caption, comparison: comparison, spark: spark, route: route)
    }

    /// Steps for a day: the strap's measured count, else Apple Health's, else the motion estimate, the
    /// precedence every other steps surface uses, with the detail route for the source it chose.
    private func stepsResolution(_ r: PulseRequest, apple: [AppleDaily], estimate: [(day: String, value: Double)])
        -> (value: Double?, history: [(day: String, value: Double)], route: TabRoute) {
        // TODO(steps-merge): read the day's total, history and detail route from StepsService once the
        // steps branch lands, instead of resolving the three sources here.
        var appleByDay: [String: Double] = [:]
        for a in apple { if let s = a.steps { appleByDay[a.day] = max(appleByDay[a.day] ?? 0, Double(s)) } }
        let estByDay = Dictionary(estimate.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let measuredByDay = Dictionary(r.days.compactMap { m in m.steps.map { (m.day, Double($0)) } },
                                       uniquingKeysWith: { _, last in last })
        let keys = Set(appleByDay.keys).union(estByDay.keys).union(measuredByDay.keys).sorted()
        let history = keys.compactMap { k in
            (measuredByDay[k] ?? appleByDay[k] ?? estByDay[k]).map { (day: k, value: $0) }
        }
        let key = r.day.key
        let metric = MetricCatalog.todayStepsMetric(hasMeasuredSteps: measuredByDay[key] != nil,
                                                    hasImportedSteps: appleByDay[key] != nil)
        let route = TabRoute.metricSourced(key: metric?.key ?? "steps_est", source: metric?.source ?? "my-whoop")
        return (measuredByDay[key] ?? appleByDay[key] ?? estByDay[key], history, route)
    }

    private func stepsStat(_ r: PulseRequest, apple: [AppleDaily],
                           estimate: [(day: String, value: Double)]) -> PulseKeyStat {
        let steps = stepsResolution(r, apple: apple, estimate: estimate)
        return stat(id: "steps", title: String(localized: "Steps"), icon: "figure.walk",
                    value: steps.value.map { StatValue(value: $0, day: r.day.key) },
                    text: PulseFormat.grouped, unit: "", history: steps.history, route: steps.route,
                    dayKey: r.day.key, flatPercent: 5)
    }

    /// Active calories: Apple Health's imported figure first, else the on-device HR estimate (#616).
    private func caloriesStat(_ r: PulseRequest, row: DailyMetric?, apple: [AppleDaily]) -> PulseKeyStat {
        var importedByDay: [String: Double] = [:]
        for a in apple { if let k = a.activeKcal { importedByDay[a.day] = max(importedByDay[a.day] ?? 0, k) } }
        let deviceByDay = Dictionary(r.days.compactMap { m in m.activeKcalEst.map { (m.day, $0) } },
                                     uniquingKeysWith: { _, last in last })
        let keys = Set(importedByDay.keys).union(deviceByDay.keys).sorted()
        let history = keys.compactMap { k in (importedByDay[k] ?? deviceByDay[k]).map { (day: k, value: $0) } }
        let key = r.day.key
        let value = (importedByDay[key] ?? deviceByDay[key]).map { StatValue(value: $0, day: key) }
        let metric = MetricCatalog.todayCaloriesMetric(hasImportedKcal: importedByDay[key] != nil,
                                                       hasOnDeviceKcal: deviceByDay[key] != nil)
        let route = TabRoute.metricSourced(key: metric?.key ?? "energy_kcal", source: metric?.source ?? "my-whoop")
        return stat(id: "kcal", title: String(localized: "Calories"), icon: "flame.fill", value: value,
                    text: PulseFormat.grouped, unit: "kcal", history: history, route: route, dayKey: key,
                    flatPercent: 5)
    }

    // MARK: Stress

    private func stressSummary(_ r: PulseRequest) async -> PulseStressSummary? {
        let stored = await stressStoredSeries()
        if r.day.isToday {
            let score: Double?
            if let cached = cache.todayStressScore {
                score = cached
            } else {
                // StressModel folds the full history for its baseline; it is built here, off the main actor.
                score = StressModel(days: r.days, stored: stored)?.score
                cache.todayStressScore = .some(score)
            }
            let curve = await StressDayCurve.today(repo: repo, now: r.now,
                                                   personalBaseline: r.prefs.stressPersonalBaseline)
            return PulseStressSummary(score: score, bandTitle: score.map { StressBand(score: $0).title },
                                      hours: curve?.result.timeline ?? [],
                                      maskedHours: curve?.result.activityMaskedHours ?? 0, isToday: true)
        }
        guard let v = stored.last(where: { $0.day == r.day.key })?.value else { return nil }
        let score = min(max(v, 0), 3)
        return PulseStressSummary(score: score, bandTitle: StressBand(score: score).title, hours: [],
                                  maskedHours: 0, isToday: false)
    }

    // MARK: - Recovery

    func recovery(_ r: PulseRequest) async -> RecoverySnapshot? {
        begin(r.seq)
        let row = displayRow(r)
        let rest = await restSeries()
        guard !Task.isCancelled else { return nil }
        let (charge, source) = chargeDisplay(r, row: row)
        let dial = recoveryDial(charge)
        let days = r.days
        let restByDay = Dictionary(rest.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })

        func series(_ f: (DailyMetric) -> Double?) -> [(day: String, value: Double)] {
            days.compactMap { m in f(m).map { (day: m.day, value: $0) } }
        }
        func contributor(id: String, title: String, value: Double?, day: String?, unit: String,
                         text: (Double) -> String, history: [(day: String, value: Double)],
                         route: TabRoute?, flatPercent: Double = 2) -> PulseContributor {
            let c = value.flatMap { v in day.flatMap { dk in
                PulseDisplay.compare(value: v, history: history, dayKey: dk, flatPercent: flatPercent) } }
            return PulseContributor(
                id: id, title: title,
                value: value.map(text) ?? "–",
                unit: value == nil ? "" : unit,
                averageText: c.map { String(localized: "30-day avg \(text($0.average)) \(unit)") },
                comparison: c.map { PulseStatText.comparison($0, unit: unit, absoluteText: text) },
                route: route)
        }

        // Contributors are read off the SAME row the dial shows (its own, or the carried night's), so the
        // inputs never describe a different night from the number above them.
        let r0 = source
        let sourceDay = r0?.day
        let contributors = [
            contributor(id: "hrv", title: String(localized: "Heart rate variability"), value: r0?.avgHrv,
                        day: sourceDay, unit: "ms", text: PulseFormat.whole, history: series(\.avgHrv),
                        route: .metric("hrv")),
            contributor(id: "rhr", title: String(localized: "Resting heart rate"),
                        value: r0?.restingHr.map(Double.init), day: sourceDay, unit: "bpm",
                        text: PulseFormat.whole, history: series { $0.restingHr.map(Double.init) },
                        route: .metric("rhr")),
            contributor(id: "resp", title: String(localized: "Respiratory rate"), value: r0?.respRateBpm,
                        day: sourceDay, unit: "rpm", text: PulseFormat.oneDecimal,
                        history: series(\.respRateBpm), route: .metric("resp_rate")),
            contributor(id: "sleep", title: PulseScore.sleep.displayName,
                        value: sourceDay.flatMap { restByDay[$0] }, day: sourceDay, unit: "%",
                        text: PulseFormat.whole, history: rest,
                        route: .metric(HeroRingMetric.rest)),
        ]

        var context: [PulseContributor] = []
        if let dev = r0?.skinTempDevC, SkinTempDisplay.kind(of: dev) == .deviation {
            let f = r.prefs.fahrenheit
            let n = SkinTempDisplay.numberString(dev, kind: .deviation, fahrenheit: f)
            context.append(PulseContributor(id: "skin", title: String(localized: "Skin temperature"), value: n,
                                            unit: SkinTempDisplay.unitSymbol(kind: .deviation, fahrenheit: f),
                                            averageText: String(localized: "vs your baseline"),
                                            comparison: nil, route: .metric("skin_temp")))
        }
        if let spo2 = r0?.spo2Pct {
            context.append(contributor(id: "spo2", title: String(localized: "Blood oxygen"), value: spo2,
                                       day: sourceDay, unit: "%", text: PulseFormat.whole,
                                       history: series(\.spo2Pct), route: .metric("spo2"), flatPercent: 1))
        }

        // "What shaped it": the engine's own per-term breakdown for the dial's row, unchanged.
        let breakdown = r0.flatMap { row in
            ChargeBreakdownWiring.breakdown(days: days, row: row, sleepPerfPercent: restByDay[row.day],
                                            hrvBaselineEpoch: Baselines.hrvBaselineEpoch())
        }

        let keys = PulseDisplay.trailingDayKeys(endingOn: r.day.key, count: 90)
        let recByDay = Dictionary(days.compactMap { m in m.recovery.map { (m.day, $0) } },
                                  uniquingKeysWith: { _, last in last })
        let history = keys.compactMap { k -> PulseDayBar? in
            guard let v = recByDay[k] else { return nil }
            return PulseDayBar(id: k, value: v, label: PulseFormat.dayLabel(k),
                               band: PulseDisplay.recoveryBand(percent: v))
        }
        guard !Task.isCancelled else { return nil }
        return RecoverySnapshot(seq: r.seq, day: r.day, dial: dial, sourceDayKey: sourceDay,
                                contributors: contributors, context: context,
                                drivers: breakdown?.drivers ?? [], confidence: breakdown?.confidence,
                                skinTempRel: RecoveryScorer.skinTempRelative(
                                    deviationC: r0?.skinTempDevC.flatMap {
                                        SkinTempDisplay.kind(of: $0) == .deviation ? $0 : nil }),
                                history: history)
    }

    // MARK: - Strain

    func strain(_ r: PulseRequest) async -> StrainSnapshot? {
        begin(r.seq)
        let row = displayRow(r)
        let (charge, _) = chargeDisplay(r, row: row)
        let window = await dayWindow(r)
        let hr = await heartRate(dayKey: r.day.key, from: window.from, to: window.to)
        guard !Task.isCancelled else { return nil }
        let strain = strainValue(r, row: row, hr: hr)

        // Accumulation through the day, through the same scorer as the headline.
        let restingHR = row?.restingHr.map(Double.init) ?? StrainScorer.defaultRestingHR
        let curve = PulseDisplay.cumulativeStrain(hr: hr, from: window.from, to: window.to, stepSeconds: 15 * 60,
                                                  maxHR: r.profile.effortHRmax, restingHR: restingHR,
                                                  method: r.prefs.effortMethod, sex: r.profile.sex)
            .map { PulseTimePoint(date: Date(timeIntervalSince1970: TimeInterval($0.ts)),
                                  value: UnitFormatter.effortValue($0.effort, scale: .whoop)) }
        guard !Task.isCancelled else { return nil }

        // The chart: 5-minute means with gap-aware segments, like the Today HR card.
        let buckets = await repo.hrBuckets(from: window.from, to: window.to, bucketSeconds: 300)
        let segments = hrGapSegments(bucketTs: buckets.map(\.ts), bucketSeconds: 300)
        let points = buckets.enumerated().map { i, b in
            PulseHRPoint(date: Date(timeIntervalSince1970: TimeInterval(b.ts)), bpm: b.bpm,
                         segment: segments.indices.contains(i) ? segments[i] : "a")
        }

        let tiz = HRZones.timeInZone(hr, zoneSet: r.profile.zoneSet)
        let zones = r.profile.zoneSet.zones.map { PulseZoneBand(number: $0.number, lower: $0.lower, upper: $0.upper) }
        let bpms = hr.map(\.bpm)
        let average = bpms.isEmpty ? nil : Int((Double(bpms.reduce(0, +)) / Double(bpms.count)).rounded())

        let apple = await appleRows()
        let rows = await workoutRows()
        guard !Task.isCancelled else { return nil }
        let imported = apple.filter { $0.day == r.day.key }.compactMap(\.activeKcal).max()
        let start = Date(timeIntervalSince1970: TimeInterval(window.from))
        let end = Date(timeIntervalSince1970: TimeInterval(max(window.to, window.from + 60)))
        return StrainSnapshot(seq: r.seq, day: r.day, dial: strainDial(strain),
                              target: strainTarget(charge, strain: strain),
                              curve: curve, hr: points, window: start...end, zones: zones,
                              zoneMinutes: tiz.seconds.map { $0 / 60 },
                              calories: imported ?? row?.activeKcalEst,
                              averageHR: average, peakHR: bpms.max(),
                              workouts: workoutItems(rows, window: window))
    }

    // MARK: - Sleep

    /// The index of the newest night that ended on or before `dayKey` (the night Home's day refers to).
    func nightIndex(for r: PulseRequest) async -> Int {
        begin(r.seq)
        let groups = await nightGroups(r)
        return groups.firstIndex { g in
            guard let end = g.first?.endTs else { return false }
            return Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(end))) <= r.day.key
        } ?? 0
    }

    func sleep(_ r: PulseRequest, nightIndex: Int) async -> SleepSnapshot? {
        begin(r.seq)
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let rest = await restSeries()
        guard !Task.isCancelled else { return nil }
        let count = groups.count
        guard count > 0 else {
            return SleepSnapshot(seq: r.seq, nightIndex: 0, nightCount: 0, wakeDayKey: nil, onset: nil,
                                 wake: nil, dial: PulseDialData(score: .sleep, value: nil, state: .noData),
                                 asleepMin: nil, inBedMin: nil, needMin: nil, contributors: [], spans: [],
                                 stages: [], sleepingHR: nil, lowestHR: nil, respRate: nil, naps: [],
                                 isStub: true)
        }
        let index = min(max(0, nightIndex), count - 1)
        let group = groups[index]
        let night = SleepModel.mergeDay(group, habitualMidsleepSec: habitual, motionByStart: [:])
        let endTs = night?.session.endTs ?? group.last?.endTs ?? 0
        let wakeKey = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(endTs)))
        let row = r.days.last(where: { $0.day == wakeKey })

        // The dial reads the same `sleep_performance` point as Home's Sleep dial for this wake day.
        let perf = rest.last(where: { $0.day == wakeKey })?.value
            ?? row.flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
        let dial = PulseDialData(score: .sleep, value: perf, state: perf == nil ? .noData : .scored)

        let stages = night?.stages
        let asleep = stages?.asleep
        let inBed = stages?.total
        // Hours vs needed and consistency mirror the Sleep tab's own tiles (`SleepModel`), so this screen
        // and the classic one it links to agree about the same night.
        let need = r.importedSleep[wakeKey]?.needMin ?? SleepModel.sleepNeedMin(days: r.days)
        let hoursPct = asleep.flatMap { a in need > 0 && a > 0 ? min(100, a / need * 100) : nil }
        let effPct = stages.flatMap { s in s.total > 0 ? s.asleep / s.total * 100 : nil }
        let restorativePct = stages.flatMap { s in s.asleep > 0 ? (s.deep + s.rem) / s.asleep * 100 : nil }
        // TODO(analytics-merge): swap in the WHOOP-style sleep consistency once the analytics branch lands.
        let daysUpTo = r.days.filter { $0.day <= wakeKey }
        let sleepsUpTo = r.sleeps.filter { $0.endTs <= endTs }
        let consistency = SleepModel.consistencySeries(days: daysUpTo, sleeps: sleepsUpTo,
                                                       importedSleep: r.importedSleep).latest

        let contributors = [
            PulseSleepContributor(id: "hours", title: String(localized: "Hours vs needed"), percent: hoursPct,
                                  detail: asleep.map { a in
                                      String(localized: "\(PulseFormat.duration(minutes: a)) of \(PulseFormat.duration(minutes: need))")
                                  }),
            PulseSleepContributor(id: "efficiency", title: String(localized: "Efficiency"), percent: effPct,
                                  detail: inBed.map { String(localized: "\(PulseFormat.duration(minutes: $0)) in bed") }),
            PulseSleepContributor(id: "consistency", title: String(localized: "Consistency"),
                                  percent: consistency, detail: String(localized: "Bed and wake times")),
            PulseSleepContributor(id: "restorative", title: String(localized: "Restorative"),
                                  percent: restorativePct, detail: String(localized: "Deep and REM share")),
        ]

        let spans = (night?.intervals ?? []).map { PulseStageSpan(stage: $0.stage, start: $0.start, end: $0.end) }
        var stageRows: [PulseStageRow] = []
        if let s = stages, s.total > 0 {
            for (stage, minutes) in [(SleepStage.awake, s.awake), (.light, s.light), (.deep, s.deep), (.rem, s.rem)] {
                stageRows.append(PulseStageRow(stage: stage, minutes: minutes, share: minutes / s.total))
            }
        }

        // Sleeping heart rate over the night's own window (real instants).
        var sleepingHR: Int?
        var lowestHR: Int?
        if let night {
            let buckets = await repo.hrBuckets(from: night.session.effectiveStartTs, to: night.session.endTs,
                                               bucketSeconds: 60)
            guard !Task.isCancelled else { return nil }
            let bpm = buckets.map(\.bpm)
            if !bpm.isEmpty {
                sleepingHR = Int((bpm.reduce(0, +) / Double(bpm.count)).rounded())
                lowestHR = bpm.min().map { Int($0.rounded()) }
            }
        }

        return SleepSnapshot(
            seq: r.seq, nightIndex: index, nightCount: count, wakeDayKey: wakeKey,
            onset: night?.onsetDate,
            wake: night.map { Date(timeIntervalSince1970: TimeInterval($0.session.endTs)) },
            dial: dial, asleepMin: asleep, inBedMin: inBed, needMin: need,
            contributors: contributors, spans: spans, stages: stageRows,
            sleepingHR: sleepingHR, lowestHR: lowestHR, respRate: row?.respRateBpm,
            naps: naps(in: group, night: night), isStub: night == nil)
    }

    // MARK: - Health

    /// The Health tab. Always built for TODAY whatever day Home is showing: it is the "how am I now"
    /// surface, so the model hands it a today request.
    func health(_ r: PulseRequest) async -> HealthSnapshot? {
        begin(r.seq)
        let unit: TemperatureUnit = r.prefs.fahrenheit ? .fahrenheit : .celsius
        // The same resolution and banding the classic Health tile uses.
        let readings = BodyVitalSigns.readings(sourceRows: r.vitalRows, temperatureUnit: unit, now: r.now,
                                               skinTempPreferred: r.prefs.skinTempPreferred)
        let vitals = readings.compactMap { vital(for: $0, r: r) }
        let stress = await stressSummary(r)
        let weekly = await weekly()
        // TODO(steps-merge): the Health tab's Steps entry reads StepsService's today total and opens
        // StepsView once the steps branch lands; until then it resolves steps like the Home tile.
        let apple = await appleRows()
        let estimate = await stepsEstSeries()
        guard !Task.isCancelled else { return nil }
        let steps = stepsResolution(r, apple: apple, estimate: estimate)
        return HealthSnapshot(seq: r.seq, vitals: vitals, stress: stress, fitnessAge: weekly.fitnessAge,
                              bodyAge: weekly.bodyAge, vitality: weekly.vitality, vo2max: weekly.vo2max,
                              stepsToday: steps.value, stepsRoute: steps.route)
    }

    /// One Health Monitor row: the classic reading plus the typical range its band was judged against.
    private func vital(for reading: BodyVitalReading, r: PulseRequest) -> PulseVital? {
        // The raw PPG counts are not a vital, and SpO₂ only earns a row when a real value exists.
        guard reading.key != "spo2raw" else { return nil }
        if reading.key == "spo2" && reading.value == nil { return nil }

        let route: TabRoute
        let population: ClosedRange<Double>
        let cfg: MetricCfg?
        let extract: (DailyMetric) -> Double?
        let isAbsoluteSkin = reading.key == "skin" && (reading.value.map(VitalBands.isAbsoluteSkinTemp) ?? false)
        switch reading.key {
        case "resp":
            route = .metric("resp_rate"); population = 12...20; cfg = Baselines.respCfg
            extract = { $0.respRateBpm }
        case "spo2":
            route = .metric("spo2"); population = 95...100; cfg = nil
            extract = { $0.spo2Pct }
        case "rhr":
            route = .metric("rhr"); population = 40...60; cfg = Baselines.restingHRCfg
            extract = { $0.restingHr.map(Double.init) }
        case "hrv":
            route = .metric("hrv"); population = 40...120; cfg = Baselines.hrvCfg
            extract = { $0.avgHrv }
        case "skin":
            route = .metric("skin_temp")
            population = isAbsoluteSkin ? 33...36 : (-0.6)...0.6
            cfg = isAbsoluteSkin ? Baselines.metricCfg["skin_temp"] : VitalBands.skinTempDeviationCfg
            extract = isAbsoluteSkin
                ? { $0.skinTempC ?? $0.skinTempDevC.flatMap { VitalBands.isAbsoluteSkinTemp($0) ? $0 : nil } }
                : { $0.skinTempDevC.flatMap { VitalBands.isAbsoluteSkinTemp($0) ? nil : $0 } }
        default:
            return nil
        }

        // The typical range the band was judged against: the personal baseline ± VitalBands.sigmaK σ once
        // the baseline is trusted, else the fixed adult range, the same two yardsticks the band itself
        // uses (`VitalBands.band`). Folded from the same source precedence the reading used.
        var typical = population
        if reading.banding.basis == .personal, let cfg, let day = reading.day {
            // Source precedence, highest first: the rule `BodyVitalSigns` resolves readings by
            // (`DailyMetricSource.vitalPrecedence`, private to VitalSignsSummary.swift). Skin omits Apple
            // Health, which has no equivalent of the strap's deviation. Keep the two in step.
            let precedence: [DailyMetricSource] = reading.key == "skin"
                ? [.whoopImport, .noopComputed, .localCache]
                : [.whoopImport, .noopComputed, .appleHealth, .localCache]
            var byDay: [String: Double] = [:]
            for source in precedence {
                for row in r.vitalRows where row.source == source && row.metric.day < day {
                    guard let v = extract(row.metric), byDay[row.metric.day] == nil else { continue }
                    byDay[row.metric.day] = v
                }
            }
            let history = VitalBands.calendarSeries(byDay.keys.sorted().map { ($0, byDay[$0]) })
            let state = Baselines.foldHistory(history, cfg: cfg)
            if state.trusted {
                let half = VitalBands.sigmaK * Baselines.sigma(state)
                typical = (state.baseline - half)...(state.baseline + half)
            }
        }

        // Lay the value and the range on one bar with room either side.
        let v = reading.value
        let lo = min(typical.lowerBound, v ?? typical.lowerBound)
        let hi = max(typical.upperBound, v ?? typical.upperBound)
        let pad = max((hi - lo) * 0.25, 0.001)
        let barLo = lo - pad, barHi = hi + pad
        func frac(_ x: Double) -> Double { (x - barLo) / (barHi - barLo) }

        let format = reading.format
        let rangeText = "\(format(typical.lowerBound))–\(format(typical.upperBound))"
        return PulseVital(
            id: reading.key,
            title: reading.label,
            value: v.map(format),
            unit: reading.unit,
            band: reading.banding.band,
            basisText: reading.banding.basis == .personal
                ? String(localized: "Your typical range")
                : String(localized: "Typical adult range"),
            rangeText: rangeText,
            valueFraction: v.map(frac),
            typicalFraction: frac(typical.lowerBound)...frac(typical.upperBound),
            dayLabel: reading.day.map { BodyVitalReading.dayLabel($0) },
            route: route)
    }
}

// MARK: - Comparison text

/// Turns a `PulseDisplay.Comparison` into the words under a stat.
enum PulseStatText {
    static func comparison(_ c: PulseDisplay.Comparison, unit: String,
                           absoluteText: (Double) -> String) -> PulseComparison {
        let caption = String(localized: "vs 30-day avg")
        if let pct = c.percent {
            let n = Int(abs(pct).rounded())
            if c.direction == .flat || n == 0 {
                return PulseComparison(direction: .flat, text: String(localized: "Steady"), caption: caption,
                                       accessibility: String(localized: "in line with your 30-day average"))
            }
            let spoken = c.direction == .up
                ? String(localized: "\(n) percent above your 30-day average")
                : String(localized: "\(n) percent below your 30-day average")
            return PulseComparison(direction: c.direction, text: "\(n)%", caption: caption, accessibility: spoken)
        }
        let magnitude = absoluteText(abs(c.delta))
        if c.direction == .flat {
            return PulseComparison(direction: .flat, text: String(localized: "Steady"), caption: caption,
                                   accessibility: String(localized: "in line with your 30-day average"))
        }
        let spoken = c.direction == .up
            ? String(localized: "\(magnitude) \(unit) above your 30-day average")
            : String(localized: "\(magnitude) \(unit) below your 30-day average")
        return PulseComparison(direction: c.direction, text: "\(magnitude) \(unit)", caption: caption,
                               accessibility: spoken)
    }
}
#endif
