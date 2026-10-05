#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Trend View snapshot (WHOOP_UI_SPEC §3.12)
//
// Immutable values the Trend View draws, built off the main actor by `PulseSnapshotBuilder.trendView` and
// `PulseTrendPageBuilder`. Every text is already formatted; every label made from a day key went through a
// UTC formatter (`PulseFormat.dayLabel`), so a window reads the same days in every time zone.

/// The display preferences a trend series is converted with.
struct PulseTrendUnits: Equatable, Hashable, Sendable {
    var fahrenheit = false
    var imperialMass = false

    /// A cache key part.
    var id: String { "\(fahrenheit ? "f" : "c")\(imperialMass ? "lb" : "kg")" }
}

/// A metric's daily values: the history resolved once per refresh, with today's live reading (Day Stress's,
/// Day Strain's) laid over it per build (`PulseSnapshotBuilder.trendSeries`).
struct PulseTrendSeries: Equatable, Sendable {
    /// The headline value per day, oldest first, never after today.
    var points: [PulseTrendMath.Point] = []
    /// Stacked parts per day, in the metric's part order (zones, sleep stages).
    var parts: [[PulseTrendMath.Point]] = []
    /// HOURS VS. NEEDED's second series: the night's need.
    var secondary: [PulseTrendMath.Point] = []
    /// The unit when the data decides it (skin temperature's °C or Δ°C, weight's lb).
    var unit: String?
    /// Values are a signed deviation (skin temperature from its baseline).
    var signed = false
    /// Days whose value is UNKNOWN rather than zero (a day with an activity logged without heart-rate
    /// zones): they are absent from `points`, and a week holding one is partial.
    var unknownDays: Set<String> = []
    /// TIME IN BED: each night's bed and wake as minutes from its wake day's local midnight.
    var spans: [String: PulseTrendSpan] = [:]
    /// Today's value where it is a reading rather than a total still counting, which "So far today" would
    /// misname (Day Stress: the Stress Monitor's gauge); nil for every other metric.
    var todayReading: PulseTrendTodayReading?

    var earliest: String? { points.first?.day }
    var hasData: Bool { !points.isEmpty }
}

/// Day Stress's today as the Stress Monitor's gauge reads it (`PulseStressDay.gaugeLevel`): a reading, not
/// a total still counting.
struct PulseTrendTodayReading: Equatable, Sendable {
    /// When it was read, as every stress readout words it: "7:30 AM", or "Fri 10:30 PM" for the evening
    /// before, which the gauge carries until today's first reading. nil when the level is today's daily
    /// score rather than a reading off the curve.
    let time: String?

    /// The Trends row's caption: when it was read, else "Daily score".
    var caption: String { time ?? String(localized: "Daily score") }
}

/// A night's bed → wake span in minutes from its wake day's local midnight: the evening before is
/// negative ("22:30" is -90), the morning positive ("06:30" is 390). TIME IN BED's floating bars.
struct PulseTrendSpan: Equatable, Sendable {
    let bed: Double
    let wake: Double
}

/// The ▲▼ chip beside a headline value: "▲ 45% vs. prior week".
struct PulseTrendChip: Equatable {
    let text: String
    let trend: PulseTrend
}

/// One headline value: "AVERAGE / 74 % / ▲ 45% vs. prior week".
struct PulseTrendHeadline: Equatable, Identifiable {
    let id: String
    /// "Average", "Weekly total", "Avg. need".
    let label: String
    /// "74", "--" without a reading.
    let value: String
    let unit: String
    var valueColor: Color = PulseTheme.textPrimary
    let chip: PulseTrendChip?
    /// HOURS VS. NEEDED stacks two compact values with the label under each and a mini chip beside it.
    var compact = false
    let accessibility: String
    /// A line under the value: when a reading was taken ("8:00 AM", "Fri 10:30 PM"), where the value is one.
    var caption: String?
}

/// A legend entry above the chart.
struct PulseTrendLegendItem: Equatable, Identifiable {
    enum Swatch: Equatable { case square, dot, ring }
    let id: String
    let title: String
    let color: Color
    var swatch: Swatch = .square
}

/// Everything the chart draws, resolved: columns on an index axis, the y scale, labels and overlays.
struct PulseTrendChartModel: Equatable {
    enum Mode: Equatable {
        case bars, line, stacked, dualLine
        /// One bar per day from `Column.range`'s lower to its upper bound (TIME IN BED's bed → wake).
        case floating
    }

    struct Column: Equatable, Identifiable {
        /// The day key (or a week's last day).
        let id: String
        /// The column's value (a stacked column's total); nil is a gap, never a zero.
        let value: Double?
        var parts: [Double] = []
        /// The dual line's second value (the need).
        var secondary: Double?
        /// A floating bar's extent on the y axis (bed → wake).
        var range: ClosedRange<Double>?
        var color: Color
        /// Over the column (a floating bar: over its top end).
        var label: String?
        /// The dual line's second label; a floating bar's label under its bottom end.
        var secondaryLabel: String?
        /// A week holding a day of unknown value: drawn faint and labelled as partial, never as a week.
        var isPartial = false
    }

    struct Tick: Equatable {
        let value: Double
        let label: String
        var color: Color = PulseTheme.textTertiary
    }

    struct XLabel: Equatable, Identifiable {
        let index: Int
        let line1: String
        var line2: String?
        var id: Int { index }
    }

    /// A long range's period segment, spanning columns `startIndex...endIndex`.
    struct Segment: Equatable, Identifiable {
        let id: String
        let startIndex: Int
        let endIndex: Int
        let value: Double
        let valueLabel: String
        let changeLabel: String?
        let color: Color
        let changeColor: Color
        /// The value label's colour (white, or the series colour when two sets share the chart).
        var labelColor: Color = PulseTheme.textPrimary
        /// The value label sits under the line rather than over it (HOURS VS. NEEDED's hours).
        var labelBelow = false
    }

    /// A dashed horizontal line with a white pill at the left axis: M's "AVG.", TIME IN BED's average
    /// bedtime and wake ("20:32" / "04:36").
    struct Marker: Equatable, Identifiable {
        let id: String
        let value: Double
        let pill: String
    }

    /// Columns `startIndex...endIndex` drawn faint under a caption (Training Load's building weeks).
    struct DimmedSpan: Equatable {
        let startIndex: Int
        let endIndex: Int
        let caption: String
    }

    /// A stretch of the menstrual-cycle strip under the plot.
    struct PhaseSpan: Equatable, Identifiable {
        let id: String
        let startIndex: Int
        let endIndex: Int
        let phase: PulseTrendCyclePhase
    }

    var mode: Mode
    var columns: [Column]
    var yDomain: ClosedRange<Double>
    var yTicks: [Tick]
    var xLabels: [XLabel]
    var barWidth: CGFloat
    /// When set, a bar is this fraction of its column's pitch instead of `barWidth` (M's thirty bars).
    var barFraction: CGFloat?
    var partColors: [Color] = []
    var lineColor: Color
    var secondaryColor: Color?
    /// The dashed AVG. line (M bars).
    var average: Double?
    var typical: ClosedRange<Double>?
    var segments: [Segment] = []
    /// Long ranges draw their data faint under the segments.
    var dimmed = false
    var showsMarkers = true
    /// M lines mark and label only their newest point.
    var marksLastPointOnly = false
    var phases: [PhaseSpan] = []
    /// Shown centred when no column has a value.
    var emptyMessage: String?
    let accessibilitySummary: String
    /// Dashed lines with pills other than M's AVG. (TIME IN BED's average bedtime and wake).
    var markers: [Marker] = []
    /// The y axis runs downward: its lower bound at the top (TIME IN BED's clock, bedtime above wake).
    var invertedY = false
    /// Columns drawn faint under a caption.
    var dimmedSpan: DimmedSpan?

    var hasValues: Bool { columns.contains { $0.value != nil || $0.range != nil } }
}

/// A breakdown block: "RECOVERY BREAKDOWN (DAYS)", a stacked bar and its rows.
struct PulseTrendBreakdown: Equatable {
    struct Row: Equatable, Identifiable {
        let id: String
        /// "3x", "0:30".
        let amount: String
        /// "Green", "Zone 4".
        let name: String
        /// "(67-100%)", or empty.
        let range: String
        let color: Color
        /// Share of the bar, 0...1.
        let share: Double
    }

    let title: String
    /// "(Days)", "(Weekly total)".
    let unitNote: String
    let rows: [Row]
}

/// The range pager under the segmented control.
struct PulseTrendPager: Equatable {
    /// "SEP 19 - SEP 25, 26" (the style uppercases it).
    let title: String
    let canGoBack: Bool
    let canGoForward: Bool
    let accessibility: String
}

/// One Trend View page: a metric over one position of one range.
struct TrendViewSnapshot: Equatable {
    let seq: Int
    let metric: PulseTrendMetric
    let range: PulseTrendMath.Range
    let page: Int
    let pager: PulseTrendPager
    let headlines: [PulseTrendHeadline]
    let insight: String?
    let legend: [PulseTrendLegendItem]
    let chart: PulseTrendChartModel
    let footnotes: [String]
    let breakdown: PulseTrendBreakdown?
    /// The metric has at least one reading anywhere in its history.
    let hasData: Bool
    /// The menstrual-cycle overlay is on the chart (its info card shows under it).
    let showsCycleNote: Bool
    /// YOUR CARDIO FITNESS LEVEL under the VO₂ Max chart (§3.28, reviews/83), from the series' newest
    /// estimate whatever window is shown; nil for every other metric.
    var cardioFitness: HealthVO2MaxCard.State? = nil
}

/// A metric that moves with (or against) the Trend View's metric over its period (the WHAT CORRELATES
/// card, §3.12 [Z]): Pearson r on the days both have a reading.
struct PulseTrendCorrelation: Equatable, Identifiable {
    /// The other metric's key (its Trend View).
    let id: String
    let title: String
    let symbol: String
    let r: Double
    let n: Int
}

/// WHAT CORRELATES for one page: the period it scanned and what moved with the metric over it.
struct PulseTrendCorrelations: Equatable {
    /// "this period", or for W, whose seven days are too few, "the 30 days to Oct 2".
    let period: String
    let rows: [PulseTrendCorrelation]
    /// The metric has at least `minimumCorrelationDays` readings in the period.
    let hasEnoughDays: Bool
}

/// A row of the metric picker.
struct PulseTrendPickerItem: Equatable, Identifiable {
    let id: String
    let title: String
    let symbol: String
    let pillar: PulseTrendPillar
    let hasData: Bool
}
#endif

#if os(iOS)
// MARK: - Trends tab snapshot (WHOOP_UI_SPEC §3.35)

/// The Trends tab: THIS WEEK, then every pillar's metric rows.
struct TrendsTabSnapshot: Equatable {
    /// One pillar's line in THIS WEEK: the mini ring, this week's average and its chip against last week.
    struct WeekLine: Equatable, Identifiable {
        let score: PulseScore
        let ring: PulseDialContent
        /// "86%", "11.4", "--".
        let value: String
        let chip: PulseTrendChip?
        let accessibility: String
        var id: String { score.rawValue }
    }

    /// A dashboard-style metric row: the newest value with its ▲▼ against the 30-day average, the average
    /// under it, and a 7-day sparkline.
    struct Row: Equatable, Identifiable {
        /// The metric key (its Trend View).
        let id: String
        let title: String
        let symbol: String
        /// nil while the metric has no reading.
        let value: String?
        let unit: String
        /// "Sep 30" for an older reading, "So far today" for a running total (or the series' own
        /// `todayReading`, Day Stress's reading time), "Last 7 days".
        let caption: String?
        let trend: PulseTrend?
        let baseline: String?
        /// The last seven days, oldest first; nil is a day without a reading.
        let spark: [Double?]
        let color: Color
        let accessibility: String
    }

    struct Section: Equatable, Identifiable {
        let pillar: PulseTrendPillar
        let rows: [Row]
        var id: String { pillar.rawValue }
    }

    let seq: Int
    /// "Sep 28 - Oct 4".
    let weekTitle: String
    let week: [WeekLine]
    /// Why a line leaves something out ("Strain leaves out today until it ends").
    let weekNote: String?
    let sections: [Section]
}

// MARK: - Weekly Digest snapshot (WHOOP_UI_SPEC §3.40)

/// A week (Monday to Sunday) or a calendar month in review.
struct WeeklyDigestSnapshot: Equatable {
    enum Mode: String, CaseIterable, Hashable {
        case week, month

        var segmentTitle: String { self == .week ? "W" : "M" }
    }

    /// One of the three summary dials with its chip against the period before.
    struct Pillar: Equatable, Identifiable {
        let score: PulseScore
        let content: PulseDialContent
        let chip: PulseTrendChip?
        /// The chip as VoiceOver reads it, with the period it compares against ("Sleep, up 4% vs. last week").
        let chipAccessibility: String?
        let route: PulseRoute
        var id: String { score.rawValue }
    }

    /// A Weekly Trends card reused from the deep dives.
    struct TrendCard: Equatable, Identifiable {
        /// The metric key.
        let id: String
        let title: String
        let data: [PulseChartDatum]
        let yDomain: ClosedRange<Double>
        let gridValues: [Double]
        let highlightID: String?
        let route: PulseRoute
    }

    /// A notable day ("Best Recovery · Tue, Sep 23 · 94%").
    struct Highlight: Equatable, Identifiable {
        let id: String
        let symbol: String
        let title: String
        let day: String
        let value: String
        let unit: String
    }

    /// A journal behaviour logged in the period, with its effect on Recovery over the last 90 days as
    /// Behavior Insights shows it.
    struct Behavior: Equatable, Identifiable {
        /// The behaviour's identity (`PulseBehaviorLibrary.identity(for:)`), which `behaviorNames` names as
        /// the page does.
        let id: String
        /// "Logged 3 days".
        let logged: String
        /// nil while there are too few yes / no days to measure it.
        let effect: PulseImpactBar.Effect?
        let fraction: Double
        let valueText: String
        let note: String?
    }

    let seq: Int
    let mode: Mode
    let page: Int
    let pager: PulseTrendPager
    let hasData: Bool
    let pillars: [Pillar]
    let note: String?
    let cards: [TrendCard]
    let highlights: [Highlight]
    let behaviors: [Behavior]
    let insight: String
    /// The plan block (§3.40 item 3): the active plan's week as Plan Overview measures it; nil without a
    /// plan, in the monthly digest, and for a week before the plan began.
    var plan: Plan?
    /// What the behaviours are named from, as Behavior Insights names them (`BehaviorNames`).
    var behaviorNames = BehaviorNameSources()

    /// The plan's name and its week, from Plan Overview's own resolver (`PulseSnapshotBuilder.planWeek`).
    struct Plan: Equatable {
        /// "BOOST FITNESS PLAN" as the cards print it.
        let title: String
        let week: PlanWeekSnapshot
    }
}
#endif

#if os(iOS)
// MARK: - Training Load snapshot (§3.35 INSIGHTS › TRAINING LOAD)

/// Fitness (CTL), fatigue (ATL) and form (TSB) over one range, from `TrainingLoadEngine`.
struct TrainingLoadSnapshot: Equatable {
    struct Stat: Equatable, Identifiable {
        let id: String
        let title: String
        let value: String
    }

    let seq: Int
    let range: PulseTrendMath.Range
    /// The model has enough contiguous days to draw.
    let isAvailable: Bool
    /// "Building: 20 of 42 days", or why nothing is drawn yet.
    let status: String?
    /// Form, signed ("+3.2", "-4.1"), and what it means.
    let form: String
    let formWord: String
    let insight: String
    let chart: PulseTrendChartModel
    let stats: [Stat]
}
#endif
