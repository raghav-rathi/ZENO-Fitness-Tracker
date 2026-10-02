#if os(iOS)
import SwiftUI

/// Report a Problem (WHOOP_UI_SPEC §1.8, §3.31), pushed from More › SUPPORT.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it. Until then, the shell's existing
/// entry points keep opening the classic Test Centre, which sends a bug report with the log.
struct PulseReportProblemView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Report a Problem"),
            symbol: "exclamationmark.bubble",
            summary: String(localized: "Tell us what went wrong, with the app's log attached if you choose."),
            spec: "§3.31",
            group: "more-profile",
            links: [
                .init(title: String(localized: "Test Centre"), symbol: "stethoscope", route: .classic(.testCentre))])
    }
}
#endif
