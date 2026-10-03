#if os(iOS)
import SwiftUI

/// "‹ MEMORY DETAIL" pushed from a memory card outside the Coach sheet.
struct PulseMemoryDetailRoute: PulseScreenRoute {
    let id: UUID
    var view: some View { PulseMemoryDetailView(id: id) }
}

/// Memory Detail (WHOOP_UI_SPEC §3.16; profile-community-2026/72): the title (22 pt), the detail, its category
/// tag, the Active card with its switch, "Share something new", and the conversations it came from. The trash
/// at the top right deletes it, after a confirmation.
struct PulseMemoryDetailView: View {
    let id: UUID
    var inCoachSheet = false

    @Environment(\.dismiss) private var dismiss
    @State private var composer: PulseMemoryComposer.Mode?
    @State private var confirmDelete = false

    private var store: PulseMemoryStore { PulseMemoryStore.shared }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Memory Detail"),
                            trailing: .symbol("trash", accessibilityLabel: String(localized: "Delete memory")) {
                                confirmDelete = true
                            },
                            coach: inCoachSheet ? .none : .button) {
            if let item = store.item(id) {
                content(item)
            } else {
                Text(String(localized: "This memory was deleted."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, 24)
            }
        }
        .sheet(item: $composer) { mode in PulseMemoryComposer(mode: mode) { _ in } }
        .confirmationDialog(String(localized: "Delete this memory?"), isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button(String(localized: "Delete"), role: .destructive) {
                store.delete(id)
                dismiss()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "Coach will no longer use it. This can't be undone."))
        }
    }

    private func content(_ item: PulseMemoryItem) -> some View {
        // A title cut short of its sentence would only repeat the start of the text under it: show the whole
        // memory as the title then, and the text under it only when it says more.
        let heading = item.title.hasSuffix("…") ? item.detail : item.title
        return VStack(alignment: .leading, spacing: 0) {
            Text(heading)
                .pulseText(.weeklyTrendsTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
                .accessibilityAddTraits(.isHeader)
            if item.detail != heading {
                Text(item.detail)
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            PulseMemoryTag(text: item.category.title, filled: false)
                .padding(.top, 16)

            activeCard(item)
                .padding(.top, 28)

            PulseMemoryShareCard(compact: true, onText: { composer = .text }, onTalk: { composer = .talk })
                .padding(.top, 24)

            relevant(item)
                .padding(.top, 28)
        }
    }

    private func activeCard(_ item: PulseMemoryItem) -> some View {
        let active = Binding(get: { store.item(id)?.isActive ?? false }, set: { store.setActive(id, $0) })
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(item.isActive ? AnyShapeStyle(aiText) : AnyShapeStyle(PulseTheme.textTertiary))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.isActive ? String(localized: "Active") : String(localized: "Inactive"))
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(item.isActive ? String(localized: "This is actively influencing your coaching.")
                                   : String(localized: "Kept, but not used in your coaching."))
                    .pulseText(.rowSubline)
                    .foregroundStyle(item.isActive ? AnyShapeStyle(aiText) : AnyShapeStyle(PulseTheme.textTertiary))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle(String(localized: "Active"), isOn: active)
                .labelsHidden()
                .tint(PulseTheme.Gradients.aiRing.stops.first?.color ?? PulseTheme.recoveryBlue)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(PulseTheme.Gradients.pillRead))
        .accessibilityElement(children: .combine)
    }

    private var aiText: LinearGradient {
        LinearGradient(gradient: PulseTheme.Gradients.aiText, startPoint: .leading, endPoint: .trailing)
    }

    @ViewBuilder
    private func relevant(_ item: PulseMemoryItem) -> some View {
        let threads = item.sourceThreadIDs.compactMap { PulseCoachThreadStore.shared.thread($0) }
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Relevant Conversations"))
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            if threads.isEmpty {
                Text(String(localized: "You added this yourself in My Memory."))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
            } else {
                ForEach(threads) { thread in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(verbatim: "•").foregroundStyle(PulseTheme.textTertiary)
                        Text(thread.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                            .pulseText(.coachingTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Text(thread.title)
                            .pulseText(.rowSubline)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .onAppear { PulseCoachThreadStore.shared.loadIfNeeded() }
    }
}

// MARK: - Share something new (TEXT / TALK)

/// Type or say something for Coach to keep in mind, pick its category, save. The first sentence becomes the
/// title. TALK dictates on this iPhone with the same `CoachVoiceInput` the composer uses.
struct PulseMemoryComposer: View {
    enum Mode: String, Identifiable {
        case text, talk
        var id: String { rawValue }
    }

    let mode: Mode
    var initialText = ""
    var sourceThread: UUID?
    let onClose: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var voice = CoachVoiceInput()
    @State private var text = ""
    @State private var category: PulseMemoryItem.Category = .lifestyle
    @State private var listening = false
    @State private var voiceStatus: String?
    @State private var started = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Text(String(localized: "Share something new"))
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                HStack {
                    Spacer()
                    PulseCloseButton { close(saved: false) }
                }
            }
            .frame(height: PulseTheme.Header.navBar)
            .padding(.top, 12)

            Text(String(localized: "What should Coach keep in mind?"))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 18)
            Text(String(localized: "A goal, your routine, an injury, a busy week. One thing at a time works best."))
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
                .padding(.top, 6)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($focused)
                    .frame(minHeight: 120, maxHeight: 200)
                if text.isEmpty {
                    Text(listening ? String(localized: "Listening…") : String(localized: "Training for a half marathon in May"))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textDisabled)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .fill(PulseTheme.Onboarding.fieldFill))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.aiInputBorder, startPoint: .leading,
                                             endPoint: .trailing), lineWidth: 1.5)
                .opacity(focused || listening ? 1 : 0.5))
            .padding(.top, 18)

            HStack(spacing: 12) {
                Button(action: toggleListening) {
                    Label(listening ? String(localized: "Stop") : String(localized: "Talk"),
                          systemImage: listening ? "stop.fill" : "mic")
                }
                .buttonStyle(.pulseNested)
                Spacer(minLength: 0)
            }
            .padding(.top, 12)
            if let voiceStatus {
                Text(voiceStatus)
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.top, 6)
            }

            PulseListSectionHeader(String(localized: "Category"))
                .padding(.top, 24)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PulseMemoryItem.Category.allCases) { c in
                        PulseFilterChip(title: c.title, isSelected: category == c) { category = c }
                    }
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .padding(.horizontal, -PulseTheme.Layout.pageMargin)
            .padding(.top, 12)

            Spacer(minLength: 24)

            Button(action: save) { Text(String(localized: "Save to My Memory")) }
                .buttonStyle(.pulseFilledWhite)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .background(PulseCoachBackground())
        .environment(\.colorScheme, .dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            guard !started else { return }
            started = true
            text = initialText
            if mode == .talk { toggleListening() } else { focused = true }
        }
        .onDisappear {
            if listening { voice.stopTranscribing { _ in } }
        }
    }

    private func toggleListening() {
        voiceStatus = nil
        if listening {
            voice.stopTranscribing { final in
                append(final)
                listening = false
            }
            return
        }
        let begin = {
            guard voice.canUseVoice else {
                voiceStatus = voice.statusMessage ?? String(localized: "On-device speech isn't available for your language.")
                return
            }
            focused = false
            listening = true
            let base = text
            voice.startTranscribing { partial in
                text = base.isEmpty ? partial : base + " " + partial
            }
        }
        switch voice.authorization {
        case .notDetermined:
            voice.requestAuthorization { state in
                if state == .authorized { begin() } else {
                    voiceStatus = String(localized: "Allow speech recognition and the microphone in Settings to talk.")
                }
            }
        case .authorized:
            begin()
        case .denied:
            voiceStatus = String(localized: "Allow speech recognition and the microphone in Settings to talk.")
        case .unavailable:
            voiceStatus = String(localized: "Voice input isn't available on this iPhone.")
        }
    }

    private func append(_ final: String) {
        let heard = final.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !heard.isEmpty, !text.contains(heard) else { return }
        text = text.isEmpty ? heard : text + " " + heard
    }

    private func save() {
        if listening { voice.stopTranscribing { _ in } }
        let saved = PulseMemoryStore.shared.add(text, category: category, sourceThread: sourceThread) != nil
        close(saved: saved)
    }

    private func close(saved: Bool) {
        onClose(saved)
        dismiss()
    }
}
#endif
