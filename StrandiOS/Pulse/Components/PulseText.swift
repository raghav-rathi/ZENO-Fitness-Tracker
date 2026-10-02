#if os(iOS)
import SwiftUI

// MARK: - Text pieces (WHOOP_UI_SPEC §2.2, §2.6 item 3)

/// A small UPPERCASE tracked label (11 pt Bold, +1.0): dial captions, row labels, status words.
struct PulseLabel: View {
    let text: String
    var color: Color = PulseTheme.textTertiary
    @Environment(\.dynamicTypeSize) private var typeSize

    init(_ text: String, color: Color = PulseTheme.textTertiary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .pulseText(.label)
            .foregroundStyle(color)
            // One line, shrinking a little if it must; at accessibility sizes it wraps rather than
            // truncating mid-word ("RESPIRAT…").
            .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.85)
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
            Text(title)
                .pulseText(.cardTitle)
                .foregroundStyle(color)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)
            if accessory == .chevron && !typeSize.isAccessibilitySize {
                PulseChevron()
            }
            Spacer(minLength: 8)
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
}
#endif
