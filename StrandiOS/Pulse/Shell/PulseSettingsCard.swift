#if os(iOS)
import SwiftUI
import StrandDesign

/// The classic Settings entry for the WHOOP-style interface, so a wearer on the classic shell can come
/// back to Pulse. Pulse's own More tab carries the reverse switch.
///
/// Drawn with the classic Settings chrome (a `StrandCard` with the overline, icon and title stack its
/// sections use) because it sits among them.
struct PulseInterfaceSettingsCard: View {
    @AppStorage("pulse.enabled") private var pulseEnabled = true

    var body: some View {
        StrandCard(padding: NoopMetrics.space5) {
            VStack(alignment: .leading, spacing: NoopMetrics.space4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings").strandOverline()
                    HStack(spacing: NoopMetrics.space2 + 2) {
                        Image(systemName: "circle.grid.3x3.fill")
                            .foregroundStyle(StrandPalette.accent)
                            .accessibilityHidden(true)
                        Text(String(localized: "Interface"))
                            .font(StrandFont.title2)
                            .foregroundStyle(StrandPalette.textPrimary)
                    }
                }
                Toggle(isOn: $pulseEnabled) {
                    Text(String(localized: "WHOOP-style interface"))
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textPrimary)
                }
                .toggleStyle(.switch)
                .tint(StrandPalette.accent)
                Text(String(localized: "Home, Health, Trends and More with a floating Coach button, Sleep, Recovery and Strain dials and a deep dive behind each. Always dark. The same data as the classic tabs."))
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
#endif
