import Foundation

// StressDayTotals.swift — the Stress Monitor's TOTAL DAY figures from a day's scored stress hours.
//
// WHOOP's TOTAL DAY card (WHOOP_UI_SPEC §3.22 item 6) splits a day into time spent LOW / MEDIUM / HIGH
// and sets it against a "typical" day of the same weekday. ZENO reads the same split off its own
// intraday stress (`DaytimeStress.Result.hours`): every scored hour counts its sixty minutes in the
// band its level falls in (LOW 0.0–0.9, MEDIUM 1.0–1.9, HIGH 2.0–3.0, the shared 0–3 bands). The
// overlapping display timeline is never counted, for the reason `DaytimeStress.timeline` gives: two
// overlapping windows would count one minute twice. So `totals(...).highMinutes` equals the result's
// own `highStressMinutes`.
//
// "Typical" is the mean of the same weekday over the previous weeks (§3.22 [Z]: 4–8 weeks), counting
// only days that were really worn, and it can be cut at an hour of the day so that a day still in
// progress is set against the same hours of its typical day, not against whole days.
//
// Pure, database-free and deterministic. Hours that were masked for activity or had too little signal
// carry no level and count nowhere: missing time is never filled in.
public enum StressDayTotals {

    /// The shared 0–3 bands.
    public enum Level: Int, CaseIterable, Equatable, Sendable {
        case low, medium, high

        /// LOW below 1.0, MEDIUM below 2.0, HIGH from 2.0 (`DaytimeStress.highBandFloor`).
        public init(score: Double) {
            if score >= DaytimeStress.highBandFloor { self = .high } else if score >= 1.0 { self = .medium } else { self = .low }
        }
    }

    /// Minutes spent in each band.
    public struct Totals: Equatable, Sendable {
        public let lowMinutes: Int
        public let mediumMinutes: Int
        public let highMinutes: Int

        public init(lowMinutes: Int, mediumMinutes: Int, highMinutes: Int) {
            self.lowMinutes = lowMinutes
            self.mediumMinutes = mediumMinutes
            self.highMinutes = highMinutes
        }

        public static let zero = Totals(lowMinutes: 0, mediumMinutes: 0, highMinutes: 0)

        /// All scored time.
        public var scoredMinutes: Int { lowMinutes + mediumMinutes + highMinutes }

        public func minutes(_ level: Level) -> Int {
            switch level {
            case .low: return lowMinutes
            case .medium: return mediumMinutes
            case .high: return highMinutes
            }
        }

        /// The band's share of the scored time, 0…1 (0 when nothing was scored).
        public func share(_ level: Level) -> Double {
            scoredMinutes > 0 ? Double(minutes(level)) / Double(scoredMinutes) : 0
        }

        /// The band holding the most time; ties go to the calmer band. nil when nothing was scored.
        public var dominant: Level? {
            guard scoredMinutes > 0 else { return nil }
            return Level.allCases.max { a, b in
                let ma = minutes(a), mb = minutes(b)
                return ma != mb ? ma < mb : a.rawValue > b.rawValue
            }
        }
    }

    /// Minutes per scored hour.
    public static let minutesPerHour = DaytimeStress.bucketSeconds / 60
    /// A day counts towards "typical" only with at least this many scored hours (a strap worn for an
    /// hour is not a day).
    public static let minTypicalHours = 4
    /// Fewer qualifying days than this: no typical day.
    public static let minTypicalDays = 2

    /// Time in each band over `hours`, optionally only hours that START before local hour-of-day
    /// `beforeHour` (so today so far meets the same hours of its typical day).
    public static func totals(_ hours: [DaytimeStress.HourPoint], beforeHour: Int? = nil) -> Totals {
        var low = 0, medium = 0, high = 0
        for h in hours {
            guard let level = h.level else { continue }
            if let cut = beforeHour, h.hour >= cut { continue }
            switch Level(score: level) {
            case .low: low += minutesPerHour
            case .medium: medium += minutesPerHour
            case .high: high += minutesPerHour
            }
        }
        return Totals(lowMinutes: low, mediumMinutes: medium, highMinutes: high)
    }

    /// The typical day: each band's mean minutes over the `days` that were worn (at least
    /// `minTypicalHours` scored hours in the span counted), rounded to whole minutes. nil when fewer than
    /// `minTypicalDays` qualify.
    public static func typical(_ days: [[DaytimeStress.HourPoint]], beforeHour: Int? = nil) -> Totals? {
        let worn = days.map { totals($0, beforeHour: beforeHour) }
            .filter { $0.scoredMinutes >= minTypicalHours * minutesPerHour }
        guard worn.count >= minTypicalDays else { return nil }
        let n = Double(worn.count)
        func mean(_ f: (Totals) -> Int) -> Int { Int((Double(worn.map(f).reduce(0, +)) / n).rounded()) }
        return Totals(lowMinutes: mean(\.lowMinutes), mediumMinutes: mean(\.mediumMinutes),
                      highMinutes: mean(\.highMinutes))
    }

    /// `value` against `typical` as a whole percent (+489, −11), or nil when there is no typical time to
    /// compare with.
    public static func percentChange(_ value: Int, typical: Int) -> Int? {
        guard typical > 0 else { return nil }
        return Int((Double(value - typical) / Double(typical) * 100).rounded())
    }

    /// The longest run of back-to-back HIGH hours: when it started (unix seconds) and how long it lasted.
    /// The earliest run wins a tie. nil without a single HIGH hour.
    public static func longestHighRun(_ hours: [DaytimeStress.HourPoint]) -> (startTs: Int, minutes: Int)? {
        let sorted = hours.sorted { $0.startTs < $1.startTs }
        var best: (startTs: Int, minutes: Int)?
        var runStart: Int?
        var runHours = 0
        var lastTs: Int?
        func close() {
            if let s = runStart, runHours > 0, runHours * minutesPerHour > (best?.minutes ?? 0) {
                best = (s, runHours * minutesPerHour)
            }
        }
        for h in sorted {
            let isHigh = h.level.map { Level(score: $0) == .high } ?? false
            let adjacent = lastTs.map { h.startTs - $0 == DaytimeStress.bucketSeconds } ?? false
            if isHigh {
                if runStart != nil && adjacent {
                    runHours += 1
                } else {
                    close()
                    runStart = h.startTs
                    runHours = 1
                }
            } else {
                close()
                runStart = nil
                runHours = 0
            }
            lastTs = h.startTs
        }
        close()
        return best
    }

    /// The same weekday as `dayKey` in each of the `weeks` previous weeks, newest first ("yyyy-MM-dd",
    /// whole calendar days at UTC).
    public static func sameWeekdayKeys(before dayKey: String, weeks: Int) -> [String] {
        guard weeks > 0 else { return [] }
        return (1...weeks).compactMap { PulseDisplay.dayKey(dayKey, offsetBy: -7 * $0) }
    }
}
