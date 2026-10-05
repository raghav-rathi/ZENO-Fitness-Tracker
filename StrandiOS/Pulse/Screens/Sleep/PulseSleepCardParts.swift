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
                            .pulseText(.subtitle)
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
/// Every card prints it at HOURS OF SLEEP's size (§2.2: "8:44" 24 pt, baseline 12): WHOOP's "60%", "100%" and
/// "87%" have the same ≈17 pt caps as its "5:27" (deep-dives-2026/14, 15, 19c), not the spec's 34 pt.
/// `compactBaseline` false sets the baseline at 13 pt instead of 12.
struct SleepFigureView: View {
    let figure: SleepFigure
    var style: PulseTextStyle = .mediumValue
    var glyphSize: CGFloat = 6
    var compactBaseline = true

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
                if compactBaseline {
                    Text(baseline)
                        .pulseText(.secondary)
                        .fontWeight(.bold)
                        .fontWidth(.condensed)
                        .foregroundStyle(PulseTheme.textTertiary)
                } else {
                    Text(baseline)
                        .pulseText(.baseline)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(figure.spoken)
    }
}

/// A Last Night's Sleep detail card: the dimmer detail fill and 16 pt padding, title + ⓘ on top, the content
/// 7 pt under it: title caps to value caps 24 pt, WHOOP's 23–24.4 on deep-dives-2026/03, 15, 19, 19b and 19c.
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
            VStack(alignment: .leading, spacing: 0) {
                SleepCardHeader(title: title, onInfo: onInfo)
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(.top, 7)
            }
        }
    }
}

/// A label + value line inside a card: "ASLEEP … 8:39", "DURATION 8:23".
struct SleepLabelValueRow: View {
    let label: String
    let value: String
    var labelColor: Color = PulseTheme.textSecondary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .pulseText(.label)
                .foregroundStyle(labelColor)
            Spacer(minLength: 8)
            Text(value)
                .sleepRowValue()
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A row figure on the dive's cards (`PulseTheme.SleepDive.rowValueSize`), Bold condensed with tabular digits,
/// following Dynamic Type from the size `.subheadline` starts at, as `.rowValue` follows `.headline`.
struct SleepRowValueText: ViewModifier {
    @ScaledMetric(relativeTo: .subheadline) private var size: CGFloat = PulseTheme.SleepDive.rowValueSize

    func body(content: Content) -> some View {
        content.font(PulseType.numeral(max(11, size)))
    }
}

extension View {
    /// Style a figure in a Sleep dive card's row (`SleepRowValueText`).
    func sleepRowValue() -> some View {
        modifier(SleepRowValueText())
    }
}

/// A small coloured swatch (10–12 pt rounded square).
struct SleepSwatch: View {
    let color: Color
    var size: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: PulseTheme.SleepDive.swatchRadius, style: .circular)
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
        .clipShape(RoundedRectangle(cornerRadius: PulseTheme.SleepDive.swatchRadius, style: .circular))
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

/// The 30-night typical range: a lighter block than the track between the shared box's dashed sides, so
/// the range reads at a glance (deep-dives-2026/12 samples #35393C with a #43474A–#494D50 hatch on the
/// #1E2225 card, the track around it #1D2023).
struct SleepTypicalRangeBox: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PulseTheme.SleepDive.swatchRadius, style: .circular)
                .fill(PulseTheme.SleepDive.typicalBoxFill)
            PulseHatchedTrack(color: PulseTheme.SleepDive.typicalBoxHatch, cornerRadius: PulseTheme.SleepDive.swatchRadius)
            PulseTypicalRangeBox()
        }
        .accessibilityHidden(true)
    }
}

/// The TYPICAL RANGE legend's box: the same block as the rows draw.
struct SleepTypicalLegendBox: View {
    var body: some View {
        SleepTypicalRangeBox()
            .frame(width: 11, height: 12)
            .accessibilityHidden(true)
    }
}

/// A rounded bar on the hatched track, `fraction` of the width (zone, stage and stress-level rows), with
/// the typical-range box laid over bar and track and standing 4 pt proud of them (deep-dives-2026/12). The
/// bar and track keep their own height whatever the box does: the box is an overlay, never part of the
/// layout, so a row is as tall with a box as without one.
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
                    .frame(width: w, height: height)
                RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                    .fill(color)
                    .frame(width: fraction > 0 ? max(4, w * CGFloat(min(1, fraction))) : 0, height: height)
            }
            .frame(width: w, height: height, alignment: .leading)
            .overlay(alignment: .leading) {
                if let typical {
                    SleepTypicalRangeBox()
                        .frame(width: max(6, w * CGFloat(typical.upperBound - typical.lowerBound)), height: height + 8)
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

/// The "no data" body of an empty Last Night's Sleep card: the dash WHOOP prints (deep-dives-2026/01), at a
/// figure's size.
struct SleepEmptyFigure: View {
    let text: String

    var body: some View {
        Text(text)
            .pulseText(.mediumValue)
            .foregroundStyle(PulseTheme.textPrimary)
            .accessibilityLabel(String(localized: "No data"))
    }
}

extension SleepStage {
    /// The stage's Pulse colour (§2.1 "Sleep stages").
    var pulseColor: Color { PulseTheme.Stage.color(self) }
}
#endif
