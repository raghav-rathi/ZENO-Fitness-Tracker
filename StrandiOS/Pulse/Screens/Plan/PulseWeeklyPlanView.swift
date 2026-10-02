#if os(iOS)
import SwiftUI

/// My Plan (WHOOP_UI_SPEC §3.19), pushed (Edit Plan as a sheet).
///
/// Owned by group "journal-plan". A placeholder until the group rebuilds it.
struct PulseWeeklyPlanView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false
    /// True for the Edit Plan modal rather than Plan Overview.
    var editing = false

    var body: some View {
        PulsePlaceholderScreen(
            name: editing ? String(localized: "Edit Plan") : String(localized: "My Plan"),
            symbol: "target",
            summary: String(localized: "Your plan's goals for the week and your progress against each."),
            spec: "§3.19",
            group: "journal-plan")
    }
}
#endif
