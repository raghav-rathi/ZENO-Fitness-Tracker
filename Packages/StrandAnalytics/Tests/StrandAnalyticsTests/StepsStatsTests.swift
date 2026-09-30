import XCTest
@testable import StrandAnalytics

/// Day-key arithmetic, the goal, the goal-notification policy, averages, streaks, best day and the chart
/// ceiling behind the Steps screen.
final class StepsStatsTests: XCTestCase {

    // MARK: Day keys

    func testDayKeyArithmeticCrossesMonthYearAndLeapBoundaries() {
        XCTAssertEqual(StepsDayKeys.adding(1, to: "2026-09-30"), "2026-10-01")
        XCTAssertEqual(StepsDayKeys.adding(-1, to: "2026-01-01"), "2025-12-31")
        XCTAssertEqual(StepsDayKeys.adding(1, to: "2028-02-28"), "2028-02-29")
        XCTAssertEqual(StepsDayKeys.adding(-29, to: "2026-03-01"), "2026-01-31")
        XCTAssertEqual(StepsDayKeys.adding(0, to: "2026-09-30"), "2026-09-30")
        XCTAssertNil(StepsDayKeys.adding(1, to: "2026-02-30"))
        XCTAssertNil(StepsDayKeys.adding(1, to: "20260930"))
    }

    func testDayKeysIgnoreTheDeviceZone() {
        // The same arithmetic in every zone: keys are civil dates. A zone west of UTC used to be where a
        // formatter slipped a day; the helper must not depend on TimeZone.current at all.
        let saved = NSTimeZone.default
        defer { NSTimeZone.default = saved }
        for id in ["America/Los_Angeles", "Pacific/Kiritimati", "UTC"] {
            NSTimeZone.default = TimeZone(identifier: id)!
            XCTAssertEqual(StepsDayKeys.adding(1, to: "2026-03-08"), "2026-03-09", id)
            XCTAssertEqual(StepsDayKeys.window(endingOn: "2026-11-02", count: 3),
                           ["2026-10-31", "2026-11-01", "2026-11-02"], id)
        }
    }

    func testWindowIsOldestFirstAndInclusive() {
        XCTAssertEqual(StepsDayKeys.window(endingOn: "2026-09-30", count: 7),
                       ["2026-09-24", "2026-09-25", "2026-09-26", "2026-09-27",
                        "2026-09-28", "2026-09-29", "2026-09-30"])
        XCTAssertEqual(StepsDayKeys.window(endingOn: "2026-09-30", count: 0), [])
        XCTAssertEqual(StepsDayKeys.window(endingOn: "junk", count: 3), [])
    }

    func testUtcMidnightIsMidnightUTC() {
        let d = StepsDayKeys.utcMidnight("2026-09-30")
        XCTAssertEqual(d.map { Int($0.timeIntervalSince1970) }, 1_790_726_400)
        XCTAssertNil(StepsDayKeys.utcMidnight("2026-13-01"))
    }

    // MARK: Goal

    func testGoalIsClampedToItsRange() {
        XCTAssertEqual(StepGoal.defaultGoal, 10_000)
        XCTAssertEqual(StepGoal.range, 1_000...30_000)
        XCTAssertEqual(StepGoal.clamp(0), 1_000)
        XCTAssertEqual(StepGoal.clamp(-4), 1_000)
        XCTAssertEqual(StepGoal.clamp(12_500), 12_500)
        XCTAssertEqual(StepGoal.clamp(99_999), 30_000)
    }

    func testProgressPercentRemainingAndRing() {
        XCTAssertEqual(StepGoal.progress(steps: 7_500, goal: 10_000), 0.75, accuracy: 1e-9)
        XCTAssertEqual(StepGoal.progress(steps: 12_500, goal: 10_000), 1.25, accuracy: 1e-9)
        XCTAssertEqual(StepGoal.progress(steps: -10, goal: 10_000), 0)
        XCTAssertEqual(StepGoal.ringFraction(steps: 12_500, goal: 10_000), 1)
        XCTAssertEqual(StepGoal.ringFraction(steps: 2_500, goal: 10_000), 0.25, accuracy: 1e-9)
        // Rounded down: one step short of the goal is 99%, never 100%.
        XCTAssertEqual(StepGoal.percent(steps: 9_999, goal: 10_000), 99)
        XCTAssertEqual(StepGoal.percent(steps: 10_000, goal: 10_000), 100)
        XCTAssertEqual(StepGoal.remaining(steps: 7_250, goal: 10_000), 2_750)
        XCTAssertEqual(StepGoal.remaining(steps: 11_000, goal: 10_000), 0)
        // An out-of-range goal is judged against its clamped value.
        XCTAssertTrue(StepGoal.isMet(steps: 1_000, goal: 10))
        XCTAssertEqual(StepGoal.progress(steps: 15_000, goal: 60_000), 0.5, accuracy: 1e-9)
    }

    func testNotificationFiresOncePerDayOnlyWhenEnabledAndMet() {
        XCTAssertTrue(StepGoal.shouldNotify(enabled: true, steps: 10_000, goal: 10_000,
                                            lastNotifiedDay: "2026-09-29", today: "2026-09-30"))
        XCTAssertTrue(StepGoal.shouldNotify(enabled: true, steps: 10_001, goal: 10_000,
                                            lastNotifiedDay: nil, today: "2026-09-30"))
        // Already posted today.
        XCTAssertFalse(StepGoal.shouldNotify(enabled: true, steps: 20_000, goal: 10_000,
                                             lastNotifiedDay: "2026-09-30", today: "2026-09-30"))
        // Off by default, short of the goal, or no count at all.
        XCTAssertFalse(StepGoal.shouldNotify(enabled: false, steps: 20_000, goal: 10_000,
                                             lastNotifiedDay: nil, today: "2026-09-30"))
        XCTAssertFalse(StepGoal.shouldNotify(enabled: true, steps: 9_999, goal: 10_000,
                                             lastNotifiedDay: nil, today: "2026-09-30"))
        XCTAssertFalse(StepGoal.shouldNotify(enabled: true, steps: nil, goal: 10_000,
                                             lastNotifiedDay: nil, today: "2026-09-30"))
    }

    // MARK: Averages

    func testAverageCountsOnlyObservedDaysInTheCalendarWindow() {
        let readings: [(day: String, value: Double)] = [
            ("2026-09-23", 50_000),   // just outside a 7-day window ending the 30th
            ("2026-09-24", 6_000),
            ("2026-09-27", 0),        // a recorded zero counts
            ("2026-09-30", 9_000),
            ("2026-10-01", 50_000),   // after the window
        ]
        let avg = StepsStats.average(readings: readings, endingOn: "2026-09-30", days: 7)
        XCTAssertEqual(avg.observedDays, 3)
        XCTAssertEqual(avg.mean ?? -1, 5_000, accuracy: 1e-9)
    }

    func testAverageDropsInvalidReadingsAndKeepsTheLastDuplicate() {
        let readings: [(day: String, value: Double)] = [
            ("2026-09-28", -1), ("2026-09-28", .nan), ("2026-09-29", .infinity),
            ("2026-09-30", 2_000), ("2026-09-30", 3_000),
        ]
        let avg = StepsStats.average(readings: readings, endingOn: "2026-09-30", days: 30)
        XCTAssertEqual(avg, StepsAverage(mean: 3_000, observedDays: 1))
    }

    func testAverageOfNothingIsNil() {
        XCTAssertEqual(StepsStats.average(readings: [], endingOn: "2026-09-30", days: 30),
                       StepsAverage(mean: nil, observedDays: 0))
        XCTAssertEqual(StepsStats.average(readings: [("2026-09-30", 5)], endingOn: "2026-09-30", days: 0),
                       StepsAverage(mean: nil, observedDays: 0))
        XCTAssertEqual(StepsStats.average(readings: [("2026-09-30", 5)], endingOn: "nope", days: 7),
                       StepsAverage(mean: nil, observedDays: 0))
    }

    // MARK: Streaks and best day

    func testStreakCountsBackFromTodayOnceTodayIsMet() {
        let steps = ["2026-09-27": 10_500, "2026-09-28": 12_000, "2026-09-29": 10_000, "2026-09-30": 11_000]
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: steps, goal: 10_000, today: "2026-09-30"), 4)
    }

    func testTodayShortOfTheGoalNeitherCountsNorBreaksTheStreak() {
        let steps = ["2026-09-28": 12_000, "2026-09-29": 10_000, "2026-09-30": 1_200]
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: steps, goal: 10_000, today: "2026-09-30"), 2)
        // No reading yet today either.
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: ["2026-09-29": 10_000], goal: 10_000, today: "2026-09-30"), 1)
    }

    func testAMissedOrMissingDayEndsTheStreak() {
        let shortDay = ["2026-09-27": 15_000, "2026-09-28": 9_999, "2026-09-29": 10_000, "2026-09-30": 10_000]
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: shortDay, goal: 10_000, today: "2026-09-30"), 2)
        let gap = ["2026-09-27": 15_000, "2026-09-29": 10_000, "2026-09-30": 10_000]
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: gap, goal: 10_000, today: "2026-09-30"), 2)
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: [:], goal: 10_000, today: "2026-09-30"), 0)
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: ["2026-09-29": 500], goal: 10_000, today: "2026-09-30"), 0)
    }

    func testStreakUsesTheClampedGoal() {
        // A goal of 10 is really 1,000.
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: ["2026-09-30": 999], goal: 10, today: "2026-09-30"), 0)
        XCTAssertEqual(StepsStats.currentStreak(stepsByDay: ["2026-09-30": 1_000], goal: 10, today: "2026-09-30"), 1)
    }

    func testBestDayPrefersTheHighestThenTheMostRecent() {
        let days = [
            ResolvedStepDay(day: "2026-09-10", steps: 18_000, source: .phonePedometer),
            ResolvedStepDay(day: "2026-09-20", steps: 18_000, source: .healthKit),
            ResolvedStepDay(day: "2026-09-25", steps: 4_000, source: .strapEstimate),
        ]
        XCTAssertEqual(StepsStats.bestDay(days)?.day, "2026-09-20")
        XCTAssertNil(StepsStats.bestDay([]))
    }

    func testChartCeilingKeepsTheGoalLineAndTallestBarOnTheChart() {
        XCTAssertEqual(StepsStats.chartCeiling(values: [3_000, 4_000], goal: 10_000), 10_800)
        XCTAssertEqual(StepsStats.chartCeiling(values: [3_000, 20_000], goal: 10_000), 21_600)
        XCTAssertEqual(StepsStats.chartCeiling(values: [], goal: 8_000), 8_640)
    }
}
