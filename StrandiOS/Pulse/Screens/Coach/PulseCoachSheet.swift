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
/// Opened from a page, the page's summary leads in a card above the first question. It goes to the provider
/// with that question only while AI Settings › USE MY DATA is on; with it off the card says it was not
/// shared and the question goes alone. From Home's Daily Outlook pill the card is the §3.15 outlook
/// (`PulseCoachOutlook`), or, once the scheduled morning brief exists for today, that brief as the first
/// assistant turn.
///
/// It drives the EXISTING `AICoachEngine` (its providers, keys, data summary, persistence, day boundary and
/// scheduled brief), which speaks Pulse's Recovery / Strain / Sleep while Pulse runs (`CoachVocabulary`);
/// everything Pulse adds sits beside it: the conversation archive behind the history list
/// (`PulseCoachThreadStore`), My Memory (`PulseMemoryStore`, handed to the engine as standing system context)
/// and the first message's context block that carries the page summary (`PulseCoachEnvelope`). Opening the
/// sheet sends nothing: unlike the classic screen it never asks for a brief on its own, so the first request
/// is always one the wearer made.
struct PulseCoachSheet: View {
    /// The page the sheet was opened from (a summary pill's sentence, the Daily Outlook), if any.
    var seed: String?

    @EnvironmentObject private var coach: AICoachEngine
    @EnvironmentObject private var repo: Repository
    /// Home's snapshot, for the Daily Outlook card (the same figures Home shows).
    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    /// The shell's Coach availability: its debounced "is a provider set up?" for the first frame, and `.off`
    /// when the Coach is switched off (the sheet closes).
    @Environment(\.pulseCoach) private var coachContext

    @State private var path: [PulseCoachDestination] = []
    /// The detent the wearer dragged to; nil until then (medium for the chat, large for setup).
    @State private var detentChoice: PresentationDetent?
    /// `AICoachEngine.isConfigured` reads the Keychain, so it is re-read only after setup or AI Settings, never
    /// per streamed token; until then the shell's probe answers, so the first frame is already right.
    @State private var configuredNow: Bool?
    @State private var opened = false
    @State private var draft = UserDefaults.standard.string(forKey: Self.draftKey) ?? ""
    /// Opened from a page and nothing sent yet: the page's summary leads, and the first question starts a
    /// conversation of its own.
    @State private var seedPending = false
    /// `seed` (Home's outlook rebuilt as `PulseCoachOutlook`), or in DEBUG captures the `--coach-seed` stand-in.
    @State private var seedText: String?
    /// A page summary the first question was asked from but NOT sent (Use my data was off), kept on screen
    /// above the conversation it started, marked as not shared.
    @State private var unsharedSeed: String?
    /// The first turn of the conversation `unsharedSeed` belongs to, once the engine has it.
    @State private var unsharedSeedAnchor: UUID?
    @State private var showsHistory = false
    @State private var remember: PulseCoachRemember?
    @State private var atBottom = true
    @State private var toast: String?
    /// With the keyboard up the composer sits clear of it instead of dipping into the bottom inset.
    @State private var keyboardShown = false

    /// The classic composer's draft key (K15), so a half-typed question survives either screen.
    private static let draftKey = "coach.composerDraft"

    private var threads: PulseCoachThreadStore { PulseCoachThreadStore.shared }

    private var configured: Bool { configuredNow ?? (coachContext.availability == .ready) }

    private var detent: Binding<PresentationDetent> {
        Binding(get: { detentChoice ?? (configured ? .medium : .large) }, set: { detentChoice = $0 })
    }

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
                            .onDisappear { configuredNow = coach.isConfigured }
                    }
                }
        }
        .presentationDetents(configured ? [.medium, .large] : [.large], selection: detent)
        .presentationDragIndicator(.visible)
        .presentationBackground { PulseCoachBackground() }
        .presentationCornerRadius(PulseCoachRadius.sheet)
        .environment(\.colorScheme, .dark)
        .onChange(of: path) { _, newPath in if !newPath.isEmpty { detentChoice = .large } }
        .onChange(of: coachContext.availability) { _, availability in
            if availability == .off { dismiss() }
        }
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
            // The pill row centres ≈32 pt under the sheet's top edge (reviews/r123).
            topBar
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
                .padding(.top, 11)
            if configured {
                transcript
                chips
                // r123: the chips sit ≈61 pt above the composer, whose bottom edge dips ≈8 pt into the
                // home-indicator inset (its centre 50 pt above the screen edge); pc66: "+" from x = 24, the
                // field to 20 pt from the right edge.
                PulseCoachComposer(draft: $draft, isSending: coach.sending, onSend: { send(draft) },
                                   onNewChat: newConversation)
                    .padding(.leading, 24)
                    .padding(.trailing, 20)
                    // The chips' 44 pt hit area ends 6 pt under each 32 pt chip: 14 + 22 puts the chip's centre
                    // 36 pt above the field, 60 pt above its centre.
                    .padding(.top, 14)
                    .padding(.bottom, keyboardShown ? 8 : -8)
            } else {
                setup
            }
        }
        .background(PulseCoachBackground())
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardShown = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardShown = false
        }
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

    /// The version pill (avatar + the model answering), the history clock and "Memory 💡". The labels are
    /// 13 pt Semibold (the 13 pt sub-line style, set Semibold), capped at accessibility2 so the row still fits.
    private var topBar: some View {
        HStack(spacing: 6) {
            Button { path.append(.settings) } label: {
                HStack(spacing: 8) {
                    PulseCoachAvatar(size: 24)
                    Text(configured ? Self.shortModel(coach.model) : String(localized: "Set up"))
                        .fontWeight(.semibold)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.leading, 4)
                .padding(.trailing, 12)
                .frame(minHeight: 32)
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
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Conversation history"))
            Button { path.append(.memory) } label: {
                HStack(spacing: 8) {
                    Text(String(localized: "Memory"))
                        .fontWeight(.semibold)
                        .pulseText(.rowSubline)
                    PulseCoachMemoryGlyph()
                        .padding(.trailing, 4)
                }
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(minHeight: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "My Memory"))
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if let lead = leadingPage {
                        seedCard(lead)
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
                // Replies start 16 pt from the edge (profile-community-2026/66).
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
                .padding(.top, 18)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            // Replies scroll away under the top bar through a short fade, never against a hard edge.
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color.black.opacity(0), Color.black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 18)
                    Rectangle()
                }
            }
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

    /// The page the conversation was opened from, in the coach's voice, above its first question, with a
    /// line saying whether it goes (or went) to the provider.
    private func seedCard(_ lead: LeadingPage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                PulseCoachAvatar(size: 22)
                Text(String(localized: "From \(PulseCoachEnvelope.pageLabel(lead.text))"))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            PulseCoachAssistantMessage(text: PulseCoachOutlook.markdown(lead.text) ?? lead.text, isStreaming: true)
            switch lead.sharing {
            case .pending where coach.dataConsent:
                PulseCoachSeedNote(symbol: "sparkle", text: String(localized: "Goes with your first question"),
                                   highlighted: true)
            case .pending, .notShared:
                PulseCoachSeedNote(symbol: "eye.slash", text: String(localized: "Not shared: Use my data is off"),
                                   highlighted: false)
            case .shared:
                EmptyView()
            }
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
                    configuredNow = coach.isConfigured
                }
                .padding(.top, 26)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    // MARK: State

    /// A page summary leading the conversation, and whether it went to the provider.
    struct LeadingPage {
        enum Sharing { case pending, shared, notShared }
        let text: String
        let sharing: Sharing
    }

    /// The page summary leading the conversation: the one handed over and not yet asked about, the one the
    /// current conversation's first question carried, or the one it was asked from without it.
    private var leadingPage: LeadingPage? {
        if seedPending, let seedText, !seedText.isEmpty { return LeadingPage(text: seedText, sharing: .pending) }
        if let first = coach.messages.first(where: { $0.role == .user }),
           let page = PulseCoachEnvelope.parse(first.text).page {
            return LeadingPage(text: page, sharing: .shared)
        }
        if let unsharedSeed, unsharedSeedAnchor == nil || coach.messages.first?.id == unsharedSeedAnchor {
            return LeadingPage(text: unsharedSeed, sharing: .notShared)
        }
        return nil
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
    /// schedule armed, and file the conversation in the history. From the Daily Outlook pill, an unread brief
    /// starts a conversation of its own (the one on screen goes to the history) and leads it; with no brief
    /// the outlook card leads.
    private func open() async {
        guard !opened else { return }
        opened = true
        // The wearer's active memories go with every request as system context. Set here as well as at
        // launch (where a scheduled brief needs it), so the sheet never depends on the launch having done so.
        coach.systemContext = PulseCoachEnvelope.standingContext
        await threads.loadIfNeeded()
        PulseMemoryStore.shared.loadIfNeeded()
        await coach.loadPersistedMessagesIfNeeded()
        coach.retireStaleConversationIfNeeded()
        var page = seed
        #if DEBUG
        if let stand = await PulseCoachDemo.seedOverride(model: model) { page = stand }
        #endif
        let kind = page.map(PulseCoachEnvelope.PageKind.init)
        let daySummary = kind?.isDaySummary == true
        if daySummary, configured, !coach.messages.isEmpty, !hasBrief, CoachBriefScheduler.hasUnconsumedBrief {
            threads.sync(coach.messages)
            coach.clearConversation()
        }
        if coach.messages.isEmpty, let stored = CoachBriefScheduler.consumeStoredBrief() {
            coach.surfaceScheduledBrief(stored)
        }
        CoachBriefScheduler.activateIfEnabled { await coach.generateBrief() }
        threads.sync(coach.messages)
        if daySummary, let home = model.home, home.day.isToday {
            // Home's outlook, laid out as §3.15 from the same snapshot Home draws.
            page = PulseCoachOutlook.page(home, evening: kind == .review)
        }
        seedText = page
        // Today's brief IS the outlook: it leads the conversation in place of the template.
        seedPending = !(seedText ?? "").isEmpty && !(daySummary && configured && hasBrief)
        #if DEBUG
        if PulseCoachDemo.requested {
            await PulseCoachDemo.prepareIfRequested(coach: coach, repo: repo)
            configuredNow = coach.isConfigured
            detentChoice = PulseCoachDemo.opensLarge || !configured ? .large : .medium
        }
        switch PulseCoachDemo.openTarget {
        case "memory": path = [.memory]
        case "settings": path = [.settings]
        case "history": showsHistory = true
        case "memory-detail": if let first = PulseMemoryStore.shared.items.first { path = [.memory, .memoryDetail(first.id)] }
        default: break
        }
        if PulseCoachDemo.asksFirstSuggestion, let first = suggestions.first { send(first) }
        #endif
    }

    /// A brief the engine wrote (it opens with "Today's brief") is in the conversation.
    private var hasBrief: Bool {
        coach.messages.contains { $0.role == .assistant && $0.text.hasPrefix("Today's brief") }
    }

    private func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !coach.sending, configured else { return }
        var page: String?
        var keptLocal = false
        if seedPending {
            // A question asked from a page starts its own conversation; the one on screen stays in history.
            // The page's summary holds the wearer's numbers, so it goes only with Use my data on (the consent
            // the engine asks before its own data summary); otherwise it stays on screen, marked not shared.
            if coach.dataConsent {
                page = seedText
            } else {
                unsharedSeed = seedText
                unsharedSeedAnchor = nil
                keptLocal = true
            }
            seedPending = false
            threads.sync(coach.messages)
            if !coach.messages.isEmpty { coach.clearConversation() }
        }
        // The engine retires yesterday's conversation inside `send`; do it first so the page's block lands on
        // the turn that really is first.
        coach.retireStaleConversationIfNeeded()
        let payload = coach.messages.isEmpty ? PulseCoachEnvelope.wrap(question, page: page) : question
        draft = ""
        Task {
            await coach.send(payload)
            if keptLocal, unsharedSeed != nil { unsharedSeedAnchor = coach.messages.first?.id }
            threads.sync(coach.messages)
        }
    }

    /// A question handed over by the classic Today launcher (`AICoachEngine.pendingPrompt`), sent once.
    private func sendPendingPrompt() async {
        guard let prompt = coach.pendingPrompt, !prompt.isEmpty else { return }
        coach.pendingPrompt = nil
        guard coach.isConfigured else { return }
        configuredNow = true
        send(prompt)
    }

    private func newConversation() {
        threads.sync(coach.messages)
        coach.clearConversation()
        seedPending = false
        unsharedSeed = nil
        draft = ""
    }

    /// Reopen an archived conversation in the engine (its newest 40 turns, the engine's own cap). Its first
    /// question keeps the page it was asked from; an older block's names and memories are dropped, since the
    /// engine now speaks Pulse's names itself and sends the memories active today.
    private func restore(_ thread: PulseCoachThread) {
        threads.sync(coach.messages)
        coach.clearConversation()
        var turns = thread.messages.suffix(40).map {
            ChatMessage(id: $0.id, role: ChatMessage.Role(rawValue: $0.role) ?? .user, text: $0.text)
        }
        if let i = turns.firstIndex(where: { $0.role == .user }) {
            turns[i] = ChatMessage(id: turns[i].id, role: .user,
                                   text: PulseCoachEnvelope.droppingLegacyContext(turns[i].text))
        }
        coach.messages = turns
        seedPending = false
        unsharedSeed = nil
    }

    /// After the history sheet: if the conversation on screen was deleted there, end it here too.
    private func dropDeletedConversation() {
        guard threads.isLoaded, !coach.messages.isEmpty, threads.thread(containing: coach.messages) == nil else {
            return
        }
        coach.clearConversation()
        unsharedSeed = nil
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
        AccessibilityNotification.Announcement(text).post()
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(PulseMotion.crossFade) { toast = nil }
        }
    }
}

/// The line under a page summary's card: "✧ Goes with your first question" or "Not shared: Use my data is off".
struct PulseCoachSeedNote: View {
    let symbol: String
    let text: String
    let highlighted: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(highlighted ? AnyShapeStyle(PulseTheme.Gradients.aiArrow)
                                             : AnyShapeStyle(PulseTheme.textTertiary))
                .accessibilityHidden(true)
            Text(text)
                .pulseText(.rowSubline)
                .foregroundStyle(highlighted ? PulseTheme.textSecondary : PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// WHOOP's Memory glyph, drawn from SF Symbols: a bulb with a sparkle at its shoulder.
struct PulseCoachMemoryGlyph: View {
    var size: CGFloat = 19

    var body: some View {
        Image(systemName: "lightbulb")
            .font(.system(size: size, weight: .light))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.47, weight: .bold))
                    .offset(x: size * 0.32, y: -size * 0.16)
            }
            .accessibilityHidden(true)
    }
}

/// The Coach surfaces' two radii, kept in one place until the theme carries them (§3.16: the sheet's top
/// corners 24; the composer field, "+" square, the wearer's bubble and Memory Detail's Active card 14).
enum PulseCoachRadius {
    static let sheet: CGFloat = 24
    static let field: CGFloat = 14
}

/// "Add to My Memory" on one of the wearer's messages.
struct PulseCoachRemember: Identifiable {
    let id = UUID()
    let text: String
    let thread: UUID?
}
#endif
