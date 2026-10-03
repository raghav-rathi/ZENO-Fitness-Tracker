#if os(iOS)
import SwiftUI
import StrandDesign

/// Privacy & Data (WHOOP_UI_SPEC §1.8, §3.31), pushed from More › ACCOUNT & SETTINGS, in place of
/// WHOOP's Privacy Settings (§3.33 "ZENO → PRIVACY & DATA"): what ZENO keeps and where, then backup,
/// restore and deletion, each through the screen or call that already does it (`DataBackup.runImport`
/// for a restore, exactly as the classic Settings runs it, behind a confirmation of its own).
struct PulsePrivacyDataView: View {
    static let isRebuilt = true

    @Environment(\.pulseNavigator) private var navigator
    @State private var confirmRestore = false
    @State private var restoring = false
    @State private var dialog: PrivacyDialog?

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Privacy & data"), spacing: MoreLayout.sectionGap) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .accessibilityHidden(true)
                MorePageIntro(title: String(localized: "Everything stays on this iPhone"),
                              text: String(localized: "ZENO has no account and no server. Your strap talks to this iPhone over Bluetooth, and your history lives in a database on it. Nothing leaves unless you export it, share it, connect Apple Health or ask the Coach."))
            }
            .padding(.horizontal, 4)
            MoreSection(String(localized: "Back up and restore")) {
                MoreButtonRow(symbol: "square.and.arrow.up", title: String(localized: "Export data"),
                              subtitle: String(localized: "A backup, a CSV archive or a report")) {
                    navigator.open(PulseDataExportRoute().route)
                }
                MoreLinkRow(.classic(.backupSync), symbol: "externaldrive.badge.icloud",
                            title: String(localized: "Back up to a folder"),
                            subtitle: String(localized: "On demand or about once a day"))
                MoreButtonRow(symbol: "arrow.counterclockwise", title: String(localized: "Restore from a backup"),
                              subtitle: restoring ? String(localized: "Restoring…") : String(localized: "Replaces the data on this iPhone")) {
                    confirmRestore = true
                }
                .disabled(restoring)
            }
            MoreSection(String(localized: "Delete data")) {
                MoreLinkRow(.classic(.devices), symbol: "sensor.tag.radiowaves.forward",
                            title: String(localized: "A strap's recordings"),
                            subtitle: String(localized: "Remove a device, then delete its data"))
                MoreLinkRow(.classic(.dataSources), symbol: "heart.text.square",
                            title: String(localized: "Imported Apple Health data"),
                            subtitle: String(localized: "In Data sources, under Apple Health"))
            }
            MoreSection(String(localized: "Your Coach")) {
                MoreButtonRow(symbol: "sparkles", title: String(localized: "What the Coach can read"),
                              subtitle: String(localized: "AI settings")) {
                    navigator.open(PulseAISettingsRoute().route)
                }
            }
        }
        .confirmationDialog(String(localized: "Restore from a backup?"), isPresented: $confirmRestore,
                            titleVisibility: .visible) {
            Button(String(localized: "Choose a backup"), role: .destructive) { restore(allowOversize: false) }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Everything on this iPhone is replaced by the backup you choose. The current data is kept in a side file, and ZENO needs a relaunch afterwards."))
        }
        .fullScreenCover(item: $dialog) { dialog in
            dialogView(dialog)
                .presentationBackground(.clear)
        }
    }

    @ViewBuilder
    private func dialogView(_ dialog: PrivacyDialog) -> some View {
        switch dialog {
        case .message(let title, let message):
            PulseDialogCard(title: title, message: message, primaryTitle: String(localized: "Okay"),
                            primary: { self.dialog = nil }, onClose: { self.dialog = nil })
        case .oversize(let message):
            PulseDialogCard(title: String(localized: "Large backup"), message: message,
                            primaryTitle: String(localized: "Restore"),
                            primary: {
                                self.dialog = nil
                                restore(allowOversize: true)
                            },
                            secondaryTitle: String(localized: "Cancel"), secondary: { self.dialog = nil },
                            onClose: { self.dialog = nil })
        }
    }

    /// The classic Settings import, result for result.
    private func restore(allowOversize: Bool) {
        restoring = true
        Task {
            let result = await DataBackup.runImport(allowOversize: allowOversize)
            restoring = false
            switch result {
            case .cancelled, .exported, .exportedOversize:
                return
            case .imported:
                dialog = .message(String(localized: "Backup restored"),
                                  String(localized: "Your data has been restored. Quit and reopen ZENO for it to take effect."))
            case .restoreTooLarge(let name, let limit):
                let cap = ByteCountFormatter.string(fromByteCount: limit, countStyle: .file)
                dialog = .oversize(String(localized: "\(name) is larger than the \(cap) a restore takes without asking. A backup you exported yourself is safe to restore; you will be asked to choose it again."))
            case .failure(let message):
                dialog = .message(String(localized: "Restore problem"), message)
            }
        }
    }
}

private enum PrivacyDialog: Identifiable {
    case message(String, String)
    case oversize(String)

    var id: String {
        switch self {
        case .message(let title, _): return "message-\(title)"
        case .oversize: return "oversize"
        }
    }
}
#endif
