#if os(iOS)
import SwiftUI

/// SELECT BEHAVIORS (WHOOP_UI_SPEC §3.17b): a full-height sheet with a grabber over the Journal.
///
/// "✕ SELECT BEHAVIORS", the search field ("Search for Behaviors": names, then synonyms, then near
/// misses), the category tabs (ALL · CUSTOM BEHAVIORS · WHOOP's nine categories), then CURRENTLY
/// SELECTED and NOT SELECTED, each alphabetical: a name over its journal question, an outlined "Custom"
/// chip on custom rows and a 24 pt checkbox at the right. Ticks are staged; SAVE BEHAVIORS applies them to
/// the journal catalog (`JournalCatalogStore`): a starter or imported question is hidden or restored, a
/// library behaviour is added or removed, and a custom one is created on the CUSTOM BEHAVIORS tab with no
/// AI needed (§3.17 ZENO data). Rows stay in their section until saved, so nothing jumps under a finger.
struct PulseSelectBehaviorsView: View {
    @ObservedObject var catalog: JournalCatalogStore
    let importedQuestions: [String]
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.pulseCoach) private var coach
    @State private var local = PulseJournalLocalStore.shared

    private enum Tab: Hashable {
        case all, custom
        case category(PulseBehaviorCategory)
    }

    @State private var tab: Tab = .all
    @State private var query = ""
    /// The staged selection, by behaviour identity.
    @State private var selection: Set<String> = []
    /// The selection as the sheet opened (which rows sit under CURRENTLY SELECTED).
    @State private var initial: Set<String> = []
    @State private var didLoad = false
    @State private var creating = false

    private var tabs: [Tab] { [.all, .custom] + PulseBehaviorCategory.allCases.map { .category($0) } }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchField
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
                .padding(.top, 4)
            tabBar
                .padding(.top, 14)
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if tab == .custom {
                            JournalAIEntryCard(title: String(localized: "Create Custom Behaviors"),
                                               showsTalk: coach.availability != .off,
                                               onText: { creating = true },
                                               onTalk: {
                                                   coach.open(String(localized: "Help me design a custom journal behavior to track: a short name, an optional unit and a yes-or-no daily question."))
                                               })
                            .padding(.top, 16)
                        }
                        let selected = rows.filter { initial.contains(identity($0)) }
                        let notSelected = rows.filter { !initial.contains(identity($0)) }
                        if !selected.isEmpty {
                            JournalSectionLabel(title: String(localized: "Currently selected"))
                                .padding(.top, 20)
                            ForEach(selected) { row($0) }
                        }
                        if !notSelected.isEmpty {
                            JournalSectionLabel(title: String(localized: "Not selected"))
                                .padding(.top, 20)
                            ForEach(notSelected) { row($0) }
                        }
                        if selected.isEmpty && notSelected.isEmpty {
                            Text(query.isEmpty ? String(localized: "No custom behaviors yet. Create one above.")
                                               : String(localized: "No behaviors match “\(query)”."))
                                .pulseText(.body)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.bottom, PulseTheme.JournalPlan.saveHeight + 56)
                }
                .scrollDismissesKeyboard(.interactively)
                saveButton
            }
        }
        .background(LinearGradient(colors: [PulseTheme.JournalPlan.selectSheetTop, PulseTheme.JournalPlan.selectSheetBottom],
                                   startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(PulseTheme.Radius.menu)
        .environment(\.colorScheme, .dark)
        .onAppear(perform: loadSelection)
        .sheet(isPresented: $creating) {
            PulseCreateBehaviorSheet { created in
                creating = false
                guard let created else { return }
                catalog.addCustom(created.question, kind: created.unit.map { .numeric(unitLabel: $0) } ?? .bool,
                                  group: created.category.group)
                local.setTitle(created.name, for: created.question)
                let id = PulseBehaviorLibrary.identity(for: created.question)
                selection.insert(id)
                initial.insert(id)
                tab = .custom
            }
        }
    }

    // MARK: Header, search, tabs

    private var header: some View {
        ZStack {
            Text(String(localized: "Select Behaviors"))
                .pulseText(.menuLabel)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack {
                PulseCloseButton { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.top, 14)
        .frame(minHeight: 56)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(PulseTheme.JournalPlan.rowGlyph)
                .foregroundStyle(PulseTheme.textSecondary)
                .accessibilityHidden(true)
            TextField(String(localized: "Search for Behaviors"), text: $query)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Clear search"))
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: PulseTheme.Layout.minTapTarget)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
            .fill(PulseTheme.JournalPlan.searchField))
    }

    private var tabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 26) {
                    ForEach(tabs, id: \.self) { t in
                        let selected = t == tab
                        Button { tab = t } label: {
                            VStack(spacing: 7) {
                                Text(title(t))
                                    .pulseText(.label)
                                    .foregroundStyle(selected ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                                    .lineLimit(1)
                                Rectangle()
                                    .fill(selected ? Color.white : Color.clear)
                                    .frame(height: 2)
                                    .frame(maxWidth: 28)
                            }
                            .frame(minHeight: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .accessibilityAddTraits(selected ? .isSelected : [])
                        .id(t)
                    }
                }
                .padding(.horizontal, 22)
            }
            .onChange(of: tab) { _, t in withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(t, anchor: .center) } }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func title(_ t: Tab) -> String {
        switch t {
        case .all: return String(localized: "All")
        case .custom: return String(localized: "Custom Behaviors")
        case .category(let c): return c.title
        }
    }

    // MARK: Rows

    /// Every behaviour the editor offers, one per identity (a shown spelling first), plus the mood check-in.
    private var everything: [PulseBehavior] {
        let items = catalog.resolvedItems(imported: importedQuestions, includeHidden: true)
        var seen = Set<String>()
        var out: [PulseBehavior] = []
        let resolved = PulseBehaviorLibrary.all(items: items, customTitles: local.customTitles)
        // Shown spellings first, so a hidden duplicate never stands in for a selected behaviour.
        for b in resolved.filter(\.isSelected) + resolved.filter({ !$0.isSelected }) {
            if seen.insert(identity(b)).inserted { out.append(b) }
        }
        out.append(PulseBehavior(canonical: PulseBehaviorLibrary.moodID, title: String(localized: "Mood"),
                                 question: String(localized: "How was your mood?"), category: .mentalWellbeing,
                                 section: .daytime, symbol: "face.smiling", followUp: nil, libraryID: nil,
                                 isCustom: false, isSelected: local.moodIsSelected))
        return out
    }

    private var rows: [PulseBehavior] {
        let filtered = everything.filter { b in
            switch tab {
            case .all: return true
            case .custom: return b.isCustom
            case .category(let c): return b.category == c
            }
        }
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        return PulseBehaviorLibrary.search(query, in: filtered)
    }

    private func identity(_ b: PulseBehavior) -> String {
        b.canonical == PulseBehaviorLibrary.moodID ? b.canonical : PulseBehaviorLibrary.identity(for: b.canonical)
    }

    private func row(_ b: PulseBehavior) -> some View {
        let id = identity(b)
        let checked = selection.contains(id)
        return Button {
            if checked { selection.remove(id) } else { selection.insert(id) }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(b.title)
                        .pulseText(.filter)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(b.question)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if b.isCustom { JournalCustomChip() }
                JournalCheckbox(checked: checked)
            }
            .padding(.vertical, 9)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(checked ? .isSelected : [])
        .accessibilityHint(checked ? String(localized: "Removes it from your journal when you save")
                                   : String(localized: "Adds it to your journal when you save"))
    }

    // MARK: Save

    private var saveButton: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [PulseTheme.JournalPlan.selectSheetBottom.opacity(0), PulseTheme.JournalPlan.selectSheetBottom],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 28)
                .allowsHitTesting(false)
            Button(action: save) {
                Text(String(localized: "Save Behaviors"))
                    .pulseText(.capsuleLabel)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, minHeight: PulseTheme.JournalPlan.saveHeight)
                    .background(Capsule(style: .continuous).fill(PulseTheme.JournalPlan.saveCapsule))
                    .contentShape(Capsule())
            }
            .buttonStyle(PulsePressStyle())
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.bottom, 8)
            .background(PulseTheme.JournalPlan.selectSheetBottom)
        }
    }

    private func loadSelection() {
        guard !didLoad else { return }
        didLoad = true
        let selected = Set(everything.filter(\.isSelected).map(identity))
        selection = selected
        initial = selected
        #if DEBUG
        if let t = JournalPlanDebug.selectTab {
            tab = t == "custom" ? .custom : (PulseBehaviorCategory(rawValue: t).map { .category($0) } ?? .all)
        }
        if let q = JournalPlanDebug.selectQuery { query = q }
        #endif
    }

    /// Apply the staged ticks to the catalog.
    private func save() {
        let all = catalog.resolvedItems(imported: importedQuestions, includeHidden: true)
        for b in everything {
            let id = identity(b)
            let want = selection.contains(id)
            guard want != b.isSelected else { continue }
            if b.canonical == PulseBehaviorLibrary.moodID {
                local.moodIsSelected = want
                continue
            }
            let spellings = all.filter { PulseBehaviorLibrary.identity(for: $0.canonical) == id }
            if want {
                if let hidden = spellings.first(where: \.hidden) {
                    catalog.restore(hidden.canonical)
                } else if spellings.isEmpty, let libraryID = b.libraryID,
                          let def = PulseBehaviorLibrary.definition(id: libraryID) {
                    catalog.addCustom(def.canonical, kind: .bool, group: def.category.group)
                }
            } else {
                for item in spellings where !item.hidden { catalog.remove(item.canonical) }
            }
        }
        onSaved()
        dismiss()
    }
}

// MARK: - Create a custom behaviour

/// The CUSTOM BEHAVIORS form: a name, the daily question, a category and, optionally, an amount to track.
struct PulseCreateBehaviorSheet: View {
    struct Created {
        let name: String
        let question: String
        let category: PulseBehaviorCategory
        let unit: String?
    }

    let onDone: (Created?) -> Void

    @State private var name = ""
    @State private var question = ""
    @State private var category: PulseBehaviorCategory = .lifestyle
    @State private var tracksAmount = false
    @State private var unit = ""
    @FocusState private var focused: Field?

    private enum Field { case name, question, unit }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !question.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    field(String(localized: "Name"), text: $name, prompt: String(localized: "Protein Shake"), focus: .name)
                    field(String(localized: "Daily question"), text: $question,
                          prompt: String(localized: "Had a protein shake?"), focus: .question)
                    VStack(alignment: .leading, spacing: 8) {
                        JournalSectionLabel(title: String(localized: "Category"), rule: false)
                        Picker(String(localized: "Category"), selection: $category) {
                            ForEach(PulseBehaviorCategory.allCases) { c in Text(c.title).tag(c) }
                        }
                        .pickerStyle(.menu)
                        .tint(PulseTheme.textPrimary)
                    }
                    Toggle(isOn: $tracksAmount) {
                        Text(String(localized: "Ask how much"))
                            .pulseText(.rowText)
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                    .tint(PulseTheme.JournalPlan.switchOn)
                    if tracksAmount {
                        field(String(localized: "Unit"), text: $unit, prompt: String(localized: "grams"), focus: .unit)
                    }
                    Text(String(localized: "It joins your journal under its section, and Behavior Insights measures it once you have logged it yes and no at least 5 times each."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(PulseTheme.Layout.pageMargin)
            }
            .background(PulseTheme.JournalPlan.selectSheetBottom.ignoresSafeArea())
            .navigationTitle(String(localized: "Create Behavior"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { onDone(nil) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Add")) {
                        var q = question.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !q.hasSuffix("?") { q += "?" }
                        let u = unit.trimmingCharacters(in: .whitespaces)
                        onDone(Created(name: name.trimmingCharacters(in: .whitespacesAndNewlines), question: q,
                                       category: category, unit: tracksAmount ? (u.isEmpty ? nil : u) : nil))
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { focused = .name }
        }
        .tint(PulseTheme.textPrimary)
        .environment(\.colorScheme, .dark)
        .presentationDetents([.large])
    }

    private func field(_ label: String, text: Binding<String>, prompt: String, focus: Field) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            JournalSectionLabel(title: label, rule: false)
            TextField(prompt, text: text)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .focused($focused, equals: focus)
                .padding(.horizontal, 14)
                .frame(minHeight: PulseTheme.Layout.minTapTarget)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                    .fill(PulseTheme.JournalPlan.searchField))
        }
    }
}
#endif
