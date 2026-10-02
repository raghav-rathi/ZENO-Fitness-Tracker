#if os(iOS)
import SwiftUI
import UIKit

// MARK: - Text pieces (WHOOP_UI_SPEC §2.2, §2.6 item 3)

/// A small UPPERCASE tracked label (11 pt Bold, +1.0): dial captions, row labels, status words. One line
/// when it fits, otherwise wrapped between words, never inside one (`PulseWordWrapText`).
struct PulseLabel: View {
    let text: String
    var color: Color = PulseTheme.textTertiary
    var alignment: HorizontalAlignment = .leading

    init(_ text: String, color: Color = PulseTheme.textTertiary, alignment: HorizontalAlignment = .leading) {
        self.text = text
        self.color = color
        self.alignment = alignment
    }

    var body: some View {
        PulseWordWrapText(text, style: .label, alignment: alignment)
            .foregroundStyle(color)
    }
}

// MARK: - No mid-word breaks (DR §2)

/// Text that never breaks inside a word. It sets one line when that fits; otherwise it wraps at spaces
/// only, each word kept whole; a single word wider than the line shrinks rather than splitting. DR §2
/// names WHOOP's "RECOMMEN / DED BEDTIME" as the bug to avoid, and a plain `lineLimit(2)` reproduces it:
/// a long word wraps by character, and because that wrap "fits", `minimumScaleFactor` never kicks in.
///
///     PulseWordWrapText(String(localized: "Recommended bedtime"), style: .label, alignment: .center)
struct PulseWordWrapText: View {
    let text: String
    let style: PulseTextStyle
    var alignment: HorizontalAlignment = .leading
    var lineSpacing: CGFloat = 2
    /// The smallest scale a single over-long word may shrink to.
    var minimumScale: CGFloat = 0.6

    @ScaledMetric private var wordSpace: CGFloat

    init(_ text: String, style: PulseTextStyle, alignment: HorizontalAlignment = .leading,
         lineSpacing: CGFloat = 2, minimumScale: CGFloat = 0.6) {
        self.text = text
        self.style = style
        self.alignment = alignment
        self.lineSpacing = lineSpacing
        self.minimumScale = minimumScale
        let spec = style.spec
        // A space plus the tracking that follows it.
        _wordSpace = ScaledMetric(wrappedValue: spec.size * 0.28 + spec.tracking,
                                  relativeTo: spec.relativeTo ?? .body)
    }

    private var words: [String] {
        text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(text)
                .pulseText(style)
                .lineLimit(1)
                .multilineTextAlignment(textAlignment)
            PulseWordFlow(alignment: alignment, spacing: style.spec.relativeTo == nil
                          ? style.spec.size * 0.28 + style.spec.tracking : wordSpace,
                          lineSpacing: lineSpacing) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .pulseText(style)
                        .lineLimit(1)
                        .minimumScaleFactor(minimumScale)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private var textAlignment: TextAlignment {
        switch alignment {
        case .center: return .center
        case .trailing: return .trailing
        default: return .leading
        }
    }
}

/// Lays words out in lines, breaking only between them.
struct PulseWordFlow: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 4
    var lineSpacing: CGFloat = 2

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(for subviews: Subviews, maxWidth: CGFloat) -> [Line] {
        var out: [Line] = []
        var current = Line()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let added = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if !current.indices.isEmpty && added > maxWidth {
                out.append(current)
                current = Line()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { out.append(current) }
        return out
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = lines(for: subviews, maxWidth: maxWidth)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width.map { min($0, width) } ?? width, height: height)
    }

    /// The first and last lines' baselines, so the words align with neighbouring text like a `Text`.
    func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize,
                           subviews: Subviews, cache: inout ()) -> CGFloat? {
        guard guide == .firstTextBaseline || guide == .lastTextBaseline else { return nil }
        let rows = lines(for: subviews, maxWidth: bounds.width)
        guard !rows.isEmpty else { return nil }
        let rowIndex = guide == .firstTextBaseline ? 0 : rows.count - 1
        var y = bounds.minY
        for row in rows.prefix(rowIndex) { y += row.height + lineSpacing }
        let row = rows[rowIndex]
        guard let first = row.indices.first else { return nil }
        let size = subviews[first].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
        let dimensions = subviews[first].dimensions(in: ProposedViewSize(width: size.width, height: size.height))
        return y + (row.height - size.height) / 2 + dimensions[guide]
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = lines(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x: CGFloat
            switch alignment {
            case .center: x = bounds.minX + (bounds.width - row.width) / 2
            case .trailing: x = bounds.maxX - row.width
            default: x = bounds.minX
            }
            for index in row.indices {
                let size = subviews[index].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      proposal: ProposedViewSize(width: size.width, height: size.height))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }
}

// MARK: - Measuring text

/// The width a string takes in a Pulse style, measured with the same SF Pro the style renders, so a row
/// can pick ONE size for several labels (the Home dials share a single label size).
enum PulseTextMetrics {
    static func width(_ text: String, style: PulseTextStyle, size: CGFloat? = nil) -> CGFloat {
        let spec = style.spec
        let pointSize = size ?? spec.size
        let weight = uiWeight(spec.weight)
        let font = spec.condensed
            ? UIFont.systemFont(ofSize: pointSize, weight: weight, width: .condensed)
            : UIFont.systemFont(ofSize: pointSize, weight: weight)
        let string = spec.uppercase ? text.uppercased() : text
        let kern = spec.tracking * pointSize / spec.size
        return ceil((string as NSString).size(withAttributes: [.font: font, .kern: kern]).width)
    }

    private static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}

/// The "›" after a tappable title: 13 pt, white 50% (§2.6 item 3).
struct PulseChevron: View {
    var color: Color = PulseTheme.textTertiary
    var size: CGFloat = 13

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

/// A number with its unit set smaller and baseline-aligned ("80%", "51 ms").
///
///     PulseValueText(value: "80", unit: "%", style: .dialValue, unitStyle: .dialUnit)
struct PulseValueText: View {
    let value: String
    var unit: String?
    var style: PulseTextStyle = .rowValue
    var unitStyle: PulseTextStyle = .tileUnit
    var color: Color = PulseTheme.textPrimary
    /// The unit's colour (text units are tertiary; a dial's "%" stays primary).
    var unitColor: Color = PulseTheme.textTertiary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(value)
                .pulseText(style)
                .foregroundStyle(color)
                .pulseNumericTransition()
            if let unit, !unit.isEmpty {
                Text(unit)
                    .pulseText(unitStyle)
                    .foregroundStyle(unitColor)
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}

/// A card's title row: UPPERCASE 12 pt Bold tracked, an inline "›" when the card opens something, and
/// an optional icon at the top-right (⤢ expand, ⓘ info).
///
///     PulseCardTitle("Today's Activities", accessory: .expand)
struct PulseCardTitle: View {
    enum Accessory: Equatable {
        case none
        /// "›" inline after the title: the whole card opens a screen.
        case chevron
        /// ⤢ at the right: opens an expanded view.
        case expand
        /// ⓘ at the right: opens an explainer.
        case info
        /// "›" at the right, as WHOOP lays it out at large text sizes.
        case trailingChevron
    }

    let title: String
    var accessory: Accessory = .none
    var color: Color = PulseTheme.textPrimary
    @Environment(\.dynamicTypeSize) private var typeSize

    init(_ title: String, accessory: Accessory = .none, color: Color = PulseTheme.textPrimary) {
        self.title = title
        self.accessory = accessory
        self.color = color
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            PulseWordWrapText(title, style: .cardTitle)
                .foregroundStyle(color)
                .accessibilityAddTraits(.isHeader)
            if accessory == .chevron && !typeSize.isAccessibilitySize {
                PulseChevron()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, accessoryReserve)
        // The accessory never sets the row's height: it is centred on the title and may overflow it, so
        // the title's caps sit 19 pt from the card's top edge whatever sits at the right.
        .overlay(alignment: .trailing) { accessoryView.fixedSize() }
    }

    /// Room kept at the right for the accessory, so the title never runs under it.
    private var accessoryReserve: CGFloat {
        switch accessory {
        case .none: return 0
        case .chevron: return typeSize.isAccessibilitySize ? 14 : 0
        case .trailingChevron: return 14
        default: return 22
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .expand:
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PulseTheme.textTertiary)
                .accessibilityHidden(true)
        case .info:
            Image(systemName: "info.circle")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .accessibilityHidden(true)
        case .trailingChevron:
            PulseChevron()
        case .chevron:
            if typeSize.isAccessibilitySize { PulseChevron() }
        case .none:
            EmptyView()
        }
    }
}
#endif
