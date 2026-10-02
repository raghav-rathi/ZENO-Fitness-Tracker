#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Pieces the Sleep dive's cards share (WHOOP_UI_SPEC §3.3 items 5–7)

/// A Last Night's Sleep card's title row: the UPPERCASE title and, at the right, the ⓘ that opens its
/// explainer (the glyph sits in a 44 pt target that overflows the row, so it never sets the row's height).
struct SleepCardHeader: View {
    let title: String
    var onInfo: (() -> Void)?

    var body: some View {
        PulseCardTitle(title)
            .padding(.trailing, onInfo == nil ? 0 : 26)
            .overlay(alignment: .trailing) {
                if let onInfo {
                    Button(action: onInfo) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(PulseTheme.textTertiary)
                            .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .padding(.trailing, -14)
                    .accessibilityLabel(String(localized: "About \(title)"))
                }
            }
    }
}

/// A figure with its trend glyph beside it and the prior-30-night baseline under it ("60% ▼" over "73%").
struct SleepFigureView: View {
    let figure: SleepFigure
    var style: PulseTextStyle = .largeValue
    var glyphSize: CGFloat = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .center, spacing: 7) {
                Text(figure.value + (figure.unit ?? ""))
                    .pulseText(style)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .pulseNumericTransition()
                if let trend = figure.trend {
                    PulseTrendGlyph(trend: trend, size: glyphSize)
                }
            }
            if let baseline = figure.baseline {
                Text(baseline)
                    .pulseText(.baseline)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(figure.spoken)
    }
}

/// A Last Night's Sleep detail card: the dimmer detail fill and 16 pt padding, title + ⓘ on top.
struct SleepDetailCard<Content: View>: View {
    let title: String
    var onInfo: (() -> Void)?
    @ViewBuilder var content: () -> Content

    init(_ title: String, onInfo: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.onInfo = onInfo
        self.content = content
    }

    var body: some View {
        PulseCard(.detail) {
            VStack(alignment: .leading, spacing: 14) {
                SleepCardHeader(title: title, onInfo: onInfo)
                content()
            }
        }
    }
}

/// A label + value line inside a card: "ASLEEP … 8:39", "DURATION 8:23".
struct SleepLabelValueRow: View {
    let label: String
    let value: String
    var labelColor: Color = PulseTheme.textSecondary
    var valueStyle: PulseTextStyle = .rowValue

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .pulseText(.label)
                .foregroundStyle(labelColor)
            Spacer(minLength: 8)
            Text(value)
                .pulseText(valueStyle)
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A small coloured swatch (10–12 pt rounded square).
struct SleepSwatch: View {
    let color: Color
    var size: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .circular)
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The RESTORATIVE swatch: a square split on its diagonal, pink top-left and purple bottom-right
/// (deep-dives-2026/02, 15).
struct SleepRestorativeSwatch: View {
    var size: CGFloat = 12

    var body: some View {
        ZStack {
            PulseTheme.Stage.restorativePurple
            SleepDiagonalHalf().fill(PulseTheme.Stage.restorativePink)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .circular))
        .accessibilityHidden(true)
    }
}

/// The top-left triangle of a square.
struct SleepDiagonalHalf: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The TYPICAL RANGE legend's box: dashed sides around a faint hatch.
struct SleepTypicalLegendBox: View {
    var body: some View {
        PulseTypicalRangeBox()
            .frame(width: 11, height: 12)
            .accessibilityHidden(true)
    }
}

/// A rounded bar on the hatched track, `fraction` of the width (zone, stage and stress-level rows).
struct SleepShareBar: View {
    let fraction: Double
    let color: Color
    var typical: ClosedRange<Double>?
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                PulseHatchedTrack()
                RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                    .fill(color)
                    .frame(width: fraction > 0 ? max(4, w * CGFloat(min(1, fraction))) : 0)
                if let typical {
                    PulseTypicalRangeBox()
                        .frame(width: max(4, w * CGFloat(typical.upperBound - typical.lowerBound)))
                        .offset(x: w * CGFloat(typical.lowerBound))
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// When a stage happened across the night: its runs on the hatched track (the selected-stage barcode).
struct SleepBarcode: View {
    let segments: [ClosedRange<Double>]
    let color: Color
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                PulseHatchedTrack()
                ForEach(Array(segments.enumerated()), id: \.offset) { _, run in
                    Rectangle()
                        .fill(color)
                        .frame(width: max(1.5, w * CGFloat(run.upperBound - run.lowerBound)))
                        .offset(x: w * CGFloat(run.lowerBound))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular))
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// The "no data" body of an empty Last Night's Sleep card: the dash WHOOP prints (deep-dives-2026/01).
struct SleepEmptyFigure: View {
    let text: String

    var body: some View {
        Text(text)
            .pulseText(.largeValue)
            .foregroundStyle(PulseTheme.textPrimary)
            .accessibilityLabel(String(localized: "No data"))
    }
}

extension SleepStage {
    /// The stage's Pulse colour (§2.1 "Sleep stages").
    var pulseColor: Color { PulseTheme.Stage.color(self) }
}
#endif
