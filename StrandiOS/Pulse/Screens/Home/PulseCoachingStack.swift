#if os(iOS)
import SwiftUI

/// The coaching card stack under the Home dials (WHOOP_UI_SPEC §3.14, §2.6 item 5): one coaching card at
/// white ≈7.5% with a "✓ n" counter chip and the next card peeking 12 pt below, feature and error variants,
/// each card opening its own route.
///
/// Owned by group "home". It draws nothing until the group builds it, so Home can place it now.
struct PulseCoachingStack: View {
    /// Flip to true once the stack is built and placed on Home.
    static let isRebuilt = false

    var body: some View {
        EmptyView()
    }
}
#endif
