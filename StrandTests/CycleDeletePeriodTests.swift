import XCTest
import Foundation
import WhoopStore
@testable import Strand

/// The classic tracker's per-start delete (`SkinTempCardsView`) removed the `period_start` row alone, so the
/// flow logged for that period stayed in the store as days with no period to belong to. `deletePeriod`
/// takes the period's flow days with the start, and nothing that is not the period's.
final class CycleDeletePeriodTests: XCTestCase {

    private let source = CycleTrackingStore.sourceId

    @MainActor
    private func seeded(_ points: [MetricPoint]) async throws -> (Repository, WhoopStore) {
        let store = try await WhoopStore.inMemory()
        _ = try await store.upsertMetricSeries(points, deviceId: source)
        let repo = Repository(deviceId: "my-whoop")
        repo.setStoreForTesting(store)
        return (repo, store)
    }

    private func start(_ day: String) -> MetricPoint {
        MetricPoint(day: day, key: CycleTrackingStore.periodStartKey, value: CycleTrackingStore.loggedValue)
    }

    private func flow(_ day: String, _ value: Double) -> MetricPoint {
        MetricPoint(day: day, key: CycleTrackingStore.periodFlowKey, value: value)
    }

    private func rows(_ store: WhoopStore, _ key: String) async throws -> [String: Double] {
        let points = try await store.metricSeries(deviceId: source, key: key, from: "0000-01-01", to: "9999-12-31")
        return Dictionary(uniqueKeysWithValues: points.map { ($0.day, $0.value) })
    }

    @MainActor
    func testDeletingAStartTakesItsPeriodFlowAndNothingElse() async throws {
        let (repo, store) = try await seeded([
            start("2026-03-01"), flow("2026-03-01", 3), flow("2026-03-02", 4), flow("2026-03-04", 2),
            flow("2026-03-05", 1),   // spotting: not a period day
            flow("2026-03-06", 0),   // "no flow": a real answer, kept
            MetricPoint(day: "2026-03-02", key: "symptom_cramps", value: 1),
            start("2026-03-29"), flow("2026-03-29", 3), flow("2026-03-30", 2),
        ])

        await repo.deletePeriod(startingOn: "2026-03-01")

        let starts = try await rows(store, CycleTrackingStore.periodStartKey)
        XCTAssertEqual(Set(starts.keys), ["2026-03-29"], "only the deleted start goes")
        let flows = try await rows(store, CycleTrackingStore.periodFlowKey)
        XCTAssertEqual(flows, ["2026-03-05": 1, "2026-03-06": 0, "2026-03-29": 3, "2026-03-30": 2],
                       "the period's light-or-heavier days go; spotting, no flow and the next period stay")
        let symptoms = try await rows(store, "symptom_cramps")
        XCTAssertEqual(Set(symptoms.keys), ["2026-03-02"], "a symptom is not period history")
    }

    /// A flow day another logged start still covers is that start's, and stays.
    @MainActor
    func testAFlowDayAnotherStartCoversIsKept() async throws {
        let (repo, store) = try await seeded([
            start("2026-03-01"), start("2026-03-04"),
            flow("2026-03-03", 3), flow("2026-03-05", 3), flow("2026-03-12", 2),
        ])

        await repo.deletePeriod(startingOn: "2026-03-04")

        let flows = try await rows(store, CycleTrackingStore.periodFlowKey)
        // 03-05 is within ten days of the remaining 03-01 start; 03-12 is not, and was the deleted period's.
        XCTAssertEqual(Set(flows.keys), ["2026-03-03", "2026-03-05"])
        let starts = try await rows(store, CycleTrackingStore.periodStartKey)
        XCTAssertEqual(Set(starts.keys), ["2026-03-01"])
    }
}
