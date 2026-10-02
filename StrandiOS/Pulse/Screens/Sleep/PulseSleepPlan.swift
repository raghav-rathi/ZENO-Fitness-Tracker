#if os(iOS)
import Foundation
import StrandAnalytics

// MARK: - Tonight's plan (WHOOP_UI_SPEC §3.11)
//
// One resolver for everything the Sleep Planner states about tonight, so the times, the bar, the headline,
// the alarm panel and the schedule can never describe different nights:
//
//   wake      the next occurrence of the alarm's wake time (its per-day override for that weekday, else the
//             base time), through `AppModel.nextSmartAlarmDate`, the SAME pure resolver `applySmartAlarm`
//             arms the strap from. It is asked with every weekday allowed, so a day the alarm is switched off
//             for still has a wake time to plan around; `alarmFires` says whether the strap buzzes for it.
//   bedtime   `SleepNeed.suggestedBedtime` for the goal's share of tonight's need, with its 15 minutes to
//             fall asleep. Never before 20:00 the evening before (WHOOP's "go to bed at 6:55 PM" is the
//             oddity users complained about) unless the wake itself is before 05:00.
//   optimal   the bed and wake time that keep tonight's Sleep Consistency highest
//             (`SleepConsistencyTarget`, the same target the dive's consistency curves draw).

/// The three need goals of "TOMORROW I WANT TO".
enum PulseSleepGoal: String, CaseIterable, Identifiable {
    case peak, perform, getBy

    var id: String { rawValue }

    /// "PEAK" / "PERFORM" / "GET BY" (the capsule uppercases it).
    var title: String {
        switch self {
        case .peak: return String(localized: "Peak")
        case .perform: return String(localized: "Perform")
        case .getBy: return String(localized: "Get by")
        }
    }

    /// The share of tonight's need the goal plans for.
    var fraction: Double {
        switch self {
        case .peak: return 1.0
        case .perform: return 0.85
        case .getBy: return 0.70
        }
    }

    var percent: Int { Int((fraction * 100).rounded()) }
}

struct PulseSleepPlan: Equatable {
    /// When tonight ends.
    let wake: Date
    /// The suggested time to get into bed.
    let bedtime: Date
    /// Bed to wake, minutes.
    let timeInBedMin: Double
    /// Tonight's need (all of it) and the goal's share of it, minutes.
    let needMin: Double
    let goalNeedMin: Double
    /// The strap alarm will buzz at `wake`.
    let alarmFires: Bool
    /// The suggestion was held at 20:00: the plan then covers less than the goal.
    let clamped: Bool
    /// It is already past the suggested bedtime.
    let isLate: Bool
    /// What going to bed now still gets, when late (minutes asleep, allowing the latency).
    let sleepIfNowMin: Double?
    /// The consistency-optimal window, when there are enough recent nights.
    let optimalBed: Date?
    let optimalWake: Date?

    /// Sleep the plan allows for (time in bed less the latency), as a share of tonight's need, 0–100.
    var coveragePercent: Int {
        guard needMin > 0 else { return 0 }
        let asleep = max(0, timeInBedMin - SleepNeed.typicalSleepLatencyMin)
        return Int((min(1, asleep / needMin) * 100).rounded())
    }

    /// The earliest bedtime the planner suggests, and the wake before which no clamp applies.
    static let earliestBedHour = 20
    static let earlyWakeHour = 5

    static func resolve(now: Date, goal: PulseSleepGoal, needMin: Double, alarmEnabled: Bool, alarmMinutes: Int,
                        alarmWeekdays: Set<Int>, overrides: [Int: Int], strapWillArm: Bool,
                        timings: [SleepConsistency.NightTiming],
                        calendar cal: Calendar = .current) -> PulseSleepPlan? {
        guard needMin > 0,
              let wake = AppModel.nextSmartAlarmDate(minutes: alarmMinutes, weekdays: [], overrides: overrides,
                                                     from: now, calendar: cal) else { return nil }
        let weekday = cal.component(.weekday, from: wake)
        let fires = alarmEnabled && strapWillArm && (alarmWeekdays.isEmpty || alarmWeekdays.contains(weekday))

        let goalNeed = needMin * goal.fraction
        var bedtime = SleepNeed.suggestedBedtime(wake: wake, needMin: needMin, needFraction: goal.fraction)
        var clamped = false
        let wakeHour = cal.component(.hour, from: wake)
        let wakeDay = cal.startOfDay(for: wake)
        if wakeHour >= earlyWakeHour,
           let earliest = cal.date(byAdding: .hour, value: earliestBedHour - 24, to: wakeDay),
           bedtime < earliest {
            bedtime = earliest
            clamped = true
        }
        let late = now > bedtime
        let sleepIfNow = late
            ? max(0, wake.timeIntervalSince(now) / 60 - SleepNeed.typicalSleepLatencyMin) : nil

        // The consistency target for the night that ends on the wake's day, placed around that wake.
        var optimalBed: Date?
        var optimalWake: Date?
        let wakeKey = Repository.localDayKey(wake)
        if let target = SleepConsistencyTarget.target(forNightEnding: wakeKey, nights: timings) {
            let wakeAt = wakeDay.addingTimeInterval(target.wakeMinute * 60)
            let bedBase = target.bedMinute >= 720 ? (cal.date(byAdding: .day, value: -1, to: wakeDay) ?? wakeDay) : wakeDay
            optimalWake = wakeAt
            optimalBed = bedBase.addingTimeInterval(target.bedMinute * 60)
        }
        return PulseSleepPlan(wake: wake, bedtime: bedtime, timeInBedMin: wake.timeIntervalSince(bedtime) / 60,
                              needMin: needMin, goalNeedMin: goalNeed, alarmFires: fires, clamped: clamped,
                              isLate: late, sleepIfNowMin: sleepIfNow, optimalBed: optimalBed,
                              optimalWake: optimalWake)
    }
}
#endif
