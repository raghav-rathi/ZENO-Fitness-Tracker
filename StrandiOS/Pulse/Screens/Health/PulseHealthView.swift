#if os(iOS)
import SwiftUI

/// The first Pulse Health screen's name, kept for the DEBUG `--demo-screen` target (`PulseDemoScreen`),
/// which still builds it with an action handler. It now shows the rebuilt tab (`PulseHealthTabView`); the
/// tab opens Breathe and the rest through routes, so the handler is not needed.
struct PulseHealthView: View {
    let onAction: (PulseQuickAction) -> Void

    var body: some View {
        PulseHealthTabView()
    }
}
#endif
