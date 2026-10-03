#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Onboarding art (WHOOP_UI_SPEC §0, §3.38)
//
// WHOOP illustrates each step with a grey "clay" 3-D render carrying one blue accent, and the device steps
// with photoreal strap renders. ZENO may copy neither (§0): these are original drawings built from SF
// Symbols and plain shapes, in the same place and at the same size, so the steps keep WHOOP's proportions
// without its art. Nothing here moves on its own (no ambient animation).

/// A step's illustration: an SF Symbol in a grey top-lit gradient (the clay look) with one small blue
/// accent symbol just off its corner, standing on the bottom of the template's ≈90 pt slot.
struct PulseOnboardingIllustration: View {
    let symbol: String
    var accent: String?
    /// Which corner of the symbol the accent sits on.
    var accentAlignment: Alignment = .bottomTrailing

    /// The glyph's height. WHOOP's clay renders stand 80–90 pt tall (15b, 22d); the symbol is drawn
    /// resizable so its frame is its ink, and the gap to the title is exactly the template's (a symbol
    /// set at a font size carries a descent that differs from symbol to symbol).
    static let glyphHeight: CGFloat = 80

    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(height: Self.glyphHeight)
            .foregroundStyle(LinearGradient(colors: [PulseOnboardingColors.illustrationTop,
                                                     PulseOnboardingColors.illustrationBottom],
                                            startPoint: .top, endPoint: .bottom))
            .overlay(alignment: accentAlignment) {
                if let accent {
                    Image(systemName: accent)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(PulseOnboardingColors.accentBlue)
                        .offset(x: 12, y: accentAlignment == .topTrailing ? -8 : 4)
                }
            }
            .frame(height: PulseOnboardingMetrics.illustrationHeight, alignment: .bottomLeading)
            .accessibilityHidden(true)
    }
}

// MARK: - The strap

/// ZENO's strap drawn from the front: a dark knit band running top to bottom and a rounded pod across it.
/// `led` circles the pod's status light in blue (Check for Pairing Mode); `charging` slides a charger onto
/// the pod with a bolt (Wake Up Your Strap). Original art, never WHOOP's render.
struct PulseStrapIllustration: View {
    var led = false
    var charging = false
    /// The pod's width; everything else scales from it.
    var podWidth: CGFloat = 120
    /// The band's length, top to bottom (2.3 pod widths unless a slot sets it).
    var length: CGFloat?

    var body: some View {
        let w = podWidth
        let h = length ?? w * 2.3
        ZStack {
            // The band, longer than the pod, fading out at both ends into the page.
            RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                .fill(LinearGradient(colors: PulseOnboardingColors.strapBand,
                                     startPoint: .leading, endPoint: .trailing))
                .overlay(knit(width: w * 0.78))
                .frame(width: w * 0.78, height: h)
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0),
                                             .init(color: .black, location: 0.22),
                                             .init(color: .black, location: 0.78),
                                             .init(color: .clear, location: 1)],
                                     startPoint: .top, endPoint: .bottom))
            // The pod.
            RoundedRectangle(cornerRadius: w * 0.2, style: .continuous)
                .fill(LinearGradient(colors: PulseOnboardingColors.strapPod,
                                     startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: w * 0.2, style: .continuous)
                        .strokeBorder(LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.02)],
                                                     startPoint: .top, endPoint: .bottom), lineWidth: 1))
                .overlay(alignment: .center) {
                    PulseZenoMonogramShape()
                        .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                        .frame(width: w * 0.14, height: w * 0.14)
                }
                .frame(width: w, height: w * 0.62)
            if led {
                ledHighlight(w)
            }
            if charging {
                charger(w)
            }
        }
        .frame(width: w * 1.5, height: h)
        .accessibilityHidden(true)
    }

    /// Faint horizontal ribs: the band's knit.
    private func knit(width: CGFloat) -> some View {
        Canvas { context, size in
            var y: CGFloat = 3
            while y < size.height {
                var p = Path()
                p.move(to: CGPoint(x: 4, y: y))
                p.addLine(to: CGPoint(x: size.width - 4, y: y))
                context.stroke(p, with: .color(Color.white.opacity(0.035)), lineWidth: 1)
                y += 5
            }
        }
    }

    /// The status light on the pod's right side, circled in blue.
    private func ledHighlight(_ w: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(PulseOnboardingColors.accentBlue.opacity(0.18))
                .frame(width: w * 0.42, height: w * 0.42)
            Circle()
                .strokeBorder(PulseOnboardingColors.accentBlue, lineWidth: 2)
                .frame(width: w * 0.42, height: w * 0.42)
            Circle()
                .fill(PulseOnboardingColors.strapLight)
                .frame(width: w * 0.07, height: w * 0.07)
        }
        .offset(x: w * 0.5, y: -w * 0.06)
    }

    /// A charger seated on top of the pod with a bolt.
    private func charger(_ w: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
                .fill(LinearGradient(colors: PulseOnboardingColors.charger,
                                     startPoint: .top, endPoint: .bottom))
            Image(systemName: "bolt.fill")
                .font(.system(size: w * 0.16, weight: .bold))
                .foregroundStyle(PulseOnboardingColors.accentBlue)
        }
        .frame(width: w * 0.82, height: w * 0.34)
        .offset(y: -w * 0.42)
    }
}

// MARK: - Phone, strap and the link between them

/// CONNECTING / CONNECTED / CONNECTION FAILED: the phone at the left edge and the strap at the right,
/// joined by a line with a status circle in the middle (onboarding/11–13). Dotted blue while connecting,
/// solid green with a glowing ✓ once connected, red with ✕ when it failed.
struct PulseConnectionArt: View {
    enum Phase: Equatable { case connecting, connected, failed }

    let state: Phase

    private var tint: Color {
        switch state {
        case .connecting: return PulseOnboardingColors.accentBlue
        case .connected: return PulseTheme.Onboarding.commitGreen
        case .failed: return PulseTheme.Onboarding.pairingFailure
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midY = geo.size.height / 2
            let phoneRight = w * 0.30
            let strapLeft = w * 0.73
            ZStack {
                // The link.
                Path { p in
                    p.move(to: CGPoint(x: phoneRight, y: midY))
                    p.addLine(to: CGPoint(x: strapLeft, y: midY))
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round,
                                                 dash: state == .connecting ? [2, 7] : []))
                endDot(at: CGPoint(x: phoneRight, y: midY))
                endDot(at: CGPoint(x: strapLeft, y: midY))
                statusCircle
                    .position(x: (phoneRight + strapLeft) / 2, y: midY)
                phone
                    .frame(width: w * 0.34, height: min(geo.size.height * 0.9, 300))
                    .position(x: phoneRight - w * 0.17, y: midY)
                PulseStrapIllustration(podWidth: min(86, w * 0.22))
                    .position(x: strapLeft + min(86, w * 0.22) / 2 + 4, y: midY)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        switch state {
        case .connecting: return String(localized: "Connecting your iPhone to your strap")
        case .connected: return String(localized: "Your iPhone and your strap are connected")
        case .failed: return String(localized: "Your iPhone could not connect to your strap")
        }
    }

    private func endDot(at point: CGPoint) -> some View {
        Circle()
            .fill(tint)
            .frame(width: 13, height: 13)
            .position(point)
    }

    @ViewBuilder
    private var statusCircle: some View {
        switch state {
        case .connecting:
            Circle()
                .fill(PulseOnboardingColors.connectingDisc)
                .overlay(Circle().strokeBorder(tint, lineWidth: 2.5))
                .overlay(
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tint))
                .frame(width: 68, height: 68)
        case .connected:
            ZStack {
                Circle()
                    .fill(tint.opacity(0.35))
                    .frame(width: 96, height: 96)
                    .blur(radius: 14)
                Circle()
                    .fill(tint)
                    .frame(width: 68, height: 68)
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        case .failed:
            ZStack {
                Circle()
                    .fill(tint.opacity(0.3))
                    .frame(width: 92, height: 92)
                    .blur(radius: 12)
                Circle()
                    .fill(PulseOnboardingColors.failedDisc)
                    .overlay(Circle().strokeBorder(tint, lineWidth: 4))
                    .frame(width: 68, height: 68)
                Image(systemName: "xmark")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
        }
    }

    /// A black phone with a thin rim and ZENO's monogram, cut by the screen's left edge.
    private var phone: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(LinearGradient(colors: PulseOnboardingColors.phone,
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5))
            .overlay(
                PulseZenoMonogramShape()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 30, height: 30)
                    .offset(x: 18))
    }
}

// MARK: - The calibration wheel (What to Expect Next)

/// A night-by-night wheel of the first two weeks: a dark track with a dot per milestone night, the
/// first-calibration span highlighted, and the strap in the middle with a caption. The milestones come
/// from the analytics constants the scores really wait for (`PulseOnboardingMilestone`).
struct PulseCalibrationWheel: View {
    let milestones: [PulseOnboardingMilestone]
    /// The nights the wheel spans.
    let nights: Int
    /// The first-calibration span (nights 1…n) that is highlighted.
    let highlightThrough: Int

    /// The wheel's outer diameter.
    static let size: CGFloat = 232

    var body: some View {
        let size = Self.size
        let track: CGFloat = 30
        let radius = (size - track) / 2
        ZStack {
            Circle()
                .stroke(PulseOnboardingColors.wheelTrack, lineWidth: track)
                .frame(width: size - track, height: size - track)
            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: fraction(highlightThrough))
                .stroke(LinearGradient(colors: PulseOnboardingColors.wheelSpan,
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: track - 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: size - track, height: size - track)
            ForEach(milestones) { milestone in
                milestoneDot(milestone, radius: radius)
            }
            VStack(spacing: 10) {
                PulseStrapIllustration(podWidth: 46)
                    .frame(height: 70)
                Text(String(localized: "New scores unlock nightly"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 130)
                    // The wheel cannot grow, so its caption stops growing before it covers the strap
                    // (VoiceOver reads the wheel as a whole).
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Calibration timeline"))
        .accessibilityValue(milestones.map(\.accessibilityText).joined(separator: ". "))
    }

    /// Where night `n` sits around the wheel: the first night just past 12 o'clock, the last just before
    /// it, so the circle reads as the first `nights` nights.
    private func fraction(_ n: Int) -> CGFloat {
        CGFloat(max(0, min(nights, n))) / CGFloat(max(1, nights + 1))
    }

    private func milestoneDot(_ milestone: PulseOnboardingMilestone, radius: CGFloat) -> some View {
        let angle = Angle.degrees(Double(fraction(milestone.night)) * 360 - 90)
        let lit = milestone.night <= highlightThrough
        return ZStack {
            Circle()
                .fill(lit ? Color.white : PulseOnboardingColors.milestoneOff)
                .frame(width: 26, height: 26)
            Image(systemName: milestone.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(lit ? PulseOnboardingColors.milestoneGlyph : PulseTheme.textSecondary)
        }
        .offset(x: cos(angle.radians) * radius, y: sin(angle.radians) * radius)
    }
}

/// One thing that unlocks on a given night of wear.
struct PulseOnboardingMilestone: Identifiable, Equatable {
    let night: Int
    let symbol: String
    let title: String

    var id: String { "\(night)-\(title)" }

    var accessibilityText: String {
        String(localized: "Night \(night): \(title)")
    }
}
#endif
