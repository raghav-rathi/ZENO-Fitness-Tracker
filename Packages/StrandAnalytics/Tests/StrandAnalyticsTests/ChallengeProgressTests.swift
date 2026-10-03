import XCTest
@testable import StrandAnalytics

final class ChallengeProgressTests: XCTestCase {

    private let allIn = ChallengeProgress.Definition(kind: .activityMinutes, target: 250, days: 7,
                                                     startDay: "2026-06-29")

    func testWindowRunsSevenDaysAcrossAMonthEnd() {
        XCTAssertEqual(allIn.endDay, "2026-07-05")
        XCTAssertEqual(allIn.dayKeys, ["2026-06-29", "2026-06-30", "2026-07-01", "2026-07-02", "2026-07-03",
                                       "2026-07-04", "2026-07-05"])
    }

    func testRunningShowsTheTotalAndTheDaysLeft() {
        // WHOOP's in-progress capture: 168 of 250 with 4 days left on Jul 2.
        let perDay = ["2026-06-29": 60.0, "2026-06-30": 42, "2026-07-01": 36, "2026-07-02": 30]
        let s = ChallengeProgress.status(allIn, perDay: perDay, today: "2026-07-02")
        XCTAssertEqual(s.logged, 168)
        XCTAssertEqual(s.phase, .running)
        XCTAssertEqual(s.daysLeft, 4)
        XCTAssertEqual(s.remaining, 82)
        XCTAssertNil(s.completedOn)
    }

    func testCompleteFromTheDayTheTargetFallsAndKeepsCounting() {
        let perDay = ["2026-06-29": 100.0, "2026-06-30": 100, "2026-07-01": 60, "2026-07-02": 200]
        let s = ChallengeProgress.status(allIn, perDay: perDay, today: "2026-07-02")
        XCTAssertEqual(s.phase, .complete)
        XCTAssertEqual(s.completedOn, "2026-07-01")
        XCTAssertEqual(s.logged, 460)
        XCTAssertEqual(s.fraction, 460.0 / 250, accuracy: 1e-9)
        XCTAssertEqual(s.daysLeft, 0)
    }

    func testDaysOutsideTheWindowOrAheadOfTodayDoNotCount() {
        let perDay = ["2026-06-28": 500.0, "2026-07-06": 500, "2026-07-03": 40, "2026-06-29": -20, "2026-06-30": 10]
        let s = ChallengeProgress.status(allIn, perDay: perDay, today: "2026-07-01")
        // Only Jun 29 (negative, ignored) and Jun 30 count: Jul 3 has not happened yet.
        XCTAssertEqual(s.logged, 10)
    }

    func testEndsShortWhenTheLastDayPasses() {
        let s = ChallengeProgress.status(allIn, perDay: ["2026-07-01": 100], today: "2026-07-06")
        XCTAssertEqual(s.phase, .ended)
        XCTAssertEqual(s.daysLeft, 0)
    }

    func testLastDayStillRunningWithOneDayLeft() {
        let s = ChallengeProgress.status(allIn, perDay: [:], today: "2026-07-05")
        XCTAssertEqual(s.phase, .running)
        XCTAssertEqual(s.daysLeft, 1)
    }

    func testUpcomingAndLeavingEarly() {
        let upcoming = ChallengeProgress.status(allIn, perDay: [:], today: "2026-06-28")
        XCTAssertEqual(upcoming.phase, .upcoming)
        XCTAssertEqual(upcoming.daysLeft, 7)

        let left = ChallengeProgress.status(allIn, perDay: ["2026-06-29": 30], today: "2026-07-01", endedEarly: true)
        XCTAssertEqual(left.phase, .ended)

        // Already won before leaving: it stays won.
        let won = ChallengeProgress.status(allIn, perDay: ["2026-06-29": 300], today: "2026-07-01", endedEarly: true)
        XCTAssertEqual(won.phase, .complete)
    }

    // MARK: Reachability (counted kinds)

    /// 7 nights on time in 7 days, from Sep 30.
    private let bedtime = ChallengeProgress.Definition(kind: .bedtime, target: 7, days: 7, startDay: "2026-09-30",
                                                       bedtimeMinute: 23 * 60)

    func testMissedNightsPutACountedTargetOutOfReach() {
        // The review's capture: two late nights, one on time, today Oct 3 with 4 days left. At most 1 + 4 = 5
        // of 7 nights can still be on time, so 7/7 is out of reach.
        let perDay = ["2026-09-30": 0.0, "2026-10-01": 0, "2026-10-02": 1]
        let s = ChallengeProgress.status(bedtime, perDay: perDay, today: "2026-10-03")
        XCTAssertEqual(s.phase, .running)
        XCTAssertEqual(s.logged, 1)
        XCTAssertEqual(s.daysLeft, 4)
        XCTAssertEqual(s.maxReachable, 5)
        XCTAssertEqual(s.openCount, 4)
        XCTAssertFalse(s.isReachable)
    }

    func testTonightCountsOnlyWhileItIsStillToBeJudged() {
        // A 5-of-7 target: Oct 3's night is open until it is judged.
        let five = ChallengeProgress.Definition(kind: .bedtime, target: 5, days: 7, startDay: "2026-09-30",
                                                bedtimeMinute: 23 * 60)
        let open = ChallengeProgress.status(five, perDay: ["2026-09-30": 0, "2026-10-01": 0, "2026-10-02": 1],
                                            today: "2026-10-03")
        XCTAssertEqual(open.maxReachable, 5)
        XCTAssertTrue(open.isReachable)
        // Judged late (an early-morning sync of a night keyed to today), it is gone.
        let judged = ChallengeProgress.status(five, perDay: ["2026-09-30": 0, "2026-10-01": 0, "2026-10-02": 1,
                                                             "2026-10-03": 0],
                                              today: "2026-10-03")
        XCTAssertEqual(judged.maxReachable, 4)
        XCTAssertFalse(judged.isReachable)
    }

    func testLastNightStaysOpenUntilItsSleepSyncs() {
        // Oct 3, nothing judged for Oct 2's night yet (it has not synced): it may still count.
        let s = ChallengeProgress.status(bedtime, perDay: ["2026-09-30": 1, "2026-10-01": 1], today: "2026-10-03")
        XCTAssertEqual(s.maxReachable, 7)
        XCTAssertTrue(s.isReachable)
        // An older night with nothing recorded is over: Sep 30 missing, two days later.
        let older = ChallengeProgress.status(bedtime, perDay: ["2026-10-01": 1], today: "2026-10-03")
        XCTAssertEqual(older.maxReachable, 6)
        XCTAssertFalse(older.isReachable)
    }

    func testReachabilityAtTheEdges() {
        let upcoming = ChallengeProgress.status(bedtime, perDay: [:], today: "2026-09-29")
        XCTAssertEqual(upcoming.maxReachable, 7)
        XCTAssertTrue(upcoming.isReachable)

        let won = ChallengeProgress.status(
            ChallengeProgress.Definition(kind: .bedtime, target: 2, days: 7, startDay: "2026-09-30"),
            perDay: ["2026-09-30": 1, "2026-10-01": 1], today: "2026-10-03")
        XCTAssertEqual(won.phase, .complete)
        XCTAssertTrue(won.isReachable)

        let ended = ChallengeProgress.status(bedtime, perDay: ["2026-10-01": 1], today: "2026-10-08")
        XCTAssertEqual(ended.phase, .ended)
        XCTAssertEqual(ended.maxReachable, 1)
        XCTAssertFalse(ended.isReachable)

        // Summed kinds have no ceiling.
        let minutes = ChallengeProgress.status(allIn, perDay: ["2026-06-29": 1], today: "2026-07-05")
        XCTAssertNil(minutes.maxReachable)
        XCTAssertNil(minutes.openCount)
        XCTAssertTrue(minutes.isReachable)
    }

    func testBedtimeReadsAfterMidnightAsLate() {
        let eleven = 23 * 60
        XCTAssertTrue(ChallengeProgress.isInBedBy(onsetMinute: 22 * 60 + 45, target: eleven))
        XCTAssertTrue(ChallengeProgress.isInBedBy(onsetMinute: eleven, target: eleven))
        XCTAssertFalse(ChallengeProgress.isInBedBy(onsetMinute: 23 * 60 + 1, target: eleven))
        XCTAssertFalse(ChallengeProgress.isInBedBy(onsetMinute: 30, target: eleven))          // 00:30
        // A target after midnight.
        XCTAssertTrue(ChallengeProgress.isInBedBy(onsetMinute: 23 * 60 + 50, target: 30))
        XCTAssertTrue(ChallengeProgress.isInBedBy(onsetMinute: 15, target: 30))
        XCTAssertFalse(ChallengeProgress.isInBedBy(onsetMinute: 45, target: 30))
    }

    func testNightBelongsToTheEveningItBegan() {
        XCTAssertEqual(ChallengeProgress.nightKey(onsetDayKey: "2026-07-01", onsetMinute: 22 * 60 + 30), "2026-07-01")
        XCTAssertEqual(ChallengeProgress.nightKey(onsetDayKey: "2026-07-02", onsetMinute: 40), "2026-07-01")
        XCTAssertEqual(ChallengeProgress.nightKey(onsetDayKey: "2026-03-01", onsetMinute: 60), "2026-02-28")
    }

    func testSuggestionsAndClamping() {
        let s = ChallengeProgress.suggested(.bedtime, startDay: "2026-10-03")
        XCTAssertEqual(s.target, 7)
        XCTAssertEqual(s.bedtimeMinute, 23 * 60)
        XCTAssertEqual(ChallengeProgress.suggested(.activityMinutes, startDay: "2026-10-03").target, 250)
        let odd = ChallengeProgress.Definition(kind: .steps, target: 0, days: 0, startDay: "2026-10-03")
        XCTAssertEqual(odd.target, 1)
        XCTAssertEqual(odd.days, 1)
        XCTAssertEqual(odd.endDay, "2026-10-03")
    }

    func testDefinitionRoundTripsThroughJSON() throws {
        let d = ChallengeProgress.Definition(kind: .bedtime, target: 5, days: 7, startDay: "2026-10-03",
                                             bedtimeMinute: 1_380)
        let back = try JSONDecoder().decode(ChallengeProgress.Definition.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(back, d)
    }
}
