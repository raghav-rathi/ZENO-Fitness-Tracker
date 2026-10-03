import Foundation

// RecoveryBehaviorChips.swift - which of yesterday's behaviours the Recovery dive names, and how each
// reads (WHOOP_UI_SPEC §3.4 item 5, §3.18).
//
// The Recovery deep dive's BEHAVIOR INSIGHTS card lists, as chips, the behaviours logged YES for the day
// whose effect on Recovery is already known: "▲ Read Before Bed" in teal when it has gone with a higher
// Recovery, "▼ Alcohol" in orange when with a lower one, grey when no effect stands out. A chip opens that
// behaviour's Behavior Details. This file decides which chips appear and how each reads, so the rule is
// tested without a view or a store.
//
// ONE RESOLVER. A chip must say what Behavior Insights says about the same behaviour, so it reads the
// page's own analysis (`BehaviorImpact.analyze`, which the app builds once for Behavior Insights, Behavior
// Details and this card) rather than ranking anything itself: the same behaviours, folded by identity (a
// library behaviour's imported and native spellings are one), the same auto-tracked behaviours (85%+ Sleep
// Performance, Consistent Bed Time, Late Workout, …), the same 90-day window, the same family of tests
// against Recovery and the same correction. A chip's colour is the page's colour for that row
// (`verdict`, which the page's bars read too).
//
// Which chips appear is the page's unlock rule (WHOOP's, for its Recovery Impact Analysis, §2.9): nothing
// before 10 Recoveries in all, then a behaviour once it has 5 "yes" and 5 "no" days with a Recovery in
// the window. A chip appears for a tested behaviour answered YES for the day; a "no" makes no chip.
//
// Answers are keyed by the wake day (the importer's and the native journal's convention): an answer keyed
// D describes the day before morning D, so the day's chips are "yesterday's behaviours". The auto-tracked
// behaviours are keyed the same way, by the morning whose Recovery they are compared with.
//
// Display-only: nothing here is persisted or exported, so there is no Kotlin twin to keep byte-identical.

public enum RecoveryBehaviorChips {

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

        /// The behaviour's identity, exactly as the analysis keys it (a journal behaviour's identity or an
        /// auto-tracked behaviour's id): the key Behavior Details opens with, never a display name.
        public let behavior: String
        public let effect: Effect
        /// Behavior Insights' % impact on Recovery for the behaviour (with against without, as a percent of
        /// the "without" mean).
        public let impactPercent: Double?

        public init(behavior: String, effect: Effect, impactPercent: Double?) {
            self.behavior = behavior
            self.effect = effect
            self.impactPercent = impactPercent
        }
    }

    /// How Behavior Insights reads a tested behaviour, and so how its chip reads: helps or hurts only when
    /// the effect is significant and prints as a whole percent other than 0, otherwise no clear effect.
    public static func verdict(impactPercent: Double?, significant: Bool) -> Chip.Effect {
        guard let impact = impactPercent, impact.isFinite, significant, impact.rounded() != 0 else {
            return .notSignificant
        }
        return impact > 0 ? .helps : .hurts
    }

    /// The chips for `dayKey`: the behaviours `analysis` has tested that were answered YES for the day,
    /// helps first, then hurts (each by the size of its impact), then the rest by identity.
    ///
    /// - Parameters:
    ///   - analysis: Behavior Insights' analysis, exactly as the page shows it.
    ///   - answers: the yes and no days the analysis was built from, by the same identities.
    ///   - dayKey: the day whose behaviours to name ("yyyy-MM-dd").
    public static func chips(analysis: BehaviorImpact.Analysis, answers: [String: BehaviorImpact.Answers],
                             dayKey: String) -> [Chip] {
        let chips = analysis.unlocked.compactMap { row -> Chip? in
            guard answers[row.behavior]?.yes.contains(dayKey) == true else { return nil }
            return Chip(behavior: row.behavior,
                        effect: verdict(impactPercent: row.impactPercent, significant: row.isSignificant),
                        impactPercent: row.impactPercent)
        }
        func rank(_ effect: Chip.Effect) -> Int {
            switch effect {
            case .helps: return 0
            case .hurts: return 1
            case .notSignificant: return 2
            }
        }
        return chips.sorted { a, b in
            if rank(a.effect) != rank(b.effect) { return rank(a.effect) < rank(b.effect) }
            let sizeA = abs(a.impactPercent ?? 0), sizeB = abs(b.impactPercent ?? 0)
            if a.effect != .notSignificant && sizeA != sizeB { return sizeA > sizeB }
            return a.behavior < b.behavior
        }
    }
}
