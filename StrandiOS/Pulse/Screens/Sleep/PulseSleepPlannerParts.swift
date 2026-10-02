#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - The planner's lower zone (WHOOP_UI_SPEC §3.11 items 5–7)

/// The suggested time to bed and the wake time over the TIME IN BED bar, with dashed drop lines to its
/// ticks, the time in bed in a black capsule at its centre, the alarm pin on the wake tick while the alarm
/// is set for that morning, and the OPTIMAL window bracketed under the bar on the same time scale (clipped
/// at the screen edge when it runs past it, as WHOOP's does).
struct PulseSleepTimeline: View {
    let plan: PulseSleepPlan

    /// The bar's ends as fractions of the content width: 17% and 84% of the SCREEN on reviews/r134 and
    /// help-center/86, inside the 16 pt margins.
    private static let bedFraction: CGFloat = 0.14
    private static let wakeFraction: CGFloat = 0.865
    /// The two times sit this far toward the centre from their ticks (both references: 15–17 pt).
    private static let timeInset: CGFloat = 16

    private let timesHeight: CGFloat = 78
    private let barTop: CGFloat = 118
    private let barHeight: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let bedX = w * Self.bedFraction
            let wakeX = w * Self.wakeFraction
            ZStack(alignment: .topLeading) {
                // The two times, centred over their ticks but kept inside the margins.
                timeBlock(plan.bedtime, caption: String(localized: "Suggested time to bed"))
                    .frame(width: 150)
                    .position(x: min(max(bedX + Self.timeInset, 75), w - 75), y: timesHeight / 2)
                timeBlock(plan.wake, caption: String(localized: "Your wake time"))
                    .frame(width: 150)
                    .position(x: min(max(wakeX - Self.timeInset, 75), w - 75), y: timesHeight / 2)

                dropLine(x: bedX, from: timesHeight + 4, to: barTop)
                dropLine(x: wakeX, from: timesHeight + 4, to: plan.alarmFires ? barTop - 30 : barTop)

                Text(String(localized: "Time in bed"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .position(x: w / 2, y: barTop - 14)

                // The bar: a faint strip across the screen, hatched between the ticks.
                PulseTheme.Planner.barStrip
                    .frame(width: w + 2 * PulseTheme.Layout.pageMargin, height: barHeight)
                    .position(x: w / 2, y: barTop + barHeight / 2)
                PulseHatchedTrack(color: PulseTheme.Planner.barHatch, spacing: 5, cornerRadius: 0)
                    .frame(width: max(0, wakeX - bedX), height: barHeight - 2)
                    .position(x: (bedX + wakeX) / 2, y: barTop + barHeight / 2)
                tick(x: bedX)
                tick(x: wakeX)
                Text(PulseFormat.hoursMinutes(plan.timeInBedMin))
                    .font(PulseType.font(.rowValue))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule(style: .circular).fill(PulseTheme.Planner.timeCapsule))
                    .overlay(Capsule(style: .circular).strokeBorder(Color.white, lineWidth: 1.5))
                    .fixedSize()
                    .position(x: (bedX + wakeX) / 2, y: barTop + barHeight / 2)
                    .accessibilityLabel(String(localized: "Time in bed \(PulseFormat.duration(minutes: plan.timeInBedMin))"))

                if plan.alarmFires {
                    PulseSleepAlarmPin()
                        .position(x: wakeX, y: barTop - 16)
                }

                if let bed = plan.optimalBed, let wake = plan.optimalWake {
                    optimalBracket(bed: bed, wake: wake, bedX: bedX, wakeX: wakeX, width: w)
                }
            }
        }
        .frame(height: barTop + barHeight + 86)
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityElement(children: .contain)
    }

    /// "10:25PM" (32 pt, the AM / PM 15 pt) over its two-line caption.
    private func timeBlock(_ date: Date, caption: String) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(PulseFormat.clockNoMeridiem(date))
                    .font(PulseType.font(.plannerTime))
                if let meridiem = Self.meridiem(date) {
                    Text(meridiem)
                        .font(PulseType.numeral(15))
                }
            }
            .foregroundStyle(PulseTheme.textPrimary)
            PulseWordWrapText(caption, style: .label, alignment: .center)
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(maxWidth: 120)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption), \(PulseFormat.clock(date))")
    }

    private func dropLine(x: CGFloat, from top: CGFloat, to bottom: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: x, y: top))
            p.addLine(to: CGPoint(x: x, y: bottom))
        }
        .stroke(PulseTheme.Planner.dropLine, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        .accessibilityHidden(true)
    }

    private func tick(x: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 2, height: barHeight + 6)
            .position(x: x, y: barTop + barHeight / 2)
            .accessibilityHidden(true)
    }

    /// The OPTIMAL window: a dashed rounded bracket under the bar between its two times, "OPTIMAL" set into
    /// its bottom line (the dashes stop either side of it) and the window's times under that.
    private func optimalBracket(bed: Date, wake: Date, bedX: CGFloat, wakeX: CGFloat, width: CGFloat) -> some View {
        let span = max(plan.wake.timeIntervalSince(plan.bedtime), 60)
        func x(_ d: Date) -> CGFloat {
            bedX + CGFloat(d.timeIntervalSince(plan.bedtime) / span) * (wakeX - bedX)
        }
        let left = x(bed)
        let right = x(wake)
        // The bracket's sides drop ≈40 pt under the bar (reviews/r134, help-center/86).
        let top = barTop + barHeight + 6
        let bottom = top + 34
        // The label sits centred on the part of the bracket that is on screen.
        let visibleLeft = max(left, -PulseTheme.Layout.pageMargin)
        let visibleRight = min(right, width + PulseTheme.Layout.pageMargin)
        let labelX = min(max((visibleLeft + visibleRight) / 2, 70), width - 70)
        let title = String(localized: "Optimal")
        let gap = PulseTextMetrics.width(title, style: .label) / 2 + 8
        return ZStack(alignment: .topLeading) {
            Path { p in
                let r: CGFloat = 6
                p.move(to: CGPoint(x: left, y: top))
                p.addLine(to: CGPoint(x: left, y: bottom - r))
                p.addQuadCurve(to: CGPoint(x: left + r, y: bottom), control: CGPoint(x: left, y: bottom))
                p.addLine(to: CGPoint(x: max(left + r, labelX - gap), y: bottom))
                p.move(to: CGPoint(x: min(right - r, labelX + gap), y: bottom))
                p.addLine(to: CGPoint(x: right - r, y: bottom))
                p.addQuadCurve(to: CGPoint(x: right, y: bottom - r), control: CGPoint(x: right, y: bottom))
                p.addLine(to: CGPoint(x: right, y: top))
            }
            .stroke(PulseTheme.Planner.dropLine, style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.Planner.optimalLabel)
                .fixedSize()
                .position(x: labelX, y: bottom)
            Text("\(PulseFormat.clock(bed)) – \(PulseFormat.clock(wake))")
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize()
                .position(x: labelX, y: bottom + 17)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Optimal \(PulseFormat.clock(bed)) to \(PulseFormat.clock(wake))"))
    }

    /// "PM" / "AM" in the reader's clock, or nil on a 24-hour clock.
    static func meridiem(_ date: Date) -> String? {
        guard !AppClock.uses24Hour else { return nil }
        let f = DateFormatter()
        f.locale = AppClock.formattingLocale
        f.dateFormat = "a"
        return f.string(from: date)
    }
}

/// The alarm pin on the wake tick: a white drop holding the strap-vibrate glyph (reviews/r136).
struct PulseSleepAlarmPin: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 24, height: 24)
            PulseSleepPinTail().fill(Color.white).frame(width: 10, height: 8).offset(y: 14)
            PulseStrapVibrateGlyph(height: 14).foregroundStyle(Color.black)
        }
        .accessibilityLabel(String(localized: "Alarm set"))
    }
}

private struct PulseSleepPinTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - The alarm panel (§3.11 item 8)

/// The panel pinned at the bottom: the strap-vibrate glyph, ALARM and its switch (teal when on), then
/// ALARM SET TO and WAKE TIME SET TO, and the honest notes that say when the alarm will not do what it says.
struct PulseSleepAlarmPanel: View {
    let plan: PulseSleepPlan?
    let alarmOn: Bool
    let rejectStreak: Int
    let strapWillArm: Bool
    let onToggle: (Bool) -> Void
    let onMode: () -> Void
    let onWake: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                PulseStrapVibrateGlyph(height: 22)
                    .foregroundStyle(alarmOn ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                    .frame(width: 60, alignment: .leading)
                Spacer(minLength: 8)
                Text(String(localized: "Alarm"))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer(minLength: 8)
                Toggle(String(localized: "Alarm"), isOn: Binding(get: { alarmOn }, set: { onToggle($0) }))
                    .labelsHidden()
                    .tint(PulseTheme.positive)
                    .frame(width: 60, alignment: .trailing)
            }
            .frame(minHeight: PulseTheme.Layout.minTapTarget)
            PulseButtonRow {
                tile(title: String(localized: "Alarm set to"),
                     value: alarmOn ? String(localized: "Exact time") : String(localized: "Off"), action: onMode)
                tile(title: String(localized: "Wake time set to"),
                     value: plan.map { PulseFormat.clock($0.wake) } ?? "--", action: onWake)
            }
            if let note {
                Text(note)
                    .pulseText(.rowSubline)
                    .foregroundStyle(noteIsWarning ? PulseTheme.negative : PulseTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
            PulseSleepStrapNotice()
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: PulseTheme.Planner.panelRadius,
                                   topTrailingRadius: PulseTheme.Planner.panelRadius, style: .continuous)
                .fill(LinearGradient(colors: [PulseTheme.Planner.panelTop, PulseTheme.Planner.panelBottom],
                                     startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea(edges: .bottom))
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    /// What the panel must admit, most important first.
    private var note: String? {
        guard alarmOn else { return nil }
        if !strapWillArm {
            return String(localized: "WHOOP 5/MG strap alarms need Protocol probes (Test Centre). Your wake time is saved, but the strap is not armed.")
        }
        if rejectStreak >= 2 {
            return String(localized: "Your strap keeps reporting a different alarm time, so it may not buzz. Keep a phone alarm until it takes.")
        }
        if let plan, !plan.alarmFires {
            let day = plan.wake.formatted(.dateTime.weekday(.wide).locale(AppLanguage.activeLocale))
            return String(localized: "Your alarm is off on \(day).")
        }
        return String(localized: "A silent buzz from your strap. Keep a phone alarm as a backup.")
    }

    private var noteIsWarning: Bool { !strapWillArm || rejectStreak >= 2 }

    private func tile(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(value)
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .fill(PulseTheme.Planner.tileFill))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .strokeBorder(PulseTheme.Planner.tileBorder, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
    }
}

/// "Strap battery under 20%" (§3.11 "States"): the only view in the planner that observes LiveState, so a
/// heart-rate tick re-renders this line and nothing else.
struct PulseSleepStrapNotice: View {
    @EnvironmentObject private var live: LiveState

    var body: some View {
        if live.activeIsWhoop, let pct = live.batteryPct, pct < 20, live.charging != true {
            Label {
                Text(String(localized: "Strap battery \(Int(pct.rounded()))%. Charge it before bed so the alarm can buzz."))
            } icon: {
                Image(systemName: "battery.25")
            }
            .pulseText(.rowSubline)
            .foregroundStyle(PulseTheme.negative)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Sheets

/// "TOMORROW I WANT TO": Peak, Perform or Get By, each with its share of tonight's need.
struct PulseSleepGoalSheet: View {
    let selection: PulseSleepGoal
    let onPick: (PulseSleepGoal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Tomorrow I want to"))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 24)
                .padding(.bottom, 6)
                .accessibilityAddTraits(.isHeader)
            ForEach(PulseSleepGoal.allCases) { goal in
                Button { onPick(goal) } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(goal.title)
                                .pulseText(.cardTitle)
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text(String(localized: "\(goal.percent)% of your sleep need"))
                                .pulseText(.rowSubline)
                                .foregroundStyle(PulseTheme.textSecondary)
                        }
                        Spacer(minLength: 8)
                        if goal == selection {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(PulseTheme.positive)
                        }
                    }
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.listWithSubline, alignment: .leading)
                    .pulseCardBackground(.rowCard)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityAddTraits(goal == selection ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PulseTheme.wheelSheet.ignoresSafeArea())
        .presentationDetents([.height(340), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(PulseTheme.Radius.menu)
        .environment(\.colorScheme, .dark)
    }
}

/// ALARM SET TO: Exact Time (the strap's silent buzz at the wake time) or Off. Sleep Goal and In the Green
/// need a phone watching the night for a light-sleep moment, which ZENO has on Android only, so they are
/// shown and unavailable rather than offered and broken (§3.11 item 9).
struct PulseSleepAlarmModeSheet: View {
    let alarmOn: Bool
    let onPick: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Alarm set to"))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 24)
                .padding(.bottom, 6)
                .accessibilityAddTraits(.isHeader)
            row(String(localized: "Exact time"),
                String(localized: "Your strap buzzes at your wake time, even if your phone is asleep or ZENO is closed."),
                selected: alarmOn, enabled: true) { onPick(true) }
            row(String(localized: "Off"), String(localized: "No alarm. The plan still uses your wake time."),
                selected: !alarmOn, enabled: true) { onPick(false) }
            row(String(localized: "Sleep goal"),
                String(localized: "Wakes you in a light moment once your goal is met. Needs a phone-side smart wake, on Android only for now."),
                selected: false, enabled: false) {}
            row(String(localized: "In the green"),
                String(localized: "Wakes you once your Recovery would reach green. Needs a phone-side smart wake, on Android only for now."),
                selected: false, enabled: false) {}
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PulseTheme.wheelSheet.ignoresSafeArea())
        .presentationDetents([.height(500), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(PulseTheme.Radius.menu)
        .environment(\.colorScheme, .dark)
    }

    private func row(_ title: String, _ detail: String, selected: Bool, enabled: Bool,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .pulseText(.cardTitle)
                        .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                    Text(detail)
                        .pulseText(.rowSubline)
                        .foregroundStyle(enabled ? PulseTheme.textSecondary : PulseTheme.textDisabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(PulseTheme.positive)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.listWithSubline, alignment: .leading)
            .pulseCardBackground(.rowCard)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// A wake-time wheel (hours and minutes) with CANCEL and a confirm button, in the wheel-sheet look (§2.6
/// item 36).
struct PulseSleepTimeSheet: View {
    let title: String
    let confirmTitle: String
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    @State private var date: Date

    init(title: String, minutes: Int, confirmTitle: String, onConfirm: @escaping (Int) -> Void,
         onCancel: @escaping () -> Void) {
        self.title = title
        self.confirmTitle = confirmTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        let base = Calendar.current.startOfDay(for: Date())
        _date = State(initialValue: base.addingTimeInterval(TimeInterval(minutes * 60)))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)
            DatePicker(title, selection: $date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(String(localized: "Cancel"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white, lineWidth: 1.5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                Button {
                    let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                    onConfirm((c.hour ?? 7) * 60 + (c.minute ?? 0))
                } label: {
                    Text(confirmTitle)
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(Color.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .frame(maxWidth: .infinity)
        .background(PulseTheme.wheelSheet.ignoresSafeArea())
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(PulseTheme.Radius.menu)
        .environment(\.colorScheme, .dark)
    }
}
#endif
