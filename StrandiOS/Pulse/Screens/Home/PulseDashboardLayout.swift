#if os(iOS)
import SwiftUI

// MARK: - My Dashboard's catalogue and stored layout (WHOOP_UI_SPEC §3.1 item 12, §3.13)

/// Everything My Dashboard can show: the metric rows WHOOP's dashboards and its ADD TO MY DASHBOARD list
/// carry that ZENO backs with its own data, plus the two chart cards. The raw values are the stored
/// layout's ids, so a case is never renamed.
///
/// Population items ([POP]) and ones ZENO has no data for are not offered.
enum PulseDashboardItem: String, CaseIterable, Identifiable, Hashable {
    case dayStrain = "day-strain"
    case sleepDebt = "sleep-debt"
    case sleepNeeded = "sleep-needed"
    case sleepConsistency = "sleep-consistency"
    case recovery
    case hrv
    case rhr
    case respiratoryRate = "respiratory-rate"
    case steps
    case weight
    case sleepPerformance = "sleep-performance"
    case hoursOfSleep = "hours-of-sleep"
    case restorativeSleep = "restorative-sleep"
    case calories
    case averageHeartRate = "average-heart-rate"
    case vo2Max = "vo2-max"
    case leanBodyMass = "lean-body-mass"
    case skinTemperature = "skin-temperature"
    case bloodOxygen = "blood-oxygen"
    case hrZones13 = "hr-zones-1-3"
    case hrZones45 = "hr-zones-4-5"
    case hrZonesAll = "hr-zones-all"
    case strengthActivityTime = "strength-activity-time"
    case stressMonitor = "stress-monitor"
    case strainRecovery = "strain-recovery"

    var id: String { rawValue }

    /// The two chart cards; every other item is a metric row.
    var isChart: Bool { self == .stressMonitor || self == .strainRecovery }

    /// The row's name, in the vocabulary Recovery and the Health tab use (the card style uppercases it).
    var title: String {
        switch self {
        case .dayStrain: return String(localized: "Day strain")
        case .sleepDebt: return String(localized: "Sleep debt")
        case .sleepNeeded: return String(localized: "Sleep needed")
        case .sleepConsistency: return String(localized: "Sleep consistency")
        case .recovery: return PulseScore.recovery.displayName
        case .hrv: return String(localized: "Heart rate variability")
        case .rhr: return String(localized: "Resting heart rate")
        case .respiratoryRate: return String(localized: "Respiratory rate")
        case .steps: return String(localized: "Steps")
        case .weight: return String(localized: "Weight")
        case .sleepPerformance: return String(localized: "Sleep performance")
        case .hoursOfSleep: return String(localized: "Hours of sleep")
        case .restorativeSleep: return String(localized: "Restorative sleep (%)")
        case .calories: return String(localized: "Calories")
        case .averageHeartRate: return String(localized: "Average heart rate")
        case .vo2Max: return String(localized: "VO₂ max")
        case .leanBodyMass: return String(localized: "Lean body mass")
        case .skinTemperature: return String(localized: "Skin temperature")
        case .bloodOxygen: return String(localized: "Blood oxygen")
        case .hrZones13: return String(localized: "HR zones 1-3 (weekly)")
        case .hrZones45: return String(localized: "HR zones 4-5 (weekly)")
        case .hrZonesAll: return String(localized: "HR zones all (weekly)")
        case .strengthActivityTime: return String(localized: "Strength activity time")
        case .stressMonitor: return String(localized: "Stress Monitor")
        case .strainRecovery: return String(localized: "Strain & Recovery")
        }
    }

    /// A line icon, ZENO's own pick from SF Symbols (WHOOP's glyphs are not copied).
    var symbol: String {
        switch self {
        case .dayStrain: return "dumbbell"
        case .sleepDebt: return "moon.zzz"
        case .sleepNeeded: return "bed.double"
        case .sleepConsistency: return "calendar"
        case .recovery: return "heart.circle"
        case .hrv: return "waveform.path.ecg"
        case .rhr: return "arrow.down.heart"
        case .respiratoryRate: return "lungs"
        case .steps: return "shoe"
        case .weight: return "scalemass"
        case .sleepPerformance: return "moon"
        case .hoursOfSleep: return "moon.stars"
        case .restorativeSleep: return "sparkles"
        case .calories: return "flame"
        case .averageHeartRate: return "heart"
        case .vo2Max: return "figure.run"
        case .leanBodyMass: return "figure.arms.open"
        case .skinTemperature: return "thermometer.medium"
        case .bloodOxygen: return "drop"
        case .hrZones13: return "heart.text.square"
        case .hrZones45: return "bolt.heart"
        case .hrZonesAll: return "heart.square"
        case .strengthActivityTime: return "figure.strengthtraining.traditional"
        case .stressMonitor: return "gauge.with.dots.needle.33percent"
        case .strainRecovery: return "chart.line.downtrend.xyaxis"
        }
    }

    /// Which direction is better, from the spec's table (`PulseMetricPolarity.forMetric`); weight,
    /// calories, average heart rate, Day Strain and the like have none and draw grey.
    var polarity: PulseMetricPolarity {
        switch self {
        case .dayStrain: return .forMetric("strain")
        case .sleepDebt: return .forMetric("sleep_debt")
        case .sleepNeeded: return .forMetric("sleep_needed")
        case .sleepConsistency: return .forMetric("sleep_consistency")
        case .recovery: return .forMetric("recovery")
        case .hrv: return .forMetric("hrv")
        case .rhr: return .forMetric("rhr")
        case .respiratoryRate: return .forMetric("resp_rate")
        case .steps: return .forMetric("steps")
        case .sleepPerformance: return .forMetric("sleep_performance")
        case .hoursOfSleep: return .forMetric("hours")
        case .restorativeSleep: return .forMetric("restorative")
        case .vo2Max: return .forMetric("vo2max")
        case .hrZones13: return .forMetric("hr_zones_1_3")
        case .hrZones45: return .forMetric("hr_zones_4_5")
        case .hrZonesAll: return .forMetric("zones")
        case .strengthActivityTime: return .forMetric("strength_time")
        case .weight, .calories, .averageHeartRate, .leanBodyMass, .skinTemperature, .bloodOxygen,
             .stressMonitor, .strainRecovery:
            return .neutral
        }
    }

    /// The `MetricCatalog` key the Trend View opens for this row (`.trendView(metric:)`).
    var trendMetric: String {
        switch self {
        case .dayStrain: return "strain"
        case .sleepDebt: return "sleep_debt_min"
        case .sleepNeeded: return "sleep_need_min"
        case .sleepConsistency: return "sleep_consistency"
        case .recovery, .strainRecovery: return "recovery"
        case .hrv: return "hrv"
        case .rhr: return "rhr"
        case .respiratoryRate: return "resp_rate"
        case .steps: return "steps"
        case .weight: return "weight"
        case .sleepPerformance: return "sleep_performance"
        case .hoursOfSleep: return "sleep_total_min"
        case .restorativeSleep: return "restorative_pct"
        case .calories: return "energy_kcal"
        case .averageHeartRate: return "avg_hr"
        case .vo2Max: return "vo2max_est"
        case .leanBodyMass: return "lean_mass"
        case .skinTemperature: return "skin_temp"
        case .bloodOxygen: return "spo2"
        case .hrZones13: return "hr_zones13_min"
        case .hrZones45: return "hr_zones45_min"
        case .hrZonesAll: return "hr_zones_all_min"
        case .strengthActivityTime: return "strength_min"
        case .stressMonitor: return "stress"
        }
    }

    /// The classic screen a row opens until the Trend View is rebuilt (`PulseTrendView.isRebuilt`).
    var classicRoute: PulseRoute {
        switch self {
        case .steps: return .tab(.steps(day: nil))
        case .stressMonitor: return PulseRoute.stressMonitor.forExistingEntryPoint
        default: return .tab(.metric(trendMetric))
        }
    }
}

/// My Dashboard's order and selection, stored as comma-separated item ids under `storageKey`. A device
/// preference only (Pulse's own; not part of the .noopbak whitelist).
enum PulseDashboardLayout {
    static let storageKey = "pulse.dashboard.items"

    /// The first-run dashboard: WHOOP's new-member set, in its order (§3.1 item 12 [C]). Everything else,
    /// ZENO's extras included, waits in ADD TO MY DASHBOARD.
    static let defaultItems: [PulseDashboardItem] = [.hrv, .sleepPerformance, .steps, .calories, .stressMonitor]

    /// The stored layout; an empty or unreadable value is the default (a stored layout is never empty).
    static func decode(_ stored: String) -> [PulseDashboardItem] {
        var seen = Set<PulseDashboardItem>()
        let items = stored.split(separator: ",").compactMap { PulseDashboardItem(rawValue: String($0)) }
            .filter { seen.insert($0).inserted }
        return items.isEmpty ? defaultItems : items
    }

    static func encode(_ items: [PulseDashboardItem]) -> String {
        items.map(\.rawValue).joined(separator: ",")
    }

    /// The items the layout leaves out, in catalogue order (the ADD TO MY DASHBOARD list).
    static func hidden(from visible: [PulseDashboardItem]) -> [PulseDashboardItem] {
        PulseDashboardItem.allCases.filter { !visible.contains($0) }
    }
}
#endif
