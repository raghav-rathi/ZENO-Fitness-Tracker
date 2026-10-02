#if os(iOS)
import SwiftUI

// MARK: - Status badges, pills and chips (WHOOP_UI_SPEC §2.1 "Status tints", §2.6 items 4, 12, 13, 23, 35)

/// The 24 pt status square of a monitor tile: a tinted fill holding ✓, "!", "–" or a short value.
///
///     PulseStatusBadge(.check, tint: .teal)
///     PulseStatusBadge(.value("1.5"), tint: PulseTheme.Stress.Level(value: 1.5).tint)
struct PulseStatusBadge: View {
    enum Content: Equatable {
        case check
        case alert
        case pending
        case value(String)
    }

    let content: Content
    let tint: PulseTheme.Tint
    var size: CGFloat = 24

    init(_ content: Content, tint: PulseTheme.Tint, size: CGFloat = 24) {
        self.content = content
        self.tint = tint
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                .fill(tint.fill)
            Group {
                switch content {
                case .check:
                    Image(systemName: "checkmark").font(.system(size: size * 0.5, weight: .bold))
                case .alert:
                    Text(verbatim: "!").font(.system(size: size * 0.6, weight: .heavy))
                case .pending:
                    Text(verbatim: "–").font(.system(size: size * 0.6, weight: .bold))
                case .value(let text):
                    Text(text).font(PulseType.numeral(13)).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            .foregroundStyle(tint.glyph)
            .padding(.horizontal, 2)
        }
        .frame(minWidth: size)
        .frame(height: size)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityHidden(true)
    }
}

/// A status pill: teal "✓ Optimal", orange "! Out of Range", grey "• Sufficient" (radius 6, 11 pt Semibold).
struct PulseStatusChip: View {
    enum Kind: Equatable {
        case positive, negative, neutral
    }

    let text: String
    let kind: Kind

    init(_ text: String, kind: Kind) {
        self.text = text
        self.kind = kind
    }

    private var glyph: String {
        switch kind {
        case .positive: return "✓"
        case .negative: return "!"
        case .neutral: return "•"
        }
    }

    private var colors: (text: Color, fill: Color) {
        switch kind {
        case .positive: return (PulseTheme.positive, PulseTheme.positive.opacity(0.16))
        case .negative: return (PulseTheme.negative, PulseTheme.Tint.orange.fill)
        case .neutral: return (PulseTheme.textSecondary, PulseTheme.Tint.grey.fill)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: glyph).pulseText(.chipStrong)
            Text(text).pulseText(.chip)
        }
        .foregroundStyle(colors.text)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular).fill(colors.fill))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// A small UPPERCASE tag ("BETA", "NEW"): radius 8, a white-12% fill or a 1 pt recovery-blue outline.
struct PulseTag: View {
    let text: String
    var outlined = false

    init(_ text: String, outlined: Bool = false) {
        self.text = text
        self.outlined = outlined
    }

    var body: some View {
        Text(text)
            .pulseText(.label)
            .foregroundStyle(outlined ? PulseTheme.recoveryBlue : PulseTheme.textPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                if outlined {
                    shape.strokeBorder(PulseTheme.recoveryBlue, lineWidth: 1)
                } else {
                    shape.fill(PulseTheme.tagFill)
                }
            }
    }
}

/// The Poor / Sufficient / Optimal mini bar: three 20 × 4 segments, 2 pt apart; only the active one is
/// coloured (orange, grey, teal), the others white 12%.
struct PulseMiniSegments: View {
    /// 0 = Poor, 1 = Sufficient, 2 = Optimal; nil lights none.
    let active: Int?

    static let colors: [Color] = [PulseTheme.negative, PulseTheme.sufficient, PulseTheme.positive]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1, style: .circular)
                    .fill(i == active ? Self.colors[i] : PulseTheme.segmentOff)
                    .frame(width: 20, height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        switch active {
        case 0: return String(localized: "Poor")
        case 1: return String(localized: "Sufficient")
        case 2: return String(localized: "Optimal")
        default: return String(localized: "Not rated")
        }
    }
}

/// The deep dives' achievement chip: a 30 pt capsule holding a pillar's mini badge and a count
/// (§1.5, §2.6 item 23). ZENO draws the badge with SF Symbols (no WHOOP badge art).
struct PulseAchievementChip: View {
    /// The badge glyph: "hexagon.fill" (sleep), "shield.fill" (recovery), "diamond.fill" (strain).
    let symbol: String
    let tint: Color
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18, height: 18)
            Text(verbatim: "\(count)")
                .font(PulseType.numeral(15, hero: true))
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Capsule(style: .circular).fill(PulseTheme.achievementChip))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(count) achievements"))
    }
}

/// A filter chip (Achievements, Exercise Details, My Memory): white with black text when selected,
/// slate with white text otherwise (h 34, radius 12).
struct PulseFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .pulseText(.filter)
                .foregroundStyle(isSelected ? Color.black : PulseTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .frame(minHeight: 34)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                    .fill(isSelected ? Color.white : PulseTheme.filterChip))
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
