#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - My Schedule (WHOOP_UI_SPEC §3.11 item 10, help-center/03)
//
// "‹ MY SCHEDULE" with its switch at the top right; with no schedule, a centred CREATE SCHEDULE capsule
// over "Create a schedule to customize your wake time by day of the week."; with one, the week: for each
// day, the time the strap alarm wakes you (that day's own time, else your wake time) and whether the alarm
// buzzes that day. It edits the EXISTING settings and nothing else: per-day times are `WindDownNudge`'s
// per-day wake overrides, which since #1864 move the strap alarm AND the evening wind-down reminder on that
// day; the days are `BehaviorStore.smartAlarmWeekdays`. After each change `AppModel.applySmartAlarm()`
// re-arms the strap and its backup notification, exactly as the classic Alarms screen does.

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

    var body: some View {
        // Decoded once per render: every row reads this one copy.
        let overrides = WindDownNudge.perDayWakeOverrides
        PulseScreenScaffold(title: String(localized: "My schedule")) {
            if scheduleOn {
                VStack(spacing: PulseTheme.Row.listGap) {
                    ForEach(Self.order, id: \.self) { weekday in
                        dayRow(weekday, own: overrides[weekday])
                    }
                }
                Text(footnote)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            } else {
                VStack(spacing: 20) {
                    Button(String(localized: "Create schedule")) { setSchedule(true) }
                        .buttonStyle(PulseButtonStyle(kind: .outlineWhite, fullWidth: false))
                    Text(String(localized: "Create a schedule to customize your wake time by day of the week."))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 28)
            }

            // The evening wind-down reminder and the strap's stored-alarm check live on the classic Alarms
            // screen, which the planner replaced as the alarm entry point: still one tap away.
            PulseLink(.classic(.alarms)) {
                PulseListRow(symbol: "moon.zzz", title: String(localized: "Wind-down reminder"),
                             subtitle: String(localized: "The evening nudge, and what your strap has stored"))
            }
            .buttonStyle(PulsePressStyle())
            .padding(.top, 8)
        }
        // The schedule's switch in the bar's trailing slot (help-center/03).
        .overlay(alignment: .topTrailing) {
            Toggle(String(localized: "My schedule"), isOn: Binding(get: { scheduleOn }, set: { setSchedule($0) }))
                .labelsHidden()
                .tint(PulseTheme.positive)
                .frame(height: PulseTheme.Header.navBar)
                .padding(.top, PulseTheme.Header.navBarTop)
                .padding(.trailing, PulseTheme.Layout.pageMargin)
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

    /// A day: its name and wake time (its own, or your wake time), a reset when it has its own, and whether
    /// the strap alarm buzzes that day (greyed and fixed while the alarm itself is off).
    private func dayRow(_ weekday: Int, own: Int?) -> some View {
        let minutes = own ?? behavior.smartAlarmMinutes
        let alarmOn = behavior.smartAlarmEnabled
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
            .accessibilityHint(String(localized: "Changes this day's wake time"))
            if own != nil {
                Button {
                    WindDownNudge.setWakeOverride(weekday: weekday, minutes: nil)
                    reArm()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .pulseText(.rowSubline)
                        .fontWeight(.semibold)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(width: 36, height: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Use your wake time on \(Self.dayName(weekday))"))
            }
            Toggle(String(localized: "Alarm on \(Self.dayName(weekday))"),
                   isOn: Binding(get: { alarmOn && alarmDay }, set: { _ in toggleAlarmDay(weekday) }))
                .labelsHidden()
                .tint(PulseTheme.positive)
                .disabled(!alarmOn)
                .opacity(alarmOn ? 1 : 0.4)
                .accessibilityHint(alarmOn ? "" : String(localized: "Turn the alarm on in the Sleep Planner first"))
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.listWithSubline)
        .pulseCardBackground(.rowCard)
    }

    private var footnote: String {
        let base = String(localized: "A day's own time moves your strap alarm and the evening wind-down reminder on that day. Days without one use your wake time, \(Self.clock(behavior.smartAlarmMinutes)).")
        guard behavior.smartAlarmEnabled else {
            return base + " " + String(localized: "Your strap alarm is off, so it buzzes on no day until you turn it on.")
        }
        return base + " " + String(localized: "The switch on each day decides whether the strap buzzes then.")
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

    private static let symbolsLock = NSLock()
    private static var weekdaySymbols: (locale: String, names: [String])?

    /// The weekday's full name in the app's language, from symbols made once per language.
    static func dayName(_ weekday: Int) -> String {
        let locale = AppLanguage.activeLocale
        symbolsLock.lock(); defer { symbolsLock.unlock() }
        let names: [String]
        if let cached = weekdaySymbols, cached.locale == locale.identifier {
            names = cached.names
        } else {
            let f = DateFormatter()
            f.locale = locale
            names = f.weekdaySymbols ?? []
            weekdaySymbols = (locale.identifier, names)
        }
        return names.indices.contains(weekday - 1) ? names[weekday - 1] : "\(weekday)"
    }

    /// A minute of the day in the reader's clock ("7:00 AM" / "07:00"), set on the calendar so a
    /// daylight-saving change day reads the same minute.
    static func clock(_ minutes: Int) -> String {
        PulseFormat.clock(PulseSleepTimeSheet.date(minutes: minutes))
    }
}
#endif
