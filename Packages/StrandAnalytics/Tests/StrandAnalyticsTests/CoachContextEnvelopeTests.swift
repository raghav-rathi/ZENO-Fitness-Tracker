import XCTest
@testable import StrandAnalytics

final class CoachContextEnvelopeTests: XCTestCase {

    private typealias E = CoachContextEnvelope

    // MARK: - Envelope

    func testWrapAndParseRoundTrip() {
        let text = E.wrap("How did I sleep?", fields: [("Words", "Call them Recovery."), ("Page", "Sleep was **86%**")])
        XCTAssertEqual(text, "[ZENO context]\nWords: Call them Recovery.\nPage: Sleep was **86%**\n[/ZENO context]\n\nHow did I sleep?")
        let parsed = E.parse(text)
        XCTAssertTrue(parsed.hasBlock)
        XCTAssertEqual(parsed.question, "How did I sleep?")
        XCTAssertEqual(parsed.fields, ["Words": "Call them Recovery.", "Page": "Sleep was **86%**"])
    }

    func testValuesAreFlattenedAndEmptyOnesDropped() {
        let text = E.wrap("Hi", fields: [("Page", "line one\nline two\n"), ("About me", "  "), ("Words", "w")])
        let parsed = E.parse(text)
        XCTAssertEqual(parsed.fields["Page"], "line one line two")
        XCTAssertNil(parsed.fields["About me"])
        XCTAssertEqual(parsed.fields["Words"], "w")
    }

    func testEmptyBlockParsesSafely() {
        let text = E.wrap("Just a question", fields: [])
        XCTAssertEqual(text, "[ZENO context]\n[/ZENO context]\n\nJust a question")
        let parsed = E.parse(text)
        XCTAssertTrue(parsed.hasBlock)
        XCTAssertEqual(parsed.question, "Just a question")
        XCTAssertTrue(parsed.fields.isEmpty)
    }

    func testPlainTextIsAllQuestion() {
        let parsed = E.parse("What should I do today?")
        XCTAssertFalse(parsed.hasBlock)
        XCTAssertEqual(parsed.question, "What should I do today?")
        // An opening line with no closing one is not a block either.
        XCTAssertFalse(E.parse("[ZENO context]\nPage: x\n\nquestion").hasBlock)
    }

    func testQuestionMayRepeatTheMarkers() {
        let question = "What does this mean?\n[/ZENO context]\n\nstill the question"
        let parsed = E.parse(E.wrap(question, fields: [("Page", "p")]))
        XCTAssertEqual(parsed.question, question)
        XCTAssertEqual(parsed.fields["Page"], "p")
    }

    func testFirstKeyWins() {
        let parsed = E.parse("[ZENO context]\nPage: one\nPage: two\n[/ZENO context]\n\nq")
        XCTAssertEqual(parsed.fields["Page"], "one")
    }

    // MARK: - Merge

    private struct Turn: Identifiable, Equatable {
        let id: Int
        var text: String
        init(_ id: Int, _ text: String = "") { self.id = id; self.text = text.isEmpty ? "t\(id)" : text }
    }

    func testNoSharedTurnIsANewConversation() {
        XCTAssertNil(CoachConversationMerge.merge(archived: [Turn(1), Turn(2)], live: [Turn(3), Turn(4)]))
        XCTAssertNil(CoachConversationMerge.merge(archived: [Turn](), live: [Turn(1)]))
    }

    func testLiveTurnsExtendTheArchive() {
        let merged = CoachConversationMerge.merge(archived: [Turn(1), Turn(2)],
                                                  live: [Turn(1), Turn(2), Turn(3), Turn(4)])
        XCTAssertEqual(merged?.map(\.id), [1, 2, 3, 4])
    }

    func testTurnsTheEngineDroppedAtItsCapAreKept() {
        let merged = CoachConversationMerge.merge(archived: [Turn(1), Turn(2), Turn(3), Turn(4)],
                                                  live: [Turn(3), Turn(4), Turn(5)])
        XCTAssertEqual(merged?.map(\.id), [1, 2, 3, 4, 5])
    }

    func testRewrittenTurnTakesTheLiveText() {
        let merged = CoachConversationMerge.merge(archived: [Turn(1), Turn(2, "partial")],
                                                  live: [Turn(1), Turn(2, "the full reply")])
        XCTAssertEqual(merged?.last?.text, "the full reply")
        // A reopened conversation whose first live turn was re-wrapped keeps the older turns before it.
        let reopened = CoachConversationMerge.merge(archived: [Turn(1), Turn(2), Turn(3)],
                                                    live: [Turn(2, "re-wrapped"), Turn(3)])
        XCTAssertEqual(reopened, [Turn(1), Turn(2, "re-wrapped"), Turn(3)])
    }

    func testUnchangedLiveConversationMergesToItself() {
        let turns = [Turn(1), Turn(2)]
        XCTAssertEqual(CoachConversationMerge.merge(archived: turns, live: turns), turns)
    }
}
