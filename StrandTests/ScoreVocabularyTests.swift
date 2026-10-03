import XCTest
@testable import Strand

/// One vocabulary on the WHOOP-style path (docs/zeno/WHOOP_UI_SPEC.md §0.3): under the iPhone's Pulse
/// interface the scores are Recovery / Strain / Sleep and Strain is shown on 0-21 everywhere, while the
/// classic interface and the Mac keep NOOP's Charge / Effort / Rest and the stored Effort-scale setting.
final class ScoreVocabularyTests: XCTestCase {

    func testPickReturnsTheFormOfTheVocabulary() {
        XCTAssertEqual(ScoreVocabulary.classic.pick(classic: "Charge", pulse: "Recovery"), "Charge")
        XCTAssertEqual(ScoreVocabulary.pulse.pick(classic: "Charge", pulse: "Recovery"), "Recovery")
    }

    /// The Mac has only the classic interface, whatever the defaults hold.
    func testTheMacIsAlwaysClassic() {
        #if os(macOS)
        XCTAssertEqual(ScoreVocabulary.current, .classic)
        XCTAssertEqual(ScoreVocabulary.appName, "NOOP")
        #endif
    }

    func testPulseForcesWhoopsStrainScaleWhateverTheSetting() {
        for raw in ["", "hundred", "whoop", "nonsense"] {
            XCTAssertEqual(UnitPrefs.resolveEffortScale(raw, vocabulary: .pulse), .whoop, "raw \(raw)")
        }
    }

    func testClassicFollowsTheStoredSetting() {
        XCTAssertEqual(UnitPrefs.resolveEffortScale("", vocabulary: .classic), .hundred)
        XCTAssertEqual(UnitPrefs.resolveEffortScale("hundred", vocabulary: .classic), .hundred)
        XCTAssertEqual(UnitPrefs.resolveEffortScale("whoop", vocabulary: .classic), .whoop)
        XCTAssertEqual(UnitPrefs.resolveEffortScale("nonsense", vocabulary: .classic), .hundred)
    }

    /// The coach's vocabulary is the same switch, so a reply and the screen it is read on cannot disagree.
    func testTheCoachSpeaksTheSameVocabulary() {
        let pulse: CoachVocabulary = .pulse
        XCTAssertEqual(pulse, ScoreVocabulary.pulse)
    }
}
