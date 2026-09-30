import XCTest
import WhoopStore
@testable import StrandAnalytics

/// Readiness's ACWR and Foster monotony, and the CTL/ATL model, run on LINEAR load (the TRIMP each
/// day's Effort stands for), not on the log-scaled Effort score.
final class LinearTrainingLoadTests: XCTestCase {

    private func day(_ i: Int, effort: Double?, hrv: Double = 60, rhr: Int = 52) -> DailyMetric {
        DailyMetric(day: LocalCalendarDate(year: 2026, month: 3, day: 1).adding(days: i - 1).key,
                    totalSleepMin: nil, efficiency: nil, deepMin: nil, remMin: nil, lightMin: nil,
                    disturbances: nil, restingHr: rhr, avgHrv: hrv, recovery: nil, strain: effort,
                    exerciseCount: nil, spo2Pct: nil, skinTempDevC: nil, respRateBpm: nil)
    }

    // MARK: The inverse map

    func testTrimpInvertsTheEffortMap() {
        for effort in stride(from: 0.0, through: 100.0, by: 2.5) {
            let trimp = StrainScorer.trimp(fromStrain: effort)
            XCTAssertEqual(StrainScorer.trimpToStrain(trimp), effort, accuracy: 0.006, "Effort \(effort)")
        }
        XCTAssertEqual(StrainScorer.trimp(fromStrain: 0), 0)
        XCTAssertEqual(StrainScorer.trimp(fromStrain: 100), StrainScorer.strainDenominator - 1, accuracy: 1e-6)
        XCTAssertEqual(StrainScorer.trimp(fromStrain: -5), 0, "clamped")
        XCTAssertEqual(StrainScorer.trimp(fromStrain: .nan), 0)
        XCTAssertEqual(StrainScorer.trimp(fromStrain: 50, denominator: 1), 0, "outside the map's domain")
    }

    func testLinearLoadRestoresTheGapBetweenEasyAndHardDays() {
        // 25 vs 60 is 2.4x on the Effort axis and roughly 25x in load.
        let ratio = ReadinessEngine.dailyLoad(effort: 60) / ReadinessEngine.dailyLoad(effort: 25)
        XCTAssertGreaterThan(ratio, 20)
    }

    // MARK: Monotony and "Primed"

    /// A normal training week: rest days in the 20s–30s, sessions near 60.
    private let variedWeek: [Double] = [25, 60, 30, 58, 25, 62, 35]

    func testAVariedWeekIsNotMonotonousAndPrimedIsReachable() throws {
        var days = (1...28).map { i in
            day(i, effort: variedWeek[(i - 1) % 7], hrv: i % 2 == 0 ? 62 : 58, rhr: i % 2 == 0 ? 54 : 50)
        }
        // Today continues the same weekly pattern with HRV up and resting HR down.
        days.append(day(29, effort: variedWeek[28 % 7], hrv: 72, rhr: 46))
        let r = ReadinessEngine.evaluate(days: days)

        let monotony = try XCTUnwrap(r.monotony)
        XCTAssertLessThan(monotony, 2, "a mixed week is not monotonous on a linear load")
        // The same week on the log-scaled Effort axis reads as monotonous — the bug being fixed.
        let week = Array(days.suffix(7)).compactMap(\.strain)
        XCTAssertGreaterThanOrEqual(ReadinessEngine.mean(week)! / ReadinessEngine.sampleSD(week)!, 2)

        XCTAssertNil(r.signals.first { $0.key == "monotony" })
        XCTAssertEqual(r.signals.first { $0.key == "acwr" }?.flag, .good)
        XCTAssertEqual(r.level, .primed)
    }

    func testAMonotonousWeekStillFlags() throws {
        let sameish: [Double] = [50, 52, 49, 51, 50, 53, 50]
        var days = (1...28).map { i in day(i, effort: sameish[(i - 1) % 7], hrv: i % 2 == 0 ? 62 : 58,
                                           rhr: i % 2 == 0 ? 54 : 50) }
        days.append(day(29, effort: sameish[28 % 7], hrv: 72, rhr: 46))
        let r = ReadinessEngine.evaluate(days: days)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(r.monotony), 2)
        XCTAssertEqual(r.signals.first { $0.key == "monotony" }?.flag, .watch)
        XCTAssertNotEqual(r.level, .primed, "a watch flag still blocks Primed")
    }

    // MARK: Calendar windows

    func testWindowsAreCalendarDaysEndingOnTheScoredDay() {
        // 10 old days, a 20-day gap, then 5 recent days: the acute window holds only the recent days, and
        // the last 28 calendar days hold too few observed days for an ACWR. Counting the last N ROWS, as
        // before, would have reached back across the gap and produced one.
        var days = (1...10).map { day($0, effort: 40) }
        days += (31...35).map { day($0, effort: 60) }
        let windows = ReadinessEngine.trainingLoadWindows(days, endingOn: days.last!.day)
        XCTAssertEqual(windows.acute.count, 5)
        XCTAssertEqual(windows.chronic.count, 3 + 5, "only days 8–10 and 31–35 fall inside 28 calendar days")
        XCTAssertNil(ReadinessEngine.evaluate(days: days).acwr, "fewer than 14 observed days in the window")
    }

    func testADayWithoutEffortIsMissingNotAZeroLoad() {
        var days = (1...29).map { day($0, effort: 40) }
        days[27] = day(28, effort: nil)
        let windows = ReadinessEngine.trainingLoadWindows(days, endingOn: days.last!.day)
        XCTAssertEqual(windows.acute.count, 6)
        XCTAssertFalse(windows.acute.contains(0))
    }

    func testRowsAfterTheScoredDayNeverCount() {
        let days = (1...40).map { day($0, effort: $0 > 29 ? 90 : 40) }
        let r = ReadinessEngine.evaluate(days: days, today: days[28].day)
        XCTAssertEqual(r.acwr ?? -1, 1, accuracy: 1e-9)
    }

    // MARK: CTL / ATL

    func testTrainingLoadModelRunsOnTheSameLinearLoad() {
        let days = (1...28).map { day($0, effort: 40) }
        let loads = ReadinessEngine.trainingLoadDays(days)
        XCTAssertEqual(loads.first?.load ?? -1, ReadinessEngine.dailyLoad(effort: 40), accuracy: 1e-9)
        let tl = ReadinessEngine.evaluateWithTrainingLoad(days: days).trainingLoad
        XCTAssertEqual(tl.ctl ?? -1, ReadinessEngine.dailyLoad(effort: 40), accuracy: 1e-9,
                       "a constant load settles at that load")
        XCTAssertNil(ReadinessEngine.trainingLoadDays([day(1, effort: nil)]).first?.load)
    }
}
