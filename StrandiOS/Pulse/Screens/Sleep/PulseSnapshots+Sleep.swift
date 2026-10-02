#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Sleep group snapshots (WHOOP_UI_SPEC §3.3, §3.11)
//
// Immutable values the Sleep dive and the Sleep Planner render from, built off the main actor by
// `PulseSnapshotBuilder+Sleep.swift`. Everything is resolved and formatted there: a view holding one never
// reads the store, re-derives a night or formats a number of its own. Day keys become text only through
// `PulseFormat.dayLabel` (UTC); real instants (onset, wake, a heart-rate sample) stay `Date`s and are shown
// in the device zone.

/// A figure against the prior 30 nights: the value, its unit, the bare baseline WHOOP prints under it, and
/// the trend glyph coloured by whether the change is good (§2.6 item 9).
struct SleepFigure: Equatable {
    /// "8:10", "60", or "-:--" / "--" with nothing to show.
    let value: String
    /// "%" for percentages; nil for durations.
    let unit: String?
    /// The prior-30-night mean as printed ("7:58", "73%"); nil under five prior nights.
    let baseline: String?
    /// ▲ / ▼ / ●; nil without a baseline.
    let trend: PulseTrend?
    /// What VoiceOver reads.
    let spoken: String

    /// True when there is no value (the empty card shows only its title and the dash).
    var isEmpty: Bool { value.hasPrefix("-") }
}

/// One of the four Sleep Performance contributors in the callout (§3.3 item 3).
struct SleepContributorRow: Equatable, Identifiable {
    enum Kind: String, Equatable {
        case hours, consistency, efficiency, stress
    }

    let kind: Kind
    let title: String
    /// 0–100, or nil when the night cannot support it.
    let percent: Double?
    /// The row cannot be scored yet ("Calibrating", e.g. consistency before enough nights).
    let calibrating: Bool
    /// 0 Poor / 1 Sufficient / 2 Optimal on the row's own thresholds.
    let band: Int?
    /// The Trend View metric the row opens.
    let metric: String

    var id: String { kind.rawValue }
}

/// A stage's span on the night's clock (for the heart-rate chart's selected-stage bands).
struct SleepStageSpan: Equatable {
    let stage: SleepStage
    let start: Date
    let end: Date
}

/// One heart-rate bucket of the night's chart.
struct SleepHRPoint: Equatable, Identifiable {
    let date: Date
    let bpm: Double
    /// Contiguous-run identity: a gap in wear is drawn as a gap.
    let run: String
    var id: Date { date }
}

/// One stage row under the night's chart (§2.6 item 19).
struct SleepStageLine: Equatable, Identifiable {
    let stage: SleepStage
    /// "AWAKE", "LIGHT", "SWS (DEEP)", "REM".
    let title: String
    /// Share of the time in bed, 0…1 (the bar's length).
    let share: Double
    /// "5%".
    let percentText: String
    /// "0:24".
    let durationText: String
    /// The prior-30-night interquartile share, 0…1, for the typical-range box; nil under five nights.
    let typical: ClosedRange<Double>?
    /// When the stage happened, as fractions of the night (the barcode once a stage is selected).
    let segments: [ClosedRange<Double>]

    var id: String { stage.rawValue }
}

/// The HOURS OF SLEEP card (§3.3 item 6).
struct SleepLastNight: Equatable {
    let hours: SleepFigure
    let hr: [SleepHRPoint]
    /// The night itself (the dashed rules), and the chart's wider span either side of it.
    let onset: Date
    let wake: Date
    let chartStart: Date
    let chartEnd: Date
    /// "11:41 PM" / "7:19 AM" under the rules.
    let onsetLabel: String
    let wakeLabel: String
    let yDomain: ClosedRange<Double>
    let yValues: [Double]
    /// Time in bed, "8:41".
    let durationText: String
    let stages: [SleepStageLine]
    let spans: [SleepStageSpan]
    /// Deep + REM against the prior 30 nights.
    let restorative: SleepFigure
    /// Bed to sleep for a hand-edited night ("0:03"); nil for a night the strap detected on its own.
    let latency: String?
    /// The night has a real per-segment timeline (on-device staging), so stages can be selected.
    let hasTimeline: Bool
}

/// HOURS VS. NEEDED (§3.3 item 7a).
struct SleepHoursVsNeeded: Equatable {
    struct Row: Equatable, Identifiable {
        enum Swatch: Equatable { case minimum, strain, debt, none }
        let id: String
        let swatch: Swatch
        let title: String
        /// "7:42", "+0:35", "-2:07".
        let value: String
        /// The Healthy Minimum row draws dimmer than the adjustments.
        let dimmed: Bool
    }

    let figure: SleepFigure
    /// Minutes asleep, and the need it is measured against.
    let hoursMin: Double
    let needMin: Double?
    let hoursText: String
    let needText: String?
    /// The need bar's segments in minutes: the baseline net of nap credit, then strain, then debt.
    let minimumMin: Double
    let strainMin: Double
    let debtMin: Double
    /// The breakdown well's rows; empty when the need has no breakdown (an imported night's total).
    let rows: [Row]
}

/// SLEEP CONSISTENCY (§3.3 item 7b): five nights on an inverted clock.
struct SleepConsistencyCard: Equatable {
    struct Night: Equatable, Identifiable {
        /// The wake day key.
        let id: String
        /// "Wed".
        let label: String
        /// Bed and wake on the chart's clock: minutes after noon of the evening the night began.
        let bed: Double
        let wake: Double
        let isLast: Bool
    }

    struct Optimal: Equatable, Identifiable {
        let id: String
        let bed: Double
        let wake: Double
    }

    struct Line: Equatable, Identifiable {
        let position: Double
        let label: String
        var id: Double { position }
    }

    /// nil while calibrating.
    let figure: SleepFigure?
    let nights: [Night]
    let optimal: [Optimal]
    /// Last night's bed and wake as callout pills ("10:41 PM" / "8:11 AM").
    let lastBedText: String?
    let lastWakeText: String?
    let lines: [Line]
    let domain: ClosedRange<Double>
}

/// SLEEP EFFICIENCY (§3.3 item 7c).
struct SleepEfficiencyCard: Equatable {
    struct AwakeRun: Equatable {
        let range: ClosedRange<Double>
        /// Long wakes draw as blocks, short ones as ticks.
        let isLong: Bool
    }

    let figure: SleepFigure
    let asleepText: String
    let awakeText: String
    /// Fractions of the time in bed.
    let asleepRuns: [ClosedRange<Double>]
    let awakeRuns: [AwakeRun]
    let wakeEvents: Int?
}

/// The window the night's stress is scored over, handed to the second build.
struct SleepStressRequest: Equatable {
    let nightKey: String
    let onset: Date
    let wake: Date
}

/// SLEEP STRESS (§3.3 item 7d) and the HIGH SLEEP STRESS contributor, built after the rest of the page
/// because it reads the night's raw heart rate and R-R and the waking hours before it.
struct SleepStressSnapshot: Equatable {
    enum State: Equatable {
        case scored
        /// No waking heart rate before the night to compare it against.
        case noReference
        /// Too little heart rate during the night.
        case noHeartRate
    }

    struct Level: Equatable, Identifiable {
        let band: SleepStress.Band
        /// "HIGH".
        let title: String
        /// 0…1.
        let share: Double
        let percentText: String
        let durationText: String
        var id: String { band.rawValue }
    }

    let nightKey: String
    let state: State
    /// HIGH SLEEP STRESS, 0–100 (printed whole).
    let highPercent: Double?
    let levels: [Level]
    /// The curve (window midpoints), with gaps as nil.
    let points: [PulseTimeValue]
    let sleepStart: Date
    let sleepEnd: Date
    let chartEnd: Date
    /// Four times under the chart, oldest first.
    let xLabels: [String]
    /// The last scored level, for the end rule's dot.
    let lastLevel: Double?
}

/// One day of the Weekly Trends cards (§3.3 item 8), keyed by wake day.
struct SleepWeekNight: Equatable, Identifiable {
    let id: String
    /// "Wed" over "5".
    let label: String
    let sublabel: String
    let performance: Double?
    let hoursMin: Double?
    let needMin: Double?
    let hoursPct: Double?
    let deepMin: Double?
    let remMin: Double?
    let consistency: Double?
    /// Time in bed on the chart's clock (minutes after noon), with the labels WHOOP prints (12 h, no AM/PM).
    let bed: Double?
    let wake: Double?
    let bedText: String?
    let wakeText: String?
    let efficiency: Double?
}

/// The Sleep deep dive for one night.
struct SleepDiveSnapshot: Equatable {
    let seq: Int
    /// The day the request was for (Home's day): the nav title says "TODAY" for its night.
    let requestDayKey: String
    /// Every banked night's wake day, newest first: ‹ › step through these.
    let nightKeys: [String]
    let nightIndex: Int
    /// The wake day of the night shown; nil with no night at all.
    let wakeDayKey: String?
    let dial: PulseDialData
    let contributors: [SleepContributorRow]
    /// The coach summary pill's local sentence.
    let summary: String?
    let lastNight: SleepLastNight?
    let hoursVsNeeded: SleepHoursVsNeeded?
    let consistency: SleepConsistencyCard?
    let efficiency: SleepEfficiencyCard?
    let stress: SleepStressRequest?
    let weekly: [SleepWeekNight]
    let naps: [PulseNap]
    let sleepingHR: Int?
    let lowestHR: Int?
    let respRate: Double?
    /// The night is the newest one banked.
    var isLatest: Bool { nightIndex == 0 }
    var hasOlder: Bool { nightIndex + 1 < nightKeys.count }
    var hasNewer: Bool { nightIndex > 0 }
}

// MARK: - Sleep Planner

/// What the Sleep Planner needs that the store knows (§3.11): tonight's need and its parts, and the recent
/// nights' timing for the consistency projection and the OPTIMAL window. Everything about the alarm is read
/// live from its settings in the view, so the panel always shows what the strap is armed with.
struct SleepPlannerSnapshot: Equatable {
    let seq: Int
    /// Tonight's need from the unified model (`Repository.sleepNeedTonight`), minutes, with its parts.
    let need: SleepNeedBreakdown
    /// The recent nights' bed and wake on the local clock (SleepConsistency's inputs).
    let timings: [SleepConsistency.NightTiming]
    /// The day whose evening is being planned (the night ends the day after).
    let planDayKey: String
}
#endif
