#if os(iOS)
import SwiftUI

// MARK: - Notched callout, contributor rows and legend wells (WHOOP_UI_SPEC §2.6 items 8, 11, 26)

/// A rounded rectangle with a small triangular notch on its top edge, pointing up at whatever sits above
/// (the deep-dive ring, a value in the card). The notch's height is part of the shape's frame.
struct PulseNotchedRectangle: Shape {
    var cornerRadius: CGFloat = PulseTheme.Radius.card
    var notchWidth: CGFloat = 15
    var notchHeight: CGFloat = 7
    /// Where the notch's tip sits along the top edge, as a fraction of the width.
    var notchPosition: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY + notchHeight, width: rect.width,
                          height: max(0, rect.height - notchHeight))
        let r = min(cornerRadius, body.width / 2, body.height / 2)
        let tipX = rect.minX + rect.width * notchPosition
        let half = notchWidth / 2
        let left = max(body.minX + r, tipX - half)
        let right = min(body.maxX - r, tipX + half)
        var p = Path()
        p.move(to: CGPoint(x: body.minX + r, y: body.minY))
        p.addLine(to: CGPoint(x: left, y: body.minY))
        p.addLine(to: CGPoint(x: tipX, y: rect.minY))
        p.addLine(to: CGPoint(x: right, y: body.minY))
        p.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))
        p.addArc(center: CGPoint(x: body.maxX - r, y: body.minY + r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))
        p.addArc(center: CGPoint(x: body.maxX - r, y: body.maxY - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: body.minX + r, y: body.maxY))
        p.addArc(center: CGPoint(x: body.minX + r, y: body.maxY - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: body.minX, y: body.minY + r))
        p.addArc(center: CGPoint(x: body.minX + r, y: body.minY + r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// The deep dive's contributor callout: no flat fill, only a radial glow from the pointer (white 10% →
/// 0 by ≈190 pt) and a top-lit 1 pt stroke, with a 15 × 7 pt pointer at the top centre.
///
///     PulseCallout {
///         PulseCalloutRow(symbol: "waveform.path.ecg", title: "Heart rate variability", value: "124", …)
///         PulseDivider(leadingInset: 16, trailingInset: 16)
///         …
///         PulseLegendWell { PulseLegendTodayVsBaseline() }
///     }
struct PulseCallout<Content: View>: View {
    var notchPosition: CGFloat = 0.5
    @ViewBuilder var content: () -> Content

    init(notchPosition: CGFloat = 0.5, @ViewBuilder content: @escaping () -> Content) {
        self.notchPosition = notchPosition
        self.content = content
    }

    var body: some View {
        let shape = PulseNotchedRectangle(notchPosition: notchPosition)
        VStack(spacing: 0) {
            content()
        }
        .padding(.top, 7)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(
            shape.fill(RadialGradient(colors: [PulseTheme.calloutGlow, PulseTheme.calloutGlow.opacity(0)],
                                      center: UnitPoint(x: notchPosition, y: 0),
                                      startRadius: 0, endRadius: 190)))
        .overlay(
            shape.stroke(LinearGradient(colors: [PulseTheme.calloutRim, PulseTheme.calloutRim.opacity(0)],
                                        startPoint: .top, endPoint: .bottom),
                         lineWidth: 1))
    }
}

/// One contributor row inside a `PulseCallout` (66 pt pitch, 2026): a 20 pt icon at 50%, an 11 pt UPPERCASE
/// label, then at the right the value (21 pt Bold condensed; a unit, if any, small and tertiary) over its
/// 30-day baseline as a bare number (13 pt, 50%, right-aligned) and the trend glyph. Sleep's rows show the
/// Poor / Sufficient / Optimal segments instead of a baseline.
struct PulseCalloutRow: View {
    let symbol: String
    let title: String
    let value: String
    var unit: String?
    var baseline: String?
    var trend: PulseTrend?
    /// 0 / 1 / 2 lights Poor / Sufficient / Optimal before the value (Sleep's contributors).
    var segments: Int?

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: 20)
                .padding(.trailing, 9)
                .accessibilityHidden(true)
            PulseWordWrapText(title, style: .label)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            if let segments {
                PulseMiniSegments(active: segments)
                    .padding(.trailing, 14)
            }
            VStack(alignment: .trailing, spacing: 1) {
                PulseValueText(value: value, unit: unit, style: .calloutValue, unitStyle: .tileUnit)
                if let baseline {
                    Text(baseline)
                        .pulseText(.baseline)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            if let trend {
                PulseTrendGlyph(trend: trend)
                    .padding(.leading, 6)
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 18)
        .frame(minHeight: PulseTheme.Row.contributorPitch)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        var parts = ["\(title), \(value)\(unit.map { " \($0)" } ?? "")"]
        if let baseline { parts.append(String(localized: "baseline \(baseline)")) }
        if let trend { parts.append(trend.accessibilityDescription) }
        return parts.joined(separator: ", ")
    }
}

/// A legend well: black 50%, radius 8, 31 pt tall, inset 16 inside its card, 12 pt under the last row.
struct PulseLegendWell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 14) {
            content()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: PulseTheme.Row.legendWell)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular).fill(PulseTheme.well))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

/// "▲▼ Today vs. last 30 days": ▲ teal, ▼ orange, "Today" white Semibold, the rest 70%.
struct PulseLegendTodayVsBaseline: View {
    var period: String = String(localized: "last 30 days")

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 2) {
                PulseTriangle(pointsUp: true).fill(PulseTheme.positive).frame(width: 7, height: 6)
                PulseTriangle(pointsUp: false).fill(PulseTheme.negative).frame(width: 7, height: 6)
            }
            (Text(String(localized: "Today")).fontWeight(.semibold).foregroundColor(PulseTheme.textPrimary)
             + Text(" ") + Text(String(localized: "vs. \(period)")).foregroundColor(PulseTheme.textSecondary))
                .pulseText(.legend)
        }
        .accessibilityElement(children: .combine)
    }
}

/// "▬ Poor ▬ Sufficient ▬ Optimal": 12 × 3 dashes in orange, grey and teal; labels 12 pt at 70%.
struct PulseLegendPoorSufficientOptimal: View {
    var body: some View {
        HStack(spacing: 14) {
            item(PulseTheme.negative, String(localized: "Poor"))
            item(PulseTheme.sufficient, String(localized: "Sufficient"))
            item(PulseTheme.positive, String(localized: "Optimal"))
        }
        .accessibilityElement(children: .combine)
    }

    private func item(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 12, height: 3)
            Text(title).pulseText(.legend).foregroundStyle(PulseTheme.textSecondary)
        }
    }
}

/// An inset well with a notch pointing up at a value (the HOURS VS. NEEDED need breakdown, §2.6 item 26):
/// `#1C2024`, radius ≈10, inset 16 inside its card; rows on a ≈23 pt pitch.
struct PulseNotchedWell<Content: View>: View {
    /// Where the notch points, as a fraction of the well's width.
    var notchPosition: CGFloat = 0.2
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content()
        }
        .padding(.horizontal, 14)
        .padding(.top, 9 + 10)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PulseNotchedRectangle(cornerRadius: 10, notchWidth: 16, notchHeight: 9, notchPosition: notchPosition)
            .fill(PulseTheme.SleepDetail.needWell))
    }
}

/// One row of a notched well: a 10 pt swatch, a mixed-case label and a value.
struct PulseNotchedWellRow: View {
    let swatch: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .circular).fill(swatch).frame(width: 10, height: 10)
            Text(title).pulseText(.filter).foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            Text(value).font(PulseType.font(.rowValue)).foregroundStyle(PulseTheme.textPrimary)
        }
        .frame(minHeight: 23)
        .accessibilityElement(children: .combine)
    }
}
#endif
