import Foundation

// AutoBehaviors.swift — behaviours Behavior Insights tracks from ZENO's own data (WHOOP_UI_SPEC §3.18
// "Auto-tracked behaviours"), so they sit beside the journal's answers without anyone logging them.
//
// Pure, deterministic, DB-free. Each returns `BehaviorImpact.Answers`: the day keys the behaviour happened
// (yes) and the day keys it demonstrably did not (no). A day the data cannot judge is in neither, exactly
// as an unanswered journal question is, so a missing night or an unscored day is never read as a "no".
//
// Day alignment follows the journal's wake-day convention: day D's answers describe the day and night
// leading INTO the morning of D, and are compared with D's Recovery. So:
//   - "85%+ Sleep Performance" on D reads the night that ended on D;
//   - "10+ Strain" on D reads the Day Strain of D − 1, the day before that morning;
//   - "Late Workout" on D asks whether a workout ended within 3 h of the onset of the night ending on D;
//   - "Early Workout" on D asks whether a workout started within 3 h of waking on D − 1 (that morning's
//     Recovery was already set when it happened, so it can only reach the next one);
//   - "Consistent Bed / Wake Time" on D compares that night's bedtime / wake time with the nights before.

public enum AutoBehaviors {

    /// Sleep Performance (%) a night must reach to count as "85%+ Sleep Performance".
    public static let sleepPerformanceThreshold: Double = 85
    /// Day Strain (0–21) the previous day must reach to count as "10+ Strain".
    public static let strainThreshold: Double = 10
    /// A workout ending this close before sleep onset is a late workout (WHOOP: "within 3 hours").
    public static let lateWorkoutWindowSec = 3 * 3_600
    /// A workout starting this soon after waking is an early workout. WHOOP names the behaviour but not
    /// its rule; ZENO mirrors the late-workout window from the other end of the day.
    public static let earlyWorkoutWindowSec = 3 * 3_600
    /// A bed or wake time within this many minutes of the recent median counts as consistent.
    public static let consistencyToleranceMin: Double = 30
    /// Nights before the judged one that set its median, and how many of them must be present.
    public static let consistencyLookbackNights = 14
    public static let consistencyMinPriorNights = 5

    /// Yes on the days whose value reaches `threshold`, no on the days below it.
    public static func atLeast(_ threshold: Double, valueByDay: [String: Double]) -> BehaviorImpact.Answers {
        var a = BehaviorImpact.Answers()
        for (day, value) in valueByDay where value.isFinite {
            if value >= threshold { a.yes.insert(day) } else { a.no.insert(day) }
        }
        return a
    }

    /// Day D is yes when the PREVIOUS calendar day's value reaches `threshold` and no when it is below;
    /// a day whose previous day has no value is in neither.
    public static func previousDayAtLeast(_ threshold: Double, valueByDay: [String: Double]) -> BehaviorImpact.Answers {
        var a = BehaviorImpact.Answers()
        for (day, value) in valueByDay where value.isFinite {
            guard let next = PulseDisplay.dayKey(day, offsetBy: 1) else { continue }
            if value >= threshold { a.yes.insert(next) } else { a.no.insert(next) }
        }
        return a
    }

    /// One night's main sleep: the wake-day key, its onset (unix seconds), the local clock minutes of its
    /// onset and wake, and its wake (unix seconds) when known.
    public struct Night: Equatable, Sendable {
        public let day: String
        public let onsetTs: Int
        public let bedMinute: Double
        public let wakeMinute: Double
        public let wakeTs: Int?

        public init(day: String, onsetTs: Int, bedMinute: Double, wakeMinute: Double, wakeTs: Int? = nil) {
            self.day = day
            self.onsetTs = onsetTs
            self.bedMinute = bedMinute
            self.wakeMinute = wakeMinute
            self.wakeTs = wakeTs
        }
    }

    /// Day D is yes when any workout ended within `window` seconds before the onset of the night that
    /// ended on D (and not after it), no when none did. Only nights we know the onset of are judged.
    public static func lateWorkout(nights: [Night], workoutEnds: [Int],
                                   window: Int = lateWorkoutWindowSec) -> BehaviorImpact.Answers {
        let ends = workoutEnds.sorted()
        var a = BehaviorImpact.Answers()
        for night in nights {
            let lo = night.onsetTs - window
            let late = ends.contains { $0 >= lo && $0 <= night.onsetTs }
            if late { a.yes.insert(night.day) } else { a.no.insert(night.day) }
        }
        return a
    }

    /// Day D is yes when a workout STARTED within `window` seconds after the wake of the night that ended
    /// on D − 1 (not before it), no when none did. Only mornings whose wake time is known are judged, and
    /// the answer lands on the next day because that morning's Recovery was set before the workout.
    public static func earlyWorkout(nights: [Night], workoutStarts: [Int],
                                    window: Int = earlyWorkoutWindowSec) -> BehaviorImpact.Answers {
        var a = BehaviorImpact.Answers()
        for night in nights {
            guard let wake = night.wakeTs, let next = PulseDisplay.dayKey(night.day, offsetBy: 1) else { continue }
            let early = workoutStarts.contains { $0 >= wake && $0 <= wake + window }
            if early { a.yes.insert(next) } else { a.no.insert(next) }
        }
        return a
    }

    /// Day D is yes when its clock minute is within `tolerance` minutes (around the 24 h dial) of the
    /// median of the previous `lookback` calendar days' minutes, no when further; judged only with at least
    /// `minPrior` of those days present.
    public static func consistent(minuteByDay: [String: Double],
                                  tolerance: Double = consistencyToleranceMin,
                                  lookback: Int = consistencyLookbackNights,
                                  minPrior: Int = consistencyMinPriorNights) -> BehaviorImpact.Answers {
        var a = BehaviorImpact.Answers()
        for (day, minute) in minuteByDay where minute.isFinite {
            let prior = (1...max(1, lookback)).compactMap { back -> Int? in
                guard let key = PulseDisplay.dayKey(day, offsetBy: -back), let m = minuteByDay[key],
                      m.isFinite else { return nil }
                return Int(m.rounded())
            }
            guard prior.count >= minPrior, let median = PulseDisplay.medianClockMinute(prior) else { continue }
            if SleepConsistency.circularDistanceMin(minute, Double(median)) <= tolerance {
                a.yes.insert(day)
            } else {
                a.no.insert(day)
            }
        }
        return a
    }
}
