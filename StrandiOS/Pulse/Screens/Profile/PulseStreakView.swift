#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Day Streak (WHOOP_UI_SPEC §3.30, reviews/r48, profile-community-2026/15, 37, 38, 60–64), pushed from
/// the Home flame and Profile's DAY STREAK row, on WHOOP's flat #101518: the flame in its tier's colour
/// and the count, "Day Streak / Wear your strap daily", when the streak started and the longest one,
/// THIS WEEK, the milestone card and the tier's message.
///
/// The count is `StreakCalculator`'s current run, the rule the Home pill reads, so the two always agree.
/// WHOOP's "Top 2%" column is [POP]: ZENO shows the start and the longest streak only (as WHOOP's own
/// two-column variant does, /60).
struct PulseStreakView: View {
    static let isRebuilt = true

    @State private var snapshot: ProfileSnapshot?
    @State private var showInfo = false

    var body: some View {
        ProfileFlatPage(title: String(localized: "Day streak"), trailing: .info { showInfo = true },
                        background: ProfileArtPalette.streakPage, ready: snapshot != nil) {
            if let streak = snapshot?.streak {
                content(streak)
            } else {
                PulseSkeleton.cards([260, 110, 120])
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.top, 40)
            }
        }
        .profileSnapshot($snapshot)
        .pulseAchievementUnlocks(snapshot)
        .sheet(isPresented: $showInfo) { StreakInfoSheet() }
    }

    private func content(_ s: ProfileStreak) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                ProfileFlameArt(days: max(1, s.current), size: 210)
                    .opacity(s.current == 0 ? 0.35 : 1)
                    .padding(.bottom, 52)
                Text(PulseFormat.grouped(Double(s.current)))
                    .pulseText(.streakCount)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .shadow(color: Color.black.opacity(0.75), radius: 14, y: 4)
                    .accessibilityLabel(ProfileFormat.days(s.current))
            }
            .padding(.top, 14)
            Text(String(localized: "Day Streak"))
                .profileFont(22, weight: .semibold, relativeTo: .title2)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 18)
                .accessibilityAddTraits(.isHeader)
            Text(s.current == 0 ? String(localized: "A night with a scored Recovery starts a new one.")
                                : String(localized: "Wear your strap daily"))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
            stats(s)
                .padding(.top, 34)
            weekCard(s)
                .padding(.top, 30)
                .id("pulse.week")
            milestoneCard(s)
                .padding(.top, 16)
            messageCard(s.tier)
                .padding(.top, 16)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
    }

    // MARK: Stats

    private func stats(_ s: ProfileStreak) -> some View {
        HStack(spacing: 0) {
            stat(value: s.startKey.map(ProfileFormat.day) ?? "--", caption: String(localized: "Streak started"))
            Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 44)
            stat(value: PulseFormat.grouped(Double(s.longest)), caption: String(localized: "Longest streak"))
        }
    }

    private func stat(value: String, caption: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .profileFont(18, weight: .bold, relativeTo: .headline)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: This week

    private func weekCard(_ s: ProfileStreak) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(String(localized: "This week"))
                .modifier(MoreLabelText(tracking: 1.4))
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                ForEach(s.week, id: \.day) { day in
                    VStack(spacing: 14) {
                        // "MON" whole on one line: shrinks rather than breaking into "MO / N" (DR §2).
                        Text(weekdayLabel(day.weekday))
                            .pulseText(.label)
                            .foregroundStyle(day.isToday ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        StreakDayMark(state: day.state, days: s.current)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(weekdayLabel(day.weekday))
                    .accessibilityValue(spoken(day.state))
                }
            }
            // Seven columns of 44 pt cannot hold accessibility-size caps; the row stops at xxxLarge.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: MoreLayout.profileCardRadius, style: .circular).fill(ProfileArtPalette.milestoneCard))
    }

    private func weekdayLabel(_ weekday: Int) -> String {
        let labels = [String(localized: "Mon"), String(localized: "Tue"), String(localized: "Wed"), String(localized: "Thu"),
                      String(localized: "Fri"), String(localized: "Sat"), String(localized: "Sun")]
        return labels[max(0, min(6, weekday - 1))]
    }

    private func spoken(_ state: PulseDayStreak.DayState) -> String {
        switch state {
        case .kept: return String(localized: "Kept")
        case .missed: return String(localized: "Missed")
        case .pending: return String(localized: "Not scored yet")
        case .upcoming: return String(localized: "Upcoming")
        case .beforeStart: return String(localized: "Before your first day")
        }
    }

    // MARK: Milestone

    /// "N more days to unlock your next milestone." between the last milestone's flame and the next one's,
    /// greyed, with an orange bar from one to the other.
    private func milestoneCard(_ s: ProfileStreak) -> some View {
        let m = s.milestone
        return HStack(spacing: 14) {
            milestoneBadge(value: m.last ?? 0, days: s.current, reached: m.last != nil)
            VStack(spacing: 10) {
                Text(m.remaining == 1 ? String(localized: "1 more day") : String(localized: "\(m.remaining) more days"))
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ProfileArtPalette.milestoneTrack)
                        Capsule().fill(ProfileArtPalette.streakBar)
                            .frame(width: max(4, geo.size.width * CGFloat(m.fraction)))
                    }
                }
                .frame(height: 6)
                Text(String(localized: "to unlock your next milestone."))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            milestoneBadge(value: m.next, days: m.next, reached: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .background(RoundedRectangle(cornerRadius: MoreLayout.profileCardRadius, style: .circular).fill(ProfileArtPalette.milestoneCard))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Next milestone \(m.next) days"))
        .accessibilityValue(String(localized: "\(m.remaining) more days"))
    }

    private func milestoneBadge(value: Int, days: Int, reached: Bool) -> some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Circle().fill(Color.black.opacity(0.5))
                Circle().strokeBorder(reached ? ProfileArtPalette.streakBar : PulseTheme.divider, lineWidth: 2)
                ProfileFlameArt(days: max(1, days), size: 40, glows: false)
                    .saturation(reached ? 1 : 0)
                    .opacity(reached ? 1 : 0.35)
            }
            .frame(width: 66, height: 66)
            .padding(.bottom, 18)
            Text(PulseFormat.grouped(Double(value)))
                .font(PulseType.numeral(30, weight: .heavy))
                .foregroundStyle(PulseTheme.textPrimary)
                .shadow(color: Color.black.opacity(0.6), radius: 4, y: 1)
        }
        .frame(width: 74)
    }

    // MARK: Message

    private func messageCard(_ tier: PulseDayStreak.Tier) -> some View {
        let message = Self.message(tier)
        return VStack(alignment: .leading, spacing: 6) {
            Text(message.title)
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(message.body)
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: MoreLayout.profileCardRadius, style: .circular).fill(ProfileArtPalette.milestoneCard))
        .accessibilityElement(children: .combine)
    }

    /// ZENO's own words for each flame tier (spec §3.30 [Z]).
    static func message(_ tier: PulseDayStreak.Tier) -> (title: String, body: String) {
        switch tier {
        case .spark:
            return (String(localized: "The spark is lit"),
                    String(localized: "Every night with a scored Recovery adds a day. Wear your strap day and night and the picture of your body sharpens."))
        case .flame:
            return (String(localized: "It's a habit now"),
                    String(localized: "A hundred days and counting. Steady wear is what makes your baselines, and every score built on them, trustworthy."))
        case .blaze:
            return (String(localized: "Every day counts"),
                    String(localized: "Half a year without a gap. Your trends now cover whole seasons of training, sleep and recovery."))
        case .inferno:
            return (String(localized: "A full year and more"),
                    String(localized: "You have worn your strap through every season. Year-on-year comparisons are yours to read."))
        case .legend:
            return (String(localized: "Legendary consistency"),
                    String(localized: "A thousand days of unbroken data. Few streaks get here: your baselines are as personal as they come."))
        case .legacy:
            return (String(localized: "Legacy-level dedication"),
                    String(localized: "Two thousand days and beyond. This is the long view of your health, written one night at a time."))
        }
    }
}

/// A THIS WEEK mark: a small flame for a kept day, ✕ in a ring for a missed one, a dashed ring for today
/// before it is scored, for the days still to come and for the days before the wearer's first one.
private struct StreakDayMark: View {
    let state: PulseDayStreak.DayState
    let days: Int

    var body: some View {
        Group {
            switch state {
            case .kept:
                ProfileFlameArt(days: max(1, days), size: 30, glows: false)
            case .missed:
                ZStack {
                    Circle().strokeBorder(PulseTheme.textDisabled, lineWidth: 1.5)
                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            case .pending, .upcoming, .beforeStart:
                Circle().strokeBorder(PulseTheme.textDisabled, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

/// ⓘ: what counts towards the streak.
private struct StreakInfoSheet: View {
    var body: some View {
        NavigationStack {
            PulseScreenScaffold(title: String(localized: "Day streak")) {
                Text(String(localized: "A day counts when it has a scored Recovery, which comes from the night before it with your strap on. Until this morning's Recovery is scored, yesterday keeps the streak alive."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(localized: "Miss a whole day and the streak starts again; your longest streak is kept."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .environment(\.pulseModalRoot, true)
        }
        .presentationDetents([.medium])
    }
}
#endif
