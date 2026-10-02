#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Pulse Home (WHOOP_UI_SPEC §3.1), in the observed 2026 order: the header, ZENO's wordmark, the three
/// dials, the HEALTH MONITOR | STRESS MONITOR tiles, My Day (the coach pill or Ask row, Today's Activities,
/// Tonight's Sleep, My Journal), My Plan, My Dashboard (metric rows, the STRESS MONITOR and STRAIN & RECOVERY
/// charts) and the wordmark footer.
///
/// Owned by group "home", which builds on it (the coaching stack, the Menstrual card, the new-member
/// variant, Customize Dashboard). Everything below the header renders `model.home`, a snapshot built off the
/// main actor. Swiping sideways changes the day; the header's pager and calendar do the same. Once the dials
/// scroll off, the mini-ring row pins under the status bar.
struct PulseHomeView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var dialsScrolledOff = false

    /// The sticky row's 44 pt hit area, centred 19.5 pt under the safe-area top.
    private static let stickyRowTop = PulseTheme.Header.stickyRowCentre - PulseTheme.Layout.minTapTarget / 2

    var body: some View {
        PulseScreenScaffold(role: .tabRoot, showsNavigationBar: false, spacing: 0, topPadding: 0,
                            refresh: { await model.pullToRefresh() }, ready: model.home != nil,
                            topBackdrop: dialsScrolledOff
                                ? .extended(extra: Self.stickyRowTop + PulseTheme.Layout.minTapTarget + 12,
                                            fade: PulseTheme.Header.stickyFade)
                                : .automatic) {
            PulseHomeHeader()
            PulseZenoWordmark()
                .frame(maxWidth: .infinity)
                .padding(.top, PulseTheme.Header.wordmarkTop)
            PulseDialsRow(home: model.home)
                .padding(.top, PulseTheme.Header.dialsTop)
                .pulseScrolledPast($dialsScrolledOff, threshold: 8)
            PulseHomeContent()
        }
        .overlay(alignment: .top) {
            if dialsScrolledOff, let home = model.home {
                PulseMiniRingRow(items: home.dials.map { dial in
                    PulseMiniRingRow.Item(id: dial.score.rawValue,
                                          content: dial.dialContent(target: home.target),
                                          action: { navigator.open(.dive(dial.score)) })
                })
                .padding(.top, Self.stickyRowTop)
                .transition(.opacity)
            }
        }
        .animation(PulseMotion.chrome, value: dialsScrolledOff)
        .simultaneousGesture(daySwipe)
        .sensoryFeedback(.selection, trigger: model.dayOffset)
    }

    /// A decisive horizontal flick changes the day: right is older, left is newer
    /// (`TodayView.daySwipeDelta`, the direction both platforms pin).
    private var daySwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width, dy = value.translation.height
                guard abs(dx) > abs(dy) * 1.5, abs(dx) > 50 else { return }
                model.stepDay(TodayView.daySwipeDelta(dx: dx))
            }
    }
}

// MARK: - Header

/// The header row (§1.4): a 32 pt row starting at the safe-area top. At the left the avatar with the day
/// streak pill tucked under it (today only); the date pager in the centre; the strap's battery and status
/// at the right, its glyph 23 pt from the screen edge. Hit areas stay 44 pt; they overflow the row.
struct PulseHomeHeader: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var showCalendar = false

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    if let streak = model.home?.streak, model.home?.day.isToday == true, streak > 0 {
                        Button { navigator.open(.dayStreak) } label: {
                            PulseStreakPill(days: streak)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .padding(.leading, PulseTheme.Header.avatar / 2)
                        .transition(.opacity)
                    }
                    PulseAvatarButton { navigator.present(PulseRoute.profile.forExistingEntryPoint) }
                }
                Spacer(minLength: 0)
                PulseStrapChip()
                    .padding(.trailing, PulseTheme.Header.strapTrailing - PulseTheme.Layout.pageMargin)
            }
            PulseDayPager(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                          canGoBack: model.dayOffset < model.maxDayOffset,
                          canGoForward: model.dayOffset > 0,
                          onBack: { model.stepDay(1) },
                          onForward: { model.stepDay(-1) },
                          onTitleTap: { showCalendar = true })
        }
        .frame(height: PulseTheme.Header.homeRow)
        .animation(PulseMotion.chrome, value: model.home?.day.isToday)
        .sheet(isPresented: $showCalendar) {
            PulseCalendarSheet()
        }
    }
}

/// The wearer's avatar (31 pt; the photo, else a person outline on white 10%), ringed in the page colour
/// so it reads apart from the streak pill under it. Opens Profile (Settings until Profile is rebuilt).
struct PulseAvatarButton: View {
    let action: () -> Void
    @EnvironmentObject private var profile: ProfileStore

    var body: some View {
        Button(action: action) {
            PulseAvatar(imageData: profile.avatarImageData, name: nil, size: PulseTheme.Header.avatar)
                .background(Circle().fill(PulseTheme.pageTop).padding(-1.5))
                .padding((PulseTheme.Layout.minTapTarget - PulseTheme.Header.avatar) / 2)
                .contentShape(Rectangle())
                .padding(-(PulseTheme.Layout.minTapTarget - PulseTheme.Header.avatar) / 2)
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Profile"))
    }
}

// MARK: - Dials

/// Sleep · Recovery · Strain (§2.5), each opening its deep dive, in three equal columns between the page
/// margins with one label size (`PulseDialColumns`). The same row shows the loading state, so the arcs
/// sweep once when the first snapshot lands and never again on the way back from a dive.
struct PulseDialsRow: View {
    let home: HomeSnapshot?

    private var contents: [(score: PulseScore, content: PulseDialContent)] {
        guard let home else {
            return PulseScore.allCases.map { score in
                let empty = score == .strain
                    ? PulseDialContent.strain(label: score.displayName, value: nil, optimalRange: nil, target: nil)
                    : PulseDialContent.percent(label: score.displayName, percent: nil, color: score.tint)
                return (score, empty)
            }
        }
        return home.dials.map { ($0.score, $0.dialContent(target: home.target)) }
    }

    var body: some View {
        let dials = contents
        PulseDialColumns(contents: dials.map(\.content), routes: dials.map { PulseRoute.dive($0.score) })
    }
}

// MARK: - Content

/// Everything below the dials, rendered from `model.home`: white-10% skeleton blocks while the first
/// snapshot builds (after 200 ms, for at least 400 ms), never a spinner.
struct PulseHomeContent: View {
    @Environment(PulseModel.self) private var model

    var body: some View {
        PulseLoadingGate(isLoading: model.home == nil) {
            if let home = model.home {
                PulseHomeSections(home: home)
                    // While a newly selected day builds, the previous day's numbers dim rather than pass for it.
                    .opacity(model.homeIsStale ? 0.45 : 1)
                    .animation(.easeOut(duration: 0.15), value: model.homeIsStale)
            }
        } skeleton: {
            PulseSkeleton.cards([88, 48, 180, 150])
                .padding(.top, 30)
        }
    }
}

/// The sections in WHOOP's 2026 order. A past day keeps My Day's activities and journal, My Plan and My
/// Dashboard, and drops the tiles, the coach pill and Tonight's Sleep (§2.9).
struct PulseHomeSections: View {
    let home: HomeSnapshot

    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.pulseCoach) private var coach

    /// After 18:00 local, or after the day's last activity if later: Day in Review, and Tonight's Sleep
    /// comes before Today's Activities (§3.1 item 8, order rule).
    private var isEvening: Bool {
        let now = Date()
        let lastEnd = home.workouts.map { $0.start.addingTimeInterval(TimeInterval($0.durationMin * 60)) }.max()
        let sixPM = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        return now >= max(sixPM, lastEnd ?? sixPM)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if home.day.isToday {
                PulseMonitorTiles(home: home)
                    .padding(.top, 26)
                    .id("pulse.monitors")
            }

            PulseSectionHeader(String(localized: "My Day"), accessory: .actionMenu)
                .padding(.top, PulseTheme.Layout.sectionGap)
                .id("pulse.myday")
            VStack(spacing: PulseTheme.Layout.stackGap) {
                if home.day.isToday {
                    coachEntry
                }
                if home.day.isToday && isEvening, let tonight = home.tonight {
                    PulseTonightsSleepCard(tonight: tonight)
                    PulseTodaysActivitiesCard(home: home)
                } else {
                    PulseTodaysActivitiesCard(home: home)
                    if home.day.isToday, let tonight = home.tonight {
                        PulseTonightsSleepCard(tonight: tonight)
                    }
                }
                if let journal = home.journal {
                    PulseJournalCard(strip: journal)
                        .id("pulse.journal")
                }
            }
            .padding(.top, PulseTheme.Layout.headerGap)

            PulseSectionHeader(String(localized: "My Plan"))
                .padding(.top, PulseTheme.Layout.sectionGap)
                .id("pulse.plan")
            PulsePlanCard()
                .padding(.top, PulseTheme.Layout.headerGap)

            PulseDashboardViews.Section(home: home)
                .padding(.top, PulseTheme.Layout.sectionGap)

            // The footer: a small ZENO mark at white 50%, 40 pt above the bottom inset.
            PulseZenoWordmark(color: PulseTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, PulseTheme.Space.xxl)
                .accessibilityHidden(true)
        }
    }

    /// The coach pill, or the Ask row while no outlook can be made (no provider and under 3 scored days);
    /// nothing while Coach is switched off.
    @ViewBuilder
    private var coachEntry: some View {
        if coach.availability != .off {
            if coach.availability == .ready || home.scoredDays >= 3 {
                let evening = isEvening
                PulseCoachPill(kind: evening ? .evening : .morning,
                               title: evening ? String(localized: "Your Day In Review")
                                              : String(localized: "Your Daily Outlook")) {
                    coach.open(PulseHomeOutlook.seed(home, evening: evening))
                }
            } else {
                PulseAskRow { coach.open(nil) }
            }
        }
    }
}

/// The local Daily Outlook / Day in Review the coach pill seeds the Coach with when it opens (§3.15 [Z]):
/// a plain summary of the day's numbers, which the Coach expands.
enum PulseHomeOutlook {
    static func seed(_ home: HomeSnapshot, evening: Bool) -> String {
        var lines = [evening ? String(localized: "Day in Review") : String(localized: "Daily Outlook")]
        if let r = home.recovery.value {
            lines.append(String(localized: "Recovery \(PulseDisplay.displayedPercent(r))%"))
        }
        if let s = home.sleep.value {
            lines.append(String(localized: "Sleep performance \(PulseDisplay.displayedPercent(s))%"))
        }
        if let strain = home.strain.value {
            var line = String(localized: "Strain \(PulseFormat.oneDecimal(strain))")
            if let target = home.target, !target.fromCarriedRecovery {
                line += ", " + String(localized: "optimal \(target.rangeText)")
            }
            lines.append(line)
        }
        if let tonight = home.tonight {
            lines.append(String(localized: "Bedtime \(PulseFormat.clock(tonight.bedtime)) for \(PulseFormat.duration(minutes: tonight.needMin)) of sleep"))
        }
        return lines.joined(separator: ". ")
    }
}

// MARK: - Monitor tiles

/// HEALTH MONITOR › | STRESS MONITOR ›, side by side 12 pt apart (§3.1 item 6). Always shown on today
/// (ZENO has no tiers), "Pending" while there is nothing to judge.
struct PulseMonitorTiles: View {
    let home: HomeSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: PulseTheme.Layout.gridGap) {
            PulseLink(PulseRoute.healthMonitor.forExistingEntryPoint) {
                PulseMonitorTile(title: String(localized: "Health Monitor"), status: healthStatus)
            }
            .buttonStyle(PulsePressStyle())
            PulseLink(PulseRoute.stressMonitor.forExistingEntryPoint) {
                PulseMonitorTile(title: String(localized: "Stress Monitor"), status: stressStatus)
            }
            .buttonStyle(PulsePressStyle())
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var healthStatus: PulseMonitorTile.Status {
        guard let monitor = home.monitor, !monitor.isPending else { return .pending }
        if monitor.outOfRange.isEmpty {
            return .init(badge: .check, tint: .teal, word: String(localized: "Within range"),
                         wordColor: PulseTheme.positive,
                         detail: String(localized: "\(monitor.inRange)/\(monitor.judged) Metrics"))
        }
        let detail = monitor.outOfRange.count == 1
            ? monitor.outOfRange[0]
            : String(localized: "\(monitor.outOfRange.count)/\(monitor.judged) Metrics")
        return .init(badge: .alert, tint: .orange, word: String(localized: "Out of range"),
                     wordColor: PulseTheme.negative, detail: detail)
    }

    private var stressStatus: PulseMonitorTile.Status {
        guard let stress = home.stress, let score = stress.score else { return .pending }
        let level = PulseTheme.Stress.Level(value: score)
        let word: String
        switch level {
        case .low: word = String(localized: "Low")
        case .medium: word = String(localized: "Medium")
        case .high: word = String(localized: "High")
        }
        let updated = stress.hours.last(where: { $0.level != nil }).map { hour -> String in
            let end = Date(timeIntervalSince1970: TimeInterval(hour.startTs + 3600))
            return PulseFormat.clock(min(end, Date()))
        }
        return .init(badge: .value(PulseFormat.oneDecimal(score)), tint: level.tint, word: word,
                     wordColor: level.color, detail: updated)
    }
}

// MARK: - Today's Activities

/// TODAY'S ACTIVITIES (ACTIVITIES on a past day): last night, naps and workouts as activity rows, oldest
/// first, then "+ ADD ACTIVITY" and "START ACTIVITY" (§3.1 item 8b). The title sits at the card's 16 pt
/// padding; the rows and buttons are inset 12 pt (completeness-critic/25), 20 pt above the buttons.
struct PulseTodaysActivitiesCard: View {
    let home: HomeSnapshot

    @Environment(\.pulseNavigator) private var navigator

    private struct Item: Identifiable {
        let id: String
        let start: Date
        let row: PulseActivityRow
        let route: PulseRoute
    }

    private var items: [Item] {
        var out: [Item] = []
        if let night = home.lastNight {
            out.append(Item(id: "night", start: night.onset,
                            row: PulseActivityRow(
                                chip: PulseActivityChip(kind: night.performance == nil ? .unscoredSleep : .sleep,
                                                        symbol: "moon.fill",
                                                        value: PulseFormat.hoursMinutes(night.asleepMin)),
                                name: String(localized: "Sleep"),
                                start: PulseFormat.activityTime(night.onset, relativeTo: night.wake),
                                end: PulseFormat.clock(night.wake),
                                barColor: PulseTheme.sleep),
                            route: .sleepDive))
        }
        for nap in home.naps {
            out.append(Item(id: "nap-\(nap.id)", start: nap.start,
                            row: PulseActivityRow(
                                chip: PulseActivityChip(kind: .sleep, symbol: "powersleep",
                                                        value: PulseFormat.hoursMinutes(nap.asleepMin)),
                                name: String(localized: "Nap"),
                                start: PulseFormat.clock(nap.start),
                                end: PulseFormat.clock(nap.end),
                                barColor: PulseTheme.sleep),
                            route: .sleepDive))
        }
        for w in home.workouts {
            let end = w.start.addingTimeInterval(TimeInterval(w.durationMin * 60))
            out.append(Item(id: "workout-\(w.id)", start: w.start,
                            row: PulseActivityRow(
                                chip: PulseActivityChip(kind: w.strain == nil ? .pending : .strain,
                                                        symbol: WorkoutTypeIconography.systemSymbolName(for: w.sport),
                                                        value: w.strain.map { PulseFormat.oneDecimal($0) }),
                                name: w.title,
                                start: PulseFormat.clock(w.start),
                                end: PulseFormat.clock(end),
                                barColor: PulseTheme.strain),
                            route: PulseRoute.activityDetail(w.route).forExistingEntryPoint))
        }
        return out.sorted { $0.start < $1.start }
    }

    var body: some View {
        let rows = items
        VStack(alignment: .leading, spacing: 0) {
            PulseLink(PulseRoute.dayTimeline.forExistingEntryPoint) {
                PulseCardTitle(home.day.isToday ? String(localized: "Today's Activities")
                                                : String(localized: "Activities"),
                               accessory: .expand)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityHint(String(localized: "Expands the day's heart rate"))
            .padding(.horizontal, 4)

            VStack(spacing: PulseTheme.Layout.gridGap) {
                if rows.isEmpty {
                    Text(String(localized: "Nothing logged yet. Start an activity or wear your strap to sleep."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                ForEach(rows) { item in
                    PulseLink(item.route) { item.row }
                        .buttonStyle(PulsePressStyle())
                }
            }
            .padding(.top, 13)

            PulseButtonRow {
                Button { navigator.quickAction(.addActivity) } label: {
                    Label(String(localized: "Add activity"), systemImage: "plus")
                }
                .buttonStyle(.pulseNested)
                if home.day.isToday && !rows.isEmpty {
                    Button { navigator.quickAction(.workout) } label: {
                        Label(String(localized: "Start activity"), systemImage: "stopwatch")
                    }
                    .buttonStyle(.pulseNested)
                }
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .id("pulse.activities")
    }
}

// MARK: - Tonight's Sleep

/// TONIGHT'S SLEEP › (§3.1 item 8c): the bedtime that meets tonight's need and the wake time, side by side
/// on one baseline (22 pt Bold condensed, no AM / PM), joined by a dashed connector; under them
/// "RECOMMENDED BEDTIME" and the alarm state (orange "ALARM OFF", or teal "● ALARM ON" over "EXACT TIME");
/// then SET ALARM (EDIT ALARM once set) with the strap-vibrate glyph.
struct PulseTonightsSleepCard: View {
    let tonight: PulseTonight

    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                PulseLink(PulseRoute.sleepPlanner.forExistingEntryPoint) {
                    PulseCardTitle(String(localized: "Tonight's Sleep"), accessory: .trailingChevron)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                HStack(alignment: .top, spacing: 8) {
                    column(icon: AnyView(sunIcon("sunset")),
                           time: tonight.bedtime) {
                        PulseWordWrapText(String(localized: "Recommended bedtime"), style: .label, alignment: .center)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "Recommended bedtime \(PulseFormat.clock(tonight.bedtime))"))
                    Line()
                        .stroke(PulseTheme.dash, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .frame(maxWidth: 60)
                        .frame(height: 26)
                        .accessibilityHidden(true)
                    column(icon: tonight.alarmOn ? AnyView(PulseStrapVibrateGlyph(height: 17).foregroundStyle(PulseTheme.textSecondary))
                                                 : AnyView(sunIcon("sunrise")),
                           time: tonight.wake) {
                        alarmCaption
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(wakeAccessibility)
                }
                Button { navigator.present(PulseRoute.sleepPlanner.forExistingEntryPoint) } label: {
                    Label {
                        Text(tonight.alarmOn ? String(localized: "Edit alarm") : String(localized: "Set alarm"))
                    } icon: {
                        if tonight.alarmOn {
                            Image(systemName: "pencil")
                        } else {
                            PulseStrapVibrateGlyph(height: 15)
                        }
                    }
                }
                .buttonStyle(.pulseNested)
            }
        }
        .id("pulse.tonight")
    }

    private func sunIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(PulseTheme.textSecondary)
    }

    @ViewBuilder
    private var alarmCaption: some View {
        if tonight.alarmOn {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Circle().fill(PulseTheme.positive).frame(width: 6, height: 6)
                    Text(String(localized: "Alarm on"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.positive)
                }
                Text(String(localized: "Exact time"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        } else {
            Text(String(localized: "Alarm off"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.negative)
        }
    }

    private var wakeAccessibility: String {
        let time = PulseFormat.clock(tonight.wake)
        return tonight.alarmOn
            ? String(localized: "Wake \(time), alarm on, exact time")
            : String(localized: "Wake \(time), alarm off")
    }

    /// A column: the icon and time on one line (the same baseline in both columns, since they are aligned
    /// at the top and both lines are the same height), the caption under it.
    private func column<Caption: View>(icon: AnyView, time: Date,
                                       @ViewBuilder caption: () -> Caption) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                icon
                Text(PulseFormat.clockNoMeridiem(time))
                    .font(PulseType.font(.sleepTime))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(height: 26)
            caption()
        }
        .frame(maxWidth: .infinity)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}

// MARK: - Journal

/// MY JOURNAL › (§3.1 item 8d): the seven days ending on the selected day as circles (logged: green with a
/// black ✓; not logged: a white-40% ring; the selected day pending: grey with a white ring), the newest at
/// the right, then BEHAVIOR INSIGHTS. The title opens today's journal; a day's circle opens that day's.
struct PulseJournalCard: View {
    let strip: PulseJournalStrip
    @EnvironmentObject private var router: NavRouter
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                Button { router.openJournal() } label: {
                    PulseCardTitle(String(localized: "My Journal"), accessory: .chevron)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens the journal"))
                PulseDayCircleRow(days: strip.days.enumerated().map { index, day in
                    let newest = index == strip.days.count - 1
                    return PulseDayCircleRow.Day(
                        id: day.key,
                        label: PulseFormat.dayLabel(day.key, template: "EEE"),
                        state: day.logged ? .logged : (newest ? .pending : .notLogged),
                        isCurrent: newest)
                }, onTap: { day in
                    if let match = strip.days.first(where: { $0.key == day.id }) {
                        router.openJournal(day: match.offset)
                    }
                })
                Button { navigator.open(PulseRoute.behaviorInsights.forExistingEntryPoint) } label: {
                    Label(String(localized: "Behavior insights"), systemImage: "lightbulb")
                }
                .buttonStyle(.pulseNested(fill: PulseTheme.Journal.insightsButton))
            }
        }
    }
}

// MARK: - My Plan

/// My Plan's empty state (§3.1 item 9): "Build Your Best Self", one line on what a plan does, and
/// "EXPLORE PLANS →", with ZENO's own art (three dashed green rings holding a moon, a heart and a lifter).
/// The journal-plan group adds the active plan's collapsed and expanded cards.
struct PulsePlanCard: View {
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        Button { navigator.open(.weeklyPlan(editing: false)) } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Build Your Best Self"))
                        .pulseText(.cardHeadline)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "Set goals, track progress, and turn small actions into long-term wins."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(String(localized: "Explore plans")).pulseText(.label)
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(PulseTheme.Plan.exploreCTA)
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
                PulsePlanArt()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulseCardBackground(.solid(PulseTheme.Plan.emptyCard))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens your plan"))
    }
}

/// Three dashed green rings holding a moon, a heart and a lifter (SF Symbols; ZENO's own art).
private struct PulsePlanArt: View {
    var body: some View {
        ZStack {
            ring("moon.fill").offset(x: -22, y: -16)
            ring("heart.fill").offset(x: 18, y: -20)
            ring("dumbbell.fill").offset(x: 0, y: 18)
        }
        .frame(width: 84, height: 84)
        .accessibilityHidden(true)
    }

    private func ring(_ symbol: String) -> some View {
        ZStack {
            Circle().strokeBorder(PulseTheme.Plan.progress, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PulseTheme.Plan.progress)
        }
        .frame(width: 36, height: 36)
    }
}

// MARK: - Calendar

/// The day picker: a graphical calendar bounded by the earliest banked day and today.
struct PulseCalendarSheet: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "",
                selection: Binding(
                    get: { model.selectedLogicalDate },
                    set: { picked in
                        model.pick(date: picked)
                        dismiss()
                    }),
                in: model.earliestLogicalDate...Repository.logicalDay(Date()),
                displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(PulseTheme.accent)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle(String(localized: "Pick a day"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "Done")) { dismiss() }
                            .foregroundStyle(PulseTheme.accent)
                    }
                }
                .background(PulseTheme.card.ignoresSafeArea())
        }
        .presentationDetents([.medium, .large])
        .environment(\.colorScheme, .dark)
    }
}
#endif
