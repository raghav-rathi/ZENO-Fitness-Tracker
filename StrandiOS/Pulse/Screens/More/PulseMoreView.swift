#if os(iOS)
import SwiftUI
import StrandDesign

/// The More tab ("MORE", WHOOP_UI_SPEC §3.31): the rest of the app as separate row cards under UPPERCASE
/// section headers. Every screen the classic More list reached is here, plus Devices.
///
/// Owned by group "more-profile", which rebuilds it to the spec's 2026 order (TOOLS, ACCOUNT &
/// SETTINGS, SUPPORT, ADVANCED, INTERFACE, version line). The sections below are today's.
struct PulseMoreView: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.pulseCoach) private var coach
    @AppStorage("pulse.enabled") private var pulseEnabled = true
    @State private var showReport = false
    @State private var confirmClassic = false

    var body: some View {
        PulseScreenScaffold(title: String(localized: "More"), role: .tabRoot, spacing: 0,
                            refresh: { await repo.refresh() }) {
            section(String(localized: "Performance")) {
                row(String(localized: "Trends"), "chart.line.uptrend.xyaxis", .trends)
                row(String(localized: "Weekly digest"), "calendar", .weeklyDigest)
                Button { showReport = true } label: {
                    PulseListRow(symbol: "doc.richtext", title: String(localized: "Report"))
                }
                .buttonStyle(PulsePressStyle())
            }
            section(String(localized: "Insights")) {
                row(String(localized: "What moves you"), "wand.and.sparkles", .insightsHub)
                row(String(localized: "Explore"), "square.grid.2x2", .explore)
                row(String(localized: "Compare"), "rectangle.split.2x1", .compare)
                row(String(localized: "Journal"), "square.and.pencil", .journal)
                if coach.availability == .needsSetup {
                    // Coach is on but has no provider yet: offer its setup here too.
                    Button { coach.open(nil) } label: {
                        PulseListRow(symbol: "sparkles", title: String(localized: "Set up AI Coach"))
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
            section(String(localized: "Activity")) {
                row(String(localized: "Workouts"), "figure.run", .workouts)
                row(String(localized: "Lift Log"), "dumbbell", .liftLog)
                row(String(localized: "Live"), "waveform.path.ecg", .live)
                row(String(localized: "Breathe"), "wind", .breathe)
                row(String(localized: "Intervals"), "timer", .intervals)
            }
            section(String(localized: "Strap & alarms")) {
                row(String(localized: "Devices"), "sensor.tag.radiowaves.forward", .devices)
                row(String(localized: "Alarms"), "alarm", .alarms)
            }
            section(String(localized: "Data")) {
                row(String(localized: "Data Sources"), "externaldrive", .dataSources)
                row(String(localized: "Apple Health"), "heart", .appleHealth)
                row(String(localized: "Backup & Sync"), "externaldrive.badge.icloud", .backupSync)
                row(String(localized: "Shortcuts Export"), "square.and.arrow.up", .shortcutsExport)
            }
            section(String(localized: "Settings")) {
                row(String(localized: "Settings"), "gearshape", .settings)
            }
            section(String(localized: "Advanced")) {
                row(String(localized: "Test Centre"), "stethoscope", .testCentre)
                    .id("pulse.advanced")
                row(String(localized: "Limitations"), "list.bullet.rectangle", .limitations)
                row(String(localized: "Mi Band"), "figure.walk.motion", .miBand)
                row(String(localized: "Rhythm"), "waveform.path", .rhythm)
                row(String(localized: "Intelligence"), "brain.head.profile", .intelligence)
                row(String(localized: "Your Data, Fused"), "square.stack.3d.up", .fusedRecord)
                row(String(localized: "Automations"), "wand.and.stars", .automations)
                row(String(localized: "Power saving"), "battery.25", .powerSaving)
                row(String(localized: "Siri & Shortcuts"), "mic", .siriShortcuts)
                row(String(localized: "Classic Health"), "heart.text.square", .classicHealth)
            }
            section(String(localized: "Interface")) {
                PulseListRow(symbol: "rectangle.stack", title: String(localized: "Classic interface"),
                             trailing: .toggle(Binding(get: { !pulseEnabled },
                                                       set: { if $0 { confirmClassic = true } })))
                Text(String(localized: "Switches to the classic tabs. Settings › WHOOP-style interface brings this one back."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showReport) {
            TrendsReportSheet(days: repo.days)
        }
        .confirmationDialog(String(localized: "Switch to the classic interface?"),
                            isPresented: $confirmClassic, titleVisibility: .visible) {
            Button(String(localized: "Switch")) { pulseEnabled = false }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Your data and settings stay as they are. You can switch back from Settings."))
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseListSectionHeader(title)
            VStack(spacing: PulseTheme.Row.listGap) {
                rows()
            }
        }
        .padding(.top, PulseTheme.Space.l)
    }

    private func row(_ title: String, _ symbol: String, _ destination: PulseClassicDestination) -> some View {
        PulseLink(.classic(destination)) {
            PulseListRow(symbol: symbol, title: title)
        }
        .buttonStyle(PulsePressStyle())
    }
}
#endif
