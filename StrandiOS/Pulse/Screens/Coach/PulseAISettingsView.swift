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
// `ai.model`, `ai.dataConsent`, `ai.includeOnDeviceSignals`, the Keychain key through `AICoachEngine.setKey`,
// the custom server's URL and header, and the morning brief's schedule (`CoachBriefScheduler`). A provider
// change always goes through the form with that provider's key, because a stored key is only ever sent to the
// provider it was saved for (`AIKeyStore.ownerProvider`).
//
// The classic Coach settings screen is not linked from here: it speaks of charge, effort and rest (§0.3). Its
// remaining controls are rows here: the second data opt-in and the morning brief. Coach instructions are
// replaced by My Memory (a "Preferences" memory says how to answer); an edited system prompt from the classic
// screen is still honoured, and this page says so and offers to return to the default. The Gemini chart image
// is left out because the sheet has no chart to attach.
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
    @State private var customModel = ""
    @State private var briefEnabled = CoachBriefScheduler.isEnabled
    @State private var briefMinutes = CoachBriefScheduler.timeMinutes
    @State private var briefStatus: String?

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
                                ? String(localized: "On: with each new question, Coach sends a short summary of your Recovery, Strain, Sleep, HRV, resting heart rate and recent workouts to \(coach.provider.displayName). A question asked from a page also carries that page's summary, such as your cycle day and phase from Menstrual Cycle Insights.")
                                : String(localized: "Off: Coach answers generally and sends none of your numbers, not even the summary of the page you ask from."))
                    .padding(.top, 28)
                if coach.dataConsent {
                    toggleBlock(title: String(localized: "Also share my patterns and Lab Book"),
                                isOn: $coach.includeOnDeviceSignals,
                                help: coach.includeOnDeviceSignals
                                    ? String(localized: "On: a short summary of your strongest patterns and the health numbers you logged in Lab Book is added. Summaries only, never raw readings.")
                                    : String(localized: "Off: only your Recovery, Strain, Sleep and workout summary is shared."))
                        .padding(.top, 22)
                }
                toggleBlock(title: String(localized: "Memory"), isOn: $memoryEnabled,
                            help: String(localized: "Allow Coach to use what you save in My Memory to personalise its guidance. Memories are stored only on this iPhone; active ones are sent with each new conversation to the provider you chose."))
                    .padding(.top, 22)

                PulseCoachDashedRule()
                    .padding(.vertical, 22)

                morningBrief
                if coach.hasCustomSystemPrompt {
                    customInstructions
                        .padding(.top, 22)
                }

                PulseCoachDashedRule()
                    .padding(.vertical, 22)

                Button { confirmDeleteHistory = true } label: {
                    PulseListRow(symbol: "clock.arrow.circlepath", title: String(localized: "Delete conversation history"),
                                 trailing: .none, titleColor: PulseTheme.recoveryLowText)
                }
                .buttonStyle(PulsePressStyle())

                privacyCard
                    .padding(.top, 28)
            }
        }
        .onAppear(perform: refreshConfigured)
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

    // MARK: Morning brief and instructions

    /// MORNING BRIEF: Coach writes today's brief at about the chosen time and posts it as a notification
    /// (`CoachBriefScheduler`, unchanged). It needs Use my data, as the brief is built from the data summary.
    private var morningBrief: some View {
        VStack(alignment: .leading, spacing: 14) {
            toggleBlock(title: String(localized: "Morning brief"), isOn: $briefEnabled,
                        help: !coach.dataConsent
                            ? String(localized: "Needs Use my data: the brief is written from your Recovery, Sleep and Strain.")
                            : (briefEnabled
                               ? String(localized: "Each morning Coach writes today's brief with your key and sends it as a notification. iOS decides exactly when a backgrounded app wakes, so it can come a little later.")
                               : String(localized: "Off: nothing is written or sent on a schedule.")))
                .disabled(!coach.dataConsent && !briefEnabled)
                .onChange(of: briefEnabled) { _, on in
                    briefStatus = nil
                    CoachBriefScheduler.setEnabled(on, generateBrief: { await coach.generateBrief() }) { outcome in
                        if outcome == .denied {
                            briefEnabled = false
                            briefStatus = String(localized: "Notifications are off for ZENO. Allow them in Settings to get a morning brief.")
                        }
                    }
                }
            if briefEnabled {
                HStack {
                    Text(String(localized: "Time"))
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    DatePicker(String(localized: "Morning brief time"), selection: briefTime,
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(.horizontal, 4)
            }
            if let briefStatus {
                Text(briefStatus)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.negative)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var briefTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: briefMinutes / 60, minute: briefMinutes % 60)) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                let minutes = (c.hour ?? 7) * 60 + (c.minute ?? 0)
                briefMinutes = minutes
                CoachBriefScheduler.setTimeMinutes(minutes, generateBrief: { await coach.generateBrief() })
            })
    }

    /// An edited system prompt from the classic Coach settings still frames every reply; say so, and offer
    /// the default back. (How Coach should answer now lives in My Memory.)
    private var customInstructions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Coach instructions"))
                .pulseText(.cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(String(localized: "Your own instructions, edited in the classic interface, frame every reply. To tell Coach how to answer here, add a Preferences memory in My Memory."))
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            Button { coach.resetSystemPrompt() } label: { Text(String(localized: "Use the default instructions")) }
                .buttonStyle(.pulseNested)
        }
        .padding(.horizontal, 4)
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

    /// The engine saves a key for the provider set at that moment, so the provider is switched first; if the
    /// key cannot be saved (the Keychain refused it), the provider, model and server it had are put back, so
    /// a failed Connect leaves the working setup as it was.
    private func connect() {
        attempted = true
        let key = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let before = Setup(provider: coach.provider, model: coach.model, baseURL: coach.customBaseURL,
                           authHeader: coach.customAuthHeader)
        coach.provider = provider
        if provider == .custom {
            coach.customBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            coach.customAuthHeader = authHeader
            if !key.isEmpty { coach.setKey(key) }
            guard coach.errorText == nil else { return restore(before) }
            coach.connectCustom()
        } else {
            if !model.isEmpty { coach.model = model }
            coach.setKey(key)
            guard coach.errorText == nil else { return restore(before) }
        }
        keyDraft = ""
        onConnected()
    }

    private struct Setup {
        let provider: AIProvider
        let model: String
        let baseURL: String
        let authHeader: CustomAIAuthHeader
    }

    private func restore(_ setup: Setup) {
        let error = coach.errorText
        coach.provider = setup.provider
        coach.model = setup.model
        coach.customBaseURL = setup.baseURL
        coach.customAuthHeader = setup.authHeader
        // Switching the provider back clears the engine's error; the wearer still needs to read it.
        coach.errorText = error
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
