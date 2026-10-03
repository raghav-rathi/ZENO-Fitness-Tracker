#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Health group snapshots
//
// Immutable values the Health tab, Health Monitor, Stress Monitor and Healthspan draw, built off the main
// actor by `PulseSnapshotBuilder+Health.swift`. Day keys stay keys (formatted at UTC by the views); real
// instants are `Date`s (device zone).

// MARK: ZENO Age

/// One week's ZENO Age (the VitalityEngine Body Age the weekly pass stores under the week's Saturday key)
/// with the whole-year age the engine scored it with.
struct HealthAgeWeek: Equatable, Identifiable {
    /// The week's key, "yyyy-MM-dd".
    let id: String
    let zenoAge: Double
    let chronoAge: Double

    /// Positive: younger than the calendar. The engine's own Δage.
    var yearsYounger: Double { chronoAge - zenoAge }
    var hue: HealthAgeHue { .forYearsYounger(yearsYounger) }

    var paceWeek: PaceOfAging.Week { .init(day: id, bodyAge: zenoAge, chronoAge: chronoAge) }
}

/// ZENO Age and its Pace of Aging, for one week.
struct HealthAgeSummary: Equatable {
    let week: HealthAgeWeek
    /// nil until the 6-month window has enough weeks (`PaceOfAging.minWeeks`).
    let pace: Double?
    let previousPace: Double?
    /// The window still holds fewer than `PaceOfAging.settledWeeks` weeks: ZENO Age is settling.
    let settling: Bool

    var paceChange: PaceOfAging.Change? {
        guard let pace, let previousPace else { return nil }
        return PaceOfAging.change(current: pace, previous: previousPace)
    }
}

/// Where ZENO Age stands on the Health tab: still unlocking, or a reading.
enum HealthAgeState: Equatable {
    /// `nights` of the `needed` nights of sleep in the last 31 days (§3.20 item 3 [Z]: 21 of 31).
    case unlocking(nights: Int, needed: Int)
    case ready(HealthAgeSummary)
}

// MARK: Lab Book

/// The Lab Book card: what the book holds, by category. Status-free on purpose: the Lab Book never judges
/// a value (its own promise, LabBookView), so the card counts markers instead of Optimal / Out of Range.
struct HealthLabsSummary: Equatable {
    struct Category: Equatable, Identifiable {
        let id: String
        let title: String
        /// Distinct markers in the category.
        let markers: Int
    }

    let markers: Int
    let readings: Int
    /// Categories that hold something, largest first.
    let categories: [Category]
    /// The newest reading's day key.
    let lastUpdatedKey: String?
}

// MARK: Vitals

/// One vital, as the Health Monitor tile and the Health tab's column show it. The colour is the
/// `VitalBands` verdict (the same one Home's tile counts); the words read the value against the range.
struct HealthVital: Equatable, Identifiable {
    enum Status: Equatable {
        /// Judged inside its range.
        case within
        /// Outside its range; `severe` beyond 3σ of a personal baseline.
        case outside(severe: Bool)
        case noData
    }

    /// "resp", "spo2", "rhr", "hrv", "skin".
    let id: String
    /// Pulse's name ("Respiratory rate"), for sentences and VoiceOver.
    let name: String
    /// The tile's caps label ("RESPIRATORY RATE", "SKIN TEMP (FROM BASELINE)").
    let tileTitle: String
    /// The Health tab's short column label ("RESP").
    let shortTitle: String
    let symbol: String
    let value: String?
    let unit: String
    let status: Status
    /// "within 13.8 - 14.8", "low < 95", "very high > 62", or, with no value, why there is none ("No HRV
    /// value", "Over-reports R-R, so no value is shown").
    let chipText: String
    /// A caveat on a value that is shown but known to be unreliable ("unverified · over-reports R-R", #1118).
    let caveat: String?
    /// -1 below the range, +1 above, 0 inside (the footer's "low" / "high").
    let direction: Int
    /// The day the value is from, and whether that is an earlier day carried forward.
    let dayKey: String?
    let isCarried: Bool
    /// Judged against a personal baseline (true) or the typical adult range.
    let isPersonal: Bool
    let route: TabRoute
}

// MARK: Stress

/// One day's stress, from ONE source: the intraday curve (`DaytimeStress`) for the gauge and the chart,
/// and the daily score (`StressModel`'s rule) only when the day has no curve, labelled as such. Home's
/// STRESS MONITOR tile and card can read the same value (see ARCHITECTURE notes).
struct PulseStressDay: Equatable {
    /// The day's local key and whether it is today.
    let dayKey: String
    let isToday: Bool
    /// The display timeline in the chart's window (half-hour steps of hour windows), oldest first; nil
    /// values are gaps.
    let points: [PulseTimeValue]
    /// The day's own scored hours (non-overlapping), for the totals and the high-stress run.
    let hours: [DaytimeStress.HourPoint]
    /// The chart's window, 24 h ending at its "now": today the last 24 h, a past day the 24 h ending on its
    /// last reading (completeness-critic/14), a past day without readings its calendar day.
    let window: ClosedRange<Date>
    /// The gauge's reading: the latest point of the curve, when it was.
    let latest: Reading?
    /// The daily score for the day (0–3), the gauge's fallback when there is no curve.
    let daily: Double?
    /// Waking hours left unscored because the strap saw you moving.
    let maskedHours: Int

    struct Reading: Equatable {
        let level: Double
        /// The end of the hour window the reading covers (now, at most).
        let at: Date
    }

    /// The level the gauge shows and whether it is a reading off the curve (`true`) or the daily score.
    var gaugeLevel: (level: Double, fromCurve: Bool)? {
        if let latest { return (latest.level, true) }
        if let daily { return (daily, false) }
        return nil
    }

    /// Where the chart's window ends with a dashed line and a dot: now today, the last reading's end on a
    /// past day; nil for a past day with no reading (its chart says so instead).
    var chartEnd: Date? {
        isToday || latest != nil ? window.upperBound : nil
    }

    /// When a gauge level was read, as the stress readouts word it: the reading's time, with its weekday
    /// when the reading is from another day than `dayKey` ("Fri 10:30 PM", the evening before early in the
    /// morning); nil when `at` is nil (the level is the daily score, not a reading).
    static func readingTime(_ at: Date?, dayKey: String) -> String? {
        guard let at else { return nil }
        if Repository.localDayKey(at) == dayKey { return PulseFormat.clock(at) }
        let weekday = at.formatted(.dateTime.weekday(.abbreviated).locale(AppLanguage.activeLocale))
        return "\(weekday) \(PulseFormat.clock(at))"
    }
}

/// The Health tab's STRESS MONITOR card.
struct HealthStressCard: Equatable {
    /// The Stress Monitor's gauge level for today (`PulseStressDay.gaugeLevel`, the funnel Home's tile
    /// reads): the curve's latest scored hour, the evening before until today's first one, else today's
    /// daily score; nil with neither.
    let level: Double?
    /// When `level` was read (`PulseStressDay.latest`); nil when it is the daily score.
    let readAt: Date?
    /// Minutes in the HIGH band so far today; nil while today has no scored hour.
    let highMinutes: Int?
    /// Today's curve so far, for the sparkline. (The typical weekday it is set against comes in a second,
    /// slower pass: `PulseSnapshotBuilder.healthTypicalHigh`.)
    let points: [PulseTimeValue]
    /// The sparkline's span: today's start to now.
    let span: ClosedRange<Date>
    /// The weekday's key, for "vs. typical Tue".
    let dayKey: String
}

/// The typical same weekday's HIGH minutes for the Health tab's chip, for the day `dayKey`. Always
/// returned by its pass (nil `minutes`: no typical day), so a newer day never keeps an older day's figure.
struct HealthTypicalHigh: Equatable {
    let dayKey: String
    let minutes: Int?
}

/// The Stress Monitor for one day. The typical same weekday arrives in a second pass
/// (`StressMonitorTypical`), so the day draws before six earlier days are scored.
struct StressMonitorSnapshot: Equatable {
    let seq: Int
    let day: PulseStressDay
    /// The pager's title ("Today", "Sun, Aug 2").
    let title: String
    /// Sleep and activity periods inside the window.
    let periods: [PulseChartPeriod]
    /// The day's minutes per band.
    let totals: StressDayTotals.Totals
    /// The longest run of HIGH hours.
    let longestHigh: LongestRun?
    /// The daily score's own explanation, used when the day has no curve.
    let dailyExplanation: String?

    struct LongestRun: Equatable {
        let start: Date
        let minutes: Int
    }
}

/// The typical same weekday for the Stress Monitor's day `dayKey`: each band's mean minutes (nil without two
/// worn same weekdays), and how many earlier same weekdays it averages.
struct StressMonitorTypical: Equatable {
    let dayKey: String
    let totals: StressDayTotals.Totals?
    let days: Int
}

// MARK: Health Monitor

/// The Health Monitor: the vitals, how far the personal ranges are from calibrated, and the report gate.
struct HealthMonitorSnapshot: Equatable {
    let seq: Int
    let vitals: [HealthVital]
    /// Nights of HRV banked toward a trusted personal baseline, and how many that needs; nil once trusted.
    let calibration: Calibration?

    struct Calibration: Equatable {
        let nights: Int
        let needed: Int
    }
}

// MARK: Health tab

/// The Health tab (always today).
struct HealthTabSnapshot: Equatable {
    let seq: Int
    let age: HealthAgeState
    let labs: HealthLabsSummary?
    let vitals: [HealthVital]
    let stress: HealthStressCard?
    let stepsToday: Double?
    let stepsRoute: TabRoute
}

// MARK: Healthspan

/// One pillar row (§3.23 item 6): the week's value on a range bar coloured by what the ZENO Age model makes
/// of it, the 6-month and 30-day averages as markers, and the years it adds or takes off.
struct HealthspanRow: Equatable, Identifiable {
    enum Tone: Equatable { case helps, neutral, hurts }

    let id: String
    let title: String
    /// The week's value as printed ("54 bpm"); nil when the week has none.
    let valueText: String?
    /// The bar's span and its end labels.
    let scale: ClosedRange<Double>
    let lowLabel: String
    let highLabel: String
    /// Ten tones across the bar, from the model (empty for a row the model does not use).
    let tones: [Tone]
    /// The unit the averages print with ("bpm", "h", "mL/kg/min"; empty for steps).
    let unit: String
    /// The 6-month and 30-day averages on the bar's axis, with their printed numbers (no unit).
    let sixMonth: Double?
    let sixMonthNumber: String?
    let thirtyDay: Double?
    let thirtyDayNumber: String?
    /// Years the factor adds (+) or takes off (−) ZENO Age this week; nil when it is not in the model or the
    /// breakdown does not add up to the week's ZENO Age (`HealthspanSnapshot.breakdownNote`).
    let years: Double?
    let verdict: String
    let sentence: String
    let route: PulseRoute?

    /// "55 mL/kg/min", "8:16 h", "84%": an average with its unit, for sentences and VoiceOver.
    func withUnit(_ number: String?) -> String? {
        number.map { PulseFormat.withUnit($0, unit) }
    }
}

struct HealthspanPillar: Equatable, Identifiable {
    let id: String
    let title: String
    let rows: [HealthspanRow]
}

/// Healthspan for one week.
struct HealthspanSnapshot: Equatable {
    let seq: Int
    /// Every ZENO Age week, oldest first (the pager and the trend).
    let weeks: [HealthAgeWeek]
    /// The week shown, or nil while ZENO Age is still unlocking.
    let summary: HealthAgeSummary?
    let unlock: Unlock?
    /// This week's Pace of Aging for every week that has one, oldest first.
    let paceSeries: [PacePoint]
    /// True when the week shown is the one still being scored (it closes in `daysLeftInWeek` days).
    let isCurrentWeek: Bool
    let daysLeftInWeek: Int
    let insight: Insight?
    let pillars: [HealthspanPillar]
    /// Why the rows show no years, when their breakdown does not add up to this week's stored ZENO Age
    /// (`HealthspanBreakdown`); nil when it does.
    let breakdownNote: String?

    struct Unlock: Equatable {
        let nights: Int
        let needed: Int
    }

    struct PacePoint: Equatable, Identifiable {
        let id: String
        let pace: Double
    }

    struct Insight: Equatable {
        let title: String
        let body: String
    }
}

/// Healthspan's rows outside the ZENO Age model for the week keyed `weekKey`: time in HR zones 1-3 and 4-5
/// and strength activity time, from the week's workouts. A second pass, because a workout without imported
/// zones reads its own heart rate.
struct HealthspanTracked: Equatable {
    let weekKey: String
    let rows: [HealthspanRow]
}
#endif
