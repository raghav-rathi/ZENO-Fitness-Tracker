#if os(iOS)
import SwiftUI

/// The Sleep deep dive (WHOOP_UI_SPEC §3.3), pushed from the Sleep dial, the sleep rows and the sticky
/// header's mini ring.
///
/// Owned by group "sleep". Until the group rebuilds it, it shows the current Pulse Sleep dive
/// (`PulseSleepView`), so the dial keeps opening a working screen. Replace the body; delete
/// `PulseSleepView.swift` once nothing uses it.
struct PulseSleepDiveView: View {
    var body: some View {
        PulseSleepView()
    }
}
#endif
