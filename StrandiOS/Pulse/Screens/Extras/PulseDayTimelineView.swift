#if os(iOS)
import SwiftUI

/// Day Timeline (WHOOP_UI_SPEC §3.7), presented as a full-screen modal.
///
/// Owned by group "extras". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Full-day heart rate screen.
struct PulseDayTimelineView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Day Timeline"),
            symbol: "waveform.path",
            summary: String(localized: "Your whole day's heart rate with its activities and sleep, landscape-capable."),
            spec: "§3.7",
            group: "extras",
            links: [
                .init(title: String(localized: "Full-day heart rate"), symbol: "waveform.path", route: .tab(.fullDayChart))])
    }
}
#endif
