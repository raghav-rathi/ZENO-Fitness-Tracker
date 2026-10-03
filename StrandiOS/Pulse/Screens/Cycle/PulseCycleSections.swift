#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Menstrual Cycle Insights sections (WHOOP_UI_SPEC §3.24 items 6–13)

/// POSSIBLE SYMPTOMS TODAY › with outline chips, or its empty state (a dot cluster, "Your symptom predictions
/// will appear here", a grey line and a full-width button).
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
                                    .pulseText(.rowText)
                                    .foregroundStyle(PulseTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 32)
                                    .overlay(Capsule(style: .circular).strokeBorder(PulseTheme.outlinedBorder, lineWidth: 1))
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

/// "Cycle Journal": today's Period and Symptoms rows, each with a white "+" that opens the log sheet.
struct PulseCycleJournalCard: View {
    let journal: CycleInsightsSnapshot.Journal
    let onLogPeriod: () -> Void
    let onLogSymptoms: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(title: String(localized: "Period"), symbol: "drop",
                detail: journal.flow ?? String(localized: "Nothing logged today"), action: onLogPeriod)
            PulseDivider(leadingInset: 16, trailingInset: 16)
            row(title: String(localized: "Symptoms"), symbol: "list.bullet.circle",
                detail: journal.symptoms.isEmpty ? String(localized: "Nothing logged today")
                                                 : journal.symptoms.joined(separator: ", "),
                action: onLogSymptoms)
        }
        .pulseCardBackground()
    }

    private func row(title: String, symbol: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .pulseText(.cardTitle)
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

/// <PHASE> PHASE COACHING: the M | F | O | L bar (widths by phase length, the current one outlined), the
/// paragraph, and how the wearer's own Recovery, HRV and resting heart rate run in this phase.
struct PulseCycleCoachingCard: View {
    let coaching: CycleInsightsSnapshot.Coaching

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 0) {
                PulseCardTitle(String(localized: "\(PulseCycleText.phaseName(coaching.phase)) phase coaching"))
                phaseBar
                    .padding(.top, 14)
                Text(coaching.paragraph)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                PulseDivider()
                    .padding(.top, 16)
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
                .padding(.top, 16)
            }
        }
    }

    private var phaseBar: some View {
        GeometryReader { geo in
            let gap: CGFloat = 6
            let minWidth: CGFloat = 34
            let total = max(1, coaching.bar.reduce(0) { $0 + $1.days })
            let spare = max(0, geo.size.width - gap * CGFloat(coaching.bar.count - 1) - minWidth * CGFloat(coaching.bar.count))
            HStack(spacing: gap) {
                ForEach(coaching.bar) { segment in
                    let current = segment.phase == coaching.phase
                    let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                    VStack(spacing: 4) {
                        Text(PulseCycleText.letter(segment.phase))
                            .pulseText(.label)
                            .foregroundStyle(current ? segment.phase.dot : PulseTheme.textTertiary)
                        if current {
                            Text(String(localized: "\(segment.days)d"))
                                .font(PulseType.numeral(13))
                                .foregroundStyle(PulseTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 8)
                    .frame(width: minWidth + spare * CGFloat(segment.days) / CGFloat(total))
                    .frame(maxHeight: .infinity)
                    .background(shape.fill(current ? segment.phase.band.opacity(0.35) : PulseTheme.nested))
                    .overlay(shape.strokeBorder(current ? Color.white : Color.clear, lineWidth: 1.5))
                }
            }
        }
        .frame(height: 64)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(coaching.bar.map { "\(PulseCycleText.phaseName($0.phase)) \($0.days) days" }
            .joined(separator: ", "))
    }

    private func metricColumn(_ metric: CycleInsightsSnapshot.Coaching.Metric) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: metric.symbol)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .accessibilityHidden(true)
            Text(metric.title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            chip(metric)
            Text(metric.detail)
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func chip(_ metric: CycleInsightsSnapshot.Coaching.Metric) -> some View {
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
}

/// "Your Cycle Patterns": YOUR TYPICAL CYCLE (three values) and YOUR CYCLES (the current cycle and the past
/// ones, each with its strip of phase dots).
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
                                Text(stat.title)
                                    .pulseText(.label)
                                    .foregroundStyle(PulseTheme.textTertiary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
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
                        PulseCardTitle(String(localized: "Your cycles"))
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
            PulseCycleDotStrip(dots: row.dots)
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
struct PulseCycleDotStrip: View {
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

/// The disclaimer card (health-more-2026/11): "Important Note" and "Medical Disclaimer" on the dimmer card.
struct PulseCycleDisclaimerCard: View {
    var body: some View {
        PulseCard(.detail, padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                block(title: String(localized: "Important Note"),
                      body: String(localized: "Menstrual Cycle Insights should not be used for birth control or fertility tracking. The ovulatory phase indicators are estimates only."))
                PulseDivider()
                    .padding(.vertical, 18)
                block(title: String(localized: "Medical Disclaimer"),
                      body: String(localized: "Menstrual Cycle Insights is not a medical device and cannot diagnose or manage medical conditions. It does not provide medical advice. Always consult your doctor for health concerns and never delay or modify medical care based on its information."))
                PulseDivider()
                    .padding(.vertical, 18)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                        .accessibilityHidden(true)
                    Text(String(localized: "Your cycle logs stay on this iPhone unless you export a backup yourself."))
                        .pulseText(.rowSubline)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func block(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(body)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
