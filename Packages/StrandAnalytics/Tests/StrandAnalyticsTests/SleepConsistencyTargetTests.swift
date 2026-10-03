import XCTest
@testable import StrandAnalytics

final class SleepConsistencyTargetTests: XCTestCase {

    private func night(_ day: String, bed: Double, wake: Double) -> SleepConsistency.NightTiming {
        SleepConsistency.NightTiming(day: day, bedMinute: bed, wakeMinute: wake)
    }

    func testTheTargetIsTheMedianBedAndWakeOfThePriorNights() {
        let t = SleepConsistencyTarget.target(prior: [(1_380, 420), (1_390, 435), (1_370, 410)])
        XCTAssertEqual(t, SleepConsistencyTarget.Target(bedMinute: 1_380, wakeMinute: 420))
    }

    func testBedTimesAroundMidnightAreMinutesApartNotHours() {
        // 23:50, 00:10, 00:20: the median is 00:10, not some time in the afternoon.
        XCTAssertEqual(SleepConsistencyTarget.circularMedianMinute([1_430, 10, 20]) ?? -1, 10, accuracy: 1e-9)
        // An even count takes the middle two: 23:00 … 00:00 → 23:30.
        XCTAssertEqual(SleepConsistencyTarget.circularMedianMinute([1_380, 1_400, 1_420, 0]) ?? -1, 1_410,
                       accuracy: 1e-9)
        XCTAssertNil(SleepConsistencyTarget.circularMedianMinute([]))
    }

    func testThereIsNoTargetWhereThereIsNoScore() {
        XCTAssertNil(SleepConsistencyTarget.target(prior: [(1_380, 420), (1_390, 430)]))
        XCTAssertNil(SleepConsistency.score(bedMinute: 1_380, wakeMinute: 420, prior: [(1_380, 420), (1_390, 430)]))
    }

    func testNoOtherTimesScoreHigherThanTheTarget() {
        let prior: [(bedMinute: Double, wakeMinute: Double)] = [(1_350, 400), (5, 455), (1_410, 380), (1_425, 470)]
        guard let t = SleepConsistencyTarget.target(prior: prior),
              let best = SleepConsistency.score(bedMinute: t.bedMinute, wakeMinute: t.wakeMinute, prior: prior)
        else { return XCTFail("four prior nights make a target and a score") }
        // Every bed and wake time within three hours either side, on a five-minute grid.
        for db in stride(from: -180.0, through: 180, by: 5) {
            for dw in stride(from: -180.0, through: 180, by: 5) {
                let bed = SleepConsistencyTarget.wrap(t.bedMinute + db)
                let wake = SleepConsistencyTarget.wrap(t.wakeMinute + dw)
                let s = SleepConsistency.score(bedMinute: bed, wakeMinute: wake, prior: prior) ?? -1
                XCTAssertLessThanOrEqual(s, best + 1e-9, "bed \(bed) wake \(wake) beat the target")
            }
        }
    }

    func testOnlyTheLatestFourPriorNightsCount() {
        let t = SleepConsistencyTarget.target(prior: [(600, 900), (1_380, 420), (1_380, 420), (1_390, 430),
                                                      (1_370, 410)])
        XCTAssertEqual(t, SleepConsistencyTarget.Target(bedMinute: 1_380, wakeMinute: 420))
    }

    func testEveryNightIsComparedWithTheCalendarNightsBeforeIt() {
        let nights = [
            night("2026-09-20", bed: 1_380, wake: 420),
            night("2026-09-21", bed: 1_390, wake: 430),
            night("2026-09-22", bed: 1_370, wake: 410),
            // 09-23 missing: the night of the 24th still has three of its four prior calendar nights.
            night("2026-09-24", bed: 60, wake: 540),
            night("2026-09-27", bed: 1_380, wake: 420),
        ]
        let targets = SleepConsistencyTarget.targets(nights)
        XCTAssertEqual(targets["2026-09-24"], SleepConsistencyTarget.Target(bedMinute: 1_380, wakeMinute: 420))
        XCTAssertNil(targets["2026-09-27"], "only one of its four prior nights exists")
        XCTAssertNil(targets["2026-09-20"])
        // Keys match the nights the score itself can score.
        XCTAssertEqual(Set(targets.keys), Set(SleepConsistency.scores(nights).keys))
    }

    func testTonightsProjectionIsTheScoreAgainstTheSameNeighbours() {
        let nights = [
            night("2026-09-27", bed: 1_380, wake: 420),
            night("2026-09-28", bed: 1_385, wake: 425),
            night("2026-09-29", bed: 1_375, wake: 415),
            night("2026-09-30", bed: 1_390, wake: 430),
        ]
        let target = SleepConsistencyTarget.target(forNightEnding: "2026-10-01", nights: nights)
        XCTAssertNotNil(target)
        let onTarget = SleepConsistencyTarget.projectedScore(bedMinute: target?.bedMinute ?? 0,
                                                             wakeMinute: target?.wakeMinute ?? 0,
                                                             forNightEnding: "2026-10-01", nights: nights)
        XCTAssertEqual(onTarget, 1, "on the target, every deviation is inside the grace")
        let late = SleepConsistencyTarget.projectedScore(bedMinute: 120, wakeMinute: 600,
                                                         forNightEnding: "2026-10-01", nights: nights)
        let scored = SleepConsistency.scores(nights + [night("2026-10-01", bed: 120, wake: 600)])
        XCTAssertEqual(late, scored["2026-10-01"])
        XCTAssertLessThan(late ?? 1, 0.5)
    }
}
