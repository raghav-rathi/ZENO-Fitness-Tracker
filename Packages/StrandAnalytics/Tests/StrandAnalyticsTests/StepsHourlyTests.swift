import XCTest
@testable import StrandAnalytics

/// Hourly bucketing of step rows into a LOCAL calendar day, including the two DST days, and the live
/// current-hour reconcile. A fixed zone (New York, UTC−4/−5) keeps the expectations deterministic.
final class StepsHourlyTests: XCTestCase {

    private let newYork: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    /// Unix seconds for an ISO-8601 instant with an explicit offset — an independent oracle for the
    /// calendar arithmetic under test.
    private func ts(_ iso: String) -> Int {
        Int(ISO8601DateFormatter().date(from: iso)!.timeIntervalSince1970)
    }

    func testDayBoundsAreLocalMidnightToLocalMidnight() {
        let b = StepsHourly.dayBounds(day: "2026-09-29", calendar: newYork)
        XCTAssertEqual(b?.start, ts("2026-09-29T00:00:00-04:00"))
        XCTAssertEqual(b?.end, ts("2026-09-30T00:00:00-04:00"))
    }

    func testDayBoundsRejectMalformedAndImpossibleKeys() {
        XCTAssertNil(StepsHourly.dayBounds(day: "2026-02-31", calendar: newYork))
        XCTAssertNil(StepsHourly.dayBounds(day: "2026-9-29", calendar: newYork))
        XCTAssertNil(StepsHourly.dayBounds(day: "not-a-day", calendar: newYork))
        XCTAssertNil(StepsHourly.dayBounds(day: "", calendar: newYork))
    }

    func testHourStartsCoverTheDayIncludingDSTDays() {
        let normal = StepsHourly.hourStarts(day: "2026-09-29", calendar: newYork)
        XCTAssertEqual(normal.count, 24)
        XCTAssertEqual(normal.first, ts("2026-09-29T00:00:00-04:00"))
        XCTAssertEqual(normal.last, ts("2026-09-29T23:00:00-04:00"))
        // Spring forward (8 Mar 2026): 02:00 does not exist, so the day is 23 hours long.
        XCTAssertEqual(StepsHourly.hourStarts(day: "2026-03-08", calendar: newYork).count, 23)
        // Fall back (1 Nov 2026): 01:00 happens twice, so the day is 25 hours long.
        XCTAssertEqual(StepsHourly.hourStarts(day: "2026-11-01", calendar: newYork).count, 25)
        XCTAssertEqual(StepsHourly.hourStarts(day: "bogus", calendar: newYork), [])
    }

    func testBucketsSumRowsIntoLocalClockHours() {
        let rows: [(ts: Int, steps: Int)] = [
            (ts("2026-09-29T00:00:00-04:00"), 12),
            (ts("2026-09-29T08:00:00-04:00"), 1_500),
            (ts("2026-09-29T08:30:00-04:00"), 100),   // same clock hour, summed
            (ts("2026-09-29T23:00:00-04:00"), 40),
            (ts("2026-09-28T23:00:00-04:00"), 9_999), // the day before: ignored
            (ts("2026-09-30T00:00:00-04:00"), 9_999), // the day after: ignored
            (ts("2026-09-29T12:00:00-04:00"), -50),   // not a count: ignored
        ]
        let b = StepsHourly.buckets(rows: rows, day: "2026-09-29", calendar: newYork)
        XCTAssertEqual(b.count, 24)
        XCTAssertEqual(b[0], 12)
        XCTAssertEqual(b[8], 1_600)
        XCTAssertEqual(b[12], 0)
        XCTAssertEqual(b[23], 40)
        XCTAssertEqual(b.reduce(0, +), 1_652)
    }

    func testBucketsUseTheCalendarsZoneNotUTC() {
        // 02:00Z on the 30th is 22:00 on the 29th in New York: it belongs to the 29th's last hours.
        let row = (ts: ts("2026-09-30T02:00:00Z"), steps: 300)
        XCTAssertEqual(StepsHourly.buckets(rows: [row], day: "2026-09-29", calendar: newYork)[22], 300)
        XCTAssertEqual(StepsHourly.buckets(rows: [row], day: "2026-09-30", calendar: newYork).reduce(0, +), 0)
    }

    func testFallBackDaySumsTheRepeatedHourIntoOneBucket() {
        let first = ts("2026-11-01T01:00:00-04:00")    // 01:00 EDT
        let second = ts("2026-11-01T01:00:00-05:00")   // 01:00 EST, one hour later
        XCTAssertEqual(second - first, 3_600)
        let b = StepsHourly.buckets(rows: [(first, 70), (second, 30)], day: "2026-11-01", calendar: newYork)
        XCTAssertEqual(b.count, 24)
        XCTAssertEqual(b[1], 100)
    }

    func testSpringForwardDayLeavesTheMissingHourEmpty() {
        let starts = StepsHourly.hourStarts(day: "2026-03-08", calendar: newYork)
        let rows = starts.map { (ts: $0, steps: 10) }
        let b = StepsHourly.buckets(rows: rows, day: "2026-03-08", calendar: newYork)
        XCTAssertEqual(b[2], 0)
        XCTAssertEqual(b.reduce(0, +), 230)
    }

    func testReconcileLetsTheCurrentHourAbsorbAFresherTotal() {
        var buckets = Array(repeating: 0, count: 24)
        buckets[8] = 1_000; buckets[9] = 200; buckets[10] = 50
        // Live total says 1,600 at 10:xx: hour 10 takes the 350 the finished hours do not explain.
        let out = StepsHourly.reconcilingCurrentHour(buckets, dayTotal: 1_600, currentHour: 10)
        XCTAssertEqual(out[10], 400)
        XCTAssertEqual(out.reduce(0, +), 1_600)
        XCTAssertEqual(out[11], 0)
    }

    func testReconcileNeverShrinksTheCurrentHour() {
        var buckets = Array(repeating: 0, count: 24)
        buckets[9] = 500; buckets[10] = 300
        let out = StepsHourly.reconcilingCurrentHour(buckets, dayTotal: 600, currentHour: 10)
        XCTAssertEqual(out, buckets)
        // Nor go negative when the finished hours already exceed the total.
        let over = StepsHourly.reconcilingCurrentHour([900] + Array(repeating: 0, count: 23), dayTotal: 100, currentHour: 5)
        XCTAssertEqual(over[5], 0)
    }

    func testReconcileIgnoresAnOutOfRangeHour() {
        let buckets = Array(repeating: 1, count: 24)
        XCTAssertEqual(StepsHourly.reconcilingCurrentHour(buckets, dayTotal: 999, currentHour: 24), buckets)
        XCTAssertEqual(StepsHourly.reconcilingCurrentHour(buckets, dayTotal: 999, currentHour: -1), buckets)
    }

    // MARK: Chart composition

    private func hours(_ pairs: [Int: Int]) -> [Int] {
        var out = Array(repeating: 0, count: 24)
        for (h, v) in pairs { out[h] = v }
        return out
    }

    func testChartDrawsTheDaysOwnSourceAndReconcilesTheLiveHour() {
        let phone = hours([8: 1_000, 9: 200])
        let chart = StepsHourly.chart(daySource: .phonePedometer, dayTotal: 1_500,
                                      hours: [.phonePedometer: phone, .healthKit: hours([8: 900])],
                                      currentHour: 9)
        XCTAssertEqual(chart?.source, .phonePedometer)
        XCTAssertEqual(chart?.matchesDaySource, true)
        XCTAssertEqual(chart?.bars[9], 500)
        XCTAssertEqual(chart?.bars.reduce(0, +), 1_500)
        XCTAssertEqual(chart?.currentHour, 9)
        XCTAssertEqual(chart?.peakHour, 8)
    }

    func testChartBorrowsAnotherSourcesShapeWithoutReconcilingIt() {
        // The day resolved to the strap estimate; the phone's hours are only a shape and must not be
        // stretched to the estimate's total.
        let phone = hours([12: 300])
        let chart = StepsHourly.chart(daySource: .strapEstimate, dayTotal: 9_000,
                                      hours: [.phonePedometer: phone], currentHour: 12)
        XCTAssertEqual(chart?.source, .phonePedometer)
        XCTAssertEqual(chart?.matchesDaySource, false)
        XCTAssertEqual(chart?.bars, phone)
    }

    func testPastDayChartIsNotReconciled() {
        let phone = hours([7: 400])
        let chart = StepsHourly.chart(daySource: .phonePedometer, dayTotal: 5_000,
                                      hours: [.phonePedometer: phone], currentHour: nil)
        XCTAssertEqual(chart?.bars, phone)
        XCTAssertNil(chart?.currentHour)
    }

    func testNoHoursMeansNoChart() {
        XCTAssertNil(StepsHourly.chart(daySource: .healthKit, dayTotal: 5_000, hours: [:], currentHour: 10))
        // A malformed bucket array is not a chart either.
        XCTAssertNil(StepsHourly.chart(daySource: .phonePedometer, dayTotal: 5,
                                       hours: [.phonePedometer: [1, 2, 3]], currentHour: nil))
        XCTAssertNil(StepsHourly.Chart(bars: Array(repeating: 0, count: 24), source: .healthKit,
                                       matchesDaySource: true, currentHour: nil).peakHour)
    }
}
