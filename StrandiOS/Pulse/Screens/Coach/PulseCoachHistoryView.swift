#if os(iOS)
import SwiftUI

// MARK: - Conversation history (WHOOP_UI_SPEC §3.16 [Z]: "a clock icon left of Memory opens a sheet of local
// threads. Each row: the title (first user message), a 2-line snippet of the last message, a relative date;
// swipe to delete.")
//
// WHOOP's own history list was never captured, so the rows use the settings-row card language: the title
// in 15 pt Semibold, the snippet in 13 pt at 70%, the date at the right in 12 pt at 50%, on 10 pt gaps.

struct PulseCoachHistoryView: View {
    /// The conversation on screen in the sheet, marked "Current".
    let currentID: UUID?
    let onOpen: (PulseCoachThread) -> Void

    @Environment(\.dismiss) private var dismiss
    private var store: PulseCoachThreadStore { PulseCoachThreadStore.shared }

    var body: some View {
        NavigationStack {
            Group {
                if store.threads.isEmpty {
                    empty
                } else {
                    List {
                        ForEach(store.threads) { thread in
                            Button {
                                onOpen(thread)
                                dismiss()
                            } label: {
                                row(thread)
                            }
                            .buttonStyle(PulsePressStyle())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: PulseTheme.Layout.pageMargin, bottom: 5,
                                                      trailing: PulseTheme.Layout.pageMargin))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.delete(thread.id)
                                } label: {
                                    Label(String(localized: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(PulseCoachBackground())
            .safeAreaInset(edge: .top, spacing: 0) { bar }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environment(\.colorScheme, .dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { store.loadIfNeeded() }
    }

    /// "HISTORY ✕", Pulse's sheet header.
    private var bar: some View {
        ZStack {
            Text(String(localized: "History"))
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Spacer()
                PulseCloseButton { dismiss() }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .frame(height: PulseTheme.Header.navBar)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func row(_ thread: PulseCoachThread) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(thread.title)
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                Text(thread.snippet)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 6) {
                Text(thread.updatedAt.formatted(.relative(presentation: .named)))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                if thread.id == currentID {
                    PulseTag(String(localized: "Current"), outlined: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground(.rowCard)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Opens this conversation. Swipe to delete."))
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(PulseTheme.textTertiary)
            Text(String(localized: "No conversations yet"))
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(String(localized: "Your conversations with Coach are kept here, on this iPhone."))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The Coach sheet's ground: near-black with an indigo glow at the top (§2.1 "Coach sheet").
struct PulseCoachBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: PulseTheme.Gradients.coachSheet, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [PulseTheme.Coach.halo.opacity(1.6), Color.clear], center: .topLeading,
                           startRadius: 0, endRadius: 360)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
#endif
