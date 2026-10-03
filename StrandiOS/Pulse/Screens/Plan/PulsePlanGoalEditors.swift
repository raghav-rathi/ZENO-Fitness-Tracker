#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Goal editors (WHOOP_UI_SPEC §3.19 "BEHAVIOR GOAL editor", "Other goal editors")
//
// WHOOP's 2026 editors other than BEHAVIOR GOAL were not seen [U]; ZENO uses the same card for every goal:
// a days-per-week row of 1–7 buttons for a count goal and a slider for a threshold or a weekly total. ZENO
// lifts WHOOP's limits users dislike [Z]: zone 4-5 time is not capped at 30 minutes, and Day Strain goals
// need not count all seven days.

/// One goal's controls: its caps name (with a checkbox to drop it, when removable), its days per week, its
/// threshold or weekly total.
struct PlanGoalEditorCard: View {
    @Binding var goal: PulsePlanGoal
    var behaviorTitle: String?
    var onRemove: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                if let onRemove {
                    Button(action: onRemove) { JournalCheckbox(checked: true) }
                        .buttonStyle(PulsePressStyle())
                        .accessibilityLabel(String(localized: "Remove \(goal.title(behaviorTitle: behaviorTitle))"))
                }
                Text(goal.title(behaviorTitle: behaviorTitle))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            if let range = PlanGoalRanges.range(goal.kind) {
                valueSlider(range)
            }
            if goal.isCount {
                daysRow
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.JournalPlan.editorSelectedCard))
    }

    /// "Days per week · 3 DAYS" over the 1–7 square buttons (selected blue with dark text).
    private var daysRow: some View {
        let days = goal.days ?? 3
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Days per week"))
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer()
                Text(days == 1 ? String(localized: "1 day") : String(localized: "\(days) days"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.JournalPlan.dayButtonSelected)
            }
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { n in
                    let selected = n == days
                    Button { goal.days = n } label: {
                        Text(verbatim: "\(n)")
                            .pulseText(.rowValue)
                            .foregroundStyle(selected ? PulseTheme.JournalPlan.checkboxGlyph : PulseTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: PulseTheme.JournalPlan.dayButtonSize)
                            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                                .fill(selected ? PulseTheme.JournalPlan.dayButtonSelected : PulseTheme.JournalPlan.dayButton))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(n == 1 ? String(localized: "1 day a week") : String(localized: "\(n) days a week"))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            // Seven buttons share the width: their numbers stop growing where they still fit.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }

    private func valueSlider(_ r: PlanGoalRanges.Range) -> some View {
        let value = goal.value ?? r.defaultValue
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(r.label)
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer()
                Text(r.format(value))
                    .pulseText(.rowValue)
                    .foregroundStyle(PulseTheme.JournalPlan.dayButtonSelected)
            }
            Slider(value: Binding(get: { value }, set: { goal.value = ($0 / r.step).rounded() * r.step }),
                   in: r.bounds, step: r.step)
                .tint(PulseTheme.JournalPlan.dayButtonSelected)
                .accessibilityLabel(r.label)
                .accessibilityValue(r.format(value))
        }
    }
}

/// The adjustable range of each goal's threshold or weekly total.
enum PlanGoalRanges {
    struct Range {
        let label: String
        let bounds: ClosedRange<Double>
        let step: Double
        let defaultValue: Double
        let format: (Double) -> String
    }

    static func range(_ kind: PulsePlanGoal.Kind) -> Range? {
        switch kind {
        case .sleepPerformance:
            return Range(label: String(localized: "Average Sleep Performance"), bounds: 60...100, step: 5, defaultValue: 85,
                         format: { "\(Int($0))%+" })
        case .sleepConsistency:
            return Range(label: String(localized: "Average Sleep Consistency"), bounds: 50...100, step: 5, defaultValue: 80,
                         format: { "\(Int($0))%+" })
        case .dayStrain:
            return Range(label: String(localized: "Day Strain"), bounds: 4...20, step: 0.5, defaultValue: 14,
                         format: { "\(PulseFormat.oneDecimal($0))+" })
        case .steps:
            return Range(label: String(localized: "Steps"), bounds: 2000...20000, step: 500, defaultValue: 7000,
                         format: { "\(PulseFormat.grouped($0))+" })
        case .hrZones45:
            return Range(label: String(localized: "Minutes in zones 4-5 a week"), bounds: 10...300, step: 5, defaultValue: 30,
                         format: { "\(PulseFormat.hoursMinutes($0))+" })
        case .hrZones13:
            return Range(label: String(localized: "Minutes in zones 1-3 a week"), bounds: 30...900, step: 15, defaultValue: 180,
                         format: { "\(PulseFormat.hoursMinutes($0))+" })
        case .strengthTime:
            return Range(label: String(localized: "Strength minutes a week"), bounds: 30...600, step: 15, defaultValue: 90,
                         format: { "\(PulseFormat.hoursMinutes($0))+" })
        case .anyActivity, .strengthActivity, .recoveryActivity, .sport, .behavior:
            return nil
        }
    }
}

// MARK: - A section's goals

/// The editor a Plan Overview section's EDIT ✎ opens (or "Add a goal"): its goals' cards, SAVE GOALS.
struct PulsePlanGoalEditor: View {
    let title: String
    let goals: [PulsePlanGoal]
    var adding = false

    @Environment(\.dismiss) private var dismiss
    @State private var plans = PulsePlanStore.shared
    @State private var edited: [PulsePlanGoal] = []
    @State private var removed = Set<String>()
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            PulseScreenScaffold(title: title) {
                if adding {
                    PlanGoalPicker(goals: $edited, existing: Set(plans.plan?.goals.map(\.kind) ?? []),
                                   showsBehaviorNote: false)
                } else {
                    ForEach($edited) { $goal in
                        if !removed.contains(goal.id) {
                            PlanGoalEditorCard(goal: $goal, onRemove: { removed.insert(goal.id) })
                        }
                    }
                    if edited.allSatisfy({ removed.contains($0.id) }) {
                        Text(String(localized: "Nothing left in this section. Save to remove it from your plan."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                }
                Button(String(localized: "Save goals"), action: save)
                    .buttonStyle(.pulseFilledWhite)
                    .padding(.top, 8)
            }
            .environment(\.pulseModalRoot, true)
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            edited = adding ? [] : goals
        }
    }

    private func save() {
        guard let plan = plans.plan else { dismiss(); return }
        let kept = edited.filter { !removed.contains($0.id) }
        if adding {
            // New kinds only: a plan holds one goal of each kind (behaviours have their own editor).
            let present = Set(plan.goals.map(\.kind))
            plans.setGoals(plan.goals + kept.filter { !present.contains($0.kind) })
        } else {
            let ids = Set(goals.map(\.id))
            var out: [PulsePlanGoal] = []
            for g in plan.goals {
                if ids.contains(g.id) {
                    if let updated = kept.first(where: { $0.id == g.id }) { out.append(updated) }
                } else {
                    out.append(g)
                }
            }
            plans.setGoals(out)
        }
        dismiss()
    }
}

// MARK: - BEHAVIOR GOAL (journal-plan-2026/30)

/// BEHAVIOR GOAL, pushed from Plan Overview's BEHAVIORS › EDIT ("‹", §1.6).
struct PlanBehaviorGoalRoute: PulseScreenRoute {
    var view: some View { PulseBehaviorGoalEditor() }
}

/// BEHAVIOR GOAL: the chosen behaviours, each a card with a checkbox, its caps name and "Days per week" over
/// 1–7 buttons; then up to four suggestions (a caps name with ⓘ, its question, the wearer's OWN impact when
/// Behavior Insights measured one, and a switch; WHOOP's "Members Like You" chip is population data
/// [POP]), "+ ADD BEHAVIORS" for any other behaviour, and, pinned under a fade, the note that new
/// behaviours join the Journal, SAVE BEHAVIORS and REMOVE. Custom behaviours can be goals too [Z].
struct PulseBehaviorGoalEditor: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var plans = PulsePlanStore.shared
    @State private var local = PulseJournalLocalStore.shared
    @StateObject private var catalog = JournalCatalogStore()
    @State private var chosen: [PulsePlanGoal] = []
    @State private var didLoad = false
    @State private var impacts: [String: (impact: Double, significant: Bool)] = [:]
    @State private var imported: [String] = []
    @State private var showSelector = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach($chosen) { $goal in
                    PlanGoalEditorCard(goal: $goal, behaviorTitle: title(goal.subject),
                                       onRemove: { chosen.removeAll { $0.id == goal.id } })
                }
                ForEach(suggestions, id: \.canonical) { b in suggestionCard(b) }
                addBehaviorsRow
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        // Pinned under the page, which scrolls beneath its fade and stops above its buttons.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            JournalPinnedBar(color: PulseTheme.JournalPlan.editorPage) {
                VStack(spacing: 4) {
                    Text(String(localized: "New behaviors will also be added to your Journal for daily tracking."))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 16)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    Button(action: save) {
                        JournalSaveCapsuleLabel(title: String(localized: "Save Behaviors"))
                    }
                    .buttonStyle(PulsePressStyle())
                    Button {
                        chosen = []
                        save()
                    } label: {
                        Text(String(localized: "Remove"))
                            .pulseText(.buttonLabel)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityHint(String(localized: "Removes every behavior goal from the plan"))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
        }
        .background(PulseTheme.JournalPlan.editorPage.ignoresSafeArea())
        .pulseNavHeader(String(localized: "Behavior Goal"))
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: $showSelector) {
            PulseSelectBehaviorsView(catalog: catalog, importedQuestions: imported,
                                     goalPicker: .init(selected: goalIdentities, onSave: applyPicked))
        }
        .task { await load() }
    }

    private var addBehaviorsRow: some View {
        Button { showSelector = true } label: {
            HStack(spacing: 18) {
                Image(systemName: "plus")
                    .font(PulseTheme.JournalPlan.rowGlyph)
                    .foregroundStyle(PulseTheme.textSecondary)
                Text(String(localized: "Add behaviors"))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.JournalPlan.editorSuggestionCard))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Choose any behavior as a goal"))
    }

    private var goalIdentities: Set<String> {
        Set(chosen.compactMap { $0.subject.map(PulseBehaviorLibrary.identity(for:)) })
    }

    /// Up to four behaviours worth a goal: the wearer's own measured links first (the largest first), then
    /// the journal's behaviours, then the library's; + ADD BEHAVIORS reaches the rest.
    private var suggestions: [PulseBehavior] {
        var seen = goalIdentities
        var offered: [PulseBehavior] = []
        for item in catalog.resolvedItems(imported: imported) {
            let b = PulseBehaviorLibrary.behavior(for: item, customTitles: local.customTitles)
            if seen.insert(PulseBehaviorLibrary.identity(for: b.canonical)).inserted { offered.append(b) }
        }
        for def in PulseBehaviorLibrary.definitions where def.goalTitle != nil {
            if seen.insert(PulseBehaviorLibrary.identity(for: def.canonical)).inserted {
                offered.append(PulseBehaviorLibrary.suggestion(def))
            }
        }
        func measured(_ b: PulseBehavior) -> Double? {
            guard let m = impacts[PulseBehaviorLibrary.identity(for: b.canonical)], m.significant else { return nil }
            return abs(m.impact)
        }
        let linked = offered.filter { measured($0) != nil }.sorted { (measured($0) ?? 0) > (measured($1) ?? 0) }
        let rest = offered.filter { measured($0) == nil }
        return Array((linked + rest).prefix(PulseTheme.JournalPlan.goalSuggestionLimit))
    }

    private func suggestionCard(_ b: PulseBehavior) -> some View {
        let id = PulseBehaviorLibrary.identity(for: b.canonical)
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(b.title)
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    PulseLink(PulseBehaviorDetailsRoute(identity: id).route) {
                        Image(systemName: "info.circle")
                            .font(PulseTheme.JournalPlan.checkGlyph)
                            .foregroundStyle(PulseTheme.recoveryBlue)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "About \(b.title)"))
                }
                Text(b.question)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let measured = impacts[id], measured.significant {
                    let up = measured.impact >= 0
                    HStack(spacing: 4) {
                        Image(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(PulseTheme.JournalPlan.smallGlyph)
                        Text(BehaviorImpactFormat.text(measured.impact)).pulseText(.chipStrong)
                    }
                    .foregroundStyle(up ? PulseTheme.Delta.favourableText : PulseTheme.Delta.unfavourableText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                        .fill(up ? PulseTheme.Delta.favourableFill : PulseTheme.Delta.unfavourableFill))
                    .accessibilityLabel(String(localized: "Your Recovery impact \(BehaviorImpactFormat.text(measured.impact))"))
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(get: { false }, set: { on in
                guard on else { return }
                chosen.append(goal(for: b))
            }))
            .labelsHidden()
            .tint(PulseTheme.JournalPlan.switchOn)
            .accessibilityLabel(String(localized: "Add \(b.title) as a goal"))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.JournalPlan.editorSuggestionCard))
    }

    /// A new goal for a behaviour: 3 days a week, AVOID when the library says the behaviour is one to avoid.
    private func goal(for b: PulseBehavior) -> PulsePlanGoal {
        let def = b.libraryID.flatMap(PulseBehaviorLibrary.definition(id:))
        return PulsePlanGoal(kind: .behavior, days: 3, subject: b.canonical, avoid: def?.avoid ?? false)
    }

    /// + ADD BEHAVIORS saved: the ticked behaviours are the goals now (kept goals keep their days).
    private func applyPicked(_ picked: [PulseBehavior]) {
        let ids = picked.map { PulseBehaviorLibrary.identity(for: $0.canonical) }
        var next = chosen.filter { g in g.subject.map { ids.contains(PulseBehaviorLibrary.identity(for: $0)) } ?? false }
        let kept = Set(next.compactMap { $0.subject.map(PulseBehaviorLibrary.identity(for:)) })
        for (b, id) in zip(picked, ids) where !kept.contains(id) {
            next.append(goal(for: b))
        }
        chosen = next
    }

    private func title(_ subject: String?) -> String? {
        guard let subject else { return nil }
        let id = PulseBehaviorLibrary.identity(for: subject)
        let items = catalog.resolvedItems(imported: imported, includeHidden: true)
        return items.first { PulseBehaviorLibrary.identity(for: $0.canonical) == id }
            .map { PulseBehaviorLibrary.behavior(for: $0, customTitles: local.customTitles).title }
    }

    private func save() {
        PlanJournalSync.ensureInJournal(chosen, catalog: catalog)
        if let plan = plans.plan {
            plans.setGoals(plan.goals.filter { $0.kind != .behavior } + chosen)
        }
        dismiss()
    }

    private func load() async {
        if !didLoad {
            didLoad = true
            chosen = plans.plan?.behaviorGoals ?? []
        }
        if let s = await model.build(dayOffset: 0, { builder, r in
            builder.begin(r.seq)        // the questions' cache belongs to this refresh
            let questions = await builder.importedJournalQuestions()
            return await builder.behaviorInsights(r).map { ($0, questions) }
        }) {
            imported = s.1
            var map: [String: (impact: Double, significant: Bool)] = [:]
            for row in s.0.unlocked { if let impact = row.impact { map[row.id] = (impact, row.significant) } }
            impacts = map
        }
    }
}
#endif
