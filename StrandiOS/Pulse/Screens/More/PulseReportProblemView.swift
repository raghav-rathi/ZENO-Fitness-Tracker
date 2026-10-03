#if os(iOS)
import SwiftUI
import StrandDesign

/// Report a Problem (WHOOP_UI_SPEC §1.8, §3.31), pushed from More › SUPPORT: what went wrong in the
/// wearer's words, the app log attached if they choose, and a share sheet. ZENO has no server, so the
/// report is a file that goes wherever the wearer sends it (Mail, Messages, Files, AirDrop).
///
/// The log is the strap log Test Centre exports (`LiveState.exportableLogText`, with the same diagnostic
/// header lines), already scrubbed of Bluetooth addresses, peripheral identifiers and strap serials as it
/// is written. Test Centre's full bundle, with every test's capture and its review step, stays one tap
/// away for a deeper report.
struct PulseReportProblemView: View {
    /// Rebuilt: More's REPORT A PROBLEM row opens this screen rather than the classic Test Centre.
    static let isRebuilt = true

    @EnvironmentObject private var model: AppModel
    @State private var details = ""
    @State private var attachLog = true
    @State private var preparing = false
    @FocusState private var detailsFocused: Bool

    private var trimmedDetails: String { details.trimmingCharacters(in: .whitespacesAndNewlines) }
    /// Something to send: words, the log, or both.
    private var canShare: Bool { !preparing && (!trimmedDetails.isEmpty || attachLog) }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Report a problem"), spacing: MoreLayout.sectionGap) {
            MorePageIntro(title: String(localized: "What went wrong?"),
                          text: String(localized: "Say what you saw and what you expected. ZENO has no server: your report is a file that goes only where you send it."))
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Details"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.Onboarding.fieldLabel)
                    .accessibilityHidden(true)
                TextField("", text: $details,
                          prompt: Text(String(localized: "For example: last night's sleep is missing, or the strap stopped syncing at 3 PM."))
                            .foregroundStyle(PulseTheme.textDisabled),
                          axis: .vertical)
                    .lineLimit(5...12)
                    .profileFont(15, weight: .regular, relativeTo: .subheadline)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .focused($detailsFocused)
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .continuous)
                        shape.fill(PulseTheme.Onboarding.fieldFill)
                            .overlay(shape.strokeBorder(PulseTheme.Onboarding.fieldBorder, lineWidth: 1))
                    }
                    .accessibilityLabel(String(localized: "Details"))
            }
            MoreToggleRow(title: String(localized: "Attach the app log"), isOn: $attachLog,
                          help: String(localized: "The log ZENO keeps on this iPhone: connections, syncs and what the app saw. Bluetooth addresses and strap serials are removed before it is written."),
                          separator: false)
            VStack(spacing: 12) {
                Button(action: share) {
                    Text(preparing ? String(localized: "Preparing…") : String(localized: "Share report"))
                }
                .buttonStyle(.pulseFilledWhite)
                .disabled(!canShare)
                .opacity(canShare ? 1 : 0.45)
                MoreHelpText(String(localized: "Send it to whoever helps you with ZENO, or save it to Files."))
            }
            MoreSection(String(localized: "More help")) {
                MoreLinkRow(.classic(.testCentre), symbol: "stethoscope",
                            title: String(localized: "Full diagnostic bundle"),
                            subtitle: String(localized: "Test Centre: every test's log, reviewed before you share it"))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done")) { detailsFocused = false }
            }
        }
    }

    /// Zip the description (with the app and iOS versions) and, if asked, the log, then open the share
    /// sheet. Nothing leaves the phone until the wearer picks where it goes.
    private func share() {
        detailsFocused = false
        preparing = true
        let text = trimmedDetails
        let withLog = attachLog
        Task {
            var entries = [FileExport.BundleEntry(name: "report.txt", data: Data(Self.reportText(text).utf8))]
            if withLog {
                let header = await DebugDataDiagnostics.dynamicLines(repo: model.repo)
                entries.append(FileExport.BundleEntry(name: "app-log.txt",
                                                      data: Data(model.live.exportableLogText(extraHeaderLines: header).utf8)))
            }
            _ = await FileExport.exportBundle(entries: entries,
                                              suggestedName: FileExport.timestampedName("zeno-report", ext: "zip"))
            preparing = false
        }
    }

    /// report.txt: what the wearer wrote, under the build and system it happened on.
    private static func reportText(_ details: String) -> String {
        let stamp = Date().formatted(.iso8601)
        return """
        ZENO problem report
        App: \(LiveState.appIdentityLine)
        iOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Written: \(stamp)

        What went wrong:
        \(details.isEmpty ? "(no description)" : details)
        """
    }
}
#endif
