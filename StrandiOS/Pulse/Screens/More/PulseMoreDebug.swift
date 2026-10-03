#if os(iOS) && DEBUG
import Foundation

/// DEBUG `--more-open <name>`: open one of group more-profile's own sub-screens at launch, so `simctl`
/// (which cannot tap) can capture it. The screen that owns the sub-screen takes the name once, when it
/// first appears: `--pulse-route profile --more-open edit-profile`, `--pulse-route app-settings
/// --more-open units`, `--pulse-route achievements --more-open badge:greenLight`. Stripped from Release.
@MainActor
enum PulseMoreDebug {
    private static var taken = false

    /// The requested name when it starts with one of `prefixes` and has not been taken yet.
    static func take(prefixes: [String]) -> String? {
        guard !taken else { return nil }
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--more-open"), i + 1 < args.count else { return nil }
        let name = args[i + 1]
        guard prefixes.contains(where: { name.hasPrefix($0) }) else { return nil }
        taken = true
        return name
    }

    /// True when the launch asks for a state flag (`--more-first-week`, …).
    static func flag(_ name: String) -> Bool { CommandLine.arguments.contains(name) }
}
#endif
