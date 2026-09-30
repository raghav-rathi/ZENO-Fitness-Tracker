#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Pulse
//
// Pulse is ZENO's WHOOP-style iPhone interface: Home · Health · Coach · More, three score dials, deep
// dives behind each dial, and a near-black visual system. It is a separate layer over the same data the
// classic shell reads. Everything it renders comes from immutable snapshots built off the main actor
// (`PulseSnapshotBuilder`) and published by one small model (`PulseModel`); its views never query the
// store. Upstream screens are reused by linking to them, never forked.
//
// This file holds the vocabulary and the visual tokens. They are Pulse's own on purpose: the classic
// shell keeps `StrandPalette`, and a shared token changed here would silently re-colour every upstream
// screen as well.

/// The three headline scores, named once. Every Pulse label, dial and accessibility string that names a
/// score goes through `displayName`, so the interface cannot drift into calling one thing two names
/// (the classic shell's Charge / Recovery / "Rest HR" problem).
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
        case .recovery: return PulseTheme.recoveryGreen
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
}

/// Pulse's colours, type and geometry.
enum PulseTheme {

    // MARK: Surfaces

    /// Top of the page gradient.
    static let backgroundTop = Color(hex: "#101518")
    /// Bottom of the page gradient.
    static let backgroundBottom = Color(hex: "#000000")
    /// Cards sit one step lighter than the page.
    static let card = Color(hex: "#161C20")
    /// A raised element inside a card (a chip, a pressed row).
    static let cardRaised = Color(hex: "#1F272C")
    /// Hairline card borders and row separators.
    static let hairline = Color.white.opacity(0.09)
    /// The thin full-circle track behind a dial arc, and the empty part of a bar.
    static let track = Color.white.opacity(0.12)

    // MARK: Text
    //
    // Measured against `card` (#161C20): primary ~17:1, secondary ~10:1, tertiary ~6.4:1. All clear the
    // 4.5:1 floor for body text, including tertiary, which the classic grey (3.5:1) did not.

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.74)
    static let textTertiary = Color.white.opacity(0.58)

    // MARK: Scores (WHOOP's published brand values; this build is private to its owner)

    static let recoveryGreen = Color(hex: "#16EC06")
    static let recoveryYellow = Color(hex: "#FFDE00")
    static let recoveryRed = Color(hex: "#FF0026")
    /// The brand red measures 4.47:1 on a card, a hair under the text floor. Arcs and bars keep the
    /// brand value; text drawn in red uses this lighter red (5.4:1) instead.
    static let recoveryRedText = Color(hex: "#FF4A5C")
    static let strain = Color(hex: "#0093E7")
    static let sleep = Color(hex: "#7BA1BB")
    /// Interactive chrome: buttons, links, the selected tab.
    static let accent = Color(hex: "#00F19F")
    /// Ink placed ON an accent fill.
    static let onAccent = Color(hex: "#04140E")
    /// A value outside its typical range. Yellow reads as "look at this" without claiming an emergency.
    static let attention = recoveryYellow

    /// The recovery band's colour, for arcs, bars and fills.
    static func recovery(_ band: PulseDisplay.RecoveryBand) -> Color {
        switch band {
        case .green: return recoveryGreen
        case .yellow: return recoveryYellow
        case .red: return recoveryRed
        }
    }

    /// The recovery band's colour for TEXT (red swaps to its legible variant).
    static func recoveryText(_ band: PulseDisplay.RecoveryBand) -> Color {
        band == .red ? recoveryRedText : recovery(band)
    }

    /// Heart-rate zone colours, zone 1 to 5, cool to hot.
    static let zones: [Color] = [
        Color(hex: "#7E8A94"),
        Color(hex: "#0093E7"),
        Color(hex: "#16C47F"),
        Color(hex: "#FFB020"),
        Color(hex: "#FF4A5C"),
    ]

    static func zone(_ number: Int) -> Color {
        zones[max(1, min(5, number)) - 1]
    }

    /// Sleep-stage colours, chosen to sit beside the sleep blue-grey.
    static func stage(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return Color(hex: "#C9D1D9")
        case .light: return Color(hex: "#7BA1BB")
        case .deep: return Color(hex: "#4F6BFF")
        case .rem: return Color(hex: "#A98BFF")
        }
    }

    // MARK: Geometry

    static let pagePadding: CGFloat = 16
    static let cardRadius: CGFloat = 18
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 22
    static let minTapTarget: CGFloat = 44

    // MARK: Type

    /// Big condensed bold numerals with tabular digits: the WHOOP read, without its licensed faces.
    static func numeral(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).width(.condensed).monospacedDigit()
    }

    /// Small uppercase tracked labels. A text style, so it follows Dynamic Type.
    static let label = Font.caption.weight(.semibold)
    static let labelTracking: CGFloat = 1.1
}

// MARK: - Shared pieces

/// The page background: the near-black gradient, edge to edge.
struct PulseBackground: View {
    var body: some View {
        LinearGradient(colors: [PulseTheme.backgroundTop, PulseTheme.backgroundBottom],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

/// A card: one step lighter than the page, hairline border, continuous corners.
struct PulseCard<Content: View>: View {
    var padding: CGFloat = PulseTheme.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PulseCardSurface())
    }
}

/// The card's fill and border on their own, for rows that are buttons or links themselves.
struct PulseCardSurface: View {
    var radius: CGFloat = PulseTheme.cardRadius
    var fill: Color = PulseTheme.card

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(PulseTheme.hairline, lineWidth: 1)
            )
    }
}

/// A small uppercase tracked label.
struct PulseLabel: View {
    let text: String
    var color: Color = PulseTheme.textTertiary

    init(_ text: String, color: Color = PulseTheme.textTertiary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(PulseTheme.label)
            .tracking(PulseTheme.labelTracking)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

/// A section title with an optional trailing label.
struct PulseSectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            PulseLabel(title, color: PulseTheme.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Press feedback without animation loops: a brief dim while the finger is down.
struct PulsePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.62 : 1)
            .contentShape(Rectangle())
    }
}

/// A trailing disclosure chevron for tappable rows.
struct PulseChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(PulseTheme.textTertiary)
            .accessibilityHidden(true)
    }
}

/// A compact text chip (e.g. "Today", a band word).
struct PulseChip: View {
    let text: String
    var tint: Color = PulseTheme.textSecondary
    var filled = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(filled ? PulseTheme.onAccent : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? tint : PulseTheme.cardRaised)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(filled ? Color.clear : PulseTheme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    /// The standard Pulse page: gradient background, forced dark, no system nav-bar fill.
    func pulsePage() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(PulseBackground())
            .toolbarBackground(.hidden, for: .navigationBar)
            .environment(\.colorScheme, .dark)
    }
}
#endif
