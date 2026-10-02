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

/// A metric's daily values, resolved once per refresh.
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

    var earliest: String? { points.first?.day }
    var hasData: Bool { !points.isEmpty }
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
    }

    struct Column: Equatable, Identifiable {
        /// The day key (or a week's last day).
        let id: String
        /// The column's value (a stacked column's total); nil is a gap, never a zero.
        let value: Double?
        var parts: [Double] = []
        /// The dual line's second value (the need).
        var secondary: Double?
        var color: Color
        var label: String?
        var secondaryLabel: String?
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

    var hasValues: Bool { columns.contains { $0.value != nil } }
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
