#if os(iOS)
import SwiftUI

/// The My Dashboard views (WHOOP_UI_SPEC §3.1 item 12): the "My Dashboard" header with CUSTOMIZE ✎, the
/// reorderable metric rows (`PulseMetricRow`) that open the Trend View, and the STRESS MONITOR and
/// STRAIN & RECOVERY chart cards.
///
/// Owned by group "home". A namespace for the group's dashboard views; `Section` draws nothing until the
/// group builds it.
enum PulseDashboardViews {
    /// The whole My Dashboard section as Home places it.
    struct Section: View {
        var body: some View {
            EmptyView()
        }
    }
}
#endif
