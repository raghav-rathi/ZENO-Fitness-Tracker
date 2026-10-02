#if os(iOS)
import SwiftUI
import StrandDesign

/// The Coach sheet (WHOOP_UI_SPEC §3.16): a bottom sheet with a grabber that opens at medium and drags
/// to large. The shell presents it from the Coach button and every coach entry point.
///
/// Owned by group "cycle-coach". Until that group rebuilds it, it wraps the classic `CoachView`, which
/// also shows provider setup while no provider is configured (so Coach setup opens straight to large).
/// `seed` is the page context a summary pill or Daily Outlook hands over; the rebuild applies it.
struct PulseCoachSheet: View {
    var seed: String?

    /// Whether a provider is configured comes from the shell's debounced probe, so the sheet does not
    /// observe the engine (it publishes on every streamed token, and `isConfigured` reads the Keychain).
    @Environment(\.pulseCoach) private var coach

    var body: some View {
        NavigationStack {
            CoachView()
                .background(StrandPalette.surfaceBase.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationDetents(coach.availability == .ready ? [.medium, .large] : [.large])
        .presentationDragIndicator(.visible)
    }
}
#endif
