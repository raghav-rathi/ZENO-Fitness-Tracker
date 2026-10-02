#if os(iOS)
import SwiftUI

// MARK: - ZENO's own marks (WHOOP_UI_SPEC §0)
//
// Wherever WHOOP prints its wordmark (above the dials, inside the deep-dive ring, at the end of the feed)
// or its "W" monogram (the AI button, the coach avatar), ZENO draws these original marks instead. They are
// drawn as thin geometric strokes, so they stay crisp at any size and never use WHOOP's assets or fonts.

/// "ZENO" in thin geometric strokes, sized to WHOOP's 72 × 12 pt wordmark slot by default.
struct PulseZenoWordmark: View {
    var color: Color = PulseTheme.textPrimary.opacity(0.85)
    var width: CGFloat = 72
    var height: CGFloat = 12

    var body: some View {
        PulseZenoWordmarkShape()
            .stroke(color, style: StrokeStyle(lineWidth: max(1, height * 0.11), lineCap: .butt, lineJoin: .miter))
            .frame(width: width, height: height)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: "ZENO"))
    }
}

/// The wordmark's outline: Z, E, N and O on a shared cap height, evenly spaced across the frame.
struct PulseZenoWordmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = max(0.5, rect.height * 0.055)
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

/// The coach avatar: the monogram inside a ring stroked with the AI gradient (violet → blue). Used by the
/// Coach button, the coach summary pill and the "Ask a question" row.
struct PulseCoachAvatar: View {
    /// The ring's outer diameter (32 pt in the Coach button).
    var size: CGFloat = PulseTheme.TabBarMetrics.coachRing
    var ringWidth: CGFloat = 1.75

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(gradient: PulseTheme.Gradients.aiRing, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: ringWidth)
            PulseZenoMonogramShape()
                .stroke(Color.white, style: StrokeStyle(lineWidth: max(1.2, size * 0.05), lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.36, height: size * 0.36)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
#endif
