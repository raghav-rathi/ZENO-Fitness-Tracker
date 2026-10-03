#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The More tab (WHOOP_UI_SPEC §3.31): WHOOP's 2026 order with ZENO's content and no promos.
///
///   FIRST WEEK WITH ZENO card   (the first seven days only)
///   TOOLS                       workouts, lift log, intervals, live heart rate, breathe, guided session
///   ACCOUNT & SETTINGS          profile, device settings, app settings, privacy & data
///   SUPPORT                     how ZENO works, what's new, report a problem, first week (after day 7)
///   ADVANCED                    the power-user screens
///   INTERFACE                   the classic-interface switch
///   ZENO 11.8.0 (428)           where WHOOP prints LOGOUT and its app version
///
/// Rows are separate 56 pt cards 10 pt apart, 20 pt from the screen edges (help-center/94, reviews/r05).
/// The 2026 root has no navigation title, so the list starts under the status bar. The screens Pulse
/// has not rebuilt yet open through `forExistingEntryPoint`, so a row never lands on a placeholder while
/// a working classic screen exists.
struct PulseMoreView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @EnvironmentObject private var repo: Repository
    @AppStorage("pulse.enabled") private var pulseEnabled = true
    /// The guided session is BETA and switchable, like its Liquid Today entry.
    @AppStorage(LiveSessionPrefs.betaKey) private var liveSessionsBeta = true
    @State private var confirmClassic = false

    var body: some View {
        PulseScreenScaffold(role: .tabRoot, showsNavigationBar: false, spacing: MoreLayout.sectionGap,
                            horizontalPadding: MoreLayout.moreMargin, topPadding: 28,
                            refresh: { await model.refresh() }) {
            if isFirstWeek {
                MoreFirstWeekCard { navigator.open(PulseRoute.firstWeek.forExistingEntryPoint) }
                    .padding(.bottom, -8)
            }
            tools
            account
            support
            advanced
            interface
            MoreVersionLine()
                .padding(.top, -8)
                .id("pulse.bottom-version")
        }
        .confirmationDialog(String(localized: "Switch to the classic interface?"),
                            isPresented: $confirmClassic, titleVisibility: .visible) {
            Button(String(localized: "Switch")) { pulseEnabled = false }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Your data and settings stay as they are. You can switch back from Settings."))
        }
    }

    // MARK: Sections

    /// TOOLS sits in WHOOP's SHOP & GIFT slot (§3.31 [Z]).
    private var tools: some View {
        MoreSection(String(localized: "Tools")) {
            MoreLinkRow(.classic(.workouts), symbol: "figure.run", title: String(localized: "Workouts log"))
                .id("pulse.tools")
            MoreLinkRow(PulseRoute.strengthTrainer.forExistingEntryPoint, symbol: "dumbbell",
                        title: String(localized: "Lift log"), subtitle: String(localized: "Strength Trainer"))
            MoreLinkRow(.classic(.intervals), symbol: "timer", title: String(localized: "Interval timer"))
            MoreLinkRow(.classic(.live), symbol: "waveform.path.ecg", title: String(localized: "Live heart rate"),
                        subtitle: String(localized: "Live Body Console"))
            MoreLinkRow(.classic(.breathe), symbol: "wind", title: String(localized: "Breathe"))
            if liveSessionsBeta {
                // Moved here from the ＋ menu (§1.3: the guided session goes to More › Tools).
                MoreButtonRow(symbol: "shield.lefthalf.filled", title: String(localized: "Guided session (beta)"),
                              subtitle: String(localized: "Strap coaching against today's Recovery")) {
                    navigator.present(.guidedSession)
                }
            }
        }
    }

    private var account: some View {
        MoreSection(String(localized: "Account & settings")) {
            MoreLinkRow(PulseRoute.profile.forExistingEntryPoint, symbol: "person.crop.circle",
                        title: String(localized: "Profile"))
                .id("pulse.account")
            MoreLinkRow(PulseRoute.deviceSettings.forExistingEntryPoint, symbol: "sensor.tag.radiowaves.forward",
                        title: String(localized: "Device settings"),
                        subtitle: String(localized: "Battery, sync, pairing"))
            MoreLinkRow(PulseRoute.appSettings.forExistingEntryPoint, symbol: "gearshape",
                        title: String(localized: "App settings"))
            MoreLinkRow(PulseRoute.privacyData.forExistingEntryPoint, symbol: "eye",
                        title: String(localized: "Privacy & data"),
                        subtitle: String(localized: "Everything stays on this iPhone"))
        }
    }

    private var support: some View {
        MoreSection(String(localized: "Support")) {
            MoreLinkRow(.classic(.scoringGuide), symbol: "graduationcap", title: String(localized: "How ZENO works"))
                .id("pulse.support")
            MoreLinkRow(.classic(.whatsNew), symbol: "sparkles", title: String(localized: "What's new"))
            MoreLinkRow(PulseRoute.reportProblem.forExistingEntryPoint, symbol: "exclamationmark.bubble",
                        title: String(localized: "Report a problem"))
            if !isFirstWeek {
                MoreLinkRow(PulseRoute.firstWeek.forExistingEntryPoint, symbol: "checklist",
                            title: String(localized: "First week with ZENO"))
            }
        }
    }

    private var advanced: some View {
        MoreSection(String(localized: "Advanced")) {
            MoreLinkRow(.classic(.testCentre), symbol: "stethoscope", title: String(localized: "Test Centre"))
                .id("pulse.advanced")
            MoreLinkRow(.classic(.limitations), symbol: "list.bullet.rectangle", title: String(localized: "Limitations"))
            MoreLinkRow(.classic(.miBand), symbol: "figure.walk.motion", title: String(localized: "Mi Band"))
            MoreLinkRow(.classic(.rhythm), symbol: "waveform.path", title: String(localized: "Rhythm"))
            MoreLinkRow(.classic(.intelligence), symbol: "brain.head.profile", title: String(localized: "Intelligence"))
            MoreLinkRow(.classic(.fusedRecord), symbol: "square.stack.3d.up", title: String(localized: "Your data, fused"))
            MoreLinkRow(.classic(.powerSaving), symbol: "battery.25", title: String(localized: "Power saving"))
            MoreLinkRow(.classic(.siriShortcuts), symbol: "mic", title: String(localized: "Siri & Shortcuts"))
            MoreLinkRow(.classic(.classicHealth), symbol: "heart.text.square", title: String(localized: "Classic Health"))
            // The classic Settings screen keeps the rest (appearance, recalibration, backups, about).
            MoreLinkRow(.classic(.settings), symbol: "slider.horizontal.3", title: String(localized: "Classic settings"))
        }
    }

    private var interface: some View {
        MoreSection(String(localized: "Interface")) {
            VStack(alignment: .leading, spacing: 10) {
                MoreListRow(symbol: "rectangle.stack", title: String(localized: "Classic interface"),
                        trailing: .toggle(Binding(get: { !pulseEnabled },
                                                  set: { if $0 { confirmClassic = true } })))
                MoreHelpText(String(localized: "Switches to the classic tabs. Settings › WHOOP-style interface brings this one back."))
            }
            .id("pulse.interface")
        }
    }

    // MARK: State

    /// The first seven days with any data: More leads with the FIRST WEEK card, and SUPPORT drops its
    /// row (WHOOP shows the card to new members and the row to everyone else).
    private var isFirstWeek: Bool {
        #if DEBUG
        if PulseMoreDebug.flag("--more-first-week") { return true }
        #endif
        // Until the store has loaded, nothing is known: no card rather than a flash of one.
        guard repo.loaded else { return false }
        // A member with no data at all is as new as it gets.
        guard let first = repo.freshness.earliestDay else { return true }
        guard let cutoff = PulseDisplay.dayKey(Repository.localDayKey(Date()), offsetBy: -6) else { return false }
        return first >= cutoff
    }
}
#endif
