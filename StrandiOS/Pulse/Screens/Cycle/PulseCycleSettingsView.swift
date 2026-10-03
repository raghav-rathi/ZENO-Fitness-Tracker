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
// decides whether phases and predictions apply. WHOOP's "Show cycle overlay on Trends" is left out until a
// Trends screen draws one: a switch that changes nothing would be a promise the app does not keep.
//
// Laid out as help-center/11: the switch as a bare row with its help text under it (no card), then one row
// per section showing the current value with "›", which pushes the choices with their explanations.
struct PulseCycleSettingsView: View {
    @EnvironmentObject private var repo: Repository
    @AppStorage(AppModel.cycleAwarenessKey) private var enabled = false
    @AppStorage(PulseCycleLog.Mode.storageKey) private var modeRaw = PulseCycleLog.Mode.menstruating.rawValue
    @AppStorage(PulseCycleLog.Contraception.storageKey) private var contraceptionRaw = PulseCycleLog.Contraception.none.rawValue
    @State private var confirmDelete = false
    @State private var engineRefresh = 0

    private var mode: PulseCycleLog.Mode { PulseCycleLog.Mode(rawValue: modeRaw) ?? .menstruating }
    private var contraception: PulseCycleLog.Contraception {
        PulseCycleLog.Contraception(rawValue: contraceptionRaw) ?? .none
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Hormonal Insights")) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Text(String(localized: "Hormonal Insights"))
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    Toggle(String(localized: "Hormonal Insights"), isOn: $enabled)
                        .labelsHidden()
                        .tint(PulseTheme.positive)
                }
                .frame(minHeight: PulseTheme.Layout.minTapTarget)
                .padding(.horizontal, 4)
                Text(String(localized: "See how your cycle shapes your Recovery, Strain and Sleep, with predictions and coaching worked out from your own logs on this iPhone."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.horizontal, 4)

                PulseListSectionHeader(String(localized: "Mode"))
                    .padding(.top, 28)
                PulseLink(PulseCycleChoiceRoute(kind: .mode).route) {
                    PulseCycleValueRow(title: mode.title, showsDrop: true)
                }
                .buttonStyle(PulsePressStyle())
                .padding(.top, 14)

                PulseListSectionHeader(String(localized: "Contraception type"))
                    .padding(.top, 28)
                PulseLink(PulseCycleChoiceRoute(kind: .contraception).route) {
                    PulseCycleValueRow(title: contraception.title, showsDrop: false)
                }
                .buttonStyle(PulsePressStyle())
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

/// A settings row holding a section's current value ("◌ MENSTRUATING ›", "NONE ›"; help-center/11): the
/// list row's card and metrics, with WHOOP's dotted-drop mark for the mode.
struct PulseCycleValueRow: View {
    let title: String
    let showsDrop: Bool

    var body: some View {
        HStack(spacing: 0) {
            if showsDrop {
                PulseCycleDropMark()
                    .frame(width: 28, height: 28)
                    .padding(.trailing, 20)
            }
            Text(title)
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 8)
            PulseChevron(color: PulseTheme.textTertiary, size: 14)
        }
        .padding(.leading, showsDrop ? 18 : 20)
        .padding(.trailing, 18)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.list, alignment: .leading)
        .pulseCardBackground(.rowCard)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A drop inside a dotted ring (ZENO's drawing of the LOG PERIOD DATA mark).
struct PulseCycleDropMark: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(PulseTheme.rowIcon, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 3.4]))
            Image(systemName: "drop.fill")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(PulseTheme.rowIcon)
        }
        .accessibilityHidden(true)
    }
}

/// MODE or CONTRACEPTION TYPE: the choices with what each one changes. Picking one goes back.
struct PulseCycleChoiceRoute: PulseScreenRoute {
    enum Kind: Hashable { case mode, contraception }
    let kind: Kind
    var view: some View { PulseCycleChoiceView(kind: kind) }
}

struct PulseCycleChoiceView: View {
    let kind: PulseCycleChoiceRoute.Kind

    @Environment(\.dismiss) private var dismiss
    @AppStorage(PulseCycleLog.Mode.storageKey) private var modeRaw = PulseCycleLog.Mode.menstruating.rawValue
    @AppStorage(PulseCycleLog.Contraception.storageKey) private var contraceptionRaw = PulseCycleLog.Contraception.none.rawValue

    var body: some View {
        PulseScreenScaffold(title: kind == .mode ? String(localized: "Mode") : String(localized: "Contraception type")) {
            VStack(spacing: PulseTheme.Row.listGap) {
                switch kind {
                case .mode:
                    ForEach(PulseCycleLog.Mode.allCases) { mode in
                        choiceRow(title: mode.title, detail: mode.detail, selected: modeRaw == mode.rawValue) {
                            modeRaw = mode.rawValue
                        }
                    }
                case .contraception:
                    ForEach(PulseCycleLog.Contraception.allCases) { option in
                        choiceRow(title: option.title, detail: option.detail,
                                  selected: contraceptionRaw == option.rawValue) {
                            contraceptionRaw = option.rawValue
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func choiceRow(title: String, detail: String, selected: Bool, pick: @escaping () -> Void) -> some View {
        Button {
            pick()
            dismiss()
        } label: {
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
