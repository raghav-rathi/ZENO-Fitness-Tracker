#if os(iOS)
import SwiftUI
import Combine

// MARK: - Coach button and coach surfaces (WHOOP_UI_SPEC §1.1, §1.2)
//
// The Coach lives behind ONE floating button, never a tab:
//   - on a tab root it sits right of the tab capsule (64 × 64 squircle, 12 pt gap, 12 pt from the edge);
//   - on deep dives, Trend View, monitors, Activity Details and the like it floats alone in EXACTLY the same
//     spot (12 pt from the right edge, its bottom on the capsule's line, 28 pt above the screen edge), so
//     it never jumps on push (`PulseScreenScaffold(coach: .button)`, deep-dives-2026/57, reviews/r119),
//     and while the Coach writes a reply it becomes the "◎ Analyzing…" pill (help-center/82);
//   - on the Sleep / Recovery / Strain dives and Activity Details a summary pill stands in for it
//     (`coach: .pill(text)`): two lines summarising the page, "⌃" opening the Coach sheet, 12 pt side
//     margins on the same bottom line (deep-dives-2026/56).
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
///
/// Equal when the availability and the owner (`identity`) are: `open` always reaches the owner's current
/// state, so readers re-render only when the availability really changes.
struct PulseCoachContext: Equatable {
    var availability: PulseCoachAvailability = .off
    /// Open the Coach sheet (or setup), optionally seeded with the page's context.
    var open: (_ seed: String?) -> Void = { _ in }
    /// Who answers `open`: the shell, or one modal host.
    var identity: ObjectIdentifier?

    static func == (lhs: PulseCoachContext, rhs: PulseCoachContext) -> Bool {
        lhs.availability == rhs.availability && lhs.identity != nil && lhs.identity == rhs.identity
    }
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

/// The Coach button: a 64 pt indigo squircle (radius 24) lit from its top-leading edge, with ZENO's
/// monogram on a lit indigo orb inside a thin violet → blue ring (32 pt, 1.33 pt).
struct PulseCoachButton: View {
    var size: CGFloat = PulseTheme.TabBarMetrics.coachSize
    let action: () -> Void

    var body: some View {
        let scale = size / PulseTheme.TabBarMetrics.coachSize
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.coachButton * scale, style: .continuous)
        Button(action: action) {
            ZStack {
                shape.fill(LinearGradient(gradient: PulseTheme.Coach.buttonFill, startPoint: .topLeading,
                                          endPoint: .bottomTrailing))
                shape.strokeBorder(LinearGradient(gradient: PulseTheme.Coach.buttonRim, startPoint: .topLeading,
                                                  endPoint: .bottomTrailing), lineWidth: 1)
                PulseCoachAvatar(size: PulseTheme.TabBarMetrics.coachRing * scale)
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

/// The floating coach summary pill (2026): ≈64 pt, radius 22, a horizontal gradient from the avatar end
/// (#2E2D3F) to #252C34 with a faint top rim and no outer glow; the 32 pt coach avatar at the left, two lines
/// of 15 pt white text, and "⌃" at the right that expands into the Coach sheet. Markdown bold renders as
/// bold (WHOOP shows the raw asterisks; ZENO does not).
struct PulseCoachSummaryPill: View {
    let summary: String
    let onExpand: () -> Void

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = PulseTextStyle.rowText.spec.size

    /// The summary with its **bold** runs set in an explicit bold font: a run's own font is the only one
    /// a styled `Text` keeps (the style's Medium would otherwise flatten the emphasis).
    private var attributed: AttributedString {
        var text = (try? AttributedString(markdown: summary,
                                          options: AttributedString.MarkdownParsingOptions(
                                            interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(summary)
        let runs = text.runs.map { ($0.range, $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true) }
        for (range, strong) in runs {
            text[range].font = .system(size: textSize, weight: strong ? .bold : PulseTextStyle.rowText.spec.weight)
        }
        return text
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.coachPill, style: .continuous)
        Button(action: onExpand) {
            HStack(spacing: 12) {
                PulseCoachAvatar(size: 32)
                Text(attributed)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .background(shape.fill(LinearGradient(gradient: PulseTheme.Coach.pillFill, startPoint: .leading,
                                                  endPoint: .trailing)))
            .overlay(shape.strokeBorder(LinearGradient(gradient: PulseTheme.Coach.pillRim, startPoint: .top,
                                                       endPoint: .bottom), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityHint(String(localized: "Opens Coach"))
    }
}

/// "◎ Analyzing…": the floating Coach button's pill form while the AI is generating (help-center/82), at
/// the button's 64 pt height with its 32 pt ring where the button's sits, growing leftward.
struct PulseCoachAnalyzingPill: View {
    var body: some View {
        HStack(spacing: 10) {
            PulseCoachAvatar(size: PulseTheme.TabBarMetrics.coachRing)
            Text(String(localized: "Analyzing…"))
                .pulseText(.pillTitle)
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .padding(.leading, (PulseTheme.TabBarMetrics.floatingCoachSize - PulseTheme.TabBarMetrics.coachRing) / 2)
        .padding(.trailing, 20)
        .frame(height: PulseTheme.TabBarMetrics.floatingCoachSize)
        .background(Capsule(style: .continuous)
            .fill(LinearGradient(gradient: PulseTheme.Coach.buttonFill, startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(Capsule(style: .continuous)
            .strokeBorder(LinearGradient(gradient: PulseTheme.Coach.buttonRim, startPoint: .top, endPoint: .bottom),
                          lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// The Coach button a pushed screen floats, or the "◎ Analyzing…" pill in its place while the Coach writes a
/// reply. It redraws only when the Coach starts or stops writing (`PulseCoachWriting`), never per streamed
/// token, and nothing above it follows the engine.
struct PulseFloatingCoachButton: View {
    let action: () -> Void
    @StateObject private var writing = PulseCoachWriting()

    var body: some View {
        Group {
            if writing.isWriting {
                Button(action: action) { PulseCoachAnalyzingPill() }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "Coach, analyzing"))
                    .accessibilityHint(String(localized: "Opens Coach"))
            } else {
                PulseCoachButton(size: PulseTheme.TabBarMetrics.floatingCoachSize, action: action)
            }
        }
        .pulseAnimation(PulseMotion.crossFade, value: writing.isWriting)
        .background(PulseCoachWritingProbe(writing: writing))
    }
}

/// Whether the Coach is writing a reply (`AICoachEngine.sending`), settled: the flag must hold for 250 ms
/// before it changes, so a request that fails at once never flashes the pill. The one subscription lives
/// here, not in a view's `onReceive`: a view re-subscribes each time it redraws, an engine mid-reply
/// redraws its observers on every token, and the debounce would never fire.
@MainActor
private final class PulseCoachWriting: ObservableObject {
    @Published private(set) var isWriting = false
    private var subscription: AnyCancellable?

    /// Follow `engine`, once.
    func follow(_ engine: AICoachEngine) {
        guard subscription == nil else { return }
        isWriting = engine.sending
        subscription = engine.$sending
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] sending in
                guard let self, self.isWriting != sending else { return }
                self.isWriting = sending
            }
    }
}

/// Hands the environment's engine to `PulseCoachWriting`. It observes the engine only because reading an
/// environment object does, so it is a clear leaf whose per-token redraw costs nothing.
private struct PulseCoachWritingProbe: View {
    let writing: PulseCoachWriting
    @EnvironmentObject private var coach: AICoachEngine

    var body: some View {
        Color.clear
            .onAppear { writing.follow(coach) }
            .accessibilityHidden(true)
    }
}

/// The coach accessory a pushed screen floats at its bottom edge, honouring the Coach's availability.
/// `PulseScreenScaffold(coach:)` places it; screens rarely use it directly. Both forms ignore the bottom
/// safe area and sit on the tab capsule's line (`PulseChromeMetrics.barBottomFromScreenBottom`).
struct PulseFloatingCoach: View {
    let accessory: PulseCoachAccessory
    /// The page context handed to the Coach when it opens from here.
    var seed: String?

    @Environment(\.pulseCoach) private var coach
    @Environment(\.pulseChrome) private var chrome

    var body: some View {
        if coach.availability != .off && accessory != .none {
            // A flexible column, so ignoring the bottom safe area really reaches the screen's edge.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                switch accessory {
                case .none:
                    EmptyView()
                case .button:
                    HStack {
                        Spacer(minLength: 0)
                        PulseFloatingCoachButton { coach.open(seed) }
                    }
                    .padding(.trailing, PulseTheme.TabBarMetrics.floatingCoachInset)
                case .pill(let summary):
                    PulseCoachSummaryPill(summary: summary) { coach.open(seed ?? summary) }
                        .padding(.horizontal, PulseTheme.TabBarMetrics.pillSideMargin)
                }
            }
            .padding(.bottom, chrome.barBottomFromScreenBottom)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}
#endif
