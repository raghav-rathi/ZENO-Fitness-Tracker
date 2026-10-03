import Foundation
import XCTest
@testable import StrandAnalytics

final class ActivityStrainTargetTests: XCTestCase {
    /// `trimpToStrain` rounds to two decimals, so a round trip may drift by a rounding step.
    private let tolerance = 0.02

    func testRequiredThenEstimatedLandsOnTheTarget() throws {
        for (day, target) in [(0.0, 57.0), (25.0, 57.0), (48.0, 76.0), (60.0, 66.7), (10.0, 33.0)] {
            let required = try XCTUnwrap(ActivityStrainTarget.requiredActivityEffort(dayEffort: day,
                                                                                     targetDayEffort: target))
            let estimated = try XCTUnwrap(ActivityStrainTarget.estimatedDayEffort(dayEffort: day,
                                                                                 activityEffort: required))
            XCTAssertEqual(estimated, target, accuracy: tolerance, "day \(day) → target \(target)")
        }
    }

    func testAnEmptyDayNeedsTheWholeTargetFromTheActivity() throws {
        let required = try XCTUnwrap(ActivityStrainTarget.requiredActivityEffort(dayEffort: 0, targetDayEffort: 62))
        XCTAssertEqual(required, 62, accuracy: tolerance)
    }

    func testADayAlreadyAtOrPastTheTargetNeedsNothing() {
        XCTAssertEqual(ActivityStrainTarget.requiredActivityEffort(dayEffort: 70, targetDayEffort: 70), 0)
        XCTAssertEqual(ActivityStrainTarget.requiredActivityEffort(dayEffort: 80, targetDayEffort: 70), 0)
    }

    func testTheLogMapMakesTheActivityNeedMoreThanTheGapOnTheAxis() throws {
        // Strain is log-compressed: closing the last few points of a busy day takes far more load than
        // the same points at the bottom of the axis, so the activity reads well above the plain gap.
        let required = try XCTUnwrap(ActivityStrainTarget.requiredActivityEffort(dayEffort: 60, targetDayEffort: 76))
        XCTAssertGreaterThan(required, 76 - 60)
        XCTAssertLessThan(required, 76)
    }

    func testABusierDayNeedsASmallerActivity() throws {
        var previous = Double.infinity
        for day in stride(from: 0.0, through: 70.0, by: 10.0) {
            let required = try XCTUnwrap(ActivityStrainTarget.requiredActivityEffort(dayEffort: day,
                                                                                     targetDayEffort: 76))
            XCTAssertLessThanOrEqual(required, previous)
            previous = required
        }
    }

    func testANullActivityLeavesTheDayAsItWas() throws {
        let estimated = try XCTUnwrap(ActivityStrainTarget.estimatedDayEffort(dayEffort: 54.3, activityEffort: 0))
        XCTAssertEqual(estimated, 54.3, accuracy: tolerance)
    }

    func testTwoEqualLoadsReadBelowTheirSum() throws {
        let estimated = try XCTUnwrap(ActivityStrainTarget.estimatedDayEffort(dayEffort: 40, activityEffort: 40))
        XCTAssertGreaterThan(estimated, 40)
        XCTAssertLessThan(estimated, 80)
    }

    func testTheEstimateNeverReadsPastTheTopOfTheAxis() throws {
        let estimated = try XCTUnwrap(ActivityStrainTarget.estimatedDayEffort(dayEffort: 100, activityEffort: 100))
        XCTAssertEqual(estimated, StrainScorer.maxStrain)
    }

    func testABanisterDenominatorRoundTripsOnItsOwnAxis() throws {
        let d = StrainScorer.logMapDenominator(method: .banister, sex: "female")
        let required = try XCTUnwrap(ActivityStrainTarget.requiredActivityEffort(dayEffort: 35, targetDayEffort: 66,
                                                                                 denominator: d))
        let estimated = try XCTUnwrap(ActivityStrainTarget.estimatedDayEffort(dayEffort: 35, activityEffort: required,
                                                                             denominator: d))
        XCTAssertEqual(estimated, 66, accuracy: tolerance)
    }

    func testOutOfDomainInputsAreNoAnswer() {
        XCTAssertNil(ActivityStrainTarget.requiredActivityEffort(dayEffort: .nan, targetDayEffort: 50))
        XCTAssertNil(ActivityStrainTarget.requiredActivityEffort(dayEffort: 10, targetDayEffort: .infinity))
        XCTAssertNil(ActivityStrainTarget.requiredActivityEffort(dayEffort: 10, targetDayEffort: 50, denominator: 1))
        XCTAssertNil(ActivityStrainTarget.estimatedDayEffort(dayEffort: 10, activityEffort: .nan))
        XCTAssertNil(ActivityStrainTarget.estimatedDayEffort(dayEffort: 10, activityEffort: 5, denominator: 0.5))
    }

    func testTrainingStateAgainstTheOptimalRange() {
        let range = 52.0...67.0
        XCTAssertEqual(ActivityStrainTarget.trainingState(estimatedDay: 40, optimalRange: range), .restorative)
        XCTAssertEqual(ActivityStrainTarget.trainingState(estimatedDay: 52, optimalRange: range), .optimal)
        XCTAssertEqual(ActivityStrainTarget.trainingState(estimatedDay: 60, optimalRange: range), .optimal)
        XCTAssertEqual(ActivityStrainTarget.trainingState(estimatedDay: 67, optimalRange: range), .optimal)
        XCTAssertEqual(ActivityStrainTarget.trainingState(estimatedDay: 71, optimalRange: range), .overreaching)
    }
}
