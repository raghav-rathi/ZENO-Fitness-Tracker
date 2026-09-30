import Foundation
import WhoopProtocol

// PulseDisplay.swift - pure display rules for the Pulse iPhone interface (the WHOOP-style shell).
//
// Nothing here scores anything. Recovery, Effort and the sleep figures arrive already computed by the
// engine; these helpers only decide how a computed value is PRESENTED: which discrete colour band a
// recovery percentage falls in, which training intent that band implies, how a vital compares with its
// own recent history, what a day's Effort looked like as it accumulated, and when to be in bed for a
// given wake time. They live in the package so the rules are unit-tested without a view, a store or a
// clock, and so every Pulse screen resolves them through one function instead of re-deriving them.
//
// Display-only by design: none of these values is persisted, fed back into an engine, or sent across
// the .noopbak boundary, so there is no Kotlin twin to keep byte-identical.

public enum PulseDisplay {

    // MARK: - Recovery bands

    /// The three discrete recovery bands the Pulse dials colour by.
    public enum RecoveryBand: String, CaseIterable, Equatable, Sendable {
        case red, yellow, green
    }

    /// The band for a recovery percentage: 67 and above green, 34 to 66 yellow, 33 and below red.
    ///
    /// Judged on the WHOLE percent a dial prints, not the stored fraction, so the colour can never
    /// disagree with the number beside it: a stored 66.6 prints "67%" and must read green, which a
    /// comparison on the raw value would colour yellow.
    public static func recoveryBand(percent: Double) -> RecoveryBand {
        let shown = displayedPercent(percent)
        if shown >= 67 { return .green }
        if shown >= 34 { return .yellow }
        return .red
    }

    /// The whole percent a recovery or sleep dial prints for a stored value, clamped to 0...100.
    public static func displayedPercent(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return min(100, max(0, Int(value.rounded())))
    }

    // MARK: - Strain target intent

    /// What today's recovery suggests doing with strain.
    public enum StrainIntent: String, CaseIterable, Equatable, Sendable {
        /// A red day: keep strain low so recovery can rebuild.
        case restore
        /// A yellow day: train, but hold back from a maximal effort.
        case maintain
        /// A green day: the body can absorb a hard session.
        case push
    }

    /// The intent for a recovery percentage. Same cut-offs as `recoveryBand`, so the word under the
    /// strain target always matches the dial colour above it.
    public static func strainIntent(recoveryPercent: Double) -> StrainIntent {
        switch recoveryBand(percent: recoveryPercent) {
        case .red: return .restore
        case .yellow: return .maintain
        case .green: return .push
        }
    }

    // MARK: - Comparison with recent history

    /// Which way a value sits relative to its recent average.
    public enum Direction: String, Equatable, Sendable { case up, down, flat }

    /// A value compared with a reference: the mean of the days before it, or a learned baseline.
    public struct Comparison: Equatable, Sendable {
        /// What the value was compared with: the window's mean (`compare(value:history:…)`) or the
        /// baseline as printed (`compare(value:baseline:…)`).
        public let reference: Double
        /// `value - reference`, in the metric's own unit.
        public let delta: Double
        /// `delta` as a percentage of `|reference|`, or nil when the reference is too close to zero
        /// for a percentage to mean anything (a skin-temperature deviation centred on 0, for one).
        public let percent: Double?
        /// How many days backed the reference (0 for a learned baseline, which carries no window).
        public let samples: Int
        public let direction: Direction

        public init(reference: Double, delta: Double, percent: Double?, samples: Int, direction: Direction) {
            self.reference = reference
            self.delta = delta
            self.percent = percent
            self.samples = samples
            self.direction = direction
        }
    }

    /// Compare `value` with a LEARNED baseline (the recovery engine's), the way the engine reads it.
    ///
    /// Both numbers are first rounded to `fractionDigits` with the engine's own rounding
    /// (`RecoveryScorer.displayRounded`, half away from zero), and the direction and percentage come
    /// from those printed figures: equal figures read `.flat`, otherwise the sign decides. That is the
    /// rule `RecoveryScorer.baselineVerdict` uses for "above / below baseline", so an arrow drawn from
    /// this can never point against the engine's verdict for the same row, nor against the two numbers
    /// printed beside it. `reference` is the ROUNDED baseline, ready to print.
    public static func compare(value: Double, baseline: Double, fractionDigits: Int,
                               percentFloor: Double = 0.5) -> Comparison? {
        guard value.isFinite, baseline.isFinite, fractionDigits >= 0 else { return nil }
        let shown = RecoveryScorer.displayRounded(value, fractionDigits: fractionDigits)
        let reference = RecoveryScorer.displayRounded(baseline, fractionDigits: fractionDigits)
        let delta = shown - reference
        let percent: Double? = abs(reference) >= percentFloor ? delta / abs(reference) * 100.0 : nil
        let direction: Direction = shown == reference ? .flat : (delta > 0 ? .up : .down)
        return Comparison(reference: reference, delta: delta, percent: percent, samples: 0, direction: direction)
    }

    /// Compare `value` with the mean of `history` over the `windowDays` calendar days BEFORE `dayKey`.
    ///
    /// The compared day itself is excluded, or a single outlier would pull its own reference toward
    /// itself. Returns nil with no value, or with fewer than `minSamples` days in the window: an average
    /// of two nights is not a baseline and an arrow drawn from it would overstate what is known.
    ///
    /// `flatPercent` is the band inside which the direction reads `.flat` when a percentage exists;
    /// `flatAbsolute` is used instead when it does not (an average within `percentFloor` of zero).
    public static func compare(value: Double?,
                               history: [(day: String, value: Double)],
                               dayKey: String,
                               windowDays: Int = 30,
                               minSamples: Int = 5,
                               flatPercent: Double = 2.0,
                               flatAbsolute: Double = 0.05,
                               percentFloor: Double = 0.5) -> Comparison? {
        guard let value, value.isFinite, windowDays > 0,
              let cutoff = Self.dayKey(dayKey, offsetBy: -windowDays) else { return nil }
        // The window is [cutoff, dayKey): yyyy-MM-dd compares chronologically as a string.
        var sum = 0.0
        var n = 0
        for point in history where point.day >= cutoff && point.day < dayKey && point.value.isFinite {
            sum += point.value
            n += 1
        }
        guard n >= max(1, minSamples) else { return nil }
        let average = sum / Double(n)
        let delta = value - average
        let percent: Double? = abs(average) >= percentFloor ? delta / abs(average) * 100.0 : nil
        let direction: Direction
        if let percent {
            direction = abs(percent) < flatPercent ? .flat : (delta > 0 ? .up : .down)
        } else {
            direction = abs(delta) < flatAbsolute ? .flat : (delta > 0 ? .up : .down)
        }
        return Comparison(reference: average, delta: delta, percent: percent, samples: n, direction: direction)
    }

    /// The trailing `count` calendar days ending ON `dayKey` (inclusive), oldest first, as day keys.
    public static func trailingDayKeys(endingOn dayKey: String, count: Int) -> [String] {
        guard count > 0 else { return [] }
        return (0..<count).reversed().compactMap { Self.dayKey(dayKey, offsetBy: -$0) }
    }

    /// `dayKey` shifted by `days` whole calendar days, or nil for a malformed key.
    ///
    /// Parsed and formatted at UTC midnight on a Gregorian calendar, so the arithmetic is the same in
    /// every time zone and across a daylight-saving change. A day key names a calendar day, not an
    /// instant; doing this in the device zone is how a label ends up one day early west of UTC.
    public static func dayKey(_ dayKey: String, offsetBy days: Int) -> String? {
        guard let date = dayKeyFormatter.date(from: dayKey),
              let shifted = utcCalendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return dayKeyFormatter.string(from: shifted)
    }

    private static let utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Cumulative strain

    /// One checkpoint of a day's accumulating Effort (0-100, NOOP's stored axis).
    public struct StrainPoint: Equatable, Sendable {
        public let ts: Int
        public let effort: Double
        public init(ts: Int, effort: Double) {
            self.ts = ts
            self.effort = effort
        }
    }

    /// The day's Effort as it accumulated: `StrainScorer.strain` over every prefix of `hr` ending at a
    /// checkpoint, one checkpoint every `stepSeconds` from `from`, plus a final one at `to`.
    ///
    /// Scored through the SAME public scorer as the headline, so the last point is the number the dial
    /// shows (before the stored row's floor). A checkpoint whose prefix is still too thin to score is
    /// omitted rather than drawn as zero. The series is floored at its running maximum: Effort accrues
    /// and must never visibly drop (`StrainScorer.effectiveEffort`), and a prefix can read a hair lower
    /// than the one before it only through the scorer's last-sample duration rule.
    ///
    /// `hr` must be time-ordered. The prefixes bypass the scorer's shared memo (a diagnostic sink is the
    /// scorer's documented bypass): dozens of one-off prefixes would otherwise evict the whole-day entries
    /// the other surfaces rely on.
    public static func cumulativeStrain(hr: [HRSample],
                                        from: Int,
                                        to: Int,
                                        stepSeconds: Int,
                                        maxHR: Double?,
                                        restingHR: Double,
                                        method: StrainScorer.Method,
                                        sex: String) -> [StrainPoint] {
        guard to > from, stepSeconds > 0, !hr.isEmpty else { return [] }
        var checkpoints: [Int] = Array(stride(from: from + stepSeconds, to: to, by: stepSeconds))
        checkpoints.append(to)
        var out: [StrainPoint] = []
        out.reserveCapacity(checkpoints.count)
        var runningMax = 0.0
        var lastEnd = -1
        var lastEffort: Double?
        for t in checkpoints {
            let end = prefixEnd(hr, through: t)
            guard end > 0 else { continue }
            // An unchanged prefix (a gap in wear) scores the same: reuse it rather than re-integrate.
            if end != lastEnd {
                lastEnd = end
                lastEffort = StrainScorer.strain(Array(hr[0..<end]), maxHR: maxHR, restingHR: restingHR,
                                                 method: method, sex: sex, diag: { _ in })
            }
            guard let effort = lastEffort else { continue }
            runningMax = max(runningMax, effort)
            out.append(StrainPoint(ts: t, effort: runningMax))
        }
        return out
    }

    /// Index one past the last sample at or before `ts` (binary search over a time-ordered series).
    static func prefixEnd(_ hr: [HRSample], through ts: Int) -> Int {
        var lo = 0
        var hi = hr.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if hr[mid].ts <= ts { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

    // MARK: - Bedtime

    /// Minutes in a day.
    public static let minutesPerDay = 24 * 60

    /// The median of clock times given as minutes since local midnight, or nil for none.
    ///
    /// Wake times are compared on a clock that starts at noon, so a wearer who sometimes wakes just
    /// before midnight and sometimes just after is not averaged into mid-afternoon.
    public static func medianClockMinute(_ minutes: [Int]) -> Int? {
        guard !minutes.isEmpty else { return nil }
        let shifted = minutes.map { (($0 - 720) % minutesPerDay + minutesPerDay) % minutesPerDay }.sorted()
        let mid = shifted.count / 2
        let median = shifted.count % 2 == 1
            ? shifted[mid]
            : (shifted[mid - 1] + shifted[mid]) / 2
        return ((median + 720) % minutesPerDay + minutesPerDay) % minutesPerDay
    }

    /// The minute of day to be asleep by to wake at `wakeMinute` having slept `needMinutes`, wrapped
    /// into 0..<1440 (a 06:30 wake with an 8 h need is 22:30 the evening before).
    public static func bedtimeMinute(wakeMinute: Int, needMinutes: Double) -> Int {
        let raw = wakeMinute - Int(needMinutes.rounded())
        return ((raw % minutesPerDay) + minutesPerDay) % minutesPerDay
    }
}
