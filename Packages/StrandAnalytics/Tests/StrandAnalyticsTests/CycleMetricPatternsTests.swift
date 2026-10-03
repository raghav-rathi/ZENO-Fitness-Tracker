import XCTest
@testable import StrandAnalytics

final class CycleMetricPatternsTests: XCTestCase {

    private typealias C = CycleMetricPatterns

    private func day(_ base: String, _ offset: Int) -> String { MenstrualCycleModel.shift(base, by: offset)! }

    // MARK: - Phase comparison

    /// 28 days: the 14 luteal days run 6 bpm higher than the rest.
    private func lutealHigher() -> (values: [String: Double], phases: [String: MenstrualCycleModel.Phase]) {
        var values: [String: Double] = [:]
        var phases: [String: MenstrualCycleModel.Phase] = [:]
        for i in 0..<28 {
            let d = day("2026-09-01", i)
            let luteal = i >= 14
            phases[d] = luteal ? .luteal : (i < 5 ? .menstrual : .follicular)
            values[d] = (luteal ? 60 : 54) + Double(i % 2)
        }
        return (values, phases)
    }

    func testHigherInThePhase() {
        let (values, phases) = lutealHigher()
        let c = C.compare(values: values, phaseByDay: phases, phase: .luteal)!
        XCTAssertEqual(c.direction, .higher)
        XCTAssertEqual(c.phaseDays, 14)
        XCTAssertEqual(c.phaseMean, 60.5, accuracy: 1e-9)
        XCTAssertEqual(c.overallMean, 57.5, accuracy: 1e-9)
        XCTAssertEqual(C.compare(values: values, phaseByDay: phases, phase: .follicular)!.direction, .lower)
    }

    func testFlatMetricIsTypical() {
        let (higher, phases) = lutealHigher()
        let flat = higher.mapValues { _ in 55.0 }
        XCTAssertEqual(C.compare(values: flat, phaseByDay: phases, phase: .luteal)!.direction, .typical)
    }

    func testTooFewDaysIsNil() {
        let (values, phases) = lutealHigher()
        // Ovulatory has no days here.
        XCTAssertNil(C.compare(values: values, phaseByDay: phases, phase: .ovulatory))
        let few = Dictionary(uniqueKeysWithValues: phases.prefix(10).map { ($0.key, $0.value) })
        XCTAssertNil(C.compare(values: values, phaseByDay: few, phase: .luteal))
    }

    func testMissingValuesAreSkippedNotZero() {
        let (complete, phases) = lutealHigher()
        var values = complete
        values[day("2026-09-01", 20)] = nil
        values[day("2026-09-01", 21)] = .nan
        let c = C.compare(values: values, phaseByDay: phases, phase: .luteal)!
        XCTAssertEqual(c.phaseDays, 12)
        XCTAssertGreaterThan(c.phaseMean, 59, "a missing night never pulls the mean towards zero")
    }

    // MARK: - Cycle series

    func testCurrentSeriesIsSmoothedDeviationFromBaseline() {
        // Constant 50 except one day at 56: the smoothed curve spreads it over its neighbours.
        var values: [String: Double] = [:]
        for i in 0..<10 { values[day("2026-09-01", i)] = 50 }
        values[day("2026-09-01", 4)] = 56
        let s = C.cycleSeries(values: values, cycleStarts: ["2026-09-01"], today: day("2026-09-01", 9),
                              relativeToZero: false)!
        XCTAssertEqual(s.baseline, 50.6, accuracy: 1e-9)
        XCTAssertEqual(s.current.count, 10)
        XCTAssertEqual(s.current[0].cycleDay, 1)
        XCTAssertEqual(s.current[4].value, 52 - 50.6, accuracy: 1e-9)       // (50 + 56 + 50) / 3
        XCTAssertEqual(s.current[0].value, 50 - 50.6, accuracy: 1e-9)       // edge: (50 + 50) / 2
        XCTAssertTrue(s.expected.isEmpty)
        XCTAssertEqual(s.previousCycles, 0)
    }

    func testRelativeSeriesKeepsZeroBaseline() {
        let values = [day("2026-09-01", 0): 0.2, day("2026-09-01", 1): 0.4]
        let s = C.cycleSeries(values: values, cycleStarts: ["2026-09-01"], today: "2026-09-02",
                              relativeToZero: true)!
        XCTAssertEqual(s.baseline, 0)
        XCTAssertEqual(s.current.count, 2)
        // Both edge days average the same two nights (tomorrow is never read).
        XCTAssertEqual(s.current[0].value, 0.3, accuracy: 1e-9)
        XCTAssertEqual(s.current[1].value, 0.3, accuracy: 1e-9)
    }

    func testMissingDayIsSkipped() {
        let values = [day("2026-09-01", 0): 1.0, day("2026-09-01", 2): 1.0]
        let s = C.cycleSeries(values: values, cycleStarts: ["2026-09-01"], today: "2026-09-03",
                              relativeToZero: true)!
        XCTAssertEqual(s.current.map(\.cycleDay), [1, 3])
    }

    func testExpectedTrendNeedsTwoPreviousCycles() {
        var values: [String: Double] = [:]
        let starts = ["2026-06-01", "2026-06-29", "2026-07-27", "2026-08-24"]
        // Every cycle rises by a degree-ish on days 15-28.
        for s in starts.dropLast() {
            for i in 0..<28 { values[day(s, i)] = i >= 14 ? 0.4 : -0.2 }
        }
        for i in 0..<10 { values[day("2026-08-24", i)] = -0.2 }
        let s = C.cycleSeries(values: values, cycleStarts: starts, today: day("2026-08-24", 9),
                              relativeToZero: true)!
        XCTAssertEqual(s.previousCycles, 3)
        XCTAssertEqual(s.expected.count, 28)
        XCTAssertEqual(s.expected[19].value, 0.4, accuracy: 1e-9)
        XCTAssertEqual(s.expected[4].value, -0.2, accuracy: 1e-9)

        let one = C.cycleSeries(values: values, cycleStarts: Array(starts.suffix(2)), today: day("2026-08-24", 9),
                                relativeToZero: true)!
        XCTAssertEqual(one.previousCycles, 1)
        XCTAssertTrue(one.expected.isEmpty)
    }

    func testImplausiblePreviousCycleIsNotAveraged() {
        let starts = ["2026-01-01", "2026-04-01", "2026-04-29", "2026-05-27"]
        var values: [String: Double] = [:]
        for i in 0..<160 { values[day("2026-01-01", i)] = 0.1 }
        let s = C.cycleSeries(values: values, cycleStarts: starts, today: "2026-06-01", relativeToZero: true)!
        XCTAssertEqual(s.previousCycles, 2)
    }

    func testNoCurrentCycleIsNil() {
        XCTAssertNil(C.cycleSeries(values: [:], cycleStarts: [], today: "2026-09-01", relativeToZero: true))
        XCTAssertNil(C.cycleSeries(values: [:], cycleStarts: ["2026-09-05"], today: "2026-09-01",
                                   relativeToZero: true))
    }
}
