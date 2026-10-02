#if os(iOS)
import SwiftUI

// MARK: - Rows (WHOOP_UI_SPEC §2.6 items 7, 22, 25; §3.1 item 12)

/// A More / settings row: its own rounded card (56 pt, 64 with a sub-line, 10 pt apart), a 28 pt outline
/// icon in grey, an UPPERCASE Bold tracked label, an optional sub-line and a trailing "›", toggle or value.
/// Wrap it in a `PulseLink`, `NavigationLink` or `Button`; the whole card is the hit area.
struct PulseListRow: View {
    enum Trailing {
        case chevron
        case none
        case value(String)
        case toggle(Binding<Bool>)
    }

    var symbol: String?
    let title: String
    var subtitle: String?
    var trailing: Trailing = .chevron
    var titleColor: Color = PulseTheme.textPrimary

    init(symbol: String? = nil, title: String, subtitle: String? = nil, trailing: Trailing = .chevron,
         titleColor: Color = PulseTheme.textPrimary) {
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.titleColor = titleColor
    }

    var body: some View {
        HStack(spacing: 0) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .light))
                    .foregroundStyle(PulseTheme.rowIcon)
                    .frame(width: 28, height: 28)
                    .padding(.trailing, 20)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(titleColor)
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(PulseTheme.rowSubline)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            switch trailing {
            case .chevron:
                PulseChevron(color: PulseTheme.textTertiary, size: 14)
            case .none:
                EmptyView()
            case .value(let text):
                Text(text)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
            case .toggle(let isOn):
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(PulseTheme.positive)
            }
        }
        .padding(.leading, symbol == nil ? 20 : 18)
        .padding(.trailing, 18)
        .frame(maxWidth: .infinity, minHeight: subtitle == nil ? PulseTheme.Row.list : PulseTheme.Row.listWithSubline,
               alignment: .leading)
        .pulseCardBackground(.rowCard)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A My Dashboard metric row (≈58 pt card): a 20 pt line icon at 50% and an UPPERCASE label at the left;
/// the value (22 pt Bold condensed, unit 14 pt tertiary) with its 6 pt trend glyph and the 30-day
/// baseline under it at the right. With no value it shows the label and a "›" only.
struct PulseMetricRow: View {
    let symbol: String
    let title: String
    var value: String?
    var unit: String?
    var trend: PulseTrend?
    var baseline: String?

    init(symbol: String, title: String, value: String? = nil, unit: String? = nil, trend: PulseTrend? = nil,
         baseline: String? = nil) {
        self.symbol = symbol
        self.title = title
        self.value = value
        self.unit = unit
        self.trend = trend
        self.baseline = baseline
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(title)
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 8)
            if let value {
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        PulseValueText(value: value, unit: unit, style: .tileValue, unitStyle: .tileUnit)
                        if let trend {
                            PulseTrendGlyph(trend: trend)
                                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] + 4 }
                        }
                    }
                    if let baseline {
                        Text(baseline)
                            .pulseText(.baseline)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            } else {
                PulseChevron()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.dashboard, alignment: .leading)
        .pulseCardBackground()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        guard let value else { return title }
        var parts = ["\(title), \(value)\(unit.map { " \($0)" } ?? "")"]
        if let trend { parts.append(trend.accessibilityDescription) }
        if let baseline { parts.append(String(localized: "30-day average \(baseline)")) }
        return parts.joined(separator: ", ")
    }
}

/// The coloured chip at the left of a Today's Activities row (≈96 × 40, radius 8), in every state the
/// spec lists.
struct PulseActivityChip: View {
    enum Kind: Equatable {
        /// Sleep or nap: sleep-blue fill, moon (or reclining) glyph, duration "6:41".
        case sleep
        /// A strain activity: strain-blue fill, sport glyph, one-decimal strain.
        case strain
        /// A recovery activity (sauna, meditation): light-blue fill, glyph, duration.
        case recovery
        /// A night that did not score: sleep fill, moon plus a struck bar-chart glyph, no number.
        case unscoredSleep
        /// Just ended, strain still computing: sport glyph plus a small bar-chart glyph.
        case pending
        /// Logged ahead of time: outlined chip (dark fill, thin grey border), glyph plus struck chart.
        case preAdded
    }

    let kind: Kind
    /// The SF Symbol for the activity ("moon.fill", "figure.run", …).
    let symbol: String
    /// The duration or strain; nil for the states that show none.
    var value: String?

    private var fill: Color {
        switch kind {
        case .sleep, .unscoredSleep: return PulseTheme.sleep
        case .strain, .pending: return PulseTheme.strain
        case .recovery: return PulseTheme.recoveryActivityChip
        case .preAdded: return Color.white.opacity(0.04)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
            switch kind {
            case .unscoredSleep, .preAdded:
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 13, weight: .semibold))
                    .overlay(Rectangle().frame(height: 1.5).rotationEffect(.degrees(-40)))
                    .accessibilityLabel(String(localized: "Not scored"))
            case .pending:
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityLabel(String(localized: "Scoring"))
            default:
                if let value {
                    Text(value).font(PulseType.numeral(17))
                }
            }
        }
        .foregroundStyle(Color.white)
        .frame(width: 96, height: 40)
        .background {
            let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
            if kind == .preAdded {
                shape.fill(fill).overlay(shape.strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
            } else {
                shape.fill(fill)
            }
        }
    }
}

/// A Today's Activities row: nested fill (radius 10, ≈56 pt), the chip, the UPPERCASE name (up to two
/// lines), the start and end times stacked at the right (12 pt, 70%), then a 2 × 24 pt bar in the
/// activity colour (white for sleep; dotted for an activity that has not happened yet).
struct PulseActivityRow: View {
    let chip: PulseActivityChip
    let name: String
    /// "[Wed] 11:03 PM": already formatted in the device zone.
    let start: String
    let end: String
    var barColor: Color = PulseTheme.strain
    var dottedBar = false

    var body: some View {
        HStack(spacing: 12) {
            chip
            Text(name)
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 4) {
                Text(start)
                Text(end)
            }
            .font(.system(size: 12, weight: .medium).monospacedDigit())
            .foregroundStyle(PulseTheme.textSecondary)
            .lineLimit(1)
            Group {
                if dottedBar {
                    Path { p in
                        p.move(to: CGPoint(x: 1, y: 0))
                        p.addLine(to: CGPoint(x: 1, y: 24))
                    }
                    .stroke(barColor, style: StrokeStyle(lineWidth: 2, dash: [2, 2]))
                } else {
                    Rectangle().fill(barColor)
                }
            }
            .frame(width: 2, height: 24)
            .accessibilityHidden(true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.activity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular).fill(PulseTheme.nested))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A row card with a subtitle (≈72 pt): a leading icon, a card title with "›", and a 15 pt subtitle
/// (the Behavior Insights compact row).
struct PulseSubtitleRowCard: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(PulseTheme.subtitleRowIcon)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                PulseCardTitle(title, accessory: .chevron)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(PulseTheme.subtitleRowText)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .pulseCardBackground(.solid(PulseTheme.subtitleRowCard))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
#endif
