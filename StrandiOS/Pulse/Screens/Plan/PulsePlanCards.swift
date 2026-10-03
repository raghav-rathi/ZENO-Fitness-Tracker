#if os(iOS)
import SwiftUI
import Charts

// MARK: - Plan cards (WHOOP_UI_SPEC §3.19, completeness-critic/23, whoop-site/33)
//
// The goal cards Plan Overview stacks, the plan header, and the pieces the Home card and the recap share.
// All take a `PlanGoalProgress` / `PlanWeekSnapshot`: every figure is already measured.

/// "27% ACCOMPLISHED" over its 4 pt green bar. The figure scales with the caps word beside it, and the word
/// drops under the figure when the two no longer fit on one line.
struct PlanAccomplishedBar: View {
    let percent: Int?
    var word: String = String(localized: "Accomplished")

    @ScaledMetric(relativeTo: .title3) private var figureSize: CGFloat = 20
    @ScaledMetric(relativeTo: .footnote) private var unitSize: CGFloat = 13

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    figure
                    wordText.padding(.leading, 6)
                }
                VStack(alignment: .leading, spacing: 2) {
                    figure
                    PulseWordWrapText(word, style: .menuLabel)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(PulseTheme.Plan.progressTrack)
                    Capsule().fill(PulseTheme.Plan.progress)
                        .frame(width: geo.size.width * CGFloat(min(100, max(0, percent ?? 0))) / 100)
                }
            }
            .frame(height: 4)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(percent ?? 0) percent accomplished"))
    }

    private var figure: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(percent.map { "\($0)" } ?? "--")
                .font(PulseType.numeral(figureSize))
            Text(verbatim: "%")
                .font(PulseType.numeral(unitSize))
        }
        .foregroundStyle(PulseTheme.textPrimary)
        .fixedSize()
    }

    private var wordText: some View {
        Text(word)
            .pulseText(.menuLabel)
            .foregroundStyle(PulseTheme.textSecondary)
            .lineLimit(1)
    }
}

/// A Plan Overview section label: caps grey, a hairline, and "EDIT ✎" at the right.
struct PlanSectionHeader: View {
    let title: String
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            PulseWordWrapText(title, style: .cardTitle)
                .foregroundStyle(PulseTheme.JournalPlan.planSectionLabel)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
            Rectangle().fill(PulseTheme.divider).frame(minWidth: 12, maxWidth: .infinity).frame(height: 1)
                .accessibilityHidden(true)
            if let onEdit {
                // Never squeezed: "EDIT" must not break inside the word at large text sizes.
                PulseTextAccessory(title: String(localized: "Edit"), symbol: "pencil", action: onEdit)
                    .fixedSize()
                    .layoutPriority(2)
                    .accessibilityLabel(String(localized: "Edit \(title)"))
            }
        }
    }
}

/// One goal on Plan Overview, in the card its kind takes.
struct PlanGoalCard: View {
    let progress: PlanGoalProgress
    /// Today's position in the week (its weekday label is white, its chart column highlighted).
    var todayIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch progress.style {
            case .time: timeBody
            case .metric: metricBody
            case .count: countBody
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.dialog, style: .continuous)
            .fill(PulseTheme.JournalPlan.planCard))
        .accessibilityElement(children: .contain)
    }

    private var titleRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(progress.cardTitle)
                .pulseText(.subsectionTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let average = progress.averageText, progress.style == .metric {
                Text(average)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            PulseGoalRing(kind: progress.ring, diameter: 44)
        }
    }

    // A time goal: total vs target on a thick bar, then the activities behind it, and what could not be
    // measured. With nothing measurable the total reads "--", never "0:00:00".
    @ViewBuilder
    private var timeBody: some View {
        titleRow
        let color = timeColor
        HStack {
            Text(progress.progressText ?? "--")
                .font(PulseTheme.JournalPlan.goalFigure)
                .foregroundStyle(progress.progressText == nil ? PulseTheme.textTertiary
                                 : (progress.met ? PulseTheme.Plan.goalMet : color))
            Spacer()
            Text(progress.targetText ?? "--")
                .font(PulseTheme.JournalPlan.goalFigure)
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(progress.progressText ?? String(localized: "Not measured")) of \(progress.targetText ?? "--")"))
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(PulseTheme.well)
                Capsule().fill(progress.met ? PulseTheme.Plan.goalMet : color)
                    .frame(width: max(progress.fraction > 0 ? 8 : 0, geo.size.width * CGFloat(progress.fraction)))
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
        if !progress.activities.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(progress.activities) { line in
                    HStack(spacing: 10) {
                        Text(PlanTimeFormat.long(line.minutes))
                            .pulseText(.rowValue)
                            .foregroundStyle(color)
                            .frame(minWidth: 64, alignment: .leading)
                        Image(systemName: line.symbol)
                            .font(PulseTheme.JournalPlan.checkGlyph)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .frame(width: 20)
                        Text(line.sport)
                            .pulseText(.cardTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        if let note = progress.note {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(PulseTheme.JournalPlan.smallGlyph)
                    .accessibilityHidden(true)
                Text(note)
                    .pulseText(.rowSubline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(PulseTheme.textTertiary)
        }
        footer
    }

    /// Zone 4-5 orange, zone 1-3 green, strength time strain blue (the zone colours, not judgement).
    private var timeColor: Color {
        switch progress.goal.kind {
        case .hrZones45: return PulseTheme.Zone.color(4)
        case .hrZones13: return PulseTheme.Zone.color(3)
        default: return PulseTheme.strain
        }
    }

    // A metric goal: the day marks, a 7-day bar chart with the dashed GOAL line, and its rule.
    @ViewBuilder
    private var metricBody: some View {
        titleRow
        PulseDayCircleRow(days: dayCircles, diameter: 26)
        PlanMetricChart(values: progress.dayValues, goal: progress.goalLine, color: metricColor,
                        format: metricFormat, highlightIndex: todayIndex)
            .frame(height: 150)
        footer
    }

    private var metricColor: Color {
        switch progress.goal.kind {
        case .dayStrain: return PulseTheme.strain
        case .steps: return PulseTheme.recoveryBlue
        default: return PulseTheme.sleep
        }
    }

    private var metricFormat: (Double) -> String {
        switch progress.goal.kind {
        case .dayStrain: return PulseFormat.oneDecimal
        case .steps: return { v in v >= 1000 ? String(format: "%.1fk", v / 1000) : "\(Int(v))" }
        default: return { "\(Int($0.rounded()))%" }
        }
    }

    // A count goal: the MON–SUN circles, no sentence (completeness-critic/23).
    @ViewBuilder
    private var countBody: some View {
        titleRow
        PulseDayCircleRow(days: dayCircles, diameter: 30)
    }

    private var footer: some View {
        Text(progress.footer)
            .pulseText(.body)
            .foregroundStyle(PulseTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var dayCircles: [PulseDayCircleRow.Day] {
        PlanWeekdays.labels.enumerated().map { i, label in
            PulseDayCircleRow.Day(id: "\(i)", label: label,
                                  state: progress.dayStates.indices.contains(i) ? progress.dayStates[i] : .future,
                                  isCurrent: i == todayIndex)
        }
    }
}

/// A metric goal's week: rounded bars in the metric's colour with their values above, and a dashed GOAL
/// line with its pill. A day with nothing measured has no bar.
struct PlanMetricChart: View {
    let values: [Double?]
    let goal: Double?
    let color: Color
    let format: (Double) -> String
    var highlightIndex: Int?

    var body: some View {
        let plotted = values.enumerated().compactMap { i, v in v.map { (i, $0) } }
        let top = max(plotted.map(\.1).max() ?? 0, goal ?? 0) * 1.25
        Chart {
            if let highlightIndex, PlanWeekdays.labels.indices.contains(highlightIndex) {
                RectangleMark(x: .value("Day", PlanWeekdays.labels[highlightIndex]),
                              yStart: .value("Bottom", 0), yEnd: .value("Top", max(top, 1)), width: .fixed(29))
                    .foregroundStyle(PulseTheme.chartHighlight)
                    .clipShape(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular))
            }
            ForEach(plotted, id: \.0) { i, v in
                BarMark(x: .value("Day", PlanWeekdays.labels[i]), y: .value("Value", v), width: .fixed(14))
                    .foregroundStyle(goal.map { v >= $0 } ?? true ? color : color.opacity(0.45))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 3, topTrailingRadius: 3, style: .circular))
                    .annotation(position: .top, spacing: 4) {
                        Text(format(v))
                            .font(PulseTheme.JournalPlan.chartValue)
                            .foregroundStyle(color)
                    }
            }
            if let goal {
                RuleMark(y: .value("Goal", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(PulseTheme.JournalPlan.goalLine)
                    .annotation(position: .top, alignment: .trailing, spacing: 2) {
                        Text(String(localized: "Goal"))
                            .pulseText(.label)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: PulseTheme.JournalPlan.goalPillRadius, style: .circular)
                                .fill(PulseTheme.JournalPlan.goalLine))
                    }
            }
        }
        .chartXScale(domain: PlanWeekdays.labels)
        .chartYScale(domain: 0...max(top, 1))
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: PlanWeekdays.labels) { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label).font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plotted.isEmpty ? String(localized: "Nothing measured yet this week")
                                            : plotted.map { "\(PlanWeekdays.labels[$0.0]) \(format($0.1))" }.joined(separator: ", "))
    }
}

/// MON … SUN in the app's language (a plan week starts on Monday; 2026-03-02 was a Monday).
enum PlanWeekdays {
    static var labels: [String] {
        (0..<7).map { PulseFormat.dayLabel(String(format: "2026-03-%02d", $0 + 2), template: "EEE") }
    }
}

/// A goal row in a list (the Home card, the recap): its name in white (green once met) and its ring.
struct PlanGoalRow: View {
    let progress: PlanGoalProgress
    var ringDiameter: CGFloat = 40

    var body: some View {
        HStack(spacing: 12) {
            Text(progress.title)
                .pulseText(.trendInsight)
                .foregroundStyle(progress.met ? PulseTheme.Plan.progress : PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            PulseGoalRing(kind: progress.ring, diameter: ringDiameter)
        }
        .frame(minHeight: 50)
        .accessibilityElement(children: .combine)
        .accessibilityValue(progress.met ? String(localized: "Goal met") : "")
    }
}
#endif
