import Foundation

// YearInReview.swift - the year's highlights behind ZENO's Year in Review story (WHOOP_UI_SPEC §3.39).
//
// WHOOP's Year in Review ranks a member against other members ("Top 2%", "43% of members achieved this").
// ZENO has no other members, so every figure here is the wearer's own: the year's best and worst days,
// how often each pillar reached its optimal mark, the longest run of scored days, and a persona picked by
// fixed rules from those figures. Nothing is scored here. Recovery, Strain, Sleep performance, time asleep
// and steps arrive already resolved by the engine (the caller passes the same values its screens show);
// this only selects, counts and averages them.
//
// Pure, deterministic and display-only: no clock (the caller passes the last day to count), no store, and
// nothing persisted or sent across the .noopbak boundary, so, like PulseDisplay, there is no Kotlin twin to
// keep byte-identical. Day keys are "yyyy-MM-dd" civil days and compare as strings.

public enum YearInReview {

    // MARK: Inputs

    /// One day of the year as the review reads it. Any field may be missing; a missing value is skipped,
    /// never counted as zero.
    public struct Day: Equatable, Sendable {
        public let day: String
        /// Recovery, 0-100.
        public let recovery: Double?
        /// Day Strain on WHOOP's 0-21 axis.
        public let strain: Double?
        /// Sleep performance of the night that ended on this day, 0-100.
        public let sleepPerformance: Double?
        /// Time asleep of the night that ended on this day, minutes.
        public let asleepMinutes: Double?
        public let steps: Int?

        public init(day: String, recovery: Double? = nil, strain: Double? = nil, sleepPerformance: Double? = nil,
                    asleepMinutes: Double? = nil, steps: Int? = nil) {
            self.day = day
            self.recovery = recovery
            self.strain = strain
            self.sleepPerformance = sleepPerformance
            self.asleepMinutes = asleepMinutes
            self.steps = steps
        }

        /// The strap scored something for the day (steps alone can come from the phone).
        public var isTracked: Bool {
            recovery != nil || strain != nil || sleepPerformance != nil || asleepMinutes != nil
        }
    }

    /// One logged activity.
    public struct Activity: Equatable, Sendable {
        public let day: String
        /// The display name the activity lists use ("Running").
        public let name: String
        public let minutes: Double

        public init(day: String, name: String, minutes: Double) {
            self.day = day
            self.name = name
            self.minutes = minutes
        }
    }

    // MARK: Outputs

    /// A day that stood out, and its value.
    public struct Moment: Equatable, Sendable {
        public let day: String
        public let value: Double

        public init(day: String, value: Double) {
            self.day = day
            self.value = value
        }
    }

    /// The activity logged most often.
    public struct TopActivity: Equatable, Sendable {
        public let name: String
        public let count: Int
        public let minutes: Double
    }

    /// The three pillars, in the order WHOOP names them.
    public enum Pillar: String, CaseIterable, Sendable {
        case sleep, recovery, strain
    }

    /// How often a pillar reached its optimal mark: Sleep performance 85% or better (WHOOP's Optimal),
    /// a green Recovery (67% or better), or a Day Strain inside that day's optimal range.
    public struct PillarScore: Equatable, Sendable {
        public let pillar: Pillar
        public let hits: Int
        public let days: Int

        public var share: Double { days > 0 ? Double(hits) / Double(days) : 0 }
    }

    /// The year's persona, picked by fixed rules (`persona(trackedDays:coverage:best:)`).
    public enum Persona: String, CaseIterable, Sendable {
        /// Under two weeks of data: the year is still the groundwork.
        case groundwork
        /// Worn nearly every day, with no pillar clearly ahead.
        case consistency
        /// Sleep was the strongest pillar.
        case sleep
        /// Recovery was the strongest pillar.
        case recovery
        /// Strain was the strongest pillar.
        case strain
    }

    public struct Summary: Equatable, Sendable {
        public let year: Int
        /// The last day counted (the caller's today, or the year's last day).
        public let through: String
        /// Days from 1 January to `through`.
        public let elapsedDays: Int
        /// Days the strap scored anything.
        public let trackedDays: Int
        public let firstTrackedDay: String?
        public let recoveries: Int
        public let nights: Int
        public let bestSleep: Moment?
        public let longestSleep: Moment?
        public let peakRecovery: Moment?
        public let lowestRecovery: Moment?
        public let maxStrain: Moment?
        public let averageRecovery: Double?
        public let averageSleepPerformance: Double?
        public let averageAsleepMinutes: Double?
        public let averageStrain: Double?
        public let activities: Int
        public let activityMinutes: Double
        public let topActivity: TopActivity?
        /// Total steps over the days that counted any, or nil when none did.
        public let steps: Int?
        public let stepDays: Int
        /// The longest run of consecutive days with a Recovery score inside the year.
        public let longestStreak: Int
        /// The pillars with at least `minimumPillarDays` readings, in `Pillar` order.
        public let pillars: [PillarScore]
        public let bestPillar: Pillar?
        public let persona: Persona

        /// The share of the elapsed days the strap scored.
        public var coverage: Double { elapsedDays > 0 ? Double(trackedDays) / Double(elapsedDays) : 0 }
        /// Enough data for the full story; below it the screen says what is missing instead.
        public var hasStory: Bool { trackedDays >= YearInReview.minimumStoryDays }
        public var bestPillarScore: PillarScore? { pillars.first { $0.pillar == bestPillar } }
    }

    // MARK: Rules

    /// Days of data before the story is told.
    public static let minimumStoryDays = 14
    /// Readings a pillar needs before it can be the strongest.
    public static let minimumPillarDays = 14
    /// WHOOP's Optimal sleep band starts here (whole percent).
    public static let sleepOptimalPercent = 85
    /// Worn on this share of the elapsed days or more reads as "showed up every day".
    public static let consistencyCoverage = 0.9
    /// A pillar this far ahead (share of days on its mark) wins the persona over consistency.
    public static let clearPillarShare = 0.5
    /// The Everest equivalence (spec §3.39 [Z]): each step counted as ≈0.16 m of climb (a stair), against
    /// 8,848.86 m. A deliberate deviation from WHOOP's own figure: its 2025 story calls 808,735 steps
    /// "Everest 8 times" (profile-community-2026/50), ≈0.0875 m a step, a rule it never states. ZENO keeps the
    /// spec's stair and says so in the sentence ("Counted as 16 cm stairs"), so the number can be checked.
    public static let metresPerStep = 0.16
    public static let everestMetres = 8_848.86

    /// How many times the steps would climb Everest at `metresPerStep` each.
    public static func everestClimbs(steps: Int) -> Double {
        Double(max(0, steps)) * metresPerStep / everestMetres
    }

    /// Days from 1 January of `year` to `through`, inclusive, capped at the year's length; 0 when `through`
    /// is before the year or unparseable.
    public static func elapsedDays(year: Int, through: String) -> Int {
        guard let first = Baselines.isoEpochDay(String(format: "%04d-01-01", year)),
              let last = Baselines.isoEpochDay(String(format: "%04d-12-31", year)),
              let end = Baselines.isoEpochDay(through) else { return 0 }
        let upTo = min(end, last)
        return upTo >= first ? upTo - first + 1 : 0
    }

    /// The persona for a year: under `minimumStoryDays` tracked days it is still the groundwork; worn on
    /// `consistencyCoverage` of the days with no pillar on its mark at least `clearPillarShare` of the time,
    /// it is consistency; otherwise the strongest pillar, falling back to consistency or groundwork.
    public static func persona(trackedDays: Int, coverage: Double, best: PillarScore?) -> Persona {
        guard trackedDays >= minimumStoryDays else { return .groundwork }
        if coverage >= consistencyCoverage && (best?.share ?? 0) < clearPillarShare { return .consistency }
        if let best {
            switch best.pillar {
            case .sleep: return .sleep
            case .recovery: return .recovery
            case .strain: return .strain
            }
        }
        return coverage >= consistencyCoverage ? .consistency : .groundwork
    }

    /// Summarise `year` up to and including `through`. Days and activities outside the year, or after
    /// `through`, are ignored. `strainRange` gives the optimal Day Strain range for a Recovery percent (the
    /// app passes the band rule its Strain target uses); a day without one does not count toward Strain.
    public static func summarize(year: Int, through: String, days: [Day], activities: [Activity],
                                 strainRange: (Double) -> ClosedRange<Double>?) -> Summary {
        let prefix = String(format: "%04d-", year)
        let inYear: (String) -> Bool = { $0.hasPrefix(prefix) && $0 <= through }

        // One row per day (the last wins), oldest first, so ties go to the earliest day.
        var byDay: [String: Day] = [:]
        for d in days where inYear(d.day) { byDay[d.day] = d }
        let ordered = byDay.keys.sorted().compactMap { byDay[$0] }

        func maxMoment(_ value: (Day) -> Double?) -> Moment? {
            var best: Moment?
            for d in ordered {
                guard let v = value(d), v.isFinite else { continue }
                if best == nil || v > best!.value { best = Moment(day: d.day, value: v) }
            }
            return best
        }
        func minMoment(_ value: (Day) -> Double?) -> Moment? {
            var best: Moment?
            for d in ordered {
                guard let v = value(d), v.isFinite else { continue }
                if best == nil || v < best!.value { best = Moment(day: d.day, value: v) }
            }
            return best
        }
        func mean(_ value: (Day) -> Double?) -> Double? {
            let vs = ordered.compactMap(value).filter(\.isFinite)
            return vs.isEmpty ? nil : vs.reduce(0, +) / Double(vs.count)
        }

        let tracked = ordered.filter(\.isTracked)

        // Pillars: how often each reached its optimal mark.
        var pillars: [PillarScore] = []
        let sleepDays = ordered.compactMap(\.sleepPerformance)
        let sleepHits = sleepDays.filter { PulseDisplay.displayedPercent($0) >= sleepOptimalPercent }.count
        if sleepDays.count >= minimumPillarDays {
            pillars.append(PillarScore(pillar: .sleep, hits: sleepHits, days: sleepDays.count))
        }
        let recoveryDays = ordered.compactMap(\.recovery)
        let greenDays = recoveryDays.filter { PulseDisplay.recoveryBand(percent: $0) == .green }.count
        if recoveryDays.count >= minimumPillarDays {
            pillars.append(PillarScore(pillar: .recovery, hits: greenDays, days: recoveryDays.count))
        }
        var strainDays = 0, strainHits = 0
        for d in ordered {
            guard let strain = d.strain, let recovery = d.recovery,
                  let range = strainRange(Double(PulseDisplay.displayedPercent(recovery))) else { continue }
            strainDays += 1
            if range.contains(strain) { strainHits += 1 }
        }
        if strainDays >= minimumPillarDays {
            pillars.append(PillarScore(pillar: .strain, hits: strainHits, days: strainDays))
        }
        // The highest share wins; a tie keeps the earlier pillar (Sleep, Recovery, Strain).
        var best: PillarScore?
        for p in pillars where best == nil || p.share > best!.share { best = p }

        // Activities.
        let yearActivities = activities.filter { inYear($0.day) }
        var counts: [String: (count: Int, minutes: Double)] = [:]
        for a in yearActivities {
            let cur = counts[a.name] ?? (0, 0)
            counts[a.name] = (cur.count + 1, cur.minutes + max(0, a.minutes))
        }
        let top = counts.sorted { lhs, rhs in
            if lhs.value.count != rhs.value.count { return lhs.value.count > rhs.value.count }
            if lhs.value.minutes != rhs.value.minutes { return lhs.value.minutes > rhs.value.minutes }
            return lhs.key < rhs.key
        }.first.map { TopActivity(name: $0.key, count: $0.value.count, minutes: $0.value.minutes) }

        // Steps.
        let stepValues = ordered.compactMap(\.steps).filter { $0 > 0 }

        let streak = StreakCalculator.streaks(dayKeys: ordered.map(\.day),
                                              qualified: ordered.map { $0.recovery != nil },
                                              today: through).longest

        let elapsed = elapsedDays(year: year, through: through)
        let coverage = elapsed > 0 ? Double(tracked.count) / Double(elapsed) : 0
        return Summary(
            year: year, through: through, elapsedDays: elapsed, trackedDays: tracked.count,
            firstTrackedDay: tracked.first?.day,
            recoveries: recoveryDays.count,
            nights: ordered.filter { $0.asleepMinutes != nil || $0.sleepPerformance != nil }.count,
            bestSleep: maxMoment(\.sleepPerformance), longestSleep: maxMoment(\.asleepMinutes),
            peakRecovery: maxMoment(\.recovery), lowestRecovery: minMoment(\.recovery),
            maxStrain: maxMoment(\.strain),
            averageRecovery: mean(\.recovery), averageSleepPerformance: mean(\.sleepPerformance),
            averageAsleepMinutes: mean(\.asleepMinutes), averageStrain: mean(\.strain),
            activities: yearActivities.count,
            activityMinutes: yearActivities.reduce(0) { $0 + max(0, $1.minutes) },
            topActivity: top,
            steps: stepValues.isEmpty ? nil : stepValues.reduce(0, +), stepDays: stepValues.count,
            longestStreak: streak, pillars: pillars, bestPillar: best?.pillar,
            persona: persona(trackedDays: tracked.count, coverage: coverage, best: best))
    }
}
