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
    /// The month the pager opens on (today's).
    let initialMonth: Int
    let showsPhaseLegend: Bool
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
        /// An expected period day: a dashed coral circle.
        let isPredictedPeriod: Bool
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
        /// Not enough logged cycles yet.
        case notYet
        /// No current cycle to predict for (no logs, a stale log, menopause).
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
            /// "58% vs 64% across your cycle", or how much more data it needs.
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
            /// "Current Cycle · 21 Days", "28 Days".
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
#endif
