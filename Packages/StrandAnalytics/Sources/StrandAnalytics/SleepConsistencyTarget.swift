import Foundation

// SleepConsistencyTarget.swift — the bed and wake time that would have scored a night's Sleep Consistency
// highest: the dashed OPTIMAL BED/WAKETIME curves on the Sleep dive's SLEEP CONSISTENCY card and the
// OPTIMAL window on the Sleep Planner (WHOOP_UI_SPEC §3.3 item 7b, §3.11 item 7).
//
// `SleepConsistency` scores a night by how far its bed and wake times sat from each of the nights before it
// (the mean of |bed − bed_k| and |wake − wake_k| over the previous `priorNights` calendar nights). The bed
// time that minimises a mean of absolute distances is their MEDIAN, and the same holds for the wake time on
// its own, so the target is the circular median of the prior nights' bed times and, separately, of their
// wake times. Circular, because 23:50 and 00:10 are 20 minutes apart: the values are unwrapped around their
// circular mean before the median is taken.
//
// Defined by the score itself, not by a separate notion of "good" timing, so the curves on the card and the
// window in the planner always name exactly the times the score rewards. Pure; minutes of the local day.

public enum SleepConsistencyTarget {

    /// The times that would have scored a night's consistency highest, in minutes of the local day.
    public struct Target: Equatable, Sendable {
        /// Minute of the local day to fall asleep, in [0, 1440).
        public let bedMinute: Double
        /// Minute of the local day to wake, in [0, 1440).
        public let wakeMinute: Double

        public init(bedMinute: Double, wakeMinute: Double) {
            self.bedMinute = bedMinute
            self.wakeMinute = wakeMinute
        }
    }

    /// The target for a night compared against `prior` (the most recent `SleepConsistency.priorNights`
    /// are used, as the score uses them). nil with fewer than `SleepConsistency.minPriorNights`, exactly
    /// when the score itself is nil.
    public static func target(prior: [(bedMinute: Double, wakeMinute: Double)]) -> Target? {
        let window = Array(prior.suffix(SleepConsistency.priorNights))
        guard window.count >= SleepConsistency.minPriorNights,
              let bed = circularMedianMinute(window.map(\.bedMinute)),
              let wake = circularMedianMinute(window.map(\.wakeMinute)) else { return nil }
        return Target(bedMinute: bed, wakeMinute: wake)
    }

    /// Every night's target from the nights on the `SleepConsistency.priorNights` calendar days before it,
    /// keyed by wake day: the same neighbours `SleepConsistency.scores` compares it with. A duplicated
    /// day keeps the last entry; a night with too few neighbours is absent.
    public static func targets(_ nights: [SleepConsistency.NightTiming]) -> [String: Target] {
        var byOrdinal: [Int: SleepConsistency.NightTiming] = [:]
        for n in nights {
            if let o = SleepNeed.ordinal(n.day) { byOrdinal[o] = n }
        }
        var out: [String: Target] = [:]
        for (o, night) in byOrdinal {
            if let t = target(prior: priorTimings(endingBefore: o, in: byOrdinal)) { out[night.day] = t }
        }
        return out
    }

    /// The target for the night that ENDS on `day` (it need not be in `nights` yet: tonight's plan), from
    /// the nights on the calendar days before it.
    public static func target(forNightEnding day: String, nights: [SleepConsistency.NightTiming]) -> Target? {
        guard let o = SleepNeed.ordinal(day) else { return nil }
        var byOrdinal: [Int: SleepConsistency.NightTiming] = [:]
        for n in nights {
            if let k = SleepNeed.ordinal(n.day) { byOrdinal[k] = n }
        }
        return target(prior: priorTimings(endingBefore: o, in: byOrdinal))
    }

    /// The consistency a night would score with `bedMinute` and `wakeMinute`, against the nights before
    /// `day` (`SleepConsistency.score` over the same neighbours). nil with too few of them.
    public static func projectedScore(bedMinute: Double, wakeMinute: Double, forNightEnding day: String,
                                      nights: [SleepConsistency.NightTiming]) -> Double? {
        guard let o = SleepNeed.ordinal(day) else { return nil }
        var byOrdinal: [Int: SleepConsistency.NightTiming] = [:]
        for n in nights {
            if let k = SleepNeed.ordinal(n.day) { byOrdinal[k] = n }
        }
        return SleepConsistency.score(bedMinute: bedMinute, wakeMinute: wakeMinute,
                                      prior: priorTimings(endingBefore: o, in: byOrdinal))
    }

    /// The prior nights on the `priorNights` calendar days before ordinal `o`, oldest first.
    private static func priorTimings(endingBefore o: Int,
                                     in byOrdinal: [Int: SleepConsistency.NightTiming])
        -> [(bedMinute: Double, wakeMinute: Double)] {
        var prior: [(bedMinute: Double, wakeMinute: Double)] = []
        for back in stride(from: SleepConsistency.priorNights, through: 1, by: -1) {
            if let p = byOrdinal[o - back] { prior.append((p.bedMinute, p.wakeMinute)) }
        }
        return prior
    }

    /// The circular median of clock minutes (in [0, 1440)), or nil for none. The values are unwrapped
    /// around their circular mean (each within 12 h of it), the ordinary median is taken (the mean of the
    /// middle two for an even count), and the result is wrapped back into [0, 1440). Values spread evenly
    /// around the whole clock have no mean direction; they fall back to the plain median.
    public static func circularMedianMinute(_ minutes: [Double]) -> Double? {
        let xs = minutes.filter(\.isFinite).map(wrap)
        guard !xs.isEmpty else { return nil }
        let angles = xs.map { $0 / 1440 * 2 * Double.pi }
        let s = angles.reduce(0) { $0 + sin($1) }
        let c = angles.reduce(0) { $0 + cos($1) }
        let centre: Double
        if (s * s + c * c).squareRoot() / Double(xs.count) < 1e-9 {
            centre = 720
        } else {
            centre = wrap(atan2(s, c) / (2 * Double.pi) * 1440)
        }
        let unwrapped = xs.map { x -> Double in
            var d = x - centre
            if d > 720 { d -= 1440 }
            if d <= -720 { d += 1440 }
            return centre + d
        }.sorted()
        let mid = unwrapped.count / 2
        let median = unwrapped.count % 2 == 1 ? unwrapped[mid] : (unwrapped[mid - 1] + unwrapped[mid]) / 2
        return wrap(median)
    }

    /// `minute` wrapped into [0, 1440).
    static func wrap(_ minute: Double) -> Double {
        let r = minute.truncatingRemainder(dividingBy: 1440)
        return r < 0 ? r + 1440 : r
    }
}
