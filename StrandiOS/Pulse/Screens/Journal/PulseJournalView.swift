#if os(iOS)
import SwiftUI

/// Journal (WHOOP_UI_SPEC §3.17), presented as a full-screen modal.
///
/// Owned by group "journal-plan". A placeholder until the group rebuilds it. Until then, the shell's existing entry points keep opening the classic Journal screen.
struct PulseJournalView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false
    /// Days back from today (nil = today).
    var dayOffset: Int?

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Journal"),
            symbol: "book.closed",
            summary: String(localized: "Answer the day's questions and track the behaviours you care about."),
            spec: "§3.17",
            group: "journal-plan",
            links: [
                .init(title: String(localized: "Journal"), symbol: "square.and.pencil", route: .classic(.journal))])
    }
}
#endif
