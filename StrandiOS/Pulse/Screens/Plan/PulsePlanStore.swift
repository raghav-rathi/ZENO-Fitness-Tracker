#if os(iOS)
import SwiftUI
import Observation
import StrandAnalytics

// MARK: - Weekly Plan model and store (WHOOP_UI_SPEC §3.19 [Z] "A new local PlanStore")
//
// A plan is a template (Boost Fitness, Feel Better, Sleep Deeper, or Custom), its goals, and the day it
// started. Weeks run Monday to Sunday; every goal is judged afresh each week from ZENO's own data
// (`PulseSnapshotBuilder.planWeek`), so the store holds only what the wearer chose, never a progress
// number. It is UserDefaults JSON on this iPhone, like `JournalCatalogStore`; nothing leaves the device.

/// One goal of a plan.
struct PulsePlanGoal: Codable, Equatable, Hashable, Identifiable {
    enum Kind: String, Codable, CaseIterable {
        /// Average Sleep Performance (%) at least `value`.
        case sleepPerformance
        /// Average Sleep Consistency (%) at least `value`.
        case sleepConsistency
        /// `days` days with a Day Strain (0–21) of at least `value`.
        case dayStrain
        /// `days` days with at least `value` steps.
        case steps
        /// At least `value` minutes in heart-rate zones 4–5 during activities this week.
        case hrZones45
        /// At least `value` minutes in heart-rate zones 1–3 during activities this week.
        case hrZones13
        /// At least `value` minutes of strength activities this week.
        case strengthTime
        /// `days` days with any strain activity.
        case anyActivity
        /// `days` days with a strength training activity.
        case strengthActivity
        /// `days` days with a recovery activity (yoga, sauna, stretching, …).
        case recoveryActivity
        /// `days` days with a `subject` activity ("Running").
        case sport
        /// `days` days answering the journal behaviour `subject` yes (or no when `avoid`).
        case behavior
    }

    var id: String
    var kind: Kind
    /// Days per week, for count goals.
    var days: Int?
    /// The threshold or weekly target (percent, strain, steps or minutes).
    var value: Double?
    /// The sport name, or the behaviour's journal key.
    var subject: String?
    /// A behaviour goal met by answering NO ("Avoid Late Meal").
    var avoid: Bool?

    init(kind: Kind, days: Int? = nil, value: Double? = nil, subject: String? = nil, avoid: Bool? = nil) {
        self.id = UUID().uuidString
        self.kind = kind
        self.days = days
        self.value = value
        self.subject = subject
        self.avoid = avoid
    }

    /// Counted in days (a 1–7 row), as opposed to an average or a weekly total.
    var isCount: Bool {
        switch kind {
        case .dayStrain, .steps, .anyActivity, .strengthActivity, .recoveryActivity, .sport, .behavior: return true
        default: return false
        }
    }

    /// The goal as WHOOP writes it ("7,000+ Steps", "0:30+ HR Zones 4-5 Time", "Avoid Late Meal"). A word
    /// joiner keeps "85%" and its "+" on one line ("85%" / "+ Sleep Performance" read as two things).
    func title(behaviorTitle: String? = nil) -> String {
        switch kind {
        case .sleepPerformance:
            return String(localized: "\(Int(value ?? 85))%\u{2060}+ Sleep Performance")
        case .sleepConsistency:
            return String(localized: "\(Int(value ?? 80))%\u{2060}+ Sleep Consistency")
        case .dayStrain:
            return String(localized: "\(PulseFormat.oneDecimal(value ?? 14))+ Day Strain")
        case .steps:
            return String(localized: "\(PulseFormat.grouped(value ?? 7000))+ Steps")
        case .hrZones45:
            return String(localized: "\(PulseFormat.hoursMinutes(value ?? 30))+ HR Zones 4-5 Time")
        case .hrZones13:
            return String(localized: "\(PulseFormat.hoursMinutes(value ?? 180))+ HR Zones 1-3 Time")
        case .strengthTime:
            return String(localized: "\(PulseFormat.hoursMinutes(value ?? 90))+ Strength Activity Time")
        case .anyActivity:
            return String(localized: "Any Strain Activity")
        case .strengthActivity:
            return String(localized: "Any Strength Training Activity")
        case .recoveryActivity:
            return String(localized: "Any Recovery Activity")
        case .sport:
            return subject.map(WorkoutSource.displaySport) ?? String(localized: "Activity")
        case .behavior:
            let def = subject.flatMap(PulseBehaviorLibrary.definition(for:))
            if avoid == def?.avoid, let goalTitle = def?.goalTitle { return goalTitle }
            let name = behaviorTitle ?? def?.title ?? subject.map(PulseBehaviorLibrary.derivedTitle) ?? ""
            return avoid == true ? String(localized: "Avoid \(name)") : name
        }
    }
}

extension PulsePlanGoal {
    /// A time goal's kind alone, without its target ("HR Zones 4-5 Time"); any other goal's title.
    var kindTitle: String {
        switch kind {
        case .hrZones45: return String(localized: "HR Zones 4-5 Time")
        case .hrZones13: return String(localized: "HR Zones 1-3 Time")
        case .strengthTime: return String(localized: "Strength Activity Time")
        default: return title()
        }
    }
}

/// Where a goal sits on Plan Overview.
enum PulsePlanSection: Int, CaseIterable, Identifiable {
    case hrZones45, hrZones13, strength, sleep, strain, steps, activities, behaviors

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .hrZones45: return String(localized: "HR Zones 4-5 Training")
        case .hrZones13: return String(localized: "HR Zones 1-3 Training")
        case .strength: return String(localized: "Strength Training")
        case .sleep: return String(localized: "Sleep")
        case .strain: return String(localized: "Strain")
        case .steps: return String(localized: "Steps")
        case .activities: return String(localized: "Activities")
        case .behaviors: return String(localized: "Behaviors")
        }
    }

    /// The section's name in DEBUG scroll anchors (`--pulse-scroll plan-sleep`).
    var debugName: String {
        switch self {
        case .hrZones45: return "zones45"
        case .hrZones13: return "zones13"
        case .strength: return "strength"
        case .sleep: return "sleep"
        case .strain: return "strain"
        case .steps: return "steps"
        case .activities: return "activities"
        case .behaviors: return "behaviors"
        }
    }

    init(_ kind: PulsePlanGoal.Kind) {
        switch kind {
        case .hrZones45: self = .hrZones45
        case .hrZones13: self = .hrZones13
        case .strengthTime: self = .strength
        case .sleepPerformance, .sleepConsistency: self = .sleep
        case .dayStrain: self = .strain
        case .steps: self = .steps
        case .anyActivity, .strengthActivity, .recoveryActivity, .sport: self = .activities
        case .behavior: self = .behaviors
        }
    }
}

/// The active plan.
struct PulsePlan: Codable, Equatable {
    enum Template: String, Codable, CaseIterable, Identifiable {
        case boostFitness, feelBetter, sleepDeeper, custom
        var id: String { rawValue }
    }

    var template: Template
    var goals: [PulsePlanGoal]
    /// The local day key the plan started on.
    var startedOn: String
    /// The Monday of the last week whose recap the wearer has seen.
    var recapSeenWeek: String?
    /// The Monday of the last week whose Friday check-in the wearer dismissed.
    var checkInSeenWeek: String?

    /// The plan's caps name on cards ("BOOST FITNESS PLAN", "CUSTOM PLAN").
    var cardTitle: String { template.planName }

    /// The journal's plan section label ("YOUR BOOST FITNESS PLAN").
    var journalLabel: String {
        String(localized: "Your \(template.planName)")
    }

    /// The behaviour goals, in plan order.
    var behaviorGoals: [PulsePlanGoal] { goals.filter { $0.kind == .behavior && $0.subject != nil } }
}

extension PulsePlan.Template {
    /// "Boost Fitness".
    var name: String {
        switch self {
        case .boostFitness: return String(localized: "Boost Fitness")
        case .feelBetter: return String(localized: "Feel Better")
        case .sleepDeeper: return String(localized: "Sleep Deeper")
        case .custom: return String(localized: "Custom Plan")
        }
    }

    /// "Boost Fitness Plan" / "Custom Plan".
    var planName: String {
        self == .custom ? name : String(localized: "\(name) Plan")
    }

    var summary: String {
        switch self {
        case .boostFitness:
            return String(localized: "Improve fitness with high-intensity training, tracking your protein, and recovering like a pro.")
        case .feelBetter:
            return String(localized: "Feel your best by moving more, focusing on recovery activities, and staying hydrated.")
        case .sleepDeeper:
            return String(localized: "Turn great nights into a habit. Build a calming nightly routine and stick to a consistent bedtime.")
        case .custom:
            return String(localized: "Build your personalized plan by selecting weekly metric, behavior and activity goals.")
        }
    }

    var symbol: String {
        switch self {
        case .boostFitness: return "dumbbell"
        case .feelBetter: return "face.smiling"
        case .sleepDeeper: return "moon"
        case .custom: return "square.and.pencil"
        }
    }

    /// The goals a template starts with (each editable before and after starting).
    var defaultGoals: [PulsePlanGoal] {
        switch self {
        case .boostFitness:
            return [PulsePlanGoal(kind: .hrZones45, value: 30),
                    PulsePlanGoal(kind: .behavior, days: 5, subject: "Consumed protein?", avoid: false),
                    PulsePlanGoal(kind: .strengthActivity, days: 2)]
        case .feelBetter:
            return [PulsePlanGoal(kind: .steps, days: 5, value: 7000),
                    PulsePlanGoal(kind: .behavior, days: 5, subject: "Drank enough water?", avoid: false),
                    PulsePlanGoal(kind: .recoveryActivity, days: 2)]
        case .sleepDeeper:
            return [PulsePlanGoal(kind: .sleepConsistency, value: 80),
                    PulsePlanGoal(kind: .sleepPerformance, value: 85),
                    PulsePlanGoal(kind: .behavior, days: 5, subject: "Did you eat close to bedtime?", avoid: true)]
        case .custom:
            return []
        }
    }
}

/// The wearer's plan, persisted on this iPhone.
@MainActor
@Observable
final class PulsePlanStore {
    static let shared = PulsePlanStore()

    private(set) var plan: PulsePlan? { didSet { revision &+= 1 } }
    /// Bumped on every change, so a screen can tell a plan was started or edited.
    private(set) var revision = 0

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "pulse.plan.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key), let decoded = try? JSONDecoder().decode(PulsePlan.self, from: data) {
            plan = decoded
        }
    }

    /// Start (or switch to) a plan today.
    func start(_ template: PulsePlan.Template, goals: [PulsePlanGoal], today: String) {
        plan = PulsePlan(template: template, goals: goals, startedOn: today, recapSeenWeek: nil, checkInSeenWeek: nil)
        persist()
    }

    /// Replace the active plan's goals (an editor saved).
    func setGoals(_ goals: [PulsePlanGoal]) {
        guard var p = plan else { return }
        p.goals = goals
        plan = p
        persist()
    }

    /// Replace one goal, or append it when new.
    func upsert(_ goal: PulsePlanGoal) {
        guard var p = plan else { return }
        if let i = p.goals.firstIndex(where: { $0.id == goal.id }) { p.goals[i] = goal } else { p.goals.append(goal) }
        plan = p
        persist()
    }

    func remove(goalID: String) {
        guard var p = plan else { return }
        p.goals.removeAll { $0.id == goalID }
        plan = p
        persist()
    }

    /// End the plan.
    func end() {
        plan = nil
        defaults.removeObject(forKey: key)
    }

    func markRecapSeen(week: String) {
        guard var p = plan, p.recapSeenWeek != week else { return }
        p.recapSeenWeek = week
        plan = p
        persist()
    }

    func markCheckInSeen(week: String) {
        guard var p = plan, p.checkInSeenWeek != week else { return }
        p.checkInSeenWeek = week
        plan = p
        persist()
    }

    private func persist() {
        guard let plan, let data = try? JSONEncoder().encode(plan) else { return }
        defaults.set(data, forKey: key)
    }
}
#endif
