#if os(iOS)
import SwiftUI
import StrandDesign

/// DATA EXPORT (WHOOP_UI_SPEC §3.33, health-more-2026/25), a modal with "✕". WHOOP's page asks for an
/// email and sends an archive within a day; ZENO exports on the spot, on this iPhone, through the same
/// exporters the classic Settings uses (`DataBackup.runExport`, `CsvExport.run`), and links the PDF
/// report, folder sync and the Shortcuts export. The copy keeps WHOOP's pattern in ZENO's words, with its
/// "LEARN MORE →". An export in progress says "Preparing…" on its own row, never a spinner (DR §8).
struct PulseDataExportView: View {
    @EnvironmentObject private var repo: Repository
    @State private var busy: ExportKind?
    @State private var result: ExportOutcome?

    private enum ExportKind { case backup, csv }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Export data"), spacing: MoreLayout.sectionGap) {
            VStack(alignment: .leading, spacing: 4) {
                MorePageIntro(text: String(localized: "Export a complete archive of your Sleep, Recovery, Strain and Journal data. Files stay on this iPhone until you share them."))
                PulseLink(.classic(.backupSync)) {
                    MoreArrowLabel(String(localized: "Learn more"))
                }
                .buttonStyle(PulsePressStyle())
            }
            VStack(alignment: .leading, spacing: 10) {
                MoreButtonRow(symbol: "archivebox", title: String(localized: "Full backup"),
                              subtitle: busy == .backup ? String(localized: "Preparing…")
                                                        : String(localized: "Everything, restorable on any device"),
                              trailing: busy == nil ? .chevron : .none) { runBackup() }
                    .disabled(busy != nil)
                MoreHelpText(String(localized: "A single .noopbak file: history, sleeps, workouts and settings. It is a plain zip archive, not encrypted, so keep it somewhere you trust."))
            }
            VStack(alignment: .leading, spacing: 10) {
                MoreButtonRow(symbol: "tablecells", title: String(localized: "CSV archive"),
                              subtitle: busy == .csv ? String(localized: "Preparing…")
                                                     : String(localized: "Days, sleeps, workouts and journal"),
                              trailing: busy == nil ? .chevron : .none) { runCSV() }
                    .disabled(busy != nil)
                MoreHelpText(String(localized: "A zip of WHOOP-format CSV files that any spreadsheet opens and ZENO can import again. Rows ZENO computed itself are marked APPROXIMATE."))
            }
            MoreSection(String(localized: "More ways out")) {
                MoreLinkRow(.classic(.report), symbol: "doc.richtext", title: String(localized: "PDF report"))
                MoreLinkRow(.classic(.backupSync), symbol: "externaldrive.badge.icloud",
                            title: String(localized: "Back up to a folder"),
                            subtitle: String(localized: "On demand or about once a day"))
                MoreLinkRow(.classic(.shortcutsExport), symbol: "square.and.arrow.up.on.square",
                            title: String(localized: "Shortcuts export"))
            }
        }
        .fullScreenCover(item: $result) { outcome in
            PulseDialogCard(title: outcome.title, message: outcome.message,
                            primaryTitle: String(localized: "Okay"), primary: { result = nil },
                            onClose: { result = nil })
                .presentationBackground(.clear)
        }
    }

    private func runBackup() {
        busy = .backup
        Task {
            let outcome = await DataBackup.runExport(checkpoint: { await repo.checkpointForBackup() })
            busy = nil
            switch outcome {
            case .cancelled, .imported:
                return
            case .exported(let url):
                result = ExportOutcome(title: String(localized: "Backup exported"),
                                       message: String(localized: "Saved to \(url.lastPathComponent). Copy it to another device and import it there to restore everything."))
            case .exportedOversize(let url, let bytes, let limit):
                let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
                let cap = ByteCountFormatter.string(fromByteCount: limit, countStyle: .file)
                result = ExportOutcome(title: String(localized: "Backup exported"),
                                       message: String(localized: "Saved to \(url.lastPathComponent). Your data is \(size), over the \(cap) a restore takes without asking, so restoring it will ask you to confirm once."))
            case .restoreTooLarge:
                return
            case .failure(let message):
                result = ExportOutcome(title: String(localized: "Export problem"), message: message)
            }
        }
    }

    private func runCSV() {
        busy = .csv
        Task {
            let outcome = await CsvExport.run(repo: repo)
            busy = nil
            switch outcome {
            case .cancelled:
                return
            case .exported(let url):
                result = ExportOutcome(title: String(localized: "CSV exported"),
                                       message: String(localized: "Saved to \(url.lastPathComponent). It imports again under Integrations › Data sources."))
            case .failure(let message):
                result = ExportOutcome(title: String(localized: "Export problem"), message: message)
            }
        }
    }
}

/// An export's result, for the dialog card.
private struct ExportOutcome: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
#endif
