#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Journal and Behavior Insights snapshots (WHOOP_UI_SPEC §3.17, §3.18)
//
// Immutable values the journal-plan screens render from, built off the main actor by
// `PulseSnapshotBuilder+Journal.swift`. Day keys are calendar days ("yyyy-MM-dd") and only become text
// through `PulseFormat.dayLabel` (UTC), the rule every Pulse day key follows.

/// One day of the Journal: the day strip, the day's own answers, the day before's (for USE PREVIOUS
/// ANSWERS), its mood, and how far the day's week has come on the plan's behaviour goals.
struct JournalDaySnapshot: Equatable {
    /// A plan behaviour goal over the selected day's week, read by `PlanBehaviorWeek` exactly as Plan
    /// Overview reads it.
    struct PlanRowWeek: Equatable {
        /// Counted days of the week, other than the selected one, that met the goal.
        let doneElsewhere: Int
        /// The days asked for (pro-rated in the week the plan began).
        let target: Int
        /// The selected day counts toward the goal (the plan covers it), so its answer adds a day.
        let countsDay: Bool
    }

    struct Day: Equatable, Identifiable {
        let key: String
        /// Days back from today (0 = today).
        let offset: Int
        /// A native journal entry exists for the day (the Home strip's rule: `nativeJournalDays`).
        let logged: Bool
        var id: String { key }
    }

    let seq: Int
    let dayKey: String
    let offset: Int
    /// The days the strip offers, oldest first, today last.
    let strip: [Day]
    /// The imported WHOOP questions, so the catalog adopts the export's exact wording.
    let importedQuestions: [String]
    /// The day's native answers and amounts, keyed by the stored question.
    let answers: [String: Bool]
    let amounts: [String: Double]
    /// The day before's native answers and amounts.
    let previousAnswers: [String: Bool]
    let previousAmounts: [String: Double]
    /// The day's mood check-in (1–5), if any.
    let mood: Int?
    /// Per plan behaviour goal, by behaviour identity. The view adds the day's own (possibly unsaved)
    /// answer when `countsDay`.
    let planWeeks: [String: PlanRowWeek]
    /// The day's IMPORTED answers by stored question (read only while the plan has behaviour goals): the
    /// journal merges them under the native ones, so a plan row counts them as Plan Overview does.
    let importedDayAnswers: [String: Bool]
}

/// One behaviour's standing on Behavior Insights (§3.18), keyed by its identity.
struct BehaviorImpactRowData: Equatable, Identifiable {
    /// The behaviour's identity (`PulseBehaviorLibrary.identity(for:)`, or an `Auto` id).
    let id: String
    let isAuto: Bool
    /// % impact on Recovery, for a tested behaviour.
    let impact: Double?
    let significant: Bool
    /// Answers logged yes / no in the last 90 days.
    let yes: Int
    let no: Int
    /// Why it is still locked; nil once tested.
    let lock: BehaviorImpact.Lock?
    /// Mean Recovery on yes-days and no-days, and how many of each, for a tested behaviour.
    let meanWith: Double?
    let meanWithout: Double?
    let nWith: Int
    let nWithout: Int

    init(_ row: BehaviorImpact.Row, isAuto: Bool) {
        id = row.behavior
        self.isAuto = isAuto
        impact = row.impactPercent
        significant = row.isSignificant
        yes = row.yesCount
        no = row.noCount
        lock = row.lock
        meanWith = row.effect?.meanWith
        meanWithout = row.effect?.meanWithout
        nWith = row.effect?.nWith ?? 0
        nWithout = row.effect?.nWithout ?? 0
    }
}

/// What `BehaviorNames` needs besides the journal catalog to name behaviours exactly as Behavior Insights
/// does: the imported WHOOP questions and, per identity, the most recent stored question. A snapshot that
/// shows behaviours outside the page (the Recovery dive's chips, the Weekly Digest) carries it from the
/// same build as its analysis.
struct BehaviorNameSources: Equatable {
    var imported: [String] = []
    var questions: [String: String] = [:]
}

/// The Behavior Insights page.
struct BehaviorInsightsSnapshot: Equatable {
    let seq: Int
    /// Tested behaviours in WHOOP's order (helps, then not significant, then hurts).
    let unlocked: [BehaviorImpactRowData]
    /// Behaviours still locked (the view orders them by name).
    let locked: [BehaviorImpactRowData]
    /// Recoveries in all of history, and the number needed before anything is tested.
    let recoveries: Int
    let recoveriesNeeded: Int
    /// The bar scale: the largest |impact| on the page, at least 10%.
    let scale: Double
    /// The most recent stored question of each identity, for naming behaviours the catalog lacks.
    let questions: [String: String]
}

/// Behavior Details (§3.18): one behaviour's impact, follow-up breakdown and logging history.
struct BehaviorDetailsSnapshot: Equatable {
    struct BucketRow: Equatable, Identifiable {
        let id: String
        let label: String
        let impact: Double?
        let significant: Bool
        let days: Int
    }

    let seq: Int
    let row: BehaviorImpactRowData?
    /// The follow-up breakdown's header and rows (empty when the behaviour has no amounts).
    let breakdownTitle: String?
    let buckets: [BucketRow]
    /// All of history's yes and no days (journal behaviours only), for the Logging History calendar.
    let yesDays: Set<String>
    let noDays: Set<String>
    /// The page's bar scale, so a behaviour's bar matches its row on Behavior Insights.
    let scale: Double
    let today: String
    let question: String?
}

/// The Journal calendar's logged days for a span of months.
struct JournalCalendarSnapshot: Equatable {
    let loggedDays: Set<String>
}
#endif
