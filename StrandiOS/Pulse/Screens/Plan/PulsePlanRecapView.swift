#if os(iOS)
import SwiftUI
import UserNotifications

/// MY WEEK RECAP (WHOOP_UI_SPEC §3.19, appstore/loc-*-10-weekly-plan; English copy unconfirmed [U]): the week
/// just finished, from Monday. A centred caps title, ZENO's own target art, a headline and a line chosen by
/// how the week went, "44% COMPLETE" over a teal bar, and a notched card of the goals (finished in teal
/// above a divider, the rest in white, each with its ring), then CONTINUE PLAN and SWITCH PLAN.
struct PulsePlanRecapView: View {
    let plan: PulsePlan
    let week: PlanWeekSnapshot
    let onContinue: () -> Void
    let onSwitch: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Text(String(localized: "My week recap"))
                        .pulseText(.navTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        PulseCloseButton(action: onContinue)
                        Spacer()
                    }
                }
                .padding(.top, 12)
                art
                    .padding(.top, 28)
                VStack(alignment: .leading, spacing: 8) {
                    Text(headline)
                        .pulseText(.weeklyTrendsTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(bodyText)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(PulseFormat.dayLabel(week.weekStart, template: "MMMd") + " – "
                         + PulseFormat.dayLabel(week.days.last ?? week.weekStart, template: "MMMd"))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 28)
                PlanAccomplishedBar(percent: week.percent, word: String(localized: "Complete"))
                    .padding(.top, 24)
                goalsCard
                    .padding(.top, 6)
                VStack(spacing: 10) {
                    Button(String(localized: "Continue plan"), action: onContinue)
                        .buttonStyle(.pulseFilledWhite)
                    Button(String(localized: "Switch plan"), action: onSwitch)
                        .buttonStyle(.pulseOutlineWhite)
                }
                .padding(.top, 28)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.bottom, 32)
        }
        .background(PulseBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .presentationDragIndicator(.visible)
    }

    /// ZENO's art: a target of three rings with a dart's check, in SF Symbols.
    private var art: some View {
        ZStack {
            Circle().fill(PulseTheme.card).frame(width: 150, height: 150)
            Circle().strokeBorder(PulseTheme.dash, lineWidth: 2).frame(width: 118, height: 118)
            Circle().strokeBorder(PulseTheme.Plan.progress.opacity(0.6), lineWidth: 2).frame(width: 84, height: 84)
            Image(systemName: "scope")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(PulseTheme.Plan.progress)
        }
        .accessibilityHidden(true)
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(week.finished) { goal in PlanGoalRow(progress: goal, ringDiameter: 36) }
            if !week.finished.isEmpty && !week.unfinished.isEmpty {
                PulseDivider().padding(.vertical, 6)
            }
            ForEach(week.unfinished) { goal in PlanGoalRow(progress: goal, ringDiameter: 36) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 10)
        .background(PulseNotchedRectangle(notchPosition: CGFloat(min(100, max(0, week.percent ?? 0))) / 100)
            .fill(PulseTheme.JournalPlan.recapCard))
    }

    private var headline: String {
        switch week.percent ?? 0 {
        case 80...: return String(localized: "Keep doing what's good for you")
        case 40..<80: return String(localized: "Good progress last week")
        default: return String(localized: "A fresh week starts now")
        }
    }

    private var bodyText: String {
        let done = week.finished.count, all = week.goals.count
        switch week.percent ?? 0 {
        case 80...:
            return String(localized: "You finished \(done) of your \(all) goals last week. The effort adds up; keep it going.")
        case 40..<80:
            return String(localized: "You finished \(done) of your \(all) goals last week. Pick up the rest this week, one at a time.")
        default:
            return String(localized: "You finished \(done) of your \(all) goals last week. Small steps count: start with the one that's easiest to fit in.")
        }
    }
}

// MARK: - Friday check-in reminder

/// The Friday check-in as a local notification (§3.19 "Friday check-in (notification)"): Friday 17:00 every
/// week while a plan runs, only when notifications are already allowed (it never asks), removed when the
/// plan ends. Its text is generic: nothing is measured when it is scheduled.
enum PulsePlanReminders {
    static let identifier = "zeno.plan.fridayCheckIn"
    static let category = "zeno.plan.checkIn"

    static func sync(active: Bool) {
        let center = UNUserNotificationCenter.current()
        guard active else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Friday check-in")
            content.body = String(localized: "See what's left to finish this week's plan.")
            content.categoryIdentifier = category
            var when = DateComponents()
            when.weekday = 6
            when.hour = 17
            when.minute = 0
            let request = UNNotificationRequest(identifier: identifier, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true))
            center.add(request)
        }
    }
}
#endif
