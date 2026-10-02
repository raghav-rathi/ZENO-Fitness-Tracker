#if os(iOS)
import SwiftUI

// MARK: - Section headers (WHOOP_UI_SPEC §2.6 items 2 and 22, §1.3)

/// A feed section header: 20 pt Semibold Title Case ("My Day", "My Dashboard") at the page margin, with
/// an optional right accessory.
///
///     PulseSectionHeader("My Day", accessory: .plus(String(localized: "Start an activity")) { … })
///     PulseSectionHeader("My Dashboard", accessory: .customize { … })
///     PulseSectionHeader("Achievements", count: 34, style: .pageTitle)
struct PulseSectionHeader: View {
    enum Accessory {
        case none
        /// The white 36 pt "+" square (the app's only "+"), with its accessibility label.
        case plus(String, () -> Void)
        /// "CUSTOMIZE ✎".
        case customize(() -> Void)
        /// "EDIT ✎".
        case edit(() -> Void)
        /// "VIEW ALL →".
        case viewAll(() -> Void)
        /// Plain grey text at the right (a date, "vs 30-day avg").
        case caption(String)
    }

    let title: String
    var count: Int?
    var style: PulseTextStyle = .sectionTitle
    var accessory: Accessory = .none

    init(_ title: String, count: Int? = nil, style: PulseTextStyle = .sectionTitle, accessory: Accessory = .none) {
        self.title = title
        self.count = count
        self.style = style
        self.accessory = accessory
    }

    /// The first Pulse screens' form: a title and an optional grey trailing caption.
    init(title: String, trailing: String? = nil) {
        self.init(title, accessory: trailing.map { .caption($0) } ?? .none)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .pulseText(style)
                    .foregroundStyle(PulseTheme.textPrimary)
                if let count {
                    Text("(\(count))")
                        .pulseText(style)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            accessoryView
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .none:
            EmptyView()
        case .plus(let label, let action):
            PulsePlusButton(accessibilityLabel: label, action: action)
        case .customize(let action):
            PulseTextAccessory(title: String(localized: "Customize"), symbol: "pencil", action: action)
        case .edit(let action):
            PulseTextAccessory(title: String(localized: "Edit"), symbol: "pencil", action: action)
        case .viewAll(let action):
            PulseTextAccessory(title: String(localized: "View all"), symbol: "arrow.right", action: action)
        case .caption(let text):
            Text(text)
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textTertiary)
        }
    }
}

/// "CUSTOMIZE ✎" / "EDIT ✎" / "VIEW ALL →": 11 pt Bold caps plus a 12 pt glyph, white.
struct PulseTextAccessory: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title).pulseText(.label)
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(PulseTheme.textPrimary)
            .frame(minHeight: PulseTheme.Layout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// The white rounded "+" square on the right of "My Day" (§1.3): black glyph, radius 12, 32 pt at the
/// default text size and growing with Dynamic Type, inside a 44 pt hit area.
struct PulsePlusButton: View {
    var accessibilityLabel: String = String(localized: "Add")
    let action: () -> Void
    @ScaledMetric(relativeTo: .title3) private var side: CGFloat = 32

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: side * 0.56, weight: .medium))
                .foregroundStyle(Color.black)
                .frame(width: side, height: side)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular).fill(Color.white))
                .frame(minWidth: PulseTheme.Layout.minTapTarget, minHeight: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// A row-list section header: UPPERCASE 12 pt Bold, light grey, tracked, then a hairline rule to the
/// right edge ("ACCOUNT & SETTINGS", "ADD TO MY DASHBOARD").
struct PulseListSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.listSectionHeader)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
            Rectangle()
                .fill(PulseTheme.divider)
                .frame(height: 1)
                .accessibilityHidden(true)
        }
    }
}
#endif
