import Foundation
import WhoopProtocol

/// Steps hour by hour: the phone's count where the phone was carried, the strap's walking estimate where it
/// clearly was not.
///
/// WHY HOURS. `StepsResolver` picks one source for a whole day, so a day the phone counted anything at all
/// shows only the phone's number, and every step walked with the phone left behind is lost. The phone and
/// Apple Health already bank clock-hour buckets (`appleStepHour`), and the strap's stored motion splits the
/// same way, so the choice can be made per hour instead.
///
/// THE RULE. An hour takes the strap's estimate only when it beats the phone's count by at least
/// `minExtraSteps` AND by at least `minExtraFraction` of the phone's count; otherwise the phone's count stands.
/// "The phone's count" is the larger of Apple Health's hour and the iPhone pedometer's hour: Health already
/// contains the phone's own steps, so the two are never added. Only hours the phone side has finished banking
/// are eligible (`settledHours`), so the strap never tops up an hour the phone is still counting.
///
/// WALKING MINUTES, NOT MOTION VOLUME. A WHOOP 4.0 banks one heavily smoothed gravity vector a second. Summed
/// over an hour, its changes measure arm movement of every kind, and on a real wearer's data an hour of typing
/// and phone use summed to as much as an hour that walked 1,700 steps, so a motion-volume estimate added
/// thousands of steps a day that were never walked. Walking looks different minute by minute: the vector moves
/// clearly almost every second for minutes on end, with the heart rate up. `walkingByHour` counts those minutes
/// (`isWalkingMinute`, in runs of at least `minBoutMinutes`), and the estimate is walking minutes times the
/// wearer's own steps per walking minute.
///
/// THE CALIBRATION. Steps per walking minute is learned from CARRIED hours only (`isCarried`): the phone
/// counted at least `carriedMinSteps`, the strap recorded the hour as usual and saw some walking, and the
/// wearer was neither asleep nor in a no-footfall workout. On that first real wearer it came out at about 100,
/// an ordinary walking cadence, and the estimate put a hidden carried hour back to within a median 2-3% of the
/// day's total (`Tools/zeno/steps-replay`).
///
/// Pure value code, unit-tested. The Android twin keeps the daily resolver: this fork does not keep Android
/// parity for ZENO-only changes.
public enum StepsHourMerge {

    // MARK: - Tunables: the merge

    /// The strap takes an hour over only when its estimate is at least this many steps above the phone's count...
    public static let minExtraSteps = 150
    /// ...and at least this fraction of the phone's count above it.
    public static let minExtraFraction = 0.5
    /// No hour's strap estimate goes above this: 150 steps a minute for the whole hour.
    public static let maxHourSteps = 9_000

    // MARK: - Tunables: the walking detector

    /// Consecutive gravity rows further apart than this are not compared (a gap is not a movement).
    public static let maxRowGap = 5
    /// A minute needs at least this many second-to-second changes to be judged.
    public static let minuteMinChanges = 40
    /// A second-to-second change of the gravity vector above this (in g) is movement.
    public static let movingChange = 0.02
    /// A walking minute moves in at least this share of its seconds...
    public static let walkingMovingShare = 0.95
    /// ...with a median change of at least this...
    public static let walkingMedianChange = 0.03
    /// ...and, when the strap has heart rate for it, a mean at least this far above the day's resting level.
    public static let walkingHeartRateAboveRest = 15.0
    /// The day's resting level: this percentile of its heart-rate samples.
    public static let restingPercentile = 0.10
    /// Only runs of at least this many consecutive walking minutes count: a single busy minute of arm movement
    /// can look like walking, a sustained run rarely does.
    public static let minBoutMinutes = 2

    // MARK: - Tunables: the calibration

    /// A carried hour: the phone counted at least this many steps in it...
    public static let carriedMinSteps = 300
    /// ...and the strap saw at least this many walking minutes.
    public static let carriedMinWalkingMinutes = 3
    /// Fewest carried hours before the hourly fit is trusted (a few days of normal use).
    public static let minCalibrationHours = 24
    /// Carried hours at which the sample-size half of the confidence saturates.
    public static let goodCalibrationHours = 120
    /// A carried hour may be at most this much asleep or in a no-footfall workout.
    public static let maxBlockedFractionForFit = 0.25
    /// Floor on the rows a carried hour needs, whatever the strap's usual density.
    public static let minRowsFloor = 30
    /// A fitted pace outside this range (steps per walking minute) means the detector is not seeing walking on
    /// this strap, so nothing is filled.
    public static let plausibleStepsPerMinute: ClosedRange<Double> = 50...200

    // MARK: - The strap's walking per clock hour

    /// The strap's walking in one clock hour: the minutes the detector accepted, and the gravity rows it banked.
    public struct HourWalk: Equatable, Sendable {
        public var walkingMinutes: Int
        public var rows: Int
        public init(walkingMinutes: Int, rows: Int) {
            self.walkingMinutes = walkingMinutes
            self.rows = rows
        }
    }

    /// Start of the clock hour `ts` falls in, for a zone `offsetSec` seconds east of UTC.
    public static func hourStart(_ ts: Int, offsetSec: Int) -> Int {
        ts - floorMod(ts + offsetSec, 3_600)
    }

    /// Start of the clock minute `ts` falls in.
    public static func minuteStart(_ ts: Int, offsetSec: Int) -> Int {
        ts - floorMod(ts + offsetSec, 60)
    }

    /// Whether one minute walked: `changes` are its second-to-second changes of the gravity vector, `heartRate`
    /// its mean heart rate (nil when the strap has none for it), `restingRate` the day's resting level (nil when
    /// the day has no heart rate at all).
    public static func isWalkingMinute(changes: [Double], heartRate: Double?, restingRate: Double?) -> Bool {
        guard changes.count >= minuteMinChanges else { return false }
        let moving = changes.filter { $0 > movingChange }.count
        guard Double(moving) >= walkingMovingShare * Double(changes.count) else { return false }
        let sorted = changes.sorted()
        guard sorted[sorted.count / 2] >= walkingMedianChange else { return false }
        if let heartRate, let restingRate, heartRate < restingRate + walkingHeartRateAboveRest { return false }
        return true
    }

    /// One day's strap streams split by clock hour (keyed by hour start): every hour the strap banked rows in,
    /// with the minutes it walked. Gravity must be in time order, as the store returns it; heart rate may be in
    /// any order.
    public static func walkingByHour(_ grav: [GravitySample], heartRate: [HRSample], offsetSec: Int) -> [Int: HourWalk] {
        var rows: [Int: Int] = [:]
        var changes: [Int: [Double]] = [:]
        var prev: GravitySample?
        for r in grav {
            rows[hourStart(r.ts, offsetSec: offsetSec), default: 0] += 1
            if let p = prev, r.ts - p.ts <= maxRowGap {
                let dx = p.x - r.x, dy = p.y - r.y, dz = p.z - r.z
                changes[minuteStart(r.ts, offsetSec: offsetSec), default: []].append((dx * dx + dy * dy + dz * dz).squareRoot())
            }
            prev = r
        }
        var hrSum: [Int: (total: Int, count: Int)] = [:]
        for s in heartRate where s.bpm > 0 {
            let m = minuteStart(s.ts, offsetSec: offsetSec)
            let cur = hrSum[m] ?? (0, 0)
            hrSum[m] = (cur.total + s.bpm, cur.count + 1)
        }
        let resting = restingRate(heartRate.map(\.bpm).filter { $0 > 0 })
        var walking: [Int] = []
        for (minute, deltas) in changes {
            let hr = hrSum[minute].map { Double($0.total) / Double($0.count) }
            if isWalkingMinute(changes: deltas, heartRate: hr, restingRate: resting) { walking.append(minute) }
        }
        var out: [Int: HourWalk] = [:]
        for (hour, n) in rows { out[hour] = HourWalk(walkingMinutes: 0, rows: n) }
        for minute in boutMinutes(walking.sorted()) {
            out[hourStart(minute, offsetSec: offsetSec), default: HourWalk(walkingMinutes: 0, rows: 0)].walkingMinutes += 1
        }
        return out
    }

    /// The minutes (sorted minute starts) that sit in a run of at least `minBoutMinutes` consecutive minutes.
    public static func boutMinutes(_ minutes: [Int]) -> [Int] {
        var out: [Int] = []
        var run: [Int] = []
        func flush() {
            if run.count >= minBoutMinutes { out += run }
            run.removeAll()
        }
        for m in minutes {
            if let last = run.last, m - last != 60 { flush() }
            run.append(m)
        }
        flush()
        return out
    }

    /// The day's resting level: the `restingPercentile` of its heart-rate samples, nil without any.
    public static func restingRate(_ bpm: [Int]) -> Double? {
        guard !bpm.isEmpty else { return nil }
        let sorted = bpm.sorted()
        return Double(sorted[Int(Double(sorted.count) * restingPercentile)])
    }

    /// The row count a strap banks in a typical recorded hour: the median over hours with any rows. A WHOOP 4.0
    /// that stores motion every second banks about 3,600; one that stores bursts banks far fewer, so the carried
    /// test scales with this rather than assuming either. 0 when nothing was recorded.
    public static func usualRows(_ hours: [HourWalk]) -> Int {
        let rows = hours.map(\.rows).filter { $0 > 0 }.sorted()
        guard !rows.isEmpty else { return 0 }
        return rows[rows.count / 2]
    }

    /// The fewest rows a carried hour needs: half the strap's usual hour, never below `minRowsFloor`.
    public static func minCarriedRows(usualRows: Int) -> Int {
        max(minRowsFloor, usualRows / 2)
    }

    // MARK: - Calibration

    /// One carried hour: the strap's walking minutes and the phone's count for the same clock hour.
    public struct CalibrationHour: Equatable, Sendable {
        public let walkingMinutes: Int
        public let steps: Double
        public init(walkingMinutes: Int, steps: Double) {
            self.walkingMinutes = walkingMinutes
            self.steps = steps
        }
    }

    /// The hourly model.
    public struct Calibration: Equatable, Sendable {
        /// The wearer's steps per walking minute.
        public let stepsPerMinute: Double
        /// Carried hours the fit rests on.
        public let sampleHours: Int
        /// 0-1, from sample size and spread.
        public let confidence: Double
        public init(stepsPerMinute: Double, sampleHours: Int, confidence: Double) {
            self.stepsPerMinute = stepsPerMinute
            self.sampleHours = sampleHours
            self.confidence = confidence
        }
    }

    /// Whether an hour counts as carried: the phone counted a real walk in it, the strap recorded it as usual and
    /// saw some walking, and the wearer was awake and not in a no-footfall workout for most of it.
    public static func isCarried(phoneSteps: Int, walk: HourWalk, minRows: Int, blockedFraction: Double) -> Bool {
        phoneSteps >= carriedMinSteps
            && walk.rows >= minRows
            && walk.walkingMinutes >= carriedMinWalkingMinutes
            && blockedFraction <= maxBlockedFractionForFit
    }

    /// Fit steps per walking minute from carried hours: the median of each hour's `steps / walkingMinutes`,
    /// weighted by its walking minutes. nil below `minCalibrationHours` or outside `plausibleStepsPerMinute`.
    public static func calibrate(_ hours: [CalibrationHour]) -> Calibration? {
        let usable = usableCalibrationHours(hours)
        guard usable.count >= minCalibrationHours, let pace = pace(usable) else { return nil }
        let ratios = usable.map { $0.steps / Double($0.walkingMinutes) }
        let weights = usable.map { Double($0.walkingMinutes) }
        let sizeTerm = min(1, Double(usable.count) / Double(goodCalibrationHours))
        let mad = StepsEstimateEngine.weightedMedian(ratios.map { abs($0 - pace) }, weights: weights)
        let tightness = max(0, 1 - mad / pace)
        let confidence = max(0, min(1, 0.5 * sizeTerm + 0.5 * tightness))
        return Calibration(stepsPerMinute: pace, sampleHours: usable.count, confidence: confidence)
    }

    /// The pace alone, for any number of hours: the walking-minute-weighted median of `steps / walkingMinutes`
    /// over the usable ones, nil when there are none or it falls outside `plausibleStepsPerMinute`. `calibrate`
    /// adds the minimum and the confidence; the replay tool's leave-one-day-out test uses this directly.
    public static func pace(_ hours: [CalibrationHour]) -> Double? {
        let usable = usableCalibrationHours(hours)
        guard !usable.isEmpty else { return nil }
        let pace = StepsEstimateEngine.weightedMedian(usable.map { $0.steps / Double($0.walkingMinutes) },
                                                      weights: usable.map { Double($0.walkingMinutes) })
        guard pace.isFinite, plausibleStepsPerMinute.contains(pace) else { return nil }
        return pace
    }

    private static func usableCalibrationHours(_ hours: [CalibrationHour]) -> [CalibrationHour] {
        hours.filter { $0.walkingMinutes >= carriedMinWalkingMinutes && $0.steps > 0 }
    }

    // MARK: - Estimate

    /// The strap's step estimate for one hour: its walking minutes at the wearer's pace. `openFraction` is the
    /// part of the hour the wearer was awake and not in a no-footfall workout; the rest contributes nothing.
    /// Clamped to `maxHourSteps`.
    public static func estimate(walkingMinutes: Int, stepsPerMinute: Double, openFraction: Double) -> Int {
        guard walkingMinutes > 0, stepsPerMinute > 0, openFraction > 0 else { return 0 }
        let raw = Double(walkingMinutes) * stepsPerMinute * min(1, openFraction)
        guard raw.isFinite else { return 0 }
        return max(0, min(maxHourSteps, Int(raw.rounded())))
    }

    // MARK: - The merge

    /// Steps the strap adds to one hour: its estimate minus the phone's count when it beats the phone clearly,
    /// otherwise 0.
    public static func added(phone: Int, band: Int) -> Int {
        let p = max(0, phone), b = max(0, band)
        let needed = max(Double(minExtraSteps), minExtraFraction * Double(p))
        return Double(b - p) >= needed ? b - p : 0
    }

    /// How many clock hours of a day, from its start, the phone side has finished counting: the hours that end
    /// at or before `settledUntil`.
    public static func settledHours(dayStart: Int, settledUntil: Int) -> Int {
        guard settledUntil > dayStart else { return 0 }
        return min(StepsHourly.hoursPerDay, (settledUntil - dayStart) / 3_600)
    }

    /// What the strap adds to each clock hour of a day. The arrays are `StepsHourly.hoursPerDay` buckets (nil
    /// when a source banked nothing that day); hours from `settledHours` on get nothing.
    public static func addedByHour(phone: [Int]?, health: [Int]?, band: [Int]?, settledHours: Int) -> [Int] {
        let n = StepsHourly.hoursPerDay
        var out = Array(repeating: 0, count: n)
        guard let band else { return out }
        for h in 0..<max(0, min(settledHours, n)) {
            let b = h < band.count ? band[h] : 0
            guard b > 0 else { continue }
            let p = max(value(phone, h), value(health, h))
            out[h] = added(phone: p, band: b)
        }
        return out
    }

    /// The strap's additions for every day it has hours for, keyed by "yyyy-MM-dd", as 24 per-hour values. Rows
    /// are hour buckets from `appleStepHour` (any order); days are local calendar days of `calendar`, the
    /// boundary `StepsHourly` and the phone use. Days the strap adds nothing to are left out.
    public static func fillByDay(phoneRows: [(ts: Int, steps: Int)], healthRows: [(ts: Int, steps: Int)],
                                 bandRows: [(ts: Int, steps: Int)], calendar: Calendar,
                                 settledUntil: Int) -> [String: [Int]] {
        let band = bucketsByDay(bandRows, calendar: calendar)
        guard !band.isEmpty else { return [:] }
        let phone = bucketsByDay(phoneRows, calendar: calendar)
        let health = bucketsByDay(healthRows, calendar: calendar)
        var out: [String: [Int]] = [:]
        for (day, bandHours) in band {
            guard let start = StepsHourly.dayBounds(day: day, calendar: calendar)?.start else { continue }
            let added = addedByHour(phone: phone[day], health: health[day], band: bandHours,
                                    settledHours: settledHours(dayStart: start, settledUntil: settledUntil))
            if added.contains(where: { $0 > 0 }) { out[day] = added }
        }
        return out
    }

    /// Hour rows summed into clock-hour buckets per local day, the same rules as `StepsHourly.buckets`
    /// (non-positive counts dropped, a repeated fall-back hour summed) in one pass over the rows.
    public static func bucketsByDay(_ rows: [(ts: Int, steps: Int)], calendar: Calendar) -> [String: [Int]] {
        var out: [String: [Int]] = [:]
        for row in rows where row.steps > 0 {
            let c = calendar.dateComponents([.year, .month, .day, .hour],
                                            from: Date(timeIntervalSince1970: TimeInterval(row.ts)))
            guard let y = c.year, let m = c.month, let d = c.day, let h = c.hour,
                  (0..<StepsHourly.hoursPerDay).contains(h) else { continue }
            let day = dayKey(year: y, month: m, day: d)
            var hours = out[day] ?? Array(repeating: 0, count: StepsHourly.hoursPerDay)
            hours[h] += row.steps
            out[day] = hours
        }
        return out
    }

    // MARK: - Blocked time (sleep and no-footfall workouts)

    /// The part of the hour starting at `hourStart` that `intervals` cover, 0-1. Intervals may overlap each
    /// other; covered time is counted once.
    public static func coveredFraction(hourStart: Int, intervals: [(start: Int, end: Int)]) -> Double {
        let hourEnd = hourStart + 3_600
        let clipped = intervals
            .map { (start: max($0.start, hourStart), end: min($0.end, hourEnd)) }
            .filter { $0.end > $0.start }
            .sorted { $0.start < $1.start }
        var covered = 0
        var reach = hourStart
        for iv in clipped {
            let from = max(iv.start, reach)
            if iv.end > from {
                covered += iv.end - from
                reach = iv.end
            }
        }
        return Double(covered) / 3_600
    }

    /// Sports whose arm or body motion is not footfalls: cycling, strength work, rowing and paddling, and
    /// swimming. During them the strap's estimate adds nothing. Matched on words in the stored sport name,
    /// case-insensitively, so catalogue names, WHOOP names ("TraditionalStrengthTraining") and free text all work.
    public static func isNoFootfallSport(_ sport: String) -> Bool {
        let s = sport.lowercased()
        return noFootfallWords.contains { s.contains($0) }
    }

    private static let noFootfallWords = [
        "cycl", "bike", "biking", "spin",
        "strength", "weight", "lifting", "powerlift",
        "rowing", "rower", "kayak", "canoe", "paddl",
        "swim",
    ]

    // MARK: - Helpers

    static func dayKey(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func value(_ hours: [Int]?, _ h: Int) -> Int {
        guard let hours, h < hours.count else { return 0 }
        return max(0, hours[h])
    }

    private static func floorMod(_ a: Int, _ b: Int) -> Int {
        let r = a % b
        return (r != 0 && (r < 0) != (b < 0)) ? r + b : r
    }
}
