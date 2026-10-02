#if os(iOS)
import SwiftUI

// MARK: - Segmented control, ranges and pagers (WHOOP_UI_SPEC §2.6 items 14 and 15, §1.4, §1.7)

/// The Trend View ranges: W / M / 6M / 1Y / ALL.
enum PulseRange: String, CaseIterable, Identifiable, Hashable {
    case week, month, sixMonths, year, all

    var id: String { rawValue }

    /// The segment's label.
    var title: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        case .all: return String(localized: "All")
        }
    }

    /// Calendar days covered, or nil for everything.
    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 182
        case .year: return 365
        case .all: return nil
        }
    }
}

/// A segmented control: a black-50% well (radius 10, 36 pt) whose selected segment is white 10%
/// (radius 8), UPPERCASE 12 pt Bold labels, white when selected and 50% otherwise. The `.underline`
/// style is the "STATUS | ADVANCED" variant.
///
///     PulseSegmentedControl(options: PulseRange.allCases, selection: $range) { $0.title }
struct PulseSegmentedControl<Value: Hashable>: View {
    enum Style { case well, underline }

    let options: [Value]
    @Binding var selection: Value
    var style: Style = .well
    let title: (Value) -> String

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(options: [Value], selection: Binding<Value>, style: Style = .well, title: @escaping (Value) -> String) {
        self.options = options
        _selection = selection
        self.style = style
        self.title = title
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .pulseText(.cardTitle)
                        .foregroundStyle(selected ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.segmented - 6)
                        .background { indicator(selected) }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(style == .well ? 3 : 0)
        .frame(minHeight: PulseTheme.Row.segmented)
        .background {
            if style == .well {
                RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular).fill(PulseTheme.well)
            } else {
                VStack {
                    Spacer()
                    Rectangle().fill(PulseTheme.divider).frame(height: 1)
                }
            }
        }
        .animation(PulseMotion.resolved(PulseMotion.menu, reduceMotion: reduceMotion), value: selection)
    }

    @ViewBuilder
    private func indicator(_ selected: Bool) -> some View {
        if selected {
            switch style {
            case .well:
                RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    .fill(PulseTheme.nested)
                    .matchedGeometryEffect(id: "selection", in: namespace)
            case .underline:
                VStack {
                    Spacer()
                    Rectangle().fill(PulseTheme.textPrimary).frame(height: 2)
                }
                .matchedGeometryEffect(id: "selection", in: namespace)
            }
        }
    }
}

/// The date pager: an outer white-5% capsule with "‹", an inner pill another 10% lighter holding the label
/// ("TODAY", "WED, MAY 27"; 11 pt Bold caps), and "›" (white 40% and disabled on today), 30 pt tall
/// (reviews/r41: outer ≈137 × 30, inner ≈81 × 30, ≈14.5% in all). Tapping the label opens the calendar
/// sheet. The Stress Monitor and Healthspan reuse it.
struct PulseDayPager: View {
    let title: String
    var canGoBack: Bool = true
    var canGoForward: Bool = false
    let onBack: () -> Void
    let onForward: () -> Void
    var onTitleTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            chevron("chevron.left", enabled: canGoBack, label: String(localized: "Previous"), action: onBack)
            Button {
                onTitleTap?()
            } label: {
                Text(title)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .frame(minWidth: 81, minHeight: 30)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                        .fill(PulseTheme.pagerPill))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(onTitleTap == nil)
            .accessibilityLabel(title)
            .accessibilityHint(onTitleTap == nil ? "" : String(localized: "Opens a calendar"))
            chevron("chevron.right", enabled: canGoForward, label: String(localized: "Next"), action: onForward)
        }
        .frame(height: 30)
        .background(Capsule(style: .circular).fill(PulseTheme.pagerCapsule))
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func chevron(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: 28, height: 30)
                .contentShape(Rectangle().inset(by: -7))
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// A range pager: "‹ MAY 9 - MAY 15, 26 ›" in 12 pt Bold caps, white "‹", "›" white 40% when disabled.
struct PulseRangePager: View {
    let title: String
    var canGoBack: Bool = true
    var canGoForward: Bool = false
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            pagerButton("chevron.left", enabled: canGoBack, label: String(localized: "Previous"), action: onBack)
            Text(title)
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
            pagerButton("chevron.right", enabled: canGoForward, label: String(localized: "Next"), action: onForward)
        }
    }

    private func pagerButton(_ symbol: String, enabled: Bool, label: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
#endif
