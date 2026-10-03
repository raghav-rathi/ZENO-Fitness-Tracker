import Foundation

// TonightSleepPlan.swift — the ONE answer to "when do I wake tomorrow, and when should I be in bed for
// it", for every screen that states it: Home's TONIGHT'S SLEEP card and the Sleep Planner it opens
// (WHOOP_UI_SPEC §3.1 item 8c, §3.11). Two screens that each worked it out for themselves disagreed on the
// same data at the same moment (one followed an alarm that was off, the other the wearer's habit), which
// is the "two readouts of one fact" fault AGENTS.md names; both now resolve through here.
//
// THE WAKE, first source that names one:
//   1. the strap's silent alarm, only when it will actually buzz that morning: switched on, armed (a
//      WHOOP 5/MG strap arms only with Protocol probes) and allowed on that weekday;
//   2. the wind-down reminder's wake time while the reminder is on (its per-day time included);
//   3. the median wake of the recent nights (`habitNights`, at least `minHabitNights` of them);
//   4. 07:00, which says nothing about the wearer and must be labelled as a typical wake, never as theirs.
// Each candidate is the source's NEXT occurrence after now, worked out by the app with the same function
// the strap alarm is armed from, so this file never re-derives a clock time of its own.
//
// THE BEDTIME. `asleepBy` is wake − need × goal share (what Home's card has always printed);
// `inBed` is `SleepNeed.suggestedBedtime`, which also allows `latencyMin` to fall asleep. Neither is
// put before 20:00 on the evening before the wake unless the wake itself is before 05:00: WHOOP's
// "go to bed at 6:55 PM" is the suggestion members complained about (§3.11 States).
//
// Pure: no store, no clock, no settings. Minutes and dates in the calendar passed in.

public enum TonightSleepPlan {

    /// Where tonight's wake time came from, in the order the sources are tried.
    public enum WakeSource: String, Equatable, Sendable, CaseIterable {
        /// The strap's silent alarm, which will buzz that morning.
        case strapAlarm
        /// The wind-down reminder's wake time (its per-day time included), while the reminder is on.
        case windDown
        /// The median wake of the recent nights.
        case habit
        /// Nothing names a wake time: `typicalWakeMinute`.
        case typical
    }

    /// The wake assumed when nothing else names one (07:00).
    public static let typicalWakeMinute = 7 * 60
    /// Recent nights the habitual wake is the median of.
    public static let habitNights = 14
    /// Fewest of them for a habit to exist.
    public static let minHabitNights = 3
    /// The earliest suggested bedtime, as an hour of the evening before the wake.
    public static let earliestBedHour = 20
    /// A wake before this hour lifts the earliest-bedtime floor.
    public static let earlyWakeHour = 5

    // MARK: The wake

    /// One resolved wake time.
    public struct Wake: Equatable, Sendable {
        public let date: Date
        public let source: WakeSource

        public init(date: Date, source: WakeSource) {
            self.date = date
            self.source = source
        }
    }

    /// The habitual wake minute: the median (on a clock that starts at noon, `PulseDisplay`'s) of the
    /// most recent `habitNights` wake minutes, newest first; nil under `minHabitNights`.
    public static func habitualWakeMinute(_ recentNewestFirst: [Int]) -> Int? {
        let window = Array(recentNewestFirst.prefix(habitNights))
        guard window.count >= minHabitNights else { return nil }
        return PulseDisplay.medianClockMinute(window)
    }

    /// Whether the strap alarm buzzes on the morning of `date`: switched on, armed, and that weekday in
    /// `weekdays` (Calendar weekdays, 1 = Sunday; an empty set means every day, as the alarm stores it,
    /// while a set holding no valid weekday means none).
    public static func alarmBuzzes(on date: Date, enabled: Bool, armed: Bool, weekdays: Set<Int>,
                                   calendar: Calendar) -> Bool {
        guard enabled, armed else { return false }
        if weekdays.isEmpty { return true }
        return weekdays.contains(calendar.component(.weekday, from: date))
    }

    /// The first source that names a wake. Each argument is that source's next occurrence after now, or
    /// nil when the source says nothing tonight (`strapAlarm` only when `alarmBuzzes`, `windDown` only
    /// while the reminder is on, `habit` only with a `habitualWakeMinute`).
    public static func wake(strapAlarm: Date?, windDown: Date?, habit: Date?, typical: Date) -> Wake {
        if let strapAlarm { return Wake(date: strapAlarm, source: .strapAlarm) }
        if let windDown { return Wake(date: windDown, source: .windDown) }
        if let habit { return Wake(date: habit, source: .habit) }
        return Wake(date: typical, source: .typical)
    }

    // MARK: The bedtime

    /// Tonight's bedtime for a wake.
    public struct Bedtime: Equatable, Sendable {
        /// When to be asleep: wake − need × share, or `latencyMin` after a held `inBed`.
        public let asleepBy: Date
        /// When to be in bed: `asleepBy` less the time it takes to fall asleep.
        public let inBed: Date
        /// `inBed` was held at `earliestBedHour`: the night then covers less than the goal.
        public let clamped: Bool

        public init(asleepBy: Date, inBed: Date, clamped: Bool) {
            self.asleepBy = asleepBy
            self.inBed = inBed
            self.clamped = clamped
        }
    }

    /// The bedtime that sleeps `needMin × fraction` before `wake`, in bed `latencyMin` earlier
    /// (`SleepNeed.suggestedBedtime`, in whole minutes, as Home has always rounded the need, so every
    /// screen prints the same clock minute), held at the earliest bedtime.
    public static func bedtime(wake: Date, needMin: Double, fraction: Double = 1,
                               latencyMin: Double = SleepNeed.typicalSleepLatencyMin,
                               calendar: Calendar) -> Bedtime {
        let latency = max(latencyMin, 0)
        let sleepMin = (max(needMin, 0) * max(fraction, 0)).rounded()
        let inBed = wake.addingTimeInterval(-(sleepMin + latency) * 60)
        let held = earliest(inBed, wake: wake, calendar: calendar)
        return Bedtime(asleepBy: held.date.addingTimeInterval(latency * 60), inBed: held.date,
                       clamped: held.clamped)
    }

    /// The bedtime that has the wearer asleep at a clock minute (a Sleep Consistency target, which is
    /// scored on sleep onsets): that minute's last occurrence before the wake, within the day before it,
    /// in bed `latencyMin` earlier, held at the earliest bedtime.
    public static func bedtime(asleepAtMinute minute: Double, wake: Date,
                               latencyMin: Double = SleepNeed.typicalSleepLatencyMin,
                               calendar: Calendar) -> Bedtime {
        let latency = max(latencyMin, 0)
        let asleep = occurrence(ofMinute: minute, before: wake, calendar: calendar)
        let held = earliest(asleep.addingTimeInterval(-latency * 60), wake: wake, calendar: calendar)
        return Bedtime(asleepBy: held.date.addingTimeInterval(latency * 60), inBed: held.date,
                       clamped: held.clamped)
    }

    /// The last time the clock reads `minute` (minutes since local midnight, in [0, 1440)) before
    /// `wake`: on the wake's own day, else the day before. Set on the calendar rather than counted back,
    /// so a night across a daylight-saving change still reads the minute asked for.
    public static func occurrence(ofMinute minute: Double, before wake: Date, calendar: Calendar) -> Date {
        let m = min(max(minute, 0), 1_439.99)
        let hour = Int(m) / 60
        let whole = Int(m) % 60
        let second = Int(((m - m.rounded(.down)) * 60).rounded(.down))
        let wakeDay = calendar.startOfDay(for: wake)
        if let sameDay = calendar.date(bySettingHour: hour, minute: whole, second: second, of: wakeDay),
           sameDay < wake {
            return sameDay
        }
        let eve = calendar.date(byAdding: .day, value: -1, to: wakeDay) ?? wakeDay.addingTimeInterval(-86_400)
        return calendar.date(bySettingHour: hour, minute: whole, second: second, of: eve)
            ?? wake.addingTimeInterval(-86_400)
    }

    /// `bed`, or `earliestBedHour`:00 on the evening before `wake` if `bed` is earlier and the wake is not
    /// before `earlyWakeHour`.
    static func earliest(_ bed: Date, wake: Date, calendar: Calendar) -> (date: Date, clamped: Bool) {
        guard calendar.component(.hour, from: wake) >= earlyWakeHour else { return (bed, false) }
        let wakeDay = calendar.startOfDay(for: wake)
        guard let eve = calendar.date(byAdding: .day, value: -1, to: wakeDay),
              let floor = calendar.date(bySettingHour: earliestBedHour, minute: 0, second: 0, of: eve),
              bed < floor else { return (bed, false) }
        return (floor, true)
    }
}
