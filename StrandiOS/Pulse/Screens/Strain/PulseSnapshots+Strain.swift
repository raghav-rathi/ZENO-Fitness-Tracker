#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - The rebuilt Strain deep dive's snapshot (WHOOP_UI_SPEC §3.5)
//
// Built off the main actor by `PulseSnapshotBuilder.strainDive(_:)`. The dial, the day's optimal range,
// its heart rate, curve, calories and workouts come from the foundation's `StrainSnapshot`, the resolver
// Home's Strain dial shares; this adds the contributors, the week and the copy.

struct StrainDiveSnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    let base: StrainSnapshot
    /// Heart-rate zones 1-3, zones 4-5, Strength Activity Time and steps, each against its 30-day average.
    let contributors: [PulseDiveContributor]
    /// The inline insight: the day's Strain band, or where it stands against its optimal range.
    let insight: String
    /// The day's seconds in zones 1-5, from the same resolver as the contributor rows; nil without heart
    /// rate. (The foundation's `zoneMinutes` is NOT used here, so this screen states one zone figure.)
    let zoneSeconds: [Double]?
    let activities: [Activity]
    let week: Week
    /// The coach summary pill's local sentence (**bold** markdown, rendered).
    let summary: String
    /// The page in plain words, handed to the Coach when it opens from here.
    let coachSeed: String

    /// The optimal range the screen may show: the day's own (never one carried from an earlier night's
    /// Recovery, which the dial does not draw either).
    var ownTarget: PulseStrainTarget? {
        guard let target = base.target, !target.fromCarriedRecovery else { return nil }
        return target
    }

    /// One row of Today's Activities.
    struct Activity: Identifiable, Equatable {
        let id: String
        let chip: PulseActivityChip.Kind
        let symbol: String
        let chipValue: String?
        let name: String
        /// Real instants, formatted in the device zone by the view.
        let start: Date
        let end: Date
        let route: PulseRoute
    }

    /// The seven days ending on the dive's day.
    struct Week: Equatable {
        let strain: [PulseChartDatum]
        /// Zone 1 at the bottom to Zone 3 at the top, h:mm totals.
        let lowerZones: [PulseStackedBarChart.Column]
        /// Zone 4 at the bottom, Zone 5 on top.
        let upperZones: [PulseStackedBarChart.Column]
        let steps: [PulseChartDatum]
        let calories: [PulseChartDatum]
        /// The catalog key the calories card's Trend View opens (imported or on-device).
        let caloriesMetric: String
        /// Where the steps card opens until the Trend View is rebuilt: the Steps screen on the day.
        let stepsRoute: PulseRoute
        let highlightID: String
    }
}
#endif
