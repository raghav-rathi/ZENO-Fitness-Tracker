#if os(iOS)
import Foundation
import StrandAnalytics

// MARK: - Achievement unlocked / Level up (WHOOP_UI_SPEC §3.14, §3.30)
//
// The milestones Home's coaching stack celebrates. They are resolved from the SAME profile snapshot the
// unlock modal over Home is evaluated with (`PulseHomeView` holds one, passed to both
// `pulseAchievementUnlocks` and the stack), by the modal's own rules, so a card and the modal can never
// name different unlocks or different figures for one:
//   - a badge is a card on the day its acknowledgement value rose (`PulseAchievements.acknowledgementValue`):
//     a cumulative badge's new milestone, an event badge's first occurrence. The ZENO Age badge is left to
//     the modal: its date is the week's measurement, not the day a year was gained, so a card could not
//     say it happened today;
//   - a day-streak milestone is a card on the day it is reached, when the modal announces it: above the
//     last milestone the wearer was shown (`PulseDayStreak.newMilestone`), never on the modal's silent
//     first look, never again for a milestone a broken streak had already reached. Closing the modal
//     records that milestone as shown, so Home keeps its own note of the day the modal announced it
//     (`streakAnnouncement`, stored under `announcedStreakKey`) and the card stays for the rest of that day;
//   - a level is a card on the day the scored Recovery that reached it lands (the modal has no level-up;
//     the Levels page reads the same `level`).
// Only today counts: the stack is the day's, and a ✓ puts a card away for the rest of it.

enum PulseHomeMilestones {
    enum Card: Equatable, Identifiable {
        /// A day-streak milestone reached today.
        case streak(milestone: Int)
        /// A badge whose new milestone, or first occurrence, fell today.
        case badge(PulseAchievements.Badge)
        /// Today's scored Recovery took the wearer to `level.level`.
        case level(PulseLevels.Progress)

        /// Stable for one unlock, so completing it with ✓ does not hide the next one.
        var id: String {
            switch self {
            case .streak(let milestone): return "milestone-streak-\(milestone)"
            case .badge(let badge): return "milestone-badge-\(badge.id)-\(badge.shown)"
            case .level(let progress): return "milestone-level-\(progress.level)"
            }
        }
    }

    /// Where Home keeps the day-streak milestone the modal last announced, with the day it did
    /// (`streakAnnouncement`'s "yyyy-MM-dd:milestone").
    static let announcedStreakKey = "pulse.home.streakAnnounced"

    /// The day-streak milestone the unlock modal announces for `s`, by its own rule
    /// (`PulseDayStreak.newMilestone`: nothing on the first look, nothing at or below the last milestone
    /// shown), as "<today>:<milestone>"; nil when it has nothing to announce. Home stores it while the
    /// announcement is pending, before the modal can be closed.
    static func streakAnnouncement(_ s: ProfileSnapshot?, acknowledgedStreak: Int?) -> String? {
        guard let s, s.storeLoaded,
              let milestone = PulseDayStreak.newMilestone(days: s.streak.current, acknowledged: acknowledgedStreak)
        else { return nil }
        return "\(s.todayKey):\(milestone)"
    }

    /// Today's milestones in the order the modal announces them (the streak, then badges in their order),
    /// the level last. `acknowledgedStreak` is the unlock record's streak milestone
    /// (`ProfileUnlockStore.acknowledgedStreakMilestone`), read by the caller on the main actor;
    /// `announcedStreak` is Home's note of the last announcement (`announcedStreakKey`).
    static func cards(_ s: ProfileSnapshot?, acknowledgedStreak: Int?, announcedStreak: String) -> [Card] {
        // A build from before the store's first load sees no days at all (the modal waits for it too).
        guard let s, s.storeLoaded else { return [] }
        var out: [Card] = []
        // The streak and the level move only with a Recovery scored today.
        let scoredToday = s.streak.week.first(where: \.isToday)?.state == .kept
        if scoredToday, let milestone = PulseDayStreak.lastMilestone(atOrBelow: s.streak.current),
           milestone == s.streak.current {
            // Announced now (the modal is up or about to be), or announced earlier today and since closed.
            let today = "\(s.todayKey):\(milestone)"
            if streakAnnouncement(s, acknowledgedStreak: acknowledgedStreak) == today || announcedStreak == today {
                out.append(.streak(milestone: milestone))
            }
        }
        for badge in s.badges where badge.isUnlocked && badge.unlockedDay == s.todayKey {
            switch badge.kind {
            case .cumulative: out.append(.badge(badge))
            case .event where badge.shown == 1: out.append(.badge(badge))
            case .event, .value: break
            }
        }
        if scoredToday, s.level.level > 1, s.level.recoveries == s.level.levelMinimum {
            out.append(.level(s.level))
        }
        return out
    }

    #if DEBUG
    /// `--pulse-home-milestones [streak|badge|level]`: a card of that kind (each kind without one) from the
    /// snapshot, whatever day it was reached on, so the copy can be captured (simctl cannot score a
    /// Recovery, nor tap ✓ to bring up the next card).
    static func debugCards(_ s: ProfileSnapshot?) -> [Card]? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--pulse-home-milestones"), let s, s.storeLoaded else { return nil }
        let kind = i + 1 < args.count ? args[i + 1] : ""
        var out: [Card] = []
        if kind != "badge" && kind != "level", let milestone = PulseDayStreak.lastMilestone(atOrBelow: s.streak.current) {
            out.append(.streak(milestone: milestone))
        }
        if kind != "streak" && kind != "level", let badge = s.unlockedBadges.first(where: { $0.kind != .value }) {
            out.append(.badge(badge))
        }
        if kind != "streak" && kind != "badge" { out.append(.level(s.level)) }
        return out
    }
    #endif
}
#endif
