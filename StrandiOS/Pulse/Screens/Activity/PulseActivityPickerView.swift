#if os(iOS)
import SwiftUI

/// SELECT ACTIVITY (WHOOP_UI_SPEC §3.9): the add flow's pushed list. A search field, the ALL · STRAIN ·
/// RECOVERY · SLEEP tabs, MOST RECENT and ALL A-Z, each activity a rounded dark card.
///
/// Inside Add Activity it hands the pick back (`onPick`). Opened on its own (the `.activityPicker` route),
/// a pick opens the Add Activity form for that activity in the same stack.
struct PulseActivityPickerView: View {
    /// The list stands on its own and replaces no classic screen.
    static let isRebuilt = true

    /// The current choice, highlighted.
    var selected: String?
    var onPick: ((PulseActivityKind) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var pickedRoute: PulseActivityFormRoute?

    init(selected: String? = nil, onPick: ((PulseActivityKind) -> Void)? = nil) {
        self.selected = selected
        self.onPick = onPick
    }

    var body: some View {
        PulseActivityPickerList(style: .cards, tabs: PulseActivityPickerList.Tab.allCases, selected: selected,
                                searchPlaceholder: String(localized: "Search")) { kind in
            if let onPick {
                onPick(kind)
                dismiss()
            } else {
                pickedRoute = PulseActivityFormRoute(sport: kind.name)
            }
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .background(LinearGradient(gradient: PulseTheme.Activity.selectSheet, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea())
        .pulseNavHeader(String(localized: "Select Activity"))
        .environment(\.pulseModalRoot, false)
        .navigationDestination(item: $pickedRoute) { route in
            route.view
        }
    }
}

/// The Add Activity form for a picked activity, pushed when the list is opened on its own.
struct PulseActivityFormRoute: PulseScreenRoute, Identifiable {
    let sport: String
    var id: String { sport }

    var view: some View {
        PulseActivityForm(mode: .add(preset: PulseActivityCatalog.kind(named: sport)), onDone: { _ in })
            .environment(\.pulseModalRoot, false)
    }
}

// MARK: - The list

/// Every activity list in Pulse (§3.8 picker, §3.9 SELECT ACTIVITY / SELECT YOUR ACTIVITY): search, the
/// category tabs, MOST RECENT (the last five picked) and ALL A-Z. `.borderless` rows are the pre-start
/// dropdown's (white glyph and caps name on a 62 pt pitch, completeness-critic/05; the current one on a
/// white-8% card); `.cards` rows are the add and edit flows' rounded dark cards.
struct PulseActivityPickerList: View {
    enum Style { case borderless, cards }

    enum Tab: Hashable, CaseIterable {
        case all, strain, recovery, sleep

        var title: String {
            switch self {
            case .all: return String(localized: "All")
            case .strain: return String(localized: "Strain")
            case .recovery: return String(localized: "Recovery")
            case .sleep: return String(localized: "Sleep")
            }
        }
    }

    let style: Style
    let tabs: [Tab]
    var selected: String?
    var searchPlaceholder: String = String(localized: "Search")
    /// A line under the tabs (the reclassify sheet's note on an auto-detected activity).
    var note: String?
    let onPick: (PulseActivityKind) -> Void

    @State private var query = ""
    @State private var tab: Tab = .all
    @FocusState private var searchFocused: Bool

    private var catalogue: [PulseActivityKind] {
        tabs.contains(.sleep) ? PulseActivityCatalog.all + PulseActivityCatalog.sleepKinds : PulseActivityCatalog.all
    }

    private func inTab(_ kind: PulseActivityKind) -> Bool {
        switch tab {
        case .all: return true
        case .strain: return kind.category == .strain
        case .recovery: return kind.category == .recovery
        case .sleep: return kind.category == .sleep
        }
    }

    private var recent: [PulseActivityKind] {
        PulseActivityCatalog.recent().filter { kind in inTab(kind) && (tabs.contains(.sleep) || kind.category != .sleep) }
    }

    private var alphabetical: [PulseActivityKind] {
        let base = catalogue.filter(inTab)
        // The sleep entries lead the SLEEP tab and close the full list.
        return tab == .sleep ? base : base.filter { $0.category != .sleep } + base.filter { $0.category == .sleep }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.top, 8)
            tabBar
                .padding(.top, 14)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: style == .cards ? 8 : 0) {
                    if let note {
                        Text(note)
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 12)
                    }
                    let trimmed = query.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let hits = PulseActivityCatalog.search(trimmed, in: catalogue.filter(inTab))
                        if hits.isEmpty {
                            Text(String(localized: "No activities match \u{201C}\(trimmed)\u{201D}."))
                                .pulseText(.body)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .padding(.top, 24)
                        }
                        ForEach(hits) { row($0) }
                    } else {
                        if !recent.isEmpty {
                            sectionHeader(String(localized: "Most recent"))
                            ForEach(recent) { row($0) }
                        }
                        sectionHeader(String(localized: "All A-Z"))
                        ForEach(alphabetical) { row($0) }
                    }
                }
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        #if DEBUG
        .onAppear { PulseActivityDebug.applyRecentsIfRequested() }
        #endif
    }

    // MARK: Pieces

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: PulseActivityStyle.Glyph.search, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
            TextField("", text: $query, prompt: Text(searchPlaceholder).foregroundColor(PulseTheme.textTertiary))
                .activityText(.searchField)
                .foregroundStyle(PulseTheme.textPrimary)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: PulseActivityStyle.Glyph.search))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Clear search"))
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
            .fill(style == .cards ? PulseTheme.Activity.searchField : PulseTheme.card))
        .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
            .strokeBorder(searchFocused && style == .cards ? PulseTheme.Activity.searchFocusBorder : .clear,
                          lineWidth: 1))
    }

    /// The underlined tabs. Four (ALL · STRAIN · RECOVERY · SLEEP) take four equal columns with their labels
    /// centred (completeness-critic/05); three (the reclassify sheet's ALL · STRAIN · RECOVERY) sit at the
    /// left with fixed gaps (c03). The underline is the label's width.
    @ViewBuilder
    private var tabBar: some View {
        if tabs.count > 3 {
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { t in
                    tabButton(t)
                        .frame(maxWidth: .infinity)
                }
            }
        } else {
            HStack(spacing: 32) {
                ForEach(tabs, id: \.self) { t in
                    tabButton(t)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func tabButton(_ t: Tab) -> some View {
        Button { tab = t } label: {
            VStack(spacing: 7) {
                Text(t.title)
                    .pulseText(.label)
                    .foregroundStyle(tab == t ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Rectangle()
                    .fill(tab == t ? PulseTheme.textPrimary : Color.clear)
                    .frame(height: 2)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(minHeight: PulseTheme.Layout.minTapTarget, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityAddTraits(tab == t ? .isSelected : [])
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize()
            Rectangle().fill(PulseTheme.divider).frame(height: 1)
        }
        .padding(.top, 18)
        .padding(.bottom, style == .cards ? 6 : 4)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func row(_ kind: PulseActivityKind) -> some View {
        let isSelected = kind.name.caseInsensitiveCompare(selected ?? "") == .orderedSame
        Button { onPick(kind) } label: {
            HStack(spacing: 18) {
                Image(systemName: kind.symbol)
                    .font(.system(size: PulseActivityStyle.Glyph.row, weight: .regular))
                    .foregroundStyle(style == .cards ? PulseTheme.textSecondary : PulseTheme.textPrimary)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                Text(kind.displayName)
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
            }
            .padding(.horizontal, style == .cards ? 16 : 14)
            .frame(maxWidth: .infinity, minHeight: style == .cards ? 56 : 62, alignment: .leading)
            .background {
                if style == .cards {
                    RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                        .fill(PulseTheme.Activity.selectRowCard)
                } else if isSelected {
                    RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                        .fill(PulseActivityStyle.selectedRow)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(kind.category == .recovery ? String(localized: "Recovery activity") : "")
    }
}
#endif
