#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Navigation API for screens
//
// Screens never reach into the shell. They open routes through the environment:
//
//     @Environment(\.pulseNavigator) private var navigator
//     Button { navigator.open(.sleepPlanner) } label: { … }
//
// or, for a row that is itself the link (push routes stay value links, so a tab re-tap pops them):
//
//     PulseLink(.healthMonitor) { PulseMetricRow(…) }
//         .buttonStyle(PulsePressStyle())

/// Opens routes. Injected by the shell for each tab and replaced inside every modal stack.
///
/// Equal when `identity` is: the closures always reach the same owner's current state, so a reader of
/// `\.pulseNavigator` is not invalidated each time the shell re-renders (a push, a sheet, a router change).
struct PulseNavigator: Equatable {
    /// Open `route` the way the spec presents it: push, sheet or full screen (`PulseRoute.presentation`).
    var open: (PulseRoute) -> Void = { _ in }
    /// Push `route` onto the current stack, whatever its usual presentation.
    var push: (PulseRoute) -> Void = { _ in }
    /// Present `route` modally in its own stack, whatever its usual presentation.
    var present: (PulseRoute) -> Void = { _ in }
    /// Run a ＋ menu action (the menu itself, or one of its screens).
    var quickAction: (PulseQuickAction) -> Void = { _ in }
    /// Who answers: the shell, or one modal host.
    var identity: ObjectIdentifier?

    static func == (lhs: PulseNavigator, rhs: PulseNavigator) -> Bool {
        lhs.identity != nil && lhs.identity == rhs.identity
    }
}

private struct PulseNavigatorKey: EnvironmentKey {
    static let defaultValue = PulseNavigator()
}

extension EnvironmentValues {
    var pulseNavigator: PulseNavigator {
        get { self[PulseNavigatorKey.self] }
        set { self[PulseNavigatorKey.self] = newValue }
    }
}

/// A link to a route: a value `NavigationLink` for push routes (so the path tracks it), a button that
/// asks the shell to present it otherwise. Style it like any button.
struct PulseLink<Label: View>: View {
    let route: PulseRoute
    @ViewBuilder var label: () -> Label

    @Environment(\.pulseNavigator) private var navigator

    init(_ route: PulseRoute, @ViewBuilder label: @escaping () -> Label) {
        self.route = route
        self.label = label
    }

    var body: some View {
        if route.presentation == .push {
            if case .tab(let tab) = route {
                // The raw value, which `tabRouteDestinations()` maps (see `NavigationPath.appendPulse`).
                NavigationLink(value: tab) { label() }
            } else {
                NavigationLink(value: route) { label() }
            }
        } else {
            Button { navigator.open(route) } label: { label() }
        }
    }
}

/// The ＋ actions and the screens they open.
enum PulseQuickAction: String, Identifiable {
    case menu, live, workout, addActivity, liftLog, intervals, breathe, journal
    var id: String { rawValue }

    /// The route an action opens, honouring the rebuild flags (the menu itself has none).
    var route: PulseRoute? {
        switch self {
        case .menu: return nil
        case .live: return .classic(.live)
        case .workout: return PulseRoute.startActivity.forExistingEntryPoint
        case .addActivity: return PulseRoute.addActivity.forExistingEntryPoint
        case .liftLog: return PulseRoute.strengthTrainer.forExistingEntryPoint
        case .intervals: return .classic(.intervals)
        case .breathe: return .classic(.breathe)
        case .journal: return PulseRoute.journal(dayOffset: nil).forExistingEntryPoint
        }
    }
}

/// A route presented modally: its own NavigationStack and path, its root marked as a modal root (so a
/// Pulse screen shows "✕"), "Done" for a classic screen, and a navigator that pushes inside the modal.
/// The shell cannot present over its own modal, so the Coach sheet and the ＋ sheet open from here while
/// one is up, and a ＋ action's screen is pushed inside the modal rather than replacing it.
struct PulseModalHost: View {
    let route: PulseRoute

    @State private var path = NavigationPath()
    @State private var coachSheet: PulseCoachSeed?
    @State private var showsActions = false
    @State private var token = PulseIdentityToken()
    @Environment(\.pulseCoach) private var parentCoach
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack(path: $path) {
            root
                .pulseDestinations()
        }
        .environment(\.pulseNavigator, PulseNavigator(
            open: { open($0) },
            push: { open($0) },
            present: { open($0) },
            quickAction: { quickAction($0) },
            identity: ObjectIdentifier(token)))
        .environment(\.pulseCoach, PulseCoachContext(availability: parentCoach.availability,
                                                     open: { seed in openCoach(seed) },
                                                     identity: ObjectIdentifier(token)))
        // No action-menu host in a modal: the "+" falls back to the ＋ sheet, from here.
        .environment(\.pulseActionMenu, PulseActionMenuContext())
        .sheet(item: $coachSheet) { PulseCoachSheet(seed: $0.seed) }
        .sheet(isPresented: $showsActions) {
            PulseActionSheet(onPick: { picked in
                showsActions = false
                if let route = picked.route { open(route) }
            }, onClose: { showsActions = false })
        }
        .tint(PulseTheme.chromeTint)
    }

    private func open(_ route: PulseRoute) {
        if case .coach(let seed) = route {
            openCoach(seed)
        } else {
            path.appendPulse(route)
        }
    }

    /// Inside a modal a ＋ action pushes its screen here; the menu itself opens as this modal's sheet.
    private func quickAction(_ action: PulseQuickAction) {
        if let route = action.route {
            open(route)
        } else {
            showsActions = true
        }
    }

    private func openCoach(_ seed: String?) {
        guard parentCoach.availability != .off else { return }
        coachSheet = PulseCoachSeed(seed: seed)
    }

    @ViewBuilder
    private var root: some View {
        if route.isClassic {
            route.destination
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "Done")) { dismiss() }
                            .foregroundStyle(PulseTheme.accent)
                    }
                }
        } else {
            route.destination
                .environment(\.pulseModalRoot, true)
        }
    }
}

/// A stable object whose identity names one owner of a navigator or coach context.
final class PulseIdentityToken {}

/// The Coach sheet's presentation, identified once per opening.
struct PulseCoachSeed: Identifiable {
    let id = UUID()
    let seed: String?
}

/// A sheet or cover the shell presents. Identified by route, so presenting the same route twice is one
/// presentation.
struct PulseModal: Identifiable {
    let route: PulseRoute
    var id: String { String(describing: route) }
}
#endif
