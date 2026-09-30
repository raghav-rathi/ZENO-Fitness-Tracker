import XCTest
@testable import StrandAnalytics

/// The illness heads-up's skin-temperature input reads DEVIATIONS only: the same column holds an imported
/// night's absolute wrist temperature (#622).
final class IllnessSkinTempTests: XCTestCase {

    func testAbsoluteImportedValuesAreNotASignal() {
        XCTAssertNil(IllnessSignalEngine.recentSkinTempDeviation([33.2, 33.5]))
        XCTAssertNil(IllnessSignalEngine.skinTempReading(recentValues: [33.2, 33.5]),
                     "two imported nights used to read as z ≈ 111")
    }

    func testOnlyTheDeviationsInAMixedWindowCount() throws {
        let reading = try XCTUnwrap(IllnessSignalEngine.skinTempReading(recentValues: [33.4, 0.6]))
        XCTAssertEqual(reading.zIllnessward, 2, accuracy: 1e-9)
        XCTAssertTrue(reading.present)
    }

    func testDeviationsAverageAndScaleByOneSpread() throws {
        XCTAssertEqual(try XCTUnwrap(IllnessSignalEngine.recentSkinTempDeviation([0.3, 0.9, nil])), 0.6,
                       accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(IllnessSignalEngine.skinTempReading(recentValues: [-0.3, -0.3])).zIllnessward,
                       -1, accuracy: 1e-9, "a cooler night is not illness-ward")
        XCTAssertNil(IllnessSignalEngine.recentSkinTempDeviation([nil, .nan]))
    }

    /// End to end: an elevated resting HR alone must not raise just because an imported absolute skin
    /// temperature sits in the window — that import used to supply the second corroborating signal.
    func testAnImportedNightCannotCorroborateAnotherSignal() {
        let rhr = IllnessSignalEngine.SignalReading(zIllnessward: 3.5)
        let skin = IllnessSignalEngine.skinTempReading(recentValues: [34.1, 33.8])
        let result = IllnessSignalEngine.evaluate(
            IllnessSignalEngine.Inputs(restingHR: rhr, skinTemp: skin),
            context: IllnessSignalEngine.Context())
        XCTAssertNotEqual(result.level, .raised)

        // The same resting HR with a genuine +0.9 °C deviation does corroborate.
        let warm = IllnessSignalEngine.skinTempReading(recentValues: [0.9, 0.9])
        let corroborated = IllnessSignalEngine.evaluate(
            IllnessSignalEngine.Inputs(restingHR: rhr, skinTemp: warm),
            context: IllnessSignalEngine.Context())
        XCTAssertEqual(corroborated.level, .raised)
    }
}
