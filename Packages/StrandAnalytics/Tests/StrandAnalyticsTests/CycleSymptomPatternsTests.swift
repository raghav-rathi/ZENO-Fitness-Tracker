import XCTest
@testable import StrandAnalytics

final class CycleSymptomPatternsTests: XCTestCase {

    private typealias P = CycleSymptomPatterns

    private func day(_ base: String, _ offset: Int) -> String { MenstrualCycleModel.shift(base, by: offset)! }

    /// Three 28-day cycles; cramps logged on cycle days 1-2 of every cycle, a headache on day 2 of one.
    private func threeCycles() -> (symptoms: [String: Set<String>], cycles: [(start: String, length: Int)]) {
        let starts = ["2026-06-01", "2026-06-29", "2026-07-27"]
        var symptoms: [String: Set<String>] = [:]
        for s in starts {
            symptoms[day(s, 0), default: []].insert("cramps")
            symptoms[day(s, 1), default: []].insert("cramps")
        }
        symptoms[day(starts[0], 1), default: []].insert("headache")
        return (symptoms, starts.map { ($0, 28) })
    }

    func testPredictsWhatCameUpInMostCycles() {
        let (symptoms, cycles) = threeCycles()
        let r = P.predictions(symptomDays: symptoms, completedCycles: cycles, cycleDay: 2)
        XCTAssertEqual(r.readiness, .ready)
        XCTAssertEqual(r.predictions, [P.Prediction(symptom: "cramps", cycles: 3, ofCycles: 3)])
        XCTAssertEqual(r.predictions.first?.share, 1)
    }

    func testWindowIsADayEitherSide() {
        let (symptoms, cycles) = threeCycles()
        XCTAssertEqual(P.predictions(symptomDays: symptoms, completedCycles: cycles, cycleDay: 3).predictions.map(\.symptom),
                       ["cramps"], "day 2 is within a day of day 3")
        XCTAssertTrue(P.predictions(symptomDays: symptoms, completedCycles: cycles, cycleDay: 4).predictions.isEmpty)
    }

    func testOneOffSymptomIsNotPredicted() {
        let (symptoms, cycles) = threeCycles()
        let r = P.predictions(symptomDays: symptoms, completedCycles: cycles, cycleDay: 2)
        XCTAssertFalse(r.predictions.contains { $0.symptom == "headache" })
    }

    func testNeedsTwoLoggingCycles() {
        let (symptoms, cycles) = threeCycles()
        let r = P.predictions(symptomDays: symptoms, completedCycles: Array(cycles.prefix(1)), cycleDay: 2)
        XCTAssertEqual(r.readiness, .needsCycles(logged: 1))
        XCTAssertTrue(r.predictions.isEmpty)
    }

    func testCyclesWithoutAnyLogDoNotCountAgainst() {
        var (symptoms, cycles) = threeCycles()
        // Two more cycles with nothing logged at all: they say nothing, so cramps stays at 3 of 3.
        cycles.append(("2026-08-24", 28))
        cycles.append(("2026-09-21", 28))
        let r = P.predictions(symptomDays: symptoms, completedCycles: cycles, cycleDay: 1)
        XCTAssertEqual(r.predictions.first, P.Prediction(symptom: "cramps", cycles: 3, ofCycles: 3))
        // One logged cycle WITHOUT cramps lowers the share but keeps it over half.
        symptoms[day("2026-08-24", 20)] = ["bloating"]
        let r2 = P.predictions(symptomDays: symptoms, completedCycles: cycles, cycleDay: 1)
        XCTAssertEqual(r2.predictions.first, P.Prediction(symptom: "cramps", cycles: 3, ofCycles: 4))
    }

    func testShortCyclesDoNotCountForLateDays() {
        let (symptoms, cycles) = threeCycles()
        let short = cycles.map { ($0.start, 20) }
        let r = P.predictions(symptomDays: symptoms, completedCycles: short, cycleDay: 25)
        XCTAssertEqual(r.readiness, .ready)
        XCTAssertTrue(r.predictions.isEmpty)
    }

    func testSummaryCountsDaysAndFindsThePhase() {
        let symptoms: [String: Set<String>] = [
            "2026-09-01": ["cramps", "bloating"],
            "2026-09-02": ["cramps"],
            "2026-09-20": ["bloating"],
            "2026-09-21": ["bloating"],
            "2026-08-01": ["cramps"],          // before `from`
        ]
        let phases: [String: MenstrualCycleModel.Phase] = [
            "2026-09-01": .menstrual, "2026-09-02": .menstrual, "2026-09-20": .luteal, "2026-09-21": .luteal,
        ]
        let s = P.summary(symptomDays: symptoms, phaseByDay: phases, from: "2026-08-15", to: "2026-09-30")
        XCTAssertEqual(s, [
            P.Summary(symptom: "bloating", days: 3, phase: .luteal, phaseDays: 2),
            P.Summary(symptom: "cramps", days: 2, phase: .menstrual, phaseDays: 2),
        ])
    }

    func testSummaryWithoutPhasesHasNone() {
        let s = P.summary(symptomDays: ["2026-09-01": ["hotFlashes"]], phaseByDay: [:],
                          from: "2026-09-01", to: "2026-09-30")
        XCTAssertEqual(s, [P.Summary(symptom: "hotFlashes", days: 1, phase: nil, phaseDays: 0)])
    }
}
