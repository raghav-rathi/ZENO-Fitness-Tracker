#if os(iOS)
import Foundation
import Observation

// MARK: - What the Pulse journal keeps beside the journal table
//
// Answers live where they always have: the journal table under "noop-journal" (`Repository`), mood in its
// own series (`MoodStore`). A few things the rebuilt Journal adds have no place there, so they live in
// UserDefaults, on this iPhone only, the same single-user pattern `JournalCatalogStore` uses:
//
//   - the day's NOTE ("Add a note…"). The journal table does have a `notes` column, but it belongs to each
//     (day, question) answer: a day's note on one of them would vanish when that answer is cleared, and a
//     note-only row would read as a behaviour everywhere the table is read (Insights, Android, exports);
//   - the NAME a custom behaviour was created with ("Protein Shake" for "Had a protein shake?");
//   - whether the mood check-in is one of the journal's questions, whether Smart log has been used (the
//     card then folds to one row) and whether the discard dialog was asked not to show again.
//
// None of it crosses the .noopbak backup yet: `BackupSettings` is WhoopStore's byte-identical contract with
// Android, so adding "pulse.journal.notes" is that owner's change on both platforms (ARCHITECTURE.md §9).

@MainActor
@Observable
final class PulseJournalLocalStore {
    static let shared = PulseJournalLocalStore()

    private(set) var notes: [String: String]
    private(set) var customTitles: [String: String]
    var moodIsSelected: Bool { didSet { defaults.set(moodIsSelected, forKey: Keys.mood) } }
    var smartLogUsed: Bool { didSet { defaults.set(smartLogUsed, forKey: Keys.smartLog) } }
    var skipDiscardDialog: Bool { didSet { defaults.set(skipDiscardDialog, forKey: Keys.skipDiscard) } }

    @ObservationIgnored private let defaults: UserDefaults

    private enum Keys {
        static let notes = "pulse.journal.notes"
        static let titles = "pulse.journal.customTitles"
        static let mood = "pulse.journal.moodSelected"
        static let smartLog = "pulse.journal.smartLogUsed"
        static let skipDiscard = "pulse.journal.skipDiscardDialog"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        notes = (defaults.dictionary(forKey: Keys.notes) as? [String: String]) ?? [:]
        customTitles = (defaults.dictionary(forKey: Keys.titles) as? [String: String]) ?? [:]
        moodIsSelected = defaults.object(forKey: Keys.mood) as? Bool ?? true
        smartLogUsed = defaults.bool(forKey: Keys.smartLog)
        skipDiscardDialog = defaults.bool(forKey: Keys.skipDiscard)
    }

    /// The day's note, if any.
    func note(for dayKey: String) -> String? {
        notes[dayKey]
    }

    /// Save (or clear, when blank) a day's note.
    func setNote(_ text: String, for dayKey: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { notes[dayKey] = nil } else { notes[dayKey] = text }
        defaults.set(notes, forKey: Keys.notes)
    }

    /// Remember a custom behaviour's name.
    func setTitle(_ title: String, for canonical: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        customTitles[canonical] = trimmed.isEmpty ? nil : trimmed
        defaults.set(customTitles, forKey: Keys.titles)
    }
}
#endif
