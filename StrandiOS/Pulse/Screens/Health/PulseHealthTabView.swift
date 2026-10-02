#if os(iOS)
import SwiftUI

/// The Health tab root ("HEALTH", WHOOP_UI_SPEC §3.20): the ZENO Age orb, Pace of Aging, Lab Book, the
/// Health and Stress Monitors, cycle insights and ZENO's extras. Always "now", whatever day Home shows.
///
/// Owned by group "health". Until the group rebuilds it, it shows the current Pulse Health tab
/// (`PulseHealthView`). Replace the body; delete `PulseHealthView.swift` once nothing uses it.
struct PulseHealthTabView: View {
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        PulseHealthView(onAction: navigator.quickAction)
    }
}
#endif
