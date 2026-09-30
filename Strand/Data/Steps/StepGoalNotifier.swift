import Foundation
import UserNotifications
import StrandAnalytics

// MARK: - Step-goal notification
//
// One opt-in, default-OFF nudge: the first time a day's resolved step count reaches the goal, post "Step
// goal reached", at most once per day. The decision is the pure `StepGoal.shouldNotify` (unit-tested in
// StrandAnalytics); this file is only the runtime around it, in the `StrainTargetNotifier` shape: ask for
// permission when the switch is turned on, only check status afterwards, and advance the persisted day
// marker only after an authorised post, so a day that crossed while notifications were denied still gets
// its one notification once they are allowed again.
//
// It fires when the app sees the crossing: live while it is on screen, or at the next foreground or
// background refresh that reads the day. iOS does not let an app count steps while it is suspended, so a
// goal reached with the app closed is announced the next time it runs, not at the moment it happened.
enum StepGoalNotifier {
    private static let requestId = "steps-goal-reached"

    /// Ask up front (called when the switch is turned on) so the system dialog appears at a predictable
    /// moment rather than at the first crossing.
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Run the policy for the in-progress day and post at most one notification for it. Safe to call on
    /// every refresh; every path that fails the policy is a no-op.
    static func evaluate(day: String, steps: Int?, goal: Int) {
        let defaults = UserDefaults.standard
        guard StepGoal.shouldNotify(enabled: defaults.bool(forKey: StepsPrefs.goalNotificationKey),
                                    steps: steps, goal: goal,
                                    lastNotifiedDay: defaults.string(forKey: StepsPrefs.goalNotifiedDayKey),
                                    today: day),
              let steps else { return }
        let target = StepGoal.clamp(goal)
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Step goal reached")
            content.body = String(localized: "\(StepsFormat.count(steps)) steps today, past your goal of \(StepsFormat.count(target)).")
            content.sound = .default
            center.add(UNNotificationRequest(identifier: requestId, content: content, trigger: nil))
            UserDefaults.standard.set(day, forKey: StepsPrefs.goalNotifiedDayKey)
        }
    }
}

/// Number formatting shared by every steps surface, so "12,408" reads the same on the card, the screen,
/// the tile and the notification.
enum StepsFormat {
    /// Grouped whole number in the app's language ("12,408").
    static func count(_ steps: Int) -> String {
        steps.formatted(.number.locale(AppLanguage.activeLocale).grouping(.automatic))
    }

    /// Compact form for tight axes ("12k", "8.5k", "900").
    static func compact(_ steps: Int) -> String {
        guard steps >= 1_000 else { return String(steps) }
        let thousands = Double(steps) / 1_000
        let rounded = (thousands * 10).rounded() / 10
        let text = rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
        return text + "k"
    }
}
