import XCTest
@testable import StrandAnalytics

final class TonightSleepPlanTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        return c
    }()

    /// `minute` past local midnight on 3 Oct 2026 (a Saturday).
    private func morning(_ minute: Int, month: Int = 10, day: Int = 3) -> Date {
        let midnight = calendar.date(from: DateComponents(year: 2026, month: month, day: day)) ?? Date()
        return calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: midnight) ?? midnight
    }

    private func minuteOfDay(_ date: Date) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    // MARK: The bedtime Home prints and the one the planner prints

    func testHomesRecommendedBedtimeIsThePlansAsleepByTime() {
        // Home's card has always printed wake − need (`PulseDisplay.bedtimeMinute`); the plan's asleep-by
        // time is the same instant, so the two screens can differ only by the latency the planner adds.
        for wakeMinute in [6 * 60 + 30, 6 * 60 + 58, 7 * 60, 9 * 60 + 15, 14 * 60] {
            for need in [360.0, 452.4, 480, 566.6] {
                let plan = TonightSleepPlan.bedtime(wake: morning(wakeMinute), needMin: need, calendar: calendar)
                XCTAssertFalse(plan.clamped, "wake \(wakeMinute) need \(need)")
                XCTAssertEqual(minuteOfDay(plan.asleepBy),
                               PulseDisplay.bedtimeMinute(wakeMinute: wakeMinute, needMinutes: need),
                               "wake \(wakeMinute) need \(need)")
            }
        }
    }

    func testInBedIsTheSuggestedBedtimeAllowingTheLatency() {
        let wake = morning(6 * 60 + 58)
        for fraction in [1.0, 0.85, 0.7] {
            let plan = TonightSleepPlan.bedtime(wake: wake, needMin: 566, fraction: fraction, calendar: calendar)
            // The analytics' own suggestion, to the minute both screens print.
            let suggested = SleepNeed.suggestedBedtime(wake: wake, needMin: 566, needFraction: fraction)
            XCTAssertEqual(plan.inBed.timeIntervalSince(suggested), 0, accuracy: 30)
            XCTAssertEqual(plan.asleepBy.timeIntervalSince(plan.inBed), SleepNeed.typicalSleepLatencyMin * 60)
            XCTAssertEqual(wake.timeIntervalSince(plan.asleepBy), (566 * fraction).rounded() * 60)
        }
        // The review's night: a 9:26 need before a 6:58 wake is asleep by 9:32 PM, in bed by 9:17 PM.
        let night = TonightSleepPlan.bedtime(wake: wake, needMin: 566, calendar: calendar)
        XCTAssertEqual(minuteOfDay(night.asleepBy), 21 * 60 + 32)
        XCTAssertEqual(minuteOfDay(night.inBed), 21 * 60 + 17)
    }

    func testABedtimeBeforeEightIsHeldAtEightUnlessTheWakeIsEarly() {
        // A 12 h need before a 7:00 wake would be in bed at 6:45 PM.
        let held = TonightSleepPlan.bedtime(wake: morning(7 * 60), needMin: 720, calendar: calendar)
        XCTAssertTrue(held.clamped)
        XCTAssertEqual(minuteOfDay(held.inBed), 20 * 60)
        XCTAssertEqual(calendar.component(.day, from: held.inBed), 2, "the evening before the wake")
        XCTAssertEqual(minuteOfDay(held.asleepBy), 20 * 60 + 15)
        // A wake before 5:00 is the wearer's own choice of an early night.
        let early = TonightSleepPlan.bedtime(wake: morning(4 * 60 + 30), needMin: 600, calendar: calendar)
        XCTAssertFalse(early.clamped)
        XCTAssertEqual(minuteOfDay(early.inBed), 18 * 60 + 15)
    }

    func testTheConsistencyBedtimeHasTheWearerAsleepAtTheTarget() {
        let wake = morning(7 * 60)
        let evening = TonightSleepPlan.bedtime(asleepAtMinute: 23 * 60, wake: wake, calendar: calendar)
        XCTAssertEqual(minuteOfDay(evening.asleepBy), 23 * 60)
        XCTAssertEqual(calendar.component(.day, from: evening.asleepBy), 2)
        XCTAssertEqual(minuteOfDay(evening.inBed), 22 * 60 + 45)
        XCTAssertFalse(evening.clamped)
        // Past midnight: the same calendar day as the wake.
        let late = TonightSleepPlan.bedtime(asleepAtMinute: 30, wake: wake, calendar: calendar)
        XCTAssertEqual(minuteOfDay(late.asleepBy), 30)
        XCTAssertEqual(calendar.component(.day, from: late.asleepBy), 3)
        // A target before 8 PM is held there too.
        let early = TonightSleepPlan.bedtime(asleepAtMinute: 19 * 60, wake: wake, calendar: calendar)
        XCTAssertTrue(early.clamped)
        XCTAssertEqual(minuteOfDay(early.inBed), 20 * 60)
    }

    func testAClockMinuteIsFoundOnTheCalendarAcrossADaylightSavingChange() {
        // US clocks go back at 2:00 on Sunday 1 Nov 2026: the night is 25 hours of wall clock long, so
        // counting minutes back from the wake would land an hour off the time asked for.
        let wake = morning(7 * 60, month: 11, day: 1)   // 7:00 EST
        XCTAssertEqual(calendar.component(.month, from: wake), 11)
        XCTAssertEqual(minuteOfDay(wake), 7 * 60)
        let bed = TonightSleepPlan.occurrence(ofMinute: 23 * 60, before: wake, calendar: calendar)
        XCTAssertEqual(minuteOfDay(bed), 23 * 60)
        XCTAssertEqual(calendar.component(.day, from: bed), 31)
        // A minute later on the wake's own day than the wake itself falls on the day before.
        let after = TonightSleepPlan.occurrence(ofMinute: 8 * 60, before: wake, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: after), 31)
        XCTAssertEqual(minuteOfDay(after), 8 * 60)
    }

    // MARK: The wake

    func testTheWakeComesFromTheFirstSourceThatNamesOne() {
        let alarm = morning(6 * 60)
        let windDown = morning(6 * 60 + 30)
        let habit = morning(6 * 60 + 58)
        let typical = morning(TonightSleepPlan.typicalWakeMinute)
        XCTAssertEqual(TonightSleepPlan.wake(strapAlarm: alarm, windDown: windDown, habit: habit, typical: typical),
                       .init(date: alarm, source: .strapAlarm))
        XCTAssertEqual(TonightSleepPlan.wake(strapAlarm: nil, windDown: windDown, habit: habit, typical: typical),
                       .init(date: windDown, source: .windDown))
        XCTAssertEqual(TonightSleepPlan.wake(strapAlarm: nil, windDown: nil, habit: habit, typical: typical),
                       .init(date: habit, source: .habit))
        XCTAssertEqual(TonightSleepPlan.wake(strapAlarm: nil, windDown: nil, habit: nil, typical: typical),
                       .init(date: typical, source: .typical))
    }

    func testTheAlarmCountsOnlyWhenItWillBuzzThatMorning() {
        let saturday = morning(7 * 60)
        func buzzes(enabled: Bool = true, armed: Bool = true, _ weekdays: Set<Int>) -> Bool {
            TonightSleepPlan.alarmBuzzes(on: saturday, enabled: enabled, armed: armed, weekdays: weekdays,
                                         calendar: calendar)
        }
        XCTAssertTrue(buzzes([]), "an empty set is every day")
        XCTAssertTrue(buzzes([7]))
        XCTAssertFalse(buzzes([2, 3, 4, 5, 6]), "weekdays only: not on a Saturday")
        XCTAssertFalse(buzzes([0, 8]), "no valid weekday is no day")
        XCTAssertFalse(buzzes(enabled: false, []), "switched off")
        XCTAssertFalse(buzzes(armed: false, []), "a 5/MG strap without Protocol probes is not armed")
    }

    func testTheHabitIsTheMedianOfTheRecentNights() {
        XCTAssertNil(TonightSleepPlan.habitualWakeMinute([]))
        XCTAssertNil(TonightSleepPlan.habitualWakeMinute([420, 430]), "two nights are not a habit")
        XCTAssertEqual(TonightSleepPlan.habitualWakeMinute([418, 410, 425]), 418)
        // Only the newest fourteen count.
        let recent = Array(repeating: 418, count: 14) + Array(repeating: 600, count: 10)
        XCTAssertEqual(TonightSleepPlan.habitualWakeMinute(recent), 418)
        // Wakes either side of midnight are minutes apart, as Home has always taken them.
        XCTAssertEqual(TonightSleepPlan.habitualWakeMinute([1_430, 10, 20]),
                       PulseDisplay.medianClockMinute([1_430, 10, 20]))
    }
}
