#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - The activity lists (WHOOP_UI_SPEC §3.8 picker, §3.9 SELECT ACTIVITY / SELECT YOUR ACTIVITY)
//
// Every list Pulse offers draws from ONE catalogue: the shared `WorkoutCatalog` (the cross-platform sport
// names a `WorkoutRow.sport` stores verbatim), sorted into WHOOP's ALL · STRAIN · RECOVERY · SLEEP tabs.
//
// RECOVERY [Z]: WHOOP scores sauna, cold exposure, breathwork and meditation as recovery activities
// (§3.6 "Recovery activity"). The shared catalogue carries Meditation; the rest ride here as suggestions.
// The catalogue's contract allows that ("free-text stays allowed everywhere — this catalogue is the
// suggestion set, not a whitelist", #519): the names are stored exactly as listed, never localised, and an
// Android build displays them verbatim. Android's picker does not offer them yet.
//
// SLEEP: the add flow can log a missed Sleep or Nap (`Repository.addManualNap`); a live session cannot be a
// sleep, so the Start picker leaves that tab out.

/// One entry in an activity list.
struct PulseActivityKind: Identifiable, Hashable {
    enum Category: String, CaseIterable, Hashable {
        case strain, recovery, sleep

        var title: String {
            switch self {
            case .strain: return String(localized: "Strain")
            case .recovery: return String(localized: "Recovery")
            case .sleep: return String(localized: "Sleep")
            }
        }
    }

    /// The stored sport name ("Running"), or the sleep entries' names ("Sleep", "Nap").
    let name: String
    let category: Category
    /// A route makes sense (the "Track Route" toggle; GPS records by default).
    let isDistanceSport: Bool

    var id: String { name }

    /// The SF Symbol drawn beside the name.
    var symbol: String { PulseActivityCatalog.symbol(for: name) }

    /// The UPPERCASE row title.
    var displayName: String { WorkoutSource.displaySport(name) }
}

enum PulseActivityCatalog {

    /// The sleep entries the add flow offers (stored as a manual sleep session, not a workout).
    static let sleepName = "Sleep"
    static let napName = "Nap"

    /// Recovery activities beyond the shared catalogue's Meditation [Z]. Stored verbatim.
    static let recoveryExtras: [String] = [
        "Sauna", "Steam room", "Ice bath", "Cold plunge", "Contrast therapy", "Breathwork", "Massage",
    ]

    /// Shared-catalogue sports that WHOOP files under RECOVERY.
    private static let recoveryCatalogNames: Set<String> = ["meditation"]

    /// Every activity, A–Z, with its category.
    static let all: [PulseActivityKind] = {
        var out: [PulseActivityKind] = WorkoutCatalog.all
            .filter { $0.name != WorkoutCatalog.defaultSportName }
            .map { sport in
                PulseActivityKind(name: sport.name,
                                  category: recoveryCatalogNames.contains(sport.name.lowercased()) ? .recovery : .strain,
                                  isDistanceSport: sport.isDistanceSport)
            }
        out += recoveryExtras.map { PulseActivityKind(name: $0, category: .recovery, isDistanceSport: false) }
        out.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        // "Other" last, as the shared catalogue orders it.
        out.append(PulseActivityKind(name: WorkoutCatalog.defaultSportName, category: .strain, isDistanceSport: false))
        return out
    }()

    /// The two sleep entries (add flow only).
    static let sleepKinds: [PulseActivityKind] = [
        PulseActivityKind(name: sleepName, category: .sleep, isDistanceSport: false),
        PulseActivityKind(name: napName, category: .sleep, isDistanceSport: false),
    ]

    /// The entry for a stored sport name (case-insensitive), or a free-typed one classified as strain.
    static func kind(named name: String) -> PulseActivityKind {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let hit = (all + sleepKinds).first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return hit
        }
        return PulseActivityKind(name: trimmed.isEmpty ? WorkoutCatalog.defaultSportName : trimmed,
                                 category: isRecovery(trimmed) ? .recovery : .strain,
                                 isDistanceSport: WorkoutCatalog.sport(named: trimmed)?.isDistanceSport ?? false)
    }

    /// Whether a stored sport is a recovery activity (exact names, then a few unambiguous words, so an
    /// imported "Infrared Sauna" or "Cold Plunge" reads as one too).
    static func isRecovery(_ sport: String) -> Bool {
        let s = sport.lowercased()
        if recoveryCatalogNames.contains(s) || recoveryExtras.contains(where: { $0.lowercased() == s }) { return true }
        let words = ["sauna", "steam", "ice bath", "cold plunge", "cryotherapy", "contrast therapy", "breathwork",
                     "breathing", "meditat", "massage"]
        return words.contains { s.contains($0) }
    }

    /// The sports most recently picked (Start, Add, Edit), newest first, as list entries.
    static func recent(limit: Int = RecentSportsPrefs.maxCount) -> [PulseActivityKind] {
        Array(RecentSportsPrefs.recent().map { kind(named: $0) }.prefix(limit))
    }

    // MARK: Search [Z]

    /// Words people type for an activity whose catalogue name does not contain them (WHOOP's search is
    /// literal: "gardening" does not find YARD WORK; ZENO's also matches these).
    private static let synonyms: [String: [String]] = [
        "jog": ["Running", "Treadmill run"],
        "run": ["Running", "Treadmill run"],
        "bike": ["Cycling", "Indoor cycle", "Mountain biking", "Spinning"],
        "cycle": ["Cycling", "Indoor cycle", "Mountain biking", "Spinning"],
        "ride": ["Cycling", "Mountain biking", "Horseback riding"],
        "swim": ["Pool swim", "Open-water swim"],
        "gym": ["Strength", "Weightlifting", "Bodybuilding", "Powerlifting", "HIIT", "Calisthenics"],
        "lift": ["Weightlifting", "Strength", "Powerlifting", "Bodybuilding"],
        "weights": ["Weightlifting", "Strength", "Powerlifting", "Bodybuilding"],
        "football": ["Soccer", "American football", "Australian football", "Gaelic football"],
        "hike": ["Hiking", "Rucking"],
        "mma": ["Martial arts", "Kickboxing", "Muay Thai", "Jiu jitsu", "Judo", "Boxing"],
        "bjj": ["Jiu jitsu"],
        "cold": ["Ice bath", "Cold plunge"],
        "heat": ["Sauna", "Steam room"],
        "spa": ["Sauna", "Steam room", "Massage"],
        "breath": ["Breathwork", "Meditation"],
        "mindful": ["Meditation", "Breathwork"],
        "nap": [napName],
        "sleep": [sleepName, napName],
        "stairs": ["Stair climber"],
        "rope": ["Jump rope"],
        "erg": ["Row machine", "Rowing"],
    ]

    /// Entries matching `query`: a word anywhere in the name, then the synonyms. An empty query matches
    /// nothing (the lists show their sections instead).
    static func search(_ query: String, in kinds: [PulseActivityKind]) -> [PulseActivityKind] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        var hits = kinds.filter { kind in
            let name = kind.name.lowercased()
            return name.contains(q) || kind.displayName.lowercased().contains(q)
        }
        let viaSynonym = synonyms.filter { $0.key.hasPrefix(q) || q.hasPrefix($0.key) }.flatMap(\.value)
        for name in viaSynonym {
            if let kind = kinds.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }),
               !hits.contains(kind) {
                hits.append(kind)
            }
        }
        return hits
    }

    // MARK: Glyphs

    /// The SF Symbol for an activity: the shared iconography, with glyphs for the entries it does not know.
    static func symbol(for name: String) -> String {
        switch name.lowercased() {
        case "sleep": return "moon.fill"
        case "nap": return "powersleep"
        case "sauna": return "flame"
        case "steam room": return "humidity"
        case "ice bath", "cold plunge": return "snowflake"
        case "contrast therapy": return "thermometer.medium"
        case "breathwork": return "lungs"
        case "massage": return "hand.raised"
        default:
            if isRecovery(name) && name.lowercased().contains("sauna") { return "flame" }
            return WorkoutTypeIconography.systemSymbolName(for: name)
        }
    }
}
#endif
