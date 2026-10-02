#if os(iOS)
import SwiftUI

// MARK: - Motion (WHOOP_UI_SPEC §2.8, DR §8)
//
// Instant press feedback, native pushes, and animation only when DATA changes:
//   - a dial arc sweeps from its old value to the new one (0.7 s ease-out), never on every appear, so
//     it fills once when the first value lands and stays put on the way back from a deep dive;
//   - numbers use `.contentTransition(.numericText())`;
//   - the action menu scales from its anchor (0.2 s).
// No ambient motion: no loops, parallax or shimmer (skeletons excepted). Under Reduce Motion there are
// no sweeps and no numeric rolls; transitions become cross-fades. Animate only opacity, transform and
// trim, so every animation stays interruptible.

enum PulseMotion {
    /// A dial arc or bar moving to a new value.
    static let valueChange = Animation.easeOut(duration: 0.7)
    /// Releasing a press: the press state clears over 0.15 s (it appears instantly).
    static let pressRelease = Animation.easeOut(duration: 0.15)
    /// The action menu and other anchored popovers.
    static let menu = Animation.easeOut(duration: 0.2)
    /// Chrome appearing or leaving (the tab bar on push and pop, a pinned header).
    static let chrome = Animation.easeInOut(duration: 0.2)
    /// The cross-fade every transition becomes under Reduce Motion.
    static let crossFade = Animation.easeInOut(duration: 0.2)
    /// Sheet presentation easing (the classic shell's curve).
    static let sheet = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.42)
    /// Skeletons wait this long before appearing…
    static let skeletonDelay: Duration = .milliseconds(200)
    /// …and once shown stay at least this long, so a fast load never flashes.
    static let skeletonMinimum: Duration = .milliseconds(400)

    /// `animation`, or nil when Reduce Motion asks for no movement.
    static func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    /// A transition that slides and fades, or only fades under Reduce Motion.
    static func transition(_ edge: Edge, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: edge).combined(with: .opacity)
    }
}

/// Animates changes of `value` only (never the first appearance), and not at all under Reduce Motion.
private struct PulseValueAnimation<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(PulseMotion.resolved(animation, reduceMotion: reduceMotion), value: value)
    }
}

extension View {
    /// Animate this view when `value` changes, with `animation`, unless Reduce Motion is on.
    func pulseAnimation<V: Equatable>(_ animation: Animation = PulseMotion.valueChange, value: V) -> some View {
        modifier(PulseValueAnimation(animation: animation, value: value))
    }

    /// Numbers roll to their new value, except under Reduce Motion.
    func pulseNumericTransition() -> some View {
        modifier(PulseNumericTransition())
    }
}

private struct PulseNumericTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.contentTransition(.identity)
        } else {
            content.contentTransition(.numericText())
        }
    }
}
#endif
