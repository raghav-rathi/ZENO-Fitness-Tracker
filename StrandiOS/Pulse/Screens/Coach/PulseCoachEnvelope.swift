#if os(iOS)
import Foundation
import StrandAnalytics

// MARK: - What goes with a question (WHOOP_UI_SPEC §3.16, §1.2 "seeded with that page's context", §0.3)
//
// The Coach sheet drives the EXISTING `AICoachEngine`. The engine itself speaks the Pulse interface's names
// (Recovery, Strain on 0–21, Sleep) in its system prompt, data summary and brief while Pulse runs
// (`CoachVocabulary`), so nothing here has to translate the classic charge / effort / rest. Two things still
// reach the model from the sheet:
//
//   - the wearer's ACTIVE memories (My Memory), while Memory is switched on, as standing system context
//     (`AICoachEngine.systemContext`, `standingContext()` below): every request carries the memories active
//     when it is sent, so one switched off stops going at once;
//   - the PAGE the sheet was opened from (a deep dive's summary pill, the Daily Outlook, the cycle page), in a
//     fenced block on the FIRST user message of a conversation, the turn the engine keeps at the head of
//     every request it sends for the conversation (its sliding window always retains it). The sheet never
//     shows the block as text: it shows the question in the bubble and a "✧ Shared your Sleep summary"
//     receipt above it, read back from the stored block, so it names only what was attached.
//
// The page summary carries the wearer's numbers (a cycle day and phase, a night's sleep), so it goes only
// while AI Settings › USE MY DATA is on, the same consent the engine asks before it sends its own data
// summary; with it off the question goes alone and the sheet says the page was not shared.
//
// Conversations from before the engine spoke Pulse's names carry "Words" and "About me" lines in their
// block. They still parse (their receipt still says how many memories went with them), and a conversation
// reopened from the history drops them (`droppingLegacyContext`), so neither an outdated memory nor a second
// copy of the names rides it again.

enum PulseCoachEnvelope {

    /// What a stored first message holds.
    struct Parsed: Equatable {
        /// The question as the wearer asked it.
        let question: String
        /// The page summary it was asked from.
        let page: String?
        /// Memories it carried.
        let memoryCount: Int
        let hasContext: Bool
    }

    /// The first question of a conversation with the page it was asked from (`CoachContextEnvelope`, the
    /// format the analytics package pins with tests), or the bare question when there is no page to share.
    static func wrap(_ question: String, page: String?) -> String {
        guard let page, !page.isEmpty else { return question }
        return CoachContextEnvelope.wrap(question, fields: [("Page", page)])
    }

    /// A stored first question as it should go again when its conversation is reopened: a block from before
    /// the engine spoke Pulse's names keeps only its page (its "Words" and "About me" lines go, the memories
    /// now riding the system context as they stand). Anything else is returned unchanged.
    static func droppingLegacyContext(_ text: String) -> String {
        let parsed = CoachContextEnvelope.parse(text)
        guard parsed.hasBlock, parsed.fields.keys.contains(where: { $0 != "Page" }) else { return text }
        return wrap(parsed.question, page: parsed.fields["Page"])
    }

    /// The wearer's active memories as standing context for the engine's system prompt, or nil with none.
    /// The detail holds the whole memory (its title is the detail's first sentence), each on one line.
    static func memoryContext(_ memories: [PulseMemoryItem]) -> String? {
        let lines = memories.map { "- " + $0.detail.split(whereSeparator: \.isNewline).joined(separator: " ") }
        guard !lines.isEmpty else { return nil }
        return (["About the user, in their own words (My Memory). Let it shape your advice; never quote it back:"]
                + lines).joined(separator: "\n")
    }

    /// The engine's standing-context hook (`AICoachEngine.systemContext`): the active memories while Memory is
    /// on (`PulseMemoryStore.promptItems`), and only while the Pulse interface, the one that shows and manages
    /// them, runs.
    @MainActor
    static func standingContext() -> String? {
        guard CoachVocabulary.current == .pulse else { return nil }
        return memoryContext(PulseMemoryStore.shared.promptItems)
    }

    /// Split a stored message into its question and context. Text without a block is all question.
    static func parse(_ text: String) -> Parsed {
        let parsed = CoachContextEnvelope.parse(text)
        let memories = parsed.fields["About me"].map { $0.components(separatedBy: memorySeparator).count } ?? 0
        return Parsed(question: parsed.question, page: parsed.fields["Page"], memoryCount: memories,
                      hasContext: parsed.hasBlock)
    }

    private static let memorySeparator = " | "

    /// "✧ Shared your Sleep summary", with "· Used 2 memories" on a turn from before memories moved to the
    /// system context, or nil when no page went along. Read from the stored block, so it names only what was
    /// attached.
    static func receipt(_ parsed: Parsed) -> String? {
        var parts: [String] = []
        if let page = parsed.page { parts.append(String(localized: "Shared \(pageLabel(page))")) }
        if parsed.memoryCount == 1 { parts.append(String(localized: "Used 1 memory")) }
        if parsed.memoryCount > 1 { parts.append(String(localized: "Used \(parsed.memoryCount) memories")) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Which page a seed came from, for the receipt ("your Sleep summary").
    static func pageLabel(_ seed: String) -> String {
        switch PageKind(seed) {
        case .outlook: return String(localized: "your Daily Outlook")
        case .review: return String(localized: "your Day in Review")
        case .cycle: return String(localized: "your cycle summary")
        case .sleep: return String(localized: "your Sleep summary")
        case .recovery: return String(localized: "your Recovery summary")
        case .strain: return String(localized: "your Strain summary")
        case .other: return String(localized: "this page's summary")
        }
    }

    /// The pages that seed the Coach today, recognised by their summary's wording.
    enum PageKind: Equatable {
        case outlook, review, cycle, sleep, recovery, strain, other

        init(_ seed: String) {
            let s = seed.lowercased()
            if s.hasPrefix(String(localized: "Daily Outlook").lowercased()) { self = .outlook }
            else if s.hasPrefix(String(localized: "Day in Review").lowercased()) { self = .review }
            else if s.contains("cycle day") || s.contains("phase predicted") || s.contains("menopause") { self = .cycle }
            else if s.contains("sleep") { self = .sleep }
            else if s.contains("recovery") { self = .recovery }
            else if s.contains("strain") { self = .strain }
            else { self = .other }
        }
    }
}

// MARK: - Suggestion chips (§3.16 "Suggestion chips")

enum PulseCoachSuggestions {
    /// The chip that asks for today's brief, as a normal question (the sheet never asks the engine for its
    /// own brief on opening: the first request is always one the wearer made).
    static var brief: String { String(localized: "Give me today's brief") }

    /// Chips for a conversation opened from `seed`'s page.
    static func seeded(_ seed: String) -> [String] {
        switch PulseCoachEnvelope.PageKind(seed) {
        case .outlook, .review:
            return [String(localized: "What should today's training look like?"),
                    String(localized: "How do I get the most from today?"),
                    String(localized: "When should I go to bed tonight?")]
        case .cycle:
            return [String(localized: "How should I train in this phase?"),
                    String(localized: "Why does my cycle change my Recovery?"),
                    String(localized: "What can help with my symptoms?")]
        case .sleep:
            return [String(localized: "Why was my sleep like this?"),
                    String(localized: "How can I sleep better tonight?"),
                    String(localized: "How does this compare to my week?")]
        case .recovery:
            return [String(localized: "What should I do with today's Recovery?"),
                    String(localized: "What's driving my Recovery?"),
                    String(localized: "How does this compare to my week?")]
        case .strain:
            return [String(localized: "How much more Strain should I take on today?"),
                    String(localized: "Was today's Strain about right?"),
                    String(localized: "How does this compare to my week?")]
        case .other:
            return [String(localized: "Explain this"),
                    String(localized: "What should I do next?"),
                    String(localized: "How does this compare to my week?")]
        }
    }
}
#endif
