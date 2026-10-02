#if os(iOS)
import SwiftUI

// MARK: - Coach button and coach surfaces (WHOOP_UI_SPEC §1.1, §1.2)
//
// The Coach lives behind ONE floating button, never a tab:
//   - on a tab root it sits right of the tab capsule (64 × 64 squircle, 12 pt gap, 12 pt from the edge);
//   - on deep dives, Trend View, monitors, Activity Details and the like it floats alone, 16 pt from the
//     right and bottom safe edges (`PulseScreenScaffold(coach: .button)`);
//   - on the Sleep / Recovery / Strain dives and Activity Details a summary pill can stand in for it
//     (`coach: .pill(text)`): two lines summarising the page, "⌃" opening the Coach sheet.
// Coach switched on with a provider: it opens the Coach sheet. On but unconfigured: Coach setup. Off: every
// coach surface disappears and the tab capsule stretches to full width.

/// Whether and how the Coach is reachable.
enum PulseCoachAvailability: Equatable {
    /// `noop.coachEnabled` is off: no button, no pill.
    case off
    /// On, but no provider is configured: the button opens Coach setup.
    case needsSetup
    /// On and configured: the button opens the Coach sheet.
    case ready
}

/// The Coach's availability and the action that opens it, injected by the shell.
struct PulseCoachContext {
    var availability: PulseCoachAvailability = .off
    /// Open the Coach sheet (or setup), optionally seeded with the page's context.
    var open: (_ seed: String?) -> Void = { _ in }
}

private struct PulseCoachContextKey: EnvironmentKey {
    static let defaultValue = PulseCoachContext()
}

extension EnvironmentValues {
    /// The Coach's availability and opener. Read it to show coach entry points; never read the AppStorage
    /// switch or the engine directly.
    var pulseCoach: PulseCoachContext {
        get { self[PulseCoachContextKey.self] }
        set { self[PulseCoachContextKey.self] = newValue }
    }
}

/// What a pushed screen floats at its bottom edge.
enum PulseCoachAccessory: Equatable {
    case none
    /// The round Coach button alone.
    case button
    /// The coach summary pill. `summary` may use **bold** markdown; it is rendered, never shown raw.
    case pill(summary: String)
}

/// The Coach button: a 64 pt indigo squircle (radius ≈22) with ZENO's monogram inside a violet → blue
/// ring. The same look floats on pushed screens at 60 pt.
struct PulseCoachButton: View {
    var size: CGFloat = PulseTheme.TabBarMetrics.coachSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: PulseTheme.Radius.coachButton * size / 64, style: .continuous)
                    .fill(LinearGradient(gradient: PulseTheme.Coach.buttonFill, startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: PulseTheme.Radius.coachButton * size / 64, style: .continuous)
                    .strokeBorder(LinearGradient(gradient: PulseTheme.Coach.buttonRim, startPoint: .top,
                                                 endPoint: .bottom), lineWidth: 1)
                PulseCoachAvatar(size: PulseTheme.TabBarMetrics.coachRing * size / 64)
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulseCoachPressStyle())
        .accessibilityLabel(String(localized: "Coach"))
        .accessibilityHint(String(localized: "Ask ZENO anything"))
    }
}

/// A slight scale-down while pressed, released over 0.15 s.
private struct PulseCoachPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(configuration.isPressed ? nil : PulseMotion.pressRelease, value: configuration.isPressed)
    }
}

/// The floating coach summary pill (2026): ≈64 pt, radius 20, translucent slate with a soft violet glow;
/// the coach avatar at the left, two lines of 15 pt white text, and "⌃" at the right that expands into the
/// Coach sheet. Markdown bold renders as bold (WHOOP shows the raw asterisks; ZENO does not).
struct PulseCoachSummaryPill: View {
    let summary: String
    let onExpand: () -> Void

    private var attributed: AttributedString {
        (try? AttributedString(markdown: summary,
                               options: AttributedString.MarkdownParsingOptions(
                                interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(summary)
    }

    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                PulseCoachAvatar(size: 36)
                Text(attributed)
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 64)
            .background {
                RoundedRectangle(cornerRadius: PulseTheme.Radius.menu, style: .continuous)
                    .fill(PulseTheme.Coach.pillFill)
                    .shadow(color: PulseTheme.Coach.pillGlow, radius: 18, x: 0, y: 0)
            }
            .overlay(
                RoundedRectangle(cornerRadius: PulseTheme.Radius.menu, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens Coach"))
    }
}

/// "◎ Analyzing…": the Coach button's pill form while the AI is generating.
struct PulseCoachAnalyzingPill: View {
    var body: some View {
        HStack(spacing: 8) {
            PulseCoachAvatar(size: 28)
            Text(String(localized: "Analyzing…"))
                .pulseText(.pillTitle)
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .padding(.leading, 10)
        .padding(.trailing, 16)
        .frame(height: 52)
        .background(Capsule(style: .continuous)
            .fill(LinearGradient(gradient: PulseTheme.Coach.buttonFill, startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(Capsule(style: .continuous)
            .strokeBorder(LinearGradient(gradient: PulseTheme.Coach.buttonRim, startPoint: .top, endPoint: .bottom),
                          lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// The coach accessory a pushed screen floats at its bottom edge, honouring the Coach's availability.
/// `PulseScreenScaffold(coach:)` places it; screens rarely use it directly.
struct PulseFloatingCoach: View {
    let accessory: PulseCoachAccessory
    /// The page context handed to the Coach when it opens from here.
    var seed: String?

    @Environment(\.pulseCoach) private var coach

    var body: some View {
        if coach.availability != .off {
            switch accessory {
            case .none:
                EmptyView()
            case .button:
                HStack {
                    Spacer()
                    PulseCoachButton(size: PulseTheme.TabBarMetrics.floatingCoachSize) { coach.open(seed) }
                }
                .padding(.horizontal, PulseTheme.TabBarMetrics.floatingCoachInset)
                .padding(.bottom, PulseTheme.TabBarMetrics.floatingCoachInset)
            case .pill(let summary):
                PulseCoachSummaryPill(summary: summary) { coach.open(seed ?? summary) }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.bottom, 8)
            }
        }
    }
}
#endif
