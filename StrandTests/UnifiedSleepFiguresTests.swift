import XCTest
import WhoopStore
import StrandAnalytics
@testable import Strand

/// The persisted unified sleep figures and the ONE per-night read every screen goes through.
final class UnifiedSleepFiguresTests: XCTestCase {

    private func daily(_ day: String, tst: Double?, eff: Double? = 0.9, strain: Double? = nil) -> DailyMetric {
        DailyMetric(day: day, totalSleepMin: tst, efficiency: eff, deepMin: tst.map { $0 * 0.2 },
                    remMin: tst.map { $0 * 0.25 }, lightMin: tst.map { $0 * 0.55 }, disturbances: nil,
                    restingHr: nil, avgHrv: nil, recovery: nil, strain: strain, exerciseCount: nil,
                    spo2Pct: nil, skinTempDevC: nil, respRateBpm: nil)
    }

    private func key(_ d: Int) -> String { LocalCalendarDate(year: 2026, month: 6, day: d).key }

    // MARK: Stored figures

    func testNightAndTonightPointsRoundTrip() throws {
        let need = SleepNeed.compose(baselineMin: 480, strainMin: 30, debtMin: 20, napMin: 10)
        let f = RestNightFigures(day: key(10), need: need, consistency: 0.8765, rest: 88.5,
                                 hoursVsNeededPct: 95.2, debtAfterMin: 12.3)
        let points = SleepFigureKeys.nightPoints(f) + SleepFigureKeys.tonightPoints(day: key(10), need)
        XCTAssertEqual(Set(points.map(\.key)), Set(SleepFigureKeys.all), "every key is written, none unknown")
        let figures = try XCTUnwrap(SleepFigureKeys.figures(from: points)[key(10)])
        XCTAssertEqual(figures.needBreakdown, need)
        XCTAssertEqual(figures.tonightBreakdown, need)
        XCTAssertEqual(figures.restScore, 88.5)
        XCTAssertEqual(figures.consistencyPct, 87.65, "stored as a percentage, like the WHOOP export")
        XCTAssertEqual(figures.debtAfterMin, 12.3)
        XCTAssertEqual(figures.hoursVsNeededPct, 95.2)
    }

    func testANightWithoutConsistencyOrRestWritesNeither() {
        let need = SleepNeed.compose(baselineMin: 480, strainMin: 0, debtMin: 0, napMin: 0)
        let points = SleepFigureKeys.nightPoints(RestNightFigures(day: key(3), need: need, consistency: nil,
                                                                  rest: nil, hoursVsNeededPct: nil))
        XCTAssertFalse(points.contains { $0.key == SleepFigureKeys.consistency })
        XCTAssertFalse(points.contains { $0.key == SleepFigureKeys.rest })
        XCTAssertTrue(SleepFigureKeys.replacedOnRescore.contains(SleepFigureKeys.consistency),
                      "so a re-score that loses a night's consistency also removes the stale stored value")
    }

    // MARK: The one per-night read

    func testResolvedNightPrefersTheImportThenTheStoredFigureThenTheDailyFallback() {
        let d = daily(key(10), tst: 420)
        let stored = [key(10): ComputedSleepFigures(restScore: 77, needMin: 500, needBaselineMin: 480,
                                                    needStrainMin: 20, needDebtMin: 0, needNapCreditMin: 0,
                                                    debtAfterMin: 44, consistencyPct: 90, hoursVsNeededPct: 84)]

        let computed = Repository.resolvedNightSleep(day: d.day, daily: d, imported: [:], computed: stored)
        XCTAssertEqual(computed.restScore, 77)
        XCTAssertEqual(computed.needMin, 500)
        XCTAssertEqual(computed.needBreakdown?.totalMin, 500)
        XCTAssertEqual(computed.consistencyPct, 90)
        XCTAssertEqual(computed.hoursVsNeededPct, 84)
        XCTAssertEqual(computed.debtMin, 44)
        XCTAssertFalse(computed.restIsImported)

        let imported = [key(10): ImportedSleepFigures(performancePct: 91, consistencyPct: 70, needMin: 450,
                                                      debtMin: 5)]
        let fromImport = Repository.resolvedNightSleep(day: d.day, daily: d, imported: imported, computed: stored)
        XCTAssertEqual(fromImport.restScore, 91)
        XCTAssertEqual(fromImport.needMin, 450)
        XCTAssertNil(fromImport.needBreakdown, "an export carries only the total; NOOP's parts would not add up to it")
        XCTAssertEqual(fromImport.consistencyPct, 70)
        XCTAssertEqual(fromImport.debtMin, 5)
        XCTAssertEqual(fromImport.hoursVsNeededPct ?? -1, 93.3, accuracy: 1e-9)
        XCTAssertTrue(fromImport.restIsImported)

        let neither = Repository.resolvedNightSleep(day: d.day, daily: d, imported: [:], computed: [:])
        XCTAssertEqual(neither.restScore, Repository.dailyColumn(key: "sleep_performance", day: d),
                       "the same daily-column fallback exploreSeries gives the Today hero")
        XCTAssertNil(neither.needMin)
        XCTAssertNil(neither.consistencyPct)
    }

    // MARK: Engine inputs

    /// Blocks for one wake day, anchored on the local calendar so the main-night selector sees a real
    /// overnight: 23:00→07:00 plus a 30-minute nap at 14:00.
    private func dayBlocks(wakeDay: Date, napMin: Double = 30) -> [CachedSleepSession] {
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: wakeDay)
        let bed = Int(midnight.timeIntervalSince1970) - 3600
        let wake = Int(midnight.timeIntervalSince1970) + 7 * 3600
        let napStart = Int(midnight.timeIntervalSince1970) + 14 * 3600
        let night = CachedSleepSession(startTs: bed, endTs: wake, efficiency: 0.95, restingHr: nil, avgHrv: nil,
                                       stagesJSON: #"{"light":260,"deep":90,"rem":106,"awake":24}"#)
        guard napMin > 0 else { return [night] }
        let nap = CachedSleepSession(startTs: napStart, endTs: napStart + Int(napMin) * 60 + 300, efficiency: 0.9,
                                     restingHr: nil, avgHrv: nil,
                                     stagesJSON: "{\"light\":\(Int(napMin)),\"deep\":0,\"rem\":0,\"awake\":5}")
        return [night, nap]
    }

    func testDayShapeTakesTheMainNightTimingAndCountsOtherBlocksAsNaps() throws {
        let wakeDay = Date(timeIntervalSince1970: 1_781_000_000)
        let blocks = dayBlocks(wakeDay: wakeDay)
        let shape = try XCTUnwrap(SleepNeedInputs.dayShape(blocks, habitualMidsleepSec: nil))
        XCTAssertEqual(shape.bedTs, blocks[0].startTs)
        XCTAssertEqual(shape.wakeTs, blocks[0].endTs)
        XCTAssertEqual(shape.napMin, 30, accuracy: 1e-9)
        XCTAssertNil(SleepNeedInputs.dayShape([], habitualMidsleepSec: nil))
    }

    func testResolutionCreditsANapToTheFollowingNightAndScoresRegularTiming() throws {
        let cal = Calendar.current
        let first = cal.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 12))!
        var history: [DailyMetric] = []
        var blocksByDay: [String: [CachedSleepSession]] = [:]
        for i in 0..<10 {
            let wakeDay = cal.date(byAdding: .day, value: i, to: first)!
            let dayKey = Repository.localDayKey(wakeDay)
            history.append(daily(dayKey, tst: 456, strain: 40))
            blocksByDay[dayKey] = dayBlocks(wakeDay: wakeDay, napMin: i == 5 ? 45 : 0)
        }
        let resolution = SleepNeedInputs.resolution(
            history: history, blocksByDay: blocksByDay, habitualMidsleepSec: nil, age: nil,
            tonightAfter: history.last?.day, offsetAt: { _ in TimeZone.current.secondsFromGMT() })
        let napDay = history[5].day, nextNight = history[6].day
        XCTAssertEqual(resolution.timeline.need(forNightEnding: nextNight)?.napCreditMin ?? -1, 45, accuracy: 1e-9)
        XCTAssertEqual(resolution.timeline.need(forNightEnding: napDay)?.napCreditMin, 0)
        XCTAssertEqual(resolution.consistency[history[9].day], 1, "identical 23:00→07:00 nights")
        XCTAssertNil(resolution.consistency[history[1].day], "too few earlier nights")

        let figures = resolution.figures(for: history[9])
        XCTAssertEqual(figures.rest, AnalyticsEngine.Rest.composite(daily: history[9], need: figures.need,
                                                                    consistency: 1))
    }

    // MARK: Sleep tab tiles

    func testSleepTabTilesReadTheStoredFiguresNotASecondDefinition() {
        let days = (1...10).map { daily(key($0), tst: 420) }
        var stored: [String: ComputedSleepFigures] = [:]
        for d in days {
            stored[d.day] = ComputedSleepFigures(restScore: 70, needMin: 525, needBaselineMin: 500,
                                                 needStrainMin: 25, needDebtMin: 0, needNapCreditMin: 0,
                                                 debtAfterMin: 58, consistencyPct: 83, hoursVsNeededPct: 80)
        }
        stored[key(10)]?.tonightNeedMin = 558
        stored[key(10)]?.tonightBaselineMin = 500
        stored[key(10)]?.tonightStrainMin = 0
        stored[key(10)]?.tonightDebtMin = 58
        stored[key(10)]?.tonightNapCreditMin = 0

        XCTAssertEqual(SleepModel.performanceSeries(days: days, importedSleep: [:], computedSleep: stored).series,
                       Array(repeating: 70, count: 10))
        XCTAssertEqual(SleepModel.consistencySeries(days: days, importedSleep: [:], computedSleep: stored).series,
                       Array(repeating: 83, count: 10))
        let fallback = SleepModel.needTimeline(days: days, napSleepMinByDay: [:])
        XCTAssertEqual(SleepModel.hoursVsNeededSeries(days: days, importedSleep: [:], computedSleep: stored,
                                                      fallback: fallback).series,
                       Array(repeating: 80, count: 10))
        let debt = SleepModel.sleepDebtSeries(days: days, importedSleep: [:], computedSleep: stored,
                                              napSleepMinByDay: [:], fallback: fallback)
        XCTAssertEqual(debt.latest, 58)

        let ledger = SleepModel.debtLedger(days: days, napSleepMinByDay: [:], computedSleep: stored,
                                           fallback: fallback)
        XCTAssertEqual(ledger.balanceMin, -58, "the stored tonight debt, the same number the tile shows")
        XCTAssertEqual(ledger.needMin, 500)
        XCTAssertEqual(ledger.nights.map(\.deltaMin), Array(repeating: -80, count: 10),
                       "each bar against the night's stored baseline")
    }

    func testWithoutStoredFiguresTheTilesFallBackToTheOneModel() {
        let days = (1...10).map { daily(key($0), tst: 420) }
        let fallback = SleepModel.needTimeline(days: days, napSleepMinByDay: [:])
        let hvn = SleepModel.hoursVsNeededSeries(days: days, importedSleep: [:], computedSleep: [:],
                                                 fallback: fallback)
        let need = fallback.need(forNightEnding: key(10))!.totalMin
        XCTAssertEqual(hvn.series.last ?? -1, (420 / need * 1000).rounded() / 10, accuracy: 1e-9)
        let ledger = SleepModel.debtLedger(days: days, napSleepMinByDay: [:])
        XCTAssertEqual(ledger, fallback.ledger)
    }
}
