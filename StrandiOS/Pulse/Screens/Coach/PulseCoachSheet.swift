#if os(iOS)
import SwiftUI
import MarkdownUI

/// The Coach sheet's own pushes: My Memory, a memory's detail and AI Settings.
enum PulseCoachDestination: Hashable {
    case memory
    case memoryDetail(UUID)
    case settings
}

/// The Coach sheet (WHOOP_UI_SPEC §3.16; reviews/r123, profile-community-2026/66, 74, 29), opened by the
/// Coach button, the summary pills, the Daily Outlook pill and every other coach entry point.
///
/// A bottom sheet with a grabber (medium → large) on the near-black ground with its indigo glow: at the top
/// the version pill (the coach avatar and the model answering, opening AI Settings), then the history clock
/// [Z] and "Memory 💡"; the conversation (assistant replies as plain text with copy, share and save under
/// them, the wearer's turns in #343850 bubbles with a ✧ receipt for what went along); white suggestion chips;
/// and the composer ("+" for a new conversation, "Ask ZENO anything", dictation). With no provider set up it
/// shows the setup form instead.
///
/// It drives the EXISTING `AICoachEngine` (its providers, keys, data summary, persistence, day boundary and
/// scheduled brief); everything Pulse adds sits beside it: the conversation archive behind the history list
/// (`PulseCoachThreadStore`), My Memory (`PulseMemoryStore`) and the first message's context block that
/// carries the page summary, the active memories and the Recovery / Strain / Sleep vocabulary
/// (`PulseCoachEnvelope`). Opening the sheet sends nothing: unlike the classic screen it never asks for a
/// brief on its own, so the first request is always one the wearer made.
struct PulseCoachSheet: View {
    /// The page the sheet was opened from (a summary pill's sentence, the Daily Outlook), if any.
    var seed: String?

    @EnvironmentObject private var coach: AICoachEngine
    @EnvironmentObject private var repo: Repository
    #if DEBUG
    /// Captures only (`--coach-seed outlook`); Release never reads the model here.
    @Environment(PulseModel.self) private var model
    #endif
    @Environment(\.dismiss) private var dismiss
    @AppStorage("noop.coachEnabled") private var coachEnabled = true

    @State private var path: [PulseCoachDestination] = []
    @State private var detent: PresentationDetent = .medium
    /// `AICoachEngine.isConfigured` reads the Keychain, so it is read on open and after setup, not per token.
    @State private var configured = false
    @State private var opened = false
    @State private var draft = UserDefaults.standard.string(forKey: Self.draftKey) ?? ""
    /// Opened from a page and nothing sent yet: the page's summary leads, and the first question starts a
    /// conversation of its own.
    @State private var seedPending = false
    /// `seed`, or in DEBUG captures the `--coach-seed` stand-in.
    @State private var seedText: String?
    @State private var showsHistory = false
    @State private var remember: PulseCoachRemember?
    @State private var atBottom = true
    @State private var toast: String?

    /// The classic composer's draft key (K15), so a half-typed question survives either screen.
    private static let draftKey = "coach.composerDraft"

    private var threads: PulseCoachThreadStore { PulseCoachThreadStore.shared }

    var body: some View {
        NavigationStack(path: $path) {
            root
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: PulseCoachDestination.self) { destination in
                    switch destination {
                    case .memory:
                        PulseMemoryView(inCoachSheet: true) { path.append(.memoryDetail($0)) }
                    case .memoryDetail(let id):
                        PulseMemoryDetailView(id: id, inCoachSheet: true)
                    case .settings:
                        PulseAISettingsView()
                            .onDisappear { configured = coach.isConfigured }
                    }
                }
        }
        .presentationDetents(configured ? [.medium, .large] : [.large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationBackground { PulseCoachBackground() }
        .presentationCornerRadius(24)
        .environment(\.colorScheme, .dark)
        .onChange(of: path) { _, newPath in if !newPath.isEmpty { detent = .large } }
        .onChange(of: coachEnabled) { _, on in if !on { dismiss() } }
        .onChange(of: draft) { _, value in UserDefaults.standard.set(value, forKey: Self.draftKey) }
        .task { await open() }
        .task(id: coach.pendingPrompt) { await sendPendingPrompt() }
        .onDisappear { threads.sync(coach.messages) }
        .sheet(isPresented: $showsHistory, onDismiss: dropDeletedConversation) {
            PulseCoachHistoryView(currentID: threads.thread(containing: coach.messages)?.id) { thread in
                restore(thread)
            }
        }
        .sheet(item: $remember) { item in
            PulseMemoryComposer(mode: .text, initialText: item.text, sourceThread: item.thread) { saved in
                if saved { flash(String(localized: "Added to My Memory")) }
            }
        }
    }

    // MARK: Layout

    private var root: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
                .padding(.top, 22)
            if configured {
                transcript
                chips
                PulseCoachComposer(draft: $draft, isSending: coach.sending, onSend: { send(draft) },
                                   onNewChat: newConversation)
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            } else {
                setup
            }
        }
        .background(PulseCoachBackground())
        .overlay(alignment: .top) {
            if let toast {
                Text(toast)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(PulseTheme.bannerWell))
                    .padding(.top, 70)
                    .transition(.opacity)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    /// The version pill (avatar + the model answering), the history clock and "Memory 💡".
    private var topBar: some View {
        HStack(spacing: 6) {
            Button { path.append(.settings) } label: {
                HStack(spacing: 8) {
                    PulseCoachAvatar(size: 24)
                    Text(configured ? Self.shortModel(coach.model) : String(localized: "Set up"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.leading, 4)
                .padding(.trailing, 12)
                .frame(height: 32)
                .background(Capsule(style: .continuous).fill(PulseTheme.card))
                .frame(minHeight: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(configured ? String(localized: "Model \(coach.model). AI settings")
                                           : String(localized: "Set up Coach. AI settings"))
            Spacer(minLength: 8)
            Button { showsHistory = true } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: 40, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Conversation history"))
            Button { path.append(.memory) } label: {
                HStack(spacing: 8) {
                    Text(String(localized: "Memory"))
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 18, weight: .regular))
                }
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(minHeight: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "My Memory"))
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if let page = leadingPage {
                        seedCard(page)
                    } else if coach.messages.isEmpty {
                        emptyState
                    }
                    // Opened from a page: its summary starts a conversation of its own, so the one in the
                    // engine waits in the history instead of trailing under it.
                    if !seedPending {
                        ForEach(coach.messages) { message in
                            messageView(message)
                                .id(message.id)
                        }
                    }
                    if showsThinking {
                        PulseCoachThinking().id("thinking")
                    }
                    if let error = coach.errorText, !error.isEmpty {
                        errorCard(error)
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                        .onAppear { atBottom = true }
                        .onDisappear { atBottom = false }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onChange(of: coach.messages.last?.text) { _, _ in
                if atBottom || coach.sending { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: coach.messages.count) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
            .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
            .overlay(alignment: .bottom) {
                if !atBottom && !coach.messages.isEmpty {
                    Button { withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("bottom", anchor: .bottom) } } label: {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white))
                            .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .padding(.bottom, 6)
                    .accessibilityLabel(String(localized: "Scroll to the latest message"))
                }
            }
        }
    }

    @ViewBuilder
    private var chips: some View {
        let prompts = suggestions
        if !prompts.isEmpty {
            PulseCoachChips(prompts: prompts, disabled: coach.sending) { send($0) }
                .padding(.top, 8)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            PulseCoachAvatar(size: 40)
            Text(String(localized: "Ask ZENO anything"))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(coach.dataConsent
                 ? String(localized: "Coach reads a short summary of your recent Recovery, Strain, Sleep and workouts, then answers in plain language.")
                 : String(localized: "Coach answers generally until you let it use your data in AI Settings."))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    /// The page the conversation was opened from, in the coach's voice, above its first question.
    private func seedCard(_ page: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                PulseCoachAvatar(size: 22)
                Text(String(localized: "From \(PulseCoachEnvelope.pageLabel(page))"))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            PulseCoachAssistantMessage(text: page, isStreaming: true)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func messageView(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            PulseCoachUserMessage(text: message.text) {
                remember = PulseCoachRemember(text: PulseCoachEnvelope.parse(message.text).question,
                                              thread: threads.thread(containing: coach.messages)?.id)
            }
        case .assistant:
            if !message.text.isEmpty {
                PulseCoachAssistantMessage(text: message.text,
                                           isStreaming: coach.sending && message.id == coach.messages.last?.id) {
                    saveToJournal(message.text)
                }
            }
        }
    }

    private func errorCard(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            PulseCoachErrorLine(text: error)
            if coach.keyRejected {
                PulseTextCTA(title: String(localized: "Update key"), tint: .color(PulseTheme.recoveryBlue)) {
                    path.append(.settings)
                }
            }
        }
    }

    private var setup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PulseCoachAvatar(size: 56)
                    .padding(.top, 10)
                Text(String(localized: "Set up Coach"))
                    .pulseText(.pageTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.top, 18)
                    .accessibilityAddTraits(.isHeader)
                Text(String(localized: "Coach answers questions about your Recovery, Strain and Sleep in plain language, through the AI provider you choose and your own key. Nothing leaves this iPhone until you ask."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                PulseAIProviderForm(isChange: false) {
                    configured = coach.isConfigured
                }
                .padding(.top, 26)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    // MARK: State

    /// The page summary leading the conversation: the one handed over and not yet asked about, or the one the
    /// current conversation was started from.
    private var leadingPage: String? {
        if seedPending, let seedText, !seedText.isEmpty { return seedText }
        guard let first = coach.messages.first(where: { $0.role == .user }) else { return nil }
        return PulseCoachEnvelope.parse(first.text).page
    }

    private var showsThinking: Bool {
        guard coach.sending, let last = coach.messages.last else { return coach.sending }
        return last.role == .user || last.text.isEmpty
    }

    private var suggestions: [String] {
        guard !coach.sending else { return [] }
        if seedPending, let seedText { return PulseCoachSuggestions.seeded(seedText) }
        if coach.messages.isEmpty { return [PulseCoachSuggestions.brief] + coach.suggestions }
        if coach.messages.last?.role == .assistant { return AICoachEngine.followUpSuggestions }
        return []
    }

    /// "gpt-5-mini", "sonnet-5-5", "gemini-flash": the model, without its vendor prefix, alias or date.
    static func shortModel(_ model: String) -> String {
        var m = model.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in ["claude-", "models/"] where m.hasPrefix(prefix) { m.removeFirst(prefix.count) }
        if m.hasSuffix("-latest") { m.removeLast("-latest".count) }
        if let stamp = m.range(of: #"-\d{8}$"#, options: .regularExpression) { m.removeSubrange(stamp) }
        return m.isEmpty ? String(localized: "Coach") : m
    }

    // MARK: Actions

    /// What the classic screen does on open, minus asking for a brief: restore today's conversation, retire
    /// one from an earlier day, surface a brief the scheduled notification already generated, keep the
    /// schedule armed, and file the conversation in the history.
    private func open() async {
        guard !opened else { return }
        opened = true
        threads.loadIfNeeded()
        PulseMemoryStore.shared.loadIfNeeded()
        configured = coach.isConfigured
        detent = configured ? .medium : .large
        await coach.loadPersistedMessagesIfNeeded()
        coach.retireStaleConversationIfNeeded()
        if coach.messages.isEmpty, let stored = CoachBriefScheduler.consumeStoredBrief() {
            coach.surfaceScheduledBrief(stored)
        }
        CoachBriefScheduler.activateIfEnabled { await coach.generateBrief() }
        threads.sync(coach.messages)
        seedText = seed
        #if DEBUG
        if let stand = await PulseCoachDemo.seedOverride(model: model) { seedText = stand }
        #endif
        seedPending = !(seedText ?? "").isEmpty
        #if DEBUG
        if PulseCoachDemo.requested {
            await PulseCoachDemo.prepareIfRequested(coach: coach, repo: repo)
            configured = coach.isConfigured
            detent = PulseCoachDemo.opensLarge || !configured ? .large : .medium
        }
        switch PulseCoachDemo.openTarget {
        case "memory": path = [.memory]
        case "settings": path = [.settings]
        case "history": showsHistory = true
        case "memory-detail": if let first = PulseMemoryStore.shared.items.first { path = [.memory, .memoryDetail(first.id)] }
        default: break
        }
        #endif
    }

    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !coach.sending, configured else { return }
        var page: String?
        if seedPending {
            // A question asked from a page starts its own conversation; the one on screen stays in history.
            page = seedText
            seedPending = false
            threads.sync(coach.messages)
            if !coach.messages.isEmpty { coach.clearConversation() }
        }
        // The engine retires yesterday's conversation inside `send`; do it first so the context block lands
        // on the turn that really is first.
        coach.retireStaleConversationIfNeeded()
        let payload = coach.messages.isEmpty
            ? PulseCoachEnvelope.wrap(question, page: page, memories: PulseMemoryStore.shared.promptItems)
            : question
        draft = ""
        Task {
            await coach.send(payload)
            threads.sync(coach.messages)
        }
    }

    /// A question handed over by the classic Today launcher (`AICoachEngine.pendingPrompt`), sent once.
    private func sendPendingPrompt() async {
        guard let prompt = coach.pendingPrompt, !prompt.isEmpty else { return }
        coach.pendingPrompt = nil
        guard coach.isConfigured else { return }
        configured = true
        send(prompt)
    }

    private func newConversation() {
        threads.sync(coach.messages)
        coach.clearConversation()
        seedPending = false
        draft = ""
    }

    /// Reopen an archived conversation in the engine (its newest 40 turns, the engine's own cap), with the
    /// context block re-attached to its first question when the cap cut the original off.
    private func restore(_ thread: PulseCoachThread) {
        threads.sync(coach.messages)
        coach.clearConversation()
        var turns = thread.messages.suffix(40).map {
            ChatMessage(id: $0.id, role: ChatMessage.Role(rawValue: $0.role) ?? .user, text: $0.text)
        }
        if let i = turns.firstIndex(where: { $0.role == .user }), !PulseCoachEnvelope.parse(turns[i].text).hasContext {
            turns[i] = ChatMessage(id: turns[i].id, role: .user,
                                   text: PulseCoachEnvelope.wrap(turns[i].text, page: nil,
                                                                 memories: PulseMemoryStore.shared.promptItems))
        }
        coach.messages = turns
        seedPending = false
    }

    /// After the history sheet: if the conversation on screen was deleted there, end it here too.
    private func dropDeletedConversation() {
        guard !coach.messages.isEmpty, threads.thread(containing: coach.messages) == nil else { return }
        coach.clearConversation()
    }

    /// The classic "Save to Journal": the reply as today's note under "Coach advice".
    private func saveToJournal(_ text: String) {
        let day = Repository.localDayKey(Date())
        Task {
            await repo.saveJournalAnswer(day: day, question: "Coach advice", answeredYes: true, notes: text)
            flash(String(localized: "Saved to today's Journal"))
        }
    }

    private func flash(_ text: String) {
        withAnimation(PulseMotion.crossFade) { toast = text }
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(PulseMotion.crossFade) { toast = nil }
        }
    }
}

/// "Add to My Memory" on one of the wearer's messages.
struct PulseCoachRemember: Identifiable {
    let id = UUID()
    let text: String
    let thread: UUID?
}
#endif
