#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - My Schedule (WHOOP_UI_SPEC §3.11 item 10)
//
// The week behind the Sleep Planner's wake time: for each day, the time the strap alarm wakes you (that
// day's own time when the schedule sets one, else your wake time) and whether the alarm buzzes that day.
// It edits the EXISTING settings and nothing else: per-day times are `WindDownNudge`'s per-day wake
// overrides, which since #1864 move the strap alarm AND the evening wind-down reminder on that day; the
// days are `BehaviorStore.smartAlarmWeekdays`. After each change `AppModel.applySmartAlarm()` re-arms the
// strap and its backup notification, exactly as the classic Alarms screen does.

/// My Schedule, pushed inside the planner's modal.
struct PulseSleepScheduleRoute: PulseScreenRoute {
    var view: some View { PulseSleepScheduleView() }
}

/// One weekday being edited (the time sheet's identity).
private struct SleepScheduleEdit: Identifiable {
    let weekday: Int
    var id: Int { weekday }
}

struct PulseSleepScheduleView: View {
    @EnvironmentObject private var behavior: BehaviorStore
    /// WindDownNudge's per-day times: declared so each edit re-renders the rows.
    @AppStorage("windDown.perDayWakeMinutes") private var perDayRaw = Data()

    @State private var scheduleOn = WindDownNudge.hasPerDayOverrides
    @State private var actions = SleepAlarmActions()
    @State private var editing: SleepScheduleEdit?

    /// Monday first (Calendar weekdays 2…7, then 1).
    private static let order = [2, 3, 4, 5, 6, 7, 1]

    private var overrides: [Int: Int] { WindDownNudge.perDayWakeOverrides }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "My schedule")) {
            PulseListRow(title: String(localized: "Wake time by day"),
                         subtitle: String(localized: "Set a different wake time for some days."),
                         trailing: .toggle(Binding(get: { scheduleOn }, set: { setSchedule($0) })))

            if !scheduleOn {
                VStack(spacing: 16) {
                    Text(String(localized: "Create a schedule to customize your wake time by day of the week."))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(String(localized: "Create schedule")) { setSchedule(true) }
                        .buttonStyle(.pulseOutlineWhite)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }

            VStack(spacing: PulseTheme.Row.listGap) {
                ForEach(Self.order, id: \.self) { weekday in
                    dayRow(weekday)
                }
            }

            Text(footnote)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)

            // The evening wind-down reminder and the strap's stored-alarm check live on the classic Alarms
            // screen, which the planner replaced as the alarm entry point: still one tap away.
            PulseLink(.classic(.alarms)) {
                PulseListRow(symbol: "moon.zzz", title: String(localized: "Wind-down reminder"),
                             subtitle: String(localized: "The evening nudge, and what your strap has stored"))
            }
            .buttonStyle(PulsePressStyle())
            .padding(.top, 8)
        }
        .background(SleepAlarmBridge(actions: $actions))
        .sheet(item: $editing) { edit in
            PulseSleepTimeSheet(title: Self.dayName(edit.weekday),
                                minutes: overrides[edit.weekday] ?? behavior.smartAlarmMinutes,
                                confirmTitle: String(localized: "Save"),
                                onConfirm: { minutes in
                                    WindDownNudge.setWakeOverride(weekday: edit.weekday, minutes: minutes)
                                    reArm()
                                    editing = nil
                                },
                                onCancel: { editing = nil })
        }
    }

    /// A day: its name and wake time (its own, or the base time "by default"), a reset when it has its own,
    /// and whether the strap alarm buzzes that day.
    private func dayRow(_ weekday: Int) -> some View {
        let own = overrides[weekday]
        let minutes = own ?? behavior.smartAlarmMinutes
        let alarmDay = SmartAlarmView.alarmWeekdayIsSelected(weekday, in: behavior.smartAlarmWeekdays)
        return HStack(spacing: 12) {
            Button {
                editing = SleepScheduleEdit(weekday: weekday)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Self.dayName(weekday))
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(own == nil ? String(localized: "\(Self.clock(minutes)) · your wake time")
                                    : Self.clock(minutes))
                        .pulseText(.rowSubline)
                        .foregroundStyle(own == nil ? PulseTheme.rowSubline : PulseTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(!scheduleOn)
            .accessibilityHint(scheduleOn ? String(localized: "Changes this day's wake time") : "")
            if own != nil {
                Button {
                    WindDownNudge.setWakeOverride(weekday: weekday, minutes: nil)
                    reArm()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(width: 36, height: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Use your wake time on \(Self.dayName(weekday))"))
            }
            Toggle(String(localized: "Alarm on \(Self.dayName(weekday))"),
                   isOn: Binding(get: { alarmDay }, set: { _ in toggleAlarmDay(weekday) }))
                .labelsHidden()
                .tint(PulseTheme.positive)
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.listWithSubline)
        .pulseCardBackground(.rowCard)
        .opacity(scheduleOn || own != nil ? 1 : 0.85)
    }

    private var footnote: String {
        String(localized: "A day's own time moves your strap alarm and the evening wind-down reminder on that day. Days without one use your wake time, \(Self.clock(behavior.smartAlarmMinutes)). The switch on each day decides whether the strap buzzes then.")
    }

    // MARK: Actions (the existing settings, then the existing re-arm)

    /// Turning the schedule off clears every day's own time, as the classic Alarms screen does, so the
    /// alarm and the reminder go back to the one wake time; turning it on creates nothing until a day is set.
    private func setSchedule(_ on: Bool) {
        scheduleOn = on
        guard !on else { return }
        for weekday in 1...7 { WindDownNudge.setWakeOverride(weekday: weekday, minutes: nil) }
        reArm()
    }

    private func toggleAlarmDay(_ weekday: Int) {
        behavior.smartAlarmWeekdays = SmartAlarmView.alarmToggledWeekday(weekday, in: behavior.smartAlarmWeekdays)
        reArm()
    }

    /// The existing re-arm (`AppModel.applySmartAlarm`), for an alarm that is on: with it off there is
    /// nothing on the strap to move. The wind-down reminder reschedules itself inside `WindDownNudge`.
    private func reArm() {
        if behavior.smartAlarmEnabled { actions.apply() }
    }

    // MARK: Formatting

    static func dayName(_ weekday: Int) -> String {
        let f = DateFormatter()
        f.locale = AppLanguage.activeLocale
        let names = f.weekdaySymbols ?? []
        return names.indices.contains(weekday - 1) ? names[weekday - 1] : "\(weekday)"
    }

    /// A minute of the day in the reader's clock ("7:00 AM" / "07:00").
    static func clock(_ minutes: Int) -> String {
        let base = Calendar.current.startOfDay(for: Date())
        return PulseFormat.clock(base.addingTimeInterval(TimeInterval(minutes * 60)))
    }
}
#endif
