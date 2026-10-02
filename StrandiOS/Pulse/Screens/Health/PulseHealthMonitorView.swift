#if os(iOS)
import SwiftUI

/// Health Monitor (WHOOP_UI_SPEC §3.21), pushed.
///
/// Owned by group "health". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Classic Health screen.
struct PulseHealthMonitorView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Health Monitor"),
            symbol: "waveform.path.ecg",
            summary: String(localized: "Your overnight vitals against your own typical ranges, with live heart rate."),
            spec: "§3.21",
            group: "health",
            links: [
                .init(title: String(localized: "Classic Health"), symbol: "heart.text.square", route: .classic(.classicHealth))],
            coach: .button)
    }
}
#endif
