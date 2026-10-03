import XCTest
import Foundation
import WhoopStore
import WhoopProtocol
@testable import Strand

/// #499: `Repository.workoutRows` recomputes a strap-native row's Avg / Max HR from the strap trace, but a
/// session recorded on the phone reaches the store only when the strap offloads it. Until the trace covers
/// the workout, a row saved with both figures keeps them, so every screen that lists it (Home, the Strain
/// dive, Activity Details) prints the same Avg HR and none prints a fragment's. A row saved without them
/// reads them from the trace it has.
final class WorkoutHrCoverageTests: XCTestCase {

    private let dev = "my-whoop"

    /// A 30-minute manual session saved with Avg 150 / Max 170 (or the figures given), and the strap trace
    /// for its first `coveredMinutes` minutes at 100 bpm, then (when `restBpm` is given) the rest at that rate.
    @MainActor
    private func seeded(coveredMinutes: Int, restBpm: Int? = nil, avgHr: Int? = 150,
                        maxHr: Int? = 170) async throws -> (Repository, WorkoutRow) {
        let store = try await WhoopStore.inMemory()
        try await store.upsertDevice(id: dev, mac: nil, name: "WHOOP")
        let start = Int(Date().timeIntervalSince1970) - 7_200
        let row = WorkoutRow(startTs: start, endTs: start + 1_800, sport: "Running", source: "manual",
                             durationS: 1_800, energyKcal: 300, avgHr: avgHr, maxHr: maxHr, strain: 50,
                             distanceM: nil, zonesJSON: nil, notes: nil, steps: nil)
        _ = try await store.upsertWorkouts([row], deviceId: dev)
        var hr = (0..<(coveredMinutes * 60)).map { HRSample(ts: start + $0, bpm: 100) }
        if let restBpm {
            hr += ((coveredMinutes * 60)...1_800).map { HRSample(ts: start + $0, bpm: restBpm) }
        }
        try await store.insert(Streams(hr: hr), deviceId: dev)
        let repo = Repository(deviceId: dev)
        repo.setStoreForTesting(store)
        return (repo, row)
    }

    /// Ten minutes of a thirty-minute session offloaded so far: the saved figures stand.
    @MainActor
    func testAFragmentOfTheTraceKeepsTheSavedFigures() async throws {
        let (repo, saved) = try await seeded(coveredMinutes: 10)
        let rows = await repo.workoutRows()
        let shown = try XCTUnwrap(rows.first { $0.startTs == saved.startTs })
        XCTAssertEqual(shown.avgHr, 150, "a fragment's 100 bpm average must not replace the saved 150")
        XCTAssertEqual(shown.maxHr, 170)
    }

    /// A retro entry, saved with no heart rate, has no figures to keep: a partial trace fills both.
    @MainActor
    func testARowSavedWithoutHeartRateReadsAPartialTrace() async throws {
        let (repo, saved) = try await seeded(coveredMinutes: 10, avgHr: nil, maxHr: nil)
        let rows = await repo.workoutRows()
        let shown = try XCTUnwrap(rows.first { $0.startTs == saved.startTs })
        XCTAssertEqual(shown.avgHr, 100)
        XCTAssertEqual(shown.maxHr, 100)
    }

    /// A retro entry's typed Avg HR (it stores no Max) gives way to the trace it is charted from, partial
    /// or not, so the figure cannot contradict the graph and zones beside it (#499).
    @MainActor
    func testATypedAverageGivesWayToAPartialTrace() async throws {
        let (repo, saved) = try await seeded(coveredMinutes: 10, avgHr: 150, maxHr: nil)
        let rows = await repo.workoutRows()
        let shown = try XCTUnwrap(rows.first { $0.startTs == saved.startTs })
        XCTAssertEqual(shown.avgHr, 100, "a hand-typed 150 must not stand beside a 100 bpm trace")
        XCTAssertEqual(shown.maxHr, 100)
    }

    /// Once the trace covers the session, it is the source again (the #499 rule a hand edit cannot break).
    @MainActor
    func testATraceCoveringTheWorkoutReplacesTheSavedFigures() async throws {
        let (repo, saved) = try await seeded(coveredMinutes: 10, restBpm: 130)
        let rows = await repo.workoutRows()
        let shown = try XCTUnwrap(rows.first { $0.startTs == saved.startTs })
        // 600 s at 100 and 1,201 s at 130 (both ends included).
        XCTAssertEqual(shown.avgHr, Int((Double(600 * 100 + 1_201 * 130) / 1_801).rounded()))
        XCTAssertEqual(shown.maxHr, 130)
    }

    /// The threshold, in the minutes `HRWindowStats.minutes` counts: 27 of 30 stands for the workout, 26
    /// does not. Activity Details reads the same constant to choose which heart rate it draws.
    func testTheTraceStandsForTheWorkoutFromNinetyPercentOfItsMinutes() {
        XCTAssertTrue(Repository.traceCoversWorkout(coveredMinutes: 27, startTs: 0, endTs: 1_800))
        XCTAssertFalse(Repository.traceCoversWorkout(coveredMinutes: 26, startTs: 0, endTs: 1_800))
        // A window shorter than a minute is one minute long.
        XCTAssertTrue(Repository.traceCoversWorkout(coveredMinutes: 1, startTs: 0, endTs: 20))
        XCTAssertEqual(Repository.workoutTraceFullCoverage, 0.9)
    }
}
