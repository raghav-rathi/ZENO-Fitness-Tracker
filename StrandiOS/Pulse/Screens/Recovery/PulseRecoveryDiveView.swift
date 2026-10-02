#if os(iOS)
import SwiftUI

/// The Recovery deep dive (WHOOP_UI_SPEC §3.4), pushed from the Recovery dial and the sticky header.
///
/// Owned by group "recovery-strain". Until the group rebuilds it, it shows the current Pulse Recovery dive
/// (`PulseRecoveryView`), so the dial keeps opening a working screen. Replace the body; delete
/// `PulseRecoveryView.swift` once nothing uses it.
struct PulseRecoveryDiveView: View {
    var body: some View {
        PulseRecoveryView()
    }
}
#endif
