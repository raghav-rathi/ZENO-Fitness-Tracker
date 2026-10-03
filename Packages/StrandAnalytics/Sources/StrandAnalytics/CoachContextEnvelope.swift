import Foundation

// CoachContextEnvelope.swift — the fenced context block a Coach conversation's FIRST message carries, and the
// merge that files the engine's live conversation into the on-device history. Pure string and array helpers,
// so the iPhone Coach sheet's writer and reader of the block can never drift apart, and so the merge, which
// decides whether an archived conversation keeps its older turns, is pinned by tests.
//
// The block exists because the engine (`AICoachEngine`) builds its own system prompt and keeps the first
// user turn at the head of every request it sends for a conversation. Context that must reach the model
// with a new conversation (the page it was asked from, the wearer's active memories, how the score names
// map) therefore rides that turn:
//
//     [ZENO context]
//     Words: …
//     Page: …
//     About me: …
//     [/ZENO context]
//
//     <the question as the wearer asked it>
public enum CoachContextEnvelope {
    public static let open = "[ZENO context]"
    public static let close = "[/ZENO context]"

    /// `question` after a block of "Key: value" lines. Each value is flattened onto one line; empty values
    /// are dropped (an empty block is still written, so the turn reads the same either way).
    public static func wrap(_ question: String, fields: [(key: String, value: String)]) -> String {
        let lines = fields.compactMap { field -> String? in
            let value = oneLine(field.value)
            return value.isEmpty ? nil : "\(field.key): \(value)"
        }
        return ([open] + lines + [close]).joined(separator: "\n") + "\n\n" + question
    }

    /// A stored turn split into its question and its block.
    public struct Parsed: Equatable, Sendable {
        /// The question as the wearer asked it (the whole text when there is no block).
        public let question: String
        /// The block's fields by key; the first line with a key wins.
        public let fields: [String: String]
        public let hasBlock: Bool

        public init(question: String, fields: [String: String], hasBlock: Bool) {
            self.question = question
            self.fields = fields
            self.hasBlock = hasBlock
        }
    }

    /// Split a stored turn. Text that does not open with a complete block is all question.
    public static func parse(_ text: String) -> Parsed {
        let head = open + "\n"
        guard text.hasPrefix(head), let end = text.range(of: "\n" + close + "\n\n") else {
            return Parsed(question: text, fields: [:], hasBlock: false)
        }
        let blockStart = text.index(text.startIndex, offsetBy: head.count)
        // An empty block's closing line follows the opening one directly.
        let block = blockStart <= end.lowerBound ? text[blockStart..<end.lowerBound] : Substring()
        var fields: [String: String] = [:]
        for line in block.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let colon = line.range(of: ": ") else { continue }
            let key = String(line[..<colon.lowerBound])
            if fields[key] == nil { fields[key] = String(line[colon.upperBound...]) }
        }
        return Parsed(question: String(text[end.upperBound...]), fields: fields, hasBlock: true)
    }

    static func oneLine(_ text: String) -> String {
        text.split(whereSeparator: \.isNewline).joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}

/// Filing the engine's live conversation into an archived one.
public enum CoachConversationMerge {
    /// `archived` brought up to date with `live`, or nil when the two share no turn (a new conversation).
    ///
    /// The live transcript is a contiguous TAIL of the conversation: the engine drops its oldest turns at its
    /// cap and rewrites its newest turn in place while a reply streams. So everything archived before the
    /// first live turn it also holds is kept, and from there the live turns (with their current text)
    /// replace the rest.
    public static func merge<T: Identifiable>(archived: [T], live: [T]) -> [T]? {
        guard let liveIndex = live.firstIndex(where: { turn in archived.contains { $0.id == turn.id } }),
              let archivedIndex = archived.firstIndex(where: { $0.id == live[liveIndex].id }) else { return nil }
        return Array(archived[..<archivedIndex]) + Array(live[liveIndex...])
    }
}
