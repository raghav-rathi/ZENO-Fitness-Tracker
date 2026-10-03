#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Pace of Aging ruler (WHOOP_UI_SPEC §2.5 "Pace of Aging ruler", §3.20 item 3, §3.23 item 4)

/// "○ Slow … Fast ◔" over the value (17 pt Bold) centred above a white 2 × 28 pt needle, on a comb of thin
/// ticks running −1.0x to 3.0x, with "-1.0x · 1.0x · 3.0x" each centred under its own tick (11 pt Bold
/// condensed, 50%; reviews/r44: the "-1.0x" centre is the first tick's x). The whole-x ticks are brighter,
/// and so are the ticks next to the needle (reviews/r44: 89 ticks, a brighter one at every 1.0x). Without a
/// pace the comb draws with no needle and the value reads "--".
struct HealthPaceRuler: View {
    /// nil while there is not enough history for a pace.
    let pace: Double?
    /// How far the comb sits in from each side, so its end labels, centred on the end ticks, stay clear of
    /// whatever is beside the ruler (reviews/r44: 2.5 pt inside the card's content, the label overhanging).
    var combInset: CGFloat = 6

    /// 4.0x across, 22 ticks per 1.0x (reviews/r44's pitch), so every whole x lands on a tick.
    private static let ticksPerUnit = 22
    private static var tickCount: Int { ticksPerUnit * 4 + 1 }

    private var fraction: Double? { pace.map(PaceOfAging.rulerFraction) }

    private var valueText: String {
        guard let pace else { return "--" }
        return String(localized: "\(PulseFormat.oneDecimal(pace))x")
    }

    /// The x of a point `f` (0…1) along the comb, on the pitch its ticks are laid on.
    private func tickX(_ f: Double, width: CGFloat) -> CGFloat {
        combInset + CGFloat(f) * (width - 2 * combInset - 1.5) + 0.75
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let width = geo.size.width
                // The needle's centre, on the same pitch the comb's ticks are laid on.
                let x = fraction.map { tickX($0, width: width) }
                ZStack(alignment: .topLeading) {
                    HStack(alignment: .center, spacing: 6) {
                        HealthPaceEndGlyph(fast: false)
                        Text(String(localized: "Slow"))
                            .pulseText(.rowSubline)
                            .foregroundStyle(PulseTheme.textTertiary)
                        Spacer(minLength: 8)
                        Text(String(localized: "Fast"))
                            .pulseText(.rowSubline)
                            .foregroundStyle(PulseTheme.textTertiary)
                        HealthPaceEndGlyph(fast: true)
                    }
                    .frame(width: width, height: 20)
                    Text(valueText)
                        .font(PulseType.font(.calloutValue))
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize()
                        .position(x: min(max(x ?? width / 2, 26), width - 26), y: clear ? 22 : 36)
                    comb(needleX: x.map { $0 - combInset })
                        .frame(width: max(0, width - 2 * combInset), height: 30)
                        .offset(x: combInset, y: clear ? 44 : 52)
                }
            }
            .frame(height: clear ? 74 : 82)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .accessibilityHidden(true)
            GeometryReader { geo in
                ForEach(Array(["-1.0x", "1.0x", "3.0x"].enumerated()), id: \.offset) { i, label in
                    Text(verbatim: label)
                        .fixedSize()
                        .position(x: tickX(Double(i) / 2, width: geo.size.width), y: geo.size.height / 2)
                }
            }
            .frame(height: 14)
            .font(PulseType.font(.axis))
            .foregroundStyle(PulseTheme.textTertiary)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Pace of Aging"))
        .accessibilityValue(accessibility)
    }

    /// Whether the value can ride level with "Slow" / "Fast" (reviews/r119): not when the needle is out by
    /// either end, where it would run into them, so it drops under them there.
    private var clear: Bool {
        guard let fraction else { return true }
        return fraction > 0.26 && fraction < 0.74
    }

    private var accessibility: String {
        guard let pace else { return String(localized: "Not enough history yet") }
        let value = PulseFormat.oneDecimal(pace)
        if pace < 1 { return String(localized: "\(value) times, slower than the calendar") }
        if pace > 1 { return String(localized: "\(value) times, faster than the calendar") }
        return String(localized: "\(value) times, the pace of the calendar")
    }

    /// The comb and the needle, drawn in one pass. `needleX` is the needle's centre.
    private func comb(needleX: CGFloat?) -> some View {
        Canvas { context, size in
            let n = Self.tickCount
            let pitch = (size.width - 1.5) / CGFloat(n - 1)
            let needleTick = needleX.map { Int((($0 - 0.75) / max(pitch, 0.001)).rounded()) }
            for i in 0..<n {
                let x = CGFloat(i) * pitch
                let major = i % Self.ticksPerUnit == 0
                var alpha = major ? 0.48 : 0.25
                if let t = needleTick {
                    let d = abs(i - t)
                    if d <= 5 { alpha = max(alpha, 0.62 - Double(d) * 0.07) }
                }
                let rect = CGRect(x: x, y: 3, width: 1.5, height: size.height - 6)
                context.fill(Path(roundedRect: rect, cornerRadius: 0.75), with: .color(Color.white.opacity(alpha)))
            }
            if let needleX {
                let x = min(max(needleX - 1, 0), size.width - 2)
                let rect = CGRect(x: x, y: 0, width: 2, height: size.height)
                context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(.white))
            }
        }
    }
}
#endif
