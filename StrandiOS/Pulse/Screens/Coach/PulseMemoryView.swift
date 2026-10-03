#if os(iOS)
import SwiftUI

/// My Memory (WHOOP_UI_SPEC §3.16 "My Memory"; profile-community-2026/27, 72, 73, help-center/07), pushed from
/// Profile's MY MEMORY row and from the Coach sheet's "Memory" button.
///
/// "Shape your ZENO experience." with the wearer's avatar, the "Share something new" card (TEXT / TALK) and
/// "HOW DOES ZENO MEMORY WORK? →"; once something is saved, a "Context updated" toast, category chips, dated
/// sections and memory cards ("New" pill, "Active" and category tags, the newest with the violet → cyan
/// border). Everything here was typed or said by the wearer and is stored only on this iPhone.
struct PulseMemoryView: View {
    /// Rebuilt: entry points open this screen.
    static let isRebuilt = true

    /// Inside the Coach sheet the page floats no Coach button of its own.
    var inCoachSheet = false
    /// The Coach sheet's own stack pushes the detail; elsewhere the route does.
    var onOpenDetail: ((UUID) -> Void)?

    @EnvironmentObject private var profile: ProfileStore
    /// Observed so the avatar's initials follow an edit; read through `PulseProfileIdentity.storedName`, the
    /// trimmed name Profile shows.
    @AppStorage(PulseProfileIdentity.nameKey) private var storedName = ""
    @Environment(\.pulseNavigator) private var navigator
    @State private var composer: PulseMemoryComposer.Mode?
    @State private var filter: PulseMemoryItem.Category?
    @State private var toastUntil: Date?
    @State private var showsExplainer = false

    private var store: PulseMemoryStore { PulseMemoryStore.shared }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "My Memory"), coach: inCoachSheet ? .none : .button) {
            VStack(alignment: .leading, spacing: 0) {
                if let until = toastUntil, until > Date() {
                    PulseMemoryToast()
                        .padding(.top, 8)
                        .transition(.opacity)
                }
                header
                    .padding(.top, 22)
                PulseMemoryShareCard(onText: { composer = .text }, onTalk: { composer = .talk },
                                     onExplain: { showsExplainer = true })
                    .padding(.top, 26)
                if !store.items.isEmpty {
                    chips
                        .padding(.top, 24)
                    sections
                }
            }
        }
        .onAppear { store.loadIfNeeded() }
        .sheet(item: $composer) { mode in
            PulseMemoryComposer(mode: mode) { saved in
                if saved { showToast() }
            }
        }
        .sheet(isPresented: $showsExplainer) { PulseMemoryExplainer() }
        #if DEBUG
        .task { openDebugComposerIfAsked() }
        #endif
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Shape your ZENO experience."))
                    .pulseText(.onboardingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(String(localized: "Help Coach understand you better."))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            Spacer(minLength: 0)
            PulseAvatar(imageData: profile.avatarImageData, name: PulseProfileIdentity.storedName, size: 56)
        }
    }

    private var categories: [PulseMemoryItem.Category] {
        PulseMemoryItem.Category.allCases.filter { c in store.items.contains { $0.category == c } }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PulseFilterChip(title: String(localized: "Timeline"), isSelected: filter == nil) { filter = nil }
                ForEach(categories) { c in
                    PulseFilterChip(title: c.title, isSelected: filter == c) { filter = c }
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .padding(.horizontal, -PulseTheme.Layout.pageMargin)
    }

    /// Dated sections: "TODAY", then "TUE, SEP 29, 2026".
    private var sections: some View {
        let visible = store.items.filter { filter == nil || $0.category == filter }
        let groups = Dictionary(grouping: visible) { Calendar.current.startOfDay(for: $0.createdAt) }
        let days = groups.keys.sorted(by: >)
        let newest = store.items.first?.id
        return ForEach(days, id: \.self) { day in
            PulseListSectionHeader(Calendar.current.isDateInToday(day)
                                   ? String(localized: "Today")
                                   : day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                .padding(.top, 26)
                .padding(.bottom, 12)
            VStack(spacing: PulseTheme.Row.listGap) {
                ForEach(groups[day] ?? []) { item in
                    Button { open(item.id) } label: {
                        PulseMemoryCard(item: item, highlighted: item.id == newest && item.isNew())
                    }
                    .buttonStyle(PulsePressStyle())
                }
            }
        }
    }

    private func open(_ id: UUID) {
        if let onOpenDetail {
            onOpenDetail(id)
        } else {
            navigator.push(PulseMemoryDetailRoute(id: id).route)
        }
    }

    private func showToast() {
        withAnimation(PulseMotion.crossFade) { toastUntil = Date().addingTimeInterval(3) }
        Task {
            try? await Task.sleep(nanoseconds: 3_100_000_000)
            withAnimation(PulseMotion.crossFade) { toastUntil = nil }
        }
    }

    #if DEBUG
    private func openDebugComposerIfAsked() {
        if CommandLine.arguments.contains("--memory-add") { composer = .text }
    }
    #endif
}

/// A memory card: title, "New" pill and "›", then "Active" and category tags; the newest one framed in the
/// violet → cyan border.
struct PulseMemoryCard: View {
    let item: PulseMemoryItem
    var highlighted = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(item.title)
                    .pulseText(.rowText)
                    .foregroundStyle(item.isActive ? PulseTheme.textPrimary : PulseTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if item.isNew() {
                    Text(String(localized: "New"))
                        .pulseText(.chipStrong)
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white))
                }
                PulseChevron(color: PulseTheme.textTertiary, size: 14)
                    .padding(.top, 2)
            }
            HStack(spacing: 8) {
                PulseMemoryTag(text: item.isActive ? String(localized: "Active") : String(localized: "Inactive"),
                               filled: item.isActive)
                PulseMemoryTag(text: item.category.title, filled: false)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(PulseTheme.card))
        .overlay {
            if highlighted {
                shape.strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.aiInputBorder, startPoint: .topLeading,
                                                  endPoint: .bottomTrailing), lineWidth: 1.5)
            }
        }
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }
}

/// "Active" (blue fill) or a category (outlined capsule).
struct PulseMemoryTag: View {
    let text: String
    let filled: Bool

    var body: some View {
        Text(text)
            .pulseText(.chip)
            .foregroundStyle(filled ? PulseTheme.recoveryBlue : PulseTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                if filled {
                    shape.fill(PulseTheme.Tint.blue.fill)
                } else {
                    shape.strokeBorder(PulseTheme.outlinedBorder, lineWidth: 1)
                }
            }
    }
}

/// "✓ Context updated / New information applied to Coach." (help-center/07).
struct PulseMemoryToast: View {
    var body: some View {
        HStack(spacing: 12) {
            PulseStatusBadge(.check, tint: .teal, size: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Context updated"))
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.positive)
                Text(String(localized: "New information applied to Coach."))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular).fill(PulseTheme.bannerWell))
        .accessibilityElement(children: .combine)
    }
}

/// The AI entry card (§2.6 item 33): a sparkle, "Share something new", one line, and TEXT / TALK.
struct PulseMemoryShareCard: View {
    var compact = false
    let onText: () -> Void
    let onTalk: () -> Void
    var onExplain: (() -> Void)?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.menu, style: .continuous)
        VStack(alignment: compact ? .leading : .center, spacing: 0) {
            if compact {
                HStack(spacing: 10) {
                    sparkle
                    Text(String(localized: "Share something new"))
                        .pulseText(.subsectionTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
            } else {
                sparkle
                    .font(.system(size: 26, weight: .regular))
                    .padding(.top, 4)
                Text(String(localized: "Share something new"))
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.top, 12)
                Text(String(localized: "The more Coach knows, the better your guidance becomes"))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }
            // The buttons' 2 pt touch margins (`entryButton`) come out of the gaps around them.
            HStack(spacing: 12) {
                entryButton(String(localized: "Text"), symbol: "keyboard", talk: false, action: onText)
                entryButton(String(localized: "Talk"), symbol: "mic", talk: true, action: onTalk)
            }
            .padding(.top, compact ? 14 : 18)
            if let onExplain {
                PulseTextCTA(title: String(localized: "How does ZENO memory work?"), tint: .ai, action: onExplain)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, onExplain == nil ? 16 : 6)
        .frame(maxWidth: .infinity)
        .background(shape.fill(LinearGradient(gradient: PulseTheme.Gradients.aiEntryFill, startPoint: .topLeading,
                                              endPoint: .bottomTrailing)))
        .overlay(shape.strokeBorder(PulseTheme.Gradients.aiEntryBorder, lineWidth: 1))
    }

    private var sparkle: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(PulseTheme.Gradients.aiEntrySparkle)
            .accessibilityHidden(true)
    }

    /// "⌨ TEXT" / "mic TALK": ≈40 pt like the Journal's Smart log buttons (§2.6.33; profile-community-2026/27
    /// measures 39), in a 2 pt margin that makes the touch target 44 pt.
    private func entryButton(_ title: String, symbol: String, talk: Bool, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .continuous)
        return Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(talk ? PulseTheme.Gradients.aiEntryMic : PulseTheme.textSecondary)
                Text(title).pulseText(.buttonLabel).foregroundStyle(PulseTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .background {
                if talk {
                    shape.fill(LinearGradient(gradient: PulseTheme.Gradients.aiEntryTalkButton, startPoint: .leading,
                                              endPoint: .trailing))
                } else {
                    shape.fill(PulseTheme.Gradients.aiEntryTextButton)
                }
            }
            .overlay(shape.strokeBorder(PulseTheme.textPrimary.opacity(0.08), lineWidth: 1))
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }
}

/// "How does ZENO memory work?"
struct PulseMemoryExplainer: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                PulseCloseButton { dismiss() }
            }
            Text(String(localized: "How does ZENO memory work?"))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(String(localized: "My Memory is a short list of things you tell Coach to keep in mind: your goals, your routine, an injury, a big week at work. You add each one yourself, by typing or speaking, or with \"Add to My Memory\" on one of your messages."))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(String(localized: "Active memories go with every question and your morning brief to the provider you chose in AI Settings. Switch one off to keep it without using it, delete it at any time, or turn Memory off in AI Settings."))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(String(localized: "Memories are stored only on this iPhone."))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(PulseTheme.Layout.pageMargin)
        .background(PulseBackground())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .dark)
    }
}
#endif
