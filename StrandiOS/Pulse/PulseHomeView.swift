#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Pulse Home: header, the three dials, the strain target, My Day, Key Stats, Stress and the journal
/// prompt, in that order, and nothing else.
///
/// Everything below the header renders `model.home`, a snapshot built off the main actor. Swiping
/// sideways changes the day; the header's ‹ › and calendar do the same.
struct PulseHomeView: View {
    let onAction: (PulseQuickAction) -> Void
    let onSettings: () -> Void

    @Environment(PulseModel.self) private var model
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    private static let topID = "pulse.home.top"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: PulseTheme.sectionSpacing) {
                    Color.clear.frame(height: 0).id(Self.topID)
                    PulseHomeHeader(onSettings: onSettings, onPlus: { onAction(.menu) })
                    PulseHomeContent(onAction: onAction)
                    // Room for the floating ＋ so the last card is never under it.
                    Color.clear.frame(height: 76).id("pulse.bottom")
                }
                .padding(.horizontal, PulseTheme.pagePadding)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .pulseStatusBarBackdrop()
            .refreshable { await model.pullToRefresh() }
            .simultaneousGesture(daySwipe)
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(Self.topID, anchor: .top) }
            }
            .pulseDebugScroll(proxy, ready: model.home != nil)
        }
        .overlay(alignment: .bottom) {
            PulseFloatingPlus { onAction(.menu) }
        }
        .sensoryFeedback(.selection, trigger: model.dayOffset)
        .pulsePage()
        .toolbar(.hidden, for: .navigationBar)
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

struct PulseHomeHeader: View {
    let onSettings: () -> Void
    let onPlus: () -> Void

    @Environment(PulseModel.self) private var model
    @State private var showCalendar = false

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                PulseAvatarButton(action: onSettings)
                Spacer(minLength: 4)
                if model.dayOffset > 0 {
                    Button { model.setDayOffset(0) } label: {
                        PulseChip(text: String(localized: "Today"), tint: PulseTheme.accent, filled: true)
                            .frame(minHeight: PulseTheme.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityHint(String(localized: "Jumps back to today"))
                }
                PulseLiveHRChip()
                PulseStrapChip()
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(PulseTheme.cardRaised))
                        .overlay(Circle().strokeBorder(PulseTheme.hairline, lineWidth: 1))
                        .frame(width: PulseTheme.minTapTarget, height: PulseTheme.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Start an activity"))
            }

            HStack(spacing: 0) {
                Button { model.stepDay(1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: PulseTheme.minTapTarget, height: PulseTheme.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .foregroundStyle(model.dayOffset < model.maxDayOffset ? PulseTheme.textPrimary : PulseTheme.textTertiary.opacity(0.5))
                .disabled(model.dayOffset >= model.maxDayOffset)
                .accessibilityLabel(String(localized: "Previous day"))

                Button { showCalendar = true } label: {
                    VStack(spacing: 1) {
                        Text(PulseFormat.dayTitle(offset: model.dayOffset, date: model.selectedLogicalDate))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(PulseTheme.textPrimary)
                        Text(PulseFormat.daySubtitle(offset: model.dayOffset, date: model.selectedLogicalDate))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: PulseTheme.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "\(PulseFormat.dayTitle(offset: model.dayOffset, date: model.selectedLogicalDate)), \(PulseFormat.daySubtitle(offset: model.dayOffset, date: model.selectedLogicalDate))"))
                .accessibilityHint(String(localized: "Opens a calendar. Swipe sideways to change the day."))

                Button { model.stepDay(-1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .frame(width: PulseTheme.minTapTarget, height: PulseTheme.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .foregroundStyle(model.dayOffset > 0 ? PulseTheme.textPrimary : PulseTheme.textTertiary.opacity(0.5))
                .disabled(model.dayOffset == 0)
                .accessibilityLabel(String(localized: "Next day"))
            }
        }
        .padding(.top, 4)
        .sheet(isPresented: $showCalendar) {
            PulseCalendarSheet()
        }
    }
}

/// The profile photo; opens Settings.
struct PulseAvatarButton: View {
    let action: () -> Void
    @EnvironmentObject private var profile: ProfileStore

    var body: some View {
        Button(action: action) {
            ProfileAvatarView(imageData: profile.avatarImageData, size: 34,
                              fallbackTint: PulseTheme.textSecondary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(PulseTheme.cardRaised))
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(PulseTheme.hairline, lineWidth: 1))
                .frame(width: PulseTheme.minTapTarget, height: PulseTheme.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Profile and settings"))
    }
}

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

/// The centred floating ＋ above the tab bar. It sits inside the tab's own content, whose safe area
/// already ends at the top of the tab bar, so it needs no knowledge of the bar's height on any OS.
struct PulseFloatingPlus: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(PulseTheme.onAccent)
                .frame(width: 56, height: 56)
                .background(Circle().fill(PulseTheme.accent))
                .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
                .contentShape(Circle())
        }
        .buttonStyle(PulsePressStyle())
        .padding(.bottom, 10)
        .accessibilityLabel(String(localized: "Start an activity"))
        .accessibilityHint(String(localized: "Workout, lift, intervals, breathe, journal and more"))
    }
}

// MARK: - Content

/// Everything below the header, rendered from `model.home`.
struct PulseHomeContent: View {
    let onAction: (PulseQuickAction) -> Void
    @Environment(PulseModel.self) private var model

    var body: some View {
        if let home = model.home {
            VStack(spacing: PulseTheme.sectionSpacing) {
                PulseDialsRow(dials: home.dials)
                if let target = home.target {
                    PulseCard { PulseStrainTargetContent(target: target) }
                }
                PulseMyDaySection(home: home, onAction: onAction)
                    .id("pulse.myday")
                PulseKeyStatsSection(stats: home.stats)
                    .id("pulse.stats")
                if let stress = home.stress {
                    PulseStressSection(stress: stress, onBreathe: { onAction(.breathe) })
                        .id("pulse.stress")
                }
                if let journal = home.journal {
                    PulseJournalCard(strip: journal)
                        .id("pulse.journal")
                }
            }
            // While a newly selected day builds, the previous day's numbers dim rather than pass for it.
            .opacity(model.homeIsStale ? 0.45 : 1)
            .animation(.easeOut(duration: 0.15), value: model.homeIsStale)
        } else {
            VStack(spacing: 16) {
                PulseDialsRow(dials: PulseScore.allCases.map {
                    PulseDialData(score: $0, value: nil, state: .noData)
                })
                ProgressView()
                    .tint(PulseTheme.textSecondary)
                    .padding(.top, 8)
            }
        }
    }
}

/// Sleep · Recovery · Strain, each opening its deep dive.
struct PulseDialsRow: View {
    let dials: [PulseDialData]

    var body: some View {
        let reserves = dials.contains { $0.caption != nil }
        HStack(alignment: .top, spacing: 4) {
            ForEach(dials, id: \.score) { dial in
                NavigationLink(value: PulseRoute.score(dial.score)) {
                    PulseDial(data: dial, diameter: 102, reservesCaption: reserves)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens \(dial.score.displayName) details"))
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - My Day

private enum PulseMyDayItem: Identifiable {
    case night(PulseNightSummary, isToday: Bool)
    case nap(PulseNap)
    case workout(PulseWorkoutItem)
    case tonight(PulseTonight)

    var id: String {
        switch self {
        case .night: return "night"
        case .nap(let n): return "nap-\(n.id)"
        case .workout(let w): return "workout-\(w.id)"
        case .tonight: return "tonight"
        }
    }
}

struct PulseMyDaySection: View {
    let home: HomeSnapshot
    let onAction: (PulseQuickAction) -> Void

    private var items: [PulseMyDayItem] {
        var out: [PulseMyDayItem] = []
        if let night = home.lastNight { out.append(.night(night, isToday: home.day.isToday)) }
        out += home.naps.map { .nap($0) }
        out += home.workouts.map { .workout($0) }
        if let tonight = home.tonight { out.append(.tonight(tonight)) }
        return out
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "My Day"))
            PulseCard(padding: 0) {
                VStack(spacing: 0) {
                    let list = items
                    if list.isEmpty {
                        Button { onAction(.menu) } label: {
                            PulseRow(title: String(localized: "Nothing logged yet"),
                                     subtitle: String(localized: "Start an activity or wear your strap to sleep"),
                                     showsChevron: false) {
                                PulseRowIcon(symbol: "plus", tint: PulseTheme.accent)
                            }
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, item in
                        row(item)
                        if index < list.count - 1 { PulseRowDivider() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ item: PulseMyDayItem) -> some View {
        switch item {
        case .night(let night, let isToday):
            NavigationLink(value: PulseRoute.score(.sleep)) {
                PulseRow(title: isToday ? String(localized: "Last night's sleep") : PulseScore.sleep.displayName,
                         subtitle: "\(PulseFormat.clock(night.onset)) – \(PulseFormat.clock(night.wake))",
                         value: PulseFormat.duration(minutes: night.asleepMin),
                         valueCaption: night.performance.map {
                             String(localized: "\(PulseDisplay.displayedPercent($0))% \(PulseScore.sleep.displayName)")
                         }) {
                    PulseRowIcon(symbol: "moon.fill", tint: PulseTheme.sleep)
                }
            }
            .buttonStyle(PulsePressStyle())
        case .nap(let nap):
            NavigationLink(value: PulseRoute.score(.sleep)) {
                PulseRow(title: String(localized: "Nap"),
                         subtitle: "\(PulseFormat.clock(nap.start)) – \(PulseFormat.clock(nap.end))",
                         value: PulseFormat.duration(minutes: nap.asleepMin)) {
                    PulseRowIcon(symbol: "powersleep", tint: PulseTheme.sleep)
                }
            }
            .buttonStyle(PulsePressStyle())
        case .workout(let w):
            NavigationLink(value: PulseRoute.workout(w.route)) {
                PulseRow(title: w.title,
                         subtitle: String(localized: "\(PulseFormat.clock(w.start)) · \(w.durationMin) min"),
                         value: w.strain.map { PulseFormat.oneDecimal($0) },
                         valueCaption: w.strain == nil ? nil : PulseScore.strain.displayName,
                         valueTint: PulseTheme.strain) {
                    WorkoutTypeIcon(workoutType: w.sport, size: 16, color: PulseTheme.strain)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(PulsePressStyle())
        case .tonight(let t):
            NavigationLink(value: PulseRoute.alarms) {
                PulseRow(title: String(localized: "Tonight"),
                         subtitle: tonightSubtitle(t),
                         value: PulseFormat.duration(minutes: t.needMin),
                         valueCaption: String(localized: "sleep need")) {
                    PulseRowIcon(symbol: "bed.double.fill", tint: PulseTheme.sleep)
                }
            }
            .buttonStyle(PulsePressStyle())
        }
    }

    /// Short lines, because they share the row with the need on the right.
    private func tonightSubtitle(_ t: PulseTonight) -> String {
        let wake = PulseFormat.clock(t.wake)
        var lines = [String(localized: "Asleep by \(PulseFormat.clock(t.bedtime))"),
                     // With no alarm and too few nights to learn a habit, say the wake time is assumed.
                     t.wakeSource == .fallback ? String(localized: "Wake \(wake) (default)")
                                               : String(localized: "Wake \(wake)")]
        if t.debtMin >= 5 {
            lines.append(String(localized: "Incl. \(PulseFormat.duration(minutes: t.debtMin)) debt"))
        }
        return lines.joined(separator: "\n")
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

// MARK: - Journal

/// The journal prompt: the last seven days with each logged one filled, today ringed until it is
/// logged. The header opens today's journal; a day's bar opens that day's (the classic card's taps).
struct PulseJournalCard: View {
    let strip: PulseJournalStrip
    @EnvironmentObject private var router: NavRouter

    private var subtitle: String {
        if !strip.todayLogged { return String(localized: "Log today's journal") }
        if strip.hasMissed { return String(localized: "Tap a day to catch up") }
        return String(localized: "Logged today")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "Journal"))
            PulseCard {
                VStack(alignment: .leading, spacing: 12) {
                    Button { router.openJournal() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "book.closed.fill")
                                .font(.body)
                                .foregroundStyle(PulseTheme.accent)
                                .accessibilityHidden(true)
                            Text(subtitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PulseTheme.textPrimary)
                            Spacer(minLength: 8)
                            PulseChevron()
                        }
                        .frame(minHeight: PulseTheme.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityHint(String(localized: "Opens the journal"))

                    HStack(spacing: 6) {
                        ForEach(strip.days) { day in
                            Button { router.openJournal(day: day.offset) } label: {
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(day.logged ? PulseTheme.accent : PulseTheme.track)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                .strokeBorder(day.offset == 0 && !day.logged
                                                              ? PulseTheme.accent : Color.clear, lineWidth: 1)
                                        )
                                        .frame(height: 10)
                                    Text(PulseFormat.dayLabel(day.key, template: "EEEEE"))
                                        .font(.caption2)
                                        .foregroundStyle(day.offset == 0 ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                                }
                                .frame(maxWidth: .infinity, minHeight: PulseTheme.minTapTarget)
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
    }

    private func dayName(_ day: PulseJournalStrip.Day) -> String {
        switch day.offset {
        case 0: return String(localized: "Today")
        case 1: return String(localized: "Yesterday")
        default: return String(localized: "\(day.offset) days ago")
        }
    }
}

// MARK: - Stress

struct PulseStressSection: View {
    let stress: PulseStressSummary
    let onBreathe: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "Stress"),
                               trailing: stress.isToday ? String(localized: "Today") : nil)
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    NavigationLink(value: TabRoute.stress) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(stress.scoreText)
                                .font(PulseTheme.numeral(36))
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text("/ 3")
                                .font(PulseTheme.numeral(16, weight: .semibold))
                                .foregroundStyle(PulseTheme.textTertiary)
                            if let band = stress.bandTitle {
                                PulseChip(text: band.capitalized, tint: PulseTheme.textSecondary)
                                    .padding(.leading, 6)
                            }
                            Spacer(minLength: 0)
                            PulseChevron()
                        }
                        .frame(minHeight: PulseTheme.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "Stress \(stress.scoreText) out of 3\(stress.bandTitle.map { ", \($0.lowercased())" } ?? "")"))
                    .accessibilityHint(String(localized: "Opens Stress"))

                    if stress.hasCurve {
                        DaytimeLoadLine(hours: stress.hours)
                    } else if stress.isToday {
                        Text(String(localized: "The hourly curve fills in as your strap records heart rate through the day."))
                            .font(.caption)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: onBreathe) {
                        PulseActionButtonLabel(title: String(localized: "Breathe"), symbol: "wind")
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
        }
    }
}
#endif
