#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Sleep Planner (WHOOP_UI_SPEC §3.11), presented as a modal sheet ("✕").
///
/// A two-tone page: the upper zone (white 6% over the gradient) holds the bar ("✕ · SLEEP PLANNER ? · My
/// Schedule"), ZENO's mark, the headline and "TOMORROW I WANT TO"; its edge, a 1 pt rule, runs behind the
/// goal capsule. Below: the suggested time to bed and the wake time over the TIME IN BED bar, the OPTIMAL
/// window bracketed under it, and the alarm panel pinned at the bottom.
///
/// Every figure comes from ONE resolver (`PulseSleepPlan`): the wake time is the strap alarm's next wake
/// (its per-day override included) through the same `AppModel.nextSmartAlarmDate` the strap is armed from,
/// the bedtime is `SleepNeed.suggestedBedtime` for the chosen share of tonight's need. The panel drives the
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

    @AppStorage("pulse.sleepPlanner.goal") private var goalRaw = PulseSleepGoal.peak.rawValue
    /// The per-day wake times (WindDownNudge's key): declared so an edit on My Schedule re-renders the plan.
    @AppStorage("windDown.perDayWakeMinutes") private var perDayRaw = Data()
    /// #34: consecutive times the strap reported a different alarm time than it was sent.
    @AppStorage("alarm.rejectStreak") private var rejectStreak = 0

    @State private var snapshot: SleepPlannerSnapshot?
    @State private var actions = SleepAlarmActions()
    @State private var sheet: PulseSleepPlannerSheet?
    #if DEBUG
    @State private var debugApplied = false
    #endif

    private var goal: PulseSleepGoal { PulseSleepGoal(rawValue: goalRaw) ?? .peak }

    private func plan(now: Date) -> PulseSleepPlan? {
        guard let snapshot else { return nil }
        return PulseSleepPlan.resolve(now: now, goal: goal, needMin: snapshot.need.totalMin,
                                      alarmEnabled: behavior.smartAlarmEnabled,
                                      alarmMinutes: behavior.smartAlarmMinutes,
                                      alarmWeekdays: behavior.smartAlarmWeekdays,
                                      overrides: WindDownNudge.perDayWakeOverrides,
                                      strapWillArm: actions.strapWillArm(), timings: snapshot.timings)
    }

    var body: some View {
        let plan = plan(now: Date())
        ScrollView {
            VStack(spacing: 0) {
                upperZone(plan)
                lowerZone(plan)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(PulseBackground())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PulseSleepAlarmPanel(plan: plan, alarmOn: behavior.smartAlarmEnabled, rejectStreak: rejectStreak,
                                 strapWillArm: actions.strapWillArm(),
                                 onToggle: { setAlarm($0) },
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
            sheetView(which, plan: plan)
        }
    }

    // MARK: Upper zone

    private func upperZone(_ plan: PulseSleepPlan?) -> some View {
        VStack(spacing: 0) {
            header
            PulseSleepPlannerMark()
                .padding(.top, 12)
            Group {
                if let plan {
                    PulseWordWrapHeadline(text: headline(plan))
                } else if snapshot != nil {
                    PulseWordWrapHeadline(text: String(localized: "Sleep a few nights with your strap to get a plan for tonight."))
                } else {
                    PulseSkeletonBlock(height: 56, width: 260)
                }
            }
            .padding(.top, 14)
            .padding(.horizontal, 32)
            // WHOOP's upper zone runs to ≈42% of the screen, the headline floating high in it (reviews/r134).
            .frame(minHeight: 112, alignment: .top)
            Text(String(localized: "Tomorrow I want to"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .padding(.top, 44)
                .padding(.bottom, 8 + PulseSleepGoalCapsule.height / 2)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            // The lighter slate of the upper zone, up to its 1 pt edge behind the capsule's centre line.
            VStack(spacing: 0) {
                PulseTheme.Planner.upperZone
                PulseTheme.divider.frame(height: 1)
            }
            .padding(.bottom, PulseSleepGoalCapsule.height / 2)
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            PulseSleepGoalCapsule(title: goal.title) { sheet = .goal }
                .alignmentGuide(.bottom) { d in d[VerticalAlignment.center] }
        }
    }

    private var header: some View {
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
                            .font(.system(size: 11, weight: .bold))
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
            scheduleButton
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    /// My Schedule: a 40 pt outlined circle with a calendar-moon glyph, and the ON / OFF chip under it.
    private var scheduleButton: some View {
        let on = !WindDownNudge.perDayWakeOverrides.isEmpty
        return Button {
            navigator.open(PulseSleepScheduleRoute().route)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle().strokeBorder(Color.white, lineWidth: 1.5)
                    PulseSleepScheduleGlyph()
                }
                .frame(width: 40, height: 40)
                Text(on ? String(localized: "On") : String(localized: "Off"))
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(on ? Color.black : PulseTheme.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                        .fill(on ? PulseTheme.positive : PulseTheme.tagFill))
            }
            .padding(.top, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "My schedule"))
        .accessibilityValue(on ? String(localized: "On") : String(localized: "Off"))
    }

    /// The headline (§3.11 item 3), 20 pt Semibold, at most three lines.
    private func headline(_ plan: PulseSleepPlan) -> String {
        let bed = PulseFormat.clock(plan.bedtime)
        let wake = PulseFormat.clock(plan.wake)
        if plan.isLate, let left = plan.sleepIfNowMin {
            return String(localized: "It's past your suggested bedtime. Going to bed now still gives you \(PulseFormat.hoursMinutes(left)) of sleep before \(wake).")
        }
        if plan.clamped {
            return String(localized: "Get to bed by \(bed), the earliest ZENO suggests, to reach \(plan.coveragePercent)% of your Sleep Need by \(wake).")
        }
        if plan.alarmFires {
            return String(localized: "Your alarm will go off at \(wake). Get to bed by \(bed) to achieve \(goal.percent)% of your Sleep Need.")
        }
        return String(localized: "Get to bed by \(bed) to achieve \(goal.percent)% of your Sleep Need by \(wake).")
    }

    // MARK: Lower zone

    private func lowerZone(_ plan: PulseSleepPlan?) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: PulseSleepGoalCapsule.height / 2)
            if let plan {
                PulseSleepTimeline(plan: plan)
                    .padding(.top, 60)
            } else {
                PulseSkeletonBlock(height: 150)
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.top, 60)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: The alarm (the existing smart-alarm settings and arming)

    private func setAlarm(_ on: Bool) {
        guard behavior.smartAlarmEnabled != on else { return }
        behavior.smartAlarmEnabled = on
        actions.apply()
    }

    /// The weekday of the wake the plan is for, and whether that day has a time of its own on My Schedule.
    private func wakeDay(_ plan: PulseSleepPlan?) -> (weekday: Int, own: Int?)? {
        guard let plan else { return nil }
        let weekday = Calendar.current.component(.weekday, from: plan.wake)
        return (weekday, WindDownNudge.perDayWakeOverrides[weekday])
    }

    /// WAKE TIME SET TO edits the time the tile shows: that day's own time when My Schedule sets one,
    /// otherwise the alarm's wake time. Then the existing re-arm runs.
    private func setWake(minutes: Int, plan: PulseSleepPlan?) {
        let m = min(max(minutes, 0), 24 * 60 - 1)
        if let day = wakeDay(plan), day.own != nil {
            WindDownNudge.setWakeOverride(weekday: day.weekday, minutes: m)
        } else {
            behavior.smartAlarmMinutes = m
        }
        // Re-arm only an alarm that is on: with it off there is nothing on the strap to move, and the
        // re-arm would send the strap a disarm it does not need.
        if behavior.smartAlarmEnabled { actions.apply() }
    }

    @ViewBuilder
    private func sheetView(_ which: PulseSleepPlannerSheet, plan: PulseSleepPlan?) -> some View {
        switch which {
        case .goal:
            PulseSleepGoalSheet(selection: goal) { picked in
                goalRaw = picked.rawValue
                sheet = nil
            }
        case .alarmMode:
            PulseSleepAlarmModeSheet(alarmOn: behavior.smartAlarmEnabled) { on in
                setAlarm(on)
                sheet = nil
            }
        case .wakeTime:
            PulseSleepTimeSheet(title: String(localized: "Wake time"),
                                minutes: wakeDay(plan)?.own ?? behavior.smartAlarmMinutes,
                                confirmTitle: behavior.smartAlarmEnabled ? String(localized: "Save & set alarm")
                                                                         : String(localized: "Save"),
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
        if PulseSleepDebug.showsSchedule { navigator.open(PulseSleepScheduleRoute().route) }
        switch PulseSleepDebug.sheet {
        case "goal": sheet = .goal
        case "alarm": sheet = .alarmMode
        case "wake": sheet = .wakeTime
        default: break
        }
    }
    #endif
}

/// The planner's sheets.
enum PulseSleepPlannerSheet: String, Identifiable {
    case goal, alarmMode, wakeTime
    var id: String { rawValue }
}

// MARK: - The alarm's existing actions, without observing AppModel

/// `AppModel.applySmartAlarm()` and the 5/MG arming gate, captured once. `AppModel` publishes the live heart
/// rate, so a view that observed it would re-render every beat; only the invisible bridge below observes it.
struct SleepAlarmActions {
    var apply: () -> Void = {}
    /// A WHOOP 5/MG arms its firmware alarm only with Protocol probes on (`BLEManager.armStrapAlarm`).
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
                                            strapWillArm: { [weak model] in
                                                !((model?.whoop5Detected ?? false) && !PuffinExperiment.isEnabled)
                                            })
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
            RoundedRectangle(cornerRadius: 3, style: .continuous)
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
            Image(systemName: "moon.fill")
                .font(.system(size: 7.5, weight: .semibold))
                .foregroundStyle(Color.white)
                .offset(x: 1.5, y: 3.5)
        }
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)
    }
}

/// The centred 20 pt Semibold headline, never split inside a word.
struct PulseWordWrapHeadline: View {
    let text: String

    var body: some View {
        Text(text)
            .pulseText(.cardHeadline)
            .foregroundStyle(PulseTheme.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(4)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }
}

/// The goal capsule: a white 1.5 pt outline (h 44), 12 pt Bold caps.
struct PulseSleepGoalCapsule: View {
    static let height: CGFloat = 44
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 26)
                .frame(minWidth: 132, minHeight: Self.height)
                .background(Capsule(style: .circular).fill(PulseTheme.Planner.capsuleFill))
                .overlay(Capsule(style: .circular).strokeBorder(Color.white, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Tomorrow I want to \(title)"))
        .accessibilityHint(String(localized: "Changes the goal"))
    }
}
#endif
