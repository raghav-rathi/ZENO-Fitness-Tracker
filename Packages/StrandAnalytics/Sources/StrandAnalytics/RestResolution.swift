import Foundation
import WhoopStore

// RestResolution.swift — the ONE place a night's Rest inputs are decided.
//
// Every stored `sleep_performance` used to come from `Rest.composite(daily:)` with its defaults (an 8 h
// need and a neutral 0.5 consistency), so Rest ignored the person's need and could never pass 95, while
// the pass-1 composite that DID personalise both was computed and thrown away. This bundles the unified
// need (`SleepNeed`) and timing consistency (`SleepConsistency`) for a history, and scores any night from
// them, so the stored series, Charge's sleep term and every screen read one number for one night.

extension AnalyticsEngine.Rest {
    /// The Rest composite for a persisted night scored against a resolved need and consistency — the form
    /// every stored and displayed Rest goes through. nil when the night has no asleep time or efficiency.
    public static func composite(daily d: DailyMetric, need: SleepNeedBreakdown?,
                                 consistency: Double?) -> Double? {
        composite(daily: d, needHours: need?.totalHours ?? defaultNeedHours, consistency: consistency)
    }

    /// Asleep minutes as a percentage of need (not clamped: 110 means ten percent over). nil without both.
    public static func hoursVsNeededPct(sleptMin: Double?, needMin: Double?) -> Double? {
        guard let sleptMin, sleptMin > 0, let needMin, needMin > 0 else { return nil }
        return (sleptMin / needMin * 1000).rounded() / 10
    }
}

/// One night's resolved sleep figures: the need it was scored against, its timing consistency, and the
/// Rest that follows from them.
public struct RestNightFigures: Equatable, Sendable {
    public let day: String
    public let need: SleepNeedBreakdown
    /// Timing consistency in [0, 1], or nil (Rest then uses its neutral term).
    public let consistency: Double?
    /// The Rest composite (0–100), or nil when the night has no asleep time / efficiency.
    public let rest: Double?
    /// Asleep ÷ need × 100.
    public let hoursVsNeededPct: Double?

    public init(day: String, need: SleepNeedBreakdown, consistency: Double?, rest: Double?,
                hoursVsNeededPct: Double?) {
        self.day = day
        self.need = need
        self.consistency = consistency
        self.rest = rest
        self.hoursVsNeededPct = hoursVsNeededPct
    }
}

/// The need timeline and consistency scores for one history, computed once and read per night.
public struct RestResolution: Equatable, Sendable {
    public let timeline: SleepNeedTimeline
    /// Consistency in [0, 1] per wake-day key; absent when the night had too few neighbours.
    public let consistency: [String: Double]
    /// Usable nights (ordinal, asleep minutes), oldest first — the fallback baseline source for a night
    /// that was not itself in the history.
    private let usableNights: [(ordinal: Int, sleptMin: Double)]
    private let age: Int?

    /// Resolve `history` (need inputs) and `timings` (bed/wake clock minutes) together.
    public init(history: [SleepNeedDay], timings: [SleepConsistency.NightTiming], age: Int?,
                tonightAfter: String? = nil) {
        self.timeline = SleepNeed.timeline(days: history, age: age, tonightAfter: tonightAfter)
        self.consistency = SleepConsistency.scores(timings)
        self.age = age
        var byOrdinal: [Int: Double] = [:]
        for d in history {
            guard let o = SleepNeed.ordinal(d.day), let slept = d.mainSleepMin, slept > 0 else { continue }
            byOrdinal[o] = slept
        }
        self.usableNights = byOrdinal.keys.sorted().map { ($0, byOrdinal[$0]!) }
    }

    /// The need for the night ending on `day`. A night the history resolved gets its full breakdown; any
    /// other night (one that was not in the history) gets the baseline its prior nights imply, with no
    /// strain, debt or nap terms, rather than a population default.
    public func need(forNightEnding day: String) -> SleepNeedBreakdown {
        if let resolved = timeline.nights[day] { return resolved }
        let cutoff = SleepNeed.ordinal(day) ?? Int.max
        let prior = usableNights.filter { $0.ordinal < cutoff }.map(\.sleptMin)
        return SleepNeed.compose(baselineMin: SleepNeed.baselineMin(priorNightlyMin: prior, age: age),
                                 strainMin: 0, debtMin: 0, napMin: 0)
    }

    /// Everything stored for `daily`'s night.
    public func figures(for daily: DailyMetric) -> RestNightFigures {
        let need = need(forNightEnding: daily.day)
        let cons = consistency[daily.day]
        return RestNightFigures(
            day: daily.day, need: need, consistency: cons,
            rest: AnalyticsEngine.Rest.composite(daily: daily, need: need, consistency: cons),
            hoursVsNeededPct: AnalyticsEngine.Rest.hoursVsNeededPct(sleptMin: daily.totalSleepMin,
                                                                    needMin: need.totalMin))
    }

    public static func == (lhs: RestResolution, rhs: RestResolution) -> Bool {
        lhs.timeline == rhs.timeline && lhs.consistency == rhs.consistency && lhs.age == rhs.age
            && lhs.usableNights.map(\.ordinal) == rhs.usableNights.map(\.ordinal)
            && lhs.usableNights.map(\.sleptMin) == rhs.usableNights.map(\.sleptMin)
    }
}
