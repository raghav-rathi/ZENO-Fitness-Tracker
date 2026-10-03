import XCTest
@testable import StrandAnalytics

final class PulseCycleOverlayTests: XCTestCase {

    /// Nights from `start` with the temperature z-score `pattern` gives, one per day.
    private func nights(from start: String, count: Int, pattern: (Int) -> Double?) -> [CyclePhaseEngine.Night] {
        (0..<count).map { i in
            CyclePhaseEngine.Night(day: PulseTrendMath.addDays(start, i), tempZ: pattern(i), rhrZ: nil, hrvZ: nil)
        }
    }

    /// Two and a bit 28-day cycles: 14 low nights, then 14 high ones.
    private func twoCycles() -> [CyclePhaseEngine.Night] {
        nights(from: "2026-06-01", count: 70) { i in (i % 28) < 14 ? -1.0 : 1.0 }
    }

    func testElevatedNightsAreLutealAndTheRestFollicular() {
        let phases = PulseCycleOverlay.phases(nights: twoCycles(), baselineUsable: true)
        XCTAssertEqual(phases["2026-06-05"], .follicular)
        XCTAssertEqual(phases["2026-06-22"], .luteal)
        XCTAssertEqual(phases.count, 70)
    }

    func testDaysAroundEachShiftOnsetAreOvulatory() {
        let phases = PulseCycleOverlay.phases(nights: twoCycles(), baselineUsable: true)
        // The first shift onset is night 14 (2026-06-15): two days either side read ovulatory.
        for day in ["2026-06-13", "2026-06-14", "2026-06-15", "2026-06-16", "2026-06-17"] {
            XCTAssertEqual(phases[day], .ovulatory, day)
        }
        XCTAssertEqual(phases["2026-06-12"], .follicular)
        XCTAssertEqual(phases["2026-06-18"], .luteal)
    }

    func testALoggedPeriodStartMarksItsDaysMenstrual() {
        let phases = PulseCycleOverlay.phases(nights: twoCycles(), baselineUsable: true,
                                              loggedPeriodStarts: ["2026-06-29"])
        for day in ["2026-06-29", "2026-06-30", "2026-07-01", "2026-07-02", "2026-07-03"] {
            XCTAssertEqual(phases[day], .menstrual, day)
        }
        XCTAssertEqual(phases["2026-07-04"], .follicular)
    }

    func testNoPhasesWhileTheEngineIsLearningOrHasNoPattern() {
        // Too few nights to classify.
        let short = nights(from: "2026-06-01", count: 20) { i in i < 10 ? -1.0 : 1.0 }
        XCTAssertTrue(PulseCycleOverlay.phases(nights: short, baselineUsable: true).isEmpty)
        // A baseline that is not usable yet.
        XCTAssertTrue(PulseCycleOverlay.phases(nights: twoCycles(), baselineUsable: false).isEmpty)
        // A flat series has no shift to read.
        let flat = nights(from: "2026-06-01", count: 70) { _ in 0.0 }
        XCTAssertTrue(PulseCycleOverlay.phases(nights: flat, baselineUsable: true).isEmpty)
    }

    func testANightWithoutAReadingHasNoPhaseAndAOneNightDipStaysLuteal() {
        var series = twoCycles()
        // Night 20 (luteal) unread, night 22 dips below the gate inside the run.
        series[20] = CyclePhaseEngine.Night(day: series[20].day, tempZ: nil, rhrZ: nil, hrvZ: nil)
        series[22] = CyclePhaseEngine.Night(day: series[22].day, tempZ: -1.0, rhrZ: nil, hrvZ: nil)
        let phases = PulseCycleOverlay.phases(nights: series, baselineUsable: true)
        XCTAssertNil(phases[series[20].day])
        XCTAssertEqual(phases[series[22].day], .luteal)
    }

    func testNightsAreBuiltFromRawReadingsLikeTheCyclePass() {
        let readings = (0..<30).map { i in
            PulseCycleOverlay.Reading(day: PulseTrendMath.addDays("2026-06-01", i),
                                      skinTempDevC: i % 2 == 0 ? 0.3 : -0.3, restingHR: 55, hrv: nil)
        }
        let built = PulseCycleOverlay.nights(readings.reversed())
        XCTAssertEqual(built.nights.count, 30)
        XCTAssertEqual(built.nights.first?.day, "2026-06-01")
        XCTAssertNotNil(built.nights.first?.tempZ)
        XCTAssertNil(built.nights.first?.hrvZ)
    }
}
