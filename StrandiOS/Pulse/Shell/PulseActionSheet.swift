#if os(iOS)
import SwiftUI
import StrandDesign

/// The ＋ menu as a sheet, for the entry points with no "+" on screen to anchor the popover to: a NavRouter
/// quick-actions request, and the "+" inside a modal. Same rows, same order and same look as the anchored
/// menu (`PulseActionMenuHost`, WHOOP_UI_SPEC §1.3): START ACTIVITY · ADD ACTIVITY · STRENGTH TRAINER ·
/// COMPLETE YOUR JOURNAL, a hairline, then BREATHE · MARK MOMENT. Intervals and Live HR live in More ›
/// TOOLS and the guided session with them, as the spec moves them out of this menu.
struct PulseActionSheet: View {
    let onPick: (PulseQuickAction) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                PulseCloseButton(action: onClose)
            }
            .padding(.trailing, 8)
            .padding(.top, 8)
            ForEach(PulseActionMenuItem.primary) { row($0) }
            Rectangle()
                .fill(PulseTheme.divider)
                .frame(height: 1)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .accessibilityHidden(true)
            ForEach(PulseActionMenuItem.extras) { row($0) }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [PulseTheme.menuTop, PulseTheme.menuBottom], startPoint: .top,
                                   endPoint: .bottom).ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func row(_ item: PulseActionMenuItem) -> some View {
        if item == .markMoment {
            PulseMarkMomentSheetRow()
        } else if let action = item.quickAction {
            Button { onPick(action) } label: {
                PulseActionMenuRowLabel(title: item.title, symbol: item.symbol)
            }
            .buttonStyle(PulsePressStyle())
        }
    }
}

/// Marks a moment on the timeline in place, with a buzz on the strap and a visible confirmation here.
/// Its own leaf because it needs `AppModel`, which publishes every heart-rate tick.
private struct PulseMarkMomentSheetRow: View {
    @EnvironmentObject private var app: AppModel
    @State private var markedAt: Date?

    var body: some View {
        Button {
            app.markMoment()
            markedAt = Date()
        } label: {
            PulseActionMenuRowLabel(
                title: markedAt.map { String(localized: "Marked at \(PulseFormat.clock($0))") }
                    ?? PulseActionMenuItem.markMoment.title,
                symbol: markedAt == nil ? PulseActionMenuItem.markMoment.symbol : "checkmark")
        }
        .buttonStyle(PulsePressStyle())
        .sensoryFeedback(.success, trigger: markedAt)
        .accessibilityHint(String(localized: "Records the current time as a moment"))
    }
}
#endif
