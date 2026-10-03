import XCTest
import WhoopStore
@testable import Strand

/// The coach speaks the interface's names (`CoachVocabulary`): NOOP's charge / effort / rest in the classic
/// interface and on the Mac, byte for byte as before, and the Pulse interface's Recovery %, Strain (0-21) and
/// Sleep on an iPhone running Pulse, so a reply or a morning brief never contradicts the screen it is read on.
@MainActor
final class AICoachVocabularyTests: XCTestCase {

    private func engine(_ vocabulary: CoachVocabulary? = nil) -> AICoachEngine {
        UserDefaults.standard.removeObject(forKey: AICoachEngine.systemPromptKey)
        let engine = AICoachEngine(repo: Repository(deviceId: "test-aicoach-vocabulary"))
        engine.vocabularyOverride = vocabulary
        return engine
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: AICoachEngine.systemPromptKey)
        super.tearDown()
    }

    private func freshDefaults() -> UserDefaults {
        let name = "test.coachVocabulary.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    private let day = DailyMetric(day: "2026-06-01", totalSleepMin: 450, efficiency: 0.94, deepMin: 84,
                                  remMin: 114, lightMin: 252, disturbances: nil, restingHr: 52, avgHrv: 65,
                                  recovery: 67, strain: 58.2, exerciseCount: nil)

    // MARK: - Which interface

    /// `pulse.enabled` is ON when never written, as StrandiOSApp's `@AppStorage` defaults it: reading it with
    /// `bool(forKey:)` alone would hand every untouched install the classic names under the Pulse screens.
    func testAnUnsetSwitchMeansPulse() {
        XCTAssertEqual(CoachVocabulary.resolve(freshDefaults()), .pulse)
    }

    func testTheSwitchDecides() {
        let d = freshDefaults()
        d.set(false, forKey: CoachVocabulary.pulseEnabledKey)
        XCTAssertEqual(CoachVocabulary.resolve(d), .classic)
        d.set(true, forKey: CoachVocabulary.pulseEnabledKey)
        XCTAssertEqual(CoachVocabulary.resolve(d), .pulse)
        // A `-pulse.enabled NO` launch argument arrives as a string.
        d.set("NO", forKey: CoachVocabulary.pulseEnabledKey)
        XCTAssertEqual(CoachVocabulary.resolve(d), .classic)
    }

    /// The Mac has only the classic interface.
    func testTheMacIsClassic() {
        XCTAssertEqual(CoachVocabulary.current, .classic)
        XCTAssertEqual(engine().vocabulary, .classic)
    }

    // MARK: - System prompt

    func testEachInterfaceGetsItsBuiltInPrompt() {
        XCTAssertEqual(engine(.classic).systemPrompt, AICoachEngine.defaultSystemPrompt)
        let pulse = engine(.pulse).systemPrompt
        XCTAssertEqual(pulse, AICoachEngine.pulseSystemPrompt)
        XCTAssertTrue(pulse.contains("Recovery 0-100%"))
        XCTAssertTrue(pulse.contains("Strain 0-21"))
        XCTAssertFalse(pulse.lowercased().contains("charge 0-100"), "the Pulse prompt must not teach the classic names")
    }

    /// Saving either built-in prompt is saving nothing: neither becomes a "custom" prompt that then sticks
    /// when the interface changes.
    func testEitherBuiltInPromptIsNotCustom() {
        let e = engine(.pulse)
        e.customSystemPrompt = AICoachEngine.pulseSystemPrompt
        XCTAssertNil(UserDefaults.standard.string(forKey: AICoachEngine.systemPromptKey))
        XCTAssertFalse(e.hasCustomSystemPrompt)
        e.customSystemPrompt = AICoachEngine.defaultSystemPrompt
        XCTAssertNil(UserDefaults.standard.string(forKey: AICoachEngine.systemPromptKey))
    }

    /// An edited prompt may be written in the classic names: in Pulse the names are spelled out under it.
    /// The classic interface sends it as it is.
    func testAnEditedPromptGetsTheNamesInPulseOnly() {
        let pulse = engine(.pulse)
        pulse.customSystemPrompt = "You are a terse coach. Talk about my charge."
        XCTAssertTrue(pulse.requestSystemPrompt.hasPrefix("You are a terse coach. Talk about my charge."))
        XCTAssertTrue(pulse.requestSystemPrompt.contains(AICoachEngine.pulseVocabularyNote))
        let classic = engine(.classic)
        classic.customSystemPrompt = "You are a terse coach."
        XCTAssertEqual(classic.requestSystemPrompt, "You are a terse coach.")
    }

    /// The standing context (the Pulse Coach's memories) rides every request's system prompt, read when the
    /// request is built; nil or blank adds nothing.
    func testStandingContextFollowsThePrompt() {
        let e = engine(.pulse)
        XCTAssertEqual(e.requestSystemPrompt, AICoachEngine.pulseSystemPrompt)
        var memory: String? = "About the user:\n- Training for a half marathon."
        e.systemContext = { memory }
        XCTAssertEqual(e.requestSystemPrompt, AICoachEngine.pulseSystemPrompt + "\n\n" + (memory ?? ""))
        memory = "   "
        XCTAssertEqual(e.requestSystemPrompt, AICoachEngine.pulseSystemPrompt)
    }

    // MARK: - Data summary and brief

    /// The classic line is unchanged (the Kotlin twin's), and Pulse's names the same figures the way its
    /// screens print them: Recovery as a percent, Strain on 0-21 (58.2 × 0.21 = 12.2), Sleep in hours.
    func testDayLineInEachInterface() {
        let e = engine()
        XCTAssertTrue(e.dayLine(day, vocabulary: .classic)
                        .hasPrefix("2026-06-01:, charge 67, effort 58.2, rest 7.5h, deep 1.4h"))
        XCTAssertTrue(e.dayLine(day, vocabulary: .pulse)
                        .hasPrefix("2026-06-01:, Recovery 67%, Strain 12.2, Sleep 7.5h, deep 1.4h"))
        XCTAssertEqual(e.dayLine(day), e.dayLine(day, vocabulary: .classic), "the Mac's line is the classic one")
    }

    func testTheBriefAsksInTheInterfaceNames() {
        XCTAssertTrue(AICoachEngine.briefInstruction(.classic).contains("citing charge, HRV and rest"))
        let pulse = AICoachEngine.briefInstruction(.pulse)
        XCTAssertTrue(pulse.contains("citing Recovery, HRV and Sleep"))
        XCTAssertFalse(pulse.contains("charge"))
    }
}
