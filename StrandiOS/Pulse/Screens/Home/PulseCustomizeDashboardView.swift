#if os(iOS)
import SwiftUI

/// Customize Dashboard (WHOOP_UI_SPEC §3.13, reviews/04, reviews/r110), presented as a full-screen modal:
/// "✕ · CUSTOMIZE DASHBOARD"; the dashboard's items as 57 pt cards in their order, each with a "–" at the
/// left [Z] (WHOOP members could not find how to remove one) and the ≡ drag handle at the right, a small
/// bar-chart glyph on the two chart cards; then "ADD TO MY DASHBOARD" and every other item with a "+";
/// and SAVE pinned at the bottom, a recovery-blue outline capsule (322 × 52) that wakes once something
/// changed.
///
/// Edits are a draft (`EditableLayoutDraft`, the classic Today layout editor's model): nothing is stored
/// until SAVE, "✕" discards, and a removed item only moves to the add list. The dashboard keeps at least
/// one item.
///
/// Owned by group "home".
struct PulseCustomizeDashboardView: View {
    /// Rebuilt: CUSTOMIZE ✎ opens this.
    static let isRebuilt = true

    @AppStorage(PulseDashboardLayout.storageKey) private var stored = ""
    @State private var draft: EditableLayoutDraft<PulseDashboardItem>?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var saved: [PulseDashboardItem] { PulseDashboardLayout.decode(stored) }

    private var isDirty: Bool {
        guard let draft else { return false }
        return draft.visible != saved
    }

    var body: some View {
        List {
            if let draft {
                Section {
                    ForEach(draft.visible) { item in
                        currentRow(item, canRemove: draft.visible.count > 1)
                    }
                    .onMove { from, to in self.draft?.moveVisible(from: from, to: to) }
                }
                Section {
                    ForEach(draft.hidden) { item in
                        addRow(item)
                            .moveDisabled(true)
                    }
                } header: {
                    PulseListSectionHeader(String(localized: "Add to My Dashboard"))
                        .padding(.top, PulseTheme.Space.l)
                        .padding(.bottom, PulseTheme.Space.xxs)
                        .listRowInsets(EdgeInsets(top: 0, leading: PulseTheme.Layout.pageMargin, bottom: 0,
                                                  trailing: PulseTheme.Layout.pageMargin))
                }
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
        .contentMargins(.top, PulseTheme.Space.s, for: .scrollContent)
        .background(PulseBackground())
        .overlay(alignment: .top) {
            PulseTopBackdrop(fade: PulseTheme.Space.s)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { saveBar }
        .pulseNavHeader(String(localized: "Customize Dashboard"))
        .environment(\.colorScheme, .dark)
        .onAppear {
            if draft == nil {
                draft = EditableLayoutDraft(visible: saved, allItems: PulseDashboardItem.allCases)
            }
        }
    }

    // MARK: Rows

    private func currentRow(_ item: PulseDashboardItem, canRemove: Bool) -> some View {
        HStack(spacing: PulseTheme.Space.s) {
            Button {
                withAnimation(animation) { draft?.hide(item) }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(canRemove ? PulseTheme.textSecondary : PulseTheme.textDisabled)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(!canRemove)
            .padding(.leading, -PulseTheme.Space.s)
            .accessibilityLabel(String(localized: "Remove \(item.title)"))
            rowLabel(item)
            if item.isChart {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .accessibilityLabel(String(localized: "Chart"))
            }
        }
        .modifier(PulseCustomizeRowStyle())
    }

    private func addRow(_ item: PulseDashboardItem) -> some View {
        Button {
            withAnimation(animation) { draft?.show(item) }
        } label: {
            HStack(spacing: PulseTheme.Space.s) {
                rowLabel(item)
                if item.isChart {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .accessibilityHidden(true)
                }
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: 28)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Add \(item.title)"))
        .modifier(PulseCustomizeRowStyle())
    }

    private func rowLabel(_ item: PulseDashboardItem) -> some View {
        HStack(spacing: PulseTheme.Space.s) {
            Image(systemName: item.symbol)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            PulseWordWrapText(item.title, style: .cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: PulseTheme.Space.xs)
        }
    }

    // MARK: Save

    private var saveBar: some View {
        Button {
            if let draft { stored = PulseDashboardLayout.encode(draft.visible) }
            dismiss()
        } label: {
            Text(String(localized: "Save"))
                .frame(minHeight: 52)
        }
        .buttonStyle(.pulseOutline(isDirty ? PulseTheme.recoveryBlue : PulseTheme.textDisabled))
        .disabled(!isDirty)
        // 322 pt on WHOOP's 393 pt screen: ≈36 pt in from each edge.
        .padding(.horizontal, PulseTheme.Space.xl + PulseTheme.Space.xxs)
        .padding(.top, PulseTheme.Space.s)
        .padding(.bottom, PulseTheme.Space.m)
        .background(alignment: .top) {
            // Rows fade out above the pinned button rather than meeting a hard edge.
            LinearGradient(colors: [PulseTheme.pageBottom.opacity(0), PulseTheme.pageBottom],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: PulseTheme.Space.xl)
                .offset(y: -PulseTheme.Space.xl)
                .allowsHitTesting(false)
        }
        .background(PulseTheme.pageBottom.ignoresSafeArea(edges: .bottom))
        .accessibilityHint(isDirty ? "" : String(localized: "Make a change to save"))
    }

    private var animation: Animation? {
        PulseMotion.resolved(PulseMotion.chrome, reduceMotion: reduceMotion)
    }
}

/// A Customize row: its own 57 pt white-10% card, 12 pt apart, inside the page margins.
private struct PulseCustomizeRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.leading, PulseTheme.Layout.cardPadding)
            .padding(.trailing, PulseTheme.Space.xs)
            .frame(minHeight: 57)
            .listRowInsets(EdgeInsets(top: PulseTheme.Space.xs - 2, leading: PulseTheme.Layout.pageMargin,
                                      bottom: PulseTheme.Space.xs - 2, trailing: PulseTheme.Layout.pageMargin))
            .listRowBackground(
                PulseCardSurface()
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.vertical, PulseTheme.Space.xs - 2))
            .listRowSeparator(.hidden)
    }
}
#endif
