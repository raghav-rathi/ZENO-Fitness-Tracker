#if os(iOS)
import SwiftUI
import Foundation

// MARK: - Behaviours, WHOOP-structured, over ZENO's journal catalog (WHOOP_UI_SPEC §3.17, §3.17b, §3.18)
//
// ZENO's journal stores one row per (day, question) under the question's verbatim CANONICAL key
// (`JournalCatalogStore`, shared with Android and with imported WHOOP history). That key is never changed
// here. This file is the presentation layer the Pulse journal draws with:
//
//   - a WHOOP-style NAME ("Alcohol") and QUESTION ("Had any alcoholic drinks?") for each behaviour, so the
//     starter set reads in WHOOP's phrasing while its stored key stays "Did you drink any alcohol?";
//   - one of WHOOP's nine CATEGORIES (the SELECT BEHAVIORS tabs) and a journal SECTION (DAYTIME,
//     NIGHTTIME, STATUS);
//   - a numeric FOLLOW-UP where one makes sense ("How many drinks?"), saved as the yes answer's
//     `numericValue`, and the buckets Behavior Details breaks it into;
//   - search terms (exact names, then synonyms, then a typo-tolerant match) and ZENO-written copy.
//
// The starter questions keep their keys; the library's other behaviours are offered under SELECT BEHAVIORS
// and, once chosen, join the catalog as ordinary custom items keyed by their question. A user's rename of a
// question (`displayName`) always wins over the library's wording. Imported WHOOP questions match a library
// behaviour through its aliases; anything unknown is shown as itself.

/// WHOOP's nine behaviour categories (the SELECT BEHAVIORS tabs, after ALL and CUSTOM BEHAVIORS).
enum PulseBehaviorCategory: String, CaseIterable, Identifiable {
    case drugsMedication, healthSymptoms, hormonalHealth, lifestyle, mentalWellbeing, nutrition, recovery,
         sleepCircadian, supplements

    var id: String { rawValue }

    var title: String {
        switch self {
        case .drugsMedication: return String(localized: "Drugs & Medication")
        case .healthSymptoms: return String(localized: "Health & Symptoms")
        case .hormonalHealth: return String(localized: "Hormonal Health")
        case .lifestyle: return String(localized: "Lifestyle")
        case .mentalWellbeing: return String(localized: "Mental Wellbeing")
        case .nutrition: return String(localized: "Nutrition")
        case .recovery: return String(localized: "Recovery")
        case .sleepCircadian: return String(localized: "Sleep & Circadian Health")
        case .supplements: return String(localized: "Supplements")
        }
    }

    /// The catalog group a behaviour of this category is stored under (ZENO's six groups, shared with
    /// Android: display and organisation only).
    var group: JournalGroup {
        switch self {
        case .supplements: return .supplements
        case .nutrition: return .nutrition
        case .lifestyle, .sleepCircadian, .recovery: return .lifestyle
        case .healthSymptoms, .hormonalHealth, .drugsMedication: return .health
        case .mentalWellbeing: return .behaviour
        }
    }

    /// The category an unknown behaviour of a catalog group falls in.
    init(group: JournalGroup) {
        switch group {
        case .supplements: self = .supplements
        case .nutrition: self = .nutrition
        case .lifestyle, .other: self = .lifestyle
        case .health: self = .healthSymptoms
        case .behaviour: self = .mentalWellbeing
        }
    }
}

/// The journal's sections, in WHOOP's order (through mid-Sep 2026; ZENO keeps them, §3.17 item 9 [Z]).
enum PulseJournalSection: Int, CaseIterable, Identifiable {
    case daytime, nighttime, status

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .daytime: return String(localized: "Daytime")
        case .nighttime: return String(localized: "Nighttime")
        case .status: return String(localized: "Status")
        }
    }
}

/// A quantity asked once a behaviour is answered ✓ ("For how long (minutes)?"), saved as the answer's
/// numeric value, and the buckets Behavior Details splits it into.
struct PulseBehaviorFollowUp: Equatable {
    /// The row's question ("How many drinks?").
    let question: String
    /// The unit as the capsule prints it, singular and plural ("Drink" / "Drinks").
    let unitSingular: String
    let unitPlural: String
    /// The wheel's choices.
    let options: [Double]
    /// Bucket lower bounds for the Behavior Details breakdown ([1, 2, 7] → 1, 2-6, 7+).
    let bucketEdges: [Double]
    /// The breakdown's caps header ("HOW MANY ALCOHOLIC DRINKS DID YOU HAVE?").
    let breakdownTitle: String
    /// Where the wheel starts before anything is logged.
    var defaultValue: Double?

    /// The wheel's starting value: the logged amount, else the default, else the first option.
    func startValue(_ logged: Double?) -> Double {
        logged ?? defaultValue ?? options.first ?? 1
    }

    /// "15 Minutes", "1 Drink".
    func valueText(_ value: Double) -> String {
        let number = PulseBehaviorFollowUp.number(value)
        return "\(number) \(value == 1 ? unitSingular : unitPlural)"
    }

    /// "-- Minutes": the empty capsule.
    var emptyText: String { "-- \(unitPlural)" }

    /// A bucket's label: "1 Drink", "2-6 Drinks", "7+ Drinks".
    func bucketLabel(lower: Double, upper: Double?) -> String {
        let lo = PulseBehaviorFollowUp.number(lower)
        guard let upper else { return "\(lo)+ \(unitPlural)" }
        let hiValue = upper - 1
        if hiValue <= lower { return "\(lo) \(lower == 1 ? unitSingular : unitPlural)" }
        return "\(lo)-\(PulseBehaviorFollowUp.number(hiValue)) \(unitPlural)"
    }

    static func number(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", v)
    }

    // The follow-ups the library uses.

    static let drinks = PulseBehaviorFollowUp(
        question: String(localized: "How many drinks?"), unitSingular: String(localized: "Drink"),
        unitPlural: String(localized: "Drinks"), options: Array(1...12).map(Double.init), bucketEdges: [1, 2, 7],
        breakdownTitle: String(localized: "How many alcoholic drinks did you have?"))
    static let servings = PulseBehaviorFollowUp(
        question: String(localized: "How many servings?"), unitSingular: String(localized: "Serving"),
        unitPlural: String(localized: "Servings"), options: Array(1...10).map(Double.init), bucketEdges: [1, 3, 6],
        breakdownTitle: String(localized: "How many servings did you have?"))
    static let minutes = PulseBehaviorFollowUp(
        question: String(localized: "For how long (minutes)?"), unitSingular: String(localized: "Minute"),
        unitPlural: String(localized: "Minutes"), options: stride(from: 5.0, through: 120, by: 5).map { $0 },
        bucketEdges: [1, 16, 31], breakdownTitle: String(localized: "For how long?"), defaultValue: 15)
    static let meditationMinutes = PulseBehaviorFollowUp(
        question: String(localized: "For how long (minutes)?"), unitSingular: String(localized: "Minute"),
        unitPlural: String(localized: "Minutes"), options: stride(from: 5.0, through: 90, by: 5).map { $0 },
        bucketEdges: [1, 11, 21], breakdownTitle: String(localized: "For how long?"), defaultValue: 10)
    static let grams = PulseBehaviorFollowUp(
        question: String(localized: "How many grams?"), unitSingular: String(localized: "Gram"),
        unitPlural: String(localized: "Grams"), options: stride(from: 10.0, through: 300, by: 10).map { $0 },
        bucketEdges: [1, 100, 150], breakdownTitle: String(localized: "How many grams did you have?"),
        defaultValue: 30)

    /// A follow-up for a custom numeric item, labelled with its own unit ("mg", "units").
    static func custom(unit: String?) -> PulseBehaviorFollowUp {
        let label = (unit?.trimmingCharacters(in: .whitespaces)).flatMap { $0.isEmpty ? nil : $0 }
            ?? String(localized: "Units")
        let lower = label.lowercased()
        let options: [Double]
        if lower.contains("mg") {
            options = stride(from: 25.0, through: 1000, by: 25).map { $0 }
        } else if lower.hasPrefix("min") {
            options = stride(from: 5.0, through: 180, by: 5).map { $0 }
        } else if lower == "g" || lower.hasPrefix("gram") {
            options = stride(from: 5.0, through: 300, by: 5).map { $0 }
        } else {
            options = Array(1...30).map(Double.init)
        }
        return PulseBehaviorFollowUp(question: String(localized: "How much (\(label))?"), unitSingular: label,
                                     unitPlural: label, options: options, bucketEdges: [],
                                     breakdownTitle: String(localized: "How much did you have?"))
    }
}

/// One behaviour the library knows.
struct PulseBehaviorDefinition {
    /// Stable library id ("alcohol").
    let id: String
    /// The stored question key: a starter's ZENO key, else the WHOOP-style question itself.
    let canonical: String
    /// Other question strings that mean this behaviour (WHOOP export phrasing), matched case-insensitively.
    var aliases: [String] = []
    let title: String
    let question: String
    let category: PulseBehaviorCategory
    var section: PulseJournalSection = .daytime
    let symbol: String
    var synonyms: [String] = []
    var followUp: PulseBehaviorFollowUp?
    /// The plan goal's name and whether the goal is to AVOID it ("Avoid Late Meal").
    var goalTitle: String?
    var avoid = false
    /// "Impact of …" paragraphs and a RECOMMENDATION tip (ZENO-written).
    var about: [String] = []
    var tip: String?
    /// One of ZENO's starter questions (journal defaults), as opposed to an optional library behaviour.
    var isStarter = false
}

/// A behaviour as the screens draw it: a catalog item (or a library suggestion) resolved through the
/// library.
struct PulseBehavior: Identifiable, Equatable {
    /// The stored question key (or an auto-tracked behaviour's id, "auto.…").
    let canonical: String
    let title: String
    let question: String
    let category: PulseBehaviorCategory
    let section: PulseJournalSection
    let symbol: String
    let followUp: PulseBehaviorFollowUp?
    /// The library definition, when the behaviour has one.
    let libraryID: String?
    /// A user-made behaviour (shows the outlined "Custom" chip).
    let isCustom: Bool
    /// Part of the journal now (not hidden, or a library behaviour already added).
    let isSelected: Bool
    /// Tracked from ZENO's own data, never logged (§3.18 ✧ chip).
    var isAuto = false

    var id: String { canonical }

    static func == (lhs: PulseBehavior, rhs: PulseBehavior) -> Bool {
        lhs.canonical == rhs.canonical && lhs.title == rhs.title && lhs.question == rhs.question
            && lhs.isSelected == rhs.isSelected && lhs.isCustom == rhs.isCustom && lhs.section == rhs.section
            && lhs.category == rhs.category
    }
}

/// The library and its resolver.
enum PulseBehaviorLibrary {

    /// The mood check-in's pseudo-behaviour (stored in `MoodStore`, not the journal table).
    static let moodID = "zeno.mood"

    /// Auto-tracked behaviour ids (Behavior Insights).
    enum Auto: String, CaseIterable {
        case sleepPerformance = "auto.sleepPerformance"
        case dayStrain = "auto.dayStrain"
        case lateWorkout = "auto.lateWorkout"
        case consistentBedTime = "auto.consistentBedTime"
        case consistentWakeTime = "auto.consistentWakeTime"

        var title: String {
            switch self {
            case .sleepPerformance: return String(localized: "85%+ Sleep Performance")
            case .dayStrain: return String(localized: "10+ Day Strain")
            case .lateWorkout: return String(localized: "Late Workout")
            case .consistentBedTime: return String(localized: "Consistent Bed Time")
            case .consistentWakeTime: return String(localized: "Consistent Wake Time")
            }
        }

        var symbol: String {
            switch self {
            case .sleepPerformance: return "bed.double"
            case .dayStrain: return "figure.run"
            case .lateWorkout: return "moon.stars"
            case .consistentBedTime: return "clock"
            case .consistentWakeTime: return "alarm"
            }
        }

        var about: [String] {
            switch self {
            case .sleepPerformance:
                return [String(localized: "Sleep Performance compares the sleep you got with the sleep you needed. A night at 85% or more counts here; anything below it counts as a night without."),
                        String(localized: "ZENO reads it from your strap, so there is nothing to log.")]
            case .dayStrain:
                return [String(localized: "A day with a Strain of 10 or more, measured on the 0–21 scale, compared with the next morning's Recovery."),
                        String(localized: "Harder days ask more of the night that follows them. How much depends on how used to the load you are.")]
            case .lateWorkout:
                return [String(localized: "A late workout is an activity that ended within 3 hours of falling asleep."),
                        String(localized: "Exercise raises heart rate and body temperature for a while afterwards. For some people that delays sleep or makes its first hours lighter; others see no difference.")]
            case .consistentBedTime:
                return [String(localized: "A night counts as consistent when you fell asleep within 30 minutes of your usual time over the previous two weeks."),
                        String(localized: "A steady bedtime helps your body anticipate sleep, which often makes falling asleep easier.")]
            case .consistentWakeTime:
                return [String(localized: "A morning counts as consistent when you woke within 30 minutes of your usual time over the previous two weeks."),
                        String(localized: "A regular wake time anchors your body clock more than any other habit.")]
            }
        }

        var tip: String {
            switch self {
            case .sleepPerformance: return String(localized: "Plan your bedtime around tonight's sleep need on Tonight's Sleep, so more nights reach 85%.")
            case .dayStrain: return String(localized: "Match hard days to green Recoveries, and follow a big day with an easier one when your Recovery dips.")
            case .lateWorkout: return String(localized: "If late sessions cost you Recovery, try finishing training a little earlier, or keep evening sessions easy.")
            case .consistentBedTime: return String(localized: "Pick a bedtime you can keep on most nights, weekends included, and let Tonight's Sleep remind you.")
            case .consistentWakeTime: return String(localized: "Keep your alarm within half an hour of the same time every day, even after a late night.")
            }
        }
    }

    // MARK: The definitions

    static let definitions: [PulseBehaviorDefinition] = [
        // ZENO's starter questions (their stored keys never change).
        PulseBehaviorDefinition(
            id: "alcohol", canonical: "Did you drink any alcohol?",
            aliases: ["Have any alcoholic drinks?", "Had any alcoholic drinks?", "Consumed alcohol?", "Drank alcohol?"],
            title: String(localized: "Alcohol"), question: String(localized: "Had any alcoholic drinks?"),
            category: .nutrition, symbol: "wineglass",
            synonyms: ["drink", "drinks", "wine", "beer", "booze", "spirits", "cocktail", "liquor"],
            followUp: .drinks, goalTitle: String(localized: "Avoid Alcohol"), avoid: true,
            about: [String(localized: "Your body treats alcohol as something to clear, and it keeps working on it after you fall asleep. While it does, heart rate tends to stay higher and heart rate variability lower than usual, and the second half of the night is often lighter and more broken."),
                    String(localized: "How much, and how late, both matter: one early drink and several close to bedtime are very different nights for most people.")],
            tip: String(localized: "Try finishing your last drink earlier in the evening, or skipping it before a demanding day, then compare the mornings."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "lateCaffeine", canonical: "Did you have caffeine late in the day?",
            aliases: ["Had caffeine late in the day?", "Consumed caffeine late in the day?"],
            title: String(localized: "Late Caffeine"), question: String(localized: "Had caffeine late in the day?"),
            category: .nutrition, symbol: "cup.and.saucer",
            synonyms: ["coffee", "espresso", "tea", "energy drink", "caffeine", "cola"],
            goalTitle: String(localized: "Avoid Late Caffeine"), avoid: true,
            about: [String(localized: "Caffeine blocks the signal that builds sleep pressure through the day, and it takes hours to clear: a coffee in the afternoon can still be partly active at bedtime."),
                    String(localized: "Late caffeine can make sleep lighter even when falling asleep feels normal.")],
            tip: String(localized: "Set yourself a caffeine cut-off around eight hours before bed and see whether your Recovery follows."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "screenInBed", canonical: "Did you view a screen in bed?",
            aliases: ["Viewed a screen device in bed?", "View a screen device in bed?"],
            title: String(localized: "Device (e.g. Phone) In Bed"),
            question: String(localized: "Viewed a screen device in bed?"),
            category: .sleepCircadian, section: .nighttime, symbol: "iphone",
            synonyms: ["phone", "screen", "tablet", "tv", "scrolling", "device"],
            goalTitle: String(localized: "Avoid Screens In Bed"), avoid: true,
            about: [String(localized: "Screens in bed keep the mind busy and push back the moment you put the day down, and bright light late in the evening can delay your body clock."),
                    String(localized: "The habit often costs more through the minutes it adds before sleep than through the light itself.")],
            tip: String(localized: "Leave the phone outside the bedroom or across the room for a week and compare your mornings."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "lateMeal", canonical: "Did you eat close to bedtime?",
            aliases: ["Ate food close to bedtime?", "Eat any food close to bedtime?", "Ate a late meal?"],
            title: String(localized: "Late Meal"), question: String(localized: "Ate food close to bedtime?"),
            category: .nutrition, section: .nighttime, symbol: "fork.knife",
            synonyms: ["dinner", "snack", "food", "eating", "meal", "supper"],
            goalTitle: String(localized: "Avoid Late Meal"), avoid: true,
            about: [String(localized: "Digesting a meal raises your metabolism and heart rate for a few hours. Eaten close to bed, that work overlaps the first part of the night, when the deepest sleep usually happens."),
                    String(localized: "Large or rich meals tend to matter more than a light snack.")],
            tip: String(localized: "Aim to finish your last meal two to three hours before bed, and keep anything later small."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "stress", canonical: "Did you feel stressed?",
            aliases: ["Felt stressed?", "Experienced stress?", "Feel stressed?"],
            title: String(localized: "Stress"), question: String(localized: "Felt stressed?"),
            category: .mentalWellbeing, symbol: "brain.head.profile",
            synonyms: ["anxious", "anxiety", "pressure", "stressed", "tension", "overwhelmed"],
            goalTitle: String(localized: "Avoid Stress"), avoid: true,
            about: [String(localized: "Stress keeps the body's alert system switched on. A stressful day can leave heart rate higher and heart rate variability lower into the night, which Recovery reflects the next morning."),
                    String(localized: "Short spells of stress are normal; it is the ones that follow you to bed that tend to show up.")],
            tip: String(localized: "On stressful days, give yourself a wind-down before bed: a short walk, a breathing session or writing tomorrow's list."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "sauna", canonical: "Did you use a sauna?",
            aliases: ["Used a sauna?", "Use a sauna?", "Dry sauna?"],
            title: String(localized: "Sauna"), question: String(localized: "Used a sauna?"),
            category: .recovery, symbol: "flame",
            synonyms: ["steam", "heat", "sweat", "steam room"],
            followUp: .minutes, goalTitle: String(localized: "Sauna"),
            about: [String(localized: "A sauna session raises heart rate and body temperature, and many people find the cool-down afterwards relaxing."),
                    String(localized: "Its effect on the night depends on timing and on staying hydrated.")],
            tip: String(localized: "If sauna days help your Recovery, keep the sessions and drink water afterwards; if they hurt it, try an earlier session."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "sharedBed", canonical: "Did you share your bed?",
            aliases: ["Shared your bed?", "Share your bed?", "Shared bed?"],
            title: String(localized: "Shared Bed"), question: String(localized: "Shared your bed?"),
            category: .sleepCircadian, section: .nighttime, symbol: "bed.double",
            synonyms: ["partner", "co-sleeping", "pet", "spouse"],
            about: [String(localized: "Sharing a bed changes the night: another person's (or pet's) movement, warmth and schedule can wake you briefly without you remembering it."),
                    String(localized: "For many people the comfort outweighs the disruption; your data shows which way it goes for you.")],
            tip: String(localized: "If shared nights cost you Recovery, a larger bed or separate covers can help."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "sick", canonical: "Did you feel sick or ill?",
            aliases: ["Feeling sick or ill?", "Felt sick or ill?", "Feel sick or ill?"],
            title: String(localized: "Sick or Ill"), question: String(localized: "Feeling sick or ill?"),
            category: .healthSymptoms, section: .status, symbol: "thermometer.medium",
            synonyms: ["ill", "cold", "flu", "fever", "unwell", "sick"],
            about: [String(localized: "Fighting off an illness takes energy. Resting heart rate often rises and heart rate variability falls, sometimes before you feel unwell, and Recovery usually drops with them."),
                    String(localized: "Logging sick days also keeps them from muddying what the rest of your behaviours seem to do.")],
            tip: String(localized: "When you are unwell, let Recovery guide you: keep Strain low and prioritise sleep until it climbs back."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "magnesium", canonical: "Did you take magnesium?",
            aliases: ["Took magnesium?", "Take magnesium?", "Took a magnesium supplement?"],
            title: String(localized: "Magnesium"), question: String(localized: "Took magnesium?"),
            category: .supplements, section: .nighttime, symbol: "pills",
            synonyms: ["supplement", "mag", "glycinate", "citrate"],
            goalTitle: String(localized: "Magnesium"),
            about: [String(localized: "Magnesium is a mineral involved in muscle and nerve function. Some people take it in the evening as part of a wind-down routine."),
                    String(localized: "Whether it changes your Recovery is exactly what logging it can show.")],
            tip: String(localized: "Take it at a consistent time so your log compares like with like, and check with a professional before starting any supplement."),
            isStarter: true),
        PulseBehaviorDefinition(
            id: "reading", canonical: "Did you read before bed?",
            aliases: ["Read (non-screened device) while in bed?", "Read before bed?", "Read in bed?"],
            title: String(localized: "Reading In Bed"),
            question: String(localized: "Read (non-screened device) while in bed?"),
            category: .sleepCircadian, section: .nighttime, symbol: "book",
            synonyms: ["book", "kindle", "read", "novel"],
            goalTitle: String(localized: "Read Before Bed"),
            about: [String(localized: "Reading a book or e-ink device is a common wind-down that replaces screens and gives the mind something calm to settle on.")],
            tip: String(localized: "Keep a book by the bed and swap the phone for it on a few nights this week."),
            isStarter: true),

        // The library: optional behaviours offered under SELECT BEHAVIORS.
        PulseBehaviorDefinition(
            id: "caffeine", canonical: "Consumed caffeine?", aliases: ["Had caffeine?", "Drank coffee?"],
            title: String(localized: "Caffeine"), question: String(localized: "Consumed caffeine?"),
            category: .nutrition, symbol: "cup.and.saucer.fill",
            synonyms: ["coffee", "espresso", "tea", "latte", "energy drink", "matcha"],
            followUp: .servings, goalTitle: String(localized: "Avoid Caffeine"), avoid: true,
            about: [String(localized: "Caffeine sharpens alertness by blocking the build-up of sleep pressure. How much, and how late in the day, decide whether it reaches your night.")],
            tip: String(localized: "Keep caffeine to the morning and early afternoon and see whether your Recovery responds.")),
        PulseBehaviorDefinition(
            id: "hydration", canonical: "Drank enough water?", aliases: ["Hydrated sufficiently?", "Stayed hydrated?"],
            title: String(localized: "Hydration"), question: String(localized: "Drank enough water?"),
            category: .nutrition, symbol: "drop", synonyms: ["water", "hydrate", "fluids", "electrolyte"],
            goalTitle: String(localized: "Hydration"),
            about: [String(localized: "Even mild dehydration raises heart rate for the same effort and can leave you feeling flat.")],
            tip: String(localized: "Keep water within reach through the day, and drink more on hot or hard days.")),
        PulseBehaviorDefinition(
            id: "protein", canonical: "Consumed protein?", aliases: ["Ate enough protein?", "Hit your protein goal?"],
            title: String(localized: "Protein"), question: String(localized: "Consumed protein?"),
            category: .nutrition, symbol: "fork.knife.circle", synonyms: ["protein", "shake", "meat", "eggs"],
            followUp: .grams, goalTitle: String(localized: "Protein Intake"),
            about: [String(localized: "Protein supplies what muscles rebuild from after training.")]),
        PulseBehaviorDefinition(
            id: "addedSugar", canonical: "Consumed added sugar?", title: String(localized: "Added Sugar"),
            question: String(localized: "Consumed added sugar?"), category: .nutrition, symbol: "birthday.cake",
            synonyms: ["sugar", "sweets", "dessert", "candy", "soda"], goalTitle: String(localized: "Avoid Added Sugar"),
            avoid: true),
        PulseBehaviorDefinition(
            id: "fasting", canonical: "Practiced intermittent fasting?", title: String(localized: "Intermittent Fasting"),
            question: String(localized: "Practiced intermittent fasting?"), category: .nutrition, symbol: "timer",
            synonyms: ["fast", "fasting", "time-restricted"]),
        PulseBehaviorDefinition(
            id: "plantBased", canonical: "Followed a plant-based diet?", aliases: ["Following a vegan diet"],
            title: String(localized: "Plant-Based Diet"), question: String(localized: "Followed a plant-based diet?"),
            category: .nutrition, symbol: "carrot", synonyms: ["vegan", "vegetarian", "plants"]),
        PulseBehaviorDefinition(
            id: "electrolytes", canonical: "Took electrolyte supplements?", title: String(localized: "Electrolytes"),
            question: String(localized: "Took electrolyte supplements?"), category: .supplements, symbol: "drop.circle",
            synonyms: ["electrolyte", "salt", "sodium", "lmnt"]),
        PulseBehaviorDefinition(
            id: "creatine", canonical: "Took creatine?", title: String(localized: "Creatine"),
            question: String(localized: "Took creatine?"), category: .supplements, symbol: "pills.circle",
            synonyms: ["creatine", "supplement"]),
        PulseBehaviorDefinition(
            id: "melatonin", canonical: "Took a melatonin supplement?", aliases: ["Take a melatonin supplement?"],
            title: String(localized: "Melatonin"), question: String(localized: "Took a melatonin supplement?"),
            category: .supplements, section: .nighttime, symbol: "moon.zzz", synonyms: ["melatonin", "sleep aid"]),
        PulseBehaviorDefinition(
            id: "coldShower", canonical: "Took a cold shower?", aliases: ["Took a cold shower"],
            title: String(localized: "Cold Shower"), question: String(localized: "Took a cold shower?"),
            category: .recovery, symbol: "shower", synonyms: ["cold", "shower", "cold exposure"],
            goalTitle: String(localized: "Cold Shower"),
            about: [String(localized: "Cold exposure briefly stresses the body and many people feel more alert afterwards. Its effect on Recovery varies from person to person.")]),
        PulseBehaviorDefinition(
            id: "iceBath", canonical: "Took an ice bath?", title: String(localized: "Ice Bath"),
            question: String(localized: "Took an ice bath?"), category: .recovery, symbol: "snowflake",
            synonyms: ["cold plunge", "ice", "cold water", "plunge"], followUp: .minutes,
            goalTitle: String(localized: "Ice Bath")),
        PulseBehaviorDefinition(
            id: "stretching", canonical: "Spent time stretching?", aliases: ["Spend time stretching?"],
            title: String(localized: "Stretching"), question: String(localized: "Spent time stretching?"),
            category: .recovery, symbol: "figure.cooldown", synonyms: ["stretch", "mobility", "yoga", "foam roll"],
            followUp: .minutes, goalTitle: String(localized: "Stretching")),
        PulseBehaviorDefinition(
            id: "restDay", canonical: "Took a rest day?", title: String(localized: "Rest Day"),
            question: String(localized: "Took a rest day?"), category: .recovery, symbol: "sofa",
            synonyms: ["rest", "off day", "recovery day"], goalTitle: String(localized: "Rest Day"),
            about: [String(localized: "A rest day takes training load off so the body can absorb the work already done.")]),
        PulseBehaviorDefinition(
            id: "meditation", canonical: "Meditated?", aliases: ["Did you meditate?", "Practiced meditation?"],
            title: String(localized: "Meditation"), question: String(localized: "Meditated?"),
            category: .mentalWellbeing, symbol: "figure.mind.and.body",
            synonyms: ["meditate", "mindfulness", "breathwork", "breathing", "calm"],
            followUp: .meditationMinutes, goalTitle: String(localized: "Meditation"),
            about: [String(localized: "Meditation and slow breathing shift the nervous system towards rest, which some people see as higher heart rate variability that night.")],
            tip: String(localized: "Even ten minutes before bed counts. Log it on the days you do it and the days you don't.")),
        PulseBehaviorDefinition(
            id: "gratitude", canonical: "Expressed gratitude?", title: String(localized: "Gratitude"),
            question: String(localized: "Expressed gratitude?"), category: .mentalWellbeing, symbol: "heart",
            synonyms: ["thankful", "journal", "grateful"], goalTitle: String(localized: "Gratitude")),
        PulseBehaviorDefinition(
            id: "anxious", canonical: "Felt nervous or anxious?", title: String(localized: "Anxiety"),
            question: String(localized: "Felt nervous or anxious?"), category: .mentalWellbeing,
            symbol: "cloud.drizzle", synonyms: ["nervous", "anxious", "worry", "worried"]),
        PulseBehaviorDefinition(
            id: "motivated", canonical: "Felt motivated?", title: String(localized: "Motivation"),
            question: String(localized: "Felt motivated?"), category: .mentalWellbeing, symbol: "bolt",
            synonyms: ["driven", "energised", "energized"]),
        PulseBehaviorDefinition(
            id: "social", canonical: "Connected with family and/or friends?",
            title: String(localized: "Social Connection"), question: String(localized: "Connected with family and/or friends?"),
            category: .mentalWellbeing, symbol: "person.2", synonyms: ["friends", "family", "social", "people"],
            goalTitle: String(localized: "Social Connection")),
        PulseBehaviorDefinition(
            id: "outdoors", canonical: "Spent time outdoors?", aliases: ["Spend time outdoors?"],
            title: String(localized: "Time Outdoors"), question: String(localized: "Spent time outdoors?"),
            category: .lifestyle, symbol: "tree", synonyms: ["outside", "nature", "walk", "fresh air"],
            goalTitle: String(localized: "Time Outdoors")),
        PulseBehaviorDefinition(
            id: "airTravel", canonical: "Traveled on a plane?", title: String(localized: "Air Travel"),
            question: String(localized: "Traveled on a plane?"), category: .lifestyle, symbol: "airplane",
            synonyms: ["flight", "plane", "flying", "travel", "jet lag"]),
        PulseBehaviorDefinition(
            id: "vacation", canonical: "Took a vacation day?", title: String(localized: "Vacation Day"),
            question: String(localized: "Took a vacation day?"), category: .lifestyle, section: .status,
            symbol: "beach.umbrella", synonyms: ["holiday", "vacation", "day off"]),
        PulseBehaviorDefinition(
            id: "morningSunlight", canonical: "Viewed sunlight within 30 minutes of waking?",
            title: String(localized: "Morning Sunlight"),
            question: String(localized: "Viewed sunlight within 30 minutes of waking?"),
            category: .sleepCircadian, symbol: "sun.max", synonyms: ["sun", "sunlight", "daylight", "morning light"],
            goalTitle: String(localized: "Morning Sunlight"),
            about: [String(localized: "Daylight soon after waking is the strongest signal your body clock gets, and it helps set the time you will feel sleepy that evening.")]),
        PulseBehaviorDefinition(
            id: "ownBed", canonical: "Slept in your own bed?", aliases: ["Slept in the same bed as usual", "Slept in the same bed as usual?"],
            title: String(localized: "Sleep In Own Bed"), question: String(localized: "Slept in your own bed?"),
            category: .sleepCircadian, section: .nighttime, symbol: "bed.double.fill",
            synonyms: ["home", "own bed", "hotel"]),
        PulseBehaviorDefinition(
            id: "darkRoom", canonical: "Slept in a dark room?", aliases: ["Sleep in a dark room?"],
            title: String(localized: "Dark Room"), question: String(localized: "Slept in a dark room?"),
            category: .sleepCircadian, section: .nighttime, symbol: "moon", synonyms: ["dark", "blackout", "curtains"]),
        PulseBehaviorDefinition(
            id: "sleepMask", canonical: "Wore a sleep mask?", title: String(localized: "Sleep Mask"),
            question: String(localized: "Wore a sleep mask?"), category: .sleepCircadian, section: .nighttime,
            symbol: "eye.slash", synonyms: ["mask", "eye mask"]),
        PulseBehaviorDefinition(
            id: "earplugs", canonical: "Wore earplugs while sleeping?", title: String(localized: "Earplugs"),
            question: String(localized: "Wore earplugs while sleeping?"), category: .sleepCircadian,
            section: .nighttime, symbol: "ear", synonyms: ["earplugs", "noise", "ear plugs"]),
        PulseBehaviorDefinition(
            id: "mouthTape", canonical: "Wore mouth tape while sleeping?", title: String(localized: "Mouth Tape"),
            question: String(localized: "Wore mouth tape while sleeping?"), category: .sleepCircadian,
            section: .nighttime, symbol: "lungs", synonyms: ["tape", "nasal breathing"]),
        PulseBehaviorDefinition(
            id: "hotShower", canonical: "Took a hot shower before bed?", title: String(localized: "Hot Shower Before Bed"),
            question: String(localized: "Took a hot shower before bed?"), category: .sleepCircadian,
            section: .nighttime, symbol: "shower.fill", synonyms: ["bath", "hot shower", "warm"]),
        PulseBehaviorDefinition(
            id: "blueLight", canonical: "Wore blue-light-blocking glasses?", title: String(localized: "Blue-Light Glasses"),
            question: String(localized: "Wore blue-light-blocking glasses?"), category: .sleepCircadian,
            section: .nighttime, symbol: "eyeglasses", synonyms: ["glasses", "blue light", "blockers"]),
        PulseBehaviorDefinition(
            id: "nicotine", canonical: "Consumed nicotine?", title: String(localized: "Nicotine"),
            question: String(localized: "Consumed nicotine?"), category: .drugsMedication, symbol: "smoke",
            synonyms: ["vape", "vaping", "pouch", "snus", "nicotine"], goalTitle: String(localized: "Avoid Nicotine"),
            avoid: true,
            about: [String(localized: "Nicotine is a stimulant: it raises heart rate and blood pressure and can make sleep lighter and more broken.")]),
        PulseBehaviorDefinition(
            id: "tobacco", canonical: "Used tobacco in any form?", title: String(localized: "Tobacco"),
            question: String(localized: "Used tobacco in any form?"), category: .drugsMedication, symbol: "smoke.fill",
            synonyms: ["smoking", "cigarette", "cigar", "smoke"], goalTitle: String(localized: "Avoid Tobacco"),
            avoid: true),
        PulseBehaviorDefinition(
            id: "cannabis", canonical: "Used cannabis?", title: String(localized: "Cannabis"),
            question: String(localized: "Used cannabis?"), category: .drugsMedication, symbol: "leaf",
            synonyms: ["weed", "marijuana", "thc", "cbd", "edible"], goalTitle: String(localized: "Avoid Cannabis"),
            avoid: true),
        PulseBehaviorDefinition(
            id: "sleepMedication", canonical: "Took sleep medication?", title: String(localized: "Sleep Medication"),
            question: String(localized: "Took sleep medication?"), category: .drugsMedication, section: .nighttime,
            symbol: "pills.fill", synonyms: ["sleeping pill", "medication", "sleep aid"]),
        PulseBehaviorDefinition(
            id: "painMedication", canonical: "Took pain medication?", title: String(localized: "Pain Medication"),
            question: String(localized: "Took pain medication?"), category: .drugsMedication, symbol: "cross.vial",
            synonyms: ["ibuprofen", "paracetamol", "painkiller", "advil", "tylenol"]),
        PulseBehaviorDefinition(
            id: "injury", canonical: "Have an injury or wound?", title: String(localized: "Injury"),
            question: String(localized: "Have an injury or wound?"), category: .healthSymptoms, section: .status,
            symbol: "bandage", synonyms: ["injured", "wound", "hurt", "sprain"]),
        PulseBehaviorDefinition(
            id: "headache", canonical: "Had a headache?", title: String(localized: "Headache"),
            question: String(localized: "Had a headache?"), category: .healthSymptoms, symbol: "bolt.heart",
            synonyms: ["migraine", "head", "pain"]),
        PulseBehaviorDefinition(
            id: "birthControl", canonical: "Took hormonal birth control?", title: String(localized: "Hormonal Birth Control"),
            question: String(localized: "Took hormonal birth control?"), category: .hormonalHealth,
            symbol: "calendar.circle", synonyms: ["pill", "contraceptive", "birth control"]),
        PulseBehaviorDefinition(
            id: "hotFlashes", canonical: "Experienced hot flashes?", title: String(localized: "Hot Flashes"),
            question: String(localized: "Experienced hot flashes?"), category: .hormonalHealth,
            symbol: "thermometer.sun", synonyms: ["menopause", "flushes", "night sweats"]),
    ]

    /// The definition matching a stored key or a WHOOP-export question, if any.
    static func definition(for question: String) -> PulseBehaviorDefinition? {
        let key = JournalCatalogStore.norm(question)
        return byKey[key]
    }

    static func definition(id: String) -> PulseBehaviorDefinition? {
        definitions.first { $0.id == id }
    }

    private static let byKey: [String: PulseBehaviorDefinition] = {
        var out: [String: PulseBehaviorDefinition] = [:]
        for d in definitions {
            out[JournalCatalogStore.norm(d.canonical)] = d
            out[JournalCatalogStore.norm(d.question)] = out[JournalCatalogStore.norm(d.question)] ?? d
            for a in d.aliases { out[JournalCatalogStore.norm(a)] = out[JournalCatalogStore.norm(a)] ?? d }
        }
        return out
    }()

    // MARK: Resolution

    /// A catalog item as the journal shows it. The user's rename wins; a known behaviour takes the
    /// library's name, question, category, section and follow-up; anything else is shown as itself.
    static func behavior(for item: JournalCatalogItem, customTitles: [String: String]) -> PulseBehavior {
        let def = definition(for: item.canonical)
        let followUp: PulseBehaviorFollowUp? = {
            if case .numeric(let unit) = item.kind { return def?.followUp ?? .custom(unit: unit) }
            return def?.followUp
        }()
        let question = item.displayName ?? def?.question ?? item.canonical
        let title = customTitles[item.canonical] ?? def?.title ?? derivedTitle(question)
        let category = def?.category ?? PulseBehaviorCategory(group: item.group)
        return PulseBehavior(canonical: item.canonical, title: title, question: question, category: category,
                             section: def?.section ?? inferredSection(item.canonical),
                             symbol: def?.symbol ?? symbol(for: category), followUp: followUp,
                             libraryID: def?.id, isCustom: item.custom && def == nil,
                             isSelected: !item.hidden)
    }

    /// A library behaviour not in the catalog yet (a NOT SELECTED row).
    static func suggestion(_ def: PulseBehaviorDefinition) -> PulseBehavior {
        PulseBehavior(canonical: def.canonical, title: def.title, question: def.question, category: def.category,
                      section: def.section, symbol: def.symbol, followUp: def.followUp, libraryID: def.id,
                      isCustom: false, isSelected: false)
    }

    /// Every behaviour the editor offers: the catalog's items (hidden ones as NOT SELECTED) plus the library's
    /// behaviours that are not in it yet.
    static func all(items: [JournalCatalogItem], customTitles: [String: String]) -> [PulseBehavior] {
        var out = items.map { behavior(for: $0, customTitles: customTitles) }
        let present = Set(out.compactMap(\.libraryID))
        let keys = Set(items.map { JournalCatalogStore.norm($0.canonical) })
        for def in definitions where !present.contains(def.id) && !keys.contains(JournalCatalogStore.norm(def.canonical)) {
            out.append(suggestion(def))
        }
        return out
    }

    /// A title for a question the library does not know: the question without its "?" ("Took a cold shower").
    static func derivedTitle(_ question: String) -> String {
        var t = question.trimmingCharacters(in: .whitespacesAndNewlines)
        while t.hasSuffix("?") { t.removeLast() }
        return t.isEmpty ? question : t
    }

    /// Where an unknown question sits: sleep words at night, sickness / injury / days off under STATUS.
    static func inferredSection(_ question: String) -> PulseJournalSection {
        let q = question.lowercased()
        if ["sick", "ill", "injur", "wound", "vacation", "holiday"].contains(where: { q.contains($0) }) { return .status }
        if ["bed", "sleep", "night", "nap"].contains(where: { q.contains($0) }) { return .nighttime }
        return .daytime
    }

    /// A category's symbol, for behaviours the library does not know.
    static func symbol(for category: PulseBehaviorCategory) -> String {
        switch category {
        case .drugsMedication: return "pills"
        case .healthSymptoms: return "cross.case"
        case .hormonalHealth: return "calendar.circle"
        case .lifestyle: return "figure.walk"
        case .mentalWellbeing: return "brain.head.profile"
        case .nutrition: return "fork.knife"
        case .recovery: return "leaf"
        case .sleepCircadian: return "moon.zzz"
        case .supplements: return "pills"
        }
    }

    // MARK: Search (§3.17b: exact names, then fuzzy, then synonyms)

    /// `behaviors` matching `query`, best first: names and questions that contain it, then synonyms
    /// ("Coffee" → Caffeine), then near misses ("Hydrtion" → Hydration).
    static func search(_ query: String, in behaviors: [PulseBehavior]) -> [PulseBehavior] {
        let q = fold(query)
        guard !q.isEmpty else { return behaviors }
        var scored: [(score: Int, behavior: PulseBehavior)] = []
        for b in behaviors {
            let title = fold(b.title), question = fold(b.question)
            let synonyms = b.libraryID.flatMap { definition(id: $0)?.synonyms.map(fold) } ?? []
            var score: Int?
            if title == q { score = 0 }
            else if title.hasPrefix(q) || title.split(separator: " ").contains(where: { $0.hasPrefix(q) }) { score = 1 }
            else if title.contains(q) || question.contains(q) { score = 2 }
            else if synonyms.contains(where: { $0 == q || $0.hasPrefix(q) || q.hasPrefix($0) }) { score = 3 }
            else if fuzzy(q, title) || synonyms.contains(where: { fuzzy(q, $0) }) { score = 4 }
            if let score { scored.append((score, b)) }
        }
        return scored.sorted { a, b in
            a.score != b.score ? a.score < b.score
                : a.behavior.title.localizedCaseInsensitiveCompare(b.behavior.title) == .orderedAscending
        }.map(\.behavior)
    }

    /// Lowercased, accent-folded, trimmed.
    static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A typo-tolerant match: the query is within a small edit distance of the text or one of its words.
    static func fuzzy(_ query: String, _ text: String) -> Bool {
        guard query.count >= 3 else { return false }
        let allowed = query.count <= 5 ? 1 : 2
        let words = [text] + text.split(separator: " ").map(String.init)
        return words.contains { word in
            abs(word.count - query.count) <= allowed && editDistance(query, word, limit: allowed) <= allowed
        }
    }

    /// Levenshtein distance, stopping early past `limit`.
    static func editDistance(_ a: String, _ b: String, limit: Int) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var prev = Array(0...b.count)
        for i in 1...a.count {
            var cur = [i] + Array(repeating: 0, count: b.count)
            var rowMin = cur[0]
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
                rowMin = min(rowMin, cur[j])
            }
            if rowMin > limit { return rowMin }
            prev = cur
        }
        return prev[b.count]
    }
}
#endif

#if os(iOS)
extension PulseJournalSection {
    /// The section's name in DEBUG scroll anchors (`--jp-scroll nighttime`).
    var debugName: String {
        switch self {
        case .daytime: return "daytime"
        case .nighttime: return "nighttime"
        case .status: return "status"
        }
    }
}
#endif
