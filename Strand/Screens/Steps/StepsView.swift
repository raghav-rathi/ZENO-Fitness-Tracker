import SwiftUI
import StrandDesign
import StrandAnalytics

/// The Steps screen: a day's count against the goal, its hour-by-hour shape, the last week and month, the
/// current streak and best day, the goal editor, and an honest note on where the numbers come from.
///
/// Everything renders from `StepsService.shared`: the same resolved days the Steps card, the Today tile and
/// the rolling average read, so no two of them can show different counts for one day. On iOS the in-progress
/// day moves live while the pedometer streams; macOS shows what is stored (a Health export, a strap counter,
/// the strap estimate).
///
/// `day` opens the screen on a given "yyyy-MM-dd" (Today's tile passes the day it is showing); nil means
/// today. The screen never shows a day after today.
struct StepsView: View {
    private let requestedDay: String?

    init(day: String? = nil) {
        requestedDay = day
    }

    @EnvironmentObject private var repo: Repository
    @ObservedObject private var service = StepsService.shared
    @AppStorage(StepsPrefs.goalKey) private var goalRaw = StepGoal.defaultGoal
    @AppStorage(StepsPrefs.goalNotificationKey) private var notifyOnGoal = false
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceSystemRaw = ""
    /// "Card transparency", as every liquid card honours it.
    @AppStorage(CardAppearancePrefs.opacityKey) private var cardOpacityPercent = CardAppearancePrefs.defaultPercent
    /// Hours for a focus day other than today (today's come live from the snapshot).
    @State private var pastDayHours: [StepSource: [Int]] = [:]
    @State private var confirmingDelete = false

    private let tint = StrandPalette.metricCyan

    private var goal: Int { StepGoal.clamp(goalRaw) }
    private var snapshot: StepsService.Snapshot { service.snapshot }
    private var today: String { snapshot.loaded ? snapshot.today : Repository.localDayKey(Date()) }
    private var day: String { min(requestedDay ?? today, today) }
    private var isToday: Bool { day == today }
    private var resolved: ResolvedStepDay? { snapshot.days[day] }
    private var cardOpacity: Double { max(0, min(1, Double(cardOpacityPercent) / 100)) }
    private var distanceSystem: UnitSystem {
        UnitPrefs.resolveDistance(system: UnitSystem(rawValue: unitSystemRaw) ?? .metric, override: distanceSystemRaw)
    }

    var body: some View {
        let history = StepsStats.history(resolved: snapshot.days, endingOn: day, today: today, goal: goal)
        ScreenScaffold(title: "Steps",
                       subtitle: LocalizedStringKey(StepsLabels.relative(day, today: today)),
                       onRefresh: { await service.refreshNow() },
                       topBackground: liquidScaffoldSky()) {
            VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                accessCard
                heroCard
                hourlyCard
                weekCard(history)
                monthCard(history)
                recordsRow(history)
                goalCard
                phoneHistoryCard
                howCountedCard
            }
        }
        .task(id: day) {
            service.activate(repo: repo)
            service.ensureCovers(day)
            if !isToday { pastDayHours = await service.hours(for: day) }
        }
        .confirmationDialog("Delete iPhone step history?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { Task { await service.deletePhoneHistory() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the steps ZENO saved from your iPhone. Apple Health and your strap's data stay. While access is on, ZENO reads the last 7 days again.")
        }
    }

    // MARK: - Cards

    /// A frosted card, the same surface HydrationView and Liquid Today use.
    private func card<V: View>(padding: CGFloat = 18, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NoopPanelSurface(tint: tint, cornerRadius: 22, surfaceOpacity: cardOpacity))
    }

    // MARK: Motion access

    /// Shown only when the iPhone could count steps but may not yet: the one place the Motion & Fitness
    /// prompt is asked for, behind an explanation and a tap.
    @ViewBuilder private var accessCard: some View {
        switch service.phoneAccess {
        case .notDetermined:
            card {
                VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                    Label("Count steps with this iPhone", systemImage: "iphone")
                        .font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text("Your iPhone counts steps whenever you carry it, even with ZENO closed. Allow Motion & Fitness and ZENO reads those steps, including the past 7 days. They stay on this iPhone.")
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    NoopButton("Allow Motion & Fitness", systemImage: "figure.walk", kind: .primary, fullWidth: true) {
                        Task { await service.requestPhoneAccess() }
                    }
                }
            }
        case .denied, .restricted:
            card {
                VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                    Label("iPhone step counting is off", systemImage: "iphone.slash")
                        .font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text(service.phoneAccess == .restricted
                         ? "Motion & Fitness is restricted on this iPhone, so ZENO can't read its step count. Steps come from Apple Health or your strap instead."
                         : "Motion & Fitness access is off for ZENO. Turn it on in Settings > Privacy & Security > Motion & Fitness to count steps with this iPhone.")
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    #if os(iOS)
                    if service.phoneAccess == .denied {
                        NoopButton("Open Settings", systemImage: "gearshape", kind: .secondary, fullWidth: true) {
                            if let url = URL(string: UIApplication.openSettingsURLString) { PlatformOpen.url(url) }
                        }
                    }
                    #endif
                }
            }
        case .authorized, .unavailable:
            EmptyView()
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        let steps = resolved?.steps
        return card(padding: 20) {
            VStack(spacing: 14) {
                GlowRing(fraction: steps.map { StepGoal.ringFraction(steps: $0, goal: goal) } ?? 0,
                         value: Double(steps ?? 0),
                         format: { value in steps == nil ? "—" : StepsFormat.count(Int(value.rounded())) },
                         color: tint, diameter: 188, lineWidth: 16)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "Steps"))
                    .accessibilityValue(heroSpoken(steps))
                VStack(spacing: 8) {
                    Text(goalLine(steps))
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .multilineTextAlignment(.center)
                    if let source = resolved?.source { StepsSourceBadge(source: source) }
                }
                statStrip(steps: steps)
                if let note = sideFactsNote { footnote(note).frame(maxWidth: .infinity, alignment: .center) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func goalLine(_ steps: Int?) -> String {
        guard let steps else {
            return isToday ? String(localized: "No steps counted yet today") : String(localized: "No steps recorded this day")
        }
        let percent = StepGoal.percent(steps: steps, goal: goal)
        if StepGoal.isMet(steps: steps, goal: goal) {
            return String(localized: "Goal of \(StepsFormat.count(goal)) reached · \(percent)%")
        }
        return String(localized: "of \(StepsFormat.count(goal)) steps · \(percent)%")
    }

    private func heroSpoken(_ steps: Int?) -> String {
        guard let steps else { return goalLine(nil) }
        return String(localized: "\(StepsFormat.count(steps)) of \(StepsFormat.count(goal)), \(StepGoal.percent(steps: steps, goal: goal)) percent")
    }

    /// Distance, floors and what is left, in three even columns.
    private func statStrip(steps: Int?) -> some View {
        let distance = snapshot.inputs.distanceM[day]
        let floors = snapshot.inputs.floorsUp[day]
        let remaining = steps.map { StepGoal.remaining(steps: $0, goal: goal) }
        return HStack(spacing: 0) {
            statCell(title: "Distance",
                     value: distance.map { UnitFormatter.distanceFromMeters($0, system: distanceSystem) } ?? "—")
            Rectangle().fill(StrandPalette.hairline).frame(width: 1, height: 30)
            statCell(title: "Floors", value: floors.map { StepsFormat.count($0) } ?? "—")
            Rectangle().fill(StrandPalette.hairline).frame(width: 1, height: 30)
            statCell(title: remaining == 0 ? "Goal met" : "To goal",
                     value: remaining.map { $0 == 0 ? "✓" : StepsFormat.count($0) } ?? "—")
        }
        .padding(.top, 4)
    }

    private func statCell(title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(StrandFont.number(17))
                .foregroundStyle(StrandPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title).strandOverline()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// Only the iPhone reports distance and floors. When another source won the count, say so, so the two
    /// figures are not read as belonging to it.
    private var sideFactsNote: LocalizedStringKey? {
        let hasSideFacts = snapshot.inputs.distanceM[day] != nil || snapshot.inputs.floorsUp[day] != nil
        guard hasSideFacts, let source = resolved?.source, source != .phonePedometer else { return nil }
        return "Distance and floors are from your iPhone."
    }

    // MARK: Hourly

    private var hourlyCard: some View {
        // Re-evaluated each minute so the highlighted hour moves on even when no step arrives.
        TimelineView(.everyMinute) { context in
            let hours = isToday ? snapshot.todayHours : pastDayHours
            let chart = StepsHourly.chart(daySource: resolved?.source, dayTotal: resolved?.steps, hours: hours,
                                          currentHour: isToday ? Calendar.current.component(.hour, from: context.date) : nil)
            card {
                VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("By hour").strandOverline()
                        Spacer()
                        if let peak = chart?.peakHour {
                            Text(String(localized: "Busiest \(StepsLabels.hourTick(peak))"))
                                .font(StrandFont.caption)
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                    }
                    if let chart {
                        StepsHourlyBarsView(bars: chart.bars, highlightHour: chart.currentHour, tint: tint)
                        if !chart.matchesDaySource {
                            footnote("Hourly shape from \(chart.source.displayName). The total above is from \(resolved?.source.displayName ?? String(localized: "another source")).")
                        }
                    } else {
                        Text(resolved == nil ? "Nothing counted yet." : "No hour-by-hour record for this day. The total comes from a source that only keeps daily counts.")
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: History

    private func weekCard(_ history: StepsStats.History) -> some View {
        historyCard(title: "Last 7 days", average: history.weekAverage, window: 7) {
            StepsDailyBarsView(bars: history.week, goal: goal, tint: tint, highlightDay: day, labels: .weekdays)
        }
    }

    private func monthCard(_ history: StepsStats.History) -> some View {
        historyCard(title: "Last 30 days", average: history.monthAverage, window: 30) {
            StepsDailyBarsView(bars: history.month, goal: goal, tint: tint, highlightDay: day, labels: .sparse,
                               height: 112)
        }
    }

    private func historyCard<Chart: View>(title: LocalizedStringKey, average: StepsAverage, window: Int,
                                          @ViewBuilder chart: () -> Chart) -> some View {
        card {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).strandOverline()
                    Spacer()
                    Text(averageText(average, window: window))
                        .font(StrandFont.caption)
                        .foregroundStyle(StrandPalette.textSecondary)
                }
                chart()
            }
        }
    }

    /// "Avg 8,420" when every day in the window counted, "Avg 8,420 · 5 of 7 days" when some did not (a
    /// missing day is left out, not counted as zero, so the reader should know how many there were).
    private func averageText(_ average: StepsAverage, window: Int) -> String {
        guard let mean = average.mean else { return String(localized: "No days yet") }
        let value = StepsFormat.count(Int(mean.rounded()))
        if average.observedDays >= window { return String(localized: "Avg \(value)") }
        return String(localized: "Avg \(value) · \(average.observedDays) of \(window) days")
    }

    private func recordsRow(_ history: StepsStats.History) -> some View {
        HStack(spacing: NoopMetrics.gap) {
            recordTile(icon: "flame.fill", title: "Streak",
                       value: history.streak == 1 ? String(localized: "1 day") : String(localized: "\(history.streak) days"),
                       caption: String(localized: "In a row at your goal"))
            recordTile(icon: "trophy.fill", title: "Best day",
                       value: history.best.map { StepsFormat.count($0.steps) } ?? "—",
                       caption: history.best.map { StepsLabels.short($0.day) } ?? String(localized: "No days yet"))
        }
    }

    private func recordTile(icon: String, title: LocalizedStringKey, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title).strandOverline()
            }
            Text(value)
                .font(StrandFont.number(22))
                .foregroundStyle(StrandPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(StrandFont.caption)
                .foregroundStyle(StrandPalette.textTertiary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NoopPanelSurface(tint: tint, cornerRadius: 18, surfaceOpacity: cardOpacity))
        .accessibilityElement(children: .combine)
    }

    // MARK: Goal

    private var goalBinding: Binding<Int> {
        Binding(get: { goal }, set: { goalRaw = StepGoal.clamp($0) })
    }

    private var goalCard: some View {
        card {
            VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                Text("Daily goal").strandOverline()
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(StepsFormat.count(goal))
                        .font(StrandFont.rounded(28, weight: .bold))
                        .foregroundStyle(StrandPalette.textPrimary)
                        .monospacedDigit()
                    Text("steps")
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                    Spacer(minLength: 8)
                    Stepper("Daily goal", value: goalBinding, in: StepGoal.range, step: StepGoal.increment)
                        .labelsHidden()
                        .accessibilityValue(String(localized: "\(StepsFormat.count(goal)) steps"))
                }
                Divider().overlay(StrandPalette.hairline)
                Toggle(isOn: $notifyOnGoal) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notify me when I reach it")
                            .font(StrandFont.body)
                            .foregroundStyle(StrandPalette.textPrimary)
                        Text("Once a day. It arrives when ZENO next reads your steps, so it can be late if the app was closed.")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(StrandPalette.accent)
                .onChangeCompat(of: notifyOnGoal) { on in
                    if on { StepGoalNotifier.requestAuthorization() }
                }
            }
        }
    }

    // MARK: Phone history

    /// Where the iPhone's own history can be cleared. Only on a device that has one.
    @ViewBuilder private var phoneHistoryCard: some View {
        if service.phoneAccess != .unavailable {
            card {
                VStack(alignment: .leading, spacing: NoopMetrics.cardInnerSpacing) {
                    Text("iPhone step history").strandOverline()
                    Text("iOS keeps only a week of your iPhone's steps. ZENO saves them as they come in so your history keeps growing. It never leaves this iPhone.")
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    NoopButton("Delete iPhone step history", systemImage: "trash", kind: .tertiary) {
                        confirmingDelete = true
                    }
                }
            }
        }
    }

    // MARK: How it's counted

    private var howCountedCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("How steps are counted").strandOverline()
                bullet("A WHOOP 4.0 has no step counter, so each day shows the best count ZENO has, and the badge under the ring names it.")
                bullet("Apple Health comes first when it is connected: it merges your iPhone and Apple Watch without counting a step twice.")
                bullet("Next is this iPhone's own pedometer. It only counts while you carry the phone.")
                bullet("Last come a strap step counter (WHOOP 5.0/MG) and an estimate from your strap's motion. The estimate is approximate, and its days are drawn hollow in the charts.")
            }
        }
    }

    private func bullet(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•").foregroundStyle(tint)
            Text(text)
                .font(StrandFont.subhead)
                .foregroundStyle(StrandPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func footnote(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(StrandFont.footnote)
            .foregroundStyle(StrandPalette.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
