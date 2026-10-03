#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - More and settings pieces (group "more-profile"; WHOOP_UI_SPEC §2.6 item 22, §3.31–3.33)
//
// The More tab and the settings pages are lists of `PulseListRow` cards under `PulseListSectionHeader`s.
// These add what those lists need around the rows: a section with the spec's rhythm, a row's grey helper
// text, a toggle row that carries a sub-line, the FIRST WEEK card, the version line and a page heading.

/// A More / settings section: the UPPERCASE header, then its rows 10 pt apart.
struct MoreSection<Rows: View>: View {
    let title: String?
    @ViewBuilder var rows: () -> Rows

    init(_ title: String?, @ViewBuilder rows: @escaping () -> Rows) {
        self.title = title
        self.rows = rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MoreLayout.headerToRows) {
            if let title {
                MoreSectionHeader(title)
            }
            VStack(spacing: PulseTheme.Row.listGap) {
                rows()
            }
        }
    }
}

/// Spacing the More and settings lists share, measured at 3x on help-center/94 (2025 list, full
/// resolution) and reviews/r05 (2026): 56 pt row cards 10 pt apart, 20 pt from the screen edges, the
/// label's caps 8.7 pt tall from x = 83, the icon's 24 pt box from x = 36, a section's caps 42 pt under
/// the card above and 18 pt over the card below.
enum MoreLayout {
    /// The More root's side inset: its cards sit 20 pt from the screen edges (2025 list and the 2026
    /// FIRST WEEK card alike); the settings pages keep the 16 pt page margin.
    static let moreMargin: CGFloat = 20
    /// From a section header's text frame to its first row: 18 pt from the caps to the card.
    static let headerToRows: CGFloat = 14
    /// Between the last row of one section and the next header's text frame: 42 pt to the caps.
    static let sectionGap: CGFloat = 38
    /// A row card's leading inset to its icon's box, the box, and the label's start (63 pt in).
    static let iconInset: CGFloat = 16
    static let iconBox: CGFloat = 24
    static let labelInset: CGFloat = 63
    /// Grey helper text under a settings row card, inset from its edge.
    static let helpInset: CGFloat = 18

    // Radii the group's pages measure that the foundation's scale does not name.
    /// The Profile, Day Streak and Achievement Details cards (spec §3.30 "radius 16", `#1E2326`).
    static let profileCardRadius: CGFloat = 16
    /// The unlock modal's and the birthday sheet's CLOSE / VIEW / CONFIRM buttons (spec §3.30 "radius 14").
    static let modalButtonRadius: CGFloat = 14
    /// The phone drawn on the disconnected STATUS picture (onboarding/43a).
    static let phoneArtRadius: CGFloat = 26
    /// ZENO's tile on the Apple Health connection graphic.
    static let healthTileRadius: CGFloat = 15
    /// Device Settings' row cards: nearly square (help-center/97 measures a 9 px corner at 3x, onboarding/43a
    /// about 2.7 pt), and 20 pt from the screen edges.
    static let deviceRowRadius: CGFloat = PulseTheme.Radius.badge
    static let deviceMargin: CGFloat = 20
}

/// The UPPERCASE Bold tracked type of a More row's label and a More section header: caps 8.7 pt tall
/// (12.3 pt SF Pro), tracked so "DEVICE SETTINGS" spans WHOOP's 126 pt. Scales with Dynamic Type.
struct MoreLabelText: ViewModifier {
    /// Tracking at the base size: 0.95 for a row label; a section header runs wider (1.4, so "ACCOUNT &
    /// SETTINGS" spans WHOOP's 165 pt).
    var tracking: CGFloat = 0.95
    @ScaledMetric(relativeTo: .footnote) private var size: CGFloat = 12.3

    func body(content: Content) -> some View {
        content
            .font(.system(size: max(11, size), weight: .bold))
            .tracking(tracking * size / 12.3)
            .textCase(.uppercase)
    }
}

/// A More / settings section header: the row label's type in light grey, no rule (help-center/94 and
/// reviews/r05 draw none under ACCOUNT & SETTINGS, SUPPORT, REFER & EARN or SHOP & GIFT).
struct MoreSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .modifier(MoreLabelText(tracking: 1.4))
            .foregroundStyle(PulseTheme.listSectionHeader)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A More / settings row: its own rounded card (56 pt, 64 with a sub-line), a 24 pt outline icon in grey,
/// the UPPERCASE label, an optional sub-line, and at the right nothing (WHOOP's list rows carry no "›"),
/// a value, a toggle or a tag. Wrap it in a link or button; the whole card is the hit area.
///
/// The label wraps between words only and a word too wide for the card shrinks instead of breaking
/// ("INTEGRATION / S" at the accessibility sizes); the row stops growing at `.accessibility2` (DR §2).
struct MoreListRow: View {
    enum Trailing {
        case none
        case chevron
        case value(String)
        case toggle(Binding<Bool>)
        case tag(String)
        case check(Bool)
    }

    var symbol: String?
    let title: String
    var subtitle: String?
    var trailing: Trailing = .none
    var titleColor: Color = PulseTheme.textPrimary
    var cornerRadius: CGFloat = PulseTheme.Radius.card

    init(symbol: String? = nil, title: String, subtitle: String? = nil, trailing: Trailing = .none,
         titleColor: Color = PulseTheme.textPrimary, cornerRadius: CGFloat = PulseTheme.Radius.card) {
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.titleColor = titleColor
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        HStack(spacing: 0) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 22.5, weight: .light))
                    .foregroundStyle(PulseTheme.rowIcon)
                    .frame(width: MoreLayout.iconBox, height: MoreLayout.iconBox)
                    .padding(.leading, MoreLayout.iconInset)
                    .padding(.trailing, MoreLayout.labelInset - MoreLayout.iconInset - MoreLayout.iconBox)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                MoreWordWrapLabel(title)
                    .foregroundStyle(titleColor)
                if let subtitle {
                    Text(subtitle)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.rowSubline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, symbol == nil ? 20 : 0)
            .padding(.vertical, 10)
            Spacer(minLength: 8)
            trailingView
        }
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, minHeight: subtitle == nil ? PulseTheme.Row.list : PulseTheme.Row.listWithSubline,
               alignment: .leading)
        .pulseCardBackground(.rowCard, radius: cornerRadius)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .none:
            EmptyView()
        case .chevron:
            PulseChevron(color: PulseTheme.textTertiary, size: 14)
        case .value(let text):
            Text(text)
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textSecondary)
                .multilineTextAlignment(.trailing)
        case .toggle(let isOn):
            Toggle(title, isOn: isOn)
                .toggleStyle(MoreSwitchStyle())
        case .tag(let text):
            PulseTag(text)
        case .check(let done):
            // A status mark: a teal ✓ in its tint once done, an empty ring before.
            Group {
                if done {
                    PulseStatusBadge(.check, tint: .teal)
                } else {
                    Circle().strokeBorder(PulseTheme.textDisabled, lineWidth: 1.5).frame(width: 22, height: 22)
                }
            }
            .accessibilityLabel(done ? String(localized: "Done") : String(localized: "Not done yet"))
        }
    }
}

/// A list row whose card is a `Button`, with the press style.
struct MoreButtonRow: View {
    let symbol: String?
    let title: String
    var subtitle: String?
    var trailing: MoreListRow.Trailing = .none
    var titleColor: Color = PulseTheme.textPrimary
    var cornerRadius: CGFloat = PulseTheme.Radius.card
    let action: () -> Void

    init(symbol: String?, title: String, subtitle: String? = nil, trailing: MoreListRow.Trailing = .none,
         titleColor: Color = PulseTheme.textPrimary, cornerRadius: CGFloat = PulseTheme.Radius.card,
         action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.titleColor = titleColor
        self.cornerRadius = cornerRadius
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            MoreListRow(symbol: symbol, title: title, subtitle: subtitle, trailing: trailing, titleColor: titleColor,
                        cornerRadius: cornerRadius)
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// A route row: a `PulseLink` around the row.
struct MoreLinkRow: View {
    let route: PulseRoute
    let symbol: String?
    let title: String
    var subtitle: String?
    var trailing: MoreListRow.Trailing = .none
    var cornerRadius: CGFloat = PulseTheme.Radius.card

    init(_ route: PulseRoute, symbol: String?, title: String, subtitle: String? = nil,
         trailing: MoreListRow.Trailing = .none, cornerRadius: CGFloat = PulseTheme.Radius.card) {
        self.route = route
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        PulseLink(route) {
            MoreListRow(symbol: symbol, title: title, subtitle: subtitle, trailing: trailing,
                        cornerRadius: cornerRadius)
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// A settings switch as WHOOP's 2026 settings pages draw it (AI SETTINGS, profile-community-2026/55): no
/// card, the UPPERCASE label at the left and the switch at the right, the grey 15 pt helper text under
/// them, and a dashed rule closing the item.
struct MoreToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    var help: String?
    var separator = true

    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>, help: String? = nil, separator: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        _isOn = isOn
        self.help = help
        self.separator = separator
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    MoreWordWrapLabel(title)
                        .foregroundStyle(PulseTheme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .pulseText(.rowSubline)
                            .foregroundStyle(PulseTheme.rowSubline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                Toggle(title, isOn: $isOn)
                    .toggleStyle(MoreSwitchStyle())
            }
            .frame(minHeight: PulseTheme.Layout.minTapTarget)
            if let help {
                Text(help)
                    .pulseText(.rowSubline)
                    .lineSpacing(2)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .accessibilityHidden(true)
            }
            if separator {
                MoreDashedRule()
                    .padding(.top, 14)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint(help ?? "")
    }
}

/// The dashed hairline that closes a settings item (white 25%, 4 on 3).
struct MoreDashedRule: View {
    var body: some View {
        Line()
            .stroke(PulseTheme.dash, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}

/// Grey helper text under a settings row (13 pt, 70%), inset to the row's text.
struct MoreHelpText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .pulseText(.rowSubline)
            .lineSpacing(2)
            .foregroundStyle(PulseTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, MoreLayout.helpInset)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A page's sentence-case heading and its grey paragraph (Export, AI Settings, Integrations).
struct MorePageIntro: View {
    let title: String?
    let text: String

    init(title: String? = nil, text: String) {
        self.title = title
        self.text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .pulseText(.cardHeadline)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(text)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// "LEARN MORE →" as a link's label: UPPERCASE 11 pt Bold tracked plus an arrow, white, 44 pt tall
/// (the look of `PulseTextCTA`, for a `PulseLink` that is itself the button).
struct MoreArrowLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title).pulseText(.label)
            Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(PulseTheme.textPrimary)
        .frame(minHeight: PulseTheme.Layout.minTapTarget, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// The black "FIRST WEEK WITH ZENO" card with the Get Started gradient border (reviews/r05): a
/// graduation cap, the caps title and a two-line sentence. New members only (the first seven days).
struct MoreFirstWeekCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: "graduationcap")
                    .font(.system(size: 21, weight: .light))
                    .foregroundStyle(PulseTheme.rowIcon)
                    .frame(width: MoreLayout.iconBox)
                    .padding(.trailing, MoreLayout.labelInset - MoreLayout.iconInset - MoreLayout.iconBox)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "First week with ZENO"))
                        .modifier(MoreLabelText())
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "Wear your strap to bed every night, then check back here to see your sleep and what it means."))
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.rowSubline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, MoreLayout.iconInset)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                shape.fill(PulseTheme.bannerWell)
                    .overlay(shape.strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.getStartedBorder,
                                                               startPoint: .leading, endPoint: .trailing),
                                                lineWidth: 1.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// "ZENO 11.8.0 (428)" in small grey caps, where WHOOP prints its app version under LOGOUT.
struct MoreVersionLine: View {
    var body: some View {
        Text(Self.text)
            .pulseText(.label)
            .foregroundStyle(PulseTheme.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(String(localized: "Version \(Self.version), build \(Self.build)"))
    }

    static var name: String {
        (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? "ZENO"
    }

    static var version: String { UpdateWatch.installedVersion }

    static var build: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
    }

    static var text: String {
        build.isEmpty ? "\(name) \(version)" : "\(name) \(version) (\(build))"
    }
}
#endif
