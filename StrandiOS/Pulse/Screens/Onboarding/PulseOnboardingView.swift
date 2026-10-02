#if os(iOS)
import SwiftUI

/// Welcome (WHOOP_UI_SPEC §3.38), presented as a full-screen flow.
///
/// Owned by group "onboarding-strength". A placeholder until the group rebuilds it.
struct PulseOnboardingView: View {
    /// Flip to true once this screen is rebuilt; existing entry points then open it instead of the classic
    /// screen (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = false

    var body: some View {
        PulsePlaceholderScreen(
            name: String(localized: "Welcome"),
            symbol: "hand.wave",
            summary: String(localized: "The first-run welcome, your profile and strap pairing."),
            spec: "§3.38",
            group: "onboarding-strength")
    }
}
#endif
