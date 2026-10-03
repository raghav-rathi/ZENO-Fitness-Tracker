#if os(iOS)
import SwiftUI
import Charts
import StrandAnalytics

/// Healthspan (WHOOP_UI_SPEC §3.23), pushed from the Health tab's orb and Pace card: "HEALTHSPAN" over
/// when the week closes, its own week pager, the ZENO Age orb (≈300 pt), the Pace of Aging ruler with the
/// notched insight under its needle, the pillars (Sleep · Strain · Fitness) as rows of range bars with the
/// years each adds or takes off, the VO₂ max card, and the ZENO AGE and PACE OF AGING trends. A compact
/// header pins once the orb scrolls away. Locked: the dormant orb and "UNLOCK ZENO AGE · N of 21 nights".
///
/// ZENO Age is the VitalityEngine Body Age; Pace of Aging is `PaceOfAging` over its weekly values; a
/// row's years are that factor's log-hazard through `VitalityEngine.years(for:)`.
struct PulseHealthspanView: View {
    /// Rebuilt: existing entry points open this instead of the classic Health screen.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseCoach) private var coach
    @EnvironmentObject private var profile: ProfileStore

    /// The week shown; nil is the newest.
    @State private var weekKey: String?
    @State private var snapshot: HealthspanSnapshot?
    @State private var showsInfo = false
    @State private var expanded: Set<String> = []
    @State private var orbPassed = false
    @State private var trendSpan: TrendSpan = .sixMonths

    enum TrendSpan: String, CaseIterable, Hashable { case month, sixMonths }

    private var shown: HealthspanSnapshot? {
        guard let snapshot else { return nil }
        if let weekKey, snapshot.summary?.week.id != weekKey { return nil }
        return snapshot
    }

    var body: some View {
        PulseScreenScaffold(coach: .button, coachSeed: coachSeed, background: .nearBlack, showsNavigationBar: false,
                            spacing: 0, topPadding: 0, ready: shown != nil) {
            PulseLoadingGate(isLoading: shown == nil) {
                if let s = shown {
                    content(s)
                }
            } skeleton: {
                VStack(spacing: 24) {
                    Circle()
                        .strokeBorder(PulseTheme.skeleton, lineWidth: 12)
                        .frame(width: 280, height: 280)
                        .frame(maxWidth: .infinity)
                    PulseSkeleton.cards([80, 120, 200])
                }
                .padding(.top, 48)
            }
        }
        .overlay(alignment: .top) {
            if orbPassed, let s = shown, let summary = s.summary {
                HealthspanCompactHeader(summary: summary)
                    .transition(.opacity)
            }
        }
        .animation(PulseMotion.chrome, value: orbPassed)
        .healthNavHeader(String(localized: "Healthspan"), subtitle: subtitle,
                         trailing: .info { showsInfo = true })
        .task(id: "\(model.healthKey)|\(weekKey ?? "latest")") {
            let dob = profile.dateOfBirth
            let key = weekKey
            if let s = await model.build(dayOffset: 0, { builder, request in
                await builder.healthspan(request, weekKey: key, dateOfBirth: dob)
            }) {
                if snapshot != s { snapshot = s }
            }
        }
        .sheet(isPresented: $showsInfo) {
            HealthInfoSheet(title: String(localized: "How ZENO Age works"), paragraphs: Self.infoParagraphs)
        }
    }

    /// "FINAL IN 3 DAYS" while the week is still being scored (the weekly pass refines it daily).
    private var subtitle: String? {
        guard let s = shown, s.summary != nil, s.isCurrentWeek else { return nil }
        switch s.daysLeftInWeek {
        case 0: return String(localized: "Final today")
        case 1: return String(localized: "Final tomorrow")
        default: return String(localized: "Final in \(s.daysLeftInWeek) days")
        }
    }

    @ViewBuilder
    private func content(_ s: HealthspanSnapshot) -> some View {
        if let summary = s.summary {
            ready(s, summary: summary)
        } else if let unlock = s.unlock {
            VStack(alignment: .leading, spacing: 24) {
                HealthUnlockHero(nights: unlock.nights, needed: unlock.needed)
                    .padding(.top, 24)
                Text(String(localized: "ZENO Age reads your sleep, resting heart rate, heart rate variability and steps against published links to long-term health. It needs a few weeks of nights to read them honestly, so it unlocks after 21 nights of sleep in a month."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HealthDisclaimer(text: Self.disclaimer)
            }
        }
    }

    @ViewBuilder
    private func ready(_ s: HealthspanSnapshot, summary: HealthAgeSummary) -> some View {
        let index = s.weeks.firstIndex { $0.id == summary.week.id }
        VStack(alignment: .leading, spacing: 0) {
            HealthPager(title: weekTitle(summary.week.id),
                        canGoBack: (index ?? 0) > 0,
                        canGoForward: index.map { $0 < s.weeks.count - 1 } ?? false,
                        onBack: { if let i = index, i > 0 { weekKey = s.weeks[i - 1].id } },
                        onForward: {
                            if let i = index, i < s.weeks.count - 1 {
                                weekKey = i + 1 == s.weeks.count - 1 ? nil : s.weeks[i + 1].id
                            }
                        })
                .padding(.top, 2)

            HealthAgeOrb(hue: summary.week.hue, diameter: 300) {
                HealthOrbReading(age: PulseFormat.oneDecimal(summary.week.zenoAge),
                                 yearsLine: healthYearsLine(summary.week.yearsYounger), hue: summary.week.hue)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
            .pulseScrolledPast($orbPassed, threshold: 150)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "ZENO Age \(PulseFormat.oneDecimal(summary.week.zenoAge)), \(healthYearsLine(summary.week.yearsYounger))"))

            VStack(alignment: .leading, spacing: 10) {
                PulseCardTitle(String(localized: "Pace of Aging"))
                HealthPaceRuler(pace: summary.pace)
            }
            .padding(.top, 34)

            if let insight = s.insight {
                insightCard(insight, pace: summary.pace)
                    .padding(.top, 14)
            }

            ForEach(s.pillars) { pillar in
                if !pillar.rows.isEmpty || pillar.id == "fitness" {
                    pillarSection(pillar, s: s)
                        .id("pulse.\(pillar.id)")
                        .padding(.top, 40)
                }
            }

            trends(s, current: summary)
                .id("pulse.trend")
                .padding(.top, 40)

            HealthDisclaimer(text: Self.disclaimer)
                .padding(.top, 32)
        }
    }

    // MARK: Insight

    private func insightCard(_ insight: HealthspanSnapshot.Insight, pace: Double?) -> some View {
        PulseCallout(notchPosition: CGFloat(pace.map(PaceOfAging.rulerFraction) ?? 0.5)) {
            VStack(alignment: .leading, spacing: 10) {
                Text(insight.title)
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(insight.body)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if coach.availability != .off {
                    PulseTextCTA(title: String(localized: "View your coach analysis"), tint: .ai) {
                        coach.open(String(localized: "Healthspan: \(insight.title). \(insight.body)"))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Pillars

    private func pillarSection(_ pillar: HealthspanPillar, s: HealthspanSnapshot) -> some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(pillar.title)
                    .pulseText(.sectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                HealthspanLegend()
            }
            if pillar.id == "fitness" {
                HealthVO2MaxCard(state: s.vo2)
            }
            if !pillar.rows.isEmpty {
                PulseCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(pillar.rows.enumerated()), id: \.element.id) { i, row in
                            HealthspanRowView(row: row, expanded: expanded.contains(row.id)) {
                                if expanded.contains(row.id) { expanded.remove(row.id) } else { expanded.insert(row.id) }
                            }
                            if i < pillar.rows.count - 1 { PulseDivider(leadingInset: 16, trailingInset: 16) }
                        }
                    }
                }
            }
        }
    }

    // MARK: Trends

    private func trends(_ s: HealthspanSnapshot, current: HealthAgeSummary) -> some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            HealthSectionHeader(title: String(localized: "Trend View"))
            PulseCard {
                VStack(alignment: .leading, spacing: 16) {
                    PulseCardTitle(String(localized: "ZENO Age trend"))
                    PulseSegmentedControl(options: TrendSpan.allCases, selection: $trendSpan) {
                        $0 == .month ? "M" : "6M"
                    }
                    HealthAgeTrendChart(weeks: trendWeeks(s), hue: current.week.hue)
                }
            }
            if s.paceSeries.count >= 2 {
                PulseCard {
                    VStack(alignment: .leading, spacing: 16) {
                        PulseCardTitle(String(localized: "Pace of Aging trend"))
                        HealthPaceTrendChart(points: Array(s.paceSeries.suffix(trendSpan == .month ? 5 : 26)))
                    }
                }
            }
        }
    }

    private func trendWeeks(_ s: HealthspanSnapshot) -> [HealthAgeWeek] {
        Array(s.weeks.suffix(trendSpan == .month ? 5 : 26))
    }

    private func weekTitle(_ key: String) -> String {
        let end = PulseDisplay.dayKey(key, offsetBy: 6) ?? key
        return "\(PulseFormat.dayLabel(key, template: "MMMd")) - \(PulseFormat.dayLabel(end, template: "MMMd"))"
    }

    private var coachSeed: String? {
        guard let summary = shown?.summary else { return nil }
        var text = String(localized: "Healthspan: ZENO Age \(PulseFormat.oneDecimal(summary.week.zenoAge)), \(healthYearsLine(summary.week.yearsYounger))")
        if let pace = summary.pace { text += ", " + String(localized: "Pace of Aging \(PulseFormat.oneDecimal(pace))x") }
        return text + "."
    }

    static let disclaimer = String(localized: "ZENO Age is a wellness estimate from your own habits, using published links between these measures and long-term health. It is not a clinical or biological age, and it cannot diagnose anything.")

    static let infoParagraphs: [String] = [
        String(localized: "ZENO Age compares your week's resting heart rate, heart rate variability, sleep duration, sleep regularity and steps with published research on how each relates to long-term health, and turns the combined effect into years older or younger than your age."),
        String(localized: "It is scored once a week, on the week starting Saturday, and refined each day until the week closes."),
        String(localized: "Pace of Aging is how fast your ZENO Age is moving against the calendar over the last six months: 1.0x keeps pace with it, under 1.0x is slower, over 1.0x faster. It needs four weeks of ZENO Age."),
        String(localized: "Each row shows the week's value on a bar coloured by what the model makes of it, your 6-month (▼) and 30-day (▲) averages, and the years that factor adds or takes off this week."),
    ]
}

/// "▼ 6 Month avg.  ▲ 30 Day avg." at a pillar header's right (11 pt, 70%).
private struct HealthspanLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                PulseTriangle(pointsUp: false).fill(Color.white).frame(width: 8, height: 6)
                Text(String(localized: "6 Month avg.")).pulseText(.legend).foregroundStyle(PulseTheme.textSecondary)
            }
            HStack(spacing: 4) {
                PulseTriangle(pointsUp: true).fill(PulseTheme.textSecondary).frame(width: 8, height: 6)
                Text(String(localized: "30 Day avg.")).pulseText(.legend).foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }
}

/// One expandable pillar row: caps label and "⌄", then the range bar with its averages and, at the right,
/// the years (17 pt Bold, teal when it takes years off, orange when it adds them) over "years"; expanded,
/// the verdict, the sentence with the week's figures, and VIEW TREND →.
struct HealthspanRowView: View {
    let row: HealthspanRow
    let expanded: Bool
    let onToggle: () -> Void

    @Environment(\.pulseNavigator) private var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack {
                    Text(row.title)
                        .pulseText(.cardTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                .frame(minHeight: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(row.title)
            .accessibilityValue(accessibility)
            .accessibilityHint(expanded ? String(localized: "Collapses the row") : String(localized: "Shows what it means"))

            HStack(alignment: .center, spacing: 12) {
                HealthspanRangeBar(row: row, showsLabels: expanded)
                impact
                    .frame(width: 52, alignment: .trailing)
            }
            .accessibilityHidden(true)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(row.verdict)
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(row.sentence)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let route = row.route {
                        PulseTextCTA(title: String(localized: "View trend")) { navigator.open(route) }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
    }

    private var impact: some View {
        VStack(alignment: .trailing, spacing: 1) {
            if let years = row.years {
                Text(Self.signed(years))
                    .font(PulseType.font(.rowValue))
                    .foregroundStyle(years <= -0.05 ? PulseTheme.positive : (years >= 0.05 ? PulseTheme.negative : PulseTheme.textPrimary))
            } else {
                Text(verbatim: "–")
                    .font(PulseType.font(.rowValue))
                    .foregroundStyle(PulseTheme.textDisabled)
            }
            Text(String(localized: "years"))
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
        }
    }

    /// "-3.2", "+0.6", "0.0".
    static func signed(_ years: Double) -> String {
        let text = PulseFormat.oneDecimal(abs(years))
        if text == PulseFormat.oneDecimal(0) { return text }
        return years < 0 ? "-\(text)" : "+\(text)"
    }

    private var accessibility: String {
        var parts: [String] = []
        if let v = row.valueText { parts.append(String(localized: "this week \(v)")) }
        if let t = row.sixMonthText { parts.append(String(localized: "6-month average \(t)")) }
        if let t = row.thirtyDayText { parts.append(String(localized: "30-day average \(t)")) }
        if let years = row.years {
            let amount = PulseFormat.oneDecimal(abs(years))
            parts.append(years < 0 ? String(localized: "takes \(amount) years off") : String(localized: "adds \(amount) years"))
        }
        return parts.joined(separator: ", ")
    }
}

/// The pillar row's bar (§2.7 "Range bars"): ten segments 2 pt apart, coloured by what the ZENO Age model
/// makes of each stretch (orange adds years, grey neutral, teal takes years off; all grey for a measure the
/// model does not use), ▼ above at the 6-month average with its value, ▲ under it at the 30-day average,
/// and the scale's ends labelled.
struct HealthspanRangeBar: View {
    let row: HealthspanRow
    var showsLabels = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let span = row.scale.upperBound - row.scale.lowerBound
            let x: (Double) -> CGFloat = { v in w * CGFloat(min(1, max(0, (v - row.scale.lowerBound) / max(span, 0.0001)))) }
            ZStack(alignment: .topLeading) {
                if let six = row.sixMonth {
                    VStack(spacing: 2) {
                        Text(showsLabels ? String(localized: "6 Month avg. \(row.sixMonthText ?? "")") : (row.sixMonthText ?? ""))
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textPrimary)
                            .fixedSize()
                        PulseTriangle(pointsUp: false).fill(Color.white).frame(width: 9, height: 6)
                    }
                    .position(x: min(max(x(six), 30), w - 30), y: 10)
                }
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle()
                            .fill(tone(i))
                            .frame(height: 8)
                    }
                }
                .offset(y: 22)
                if let thirty = row.thirtyDay {
                    VStack(spacing: 2) {
                        PulseTriangle(pointsUp: true).fill(PulseTheme.textSecondary).frame(width: 9, height: 6)
                        if showsLabels {
                            Text(String(localized: "30 Day avg. \(row.thirtyDayText ?? "")"))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textSecondary)
                                .fixedSize()
                        }
                    }
                    .position(x: min(max(x(thirty), 30), w - 30), y: showsLabels ? 46 : 37)
                }
                HStack {
                    Text(row.lowLabel)
                    Spacer()
                    Text(row.highLabel)
                }
                .font(PulseType.font(.axis))
                .foregroundStyle(PulseTheme.textTertiary)
                .offset(y: showsLabels ? 56 : 42)
            }
        }
        .frame(height: showsLabels ? 70 : 56)
    }

    private func tone(_ i: Int) -> Color {
        guard row.tones.indices.contains(i) else { return Color.white.opacity(0.22) }
        switch row.tones[i] {
        case .helps: return PulseTheme.positive
        case .neutral: return PulseTheme.sufficient
        case .hurts: return PulseTheme.negative
        }
    }
}

/// ZENO AGE TREND (§2.7 "Healthspan age trend"): ZENO Age as a step line in the orb's hue against the
/// chronological age (white), a legend, and the latest values at the line ends.
struct HealthAgeTrendChart: View {
    let weeks: [HealthAgeWeek]
    let hue: HealthAgeHue

    var body: some View {
        let values = weeks.flatMap { [$0.zenoAge, $0.chronoAge] }
        let lo = floor(((values.min() ?? 30) - 2) / 5) * 5
        let hi = ceil(((values.max() ?? 40) + 2) / 5) * 5
        let colour = HealthPalette.orb(hue).particles
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                legend(colour, String(localized: "ZENO Age"), filled: true)
                legend(Color.white, String(localized: "Chronological age"), filled: false)
            }
            Chart {
                ForEach(Array(weeks.enumerated()), id: \.element.id) { i, w in
                    LineMark(x: .value("Week", i), y: .value("Age", w.chronoAge), series: .value("S", "chrono"))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.stepEnd)
                    LineMark(x: .value("Week", i), y: .value("Age", w.zenoAge), series: .value("S", "zeno"))
                        .foregroundStyle(colour)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.stepEnd)
                }
                if let last = weeks.last {
                    // The two end labels point away from each other: the higher line's above, the lower's below.
                    let zenoAbove = last.zenoAge >= last.chronoAge
                    PointMark(x: .value("Week", weeks.count - 1), y: .value("Age", last.zenoAge))
                        .foregroundStyle(colour)
                        .annotation(position: zenoAbove ? .top : .bottom, alignment: .trailing, spacing: 4) {
                            Text(PulseFormat.oneDecimal(last.zenoAge))
                                .font(PulseType.numeral(12))
                                .foregroundStyle(colour)
                        }
                    PointMark(x: .value("Week", weeks.count - 1), y: .value("Age", last.chronoAge))
                        .foregroundStyle(Color.white)
                        .annotation(position: zenoAbove ? .bottom : .top, alignment: .trailing, spacing: 4) {
                            Text(PulseFormat.oneDecimal(last.chronoAge))
                                .font(PulseType.numeral(12))
                                .foregroundStyle(PulseTheme.textPrimary)
                        }
                }
            }
            .chartYScale(domain: lo...hi)
            .chartXScale(domain: 0...max(1, weeks.count - 1))
            .chartXAxis {
                AxisMarks(values: xLabelIndices) { value in
                    let i = value.as(Int.self) ?? 0
                    AxisValueLabel(anchor: i == 0 ? .topLeading : (i == weeks.count - 1 ? .topTrailing : .top),
                                   collisionResolution: .disabled) {
                        if weeks.indices.contains(i) {
                            Text(PulseFormat.dayLabel(weeks[i].id, template: "MMMd"))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: PulseChartAxis.gridValues(lo...hi, count: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(PulseFormat.oneDecimal(v)).font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "ZENO Age trend"))
        .accessibilityValue(summary)
    }

    private var xLabelIndices: [Int] {
        guard weeks.count > 2 else { return Array(weeks.indices) }
        return [0, weeks.count / 2, weeks.count - 1]
    }

    private var summary: String {
        guard let first = weeks.first, let last = weeks.last else { return String(localized: "No data") }
        return String(localized: "From \(PulseFormat.oneDecimal(first.zenoAge)) to \(PulseFormat.oneDecimal(last.zenoAge)); chronological age \(PulseFormat.oneDecimal(last.chronoAge))")
    }

    private func legend(_ colour: Color, _ title: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .circular)
                .fill(filled ? colour : Color.clear)
                .overlay(RoundedRectangle(cornerRadius: 2, style: .circular).strokeBorder(colour, lineWidth: filled ? 0 : 1.5))
                .frame(width: 11, height: 11)
            Text(title).pulseText(.label).foregroundStyle(PulseTheme.textSecondary)
        }
    }
}

/// PACE OF AGING TREND (whoop-site/73): the weekly pace from −1.0x to 3.0x with a dashed 1.0x line.
struct HealthPaceTrendChart: View {
    let points: [HealthspanSnapshot.PacePoint]

    var body: some View {
        Chart {
            RuleMark(y: .value("Calendar", 1.0))
                .foregroundStyle(PulseTheme.dash)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            ForEach(Array(points.enumerated()), id: \.element.id) { i, p in
                LineMark(x: .value("Week", i), y: .value("Pace", p.pace))
                    .foregroundStyle(PulseTheme.recoveryBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                PointMark(x: .value("Week", i), y: .value("Pace", p.pace))
                    .symbol {
                        Circle().strokeBorder(PulseTheme.recoveryBlue, lineWidth: 2)
                            .background(Circle().fill(PulseTheme.cardSolidMiddle))
                            .frame(width: 8, height: 8)
                    }
            }
        }
        .chartYScale(domain: -1...3)
        .chartXScale(domain: 0...max(1, points.count - 1))
        .chartXAxis {
            AxisMarks(values: points.count > 2 ? [0, points.count / 2, points.count - 1] : Array(points.indices)) { value in
                let i = value.as(Int.self) ?? 0
                AxisValueLabel(anchor: i == 0 ? .topLeading : (i == points.count - 1 ? .topTrailing : .top),
                               collisionResolution: .disabled) {
                    if points.indices.contains(i) {
                        Text(PulseFormat.dayLabel(points[i].id, template: "MMMd"))
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [-1.0, 1.0, 3.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(String(localized: "\(PulseFormat.oneDecimal(v))x"))
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .frame(height: 160)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Pace of Aging trend"))
        .accessibilityValue(points.last.map { String(localized: "Latest \(PulseFormat.oneDecimal($0.pace)) times") } ?? "")
    }
}

/// The compact header that pins once the orb scrolls away (§3.23): "8.3 YEARS YOUNGER" at the left, a small
/// orb with the age in the centre, "0.1x PACE OF AGING" at the right, on the near-black page.
struct HealthspanCompactHeader: View {
    let summary: HealthAgeSummary

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            stat(PulseFormat.oneDecimal(abs(summary.week.yearsYounger)),
                 summary.week.yearsYounger >= 0 ? String(localized: "Years younger") : String(localized: "Years older"),
                 colour: HealthPalette.orb(summary.week.hue).text)
                .frame(maxWidth: .infinity)
            HealthAgeOrb(hue: summary.week.hue, diameter: 84) {
                HealthOrbReading(age: PulseFormat.oneDecimal(summary.week.zenoAge), yearsLine: nil,
                                 hue: summary.week.hue, ageSize: PulseTextStyle.mediumValue.spec.size)
            }
            stat(summary.pace.map { String(localized: "\(PulseFormat.oneDecimal($0))x") } ?? "--",
                 String(localized: "Pace of Aging"), colour: PulseTheme.textPrimary)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .padding(.vertical, 8)
        .background(
            LinearGradient(stops: [
                .init(color: PulseTheme.pageNearBlack, location: 0),
                .init(color: PulseTheme.pageNearBlack, location: 0.82),
                .init(color: PulseTheme.pageNearBlack.opacity(0), location: 1),
            ], startPoint: .top, endPoint: .bottom)
            .padding(.bottom, -24)
        )
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String, colour: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PulseType.font(.rowValue))
                .foregroundStyle(colour)
            Text(label)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
#endif
