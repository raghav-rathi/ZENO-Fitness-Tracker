import XCTest
@testable import StrandAnalytics

final class PulseLevelsTests: XCTestCase {

    func testTheLadderHasThirtyRisingRungsStartingAtZero() {
        XCTAssertEqual(PulseLevels.thresholds.count, PulseLevels.maxLevel)
        XCTAssertEqual(PulseLevels.thresholds.first, 0)
        XCTAssertEqual(PulseLevels.thresholds.last, 3000)
        XCTAssertEqual(zip(PulseLevels.thresholds, PulseLevels.thresholds.dropFirst()).filter { $0 >= $1 }.count, 0)
    }

    func testEveryDataPointTheSpecCheckedLandsOnItsLevel() {
        // WHOOP_UI_SPEC §3.30: L22 at 1226, L24 at 1724, L25 at 1907, L27 at 2344, "1 more" at 2999.
        XCTAssertEqual(PulseLevels.level(forRecoveries: 1226), 22)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 1724), 24)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 1907), 25)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 2344), 27)
        let almost = PulseLevels.progress(recoveries: 2999)
        XCTAssertEqual(almost.level, 29)
        XCTAssertEqual(almost.nextLevel, 30)
        XCTAssertEqual(almost.remaining, 1)
    }

    func testBoundariesBelongToTheLevelTheyOpen() {
        XCTAssertEqual(PulseLevels.level(forRecoveries: 0), 1)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 3), 1)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 4), 2)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 29), 5)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 30), 6)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 3000), 30)
        XCTAssertEqual(PulseLevels.level(forRecoveries: 9999), 30)
        XCTAssertEqual(PulseLevels.level(forRecoveries: -5), 1)
    }

    func testProgressRunsFromTheLevelMinimumToTheNext() {
        let p = PulseLevels.progress(recoveries: 120)
        XCTAssertEqual(p.level, 11)
        XCTAssertEqual(p.levelMinimum, 100)
        XCTAssertEqual(p.nextMinimum, 125)
        XCTAssertEqual(p.remaining, 5)
        XCTAssertEqual(p.fraction, 0.8, accuracy: 1e-9)
        XCTAssertEqual(p.tier, .silver)
        XCTAssertFalse(p.isMax)
    }

    func testTheTopLevelIsFullAndHasNothingNext() {
        let p = PulseLevels.progress(recoveries: 3400)
        XCTAssertTrue(p.isMax)
        XCTAssertNil(p.nextLevel)
        XCTAssertNil(p.remaining)
        XCTAssertEqual(p.fraction, 1)
        XCTAssertEqual(p.tier, .diamond)
    }

    func testTiersAreFiveLevelsEachAndStarsFollowTheTier() {
        XCTAssertEqual(PulseLevels.tier(forLevel: 1), .beginner)
        XCTAssertEqual(PulseLevels.tier(forLevel: 5), .beginner)
        XCTAssertEqual(PulseLevels.tier(forLevel: 6), .bronze)
        XCTAssertEqual(PulseLevels.tier(forLevel: 16), .gold)
        XCTAssertEqual(PulseLevels.tier(forLevel: 25), .platinum)
        XCTAssertEqual(PulseLevels.tier(forLevel: 30), .diamond)
        // Spec: medal stars equal the tier index (Bronze 1, Gold 3, Platinum 4, Diamond 5).
        XCTAssertEqual(PulseLevels.Tier.bronze.rawValue, 1)
        XCTAssertEqual(PulseLevels.Tier.gold.rawValue, 3)
        XCTAssertEqual(PulseLevels.Tier.platinum.rawValue, 4)
        XCTAssertEqual(PulseLevels.Tier.diamond.rawValue, 5)
    }

    func testMaterialsNameTheFirstSixLevelsThenFollowTheTier() {
        let firstSix = (1...6).map(PulseLevels.material(forLevel:))
        XCTAssertEqual(firstSix, [.carbon, .iron, .steel, .gunmetal, .titanium, .bronze])
        XCTAssertEqual(PulseLevels.material(forLevel: 10), .bronze)
        XCTAssertEqual(PulseLevels.material(forLevel: 11), .silver)
        XCTAssertEqual(PulseLevels.material(forLevel: 22), .platinum)
        XCTAssertEqual(PulseLevels.material(forLevel: 29), .diamond)
    }

    func testTierStartsAreTheFirstLevelOfEachTierAfterBeginner() {
        XCTAssertEqual((1...30).filter(PulseLevels.isTierStart), [6, 11, 16, 21, 26])
    }

    func testOnlyRealScoresCount() {
        XCTAssertEqual(PulseLevels.scoredRecoveries([50, nil, 70, .nan, .infinity, 0]), 3)
        XCTAssertEqual(PulseLevels.scoredRecoveries([]), 0)
    }

    func testMinimumIsNilOutsideTheLadder() {
        XCTAssertEqual(PulseLevels.minimum(forLevel: 27), 2250)
        XCTAssertNil(PulseLevels.minimum(forLevel: 0))
        XCTAssertNil(PulseLevels.minimum(forLevel: 31))
    }
}
