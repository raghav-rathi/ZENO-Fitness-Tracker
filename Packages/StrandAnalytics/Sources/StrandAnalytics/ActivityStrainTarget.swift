import Foundation

// ActivityStrainTarget.swift — how much one activity must add to bring the day's Strain to a target, and
// what the day reads once an activity is added.
//
// Strain is log-compressed on purpose (`StrainScorer`: Effort = maxStrain × ln(TRIMP + 1) / ln(D)), so two
// Strains do not add: a day at 12 plus a 12 activity is nowhere near 24. What does add is the load
// underneath, the accumulated TRIMP. The day's window contains the activity's samples, so for the same
// recipe the day's TRIMP after an activity is the day's TRIMP before it plus the activity's own:
//
//   T(day after) = T(day before) + T(activity)
//
// Both directions therefore go through `StrainScorer.trimp(fromStrain:denominator:)` (the exact inverse of
// the log map) and back through `trimpToStrain`:
//
//   required activity Effort  = strain( T(target day) − T(day so far) )
//   estimated day Effort      = strain( T(day so far) + T(activity) )
//
// Exact for an Edwards-scored day with the default denominator. A Banister day passes its own
// `StrainScorer.logMapDenominator(method:sex:)`; its sedentary floor is subtracted per sample on both sides
// alike, so the sum still holds to within a sample's rounding.
//
// Everything is on the stored 0–`StrainScorer.maxStrain` Effort axis. Callers that show WHOOP's 0–21 Strain
// convert at the edge, exactly as every other Strain read-out does. Display math only: nothing here is
// stored, so there is no persisted value for an Android twin to match (see the Pulse activity notes).

public enum ActivityStrainTarget {

    /// The Effort an activity must score for the day to land on `targetDayEffort`, given the day's Effort
    /// so far. Zero when the day is already at or past the target (there is nothing left to build). Nil
    /// when an input is not finite or the denominator is outside the log map's domain (D ≤ 1).
    public static func requiredActivityEffort(dayEffort: Double, targetDayEffort: Double,
                                              denominator: Double = StrainScorer.strainDenominator) -> Double? {
        guard dayEffort.isFinite, targetDayEffort.isFinite, denominator.isFinite, denominator > 1 else {
            return nil
        }
        let day = StrainScorer.trimp(fromStrain: dayEffort, denominator: denominator)
        let target = StrainScorer.trimp(fromStrain: targetDayEffort, denominator: denominator)
        guard target > day else { return 0 }
        return min(StrainScorer.maxStrain, StrainScorer.trimpToStrain(target - day, denominator: denominator))
    }

    /// The day's Effort once an activity scoring `activityEffort` is added to a day at `dayEffort`, capped at
    /// the top of the axis (two near-maximal loads would otherwise read past it). Nil when an input is not
    /// finite or the denominator is outside the log map's domain.
    public static func estimatedDayEffort(dayEffort: Double, activityEffort: Double,
                                          denominator: Double = StrainScorer.strainDenominator) -> Double? {
        guard dayEffort.isFinite, activityEffort.isFinite, denominator.isFinite, denominator > 1 else {
            return nil
        }
        let day = StrainScorer.trimp(fromStrain: dayEffort, denominator: denominator)
        let activity = StrainScorer.trimp(fromStrain: activityEffort, denominator: denominator)
        return min(StrainScorer.maxStrain, StrainScorer.trimpToStrain(day + activity, denominator: denominator))
    }

    /// Where an estimated day sits against the day's optimal range (all on one axis): under it the day stays
    /// restorative, inside it the training is optimal, above it the day is overreaching.
    public enum TrainingState: String, Sendable, Equatable, CaseIterable {
        case restorative
        case optimal
        case overreaching
    }

    /// The training state of `estimatedDay` against `optimalRange`. A day exactly on either edge of the
    /// range counts as inside it.
    public static func trainingState(estimatedDay: Double, optimalRange: ClosedRange<Double>) -> TrainingState {
        if estimatedDay < optimalRange.lowerBound { return .restorative }
        if estimatedDay > optimalRange.upperBound { return .overreaching }
        return .optimal
    }
}
