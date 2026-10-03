import Foundation

/// The names the app gives its three daily scores, and the scale it shows the strain score on.
///
/// NOOP's classic interface says Charge, Effort (0-100) and Rest. The iPhone's Pulse interface, ZENO's
/// WHOOP-structured shell, says Recovery, Strain (0-21) and Sleep, and the spec requires one vocabulary on
/// that path, including on the classic screens it still links to (docs/zeno/WHOOP_UI_SPEC.md §0.3). The
/// data is the same either way: Strain is the stored Effort rescaled for display
/// (`UnitFormatter.effortValue(_:scale: .whoop)`).
///
/// Read it at render time (`ScoreVocabulary.current`), so switching interfaces takes effect on the next
/// render. Classic copy keeps its own localized literal and the Pulse form is a second literal beside it
/// (`pick(classic:pulse:)`), so the classic keys, and their translations, stay exactly as they were.
enum ScoreVocabulary: Equatable {
    case classic
    case pulse

    /// The iPhone's interface switch (`@AppStorage("pulse.enabled")` in StrandiOSApp).
    static let pulseEnabledKey = "pulse.enabled"

    /// The vocabulary of the interface the app runs: Pulse on an iPhone while `pulse.enabled` is on, classic
    /// otherwise, and always on the Mac, which has only the classic interface.
    static var current: ScoreVocabulary {
        #if os(iOS)
        return resolve(UserDefaults.standard)
        #else
        return .classic
        #endif
    }

    /// The iPhone rule, on its own for tests. An unset key reads as ON, as StrandiOSApp's `@AppStorage`
    /// defaults it: `bool(forKey:)` alone answers false for a key never written, which would give every
    /// install that never touched the switch the classic names under the Pulse screens.
    static func resolve(_ defaults: UserDefaults) -> ScoreVocabulary {
        guard defaults.object(forKey: pulseEnabledKey) != nil else { return .pulse }
        return defaults.bool(forKey: pulseEnabledKey) ? .pulse : .classic
    }

    /// The classic or the Pulse form of a piece of copy. Give each form as its own localized literal at the
    /// call site, so the extractor sees both and the classic key stays byte-identical.
    func pick<T>(classic: @autoclosure () -> T, pulse: @autoclosure () -> T) -> T {
        self == .pulse ? pulse() : classic()
    }

    /// `current.pick(classic:pulse:)`.
    static func pick<T>(classic: @autoclosure () -> T, pulse: @autoclosure () -> T) -> T {
        current.pick(classic: classic(), pulse: pulse())
    }

    /// The recovery score's name: "Charge" in the classic interface, "Recovery" in Pulse.
    var recovery: String { pick(classic: String(localized: "Charge"), pulse: String(localized: "Recovery")) }

    /// The strain score's name: "Effort" in the classic interface, "Strain" in Pulse.
    var strain: String { pick(classic: String(localized: "Effort"), pulse: String(localized: "Strain")) }

    /// The sleep score's name: "Rest" in the classic interface, "Sleep" in Pulse.
    var sleep: String { pick(classic: String(localized: "Rest"), pulse: String(localized: "Sleep")) }

    /// The strain scale this vocabulary insists on, if any: Pulse shows Strain on WHOOP's 0-21 axis
    /// everywhere (§0.3), whatever the classic "Effort scale" setting says. Classic leaves the setting in charge.
    var forcedEffortScale: EffortScale? { self == .pulse ? .whoop : nil }

    /// The app's own name in copy. It follows the build, not the shell: the iPhone app is ZENO in both of
    /// its interfaces (its home-screen name), the Mac app is still NOOP.
    static var appName: String {
        #if os(iOS)
        return "ZENO"
        #else
        return "NOOP"
        #endif
    }
}
