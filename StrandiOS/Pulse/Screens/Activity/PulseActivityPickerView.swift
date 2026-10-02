#if os(iOS)
import SwiftUI

/// Select Activity (WHOOP_UI_SPEC §3.9), pushed inside the add flow.
///
/// Owned by group "activity". A placeholder until the group rebuilds it.
struct PulseActivityPickerView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Select Activity"),
            symbol: "list.bullet",
            summary: String(localized: "Search and choose the activity type."),
            spec: "§3.9",
            group: "activity")
    }
}
#endif
