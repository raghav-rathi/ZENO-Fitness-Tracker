#if os(iOS)
import SwiftUI

// MARK: - Shared cards two or more screen groups draw (WHOOP_UI_SPEC §2.6, §2.5, §3.1)
//
// Each takes plain values, never a snapshot: map yours to them in your group.

// MARK: Monitor tile (§2.6 item 4, §3.1 item 6)

/// A HEALTH MONITOR › / STRESS MONITOR › tile (Home, the Health tab), 92 pt tall: the title with "›", then 12 pt below,
/// a 24 pt status badge beside the status word (11 pt Bold caps, semantic colour) over a secondary line
/// (12 pt, 70%). While calibrating it shows a grey "–" and "Pending" (§2.9: tiles always show in ZENO).
///
///     PulseMonitorTile(title: "Health Monitor", status: .init(badge: .check, tint: .teal,
///                      word: "Within range", wordColor: PulseTheme.positive, detail: "5/5 Metrics"))
struct PulseMonitorTile: View {
    struct Status: Equatable {
        var badge: PulseStatusBadge.Content
        var tint: PulseTheme.Tint
        /// The status word ("WITHIN RANGE", "MEDIUM"); nil shows "Pending".
        var word: String?
        var wordColor: Color = PulseTheme.textPrimary
        /// The secondary line ("5/5 Metrics", "4:31 PM").
        var detail: String?

        /// Calibrating, or nothing to judge yet: grey "–" and "Pending".
        static let pending = Status(badge: .pending, tint: .grey, word: nil, detail: nil)
    }

    let title: String
    let status: Status

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PulseCardTitle(title, accessory: .trailingChevron)
            HStack(alignment: .center, spacing: 10) {
                PulseStatusBadge(status.badge, tint: status.tint)
                VStack(alignment: .leading, spacing: 1) {
                    if let word = status.word {
                        PulseWordWrapText(word, style: .label)
                            .foregroundStyle(status.wordColor)
                        if let detail = status.detail {
                            Text(detail)
                                .pulseText(.secondary)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    } else {
                        Text(String(localized: "Pending"))
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        // 92 pt at the default size (reviews/r41: 298.3–390.7 pt), growing with the text.
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .pulseCardBackground()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue([status.word ?? String(localized: "Pending"), status.detail]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: Insight (coach) card (§2.6 item 10)

/// The coach's inline insight: transparent, a 1.5 pt AI-gradient border (radius 12), 14 pt Medium white
/// text on a ≈20 pt line pitch, then 12 pt below the CTA in the AI text gradient
/// ("BREAK DOWN MY RECOVERY →") over the card's 16 pt padding: the CTA sits ≈18 pt under the last baseline
/// and ≈18 pt above the border (deep-dives-2026/57, activity-flows-2026/e01). Only coach content uses this
/// look (Strain dive, Activity Details, recovery-activity details).
struct PulseInsightCard: View {
    let text: String
    var cta: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .pulseText(.body)
                .lineSpacing(3.5)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let cta, let action {
                PulseTextCTA(title: cta, tint: .ai, compact: true, action: action)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.aiBorder, startPoint: .leading,
                                         endPoint: .trailing), lineWidth: 1.5))
    }
}

// MARK: Coach pill and Ask row (§2.6 item 6, §3.1 item 8a)

/// "☀ Your Daily Outlook ›" / "☾ Your Day In Review ›": a 48 pt gradient pill (morning tan → slate,
/// evening indigo → blue), a 20 pt line icon, 15 pt Semibold Title Case text, and "›" in the tinted chevron
/// colour; once read, a plain card with a white "›".
struct PulseCoachPill: View {
    enum Kind: Equatable { case morning, evening }

    let kind: Kind
    let title: String
    var isRead = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: kind == .morning ? "sun.max" : "moon")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(title)
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                PulseChevron(color: isRead ? PulseTheme.textPrimary : chevronColor, size: 14)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.pill)
            .background(background)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens Coach"))
    }

    private var chevronColor: Color {
        kind == .morning ? PulseTheme.Gradients.pillMorningChevron : PulseTheme.Gradients.pillEveningChevron
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        if isRead {
            shape.fill(PulseTheme.Gradients.pillRead)
        } else {
            shape.fill(LinearGradient(gradient: kind == .morning ? PulseTheme.Gradients.pillMorning
                                                                 : PulseTheme.Gradients.pillEvening,
                                      startPoint: .leading, endPoint: .trailing))
        }
    }
}

/// "Ask a question, get support… ›" (completeness-critic/25): a 48 pt white-10% card row with the outlined
/// coach mark, 15 pt text at 70% and "›". It stands in for the coach pill when no outlook can be made.
struct PulseAskRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PulseCoachAvatar(size: 22, ringWidth: 1, showsOrb: false)
                Text(String(localized: "Ask a question, get support…"))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                PulseChevron(color: PulseTheme.textSecondary, size: 14)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.pill)
            .pulseCardBackground()
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens Coach"))
    }
}

// MARK: Zone row card (§2.6 item 18)

/// One heart-rate zone in its own card: "ZONE 4" with its range and share in the zone colour, the time at
/// the right (seconds smaller and grey), then a zone-coloured bar over the hatched track with the typical
/// range boxed. A zone with no time draws at 40% opacity.
struct PulseZoneRowCard: View {
    let zone: Int
    /// "162-171 BPM" or "(80-90%)".
    let range: String
    /// 0...1 of the activity's time.
    let share: Double
    /// "0:00:48".
    let duration: String
    /// The typical share as fractions of the bar, if known.
    var typical: ClosedRange<Double>?

    var body: some View {
        let color = PulseTheme.Zone.color(zone)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(localized: "Zone \(zone)"))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(range)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
                Text("\(Int((share * 100).rounded()))%")
                    .font(PulseType.numeral(13))
                    .foregroundStyle(color)
                Spacer(minLength: 8)
                durationText
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    PulseHatchedTrack()
                    RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                        .fill(color)
                        .frame(width: max(share > 0 ? 4 : 0, geo.size.width * CGFloat(max(0, min(1, share)))))
                    if let typical {
                        PulseTypicalRangeBox()
                            .frame(width: geo.size.width * CGFloat(typical.upperBound - typical.lowerBound))
                            .offset(x: geo.size.width * CGFloat(typical.lowerBound))
                    }
                }
            }
            .frame(height: 14)
        }
        .padding(16)
        .pulseCardBackground()
        .opacity(share > 0 ? 1 : 0.4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Zone \(zone), \(range), \(Int((share * 100).rounded())) percent, \(duration)"))
    }

    /// "0:00:48" with the seconds smaller and grey.
    private var durationText: some View {
        let parts = duration.split(separator: ":")
        let head = parts.count > 1 ? parts.dropLast().joined(separator: ":") + ":" : ""
        let tail = parts.last.map(String.init) ?? duration
        return (Text(head).font(PulseType.font(.rowValue)).foregroundColor(PulseTheme.textPrimary)
                + Text(tail).font(PulseType.font(.baseline)).foregroundColor(PulseTheme.textTertiary))
    }
}

/// The typical-range box over a bar: two dashed 1 pt verticals (white 50%) with a white 10% veil between.
/// It draws no hatch of its own: the track's stripes show through it lighter and the bar shows through it
/// lighter and unstriped, as WHOOP's box and its legend swatch do (help-center/82, deep-dives-2026/15).
struct PulseTypicalRangeBox: View {
    var body: some View {
        ZStack {
            Rectangle().fill(PulseTheme.typicalBox)
            HStack {
                PulseDashedVertical()
                Spacer(minLength: 0)
                PulseDashedVertical()
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PulseDashedVertical: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0.5, y: 0))
            p.addLine(to: CGPoint(x: 0.5, y: 200))
        }
        .stroke(PulseTheme.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        .frame(width: 1)
        .clipped()
    }
}

// MARK: Diverging impact bar (§2.6 item 20)

/// A behaviour's impact on a hatched track centred on a 4 pt white dot in a dark ring: green to the right
/// when it helps, orange to the left when it hurts, grey when not significant, with the value at the right
/// in the bar's colour ("+8%"). The Behavior Details version is wider with a ≈30 pt value (`large`).
struct PulseImpactBar: View {
    enum Effect: Equatable { case helps, hurts, notSignificant }

    /// Signed fraction of the half-track, −1...1 (negative = to the left).
    let fraction: Double
    let effect: Effect
    /// "+8%", "-3%".
    let valueText: String
    var large = false

    private var color: Color {
        switch effect {
        case .helps: return PulseTheme.Impact.helps
        case .hurts: return PulseTheme.Impact.hurts
        case .notSignificant: return PulseTheme.Impact.notSignificant
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                let half = geo.size.width / 2
                let length = half * CGFloat(min(1, abs(fraction)))
                ZStack {
                    PulseHatchedTrack(color: PulseTheme.Impact.hatch, cornerRadius: 3)
                    RoundedRectangle(cornerRadius: 3, style: .circular)
                        .fill(color)
                        .frame(width: length, height: geo.size.height)
                        .offset(x: fraction >= 0 ? length / 2 : -length / 2)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                        .padding(3)
                        .background(Circle().fill(PulseTheme.Impact.dotRing))
                }
            }
            .frame(height: large ? 12 : 8)
            Text(valueText)
                .font(large ? PulseType.font(.impactValue) : PulseType.font(.rowValue))
                .foregroundStyle(color)
                .frame(minWidth: large ? 70 : 44, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(valueText)
    }
}

// MARK: Day-circle row (§2.6 item 37)

/// MON–SUN caps labels (the newest white, the others 50%) over 28 pt circles. The Journal style: logged =
/// green with a black ✓, not logged = white-40% ring, today pending = grey with a 2 pt white ring. The Plan
/// style: done = blue ring with a blue dot, rest = grey "–", future = dashed ring.
struct PulseDayCircleRow: View {
    enum State: Equatable {
        // Journal
        case logged, notLogged, pending
        // Plan
        case done, rest, future
    }

    struct Day: Identifiable, Equatable {
        let id: String
        /// "MON".
        let label: String
        let state: State
        /// The selected / newest day: its label is white.
        var isCurrent = false
    }

    let days: [Day]
    var diameter: CGFloat = 28
    var onTap: ((Day) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                Group {
                    if let onTap {
                        Button { onTap(day) } label: { cell(day) }
                            .buttonStyle(PulsePressStyle())
                    } else {
                        cell(day)
                    }
                }
                .accessibilityLabel(day.label)
                .accessibilityValue(spoken(day.state))
            }
        }
        // Seven columns of three-letter labels: past xxLarge they would run into each other.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func cell(_ day: Day) -> some View {
        VStack(spacing: 8) {
            Text(day.label)
                .pulseText(.label)
                .foregroundStyle(day.isCurrent ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            PulseDayCircle(state: day.state, diameter: diameter)
        }
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
        .contentShape(Rectangle())
    }

    private func spoken(_ state: State) -> String {
        switch state {
        case .logged: return String(localized: "Logged")
        case .notLogged: return String(localized: "Not logged")
        case .pending: return String(localized: "Not logged yet")
        case .done: return String(localized: "Done")
        case .rest: return String(localized: "Rest day")
        case .future: return String(localized: "Upcoming")
        }
    }
}

/// One circle of a `PulseDayCircleRow`.
struct PulseDayCircle: View {
    let state: PulseDayCircleRow.State
    var diameter: CGFloat = 28

    var body: some View {
        Group {
            switch state {
            case .logged:
                Circle()
                    .fill(PulseTheme.Journal.logged)
                    .overlay(Image(systemName: "checkmark")
                        .font(.system(size: diameter * 0.43, weight: .bold))
                        .foregroundStyle(Color.black))
            case .notLogged:
                Circle().strokeBorder(PulseTheme.Journal.notLogged, lineWidth: 1.5)
            case .pending:
                Circle()
                    .fill(PulseTheme.Journal.todayPending)
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
            case .done:
                Circle()
                    .strokeBorder(PulseTheme.recoveryBlue, lineWidth: 2)
                    .overlay(Circle().fill(PulseTheme.recoveryBlue).frame(width: diameter * 0.3, height: diameter * 0.3))
            case .rest:
                Circle()
                    .fill(PulseTheme.card)
                    .overlay(Text(verbatim: "–").font(.system(size: diameter * 0.45, weight: .bold))
                        .foregroundStyle(PulseTheme.textTertiary))
            case .future:
                Circle().strokeBorder(PulseTheme.textDisabled, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

// MARK: Plan goal ring (§2.5 "Plan goal counters")

/// A ≈40 pt goal ring. Count goals split into one dashed segment per target day with the completed ones
/// teal ("5/7" inside); time and value goals use a solid ring ("0:27"). A met goal is green.
struct PulseGoalRing: View {
    enum Kind: Equatable {
        /// `done` of `target` days.
        case count(done: Int, target: Int)
        /// A value goal: the text inside and how far along it is (0...1).
        case value(text: String, fraction: Double)
    }

    let kind: Kind
    var diameter: CGFloat = 40

    private var isMet: Bool {
        switch kind {
        case .count(let done, let target): return target > 0 && done >= target
        case .value(_, let fraction): return fraction >= 1
        }
    }

    var body: some View {
        let stroke: CGFloat = 3
        ZStack {
            switch kind {
            case .count(let done, let target):
                let n = max(1, target)
                ForEach(0..<n, id: \.self) { i in
                    let gap = 0.025
                    PulseRingSegment(start: Double(i) / Double(n) + gap / 2, end: Double(i + 1) / Double(n) - gap / 2,
                                     thickness: stroke, cornerRadius: 1)
                        .fill(i < done ? (isMet ? PulseTheme.Plan.goalMet : PulseTheme.positive) : PulseTheme.track)
                }
            case .value(_, let fraction):
                Circle().strokeBorder(PulseTheme.track, lineWidth: stroke)
                PulseRingSegment(start: 0, end: max(0, min(1, fraction)), thickness: stroke, cornerRadius: 1)
                    .fill(isMet ? PulseTheme.Plan.goalMet : PulseTheme.positive)
            }
            Text(label)
                .font(PulseType.numeral(13))
                .foregroundStyle(isMet ? PulseTheme.Plan.goalMet : PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, stroke + 3)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(isMet ? String(localized: "Goal met") : "")
    }

    private var label: String {
        switch kind {
        case .count(let done, let target): return "\(done)/\(target)"
        case .value(let text, _): return text
        }
    }
}

// MARK: Dialog card and error page (§2.6 items 30, 31; §3.37)

/// A centred dialog card over black or a deep dim: gradient #27343C → #1B2228 (radius 15), "✕" at the
/// top-right, a white Bold caps title, grey centred body, a white filled capsule and an optional outlined
/// second action. Present it full screen (`.fullScreenCover`); it draws its own black 85% scrim.
struct PulseDialogCard: View {
    let title: String
    let message: String
    let primaryTitle: String
    let primary: () -> Void
    var secondaryTitle: String?
    var secondary: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        ZStack {
            PulseTheme.dialogScrim.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    PulseCloseButton(action: onClose)
                }
                .padding(.bottom, -12)
                Text(title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(primaryTitle, action: primary)
                    .buttonStyle(.pulseFilledWhite)
                if let secondaryTitle, let secondary {
                    Button(secondaryTitle, action: secondary)
                        .buttonStyle(.pulseOutlineWhite)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 8)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.dialog, style: .continuous)
                .fill(LinearGradient(colors: [PulseTheme.dialogTop, PulseTheme.dialogBottom], startPoint: .top,
                                     endPoint: .bottom)))
            .padding(.horizontal, 32)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .environment(\.colorScheme, .dark)
    }
}

/// A full-screen error page: a 95 pt red ring (4.7 pt) holding "!", the title ("ERROR", "YOUR ENTRY WAS NOT
/// SAVED"; 15 pt Bold caps), a grey body, an outlined white "RETRY" capsule and a "CLOSE" text button.
struct PulseErrorPage: View {
    var title: String = String(localized: "Error")
    let message: String
    var retryTitle: String = String(localized: "Retry")
    let onRetry: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().strokeBorder(PulseTheme.Onboarding.errorRing, lineWidth: 4.7)
                Text(verbatim: "!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(PulseTheme.Onboarding.errorRing)
            }
            .frame(width: 95, height: 95)
            .accessibilityHidden(true)
            Text(title)
                .pulseText(.capsuleLabel)
                .foregroundStyle(PulseTheme.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(retryTitle, action: onRetry)
                .buttonStyle(.pulseOutlineWhite)
            Button(action: onClose) {
                Text(String(localized: "Close"))
                    .pulseText(.capsuleLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }
}

// MARK: Wheel-picker sheet (§2.6 item 36)

/// A bottom sheet with a grabber and a 20 pt Semibold title over an iOS wheel (its selection band
/// #26292E), then "CANCEL" (outlined) and "CONFIRM" (solid; grey while invalid), 52 pt tall, radius 14.
/// Present it with `.sheet` and `.presentationDetents([.height(360)])`.
struct PulseWheelPickerSheet<Value: Hashable>: View {
    let title: String
    let options: [Value]
    @Binding var selection: Value
    var isValid: (Value) -> Bool = { _ in true }
    let label: (Value) -> String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    init(title: String, options: [Value], selection: Binding<Value>, isValid: @escaping (Value) -> Bool = { _ in true },
         label: @escaping (Value) -> String, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.options = options
        _selection = selection
        self.isValid = isValid
        self.label = label
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 24)
                .accessibilityAddTraits(.isHeader)
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .pickerStyle(.wheel)
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
                Button(action: onConfirm) {
                    Text(String(localized: "Confirm"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(isValid(selection) ? Color.black : PulseTheme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isValid(selection) ? Color.white : PulseTheme.buttonInvalid))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .disabled(!isValid(selection))
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(PulseTheme.wheelSheet.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .environment(\.colorScheme, .dark)
    }
}
#endif
