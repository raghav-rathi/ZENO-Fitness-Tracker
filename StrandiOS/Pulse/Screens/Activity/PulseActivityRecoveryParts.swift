#if os(iOS)
import SwiftUI
import Charts

// MARK: - The recovery variant's STRESS tab and IMPACT ON RECOVERY (WHOOP_UI_SPEC §3.6 "Recovery activity")

/// The STRESS tab (e08, e10): the Stress Monitor's readings around the activity on the 0.0–3.0 scale, the
/// line coloured by its value, the start reading and its level at the top-left ("0.6 LOW"), the end reading
/// at the top-right ("MEDIUM 1.5"), and dashed rules at the activity's start and end with their times.
/// ZENO's stress is scored an hour of heart rate at a time, so the curve is coarser than WHOOP's, and the
/// footnote says so.
struct PulseActivityStressChart: View {
    let summary: ActivityStressSummary
    let window: ClosedRange<Date>
    var height: CGFloat = 170

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                reading(summary.start, valueFirst: true)
                Spacer(minLength: 12)
                reading(summary.end, valueFirst: false)
            }
            .padding(.leading, 4)
            Chart {
                ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                    ForEach([pair.0, pair.1], id: \.date) { p in
                        LineMark(x: .value("Time", p.date), y: .value("Stress", p.value ?? 0),
                                 series: .value("Segment", index))
                            .foregroundStyle(PulseTheme.Stress.color(for: ((pair.0.value ?? 0) + (pair.1.value ?? 0)) / 2))
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                }
                ForEach(singles) { p in
                    PointMark(x: .value("Time", p.date), y: .value("Stress", p.value ?? 0))
                        .symbolSize(14)
                        .foregroundStyle(PulseTheme.Stress.color(for: p.value ?? 0))
                }
                ForEach([window.lowerBound, window.upperBound], id: \.self) { edge in
                    RuleMark(x: .value("Edge", edge))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Edge", edge), y: .value("Foot", 0))
                        .symbolSize(18)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
            }
            .chartXScale(domain: summary.span)
            .chartYScale(domain: 0...3)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.0, 1.0, 2.0, 3.0]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnPage)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(String(format: "%.1f", v))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                }
            }
            .frame(height: height)
            edgeLabels
            Text(String(localized: "Stress is scored from an hour of heart rate at a time, so this curve is coarser than the heart rate."))
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Stress during this activity"))
        .accessibilityValue(String(localized: "From \(PulseFormat.oneDecimal(summary.start)) \(Self.levelWord(summary.start)) to \(PulseFormat.oneDecimal(summary.end)) \(Self.levelWord(summary.end)), on the 0 to 3 stress scale"))
    }

    /// "0.6 LOW" at the left, "MEDIUM 1.5" at the right (e08).
    private func reading(_ value: Double, valueFirst: Bool) -> some View {
        let shown = (value * 10).rounded() / 10
        let level = PulseTheme.Stress.Level(value: shown)
        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            if valueFirst {
                Text(PulseFormat.oneDecimal(shown)).font(PulseType.font(.rowValue)).foregroundStyle(PulseTheme.textPrimary)
                Text(Self.levelWord(shown)).pulseText(.label).foregroundStyle(level.color)
            } else {
                Text(Self.levelWord(shown)).pulseText(.label).foregroundStyle(level.color)
                Text(PulseFormat.oneDecimal(shown)).font(PulseType.font(.rowValue)).foregroundStyle(PulseTheme.textPrimary)
            }
        }
    }

    /// LOW / MEDIUM / HIGH as the Stress screen words them, judged on the value printed.
    static func levelWord(_ value: Double) -> String {
        StressBand(score: (value * 10).rounded() / 10).title
    }

    /// The activity's start and end under their rules, placed on the chart's own time scale.
    private var edgeLabels: some View {
        GeometryReader { geo in
            let total = summary.span.upperBound.timeIntervalSince(summary.span.lowerBound)
            let startX = total > 0 ? geo.size.width * window.lowerBound.timeIntervalSince(summary.span.lowerBound) / total : 0
            let endX = total > 0 ? geo.size.width * window.upperBound.timeIntervalSince(summary.span.lowerBound) / total
                : geo.size.width
            ZStack(alignment: .topLeading) {
                Text(PulseFormat.clock(window.lowerBound))
                    .activityNumeral(12, relativeTo: .caption, maxScale: 1.4)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                    .offset(x: max(0, startX - 2))
                Text(PulseFormat.clock(window.upperBound))
                    .activityNumeral(12, relativeTo: .caption, maxScale: 1.4)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize()
                    .frame(width: max(0, endX + 2), alignment: .trailing)
            }
        }
        .frame(height: 20)
    }

    /// Consecutive readings with no gap between them, each drawn in its own value's colour.
    private var pairs: [(PulseTimeValue, PulseTimeValue)] {
        let points = summary.points
        guard points.count > 1 else { return [] }
        return (1..<points.count).compactMap { i in
            points[i - 1].value != nil && points[i].value != nil ? (points[i - 1], points[i]) : nil
        }
    }

    /// Readings with no neighbour, drawn as dots.
    private var singles: [PulseTimeValue] {
        let points = summary.points
        return points.indices.compactMap { i in
            guard points[i].value != nil else { return nil }
            let before = i > 0 && points[i - 1].value != nil
            let after = i + 1 < points.count && points[i + 1].value != nil
            return before || after ? nil : points[i]
        }
    }
}

/// IMPACT ON RECOVERY (e03): "--%" until there are five days with this activity and five without, each
/// followed by a scored Recovery, five progress circles and "1/5" while locked; then the difference in
/// next-day Recovery, coloured only when it clears the Behavior Insights significance rule.
struct PulseActivityImpactCard: View {
    let impact: ActivityRecoveryImpact

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                PulseCardTitle(String(localized: "Impact on Recovery"))
                Spacer(minLength: 8)
                Text(valueText)
                    .font(PulseType.font(.calloutValue))
                    .foregroundStyle(valueColor)
            }
            Text(sentence)
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if !impact.isUnlocked {
                HStack(spacing: 8) {
                    ForEach(0..<ActivityRecoveryImpact.required, id: \.self) { i in
                        progressCircle(done: i < impact.progress)
                    }
                    Spacer(minLength: 8)
                    Text("\(impact.progress)/\(ActivityRecoveryImpact.required)")
                        .font(PulseType.font(.rowValue))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
        }
        .padding(PulseTheme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .accessibilityElement(children: .combine)
        .id("pulse.activity-impact")
    }

    private var valueText: String {
        guard let change = impact.percentChange else { return "--%" }
        let rounded = Int(change.rounded())
        return rounded > 0 ? "+\(rounded)%" : "\(rounded)%"
    }

    /// Green or orange only for a difference that clears the significance rule; grey otherwise.
    private var valueColor: Color {
        guard let change = impact.percentChange else { return PulseTheme.textTertiary }
        guard impact.significant, Int(change.rounded()) != 0 else { return PulseTheme.textSecondary }
        return change > 0 ? PulseTheme.positive : PulseTheme.negative
    }

    private var sentence: String {
        guard let change = impact.percentChange else {
            return String(localized: "Keep logging this activity. Once you have \(ActivityRecoveryImpact.required) days with it and \(ActivityRecoveryImpact.required) days without it, each followed by a Recovery, ZENO shows how it moves your next morning's Recovery.")
        }
        let amount = abs(Int(change.rounded()))
        let base = change >= 0
            ? String(localized: "Your Recovery the next morning averaged \(amount)% higher after days with this activity (\(impact.daysWith) days) than after days without it (\(impact.daysWithout)).")
            : String(localized: "Your Recovery the next morning averaged \(amount)% lower after days with this activity (\(impact.daysWith) days) than after days without it (\(impact.daysWithout)).")
        return impact.significant ? base : base + " " + String(localized: "That isn't a clear difference yet.")
    }

    private func progressCircle(done: Bool) -> some View {
        ZStack {
            Circle()
                .strokeBorder(done ? PulseTheme.recoveryBlue : PulseTheme.textTertiary, lineWidth: 1.5)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: PulseActivityStyle.Glyph.chip, weight: .bold))
                    .foregroundStyle(PulseTheme.recoveryBlue)
            }
        }
        .frame(width: 30, height: 30)
        .accessibilityHidden(true)
    }
}
#endif
