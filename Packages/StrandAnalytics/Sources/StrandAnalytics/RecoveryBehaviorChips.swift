import Foundation

// RecoveryBehaviorChips.swift - which of yesterday's behaviours the Recovery dive names (WHOOP_UI_SPEC
// §3.4 item 5, §3.18).
//
// The Recovery deep dive's BEHAVIOR INSIGHTS card lists, as chips, the behaviours the journal logged for
// the day whose effect on Recovery is already known: "▲ Read before bed" in teal when it has gone with a
// higher Recovery, "▼ Alcohol" in orange when with a lower one, grey when no effect stands out. This file
// decides which chips appear and how each reads, from the journal answers and the Recovery series, so the
// rule is tested without a view or a store.
//
// The rule, after the unlock rules WHOOP publishes for its Recovery Impact Analysis:
//   - nothing at all until the history holds `minimumRecoveries` Recovery scores;
//   - a behaviour is "unlocked" once it has at least 5 "yes" and 5 "no" answers on days with a Recovery
//     inside the `windowDays` before the day (BehaviorInsights' group rule);
//   - its effect is the BehaviorInsights split (Recovery on yes days against no days), significance
//     corrected with Benjamini-Hochberg across every behaviour tested;
//   - a chip appears for an unlocked behaviour answered YES for the day. A "no" makes no chip.
//
// Journal answers are keyed by the wake day (the importer's and the native journal's convention), so an
// answer keyed D describes the day before morning D and pairs with Recovery D: same-day pairing, no lag
// search. The day itself is left out of the test, so a chip states what the history shows, not what
// this morning's score did to it.
//
// Display-only: nothing here is persisted or exported, so there is no Kotlin twin to keep byte-identical.

public enum RecoveryBehaviorChips {

    /// One journal answer: the day it is keyed to (wake-day convention), the behaviour and the answer.
    public struct Answer: Equatable, Sendable {
        public let day: String
        public let behavior: String
        public let answeredYes: Bool

        public init(day: String, behavior: String, answeredYes: Bool) {
            self.day = day
            self.behavior = behavior
            self.answeredYes = answeredYes
        }
    }

    /// One chip on the card.
    public struct Chip: Equatable, Sendable {
        public enum Effect: String, Equatable, Sendable {
            /// Recovery has been higher after this behaviour.
            case helps
            /// Recovery has been lower after this behaviour.
            case hurts
            /// Tested, but no effect stands out.
            case notSignificant
        }

        /// The behaviour exactly as the journal stores it.
        public let behavior: String
        public let effect: Effect
        /// Recovery on yes days against no days, as a percent of the no-day mean; nil when that mean is 0.
        public let impactPercent: Double?

        public init(behavior: String, effect: Effect, impactPercent: Double?) {
            self.behavior = behavior
            self.effect = effect
            self.impactPercent = impactPercent
        }
    }

    /// Recovery scores the history needs before any behaviour can be analysed.
    public static let minimumRecoveries = 10
    /// How far back, in days, the answers and Recoveries a test uses may reach.
    public static let windowDays = 90

    /// The outcome label the effects are ranked under.
    static let outcome = "Recovery"

    /// One answer's identity: a behaviour answered once per day.
    private struct AnswerKey: Hashable {
        let day: String
        let behavior: String
    }

    /// The chips for `dayKey`: helps first, then hurts (each by the size of the effect), then the rest by
    /// name.
    ///
    /// - Parameters:
    ///   - answers: every journal answer; for a (day, behaviour) answered twice the later one wins, as the
    ///     repository's merge (native over imported) already guarantees.
    ///   - recoveryByDay: Recovery (0-100) by day key.
    ///   - dayKey: the day whose behaviours to name ("yyyy-MM-dd").
    public static func chips(answers: [Answer], recoveryByDay: [String: Double], dayKey: String) -> [Chip] {
        let history = recoveryByDay.filter { $0.key < dayKey && $0.value.isFinite }
        guard history.count >= minimumRecoveries,
              let windowStart = PulseDisplay.dayKey(dayKey, offsetBy: -windowDays) else { return [] }

        var latest: [AnswerKey: Bool] = [:]
        for answer in answers {
            latest[AnswerKey(day: answer.day, behavior: answer.behavior)] = answer.answeredYes
        }
        var yes: [String: Set<String>] = [:]
        var no: [String: Set<String>] = [:]
        var loggedToday = Set<String>()
        for (key, answeredYes) in latest {
            if key.day == dayKey {
                if answeredYes { loggedToday.insert(key.behavior) }
                continue
            }
            guard key.day >= windowStart, key.day < dayKey else { continue }
            if answeredYes {
                yes[key.behavior, default: []].insert(key.day)
            } else {
                no[key.behavior, default: []].insert(key.day)
            }
        }
        guard !loggedToday.isEmpty else { return [] }

        let outcomes = history.filter { $0.key >= windowStart }
        // Every behaviour with answers in the window enters the family, not just today's, so the
        // correction counts every test the analysis could have shown.
        let ranked = BehaviorInsights.rankAll(behaviors: yes, controls: no, outcomes: [outcome: outcomes])[outcome] ?? []
        let byBehavior = Dictionary(ranked.map { ($0.behavior, $0) }, uniquingKeysWith: { first, _ in first })

        let chips: [(chip: Chip, size: Double)] = loggedToday.compactMap { behavior in
            guard let effect = byBehavior[behavior] else { return nil }
            let kind: Chip.Effect
            if !effect.significant || effect.delta == 0 {
                kind = .notSignificant
            } else {
                kind = effect.delta > 0 ? .helps : .hurts
            }
            return (Chip(behavior: behavior, effect: kind, impactPercent: effect.pctChange), abs(effect.cohensD))
        }
        func rank(_ effect: Chip.Effect) -> Int {
            switch effect {
            case .helps: return 0
            case .hurts: return 1
            case .notSignificant: return 2
            }
        }
        return chips.sorted { a, b in
            if rank(a.chip.effect) != rank(b.chip.effect) { return rank(a.chip.effect) < rank(b.chip.effect) }
            if a.chip.effect != .notSignificant && a.size != b.size { return a.size > b.size }
            return a.chip.behavior < b.chip.behavior
        }
        .map(\.chip)
    }
}
