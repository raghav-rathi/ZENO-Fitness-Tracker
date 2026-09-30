import Foundation
import WhoopStore
import StrandAnalytics

// SleepFigures.swift — the persisted form of the unified sleep figures, and the ONE per-night read.
//
// IntelligenceEngine resolves every scored night through `RestResolution` (SleepNeed + SleepConsistency)
// and stores the result under the computed ("-noop") source with the keys below. Screens never re-derive
// a night's Rest, need or consistency: they read these through `Repository.resolvedNightSleep`, which is
// the same precedence `exploreSeries` gives the Today hero, the widgets and the watch (a WHOOP export's
// own figure wins its day, then NOOP's stored value, then the daily-column fallback). So the Today hero,
// the Sleep tab, the stored series and Charge's sleep term cannot show two numbers for one night.

/// Metric-series keys the engine writes for the unified sleep figures. The per-night keys reuse the names
/// a WHOOP export already writes under the imported source (`sleep_need_min`, `sleep_consistency`,
/// `sleep_debt_min`, `hours_vs_needed_pct`), so the Explore catalog's existing entries resolve them the
/// same imported-wins way as `sleep_performance`.
enum SleepFigureKeys {
    static let rest = "sleep_performance"
    static let need = "sleep_need_min"
    static let needBaseline = "sleep_need_baseline_min"
    static let needStrain = "sleep_need_strain_min"
    /// The debt component of the night's need: what earlier nights carried INTO it.
    static let needDebt = "sleep_need_debt_min"
    static let needNapCredit = "sleep_need_nap_min"
    /// The debt the night LEFT (the ledger balance through it), so the newest value is the debt owed
    /// tonight — the number the debt card headlines. Same key the local Sleep Debt tile series used.
    static let debtAfter = "sleep_debt_min"
    /// Stored as a percentage (0–100), the unit the WHOOP export uses for the same key.
    static let consistency = "sleep_consistency"
    static let hoursVsNeeded = "hours_vs_needed_pct"

    /// The upcoming night's need, stored on the pass's newest day (the day whose evening it plans).
    static let tonightNeed = "sleep_need_tonight_min"
    static let tonightBaseline = "sleep_need_tonight_baseline_min"
    static let tonightStrain = "sleep_need_tonight_strain_min"
    static let tonightDebt = "sleep_need_tonight_debt_min"
    static let tonightNapCredit = "sleep_need_tonight_nap_min"

    /// Every key above, for the dashboard's one-query read.
    static let all: [String] = [rest, need, needBaseline, needStrain, needDebt, needNapCredit, debtAfter,
                                consistency, hoursVsNeeded, tonightNeed, tonightBaseline, tonightStrain,
                                tonightDebt, tonightNapCredit]

    /// Keys a re-score deletes across its window before writing, because a night can lose them while
    /// keeping its Rest (consistency needs neighbouring nights; the tonight figures move to a new day).
    static let replacedOnRescore: [String] = [consistency, tonightNeed, tonightBaseline, tonightStrain,
                                              tonightDebt, tonightNapCredit]

    /// The points one resolved night persists.
    static func nightPoints(_ f: RestNightFigures) -> [MetricPoint] {
        var points: [MetricPoint] = []
        if let rest = f.rest { points.append(MetricPoint(day: f.day, key: Self.rest, value: rest)) }
        points.append(MetricPoint(day: f.day, key: need, value: f.need.totalMin))
        points.append(MetricPoint(day: f.day, key: needBaseline, value: f.need.baselineMin))
        points.append(MetricPoint(day: f.day, key: needStrain, value: f.need.strainMin))
        points.append(MetricPoint(day: f.day, key: needDebt, value: f.need.debtMin))
        points.append(MetricPoint(day: f.day, key: needNapCredit, value: f.need.napCreditMin))
        if let d = f.debtAfterMin { points.append(MetricPoint(day: f.day, key: debtAfter, value: d)) }
        if let c = f.consistency {
            points.append(MetricPoint(day: f.day, key: consistency, value: (c * 10_000).rounded() / 100))
        }
        if let h = f.hoursVsNeededPct { points.append(MetricPoint(day: f.day, key: hoursVsNeeded, value: h)) }
        return points
    }

    /// The points that store the upcoming night's need on `day`.
    static func tonightPoints(day: String, _ n: SleepNeedBreakdown) -> [MetricPoint] {
        [MetricPoint(day: day, key: tonightNeed, value: n.totalMin),
         MetricPoint(day: day, key: tonightBaseline, value: n.baselineMin),
         MetricPoint(day: day, key: tonightStrain, value: n.strainMin),
         MetricPoint(day: day, key: tonightDebt, value: n.debtMin),
         MetricPoint(day: day, key: tonightNapCredit, value: n.napCreditMin)]
    }

    /// Fold stored points (any order, one source) into per-day figures.
    static func figures(from points: [MetricPoint]) -> [String: ComputedSleepFigures] {
        var out: [String: ComputedSleepFigures] = [:]
        for p in points {
            var f = out[p.day] ?? ComputedSleepFigures()
            switch p.key {
            case rest: f.restScore = p.value
            case need: f.needMin = p.value
            case needBaseline: f.needBaselineMin = p.value
            case needStrain: f.needStrainMin = p.value
            case needDebt: f.needDebtMin = p.value
            case needNapCredit: f.needNapCreditMin = p.value
            case debtAfter: f.debtAfterMin = p.value
            case consistency: f.consistencyPct = p.value
            case hoursVsNeeded: f.hoursVsNeededPct = p.value
            case tonightNeed: f.tonightNeedMin = p.value
            case tonightBaseline: f.tonightBaselineMin = p.value
            case tonightStrain: f.tonightStrainMin = p.value
            case tonightDebt: f.tonightDebtMin = p.value
            case tonightNapCredit: f.tonightNapCreditMin = p.value
            default: continue
            }
            out[p.day] = f
        }
        return out
    }
}

/// Per-day sleep figures the engine computed and persisted under the "-noop" source (the counterpart of
/// `ImportedSleepFigures`, which holds what a WHOOP export carried).
struct ComputedSleepFigures: Equatable {
    var restScore: Double?
    var needMin: Double?
    var needBaselineMin: Double?
    var needStrainMin: Double?
    var needDebtMin: Double?
    var needNapCreditMin: Double?
    var debtAfterMin: Double?
    var consistencyPct: Double?
    var hoursVsNeededPct: Double?
    var tonightNeedMin: Double?
    var tonightBaselineMin: Double?
    var tonightStrainMin: Double?
    var tonightDebtMin: Double?
    var tonightNapCreditMin: Double?

    /// The stored need breakdown for this night, when every component was stored.
    var needBreakdown: SleepNeedBreakdown? {
        guard let total = needMin, let base = needBaselineMin, let strain = needStrainMin,
              let debt = needDebtMin, let nap = needNapCreditMin else { return nil }
        return SleepNeedBreakdown(baselineMin: base, strainMin: strain, debtMin: debt, napCreditMin: nap,
                                  totalMin: total)
    }

    /// The need stored for the night that follows this day, when every component was stored.
    var tonightBreakdown: SleepNeedBreakdown? {
        guard let total = tonightNeedMin, let base = tonightBaselineMin, let strain = tonightStrainMin,
              let debt = tonightDebtMin, let nap = tonightNapCreditMin else { return nil }
        return SleepNeedBreakdown(baselineMin: base, strainMin: strain, debtMin: debt, napCreditMin: nap,
                                  totalMin: total)
    }
}

/// Everything a screen shows about one night's sleep score, resolved once.
struct ResolvedNightSleep: Equatable {
    let day: String
    /// The Rest (0–100): the WHOOP export's sleep performance for an imported night, else NOOP's.
    let restScore: Double?
    /// The need the night was measured against (minutes).
    let needMin: Double?
    /// NOOP's breakdown of that need. nil for an imported need: an export carries only the total.
    let needBreakdown: SleepNeedBreakdown?
    /// Timing consistency, 0–100.
    let consistencyPct: Double?
    /// Asleep ÷ need × 100.
    let hoursVsNeededPct: Double?
    /// Sleep debt for the night: the export's own figure for an imported night, else the debt NOOP's
    /// ledger was left with after it.
    let debtMin: Double?
    /// True when `restScore` is the export's own figure rather than NOOP's.
    let restIsImported: Bool
}

extension Repository {

    /// THE per-night sleep read (pure form). Precedence per field: the WHOOP export's figure, then NOOP's
    /// stored figure, then — for Rest only — the daily-column fallback `exploreSeries` also uses for a
    /// night the engine has not scored yet. A need and a consistency are never re-derived here; a night
    /// without a stored one shows none rather than a second definition.
    nonisolated static func resolvedNightSleep(day: String, daily: DailyMetric?,
                                               imported: [String: ImportedSleepFigures],
                                               computed: [String: ComputedSleepFigures]) -> ResolvedNightSleep {
        let imp = imported[day]
        let comp = computed[day]
        let importedRest = imp?.performancePct
        let rest = importedRest ?? comp?.restScore ?? daily.flatMap { dailyColumn(key: "sleep_performance", day: $0) }
        let importedNeed = imp?.needMin.flatMap { $0 > 0 ? $0 : nil }
        let need = importedNeed ?? comp?.needMin
        let hoursVsNeeded: Double?
        if let importedNeed {
            hoursVsNeeded = AnalyticsEngine.Rest.hoursVsNeededPct(sleptMin: daily?.totalSleepMin, needMin: importedNeed)
        } else {
            hoursVsNeeded = comp?.hoursVsNeededPct
                ?? AnalyticsEngine.Rest.hoursVsNeededPct(sleptMin: daily?.totalSleepMin, needMin: comp?.needMin)
        }
        return ResolvedNightSleep(
            day: day, restScore: rest, needMin: need,
            needBreakdown: importedNeed == nil ? comp?.needBreakdown : nil,
            consistencyPct: imp?.consistencyPct ?? comp?.consistencyPct,
            hoursVsNeededPct: hoursVsNeeded,
            debtMin: imp?.debtMin ?? comp?.debtAfterMin,
            restIsImported: importedRest != nil)
    }

    /// THE per-night sleep read for `day` over the published caches.
    func resolvedNightSleep(day: String) -> ResolvedNightSleep {
        Self.resolvedNightSleep(day: day, daily: days.last(where: { $0.day == day }),
                                imported: importedSleep, computed: computedSleep)
    }

    /// The Rest (0–100) for `day` — `resolvedNightSleep(day:).restScore`.
    func restScore(forDay day: String) -> Double? {
        resolvedNightSleep(day: day).restScore
    }

    /// The need for the night that follows `now`'s local day, with its breakdown. The engine stores it on
    /// its newest day each pass; a store without it (no strap-scored pass today, e.g. an import-only
    /// install) resolves the same model over the merged history, with no nap credit because naps are
    /// not in the daily rows.
    func sleepNeedTonight(now: Date = Date(), age: Int? = nil) -> SleepNeedBreakdown {
        let todayKey = Self.localDayKey(now)
        if let stored = computedSleep[todayKey]?.tonightBreakdown { return stored }
        // The model looks back at most 60 usable nights (baseline), 28 days (typical Effort) and 14 nights
        // (debt), so the last 120 days cover everything it reads unless the history is gappy — at a bounded
        // cost, because this can be reached from a view body.
        let history = days.suffix(120).map {
            SleepNeedDay(day: $0.day, mainSleepMin: $0.totalSleepMin, effort: $0.strain)
        }
        return SleepNeed.timeline(days: history, age: age, tonightAfter: todayKey).tonight
    }
}

/// Builds the engine's `RestResolution` inputs from daily rows and sleep blocks. Pure, so the day grouping
/// and main-night/nap split can be tested without a store.
enum SleepNeedInputs {

    /// The main night's displayed bed and wake instants, and the asleep minutes of every block outside the
    /// main-night group, for one wake day's blocks. Uses the Sleep tab's own selectors (the bridged
    /// main-night group, its displayed onset, its nap credit) so the timing and naps the need is built
    /// from are the ones the Sleep tab draws. nil when the day has no main night.
    static func dayShape(_ blocks: [CachedSleepSession],
                         habitualMidsleepSec: Int?) -> (bedTs: Int, wakeTs: Int, napMin: Double)? {
        let group = SleepView.mainNightGroup(blocks, habitualMidsleepSec: habitualMidsleepSec)
        guard let last = group.last else { return nil }
        // A one-block night's displayed onset is its own start; only a fragmented night needs the stage
        // decode that skips a leading pre-onset awake stub (a full-history pass would otherwise decode
        // every night's stage JSON just to learn nothing).
        let bed = group.count == 1 ? last.effectiveStartTs : SleepModel.nightOnsetTs(group)
        guard last.endTs > bed else { return nil }
        return (bed, last.endTs, SleepView.napSleepMinutes(blocks, habitualMidsleepSec: habitualMidsleepSec))
    }

    /// Resolve Rest inputs for a merged daily history and its sleep blocks grouped by wake-day key.
    /// `offsetAt` returns the UTC offset (seconds east) in force at an instant, so a night keeps its
    /// wall-clock timing across a DST change.
    static func resolution(history: [DailyMetric], blocksByDay: [String: [CachedSleepSession]],
                           habitualMidsleepSec: Int?, age: Int?, tonightAfter: String?,
                           offsetAt: (Int) -> Int) -> RestResolution {
        var needDays: [SleepNeedDay] = []
        needDays.reserveCapacity(history.count)
        var timings: [SleepConsistency.NightTiming] = []
        var shapes: [String: (bedTs: Int, wakeTs: Int, napMin: Double)] = [:]
        for (day, blocks) in blocksByDay {
            if let shape = dayShape(blocks, habitualMidsleepSec: habitualMidsleepSec) { shapes[day] = shape }
        }
        var seen = Set<String>()
        for d in history {
            seen.insert(d.day)
            needDays.append(SleepNeedDay(day: d.day, mainSleepMin: d.totalSleepMin,
                                         napSleepMin: shapes[d.day]?.napMin ?? 0, effort: d.strain))
        }
        // A day with blocks but no daily row still contributes its naps to the night after it.
        for (day, shape) in shapes where !seen.contains(day) && shape.napMin > 0 {
            needDays.append(SleepNeedDay(day: day, mainSleepMin: nil, napSleepMin: shape.napMin, effort: nil))
        }
        for (day, shape) in shapes {
            timings.append(SleepConsistency.NightTiming(day: day, bedTs: shape.bedTs, wakeTs: shape.wakeTs,
                                                        bedOffsetSec: offsetAt(shape.bedTs),
                                                        wakeOffsetSec: offsetAt(shape.wakeTs)))
        }
        return RestResolution(history: needDays, timings: timings, age: age, tonightAfter: tonightAfter)
    }
}
