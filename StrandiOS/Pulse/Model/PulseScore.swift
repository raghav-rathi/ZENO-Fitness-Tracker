#if os(iOS)
import SwiftUI

/// The three headline scores, named once. Every Pulse label, dial and accessibility string that names a
/// score goes through `displayName`, so the interface cannot drift into calling one thing two names
/// (the classic shell's Charge / Recovery / "Rest HR" problem). The WHOOP-style path says Recovery /
/// Strain / Sleep everywhere and shows Strain on 0–21 (WHOOP_UI_SPEC §0.3).
enum PulseScore: String, CaseIterable, Identifiable, Hashable {
    /// Home order, as WHOOP lays out its dials: Sleep, Recovery, Strain.
    case sleep, recovery, strain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleep: return String(localized: "Sleep")
        case .recovery: return String(localized: "Recovery")
        case .strain: return String(localized: "Strain")
        }
    }

    /// The score's fixed colour. Recovery has none of its own: it is always drawn in its band colour
    /// (`PulseTheme.recovery(_:)`), so this returns the green only as a neutral fallback.
    var tint: Color {
        switch self {
        case .sleep: return PulseTheme.sleep
        case .recovery: return PulseTheme.recoveryHigh
        case .strain: return PulseTheme.strain
        }
    }

    var symbol: String {
        switch self {
        case .sleep: return "moon.fill"
        case .recovery: return "heart.fill"
        case .strain: return "flame.fill"
        }
    }

    /// The value a full circle stands for: 100% for Sleep and Recovery, 21 for Strain.
    var fullScale: Double { self == .strain ? 21 : 100 }
}
#endif
