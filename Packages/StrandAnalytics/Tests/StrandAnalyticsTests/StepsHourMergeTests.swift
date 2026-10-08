import XCTest
import WhoopProtocol
@testable import StrandAnalytics

/// The hour-by-hour merge of phone and strap steps: the walking detector on the strap's 1 Hz gravity and heart
/// rate, the pace learned from carried hours, the strap's estimate per hour, the merge rule, and the per-day
/// fill the resolver adds.
final class StepsHourMergeTests: XCTestCase {

    private let newYork: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()
    /// New York in summer, seconds east of UTC.
    private let edt = -4 * 3_600

    private func ts(_ iso: String) -> Int {
        Int(ISO8601DateFormatter().date(from: iso)!.timeIntervalSince1970)
    }

    private func g(_ ts: Int, _ x: Double, _ y: Double = 0, _ z: Double = 1) -> GravitySample {
        GravitySample(ts: ts, x: x, y: y, z: z)
    }

    // MARK: - The walking detector

    func testHourAndMinuteStartsFloorToTheLocalClock() {
        XCTAssertEqual(StepsHourMerge.hourStart(ts("2026-09-29T08:59:59-04:00"), offsetSec: edt),
                       ts("2026-09-29T08:00:00-04:00"))
        XCTAssertEqual(StepsHourMerge.hourStart(ts("2026-09-29T09:00:00-04:00"), offsetSec: edt),
                       ts("2026-09-29T09:00:00-04:00"))
        // A half-hour zone (India, UTC+5:30): its clock hours start at :30 past the UTC hour.
        XCTAssertEqual(StepsHourMerge.hourStart(ts("2026-09-29T10:45:00+05:30"), offsetSec: 19_800),
                       ts("2026-09-29T10:00:00+05:30"))
        XCTAssertEqual(StepsHourMerge.minuteStart(ts("2026-09-29T08:41:59-04:00"), offsetSec: edt),
                       ts("2026-09-29T08:41:00-04:00"))
    }

    func testAWalkingMinuteMovesClearlyAlmostEverySecondWithTheHeartRateUp() {
        let walk = Array(repeating: 0.1, count: 59)
        XCTAssertTrue(StepsHourMerge.isWalkingMinute(changes: walk, heartRate: 100, restingRate: 61))
        // Arm movement: busy half the minute, still the rest.
        let arms = Array(repeating: 0.1, count: 30) + Array(repeating: 0.005, count: 29)
        XCTAssertFalse(StepsHourMerge.isWalkingMinute(changes: arms, heartRate: 100, restingRate: 61))
        // Moving every second, but barely: the median is under the walking level.
        XCTAssertFalse(StepsHourMerge.isWalkingMinute(changes: Array(repeating: 0.025, count: 59),
                                                      heartRate: 100, restingRate: 61))
        // A gap in the record leaves too little of the minute to judge.
        XCTAssertFalse(StepsHourMerge.isWalkingMinute(changes: Array(repeating: 0.1, count: 39),
                                                      heartRate: 100, restingRate: 61))
        // The heart rate is not up (gesturing while seated, steering a car).
        XCTAssertFalse(StepsHourMerge.isWalkingMinute(changes: walk, heartRate: 70, restingRate: 61))
        XCTAssertTrue(StepsHourMerge.isWalkingMinute(changes: walk, heartRate: 76, restingRate: 61))
        // No heart rate for the minute, or none for the day: the movement alone decides.
        XCTAssertTrue(StepsHourMerge.isWalkingMinute(changes: walk, heartRate: nil, restingRate: 61))
        XCTAssertTrue(StepsHourMerge.isWalkingMinute(changes: walk, heartRate: 70, restingRate: nil))
    }

    func testOnlyRunsOfTwoOrMoreWalkingMinutesCount() {
        XCTAssertEqual(StepsHourMerge.boutMinutes([0, 60, 180, 300, 360, 420]), [0, 60, 300, 360, 420])
        XCTAssertEqual(StepsHourMerge.boutMinutes([120]), [])
        XCTAssertEqual(StepsHourMerge.boutMinutes([]), [])
    }

    func testRestingRateIsALowPercentileOfTheDay() {
        XCTAssertNil(StepsHourMerge.restingRate([]))
        XCTAssertEqual(StepsHourMerge.restingRate(Array(50...149)), 60)
    }

    func testWalkingByHourCountsWalkedMinutesInBoutsAndEveryRow() {
        let eight = ts("2026-09-29T08:00:00-04:00")
        var grav: [GravitySample] = []
        var heart: [HRSample] = []
        for t in (eight - 600)..<(eight + 3_600) {
            let offset = t - eight
            let walking = (0..<600).contains(offset) || (1_800..<1_860).contains(offset)  // 08:00-08:09, 08:30
            let x = walking ? (t % 2 == 0 ? 0.05 : -0.05) : 0.0005 * Double(t % 3)
            grav.append(g(t, x))
            heart.append(HRSample(ts: t, bpm: walking ? 105 : 64))
        }
        let hours = StepsHourMerge.walkingByHour(grav, heartRate: heart, offsetSec: edt)
        // Ten minutes walked from 08:00; the lone minute at 08:30 is not a bout.
        XCTAssertEqual(hours[eight], StepsHourMerge.HourWalk(walkingMinutes: 10, rows: 3_600))
        XCTAssertEqual(hours[eight - 3_600], StepsHourMerge.HourWalk(walkingMinutes: 0, rows: 600))
        XCTAssertTrue(StepsHourMerge.walkingByHour([], heartRate: [], offsetSec: edt).isEmpty)
    }

    func testUsualRowsIsTheMedianRecordedHour() {
        let hours = [3_600, 3_590, 0, 1_200, 3_500].map { StepsHourMerge.HourWalk(walkingMinutes: 0, rows: $0) }
        XCTAssertEqual(StepsHourMerge.usualRows(hours), 3_590)
        XCTAssertEqual(StepsHourMerge.usualRows([]), 0)
        XCTAssertEqual(StepsHourMerge.minCarriedRows(usualRows: 3_600), 1_800)
        // A strap that stores bursts still gets a usable floor.
        XCTAssertEqual(StepsHourMerge.minCarriedRows(usualRows: 40), StepsHourMerge.minRowsFloor)
    }

    // MARK: - Calibration

    func testCarriedHourNeedsAWalkUsualRowsSomeStrapWalkingAndAnAwakeWearer() {
        let walk = StepsHourMerge.HourWalk(walkingMinutes: 12, rows: 3_500)
        XCTAssertTrue(StepsHourMerge.isCarried(phoneSteps: 300, walk: walk, minRows: 1_800, blockedFraction: 0))
        XCTAssertFalse(StepsHourMerge.isCarried(phoneSteps: 299, walk: walk, minRows: 1_800, blockedFraction: 0))
        XCTAssertFalse(StepsHourMerge.isCarried(phoneSteps: 900, walk: .init(walkingMinutes: 12, rows: 1_000),
                                                minRows: 1_800, blockedFraction: 0))
        // The phone walked but the strap saw no walking (hands on a trolley): no ratio to learn from.
        XCTAssertFalse(StepsHourMerge.isCarried(phoneSteps: 900, walk: .init(walkingMinutes: 2, rows: 3_500),
                                                minRows: 1_800, blockedFraction: 0))
        XCTAssertTrue(StepsHourMerge.isCarried(phoneSteps: 900, walk: walk, minRows: 1_800, blockedFraction: 0.25))
        XCTAssertFalse(StepsHourMerge.isCarried(phoneSteps: 900, walk: walk, minRows: 1_800, blockedFraction: 0.5))
    }

    func testCalibrationWaitsForEnoughCarriedHours() {
        let hours = Array(repeating: StepsHourMerge.CalibrationHour(walkingMinutes: 10, steps: 1_000), count: 23)
        XCTAssertNil(StepsHourMerge.calibrate(hours))
        XCTAssertNotNil(StepsHourMerge.calibrate(hours + [.init(walkingMinutes: 10, steps: 1_000)]))
    }

    func testCalibrationIsTheMedianPaceWeightedByWalkingMinutes() {
        var hours = Array(repeating: StepsHourMerge.CalibrationHour(walkingMinutes: 10, steps: 1_000), count: 24)
        let tight = StepsHourMerge.calibrate(hours)
        XCTAssertEqual(tight?.stepsPerMinute ?? 0, 100, accuracy: 1e-9)
        XCTAssertEqual(tight?.sampleHours, 24)
        // 24 of 120 hours, no spread: 0.5 * 0.2 + 0.5 * 1.
        XCTAssertEqual(tight?.confidence ?? 0, 0.6, accuracy: 1e-9)

        // Hours the phone was only carried for part of read low; a minority of them cannot drag the median.
        hours += Array(repeating: StepsHourMerge.CalibrationHour(walkingMinutes: 10, steps: 300), count: 10)
        XCTAssertEqual(StepsHourMerge.calibrate(hours)?.stepsPerMinute ?? 0, 100, accuracy: 1e-9)
        // Hours with almost no strap walking are left out rather than producing huge ratios.
        let barely = hours + Array(repeating: StepsHourMerge.CalibrationHour(walkingMinutes: 1, steps: 900), count: 40)
        XCTAssertEqual(StepsHourMerge.calibrate(barely)?.stepsPerMinute ?? 0, 100, accuracy: 1e-9)
    }

    func testThePaceAloneNeedsNoMinimumButStaysPlausible() {
        let few = Array(repeating: StepsHourMerge.CalibrationHour(walkingMinutes: 10, steps: 1_050), count: 3)
        XCTAssertEqual(StepsHourMerge.pace(few) ?? 0, 105, accuracy: 1e-9)
        XCTAssertNil(StepsHourMerge.calibrate(few), "the calibration still waits for enough hours")
        XCTAssertNil(StepsHourMerge.pace([]))
        XCTAssertNil(StepsHourMerge.pace([.init(walkingMinutes: 2, steps: 900)]), "too little strap walking to use")
        XCTAssertNil(StepsHourMerge.pace([.init(walkingMinutes: 50, steps: 1_000)]), "20 steps a minute")
    }

    func testAPaceNoWalkerHasMeansTheDetectorIsNotSeeingWalking() {
        let slow = Array(repeating: StepsHourMerge.CalibrationHour(walkingMinutes: 50, steps: 1_000), count: 30)
        XCTAssertNil(StepsHourMerge.calibrate(slow), "20 steps a minute")
        let fast = Array(repeating: StepsHourMerge.CalibrationHour(walkingMinutes: 3, steps: 1_500), count: 30)
        XCTAssertNil(StepsHourMerge.calibrate(fast), "500 steps a minute")
    }

    // MARK: - Estimate

    func testEstimateIsWalkingMinutesAtTheWearersPaceAndIsCapped() {
        XCTAssertEqual(StepsHourMerge.estimate(walkingMinutes: 12, stepsPerMinute: 101.5, openFraction: 1), 1_218)
        XCTAssertEqual(StepsHourMerge.estimate(walkingMinutes: 12, stepsPerMinute: 100, openFraction: 0.25), 300)
        XCTAssertEqual(StepsHourMerge.estimate(walkingMinutes: 12, stepsPerMinute: 100, openFraction: 0), 0)
        XCTAssertEqual(StepsHourMerge.estimate(walkingMinutes: 0, stepsPerMinute: 100, openFraction: 1), 0)
        XCTAssertEqual(StepsHourMerge.estimate(walkingMinutes: 12, stepsPerMinute: 0, openFraction: 1), 0)
        XCTAssertEqual(StepsHourMerge.estimate(walkingMinutes: 120, stepsPerMinute: 100, openFraction: 1),
                       StepsHourMerge.maxHourSteps)
    }

    // MARK: - The merge rule

    func testTheBandTakesAnHourOnlyWhenItClearlyBeatsThePhone() {
        // A carried hour where the two roughly agree keeps the phone's count.
        XCTAssertEqual(StepsHourMerge.added(phone: 1_000, band: 1_400), 0)
        XCTAssertEqual(StepsHourMerge.added(phone: 1_000, band: 1_499), 0)
        XCTAssertEqual(StepsHourMerge.added(phone: 1_000, band: 1_500), 500)
        // Small counts need the 150-step margin, not 50%.
        XCTAssertEqual(StepsHourMerge.added(phone: 100, band: 249), 0)
        XCTAssertEqual(StepsHourMerge.added(phone: 100, band: 250), 150)
        // The phone left at home.
        XCTAssertEqual(StepsHourMerge.added(phone: 0, band: 149), 0)
        XCTAssertEqual(StepsHourMerge.added(phone: 0, band: 2_900), 2_900)
        // The band never takes steps away.
        XCTAssertEqual(StepsHourMerge.added(phone: 2_000, band: 100), 0)
        XCTAssertEqual(StepsHourMerge.added(phone: -5, band: -5), 0)
    }

    func testSettledHoursCountOnlyFinishedHours() {
        let day = ts("2026-09-29T00:00:00-04:00")
        XCTAssertEqual(StepsHourMerge.settledHours(dayStart: day, settledUntil: day - 1), 0)
        XCTAssertEqual(StepsHourMerge.settledHours(dayStart: day, settledUntil: day + 3_599), 0)
        XCTAssertEqual(StepsHourMerge.settledHours(dayStart: day, settledUntil: day + 3_600), 1)
        XCTAssertEqual(StepsHourMerge.settledHours(dayStart: day, settledUntil: day + 15 * 3_600 + 10), 15)
        XCTAssertEqual(StepsHourMerge.settledHours(dayStart: day, settledUntil: day + 5 * 86_400), 24)
    }

    func testAddedByHourComparesWithTheLargerPhoneSideCountAndStopsAtTheSettledHour() {
        var phone = Array(repeating: 0, count: 24), health = phone, band = phone
        phone[8] = 1_000; band[8] = 1_100          // carried, agrees
        health[12] = 900; phone[12] = 200; band[12] = 1_000   // Health saw the walk (a Watch): no fill
        band[18] = 2_900; phone[18] = 30           // left at home: filled
        band[22] = 3_000                           // not settled yet: nothing
        let added = StepsHourMerge.addedByHour(phone: phone, health: health, band: band, settledHours: 22)
        XCTAssertEqual(added[8], 0)
        XCTAssertEqual(added[12], 0)
        XCTAssertEqual(added[18], 2_870)
        XCTAssertEqual(added[22], 0)
        XCTAssertEqual(added.reduce(0, +), 2_870)
        XCTAssertEqual(StepsHourMerge.addedByHour(phone: phone, health: nil, band: nil, settledHours: 24),
                       Array(repeating: 0, count: 24))
        // A short array is read as zeros past its end, never out of bounds.
        XCTAssertEqual(StepsHourMerge.addedByHour(phone: [5], health: nil, band: [0, 400], settledHours: 24)[1], 400)
    }

    func testFillByDayBucketsPerLocalDayAndLeavesOutDaysTheBandAddsNothingTo() {
        let rows: (String) -> Int = { self.ts($0) }
        let phone: [(ts: Int, steps: Int)] = [
            (rows("2026-09-28T09:00:00-04:00"), 2_000),
            (rows("2026-09-29T09:00:00-04:00"), 1_800),
        ]
        let health: [(ts: Int, steps: Int)] = []
        let band: [(ts: Int, steps: Int)] = [
            (rows("2026-09-28T09:00:00-04:00"), 2_100),   // agrees: nothing that day
            (rows("2026-09-29T09:00:00-04:00"), 1_900),   // agrees
            (rows("2026-09-29T18:00:00-04:00"), 2_900),   // phone at home
            (rows("2026-09-29T21:00:00-04:00"), 1_000),   // after the settled point
        ]
        let fill = StepsHourMerge.fillByDay(phoneRows: phone, healthRows: health, bandRows: band,
                                            calendar: newYork, settledUntil: rows("2026-09-29T20:00:00-04:00"))
        XCTAssertNil(fill["2026-09-28"])
        XCTAssertEqual(fill["2026-09-29"]?[18], 2_900)
        XCTAssertEqual(fill["2026-09-29"]?[21], 0)
        XCTAssertEqual(fill["2026-09-29"]?.reduce(0, +), 2_900)
        XCTAssertTrue(StepsHourMerge.fillByDay(phoneRows: phone, healthRows: health, bandRows: [],
                                               calendar: newYork, settledUntil: .max).isEmpty)
    }

    func testBucketsByDayMatchesTheSingleDayBucketsIncludingFallBack() {
        let rows: [(ts: Int, steps: Int)] = [
            (ts("2026-11-01T01:00:00-04:00"), 10),   // the first 1 AM
            (ts("2026-11-01T01:00:00-05:00"), 5),    // the repeated 1 AM, summed into the same bucket
            (ts("2026-11-01T23:00:00-05:00"), 7),
            (ts("2026-11-02T00:00:00-05:00"), 3),
            (ts("2026-11-01T12:00:00-05:00"), -1),   // not a count
        ]
        let byDay = StepsHourMerge.bucketsByDay(rows, calendar: newYork)
        XCTAssertEqual(byDay["2026-11-01"], StepsHourly.buckets(rows: rows, day: "2026-11-01", calendar: newYork))
        XCTAssertEqual(byDay["2026-11-01"]?[1], 15)
        XCTAssertEqual(byDay["2026-11-02"]?[0], 3)
    }

    // MARK: - Blocked time

    func testCoveredFractionCountsOverlapsOnce() {
        let h = ts("2026-09-29T22:00:00-04:00")
        XCTAssertEqual(StepsHourMerge.coveredFraction(hourStart: h, intervals: []), 0)
        XCTAssertEqual(StepsHourMerge.coveredFraction(hourStart: h, intervals: [(h - 7_200, h + 7_200)]), 1)
        XCTAssertEqual(StepsHourMerge.coveredFraction(hourStart: h, intervals: [(h + 2_700, h + 9_000)]), 0.25)
        // Sleep and a workout that overlap each other: the shared 15 minutes count once.
        let covered = StepsHourMerge.coveredFraction(hourStart: h, intervals: [(h, h + 1_800), (h + 900, h + 2_700)])
        XCTAssertEqual(covered, 0.75, accuracy: 1e-12)
        XCTAssertEqual(StepsHourMerge.coveredFraction(hourStart: h, intervals: [(h + 3_600, h + 7_200)]), 0)
    }

    func testNoFootfallSportsAreCyclingStrengthRowingAndSwimming() {
        for sport in ["Cycling", "Indoor Cycling", "Mountain Biking", "Spinning", "TraditionalStrengthTraining",
                      "Weightlifting", "Powerlifting", "Rowing", "Kayaking", "Paddleboarding", "Swimming"] {
            XCTAssertTrue(StepsHourMerge.isNoFootfallSport(sport), sport)
        }
        for sport in ["Running", "Walking", "Hiking", "Treadmill walk", "Soccer", "Tennis", "detected", ""] {
            XCTAssertFalse(StepsHourMerge.isNoFootfallSport(sport), sport)
        }
    }

    // MARK: - Hourly walking cache

    func testCacheRoundTripsExactly() {
        let entries: [String: StepsHourWalkCache.Entry] = [
            "2026-09-29": (key: "whoop-abc|3600|1790000000",
                           hours: [1_790_000_000: .init(walkingMinutes: 12, rows: 3_600),
                                   1_790_003_600: .init(walkingMinutes: 0, rows: 1_201)]),
            "2026-09-30": (key: "whoop-abc|0|0", hours: [:]),
        ]
        let raw = StepsHourWalkCache.serialize(entries)
        let back = StepsHourWalkCache.deserialize(raw)
        XCTAssertEqual(back.count, 2)
        XCTAssertEqual(back["2026-09-29"]?.key, "whoop-abc|3600|1790000000")
        XCTAssertEqual(back["2026-09-29"]?.hours, entries["2026-09-29"]?.hours)
        XCTAssertEqual(back["2026-09-30"]?.hours, [:])
        XCTAssertEqual(StepsHourWalkCache.serialize(back), raw, "an unchanged cache renders identically")
    }

    func testCacheDiscardsWhatItCannotVouchFor() {
        XCTAssertTrue(StepsHourWalkCache.deserialize("").isEmpty)
        XCTAssertTrue(StepsHourWalkCache.deserialize("stepsHourWalk v0\n2026-09-29\tk|1|2\t").isEmpty)
        let raw = "stepsHourWalk v\(StepsHourWalkCache.foldVersion)\n"
            + "2026-09-29\tk|1|2\t100:x:5\n"
            + "2026-09-30\tk|1|2\t100:7:3600"
        let parsed = StepsHourWalkCache.deserialize(raw)
        XCTAssertNil(parsed["2026-09-29"], "a malformed day is dropped and re-split")
        XCTAssertEqual(parsed["2026-09-30"]?.hours[100], .init(walkingMinutes: 7, rows: 3_600))
    }

    func testOwnerComesBackFromTheDailyFoldKey() {
        let key = StepsMotionCache.cacheKey(owner: "whoop-1234", gravityCount: 86_000, gravityMaxTs: 1_790_000_000)
        XCTAssertEqual(StepsHourWalkCache.owner(fromCacheKey: key), "whoop-1234")
        XCTAssertEqual(StepsHourWalkCache.owner(fromCacheKey: "odd|id|5|6"), "odd|id")
        XCTAssertNil(StepsHourWalkCache.owner(fromCacheKey: "|5|6"))
        XCTAssertNil(StepsHourWalkCache.owner(fromCacheKey: "whoop|x|6"))
        XCTAssertNil(StepsHourWalkCache.owner(fromCacheKey: "nothing"))
    }

    // MARK: - The resolver and the chart

    func testResolverAddsTheFillToPhoneSideDaysOnly() {
        func resolve(_ c: StepDayCandidates, today: Bool = false) -> ResolvedStepDay? {
            StepsResolver.resolve(day: "2026-09-29", candidates: c, isInProgressDay: today)
        }
        let health = resolve(StepDayCandidates(healthKit: 5_980, bandFill: 4_510))
        XCTAssertEqual(health, ResolvedStepDay(day: "2026-09-29", steps: 10_490, source: .healthKit, bandSteps: 4_510))
        XCTAssertEqual(health?.sourceSteps, 5_980)
        XCTAssertEqual(resolve(StepDayCandidates(phonePedometer: 3_000, bandFill: 200))?.steps, 3_200)
        // The in-progress day keeps its live-phone exception, then takes the fill.
        let live = resolve(StepDayCandidates(healthKit: 2_000, phonePedometer: 2_500, bandFill: 300), today: true)
        XCTAssertEqual(live?.source, .phonePedometer)
        XCTAssertEqual(live?.steps, 2_800)
        // A strap counter or a strap-estimate day takes no fill: neither depends on the phone being carried.
        XCTAssertEqual(resolve(StepDayCandidates(strapCounter: 9_000, bandFill: 1_000))?.steps, 9_000)
        XCTAssertEqual(resolve(StepDayCandidates(strapEstimate: 7_000, bandFill: 1_000))?.bandSteps, 0)
        // No fill, a zero fill and a fill on an empty day change nothing.
        XCTAssertEqual(resolve(StepDayCandidates(healthKit: 5_000))?.bandSteps, 0)
        XCTAssertEqual(resolve(StepDayCandidates(healthKit: 5_000, bandFill: 0))?.steps, 5_000)
        XCTAssertNil(resolve(StepDayCandidates(bandFill: 800)))
    }

    func testChartStacksTheFillAndFindsThePeakWithIt() {
        var phone = Array(repeating: 0, count: 24)
        phone[8] = 1_450; phone[18] = 30
        var filled = Array(repeating: 0, count: 24)
        filled[18] = 2_870
        let chart = StepsHourly.chart(daySource: .healthKit, dayTotal: 1_480, hours: [.healthKit: phone],
                                      currentHour: nil, filled: filled)
        XCTAssertEqual(chart?.bars, phone)
        XCTAssertEqual(chart?.filled, filled)
        XCTAssertEqual(chart?.totals[18], 2_900)
        XCTAssertEqual(chart?.peakHour, 18)
        XCTAssertEqual(chart?.hasFill, true)
        // Without a fill (or a malformed one) the chart is the one it always was.
        let plain = StepsHourly.chart(daySource: .healthKit, dayTotal: 1_480, hours: [.healthKit: phone], currentHour: nil)
        XCTAssertEqual(plain?.hasFill, false)
        XCTAssertEqual(plain?.peakHour, 8)
        XCTAssertEqual(StepsHourly.Chart(bars: phone, source: .healthKit, matchesDaySource: true, currentHour: nil,
                                         filled: [1, 2]).filled, Array(repeating: 0, count: 24))
    }
}
