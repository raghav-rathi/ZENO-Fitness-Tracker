#if os(iOS)
import Foundation
import SwiftUI
import StrandAnalytics
import WhoopStore

// MARK: - Home's own builds (group "home")

extension PulseSnapshotBuilder {

    /// Home's own facts for the request's day: the dashboard rows in `items`, the coaching rules' inputs,
    /// the Daily Outlook's facts and the Get Started flags. `home` is the HomeSnapshot for the same day;
    /// every figure the two share is read from it (the dials, the stats, tonight's plan), never re-derived.
    func homeExtras(_ r: PulseRequest, home: HomeSnapshot, items: [PulseDashboardItem]) async -> HomeExtrasSnapshot? {
        begin(r.seq)
        guard home.day == r.day else { return nil }
        let rest = await restSeries()
        let debt = await homeSeries("sleep_debt_min")
        let rows = await workoutRows()
        guard isCurrent(r) else { return nil }

        var dashboard: [PulseDashboardItem: PulseDashboardValue] = [:]
        for item in Set(items) {
            dashboard[item] = await dashboardValue(item, r: r, home: home, rest: rest, debt: debt)
            guard isCurrent(r) else { return nil }
        }

        let coaching = r.day.isToday ? coachingInputs(r, home: home, rest: rest, debt: debt) : nil
        let outlook = r.day.isToday ? await outlookFacts(r, rows: rows) : nil
        let start = await getStartedFacts(r, home: home, rows: rows)
        guard isCurrent(r) else { return nil }
        return HomeExtrasSnapshot(seq: r.seq, day: r.day, dashboard: dashboard, coaching: coaching,
                                  outlook: outlook, start: start)
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
                                debt: [(day: String, value: Double)]) async -> PulseDashboardValue {
        let key = r.day.key
        let polarity = item.polarity
        switch item {
        // The vitals, steps and calories HomeSnapshot already resolved (one resolver per fact).
        case .hrv: return stat("hrv", home: home, item: item)
        case .rhr: return stat("rhr", home: home, item: item)
        case .respiratoryRate: return stat("resp", home: home, item: item)
        case .skinTemperature: return stat("skin", home: home, item: item)
        case .bloodOxygen: return stat("spo2", home: home, item: item)
        case .steps: return stat("steps", home: home, item: item)
        case .calories: return stat("kcal", home: home, item: item)

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
            case .carried: valueDay = rest.last?.day
            default: valueDay = nil
            }
            return compared(home.sleep.value, on: valueDay, caption: home.sleep.caption, history: rest,
                            dayKey: key, text: Self.percentNumber, unit: "%", baselineText: Self.percent,
                            polarity: polarity, fallback: item.classicRoute)
        case .dayStrain:
            let history = r.days.compactMap { m in
                m.strain.map { (day: m.day, value: UnitFormatter.effortValue($0, scale: .whoop)) }
            }
            return compared(home.strain.value, on: key, caption: nil, history: history, dayKey: key,
                            text: PulseFormat.oneDecimal, unit: nil, baselineText: PulseFormat.oneDecimal,
                            polarity: polarity, fallback: item.classicRoute, runningTotal: r.day.isToday)

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

        // Body figures (Apple Health and the strap's estimates): the latest within 30 days, said so.
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
            return compared(point?.value, on: point?.day, caption: carriedCaption(point?.day, key), history: shown,
                            dayKey: key, text: PulseFormat.oneDecimal, unit: UnitFormatter.massUnit(Self.unitSystem),
                            baselineText: PulseFormat.oneDecimal, polarity: polarity, fallback: item.classicRoute,
                            flatPercent: 0.5)
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
        case .hrZones13, .hrZones45:
            let series = await homeSeries(item == .hrZones13 ? "hr_zones13_min" : "hr_zones45_min")
            return weeklyZones(series, dayKey: key, polarity: polarity, fallback: item.classicRoute)

        case .stressMonitor, .strainRecovery:
            return .empty(item.classicRoute)
        }
    }

    /// A row from one of HomeSnapshot's stats. WHOOP prints counts and heart rates bare, so only "%" and
    /// a temperature keep their unit; a running total (steps, calories today) says "So far today".
    private func stat(_ id: String, home: HomeSnapshot, item: PulseDashboardItem) -> PulseDashboardValue {
        guard let s = home.stats.first(where: { $0.id == id }) else { return .empty(item.classicRoute) }
        guard s.value != "–" else { return .empty(.tab(s.route)) }
        let unit: String? = s.unit == "%" || s.unit.contains("°") ? s.unit : nil
        let trend = s.baselineDelta.map { PulseTrend(delta: $0, polarity: item.polarity) }
            ?? s.comparison.map { c in PulseTrend(direction: Self.direction(c.direction), polarity: item.polarity) }
        return PulseDashboardValue(value: s.value, unit: unit, trend: trend,
                                   baseline: s.isRunningTotal ? String(localized: "So far today") : s.baseline,
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
    /// grey dot. A running total (today's Strain) says "So far today" instead of a comparison.
    private func compared(_ value: Double?, on valueDay: String?, caption: String?,
                          history: [(day: String, value: Double)], dayKey: String, text: (Double) -> String,
                          unit: String?, baselineText: (Double) -> String, polarity: PulseMetricPolarity,
                          fallback: PulseRoute, flatPercent: Double = 2, runningTotal: Bool = false,
                          compareDay: String? = nil) -> PulseDashboardValue {
        guard let value, value.isFinite, let valueDay else { return .empty(fallback) }
        if runningTotal {
            return PulseDashboardValue(value: text(value), unit: unit, trend: nil,
                                       baseline: String(localized: "So far today"), caption: caption, fallback: fallback)
        }
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

    /// A WEEKLY zone total: the 7 days ending on the day, against the mean week of the 28 days before.
    private func weeklyZones(_ series: [(day: String, value: Double)], dayKey: String,
                             polarity: PulseMetricPolarity, fallback: PulseRoute) -> PulseDashboardValue {
        guard let weekStart = PulseDisplay.dayKey(dayKey, offsetBy: -6),
              let baseStart = PulseDisplay.dayKey(weekStart, offsetBy: -28) else { return .empty(fallback) }
        let week = series.filter { $0.day >= weekStart && $0.day <= dayKey }
        guard !week.isEmpty else { return .empty(fallback) }
        let total = week.reduce(0) { $0 + $1.value }
        let before = series.filter { $0.day >= baseStart && $0.day < weekStart }
        let text = PulseFormat.hoursMinutes
        guard before.count >= 5 else {
            return PulseDashboardValue(value: text(total), unit: nil, trend: nil, baseline: nil, caption: nil,
                                       fallback: fallback)
        }
        let reference = before.reduce(0) { $0 + $1.value } / 4
        return PulseDashboardValue(value: text(total), unit: nil,
                                   trend: PulseTrend(delta: text(total) == text(reference) ? 0 : total - reference,
                                                     polarity: polarity),
                                   baseline: text(reference), caption: nil, fallback: fallback)
    }

    private static func percentNumber(_ v: Double) -> String { "\(PulseDisplay.displayedPercent(v))" }
    private static func percent(_ v: Double) -> String { "\(PulseDisplay.displayedPercent(v))%" }

    /// The wearer's unit system (Settings), read the way every screen resolves it.
    private static var unitSystem: UnitSystem {
        UnitSystem(rawValue: UserDefaults.standard.string(forKey: UnitPrefs.systemKey) ?? "") ?? .metric
    }

    // MARK: Coaching

    /// The coaching rules' inputs the store answers (§3.14 [Z]); the view adds the illness heads-up, this
    /// morning's alarm and the release notes, which live in app state.
    private func coachingInputs(_ r: PulseRequest, home: HomeSnapshot, rest: [(day: String, value: Double)],
                                debt: [(day: String, value: Double)]) -> HomeCoachingRules.Inputs {
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
        let isMonday = Calendar.current.component(.weekday, from: r.now) == 2
        // A target only from the day's own Recovery, exactly as the dial draws its band.
        let ownTarget = home.target.flatMap { $0.fromCarriedRecovery ? nil : $0 }
        return HomeCoachingRules.Inputs(
            dayKey: key, recovery: ownRecovery, recoveryHistory: history, calibration: calibration,
            strain: home.strain.value, optimalRange: ownTarget?.range,
            hrv: displayRow(r)?.avgHrv, hrvBaseline: hrvBaseline, sleepPerformance: performance,
            sleepDebtMin: debt.last { $0.day == key }?.value,
            previousSleepDebtMin: debt.last { $0.day == yesterday }?.value,
            weekInReview: isMonday && lastWeekScored >= 3)
    }

    // MARK: Daily Outlook

    private func outlookFacts(_ r: PulseRequest, rows: [WorkoutRow]) async -> PulseOutlookFacts {
        let key = r.day.key
        // Recovery against its 7-day average (the days before today).
        let weekAgo = PulseDisplay.dayKey(key, offsetBy: -7) ?? key
        let recent = r.days.filter { $0.day >= weekAgo && $0.day < key }.compactMap(\.recovery)
        let average = recent.count >= 3 ? PulseDisplay.displayedPercent(recent.reduce(0, +) / Double(recent.count)) : nil

        // The journal streak, over the local days the journal keys entries by.
        let cal = Calendar.current
        let localKeys = (0..<60).map { Repository.localDayKey(cal.date(byAdding: .day, value: -$0, to: r.now) ?? r.now) }
        let logged = await repo.nativeJournalDays(from: localKeys.last ?? key, to: localKeys.first ?? key)
        let loggedToday = logged.contains(localKeys[0])
        var streak = 0
        for k in localKeys.dropFirst(loggedToday ? 0 : 1) {
            guard logged.contains(k) else { break }
            streak += 1
        }

        // Zone minutes across the last 7 days' activities: the export's own split where a row carries one,
        // else the strap's heart rate binned into the wearer's zones (the Workout detail's reader).
        let since = Int(r.now.timeIntervalSince1970) - 7 * 86_400
        let week = rows.filter { $0.startTs >= since }.sorted { $0.startTs > $1.startTs }.prefix(20)
        var zones = [Double](repeating: 0, count: 5)
        var counted = 0
        for w in week {
            if let pct = WorkoutZones.percents(w.zonesJSON) {
                let minutes = (w.durationS ?? Double(w.endTs - w.startTs)) / 60
                for i in 0..<5 { zones[i] += minutes * pct[i] / 100 }
                counted += 1
            } else if let minutes = await cached("home.zones.\(w.startTs)|\(w.endTs)|\(w.source)", load: {
                await repo.workoutZoneMinutes(from: w.startTs, to: w.endTs, zoneSet: r.profile.zoneSet, source: w.source)
            }) {
                // `timeInZone` reports zones 1-5 in order.
                for i in 0..<min(5, minutes.count) { zones[i] += minutes[i] }
                counted += 1
            }
        }
        let total = zones.reduce(0, +)
        return PulseOutlookFacts(recoveryAverage7: average, journalStreak: streak, journalLoggedToday: loggedToday,
                                 zoneMinutesWeek: counted > 0 && total > 0 ? total : nil,
                                 highZoneMinutesWeek: counted > 0 && total > 0 ? zones[3] + zones[4] : nil,
                                 activitiesThisWeek: week.count)
    }

    // MARK: Get Started

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
        let cal = Calendar.current
        let from = Repository.localDayKey(cal.date(byAdding: .day, value: -60, to: r.now) ?? r.now)
        let journal = await repo.nativeJournalDays(from: from, to: Repository.localDayKey(r.now))
        return PulseGetStartedFacts(
            isNewMember: r.day.isToday && scored == 0,
            calibration: r.day.isToday ? progress : nil,
            personalizing: r.day.isToday && scored < 7,
            hasWorkout: !rows.isEmpty,
            hasJournal: !journal.isEmpty,
            hasHistoryImport: !r.importedSleep.isEmpty || !apple.isEmpty,
            sleepScheduled: r.prefs.alarmWakeMinute != nil || r.prefs.strapAlarmMinute != nil)
    }
}
#endif
