#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// The My Dashboard views (WHOOP_UI_SPEC §3.1 item 12): the "My Dashboard" header with CUSTOMIZE ✎, the
/// metric rows (`PulseMetricRow`: value, ▲▼ by good / bad, the 30-day baseline) that open the Trend View,
/// and the STRESS MONITOR and STRAIN & RECOVERY chart cards. They replace the old KEY STATS grid and Stress
/// section.
///
/// Owned by group "home", which adds reordering and the Customize Dashboard set.
enum PulseDashboardViews {
    /// The whole My Dashboard section as Home places it.
    struct Section: View {
        let home: HomeSnapshot

        @Environment(\.pulseNavigator) private var navigator

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                PulseSectionHeader(String(localized: "My Dashboard"),
                                   accessory: .customize { navigator.open(.customizeDashboard) })
                    .id("pulse.dashboard")
                VStack(spacing: PulseTheme.Layout.gridGap) {
                    ForEach(home.stats) { stat in
                        PulseLink(route(stat)) { row(stat) }
                            .buttonStyle(PulsePressStyle())
                    }
                    StressCard(home: home)
                        .id("pulse.stress")
                    StrainRecoveryCard(home: home)
                        .id("pulse.strain-recovery")
                }
                .padding(.top, PulseTheme.Layout.headerGap)
            }
        }

        /// The Trend View once it is rebuilt, else the metric's current detail screen.
        private func route(_ stat: PulseKeyStat) -> PulseRoute {
            PulseRoute.trendView(metric: stat.id).isRebuilt ? .trendView(metric: stat.id) : .tab(stat.route)
        }

        private func row(_ stat: PulseKeyStat) -> PulseMetricRow {
            let hasValue = stat.value != "–"
            return PulseMetricRow(symbol: Self.symbol(stat.id), title: Self.title(stat),
                                  value: hasValue ? stat.value : nil,
                                  unit: stat.unit.isEmpty ? nil : stat.unit,
                                  trend: stat.baselineDelta.map { delta in
                                      PulseTrend(delta: delta, polarity: PulseMetricPolarity.forMetric(stat.id))
                                  } ?? stat.comparison.map { c in
                                      PulseTrend(direction: Self.direction(c.direction),
                                                 polarity: PulseMetricPolarity.forMetric(stat.id))
                                  },
                                  baseline: stat.baseline)
        }

        /// The dashboard's names: the ones Recovery and the Health tab use, never abbreviations.
        private static func title(_ stat: PulseKeyStat) -> String {
            switch stat.id {
            case "hrv": return String(localized: "Heart rate variability")
            case "rhr": return String(localized: "Resting heart rate")
            case "resp": return String(localized: "Respiratory rate")
            case "skin": return String(localized: "Skin temperature")
            case "spo2": return String(localized: "Blood oxygen")
            default: return stat.title
            }
        }

        private static func symbol(_ id: String) -> String {
            switch id {
            case "hrv": return "waveform.path.ecg"
            case "rhr": return "heart"
            case "resp": return "lungs"
            case "skin": return "thermometer.medium"
            case "spo2": return "drop"
            case "steps": return "figure.walk"
            case "kcal": return "flame"
            default: return "circle"
            }
        }

        private static func direction(_ d: PulseDisplay.Direction) -> PulseTrend.Direction {
            switch d {
            case .up: return .up
            case .down: return .down
            case .flat: return .flat
            }
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
#endif
