#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics

/// The shared frame of a deep dive: an inline title with the day under it, the Pulse page behind.
struct PulseDetailScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    /// The snapshot has landed (drives the DEBUG screenshot scroll).
    var ready = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: PulseTheme.sectionSpacing) {
                    content()
                    Color.clear.frame(height: 1).id("pulse.bottom")
                }
                .padding(.horizontal, PulseTheme.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .pulseDebugScroll(proxy, ready: ready)
        }
        .pulsePage()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(PulseTheme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// A loading placeholder for a dive whose snapshot is still building.
struct PulseDetailLoading: View {
    var body: some View {
        ProgressView()
            .tint(PulseTheme.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 240)
    }
}

extension PulseModel {
    /// "Today, Wed 30 Sep" for the dive subtitle.
    var dayCaption: String {
        "\(PulseFormat.dayTitle(offset: dayOffset, date: selectedLogicalDate)), \(PulseFormat.daySubtitle(offset: dayOffset, date: selectedLogicalDate))"
    }
}

// MARK: - Recovery

struct PulseRecoveryView: View {
    @Environment(PulseModel.self) private var model
    #if DEBUG
    @State private var range = PulseDebugLaunch.historyRange ?? 30
    #else
    @State private var range = 30
    #endif

    var body: some View {
        PulseDetailScaffold(title: PulseScore.recovery.displayName, subtitle: model.dayCaption,
                            ready: model.recovery != nil) {
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
            PulseContributorsCard(title: String(localized: "Contributors"),
                                  trailing: s.sourceDayKey.map { PulseFormat.dayLabel($0) },
                                  rows: s.contributors)
                .id("pulse.contributors")
            if !s.context.isEmpty {
                PulseContributorsCard(title: String(localized: "Context"), trailing: nil, rows: s.context)
            }
        }

        if !s.drivers.isEmpty, let confidence = s.confidence {
            PulseWhatShapedIt(drivers: s.drivers, confidence: confidence)
                .id("pulse.shaped")
        }

        PulseRecoveryHistory(bars: s.history, endKey: s.day.key, range: $range)
            .id("pulse.history")
    }
}

/// The big dial with the band word and, for a carried score, whose night it is.
struct PulseRecoveryHero: View {
    let dial: PulseDialData

    var body: some View {
        VStack(spacing: 12) {
            PulseDial(data: dial, diameter: 196, lineWidth: 14, showsLabel: false)
            if let band = dial.band {
                HStack(spacing: 8) {
                    PulseChip(text: bandName(band), tint: PulseTheme.recoveryText(band))
                    Text(bandLine(band))
                        .font(.subheadline)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
            if case .carried(let caption) = dial.state {
                Text(String(localized: "No score for this day yet. Showing \(caption)."))
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            if case .noData = dial.state {
                Text(String(localized: "No Recovery for this day. It scores from a night of overnight HRV."))
                    .font(.caption)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func bandName(_ band: PulseDisplay.RecoveryBand) -> String {
        switch band {
        case .green: return String(localized: "Green")
        case .yellow: return String(localized: "Yellow")
        case .red: return String(localized: "Red")
        }
    }

    private func bandLine(_ band: PulseDisplay.RecoveryBand) -> String {
        switch band {
        case .green: return String(localized: "Ready to push")
        case .yellow: return String(localized: "Maintain today")
        case .red: return String(localized: "Prioritise recovery")
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
                PulseLabel(String(localized: "Building your baseline"), color: PulseTheme.textSecondary)
                Text(ChargeBreakdownFormat.calibrationProgress(banked: nights, seed: of))
                    .font(.headline)
                    .foregroundStyle(PulseTheme.textPrimary)
                PulseSegmentBar(filled: nights, total: of, tint: PulseTheme.recoveryGreen)
                    .frame(height: 6)
                Text(String(localized: "Recovery compares each night's heart rate variability, resting heart rate and breathing with your own baseline. That baseline needs \(of) nights of overnight wear before the first score, so the dial fills in once the strap has seen enough nights."))
                    .font(.subheadline)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let restart = ChargeBreakdownFormat.currentCalibrationRestartCause() {
                    Text(restart)
                        .font(.caption)
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

/// "What shaped it": the engine's per-term points, one upstream `ChargeDriverRow` per driver, under a
/// Pulse section header rather than inside `ChargeBreakdownSection`, whose leading divider (it sits
/// under the classic ring) drew a stray rule across the top of a card. The relative skin-temperature
/// marker is left off: the Context card above already states that night's deviation.
struct PulseWhatShapedIt: View {
    let drivers: [ChargeDriver]
    let confidence: ScoreConfidence

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                PulseLabel(String(localized: "What shaped it"), color: PulseTheme.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                PulseChip(text: confidenceTitle, tint: confidenceTint)
                    .accessibilityLabel(confidenceAccessibility)
            }
            .padding(.horizontal, 4)
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

    private var confidenceTint: Color {
        confidence == .solid ? PulseTheme.accent : PulseTheme.textSecondary
    }

    private var confidenceAccessibility: String {
        switch confidence {
        case .solid: return String(localized: "Confidence: reliable")
        case .building: return String(localized: "Confidence: estimate")
        case .calibrating: return String(localized: "Confidence: calibrating")
        }
    }
}

/// Rows of contributors, each against the engine's baseline or, for terms without one, its 30-day mean.
struct PulseContributorsCard: View {
    let title: String
    let trailing: String?
    let rows: [PulseContributor]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: title, trailing: trailing)
            PulseCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        if let route = row.route {
                            NavigationLink(value: route) { PulseContributorRow(row: row, linked: true) }
                                .buttonStyle(PulsePressStyle())
                        } else {
                            PulseContributorRow(row: row, linked: false)
                        }
                        if index < rows.count - 1 {
                            Rectangle().fill(PulseTheme.hairline).frame(height: 1).padding(.leading, 14)
                        }
                    }
                }
            }
        }
    }
}

struct PulseContributorRow: View {
    let row: PulseContributor
    let linked: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PulseTheme.textPrimary)
                if let average = row.averageText {
                    Text(average)
                        .font(.caption)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(row.value)
                        .font(PulseTheme.numeral(22))
                        .foregroundStyle(PulseTheme.textPrimary)
                    if !row.unit.isEmpty {
                        Text(row.unit)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
                if let c = row.comparison {
                    PulseComparisonLine(comparison: c, showsCaption: false)
                }
            }
            if linked { PulseChevron() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibility)
    }

    private var accessibility: String {
        var parts = ["\(row.title), \(row.value) \(row.unit)"]
        if let c = row.comparison { parts.append(c.accessibility) }
        return parts.joined(separator: ", ")
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
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "History"))
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    Picker(String(localized: "Range"), selection: $range) {
                        Text(String(localized: "7 days")).tag(7)
                        Text(String(localized: "30 days")).tag(30)
                        Text(String(localized: "90 days")).tag(90)
                    }
                    .pickerStyle(.segmented)

                    if shown.count >= 2 {
                        let data = shown
                        let domain = days
                        // Categorical x on the DAY KEY: the key is unique and its label is formatted at
                        // UTC, so no axis ever re-derives a date in the device zone.
                        Chart(data) { bar in
                            BarMark(x: .value("Day", bar.id), y: .value("Recovery", bar.value))
                                .foregroundStyle(PulseTheme.recovery(bar.band ?? .yellow))
                                .cornerRadius(2)
                        }
                        .chartXScale(domain: domain)
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(position: .trailing, values: [0, 33, 67, 100]) { _ in
                                AxisGridLine().foregroundStyle(PulseTheme.hairline)
                                AxisValueLabel().foregroundStyle(PulseTheme.textTertiary)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: axisKeys(domain)) { value in
                                AxisValueLabel {
                                    if let key = value.as(String.self) {
                                        Text(PulseFormat.dayLabel(key))
                                    }
                                }
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
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PulseTheme.textSecondary)
                            }
                        }
                    } else {
                        Text(String(localized: "Not enough scored days yet."))
                            .font(.subheadline)
                            .foregroundStyle(PulseTheme.textTertiary)
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
            Text(text).font(.caption2.monospacedDigit()).foregroundStyle(PulseTheme.textTertiary)
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
