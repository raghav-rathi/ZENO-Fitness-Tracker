import Foundation

// PulseAchievements.swift - the local achievement rules behind the Pulse Achievements page, its badge
// details, the Profile carousel and the unlock modal (WHOOP_UI_SPEC §3.30).
//
// Every badge is a rule over data ZENO already scored on this device: a day's Sleep Performance,
// Recovery, Day Strain (0–21) and hours asleep, the activities logged, and the ZENO Age gap. Nothing is
// compared with other people (WHOOP's percentile lines are [POP] and omitted), and a badge is never
// unlocked by anything but a qualifying day in the wearer's own history.
//
// Three kinds of badge:
//   - cumulative: a running total ("nights of 85%+ Sleep Performance"). It shows the last MILESTONE
//     reached (1, 5, 10, 25, 50, then every 50 from 100), dated the day that milestone fell, and earns
//     0–6 stars by that milestone (1★ 50, 2★ 100, 3★ 250, 4★ 500, 5★ 750, 6★ 1000; spec §3.30 "Star
//     tiers"). Activity badges, one per sport logged, are cumulative.
//   - event: a count of occurrences ("a Recovery of 99%+"), dated the latest one, never starred.
//   - value: a level reached ("ZENO Age 4 years younger"), its next milestone one step on.
//
// Names and copy live in the app; this file decides only who qualifies, how many, and since when.
// Day keys are civil "yyyy-MM-dd" days; runs of consecutive days use civil epoch days, so a run never
// breaks or joins across a time-zone change.
//
// Display-only by design: nothing here is persisted except the app's own record of which unlocks the
// wearer has seen, which never leaves the device or crosses the .noopbak boundary, so there is no
// Kotlin twin to keep byte-identical (the same rule as `PulseDisplay`). Pure, no clock, no I/O.

public enum PulseAchievements {

    // MARK: - Families and rules

    /// The badge families, in the order the page lists them. Each has its own frame shape.
    public enum Family: String, CaseIterable, Equatable, Sendable {
        case sleep, recovery, strain, healthspan, activities
    }

    public enum Kind: String, Equatable, Sendable {
        case cumulative, event, value
    }

    /// The fixed rules. Activity badges are made per sport and carry no rule.
    public enum Rule: String, CaseIterable, Equatable, Sendable {
        /// Sleep, cumulative: nights of 85%+ Sleep Performance.
        case restfulNights
        /// Sleep, event: nights with eight hours or more asleep.
        case fullEight
        /// Sleep, event: seven nights in a row of 70%+ Sleep Performance (each full week counts once).
        case steadyWeek
        /// Recovery, cumulative: green Recoveries (67%+ as the dial prints it).
        case greenLight
        /// Recovery, event: seven green Recoveries in a row (each full week counts once).
        case greenStreak
        /// Recovery, event: a Recovery of 99% or more.
        case nearPerfect
        /// Recovery, event: a Recovery of 5% or less.
        case runningOnEmpty
        /// Strain, cumulative: days of 14 or more Day Strain.
        case bigDays
        /// Strain, event: a day of 18 or more Day Strain.
        case redline
        /// Strain, cumulative: days whose Strain finished inside that day's optimal range.
        case onTarget
        /// Healthspan, value: ZENO Age at least a whole year younger than the calendar age.
        case youngerSelf

        public var family: Family {
            switch self {
            case .restfulNights, .fullEight, .steadyWeek: return .sleep
            case .greenLight, .greenStreak, .nearPerfect, .runningOnEmpty: return .recovery
            case .bigDays, .redline, .onTarget: return .strain
            case .youngerSelf: return .healthspan
            }
        }

        public var kind: Kind {
            switch self {
            case .restfulNights, .greenLight, .bigDays, .onTarget: return .cumulative
            case .youngerSelf: return .value
            default: return .event
            }
        }
    }

    // MARK: - Inputs

    /// One day as the app resolved it. Missing values are nil and never qualify for anything.
    public struct Day: Equatable, Sendable {
        public let day: String
        /// Sleep Performance for the night that ended on `day`, 0–100.
        public let sleepPerformance: Double?
        /// Minutes asleep that night.
        public let asleepMinutes: Double?
        /// The day's Recovery, 0–100.
        public let recovery: Double?
        /// The day's Strain on the 0–21 scale.
        public let strain: Double?
        /// The day's optimal Strain range (from its Recovery), on the 0–21 scale.
        public let optimalStrain: ClosedRange<Double>?

        public init(day: String, sleepPerformance: Double? = nil, asleepMinutes: Double? = nil,
                    recovery: Double? = nil, strain: Double? = nil, optimalStrain: ClosedRange<Double>? = nil) {
            self.day = day
            self.sleepPerformance = sleepPerformance
            self.asleepMinutes = asleepMinutes
            self.recovery = recovery
            self.strain = strain
            self.optimalStrain = optimalStrain
        }
    }

    /// One logged activity.
    public struct Activity: Equatable, Sendable {
        /// The civil day it started on.
        public let day: String
        /// The stored sport token ("Running", "cycling", …); badges group by it, case-insensitively.
        public let sport: String

        public init(day: String, sport: String) {
            self.day = day
            self.sport = sport
        }
    }

    /// The ZENO Age gap as it stands, for the Healthspan badge.
    public struct AgeGap: Equatable, Sendable {
        /// Calendar age minus ZENO Age, in years (positive = younger).
        public let yearsYounger: Double
        /// The day it was measured.
        public let day: String

        public init(yearsYounger: Double, day: String) {
            self.yearsYounger = yearsYounger
            self.day = day
        }
    }

    // MARK: - Output

    public struct Badge: Equatable, Identifiable, Sendable {
        /// The rule's raw value, or "activity.<sport>" for an activity badge.
        public let id: String
        public let rule: Rule?
        public let family: Family
        public let kind: Kind
        /// An activity badge's sport, as first logged (the display name is the app's).
        public let sport: String?
        /// The qualifying total as it stands.
        public let count: Int
        /// The number the badge shows: the last milestone reached (cumulative), the occurrences (event)
        /// or the whole years (value). 0 = locked.
        public let shown: Int
        /// When `shown` was reached (cumulative, value) or the latest occurrence (event).
        public let unlockedDay: String?
        /// The milestone before `shown` and the next one, for the milestone card (cumulative, value).
        public let nextMilestone: Int?
        /// 0–6, cumulative badges only.
        public let stars: Int

        public var isUnlocked: Bool { shown > 0 }

        /// What still separates the count from the next milestone.
        public var remaining: Int? { nextMilestone.map { max(0, $0 - count) } }

        /// How far the count has come from `shown` toward the next milestone, 0...1.
        public var milestoneFraction: Double? {
            guard let next = nextMilestone, next > shown else { return nil }
            return min(1, max(0, Double(count - shown) / Double(next - shown)))
        }
    }

    // MARK: - Milestones and stars

    /// Cumulative milestones below 100; from 100 on they fall every 50 (spec §3.30: "above 100 the steps
    /// are 50"; WHOOP's grid also shows 1, 5, 10, 25 and 50).
    public static let lowMilestones: [Int] = [1, 5, 10, 25, 50, 100]

    /// The last cumulative milestone at or below `count`, or 0 when none is reached.
    public static func milestone(atOrBelow count: Int) -> Int {
        guard count >= 1 else { return 0 }
        if count < 100 { return lowMilestones.last(where: { $0 <= count }) ?? 0 }
        return 100 + (count - 100) / 50 * 50
    }

    /// The first cumulative milestone strictly above `count`.
    public static func milestone(after count: Int) -> Int {
        if count < 100 { return lowMilestones.first(where: { $0 > count }) ?? 100 }
        return 100 + ((count - 100) / 50 + 1) * 50
    }

    /// Stars for a cumulative badge showing `milestone`.
    public static func stars(forMilestone milestone: Int) -> Int {
        switch milestone {
        case 1000...: return 6
        case 750...: return 5
        case 500...: return 4
        case 250...: return 3
        case 100...: return 2
        case 50...: return 1
        default: return 0
        }
    }

    // MARK: - Evaluation

    /// Every badge, fixed rules first in `Rule` order, then one activity badge per sport (most logged
    /// first). Locked rule badges are included (shown 0); a sport is listed once it has been logged.
    public static func evaluate(days: [Day], activities: [Activity], ageGap: AgeGap? = nil) -> [Badge] {
        // One row per civil day: the last one supplied wins, as the app's day list resolves duplicates.
        var byDay: [String: Day] = [:]
        for d in days where Baselines.isoEpochDay(d.day) != nil { byDay[d.day] = d }
        let ordered = byDay.values.sorted { $0.day < $1.day }

        var badges: [Badge] = []
        for rule in Rule.allCases {
            switch rule {
            case .restfulNights:
                badges.append(cumulative(rule, ordered.filter { ($0.sleepPerformance ?? -1) >= 85 }.map(\.day)))
            case .fullEight:
                badges.append(event(rule, ordered.filter { ($0.asleepMinutes ?? 0) >= 480 }.map(\.day)))
            case .steadyWeek:
                badges.append(event(rule, weekCompletions(ordered.filter { ($0.sleepPerformance ?? -1) >= 70 }
                    .map(\.day))))
            case .greenLight:
                badges.append(cumulative(rule, ordered.filter { isGreen($0.recovery) }.map(\.day)))
            case .greenStreak:
                badges.append(event(rule, weekCompletions(ordered.filter { isGreen($0.recovery) }.map(\.day))))
            case .nearPerfect:
                badges.append(event(rule, ordered.filter { shownPercent($0.recovery).map { $0 >= 99 } ?? false }
                    .map(\.day)))
            case .runningOnEmpty:
                badges.append(event(rule, ordered.filter { shownPercent($0.recovery).map { $0 <= 5 } ?? false }
                    .map(\.day)))
            case .bigDays:
                badges.append(cumulative(rule, ordered.filter { ($0.strain ?? -1) >= 14 }.map(\.day)))
            case .redline:
                badges.append(event(rule, ordered.filter { ($0.strain ?? -1) >= 18 }.map(\.day)))
            case .onTarget:
                badges.append(cumulative(rule, ordered.filter { d in
                    guard let s = d.strain, let range = d.optimalStrain else { return false }
                    return range.contains(s)
                }.map(\.day)))
            case .youngerSelf:
                badges.append(value(rule, ageGap))
            }
        }
        badges.append(contentsOf: activityBadges(activities))
        return badges
    }

    /// The badges whose unlock the wearer has not been shown yet. `acknowledged` maps a badge id to the
    /// value last acknowledged (`acknowledgementValue`); nil means nothing was ever recorded, which is a
    /// baseline (the first look announces nothing). An event badge is announced once, on its first
    /// occurrence; cumulative and value badges on every new milestone.
    public static func newUnlocks(_ badges: [Badge], acknowledged: [String: Int]?) -> [Badge] {
        guard let acknowledged else { return [] }
        return badges.filter { acknowledgementValue($0) > (acknowledged[$0.id] ?? 0) }
    }

    /// The value a badge is acknowledged at: its milestone (cumulative, value) or 1 once it has
    /// occurred at all (event).
    public static func acknowledgementValue(_ badge: Badge) -> Int {
        badge.kind == .event ? min(badge.shown, 1) : badge.shown
    }

    /// The acknowledgement record for `badges` as they stand (the first look's silent baseline).
    public static func acknowledging(_ badges: [Badge]) -> [String: Int] {
        Dictionary(badges.map { ($0.id, acknowledgementValue($0)) }, uniquingKeysWith: { a, _ in a })
    }

    /// `record` with ONE badge acknowledged as it stands: the unlock the wearer was actually shown, so
    /// every other pending unlock stays pending and is announced in its turn. Never lowers a value
    /// already recorded.
    public static func acknowledging(_ badge: Badge, into record: [String: Int]) -> [String: Int] {
        var out = record
        out[badge.id] = max(record[badge.id] ?? 0, acknowledgementValue(badge))
        return out
    }

    // MARK: - Rule helpers

    /// Green as the dial prints it: 67% and up, judged on the whole percent (`PulseDisplay`).
    static func isGreen(_ recovery: Double?) -> Bool {
        guard let recovery, recovery.isFinite else { return false }
        return PulseDisplay.recoveryBand(percent: recovery) == .green
    }

    /// The whole percent a Recovery dial prints, or nil.
    static func shownPercent(_ recovery: Double?) -> Int? {
        guard let recovery, recovery.isFinite else { return nil }
        return PulseDisplay.displayedPercent(recovery)
    }

    /// The days on which a run of seven consecutive qualifying days completed. A run of length L counts
    /// floor(L / 7) weeks, each completing on its seventh day; a missing day breaks the run.
    static func weekCompletions(_ dayKeys: [String]) -> [String] {
        let epochs = Set(dayKeys.compactMap(Baselines.isoEpochDay)).sorted()
        var out: [String] = []
        var runLength = 0
        var previous: Int?
        for e in epochs {
            runLength = (previous.map { e == $0 + 1 } ?? false) ? runLength + 1 : 1
            if runLength % 7 == 0 { out.append(ActivityHeatmap.civilDay(e)) }
            previous = e
        }
        return out
    }

    private static func cumulative(_ rule: Rule, _ qualifying: [String]) -> Badge {
        let count = qualifying.count
        let shown = milestone(atOrBelow: count)
        return Badge(id: rule.rawValue, rule: rule, family: rule.family, kind: .cumulative, sport: nil,
                     count: count, shown: shown,
                     unlockedDay: shown > 0 ? qualifying[shown - 1] : nil,
                     nextMilestone: milestone(after: count), stars: stars(forMilestone: shown))
    }

    private static func event(_ rule: Rule, _ occurrences: [String]) -> Badge {
        Badge(id: rule.rawValue, rule: rule, family: rule.family, kind: .event, sport: nil,
              count: occurrences.count, shown: occurrences.count, unlockedDay: occurrences.last,
              nextMilestone: nil, stars: 0)
    }

    private static func value(_ rule: Rule, _ gap: AgeGap?) -> Badge {
        let years: Int
        if let gap, gap.yearsYounger.isFinite, gap.yearsYounger >= 1 {
            years = Int(gap.yearsYounger.rounded(.down))
        } else {
            years = 0
        }
        return Badge(id: rule.rawValue, rule: rule, family: rule.family, kind: .value, sport: nil,
                     count: years, shown: years, unlockedDay: years > 0 ? gap?.day : nil,
                     nextMilestone: years + 1, stars: 0)
    }

    private static func activityBadges(_ activities: [Activity]) -> [Badge] {
        // Group by the sport token, case-insensitively; an unnamed or auto-detected bout is no sport.
        var groups: [String: (sport: String, days: [String])] = [:]
        for a in activities.sorted(by: { $0.day < $1.day }) {
            let token = a.sport.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = token.lowercased()
            guard !key.isEmpty, key != "detected", Baselines.isoEpochDay(a.day) != nil else { continue }
            groups[key, default: (token, [])].days.append(a.day)
        }
        return groups.map { key, group -> Badge in
            let count = group.days.count
            let shown = milestone(atOrBelow: count)
            return Badge(id: "activity.\(key)", rule: nil, family: .activities, kind: .cumulative,
                         sport: group.sport, count: count, shown: shown,
                         unlockedDay: shown > 0 ? group.days[shown - 1] : nil,
                         nextMilestone: milestone(after: count), stars: stars(forMilestone: shown))
        }
        .sorted { $0.count != $1.count ? $0.count > $1.count : $0.id < $1.id }
    }
}
