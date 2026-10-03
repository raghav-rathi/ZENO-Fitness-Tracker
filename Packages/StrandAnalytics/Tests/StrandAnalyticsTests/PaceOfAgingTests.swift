import XCTest
@testable import StrandAnalytics

final class PaceOfAgingTests: XCTestCase {

    // MARK: Helpers

    /// `count` weekly keys ending on `last`, oldest first.
    private func weekKeys(endingOn last: String, count: Int) -> [String] {
        (0..<count).reversed().compactMap { PulseDisplay.dayKey(last, offsetBy: -7 * $0) }
    }

    /// Weeks whose gap moves `gapPerYear` years per calendar year from `startGap`, at a fixed age.
    private func weeks(endingOn last: String, count: Int, startGap: Double, gapPerYear: Double,
                       age: Double = 40) -> [PaceOfAging.Week] {
        weekKeys(endingOn: last, count: count).enumerated().map { i, key in
            let years = Double(i * 7) / 365.2425
            return PaceOfAging.Week(day: key, bodyAge: age + startGap + gapPerYear * years, chronoAge: age)
        }
    }

    // MARK: The slope

    /// A ZENO Age that keeps a steady distance from the calendar ages at exactly 1.0x.
    func testSteadyGapIsOnePace() {
        let w = weeks(endingOn: "2026-09-26", count: 26, startGap: -3, gapPerYear: 0)
        XCTAssertEqual(PaceOfAging.pace(w, asOf: "2026-09-26")!, 1.0, accuracy: 1e-9)
    }

    /// A gap closing by a year every year means the ZENO Age is standing still: 0.0x.
    func testGapClosingOneYearPerYearIsZeroPace() {
        let w = weeks(endingOn: "2026-09-26", count: 26, startGap: 2, gapPerYear: -1)
        XCTAssertEqual(PaceOfAging.pace(w, asOf: "2026-09-26")!, 0.0, accuracy: 1e-9)
    }

    func testWideningGapIsFasterThanOne() {
        let w = weeks(endingOn: "2026-09-26", count: 20, startGap: 0, gapPerYear: 0.5)
        XCTAssertEqual(PaceOfAging.pace(w, asOf: "2026-09-26")!, 1.5, accuracy: 1e-9)
    }

    /// The fit is least squares, so week-to-week noise around a steady gap averages out.
    func testNoiseAroundASteadyGapStaysNearOne() {
        let noise = [0.3, -0.2, 0.1, -0.3, 0.2, 0.0, -0.1, 0.25, -0.25, 0.15, -0.15, 0.05, -0.05,
                     0.3, -0.2, 0.1, -0.3, 0.2, 0.0, -0.1, 0.25, -0.25, 0.15, -0.15, 0.05, -0.05]
        let w = weeks(endingOn: "2026-09-26", count: noise.count, startGap: -2, gapPerYear: 0)
            .enumerated().map { i, week in
                PaceOfAging.Week(day: week.day, bodyAge: week.bodyAge + noise[i], chronoAge: week.chronoAge)
            }
        let pace = PaceOfAging.pace(w, asOf: "2026-09-26")!
        XCTAssertEqual(pace, 1.0, accuracy: 0.5)
    }

    func testPaceIsClampedToTheRuler() {
        let fast = weeks(endingOn: "2026-09-26", count: 8, startGap: 0, gapPerYear: 10)
        XCTAssertEqual(PaceOfAging.pace(fast, asOf: "2026-09-26"), 3.0)
        let slow = weeks(endingOn: "2026-09-26", count: 8, startGap: 0, gapPerYear: -10)
        XCTAssertEqual(PaceOfAging.pace(slow, asOf: "2026-09-26"), -1.0)
    }

    // MARK: Honesty gates

    func testTooFewWeeksHasNoPace() {
        let w = weeks(endingOn: "2026-09-26", count: PaceOfAging.minWeeks - 1, startGap: 0, gapPerYear: 0)
        XCTAssertNil(PaceOfAging.pace(w, asOf: "2026-09-26"))
        let enough = weeks(endingOn: "2026-09-26", count: PaceOfAging.minWeeks, startGap: 0, gapPerYear: 0)
        XCTAssertNotNil(PaceOfAging.pace(enough, asOf: "2026-09-26"))
    }

    /// Four points crowded into a fortnight do not make a slope.
    func testTooShortASpanHasNoPace() {
        let crowded = ["2026-09-12", "2026-09-16", "2026-09-20", "2026-09-26"].map {
            PaceOfAging.Week(day: $0, bodyAge: 38, chronoAge: 40)
        }
        XCTAssertNil(PaceOfAging.pace(crowded, asOf: "2026-09-26"))
    }

    func testNoWeeksAndMalformedKeys() {
        XCTAssertNil(PaceOfAging.pace([], asOf: "2026-09-26"))
        XCTAssertNil(PaceOfAging.pace(weeks(endingOn: "2026-09-26", count: 8, startGap: 0, gapPerYear: 0),
                                      asOf: "not-a-day"))
        // A malformed week is skipped, not read as day zero.
        var w = weeks(endingOn: "2026-09-26", count: 8, startGap: 0, gapPerYear: 0)
        w.append(PaceOfAging.Week(day: "2026-13-40", bodyAge: 90, chronoAge: 40))
        XCTAssertEqual(PaceOfAging.pace(w, asOf: "2026-09-26")!, 1.0, accuracy: 1e-9)
    }

    // MARK: The window

    /// Only the last 6 months count: a steep stretch older than that does not move today's pace, and a
    /// week after the day asked about is not in its window.
    func testOnlyTheTrailingSixMonthsCount() {
        let old = weeks(endingOn: "2025-12-27", count: 20, startGap: 0, gapPerYear: 8)
        let recent = weeks(endingOn: "2026-09-26", count: 26, startGap: -1, gapPerYear: 0)
        XCTAssertEqual(PaceOfAging.pace(old + recent, asOf: "2026-09-26")!, 1.0, accuracy: 1e-9)

        let future = PaceOfAging.Week(day: "2026-10-03", bodyAge: 80, chronoAge: 40)
        XCTAssertEqual(PaceOfAging.pace(recent + [future], asOf: "2026-09-26")!, 1.0, accuracy: 1e-9)
    }

    func testWeeksInWindowCountsWhatTheFitSees() {
        let w = weeks(endingOn: "2026-09-26", count: 40, startGap: 0, gapPerYear: 0)
        // 182 days hold 26 weekly points.
        XCTAssertEqual(PaceOfAging.weeksInWindow(w, endingOn: "2026-09-26"), 26)
        XCTAssertEqual(PaceOfAging.weeksInWindow(w, endingOn: "garbage"), 0)
    }

    /// The input order and duplicated keys do not matter: one point per week, the last entry wins.
    func testOrderAndDuplicates() {
        let w = weeks(endingOn: "2026-09-26", count: 12, startGap: 1, gapPerYear: -0.5)
        let shuffled = Array(w.reversed()) + [PaceOfAging.Week(day: w[3].day, bodyAge: w[3].bodyAge,
                                                              chronoAge: w[3].chronoAge)]
        XCTAssertEqual(PaceOfAging.pace(shuffled, asOf: "2026-09-26")!, 0.5, accuracy: 1e-9)
    }

    /// The engine scores each week with the whole-year age, so the stored ZENO Age steps up a year on a
    /// birthday. Subtracting the age it was scored with keeps a steady person at 1.0x across the step.
    func testABirthdayStepDoesNotMoveThePace() {
        let keys = weekKeys(endingOn: "2026-09-26", count: 26)
        let w = keys.enumerated().map { i, key -> PaceOfAging.Week in
            let age: Double = i < 13 ? 39 : 40
            return PaceOfAging.Week(day: key, bodyAge: age - 2.5, chronoAge: age)
        }
        XCTAssertEqual(PaceOfAging.pace(w, asOf: "2026-09-26")!, 1.0, accuracy: 1e-9)
    }

    // MARK: Series, change and ruler

    func testSeriesHasAPaceForEveryWeekWithEnoughHistory() {
        let w = weeks(endingOn: "2026-09-26", count: 10, startGap: 0, gapPerYear: 0)
        let s = PaceOfAging.series(w)
        // The first three weeks are too few to fit; every week from the fourth has a pace.
        XCTAssertEqual(s.count, 10 - (PaceOfAging.minWeeks - 1))
        XCTAssertEqual(s.first?.day, w[PaceOfAging.minWeeks - 1].day)
        XCTAssertEqual(s.last?.day, "2026-09-26")
        for point in s { XCTAssertEqual(point.pace, 1.0, accuracy: 1e-9) }
    }

    func testChangeIsJudgedOnThePrintedFigure() {
        XCTAssertEqual(PaceOfAging.change(current: 1.04, previous: 0.96), .same)    // both print 1.0
        XCTAssertEqual(PaceOfAging.change(current: 0.8, previous: 1.2), .slower)
        XCTAssertEqual(PaceOfAging.change(current: 1.7, previous: 1.5), .faster)
        XCTAssertEqual(PaceOfAging.change(current: -0.26, previous: -0.34), .same)   // both print -0.3
        XCTAssertEqual(PaceOfAging.change(current: -0.5, previous: -0.2), .slower)
    }

    func testRulerFraction() {
        XCTAssertEqual(PaceOfAging.rulerFraction(-1), 0, accuracy: 1e-12)
        XCTAssertEqual(PaceOfAging.rulerFraction(1), 0.5, accuracy: 1e-12)
        XCTAssertEqual(PaceOfAging.rulerFraction(3), 1, accuracy: 1e-12)
        XCTAssertEqual(PaceOfAging.rulerFraction(7), 1, accuracy: 1e-12)
        XCTAssertEqual(PaceOfAging.rulerFraction(-4), 0, accuracy: 1e-12)
    }

    func testDayNumberIsTheGregorianDayCount() {
        XCTAssertEqual(PaceOfAging.dayNumber("1970-01-01"), 0)
        XCTAssertEqual(PaceOfAging.dayNumber("1970-01-02"), 1)
        XCTAssertEqual(PaceOfAging.dayNumber("2000-03-01"), 11_017)
        XCTAssertEqual(PaceOfAging.dayNumber("2024-03-01")! - PaceOfAging.dayNumber("2024-02-28")!, 2) // leap
        XCTAssertEqual(PaceOfAging.dayNumber("2026-03-01")! - PaceOfAging.dayNumber("2026-02-28")!, 1)
        XCTAssertNil(PaceOfAging.dayNumber("2026-9-26"))
        XCTAssertNil(PaceOfAging.dayNumber("2026-00-10"))
        XCTAssertNil(PaceOfAging.dayNumber(""))
    }

    // MARK: Per-factor years

    /// A result's factors, each converted to years, add up to its gap (ZENO Age − chronological age).
    func testFactorYearsAddUpToTheGap() {
        let inputs = VitalityEngine.Inputs(
            chronoAge: 40, restingHR: 52, vo2max: 55.5, expectedVO2max: 45,
            sleepHours: 7.5, sleepConsistency: 0.9, rmssd: 54, rmssdNorm: 45, steps: 11000)
        let r = VitalityEngine.compute(inputs)!
        let years = r.contributions.map(VitalityEngine.years(for:)).reduce(0, +)
        XCTAssertEqual(years, r.bodyAge - r.chronoAge, accuracy: 1e-9)
        // Protective factors are negative years, a factor that ages you positive.
        let rhr = r.contributions.first { $0.key == "rhr" }!
        XCTAssertLessThan(VitalityEngine.years(for: rhr), 0)
        let older = VitalityEngine.contributions(.init(chronoAge: 40, restingHR: 85)).first!
        XCTAssertGreaterThan(VitalityEngine.years(for: older), 0)
    }
}
