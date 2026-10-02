import XCTest
@testable import StrandAnalytics

final class PulseTrendMathTests: XCTestCase {

    private typealias M = PulseTrendMath

    /// `values` on consecutive days ending on `end`, oldest first; nil leaves the day out.
    private func series(_ values: [Double?], endingOn end: String) -> [M.Point] {
        let start = M.addDays(end, -(values.count - 1))
        return values.enumerated().compactMap { i, v in v.map { M.Point(day: M.addDays(start, i), value: $0) } }
    }

    // MARK: - Windows

    func testWindowsMatchWhoopsPagerSpans() {
        // "SEP 19 - SEP 25, 26" (W), "AUG 5 - SEP 3, 26" (M), "MAR 31 - SEP 26, 26" (6M).
        let w = M.window(.week, anchor: "2026-09-25", earliest: "2026-01-01")
        XCTAssertEqual(w?.start, "2026-09-19")
        XCTAssertEqual(w?.end, "2026-09-25")
        XCTAssertEqual(w?.dayCount, 7)
        XCTAssertEqual(M.window(.month, anchor: "2026-09-03", earliest: nil)?.start, "2026-08-05")
        XCTAssertEqual(M.window(.sixMonths, anchor: "2026-09-26", earliest: nil)?.start, "2026-03-31")
        // Across a leap day and a year: "SEP 3, 23 - FEB 29, 24".
        XCTAssertEqual(M.window(.sixMonths, anchor: "2024-02-29", earliest: nil)?.start, "2023-09-03")
        XCTAssertEqual(M.window(.year, anchor: "2026-10-01", earliest: nil)?.start, "2025-10-02")
    }

    func testWindowDayKeysCoverEveryDayInOrder() {
        let w = M.window(.week, anchor: "2026-03-01", earliest: nil)
        XCTAssertEqual(w?.dayKeys, ["2026-02-23", "2026-02-24", "2026-02-25", "2026-02-26", "2026-02-27",
                                    "2026-02-28", "2026-03-01"])
    }

    func testPagingStepsBackOneWindowAndKnowsWhereTheDataEnds() {
        let anchor = "2026-09-25"
        let p0 = M.window(.week, anchor: anchor, page: 0, earliest: "2026-09-15")
        let p1 = M.window(.week, anchor: anchor, page: 1, earliest: "2026-09-15")
        XCTAssertEqual(p1?.start, "2026-09-12")
        XCTAssertEqual(p1?.end, "2026-09-18")
        XCTAssertEqual(p0?.hasOlder, true)
        XCTAssertEqual(p0?.hasNewer, false)
        XCTAssertEqual(p1?.hasOlder, false)
        XCTAssertEqual(p1?.hasNewer, true)
        XCTAssertEqual(M.lastPage(.week, anchor: anchor, earliest: "2026-09-15"), 1)
        XCTAssertEqual(M.lastPage(.week, anchor: anchor, earliest: "2026-09-25"), 0)
        XCTAssertEqual(M.lastPage(.week, anchor: anchor, earliest: nil), 0)
        XCTAssertEqual(M.lastPage(.all, anchor: anchor, earliest: "2020-01-01"), 0)
        // Negative pages clamp to the latest window.
        XCTAssertEqual(M.window(.week, anchor: anchor, page: -3, earliest: nil)?.page, 0)
    }

    func testPreviousWindowIsTheSameLengthAndAdjacent() {
        let w = M.window(.month, anchor: "2026-09-03", earliest: nil)!
        XCTAssertEqual(w.previous.end, "2026-08-04")
        XCTAssertEqual(w.previous.start, "2026-07-06")
        XCTAssertEqual(w.previous.dayCount, 30)
    }

    func testAllRunsFromTheFirstReadingToTheAnchor() {
        let w = M.window(.all, anchor: "2026-10-01", earliest: "2026-06-04")
        XCTAssertEqual(w?.start, "2026-06-04")
        XCTAssertEqual(w?.dayCount, 120)
        XCTAssertEqual(w?.hasOlder, false)
        // No history: a one-day window on the anchor rather than nothing.
        XCTAssertEqual(M.window(.all, anchor: "2026-10-01", earliest: nil)?.dayCount, 1)
        XCTAssertNil(M.window(.week, anchor: "not-a-day", earliest: nil))
    }

    // MARK: - Averages

    func testAverageLeavesOutTheRunningTotalsDayStillCounting() {
        // WHOOP's Steps week MAR 6 - MAR 12 prints 13,533: the mean of the six finished days.
        let steps = series([14_434, 10_599, 17_391, 12_527, 14_607, 11_640, 18_444], endingOn: "2026-03-12")
        let w = M.window(.week, anchor: "2026-03-12", earliest: nil)!
        let avg = M.average(steps, in: w, inProgressDay: "2026-03-12")
        XCTAssertEqual(avg?.value ?? 0, 13_533, accuracy: 0.5)
        XCTAssertEqual(avg?.count, 6)
        XCTAssertEqual(avg?.excludedDay, "2026-03-12")
        // A score that is final for the day keeps it: Recovery SEP 19 - SEP 25 prints 74%.
        let recovery = series([72, 97, 85, 66, 66, 66, 66], endingOn: "2026-09-25")
        let r = M.average(recovery, in: M.window(.week, anchor: "2026-09-25", earliest: nil)!)
        XCTAssertEqual(r?.value ?? 0, 74, accuracy: 0.01)
        XCTAssertNil(r?.excludedDay)
    }

    func testAverageKeepsTheInProgressDayWhenItIsTheOnlyReadingAndSkipsMissingDays() {
        let w = M.window(.week, anchor: "2026-03-12", earliest: nil)!
        let only = [M.Point(day: "2026-03-12", value: 4_000)]
        XCTAssertEqual(M.average(only, in: w, inProgressDay: "2026-03-12")?.value, 4_000)
        XCTAssertNil(M.average(only, in: w, inProgressDay: "2026-03-12")?.excludedDay)
        let gappy = series([50, nil, nil, 70, nil, nil, nil], endingOn: "2026-03-12")
        XCTAssertEqual(M.average(gappy, in: w)?.value, 60)
        XCTAssertEqual(M.average(gappy, in: w)?.count, 2)
        XCTAssertNil(M.average([], in: w))
    }

    // MARK: - Weekly totals

    func testWeeklyTotalsUseCompleteWeeksCountedBackFromTheEnd() {
        // 30 days: four complete weeks from the end; the two oldest days are not a week.
        let anchor = "2026-09-30"
        let values = (0..<30).map { Double($0 < 2 ? 100 : 10) }
        let s = series(values, endingOn: anchor)
        let w = M.window(.month, anchor: anchor, earliest: nil)!
        let weeks = M.weeklyTotals(s, in: w)
        XCTAssertEqual(weeks.count, 4)
        XCTAssertEqual(weeks.last?.end, anchor)
        XCTAssertEqual(weeks.last?.start, "2026-09-24")
        XCTAssertEqual(weeks.map(\.total), [70, 70, 70, 70])
        XCTAssertEqual(M.averageWeeklyTotal(s, in: w), 70)
    }

    func testWeeklyTotalsDropWeeksWithoutAnyReading() {
        let anchor = "2026-09-30"
        let s = series([5, 5, 5, 5, 5, 5, 5], endingOn: anchor)
        let w = M.window(.month, anchor: anchor, earliest: nil)!
        XCTAssertEqual(M.weeklyTotals(s, in: w).count, 1)
        XCTAssertEqual(M.averageWeeklyTotal(s, in: w), 35)
        XCTAssertNil(M.averageWeeklyTotal([], in: w))
    }

    // MARK: - Change

    func testChangeIsAPercentOfThePreviousPeriodWhenThatCanBeDivided() {
        let c = M.change(current: 74, previous: 51)
        XCTAssertEqual(c?.delta ?? 0, 23, accuracy: 1e-9)
        XCTAssertEqual(c?.percent ?? 0, 45.098, accuracy: 0.01)
        XCTAssertNil(M.change(current: 0.3, previous: 0.1)?.percent)
        XCTAssertEqual(M.change(current: 0.3, previous: 0.1)?.delta ?? 0, 0.2, accuracy: 1e-9)
        XCTAssertNil(M.change(current: nil, previous: 3))
        XCTAssertNil(M.change(current: 3, previous: nil))
        // Against a negative previous value the sign still follows the move.
        XCTAssertEqual(M.change(current: -1, previous: -2)?.percent ?? 0, 50, accuracy: 1e-9)
    }

    // MARK: - Typical range

    func testTypicalRangeIsMeanPlusMinusOneSDOfTheThirtyDaysBeforeTheWindow() {
        let windowStart = "2026-09-19"
        var s = series(Array(repeating: 40.0, count: 15) + Array(repeating: 50.0, count: 15),
                       endingOn: M.addDays(windowStart, -1))
        // Readings inside the window and older than 30 days never count.
        s.append(M.Point(day: windowStart, value: 500))
        s.append(M.Point(day: M.addDays(windowStart, -31), value: -500))
        let range = M.typicalRange(s, before: windowStart)
        // Mean 45, sample SD of fifteen 40s and fifteen 50s = 5 * sqrt(30 / 29).
        let sd = 5 * (30.0 / 29.0).squareRoot()
        XCTAssertEqual(range?.lowerBound ?? 0, 45 - sd, accuracy: 1e-9)
        XCTAssertEqual(range?.upperBound ?? 0, 45 + sd, accuracy: 1e-9)
    }

    func testTypicalRangeNeedsEnoughReadings() {
        let s = series([40, 41, 42, 43, 44, 45], endingOn: "2026-09-18")
        XCTAssertNil(M.typicalRange(s, before: "2026-09-19"))
        XCTAssertNotNil(M.typicalRange(s, before: "2026-09-19", minSamples: 6))
    }

    // MARK: - Relations

    func testRelationToARangeCountsItsBoundsAsInside() {
        XCTAssertEqual(M.relation(17.9, to: 18...24), .below)
        XCTAssertEqual(M.relation(18, to: 18...24), .within)
        XCTAssertEqual(M.relation(24, to: 18...24), .within)
        XCTAssertEqual(M.relation(50, to: 18...24), .above)
    }

    func testRelationToAReferenceHasATolerance() {
        XCTAssertEqual(M.relation(30, reference: 30), .within)
        XCTAssertEqual(M.relation(30.4, reference: 30), .within)
        XCTAssertEqual(M.relation(31, reference: 30), .above)
        XCTAssertEqual(M.relation(60, reference: 73), .below)
        // Near zero the absolute tolerance applies.
        XCTAssertEqual(M.relation(0.03, reference: 0), .within)
        XCTAssertEqual(M.relation(-0.2, reference: 0.1), .below)
    }

    // MARK: - Segments

    func testSixMonthSegmentsAreThirtyDayBlocksCountedBackFromTheEnd() {
        // WHOOP's Steps 6M MAR 31 - SEP 26: the first segment spans MAR 31 - APR 29.
        let anchor = "2026-09-26"
        let w = M.window(.sixMonths, anchor: anchor, earliest: nil)!
        let s = series((0..<180).map { Double($0 / 30 + 1) * 100 }, endingOn: anchor)
        let segs = M.segments(s, in: w, blockDays: M.segmentDays(.sixMonths, dayCount: w.dayCount))
        XCTAssertEqual(segs.count, 6)
        XCTAssertEqual(segs.first?.start, "2026-03-31")
        XCTAssertEqual(segs.first?.end, "2026-04-29")
        XCTAssertEqual(segs.last?.end, anchor)
        XCTAssertEqual(segs.map(\.value), [100, 200, 300, 400, 500, 600])
        XCTAssertNil(segs.first?.changePercent)
        XCTAssertEqual(segs[1].changePercent ?? 0, 100, accuracy: 1e-9)
        XCTAssertEqual(segs[5].changePercent ?? 0, 20, accuracy: 1e-9)
    }

    func testSegmentsSkipEmptyBlocksWhenComparing() {
        let anchor = "2026-09-26"
        let w = M.window(.sixMonths, anchor: anchor, earliest: nil)!
        // Readings only in the first and last blocks.
        var s = series(Array(repeating: 50.0, count: 30), endingOn: M.addDays(anchor, -150))
        s += series(Array(repeating: 75.0, count: 30), endingOn: anchor)
        let segs = M.segments(s, in: w, blockDays: 30)
        XCTAssertEqual(segs.compactMap(\.value), [50, 75])
        XCTAssertNil(segs[1].value)
        XCTAssertNil(segs[1].changePercent)
        XCTAssertEqual(segs[5].changePercent ?? 0, 50, accuracy: 1e-9)
    }

    func testAShortOldestBlockIsDropped() {
        // 125 days in 30-day blocks: four full blocks and a 5-day stub, which is not a period.
        let anchor = "2026-10-01"
        let w = M.window(.all, anchor: anchor, earliest: M.addDays(anchor, -124))!
        let s = series(Array(repeating: 1.0, count: 125), endingOn: anchor)
        let segs = M.segments(s, in: w, blockDays: 30)
        XCTAssertEqual(segs.count, 4)
        XCTAssertEqual(segs.first?.start, M.addDays(anchor, -119))
        // A stub of at least a third of a block stays.
        let w2 = M.window(.all, anchor: anchor, earliest: M.addDays(anchor, -129))!
        XCTAssertEqual(M.segments(s, in: w2, blockDays: 30).count, 5)
    }

    func testSegmentLengthKeepsLongRangesToAboutSixSegments() {
        XCTAssertEqual(M.segmentDays(.sixMonths, dayCount: 180), 30)
        XCTAssertEqual(M.segmentDays(.year, dayCount: 365), 61)
        XCTAssertEqual(M.segmentDays(.all, dayCount: 120), 30)
        XCTAssertEqual(M.segmentDays(.all, dayCount: 180), 30)
        XCTAssertEqual(M.segmentDays(.all, dayCount: 400), 90)
        XCTAssertEqual(M.segmentDays(.all, dayCount: 1_000), 180)
        // Six segments of a year's 61 days cover it (the oldest is 60).
        let w = M.window(.year, anchor: "2026-10-01", earliest: nil)!
        let s = series(Array(repeating: 1.0, count: 365), endingOn: "2026-10-01")
        XCTAssertEqual(M.segments(s, in: w, blockDays: 61).count, 6)
    }

    func testWeeklyTotalSegmentsAverageTheirWeeks() {
        // Zone minutes: 10 a day in the last block, 5 a day before it.
        let anchor = "2026-09-26"
        let w = M.window(.sixMonths, anchor: anchor, earliest: nil)!
        let s = series((0..<180).map { $0 >= 150 ? 10.0 : 5.0 }, endingOn: anchor)
        let segs = M.segments(s, in: w, blockDays: 30, aggregation: .weeklyTotal)
        XCTAssertEqual(segs.last?.value ?? 0, 70, accuracy: 1e-9)
        XCTAssertEqual(segs.first?.value ?? 0, 35, accuracy: 1e-9)
        XCTAssertEqual(segs.last?.changePercent ?? 0, 100, accuracy: 1e-9)
    }

    // MARK: - Breakdown

    func testBreakdownCountsByPrintedBands() {
        // WHOOP's Recovery SEP 19 - SEP 25: 3x Green, 4x Yellow, 0x Red.
        XCTAssertEqual(M.breakdown([72, 97, 85, 66, 66, 66, 66], lowerBounds: [67, 34]), [3, 4, 0])
        // Strain on its printed one-decimal value: All Out above 18.0, Strenuous 14.1-18.0, Moderate
        // 10.1-14.0, Light up to 10.0.
        let strain = [12.0, 16.7, 16.9, 16.2, 15.6, 20.1, 13.1, 18.0, 10.0, 10.1]
        XCTAssertEqual(M.breakdown(strain, lowerBounds: [18.1, 14.1, 10.1]), [1, 5, 3, 1])
        XCTAssertEqual(M.breakdown([], lowerBounds: [1]), [0, 0])
        XCTAssertEqual(M.breakdown([.nan, 2], lowerBounds: [1]), [1, 0])
    }

    // MARK: - Day arithmetic

    func testDayArithmeticIsCalendarExact() {
        XCTAssertEqual(M.addDays("2024-02-28", 1), "2024-02-29")
        XCTAssertEqual(M.addDays("2023-12-31", 1), "2024-01-01")
        XCTAssertEqual(M.daysBetween("2026-03-31", "2026-09-26"), 179)
        XCTAssertNil(M.daysBetween("2026-02-30", "2026-03-01"))
    }
}
