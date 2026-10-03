import XCTest
@testable import StrandAnalytics
import WhoopProtocol

final class StressDayTotalsTests: XCTestCase {

    /// One hour at local hour-of-day `hour` on a fixed day, with `level` (nil = unscored).
    private func hour(_ hour: Int, _ level: Double?, masked: Bool = false) -> DaytimeStress.HourPoint {
        DaytimeStress.HourPoint(hour: hour, startTs: 1_790_000_000 + hour * 3600, level: level,
                                meanHR: level == nil ? nil : 70, rmssd: nil, maskedForActivity: masked)
    }

    func testBandsMatchTheSharedScale() {
        XCTAssertEqual(StressDayTotals.Level(score: 0.0), .low)
        XCTAssertEqual(StressDayTotals.Level(score: 0.99), .low)
        XCTAssertEqual(StressDayTotals.Level(score: 1.0), .medium)
        XCTAssertEqual(StressDayTotals.Level(score: 1.99), .medium)
        XCTAssertEqual(StressDayTotals.Level(score: 2.0), .high)
        XCTAssertEqual(StressDayTotals.Level(score: 3.0), .high)
    }

    /// Every scored hour counts sixty minutes in its band; unscored and activity-masked hours count nowhere.
    func testTotalsCountScoredHoursOnly() {
        let day = [hour(6, 0.4), hour(7, 1.2), hour(8, nil), hour(9, nil, masked: true), hour(10, 2.4),
                   hour(11, 2.1), hour(12, 0.8)]
        let t = StressDayTotals.totals(day)
        XCTAssertEqual(t.lowMinutes, 120)
        XCTAssertEqual(t.mediumMinutes, 60)
        XCTAssertEqual(t.highMinutes, 120)
        XCTAssertEqual(t.scoredMinutes, 300)
        XCTAssertEqual(t.share(.high), 0.4, accuracy: 1e-12)
        XCTAssertEqual(t.dominant, .low)          // a tie with HIGH goes to the calmer band
        XCTAssertEqual(StressDayTotals.Totals.zero.dominant, nil)
        XCTAssertEqual(StressDayTotals.Totals.zero.share(.low), 0)
    }

    /// The HIGH total is the same figure `DaytimeStress` reports as `highStressMinutes`.
    func testHighMinutesAgreeWithTheEngine() {
        // Two hours of HR at a calm 60 bpm and one at 110: the day-relative read puts the busy hour high.
        var hr: [HRSample] = []
        // 08:00 UTC on a fixed day, inside the waking hours the engine scores.
        let start = 1_790_000_000 - (1_790_000_000 % 86_400) + 8 * 3600
        for i in 0..<3 * 3600 {
            let bpm = i >= 2 * 3600 ? 110 : (i % 2 == 0 ? 60 : 62)
            hr.append(HRSample(ts: start + i, bpm: bpm))
        }
        let result = DaytimeStress.analyze(hr: hr, rr: [], tzOffsetSeconds: 0)
        XCTAssertGreaterThan(result.highStressMinutes, 0)
        XCTAssertEqual(StressDayTotals.totals(result.hours).highMinutes, result.highStressMinutes)
    }

    func testTotalsCanStopAtAnHourOfTheDay() {
        let day = [hour(6, 0.4), hour(7, 1.2), hour(8, 2.5), hour(14, 2.5)]
        let morning = StressDayTotals.totals(day, beforeHour: 8)
        XCTAssertEqual(morning, StressDayTotals.Totals(lowMinutes: 60, mediumMinutes: 60, highMinutes: 0))
    }

    /// The typical day is the mean over worn days only, and needs at least two of them.
    func testTypicalAveragesWornDays() {
        let a = (6..<12).map { hour($0, $0 < 9 ? 0.5 : 1.5) }       // 3 h low, 3 h medium
        let b = (6..<12).map { hour($0, $0 < 10 ? 0.5 : 2.5) }      // 4 h low, 2 h high
        let barelyWorn = [hour(7, 2.8)]                              // 1 scored hour: not a day
        let t = StressDayTotals.typical([a, b, barelyWorn])!
        XCTAssertEqual(t.lowMinutes, 210)
        XCTAssertEqual(t.mediumMinutes, 90)
        XCTAssertEqual(t.highMinutes, 60)
        XCTAssertNil(StressDayTotals.typical([a, barelyWorn]))
        XCTAssertNil(StressDayTotals.typical([]))
    }

    func testTypicalCanStopAtAnHourOfTheDay() {
        let a = (6..<18).map { hour($0, $0 < 12 ? 0.5 : 2.5) }
        let b = (6..<18).map { hour($0, $0 < 12 ? 1.5 : 2.5) }
        let t = StressDayTotals.typical([a, b], beforeHour: 12)!
        XCTAssertEqual(t, StressDayTotals.Totals(lowMinutes: 180, mediumMinutes: 180, highMinutes: 0))
    }

    func testPercentChange() {
        XCTAssertEqual(StressDayTotals.percentChange(129, typical: 22), 486)
        XCTAssertEqual(StressDayTotals.percentChange(479, typical: 538), -11)
        XCTAssertEqual(StressDayTotals.percentChange(60, typical: 60), 0)
        XCTAssertNil(StressDayTotals.percentChange(40, typical: 0))
    }

    /// Run length counts back-to-back HIGH hours; a gap in the clock or a calmer hour ends a run.
    func testLongestHighRun() {
        let day = [hour(7, 2.2), hour(9, 2.5), hour(10, 2.9), hour(11, 1.1), hour(13, 2.1), hour(14, 2.0),
                   hour(15, 2.6)]
        let run = StressDayTotals.longestHighRun(day)!
        XCTAssertEqual(run.startTs, hour(13, nil).startTs)
        XCTAssertEqual(run.minutes, 180)
        // Out of order in, same answer out; ties go to the earliest run.
        let tie = [hour(10, 2.5), hour(9, 2.5), hour(14, 2.2), hour(15, 2.2)]
        XCTAssertEqual(StressDayTotals.longestHighRun(tie)?.startTs, hour(9, nil).startTs)
        XCTAssertNil(StressDayTotals.longestHighRun([hour(8, 1.5), hour(9, nil)]))
    }

    func testSameWeekdayKeys() {
        XCTAssertEqual(StressDayTotals.sameWeekdayKeys(before: "2026-10-02", weeks: 3),
                       ["2026-09-25", "2026-09-18", "2026-09-11"])
        XCTAssertEqual(StressDayTotals.sameWeekdayKeys(before: "2026-10-02", weeks: 0), [])
    }
}
