import Foundation

// RecoveryBehaviorChips.swift - which of yesterday's behaviours the Recovery dive names, and how each
// reads (WHOOP_UI_SPEC §3.4 item 5, §3.18).
//
// The Recovery deep dive's BEHAVIOR INSIGHTS card lists, as chips, the behaviours the journal logged YES
// for the day whose effect on Recovery is already known: "▲ Read Before Bed" in teal when it has gone with
// a higher Recovery, "▼ Alcohol" in orange when with a lower one, grey when no effect stands out. This file
// decides which chips appear and how each reads, so the rule is tested without a view or a store.
//
// ONE RESOLVER. The card opens the behaviour analysis (until Behavior Insights is rebuilt, the classic
// Insights hub, "What moves you"), so a chip must say what that screen says. Its effect is therefore the
// hub's own ranking: `EffectRanker.rankAll` over EVERY journal answer on file, against the four outcomes
// the hub ranks (`outcomeKeys`: Recovery, HRV, Sleep Performance, resting heart rate) at lags 0, +1 and
// +2, corrected with Benjamini-Hochberg across that whole family, and the chip takes the Recovery row for
// its behaviour. Ranking Recovery alone, one lag, or a shorter window would correct across a smaller
// family and could call significant what the hub calls noise, or the reverse.
//
// Which chips appear is WHOOP's unlock rule for its Recovery Impact Analysis (§2.9) on top:
//   - nothing until the Recovery series holds `minimumRecoveries` scores up to the day;
//   - a behaviour is unlocked once it has `minimumAnswers` "yes" and as many "no" answers on days with a
//     Recovery, within the `windowDays` days ending on the day;
//   - a chip appears for an unlocked behaviour answered YES for the day. A "no" makes no chip.
//
// Journal answers are keyed by the wake day (the importer's and the native journal's convention): an
// answer keyed D describes the day before morning D, so the day's chips are "yesterday's behaviours".
//
// Auto-tracked behaviours (Consistent Bed Time, 85%+ Sleep Performance, Late Workout) join when the
// behaviour resolver that Behavior Insights' rebuild and this card share lands; until then only journal
// answers can make a chip.
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
            /// Recovery has been higher with this behaviour.
            case helps
            /// Recovery has been lower with this behaviour.
            case hurts
            /// Tested, but no effect stands out.
            case notSignificant
        }

        /// The behaviour exactly as the journal stores it (the canonical key, never a display name).
        public let behavior: String
        public let effect: Effect
        /// Recovery with the behaviour against without, as a percent of the "without" mean, at the lag the
        /// ranking kept; nil when that mean is 0.
        public let impactPercent: Double?

        public init(behavior: String, effect: Effect, impactPercent: Double?) {
            self.behavior = behavior
            self.effect = effect
            self.impactPercent = impactPercent
        }
    }

    /// The outcome series the behaviours are ranked against, keyed as the store keys them: the Insights
    /// hub's set, so the Benjamini-Hochberg family is the hub's. Other keys in `outcomes` are ignored.
    public static let outcomeKeys = ["recovery", "hrv", "sleep_performance", "rhr"]
    /// The Recovery series' key in `outcomes`; its ranked rows are the chips' verdicts.
    public static let recoveryKey = "recovery"
    /// Recovery scores the history needs, up to the day, before any behaviour can be named.
    public static let minimumRecoveries = 10
    /// The days, ending on the day, inside which a behaviour's answers unlock it.
    public static let windowDays = 90
    /// "Yes" answers, and as many "no" answers, a behaviour needs on days with a Recovery to unlock.
    public static let minimumAnswers = BehaviorInsights.minGroupForSignificance

    /// One answer's identity: a behaviour answered once per day.
    private struct AnswerKey: Hashable {
        let day: String
        let behavior: String
    }

    /// The chips for `dayKey`: helps first, then hurts (each by the size of the effect), then the rest by
    /// name.
    ///
    /// - Parameters:
    ///   - answers: every journal answer on file; for a (day, behaviour) answered twice the later one wins,
    ///     as the repository's merge (native over imported) already guarantees.
    ///   - outcomes: day key → value for each of `outcomeKeys` ("recovery" 0-100, "hrv" ms,
    ///     "sleep_performance" 0-100, "rhr" bpm), read exactly as the Insights hub reads them.
    ///   - dayKey: the day whose behaviours to name ("yyyy-MM-dd").
    public static func chips(answers: [Answer], outcomes: [String: [String: Double]], dayKey: String) -> [Chip] {
        let family = outcomes.filter { outcomeKeys.contains($0.key) }
        let recovery = (family[recoveryKey] ?? [:]).filter { $0.value.isFinite }
        guard recovery.keys.filter({ $0 <= dayKey }).count >= minimumRecoveries,
              let windowStart = PulseDisplay.dayKey(dayKey, offsetBy: -(windowDays - 1)) else { return [] }

        var latest: [AnswerKey: Bool] = [:]
        for answer in answers {
            latest[AnswerKey(day: answer.day, behavior: answer.behavior)] = answer.answeredYes
        }
        // Yes days and no days per behaviour, over every answer on file (the hub's split: a day with no
        // answer is in neither, never a "no").
        var yes: [String: Set<String>] = [:]
        var no: [String: Set<String>] = [:]
        var loggedYes = Set<String>()
        for (key, answeredYes) in latest {
            if answeredYes {
                yes[key.behavior, default: []].insert(key.day)
                if key.day == dayKey { loggedYes.insert(key.behavior) }
            } else {
                no[key.behavior, default: []].insert(key.day)
            }
        }

        func answersInWindow(_ days: Set<String>?) -> Int {
            (days ?? []).filter { $0 >= windowStart && $0 <= dayKey && recovery[$0] != nil }.count
        }
        let unlocked = loggedYes.filter {
            answersInWindow(yes[$0]) >= minimumAnswers && answersInWindow(no[$0]) >= minimumAnswers
        }
        guard !unlocked.isEmpty else { return [] }

        // The hub's ranking: every behaviour with answers enters the family, not just the day's, so the
        // correction counts every test the analysis shows.
        let ranked = EffectRanker.rankAll(behaviors: yes, controls: no, outcomes: family)[recoveryKey] ?? []
        let byBehavior = Dictionary(ranked.map { ($0.behavior, $0) }, uniquingKeysWith: { first, _ in first })

        let chips: [(chip: Chip, size: Double)] = unlocked.compactMap { behavior in
            guard let row = byBehavior[behavior] else { return nil }
            let effect = row.effect
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
