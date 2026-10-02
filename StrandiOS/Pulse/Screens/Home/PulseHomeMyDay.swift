#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Monitor tiles (§3.1 item 6)

/// HEALTH MONITOR › | STRESS MONITOR ›, side by side 12 pt apart. Always shown on today (ZENO has no
/// tiers), "Pending" while there is nothing to judge.
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

// MARK: - Coach pill or Ask row (§3.1 item 8a, §3.15)

/// "☀ Your Daily Outlook ›" by day, "☾ Your Day In Review ›" in the evening; plain once opened today.
/// With a Coach provider it opens the Coach sheet seeded with the day; without one, or with Coach off, it
/// opens ZENO's own outlook page [Z]. While no outlook can be made (no provider and under 3 scored days)
/// the Ask row stands in, and with Coach off too there is nothing.
struct PulseHomeCoachEntry: View {
    let home: HomeSnapshot
    let facts: PulseOutlookFacts?

    @Environment(\.pulseCoach) private var coach
    @Environment(\.pulseNavigator) private var navigator
    /// The outlooks opened, as "yyyy-MM-dd|morning" / "yyyy-MM-dd|evening" (today's only).
    @AppStorage("pulse.home.outlookRead") private var read = ""

    var body: some View {
        let evening = PulseDailyOutlook.isEvening(home)
        let content = PulseDailyOutlook.compose(home: home, facts: facts, evening: evening)
        let readKey = "\(home.day.key)|\(evening ? "evening" : "morning")"
        if coach.availability == .ready || (home.scoredDays >= 3 && !content.isEmpty) {
            PulseCoachPill(kind: evening ? .evening : .morning,
                           title: evening ? String(localized: "Your Day In Review")
                                          : String(localized: "Your Daily Outlook"),
                           isRead: read == readKey) {
                read = readKey
                if coach.availability == .ready {
                    coach.open(content.plainText)
                } else {
                    navigator.open(PulseDailyOutlookRoute(content: content).route)
                }
            }
        } else if coach.availability != .off {
            PulseAskRow { coach.open(nil) }
        }
    }
}

// MARK: - Today's Activities (§3.1 item 8b, §2.6 item 7)

/// TODAY'S ACTIVITIES (ACTIVITIES on a past day): last night, naps and workouts as activity rows, oldest
/// first, in every chip state (scored, unscored night, strain still computing, a recovery activity's
/// duration, logged ahead of time); "NO SLEEP" with ADD SLEEP when the night is missing; then "+ ADD
/// ACTIVITY" and "START ACTIVITY", or ADD alone on a past day or with nothing logged. ⤢ opens the day's
/// heart-rate timeline. The title sits at the card's 16 pt padding; rows and buttons are inset 12 pt.
struct PulseTodaysActivitiesCard: View {
    let home: HomeSnapshot
    /// Show "NO SLEEP" when the night is missing (not for a new member, who has nothing yet).
    var showsMissingSleep = true

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
                                chip: PulseActivityChip(kind: .sleep, symbol: "chair.lounge.fill",
                                                        value: PulseFormat.hoursMinutes(nap.asleepMin)),
                                name: String(localized: "Nap"),
                                start: PulseFormat.clock(nap.start),
                                end: PulseFormat.clock(nap.end),
                                barColor: PulseTheme.sleep),
                            route: .sleepDive))
        }
        let now = Date()
        for w in home.workouts {
            let end = w.start.addingTimeInterval(TimeInterval(w.durationMin * 60))
            let ahead = w.start > now
            let recovery = PulseHomeActivity.isRecoveryActivity(w.sport)
            let kind: PulseActivityChip.Kind = ahead ? .preAdded
                : (recovery ? .recovery : (w.strain == nil ? .pending : .strain))
            let value = recovery ? PulseFormat.hoursMinutes(Double(w.durationMin)) : w.strain.map { PulseFormat.oneDecimal($0) }
            out.append(Item(id: "workout-\(w.id)", start: w.start,
                            row: PulseActivityRow(
                                chip: PulseActivityChip(kind: kind,
                                                        symbol: WorkoutTypeIconography.systemSymbolName(for: w.sport),
                                                        value: value),
                                name: w.title,
                                start: PulseFormat.clock(w.start),
                                end: PulseFormat.clock(end),
                                barColor: recovery ? PulseTheme.recoveryActivityChip : PulseTheme.strain,
                                dottedBar: ahead),
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
                if home.lastNight == nil && showsMissingSleep {
                    PulseNoSleepRow { navigator.quickAction(.addActivity) }
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

/// "NO SLEEP" (help-center/68): a sleep chip with the moon alone, the words, and an outlined white ADD
/// SLEEP (radius 8, 36 pt) at the right, opening Add Activity (which offers Sleep and Nap).
struct PulseNoSleepRow: View {
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 96, height: 40)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    .fill(PulseTheme.sleep))
                .accessibilityHidden(true)
            Text(String(localized: "No sleep"))
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 6)
            Button(action: onAdd) {
                Text(String(localized: "Add sleep"))
                    .pulseText(.buttonLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.horizontal, PulseTheme.Space.s)
                    .frame(minHeight: 36)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                        .strokeBorder(Color.white, lineWidth: 1.5))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.activity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular).fill(PulseTheme.nested))
        .accessibilityElement(children: .contain)
    }
}

/// Which activities are recovery activities (scored for recovery, shown with their duration in the
/// light-blue chip rather than a Strain; activity-flows-2026/e12).
enum PulseHomeActivity {
    static func isRecoveryActivity(_ sport: String) -> Bool {
        let s = sport.lowercased()
        return ["sauna", "meditat", "breath", "ice bath", "cold plunge", "massage"].contains { s.contains($0) }
    }
}

// MARK: - Tonight's Sleep (§3.1 item 8c)

/// TONIGHT'S SLEEP ›: the bedtime that meets tonight's need and the wake time, side by side on one baseline
/// (22 pt Bold condensed, no AM / PM), joined by a dashed connector; under them "RECOMMENDED BEDTIME" and
/// the alarm state (orange "ALARM OFF", or teal "● ALARM ON" over "EXACT TIME"); then SET ALARM (EDIT ALARM
/// once set) with the strap-vibrate glyph. Opens the Sleep Planner.
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
                Button { navigator.open(PulseRoute.sleepPlanner.forExistingEntryPoint) } label: {
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

    /// A column: the icon and time on one line (the same baseline in both columns), the caption under it.
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

// MARK: - Journal (§3.1 item 8d)

/// MY JOURNAL › : the seven days ending on the selected day as circles (logged: green with a black ✓; not
/// logged: a white-40% ring; the selected day pending: grey with a white ring), the newest at the right,
/// then BEHAVIOR INSIGHTS. The title opens the selected day's journal; a day's circle opens that day's.
struct PulseJournalCard: View {
    let strip: PulseJournalStrip
    @EnvironmentObject private var router: NavRouter
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                Button { openJournal(strip.days.last?.offset ?? 0) } label: {
                    PulseCardTitle(String(localized: "My Journal"), accessory: .trailingChevron)
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
                    if let match = strip.days.first(where: { $0.key == day.id }) { openJournal(match.offset) }
                })
                Button { navigator.open(PulseRoute.behaviorInsights.forExistingEntryPoint) } label: {
                    Label(String(localized: "Behavior insights"), systemImage: "lightbulb")
                }
                .buttonStyle(.pulseNested(fill: PulseTheme.Journal.insightsButton))
            }
        }
    }

    /// The Journal for a day `offset` days back, through NavRouter's request: the shell opens the rebuilt
    /// Journal with the offset, and the classic one reads it from the router until then.
    private func openJournal(_ offset: Int) {
        router.openJournal(day: offset == 0 ? nil : offset)
    }
}

// MARK: - My Plan (§3.1 item 9)

/// My Plan. Today it shows the empty state (§3.1 item 9, reviews/r113): "Build Your Best Self", one line on
/// what a plan does, and "EXPLORE PLANS →", with ZENO's own art (three dashed green rings holding a moon, a
/// heart and a lifter). It opens the Plan Overview (`.weeklyPlan`).
///
/// TODO(plan-card): group "journal-plan" builds the plan store. Once an active plan exists, replace this
/// empty state with the collapsed card ("CUSTOM PLAN" ⌄, "6 days left", "27% ACCOMPLISHED" over a 4 pt
/// green progress bar) that expands in place to the goal rows and "VIEW MY PLAN" (§3.1 item 9). Feed it a
/// plain value (`PulsePlanCard(plan:)`), resolved off the main actor like Home's other snapshots.
struct PulsePlanCard: View {
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        Button { navigator.open(PulseRoute.weeklyPlan(editing: false).forExistingEntryPoint) } label: {
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
            .padding(.leading, PulseTheme.Layout.cardPadding + 4)
            .padding(.trailing, PulseTheme.Layout.cardPadding)
            .padding(.vertical, PulseTheme.Layout.cardPadding + 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulseCardBackground(.solid(PulseTheme.Plan.emptyCard))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens your plan"))
        .id("pulse.plan-card")
    }
}

/// Three dashed green rings holding a moon, a heart and a lifter (SF Symbols; ZENO's own art).
private struct PulsePlanArt: View {
    var body: some View {
        ZStack {
            ring("moon.stars.fill", size: 50).offset(x: 14, y: -18)
            ring("heart.fill", size: 34).offset(x: -30, y: -4)
            ring("figure.strengthtraining.traditional", size: 42).offset(x: 6, y: 26)
        }
        .frame(width: 96, height: 100)
        .accessibilityHidden(true)
    }

    private func ring(_ symbol: String, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(PulseTheme.card)
            Circle().strokeBorder(PulseTheme.Plan.progress, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .frame(width: size, height: size)
    }
}
#endif
