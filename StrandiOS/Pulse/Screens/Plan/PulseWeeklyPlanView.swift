#if os(iOS)
import SwiftUI
import StrandAnalytics

/// My Plan (WHOOP_UI_SPEC §3.19): Plan Overview, pushed, or Edit Plan as a sheet (`editing`).
///
/// With no plan, the pushed page is the plan chooser (Home's "EXPLORE PLANS →").
struct PulseWeeklyPlanView: View {
    /// The rebuilt plan screens: Home's My Plan card and its EXPLORE PLANS open them.
    static let isRebuilt = true
    /// True for the Edit Plan modal rather than Plan Overview.
    var editing = false

    var body: some View {
        if editing {
            PulseEditPlanView()
        } else {
            PulsePlanOverviewView()
        }
    }
}

/// PLAN OVERVIEW (§3.19): the plan's name, the days left and "27% ACCOMPLISHED" with EDIT PLAN ✎ [Z], the
/// Friday check-in from Friday to Sunday, last week's recap until it has been seen, then the goals by
/// section ("HR ZONES 4-5 TRAINING", "SLEEP", "STRAIN", "ACTIVITIES", "BEHAVIORS"), each with EDIT ✎: time
/// goals on a thick bar with the activities behind them, metric goals with their day marks and a 7-day chart
/// against a dashed GOAL line, count goals on MON–SUN circles.
struct PulsePlanOverviewView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var plans = PulsePlanStore.shared
    @State private var snapshot: PlanWeekSnapshot?
    @State private var lastWeek: PlanWeekSnapshot?
    @State private var editor: PlanEditorSheet?
    @State private var showRecap = false
    @State private var switchAfterRecap = false

    #if DEBUG
    @State private var debugHomeCard = false
    @State private var debugPreview: PlanPreviewRoute?
    #endif

    var body: some View {
        Group {
            overview
        }
        #if DEBUG
        .onAppear {
            JournalPlanDebug.startPlanIfRequested()
            if JournalPlanDebug.planScreen == "homecard" { debugHomeCard = true }
            if let screen = JournalPlanDebug.planScreen, screen.hasPrefix("preview:"),
               let template = PulsePlan.Template(rawValue: String(screen.dropFirst("preview:".count))) {
                debugPreview = PlanPreviewRoute(template: template)
            }
        }
        .navigationDestination(isPresented: $debugHomeCard) { PlanHomeCardPreview() }
        .navigationDestination(item: $debugPreview) { $0.view }
        #endif
    }

    @ViewBuilder
    private var overview: some View {
        if let plan = plans.plan {
            PulseScreenScaffold(title: String(localized: "Plan Overview"), coach: .button,
                                coachSeed: String(localized: "Help me make progress on this week's \(plan.cardTitle)."),
                                ready: snapshot != nil) {
                PulseLoadingGate(isLoading: snapshot == nil) {
                    if let snapshot { content(plan, snapshot) }
                } skeleton: {
                    PulseSkeleton.cards([118, 160, 260, 150])
                }
            }
            .task(id: PlanLoadKey(seq: model.seq, plan: plan)) { await load(plan) }
            .sheet(item: $editor) { sheet in
                editorSheet(sheet, plan: plan)
            }
            .sheet(isPresented: $showRecap, onDismiss: {
                if switchAfterRecap {
                    switchAfterRecap = false
                    navigator.open(.weeklyPlan(editing: true))
                }
            }) {
                if let lastWeek {
                    PulsePlanRecapView(plan: plan, week: lastWeek,
                                       onContinue: { plans.markRecapSeen(week: lastWeek.weekStart); showRecap = false },
                                       onSwitch: {
                                           plans.markRecapSeen(week: lastWeek.weekStart)
                                           switchAfterRecap = true
                                           showRecap = false
                                       })
                }
            }
        } else {
            PulseEditPlanView()
        }
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ plan: PulsePlan, _ s: PlanWeekSnapshot) -> some View {
        let todayIndex = s.days.firstIndex(of: s.today)
        header(plan, s)
        if let lastWeek, recapDue(plan, lastWeek) {
            recapRow(lastWeek)
        }
        if checkInDue(plan, s) {
            PlanCheckInCard(week: s) { plans.markCheckInSeen(week: s.weekStart) }
        }
        if s.goals.isEmpty {
            noGoals
        }
        ForEach(PulsePlanSection.allCases) { section in
            let goals = s.goals.filter { $0.section == section }
            if !goals.isEmpty {
                PlanSectionHeader(title: section.title) {
                    if section == .behaviors {
                        navigator.open(PlanBehaviorGoalRoute().route)
                    } else {
                        editor = .section(section)
                    }
                }
                .padding(.top, 12)
                .id("pulse.plan-\(section.debugName)")
                ForEach(goals) { goal in PlanGoalCard(progress: goal, todayIndex: todayIndex) }
            }
        }
        Button { editor = .add } label: {
            PulseListRow(symbol: "plus", title: String(localized: "Add a goal"), trailing: .none)
        }
        .buttonStyle(PulsePressStyle())
        .padding(.top, 12)
        if !plan.goals.contains(where: { $0.kind == .behavior }) {
            Button { navigator.open(PlanBehaviorGoalRoute().route) } label: {
                PulseListRow(symbol: "plus", title: String(localized: "Add a behavior goal"), trailing: .none)
            }
            .buttonStyle(PulsePressStyle())
        }
        Text(String(localized: "Progress is measured from your strap, your activities and your journal, Monday to Sunday."))
            .pulseText(.rowSubline)
            .foregroundStyle(PulseTheme.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The plan's name, the days left and the week's percentage, with EDIT PLAN ✎ [Z].
    private func header(_ plan: PulsePlan, _ s: PlanWeekSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.cardTitle)
                    .pulseText(.capsuleLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                PulseTextAccessory(title: String(localized: "Edit plan"), symbol: "pencil") {
                    navigator.open(.weeklyPlan(editing: true))
                }
                .padding(.vertical, -10)
            }
            Text(PlanCopy.daysLeft(s.daysLeft))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
            PlanAccomplishedBar(percent: s.percent)
                .padding(.top, 4)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.dialog, style: .continuous)
            .fill(PulseTheme.JournalPlan.planCard))
    }

    private func recapRow(_ week: PlanWeekSnapshot) -> some View {
        Button { showRecap = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(PulseTheme.JournalPlan.rowGlyph)
                    .foregroundStyle(PulseTheme.Plan.progress)
                VStack(alignment: .leading, spacing: 3) {
                    Text(String(localized: "My week recap"))
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "Last week: \(week.percent ?? 0)% complete"))
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.rowSubline)
                }
                Spacer(minLength: 8)
                PulseChevron(color: PulseTheme.textTertiary, size: 14)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.listWithSubline)
            .pulseCardBackground(.rowCard)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }

    private var noGoals: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "No goals yet"))
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "Add a sleep, strain, activity or behavior goal for the week."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
    }

    // MARK: Check-in and recap timing

    /// Friday to Sunday of a week the plan covered from at least Monday… any start day, until dismissed.
    private func checkInDue(_ plan: PulsePlan, _ s: PlanWeekSnapshot) -> Bool {
        guard let weekday = WeeklyPlanProgress.isoWeekday(s.today), weekday >= 5 else { return false }
        return plan.checkInSeenWeek != s.weekStart && !s.unfinished.isEmpty
    }

    /// Last week's recap, until seen, once the plan covered any of last week.
    private func recapDue(_ plan: PulsePlan, _ last: PlanWeekSnapshot) -> Bool {
        guard let sunday = last.days.last else { return false }
        return plan.startedOn <= sunday && plan.recapSeenWeek != last.weekStart
    }

    // MARK: Editors

    /// A section's goals, or new ones, in a sheet (WHOOP's editors other than BEHAVIOR GOAL were not seen in
    /// 2026 [U]); BEHAVIOR GOAL itself is pushed (`PlanBehaviorGoalRoute`, journal-plan-2026/30).
    @ViewBuilder
    private func editorSheet(_ sheet: PlanEditorSheet, plan: PulsePlan) -> some View {
        switch sheet {
        case .section(let section):
            PulsePlanGoalEditor(title: section.title, goals: plan.goals.filter { PulsePlanSection($0.kind) == section })
        case .add:
            PulsePlanGoalEditor(title: String(localized: "Add a goal"), goals: [], adding: true)
        }
    }

    // MARK: Loading

    private func load(_ plan: PulsePlan) async {
        #if DEBUG
        var behaviorGoal = false
        JournalPlanDebug.applyPlanScreen(editor: &editor, showRecap: &showRecap, behaviorGoal: &behaviorGoal)
        if behaviorGoal { navigator.open(PlanBehaviorGoalRoute().route) }
        #endif
        #if DEBUG
        let week = JournalPlanDebug.planWeekOffset ?? 0
        #else
        let week = 0
        #endif
        if let s = await model.build(dayOffset: 0, { builder, r in await builder.planWeek(r, plan: plan, weekOffset: week) }) {
            snapshot = s
        }
        if let last = await model.build(dayOffset: 0, { builder, r in await builder.planWeek(r, plan: plan, weekOffset: -1) }) {
            lastWeek = last
        }
        PulsePlanReminders.sync(active: true)
    }
}

#if DEBUG
/// DEBUG only (`--jp-plan-screen homecard`): Home's My Plan card on a page of its own, as Home places it.
struct PlanHomeCardPreview: View {
    var body: some View {
        PulseScreenScaffold(title: "My Plan card", spacing: 0) {
            PulseSectionHeader(String(localized: "My Plan"))
                .padding(.top, 8)
            PulsePlanHomeCard()
                .padding(.top, PulseTheme.Layout.headerGap)
        }
    }
}
#endif

/// What a Plan Overview editor sheet edits.
enum PlanEditorSheet: Identifiable, Equatable {
    case section(PulsePlanSection)
    case add

    var id: String {
        switch self {
        case .section(let s): return "section-\(s.rawValue)"
        case .add: return "add"
        }
    }
}

/// Reload when the data or the plan changes.
struct PlanLoadKey: Equatable {
    let seq: Int
    let plan: PulsePlan
}

// MARK: - Friday check-in

/// FRIDAY CHECK-IN (§3.19, text only in WHOOP [U]): from Friday, what is left for each unfinished goal with
/// the days that remain. Dismissed for the week with ✕.
struct PlanCheckInCard: View {
    let week: PlanWeekSnapshot
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(String(localized: "Friday check-in"))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(PulseTheme.JournalPlan.checkGlyph)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .padding(.vertical, -12)
                .padding(.trailing, -12)
                .accessibilityLabel(String(localized: "Dismiss the check-in"))
            }
            Text(String(localized: "\(PlanCopy.daysLeft(week.daysLeft)) this week. Here's what's left:"))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
            ForEach(week.unfinished) { goal in
                HStack(spacing: 12) {
                    PulseGoalRing(kind: goal.ring, diameter: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.title)
                            .pulseText(.coachingTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Text(PlanCopy.remaining(goal))
                            .pulseText(.rowSubline)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.featureAnnounceBorder,
                                         startPoint: .leading, endPoint: .trailing), lineWidth: 1.5)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.Gradients.featureAnnounceFill)))
    }
}

/// Plan wording shared by the overview, the Home card and the recap.
enum PlanCopy {
    /// "6 days left", "Last day".
    static func daysLeft(_ n: Int) -> String {
        switch n {
        case ..<1: return String(localized: "Week complete")
        case 1: return String(localized: "Last day")
        default: return String(localized: "\(n) days left")
        }
    }

    /// What a goal still needs this week.
    static func remaining(_ goal: PlanGoalProgress) -> String {
        switch goal.ring {
        case .count(let done, let target):
            let left = max(0, target - done)
            return left == 1 ? String(localized: "1 more day to go") : String(localized: "\(left) more days to go")
        case .value:
            if goal.style == .time { return goal.footer }
            return [goal.averageText, goal.footer].compactMap { $0 }.joined(separator: " · ")
        }
    }
}
#endif
