#if os(iOS)
import SwiftUI
import StrandDesign

/// The ＋ menu: every "start something" entry in one place (the classic shell spreads six of them
/// across Today, Live and More). Each row opens the existing screen; Mark moment acts in place.
struct PulseActionSheet: View {
    let onPick: (PulseQuickAction) -> Void
    let onGuidedSession: () -> Void
    let onClose: () -> Void

    /// The guided session is BETA and switchable, like its Liquid Today entry.
    @AppStorage(LiveSessionPrefs.betaKey) private var liveSessionsBeta = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    row(String(localized: "Start workout"), String(localized: "GPS or manual, with live heart rate"),
                        "figure.run", PulseTheme.strain) { onPick(.workout) }
                    row(String(localized: "Lift session"), String(localized: "Sets, reps and rest on the strap"),
                        "dumbbell.fill", PulseTheme.strain) { onPick(.liftLog) }
                    row(String(localized: "Intervals"), String(localized: "Work and rest timer"),
                        "timer", PulseTheme.strain) { onPick(.intervals) }
                    if liveSessionsBeta {
                        row(String(localized: "Guided session"), String(localized: "Silent strap coaching against today's Recovery · beta"),
                            "shield.lefthalf.filled", PulseTheme.strain) { onGuidedSession() }
                    }
                    row(String(localized: "Live HR"), String(localized: "Your heart rate, beat by beat"),
                        "waveform.path.ecg", PulseTheme.recoveryRedText) { onPick(.live) }
                    row(String(localized: "Breathe"), String(localized: "A few slow minutes"),
                        "wind", PulseTheme.sleep) { onPick(.breathe) }
                    row(String(localized: "Log journal"), String(localized: "Today's behaviours and notes"),
                        "square.and.pencil", PulseTheme.accent) { onPick(.journal) }
                    PulseMarkMomentRow()
                }
                .padding(.horizontal, PulseTheme.pagePadding)
                .padding(.bottom, 24)
            }
            .pulsePage()
            .navigationTitle(String(localized: "Start"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done"), action: onClose)
                        .foregroundStyle(PulseTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .dark)
    }

    private func row(_ title: String, _ subtitle: String, _ symbol: String, _ tint: Color,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PulseRow(title: title, subtitle: subtitle) {
                PulseRowIcon(symbol: symbol, tint: tint)
            }
            .background(PulseCardSurface(radius: 14))
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// Marks a moment on the timeline in place, with a buzz on the strap and a visible confirmation here.
/// Its own leaf because it needs `AppModel`, which publishes every heart-rate tick.
private struct PulseMarkMomentRow: View {
    @EnvironmentObject private var app: AppModel
    @State private var markedAt: Date?

    var body: some View {
        Button {
            app.markMoment()
            markedAt = Date()
        } label: {
            PulseRow(title: markedAt == nil ? String(localized: "Mark moment")
                                            : String(localized: "Moment marked"),
                     subtitle: markedAt.map { String(localized: "At \(PulseFormat.clock($0))") }
                        ?? String(localized: "Pin this minute to your timeline"),
                     showsChevron: false) {
                PulseRowIcon(symbol: markedAt == nil ? "mappin.and.ellipse" : "checkmark",
                             tint: markedAt == nil ? PulseTheme.textSecondary : PulseTheme.accent)
            }
            .background(PulseCardSurface(radius: 14))
        }
        .buttonStyle(PulsePressStyle())
        .sensoryFeedback(.success, trigger: markedAt)
        .accessibilityHint(String(localized: "Records the current time as a moment"))
    }
}
#endif
