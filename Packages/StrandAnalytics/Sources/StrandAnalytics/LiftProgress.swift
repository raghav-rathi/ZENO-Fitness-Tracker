import Foundation
import WhoopStore

// Progress over time for the Strength Trainer: how much each session lifted, how that average moves
// from month to month (or week to week), and the best sets per exercise.
//
// Every figure is arithmetic over the user's own logged sets, under the same constraint as
// `LiftMetrics`: a session's volume is `LiftMetrics.volumeLoadKg` (working sets, weight × reps), a
// session counts only when it has some, and an average is the plain mean of the sessions in its window.
// Nothing is estimated, smoothed or carried forward, so a month with no session is a gap, never a zero.
//
// PURE: rows in, numbers out. The calendar is a parameter, so a test pins months and weeks exactly.
//
// No Kotlin twin yet: these aggregates feed only the iPhone's Pulse Strength Trainer, and Android has
// no screen that shows them. A port needs a twin and an oracle test (AGENTS.md, parity contract).

public enum LiftProgress {

    // MARK: - Session volume

    /// A finished session with the sets logged in it.
    public struct SessionSets: Equatable, Sendable {
        public let session: LiftSessionRow
        public let sets: [LiftSetRow]

        public init(session: LiftSessionRow, sets: [LiftSetRow]) {
            self.session = session
            self.sets = sets
        }
    }

    /// One session's working volume.
    public struct SessionVolume: Equatable, Sendable {
        public let sessionId: String
        public let startTs: Int
        public let volumeKg: Double

        public init(sessionId: String, startTs: Int, volumeKg: Double) {
            self.sessionId = sessionId
            self.startTs = startTs
            self.volumeKg = volumeKg
        }
    }

    /// The volume of every finished session that has any, oldest first. `exercise` restricts the count
    /// to one exercise's sets (Exercise Details). A session still running, or one with nothing countable
    /// (bodyweight only, every set discarded), is left out rather than listed as zero.
    public static func sessionVolumes(_ sessions: [SessionSets], exercise: String? = nil) -> [SessionVolume] {
        sessions.compactMap { entry -> SessionVolume? in
            guard entry.session.endTs != nil else { return nil }
            let sets = exercise.map { name in entry.sets.filter { $0.exercise == name } } ?? entry.sets
            guard let kg = LiftMetrics.volumeLoadKg(sets) else { return nil }
            return SessionVolume(sessionId: entry.session.id, startTs: entry.session.startTs, volumeKg: kg)
        }
        .sorted { ($0.startTs, $0.sessionId) < ($1.startTs, $1.sessionId) }
    }

    /// The mean volume of the sessions that started in `[from, to)` (unix seconds), or nil when none did.
    public static func averageVolume(_ volumes: [SessionVolume], from: Int, to: Int) -> Double? {
        let inside = volumes.filter { $0.startTs >= from && $0.startTs < to }
        guard !inside.isEmpty else { return nil }
        return inside.reduce(0) { $0 + $1.volumeKg } / Double(inside.count)
    }

    /// The relative change from `previous` to `current` (0.13 is +13%). Nil when either side is
    /// missing, or when `previous` is not positive and so cannot be a base.
    public static func change(from previous: Double?, to current: Double?) -> Double? {
        guard let previous, let current, previous > 0 else { return nil }
        return (current - previous) / previous
    }

    // MARK: - Segments

    /// The calendar span one segment averages over.
    public enum Bucket: Sendable {
        case month
        case week
    }

    /// One bucket's average, with the change from the previous bucket that had sessions.
    public struct Segment: Equatable, Sendable {
        /// The bucket's first instant and the instant after its last, clipped to the window asked for.
        public let from: Int
        public let to: Int
        public let averageKg: Double
        public let sessions: Int
        /// The change from the previous segment in the window; nil for the first one.
        public let change: Double?

        public init(from: Int, to: Int, averageKg: Double, sessions: Int, change: Double?) {
            self.from = from
            self.to = to
            self.averageKg = averageKg
            self.sessions = sessions
            self.change = change
        }
    }

    /// Per-bucket averages of the sessions that started in `[from, to)`, oldest first. A bucket with no
    /// session is skipped (the chart leaves a gap there), and each change compares with the previous
    /// segment that HAD sessions, which is how the chart reads from left to right.
    public static func segments(_ volumes: [SessionVolume], from: Int, to: Int, bucket: Bucket,
                                calendar: Calendar) -> [Segment] {
        guard to > from else { return [] }
        var grouped: [Int: [SessionVolume]] = [:]
        for volume in volumes where volume.startTs >= from && volume.startTs < to {
            grouped[bucketStart(volume.startTs, bucket: bucket, calendar: calendar), default: []].append(volume)
        }
        var out: [Segment] = []
        var previous: Double?
        for start in grouped.keys.sorted() {
            let rows = grouped[start] ?? []
            let average = rows.reduce(0) { $0 + $1.volumeKg } / Double(rows.count)
            let end = bucketEnd(start, bucket: bucket, calendar: calendar)
            out.append(Segment(from: max(start, from), to: min(end, to), averageKg: average,
                               sessions: rows.count, change: change(from: previous, to: average)))
            previous = average
        }
        return out
    }

    /// The first instant of the bucket holding `ts`.
    static func bucketStart(_ ts: Int, bucket: Bucket, calendar: Calendar) -> Int {
        let date = Date(timeIntervalSince1970: TimeInterval(ts))
        guard let interval = calendar.dateInterval(of: component(bucket), for: date) else { return ts }
        return Int(interval.start.timeIntervalSince1970)
    }

    /// The instant after the last one of the bucket starting at `start`.
    static func bucketEnd(_ start: Int, bucket: Bucket, calendar: Calendar) -> Int {
        let date = Date(timeIntervalSince1970: TimeInterval(start))
        guard let interval = calendar.dateInterval(of: component(bucket), for: date) else { return start }
        return Int(interval.end.timeIntervalSince1970)
    }

    private static func component(_ bucket: Bucket) -> Calendar.Component {
        switch bucket {
        case .month: return .month
        case .week: return .weekOfYear
        }
    }

    // MARK: - Personal records

    /// A logged set with the moment its session started (a set's own timestamps are nil when it was
    /// completed at finish without being started).
    public struct DatedSet: Equatable, Sendable {
        public let set: LiftSetRow
        public let sessionStartTs: Int

        public init(set: LiftSetRow, sessionStartTs: Int) {
            self.set = set
            self.sessionStartTs = sessionStartTs
        }
    }

    /// One of an exercise's best sets.
    public struct RecordSet: Equatable, Sendable {
        public let exercise: String
        public let weightKg: Double?
        public let reps: Int?
        public let sessionStartTs: Int
        /// Epley, through `LiftMetrics.estimatedOneRepMaxKg` (nil above its rep ceiling or without weight).
        public let estimatedOneRepMaxKg: Double?

        public init(exercise: String, weightKg: Double?, reps: Int?, sessionStartTs: Int,
                    estimatedOneRepMaxKg: Double?) {
            self.exercise = exercise
            self.weightKg = weightKg
            self.reps = reps
            self.sessionStartTs = sessionStartTs
            self.estimatedOneRepMaxKg = estimatedOneRepMaxKg
        }
    }

    /// An exercise's record: its best set, and when the exercise was last done.
    public struct PersonalRecord: Equatable, Sendable {
        public let best: RecordSet
        public let lastPerformedTs: Int
        /// True when the exercise has been logged with a weight, so the record is a weight; otherwise it
        /// is a rep count (bodyweight work).
        public let isWeighted: Bool

        public init(best: RecordSet, lastPerformedTs: Int, isWeighted: Bool) {
            self.best = best
            self.lastPerformedTs = lastPerformedTs
            self.isWeighted = isWeighted
        }
    }

    /// The sets that can hold a record: working sets that were performed (`LiftMetrics.isPerformed`).
    private static func countable(_ sets: [DatedSet], exercise: String) -> [DatedSet] {
        sets.filter { $0.set.exercise == exercise && !$0.set.isWarmup && LiftMetrics.isPerformed(reps: $0.set.reps) }
    }

    /// Whether any countable set of these carries a weight.
    private static func weighted(_ sets: [DatedSet]) -> Bool {
        sets.contains { ($0.set.weightKg ?? 0) > 0 }
    }

    /// `exercise`'s best sets, best first, at most `limit`. A weighted exercise ranks by weight, then
    /// reps, then the more recent session; one never logged with a weight ranks by reps. Warm-ups and
    /// sets that were not performed never rank.
    public static func topSets(_ sets: [DatedSet], exercise: String, limit: Int) -> [RecordSet] {
        let pool = countable(sets, exercise: exercise)
        let byWeight = weighted(pool)
        let ranked = pool.sorted { a, b in
            if byWeight {
                let (wa, wb) = (a.set.weightKg ?? -1, b.set.weightKg ?? -1)
                if wa != wb { return wa > wb }
            }
            let (ra, rb) = (a.set.reps ?? -1, b.set.reps ?? -1)
            if ra != rb { return ra > rb }
            if a.sessionStartTs != b.sessionStartTs { return a.sessionStartTs > b.sessionStartTs }
            return a.set.ord < b.set.ord
        }
        return ranked.prefix(max(0, limit)).map { dated in
            RecordSet(exercise: exercise, weightKg: dated.set.weightKg, reps: dated.set.reps,
                      sessionStartTs: dated.sessionStartTs,
                      estimatedOneRepMaxKg: LiftMetrics.estimatedOneRepMaxKg(weightKg: dated.set.weightKg,
                                                                            reps: dated.set.reps))
        }
    }

    /// One record per exercise that has a countable set, the exercise done most recently first (ties by
    /// name, so the order is stable).
    public static func personalRecords(_ sets: [DatedSet]) -> [PersonalRecord] {
        let names = Set(sets.map(\.set.exercise))
        let records = names.compactMap { name -> PersonalRecord? in
            let pool = countable(sets, exercise: name)
            guard let best = topSets(pool, exercise: name, limit: 1).first,
                  let last = pool.map(\.sessionStartTs).max() else { return nil }
            return PersonalRecord(best: best, lastPerformedTs: last, isWeighted: weighted(pool))
        }
        return records.sorted { a, b in
            if a.lastPerformedTs != b.lastPerformedTs { return a.lastPerformedTs > b.lastPerformedTs }
            return a.best.exercise < b.best.exercise
        }
    }
}
