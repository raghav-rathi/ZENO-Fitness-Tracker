#if os(iOS)
import Foundation
import StrandAnalytics
import WhoopStore

// MARK: - Strength Trainer snapshots (WHOOP_UI_SPEC §3.29)
//
// Immutable, already formatted values for the Strength Trainer's root (MY WORKOUTS, PROGRESS) and
// Exercise Details, built off the main actor by `PulseSnapshotBuilder+Strength.swift` from the Lift
// Log's own store rows. Weights are in the wearer's unit (`UnitPrefs.systemKey`, the Lift Log's only
// unit setting); every number is `LiftMetrics` / `LiftProgress` arithmetic over logged sets.

/// The PROGRESS chart's span: M (30 days, weekly segments) or 6M (182 days, monthly segments, WHOOP's
/// default), stepped back with the pager.
enum StrengthRange: String, CaseIterable, Hashable, Sendable {
    case month
    case sixMonths

    var title: String {
        switch self {
        case .month: return "M"
        case .sixMonths: return "6M"
        }
    }

    var days: Int {
        switch self {
        case .month: return 30
        case .sixMonths: return 182
        }
    }

    var bucket: LiftProgress.Bucket {
        switch self {
        case .month: return .week
        case .sixMonths: return .month
        }
    }

    /// "vs. prior month" / "vs. prior 6 months": what an average is compared against.
    var priorPhrase: String {
        switch self {
        case .month: return String(localized: "vs. prior month")
        case .sixMonths: return String(localized: "vs. prior 6 months")
        }
    }
}

/// The volume chart: each session's volume as a faint line (the latest one ringed), and the per-bucket
/// averages as segments with their value above and the change from the previous segment below (spec
/// §2.7, 6M grammar).
struct StrengthVolumeChart: Equatable {
    let start: Date
    let end: Date
    /// Oldest first.
    let points: [Point]
    let segments: [Segment]
    let yTicks: [Double]
    /// One name per month (6M) or week (M), under the middle of its part of the window.
    let xLabels: [AxisLabel]

    var yMax: Double { yTicks.last ?? 1 }

    struct Point: Equatable, Identifiable {
        let id: String
        let date: Date
        let value: Double
        /// "7,550".
        let valueText: String
    }

    struct AxisLabel: Equatable {
        let date: Date
        let text: String
    }

    struct Segment: Equatable, Identifiable {
        let id: Int
        let from: Date
        let to: Date
        let value: Double
        let valueText: String
        let changeText: String?
        let tone: Tone
    }

    /// How a segment's change reads: the first one white, then teal up, orange down, grey unchanged.
    enum Tone: Equatable {
        case first, up, down, flat
    }

    static let empty = StrengthVolumeChart(start: Date(), end: Date(), points: [], segments: [], yTicks: [0, 1],
                                           xLabels: [])
}

/// "‹ NOV 27, 25 - MAY 25, 26 ›".
struct StrengthPager: Equatable {
    let title: String
    let canGoBack: Bool
    let canGoForward: Bool
}

/// A saved workout (a Lift Log program) on MY WORKOUTS, with its lines for the workout page.
struct StrengthWorkout: Equatable, Identifiable {
    let program: LiftProgramRow
    let lines: [Line]
    /// "4 exercises · 12 sets".
    let detail: String
    /// "Last done Sep 29", nil when never run.
    let lastDone: String?

    var id: String { program.id }

    struct Line: Equatable, Identifiable {
        let id: String
        let exercise: String
        let muscles: String?
        /// "3 Sets".
        let setsText: String
        /// One row per planned set: reps and weight as the program targets them ("8", "60"), nil = not set.
        let sets: [PlannedSet]
        /// "Rest 2:00".
        let rest: String
        let note: String?
    }

    struct PlannedSet: Equatable, Identifiable {
        let id: Int
        let reps: String?
        let weight: String?
    }
}

/// One exercise's record on PROGRESS: its best set's weight, or its most reps for bodyweight work.
struct StrengthRecord: Equatable, Identifiable {
    let exercise: String
    let value: String
    let unit: String

    var id: String { exercise }
}

/// A finished session in RECENT SESSIONS.
struct StrengthSession: Equatable, Identifiable {
    let row: LiftSessionRow
    let title: String
    let subtitle: String

    var id: String { row.id }
}

/// One muscle's week, drawn like the classic Lift Log's bar: the count, and the ≈4-set research floor
/// as a tick on a 20-set span that is never "full".
struct StrengthMuscleWeek: Equatable, Identifiable {
    let id: String
    let name: String
    let setsText: String
    let fill: Double
    let tick: Double
    let atOrAboveFloor: Bool
}

/// The Strength Trainer's root.
struct StrengthTrainerSnapshot: Equatable {
    /// "kg" or "lb".
    let unit: String
    let workouts: [StrengthWorkout]
    /// "Ø VOLUME LOAD": the mean session volume in the window, nil when no session counted.
    let averageVolume: String?
    let chart: StrengthVolumeChart
    let pager: StrengthPager
    let records: [StrengthRecord]
    let muscles: [StrengthMuscleWeek]
    let sessions: [StrengthSession]
    /// True once any session has been finished (PROGRESS has something to show).
    let hasSessions: Bool
}

/// Exercise Details.
struct StrengthExerciseSnapshot: Equatable {
    let exercise: String
    let muscles: String?
    let unit: String
    /// "AVG VOLUME LOAD" over the window, and its change against the window before.
    let averageVolume: String?
    let change: Change?
    let chart: StrengthVolumeChart
    let pager: StrengthPager
    let topSets: [TopSet]
    let history: [HistorySession]
    /// The technique notes this exercise carries in the wearer's workouts.
    let notes: [Note]

    struct Change: Equatable {
        /// "3% vs. prior 6 months".
        let text: String
        let up: Bool?
    }

    struct TopSet: Equatable, Identifiable {
        let id: Int
        /// 1-based rank; the first three carry a medal.
        let rank: Int
        let weight: String?
        let reps: String?
        let date: String
        /// "Estimated 1RM 120 kg (Epley)", nil when the set cannot support one.
        let estimate: String?
        let workout: String?
    }

    struct HistorySession: Equatable, Identifiable {
        let id: String
        let date: String
        let title: String
        let sets: [String]
    }

    struct Note: Equatable, Identifiable {
        let id: String
        let workout: String
        let text: String
    }
}
#endif
