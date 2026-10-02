#if os(iOS)
import SwiftUI

// MARK: - Score dials (WHOOP_UI_SPEC §2.5, §1.4, §1.5; DR §5)
//
//                Home            Deep dive        Mini (sticky header)
//   Diameter     88              260              24
//   Stroke       6               15               2
//
// The track is white 10% and as wide as the arc. Arcs start at 12 o'clock and run clockwise, with FLAT
// ends rounded by about a fifth of the stroke (not round caps). A full circle is 100% for Sleep and
// Recovery and 21 for Strain. The Strain dial adds the day's optimal range as a light band on the track
// UNDER the arc, and the Strain Target as a 1 pt white tick at full stroke height OVER it; neither is
// drawn before Recovery has scored.
//
// Data in: `PulseDialContent`, a plain value. Map a snapshot to it in Model/ (see `PulseDialData`).

/// Everything a dial draws, already resolved: no store reads, no formatting in the view.
struct PulseDialContent: Equatable {
    /// The score's name, shown UPPERCASE under (Home) or inside (deep dive) the ring.
    var label: String
    /// The centred number: "80", "9.8", or "--" when there is no score yet.
    var valueText: String
    /// "%" for Sleep and Recovery; nil for Strain.
    var unitText: String?
    /// How much of the circle the arc covers, 0...1.
    var fraction: Double
    var color: Color
    /// The optimal range as fractions of the circle (Strain only), drawn on the track under the arc.
    var band: ClosedRange<Double>?
    /// The target as a fraction of the circle (Strain only), a white tick over the arc.
    var tick: Double?
    /// True while there is no score: the value draws in white 40%.
    var isPlaceholder: Bool
    /// An optional state line under the label ("CALIBRATING", whose night a carried value is).
    var caption: String?
    /// The whole dial as one VoiceOver sentence.
    var accessibilityLabel: String

    init(label: String, valueText: String, unitText: String? = nil, fraction: Double, color: Color,
         band: ClosedRange<Double>? = nil, tick: Double? = nil, isPlaceholder: Bool = false,
         caption: String? = nil, accessibilityLabel: String? = nil) {
        self.label = label
        self.valueText = valueText
        self.unitText = unitText
        self.fraction = max(0, min(1, fraction.isFinite ? fraction : 0))
        self.color = color
        self.band = band
        self.tick = tick
        self.isPlaceholder = isPlaceholder
        self.caption = caption
        self.accessibilityLabel = accessibilityLabel ?? "\(label), \(valueText)\(unitText ?? "")"
    }

    /// A percent dial (Sleep, Recovery). `percent` nil draws "--%" with an empty arc.
    static func percent(label: String, percent: Double?, color: Color, caption: String? = nil) -> PulseDialContent {
        guard let percent, percent.isFinite else {
            return PulseDialContent(label: label, valueText: "--", unitText: "%", fraction: 0,
                                    color: color, isPlaceholder: true, caption: caption,
                                    accessibilityLabel: String(localized: "\(label), no score yet"))
        }
        let shown = min(100, max(0, Int(percent.rounded())))
        return PulseDialContent(label: label, valueText: "\(shown)", unitText: "%",
                                fraction: Double(shown) / 100, color: color, caption: caption,
                                accessibilityLabel: String(localized: "\(label), \(shown) percent"))
    }

    /// A Strain dial on the 0–21 scale with the optimal range and target (both on the 0–21 axis).
    static func strain(label: String, value: Double?, optimalRange: ClosedRange<Double>?, target: Double?,
                       color: Color = PulseTheme.strain, caption: String? = nil) -> PulseDialContent {
        let band = optimalRange.map { max(0, $0.lowerBound / 21)...min(1, $0.upperBound / 21) }
        let tick = target.map { max(0, min(1, $0 / 21)) }
        guard let value, value.isFinite else {
            return PulseDialContent(label: label, valueText: "--", fraction: 0, color: color, band: band,
                                    tick: tick, isPlaceholder: true, caption: caption,
                                    accessibilityLabel: String(localized: "\(label), no score yet"))
        }
        let text = String(format: "%.1f", locale: AppLanguage.activeLocale, min(21, max(0, value)))
        return PulseDialContent(label: label, valueText: text, fraction: value / 21, color: color,
                                band: band, tick: tick, caption: caption,
                                accessibilityLabel: String(localized: "\(label), \(text) out of 21"))
    }
}

// MARK: - Geometry

/// An arc of a ring from `start` to `end` (fractions of a turn from 12 o'clock, clockwise), `thickness`
/// deep, with flat ends whose corners are rounded by `cornerRadius`. Animatable, so a value change
/// sweeps the arc rather than snapping it.
struct PulseRingSegment: Shape {
    var start: Double
    var end: Double
    var thickness: CGFloat
    var cornerRadius: CGFloat
    /// The shortest arc length (pt along the ring's centre line) drawn for a non-empty segment.
    var minimumLength: CGFloat = 0

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(start, end) }
        set {
            start = newValue.first
            end = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let outer = min(rect.width, rect.height) / 2
        let inner = max(0, outer - thickness)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let a0 = min(start, end)
        var a1 = max(start, end)
        guard a1 > a0, outer > 0 else { return Path() }
        let middle = (outer + inner) / 2
        if middle > 0 && minimumLength > 0 {
            let minimum = Double(minimumLength / (2 * .pi * middle))
            if a1 - a0 < minimum { a1 = a0 + minimum }
        }
        if a1 - a0 >= 1 {
            var ring = Path()
            ring.addRelativeArc(center: center, radius: outer, startAngle: .zero, delta: .radians(2 * .pi))
            ring.closeSubpath()
            if inner > 0 {
                ring.move(to: CGPoint(x: center.x + inner, y: center.y))
                ring.addRelativeArc(center: center, radius: inner, startAngle: .zero, delta: .radians(-2 * .pi))
                ring.closeSubpath()
            }
            return ring
        }

        let theta0 = a0 * 2 * .pi - .pi / 2
        let theta1 = a1 * 2 * .pi - .pi / 2
        let sweep = theta1 - theta0
        // Shrink the rounding for a very short arc so the four corners always fit.
        let s = sin(sweep / 2)
        var r = Double(min(cornerRadius, thickness / 2))
        r = min(r, Double(outer) * s / (1 + s))
        if s < 1 { r = min(r, Double(inner) * s / (1 - s)) }
        r = max(0, r)
        let rhoOuter = Double(outer) - r
        let rhoInner = Double(inner) + r
        let deltaOuter = rhoOuter > 0 ? asin(min(1, r / rhoOuter)) : 0
        let deltaInner = rhoInner > 0 ? asin(min(1, r / rhoInner)) : 0

        func point(_ radius: Double, _ angle: Double) -> CGPoint {
            CGPoint(x: center.x + CGFloat(radius * cos(angle)), y: center.y + CGFloat(radius * sin(angle)))
        }

        var p = Path()
        // Up the start edge, round the outer corner, along the outer arc, round the far corner, down
        // the end edge, round the inner corner, back along the inner arc, round the last corner.
        p.move(to: point(rhoInner * cos(deltaInner), theta0))
        p.addLine(to: point(rhoOuter * cos(deltaOuter), theta0))
        p.addRelativeArc(center: point(rhoOuter, theta0 + deltaOuter), radius: CGFloat(r),
                         startAngle: .radians(theta0 - .pi / 2), delta: .radians(.pi / 2 + deltaOuter))
        p.addRelativeArc(center: center, radius: outer, startAngle: .radians(theta0 + deltaOuter),
                         delta: .radians(sweep - 2 * deltaOuter))
        p.addRelativeArc(center: point(rhoOuter, theta1 - deltaOuter), radius: CGFloat(r),
                         startAngle: .radians(theta1 - deltaOuter), delta: .radians(.pi / 2 + deltaOuter))
        p.addLine(to: point(rhoInner * cos(deltaInner), theta1))
        p.addRelativeArc(center: point(rhoInner, theta1 - deltaInner), radius: CGFloat(r),
                         startAngle: .radians(theta1 + .pi / 2), delta: .radians(.pi / 2 - deltaInner))
        if inner > 0 {
            p.addRelativeArc(center: center, radius: inner, startAngle: .radians(theta1 - deltaInner),
                             delta: .radians(-(sweep - 2 * deltaInner)))
        }
        p.addRelativeArc(center: point(rhoInner, theta0 + deltaInner), radius: CGFloat(r),
                         startAngle: .radians(theta0 + deltaInner + .pi), delta: .radians(.pi / 2 - deltaInner))
        p.closeSubpath()
        return p
    }
}

/// A radial line across the ring at `fraction` of a turn: the Strain Target tick.
struct PulseRingTick: Shape {
    var fraction: Double
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let outer = min(rect.width, rect.height) / 2
        let inner = max(0, outer - thickness)
        let angle = fraction * 2 * .pi - .pi / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: CGPoint(x: center.x + inner * CGFloat(cos(angle)), y: center.y + inner * CGFloat(sin(angle))))
        p.addLine(to: CGPoint(x: center.x + outer * CGFloat(cos(angle)), y: center.y + outer * CGFloat(sin(angle))))
        return p
    }
}

// MARK: - Ring

/// A ring at any size: track, optional optimal-range band, the arc, optional target tick.
///
/// The arc animates only when `fraction` CHANGES (from its old value to the new one, 0.7 s ease-out), never
/// on appear, and not at all under Reduce Motion. A dial that first shows a loading state and then
/// its value therefore sweeps exactly once.
struct PulseRing: View {
    var fraction: Double
    var color: Color
    var diameter: CGFloat
    var thickness: CGFloat
    var band: ClosedRange<Double>?
    var tick: Double?
    var trackColor: Color = PulseTheme.track

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown: Double

    init(fraction: Double, color: Color, diameter: CGFloat, thickness: CGFloat,
         band: ClosedRange<Double>? = nil, tick: Double? = nil, trackColor: Color = PulseTheme.track) {
        self.fraction = fraction
        self.color = color
        self.diameter = diameter
        self.thickness = thickness
        self.band = band
        self.tick = tick
        self.trackColor = trackColor
        _shown = State(initialValue: PulseRing.clamp(fraction))
    }

    private static func clamp(_ value: Double) -> Double {
        value.isFinite ? max(0, min(1, value)) : 0
    }

    var body: some View {
        let corner = thickness * PulseTheme.Dial.cornerFraction
        ZStack {
            Circle()
                .strokeBorder(trackColor, lineWidth: thickness)
            if let band, band.upperBound > band.lowerBound {
                PulseRingSegment(start: band.lowerBound, end: band.upperBound, thickness: thickness,
                                 cornerRadius: corner)
                    .fill(PulseTheme.targetBand)
            }
            PulseRingSegment(start: 0, end: shown, thickness: thickness, cornerRadius: corner,
                             minimumLength: PulseTheme.Dial.minimumArc)
                .fill(color)
            if let tick {
                PulseRingTick(fraction: tick, thickness: thickness)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: PulseTheme.Dial.tickWidth, lineCap: .butt))
            }
        }
        .frame(width: diameter, height: diameter)
        .onChange(of: fraction) { _, new in
            let target = PulseRing.clamp(new)
            if reduceMotion {
                shown = target
            } else {
                withAnimation(PulseMotion.valueChange) { shown = target }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Press state

private struct PulseDialPressedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True while the button wrapping a dial is pressed (set by `PulseDialButtonStyle`).
    var pulseDialPressed: Bool {
        get { self[PulseDialPressedKey.self] }
        set { self[PulseDialPressedKey.self] = newValue }
    }
}

/// The button style for a dial: on touch-down the ring's interior fills with white 40%, released over
/// 0.15 s (§1.5). Apply it to the `NavigationLink` or `Button` around a `PulseScoreDial` or `PulseHeroRing`.
struct PulseDialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.pulseDialPressed, configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// The pressed disc inside a ring of `diameter` and `thickness`.
private struct PulseDialPressDisc: View {
    let diameter: CGFloat
    let thickness: CGFloat
    @Environment(\.pulseDialPressed) private var pressed

    var body: some View {
        Circle()
            .fill(PulseTheme.pressDisc)
            .frame(width: diameter - thickness * 2, height: diameter - thickness * 2)
            .opacity(pressed ? 1 : 0)
            .animation(pressed ? nil : PulseMotion.pressRelease, value: pressed)
            .accessibilityHidden(true)
    }
}

// MARK: - Home dial (88 / 6)

/// A Home score dial: the 88 pt ring with its value inside and "LABEL ›" 12 pt below.
///
///     NavigationLink(value: route) { PulseScoreDial(content: dial) }
///         .buttonStyle(PulseDialButtonStyle())
struct PulseScoreDial: View {
    let content: PulseDialContent
    /// Keep room for a caption line so a row whose neighbour has one stays aligned.
    var reservesCaption = false
    var diameter: CGFloat = PulseTheme.Dial.homeDiameter
    var thickness: CGFloat = PulseTheme.Dial.homeStroke

    var body: some View {
        VStack(spacing: PulseTheme.Dial.labelGap) {
            ZStack {
                PulseDialPressDisc(diameter: diameter, thickness: thickness)
                PulseRing(fraction: content.fraction, color: content.color, diameter: diameter,
                          thickness: thickness, band: content.band, tick: content.tick)
                value
            }
            .frame(width: diameter, height: diameter)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(content.label)
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    PulseChevron(size: 10)
                }
                if content.caption != nil || reservesCaption {
                    Text(content.caption ?? " ")
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .opacity(content.caption == nil ? 0 : 1)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var value: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(content.valueText)
                .font(PulseType.font(.dialValue))
                .pulseNumericTransition()
            if let unit = content.unitText {
                Text(unit).font(PulseType.font(.dialUnit))
            }
        }
        .foregroundStyle(content.isPlaceholder ? PulseTheme.textDisabled : PulseTheme.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, thickness + 6)
    }
}

// MARK: - Deep-dive ring (260 / 15)

/// The deep dive's hero ring: ZENO's mark, the score (58 pt + 32 pt unit), the label, and an optional
/// accessory under the label (the Sleep dive's Poor / Sufficient / Optimal segments).
///
///     PulseHeroRing(content: dial) { PulseMiniSegments(active: 2) }
struct PulseHeroRing<Accessory: View>: View {
    let content: PulseDialContent
    var diameter: CGFloat = PulseTheme.Dial.heroDiameter
    var thickness: CGFloat = PulseTheme.Dial.heroStroke
    @ViewBuilder var accessory: () -> Accessory

    init(content: PulseDialContent, diameter: CGFloat = PulseTheme.Dial.heroDiameter,
         thickness: CGFloat = PulseTheme.Dial.heroStroke,
         @ViewBuilder accessory: @escaping () -> Accessory) {
        self.content = content
        self.diameter = diameter
        self.thickness = thickness
        self.accessory = accessory
    }

    var body: some View {
        ZStack {
            PulseDialPressDisc(diameter: diameter, thickness: thickness)
            PulseRing(fraction: content.fraction, color: content.color, diameter: diameter,
                      thickness: thickness, band: content.band, tick: content.tick)
            VStack(spacing: 6) {
                PulseZenoWordmark(color: PulseTheme.textTertiary)
                    .padding(.bottom, 2)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(content.valueText)
                        .font(PulseType.font(.heroScore))
                        .pulseNumericTransition()
                    if let unit = content.unitText {
                        Text(unit).font(PulseType.font(.heroUnit))
                    }
                }
                .foregroundStyle(content.isPlaceholder ? PulseTheme.textDisabled : PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                Text(content.label)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if let caption = content.caption {
                    Text(caption)
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                accessory()
            }
            .padding(.horizontal, thickness + 24)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }
}

extension PulseHeroRing where Accessory == EmptyView {
    init(content: PulseDialContent, diameter: CGFloat = PulseTheme.Dial.heroDiameter,
         thickness: CGFloat = PulseTheme.Dial.heroStroke) {
        self.init(content: content, diameter: diameter, thickness: thickness) { EmptyView() }
    }
}

// MARK: - Mini rings (sticky header, 24 / 2)

/// A 24 pt ring with a 2 pt stroke.
struct PulseMiniRing: View {
    let content: PulseDialContent

    var body: some View {
        PulseRing(fraction: content.fraction, color: content.color,
                  diameter: PulseTheme.Dial.miniDiameter, thickness: PulseTheme.Dial.miniStroke)
    }
}

/// The compact sticky header WHOOP pins under the status bar once the dials scroll off (§1.4): three
/// mini rings, each followed by its label, on the page gradient with no card. Tapping one opens its dive.
struct PulseMiniRingRow: View {
    struct Item: Identifiable {
        let id: String
        let content: PulseDialContent
        let action: () -> Void
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                Button(action: item.action) {
                    HStack(spacing: 8) {
                        PulseMiniRing(content: item.content)
                        Text(item.content.label)
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(item.content.accessibilityLabel)
            }
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
    }
}
#endif
