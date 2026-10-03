#if os(iOS) && DEBUG
import Foundation
import WhoopStore

// MARK: - DEBUG Lift Log demo (captures only)
//
// `--demo-seed` fills the store with days, sleeps and workouts but no Lift Log, which leaves the Strength
// Trainer empty. With `--demo-lift` as well, this writes three deterministic workouts and six months of
// sessions so MY WORKOUTS, PROGRESS, the records, Exercise Details and the live screen can be captured.
// Stripped from Release (the whole file is DEBUG); it runs only when asked and only into a Lift Log with
// no workouts, so it never touches a real one.
enum PulseStrengthDemo {

    static var requested: Bool { CommandLine.arguments.contains("--demo-lift") }

    /// The one seeding run; every caller awaits it, so nothing reads the Lift Log half-written.
    @MainActor private static var seeding: Task<Void, Never>?

    private struct Line {
        let exercise: String
        let primary: LiftMuscle
        let secondary: [LiftMuscle]
        let sets: Int
        let reps: Int
        /// Starting weight (kg); nil for bodyweight.
        let weight: Double?
        /// Weight added per week of training.
        let weeklyGain: Double
        let rest: Int
        let note: String?
    }

    private static let programs: [(name: String, note: String?, lines: [Line])] = [
        ("Upper A", "Push and pull, heavy first.", [
            Line(exercise: "Bench Press - Barbell", primary: .chest, secondary: [.frontDelts, .triceps], sets: 3, reps: 8,
                 weight: 60, weeklyGain: 0.6, rest: 150, note: "Pause one second on the chest."),
            Line(exercise: "Pull-up", primary: .lats, secondary: [.biceps, .upperBack], sets: 3, reps: 8,
                 weight: nil, weeklyGain: 0, rest: 120, note: nil),
            Line(exercise: "Overhead Press - Dumbbell", primary: .frontDelts, secondary: [.sideDelts, .triceps], sets: 3,
                 reps: 10, weight: 18, weeklyGain: 0.2, rest: 90, note: nil),
            Line(exercise: "Bicep Curl - Cable", primary: .biceps, secondary: [.forearms], sets: 3, reps: 12,
                 weight: 20, weeklyGain: 0.15, rest: 75, note: nil),
        ]),
        ("Lower A", nil, [
            Line(exercise: "Back Squat - Barbell", primary: .quads, secondary: [.glutes, .adductors], sets: 4, reps: 5,
                 weight: 90, weeklyGain: 1.0, rest: 180, note: "Brace before each rep. Below parallel."),
            Line(exercise: "Romanian Deadlift - Barbell", primary: .hamstrings, secondary: [.glutes, .lowerBack], sets: 3,
                 reps: 8, weight: 80, weeklyGain: 0.8, rest: 150, note: nil),
            Line(exercise: "Leg Press - Machine", primary: .quads, secondary: [.glutes], sets: 3, reps: 10,
                 weight: 140, weeklyGain: 1.5, rest: 120, note: nil),
            Line(exercise: "Calf Raise - Machine", primary: .calves, secondary: [], sets: 3, reps: 15,
                 weight: 60, weeklyGain: 0.5, rest: 60, note: nil),
        ]),
        ("Full Body (No EQ)", "Travel days.", [
            Line(exercise: "Push-up", primary: .chest, secondary: [.triceps, .frontDelts], sets: 3, reps: 15,
                 weight: nil, weeklyGain: 0, rest: 60, note: "Exclude your bodyweight when inputting weight."),
            Line(exercise: "Bodyweight Squat", primary: .quads, secondary: [.glutes], sets: 3, reps: 20,
                 weight: nil, weeklyGain: 0, rest: 60, note: nil),
            Line(exercise: "Walking Lunge", primary: .glutes, secondary: [.quads, .hamstrings], sets: 3, reps: 12,
                 weight: nil, weeklyGain: 0, rest: 60, note: nil),
        ]),
    ]

    /// Seed once per launch when `--demo-lift` is passed and the Lift Log has no workouts. A caller that
    /// arrives while the seed is running waits for it to finish (the root's load and the capture flags
    /// both ask, and a snapshot built mid-seed showed a workout last done months ago).
    @MainActor
    static func seedIfRequested(repo: Repository) async {
        guard requested else { return }
        if seeding == nil {
            seeding = Task { @MainActor in await seed(repo: repo) }
        }
        await seeding?.value
    }

    @MainActor
    private static func seed(repo: Repository) async {
        guard let store = await repo.storeHandle() else { return }
        let deviceId = repo.deviceId
        guard ((try? await store.liftPrograms(deviceId: deviceId)) ?? []).isEmpty else { return }

        let now = Int(Date().timeIntervalSince1970)
        var rng: UInt64 = 0x11F7_5EED
        func noise() -> Double {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            return Double(rng >> 33) / Double(1 << 31) - 0.5
        }

        // The vocabulary, so every set is classified.
        var vocabulary: [LiftExerciseRow] = []
        for program in programs {
            for line in program.lines where !vocabulary.contains(where: { $0.name == line.exercise }) {
                vocabulary.append(LiftExerciseRow(id: UUID().uuidString, deviceId: deviceId, name: line.exercise,
                                                  primaryMuscle: line.primary, secondaryMuscles: line.secondary,
                                                  createdAt: now - 200 * 86_400, lastUsedTs: now - 86_400))
            }
        }
        _ = try? await store.upsertLiftExercises(vocabulary)

        // The workouts.
        var ids: [String] = []
        for (index, program) in programs.enumerated() {
            let id = UUID().uuidString
            ids.append(id)
            let row = LiftProgramRow(id: id, deviceId: deviceId, name: program.name, note: program.note,
                                     createdAt: now - 200 * 86_400, updatedAt: now - index * 3_600, archived: false)
            _ = try? await store.upsertLiftPrograms([row])
            let items = program.lines.enumerated().map { ord, line in
                LiftProgramItemRow(id: UUID().uuidString, deviceId: deviceId, programId: id, ord: ord,
                                   exercise: line.exercise, targetSets: line.sets, targetRepsLow: line.reps,
                                   targetRepsHigh: nil, targetRpe: nil,
                                   targetWeightKg: line.weight.map { $0 + line.weeklyGain * 26 },
                                   restSec: line.rest, note: line.note)
            }
            _ = try? await store.replaceLiftProgramItems(programId: id, items: items)
        }

        // 26 weeks of sessions: Upper on Monday, Lower on Thursday, the bodyweight day every third Saturday,
        // weights creeping up with a deload in week 12, a missed fortnight in week 6.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for week in 0..<26 {
            if week == 6 || week == 7 { continue }
            let days: [(program: Int, offset: Int)] = week % 3 == 2 ? [(0, 0), (1, 3), (2, 5)] : [(0, 0), (1, 3)]
            for (programIndex, offset) in days {
                let dayOffset = (25 - week) * 7 + (6 - offset) + 1
                guard dayOffset > 1, let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let start = Int(day.timeIntervalSince1970) + 18 * 3_600 + Int(noise() * 1_800)
                let program = programs[programIndex]
                let sessionId = UUID().uuidString
                var ord = 0
                var t = start + 300
                var sets: [LiftSetRow] = []
                let deload = week == 12 ? 0.85 : 1.0
                for line in program.lines {
                    for setIndex in 1...line.sets {
                        let weight = line.weight.map { (($0 + line.weeklyGain * Double(week)) * deload * 2).rounded() / 2 }
                        let reps = max(1, line.reps + Int((noise() * 3).rounded()) - (setIndex == line.sets ? 1 : 0))
                        let work = 35 + Int(noise() * 20)
                        sets.append(LiftSetRow(id: UUID().uuidString, deviceId: deviceId, sessionId: sessionId, ord: ord,
                                               exercise: line.exercise, primaryMuscle: line.primary,
                                               secondaryMuscles: line.secondary, setIndex: setIndex,
                                               weightKg: weight, reps: reps, rpe: nil, isWarmup: false,
                                               startTs: t, endTs: t + work, restSec: line.rest + Int(noise() * 30),
                                               note: nil))
                        ord += 1
                        t += work + line.rest
                    }
                }
                let session = LiftSessionRow(id: sessionId, deviceId: deviceId, startTs: start, endTs: t,
                                             sport: LiftSessionView.sport, programId: ids[programIndex],
                                             programName: program.name, sessionRpe: 7, note: program.name)
                _ = try? await store.upsertLiftSessions([session])
                _ = try? await store.upsertLiftSets(sets)
            }
        }
        NSLog("PulseStrengthDemo: seeded the Lift Log.")
    }

    /// A seeded workout by name.
    @MainActor
    static func program(named name: String, repo: Repository) async -> LiftProgramRow? {
        guard let store = await repo.storeHandle() else { return nil }
        return ((try? await store.liftPrograms(deviceId: repo.deviceId)) ?? []).first { $0.name == name }
    }

    /// An exercise in the vocabulary whose name starts with `prefix` ("_" for spaces).
    @MainActor
    static func exercise(matching prefix: String, repo: Repository) async -> String? {
        guard let store = await repo.storeHandle() else { return nil }
        let wanted = prefix.replacingOccurrences(of: "_", with: " ").lowercased()
        return ((try? await store.liftExercises(deviceId: repo.deviceId)) ?? [])
            .map(\.name)
            .first { $0.lowercased().hasPrefix(wanted) }
    }

    /// Start the first workout and walk it to `stage` ("warmup", "active", "rest", "exercises", "done").
    @MainActor
    static func startLive(stage: String, session: LiftSessionController, repo: Repository) async {
        // A session a previous capture left running is replaced, so each capture shows the stage asked for.
        if session.isActive { session.discard() }
        guard let program = await program(named: "Upper A", repo: repo),
              let plan = await PulseStrengthSessionStarter.plan(for: program, repo: repo), !plan.isEmpty else { return }
        session.start(plan: plan, programId: program.id, programName: program.name)
        switch stage {
        case "active", "exercises":
            session.advance()
            session.advance()
            session.advance()
        case "rest":
            session.advance()
            session.advance()
        case "done":
            for _ in 0..<(plan.reduce(0) { $0 + $1.targetSets } * 2) { session.advance() }
        default:
            break
        }
    }
}
#endif
