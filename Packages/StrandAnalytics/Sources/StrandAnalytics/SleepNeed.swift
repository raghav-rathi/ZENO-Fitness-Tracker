import Foundation

// SleepNeed.swift — the ONE sleep-need model every Rest, debt, "hours vs needed" and planner surface reads.
//
// There used to be four definitions of the same fact: Rest scored every night against a flat 8 h, the
// "hours vs needed" tile against max(7.5 h, mean), the debt ledger against the upper-quartile
// `personalizedNeedHours`, and the wind-down nudge against a stored 8 h. None carried a strain term, so one
// screen could call a night "enough" while another counted it as debt. This is the replacement, shaped the
// way WHOOP describes its own Sleep Need:
//
//   need(night) = baseline + strain + debt − naps        (never below half the baseline)
//
//   baseline  `Rest.personalizedNeedHours` (upper quartile, age-floored, capped) over the usable nights
//             BEFORE this one, at most `baselineWindowNights` of them. Trailing, so a night's need is the
//             same number whenever it is recomputed and never moves when later nights land.
//   strain    extra need after a harder-than-usual day: 0…`maxStrainExtraMin` minutes, linear in how far
//             the day's Effort ran above the person's TYPICAL Effort (median of the 28 days before it,
//             needing 7 of them). A documented heuristic, not a measured constant — WHOOP says a strain
//             term exists, not how big it is. A below-typical day adds nothing and never subtracts.
//   debt      the `SleepDebt` recurrence (55 % of each night's shortfall carries, under 10 min clears,
//             14-night window), run over these same per-night needs, so the debt component IS the ledger.
//   naps      asleep minutes napped on the day before the night. They reduce the NEXT night's need and are
//             NOT also credited as slept time in the debt recurrence: counting them in both places would
//             repay the same minutes twice.
//
// Day keys are the app's wake-day keys: the night that ENDS on day D is "night D". Its strain and nap
// inputs come from calendar day D−1, the day that precedes it. All values are minutes, rounded to 0.1.

/// One night's sleep need and where it came from. `baselineMin + strainMin + debtMin − napCreditMin`
/// equals `totalMin` (to rounding), so a UI can draw the breakdown without re-deriving anything.
public struct SleepNeedBreakdown: Equatable, Sendable {
    /// The personal baseline (upper-quartile nightly sleep, age-floored and capped).
    public let baselineMin: Double
    /// Extra need from a harder-than-usual previous day (0…`SleepNeed.maxStrainExtraMin`).
    public let strainMin: Double
    /// Sleep debt carried into the night by the ledger recurrence.
    public let debtMin: Double
    /// Nap minutes actually credited against the need. Can be less than the naps taken when the
    /// half-baseline floor binds.
    public let napCreditMin: Double
    /// The need itself: baseline + strain + debt − nap credit.
    public let totalMin: Double

    public init(baselineMin: Double, strainMin: Double, debtMin: Double, napCreditMin: Double,
                totalMin: Double) {
        self.baselineMin = baselineMin
        self.strainMin = strainMin
        self.debtMin = debtMin
        self.napCreditMin = napCreditMin
        self.totalMin = totalMin
    }

    /// The need in hours, the unit `Rest.composite` takes.
    public var totalHours: Double { totalMin / 60.0 }
}

/// One calendar day of input to the need model, keyed by the app's wake-day key.
public struct SleepNeedDay: Equatable, Sendable {
    /// "yyyy-MM-dd" wake-day key.
    public let day: String
    /// Asleep minutes of the MAIN night that ended on `day`; nil or ≤ 0 means no usable night.
    public let mainSleepMin: Double?
    /// Asleep minutes of naps on `day` (blocks outside its main-night group).
    public let napSleepMin: Double
    /// The day's Effort on NOOP's 0–100 axis, or nil when the day was not scored.
    public let effort: Double?

    public init(day: String, mainSleepMin: Double?, napSleepMin: Double = 0, effort: Double? = nil) {
        self.day = day
        self.mainSleepMin = mainSleepMin
        self.napSleepMin = napSleepMin
        self.effort = effort
    }
}

/// The resolved need for every night in a history, plus the upcoming night and the debt ledger.
public struct SleepNeedTimeline: Equatable, Sendable {
    /// The need that applied to each usable night, keyed by that night's wake day.
    public let nights: [String: SleepNeedBreakdown]
    /// The debt each usable night LEFT (the ledger balance through that night, as a positive magnitude) —
    /// what it carried into the next night's need. For the newest night this equals `tonight.debtMin`.
    public let debtAfter: [String: Double]
    /// The need for the NEXT night: the one that follows `tonightAfterDay`.
    public let tonight: SleepNeedBreakdown
    /// The day whose evening `tonight` plans for (the night itself ends the day after). nil only for an
    /// empty history with no explicit plan day.
    public let tonightAfterDay: String?
    /// The most recent usable nights up to `tonightAfterDay` in the existing ledger shape: `balanceMin` is
    /// minus tonight's debt component, each night's `deltaMin` is slept minus that night's baseline, and
    /// `needMin` is tonight's baseline.
    public let ledger: SleepDebtLedger

    public init(nights: [String: SleepNeedBreakdown], debtAfter: [String: Double] = [:],
                tonight: SleepNeedBreakdown, tonightAfterDay: String?, ledger: SleepDebtLedger) {
        self.nights = nights
        self.debtAfter = debtAfter
        self.tonight = tonight
        self.tonightAfterDay = tonightAfterDay
        self.ledger = ledger
    }

    /// The need that applied to the night ending on `day`, or nil when that night had no usable sleep.
    public func need(forNightEnding day: String) -> SleepNeedBreakdown? { nights[day] }
}

public enum SleepNeed {

    // MARK: Tunables (named so every threshold is auditable)

    /// The most a hard day can add to the next night's need.
    public static let maxStrainExtraMin: Double = 60
    /// Effort points above typical at which the strain term reaches its maximum. 25 points on NOOP's
    /// 0–100 axis is about +5 on WHOOP's 0–21 Strain axis: a clearly big day, not an ordinary workout.
    public static let strainFullScaleExcess: Double = 25
    /// Days of Effort history the "typical" day is the median of.
    public static let typicalEffortWindowDays: Int = 28
    /// Fewest scored days before a typical Effort exists (and so before any strain term applies).
    public static let minTypicalEffortDays: Int = 7
    /// Usable nights the baseline is estimated over.
    public static let baselineWindowNights: Int = 60
    /// Naps can lower a night's need to this fraction of the baseline and no further: a very long daytime
    /// block is more often a misfiled main sleep than a genuine halving of need.
    public static let minNeedFractionOfBaseline: Double = 0.5
    /// Minutes between getting into bed and falling asleep for a healthy adult (clinical norm 10–20).
    public static let typicalSleepLatencyMin: Double = 15

    // MARK: Components

    /// Extra need (minutes) after a day with `effort`, against the person's `typicalEffort`. Zero when
    /// either is unknown or the day was at or below typical; otherwise linear up to the cap.
    public static func strainAdjustmentMin(effort: Double?, typicalEffort: Double?) -> Double {
        guard let effort, let typicalEffort, effort.isFinite, typicalEffort.isFinite else { return 0 }
        let excess = effort - typicalEffort
        guard excess > 0 else { return 0 }
        return round1(maxStrainExtraMin * min(1.0, excess / strainFullScaleExcess))
    }

    /// The typical Effort: the median of `efforts`, or nil below `minTypicalEffortDays` values. A median
    /// rather than a mean so one race day does not move what "normal" means.
    public static func typicalEffort(_ efforts: [Double]) -> Double? {
        let xs = efforts.filter { $0.isFinite && $0 >= 0 }.sorted()
        guard xs.count >= minTypicalEffortDays else { return nil }
        let mid = xs.count / 2
        return xs.count % 2 == 1 ? xs[mid] : (xs[mid - 1] + xs[mid]) / 2
    }

    /// The baseline need (minutes) from the usable nights before the one being planned, oldest first.
    /// Only the most recent `baselineWindowNights` count; under `Rest.minNeedNights` of them this is the
    /// population default, exactly as `Rest.personalizedNeedHours` rules.
    public static func baselineMin(priorNightlyMin: [Double], age: Int?) -> Double {
        let recent = priorNightlyMin.filter { $0 > 0 }.suffix(baselineWindowNights)
        let hours = AnalyticsEngine.Rest.personalizedNeedHours(nightlyHours: recent.map { $0 / 60.0 },
                                                               age: age)
        return round1(hours * 60.0)
    }

    /// Put the four components together, applying the nap floor. Negative inputs are treated as zero.
    public static func compose(baselineMin: Double, strainMin: Double, debtMin: Double,
                               napMin: Double) -> SleepNeedBreakdown {
        let base = round1(max(baselineMin, 0))
        let strain = round1(max(strainMin, 0))
        let debt = round1(max(debtMin, 0))
        let credit = round1(napCredit(base: base, gross: base + strain + debt, nap: round1(max(napMin, 0))))
        return SleepNeedBreakdown(baselineMin: base, strainMin: strain, debtMin: debt,
                                  napCreditMin: credit, totalMin: round1(base + strain + debt - credit))
    }

    /// The nap minutes that may come off `gross` without taking it below the half-baseline floor.
    static func napCredit(base: Double, gross: Double, nap: Double) -> Double {
        min(max(nap, 0), max(0, gross - max(base, 0) * minNeedFractionOfBaseline))
    }

    /// The need total the debt recurrence runs on — `compose` without its display rounding, so the ledger
    /// arithmetic is exactly `SleepDebt.ledger`'s when there is no strain or nap.
    static func unroundedTotal(base: Double, strain: Double, debt: Double, nap: Double) -> Double {
        let gross = max(base, 0) + max(strain, 0) + max(debt, 0)
        return gross - napCredit(base: base, gross: gross, nap: nap)
    }

    /// The debt a night leaves behind: `SleepDebt.debtCarryFactor` of the part of its need that was not
    /// slept, cleared when it is below `SleepDebt.minimumDebtMin`. `needMin` already includes the debt
    /// that was carried INTO the night, which is what makes this the ledger's own recurrence.
    public static func debtCarry(needMin: Double, sleptMin: Double) -> Double {
        let carry = SleepDebt.debtCarryFactor * max(0, needMin - sleptMin)
        return carry < SleepDebt.minimumDebtMin ? 0 : carry
    }

    // MARK: Timeline

    /// Resolve the need of every usable night in `days`, plus the upcoming night.
    ///
    /// - Parameters:
    ///   - days: per-day inputs in any order; a duplicated day keeps the last row. Days without a usable
    ///     main night still supply their Effort and naps to the night that follows them.
    ///   - age: the person's age, for the baseline's population floor (nil → adult).
    ///   - tonightAfter: the day whose evening to plan for. nil → the newest day in `days`. Nights after
    ///     it are ignored for `tonight` and the ledger (they are still resolved in `nights`).
    ///   - ledgerWindow: usable nights the debt recurrence looks back over.
    /// - Complexity: O(n · (window + log window)) — every night's debt is recomputed from its own
    ///   trailing window, the same way `SleepDebt.debtSeries` does, so no night depends on how far back
    ///   the history happened to start.
    public static func timeline(days: [SleepNeedDay], age: Int?, tonightAfter: String? = nil,
                                ledgerWindow: Int = SleepDebt.defaultWindowNights) -> SleepNeedTimeline {
        var byOrdinal: [Int: SleepNeedDay] = [:]
        for d in days {
            if let o = ordinal(d.day) { byOrdinal[o] = d }
        }
        let ordinals = byOrdinal.keys.sorted()
        let window = max(ledgerWindow, 1)

        struct NightInput {
            let ordinal: Int
            let day: String
            let sleptMin: Double
            let baselineMin: Double
            let strainMin: Double
            let napMin: Double
        }

        // The evening before a night: its strain and the naps taken during it.
        func evening(_ o: Int) -> (strain: Double, nap: Double) {
            let row = byOrdinal[o]
            var prior: [Double] = []
            prior.reserveCapacity(typicalEffortWindowDays)
            for back in 1...typicalEffortWindowDays {
                if let e = byOrdinal[o - back]?.effort { prior.append(e) }
            }
            let strain = strainAdjustmentMin(effort: row?.effort, typicalEffort: typicalEffort(prior))
            return (strain, max(row?.napSleepMin ?? 0, 0))
        }

        var nights: [NightInput] = []
        var sleptSoFar: [Double] = []
        for o in ordinals {
            guard let row = byOrdinal[o], let slept = row.mainSleepMin, slept > 0 else { continue }
            let ev = evening(o - 1)
            nights.append(NightInput(ordinal: o, day: row.day, sleptMin: slept,
                                     baselineMin: baselineMin(priorNightlyMin: sleptSoFar, age: age),
                                     strainMin: ev.strain, napMin: ev.nap))
            sleptSoFar.append(slept)
        }

        // Debt carried into the night at index `end`, from the recurrence over the usable nights before it.
        func debtInto(_ end: Int) -> Double {
            var running = 0.0
            var k = max(0, end - window)
            while k < end {
                let n = nights[k]
                let need = unroundedTotal(base: n.baselineMin, strain: n.strainMin, debt: running, nap: n.napMin)
                running = debtCarry(needMin: need, sleptMin: n.sleptMin)
                k += 1
            }
            return running
        }

        var resolved: [String: SleepNeedBreakdown] = [:]
        var debtAfter: [String: Double] = [:]
        for i in nights.indices {
            let n = nights[i]
            resolved[n.day] = compose(baselineMin: n.baselineMin, strainMin: n.strainMin,
                                      debtMin: debtInto(i), napMin: n.napMin)
            debtAfter[n.day] = round1(debtInto(i + 1))
        }

        let planOrdinal = tonightAfter.flatMap(ordinal) ?? ordinals.last
        let done = planOrdinal.map { p in nights.firstIndex { $0.ordinal > p } ?? nights.count } ?? nights.count
        let tonightEvening = planOrdinal.map(evening) ?? (strain: 0, nap: 0)
        let tonight = compose(baselineMin: baselineMin(priorNightlyMin: nights[..<done].map(\.sleptMin), age: age),
                              strainMin: tonightEvening.strain, debtMin: debtInto(done),
                              napMin: tonightEvening.nap)
        let ledgerNights = nights[max(0, done - window)..<done].map {
            SleepDebtNight(day: $0.day, sleptMin: $0.sleptMin, deltaMin: round1($0.sleptMin - $0.baselineMin))
        }
        let ledger = SleepDebtLedger(balanceMin: -tonight.debtMin, nights: ledgerNights,
                                     needMin: tonight.baselineMin)
        return SleepNeedTimeline(nights: resolved, debtAfter: debtAfter, tonight: tonight,
                                 tonightAfterDay: planOrdinal.map { LocalCalendarDate(daysSinceEpoch: $0).key },
                                 ledger: ledger)
    }

    // MARK: Bedtime

    /// The latest time to be in bed to sleep `needMin × needFraction` before `wakeTs`, allowing
    /// `latencyMin` to fall asleep. `needFraction` lets a planner offer 100 % / 85 % / 70 % of need.
    public static func suggestedBedtime(wakeTs: Int, needMin: Double, needFraction: Double = 1.0,
                                        latencyMin: Double = typicalSleepLatencyMin) -> Int {
        let minutes = max(needMin, 0) * max(needFraction, 0) + max(latencyMin, 0)
        return wakeTs - Int((minutes * 60.0).rounded())
    }

    /// `Date` form of `suggestedBedtime(wakeTs:needMin:needFraction:latencyMin:)`.
    public static func suggestedBedtime(wake: Date, needMin: Double, needFraction: Double = 1.0,
                                        latencyMin: Double = typicalSleepLatencyMin) -> Date {
        let ts = suggestedBedtime(wakeTs: Int(wake.timeIntervalSince1970.rounded()), needMin: needMin,
                                  needFraction: needFraction, latencyMin: latencyMin)
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    // MARK: Trace

    /// One Sleep & Rest test-mode line naming what a stored Rest was scored against, so a Rest that reads
    /// low can be traced to its need components and consistency from an export. PURE.
    public static func traceLine(day: String, need: SleepNeedBreakdown, consistency: Double?,
                                 rest: Double?) -> String {
        func r1(_ x: Double) -> String { String(format: "%.1f", x) }
        let cons = consistency.map { String(format: "%.2f", $0) } ?? "nil"
        let score = rest.map { String(format: "%.2f", $0) } ?? "nil"
        return "rest stored day=\(day) composite=\(score) needMin=\(r1(need.totalMin)) "
            + "baseline=\(r1(need.baselineMin)) strain=\(r1(need.strainMin)) debt=\(r1(need.debtMin)) "
            + "napCredit=\(r1(need.napCreditMin)) consistency=\(cons)"
    }

    // MARK: Helpers

    /// Days since 1970-01-01 for a strict "yyyy-MM-dd" key, or nil when it does not parse. Timezone-free
    /// integer arithmetic, so neighbouring days are one apart across DST changes.
    static func ordinal(_ key: String) -> Int? {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              (1...12).contains(m), (1...31).contains(d) else { return nil }
        return LocalCalendarDate(year: y, month: m, day: d).daysSinceEpoch
    }

    static func round1(_ v: Double) -> Double { (v * 10.0).rounded() / 10.0 }
}
