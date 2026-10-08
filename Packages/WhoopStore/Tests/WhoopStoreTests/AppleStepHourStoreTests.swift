import XCTest
import GRDB
@testable import WhoopStore

final class AppleStepHourStoreTests: XCTestCase {
    func testUpsertIsIdempotentByNaturalKey() async throws {
        let store = try await WhoopStore.inMemory()
        let n1 = try await store.upsertAppleStepHours([(ts: 1_000, steps: 120)], deviceId: "apple-health")
        XCTAssertEqual(n1, 1)

        // Re-import the same hour with a revised count → overwrite in place, still one row.
        let n2 = try await store.upsertAppleStepHours([(ts: 1_000, steps: 250)], deviceId: "apple-health")
        XCTAssertEqual(n2, 1)

        let rows = try await store.appleStepHours(deviceId: "apple-health", fromTs: 0, toTs: 10_000)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.ts, 1_000)
        XCTAssertEqual(rows.first?.steps, 250)
    }

    func testRangeReadReturnsOldestFirstWithinBoundsInclusive() async throws {
        let store = try await WhoopStore.inMemory()
        _ = try await store.upsertAppleStepHours([
            (ts: 3_600, steps: 100),   // hour 1
            (ts: 7_200, steps: 200),   // hour 2
            (ts: 10_800, steps: 300),  // hour 3
        ], deviceId: "apple-health")

        // Inclusive bounds: both edges of the range are included.
        let rows = try await store.appleStepHours(deviceId: "apple-health", fromTs: 3_600, toTs: 10_800)
        XCTAssertEqual(rows.map(\.ts), [3_600, 7_200, 10_800])
        XCTAssertEqual(rows.map(\.steps), [100, 200, 300])

        // A narrower window excludes rows outside it.
        let narrow = try await store.appleStepHours(deviceId: "apple-health", fromTs: 3_601, toTs: 10_799)
        XCTAssertEqual(narrow.map(\.ts), [7_200])

        // A different device sees no rows.
        let other = try await store.appleStepHours(deviceId: "my-whoop", fromTs: 0, toTs: 100_000)
        XCTAssertTrue(other.isEmpty)
    }

    func testUpsertPartitionsByDevice() async throws {
        let store = try await WhoopStore.inMemory()
        _ = try await store.upsertAppleStepHours([(ts: 1_000, steps: 50)], deviceId: "apple-health")
        _ = try await store.upsertAppleStepHours([(ts: 1_000, steps: 999)], deviceId: "other-device")

        let mine = try await store.appleStepHours(deviceId: "apple-health", fromTs: 0, toTs: 10_000)
        XCTAssertEqual(mine.count, 1)
        XCTAssertEqual(mine.first?.steps, 50)

        let others = try await store.appleStepHours(deviceId: "other-device", fromTs: 0, toTs: 10_000)
        XCTAssertEqual(others.count, 1)
        XCTAssertEqual(others.first?.steps, 999)
    }

    /// The iPhone pedometer banks its hours under its own id beside Apple Health's; clearing one source
    /// must remove exactly that source's hours and leave the other's intact.
    func testDeleteRemovesOnlyTheNamedDevicesHours() async throws {
        let store = try await WhoopStore.inMemory()
        _ = try await store.upsertAppleStepHours([(ts: 3_600, steps: 10), (ts: 7_200, steps: 20)],
                                                 deviceId: "iphone-pedometer")
        _ = try await store.upsertAppleStepHours([(ts: 3_600, steps: 30)], deviceId: "apple-health")

        let removed = try await store.deleteAppleStepHours(deviceId: "iphone-pedometer")
        XCTAssertEqual(removed, 2)
        let phone = try await store.appleStepHours(deviceId: "iphone-pedometer", fromTs: 0, toTs: 100_000)
        XCTAssertTrue(phone.isEmpty)
        let health = try await store.appleStepHours(deviceId: "apple-health", fromTs: 0, toTs: 100_000)
        XCTAssertEqual(health.map(\.steps), [30])

        // Deleting an absent source is an idempotent zero-row change.
        let again = try await store.deleteAppleStepHours(deviceId: "iphone-pedometer")
        XCTAssertEqual(again, 0)
    }

    /// The band's hourly estimate is rewritten for its calibration window only: a range delete removes that
    /// device's hours inside the bounds (inclusive) and leaves older hours and other devices alone.
    func testRangeDeleteRemovesOnlyThatDevicesHoursInsideTheBounds() async throws {
        let store = try await WhoopStore.inMemory()
        _ = try await store.upsertAppleStepHours([(ts: 3_600, steps: 1), (ts: 7_200, steps: 2),
                                                  (ts: 10_800, steps: 3), (ts: 14_400, steps: 4)],
                                                 deviceId: "my-whoop-noop")
        _ = try await store.upsertAppleStepHours([(ts: 7_200, steps: 50)], deviceId: "apple-health")

        let removed = try await store.deleteAppleStepHours(deviceId: "my-whoop-noop", fromTs: 7_200, toTs: 10_800)
        XCTAssertEqual(removed, 2)
        let band = try await store.appleStepHours(deviceId: "my-whoop-noop", fromTs: 0, toTs: 100_000)
        XCTAssertEqual(band.map(\.ts), [3_600, 14_400])
        let health = try await store.appleStepHours(deviceId: "apple-health", fromTs: 0, toTs: 100_000)
        XCTAssertEqual(health.map(\.steps), [50])
    }
}
