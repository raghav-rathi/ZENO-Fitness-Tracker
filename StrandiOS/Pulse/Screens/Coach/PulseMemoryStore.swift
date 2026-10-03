#if os(iOS)
import Foundation
import Observation

// MARK: - My Memory store (WHOOP_UI_SPEC §3.16 [Z] "My Memory is a local MemoryStore")
//
// What the wearer asks Coach to keep in mind: category, title, detail, an Active flag, when it was added and
// the conversations it came from. It is entered by the wearer (typed, spoken, or "Add to My Memory" on one
// of their own messages); nothing is extracted from conversations behind their back. One JSON file in
// Application Support, on this iPhone only.
//
// Only ACTIVE memories reach the provider, and only while AI Settings' MEMORY switch is on: they go with
// every request as standing system context (`AICoachEngine.systemContext`, `PulseCoachEnvelope.standingContext`),
// as they stand when it is sent, so switching one off takes effect on the next question.

struct PulseMemoryItem: Codable, Identifiable, Equatable {
    enum Category: String, Codable, CaseIterable, Identifiable {
        case goals, identity, lifestyle, preferences, events, healthHistory, mood
        var id: String { rawValue }

        var title: String {
            switch self {
            case .goals: return String(localized: "Goals")
            case .identity: return String(localized: "Identity")
            case .lifestyle: return String(localized: "Lifestyle")
            case .preferences: return String(localized: "Preferences")
            case .events: return String(localized: "Events")
            case .healthHistory: return String(localized: "Health history")
            case .mood: return String(localized: "Mood")
            }
        }
    }

    let id: UUID
    var category: Category
    var title: String
    var detail: String
    var isActive: Bool
    let createdAt: Date
    /// The conversations it came from (`PulseCoachThread.id`).
    var sourceThreadIDs: [UUID]

    /// Added in the last day: the list marks it "New".
    func isNew(now: Date = Date()) -> Bool { now.timeIntervalSince(createdAt) < 86_400 }
}

@MainActor
@Observable
final class PulseMemoryStore {
    static let shared = PulseMemoryStore()

    /// AI Settings' MEMORY switch (default on: the store only holds what the wearer added).
    static let enabledKey = "pulse.coach.memoryEnabled"

    /// Newest first.
    private(set) var items: [PulseMemoryItem] = []
    @ObservationIgnored private var loaded = false
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    private init() {}

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    private static var fileURL: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("Pulse", isDirectory: true).appendingPathComponent("coach-memory.json")
    }

    func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let url = Self.fileURL, let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PulseMemoryItem].self, from: data) else { return }
        items = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    /// The memories every request to the provider carries (a question, the morning brief): active ones,
    /// while Memory is switched on.
    var promptItems: [PulseMemoryItem] {
        loadIfNeeded()
        return Self.isEnabled ? items.filter(\.isActive) : []
    }

    func item(_ id: UUID) -> PulseMemoryItem? { items.first { $0.id == id } }

    /// Add what the wearer shared. The first sentence (up to 60 characters) becomes the title.
    @discardableResult
    func add(_ text: String, category: PulseMemoryItem.Category, sourceThread: UUID? = nil,
             now: Date = Date()) -> PulseMemoryItem? {
        loadIfNeeded()
        let detail = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !detail.isEmpty else { return nil }
        let item = PulseMemoryItem(id: UUID(), category: category, title: Self.title(from: detail), detail: detail,
                                   isActive: true, createdAt: now,
                                   sourceThreadIDs: sourceThread.map { [$0] } ?? [])
        items.insert(item, at: 0)
        save()
        return item
    }

    func setActive(_ id: UUID, _ active: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }), items[i].isActive != active else { return }
        items[i].isActive = active
        save()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func deleteAll() {
        items = []
        save()
    }

    static func title(from text: String) -> String {
        let firstSentence = text.split(whereSeparator: { ".!?\n".contains($0) }).first.map(String.init) ?? text
        return firstSentence.firstLine(limit: 60)
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        let snapshot = items
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
#endif
