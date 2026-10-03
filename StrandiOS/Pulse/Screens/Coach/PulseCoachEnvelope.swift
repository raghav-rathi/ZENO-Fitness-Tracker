#if os(iOS)
import Foundation
import StrandAnalytics

// MARK: - The first message's context block (WHOOP_UI_SPEC §3.16, §1.2 "seeded with that page's context", §0.3)
//
// The Coach sheet drives the EXISTING `AICoachEngine`, which builds its own system prompt and data summary
// and offers no hook for extra context. Three things still have to reach the model with a new conversation:
//
//   - the WORDS: the engine's prompt and data summary speak in the classic "charge / effort (0–100) / rest"
//     names, and the rebuilt UI must say Recovery, Strain (0–21) and Sleep (§0.3), so the model is told how
//     the names map and to use the WHOOP-structured ones;
//   - the PAGE the sheet was opened from (a deep dive's summary pill, the Daily Outlook, the cycle page);
//   - the wearer's ACTIVE memories (My Memory), while Memory is switched on.
//
// They ride the FIRST user message of a conversation in a fenced block, because that is the turn the engine
// keeps at the head of every request it sends for the conversation (its sliding window always retains it).
// The sheet never shows the block as text: it shows the question in the bubble and a "✧ Shared your Sleep
// summary · Used 2 memories" receipt above it, so what was sent is still stated.
//
// The page summary carries the wearer's numbers (a cycle day and phase, a night's sleep), so it goes only
// while AI Settings › USE MY DATA is on, the same consent the engine asks before it sends its own data
// summary; with it off the block carries the words and any memories only, and the sheet says the page was
// not shared. The receipt is read back from the stored block, so it names only what was attached.
//
// `AICoachEngine` has no hook for extra system context today. When it gains one, this block should move
// there and `wrap` is the one place to change.

enum PulseCoachEnvelope {
    /// How the engine's data names map onto the names the wearer sees (the block's "Words" line).
    static let vocabulary = """
    in this app the daily scores are called Recovery (your data's "charge", 0-100%), Strain (your data's \
    "effort" times 0.21, on a 0-21 scale) and Sleep (your data's "rest"). Call them Recovery, Strain and Sleep, \
    give Strain on the 0-21 scale, and never call them charge, effort or rest.
    """

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

    /// The first question of a conversation with its context block (`CoachContextEnvelope`, the format the
    /// analytics package pins with tests).
    static func wrap(_ question: String, page: String?, memories: [PulseMemoryItem]) -> String {
        // The detail holds the whole memory (its title is the detail's first sentence).
        let about = memories.map(\.detail).joined(separator: memorySeparator)
        return CoachContextEnvelope.wrap(question, fields: [("Words", vocabulary), ("Page", page ?? ""),
                                                            ("About me", about)])
    }

    /// Split a stored message into its question and context. Text without a block is all question.
    static func parse(_ text: String) -> Parsed {
        let parsed = CoachContextEnvelope.parse(text)
        let memories = parsed.fields["About me"].map { $0.components(separatedBy: memorySeparator).count } ?? 0
        return Parsed(question: parsed.question, page: parsed.fields["Page"], memoryCount: memories,
                      hasContext: parsed.hasBlock)
    }

    private static let memorySeparator = " | "

    /// "✧ Shared your Sleep summary · Used 2 memories", or nil when nothing but the words went along. Read
    /// from the stored block, so it names only what was attached.
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
    /// The chip that asks for today's brief (the engine's own brief speaks the classic names, so the sheet
    /// asks for it through a normal question, which carries the words above).
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
