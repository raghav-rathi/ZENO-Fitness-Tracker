import Foundation

// ChallengeProgress.swift - progress through a personal challenge (WHOOP_UI_SPEC §3.41, ZENO's local version).
//
// WHOOP runs timed challenges for its members ("All-In 250": 250 activity minutes in 7 days) and pays a
// reward. ZENO lets the wearer set their own, with no reward and nothing leaving the phone: a target over a
// run of local days. What each day counted (activity minutes, Zone 2 minutes, steps, a night in bed on
// time) is measured by the app's existing resolvers and handed in per day; this file only adds the days
// up, decides where the challenge stands and on which day it was won, and judges a bedtime.
//
// Pure, deterministic and display-only: the definitions live on this iPhone and never cross the .noopbak
// boundary, so, like PulseDisplay, there is no Kotlin twin. Day keys are local "yyyy-MM-dd" civil days.

public enum ChallengeProgress {

    /// What a challenge counts.
    public enum Kind: String, Codable, CaseIterable, Sendable {
        /// Minutes of logged activity (workouts), summed.
        case activityMinutes
        /// Minutes in heart-rate Zone 2, summed.
        case zoneMinutes
        /// Steps, summed.
        case steps
        /// Nights in bed by a set time, counted.
        case bedtime
    }

    /// A challenge as the wearer set it.
    public struct Definition: Equatable, Codable, Sendable {
        public let kind: Kind
        /// Minutes, steps or nights.
        public let target: Int
        /// Its length in days (at least 1).
        public let days: Int
        /// Its first day.
        public let startDay: String
        /// Bedtime challenges: the latest time in bed that counts, minutes after midnight (23:00 is 1380).
        public let bedtimeMinute: Int?

        public init(kind: Kind, target: Int, days: Int, startDay: String, bedtimeMinute: Int? = nil) {
            self.kind = kind
            self.target = max(1, target)
            self.days = max(1, days)
            self.startDay = startDay
            self.bedtimeMinute = bedtimeMinute
        }

        /// Its last day.
        public var endDay: String { PulseDisplay.dayKey(startDay, offsetBy: days - 1) ?? startDay }

        /// Every day it runs, first to last.
        public var dayKeys: [String] {
            (0..<days).compactMap { PulseDisplay.dayKey(startDay, offsetBy: $0) }
        }
    }

    /// Where a challenge stands.
    public enum Phase: String, Equatable, Sendable {
        /// Its first day has not come yet.
        case upcoming
        /// Under way and short of the target.
        case running
        /// The target was reached (it keeps counting, as WHOOP's "460/250" does).
        case complete
        /// The last day passed short of the target, or the wearer left it.
        case ended
    }

    public struct Status: Equatable, Sendable {
        /// The total so far.
        public let logged: Double
        public let target: Int
        public let phase: Phase
        /// While running, the days left including today; the whole length while upcoming; else 0.
        public let daysLeft: Int
        /// The day the running total reached the target.
        public let completedOn: String?

        public var fraction: Double { target > 0 ? logged / Double(target) : 0 }
        public var remaining: Double { max(0, Double(target) - logged) }
    }

    /// Where `definition` stands on `today`, from what each day counted. Days outside the challenge and
    /// after today are ignored, as are negative counts. It is complete from the day the running total
    /// reaches the target, even if the wearer left it afterwards; otherwise it ends when its last day has
    /// passed or the wearer left it (`endedEarly`).
    public static func status(_ definition: Definition, perDay: [String: Double], today: String,
                              endedEarly: Bool = false) -> Status {
        var total = 0.0
        var completedOn: String?
        for key in definition.dayKeys where key <= today {
            total += max(0, perDay[key] ?? 0)
            if completedOn == nil && total >= Double(definition.target) { completedOn = key }
        }
        let phase: Phase
        if today < definition.startDay && !endedEarly {
            phase = .upcoming
        } else if completedOn != nil {
            phase = .complete
        } else if endedEarly || today > definition.endDay {
            phase = .ended
        } else {
            phase = .running
        }
        let daysLeft: Int
        switch phase {
        case .upcoming:
            daysLeft = definition.days
        case .running:
            if let end = Baselines.isoEpochDay(definition.endDay), let now = Baselines.isoEpochDay(today) {
                daysLeft = max(1, end - now + 1)
            } else {
                daysLeft = 1
            }
        case .complete, .ended:
            daysLeft = 0
        }
        return Status(logged: total, target: definition.target, phase: phase, daysLeft: daysLeft,
                      completedOn: completedOn)
    }

    /// Whether a night's time in bed meets a bedtime target. A time before noon is after midnight, so
    /// 00:30 is later than 23:00; a target after midnight is read the same way.
    public static func isInBedBy(onsetMinute: Int, target: Int) -> Bool {
        func evening(_ minute: Int) -> Int {
            let m = ((minute % 1_440) + 1_440) % 1_440
            return m < 12 * 60 ? m + 1_440 : m
        }
        return evening(onsetMinute) <= evening(target)
    }

    /// The evening a night belongs to: the day its sleep began, or the day before when it began after
    /// midnight (before noon).
    public static func nightKey(onsetDayKey: String, onsetMinute: Int) -> String {
        onsetMinute < 12 * 60 ? (PulseDisplay.dayKey(onsetDayKey, offsetBy: -1) ?? onsetDayKey) : onsetDayKey
    }

    /// A first suggestion for each kind: WHOOP's All-In 250 for activity minutes, then targets of the same
    /// week-long shape for the others.
    public static func suggested(_ kind: Kind, startDay: String) -> Definition {
        switch kind {
        case .activityMinutes:
            return Definition(kind: kind, target: 250, days: 7, startDay: startDay)
        case .zoneMinutes:
            return Definition(kind: kind, target: 150, days: 7, startDay: startDay)
        case .steps:
            return Definition(kind: kind, target: 70_000, days: 7, startDay: startDay)
        case .bedtime:
            return Definition(kind: kind, target: 7, days: 7, startDay: startDay, bedtimeMinute: 23 * 60)
        }
    }
}
