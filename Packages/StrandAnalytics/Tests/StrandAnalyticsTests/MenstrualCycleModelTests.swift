import XCTest
@testable import StrandAnalytics

final class MenstrualCycleModelTests: XCTestCase {

    private typealias M = MenstrualCycleModel

    private func day(_ base: String, _ offset: Int) -> String { M.shift(base, by: offset)! }

    /// Flow logged for `count` days from `start`.
    private func bleed(_ start: String, _ count: Int, _ level: M.Flow = .medium) -> [String: M.Flow] {
        var out: [String: M.Flow] = [:]
        for i in 0..<count { out[day(start, i)] = level }
        return out
    }

    // MARK: - No logs / stale

    func testNoLogsPredictsNothing() {
        let s = M.summarize(periodStarts: [], flow: [:], today: "2026-10-03")
        XCTAssertEqual(s.status, .noLogs)
        XCTAssertNil(s.cycleDay)
        XCTAssertNil(s.phase)
        XCTAssertNil(s.nextPeriod)
        XCTAssertNil(s.basis)
        XCTAssertTrue(s.cycles.isEmpty)
    }

    func testFutureStartsAreIgnored() {
        let s = M.summarize(periodStarts: ["2026-10-10"], flow: [:], today: "2026-10-03")
        XCTAssertEqual(s.status, .noLogs)
    }

    func testOldLogStopsPredicting() {
        let s = M.summarize(periodStarts: ["2026-06-01"], flow: [:], today: "2026-10-03")
        XCTAssertEqual(s.status, .stale(lastStart: "2026-06-01"))
        XCTAssertNil(s.phase)
        XCTAssertNil(s.nextPeriod)
    }

    // MARK: - One logged start (a prior until a second period)

    func testOneStartUsesTextbookPriorAndSaysSo() {
        let s = M.summarize(periodStarts: ["2026-09-20"], flow: [:], today: "2026-10-03")
        XCTAssertEqual(s.status, .active)
        XCTAssertEqual(s.cycleDay, 14)
        XCTAssertEqual(s.basis, .typical)
        XCTAssertEqual(s.modelCycleLength, 28)
        // 28 ± 3 days from Sep 20.
        XCTAssertEqual(s.nextPeriod, M.Window(earliest: "2026-10-15", latest: "2026-10-21"))
        XCTAssertNil(s.typical.cycleLength, "one start is no cycle of the user's own")
    }

    func testTemperatureLengthBeatsThePrior() {
        let s = M.summarize(periodStarts: ["2026-09-20"], flow: [:], today: "2026-10-03",
                            temperatureCycleLength: 31)
        XCTAssertEqual(s.basis, .temperature)
        XCTAssertEqual(s.modelCycleLength, 31)
    }

    func testImplausibleTemperatureLengthIsIgnored() {
        let s = M.summarize(periodStarts: ["2026-09-20"], flow: [:], today: "2026-10-03",
                            temperatureCycleLength: 90)
        XCTAssertEqual(s.basis, .typical)
    }

    // MARK: - Personal statistics

    func testTypicalCycleFromOwnLogs() {
        // Cycles of 27, 29, 28 days, then the current one.
        let starts = ["2026-06-01", "2026-06-28", "2026-07-27", "2026-08-24"]
        let flow = bleed("2026-06-01", 4).merging(bleed("2026-06-28", 5)) { a, _ in a }
            .merging(bleed("2026-07-27", 6)) { a, _ in a }
        let s = M.summarize(periodStarts: starts, flow: flow, today: "2026-08-30")
        XCTAssertEqual(s.typical.cycleLength, 28)
        XCTAssertEqual(s.typical.cycleVariation, 2)
        XCTAssertEqual(s.typical.cyclesUsed, 3)
        XCTAssertEqual(s.typical.cycleSD!, 1.0, accuracy: 1e-9)
        XCTAssertEqual(s.typical.periodLength, 5)
        XCTAssertEqual(s.basis, .personal(cycles: 3))
        // Mean 28 ± max(1, round(SD)) = ± 1 from Aug 24.
        XCTAssertEqual(s.nextPeriod, M.Window(earliest: "2026-09-20", latest: "2026-09-22"))
        XCTAssertEqual(s.cycleDay, 7)
    }

    func testOneCompletedCycleWidensToTwoDays() {
        let s = M.summarize(periodStarts: ["2026-08-01", "2026-08-31"], flow: [:], today: "2026-09-05")
        XCTAssertEqual(s.basis, .personal(cycles: 1))
        XCTAssertEqual(s.modelCycleLength, 30)
        XCTAssertEqual(s.nextPeriod, M.Window(earliest: "2026-09-28", latest: "2026-10-02"))
    }

    func testExtraSpreadWidensTheWindow() {
        let s = M.summarize(periodStarts: ["2026-08-01", "2026-08-31"], flow: [:], today: "2026-09-05",
                            extraSpread: 2)
        XCTAssertEqual(s.nextPeriod, M.Window(earliest: "2026-09-26", latest: "2026-10-04"))
    }

    func testImplausibleCycleIsKeptButNotAveraged() {
        // A 70-day gap (a missed log) between two ordinary cycles.
        let starts = ["2026-01-01", "2026-01-29", "2026-04-09", "2026-05-07"]
        let s = M.summarize(periodStarts: starts, flow: [:], today: "2026-05-10")
        XCTAssertEqual(s.cycles.count, 4)
        XCTAssertEqual(s.cycles.map(\.length), [28, 70, 28, nil])
        XCTAssertEqual(s.typical.cyclesUsed, 2)
        XCTAssertEqual(s.typical.cycleLength, 28)
    }

    func testDuplicateStartsAreOne() {
        let s = M.summarize(periodStarts: ["2026-09-20", "2026-09-20"], flow: [:], today: "2026-09-21")
        XCTAssertEqual(s.cycles.count, 1)
    }

    // MARK: - Period runs

    func testLoggedRunToleratesOneDayGapAndStopsAtNoFlow() {
        var flow = bleed("2026-09-01", 2)
        flow["2026-09-04"] = .light           // a one-day gap on the 3rd
        flow["2026-09-05"] = .noFlow          // explicitly over
        flow["2026-09-06"] = .heavy           // not part of this period
        XCTAssertEqual(M.loggedRun(from: "2026-09-01", flow: flow, through: "2026-09-30"), 4)
    }

    func testSpottingIsNotAPeriodDay() {
        var flow = bleed("2026-09-01", 3)
        flow["2026-09-04"] = .spotting
        XCTAssertEqual(M.loggedRun(from: "2026-09-01", flow: flow, through: "2026-09-30"), 3)
        XCTAssertFalse(M.Flow.spotting.isPeriod)
        XCTAssertTrue(M.Flow.light.isPeriod)
    }

    func testRunMayBeginTheDayAfterTheLoggedStart() {
        let flow = bleed("2026-09-02", 3)
        XCTAssertEqual(M.loggedRun(from: "2026-09-01", flow: flow, through: "2026-09-30"), 4)
        XCTAssertNil(M.loggedRun(from: "2026-08-25", flow: flow, through: "2026-09-30"))
    }

    func testCurrentBleedStaysOpenWhileFlowContinues() {
        // Day 2 of a period with flow on both days: today is menstrual and days 3-5 are still expected.
        let s = M.summarize(periodStarts: ["2026-10-02"], flow: bleed("2026-10-02", 2), today: "2026-10-03")
        XCTAssertEqual(s.cycleDay, 2)
        XCTAssertEqual(s.phase, .menstrual)
        XCTAssertTrue(s.isPeriodDay)
        XCTAssertEqual(s.modelPeriodLength, 5)
        let cal = M.calendar(from: "2026-10-02", to: "2026-10-08", summary: s, flow: bleed("2026-10-02", 2),
                             today: "2026-10-03")
        XCTAssertEqual(cal.map(\.isLoggedPeriodDay), [true, true, false, false, false, false, false])
        XCTAssertEqual(cal.map(\.isPredictedPeriodDay), [false, false, true, true, true, false, false])
    }

    func testFinishedBleedUsesTheLoggedLength() {
        let flow = bleed("2026-09-25", 3)
        let s = M.summarize(periodStarts: ["2026-09-25"], flow: flow, today: "2026-10-03")
        XCTAssertEqual(s.modelPeriodLength, 3)
        XCTAssertEqual(s.phase, .follicular)
    }

    // MARK: - Phases

    func testPhaseSpansFor28Days() {
        let spans = M.phaseSpans(cycleLength: 28, periodLength: 5)
        XCTAssertEqual(spans.map(\.phase), [.menstrual, .follicular, .ovulatory, .luteal])
        XCTAssertEqual(spans.map(\.days), [1...5, 6...12, 13...14, 15...28])
        XCTAssertEqual(M.phaseLengths(cycleLength: 28, periodLength: 5).map(\.days), [5, 7, 2, 14])
    }

    func testShortCycleKeepsEveryPhase() {
        for length in 15...22 {
            let spans = M.phaseSpans(cycleLength: length, periodLength: 7)
            XCTAssertTrue(spans.allSatisfy { !$0.days.isEmpty }, "length \(length)")
            XCTAssertEqual(spans.last!.days.upperBound, max(length, 7 + M.ovulatoryDays + 2))
            // Contiguous.
            for i in 1..<spans.count {
                XCTAssertEqual(spans[i].days.lowerBound, spans[i - 1].days.upperBound + 1)
            }
        }
    }

    func testLatePeriodStaysLutealAndCountsDaysLate() {
        // Day 33 on a 28 ± 3 prior: the window closed on Oct 2.
        let s = M.summarize(periodStarts: ["2026-09-01"], flow: [:], today: "2026-10-03")
        XCTAssertEqual(s.cycleDay, 33)
        XCTAssertEqual(s.phase, .luteal)
        XCTAssertEqual(s.nextPeriod?.latest, "2026-10-02")
        XCTAssertEqual(s.daysLate, 1)
    }

    func testPhasesDoNotApplyShowsOnlyTheBleed() {
        let flow = bleed("2026-10-01", 2)
        let s = M.summarize(periodStarts: ["2026-10-01"], flow: flow, today: "2026-10-02", phasesApply: false)
        XCTAssertEqual(s.phase, .menstrual)
        let later = M.summarize(periodStarts: ["2026-09-20"], flow: [:], today: "2026-10-03", phasesApply: false)
        XCTAssertNil(later.phase)
        let cal = M.calendar(from: "2026-09-20", to: "2026-10-20", summary: later, flow: [:],
                             today: "2026-10-03", phasesApply: false)
        XCTAssertTrue(cal.allSatisfy { $0.phase == nil || $0.phase == .menstrual })
        XCTAssertTrue(cal.contains { $0.isPredictedPeriodDay }, "the next bleed is still expected")
    }

    // MARK: - Calendar

    func testCalendarLaysOutPastCurrentAndPredictedCycles() {
        let starts = ["2026-08-01", "2026-08-29"]
        let flow = bleed("2026-08-01", 5).merging(bleed("2026-08-29", 4)) { a, _ in a }
        let s = M.summarize(periodStarts: starts, flow: flow, today: "2026-09-10")
        let cal = M.calendar(from: "2026-07-25", to: "2026-10-31", summary: s, flow: flow, today: "2026-09-10")
        let byDay = Dictionary(uniqueKeysWithValues: cal.map { ($0.day, $0) })
        XCTAssertNil(byDay["2026-07-31"]!.phase, "nothing before the first logged start")
        XCTAssertEqual(byDay["2026-08-01"]!.phase, .menstrual)
        XCTAssertEqual(byDay["2026-08-01"]!.cycleDay, 1)
        XCTAssertEqual(byDay["2026-08-14"]!.phase, .ovulatory)   // 28-day cycle: days 13-14
        XCTAssertEqual(byDay["2026-08-28"]!.phase, .luteal)
        XCTAssertEqual(byDay["2026-08-29"]!.cycleDay, 1)
        XCTAssertFalse(byDay["2026-09-10"]!.isPredicted)
        XCTAssertTrue(byDay["2026-09-11"]!.isPredicted)
        // The next predicted period starts 28 days after Aug 29 and is dashed, unlogged.
        XCTAssertEqual(byDay["2026-09-26"]!.phase, .menstrual)
        XCTAssertTrue(byDay["2026-09-26"]!.isPredictedPeriodDay)
        XCTAssertEqual(byDay["2026-09-26"]!.cycleDay, 1)
    }

    func testImplausibleCycleLaysOutOnlyItsBleed() {
        let starts = ["2026-01-01", "2026-03-15"]
        let flow = bleed("2026-01-01", 4)
        let s = M.summarize(periodStarts: starts, flow: flow, today: "2026-03-20")
        let cal = M.calendar(from: "2026-01-01", to: "2026-03-14", summary: s, flow: flow, today: "2026-03-20")
        XCTAssertEqual(cal.filter { $0.phase != nil }.count, 4)
        XCTAssertTrue(cal.allSatisfy { $0.phase == nil || $0.phase == .menstrual })
    }

    func testLateCycleHasNoPhasesAfterToday() {
        let s = M.summarize(periodStarts: ["2026-09-01"], flow: [:], today: "2026-10-03")
        XCTAssertNotNil(s.daysLate)
        let cal = M.calendar(from: "2026-10-01", to: "2026-10-10", summary: s, flow: [:], today: "2026-10-03")
        let byDay = Dictionary(uniqueKeysWithValues: cal.map { ($0.day, $0) })
        XCTAssertEqual(byDay["2026-10-03"]!.phase, .luteal)
        XCTAssertNil(byDay["2026-10-04"]!.phase)
        XCTAssertFalse(cal.contains { $0.isPredictedPeriodDay }, "a late period has no honest next start")
    }

    func testCalendarRejectsAnInvertedSpan() {
        let s = M.summarize(periodStarts: ["2026-09-01"], flow: [:], today: "2026-09-10")
        XCTAssertTrue(M.calendar(from: "2026-09-10", to: "2026-09-01", summary: s, flow: [:],
                                 today: "2026-09-10").isEmpty)
    }
}
