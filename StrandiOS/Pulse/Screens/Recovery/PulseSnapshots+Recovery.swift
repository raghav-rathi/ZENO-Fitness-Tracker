#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - The rebuilt Recovery deep dive's snapshot (WHOOP_UI_SPEC §3.4)
//
// Built off the main actor by `PulseSnapshotBuilder.recoveryDive(_:)`, everything already resolved and
// formatted. The dial, the engine's drivers and the confidence tier come from the foundation's
// `RecoverySnapshot`, so this dive and every other Recovery surface read one resolver.

struct RecoveryDiveSnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    let dial: PulseDialData
    /// Whose night a carried score is ("Last night · Sep 30"), shown under the bar.
    let carriedCaption: String?
    /// The day whose row the dial and the callout read (its own, or the carried night's).
    let sourceDayKey: String?
    /// Heart rate variability, resting heart rate, respiratory rate and sleep performance, each against
    /// its 30-day average.
    let contributors: [PulseDiveContributor]
    /// The behaviours logged YES for the day that the analysis has unlocked, with their effect on
    /// Recovery; empty unless today's Recovery is scored. The expanded card shows them only when one has
    /// a known effect; otherwise the compact row.
    let behaviors: [Behavior]
    let week: Week
    /// "What shaped it": the engine's per-input points, or nil when the night cannot honestly score.
    let shaped: Shaped?
    /// The coach summary pill's local sentence (**bold** markdown, rendered).
    let summary: String
    /// The page in plain words, handed to the Coach when it opens from here.
    let coachSeed: String

    /// A behaviour chip.
    struct Behavior: Identifiable, Equatable {
        let id: String
        let title: String
        let effect: PulseBehaviorChip.Effect
        let spoken: String
    }

    /// The seven days ending on the dive's day.
    struct Week: Equatable {
        let recovery: [PulseChartDatum]
        let hrv: [PulseChartDatum]
        let rhr: [PulseChartDatum]
        let resp: [PulseChartDatum]
        /// The dive's own day, highlighted in every card.
        let highlightID: String
    }

    /// "What shaped it" (§3.4 item 7): one row per input that fed the score.
    struct Shaped: Equatable {
        let confidence: ScoreConfidence
        let rows: [Row]

        struct Row: Identifiable, Equatable {
            let id: String
            let title: String
            /// "65 ms · baseline 68 ms".
            let detail: String
            /// The input's signed contribution to the score.
            let points: Int
            let spoken: String
        }
    }
}
#endif
