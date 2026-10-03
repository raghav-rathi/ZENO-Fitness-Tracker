import XCTest
@testable import StrandAnalytics

final class PulseDayStreakTests: XCTestCase {

    // 2026-10-01 is a Thursday.
    private let today = "2026-10-01"

    private func keys(from start: String, count: Int) -> [String] {
        (0..<count).compactMap { PulseDisplay.dayKey(start, offsetBy: $0) }
    }

    // MARK: Tiers

    func testTierCutOffsMatchTheFlameColours() {
        XCTAssertEqual(PulseDayStreak.tier(days: 0), .spark)
        XCTAssertEqual(PulseDayStreak.tier(days: 1), .spark)
        XCTAssertEqual(PulseDayStreak.tier(days: 99), .spark)
        XCTAssertEqual(PulseDayStreak.tier(days: 100), .flame)
        XCTAssertEqual(PulseDayStreak.tier(days: 179), .flame)
        XCTAssertEqual(PulseDayStreak.tier(days: 180), .blaze)
        XCTAssertEqual(PulseDayStreak.tier(days: 364), .blaze)
        XCTAssertEqual(PulseDayStreak.tier(days: 365), .inferno)
        XCTAssertEqual(PulseDayStreak.tier(days: 999), .inferno)
        XCTAssertEqual(PulseDayStreak.tier(days: 1000), .legend)
        XCTAssertEqual(PulseDayStreak.tier(days: 1999), .legend)
        XCTAssertEqual(PulseDayStreak.tier(days: 2000), .legacy)
    }

    // MARK: Milestones

    func testMilestonesSeenOnWhoopCaptures() {
        // 1 → 7 (a one-day streak), 100 → 180 (101), 1300 → 1350 (1337), 2000 → 2050.
        XCTAssertEqual(PulseDayStreak.milestoneProgress(days: 1), .init(last: 1, next: 7, days: 1))
        XCTAssertEqual(PulseDayStreak.milestoneProgress(days: 101), .init(last: 100, next: 180, days: 101))
        XCTAssertEqual(PulseDayStreak.milestoneProgress(days: 1337), .init(last: 1300, next: 1350, days: 1337))
        XCTAssertEqual(PulseDayStreak.milestoneProgress(days: 2000), .init(last: 2000, next: 2050, days: 2000))
    }

    func testRemainingAndFractionSpanLastToNext() {
        let p = PulseDayStreak.milestoneProgress(days: 101)
        XCTAssertEqual(p.remaining, 79)                         // "79 more days" on the 101-day capture
        XCTAssertEqual(p.fraction, 1.0 / 80.0, accuracy: 1e-9)
        let none = PulseDayStreak.milestoneProgress(days: 0)
        XCTAssertNil(none.last)
        XCTAssertEqual(none.next, 1)
        XCTAssertEqual(none.fraction, 0)
    }

    func testEveryLadderRungIsItsOwnLastMilestone() {
        for rung in PulseDayStreak.ladder {
            XCTAssertEqual(PulseDayStreak.lastMilestone(atOrBelow: rung), rung)
        }
        XCTAssertEqual(PulseDayStreak.nextMilestone(after: 999), 1000)
        XCTAssertEqual(PulseDayStreak.nextMilestone(after: 1049), 1050)
        XCTAssertEqual(PulseDayStreak.lastMilestone(atOrBelow: 1049), 1000)
    }

    // MARK: Current run

    func testTheRunAgreesWithStreakCalculator() {
        let dayKeys = keys(from: "2026-09-01", count: 31)   // Sep 1 … Oct 1
        var qualified = Array(repeating: true, count: dayKeys.count)
        qualified[20] = false                               // Sep 21 missed
        let run = PulseDayStreak.currentRun(dayKeys: dayKeys, qualified: qualified, today: today)
        let calc = StreakCalculator.streaks(dayKeys: dayKeys, qualified: qualified, today: today)
        XCTAssertEqual(run?.length, calc.current)
        XCTAssertEqual(run?.startDay, "2026-09-22")
        XCTAssertEqual(run?.endDay, today)
    }

    func testTodayNotScoredYetKeepsYesterdaysRun() {
        let dayKeys = keys(from: "2026-09-25", count: 6)    // Sep 25 … Sep 30
        let run = PulseDayStreak.currentRun(dayKeys: dayKeys, qualified: Array(repeating: true, count: 6),
                                            today: today)
        XCTAssertEqual(run, .init(length: 6, startDay: "2026-09-25", endDay: "2026-09-30"))
    }

    func testNoRunAfterTwoMissedDays() {
        let dayKeys = keys(from: "2026-09-20", count: 10)   // ends Sep 29
        XCTAssertNil(PulseDayStreak.currentRun(dayKeys: dayKeys, qualified: Array(repeating: true, count: 10),
                                               today: today))
        XCTAssertNil(PulseDayStreak.currentRun(dayKeys: [], qualified: [], today: today))
        XCTAssertNil(PulseDayStreak.currentRun(dayKeys: dayKeys, qualified: [true], today: "not-a-day"))
    }

    func testARunCrossesMonthAndYearEnds() {
        let dayKeys = keys(from: "2025-12-30", count: 5)    // Dec 30 … Jan 3
        let run = PulseDayStreak.currentRun(dayKeys: dayKeys, qualified: Array(repeating: true, count: 5),
                                            today: "2026-01-03")
        XCTAssertEqual(run, .init(length: 5, startDay: "2025-12-30", endDay: "2026-01-03"))
    }

    // MARK: This week

    func testTheWeekRunsMondayToSundayWithAStatePerDay() {
        // Mon Sep 28 kept, Tue Sep 29 missed, Wed Sep 30 kept, Thu Oct 1 (today) not scored yet.
        let week = PulseDayStreak.week(dayKeys: ["2026-09-28", "2026-09-29", "2026-09-30"],
                                       qualified: [true, false, true], today: today, firstDay: "2026-09-01")
        XCTAssertEqual(week.map(\.day), ["2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01",
                                         "2026-10-02", "2026-10-03", "2026-10-04"])
        XCTAssertEqual(week.map(\.weekday), [1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(week.map(\.state), [.kept, .missed, .kept, .pending, .upcoming, .upcoming, .upcoming])
        XCTAssertEqual(week.map(\.isToday), [false, false, false, true, false, false, false])
    }

    func testASundayTodayEndsItsOwnWeek() {
        let week = PulseDayStreak.week(dayKeys: ["2026-10-04"], qualified: [true], today: "2026-10-04",
                                       firstDay: "2026-09-01")
        XCTAssertEqual(week.first?.day, "2026-09-28")
        XCTAssertEqual(week.last?.day, "2026-10-04")
        XCTAssertEqual(week.last?.state, .kept)
        XCTAssertTrue(week.last?.isToday ?? false)
    }

    func testAMalformedTodayHasNoWeek() {
        XCTAssertTrue(PulseDayStreak.week(dayKeys: [], qualified: [], today: "2026-13-40", firstDay: nil).isEmpty)
    }

    func testDaysBeforeAMidWeekStartAreNeitherKeptNorMissed() {
        // History starts on Tuesday Sep 29 (a missed Tuesday, a kept Wednesday); today is Thursday Oct 1.
        // Monday came before the first recorded day: no streak existed to miss.
        let week = PulseDayStreak.week(dayKeys: ["2026-09-29", "2026-09-30"], qualified: [false, true],
                                       today: today, firstDay: "2026-09-29")
        XCTAssertEqual(week.map(\.state), [.beforeStart, .missed, .kept, .pending, .upcoming, .upcoming, .upcoming])
    }

    func testAFridayStartLeavesMondayToThursdayNeutral() {
        // A member whose first day is Friday Oct 2, looking on Saturday Oct 3 with Friday scored.
        let week = PulseDayStreak.week(dayKeys: ["2026-10-02"], qualified: [true], today: "2026-10-03",
                                       firstDay: "2026-10-02")
        XCTAssertEqual(week.map(\.state), [.beforeStart, .beforeStart, .beforeStart, .beforeStart,
                                           .kept, .pending, .upcoming])
    }

    func testNothingRecordedYetMissesNothing() {
        let week = PulseDayStreak.week(dayKeys: [], qualified: [], today: today, firstDay: nil)
        XCTAssertEqual(week.map(\.state), [.beforeStart, .beforeStart, .beforeStart, .pending,
                                           .upcoming, .upcoming, .upcoming])
    }

    // MARK: Unlocks

    func testAFirstLookIsABaselineNotAnUnlock() {
        XCTAssertNil(PulseDayStreak.newMilestone(days: 120, acknowledged: nil))
    }

    func testANewMilestoneIsAnnouncedOnce() {
        XCTAssertEqual(PulseDayStreak.newMilestone(days: 100, acknowledged: 60), 100)
        XCTAssertNil(PulseDayStreak.newMilestone(days: 101, acknowledged: 100))
        XCTAssertNil(PulseDayStreak.newMilestone(days: 0, acknowledged: 100))
    }
}
