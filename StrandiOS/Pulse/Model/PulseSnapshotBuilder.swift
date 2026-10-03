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
    /// The strap alarm, the wind-down reminder and My Schedule's per-day times, as the Sleep Planner reads
    /// them (`PulseSleepPlanSettings.stored`), whether the strap will arm included: what tonight's plan is
    /// resolved from.
    var sleepPlan = PulseSleepPlanSettings()
    /// The journal prompt's switch (Settings, shared with the classic Today).
    var journalReminder = true
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
/// Screen groups add their own snapshots in an extension file in their folder
/// (`PulseSnapshotBuilder+<Group>.swift`), reusing the readers and resolvers below (`restSeries()`,
/// `workoutRows()`, `nightGroups(_:)`, `dayWindow(_:)`, `chargeDisplay(_:row:)`, …), the per-refresh
/// `cached(_:load:)` slot, and `begin(_:)` / `isCurrent(_:)` to stop when superseded. A screen runs one
/// through `PulseModel.build(_:)`. See StrandiOS/Pulse/ARCHITECTURE.md.
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
    let repo: Repository
    /// The optimal Strain range for each whole Recovery percent, 0...100 (`optimalStrainBands()`).
    private let strainBands: [ClosedRange<Double>?]

    init(repo: Repository, strainBands: [ClosedRange<Double>?]) {
        self.repo = repo
        self.strainBands = strainBands
    }

    /// CoupledView's approved recovery-to-strain bands (`CoupledView.optimalStrainRange`) for every whole
    /// percent a dial can print, read once on the main actor, where that rule is isolated, for the builder
    /// to look up off it.
    @MainActor
    static func optimalStrainBands() -> [ClosedRange<Double>?] {
        (0...100).map { percent in
            CoupledView.optimalStrainRange(recovery: Double(percent)).map { Double($0.lowerBound)...Double($0.upperBound) }
        }
    }

    // MARK: Per-refresh cache

    private struct Cache {
        var rest: [(day: String, value: Double)]?
        var stressStored: [(day: String, value: Double)]?
        var markers: [(day: String, value: Double)]?
        var apple: [AppleDaily]?
        var workouts: [WorkoutRow]?
        var sessions: [CachedSleepSession]?
        var habitual: Int?
        var habitualLoaded = false
        var nights: [[CachedSleepSession]]?
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
    /// Values extension files cache for the current refresh, by key (`cached(_:load:)`).
    private var extensionCache: [String: Any] = [:]

    /// Point the cache at `seq`, dropping everything read for an earlier refresh.
    ///
    /// The actor interleaves builds at every await, so a build begun for an older refresh can resume
    /// after a newer one has reset the cache. Every write below therefore checks the seq it read under
    /// against `cacheSeq`, and `isCurrent` lets a superseded build stop rather than publish: without
    /// that, a launch-time build over the still-empty day list wrote "no stress score" into the fresh
    /// refresh's cache, and Home showed a dash for the rest of that refresh.
    func begin(_ seq: Int) {
        guard seq > cacheSeq else { return }
        cacheSeq = seq
        cache = Cache()
        extensionCache = [:]
    }

    /// A value read once per refresh and shared by every build until the next one, for extension files:
    ///
    ///     let plans = await cached("plan.goals") { await repo.planGoals() }
    ///
    /// Keys are namespaced by the caller ("<group>.<what>"). A load begun under an older refresh is
    /// returned to its caller but not stored, exactly like the built-in readers. An optional `T` works too:
    /// a stored nil is a hit, a missing key loads.
    func cached<T>(_ key: String, load: () async -> T) async -> T {
        // Unwrap the lookup before casting: `nil as? T` succeeds when T is itself optional, which would
        // turn a missing key into a cached nil and never load.
        if let hit = extensionCache[key], let value = hit as? T { return value }
        let seq = cacheSeq
        let value = await load()
        if seq == cacheSeq { extensionCache[key] = value }
        return value
    }

    /// False once a newer refresh has begun: the build's data is stale and it should stop.
    func isCurrent(_ r: PulseRequest) -> Bool {
        r.seq == cacheSeq && !Task.isCancelled
    }

    /// Runs an extension build on this actor (`PulseModel.build`), so none of it touches the main actor.
    func run<S>(_ r: PulseRequest, _ work: @Sendable (isolated PulseSnapshotBuilder, PulseRequest) async -> S?) async -> S? {
        await work(self, r)
    }

    func restSeries() async -> [(day: String, value: Double)] {
        if let v = cache.rest { return v }
        let seq = cacheSeq
        let v = await repo.exploreSeries(key: "sleep_performance", source: "my-whoop")
        if seq == cacheSeq { cache.rest = v }
        return v
    }

    func stressStoredSeries() async -> [(day: String, value: Double)] {
        if let v = cache.stressStored { return v }
        let seq = cacheSeq
        let v = await repo.series(key: "stress", source: "my-whoop")
        if seq == cacheSeq { cache.stressStored = v }
        return v
    }

    func onsetMarkers() async -> [(day: String, value: Double)] {
        if let v = cache.markers { return v }
        let seq = cacheSeq
        let v = await repo.exploreSeries(key: DayCycleIntelligenceIntegration.onsetKey, source: "my-whoop")
        if seq == cacheSeq { cache.markers = v }
        return v
    }

    func appleRows() async -> [AppleDaily] {
        if let v = cache.apple { return v }
        let seq = cacheSeq
        let v = await repo.appleDailyRows()
        if seq == cacheSeq { cache.apple = v }
        return v
    }

    func workoutRows() async -> [WorkoutRow] {
        if let v = cache.workouts { return v }
        let seq = cacheSeq
        let v = await repo.workoutRows()
        if seq == cacheSeq { cache.workouts = v }
        return v
    }

    func habitualMidsleep() async -> Int? {
        if cache.habitualLoaded { return cache.habitual }
        let seq = cacheSeq
        let v = await repo.habitualMidsleepSec()
        if seq == cacheSeq { cache.habitual = v; cache.habitualLoaded = true }
        return v
    }

    /// Every sleep block grouped by the local day it ends on, newest day first: the SAME grouping the
    /// Sleep tab browses (`SleepModel.navDays`), so a night here is the night there.
    func nightGroups(_ r: PulseRequest) async -> [[CachedSleepSession]] {
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
    ///
    /// A finished day's window is fixed, but today's runs to now and the strap keeps writing into it
    /// without a refresh necessarily following (`refresh()` publishes only when the daily caches
    /// change). Keying today on a five-minute bucket of the window's end lets a foreground rebuild pick
    /// up new beats while a burst of rebuilds still shares one read.
    func heartRate(dayKey: String, from: Int, to: Int, isToday: Bool) async -> [HRSample] {
        let key = isToday ? "\(dayKey)|\(from)|\(to / 300)" : "\(dayKey)|\(from)"
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

    /// The day's own row. For today the model keyed the request with the repository's resolved today
    /// row (its pre-04:00 local-day carve-out included), so this finds that same row.
    func displayRow(_ r: PulseRequest) -> DailyMetric? {
        r.days.last(where: { $0.day == r.day.key })
    }

    /// The window a day's Effort is scored over, resolved exactly as the Liquid Today resolves it: the
    /// day-cycle onset markers when that mode is on, else calendar midnight to now (today) or to the
    /// next midnight (a past day).
    func dayWindow(_ r: PulseRequest) async -> (from: Int, to: Int) {
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
    func chargeDisplay(_ r: PulseRequest, row: DailyMetric?) -> (LiquidTodayView.ChargeDisplay, DailyMetric?) {
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

    func recoveryDial(_ display: LiquidTodayView.ChargeDisplay) -> PulseDialData {
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

    /// Sleep performance for the night that ENDED on `dayKey`: the stored `sleep_performance` point,
    /// else the Rest composite of that day's row, the order the Sleep tab resolves it in
    /// (`SleepModel.performanceSeries`). The ONE resolver Home's dial, Home's sleep row and the Sleep
    /// dive all read, so no two of them can show different numbers for the same night.
    func sleepPerformance(dayKey: String, rest: [(day: String, value: Double)],
                                  days: [DailyMetric]) -> Double? {
        rest.last(where: { $0.day == dayKey })?.value
            ?? days.last(where: { $0.day == dayKey }).flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
    }

    /// The Sleep dial for the day: the night that ended on it, else (today only) the last scored night
    /// under the Liquid Today's freshness rule, labelled as carried.
    func sleepDial(_ r: PulseRequest, rest: [(day: String, value: Double)]) -> PulseDialData {
        if let own = sleepPerformance(dayKey: r.day.key, rest: rest, days: r.days) {
            return PulseDialData(score: .sleep, value: own, state: .scored)
        }
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
    func strainValue(_ r: PulseRequest, row: DailyMetric?, hr: [HRSample]?) -> Double? {
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

    func strainDial(_ value: Double?) -> PulseDialData {
        PulseDialData(score: .strain, value: value, state: value == nil ? .noData : .scored)
    }

    /// The optimal Strain range for a Recovery as a dial prints it (a whole percent, 0...100), from
    /// CoupledView's approved bands as the builder read them at start-up.
    func optimalStrainRange(percent: Int) -> ClosedRange<Double>? {
        strainBands.indices.contains(percent) ? strainBands[percent] : nil
    }

    /// The recommended range for the day from the recovery the dial shows, through CoupledView's
    /// approved recovery-to-strain bands. Judged on the whole percent the dial prints.
    func strainTarget(_ display: LiquidTodayView.ChargeDisplay, strain: Double?,
                              isToday: Bool) -> PulseStrainTarget? {
        guard let pct = display.pct else { return nil }
        let percent = PulseDisplay.displayedPercent(pct)
        let shown = Double(percent)
        guard let band = optimalStrainRange(percent: percent) else { return nil }
        let carried: Bool
        if case .carried = display { carried = true } else { carried = false }
        return PulseStrainTarget(range: band,
                                 intent: PulseDisplay.strainIntent(recoveryPercent: shown),
                                 band: PulseDisplay.recoveryBand(percent: shown),
                                 current: strain, fromCarriedRecovery: carried, isToday: isToday)
    }

    func workoutItems(_ rows: [WorkoutRow], window: (from: Int, to: Int)) -> [PulseWorkoutItem] {
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
    func group(endingOn dayKey: String, in groups: [[CachedSleepSession]]) -> [CachedSleepSession]? {
        groups.first { g in
            guard let end = g.first?.endTs else { return false }
            return Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(end))) == dayKey
        }
    }

    /// Blocks outside the main-night group, up to the Sleep tab's nap ceiling.
    func naps(in group: [CachedSleepSession], night: Night?) -> [PulseNap] {
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
        guard isCurrent(r) else { return nil }

        let (charge, _) = chargeDisplay(r, row: row)
        let window = await dayWindow(r)
        let hr: [HRSample]? = r.day.isToday
            ? await heartRate(dayKey: r.day.key, from: window.from, to: window.to, isToday: r.day.isToday)
            : nil
        guard isCurrent(r) else { return nil }
        let strain = strainValue(r, row: row, hr: hr)
        let sleep = sleepDial(r, rest: rest)

        // My Day.
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let rows = await workoutRows()
        guard isCurrent(r) else { return nil }
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
                    performance: sleep.state == .scored ? sleep.value : nil)
            }
            napList = naps(in: g, night: night)
        }
        let tonight = r.day.isToday ? await tonightPlan(r) : nil
        let stats = await keyStats(r, row: row)
        let stress = await stressSummary(r)
        // The journal strip ends on the selected day; it stays on a past day (§2.9).
        let journal = r.prefs.journalReminder ? await journalStrip(endingOn: r.day.date, offset: r.day.offset) : nil
        let monitor = r.day.isToday ? monitorSummary(r) : nil
        guard isCurrent(r) else { return nil }

        let todayKey = Repository.localDayKey(r.now)
        let streak = r.day.isToday
            ? StreakCalculator.streaks(dayKeys: r.days.map(\.day), qualified: r.days.map { $0.recovery != nil },
                                       today: todayKey).current
            : nil

        return HomeSnapshot(
            seq: r.seq,
            day: r.day,
            sleep: sleep,
            recovery: recoveryDial(charge),
            strain: strainDial(strain),
            target: strainTarget(charge, strain: strain, isToday: r.day.isToday),
            lastNight: lastNight,
            naps: napList,
            workouts: workoutItems(rows, window: window),
            tonight: tonight,
            stats: stats,
            stress: stress,
            journal: journal,
            streak: streak,
            monitor: monitor,
            week: week(r, liveStrain: strain),
            scoredDays: r.days.reduce(0) { $0 + ($1.recovery != nil ? 1 : 0) })
    }

    /// The seven days ending on the selected one, oldest first: each day's stored Strain (0–21) and
    /// Recovery, with today's live Strain in place of the stored one.
    func week(_ r: PulseRequest, liveStrain: Double?) -> [PulseWeekDay] {
        let byDay = Dictionary(r.days.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
        return PulseDisplay.trailingDayKeys(endingOn: r.day.key, count: 7).map { key in
            let row = byDay[key]
            let stored = row?.strain.map { UnitFormatter.effortValue($0, scale: .whoop) }
            return PulseWeekDay(id: key, strain: key == r.day.key ? (liveStrain ?? stored) : stored,
                                recovery: row?.recovery)
        }
    }

    /// Today's vitals judged against their typical ranges, as the Health Monitor tile counts them: the same
    /// readings and bands the Health tab draws (`BodyVitalSigns`, `VitalBands`).
    func monitorSummary(_ r: PulseRequest) -> PulseMonitorSummary {
        let unit: TemperatureUnit = r.prefs.fahrenheit ? .fahrenheit : .celsius
        let readings = BodyVitalSigns.readings(sourceRows: r.vitalRows, temperatureUnit: unit, now: r.now,
                                               skinTempPreferred: r.prefs.skinTempPreferred)
            .filter { $0.key != "spo2raw" && !($0.key == "spo2" && $0.value == nil) }
        let judged = readings.filter { $0.banding.band != .noData }
        let out = judged.filter { $0.banding.band == .outOfRange }
        return PulseMonitorSummary(inRange: judged.count - out.count, judged: judged.count,
                                   outOfRange: out.map { Self.vitalName($0.key) })
    }

    /// Pulse's names for the vitals, the ones Recovery and the Health tab use.
    static func vitalName(_ key: String) -> String {
        switch key {
        case "resp": return String(localized: "Respiratory rate")
        case "spo2": return String(localized: "Blood oxygen")
        case "rhr": return String(localized: "Resting heart rate")
        case "hrv": return String(localized: "Heart rate variability")
        case "skin": return String(localized: "Skin temperature")
        default: return key
        }
    }

    /// The seven LOCAL calendar days ending on `date` (as the classic journal strip keys them) and which
    /// have a native journal entry; `offset` is how many days back `date` is (the journal opens on it).
    /// Not cached: logging an entry does not bump `refreshSeq`, and the read is one small indexed query.
    func journalStrip(endingOn date: Date, offset: Int) async -> PulseJournalStrip {
        let cal = Calendar.current
        let days = (0..<7).reversed().map { n -> (key: String, offset: Int) in
            (Repository.localDayKey(cal.date(byAdding: .day, value: -n, to: date) ?? date), offset + n)
        }
        let logged = await repo.nativeJournalDays(from: days.first?.key ?? "", to: days.last?.key ?? "")
        return PulseJournalStrip(days: days.map {
            PulseJournalStrip.Day(key: $0.key, offset: $0.offset, logged: logged.contains($0.key))
        })
    }

    /// Tonight's plan through the Sleep Planner's own resolver (`tonightSleepPlan`, Screens/Sleep, which runs
    /// `PulseSleepPlan.resolve` over the unified sleep need) on the settings the request captured: the wake
    /// the strap is really armed for (per-day times included), the bedtime with time to fall asleep. Home's
    /// TONIGHT'S SLEEP card and the planner it opens therefore print the same night.
    func tonightPlan(_ r: PulseRequest) async -> PulseTonight? {
        guard let plan = await tonightSleepPlan(r, settings: r.prefs.sleepPlan) else { return nil }
        return PulseTonight(needMin: plan.needMin, inBed: plan.bedtime, asleepBy: plan.asleepBy, wake: plan.wake,
                            wakeSource: plan.wakeSource)
    }

    // MARK: Key stats

    private struct StatValue {
        let value: Double
        let day: String
    }

    /// One tile's value vs its 30-day average plus its 14-day spark, all from `history`.
    /// `runningTotal`: the tile shows TODAY's still-accumulating count (steps, calories; callers pass the
    /// displayed day's `isToday`). Comparing a partial day with full-day averages would read as a steep
    /// drop every morning, so such a tile says "So far today" instead of showing a delta; any finished day
    /// compares normally.
    private func stat(id: String, title: String, icon: String, value: StatValue?, text: (Double) -> String,
                      unit: String, history: [(day: String, value: Double)], route: TabRoute,
                      dayKey: String, flatPercent: Double = 2, runningTotal: Bool = false) -> PulseKeyStat {
        let inProgress = runningTotal && value?.day == dayKey
        let compared = inProgress ? nil : value.flatMap { v in
            PulseDisplay.compare(value: v.value, history: history, dayKey: v.day, flatPercent: flatPercent)
        }
        let comparison = compared.map { PulseStatText.comparison($0, unit: unit, absoluteText: text) }
        let byDay = Dictionary(history.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let spark = PulseDisplay.trailingDayKeys(endingOn: dayKey, count: 14).compactMap { byDay[$0] }
        let caption = inProgress ? nil : value.flatMap { v in
            v.day == dayKey ? nil : TodayView.carriedCaption(priorDayKey: v.day, todayKey: dayKey)
        }
        let reference = compared?.reference
        let delta: Double? = value.flatMap { v in
            reference.map { ref in text(v.value) == text(ref) ? 0 : v.value - ref }
        }
        return PulseKeyStat(id: id, title: title, icon: icon,
                            value: value.map { text($0.value) } ?? "–",
                            unit: value == nil ? "" : unit,
                            caption: caption, comparison: comparison, spark: spark, route: route,
                            isRunningTotal: inProgress, baseline: reference.map(text), baselineDelta: delta)
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
        out.append(await stepsStat(r))
        out.append(caloriesStat(r, apple: apple))
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
    /// The day's steps from the ONE resolver every steps surface shares (Apple Health, then the iPhone
    /// pedometer, then a strap counter, then the strap estimate — see `StepsResolver`), so this tile, the
    /// Steps screen, its card and the classic Today can never show different counts. `history` covers the
    /// window the tile's 30-day comparison and 14-day spark read; taps open the Steps screen on that day.
    func stepsResolution(_ r: PulseRequest)
        async -> (value: Double?, history: [(day: String, value: Double)], route: TabRoute) {
        let key = r.day.key
        let from = PulseDisplay.dayKey(key, offsetBy: -Self.stepsHistoryDays) ?? key
        let resolved = await repo.resolvedStepDays(from: from, to: key).days
        let history = resolved.map { (day: $0.day, value: Double($0.steps)) }
        let value = resolved.last(where: { $0.day == key }).map { Double($0.steps) }
        return (value, history, .steps(day: key))
    }

    /// Days of step history behind the tile: its 30-day average plus a margin, never the whole store.
    private static let stepsHistoryDays = 45

    private func stepsStat(_ r: PulseRequest) async -> PulseKeyStat {
        let steps = await stepsResolution(r)
        return stat(id: "steps", title: String(localized: "Steps"), icon: "figure.walk",
                    value: steps.value.map { StatValue(value: $0, day: r.day.key) },
                    text: PulseFormat.grouped, unit: "", history: steps.history, route: steps.route,
                    dayKey: r.day.key, flatPercent: 5, runningTotal: r.day.isToday)
    }

    /// Active calories: Apple Health's imported figure first, else the on-device HR estimate (#616).
    private func caloriesStat(_ r: PulseRequest, apple: [AppleDaily]) -> PulseKeyStat {
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
                    flatPercent: 5, runningTotal: r.day.isToday)
    }

    // MARK: Stress

    /// The day's stress for Home's STRESS MONITOR tile and dashboard card, past days included: the Stress
    /// Monitor's own day (`stressDay`, Screens/Health, which caches its reads per refresh), so its level, the
    /// reading's time and the curve are the ones the screen the tile opens shows.
    func stressSummary(_ r: PulseRequest) async -> PulseStressSummary? {
        guard let day = await stressDay(r) else { return nil }
        return PulseStressSummary(score: day.gaugeLevel?.level, at: day.latest?.at, dayKey: day.dayKey,
                                  points: day.points, chartEnd: day.chartEnd, hours: day.hours,
                                  maskedHours: day.maskedHours, isToday: day.isToday)
    }

    // MARK: - Recovery

    func recovery(_ r: PulseRequest) async -> RecoverySnapshot? {
        begin(r.seq)
        let row = displayRow(r)
        let rest = await restSeries()
        guard isCurrent(r) else { return nil }
        let (charge, source) = chargeDisplay(r, row: row)
        let dial = recoveryDial(charge)
        let days = r.days
        let restByDay = Dictionary(rest.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })

        // Contributors are read off the SAME row the dial shows (its own, or the carried night's), so the
        // inputs never describe a different night from the number above them.
        let r0 = source
        let sourceDay = r0?.day

        func series(_ f: (DailyMetric) -> Double?) -> [(day: String, value: Double)] {
            days.compactMap { m in f(m).map { (day: m.day, value: $0) } }
        }
        /// A contributor against its 30-day mean (the terms the engine has no learned baseline for).
        func contributor(id: String, title: String, value: Double?, day: String?, unit: String,
                         text: (Double) -> String, history: [(day: String, value: Double)],
                         route: TabRoute?, flatPercent: Double = 2) -> PulseContributor {
            let c = value.flatMap { v in day.flatMap { dk in
                PulseDisplay.compare(value: v, history: history, dayKey: dk, flatPercent: flatPercent) } }
            return PulseContributor(
                id: id, title: title,
                value: value.map(text) ?? "–",
                unit: value == nil ? "" : unit,
                // The bare 30-day average under the value, as WHOOP prints it ("93", "75%").
                averageText: c.map { Self.baselineText(text($0.reference), unit: unit) },
                comparison: c.map { PulseStatText.comparison($0, unit: unit, absoluteText: text) },
                route: route)
        }
        /// A contributor against the baseline the engine scored it with, printed as the engine prints
        /// it; falls back to the 30-day mean when the engine had no usable baseline for the term.
        func engineContributor(id: String, title: String, value: Double?, baseline: BaselineState?,
                               fractionDigits: Int, unit: String, text: (Double) -> String,
                               history: [(day: String, value: Double)], route: TabRoute) -> PulseContributor {
            guard let value, let baseline,
                  let c = PulseDisplay.compare(value: value, baseline: baseline.baseline,
                                               fractionDigits: fractionDigits) else {
                return contributor(id: id, title: title, value: value, day: sourceDay, unit: unit,
                                   text: text, history: history, route: route)
            }
            // The value exactly as the comparison read it (rounded the engine's way), so the printed
            // figure and its arrow cannot disagree at a half.
            return PulseContributor(
                id: id, title: title, value: text(c.reference + c.delta), unit: unit,
                // The bare baseline under the value, as WHOOP prints it ("79", not "Baseline 79 ms").
                averageText: Self.baselineText(text(c.reference), unit: unit),
                comparison: PulseStatText.baselineComparison(c),
                route: route)
        }

        // The engine's baselines, folded ONCE here exactly as `ChargeBreakdownWiring.breakdown` folds them
        // (the same series, configs, HRV recalibration epoch and usable gates), and read by BOTH the
        // Contributors card and "What shaped it". The screen used to print a plain 30-day mean (55 bpm)
        // in one card and the engine's baseline (56 bpm) in the next; one fold makes that impossible.
        // Keep this in step with `ChargeBreakdownWiring.breakdown` if the engine's wiring changes.
        let hrvBase = Baselines.foldHistory(days.map(\.avgHrv), dayKeys: days.map(\.day), cfg: Baselines.hrvCfg,
                                            baselineEpoch: Baselines.hrvBaselineEpoch())
        let rhrFold = Baselines.foldHistory(days.map { $0.restingHr.map(Double.init) }, cfg: Baselines.restingHRCfg)
        let respFold = Baselines.foldHistory(days.map(\.respRateBpm), cfg: Baselines.respCfg)
        let rhrBase = rhrFold.usable ? rhrFold : nil
        let respBase = respFold.usable ? respFold : nil

        // "What shaped it": the engine's own per-term breakdown for the dial's row. Like the classic
        // sheet it hides when the night cannot honestly score (no HRV or resting HR, or an HRV baseline
        // that is not usable yet), and then the contributors fall back to their 30-day means as well.
        var drivers: [ChargeDriver] = []
        var confidence: ScoreConfidence?
        if let row = r0, let hrv = row.avgHrv, let rhr = row.restingHr, hrvBase.usable {
            drivers = RecoveryScorer.chargeDrivers(
                hrv: hrv, rhr: Double(rhr), resp: row.respRateBpm,
                hrvBaseline: hrvBase, rhrBaseline: rhrBase, respBaseline: respBase,
                sleepPerf: restByDay[row.day].map { $0 / 100.0 },
                skinTempDev: row.skinTempDevC)
            confidence = ScoreConfidence.charge(recovery: row.recovery, hrvBaseline: hrvBase)
        }
        let scored = !drivers.isEmpty

        let contributors = [
            engineContributor(id: "hrv", title: String(localized: "Heart rate variability"), value: r0?.avgHrv,
                              baseline: scored ? hrvBase : nil, fractionDigits: 0, unit: "ms",
                              text: PulseFormat.whole, history: series(\.avgHrv), route: .metric("hrv")),
            engineContributor(id: "rhr", title: String(localized: "Resting heart rate"),
                              value: r0?.restingHr.map(Double.init), baseline: scored ? rhrBase : nil,
                              fractionDigits: 0, unit: "bpm", text: PulseFormat.whole,
                              history: series { $0.restingHr.map(Double.init) }, route: .metric("rhr")),
            engineContributor(id: "resp", title: String(localized: "Respiratory rate"), value: r0?.respRateBpm,
                              baseline: scored ? respBase : nil, fractionDigits: 1, unit: "rpm",
                              text: PulseFormat.oneDecimal, history: series(\.respRateBpm),
                              route: .metric("resp_rate")),
            // The engine scores sleep against a fixed "good night", not a learned baseline.
            contributor(id: "sleep", title: PulseScore.sleep.displayName,
                        value: sourceDay.flatMap { sleepPerformance(dayKey: $0, rest: rest, days: days) },
                        day: sourceDay, unit: "%",
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

        let keys = PulseDisplay.trailingDayKeys(endingOn: r.day.key, count: 90)
        let recByDay = Dictionary(days.compactMap { m in m.recovery.map { (m.day, $0) } },
                                  uniquingKeysWith: { _, last in last })
        let history = keys.compactMap { k -> PulseDayBar? in
            guard let v = recByDay[k] else { return nil }
            return PulseDayBar(id: k, value: v, band: PulseDisplay.recoveryBand(percent: v))
        }
        guard isCurrent(r) else { return nil }
        return RecoverySnapshot(seq: r.seq, day: r.day, dial: dial, sourceDayKey: sourceDay,
                                contributors: contributors, context: context,
                                drivers: drivers, confidence: confidence,
                                history: history)
    }

    /// A contributor's baseline line: the bare number, keeping only a "%" (WHOOP's "75%" / "93").
    static func baselineText(_ number: String, unit: String) -> String {
        unit == "%" ? number + "%" : number
    }

    // MARK: - Strain

    func strain(_ r: PulseRequest) async -> StrainSnapshot? {
        begin(r.seq)
        let row = displayRow(r)
        let (charge, _) = chargeDisplay(r, row: row)
        let window = await dayWindow(r)
        let hr = await heartRate(dayKey: r.day.key, from: window.from, to: window.to, isToday: r.day.isToday)
        guard isCurrent(r) else { return nil }
        let strain = strainValue(r, row: row, hr: hr)

        // Accumulation through the day, through the same scorer as the headline.
        let restingHR = row?.restingHr.map(Double.init) ?? StrainScorer.defaultRestingHR
        let curve = PulseDisplay.cumulativeStrain(hr: hr, from: window.from, to: window.to, stepSeconds: 15 * 60,
                                                  maxHR: r.profile.effortHRmax, restingHR: restingHR,
                                                  method: r.prefs.effortMethod, sex: r.profile.sex)
            .map { PulseTimePoint(date: Date(timeIntervalSince1970: TimeInterval($0.ts)),
                                  value: UnitFormatter.effortValue($0.effort, scale: .whoop)) }
        guard isCurrent(r) else { return nil }

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
        guard isCurrent(r) else { return nil }
        let imported = apple.filter { $0.day == r.day.key }.compactMap(\.activeKcal).max()
        let start = Date(timeIntervalSince1970: TimeInterval(window.from))
        let end = Date(timeIntervalSince1970: TimeInterval(max(window.to, window.from + 60)))
        return StrainSnapshot(seq: r.seq, day: r.day, dial: strainDial(strain),
                              target: strainTarget(charge, strain: strain, isToday: r.day.isToday),
                              curve: curve, hr: points, window: start...end, zones: zones,
                              zoneMinutes: tiz.seconds.map { $0 / 60 },
                              calories: imported ?? row?.activeKcalEst,
                              averageHR: average, peakHR: bpms.max(),
                              workouts: workoutItems(rows, window: window))
    }

    // MARK: - Sleep

    /// The Sleep dive for the newest night that ended on or before `anchorKey` (a wake day key; Home's
    /// day when nil).
    ///
    /// Nights are addressed by wake day, never by position: a newly banked night shifts every index by
    /// one, so an index kept across a refresh would silently swap the screen to the neighbouring night.
    func sleep(_ r: PulseRequest, onOrBefore anchorKey: String?) async -> SleepSnapshot? {
        begin(r.seq)
        let groups = await nightGroups(r)
        let habitual = await habitualMidsleep()
        let rest = await restSeries()
        guard isCurrent(r) else { return nil }
        let anchor = anchorKey ?? r.day.key
        // `navDays` groups sessions by the local day they END on, newest first.
        let keys = groups.map { g in
            Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(g.first?.endTs ?? 0)))
        }
        guard !keys.isEmpty else {
            return SleepSnapshot(seq: r.seq, anchorKey: anchor, nightIndex: 0, nightKeys: [], wakeDayKey: nil,
                                 onset: nil, wake: nil,
                                 dial: PulseDialData(score: .sleep, value: nil, state: .noData),
                                 asleepMin: nil, inBedMin: nil, needMin: nil, contributors: [], spans: [],
                                 stages: [], sleepingHR: nil, lowestHR: nil, respRate: nil, naps: [],
                                 isStub: true)
        }
        // A day older than every banked night opens on the oldest night, the nearest one there is.
        let index = keys.firstIndex { $0 <= anchor } ?? keys.count - 1
        let group = groups[index]
        let night = SleepModel.mergeDay(group, habitualMidsleepSec: habitual, motionByStart: [:])
        let endTs = night?.session.endTs ?? group.last?.endTs ?? 0
        let wakeKey = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(endTs)))
        let row = r.days.last(where: { $0.day == wakeKey })

        // The same resolver as Home's Sleep dial for this wake day.
        let perf = sleepPerformance(dayKey: wakeKey, rest: rest, days: r.days)
        let dial = PulseDialData(score: .sleep, value: perf, state: perf == nil ? .noData : .scored)

        // Every duration on this screen is the merged main night the hypnogram draws, so the stage rows
        // add up to the "asleep" figure and the efficiency matches the classic stage card.
        let stages = night?.stages
        let asleep = stages?.asleep
        let inBed = stages?.total
        // Need and consistency come from the ONE per-night resolver (the export's figures for an imported
        // night, else the unified need and WHOOP-style bed + wake consistency the scoring pass stored), so
        // this screen, the Sleep tab and the stored Rest agree. Hours-vs-needed divides THIS screen's merged
        // main night by that need, so the percent and its "x of y" caption can never disagree.
        let resolved = await repo.resolvedNightSleep(day: wakeKey)
        guard isCurrent(r) else { return nil }
        let need = resolved.needMin
        let hoursPct = asleep.flatMap { a in
            need.flatMap { n in n > 0 && a > 0 ? min(100, a / n * 100) : nil }
        }
        let effPct = stages.flatMap { s in s.total > 0 ? s.asleep / s.total * 100 : nil }
        let restorativePct = stages.flatMap { s in s.asleep > 0 ? (s.deep + s.rem) / s.asleep * 100 : nil }
        let consistency = resolved.consistencyPct

        let contributors = [
            PulseSleepContributor(id: "hours", title: String(localized: "Hours vs needed"), percent: hoursPct,
                                  detail: asleep.map { a in
                                      guard let n = need else {
                                          return String(localized: "\(PulseFormat.duration(minutes: a)) asleep")
                                      }
                                      return String(localized: "\(PulseFormat.duration(minutes: a)) of \(PulseFormat.duration(minutes: n))")
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
            guard isCurrent(r) else { return nil }
            let bpm = buckets.map(\.bpm)
            if !bpm.isEmpty {
                sleepingHR = Int((bpm.reduce(0, +) / Double(bpm.count)).rounded())
                lowestHR = bpm.min().map { Int($0.rounded()) }
            }
        }

        return SleepSnapshot(
            seq: r.seq, anchorKey: anchor, nightIndex: index, nightKeys: keys, wakeDayKey: wakeKey,
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
        // The Steps entry reads today's total from the shared resolver and opens the Steps screen.
        let steps = await stepsResolution(r)
        guard isCurrent(r) else { return nil }
        return HealthSnapshot(seq: r.seq, vitals: vitals, stress: stress, fitnessAge: weekly.fitnessAge,
                              bodyAge: weekly.bodyAge, vitality: weekly.vitality, vo2max: weekly.vo2max,
                              stepsToday: steps.value, stepsRoute: steps.route)
    }

    /// One Health Monitor row: the classic reading plus the typical range its band was judged against.
    private func vital(for reading: BodyVitalReading, r: PulseRequest) -> PulseVital? {
        // The raw PPG counts are not a vital, and SpO₂ only earns a row when a real value exists.
        guard reading.key != "spo2raw" else { return nil }
        if reading.key == "spo2" && reading.value == nil { return nil }

        // Titles are Pulse's own names for these metrics, the ones Recovery uses, rather than the classic
        // monitor's abbreviations ("Resp Rate", "Blood O₂"), so one metric reads the same everywhere.
        let title: String
        let route: TabRoute
        let population: ClosedRange<Double>
        let cfg: MetricCfg?
        let extract: (DailyMetric) -> Double?
        let isAbsoluteSkin = reading.key == "skin" && (reading.value.map(VitalBands.isAbsoluteSkinTemp) ?? false)
        switch reading.key {
        case "resp":
            title = String(localized: "Respiratory rate")
            route = .metric("resp_rate"); population = 12...20; cfg = Baselines.respCfg
            extract = { $0.respRateBpm }
        case "spo2":
            title = String(localized: "Blood oxygen")
            route = .metric("spo2"); population = 95...100; cfg = nil
            extract = { $0.spo2Pct }
        case "rhr":
            title = String(localized: "Resting heart rate")
            route = .metric("rhr"); population = 40...60; cfg = Baselines.restingHRCfg
            extract = { $0.restingHr.map(Double.init) }
        case "hrv":
            title = String(localized: "Heart rate variability")
            route = .metric("hrv"); population = 40...120; cfg = Baselines.hrvCfg
            extract = { $0.avgHrv }
        case "skin":
            title = String(localized: "Skin temperature")
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
        var personal = false
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
                personal = true
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
        // A signed range reads badly with a dash between the signs ("-0.7–+0.8"), so it says "to".
        let rangeText = typical.lowerBound < 0
            ? String(localized: "\(format(typical.lowerBound)) to \(format(typical.upperBound))")
            : "\(format(typical.lowerBound))–\(format(typical.upperBound))"
        return PulseVital(
            id: reading.key,
            title: title,
            value: v.map(format),
            unit: reading.unit,
            band: reading.banding.band,
            basisText: personal
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

    /// A value against the engine's learned baseline (`PulseDisplay.compare(value:baseline:…)`). Equal
    /// printed figures read "Near baseline", which holds whether the engine calls the row "at baseline"
    /// or "slightly above / below baseline" (both happen when the two figures print the same).
    static func baselineComparison(_ c: PulseDisplay.Comparison) -> PulseComparison {
        let caption = String(localized: "vs baseline")
        guard c.direction != .flat, let pct = c.percent else {
            return PulseComparison(direction: .flat, text: String(localized: "Near baseline"), caption: caption,
                                   accessibility: String(localized: "near your baseline"))
        }
        // Figures that print differently are never "0%": a sub-percent gap still points the right way.
        let n = Int(abs(pct).rounded())
        let text = n == 0 ? "<1%" : "\(n)%"
        let amount = n == 0 ? String(localized: "less than 1 percent") : String(localized: "\(n) percent")
        let spoken = c.direction == .up
            ? String(localized: "\(amount) above your baseline")
            : String(localized: "\(amount) below your baseline")
        return PulseComparison(direction: c.direction, text: text, caption: caption, accessibility: spoken)
    }
}
#endif
