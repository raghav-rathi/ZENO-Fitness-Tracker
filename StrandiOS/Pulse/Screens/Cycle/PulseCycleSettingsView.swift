#if os(iOS)
import SwiftUI

/// "‹ HORMONAL INSIGHTS" (WHOOP_UI_SPEC §3.24 "Settings"; help-center/11), pushed from the cycle page's ⚙.
/// More › App Settings › Hormonal Insights opens the same route.
struct PulseCycleSettingsRoute: PulseScreenRoute {
    var view: some View { PulseCycleSettingsView() }
}

// The master switch is the classic cycle-awareness opt-in (`AppModel.cycleAwarenessKey`, default off: the
// most sensitive health category stays manual-first), so turning it on here also starts the temperature
// engine the classic Health card reads. MODE adds perimenopause and menopause [Z]; CONTRACEPTION TYPE
// decides whether phases apply. WHOOP's "Show cycle overlay on Trends" is left out until a Trends screen
// draws one: a switch that changes nothing would be a promise the app does not keep.
struct PulseCycleSettingsView: View {
    @EnvironmentObject private var repo: Repository
    @AppStorage(AppModel.cycleAwarenessKey) private var enabled = false
    @AppStorage(PulseCycleLog.Mode.storageKey) private var modeRaw = PulseCycleLog.Mode.menstruating.rawValue
    @AppStorage(PulseCycleLog.Contraception.storageKey) private var contraceptionRaw = PulseCycleLog.Contraception.none.rawValue
    @State private var confirmDelete = false
    @State private var engineRefresh = 0

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Hormonal Insights")) {
            VStack(alignment: .leading, spacing: 0) {
                PulseListRow(title: String(localized: "Hormonal Insights"), trailing: .toggle($enabled))
                Text(String(localized: "See how your cycle shapes your Recovery, Strain and Sleep, with predictions and coaching worked out from your own logs on this iPhone."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                    .padding(.horizontal, 4)

                PulseListSectionHeader(String(localized: "Mode"))
                    .padding(.top, 32)
                VStack(spacing: PulseTheme.Row.listGap) {
                    ForEach(PulseCycleLog.Mode.allCases) { mode in
                        choiceRow(title: mode.title, detail: mode.detail, selected: modeRaw == mode.rawValue) {
                            modeRaw = mode.rawValue
                        }
                    }
                }
                .padding(.top, 14)

                PulseListSectionHeader(String(localized: "Contraception type"))
                    .padding(.top, 32)
                VStack(spacing: PulseTheme.Row.listGap) {
                    ForEach(PulseCycleLog.Contraception.allCases) { option in
                        choiceRow(title: option.title, detail: option.detail,
                                  selected: contraceptionRaw == option.rawValue) {
                            contraceptionRaw = option.rawValue
                        }
                    }
                }
                .padding(.top, 14)

                privacyCard
                    .padding(.top, 32)
            }
        }
        .background(PulseCycleEngineRefresher(request: engineRefresh))
        .onChange(of: enabled) { _, _ in engineRefresh += 1 }
        .confirmationDialog(String(localized: "Delete all cycle data?"), isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button(String(localized: "Delete all cycle data"), role: .destructive) {
                Task {
                    await repo.deleteAllCycleLogs()
                    engineRefresh += 1
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "This permanently removes every period, flow and symptom you logged on this iPhone. Your strap's data is not changed."))
        }
    }

    private func choiceRow(title: String, detail: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(detail)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.rowSubline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(selected ? PulseTheme.positive : PulseTheme.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.listWithSubline, alignment: .leading)
            .pulseCardBackground(.rowCard)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var privacyCard: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Privacy"))
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "Everything about your cycle is worked out and stored on this iPhone. Nothing is uploaded; a backup you export yourself is the only copy that ever leaves it."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button { confirmDelete = true } label: {
                    HStack(spacing: 6) {
                        Text(String(localized: "Delete all cycle data")).pulseText(.label)
                        Image(systemName: "trash").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(PulseTheme.recoveryLowText)
                    .frame(minHeight: PulseTheme.Layout.minTapTarget, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
            }
        }
    }
}

/// Re-runs the temperature engine (`AppModel.refreshV5Signals`) each time `request` changes, after the
/// opt-in flips or the period starts it cross-checks change. A leaf, so the screen holding it never observes
/// the whole `AppModel`.
struct PulseCycleEngineRefresher: View {
    let request: Int
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Color.clear
            .onChange(of: request) { _, _ in
                Task { await appModel.refreshV5Signals() }
            }
            .accessibilityHidden(true)
    }
}
#endif
