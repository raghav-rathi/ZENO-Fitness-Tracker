#if os(iOS)
import SwiftUI

// MARK: - Navigation header (WHOOP_UI_SPEC §1.5)
//
// No large titles. A pushed screen shows a thin white "‹" (the system back button, title hidden, so the
// interactive swipe-back keeps working), a centred UPPERCASE 12 pt Bold title tracked 1.2 ("TODAY",
// "WED, JUN 4", "HEALTH MONITOR"), and one trailing accessory. The bar is transparent over the fixed
// gradient and takes the page's top colour once content scrolls under it. A modal flow's root shows "✕"
// at the top-left instead of "‹".

/// What sits at the right of a Pulse navigation bar.
enum PulseNavTrailing {
    case none
    /// The outlined ⓘ (27.5 pt, white 50%) that opens an explainer sheet.
    case info(() -> Void)
    /// The pillar's achievement chip: badge glyph, tint and count.
    case achievement(symbol: String, tint: Color, count: Int, action: () -> Void)
    /// A plain glyph: ⚙ (Stress Monitor, Menstrual), a history clock (Coach), "?" (Sleep Planner), "•••".
    case symbol(String, accessibilityLabel: String, action: () -> Void)

    var isNone: Bool {
        if case .none = self { return true }
        return false
    }
}

private struct PulseModalRootKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True for the root view of a modally presented Pulse flow: its header shows "✕", not "‹". The shell's
    /// modal host sets it; every pushed destination resets it.
    var pulseModalRoot: Bool {
        get { self[PulseModalRootKey.self] }
        set { self[PulseModalRootKey.self] = newValue }
    }
}

/// The outlined ⓘ circle (27.5 pt, white 50%).
struct PulseInfoButton: View {
    var accessibilityLabel: String = String(localized: "How it's calculated")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().strokeBorder(PulseTheme.textTertiary, lineWidth: 1.5)
                Image(systemName: "info")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            .frame(width: 27.5, height: 27.5)
            .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// "✕", white, for a modal flow's root.
struct PulseCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Close"))
    }
}

/// Applies the Pulse navigation header to a screen.
private struct PulseNavHeaderModifier: ViewModifier {
    let title: String?
    let trailing: PulseNavTrailing

    @Environment(\.pulseModalRoot) private var modalRoot
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            // The back button keeps the system chevron (and its swipe-back) without the previous title.
            .toolbarRole(.editor)
            .toolbar {
                if let title {
                    ToolbarItem(placement: .principal) {
                        Text(title)
                            .pulseText(.navTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                if modalRoot {
                    ToolbarItem(placement: .topBarLeading) {
                        PulseCloseButton { dismiss() }
                    }
                }
                if !trailing.isNone {
                    ToolbarItem(placement: .topBarTrailing) {
                        trailingView
                    }
                }
            }
            .toolbarBackground(PulseTheme.pageTop, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .none:
            EmptyView()
        case .info(let action):
            PulseInfoButton(action: action)
        case .achievement(let symbol, let tint, let count, let action):
            Button(action: action) {
                PulseAchievementChip(symbol: symbol, tint: tint, count: count)
            }
            .buttonStyle(PulsePressStyle())
        case .symbol(let symbol, let label, let action):
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(label)
        }
    }
}

extension View {
    /// The Pulse navigation header: centred UPPERCASE `title`, the system "‹" (or "✕" at a modal root),
    /// and one `trailing` accessory, on a bar that is clear until content scrolls under it.
    func pulseNavHeader(_ title: String?, trailing: PulseNavTrailing = .none) -> some View {
        modifier(PulseNavHeaderModifier(title: title, trailing: trailing))
    }
}
#endif
