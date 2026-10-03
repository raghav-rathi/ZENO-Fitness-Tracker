#if os(iOS)
import Foundation
import SwiftUI
import StrandAnalytics
import StrandDesign
import StrandImport
import WhoopStore
import WhoopProtocol

// MARK: - Health group builds (off the main actor)
//
// The Health tab, Health Monitor, Stress Monitor and Healthspan, built from the core readers
// (`nightGroups`, `stepsResolution`, `stressStoredSeries`, …) plus per-refresh cached reads of their own.
// Each fact has one resolver here that every screen asking for it shares:
//   - `healthVitals`   the vitals, banded exactly as Home's HEALTH MONITOR tile counts them;
//   - `healthAgeWeeks` ZENO Age per week, with the whole-year age the engine scored it with;
//   - `stressDay`      a day's stress level AND curve, from the intraday curve (one source for both).

/// Carries an optional value through the builder's per-refresh cache.
private struct HealthCacheBox<T> {
    let value: T?
}

extension PulseSnapshotBuilder {

    /// `cached(_:load:)` for an optional value. The core slot looks a key up with `as? T`, and when `T` is
    /// itself optional a missing key casts to a cached `nil`, so the value would never load; boxed, it does.
    func cachedOptional<T>(_ key: String, load: () async -> T?) async -> T? {
        await cached(key) { HealthCacheBox(value: await load()) }.value
    }

    // MARK: - Health tab

    /// The Health tab, always for today. `dateOfBirth` is the profile's (read on the main actor by the view).
    func healthTab(_ r: PulseRequest, dateOfBirth: Date) async -> HealthTabSnapshot? {
        begin(r.seq)
        let weeks = await healthAgeWeeks(dateOfBirth: dateOfBirth, now: r.now)
        let groups = await nightGroups(r)
        guard isCurrent(r) else { return nil }
        let age = healthAgeState(r, weeks: weeks, groups: groups)
        let labs = await healthLabs()
        let stress = await stressDay(r)
        let steps = await stepsResolution(r)
        guard isCurrent(r) else { return nil }
        let card = stress.map { day -> HealthStressCard in
            let todayHours = day.hours
            let scored = todayHours.contains { $0.level != nil }
            let start = Calendar.current.startOfDay(for: r.now)
            return HealthStressCard(
                highMinutes: scored ? StressDayTotals.totals(todayHours).highMinutes : nil,
                points: day.points.filter { $0.date >= start },
                dayKey: day.dayKey)
        }
        return HealthTabSnapshot(seq: r.seq, age: age, labs: labs, vitals: healthVitals(r), stress: card,
                                 stepsToday: steps.value, stepsRoute: steps.route)
    }

    /// The typical same weekday's HIGH minutes up to this hour, for the tab's "vs. typical Tue" chip. Built
    /// in a second pass because it reads six earlier days of heart rate.
    func healthTypicalHighMinutes(_ r: PulseRequest) async -> Int? {
        begin(r.seq)
        let typical = await stressTypical(r, dayStart: Calendar.current.startOfDay(for: r.now), isToday: true)
        guard isCurrent(r) else { return nil }
        return typical.totals?.highMinutes
    }

    // MARK: - ZENO Age

    /// Every stored weekly ZENO Age, oldest first, with the whole-year age the profile had at the end of that
    /// week (the age the weekly pass scored it with, `profile.age` at the time).
    func healthAgeWeeks(dateOfBirth: Date, now: Date) async -> [HealthAgeWeek] {
        let series = await cached("health.bodyAge") {
            await repo.exploreSeries(key: "body_age", source: "my-whoop")
        }
        let cal = Calendar.current
        var byWeek: [String: Double] = [:]
        for point in series where point.value.isFinite && point.value > 0 { byWeek[point.day] = point.value }
        return byWeek.keys.sorted().compactMap { key -> HealthAgeWeek? in
            guard let value = byWeek[key], let start = Self.healthLocalNoon(key),
                  let weekEnd = cal.date(byAdding: .day, value: 6, to: start) else { return nil }
            let scoredAt = min(weekEnd, now)
            guard let years = cal.dateComponents([.year], from: dateOfBirth, to: scoredAt).year, years > 0 else {
                return nil
            }
            return HealthAgeWeek(id: key, zenoAge: value, chronoAge: Double(years))
        }
    }

    /// Unlocked once there is a recent ZENO Age (within five weeks) and 21 nights of sleep in the last 31
    /// days (§3.20 item 3 [Z], WHOOP's own threshold).
    func healthAgeState(_ r: PulseRequest, weeks: [HealthAgeWeek], groups: [[CachedSleepSession]]) -> HealthAgeState {
        let needed = Self.healthUnlockNights
        let nights = nightsLogged(r, groups: groups, withinDays: 31)
        let todayKey = Repository.localDayKey(r.now)
        guard let latest = weeks.last, nights >= needed,
              let cutoff = PulseDisplay.dayKey(todayKey, offsetBy: -35), latest.id >= cutoff else {
            return .unlocking(nights: min(nights, needed), needed: needed)
        }
        return .ready(ageSummary(for: latest, in: weeks))
    }

    static let healthUnlockNights = 21

    func ageSummary(for week: HealthAgeWeek, in weeks: [HealthAgeWeek]) -> HealthAgeSummary {
        let paceWeeks = weeks.map(\.paceWeek)
        let pace = PaceOfAging.pace(paceWeeks, asOf: week.id)
        let previous = weeks.last(where: { $0.id < week.id }).flatMap { PaceOfAging.pace(paceWeeks, asOf: $0.id) }
        let settling = PaceOfAging.weeksInWindow(paceWeeks, endingOn: week.id) < PaceOfAging.settledWeeks
        return HealthAgeSummary(week: week, pace: pace, previousPace: previous, settling: settling)
    }

    /// Distinct nights (wake days) with sleep in the `withinDays` days ending today.
    func nightsLogged(_ r: PulseRequest, groups: [[CachedSleepSession]], withinDays: Int) -> Int {
        let todayKey = Repository.localDayKey(r.now)
        guard let from = PulseDisplay.dayKey(todayKey, offsetBy: -(withinDays - 1)) else { return 0 }
        var keys = Set<String>()
        for g in groups {
            guard let end = g.map(\.endTs).max() else { continue }
            let key = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(end)))
            if key >= from && key <= todayKey { keys.insert(key) }
        }
        return keys.count
    }

    /// Noon on a local "yyyy-MM-dd" day (a stable instant inside the day, whatever its DST).
    static func healthLocalNoon(_ key: String) -> Date? {
        healthKeyParser.date(from: key).map { $0.addingTimeInterval(12 * 3600) }
    }

    private static let healthKeyParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Lab Book

    /// What the Lab Book holds, by category (nil when it is empty). Status-free: the Lab Book never judges
    /// a value (LabBookView's promise).
    func healthLabs() async -> HealthLabsSummary? {
        await cachedOptional("health.labs") { () async -> HealthLabsSummary? in
            guard let store = await repo.storeHandle() else { return nil }
            let deviceId = await repo.deviceId
            var rows: [(LabMarkerCategory, LabMarkerRow)] = []
            for category in LabMarkerCategory.allCases {
                let read = (try? await store.labMarkers(deviceId: deviceId, category: category.rawValue)) ?? []
                rows += read.map { (category, $0) }
            }
            guard !rows.isEmpty else { return nil }
            var markersByCategory: [LabMarkerCategory: Set<String>] = [:]
            for (category, row) in rows { markersByCategory[category, default: []].insert(row.markerKey) }
            let categories = LabMarkerCategory.allCases.compactMap { c -> HealthLabsSummary.Category? in
                guard let keys = markersByCategory[c], !keys.isEmpty else { return nil }
                return HealthLabsSummary.Category(id: c.rawValue, title: c.displayName, markers: keys.count)
            }
            .sorted { $0.markers > $1.markers }
            return HealthLabsSummary(markers: Set(rows.map { $0.1.markerKey }).count, readings: rows.count,
                                     categories: categories, lastUpdatedKey: rows.map { $0.1.day }.max())
        }
    }

    // MARK: - Vitals

    /// Today's vitals as the Health Monitor and the Health tab show them: the readings and bands of
    /// `BodyVitalSigns` (the ones Home's tile counts), worded against a ±1σ personal range when the
    /// baseline is trusted, else the typical adult range.
    func healthVitals(_ r: PulseRequest) -> [HealthVital] {
        let unit: TemperatureUnit = r.prefs.fahrenheit ? .fahrenheit : .celsius
        let readings = BodyVitalSigns.readings(sourceRows: r.vitalRows, temperatureUnit: unit, now: r.now,
                                               skinTempPreferred: r.prefs.skinTempPreferred)
        let order = ["resp", "spo2", "rhr", "hrv", "skin"]
        let todayKey = BodyVitalSigns.logicalDayKey(r.now)
        return readings.compactMap { healthVital($0, r: r, todayKey: todayKey) }
            .sorted { (order.firstIndex(of: $0.id) ?? 9) < (order.firstIndex(of: $1.id) ?? 9) }
    }

    private func healthVital(_ reading: BodyVitalReading, r: PulseRequest, todayKey: String) -> HealthVital? {
        guard reading.key != "spo2raw" else { return nil }
        if reading.key == "spo2" && reading.value == nil { return nil }

        let name: String, tileTitle: String, shortTitle: String, symbol: String
        let route: TabRoute
        let population: ClosedRange<Double>
        let cfg: MetricCfg?
        let extract: (DailyMetric) -> Double?
        let isAbsoluteSkin = reading.key == "skin" && (reading.value.map(VitalBands.isAbsoluteSkinTemp) ?? false)
        switch reading.key {
        case "resp":
            name = String(localized: "Respiratory rate"); tileTitle = name; shortTitle = String(localized: "Resp")
            symbol = "lungs"; route = .metric("resp_rate"); population = 12...20; cfg = Baselines.respCfg
            extract = { $0.respRateBpm }
        case "spo2":
            name = String(localized: "Blood oxygen"); tileTitle = String(localized: "Blood oxygen (SpO₂)")
            shortTitle = String(localized: "SpO₂"); symbol = "drop"; route = .metric("spo2")
            population = 95...100; cfg = nil; extract = { $0.spo2Pct }
        case "rhr":
            name = String(localized: "Resting heart rate"); tileTitle = String(localized: "RHR")
            shortTitle = String(localized: "RHR"); symbol = "arrow.down.heart"; route = .metric("rhr")
            population = 40...60; cfg = Baselines.restingHRCfg; extract = { $0.restingHr.map(Double.init) }
        case "hrv":
            name = String(localized: "Heart rate variability"); tileTitle = String(localized: "HRV")
            shortTitle = String(localized: "HRV"); symbol = "waveform.path.ecg"; route = .metric("hrv")
            population = 40...120; cfg = Baselines.hrvCfg; extract = { $0.avgHrv }
        case "skin":
            name = String(localized: "Skin temperature")
            tileTitle = isAbsoluteSkin ? String(localized: "Skin temp") : String(localized: "Skin temp (from baseline)")
            shortTitle = String(localized: "Temp"); symbol = "thermometer.medium"; route = .metric("skin_temp")
            population = isAbsoluteSkin ? 33...36 : (-0.6)...0.6
            cfg = isAbsoluteSkin ? Baselines.metricCfg["skin_temp"] : VitalBands.skinTempDeviationCfg
            extract = isAbsoluteSkin
                ? { $0.skinTempC ?? $0.skinTempDevC.flatMap { VitalBands.isAbsoluteSkinTemp($0) ? $0 : nil } }
                : { $0.skinTempDevC.flatMap { VitalBands.isAbsoluteSkinTemp($0) ? nil : $0 } }
        default:
            return nil
        }

        let format = reading.format
        guard let v = reading.value else {
            return HealthVital(id: reading.key, name: name, tileTitle: tileTitle, shortTitle: shortTitle,
                               symbol: symbol, value: nil, unit: reading.unit, status: .noData,
                               chipText: String(localized: "No reading yet"), direction: 0, dayKey: nil,
                               isCarried: false, isPersonal: false, route: route)
        }

        // The personal baseline the band judged against, folded from the same source precedence the reading
        // used (`DailyMetricSource.vitalPrecedence`): the core's Health Monitor rows fold it the same way.
        var state: BaselineState?
        if reading.banding.basis == .personal, let cfg, let day = reading.day {
            let precedence: [DailyMetricSource] = reading.key == "skin"
                ? [.whoopImport, .noopComputed, .localCache]
                : [.whoopImport, .noopComputed, .appleHealth, .localCache]
            var byDay: [String: Double] = [:]
            for source in precedence {
                for row in r.vitalRows where row.source == source && row.metric.day < day {
                    guard let x = extract(row.metric), byDay[row.metric.day] == nil else { continue }
                    byDay[row.metric.day] = x
                }
            }
            let folded = Baselines.foldHistory(VitalBands.calendarSeries(byDay.keys.sorted().map { ($0, byDay[$0]) }),
                                               cfg: cfg)
            if folded.trusted { state = folded }
        }

        let inRange = reading.banding.band == .inRange
        let status: HealthVital.Status
        let chip: String
        let direction: Int
        if let state {
            let sigma = Baselines.sigma(state)
            let z = Baselines.deviation(v, state: state).z
            let lo = format(state.baseline - sigma), hi = format(state.baseline + sigma)
            let range = Self.rangeText(lo, hi, unit: reading.unit)
            let az = abs(z)
            direction = az <= 1 ? 0 : (z < 0 ? -1 : 1)
            if inRange {
                status = .within
                if az <= 1 {
                    chip = String(localized: "within \(range)")
                } else if az <= 1.5 {
                    chip = String(localized: "near \(range)")
                } else {
                    chip = z < 0 ? String(localized: "low < \(Self.bound(lo, unit: reading.unit))")
                                 : String(localized: "high > \(Self.bound(hi, unit: reading.unit))")
                }
            } else {
                let severe = az > 3
                status = .outside(severe: severe)
                let below = z < 0 || (az <= 1 && v < state.baseline)
                if severe {
                    chip = below ? String(localized: "very low < \(Self.bound(lo, unit: reading.unit))")
                                 : String(localized: "very high > \(Self.bound(hi, unit: reading.unit))")
                } else {
                    chip = below ? String(localized: "low < \(Self.bound(lo, unit: reading.unit))")
                                 : String(localized: "high > \(Self.bound(hi, unit: reading.unit))")
                }
            }
        } else {
            let lo = format(population.lowerBound), hi = format(population.upperBound)
            if inRange {
                status = .within
                direction = 0
                chip = String(localized: "within \(Self.rangeText(lo, hi, unit: reading.unit))")
            } else {
                status = .outside(severe: false)
                let below = v < population.lowerBound
                direction = below ? -1 : 1
                chip = below ? String(localized: "low < \(Self.bound(lo, unit: reading.unit))")
                             : String(localized: "high > \(Self.bound(hi, unit: reading.unit))")
            }
        }

        let day = reading.day
        return HealthVital(id: reading.key, name: name, tileTitle: tileTitle, shortTitle: shortTitle, symbol: symbol,
                           value: format(v), unit: reading.unit, status: status, chipText: chip, direction: direction,
                           dayKey: day, isCarried: day.map { $0 != todayKey } ?? false,
                           isPersonal: state != nil, route: route)
    }

    /// "13.8 - 14.8", "95% - 100%", "-0.4 to +0.3" (a signed range reads badly with a dash).
    private static func rangeText(_ lo: String, _ hi: String, unit: String) -> String {
        if lo.hasPrefix("-") || lo.hasPrefix("+") || hi.hasPrefix("-") {
            return String(localized: "\(lo) to \(hi)")
        }
        return unit == "%" ? "\(lo)% - \(hi)%" : "\(lo) - \(hi)"
    }

    private static func bound(_ value: String, unit: String) -> String {
        unit == "%" ? value + "%" : value
    }

    // MARK: - Health Monitor

    func healthMonitor(_ r: PulseRequest) async -> HealthMonitorSnapshot? {
        begin(r.seq)
        let vitals = healthVitals(r)
        // The personal ranges need `Baselines.minNightsTrust` nights of HRV; until then the monitor says how
        // many nights are left (the "Wear your strap to sleep N more nights" banner).
        let todayKey = Repository.localDayKey(r.now)
        let hrvState = Baselines.foldHistory(r.days.filter { $0.day < todayKey }.map(\.avgHrv),
                                             dayKeys: r.days.filter { $0.day < todayKey }.map(\.day),
                                             cfg: Baselines.hrvCfg, baselineEpoch: Baselines.hrvBaselineEpoch())
        let needed = Baselines.minNightsTrust
        let calibration = hrvState.trusted ? nil
            : HealthMonitorSnapshot.Calibration(nights: min(hrvState.nValid, needed), needed: needed)
        guard isCurrent(r) else { return nil }
        return HealthMonitorSnapshot(seq: r.seq, vitals: vitals, calibration: calibration)
    }

    // MARK: - Stress

    /// One day's stress for the day `r.day.offset` calendar days before today: the intraday curve for both
    /// the gauge (its latest reading) and the chart, the daily score only as a labelled fallback. Today's
    /// chart covers the last 24 h, so yesterday's evening is included.
    func stressDay(_ r: PulseRequest) async -> PulseStressDay? {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: r.now)
        guard let dayStart = cal.date(byAdding: .day, value: -r.day.offset, to: todayStart),
              let nextStart = cal.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        let isToday = r.day.offset == 0
        let dayKey = Repository.localDayKey(dayStart)
        let result = await stressResult(dayStart: dayStart, isToday: isToday, r: r)

        var timeline = result.timeline
        let window: ClosedRange<Date>
        if isToday {
            let start = r.now.addingTimeInterval(-24 * 3600)
            window = start...r.now
            if let yesterdayStart = cal.date(byAdding: .day, value: -1, to: dayStart) {
                let yesterday = await stressResult(dayStart: yesterdayStart, isToday: false, r: r)
                let startTs = Int(start.timeIntervalSince1970)
                timeline = yesterday.timeline.filter { $0.startTs + 1800 >= startTs } + timeline
            }
        } else {
            window = dayStart...nextStart
        }

        // Points at each window's centre, with a gap wherever the curve skips more than an hour (the night).
        var points: [PulseTimeValue] = []
        var lastTs: Int?
        for p in timeline.sorted(by: { $0.startTs < $1.startTs }) {
            if let lastTs, p.startTs - lastTs > 3600 {
                points.append(PulseTimeValue(date: Date(timeIntervalSince1970: TimeInterval(lastTs + 1800 + 1)),
                                             value: nil))
            }
            points.append(PulseTimeValue(date: Date(timeIntervalSince1970: TimeInterval(p.startTs + 1800)),
                                         value: p.level))
            lastTs = p.startTs
        }

        let latest = timeline.filter { $0.level != nil }.max { $0.startTs < $1.startTs }.map { p in
            PulseStressDay.Reading(level: p.level ?? 0,
                                   at: min(Date(timeIntervalSince1970: TimeInterval(p.startTs + 3600)), r.now))
        }
        let daily = await dailyStress(r, dayKey: dayKey, isToday: isToday)
        return PulseStressDay(dayKey: dayKey, isToday: isToday, points: points, hours: result.hours, window: window,
                              latest: latest, daily: daily, maskedHours: result.activityMaskedHours)
    }

    /// The intraday stress of the local day starting at `dayStart` (today: up to now), read and scored once
    /// per refresh (today's once per five minutes), exactly as the Stress screen scores today: the day's heart
    /// rate, R-R and wrist motion through `DaytimeStress` in the lens the settings pick.
    func stressResult(dayStart: Date, isToday: Bool, r: PulseRequest) async -> DaytimeStress.Result {
        let cal = Calendar.current
        let from = Int(dayStart.timeIntervalSince1970)
        let nextStart = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86_400)
        let to = isToday ? Int(r.now.timeIntervalSince1970) : Int(nextStart.timeIntervalSince1970) - 1
        let key = isToday ? "health.stress.\(from).\(to / 300)" : "health.stress.\(from)"
        let personal = r.prefs.stressPersonalBaseline
        return await cached(key) { () async -> DaytimeStress.Result in
            let hr = await repo.hrSamples(from: from, to: to, limit: 200_000)
            guard hr.count >= DaytimeStress.minHourHRSamples else { return .empty }
            let rr = await repo.rrIntervals(from: from, to: to, limit: 200_000)
            let gravity = await repo.gravitySamplesUnion(from: from, to: to, limit: 200_000)
            let mode = await DaytimeStressMode.selected(repo: repo, startOfToday: dayStart, calendar: cal,
                                                        personalBaseline: personal)
            let tz = TimeZone.current.secondsFromGMT(for: dayStart)
            return DaytimeStress.analyze(hr: hr, rr: rr, gravity: gravity, tzOffsetSeconds: tz, mode: mode,
                                         includeTimeline: true)
        }
    }

    /// The day's daily stress score (0–3): today's through `StressModel` (the newest night with signal),
    /// a past day's stored value, else its own derivation against its trailing baseline.
    func dailyStress(_ r: PulseRequest, dayKey: String, isToday: Bool) async -> Double? {
        let stored = await stressStoredSeries()
        if isToday {
            return await cachedOptional("health.stress.daily.today") { () async -> Double? in
                StressModel(days: r.days, stored: stored)?.score
            }
        }
        let derived = await cached("health.stress.derived") { () async -> [String: DailyStressTrend.Score] in
            DailyStressTrend.scores(r.days.map {
                DailyStressTrend.Day(day: $0.day, restingHR: $0.restingHr.map(Double.init), hrv: $0.avgHrv)
            })
        }
        return dailyScoreFor(dayKey: dayKey, stored: stored, derived: derived)
    }

    /// The typical same weekday over the previous six weeks (worn days only). Today it is cut after the
    /// current hour, the same hours today's own totals count (the hour in progress included, once scored).
    func stressTypical(_ r: PulseRequest, dayStart: Date,
                       isToday: Bool) async -> (totals: StressDayTotals.Totals?, days: Int) {
        let cal = Calendar.current
        var days: [[DaytimeStress.HourPoint]] = []
        for weeks in 1...Self.typicalWeeks {
            guard let start = cal.date(byAdding: .day, value: -7 * weeks, to: dayStart) else { continue }
            let result = await stressResult(dayStart: start, isToday: false, r: r)
            if !result.hours.isEmpty { days.append(result.hours) }
        }
        let cut = isToday ? cal.component(.hour, from: r.now) + 1 : nil
        let typical = StressDayTotals.typical(days, beforeHour: cut)
        let worn = days.filter {
            StressDayTotals.totals($0, beforeHour: cut).scoredMinutes
                >= StressDayTotals.minTypicalHours * StressDayTotals.minutesPerHour
        }.count
        return (typical, worn)
    }

    static let typicalWeeks = 6

    /// The Stress Monitor for the day `r.day.offset` back.
    func stressMonitor(_ r: PulseRequest) async -> StressMonitorSnapshot? {
        begin(r.seq)
        guard let day = await stressDay(r) else { return nil }
        guard isCurrent(r) else { return nil }
        let cal = Calendar.current
        let dayStart = cal.date(byAdding: .day, value: -r.day.offset, to: cal.startOfDay(for: r.now)) ?? r.now
        let typical = await stressTypical(r, dayStart: dayStart, isToday: day.isToday)
        let groups = await nightGroups(r)
        let workouts = await workoutRows()
        guard isCurrent(r) else { return nil }

        var periods: [PulseChartPeriod] = []
        for g in groups {
            for s in g where s.endTs > Int(day.window.lowerBound.timeIntervalSince1970)
                && s.effectiveStartTs < Int(day.window.upperBound.timeIntervalSince1970) {
                periods.append(PulseChartPeriod(id: "sleep-\(s.startTs)",
                                                start: Date(timeIntervalSince1970: TimeInterval(s.effectiveStartTs)),
                                                end: Date(timeIntervalSince1970: TimeInterval(s.endTs)),
                                                kind: .sleep, symbol: "moon.fill"))
            }
        }
        for w in workouts where w.endTs > Int(day.window.lowerBound.timeIntervalSince1970)
            && w.startTs < Int(day.window.upperBound.timeIntervalSince1970) {
            periods.append(PulseChartPeriod(id: "w-\(w.startTs)-\(w.sport)",
                                            start: Date(timeIntervalSince1970: TimeInterval(w.startTs)),
                                            end: Date(timeIntervalSince1970: TimeInterval(w.endTs)),
                                            kind: .activity,
                                            symbol: WorkoutTypeIconography.systemSymbolName(for: w.sport)))
        }

        let longest = StressDayTotals.longestHighRun(day.hours).map {
            StressMonitorSnapshot.LongestRun(start: Date(timeIntervalSince1970: TimeInterval($0.startTs)),
                                             minutes: $0.minutes)
        }
        var explanation: String?
        if day.latest == nil, day.daily != nil {
            explanation = await dailyExplanation(r, dayKey: day.dayKey, isToday: day.isToday)
        }
        let title = day.isToday ? String(localized: "Today") : PulseFormat.navDayTitle(dayKey: day.dayKey)
        return StressMonitorSnapshot(seq: r.seq, day: day, title: title, periods: periods,
                                     totals: StressDayTotals.totals(day.hours), typical: typical.totals,
                                     typicalDays: typical.days, longestHigh: longest,
                                     dailyExplanation: explanation)
    }

    /// The daily score's own sentence (resting HR and HRV against their baselines), for a day with no curve:
    /// the same `StressModel` (stored series included) or derivation `dailyStress` took the score from.
    private func dailyExplanation(_ r: PulseRequest, dayKey: String, isToday: Bool) async -> String? {
        let stored = await stressStoredSeries()
        if isToday {
            return StressModel(days: r.days, stored: stored)?.explanation
        }
        let derived = await cached("health.stress.derived") { () async -> [String: DailyStressTrend.Score] in
            DailyStressTrend.scores(r.days.map {
                DailyStressTrend.Day(day: $0.day, restingHR: $0.restingHr.map(Double.init), hrv: $0.avgHrv)
            })
        }
        let usingStored = stored.contains { $0.day == dayKey }
        guard let score = dailyScoreFor(dayKey: dayKey, stored: stored, derived: derived) else { return nil }
        let deltas = derived[dayKey]
        return StressMath.explanation(band: StressBand(score: score), rhrDelta: deltas?.rhrDelta,
                                      hrvDelta: deltas?.hrvDelta, usingStored: usingStored)
    }

    /// A past day's daily score: its stored value, else its own derivation.
    private func dailyScoreFor(dayKey: String, stored: [(day: String, value: Double)],
                               derived: [String: DailyStressTrend.Score]) -> Double? {
        if let v = stored.last(where: { $0.day == dayKey })?.value { return min(max(v, 0), 3) }
        return derived[dayKey]?.score
    }

    // MARK: - Healthspan

    /// The week a Healthspan build shows: the one keyed `weekKey`, else the newest.
    private func healthspanWeek(_ weeks: [HealthAgeWeek], weekKey: String?) -> HealthAgeWeek? {
        weekKey.flatMap { k in weeks.first { $0.id == k } } ?? weeks.last
    }

    /// The last day a week's figures run to: its Friday, or today while it is still being scored.
    private func healthspanEndKey(_ week: HealthAgeWeek, todayKey: String) -> String {
        min(PulseDisplay.dayKey(week.id, offsetBy: 6) ?? week.id, todayKey)
    }

    /// Healthspan for the week keyed `weekKey` (the newest when nil).
    ///
    /// The orb shows the ZENO Age the weekly pass stored. The rows recompute the week's inputs and print each
    /// factor's years only when they add up to that stored age (`HealthspanBreakdown`); otherwise they show
    /// their values without years and `breakdownNote` says why. The rows outside the model (time in HR
    /// zones, strength time) come in a second pass, `healthspanTracked`.
    func healthspan(_ r: PulseRequest, weekKey: String?, dateOfBirth: Date) async -> HealthspanSnapshot? {
        begin(r.seq)
        let weeks = await healthAgeWeeks(dateOfBirth: dateOfBirth, now: r.now)
        let groups = await nightGroups(r)
        let vo2Series = await cached("health.vo2") { await repo.resolvedSeries(key: "vo2max_est", source: "my-whoop").values }
        let fitnessAge = await cached("health.fitnessAge") { await repo.exploreSeries(key: "fitness_age", source: "my-whoop") }
        let lean = await cached("health.leanMass") { await repo.exploreSeries(key: "lean_mass", source: "apple-health") }
        guard isCurrent(r) else { return nil }

        let totalNights = groups.count
        let todayKey = Repository.localDayKey(r.now)
        let state = healthAgeState(r, weeks: weeks, groups: groups)
        let paceSeries = PaceOfAging.series(weeks.map(\.paceWeek))
            .map { HealthspanSnapshot.PacePoint(id: $0.day, pace: $0.pace) }

        guard case .ready = state, let week = healthspanWeek(weeks, weekKey: weekKey) else {
            let unlock: HealthspanSnapshot.Unlock
            if case .unlocking(let nights, let needed) = state {
                unlock = .init(nights: nights, needed: needed)
            } else {
                unlock = .init(nights: 0, needed: Self.healthUnlockNights)
            }
            return HealthspanSnapshot(seq: r.seq, weeks: weeks, summary: nil, unlock: unlock, paceSeries: paceSeries,
                                      isCurrentWeek: true, daysLeftInWeek: 0, insight: nil, pillars: [],
                                      breakdownNote: nil)
        }

        let summary = ageSummary(for: week, in: weeks)
        let weekEndKey = PulseDisplay.dayKey(week.id, offsetBy: 6) ?? week.id
        let endKey = healthspanEndKey(week, todayKey: todayKey)
        let isCurrentWeek = todayKey >= week.id && todayKey <= weekEndKey
        let daysLeft = isCurrentWeek ? Self.daysBetween(todayKey, weekEndKey) : 0

        // The week's inputs as the weekly pass aggregates them, and their breakdown only when it adds up to
        // the ZENO Age the orb shows.
        let inputs = weekInputs(r, endKey: endKey)
        let engineInputs = VitalityEngine.Inputs(
            chronoAge: week.chronoAge, restingHR: inputs.rhr, sleepHours: inputs.sleepHours,
            sleepConsistency: inputs.regularity, rmssd: inputs.hrv,
            rmssdNorm: VitalityEngine.rmssdNorm(forAge: week.chronoAge), steps: inputs.steps)
        let breakdown = HealthspanBreakdown.years(engineInputs, storedBodyAge: week.zenoAge)
        let note: String? = breakdown != nil ? nil : (isCurrentWeek
            ? String(localized: "Breakdown updates with this week's ZENO Age.")
            : String(localized: "This week's breakdown does not add up to its ZENO Age, so no years are shown."))

        // Steps for the row when the week's ZENO Age had none of its own (a WHOOP 4.0 counts no steps): the
        // app's one steps resolver, shown alongside without an effect.
        var resolvedSteps: [(day: String, value: Double)] = []
        if inputs.steps == nil, let from = PulseDisplay.dayKey(endKey, offsetBy: -181) {
            resolvedSteps = await cached("health.steps.\(endKey)") {
                await repo.resolvedStepDays(from: from, to: endKey).days
                    .filter { $0.day != todayKey }
                    .map { (day: $0.day, value: Double($0.steps)) }
            }
        }
        guard isCurrent(r) else { return nil }
        let context = PillarContext(endKey: endKey, chrono: week.chronoAge, inputs: inputs, breakdown: breakdown,
                                    isCurrentWeek: isCurrentWeek)
        let vo2 = vo2Row(series: vo2Series, fitnessAge: fitnessAge, context: context, nights: totalNights)
        let pillars = healthspanPillars(r, context: context, lean: lean, resolvedSteps: resolvedSteps, vo2: vo2)
        let insight = healthspanInsight(summary: summary, breakdown: breakdown)
        return HealthspanSnapshot(seq: r.seq, weeks: weeks, summary: summary, unlock: nil, paceSeries: paceSeries,
                                  isCurrentWeek: isCurrentWeek, daysLeftInWeek: daysLeft, insight: insight,
                                  pillars: pillars, breakdownNote: note)
    }

    /// The week's VitalityEngine inputs, aggregated exactly as the weekly pass and the classic Vitality card
    /// do: resting HR and HRV medians, sleep and steps means, regularity from the nightly hours.
    private struct WeekInputs {
        var rhr: Double?
        var hrv: Double?
        var sleepHours: Double?
        var regularity: Double?
        var steps: Double?
    }

    /// What every pillar row of one week is read against.
    private struct PillarContext {
        let endKey: String
        let chrono: Double
        let inputs: WeekInputs
        /// The factors' years when they add up to the week's ZENO Age, else nil (withheld).
        let breakdown: [String: Double]?
        let isCurrentWeek: Bool

        var sixFrom: String { PulseDisplay.dayKey(endKey, offsetBy: -181) ?? endKey }
        var thirtyFrom: String { PulseDisplay.dayKey(endKey, offsetBy: -29) ?? endKey }

        /// A factor's effect: its years, withheld when the breakdown does not add up, or outside the model.
        func effect(_ key: String, inModel: Bool) -> RowEffect {
            guard inModel else { return .outsideModel(String(localized: "This week's ZENO Age did not use it, so it is shown here without an effect.")) }
            guard let breakdown else { return .withheld(isCurrentWeek: isCurrentWeek) }
            return breakdown[key].map { .years($0) } ?? .withheld(isCurrentWeek: isCurrentWeek)
        }
    }

    /// What a row says about ZENO Age.
    private enum RowEffect {
        /// The factor's share of this week's ZENO Age, in years.
        case years(Double)
        /// In the model, but the week's breakdown does not add up to its ZENO Age.
        case withheld(isCurrentWeek: Bool)
        /// Not one of ZENO Age's inputs this week; the reason, as a sentence.
        case outsideModel(String)
    }

    private func weekInputs(_ r: PulseRequest, endKey: String) -> WeekInputs {
        guard let startKey = PulseDisplay.dayKey(endKey, offsetBy: -6) else { return WeekInputs() }
        let rows = r.days.filter { $0.day >= startKey && $0.day <= endKey }
        let nights = rows.compactMap(\.totalSleepMin).map { $0 / 60 }.filter { $0 > 0 }
        let rhrs = rows.compactMap(\.restingHr).map(Double.init)
        let hrvs = rows.compactMap(\.avgHrv)
        let steps = rows.compactMap(\.steps).map(Double.init)
        return WeekInputs(rhr: rhrs.isEmpty ? nil : Self.median(rhrs),
                          hrv: hrvs.isEmpty ? nil : Self.median(hrvs),
                          sleepHours: nights.isEmpty ? nil : nights.reduce(0, +) / Double(nights.count),
                          regularity: VitalityEngine.sleepConsistency(nightlyHours: nights),
                          steps: steps.isEmpty ? nil : steps.reduce(0, +) / Double(steps.count))
    }

    private static func median(_ xs: [Double]) -> Double {
        let s = xs.sorted()
        let n = s.count
        return n % 2 == 1 ? s[n / 2] : (s[n / 2 - 1] + s[n / 2]) / 2
    }

    private static func daysBetween(_ a: String, _ b: String) -> Int {
        guard let x = PaceOfAging.dayNumber(a), let y = PaceOfAging.dayNumber(b) else { return 0 }
        return max(0, y - x)
    }

    /// VO₂ MAX as a Fitness row (reviews/29: "55 mL/kg/min" on a 15–70 bar): the latest weekly estimate up
    /// to the week's end, the 6-month and 30-day averages of the weekly estimates, and that week's Fitness
    /// Age in the sentence (§3.23 [Z]). The weekly ZENO Age pass leaves VO₂ max to Fitness Age, so it carries
    /// no years. Before there is an estimate, the row says what it is waiting for.
    private func vo2Row(series: [(day: String, value: Double)], fitnessAge: [(day: String, value: Double)],
                        context: PillarContext, nights: Int) -> HealthspanRow {
        let points = series.filter { $0.day <= context.endKey && $0.value.isFinite && $0.value > 0 }
        let title = String(localized: "VO₂ max")
        let unit = String(localized: "mL/kg/min")
        let route = PulseRoute.trendView(metric: "vo2max_est").forExistingEntryPoint
        guard let latest = points.last else {
            let needed = 14
            let sentence = nights < needed
                ? String(localized: "Log \(needed - nights) more sleeps to unlock VO₂ max.")
                : String(localized: "ZENO estimates VO₂ max each week once your profile has your age and biological sex and the strap has your resting heart rate on most nights of the week.")
            return HealthspanRow(id: "vo2", title: title, valueText: nil, scale: 15...70, lowLabel: "15",
                                 highLabel: "70", tones: [], unit: unit, sixMonth: nil, sixMonthNumber: nil,
                                 thirtyDay: nil, thirtyDayNumber: nil, years: nil,
                                 verdict: String(localized: "Not estimated yet"), sentence: sentence, route: nil)
        }
        func mean(from: String) -> Double? {
            let xs = points.filter { $0.day >= from }.map(\.value)
            return xs.isEmpty ? nil : xs.reduce(0, +) / Double(xs.count)
        }
        let six = mean(from: context.sixFrom)
        let thirty = mean(from: context.thirtyFrom)
        var reason = String(localized: "ZENO Age leaves VO₂ max to your Fitness Age, so it is shown here without an effect.")
        if let age = fitnessAge.last(where: { $0.day <= context.endKey && $0.value.isFinite && $0.value > 0 }) {
            reason += " " + String(localized: "Your Fitness Age for the week of \(PulseFormat.dayLabel(age.day, template: "MMMd")) was \(PulseFormat.oneDecimal(age.value)).")
        }
        let valueText = PulseFormat.withUnit(PulseFormat.whole(latest.value), unit)
        let lead = String(localized: "Your VO₂ max was \(valueText) at your last weekly estimate.")
        return HealthspanRow(id: "vo2", title: title, valueText: valueText, scale: 15...70, lowLabel: "15",
                             highLabel: "70", tones: [], unit: unit,
                             sixMonth: six, sixMonthNumber: six.map(PulseFormat.whole),
                             thirtyDay: thirty, thirtyDayNumber: thirty.map(PulseFormat.whole),
                             years: nil, verdict: String(localized: "Tracked alongside"),
                             sentence: lead + " " + reason, route: route)
    }

    // MARK: Pillars

    private func healthspanPillars(_ r: PulseRequest, context c: PillarContext,
                                   lean: [(day: String, value: Double)],
                                   resolvedSteps: [(day: String, value: Double)],
                                   vo2: HealthspanRow) -> [HealthspanPillar] {
        let sixFrom = c.sixFrom
        let thirtyFrom = c.thirtyFrom
        let endKey = c.endKey
        let chrono = c.chrono
        let inputs = c.inputs
        let rows = r.days.filter { $0.day <= endKey }
        func average(_ f: (DailyMetric) -> Double?, from: String) -> Double? {
            let xs = rows.filter { $0.day >= from }.compactMap(f).filter(\.isFinite)
            return xs.isEmpty ? nil : xs.reduce(0, +) / Double(xs.count)
        }
        /// Regularity averaged over the 7-night windows ending every week back to `from`.
        func regularityAverage(from: String) -> Double? {
            var values: [Double] = []
            var end = endKey
            while end >= from {
                guard let start = PulseDisplay.dayKey(end, offsetBy: -6) else { break }
                let nights = rows.filter { $0.day >= start && $0.day <= end }.compactMap(\.totalSleepMin)
                    .map { $0 / 60 }.filter { $0 > 0 }
                if let c = VitalityEngine.sleepConsistency(nightlyHours: nights) { values.append(c) }
                guard let next = PulseDisplay.dayKey(end, offsetBy: -7) else { break }
                end = next
            }
            return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
        }
        /// Ten tones across `scale`, from the years the model gives each segment's midpoint.
        func tones(_ scale: ClosedRange<Double>, _ inputs: (Double) -> VitalityEngine.Inputs) -> [HealthspanRow.Tone] {
            (0..<10).map { i in
                let x = scale.lowerBound + (Double(i) + 0.5) / 10 * (scale.upperBound - scale.lowerBound)
                let y = VitalityEngine.contributions(inputs(x)).map(VitalityEngine.years(for:)).reduce(0, +)
                return y <= -0.15 ? .helps : (y >= 0.15 ? .hurts : .neutral)
            }
        }
        let norm = VitalityEngine.rmssdNorm(forAge: chrono)

        // Sleep. "Sleep regularity", not WHOOP's SLEEP CONSISTENCY: ZENO Age reads 1 − the variation of the
        // nightly hours, which is not the timing-based Sleep Consistency the Sleep dive shows (ARCHITECTURE §9).
        let hours = row(id: "sleep", title: String(localized: "Hours of sleep"),
                        value: inputs.sleepHours, text: { PulseFormat.hoursMinutes($0 * 60) }, unit: "h",
                        scale: 5...9, low: "5h", high: "9h",
                        tones: tones(5...9) { VitalityEngine.Inputs(chronoAge: chrono, sleepHours: $0) },
                        six: average({ $0.totalSleepMin.map { $0 / 60 } }, from: sixFrom),
                        thirty: average({ $0.totalSleepMin.map { $0 / 60 } }, from: thirtyFrom),
                        effect: c.effect("sleep", inModel: inputs.sleepHours != nil),
                        label: String(localized: "Your nightly sleep"),
                        route: PulseRoute.trendView(metric: "sleep_total_min").forExistingEntryPoint)
        let regularity = row(id: "consistency", title: String(localized: "Sleep regularity"),
                             value: inputs.regularity.map { $0 * 100 }, text: { PulseFormat.whole($0) }, unit: "%",
                             scale: 40...100, low: "40%", high: "100%",
                             tones: tones(40...100) { VitalityEngine.Inputs(chronoAge: chrono, sleepConsistency: $0 / 100) },
                             six: regularityAverage(from: sixFrom).map { $0 * 100 },
                             thirty: regularityAverage(from: thirtyFrom).map { $0 * 100 },
                             effect: c.effect("consistency", inModel: inputs.regularity != nil),
                             label: String(localized: "Your sleep regularity"), route: nil)
        // Strain (the zone and strength rows join from `healthspanTracked`)
        let steps: HealthspanRow?
        if inputs.steps != nil || resolvedSteps.isEmpty {
            steps = row(id: "steps", title: String(localized: "Steps"),
                        value: inputs.steps, text: { PulseFormat.grouped($0) }, unit: "",
                        scale: 2_000...14_000, low: "2k", high: "14k",
                        tones: tones(2_000...14_000) { VitalityEngine.Inputs(chronoAge: chrono, steps: $0) },
                        six: average({ $0.steps.map(Double.init) }, from: sixFrom),
                        thirty: average({ $0.steps.map(Double.init) }, from: thirtyFrom),
                        effect: c.effect("steps", inModel: inputs.steps != nil),
                        label: String(localized: "Your daily steps"), route: PulseRoute.tab(.steps(day: nil)))
        } else {
            func mean(from: String) -> Double? {
                let xs = resolvedSteps.filter { $0.day >= from && $0.day <= endKey }.map(\.value)
                return xs.isEmpty ? nil : xs.reduce(0, +) / Double(xs.count)
            }
            steps = row(id: "steps", title: String(localized: "Steps"),
                        value: PulseDisplay.dayKey(endKey, offsetBy: -6).flatMap { mean(from: $0) },
                        text: { PulseFormat.grouped($0) }, unit: "",
                        scale: 2_000...14_000, low: "2k", high: "14k", tones: [],
                        six: mean(from: sixFrom), thirty: mean(from: thirtyFrom),
                        effect: c.effect("steps", inModel: false),
                        label: String(localized: "Your daily steps"), route: PulseRoute.tab(.steps(day: nil)))
        }
        // Fitness
        let rhr = row(id: "rhr", title: String(localized: "RHR"),
                      value: inputs.rhr, text: { PulseFormat.whole($0) }, unit: "bpm",
                      scale: 40...80, low: "40bpm", high: "80bpm",
                      tones: tones(40...80) { VitalityEngine.Inputs(chronoAge: chrono, restingHR: $0) },
                      six: average({ $0.restingHr.map(Double.init) }, from: sixFrom),
                      thirty: average({ $0.restingHr.map(Double.init) }, from: thirtyFrom),
                      effect: c.effect("rhr", inModel: inputs.rhr != nil),
                      label: String(localized: "Your resting heart rate"),
                      route: PulseRoute.trendView(metric: "rhr").forExistingEntryPoint)
        let hrv = row(id: "hrv", title: String(localized: "HRV"),
                      value: inputs.hrv, text: { PulseFormat.whole($0) }, unit: "ms",
                      scale: 15...105, low: "15ms", high: "105ms",
                      tones: tones(15...105) { VitalityEngine.Inputs(chronoAge: chrono, rmssd: $0, rmssdNorm: norm) },
                      six: average(\.avgHrv, from: sixFrom), thirty: average(\.avgHrv, from: thirtyFrom),
                      effect: c.effect("hrv", inModel: inputs.hrv != nil),
                      label: String(localized: "Your heart rate variability"),
                      route: PulseRoute.trendView(metric: "hrv").forExistingEntryPoint)
        var fitness = [vo2] + [rhr, hrv].compactMap { $0 }
        let leanPoints = lean.filter { $0.day <= endKey && $0.value.isFinite && $0.value > 0 }
        if let latest = leanPoints.last {
            let six = leanPoints.filter { $0.day >= sixFrom }.map(\.value)
            let thirty = leanPoints.filter { $0.day >= thirtyFrom }.map(\.value)
            let lo = floor(((six.min() ?? latest.value) - 3) / 5) * 5
            let hi = ceil(((six.max() ?? latest.value) + 3) / 5) * 5
            if let leanRow = row(id: "lean", title: String(localized: "Lean body mass"),
                                 value: latest.value, text: { PulseFormat.oneDecimal($0) }, unit: "kg",
                                 scale: lo...max(hi, lo + 5), low: "\(Int(lo))kg", high: "\(Int(max(hi, lo + 5)))kg",
                                 tones: [],
                                 six: six.isEmpty ? nil : six.reduce(0, +) / Double(six.count),
                                 thirty: thirty.isEmpty ? nil : thirty.reduce(0, +) / Double(thirty.count),
                                 effect: c.effect("lean", inModel: false),
                                 label: String(localized: "Your lean body mass"), latest: true,
                                 route: PulseRoute.tab(.metricSourced(key: "lean_mass", source: "apple-health"))) {
                fitness.append(leanRow)
            }
        }
        return [
            HealthspanPillar(id: "sleep", title: String(localized: "Sleep"), rows: [regularity, hours].compactMap { $0 }),
            HealthspanPillar(id: "strain", title: String(localized: "Strain"), rows: [steps].compactMap { $0 }),
            HealthspanPillar(id: "fitness", title: String(localized: "Fitness"), rows: fitness),
        ]
    }

    /// One pillar row, or nil when there is nothing to show (no value and no averages). `label` names the
    /// measure as a sentence subject ("Your resting heart rate"); `latest` reads a last reading, not a
    /// week's average.
    private func row(id: String, title: String, value: Double?, text: (Double) -> String, unit: String,
                     scale: ClosedRange<Double>, low: String, high: String, tones: [HealthspanRow.Tone],
                     six: Double?, thirty: Double?, effect: RowEffect, label: String, latest: Bool = false,
                     route: PulseRoute?) -> HealthspanRow? {
        guard value != nil || six != nil || thirty != nil else { return nil }
        let valueText = value.map { PulseFormat.withUnit(text($0), unit) }
        var years: Double?
        let verdict: String
        let sentence: String
        if let valueText {
            let lead = latest ? String(localized: "\(label) was \(valueText) at your last reading.")
                              : String(localized: "\(label) averaged \(valueText) this week.")
            switch effect {
            case .years(let y):
                years = y
                let amount = PulseFormat.oneDecimal(abs(y))
                if y <= -0.05 {
                    verdict = String(localized: "Taking years off")
                    sentence = lead + " " + String(localized: "In ZENO's model that takes \(amount) years off your ZENO Age.")
                } else if y >= 0.05 {
                    verdict = String(localized: "Adding years")
                    sentence = lead + " " + String(localized: "In ZENO's model that adds \(amount) years to your ZENO Age.")
                } else {
                    verdict = String(localized: "Holding steady")
                    sentence = lead + " " + String(localized: "In ZENO's model that leaves your ZENO Age where it is.")
                }
            case .withheld(let isCurrentWeek):
                verdict = String(localized: "In this week's ZENO Age")
                sentence = lead + " " + (isCurrentWeek
                    ? String(localized: "Its share in years shows once this week's ZENO Age is scored again.")
                    : String(localized: "Its share in years is not shown: this week's breakdown does not add up to its ZENO Age."))
            case .outsideModel(let reason):
                verdict = String(localized: "Tracked alongside")
                sentence = lead + " " + reason
            }
        } else {
            verdict = String(localized: "No reading this week")
            sentence = String(localized: "There is no reading this week, so it is left out of this week's ZENO Age.")
        }
        return HealthspanRow(id: id, title: title, valueText: valueText, scale: scale, lowLabel: low, highLabel: high,
                             tones: tones, unit: unit, sixMonth: six, sixMonthNumber: six.map(text),
                             thirtyDay: thirty, thirtyDayNumber: thirty.map(text),
                             years: years, verdict: verdict, sentence: sentence, route: route)
    }

    /// The notched card under the ruler: a title from the pace and its week-on-week change, and a body
    /// with the real numbers (the change, and the factor doing the most when the breakdown adds up).
    private func healthspanInsight(summary: HealthAgeSummary, breakdown: [String: Double]?) -> HealthspanSnapshot.Insight {
        let title: String
        var parts: [String] = []
        if let pace = summary.pace {
            let change = summary.paceChange
            switch (pace <= 1, change) {
            case (true, .faster?): title = String(localized: "Maintain Your Gains")
            case (true, _): title = String(localized: "Steady And Healthy")
            case (false, .slower?): title = String(localized: "On Your Way There")
            case (false, _): title = String(localized: "Small Steps, Big Impact")
            }
            let now = PulseFormat.oneDecimal(pace)
            if let previous = summary.previousPace, let change {
                let before = PulseFormat.oneDecimal(previous)
                switch change {
                case .slower: parts.append(String(localized: "Your Pace of Aging slowed from \(before)x to \(now)x this week."))
                case .faster: parts.append(String(localized: "Your Pace of Aging rose from \(before)x to \(now)x this week."))
                case .same: parts.append(String(localized: "Your Pace of Aging held at \(now)x this week."))
                }
            } else {
                parts.append(String(localized: "Your Pace of Aging is \(now)x."))
            }
        } else {
            title = String(localized: "Settling In")
            parts.append(String(localized: "Your Pace of Aging appears once ZENO has four weeks of ZENO Age to compare."))
        }
        let ranked = (breakdown ?? [:]).sorted { abs($0.value) > abs($1.value) || (abs($0.value) == abs($1.value) && $0.key < $1.key) }
        if let top = ranked.first, abs(top.value) >= 0.05 {
            let amount = PulseFormat.oneDecimal(abs(top.value))
            let factor = Self.factorName(top.key)
            parts.append(top.value < 0
                ? String(localized: "\(factor) is helping most, taking \(amount) years off.")
                : String(localized: "\(factor) is adding the most, \(amount) years."))
        }
        return HealthspanSnapshot.Insight(title: title, body: parts.joined(separator: " "))
    }

    /// The factor names the Healthspan rows use.
    static func factorName(_ key: String) -> String {
        switch key {
        case "rhr": return String(localized: "Resting heart rate")
        case "hrv": return String(localized: "Heart rate variability")
        case "sleep": return String(localized: "Hours of sleep")
        case "consistency": return String(localized: "Sleep regularity")
        case "steps": return String(localized: "Daily steps")
        case "vo2max": return String(localized: "Cardio fitness")
        default: return key
        }
    }

    // MARK: Rows outside the model

    /// TIME IN HR ZONES 1-3 (WEEKLY), TIME IN HR ZONES 4-5 (WEEKLY) and STRENGTH ACTIVITY TIME for the week
    /// keyed `weekKey` (the newest when nil), from the week's workouts: a workout's imported zone split when
    /// it has one, else its own heart rate in the profile's zones (the Strain dive's zones); strength time is
    /// the length of the strength sessions. ZENO Age does not use them, so they carry no years. The 6-month
    /// and 30-day markers are the weekly rate over the days the strap was worn in each window.
    func healthspanTracked(_ r: PulseRequest, weekKey: String?, dateOfBirth: Date) async -> HealthspanTracked? {
        begin(r.seq)
        let weeks = await healthAgeWeeks(dateOfBirth: dateOfBirth, now: r.now)
        guard let week = healthspanWeek(weeks, weekKey: weekKey) else {
            return isCurrent(r) ? HealthspanTracked(weekKey: weekKey ?? "", rows: []) : nil
        }
        let todayKey = Repository.localDayKey(r.now)
        let endKey = healthspanEndKey(week, todayKey: todayKey)
        let sixFrom = PulseDisplay.dayKey(endKey, offsetBy: -181) ?? endKey
        let thirtyFrom = PulseDisplay.dayKey(endKey, offsetBy: -29) ?? endKey
        let isCurrentWeek = todayKey <= (PulseDisplay.dayKey(week.id, offsetBy: 6) ?? week.id)
        let workouts = await workoutRows()
        guard isCurrent(r) else { return nil }

        // Minutes per local day: zones 1-3, zones 4-5, strength.
        var z13: [String: Double] = [:]
        var z45: [String: Double] = [:]
        var strength: [String: Double] = [:]
        for w in workouts where w.endTs > w.startTs {
            let day = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(w.startTs)))
            guard day >= sixFrom && day <= endKey else { continue }
            let minutes = (w.durationS ?? Double(w.endTs - w.startTs)) / 60
            if Self.isStrength(w.sport) { strength[day, default: 0] += minutes }
            let zones: [Double]?
            if let pct = WorkoutZones.percents(w.zonesJSON) {
                zones = pct.map { minutes * $0 / 100 }
            } else {
                zones = await cachedOptional("health.workoutZones.\(w.startTs).\(w.source)") { () async -> [Double]? in
                    await repo.workoutZoneMinutes(from: w.startTs, to: w.endTs, zoneSet: r.profile.zoneSet,
                                                  source: w.source)
                }
            }
            guard isCurrent(r) else { return nil }
            if let zones, zones.count >= 5 {
                z13[day, default: 0] += zones[0] + zones[1] + zones[2]
                z45[day, default: 0] += zones[3] + zones[4]
            }
        }

        // Worn days anchor the rates, so a week off the wrist is skipped rather than read as zero.
        let worn = Set(r.days.map(\.day).filter { $0 >= sixFrom && $0 <= endKey })
        func weekTotal(_ byDay: [String: Double]) -> Double? {
            let days = worn.filter { $0 >= week.id && $0 <= endKey }
            guard !days.isEmpty else { return nil }
            return days.reduce(0) { $0 + (byDay[$1] ?? 0) }
        }
        func weeklyRate(_ byDay: [String: Double], from: String) -> Double? {
            let days = worn.filter { $0 >= from }
            guard !days.isEmpty else { return nil }
            return days.reduce(0) { $0 + (byDay[$1] ?? 0) } / Double(days.count) * 7
        }
        func trackedRow(id: String, title: String, byDay: [String: Double], floorHours: Double,
                        lead: (String) -> String) -> HealthspanRow? {
            let value = weekTotal(byDay)
            let six = weeklyRate(byDay, from: sixFrom)
            let thirty = weeklyRate(byDay, from: thirtyFrom)
            guard value != nil || six != nil || thirty != nil else { return nil }
            let top = max(floorHours, ceil(([value, six, thirty].compactMap { $0 }.max() ?? 0) / 60))
            let text = { (m: Double) in PulseFormat.hoursMinutes(m) }
            let valueText = value.map { PulseFormat.withUnit(text($0), "h") }
            let sentence = valueText.map { lead($0) + " " + String(localized: "ZENO Age does not use it, so it is shown here without an effect.") }
                ?? String(localized: "There is no reading this week.")
            return HealthspanRow(id: id, title: title, valueText: valueText, scale: 0...(top * 60), lowLabel: "0h",
                                 highLabel: "\(Int(top))h", tones: [], unit: "h",
                                 sixMonth: six, sixMonthNumber: six.map(text),
                                 thirtyDay: thirty, thirtyDayNumber: thirty.map(text), years: nil,
                                 verdict: valueText == nil ? String(localized: "No reading this week")
                                                           : String(localized: "Tracked alongside"),
                                 sentence: sentence, route: nil)
        }
        let soFar = isCurrentWeek
        let rows = [
            trackedRow(id: "zones13", title: String(localized: "Time in HR zones 1-3 (weekly)"), byDay: z13,
                       floorHours: 5) { v in
                soFar ? String(localized: "Your workouts have spent \(v) in heart rate zones 1 to 3 so far this week.")
                      : String(localized: "Your workouts spent \(v) in heart rate zones 1 to 3 this week.")
            },
            trackedRow(id: "zones45", title: String(localized: "Time in HR zones 4-5 (weekly)"), byDay: z45,
                       floorHours: 2) { v in
                soFar ? String(localized: "Your workouts have spent \(v) in heart rate zones 4 and 5 so far this week.")
                      : String(localized: "Your workouts spent \(v) in heart rate zones 4 and 5 this week.")
            },
            trackedRow(id: "strength", title: String(localized: "Strength activity time"), byDay: strength,
                       floorHours: 3) { v in
                soFar ? String(localized: "You have logged \(v) of strength training so far this week.")
                      : String(localized: "You logged \(v) of strength training this week.")
            },
        ].compactMap { $0 }
        return HealthspanTracked(weekKey: week.id, rows: rows)
    }

    /// A strength session: Strength Trainer and Lift Log sessions, weightlifting, imported strength work.
    static func isStrength(_ sport: String) -> Bool {
        let s = sport.lowercased()
        return s.contains("strength") || s.contains("weight") || s.contains("lift")
    }
}
#endif
