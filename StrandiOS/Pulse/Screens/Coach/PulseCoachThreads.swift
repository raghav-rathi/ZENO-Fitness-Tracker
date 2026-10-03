#if os(iOS)
import Foundation
import Observation

// MARK: - Conversation history (WHOOP_UI_SPEC §3.16 [Z] "History list")
//
// `AICoachEngine` keeps ONE live conversation (persisted in the store's coach table, capped at 40 turns
// and retired at the local day boundary). The Coach sheet keeps every conversation the wearer had in a
// local archive beside it, so the history list can reopen one:
//
//   - a thread is identified by the id of its first message, and found again by ANY message id it shares
//     with the live conversation, so the engine dropping its oldest turns at the cap, or rewriting the
//     last turn while it streams, never forks or loses a thread;
//   - the archive is synced when a reply completes and when the sheet closes, never per streamed token;
//   - it lives in Application Support (complete-until-first-unlock protection) as one JSON file, on this
//     iPhone only, and is deleted per thread (swipe) or all at once (AI Settings).

/// One archived conversation.
struct PulseCoachThread: Codable, Identifiable, Equatable {
    struct Message: Codable, Identifiable, Equatable {
        let id: UUID
        /// "user" or "assistant" (`ChatMessage.Role.rawValue`).
        let role: String
        var text: String
    }

    /// The first message's id.
    let id: UUID
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date

    /// The first question as the wearer typed it (the context block stripped), else the first reply.
    var title: String {
        if let first = messages.first(where: { $0.role == ChatMessage.Role.user.rawValue }) {
            return PulseCoachEnvelope.parse(first.text).question.firstLine(limit: 80)
        }
        return (messages.first?.text ?? "").firstLine(limit: 80)
    }

    /// The last message as plain text, for the row's two-line snippet (markdown emphasis, headings and list
    /// markers dropped).
    var snippet: String {
        guard let last = messages.last else { return "" }
        let text = last.role == ChatMessage.Role.user.rawValue ? PulseCoachEnvelope.parse(last.text).question : last.text
        return text.replacingOccurrences(of: "**", with: "")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { line -> String in
                var l = line.trimmingCharacters(in: .whitespaces)
                for marker in ["- ", "* ", "• ", "### ", "## ", "# "] where l.hasPrefix(marker) {
                    l.removeFirst(marker.count)
                }
                return l
            }
            .joined(separator: " ")
    }
}

@MainActor
@Observable
final class PulseCoachThreadStore {
    static let shared = PulseCoachThreadStore()

    /// Newest first.
    private(set) var threads: [PulseCoachThread] = []
    @ObservationIgnored private var loaded = false
    /// The previous write, so writes land in order.
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    private init() {}

    private static var fileURL: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("Pulse", isDirectory: true).appendingPathComponent("coach-threads.json")
    }

    func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let url = Self.fileURL, let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PulseCoachThread].self, from: data) else { return }
        threads = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// The archived thread that holds any of `messages`.
    func thread(containing messages: [ChatMessage]) -> PulseCoachThread? {
        let ids = Set(messages.map(\.id))
        return threads.first { t in t.messages.contains { ids.contains($0.id) } }
    }

    func thread(_ id: UUID) -> PulseCoachThread? {
        threads.first { $0.id == id }
    }

    /// File the live conversation: merged into the thread it continues, or a new thread.
    func sync(_ live: [ChatMessage], now: Date = Date()) {
        loadIfNeeded()
        let usable = live.filter { !$0.text.isEmpty }
        guard !usable.isEmpty else { return }
        let incoming = usable.map { PulseCoachThread.Message(id: $0.id, role: $0.role.rawValue, text: $0.text) }
        if let index = threads.firstIndex(where: { t in t.messages.contains { m in incoming.contains { $0.id == m.id } } }) {
            var thread = threads[index]
            // Keep what the engine has already dropped (its 40-turn cap), then take the live turns.
            if let firstLive = incoming.firstIndex(where: { m in thread.messages.contains { $0.id == m.id } }),
               let archived = thread.messages.firstIndex(where: { $0.id == incoming[firstLive].id }) {
                let merged = Array(thread.messages.prefix(archived)) + Array(incoming[firstLive...])
                guard merged != thread.messages else { return }
                thread.messages = merged
                thread.updatedAt = now
                threads[index] = thread
            }
        } else {
            threads.append(PulseCoachThread(id: incoming[0].id, messages: incoming, createdAt: now, updatedAt: now))
        }
        threads.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func delete(_ id: UUID) {
        threads.removeAll { $0.id == id }
        save()
    }

    func deleteAll() {
        threads = []
        save()
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        let snapshot = threads
        let previous = saveTask
        saveTask = Task.detached(priority: .utility) {
            await previous?.value
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true)
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
    }
}

extension String {
    /// The first line, cut at a word near `limit` characters with an ellipsis.
    func firstLine(limit: Int) -> String {
        let line = split(separator: "\n", omittingEmptySubsequences: true).first.map(String.init) ?? self
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        let cut = trimmed.prefix(limit)
        let word = cut.lastIndex(of: " ").map { cut[..<$0] } ?? cut
        return String(word) + "…"
    }
}
#endif
