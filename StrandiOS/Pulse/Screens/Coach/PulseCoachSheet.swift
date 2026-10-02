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

    @EnvironmentObject private var coach: AICoachEngine

    var body: some View {
        NavigationStack {
            CoachView()
                .background(StrandPalette.surfaceBase.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationDetents(coach.isConfigured ? [.medium, .large] : [.large])
        .presentationDragIndicator(.visible)
    }
}
#endif
