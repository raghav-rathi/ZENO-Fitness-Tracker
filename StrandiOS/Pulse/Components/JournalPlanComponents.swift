#if os(iOS)
import SwiftUI

// MARK: - Journal and Plan components (WHOOP_UI_SPEC §2.6 items 21, 27, 28, 33; §3.17–3.19)
//
// Pieces the journal-plan group's screens share among themselves. They take plain values, never
// snapshots, and draw only with `PulseTheme` tokens (the group's own in `JournalPlanTokens.swift`).

// MARK: Answer toggles (§2.6 item 21)

/// The ✕ / ✓ pair at the right of a journal row: two 32 pt squares (radius 6, 8 pt apart). ✕ selected is a
/// white square with a black ✕; ✓ selected is blue with a near-black ✓; unselected squares are a
/// translucent white over the card, with a white glyph. Tapping the selected square again clears it.
struct JournalAnswerToggles: View {
    /// true = ✓, false = ✕, nil = unanswered.
    let answer: Bool?
    /// The row's question, for VoiceOver.
    let question: String
    let onChange: (Bool?) -> Void

    var body: some View {
        HStack(spacing: PulseTheme.JournalPlan.toggleGap) {
            square(isYes: false)
            square(isYes: true)
        }
    }

    private func square(isYes: Bool) -> some View {
        let selected = answer == isYes
        return Button {
            onChange(selected ? nil : isYes)
        } label: {
            Image(systemName: isYes ? "checkmark" : "xmark")
                .font(PulseTheme.JournalPlan.toggleGlyph)
                .foregroundStyle(selected ? PulseTheme.JournalPlan.toggleGlyphOnSelected : PulseTheme.textPrimary)
                .frame(width: PulseTheme.JournalPlan.toggleSize, height: PulseTheme.JournalPlan.toggleSize)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                    .fill(fill(isYes: isYes, selected: selected)))
                .contentShape(Rectangle().inset(by: -6))
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(isYes ? String(localized: "Yes") : String(localized: "No"))
        .accessibilityValue(question)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(selected ? String(localized: "Double-tap to clear the answer") : "")
    }

    private func fill(isYes: Bool, selected: Bool) -> Color {
        guard selected else { return PulseTheme.JournalPlan.toggleIdle }
        return isYes ? PulseTheme.Journal.toggleYes : PulseTheme.JournalPlan.toggleNo
    }
}

// MARK: Journal section label

/// "DAYTIME", "YOUR CUSTOM PLAN": 11 pt Bold caps at white 50%, with a hairline to the right edge; or
/// "NOTES" with no rule.
struct JournalSectionLabel: View {
    let title: String
    var rule = true

    var body: some View {
        HStack(spacing: 10) {
            PulseWordWrapText(title, style: .label)
                .foregroundStyle(PulseTheme.JournalPlan.sectionLabel)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
            if rule {
                Rectangle()
                    .fill(PulseTheme.JournalPlan.sectionRule)
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .accessibilityHidden(true)
            } else {
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: Follow-up value capsule (§3.17 item 10)

/// A follow-up's value at the right of its row: "-- Minutes" on translucent grey while empty, "15 Minutes"
/// in black bold on blue once set (radius 8). Tapping it opens the wheel.
struct JournalValueCapsule: View {
    let text: String
    let isSet: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(isSet ? PulseTheme.JournalPlan.followUpValue : PulseType.font(.pillTitle))
                .foregroundStyle(isSet ? Color.black : PulseTheme.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .frame(minHeight: 34)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    .fill(isSet ? PulseTheme.JournalPlan.followUpFilled : PulseTheme.JournalPlan.followUpIdle))
                .contentShape(Rectangle().inset(by: -5))
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(text)
        .accessibilityHint(String(localized: "Opens a picker"))
    }
}

// MARK: Behaviour row card (§3.17 item 8)

/// One behaviour in its own rounded card: the question (15 pt Medium) at the left, the ✕ / ✓ squares (or a
/// value capsule) at the right, 64 pt for a one-line question, and once answered ✓ a follow-up row under
/// a hairline.
struct JournalRowCard<Trailing: View, FollowUp: View>: View {
    let question: String
    /// A leading accessory (the plan section's progress ring).
    var leading: AnyView?
    /// The outlined "Custom" chip after a custom behaviour's question.
    var isCustom = false
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let followUp: () -> FollowUp

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                if let leading { leading }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(question)
                        .pulseText(.rowText)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if isCustom { JournalCustomChip() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                trailing()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(minHeight: PulseTheme.JournalPlan.rowHeight)
            followUp()
        }
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.JournalPlan.rowCard))
        .accessibilityElement(children: .contain)
    }
}

/// The follow-up block under a row's hairline: "For how long (minutes)?" indented, its capsule right.
struct JournalFollowUpRow: View {
    let question: String
    let capsule: JournalValueCapsule

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(PulseTheme.divider).frame(height: 1)
                .padding(.horizontal, 16)
                .accessibilityHidden(true)
            HStack(spacing: 12) {
                Text(question)
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                capsule
            }
            .padding(.leading, 32)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
        }
    }
}

/// The outlined "Custom" chip.
struct JournalCustomChip: View {
    var body: some View {
        Text(String(localized: "Custom"))
            .pulseText(.chip)
            .foregroundStyle(PulseTheme.textPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                .strokeBorder(PulseTheme.JournalPlan.customChipBorder, lineWidth: 1))
            .fixedSize()
    }
}

// MARK: AI entry card (§2.6 item 33)

/// "✧ Smart log with Coach" over "⌨ TEXT" and "mic TALK": the AI-entry gradient card (radius 20, 1 pt
/// border). `collapsed` folds it to one row once it has been used ([Z]: it pushes the rows down).
struct JournalAIEntryCard: View {
    let title: String
    var collapsed = false
    var showsTalk = true
    let onText: () -> Void
    let onTalk: () -> Void

    var body: some View {
        Group {
            if collapsed {
                Button(action: onText) {
                    HStack(spacing: 10) {
                        sparkle(size: 16)
                        Text(title)
                            .pulseText(.coachingTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Spacer(minLength: 8)
                        PulseChevron(color: PulseTheme.textSecondary, size: 13)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.pill)
                    .background(background)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens Coach"))
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        sparkle(size: 20)
                        Text(title)
                            .pulseText(.cardHeadline)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                    }
                    PulseButtonRow(spacing: 10) {
                        entryButton(String(localized: "Text"), symbol: "keyboard", talk: false, action: onText)
                        if showsTalk {
                            entryButton(String(localized: "Talk"), symbol: "mic", talk: true, action: onTalk)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(background)
            }
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: PulseTheme.Radius.menu, style: .continuous)
            .fill(LinearGradient(gradient: PulseTheme.Gradients.aiEntryFill, startPoint: .leading, endPoint: .trailing))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.menu, style: .continuous)
                .strokeBorder(PulseTheme.Gradients.aiEntryBorder, lineWidth: 1))
    }

    private func sparkle(size: CGFloat) -> some View {
        Image(systemName: "sparkles")
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(PulseTheme.Gradients.aiEntrySparkle)
            .accessibilityHidden(true)
    }

    private func entryButton(_ title: String, symbol: String, talk: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(talk ? PulseTheme.Gradients.aiEntryMic : PulseTheme.textSecondary)
                Text(title).pulseText(.capsuleLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background {
                let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .continuous)
                if talk {
                    shape.fill(LinearGradient(gradient: PulseTheme.Gradients.aiEntryTalkButton,
                                              startPoint: .leading, endPoint: .trailing))
                } else {
                    shape.fill(PulseTheme.Gradients.aiEntryTextButton)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }
}

// MARK: Day capsule (§3.17 item 4)

/// One day of the Journal's strip: a tall white-12% capsule holding the weekday ("Mon", 13 pt at 70%), the
/// date (20 pt Bold condensed) and, under a logged day, a green ✓ disc. The selected day is ringed 2 pt white.
struct JournalDayCapsule: View {
    let weekday: String
    let date: String
    let logged: Bool
    let selected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(weekday)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(date)
                .font(PulseTheme.JournalPlan.dayNumber)
                .foregroundStyle(PulseTheme.textPrimary)
            ZStack {
                if logged {
                    Circle().fill(PulseTheme.Journal.logged)
                    Image(systemName: "checkmark")
                        .font(PulseTheme.JournalPlan.smallGlyph)
                        .foregroundStyle(Color.black)
                }
            }
            .frame(width: 18, height: 18)
        }
        .frame(maxWidth: .infinity)
        .frame(height: PulseTheme.JournalPlan.dayCapsuleHeight)
        .background(Capsule(style: .continuous).fill(PulseTheme.JournalPlan.dayCapsule))
        .overlay {
            if selected {
                Capsule(style: .continuous).strokeBorder(Color.white, lineWidth: 2)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }
}

// MARK: Count badges (§2.6 item 27)

/// "☒ 51 ☑ 18": an outlined ✕ and ✓ square, each followed by its count; the side with fewer than
/// `enough` answers is dimmed.
struct JournalCountBadges: View {
    let no: Int
    let yes: Int
    var enough = 5

    var body: some View {
        HStack(spacing: 10) {
            badge(symbol: "xmark", count: no)
            badge(symbol: "checkmark", count: yes)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(yes) yes, \(no) no"))
    }

    private func badge(symbol: String, count: Int) -> some View {
        let dim = count < enough
        let color = dim ? PulseTheme.JournalPlan.countBorderDim : PulseTheme.JournalPlan.countBorder
        return HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(PulseTheme.JournalPlan.smallGlyph)
                .foregroundStyle(color)
                .frame(width: 18, height: 18)
                .overlay(RoundedRectangle(cornerRadius: 4, style: .circular).strokeBorder(color, lineWidth: 1.5))
            Text(verbatim: "\(count)")
                .font(PulseTheme.JournalPlan.countNumber)
                .foregroundStyle(dim ? PulseTheme.textTertiary : PulseTheme.textPrimary)
        }
    }
}

// MARK: Checkbox (§3.17b item 6)

/// A 24 pt checkbox: blue with a dark ✓ when checked, a 1.5 pt white outline when not (radius 4).
struct JournalCheckbox: View {
    let checked: Bool

    var body: some View {
        ZStack {
            if checked {
                RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                    .fill(PulseTheme.JournalPlan.checkbox)
                Image(systemName: "checkmark")
                    .font(PulseTheme.JournalPlan.checkGlyph)
                    .foregroundStyle(PulseTheme.JournalPlan.checkboxGlyph)
            } else {
                RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                    .strokeBorder(Color.white, lineWidth: 1.5)
            }
        }
        .frame(width: PulseTheme.JournalPlan.checkboxSize, height: PulseTheme.JournalPlan.checkboxSize)
        .accessibilityHidden(true)
    }
}

// MARK: Verdict chip (§3.18 Behavior Details)

/// "Negative" / "Positive" / "Not significant" at the right of RECOVERY IMPACT (radius 6).
struct BehaviorVerdictChip: View {
    enum Verdict { case positive, negative, neutral }

    let verdict: Verdict

    var body: some View {
        Text(title)
            .pulseText(.pillTitle)
            .foregroundStyle(colors.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular).fill(colors.fill))
            .fixedSize()
    }

    private var title: String {
        switch verdict {
        case .positive: return String(localized: "Positive")
        case .negative: return String(localized: "Negative")
        case .neutral: return String(localized: "Not significant")
        }
    }

    private var colors: (text: Color, fill: Color) {
        switch verdict {
        case .positive: return (PulseTheme.JournalPlan.verdictPositiveText, PulseTheme.JournalPlan.verdictPositiveFill)
        case .negative: return (PulseTheme.JournalPlan.verdictNegativeText, PulseTheme.JournalPlan.verdictNegativeFill)
        case .neutral: return (PulseTheme.JournalPlan.verdictNeutralText, PulseTheme.JournalPlan.verdictNeutralFill)
        }
    }
}

// MARK: Impact value (§3.18)

/// "-6%" with the "%" smaller, in the bar's colour.
struct BehaviorImpactValue: View {
    let impact: Double
    let color: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(BehaviorImpactFormat.number(impact))
                .font(PulseType.font(.impactValue))
            Text(verbatim: "%")
                .font(PulseTheme.JournalPlan.impactUnit)
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(BehaviorImpactFormat.text(impact))
    }
}

/// How an impact reads: "+8%", "-3%", "0%"; and the bar's effect and colour.
enum BehaviorImpactFormat {
    static func number(_ impact: Double) -> String {
        let rounded = Int(impact.rounded())
        return rounded > 0 ? "+\(rounded)" : "\(rounded)"
    }

    static func text(_ impact: Double) -> String { number(impact) + "%" }

    static func effect(impact: Double?, significant: Bool) -> PulseImpactBar.Effect {
        guard let impact, significant, Int(impact.rounded()) != 0 else { return .notSignificant }
        return impact > 0 ? .helps : .hurts
    }

    static func color(_ effect: PulseImpactBar.Effect) -> Color {
        switch effect {
        case .helps: return PulseTheme.Impact.helps
        case .hurts: return PulseTheme.Impact.hurts
        case .notSignificant: return PulseTheme.Impact.notSignificant
        }
    }

    /// The bar's signed fraction of its half-track on a page scaled to `scale` percent.
    static func fraction(_ impact: Double?, scale: Double) -> Double {
        guard let impact, scale > 0 else { return 0 }
        return max(-1, min(1, impact / scale))
    }
}

// MARK: Locked track

/// A locked behaviour's track: the hatched line with only the centre dot (§2.6 item 28).
struct BehaviorLockedTrack: View {
    var body: some View {
        ZStack {
            PulseHatchedTrack(color: PulseTheme.Impact.hatch, cornerRadius: 3)
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}
#endif

#if os(iOS)
// MARK: Scroll backdrop

/// For a page with its own background (not `PulseScreenScaffold`): once content scrolls under the bar, a
/// solid band of `color` behind the bar and status bar with a short fade below it, so text never runs
/// under the title. Put `JournalPlanScrollMarker()` first in the scroll content and name the scroll view's
/// coordinate space `JournalPlanScrollMarker.space`.
struct JournalPlanScrollBackdrop: View {
    let color: Color
    var fade: CGFloat = PulseTheme.Header.barFade

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                color.frame(height: geo.safeAreaInsets.top)
                LinearGradient(colors: [color, color.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: fade)
                Spacer(minLength: 0)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Reports how far the scroll content's top has moved (see `JournalPlanScrollBackdrop`).
struct JournalPlanScrollMarker: View {
    static let space = "jp.scroll"

    var body: some View {
        Color.clear
            .frame(height: 0)
            .background(GeometryReader { geo in
                Color.clear.preference(key: JournalPlanScrollTopKey.self,
                                       value: geo.frame(in: .named(Self.space)).minY)
            })
    }
}

struct JournalPlanScrollTopKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

extension View {
    /// Sets `scrolled` once the content's top has moved above where it first rested.
    func journalPlanTrackScroll(_ scrolled: Binding<Bool>, rest: Binding<CGFloat?>) -> some View {
        coordinateSpace(name: JournalPlanScrollMarker.space)
            .onPreferenceChange(JournalPlanScrollTopKey.self) { top in
                guard let top else { return }
                if rest.wrappedValue == nil { rest.wrappedValue = top }
                let under = top < (rest.wrappedValue ?? top) - 1
                if under != scrolled.wrappedValue { scrolled.wrappedValue = under }
            }
    }
}
#endif
