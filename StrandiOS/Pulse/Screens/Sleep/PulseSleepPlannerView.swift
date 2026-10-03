#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Sleep Planner (WHOOP_UI_SPEC §3.11), presented modally ("✕").
///
/// A two-tone page: the upper zone (a lighter slate over the gradient) holds the bar ("✕ · SLEEP PLANNER ? · My
/// Schedule"), ZENO's mark, the headline and "TOMORROW I WANT TO"; its edge, a 1 pt rule, runs behind the
/// goal capsule. Below: the suggested time to bed and the wake time over the TIME IN BED bar, the OPTIMAL
/// window bracketed under it, and the alarm panel pinned at the bottom.
///
/// Every figure comes from ONE resolver (`PulseSleepPlan`), the one Home's TONIGHT'S SLEEP card reads too,
/// for the goal chosen here: the wake is the strap alarm only when it will buzz that morning, else the
/// wind-down wake, else the wake time set here with the alarm off, else (no wake time ever set) the wearer's
/// usual wake, else a typical 07:00 that says so; WAKE TIME SET TO shows that same wake. The panel drives the
/// EXISTING alarm: its toggle and times write `BehaviorStore`'s smart-alarm settings and then call
/// `AppModel.applySmartAlarm()`, exactly as the classic Alarms screen does, so the strap is armed or cleared
/// by the code that always did it (no new commands).
struct PulseSleepPlannerView: View {
    /// Existing entry points (NavRouter `.alarms`, Home's Tonight's Sleep) open this instead of the classic
    /// Alarms screen.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var behavior: BehaviorStore

    @AppStorage(PulseSleepGoal.storageKey) private var goalRaw = PulseSleepGoal.default.storageValue
    // WindDownNudge's keys: declared so that an edit on My Schedule or the classic reminder re-renders the
    // plan. They are read through `PulseSleepPlanSettings.current`, once per render.
    @AppStorage("windDown.perDayWakeMinutes") private var perDayRaw = Data()
    @AppStorage("windDown.enabled") private var windDownOn = false
    @AppStorage("windDown.wakeMinutes") private var windDownWake = TonightSleepPlan.typicalWakeMinute
    /// #34: consecutive times the strap reported a different alarm time than it was sent.
    @AppStorage("alarm.rejectStreak") private var rejectStreak = 0

    @State private var snapshot: SleepPlannerSnapshot?
    @State private var actions = SleepAlarmActions()
    @State private var sheet: PulseSleepPlannerSheet?
    @State private var choosingGoal = false
    #if DEBUG
    @State private var debugApplied = false
    #endif

    private var goal: PulseSleepGoal { PulseSleepGoal(storageValue: goalRaw) }

    var body: some View {
        let settings = PulseSleepPlanSettings.current(behavior: behavior, strapWillArm: actions.strapWillArm())
        // Read through the plan store's observation, so starting, editing or ending a plan re-plans tonight.
        let weeklyPlan = PulseWeeklyPlanSleepGoals.current()
        let plan = snapshot.flatMap { s in
            PulseSleepPlan.resolve(now: Date(), goal: goal, needMin: s.need.totalMin, settings: settings,
                                   recentWakeMinutes: s.recentWakeMinutes, timings: s.timings,
                                   weeklyPlan: weeklyPlan, nightEnded: s.nightEnded)
        }
        ScrollView {
            VStack(spacing: 0) {
                upperZone(plan, scheduleOn: !settings.dayTimes.isEmpty)
                lowerZone(plan, settings: settings)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PulseBackground())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PulseSleepAlarmPanel(plan: plan, alarmOn: settings.alarmEnabled, warning: warning(settings),
                                 onToggle: { setAlarm($0, plan: plan, settings: settings) },
                                 onMode: { sheet = .alarmMode },
                                 onWake: { sheet = .wakeTime })
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(SleepAlarmBridge(actions: $actions))
        .environment(\.colorScheme, .dark)
        .task(id: model.healthKey) {
            if let s = await model.build(dayOffset: 0, { builder, request in await builder.sleepPlanner(request) }) {
                snapshot = s
            }
            #if DEBUG
            applyDebugLaunch()
            #endif
        }
        .sheet(item: $sheet) { which in
            sheetView(which, plan: plan, settings: settings)
        }
        .confirmationDialog(String(localized: "Tomorrow I want to"), isPresented: $choosingGoal,
                            titleVisibility: .visible) {
            ForEach(goalChoices(plan: plan)) { choice in
                Button(choice.choiceTitle) { choose(choice, weeklyPlan: weeklyPlan) }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }

    /// REACH MY SLEEP NEED at 100, 85 and 70%, then IMPROVE MY SLEEP once there are enough recent nights
    /// for a consistency target, then REACH MY WEEKLY PLAN GOAL (§3.11 item 4).
    private func goalChoices(plan: PulseSleepPlan?) -> [PulseSleepGoal] {
        let need = PulseSleepGoal.needPercents.map { PulseSleepGoal.need(percent: $0) }
        return (plan?.optimalBed == nil ? need : need + [.improve]) + [.weeklyPlan]
    }

    /// Keep the choice; REACH MY WEEKLY PLAN GOAL with no plan sleep goal to reach opens Edit Plan instead
    /// (inside this sheet), where a plan with one is started, and leaves the goal as it was.
    private func choose(_ choice: PulseSleepGoal, weeklyPlan: PulseWeeklyPlanSleepGoals?) {
        if choice == .weeklyPlan && weeklyPlan == nil {
            navigator.open(.weeklyPlan(editing: true))
        } else {
            goalRaw = choice.storageValue
        }
    }

    // MARK: Upper zone

    private func upperZone(_ plan: PulseSleepPlan?, scheduleOn: Bool) -> some View {
        VStack(spacing: 0) {
            header(scheduleOn: scheduleOn)
            PulseSleepPlannerMark()
                .padding(.top, 16)
            PulseLoadingGate(isLoading: snapshot == nil) {
                PulseWordWrapHeadline(text: plan.map(headline)
                                      ?? String(localized: "Sleep a few nights with your strap to get a plan for tonight."))
            } skeleton: {
                PulseSkeletonBlock(height: 44, width: 260)
            }
            .padding(.top, 18)
            .padding(.horizontal, 32)
            // The headline floats high in the upper zone: TOMORROW I WANT TO sits ≈276 pt and the capsule's
            // centre ≈311 pt under the bar's centre line on reviews/r134 and r135 alike.
            .frame(minHeight: 131, alignment: .top)
            Text(String(localized: "Tomorrow I want to"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .padding(.top, 49)
                .padding(.bottom, 7 + PulseSleepGoalCapsule.height / 2)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            // The lighter slate of the upper zone, up to its 1 pt edge behind the capsule's centre line.
            VStack(spacing: 0) {
                PulseTheme.Planner.upperZone
                PulseTheme.divider.frame(height: 1)
            }
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            PulseSleepGoalCapsule(title: (plan?.goal ?? goal).title) { choosingGoal = true }
                .alignmentGuide(.bottom) { d in d[VerticalAlignment.center] }
        }
    }

    private func header(scheduleOn: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            PulseCloseButton { dismiss() }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Text(String(localized: "Sleep planner"))
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityAddTraits(.isHeader)
                Button {
                    navigator.open(PulseSleepExplainerRoute(topic: .planner).route)
                } label: {
                    ZStack {
                        Circle().strokeBorder(PulseTheme.textTertiary, lineWidth: 1.2)
                        Text(verbatim: "?")
                            .font(PulseType.font(.chipStrong))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                    .frame(width: 16, height: 16)
                    .frame(width: 30, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "How the plan works"))
            }
            .frame(height: PulseTheme.Layout.minTapTarget)
            .padding(.leading, 30)
            Spacer(minLength: 0)
            scheduleButton(on: scheduleOn)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// My Schedule: a 40 pt outlined circle with a calendar-moon glyph, and the ON / OFF chip under it
    /// (11 pt Bold caps on white 20% in both states, §3.11 item 1 at DR's 11 pt floor).
    private func scheduleButton(on: Bool) -> some View {
        Button {
            navigator.open(PulseSleepScheduleRoute().route)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().strokeBorder(Color.white, lineWidth: 1.5)
                    PulseSleepScheduleGlyph()
                }
                .frame(width: 40, height: 40)
                Text(on ? String(localized: "On") : String(localized: "Off"))
                    .pulseText(.label)
                    .foregroundStyle(on ? PulseTheme.textPrimary : PulseTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                        .fill(PulseTheme.Planner.scheduleChip))
            }
            .padding(.top, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "My schedule"))
        .accessibilityValue(on ? String(localized: "On") : String(localized: "Off"))
    }

    /// The headline (§3.11 item 3).
    private func headline(_ plan: PulseSleepPlan) -> String {
        let bed = PulseFormat.clock(plan.bedtime)
        let wake = PulseFormat.clock(plan.wake)
        if plan.isLate, let left = plan.sleepIfNowMin {
            return String(localized: "It's past your suggested bedtime. Going to bed now still gives you \(PulseFormat.hoursMinutes(left)) of sleep before \(wake).")
        }
        switch plan.goal {
        case .weeklyPlan:
            if plan.alarmFires {
                return String(localized: "Your alarm will go off at \(wake). Get to bed by \(bed) to help you reach your Weekly Plan sleep goals.")
            }
            return String(localized: "Get to bed by \(bed) to help you reach your Weekly Plan sleep goals.")
        case .improve:
            let percent = PulseDisplay.displayedPercent(plan.consistencyPercent ?? 0)
            if Calendar.current.isDate(plan.bedtime, inSameDayAs: Date()) {
                return String(localized: "Go to bed at \(bed) today to achieve a \(percent)% Sleep Consistency tomorrow.")
            }
            return String(localized: "Go to bed at \(bed) tonight to achieve a \(percent)% Sleep Consistency tomorrow.")
        case .need(let share):
            if plan.clamped {
                return String(localized: "Get to bed by \(bed), the earliest ZENO suggests, to reach \(plan.coveragePercent)% of your Sleep Need by \(wake).")
            }
            if plan.alarmFires {
                return String(localized: "Your alarm will go off at \(wake). Get to bed by \(bed) to achieve \(share)% of your Sleep Need.")
            }
            return String(localized: "Get to bed by \(bed) to achieve \(share)% of your Sleep Need by \(wake).")
        }
    }

    // MARK: Lower zone

    private func lowerZone(_ plan: PulseSleepPlan?, settings: PulseSleepPlanSettings) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: PulseSleepGoalCapsule.height / 2)
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let plan {
                    VStack(spacing: 12) {
                        PulseSleepTimeline(plan: plan)
                        PulseSleepAlarmNotes(plan: plan, alarmOn: settings.alarmEnabled,
                                             strapWillArm: settings.strapWillArm)
                    }
                }
            } skeleton: {
                PulseSkeletonBlock(height: 150)
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .padding(.top, 75)
        }
        .padding(.bottom, 24)
    }

    // MARK: The alarm (the existing smart-alarm settings and arming)

    /// What the panel must admit before anything else (§3.11 States): an alarm switched on that the strap
    /// will not keep. The softer notes (the silent buzz, a day it is off) stay under the plan.
    private func warning(_ settings: PulseSleepPlanSettings) -> PulseSleepAlarmPanel.Warning? {
        guard settings.alarmEnabled else { return nil }
        if !settings.strapWillArm { return .notArmed }
        if rejectStreak >= 2 { return .rejected }
        return nil
    }

    /// Switched on while no wake time was ever set, the alarm arms at the wake on screen (the usual or typical
    /// one the plan assumed) rather than at the store's unset 07:00.
    private func setAlarm(_ on: Bool, plan: PulseSleepPlan?, settings: PulseSleepPlanSettings) {
        guard behavior.smartAlarmEnabled != on else { return }
        if on, !settings.wakeTimeStored, let plan, plan.wakeSource == .habit || plan.wakeSource == .typical {
            behavior.smartAlarmMinutes = Self.minuteOfDay(plan.wake)
        }
        behavior.smartAlarmEnabled = on
        actions.apply()
    }

    /// The clock minute of `date`, minutes after midnight.
    private static func minuteOfDay(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// WAKE TIME SET TO edits the alarm's time for the morning the plan is for (that day's own time when
    /// My Schedule sets one, otherwise the alarm's wake time), then sets the alarm through the existing
    /// re-arm ("SAVE & SET ALARM", §3.11 item 9): a wake time is what the alarm wakes you at.
    private func setWake(minutes: Int, plan: PulseSleepPlan?) {
        let m = min(max(minutes, 0), 24 * 60 - 1)
        if let plan, plan.hasDayTime {
            WindDownNudge.setWakeOverride(weekday: plan.weekday, minutes: m)
        } else {
            behavior.smartAlarmMinutes = m
        }
        behavior.smartAlarmEnabled = true
        actions.apply()
    }

    @ViewBuilder
    private func sheetView(_ which: PulseSleepPlannerSheet, plan: PulseSleepPlan?,
                           settings: PulseSleepPlanSettings) -> some View {
        switch which {
        case .alarmMode:
            PulseSleepAlarmModeSheet(alarmOn: settings.alarmEnabled) { on in
                setAlarm(on, plan: plan, settings: settings)
                sheet = nil
            }
        case .wakeTime:
            // Opens on the wake the page shows.
            let minutes = plan.map { Self.minuteOfDay($0.wake) } ?? settings.alarmMinutes
            PulseSleepTimeSheet(title: String(localized: "Wake time"), minutes: minutes,
                                confirmTitle: String(localized: "Save & set alarm"),
                                onConfirm: { minutes in
                                    setWake(minutes: minutes, plan: plan)
                                    sheet = nil
                                },
                                onCancel: { sheet = nil })
        }
    }

    #if DEBUG
    private func applyDebugLaunch() {
        guard !debugApplied else { return }
        debugApplied = true
        // `--jp-plan <template>`: a running Weekly Plan, for REACH MY WEEKLY PLAN GOAL captures.
        JournalPlanDebug.startPlanIfRequested()
        if PulseSleepDebug.showsSchedule { navigator.open(PulseSleepScheduleRoute().route) }
        switch PulseSleepDebug.sheet {
        case "goal": choosingGoal = true
        case "alarm": sheet = .alarmMode
        case "wake": sheet = .wakeTime
        default: break
        }
    }
    #endif
}

/// The planner's sheets.
enum PulseSleepPlannerSheet: String, Identifiable {
    case alarmMode, wakeTime
    var id: String { rawValue }
}

// MARK: - The alarm's existing actions, without observing AppModel

/// `AppModel.applySmartAlarm()` and the 5/MG arming gate, captured once. `AppModel` publishes the live heart
/// rate, so a view that observed it would re-render every beat; only the invisible bridge below observes it.
struct SleepAlarmActions {
    var apply: () -> Void = {}
    /// Whether the strap arms its firmware alarm (`BLEManager.strapAlarmWillArm`: a WHOOP 5/MG only with
    /// Protocol probes on).
    var strapWillArm: () -> Bool = { true }
}

struct SleepAlarmBridge: View {
    @Binding var actions: SleepAlarmActions
    @EnvironmentObject private var app: AppModel

    var body: some View {
        Color.clear
            .onAppear {
                let model = app
                actions = SleepAlarmActions(apply: { [weak model] in model?.applySmartAlarm() },
                                            strapWillArm: { [weak model] in model?.ble.strapAlarmWillArm ?? true })
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Pieces

/// ZENO's mark in a 36 pt outlined circle (§3.11 item 2).
struct PulseSleepPlannerMark: View {
    var body: some View {
        ZStack {
            Circle().strokeBorder(Color.white, lineWidth: 1.5)
            PulseZenoMonogramShape()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: 14, height: 14)
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }
}

/// My Schedule's glyph: a calendar page with a crescent moon in it (ZENO's own drawing).
struct PulseSleepScheduleGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PulseTheme.Planner.glyphRadius, style: .continuous)
                .strokeBorder(Color.white, lineWidth: 1.4)
                .frame(width: 18, height: 16)
                .offset(y: 1)
            Rectangle()
                .fill(Color.white)
                .frame(width: 17, height: 1.4)
                .offset(y: -3)
            HStack(spacing: 7) {
                Capsule().fill(Color.white).frame(width: 1.6, height: 4.5)
                Capsule().fill(Color.white).frame(width: 1.6, height: 4.5)
            }
            .offset(y: -7.5)
            PulseSleepCrescent()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .offset(x: 1.5, y: 3.5)
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}

/// A crescent moon drawn as a shape, so the glyph keeps its size at every text size.
struct PulseSleepCrescent: Shape {
    func path(in rect: CGRect) -> Path {
        var outer = Path(ellipseIn: rect)
        let bite = Path(ellipseIn: rect.offsetBy(dx: rect.width * 0.38, dy: -rect.height * 0.22))
        outer = outer.subtracting(bite)
        return outer
    }
}

/// The centred headline (≈17 pt Medium, two lines on reviews/r134), never split inside a word.
struct PulseWordWrapHeadline: View {
    let text: String

    var body: some View {
        Text(text)
            .pulseText(.trendInsight)
            .fontWeight(.medium)
            .lineSpacing(4)
            .foregroundStyle(PulseTheme.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

/// The goal capsule: a white 1.5 pt outline 36 pt tall around 11 pt Bold caps (reviews/r134, r135).
struct PulseSleepGoalCapsule: View {
    static let height: CGFloat = 36
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .pulseText(.buttonLabel)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 18)
                .frame(minWidth: 112, minHeight: Self.height)
                .background(Capsule(style: .circular).fill(PulseTheme.Planner.capsuleFill))
                .overlay(Capsule(style: .circular).strokeBorder(Color.white, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(PulsePressStyle())
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel(String(localized: "Tomorrow I want to \(title)"))
        .accessibilityHint(String(localized: "Changes the goal"))
    }
}
#endif
