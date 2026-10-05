import XCTest
import StrandAnalytics
@testable import Strand

/// The explanation and insight screens Pulse links to speak its vocabulary (docs/zeno/WHOOP_UI_SPEC.md §0.3)
/// without touching the engine strings other surfaces read: the engine's words are mapped where they are
/// shown. These pin both halves: the mappings themselves, and the exact engine strings they match, so a
/// reworded engine string fails here instead of quietly slipping past its mapping back to "Charge".
///
/// The suite runs on the Mac, whose vocabulary is always classic, so each mapping is driven with an
/// explicit vocabulary and the classic side is checked to be the text the screens always showed.
@MainActor
final class InsightScreensVocabularyTests: XCTestCase {

    // MARK: - Intelligence: the engine's empty-state note

    func testTheEngineNoteTheMappingMatchesIsTheOneTheEngineWrites() throws {
        let engine = try Self.source("Strand/Data/IntelligenceEngine.swift")
        XCTAssertTrue(engine.contains("\"\(IntelligenceView.engineNoNightsNote)\""),
                      "IntelligenceEngine's no-nights note changed; update IntelligenceView.engineNoNightsNote")
    }

    func testTheNoNightsNoteSpeaksPulseOnlyUnderPulse() {
        let note = IntelligenceView.engineNoNightsNote
        XCTAssertEqual(IntelligenceView.noteText(note, vocabulary: .classic), note)

        let pulse = IntelligenceView.noteText(note, vocabulary: .pulse)
        XCTAssertNotEqual(pulse, note)
        XCTAssertTrue(pulse.contains("ZENO"))
        XCTAssertTrue(pulse.contains("recovery, strain and sleep"))
        XCTAssertFalse(pulse.contains("NOOP"))
        XCTAssertFalse(pulse.lowercased().contains("charge"))
    }

    func testAnyOtherEngineNoteIsShownAsWritten() {
        XCTAssertEqual(IntelligenceView.noteText("No on-device store yet.", vocabulary: .pulse),
                       "No on-device store yet.")
    }

    // MARK: - Charge drivers: verdicts that name the score

    func testEveryEngineVerdictNamingChargeHasARecoveryForm() throws {
        let drivers = try Self.source("Packages/StrandAnalytics/Sources/StrandAnalytics/ChargeDrivers.swift")
        let naming = Self.literals(in: drivers).filter { $0.contains("Charge") && $0.contains("baseline") }
        XCTAssertEqual(Set(naming), ["above baseline, too small to change Charge",
                                     "below baseline, too small to change Charge"],
                       "a ChargeDrivers verdict naming Charge was added or reworded; map it in pulseVerdict")
        for verdict in naming {
            let pulse = try XCTUnwrap(ChargeBreakdownFormat.pulseVerdict(verdict), verdict)
            XCTAssertTrue(pulse.hasSuffix("too small to change Recovery"), pulse)
        }
    }

    func testVerdictsThatDoNotNameTheScoreReadTheSameInBoth() {
        for verdict in ["above baseline, supporting recovery", "at baseline", "a typical night"] {
            XCTAssertNil(ChargeBreakdownFormat.pulseVerdict(verdict), verdict)
            XCTAssertEqual(ChargeBreakdownFormat.verdictText(verdict, vocabulary: .pulse),
                           ChargeBreakdownFormat.verdictText(verdict, vocabulary: .classic))
        }
    }

    func testTheDriverReadOutSaysRecoveryUnderPulseAndChargeInClassic() {
        let d = ChargeDriver(label: "Resting heart rate", deltaPoints: 0, valueText: "58 bpm",
                             baselineText: "58 bpm baseline", verdict: "below baseline, too small to change Charge")
        XCTAssertEqual(ChargeBreakdownFormat.driverAccessibilityLabel(d, vocabulary: .classic),
                       "Resting heart rate: no change. 58 bpm, 58 bpm baseline. below baseline, too small to change Charge.")
        XCTAssertEqual(ChargeBreakdownFormat.driverAccessibilityLabel(d, vocabulary: .pulse),
                       "Resting heart rate: no change. 58 bpm, 58 bpm baseline. below baseline, too small to change Recovery.")
    }

    // MARK: - Insights Hub: outcome names

    func testOutcomeIdsKeepTheirIdentityAndGainPulseNames() {
        XCTAssertEqual(DoseResponsePriors.defaultOutcome(for: .alcohol), "Charge",
                       "the alcohol prior's outcome id is what outcomeDisplayName maps")
        XCTAssertEqual(InsightsHubViewModel.outcomeKey(forEngineName: "Charge"), "recovery")
        XCTAssertEqual(InsightsHubViewModel.outcomeKey(forEngineName: "Rest"), "sleep_performance")

        XCTAssertEqual(InsightsHubViewModel.outcomeDisplayName("Charge", vocabulary: .classic), "Charge")
        XCTAssertEqual(InsightsHubViewModel.outcomeDisplayName("Rest", vocabulary: .classic), "Rest")
        XCTAssertEqual(InsightsHubViewModel.outcomeDisplayName("Charge", vocabulary: .pulse), "Recovery")
        XCTAssertEqual(InsightsHubViewModel.outcomeDisplayName("Rest", vocabulary: .pulse), "Sleep")
        XCTAssertEqual(InsightsHubViewModel.outcomeDisplayName("HRV", vocabulary: .pulse), "HRV")
    }

    /// The real engine sentence for a cold-start alcohol curve (prior only), so the shape the swap relies
    /// on, the outcome id as a word of its own, is the engine's and not a copy of it.
    func testTheDoseSentenceNamesRecoveryUnderPulse() throws {
        let response = try XCTUnwrap(DoseResponseEngine.estimate(behavior: .alcohol, doseByDay: [:], outcomeByDay: [:]))
        let sentence = response.sentence()
        XCTAssertTrue(sentence.contains(" Charge "), sentence)

        XCTAssertEqual(InsightsHubViewModel.displaySentence(sentence, outcomeId: response.outcome, vocabulary: .classic),
                       sentence)
        let pulse = InsightsHubViewModel.displaySentence(sentence, outcomeId: response.outcome, vocabulary: .pulse)
        XCTAssertEqual(pulse, sentence.replacingOccurrences(of: " Charge ", with: " Recovery "))
        XCTAssertFalse(pulse.contains("Charge"), pulse)
    }

    func testAnHRVSentenceIsLeftAlone() {
        let s = "Each extra unit tends to line up with about 3.1 HRV lower for you (n=9)."
        XCTAssertEqual(InsightsHubViewModel.displaySentence(s, outcomeId: "HRV", vocabulary: .pulse), s)
    }

    // MARK: - Scoring guide

    func testTheGuideNamesItsSectionsInEachVocabulary() {
        XCTAssertEqual(ScoreSection.allCases.map { $0.displayName(.classic) }, ["Charge", "Effort", "Rest"])
        XCTAssertEqual(ScoreSection.allCases.map { $0.displayName(.pulse) }, ["Recovery", "Strain", "Sleep"])
    }

    /// The sample rings read like the screens they stand for: a percentage for Recovery and Sleep, and
    /// Strain on WHOOP's 0-21 axis through the shared formatter, under Pulse; the bare number in classic.
    func testTheSampleRingsReadOnEachVocabularysScale() {
        XCTAssertEqual(ScoreSection.effort.sampleText(64, vocabulary: .classic), "64")
        XCTAssertEqual(ScoreSection.charge.sampleText(82, vocabulary: .classic), "82")
        XCTAssertEqual(ScoreSection.effort.sampleText(64, vocabulary: .pulse),
                       UnitFormatter.effortDisplay(64, scale: .whoop))
        XCTAssertEqual(ScoreSection.effort.sampleText(64, vocabulary: .pulse), "13.4")
        XCTAssertEqual(ScoreSection.charge.sampleText(82, vocabulary: .pulse), "82%")
        XCTAssertEqual(ScoreSection.rest.sampleText(88, vocabulary: .pulse), "88%")
    }

    // MARK: - The classic side is what it always was (the Mac runs classic)

    func testTheMacKeepsTheClassicCopy() {
        XCTAssertEqual(ScoreVocabulary.current, .classic)
        XCTAssertEqual(FusionSource.noopComputed.fusedDisplayName, "NOOP")
        XCTAssertEqual(FusionSource.whoopImport.fusedDisplayName, FusionSource.whoopImport.displayName)
        XCTAssertTrue(AppChangelog.expectations[0].body.hasPrefix("NOOP is a personal, open project"))
        XCTAssertTrue(RhythmConsent.points[3].1.hasSuffix("Do not rely on NOOP."))
        XCTAssertTrue(ChargeBreakdownFormat.chargeLegacyRRGapDetail.contains("before NOOP labelled"))
    }

    /// ZENO's entry is its own, outside NOOP's history: the generator, the Android mirror and the Home
    /// "What's new" card all read `releases`, whose newest entry stays NOOP's current release.
    func testTheZenoEntryStaysOutOfNOOPsHistory() {
        XCTAssertEqual(AppChangelog.releases.first?.version, AppChangelog.currentVersion)
        XCTAssertFalse(AppChangelog.releases.contains { $0.title == AppChangelog.Zeno.title })
        XCTAssertFalse(AppChangelog.Zeno.highlights.isEmpty)
    }

    // MARK: - Helpers

    /// A repository source file, found by walking up from this test file (the tests read the engine
    /// source the mappings match, as `AlarmWakeTimeLabellingTests` reads its screen).
    private static func source(_ relative: String, file: StaticString = #filePath) throws -> String {
        var dir = URL(fileURLWithPath: "\(file)").deletingLastPathComponent()
        for _ in 0..<5 {
            let candidate = dir.appendingPathComponent(relative)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return try String(contentsOf: candidate, encoding: .utf8)
            }
            dir = dir.deletingLastPathComponent()
        }
        throw SourceNotFound(relative: relative)
    }

    private struct SourceNotFound: Error, CustomStringConvertible {
        let relative: String
        var description: String { "\(relative) not reachable from the test file" }
    }

    /// Every plain one-line string literal in the code of `source` (comment lines skipped, escaped quotes
    /// honoured, interpolated literals left out), content only.
    private static func literals(in source: String) -> [String] {
        var out: [String] = []
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") { continue }
            var literal: String?
            var escaped = false
            for ch in line {
                if var open = literal {
                    if escaped { open.append(ch); escaped = false; literal = open; continue }
                    if ch == "\\" { open.append(ch); escaped = true; literal = open; continue }
                    if ch == "\"" {
                        if !open.contains("\\(") { out.append(open) }
                        literal = nil
                    } else {
                        open.append(ch)
                        literal = open
                    }
                } else if ch == "\"" {
                    literal = ""
                }
            }
        }
        return out
    }
}
