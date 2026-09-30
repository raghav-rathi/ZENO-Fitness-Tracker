import XCTest
@testable import StrandAnalytics

/// Display/coaching zones on heart-rate reserve — the bands Effort is scored in and WHOOP uses.
final class HRReserveZonesTests: XCTestCase {

    private let set = HRZones.reserveZones(maxHR: 190, restingHR: 60)

    func testEdgesAreFractionsOfTheReserveAboveRest() {
        XCTAssertEqual(set.zones.map(\.lower), [125, 138, 151, 164, 177])
        XCTAssertEqual(set.zones.map(\.upper), [138, 151, 164, 177, 190])
        XCTAssertEqual(set.zones.map { ($0.lowerPct * 100).rounded() }, [50, 60, 70, 80, 90])
        XCTAssertEqual(set.restingHR, 60)
        XCTAssertEqual(set.maxHR, 190)
    }

    func testZoneNumbersAtAndAroundTheEdges() {
        XCTAssertEqual(set.zoneNumber(forBPM: 124), 0)
        XCTAssertEqual(set.zoneNumber(forBPM: 125), 1)
        XCTAssertEqual(set.zoneNumber(forBPM: 150), 2)
        XCTAssertEqual(set.zoneNumber(forBPM: 151), 3)
        XCTAssertEqual(set.zoneNumber(forBPM: 176), 4)
        XCTAssertEqual(set.zoneNumber(forBPM: 177), 5)
        XCTAssertEqual(set.zoneNumber(forBPM: 200), 5)
    }

    /// The zone shown for a heartbeat is the Edwards zone Effort credits it to.
    func testZonesMatchTheEffortScorersZones() {
        let rest = 58.0, max = 187.0
        let zones = HRZones.reserveZones(maxHR: max, restingHR: rest)
        for bpm in stride(from: 40.0, through: 210.0, by: 0.5) {
            let edwards = StrainScorer.zoneWeight(bpm, restingHR: rest, hrReserve: max - rest)
            // Skip the measure-zero exact edges, where the two float paths may round differently.
            let pct = (bpm - rest) / (max - rest) * 100
            let edge = [50.0, 60, 70, 80, 90].contains { abs(pct - $0) < 1e-6 }
            if !edge { XCTAssertEqual(zones.zoneNumber(forBPM: bpm), edwards, "bpm \(bpm)") }
        }
    }

    func testTheOldPercentOfMaxBandsDifferSubstantially() {
        // 130 bpm is zone 1 on reserve (125–138) but zone 2 on %HRmax (114–133).
        let percentOfMax = HRZones.zones(maxHR: 190)
        XCTAssertEqual(percentOfMax.zoneNumber(forBPM: 130), 2)
        XCTAssertEqual(set.zoneNumber(forBPM: 130), 1)
    }

    func testAnImpossibleRestingHRFallsBackToPercentOfMax() {
        for rest in [0.0, -5, 190, 200, .nan] {
            let fallback = HRZones.reserveZones(maxHR: 190, restingHR: rest)
            XCTAssertNil(fallback.restingHR, "rest \(rest)")
            XCTAssertEqual(fallback.zones.map(\.lower), HRZones.zones(maxHR: 190).zones.map(\.lower))
        }
        XCTAssertEqual(HRZones.defaultLowerBounds(maxHR: 190, restingHR: 0),
                       HRZones.defaultLowerBounds(maxHR: 190))
    }

    func testCustomBoundsStillWin() {
        let custom = HRZones.reserveZones(maxHR: 190, restingHR: 60,
                                          customLowerBounds: [100, 120, 140, 160, 175])
        XCTAssertEqual(custom.source, "custom")
        XCTAssertEqual(custom.zones.map(\.lower), [100, 120, 140, 160, 175])
        XCTAssertEqual(custom.zoneNumber(forBPM: 130), 2)
    }

    /// Seeding the custom editor with the rounded-up reserve bounds classifies every integer bpm exactly
    /// as the reserve set does, so turning custom zones on changes nothing until a bound is moved.
    func testEditorSeedMatchesTheReserveSetForIntegerBPM() {
        for (rest, max) in [(60.0, 190.0), (47.0, 183.0), (72.0, 201.0)] {
            let reserve = HRZones.reserveZones(maxHR: max, restingHR: rest)
            let seeded = HRZones.reserveZones(
                maxHR: max, restingHR: rest,
                customLowerBounds: HRZones.defaultLowerBounds(maxHR: max, restingHR: rest).map(Double.init))
            for bpm in 30...230 {
                XCTAssertEqual(seeded.zoneNumber(forBPM: Double(bpm)), reserve.zoneNumber(forBPM: Double(bpm)),
                               "rest \(rest) max \(max) bpm \(bpm)")
            }
        }
    }
}
