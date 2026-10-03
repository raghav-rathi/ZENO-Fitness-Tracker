#if os(iOS)
import Foundation
import StrandAnalytics

// MARK: - Tonight's plan (WHOOP_UI_SPEC §3.1 item 8c, §3.11)
//
// One resolver for everything a screen states about tonight, so the Sleep Planner's times, bar, headline
// and alarm panel and My Schedule can never describe different nights. Home's TONIGHT'S SLEEP card reads it
// too (`PulseSnapshotBuilder.tonightSleepPlan`), for the goal chosen in the planner:
//
//   wake      `TonightSleepPlan.wake`: the strap alarm only when it will buzz that morning (on, armed,
//             that weekday), else the wind-down reminder's wake while it is on, else the median wake of
//             the last 14 nights, else 07:00 as a TYPICAL wake. Every candidate is the source's next
//             occurrence (its My Schedule day time included) through `AppModel.nextSmartAlarmDate`, the
//             function the strap alarm is armed from, so the plan and the strap cannot name different
//             mornings. Next after now, until the main night ending today is over; from then, after the
//             start of tomorrow (`planStart`), so the morning after waking plans the coming night instead
//             of "Now" to bed for this morning's wake.
//   bedtime   REACH MY SLEEP NEED: the goal's share of tonight's need (`Repository.sleepNeedTonight`)
//             before the wake, in bed 15 minutes earlier to fall asleep; IMPROVE MY SLEEP: asleep at the
//             Sleep Consistency target's bed time; REACH MY WEEKLY PLAN GOAL: the running Weekly Plan's
//             Sleep Performance goal as that share of the need and its Sleep Consistency goal as the
//             target's bed time, in bed by the earlier of the two, else the whole need. Never before 20:00
//             the evening before unless the wake is before 05:00 (`TonightSleepPlan`).
//   optimal   the bed and wake time that keep tonight's Sleep Consistency highest
//             (`SleepConsistencyTarget`, the same target the dive's consistency curves draw).

/// "TOMORROW I WANT TO" (§3.11 item 4).
enum PulseSleepGoal: Hashable, Identifiable {
    /// REACH MY SLEEP NEED, planning for this share of tonight's need (100, 85 or 70).
    case need(percent: Int)
    /// IMPROVE MY SLEEP: the bedtime that keeps tomorrow's Sleep Consistency highest.
    case improve
    /// REACH MY WEEKLY PLAN GOAL: tonight planned for the running Weekly Plan's sleep goals
    /// (`PulseWeeklyPlanSleepGoals`).
    case weeklyPlan

    static let needPercents = [100, 85, 70]
    static let `default` = PulseSleepGoal.need(percent: 100)
    /// Where the planner keeps the chosen goal (`storageValue`), which Home's card plans for too.
    static let storageKey = "pulse.sleepPlanner.goal"

    var id: String { storageValue }

    /// What `@AppStorage` keeps.
    var storageValue: String {
        switch self {
        case .need(let percent): return "need\(percent)"
        case .improve: return "improve"
        case .weeklyPlan: return "weeklyPlan"
        }
    }

    /// The stored goal, the first build's Peak / Perform / Get By included.
    init(storageValue raw: String) {
        switch raw {
        case "improve": self = .improve
        case "weeklyPlan": self = .weeklyPlan
        case "need85", "perform": self = .need(percent: 85)
        case "need70", "getBy": self = .need(percent: 70)
        default: self = .default
        }
    }

    /// The capsule's words (it uppercases them).
    var title: String {
        switch self {
        case .need: return String(localized: "Reach my sleep need")
        case .improve: return String(localized: "Improve my sleep")
        case .weeklyPlan: return String(localized: "Reach my Weekly Plan goal")
        }
    }

    /// The action sheet's words.
    var choiceTitle: String {
        switch self {
        case .need(let percent): return String(localized: "Reach \(percent)% of my sleep need")
        case .improve: return String(localized: "Improve my sleep consistency")
        case .weeklyPlan: return String(localized: "Reach my Weekly Plan goal")
        }
    }
}

/// The running Weekly Plan's sleep goals (§3.19, `PulsePlanStore`), what REACH MY WEEKLY PLAN GOAL plans
/// tonight for. nil when no plan runs or the plan has no sleep goal.
struct PulseWeeklyPlanSleepGoals: Equatable {
    /// The week's average Sleep Consistency the plan asks for (%), when it has that goal.
    var consistency: Double?
    /// The week's average Sleep Performance the plan asks for (%), when it has that goal.
    var performance: Double?

    /// Read from the plan as it stands (`store`, else the app's plan store), with the targets
    /// `PulsePlanGoal.title` prints for a goal saved without one.
    @MainActor
    static func current(_ store: PulsePlanStore? = nil) -> PulseWeeklyPlanSleepGoals? {
        guard let goals = (store ?? .shared).plan?.goals else { return nil }
        let consistency = goals.first { $0.kind == .sleepConsistency }.map { $0.value ?? 80 }
        let performance = goals.first { $0.kind == .sleepPerformance }.map { $0.value ?? 85 }
        guard consistency != nil || performance != nil else { return nil }
        return PulseWeeklyPlanSleepGoals(consistency: consistency, performance: performance)
    }
}

/// The alarm and wake-time settings the plan reads, captured once per render (BehaviorStore's strap alarm,
/// WindDownNudge's reminder and My Schedule's per-day times), so one pass never sees two values.
struct PulseSleepPlanSettings: Equatable {
    var alarmEnabled = false
    /// The strap alarm's base wake time, minutes after midnight.
    var alarmMinutes = TonightSleepPlan.typicalWakeMinute
    /// Calendar weekdays the alarm buzzes on; empty means every day.
    var alarmWeekdays: Set<Int> = []
    /// My Schedule's per-day wake times ({weekday: minutes}), shared by the strap alarm and the reminder.
    var dayTimes: [Int: Int] = [:]
    /// False for a WHOOP 5/MG strap without Protocol probes, whose alarm never arms.
    var strapWillArm = true
    var windDownEnabled = false
    /// The wind-down reminder's base wake time, minutes after midnight.
    var windDownWakeMinutes = TonightSleepPlan.typicalWakeMinute

    /// The settings as stored now.
    @MainActor
    static func current(behavior: BehaviorStore, strapWillArm: Bool) -> PulseSleepPlanSettings {
        PulseSleepPlanSettings(alarmEnabled: behavior.smartAlarmEnabled, alarmMinutes: behavior.smartAlarmMinutes,
                               alarmWeekdays: behavior.smartAlarmWeekdays,
                               dayTimes: WindDownNudge.perDayWakeOverrides, strapWillArm: strapWillArm,
                               windDownEnabled: WindDownNudge.isEnabled,
                               windDownWakeMinutes: WindDownNudge.wakeMinutes)
    }

    /// The same, read straight from the stored keys (BehaviorStore's alarm keys, as `BehaviorStore.init` reads
    /// them, and WindDownNudge's), for a caller without the store, such as the shell building the request
    /// for Home's card (`PulseSnapshotBuilder.tonightSleepPlan`).
    @MainActor
    static func stored(strapWillArm: Bool = true, defaults d: UserDefaults = .standard) -> PulseSleepPlanSettings {
        let weekdays = (d.array(forKey: "behavior.smartAlarmWeekdays") as? [Int] ?? []).filter { (1...7).contains($0) }
        return PulseSleepPlanSettings(
            alarmEnabled: d.object(forKey: "behavior.smartAlarmEnabled") as? Bool ?? false,
            alarmMinutes: d.object(forKey: "behavior.smartAlarmMinutes") as? Int ?? TonightSleepPlan.typicalWakeMinute,
            alarmWeekdays: Set(weekdays), dayTimes: WindDownNudge.perDayWakeOverrides, strapWillArm: strapWillArm,
            windDownEnabled: WindDownNudge.isEnabled, windDownWakeMinutes: WindDownNudge.wakeMinutes)
    }
}

struct PulseSleepPlan: Equatable {
    /// The goal planned for (IMPROVE MY SLEEP falls back to the whole need without a consistency target).
    let goal: PulseSleepGoal
    /// When tonight ends, and what named it.
    let wake: Date
    let wakeSource: TonightSleepPlan.WakeSource
    /// The suggested time to get into bed, and the time to be asleep by.
    let bedtime: Date
    let asleepBy: Date
    /// Bed to wake, minutes.
    let timeInBedMin: Double
    /// Tonight's need (all of it), minutes.
    let needMin: Double
    /// The strap alarm's own wake time on the planned morning (its My Schedule day time, else its base
    /// time): what the panel's WAKE TIME SET TO shows and edits. Equal to `wake` when the alarm buzzes.
    let alarmTime: Date
    /// That morning's weekday, and whether My Schedule gives it a time of its own.
    let weekday: Int
    let hasDayTime: Bool
    /// The bedtime was held at 20:00: the plan then covers less than the goal.
    let clamped: Bool
    /// It is already past the suggested bedtime.
    let isLate: Bool
    /// What going to bed now still gets, when late (minutes asleep, allowing the latency).
    let sleepIfNowMin: Double?
    /// The consistency-optimal window, when there are enough recent nights.
    let optimalBed: Date?
    let optimalWake: Date?
    /// The Sleep Consistency this plan's onset and wake would score tomorrow, 0–100.
    let consistencyPercent: Double?

    /// The strap alarm buzzes at `wake`.
    var alarmFires: Bool { wakeSource == .strapAlarm }

    /// Sleep the plan allows for, as a share of tonight's need, 0–100.
    var coveragePercent: Int {
        guard needMin > 0 else { return 0 }
        let asleep = max(0, wake.timeIntervalSince(asleepBy) / 60)
        return Int((min(1, asleep / needMin) * 100).rounded())
    }

    /// The plan for `goal`, or nil before there is a need to plan for. `recentWakeMinutes` are the wake
    /// minutes of the recent nights, newest first; `timings` the nights SleepConsistency compares with;
    /// `weeklyPlan` the running Weekly Plan's sleep goals, for REACH MY WEEKLY PLAN GOAL; `nightEnded` the end
    /// of the main night that ended on today's logical day, if one is recorded (`SleepPlannerSnapshot`).
    static func resolve(now: Date, goal: PulseSleepGoal, needMin: Double, settings s: PulseSleepPlanSettings,
                        recentWakeMinutes: [Int], timings: [SleepConsistency.NightTiming],
                        weeklyPlan: PulseWeeklyPlanSleepGoals? = nil, nightEnded: Date? = nil,
                        calendar cal: Calendar = .current) -> PulseSleepPlan? {
        // The wake is looked for after the plan's start; lateness is still judged against now.
        let from = planStart(now: now, nightEnded: nightEnded, calendar: cal)
        guard needMin > 0,
              let typical = AppModel.nextSmartAlarmDate(minutes: TonightSleepPlan.typicalWakeMinute, weekdays: [],
                                                        from: from, calendar: cal) else { return nil }
        // Every source's next occurrence, through the function the strap alarm is armed from.
        let alarmNext = AppModel.nextSmartAlarmDate(minutes: s.alarmMinutes, weekdays: [], overrides: s.dayTimes,
                                                    from: from, calendar: cal)
        let alarmBuzzes = alarmNext.map {
            TonightSleepPlan.alarmBuzzes(on: $0, enabled: s.alarmEnabled, armed: s.strapWillArm,
                                         weekdays: s.alarmWeekdays, calendar: cal)
        } ?? false
        let windDown = s.windDownEnabled
            ? AppModel.nextSmartAlarmDate(minutes: s.windDownWakeMinutes, weekdays: [], overrides: s.dayTimes,
                                          from: from, calendar: cal)
            : nil
        let habit = TonightSleepPlan.habitualWakeMinute(recentWakeMinutes).flatMap {
            AppModel.nextSmartAlarmDate(minutes: $0, weekdays: [], from: from, calendar: cal)
        }
        let wake = TonightSleepPlan.wake(strapAlarm: alarmBuzzes ? alarmNext : nil, windDown: windDown,
                                         habit: habit, typical: typical)

        // The strap alarm's own time on that morning.
        let weekday = cal.component(.weekday, from: wake.date)
        let dayTime = s.dayTimes[weekday]
        let alarmMinutes = dayTime ?? s.alarmMinutes
        let alarmTime = cal.date(bySettingHour: alarmMinutes / 60, minute: alarmMinutes % 60, second: 0,
                                 of: wake.date) ?? wake.date

        // The consistency target for the night that ends on the wake's day.
        let wakeKey = Repository.localDayKey(wake.date)
        let target = SleepConsistencyTarget.target(forNightEnding: wakeKey, nights: timings)
        // IMPROVE MY SLEEP without a target, and REACH MY WEEKLY PLAN GOAL with no plan sleep goal left (the
        // plan ended, or lost it), plan for the whole need, and say so.
        let planned: PulseSleepGoal
        switch goal {
        case .improve where target == nil, .weeklyPlan where weeklyPlan == nil: planned = .default
        default: planned = goal
        }
        let bed: TonightSleepPlan.Bedtime
        switch planned {
        case .improve:
            bed = TonightSleepPlan.bedtime(asleepAtMinute: target?.bedMinute ?? 0, wake: wake.date, calendar: cal)
        case .need(let percent):
            bed = TonightSleepPlan.bedtime(wake: wake.date, needMin: needMin, fraction: Double(percent) / 100,
                                           calendar: cal)
        case .weeklyPlan:
            // Every sleep goal the plan has, planned short of none: the part of Sleep Performance a bedtime
            // decides is the hours asleep against the need, so its goal is that share of the need; a Sleep
            // Consistency goal is judged on timing, so asleep at the target's bed time, as IMPROVE MY SLEEP
            // plans (once there are nights enough for a target). With both, the earlier bedtime.
            bed = TonightSleepPlan.bedtime(wake: wake.date, needMin: needMin,
                                           share: weeklyPlan?.performance.map { $0 / 100 },
                                           asleepAtMinute: weeklyPlan?.consistency == nil ? nil : target?.bedMinute,
                                           calendar: cal)
        }
        let late = now > bed.inBed
        let sleepIfNow = late
            ? max(0, wake.date.timeIntervalSince(now) / 60 - SleepNeed.typicalSleepLatencyMin) : nil

        var optimalBed: Date?
        var optimalWake: Date?
        if let target {
            // The window as the target has it, never held at 20:00.
            optimalBed = TonightSleepPlan.occurrence(ofMinute: target.bedMinute, before: wake.date, calendar: cal)
            optimalWake = cal.date(bySettingHour: Int(target.wakeMinute) / 60, minute: Int(target.wakeMinute) % 60,
                                   second: 0, of: wake.date)
        }
        let consistency = SleepConsistencyTarget.projectedScore(
            bedMinute: minuteOfDay(bed.asleepBy, calendar: cal), wakeMinute: minuteOfDay(wake.date, calendar: cal),
            forNightEnding: wakeKey, nights: timings).map { $0 * 100 }

        return PulseSleepPlan(goal: planned, wake: wake.date, wakeSource: wake.source, bedtime: bed.inBed,
                              asleepBy: bed.asleepBy, timeInBedMin: wake.date.timeIntervalSince(bed.inBed) / 60,
                              needMin: needMin, alarmTime: alarmTime, weekday: weekday, hasDayTime: dayTime != nil,
                              clamped: bed.clamped, isLate: late, sleepIfNowMin: sleepIfNow, optimalBed: optimalBed,
                              optimalWake: optimalWake, consistencyPercent: consistency)
    }

    /// When tonight's wake is looked for from: now, until the main night that ended on today's logical day
    /// (`nightEnded`) is over; from then the start of the day after it ended, so a morning after waking,
    /// even before the usual wake time, plans the coming night instead of this morning's wake. Before
    /// 04:00 that night is last night's, so the plan still runs from now.
    static func planStart(now: Date, nightEnded: Date?, calendar cal: Calendar) -> Date {
        guard let nightEnded,
              let nextDay = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: nightEnded)) else { return now }
        return max(now, nextDay)
    }

    /// Minutes since local midnight, with the seconds.
    private static func minuteOfDay(_ date: Date, calendar cal: Calendar) -> Double {
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        return Double((c.hour ?? 0) * 60 + (c.minute ?? 0)) + Double(c.second ?? 0) / 60
    }
}

#endif
