import Foundation

// CycleMetricPatterns.swift — how the user's OWN nightly metrics move across their logged cycles. Pure,
// deterministic, UTC day keys.
//
// Two reads, both against the user's personal numbers only (no population curves, no reference ranges):
//   - `compare`: a metric's mean on the days of one phase against its mean over every day with a phase,
//     judged higher / lower / typical by how far apart they sit in the metric's own spread;
//   - `cycleSeries`: the current cycle's smoothed deviation from the personal baseline by cycle day, and,
//     once enough previous cycles are logged, their average at each cycle day, plus that average smoothed
//     over a week of cycle days as the "expected" trend.
// A missing day is skipped, never drawn as zero.
public enum CycleMetricPatterns {

    /// Phase days a comparison needs.
    public static let minPhaseDays = 3
    /// Days with a phase overall a comparison needs.
    public static let minOverallDays = 14
    /// How many of the metric's own standard deviations the phase mean must sit away to count.
    public static let directionThresholdSD = 0.3
    /// Previous cycles that must contribute at a cycle day for the expected trend to show there.
    public static let minPreviousCycles = 2
    /// The most recent completed cycles the expected trend averages.
    public static let previousCyclesAveraged = 3
    /// Cycle days on each side of a day that the expected trend's centred mean takes in (3: a week).
    public static let trendHalfWindow = 3

    public enum Direction: String, Sendable, Equatable {
        case higher, lower, typical
    }

    /// A metric in one phase against the same metric across the cycle.
    public struct Comparison: Equatable, Sendable {
        public let phaseMean: Double
        public let overallMean: Double
        public let phaseDays: Int
        public let direction: Direction

        public init(phaseMean: Double, overallMean: Double, phaseDays: Int, direction: Direction) {
            self.phaseMean = phaseMean
            self.overallMean = overallMean
            self.phaseDays = phaseDays
            self.direction = direction
        }
    }

    /// The metric's mean on `phase` days against its mean over every day that has a phase; nil until
    /// there are `minPhaseDays` and `minOverallDays` days with a value.
    public static func compare(values: [String: Double],
                               phaseByDay: [String: MenstrualCycleModel.Phase],
                               phase: MenstrualCycleModel.Phase) -> Comparison? {
        var all: [Double] = []
        var inPhase: [Double] = []
        for (day, p) in phaseByDay {
            guard let v = values[day], v.isFinite else { continue }
            all.append(v)
            if p == phase { inPhase.append(v) }
        }
        guard all.count >= minOverallDays, inPhase.count >= minPhaseDays else { return nil }
        let overall = mean(all)
        let phaseMean = mean(inPhase)
        let sd = sampleSD(all, mean: overall)
        let z = sd > 0 ? (phaseMean - overall) / sd : 0
        let direction: Direction = z >= directionThresholdSD ? .higher
            : (z <= -directionThresholdSD ? .lower : .typical)
        return Comparison(phaseMean: phaseMean, overallMean: overall, phaseDays: inPhase.count,
                          direction: direction)
    }

    /// A value at a cycle day.
    public struct Point: Equatable, Sendable {
        public let cycleDay: Int
        public let value: Double

        public init(cycleDay: Int, value: Double) {
            self.cycleDay = cycleDay
            self.value = value
        }
    }

    /// The current cycle's curve and the expected one.
    public struct CycleSeries: Equatable, Sendable {
        /// The current cycle so far: the smoothed deviation from the baseline at each cycle day with a value.
        public let current: [Point]
        /// The previous cycles' average deviation at each cycle day where `minPreviousCycles` contribute.
        public let expected: [Point]
        /// `expected` as a trend: its centred mean over `trendHalfWindow` cycle days each side, at the same
        /// cycle days. Three cycles averaged night by night still zig-zag; the trend is what the chart's
        /// "Expected Trend" area draws.
        public let expectedTrend: [Point]
        /// Completed cycles averaged into `expected`.
        public let previousCycles: Int
        /// What the deviations are measured from (0 for a series that is already a deviation).
        public let baseline: Double

        public init(current: [Point], expected: [Point], expectedTrend: [Point]? = nil, previousCycles: Int,
                    baseline: Double) {
            self.current = current
            self.expected = expected
            self.expectedTrend = expectedTrend ?? CycleMetricPatterns.centredMean(expected,
                                                                                  halfWindow: CycleMetricPatterns.trendHalfWindow)
            self.previousCycles = previousCycles
            self.baseline = baseline
        }
    }

    /// Each point replaced by the mean of the points within `halfWindow` cycle days of it (itself included),
    /// at the same cycle days. Near an end or a gap the window holds only the points that exist, so a gap is
    /// never filled and a missing day never counts as zero.
    public static func centredMean(_ points: [Point], halfWindow: Int) -> [Point] {
        guard halfWindow > 0 else { return points }
        let byDay = Dictionary(points.map { ($0.cycleDay, $0.value) }, uniquingKeysWith: { first, _ in first })
        return points.map { p in
            var sum = 0.0, n = 0.0
            for d in (p.cycleDay - halfWindow)...(p.cycleDay + halfWindow) {
                if let v = byDay[d], v.isFinite {
                    sum += v
                    n += 1
                }
            }
            return Point(cycleDay: p.cycleDay, value: n > 0 ? sum / n : p.value)
        }
    }

    /// The current cycle's smoothed deviation by cycle day, and the previous cycles' average.
    ///
    /// - Parameters:
    ///   - values: the metric by day key.
    ///   - cycleStarts: logged period starts; the latest on or before `today` starts the current cycle.
    ///   - today: today's day key.
    ///   - relativeToZero: the values are already deviations from a personal baseline (skin temperature).
    /// - Returns: nil without a current cycle.
    public static func cycleSeries(values: [String: Double], cycleStarts: [String], today: String,
                                   relativeToZero: Bool) -> CycleSeries? {
        let starts = Array(Set(cycleStarts.filter { $0 <= today })).sorted()
        guard let current = starts.last else { return nil }
        // The previous completed cycles worth averaging (plausible lengths only), most recent last.
        var previous: [(start: String, length: Int)] = []
        if starts.count >= 2 {
            for i in 0..<(starts.count - 1) {
                guard let len = MenstrualCycleModel.days(from: starts[i], to: starts[i + 1]),
                      MenstrualCycleModel.plausibleCycleLengths.contains(len) else { continue }
                previous.append((starts[i], len))
            }
        }
        previous = Array(previous.suffix(previousCyclesAveraged))

        let baseline: Double = {
            if relativeToZero { return 0 }
            let from = previous.first?.start ?? current
            let span = values.filter { $0.key >= from && $0.key <= today && $0.value.isFinite }.map(\.value)
            return span.isEmpty ? 0 : mean(span)
        }()

        func smoothed(_ day: String) -> Double? {
            guard let v = values[day], v.isFinite else { return nil }
            var sum = v, n = 1.0
            for delta in [-1, 1] {
                // Never reach past today: tomorrow is not data.
                if let d = MenstrualCycleModel.shift(day, by: delta), d <= today, let w = values[d], w.isFinite {
                    sum += w
                    n += 1
                }
            }
            return sum / n - baseline
        }

        var currentPoints: [Point] = []
        if let span = MenstrualCycleModel.days(from: current, to: today) {
            for offset in 0...max(0, span) {
                guard let day = MenstrualCycleModel.shift(current, by: offset), let v = smoothed(day) else { continue }
                currentPoints.append(Point(cycleDay: offset + 1, value: v))
            }
        }

        var byDay: [Int: [Double]] = [:]
        for cycle in previous {
            for offset in 0..<cycle.length {
                guard let day = MenstrualCycleModel.shift(cycle.start, by: offset), let v = smoothed(day) else { continue }
                byDay[offset + 1, default: []].append(v)
            }
        }
        let expected = byDay
            .filter { $0.value.count >= minPreviousCycles }
            .map { Point(cycleDay: $0.key, value: mean($0.value)) }
            .sorted { $0.cycleDay < $1.cycleDay }

        return CycleSeries(current: currentPoints, expected: expected, previousCycles: previous.count,
                           baseline: baseline)
    }

    // MARK: - Small stats

    static func mean(_ xs: [Double]) -> Double {
        xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count)
    }

    static func sampleSD(_ xs: [Double], mean m: Double) -> Double {
        guard xs.count >= 2 else { return 0 }
        let ss = xs.reduce(0.0) { $0 + ($1 - m) * ($1 - m) }
        return (ss / Double(xs.count - 1)).squareRoot()
    }
}
