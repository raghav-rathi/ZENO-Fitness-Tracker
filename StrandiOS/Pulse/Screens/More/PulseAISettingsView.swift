#if os(iOS)
import SwiftUI
import StrandDesign

/// AI SETTINGS (WHOOP_UI_SPEC §3.33, profile-community-2026/55), a modal with "✕". WHOOP's page is a
/// MEMORY switch with its helper text and a "Data privacy" card; WHOOP removed its Coach switch in 2026,
/// ZENO keeps it [Z] and adds the provider and model, and the data the Coach may read.
///
/// The Coach switch is the classic Settings' `noop.coachEnabled`, and turning it off takes down the
/// morning brief exactly as that switch does (`CoachBriefScheduler.applyMasterSwitch`). The provider and
/// key are managed where they always were, on the Coach screen; this page opens it.
struct PulseAISettingsView: View {
    @EnvironmentObject private var coach: AICoachEngine
    @Environment(\.pulseCoach) private var coachContext
    @AppStorage("noop.coachEnabled") private var coachEnabled = true
    @State private var showCoachSettings = false

    var body: some View {
        PulseScreenScaffold(title: String(localized: "AI settings"), spacing: MoreLayout.sectionGap) {
            MoreSection(nil) {
                MoreToggleRow(title: String(localized: "Coach"), isOn: $coachEnabled,
                              help: String(localized: "Turns the AI Coach on or off. Off hides every Coach button and stops the morning brief. Your saved key is kept, so turning it back on needs no setup."))
                    .onChange(of: coachEnabled) { _, on in CoachBriefScheduler.applyMasterSwitch(on) }
            }
            if coachEnabled {
                MoreSection(String(localized: "Provider")) {
                    if coach.isConfigured {
                        MoreButtonRow(symbol: "cpu", title: coach.provider.displayName,
                                      subtitle: coach.model,
                                      trailing: .chevron) { coachContext.open(nil) }
                        MoreHelpText(String(localized: "Change the provider or the key on the Coach screen."))
                    } else {
                        MoreButtonRow(symbol: "sparkles", title: String(localized: "Set up Coach"),
                                      subtitle: String(localized: "Choose a provider and add your key"),
                                      trailing: .chevron) { coachContext.open(nil) }
                    }
                }
                MoreSection(String(localized: "Your data")) {
                    MoreToggleRow(title: String(localized: "Share my data with Coach"),
                                  isOn: Binding(get: { coach.dataConsent }, set: { coach.dataConsent = $0 }),
                                  help: String(localized: "Lets the Coach read your scores and trends when it answers. Off, it answers only from what you type."))
                    MoreButtonRow(symbol: "slider.horizontal.3", title: String(localized: "Coach settings"),
                                  subtitle: String(localized: "Instructions, morning brief, on-device signals"),
                                  trailing: .chevron) { showCoachSettings = true }
                }
            }
            PulseCard(padding: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "Data privacy"))
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text(String(localized: "ZENO has no server. Your history stays on this iPhone, and a question goes only to the provider you chose, with your own key, when you ask it."))
                        .pulseText(.rowSubline)
                        .lineSpacing(2)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .sheet(isPresented: $showCoachSettings) {
            CoachSettingsView()
        }
    }
}
#endif
