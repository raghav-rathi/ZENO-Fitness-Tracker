#if os(iOS)
import SwiftUI

// MARK: - Buttons (WHOOP_UI_SPEC §2.6 item 16)
//
//   (a) .pulseNested        in-card button: white 10% on the card, radius 10, drawn 40 pt tall with a 44 pt
//                           hit area, UPPERCASE 11 pt Bold at 85% (completeness-critic/25)
//   (b) .pulseOutline(...)  capsule with a 2 pt recovery-blue (or 1.5 pt white) outline and matching
//                           15 pt text (DR §6)
//   (c) .pulseFilledWhite   white capsule, black UPPERCASE 15 pt text ("SAVE JOURNAL", "GOT IT")
//   (d) PulseTextCTA        UPPERCASE text + "→" (AI gradient for coach, blue, magenta)
//   (e) PulsePlusButton     the white 36 pt "+" square (PulseHeaders.swift)
//   (f) .pulseFilledBlue    the blue "START ACTIVITY" capsule
//
//     Button { … } label: { Label(String(localized: "Add activity"), systemImage: "plus") }
//         .buttonStyle(.pulseNested)
//
// Labels stay on one line and shrink a little at large sizes; two side by side go in a `PulseButtonRow`,
// which stacks them when they no longer fit next to each other, so no label is ever cut ("ADD ACTIV…").

struct PulseButtonStyle: ButtonStyle {
    enum Kind: Equatable {
        case nested
        /// The in-card button on a spec'd solid fill (Journal's BEHAVIOR INSIGHTS `#484C50`).
        case nestedFill(Color)
        case outline(Color)
        case outlineWhite
        case filledWhite
        case filledBlue
    }

    let kind: Kind
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let hitOverflow = max(0, (PulseTheme.Layout.minTapTarget - height) / 2)
        return configuration.label
            .labelStyle(PulseButtonLabelStyle())
            .pulseText(isNested ? .buttonLabel : .capsuleLabel)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background(background)
            // A 40 pt button still takes a 44 pt touch: the hit area overflows its drawn edge.
            .padding(.vertical, hitOverflow)
            .contentShape(Rectangle())
            .padding(.vertical, -hitOverflow)
            .opacity(pressed ? 0.7 : 1)
            .animation(pressed ? nil : PulseMotion.pressRelease, value: pressed)
    }

    private var isNested: Bool {
        switch kind {
        case .nested, .nestedFill: return true
        default: return false
        }
    }

    private var height: CGFloat {
        switch kind {
        case .nested, .nestedFill: return PulseTheme.Row.nestedButton
        case .filledBlue: return 49
        default: return PulseTheme.Layout.minTapTarget
        }
    }

    private var foreground: Color {
        switch kind {
        case .nested, .nestedFill: return PulseTheme.textButton
        case .outline(let color): return color
        case .outlineWhite: return PulseTheme.textPrimary
        case .filledWhite: return Color.black
        case .filledBlue: return PulseTheme.textPrimary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .nested:
            RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular).fill(PulseTheme.nested)
        case .nestedFill(let color):
            RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular).fill(color)
        case .outline(let color):
            Capsule(style: .circular).strokeBorder(color, lineWidth: 2)
        case .outlineWhite:
            Capsule(style: .circular).strokeBorder(Color.white, lineWidth: 1.5)
        case .filledWhite:
            Capsule(style: .circular).fill(Color.white)
        case .filledBlue:
            Capsule(style: .circular).fill(PulseTheme.Activity.startCapsule)
        }
    }
}

/// Icon then title, 8 pt apart, for `Label`s inside Pulse buttons.
struct PulseButtonLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon.font(.system(size: 14, weight: .semibold))
            configuration.title
        }
    }
}

/// Two (or more) buttons side by side, 12 pt apart, that stack full width once their labels no longer fit
/// next to each other (large text sizes), rather than truncating a label.
///
///     PulseButtonRow {
///         Button { … } label: { Label("Add activity", systemImage: "plus") }.buttonStyle(.pulseNested)
///         Button { … } label: { Label("Start activity", systemImage: "stopwatch") }.buttonStyle(.pulseNested)
///     }
struct PulseButtonRow<Content: View>: View {
    var spacing: CGFloat = PulseTheme.Layout.gridGap
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = PulseTheme.Layout.gridGap, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) { content() }
            VStack(spacing: spacing) { content() }
        }
    }
}

extension ButtonStyle where Self == PulseButtonStyle {
    /// (a) The in-card button: white 10% on the card.
    static var pulseNested: PulseButtonStyle { PulseButtonStyle(kind: .nested) }
    /// (a) The in-card button on a spec'd solid fill.
    static func pulseNested(fill: Color) -> PulseButtonStyle { PulseButtonStyle(kind: .nestedFill(fill)) }
    /// (b) An outline capsule (recovery blue by default).
    static func pulseOutline(_ color: Color = PulseTheme.recoveryBlue) -> PulseButtonStyle {
        PulseButtonStyle(kind: .outline(color))
    }
    /// (b) The white 1.5 pt outline capsule ("ADD SLEEP", "RETRY").
    static var pulseOutlineWhite: PulseButtonStyle { PulseButtonStyle(kind: .outlineWhite) }
    /// (c) The white filled capsule with black text.
    static var pulseFilledWhite: PulseButtonStyle { PulseButtonStyle(kind: .filledWhite) }
    /// (f) The blue filled capsule.
    static var pulseFilledBlue: PulseButtonStyle { PulseButtonStyle(kind: .filledBlue) }
}

/// (d) A text call to action: UPPERCASE 11 pt Bold tracked plus "→". `.ai` paints it with the AI text
/// gradient (coach content only); otherwise it takes a flat colour.
struct PulseTextCTA: View {
    enum Tint {
        case ai
        case color(Color)
    }

    let title: String
    var tint: Tint = .color(PulseTheme.recoveryBlue)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title).pulseText(.label)
                Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(style)
            .frame(minHeight: PulseTheme.Layout.minTapTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }

    private var style: AnyShapeStyle {
        switch tint {
        case .ai:
            return AnyShapeStyle(LinearGradient(gradient: PulseTheme.Gradients.aiText,
                                                startPoint: .leading, endPoint: .trailing))
        case .color(let color):
            return AnyShapeStyle(color)
        }
    }
}
#endif
