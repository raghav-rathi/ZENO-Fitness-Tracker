import Foundation

// PulseTrendMath.swift - the Trend View's arithmetic (WHOOP_UI_SPEC §3.12), pure and DB-free.
//
// One metric's daily series goes in; everything the Trend View states about a period comes out: which days a
// W / M / 6M / 1Y / ALL window covers and where its pager can go, the period's average (with a running
// total's still-counting day left out, WHOOP's "Average does not include today"), its change against the
// period before, the typical range a line is judged against, the 30-day segments the long ranges draw,
// complete weekly totals for minute metrics, the breakdown counts, and how a value relates to a reference
// ("above", "within", "consistent with").
//
// Day keys are "yyyy-MM-dd" calendar days and every step between them is whole-day arithmetic on the
// key itself (Julian day numbers, as `WeeklyDigestEngine` does), so a window never shifts with the
// device's time zone or a daylight-saving change.
//
// Display-only by design, like `PulseDisplay`: nothing here scores anything, and nothing it returns is
// persisted, fed back into an engine or sent across the .noopbak boundary, so there is no Kotlin twin to
// keep byte-identical.

public enum PulseTrendMath {

    // MARK: - Points

    /// One day's reading.
    public struct Point: Equatable, Sendable {
        public let day: String
        public let value: Double

        public init(day: String, value: Double) {
            self.day = day
            self.value = value
        }
    }

    // MARK: - Ranges

    /// The Trend View's ranges. W / M / 6M follow WHOOP; 1Y and ALL are ZENO's additions (§3.12 [Z]).
    public enum Range: String, CaseIterable, Equatable, Sendable {
        case week, month, sixMonths, year, all

        /// Calendar days one window covers, or nil for everything.
        ///
        /// 6M is 180 days: every WHOOP 6M pager spans 180 inclusive days ("MAR 31 - SEP 26",
        /// "APR 20 - OCT 16", "SEP 3, 23 - FEB 29, 24"); M spans 30 ("AUG 5 - SEP 3").
        public var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .sixMonths: return 180
            case .year: return 365
            case .all: return nil
            }
        }

        /// True for the long ranges, which draw the daily data dimmed under period segments.
        public var drawsSegments: Bool {
            switch self {
            case .week, .month: return false
            case .sixMonths, .year, .all: return true
            }
        }
    }

    // MARK: - Windows

    /// The days one pager position covers.
    public struct Window: Equatable, Sendable {
        /// The first day, inclusive.
        public let start: String
        /// The last day, inclusive.
        public let end: String
        /// 0 for the window ending on the anchor day, 1 for the one before it, and so on.
        public let page: Int
        /// Calendar days covered.
        public let dayCount: Int
        /// An older window would still hold readings (the pager's "‹" is enabled).
        public let hasOlder: Bool

        public init(start: String, end: String, page: Int, dayCount: Int, hasOlder: Bool) {
            self.start = start
            self.end = end
            self.page = page
            self.dayCount = dayCount
            self.hasOlder = hasOlder
        }

        /// A newer window exists (the pager's "›" is enabled).
        public var hasNewer: Bool { page > 0 }

        public func contains(_ day: String) -> Bool { day >= start && day <= end }

        /// Every day of the window, oldest first.
        public var dayKeys: [String] {
            guard let first = PulseTrendMath.jdn(start) else { return [] }
            return (0..<max(0, dayCount)).map { PulseTrendMath.key(fromJDN: first + $0) }
        }

        /// The window of the same length that ends the day before this one starts.
        public var previous: Window {
            let end = PulseTrendMath.addDays(start, -1)
            return Window(start: PulseTrendMath.addDays(end, -(dayCount - 1)), end: end, page: page + 1,
                          dayCount: dayCount, hasOlder: false)
        }
    }

    /// The window `page` positions back from the one ending on `anchor`, or nil for a malformed key.
    ///
    /// ALL has one position: from the series' first day (`earliest`) to the anchor. A finite range steps
    /// back by its own length; `hasOlder` says whether the window before this one would still reach a
    /// reading, so the pager never offers an empty page.
    public static func window(_ range: Range, anchor: String, page: Int = 0, earliest: String?) -> Window? {
        guard let anchorJDN = jdn(anchor) else { return nil }
        guard let days = range.days else {
            let first = earliest.flatMap(jdn).map { min($0, anchorJDN) } ?? anchorJDN
            return Window(start: key(fromJDN: first), end: anchor, page: 0, dayCount: anchorJDN - first + 1,
                          hasOlder: false)
        }
        let p = max(0, page)
        let endJDN = anchorJDN - p * days
        let startJDN = endJDN - (days - 1)
        let start = key(fromJDN: startJDN)
        let hasOlder = earliest.map { $0 < start } ?? false
        return Window(start: start, end: key(fromJDN: endJDN), page: p, dayCount: days, hasOlder: hasOlder)
    }

    /// The pages a range can step back through before its windows hold no reading at all (0 = only the
    /// latest), so a stored page can be clamped when the history shrinks.
    public static func lastPage(_ range: Range, anchor: String, earliest: String?) -> Int {
        guard let days = range.days, let earliest, let a = jdn(anchor), let e = jdn(earliest), e < a else {
            return 0
        }
        return (a - e) / days
    }

    /// The points inside `window`, oldest first. The input need not be sorted.
    public static func points(_ series: [Point], in window: Window) -> [Point] {
        series.filter { window.contains($0.day) && $0.value.isFinite }.sorted { $0.day < $1.day }
    }

    // MARK: - Averages

    /// A period's average.
    public struct Average: Equatable, Sendable {
        public let value: Double
        /// Readings behind it.
        public let count: Int
        /// The in-progress day left out of it, when that day held a reading.
        public let excludedDay: String?

        public init(value: Double, count: Int, excludedDay: String?) {
            self.value = value
            self.count = count
            self.excludedDay = excludedDay
        }
    }

    /// The mean of the window's readings, or nil when it has none.
    ///
    /// `inProgressDay` is a running total's day that is still counting (today's Strain, steps or calories):
    /// it is left out, as WHOOP leaves it out ("Average does not include today (Apr 15)"), because a
    /// half-finished day would drag the average down every morning. It stays in when it is the only
    /// reading, so the period still says something.
    public static func average(_ series: [Point], in window: Window, inProgressDay: String? = nil) -> Average? {
        let inside = points(series, in: window)
        guard !inside.isEmpty else { return nil }
        if let skip = inProgressDay, inside.contains(where: { $0.day == skip }) {
            let rest = inside.filter { $0.day != skip }
            if !rest.isEmpty {
                return Average(value: mean(rest.map(\.value)), count: rest.count, excludedDay: skip)
            }
        }
        return Average(value: mean(inside.map(\.value)), count: inside.count, excludedDay: nil)
    }

    // MARK: - Weekly totals (minute metrics: HR zones, strength time)

    /// One complete 7-day block's total.
    public struct WeekTotal: Equatable, Sendable {
        public let start: String
        public let end: String
        public let total: Double
        /// Days of the block that carried a reading.
        public let count: Int

        public init(start: String, end: String, total: Double, count: Int) {
            self.start = start
            self.end = end
            self.total = total
            self.count = count
        }
    }

    /// The window's COMPLETE 7-day blocks, counted back from its last day, oldest first. A leading
    /// partial block is dropped, so every total covers the same seven days. Blocks with no reading at all
    /// are dropped too: a week before the first reading is not a week of zeros.
    public static func weeklyTotals(_ series: [Point], in window: Window) -> [WeekTotal] {
        guard let endJDN = jdn(window.end), let startJDN = jdn(window.start) else { return [] }
        let inside = points(series, in: window)
        var byDay: [String: Double] = [:]
        for p in inside { byDay[p.day, default: 0] += p.value }
        var out: [WeekTotal] = []
        var blockEnd = endJDN
        while blockEnd - 6 >= startJDN {
            let keys = (0..<7).map { key(fromJDN: blockEnd - 6 + $0) }
            let present = keys.compactMap { byDay[$0] }
            if !present.isEmpty {
                out.append(WeekTotal(start: keys[0], end: keys[6], total: present.reduce(0, +),
                                     count: present.count))
            }
            blockEnd -= 7
        }
        return out.reversed()
    }

    /// The average of the window's complete weekly totals ("AVG. WEEKLY TOTAL"), or nil without one.
    public static func averageWeeklyTotal(_ series: [Point], in window: Window) -> Double? {
        let weeks = weeklyTotals(series, in: window)
        guard !weeks.isEmpty else { return nil }
        return mean(weeks.map(\.total))
    }

    // MARK: - Change against the previous period

    /// A period's value against the period before it.
    public struct Change: Equatable, Sendable {
        public let current: Double
        public let previous: Double
        /// `current - previous`, in the metric's unit.
        public let delta: Double
        /// `delta` as a percent of |previous|; nil when `previous` is too close to zero to divide by.
        public let percent: Double?

        public init(current: Double, previous: Double, delta: Double, percent: Double?) {
            self.current = current
            self.previous = previous
            self.delta = delta
            self.percent = percent
        }
    }

    /// The change from `previous` to `current`, or nil when either is missing.
    public static func change(current: Double?, previous: Double?, percentFloor: Double = 0.5) -> Change? {
        guard let current, let previous, current.isFinite, previous.isFinite else { return nil }
        let delta = current - previous
        let percent: Double? = abs(previous) >= percentFloor ? delta / abs(previous) * 100 : nil
        return Change(current: current, previous: previous, delta: delta, percent: percent)
    }

    // MARK: - Typical range

    /// The range a period is judged against: the mean ± one standard deviation of the readings in the
    /// `days` calendar days BEFORE `day` (the window's first day, so a period never sets its own yardstick),
    /// or nil with fewer than `minSamples` readings, which is too few to call anything typical.
    public static func typicalRange(_ series: [Point], before day: String, days: Int = 30,
                                    minSamples: Int = 7) -> ClosedRange<Double>? {
        guard days > 0 else { return nil }
        let start = addDays(day, -days)
        let values = series.filter { $0.day >= start && $0.day < day && $0.value.isFinite }.map(\.value)
        guard values.count >= max(2, minSamples) else { return nil }
        let m = mean(values)
        let sd = standardDeviation(values, mean: m)
        return (m - sd)...(m + sd)
    }

    /// How a value relates to a reference.
    public enum Relation: String, Equatable, Sendable {
        case below, within, above
    }

    /// Where `value` sits against a range (its bounds count as inside).
    public static func relation(_ value: Double, to range: ClosedRange<Double>) -> Relation {
        if value < range.lowerBound { return .below }
        if value > range.upperBound { return .above }
        return .within
    }

    /// How `value` compares with `reference`: within `tolerancePercent` of it (or printing the same,
    /// which the caller passes as equal values) reads `.within` ("consistent with"); otherwise above or
    /// below. A reference near zero uses `toleranceAbsolute` instead.
    public static func relation(_ value: Double, reference: Double, tolerancePercent: Double = 2,
                                toleranceAbsolute: Double = 0.05) -> Relation {
        let delta = value - reference
        if abs(reference) >= 0.5 {
            if abs(delta) / abs(reference) * 100 < tolerancePercent { return .within }
        } else if abs(delta) < toleranceAbsolute {
            return .within
        }
        return delta > 0 ? .above : .below
    }

    // MARK: - Segments (6M, 1Y, ALL)

    /// How a segment summarises its days.
    public enum Aggregation: Equatable, Sendable {
        /// The mean of its readings.
        case mean
        /// The average of its complete weekly totals (minute metrics).
        case weeklyTotal
    }

    /// One period segment of a long range: a horizontal line at its value, the value above it and the
    /// change from the previous segment below it.
    public struct Segment: Equatable, Sendable {
        public let start: String
        public let end: String
        /// The segment's value, or nil when it held no reading.
        public let value: Double?
        /// Readings behind it.
        public let count: Int
        /// Percent change from the nearest earlier segment with a value; nil for the first such segment,
        /// for one without a value, and when the earlier value is too close to zero to divide by.
        public let changePercent: Double?

        public init(start: String, end: String, value: Double?, count: Int, changePercent: Double?) {
            self.start = start
            self.end = end
            self.value = value
            self.count = count
            self.changePercent = changePercent
        }
    }

    /// The segment length a long range uses: 30 days for 6M (six segments, WHOOP's "monthly" lines are
    /// 30-day blocks counted back from the window's end), 61 for 1Y (six two-month segments, so the value
    /// labels keep the 6M spacing), and for ALL a whole number of 30 days that keeps it to six segments.
    public static func segmentDays(_ range: Range, dayCount: Int) -> Int {
        switch range {
        case .week, .month: return max(1, dayCount)
        case .sixMonths: return 30
        case .year: return 61
        case .all:
            let blocks = Int((Double(max(1, dayCount)) / 6.0 / 30.0).rounded(.up))
            return max(30, blocks * 30)
        }
    }

    /// Consecutive `blockDays` blocks counted back from the window's last day, oldest first. The oldest
    /// block may be shorter; one shorter than a third of a block is dropped (it would print a value
    /// from a few days as if it were a period).
    public static func segments(_ series: [Point], in window: Window, blockDays: Int,
                                aggregation: Aggregation = .mean, percentFloor: Double = 0.5) -> [Segment] {
        guard blockDays > 0, let endJDN = jdn(window.end), let startJDN = jdn(window.start) else { return [] }
        var blocks: [(start: Int, end: Int)] = []
        var blockEnd = endJDN
        while blockEnd >= startJDN {
            let blockStart = max(startJDN, blockEnd - blockDays + 1)
            blocks.append((blockStart, blockEnd))
            blockEnd = blockStart - 1
        }
        if let oldest = blocks.last, blocks.count > 1, (oldest.end - oldest.start + 1) * 3 < blockDays {
            blocks.removeLast()
        }
        blocks.reverse()

        var out: [Segment] = []
        var lastValue: Double?
        for b in blocks {
            let w = Window(start: key(fromJDN: b.start), end: key(fromJDN: b.end), page: 0,
                           dayCount: b.end - b.start + 1, hasOlder: false)
            let inside = points(series, in: w)
            let value: Double?
            switch aggregation {
            case .mean:
                value = inside.isEmpty ? nil : mean(inside.map(\.value))
            case .weeklyTotal:
                // A block shorter than a week still has a weekly RATE: its total scaled to seven days.
                if inside.isEmpty {
                    value = nil
                } else if w.dayCount >= 7 {
                    value = averageWeeklyTotal(series, in: w)
                        ?? inside.map(\.value).reduce(0, +) / Double(w.dayCount) * 7
                } else {
                    value = inside.map(\.value).reduce(0, +) / Double(w.dayCount) * 7
                }
            }
            var changePercent: Double?
            if let value, let lastValue, abs(lastValue) >= percentFloor {
                changePercent = (value - lastValue) / abs(lastValue) * 100
            }
            out.append(Segment(start: w.start, end: w.end, value: value, count: inside.count,
                               changePercent: changePercent))
            if let value { lastValue = value }
        }
        return out
    }

    // MARK: - Breakdown

    /// Counts of `values` per band, the bands given by their inclusive LOWER bounds from the highest band
    /// down (e.g. Recovery [67, 34] → green, yellow, red). The result has `lowerBounds.count + 1` entries;
    /// the last counts everything below the lowest bound. Pass values as they are PRINTED (a recovery of
    /// 66.6 prints "67%" and is green), so a count can never disagree with the bars above it.
    public static func breakdown(_ values: [Double], lowerBounds: [Double]) -> [Int] {
        var counts = [Int](repeating: 0, count: lowerBounds.count + 1)
        for v in values where v.isFinite {
            let index = lowerBounds.firstIndex { v >= $0 } ?? lowerBounds.count
            counts[index] += 1
        }
        return counts
    }

    // MARK: - Statistics

    static func mean(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    /// Sample standard deviation (n − 1); 0 for fewer than two values.
    static func standardDeviation(_ values: [Double], mean m: Double) -> Double {
        guard values.count >= 2 else { return 0 }
        let ss = values.reduce(0) { $0 + ($1 - m) * ($1 - m) }
        return (ss / Double(values.count - 1)).squareRoot()
    }

    // MARK: - Day arithmetic (time-zone free)

    /// `day` shifted by `days` calendar days ("yyyy-MM-dd"); a malformed key comes back unchanged.
    public static func addDays(_ day: String, _ days: Int) -> String {
        WeeklyDigestEngine.addDays(day, days)
    }

    /// Calendar days from `from` to `to` (negative when `to` is earlier), or nil for a malformed key.
    public static func daysBetween(_ from: String, _ to: String) -> Int? {
        guard let a = jdn(from), let b = jdn(to) else { return nil }
        return b - a
    }

    static func jdn(_ day: String) -> Int? {
        guard let (y, m, d) = WeeklyDigestEngine.parseYMD(day) else { return nil }
        return WeeklyDigestEngine.julianDayNumber(y, m, d)
    }

    static func key(fromJDN jdn: Int) -> String {
        let (y, m, d) = WeeklyDigestEngine.fromJulianDayNumber(jdn)
        return WeeklyDigestEngine.formatYMD(y, m, d)
    }
}
