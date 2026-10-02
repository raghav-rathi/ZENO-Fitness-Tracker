#if os(iOS)
import SwiftUI

// MARK: - Buttons (WHOOP_UI_SPEC §2.6 item 16)
//
//   (a) .pulseNested        in-card button: white 10% on the card, radius 10, 44 pt, UPPERCASE 12 pt at 85%
//   (b) .pulseOutline(...)  capsule with a 2 pt recovery-blue (or 1.5 pt white) outline and matching text
//   (c) .pulseFilledWhite   white capsule, black UPPERCASE text ("SAVE JOURNAL", "GOT IT")
//   (d) PulseTextCTA        UPPERCASE text + "→" (AI gradient for coach, blue, magenta)
//   (e) PulsePlusButton     the white 36 pt "+" square (PulseHeaders.swift)
//   (f) .pulseFilledBlue    the blue "START ACTIVITY" capsule
//
//     Button { … } label: { Label(String(localized: "Add activity"), systemImage: "plus") }
//         .buttonStyle(.pulseNested)

struct PulseButtonStyle: ButtonStyle {
    enum Kind: Equatable {
        case nested
        case outline(Color)
        case outlineWhite
        case filledWhite
        case filledBlue
    }

    let kind: Kind
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .labelStyle(PulseButtonLabelStyle())
            .pulseText(.cardTitle)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: height)
            .background(background)
            .contentShape(Rectangle())
            .opacity(pressed ? 0.7 : 1)
            .animation(pressed ? nil : PulseMotion.pressRelease, value: pressed)
    }

    private var height: CGFloat {
        switch kind {
        case .nested: return PulseTheme.Row.nestedButton
        case .filledBlue: return 49
        default: return PulseTheme.Layout.minTapTarget
        }
    }

    private var foreground: Color {
        switch kind {
        case .nested: return PulseTheme.textButton
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

extension ButtonStyle where Self == PulseButtonStyle {
    /// (a) The in-card button: white 10% on the card.
    static var pulseNested: PulseButtonStyle { PulseButtonStyle(kind: .nested) }
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
