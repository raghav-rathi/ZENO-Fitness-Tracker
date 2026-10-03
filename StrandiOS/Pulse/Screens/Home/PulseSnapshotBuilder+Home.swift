#if os(iOS)
import Foundation
import SwiftUI
import StrandAnalytics
import WhoopStore

// MARK: - Home's own builds (group "home")

extension PulseSnapshotBuilder {

    /// Home's own facts for the request's day: the dashboard rows in `items`, the coaching rules' inputs,
    /// the Daily Outlook's facts, the Health Monitor tile's grades, the Get Started flags and the day's
    /// stress. `home` is the HomeSnapshot for the same day; every figure the two share is read from it (the
    /// dials, the stats, tonight's plan), never re-derived.
    func homeExtras(_ r: PulseRequest, home: HomeSnapshot, items: [PulseDashboardItem]) async -> HomeExtrasSnapshot? {
        begin(r.seq)
        guard home.day == r.day else { return nil }
        let rest = await restSeries()
        let debt = await homeSeries("sleep_debt_min")
        let rows = await workoutRows()
        guard isCurrent(r) else { return nil }

        // Zone minutes per day, resolved once for the HR ZONES rows and the outlook: the four weeks behind
        // a weekly row's baseline when one is on the dashboard, else today's week for the outlook.
        let zoneItems: Set<PulseDashboardItem> = [.hrZones13, .hrZones45, .hrZonesAll]
        let zoneDaysBack = !zoneItems.isDisjoint(with: items) ? Self.zoneHistoryDays : (r.day.isToday ? 6 : nil)
        var zones: [String: ZoneDay] = [:]
        if let zoneDaysBack {
            zones = await zoneDays(r, rows: rows, daysBack: zoneDaysBack)
        }
        guard isCurrent(r) else { return nil }

        var dashboard: [PulseDashboardItem: PulseDashboardValue] = [:]
        for item in Set(items) {
            dashboard[item] = await dashboardValue(item, r: r, home: home, rest: rest, debt: debt, rows: rows,
                                                   zones: zones)
            guard isCurrent(r) else { return nil }
        }

        let coaching = r.day.isToday ? await coachingInputs(r, home: home, rest: rest, debt: debt) : nil
        let outlook = r.day.isToday ? await outlookFacts(r, home: home, zones: zones) : nil
        let monitor = r.day.isToday ? await monitorGrades(r) : nil
        let start = r.day.isToday ? await getStartedFacts(r, home: home, rows: rows) : .pastDay
        // Today's STRESS MONITOR tile, and the dashboard's card on any day it is on.
        let stress = r.day.isToday || items.contains(.stressMonitor) ? await stressSummary(r) : nil
        guard isCurrent(r) else { return nil }
        return HomeExtrasSnapshot(seq: r.seq, day: r.day, dashboard: dashboard, coaching: coaching,
                                  outlook: outlook, monitor: monitor, start: start, stress: stress)
    }

    /// Logged period starts (oldest first) for the Menstrual card's dot strip. Not cached: logging a
    /// period bumps `Repository.cycleTrackingSeq`, not `refreshSeq`, and the card re-reads on that.
    func homePeriodStarts() async -> [String] {
        await repo.periodStarts()
    }

    // MARK: Series

    /// A strap-source Explore series (imported-wins per day, then NOOP's computed value, then the daily
    /// column), read once per refresh.
    private func homeSeries(_ key: String) async -> [(day: String, value: Double)] {
        await cached("home.series.\(key)") { await repo.exploreSeries(key: key, source: "my-whoop") }
    }

    // MARK: Dashboard

    private func dashboardValue(_ item: PulseDashboardItem, r: PulseRequest, home: HomeSnapshot,
                                rest: [(day: String, value: Double)],
                                debt: [(day: String, value: Double)],
                                rows: [WorkoutRow], zones: [String: ZoneDay]) async -> PulseDashboardValue {
        let key = r.day.key
        let polarity = item.polarity
        switch item {
        // The vitals HomeSnapshot already resolved (one resolver per fact).
        case .hrv: return stat("hrv", home: home, item: item)
        case .rhr: return stat("rhr", home: home, item: item)
        case .respiratoryRate: return stat("resp", home: home, item: item)
        case .skinTemperature: return stat("skin", home: home, item: item)
        case .bloodOxygen: return stat("spo2", home: home, item: item)

        // Steps and calories: the day's total against the 30 days before, today's running total included,
        // as WHOOP prints it ("STEPS 2 ▼ 9,706" at 06:59). The figure and its history come from one
        // resolution, so the arrow always describes the number beside it.
        case .steps:
            let steps = await stepsResolution(r)
            let route = home.stats.first { $0.id == "steps" }.map { PulseRoute.tab($0.route) } ?? item.classicRoute
            var value = compared(steps.value, on: key, caption: nil, history: steps.history, dayKey: key,
                                 text: PulseFormat.grouped, unit: nil, baselineText: PulseFormat.grouped,
                                 polarity: polarity, fallback: route, flatPercent: 5)
            value.isRunningTotal = r.day.isToday && value.value != nil
            return value
        case .calories:
            let calories = await caloriesResolution(r)
            let route = home.stats.first { $0.id == "kcal" }.map { PulseRoute.tab($0.route) } ?? item.classicRoute
            var value = compared(calories.value, on: key, caption: nil, history: calories.history, dayKey: key,
                                 text: PulseFormat.grouped, unit: nil, baselineText: PulseFormat.grouped,
                                 polarity: polarity, fallback: route, flatPercent: 5)
            value.isRunningTotal = r.day.isToday && value.value != nil
            return value

        // The dials' own values.
        case .recovery:
            let (_, source) = chargeDisplay(r, row: displayRow(r))
            let history = r.days.compactMap { m in m.recovery.map { (day: m.day, value: $0) } }
            return compared(home.recovery.value, on: source?.day, caption: home.recovery.caption, history: history,
                            dayKey: key, text: Self.percentNumber, unit: "%", baselineText: Self.percent,
                            polarity: polarity, fallback: item.classicRoute)
        case .sleepPerformance:
            let valueDay: String?
            switch home.sleep.state {
            case .scored: valueDay = key
            // The carried night is the newest one on or before the day shown, never a later one.
            case .carried: valueDay = rest.last { $0.day <= key }?.day
            default: valueDay = nil
            }
            return compared(home.sleep.value, on: valueDay, caption: home.sleep.caption, history: rest,
                            dayKey: key, text: Self.percentNumber, unit: "%", baselineText: Self.percent,
                            polarity: polarity, fallback: item.classicRoute)
        case .dayStrain:
            let history = r.days.compactMap { m in
                m.strain.map { (day: m.day, value: UnitFormatter.effortValue($0, scale: .whoop)) }
            }
            var value = compared(home.strain.value, on: key, caption: nil, history: history, dayKey: key,
                                 text: PulseFormat.oneDecimal, unit: nil, baselineText: PulseFormat.oneDecimal,
                                 polarity: polarity, fallback: item.classicRoute)
            value.isRunningTotal = r.day.isToday && value.value != nil
            return value

        // Sleep figures, per night by wake day.
        case .sleepDebt:
            let point = latest(debt, onOrBefore: key, carryDays: r.day.isToday ? 7 : 0)
            var value = compared(point?.value, on: point?.day, caption: nil, history: debt, dayKey: key,
                                 text: PulseFormat.hoursMinutes, unit: nil, baselineText: PulseFormat.hoursMinutes,
                                 polarity: polarity, fallback: item.classicRoute)
            value.carriedNight = point.flatMap { $0.day == key ? nil : $0.day }
            return value
        case .sleepNeeded:
            // What the day's evening called for: tonight's need (the Sleep Planner's figure) today, the
            // stored need of the night that followed a past day. Compared with the nights before that night.
            let need = await homeSeries("sleep_need_min")
            guard let nextNight = PulseDisplay.dayKey(key, offsetBy: 1) else { return .empty(item.classicRoute) }
            let value = r.day.isToday ? home.tonight?.needMin : need.last { $0.day == nextNight }?.value
            return compared(value, on: nextNight, caption: nil, history: need, dayKey: key,
                            text: PulseFormat.hoursMinutes, unit: nil, baselineText: PulseFormat.hoursMinutes,
                            polarity: polarity, fallback: item.classicRoute, compareDay: nextNight)
        case .sleepConsistency:
            let series = await homeSeries("sleep_consistency")
            let point = latest(series, onOrBefore: key, carryDays: r.day.isToday ? 7 : 0)
            var value = compared(point?.value, on: point?.day, caption: nil, history: series, dayKey: key,
                                 text: Self.percentNumber, unit: "%", baselineText: Self.percent,
                                 polarity: polarity, fallback: item.classicRoute)
            value.carriedNight = point.flatMap { $0.day == key ? nil : $0.day }
            return value
        case .hoursOfSleep:
            // The figure the night's activity chip prints; its history is the stored nightly total.
            let history = r.days.compactMap { m in m.totalSleepMin.map { (day: m.day, value: $0) } }
            return compared(home.lastNight?.asleepMin, on: key, caption: nil, history: history, dayKey: key,
                            text: PulseFormat.hoursMinutes, unit: nil, baselineText: PulseFormat.hoursMinutes,
                            polarity: polarity, fallback: item.classicRoute)
        case .restorativeSleep:
            // Deep + REM over asleep for the merged main night the Sleep dive draws.
            let groups = await nightGroups(r)
            let habitual = await habitualMidsleep()
            let night = group(endingOn: key, in: groups).flatMap {
                SleepModel.mergeDay($0, habitualMidsleepSec: habitual, motionByStart: [:])
            }
            let value = night.flatMap { n in n.stages.asleep > 0 ? (n.stages.deep + n.stages.rem) / n.stages.asleep * 100 : nil }
            let history = r.days.compactMap { m -> (day: String, value: Double)? in
                guard let total = m.totalSleepMin, total > 0, let deep = m.deepMin, let rem = m.remMin else { return nil }
                return (m.day, (deep + rem) / total * 100)
            }
            return compared(value, on: key, caption: nil, history: history, dayKey: key, text: Self.percentNumber,
                            unit: "%", baselineText: Self.percent, polarity: polarity, fallback: item.classicRoute)

        // Body figures (Apple Health and the strap's estimates): the latest within 30 days, said so. WHOOP
        // prints weight bare ("88.5 ▲ 88.3"); VoiceOver still hears the unit.
        case .weight, .leanBodyMass:
            let series: [(day: String, value: Double)]
            if item == .weight {
                series = await appleRows().compactMap { a in a.weightKg.map { (day: a.day, value: $0) } }
                    .sorted { $0.day < $1.day }
            } else {
                series = await cached("home.series.lean_mass") { await repo.series(key: "lean_mass", source: "apple-health") }
            }
            let imperial = Self.unitSystem == .imperial
            let shown = series.map { (day: $0.day, value: imperial ? UnitFormatter.kgToPounds($0.value) : $0.value) }
            let point = latest(shown, onOrBefore: key, carryDays: 30)
            var value = compared(point?.value, on: point?.day, caption: carriedCaption(point?.day, key), history: shown,
                                 dayKey: key, text: PulseFormat.oneDecimal, unit: nil,
                                 baselineText: PulseFormat.oneDecimal, polarity: polarity, fallback: item.classicRoute,
                                 flatPercent: 0.5)
            value.spokenUnit = UnitFormatter.massUnit(Self.unitSystem)
            return value
        case .vo2Max:
            let series = await cached("home.series.vo2max_est") {
                await repo.resolvedSeries(key: "vo2max_est", source: "my-whoop").values
            }
            let point = latest(series, onOrBefore: key, carryDays: 30)
            return compared(point?.value, on: point?.day, caption: carriedCaption(point?.day, key), history: series,
                            dayKey: key, text: PulseFormat.whole, unit: nil, baselineText: PulseFormat.whole,
                            polarity: polarity, fallback: item.classicRoute, flatPercent: 1)
        case .averageHeartRate:
            let series = await homeSeries("avg_hr")
            let point = latest(series, onOrBefore: key, carryDays: 0)
            return compared(point?.value, on: point?.day, caption: nil, history: series, dayKey: key,
                            text: PulseFormat.whole, unit: nil, baselineText: PulseFormat.whole,
                            polarity: polarity, fallback: item.classicRoute)

        // Weekly zone totals from the activities' zone minutes (`zoneDays`), the outlook's own figures.
        case .hrZones13:
            return weeklyZones(zones, range: 0..<3, r: r, polarity: polarity, fallback: item.classicRoute)
        case .hrZones45:
            return weeklyZones(zones, range: 3..<5, r: r, polarity: polarity, fallback: item.classicRoute)
        case .hrZonesAll:
            return weeklyZones(zones, range: 0..<5, r: r, polarity: polarity, fallback: item.classicRoute)

        case .strengthActivityTime:
            let series = strengthSeries(r, rows: rows)
            return compared(series.last { $0.day == key }?.value, on: key, caption: nil, history: series,
                            dayKey: key, text: PulseFormat.hoursMinutes, unit: nil,
                            baselineText: PulseFormat.hoursMinutes, polarity: polarity, fallback: item.classicRoute)

        case .stressMonitor, .strainRecovery:
            return .empty(item.classicRoute)
        }
    }

    /// A row from one of HomeSnapshot's stats. WHOOP prints counts and heart rates bare, so only "%" and
    /// a temperature keep their unit.
    private func stat(_ id: String, home: HomeSnapshot, item: PulseDashboardItem) -> PulseDashboardValue {
        guard let s = home.stats.first(where: { $0.id == id }) else { return .empty(item.classicRoute) }
        guard s.value != "–" else { return .empty(.tab(s.route)) }
        let unit: String? = s.unit == "%" || s.unit.contains("°") ? s.unit : nil
        let trend = s.baselineDelta.map { PulseTrend(delta: $0, polarity: item.polarity) }
            ?? s.comparison.map { c in PulseTrend(direction: Self.direction(c.direction), polarity: item.polarity) }
        // A percentage's baseline keeps its "%", as the dashboard's own percent rows print it ("42%").
        let baseline = s.baseline.map { s.unit == "%" ? $0 + "%" : $0 }
        return PulseDashboardValue(value: s.value, unit: unit, trend: trend, baseline: baseline,
                                   caption: s.caption, fallback: .tab(s.route))
    }

    private static func direction(_ d: PulseDisplay.Direction) -> PulseTrend.Direction {
        switch d {
        case .up: return .up
        case .down: return .down
        case .flat: return .flat
        }
    }

    /// `value` (from `valueDay`) against the mean of the 30 days before `compareDay` (the value's own day
    /// by default), formatted. Any difference that PRINTS is coloured good / bad; equal figures draw the
    /// grey dot.
    private func compared(_ value: Double?, on valueDay: String?, caption: String?,
                          history: [(day: String, value: Double)], dayKey: String, text: (Double) -> String,
                          unit: String?, baselineText: (Double) -> String, polarity: PulseMetricPolarity,
                          fallback: PulseRoute, flatPercent: Double = 2,
                          compareDay: String? = nil) -> PulseDashboardValue {
        guard let value, value.isFinite, let valueDay else { return .empty(fallback) }
        let c = PulseDisplay.compare(value: value, history: history, dayKey: compareDay ?? valueDay,
                                     flatPercent: flatPercent)
        let trend = c.map { PulseTrend(delta: text(value) == text($0.reference) ? 0 : value - $0.reference,
                                       polarity: polarity) }
        return PulseDashboardValue(value: text(value), unit: unit, trend: trend,
                                   baseline: c.map { baselineText($0.reference) }, caption: caption,
                                   fallback: fallback)
    }

    /// The point on `dayKey`, else (when `carryDays` > 0) the latest within that many days before it.
    private func latest(_ series: [(day: String, value: Double)], onOrBefore dayKey: String,
                        carryDays: Int) -> (day: String, value: Double)? {
        if let own = series.last(where: { $0.day == dayKey }) { return own }
        guard carryDays > 0, let cutoff = PulseDisplay.dayKey(dayKey, offsetBy: -carryDays) else { return nil }
        return series.last { $0.day < dayKey && $0.day >= cutoff }
    }

    /// "From 28 Sep" for a body figure carried from an earlier day.
    private func carriedCaption(_ valueDay: String?, _ dayKey: String) -> String? {
        guard let valueDay, valueDay != dayKey else { return nil }
        return String(localized: "From \(PulseFormat.dayLabel(valueDay))")
    }

    private static func percentNumber(_ v: Double) -> String { "\(PulseDisplay.displayedPercent(v))" }
    private static func percent(_ v: Double) -> String { "\(PulseDisplay.displayedPercent(v))%" }

    /// The wearer's unit system (Settings), read the way every screen resolves it.
    private static var unitSystem: UnitSystem {
        UnitSystem(rawValue: UserDefaults.standard.string(forKey: UnitPrefs.systemKey) ?? "") ?? .metric
    }

    // MARK: Zones and strength time

    /// One local day's minutes in heart-rate zones 1-5, from that day's activities.
    struct ZoneDay: Equatable {
        var minutes = [Double](repeating: 0, count: 5)
        /// The activities the minutes came from.
        var activities = 0
        /// The day's activities with neither a zone split nor heart rate to bin: their minutes are unknown.
        var unresolved = 0
    }

    /// The days before the shown one a weekly row reads: the rest of its week plus the four weeks behind
    /// its baseline.
    private static let zoneHistoryDays = 34

    /// Minutes in zones 1-5 per local day (an activity counts on the day it started), over the `daysBack`
    /// days before the request's day and the day itself. ONE resolver for the HR ZONES rows and the Daily
    /// Outlook, so the two can never print different weekly totals: an export's own zone split where a row
    /// carries one, else the strap's heart rate binned into the wearer's zones (the Workout detail's
    /// reader). An activity with neither adds no minutes and is counted as unresolved.
    private func zoneDays(_ r: PulseRequest, rows: [WorkoutRow], daysBack: Int) async -> [String: ZoneDay] {
        guard let first = PulseDisplay.dayKey(r.day.key, offsetBy: -daysBack) else { return [:] }
        // The bounds the heart rate is binned by: an edit to HR max or the zones re-bins within the refresh.
        let bounds = r.profile.zoneSet.zones.map { "\($0.lower)-\($0.upper)" }.joined(separator: ",")
        var out: [String: ZoneDay] = [:]
        for w in rows {
            let day = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(w.startTs)))
            guard day >= first, day <= r.day.key else { continue }
            var minutes: [Double]?
            if let pct = WorkoutZones.percents(w.zonesJSON) {
                let total = (w.durationS ?? Double(w.endTs - w.startTs)) / 60
                minutes = (0..<5).map { total * pct[$0] / 100 }
            } else if let binned = await cached("home.zones.\(w.startTs)|\(w.endTs)|\(w.source)|\(bounds)", load: {
                await repo.workoutZoneMinutes(from: w.startTs, to: w.endTs, zoneSet: r.profile.zoneSet, source: w.source)
            }) {
                // `timeInZone` reports zones 1-5 in order.
                minutes = (0..<5).map { $0 < binned.count ? binned[$0] : 0 }
            }
            var entry = out[day] ?? ZoneDay()
            if let minutes {
                for i in 0..<5 { entry.minutes[i] += minutes[i] }
                entry.activities += 1
            } else {
                entry.unresolved += 1
            }
            out[day] = entry
        }
        return out
    }

    /// A WEEKLY zone total (zones `range`): the 7 days ending on the day, against the mean week of the 28
    /// days before. A week the strap saw nothing of, or whose activities none had heart rate for, reads "no
    /// data", not 0:00; when only some had it, the row says how many its total covers. The baseline needs
    /// half of the four weeks before it recorded.
    private func weeklyZones(_ zones: [String: ZoneDay], range: Range<Int>, r: PulseRequest,
                             polarity: PulseMetricPolarity, fallback: PulseRoute) -> PulseDashboardValue {
        let dayKey = r.day.key
        guard let weekStart = PulseDisplay.dayKey(dayKey, offsetBy: -6),
              let baseStart = PulseDisplay.dayKey(weekStart, offsetBy: -28),
              let afterDay = PulseDisplay.dayKey(dayKey, offsetBy: 1) else { return .empty(fallback) }
        let recorded = Set(r.days.map(\.day)).union(zones.keys)
        guard r.day.isToday || recorded.contains(where: { $0 >= weekStart && $0 <= dayKey }) else {
            return .empty(fallback)
        }
        func total(from: String, until: String) -> Double {
            zones.filter { $0.key >= from && $0.key < until }.values
                .reduce(0) { sum, day in sum + range.reduce(0) { $0 + day.minutes[$1] } }
        }
        let days = zones.filter { $0.key >= weekStart && $0.key < afterDay }.values
        let resolved = days.reduce(0) { $0 + $1.activities }
        let unresolved = days.reduce(0) { $0 + $1.unresolved }
        guard resolved > 0 || unresolved == 0 else { return .empty(fallback) }
        let week = total(from: weekStart, until: afterDay)
        let text = PulseFormat.hoursMinutes
        let caption = unresolved > 0
            ? String(localized: "From \(resolved) of \(resolved + unresolved) activities") : nil
        var value = PulseDashboardValue(value: text(week), unit: nil, trend: nil, baseline: nil, caption: caption,
                                        fallback: fallback)
        value.baselineKind = .fourWeeks
        guard recorded.filter({ $0 >= baseStart && $0 < weekStart }).count >= 14 else { return value }
        let reference = total(from: baseStart, until: weekStart) / 4
        value.trend = PulseTrend(delta: text(week) == text(reference) ? 0 : week - reference, polarity: polarity)
        value.baseline = text(reference)
        return value
    }

    /// Minutes of strength activities per local day (an activity counts on the day it started), with every
    /// other day the strap recorded at 0:00, so the 30-day mean is a typical day's, the way WHOOP's STRENGTH
    /// ACTIVITY TIME is compared ("0:00 ▼ (0:52)").
    private func strengthSeries(_ r: PulseRequest, rows: [WorkoutRow]) -> [(day: String, value: Double)] {
        var byDay: [String: Double] = [:]
        for day in r.days.map(\.day) { byDay[day] = 0 }
        if r.day.isToday { byDay[r.day.key] = byDay[r.day.key] ?? 0 }
        for w in rows where PulseHomeActivity.isStrengthActivity(w.sport) {
            let day = Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval(w.startTs)))
            byDay[day, default: 0] += (w.durationS ?? Double(w.endTs - w.startTs)) / 60
        }
        return byDay.sorted { $0.key < $1.key }.map { (day: $0.key, value: $0.value) }
    }

    // MARK: Health Monitor

    /// Today's Health Monitor tile (§3.1 item 6), read from the vitals the Health Monitor itself draws
    /// (`healthVitals`: the same readings with the HRV over-count flags, the same bands, and "very" beyond 3σ
    /// of a trusted personal baseline), so the tile names exactly the vitals the screen it opens shows out of
    /// range, in the same direction, and calls one far out only where the screen says "very high" or "very
    /// low".
    private func monitorGrades(_ r: PulseRequest) async -> PulseMonitorGrades {
        let vitals = await healthVitals(r)
        let judged = vitals.filter { $0.status != .noData }
        let out = judged.compactMap { vital -> PulseMonitorGrades.Flag? in
            guard case .outside(let severe) = vital.status else { return nil }
            return .init(name: vital.name, strong: severe,
                         high: vital.direction == 0 ? nil : vital.direction > 0)
        }
        return PulseMonitorGrades(judged: judged.count, out: out)
    }

    // MARK: Coaching

    /// The coaching rules' inputs the store answers (§3.14 [Z]); the view adds the illness heads-up and
    /// the release notes, which live in app state, and moves the alarm check to the current minute.
    private func coachingInputs(_ r: PulseRequest, home: HomeSnapshot, rest: [(day: String, value: Double)],
                                debt: [(day: String, value: Double)]) async -> HomeCoachingRules.Inputs {
        let key = r.day.key
        let prior = r.days.filter { $0.day < key }
        let history = prior.compactMap { m in m.recovery.map { HomeCoachingRules.DayValue(day: m.day, value: $0) } }
        var ownRecovery: Double?
        var calibration: HomeCoachingRules.Calibration?
        switch home.recovery.state {
        case .scored: ownRecovery = home.recovery.value
        case .calibrating(let nights, let of): calibration = HomeCoachingRules.Calibration(nights: nights, of: of)
        default: break
        }
        // HRV against the recovery engine's baseline as it stood before last night (same series, config
        // and recalibration epoch the engine folds).
        let hrvBaseline = Baselines.foldHistory(prior.map(\.avgHrv), dayKeys: prior.map(\.day), cfg: Baselines.hrvCfg,
                                                baselineEpoch: Baselines.hrvBaselineEpoch())
        let monthAgo = PulseDisplay.dayKey(key, offsetBy: -30) ?? key
        let performance = rest.filter { $0.day >= monthAgo && $0.day <= key }
            .map { HomeCoachingRules.DayValue(day: $0.day, value: $0.value) }
        let yesterday = PulseDisplay.dayKey(key, offsetBy: -1) ?? key
        // Monday's look back: a week with at least three scored days behind it.
        let weekAgo = PulseDisplay.dayKey(key, offsetBy: -7) ?? key
        let lastWeekScored = history.filter { $0.day >= weekAgo }.count
        var isMonday = Calendar.current.component(.weekday, from: r.now) == 2
        #if DEBUG
        // `--pulse-week-review`: any day is Monday for the week-in-review card, for a capture.
        if CommandLine.arguments.contains("--pulse-week-review") { isMonday = true }
        #endif
        // A target only from the day's own Recovery, exactly as the dial draws its band and tick.
        let ownTarget = home.target.flatMap { $0.fromCarriedRecovery ? nil : $0 }
        let alarm = alarmCheck(r, home: home)
        return HomeCoachingRules.Inputs(
            dayKey: key, recovery: ownRecovery, recoveryHistory: history, calibration: calibration,
            strain: home.strain.value, optimalRange: ownTarget?.range, strainTarget: ownTarget?.targetValue,
            hrv: displayRow(r)?.avgHrv, hrvBaseline: hrvBaseline, sleepPerformance: performance,
            sleepDebtMin: debt.last { $0.day == key }?.value,
            previousSleepDebtMin: debt.last { $0.day == yesterday }?.value,
            alarm: alarm,
            weekInReview: isMonday && lastWeekScored >= 3)
    }

    /// This morning's strap alarm against when last night ended. The alarm comes from
    /// `AppModel.nextSmartAlarmDate`, the function the strap is armed from (per-day overrides included),
    /// on the settings the request captured for tonight's plan (`PulsePrefs.sleepPlan`), and only when the
    /// strap will arm it, so the card names the alarm that will really ring. `nowMinute` is the request's;
    /// the view moves it to the current minute.
    private func alarmCheck(_ r: PulseRequest, home: HomeSnapshot) -> HomeCoachingRules.AlarmCheck? {
        let s = r.prefs.sleepPlan
        guard s.alarmEnabled, s.strapWillArm else { return nil }
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: r.now)
        guard let fire = AppModel.nextSmartAlarmDate(minutes: s.alarmMinutes, weekdays: s.alarmWeekdays,
                                                     overrides: s.dayTimes, from: midnight, calendar: cal),
              cal.isDate(fire, inSameDayAs: midnight) else { return nil }
        func minuteOfDay(_ date: Date) -> Int {
            let c = cal.dateComponents([.hour, .minute], from: date)
            return (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
        let woke = home.lastNight.flatMap { cal.isDate($0.wake, inSameDayAs: r.now) ? minuteOfDay($0.wake) : nil }
        return HomeCoachingRules.AlarmCheck(alarmMinute: minuteOfDay(fire), wokeMinute: woke,
                                            nowMinute: minuteOfDay(r.now))
    }

    // MARK: Daily Outlook

    private func outlookFacts(_ r: PulseRequest, home: HomeSnapshot, zones: [String: ZoneDay]) async -> PulseOutlookFacts {
        let key = r.day.key
        // Recovery against its 7-day average (the days before today).
        let weekAgo = PulseDisplay.dayKey(key, offsetBy: -7) ?? key
        let recent = r.days.filter { $0.day >= weekAgo && $0.day < key }.compactMap(\.recovery)
        let average = recent.count >= 3 ? PulseDisplay.displayedPercent(recent.reduce(0, +) / Double(recent.count)) : nil

        // The journal streak, over the local days the journal keys entries by.
        let localKeys = Self.journalKeys(r)
        let logged = await journalDays(r, home: home)
        let loggedToday = logged.contains(localKeys[0])
        var streak = 0
        for k in localKeys.dropFirst(loggedToday ? 0 : 1) {
            guard logged.contains(k) else { break }
            streak += 1
        }

        // This week's zone minutes: the 7 days ending today, the HR ZONES (WEEKLY) rows' own figures.
        let weekStart = PulseDisplay.dayKey(key, offsetBy: -6) ?? key
        let week = zones.filter { $0.key >= weekStart && $0.key <= key }.values
        let counted = week.reduce(0) { $0 + $1.activities }
        let total = week.reduce(0.0) { $0 + $1.minutes.reduce(0, +) }
        let high = week.reduce(0.0) { $0 + $1.minutes[3] + $1.minutes[4] }
        return PulseOutlookFacts(recoveryAverage7: average, journalStreak: streak, journalLoggedToday: loggedToday,
                                 zoneMinutesWeek: counted > 0 && total > 0 ? total : nil,
                                 highZoneMinutesWeek: counted > 0 && total > 0 ? high : nil,
                                 zoneActivitiesWeek: counted)
    }

    /// The last 60 local days, newest first: the outlook's streak window and Get Started's journal check.
    private static func journalKeys(_ r: PulseRequest) -> [String] {
        let cal = Calendar.current
        return (0..<60).map { Repository.localDayKey(cal.date(byAdding: .day, value: -$0, to: r.now) ?? r.now) }
    }

    /// The local days of the last 60 with a journal entry, read once for the outlook and Get Started.
    /// Logging an entry does not bump `refreshSeq`, so the cache is also keyed on the day's journal strip
    /// (read fresh with every Home snapshot): a newly logged day misses it, and the two never disagree.
    private func journalDays(_ r: PulseRequest, home: HomeSnapshot) async -> Set<String> {
        let keys = Self.journalKeys(r)
        let strip = home.journal?.days.map { $0.logged ? "1" : "0" }.joined() ?? "-"
        return await cached("home.journal60.\(keys[0]).\(strip)") {
            await repo.nativeJournalDays(from: keys.last ?? r.day.key, to: keys.first ?? r.day.key)
        }
    }

    // MARK: Get Started

    /// Today's Get Started and Looking Ahead facts (a past day has none: `PulseGetStartedFacts.pastDay`).
    private func getStartedFacts(_ r: PulseRequest, home: HomeSnapshot, rows: [WorkoutRow]) async -> PulseGetStartedFacts {
        let scored = home.scoredDays
        let progress: PulseGetStartedFacts.Progress?
        if case .calibrating(let nights, let of) = home.recovery.state {
            progress = .init(done: nights, of: of)
        } else if scored == 0 {
            progress = .init(done: 0, of: Baselines.minNightsSeed)
        } else if scored < 7 {
            progress = .init(done: scored, of: 7)
        } else {
            progress = nil
        }
        let apple = await appleRows()
        // Any journal answer in the last two months marks "Customize Your Journal" done.
        let journal = await journalDays(r, home: home)
        return PulseGetStartedFacts(
            isNewMember: scored == 0,
            calibration: progress,
            personalizing: scored < 7,
            hasWorkout: !rows.isEmpty,
            hasJournal: !journal.isEmpty,
            hasHistoryImport: !r.importedSleep.isEmpty || !apple.isEmpty,
            sleepScheduled: r.prefs.sleepPlan.windDownEnabled || r.prefs.sleepPlan.alarmEnabled)
    }
}
#endif
