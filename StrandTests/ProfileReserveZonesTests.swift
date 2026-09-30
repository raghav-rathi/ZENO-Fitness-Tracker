import XCTest
import WhoopStore
import StrandAnalytics
@testable import Strand

/// The profile's display/coaching zones are heart-rate-reserve zones on the Effort HRmax and the latest
/// nightly resting HR.
@MainActor
final class ProfileReserveZonesTests: XCTestCase {

    private func day(_ key: String, rhr: Int?) -> DailyMetric {
        DailyMetric(day: key, totalSleepMin: nil, efficiency: nil, deepMin: nil, remMin: nil, lightMin: nil,
                    disturbances: nil, restingHr: rhr, avgHrv: nil, recovery: nil, strain: nil,
                    exerciseCount: nil)
    }

    private func withProfileDefaults(_ body: () throws -> Void) rethrows {
        let defaults = UserDefaults.standard
        let keys = ["profile.zoneRestingHR", "profile.hrMaxOverride", "profile.hrZoneThresholds"]
        let saved = keys.map { ($0, defaults.object(forKey: $0)) }
        defer {
            for (key, value) in saved {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        try body()
    }

    func testLatestNightlyRestingHRIsTheNewestDayThatHasOne() {
        let days = [day("2026-06-03", rhr: 58), day("2026-06-01", rhr: 55), day("2026-06-04", rhr: nil)]
        XCTAssertEqual(ProfileStore.latestNightlyRestingHR(days), 58)
        XCTAssertNil(ProfileStore.latestNightlyRestingHR([day("2026-06-01", rhr: nil)]))
    }

    func testProfileZonesAreReserveZonesOnTheEffortHRmax() {
        withProfileDefaults {
            let profile = ProfileStore()
            profile.hrMaxOverride = 190
            profile.hrZoneThresholds = []
            profile.updateZoneRestingHR(from: [day("2026-06-01", rhr: 60)])
            XCTAssertEqual(profile.zoneRestingHR, 60)
            XCTAssertEqual(profile.hrZoneSet.restingHR, 60)
            XCTAssertEqual(profile.hrZoneSet.zones.map(\.lower), [125, 138, 151, 164, 177])

            // Turning custom zones on seeds the editor with the same reserve boundaries.
            profile.setCustomHRZonesEnabled(true)
            XCTAssertEqual(profile.hrZoneThresholds, [125, 138, 151, 164, 177])
            profile.setCustomHRZonesEnabled(false)

            // No scored night yet: the Effort scorer's own 60 bpm fallback, not %HRmax.
            profile.zoneRestingHR = nil
            XCTAssertEqual(profile.hrZoneSet.restingHR, StrainScorer.defaultRestingHR)
        }
    }
}
