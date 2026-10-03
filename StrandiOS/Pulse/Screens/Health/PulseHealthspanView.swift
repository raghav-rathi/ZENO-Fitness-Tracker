#if os(iOS)
import SwiftUI
import Charts
import StrandAnalytics

/// Healthspan (WHOOP_UI_SPEC §3.23), pushed from the Health tab's orb and Pace card: "HEALTHSPAN" over
/// when the week closes, its own week pager, the ZENO Age orb (312 pt), the Pace of Aging ruler with the
/// notched insight under it, the pillars (Sleep · Strain · Fitness) as rows of range bars with the years
/// each adds or takes off, and the ZENO AGE and PACE OF AGING trends. Once the orb scrolls away a compact
/// header takes the title's place in the bar. Locked: the dormant orb and "UNLOCK ZENO AGE · N of 21 nights".
///
/// ZENO Age is the VitalityEngine Body Age the weekly pass stored; Pace of Aging is `PaceOfAging` over its
/// weekly values; a row's years are that factor's log-hazard through `VitalityEngine.years(for:)`, shown
/// only when the rows add up to the stored age (`HealthspanBreakdown`).
///
/// Not built on `PulseScreenScaffold`: the page is slate with the black behind the orb scrolling away with
/// it (reviews/r119 at rest, reviews/29 scrolled), and the bar trades its title for the compact header, so
/// the screen carries the scaffold's pushed-screen duties itself: the bar and swipe-back, the backdrop once
/// content scrolls under the bar, the floating Coach button and its 80 pt inset, and the DEBUG
/// `--pulse-scroll` anchors.
struct PulseHealthspanView: View {
    /// Rebuilt: existing entry points open this instead of the classic Health screen.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseCoach) private var coach
    @Environment(\.pulseModalRoot) private var modalRoot
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profile: ProfileStore

    /// The week shown; nil is the newest.
    @State private var weekKey: String?
    @State private var snapshot: HealthspanSnapshot?
    /// The rows outside the model (zones, strength), from their own pass.
    @State private var tracked: HealthspanTracked?
    @State private var showsInfo = false
    @State private var expanded: Set<String> = []
    @State private var orbPassed = false
    @State private var restTop: CGFloat?
    @State private var scrolledUnder = false
    @State private var trendSpan: TrendSpan = .sixMonths

    enum TrendSpan: String, CaseIterable, Hashable { case month, sixMonths }

    /// The big orb (reviews/r119: ≈312 pt, its top at 186 pt).
    static let orbDiameter: CGFloat = 312
    /// The compact header's orb (reviews/29: ≈106 pt).
    static let compactOrb: CGFloat = 100
    /// The ruler and the insight card sit 20 pt from the screen edges (reviews/r119: card 19.3–374.3 pt).
    static let wideInset: CGFloat = 4

    private var shown: HealthspanSnapshot? {
        guard let snapshot else { return nil }
        if let weekKey, snapshot.summary?.week.id != weekKey { return nil }
        return snapshot
    }

    private var bottomInset: CGFloat {
        coach.availability != .off ? PulseTheme.Layout.floatingChromeInset : PulseTheme.Layout.plainBottomInset
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("pulse.top")
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: HealthspanScrollTopKey.self,
                                                   value: geo.frame(in: .named(PulseScrollSpace.name)).minY)
                        })
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
                    Color.clear.frame(height: bottomInset).id("pulse.bottom")
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .coordinateSpace(name: PulseScrollSpace.name)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .onPreferenceChange(HealthspanScrollTopKey.self) { top in
                guard let top else { return }
                if restTop == nil { restTop = top }
                let under = top < (restTop ?? top) - 1
                if under != scrolledUnder { scrolledUnder = under }
            }
            .pulseDebugScroll(proxy, ready: shown != nil)
        }
        .background(HealthspanPageBackground())
        .overlay(alignment: .top) {
            HealthspanBarBackdrop(colour: orbPassed ? HealthPalette.healthspanSlate : HealthPalette.healthspanTop,
                                  extra: orbPassed ? Self.compactExtra : 0)
                .opacity(scrolledUnder ? 1 : 0)
                .animation(PulseMotion.chrome, value: scrolledUnder)
                .animation(PulseMotion.chrome, value: orbPassed)
        }
        .overlay { PulseFloatingCoach(accessory: .button, seed: coachSeed) }
        .navigationTitle(String(localized: "Healthspan"))
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .background(PulseSwipeBackEnabler())
        .environment(\.colorScheme, .dark)
        .task(id: "\(model.healthKey)|\(weekKey ?? "latest")") {
            let dob = profile.dateOfBirth
            let key = weekKey
            if let s = await model.build(dayOffset: 0, { builder, request in
                await builder.healthspan(request, weekKey: key, dateOfBirth: dob)
            }) {
                if snapshot != s { snapshot = s }
            }
        }
        .task(id: "\(model.healthKey)|tracked|\(weekKey ?? "latest")|\(snapshot?.seq ?? -1)") {
            guard snapshot?.summary != nil else { return }
            let dob = profile.dateOfBirth
            let key = weekKey
            if let t = await model.build(dayOffset: 0, { builder, request in
                await builder.healthspanTracked(request, weekKey: key, dateOfBirth: dob)
            }) {
                if tracked != t { tracked = t }
            }
        }
        .sheet(isPresented: $showsInfo) {
            HealthInfoSheet(title: String(localized: "How ZENO Age works"), paragraphs: Self.infoParagraphs)
        }
    }

    /// How far below the bar the compact header reaches (its orb's foot), for the backdrop behind it.
    private static var compactExtra: CGFloat { compactOrb - PulseTheme.Header.navBar / 2 + 8 }

    /// The bar: "‹", "HEALTHSPAN" over when the week closes, ⓘ. Once the orb has scrolled away its title gives
    /// way to the compact header, hung from the bar's centre line (reviews/29).
    private var header: some View {
        HealthNavBar(title: String(localized: "Healthspan"), subtitle: subtitle, showsTitle: !orbPassed,
                     trailing: .info { showsInfo = true }, leading: modalRoot ? .close : .back,
                     onLeading: { dismiss() })
            .overlay(alignment: .top) {
                if orbPassed, let summary = shown?.summary {
                    HealthspanCompactHeader(summary: summary, orbDiameter: Self.compactOrb)
                        .padding(.top, PulseTheme.Header.navBarTop + PulseTheme.Header.navBar / 2 - 2)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .animation(PulseMotion.chrome, value: orbPassed)
    }

    /// "FINAL IN 3 DAYS" while the week is still being scored: ZENO's weekly pass refines the current
    /// week's ZENO Age every day until the week closes, so it says when the figure stops moving rather than
    /// promising WHOOP's "next update" (ARCHITECTURE §9).
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

            HealthAgeOrb(hue: summary.week.hue, diameter: Self.orbDiameter) {
                HealthOrbReading(age: PulseFormat.oneDecimal(summary.week.zenoAge),
                                 yearsLine: healthYearsLine(summary.week.yearsYounger), hue: summary.week.hue,
                                 largeLabel: true)
            }
            .frame(maxWidth: .infinity)
            .background(alignment: .top) { HealthspanTopShade(diameter: Self.orbDiameter) }
            .padding(.top, 43)
            .pulseScrolledPast($orbPassed, threshold: 200)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "ZENO Age \(PulseFormat.oneDecimal(summary.week.zenoAge)), \(healthYearsLine(summary.week.yearsYounger))"))
            // Drawn under the pager, so the black behind the orb never covers it.
            .zIndex(-1)

            VStack(alignment: .leading, spacing: 10) {
                PulseCardTitle(String(localized: "Pace of Aging"))
                HealthPaceRuler(pace: summary.pace, combInset: 1)
            }
            .padding(.horizontal, Self.wideInset)
            .padding(.top, 22)

            if let insight = s.insight {
                insightCard(insight)
                    .padding(.horizontal, Self.wideInset)
                    .padding(.top, 14)
            }

            if let note = s.breakdownNote {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "info.circle")
                        .healthGlyph(.info)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .accessibilityHidden(true)
                    Text(note)
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 20)
            }

            ForEach(s.pillars) { pillar in
                let rows = pillarRows(pillar, week: summary.week.id)
                if !rows.isEmpty {
                    pillarSection(pillar.title, rows: rows)
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

    /// A pillar's rows; the Strain pillar takes the zone and strength rows ahead of steps once their pass
    /// has landed for this week (WHOOP's order: zones 1-3, zones 4-5, strength, steps).
    private func pillarRows(_ pillar: HealthspanPillar, week: String) -> [HealthspanRow] {
        guard pillar.id == "strain", let tracked, tracked.weekKey == week else { return pillar.rows }
        return tracked.rows + pillar.rows
    }

    // MARK: Insight

    /// The notched insight under the ruler. Its pointer stays at the card's centre whatever the needle does
    /// (reviews/r119: needle at ≈119 pt, pointer at ≈197 pt; appstore/ios69-05 the same).
    private func insightCard(_ insight: HealthspanSnapshot.Insight) -> some View {
        PulseCallout(notchPosition: 0.5) {
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

    private func pillarSection(_ title: String, rows: [HealthspanRow]) -> some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .pulseText(.sectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                HealthspanLegend()
            }
            PulseCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                        HealthspanRowView(row: row, expanded: expanded.contains(row.id) || Self.expandsAll) {
                            if expanded.contains(row.id) { expanded.remove(row.id) } else { expanded.insert(row.id) }
                        }
                        if i < rows.count - 1 { PulseDivider(leadingInset: 16, trailingInset: 16) }
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

    /// DEBUG `--pulse-health-expand`: every pillar row open, for captures.
    private static var expandsAll: Bool {
        #if DEBUG
        return CommandLine.arguments.contains("--pulse-health-expand")
        #else
        return false
        #endif
    }

    static let disclaimer = String(localized: "ZENO Age is a wellness estimate from your own habits, using published links between these measures and long-term health. It is not a clinical or biological age, and it cannot diagnose anything.")

    static let infoParagraphs: [String] = [
        String(localized: "ZENO Age compares your week's resting heart rate, heart rate variability, sleep duration, sleep regularity and steps with published research on how each relates to long-term health, and turns the combined effect into years older or younger than your age."),
        String(localized: "It is scored once a week, on the week starting Saturday, and refined each day until the week closes."),
        String(localized: "Pace of Aging is how fast your ZENO Age is moving against the calendar over the last six months: 1.0x keeps pace with it, under 1.0x is slower, over 1.0x faster. It needs four weeks of ZENO Age."),
        String(localized: "Each row shows the week's value on a bar coloured by what the model makes of it, your 6-month (▼) and 30-day (▲) averages, and the years that factor adds or takes off this week. The years only show when they add up to the week's ZENO Age; sleep regularity is how steady your nightly hours were, not the timing-based Sleep Consistency."),
        String(localized: "Time in heart rate zones and strength time count your workouts, and VO₂ max is your weekly estimate. ZENO Age does not use them, so they are shown alongside without years."),
    ]
}

private struct HealthspanScrollTopKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
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
/// the years (17 pt Bold, teal when it takes years off, orange when it adds them) over "years"; "–" when the
/// row carries no years (outside the model, or a breakdown that does not add up); expanded, the verdict, the
/// sentence with the week's figures, and VIEW TREND →.
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
                        .healthGlyph(.disclosure)
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
                    .pulseText(.rowValue)
                    .foregroundStyle(years <= -0.05 ? PulseTheme.positive : (years >= 0.05 ? PulseTheme.negative : PulseTheme.textPrimary))
            } else {
                Text(verbatim: "–")
                    .pulseText(.rowValue)
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
        if let t = row.withUnit(row.sixMonthNumber) { parts.append(String(localized: "6-month average \(t)")) }
        if let t = row.withUnit(row.thirtyDayNumber) { parts.append(String(localized: "30-day average \(t)")) }
        if let years = row.years {
            let amount = PulseFormat.oneDecimal(abs(years))
            parts.append(years < 0 ? String(localized: "takes \(amount) years off") : String(localized: "adds \(amount) years"))
        } else {
            parts.append(row.verdict)
        }
        return parts.joined(separator: ", ")
    }
}

/// The pillar row's bar (§2.7 "Range bars"; reviews/29): ten 4 pt segments 2 pt apart, coloured by what the
/// ZENO Age model makes of each stretch (orange adds years, grey neutral, teal takes years off, the ends
/// lightened and the middle dimmed; all grey for a measure the model does not use), ▼ above at the 6-month
/// average with its value (the number bold, the unit regular grey), ▲ under it at the 30-day average, and
/// the scale's ends labelled in their end segment's tone.
struct HealthspanRangeBar: View {
    let row: HealthspanRow
    var showsLabels = false

    private static let barHeight: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let span = row.scale.upperBound - row.scale.lowerBound
            let x: (Double) -> CGFloat = { v in w * CGFloat(min(1, max(0, (v - row.scale.lowerBound) / max(span, 0.0001)))) }
            ZStack(alignment: .topLeading) {
                if let six = row.sixMonth {
                    VStack(spacing: 2) {
                        sixMonthLabel
                            .fixedSize()
                        PulseTriangle(pointsUp: false).fill(Color.white).frame(width: 9, height: 6)
                    }
                    .position(x: min(max(x(six), 30), w - 30), y: 10)
                }
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { i in
                        Rectangle()
                            .fill(HealthPalette.rangeSegment(tone(i), emphasis: emphasis(i)))
                            .frame(height: Self.barHeight)
                    }
                }
                .offset(y: 24)
                if let thirty = row.thirtyDay {
                    VStack(spacing: 2) {
                        PulseTriangle(pointsUp: true).fill(PulseTheme.textSecondary).frame(width: 9, height: 6)
                        if showsLabels, let text = row.withUnit(row.thirtyDayNumber) {
                            Text(String(localized: "30 Day avg. \(text)"))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textSecondary)
                                .fixedSize()
                        }
                    }
                    .position(x: min(max(x(thirty), 30), w - 30), y: showsLabels ? 44 : 35)
                }
                HStack {
                    Text(row.lowLabel).foregroundStyle(HealthPalette.rangeLabel(row.tones.first))
                    Spacer()
                    Text(row.highLabel).foregroundStyle(HealthPalette.rangeLabel(row.tones.last))
                }
                .font(PulseType.font(.axis))
                .offset(y: showsLabels ? 54 : 40)
            }
        }
        .frame(height: showsLabels ? 68 : 54)
    }

    /// "55 mL/kg/min": the number bold and white, the unit regular and grey (reviews/29); expanded, led by
    /// "6 Month avg.".
    private var sixMonthLabel: some View {
        let number = Text(row.sixMonthNumber ?? "").font(PulseType.font(.baseline)).foregroundColor(PulseTheme.textPrimary)
        let unit = row.unit.isEmpty ? Text("")
            : Text((row.unit == "%" ? "" : " ") + row.unit).font(PulseType.font(.legend))
                .foregroundColor(PulseTheme.textTertiary)
        let lead = showsLabels
            ? Text(String(localized: "6 Month avg.") + " ").font(PulseType.font(.legend)).foregroundColor(PulseTheme.textSecondary)
            : Text("")
        return lead + number + unit
    }

    private func tone(_ i: Int) -> HealthspanRow.Tone? {
        row.tones.indices.contains(i) ? row.tones[i] : nil
    }

    /// 1 at either end of the bar, falling to 0 at its middle.
    private func emphasis(_ i: Int) -> Double {
        let fromEnd = Double(min(i, 9 - i))
        return 1 - fromEnd / 4.5
    }
}

/// ZENO AGE TREND (§2.7 "Healthspan age trend"): ZENO Age as a step line in the orb's hue against the
/// chronological age (white), a legend, 5-year gridlines, and the latest values beside the line ends, with
/// room kept at the right so neither label sits on the last step (reviews/29).
struct HealthAgeTrendChart: View {
    let weeks: [HealthAgeWeek]
    let hue: HealthAgeHue

    /// The share of the x axis kept clear after the last week for the end labels.
    private static let endRoom = 0.16

    var body: some View {
        let values = weeks.flatMap { [$0.zenoAge, $0.chronoAge] }
        let lo = floor(((values.min() ?? 30) - 2) / 5) * 5
        let hi = ceil(((values.max() ?? 40) + 2) / 5) * 5
        let colour = HealthPalette.orb(hue).particles
        let lastIndex = Double(max(1, weeks.count - 1))
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                legend(colour, String(localized: "ZENO Age"), filled: true)
                legend(Color.white, String(localized: "Chronological age"), filled: false)
            }
            Chart {
                ForEach(Array(weeks.enumerated()), id: \.element.id) { i, w in
                    LineMark(x: .value("Week", Double(i)), y: .value("Age", w.chronoAge), series: .value("S", "chrono"))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.stepEnd)
                    LineMark(x: .value("Week", Double(i)), y: .value("Age", w.zenoAge), series: .value("S", "zeno"))
                        .foregroundStyle(colour)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.stepEnd)
                }
                if let last = weeks.last {
                    // The two end labels point away from each other: the higher line's above, the lower's below,
                    // both starting just right of the line's end.
                    let zenoAbove = last.zenoAge >= last.chronoAge
                    PointMark(x: .value("Week", Double(weeks.count - 1)), y: .value("Age", last.zenoAge))
                        .symbol { endDot(colour) }
                        .annotation(position: zenoAbove ? .topTrailing : .bottomTrailing, spacing: 2) {
                            Text(PulseFormat.oneDecimal(last.zenoAge))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(colour)
                                .padding(.leading, 6)
                        }
                    PointMark(x: .value("Week", Double(weeks.count - 1)), y: .value("Age", last.chronoAge))
                        .symbol { endDot(Color.white) }
                        .annotation(position: zenoAbove ? .bottomTrailing : .topTrailing, spacing: 2) {
                            Text(PulseFormat.oneDecimal(last.chronoAge))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textPrimary)
                                .padding(.leading, 6)
                        }
                }
            }
            .chartYScale(domain: lo...hi)
            .chartXScale(domain: 0...(lastIndex * (1 + Self.endRoom)))
            .chartXAxis {
                AxisMarks(values: xLabelIndices.map(Double.init)) { value in
                    let i = Int((value.as(Double.self) ?? 0).rounded())
                    AxisValueLabel(anchor: i == 0 ? .topLeading : .top, collisionResolution: .disabled) {
                        if weeks.indices.contains(i) {
                            Text(PulseFormat.dayLabel(weeks[i].id, template: "MMMd"))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: Self.fiveYearGrid(lo...hi)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(PulseTheme.gridOnCard)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(PulseFormat.whole(v)).font(PulseType.font(.axis)).foregroundStyle(PulseTheme.textTertiary)
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

    /// Gridlines every 5 years across the domain (every 10 once that would draw more than five).
    static func fiveYearGrid(_ domain: ClosedRange<Double>) -> [Double] {
        let step = (domain.upperBound - domain.lowerBound) / 5 > 4 ? 10.0 : 5.0
        return Array(stride(from: domain.lowerBound, through: domain.upperBound, by: step))
    }

    private func endDot(_ colour: Color) -> some View {
        Circle()
            .strokeBorder(colour, lineWidth: 2)
            .background(Circle().fill(PulseTheme.cardSolidMiddle))
            .frame(width: 9, height: 9)
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

/// PACE OF AGING TREND (whoop-site/73): the weekly pace from −1.0x to 3.0x with a dashed 1.0x line. The
/// domain runs a quarter past each end, so a pace held at the clamp sits inside the plot, clear of the
/// axis labels.
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
        .chartYScale(domain: -1.25...3.25)
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

/// The compact header that takes the bar's title once the orb scrolls away (§3.23; reviews/29): "8.3 YEARS
/// YOUNGER" at the left, a ≈100 pt orb with the age in the centre, "0.1x PACE OF AGING" at the right, the
/// orb hung from the bar's centre line between "‹" and ⓘ.
struct HealthspanCompactHeader: View {
    let summary: HealthAgeSummary
    var orbDiameter: CGFloat = 100

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            stat(PulseFormat.oneDecimal(abs(summary.week.yearsYounger)),
                 summary.week.yearsYounger >= 0 ? String(localized: "Years younger") : String(localized: "Years older"),
                 colour: HealthPalette.orb(summary.week.hue).text)
                .frame(maxWidth: .infinity)
            HealthAgeOrb(hue: summary.week.hue, diameter: orbDiameter) {
                HealthOrbReading(age: PulseFormat.oneDecimal(summary.week.zenoAge), yearsLine: nil,
                                 hue: summary.week.hue, ageSize: PulseTextStyle.mediumValue.spec.size)
                    .dynamicTypeSize(...DynamicTypeSize.large)
            }
            stat(summary.pace.map { String(localized: "\(PulseFormat.oneDecimal($0))x") } ?? "--",
                 String(localized: "Pace of Aging"), colour: PulseTheme.textPrimary)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        // A fixed header over the page: its text stops growing where the small orb's label would not fit.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String, colour: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .pulseText(.rowValue)
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
