import XCTest
@testable import StrandAnalytics
import WhoopStore

/// The Strength Trainer's progress figures. Every expected number is worked out by hand from the rows
/// the test builds, so the screen's averages, changes and records can be checked without a simulator.
final class LiftProgressTests: XCTestCase {

    private var ord = 0

    /// A UTC Gregorian calendar whose weeks start on Monday, so month and week edges are fixed.
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2
        return cal
    }

    /// Unix seconds for a UTC date and hour.
    private func ts(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Int {
        let date = calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
        return Int(date.timeIntervalSince1970)
    }

    private func set(_ exercise: String = "Bench press", weight: Double? = 100, reps: Int? = 5,
                     warmup: Bool = false, session: String = "s") -> LiftSetRow {
        ord += 1
        return LiftSetRow(id: UUID().uuidString, deviceId: "dev", sessionId: session, ord: ord,
                          exercise: exercise, primaryMuscle: .chest, secondaryMuscles: [],
                          setIndex: ord, weightKg: weight, reps: reps, rpe: nil, isWarmup: warmup,
                          startTs: nil, endTs: nil, restSec: nil, note: nil)
    }

    private func session(_ id: String, start: Int, finished: Bool = true) -> LiftSessionRow {
        LiftSessionRow(id: id, deviceId: "dev", startTs: start, endTs: finished ? start + 3_600 : nil,
                       sport: "Strength Training", programId: nil, programName: nil, sessionRpe: nil, note: nil)
    }

    // MARK: - Session volume

    func testSessionVolumeIsTheWorkingVolumeOfEachFinishedSessionOldestFirst() {
        let later = LiftProgress.SessionSets(session: session("b", start: ts(2026, 3, 2)),
                                             sets: [set(weight: 60, reps: 10, session: "b")])
        let earlier = LiftProgress.SessionSets(session: session("a", start: ts(2026, 3, 1)),
                                               sets: [set(weight: 100, reps: 5, session: "a"),
                                                      set(weight: 40, reps: 10, warmup: true, session: "a")])
        let volumes = LiftProgress.sessionVolumes([later, earlier])
        XCTAssertEqual(volumes.map(\.sessionId), ["a", "b"])
        XCTAssertEqual(volumes[0].volumeKg, 500, accuracy: 0.001, "the warm-up is not volume")
        XCTAssertEqual(volumes[1].volumeKg, 600, accuracy: 0.001)
    }

    func testASessionWithNothingCountableOrStillRunningIsLeftOutRatherThanZero() {
        let bodyweight = LiftProgress.SessionSets(session: session("bw", start: ts(2026, 3, 1)),
                                                  sets: [set("Pull-up", weight: nil, reps: 12, session: "bw")])
        let running = LiftProgress.SessionSets(session: session("run", start: ts(2026, 3, 2), finished: false),
                                               sets: [set(weight: 100, reps: 5, session: "run")])
        XCTAssertTrue(LiftProgress.sessionVolumes([bodyweight, running]).isEmpty)
    }

    func testAnExerciseFilterCountsOnlyThatExercisesSets() {
        let mixed = LiftProgress.SessionSets(session: session("m", start: ts(2026, 3, 1)),
                                             sets: [set("Squat", weight: 120, reps: 5, session: "m"),
                                                    set("Bench press", weight: 80, reps: 8, session: "m")])
        let squat = LiftProgress.sessionVolumes([mixed], exercise: "Squat")
        XCTAssertEqual(squat.count, 1)
        XCTAssertEqual(squat[0].volumeKg, 600, accuracy: 0.001)
        XCTAssertTrue(LiftProgress.sessionVolumes([mixed], exercise: "Deadlift").isEmpty)
    }

    // MARK: - Averages and change

    func testAverageVolumeIsThePlainMeanOfTheSessionsInsideTheWindow() {
        let volumes = [
            LiftProgress.SessionVolume(sessionId: "a", startTs: 100, volumeKg: 1_000),
            LiftProgress.SessionVolume(sessionId: "b", startTs: 200, volumeKg: 2_000),
            LiftProgress.SessionVolume(sessionId: "c", startTs: 300, volumeKg: 9_000),
        ]
        XCTAssertEqual(LiftProgress.averageVolume(volumes, from: 100, to: 300)!, 1_500, accuracy: 0.001,
                       "the window is half-open: the session AT `to` belongs to the next one")
        XCTAssertNil(LiftProgress.averageVolume(volumes, from: 400, to: 500))
    }

    func testChangeIsRelativeAndNeedsAPositiveBase() {
        XCTAssertEqual(LiftProgress.change(from: 5_122, to: 5_773)!, 0.1271, accuracy: 0.0001)
        XCTAssertEqual(LiftProgress.change(from: 6_000, to: 4_000)!, -1.0 / 3.0, accuracy: 0.0001)
        XCTAssertNil(LiftProgress.change(from: nil, to: 100))
        XCTAssertNil(LiftProgress.change(from: 100, to: nil))
        XCTAssertNil(LiftProgress.change(from: 0, to: 100))
    }

    // MARK: - Segments

    func testMonthlySegmentsAverageEachMonthSkipEmptyOnesAndCompareWithThePreviousSegment() {
        let volumes = [
            LiftProgress.SessionVolume(sessionId: "j1", startTs: ts(2026, 1, 5), volumeKg: 4_000),
            LiftProgress.SessionVolume(sessionId: "j2", startTs: ts(2026, 1, 20), volumeKg: 6_000),
            // February: nothing.
            LiftProgress.SessionVolume(sessionId: "m1", startTs: ts(2026, 3, 9), volumeKg: 5_500),
        ]
        let segments = LiftProgress.segments(volumes, from: ts(2026, 1, 1, hour: 0), to: ts(2026, 4, 1, hour: 0),
                                             bucket: .month, calendar: calendar)
        XCTAssertEqual(segments.count, 2, "an empty month is a gap, never a zero")
        XCTAssertEqual(segments[0].averageKg, 5_000, accuracy: 0.001)
        XCTAssertEqual(segments[0].sessions, 2)
        XCTAssertNil(segments[0].change, "the first segment has nothing to compare with")
        XCTAssertEqual(segments[0].from, ts(2026, 1, 1, hour: 0))
        XCTAssertEqual(segments[0].to, ts(2026, 2, 1, hour: 0))
        XCTAssertEqual(segments[1].averageKg, 5_500, accuracy: 0.001)
        XCTAssertEqual(segments[1].change!, 0.1, accuracy: 0.0001, "March against January, the last month with sessions")
    }

    func testSegmentsAreClippedToTheWindowAndIgnoreSessionsOutsideIt() {
        let volumes = [
            LiftProgress.SessionVolume(sessionId: "before", startTs: ts(2026, 1, 10), volumeKg: 99_000),
            LiftProgress.SessionVolume(sessionId: "in", startTs: ts(2026, 1, 20), volumeKg: 3_000),
        ]
        let from = ts(2026, 1, 15, hour: 0)
        let to = ts(2026, 1, 25, hour: 0)
        let segments = LiftProgress.segments(volumes, from: from, to: to, bucket: .month, calendar: calendar)
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].averageKg, 3_000, accuracy: 0.001)
        XCTAssertEqual(segments[0].from, from)
        XCTAssertEqual(segments[0].to, to)
    }

    func testWeeklySegmentsFollowTheCalendarsWeeks() {
        // Monday 2 March 2026 starts a week; Sunday 8 March ends it.
        let volumes = [
            LiftProgress.SessionVolume(sessionId: "mon", startTs: ts(2026, 3, 2), volumeKg: 2_000),
            LiftProgress.SessionVolume(sessionId: "sun", startTs: ts(2026, 3, 8), volumeKg: 4_000),
            LiftProgress.SessionVolume(sessionId: "nextMon", startTs: ts(2026, 3, 9), volumeKg: 1_500),
        ]
        let segments = LiftProgress.segments(volumes, from: ts(2026, 3, 1, hour: 0), to: ts(2026, 3, 16, hour: 0),
                                             bucket: .week, calendar: calendar)
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].averageKg, 3_000, accuracy: 0.001)
        XCTAssertEqual(segments[0].from, ts(2026, 3, 2, hour: 0))
        XCTAssertEqual(segments[1].averageKg, 1_500, accuracy: 0.001)
        XCTAssertEqual(segments[1].change!, -0.5, accuracy: 0.0001)
    }

    func testAnEmptyOrReversedWindowHasNoSegments() {
        let volumes = [LiftProgress.SessionVolume(sessionId: "a", startTs: ts(2026, 3, 2), volumeKg: 2_000)]
        XCTAssertTrue(LiftProgress.segments(volumes, from: ts(2026, 4, 1), to: ts(2026, 3, 1),
                                            bucket: .month, calendar: calendar).isEmpty)
    }

    // MARK: - Personal records

    func testTopSetsRankByWeightThenRepsThenTheMoreRecentSession() {
        let sets = [
            LiftProgress.DatedSet(set: set("Squat", weight: 120, reps: 5), sessionStartTs: 100),
            LiftProgress.DatedSet(set: set("Squat", weight: 130, reps: 3), sessionStartTs: 200),
            LiftProgress.DatedSet(set: set("Squat", weight: 120, reps: 6), sessionStartTs: 150),
            LiftProgress.DatedSet(set: set("Squat", weight: 130, reps: 3), sessionStartTs: 300),
            LiftProgress.DatedSet(set: set("Bench press", weight: 200, reps: 1), sessionStartTs: 400),
        ]
        let top = LiftProgress.topSets(sets, exercise: "Squat", limit: 3)
        XCTAssertEqual(top.map(\.weightKg), [130, 130, 120])
        XCTAssertEqual(top.map(\.sessionStartTs), [300, 200, 150],
                       "an equal set ranks the more recent first; then more reps beat fewer")
        XCTAssertEqual(top[0].estimatedOneRepMaxKg!, 130 * (1 + 3.0 / 30.0), accuracy: 0.001)
    }

    func testWarmUpsAndSetsNotPerformedNeverHoldARecord() {
        let sets = [
            LiftProgress.DatedSet(set: set("Squat", weight: 200, reps: 5, warmup: true), sessionStartTs: 100),
            LiftProgress.DatedSet(set: set("Squat", weight: 180, reps: 0), sessionStartTs: 100),
            LiftProgress.DatedSet(set: set("Squat", weight: 100, reps: 5), sessionStartTs: 100),
        ]
        XCTAssertEqual(LiftProgress.topSets(sets, exercise: "Squat", limit: 5).map(\.weightKg), [100])
    }

    func testABodyweightExerciseRanksByReps() {
        let sets = [
            LiftProgress.DatedSet(set: set("Pull-up", weight: nil, reps: 8), sessionStartTs: 100),
            LiftProgress.DatedSet(set: set("Pull-up", weight: nil, reps: 12), sessionStartTs: 200),
        ]
        let records = LiftProgress.personalRecords(sets)
        XCTAssertEqual(records.count, 1)
        XCTAssertFalse(records[0].isWeighted)
        XCTAssertEqual(records[0].best.reps, 12)
        XCTAssertNil(records[0].best.estimatedOneRepMaxKg)
    }

    func testPersonalRecordsListTheMostRecentlyDoneExerciseFirst() {
        let sets = [
            LiftProgress.DatedSet(set: set("Squat", weight: 120, reps: 5), sessionStartTs: 100),
            LiftProgress.DatedSet(set: set("Deadlift", weight: 160, reps: 3), sessionStartTs: 300),
            LiftProgress.DatedSet(set: set("Squat", weight: 110, reps: 5), sessionStartTs: 200),
            LiftProgress.DatedSet(set: set("Curl", weight: 20, reps: 0), sessionStartTs: 400),
        ]
        let records = LiftProgress.personalRecords(sets)
        XCTAssertEqual(records.map(\.best.exercise), ["Deadlift", "Squat"],
                       "an exercise with no performed set has no record")
        XCTAssertEqual(records[1].best.weightKg, 120, "the record is the heaviest set, not the latest")
        XCTAssertEqual(records[1].lastPerformedTs, 200)
        XCTAssertTrue(records[1].isWeighted)
    }
}
