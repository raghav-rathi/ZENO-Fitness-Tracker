import Foundation

/// The hour-by-hour shape of one LOCAL calendar day of steps.
///
/// Hourly rows are real instants (the unix second an hour bucket starts), unlike the "yyyy-MM-dd" day keys
/// the rest of the steps code works in, so everything here takes the calendar whose time zone defines the
/// day. The app passes `Calendar.current`: an hour chart reads in the wearer's own clock, and "today" starts
/// at the device's local midnight, the same boundary HealthKit's statistics query and CoreMotion's pedometer
/// are anchored to. Tests pass a fixed zone so DST days are deterministic.
public enum StepsHourly {
    /// Buckets in a chart. A spring-forward day leaves one of them empty and a fall-back day sums its
    /// repeated hour into one, so the chart keeps 24 clock hours rather than 23 or 25 bars.
    public static let hoursPerDay = 24

    /// `[start, end)` of `day` (a "yyyy-MM-dd" key) as unix seconds, local midnight to local midnight in
    /// `calendar`'s zone. nil for a key that does not name a real date ("2026-02-31" included).
    public static func dayBounds(day: String, calendar: Calendar) -> (start: Int, end: Int)? {
        guard let (y, m, d) = StepsDayKeys.components(day),
              let start = calendar.date(from: DateComponents(year: y, month: m, day: d)),
              let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        return (Int(start.timeIntervalSince1970), Int(end.timeIntervalSince1970))
    }

    /// The start of every clock hour in `day`, oldest first: the windows a pedometer is queried over. Stepped
    /// from local midnight in whole hours, the same anchor and interval as HealthKit's hourly collection
    /// query, so a phone hour and a Health hour for the same clock hour share one start instant.
    public static func hourStarts(day: String, calendar: Calendar) -> [Int] {
        guard let bounds = dayBounds(day: day, calendar: calendar) else { return [] }
        return Array(stride(from: bounds.start, to: bounds.end, by: 3_600))
    }

    /// The local clock hour (0–23) an instant falls in.
    public static func hourOfDay(ts: Int, calendar: Calendar) -> Int {
        calendar.component(.hour, from: Date(timeIntervalSince1970: TimeInterval(ts)))
    }

    /// Sum hourly rows into `hoursPerDay` clock-hour buckets for `day`. Rows outside the day are ignored,
    /// negative counts are dropped, and an hour with no row stays 0 (no row means nothing was recorded, which
    /// the chart cannot tell apart from a still hour and does not try to).
    public static func buckets(rows: [(ts: Int, steps: Int)], day: String, calendar: Calendar) -> [Int] {
        var out = Array(repeating: 0, count: hoursPerDay)
        guard let bounds = dayBounds(day: day, calendar: calendar) else { return out }
        for row in rows where row.ts >= bounds.start && row.ts < bounds.end && row.steps > 0 {
            let hour = hourOfDay(ts: row.ts, calendar: calendar)
            guard out.indices.contains(hour) else { continue }
            out[hour] += row.steps
        }
        return out
    }

    /// Bring the current hour in line with a fresher day total.
    ///
    /// The pedometer's live running total moves every few seconds, while its hour buckets are re-read only
    /// every few minutes. Without this the bars would lag the headline for most of an hour. The current hour
    /// takes whatever the finished hours do not already account for, and never shrinks below its own stored
    /// value (a stale live total must not erase a fresher bucket). Hours after `currentHour` are left alone:
    /// they are in the future and hold nothing.
    public static func reconcilingCurrentHour(_ buckets: [Int], dayTotal: Int, currentHour: Int) -> [Int] {
        guard buckets.indices.contains(currentHour) else { return buckets }
        var out = buckets
        let others = out.indices.filter { $0 != currentHour }.reduce(0) { $0 + max(0, out[$1]) }
        out[currentHour] = max(out[currentHour], dayTotal - others, 0)
        return out
    }

    /// What an hour-by-hour chart of one day draws.
    public struct Chart: Equatable, Sendable {
        /// `hoursPerDay` bars.
        public let bars: [Int]
        /// Whose hours these are.
        public let source: StepSource
        /// True when the bars are the day's own source, so they add up to the headline. False means the
        /// shape is borrowed from another source and the chart must say so.
        public let matchesDaySource: Bool
        /// The clock hour to highlight: the current one, on the in-progress day only.
        public let currentHour: Int?
        /// What the band added to each hour the phone missed (`StepsHourMerge`), drawn stacked on `bars`.
        /// All zeros on a day the phone covered.
        public let filled: [Int]

        public init(bars: [Int], source: StepSource, matchesDaySource: Bool, currentHour: Int?,
                    filled: [Int] = []) {
            self.bars = bars
            self.source = source
            self.matchesDaySource = matchesDaySource
            self.currentHour = currentHour
            self.filled = filled.count == bars.count ? filled : Array(repeating: 0, count: bars.count)
        }

        /// Each hour's full height: its bar plus what the band added.
        public var totals: [Int] { zip(bars, filled).map { $0 + $1 } }

        /// True when the band added to any hour.
        public var hasFill: Bool { filled.contains { $0 > 0 } }

        /// The busiest hour counting the band's additions, nil when every hour is empty. On a tie the earlier hour.
        public var peakHour: Int? {
            let all = totals
            guard let top = all.max(), top > 0 else { return nil }
            return all.firstIndex(of: top)
        }
    }

    /// Compose the chart for a day from its resolved source and total, the hours each source banked, and
    /// (for the in-progress day) the current clock hour. The bars come from `StepsResolver.hourlySource`;
    /// when they are the day's own source on the in-progress day, the current hour absorbs whatever the
    /// headline counts that the banked hours do not yet, so the bars and the number agree while walking.
    /// `dayTotal` is the source's own count (`ResolvedStepDay.sourceSteps`); `filled` is what the band added
    /// per hour, stacked on top. nil when no source banked any hour for the day.
    public static func chart(daySource: StepSource?, dayTotal: Int?, hours: [StepSource: [Int]],
                             currentHour: Int?, filled: [Int]? = nil) -> Chart? {
        let withHours = Set(hours.filter { $0.value.count == hoursPerDay }.keys)
        guard let source = StepsResolver.hourlySource(daySource: daySource, sourcesWithHours: withHours),
              var bars = hours[source] else { return nil }
        let matches = source == daySource
        if matches, let currentHour, let dayTotal {
            bars = reconcilingCurrentHour(bars, dayTotal: dayTotal, currentHour: currentHour)
        }
        return Chart(bars: bars, source: source, matchesDaySource: matches, currentHour: currentHour,
                     filled: filled ?? [])
    }
}
