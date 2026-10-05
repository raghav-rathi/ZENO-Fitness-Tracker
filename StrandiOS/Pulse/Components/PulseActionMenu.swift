#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Action (+) menu (WHOOP_UI_SPEC §1.3, §3.2)
//
// The "+" on the right of "My Day" opens a popover card anchored to it, and the "+" morphs into "✕" on a
// dark square:
//   - card: radius 20, vertical gradient #464D56 → #32383D, 16 pt from the screen edge, right-aligned to
//     the button; it drops down below the button, or opens upward (rows mirrored, START ACTIVITY still
//     nearest the button) when only the room above fits it. Where neither does, it opens toward the
//     larger room, held inside the safe area over the button, with the "✕" on top;
//   - rows on a 52 pt pitch, no dividers: a 28 pt line icon at white 70% and an UPPERCASE Bold 13 pt label
//     tracked 10%; START ACTIVITY · ADD ACTIVITY · STRENGTH TRAINER · COMPLETE YOUR JOURNAL · CREATE ZENO
//     LIVE, a hairline, then ZENO's two extras BREATHE · MARK MOMENT;
//   - the page behind dims slightly (#14171C at 55%); a tap outside or on "✕" closes it;
//   - it scales and fades from its anchor over 0.2 s (a cross-fade under Reduce Motion).
//
// The shell hosts the card above everything (`PulseActionMenuHost`) and hands screens the opener through
// `\.pulseActionMenu`. Where no host is listening (inside a modal), the "+" falls back to the ＋ sheet.

/// One row of the action menu.
enum PulseActionMenuItem: String, CaseIterable, Identifiable {
    case startActivity, addActivity, strengthTrainer, journal, zenoLive, breathe, markMoment

    var id: String { rawValue }

    /// The spec's rows, then ZENO's extras after the hairline.
    static let primary: [PulseActionMenuItem] = [.startActivity, .addActivity, .strengthTrainer, .journal, .zenoLive]
    static let extras: [PulseActionMenuItem] = [.breathe, .markMoment]

    var title: String {
        switch self {
        case .startActivity: return String(localized: "Start activity")
        case .addActivity: return String(localized: "Add activity")
        case .strengthTrainer: return String(localized: "Strength Trainer")
        case .journal: return String(localized: "Complete your journal")
        case .zenoLive: return String(localized: "Create ZENO Live")
        case .breathe: return String(localized: "Breathe")
        case .markMoment: return String(localized: "Mark moment")
        }
    }

    /// The spec's stopwatch, bare plus, weight-lifter, notebook-and-pencil and camera (§1.3, reviews/03).
    /// SF Symbols has no notebook with a pencil; the journal keeps the page-and-pencil Pulse uses for it
    /// everywhere else.
    var symbol: String {
        switch self {
        case .startActivity: return "stopwatch"
        case .addActivity: return "plus"
        case .strengthTrainer: return "figure.strengthtraining.traditional"
        case .journal: return "square.and.pencil"
        case .zenoLive: return "camera"
        case .breathe: return "wind"
        case .markMoment: return "mappin.and.ellipse"
        }
    }

    /// The quick action the row runs; Mark moment acts in place and has none.
    var quickAction: PulseQuickAction? {
        switch self {
        case .startActivity: return .workout
        case .addActivity: return .addActivity
        case .strengthTrainer: return .liftLog
        case .journal: return .journal
        case .zenoLive: return .zenoLive
        case .breathe: return .breathe
        case .markMoment: return nil
        }
    }
}

/// How a screen opens the action menu: the shell's host listens; nil where none does.
struct PulseActionMenuContext: Equatable {
    /// Open the menu anchored to `anchor`, a frame in the window's coordinates.
    var open: ((CGRect) -> Void)?
    /// Who listens (the shell); equal contexts open the same menu.
    var identity: ObjectIdentifier?

    static func == (lhs: PulseActionMenuContext, rhs: PulseActionMenuContext) -> Bool {
        lhs.identity == rhs.identity && (lhs.open == nil) == (rhs.open == nil)
    }
}

private struct PulseActionMenuContextKey: EnvironmentKey {
    static let defaultValue = PulseActionMenuContext()
}

extension EnvironmentValues {
    var pulseActionMenu: PulseActionMenuContext {
        get { self[PulseActionMenuContextKey.self] }
        set { self[PulseActionMenuContextKey.self] = newValue }
    }
}

/// The "+" that opens the action menu anchored to itself (or the ＋ sheet where no host listens).
struct PulseActionMenuButton: View {
    @Environment(\.pulseActionMenu) private var menu
    @Environment(\.pulseNavigator) private var navigator
    @ScaledMetric(relativeTo: .title3) private var side: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            Button {
                if let open = menu.open {
                    open(geo.frame(in: .global))
                } else {
                    navigator.quickAction(.menu)
                }
            } label: {
                PulsePlusSquare()
            }
            .buttonStyle(PulsePressStyle())
            #if DEBUG
            // `--pulse-sheet menu`: open the anchored menu once Home has settled, for a screenshot.
            .task {
                guard PulseDebugLaunch.sheet == "menu", let open = menu.open else { return }
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                open(geo.frame(in: .global))
            }
            #endif
        }
        .frame(width: side, height: side)
        .accessibilityLabel(String(localized: "Start or add an activity"))
        .accessibilityHint(String(localized: "Opens a menu"))
    }
}

/// The open menu, drawn by the shell above everything: the dim, the "✕" square over the "+", the card.
struct PulseActionMenuHost: View {
    /// The "+" button's frame in window coordinates.
    let anchor: CGRect
    let onPick: (PulseActionMenuItem) -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// Rows plus the hairline, padded: what the card needs below (or above) the button.
    private static let estimatedHeight = CGFloat(PulseActionMenuItem.allCases.count) * 52 + 17 + 16

    var body: some View {
        // The reader keeps to the safe area, so the card is placed clear of the status bar, the Dynamic
        // Island and the home indicator; only the dim reaches the screen's edges.
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            let local = anchor.offsetBy(dx: -origin.x, dy: -origin.y)
            let placement = Placement.resolve(anchor: local, height: geo.size.height,
                                              cardHeight: Self.estimatedHeight)
            ZStack(alignment: .topLeading) {
                PulseTheme.menuDim
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { onClose() }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(String(localized: "Close menu"))

                card(opensUp: placement.opensUp)
                    .scaleEffect(shown || reduceMotion ? 1 : 0.85,
                                 anchor: placement.opensUp ? .bottomTrailing : .topTrailing)
                    .opacity(shown ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: placement.alignment)
                    .padding(.trailing, PulseTheme.Layout.pageMargin)
                    .padding(.top, placement.top)
                    .padding(.bottom, placement.bottom)

                // Drawn after the card, so it stays on top where a held card covers the "+".
                Button(action: onClose) {
                    PulsePlusSquare(isClose: true)
                }
                .buttonStyle(PulsePressStyle())
                .position(x: local.midX, y: local.midY)
                .accessibilityLabel(String(localized: "Close menu"))
            }
        }
        .onAppear {
            withAnimation(PulseMotion.resolved(PulseMotion.menu, reduceMotion: reduceMotion) ?? .linear(duration: 0)) {
                shown = true
            }
        }
        .environment(\.colorScheme, .dark)
    }

    /// Where the card sits, in the safe area's coordinates: its row order, the corner it is held by, and
    /// that corner's distance from the safe area's top or bottom edge.
    private struct Placement {
        var opensUp: Bool
        var alignment: Alignment
        var top: CGFloat = 0
        var bottom: CGFloat = 0

        /// Below the "+" where the card fits (8 pt from it and from the safe area's edge), else above it
        /// where it fits, rows mirrored. Where it fits neither way, it opens toward the larger room and is
        /// held 8 pt inside the safe area, over the "+".
        ///
        /// - Parameters:
        ///   - anchor: the "+" in the safe area's coordinates.
        ///   - height: the safe area's height.
        ///   - cardHeight: the card's height.
        static func resolve(anchor: CGRect, height: CGFloat, cardHeight: CGFloat) -> Placement {
            let gap: CGFloat = 8
            let roomBelow = height - gap - (anchor.maxY + gap)
            let roomAbove = anchor.minY - gap - gap
            if cardHeight <= roomBelow {
                return Placement(opensUp: false, alignment: .topTrailing, top: anchor.maxY + gap)
            }
            if cardHeight <= roomAbove {
                return Placement(opensUp: true, alignment: .bottomTrailing, bottom: height - anchor.minY + gap)
            }
            return roomBelow >= roomAbove
                ? Placement(opensUp: false, alignment: .bottomTrailing, bottom: gap)
                : Placement(opensUp: true, alignment: .topTrailing, top: gap)
        }
    }

    private func card(opensUp: Bool) -> some View {
        let primary = opensUp ? Array(PulseActionMenuItem.primary.reversed()) : PulseActionMenuItem.primary
        let extras = opensUp ? Array(PulseActionMenuItem.extras.reversed()) : PulseActionMenuItem.extras
        return VStack(alignment: .leading, spacing: 0) {
            if opensUp {
                ForEach(extras) { row($0) }
                hairline
                ForEach(primary) { row($0) }
            } else {
                ForEach(primary) { row($0) }
                hairline
                ForEach(extras) { row($0) }
            }
        }
        .padding(.vertical, 8)
        .fixedSize(horizontal: true, vertical: false)
        // A popover hugging its longest row: past xLarge "COMPLETE YOUR JOURNAL" would outgrow the screen.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.menu, style: .continuous)
            .fill(LinearGradient(colors: [PulseTheme.menuTop, PulseTheme.menuBottom], startPoint: .top,
                                 endPoint: .bottom)))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var hairline: some View {
        Rectangle()
            .fill(PulseTheme.divider)
            .frame(height: 1)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func row(_ item: PulseActionMenuItem) -> some View {
        if item == .markMoment {
            PulseMarkMomentMenuRow(onDone: onClose)
        } else if item == .startActivity {
            PulseStartActivityMenuRow { onPick(item) }
        } else {
            Button { onPick(item) } label: {
                PulseActionMenuRowLabel(title: item.title, symbol: item.symbol)
            }
            .buttonStyle(PulsePressStyle())
        }
    }
}

/// A menu row's look: a 28 pt line icon at white 70% and the UPPERCASE label, on a 52 pt pitch.
struct PulseActionMenuRowLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .light))
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            Text(title)
                .pulseText(.menuLabel)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 52, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// START ACTIVITY, or RESUME ACTIVITY while a workout runs [Z]. Its own leaf because it needs `AppModel`,
/// which publishes every heart-rate tick.
private struct PulseStartActivityMenuRow: View {
    let action: () -> Void
    @EnvironmentObject private var app: AppModel

    var body: some View {
        Button(action: action) {
            PulseActionMenuRowLabel(title: app.activeWorkout == nil ? PulseActionMenuItem.startActivity.title
                                                                    : String(localized: "Resume activity"),
                                    symbol: PulseActionMenuItem.startActivity.symbol)
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// MARK MOMENT acts in place: a buzz on the strap, a check here, then the menu closes.
private struct PulseMarkMomentMenuRow: View {
    let onDone: () -> Void
    @EnvironmentObject private var app: AppModel
    @State private var marked = false

    var body: some View {
        Button {
            app.markMoment()
            marked = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onDone() }
        } label: {
            PulseActionMenuRowLabel(title: marked ? String(localized: "Moment marked")
                                                  : PulseActionMenuItem.markMoment.title,
                                    symbol: marked ? "checkmark" : PulseActionMenuItem.markMoment.symbol)
        }
        .buttonStyle(PulsePressStyle())
        .sensoryFeedback(.success, trigger: marked)
        .accessibilityHint(String(localized: "Records the current time as a moment"))
    }
}
#endif
