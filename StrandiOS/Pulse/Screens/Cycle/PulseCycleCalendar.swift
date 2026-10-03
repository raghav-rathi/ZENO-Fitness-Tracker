#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Cycle calendar (WHOOP_UI_SPEC §3.24 items 3–5; appstore/ios69-09, help-center/10, 12)
//
// "‹ APRIL ›" left-aligned, MON … SUN, then 5–6 week rows on a ≈60 pt pitch. Each run of one phase is a
// continuous band (30 pt) behind the dates, rounded only where the phase changes and square where it carries
// on into the next row or month; the part still to come is the darker future tone. Logged period days are
// filled coral circles, expected ones dashed coral circles, spotting a thin coral ring, today a white 2 pt
// ring around a disc in its phase colour, and a white dot under a date means symptoms were logged. A day up
// to today opens the log sheet for that day.

struct PulseCycleCalendar: View {
    let months: [CycleInsightsSnapshot.Month]
    @Binding var monthIndex: Int
    let onSelect: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Every day of every month by key, so a band knows whether its phase carries on past the edge.
    private var allDays: [String: CycleInsightsSnapshot.Day] {
        Dictionary(uniqueKeysWithValues: months.flatMap(\.days).map { ($0.id, $0) })
    }

    var body: some View {
        let month = months.indices.contains(monthIndex) ? months[monthIndex] : nil
        VStack(alignment: .leading, spacing: 0) {
            pager(month)
            weekdayHeader
                .padding(.top, 9)
            if let month {
                grid(month)
                    .padding(.top, 6)
                    .id(month.id)
                    .transition(.opacity)
            }
        }
        .animation(PulseMotion.resolved(PulseMotion.crossFade, reduceMotion: reduceMotion), value: monthIndex)
    }

    private func pager(_ month: CycleInsightsSnapshot.Month?) -> some View {
        HStack(spacing: 2) {
            pagerButton("chevron.left", enabled: monthIndex > 0, label: String(localized: "Previous month")) {
                monthIndex -= 1
            }
            Text(month?.title ?? "")
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            pagerButton("chevron.right", enabled: monthIndex < months.count - 1, label: String(localized: "Next month")) {
                monthIndex += 1
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, -12)
    }

    private func pagerButton(_ symbol: String, enabled: Bool, label: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: 36, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(PulseCycleDates.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
        }
        // Seven fixed columns: past xxxLarge the initials would run into each other.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityHidden(true)
    }

    private func grid(_ month: CycleInsightsSnapshot.Month) -> some View {
        let cells: [CycleInsightsSnapshot.Day?] = Array(repeating: nil, count: month.leadingBlanks) + month.days.map { $0 }
        let rows = stride(from: 0, to: cells.count, by: 7).map { start in
            Array(cells[start..<min(start + 7, cells.count)]) + Array(repeating: nil, count: max(0, start + 7 - cells.count))
        }
        let lookup = allDays
        return VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                PulseCycleWeekRow(days: row, lookup: lookup, onSelect: onSelect)
            }
        }
    }
}

/// One week: the phase bands behind, then the seven day cells.
private struct PulseCycleWeekRow: View {
    let days: [CycleInsightsSnapshot.Day?]
    let lookup: [String: CycleInsightsSnapshot.Day]
    let onSelect: (String) -> Void

    static let pitch: CGFloat = 60
    static let band: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let cell = geo.size.width / 7
            ZStack(alignment: .topLeading) {
                ForEach(runs(), id: \.start) { run in
                    bandShape(run, cell: cell, rowWidth: geo.size.width)
                }
                ForEach(0..<7, id: \.self) { column in
                    if let day = days[column] {
                        PulseCycleDayCell(day: day, onSelect: onSelect)
                            .frame(width: cell, height: Self.pitch)
                            .offset(x: CGFloat(column) * cell)
                    }
                }
            }
        }
        .frame(height: Self.pitch)
    }

    /// A run of consecutive days in this row sharing a phase.
    struct Run {
        let start: Int
        let end: Int
        let phase: PulseCyclePhase
        /// The first column that is a future day (end + 1 when none is).
        let futureFrom: Int
        let roundLeft: Bool
        let roundRight: Bool
    }

    private func runs() -> [Run] {
        var out: [Run] = []
        var column = 0
        while column < 7 {
            guard let day = days[column], let phase = day.phase else { column += 1; continue }
            var end = column
            while end + 1 < 7, let next = days[end + 1], next.phase == phase { end += 1 }
            let first = days[column]!, last = days[end]!
            let before = MenstrualCycleModel.shift(first.id, by: -1).flatMap { lookup[$0] }
            let after = MenstrualCycleModel.shift(last.id, by: 1).flatMap { lookup[$0] }
            let futureFrom = (column...end).first { days[$0]?.isFuture == true } ?? end + 1
            // Square only at the row's own edge, where the phase carries on into the previous or next row
            // (or month); a run that stops inside the row always ends rounded.
            out.append(Run(start: column, end: end, phase: phase, futureFrom: futureFrom,
                           roundLeft: column > 0 || before?.phase != phase,
                           roundRight: end < 6 || after?.phase != phase))
            column = end + 1
        }
        return out
    }

    @ViewBuilder
    private func bandShape(_ run: Run, cell: CGFloat, rowWidth: CGFloat) -> some View {
        // A band ending mid-row stops 3 pt short of the cell edge, so two phases meet with a small gap.
        let inset: CGFloat = 3
        let x0 = CGFloat(run.start) * cell + (run.roundLeft ? inset : 0)
        let x1 = CGFloat(run.end + 1) * cell - (run.roundRight ? inset : 0)
        let width = max(0, x1 - x0)
        let split = width > 0 ? min(1, max(0, (CGFloat(run.futureFrom) * cell - x0) / width)) : 1
        let fill = LinearGradient(stops: [
            .init(color: run.phase.band, location: 0),
            .init(color: run.phase.band, location: split),
            .init(color: run.phase.futureBand, location: split),
            .init(color: run.phase.futureBand, location: 1),
        ], startPoint: .leading, endPoint: .trailing)
        UnevenRoundedRectangle(topLeadingRadius: run.roundLeft ? Self.band / 2 : 0,
                               bottomLeadingRadius: run.roundLeft ? Self.band / 2 : 0,
                               bottomTrailingRadius: run.roundRight ? Self.band / 2 : 0,
                               topTrailingRadius: run.roundRight ? Self.band / 2 : 0,
                               style: .circular)
            .fill(fill)
            .frame(width: width, height: Self.band)
            .offset(x: x0, y: (Self.pitch - Self.band) / 2)
            .accessibilityHidden(true)
    }
}

/// One date: its number on the band, the period marks, today's ring and the symptoms dot.
private struct PulseCycleDayCell: View {
    let day: CycleInsightsSnapshot.Day
    let onSelect: (String) -> Void

    private static let circle: CGFloat = 28
    private static let ring: CGFloat = 40
    private var coral: Color { PulseCyclePhase.menstrual.dot }

    var body: some View {
        Button { onSelect(day.id) } label: {
            ZStack {
                marks
                Text(verbatim: "\(day.number)")
                    .font(PulseType.numeral(14))
                    .foregroundStyle(numberColor)
                    .minimumScaleFactor(0.8)
                if day.hasSymptoms {
                    Circle()
                        .fill(PulseTheme.textPrimary)
                        .frame(width: 5, height: 5)
                        .offset(y: PulseCycleWeekRow.band / 2 + 7)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(day.isFuture)
        .accessibilityLabel(day.accessibility)
        .accessibilityHint(day.isFuture ? "" : String(localized: "Opens the log for this day"))
    }

    @ViewBuilder
    private var marks: some View {
        if day.isToday {
            Circle()
                .strokeBorder(PulseTheme.textPrimary, lineWidth: 2)
                .frame(width: Self.ring, height: Self.ring)
        }
        if day.isLoggedPeriod {
            Circle().fill(coral).frame(width: Self.circle, height: Self.circle)
        } else if day.isToday, let phase = day.phase {
            Circle().fill(phase.dot).frame(width: Self.circle, height: Self.circle)
        }
        if day.isPredictedPeriod {
            Circle()
                .strokeBorder(coral, style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5]))
                .frame(width: Self.circle, height: Self.circle)
        } else if day.isSpotting {
            Circle()
                .strokeBorder(coral, lineWidth: 1.5)
                .frame(width: Self.circle, height: Self.circle)
        }
    }

    private var numberColor: Color {
        if day.isLoggedPeriod || (day.isToday && day.phase != nil) { return PulseTheme.textPrimary }
        if day.isPredictedPeriod { return coral }
        if day.isFuture { return day.phase == nil ? PulseTheme.textDisabled : PulseTheme.textTertiary }
        return day.phase == nil ? PulseTheme.textSecondary : PulseTheme.textPrimary
    }
}

/// "● Menstrual ● Follicular ● Ovulatory ● Luteal ● Symptoms ◌ Predicted period", wrapping as needed.
struct PulseCycleLegend: View {
    let showsPhases: Bool
    var showsPrediction = true

    var body: some View {
        PulseWordFlow(alignment: .leading, spacing: 14, lineSpacing: 13) {
            if showsPhases {
                ForEach(PulseCyclePhase.allCases, id: \.self) { phase in
                    item(PulseCycleText.phaseName(phase)) {
                        Capsule().fill(phase.dot).frame(width: 15, height: 8)
                    }
                }
            }
            item(String(localized: "Symptoms")) {
                Circle().fill(PulseTheme.textPrimary).frame(width: 7, height: 7)
            }
            if showsPrediction {
                item(String(localized: "Predicted period")) {
                    Circle()
                        .strokeBorder(PulseCyclePhase.menstrual.dot, style: StrokeStyle(lineWidth: 1.2, dash: [2, 2]))
                        .frame(width: 11, height: 11)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func item<Swatch: View>(_ title: String, @ViewBuilder swatch: () -> Swatch) -> some View {
        HStack(spacing: 7) {
            swatch()
            Text(title)
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textSecondary)
                .lineLimit(1)
        }
    }
}
#endif
