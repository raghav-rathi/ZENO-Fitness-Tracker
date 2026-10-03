#if os(iOS)
import Foundation
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

// MARK: - The rebuilt Strain deep dive (WHOOP_UI_SPEC §3.5), built off the main actor

extension PulseSnapshotBuilder {

    /// Heart rate is read for time in zones as means of this many seconds, aggregated in SQL: a month of
    /// days without loading millions of rows, at a grain where a zone boundary moves by seconds.
    static let zoneBucketSeconds = 15

    /// The Strain dive for the request's day.
    ///
    /// Time in zones is the whole day's (the window Strain scores over), from ONE resolver for the
    /// contributor rows, the weekly zone bars and TIME IN ZONES, each day's figure cached against that
    /// day's heart-rate fingerprint so a refresh re-reads only the days whose heart rate changed.
    func strainDive(_ r: PulseRequest) async -> StrainDiveSnapshot? {
        guard let base = await strain(r) else { return nil }
        let rows = await workoutRows()
        let markers = r.prefs.sleepOnsetDayCycle ? await onsetMarkers() : []
        let ownWindow = await dayWindow(r)
        let steps = await stepsResolution(r)
        let calories = await caloriesResolution(r)
        guard isCurrent(r) else { return nil }

        // The day and the 30 before it: the contributors' averages, and the week inside them.
        let keys = PulseDisplay.trailingDayKeys(endingOn: r.day.key, count: 31)
        var windows: [(key: String, from: Int, to: Int)] = []
        for key in keys {
            if key == r.day.key {
                windows.append((key, ownWindow.from, ownWindow.to))
            } else if let w = Self.strainWindow(dayKey: key, markers: markers) {
                windows.append((key, w.from, w.to))
            }
        }
        // Today's window runs to now, so it is read fresh every build and never cached.
        let zones = await zoneSecondsByDay(windows, zoneSet: r.profile.zoneSet,
                                           liveKey: r.day.isToday ? r.day.key : nil)
        guard isCurrent(r) else { return nil }

        let byDay = Dictionary(r.days.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
        // Strength Activity Time per day: the union of that day's strength activities (a workout belongs
        // to the day its start falls in, as Today's Activities lists it). A day ZENO has a row for and no
        // strength activity is a real zero; a day it knows nothing about is left out of the average.
        var strength: [String: Double] = [:]
        for w in windows {
            let day = rows.filter { $0.startTs >= w.from && $0.startTs < w.to }
            let activities = day.map { row in
                (span: StrainContributors.Span(start: row.startTs, end: max(row.endTs, row.startTs)), sport: row.sport)
            }
            if byDay[w.key] != nil || !day.isEmpty || w.key == r.day.key {
                strength[w.key] = StrainContributors.strengthMinutes(activities)
            }
        }

        func zoneHistory(_ group: (_ minutes: (lower: Double, upper: Double)) -> Double) -> [(day: String, value: Double)] {
            zones.map { key, seconds in
                (day: key, value: group(StrainContributors.zoneGroups(seconds.map { $0 / 60 })))
            }
        }
        let ownZones = zones[r.day.key].map { StrainContributors.zoneGroups($0.map { $0 / 60 }) }
        let duration: (Double) -> String = { PulseFormat.hoursMinutes($0) }
        let contributors = [
            PulseDiveBaseline.contributor(
                id: "hr_zones13_min", symbol: "heart", title: String(localized: "Heart rate zones 1-3"),
                value: ownZones?.lower, dayKey: r.day.key, history: zoneHistory { $0.lower }, polarity: .higherIsBetter,
                route: PulseDiveRoutes.trend("hr_zones13_min"), text: duration,
                spoken: PulseDiveBaseline.spokenDuration),
            PulseDiveBaseline.contributor(
                id: "hr_zones45_min", symbol: "bolt.heart", title: String(localized: "Heart rate zones 4-5"),
                value: ownZones?.upper, dayKey: r.day.key, history: zoneHistory { $0.upper }, polarity: .higherIsBetter,
                route: PulseDiveRoutes.trend("hr_zones45_min"), text: duration,
                spoken: PulseDiveBaseline.spokenDuration),
            PulseDiveBaseline.contributor(
                id: "strength_min", symbol: "dumbbell", title: String(localized: "Strength activity time"),
                value: strength[r.day.key], dayKey: r.day.key,
                history: strength.map { (day: $0.key, value: $0.value) }, polarity: .higherIsBetter,
                route: PulseDiveRoutes.trend("strength_min"), text: duration,
                spoken: PulseDiveBaseline.spokenDuration),
            PulseDiveBaseline.contributor(
                id: "steps", symbol: "shoe", title: String(localized: "Steps"),
                value: steps.value, dayKey: r.day.key, history: steps.history, polarity: .higherIsBetter,
                route: PulseDiveRoutes.trend("steps", fallback: .tab(steps.route)), text: PulseFormat.grouped,
                spoken: { String(localized: "\(PulseFormat.grouped($0)) steps") }),
        ]

        // The week.
        let weekKeys = PulseDiveWeek.keys(endingOn: r.day.key)
        let strainWeek = self.week(r, liveStrain: base.dial.value)
        let strainByDay = Dictionary(strainWeek.map { ($0.id, $0.strain) }, uniquingKeysWith: { _, last in last })
        let stepsByDay = Dictionary(steps.history.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        // Calories through the one resolver Home's CALORIES tile and this dive's stats read
        // (`caloriesResolution`): Apple Health's imported figure first, else the on-device estimate, and the
        // catalog key of the source it chose for the card's Trend View.
        let caloriesByDay = Dictionary(calories.history.map { ($0.day, $0.value) },
                                       uniquingKeysWith: { _, last in last })
        var caloriesMetric = "energy_kcal"
        if case .metricSourced(let key, _) = calories.route { caloriesMetric = key }
        let trends = StrainDiveSnapshot.Week(
            strain: PulseDiveWeek.data(weekKeys, value: { strainByDay[$0] ?? nil }, color: { _ in PulseTheme.strain },
                                       label: PulseFormat.oneDecimal),
            lowerZones: weekKeys.map { key in
                Self.zoneColumn(key, seconds: zones[key], zones: [1, 2, 3])
            },
            upperZones: weekKeys.map { key in
                Self.zoneColumn(key, seconds: zones[key], zones: [4, 5])
            },
            steps: PulseDiveWeek.data(weekKeys, value: { stepsByDay[$0] }, color: { _ in PulseTheme.strain },
                                      label: PulseFormat.grouped),
            calories: PulseDiveWeek.data(weekKeys, value: { caloriesByDay[$0] },
                                         color: { _ in PulseTheme.strain }, label: PulseFormat.grouped),
            caloriesMetric: caloriesMetric,
            stepsRoute: PulseDiveRoutes.trend("steps", fallback: .tab(steps.route)),
            highlightID: r.day.key)

        let activities = base.workouts.map { w in
            StrainDiveSnapshot.Activity(
                id: w.id, chip: w.strain == nil ? .pending : .strain,
                symbol: WorkoutTypeIconography.systemSymbolName(for: w.sport),
                chipValue: w.strain.map { PulseFormat.oneDecimal($0) }, name: w.title,
                start: w.start, end: w.start.addingTimeInterval(TimeInterval(w.durationMin * 60)),
                route: PulseRoute.activityDetail(w.route).forExistingEntryPoint)
        }

        let ownTarget = base.target.flatMap { $0.fromCarriedRecovery ? nil : $0 }
        let text = Self.strainSentences(strain: base.dial.value, target: ownTarget, day: r.day,
                                        contributors: contributors)
        guard isCurrent(r) else { return nil }
        return StrainDiveSnapshot(seq: r.seq, day: r.day, base: base, contributors: contributors,
                                  insight: text.insight, zoneSeconds: zones[r.day.key], activities: activities,
                                  week: trends, summary: text.summary, coachSeed: text.seed)
    }

    // MARK: Day windows

    /// The window a PAST day's Strain is scored over, resolved as `dayWindow(_:)` resolves the request's
    /// day: the day-cycle onset markers when that mode is on, else local midnight to midnight. (The
    /// request's own day, today included, takes `dayWindow(_:)` itself.)
    static func strainWindow(dayKey: String, markers: [(day: String, value: Double)]) -> (from: Int, to: Int)? {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        let cal = Calendar.current
        guard let midnight = cal.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
            return nil
        }
        let dayStart = cal.startOfDay(for: midnight)
        let nextStart = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let calendarFrom = Int(dayStart.timeIntervalSince1970)
        let calendarTo = Int(nextStart.timeIntervalSince1970)
        let nextKey = Repository.localDayKey(nextStart)
        let from = markers.last(where: { $0.day == dayKey }).map { Int($0.value) } ?? calendarFrom
        let toExclusive = markers.last(where: { $0.day == nextKey }).map { Int($0.value) } ?? calendarTo
        return (from, max(from, toExclusive - 1))
    }

    // MARK: Time in zones

    /// Seconds in zones 1-5 per day key, for days with heart rate (a day without any is absent, never a
    /// zero). A finished day is re-read only when its heart-rate fingerprint or the zone set changed;
    /// `liveKey`'s window (today's, running to now) is read every time and kept out of the cache, so its
    /// churn never pushes the finished days out.
    private func zoneSecondsByDay(_ windows: [(key: String, from: Int, to: Int)], zoneSet: HRZoneSet,
                                  liveKey: String?) async -> [String: [Double]] {
        let signature = "\(zoneSet.maxHR)|\(zoneSet.restingHR ?? -1)|"
            + zoneSet.zones.map { "\($0.lower)" }.joined(separator: ",")
        var out: [String: [Double]] = [:]
        for w in windows {
            if Task.isCancelled { break }
            let live = w.key == liveKey
            var cacheKey: String?
            if !live {
                let fingerprint = await repo.hrFingerprintUnion(from: w.from, to: w.to)
                cacheKey = "\(w.from)|\(w.to)|\(fingerprint)|\(signature)"
            }
            if let cacheKey, let hit = await PulseZoneDayCache.shared.lookup(cacheKey) {
                if let seconds = hit { out[w.key] = seconds }
                continue
            }
            let buckets = await repo.hrBuckets(from: w.from, to: w.to, bucketSeconds: Self.zoneBucketSeconds)
            let seconds: [Double]? = buckets.isEmpty ? nil : StrainContributors.zoneSeconds(
                buckets: buckets.map { StrainContributors.HRBucketMean(ts: $0.ts, bpm: $0.bpm) },
                bucketSeconds: Self.zoneBucketSeconds, zoneSet: zoneSet)
            if let cacheKey { await PulseZoneDayCache.shared.store(cacheKey, seconds) }
            if let seconds { out[w.key] = seconds }
        }
        return out
    }

    /// One day's stacked zone column: the zones given, bottom to top, with the h:mm total above
    /// ("0:00" on a day with heart rate and no time in them; nothing on a day without heart rate).
    static func zoneColumn(_ key: String, seconds: [Double]?, zones: [Int]) -> PulseStackedBarChart.Column {
        guard let seconds else {
            return PulseStackedBarChart.Column(id: key, label: PulseWeekLabels.weekday(key),
                                               sublabel: PulseWeekLabels.dayNumber(key), segments: [],
                                               totalLabel: nil)
        }
        let segments = zones.map { zone in
            PulseStackedBarChart.Segment(id: "\(key)-z\(zone)",
                                         value: seconds.indices.contains(zone - 1) ? seconds[zone - 1] / 60 : 0,
                                         color: PulseTheme.Zone.color(zone))
        }
        let total = segments.reduce(0) { $0 + $1.value }
        return PulseStackedBarChart.Column(id: key, label: PulseWeekLabels.weekday(key),
                                           sublabel: PulseWeekLabels.dayNumber(key), segments: segments,
                                           totalLabel: PulseFormat.hoursMinutes(total))
    }

    // MARK: Sentences

    /// The inline insight (§3.5 item 4), the coach pill's sentence and the plain page context for the
    /// Coach. The range copy follows WHOOP's: above the optimal range it says so; before Recovery has
    /// scored for the day it says the recommendation is still to come; otherwise the band's meaning.
    static func strainSentences(strain: Double?, target: PulseStrainTarget?, day: PulseDay,
                                contributors: [PulseDiveContributor]) -> (insight: String, summary: String, seed: String) {
        let dayName = PulseFormat.navDayTitle(offset: day.offset, date: day.date)
        var seed = String(localized: "Strain deep dive, \(dayName).")
        guard let strain else {
            let none = day.isToday
                ? String(localized: "Strain builds here as your strap records heart rate through the day.")
                : String(localized: "No Strain was recorded for this day.")
            return (none, day.isToday ? String(localized: "No Strain yet today.") : none, seed)
        }
        let shown = PulseFormat.oneDecimal(strain)
        let band: String
        switch StrainContributors.band(strain: strain) {
        case .light:
            band = String(localized: "Strain between 0 and 9.9 is considered light, meaning your cardiovascular load has been minimal.")
        case .moderate:
            band = String(localized: "Strain between 10 and 13.9 is considered moderate. Your cardiovascular load is significant but not strenuous.")
        case .strenuous:
            band = String(localized: "Strain between 14.0 and 17.9 is considered strenuous, meaning your cardiovascular system has been working hard.")
        case .allOut:
            band = String(localized: "Strain between 18 and 21 represents near maximal cardiovascular load. Dedicate additional time to rest and recovery.")
        }

        let insight: String
        let summary: String
        if let target {
            let range = target.rangeText
            switch StrainContributors.standing(strain: strain, range: target.range) {
            case .above:
                // Differences of the PRINTED figures, so the gap never reads "0.0".
                let over = PulseFormat.oneDecimal(StrainContributors.printedOneDecimal(strain)
                                                  - StrainContributors.printedOneDecimal(target.range.upperBound))
                insight = day.isToday
                    ? String(localized: "You've worked extra hard today and have exceeded a balanced level of Strain. Reduce fatigue tomorrow by dedicating extra time to rest and recovery.")
                    : String(localized: "This day's Strain went past its optimal range of \(range), beyond a balanced level for that day's Recovery.")
                summary = day.isToday
                    ? String(localized: "Strain is **\(shown)**, **\(over) above** today's optimal range of \(range).")
                    : String(localized: "Strain was **\(shown)**, **\(over) above** that day's optimal range of \(range).")
            case .below:
                let under = PulseFormat.oneDecimal(StrainContributors.printedOneDecimal(target.range.lowerBound)
                                                   - StrainContributors.printedOneDecimal(strain))
                insight = day.isToday
                    ? band + " " + String(localized: "Today's optimal Strain is \(range), so there is room for more activity if you feel up to it.")
                    : band + " " + String(localized: "That day's optimal Strain was \(range).")
                summary = day.isToday
                    ? String(localized: "Strain is **\(shown)** so far, **\(under) below** today's optimal range of \(range).")
                    : String(localized: "Strain was **\(shown)**, **\(under) below** that day's optimal range of \(range).")
            case .within:
                insight = band + " " + (day.isToday
                    ? String(localized: "That is within today's optimal range of \(range).")
                    : String(localized: "That was within the day's optimal range of \(range)."))
                summary = day.isToday
                    ? String(localized: "Strain is **\(shown)**, within today's optimal range of **\(range)**.")
                    : String(localized: "Strain was **\(shown)**, within that day's optimal range of **\(range)**.")
            }
            seed += " " + String(localized: "Strain \(shown) of 21, optimal range \(range).")
        } else {
            insight = day.isToday
                ? String(localized: "Your optimal Strain recommendation will be calculated once ZENO processes your recent Recovery.")
                : band
            summary = day.isToday
                ? String(localized: "Strain is **\(shown)** so far today.")
                : String(localized: "Strain was **\(shown)** on \(dayName).")
            seed += " " + String(localized: "Strain \(shown) of 21.")
        }
        for row in contributors where row.value != "--" {
            seed += " " + (row.baseline.map { String(localized: "\(row.title) \(row.value) (30-day average \($0)).") }
                           ?? "\(row.title) \(row.value).")
        }
        return (insight, summary, seed)
    }
}

// MARK: - Zone-time cache

/// Days' seconds in heart-rate zones, kept across refreshes while a day's heart rate is unchanged: the key
/// carries the day window, the heart-rate fingerprint and the zone bounds the seconds were binned by, so new
/// beats, a backfilled night or a changed maximum heart rate each make a new key. The Strain dive keeps
/// each day's five zones here, the Challenges each finished day's Zone 2 (`zone2Minutes`, keys "zone2|…").
/// Holds at most `capacity` finished days.
actor PulseZoneDayCache {
    static let shared = PulseZoneDayCache()

    /// A value per key; a stored nil means "no heart rate in that window".
    private var entries: [String: [Double]?] = [:]
    private var order: [String] = []
    private let capacity = 160

    /// The cached figure (`.some(nil)` for a window without heart rate), or nil when not cached.
    func lookup(_ key: String) -> [Double]?? {
        entries[key]
    }

    func store(_ key: String, _ value: [Double]?) {
        if entries[key] == nil { order.append(key) }
        entries[key] = .some(value)
        while order.count > capacity {
            entries.removeValue(forKey: order.removeFirst())
        }
    }
}
#endif
