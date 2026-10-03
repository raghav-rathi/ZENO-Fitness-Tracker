#if os(iOS)
import Foundation
import SwiftUI
import StrandAnalytics
import WhoopStore
import WhoopProtocol

/// What an activity build needs from the main actor that `PulseRequest` does not carry. Captured by the
/// view and handed in, so the builder never reads a main-actor store or a key it does not own.
struct ActivityBuildInputs: Equatable {
    /// `ProfileStore.hrMax`: the max the classic workout detail scores heart-rate recovery against.
    var hrMax: Int
    /// `ProfileStore.stepTicksPerStep`: the strap step counter's calibration.
    var stepTicksPerStep: Double
    /// The exercise-distance unit system ("metric" / "imperial").
    var distanceImperial: Bool
    /// The body unit system, for tonnage.
    var massImperial: Bool
}

extension PulseSnapshotBuilder {

    // MARK: - Activity Details (§3.6)

    /// Activity Details for one workout. Re-reads the row from the store (so an edit lands), the heart rate
    /// of its own recording strap from a little before the start to a little after the end (one read
    /// feeds the chart, the zones and the minimum), its zone split (an import's own percentages when it
    /// has them, never overwritten), this sport's last 30 days for every comparison, heart-rate recovery,
    /// the recorded route and a paired Lift Log session.
    func activityDetail(_ r: PulseRequest, row handed: WorkoutRow,
                        inputs: ActivityBuildInputs) async -> ActivityDetailSnapshot? {
        begin(r.seq)
        let rows = await workoutRows()
        guard isCurrent(r) else { return nil }
        let stored = rows.first { Self.isSameWorkout($0, handed) }
        let row = stored ?? handed

        let start = Date(timeIntervalSince1970: TimeInterval(row.startTs))
        let end = Date(timeIntervalSince1970: TimeInterval(max(row.endTs, row.startTs + 1)))
        let duration = row.durationS ?? Double(max(row.endTs - row.startTs, 0))
        let span = Double(max(row.endTs - row.startTs, 60))
        let pad = Int(max(60, min(900, span * 0.08)))

        // One read of the recording strap's heart rate over the window and its margins.
        let activeStrap = await repo.deviceId
        let imported = await repo.importedReadIds
        let ids = Repository.workoutHrDeviceIds(source: row.source, activeStrapId: activeStrap, importedIds: imported)
        let samples = await repo.hrSamples(deviceIds: ids, from: row.startTs - pad, to: row.endTs + pad, limit: 60_000)
        guard isCurrent(r) else { return nil }
        let window = samples.filter { $0.ts >= row.startTs && $0.ts <= row.endTs }

        // The paired Lift Log session, when there is one.
        let lift = await liftSummary(for: row, inputs: inputs)
        guard isCurrent(r) else { return nil }

        let variant: ActivityDetailSnapshot.Variant = lift != nil ? .strength
            : (PulseActivityCatalog.isRecovery(row.sport) ? .recovery : .strain)
        let ownership: ActivityDetailSnapshot.Ownership
        if stored == nil {
            ownership = .missing
        } else if lift != nil {
            ownership = .liftLinked
        } else {
            switch WorkoutSource.classify(row.source) {
            case .manual: ownership = .manual
            case .detected: ownership = .detected
            case .whoop, .apple, .lifting, .activityFile: ownership = .imported
            }
        }

        // This sport's other sessions over the 30 days before this one.
        let others = rows.filter { other in
            !Self.isSameWorkout(other, row)
                && other.sport.caseInsensitiveCompare(row.sport) == .orderedSame
                && other.startTs < row.startTs && other.startTs >= row.startTs - 30 * 86_400
        }
        let history = await sportHistory(for: row, rows: rows, zoneSet: r.profile.zoneSet)
        guard isCurrent(r) else { return nil }

        // Zones: an import's own split first (never overwritten by an on-device approximation), else the
        // strap's heart rate over the window, against the zone set every other Pulse screen uses.
        let zoneSet = r.profile.zoneSet
        var zoneSeconds: [Double]   // index 0 = below Zone 1 … 5 = Zone 5
        var fromImport = false
        if let pct = WorkoutZones.percents(row.zonesJSON), duration > 0 {
            let z = pct.map { duration * $0 / 100 }
            zoneSeconds = [max(0, duration - z.reduce(0, +))] + z
            fromImport = true
        } else {
            let tiz = HRZones.timeInZone(window, zoneSet: zoneSet)
            zoneSeconds = window.isEmpty ? [Double](repeating: 0, count: 6) : [tiz.belowZone1] + tiz.seconds
        }
        let credited = zoneSeconds.reduce(0, +)
        let zones = (0...5).reversed().map { z -> ActivityZoneRow in
            ActivityZoneRow(zone: z,
                            range: fromImport ? Self.importedZoneRange(z) : Self.zoneRange(z, zoneSet: zoneSet),
                            share: credited > 0 ? zoneSeconds[z] / credited : 0,
                            seconds: zoneSeconds[z],
                            typical: history.typicalShares[z])
        }

        // Headline.
        let strain = row.strain.map { UnitFormatter.effortValue($0, scale: .whoop) }
        let strainAverage = Self.mean(others.compactMap { $0.strain }).map { UnitFormatter.effortValue($0, scale: .whoop) }
        var strainNote: String?
        if strain == nil {
            if window.count < 2 || credited < 600 {
                strainNote = String(localized: "There wasn't enough heart-rate data during this activity to calculate its Strain.")
            } else if WorkoutSource.classify(row.source) == .manual {
                strainNote = String(localized: "This activity's Strain is calculated from your strap's heart rate the next time ZENO analyses your data.")
            } else {
                strainNote = String(localized: "This activity was imported without a Strain.")
            }
        }
        let steps = await activitySteps(for: row, inputs: inputs)
        let durationAverage = Self.mean(others.map { $0.durationS ?? Double(max($0.endTs - $0.startTs, 0)) })
        guard isCurrent(r) else { return nil }

        let hrr = await repo.workoutHeartRateRecovery(from: row.startTs, to: row.endTs, maxHR: Double(inputs.hrMax),
                                                      source: row.source)
        guard isCurrent(r) else { return nil }

        let route = Self.routeSummary(for: row, duration: duration, imperial: inputs.distanceImperial)
        let minHR = window.map(\.bpm).min()
        let otherMinHRs = variant == .recovery ? await minHeartRates(before: row, others: others) : []
        guard isCurrent(r) else { return nil }
        let keyStats = Self.keyStats(row: row, variant: variant, duration: duration, steps: steps, minHR: minHR,
                                     others: others, historyMinHR: otherMinHRs, inputs: inputs)
        let insight = Self.insight(row: row, variant: variant, zoneSeconds: zoneSeconds, hasZones: credited > 0,
                                   typicalHighZoneSeconds: history.typicalHighZoneSeconds,
                                   duration: duration, durationAverage: durationAverage, lift: lift)

        return ActivityDetailSnapshot(
            seq: r.seq, row: row, variant: variant, ownership: ownership,
            title: WorkoutSource.displaySport(row.sport),
            symbol: PulseActivityCatalog.symbol(for: row.sport),
            start: start, end: end, timeRange: ActivityFormat.timeRange(start, end),
            sourceChip: Self.sourceChip(row.source),
            programChip: lift?.programName,
            strain: strain, strainAverage: strainAverage, strainNote: strainNote, steps: steps,
            durationSeconds: duration, durationAverage: variant == .recovery ? durationAverage : nil,
            hr: Self.displayPoints(samples),
            chartSpan: Date(timeIntervalSince1970: TimeInterval(row.startTs - pad))...Date(timeIntervalSince1970: TimeInterval(row.endTs + pad)),
            windowSampleCount: window.count,
            zones: zones, zonesFromImport: fromImport,
            zoneFootnote: Self.zoneFootnote(zoneSet: zoneSet, fromImport: fromImport),
            keyStats: keyStats, hrRecovery: hrr?.hasMeasurement == true ? hrr : nil, route: route, lift: lift,
            insight: insight)
    }

    /// The heart rate of a row's own strap around it (half its length either side, at least 15 minutes,
    /// never past now), bucketed for a chart: the Edit sheet's scrubber [Z].
    func activityHeartRate(around row: WorkoutRow) async -> [PulseTimeValue] {
        let pad = max(15 * 60, (row.endTs - row.startTs) / 2)
        let now = Int(Date().timeIntervalSince1970)
        let activeStrap = await repo.deviceId
        let imported = await repo.importedReadIds
        let ids = Repository.workoutHrDeviceIds(source: row.source, activeStrapId: activeStrap, importedIds: imported)
        let samples = await repo.hrSamples(deviceIds: ids, from: row.startTs - pad, to: min(now, row.endTs + pad),
                                           limit: 60_000)
        return Self.displayPoints(samples)
    }

    /// The same workout: its natural key (start and sport) and source.
    static func isSameWorkout(_ a: WorkoutRow, _ b: WorkoutRow) -> Bool {
        a.startTs == b.startTs && a.source == b.source && a.sport.caseInsensitiveCompare(b.sport) == .orderedSame
    }

    // MARK: Heart rate

    /// The chart's points: means over buckets small enough to keep a session's shape (≤ ≈300 points), with
    /// a gap wherever the strap recorded nothing for a while, so a dropout reads as a gap, not a line.
    static func displayPoints(_ samples: [HRSample]) -> [PulseTimeValue] {
        guard let first = samples.first, let last = samples.last, last.ts > first.ts else {
            return samples.map { PulseTimeValue(date: Date(timeIntervalSince1970: TimeInterval($0.ts)),
                                                value: Double($0.bpm)) }
        }
        let bucket = max(5, Int((Double(last.ts - first.ts) / 300).rounded(.up)))
        var sums: [Int: (Double, Int)] = [:]
        for s in samples {
            let k = (s.ts - first.ts) / bucket
            let (sum, n) = sums[k] ?? (0, 0)
            sums[k] = (sum + Double(s.bpm), n + 1)
        }
        let maxGap = max(120, bucket * 4)
        var out: [PulseTimeValue] = []
        var previous: Int?
        for k in sums.keys.sorted() {
            guard let (sum, n) = sums[k] else { continue }
            let ts = first.ts + k * bucket + bucket / 2
            if let previous, ts - previous > maxGap {
                out.append(PulseTimeValue(date: Date(timeIntervalSince1970: TimeInterval(previous + 1)), value: nil))
            }
            out.append(PulseTimeValue(date: Date(timeIntervalSince1970: TimeInterval(ts)), value: sum / Double(n)))
            previous = ts
        }
        return out
    }

    // MARK: Zones

    /// "162-171 BPM", "172+ BPM" for Zone 5, "<118 BPM" below Zone 1: the bounds the zone set bins by.
    static func zoneRange(_ zone: Int, zoneSet: HRZoneSet) -> String {
        let bpm = String(localized: "BPM")
        if zone == 0 {
            guard let z1 = zoneSet.zones.first(where: { $0.number == 1 }) else { return "" }
            return "<\(Int(z1.lower.rounded(.up))) \(bpm)"
        }
        guard let z = zoneSet.zones.first(where: { $0.number == zone }) else { return "" }
        let lower = Int(z.lower.rounded(.up))
        if zone == 5 { return "\(lower)+ \(bpm)" }
        let upper = max(lower, Int(z.upper.rounded(.up)) - 1)
        return "\(lower)-\(upper) \(bpm)"
    }

    /// An import's zones are its own (% of max heart rate), so they keep its percentages, not ZENO's bpm.
    static func importedZoneRange(_ zone: Int) -> String {
        switch zone {
        case 0: return "(<50%)"
        case 5: return "(90-100%)"
        default: return "(\(40 + zone * 10)-\(50 + zone * 10)%)"
        }
    }

    static func zoneFootnote(zoneSet: HRZoneSet, fromImport: Bool) -> String {
        if fromImport {
            return String(localized: "This split came with the import, in its own zones (% of max heart rate).")
        }
        let max = Int(zoneSet.maxHR.rounded())
        if let resting = zoneSet.restingHR {
            return String(localized: "Zones use your heart-rate reserve: max \(max) bpm, resting \(Int(resting.rounded())) bpm.")
        }
        return String(localized: "Zones use your max heart rate of \(max) bpm.")
    }

    /// This sport's typical zone shares (the middle half of up to eight recent sessions, needing three) and
    /// the typical minutes in Zones 4–5. Read once per refresh.
    struct ActivitySportHistory {
        /// Index 0…5 → the typical share as a range of the bar, or nil.
        var typicalShares: [ClosedRange<Double>?] = Array(repeating: nil, count: 6)
        var typicalHighZoneSeconds: Double?
    }

    func sportHistory(for row: WorkoutRow, rows: [WorkoutRow], zoneSet: HRZoneSet) async -> ActivitySportHistory {
        let key = "activity.history.\(row.sport.lowercased())|\(row.startTs)"
        return await cached(key) {
            var out = ActivitySportHistory()
            let prior = rows.filter { other in
                other.sport.caseInsensitiveCompare(row.sport) == .orderedSame
                    && other.startTs < row.startTs && other.startTs >= row.startTs - 120 * 86_400
            }
            .sorted { $0.startTs > $1.startTs }
            .prefix(8)

            let activeStrap = await repo.deviceId
            let imported = await repo.importedReadIds
            var shares: [[Double]] = []
            var highs: [Double] = []
            for other in prior {
                let duration = other.durationS ?? Double(max(other.endTs - other.startTs, 0))
                var seconds: [Double]?
                if let pct = WorkoutZones.percents(other.zonesJSON), duration > 0 {
                    let z = pct.map { duration * $0 / 100 }
                    seconds = [max(0, duration - z.reduce(0, +))] + z
                }
                let ids = Repository.workoutHrDeviceIds(source: other.source, activeStrapId: activeStrap,
                                                        importedIds: imported)
                let samples = await repo.hrSamples(deviceIds: ids, from: other.startTs, to: other.endTs, limit: 20_000)
                if seconds == nil, samples.count >= 2 {
                    let tiz = HRZones.timeInZone(samples, zoneSet: zoneSet)
                    seconds = [tiz.belowZone1] + tiz.seconds
                }
                guard let s = seconds else { continue }
                let total = s.reduce(0, +)
                guard total > 0 else { continue }
                shares.append(s.map { $0 / total })
                highs.append(s[4] + s[5])
            }
            if shares.count >= 3 {
                for z in 0...5 {
                    let values = shares.map { $0[z] }.sorted()
                    let lo = Self.quantile(values, 0.25), hi = Self.quantile(values, 0.75)
                    out.typicalShares[z] = lo...max(lo, hi)
                }
                out.typicalHighZoneSeconds = Self.quantile(highs.sorted(), 0.5)
            }
            return out
        }
    }

    /// The lowest heart rate of each of this sport's sessions over the 30 days before this one (the
    /// recovery variant's MIN HR comparison), each from its own strap.
    func minHeartRates(before row: WorkoutRow, others: [WorkoutRow]) async -> [Int] {
        let key = "activity.minhr.\(row.sport.lowercased())|\(row.startTs)"
        return await cached(key) {
            let activeStrap = await repo.deviceId
            let imported = await repo.importedReadIds
            var out: [Int] = []
            for other in others.prefix(31) {
                let ids = Repository.workoutHrDeviceIds(source: other.source, activeStrapId: activeStrap,
                                                        importedIds: imported)
                let samples = await repo.hrSamples(deviceIds: ids, from: other.startTs, to: other.endTs, limit: 20_000)
                if let lowest = samples.map(\.bpm).min() { out.append(lowest) }
            }
            return out
        }
    }

    static func quantile(_ sorted: [Double], _ q: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let position = q * Double(sorted.count - 1)
        let lower = Int(position)
        let upper = min(lower + 1, sorted.count - 1)
        return sorted[lower] + (position - Double(lower)) * (sorted[upper] - sorted[lower])
    }

    static func mean(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    // MARK: Steps, route, lift

    /// Steps over an on-foot session: the row's own count (an import), else the strap's counter once it has
    /// offloaded the window, else the phone's pedometer; nil for other sports or when nothing counted.
    func activitySteps(for row: WorkoutRow, inputs: ActivityBuildInputs) async -> Int? {
        guard WorkoutCatalog.isOnFoot(row.sport) else { return nil }
        if let steps = row.steps, steps > 0 { return steps }
        if let ticks = await repo.strapStepTicks(from: row.startTs, to: row.endTs) {
            let scaled = Int((Double(ticks) / max(inputs.stepTicksPerStep, 0.5)).rounded())
            if scaled > 0 { return scaled }
        }
        if let phone = await WorkoutPedometer.steps(fromSec: row.startTs, toSec: row.endTs), phone > 0 { return phone }
        return nil
    }

    static func routeSummary(for row: WorkoutRow, duration: Double, imperial: Bool) -> ActivityRouteSummary? {
        guard let stored = RouteStore.load(startTs: row.startTs, sport: row.sport) else { return nil }
        let points = RouteMath.decode(stored.polyline)
        guard points.count >= 2 else { return nil }
        let system: UnitSystem = imperial ? .imperial : .metric
        let meters = row.distanceM ?? stored.distanceM
        let km = meters / 1000
        let shown = imperial ? km * UnitFormatter.milesPerKilometer : km
        let distanceUnit = UnitFormatter.distanceUnit(system)
        let hours = duration / 3600
        let isRide = ["cycl", "bike", "ride", "skat", "ski", "snowboard", "kayak", "sail", "paddle"]
            .contains { row.sport.lowercased().contains($0) }
        let rate: (String, String)
        if isRide {
            let speed = hours > 0 ? shown / hours : 0
            rate = (PulseFormat.oneDecimal(speed), imperial ? "mph" : "km/h")
        } else {
            let perUnit = shown > 0 ? duration / shown : 0
            let total = Int(perUnit.rounded())
            rate = (String(format: "%d:%02d", total / 60, total % 60), "/\(distanceUnit)")
        }
        let origin = WorkoutSource.classify(row.source)
        let recorded = origin == .manual || origin == .detected
        return ActivityRouteSummary(points: points.map { .init(lat: $0.lat, lon: $0.lon) },
                                    distance: (PulseFormat.oneDecimal(shown), distanceUnit),
                                    rateTitle: isRide ? String(localized: "Speed") : String(localized: "Pace"),
                                    rate: rate,
                                    duration: ActivityFormat.clock(seconds: duration),
                                    recordedOnDevice: recorded)
    }

    /// The Lift Log session paired with this workout (same start and sport), summarised: exercises, working
    /// sets, reps, tonnage (working sets only) and each exercise's best set by estimated 1RM.
    func liftSummary(for row: WorkoutRow, inputs: ActivityBuildInputs) async -> ActivityLiftSummary? {
        guard let store = await repo.storeHandle() else { return nil }
        let owner = await repo.deviceId
        guard let sessions = try? await store.liftSessions(deviceId: owner, fromTs: row.startTs, toTs: row.startTs),
              let session = sessions.first(where: { $0.sport.caseInsensitiveCompare(row.sport) == .orderedSame }),
              let sets = try? await store.liftSets(sessionId: session.id), !sets.isEmpty
        else { return nil }
        let system: UnitSystem = inputs.massImperial ? .imperial : .metric
        let unit = UnitFormatter.massUnit(system)
        func mass(_ kg: Double) -> String {
            PulseFormat.grouped(inputs.massImperial ? UnitFormatter.kgToPounds(kg) : kg)
        }
        let performed = sets.filter { LiftMetrics.isPerformed(reps: $0.reps) }
        let working = performed.filter { !$0.isWarmup }
        let exercises = LiftMetrics.perExercise(sets).map { e in
            ActivityLiftSummary.Exercise(
                name: e.exercise, workingSets: e.workingSets,
                bestSet: e.bestWeightKg.flatMap { w in e.bestReps.map { "\(mass(w)) \(unit) × \($0)" } },
                estimatedOneRepMax: e.bestEstimatedOneRepMaxKg.map { "\(mass($0)) \(unit)" })
        }
        return ActivityLiftSummary(sessionId: session.id, exercises: exercises, workingSets: working.count,
                                   totalReps: working.compactMap(\.reps).reduce(0, +),
                                   tonnage: LiftMetrics.volumeLoadKg(sets).map(mass), massUnit: unit,
                                   programName: session.programName)
    }

    // MARK: Key statistics

    static func keyStats(row: WorkoutRow, variant: ActivityDetailSnapshot.Variant, duration: Double, steps: Int?,
                         minHR: Int?, others: [WorkoutRow], historyMinHR: [Int],
                         inputs: ActivityBuildInputs) -> [ActivityKeyStat] {
        var out: [ActivityKeyStat] = []
        func stat(_ id: String, _ title: String, _ icon: String, value: Double?, unit: String,
                  text: (Double) -> String, average: Double?) {
            guard let value else { return }
            let shown = text(value)
            var direction: PulseTrend.Direction?
            var averageText: String?
            var spoken: String?
            if let average {
                let avg = text(average)
                averageText = avg + unit
                direction = shown == avg ? .flat : (value > average ? .up : .down)
                spoken = direction == .flat
                    ? String(localized: "the same as your 30-day average")
                    : (direction == .up ? String(localized: "above your 30-day average of \(avg) \(unit)")
                                        : String(localized: "below your 30-day average of \(avg) \(unit)"))
            }
            out.append(ActivityKeyStat(id: id, title: title, icon: icon, value: shown, unit: unit,
                                       average: averageText, direction: direction, accessibilityComparison: spoken))
        }
        let cals = String(localized: "cals")
        let bpm = String(localized: "bpm")
        func avg(_ f: (WorkoutRow) -> Double?) -> Double? { mean(others.compactMap(f)) }

        if variant == .recovery {
            stat("min-hr", String(localized: "Min HR"), "arrow.down.heart", value: minHR.map(Double.init), unit: bpm,
                 text: PulseFormat.whole, average: mean(historyMinHR.map(Double.init)))
            stat("avg-hr", String(localized: "Avg HR"), "heart", value: row.avgHr.map(Double.init), unit: bpm,
                 text: PulseFormat.whole, average: avg { $0.avgHr.map(Double.init) })
            stat("max-hr", String(localized: "Max HR"), "arrow.up.heart", value: row.maxHr.map(Double.init), unit: bpm,
                 text: PulseFormat.whole, average: avg { $0.maxHr.map(Double.init) })
            return out
        }
        if variant == .strength {
            stat("duration", String(localized: "Duration"), "stopwatch", value: duration > 0 ? duration : nil, unit: "",
                 text: { ActivityFormat.clock(seconds: $0) },
                 average: avg { $0.durationS ?? Double(max($0.endTs - $0.startTs, 0)) })
        }
        stat("calories", String(localized: "Calories"), "flame", value: row.energyKcal, unit: cals,
             text: PulseFormat.grouped, average: avg(\.energyKcal))
        stat("avg-hr", String(localized: "Avg HR"), "heart", value: row.avgHr.map(Double.init), unit: bpm,
             text: PulseFormat.whole, average: avg { $0.avgHr.map(Double.init) })
        stat("max-hr", String(localized: "Max HR"), "arrow.up.heart", value: row.maxHr.map(Double.init), unit: bpm,
             text: PulseFormat.whole, average: avg { $0.maxHr.map(Double.init) })
        if variant == .strain {
            stat("duration", String(localized: "Duration"), "stopwatch", value: duration > 0 ? duration : nil, unit: "",
                 text: { ActivityFormat.clock(seconds: $0) },
                 average: avg { $0.durationS ?? Double(max($0.endTs - $0.startTs, 0)) })
        }
        if let steps {
            stat("steps", String(localized: "Steps"), "figure.walk", value: Double(steps), unit: "",
                 text: PulseFormat.grouped, average: nil)
        }
        if let meters = row.distanceM, meters > 0 {
            let factor = inputs.distanceImperial ? UnitFormatter.milesPerKilometer / 1000 : 1.0 / 1000
            let unit = UnitFormatter.distanceUnit(inputs.distanceImperial ? .imperial : .metric)
            stat("distance", String(localized: "Distance"), "point.topleft.down.to.point.bottomright.curvepath",
                 value: meters * factor, unit: unit, text: PulseFormat.oneDecimal,
                 average: avg { $0.distanceM.map { $0 * factor } })
        }
        return out
    }

    // MARK: Words

    static func sourceChip(_ source: String) -> String? {
        switch WorkoutSource.classify(source) {
        case .manual: return nil
        case .detected: return String(localized: "Auto-detected")
        case .apple: return String(localized: "Via Apple Health")
        case .activityFile: return String(localized: "Via activity file")
        case .whoop, .lifting: return String(localized: "Imported")
        }
    }

    /// One local sentence about the activity, from its own numbers (the Coach writes its own when set up).
    static func insight(row: WorkoutRow, variant: ActivityDetailSnapshot.Variant, zoneSeconds: [Double],
                        hasZones: Bool, typicalHighZoneSeconds: Double?, duration: Double,
                        durationAverage: Double?, lift: ActivityLiftSummary?) -> String? {
        let sport = WorkoutSource.displaySport(row.sport)
        switch variant {
        case .recovery:
            let minutes = Int((duration / 60).rounded())
            guard let durationAverage, durationAverage > 0 else {
                return String(localized: "Recovery activities are low-intensity activities that promote blood flow to the muscles to help you recover from strain, fatigue, or sore muscles.")
            }
            let previous = Int((durationAverage / 60).rounded())
            if minutes == previous {
                return String(localized: "You spent \(minutes) minutes on this activity. This is consistent with your previous average of \(previous) minutes.")
            }
            return minutes > previous
                ? String(localized: "You spent \(minutes) minutes on this activity. This is longer than your previous average of \(previous) minutes.")
                : String(localized: "You spent \(minutes) minutes on this activity. This is shorter than your previous average of \(previous) minutes.")
        case .strength:
            if let lift, let tonnage = lift.tonnage {
                return String(localized: "You lifted **\(tonnage) \(lift.massUnit)** across **\(lift.exercises.count) exercises** and **\(lift.totalReps) reps**.")
            }
            fallthrough
        case .strain:
            guard hasZones else { return nil }
            let high = Int(((zoneSeconds[4] + zoneSeconds[5]) / 60).rounded())
            let usual = typicalHighZoneSeconds.map { Int(($0 / 60).rounded()) }
            if high == 0 {
                // Nothing in the top zones: say where the time went instead of "0 min".
                let top = (0...3).max { zoneSeconds[$0] < zoneSeconds[$1] } ?? 0
                let minutes = Int((zoneSeconds[top] / 60).rounded())
                if let usual, usual > 0 {
                    return String(localized: "Most of this activity was in Zone \(top) (**\(minutes) min**). You stayed out of Zones 4-5, where you typically spend \(usual) min during \(sport).")
                }
                return String(localized: "Most of this activity was in Zone \(top) (**\(minutes) min**).")
            }
            if let usual, high > usual {
                return String(localized: "You spent **\(high) min** in Zones 4-5, \(high - usual) more than you typically do during \(sport).")
            }
            if let usual, high < usual {
                return String(localized: "You spent **\(high) min** in Zones 4-5, \(usual - high) less than you typically do during \(sport).")
            }
            let mid = Int(((zoneSeconds[1] + zoneSeconds[2] + zoneSeconds[3]) / 60).rounded())
            return String(localized: "You spent **\(high) min** in Zones 4-5 and **\(mid) min** in Zones 1-3.")
        }
    }

    // MARK: - Start Activity (§3.8)

    /// Today's Recovery, Strain and optimal range for the pre-start screen's Strain Target, through the
    /// same resolvers as Home's dials (so the panel and the dials can never disagree).
    func startActivity(_ r: PulseRequest) async -> StartActivitySnapshot? {
        begin(r.seq)
        let row = displayRow(r)
        let (charge, _) = chargeDisplay(r, row: row)
        let window = await dayWindow(r)
        let hr = await heartRate(dayKey: r.day.key, from: window.from, to: window.to, isToday: true)
        guard isCurrent(r) else { return nil }
        let strain = strainValue(r, row: row, hr: hr)
        let target = strainTarget(charge, strain: strain, isToday: true)
        let percent = charge.pct.map { PulseDisplay.displayedPercent($0) }
        let carried: Bool
        if case .carried = charge { carried = true } else { carried = false }
        let midpoint = target.map { ($0.range.lowerBound + $0.range.upperBound) / 2 }
        return StartActivitySnapshot(
            seq: r.seq, recoveryPercent: percent,
            recoveryBand: percent.map { PulseDisplay.recoveryBand(percent: Double($0)) },
            recoveryCarried: carried, dayStrain: strain, optimalRange: target?.range, targetDayStrain: midpoint,
            denominator: StrainScorer.logMapDenominator(method: r.prefs.effortMethod, sex: r.profile.sex))
    }
}
#endif
