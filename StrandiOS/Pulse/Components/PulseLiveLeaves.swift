#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Live leaves
//
// Each leaf below is the ONLY view that observes `LiveState` (64 published properties, several ticking
// every second). The wrapper reads the few values it shows and hands them to an Equatable content view,
// so a heart-rate tick re-renders one chip and nothing around it.

/// The Home header's strap status (WHOOP_UI_SPEC §1.4, right): the battery figure ("65%", 13 pt Bold
/// condensed, red when low, "⚡" while charging) and a strap glyph whose 6 pt dot is teal while connected
/// and grey when not. Tapping it opens the strap screen (`action`, or NavRouter's Devices request).
struct PulseStrapChip: View {
    var action: (() -> Void)?

    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var router: NavRouter

    var body: some View {
        let display = LiquidTodayView.StrapBatteryDisplay.resolve(
            activeIsWhoop: live.activeIsWhoop, connected: live.connected, batteryPct: live.batteryPct,
            charging: live.charging, ringPct: live.ouraBatteryPct,
            ringCharging: live.ouraWearState == .charging)
        Button { (action ?? { router.openDevices() })() } label: {
            PulseStrapChipContent(display: demoDisplay ?? display, connected: demoDisplay != nil || live.connected,
                                  syncing: live.backfilling)
                .equatable()
        }
        .buttonStyle(PulsePressStyle())
    }

    /// DEBUG `--demo-sync` stands in for a connected strap so the chip can be screenshotted.
    private var demoDisplay: LiquidTodayView.StrapBatteryDisplay? {
        #if DEBUG
        if DemoSyncHarness.active {
            return .charge(pct: DemoSyncHarness.batteryPercent, charging: DemoSyncHarness.charging, isRing: false)
        }
        #endif
        return nil
    }
}

private struct PulseStrapChipContent: View, Equatable {
    let display: LiquidTodayView.StrapBatteryDisplay
    let connected: Bool
    let syncing: Bool

    /// ZENO's low-battery threshold (WHOOP's own cut-off is unconfirmed).
    private static let lowBattery = 15.0

    var body: some View {
        HStack(spacing: 6) {
            if syncing {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(PulseTheme.positive)
            }
            if let text {
                Text(text)
                    .font(PulseType.numeral(13))
                    .foregroundStyle(textColor)
            }
            PulseStrapGlyph(connected: connected)
        }
        .frame(minWidth: PulseTheme.Layout.minTapTarget, minHeight: PulseTheme.Layout.minTapTarget, alignment: .trailing)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
        .accessibilityHint(String(localized: "Opens your strap"))
    }

    private var text: String? {
        switch display {
        case .charge(let pct, let charging, _): return "\(charging ? "⚡" : "")\(Int(pct.rounded()))%"
        case .pending: return "–%"
        case .offline, .notActiveDevice: return nil
        }
    }

    private var textColor: Color {
        if case .charge(let pct, let charging, _) = display, !charging, pct <= Self.lowBattery {
            return PulseTheme.recoveryLowText
        }
        return PulseTheme.textSecondary
    }

    private var accessibility: String {
        if syncing { return String(localized: "Syncing strap history") }
        switch display {
        case .offline, .notActiveDevice: return String(localized: "Strap not connected")
        case .pending: return String(localized: "Strap battery, no reading yet")
        case .charge(let pct, let charging, let isRing):
            let n = Int(pct.rounded())
            if isRing { return String(localized: "Ring battery \(n) percent") }
            return charging
                ? String(localized: "Strap battery \(n) percent, charging")
                : String(localized: "Strap battery \(n) percent")
        }
    }
}

/// An outline strap with its status dot: teal while connected, grey otherwise. ZENO's own glyph.
struct PulseStrapGlyph: View {
    let connected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(PulseTheme.textSecondary, lineWidth: 1.6)
                .frame(width: 13, height: 20)
                .overlay(
                    Capsule().fill(PulseTheme.textSecondary).frame(width: 5, height: 1.6),
                    alignment: .center)
                .padding(.top, 2)
                .padding(.trailing, 3)
            Circle()
                .fill(connected ? PulseTheme.positive : PulseTheme.textDisabled)
                .frame(width: 6, height: 6)
                .overlay(Circle().strokeBorder(PulseTheme.pageTop, lineWidth: 1))
        }
        .frame(width: 18, height: 24)
        .accessibilityHidden(true)
    }
}

/// The live heart-rate chip, present only while the strap is streaming.
struct PulseLiveHRChip: View {
    @EnvironmentObject private var live: LiveState

    var body: some View {
        let bpm: Int? = (live.connected && (live.heartRate ?? 0) > 0) ? live.heartRate : nil
        PulseLiveHRChipContent(bpm: bpm).equatable()
    }
}

private struct PulseLiveHRChipContent: View, Equatable {
    let bpm: Int?

    var body: some View {
        if let bpm {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PulseTheme.recoveryLowText)
                Text("\(bpm)")
                    .font(PulseType.numeral(13))
                    .foregroundStyle(PulseTheme.textPrimary)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 28)
            .background(Capsule(style: .continuous).fill(PulseTheme.card))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Live heart rate \(bpm) beats per minute"))
        }
    }
}
#endif
