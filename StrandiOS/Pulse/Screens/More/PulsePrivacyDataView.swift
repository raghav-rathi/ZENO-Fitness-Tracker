#if os(iOS)
import SwiftUI

/// Privacy & Data (WHOOP_UI_SPEC §1.8, §3.31), pushed from More › ACCOUNT & SETTINGS: everything stays on
/// this iPhone; backup, restore and delete all data.
///
/// Owned by group "more-profile". A placeholder until the group rebuilds it. Until then, the shell's existing
/// entry points keep opening the classic Backup & Sync screen.
struct PulsePrivacyDataView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Privacy & Data"),
            symbol: "lock.shield",
            summary: String(localized: "Everything stays on this iPhone. Back up, restore or delete all of your data."),
            spec: "§3.31",
            group: "more-profile",
            links: [
                .init(title: String(localized: "Backup & Sync"), symbol: "externaldrive.badge.icloud",
                      route: .classic(.backupSync)),
                .init(title: String(localized: "Data Sources"), symbol: "externaldrive", route: .classic(.dataSources))])
    }
}
#endif
