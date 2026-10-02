#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Trend View metrics (WHOOP_UI_SPEC §3.12 "Metrics to support", §3.35)
//
// Every metric the Trend View can chart, named in Pulse's vocabulary (Recovery / Strain / Sleep, Strain on
// 0–21), with what its header says, how its values print, how its chart is drawn and where its numbers come
// from. The WHOOP metrics are spelled out below; any other `MetricCatalog` key falls back to a generic
// entry built from the catalog, so every metric the app stores has a Trend View.

/// The pillar a metric belongs to: the Trends tab's sections and the metric picker's groups.
enum PulseTrendPillar: String, CaseIterable, Identifiable, Hashable, Sendable {
    case sleep, recovery, strain, stress, body

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: return PulseScore.sleep.displayName
        case .recovery: return PulseScore.recovery.displayName
        case .strain: return PulseScore.strain.displayName
        case .stress: return String(localized: "Stress")
        case .body: return String(localized: "Body")
        }
    }
}

/// How a metric's values print.
enum PulseTrendValueFormat: Equatable, Hashable, Sendable {
    /// "47".
    case whole
    /// "15.5".
    case oneDecimal
    /// "9,706".
    case grouped
    /// Minutes as "7:40".
    case duration
    /// A signed one-decimal value ("+0.3"), a skin-temperature deviation.
    case signedOneDecimal

    func text(_ v: Double) -> String {
        switch self {
        case .whole: return PulseFormat.whole(v)
        case .oneDecimal: return PulseFormat.oneDecimal(v)
        case .grouped: return PulseFormat.grouped(v)
        case .duration: return PulseFormat.hoursMinutes(v)
        case .signedOneDecimal:
            let text = PulseFormat.oneDecimal(v)
            // A value that rounds to zero never keeps a sign ("-0.0" reads as a fault).
            if PulseFormat.oneDecimal(abs(v)) == PulseFormat.oneDecimal(0) { return PulseFormat.oneDecimal(0) }
            return v > 0 ? "+" + text : text
        }
    }

    /// The value rounded the way it prints, so a comparison or a count never disagrees with the text.
    func printed(_ v: Double) -> Double {
        switch self {
        case .whole, .grouped: return v.rounded()
        case .oneDecimal, .signedOneDecimal: return (v * 10).rounded() / 10
        case .duration: return v.rounded()
        }
    }
}

/// How the y axis is laid out.
enum PulseTrendScale: Equatable, Hashable, Sendable {
    /// 0–100%, gridlines every 25.
    case percent
    /// 0–100% with gridlines at 0 / 33 / 66 / 100, labelled in the Recovery band colours.
    case recovery
    /// Strain's 0–21, gridlines 0 / 5 / 10 / 15 / 21 (deep-dives-2026/44).
    case strain
    /// Stress's 0–3.
    case stress
    /// From 0 to a round number above the largest value (steps, calories, minutes).
    case zeroBased
    /// Around the data and its typical range, never pinned to 0 (heart rate, HRV).
    case dynamic
    /// Dynamic, but never above 100% (sleep efficiency, blood oxygen).
    case dynamicPercent
}

/// One stacked part of a column (a zone, a sleep stage), bottom to top.
struct PulseTrendPart: Equatable, Hashable, Identifiable {
    let id: String
    let title: String
    let color: Color
}

/// What the chart draws.
enum PulseTrendChartKind: Equatable, Hashable {
    /// One bar per day.
    case bars
    /// A line through the days with hollow markers.
    case line
    /// Stacked parts per column with a total above (zones, restorative sleep).
    case stacked([PulseTrendPart])
    /// Two lines: hours of sleep against the need (HOURS VS. NEEDED (HOURS)).
    case hoursVsNeed
}

/// How a period's headline value is aggregated.
enum PulseTrendAggregation: Equatable, Hashable, Sendable {
    /// The mean of the days.
    case average
    /// The total of a week's days, averaged across complete weeks past W ("WEEKLY TOTAL",
    /// "AVG. WEEKLY TOTAL").
    case weeklyTotal
}

/// Where a metric's daily values come from.
enum PulseTrendSource: Equatable, Hashable, Sendable {
    /// A merged daily-row column (the values Home and the dives read).
    case daily(PulseTrendDailyField)
    /// The night's sleep performance through the Sleep dial's resolver.
    case sleepPerformance
    /// A per-night sleep figure through `Repository.resolvedNightSleep`.
    case night(PulseTrendNightField)
    /// Restorative sleep (deep + REM) from the stage minutes; `percent` divides by the time asleep.
    case restorative(percent: Bool)
    /// Hours asleep with the night's need beside them.
    case hoursVsNeed
    /// The one steps resolver (`StepsResolver`).
    case steps
    /// Active calories: Apple Health's imported figure, else the on-device estimate (Home's tile rule).
    case calories
    /// Minutes in heart-rate zones, derived from logged activities.
    case zones([Int])
    /// Minutes of strength activities, derived from logged activities.
    case strength
    /// The stored daily stress score (0–3).
    case stress
    /// ZENO's weekly VO₂ max estimate.
    case vo2Estimate
    /// Skin temperature, as a deviation from baseline or an absolute reading.
    case skinTemp
    /// Any other catalog series, through the Explore read path.
    case explore(key: String, source: String)
}

enum PulseTrendDailyField: String, Equatable, Hashable, Sendable {
    case recovery, hrv, rhr, resp, spo2, strain
}

enum PulseTrendNightField: String, Equatable, Hashable, Sendable {
    case need, consistency, debt, hoursVsNeeded
}

/// A row card at the end of the page that leads somewhere ("+ ADD ACTIVITY ›").
enum PulseTrendCTA: Equatable, Hashable {
    case addActivity
    case stepsGoal
}

/// A breakdown block's bands, highest first ("RECOVERY BREAKDOWN (DAYS)").
struct PulseTrendBreakdownSpec: Equatable, Hashable {
    struct Band: Equatable, Hashable {
        let name: String
        /// "(67-99%)".
        let range: String
        let color: Color
    }

    let title: String
    /// Inclusive lower bounds on the PRINTED value, one fewer than `bands`.
    let lowerBounds: [Double]
    let bands: [Band]
}

/// Everything the Trend View needs to know about one metric.
struct PulseTrendMetric: Identifiable, Equatable, Hashable {
    /// The `MetricCatalog` key the route carries.
    let key: String
    /// "Heart Rate Variability" (the dropdown uppercases it).
    let title: String
    /// The name inside a sentence: "HRV", "Recovery", "steps".
    let sentenceName: String
    let symbol: String
    let pillar: PulseTrendPillar
    /// The unit printed after the headline value ("ms", "%", "hr"); empty for none.
    let unit: String
    let format: PulseTrendValueFormat
    let scale: PulseTrendScale
    let chart: PulseTrendChartKind
    /// The series colour (bars, line, markers). Recovery and stress colour each value by its band.
    let color: Color
    /// Which direction is good, for the ▲▼ glyphs on the Trends tab.
    let polarity: PulseMetricPolarity
    /// The Trend View's chips and segments: grey for Recovery, Day Strain and Calories in every capture
    /// (§2.7), otherwise `polarity`.
    let chipPolarity: PulseMetricPolarity
    let aggregation: PulseTrendAggregation
    /// A total still counting today (Strain, steps, calories, stress): today is left out of averages.
    let isRunningTotal: Bool
    /// Draw the typical range band behind the line (HRV, RHR, RR, …).
    let showsTypicalRange: Bool
    /// "+ ADD ACTIVITY", "SET A STEPS GOAL …".
    let cta: PulseTrendCTA?
    let breakdown: PulseTrendBreakdownSpec?
    /// A footnote that always applies ("Zone time is derived from logged activities").
    let note: String?
    /// "What is Strength Activity Time?" and its paragraph.
    let explainer: [String]?
    let ranges: [PulseTrendMath.Range]
    let source: PulseTrendSource

    var id: String { key }

    /// The name on a Trends row, where WHOOP's dashboard names are shorter than the dropdown's.
    var rowTitle: String {
        switch key {
        case "sleep_total_min": return String(localized: "Hours of Sleep")
        case "hours_vs_needed_pct": return String(localized: "Hours vs. Needed")
        case "restorative_min": return String(localized: "Restorative Sleep")
        case "restorative_pct": return String(localized: "Restorative %")
        case "strength_min": return String(localized: "Strength Time")
        default: return title
        }
    }
}

// MARK: - The catalogue

extension PulseTrendMetric {

    /// The metrics in picker and Trends-tab order, by pillar.
    static let curated: [PulseTrendMetric] = [
        // Sleep
        sleepPerformance, hoursVsNeed, hoursVsNeededPercent, timeInBed, sleepConsistency,
        restorativeHours, restorativePercent, sleepEfficiency, sleepDebt, sleepNeed,
        // Recovery
        recovery, hrv, rhr, respiratoryRate, bloodOxygen, skinTemperature,
        // Strain
        dayStrain, steps, calories, zones13, zones45, strengthTime, vo2Max, averageHeartRate,
        // Stress
        dayStress,
        // Body
        weight, leanBodyMass, bodyFat
    ]

    /// The metric for a route's key: a curated metric (or one of its aliases), else a generic entry built
    /// from the `MetricCatalog`, else nil for a key the app does not know.
    static func resolve(_ key: String) -> PulseTrendMetric? {
        let canonical = aliases[key] ?? key
        if let curated = curated.first(where: { $0.key == canonical }) { return curated }
        return generic(key)
    }

    /// Catalog keys that open a curated metric under another key.
    private static let aliases: [String: String] = [
        "active_kcal": "energy_kcal",
        "steps_est": "steps",
        "hours_of_sleep": "sleep_total_min",
        "resting_hr": "rhr",
        "sleep": "sleep_performance"
    ]

    private static let allRanges: [PulseTrendMath.Range] = PulseTrendMath.Range.allCases

    // MARK: Sleep

    static let sleepPerformance = PulseTrendMetric(
        key: "sleep_performance", title: String(localized: "Sleep Performance"),
        sentenceName: String(localized: "Sleep Performance"), symbol: "moon", pillar: .sleep, unit: "%",
        format: .whole, scale: .percent, chart: .bars, color: PulseTheme.sleep, polarity: .higherIsBetter,
        chipPolarity: .higherIsBetter, aggregation: .average, isRunningTotal: false, showsTypicalRange: false,
        cta: nil,
        breakdown: PulseTrendBreakdownSpec(
            title: String(localized: "Sleep performance breakdown"), lowerBounds: [85, 70],
            bands: [.init(name: String(localized: "Optimal"), range: "(85-100%)", color: PulseTheme.positive),
                    .init(name: String(localized: "Sufficient"), range: "(70-84%)", color: PulseTheme.sufficient),
                    .init(name: String(localized: "Poor"), range: "(0-69%)", color: PulseTheme.negative)]),
        note: nil, explainer: nil, ranges: allRanges, source: .sleepPerformance)

    static let hoursVsNeed = PulseTrendMetric(
        key: "sleep_total_min", title: String(localized: "Hours vs. Needed (Hours)"),
        sentenceName: String(localized: "hours of sleep"), symbol: "moon.zzz", pillar: .sleep,
        unit: String(localized: "hr"), format: .duration, scale: .zeroBased, chart: .hoursVsNeed,
        color: PulseTheme.sleep, polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .hoursVsNeed)

    static let hoursVsNeededPercent = PulseTrendMetric(
        key: "hours_vs_needed_pct", title: String(localized: "Hours vs. Needed (%)"),
        sentenceName: String(localized: "hours vs. needed"), symbol: "gauge.medium", pillar: .sleep, unit: "%",
        format: .whole, scale: .percent, chart: .bars, color: PulseTheme.sleep, polarity: .higherIsBetter,
        chipPolarity: .higherIsBetter, aggregation: .average, isRunningTotal: false, showsTypicalRange: false,
        cta: nil, breakdown: nil, note: nil, explainer: nil, ranges: allRanges, source: .night(.hoursVsNeeded))

    static let timeInBed = PulseTrendMetric(
        key: "in_bed_min", title: String(localized: "Time in Bed"), sentenceName: String(localized: "time in bed"),
        symbol: "bed.double", pillar: .sleep, unit: String(localized: "hr"), format: .duration,
        scale: .zeroBased, chart: .bars, color: PulseTheme.sleep, polarity: .neutral, chipPolarity: .neutral,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .explore(key: "in_bed_min", source: "my-whoop"))

    static let sleepConsistency = PulseTrendMetric(
        key: "sleep_consistency", title: String(localized: "Sleep Consistency"),
        sentenceName: String(localized: "sleep consistency"), symbol: "calendar", pillar: .sleep, unit: "%",
        format: .whole, scale: .percent, chart: .bars, color: PulseTheme.sleep, polarity: .higherIsBetter,
        chipPolarity: .higherIsBetter, aggregation: .average, isRunningTotal: false, showsTypicalRange: false,
        cta: nil,
        breakdown: PulseTrendBreakdownSpec(
            title: String(localized: "Sleep consistency breakdown"), lowerBounds: [80, 70],
            bands: [.init(name: String(localized: "Optimal"), range: "(80-100%)", color: PulseTheme.positive),
                    .init(name: String(localized: "Sufficient"), range: "(70-79%)", color: PulseTheme.sufficient),
                    .init(name: String(localized: "Poor"), range: "(0-69%)", color: PulseTheme.negative)]),
        note: nil, explainer: nil, ranges: allRanges, source: .night(.consistency))

    static let restorativeHours = PulseTrendMetric(
        key: "restorative_min", title: String(localized: "Restorative Sleep (Hours)"),
        sentenceName: String(localized: "restorative sleep"), symbol: "circle.dashed", pillar: .sleep,
        unit: String(localized: "hr"), format: .duration, scale: .zeroBased,
        chart: .stacked([PulseTrendPart(id: "rem", title: String(localized: "REM"), color: PulseTheme.Stage.rem),
                         PulseTrendPart(id: "deep", title: String(localized: "SWS (Deep)"), color: PulseTheme.Stage.deep)]),
        color: PulseTheme.Stage.rem, polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .restorative(percent: false))

    static let restorativePercent = PulseTrendMetric(
        key: "restorative_pct", title: String(localized: "Restorative Sleep (%)"),
        sentenceName: String(localized: "restorative sleep"), symbol: "circle.dashed", pillar: .sleep, unit: "%",
        format: .whole, scale: .percent, chart: .bars, color: PulseTheme.sleep, polarity: .higherIsBetter,
        chipPolarity: .higherIsBetter, aggregation: .average, isRunningTotal: false, showsTypicalRange: false,
        cta: nil,
        breakdown: PulseTrendBreakdownSpec(
            title: String(localized: "Restorative % breakdown"), lowerBounds: [46, 30],
            bands: [.init(name: String(localized: "High"), range: "(>45%)", color: PulseTheme.sleep),
                    .init(name: String(localized: "Sufficient"), range: "(30-45%)", color: PulseTheme.sleep.opacity(0.6)),
                    .init(name: String(localized: "Low"), range: "(<30%)", color: PulseTheme.sleep.opacity(0.35))]),
        note: nil, explainer: nil, ranges: allRanges, source: .restorative(percent: true))

    static let sleepEfficiency = PulseTrendMetric(
        key: "sleep_efficiency", title: String(localized: "Sleep Efficiency"),
        sentenceName: String(localized: "sleep efficiency"), symbol: "bed.double.fill", pillar: .sleep, unit: "%",
        format: .whole, scale: .dynamicPercent, chart: .line, color: PulseTheme.sleep, polarity: .higherIsBetter,
        chipPolarity: .higherIsBetter, aggregation: .average, isRunningTotal: false, showsTypicalRange: false,
        cta: nil,
        breakdown: PulseTrendBreakdownSpec(
            title: String(localized: "Sleep efficiency breakdown"), lowerBounds: [86, 70],
            bands: [.init(name: String(localized: "Optimal"), range: "(>85%)", color: PulseTheme.positive),
                    .init(name: String(localized: "Sufficient"), range: "(70-85%)", color: PulseTheme.sufficient),
                    .init(name: String(localized: "Poor"), range: "(<70%)", color: PulseTheme.negative)]),
        note: nil, explainer: nil, ranges: allRanges,
        source: .explore(key: "sleep_efficiency", source: "my-whoop"))

    static let sleepDebt = PulseTrendMetric(
        key: "sleep_debt_min", title: String(localized: "Sleep Debt"), sentenceName: String(localized: "sleep debt"),
        symbol: "hourglass", pillar: .sleep, unit: String(localized: "hr"), format: .duration, scale: .zeroBased,
        chart: .bars, color: PulseTheme.SleepDetail.sleepDebt, polarity: .lowerIsBetter,
        chipPolarity: .lowerIsBetter, aggregation: .average, isRunningTotal: false, showsTypicalRange: false,
        cta: nil, breakdown: nil, note: nil, explainer: nil, ranges: allRanges, source: .night(.debt))

    static let sleepNeed = PulseTrendMetric(
        key: "sleep_need_min", title: String(localized: "Sleep Need"), sentenceName: String(localized: "sleep need"),
        symbol: "gauge", pillar: .sleep, unit: String(localized: "hr"), format: .duration, scale: .dynamic,
        chart: .line, color: PulseTheme.positive, polarity: .lowerIsBetter, chipPolarity: .lowerIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .night(.need))

    // MARK: Recovery

    static let recovery = PulseTrendMetric(
        key: "recovery", title: PulseScore.recovery.displayName, sentenceName: PulseScore.recovery.displayName,
        symbol: "heart.circle", pillar: .recovery, unit: "%", format: .whole, scale: .recovery, chart: .bars,
        color: PulseTheme.recoveryHigh, polarity: .higherIsBetter, chipPolarity: .neutral, aggregation: .average,
        isRunningTotal: false, showsTypicalRange: false, cta: nil,
        breakdown: PulseTrendBreakdownSpec(
            title: String(localized: "Recovery breakdown"), lowerBounds: [67, 34],
            bands: [.init(name: String(localized: "Green"), range: "(67-100%)", color: PulseTheme.recoveryHigh),
                    .init(name: String(localized: "Yellow"), range: "(34-66%)", color: PulseTheme.recoveryMid),
                    .init(name: String(localized: "Red"), range: "(0-33%)", color: PulseTheme.recoveryLow)]),
        note: nil, explainer: nil, ranges: allRanges, source: .daily(.recovery))

    static let hrv = PulseTrendMetric(
        key: "hrv", title: String(localized: "Heart Rate Variability"), sentenceName: String(localized: "HRV"),
        symbol: "waveform.path.ecg", pillar: .recovery, unit: "ms", format: .whole, scale: .dynamic, chart: .line,
        color: PulseTheme.recoveryBlue, polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: true, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .daily(.hrv))

    static let rhr = PulseTrendMetric(
        key: "rhr", title: String(localized: "Resting Heart Rate"), sentenceName: String(localized: "RHR"),
        symbol: "heart", pillar: .recovery, unit: "bpm", format: .whole, scale: .dynamic, chart: .line,
        color: PulseTheme.recoveryBlue, polarity: .lowerIsBetter, chipPolarity: .lowerIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: true, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .daily(.rhr))

    static let respiratoryRate = PulseTrendMetric(
        key: "resp_rate", title: String(localized: "Respiratory Rate"),
        sentenceName: String(localized: "respiratory rate"), symbol: "lungs", pillar: .recovery, unit: "rpm",
        format: .oneDecimal, scale: .dynamic, chart: .line, color: PulseTheme.recoveryBlue,
        polarity: .lowerIsBetter, chipPolarity: .lowerIsBetter, aggregation: .average, isRunningTotal: false,
        showsTypicalRange: true, cta: nil, breakdown: nil, note: nil, explainer: nil, ranges: allRanges,
        source: .daily(.resp))

    static let bloodOxygen = PulseTrendMetric(
        key: "spo2", title: String(localized: "Blood Oxygen"), sentenceName: String(localized: "blood oxygen"),
        symbol: "drop", pillar: .recovery, unit: "%", format: .whole, scale: .dynamicPercent, chart: .line,
        color: PulseTheme.recoveryBlue, polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: true, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .daily(.spo2))

    static let skinTemperature = PulseTrendMetric(
        key: "skin_temp", title: String(localized: "Skin Temperature"),
        sentenceName: String(localized: "skin temperature"), symbol: "thermometer.medium", pillar: .recovery,
        unit: "", format: .oneDecimal, scale: .dynamic, chart: .line, color: PulseTheme.recoveryBlue,
        polarity: .neutral, chipPolarity: .neutral, aggregation: .average, isRunningTotal: false,
        showsTypicalRange: true, cta: nil, breakdown: nil, note: nil, explainer: nil, ranges: allRanges,
        source: .skinTemp)

    // MARK: Strain

    static let dayStrain = PulseTrendMetric(
        key: "strain", title: String(localized: "Day Strain"), sentenceName: String(localized: "Day Strain"),
        symbol: "speedometer", pillar: .strain, unit: "", format: .oneDecimal, scale: .strain, chart: .bars,
        color: PulseTheme.strain, polarity: .neutral, chipPolarity: .neutral, aggregation: .average,
        isRunningTotal: true, showsTypicalRange: false, cta: nil,
        breakdown: PulseTrendBreakdownSpec(
            title: String(localized: "Strain breakdown"), lowerBounds: [18.1, 14.1, 10.1],
            bands: [.init(name: String(localized: "All Out"), range: "(>18.0)", color: PulseTheme.Trends.strainShade(0)),
                    .init(name: String(localized: "Strenuous"), range: "(14.1-18.0)", color: PulseTheme.Trends.strainShade(1)),
                    .init(name: String(localized: "Moderate"), range: "(10.1-14.0)", color: PulseTheme.Trends.strainShade(2)),
                    .init(name: String(localized: "Light"), range: "(0-10.0)", color: PulseTheme.Trends.strainShade(3))]),
        note: nil, explainer: nil, ranges: allRanges, source: .daily(.strain))

    static let steps = PulseTrendMetric(
        key: "steps", title: String(localized: "Steps"), sentenceName: String(localized: "steps"),
        symbol: "figure.walk", pillar: .strain, unit: "", format: .grouped, scale: .zeroBased, chart: .bars,
        color: PulseTheme.strain, polarity: .higherIsBetter, chipPolarity: .higherIsBetter, aggregation: .average,
        isRunningTotal: true, showsTypicalRange: false, cta: .stepsGoal, breakdown: nil, note: nil,
        explainer: nil, ranges: allRanges, source: .steps)

    static let calories = PulseTrendMetric(
        key: "energy_kcal", title: String(localized: "Calories"), sentenceName: String(localized: "calories"),
        symbol: "flame", pillar: .strain, unit: "kcal", format: .grouped, scale: .zeroBased, chart: .bars,
        color: PulseTheme.strain, polarity: .neutral, chipPolarity: .neutral, aggregation: .average,
        isRunningTotal: true, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: String(localized: "Active calories: Apple Health's figure when it has one, else estimated from your heart rate"),
        explainer: nil, ranges: allRanges, source: .calories)

    static let zones13 = PulseTrendMetric(
        key: "hr_zones13_min", title: String(localized: "HR Zones 1-3"), sentenceName: String(localized: "HR zones 1-3"),
        symbol: "heart.text.square", pillar: .strain, unit: String(localized: "hr"), format: .duration,
        scale: .zeroBased,
        chart: .stacked([PulseTrendPart(id: "z1", title: String(localized: "Zone 1"), color: PulseTheme.Zone.color(1)),
                         PulseTrendPart(id: "z2", title: String(localized: "Zone 2"), color: PulseTheme.Zone.color(2)),
                         PulseTrendPart(id: "z3", title: String(localized: "Zone 3"), color: PulseTheme.Zone.color(3))]),
        color: PulseTheme.Zone.color(2), polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .weeklyTotal, isRunningTotal: false, showsTypicalRange: false, cta: .addActivity,
        breakdown: nil, note: String(localized: "Zone time is derived from logged activities"), explainer: nil,
        ranges: allRanges, source: .zones([1, 2, 3]))

    static let zones45 = PulseTrendMetric(
        key: "hr_zones45_min", title: String(localized: "HR Zones 4-5"), sentenceName: String(localized: "HR zones 4-5"),
        symbol: "heart.text.square.fill", pillar: .strain, unit: String(localized: "hr"), format: .duration,
        scale: .zeroBased,
        chart: .stacked([PulseTrendPart(id: "z4", title: String(localized: "Zone 4"), color: PulseTheme.Zone.color(4)),
                         PulseTrendPart(id: "z5", title: String(localized: "Zone 5"), color: PulseTheme.Zone.color(5))]),
        color: PulseTheme.Zone.color(4), polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .weeklyTotal, isRunningTotal: false, showsTypicalRange: false, cta: .addActivity,
        breakdown: nil, note: String(localized: "Zone time is derived from logged activities"), explainer: nil,
        ranges: allRanges, source: .zones([4, 5]))

    static let strengthTime = PulseTrendMetric(
        key: "strength_min", title: String(localized: "Strength Activity Time"),
        sentenceName: String(localized: "strength activity time"), symbol: "dumbbell", pillar: .strain,
        unit: String(localized: "hr"), format: .duration, scale: .zeroBased, chart: .bars, color: PulseTheme.strain,
        polarity: .higherIsBetter, chipPolarity: .higherIsBetter, aggregation: .weeklyTotal,
        isRunningTotal: false, showsTypicalRange: false, cta: .addActivity, breakdown: nil,
        note: String(localized: "Strength time is derived from logged activities"),
        explainer: [String(localized: "What is Strength Activity Time?"),
                    String(localized: "The time you spend in strength activities you log, such as weightlifting or strength training, counted from each activity's start to its end.")],
        ranges: allRanges, source: .strength)

    static let vo2Max = PulseTrendMetric(
        key: "vo2max_est", title: String(localized: "VO₂ Max"), sentenceName: String(localized: "VO₂ max"),
        symbol: "lungs.fill", pillar: .strain, unit: "mL/kg/min", format: .oneDecimal, scale: .dynamic,
        chart: .line, color: PulseTheme.recoveryBlue, polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: [.month, .sixMonths, .year, .all], source: .vo2Estimate)

    static let averageHeartRate = PulseTrendMetric(
        key: "avg_hr", title: String(localized: "Average Heart Rate"),
        sentenceName: String(localized: "average heart rate"), symbol: "waveform.path", pillar: .strain,
        unit: "bpm", format: .whole, scale: .dynamic, chart: .line, color: PulseTheme.strain, polarity: .neutral,
        chipPolarity: .neutral, aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil,
        breakdown: nil, note: nil, explainer: nil, ranges: allRanges,
        source: .explore(key: "avg_hr", source: "my-whoop"))

    // MARK: Stress

    static let dayStress = PulseTrendMetric(
        key: "stress", title: String(localized: "Day Stress"), sentenceName: String(localized: "stress"),
        symbol: "gauge.with.dots.needle.50percent", pillar: .stress, unit: "", format: .oneDecimal,
        scale: .stress, chart: .bars, color: PulseTheme.Stress.medium, polarity: .lowerIsBetter,
        chipPolarity: .lowerIsBetter, aggregation: .average, isRunningTotal: true, showsTypicalRange: false,
        cta: nil,
        breakdown: PulseTrendBreakdownSpec(
            title: String(localized: "Stress breakdown"), lowerBounds: [2.0, 1.0],
            bands: [.init(name: String(localized: "High"), range: "(2.0-3.0)", color: PulseTheme.Stress.high),
                    .init(name: String(localized: "Medium"), range: "(1.0-1.9)", color: PulseTheme.Stress.medium),
                    .init(name: String(localized: "Low"), range: "(0.0-0.9)", color: PulseTheme.Stress.low)]),
        note: nil, explainer: nil, ranges: allRanges, source: .stress)

    // MARK: Body

    static let weight = PulseTrendMetric(
        key: "weight", title: String(localized: "Weight"), sentenceName: String(localized: "weight"),
        symbol: "scalemass", pillar: .body, unit: "kg", format: .oneDecimal, scale: .dynamic, chart: .line,
        color: PulseTheme.recoveryBlue, polarity: .neutral, chipPolarity: .neutral, aggregation: .average,
        isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil, note: nil, explainer: nil,
        ranges: allRanges, source: .explore(key: "weight", source: "apple-health"))

    static let leanBodyMass = PulseTrendMetric(
        key: "lean_mass", title: String(localized: "Lean Body Mass"), sentenceName: String(localized: "lean body mass"),
        symbol: "figure.arms.open", pillar: .body, unit: "kg", format: .oneDecimal, scale: .dynamic, chart: .line,
        color: PulseTheme.recoveryBlue, polarity: .higherIsBetter, chipPolarity: .higherIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .explore(key: "lean_mass", source: "apple-health"))

    static let bodyFat = PulseTrendMetric(
        key: "body_fat", title: String(localized: "Body Fat"), sentenceName: String(localized: "body fat"),
        symbol: "percent", pillar: .body, unit: "%", format: .oneDecimal, scale: .dynamicPercent, chart: .line,
        color: PulseTheme.recoveryBlue, polarity: .lowerIsBetter, chipPolarity: .lowerIsBetter,
        aggregation: .average, isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil,
        note: nil, explainer: nil, ranges: allRanges, source: .explore(key: "body_fat", source: "apple-health"))

    // MARK: Any other catalog metric

    /// A metric the curated list does not name, from its `MetricCatalog` entry: its own title, icon,
    /// unit and direction, a line chart (bars for minutes and counts), and the Explore read path.
    private static func generic(_ key: String) -> PulseTrendMetric? {
        guard let d = MetricCatalog.all.first(where: { $0.key == key }) else { return nil }
        let pillar: PulseTrendPillar
        switch d.category {
        case "Rest": pillar = .sleep
        case "Charge": pillar = .recovery
        case "Effort", "Heart": pillar = .strain
        case "Mind": pillar = .stress
        default: pillar = d.key == "stress" ? .stress : .body
        }
        let isMinutes = d.unit == "min"
        let isCount = d.unit.isEmpty || d.unit == "steps" || d.unit == "kcal"
        let format: PulseTrendValueFormat = isMinutes ? .duration
            : (d.decimals > 0 ? .oneDecimal : (isCount ? .grouped : .whole))
        let polarity: PulseMetricPolarity = d.higherIsBetter.map { $0 ? .higherIsBetter : .lowerIsBetter } ?? .neutral
        let color: Color = pillar == .sleep ? PulseTheme.sleep : (pillar == .strain ? PulseTheme.strain : PulseTheme.recoveryBlue)
        return PulseTrendMetric(
            key: d.key, title: d.title, sentenceName: d.title.lowercased(), symbol: d.icon, pillar: pillar,
            unit: isMinutes ? String(localized: "hr") : d.unit, format: format,
            scale: isMinutes || isCount ? .zeroBased : .dynamic, chart: isMinutes || isCount ? .bars : .line,
            color: color, polarity: polarity, chipPolarity: polarity, aggregation: .average,
            isRunningTotal: false, showsTypicalRange: false, cta: nil, breakdown: nil, note: nil, explainer: nil,
            ranges: allRanges, source: .explore(key: d.key, source: d.source))
    }
}

// MARK: - Range words

extension PulseTrendMath.Range {
    /// The segment's label: W / M / 6M / 1Y / ALL.
    var segmentTitle: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        case .all: return String(localized: "All")
        }
    }

    /// What a chip compares with: "vs. prior week".
    var priorPhrase: String? {
        switch self {
        case .week: return String(localized: "vs. prior week")
        case .month: return String(localized: "vs. prior month")
        case .sixMonths: return String(localized: "vs. prior 6 months")
        case .year: return String(localized: "vs. prior year")
        case .all: return nil
        }
    }

    /// The range spoken by VoiceOver.
    var spokenName: String {
        switch self {
        case .week: return String(localized: "Week")
        case .month: return String(localized: "Month")
        case .sixMonths: return String(localized: "6 months")
        case .year: return String(localized: "Year")
        case .all: return String(localized: "All time")
        }
    }
}
#endif
