import XCTest
@testable import StrandAnalytics

final class StrainContributorsTests: XCTestCase {

    /// %HRmax zones on a 200 bpm max: Z1 100-120, Z2 120-140, Z3 140-160, Z4 160-180, Z5 180+.
    private let zones = HRZones.zones(maxHR: 200)

    private func bucket(_ ts: Int, _ bpm: Double) -> StrainContributors.HRBucketMean {
        StrainContributors.HRBucketMean(ts: ts, bpm: bpm)
    }

    // MARK: - Time in zones

    func testZoneSecondsCreditsEachBucketToTheZoneOfItsMean() {
        let buckets = [bucket(0, 90), bucket(15, 110), bucket(30, 130), bucket(45, 150), bucket(60, 170),
                       bucket(75, 190), bucket(90, 200)]
        let seconds = StrainContributors.zoneSeconds(buckets: buckets, bucketSeconds: 15, zoneSet: zones)
        // 90 bpm is below Zone 1 and counts nowhere; 200 (HRmax) lands in Zone 5.
        XCTAssertEqual(seconds, [15, 15, 15, 15, 30])
    }

    func testZoneSecondsCountsASharedBucketStartOnce() {
        let buckets = [bucket(0, 150), bucket(0, 150), bucket(15, 150)]
        XCTAssertEqual(StrainContributors.zoneSeconds(buckets: buckets, bucketSeconds: 15, zoneSet: zones),
                       [0, 0, 30, 0, 0])
    }

    func testZoneSecondsIgnoresUnusableReadingsAndBucketSizes() {
        let buckets = [bucket(0, .nan), bucket(15, 0), bucket(30, -5), bucket(45, .infinity)]
        XCTAssertEqual(StrainContributors.zoneSeconds(buckets: buckets, bucketSeconds: 15, zoneSet: zones),
                       [0, 0, 0, 0, 0])
        XCTAssertEqual(StrainContributors.zoneSeconds(buckets: [bucket(0, 150)], bucketSeconds: 0, zoneSet: zones),
                       [0, 0, 0, 0, 0])
    }

    func testZoneSecondsWithNoHeartRateIsZeroNotMissing() {
        XCTAssertEqual(StrainContributors.zoneSeconds(buckets: [], bucketSeconds: 15, zoneSet: zones),
                       [0, 0, 0, 0, 0])
    }

    func testZoneGroupsSplitOneToThreeFromFourAndFive() {
        let groups = StrainContributors.zoneGroups([1, 2, 3, 4, 5])
        XCTAssertEqual(groups.lower, 6)
        XCTAssertEqual(groups.upper, 9)
        // A short array is padded with zero; a negative value counts as none.
        let short = StrainContributors.zoneGroups([-3, 2])
        XCTAssertEqual(short.lower, 2)
        XCTAssertEqual(short.upper, 0)
    }

    // MARK: - Strength Activity Time

    func testStrengthActivitiesFollowThePublishedListAndAppleNames() {
        let strength = ["Strength Training", "strength_training", "Strength", "Weightlifting", "Weight training",
                        "Powerlifting", "Bodybuilding", "Functional Fitness", "CrossFit", "HIIT",
                        "High Intensity Interval Training", "Pilates", "Reformer Pilates", "Barre", "Yoga",
                        "Hot Yoga", "Climbing", "Rock Climbing", "Bouldering", "Rucking", "Kayaking",
                        "Canoeing", "Jiu jitsu", "Jiu-Jitsu", "Breakdancing", "Kiteboarding", "Kite Boarding",
                        "Wheelchair", "Traditional Strength Training", "Functional Strength Training",
                        "Core Training", "F45 Training", "solidcore", "Box Fitness", "Manual Labor"]
        for sport in strength {
            XCTAssertTrue(StrainContributors.isStrengthActivity(sport), sport)
        }
        let other = ["Running", "Walking", "Cycling", "Swimming", "Rowing", "Stair climber", "Stair Climbing",
                     "Tennis", "Soccer", "Meditation", "Other", "", "   "]
        for sport in other {
            XCTAssertFalse(StrainContributors.isStrengthActivity(sport), sport)
        }
    }

    func testUnionSecondsCountsOverlapsOnce() {
        typealias Span = StrainContributors.Span
        XCTAssertEqual(StrainContributors.unionSeconds([Span(start: 0, end: 100), Span(start: 50, end: 150)]), 150)
        XCTAssertEqual(StrainContributors.unionSeconds([Span(start: 0, end: 10), Span(start: 10, end: 20)]), 20)
        XCTAssertEqual(StrainContributors.unionSeconds([Span(start: 20, end: 30), Span(start: 0, end: 10)]), 20)
        XCTAssertEqual(StrainContributors.unionSeconds([Span(start: 0, end: 100), Span(start: 10, end: 20)]), 100)
        XCTAssertEqual(StrainContributors.unionSeconds([Span(start: 50, end: 40), Span(start: 5, end: 5)]), 0)
        XCTAssertEqual(StrainContributors.unionSeconds([]), 0)
    }

    func testStrengthMinutesCountsOnlyStrengthSpansAndADoubleRecordingOnce() {
        typealias Span = StrainContributors.Span
        let day: [(span: Span, sport: String)] = [
            // The strap's bout and the Apple Health import of the same 45-minute lift.
            (Span(start: 0, end: 2_700), "Strength Training"),
            (Span(start: 300, end: 3_000), "Traditional Strength Training"),
            // A run never counts, even overlapping a lift.
            (Span(start: 2_000, end: 6_000), "Running"),
            // A separate 20-minute yoga session.
            (Span(start: 10_000, end: 11_200), "Yoga"),
        ]
        XCTAssertEqual(StrainContributors.strengthMinutes(day), 50 + 20, accuracy: 1e-9)
        XCTAssertEqual(StrainContributors.strengthMinutes([]), 0)
    }

    // MARK: - Band and standing

    func testBandFollowsThePrintedFigure() {
        XCTAssertEqual(StrainContributors.band(strain: 0), .light)
        XCTAssertEqual(StrainContributors.band(strain: 9.94), .light)
        // 9.96 prints "10.0": moderate, like the dial says.
        XCTAssertEqual(StrainContributors.band(strain: 9.96), .moderate)
        XCTAssertEqual(StrainContributors.band(strain: 13.9), .moderate)
        XCTAssertEqual(StrainContributors.band(strain: 13.96), .strenuous)
        XCTAssertEqual(StrainContributors.band(strain: 17.9), .strenuous)
        // The app's locale-aware formatter prints 17.95 as "18.0" (C printf would say "17.9"): the band
        // follows the dial, so it is all out.
        XCTAssertEqual(StrainContributors.band(strain: 17.95), .allOut)
        XCTAssertEqual(StrainContributors.band(strain: 18), .allOut)
        XCTAssertEqual(StrainContributors.band(strain: 21), .allOut)
    }

    func testPrintedFigureMatchesTheDialFormatterAtHalves() {
        for value in [17.95, 14.05, 9.95, 0.15, 0.05, 13.96] {
            let dial = String(format: "%.1f", locale: Locale(identifier: "en_GB"), value)
            XCTAssertEqual(StrainContributors.printedOneDecimal(value), Double(dial), "\(value)")
        }
    }

    func testStandingAgainstTheOptimalRange() {
        let range = 10.0...14.0
        XCTAssertEqual(StrainContributors.standing(strain: 4.2, range: range), .below)
        XCTAssertEqual(StrainContributors.standing(strain: 9.94, range: range), .below)
        XCTAssertEqual(StrainContributors.standing(strain: 9.96, range: range), .within)
        XCTAssertEqual(StrainContributors.standing(strain: 12, range: range), .within)
        XCTAssertEqual(StrainContributors.standing(strain: 14.04, range: range), .within)
        // Prints "14.0" with the app's formatter.
        XCTAssertEqual(StrainContributors.standing(strain: 14.05, range: range), .within)
        XCTAssertEqual(StrainContributors.standing(strain: 14.06, range: range), .above)
        XCTAssertEqual(StrainContributors.standing(strain: 20.7, range: range), .above)
    }
}
