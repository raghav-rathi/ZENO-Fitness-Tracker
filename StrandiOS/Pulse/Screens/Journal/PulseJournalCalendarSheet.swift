#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The Journal's calendar (WHOOP_UI_SPEC §3.17 "Calendar", help-center/105): a month grid opened from the
/// date row. Days with a journal entry are teal numbers over a teal dot, the others 50% grey, today in a
/// dashed circle, with "• Journal filled out" under it. "‹ MARCH ›" steps months. The days the strip offers
/// (the last fourteen) open that day's journal; earlier days only show whether they were logged.
struct PulseJournalCalendarSheet: View {
    let selectedKey: String
    let stripDays: Int
    /// The picked day, as days back from today.
    let onPick: (Int) -> Void

    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var monthsBack = 0
    @State private var logged: Set<String> = []

    private var todayKey: String { PulseJournalView.dayKey(offset: 0) }

    /// The shown month, `monthsBack` before the selected day's.
    private var month: (year: Int, month: Int) {
        BehaviorLoggingHistory.months(endingAt: selectedKey, count: 1, pagesBack: monthsBack).first ?? (2026, 1)
    }

    private var pickable: [String: Int] {
        Dictionary(uniqueKeysWithValues: (0..<stripDays).map { (PulseJournalView.dayKey(offset: $0), $0) })
    }

    var body: some View {
        let m = month
        let monthData = BehaviorLoggingHistory.month(year: m.year, month: m.month, yes: logged, no: [], today: todayKey)
        VStack(spacing: 18) {
            HStack {
                pager("chevron.left", enabled: monthsBack < 24, label: String(localized: "Previous month")) { monthsBack += 1 }
                Spacer()
                Text(monthTitle(m))
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                pager("chevron.right", enabled: monthsBack > 0, label: String(localized: "Next month")) { monthsBack -= 1 }
            }
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Self.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                ForEach(0..<monthData.leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 40) }
                ForEach(Array(monthData.marks.enumerated()), id: \.offset) { index, mark in
                    dayCell(day: index + 1, mark: mark, month: m)
                }
            }
            HStack(spacing: 6) {
                Spacer()
                Circle().fill(PulseTheme.Journal.logged).frame(width: 5, height: 5)
                Text(String(localized: "Journal filled out"))
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.Journal.logged)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(PulseTheme.JournalPlan.calendarSheet.ignoresSafeArea())
        .presentationDetents([.height(500), .large])
        .presentationDragIndicator(.visible)
        .environment(\.colorScheme, .dark)
        .task(id: "\(m.year)-\(m.month)|\(model.seq)") { await load(m) }
    }

    private func dayCell(day: Int, mark: BehaviorLoggingHistory.Mark, month m: (year: Int, month: Int)) -> some View {
        let key = String(format: "%04d-%02d-%02d", m.year, m.month, day)
        let isLogged = mark == .yes
        let isToday = key == todayKey
        let offset = pickable[key]
        return Button {
            if let offset { onPick(offset) }
        } label: {
            VStack(spacing: 4) {
                Text(verbatim: "\(day)")
                    .font(PulseType.font(.rowValue))
                    .foregroundStyle(isLogged ? PulseTheme.Journal.logged
                                              : (mark == .future ? PulseTheme.JournalPlan.calendarFuture : PulseTheme.textTertiary))
                    .frame(width: 34, height: 34)
                    .overlay {
                        if isToday {
                            Circle().strokeBorder(PulseTheme.textSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        } else if key == selectedKey {
                            Circle().strokeBorder(PulseTheme.textPrimary, lineWidth: 1.5)
                        }
                    }
                Circle()
                    .fill(isLogged ? PulseTheme.Journal.logged : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(offset == nil)
        .accessibilityLabel(PulseFormat.navDayTitle(dayKey: key))
        .accessibilityValue(isLogged ? String(localized: "Journal filled out") : "")
    }

    private func pager(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(PulseTheme.JournalPlan.rowGlyph)
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    /// "MARCH", or "MARCH 2025" outside this year (UTC, like every day key).
    private func monthTitle(_ m: (year: Int, month: Int)) -> String {
        let key = String(format: "%04d-%02d-01", m.year, m.month)
        let sameYear = todayKey.hasPrefix(String(format: "%04d", m.year))
        return PulseFormat.dayLabel(key, template: sameYear ? "MMMM" : "MMMMyyyy")
    }

    private static var weekdaySymbols: [String] {
        // A Sunday-first week, short names in the app's language (2026-03-01 was a Sunday).
        (0..<7).map { PulseFormat.dayLabel(String(format: "2026-03-%02d", $0 + 1), template: "EEE") }
    }

    private func load(_ m: (year: Int, month: Int)) async {
        let from = String(format: "%04d-%02d-01", m.year, m.month)
        let to = String(format: "%04d-%02d-%02d", m.year, m.month, BehaviorLoggingHistory.daysIn(year: m.year, month: m.month))
        if let s = await model.build(dayOffset: 0, { builder, _ in await builder.journalCalendar(from: from, to: to) }) {
            logged = s.loggedDays
        }
    }
}
#endif
