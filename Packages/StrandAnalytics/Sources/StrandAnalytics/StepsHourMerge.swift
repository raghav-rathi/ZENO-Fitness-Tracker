import Foundation
import WhoopProtocol

/// Steps hour by hour: the phone's count where the phone was carried, the band's motion estimate where it
/// clearly was not.
///
/// WHY HOURS. `StepsResolver` picks one source for a whole day, so a day the phone counted anything at all
/// shows only the phone's number, and every step walked with the phone left behind is lost. The phone and
/// Apple Health already bank clock-hour buckets (`appleStepHour`), and the band's stored motion splits the same
/// way, so the choice can be made per hour instead.
///
/// THE RULE. An hour takes the band's estimate only when it beats the phone's count by at least
/// `minExtraSteps` AND by at least `minExtraFraction` of the phone's count; otherwise the phone's count stands.
/// "The phone's count" is the larger of Apple Health's hour and the iPhone pedometer's hour: Health already
/// contains the phone's own steps, so the two are never added. Only hours the phone side has finished banking
/// are eligible (`settledHours`), so the band never tops up an hour the phone is still counting.
///
/// THE CALIBRATION. The band's estimate for an hour is `k * motion`, the model `StepsEstimateEngine` fits per
/// day, but `k` is learned from CARRIED hours only (`isCarried`): the phone counted at least `carriedMinSteps`,
/// the band banked its usual amount of motion, and the wearer was neither asleep nor in a no-footfall workout.
/// A whole day mixes in the hours the phone sat at home, which pulls a day-level `k` low; a carried hour has no
/// such gap. `hourlyMotion` is the daily fold split by clock hour, so a day's hours sum to
/// `StepsEstimateEngine.dayMotionIntensity` and a manual `k` means the same thing in both models.
///
/// Pure value code, unit-tested. The Android twin keeps the daily resolver: this fork does not keep Android
/// parity for ZENO-only changes.
public enum StepsHourMerge {

    // MARK: - Tunables

    /// The band takes an hour over only when its estimate is at least this many steps above the phone's count...
    public static let minExtraSteps = 150
    /// ...and at least this fraction of the phone's count above it.
    public static let minExtraFraction = 0.5
    /// No hour's band estimate goes above this: 150 steps a minute for the whole hour.
    public static let maxHourSteps = 9_000
    /// A carried hour: the phone counted at least this many steps in it.
    public static let carriedMinSteps = 300
    /// Fewest carried hours before the hourly fit is trusted (about three days of normal use).
    public static let minCalibrationHours = 24
    /// Carried hours at which the sample-size half of the confidence saturates.
    public static let goodCalibrationHours = 120
    /// An hour must move at least this much to enter the fit: guards the `steps / motion` ratio of a band that
    /// barely recorded the hour.
    public static let minMotionForFit = 0.01
    /// A carried hour may be at most this much asleep or in a no-footfall workout.
    public static let maxBlockedFractionForFit = 0.25
    /// Floor on the row count a carried hour needs, whatever the band's usual density.
    public static let minRowsFloor = 30

    // MARK: - Band motion per clock hour

    /// The band's motion in one clock hour: the summed gravity change, and how many rows it banked.
    public struct HourMotion: Equatable, Sendable {
        public var motion: Double
        public var rows: Int
        public init(motion: Double, rows: Int) {
            self.motion = motion
            self.rows = rows
        }
    }

    /// Start of the clock hour `ts` falls in, for a zone `offsetSec` seconds east of UTC.
    public static func hourStart(_ ts: Int, offsetSec: Int) -> Int {
        ts - floorMod(ts + offsetSec, 3_600)
    }

    /// One day's gravity stream split by clock hour, keyed by hour start. Each sample-to-sample change is
    /// credited to the hour of the later sample, so the hours sum to `StepsEstimateEngine.dayMotionIntensity`
    /// over the same samples. Samples must be in time order, as the store returns them.
    public static func hourlyMotion(_ grav: [GravitySample], offsetSec: Int) -> [Int: HourMotion] {
        var out: [Int: HourMotion] = [:]
        var prev: GravitySample?
        for r in grav {
            let hour = hourStart(r.ts, offsetSec: offsetSec)
            var cell = out[hour] ?? HourMotion(motion: 0, rows: 0)
            cell.rows += 1
            if let p = prev {
                let dx = p.x - r.x, dy = p.y - r.y, dz = p.z - r.z
                cell.motion += (dx * dx + dy * dy + dz * dz).squareRoot()
            }
            out[hour] = cell
            prev = r
        }
        return out
    }

    /// The row count a band banks in a typical recorded hour: the median over hours with any rows. A WHOOP 4.0
    /// that stores motion every second banks about 3,600; one that stores bursts banks far fewer, so the carried
    /// test scales with this rather than assuming either. 0 when nothing was recorded.
    public static func usualRows(_ hours: [HourMotion]) -> Int {
        let rows = hours.map(\.rows).filter { $0 > 0 }.sorted()
        guard !rows.isEmpty else { return 0 }
        return rows[rows.count / 2]
    }

    /// The fewest rows a carried hour needs: half the band's usual hour, never below `minRowsFloor`.
    public static func minCarriedRows(usualRows: Int) -> Int {
        max(minRowsFloor, usualRows / 2)
    }

    // MARK: - Calibration

    /// One carried hour: the band's motion and the phone's count for the same clock hour.
    public struct CalibrationHour: Equatable, Sendable {
        public let motion: Double
        public let steps: Double
        public init(motion: Double, steps: Double) {
            self.motion = motion
            self.steps = steps
        }
    }

    /// The hourly model.
    public struct Calibration: Equatable, Sendable {
        /// Steps per unit of motion, the same unit as `StepsEstimateEngine.Calibration.coefficient`.
        public let coefficient: Double
        /// Carried hours the fit rests on.
        public let sampleHours: Int
        /// 0-1, from sample size and spread. 1 for a manual coefficient.
        public let confidence: Double
        /// True when the wearer set the coefficient by hand.
        public let manual: Bool
        public init(coefficient: Double, sampleHours: Int, confidence: Double, manual: Bool) {
            self.coefficient = coefficient
            self.sampleHours = sampleHours
            self.confidence = confidence
            self.manual = manual
        }
    }

    /// Whether an hour counts as carried: the phone counted a real walk in it, the band recorded it as usual,
    /// it moved, and the wearer was awake and not in a no-footfall workout for most of it.
    public static func isCarried(phoneSteps: Int, motion: HourMotion, minRows: Int, blockedFraction: Double) -> Bool {
        phoneSteps >= carriedMinSteps
            && motion.rows >= minRows
            && motion.motion >= minMotionForFit
            && blockedFraction <= maxBlockedFractionForFit
    }

    /// Fit `k` from carried hours: the motion-weighted median of each hour's `steps / motion`, as
    /// `StepsEstimateEngine.calibrate` does per day. A manual coefficient wins. nil below `minCalibrationHours`.
    public static func calibrate(_ hours: [CalibrationHour], manualOverride: Double? = nil) -> Calibration? {
        let usable = hours.filter { $0.motion >= minMotionForFit && $0.steps > 0 }
        if let k = manualOverride, k > 0 {
            return Calibration(coefficient: k, sampleHours: usable.count, confidence: 1, manual: true)
        }
        guard usable.count >= minCalibrationHours else { return nil }
        let ratios = usable.map { $0.steps / $0.motion }
        let weights = usable.map(\.motion)
        let k = StepsEstimateEngine.weightedMedian(ratios, weights: weights)
        guard k > 0, k.isFinite else { return nil }
        let sizeTerm = min(1, Double(usable.count) / Double(goodCalibrationHours))
        let mad = StepsEstimateEngine.weightedMedian(ratios.map { abs($0 - k) }, weights: weights)
        let tightness = max(0, 1 - mad / k)
        let confidence = max(0, min(1, 0.5 * sizeTerm + 0.5 * tightness))
        return Calibration(coefficient: k, sampleHours: usable.count, confidence: confidence, manual: false)
    }

    // MARK: - Estimate

    /// The band's step estimate for one hour. `openFraction` is the part of the hour the wearer was awake and
    /// not in a no-footfall workout; the rest contributes nothing. Clamped to `maxHourSteps`.
    public static func estimate(motion: Double, coefficient: Double, openFraction: Double) -> Int {
        guard coefficient > 0, motion > 0, openFraction > 0 else { return 0 }
        let raw = motion * coefficient * min(1, openFraction)
        guard raw.isFinite else { return 0 }
        return max(0, min(maxHourSteps, Int(raw.rounded())))
    }

    // MARK: - The merge

    /// Steps the band adds to one hour: its estimate minus the phone's count when it beats the phone clearly,
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

    /// What the band adds to each clock hour of a day. The arrays are `StepsHourly.hoursPerDay` buckets (nil
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

    /// The band's additions for every day it has hours for, keyed by "yyyy-MM-dd", as 24 per-hour values. Rows
    /// are hour buckets from `appleStepHour` (any order); days are local calendar days of `calendar`, the
    /// boundary `StepsHourly` and the phone use. Days the band adds nothing to are left out.
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
    /// swimming. During them the band's estimate adds nothing. Matched on words in the stored sport name,
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
