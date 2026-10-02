import Foundation
import WhoopProtocol

// StrainContributors.swift - the Strain deep dive's contributor math (WHOOP_UI_SPEC §3.5).
//
// The Pulse Strain dive explains a day's Strain with four contributors: time in heart-rate zones 1-3,
// time in zones 4-5, Strength Activity Time and steps, each against its own 30-day average. This file
// holds the rules that turn stored rows into those figures, so they are unit-tested without a view, a
// store or a clock:
//
//   - time in zones from bucketed heart rate (the store aggregates the raw ~1 Hz stream in SQL), so a
//     whole month of days can be scored without loading millions of rows;
//   - which activities count as strength activities, and their time as the UNION of their spans, so a
//     session recorded twice (the strap's bout and an Apple Health import of the same lift) counts once;
//   - the day's Strain band (light / moderate / strenuous / all out) and where it stands against the
//     day's optimal range, both judged on the one-decimal figure the dial prints.
//
// Display-only by design, like PulseDisplay: nothing here is persisted, fed back into an engine, or sent
// across the .noopbak boundary, so there is no Kotlin twin to keep byte-identical.

public enum StrainContributors {

    // MARK: - Time in heart-rate zones

    /// One bucket of heart rate: the bucket's start and the MEAN bpm of the readings inside it.
    public struct HRBucketMean: Equatable, Sendable {
        public let ts: Int
        public let bpm: Double

        public init(ts: Int, bpm: Double) {
            self.ts = ts
            self.bpm = bpm
        }
    }

    /// Seconds in zones 1...5 (index 0 = Zone 1) from bucketed heart rate.
    ///
    /// Each bucket that holds a reading counts `bucketSeconds` in the zone its mean falls in; time below
    /// Zone 1 is not counted, and a bucket with no reading (strap off) counts nothing, so missing wear is
    /// never drawn as rest. Buckets sharing a start are counted once (the first wins), so a caller that
    /// merges two straps' buckets cannot double-count an overlap.
    ///
    /// The buckets are means, so a short spike inside a bucket is smoothed into its neighbours; at the
    /// 15-second buckets the dive reads, that moves a zone boundary by seconds, not minutes.
    public static func zoneSeconds(buckets: [HRBucketMean], bucketSeconds: Int, zoneSet: HRZoneSet) -> [Double] {
        var seconds = [Double](repeating: 0, count: 5)
        guard bucketSeconds > 0 else { return seconds }
        var seen = Set<Int>()
        for bucket in buckets where bucket.bpm.isFinite && bucket.bpm > 0 {
            guard seen.insert(bucket.ts).inserted else { continue }
            let zone = zoneSet.zoneNumber(forBPM: bucket.bpm)
            if zone >= 1 && zone <= 5 { seconds[zone - 1] += Double(bucketSeconds) }
        }
        return seconds
    }

    /// Zones 1-3 and zones 4-5 from five per-zone values (index 0 = Zone 1), in the values' own unit.
    public static func zoneGroups(_ perZone: [Double]) -> (lower: Double, upper: Double) {
        func at(_ i: Int) -> Double { perZone.indices.contains(i) ? max(0, perZone[i]) : 0 }
        return (at(0) + at(1) + at(2), at(3) + at(4))
    }

    // MARK: - Strength Activity Time

    /// A time span in unix seconds, `start` inclusive and `end` exclusive.
    public struct Span: Equatable, Sendable {
        public let start: Int
        public let end: Int

        public init(start: Int, end: Int) {
            self.start = start
            self.end = end
        }
    }

    /// Whether an activity's sport counts toward Strength Activity Time: activities that put a muscular
    /// load on the body, after the published list of activities that count toward it (weightlifting,
    /// powerlifting, functional fitness, HIIT, pilates and barre, yoga, climbing, rucking, paddling,
    /// grappling, …), plus Apple Health's strength workout names.
    ///
    /// Matched on the sport's letters and digits only, case-insensitively, so "Strength Training",
    /// "strength_training", "Jiu jitsu" and "Jiu-Jitsu" all resolve the same way. "Stair climber" is
    /// cardio and is not climbing.
    public static func isStrengthActivity(_ sport: String) -> Bool {
        let key = normalized(sport)
        guard !key.isEmpty else { return false }
        if key.contains("stairclimb") { return false }
        return strengthTokens.contains { key.contains($0) }
    }

    /// Substrings of a normalised sport name that mark a strength activity.
    static let strengthTokens: [String] = [
        "strength", "weight", "lifting", "bodybuilding", "functionalfitness", "crossfit", "hiit",
        "highintensityinterval", "pilates", "barre", "yoga", "climbing", "boulder", "rucking", "kayak",
        "canoe", "jiujitsu", "breakdanc", "kiteboard", "wakeboard", "wheelchair", "f45", "solidcore",
        "boxfitness", "manuallabor", "manuallabour", "snowshovel", "firefight", "babywearing",
        "toddlerwearing", "coretraining",
    ]

    static func normalized(_ sport: String) -> String {
        String(sport.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    /// Seconds covered by the union of `spans`: overlapping or touching spans count once, empty or
    /// inverted spans count nothing.
    public static func unionSeconds(_ spans: [Span]) -> Int {
        let sorted = spans.filter { $0.end > $0.start }.sorted { $0.start < $1.start }
        var total = 0
        var current: Span?
        for span in sorted {
            guard let open = current else {
                current = span
                continue
            }
            if span.start <= open.end {
                current = Span(start: open.start, end: max(open.end, span.end))
            } else {
                total += open.end - open.start
                current = span
            }
        }
        if let open = current { total += open.end - open.start }
        return total
    }

    /// Strength Activity Time in minutes: the union of the strength activities' spans, so a lift logged
    /// in the Lift Log and the strap's bout for the same session count once.
    public static func strengthMinutes(_ activities: [(span: Span, sport: String)]) -> Double {
        Double(unionSeconds(activities.filter { isStrengthActivity($0.sport) }.map(\.span))) / 60
    }

    // MARK: - Strain band and the optimal range

    /// The Strain band a day falls in: light 0-9.9, moderate 10-13.9, strenuous 14-17.9, all out 18-21.
    public enum Band: String, CaseIterable, Equatable, Sendable {
        case light, moderate, strenuous, allOut
    }

    /// The band for a day's Strain (0-21), judged on the one-decimal figure the dial prints: 13.96
    /// prints "14.0" and must read strenuous, not moderate.
    public static func band(strain: Double) -> Band {
        let shown = printedOneDecimal(strain)
        if shown >= 18 { return .allOut }
        if shown >= 14 { return .strenuous }
        if shown >= 10 { return .moderate }
        return .light
    }

    /// Where a day's Strain stands against its optimal range.
    public enum Standing: String, Equatable, Sendable {
        case below, within, above
    }

    /// Below, within or above `range`, judged on the printed one-decimal figures, so "14.0" against a
    /// 10.0-14.0 range reads within whatever the hundredths were.
    public static func standing(strain: Double, range: ClosedRange<Double>) -> Standing {
        let shown = printedOneDecimal(strain)
        if shown < printedOneDecimal(range.lowerBound) { return .below }
        if shown > printedOneDecimal(range.upperBound) { return .above }
        return .within
    }

    /// `value` as the app prints it with one decimal, read back as a number.
    ///
    /// Formatted exactly as the Strain dial formats it (`String(format: "%.1f", locale:)`), never scaled
    /// and rounded, because the two disagree at a half. With a locale, Foundation rounds the value's
    /// shortest decimal form half-to-even: 17.95 prints "18.0" and 14.05 prints "14.0", where a C `printf`
    /// (no locale) gives "17.9" and "14.1" and a half-away rounding gives "18.0" and "14.1". Any of the
    /// other two would let a band or a standing disagree with the number on the dial.
    static func printedOneDecimal(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return Double(String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), value)) ?? value
    }
}
