#if os(iOS)
import SwiftUI

/// "✕ AI SETTINGS" (WHOOP_UI_SPEC §3.33 "AI Settings", profile-community-2026/55), presented as a sheet.
/// App Settings › AI SETTINGS opens it with `PulseAISettingsRoute().route`; the Coach sheet pushes the same
/// view from its version pill.
struct PulseAISettingsRoute: PulseScreenRoute {
    var presentation: PulsePresentation { .sheet }
    var view: some View { PulseAISettingsView() }
}

// WHOOP's page is MEMORY + a privacy card. ZENO keeps its Coach switch and adds the provider, model, key and
// data-access rows [Z], all bound to the EXISTING engine and its keys: `noop.coachEnabled`, `ai.provider`,
// `ai.model`, `ai.dataConsent`, the Keychain key through `AICoachEngine.setKey`, and the custom server's URL
// and header. A provider change always goes through the form with that provider's key, because a stored key
// is only ever sent to the provider it was saved for (`AIKeyStore.ownerProvider`).
struct PulseAISettingsView: View {
    @EnvironmentObject private var coach: AICoachEngine
    @AppStorage("noop.coachEnabled") private var coachEnabled = true
    @AppStorage(PulseMemoryStore.enabledKey) private var memoryEnabled = true
    @Environment(\.dismiss) private var dismiss

    @State private var configured = false
    @State private var changingProvider = false
    @State private var updatingKey = false
    @State private var keyDraft = ""
    @State private var confirmDisconnect = false
    @State private var confirmDeleteHistory = false
    @State private var showsClassicSettings = false
    @State private var customModel = ""

    var body: some View {
        PulseScreenScaffold(title: String(localized: "AI Settings")) {
            VStack(alignment: .leading, spacing: 0) {
                toggleBlock(title: String(localized: "Coach"), isOn: $coachEnabled,
                            help: String(localized: "Turn Coach off to hide it everywhere in ZENO. Your provider and key stay saved, so turning it back on needs no setup."))
                    .onChange(of: coachEnabled) { _, on in CoachBriefScheduler.applyMasterSwitch(on) }
                PulseCoachDashedRule()
                    .padding(.vertical, 22)

                if configured && !changingProvider {
                    connectionRows
                } else {
                    PulseAIProviderForm(isChange: configured,
                                        onConnected: {
                                            changingProvider = false
                                            refreshConfigured()
                                        },
                                        onCancel: configured ? { changingProvider = false } : nil)
                }

                toggleBlock(title: String(localized: "Use my data"), isOn: $coach.dataConsent,
                            help: coach.dataConsent
                                ? String(localized: "On: with each new question, Coach sends a short summary of your Recovery, Strain, Sleep, HRV, resting heart rate and recent workouts to \(coach.provider.displayName).")
                                : String(localized: "Off: Coach answers generally and sends none of your numbers."))
                    .padding(.top, 28)
                toggleBlock(title: String(localized: "Memory"), isOn: $memoryEnabled,
                            help: String(localized: "Allow Coach to use what you save in My Memory to personalise its guidance. Memories are stored only on this iPhone; active ones are sent with each new conversation to the provider you chose."))
                    .padding(.top, 22)

                PulseCoachDashedRule()
                    .padding(.vertical, 22)

                Button { confirmDeleteHistory = true } label: {
                    PulseListRow(symbol: "clock.arrow.circlepath", title: String(localized: "Delete conversation history"),
                                 trailing: .none, titleColor: PulseTheme.recoveryLowText)
                }
                .buttonStyle(PulsePressStyle())
                Button { showsClassicSettings = true } label: {
                    PulseListRow(symbol: "slider.horizontal.3", title: String(localized: "More coach settings"),
                                 subtitle: String(localized: "Instructions, morning brief, extra data sharing"))
                }
                .buttonStyle(PulsePressStyle())
                .padding(.top, PulseTheme.Row.listGap)

                privacyCard
                    .padding(.top, 28)
            }
        }
        .onAppear(perform: refreshConfigured)
        .sheet(isPresented: $showsClassicSettings) {
            CoachSettingsView()
                .environmentObject(coach)
        }
        .confirmationDialog(String(localized: "Disconnect \(coach.provider.displayName)?"), isPresented: $confirmDisconnect,
                            titleVisibility: .visible) {
            Button(String(localized: "Disconnect"), role: .destructive) {
                coach.disconnect()
                refreshConfigured()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "This removes your key from the Keychain and ends the current conversation. Your conversation history stays on this iPhone."))
        }
        .confirmationDialog(String(localized: "Delete all conversations?"), isPresented: $confirmDeleteHistory,
                            titleVisibility: .visible) {
            Button(String(localized: "Delete all conversations"), role: .destructive) {
                PulseCoachThreadStore.shared.deleteAll()
                coach.clearConversation()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "This permanently removes every Coach conversation saved on this iPhone."))
        }
    }

    private func refreshConfigured() {
        configured = coach.isConfigured
    }

    // MARK: Connected

    private var connectionRows: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Row.listGap) {
            PulseListSectionHeader(String(localized: "Provider"))
                .padding(.bottom, 4)
            Button { changingProvider = true } label: {
                PulseListRow(symbol: "sparkles", title: coach.provider.displayName,
                             subtitle: coach.provider == .custom ? AIProvider.customBaseURL : nil,
                             trailing: .value(String(localized: "Change")))
            }
            .buttonStyle(PulsePressStyle())

            PulseListSectionHeader(String(localized: "Model"))
                .padding(.top, 18)
                .padding(.bottom, 4)
            modelRow
            Button { Task { await coach.refreshModels() } } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 12, weight: .semibold))
                    Text(String(localized: "Refresh models")).pulseText(.label)
                }
                .foregroundStyle(PulseTheme.recoveryBlue)
                .frame(minHeight: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(!coach.hasKey && coach.provider != .custom)

            PulseListSectionHeader(String(localized: "API key"))
                .padding(.top, 10)
                .padding(.bottom, 4)
            keyRow
            if let error = coach.errorText, !error.isEmpty {
                PulseCoachErrorLine(text: error)
            }
        }
    }

    private var modelRow: some View {
        Menu {
            ForEach(coach.availableModels, id: \.self) { model in
                Button {
                    coach.model = model
                } label: {
                    if model == coach.model { Label(model, systemImage: "checkmark") } else { Text(model) }
                }
            }
        } label: {
            PulseCoachModelRow(model: coach.model)
        }
        .accessibilityLabel(String(localized: "Model, \(coach.model)"))
    }

    @ViewBuilder
    private var keyRow: some View {
        if updatingKey {
            VStack(alignment: .leading, spacing: 12) {
                PulseCoachSecureField(placeholder: String(localized: "Paste your \(coach.provider.displayName) API key"),
                                      text: $keyDraft)
                PulseButtonRow {
                    Button {
                        coach.setKey(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines))
                        if coach.errorText == nil {
                            keyDraft = ""
                            updatingKey = false
                        }
                    } label: { Text(String(localized: "Save key")) }
                    .buttonStyle(.pulseFilledWhite)
                    .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button { keyDraft = ""; updatingKey = false } label: { Text(String(localized: "Cancel")) }
                        .buttonStyle(.pulseOutlineWhite)
                }
            }
        } else {
            PulseListRow(symbol: "key", title: coach.hasKey ? String(localized: "Saved in the Keychain") : String(localized: "No key"),
                         subtitle: String(localized: "Sent only to \(coach.provider.displayName), only when you ask"),
                         trailing: .none)
            PulseButtonRow {
                Button { updatingKey = true } label: { Text(String(localized: "Update key")) }
                    .buttonStyle(.pulseNested)
                Button { confirmDisconnect = true } label: { Text(String(localized: "Disconnect")) }
                    .buttonStyle(.pulseNested)
            }
            .padding(.top, 2)
        }
    }

    // MARK: Pieces

    private func toggleBlock(title: String, isOn: Binding<Bool>, help: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer(minLength: 8)
                Toggle(title, isOn: isOn)
                    .labelsHidden()
                    .tint(PulseTheme.positive)
            }
            Text(help)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    private var privacyCard: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Data privacy"))
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "Coach is the only part of ZENO that uses the internet. Nothing is sent until you ask a question, and then only to the provider you chose, with your own key. Conversations and memories stay on this iPhone."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Provider, key and model (the setup state and "Change provider")

/// Choose a provider, paste its key (or a local server's URL) and a model, then connect. Nothing is written
/// to the engine until CONNECT, so leaving half-way changes nothing.
struct PulseAIProviderForm: View {
    let isChange: Bool
    let onConnected: () -> Void
    var onCancel: (() -> Void)?

    @EnvironmentObject private var coach: AICoachEngine
    @State private var provider: AIProvider = .openAI
    @State private var keyDraft = ""
    @State private var baseURL = ""
    @State private var authHeader: CustomAIAuthHeader = .bearer
    @State private var model = ""
    @State private var attempted = false
    @State private var seeded = false

    init(isChange: Bool, onConnected: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.isChange = isChange
        self.onConnected = onConnected
        self.onCancel = onCancel
    }

    private var canConnect: Bool {
        provider == .custom
            ? !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            : !keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Row.listGap) {
            PulseListSectionHeader(String(localized: "Provider"))
                .padding(.bottom, 4)
            ForEach(AIProvider.allCases) { p in
                Button { select(p) } label: {
                    PulseCoachChoiceRow(title: p.displayName, detail: detail(p), selected: provider == p)
                }
                .buttonStyle(PulsePressStyle())
            }

            if provider == .custom {
                PulseListSectionHeader(String(localized: "Server URL"))
                    .padding(.top, 18)
                    .padding(.bottom, 4)
                PulseCoachTextField(placeholder: "http://localhost:11434/v1", text: $baseURL)
                PulseSegmentedControl(options: CustomAIAuthHeader.allCases, selection: $authHeader) { $0.displayName }
                    .padding(.top, 4)
            }

            PulseListSectionHeader(provider == .custom ? String(localized: "API key (optional)") : String(localized: "API key"))
                .padding(.top, 18)
                .padding(.bottom, 4)
            PulseCoachSecureField(placeholder: provider == .custom
                                  ? String(localized: "Only if your server needs one")
                                  : String(localized: "Paste your \(provider.displayName) API key"),
                                  text: $keyDraft)

            if provider != .custom {
                PulseListSectionHeader(String(localized: "Model"))
                    .padding(.top, 18)
                    .padding(.bottom, 4)
                Menu {
                    ForEach(provider.modelOptions, id: \.self) { m in
                        Button { model = m } label: {
                            if m == model { Label(m, systemImage: "checkmark") } else { Text(m) }
                        }
                    }
                } label: {
                    PulseCoachModelRow(model: model)
                }
            }

            if attempted, let error = coach.errorText, !error.isEmpty {
                PulseCoachErrorLine(text: error)
                    .padding(.top, 6)
            }

            PulseButtonRow {
                Button(action: connect) {
                    Text(isChange ? String(localized: "Save") : String(localized: "Connect"))
                }
                .buttonStyle(.pulseFilledWhite)
                .disabled(!canConnect)
                if let onCancel {
                    Button(action: onCancel) { Text(String(localized: "Cancel")) }
                        .buttonStyle(.pulseOutlineWhite)
                }
            }
            .padding(.top, 18)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)
                Text(provider == .custom
                     ? String(localized: "Coach talks only to the server you set. Point it at a model on your own network to keep everything at home.")
                     : String(localized: "Your key is stored in this iPhone's Keychain and sent only to \(provider.displayName), only when you ask a question."))
                    .pulseText(.rowSubline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(PulseTheme.textTertiary)
            .padding(.top, 8)
            .accessibilityElement(children: .combine)
        }
        .onAppear {
            guard !seeded else { return }
            seeded = true
            provider = coach.provider
            baseURL = coach.customBaseURL
            authHeader = coach.customAuthHeader
            model = coach.provider.modelOptions.contains(coach.model) ? coach.model : coach.provider.defaultModel
        }
    }

    private func detail(_ p: AIProvider) -> String {
        p == .custom ? String(localized: "A local or self-hosted OpenAI-compatible server")
                     : String(localized: "Your own \(p.displayName) API key")
    }

    private func select(_ p: AIProvider) {
        provider = p
        model = p.defaultModel
        attempted = false
    }

    private func connect() {
        attempted = true
        let key = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        coach.provider = provider
        if provider == .custom {
            coach.customBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            coach.customAuthHeader = authHeader
            if !key.isEmpty { coach.setKey(key) }
            guard coach.errorText == nil else { return }
            coach.connectCustom()
        } else {
            if !model.isEmpty { coach.model = model }
            coach.setKey(key)
            guard coach.errorText == nil else { return }
        }
        keyDraft = ""
        onConnected()
    }
}

// MARK: - Shared pieces

/// The model row: a model id is case-sensitive, so it keeps its own case (a settings row would uppercase it).
struct PulseCoachModelRow: View {
    let model: String

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "cpu")
                .font(.system(size: 21, weight: .light))
                .foregroundStyle(PulseTheme.rowIcon)
                .frame(width: 28, height: 28)
                .padding(.trailing, 20)
                .accessibilityHidden(true)
            Text(model.isEmpty ? String(localized: "Choose a model") : model)
                .pulseText(.rowText)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            PulseChevron(color: PulseTheme.textTertiary, size: 14)
        }
        .padding(.leading, 18)
        .padding(.trailing, 18)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.list, alignment: .leading)
        .pulseCardBackground(.rowCard)
        .contentShape(Rectangle())
    }
}

/// A selectable row with a radio mark.
struct PulseCoachChoiceRow: View {
    let title: String
    let detail: String?
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                if let detail {
                    Text(detail)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.rowSubline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(selected ? PulseTheme.positive : PulseTheme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.list, alignment: .leading)
        .pulseCardBackground(.rowCard)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// A text field on the page's dark field fill with a thin border (the onboarding field tokens).
struct PulseCoachTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .pulseText(.rowText)
            .foregroundStyle(PulseTheme.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .fill(PulseTheme.Onboarding.fieldFill))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .strokeBorder(PulseTheme.Onboarding.fieldBorder, lineWidth: 1))
    }
}

/// The same field for a secret.
struct PulseCoachSecureField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .pulseText(.rowText)
            .foregroundStyle(PulseTheme.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .fill(PulseTheme.Onboarding.fieldFill))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .strokeBorder(PulseTheme.Onboarding.fieldBorder, lineWidth: 1))
            .accessibilityLabel(placeholder)
    }
}

/// An engine error in the negative colour.
struct PulseCoachErrorLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 13, weight: .semibold))
                .accessibilityHidden(true)
            Text(text)
                .pulseText(.rowSubline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(PulseTheme.negative)
        .accessibilityElement(children: .combine)
    }
}

/// The dashed hairline under AI SETTINGS' toggles (profile-community-2026/55).
struct PulseCoachDashedRule: View {
    var body: some View {
        Line()
            .stroke(PulseTheme.dash, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}
#endif
