#if os(iOS)
import SwiftUI

// MARK: - Section headers (WHOOP_UI_SPEC §2.6 items 2 and 22, §1.3)

/// A feed section header: 20 pt Semibold Title Case ("My Day", "My Dashboard") with an optional right
/// accessory. Title and accessory sit 20 pt from the screen edges (4 pt inside the page margin), as WHOOP
/// insets them (reviews/r41, completeness-critic/25: "My Day" ink at x = 21.7, "+" 20 pt from the edge).
///
/// The header HUGS its title: the accessory is centred on the title and its 44 pt hit area overflows the
/// row rather than growing it, so `Layout.sectionGap` above and `Layout.headerGap` below give the same
/// 40 / 24 pt rhythm (DR §3) with or without an accessory.
///
///     PulseSectionHeader("My Day", accessory: .actionMenu)
///     PulseSectionHeader("My Dashboard", accessory: .customize { … })
///     PulseSectionHeader("Achievements", count: 34, style: .pageTitle)
struct PulseSectionHeader: View {
    enum Accessory {
        case none
        /// The white 36 pt "+" square (the app's only "+"), with its accessibility label.
        case plus(String, () -> Void)
        /// The "+" that opens the action menu anchored to it (§1.3): My Day, Get Started.
        case actionMenu
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
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .pulseText(style)
                .foregroundStyle(PulseTheme.textPrimary)
            if let count {
                Text("(\(count))")
                    .pulseText(style)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            Spacer(minLength: 8 + accessoryReserve)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .overlay(alignment: .trailing) { accessoryView }
        .padding(.horizontal, 4)
    }

    /// Room kept at the right so a long title never runs under the accessory.
    private var accessoryReserve: CGFloat {
        switch accessory {
        case .none: return 0
        case .plus, .actionMenu: return 36
        case .caption: return 60
        default: return 90
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
        case .none:
            EmptyView()
        case .plus(let label, let action):
            PulsePlusButton(accessibilityLabel: label, action: action)
        case .actionMenu:
            PulseActionMenuButton()
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

/// The white rounded "+" square on the right of "My Day" (§1.3): black glyph, radius 12, 36 pt at the
/// default text size (reviews/r41, completeness-critic/25: 36.0 × 36.0) and growing with Dynamic Type. Its
/// 44 pt hit area overflows the square without adding layout height.
struct PulsePlusButton: View {
    var accessibilityLabel: String = String(localized: "Add")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PulsePlusSquare()
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// The "+" square itself, or the "✕" on a dark square it morphs into while the action menu is open.
struct PulsePlusSquare: View {
    var isClose = false
    @ScaledMetric(relativeTo: .title3) private var side: CGFloat = 36

    var body: some View {
        Image(systemName: isClose ? "xmark" : "plus")
            .font(.system(size: side * (isClose ? 0.42 : 0.5), weight: .medium))
            .foregroundStyle(isClose ? Color.white : Color.black)
            .frame(width: side, height: side)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(isClose ? PulseTheme.menuCloseSquare : Color.white))
            .padding(max(0, (PulseTheme.Layout.minTapTarget - side) / 2))
            .contentShape(Rectangle())
            .padding(-max(0, (PulseTheme.Layout.minTapTarget - side) / 2))
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
            // Never wider than the row: past one line it wraps between words (a fixed-size title pushed
            // the whole page sideways at accessibility sizes).
            PulseWordWrapText(title, style: .cardTitle)
                .foregroundStyle(PulseTheme.listSectionHeader)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
            Rectangle()
                .fill(PulseTheme.divider)
                .frame(minWidth: 16, maxWidth: .infinity)
                .frame(height: 1)
                .accessibilityHidden(true)
        }
    }
}
#endif
