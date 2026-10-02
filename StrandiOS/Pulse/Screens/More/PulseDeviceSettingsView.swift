#if os(iOS)
import SwiftUI

/// Device Settings (WHOOP_UI_SPEC §3.32), presented as a full-screen modal.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Devices screen.
struct PulseDeviceSettingsView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Device Settings"),
            symbol: "sensor.tag.radiowaves.forward",
            summary: String(localized: "Your strap's battery, sync status and pairing."),
            spec: "§3.32",
            group: "more-profile",
            links: [
                .init(title: String(localized: "Devices"), symbol: "sensor.tag.radiowaves.forward", route: .classic(.devices))])
    }
}
#endif
