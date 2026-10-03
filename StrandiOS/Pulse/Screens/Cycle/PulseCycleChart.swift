#if os(iOS)
import SwiftUI
import Charts
import StrandAnalytics

// MARK: - "Your Current Cycle" (WHOOP_UI_SPEC §3.24 item 9; help-center/85, health-more-2026/07)
//
// Metric chips (SKIN TEMP | RHR | HRV | RECOVERY, the selected one white), a "Smoothed Data | Expected
// Trend ⓘ" legend, then one bar per cycle day: the night's 3-day smoothed deviation from the wearer's OWN
// baseline, coloured by that day's phase, over a grey "expected" area that is the wearer's own previous
// cycles averaged by cycle day and smoothed over a week (shown once two previous cycles are logged; never a
// population curve). A dotted white line marks today (its cycle day bold on the axis) and a dashed coral line
// the predicted next start. CURRENT | LAST 3 MONTHS switches the bars to the previous cycles' average. The
// plot keeps WHOOP's proportions (help-center/85: ≈218 pt from +0.3 to -0.3) and its "+0.3" labels.

struct PulseCycleCurrentChart: View {
    let cycle: CycleInsightsSnapshot.CurrentCycle

    @State private var selectedID = "skin"
    @State private var range: Range = .current
    @State private var explains = false

    enum Range: Hashable { case current, average }

    private var series: CycleInsightsSnapshot.CurrentCycle.Series? {
        cycle.series.first { $0.id == selectedID } ?? cycle.series.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            chips
            legend
                .padding(.top, 18)
            if explains {
                Text(String(localized: "Smoothed Data: each night's change from your own baseline, averaged with the nights either side. Expected Trend: your previous cycles averaged by cycle day, smoothed over a week. Both come from your own nights only."))
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
            if let series {
                chart(series)
                    .frame(height: 235)
                    .padding(.top, 14)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(accessibility(series))
                Text(String(localized: "Cycle days"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.top, 4)
                    .accessibilityHidden(true)
            }
            PulseSegmentedControl(options: [Range.current, .average], selection: $range) { r in
                r == .current ? String(localized: "Current") : String(localized: "Last 3 months")
            }
            .padding(.top, 24)
            Text(range == .current ? cycle.paragraph : averageNote)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textPrimary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 18)
        }
    }

    private var averageNote: String {
        guard let series, series.previousCycles >= CycleMetricPatterns.minPreviousCycles else {
            return String(localized: "Log two complete cycles to see your average across them.")
        }
        return String(localized: "Your average for each cycle day across your last \(series.previousCycles) cycles, from your own nights.")
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cycle.series) { s in
                    let selected = s.id == (series?.id ?? "")
                    Button { selectedID = s.id } label: {
                        HStack(spacing: 6) {
                            Image(systemName: s.symbol).font(.system(size: 13, weight: .semibold))
                            Text(s.title).pulseText(.cardTitle).lineLimit(1)
                        }
                        .foregroundStyle(selected ? Color.black : PulseTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 34)
                        .background(Capsule(style: .circular).fill(selected ? Color.white : PulseTheme.filterChip))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .padding(.horizontal, -PulseTheme.Layout.pageMargin)
    }

    private var legend: some View {
        HStack(spacing: 18) {
            HStack(spacing: 18) {
                HStack(spacing: 7) {
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach([7.0, 11.0, 5.0], id: \.self) { h in
                            Capsule().fill(PulseTheme.textSecondary).frame(width: 3, height: h)
                        }
                    }
                    Text(String(localized: "Smoothed Data")).pulseText(.legend).foregroundStyle(PulseTheme.textSecondary)
                }
                HStack(spacing: 7) {
                    Capsule().fill(PulseTheme.dash).frame(width: 16, height: 8)
                    Text(String(localized: "Expected Trend")).pulseText(.legend).foregroundStyle(PulseTheme.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            Button { explains.toggle() } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget,
                           alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(explains ? String(localized: "Hide what the chart shows")
                                         : String(localized: "What the chart shows"))
        }
        .frame(minHeight: 20)
        .padding(.vertical, -12)
    }

    private func bars(_ s: CycleInsightsSnapshot.CurrentCycle.Series) -> [CycleInsightsSnapshot.CurrentCycle.Bar] {
        range == .current ? s.current : s.average
    }

    /// A symmetric domain around zero that fits every bar and the expected curve, with a sensible floor.
    private func domain(_ s: CycleInsightsSnapshot.CurrentCycle.Series) -> Double {
        let values = bars(s).map { abs($0.value) } + (range == .current ? s.expected.map { abs($0.value) } : [])
        let floor: Double = s.id == "skin" ? 0.3 : (s.id == "recovery" ? 10 : 5)
        return max(floor, (values.max() ?? 0) * 1.15)
    }

    private func chart(_ s: CycleInsightsSnapshot.CurrentCycle.Series) -> some View {
        let top = domain(s)
        let ticks = [-top, -top / 2, 0, top / 2, top]
        let xTicks = Array(Set([1, 7, 14, 21, 28, 35, 42].filter { $0 <= cycle.axisMax } + [cycle.todayCycleDay])).sorted()
        return Chart {
            if range == .current {
                ForEach(s.expected, id: \.cycleDay) { p in
                    AreaMark(x: .value("Cycle day", p.cycleDay), yStart: .value("Zero", 0.0),
                             yEnd: .value("Expected", p.value))
                        .foregroundStyle(PulseTheme.dash.opacity(0.6))
                        .interpolationMethod(.monotone)
                }
            }
            ForEach(bars(s)) { bar in
                BarMark(x: .value("Cycle day", bar.cycleDay), yStart: .value("Zero", 0.0),
                        yEnd: .value("Deviation", bar.value), width: .fixed(5))
                    .foregroundStyle(bar.phase?.dot ?? PulseTheme.textSecondary)
                    .clipShape(Capsule())
                    .accessibilityLabel(barLabel(bar))
                    .accessibilityValue(barValue(bar, series: s))
            }
            RuleMark(y: .value("Zero", 0.0))
                .foregroundStyle(PulseTheme.gridOnPage)
            if range == .current {
                RuleMark(x: .value("Today", cycle.todayCycleDay))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [2, 3]))
                if let next = cycle.nextStartCycleDay, next <= cycle.axisMax {
                    RuleMark(x: .value("Next period", next))
                        .foregroundStyle(PulseCyclePhase.menstrual.dot)
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                }
            }
        }
        .chartXScale(domain: 0...(cycle.axisMax + 1))
        .chartYScale(domain: -top...top)
        .chartXAxis {
            AxisMarks(values: xTicks) { value in
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text(verbatim: "\(day)")
                            .pulseText(.axis)
                            .foregroundStyle(day == cycle.todayCycleDay && range == .current
                                             ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: ticks) { value in
                AxisGridLine().foregroundStyle(PulseTheme.gridOnPage)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(label(v, decimals: s.decimals))
                            .pulseText(.axis)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .overlay {
            if bars(s).isEmpty {
                Text(range == .current ? String(localized: "No nights logged this cycle yet")
                                       : String(localized: "Not enough previous cycles yet"))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
    }

    private func barLabel(_ bar: CycleInsightsSnapshot.CurrentCycle.Bar) -> String {
        String(localized: "Cycle day \(bar.cycleDay)")
    }

    /// "+0.12 °C, Luteal".
    private func barValue(_ bar: CycleInsightsSnapshot.CurrentCycle.Bar,
                          series: CycleInsightsSnapshot.CurrentCycle.Series) -> String {
        var text = label(bar.value, decimals: series.decimals) + " " + series.unit
        if let phase = bar.phase { text += ", " + PulseCycleText.phaseName(phase) }
        return text
    }

    /// "+0.3", "+0.15", "−5": signed, at most `decimals` places and no trailing zeros (help-center/85).
    private func label(_ v: Double, decimals: Int) -> String {
        if abs(v) < 1e-9 { return "0" }
        let text = abs(v).formatted(.number.precision(.fractionLength(0...decimals))
            .locale(AppLanguage.activeLocale))
        return (v > 0 ? "+" : "−") + text
    }

    private func accessibility(_ s: CycleInsightsSnapshot.CurrentCycle.Series) -> String {
        let latest = s.current.last.map { label($0.value, decimals: s.decimals) + " " + s.unit }
        let title = String(localized: "\(s.title) by cycle day, against your own baseline")
        guard let latest else { return title + ". " + String(localized: "No nights logged this cycle yet") }
        return title + ". " + String(localized: "Cycle day \(cycle.todayCycleDay): \(latest)")
    }
}
#endif
