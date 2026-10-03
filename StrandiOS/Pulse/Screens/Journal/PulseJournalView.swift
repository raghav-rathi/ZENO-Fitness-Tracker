#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Journal (WHOOP_UI_SPEC §3.17), presented as a full-screen modal.
///
/// Top to bottom, on a fixed gradient the rows scroll over (warm sand for today, purple for a past day):
/// "✕ JOURNAL ✎" (✎ opens SELECT BEHAVIORS); "‹ TODAY ›" with an outlined TODAY pill on a past day (its
/// title opens the calendar); the 14-day strip of capsules; "What's happening today, June 30?"; USE PREVIOUS
/// ANSWERS when the day is still empty; the Smart log card; the plan's behaviour goals; the behaviours by
/// DAYTIME · NIGHTTIME · STATUS, each its own card with ✕ / ✓ and, once ✓, its follow-up; NOTES; and the
/// pinned SAVE JOURNAL.
///
/// Answers are staged here and written on SAVE JOURNAL, under the native journal source ("noop-journal")
/// exactly as the classic journal writes them, so the effects engine, Home's strip and an Android restore all
/// read the same rows. ✕ with unsaved answers asks first (DISCARD CHANGES?). The save is verified by reading
/// the day back; a mismatch shows YOUR ENTRY WAS NOT SAVED with RETRY.
struct PulseJournalView: View {
    /// The rebuilt Journal: existing entry points (NavRouter, quick action, ＋ menu) open it.
    static let isRebuilt = true
    /// Days back from today (nil = today).
    var dayOffset: Int?

    /// Days the strip offers ("swipe back up to 14 days"), longer only when an entry point asks for an older
    /// day (Home's strip on a past day), never past `maxStripDays`.
    static let minStripDays = 14
    static let maxStripDays = 30

    @Environment(PulseModel.self) private var model
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var router: NavRouter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pulseCoach) private var coach
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var catalog = JournalCatalogStore()
    @State private var local = PulseJournalLocalStore.shared
    @State private var plans = PulsePlanStore.shared

    @State private var offset = 0
    @State private var stripDays = PulseJournalView.minStripDays
    @State private var didStart = false
    @State private var snapshot: JournalDaySnapshot?
    /// What the day holds on disk, and what the screen shows (staged edits).
    @State private var original = JournalAnswersState()
    @State private var current = JournalAnswersState()
    @State private var usePrevious = false
    @State private var reload = 0
    @State private var sheet: JournalSheet?
    @State private var dialog: JournalDialog?
    @State private var saveFailed = false
    @State private var saving = false
    @State private var dontAskAgain = false

    private var isToday: Bool { offset == 0 }
    private var hasChanges: Bool { current != original }
    private var loadKey: String { "\(model.seq)|\(offset)|\(reload)" }
    private var isLoaded: Bool { snapshot?.offset == offset }

    var body: some View {
        VStack(spacing: 0) {
            PulseNavBar(title: String(localized: "Journal"), leading: .close,
                        trailing: .symbol("pencil", accessibilityLabel: String(localized: "Select behaviors"),
                                          action: { sheet = .select }),
                        onLeading: attemptClose)
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        dateRow
                            .padding(.top, 8)
                        dayStrip
                            .padding(.top, 14)
                        questionTitle
                            .padding(.top, 24)
                        PulseLoadingGate(isLoading: !isLoaded) {
                            if let snapshot, isLoaded { content(snapshot) }
                        } skeleton: {
                            PulseSkeleton.cards([64, 64, 64, 64, 64])
                                .padding(.top, 24)
                        }
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.bottom, PulseTheme.JournalPlan.saveHeight + PulseTheme.JournalPlan.saveFade + 24)
                }
                .scrollDismissesKeyboard(.interactively)
                #if DEBUG
                .onChange(of: isLoaded) { _, loaded in
                    guard loaded, let anchor = JournalPlanDebug.scrollAnchor else { return }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(700))
                        proxy.scrollTo("jp.\(anchor)", anchor: .top)
                    }
                }
                #endif
                }
                .mask {
                    VStack(spacing: 0) {
                        LinearGradient(colors: [Color.black.opacity(0), Color.black], startPoint: .top, endPoint: .bottom)
                            .frame(height: 14)
                        Color.black
                    }
                }
                saveBar
            }
        }
        .background(JournalBackground(isToday: isToday).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay { dialogOverlay }
        .sheet(item: $sheet) { sheetContent($0) }
        .fullScreenCover(isPresented: $saveFailed) {
            PulseErrorPage(title: String(localized: "Your entry was not saved"),
                           message: String(localized: "Your answers couldn't be written to the journal on this iPhone. Try again."),
                           onRetry: { saveFailed = false; Task { await save(then: .close) } },
                           onClose: { saveFailed = false })
        }
        .task(id: loadKey) { await load() }
        .onAppear(perform: start)
        .environment(\.colorScheme, .dark)
        .sensoryFeedback(.selection, trigger: offset)
    }

    // MARK: Header

    /// "‹ TODAY ›" (or "‹ MON, MAR 16 ›") centred, with an outlined TODAY pill on a past day.
    private var dateRow: some View {
        ZStack {
            HStack(spacing: 4) {
                stepButton("chevron.left", enabled: offset < stripDays - 1, label: String(localized: "Previous day")) {
                    requestDay(offset + 1)
                }
                Button { sheet = .calendar } label: {
                    Text(dayTitle)
                        .pulseText(.menuLabel)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(minWidth: 110, minHeight: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens a calendar"))
                stepButton("chevron.right", enabled: offset > 0, label: String(localized: "Next day")) {
                    requestDay(offset - 1)
                }
            }
            HStack {
                Spacer()
                if !isToday {
                    Button { requestDay(0) } label: {
                        Text(String(localized: "Today"))
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Capsule(style: .continuous)
                                .strokeBorder(PulseTheme.JournalPlan.todayPillBorder, lineWidth: 1.5))
                            .frame(minHeight: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "Go to today"))
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func stepButton(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(PulseTheme.JournalPlan.checkGlyph)
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    /// The fourteen days, oldest at the left, today at the right, sized so seven fill the width.
    private var dayStrip: some View {
        let days = snapshot?.strip ?? placeholderStrip
        let selectedKey = days.first { $0.offset == offset }?.key
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PulseTheme.JournalPlan.dayCapsuleGap) {
                    ForEach(days) { day in
                        Button { requestDay(day.offset) } label: {
                            JournalDayCapsule(weekday: PulseFormat.dayLabel(day.key, template: "EEE"),
                                              date: PulseFormat.dayLabel(day.key, template: "d"),
                                              logged: day.logged, selected: day.offset == offset)
                        }
                        .buttonStyle(PulsePressStyle())
                        .containerRelativeFrame(.horizontal, count: 7, spacing: PulseTheme.JournalPlan.dayCapsuleGap)
                        .id(day.key)
                        .accessibilityLabel(PulseFormat.navDayTitle(dayKey: day.key))
                        .accessibilityValue(day.logged ? String(localized: "Logged") : String(localized: "Not logged"))
                        .accessibilityAddTraits(day.offset == offset ? .isSelected : [])
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
            .onChange(of: selectedKey) { _, key in
                if let key {
                    withAnimation(PulseMotion.resolved(PulseMotion.chrome, reduceMotion: reduceMotion)) {
                        proxy.scrollTo(key, anchor: .center)
                    }
                }
            }
        }
    }

    /// Before the first load: the same fourteen days, nothing logged, so the strip never jumps.
    private var placeholderStrip: [JournalDaySnapshot.Day] {
        (0..<stripDays).reversed().map { n in
            JournalDaySnapshot.Day(key: Self.dayKey(offset: n), offset: n, logged: false)
        }
    }

    private var questionTitle: some View {
        Text(questionText)
            .pulseText(.journalQuestion)
            .foregroundStyle(PulseTheme.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ s: JournalDaySnapshot) -> some View {
        let layout = journalLayout(s)
        VStack(alignment: .leading, spacing: 0) {
            if showsUsePrevious(s) {
                usePreviousRow(s)
                    .padding(.top, 16)
            }
            if coach.availability != .off {
                smartLog
                    .padding(.top, 24)
            }
            if let plan = plans.plan, !layout.planRows.isEmpty {
                JournalSectionLabel(title: plan.journalLabel)
                    .padding(.top, 28)
                VStack(spacing: PulseTheme.JournalPlan.rowGap) {
                    ForEach(layout.planRows, id: \.goal.id) { row in planRow(row, snapshot: s) }
                }
                .padding(.top, 12)
            }
            ForEach(layout.sections, id: \.section) { group in
                JournalSectionLabel(title: group.section.title)
                    .padding(.top, 28)
                    .id("jp.\(group.section.debugName)")
                VStack(spacing: PulseTheme.JournalPlan.rowGap) {
                    ForEach(group.rows) { row in behaviorRow(row) }
                }
                .padding(.top, 12)
            }
            if layout.sections.isEmpty && layout.planRows.isEmpty {
                emptyJournal
                    .padding(.top, 28)
            }
            notes
                .padding(.top, 28)
                .id("jp.notes")
        }
    }

    /// Nothing selected: one card that opens SELECT BEHAVIORS.
    private var emptyJournal: some View {
        Button { sheet = .select } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Choose what to track"))
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(String(localized: "Pick the behaviors you want to log each day. ZENO compares them with your Recovery."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(String(localized: "Select behaviors")).pulseText(.label)
                    Image(systemName: "arrow.right").font(PulseTheme.JournalPlan.smallGlyph)
                }
                .foregroundStyle(PulseTheme.Plan.exploreCTA)
                .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.JournalPlan.rowCard))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }

    // MARK: Smart log (§3.17 item 6)

    /// "Smart log with Coach": opens the Coach over the Journal with the day as its context. ZENO's Coach
    /// cannot write journal answers, so the caption says where answers are saved rather than WHOOP's
    /// "saved automatically". It folds to one row once used ([Z]).
    private var smartLog: some View {
        VStack(spacing: 12) {
            JournalAIEntryCard(title: String(localized: "Smart log with Coach"), collapsed: local.smartLogUsed,
                               showsTalk: true,
                               onText: openSmartLog, onTalk: openSmartLog)
            if !local.smartLogUsed {
                Text(String(localized: "Your answers save when you tap Save Journal"))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func openSmartLog() {
        local.smartLogUsed = true
        let day = isToday ? String(localized: "today") : PulseFormat.navDayTitle(dayKey: Self.dayKey(offset: offset))
        coach.open(String(localized: "I'm filling in my ZENO journal for \(day). Help me remember what I did and what I should log."))
    }

    // MARK: Rows

    private func behaviorRow(_ row: JournalRow) -> some View {
        Group {
            switch row {
            case .mood:
                JournalRowCard(question: String(localized: "How was your mood?")) {
                    JournalValueCapsule(text: current.mood.map(MoodStore.label(for:)) ?? "--",
                                        isSet: current.mood != nil,
                                        accessibilityLabel: String(localized: "Mood")) {
                        sheet = .mood
                    }
                } followUp: { EmptyView() }
            case .behavior(let b):
                let id = PulseBehaviorLibrary.identity(for: b.canonical)
                JournalRowCard(question: b.question, isCustom: b.isCustom) {
                    JournalAnswerToggles(answer: current.answers[id], question: b.question) { setAnswer($0, id: id) }
                } followUp: {
                    if current.answers[id] == true, let followUp = b.followUp {
                        followUpRow(followUp, id: id)
                    }
                }
            }
        }
    }

    /// A plan behaviour goal: its week's ring, then the question, then ✕ / ✓. An AVOID goal asks
    /// "Avoided Late Meal?", so its ✓ stores "no" for the behaviour and its follow-up hangs off ✕ (§3.17
    /// item 7).
    private func planRow(_ row: JournalPlanRow, snapshot s: JournalDaySnapshot) -> some View {
        let id = PulseBehaviorLibrary.identity(for: row.behavior.canonical)
        let avoid = row.goal.avoid == true
        let stored = current.answers[id]
        let shown = avoid ? stored.map { !$0 } : stored
        let todayMet = avoid ? stored == false : stored == true
        let done = (s.planDoneElsewhere[id] ?? 0) + (todayMet ? 1 : 0)
        let question = avoid ? String(localized: "Avoided \(row.behavior.title)?") : row.behavior.question
        return JournalRowCard(question: question,
                              leading: AnyView(PulseGoalRing(kind: .count(done: done, target: max(1, row.goal.days ?? 1)),
                                                             diameter: 36))) {
            JournalAnswerToggles(answer: shown, question: question) { new in
                setAnswer(avoid ? new.map { !$0 } : new, id: id)
            }
        } followUp: {
            if stored == true, let followUp = row.behavior.followUp {
                followUpRow(followUp, id: id)
            }
        }
    }

    private func followUpRow(_ followUp: PulseBehaviorFollowUp, id: String) -> some View {
        let amount = current.amounts[id]
        return JournalFollowUpRow(
            question: followUp.question,
            capsule: JournalValueCapsule(text: amount.map(followUp.valueText) ?? followUp.emptyText,
                                         isSet: amount != nil, accessibilityLabel: followUp.question) {
                sheet = .amount(id: id, followUp: followUp)
            })
    }

    private func setAnswer(_ answer: Bool?, id: String) {
        current.answers[id] = answer
        if answer != true { current.amounts[id] = nil }
    }

    // MARK: Use previous answers (§3.17 item 13 [Z])

    private func showsUsePrevious(_ s: JournalDaySnapshot) -> Bool {
        s.answers.isEmpty && !s.previousAnswers.isEmpty
    }

    private func usePreviousRow(_ s: JournalDaySnapshot) -> some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(get: { usePrevious }, set: { on in applyPrevious(on, s) })) {
                EmptyView()
            }
            .labelsHidden()
            .tint(PulseTheme.JournalPlan.switchOn)
            Text(String(localized: "Use previous answers"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Fills today with the answers you saved the day before"))
    }

    private func applyPrevious(_ on: Bool, _ s: JournalDaySnapshot) {
        usePrevious = on
        if on {
            let previous = Self.state(answers: s.previousAnswers, amounts: s.previousAmounts)
            current.answers = previous.answers
            current.amounts = previous.amounts
        } else {
            current.answers = original.answers
            current.amounts = original.amounts
        }
    }

    // MARK: Notes (§3.17 item 11)

    private var notes: some View {
        VStack(alignment: .leading, spacing: 10) {
            JournalSectionLabel(title: String(localized: "Notes"), rule: false)
            TextField(String(localized: "Add a note..."), text: $current.note, axis: .vertical)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(2...8)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minHeight: 60, alignment: .topLeading)
                .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    .fill(PulseTheme.JournalPlan.notesFill))
                .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    .strokeBorder(PulseTheme.JournalPlan.notesBorder, lineWidth: 1))
                .accessibilityLabel(String(localized: "Notes"))
        }
    }

    // MARK: Save (§3.17 item 12)

    private var saveBar: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [PulseTheme.JournalPlan.pageBottom.opacity(0), PulseTheme.JournalPlan.pageBottom],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: PulseTheme.JournalPlan.saveFade)
                .allowsHitTesting(false)
            Button {
                Task { await save(then: .close) }
            } label: {
                Text(String(localized: "Save Journal"))
                    .pulseText(.capsuleLabel)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, minHeight: PulseTheme.JournalPlan.saveHeight)
                    .background(Capsule(style: .continuous).fill(PulseTheme.JournalPlan.saveCapsule))
                    .contentShape(Capsule())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(saving || !isLoaded)
            .padding(.horizontal, PulseTheme.JournalPlan.saveSideMargin - PulseTheme.Layout.pageMargin)
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.bottom, 5)
            .background(PulseTheme.JournalPlan.pageBottom)
        }
    }

    private func save(then next: JournalDialog.Next) async {
        guard let s = snapshot, isLoaded, !saving else { return }
        saving = true
        defer { saving = false }
        let day = s.dayKey
        let rowKeys = rowCanonicals(s)
        // The day's stored questions, by behaviour, so a behaviour answered under another spelling is
        // rewritten under the row's own key rather than left as a second answer.
        var storedKeys: [String: [String]] = [:]
        for q in s.answers.keys { storedKeys[PulseBehaviorLibrary.identity(for: q), default: []].append(q) }

        var written: [(key: String, answer: Bool?, amount: Double?)] = []
        for id in Set(current.answers.keys).union(original.answers.keys).union(current.amounts.keys) {
            let new = current.answers[id], old = original.answers[id]
            let newAmount = new == true ? current.amounts[id] : nil
            let oldAmount = original.amounts[id]
            guard new != old || newAmount != oldAmount else { continue }
            guard let key = rowKeys[id] ?? storedKeys[id]?.first else { continue }
            for other in storedKeys[id] ?? [] where other != key {
                await repo.clearJournalAnswer(day: day, question: other)
            }
            switch new {
            case .none:
                await repo.clearJournalAnswer(day: day, question: key)
            case .some(true):
                if let amount = newAmount {
                    await repo.saveJournalNumeric(day: day, question: key, value: amount)
                } else {
                    await repo.saveJournalAnswer(day: day, question: key, answeredYes: true)
                }
            case .some(false):
                await repo.saveJournalAnswer(day: day, question: key, answeredYes: false)
            }
            written.append((key, new, newAmount))
        }
        if let mood = current.mood, mood != original.mood {
            await repo.saveMood(day: day, value: mood)
        }
        if current.note != original.note {
            local.setNote(current.note, for: day)
        }

        // Read the day back: what the screen says was saved must be what the journal now holds.
        let storedAnswers = await repo.nativeJournalAnswers(day: day)
        let storedAmounts = await repo.nativeJournalNumeric(day: day)
        let moodSaved = current.mood == nil ? true : await repo.mood(day: day) == current.mood
        let ok = moodSaved && written.allSatisfy { w in
            storedAnswers[w.key] == w.answer && (w.amount == nil || storedAmounts[w.key] == w.amount)
        }
        guard ok else {
            saveFailed = true
            return
        }
        original = current
        usePrevious = false
        switch next {
        case .close:
            dismiss()
        case .switchDay(let n):
            offset = n
            reload &+= 1
        }
    }

    // MARK: Day changes and closing

    private func requestDay(_ n: Int) {
        let target = max(0, min(stripDays - 1, n))
        guard target != offset else { return }
        if hasChanges {
            dialog = .discard(.switchDay(target))
        } else {
            offset = target
        }
    }

    private func attemptClose() {
        if hasChanges && !local.skipDiscardDialog {
            dialog = .discard(.close)
        } else {
            dismiss()
        }
    }

    /// DISCARD CHANGES? ([Z] wording): SAVE JOURNAL, DISCARD, and "don't show again".
    @ViewBuilder
    private var dialogOverlay: some View {
        if case .discard(let next) = dialog {
            JournalDiscardDialog(
                message: isToday ? String(localized: "Your answers for today haven't been saved.")
                                 : String(localized: "Your answers for \(PulseFormat.navDayTitle(dayKey: Self.dayKey(offset: offset))) haven't been saved."),
                dontAskAgain: $dontAskAgain,
                onSave: {
                    dialog = nil
                    commitDontAsk()
                    Task { await save(then: next) }
                },
                onDiscard: {
                    dialog = nil
                    commitDontAsk()
                    current = original
                    usePrevious = false
                    switch next {
                    case .close: dismiss()
                    case .switchDay(let n): offset = n
                    }
                },
                onClose: { dialog = nil })
            .transition(.opacity)
        }
    }

    private func commitDontAsk() {
        if dontAskAgain { local.skipDiscardDialog = true }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(_ s: JournalSheet) -> some View {
        switch s {
        case .select:
            PulseSelectBehaviorsView(catalog: catalog, importedQuestions: snapshot?.importedQuestions ?? [],
                                     onSaved: { reload &+= 1 })
                .environment(model)
        case .calendar:
            PulseJournalCalendarSheet(selectedKey: Self.dayKey(offset: offset), stripDays: stripDays) { picked in
                sheet = nil
                requestDay(picked)
            }
            .environment(model)
        case .amount(let id, let followUp):
            JournalWheelSheet(title: followUp.question, options: followUp.options,
                              initial: followUp.startValue(current.amounts[id]),
                              label: followUp.valueText) { value in
                current.amounts[id] = value
                sheet = nil
            } onCancel: { sheet = nil }
        case .mood:
            JournalWheelSheet(title: String(localized: "How was your mood?"), options: [1, 2, 3, 4, 5],
                              initial: Double(current.mood ?? 3),
                              label: { MoodStore.label(for: Int($0)) }) { value in
                current.mood = Int(value)
                sheet = nil
            } onCancel: { sheet = nil }
        }
    }

    // MARK: Loading

    private func start() {
        guard !didStart else { return }
        didStart = true
        stripDays = min(Self.maxStripDays, max(Self.minStripDays, (dayOffset ?? 0) + 1))
        offset = max(0, min(stripDays - 1, dayOffset ?? 0))
        // The shell handed the router's pending day to `dayOffset`; consume it so it is not reused.
        router.pendingJournalDayOffset = nil
        #if DEBUG
        if let n = JournalPlanDebug.journalDay { offset = max(0, min(stripDays - 1, n)) }
        #endif
    }

    private func load() async {
        #if DEBUG
        await JournalPlanDebug.seedJournalIfRequested(repo: repo)
        #endif
        let off = offset
        let goals = plans.plan?.goals ?? []
        let days = stripDays
        guard let s = await model.build(dayOffset: 0, { builder, r in
            await builder.journalDay(r, offset: off, stripDays: days, planGoals: goals)
        }), s.offset == offset else { return }
        let fresh = Self.state(answers: s.answers, amounts: s.amounts)
        let stored = JournalAnswersState(answers: fresh.answers, amounts: fresh.amounts, mood: s.mood,
                                         note: local.note(for: s.dayKey) ?? "")
        let sameDay = snapshot?.dayKey == s.dayKey
        snapshot = s
        // A refresh landing mid-edit keeps the edits; a new day (or a save) starts from disk.
        if !(sameDay && hasChanges) {
            original = stored
            current = stored
            usePrevious = false
        } else {
            original = stored
        }
        #if DEBUG
        JournalPlanDebug.applyJournalState(current: &current, behaviors: journalLayout(s), sheet: &sheet,
                                           dialog: &dialog, saveFailed: &saveFailed)
        #endif
    }

    /// Native answers keyed by behaviour identity (a day answered under two spellings reads as yes).
    static func state(answers: [String: Bool], amounts: [String: Double]) -> JournalAnswersState {
        var s = JournalAnswersState()
        for (q, yes) in answers {
            let id = PulseBehaviorLibrary.identity(for: q)
            s.answers[id] = (s.answers[id] ?? false) || yes
        }
        for (q, v) in amounts where answers[q] == true {
            s.amounts[PulseBehaviorLibrary.identity(for: q)] = v
        }
        return s
    }

    // MARK: Layout

    /// The plan's behaviour rows and the sections' rows: every selected catalog behaviour once (the first
    /// spelling of a behaviour wins, imported wording first), the plan's behaviours lifted out into their
    /// own section, and the mood check-in when selected. Alphabetical by question within a section.
    func journalLayout(_ s: JournalDaySnapshot) -> JournalLayout {
        let items = catalog.resolvedItems(imported: s.importedQuestions)
        var seen = Set<String>()
        var behaviors: [PulseBehavior] = []
        for item in items {
            let b = PulseBehaviorLibrary.behavior(for: item, customTitles: local.customTitles)
            if seen.insert(PulseBehaviorLibrary.identity(for: b.canonical)).inserted { behaviors.append(b) }
        }
        var planRows: [JournalPlanRow] = []
        var planIDs = Set<String>()
        for goal in plans.plan?.behaviorGoals ?? [] {
            guard let subject = goal.subject else { continue }
            let id = PulseBehaviorLibrary.identity(for: subject)
            guard !planIDs.contains(id) else { continue }
            let behavior = behaviors.first { PulseBehaviorLibrary.identity(for: $0.canonical) == id }
                ?? PulseBehaviorLibrary.definition(for: subject).map(PulseBehaviorLibrary.suggestion)
            if let behavior {
                planRows.append(JournalPlanRow(goal: goal, behavior: behavior))
                planIDs.insert(id)
            }
        }
        var rows: [PulseJournalSection: [JournalRow]] = [:]
        for b in behaviors where !planIDs.contains(PulseBehaviorLibrary.identity(for: b.canonical)) {
            rows[b.section, default: []].append(.behavior(b))
        }
        if local.moodIsSelected { rows[.daytime, default: []].append(.mood) }
        let sections = PulseJournalSection.allCases.compactMap { section -> (section: PulseJournalSection, rows: [JournalRow])? in
            guard let r = rows[section], !r.isEmpty else { return nil }
            return (section, r.sorted { $0.sortKey.localizedCaseInsensitiveCompare($1.sortKey) == .orderedAscending })
        }
        return JournalLayout(planRows: planRows, sections: sections)
    }

    /// The key each shown behaviour writes under.
    private func rowCanonicals(_ s: JournalDaySnapshot) -> [String: String] {
        let layout = journalLayout(s)
        var out: [String: String] = [:]
        for row in layout.planRows { out[PulseBehaviorLibrary.identity(for: row.behavior.canonical)] = row.behavior.canonical }
        for group in layout.sections {
            for row in group.rows {
                if case .behavior(let b) = row { out[PulseBehaviorLibrary.identity(for: b.canonical)] = b.canonical }
            }
        }
        return out
    }

    // MARK: Text

    private var dayTitle: String {
        isToday ? String(localized: "Today") : PulseFormat.navDayTitle(dayKey: Self.dayKey(offset: offset))
    }

    private var questionText: String {
        let key = Self.dayKey(offset: offset)
        switch offset {
        case 0:
            return String(localized: "What's happening today, \(PulseFormat.dayLabel(key, template: "MMMMd"))?")
        case 1:
            return String(localized: "What happened yesterday, \(PulseFormat.dayLabel(key, template: "MMMMd"))?")
        default:
            return String(localized: "What happened on \(PulseFormat.dayLabel(key, template: "EEEMMMMd"))?")
        }
    }

    /// The local day key `n` days back from today's logical day, as Home's strip and the builder count.
    static func dayKey(offset n: Int) -> String {
        let logical = Repository.logicalDay(Date())
        return Repository.localDayKey(Calendar.current.date(byAdding: .day, value: -n, to: logical) ?? logical)
    }
}

// MARK: - State and layout types

/// The Journal's answers for one day, keyed by behaviour identity.
struct JournalAnswersState: Equatable {
    var answers: [String: Bool] = [:]
    var amounts: [String: Double] = [:]
    var mood: Int?
    var note = ""
}

/// A row in a journal section.
enum JournalRow: Identifiable {
    case behavior(PulseBehavior)
    case mood

    var id: String {
        switch self {
        case .behavior(let b): return b.canonical
        case .mood: return PulseBehaviorLibrary.moodID
        }
    }

    /// Rows sort by their question.
    var sortKey: String {
        switch self {
        case .behavior(let b): return b.question
        case .mood: return String(localized: "How was your mood?")
        }
    }
}

/// A plan behaviour goal's journal row.
struct JournalPlanRow {
    let goal: PulsePlanGoal
    let behavior: PulseBehavior
}

struct JournalLayout {
    let planRows: [JournalPlanRow]
    let sections: [(section: PulseJournalSection, rows: [JournalRow])]
}

enum JournalSheet: Identifiable {
    case select
    case calendar
    case amount(id: String, followUp: PulseBehaviorFollowUp)
    case mood

    var id: String {
        switch self {
        case .select: return "select"
        case .calendar: return "calendar"
        case .amount(let id, _): return "amount-\(id)"
        case .mood: return "mood"
        }
    }
}

enum JournalDialog: Equatable {
    enum Next: Equatable {
        case close
        case switchDay(Int)
    }

    case discard(Next)
}

// MARK: - Background

/// The Journal's fixed gradient: sand for today, purple for a past day, ≈520 pt tall and flat below.
struct JournalBackground: View {
    let isToday: Bool

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(stops: isToday ? PulseTheme.JournalPlan.todayStops : PulseTheme.JournalPlan.pastDayStops,
                           startPoint: .top, endPoint: .bottom)
                .frame(height: PulseTheme.JournalPlan.pageGradientHeight)
            PulseTheme.JournalPlan.pageBottom
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Discard dialog (§3.17 "Dismiss confirmation")

/// A centred dialog card over a deep dim: "DISCARD CHANGES?", the body, a "Don't show this again" check,
/// a white SAVE JOURNAL capsule and a DISCARD text button.
struct JournalDiscardDialog: View {
    let message: String
    @Binding var dontAskAgain: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            PulseTheme.dialogScrim.ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    PulseCloseButton(action: onClose)
                }
                .padding(.bottom, -14)
                Text(String(localized: "Discard changes?"))
                    .pulseText(.capsuleLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button { dontAskAgain.toggle() } label: {
                    HStack(spacing: 10) {
                        JournalCheckbox(checked: dontAskAgain)
                        Text(String(localized: "Don't show this again"))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                    .frame(minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityAddTraits(dontAskAgain ? .isSelected : [])
                Button(action: onSave) {
                    Text(String(localized: "Save Journal"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, minHeight: PulseTheme.JournalPlan.saveHeight)
                        .background(Capsule(style: .continuous).fill(PulseTheme.JournalPlan.saveCapsule))
                        .contentShape(Capsule())
                }
                .buttonStyle(PulsePressStyle())
                Button(action: onDiscard) {
                    Text(String(localized: "Discard"))
                        .pulseText(.capsuleLabel)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.dialog, style: .continuous)
                .fill(LinearGradient(colors: [PulseTheme.dialogTop, PulseTheme.dialogBottom],
                                     startPoint: .top, endPoint: .bottom)))
            .padding(.horizontal, 28)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }
}

// MARK: - Wheel sheet

/// A follow-up's or the mood's wheel, in the shared wheel-picker sheet.
struct JournalWheelSheet: View {
    let title: String
    let options: [Double]
    let label: (Double) -> String
    let onConfirm: (Double) -> Void
    let onCancel: () -> Void
    @State private var value: Double

    init(title: String, options: [Double], initial: Double, label: @escaping (Double) -> String,
         onConfirm: @escaping (Double) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.options = options
        self.label = label
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        let nearest = options.min { abs($0 - initial) < abs($1 - initial) } ?? initial
        _value = State(initialValue: nearest)
    }

    var body: some View {
        PulseWheelPickerSheet(title: title, options: options, selection: $value, label: label,
                              onConfirm: { onConfirm(value) }, onCancel: onCancel)
            .presentationDetents([.height(380)])
    }
}
#endif
