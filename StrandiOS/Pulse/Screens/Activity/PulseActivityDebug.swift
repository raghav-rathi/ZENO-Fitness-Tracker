#if os(iOS) && DEBUG
import SwiftUI
import StrandAnalytics
import WhoopStore
import WhoopProtocol

// MARK: - DEBUG launch flags for the activity screens (stripped from Release)
//
// simctl cannot tap, so every state the activity group draws is reachable at launch:
//
//   --activity-seed               add three demo activities scored from the demo heart rate (a Running
//                                 session on the morning tempo run, a Weightlifting session with a Lift Log
//                                 session on yesterday's hard session, a Sauna over yesterday's lunchtime)
//   --activity-workout <pick>     Activity Details on a stored workout instead of the shell's launch stand-in:
//                                 "latest", an index (0 = newest) or part of a sport name ("running")
//   --activity-menu / --activity-edit / --activity-delete / --activity-export / --activity-scrub /
//   --activity-zones-tab / --activity-heart-rate-tab
//                                 that state of Activity Details once it has loaded
//   --activity-tap-zones          switch EXERCISES → HR ZONES two seconds after load, alone, through the
//                                 segmented control's binding (the update a tap makes)
//   --activity-lift-page N        the strength EXERCISES pager on page N (0 = the summary card)
//   --activity-view-all           open EXERCISE SUMMARY (VIEW ALL) once Activity Details has loaded
//   --activity-wheel / --activity-invalid / --activity-overlap / --activity-reclassify
//                                 that state of the Add / Edit form; --activity-form-sport <name> picks one
//   --activity-sport <name>       the pre-start screen's activity
//   --activity-picker-open        the pre-start screen with its activity list dropped down
//   --activity-panel ring|chart   the Strain Target panel expanded on that view
//   --activity-demo-live [min]    a live session N minutes in (default 28) fed demo heart rate
//   --activity-no-route           start that session with Track Route off (a distance sport records no route)
//   --activity-live-page hr|strain|map   the live pager on that page
//   --activity-end-dialog         the live session's END THIS ACTIVITY? card
//   --activity-live-camera        the live session's LIVE button: ZENO Live pushed over the session
//   --activity-end-save           End & Save the live session once it is on screen (then Activity Details)
//   --activity-target <value>     the Strain Target panel with a dragged target
//   --activity-reset              discard a session an earlier launch left running
//   --activity-recents <a,b>      the activity lists' MOST RECENT
enum PulseActivityDebug {
    static func value(_ flag: String) -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count, !args[i + 1].hasPrefix("--") else { return nil }
        return args[i + 1]
    }

    static func has(_ flag: String) -> Bool { CommandLine.arguments.contains(flag) }

    static var workoutPick: String? { value("--activity-workout") }

    /// `--activity-recents Running,Walking`: fold these into the pickers' MOST RECENT (oldest first).
    static func applyRecentsIfRequested() {
        guard let list = value("--activity-recents") else { return }
        for name in list.split(separator: ",").reversed() { RecentSportsPrefs.recordSelection(String(name)) }
    }
    static var sport: String? { value("--activity-sport") }
    static var panel: String? { value("--activity-panel") }
    static var livePage: String? { value("--activity-live-page") }
    static var demoLiveMinutes: Int? {
        guard has("--activity-demo-live") else { return nil }
        return value("--activity-demo-live").flatMap(Int.init) ?? 28
    }

    // MARK: Demo activities

    /// `--activity-seed`: three activities over the demo heart rate (PulseDemo's synthetic day), scored
    /// exactly as a live session is saved (`AppModel.endWorkout`), so Activity Details has a strain, a
    /// strength and a recovery activity with real curves. Idempotent: an existing row is left alone.
    @MainActor
    static func seedIfRequested(repo: Repository, profile: ProfileStore) async {
        guard has("--activity-seed"), let store = await repo.storeHandle() else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return }
        let nowTs = Int(Date().timeIntervalSince1970)
        func ts(_ day: Date, _ hour: Double) -> Int { Int(day.timeIntervalSince1970) + Int(hour * 3600) }
        let runDay = nowTs > ts(today, 8.1) ? today : yesterday
        let plans: [(sport: String, from: Int, to: Int)] = [
            ("Running", ts(runDay, 7.25), ts(runDay, 8.0)),
            ("Weightlifting", ts(yesterday, 17.5), ts(yesterday, 18.33)),
            ("Sauna", ts(yesterday, 12.5), ts(yesterday, 12.85)),
        ]
        // And one typed in for a time the strap has no heart rate for (the not-enough-HR variant).
        if let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: today) {
            let from = ts(threeDaysAgo, 10), to = ts(threeDaysAgo, 10.75)
            if !(await repo.workoutRows(days: 5)).contains(where: { $0.startTs == from && $0.sport == "Yoga" }) {
                _ = try? await store.upsertWorkouts([WorkoutRow(startTs: from, endTs: to, sport: "Yoga", source: "manual",
                                                                durationS: Double(to - from), energyKcal: nil,
                                                                avgHr: nil, maxHr: nil, strain: nil, distanceM: nil,
                                                                zonesJSON: nil, notes: nil, steps: nil)],
                                                    deviceId: repo.deviceId)
            }
        }
        let existing = await repo.workoutRows(days: 3)
        let up = UserProfile(weightKg: profile.weightKg, heightCm: profile.heightCm, age: Double(profile.age),
                             sex: profile.sex)
        var rows: [WorkoutRow] = []
        for plan in plans where !existing.contains(where: { $0.startTs == plan.from && $0.sport == plan.sport }) {
            let samples = await repo.hrSamples(from: plan.from, to: plan.to, limit: 20_000)
            guard samples.count >= 2 else { continue }
            let resting = repo.today?.restingHr.map(Double.init) ?? StrainScorer.defaultRestingHR
            let strain = StrainScorer.strain(samples, maxHR: Double(profile.hrMax), restingHR: resting,
                                             method: .edwards, sex: profile.sex)
            let kcal = Calories.estimateBoutCalories(samples, profile: up, hrmax: Double(profile.hrMax),
                                                     restingHR: resting).0
            let bpm = samples.map(\.bpm)
            rows.append(WorkoutRow(startTs: plan.from, endTs: plan.to, sport: plan.sport, source: "manual",
                                   durationS: Double(plan.to - plan.from), energyKcal: kcal > 0 ? kcal : nil,
                                   avgHr: Int((Double(bpm.reduce(0, +)) / Double(bpm.count)).rounded()),
                                   maxHr: bpm.max(), strain: strain,
                                   distanceM: plan.sport == "Running" ? 8_350 : nil,
                                   zonesJSON: nil, notes: nil, steps: nil))
            if plan.sport == "Running" {
                RouteStore.store(demoRoute(distance: 8_350), startTs: plan.from, sport: plan.sport)
            }
            if plan.sport == "Weightlifting" {
                await seedLiftSession(store: store, owner: repo.deviceId, from: plan.from, to: plan.to)
            }
        }
        guard !rows.isEmpty else { return }
        _ = try? await store.upsertWorkouts(rows, deviceId: repo.deviceId)
        await repo.refresh()
        NSLog("PulseActivityDebug: seeded \(rows.count) demo activities.")
    }

    /// A loop through a park, about the run's length, for the ROUTE card.
    private static func demoRoute(distance: Double) -> WorkoutRoute {
        let center = (lat: 40.6602, lon: -73.9690)
        let points = (0...72).map { i -> RouteMath.LatLng in
            let t = Double(i) / 72 * 2 * .pi
            return RouteMath.LatLng(center.lat + 0.0105 * sin(t) + 0.002 * sin(3 * t),
                                    center.lon + 0.0085 * cos(t) + 0.0015 * cos(2 * t))
        }
        return WorkoutRoute(polyline: RouteMath.encode(points), distanceM: distance)
    }

    private static func seedLiftSession(store: WhoopStore, owner: String, from: Int, to: Int) async {
        let id = "demo-lift-\(from)"
        let session = LiftSessionRow(id: id, deviceId: owner, startTs: from, endTs: to, sport: "Weightlifting",
                                     programId: nil, programName: "Lower body", sessionRpe: 8, note: nil)
        let plan: [(String, LiftMuscle, Double, [Int])] = [
            ("Back squat", .quads, 100, [5, 5, 5, 5]),
            ("Romanian deadlift", .hamstrings, 80, [8, 8, 8]),
            ("Bulgarian split squat", .quads, 24, [10, 10, 10]),
            ("Hip thrust", .glutes, 90, [10, 10, 10]),
            ("Calf raise", .calves, 60, [12, 12, 12]),
        ]
        var sets: [LiftSetRow] = []
        var ord = 0
        for (exercise, muscle, weight, reps) in plan {
            for (i, r) in reps.enumerated() {
                sets.append(LiftSetRow(id: "\(id)-\(ord)", deviceId: owner, sessionId: id, ord: ord, exercise: exercise,
                                       primaryMuscle: muscle, setIndex: i + 1, weightKg: weight, reps: r, rpe: nil,
                                       isWarmup: false, startTs: nil, endTs: nil, restSec: nil, note: nil))
                ord += 1
            }
        }
        _ = try? await store.upsertLiftSessions([session])
        _ = try? await store.upsertLiftSets(sets)
    }

    // MARK: Demo live session

    /// `--activity-demo-live N`: a session started N minutes ago, its samples drawn from a steady
    /// moderate effort, scored through the same scorer the live engine uses, so the live pages can be
    /// captured in a simulator with no strap. Never persisted: ending it saves through `endWorkout`.
    @MainActor
    static func startDemoLiveIfRequested(app: AppModel, sport: String) {
        guard let minutes = demoLiveMinutes else { return }
        // A session left by an earlier demo launch would be rehydrated without its samples: start afresh.
        if app.activeWorkout != nil { app.discardWorkout() }
        let now = Int(Date().timeIntervalSince1970)
        let start = now - minutes * 60
        var samples: [HRSample] = []
        var rng: UInt64 = 0xACE5
        for t in stride(from: start, through: now, by: 1) {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            let noise = Double(rng >> 33) / Double(1 << 31) - 0.5
            let progress = Double(t - start) / Double(max(1, now - start))
            let bpm = 102 + 48 * min(1, progress * 3) + 8 * sin(Double(t - start) / 90) + noise * 6
            samples.append(HRSample(ts: t, bpm: Int(bpm.rounded())))
        }
        app.startWorkout(sport: sport, trackRoute: !has("--activity-no-route"))
        guard var w = app.activeWorkout else { return }
        w = AppModel.ActiveWorkout(start: Date(timeIntervalSince1970: TimeInterval(start)), sport: sport)
        w.samples = samples
        w.avgHr = Int((Double(samples.map(\.bpm).reduce(0, +)) / Double(samples.count)).rounded())
        w.peakHr = samples.map(\.bpm).max() ?? 0
        w.liveStrain = StrainScorer.strain(samples, maxHR: Double(app.profile.hrMax), method: .edwards,
                                           sex: app.profile.sex) ?? 0
        app.activeWorkout = w
        app.bpm = samples.last?.bpm
    }
}

extension PulseSnapshotBuilder {
    /// DEBUG: the stored workout `--activity-workout` names, for the shell's launch stand-in.
    func debugPickWorkout(_ r: PulseRequest, pick: String?) async -> WorkoutRow? {
        let rows = await workoutRows().sorted { $0.startTs > $1.startTs }
        guard !rows.isEmpty else { return nil }
        guard let pick, pick != "latest" else { return rows.first }
        if let index = Int(pick) { return rows.indices.contains(index) ? rows[index] : rows.first }
        return rows.first { $0.sport.lowercased().contains(pick.lowercased()) } ?? rows.first
    }
}
#endif
