#if os(iOS)
import SwiftUI
import UIKit
import Observation

// MARK: - Tilt mode (WHOOP_UI_SPEC §3.7)
//
// WHOOP turns its day heart-rate graph landscape when the phone is tilted, and opens it from Home the same
// way. ZENO's iPhone interface is portrait-only (the app declares only portrait, and every other screen
// expects it), so instead of rotating the whole interface the timeline reads the PHYSICAL orientation and
// lays itself out sideways, rotated to stay upright in the hand. Nothing else in the app rotates.
//
// `UIDevice` keeps reporting the physical orientation even though the interface stays portrait. When the
// wearer has Portrait Orientation Lock on it reports portrait, so the timeline stays in its portrait layout,
// which is the behaviour a locked phone should have.

/// The phone's physical orientation, as the timeline uses it.
enum PulseTiltOrientation: Equatable {
    case portrait
    /// Turned anticlockwise: the phone's top is on the LEFT (`UIDeviceOrientation.landscapeLeft`). The
    /// content turns clockwise to stay upright.
    case landscapeLeft
    /// Turned clockwise: the phone's top is on the right.
    case landscapeRight

    var isLandscape: Bool { self != .portrait }

    /// How far the content turns to read upright in the hand.
    var contentRotation: Angle {
        switch self {
        case .portrait: return .zero
        case .landscapeLeft: return .degrees(90)
        case .landscapeRight: return .degrees(-90)
        }
    }
}

/// Follows the phone's physical orientation while started. Face up, face down, upside down and unknown keep
/// the last orientation, so laying the phone on a table does not flip the layout.
@MainActor
@Observable
final class PulseTiltMonitor {
    private(set) var orientation: PulseTiltOrientation = .portrait

    @ObservationIgnored private var observer: NSObjectProtocol?

    func start() {
        guard observer == nil else { return }
        #if DEBUG
        // `--pulse-tilt left|right`: hold a landscape orientation for simulator captures (simctl cannot
        // rotate the device).
        if let forced = PulseTiltDebug.forced {
            orientation = forced
            return
        }
        #endif
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        apply(UIDevice.current.orientation)
        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.apply(UIDevice.current.orientation) }
        }
    }

    func stop() {
        guard let observer else { return }
        NotificationCenter.default.removeObserver(observer)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        self.observer = nil
    }

    private func apply(_ device: UIDeviceOrientation) {
        let next: PulseTiltOrientation
        switch device {
        case .portrait: next = .portrait
        case .landscapeLeft: next = .landscapeLeft
        case .landscapeRight: next = .landscapeRight
        default: return
        }
        if next != orientation { orientation = next }
    }
}

#if DEBUG
/// `--pulse-tilt left|right`: the timeline lays out as if the phone were turned (DEBUG only).
enum PulseTiltDebug {
    static var forced: PulseTiltOrientation? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--pulse-tilt"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "left": return .landscapeLeft
        case "right": return .landscapeRight
        default: return nil
        }
    }
}
#endif

// MARK: - Opening the timeline by tilting

/// The day timeline opened by turning the phone (tilt mode): full screen, and it closes itself when the
/// phone turns back upright. The ⤢ entry opens the plain `.dayTimeline` route, which stays open.
struct PulseTiltTimelineRoute: PulseScreenRoute {
    var presentation: PulsePresentation { .fullScreen }
    var view: some View { PulseDayTimelineView(closesWhenUpright: true) }
}

/// Opens the day timeline when the phone turns to landscape while the modified view is on screen.
private struct PulseTiltOpensTimeline: ViewModifier {
    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.scenePhase) private var scenePhase
    @State private var monitor = PulseTiltMonitor()
    @State private var onScreen = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                onScreen = true
                monitor.start()
            }
            .onDisappear {
                onScreen = false
                monitor.stop()
            }
            .onChange(of: monitor.orientation) { _, orientation in
                guard onScreen, scenePhase == .active, orientation.isLandscape else { return }
                navigator.open(PulseTiltTimelineRoute().route)
            }
    }
}

extension View {
    /// Tilt mode (§3.7): while this view is on screen, turning the phone sideways opens the day heart-rate
    /// timeline full screen, laid out landscape; turning it back upright closes it. Home's tab root applies
    /// it (the spec limits tilt detection to Home).
    func pulseDayTimelineOnTilt() -> some View {
        modifier(PulseTiltOpensTimeline())
    }
}
#endif
