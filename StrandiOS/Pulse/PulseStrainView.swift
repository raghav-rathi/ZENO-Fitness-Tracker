#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics

/// The Strain deep dive: the dial, the target, how the day's strain built, heart rate against its zones,
/// time in each zone, calories and the day's activities.
struct PulseStrainView: View {
    @Environment(PulseModel.self) private var model

    var body: some View {
        PulseDetailScaffold(title: PulseScore.strain.displayName, subtitle: model.dayCaption) {
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
        VStack(spacing: 6) {
            PulseDial(data: s.dial, diameter: 196, lineWidth: 14, showsLabel: false)
            Text(String(localized: "of 21"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(PulseTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)

        if let target = s.target {
            PulseCard { PulseStrainTargetContent(target: target) }
        }

        PulseStrainBuildCard(snapshot: s)
        PulseHeartRateZonesCard(snapshot: s)
        PulseZoneTimeCard(snapshot: s)
        PulseStrainStatsRow(snapshot: s)

        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "Activities"))
            PulseCard(padding: 0) {
                VStack(spacing: 0) {
                    if s.workouts.isEmpty {
                        PulseRow(title: String(localized: "No activities"),
                                 subtitle: String(localized: "Workouts you log or NOOP detects appear here"),
                                 showsChevron: false) {
                            PulseRowIcon(symbol: "figure.run", tint: PulseTheme.textTertiary)
                        }
                    }
                    ForEach(Array(s.workouts.enumerated()), id: \.element.id) { index, w in
                        NavigationLink(value: PulseRoute.workout(w.route)) {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PulseSectionHeader(title: String(localized: "Through the day"))
            PulseCard {
                if snapshot.curve.count >= 2 {
                    Chart {
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
                            AxisValueLabel().foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                    .chartXAxis { PulseTimeAxis.marks() }
                    .frame(height: 170)
                    .accessibilityLabel(String(localized: "Strain through the day"))
                    .accessibilityValue(snapshot.curve.last.map {
                        String(localized: "\(PulseFormat.oneDecimal($0.value)) at \(PulseFormat.clock($0.date))")
                    } ?? "")
                } else {
                    Text(String(localized: "Strain builds here as your strap records heart rate through the day."))
                        .font(.subheadline)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                }
            }
        }
    }
}

/// Hour labels on a time axis. Real instants, so the chart's device-zone calendar is the right one.
enum PulseTimeAxis {
    static func marks() -> some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 5)) { value in
            AxisGridLine().foregroundStyle(PulseTheme.hairline)
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date.formatted(.dateTime.hour()))
                }
            }
            .foregroundStyle(PulseTheme.textTertiary)
        }
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
        VStack(alignment: .leading, spacing: 10) {
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
                    .chartXAxis { PulseTimeAxis.marks() }
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
        VStack(alignment: .leading, spacing: 10) {
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
            stat(String(localized: "Calories"), snapshot.calories.map { PulseFormat.grouped($0) }, "kcal")
            stat(String(localized: "Avg HR"), snapshot.averageHR.map { "\($0)" }, "bpm")
            stat(String(localized: "Peak HR"), snapshot.peakHR.map { "\($0)" }, "bpm")
        }
    }

    private func stat(_ title: String, _ value: String?, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PulseLabel(title)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value ?? "–")
                    .font(PulseTheme.numeral(24))
                    .foregroundStyle(value == nil ? PulseTheme.textTertiary : PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if value != nil {
                    Text(unit)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PulseCardSurface())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.map { "\(title), \($0) \(unit)" } ?? "\(title), no data")
    }
}
#endif
