#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics

// MARK: - The four detail cards (WHOOP_UI_SPEC §3.3 item 7)
//
// HOURS VS. NEEDED, SLEEP CONSISTENCY, SLEEP EFFICIENCY and SLEEP STRESS, in that order, on the detail fill
// with ⓘ at the top-right. A card with nothing to show keeps its title and prints the dash WHOOP prints
// (deep-dives-2026/01): "-:--" or "--%".

// MARK: HOURS VS. NEEDED (deep-dives-2026/02, 12, 15, 18)

struct PulseSleepHoursVsNeededCard: View {
    let card: SleepHoursVsNeeded
    var onInfo: () -> Void

    /// The bars' track width, measured (the labels and values are positioned along it).
    @State private var trackWidth: CGFloat = 300

    var body: some View {
        SleepDetailCard(String(localized: "Hours vs. needed"), onInfo: onInfo) {
            SleepFigureView(figure: card.figure)
            VStack(alignment: .leading, spacing: 6) {
                labelled(String(localized: "Hours of sleep"), value: card.hoursText, width: hoursWidth)
                Capsule(style: .circular)
                    .fill(LinearGradient(stops: [
                        .init(color: PulseTheme.card, location: 0),
                        .init(color: PulseTheme.SleepDetail.hoursBarMid, location: 0.4),
                        .init(color: PulseTheme.sleep, location: 0.67),
                        .init(color: PulseTheme.sleep, location: 1),
                    ], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(hoursWidth, 12), height: 12)
                if card.needMin != nil {
                    needBar
                    labelled(String(localized: "Sleep needed"), value: card.needText ?? "", width: needWidth)
                }
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GeometryReader { geo in
                Color.clear.preference(key: SleepWidthKey.self, value: geo.size.width - 16)
            })
            .onPreferenceChange(SleepWidthKey.self) { w in
                if w > 0, abs(w - trackWidth) > 0.5 { trackWidth = w }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(card.needText.map { String(localized: "\(card.hoursText) asleep of \($0) needed") }
                                ?? String(localized: "\(card.hoursText) asleep"))
            if !card.rows.isEmpty {
                breakdown
            }
        }
    }

    /// The longer of hours and need spans the track; the other is drawn to the same scale.
    private var scale: Double { max(card.hoursMin, card.needMin ?? 0, 1) }
    private var hoursWidth: CGFloat { CGFloat(card.hoursMin / scale) * trackWidth }
    private var needWidth: CGFloat { CGFloat((card.needMin ?? 0) / scale) * trackWidth }

    /// A caps label at the left and its value right-aligned to the end of its bar (never under the label).
    private func labelled(_ label: String, value: String, width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Text(label)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
                .padding(.bottom, 2)
            Text(value)
                .pulseText(.rowValue)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize()
                .frame(width: max(width, PulseTextMetrics.width(label, style: .label) + 56), alignment: .trailing)
        }
    }

    /// The need as one bar: the healthy minimum (net of nap credit) in grey, then strain and debt.
    private var needBar: some View {
        let parts: [(Double, Color)] = [
            (card.minimumMin, PulseTheme.SleepDetail.healthyMinimum),
            (card.strainMin, PulseTheme.SleepDetail.recentStrain),
            (card.debtMin, PulseTheme.SleepDetail.sleepDebt),
        ].filter { $0.0 >= 0.5 }
        let total = max(parts.reduce(0) { $0 + $1.0 }, 1)
        let width = max(needWidth, 12)
        return HStack(spacing: 2) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                Rectangle()
                    .fill(part.1)
                    .frame(width: max(3, (width - CGFloat(parts.count - 1) * 2) * CGFloat(part.0 / total)))
            }
        }
        .frame(width: width, height: 12, alignment: .leading)
        .clipShape(Capsule(style: .circular))
    }

    /// The need's parts in a well whose notch points up at the SLEEP NEEDED value.
    private var breakdown: some View {
        let valueEnd = 8 + max(needWidth, PulseTextMetrics.width(String(localized: "Sleep needed"), style: .label) + 56)
        let tip = (valueEnd - 16) / max(trackWidth + 16, 1)
        return PulseNotchedWell(notchPosition: min(0.94, max(0.08, tip))) {
            ForEach(card.rows) { row in
                HStack(spacing: 10) {
                    Group {
                        switch row.swatch {
                        case .minimum: SleepSwatch(color: PulseTheme.SleepDetail.healthyMinimum)
                        case .strain: SleepSwatch(color: PulseTheme.SleepDetail.recentStrain)
                        case .debt: SleepSwatch(color: PulseTheme.SleepDetail.sleepDebt)
                        case .none: Color.clear.frame(width: 12, height: 12)
                        }
                    }
                    Text(row.title)
                        .pulseText(.filter)
                        .foregroundStyle(row.dimmed ? PulseTheme.textSecondary : PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    Text(row.value)
                        .pulseText(.rowValue)
                        .foregroundStyle(row.dimmed ? PulseTheme.textSecondary : PulseTheme.textPrimary)
                }
                // 23 pt from row to row with the well's own 4 pt spacing (deep-dives-2026/18).
                .frame(minHeight: 19)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// A measured width, reported up from a background reader.
struct SleepWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

// MARK: SLEEP CONSISTENCY (deep-dives-2026/03, 18, 19c)

struct PulseSleepConsistencyCard: View {
    let card: SleepConsistencyCard
    var onInfo: () -> Void

    var body: some View {
        SleepDetailCard(String(localized: "Sleep consistency"), onInfo: onInfo) {
            HStack(alignment: .bottom, spacing: 8) {
                if let figure = card.figure {
                    SleepFigureView(figure: figure)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        SleepEmptyFigure(text: "--%")
                        Text(String(localized: "Calibrating"))
                            .pulseText(.subtitle)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                if !card.optimal.isEmpty {
                    HStack(spacing: 7) {
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: 1))
                            p.addLine(to: CGPoint(x: 18, y: 1))
                        }
                        .stroke(PulseTheme.SleepDetail.optimalDash, style: StrokeStyle(lineWidth: 1.5, dash: [3.5, 2.5]))
                        .frame(width: 18, height: 2)
                        Text(String(localized: "Optimal bed/waketime"))
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.bottom, 2)
                    .accessibilityElement(children: .combine)
                }
            }
            if !card.nights.isEmpty {
                PulseSleepConsistencyChart(card: card)
                    .padding(.top, 4)
            }
        }
    }
}

/// Five nights on an inverted clock (earlier at the top): past nights grey, last night sleep blue with its
/// bed and wake times in pills, and the dashed optimal bed and wake curves across the whole plot.
struct PulseSleepConsistencyChart: View {
    let card: SleepConsistencyCard

    /// 40 pt per four-hour gridline step, as WHOOP spaces them (deep-dives-2026/03, 18), plus the x labels.
    private var height: CGFloat { CGFloat(max(card.lines.count - 1, 2)) * 40 + 30 }

    var body: some View {
        // Positions are minutes after noon; the y axis is drawn negated so the evening sits on top.
        let domain = (-card.domain.upperBound)...(-card.domain.lowerBound)
        Chart {
            ForEach(card.nights) { night in
                RectangleMark(x: .value("Night", night.id), yStart: .value("Bed", -night.bed),
                              yEnd: .value("Wake", -night.wake), width: .fixed(14))
                    .foregroundStyle(night.isLast ? PulseTheme.sleep : PulseTheme.SleepDetail.consistencyPast)
                    .cornerRadius(3)
            }
        }
        .chartXScale(domain: card.nights.map(\.id))
        .chartYScale(domain: domain)
        .chartYAxis {
            AxisMarks(position: .leading, values: card.lines.map { -$0.position }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                AxisValueLabel {
                    if let v = value.as(Double.self), let line = card.lines.first(where: { -$0.position == v }) {
                        Text(line.label)
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: card.nights.map(\.id)) { value in
                AxisValueLabel(centered: true) {
                    if let id = value.as(String.self), let night = card.nights.first(where: { $0.id == id }) {
                        Text(night.label)
                            .font(PulseType.font(.legend))
                            .foregroundStyle(night.isLast ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let anchor = proxy.plotFrame {
                    let plot = geo[anchor]
                    optimalCurve(proxy: proxy, plot: plot, keyPath: \.bed)
                    optimalCurve(proxy: proxy, plot: plot, keyPath: \.wake)
                    pills(proxy: proxy, plot: plot)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Bed and wake times, last five nights"))
        .accessibilityValue([card.lastBedText.map { String(localized: "last night to bed \($0)") },
                             card.lastWakeText.map { String(localized: "up \($0)") }].compactMap { $0 }.joined(separator: ", "))
    }

    /// A dashed smooth curve through each night's optimal time, carried flat to both edges of the plot.
    private func optimalCurve(proxy: ChartProxy, plot: CGRect,
                              keyPath: KeyPath<SleepConsistencyCard.Optimal, Double>) -> some View {
        let points: [CGPoint] = card.optimal.compactMap { o in
            guard let x = proxy.position(forX: o.id), let y = proxy.position(forY: -o[keyPath: keyPath]) else {
                return nil
            }
            return CGPoint(x: plot.minX + x, y: plot.minY + y)
        }
        return Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: plot.minX, y: first.y))
            path.addLine(to: first)
            for (a, b) in zip(points, points.dropFirst()) {
                let mid = (a.x + b.x) / 2
                path.addCurve(to: b, control1: CGPoint(x: mid, y: a.y), control2: CGPoint(x: mid, y: b.y))
            }
            path.addLine(to: CGPoint(x: plot.maxX, y: last.y))
        }
        .stroke(PulseTheme.SleepDetail.optimalDash, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    }

    /// Last night's bed time above its bar and wake time below it.
    @ViewBuilder
    private func pills(proxy: ChartProxy, plot: CGRect) -> some View {
        if let last = card.nights.first(where: \.isLast), let x = proxy.position(forX: last.id),
           let top = proxy.position(forY: -last.bed), let bottom = proxy.position(forY: -last.wake) {
            if let bed = card.lastBedText {
                pill(bed).position(x: plot.minX + x, y: plot.minY + top - 13)
            }
            if let wake = card.lastWakeText {
                pill(wake).position(x: plot.minX + x, y: plot.minY + bottom + 13)
            }
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(PulseType.numeral(15))
            .foregroundStyle(PulseTheme.sleep)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                .fill(PulseTheme.SleepDetail.consistencyCallout))
    }
}

// MARK: SLEEP EFFICIENCY (deep-dives-2026/19, 18, 19c)

struct PulseSleepEfficiencyCard: View {
    let card: SleepEfficiencyCard
    var onInfo: () -> Void

    var body: some View {
        SleepDetailCard(String(localized: "Sleep efficiency"), onInfo: onInfo) {
            SleepFigureView(figure: card.figure)
            VStack(spacing: 10) {
                SleepLabelValueRow(label: String(localized: "Asleep"), value: card.asleepText)
                if !card.asleepRuns.isEmpty || !card.awakeRuns.isEmpty {
                    asleepTrack
                    awakeTrack
                }
                SleepLabelValueRow(label: String(localized: "Awake"), value: card.awakeText)
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)
            if let events = card.wakeEvents {
                PulseDivider()
                    .padding(.horizontal, -4)
                    .padding(.top, 6)
                HStack(spacing: 10) {
                    SleepSwatch(color: PulseTheme.SleepDetail.wakeEvents)
                    Text(String(localized: "Wake events"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    Text("\(events)")
                        .pulseText(.calloutValue)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// ASLEEP: the asleep stretches in sleep blue on the hatched track, the wakes left as hatch.
    private var asleepTrack: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                PulseHatchedTrack(cornerRadius: 6)
                ForEach(Array(card.asleepRuns.enumerated()), id: \.offset) { _, run in
                    Rectangle()
                        .fill(PulseTheme.sleep)
                        .frame(width: max(1.5, w * CGFloat(run.upperBound - run.lowerBound) - 1))
                        .offset(x: w * CGFloat(run.lowerBound))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }

    /// AWAKE: hatched, with a white tick for each short wake and a light block for each long one.
    private var awakeTrack: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                PulseHatchedTrack(cornerRadius: 2)
                ForEach(Array(card.awakeRuns.enumerated()), id: \.offset) { _, run in
                    Rectangle()
                        .fill(run.isLong ? PulseTheme.SleepDetail.awakeBlock : Color.white)
                        .frame(width: run.isLong ? max(3, w * CGFloat(run.range.upperBound - run.range.lowerBound)) : 2)
                        .offset(x: w * CGFloat(run.range.lowerBound))
                }
            }
        }
        .frame(height: 15)
        .accessibilityHidden(true)
    }
}

// MARK: SLEEP STRESS (deep-dives-2026/19b, 19c)

struct PulseSleepStressCard: View {
    /// nil while the night's stress is still being scored.
    let stress: SleepStressSnapshot?
    var onInfo: () -> Void

    var body: some View {
        SleepDetailCard(String(localized: "Sleep stress"), onInfo: onInfo) {
            if let stress {
                switch stress.state {
                case .scored:
                    scored(stress)
                case .noReference:
                    empty(String(localized: "Sleep stress is measured against your heart rate while awake the day before. Wear your strap through the day to see it."))
                case .noHeartRate:
                    empty(String(localized: "There was too little heart rate during this night to measure its stress."))
                }
            } else {
                PulseSkeletonBlock(height: 150)
                    .accessibilityLabel(String(localized: "Loading"))
            }
        }
    }

    @ViewBuilder
    private func scored(_ s: SleepStressSnapshot) -> some View {
        Text("\(Int((s.highPercent ?? 0).rounded()))%")
            .pulseText(.largeValue)
            .foregroundStyle(PulseTheme.textPrimary)
            .accessibilityLabel(String(localized: "High sleep stress \(Int((s.highPercent ?? 0).rounded())) percent"))
        PulseStressChart(points: s.points,
                         periods: [PulseChartPeriod(id: "sleep", start: s.sleepStart, end: s.sleepEnd, kind: .sleep,
                                                    symbol: "moon.fill")],
                         now: s.chartEnd, currentLevel: s.lastLevel, xLabels: s.xLabels, height: 150)
        VStack(spacing: 16) {
            ForEach(s.levels) { level in
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        Text(level.title)
                            .pulseText(.cardTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Text(level.percentText)
                            .pulseText(.chipStrong)
                            .foregroundStyle(color(level.band))
                        Spacer(minLength: 8)
                        Text(level.durationText)
                            .pulseText(.rowValue)
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                    SleepShareBar(fraction: level.share, color: color(level.band))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(level.title), \(level.percentText), \(level.durationText)")
            }
        }
        .padding(.top, 8)
    }

    private func empty(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SleepEmptyFigure(text: "--%")
            Text(message)
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func color(_ band: SleepStress.Band) -> Color {
        switch band {
        case .low: return PulseTheme.Stress.low
        case .medium: return PulseTheme.Stress.medium
        case .high: return PulseTheme.Stress.high
        }
    }
}

// MARK: Empty cards (deep-dives-2026/01)

/// A detail card with no night behind it: the title and the dash.
struct PulseSleepEmptyCard: View {
    let title: String
    let dash: String
    var onInfo: () -> Void

    var body: some View {
        SleepDetailCard(title, onInfo: onInfo) {
            SleepEmptyFigure(text: dash)
        }
    }
}
#endif
