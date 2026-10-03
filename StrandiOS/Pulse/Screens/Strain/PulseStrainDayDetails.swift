#if os(iOS)
import SwiftUI
import Charts
import StrandAnalytics

// MARK: - ZENO's Strain day details (WHOOP_UI_SPEC §3.5 item 7)
//
// After Weekly Trends, in this system's look: the STRAIN TARGET card, THROUGH THE DAY (how the day's
// Strain built), HEART RATE against its zones, TIME IN ZONES (zone rows, Zone 5 to 1) and the day's
// calories and heart rate. Every figure is the snapshot's: the zone times are the contributor rows'
// resolver, the calories the weekly card's rule.

struct PulseStrainDayDetails: View {
    let snapshot: StrainDiveSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(String(localized: "Day Details"))
            VStack(alignment: .leading, spacing: PulseTheme.Layout.stackGap) {
                if let target = snapshot.ownTarget {
                    PulseStrainTargetCard(target: target)
                        .id("pulse.target")
                }
                PulseStrainBuildChart(base: snapshot.base, target: snapshot.ownTarget, isToday: snapshot.day.isToday)
                    .id("pulse.build")
                PulseStrainHeartRateChart(base: snapshot.base)
                    .id("pulse.hr")
                PulseStrainTimeInZones(zones: snapshot.base.zones, seconds: snapshot.zoneSeconds)
                    .id("pulse.zones")
                PulseStrainStatsRow(base: snapshot.base)
                    .id("pulse.stats")
            }
        }
    }
}

// MARK: - Strain target

/// STRAIN TARGET: the intent word in the band colour, the optimal range, the 0–21 track (the range as the
/// dial's light band, the day's Strain in strain blue, the target tick at the range's middle) and where the
/// day stands. Shown only for the day's own Recovery, as the dial's band is.
struct PulseStrainTargetCard: View {
    let target: PulseStrainTarget

    /// Where the day stands, from the printed figures (the insight above says the same).
    private var standing: String {
        guard let current = target.current else { return String(localized: "No Strain logged yet") }
        let shown = StrainContributors.printedOneDecimal(current)
        switch StrainContributors.standing(strain: current, range: target.range) {
        case .below:
            let gap = StrainContributors.printedOneDecimal(target.range.lowerBound) - shown
            return String(localized: "\(PulseFormat.oneDecimal(gap)) below the range")
        case .above:
            let gap = shown - StrainContributors.printedOneDecimal(target.range.upperBound)
            return String(localized: "\(PulseFormat.oneDecimal(gap)) above the range")
        case .within:
            return String(localized: "In the range")
        }
    }

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    PulseCardTitle(String(localized: "Strain target"))
                    if let label = target.currentLabel {
                        Text(label)
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize()
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(target.intentTitle)
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.recoveryText(target.band))
                    Text(target.rangeText)
                        .pulseText(.mediumValue)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
                PulseStrainTargetTrack(target: target)
                    .frame(height: 10)
                HStack {
                    Text(verbatim: "0")
                    Spacer(minLength: 8)
                    Text(standing)
                    Spacer(minLength: 8)
                    Text(verbatim: "21")
                }
                .pulseText(.axis)
                .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Strain target: \(target.intentTitle), \(target.rangeText) out of 21. \(target.currentLabel ?? ""). \(standing)."))
    }
}

/// The 0–21 track: white 10%, the optimal range as the dial's band, the day so far in strain blue and a
/// 2 pt white tick at the target.
private struct PulseStrainTargetTrack: View {
    let target: PulseStrainTarget

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let low = CGFloat(target.range.lowerBound / 21)
            let high = CGFloat(target.range.upperBound / 21)
            let current = CGFloat(min(1, max(0, (target.current ?? 0) / 21)))
            let tick = CGFloat(target.targetValue / 21)
            ZStack(alignment: .leading) {
                Capsule().fill(PulseTheme.track)
                Capsule()
                    .fill(PulseTheme.targetBandOverTrack)
                    .frame(width: max(geo.size.height, w * (high - low)))
                    .offset(x: w * low)
                if target.current != nil {
                    Capsule()
                        .fill(PulseTheme.strain)
                        .frame(width: max(geo.size.height, w * current))
                }
                Rectangle()
                    .fill(Color.white)
                    .frame(width: PulseTheme.Dial.tickWidth, height: geo.size.height)
                    .offset(x: w * tick - PulseTheme.Dial.tickWidth / 2)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Through the day

/// THROUGH THE DAY: the day's Strain as it accumulated (the same scorer as the dial), over the optimal
/// range; a dashed line marks the day's total when it runs ahead of the heart-rate trace. Without a trace,
/// today says where it will appear and a past day says none was recorded, as HEART RATE and TIME IN ZONES
/// do.
private struct PulseStrainBuildChart: View {
    let base: StrainSnapshot
    let target: PulseStrainTarget?
    let isToday: Bool

    /// The day's Strain when it runs ahead of the curve's end: the dial floors today's live score at the
    /// stored day row, which can carry load this trace does not show (a logged workout).
    private var totalAhead: Double? {
        guard let total = base.dial.value else { return nil }
        let end = base.curve.last?.value ?? 0
        return total - end > 0.3 ? total : nil
    }

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 16) {
                PulseCardTitle(String(localized: "Through the day"))
                if base.curve.count >= 2 {
                    chart
                    if let total = totalAhead {
                        Text(String(localized: "Dashed: the day's Strain of \(PulseFormat.oneDecimal(total)), which can include load this heart-rate trace does not show, such as a logged workout."))
                            .pulseText(.legend)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(isToday
                         ? String(localized: "Strain builds here as your strap records heart rate through the day.")
                         : String(localized: "No heart rate recorded for this day."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            if let target {
                RectangleMark(xStart: .value("Start", base.window.lowerBound),
                              xEnd: .value("End", base.window.upperBound),
                              yStart: .value("Low", target.range.lowerBound),
                              yEnd: .value("High", target.range.upperBound))
                    .foregroundStyle(PulseTheme.typicalBand)
            }
            if let total = totalAhead {
                RuleMark(y: .value("Day strain", total))
                    .foregroundStyle(PulseTheme.strain)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            ForEach(base.curve) { p in
                AreaMark(x: .value("Time", p.date), y: .value("Strain", p.value))
                    .foregroundStyle(LinearGradient(colors: [PulseTheme.strain.opacity(0.35), PulseTheme.strain.opacity(0)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", p.date), y: .value("Strain", p.value))
                    .foregroundStyle(PulseTheme.strain)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .interpolationMethod(.monotone)
            }
        }
        .chartXScale(domain: base.window.lowerBound...base.window.upperBound)
        .chartYScale(domain: 0...21)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 7, 14, 21]) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                AxisValueLabel().font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .chartXAxis { PulseStrainTimeAxis.marks(for: base.window) }
        .frame(height: 170)
        .accessibilityLabel(String(localized: "Strain through the day"))
        .accessibilityValue(base.curve.last.map {
            String(localized: "\(PulseFormat.oneDecimal($0.value)) at \(PulseFormat.clock($0.date))")
        } ?? "")
    }
}

/// Hour labels on a time axis. The values are real instants, so they are formatted in the device zone.
enum PulseStrainTimeAxis {
    static func marks(for domain: ClosedRange<Date>) -> some AxisContent {
        AxisMarks(values: hours(in: domain)) { value in
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date.formatted(.dateTime.hour()))
                }
            }
            .font(PulseType.font(.axis))
            .foregroundStyle(PulseTheme.textTertiary)
        }
    }

    /// Whole hours every 3 h (every 6 h past a 13-hour span), leaving out any in the last eighth of the
    /// span, where the label would run into the value axis.
    static func hours(in domain: ClosedRange<Date>) -> [Date] {
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        guard span > 0 else { return [] }
        let step = span > 13 * 3600 ? 6 : 3
        let cal = Calendar.current
        guard var t = cal.dateInterval(of: .hour, for: domain.lowerBound)?.start else { return [] }
        if t < domain.lowerBound { t = t.addingTimeInterval(3600) }
        var out: [Date] = []
        while t <= domain.upperBound {
            if cal.component(.hour, from: t) % step == 0, t.timeIntervalSince(domain.lowerBound) <= span * 0.875 {
                out.append(t)
            }
            t = t.addingTimeInterval(3600)
        }
        return out
    }
}

// MARK: - Heart rate

/// HEART RATE: the day's heart rate (5-minute means, a gap in wear left as a gap) over its zone bands, with
/// the peak at the right of the title.
private struct PulseStrainHeartRateChart: View {
    let base: StrainSnapshot

    private var yDomain: ClosedRange<Double> {
        let bpm = base.hr.map(\.bpm)
        let zoneTop = base.zones.last?.upper ?? 190
        let lo = min(40, (bpm.min() ?? 60) - 5)
        let hi = max(zoneTop, (bpm.max() ?? 150) + 5)
        return lo...hi
    }

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    PulseCardTitle(String(localized: "Heart rate"))
                    if let peak = base.peakHR {
                        Text(String(localized: "Peak \(peak) bpm"))
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize()
                    }
                }
                if base.hr.count >= 2 {
                    chart
                } else {
                    Text(String(localized: "No heart rate recorded for this day."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(base.zones) { zone in
                RectangleMark(xStart: .value("Start", base.window.lowerBound),
                              xEnd: .value("End", base.window.upperBound),
                              yStart: .value("Low", zone.lower),
                              yEnd: .value("High", min(zone.upper, yDomain.upperBound)))
                    .foregroundStyle(PulseTheme.Zone.color(zone.number).opacity(0.10))
            }
            ForEach(base.hr) { p in
                LineMark(x: .value("Time", p.date), y: .value("BPM", p.bpm), series: .value("Run", p.segment))
                    .foregroundStyle(PulseTheme.textPrimary.opacity(0.9))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .chartXScale(domain: base.window.lowerBound...base.window.upperBound)
        .chartYScale(domain: yDomain)
        .chartYAxis {
            AxisMarks(position: .trailing, values: base.zones.map(\.lower)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                AxisValueLabel {
                    // A zone's first whole beat, the figure its TIME IN ZONES row starts on ("161-173 BPM").
                    if let v = value.as(Double.self) { Text(verbatim: "\(Int(v.rounded(.up)))") }
                }
                .font(PulseType.font(.axis))
                .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .chartXAxis { PulseStrainTimeAxis.marks(for: base.window) }
        .frame(height: 190)
        .accessibilityLabel(String(localized: "Heart rate through the day, shaded by zone"))
        .accessibilityValue([base.averageHR.map { String(localized: "average \($0) beats per minute") },
                             base.peakHR.map { String(localized: "peak \($0)") }]
            .compactMap { $0 }.joined(separator: ", "))
    }
}

// MARK: - Time in zones

/// TIME IN ZONES: one zone row card per zone, Zone 5 to Zone 1 (§2.6 item 18), from the same time-in-zone
/// figures as the contributor rows. The rows are Activity Details' own (`PulseActivityZoneRow`), labelled by
/// the same rule, so one day's zones read the same on both screens: "174+ BPM" open-ended at the top, no
/// beat in two zones, and a zone with no time a short title-only card with its text dimmed (g16, hc82).
private struct PulseStrainTimeInZones: View {
    let zones: [PulseZoneBand]
    /// Seconds in zones 1-5; nil when the day has no heart rate.
    let seconds: [Double]?

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.gridGap) {
            PulseCardTitle(String(localized: "Time in zones"))
                .padding(.horizontal, 4)
            if let seconds {
                let total = seconds.reduce(0, +)
                ForEach(zones.reversed()) { zone in
                    let s = seconds.indices.contains(zone.number - 1) ? seconds[zone.number - 1] : 0
                    PulseActivityZoneRow(row: ActivityZoneRow(
                        zone: zone.number,
                        range: PulseSnapshotBuilder.zoneRange(zone.number, lower: zone.lower, upper: zone.upper),
                        share: total > 0 ? s / total : 0,
                        seconds: s,
                        typical: nil))
                }
                Text(String(localized: "Zones from your maximum heart rate of \(Int((zones.last?.upper ?? 0).rounded())) bpm."))
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.horizontal, 4)
            } else {
                PulseCard {
                    Text(String(localized: "No heart rate recorded for this day."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Calories and heart rate

/// CALORIES · AVG HR · PEAK HR: three equal tiles side by side, stacked full width when their figures
/// would not fit side by side (large Dynamic Type, long labels), so a value never truncates.
private struct PulseStrainStatsRow: View {
    let base: StrainSnapshot

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: PulseTheme.Layout.gridGap) { tiles }
            VStack(spacing: PulseTheme.Layout.gridGap) { tiles }
        }
    }

    @ViewBuilder
    private var tiles: some View {
        tile(String(localized: "Calories"), base.calories.map { PulseFormat.grouped($0) }, "kcal")
        tile(String(localized: "Avg HR"), base.averageHR.map { "\($0)" }, "bpm")
        tile(String(localized: "Peak HR"), base.peakHR.map { "\($0)" }, "bpm")
    }

    private func tile(_ title: String, _ value: String?, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            PulseLabel(title, color: PulseTheme.textSecondary)
            PulseValueText(value: value ?? "--", unit: value == nil ? nil : unit, style: .tileValue,
                           unitStyle: .tileUnit,
                           color: value == nil ? PulseTheme.textTertiary : PulseTheme.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value.map { "\($0) \(unit)" } ?? String(localized: "no data"))")
    }
}
#endif
