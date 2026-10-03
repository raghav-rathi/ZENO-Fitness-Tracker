#if os(iOS) && DEBUG
import SwiftUI
import WhoopStore
import StrandAnalytics

// MARK: - DEBUG launch flags for the journal-plan screens (stripped from Release)
//
// `simctl` cannot tap, so these put the group's screens into a given state at launch for captures. They
// sit beside the shell's own flags (`PulseDebugLaunch`) and are read only by this group's views:
//
//   --jp-day N                 the Journal opens N days back
//   --jp-sheet <name>          the Journal opens select | calendar | amount | mood | discard | error
//   --jp-stage                 the Journal stages a few answers (✕, ✓ with a follow-up) as if tapped
//   --jp-seed                  with --demo-seed: write a week of native journal answers if there are none
//   --jp-tab <category>        SELECT BEHAVIORS opens on a tab (custom, nutrition, …)
//   --jp-query <text>          SELECT BEHAVIORS opens with a search
//   --jp-details <identity>    Behavior Insights pushes Behavior Details for a behaviour (lib.alcohol,
//                              auto.sleepPerformance, …; "first" = the first tested row)
//   --jp-expand                Behavior Details opens with its amount breakdown expanded
//   --jp-plan <template>       start a plan (boostFitness | feelBetter | sleepDeeper | custom) if none is active
//   --jp-plan-screen <name>    Plan Overview opens recap | checkin | goal:<kind> | behavior
//   --jp-plan-expanded         the Home plan card starts expanded
//   --jp-scroll <anchor>       scroll to a section once loaded (daytime, nighttime, status, notes, …)

enum JournalPlanDebug {
    private static func value(_ flag: String) -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    private static func has(_ flag: String) -> Bool { CommandLine.arguments.contains(flag) }

    static var journalDay: Int? { value("--jp-day").flatMap(Int.init) }
    static var journalSheet: String? { value("--jp-sheet") }
    static var selectTab: String? { value("--jp-tab") }
    static var selectQuery: String? { value("--jp-query") }
    static var detailsIdentity: String? { value("--jp-details") }
    static var planTemplate: String? { value("--jp-plan") }
    static var planScreen: String? { value("--jp-plan-screen") }
    static var planExpanded: Bool { has("--jp-plan-expanded") }
    /// `--jp-expand`: Behavior Details opens with its breakdown expanded.
    static var detailsExpanded: Bool { has("--jp-expand") }
    /// `--jp-scroll <anchor>`: the Journal or a Plan screen scrolls to `.id("jp.<anchor>")` once loaded.
    static var scrollAnchor: String? { value("--jp-scroll") }

    @MainActor private static var appliedJournal = false
    @MainActor private static var appliedPlan = false

    /// Open the --jp-plan-screen sheet on Plan Overview's first load.
    @MainActor
    static func applyPlanScreen(editor: inout PlanEditorSheet?, showRecap: inout Bool) {
        guard !appliedPlan, let screen = planScreen else { return }
        appliedPlan = true
        switch screen {
        case "recap": showRecap = true
        case "behavior": editor = .behaviors
        case "add": editor = .add
        default:
            if screen.hasPrefix("goal:"),
               let section = PulsePlanSection.allCases.first(where: { "goal:\($0.rawValue)" == screen || "goal:\($0)" == screen }) {
                editor = .section(section)
            }
        }
    }
    @MainActor private static var seeded = false

    /// Stage the launch state on the Journal's first load: answers (--jp-stage) and a sheet or dialog.
    @MainActor
    static func applyJournalState(current: inout JournalAnswersState, behaviors: JournalLayout,
                                  sheet: inout JournalSheet?, dialog: inout JournalDialog?, saveFailed: inout Bool) {
        guard !appliedJournal else { return }
        appliedJournal = true
        let rows: [PulseBehavior] = behaviors.sections.flatMap { $0.rows }.compactMap {
            if case .behavior(let b) = $0 { return b } else { return nil }
        }
        if has("--jp-stage") {
            var withFollowUp: PulseBehavior?
            for (i, b) in rows.enumerated() {
                let id = PulseBehaviorLibrary.identity(for: b.canonical)
                if b.followUp != nil && withFollowUp == nil {
                    withFollowUp = b
                    current.answers[id] = true
                    if let first = b.followUp?.options.first { current.amounts[id] = first * 2 }
                } else if i % 3 == 0 {
                    current.answers[id] = false
                } else if i % 3 == 1 {
                    current.answers[id] = true
                }
            }
            current.mood = 4
            current.note = "Long day at work, early night."
        }
        switch journalSheet {
        case "select": sheet = .select
        case "calendar": sheet = .calendar
        case "mood": sheet = .mood
        case "amount":
            if let b = rows.first(where: { $0.followUp != nil }), let f = b.followUp {
                let id = PulseBehaviorLibrary.identity(for: b.canonical)
                current.answers[id] = true
                sheet = .amount(id: id, followUp: f)
            }
        case "discard": dialog = .discard(.close)
        case "error": saveFailed = true
        default: break
        }
    }

    /// With --demo-seed and --jp-seed: a week of native answers (never over real ones), so the strip, the
    /// calendar and USE PREVIOUS ANSWERS have something to show.
    @MainActor
    static func seedJournalIfRequested(repo: Repository) async {
        guard has("--jp-seed"), has("--demo-seed"), !seeded else { return }
        seeded = true
        let today = PulseJournalView.dayKey(offset: 0)
        let from = PulseJournalView.dayKey(offset: 13)
        guard await repo.nativeJournalDays(from: from, to: today).isEmpty else { return }
        for n in [1, 2, 3, 5, 6, 8, 9] {
            let day = PulseJournalView.dayKey(offset: n)
            await repo.saveJournalAnswer(day: day, question: "Did you eat close to bedtime?", answeredYes: n % 3 == 0)
            await repo.saveJournalAnswer(day: day, question: "Did you view a screen in bed?", answeredYes: n % 2 == 0)
            await repo.saveJournalAnswer(day: day, question: "Did you feel stressed?", answeredYes: n == 2)
            if n % 4 == 1 {
                await repo.saveJournalNumeric(day: day, question: "Did you drink any alcohol?", value: Double(n % 3 + 1))
            } else {
                await repo.saveJournalAnswer(day: day, question: "Did you drink any alcohol?", answeredYes: false)
            }
        }
    }

    /// With --jp-plan: start that plan once, if none is active.
    @MainActor
    static func startPlanIfRequested() {
        guard let raw = planTemplate, PulsePlanStore.shared.plan == nil,
              let template = PulsePlan.Template(rawValue: raw) else { return }
        var goals = template.defaultGoals
        if template == .custom {
            goals = [PulsePlanGoal(kind: .steps, days: 5, value: 7000),
                     PulsePlanGoal(kind: .dayStrain, days: 4, value: 12),
                     PulsePlanGoal(kind: .hrZones45, value: 45),
                     PulsePlanGoal(kind: .anyActivity, days: 4),
                     PulsePlanGoal(kind: .sleepPerformance, value: 85),
                     PulsePlanGoal(kind: .behavior, days: 4, subject: "Did you drink any alcohol?", avoid: true)]
        }
        // Started two Mondays ago, so this week and last week are whole (the recap has a week to show).
        let today = PulseJournalView.dayKey(offset: 0)
        let monday = WeeklyPlanProgress.weekStart(of: today).flatMap { PulseDisplay.dayKey($0, offsetBy: -14) } ?? today
        PulsePlanStore.shared.start(template, goals: goals, today: monday)
    }
}
#endif
