#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Monitor tiles (§3.1 item 6)

/// HEALTH MONITOR › | STRESS MONITOR ›, side by side 12 pt apart. Always shown on today (ZENO has no
/// tiers), "Pending" while there is nothing to judge.
struct PulseMonitorTiles: View {
    let home: HomeSnapshot
    /// Today's graded vitals (Home's own facts): WITHIN RANGE, ELEVATED / LOW, VERY ELEVATED / VERY LOW or
    /// OUT OF RANGE. nil only before they first build; the tile then reads the snapshot's count.
    let grades: PulseMonitorGrades?
    /// When the stress reading was last updated, resolved once for this tile and the dashboard's card.
    let stressUpdated: String?

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
        guard let grades else { return countStatus }
        guard !grades.isPending else { return .pending }
        guard let first = grades.out.first else {
            return .init(badge: .check, tint: .teal, word: String(localized: "Within range"),
                         wordColor: PulseTheme.positive,
                         detail: String(localized: "\(grades.inRange)/\(grades.judged) Metrics"))
        }
        // One vital out names it with how far out (help-center/91: "VERY ELEVATED · Skin Temperature"); a
        // vital far out leads even when others are out too; otherwise several read OUT OF RANGE and a count.
        let lead = grades.out.first { $0.strong } ?? first
        let others = grades.out.count - 1
        guard grades.out.count == 1 || lead.strong else {
            return .init(badge: .alert, tint: .orange, word: String(localized: "Out of range"),
                         wordColor: PulseTheme.negative,
                         detail: String(localized: "\(grades.out.count)/\(grades.judged) Metrics"))
        }
        let detail = others > 0 ? String(localized: "\(lead.name) +\(others)") : lead.name
        if lead.strong {
            return .init(badge: .alert, tint: .red,
                         word: lead.high == false ? String(localized: "Very low") : String(localized: "Very elevated"),
                         wordColor: PulseTheme.recoveryLowText, detail: detail)
        }
        let word: String
        switch lead.high {
        case true?: word = String(localized: "Elevated")
        case false?: word = String(localized: "Low")
        case nil: word = String(localized: "Out of range")
        }
        return .init(badge: .alert, tint: .orange, word: word, wordColor: PulseTheme.negative, detail: detail)
    }

    /// Before Home's own facts land: the snapshot's in / out count, without severity.
    private var countStatus: PulseMonitorTile.Status {
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

    /// The Stress Monitor's level as its gauge prints it, the reading's time under the word, or "Daily
    /// score" when the figure is the day's score rather than a reading.
    private var stressStatus: PulseMonitorTile.Status {
        guard let shown = home.stress?.shown else { return .pending }
        let level = PulseTheme.Stress.Level(value: shown)
        return .init(badge: .value(PulseFormat.oneDecimal(shown)), tint: level.tint, word: PulseHomeStress.word(level),
                     wordColor: level.color, detail: stressUpdated ?? String(localized: "Daily score"))
    }
}

/// The stress reading's words and update time, ONE helper for the STRESS MONITOR tile and the dashboard's
/// STRESS MONITOR card, so the two can never print different times or words for one reading.
enum PulseHomeStress {
    /// When the figure was read, worded as the Stress Monitor's gauge words it: the reading's time, with its
    /// weekday when it is from the evening before ("Fri 10:30 PM"). nil when the figure is the day's daily
    /// score rather than a reading, or there is none. Home resolves it once per pass for both readouts.
    static func updated(_ stress: PulseStressSummary?) -> String? {
        guard let stress, let at = stress.at else { return nil }
        if Repository.localDayKey(at) == stress.dayKey { return PulseFormat.clock(at) }
        let weekday = at.formatted(.dateTime.weekday(.abbreviated).locale(AppLanguage.activeLocale))
        return "\(weekday) \(PulseFormat.clock(at))"
    }

    static func word(_ level: PulseTheme.Stress.Level) -> String {
        switch level {
        case .low: return String(localized: "Low")
        case .medium: return String(localized: "Medium")
        case .high: return String(localized: "High")
        }
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

// MARK: - Year in Review (§3.39 [Z])

/// "✦ Your 2026 in Review ›": My Day's seasonal promo, shown from 1 December to 15 January
/// (`PulseYearInReviewView.isInSeason`) and opening the full-screen story. A pill row like the coach
/// pill's, on the story's own near-black page lifting into its indigo glow, the mark in the year's blue.
struct PulseYearInReviewPromo: View {
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        Button { navigator.open(.yearInReview) } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .pulseHomeGlyph(.pillMark)
                    .foregroundStyle(LinearGradient(gradient: PulseTheme.Gradients.yearInReviewYear,
                                                    startPoint: .leading, endPoint: .trailing))
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(PulseYearInReviewView.seasonTitle())
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                PulseChevron(color: PulseTheme.textPrimary, size: 14)
            }
            .padding(.horizontal, PulseTheme.Layout.cardPadding)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.pill)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(LinearGradient(colors: [PulseTheme.Gradients.yearInReviewPage,
                                              PulseTheme.Gradients.yearInReviewGlowIndigo],
                                     startPoint: .leading, endPoint: .trailing)))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens your year in review"))
        .id("pulse.year-in-review")
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
                    .pulseHomeHitArea()
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
            .padding(.top, PulseHomeMetrics.activitiesRowsTop)

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
            .padding(.top, PulseHomeMetrics.activitiesButtonsTop)
        }
        .padding(.horizontal, PulseTheme.Space.s)
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
            PulseActivityChip(kind: .sleep, symbol: "moon.fill", value: nil)
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
                    .frame(minHeight: PulseHomeMetrics.addSleepHeight)
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

/// How Home sorts activities by sport.
enum PulseHomeActivity {
    /// Recovery activities: scored for recovery, shown with their duration in the light-blue chip rather
    /// than a Strain (activity-flows-2026/e12).
    static func isRecoveryActivity(_ sport: String) -> Bool {
        let s = sport.lowercased()
        return ["sauna", "meditat", "breath", "ice bath", "cold plunge", "massage"].contains { s.contains($0) }
    }

    /// Strength activities, for STRENGTH ACTIVITY TIME: the catalogue's Strength, Weightlifting,
    /// Powerlifting, Bodybuilding and Calisthenics, and an export's own "strength" / "weight" names (the
    /// rule the WHOOP importer derives its strength minutes with).
    static func isStrengthActivity(_ sport: String) -> Bool {
        let s = sport.lowercased()
        return ["strength", "weight", "powerlifting", "bodybuilding", "calisthenics"].contains { s.contains($0) }
    }
}

// MARK: - Tonight's Sleep (§3.1 item 8c)

/// TONIGHT'S SLEEP ›: the Sleep Planner's plan for tonight (`PulseTonight`), its time to get into bed ("Now"
/// once it has passed) and its wake time, side by side on one baseline (22 pt Bold condensed, no AM / PM),
/// joined by a dashed connector; under them "RECOMMENDED BEDTIME" and the alarm state (orange "ALARM OFF",
/// or teal "● ALARM ON" over "EXACT TIME" when the strap alarm will buzz at that wake), both captions at one
/// size; then SET ALARM (EDIT ALARM once set) with the strap-vibrate glyph.
/// The title and both times are one link to the Sleep Planner (WHOOP's whole card opens it); SET ALARM is
/// its own button. Spacing measured on reviews/r41: times centred 41.5 pt under the title's, SET ALARM
/// 19.6 pt under the captions.
struct PulseTonightsSleepCard: View {
    let tonight: PulseTonight

    @Environment(\.pulseNavigator) private var navigator
    /// The captions' size: the label style's Dynamic Type size, shrunk only as far as the widest word of
    /// EITHER caption needs to fit its column, so the two never print at different sizes.
    @ScaledMetric(relativeTo: .caption2) private var labelSize = PulseTextStyle.label.spec.size
    /// The card's inner width, for the columns' width (measured outside the minute timeline).
    @State private var innerWidth: CGFloat = 0

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                PulseLink(PulseRoute.sleepPlanner.forExistingEntryPoint) {
                    VStack(alignment: .leading, spacing: 14) {
                        PulseCardTitle(String(localized: "Tonight's Sleep"), accessory: .trailingChevron)
                        // Re-read each minute, so the bedtime turns into "Now" when it passes.
                        TimelineView(.everyMinute) { context in
                            columns(now: context.date)
                        }
                        .padding(.top, PulseHomeMetrics.tonightTimesTop)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
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
                .padding(.top, PulseHomeMetrics.tonightButtonTop)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { innerWidth = $0 }
        }
        .id("pulse.tonight")
    }

    private func columns(now: Date) -> some View {
        let passed = now >= tonight.inBed
        return HStack(alignment: .top, spacing: PulseTheme.Space.xs) {
            column(icon: AnyView(sunIcon("sunset")),
                   time: passed ? String(localized: "Now") : PulseFormat.clockNoMeridiem(tonight.inBed)) {
                caption(String(localized: "Recommended bedtime"), color: PulseTheme.textSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(passed ? String(localized: "Recommended bedtime now")
                                       : String(localized: "Recommended bedtime \(PulseFormat.clock(tonight.inBed))"))
            Line()
                .stroke(PulseTheme.dash, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(maxWidth: PulseHomeMetrics.tonightConnector)
                .frame(height: PulseHomeMetrics.tonightTimeRow)
                .accessibilityHidden(true)
            column(icon: tonight.alarmOn ? AnyView(PulseStrapVibrateGlyph(height: 17).foregroundStyle(PulseTheme.textSecondary))
                                         : AnyView(sunIcon("sunrise")),
                   time: PulseFormat.clockNoMeridiem(tonight.wake)) {
                alarmCaption
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(wakeAccessibility)
        }
    }

    private func sunIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .pulseHomeGlyph(.tonightSun)
            .foregroundStyle(PulseTheme.textSecondary)
    }

    @ViewBuilder
    private var alarmCaption: some View {
        if tonight.alarmOn {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Circle().fill(PulseTheme.positive).frame(width: 6, height: 6)
                    caption(String(localized: "Alarm on"), color: PulseTheme.positive)
                }
                caption(String(localized: "Exact time"), color: PulseTheme.textSecondary)
            }
        } else {
            caption(String(localized: "Alarm off"), color: PulseTheme.negative)
        }
    }

    /// Every caption word, for the one size they share.
    private var captionWords: [String] {
        let alarm = tonight.alarmOn ? [String(localized: "Alarm on"), String(localized: "Exact time")]
                                    : [String(localized: "Alarm off")]
        return ([String(localized: "Recommended bedtime")] + alarm)
            .flatMap { $0.split(separator: " ").map(String.init) }
    }

    /// One time column's width: the card's inner width less the connector and the two gaps around it.
    private var columnWidth: CGFloat {
        max(0, (innerWidth - PulseHomeMetrics.tonightConnector - 2 * PulseTheme.Space.xs) / 2)
    }

    /// The label style's scaled size, shrunk (never below 60%) until the widest caption word fits a column,
    /// with a little room to spare: Text sets a word a hair wider than its measured advance.
    private var captionSize: CGFloat {
        let room = columnWidth * 0.94
        let widest = captionWords.map { PulseTextMetrics.width($0, style: .label, size: labelSize) }.max() ?? 0
        guard room > 0, widest > room else { return labelSize }
        return max(labelSize * 0.6, labelSize * room / widest)
    }

    /// A caption at the shared size, wrapping between words only (every word fits by construction).
    private func caption(_ text: String, color: Color) -> some View {
        let spec = PulseTextStyle.label.spec
        let size = captionSize
        return Text(text)
            .font(spec.font(size: size))
            .tracking(spec.tracking * size / spec.size)
            .textCase(.uppercase)
            // reviews/r41 sets the two lines of RECOMMENDED BEDTIME 15 pt apart.
            .lineSpacing(2)
            .multilineTextAlignment(.center)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var wakeAccessibility: String {
        let time = PulseFormat.clock(tonight.wake)
        return tonight.alarmOn
            ? String(localized: "Wake \(time), alarm on, exact time")
            : String(localized: "Wake \(time), alarm off")
    }

    /// A column: the icon and time on one line (the same baseline in both columns), the caption under it.
    private func column<Caption: View>(icon: AnyView, time: String,
                                       @ViewBuilder caption: () -> Caption) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                icon
                Text(time)
                    .font(PulseType.font(.sleepTime))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(height: PulseHomeMetrics.tonightTimeRow)
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

/// MY JOURNAL › : the seven days ending on the selected day as 22 pt circles (logged: green with a black ✓;
/// not logged: a white-40% ring; the selected day pending: grey with a white ring), the newest at the right,
/// then BEHAVIOR INSIGHTS. The title opens the selected day's journal; a day's circle opens that day's.
/// Proportions from completeness-critic/16 and reviews/r113: day labels centred ≈47 pt under the title's
/// centre, BEHAVIOR INSIGHTS ≈41 pt under the circles' centres, ≈188 pt in all.
struct PulseJournalCard: View {
    let strip: PulseJournalStrip
    @EnvironmentObject private var router: NavRouter
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                Button { openJournal(strip.days.last?.offset ?? 0) } label: {
                    PulseCardTitle(String(localized: "My Journal"), accessory: .trailingChevron)
                        .pulseHomeHitArea()
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
                }, diameter: PulseHomeMetrics.journalCircle, onTap: { day in
                    if let match = strip.days.first(where: { $0.key == day.id }) { openJournal(match.offset) }
                })
                .padding(.top, PulseHomeMetrics.journalStripTop)
                Button { navigator.open(PulseRoute.behaviorInsights.forExistingEntryPoint) } label: {
                    Label(String(localized: "Behavior insights"), systemImage: "lightbulb")
                }
                .buttonStyle(.pulseNested(fill: PulseTheme.Journal.insightsButton))
                .padding(.top, PulseHomeMetrics.journalButtonTop)
            }
        }
    }

    /// The Journal for a day `offset` days back, through NavRouter's request: the shell opens the rebuilt
    /// Journal with the offset, and the classic one reads it from the router until then.
    private func openJournal(_ offset: Int) {
        router.openJournal(day: offset == 0 ? nil : offset)
    }
}
#endif
