#if os(iOS)
import Foundation
import WhoopStore

extension LiftSessionController {
    /// Reads what was lifted for each of this session's exercises LAST time, by set number, and hands it
    /// over (`setLastSession`): the middle layer of the grey numbers that the session screens, the minimised
    /// bar and the Lock Screen banner all read. It is the read the Lift Log's sheet makes
    /// (`LiftSessionView.loadLastTime`), so whichever loads it, the numbers are the same.
    ///
    /// The app root runs it for a session picked up after a restart (`StrandiOSApp.init`), which comes back
    /// as the bar with no session screen open to load it; the rebuilt live screen runs it as it opens and
    /// whenever the exercises change. A result is dropped when its task was cancelled or the session or its
    /// exercises changed while the store answered, so an older read never replaces a newer one.
    func loadLastSession(from repo: Repository) async {
        guard let engine, let store = await repo.storeHandle() else { return }
        let exercises = engine.plan.map(\.exercise)
        var out: [String: [Int: LiftSetCarry]] = [:]
        // One query per DISTINCT exercise, not per plan line.
        for exercise in NSOrderedSet(array: exercises).compactMap({ $0 as? String }) {
            let rows = (try? await store.lastLiftSets(deviceId: repo.deviceId, exercise: exercise,
                                                      before: engine.startTs)) ?? []
            var bySet: [Int: LiftSetCarry] = [:]
            for row in rows where !row.isWarmup {
                bySet[row.setIndex] = LiftSetCarry(weightKg: row.weightKg, reps: row.reps)
            }
            out[exercise] = bySet
        }
        guard !Task.isCancelled, let now = self.engine, now.startTs == engine.startTs,
              now.plan.map(\.exercise) == exercises else { return }
        setLastSession(out)
    }
}
#endif
