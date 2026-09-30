import Foundation

// DailyStressTrend.swift — the daily autonomic-stress proxy, each day against its OWN trailing baseline.
//
// The Stress screen scored its whole history against TODAY's 30-day baseline: a day from March was
// z-scored against June's resting-HR/HRV mean, so the line bent with whatever the latest month looked
// like and an old day's value changed every time a new day landed. It also used a population SD with no
// minimum sample, so a two-day "baseline" produced confident scores. Here every day is scored against
// the 30 CALENDAR days before it — the same way the headline day always was — with a sample SD and at
// least `minBaselineDays` prior values per signal, and no score at all without one.
//
//   z_RHR = (RHR − mean) / sd          (higher resting HR = more activation)
//   z_HRV = (mean − HRV) / sd          (lower HRV = more activation)
//   score = 3 / (1 + e^−(z_RHR + z_HRV))   on 0–3, 1.5 at baseline
//
// A signal joins only when the day has it and its baseline has enough values; a baseline with no spread
// cannot z-score, so that signal contributes 0 (reads "at baseline"), as the screen always treated it. A
// day with neither signal usable has no score (the caller shows it as missing, never as 1.5).

public enum DailyStressTrend {

    /// Calendar days before a day that form its baseline.
    public static let baselineWindowDays: Int = 30
    /// Fewest prior values a signal's baseline needs before it may score a day.
    public static let minBaselineDays: Int = 7
    /// A baseline spread at or below this (bpm or ms) is treated as no spread: the signal counts but
    /// contributes z = 0.
    public static let minSpread: Double = 0.0001

    /// One day's inputs.
    public struct Day: Equatable, Sendable {
        public let day: String
        public let restingHR: Double?
        public let hrv: Double?
        public init(day: String, restingHR: Double?, hrv: Double?) {
            self.day = day
            self.restingHR = restingHR
            self.hrv = hrv
        }
    }

    /// A day scored against its trailing baseline.
    public struct Score: Equatable, Sendable {
        public let day: String
        /// 0–3 stress proxy (1.5 = at baseline).
        public let score: Double
        /// The day's resting HR minus its baseline mean (bpm); nil when RHR did not score.
        public let rhrDelta: Double?
        /// The day's HRV minus its baseline mean (ms); nil when HRV did not score.
        public let hrvDelta: Double?
    }

    /// Score every day that can be scored. A duplicated day keeps the last entry.
    /// - Complexity: O(days × window).
    public static func scores(_ days: [Day]) -> [String: Score] {
        var byOrdinal: [Int: Day] = [:]
        for d in days {
            if let o = LocalCalendarDate(key: d.day)?.daysSinceEpoch { byOrdinal[o] = d }
        }
        var out: [String: Score] = [:]
        for (o, d) in byOrdinal {
            var priorRHR: [Double] = [], priorHRV: [Double] = []
            for back in 1...baselineWindowDays {
                guard let p = byOrdinal[o - back] else { continue }
                if let r = p.restingHR, r.isFinite { priorRHR.append(r) }
                if let h = p.hrv, h.isFinite { priorHRV.append(h) }
            }
            if let s = score(day: d, priorRHR: priorRHR, priorHRV: priorHRV) { out[d.day] = s }
        }
        return out
    }

    /// Score one day against explicit prior values (its trailing window). nil when neither signal can score.
    public static func score(day d: Day, priorRHR: [Double], priorHRV: [Double]) -> Score? {
        var raw = 0.0
        var rhrDelta: Double?
        var hrvDelta: Double?
        if let r = d.restingHR, r.isFinite, let b = baseline(priorRHR) {
            if b.sd > minSpread { raw += (r - b.mean) / b.sd }
            rhrDelta = r - b.mean
        }
        if let h = d.hrv, h.isFinite, let b = baseline(priorHRV) {
            if b.sd > minSpread { raw += (b.mean - h) / b.sd }
            hrvDelta = h - b.mean
        }
        guard rhrDelta != nil || hrvDelta != nil else { return nil }
        return Score(day: d.day, score: squash(raw), rhrDelta: rhrDelta, hrvDelta: hrvDelta)
    }

    /// Logistic map of a z-sum onto 0–3 (0 → 1.5).
    public static func squash(_ raw: Double) -> Double {
        min(max(3.0 / (1.0 + exp(-raw)), 0), 3)
    }

    /// Mean and sample SD of a baseline, or nil when it has fewer than `minBaselineDays` values.
    static func baseline(_ xs: [Double]) -> (mean: Double, sd: Double)? {
        guard xs.count >= minBaselineDays else { return nil }
        let m = xs.reduce(0, +) / Double(xs.count)
        let sd = (xs.reduce(0) { $0 + ($1 - m) * ($1 - m) } / Double(xs.count - 1)).squareRoot()
        return (m, sd)
    }
}
