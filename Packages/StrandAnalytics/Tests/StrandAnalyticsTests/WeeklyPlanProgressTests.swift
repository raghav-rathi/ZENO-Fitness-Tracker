import XCTest
@testable import StrandAnalytics

final class WeeklyPlanProgressTests: XCTestCase {

    func testIsoWeekday() {
        XCTAssertEqual(WeeklyPlanProgress.isoWeekday("1970-01-01"), 4)   // Thursday
        XCTAssertEqual(WeeklyPlanProgress.isoWeekday("2000-03-01"), 3)   // Wednesday
        XCTAssertEqual(WeeklyPlanProgress.isoWeekday("2026-10-02"), 5)   // Friday
        XCTAssertEqual(WeeklyPlanProgress.isoWeekday("2026-10-04"), 7)   // Sunday
        XCTAssertEqual(WeeklyPlanProgress.isoWeekday("1969-12-31"), 3)   // before the epoch
        XCTAssertNil(WeeklyPlanProgress.isoWeekday("2026-13-01"))
        XCTAssertNil(WeeklyPlanProgress.isoWeekday("not a day"))
    }

    func testWeekStartIsTheMondayOnOrBefore() {
        XCTAssertEqual(WeeklyPlanProgress.weekStart(of: "2026-10-02"), "2026-09-28")
        XCTAssertEqual(WeeklyPlanProgress.weekStart(of: "2026-10-04"), "2026-09-28")
        XCTAssertEqual(WeeklyPlanProgress.weekStart(of: "2026-09-28"), "2026-09-28")
        XCTAssertEqual(WeeklyPlanProgress.weekStart(of: "2026-10-05"), "2026-10-05")
    }

    func testWeekDaysCrossMonthAndYearEnds() {
        XCTAssertEqual(WeeklyPlanProgress.days(ofWeekStarting: "2026-12-28"),
                       ["2026-12-28", "2026-12-29", "2026-12-30", "2026-12-31", "2027-01-01", "2027-01-02",
                        "2027-01-03"])
    }

    func testDaysLeftCountsToday() {
        XCTAssertEqual(WeeklyPlanProgress.daysLeft(today: "2026-09-28"), 7)   // Monday
        XCTAssertEqual(WeeklyPlanProgress.daysLeft(today: "2026-10-02"), 3)   // Friday
        XCTAssertEqual(WeeklyPlanProgress.daysLeft(today: "2026-10-04"), 1)   // Sunday
    }

    func testCountProgressCapsAtOne() {
        XCTAssertEqual(WeeklyPlanProgress.count(done: 2, target: 4), .init(fraction: 0.5, met: false))
        XCTAssertEqual(WeeklyPlanProgress.count(done: 5, target: 4), .init(fraction: 1, met: true))
        XCTAssertEqual(WeeklyPlanProgress.count(done: 0, target: 0), .init(fraction: 1, met: true))
    }

    func testAverageProgress() {
        let r = WeeklyPlanProgress.average([80, 84, .nan], target: 85)
        XCTAssertEqual(r.average!, 82, accuracy: 1e-9)
        XCTAssertEqual(r.progress.fraction, 82.0 / 85.0, accuracy: 1e-9)
        XCTAssertFalse(r.progress.met)
        let met = WeeklyPlanProgress.average([90, 86], target: 85)
        XCTAssertTrue(met.progress.met)
        XCTAssertEqual(met.progress.fraction, 1)
        let none = WeeklyPlanProgress.average([], target: 85)
        XCTAssertNil(none.average)
        XCTAssertFalse(none.progress.met)
    }

    func testTotalProgress() {
        XCTAssertEqual(WeeklyPlanProgress.total(27, target: 22), .init(fraction: 1, met: true))
        XCTAssertEqual(WeeklyPlanProgress.total(11, target: 22).fraction, 0.5, accuracy: 1e-9)
    }

    func testOverallPercentIsTheEqualWeightMean() {
        let p: [WeeklyPlanProgress.Progress] = [.init(fraction: 1, met: true), .init(fraction: 0.5, met: false),
                                                .init(fraction: 0.25, met: false)]
        XCTAssertEqual(WeeklyPlanProgress.overallPercent(p), 58)
        XCTAssertNil(WeeklyPlanProgress.overallPercent([]))
    }

    func testProration() {
        XCTAssertEqual(WeeklyPlanProgress.proratedTarget(5, countedDays: 7), 5)
        XCTAssertEqual(WeeklyPlanProgress.proratedTarget(5, countedDays: 3), 3)
        XCTAssertEqual(WeeklyPlanProgress.proratedTarget(2, countedDays: 3), 2)
        XCTAssertEqual(WeeklyPlanProgress.proratedTarget(5, countedDays: 0), 1)
        XCTAssertEqual(WeeklyPlanProgress.proratedTotal(60, countedDays: 7), 60)
        XCTAssertEqual(WeeklyPlanProgress.proratedTotal(60, countedDays: 3), 30)   // 25.7 → 30
    }
}
