import XCTest
@testable import StrandAnalytics

final class HealthspanBreakdownTests: XCTestCase {

    /// A week with all five factors the weekly pass scores.
    private func week(chrono: Double = 35, rhr: Double = 58, sleep: Double = 7.2, consistency: Double = 0.9,
                      rmssd: Double = 50, steps: Double = 8_000) -> VitalityEngine.Inputs {
        VitalityEngine.Inputs(chronoAge: chrono, restingHR: rhr, sleepHours: sleep, sleepConsistency: consistency,
                              rmssd: rmssd, rmssdNorm: VitalityEngine.rmssdNorm(forAge: chrono), steps: steps)
    }

    /// The rows and the orb agree: a breakdown of the inputs the pass scored adds up to the stored gap.
    func testBreakdownOfTheScoredInputsAddsUpToTheStoredGap() throws {
        let inputs = week()
        let stored = try XCTUnwrap(VitalityEngine.compute(inputs)).bodyAge
        let years = try XCTUnwrap(HealthspanBreakdown.years(inputs, storedBodyAge: stored))
        XCTAssertEqual(years.values.reduce(0, +), stored - inputs.chronoAge, accuracy: 1e-9)
        XCTAssertEqual(Set(years.keys), ["rhr", "sleep", "consistency", "hrv", "steps"])
    }

    /// Each factor's years are the engine's own conversion of its log-hazard.
    func testEachFactorIsTheEnginesYears() throws {
        let inputs = week(rhr: 70, sleep: 6.0, consistency: 0.6, rmssd: 30, steps: 4_000)
        let result = try XCTUnwrap(VitalityEngine.compute(inputs))
        let years = try XCTUnwrap(HealthspanBreakdown.years(inputs, storedBodyAge: result.bodyAge))
        for c in result.contributions {
            XCTAssertEqual(years[c.key] ?? .nan, VitalityEngine.years(for: c), accuracy: 1e-12)
        }
    }

    /// A stored value rounded to one decimal (as a seeded or exported value is) still matches.
    func testRoundedStoredValueStillMatches() throws {
        let inputs = week(rhr: 52, sleep: 8.1, consistency: 0.85, rmssd: 61, steps: 10_500)
        let exact = try XCTUnwrap(VitalityEngine.compute(inputs)).bodyAge
        let rounded = (exact * 10).rounded() / 10
        XCTAssertNotNil(HealthspanBreakdown.years(inputs, storedBodyAge: rounded))
    }

    /// A stale or foreign stored value: the rows would not add up to the orb, so there is no breakdown.
    func testStoredValueFromOtherInputsHasNoBreakdown() throws {
        let inputs = week()
        let stored = try XCTUnwrap(VitalityEngine.compute(inputs)).bodyAge
        XCTAssertNil(HealthspanBreakdown.years(inputs, storedBodyAge: stored + 0.5))
        XCTAssertNil(HealthspanBreakdown.years(inputs, storedBodyAge: stored - 4.1))
        let olderWeek = week(rhr: 66, sleep: 6.4, consistency: 0.7, rmssd: 38, steps: 5_000)
        let otherStored = try XCTUnwrap(VitalityEngine.compute(olderWeek)).bodyAge
        XCTAssertNil(HealthspanBreakdown.years(inputs, storedBodyAge: otherStored))
    }

    /// When the age clamp moved the stored age, the factors add up to more than the gap shown.
    func testClampedAgeHasNoBreakdown() throws {
        let inputs = week(chrono: 21, rhr: 40, sleep: 7.5, consistency: 1.0, rmssd: 120, steps: 12_000)
        let result = try XCTUnwrap(VitalityEngine.compute(inputs))
        XCTAssertEqual(result.bodyAge, VitalityEngine.minBodyAge, accuracy: 1e-12)
        let summed = result.contributions.map(VitalityEngine.years(for:)).reduce(0, +)
        XCTAssertLessThan(summed, result.bodyAge - inputs.chronoAge - 1)
        XCTAssertNil(HealthspanBreakdown.years(inputs, storedBodyAge: result.bodyAge))
    }

    /// Too few factors for the engine to score: nothing to break down, whatever is stored.
    func testTooFewFactorsHasNoBreakdown() {
        let inputs = VitalityEngine.Inputs(chronoAge: 35, restingHR: 58, sleepHours: 7.2)
        XCTAssertNil(VitalityEngine.compute(inputs))
        XCTAssertNil(HealthspanBreakdown.years(inputs, storedBodyAge: 34))
    }

    func testNonFiniteStoredValueHasNoBreakdown() {
        XCTAssertNil(HealthspanBreakdown.years(week(), storedBodyAge: .nan))
        XCTAssertNil(HealthspanBreakdown.years(week(), storedBodyAge: .infinity))
    }
}
