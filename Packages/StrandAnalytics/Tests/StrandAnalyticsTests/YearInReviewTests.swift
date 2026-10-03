import XCTest
@testable import StrandAnalytics

final class YearInReviewTests: XCTestCase {

    /// The band rule the app's Strain target uses (CoupledView.optimalStrainRange).
    private func range(_ recovery: Double) -> ClosedRange<Double>? {
        switch recovery {
        case 67...: return 14...18
        case 34..<67: return 10...14
        default: return 4...10
        }
    }

    private func key(_ year: Int, _ dayOfYear: Int) -> String {
        var c = DateComponents()
        c.year = year
        c.day = dayOfYear
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let date = cal.date(from: c)!
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    func testEverestEquivalence() {
        // 8,848.86 m at 0.16 m a step is 55,305.4 steps a climb.
        XCTAssertEqual(YearInReview.everestClimbs(steps: 55_305), 1.0, accuracy: 0.001)
        XCTAssertEqual(YearInReview.everestClimbs(steps: 808_735), 14.62, accuracy: 0.01)
        XCTAssertEqual(YearInReview.everestClimbs(steps: -5), 0)
    }

    func testElapsedDaysCountsInclusivelyAndCapsAtTheYear() {
        XCTAssertEqual(YearInReview.elapsedDays(year: 2026, through: "2026-01-01"), 1)
        XCTAssertEqual(YearInReview.elapsedDays(year: 2026, through: "2026-10-03"), 276)
        XCTAssertEqual(YearInReview.elapsedDays(year: 2024, through: "2025-01-10"), 366)   // leap year
        XCTAssertEqual(YearInReview.elapsedDays(year: 2027, through: "2026-12-31"), 0)
        XCTAssertEqual(YearInReview.elapsedDays(year: 2026, through: "nonsense"), 0)
    }

    func testMomentsPickTheExtremesAndTheEarliestTie() {
        let days = [
            YearInReview.Day(day: "2026-03-01", recovery: 40, strain: 12.0, sleepPerformance: 80, asleepMinutes: 420),
            YearInReview.Day(day: "2026-03-02", recovery: 95, strain: 20.6, sleepPerformance: 100, asleepMinutes: 567),
            YearInReview.Day(day: "2026-03-03", recovery: 7, strain: 9.0, sleepPerformance: 100, asleepMinutes: 380),
            YearInReview.Day(day: "2026-03-04", recovery: 95, strain: 4.0, sleepPerformance: 55, asleepMinutes: 567),
        ]
        let s = YearInReview.summarize(year: 2026, through: "2026-03-31", days: days, activities: [],
                                       strainRange: range)
        XCTAssertEqual(s.peakRecovery, YearInReview.Moment(day: "2026-03-02", value: 95))
        XCTAssertEqual(s.lowestRecovery, YearInReview.Moment(day: "2026-03-03", value: 7))
        XCTAssertEqual(s.maxStrain, YearInReview.Moment(day: "2026-03-02", value: 20.6))
        // Two nights at 100%: the earlier one.
        XCTAssertEqual(s.bestSleep, YearInReview.Moment(day: "2026-03-02", value: 100))
        XCTAssertEqual(s.longestSleep, YearInReview.Moment(day: "2026-03-02", value: 567))
        XCTAssertEqual(s.averageRecovery!, (40 + 95 + 7 + 95) / 4.0, accuracy: 1e-9)
        XCTAssertEqual(s.trackedDays, 4)
        XCTAssertEqual(s.recoveries, 4)
        XCTAssertEqual(s.nights, 4)
        XCTAssertEqual(s.firstTrackedDay, "2026-03-01")
    }

    func testDaysOutsideTheYearOrAfterThroughAreIgnored() {
        let days = [
            YearInReview.Day(day: "2025-12-31", recovery: 99),
            YearInReview.Day(day: "2026-06-01", recovery: 50),
            YearInReview.Day(day: "2026-10-04", recovery: 98),   // tomorrow: a seeded future row
        ]
        let s = YearInReview.summarize(year: 2026, through: "2026-10-03", days: days, activities: [],
                                       strainRange: range)
        XCTAssertEqual(s.peakRecovery?.value, 50)
        XCTAssertEqual(s.trackedDays, 1)
    }

    func testMissingValuesAreSkippedNotZero() {
        let days = [
            YearInReview.Day(day: "2026-01-02", recovery: nil, strain: 8.0),
            YearInReview.Day(day: "2026-01-03", recovery: 60, strain: nil),
            YearInReview.Day(day: "2026-01-04", steps: 9_000),   // phone steps only: not a tracked day
        ]
        let s = YearInReview.summarize(year: 2026, through: "2026-01-31", days: days, activities: [],
                                       strainRange: range)
        XCTAssertEqual(s.lowestRecovery?.value, 60)
        XCTAssertNil(s.bestSleep)
        XCTAssertNil(s.averageSleepPerformance)
        XCTAssertEqual(s.trackedDays, 2)
        XCTAssertEqual(s.steps, 9_000)
        XCTAssertEqual(s.stepDays, 1)
    }

    func testPillarsNeedTwoWeeksAndScoreTheirOptimalMarks() {
        // 20 days: Sleep Optimal (85%+, judged on the whole percent) on 10 nights, Recovery green on 5 days,
        // Strain inside the day's range on 15 days.
        var days: [YearInReview.Day] = []
        for i in 1...20 {
            let sleep = i <= 10 ? 84.6 : 84.4          // 84.6 prints 85% (Optimal); 84.4 prints 84%
            let recovery = i <= 5 ? 70.0 : 50.0          // green, then yellow
            let strain = i <= 15 ? (i <= 5 ? 15.0 : 11.0) : 19.0   // in range for 15 days
            days.append(YearInReview.Day(day: key(2026, i), recovery: recovery, strain: strain,
                                         sleepPerformance: sleep))
        }
        let s = YearInReview.summarize(year: 2026, through: "2026-12-31", days: days, activities: [],
                                       strainRange: range)
        XCTAssertEqual(s.pillars.map(\.pillar), [.sleep, .recovery, .strain])
        XCTAssertEqual(s.pillars[0].hits, 10)
        XCTAssertEqual(s.pillars[1].hits, 5)
        XCTAssertEqual(s.pillars[2].hits, 15)
        XCTAssertEqual(s.bestPillar, .strain)

        // Under two weeks of readings, no pillar can win.
        let short = YearInReview.summarize(year: 2026, through: "2026-12-31", days: Array(days.prefix(13)),
                                           activities: [], strainRange: range)
        XCTAssertTrue(short.pillars.isEmpty)
        XCTAssertNil(short.bestPillar)
        XCTAssertEqual(short.persona, .groundwork)
        XCTAssertFalse(short.hasStory)
    }

    func testPillarTieKeepsTheEarlierPillar() {
        var days: [YearInReview.Day] = []
        for i in 1...14 {
            // Sleep Optimal and Recovery green on every day; Strain never in range.
            days.append(YearInReview.Day(day: key(2026, i), recovery: 80, strain: 2, sleepPerformance: 90))
        }
        let s = YearInReview.summarize(year: 2026, through: "2026-01-14", days: days, activities: [],
                                       strainRange: range)
        XCTAssertEqual(s.bestPillar, .sleep)
    }

    func testPersonaRules() {
        let clear = YearInReview.PillarScore(pillar: .recovery, hits: 30, days: 40)    // 75%
        let faint = YearInReview.PillarScore(pillar: .strain, hits: 10, days: 40)      // 25%
        XCTAssertEqual(YearInReview.persona(trackedDays: 10, coverage: 1, best: clear), .groundwork)
        XCTAssertEqual(YearInReview.persona(trackedDays: 200, coverage: 0.95, best: faint), .consistency)
        XCTAssertEqual(YearInReview.persona(trackedDays: 200, coverage: 0.95, best: clear), .recovery)
        XCTAssertEqual(YearInReview.persona(trackedDays: 100, coverage: 0.4, best: faint), .strain)
        XCTAssertEqual(YearInReview.persona(trackedDays: 100, coverage: 0.95, best: nil), .consistency)
        XCTAssertEqual(YearInReview.persona(trackedDays: 100, coverage: 0.4, best: nil), .groundwork)
    }

    func testTopActivityCountsThenMinutesThenName() {
        let acts = [
            YearInReview.Activity(day: "2026-02-01", name: "Running", minutes: 30),
            YearInReview.Activity(day: "2026-02-02", name: "Cycling", minutes: 90),
            YearInReview.Activity(day: "2026-02-03", name: "Running", minutes: 30),
            YearInReview.Activity(day: "2026-02-04", name: "Cycling", minutes: 10),
            YearInReview.Activity(day: "2025-02-04", name: "Yoga", minutes: 10),      // last year
        ]
        let s = YearInReview.summarize(year: 2026, through: "2026-12-31", days: [], activities: acts,
                                       strainRange: range)
        // Both twice; Cycling has more minutes.
        XCTAssertEqual(s.topActivity?.name, "Cycling")
        XCTAssertEqual(s.topActivity?.count, 2)
        XCTAssertEqual(s.activities, 4)
        XCTAssertEqual(s.activityMinutes, 160)
    }

    func testLongestStreakStaysInsideTheYear() {
        let days = ["2025-12-30", "2025-12-31", "2026-01-01", "2026-01-02", "2026-01-05", "2026-01-06",
                    "2026-01-07"].map { YearInReview.Day(day: $0, recovery: 50) }
        let s = YearInReview.summarize(year: 2026, through: "2026-12-31", days: days, activities: [],
                                       strainRange: range)
        // 1-2 Jan is two days (the December days belong to 2025); 5-7 Jan is three.
        XCTAssertEqual(s.longestStreak, 3)
    }

    func testCoverageAndConsistencyPersona() {
        var days: [YearInReview.Day] = []
        for i in 1...30 {
            // Every day worn, nothing on its optimal mark.
            days.append(YearInReview.Day(day: key(2026, i), recovery: 40, strain: 20, sleepPerformance: 60))
        }
        let s = YearInReview.summarize(year: 2026, through: key(2026, 30), days: days, activities: [],
                                       strainRange: range)
        XCTAssertEqual(s.elapsedDays, 30)
        XCTAssertEqual(s.coverage, 1, accuracy: 1e-9)
        XCTAssertEqual(s.persona, .consistency)
        XCTAssertTrue(s.hasStory)
    }
}
