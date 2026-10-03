#if os(iOS)
import SwiftUI

/// EDIT PLAN (WHOOP_UI_SPEC §3.19, reviews/r11): "Edit your Weekly Plan", the CURRENT PLAN, CHOOSE A PLAN's
/// three templates (Boost Fitness orange, Feel Better green, Sleep Deeper blue-grey), CUSTOM, and END PLAN
/// while one runs. A template or Custom opens its goals, adjustable before START PLAN. As a sheet it shows
/// "✕"; pushed (no plan yet) "‹".
struct PulseEditPlanView: View {
    @State private var plans = PulsePlanStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pulseModalRoot) private var isModalRoot
    @State private var confirmEnd = false
    @State private var startedRevision: Int?

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Edit Plan")) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Edit your Weekly Plan"))
                    .pulseText(.pageTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(String(localized: "Choose from the plans below or create your own. A plan sets weekly goals for your sleep, strain, activities and behaviors, and ZENO tracks them from your data."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let plan = plans.plan {
                PulseListSectionHeader(String(localized: "Current plan"))
                    .padding(.top, 8)
                currentPlan(plan)
            }
            PulseListSectionHeader(String(localized: "Choose a plan"))
                .padding(.top, 8)
            ForEach([PulsePlan.Template.boostFitness, .feelBetter, .sleepDeeper]) { template in
                PulseLink(PlanPreviewRoute(template: template).route) { templateCard(template) }
                    .buttonStyle(PulsePressStyle())
            }
            PulseListSectionHeader(String(localized: "Custom"))
                .padding(.top, 8)
            PulseLink(PlanPreviewRoute(template: .custom).route) { templateCard(.custom) }
                .buttonStyle(PulsePressStyle())
            if plans.plan != nil {
                Button { confirmEnd = true } label: {
                    Text(String(localized: "End plan"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(PulseTheme.recoveryLowText)
                        .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .padding(.top, 8)
            }
        }
        .overlay {
            if confirmEnd {
                PulseDialogCard(title: String(localized: "End your plan?"),
                                message: String(localized: "Your goals stop counting from today. Your journal, activities and data stay as they are."),
                                primaryTitle: String(localized: "End plan"),
                                primary: {
                                    confirmEnd = false
                                    plans.end()
                                    PulsePlanReminders.sync(active: false)
                                    if isModalRoot { dismiss() }
                                },
                                secondaryTitle: String(localized: "Keep plan"),
                                secondary: { confirmEnd = false },
                                onClose: { confirmEnd = false })
                    .transition(.opacity)
            }
        }
        .onAppear { if startedRevision == nil { startedRevision = plans.revision } }
        .onChange(of: plans.revision) { _, new in
            // A plan started from a template page inside this sheet: close the sheet on the way back.
            if isModalRoot, let start = startedRevision, new != start { dismiss() }
        }
    }

    private func currentPlan(_ plan: PulsePlan) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(PulseTheme.JournalPlan.rowGlyph)
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.template.name)
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(PlanCopy.summary(plan.goals))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.JournalPlan.currentPlanCard))
        .accessibilityElement(children: .combine)
    }

    private func templateCard(_ template: PulsePlan.Template) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: template.symbol)
                .font(PulseTheme.JournalPlan.rowGlyph)
                .foregroundStyle(PlanTemplateStyle.title(template))
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PlanTemplateStyle.title(template))
                Text(template.summary)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlanTemplateStyle.background(template))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Shows the plan's goals"))
    }
}

/// A template card's tint and title colour (reviews/r11: lit from the top-right over a dark base).
enum PlanTemplateStyle {
    static func title(_ template: PulsePlan.Template) -> Color {
        switch template {
        case .boostFitness: return PulseTheme.JournalPlan.boostFitnessTitle
        case .feelBetter: return PulseTheme.JournalPlan.feelBetterTitle
        case .sleepDeeper: return PulseTheme.JournalPlan.sleepDeeperTitle
        case .custom: return PulseTheme.textPrimary
        }
    }

    @ViewBuilder
    static func background(_ template: PulsePlan.Template) -> some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        switch template {
        case .custom:
            shape.fill(PulseTheme.JournalPlan.customPlanCard)
        default:
            shape.fill(LinearGradient(colors: [tint(template), PulseTheme.JournalPlan.templateBase],
                                      startPoint: .topTrailing, endPoint: .bottomLeading))
        }
    }

    private static func tint(_ template: PulsePlan.Template) -> Color {
        switch template {
        case .boostFitness: return PulseTheme.JournalPlan.boostFitnessTint
        case .feelBetter: return PulseTheme.JournalPlan.feelBetterTint
        case .sleepDeeper: return PulseTheme.JournalPlan.sleepDeeperTint
        case .custom: return PulseTheme.JournalPlan.customPlanCard
        }
    }
}

// MARK: - A plan's goals before it starts

/// A template's goals (adjustable), or the Custom plan's goal picker, then START PLAN.
struct PlanPreviewRoute: PulseScreenRoute {
    let template: PulsePlan.Template

    var view: some View { PlanPreviewView(template: template) }
}

struct PlanPreviewView: View {
    let template: PulsePlan.Template

    @Environment(\.dismiss) private var dismiss
    @State private var plans = PulsePlanStore.shared
    @State private var goals: [PulsePlanGoal] = []
    @State private var didLoad = false
    @StateObject private var catalog = JournalCatalogStore()

    var body: some View {
        PulseScreenScaffold(title: template.planName) {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .pulseText(.pageTitle)
                    .foregroundStyle(PlanTemplateStyle.title(template))
                    .accessibilityAddTraits(.isHeader)
                Text(template.summary)
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if template == .custom {
                PlanGoalPicker(goals: $goals)
            } else {
                PulseListSectionHeader(String(localized: "Weekly goals"))
                    .padding(.top, 8)
                ForEach($goals) { $goal in
                    PlanGoalEditorCard(goal: $goal)
                }
            }
            Button(action: start) {
                Text(plans.plan == nil ? String(localized: "Start plan") : String(localized: "Switch to this plan"))
            }
            .buttonStyle(.pulseOutlineWhite)
            .disabled(goals.isEmpty)
            .opacity(goals.isEmpty ? 0.4 : 1)
            .padding(.top, 8)
            Text(String(localized: "Behavior goals are added to your Journal for daily tracking."))
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            goals = template.defaultGoals
        }
    }

    private func start() {
        PlanJournalSync.ensureInJournal(goals, catalog: catalog)
        plans.start(template, goals: goals, today: PulseJournalView.dayKey(offset: 0))
        PulsePlanReminders.sync(active: true)
        dismiss()
    }
}

/// The Custom plan's picker: every kind of goal, on or off, each adjustable once on.
struct PlanGoalPicker: View {
    @Binding var goals: [PulsePlanGoal]
    /// Kinds the plan already has (not offered again).
    var existing: Set<PulsePlanGoal.Kind> = []
    /// Before a plan starts, behaviour goals are added afterwards from Plan Overview.
    var showsBehaviorNote = true

    private static let options: [(section: String, kinds: [PulsePlanGoal])] = [
        (String(localized: "Sleep"), [PulsePlanGoal(kind: .sleepPerformance, value: 85),
                                      PulsePlanGoal(kind: .sleepConsistency, value: 80)]),
        (String(localized: "Strain"), [PulsePlanGoal(kind: .dayStrain, days: 4, value: 14)]),
        (String(localized: "Steps"), [PulsePlanGoal(kind: .steps, days: 5, value: 7000)]),
        (String(localized: "HR zones"), [PulsePlanGoal(kind: .hrZones45, value: 30),
                                         PulsePlanGoal(kind: .hrZones13, value: 180)]),
        (String(localized: "Activities"), [PulsePlanGoal(kind: .anyActivity, days: 4),
                                           PulsePlanGoal(kind: .strengthActivity, days: 2),
                                           PulsePlanGoal(kind: .strengthTime, value: 90),
                                           PulsePlanGoal(kind: .recoveryActivity, days: 2)]),
    ]

    var body: some View {
        ForEach(Self.options.filter { !Set($0.kinds.map(\.kind)).isSubset(of: existing) }, id: \.section) { option in
            PulseListSectionHeader(option.section)
                .padding(.top, 8)
            ForEach(option.kinds.filter { !existing.contains($0.kind) }, id: \.kind) { template in
                if let i = goals.firstIndex(where: { $0.kind == template.kind }) {
                    PlanGoalEditorCard(goal: $goals[i], onRemove: { goals.remove(at: i) })
                } else {
                    Button { goals.append(PulsePlanGoal(kind: template.kind, days: template.days, value: template.value)) } label: {
                        PulseListRow(symbol: "plus", title: template.title(), trailing: .none)
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
        }
        if showsBehaviorNote {
            PulseListSectionHeader(String(localized: "Behaviors"))
                .padding(.top, 8)
            Text(String(localized: "Add behavior goals from Plan Overview once the plan has started: BEHAVIORS › EDIT."))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension PlanCopy {
    /// "7,000+ Steps, Hydration and Any Recovery Activity each week."
    static func summary(_ goals: [PulsePlanGoal]) -> String {
        let titles = goals.map { $0.title() }
        guard let last = titles.last else { return String(localized: "No goals yet.") }
        if titles.count == 1 { return String(localized: "\(last) each week.") }
        let head = titles.dropLast().joined(separator: ", ")
        return String(localized: "\(head) and \(last) each week.")
    }
}

/// Behaviour goals join the journal ("New behaviors will also be added to your Journal").
enum PlanJournalSync {
    @MainActor
    static func ensureInJournal(_ goals: [PulsePlanGoal], catalog: JournalCatalogStore) {
        let items = catalog.resolvedItems(imported: [], includeHidden: true)
        for goal in goals where goal.kind == .behavior {
            guard let subject = goal.subject else { continue }
            let id = PulseBehaviorLibrary.identity(for: subject)
            let spellings = items.filter { PulseBehaviorLibrary.identity(for: $0.canonical) == id }
            if spellings.contains(where: { !$0.hidden }) { continue }
            if let hidden = spellings.first(where: \.hidden) {
                catalog.restore(hidden.canonical)
            } else if let def = PulseBehaviorLibrary.definition(for: subject) {
                catalog.addCustom(def.canonical, kind: .bool, group: def.category.group)
            } else {
                catalog.addCustom(subject)
            }
        }
    }
}
#endif
