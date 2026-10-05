#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Stress Monitor (WHOOP_UI_SPEC §3.22), pushed from Home's tile and dashboard card and the Health tab's
/// card: ⚙ in the bar (stress check-ins and the scoring lens, `HealthStressSettingsRoute`), its own day
/// pager ("‹ TODAY ›"), the gauge with ⓘ, the 24 h chart, plain sentences on the day, TOTAL DAY against the
/// typical same weekday, and guided-breathing session cards under "Sessions".
///
/// One source for the level and the curve (`PulseSnapshotBuilder.stressDay`): the gauge shows the curve's
/// latest scored hour, and only a day without a curve falls back to the daily score, labelled as such.
/// The typical weekday reads six earlier days, so it arrives in a second pass (`stressMonitorTypical`)
/// after the day has drawn.
struct PulseStressMonitorView: View {
    /// Rebuilt: existing entry points (Home's tile and dashboard card) open this instead of the classic screen.
    static let isRebuilt = true

    /// The day to open on, days back from today; nil opens on the day Home shows, so the dashboard's
    /// STRESS MONITOR card on a past day opens that day (the Health tab passes 0: it is always now).
    var startOffset: Int?

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    /// Days back from today, seeded once on first appearance; the screen then pages on its own (§1.7).
    @State private var offset: Int?
    @State private var snapshot: StressMonitorSnapshot?
    @State private var typical: StressMonitorTypical?
    @State private var showsInfo = false

    private var day: Int { offset ?? startOffset ?? 0 }

    private var shown: StressMonitorSnapshot? {
        guard let snapshot, snapshot.day.dayKey == dayKey(day) else { return nil }
        return snapshot
    }

    /// The typical weekday for the day shown, once its pass has landed.
    private var shownTypical: StressMonitorTypical? {
        guard let typical, let shown, typical.dayKey == shown.day.dayKey else { return nil }
        return typical
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Stress Monitor"),
                            trailing: .symbol("gearshape",
                                              accessibilityLabel: String(localized: "Stress Monitor settings")) {
                                navigator.push(HealthStressSettingsRoute().route)
                            },
                            coach: .button, coachSeed: coachSeed, spacing: 0, topPadding: 0, ready: shown != nil) {
            HealthPager(title: shown?.title ?? pagerTitle, canGoBack: day < model.maxDayOffset,
                        canGoForward: day > 0,
                        onBack: { offset = min(model.maxDayOffset, day + 1) },
                        onForward: { offset = max(0, day - 1) })
            PulseLoadingGate(isLoading: shown == nil) {
                if let s = shown {
                    content(s)
                }
            } skeleton: {
                VStack(spacing: 24) {
                    Circle()
                        .trim(from: 0, to: 0.62)
                        .stroke(PulseTheme.skeleton, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                        .rotationEffect(.degrees(-202.5))
                        .frame(width: 230, height: 230)
                        .frame(height: 180, alignment: .top)
                        .frame(maxWidth: .infinity)
                    PulseSkeleton.cards([230, 180])
                }
                .padding(.top, 24)
            }
        }
        .onAppear {
            guard offset == nil else { return }
            #if DEBUG
            offset = startOffset ?? PulseDebugLaunch.dayOffset ?? model.dayOffset
            #else
            offset = startOffset ?? model.dayOffset
            #endif
        }
        .task(id: "\(model.healthKey)|\(offset.map(String.init) ?? "-")") {
            guard let day = offset else { return }
            if let s = await model.build(dayOffset: day, { builder, request in await builder.stressMonitor(request) }) {
                if snapshot != s { snapshot = s }
            }
        }
        .task(id: "\(model.healthKey)|typical|\(snapshot?.day.dayKey ?? "-")|\(snapshot?.seq ?? -1)") {
            guard let day = offset, snapshot != nil else { return }
            if let t = await model.build(dayOffset: day, { builder, request in
                await builder.stressMonitorTypical(request)
            }) {
                if typical != t { typical = t }
            }
        }
        .sheet(isPresented: $showsInfo) {
            HealthInfoSheet(title: String(localized: "How stress is scored"), paragraphs: Self.infoParagraphs)
        }
        #if DEBUG
        .task(id: shown != nil) { openDebugBreatheIfAsked() }
        #endif
    }

    #if DEBUG
    @MainActor private static var openedDebugBreathe = false

    /// `--pulse-stress-breathe`: open the first Sessions card's Breathe once the day has drawn, for captures;
    /// `--pulse-stress-settings`: open the ⚙ page the same way.
    private func openDebugBreatheIfAsked() {
        guard shown != nil, !Self.openedDebugBreathe else { return }
        if CommandLine.arguments.contains("--pulse-stress-breathe") {
            Self.openedDebugBreathe = true
            navigator.open(HealthBreatheSession.destination.route)
        } else if CommandLine.arguments.contains("--pulse-stress-settings") {
            Self.openedDebugBreathe = true
            navigator.push(HealthStressSettingsRoute().route)
        }
    }
    #endif

    /// The local key of the day `offset` back from Home's today, the logical day that rolls at 04:00, as
    /// `PulseModel` dates a request and the builder keys the snapshot (`stressDayStart`), so the pager's
    /// title and the snapshot name the same day.
    private func dayKey(_ offset: Int) -> String {
        let logical = Repository.logicalDay(Date())
        let day = Calendar.current.date(byAdding: .day, value: -offset, to: logical) ?? logical
        return Repository.localDayKey(day)
    }

    private var pagerTitle: String {
        day == 0 ? String(localized: "Today") : PulseFormat.navDayTitle(dayKey: dayKey(day))
    }

    @ViewBuilder
    private func content(_ s: StressMonitorSnapshot) -> some View {
        let gauge = s.day.gaugeLevel
        let typical = shownTypical
        VStack(alignment: .leading, spacing: 0) {
            HealthStressGauge(level: gauge?.level, caption: gaugeCaption(s), onInfo: { showsInfo = true })
                .frame(maxWidth: .infinity)
                .padding(.top, 22)

            HealthStressDayChart(points: s.day.points, periods: s.periods, window: s.day.window,
                                 now: s.day.chartEnd,
                                 emptyMessage: s.day.isToday
                                    ? String(localized: "The day fills in as your strap records heart rate.")
                                    : String(localized: "No stress readings for this day."))
                .id("pulse.chart")
                .padding(.top, 26)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(sentences(s, typical: typical?.totals).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 28)

            if s.totals.scoredMinutes > 0 {
                HealthTotalDayCard(dayKey: s.day.dayKey, totals: s.totals, typical: typical?.totals,
                                   typicalDays: typical?.days ?? 0)
                    .id("pulse.total")
                    .padding(.top, 28)
            }

            PulseTextCTA(title: String(localized: "See trends")) {
                navigator.open(PulseRoute.trendView(metric: "stress").forExistingEntryPoint)
            }
            .padding(.top, 8)

            HealthBreatheSession(onOpen: { navigator.push($0.route) })
                .id("pulse.sessions")
                .padding(.top, 32)
        }
    }

    /// The gauge's line: the reading's time, with its day when it is not the day shown, or what the value is.
    private func gaugeCaption(_ s: StressMonitorSnapshot) -> String? {
        if let time = PulseStressDay.readingTime(s.day.latest?.at, dayKey: s.day.dayKey) { return time }
        if s.day.daily != nil { return String(localized: "Daily score from your vitals") }
        return nil
    }

    /// Plain sentences on the day (completeness-critic/14, 15; the App Store mock's longest-run line), every
    /// figure from the snapshot and, once it lands, the typical weekday's pass.
    private func sentences(_ s: StressMonitorSnapshot, typical: StressDayTotals.Totals?) -> [String] {
        var out: [String] = []
        let t = s.totals
        if t.scoredMinutes == 0 {
            if let e = s.dailyExplanation { out.append(e) }
            if let masked = stressActivityMaskedHoursCaption(s.day.maskedHours) { out.append(masked) }
            return out
        }
        let weekday = PulseFormat.dayLabel(s.day.dayKey, template: "EEEE")
        if t.highMinutes > 0 {
            out.append(s.day.isToday
                ? String(localized: "You've spent \(HealthFormat.spokenHours(minutes: t.highMinutes)) in the high stress zone so far today.")
                : String(localized: "You spent \(HealthFormat.spokenHours(minutes: t.highMinutes)) in the high stress zone on this day."))
        } else if let dominant = t.dominant {
            let zone = Self.levelName(dominant)
            out.append(s.day.isToday
                ? String(localized: "Most of your scored time today has been in the \(zone) stress zone.")
                : String(localized: "Most of your scored time on this day was in the \(zone) stress zone."))
        }
        if let typical {
            let diff = t.highMinutes - typical.highMinutes
            if abs(diff) < 5 {
                out.append(String(localized: "That's about the same as a typical \(weekday)."))
            } else if diff < 0 {
                out.append(String(localized: "That's \(HealthFormat.spokenHours(minutes: -diff)) less than a typical \(weekday)."))
            } else {
                out.append(String(localized: "That's \(HealthFormat.spokenHours(minutes: diff)) more than a typical \(weekday)."))
            }
        }
        if let run = s.longestHigh {
            out.append(String(localized: "Your longest stretch of high stress started at \(PulseFormat.clock(run.start)) and lasted \(HealthFormat.spokenHours(minutes: run.minutes))."))
        }
        if let masked = stressActivityMaskedHoursCaption(s.day.maskedHours) { out.append(masked) }
        return out
    }

    static func levelName(_ level: StressDayTotals.Level) -> String {
        switch level {
        case .low: return String(localized: "low")
        case .medium: return String(localized: "medium")
        case .high: return String(localized: "high")
        }
    }

    private var coachSeed: String? {
        guard let s = shown else { return nil }
        var parts = [String(localized: "Stress Monitor, \(s.title)")]
        if let g = s.day.gaugeLevel {
            parts.append(String(localized: "level \(PulseFormat.oneDecimal(HealthStressGauge.printed(g.level))) of 3"))
        }
        if s.totals.scoredMinutes > 0 {
            parts.append(String(localized: "high \(HealthFormat.spokenHours(minutes: s.totals.highMinutes)), medium \(HealthFormat.spokenHours(minutes: s.totals.mediumMinutes)), low \(HealthFormat.spokenHours(minutes: s.totals.lowMinutes))"))
        }
        if let typical = shownTypical?.totals {
            parts.append(String(localized: "typical high \(HealthFormat.spokenHours(minutes: typical.highMinutes))"))
        }
        return parts.joined(separator: "; ")
    }

    static let infoParagraphs: [String] = [
        String(localized: "ZENO reads stress from your heart rate, and the beat-to-beat timing when the strap records it, across your waking hours (6 AM to 10 PM). Each hour is set against your calmest hours that day, or against your own daytime baseline if you turned that on in the Stress Monitor's settings (⚙), and placed on a 0 to 3 scale: low under 1.0, medium to 1.9, high from 2.0."),
        String(localized: "Hours when the strap saw you moving are left out, so a workout or a walk is not read as stress. Sleep is scored in five-minute windows against the waking hours before it, as on the Sleep dive, and drawn on the chart; TOTAL DAY counts your waking hours only. Because each waking hour is scored as a whole, time in each zone counts in whole hours."),
        String(localized: "The chart shows the 24 hours up to the day's latest reading, or the last 24 hours before today's first one. The gauge shows your latest scored hour; on a day without hourly readings it shows that day's score from your resting heart rate and HRV against your baseline."),
        String(localized: "Typical is the average of the same weekday over the previous six weeks you wore the strap, up to the same hour when the day is still going. A wellness estimate, not a diagnosis."),
    ]
}

/// The Stress Monitor opened at a given day, for an entry point that must not follow Home's day: the Health
/// tab's card opens it at today (§1.7: the Health tab is always now).
struct HealthStressMonitorRoute: PulseScreenRoute {
    let startOffset: Int
    var view: some View { PulseStressMonitorView(startOffset: startOffset) }
}

/// TOTAL DAY (§3.22 item 6; completeness-critic/14): "SUN, AUG 2 STRESS VS. TYPICAL SUNDAY", the day's
/// time LOW / MEDIUM / HIGH as a 12 pt bar in the stress level colours over the typical day's 8 pt bar in
/// the same hues at half strength, then each band's time (17 pt; whole hours, since ZENO scores stress by
/// the hour), its change against typical (grey chips) and its name. On the dimmer card WHOOP draws it on.
/// The typical bar, chips and footnote join when the typical weekday's pass lands.
struct HealthTotalDayCard: View {
    let dayKey: String
    let totals: StressDayTotals.Totals
    let typical: StressDayTotals.Totals?
    /// How many earlier same weekdays the typical day averages.
    var typicalDays = 0

    private static let levels: [StressDayTotals.Level] = [.low, .medium, .high]

    var body: some View {
        PulseCard(.solid(HealthPalette.totalDayCard)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .healthGlyph(.cardIcon)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .accessibilityHidden(true)
                    PulseCardTitle(String(localized: "Total day"))
                }
                heading
                VStack(spacing: 8) {
                    bar(totals, height: 12,
                        colours: [HealthPalette.totalLow, HealthPalette.totalMedium, HealthPalette.totalHigh])
                    if let typical {
                        bar(typical, height: 8,
                            colours: [HealthPalette.typicalLow, HealthPalette.typicalMedium, HealthPalette.typicalHigh])
                    }
                }
                HStack(alignment: .top, spacing: 8) {
                    ForEach(Self.levels, id: \.rawValue) { level in
                        column(level)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Text(footnote)
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Total day"))
        .accessibilityValue(accessibility)
    }

    private var footnote: String {
        let base = String(localized: "Stress across your scored waking hours, counted by the hour. Your sleep is charted above as the Sleep dive scores it; hours you were moving are not scored.")
        guard typical != nil, typicalDays > 0 else { return base }
        return base + " " + String(localized: "Typical averages this weekday over \(typicalDays) earlier weeks you wore your strap.")
    }

    private var heading: some View {
        let date = PulseFormat.navDayTitle(dayKey: dayKey)
        let weekday = PulseFormat.dayLabel(dayKey, template: "EEEE")
        return (Text(String(localized: "\(date) stress")).foregroundColor(PulseTheme.textPrimary)
                + Text(typical == nil ? "" : " " + String(localized: "vs. typical \(weekday)"))
                    .foregroundColor(PulseTheme.textTertiary))
            .pulseText(.navTitle)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func bar(_ t: StressDayTotals.Totals, height: CGFloat, colours: [Color]) -> some View {
        GeometryReader { geo in
            let parts = Self.levels.map { t.minutes($0) }
            let shown = parts.filter { $0 > 0 }.count
            let gap: CGFloat = 2
            let usable = max(0, geo.size.width - gap * CGFloat(max(0, shown - 1)))
            let total = max(1, parts.reduce(0, +))
            HStack(spacing: gap) {
                ForEach(0..<3, id: \.self) { i in
                    if parts[i] > 0 {
                        Rectangle()
                            .fill(colours[i])
                            .frame(width: usable * CGFloat(parts[i]) / CGFloat(total))
                    }
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private func column(_ level: StressDayTotals.Level) -> some View {
        let minutes = totals.minutes(level)
        let change = typical.flatMap { StressDayTotals.percentChange(minutes, typical: $0.minutes(level)) }
        let hours = HealthFormat.stressHours(minutes: minutes)
        return VStack(alignment: .leading, spacing: 6) {
            PulseValueText(value: hours.value, unit: hours.unit, style: .rowValue, unitStyle: .tileUnit)
            if let change {
                PulseDeltaChip(text: "\(abs(change))%",
                               trend: PulseTrend(delta: Double(change), polarity: .neutral))
            }
            HStack(spacing: 5) {
                Rectangle().fill(colour(level)).frame(width: 10, height: 10)
                // A single word: it shrinks rather than breaking ("MEDIU / M").
                Text(PulseStressMonitorView.levelName(level))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func colour(_ level: StressDayTotals.Level) -> Color {
        switch level {
        case .low: return HealthPalette.totalLow
        case .medium: return HealthPalette.totalMedium
        case .high: return HealthPalette.totalHigh
        }
    }

    private var accessibility: String {
        Self.levels.map { level -> String in
            var text = "\(PulseStressMonitorView.levelName(level)) \(HealthFormat.spokenHours(minutes: totals.minutes(level)))"
            if let typical, let change = StressDayTotals.percentChange(totals.minutes(level), typical: typical.minutes(level)) {
                text += change >= 0 ? ", " + String(localized: "\(change) percent above typical")
                                    : ", " + String(localized: "\(-change) percent below typical")
            }
            return text
        }.joined(separator: "; ")
    }
}

/// Breathe opened on one pace (a `BreathProtocolCatalog` id) with that pace's recommended length: the
/// classic `BreathingView` in the wrapper every classic destination is pushed in (`PulseClassicScreen`).
struct HealthBreatheRoute: PulseScreenRoute {
    let protocolId: String
    var view: some View { PulseClassicScreen { BreathingView(preselectedProtocolId: protocolId) } }
}

/// "Sessions" (§3.22 item 8 [Z]): ZENO's guided breathing in WHOOP's slot, as WHOOP's session cards without
/// their artwork (whoop-site/20c: "INCREASE RELAXATION / Guided Breathing"). RELAX · COHERENCE · BOX · 4-7-8
/// · ALERTNESS sit in a row that scrolls sideways past the page margin, each opening Breathe on its own pace
/// with that pace's recommended length (`HealthBreatheRoute`).
struct HealthBreatheSession: View {
    /// One card: its caps title, its glyph and the Breathe pace it opens (a `BreathProtocolCatalog` id).
    struct Session: Identifiable {
        let id: String
        let title: String
        let symbol: String
    }

    static let sessions: [Session] = [
        Session(id: "relax_4_6", title: String(localized: "Relax"), symbol: "wind"),
        Session(id: "coherence_5_5", title: String(localized: "Coherence"), symbol: "waveform.path"),
        Session(id: "box_4_4_4_4", title: String(localized: "Box"), symbol: "square"),
        Session(id: "four_seven_eight", title: String(localized: "4-7-8"), symbol: "moon.zzz"),
        Session(id: "kapalabhati", title: String(localized: "Alertness"), symbol: "bolt")
    ]

    /// The first card's session, which the DEBUG `--pulse-stress-breathe` capture opens.
    static let destination = HealthBreatheRoute(protocolId: "relax_4_6")

    /// Opens a card's session.
    let onOpen: (HealthBreatheRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            HealthSectionHeader(title: String(localized: "Sessions"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PulseTheme.Layout.gridGap) {
                    ForEach(Self.sessions) { session in
                        Button { onOpen(HealthBreatheRoute(protocolId: session.id)) } label: { card(session) }
                            .buttonStyle(PulsePressStyle())
                            .accessibilityLabel(String(localized: "\(session.title), guided breathing"))
                            .accessibilityHint(String(localized: "Opens Breathe on this pace"))
                    }
                }
                // Every card as tall as the tallest, whatever its title wraps to.
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .padding(.horizontal, -PulseTheme.Layout.pageMargin)
        }
    }

    private func card(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: session.symbol)
                .healthGlyph(.sessionIcon)
                .foregroundStyle(PulseTheme.recoveryBlue)
                .accessibilityHidden(true)
            Spacer(minLength: 28)
            PulseCardTitle(session.title)
            Text(String(localized: "Guided Breathing"))
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textSecondary)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(width: 168, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .pulseCardBackground()
        .contentShape(Rectangle())
    }
}
#endif
