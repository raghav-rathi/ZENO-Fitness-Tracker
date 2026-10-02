#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics

/// The current Pulse Strain dive (WHOOP_UI_SPEC §3.5 in the new theme): the 260 pt ring with the day's
/// optimal range and target, the target card, how the day's strain built, heart rate against its zones,
/// time in each zone, calories and the day's activities.
///
/// Owned by group "recovery-strain", which rebuilds it as `PulseStrainDiveView` (callout contributors,
/// Weekly Trends, the inline insight card). Until then that route hosts this screen.
struct PulseStrainView: View {
    @Environment(PulseModel.self) private var model

    var body: some View {
        PulseScreenScaffold(title: PulseFormat.navDayTitle(offset: model.dayOffset, date: model.selectedLogicalDate),
                            coach: .button, ready: model.strain != nil) {
            if let s = model.strain, s.day.offset == model.dayOffset {
                content(s)
            } else {
                PulseDetailLoading()
            }
        }
        .task(id: model.detailKey) { await model.loadStrain() }
    }

    @ViewBuilder
    private func content(_ s: StrainSnapshot) -> some View {
        PulseHeroRing(content: s.dial.dialContent(target: s.target))
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 8)

        if let target = s.target {
            PulseCard { PulseStrainTargetContent(target: target) }
        }

        PulseStrainBuildCard(snapshot: s)
            .id("pulse.build")
        PulseHeartRateZonesCard(snapshot: s)
            .id("pulse.hr")
        PulseZoneTimeCard(snapshot: s)
            .id("pulse.zones")
        PulseStrainStatsRow(snapshot: s)

        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(String(localized: "Activities"))
            PulseCard(padding: 0) {
                VStack(spacing: 0) {
                    if s.workouts.isEmpty {
                        PulseRow(title: String(localized: "No activities"),
                                 subtitle: String(localized: "Logged and auto-detected workouts appear here"),
                                 showsChevron: false) {
                            PulseRowIcon(symbol: "figure.run", tint: PulseTheme.textTertiary)
                        }
                    }
                    ForEach(Array(s.workouts.enumerated()), id: \.element.id) { index, w in
                        PulseLink(PulseRoute.activityDetail(w.route).forExistingEntryPoint) {
                            PulseRow(title: w.title,
                                     subtitle: String(localized: "\(PulseFormat.clock(w.start)) · \(w.durationMin) min\(w.kcal.map { " · \(PulseFormat.grouped($0)) kcal" } ?? "")"),
                                     value: w.strain.map { PulseFormat.oneDecimal($0) },
                                     valueCaption: w.strain == nil ? nil : PulseScore.strain.displayName,
                                     valueTint: PulseTheme.strain) {
                                WorkoutTypeIcon(workoutType: w.sport, size: 16, color: PulseTheme.strain)
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(PulsePressStyle())
                        if index < s.workouts.count - 1 { PulseRowDivider() }
                    }
                }
            }
        }
    }
}

// MARK: - How the day built

struct PulseStrainBuildCard: View {
    let snapshot: StrainSnapshot

    /// The day's strain when it runs ahead of the curve's end. The dial floors today's live score at the
    /// stored day row (`StrainScorer.effectiveEffort`), and that row can carry load the heart-rate
    /// stream here does not show, such as a logged workout. Drawn so the chart cannot quietly disagree
    /// with the dial above it.
    private var dayTotalAhead: Double? {
        guard let total = snapshot.dial.value else { return nil }
        let end = snapshot.curve.last?.value ?? 0
        return total - end > 0.3 ? total : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(title: String(localized: "Through the day"))
            PulseCard {
                if snapshot.curve.count >= 2 {
                    VStack(alignment: .leading, spacing: 10) {
                        chart
                        if let total = dayTotalAhead {
                            Text(String(localized: "Dashed: the day's strain of \(PulseFormat.oneDecimal(total)), which can include load this heart-rate trace does not show, such as a logged workout."))
                                .font(.caption)
                                .foregroundStyle(PulseTheme.textTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    Text(String(localized: "Strain builds here as your strap records heart rate through the day."))
                        .font(.subheadline)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                }
            }
        }
    }

    private var chart: some View {
        Chart {
            if let total = dayTotalAhead {
                RuleMark(y: .value("Day strain", total))
                    .foregroundStyle(PulseTheme.strain.opacity(0.9))
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
            }
            if let target = snapshot.target {
                RectangleMark(xStart: .value("Start", snapshot.window.lowerBound),
                              xEnd: .value("End", snapshot.window.upperBound),
                              yStart: .value("Low", target.range.lowerBound),
                              yEnd: .value("High", target.range.upperBound))
                    .foregroundStyle(PulseTheme.strain.opacity(0.14))
            }
            ForEach(snapshot.curve) { p in
                AreaMark(x: .value("Time", p.date), y: .value("Strain", p.value))
                    .foregroundStyle(LinearGradient(colors: [PulseTheme.strain.opacity(0.35),
                                                             PulseTheme.strain.opacity(0.02)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", p.date), y: .value("Strain", p.value))
                    .foregroundStyle(PulseTheme.strain)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.monotone)
            }
        }
        .chartXScale(domain: snapshot.window.lowerBound...snapshot.window.upperBound)
        .chartYScale(domain: 0...21)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 7, 14, 21]) { _ in
                AxisGridLine().foregroundStyle(PulseTheme.hairline)
                AxisValueLabel().font(PulseType.font(.axis))
                .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .chartXAxis { PulseTimeAxis.marks(for: snapshot.window) }
        .frame(height: 170)
        .accessibilityLabel(String(localized: "Strain through the day"))
        .accessibilityValue(snapshot.curve.last.map {
            String(localized: "\(PulseFormat.oneDecimal($0.value)) at \(PulseFormat.clock($0.date))")
        } ?? "")
    }
}

/// Hour labels on a time axis. The values are real instants, so they are formatted in the device zone.
enum PulseTimeAxis {
    static func marks(for domain: ClosedRange<Date>) -> some AxisContent {
        AxisMarks(values: hours(in: domain)) { value in
            AxisGridLine().foregroundStyle(PulseTheme.hairline)
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date.formatted(.dateTime.hour()))
                }
            }
            .foregroundStyle(PulseTheme.textTertiary)
        }
    }

    /// Whole hours every 3 h (every 6 h past a 13-hour span), leaving out any in the last eighth of the
    /// span, where its label would run into the value axis and be clipped.
    static func hours(in domain: ClosedRange<Date>) -> [Date] {
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        guard span > 0 else { return [] }
        let step = span > 13 * 3600 ? 6 : 3
        let cal = Calendar.current
        guard var t = cal.dateInterval(of: .hour, for: domain.lowerBound)?.start else { return [] }
        if t < domain.lowerBound { t = t.addingTimeInterval(3600) }
        var out: [Date] = []
        while t <= domain.upperBound {
            if cal.component(.hour, from: t) % step == 0,
               t.timeIntervalSince(domain.lowerBound) <= span * 0.875 {
                out.append(t)
            }
            t = t.addingTimeInterval(3600)
        }
        return out
    }
}

// MARK: - Heart rate with zones

struct PulseHeartRateZonesCard: View {
    let snapshot: StrainSnapshot

    private var yDomain: ClosedRange<Double> {
        let bpm = snapshot.hr.map(\.bpm)
        let zoneTop = snapshot.zones.last?.upper ?? 190
        let lo = min(40, (bpm.min() ?? 60) - 5)
        let hi = max(zoneTop, (bpm.max() ?? 150) + 5)
        return lo...hi
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(title: String(localized: "Heart rate"),
                               trailing: snapshot.peakHR.map { String(localized: "Peak \($0) bpm") })
            PulseCard {
                if snapshot.hr.count >= 2 {
                    Chart {
                        ForEach(snapshot.zones) { zone in
                            RectangleMark(xStart: .value("Start", snapshot.window.lowerBound),
                                          xEnd: .value("End", snapshot.window.upperBound),
                                          yStart: .value("Low", zone.lower),
                                          yEnd: .value("High", min(zone.upper, yDomain.upperBound)))
                                .foregroundStyle(PulseTheme.zone(zone.number).opacity(0.10))
                        }
                        ForEach(snapshot.hr) { p in
                            LineMark(x: .value("Time", p.date), y: .value("BPM", p.bpm),
                                     series: .value("Run", p.segment))
                                .foregroundStyle(PulseTheme.textPrimary.opacity(0.9))
                                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        }
                    }
                    .chartXScale(domain: snapshot.window.lowerBound...snapshot.window.upperBound)
                    .chartYScale(domain: yDomain)
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: snapshot.zones.map(\.lower)) { value in
                            AxisGridLine().foregroundStyle(PulseTheme.hairline)
                            AxisValueLabel {
                                if let v = value.as(Double.self) { Text("\(Int(v.rounded()))") }
                            }
                            .foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                    .chartXAxis { PulseTimeAxis.marks(for: snapshot.window) }
                    .frame(height: 190)
                    .accessibilityLabel(String(localized: "Heart rate through the day, shaded by zone"))
                    .accessibilityValue(accessibility)
                } else {
                    Text(String(localized: "No heart rate recorded for this day."))
                        .font(.subheadline)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                }
            }
        }
    }

    private var accessibility: String {
        var parts: [String] = []
        if let avg = snapshot.averageHR { parts.append(String(localized: "average \(avg) beats per minute")) }
        if let peak = snapshot.peakHR { parts.append(String(localized: "peak \(peak)")) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Time in zones

struct PulseZoneTimeCard: View {
    let snapshot: StrainSnapshot

    var body: some View {
        let minutes = snapshot.zoneMinutes
        let top = max(1, minutes.max() ?? 1)
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            PulseSectionHeader(title: String(localized: "Time in zones"))
            PulseCard {
                VStack(spacing: 10) {
                    ForEach(Array(snapshot.zones.enumerated()), id: \.element.id) { index, zone in
                        let m = minutes.indices.contains(index) ? minutes[index] : 0
                        HStack(spacing: 10) {
                            Text(String(localized: "Zone \(zone.number)"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PulseTheme.textSecondary)
                                .frame(width: 58, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(PulseTheme.track)
                                    Capsule()
                                        .fill(PulseTheme.zone(zone.number))
                                        .frame(width: m > 0 ? max(6, geo.size.width * m / top) : 0)
                                }
                            }
                            .frame(height: 8)
                            Text(PulseFormat.duration(minutes: m))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(PulseTheme.textPrimary)
                                .frame(width: 58, alignment: .trailing)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(String(localized: "Zone \(zone.number), \(PulseFormat.duration(minutes: m))"))
                    }
                    Text(String(localized: "Zones from your max heart rate of \(Int((snapshot.zones.last?.upper ?? 0).rounded())) bpm."))
                        .font(.caption2)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Calories and HR

struct PulseStrainStatsRow: View {
    let snapshot: StrainSnapshot

    var body: some View {
        HStack(spacing: 12) {
            PulseMiniStat(title: String(localized: "Calories"),
                          value: snapshot.calories.map { PulseFormat.grouped($0) }, unit: "kcal")
            PulseMiniStat(title: String(localized: "Avg HR"), value: snapshot.averageHR.map { "\($0)" }, unit: "bpm")
            PulseMiniStat(title: String(localized: "Peak HR"), value: snapshot.peakHR.map { "\($0)" }, unit: "bpm")
        }
    }
}
#endif
