#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Cycle calendar (WHOOP_UI_SPEC §3.24 items 3–5; appstore/ios69-09, help-center/10, 12, whoop-site/56)
//
// "‹ APRIL ›" left-aligned, MON … SUN, then 5–6 week rows on a 60 pt pitch. The seven dates sit on a 53 pt
// pitch with the outer ones 21.5 pt inside the row (whoop-site/56: 21.6 and ≈53). Each run of one phase is a
// continuous 28 pt band behind the dates. Where the phase changes, the band ends in a semicircle concentric
// with that day's 28 pt circle (day centre ± 14, so two phases meet ≈25 pt apart); where the phase carries
// on into the next row or month, the end is square, 21.5 pt past the day's centre (the row's edge for the
// outer columns). The days still to come take the phase's darker future tone. Logged period days are filled
// coral circles, the days the next period may start on dashed coral circles, spotting a thin coral ring,
// today a white ring around a disc in its phase colour, and a white dot under a date means symptoms were
// logged. A day up to today opens the log sheet for that day.

/// The seven columns: centres 21.5 pt inside the row's ends, evenly spaced between.
enum PulseCycleColumns {
    static let inset: CGFloat = 21.5

    static func pitch(_ width: CGFloat) -> CGFloat { max(0, width - 2 * inset) / 6 }

    static func centre(_ column: Int, width: CGFloat) -> CGFloat { inset + CGFloat(column) * pitch(width) }
}

/// Lays seven views out centred on the calendar's columns (the weekday header).
struct PulseCycleColumnsLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 361
        let pitch = PulseCycleColumns.pitch(width)
        let height = subviews.map { $0.sizeThatFits(ProposedViewSize(width: pitch, height: nil)).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let pitch = PulseCycleColumns.pitch(bounds.width)
        for (column, view) in subviews.enumerated() {
            view.place(at: CGPoint(x: bounds.minX + PulseCycleColumns.centre(column, width: bounds.width),
                                   y: bounds.midY),
                       anchor: .center, proposal: ProposedViewSize(width: pitch, height: bounds.height))
        }
    }
}

struct PulseCycleCalendar: View {
    let months: [CycleInsightsSnapshot.Month]
    /// The month on screen ("yyyy-MM").
    @Binding var monthID: String
    let onSelect: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var monthIndex: Int? { months.firstIndex { $0.id == monthID } }

    /// Every day of every month by key, so a band knows whether its phase carries on past the edge.
    private var allDays: [String: CycleInsightsSnapshot.Day] {
        Dictionary(uniqueKeysWithValues: months.flatMap(\.days).map { ($0.id, $0) })
    }

    var body: some View {
        let index = monthIndex
        let month = index.map { months[$0] }
        VStack(alignment: .leading, spacing: 0) {
            pager(month, index: index)
            weekdayHeader
                .padding(.top, 9)
            if let month {
                grid(month)
                    .padding(.top, 6)
                    .id(month.id)
                    .transition(.opacity)
            }
        }
        .animation(PulseMotion.resolved(PulseMotion.crossFade, reduceMotion: reduceMotion), value: monthID)
    }

    /// "‹ APRIL ›": 44 pt chevrons, the left glyph centred ≈28 pt from the screen edge (whoop-site/56: 27).
    private func pager(_ month: CycleInsightsSnapshot.Month?, index: Int?) -> some View {
        HStack(spacing: -6) {
            pagerButton("chevron.left", enabled: (index ?? 0) > 0, label: String(localized: "Previous month")) {
                if let index, index > 0 { monthID = months[index - 1].id }
            }
            Text(month?.title ?? "")
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            pagerButton("chevron.right", enabled: index.map { $0 < months.count - 1 } ?? false,
                        label: String(localized: "Next month")) {
                if let index, index < months.count - 1 { monthID = months[index + 1].id }
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, -10)
    }

    private func pagerButton(_ symbol: String, enabled: Bool, label: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private var weekdayHeader: some View {
        PulseCycleColumnsLayout {
            ForEach(Array(PulseCycleDates.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        // Seven fixed 53 pt columns: past xLarge three-letter names run into each other.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
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
            let width = geo.size.width
            let column = PulseCycleColumns.pitch(width)
            ZStack(alignment: .topLeading) {
                ForEach(runs(), id: \.start) { run in
                    bandShape(run, width: width)
                }
                ForEach(0..<7, id: \.self) { index in
                    if let day = days[index] {
                        PulseCycleDayCell(day: day, onSelect: onSelect)
                            .frame(width: column, height: Self.pitch)
                            .offset(x: PulseCycleColumns.centre(index, width: width) - column / 2)
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
            // The day before the run's first and after its last, wherever they are drawn (this row, the
            // row above or below, or the month before or after): an end is rounded only where the phase
            // really changes, and square where it carries on past the row's or the month's edge.
            let before = MenstrualCycleModel.shift(first.id, by: -1).flatMap { lookup[$0] }
            let after = MenstrualCycleModel.shift(last.id, by: 1).flatMap { lookup[$0] }
            let futureFrom = (column...end).first { days[$0]?.isFuture == true } ?? end + 1
            out.append(Run(start: column, end: end, phase: phase, futureFrom: futureFrom,
                           roundLeft: before?.phase != phase, roundRight: after?.phase != phase))
            column = end + 1
        }
        return out
    }

    @ViewBuilder
    private func bandShape(_ run: Run, width: CGFloat) -> some View {
        let half = Self.band / 2
        let x0 = PulseCycleColumns.centre(run.start, width: width) - (run.roundLeft ? half : PulseCycleColumns.inset)
        let x1 = PulseCycleColumns.centre(run.end, width: width) + (run.roundRight ? half : PulseCycleColumns.inset)
        let length = max(0, x1 - x0)
        // Past and future meet halfway between the last past day and the first future one.
        let boundary = PulseCycleColumns.centre(run.futureFrom, width: width) - PulseCycleColumns.pitch(width) / 2
        let split = length > 0 ? min(1, max(0, (boundary - x0) / length)) : 1
        let fill = LinearGradient(stops: [
            .init(color: run.phase.pastTone.color(run.phase), location: 0),
            .init(color: run.phase.pastTone.color(run.phase), location: split),
            .init(color: run.phase.futureTone.color(run.phase), location: split),
            .init(color: run.phase.futureTone.color(run.phase), location: 1),
        ], startPoint: .leading, endPoint: .trailing)
        let shape = UnevenRoundedRectangle(topLeadingRadius: run.roundLeft ? half : 0,
                                           bottomLeadingRadius: run.roundLeft ? half : 0,
                                           bottomTrailingRadius: run.roundRight ? half : 0,
                                           topTrailingRadius: run.roundRight ? half : 0,
                                           style: .circular)
        ZStack {
            // An opaque ground under the tones that are a phase colour over the page, so the band reads the
            // same at any height on the phase-tinted page.
            shape.fill(PulseTheme.pageBottom)
            shape.fill(fill)
        }
        .frame(width: length, height: Self.band)
        .offset(x: x0, y: (Self.pitch - Self.band) / 2)
        .accessibilityHidden(true)
    }
}

/// One date: its number on the band, the period marks, today's ring and the symptoms dot.
private struct PulseCycleDayCell: View {
    let day: CycleInsightsSnapshot.Day
    let onSelect: (String) -> Void

    private static let circle: CGFloat = 28
    /// Today's ring: ≈44 pt with a 1.5 pt stroke (whoop-site/56: 44.2 pt, 1.4 pt).
    private static let ring: CGFloat = 44
    /// The symptoms dot: 7.5 pt, 22 pt under the row's centre (whoop-site/56: 7.8 pt).
    private static let dot: CGFloat = 7.5
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
                        .frame(width: Self.dot, height: Self.dot)
                        .offset(y: 22)
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
                .strokeBorder(PulseTheme.textPrimary, lineWidth: 1.5)
                .frame(width: Self.ring, height: Self.ring)
        }
        if day.isLoggedPeriod {
            Circle().fill(coral).frame(width: Self.circle, height: Self.circle)
        } else if day.isToday, let phase = day.phase {
            Circle().fill(phase.dot).frame(width: Self.circle, height: Self.circle)
        }
        if day.isPossibleStart {
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
        if day.isPossibleStart { return coral }
        if day.isFuture { return day.phase == nil ? PulseTheme.textDisabled : PulseTheme.textTertiary }
        return day.phase == nil ? PulseTheme.textSecondary : PulseTheme.textPrimary
    }
}

/// "● Menstrual ● Follicular ● Ovulatory ● Luteal ● Symptoms ◌ Possible period start" (help-center/10),
/// wrapping as needed.
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
                item(String(localized: "Possible period start")) {
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
