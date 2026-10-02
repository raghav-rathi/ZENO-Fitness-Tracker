#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Dial

/// A score dial: a thin full-circle track, a thick rounded progress arc, the value centred, the score
/// name below.
///
/// The arc fills once when the dial appears and eases to a new value when the snapshot changes; both
/// are one-shot transitions, never a loop, and both are skipped under Reduce Motion. Nothing here draws
/// per frame at rest (the classic Today's animated canvases cost ~18% of a core idle).
struct PulseDial: View {
    let data: PulseDialData
    var diameter: CGFloat = 104
    var lineWidth: CGFloat = 9
    /// Show the score name and state caption under the dial.
    var showsLabel = true
    /// Keep room for a two-line caption even when this dial has none, so a row of dials whose
    /// neighbour carries a caption stays aligned. Off when no dial in the row has one.
    var reservesCaption = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var numeralBase: CGFloat = 34
    @State private var shown: Double = 0

    private var numeralSize: CGFloat {
        // Follow Dynamic Type, but never outgrow the ring.
        min(diameter * 0.40, max(diameter * 0.30, numeralBase * diameter / 104))
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(PulseTheme.track, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: shown)
                    .stroke(data.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                centre
            }
            .padding(lineWidth / 2)
            .frame(width: diameter, height: diameter)

            if showsLabel {
                VStack(spacing: 3) {
                    PulseLabel(data.score.displayName, color: PulseTheme.textSecondary)
                    if caption != nil || reservesCaption {
                        Text(caption ?? " ")
                            .font(.caption2)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.85)
                            .frame(minHeight: 28, alignment: .top)
                            .opacity(caption == nil ? 0 : 1)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(data.accessibilityLabel)
        .onAppear { fill(to: data.progress, duration: 0.9) }
        .onChange(of: data.progress) { _, new in fill(to: new, duration: 0.35) }
    }

    @ViewBuilder
    private var centre: some View {
        switch data.state {
        case .calibrating(let nights, let of):
            VStack(spacing: 0) {
                Text("\(nights)/\(of)")
                    .font(PulseTheme.numeral(numeralSize * 0.72))
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "nights"))
                    .font(.caption2)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        case .noData:
            Text("–")
                .font(PulseTheme.numeral(numeralSize))
                .foregroundStyle(PulseTheme.textTertiary)
        case .scored, .carried:
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(data.valueText)
                    .font(PulseTheme.numeral(numeralSize))
                    .foregroundStyle(PulseTheme.textPrimary)
                if let unit = data.unitText {
                    Text(unit)
                        .font(PulseTheme.numeral(numeralSize * 0.45, weight: .semibold))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, lineWidth + 4)
        }
    }

    private var caption: String? { data.caption }

    private func fill(to target: Double, duration: Double) {
        guard !reduceMotion else {
            shown = target
            return
        }
        withAnimation(.easeOut(duration: duration)) { shown = target }
    }
}

// MARK: - Strain target

/// The 0-21 strain track with the recommended range shaded and the day's strain filled in.
struct PulseStrainTargetBar: View {
    let target: PulseStrainTarget
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let lo = CGFloat(target.range.lowerBound / 21)
            let hi = CGFloat(target.range.upperBound / 21)
            let current = CGFloat(min(1, max(0, (target.current ?? 0) / 21)))
            let knob = height + 6
            ZStack(alignment: .leading) {
                Capsule().fill(PulseTheme.track)
                // The recommended range.
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(PulseTheme.strain.opacity(0.30))
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                            .strokeBorder(PulseTheme.strain.opacity(0.8), lineWidth: 1)
                    )
                    .frame(width: max(height, w * (hi - lo)))
                    .offset(x: w * lo)
                // The day so far.
                if target.current != nil {
                    Capsule()
                        .fill(PulseTheme.strain)
                        .frame(width: max(height, w * current))
                    Circle()
                        .fill(PulseTheme.textPrimary)
                        .frame(width: knob, height: knob)
                        .offset(x: min(max(0, w * current - knob / 2), w - knob))
                }
            }
            .frame(height: height)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: height + 8)
        .accessibilityHidden(true)
    }
}

/// The Strain Target card body: intent, range, the bar and where the day stands.
struct PulseStrainTargetContent: View {
    let target: PulseStrainTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                PulseLabel(String(localized: "Strain target"), color: PulseTheme.textSecondary)
                Spacer(minLength: 8)
                if let label = target.currentLabel {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(target.intentTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(PulseTheme.recoveryText(target.band))
                Text(target.rangeText)
                    .font(PulseTheme.numeral(22))
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer(minLength: 0)
            }
            PulseStrainTargetBar(target: target)
            HStack {
                Text("0").font(.caption2.monospacedDigit())
                Spacer()
                Text(target.progressText).font(.caption)
                Spacer()
                Text("21").font(.caption2.monospacedDigit())
            }
            .foregroundStyle(PulseTheme.textTertiary)
            if target.fromCarriedRecovery {
                Text(String(localized: "Based on your last scored Recovery."))
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        let base = String(localized: "Strain target: \(target.intentTitle), \(target.rangeText) out of 21.")
        guard let label = target.currentLabel else { return base + " " + target.progressText }
        return base + " " + "\(label). \(target.progressText)."
    }
}

// MARK: - Sparkline

/// A tiny static trend line with a dot on the latest point. No gestures, no animation, so it can sit
/// inside a tappable tile without competing for the tap.
struct PulseSparkline: View {
    let values: [Double]
    var tint: Color = PulseTheme.textSecondary

    var body: some View {
        GeometryReader { geo in
            if values.count >= 2, let lo = values.min(), let hi = values.max() {
                let span = max(hi - lo, 0.0001)
                let step = geo.size.width / CGFloat(values.count - 1)
                let inset: CGFloat = 3
                let h = geo.size.height - inset * 2
                let point: (Int) -> CGPoint = { i in
                    CGPoint(x: CGFloat(i) * step,
                            y: inset + h - CGFloat((values[i] - lo) / span) * h)
                }
                Path { p in
                    p.move(to: point(0))
                    for i in 1..<values.count { p.addLine(to: point(i)) }
                }
                .stroke(tint.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                Circle()
                    .fill(tint)
                    .frame(width: 5, height: 5)
                    .position(point(values.count - 1))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Comparison line

/// "▲ 8% vs 30-day avg".
struct PulseComparisonLine: View {
    let comparison: PulseComparison
    var showsCaption = true

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 8, weight: .bold))
            Text(comparison.text)
                .font(.caption.weight(.semibold).monospacedDigit())
            if showsCaption {
                Text(comparison.caption)
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(PulseTheme.textSecondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(comparison.accessibility)
    }

    private var symbol: String {
        switch comparison.direction {
        case .up: return "arrowtriangle.up.fill"
        case .down: return "arrowtriangle.down.fill"
        case .flat: return "minus"
        }
    }
}

// MARK: - Rows

/// A tappable list row: icon, title and subtitle, a trailing value, a chevron. At accessibility text
/// sizes the value moves under the title, so neither is truncated to make room for the other.
struct PulseRow<Icon: View>: View {
    let title: String
    var subtitle: String?
    var value: String?
    var valueCaption: String?
    var valueTint: Color = PulseTheme.textPrimary
    var showsChevron = true
    @ViewBuilder var icon: () -> Icon

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: typeSize.isAccessibilitySize ? .top : .center, spacing: 12) {
            icon()
                .frame(width: 36, height: 36)
                .background(Circle().fill(PulseTheme.cardRaised))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if typeSize.isAccessibilitySize { valueStack(alignment: .leading).padding(.top, 4) }
            }
            Spacer(minLength: 8)
            if !typeSize.isAccessibilitySize { valueStack(alignment: .trailing) }
            if showsChevron { PulseChevron() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func valueStack(alignment: HorizontalAlignment) -> some View {
        if value != nil || valueCaption != nil {
            VStack(alignment: alignment, spacing: 2) {
                if let value {
                    Text(value)
                        .font(PulseTheme.numeral(20))
                        .foregroundStyle(valueTint)
                }
                if let valueCaption {
                    Text(valueCaption)
                        .font(.caption2)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
    }
}

/// A row's round SF Symbol icon.
struct PulseRowIcon: View {
    let symbol: String
    var tint: Color = PulseTheme.textSecondary

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .accessibilityHidden(true)
    }
}

/// A hairline between rows in a grouped card.
struct PulseRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(PulseTheme.hairline)
            .frame(height: 1)
            .padding(.leading, 62)
    }
}

// MARK: - Big button

/// A full-width accent button (Breathe, Open full Sleep screen...).
struct PulseActionButtonLabel: View {
    let title: String
    var symbol: String?
    var prominent = false

    var body: some View {
        HStack(spacing: 8) {
            if let symbol { Image(systemName: symbol).font(.subheadline.weight(.semibold)) }
            Text(title).font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(prominent ? PulseTheme.onAccent : PulseTheme.accent)
        .frame(maxWidth: .infinity)
        .frame(minHeight: PulseTheme.minTapTarget)
        .background(
            Capsule(style: .continuous)
                .fill(prominent ? PulseTheme.accent : PulseTheme.cardRaised)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(prominent ? Color.clear : PulseTheme.accent.opacity(0.35), lineWidth: 1)
        )
        .contentShape(Capsule())
    }
}

// MARK: - Chip and page helpers (moved from the first theme file)

/// A compact text chip (e.g. "Today", a band word): a nested capsule, no border.
struct PulseChip: View {
    let text: String
    var tint: Color = PulseTheme.textSecondary
    var filled = false

    var body: some View {
        Text(text)
            .pulseText(.secondary)
            .foregroundStyle(filled ? PulseTheme.onAccent : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? tint : PulseTheme.nested)
            )
    }
}

extension View {
    /// DEBUG `--pulse-scroll <anchor>`: once `ready`, scroll to the tagged section so a screenshot can
    /// capture it (simctl cannot swipe). Compiles to nothing in Release.
    @ViewBuilder
    func pulseDebugScroll(_ proxy: ScrollViewProxy, ready: Bool) -> some View {
        #if DEBUG
        self.task(id: ready) {
            guard ready, let anchor = PulseDebugLaunch.scrollAnchor else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            proxy.scrollTo(anchor, anchor: .top)
        }
        #else
        self
        #endif
    }

    /// A band in the page's top colour behind the status bar on the tab roots that hide the navigation
    /// bar, so content scrolled up under the clock does not collide with it.
    func pulseStatusBarBackdrop() -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: 0)
                .background(PulseTheme.pageTop.ignoresSafeArea(edges: .top))
        }
    }

    /// The standard Pulse page: the fixed gradient behind, forced dark. The navigation bar stays clear at
    /// rest and takes the page's top colour once content scrolls under it, so a pushed page's title and
    /// back button never sit on top of scrolled cards.
    func pulsePage() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(PulseBackground())
            .toolbarBackground(PulseTheme.pageTop, for: .navigationBar)
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - Live leaves
//
// Each leaf below is the ONLY view that observes `LiveState` (64 published properties, several of them
// ticking every second). The wrapper reads the few values it shows and hands them to an Equatable
// content view, so a heart-rate tick re-renders one chip and nothing around it.

/// The strap chip: battery % and sync state; tap → Devices.
struct PulseStrapChip: View {
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var router: NavRouter

    var body: some View {
        let display = LiquidTodayView.StrapBatteryDisplay.resolve(
            activeIsWhoop: live.activeIsWhoop, connected: live.connected, batteryPct: live.batteryPct,
            charging: live.charging, ringPct: live.ouraBatteryPct,
            ringCharging: live.ouraWearState == .charging)
        Button { router.openDevices() } label: {
            PulseStrapChipContent(display: demoDisplay ?? display, syncing: live.backfilling)
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
    let syncing: Bool

    var body: some View {
        HStack(spacing: 5) {
            if syncing {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PulseTheme.accent)
            } else {
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            if let text {
                Text(text)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(PulseTheme.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .frame(minWidth: PulseTheme.minTapTarget, minHeight: 32)
        .background(Capsule(style: .continuous).fill(PulseTheme.cardRaised))
        .overlay(Capsule(style: .continuous).strokeBorder(PulseTheme.hairline, lineWidth: 1))
        .frame(minHeight: PulseTheme.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
        .accessibilityHint(String(localized: "Opens Devices"))
    }

    private var text: String? {
        if syncing { return String(localized: "Syncing") }
        switch display {
        case .charge(let pct, _, _): return "\(Int(pct.rounded()))%"
        case .pending: return "–"
        case .offline, .notActiveDevice: return nil
        }
    }

    private var symbol: String {
        switch display {
        case .offline, .notActiveDevice: return "antenna.radiowaves.left.and.right.slash"
        case .pending(let charging): return charging ? "battery.100.bolt" : "battery.50"
        case .charge(let pct, let charging, _):
            if charging { return "battery.100.bolt" }
            switch pct {
            case ..<15: return "battery.0"
            case ..<40: return "battery.25"
            case ..<65: return "battery.50"
            case ..<90: return "battery.75"
            default: return "battery.100"
            }
        }
    }

    private var tint: Color {
        switch display {
        case .offline, .notActiveDevice: return PulseTheme.textTertiary
        case .pending: return PulseTheme.textSecondary
        case .charge(let pct, let charging, _):
            if charging { return PulseTheme.accent }
            return pct < 15 ? PulseTheme.recoveryRedText : PulseTheme.textSecondary
        }
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
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PulseTheme.recoveryRedText)
                Text("\(bpm)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(PulseTheme.textPrimary)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 32)
            .background(Capsule(style: .continuous).fill(PulseTheme.cardRaised))
            .overlay(Capsule(style: .continuous).strokeBorder(PulseTheme.hairline, lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Live heart rate \(bpm) beats per minute"))
        }
    }
}
#endif
