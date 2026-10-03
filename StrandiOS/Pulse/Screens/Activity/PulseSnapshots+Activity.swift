#if os(iOS)
import SwiftUI
import StrandAnalytics
import WhoopStore

// MARK: - Activity snapshots (WHOOP_UI_SPEC §3.6, §3.8)
//
// Built off the main actor by `PulseSnapshotBuilder+Activity.swift`, with every figure already resolved:
// a view holding one of these does no store reads. Real instants (a workout's start, an HR sample) are
// `Date`s shown in the device zone; nothing here is keyed by a day.

/// Everything Activity Details draws for one workout.
struct ActivityDetailSnapshot: Equatable {
    /// Which layout the activity takes (§3.6 "Variants").
    enum Variant: Equatable {
        /// A strain activity: Activity Strain headline, heart rate and zones, key statistics.
        case strain
        /// Sauna, cold, breathwork, meditation: minutes headline, heart rate, session metrics.
        case recovery
        /// A session logged in the Lift Log: the strain headline plus EXERCISES | HR ZONES.
        case strength
    }

    /// What the "•••" menu may do to the row: imported history is never rewritten (`WorkoutsView`'s rule).
    enum Ownership: Equatable {
        /// Logged or recorded on this phone: Edit · Delete.
        case manual
        /// A legacy auto-detected bout: Edit (re-classify) · Not a workout.
        case detected
        /// Imported (Apple Health, a WHOOP export, a file, a lifting app): Edit a copy.
        case imported
        /// Paired with a Lift Log session, which owns its edits: Delete only.
        case liftLinked
        /// No longer in the store (deleted elsewhere): nothing to act on.
        case missing
    }

    let seq: Int
    /// The row as the store holds it now (or as it was handed in, when it is gone).
    let row: WorkoutRow
    let variant: Variant
    let ownership: Ownership
    /// "RUNNING".
    let title: String
    let symbol: String
    let start: Date
    let end: Date
    /// "6:45 AM to 7:30 AM", device zone.
    let timeRange: String
    /// The source chip ("VIA APPLE HEALTH", "AUTO-DETECTED", "MANUAL"), or nil.
    let sourceChip: String?
    /// The Lift Log program's name (the strength variant's workout chip), when it had one.
    let programChip: String?

    // Headline
    /// Activity Strain on the 0–21 axis; nil when the activity carries none.
    let strain: Double?
    /// This sport's average Strain over the 30 days before it (other sessions only).
    let strainAverage: Double?
    /// Why there is no Strain, when there is none.
    let strainNote: String?
    /// Steps over the session (on-foot sports with a step source).
    let steps: Int?
    /// Seconds between start and end.
    let durationSeconds: Double
    /// The recovery variant's "previous average" duration of this activity, seconds.
    let durationAverage: Double?

    // Heart rate
    /// Bucketed heart rate from a little before the start to a little after the end; nil is a gap.
    let hr: [PulseTimeValue]
    /// The chart's time span (the window plus its margins).
    let chartSpan: ClosedRange<Date>
    /// Heart-rate readings inside the activity's own window.
    let windowSampleCount: Int

    // Zones
    /// ZONE 5 down to ZONE 0.
    let zones: [ActivityZoneRow]
    /// The split came from an import's per-zone percentages rather than the strap's heart rate.
    let zonesFromImport: Bool
    /// The footnote under the zone rows.
    let zoneFootnote: String

    // Statistics
    let keyStats: [ActivityKeyStat]
    let hrRecovery: HeartRateRecovery.Result?
    let route: ActivityRouteSummary?
    let lift: ActivityLiftSummary?

    /// The local insight sentence (`**bold**` markdown), for the coach pill or the recovery card.
    let insight: String?

    var isRecoveryActivity: Bool { variant == .recovery }
    var hasHeartRate: Bool { windowSampleCount > 0 }
}

/// One zone's row (§2.6 item 18): "ZONE 4  162-171 BPM  2%" and its time.
struct ActivityZoneRow: Identifiable, Equatable {
    /// 0 (below Zone 1) to 5.
    let zone: Int
    /// "162-171 BPM", "172+ BPM", "<118 BPM", or the import's "(80-90%)".
    let range: String
    /// 0...1 of the activity's credited time.
    let share: Double
    let seconds: Double
    /// This sport's typical share (the middle half of recent sessions), as fractions of the bar.
    let typical: ClosedRange<Double>?

    var id: Int { zone }
}

/// One KEY STATISTICS / SESSION METRICS tile.
struct ActivityKeyStat: Identifiable, Equatable {
    let id: String
    /// "CALORIES".
    let title: String
    let icon: String
    /// "214".
    let value: String
    /// "cals", "bpm"; empty for a clock value.
    let unit: String
    /// The 30-day average printed in the chip ("137cals"), or nil when there is none to compare with.
    let average: String?
    /// How the value sits against that average: ▲ above, ▼ below, ● equal as printed.
    let direction: PulseTrend.Direction?
    /// Spoken form of the comparison.
    let accessibilityComparison: String?
}

/// The ROUTE card's drawing and its stats panel.
struct ActivityRouteSummary: Equatable {
    struct Point: Equatable {
        let lat: Double
        let lon: Double
    }

    let points: [Point]
    /// "3.5", "mi".
    let distance: (value: String, unit: String)
    /// "PACE" or "SPEED".
    let rateTitle: String
    let rate: (value: String, unit: String)
    let duration: String
    /// The route was recorded on this phone (vs an import).
    let recordedOnDevice: Bool

    static func == (lhs: ActivityRouteSummary, rhs: ActivityRouteSummary) -> Bool {
        lhs.points == rhs.points && lhs.distance == rhs.distance && lhs.rateTitle == rhs.rateTitle
            && lhs.rate == rhs.rate && lhs.duration == rhs.duration && lhs.recordedOnDevice == rhs.recordedOnDevice
    }
}

/// A Lift Log session paired with the workout (the strength variant's EXERCISES tab).
struct ActivityLiftSummary: Equatable {
    struct Exercise: Identifiable, Equatable {
        let name: String
        let workingSets: Int
        /// "100 kg × 5", or nil when no set carried a weight.
        let bestSet: String?
        /// "112 kg", Epley, or nil past the rep ceiling.
        let estimatedOneRepMax: String?
        var id: String { name }
    }

    /// The Lift Log session's id (deleting the activity deletes the session, as the Lift Log does).
    let sessionId: String
    let exercises: [Exercise]
    let workingSets: Int
    let totalReps: Int
    /// "3,114", with `massUnit`.
    let tonnage: String?
    let massUnit: String
    /// The Lift Log program the session ran, as it was named then.
    let programName: String?
}

// MARK: - Start Activity

/// What the pre-start screen and its Strain Target panel need (§3.8), for today.
struct StartActivitySnapshot: Equatable {
    let seq: Int
    /// Today's Recovery as the dial prints it, and its band; nil before Recovery scores.
    let recoveryPercent: Int?
    let recoveryBand: PulseDisplay.RecoveryBand?
    /// The Recovery behind the target is an earlier night's.
    let recoveryCarried: Bool
    /// Today's Strain so far, 0–21.
    let dayStrain: Double?
    /// Today's optimal range and its target (the range midpoint, §2.5), 0–21; nil without a Recovery.
    let optimalRange: ClosedRange<Double>?
    let targetDayStrain: Double?
    /// The scoring recipe's log-map denominator (Edwards' 7201 or Banister's), for the target math.
    let denominator: Double

    /// The Activity Strain that brings today to `dayTarget` (0–21), from `ActivityStrainTarget`.
    func activityStrain(toReach dayTarget: Double) -> Double? {
        let day = StrainScorer.effortValue(fromWhoopStrain: dayStrain ?? 0)
        let target = StrainScorer.effortValue(fromWhoopStrain: dayTarget)
        return ActivityStrainTarget.requiredActivityEffort(dayEffort: day, targetDayEffort: target,
                                                           denominator: denominator)
            .map { UnitFormatter.effortValue($0, scale: .whoop) }
    }

    /// The day an activity of `activityStrain` (0–21) would leave, 0–21.
    func estimatedDayStrain(adding activityStrain: Double) -> Double? {
        let day = StrainScorer.effortValue(fromWhoopStrain: dayStrain ?? 0)
        let activity = StrainScorer.effortValue(fromWhoopStrain: activityStrain)
        return ActivityStrainTarget.estimatedDayEffort(dayEffort: day, activityEffort: activity,
                                                       denominator: denominator)
            .map { UnitFormatter.effortValue($0, scale: .whoop) }
    }

    /// The recommended Activity Strain: what reaches today's target, nil without a Recovery.
    var recommendedActivityStrain: Double? {
        guard let targetDayStrain else { return nil }
        return activityStrain(toReach: targetDayStrain)
    }

    /// Where a day of `estimated` (0–21) sits against today's range.
    func trainingState(estimated: Double) -> ActivityStrainTarget.TrainingState? {
        optimalRange.map { ActivityStrainTarget.trainingState(estimatedDay: estimated, optimalRange: $0) }
    }
}

extension ActivityStrainTarget.TrainingState {
    /// "OPTIMAL", "RESTORATIVE", "OVERREACHING" (the Strain Coach article's words).
    var title: String {
        switch self {
        case .restorative: return String(localized: "Restorative")
        case .optimal: return String(localized: "Optimal")
        case .overreaching: return String(localized: "Overreaching")
        }
    }
}

// MARK: - Formatting

enum ActivityFormat {
    /// "6:45 AM to 7:30 AM", device zone.
    static func timeRange(_ start: Date, _ end: Date) -> String {
        String(localized: "\(PulseFormat.clock(start)) to \(PulseFormat.clock(end))")
    }

    /// "0:14:59", or "1:02:57".
    static func clock(seconds: Double) -> String {
        let total = seconds.isFinite ? max(0, Int(seconds.rounded())) : 0
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    /// The live band's "00:27:53".
    static func paddedClock(seconds: Double) -> String {
        let total = seconds.isFinite ? max(0, Int(seconds)) : 0
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    /// A live session's intensity word under its Activity Strain [Z]: the spec's Strain bands (Light,
    /// Moderate, Strenuous, All out), with WHOOP's "RESTING" below 5 (b02–b04 print it at 0.0–4.7).
    static func intensity(activityStrain: Double) -> String {
        switch activityStrain {
        case ..<5: return String(localized: "Resting")
        case ..<10: return String(localized: "Light")
        case ..<14: return String(localized: "Moderate")
        case ..<18: return String(localized: "Strenuous")
        default: return String(localized: "All out")
        }
    }
}
#endif
