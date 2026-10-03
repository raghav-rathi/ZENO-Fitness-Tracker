#if os(iOS)
import SwiftUI

// MARK: - Stress gauge (WHOOP_UI_SPEC §2.5 "Stress gauge", §3.22 item 3)

/// The Stress Monitor's gauge: a 225° arc symmetric about 12 o'clock (0.0 at −112.5°, 3.0 at +112.5°), a
/// bright 3 pt stroke in the stress scale over a dimmer 13 pt band of the same hues, a white needle pointing
/// in from the arc with a fading tail, "0.0" / "3.0" under the ends, and the value (52 pt Bold, standard
/// width), the level word in its colour and a time line in the centre. The 2026 captures draw it 0.58 of the
/// screen wide (completeness-critic/14, 15): 230 pt on a 402 pt iPhone.
struct HealthStressGauge: View {
    /// 0…3, or nil with nothing to show (no needle, and the value reads "--").
    let level: Double?
    /// The line under the word: the reading's time ("10:49 PM"), or what the value is when it is not one.
    let caption: String?
    var diameter: CGFloat = 230

    private static let sweep: Double = 225
    /// 12 o'clock is −90° in SwiftUI's angles; the arc starts 112.5° before it.
    private static var startAngle: Double { -90 - sweep / 2 }
    /// Trim margin, so the round start cap sits inside the gradient's first colour (an angular gradient
    /// wraps, and a cap drawn at 359° would take the last colour).
    private static let margin = 0.03

    private var band: PulseTheme.Stress.Level? { level.map { PulseTheme.Stress.Level(value: $0) } }

    var body: some View {
        let r = diameter / 2
        let endDrop = r * CGFloat(cos(67.5 * Double.pi / 180))
        let endX = r * CGFloat(sin(67.5 * Double.pi / 180))
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                arc
                    .frame(width: diameter, height: diameter)
                if let level {
                    needle(level: level, radius: r)
                        .frame(width: diameter, height: diameter)
                }
                centre
                    .frame(width: diameter, height: diameter)
                    .offset(y: endDrop * 0.3)
            }
            .frame(width: diameter, height: r + endDrop + 4, alignment: .top)
            ZStack {
                Text(verbatim: "0.0").offset(x: -endX)
                Text(verbatim: "3.0").offset(x: endX)
            }
            .font(PulseType.font(.axis))
            .foregroundStyle(PulseTheme.textTertiary)
            .frame(width: diameter)
            .padding(.top, 12)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Stress"))
        .accessibilityValue(accessibility)
    }

    private var accessibility: String {
        guard let level else { return String(localized: "No reading") }
        var parts = [String(localized: "\(PulseFormat.oneDecimal(level)) out of 3"), word(band)]
        if let caption { parts.append(caption) }
        return parts.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private func word(_ band: PulseTheme.Stress.Level?) -> String {
        switch band {
        case .low: return String(localized: "Low")
        case .medium: return String(localized: "Medium")
        case .high: return String(localized: "High")
        case nil: return ""
        }
    }

    private var centre: some View {
        VStack(spacing: 6) {
            Text(level.map { PulseFormat.oneDecimal($0) } ?? "--")
                .font(PulseType.font(.stressValue))
                .foregroundStyle(level == nil ? PulseTheme.textDisabled : PulseTheme.textPrimary)
                .pulseNumericTransition()
            if let band {
                Text(word(band))
                    .pulseText(.navTitle)
                    .foregroundStyle(band.color)
            }
            if let caption {
                Text(caption)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: diameter * 0.6)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    /// The dim band and the bright stroke, both in the stress scale along the sweep.
    private var arc: some View {
        let m = Self.margin
        let gradient = AngularGradient(stops: PulseTheme.Stress.stops, center: .center,
                                       startAngle: .degrees(m * 360),
                                       endAngle: .degrees(m * 360 + Self.sweep))
        let end = m + Self.sweep / 360
        return ZStack {
            Circle()
                .trim(from: m, to: end)
                .stroke(gradient, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                .opacity(0.22)
                .padding(10)
            Circle()
                .trim(from: m, to: end)
                .stroke(gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .padding(1.5)
        }
        .rotationEffect(.degrees(Self.startAngle - m * 360))
    }

    /// A white capsule standing on the arc and pointing at the centre, its tail fading out.
    private func needle(level: Double, radius r: CGFloat) -> some View {
        let angle = Self.startAngle + Self.sweep * min(1, max(0, level / 3))
        return LinearGradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .white, location: 0.4),
            .init(color: .white.opacity(0), location: 1),
        ], startPoint: .top, endPoint: .bottom)
            .frame(width: 5, height: 46)
            .clipShape(Capsule(style: .continuous))
            // Stand it on the ring's 12 o'clock point, then turn it about the centre.
            .offset(y: -r + 23)
            .rotationEffect(.degrees(angle + 90))
            .pulseAnimation(value: level)
    }
}
#endif
