#if os(iOS)
import SwiftUI

/// Calibration Timeline (WHOOP_UI_SPEC §3.1 item 10), pushed from Looking Ahead.
///
/// Owned by group "home". A placeholder until the group rebuilds it.
struct PulseCalibrationTimelineView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Calibration Timeline"),
            symbol: "calendar.badge.clock",
            summary: String(localized: "The nights left before Recovery scores and the seven-day features unlock."),
            spec: "§3.1 item 10",
            group: "home")
    }
}
#endif
