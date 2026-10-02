#if os(iOS)
import SwiftUI
import UIKit

// MARK: - ZENO's own marks (WHOOP_UI_SPEC §0)
//
// Wherever WHOOP prints its wordmark (above the dials, inside the deep-dive ring, at the end of the feed)
// or its "W" monogram (the AI button, the coach avatar), ZENO draws these original marks instead. They are
// drawn as thin geometric strokes, so they stay crisp at any size and never use WHOOP's assets or fonts.

/// "ZENO" in thin geometric strokes, sized to WHOOP's 72 × 12 pt wordmark slot by default: white, strokes
/// ≈13% of the height (1.5 pt at 12), round joins, and the ink kept inside the slot (a miter join made the
/// Z and N overshoot to 13.4 pt).
struct PulseZenoWordmark: View {
    var color: Color = PulseTheme.textPrimary
    var width: CGFloat = 72
    var height: CGFloat = 12

    var body: some View {
        let line = max(1, height * 0.13)
        PulseZenoWordmarkShape(inset: line / 2)
            .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .butt, lineJoin: .round))
            .frame(width: width, height: height)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: "ZENO"))
    }
}

/// The wordmark's outline: Z, E, N and O on a shared cap height, evenly spaced across the frame. `inset`
/// is half the stroke, so a round-joined stroke's ink fills the frame exactly.
struct PulseZenoWordmarkShape: Shape {
    var inset: CGFloat = 0.75

    func path(in rect: CGRect) -> Path {
        let inset = max(0.5, self.inset)
        let top = rect.minY + inset
        let bottom = rect.maxY - inset
        let h = bottom - top
        // Glyph widths relative to the cap height, and the gap that fills the frame.
        let zW = h * 0.95, eW = h * 0.8, nW = h * 0.95, oW = h
        let gap = max(0, (rect.width - 2 * inset - zW - eW - nW - oW) / 3)
        var x = rect.minX + inset
        var p = Path()

        // Z
        p.move(to: CGPoint(x: x, y: top))
        p.addLine(to: CGPoint(x: x + zW, y: top))
        p.addLine(to: CGPoint(x: x, y: bottom))
        p.addLine(to: CGPoint(x: x + zW, y: bottom))
        x += zW + gap

        // E
        p.move(to: CGPoint(x: x + eW, y: top))
        p.addLine(to: CGPoint(x: x, y: top))
        p.addLine(to: CGPoint(x: x, y: bottom))
        p.addLine(to: CGPoint(x: x + eW, y: bottom))
        p.move(to: CGPoint(x: x, y: top + h / 2))
        p.addLine(to: CGPoint(x: x + eW * 0.82, y: top + h / 2))
        x += eW + gap

        // N
        p.move(to: CGPoint(x: x, y: bottom))
        p.addLine(to: CGPoint(x: x, y: top))
        p.addLine(to: CGPoint(x: x + nW, y: bottom))
        p.addLine(to: CGPoint(x: x + nW, y: top))
        x += nW + gap

        // O
        p.addEllipse(in: CGRect(x: x, y: top, width: oW, height: h))
        return p
    }
}

/// ZENO's monogram: a thin geometric "Z" with a short crossbar, for the coach button and avatar.
struct PulseZenoMonogramShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let x0 = rect.midX - side / 2, y0 = rect.midY - side / 2
        let top = y0 + side * 0.12, bottom = y0 + side * 0.88
        let left = x0 + side * 0.14, right = x0 + side * 0.86
        var p = Path()
        p.move(to: CGPoint(x: left, y: top))
        p.addLine(to: CGPoint(x: right, y: top))
        p.addLine(to: CGPoint(x: left, y: bottom))
        p.addLine(to: CGPoint(x: right, y: bottom))
        // The crossbar that makes it ZENO's rather than a plain letter.
        p.move(to: CGPoint(x: x0 + side * 0.34, y: rect.midY))
        p.addLine(to: CGPoint(x: x0 + side * 0.66, y: rect.midY))
        return p
    }
}

/// The coach avatar: the monogram inside a thin ring stroked with the AI gradient (violet → blue), over a
/// lit indigo orb (lighter at the top) with a faint halo. Used by the Coach button, the coach summary pill
/// and the "Ask a question" row.
struct PulseCoachAvatar: View {
    /// The ring's outer diameter (32 pt in the Coach button).
    var size: CGFloat = PulseTheme.TabBarMetrics.coachRing
    var ringWidth: CGFloat = PulseTheme.TabBarMetrics.coachRingWidth
    /// The lit orb inside the ring (off for the outlined "Ask a question" glyph).
    var showsOrb = true

    var body: some View {
        ZStack {
            if showsOrb {
                Circle()
                    .fill(PulseTheme.Coach.halo)
                    .frame(width: size + 6, height: size + 6)
                    .blur(radius: 3)
                Circle()
                    .fill(LinearGradient(gradient: PulseTheme.Coach.orb, startPoint: .top, endPoint: .bottom))
            }
            Circle()
                .strokeBorder(
                    LinearGradient(gradient: PulseTheme.Gradients.aiRing, startPoint: .leading, endPoint: .trailing),
                    lineWidth: ringWidth)
            PulseZenoMonogramShape()
                .stroke(Color.white, style: StrokeStyle(lineWidth: max(1.2, min(1.5, size * 0.045)),
                                                        lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.36, height: size * 0.36)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Avatar, streak and strap glyphs (§1.4)

/// The wearer's avatar: the photo when there is one, else initials on a coloured disc when a name is
/// known, else a person outline on white 10% (onboarding/31a). ZENO's own; never the app's brand mark.
struct PulseAvatar: View {
    var imageData: Data?
    /// The wearer's name, for initials; nil or blank draws the person outline.
    var name: String?
    var size: CGFloat = PulseTheme.Header.avatar

    var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else if let initials {
                ZStack {
                    Circle().fill(Self.discColor(for: initials))
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            } else {
                ZStack {
                    Circle().fill(PulseTheme.avatarFallback)
                    Image(systemName: "person")
                        .font(.system(size: size * 0.45, weight: .regular))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var image: Image? {
        guard let imageData, let ui = UIImage(data: imageData) else { return nil }
        return Image(uiImage: ui)
    }

    private var initials: String? {
        let parts = (name ?? "").split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first.map { String($0).uppercased() } }.joined()
        return letters.isEmpty ? nil : letters
    }

    /// A stable colour per name (WHOOP: "IW" pink, "NR" purple, "MO" green).
    static func discColor(for initials: String) -> Color {
        let palette = [Color(hex: "#C2477E"), Color(hex: "#7A5AC8"), Color(hex: "#2E9E6A"), Color(hex: "#3A7BC8"),
                       Color(hex: "#C47A2C")]
        let sum = initials.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[sum % palette.count]
    }
}

/// The day-streak pill tucked under the avatar's right edge (§1.4): a white-5% capsule holding the flame,
/// tinted by streak length, and the day count (13 pt Bold condensed). Hidden on past days by its caller.
struct PulseStreakPill: View {
    let days: Int
    /// The avatar's diameter: the pill starts under its centre and the avatar overlaps it.
    var avatarSize: CGFloat = PulseTheme.Header.avatar

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(PulseTheme.Streak.flame(days: days))
            Text(verbatim: "\(days)")
                .font(PulseType.font(.headerNumeral))
                .foregroundStyle(PulseTheme.textPrimary)
                .pulseNumericTransition()
        }
        .fixedSize()
        .padding(.leading, avatarSize / 2 + 16)
        .padding(.trailing, 11)
        .frame(height: avatarSize)
        .background(Capsule(style: .circular).fill(PulseTheme.streakPill))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Day streak, \(days) days"))
    }
}

/// ZENO's strap glyph: a fitness band seen from the front (a rounded pod between two strap ends), drawn as
/// a 1.5 pt outline. Original art; never WHOOP's strap render.
struct PulseStrapShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let strapW = w * 0.56
        let podTop = rect.minY + h * 0.26, podBottom = rect.maxY - h * 0.26
        let strapX = rect.midX - strapW / 2
        var p = Path()
        // The pod.
        p.addRoundedRect(in: CGRect(x: rect.minX, y: podTop, width: w, height: podBottom - podTop),
                         cornerSize: CGSize(width: w * 0.24, height: w * 0.24), style: .continuous)
        // The strap ends above and below, open where they meet the pod.
        let r = strapW * 0.3
        p.move(to: CGPoint(x: strapX, y: podTop))
        p.addLine(to: CGPoint(x: strapX, y: rect.minY + r))
        p.addQuadCurve(to: CGPoint(x: strapX + r, y: rect.minY), control: CGPoint(x: strapX, y: rect.minY))
        p.addLine(to: CGPoint(x: strapX + strapW - r, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: strapX + strapW, y: rect.minY + r),
                       control: CGPoint(x: strapX + strapW, y: rect.minY))
        p.addLine(to: CGPoint(x: strapX + strapW, y: podTop))
        p.move(to: CGPoint(x: strapX, y: podBottom))
        p.addLine(to: CGPoint(x: strapX, y: rect.maxY - r))
        p.addQuadCurve(to: CGPoint(x: strapX + r, y: rect.maxY), control: CGPoint(x: strapX, y: rect.maxY))
        p.addLine(to: CGPoint(x: strapX + strapW - r, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: strapX + strapW, y: rect.maxY - r),
                       control: CGPoint(x: strapX + strapW, y: rect.maxY))
        p.addLine(to: CGPoint(x: strapX + strapW, y: podBottom))
        return p
    }
}

/// The strap glyph with vibration marks either side: SET ALARM's icon (a strap that buzzes you awake).
struct PulseStrapVibrateGlyph: View {
    var height: CGFloat = 15

    var body: some View {
        HStack(spacing: height * 0.12) {
            PulseVibrationMarks(leading: true).frame(width: height * 0.22, height: height * 0.6)
            PulseStrapShape()
                .stroke(style: StrokeStyle(lineWidth: max(1.1, height * 0.08), lineCap: .round, lineJoin: .round))
                .frame(width: height * 0.62, height: height)
            PulseVibrationMarks(leading: false).frame(width: height * 0.22, height: height * 0.6)
        }
        .accessibilityHidden(true)
    }
}

/// Two short arcs: the buzz either side of the strap glyph.
private struct PulseVibrationMarks: View {
    let leading: Bool

    var body: some View {
        Canvas { context, size in
            for (i, scale) in [1.0, 0.55].enumerated() {
                var p = Path()
                let x = leading ? size.width * (1 - CGFloat(i) * 0.7) : size.width * CGFloat(i) * 0.7
                let h = size.height * CGFloat(scale)
                let bulge = (leading ? -1.0 : 1.0) * size.width * 0.35
                p.move(to: CGPoint(x: x, y: (size.height - h) / 2))
                p.addQuadCurve(to: CGPoint(x: x, y: (size.height + h) / 2),
                               control: CGPoint(x: x + bulge, y: size.height / 2))
                context.stroke(p, with: .foreground, style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            }
        }
    }
}
#endif
