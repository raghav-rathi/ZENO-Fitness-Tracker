#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics

/// The current Pulse Recovery dive (WHOOP_UI_SPEC §3.4 in the new theme): the 260 pt ring, the
/// contributors in the notched callout, context, what shaped the score, and its history.
///
/// Owned by group "recovery-strain", which rebuilds it as `PulseRecoveryDiveView` (Weekly Trends,
/// Behavior Insights, the achievement chip). Until then that route hosts this screen.
struct PulseRecoveryView: View {
    @Environment(PulseModel.self) private var model
    #if DEBUG
    @State private var range = PulseDebugLaunch.historyRange ?? 30
    #else
    @State private var range = 30
    #endif

    var body: some View {
        PulseScreenScaffold(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                            coach: .button, ready: model.recovery != nil) {
            if let s = model.recovery, s.day.offset == model.dayOffset {
                content(s)
            } else {
                PulseDetailLoading()
            }
        }
        .task(id: model.detailKey) { await model.loadRecovery() }
    }

    @ViewBuilder
    private func content(_ s: RecoverySnapshot) -> some View {
        PulseRecoveryHero(dial: s.dial)

        if case .calibrating(let nights, let of) = s.dial.state {
            PulseCalibrationCard(nights: nights, of: of)
        }

        if s.dial.value != nil {
            PulseRecoveryContributors(rows: s.contributors)
                .padding(.top, -4)
                .id("pulse.contributors")
            if !s.context.isEmpty {
                VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
                    PulseSectionHeader(String(localized: "Context"))
                    PulseCard(padding: 0) {
                        PulseContributorRows(rows: s.context)
                    }
                }
                .padding(.top, PulseTheme.Space.xs)
            }
        }

        if !s.drivers.isEmpty, let confidence = s.confidence {
            PulseWhatShapedIt(drivers: s.drivers, confidence: confidence)
                .padding(.top, PulseTheme.Space.xs)
                .id("pulse.shaped")
        }

        PulseRecoveryHistory(bars: s.history, endKey: s.day.key, range: $range)
            .padding(.top, PulseTheme.Space.xs)
            .id("pulse.history")
    }
}

/// The 260 pt ring with the band's reading inside it, or whose night a carried score is.
struct PulseRecoveryHero: View {
    let dial: PulseDialData

    private var content: PulseDialContent {
        var content = dial.dialContent()
        if case .noData = dial.state {
            content.caption = String(localized: "Scores from a night of overnight HRV")
        } else if case .carried(let caption) = dial.state {
            content.caption = String(localized: "Showing \(caption)")
        } else if let band = dial.band {
            content.caption = bandLine(band)
        }
        return content
    }

    var body: some View {
        PulseHeroRing(content: content)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private func bandLine(_ band: PulseDisplay.RecoveryBand) -> String {
        switch band {
        case .green: return String(localized: "Ready to push")
        case .yellow: return String(localized: "Maintain today")
        case .red: return String(localized: "Prioritise recovery")
        }
    }
}

/// The contributors under the ring: the notched callout's rows (value over its baseline, trend glyph by
/// good / bad) and the "Today vs. baseline" legend.
struct PulseRecoveryContributors: View {
    let rows: [PulseContributor]

    var body: some View {
        PulseCallout {
            PulseContributorRows(rows: rows)
            PulseLegendWell {
                PulseLegendTodayVsBaseline(period: String(localized: "your baseline"))
            }
        }
    }
}

/// Contributor rows with 16 pt-inset dividers, each opening its metric when it has one.
struct PulseContributorRows: View {
    let rows: [PulseContributor]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if let route = row.route {
                    NavigationLink(value: route) { calloutRow(row) }
                        .buttonStyle(PulsePressStyle())
                } else {
                    calloutRow(row)
                }
                if index < rows.count - 1 {
                    PulseDivider(leadingInset: 16, trailingInset: 16)
                }
            }
        }
    }

    private func calloutRow(_ row: PulseContributor) -> PulseCalloutRow {
        PulseCalloutRow(symbol: Self.symbol(row.id), title: row.title, value: row.value, unit: row.unit,
                        baseline: row.averageText,
                        trend: row.comparison.map { comparison in
                            PulseTrend(direction: Self.direction(comparison.direction),
                                       polarity: PulseMetricPolarity.forMetric(row.id))
                        })
    }

    private static func symbol(_ id: String) -> String {
        switch id {
        case "hrv": return "waveform.path.ecg"
        case "rhr": return "heart"
        case "resp": return "lungs"
        case "sleep": return "moon"
        case "skin": return "thermometer.medium"
        case "spo2": return "drop"
        default: return "circle"
        }
    }

    private static func direction(_ d: PulseDisplay.Direction) -> PulseTrend.Direction {
        switch d {
        case .up: return .up
        case .down: return .down
        case .flat: return .flat
        }
    }
}

/// What calibration means and how far along it is.
struct PulseCalibrationCard: View {
    let nights: Int
    let of: Int

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 10) {
                PulseCardTitle(String(localized: "Building your baseline"))
                Text(ChargeBreakdownFormat.calibrationProgress(banked: nights, seed: of))
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                PulseSegmentBar(filled: nights, total: of, tint: PulseTheme.recoveryHigh)
                    .frame(height: 6)
                Text(String(localized: "Recovery compares each night's heart rate variability, resting heart rate and breathing with your own baseline. That baseline needs \(of) nights of overnight wear before the first score, so the dial fills in once the strap has seen enough nights."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let restart = ChargeBreakdownFormat.currentCalibrationRestartCause() {
                    Text(restart)
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// `total` segments with the first `filled` lit.
struct PulseSegmentBar: View {
    let filled: Int
    let total: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(1, total), id: \.self) { i in
                Capsule().fill(i < filled ? tint : PulseTheme.track)
            }
        }
        .accessibilityHidden(true)
    }
}

/// "What shaped it": the engine's per-term points, one upstream `ChargeDriverRow` per driver. The relative
/// skin-temperature marker is left off: the Context card above already states that night's deviation.
struct PulseWhatShapedIt: View {
    let drivers: [ChargeDriver]
    let confidence: ScoreConfidence

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            HStack(alignment: .center) {
                PulseSectionHeader(String(localized: "What shaped it"))
                PulseStatusChip(confidenceTitle, kind: confidence == .solid ? .positive : .neutral)
                    .accessibilityLabel(confidenceAccessibility)
            }
            PulseCard {
                VStack(spacing: 18) {
                    let biggest = drivers.map { abs($0.deltaPoints) }.max() ?? 1
                    ForEach(Array(drivers.enumerated()), id: \.offset) { _, driver in
                        ChargeDriverRow(driver: driver, maxMagnitude: biggest)
                    }
                }
            }
        }
    }

    /// Spelled out: the classic chip's "REL." / "EST." abbreviations do not read on their own.
    private var confidenceTitle: String {
        switch confidence {
        case .solid: return String(localized: "Reliable")
        case .building: return String(localized: "Estimate")
        case .calibrating: return String(localized: "Calibrating")
        }
    }

    private var confidenceAccessibility: String {
        switch confidence {
        case .solid: return String(localized: "Confidence: reliable")
        case .building: return String(localized: "Confidence: estimate")
        case .calibrating: return String(localized: "Confidence: calibrating")
        }
    }
}

/// 7 / 30 / 90 days of Recovery, each bar in its band colour.
struct PulseRecoveryHistory: View {
    let bars: [PulseDayBar]
    /// The chart's last day: the day the dive is showing.
    let endKey: String
    @Binding var range: Int

    /// Every calendar day in the range, oldest first. It is the x domain, so a day without a score
    /// leaves a gap: taking the last N BARS instead let "7 days" quietly reach back past a missed night.
    private var days: [String] { PulseDisplay.trailingDayKeys(endingOn: endKey, count: range) }

    private var shown: [PulseDayBar] {
        guard let first = days.first else { return [] }
        return bars.filter { $0.id >= first && $0.id <= endKey }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(String(localized: "History"))
            PulseCard {
                VStack(alignment: .leading, spacing: 16) {
                    PulseSegmentedControl(options: [7, 30, 90], selection: $range) { days in
                        String(localized: "\(days) days")
                    }

                    if shown.count >= 2 {
                        let data = shown
                        let domain = days
                        // Categorical x on the DAY KEY: the key is unique and its label is formatted at
                        // UTC, so no axis ever re-derives a date in the device zone.
                        Chart(data) { bar in
                            BarMark(x: .value("Day", bar.id), y: .value("Recovery", bar.value))
                                .foregroundStyle(PulseTheme.recovery(bar.band ?? .yellow))
                                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2))
                        }
                        .chartXScale(domain: domain)
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(position: .trailing, values: [0, 33, 66, 100]) { _ in
                                AxisGridLine().foregroundStyle(PulseTheme.gridOnCard)
                                AxisValueLabel().font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: axisKeys(domain)) { value in
                                AxisValueLabel {
                                    if let key = value.as(String.self) {
                                        Text(PulseFormat.dayLabel(key))
                                    }
                                }
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textTertiary)
                            }
                        }
                        .frame(height: 170)
                        .accessibilityLabel(String(localized: "Recovery, last \(range) days"))
                        .accessibilityValue(accessibilitySummary(data))

                        HStack(spacing: 14) {
                            legend(.green, "67–100")
                            legend(.yellow, "34–66")
                            legend(.red, "0–33")
                            Spacer()
                            if let avg = average(data) {
                                Text(String(localized: "Avg \(PulseFormat.whole(avg))%"))
                                    .pulseText(.secondary)
                                    .foregroundStyle(PulseTheme.textSecondary)
                            }
                        }
                    } else {
                        Text(String(localized: "Not enough scored days yet."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    }
                }
            }
        }
    }

    /// Days to label, a fixed number of days apart counted back from the last day (every 2nd day on a
    /// week, weekly on a month, every 3 weeks on 90 days), so the ticks keep one rhythm; evenly spaced
    /// fractions landed 7, 7 and then 8 days apart. The last day sits against the value axis, where
    /// its label would be clipped, so counting starts one step back.
    private func axisKeys(_ keys: [String]) -> [String] {
        let count = keys.count
        guard count > 1 else { return keys }
        let step = count <= 7 ? 2 : (count <= 30 ? 7 : 21)
        return stride(from: count - 1 - step, through: 0, by: -step).map { keys[$0] }.reversed()
    }

    private func legend(_ band: PulseDisplay.RecoveryBand, _ text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(PulseTheme.recovery(band)).frame(width: 7, height: 7)
            Text(text).font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
        }
        .accessibilityHidden(true)
    }

    private func average(_ data: [PulseDayBar]) -> Double? {
        guard !data.isEmpty else { return nil }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }

    private func accessibilitySummary(_ data: [PulseDayBar]) -> String {
        let greens = data.filter { $0.band == .green }.count
        let yellows = data.filter { $0.band == .yellow }.count
        let reds = data.filter { $0.band == .red }.count
        return String(localized: "\(greens) green, \(yellows) yellow, \(reds) red days")
    }
}
#endif
