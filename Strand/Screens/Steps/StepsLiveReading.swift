import SwiftUI
import StrandAnalytics

/// Hosts one steps read-out inside a bigger screen (Today's tile or card) so it can follow the live count.
///
/// Only THIS leaf observes `StepsService`, which publishes every few seconds while the pedometer streams;
/// observing it from the whole Today screen would re-render every card on each tick. The count comes from the
/// service's snapshot, the same resolved day the Steps screen and card show, and falls back to the host's own
/// `fallback` (resolved by the same resolver in the host's load) for a day outside the service's window.
struct StepsLiveReading<Content: View>: View {
    /// The "yyyy-MM-dd" day the host is showing.
    let day: String
    let fallback: ResolvedStepDay?
    /// Builds the read-out from the resolved day (nil when nothing counted it) and the clamped goal.
    @ViewBuilder let content: (ResolvedStepDay?, Int) -> Content

    @EnvironmentObject private var repo: Repository
    @ObservedObject private var service = StepsService.shared
    @AppStorage(StepsPrefs.goalKey) private var goalRaw = StepGoal.defaultGoal

    var body: some View {
        content(resolved, StepGoal.clamp(goalRaw))
            .task { service.activate(repo: repo) }
    }

    private var resolved: ResolvedStepDay? {
        let snapshot = service.snapshot
        if snapshot.loaded, day >= snapshot.windowStart, day <= snapshot.today { return snapshot.days[day] }
        return fallback
    }
}
