#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Stress Monitor (WHOOP_UI_SPEC §3.22), pushed from Home's tile and dashboard card and the Health tab's
/// card: its own day pager ("‹ TODAY ›"), the gauge with ⓘ, the 24 h chart, plain sentences on the day,
/// TOTAL DAY against the typical same weekday, and Sessions into Breathe.
///
/// One source for the level and the curve (`PulseSnapshotBuilder.stressDay`): the gauge shows the curve's
/// latest scored hour, and only a day without a curve falls back to the daily score, labelled as such.
/// There is no ⚙: ZENO has no stress notifications to configure.
struct PulseStressMonitorView: View {
    /// Rebuilt: existing entry points (Home's tile and dashboard card) open this instead of the classic screen.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    /// Days back from today; the screen pages on its own, whatever day Home shows (§1.7).
    @State private var offset = 0
    @State private var snapshot: StressMonitorSnapshot?
    @State private var showsInfo = false

    private var shown: StressMonitorSnapshot? {
        guard let snapshot, snapshot.day.dayKey == dayKey(offset) else { return nil }
        return snapshot
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Stress Monitor"), coach: .button, coachSeed: coachSeed,
                            spacing: 0, topPadding: 0, ready: shown != nil) {
            HealthPager(title: shown?.title ?? pagerTitle, canGoBack: offset < model.maxDayOffset,
                        canGoForward: offset > 0,
                        onBack: { offset = min(model.maxDayOffset, offset + 1) },
                        onForward: { offset = max(0, offset - 1) })
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
        .task(id: "\(model.healthKey)|\(offset)") {
            let day = offset
            if let s = await model.build(dayOffset: day, { builder, request in await builder.stressMonitor(request) }) {
                if snapshot != s { snapshot = s }
            }
        }
        .sheet(isPresented: $showsInfo) {
            HealthInfoSheet(title: String(localized: "How stress is scored"), paragraphs: Self.infoParagraphs)
        }
    }

    /// The local key of the day `offset` back (the snapshot carries the same key).
    private func dayKey(_ offset: Int) -> String {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date())) ?? Date()
        return Repository.localDayKey(start)
    }

    private var pagerTitle: String {
        offset == 0 ? String(localized: "Today") : PulseFormat.navDayTitle(dayKey: dayKey(offset))
    }

    @ViewBuilder
    private func content(_ s: StressMonitorSnapshot) -> some View {
        let gauge = s.day.gaugeLevel
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                HealthStressGauge(level: gauge?.level, caption: gaugeCaption(s))
                    .frame(maxWidth: .infinity)
                PulseInfoButton(accessibilityLabel: String(localized: "How stress is scored")) { showsInfo = true }
                    .offset(x: 6, y: -2)
            }
            .padding(.top, 22)

            HealthStressDayChart(points: s.day.points, periods: s.periods, window: s.day.window,
                                 now: s.day.isToday ? s.day.window.upperBound : nil,
                                 currentLevel: gauge?.level,
                                 emptyMessage: s.day.isToday
                                    ? String(localized: "The day fills in as your strap records heart rate.")
                                    : String(localized: "No stress readings for this day."))
                .id("pulse.chart")
                .padding(.top, 26)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(sentences(s).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 28)

            if s.totals.scoredMinutes > 0 {
                HealthTotalDayCard(dayKey: s.day.dayKey, totals: s.totals, typical: s.typical)
                    .id("pulse.total")
                    .padding(.top, 28)
            }

            PulseTextCTA(title: String(localized: "See trends")) {
                navigator.open(PulseRoute.trendView(metric: "stress").forExistingEntryPoint)
            }
            .padding(.top, 8)

            HealthBreatheSessions(onOpen: { navigator.open(.classic(.breathe)) })
                .id("pulse.sessions")
                .padding(.top, 32)
        }
    }

    /// The gauge's line: the reading's time, with its day when it is not the day shown, or what the value is.
    private func gaugeCaption(_ s: StressMonitorSnapshot) -> String? {
        if let latest = s.day.latest {
            let sameDay = Repository.localDayKey(latest.at) == s.day.dayKey
            if sameDay { return PulseFormat.clock(latest.at) }
            let weekday = latest.at.formatted(.dateTime.weekday(.abbreviated).locale(AppLanguage.activeLocale))
            return "\(weekday) \(PulseFormat.clock(latest.at))"
        }
        if s.day.daily != nil { return String(localized: "Daily score from your vitals") }
        return nil
    }

    /// Plain sentences on the day (completeness-critic/14, 15; the App Store mock's longest-run line), every
    /// figure from the snapshot.
    private func sentences(_ s: StressMonitorSnapshot) -> [String] {
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
                ? String(localized: "You've spent \(Self.minutesText(t.highMinutes)) in the high stress zone so far today.")
                : String(localized: "You spent \(Self.minutesText(t.highMinutes)) in the high stress zone on this day."))
        } else if let dominant = t.dominant {
            let zone = Self.levelName(dominant)
            out.append(s.day.isToday
                ? String(localized: "Most of your scored time today has been in the \(zone) stress zone.")
                : String(localized: "Most of your scored time on this day was in the \(zone) stress zone."))
        }
        if let typical = s.typical {
            let diff = t.highMinutes - typical.highMinutes
            if abs(diff) < 5 {
                out.append(String(localized: "That's about the same as a typical \(weekday)."))
            } else if diff < 0 {
                out.append(String(localized: "That's \(Self.minutesText(-diff)) less than a typical \(weekday)."))
            } else {
                out.append(String(localized: "That's \(Self.minutesText(diff)) more than a typical \(weekday)."))
            }
        }
        if let run = s.longestHigh {
            out.append(String(localized: "Your longest stretch of high stress started at \(PulseFormat.clock(run.start)) and lasted \(Self.minutesText(run.minutes))."))
        }
        if let masked = stressActivityMaskedHoursCaption(s.day.maskedHours) { out.append(masked) }
        return out
    }

    static func minutesText(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return String(localized: "\(m) min") }
        if m == 0 { return h == 1 ? String(localized: "1 hour") : String(localized: "\(h) hours") }
        return String(localized: "\(h) hr \(m) min")
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
            parts.append(String(localized: "high \(PulseFormat.hoursMinutes(Double(s.totals.highMinutes))), medium \(PulseFormat.hoursMinutes(Double(s.totals.mediumMinutes))), low \(PulseFormat.hoursMinutes(Double(s.totals.lowMinutes)))"))
        }
        if let typical = s.typical {
            parts.append(String(localized: "typical high \(PulseFormat.hoursMinutes(Double(typical.highMinutes)))"))
        }
        return parts.joined(separator: "; ")
    }

    static let infoParagraphs: [String] = [
        String(localized: "ZENO reads stress from your heart rate, and the beat-to-beat timing when the strap records it, across your waking hours (6 AM to 10 PM). Each hour is set against your calmest hours that day, or against your own daytime baseline if you turned that on in Settings, and placed on a 0 to 3 scale: low under 1.0, medium to 1.9, high from 2.0."),
        String(localized: "Hours when the strap saw you moving are left out, so a workout or a walk is not read as stress. Sleep is not scored."),
        String(localized: "The Today view shows the last 24 hours. The gauge shows your latest scored hour; on a day without hourly readings it shows that day's score from your resting heart rate and HRV against your baseline."),
        String(localized: "Typical is the average of the same weekday over the previous six weeks you wore the strap, up to the same hour when the day is still going. A wellness estimate, not a diagnosis."),
    ]
}

/// TOTAL DAY (§3.22 item 6; completeness-critic/14): "SUN, AUG 2 STRESS VS. TYPICAL SUNDAY", the day's
/// time LOW / MEDIUM / HIGH as a 12 pt bar over the typical day's 6 pt bar at half strength, then each band's
/// time, its change against typical (grey chips) and its name. On the dimmer card WHOOP draws it on.
struct HealthTotalDayCard: View {
    let dayKey: String
    let totals: StressDayTotals.Totals
    let typical: StressDayTotals.Totals?

    private static let levels: [StressDayTotals.Level] = [.low, .medium, .high]

    var body: some View {
        PulseCard(.solid(HealthPalette.totalDayCard)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(PulseTheme.textSecondary)
                        .accessibilityHidden(true)
                    PulseCardTitle(String(localized: "Total day"))
                }
                heading
                VStack(spacing: 8) {
                    bar(totals, height: 12, colours: [PulseTheme.Stress.low, PulseTheme.Stress.medium, PulseTheme.Stress.high])
                    if let typical {
                        bar(typical, height: 6,
                            colours: [HealthPalette.typicalLow, HealthPalette.typicalMedium, HealthPalette.typicalHigh])
                    }
                }
                HStack(alignment: .top, spacing: 8) {
                    ForEach(Self.levels, id: \.rawValue) { level in
                        column(level)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Text(String(localized: "Stress across your scored waking hours. Sleep, and hours you were moving, are not scored."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Total day"))
        .accessibilityValue(accessibility)
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
        return VStack(alignment: .leading, spacing: 6) {
            Text(PulseFormat.hoursMinutes(Double(minutes)))
                .font(PulseType.font(.calloutValue))
                .foregroundStyle(PulseTheme.textPrimary)
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
        case .low: return PulseTheme.Stress.low
        case .medium: return PulseTheme.Stress.medium
        case .high: return PulseTheme.Stress.high
        }
    }

    private var accessibility: String {
        Self.levels.map { level -> String in
            var text = "\(PulseStressMonitorView.levelName(level)) \(PulseFormat.duration(minutes: Double(totals.minutes(level))))"
            if let typical, let change = StressDayTotals.percentChange(totals.minutes(level), typical: typical.minutes(level)) {
                text += change >= 0 ? ", " + String(localized: "\(change) percent above typical")
                                    : ", " + String(localized: "\(-change) percent below typical")
            }
            return text
        }.joined(separator: "; ")
    }
}

/// "Sessions" (§3.22 item 8 [Z]): ZENO's Breathe in WHOOP's slot, as cards for five of its paces. Each opens
/// Breathe, where the pace is picked (the classic screen takes no preselected pace yet).
struct HealthBreatheSessions: View {
    let onOpen: () -> Void

    private struct Session: Identifiable {
        let id: String
        let title: String
        let detail: String
        let symbol: String
    }

    private var sessions: [Session] {
        let picks: [(String, String, String)] = [
            ("relax_4_6", String(localized: "Relax"), "leaf"),
            ("coherence_5_5", String(localized: "Coherence"), "waveform.path"),
            ("box_4_4_4_4", String(localized: "Box"), "square"),
            ("four_seven_eight", String(localized: "4-7-8"), "moon.zzz"),
            ("kapalabhati", String(localized: "Alertness"), "sun.max"),
        ]
        return picks.compactMap { id, title, symbol in
            guard let p = BreathProtocolCatalog.protocolById(id) else { return nil }
            return Session(id: id, title: title, detail: String(localized: String.LocalizationValue(p.subtitle)),
                           symbol: symbol)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.headerGap) {
            HealthSectionHeader(title: String(localized: "Sessions"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: PulseTheme.Layout.gridGap) {
                    ForEach(sessions) { session in
                        Button(action: onOpen) {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: session.symbol)
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundStyle(PulseTheme.recoveryBlue)
                                    .accessibilityHidden(true)
                                PulseWordWrapText(session.title, style: .cardTitle)
                                    .foregroundStyle(PulseTheme.textPrimary)
                                Text(session.detail)
                                    .pulseText(.secondary)
                                    .foregroundStyle(PulseTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .frame(width: 148, alignment: .topLeading)
                            .frame(minHeight: 132, alignment: .topLeading)
                            .pulseCardBackground()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .accessibilityLabel(session.title)
                        .accessibilityValue(session.detail)
                        .accessibilityHint(String(localized: "Opens Breathe"))
                    }
                }
            }
            .scrollClipDisabled()
            Text(String(localized: "Opens Breathe, where you choose the pace and can pace it with your strap."))
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
