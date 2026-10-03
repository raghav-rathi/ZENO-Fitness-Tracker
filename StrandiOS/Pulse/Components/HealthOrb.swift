#if os(iOS)
import SwiftUI

// MARK: - ZENO Age orb (WHOOP_UI_SPEC §3.20 item 1, §3.23 item 3, §2.1 "Healthspan orb")
//
// ZENO's own rendering, deliberately not WHOOP's art (§0: no WHOOP Age orb artwork). WHOOP draws an
// irregular blob of soft bokeh. ZENO draws a true circle: a lens whose rim is lit in the hue and whose
// particles sit on a sunflower (golden-angle) spiral, thickening toward the rim around a dark centre
// where the reading sits. The geometric spiral matches ZENO's thin geometric mark.
//
// It is drawn once and never moves (DR §8: no ambient motion). The dormant variant (still unlocking)
// fills the whole disc with grey and scatters the magenta speckles across it.

/// The orb, with its reading laid over the dark centre.
///
///     HealthAgeOrb(hue: .younger, diameter: 300) { HealthOrbReading(…) }
struct HealthAgeOrb<Content: View>: View {
    let hue: HealthAgeHue
    var diameter: CGFloat = 220
    @ViewBuilder var content: () -> Content

    init(hue: HealthAgeHue, diameter: CGFloat = 220, @ViewBuilder content: @escaping () -> Content) {
        self.hue = hue
        self.diameter = diameter
        self.content = content
    }

    var body: some View {
        let palette = HealthPalette.orb(hue)
        ZStack {
            HealthOrbArt(palette: palette, dormant: hue == .unlocking)
                .frame(width: diameter, height: diameter)
                .accessibilityHidden(true)
            content()
                .frame(width: diameter * 0.7)
        }
        .frame(width: diameter, height: diameter)
    }
}

extension HealthAgeOrb where Content == EmptyView {
    /// The orb alone (the dormant orb, the compact header).
    init(hue: HealthAgeHue, diameter: CGFloat = 220) {
        self.init(hue: hue, diameter: diameter) { EmptyView() }
    }
}

/// "34.5 / ZENO AGE / 7.2 years younger" inside the orb: the age (40 pt condensed on Healthspan, smaller
/// in the compact header), the label at 70%, and the years line in the hue.
struct HealthOrbReading: View {
    let age: String
    let yearsLine: String?
    let hue: HealthAgeHue
    var ageSize: CGFloat = PulseTextStyle.activityStrain.spec.size
    var showsLabel = true

    var body: some View {
        VStack(spacing: 2) {
            Text(age)
                .font(PulseType.numeral(ageSize))
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if showsLabel {
                Text(String(localized: "ZENO Age"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            if let yearsLine {
                Text(yearsLine)
                    .pulseText(.coachingTitle)
                    .foregroundStyle(HealthPalette.orb(hue).text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.top, 4)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .multilineTextAlignment(.center)
    }
}

/// The drawing itself: halo, lens, spiral particles and rim.
private struct HealthOrbArt: View {
    let palette: HealthPalette.Orb
    let dormant: Bool

    var body: some View {
        Canvas { context, size in
            let r = min(size.width, size.height) / 2
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let disc = Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2))

            // The lens: a dark centre opening into the hue at the rim (dormant: a grey sphere, lit at the top).
            if dormant {
                context.fill(disc, with: .linearGradient(
                    Gradient(colors: [palette.interior.opacity(0.95), palette.interior.opacity(0.75)]),
                    startPoint: CGPoint(x: centre.x, y: centre.y - r), endPoint: CGPoint(x: centre.x, y: centre.y + r)))
                context.fill(disc, with: .radialGradient(
                    Gradient(colors: [Color.white.opacity(0.10), Color.white.opacity(0)]),
                    center: CGPoint(x: centre.x - r * 0.25, y: centre.y - r * 0.4), startRadius: 0,
                    endRadius: r * 0.9))
            } else {
                context.fill(disc, with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color.black, location: 0.0),
                        .init(color: Color.black, location: 0.42),
                        .init(color: palette.interior.opacity(0.85), location: 0.74),
                        .init(color: palette.rim.opacity(0.55), location: 0.93),
                        .init(color: palette.rim.opacity(0.9), location: 1.0),
                    ]),
                    center: centre, startRadius: 0, endRadius: r))
            }

            // Particles on a golden-angle spiral: the ring thickens toward the rim (dormant: the whole disc).
            let count = Int((r * r) / 95) + 40
            let golden = Double.pi * (3 - 5.0.squareRoot())
            for i in 0..<count {
                let u = (Double(i) + 0.5) / Double(count)
                let inner = dormant ? 0.08 : 0.5
                let radial = inner + (0.965 - inner) * (dormant ? u.squareRoot() : pow(u, 0.55))
                let angle = Double(i) * golden
                let jitter = HealthOrbArt.noise(i, salt: 1)
                let d = r * CGFloat(radial)
                let p = CGPoint(x: centre.x + d * CGFloat(cos(angle)), y: centre.y + d * CGFloat(sin(angle)))
                let rimWeight = dormant ? 1.0 : max(0, (radial - inner) / (0.965 - inner))
                let size = CGFloat(0.7 + 2.1 * HealthOrbArt.noise(i, salt: 2) * (0.45 + 0.55 * rimWeight))
                    * max(1, r / 110)
                let alpha = (0.25 + 0.7 * jitter) * (dormant ? 0.9 : 0.35 + 0.65 * rimWeight)
                let dot = Path(ellipseIn: CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size))
                context.fill(dot, with: .color(palette.particles.opacity(alpha)))
            }

            // The rim, a hair brighter at the foot as if lit from below.
            context.stroke(disc, with: .linearGradient(
                Gradient(colors: [palette.rim.opacity(dormant ? 0.9 : 0.55), palette.rim]),
                startPoint: CGPoint(x: centre.x, y: centre.y - r), endPoint: CGPoint(x: centre.x, y: centre.y + r)),
                lineWidth: max(1.2, r / 90))
        }
        // The soft halo the page glow continues.
        .background(
            Circle()
                .fill(palette.rim.opacity(dormant ? 0.35 : 0.28))
                .blur(radius: 26)
        )
    }

    /// A fixed 0…1 value per particle (SplitMix64 over the index), so the orb is identical on every render.
    private static func noise(_ i: Int, salt: UInt64) -> Double {
        var z = UInt64(truncatingIfNeeded: i) &* 0x9E37_79B9_7F4A_7C15 &+ salt &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}

/// The small glyphs at the ends of the Pace of Aging ruler: a smooth sphere for "Slow" and a lumpy one for
/// "Fast" (ZENO's own shapes).
struct HealthPaceEndGlyph: View {
    let fast: Bool

    var body: some View {
        Group {
            if fast {
                HealthBlobShape()
                    .fill(HealthPalette.slowGlyph)
                    .overlay(HealthBlobShape().stroke(Color.white.opacity(0.35), lineWidth: 1))
            } else {
                Circle()
                    .fill(HealthPalette.slowGlyph)
                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}

/// A lumpy closed curve: a circle whose radius ripples with three lobes.
struct HealthBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let base = min(rect.width, rect.height) / 2
        var p = Path()
        let steps = 48
        for s in 0...steps {
            let a = Double(s) / Double(steps) * 2 * .pi
            let ripple = 0.86 + 0.1 * sin(3 * a + 0.6) + 0.04 * sin(5 * a)
            let pt = CGPoint(x: c.x + base * CGFloat(ripple * cos(a)), y: c.y + base * CGFloat(ripple * sin(a)))
            if s == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}
#endif
