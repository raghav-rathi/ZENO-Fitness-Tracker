import XCTest
@testable import StrandAnalytics

final class HomeCoachingRulesTests: XCTestCase {

    private typealias Rules = HomeCoachingRules
    private let today = "2026-10-02"

    /// `count` scored days ending the day before `today`, all at `value`.
    private func history(_ count: Int, value: Double) -> [Rules.DayValue] {
        (1...max(1, count)).reversed().compactMap { n in
            PulseDisplay.dayKey(today, offsetBy: -n).map { Rules.DayValue(day: $0, value: value) }
        }
    }

    private func day(_ offset: Int) -> String {
        PulseDisplay.dayKey(today, offsetBy: offset) ?? today
    }

    private func trustedHRV(_ baseline: Double, spread: Double) -> BaselineState {
        BaselineState(baseline: baseline, spread: spread, nValid: 30, nightsSinceUpdate: 0, status: .trusted)
    }

    // MARK: Nothing to say

    func testEmptyInputsMakeNoCards() {
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today)), [])
    }

    // MARK: Recovery cards

    func testNewlyRedAfterAYellowDay() {
        let inputs = Rules.Inputs(dayKey: today, recovery: 28,
                                  recoveryHistory: [Rules.DayValue(day: day(-1), value: 55)])
        XCTAssertEqual(Rules.cards(inputs), [.newlyRed(recovery: 28, previous: 55)])
    }

    func testNewlyRedNeedsYesterday() {
        // Three nights off-wrist: the last scored day is four days back. The card says "the day before",
        // so it must not fire against an older day.
        let gap = Rules.Inputs(dayKey: today, recovery: 28,
                               recoveryHistory: [Rules.DayValue(day: day(-4), value: 55)])
        XCTAssertEqual(Rules.cards(gap), [])
        // The same history with yesterday scored and yellow is newly red against yesterday's figure.
        let yesterday = Rules.Inputs(dayKey: today, recovery: 28,
                                     recoveryHistory: [Rules.DayValue(day: day(-4), value: 20),
                                                       Rules.DayValue(day: day(-1), value: 61)])
        XCTAssertEqual(Rules.cards(yesterday), [.newlyRed(recovery: 28, previous: 61)])
    }

    func testRedAfterRedIsNotNewlyRed() {
        let inputs = Rules.Inputs(dayKey: today, recovery: 28,
                                  recoveryHistory: [Rules.DayValue(day: day(-1), value: 30)])
        XCTAssertEqual(Rules.cards(inputs), [])
    }

    func testBandsAreJudgedOnThePrintedPercent() {
        // 33.6 prints "34%", which is yellow: no red card.
        let yellow = Rules.Inputs(dayKey: today, recovery: 33.6,
                                  recoveryHistory: [Rules.DayValue(day: day(-1), value: 60)])
        XCTAssertEqual(Rules.cards(yellow), [])
        // 33.4 prints "33%": red.
        let red = Rules.Inputs(dayKey: today, recovery: 33.4,
                               recoveryHistory: [Rules.DayValue(day: day(-1), value: 60)])
        XCTAssertEqual(Rules.cards(red), [.newlyRed(recovery: 33, previous: 60)])
    }

    func testLowestInNinetyDaysNamesTheLastDayAsLow() {
        var past = history(30, value: 60)
        // A day 120 days back at 18%: outside the window, it is what "since" names.
        past.insert(Rules.DayValue(day: day(-120), value: 18), at: 0)
        let inputs = Rules.Inputs(dayKey: today, recovery: 20, recoveryHistory: past)
        XCTAssertEqual(Rules.cards(inputs), [.lowestInAWhile(recovery: 20, sinceDay: day(-120), lowestInWindow: true)])
    }

    func testLowestOnRecordHasNoSinceDay() {
        let inputs = Rules.Inputs(dayKey: today, recovery: 40, recoveryHistory: history(20, value: 70))
        XCTAssertEqual(Rules.cards(inputs), [.lowestInAWhile(recovery: 40, sinceDay: nil, lowestInWindow: true)])
    }

    func testLowestNeedsEnoughHistory() {
        // Lowest of only ten scored days: not enough to call it the lowest in a while.
        let inputs = Rules.Inputs(dayKey: today, recovery: 40, recoveryHistory: history(10, value: 70))
        XCTAssertEqual(Rules.cards(inputs), [])
    }

    func testAnEqualDayInTheWindowIsNotBeaten() {
        var past = history(30, value: 60)
        past[10] = Rules.DayValue(day: past[10].day, value: 40)
        let inputs = Rules.Inputs(dayKey: today, recovery: 40, recoveryHistory: past)
        XCTAssertEqual(Rules.cards(inputs), [])
    }

    func testFloorAlwaysCountsAndSuppressesNewlyRed() {
        // 4% after a 3% day five days ago: not the lowest in the window, but at the floor.
        var past = history(30, value: 60)
        past[25] = Rules.DayValue(day: past[25].day, value: 3)
        let inputs = Rules.Inputs(dayKey: today, recovery: 4, recoveryHistory: past)
        XCTAssertEqual(Rules.cards(inputs), [.lowestInAWhile(recovery: 4, sinceDay: nil, lowestInWindow: false)])
    }

    func testNearPerfect() {
        let inputs = Rules.Inputs(dayKey: today, recovery: 98.6, recoveryHistory: history(5, value: 70))
        XCTAssertEqual(Rules.cards(inputs), [.nearPerfect(recovery: 99)])
    }

    func testCalibratingCountsNights() {
        let inputs = Rules.Inputs(dayKey: today, calibration: Rules.Calibration(nights: 2, of: 4))
        XCTAssertEqual(Rules.cards(inputs), [.calibrating(nights: 2, of: 4)])
        let done = Rules.Inputs(dayKey: today, calibration: Rules.Calibration(nights: 4, of: 4))
        XCTAssertEqual(Rules.cards(done), [])
    }

    // MARK: HRV

    func testLowHRVBelowOneSpread() {
        // sigma = 1.253 × 8 ≈ 10.0; 52 is ≈ −1.2 σ under 64.
        let inputs = Rules.Inputs(dayKey: today, hrv: 52, hrvBaseline: trustedHRV(64, spread: 8))
        XCTAssertEqual(Rules.cards(inputs), [.lowHRV(hrv: 52, baseline: 64)])
    }

    func testHRVWithinOneSpreadIsQuiet() {
        let inputs = Rules.Inputs(dayKey: today, hrv: 58, hrvBaseline: trustedHRV(64, spread: 8))
        XCTAssertEqual(Rules.cards(inputs), [])
    }

    func testHRVNeedsAUsableBaseline() {
        let learning = BaselineState(baseline: 64, spread: 8, nValid: 2, nightsSinceUpdate: 0, status: .calibrating)
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, hrv: 30, hrvBaseline: learning)), [])
    }

    // MARK: Sleep

    func testRoughSleepStreakEndingLastNight() {
        let nights = [day(-3), day(-2), day(-1), today].map { Rules.DayValue(day: $0, value: 62) }
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepPerformance: nights)),
                       [.roughSleepStreak(nights: 4)])
    }

    func testRoughSleepStreakBrokenByAGoodNightOrAGap() {
        let good = [Rules.DayValue(day: day(-2), value: 60), Rules.DayValue(day: day(-1), value: 85),
                    Rules.DayValue(day: today, value: 60)]
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepPerformance: good)), [])
        let gap = [Rules.DayValue(day: day(-4), value: 60), Rules.DayValue(day: day(-3), value: 60),
                   Rules.DayValue(day: day(-1), value: 60), Rules.DayValue(day: today, value: 60)]
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepPerformance: gap)), [])
    }

    func testRoughSleepNeedsLastNight() {
        let stale = [day(-4), day(-3), day(-2)].map { Rules.DayValue(day: $0, value: 50) }
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepPerformance: stale)), [])
    }

    func testSleepDebtRising() {
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepDebtMin: 140, previousSleepDebtMin: 100)),
                       [.sleepDebtRising(debtMin: 140)])
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepDebtMin: 140, previousSleepDebtMin: 150)), [])
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepDebtMin: 110, previousSleepDebtMin: 60)), [])
    }

    func testSleepDebtNeedsTheDayBeforeToBeRising() {
        // A large debt with no figure for the day before is not "rising": nothing says it rose.
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, sleepDebtMin: 180, previousSleepDebtMin: nil)), [])
    }

    // MARK: Strain progress (the optimal range 14–18, target 16)

    private func strain(_ value: Double?, recovery: Double = 80, target: Double = 16) -> [Rules.Card] {
        Rules.cards(Rules.Inputs(dayKey: today, recovery: recovery, recoveryHistory: history(5, value: 70),
                                 strain: value, optimalRange: 14...18, strainTarget: target))
    }

    func testStrainFamilyFollowsTheRange() {
        XCTAssertEqual(strain(nil), [.optimalHealth(target: 16)])
        XCTAssertEqual(strain(9.5), [.optimalHealth(target: 16)])
        XCTAssertEqual(strain(14.0), [.buildingFitness(target: 16)])
        XCTAssertEqual(strain(16.0), [.strainTargetReached(target: 16)])
        XCTAssertEqual(strain(18.0), [.strainTargetReached(target: 16)])
        XCTAssertEqual(strain(18.4), [.pushingLimits(strain: 18.4, rangeHigh: 18)])
    }

    func testTheTargetIsTheDialsOwn() {
        // The card names the target it is given (the dial's tick), not a midpoint it works out itself.
        XCTAssertEqual(strain(15.6, target: 15.5), [.strainTargetReached(target: 15.5)])
        XCTAssertEqual(strain(15.0, target: 15.5), [.buildingFitness(target: 15.5)])
        XCTAssertEqual(strain(9.5, target: 15.5), [.optimalHealth(target: 15.5)])
    }

    func testNoTargetNoStrainCard() {
        // A range without the dial's target (or a target outside it) names nothing.
        let none = Rules.Inputs(dayKey: today, recovery: 80, recoveryHistory: history(5, value: 70),
                                strain: 15, optimalRange: 14...18)
        XCTAssertEqual(Rules.cards(none), [])
        XCTAssertEqual(strain(15, target: 19), [])
    }

    func testBelowTheRangeDependsOnTheBand() {
        let red = Rules.cards(Rules.Inputs(dayKey: today, recovery: 20,
                                           recoveryHistory: [Rules.DayValue(day: day(-1), value: 25)],
                                           strain: 2, optimalRange: 4...10, strainTarget: 7))
        XCTAssertEqual(red, [.recoveringFromStrain(rangeHigh: 10)])
        let yellow = Rules.cards(Rules.Inputs(dayKey: today, recovery: 50, recoveryHistory: history(5, value: 50),
                                              strain: 2, optimalRange: 10...14, strainTarget: 12))
        XCTAssertEqual(yellow, [])
    }

    func testNoRangeNoStrainCard() {
        // Recovery not scored for the day (a carried value never sets a range): no Strain card.
        let inputs = Rules.Inputs(dayKey: today, recovery: nil, strain: 12, optimalRange: 14...18, strainTarget: 16)
        XCTAssertEqual(Rules.cards(inputs), [])
    }

    // MARK: Alarm

    func testAlarmWhileAwake() {
        let up = Rules.AlarmCheck(alarmMinute: 7 * 60 + 30, wokeMinute: 6 * 60 + 40, nowMinute: 7 * 60)
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, alarm: up)), [.alarmWhileAwake(alarmMinute: 450)])
        let rang = Rules.AlarmCheck(alarmMinute: 7 * 60 + 30, wokeMinute: 6 * 60 + 40, nowMinute: 8 * 60)
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, alarm: rang)), [])
        let asleep = Rules.AlarmCheck(alarmMinute: 7 * 60 + 30, wokeMinute: nil, nowMinute: 7 * 60)
        XCTAssertEqual(Rules.cards(Rules.Inputs(dayKey: today, alarm: asleep)), [])
    }

    // MARK: Order

    func testPriorityOrder() {
        let nights = [day(-2), day(-1), today].map { Rules.DayValue(day: $0, value: 55) }
        let inputs = Rules.Inputs(
            dayKey: today, recovery: 28, recoveryHistory: [Rules.DayValue(day: day(-1), value: 60)],
            strain: 1, optimalRange: 4...10, strainTarget: 7, hrv: 40, hrvBaseline: trustedHRV(64, spread: 8),
            sleepPerformance: nights, sleepDebtMin: 150, previousSleepDebtMin: 90, illness: true,
            alarm: Rules.AlarmCheck(alarmMinute: 480, wokeMinute: 400, nowMinute: 420),
            weekInReview: true, whatsNew: true)
        XCTAssertEqual(Rules.cards(inputs).map(\.id), [
            "illness", "alarm-awake", "newly-red", "low-hrv", "rough-sleep", "recovering", "sleep-debt",
            "week-review", "whats-new",
        ])
    }
}
