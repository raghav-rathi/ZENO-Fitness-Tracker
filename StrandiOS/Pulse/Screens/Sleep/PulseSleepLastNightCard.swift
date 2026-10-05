#if os(iOS)
import SwiftUI
import Charts
import StrandDesign

// MARK: - HOURS OF SLEEP (WHOOP_UI_SPEC §3.3 item 6)
//
// The first card of Last Night's Sleep, on the dimmer detail fill: hours asleep against the prior 30 nights,
// the night's heart rate (the dashed rules mark onset and wake; heart rate before and after them dimmer),
// TYPICAL RANGE / DURATION, the four stage rows with their typical-range boxes, then RESTORATIVE SLEEP and,
// for a night set by hand, SLEEP LATENCY. Tapping a stage's radio selects it: the chart picks out its
// stretches in its colour and every row turns into a barcode of when its stage happened; tapping it again
// deselects (deep-dives-2026/11).

struct PulseSleepLastNightCard: View {
    let night: SleepLastNight
    @Binding var selected: SleepStage?
    var onInfo: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PulseCard(.detail) {
            VStack(alignment: .leading, spacing: 0) {
                SleepCardHeader(title: String(localized: "Hours of sleep"), onInfo: onInfo)
                // Title caps to value caps 24 pt, as on the detail cards (deep-dives-2026/14, 15: 23.3–23.7).
                SleepFigureView(figure: night.hours)
                    .padding(.top, 7)

                PulseSleepHRChart(night: night, selected: selected)
                    .padding(.horizontal, -PulseTheme.Layout.cardPadding)
                    .padding(.top, 14)

                PulseDivider()
                    .padding(.top, 14)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HStack(spacing: 8) {
                        SleepTypicalLegendBox()
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 1 }
                        Text(String(localized: "Typical range"))
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textSecondary)
                    }
                    Spacer(minLength: 8)
                    Text(String(localized: "Duration"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textSecondary)
                    Text(night.durationText)
                        .sleepRowValue()
                        .foregroundStyle(PulseTheme.textPrimary)
                }
                .padding(.top, 16)
                .accessibilityElement(children: .combine)

                // 70 pt from stage row to stage row: 26 + 11 + 16 + 17 (deep-dives-2026/12).
                VStack(spacing: 17) {
                    ForEach(night.stages) { line in
                        PulseSleepStageRowView(line: line, selected: selected, selectable: night.hasTimeline) {
                            withAnimation(PulseMotion.resolved(PulseMotion.crossFade, reduceMotion: reduceMotion)) {
                                selected = selected == line.stage ? nil : line.stage
                            }
                        }
                    }
                }
                .padding(.top, 14)
                .id("pulse.stages")

                PulseDivider()
                    .padding(.top, 18)

                restorativeRow
                    .padding(.top, 14)

                if let latency = night.latency {
                    HStack(spacing: 10) {
                        SleepSwatch(color: PulseTheme.SleepDetail.latency)
                        Text(String(localized: "Sleep latency"))
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Spacer(minLength: 8)
                        Text(latency)
                            .sleepRowValue()
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                    .padding(.top, 18)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var restorativeRow: some View {
        HStack(alignment: .center, spacing: 10) {
            SleepRestorativeSwatch()
            Text(String(localized: "Restorative sleep"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 6) {
                    Text(night.restorative.value)
                        .sleepRowValue()
                        .foregroundStyle(PulseTheme.textPrimary)
                    if let trend = night.restorative.trend {
                        PulseTrendGlyph(trend: trend)
                    }
                }
                if let baseline = night.restorative.baseline {
                    Text(baseline)
                        .pulseText(.baseline)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(night.restorative.spoken)
    }
}

// MARK: - Stage row (§2.6 item 19)

/// A stage row: a 26 pt radio, the UPPERCASE stage name, its share in the stage colour and the duration at
/// the right; under it the share as a bar on the hatched track with the typical-range box, or, once a stage
/// is selected, the barcode of when this row's stage happened (the selected one in its colour).
struct PulseSleepStageRowView: View {
    let line: SleepStageLine
    let selected: SleepStage?
    let selectable: Bool
    let onTap: () -> Void

    private var isSelected: Bool { selected == line.stage }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 10) {
                    radio
                    Text(line.title)
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(line.percentText)
                        .pulseText(.chipStrong)
                        .foregroundStyle(selected == nil || isSelected ? line.stage.pulseColor : PulseTheme.textTertiary)
                    Spacer(minLength: 8)
                    Text(line.durationText)
                        .sleepRowValue()
                        .foregroundStyle(PulseTheme.textPrimary)
                }
                if selected == nil {
                    SleepShareBar(fraction: line.share, color: line.stage.pulseColor, typical: line.typical,
                                  height: 16)
                } else {
                    SleepBarcode(segments: line.segments,
                                 color: isSelected ? line.stage.pulseColor : PulseTheme.textTertiary, height: 16)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!selectable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(line.title), \(line.percentText), \(line.durationText)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : (selectable ? .isButton : []))
        .accessibilityHint(selectable ? String(localized: "Shows when this stage happened") : "")
    }

    private var radio: some View {
        ZStack {
            if isSelected {
                Circle().fill(Color.white)
                Circle().fill(Color.black).frame(width: 7, height: 7)
            } else {
                Circle().strokeBorder(Color.white, lineWidth: 1.5)
            }
        }
        .frame(width: PulseTheme.SleepDive.stageRadio, height: PulseTheme.SleepDive.stageRadio)
        .opacity(selectable ? 1 : 0.4)
        .accessibilityHidden(true)
    }
}

// MARK: - The night's heart rate (§2.7 "HR area")

/// The night's heart rate edge to edge across the card: a 1.5 pt sleep-blue line over a soft gradient,
/// dimmer before onset and after wake, dashed rules with a dot at their foot at onset and wake, the onset and
/// wake times under the rules, and y labels (30 / 50 / 70 / 90 …) drawn inside the plot at the left. With a
/// stage selected, that stage's stretches get a translucent band in its colour and the line through them
/// takes the colour; the rest of the line greys out.
struct PulseSleepHRChart: View {
    let night: SleepLastNight
    let selected: SleepStage?
    var height: CGFloat = 150

    /// Consecutive points sharing a run, a side of the window and (with a selection) whether they fall in
    /// the selected stage: each is drawn as its own series, sharing its boundary point with the next so the
    /// line never breaks where its colour changes.
    private struct Piece: Identifiable {
        let id: Int
        let points: [SleepHRPoint]
        let inWindow: Bool
        let highlighted: Bool
    }

    private func inWindow(_ d: Date) -> Bool { d >= night.onset && d <= night.wake }

    private func inSelected(_ d: Date) -> Bool {
        guard let selected else { return false }
        return night.spans.contains { $0.stage == selected && d >= $0.start && d <= $0.end }
    }

    private struct PieceKey: Equatable {
        let run: String
        let inWindow: Bool
        let highlighted: Bool
    }

    private var pieces: [Piece] {
        var out: [Piece] = []
        var current: [SleepHRPoint] = []
        var currentKey: PieceKey?
        for p in night.hr {
            let k = PieceKey(run: p.run, inWindow: inWindow(p.date), highlighted: inSelected(p.date))
            if let ck = currentKey, ck != k {
                // A new colour on the same run ends this piece ON the new point, so the line stays joined;
                // a new run (a wear gap) leaves the gap.
                if ck.run == k.run { current.append(p) }
                out.append(Piece(id: out.count, points: current, inWindow: ck.inWindow, highlighted: ck.highlighted))
                current = [p]
            } else {
                current.append(p)
            }
            currentKey = k
        }
        if let ck = currentKey, !current.isEmpty {
            out.append(Piece(id: out.count, points: current, inWindow: ck.inWindow, highlighted: ck.highlighted))
        }
        return out
    }

    private func lineColor(_ piece: Piece) -> Color {
        if let selected {
            return piece.highlighted ? selected.pulseColor : PulseTheme.textTertiary.opacity(piece.inWindow ? 1 : 0.6)
        }
        return PulseTheme.sleep.opacity(piece.inWindow ? 1 : 0.45)
    }

    private var span: TimeInterval { max(night.chartEnd.timeIntervalSince(night.chartStart), 1) }

    private func fraction(_ d: Date) -> CGFloat {
        CGFloat(max(0, min(1, d.timeIntervalSince(night.chartStart) / span)))
    }

    var body: some View {
        let domain = night.yDomain
        VStack(spacing: 6) {
            Chart {
                if let selected {
                    ForEach(Array(night.spans.filter { $0.stage == selected }.enumerated()), id: \.offset) { _, s in
                        RectangleMark(xStart: .value("Start", s.start), xEnd: .value("End", s.end),
                                      yStart: .value("Low", domain.lowerBound), yEnd: .value("High", domain.upperBound))
                            .foregroundStyle(selected.pulseColor.opacity(0.16))
                    }
                }
                ForEach(pieces) { piece in
                    ForEach(piece.points) { p in
                        AreaMark(x: .value("Time", p.date), yStart: .value("Base", domain.lowerBound),
                                 yEnd: .value("BPM", p.bpm), series: .value("Piece", piece.id))
                            .foregroundStyle(LinearGradient(colors: [PulseTheme.sleep.opacity(selected == nil ? 0.28 : 0.10),
                                                                     PulseTheme.sleep.opacity(0)],
                                                            startPoint: .top, endPoint: .bottom))
                            .opacity(piece.inWindow ? 1 : 0.4)
                        LineMark(x: .value("Time", p.date), y: .value("BPM", p.bpm), series: .value("Piece", piece.id))
                            .foregroundStyle(lineColor(piece))
                            .lineStyle(StrokeStyle(lineWidth: piece.highlighted ? 1.6 : 1.3, lineCap: .round,
                                                   lineJoin: .round))
                    }
                }
                ForEach([night.onset, night.wake], id: \.self) { edge in
                    RuleMark(x: .value("Edge", edge))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(x: .value("Edge", edge), y: .value("Foot", domain.lowerBound))
                        .symbolSize(18)
                        .foregroundStyle(PulseTheme.textPrimary)
                }
            }
            .chartXScale(domain: night.chartStart...night.chartEnd)
            .chartYScale(domain: domain)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    ForEach(night.yValues, id: \.self) { value in
                        if let y = proxy.position(forY: value), let plot = proxy.plotFrame {
                            Text("\(Int(value))")
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textTertiary)
                                .position(x: geo[plot].minX + 22, y: geo[plot].minY + y)
                        }
                    }
                }
            }
            .frame(height: height)

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .topLeading) {
                    edgeLabel(night.onsetLabel)
                        .fixedSize()
                        .offset(x: min(max(0, fraction(night.onset) * w - 4), w * 0.5))
                    edgeLabel(night.wakeLabel)
                        .fixedSize()
                        .frame(width: w, alignment: .trailing)
                        .offset(x: -(w - min(w, fraction(night.wake) * w + 4)))
                }
            }
            .frame(height: 16)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart rate through the night"))
        .accessibilityValue(summary)
    }

    private func edgeLabel(_ text: String) -> some View {
        Text(text)
            .font(PulseType.font(.secondary))
            .fontWeight(.bold)
            .fontWidth(.condensed)
            .foregroundStyle(PulseTheme.textPrimary)
    }

    private var summary: String {
        let inside = night.hr.filter { inWindow($0.date) }.map(\.bpm)
        guard let lo = inside.min(), let hi = inside.max() else { return String(localized: "No heart rate") }
        return String(localized: "\(night.onsetLabel) to \(night.wakeLabel), \(Int(lo.rounded())) to \(Int(hi.rounded())) beats per minute")
    }
}
#endif
