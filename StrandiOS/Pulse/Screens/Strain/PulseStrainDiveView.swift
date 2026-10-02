#if os(iOS)
import SwiftUI

/// The Strain deep dive (WHOOP_UI_SPEC §3.5), pushed from the Strain dial and the sticky header.
///
/// Owned by group "recovery-strain". Until the group rebuilds it, it shows the current Pulse Strain dive
/// (`PulseStrainView`), so the dial keeps opening a working screen. Replace the body; delete
/// `PulseStrainView.swift` once nothing uses it.
struct PulseStrainDiveView: View {
    var body: some View {
        PulseStrainView()
    }
}
#endif
