import XCTest
import WhoopStore
@testable import StrandAnalytics

/// The unified need model: baseline + strain + debt − naps, one number per night.
final class SleepNeedTests: XCTestCase {

    /// `count` consecutive days ending at 2026-06-`endDay`, oldest first.
    private func days(_ count: Int, slept: Double?, effort: Double? = nil, nap: Double = 0,
                      startDay: Int = 1) -> [SleepNeedDay] {
        (0..<count).map { i in
            SleepNeedDay(day: key(startDay + i), mainSleepMin: slept, napSleepMin: nap, effort: effort)
        }
    }

    private func key(_ dayOfJune: Int) -> String {
        LocalCalendarDate(year: 2026, month: 6, day: 1).adding(days: dayOfJune - 1).key
    }

    // MARK: Components

    func testStrainAddsNothingWithoutATypicalDayOrOnAnOrdinaryDay() {
        XCTAssertEqual(SleepNeed.strainAdjustmentMin(effort: 80, typicalEffort: nil), 0)
        XCTAssertEqual(SleepNeed.strainAdjustmentMin(effort: nil, typicalEffort: 40), 0)
        XCTAssertEqual(SleepNeed.strainAdjustmentMin(effort: 40, typicalEffort: 40), 0)
        XCTAssertEqual(SleepNeed.strainAdjustmentMin(effort: 20, typicalEffort: 40), 0,
                       "an easy day never lowers the need")
    }

    func testStrainIsLinearAboveTypicalAndCapped() {
        XCTAssertEqual(SleepNeed.strainAdjustmentMin(effort: 52.5, typicalEffort: 40), 30, accuracy: 1e-9)
        XCTAssertEqual(SleepNeed.strainAdjustmentMin(effort: 65, typicalEffort: 40), 60, accuracy: 1e-9)
        XCTAssertEqual(SleepNeed.strainAdjustmentMin(effort: 99, typicalEffort: 40),
                       SleepNeed.maxStrainExtraMin, accuracy: 1e-9)
    }

    func testTypicalEffortIsAMedianThatNeedsAWeek() {
        XCTAssertNil(SleepNeed.typicalEffort([30, 40, 50, 60, 70, 80]))
        XCTAssertEqual(SleepNeed.typicalEffort([30, 40, 50, 60, 70, 80, 99]), 60)
        XCTAssertEqual(SleepNeed.typicalEffort([30, 40, 50, 60, 70, 80, 90, 100]), 65)
    }

    func testComposeKeepsTheBreakdownIdentityAndTheNapFloor() {
        let n = SleepNeed.compose(baselineMin: 480, strainMin: 30, debtMin: 42.5, napMin: 20)
        XCTAssertEqual(n.totalMin, 532.5, accuracy: 1e-9)
        XCTAssertEqual(n.baselineMin + n.strainMin + n.debtMin - n.napCreditMin, n.totalMin, accuracy: 1e-9)

        // A four-hour "nap" cannot take the need below half the baseline.
        let floored = SleepNeed.compose(baselineMin: 480, strainMin: 0, debtMin: 0, napMin: 240 + 60)
        XCTAssertEqual(floored.totalMin, 240, accuracy: 1e-9)
        XCTAssertEqual(floored.napCreditMin, 240, accuracy: 1e-9,
                       "the credit reports only what was applied, so the parts still add up")
    }

    // MARK: Timeline

    func testColdStartIsThePopulationBaselineAlone() {
        let t = SleepNeed.timeline(days: [], age: nil, tonightAfter: "2026-06-10")
        XCTAssertEqual(t.tonight, SleepNeed.compose(baselineMin: 480, strainMin: 0, debtMin: 0, napMin: 0))
        XCTAssertEqual(t.tonightAfterDay, "2026-06-10")
        XCTAssertEqual(t.ledger.nightCount, 0)
    }

    func testDebtMatchesTheExistingLedgerWhenThereIsNoStrainOrNap() {
        // Ten 6-hour nights: the baseline stays at the 8 h adult floor, so the unified debt must equal
        // the old ledger's recurrence against 8 h exactly.
        let history = days(10, slept: 360)
        let t = SleepNeed.timeline(days: history, age: 35)
        let old = SleepDebt.ledger(series: history.map { ($0.day, $0.mainSleepMin) }, needHours: 8)
        XCTAssertEqual(t.tonight.debtMin, old.magnitudeMin)
        XCTAssertEqual(t.ledger.balanceMin, old.balanceMin)
        XCTAssertEqual(t.ledger.nights.map(\.deltaMin), old.nights.map(\.deltaMin))
    }

    func testANightsNeedIncludesTheDebtCarriedIntoIt() {
        let history = days(3, slept: 360)
        let t = SleepNeed.timeline(days: history, age: nil)
        let first = t.need(forNightEnding: key(1))!
        XCTAssertEqual(first.debtMin, 0, "nothing is owed before the first night")
        let second = t.need(forNightEnding: key(2))!
        XCTAssertEqual(second.debtMin, 0.55 * (480 - 360), accuracy: 0.05)
        XCTAssertEqual(second.totalMin, 480 + 0.55 * 120, accuracy: 0.05)
    }

    func testDebtAfterANightIsTheDebtCarriedIntoTheNextAndTheNewestIsTonights() {
        let history = days(6, slept: 400)
        let t = SleepNeed.timeline(days: history, age: nil)
        for d in 1...5 {
            XCTAssertEqual(t.debtAfter[key(d)], t.need(forNightEnding: key(d + 1))?.debtMin, "night \(d)")
        }
        XCTAssertEqual(t.debtAfter[key(6)], t.tonight.debtMin)
        XCTAssertEqual(t.debtAfter[key(6)], t.ledger.magnitudeMin)
    }

    func testAHardDayRaisesOnlyTheNextNightsNeed() {
        // Nine ordinary days at Effort 40, then a 65 on day 10: night 11 carries the full +60.
        var history = days(10, slept: 480, effort: 40)
        history[9] = SleepNeedDay(day: key(10), mainSleepMin: 480, effort: 65)
        history.append(SleepNeedDay(day: key(11), mainSleepMin: 480, effort: 40))
        let t = SleepNeed.timeline(days: history, age: nil)
        XCTAssertEqual(t.need(forNightEnding: key(10))?.strainMin, 0)
        XCTAssertEqual(t.need(forNightEnding: key(11))?.strainMin ?? -1, 60, accuracy: 1e-9)
        // A met 8 h night against a 9 h need leaves debt behind for the night after.
        XCTAssertGreaterThan(t.tonight.debtMin, 0)
    }

    func testNapsLowerTheNextNightAndAreNotAlsoCreditedAsSleep() {
        // 8 h nights, and a 60-minute nap on day 3.
        var history = days(5, slept: 480)
        history[2] = SleepNeedDay(day: key(3), mainSleepMin: 480, napSleepMin: 60)
        let t = SleepNeed.timeline(days: history, age: nil)
        let night4 = t.need(forNightEnding: key(4))!
        XCTAssertEqual(night4.napCreditMin, 60, accuracy: 1e-9)
        XCTAssertEqual(night4.totalMin, 420, accuracy: 1e-9)
        // Sleeping the full 8 h against a 7 h need does not bank a surplus, and the nap was not ALSO
        // counted as sleep: no debt exists anywhere.
        XCTAssertEqual(t.need(forNightEnding: key(5))?.debtMin, 0)
        XCTAssertEqual(t.tonight.debtMin, 0)

        // The same history where the 8 h night after the nap is only 7 h: exactly met, so still no debt.
        history[3] = SleepNeedDay(day: key(4), mainSleepMin: 420)
        let met = SleepNeed.timeline(days: history, age: nil)
        XCTAssertEqual(met.need(forNightEnding: key(5))?.debtMin, 0)
    }

    func testANightsNeedDoesNotMoveWhenLaterNightsLand() {
        let early = days(12, slept: 400, effort: 50)
        let later = early + days(8, slept: 600, effort: 90, nap: 30, startDay: 13)
        let a = SleepNeed.timeline(days: early, age: 40)
        let b = SleepNeed.timeline(days: later, age: 40)
        for d in 1...12 {
            XCTAssertEqual(a.need(forNightEnding: key(d)), b.need(forNightEnding: key(d)), "night \(d)")
        }
    }

    func testHistoryOlderThanTheWindowsChangesNothing() {
        // 200 days of mixed sleep and effort; dropping everything older than `historyNeededDays` before
        // day 150 leaves every need from day 150 on identical — which is what lets the engine and the
        // Repository fallback feed a bounded slice instead of the whole history.
        let full: [SleepNeedDay] = (1...200).map { i in
            SleepNeedDay(day: key(i), mainSleepMin: [330, 420, 510, 480, 560][i % 5],
                         napSleepMin: i % 9 == 0 ? 25 : 0, effort: [20, 45, 70, 35][i % 4])
        }
        let cutoff = LocalCalendarDate(key: key(150))!.adding(days: -SleepNeed.historyNeededDays).key
        let a = SleepNeed.timeline(days: full, age: 33)
        let b = SleepNeed.timeline(days: full.filter { $0.day >= cutoff }, age: 33)
        for i in 150...200 {
            XCTAssertEqual(a.need(forNightEnding: key(i)), b.need(forNightEnding: key(i)), "night \(i)")
            XCTAssertEqual(a.debtAfter[key(i)], b.debtAfter[key(i)], "night \(i)")
        }
        XCTAssertEqual(a.tonight, b.tonight)
        XCTAssertEqual(a.ledger, b.ledger)
    }

    func testAShortfallDoesNotStayOwedAcrossALongBreak() {
        // Ten 5-hour nights build real debt; after a five-week break the next night owes none of it.
        let history = days(10, slept: 300) + [SleepNeedDay(day: key(46), mainSleepMin: 480)]
        let t = SleepNeed.timeline(days: history, age: nil)
        XCTAssertGreaterThan(t.need(forNightEnding: key(10))?.debtMin ?? 0, 60)
        XCTAssertEqual(t.need(forNightEnding: key(46))?.debtMin, 0)
    }

    func testTheBaselineForgetsNightsOlderThanNinetyDays() {
        // Thirty 9-hour nights, then a 100-day break: the next night is back on the population baseline.
        let history = days(30, slept: 540) + [SleepNeedDay(day: key(131), mainSleepMin: 480)]
        let t = SleepNeed.timeline(days: history, age: nil)
        XCTAssertEqual(t.need(forNightEnding: key(30))?.baselineMin, 540)
        XCTAssertEqual(t.need(forNightEnding: key(131))?.baselineMin, 480)
    }

    func testTheBaselineIsTrailingAndPersonal() {
        // A long sleeper: 30 nights of 9 h. The first 7 nights see a cold-start 8 h; after that the upper
        // quartile of PRIOR nights (9 h) takes over.
        let t = SleepNeed.timeline(days: days(30, slept: 540), age: 30)
        XCTAssertEqual(t.need(forNightEnding: key(1))?.baselineMin, 480)
        XCTAssertEqual(t.need(forNightEnding: key(7))?.baselineMin, 480)
        XCTAssertEqual(t.need(forNightEnding: key(8))?.baselineMin, 540)
        XCTAssertEqual(t.tonight.baselineMin, 540)
    }

    func testTonightPlansTheEveningOfThePlanDay() {
        var history = days(10, slept: 480, effort: 40)
        history.append(SleepNeedDay(day: key(11), mainSleepMin: 480, napSleepMin: 25, effort: 52.5))
        let t = SleepNeed.timeline(days: history, age: nil, tonightAfter: key(11))
        XCTAssertEqual(t.tonightAfterDay, key(11))
        XCTAssertEqual(t.tonight.strainMin, 30, accuracy: 1e-9)
        XCTAssertEqual(t.tonight.napCreditMin, 25, accuracy: 1e-9)
        XCTAssertEqual(t.tonight.totalMin, 480 + 30 - 25, accuracy: 1e-9)

        // Planning a day with no row yet (today, before anything scored) adds no strain or nap.
        let ahead = SleepNeed.timeline(days: history, age: nil, tonightAfter: key(12))
        XCTAssertEqual(ahead.tonight.strainMin, 0)
        XCTAssertEqual(ahead.tonight.napCreditMin, 0)
        XCTAssertEqual(ahead.ledger.nightCount, 11)
    }

    func testTheLedgerCoversTheRecentWindowOnly() {
        let t = SleepNeed.timeline(days: days(20, slept: 420), age: nil)
        XCTAssertEqual(t.ledger.nightCount, SleepDebt.defaultWindowNights)
        XCTAssertEqual(t.ledger.nights.last?.day, key(20))
        XCTAssertEqual(t.ledger.balanceMin, -t.tonight.debtMin)
        XCTAssertEqual(t.ledger.needMin, t.tonight.baselineMin)
    }

    func testUnusableNightsSupplyEffortButAreNotScored() {
        var history = days(9, slept: 480, effort: 40)
        history.append(SleepNeedDay(day: key(10), mainSleepMin: nil, effort: 65))
        history.append(SleepNeedDay(day: key(11), mainSleepMin: 480))
        let t = SleepNeed.timeline(days: history, age: nil)
        XCTAssertNil(t.need(forNightEnding: key(10)))
        XCTAssertEqual(t.need(forNightEnding: key(11))?.strainMin ?? -1, 60, accuracy: 1e-9)
    }

    // MARK: Bedtime

    func testSuggestedBedtimeSubtractsNeedAndLatency() {
        let wake = 1_780_000_000
        XCTAssertEqual(SleepNeed.suggestedBedtime(wakeTs: wake, needMin: 480), wake - (480 + 15) * 60)
        XCTAssertEqual(SleepNeed.suggestedBedtime(wakeTs: wake, needMin: 480, needFraction: 0.85, latencyMin: 0),
                       wake - 408 * 60)
        let wakeDate = Date(timeIntervalSince1970: TimeInterval(wake))
        XCTAssertEqual(SleepNeed.suggestedBedtime(wake: wakeDate, needMin: 450).timeIntervalSince1970,
                       TimeInterval(wake - 465 * 60))
    }

    func testTraceLineNamesEveryComponent() {
        let need = SleepNeed.compose(baselineMin: 480, strainMin: 30, debtMin: 12, napMin: 0)
        let line = SleepNeed.traceLine(day: "2026-06-02", need: need, consistency: 0.8, rest: 91.25)
        XCTAssertEqual(line, "rest stored day=2026-06-02 composite=91.25 needMin=522.0 baseline=480.0 "
                       + "strain=30.0 debt=12.0 napCredit=0.0 consistency=0.80")
    }
}

/// WHOOP-style consistency: bed AND wake timing against the previous four nights, circular clock.
final class SleepConsistencyTests: XCTestCase {

    func testCircularDistanceWrapsMidnight() {
        XCTAssertEqual(SleepConsistency.circularDistanceMin(23 * 60 + 50, 10), 20, accuracy: 1e-9)
        XCTAssertEqual(SleepConsistency.circularDistanceMin(60, 23 * 60), 120, accuracy: 1e-9)
        XCTAssertEqual(SleepConsistency.circularDistanceMin(0, 720), 720, accuracy: 1e-9)
    }

    func testIdenticalOrJitteryTimingScoresFullMarks() {
        let prior = Array(repeating: (bedMinute: 23.0 * 60, wakeMinute: 7.0 * 60), count: 4)
        XCTAssertEqual(SleepConsistency.score(bedMinute: 23 * 60, wakeMinute: 7 * 60, prior: prior), 1)
        XCTAssertEqual(SleepConsistency.score(bedMinute: 23 * 60 + 10, wakeMinute: 7 * 60 - 10, prior: prior), 1,
                       "inside the detection grace")
    }

    func testAShiftedNightLosesCreditLinearlyAndBottomsOut() {
        let prior = Array(repeating: (bedMinute: 23.0 * 60, wakeMinute: 7.0 * 60), count: 4)
        // 97.5 min average deviation: halfway between the 15 min grace and the 180 min zero.
        let half = SleepConsistency.score(bedMinute: 23 * 60 + 97.5, wakeMinute: 7 * 60 + 97.5, prior: prior)
        XCTAssertEqual(half ?? -1, 0.5, accuracy: 1e-4)
        XCTAssertEqual(SleepConsistency.score(bedMinute: 3 * 60, wakeMinute: 11 * 60, prior: prior), 0)
    }

    func testABedtimeAfterMidnightIsCloseToOneBeforeIt() {
        let prior = Array(repeating: (bedMinute: 23.0 * 60 + 45, wakeMinute: 7.0 * 60), count: 4)
        // 00:15 vs 23:45 is 30 minutes; the wake is identical, so the mean deviation is 15 → full marks.
        XCTAssertEqual(SleepConsistency.score(bedMinute: 15, wakeMinute: 7 * 60, prior: prior), 1)
    }

    func testNeedsThreeOfTheLastFourNights() {
        let two = Array(repeating: (bedMinute: 23.0 * 60, wakeMinute: 7.0 * 60), count: 2)
        XCTAssertNil(SleepConsistency.score(bedMinute: 23 * 60, wakeMinute: 7 * 60, prior: two))
    }

    func testScoresUseTheFourPreviousCalendarNightsOnly() {
        func night(_ d: Int, bed: Double, wake: Double) -> SleepConsistency.NightTiming {
            SleepConsistency.NightTiming(day: LocalCalendarDate(year: 2026, month: 6, day: d).key,
                                         bedMinute: bed, wakeMinute: wake)
        }
        // A wildly different night on the 1st is five nights before the 6th: it must not count.
        let nights = [night(1, bed: 180, wake: 660),
                      night(2, bed: 1380, wake: 420), night(3, bed: 1380, wake: 420),
                      night(4, bed: 1380, wake: 420), night(5, bed: 1380, wake: 420),
                      night(6, bed: 1380, wake: 420)]
        let scores = SleepConsistency.scores(nights)
        XCTAssertEqual(scores["2026-06-06"], 1)
        XCTAssertNil(scores["2026-06-03"], "only two earlier nights exist for the 3rd")
        XCTAssertNotNil(scores["2026-06-05"])
        XCTAssertLessThan(scores["2026-06-05"] ?? 1, 1, "the 5th still sees the odd night on the 1st")

        // A two-night gap leaves the 9th with only one neighbour in its window.
        let gap = nights + [night(9, bed: 1380, wake: 420)]
        XCTAssertNil(SleepConsistency.scores(gap)["2026-06-09"])
    }

    func testTimingKeepsItsWallClockAcrossAnOffsetChange() {
        // The same local wall-clock times two days apart, either side of a one-hour offset change: the
        // later instants are an hour earlier in UTC and must still read the same local minutes.
        let beforeDST = SleepConsistency.NightTiming(day: "2026-03-07", bedTs: 1_772_924_400, wakeTs: 1_772_953_200,
                                                     bedOffsetSec: -5 * 3600, wakeOffsetSec: -5 * 3600)
        let afterDST = SleepConsistency.NightTiming(day: "2026-03-09", bedTs: 1_772_924_400 + 2 * 86_400 - 3600,
                                                    wakeTs: 1_772_953_200 + 2 * 86_400 - 3600,
                                                    bedOffsetSec: -4 * 3600, wakeOffsetSec: -4 * 3600)
        XCTAssertEqual(beforeDST.bedMinute, afterDST.bedMinute)
        XCTAssertEqual(beforeDST.wakeMinute, afterDST.wakeMinute)
    }
}

/// One Rest per night: the stored value is the composite over the unified need and consistency.
final class RestResolutionTests: XCTestCase {

    private func daily(_ day: String, tst: Double, eff: Double = 0.95, deep: Double = 90,
                       rem: Double = 120) -> DailyMetric {
        DailyMetric(day: day, totalSleepMin: tst, efficiency: eff, deepMin: deep, remMin: rem,
                    lightMin: tst - deep - rem, disturbances: nil, restingHr: nil, avgHrv: nil,
                    recovery: nil, strain: nil, exerciseCount: nil, spo2Pct: nil, skinTempDevC: nil,
                    respRateBpm: nil)
    }

    private func key(_ d: Int) -> String { LocalCalendarDate(year: 2026, month: 6, day: d).key }

    func testFiguresAreTheCompositeOverTheResolvedInputs() {
        let history = (1...10).map { SleepNeedDay(day: key($0), mainSleepMin: 420, effort: 40) }
        let timings = (1...10).map { SleepConsistency.NightTiming(day: key($0), bedMinute: 1380, wakeMinute: 420) }
        let resolution = RestResolution(history: history, timings: timings, age: nil)
        let night = daily(key(10), tst: 420)
        let f = resolution.figures(for: night)
        let need = resolution.timeline.need(forNightEnding: key(10))!
        XCTAssertEqual(f.need, need)
        XCTAssertEqual(f.consistency, 1)
        XCTAssertEqual(f.rest, AnalyticsEngine.Rest.composite(daily: night, needHours: need.totalHours,
                                                              consistency: 1))
        XCTAssertEqual(f.hoursVsNeededPct ?? -1, (420 / need.totalMin * 1000).rounded() / 10, accuracy: 1e-9)
    }

    func testAFullyRegularNightCanNowScoreAHundred() {
        // Need met, near-perfect efficiency, a restorative night and identical timing: the old stored path
        // capped this at 95 (consistency stuck at 0.5).
        let history = (1...10).map { SleepNeedDay(day: key($0), mainSleepMin: 480) }
        let timings = (1...10).map { SleepConsistency.NightTiming(day: key($0), bedMinute: 1380, wakeMinute: 420) }
        let resolution = RestResolution(history: history, timings: timings, age: nil)
        let night = daily(key(10), tst: 480, eff: 1.0, deep: 100, rem: 150)
        XCTAssertEqual(resolution.figures(for: night).rest, 100)
        XCTAssertEqual(AnalyticsEngine.Rest.composite(daily: night), 95, "the old default path, for contrast")
    }

    func testANightOutsideTheHistoryGetsItsPriorBaselineNotADefault() {
        let history = (1...20).map { SleepNeedDay(day: key($0), mainSleepMin: 540) }
        let resolution = RestResolution(history: history, timings: [], age: nil)
        let need = resolution.need(forNightEnding: key(25))
        XCTAssertEqual(need.baselineMin, 540)
        XCTAssertEqual(need.totalMin, 540)
        XCTAssertNil(resolution.consistency[key(25)])
    }
}
