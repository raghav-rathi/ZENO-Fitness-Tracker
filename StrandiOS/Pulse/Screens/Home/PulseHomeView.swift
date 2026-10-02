#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Pulse Home (WHOOP_UI_SPEC §3.1): the header, ZENO's wordmark, the three dials, My Day (Today's
/// Activities and Tonight's Sleep), Key Stats, Stress and the journal.
///
/// Owned by group "home", which rebuilds it to the spec's full order (coaching stack, monitor tiles, My
/// Plan, My Dashboard). Everything below the header renders `model.home`, a snapshot built off the main
/// actor. Swiping sideways changes the day; the header's pager and calendar do the same. Once the dials
/// scroll off, the mini-ring row pins under the status bar.
struct PulseHomeView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var dialsScrolledOff = false

    var body: some View {
        PulseScreenScaffold(role: .tabRoot, showsNavigationBar: false, spacing: 0, topPadding: 0,
                            refresh: { await model.pullToRefresh() }, ready: model.home != nil) {
            PulseHomeHeader()
                .padding(.top, 2)
            PulseZenoWordmark()
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            PulseDialsRow(home: model.home)
                .padding(.top, 24)
                .pulseScrolledPast($dialsScrolledOff, threshold: 8)
            PulseHomeContent()
        }
        .pulseStatusBarBackdrop()
        .overlay(alignment: .top) {
            if dialsScrolledOff, let home = model.home {
                PulseMiniRingRow(items: home.dials.map { dial in
                    PulseMiniRingRow.Item(id: dial.score.rawValue,
                                          content: dial.dialContent(target: home.target),
                                          action: { navigator.open(.dive(dial.score)) })
                })
                .padding(.vertical, 2)
                .background(PulseTheme.pageTop.ignoresSafeArea(edges: .top))
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

/// The header row (§1.4): the avatar at the left, the date pager in the centre, the strap's battery and
/// status at the right.
struct PulseHomeHeader: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var showCalendar = false

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                PulseAvatarButton { navigator.present(PulseRoute.profile.forExistingEntryPoint) }
                Spacer(minLength: 0)
                PulseLiveHRChip()
                PulseStrapChip()
            }
            PulseDayPager(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                          canGoBack: model.dayOffset < model.maxDayOffset,
                          canGoForward: model.dayOffset > 0,
                          onBack: { model.stepDay(1) },
                          onForward: { model.stepDay(-1) },
                          onTitleTap: { showCalendar = true })
        }
        .frame(minHeight: PulseTheme.Layout.minTapTarget)
        .sheet(isPresented: $showCalendar) {
            PulseCalendarSheet()
        }
    }
}

/// The profile photo, 32 pt; opens Profile (Settings until Profile is rebuilt).
struct PulseAvatarButton: View {
    let action: () -> Void
    @EnvironmentObject private var profile: ProfileStore

    var body: some View {
        Button(action: action) {
            ProfileAvatarView(imageData: profile.avatarImageData, size: 30, fallbackTint: PulseTheme.textSecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(PulseTheme.card))
                .clipShape(Circle())
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Profile"))
    }
}

// MARK: - Dials

/// Sleep · Recovery · Strain (§2.5), each opening its deep dive. The same row shows the loading state, so
/// the arcs sweep once when the first snapshot lands and never again on the way back from a dive.
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
        let reserves = dials.contains { $0.content.caption != nil }
        HStack(alignment: .top, spacing: PulseTheme.Dial.homeSpacing) {
            ForEach(dials, id: \.score) { dial in
                NavigationLink(value: PulseRoute.dive(dial.score)) {
                    PulseScoreDial(content: dial.content, reservesCaption: reserves)
                }
                .buttonStyle(PulseDialButtonStyle())
                .accessibilityHint(String(localized: "Opens \(dial.score.displayName) details"))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Content

/// Everything below the dials, rendered from `model.home`.
struct PulseHomeContent: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        if let home = model.home {
            VStack(alignment: .leading, spacing: 0) {
                PulseSectionHeader(String(localized: "My Day"),
                                   accessory: .plus(String(localized: "Start an activity")) { navigator.quickAction(.menu) })
                    .padding(.top, PulseTheme.Space.xxl)
                    .id("pulse.myday")
                VStack(spacing: PulseTheme.Layout.stackGap) {
                    PulseTodaysActivitiesCard(home: home)
                    if let tonight = home.tonight {
                        PulseTonightsSleepCard(tonight: tonight)
                    }
                }
                .padding(.top, PulseTheme.Layout.headerGap)

                PulseKeyStatsSection(stats: home.stats)
                    .padding(.top, PulseTheme.Layout.sectionGap)
                    .id("pulse.stats")
                if let stress = home.stress {
                    PulseStressSection(stress: stress, onBreathe: { navigator.quickAction(.breathe) })
                        .padding(.top, PulseTheme.Layout.sectionGap)
                        .id("pulse.stress")
                }
                if let journal = home.journal {
                    PulseJournalCard(strip: journal)
                        .padding(.top, PulseTheme.Layout.sectionGap)
                        .id("pulse.journal")
                }
            }
            // While a newly selected day builds, the previous day's numbers dim rather than pass for it.
            .opacity(model.homeIsStale ? 0.45 : 1)
            .animation(.easeOut(duration: 0.15), value: model.homeIsStale)
        } else {
            ProgressView()
                .tint(PulseTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, PulseTheme.Space.xxl)
        }
    }
}

// MARK: - Today's Activities

/// TODAY'S ACTIVITIES (ACTIVITIES on a past day): last night, naps and workouts as activity rows, oldest
/// first, then "+ ADD ACTIVITY" and "START ACTIVITY" (§3.1 item 8b).
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
                                barColor: PulseTheme.textPrimary),
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
                                barColor: PulseTheme.textPrimary),
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
        PulseCard {
            VStack(alignment: .leading, spacing: PulseTheme.Layout.gridGap) {
                HStack {
                    PulseCardTitle(home.day.isToday ? String(localized: "Today's Activities")
                                                    : String(localized: "Activities"))
                    PulseLink(PulseRoute.dayTimeline.forExistingEntryPoint) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(PulseTheme.textTertiary)
                            .frame(width: 32, height: 24, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "Expand the day's heart rate"))
                }
                if rows.isEmpty {
                    Text(String(localized: "Nothing logged yet. Start an activity or wear your strap to sleep."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(rows) { item in
                    PulseLink(item.route) { item.row }
                        .buttonStyle(PulsePressStyle())
                }
                HStack(spacing: PulseTheme.Layout.gridGap) {
                    Button { navigator.present(PulseRoute.addActivity.forExistingEntryPoint) } label: {
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
            }
        }
    }
}

// MARK: - Tonight's Sleep

/// TONIGHT'S SLEEP (§3.1 item 8c): the bedtime that meets tonight's need and the wake time it counts back
/// from, joined by a dashed connector, then the planner button.
struct PulseTonightsSleepCard: View {
    let tonight: PulseTonight

    @Environment(\.pulseNavigator) private var navigator

    /// Where the wake time came from, said plainly: ZENO does not read the strap alarm's state here.
    private var wakeCaption: String {
        switch tonight.wakeSource {
        case .alarm: return String(localized: "Wind-down wake")
        case .habit: return String(localized: "Usual wake")
        case .fallback: return String(localized: "Default wake")
        }
    }

    private var needLine: String {
        var parts = [String(localized: "\(PulseFormat.duration(minutes: tonight.needMin)) sleep need")]
        if tonight.debtMin >= 5 { parts.append(String(localized: "+\(PulseFormat.duration(minutes: tonight.debtMin)) debt")) }
        if tonight.strainMin >= 5 { parts.append(String(localized: "+\(PulseFormat.duration(minutes: tonight.strainMin)) strain")) }
        if tonight.napCreditMin >= 5 { parts.append(String(localized: "−\(PulseFormat.duration(minutes: tonight.napCreditMin)) nap")) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                PulseLink(PulseRoute.sleepPlanner.forExistingEntryPoint) {
                    PulseCardTitle(String(localized: "Tonight's Sleep"), accessory: .trailingChevron)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                HStack(alignment: .center, spacing: 8) {
                    column(symbol: "sunset", time: PulseFormat.clock(tonight.bedtime),
                           caption: String(localized: "Recommended bedtime"), captionColor: PulseTheme.textSecondary)
                    Line()
                        .stroke(PulseTheme.dash, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .frame(height: 1)
                        .frame(maxWidth: 60)
                        .padding(.bottom, 18)
                        .accessibilityHidden(true)
                    column(symbol: "sunrise", time: PulseFormat.clock(tonight.wake), caption: wakeCaption,
                           captionColor: tonight.wakeSource == .fallback ? PulseTheme.negative : PulseTheme.textSecondary)
                }
                Text(needLine)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                Button { navigator.present(PulseRoute.sleepPlanner.forExistingEntryPoint) } label: {
                    Label(String(localized: "Set alarm"), systemImage: "alarm")
                }
                .buttonStyle(.pulseNested)
            }
        }
        .id("pulse.tonight")
    }

    private func column(symbol: String, time: String, caption: String, captionColor: Color) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .accessibilityHidden(true)
                Text(time)
                    .font(PulseType.font(.mediumValue))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(caption)
                .pulseText(.label)
                .foregroundStyle(captionColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
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

/// MY JOURNAL › (§3.1 item 8d): the last seven days as circles (logged: green with a black ✓; not logged:
/// a white-40% ring; today pending: grey with a white ring), the newest at the right. The title opens
/// today's journal; a day's circle opens that day's.
struct PulseJournalCard: View {
    let strip: PulseJournalStrip
    @EnvironmentObject private var router: NavRouter

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                Button { router.openJournal() } label: {
                    PulseCardTitle(String(localized: "My Journal"), accessory: .chevron)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens the journal"))
                HStack(spacing: 0) {
                    ForEach(strip.days) { day in
                        Button { router.openJournal(day: day.offset) } label: {
                            VStack(spacing: 8) {
                                Text(PulseFormat.dayLabel(day.key, template: "EEE"))
                                    .pulseText(.label)
                                    .foregroundStyle(day.offset == 0 ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                                circle(day)
                            }
                            .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .accessibilityLabel(dayName(day))
                        .accessibilityValue(day.logged ? String(localized: "Logged") : String(localized: "Not logged"))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func circle(_ day: PulseJournalStrip.Day) -> some View {
        if day.logged {
            Circle()
                .fill(PulseTheme.Journal.logged)
                .overlay(Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.black))
                .frame(width: 28, height: 28)
        } else if day.offset == 0 {
            Circle()
                .fill(PulseTheme.Journal.todayPending)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                .frame(width: 28, height: 28)
        } else {
            Circle()
                .strokeBorder(PulseTheme.Journal.notLogged, lineWidth: 1.5)
                .frame(width: 28, height: 28)
        }
    }

    private func dayName(_ day: PulseJournalStrip.Day) -> String {
        switch day.offset {
        case 0: return String(localized: "Today")
        case 1: return String(localized: "Yesterday")
        default: return String(localized: "\(day.offset) days ago")
        }
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

// MARK: - Key stats

struct PulseKeyStatsSection: View {
    let stats: [PulseKeyStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "Key stats"), trailing: String(localized: "vs 30-day avg"))
            // Two per row; an odd last tile takes the full width rather than leaving a hole.
            VStack(spacing: 12) {
                ForEach(rows, id: \.first?.id) { row in
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(row) { stat in
                            NavigationLink(value: stat.route) {
                                PulseStatTile(stat: stat)
                            }
                            .buttonStyle(PulsePressStyle())
                        }
                    }
                }
            }
        }
    }

    private var rows: [[PulseKeyStat]] {
        stride(from: 0, to: stats.count, by: 2).map { Array(stats[$0..<min($0 + 2, stats.count)]) }
    }
}

struct PulseStatTile: View {
    let stat: PulseKeyStat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: stat.icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .accessibilityHidden(true)
                PulseLabel(stat.title)
                Spacer(minLength: 0)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(stat.value)
                    .font(PulseTheme.numeral(30))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !stat.unit.isEmpty {
                    Text(stat.unit)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            if let comparison = stat.comparison {
                PulseComparisonLine(comparison: comparison, showsCaption: false)
            } else if stat.isRunningTotal {
                Text(String(localized: "So far today"))
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
            } else {
                Text(stat.value == "–" ? String(localized: "No data") : String(localized: "Building average"))
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            if let caption = stat.caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            PulseSparkline(values: stat.spark)
                .frame(height: 22)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .background(PulseCardSurface())
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
        .accessibilityHint(String(localized: "Opens the trend"))
    }

    private var accessibility: String {
        var parts = ["\(stat.title), \(stat.value) \(stat.unit)"]
        if let c = stat.comparison { parts.append(c.accessibility) }
        if let caption = stat.caption { parts.append(caption) }
        return parts.joined(separator: ". ")
    }
}

#endif
