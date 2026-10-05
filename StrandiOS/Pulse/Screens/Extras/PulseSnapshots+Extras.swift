#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Snapshots for the extras screens (group "extras")
//
// Immutable values the day timeline, Year in Review and Challenges render from, built off the main actor in
// `PulseSnapshotBuilder+Extras.swift`. Instants (a heart-rate bucket, sleep onset, a workout) are `Date`s
// shown in the device zone; anything named by a day key is formatted at UTC (`PulseFormat.dayLabel`).

// MARK: Day heart-rate timeline (§3.7)

/// The expanded day heart-rate timeline: the day window's heart rate with its sleep and activity bands, the
/// Recovery marker at wake and the Strain marker at the last reading.
struct DayTimelineSnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    /// The span the chart covers: the day window's start (last night's onset with the day-cycle setting,
    /// else midnight) to the newest reading (today) or the window's end (a finished day).
    let start: Date
    let end: Date
    /// Heart rate at day scale (about one point per point of a landscape plot) and at ⊕ scale.
    let overview: [DayTimelinePoint]
    let detail: [DayTimelinePoint]
    /// The bucket widths behind `overview` and `detail`, seconds.
    let overviewBucket: Int
    let detailBucket: Int
    /// Sleep, naps and activities, oldest first, clipped to the span.
    let periods: [DayTimelinePeriod]
    /// The day's own Recovery at the time its night ended. nil when the day has no scored Recovery of its
    /// own (a carried value belongs to another night, so it is not pinned here).
    let recovery: DayTimelineMarker?
    /// The day's Strain (0–21) at the newest reading.
    let strain: DayTimelineMarker?
    /// The newest heart-rate reading inside the span.
    let lastReading: Date?
    /// Over the raw readings of the window, the figures the Strain dive prints for the same day.
    let lowest: Int?
    let average: Int?
    let highest: Int?

    var hasHeartRate: Bool { !overview.isEmpty }

    /// The instant the axis names at the chart's end. A finished day's window ends one second before the
    /// next day begins, so it reads "12:00 AM" (the next midnight), never "11:59 PM"; today ends at its
    /// newest reading.
    var endLabelDate: Date { day.isToday ? end : end.addingTimeInterval(1) }
}

/// One heart-rate bucket.
struct DayTimelinePoint: Equatable {
    let date: Date
    let bpm: Double
    /// Contiguous-run index: a bucket with no reading starts a new run, drawn as a gap, never a line.
    let run: Int
}

/// A shaded period on the timeline.
struct DayTimelinePeriod: Equatable, Identifiable {
    enum Kind: Equatable {
        case sleep, nap, activity
        var isSleep: Bool { self != .activity }
    }

    let id: String
    let kind: Kind
    let start: Date
    let end: Date
    /// The glyph over the band ("moon.fill", a sport symbol).
    let symbol: String
    /// The figure under the glyph: time asleep ("7:29") or the activity's Strain ("13.8").
    let value: String?
    /// The activity's name ("Running"), or "Sleep" / "Nap".
    let title: String
    /// Spoken: "Sleep, 7 hours 29 minutes", "Running, Strain 13.8".
    let accessibilityLabel: String

    func contains(_ date: Date) -> Bool { date >= start && date <= end }
}

/// A dashed vertical marker with its label in the strip: RECOVERY at wake, STRAIN at the newest reading.
struct DayTimelineMarker: Equatable {
    let date: Date
    /// "65%" or "4.2".
    let value: String
    /// The Recovery band (its colour); nil for Strain.
    let band: PulseDisplay.RecoveryBand?
}

// MARK: Year in Review (§3.39)

/// ZENO's local Year in Review: the wearer's own year, with no other members to compare against.
struct YearInReviewSnapshot: Equatable {
    let seq: Int
    let year: Int
    /// The year is still running: the review covers 1 January to `through` (a "so far" review).
    let isPartial: Bool
    /// The last day counted (today, or 31 December), a day key.
    let through: String
    let summary: YearInReview.Summary
    /// Journal behaviours ranked by how Recovery differed on the days they were logged, this year.
    let behaviors: [YearReviewBehavior]
    /// The most logged activity's glyph.
    let topActivitySymbol: String?
    /// ZENO Age: the year's last weekly Body Age (`VitalityEngine`, the value the Health tab shows), or nil
    /// when none was computed in the year.
    let zenoAge: Double?
    /// The Level every scored Recovery up to `through` reaches (Profile's rule, so this year's review prints
    /// Profile's Level; a past year's, the Level that year ended on).
    let level: PulseLevels.Progress
}

/// One behaviour on the "Behavior impacts on Recovery" slide.
struct YearReviewBehavior: Equatable, Identifiable {
    /// The journal question, verbatim (the behaviour's key).
    let id: String
    /// The bar's label: the wearer's own name for the behaviour when they renamed it in the journal, else a
    /// short form of the question ("Drink any alcohol").
    let title: String
    /// Recovery on days with the behaviour against days without, as a percent of the without-days' mean.
    let percent: Double
    /// The ranker's false-discovery-corrected verdict; the rest are drawn muted.
    let significant: Bool
    let daysWith: Int
    let daysWithout: Int
}

// MARK: Challenges (§3.41)

/// The wearer's challenges, measured.
struct ChallengesSnapshot: Equatable {
    let seq: Int
    /// The local day the build measured to.
    let today: String
    let items: [ChallengeSnapshot]
}

/// One challenge: where it stands and what counted, by day.
struct ChallengeSnapshot: Equatable, Identifiable {
    let id: String
    let definition: ChallengeProgress.Definition
    let status: ChallengeProgress.Status
    /// The day the wearer left it, if they did.
    let leftOn: String?
    /// The days that counted something (or whose night was judged), newest first.
    let days: [ChallengeDay]
}

/// One day of a challenge's list.
struct ChallengeDay: Equatable, Identifiable {
    /// The day key.
    let id: String
    let entries: [ChallengeEntry]
}

/// One line under a day: a workout (activity challenges) or the day's amount.
enum ChallengeEntry: Equatable, Identifiable {
    case workout(PulseWorkoutItem, end: Date)
    /// "Zone 2 · 34 min", "8,412 steps", "Asleep 10:52 PM" and whether a night met the bedtime.
    case amount(id: String, title: String, value: String, met: Bool?)

    var id: String {
        switch self {
        case .workout(let item, _): return item.id
        case .amount(let id, _, _, _): return id
        }
    }
}

// MARK: ZENO Live (§3.10)

/// Today's numbers for the ZENO Live overlay: Home's three dials and the newest heart rate.
struct ZenoLiveSnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    let sleep: PulseDialData
    let recovery: PulseDialData
    let strain: PulseDialData
    /// The newest heart-rate reading, when it is recent enough to call current (the last 15 minutes).
    let heartRate: Int?
    let heartRateAt: Date?
}
#endif
