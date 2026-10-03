#if os(iOS)
import Foundation
import StrandAnalytics
import WhoopStore

// MARK: - Strength Trainer builds (WHOOP_UI_SPEC §3.29)
//
// Reads the Lift Log's rows (programs, their lines, finished sessions with their sets, the exercise
// vocabulary and the week's per-muscle counts) ONCE per refresh and edit version, off the main actor, and
// turns them into the Strength Trainer's snapshots. The figures are the Lift Log's own: session volume is
// `LiftMetrics.volumeLoadKg`, averages, segments and records are `LiftProgress`, the week's muscle counts
// are `WhoopStore.liftSetCounts`. Nothing is written here.

/// The Lift Log's rows the Strength Trainer reads.
struct StrengthRows: Sendable {
    let programs: [LiftProgramRow]
    let items: [String: [LiftProgramItemRow]]
    /// Finished sessions with their sets, oldest first.
    let sessions: [LiftProgress.SessionSets]
    let vocabulary: [LiftExerciseRow]
    let week: [LiftMuscle: Double]
    let now: Date

    static func empty(_ now: Date) -> StrengthRows {
        StrengthRows(programs: [], items: [:], sessions: [], vocabulary: [], week: [:], now: now)
    }
}

extension PulseSnapshotBuilder {

    /// The rows, read once per refresh and `version` (bumped by the screen after an edit, a save or a
    /// delete, none of which necessarily moves the repository's refresh).
    func strengthRows(version: Int) async -> StrengthRows {
        await cached("strength.rows.\(version)") { await self.readStrengthRows() }
    }

    private func readStrengthRows() async -> StrengthRows {
        let now = Date()
        guard let store = await repo.storeHandle() else { return .empty(now) }
        // The Lift Log reads and writes under the repository's device id (`LiftLogView`, `LiftSessionView`).
        let deviceId = await repo.deviceId
        let nowTs = Int(now.timeIntervalSince1970)
        let programs = (try? await store.liftPrograms(deviceId: deviceId)) ?? []
        var items: [String: [LiftProgramItemRow]] = [:]
        for program in programs {
            items[program.id] = ((try? await store.liftProgramItems(programId: program.id)) ?? [])
                .sorted { $0.ord < $1.ord }
        }
        // An abandoned session (no end) is not history, as the Lift Log reads it.
        let rows = ((try? await store.liftSessions(deviceId: deviceId, fromTs: 0, toTs: nowTs + 86_400)) ?? [])
            .filter { $0.endTs != nil }
            .sorted { $0.startTs < $1.startTs }
        var sessions: [LiftProgress.SessionSets] = []
        sessions.reserveCapacity(rows.count)
        for row in rows {
            let sets = (try? await store.liftSets(sessionId: row.id)) ?? []
            sessions.append(LiftProgress.SessionSets(session: row, sets: sets))
        }
        let vocabulary = (try? await store.liftExercises(deviceId: deviceId)) ?? []
        let week = (try? await store.liftSetCounts(deviceId: deviceId, fromTs: nowTs - 7 * 86_400, toTs: nowTs))?
            .fractional ?? [:]
        return StrengthRows(programs: programs, items: items, sessions: sessions, vocabulary: vocabulary,
                            week: week, now: now)
    }

    // MARK: Root

    /// MY WORKOUTS and PROGRESS for `range`, `page` windows back.
    func strengthTrainer(_ r: PulseRequest, version: Int, range: StrengthRange, page: Int,
                         system: UnitSystem) async -> StrengthTrainerSnapshot? {
        begin(r.seq)
        let rows = await strengthRows(version: version)
        guard isCurrent(r) else { return nil }
        let calendar = Calendar.current
        let window = StrengthFormat.window(range: range, page: page, now: rows.now, calendar: calendar)
        let volumes = LiftProgress.sessionVolumes(rows.sessions)
        let from = Int(window.start.timeIntervalSince1970)
        let to = Int(window.end.timeIntervalSince1970)
        let average = LiftProgress.averageVolume(volumes, from: from, to: to)

        let dated = rows.sessions.flatMap { entry in
            entry.sets.map { LiftProgress.DatedSet(set: $0, sessionStartTs: entry.session.startTs) }
        }
        let records = LiftProgress.personalRecords(dated).prefix(12).map { record -> StrengthRecord in
            if record.isWeighted, let kg = record.best.weightKg {
                return StrengthRecord(exercise: record.best.exercise, value: StrengthFormat.weight(kg, system),
                                      unit: LiftFormat.weightUnit(system))
            }
            return StrengthRecord(exercise: record.best.exercise, value: record.best.reps.map(String.init) ?? "–",
                                  unit: String(localized: "reps"))
        }

        return StrengthTrainerSnapshot(
            unit: LiftFormat.weightUnit(system),
            workouts: workouts(rows, system: system),
            averageVolume: average.map { StrengthFormat.volume($0, system) },
            chart: StrengthFormat.chart(volumes, start: window.start, end: window.end, range: range, system: system,
                                        calendar: calendar),
            pager: StrengthFormat.pager(window: window, page: page, earliest: rows.sessions.first?.session.startTs),
            records: Array(records),
            muscles: muscleWeek(rows.week),
            sessions: recentSessions(rows, system: system),
            hasSessions: !rows.sessions.isEmpty)
    }

    private func workouts(_ rows: StrengthRows, system: UnitSystem) -> [StrengthWorkout] {
        var lastRun: [String: Int] = [:]
        for entry in rows.sessions {
            guard let id = entry.session.programId else { continue }
            lastRun[id] = max(lastRun[id] ?? 0, entry.session.startTs)
        }
        let known = Dictionary(rows.vocabulary.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        return rows.programs.map { program in
            let items = rows.items[program.id] ?? []
            let lines = items.map { item -> StrengthWorkout.Line in
                let count = max(1, item.targetSets ?? 1)
                let reps: String? = item.targetRepsLow.map { low in
                    item.targetRepsHigh.map { "\(low)-\($0)" } ?? "\(low)"
                }
                let weight = item.targetWeightKg.map { StrengthFormat.weight($0, system) }
                let vocab = known[item.exercise]
                return StrengthWorkout.Line(
                    id: item.id,
                    exercise: item.exercise,
                    muscles: vocab.map { LiftMuscleSummary.line(primary: $0.primaryMuscle, secondaries: $0.secondaryMuscles) },
                    setsText: count == 1 ? String(localized: "1 Set") : String(localized: "\(count) Sets"),
                    sets: (1...count).map { StrengthWorkout.PlannedSet(id: $0, reps: reps, weight: weight) },
                    rest: String(localized: "Rest \(LiftFormat.duration(item.restSec ?? LiftPlanItem.defaultRestSec))"),
                    note: item.note.flatMap { $0.isEmpty ? nil : $0 })
            }
            let sets = lines.reduce(0) { $0 + $1.sets.count }
            let detail = String(localized: "\(lines.count) exercises · \(sets) sets")
            let last = lastRun[program.id].map {
                String(localized: "Last done \(StrengthFormat.shortDate(Date(timeIntervalSince1970: TimeInterval($0))))")
            }
            return StrengthWorkout(program: program, lines: lines, detail: detail, lastDone: last)
        }
    }

    private func muscleWeek(_ week: [LiftMuscle: Double]) -> [StrengthMuscleWeek] {
        // The classic Lift Log's drawing: a 20-set span that is never "full", the ≈4-set floor as a tick.
        let span = 20.0
        let floor = LiftMetrics.ReferenceDose.hypertrophyMinimumSetsPerWeek
        return LiftMuscle.ordered.compactMap { muscle in
            guard let sets = week[muscle], sets > 0 else { return nil }
            return StrengthMuscleWeek(id: muscle.rawValue, name: muscle.displayName, setsText: LiftFormat.trim(sets),
                                      fill: min(1, sets / span), tick: min(1, floor / span),
                                      atOrAboveFloor: sets >= floor)
        }
    }

    private func recentSessions(_ rows: StrengthRows, system: UnitSystem) -> [StrengthSession] {
        rows.sessions.suffix(10).reversed().map { entry in
            let start = Date(timeIntervalSince1970: TimeInterval(entry.session.startTs))
            let performed = entry.sets.filter { !$0.isWarmup && LiftMetrics.isPerformed(reps: $0.reps) }.count
            var parts = [StrengthFormat.dayTime(start), String(localized: "\(performed) sets")]
            if let kg = LiftMetrics.volumeLoadKg(entry.sets) {
                parts.append("\(StrengthFormat.volume(kg, system)) \(LiftFormat.weightUnit(system))")
            }
            return StrengthSession(row: entry.session,
                                   title: entry.session.programName ?? String(localized: "Session"),
                                   subtitle: parts.joined(separator: " · "))
        }
    }

    // MARK: Exercise Details

    /// One exercise's progress, records, history and notes.
    func strengthExercise(_ r: PulseRequest, version: Int, exercise: String, range: StrengthRange, page: Int,
                          system: UnitSystem) async -> StrengthExerciseSnapshot? {
        begin(r.seq)
        let rows = await strengthRows(version: version)
        guard isCurrent(r) else { return nil }
        let calendar = Calendar.current
        let window = StrengthFormat.window(range: range, page: page, now: rows.now, calendar: calendar)
        let volumes = LiftProgress.sessionVolumes(rows.sessions, exercise: exercise)
        let from = Int(window.start.timeIntervalSince1970)
        let to = Int(window.end.timeIntervalSince1970)
        let span = to - from
        let average = LiftProgress.averageVolume(volumes, from: from, to: to)
        let prior = LiftProgress.averageVolume(volumes, from: from - span, to: from)
        let change = LiftProgress.change(from: prior, to: average).map { value -> StrengthExerciseSnapshot.Change in
            let percent = Int((abs(value) * 100).rounded())
            return StrengthExerciseSnapshot.Change(text: "\(percent)% \(range.priorPhrase)",
                                                   up: percent == 0 ? nil : value > 0)
        }

        let withExercise = rows.sessions.filter { entry in entry.sets.contains { $0.exercise == exercise } }
        let dated = withExercise.flatMap { entry in
            entry.sets.map { LiftProgress.DatedSet(set: $0, sessionStartTs: entry.session.startTs) }
        }
        let names = Dictionary(withExercise.map { ($0.session.startTs, $0.session.programName) },
                               uniquingKeysWith: { first, _ in first })
        let topSets = LiftProgress.topSets(dated, exercise: exercise, limit: 5).enumerated().map { index, set in
            StrengthExerciseSnapshot.TopSet(
                id: index,
                rank: index + 1,
                weight: set.weightKg.flatMap { $0 > 0 ? StrengthFormat.weight($0, system) : nil },
                reps: set.reps.map(String.init),
                date: StrengthFormat.longDate(Date(timeIntervalSince1970: TimeInterval(set.sessionStartTs))),
                estimate: set.estimatedOneRepMaxKg.map {
                    String(localized: "Estimated 1RM \(StrengthFormat.weight($0, system)) \(LiftFormat.weightUnit(system)) (Epley)")
                },
                workout: names[set.sessionStartTs] ?? nil)
        }

        let history = withExercise.suffix(20).reversed().map { entry -> StrengthExerciseSnapshot.HistorySession in
            let lines = entry.sets
                .filter { $0.exercise == exercise && LiftMetrics.isPerformed(reps: $0.reps) }
                .sorted { $0.ord < $1.ord }
                .map { set -> String in
                    let label = set.isWarmup ? String(localized: "Warm-up") : String(localized: "Set \(set.setIndex)")
                    return "\(label) · \(StrengthFormat.setFigures(weightKg: set.weightKg, reps: set.reps, system))"
                }
            return StrengthExerciseSnapshot.HistorySession(
                id: entry.session.id,
                date: StrengthFormat.dayTime(Date(timeIntervalSince1970: TimeInterval(entry.session.startTs))),
                title: entry.session.programName ?? String(localized: "Session"),
                sets: lines)
        }

        var notes: [StrengthExerciseSnapshot.Note] = []
        for program in rows.programs {
            for item in rows.items[program.id] ?? [] where item.exercise == exercise {
                if let note = item.note, !note.isEmpty {
                    notes.append(.init(id: item.id, workout: program.name, text: note))
                }
            }
        }
        let vocab = rows.vocabulary.first { $0.name == exercise }

        return StrengthExerciseSnapshot(
            exercise: exercise,
            muscles: vocab.map { LiftMuscleSummary.line(primary: $0.primaryMuscle, secondaries: $0.secondaryMuscles) },
            unit: LiftFormat.weightUnit(system),
            averageVolume: average.map { StrengthFormat.volume($0, system) },
            change: change,
            chart: StrengthFormat.chart(volumes, start: window.start, end: window.end, range: range, system: system,
                                        calendar: calendar),
            pager: StrengthFormat.pager(window: window, page: page, earliest: dated.map(\.sessionStartTs).min()),
            topSets: topSets,
            history: Array(history),
            notes: notes)
    }
}

// MARK: - Formatting

/// The Strength Trainer's formatting and chart geometry. Sessions are real instants, so dates use the
/// device's own zone (not the UTC day keys the daily scores use).
enum StrengthFormat {

    /// `range`'s window, `page` windows back from the one that ends at the end of today.
    static func window(range: StrengthRange, page: Int, now: Date, calendar: Calendar) -> (start: Date, end: Date) {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        let end = calendar.date(byAdding: .day, value: -range.days * max(0, page), to: tomorrow) ?? tomorrow
        let start = calendar.date(byAdding: .day, value: -range.days, to: end) ?? end
        return (start, end)
    }

    static func pager(window: (start: Date, end: Date), page: Int, earliest: Int?) -> StrengthPager {
        let last = window.end.addingTimeInterval(-1)
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMdyy")
        let title = "\(formatter.string(from: window.start)) - \(formatter.string(from: last))".uppercased()
        let canGoBack = earliest.map { $0 < Int(window.start.timeIntervalSince1970) } ?? false
        return StrengthPager(title: title, canGoBack: canGoBack, canGoForward: page > 0)
    }

    /// A weight in the wearer's unit, as the Lift Log prints it ("60", "132.5").
    static func weight(_ kg: Double, _ system: UnitSystem) -> String {
        LiftFormat.trim(LiftFormat.display(fromKilograms: kg, system: system))
    }

    /// A volume in the wearer's unit, whole and grouped ("5,478").
    static func volume(_ kg: Double, _ system: UnitSystem) -> String {
        Int(LiftFormat.display(fromKilograms: kg, system: system).rounded()).formatted(.number)
    }

    /// "100 kg × 5", "12 reps", "60 kg".
    static func setFigures(weightKg: Double?, reps: Int?, _ system: UnitSystem) -> String {
        let weight = weightKg.flatMap { $0 > 0 ? "\(Self.weight($0, system)) \(LiftFormat.weightUnit(system))" : nil }
        switch (weight, reps) {
        case (let w?, let r?): return "\(w) × \(r)"
        case (nil, let r?): return String(localized: "\(r) reps")
        case (let w?, nil): return w
        case (nil, nil): return "–"
        }
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    static func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.wide).day().year())
    }

    static func dayTime(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
    }

    /// The volume chart for `[start, end)`: each session as a point, per-bucket segments, three nice
    /// steps on the y axis (WHOOP's 0 / 5k / 10k / 15k) and the month or week starts on the x axis.
    static func chart(_ volumes: [LiftProgress.SessionVolume], start: Date, end: Date, range: StrengthRange,
                      system: UnitSystem, calendar: Calendar) -> StrengthVolumeChart {
        let from = Int(start.timeIntervalSince1970)
        let to = Int(end.timeIntervalSince1970)
        let points = volumes.filter { $0.startTs >= from && $0.startTs < to }
            .sorted { $0.startTs < $1.startTs }
            .map { volume -> StrengthVolumeChart.Point in
                let value = LiftFormat.display(fromKilograms: volume.volumeKg, system: system)
                return StrengthVolumeChart.Point(id: volume.sessionId,
                                                 date: Date(timeIntervalSince1970: TimeInterval(volume.startTs)),
                                                 value: value, valueText: Int(value.rounded()).formatted(.number))
            }
        let raw = LiftProgress.segments(volumes, from: from, to: to, bucket: range.bucket, calendar: calendar)
        let segments = raw.enumerated().map { index, segment -> StrengthVolumeChart.Segment in
            let value = LiftFormat.display(fromKilograms: segment.averageKg, system: system)
            let tone: StrengthVolumeChart.Tone
            var changeText: String?
            if let change = segment.change {
                let percent = Int((change * 100).rounded())
                tone = percent > 0 ? .up : (percent < 0 ? .down : .flat)
                changeText = percent > 0 ? "+\(percent)%" : "\(percent)%"
            } else {
                tone = .first
            }
            return StrengthVolumeChart.Segment(
                id: index,
                from: Date(timeIntervalSince1970: TimeInterval(segment.from)),
                to: Date(timeIntervalSince1970: TimeInterval(segment.to)),
                value: value,
                valueText: Int(value.rounded()).formatted(.number),
                changeText: changeText,
                tone: tone)
        }
        let top = max(points.map(\.value).max() ?? 0, segments.map(\.value).max() ?? 0)
        return StrengthVolumeChart(start: start, end: end, points: points, segments: segments,
                                   yTicks: ticks(top),
                                   xLabels: xLabels(start: start, end: end, range: range, segments: raw,
                                                    calendar: calendar))
    }

    /// 0 and three "nice" steps (1, 2, 2.5 or 5 × 10ⁿ) that clear `top`.
    static func ticks(_ top: Double) -> [Double] {
        guard top > 0 else { return [0, 1_000, 2_000, 3_000] }
        let rough = top / 3
        let magnitude = pow(10, floor(log10(rough)))
        let fraction = rough / magnitude
        let nice: Double
        switch fraction {
        case ...1: nice = 1
        case ...2: nice = 2
        case ...2.5: nice = 2.5
        case ...5: nice = 5
        default: nice = 10
        }
        let step = nice * magnitude
        return [0, step, step * 2, step * 3]
    }

    /// One label per month (6M) or week (M) the window touches, under the middle of the part inside the
    /// window, so a segment always has its month under it (g03), the partial first and last months
    /// included. A sliver of a bucket (under a third of it) without a segment is left unnamed, so two
    /// names never collide at the window's edge. Months read "Apr", weeks "Sep 7" (their first day in
    /// the window).
    static func xLabels(start: Date, end: Date, range: StrengthRange, segments: [LiftProgress.Segment],
                        calendar: Calendar) -> [StrengthVolumeChart.AxisLabel] {
        let component: Calendar.Component = range == .sixMonths ? .month : .weekOfYear
        guard var cursor = calendar.dateInterval(of: component, for: start)?.start else { return [] }
        var out: [StrengthVolumeChart.AxisLabel] = []
        while cursor < end {
            guard let next = calendar.date(byAdding: component, value: 1, to: cursor) else { break }
            let from = max(cursor, start)
            let to = min(next, end)
            let share = to.timeIntervalSince(from) / next.timeIntervalSince(cursor)
            let fromTs = Int(from.timeIntervalSince1970)
            let toTs = Int(to.timeIntervalSince1970)
            let hasSegment = segments.contains { $0.from < toTs && $0.to > fromTs }
            if share >= 1.0 / 3 || hasSegment {
                // A week is named by its first day in the window.
                let text = range == .sixMonths ? cursor.formatted(.dateTime.month(.abbreviated))
                                               : from.formatted(.dateTime.month(.abbreviated).day())
                out.append(.init(date: from.addingTimeInterval(to.timeIntervalSince(from) / 2), text: text))
            }
            cursor = next
        }
        return out
    }
}
#endif
