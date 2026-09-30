import XCTest
import StrandAnalytics
@testable import Strand

/// The app-side seams of the Steps feature: folding the live pedometer total into a day, refreshing part of
/// the window, the provenance ids the combined Explore detail labels, and the display helpers that must not
/// slip a day west of UTC.
@MainActor
final class StepsInputsTests: XCTestCase {

    func testLiveFoldKeepsTheLargerRunningTotal() {
        var inputs = StepsInputs()
        inputs.candidates["2026-09-30"] = StepDayCandidates(healthKit: 3_000, phonePedometer: 2_500)
        inputs.distanceM["2026-09-30"] = 1_900
        inputs.foldLivePhone(LivePhoneSteps(day: "2026-09-30", steps: 2_800, distanceM: 2_100, floorsUp: 4))
        XCTAssertEqual(inputs.candidates["2026-09-30"]?.phonePedometer, 2_800)
        XCTAssertEqual(inputs.candidates["2026-09-30"]?.healthKit, 3_000, "other sources are untouched")
        XCTAssertEqual(inputs.distanceM["2026-09-30"], 2_100)
        XCTAssertEqual(inputs.floorsUp["2026-09-30"], 4)

        // A stale live total never pulls a fresher banked one down.
        inputs.foldLivePhone(LivePhoneSteps(day: "2026-09-30", steps: 1_000, distanceM: 500, floorsUp: 1))
        XCTAssertEqual(inputs.candidates["2026-09-30"]?.phonePedometer, 2_800)
        XCTAssertEqual(inputs.distanceM["2026-09-30"], 2_100)
        XCTAssertEqual(inputs.floorsUp["2026-09-30"], 4)
    }

    func testLiveFoldCreatesADayNothingElseCounted() {
        var inputs = StepsInputs()
        inputs.foldLivePhone(LivePhoneSteps(day: "2026-09-30", steps: 120, distanceM: nil, floorsUp: nil))
        XCTAssertEqual(inputs.candidates["2026-09-30"], StepDayCandidates(phonePedometer: 120))
        XCTAssertNil(inputs.distanceM["2026-09-30"])
        // The live total is today's in-progress count, so it beats a Health import that has not caught up.
        inputs.candidates["2026-09-30"]?.healthKit = 100
        XCTAssertEqual(inputs.resolved(inProgressDay: "2026-09-30").first?.source, .phonePedometer)
    }

    func testReplacingSwapsOnlyTheRefreshedDays() {
        var window = StepsInputs()
        window.candidates = ["2026-09-01": StepDayCandidates(healthKit: 1),
                             "2026-09-29": StepDayCandidates(healthKit: 2),
                             "2026-09-30": StepDayCandidates(healthKit: 3)]
        window.floorsUp = ["2026-09-01": 9, "2026-09-30": 9]
        window.strapEstimateSourceId = ["2026-09-29": "old"]
        var fresh = StepsInputs()
        fresh.candidates = ["2026-09-30": StepDayCandidates(phonePedometer: 30),
                            "2026-08-01": StepDayCandidates(healthKit: 99)]  // outside the range: ignored
        window.replacing(from: "2026-09-29", to: "2026-09-30", with: fresh)
        XCTAssertEqual(window.candidates["2026-09-01"], StepDayCandidates(healthKit: 1))
        XCTAssertNil(window.candidates["2026-09-29"], "a refreshed day the new read no longer has is dropped")
        XCTAssertEqual(window.candidates["2026-09-30"], StepDayCandidates(phonePedometer: 30))
        XCTAssertNil(window.candidates["2026-08-01"])
        XCTAssertEqual(window.floorsUp, ["2026-09-01": 9])
        XCTAssertTrue(window.strapEstimateSourceId.isEmpty)
    }

    func testStoredValuesBecomeCountsOnlyWhenTheyCanBeOne() {
        XCTAssertEqual(StepsInputs.count(8_421.6), 8_422)
        XCTAssertEqual(StepsInputs.count(0), 0)
        XCTAssertNil(StepsInputs.count(-1))
        XCTAssertNil(StepsInputs.count(.nan))
        XCTAssertNil(StepsInputs.count(.infinity))
        XCTAssertNil(StepsInputs.count(1e18), "an absurd value must not trap the Int conversion")
    }

    func testProvenanceIdsSpeakTheReadingsTableVocabulary() {
        var inputs = StepsInputs()
        inputs.strapCounterSourceId["2026-09-28"] = "whoop-abc"
        inputs.strapEstimateSourceId["2026-09-29"] = "my-whoop-noop"
        func id(_ day: String, _ source: StepSource) -> String {
            inputs.provenanceId(for: ResolvedStepDay(day: day, steps: 1, source: source))
        }
        XCTAssertEqual(id("2026-09-30", .healthKit), "apple-health")
        XCTAssertEqual(id("2026-09-30", .phonePedometer), StepsPrefs.phoneDeviceId)
        XCTAssertEqual(id("2026-09-28", .strapCounter), "whoop-abc")
        XCTAssertEqual(id("2026-09-29", .strapEstimate), "my-whoop-noop")
        // The readings table names the phone rather than printing its raw id.
        XCTAssertEqual(TodayView.provenanceDisplayLabel(rawSource: StepsPrefs.phoneDeviceId, deviceId: "my-whoop"),
                       "iPhone")
    }

    func testCombinedCandidatesFollowTheResolverPrecedence() {
        XCTAssertEqual(Repository.stepSourceCandidates.map(\.source),
                       ["apple-health", StepsPrefs.phoneDeviceId, "my-whoop", "my-whoop-noop"])
    }

    func testDayLabelsDoNotSlipWestOfUTC() {
        let saved = NSTimeZone.default
        defer { NSTimeZone.default = saved }
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        // 28 Sep 2026 is a Monday; a device-zone formatter would print Sunday the 27th here.
        XCTAssertTrue(StepsLabels.short("2026-09-28").contains("28"), StepsLabels.short("2026-09-28"))
        XCTAssertTrue(StepsLabels.full("2026-09-28").contains("28"), StepsLabels.full("2026-09-28"))
        XCTAssertEqual(StepsLabels.relative("2026-09-30", today: "2026-09-30"), String(localized: "Today"))
        XCTAssertEqual(StepsLabels.relative("2026-09-29", today: "2026-09-30"), String(localized: "Yesterday"))
        XCTAssertEqual(StepsLabels.weekdayInitial("not-a-day"), "·")
    }

    func testCompactFormatForAxisTags() {
        XCTAssertEqual(StepsFormat.compact(900), "900")
        XCTAssertEqual(StepsFormat.compact(1_000), "1k")
        XCTAssertEqual(StepsFormat.compact(8_500), "8.5k")
        XCTAssertEqual(StepsFormat.compact(12_000), "12k")
        XCTAssertEqual(StepsFormat.compact(12_345), "12.3k")
    }

    func testSparseAxisTicksCoverBothEnds() {
        XCTAssertEqual(StepsDailyBarsView.sparseTicks(count: 30), [0, 9, 19, 29])
        XCTAssertEqual(StepsDailyBarsView.sparseTicks(count: 2), [0, 1])
        XCTAssertEqual(StepsDailyBarsView.sparseTicks(count: 1), [0])
        XCTAssertEqual(StepsDailyBarsView.sparseTicks(count: 0), [])
    }

    func testStoredGoalIsClamped() {
        let saved = UserDefaults.standard.object(forKey: StepsPrefs.goalKey)
        defer { UserDefaults.standard.set(saved, forKey: StepsPrefs.goalKey) }
        UserDefaults.standard.removeObject(forKey: StepsPrefs.goalKey)
        XCTAssertEqual(StepsPrefs.goal, StepGoal.defaultGoal)
        UserDefaults.standard.set(99_999, forKey: StepsPrefs.goalKey)
        XCTAssertEqual(StepsPrefs.goal, 30_000)
        UserDefaults.standard.set(250, forKey: StepsPrefs.goalKey)
        XCTAssertEqual(StepsPrefs.goal, 1_000)
    }
}
