#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Profile snapshot (WHOOP_UI_SPEC §3.30)
//
// Profile, Levels, Achievements and Day Streak read ONE snapshot, built off the main actor from the same
// day list, so the level on Profile, the ladder on Levels, the streak on Day Streak and the badge counts
// can never disagree with each other. The day streak is `StreakCalculator`'s current run, the rule the
// Home streak pill reads (`PulseSnapshotBuilder.home`), so the pill and the page agree too.

/// Everything the profile pages show, already resolved.
struct ProfileSnapshot: Equatable {
    let seq: Int
    /// Whether the build read a loaded store. Before the repository's first load the day list is empty,
    /// so an unlock check must not take such a snapshot for the wearer's history.
    let storeLoaded: Bool
    /// Today's day key, the streak's anchor (the Home pill's).
    let todayKey: String
    /// The level ladder over the scored Recoveries.
    let level: PulseLevels.Progress
    let streak: ProfileStreak
    /// Every badge, fixed rules first, then one per sport logged.
    let badges: [PulseAchievements.Badge]
    /// The first day with any data ("Tracking since").
    let firstDayKey: String?
    /// ZENO Age against the calendar age; nil when there is no ZENO Age yet.
    let zenoAge: ProfileZenoAge?
    /// Data Highlights and Activity Summary per window.
    let highlights: [ProfileWindow: ProfileHighlights]
    let activity: [ProfileWindow: ProfileActivitySummary]

    /// The unlocked badges, most recent first (the Profile carousel's order).
    var unlockedBadges: [PulseAchievements.Badge] {
        badges.filter(\.isUnlocked).sorted { ($0.unlockedDay ?? "") > ($1.unlockedDay ?? "") }
    }
}

/// The day streak as the Day Streak page draws it.
struct ProfileStreak: Equatable {
    /// The current run (`StreakCalculator`'s), 0 when there is none.
    let current: Int
    /// The longest run in the whole history.
    let longest: Int
    /// The run's first day key.
    let startKey: String?
    /// Monday to Sunday of this week.
    let week: [PulseDayStreak.WeekDay]
    let milestone: PulseDayStreak.MilestoneProgress

    var tier: PulseDayStreak.Tier { PulseDayStreak.tier(days: current) }
}

/// ZENO Age (VitalityEngine's Body Age, the value the Health tab shows) beside the calendar age.
struct ProfileZenoAge: Equatable {
    let zenoAge: Double
    /// The calendar age from the profile's birthday.
    let calendarAge: Int
    /// The day the ZENO Age was last computed.
    let dayKey: String

    /// Calendar age minus ZENO Age: positive = younger.
    var yearsYounger: Double { Double(calendarAge) - zenoAge }
}

/// The Data Highlights and Activity Summary windows: "1M | 3M | ALL TIME".
enum ProfileWindow: String, CaseIterable, Hashable {
    case month, quarter, all

    var title: String {
        switch self {
        case .month: return "1M"
        case .quarter: return "3M"
        case .all: return String(localized: "All time")
        }
    }

    /// Calendar days covered, ending today; nil for the whole history.
    var days: Int? {
        switch self {
        case .month: return 30
        case .quarter: return 90
        case .all: return nil
        }
    }
}

/// Data Highlights for one window: the three highlight rings, the three streaks and the notable stats.
/// Every value is the wearer's own extreme in the window; a value with no data is nil, never zero.
struct ProfileHighlights: Equatable {
    /// The best Sleep Performance, %.
    let bestSleep: Double?
    /// The highest Recovery, %.
    let peakRecovery: Double?
    /// The highest Day Strain, 0–21.
    let maxStrain: Double?
    /// The longest runs of consecutive days in the window: 70%+ Sleep Performance, green Recovery,
    /// and 10+ Day Strain.
    let sleepStreak: Int
    let greenStreak: Int
    let strainStreak: Int
    let lowestRHR: Int?
    let highestRHR: Int?
    let lowestHRV: Double?
    let highestHRV: Double?
    /// The highest heart rate any logged activity reached.
    let maxHeartRate: Int?
    /// The longest night asleep, minutes.
    let longestSleepMin: Double?
    /// The lowest Recovery, %.
    let lowestRecovery: Double?

    /// True when the window holds nothing to show.
    var isEmpty: Bool {
        bestSleep == nil && peakRecovery == nil && maxStrain == nil && lowestRHR == nil && lowestHRV == nil
            && maxHeartRate == nil && longestSleepMin == nil && lowestRecovery == nil
    }
}

/// The Activity Summary for one window.
struct ProfileActivitySummary: Equatable {
    struct Sport: Equatable, Identifiable {
        /// The lowercased sport token.
        let id: String
        let name: String
        let symbol: String
        let count: Int
        /// The mean Strain of the sessions that carry one, 0–21; nil when none does.
        let averageStrain: Double?
    }

    let total: Int
    /// Most logged first.
    let sports: [Sport]
}

/// What the First Week checklist reads from the store (More › FIRST WEEK WITH ZENO).
struct FirstWeekSnapshot: Equatable {
    let seq: Int
    /// Any activity in the history.
    let hasActivity: Bool
    /// Any native journal entry.
    let hasJournal: Bool
}
#endif
