#if os(iOS)
import SwiftUI

/// Customize Dashboard (WHOOP_UI_SPEC §3.13, reviews/04, reviews/r110), presented as a full-screen modal:
/// "✕ · CUSTOMIZE DASHBOARD"; the dashboard's items as 57 pt cards in their order, each with a "–" [Z]
/// (WHOOP members could not find how to remove one) beside the ≡ drag handle at the right, a small
/// bar-chart glyph on the two chart cards; then "ADD TO MY DASHBOARD" and every other item with a "+", A to Z.
/// Both lists keep their names in one column ≈42 pt in from the card, as WHOOP's do. SAVE is pinned at the
/// bottom, a recovery-blue outline capsule (322 × 52) that wakes once something changed.
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
    /// The icon column (20 pt) and the "–" / "+" column (28 pt), scaling with their glyphs.
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 20
    @ScaledMetric(relativeTo: .title3) private var controlWidth: CGFloat = 28
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
                    ForEach(Self.alphabetical(draft.hidden)) { item in
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

    /// ADD TO MY DASHBOARD in alphabetical order, as WHOOP lists it (reviews/04: AVERAGE HEART RATE,
    /// CALORIES, HOURS OF SLEEP, HR ZONES 1-3 …; r110), so a removed item lands in its place. Only the
    /// list shown is sorted: the draft's `hidden` keeps its order for the classic layout editors.
    private static func alphabetical(_ items: [PulseDashboardItem]) -> [PulseDashboardItem] {
        items.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    // MARK: Rows

    /// A current item: icon and name in the same column as the add list's (≈42 pt in, reviews/04 and
    /// r110), then the chart mark, the "–" [Z] and the system's ≡ handle at the right.
    private func currentRow(_ item: PulseDashboardItem, canRemove: Bool) -> some View {
        HStack(spacing: PulseTheme.Space.xs) {
            rowLabel(item)
            chartMark(item)
            Button {
                withAnimation(animation) { draft?.hide(item) }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .pulseHomeGlyph(.customizeControl)
                    .foregroundStyle(canRemove ? PulseTheme.textSecondary : PulseTheme.textDisabled)
                    .frame(minWidth: controlWidth, minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(!canRemove)
            .accessibilityLabel(String(localized: "Remove \(item.title)"))
        }
        .modifier(PulseCustomizeRowStyle())
    }

    private func addRow(_ item: PulseDashboardItem) -> some View {
        Button {
            withAnimation(animation) { draft?.show(item) }
        } label: {
            HStack(spacing: PulseTheme.Space.xs) {
                rowLabel(item)
                chartMark(item)
                Image(systemName: "plus")
                    .pulseHomeGlyph(.customizeControl)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(minWidth: controlWidth)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Add \(item.title)"))
        .modifier(PulseCustomizeRowStyle())
    }

    /// The icon in a fixed column, then the name: the same leading slot in both lists.
    private func rowLabel(_ item: PulseDashboardItem) -> some View {
        HStack(spacing: PulseTheme.Space.xs) {
            Image(systemName: item.symbol)
                .pulseHomeGlyph(.customizeIcon)
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            PulseWordWrapText(item.title, style: .cardTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: PulseTheme.Space.xs)
        }
    }

    /// The small bar-chart mark on the two chart cards.
    @ViewBuilder
    private func chartMark(_ item: PulseDashboardItem) -> some View {
        if item.isChart {
            Image(systemName: "chart.bar.xaxis")
                .pulseHomeGlyph(.chartMark)
                .foregroundStyle(PulseTheme.textTertiary)
                .accessibilityLabel(String(localized: "Chart"))
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

/// A Customize row: its own 57 pt white-10% card, 12 pt apart, inside the page margins; the icon 14 pt in
/// and the name at 42 pt (reviews/04: ≈41-45 pt in both lists).
private struct PulseCustomizeRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.leading, PulseTheme.Space.s + 2)
            .padding(.trailing, PulseTheme.Space.xs)
            .padding(.vertical, PulseTheme.Space.xs)
            .frame(minHeight: PulseHomeMetrics.customizeRow)
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
