import XCTest
@testable import StrandAnalytics

final class AutoBehaviorsTests: XCTestCase {

    func testAtLeastSplitsByThreshold() {
        let a = AutoBehaviors.atLeast(85, valueByDay: ["2026-10-01": 91, "2026-10-02": 85, "2026-10-03": 84.9,
                                                       "2026-10-04": .nan])
        XCTAssertEqual(a.yes, ["2026-10-01", "2026-10-02"])
        XCTAssertEqual(a.no, ["2026-10-03"])
    }

    func testPreviousDayStrainLandsOnTheNextMorning() {
        let a = AutoBehaviors.previousDayAtLeast(10, valueByDay: ["2026-02-28": 14.2, "2026-03-01": 6.1])
        XCTAssertEqual(a.yes, ["2026-03-01"])
        XCTAssertEqual(a.no, ["2026-03-02"])
    }

    func testLateWorkoutIsWithinThreeHoursBeforeOnset() {
        let onset = 1_790_000_000
        let nights = [
            AutoBehaviors.Night(day: "2026-10-01", onsetTs: onset, bedMinute: 1380, wakeMinute: 420),
            AutoBehaviors.Night(day: "2026-10-02", onsetTs: onset + 86_400, bedMinute: 1380, wakeMinute: 420),
            AutoBehaviors.Night(day: "2026-10-03", onsetTs: onset + 2 * 86_400, bedMinute: 1380, wakeMinute: 420),
        ]
        let ends = [onset - 2 * 3_600,                    // 2 h before night 1: late
                    onset + 86_400 - 4 * 3_600,           // 4 h before night 2: not late
                    onset + 2 * 86_400 + 600]             // after night 3's onset: not before bed
        let a = AutoBehaviors.lateWorkout(nights: nights, workoutEnds: ends)
        XCTAssertEqual(a.yes, ["2026-10-01"])
        XCTAssertEqual(a.no, ["2026-10-02", "2026-10-03"])
    }

    func testConsistentWakeTimeNeedsEnoughPriorNights() {
        var wake: [String: Double] = [:]
        let keys = PulseDisplay.trailingDayKeys(endingOn: "2026-10-16", count: 16)
        for k in keys { wake[k] = 420 }                   // 07:00 every morning…
        wake["2026-10-15"] = 440                          // …07:20: within 30 min
        wake["2026-10-16"] = 540                          // …09:00: not
        let a = AutoBehaviors.consistent(minuteByDay: wake)
        XCTAssertTrue(a.yes.contains("2026-10-15"))
        XCTAssertTrue(a.no.contains("2026-10-16"))
        // The first five mornings have fewer than five nights before them: not judged.
        for k in keys.prefix(5) {
            XCTAssertFalse(a.yes.contains(k) || a.no.contains(k), k)
        }
        XCTAssertTrue(a.yes.contains(keys[5]))
    }

    func testConsistentBedTimeWrapsAroundMidnight() {
        var bed: [String: Double] = [:]
        let keys = PulseDisplay.trailingDayKeys(endingOn: "2026-10-10", count: 10)
        for k in keys { bed[k] = 10 }                     // 00:10
        bed["2026-10-10"] = 1430                          // 23:50 is 20 minutes away, not 23 h 40
        let a = AutoBehaviors.consistent(minuteByDay: bed)
        XCTAssertTrue(a.yes.contains("2026-10-10"))
    }
}
