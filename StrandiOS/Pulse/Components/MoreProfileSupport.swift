#if os(iOS)
import SwiftUI
import UIKit
import WhoopStore

// MARK: - Support for the More and Profile pages (group "more-profile")
//
// Pieces the group's screens share that the foundation's catalogue does not carry:
//   - `.profileFont(…)`: a size of the group's own that still scales with Dynamic Type (DR §2: every word
//     scales; only numerals inside art stay fixed);
//   - `MoreWordWrapLabel`: the row-label type, wrapped between words only (DR §2, no "INTEGRATION / S");
//   - `MoreStrapRegistry`: which registry rows are straps the wearer actually paired;
//   - `MoreSwitchStyle`: WHOOP's settings switch, grey knob on a grey track when off;
//   - `ProfileSharePresenter`: the system share sheet for an image rendered on demand.

// MARK: - Scaled fonts

/// A font at one of the group's own sizes that scales with Dynamic Type relative to `relativeTo`, never
/// below DR's 11 pt floor. Caps and tracking follow the size, like `PulseTextStyle`.
struct ProfileScaledFont: ViewModifier {
    private let size: CGFloat
    private let weight: Font.Weight
    private let condensed: Bool
    private let tracking: CGFloat
    private let uppercase: Bool
    @ScaledMetric private var scaled: CGFloat

    init(size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle, condensed: Bool = false,
         tracking: CGFloat = 0, uppercase: Bool = false) {
        self.size = size
        self.weight = weight
        self.condensed = condensed
        self.tracking = tracking
        self.uppercase = uppercase
        _scaled = ScaledMetric(wrappedValue: size, relativeTo: relativeTo)
    }

    func body(content: Content) -> some View {
        let points = max(11, scaled)
        let base = Font.system(size: points, weight: weight)
        return content
            .font(condensed ? base.width(.condensed).monospacedDigit() : base)
            .tracking(tracking * points / size)
            .textCase(uppercase ? .uppercase : nil)
    }
}

extension View {
    /// Text at `size` pt that scales with Dynamic Type (relative to `relativeTo`).
    func profileFont(_ size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle, condensed: Bool = false,
                     tracking: CGFloat = 0, uppercase: Bool = false) -> some View {
        modifier(ProfileScaledFont(size: size, weight: weight, relativeTo: relativeTo, condensed: condensed,
                                   tracking: tracking, uppercase: uppercase))
    }
}

// MARK: - Labels that never break inside a word

/// The UPPERCASE row-label type (`MoreLabelText`) set on one line when it fits, otherwise wrapped between
/// words only; a single word too wide for its line shrinks with the others rather than splitting (DR §2:
/// "Never break a word mid-wrap", WHOOP's own "RECOMMENDE / D BEDTIME" bug). Built on the foundation's
/// `PulseWordFlow`, as `PulseWordWrapText` is for the shared styles.
struct MoreWordWrapLabel: View {
    let text: String
    var tracking: CGFloat
    var alignment: HorizontalAlignment
    @ScaledMetric private var wordSpace: CGFloat

    init(_ text: String, tracking: CGFloat = 0.95, alignment: HorizontalAlignment = .leading) {
        self.text = text
        self.tracking = tracking
        self.alignment = alignment
        // A space at the label's 12.3 pt, plus the tracking that follows it.
        _wordSpace = ScaledMetric(wrappedValue: 12.3 * 0.28 + tracking, relativeTo: .footnote)
    }

    private var words: [String] {
        text.uppercased().split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(text)
                .modifier(MoreLabelText(tracking: tracking))
                .lineLimit(1)
            PulseWordFlow(alignment: alignment, spacing: wordSpace, lineSpacing: 2) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Text(word)
                        .modifier(MoreLabelText(tracking: tracking))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// Text at one of the group's own sizes (`profileFont`) with the same rule: one line when it fits, else
/// wrapped between words only, a single over-long word shrinking with the rest ("Peak Recovery" under a
/// highlight ring at the accessibility sizes, never "Peak Recov…" or "Recov / ery").
struct ProfileWordWrapText: View {
    let text: String
    let size: CGFloat
    let weight: Font.Weight
    let relativeTo: Font.TextStyle
    var alignment: HorizontalAlignment
    @ScaledMetric private var wordSpace: CGFloat

    init(_ text: String, size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle,
         alignment: HorizontalAlignment = .center) {
        self.text = text
        self.size = size
        self.weight = weight
        self.relativeTo = relativeTo
        self.alignment = alignment
        _wordSpace = ScaledMetric(wrappedValue: size * 0.28, relativeTo: relativeTo)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(text)
                .profileFont(size, weight: weight, relativeTo: relativeTo)
                .lineLimit(1)
            PulseWordFlow(alignment: alignment, spacing: wordSpace, lineSpacing: 1) {
                ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, word in
                    Text(String(word))
                        .profileFont(size, weight: weight, relativeTo: relativeTo)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

// MARK: - Which straps are paired

/// The device registry as the wearer knows it. A fresh install carries one row it never paired: migration
/// v15 seeds an active "my-whoop" WHOOP row so old samples keep an owner, and that row adopts a strap's
/// identity (`peripheralId`) only on the first connect (`SourceCoordinator.connectedPeripheralChanged`).
/// Until then it stands for no strap, so the pages say "No strap paired" and offer pairing rather than
/// renaming, unpairing or firmware-checking a WHOOP 4.0 that was never there.
enum MoreStrapRegistry {
    /// The never-adopted placeholder: a WHOOP Bluetooth row with no strap identity. Rows without a
    /// Bluetooth identity by design (an Apple Watch through HealthKit, an import) are not placeholders.
    static func isUnadoptedPlaceholder(_ device: PairedDevice) -> Bool {
        if demoStandsInForAStrap { return false }
        return device.sourceKind == .liveBLE && SourceIdentity.isWhoop(device) && device.peripheralId == nil
    }

    /// The active device the wearer paired, if any.
    static func active(in devices: [PairedDevice]) -> PairedDevice? {
        devices.first { $0.status == .active && !$0.isImportSource && !isUnadoptedPlaceholder($0) }
    }

    /// Every paired, unarchived device that is not an import source or the placeholder.
    static func paired(in devices: [PairedDevice]) -> [PairedDevice] {
        devices.filter { $0.status != .archived && !$0.isImportSource && !isUnadoptedPlaceholder($0) }
    }

    /// DEBUG `--demo-sync` stands in for a connected strap (as it does for the Home strap chip), so the
    /// seeded row counts as one in those captures.
    private static var demoStandsInForAStrap: Bool {
        #if DEBUG
        return DemoSyncHarness.active
        #else
        return false
        #endif
    }
}

// MARK: - Switch

/// WHOOP's settings switch (AI SETTINGS on profile-community-2026/55, Manual Heart Rate Zones on
/// help-center/98): off, a grey knob (#8F8E93) on a #656A6E track; on, a white knob on teal. The system
/// switch draws off as a white knob on near-black. A `ToggleStyle`, so VoiceOver still reads a switch.
struct MoreSwitchStyle: ToggleStyle {
    /// Draw the toggle's label at the left (the switch alone otherwise; VoiceOver reads the label either way).
    var showsLabel = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            if showsLabel {
                configuration.label
                Spacer(minLength: 8)
            }
            MoreSwitchTrack(isOn: configuration.isOn)
                .onTapGesture { configuration.isOn.toggle() }
        }
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

private struct MoreSwitchTrack: View {
    let isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule(style: .circular)
                .fill(isOn ? PulseTheme.positive : ProfileArtPalette.switchOffTrack)
            Circle()
                .fill(isOn ? Color.white : ProfileArtPalette.switchOffKnob)
                .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
                .padding(2)
        }
        .frame(width: 51, height: 31)
        .opacity(isEnabled ? 1 : 0.45)
        .pulseAnimation(PulseMotion.chrome, value: isOn)
        // A 44 pt touch around the 31 pt track.
        .padding(.vertical, 6.5)
        .contentShape(Rectangle())
        .padding(.vertical, -6.5)
    }
}

// MARK: - Share sheet

/// Presents the system share sheet over whatever is on screen, for content made at the moment of the tap
/// (an achievement card rendered only when the wearer asks to share it).
enum ProfileSharePresenter {
    @MainActor
    static func share(_ items: [Any]) {
        guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let root = scene.keyWindow?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController, !presented.isBeingDismissed { top = presented }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = top.view
        top.present(controller, animated: true)
    }
}
#endif
