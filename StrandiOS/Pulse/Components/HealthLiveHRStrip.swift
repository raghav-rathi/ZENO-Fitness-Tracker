#if os(iOS)
import SwiftUI
import StrandAnalytics
import WhoopProtocol

// MARK: - Live heart rate strip (WHOOP_UI_SPEC §3.21 item 3; §1.4: live HR left the Home header for here)

/// HEART RATE, no card (help-center/87, 90; reviews/33): a blue heart, the bpm (40 pt) over "BPM" and
/// "Zone 0", five zone dashes with the current one lit, and a live line running right over a faint grid
/// to a dashed now-line and a white end dot. Not streaming: "--" and "Not connected".
///
/// The only view here that observes `LiveState`: it keeps the last five minutes of beats it has seen
/// (seeded from the store's last five minutes, so the line is there when the screen opens) and hands an
/// Equatable value to the drawing, so a heartbeat re-renders the strip and nothing around it. Tapping it
/// opens ZENO's live console (§3.21 [Z]).
struct HealthLiveHRStrip: View {
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var profile: ProfileStore
    @Environment(\.pulseNavigator) private var navigator

    @State private var samples: [HealthHRPoint] = []
    #if DEBUG
    @State private var demoBPM: Int?
    #endif

    private static let span: TimeInterval = 5 * 60

    private var liveBPM: Int? {
        live.connected && (live.heartRate ?? 0) > 0 ? live.heartRate : nil
    }

    private var bpm: Int? {
        #if DEBUG
        if let demoBPM { return demoBPM }
        #endif
        return liveBPM
    }

    var body: some View {
        Button {
            navigator.open(.classic(.live))
        } label: {
            HealthLiveHRStripContent(bpm: bpm,
                                     zone: bpm.map { profile.hrZoneSet.zoneNumber(forBPM: Double($0)) },
                                     connected: live.connected || bpm != nil,
                                     samples: bpm == nil ? [] : samples)
                .equatable()
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens the live heart-rate console"))
        .onChange(of: live.heartRate) { _, value in
            guard let value, value > 0, live.connected else { return }
            append(HealthHRPoint(date: Date(), bpm: Double(value)))
        }
        .task { await seed() }
    }

    private func append(_ point: HealthHRPoint) {
        var next = samples
        next.append(point)
        let cutoff = point.date.addingTimeInterval(-Self.span)
        next.removeAll { $0.date < cutoff }
        samples = next
    }

    /// The last five minutes the strap has already written, so the line does not start empty.
    private func seed() async {
        let now = Int(Date().timeIntervalSince1970)
        #if DEBUG
        // `--demo-sync` stands in for a streaming strap in captures: replay the store's newest five minutes.
        if DemoSyncHarness.active && !live.connected {
            let stored = await repo.hrSamples(from: now - 6 * 3600, to: now, limit: 50_000)
            if let last = stored.last {
                samples = stored.filter { $0.ts >= last.ts - Int(Self.span) }
                    .map { HealthHRPoint(date: Date(timeIntervalSince1970: TimeInterval($0.ts)), bpm: Double($0.bpm)) }
                demoBPM = last.bpm
            }
            return
        }
        #endif
        guard live.connected else { return }
        let stored = await repo.hrSamples(from: now - Int(Self.span), to: now, limit: 2_000)
        let seeded = stored.map { HealthHRPoint(date: Date(timeIntervalSince1970: TimeInterval($0.ts)),
                                                bpm: Double($0.bpm)) }
        samples = (seeded + samples).sorted { $0.date < $1.date }
    }
}

/// One beat on the strip's line.
struct HealthHRPoint: Equatable {
    let date: Date
    let bpm: Double
}

private struct HealthLiveHRStripContent: View, Equatable {
    let bpm: Int?
    let zone: Int?
    let connected: Bool
    let samples: [HealthHRPoint]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Heart rate"))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                Image(systemName: "heart.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(bpm == nil ? PulseTheme.textTertiary : HealthPalette.liveHeart)
                    .padding(.top, 6)
                Text(bpm.map(String.init) ?? "--")
                    .font(PulseType.numeral(40))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .pulseNumericTransition()
                Text(String(localized: "BPM"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                Text(status)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize()
                    .padding(.top, 6)
                zoneDashes
                    .padding(.top, 2)
            }
            .frame(width: 104, alignment: .leading)
            chart
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .padding(.top, 26)
        }
        .padding(.vertical, 8)
        .background(grid)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Live heart rate"))
        .accessibilityValue(accessibility)
    }

    private var status: String {
        guard bpm != nil else {
            return connected ? String(localized: "Calibrating…") : String(localized: "Not connected")
        }
        return String(localized: "Zone \(zone ?? 0)")
    }

    private var accessibility: String {
        guard let bpm else { return status }
        return String(localized: "\(bpm) beats per minute, zone \(zone ?? 0)")
    }

    /// Five dashes, zone 1 to 5; the current one lit in its zone colour (zone 0 lights none).
    private var zoneDashes: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { z in
                RoundedRectangle(cornerRadius: 1, style: .circular)
                    .fill(z == zone ? PulseTheme.Zone.color(z) : Color.white.opacity(0.16))
                    .frame(width: 16, height: 3)
            }
        }
        .accessibilityHidden(true)
    }

    /// The faint square grid behind the whole strip.
    private var grid: some View {
        Canvas { context, size in
            let step: CGFloat = 16
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(HealthPalette.liveGrid), lineWidth: 0.5)
        }
        .mask(LinearGradient(colors: [.clear, .black, .black, .clear], startPoint: .top, endPoint: .bottom))
        .accessibilityHidden(true)
    }

    /// The line to the dashed now-line and its white end dot.
    private var chart: some View {
        Canvas { context, size in
            let nowX = size.width - 8
            // The dashed now-line.
            var dash = Path()
            dash.move(to: CGPoint(x: nowX, y: 0))
            dash.addLine(to: CGPoint(x: nowX, y: size.height))
            context.stroke(dash, with: .color(PulseTheme.textTertiary), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            guard let last = samples.last, samples.count > 1 else {
                let dot = CGRect(x: nowX - 4, y: size.height * 0.2 - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dot), with: .color(.white))
                return
            }
            let span: TimeInterval = 5 * 60
            let start = last.date.addingTimeInterval(-span)
            let values = samples.map(\.bpm)
            let lo = (values.min() ?? 50) - 8
            let hi = (values.max() ?? 90) + 8
            func point(_ s: HealthHRPoint) -> CGPoint {
                let fx = CGFloat(s.date.timeIntervalSince(start) / span)
                let fy = CGFloat((s.bpm - lo) / max(hi - lo, 1))
                return CGPoint(x: nowX * fx, y: size.height * (1 - fy))
            }
            var line = Path()
            for (i, s) in samples.enumerated() {
                let p = point(s)
                if i == 0 { line.move(to: p) } else { line.addLine(to: p) }
            }
            context.stroke(line, with: .color(HealthPalette.liveLine.opacity(0.35)),
                           style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            context.stroke(line, with: .color(HealthPalette.liveLine),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            let end = point(last)
            context.fill(Path(ellipseIn: CGRect(x: end.x - 6, y: end.y - 6, width: 12, height: 12)),
                         with: .color(Color.black.opacity(0.6)))
            context.fill(Path(ellipseIn: CGRect(x: end.x - 4, y: end.y - 4, width: 8, height: 8)),
                         with: .color(.white))
        }
        .accessibilityHidden(true)
    }
}
#endif
