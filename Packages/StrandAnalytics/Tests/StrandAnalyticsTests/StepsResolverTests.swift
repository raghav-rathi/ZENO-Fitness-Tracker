import XCTest
@testable import StrandAnalytics

/// Pins the ONE steps resolver: source precedence, the in-progress-day exception, zero handling, and which
/// source an hourly chart draws.
final class StepsResolverTests: XCTestCase {

    private func resolve(_ c: StepDayCandidates, today: Bool = false) -> ResolvedStepDay? {
        StepsResolver.resolve(day: "2026-09-29", candidates: c, isInProgressDay: today)
    }

    func testPrecedenceOrderIsHealthThenPhoneThenCounterThenEstimate() {
        XCTAssertEqual(StepSource.allCases, [.healthKit, .phonePedometer, .strapCounter, .strapEstimate])
        XCTAssertEqual(StepSource.allCases.map(\.rank), [0, 1, 2, 3])
        XCTAssertFalse(StepSource.strapEstimate.isMeasured)
        XCTAssertTrue(StepSource.allCases.filter { $0 != .strapEstimate }.allSatisfy(\.isMeasured))
    }

    func testEachSourceWinsOverEveryLowerRankedOne() {
        let all = StepDayCandidates(healthKit: 9_000, phonePedometer: 8_000, strapCounter: 12_000, strapEstimate: 7_000)
        XCTAssertEqual(resolve(all), ResolvedStepDay(day: "2026-09-29", steps: 9_000, source: .healthKit))

        var noHealth = all; noHealth.healthKit = nil
        XCTAssertEqual(resolve(noHealth)?.source, .phonePedometer)
        XCTAssertEqual(resolve(noHealth)?.steps, 8_000)

        var counterAndEstimate = noHealth; counterAndEstimate.phonePedometer = nil
        XCTAssertEqual(resolve(counterAndEstimate)?.source, .strapCounter)
        XCTAssertEqual(resolve(counterAndEstimate)?.steps, 12_000)

        let estimateOnly = StepDayCandidates(strapEstimate: 6_500)
        XCTAssertEqual(resolve(estimateOnly), ResolvedStepDay(day: "2026-09-29", steps: 6_500, source: .strapEstimate))
    }

    func testNoReadingResolvesToNil() {
        XCTAssertNil(resolve(StepDayCandidates()))
        XCTAssertTrue(StepDayCandidates().isEmpty)
        // A negative value is not a count.
        XCTAssertNil(resolve(StepDayCandidates(healthKit: -5)))
        XCTAssertTrue(StepDayCandidates(phonePedometer: -1).isEmpty)
    }

    func testAZeroNeverBeatsAPositiveLowerRankedReading() {
        // A phone left in a drawer reads 0 all day; the strap's estimate of that day is the better answer.
        let c = StepDayCandidates(healthKit: 0, phonePedometer: 0, strapEstimate: 5_400)
        XCTAssertEqual(resolve(c), ResolvedStepDay(day: "2026-09-29", steps: 5_400, source: .strapEstimate))
    }

    func testAnExplicitZeroStillShowsWhenNothingElseCounted() {
        // 0 from the highest-ranked source that reported one, rather than a blank.
        XCTAssertEqual(resolve(StepDayCandidates(phonePedometer: 0, strapCounter: 0)),
                       ResolvedStepDay(day: "2026-09-29", steps: 0, source: .phonePedometer))
    }

    func testPastDayKeepsStrictPrecedenceEvenWhenThePhoneIsHigher() {
        let c = StepDayCandidates(healthKit: 7_000, phonePedometer: 7_400)
        XCTAssertEqual(resolve(c, today: false)?.source, .healthKit)
        XCTAssertEqual(resolve(c, today: false)?.steps, 7_000)
    }

    func testInProgressDayTakesTheLivePhoneWhenHealthHasNotCaughtUp() {
        // Health synced at 09:00 with 3,000; the pedometer has counted 3,400 since midnight.
        let c = StepDayCandidates(healthKit: 3_000, phonePedometer: 3_400, strapEstimate: 9_999)
        XCTAssertEqual(resolve(c, today: true), ResolvedStepDay(day: "2026-09-29", steps: 3_400, source: .phonePedometer))
    }

    func testInProgressDayKeepsHealthWhenItIsAhead() {
        // Steps the Watch saw while the phone sat on a desk: Health is ahead and stays the answer.
        let ahead = StepDayCandidates(healthKit: 5_000, phonePedometer: 3_000)
        XCTAssertEqual(resolve(ahead, today: true)?.source, .healthKit)
        // A tie is Health's too.
        let tie = StepDayCandidates(healthKit: 4_000, phonePedometer: 4_000)
        XCTAssertEqual(resolve(tie, today: true)?.source, .healthKit)
    }

    func testInProgressDayWithoutHealthFallsBackToPlainPrecedence() {
        XCTAssertEqual(resolve(StepDayCandidates(phonePedometer: 1_200, strapEstimate: 4_000), today: true)?.source,
                       .phonePedometer)
        XCTAssertEqual(resolve(StepDayCandidates(strapEstimate: 4_000), today: true)?.source, .strapEstimate)
        // A zero live phone reading does not unseat a real Health figure.
        XCTAssertEqual(resolve(StepDayCandidates(healthKit: 800, phonePedometer: 0), today: true)?.source, .healthKit)
    }

    func testWindowResolutionIsSortedAndOnlyTheInProgressDayGetsTheException() {
        let byDay: [String: StepDayCandidates] = [
            "2026-09-30": StepDayCandidates(healthKit: 1_000, phonePedometer: 2_000),
            "2026-09-28": StepDayCandidates(healthKit: 1_000, phonePedometer: 2_000),
            "2026-09-29": StepDayCandidates(),
        ]
        let out = StepsResolver.resolve(byDay, inProgressDay: "2026-09-30")
        XCTAssertEqual(out.map(\.day), ["2026-09-28", "2026-09-30"])
        XCTAssertEqual(out.map(\.source), [.healthKit, .phonePedometer])
    }

    func testCandidatesSetterAndCountRoundTrip() {
        var c = StepDayCandidates()
        for (i, source) in StepSource.allCases.enumerated() { c.set(100 * (i + 1), for: source) }
        XCTAssertEqual(StepSource.allCases.map { c.count(for: $0) }, [100, 200, 300, 400])
    }

    func testHourlySourcePrefersTheDaysOwnSource() {
        XCTAssertEqual(StepsResolver.hourlySource(daySource: .phonePedometer,
                                                  sourcesWithHours: [.healthKit, .phonePedometer]), .phonePedometer)
        XCTAssertEqual(StepsResolver.hourlySource(daySource: .healthKit,
                                                  sourcesWithHours: [.healthKit, .phonePedometer]), .healthKit)
    }

    func testHourlySourceFallsBackToTheBestMeasuredSourceWithHours() {
        // A strap-resolved day can still draw the phone's shape; the caller labels it.
        XCTAssertEqual(StepsResolver.hourlySource(daySource: .strapEstimate,
                                                  sourcesWithHours: [.phonePedometer]), .phonePedometer)
        XCTAssertEqual(StepsResolver.hourlySource(daySource: .healthKit,
                                                  sourcesWithHours: [.phonePedometer]), .phonePedometer)
        XCTAssertEqual(StepsResolver.hourlySource(daySource: nil,
                                                  sourcesWithHours: [.healthKit, .phonePedometer]), .healthKit)
        XCTAssertNil(StepsResolver.hourlySource(daySource: .strapCounter, sourcesWithHours: []))
        // The estimate never has an hourly series, even if a caller claims it does.
        XCTAssertNil(StepsResolver.hourlySource(daySource: nil, sourcesWithHours: [.strapEstimate]))
    }
}
