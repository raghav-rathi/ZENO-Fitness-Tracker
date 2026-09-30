import Foundation

// SleepConsistency.swift — how closely last night's bed AND wake times matched the nights before it.
//
// Rest's consistency term (0.10 of the composite) had no producer on the stored path, so every stored
// Rest ran on the neutral 0.5 and could never exceed 95. The one regularity signal that did exist
// (`VitalityEngine.sleepConsistency`) measures how steady sleep DURATION is, which says nothing about
// timing: 23:00–07:00 and 03:00–11:00 are the same duration. This scores timing, the way WHOOP describes
// its Sleep Consistency: last night's bedtime and wake time against each of the previous four nights.
//
//   deviation(k) = ( |bed − bed_k| + |wake − wake_k| ) / 2      (minutes, circular around midnight)
//   meanDev      = mean of deviation(k) over the prior nights present among the previous 4 calendar nights
//   score        = 1 − (meanDev − grace) / (zeroAt − grace), clamped to [0, 1]
//
// Circular so 23:50 and 00:10 are 20 minutes apart, not 23 h 40 min. The 15-minute grace absorbs the
// night-to-night jitter of sleep detection itself; a 3-hour mean deviation scores 0. Fewer than 3 of the
// previous 4 nights → nil, which Rest treats as neutral: a timing habit needs a few nights to exist.

public enum SleepConsistency {

    /// Calendar nights before the scored one that it is compared against.
    public static let priorNights: Int = 4
    /// Fewest of those that must be present for a score.
    public static let minPriorNights: Int = 3
    /// Mean deviation (minutes) that still scores full marks — detection jitter, not behaviour.
    public static let graceMin: Double = 15
    /// Mean deviation (minutes) at which the score reaches zero.
    public static let zeroAtMin: Double = 180

    /// One night's main-sleep timing on the local clock.
    public struct NightTiming: Equatable, Sendable {
        /// "yyyy-MM-dd" wake-day key of the night.
        public let day: String
        /// Minute of the local day the main night began, in [0, 1440).
        public let bedMinute: Double
        /// Minute of the local day the main night ended, in [0, 1440).
        public let wakeMinute: Double

        public init(day: String, bedMinute: Double, wakeMinute: Double) {
            self.day = day
            self.bedMinute = bedMinute
            self.wakeMinute = wakeMinute
        }

        /// Build from unix timestamps and each instant's own UTC offset (seconds east of UTC), so a night
        /// on either side of a DST change keeps its wall-clock reading.
        public init(day: String, bedTs: Int, wakeTs: Int, bedOffsetSec: Int, wakeOffsetSec: Int) {
            self.init(day: day,
                      bedMinute: SleepConsistency.minuteOfDay(ts: bedTs, offsetSec: bedOffsetSec),
                      wakeMinute: SleepConsistency.minuteOfDay(ts: wakeTs, offsetSec: wakeOffsetSec))
        }
    }

    /// Local minute-of-day of `ts` at a UTC offset (seconds east of UTC), in [0, 1440).
    public static func minuteOfDay(ts: Int, offsetSec: Int) -> Double {
        let local = ts + offsetSec
        let secOfDay = ((local % 86_400) + 86_400) % 86_400
        return Double(secOfDay) / 60.0
    }

    /// Shortest distance between two clock minutes around a 24-hour dial, in [0, 720].
    public static func circularDistanceMin(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 1440)
        return min(d, 1440 - d)
    }

    /// Consistency in [0, 1] of a night's bed/wake minutes against `prior` nights (the most recent
    /// `priorNights` are used). nil with fewer than `minPriorNights`.
    public static func score(bedMinute: Double, wakeMinute: Double,
                             prior: [(bedMinute: Double, wakeMinute: Double)]) -> Double? {
        let window = prior.suffix(priorNights)
        guard window.count >= minPriorNights else { return nil }
        let meanDev = window.map {
            (circularDistanceMin(bedMinute, $0.bedMinute) + circularDistanceMin(wakeMinute, $0.wakeMinute)) / 2
        }.reduce(0, +) / Double(window.count)
        let raw = 1 - (meanDev - graceMin) / (zeroAtMin - graceMin)
        return (max(0, min(1, raw)) * 10_000).rounded() / 10_000
    }

    /// Score every night in `nights` against the nights on the `priorNights` calendar days before it.
    /// A duplicated day keeps the last entry. Nights with too few neighbours are absent from the result.
    public static func scores(_ nights: [NightTiming]) -> [String: Double] {
        var byOrdinal: [Int: NightTiming] = [:]
        for n in nights {
            if let o = SleepNeed.ordinal(n.day) { byOrdinal[o] = n }
        }
        var out: [String: Double] = [:]
        for (o, night) in byOrdinal {
            var prior: [(bedMinute: Double, wakeMinute: Double)] = []
            for back in stride(from: priorNights, through: 1, by: -1) {
                if let p = byOrdinal[o - back] { prior.append((p.bedMinute, p.wakeMinute)) }
            }
            if let s = score(bedMinute: night.bedMinute, wakeMinute: night.wakeMinute, prior: prior) {
                out[night.day] = s
            }
        }
        return out
    }
}
