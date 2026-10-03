#if os(iOS)
import Foundation
import StrandAnalytics

// MARK: - Menstrual Cycle Insights snapshot (WHOOP_UI_SPEC §3.24)
//
// Everything the page shows, already resolved and formatted, from ONE pass over the logs, the day rows and
// the temperature engine's result (`PulseSnapshotBuilder.cycleInsights`). The phase, cycle day, prediction
// and calendar all come from that single funnel, so the header, the calendar and the coaching card can
// never disagree about where the cycle is.

typealias PulseCyclePhase = MenstrualCycleModel.Phase

struct CycleInsightsSnapshot: Equatable {
    let seq: Int
    /// Today's day key (UTC-midnight anchor).
    let today: String
    let mode: PulseCycleLog.Mode
    /// Anything logged at all (a start, a flow, a symptom).
    let hasLogs: Bool
    /// The first day the log sheet steps back to.
    let earliestLogDay: String
    let header: Header
    let months: [Month]
    /// The month the pager opens on ("yyyy-MM", today's).
    let todayMonthID: String
    let showsPhaseLegend: Bool
    /// Any possible start day drawn: the legend explains the dashed circle only when there is one.
    var showsPredictionLegend: Bool { months.contains { $0.days.contains(where: \.isPossibleStart) } }
    let symptomsToday: SymptomsToday
    let journal: Journal
    let coaching: Coaching?
    let currentCycle: CurrentCycle?
    let patterns: Patterns?
    let symptomSummary: [SymptomRow]
    /// The phase whose tint the page header takes (nil: the plain page).
    var tintPhase: PulseCyclePhase? { header.phase }

    struct Header: Equatable {
        /// "Cycle Day 3", "Cycle Day 18–22", or nil ("No Phase Predicted", "Menopause").
        let cycleDay: String?
        let phase: PulseCyclePhase?
        /// "Menstrual Phase", "No Phase Predicted", "Menopause"; nil where phases do not apply (hormonal
        /// contraception), leaving the cycle day alone.
        let title: String?
        /// "Predicted Period Day • Next period in: 25–27 Days".
        let subtitle: String
        /// Where a prediction comes from ("Based on your last 3 cycles"), when there is one.
        let basis: String?
        /// A caveat to show under it (a mistimed log, hormonal contraception, wider perimenopause windows).
        let caveat: String?
        let accessibility: String
    }

    struct Month: Equatable, Identifiable {
        /// "yyyy-MM".
        let id: String
        /// "APRIL", or "APRIL 2025" outside the current year.
        let title: String
        /// Blank cells before the 1st in a Monday-first week.
        let leadingBlanks: Int
        let days: [Day]
    }

    struct Day: Equatable, Identifiable {
        let id: String
        let number: Int
        let phase: PulseCyclePhase?
        /// After today: dimmed band and number.
        let isFuture: Bool
        let isToday: Bool
        /// A logged period day: a filled coral circle.
        let isLoggedPeriod: Bool
        /// A day the next period may start on (the prediction window): a dashed coral circle.
        let isPossibleStart: Bool
        /// Spotting logged: a thin coral ring.
        let isSpotting: Bool
        let hasSymptoms: Bool
        let accessibility: String
    }

    enum SymptomsToday: Equatable {
        /// Symptoms seen around this cycle day in most previous cycles.
        case predictions([String])
        /// Enough cycles, nothing stands out today.
        case nothingExpected
        /// Nothing logged yet, or not enough logged cycles.
        case notYet
        /// No current cycle to predict for (a stale log, menopause, hormonal contraception).
        case unavailable
    }

    /// Today's Cycle Journal rows.
    struct Journal: Equatable {
        let flow: String?
        let symptoms: [String]
    }

    struct Coaching: Equatable {
        let phase: PulseCyclePhase
        /// Phase lengths for the M | F | O | L bar.
        let bar: [Segment]
        let paragraph: String
        let metrics: [Metric]

        struct Segment: Equatable, Identifiable {
            let phase: PulseCyclePhase
            let days: Int
            var id: String { phase.rawValue }
        }

        struct Metric: Equatable, Identifiable {
            let id: String
            let title: String
            let symbol: String
            /// "Higher", "Lower", "Typical", or "Calibrating".
            let chip: String
            let kind: Kind
            /// "91% vs 88% across your cycle", or how much more data it needs.
            let detail: String

            enum Kind: Equatable { case positive, negative, neutral, calibrating }
        }
    }

    struct CurrentCycle: Equatable {
        let series: [Series]
        let todayCycleDay: Int
        /// The predicted next start, as a cycle day of this cycle (nil when late or unknown).
        let nextStartCycleDay: Int?
        /// The x axis runs 1…this.
        let axisMax: Int
        let paragraph: String

        struct Series: Equatable, Identifiable {
            let id: String
            let title: String
            let symbol: String
            /// The unit of the y labels ("°C", "bpm", "ms", "%").
            let unit: String
            let decimals: Int
            let current: [Bar]
            /// The previous cycles' average as a smoothed trend (`CycleSeries.expectedTrend`).
            let expected: [CycleMetricPatterns.Point]
            /// The previous cycles' average, for "LAST 3 MONTHS".
            let average: [Bar]
            let previousCycles: Int
        }

        struct Bar: Equatable, Identifiable {
            let cycleDay: Int
            let value: Double
            let phase: PulseCyclePhase?
            var id: Int { cycleDay }
        }
    }

    struct Patterns: Equatable {
        let typical: [Stat]
        /// Why a value is "--".
        let footnote: String?
        let cycles: [CycleRow]

        struct Stat: Equatable, Identifiable {
            let id: String
            let title: String
            /// "28", or "--".
            let value: String
            let unit: String
        }

        struct CycleRow: Equatable, Identifiable {
            let id: String
            /// "Current Cycle 21 Days", "28 Days".
            let title: String
            /// "Sep 13 – Today".
            let range: String
            let dots: [Dot]
            let note: String?
        }

        struct Dot: Equatable {
            let phase: PulseCyclePhase?
            let isFuture: Bool
            let isPeriod: Bool
        }
    }

    struct SymptomRow: Equatable, Identifiable {
        let id: String
        let title: String
        let detail: String
    }
}

/// Where the cycle is today, as Menstrual Cycle Insights' header states it, for a card outside the page (the
/// Health tab's MENSTRUAL CYCLE INSIGHTS), built by the page's own funnel (`PulseSnapshotBuilder.cycleToday`)
/// so the card and the page it opens state one cycle day and one phase.
struct CycleTodaySnapshot: Equatable {
    let seq: Int
    /// The page's header: "Cycle Day 3" with "Menstrual Phase", "No Phase Predicted", "Menopause".
    let header: CycleInsightsSnapshot.Header
    /// The line under the card's label: the cycle day, or what there is instead ("Log a period to start").
    let headline: String
    /// Today's place in the cycle, 0…1, for the card's bar; nil without a cycle day to place.
    let position: Double?
}
#endif
