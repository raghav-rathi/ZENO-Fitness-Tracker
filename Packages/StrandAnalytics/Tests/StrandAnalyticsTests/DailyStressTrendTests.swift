import XCTest
@testable import StrandAnalytics

/// The daily stress proxy scores each day against the 30 calendar days before IT, never today's baseline.
final class DailyStressTrendTests: XCTestCase {

    private func key(_ i: Int) -> String {
        LocalCalendarDate(year: 2026, month: 1, day: 1).adding(days: i).key
    }

    /// A slightly varying resting HR around `rhr` and HRV around `hrv`.
    private func day(_ i: Int, rhr: Double?, hrv: Double?) -> DailyStressTrend.Day {
        let wobble = Double(i % 3) - 1   // -1, 0, +1
        return DailyStressTrend.Day(day: key(i), restingHR: rhr.map { $0 + wobble },
                                    hrv: hrv.map { $0 - 2 * wobble })
    }

    func testNeedsSevenPriorDaysPerSignal() {
        let days = (0..<8).map { day($0, rhr: 55, hrv: 60) }
        let scores = DailyStressTrend.scores(days)
        XCTAssertNil(scores[key(6)], "six prior days are not a baseline")
        XCTAssertNotNil(scores[key(7)], "seven are")
    }

    func testAPastDayIsScoredAgainstItsOwnPastNotToday() throws {
        // Forty calm days at RHR ~50, then forty at ~65. Day 34 sits exactly at its own baseline, so it reads
        // 1.5 — today's baseline (~65) would have called it extremely calm.
        let days = (0..<40).map { day($0, rhr: 50, hrv: 70) } + (40..<80).map { day($0, rhr: 65, hrv: 45) }
        let scores = DailyStressTrend.scores(days)
        let past = try XCTUnwrap(scores[key(34)])
        XCTAssertEqual(past.score, 1.5, accuracy: 1e-9)
        // And the first days of the new regime read as stressed against the calm month before them.
        XCTAssertGreaterThan(try XCTUnwrap(scores[key(41)]).score, 2.5)
    }

    func testAnOldDayDoesNotMoveWhenNewDaysLand() {
        let early = (0..<30).map { day($0, rhr: 55, hrv: 60) }
        let later = early + (30..<60).map { day($0, rhr: 75, hrv: 30) }
        let a = DailyStressTrend.scores(early), b = DailyStressTrend.scores(later)
        for i in 7..<30 { XCTAssertEqual(a[key(i)], b[key(i)], "day \(i)") }
    }

    func testScoreUsesTheSampleSDOfThePriorWindow() throws {
        // Seven prior resting HRs with mean 55 and a known sample SD; no HRV.
        let prior: [Double] = [52, 53, 54, 55, 56, 57, 58]
        let sd = (prior.map { ($0 - 55) * ($0 - 55) }.reduce(0, +) / 6).squareRoot()
        let s = try XCTUnwrap(DailyStressTrend.score(day: .init(day: "d", restingHR: 60, hrv: nil),
                                                     priorRHR: prior, priorHRV: []))
        XCTAssertEqual(s.score, 3 / (1 + exp(-(5 / sd))), accuracy: 1e-12)
        XCTAssertEqual(s.rhrDelta, 5)
        XCTAssertNil(s.hrvDelta)
    }

    func testAFlatBaselineReadsAtBaseline() throws {
        let s = try XCTUnwrap(DailyStressTrend.score(day: .init(day: "d", restingHR: 60, hrv: nil),
                                                     priorRHR: Array(repeating: 55, count: 10), priorHRV: []))
        XCTAssertEqual(s.score, 1.5, "no spread cannot z-score; the signal reads at baseline")
    }

    func testTheWindowIsCalendarDays() {
        // Thirty days, a 40-day gap, then one more day: nothing lies in its 30-day window.
        let days = (0..<30).map { day($0, rhr: 55, hrv: 60) } + [day(70, rhr: 55, hrv: 60)]
        XCTAssertNil(DailyStressTrend.scores(days)[key(70)])
    }

    func testADayWithoutEitherSignalHasNoScore() {
        let days = (0..<10).map { day($0, rhr: 55, hrv: 60) } + [day(10, rhr: nil, hrv: nil)]
        XCTAssertNil(DailyStressTrend.scores(days)[key(10)])
    }
}
