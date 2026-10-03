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
