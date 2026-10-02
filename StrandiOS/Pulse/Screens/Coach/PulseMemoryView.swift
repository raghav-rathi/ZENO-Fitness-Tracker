#if os(iOS)
import SwiftUI

/// My Memory (WHOOP_UI_SPEC §3.16), pushed.
///
/// Owned by group "cycle-coach". A placeholder until the group rebuilds it.
struct PulseMemoryView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "My Memory"),
            symbol: "brain",
            summary: String(localized: "What the Coach remembers about you, and the controls to change it."),
            spec: "§3.16",
            group: "cycle-coach")
    }
}
#endif
