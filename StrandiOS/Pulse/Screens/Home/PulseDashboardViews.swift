#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The My Dashboard views (WHOOP_UI_SPEC §3.1 item 12): the "My Dashboard" header with CUSTOMIZE ✎, the
/// wearer's items in their chosen order (`PulseDashboardLayout`), each metric row's value with ▲▼ by good /
/// bad and the 30-day baseline, and the STRESS MONITOR and STRAIN & RECOVERY chart cards. While the strap is
/// still personalizing, the pencil hides and "Personalization in Progress" leads the list.
///
/// Owned by group "home". Rows open the Trend View once it is rebuilt (group "trends"), else the metric's
/// current detail screen.
enum PulseDashboardViews {
    /// The whole My Dashboard section as Home places it.
    struct Section: View {
        let home: HomeSnapshot
        /// Home's own facts for the same day; nil while they build (rows read label + "›" meanwhile).
        let extras: HomeExtrasSnapshot?
        let items: [PulseDashboardItem]
        /// Fewer than 7 scored days: the Personalization card shows and CUSTOMIZE hides.
        let personalizing: Bool

        @Environment(\.pulseNavigator) private var navigator

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                PulseSectionHeader(String(localized: "My Dashboard"),
                                   accessory: personalizing ? .none
                                                            : .customize { navigator.open(.customizeDashboard) })
                    .id("pulse.dashboard")
                VStack(spacing: PulseTheme.Layout.gridGap) {
                    if personalizing {
                        PersonalizationCard()
                    }
                    ForEach(items) { item in
                        switch item {
                        case .stressMonitor:
                            StressCard(home: home)
                                .id("pulse.stress")
                        case .strainRecovery:
                            StrainRecoveryCard(home: home)
                                .id("pulse.strain-recovery")
                        default:
                            let value = extras?.dashboard[item] ?? .empty(item.classicRoute)
                            PulseLink(route(item, value: value)) {
                                PulseDashboardMetricRow(item: item, value: value,
                                                        caption: value.captionText(dayKey: home.day.key))
                            }
                            .buttonStyle(PulsePressStyle())
                        }
                    }
                }
                .padding(.top, PulseTheme.Layout.headerGap)
            }
        }

        /// The Trend View once it is rebuilt, else the row's own detail screen.
        private func route(_ item: PulseDashboardItem, value: PulseDashboardValue) -> PulseRoute {
            let trend = PulseRoute.trendView(metric: item.trendMetric)
            return trend.isRebuilt ? trend : value.fallback
        }
    }

    /// "Personalization in Progress" (help-center/62, 67): an outlined card while the strap calibrates.
    struct PersonalizationCard: View {
        var body: some View {
            HStack(alignment: .center, spacing: PulseTheme.Space.s) {
                VStack(alignment: .leading, spacing: PulseTheme.Space.xxs) {
                    Text(String(localized: "Personalization in Progress"))
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "As your strap calibrates to your unique physiology, you'll gain insight into your trends here."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                PulseCalibratingArt()
            }
            .padding(.horizontal, PulseTheme.Layout.cardPadding + 4)
            .padding(.vertical, PulseTheme.Layout.cardPadding + 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulseCardBackground(.outlined)
            .accessibilityElement(children: .combine)
        }
    }

    /// STRESS MONITOR ›: "Last updated 10:15 PM" and "MEDIUM 1.1", then the day's stress chart (150 pt).
    struct StressCard: View {
        let home: HomeSnapshot

        var body: some View {
            PulseLink(PulseRoute.stressMonitor.forExistingEntryPoint) {
                PulseCard {
                    VStack(alignment: .leading, spacing: 12) {
                        PulseCardTitle(String(localized: "Stress Monitor"), accessory: .trailingChevron)
                        HStack(alignment: .firstTextBaseline) {
                            if let updated {
                                Text(String(localized: "Last updated \(updated)"))
                                    .pulseText(.secondary)
                                    .foregroundStyle(PulseTheme.textSecondary)
                            }
                            Spacer(minLength: 8)
                            if let score = home.stress?.score {
                                let level = PulseTheme.Stress.Level(value: score)
                                Text(levelWord(level))
                                    .pulseText(.label)
                                    .foregroundStyle(level.color)
                                Text(PulseFormat.oneDecimal(score))
                                    .pulseText(.rowValue)
                                    .foregroundStyle(PulseTheme.textPrimary)
                            }
                        }
                        PulseStressChart(points: points, periods: periods, now: home.day.isToday ? Date() : nil,
                                         currentLevel: home.stress?.score, xLabels: xLabels)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }

        private var points: [PulseTimeValue] {
            (home.stress?.hours ?? []).map { hour in
                PulseTimeValue(date: Date(timeIntervalSince1970: TimeInterval(hour.startTs + 1800)), value: hour.level)
            }
        }

        private var periods: [PulseChartPeriod] {
            var out: [PulseChartPeriod] = []
            if let night = home.lastNight, home.day.isToday {
                out.append(PulseChartPeriod(id: "sleep", start: night.onset, end: night.wake, kind: .sleep,
                                            symbol: "moon.fill"))
            }
            for w in home.workouts {
                out.append(PulseChartPeriod(id: w.id, start: w.start,
                                            end: w.start.addingTimeInterval(TimeInterval(w.durationMin * 60)),
                                            kind: .activity,
                                            symbol: WorkoutTypeIconography.systemSymbolName(for: w.sport)))
            }
            return out
        }

        private var updated: String? {
            guard let hour = home.stress?.hours.last(where: { $0.level != nil }) else { return nil }
            return PulseFormat.clock(min(Date(timeIntervalSince1970: TimeInterval(hour.startTs + 3600)), Date()))
        }

        /// The chart's x labels: four times across the span shown, the last one now.
        private var xLabels: [String] {
            let dates = points.map(\.date) + periods.flatMap { [$0.start, $0.end] }
            guard let lo = dates.min() else { return [] }
            let hi = home.day.isToday ? Date() : (dates.max() ?? lo)
            guard hi > lo else { return [] }
            let step = hi.timeIntervalSince(lo) / 3
            return (0...3).map { PulseFormat.clock(lo.addingTimeInterval(step * Double($0))) }
        }

        private func levelWord(_ level: PulseTheme.Stress.Level) -> String {
            switch level {
            case .low: return String(localized: "Low")
            case .medium: return String(localized: "Medium")
            case .high: return String(localized: "High")
            }
        }
    }

    /// STRAIN & RECOVERY ⓘ: the seven days ending on the selected one, Strain against Recovery.
    struct StrainRecoveryCard: View {
        let home: HomeSnapshot

        var body: some View {
            PulseLink(PulseRoute.trendView(metric: "recovery").forExistingEntryPoint) {
                PulseChartCard(String(localized: "Strain & Recovery"), accessory: .info) {
                    PulseStrainRecoveryChart(days: home.week.map { day in
                        PulseStrainRecoveryChart.Day(id: day.id,
                                                     label: PulseFormat.dayLabel(day.id, template: "EEE"),
                                                     sublabel: PulseFormat.dayLabel(day.id, template: "d"),
                                                     strain: day.strain, recovery: day.recovery)
                    }, highlightID: home.day.key)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }
    }
}

// MARK: - Metric row

/// A My Dashboard metric row (completeness-critic/16, reviews/r111): a ≈58 pt card, a 20 pt line icon at
/// 50% and the UPPERCASE name at the left; at the right the value (22 pt Bold condensed) with the 30-day
/// baseline under it, right-aligned to the value, and the 6 pt ▲▼ / ● hanging beside the value. A value
/// carried from an earlier day names that day under the row's name. With nothing to show, the name and a
/// white "›" only.
///
/// `PulseMetricRow` (Components/) draws the same row with the glyph inside the value column and a grey
/// chevron; this keeps WHOOP's alignment and the carried-day line, which the dashboard needs.
struct PulseDashboardMetricRow: View {
    let item: PulseDashboardItem
    let value: PulseDashboardValue
    /// Whose day a carried value is ("Last night · 28 Sep"), shown under the name.
    var caption: String?

    var body: some View {
        HStack(spacing: PulseTheme.Space.s) {
            Image(systemName: item.symbol)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                PulseWordWrapText(item.title, style: .cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                if let caption, value.value != nil {
                    Text(caption)
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: PulseTheme.Space.xs)
            if let text = value.value {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    VStack(alignment: .trailing, spacing: 1) {
                        PulseValueText(value: text, unit: value.unit, style: .tileValue, unitStyle: .tileUnit,
                                       unitColor: value.unit == "%" ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                        if let baseline = value.baseline {
                            Text(baseline)
                                .pulseText(.baseline)
                                .foregroundStyle(PulseTheme.textTertiary)
                                .lineLimit(1)
                        }
                    }
                    PulseTrendGlyph(trend: value.trend ?? PulseTrend(direction: .flat, polarity: .neutral))
                        .opacity(value.trend == nil ? 0 : 1)
                        .alignmentGuide(.firstTextBaseline) { d in d[.bottom] + 5 }
                }
                .fixedSize()
            } else {
                PulseChevron(color: PulseTheme.textPrimary, size: 16)
            }
        }
        .padding(.leading, PulseTheme.Layout.cardPadding)
        .padding(.trailing, PulseTheme.Space.s)
        .padding(.vertical, PulseTheme.Space.xs)
        .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.dashboard, alignment: .leading)
        .pulseCardBackground()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityValue(spoken)
        .accessibilityAddTraits(.isButton)
    }

    private var spoken: String {
        guard let text = value.value else { return String(localized: "No data yet") }
        var parts = [[text, value.unit].compactMap { $0 }.joined(separator: " ")]
        if let caption { parts.append(caption) }
        if let trend = value.trend { parts.append(trend.accessibilityDescription) }
        if let baseline = value.baseline { parts.append(String(localized: "30-day average \(baseline)")) }
        return parts.joined(separator: ", ")
    }
}

/// ZENO's own art for a calibrating strap: the band outline with a heartbeat line through it.
struct PulseCalibratingArt: View {
    var body: some View {
        ZStack {
            PulseStrapShape()
                .stroke(PulseTheme.textTertiary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .frame(width: 40, height: 62)
            Image(systemName: "waveform.path")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(PulseTheme.recoveryBlue)
        }
        .frame(width: 84, height: 66)
        .accessibilityHidden(true)
    }
}
#endif
