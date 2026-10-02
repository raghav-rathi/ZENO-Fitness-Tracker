#if os(iOS)
import SwiftUI

// MARK: - Status banners (WHOOP_UI_SPEC §3.1 item 2, §2.9 "Syncing", "Off wrist")
//
// A pure-black well (radius 12, ≈44 pt) 12 pt under the Home header, 16 pt margins. One component for
// every banner so they share a height and never stack two different looks.

/// A Home status banner.
///
///     PulseStatusBanner(.caughtUp(syncedTo: "7:32AM"))
///     PulseStatusBanner(.catchingUp(progress: 0.4))
///     PulseStatusBanner(.offWrist)
///     PulseStatusBanner(.lowBattery(percent: 12), onDismiss: { … })
struct PulseStatusBanner: View {
    enum Kind: Equatable {
        /// "DATA CAUGHT UP · SYNCED TO 7:32AM ✓": shown for a few seconds after a sync completes.
        /// `syncedTo` is a clock time already formatted in the device zone.
        case caughtUp(syncedTo: String)
        /// "CATCHING UP…" with a teal progress line while history backfills; nil progress hides the line.
        case catchingUp(progress: Double?)
        /// "STRAP OFF WRIST / Wear your strap 24/7 to unlock insights."
        case offWrist
        /// "LOW STRAP BATTERY · 12%" with an orange "!" square.
        case lowBattery(percent: Int)
    }

    let kind: Kind
    var onDismiss: (() -> Void)?

    init(_ kind: Kind, onDismiss: (() -> Void)? = nil) {
        self.kind = kind
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: 12) {
            content
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Dismiss"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.banner, alignment: .leading)
        .background(alignment: .bottomLeading) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                    .fill(PulseTheme.bannerWell)
                if case .catchingUp(let progress?) = kind {
                    GeometryReader { geo in
                        Capsule()
                            .fill(PulseTheme.positive)
                            .frame(width: geo.size.width * max(0.02, min(1, progress)), height: 2)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .caughtUp(let time):
            Text(String(localized: "Data caught up"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(String(localized: "Synced to"))
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(time)
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .foregroundStyle(PulseTheme.syncedTeal)
            }
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(PulseTheme.syncedTeal)
        case .catchingUp(let progress):
            Text(String(localized: "Catching up…"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            if let progress {
                Text("\(Int((max(0, min(1, progress)) * 100).rounded()))%")
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .foregroundStyle(PulseTheme.positive)
            }
        case .offWrist:
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Strap off wrist"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "Wear your strap 24/7 to unlock insights."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            Spacer(minLength: 0)
        case .lowBattery(let percent):
            PulseStatusBadge(.alert, tint: .orange)
            Text(String(localized: "Low strap battery · \(percent)%"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 0)
        }
    }
}
#endif
