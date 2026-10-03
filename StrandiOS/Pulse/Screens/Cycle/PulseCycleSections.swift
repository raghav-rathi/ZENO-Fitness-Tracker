#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Menstrual Cycle Insights sections (WHOOP_UI_SPEC §3.24 items 6–13)

/// POSSIBLE SYMPTOMS TODAY › with outline chips, or its empty state (a dot cluster, "Your symptom predictions
/// will appear here", a grey line and a full-width button). The chips follow help-center/10: ≈24 pt rounded
/// rectangles with a 1 pt grey outline and ≈12 pt text at ≈74% white, 8 pt apart.
struct PulseCycleSymptomsTodayCard: View {
    let state: CycleInsightsSnapshot.SymptomsToday
    let onLog: () -> Void

    var body: some View {
        switch state {
        case .predictions(let titles):
            Button(action: onLog) {
                PulseCard {
                    VStack(alignment: .leading, spacing: 14) {
                        PulseCardTitle(String(localized: "Possible symptoms today"), accessory: .trailingChevron)
                        PulseWordFlow(alignment: .leading, spacing: 8, lineSpacing: 8) {
                            ForEach(titles, id: \.self) { title in
                                Text(title)
                                    .fontWeight(.medium)
                                    .pulseText(.legend)
                                    .foregroundStyle(PulseTheme.textSecondary)
                                    .lineLimit(1)
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 24)
                                    .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                                        .strokeBorder(PulseTheme.outlinedBorder, lineWidth: 1))
                            }
                        }
                    }
                }
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint(String(localized: "Opens today's log"))
        case .nothingExpected:
            PulseCard {
                VStack(alignment: .leading, spacing: 10) {
                    PulseCardTitle(String(localized: "Possible symptoms today"))
                    Text(String(localized: "Nothing stands out for this point in your cycle from your previous cycles."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        case .notYet:
            PulseCard {
                VStack(spacing: 0) {
                    PulseCycleDotCluster()
                        .frame(width: 64, height: 56)
                        .padding(.top, 8)
                    Text(String(localized: "Your symptom predictions will appear here"))
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                    Text(String(localized: "Log your symptoms and periods regularly to start seeing predictions of the symptoms you might experience each day."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                    Button(action: onLog) {
                        Label(String(localized: "Log symptoms"), systemImage: "plus")
                    }
                    .buttonStyle(.pulseNested)
                    .padding(.top, 18)
                }
                .frame(maxWidth: .infinity)
            }
        case .unavailable:
            EmptyView()
        }
    }
}

/// A small cluster of dots (ZENO's own mark for "patterns appear here"; no WHOOP art).
struct PulseCycleDotCluster: View {
    var body: some View {
        Canvas { context, size in
            let dots: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (0.50, 0.50, 7, 0.9), (0.24, 0.40, 5, 0.55), (0.76, 0.30, 6, 0.7), (0.70, 0.74, 5, 0.5),
                (0.33, 0.78, 4, 0.4), (0.12, 0.66, 3, 0.3), (0.90, 0.56, 3, 0.35), (0.46, 0.14, 3.5, 0.45),
            ]
            for (x, y, r, a) in dots {
                let rect = CGRect(x: x * size.width - r, y: y * size.height - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(PulseTheme.textPrimary.opacity(a)))
            }
            var ring = Path()
            ring.addEllipse(in: CGRect(x: size.width * 0.5 - 18, y: size.height * 0.5 - 18, width: 36, height: 36))
            context.stroke(ring, with: .color(PulseTheme.textPrimary.opacity(0.18)),
                           style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        }
        .accessibilityHidden(true)
    }
}

/// "Cycle Journal" (health-more-2026/07): today's Symptoms and Period rows, Title Case with no leading icon,
/// each with a white "+" that opens the log sheet.
struct PulseCycleJournalCard: View {
    let journal: CycleInsightsSnapshot.Journal
    let onLogPeriod: () -> Void
    let onLogSymptoms: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(title: String(localized: "Symptoms"),
                detail: journal.symptoms.isEmpty ? String(localized: "Nothing logged today")
                                                 : journal.symptoms.joined(separator: ", "),
                action: onLogSymptoms)
            PulseDivider(leadingInset: 16, trailingInset: 16)
            row(title: String(localized: "Period"),
                detail: journal.flow ?? String(localized: "Nothing logged today"), action: onLogPeriod)
        }
        .pulseCardBackground()
    }

    private func row(title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .pulseText(.rowText)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(detail)
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.white))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Opens today's log"))
    }
}

/// <PHASE> PHASE COACHING (§3.24 item 8; health-more-2026/07, whoop-site/78): the M | F | O | L columns
/// (≈144 pt tall, widths by the wearer's phase lengths, the current one outlined in white on its phase
/// tint, its letter in the phase colour) with ZENO's own textbook hormone curves running through them and
/// coloured in the current column; the paragraph; then SLEEP EFFICIENCY | STRAIN | STRESS, each the wearer's
/// own phase mean against their cycle mean. At the accessibility sizes the three stack as full-width rows.
struct PulseCycleCoachingCard: View {
    let coaching: CycleInsightsSnapshot.Coaching

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 0) {
                PulseCardTitle(String(localized: "\(PulseCycleText.phaseName(coaching.phase)) phase coaching"))
                PulseCyclePhaseColumns(bar: coaching.bar, current: coaching.phase)
                    .frame(height: 144)
                    .padding(.top, 14)
                Text(coaching.paragraph)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                PulseDivider()
                    .padding(.top, 16)
                metrics
                    .padding(.top, 16)
            }
        }
    }

    @ViewBuilder
    private var metrics: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(coaching.metrics.enumerated()), id: \.element.id) { index, metric in
                    if index > 0 { PulseDivider().padding(.vertical, 12) }
                    metricRow(metric)
                }
            }
        } else {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(coaching.metrics.enumerated()), id: \.element.id) { index, metric in
                    if index > 0 {
                        Rectangle().fill(PulseTheme.divider).frame(width: 1).padding(.vertical, 2)
                    }
                    metricColumn(metric)
                        .padding(.leading, index == 0 ? 0 : 12)
                        .padding(.trailing, index == coaching.metrics.count - 1 ? 0 : 8)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func metricColumn(_ metric: CycleInsightsSnapshot.Coaching.Metric) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            icon(metric)
            PulseWordWrapText(metric.title, style: .label)
                .foregroundStyle(PulseTheme.textPrimary)
            chip(metric)
            Text(metric.detail)
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// One metric across the card: the icon and title over the detail, the chip at the right.
    private func metricRow(_ metric: CycleInsightsSnapshot.Coaching.Metric) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                icon(metric)
                PulseWordWrapText(metric.title, style: .label)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer(minLength: 8)
                chip(metric)
            }
            Text(metric.detail)
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func icon(_ metric: CycleInsightsSnapshot.Coaching.Metric) -> some View {
        Image(systemName: metric.symbol)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(PulseTheme.textTertiary)
            .frame(height: 20, alignment: .leading)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func chip(_ metric: CycleInsightsSnapshot.Coaching.Metric) -> some View {
        Group {
            switch metric.kind {
            case .positive: PulseStatusChip(metric.chip, kind: .positive)
            case .negative: PulseStatusChip(metric.chip, kind: .negative)
            case .neutral: PulseStatusChip(metric.chip, kind: .neutral)
            case .calibrating:
                Text(metric.chip)
                    .pulseText(.chip)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                        .strokeBorder(PulseTheme.outlinedBorder, lineWidth: 1))
            }
        }
        .lineLimit(1)
        .fixedSize()
    }
}

/// The M | F | O | L columns with three textbook hormone curves (estrogen solid, progesterone dashed, FSH
/// dotted) drawn across them: grey, and in the current phase's colour inside its column. An illustration of
/// the textbook cycle, never the wearer's data, and ZENO's own drawing (no WHOOP art).
struct PulseCyclePhaseColumns: View {
    let bar: [CycleInsightsSnapshot.Coaching.Segment]
    let current: PulseCyclePhase

    private static let gap: CGFloat = 6
    private static let minWidth: CGFloat = 34
    /// Where each phase sits in the textbook curves' 0…1 cycle.
    private static let span: [PulseCyclePhase: ClosedRange<Double>] = [
        .menstrual: 0...0.18, .follicular: 0.18...0.46, .ovulatory: 0.46...0.54, .luteal: 0.54...1,
    ]

    var body: some View {
        GeometryReader { geo in
            let frames = columnFrames(width: geo.size.width, height: geo.size.height)
            ZStack(alignment: .topLeading) {
                ForEach(Array(bar.enumerated()), id: \.element.id) { index, segment in
                    let isCurrent = segment.phase == current
                    let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    shape.fill(isCurrent ? segment.phase.band.opacity(0.35) : PulseTheme.nested)
                        .overlay(shape.strokeBorder(isCurrent ? PulseTheme.textPrimary : Color.clear, lineWidth: 1.5))
                        .frame(width: frames[index].width, height: frames[index].height)
                        .offset(x: frames[index].minX)
                    Text(PulseCycleText.letter(segment.phase))
                        .pulseText(.label)
                        .foregroundStyle(isCurrent ? segment.phase.dot : PulseTheme.textTertiary)
                        .frame(width: frames[index].width)
                        .offset(x: frames[index].minX, y: 10)
                }
                curves(frames: frames, size: geo.size, color: PulseTheme.textPrimary.opacity(0.28))
                if let index = bar.firstIndex(where: { $0.phase == current }) {
                    curves(frames: frames, size: geo.size, color: current.dot)
                        .mask(alignment: .topLeading) {
                            Rectangle()
                                .frame(width: frames[index].width, height: frames[index].height)
                                .offset(x: frames[index].minX)
                        }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bar.map { segment in
            let text = String(localized: "\(PulseCycleText.phaseName(segment.phase)) \(segment.days) days")
            return segment.phase == current ? text + ", " + String(localized: "current") : text
        }.joined(separator: ", "))
    }

    /// Each column's rectangle: widths by phase length over a 34 pt minimum, 6 pt apart.
    private func columnFrames(width: CGFloat, height: CGFloat) -> [CGRect] {
        let total = max(1, bar.reduce(0) { $0 + $1.days })
        let spare = max(0, width - Self.gap * CGFloat(max(0, bar.count - 1)) - Self.minWidth * CGFloat(bar.count))
        var x: CGFloat = 0
        return bar.map { segment in
            let w = Self.minWidth + spare * CGFloat(segment.days) / CGFloat(total)
            defer { x += w + Self.gap }
            return CGRect(x: x, y: 0, width: w, height: height)
        }
    }

    private func curves(frames: [CGRect], size: CGSize, color: Color) -> some View {
        ZStack {
            curvePath(frames: frames, size: size, value: Self.estrogen)
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            curvePath(frames: frames, size: size, value: Self.progesterone)
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 4]))
            curvePath(frames: frames, size: size, value: Self.fsh)
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 4]))
        }
        .allowsHitTesting(false)
    }

    /// A curve through the columns: each phase's part of the textbook cycle drawn across its own column.
    private func curvePath(frames: [CGRect], size: CGSize, value: (Double) -> Double) -> Path {
        let top = size.height * 0.36, bottom = size.height - 12
        var path = Path()
        for (index, segment) in bar.enumerated() {
            guard let range = Self.span[segment.phase] else { continue }
            let frame = frames[index]
            let steps = 24
            for step in 0...steps {
                let f = Double(step) / Double(steps)
                let t = range.lowerBound + (range.upperBound - range.lowerBound) * f
                let point = CGPoint(x: frame.minX + frame.width * f,
                                    y: bottom - (bottom - top) * value(t))
                if path.isEmpty { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
        return path
    }

    /// Textbook estrogen: low in the period, a peak just before ovulation, a smaller rise mid-luteal.
    private static func estrogen(_ t: Double) -> Double {
        0.12 + 0.8 * exp(-pow((t - 0.44) / 0.07, 2)) + 0.38 * exp(-pow((t - 0.73) / 0.11, 2))
    }

    /// Textbook progesterone: flat until ovulation, one broad luteal hump.
    private static func progesterone(_ t: Double) -> Double {
        0.06 + 0.78 * exp(-pow((t - 0.75) / 0.12, 2))
    }

    /// Textbook FSH: raised as a cycle begins, a brief peak with ovulation, low through the luteal phase.
    private static func fsh(_ t: Double) -> Double {
        0.1 + 0.3 * exp(-pow((t - 0.07) / 0.1, 2)) + 0.32 * exp(-pow((t - 0.47) / 0.035, 2))
    }
}

/// "Your Cycle Patterns": YOUR TYPICAL CYCLE (three values) and CYCLE HISTORY (the current cycle and the past
/// ones, each with its strip of phase dots), as §3.24 and health-more-2026/07 name them.
struct PulseCyclePatternsSection: View {
    let patterns: CycleInsightsSnapshot.Patterns

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.gridGap) {
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    PulseCardTitle(String(localized: "Your typical cycle"))
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(patterns.typical) { stat in
                            VStack(alignment: .leading, spacing: 6) {
                                PulseWordWrapText(stat.title, style: .label)
                                    .foregroundStyle(PulseTheme.textTertiary)
                                Spacer(minLength: 0)
                                PulseValueText(value: stat.value, unit: stat.value == "--" ? nil : stat.unit,
                                               style: .tileValue)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    if let note = patterns.footnote {
                        Text(note)
                            .pulseText(.legend)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if !patterns.cycles.isEmpty {
                PulseCard {
                    VStack(alignment: .leading, spacing: 0) {
                        PulseCardTitle(String(localized: "Cycle history"))
                        ForEach(Array(patterns.cycles.enumerated()), id: \.element.id) { index, row in
                            if index > 0 { PulseDivider().padding(.vertical, 12) }
                            cycleRow(row)
                                .padding(.top, index == 0 ? 14 : 0)
                        }
                    }
                }
            }
        }
    }

    private func cycleRow(_ row: CycleInsightsSnapshot.Patterns.CycleRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.title)
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(row.range)
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textTertiary)
            PulseCyclePatternDotStrip(dots: row.dots)
                .frame(height: 8)
                .padding(.top, 6)
            if let note = row.note {
                Text(note)
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.top, 2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// One dot per cycle day in its phase colour; days still to come dimmed, days without a phase grey.
struct PulseCyclePatternDotStrip: View {
    let dots: [CycleInsightsSnapshot.Patterns.Dot]

    var body: some View {
        Canvas { context, size in
            guard !dots.isEmpty else { return }
            let pitch = min(9, size.width / CGFloat(dots.count))
            let d = max(3, pitch - 2.5)
            for (i, dot) in dots.enumerated() {
                let color: Color = dot.isPeriod ? PulseCyclePhase.menstrual.dot
                    : (dot.phase?.dot ?? PulseTheme.textPrimary.opacity(0.25))
                let rect = CGRect(x: CGFloat(i) * pitch, y: (size.height - d) / 2, width: d, height: d)
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(dot.isFuture ? 0.35 : 1)))
            }
        }
        .accessibilityHidden(true)
    }
}

/// YOUR SYMPTOMS: the most-logged symptoms in the last six months, or "Start uncovering patterns".
struct PulseCycleSymptomSummaryCard: View {
    let rows: [CycleInsightsSnapshot.SymptomRow]
    let onLog: () -> Void

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 0) {
                PulseCardTitle(String(localized: "Your symptoms"))
                if rows.isEmpty {
                    VStack(spacing: 0) {
                        PulseCycleDotCluster()
                            .frame(width: 64, height: 56)
                        Text(String(localized: "Start uncovering patterns"))
                            .pulseText(.coachingTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .padding(.top, 14)
                        Text(String(localized: "Keep logging your symptoms to see which ones come up most, and when in your cycle."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                } else {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 { PulseDivider() }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.title)
                                .pulseText(.rowText)
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text(row.detail)
                                .pulseText(.rowSubline)
                                .foregroundStyle(PulseTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                        .accessibilityElement(children: .combine)
                    }
                    .padding(.top, 6)
                }
                Button(action: onLog) {
                    Label(String(localized: "Log symptoms"), systemImage: "plus")
                }
                .buttonStyle(.pulseNested)
                .padding(.top, 16)
            }
        }
    }
}

/// The disclaimer card (health-more-2026/11): "Important Note" and "Medical Disclaimer" on the dimmer card,
/// 15 pt Semibold titles over 13 pt bodies with 20 pt padding, as WHOOP sets them. (Where the logs are kept is
/// said on the setup page and in Hormonal Insights settings, not here.)
struct PulseCycleDisclaimerCard: View {
    var body: some View {
        PulseCard(.detail, padding: 20) {
            VStack(alignment: .leading, spacing: 0) {
                block(title: String(localized: "Important Note"),
                      body: String(localized: "Menstrual Cycle Insights should not be used for birth control or fertility tracking. The ovulatory phase indicators are estimates only."))
                PulseDivider()
                    .padding(.vertical, 16)
                block(title: String(localized: "Medical Disclaimer"),
                      body: String(localized: "Menstrual Cycle Insights is not a medical device and cannot diagnose or manage medical conditions. It does not provide medical advice. Always consult your doctor for health concerns and never delay or modify medical care based on its information."))
            }
        }
    }

    private func block(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(body)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
