import Foundation
import StrandAnalytics
import WhoopStore

/// The iPhone pedometer's running total for the day in progress, as the live stream last reported it.
struct LivePhoneSteps: Equatable, Sendable {
    let day: String
    let steps: Int
    let distanceM: Double?
    let floorsUp: Int?
}

/// Everything a window of days knows about steps, gathered once so the resolver sees every source side by
/// side. Days with no reading from any source are simply absent.
struct StepsInputs: Equatable, Sendable {
    var candidates: [String: StepDayCandidates] = [:]
    /// Distance (metres) and floors climbed per day. Only the iPhone pedometer reports these, so they are
    /// shown beside whichever source won the day's COUNT rather than resolved with it.
    var distanceM: [String: Double] = [:]
    var floorsUp: [String: Int] = [:]
    /// The stored source id behind each strap-side day (the active strap, the canonical import or its
    /// computed sibling), so the combined Explore detail can still name exactly where a value came from.
    var strapCounterSourceId: [String: String] = [:]
    var strapEstimateSourceId: [String: String] = [:]
    /// What the band adds to each clock hour of a day the phone missed hours of (24 values), the per-hour
    /// split of that day's `StepDayCandidates.bandFill`. Kept beside it so the hour chart draws exactly the
    /// steps the total includes.
    var bandFillHours: [String: [Int]] = [:]

    /// Resolve every day through THE resolver. `inProgressDay` is the device's local today.
    func resolved(inProgressDay: String?) -> [ResolvedStepDay] {
        StepsResolver.resolve(candidates, inProgressDay: inProgressDay)
    }

    /// The raw source id a resolved day came from, in the vocabulary `TodayView.provenanceDisplayLabel`
    /// already speaks ("apple-health", a strap id, its "-noop" sibling) plus the phone's own id, with
    /// `StepsPrefs.bandFillSourceSuffix` when the band filled hours the phone missed. Main-actor because the
    /// canonical ids are `Repository` statics.
    @MainActor
    func provenanceId(for day: ResolvedStepDay) -> String {
        let base: String
        switch day.source {
        case .healthKit: base = Repository.appleHealthSource
        case .phonePedometer: base = StepsPrefs.phoneDeviceId
        case .strapCounter: base = strapCounterSourceId[day.day] ?? Repository.whoopSource
        case .strapEstimate: base = strapEstimateSourceId[day.day] ?? Repository.whoopSource + "-noop"
        }
        return day.bandSteps > 0 ? base + StepsPrefs.bandFillSourceSuffix : base
    }

    /// Fold the live pedometer total into its day. The larger of the stored and live figures wins: both are
    /// running totals of the same day from the same coprocessor, so the larger one is simply the fresher.
    mutating func foldLivePhone(_ live: LivePhoneSteps) {
        var day = candidates[live.day] ?? StepDayCandidates()
        day.phonePedometer = max(day.phonePedometer ?? live.steps, live.steps)
        candidates[live.day] = day
        if let d = live.distanceM { distanceM[live.day] = max(distanceM[live.day] ?? d, d) }
        if let f = live.floorsUp { floorsUp[live.day] = max(floorsUp[live.day] ?? f, f) }
    }

    /// Replace every day in `from...to` with `newer`'s view of it, keeping the rest. Used to refresh the
    /// last few days after a backfill without re-reading a year.
    mutating func replacing(from: String, to: String, with newer: StepsInputs) {
        func inRange(_ day: String) -> Bool { day >= from && day <= to }
        candidates = candidates.filter { !inRange($0.key) }.merging(newer.candidates.filter { inRange($0.key) }) { $1 }
        distanceM = distanceM.filter { !inRange($0.key) }.merging(newer.distanceM.filter { inRange($0.key) }) { $1 }
        floorsUp = floorsUp.filter { !inRange($0.key) }.merging(newer.floorsUp.filter { inRange($0.key) }) { $1 }
        strapCounterSourceId = strapCounterSourceId.filter { !inRange($0.key) }
            .merging(newer.strapCounterSourceId.filter { inRange($0.key) }) { $1 }
        strapEstimateSourceId = strapEstimateSourceId.filter { !inRange($0.key) }
            .merging(newer.strapEstimateSourceId.filter { inRange($0.key) }) { $1 }
        bandFillHours = bandFillHours.filter { !inRange($0.key) }
            .merging(newer.bandFillHours.filter { inRange($0.key) }) { $1 }
    }

    /// A stored step value as a count: finite, non-negative and below a sanity ceiling no day reaches
    /// (converting an absurd Double to Int would trap).
    static func count(_ value: Double) -> Int? {
        guard value.isFinite, value >= 0, value < 10_000_000 else { return nil }
        return Int(value.rounded())
    }
}

extension Repository {

    /// THE gather behind every steps surface: Apple Health's daily count, the iPhone pedometer's banked
    /// totals (plus the live running total for today), the strap counter and the strap estimate, for every
    /// day in `from...to`. The strap sides go through `resolvedSeries`, the same reads the metric details
    /// use, so a strap figure here is the one those screens show.
    func stepInputs(from: String, to: String) async -> StepsInputs {
        guard let store = await storeHandle() else { return StepsInputs() }
        let phone = StepsPrefs.phoneDeviceId
        async let appleRows = store.appleDaily(deviceId: Self.appleHealthSource, from: from, to: to)
        async let phoneSteps = store.metricSeries(deviceId: phone, key: StepsPrefs.phoneStepsKey, from: from, to: to)
        async let phoneDistance = store.metricSeries(deviceId: phone, key: StepsPrefs.phoneDistanceKey, from: from, to: to)
        async let phoneFloors = store.metricSeries(deviceId: phone, key: StepsPrefs.phoneFloorsKey, from: from, to: to)
        async let counter = resolvedSeries(key: "steps", source: Self.whoopSource, from: from, to: to)
        async let estimate = resolvedSeries(key: "steps_est", source: Self.whoopSource, from: from, to: to)

        var inputs = StepsInputs()
        for row in (try? await appleRows) ?? [] {
            if let steps = row.steps { inputs.candidates[row.day, default: StepDayCandidates()].healthKit = steps }
        }
        for point in (try? await phoneSteps) ?? [] {
            inputs.candidates[point.day, default: StepDayCandidates()].phonePedometer = StepsInputs.count(point.value)
        }
        for point in (try? await phoneDistance) ?? [] where point.value.isFinite && point.value >= 0 {
            inputs.distanceM[point.day] = point.value
        }
        for point in (try? await phoneFloors) ?? [] {
            if let floors = StepsInputs.count(point.value) { inputs.floorsUp[point.day] = floors }
        }
        for point in await counter.points {
            inputs.candidates[point.day, default: StepDayCandidates()].strapCounter = StepsInputs.count(point.value)
            inputs.strapCounterSourceId[point.day] = point.source
        }
        for point in await estimate.points {
            inputs.candidates[point.day, default: StepDayCandidates()].strapEstimate = StepsInputs.count(point.value)
            inputs.strapEstimateSourceId[point.day] = point.source
        }
        // The band's estimate for the hours the phone missed. Only a day something already counted takes it;
        // the resolver then adds it to a phone-side day and ignores it on any other.
        if StepsPrefs.bandFillEnabled {
            for (day, added) in await bandFillByDay(store: store, from: from, to: to) where inputs.candidates[day] != nil {
                inputs.candidates[day]?.bandFill = added.reduce(0, +)
                inputs.bandFillHours[day] = added
            }
        }
        if let live = StepsService.shared.livePhone, live.day >= from, live.day <= to {
            inputs.foldLivePhone(live)
        }
        return inputs
    }

    /// The window's inputs and the days they resolve to, oldest first.
    func resolvedStepDays(from: String, to: String) async -> (inputs: StepsInputs, days: [ResolvedStepDay]) {
        let inputs = await stepInputs(from: from, to: to)
        return (inputs, inputs.resolved(inProgressDay: Self.localDayKey(Date())))
    }

    /// One day's resolved count, or nil when nothing counted it.
    func resolvedStepDay(_ day: String) async -> ResolvedStepDay? {
        await resolvedStepDays(from: day, to: day).days.first
    }

    /// The combined daily steps series (the rolling-average card and Explore's combined Steps detail),
    /// resolved by the ONE steps resolver. Each point names the stored source that supplied it, so the
    /// readings table can say "Apple Health" for one day and "iPhone" for the next.
    func resolvedSteps(from: String, to: String) async -> MetricSeriesResolution {
        let (inputs, days) = await resolvedStepDays(from: from, to: to)
        let points = days.map { day in
            ResolvedMetricPoint(day: day.day, value: Double(day.steps), source: inputs.provenanceId(for: day),
                                sourceKey: day.source == .strapEstimate ? "steps_est" : "steps")
        }
        return MetricSeriesResolution(requestedSource: Self.whoopSource, candidates: Self.stepSourceCandidates,
                                      points: points)
    }

    /// The (source, key) pairs the steps resolver consults, in its precedence order.
    static let stepSourceCandidates: [MetricSourceCandidate] = [
        MetricSourceCandidate(source: appleHealthSource, key: "steps"),
        MetricSourceCandidate(source: StepsPrefs.phoneDeviceId, key: StepsPrefs.phoneStepsKey),
        MetricSourceCandidate(source: whoopSource, key: "steps"),
        MetricSourceCandidate(source: whoopSource + "-noop", key: "steps_est"),
    ]

    /// Hour buckets for `day` from every source that banks hours (Apple Health's bridge, the iPhone
    /// pedometer, and the band's hourly estimate under `.strapEstimate`). Hours are real instants, bucketed in
    /// the device's zone: the wearer's own clock.
    func stepHours(day: String, calendar: Calendar = .current) async -> [StepSource: [Int]] {
        guard let bounds = StepsHourly.dayBounds(day: day, calendar: calendar),
              let store = await storeHandle() else { return [:] }
        async let health = store.appleStepHours(deviceId: Self.appleHealthSource,
                                                fromTs: bounds.start, toTs: bounds.end - 1)
        async let phone = store.appleStepHours(deviceId: StepsPrefs.phoneDeviceId,
                                               fromTs: bounds.start, toTs: bounds.end - 1)
        var out: [StepSource: [Int]] = [:]
        let healthRows = (try? await health) ?? []
        if !healthRows.isEmpty { out[.healthKit] = StepsHourly.buckets(rows: healthRows, day: day, calendar: calendar) }
        let phoneRows = (try? await phone) ?? []
        if !phoneRows.isEmpty { out[.phonePedometer] = StepsHourly.buckets(rows: phoneRows, day: day, calendar: calendar) }
        let bandRows = await bandHourRows(store: store, fromTs: bounds.start, toTs: bounds.end - 1)
        if !bandRows.isEmpty { out[.strapEstimate] = StepsHourly.buckets(rows: bandRows, day: day, calendar: calendar) }
        return out
    }

    /// What the band adds to each clock hour of every day in `from...to` it adds to (`StepsHourMerge`), from
    /// the band's hourly estimate and the phone's and Apple Health's hours. Only hours the phone side has
    /// finished counting take anything.
    func bandFillByDay(store: WhoopStore, from: String, to: String,
                       calendar: Calendar = .current) async -> [String: [Int]] {
        guard let start = StepsHourly.dayBounds(day: from, calendar: calendar)?.start,
              let end = StepsHourly.dayBounds(day: to, calendar: calendar)?.end else { return [:] }
        let band = await bandHourRows(store: store, fromTs: start, toTs: end - 1)
        guard let first = band.first?.ts, let last = band.last?.ts else { return [:] }
        async let health = store.appleStepHours(deviceId: Self.appleHealthSource, fromTs: first, toTs: last)
        async let phone = store.appleStepHours(deviceId: StepsPrefs.phoneDeviceId, fromTs: first, toTs: last)
        let todayStart = Int(calendar.startOfDay(for: Date()).timeIntervalSince1970)
        return StepsHourMerge.fillByDay(phoneRows: (try? await phone) ?? [], healthRows: (try? await health) ?? [],
                                        bandRows: band, calendar: calendar,
                                        settledUntil: StepsPrefs.phoneSideSettledUntil(todayStart: todayStart))
    }

    /// The band's hourly step estimate in `[fromTs, toTs]`, oldest first. The analysis pass writes it under the
    /// computed id; both computed ids the dashboard reads are tried, the active strap's first.
    func bandHourRows(store: WhoopStore, fromTs: Int, toTs: Int) async -> [(ts: Int, steps: Int)] {
        var byTs: [Int: Int] = [:]
        for id in computedReadIds {
            for row in (try? await store.appleStepHours(deviceId: id, fromTs: fromTs, toTs: toTs)) ?? []
            where byTs[row.ts] == nil {
                byTs[row.ts] = row.steps
            }
        }
        return byTs.keys.sorted().map { (ts: $0, steps: byTs[$0] ?? 0) }
    }
}

/// Writes for the iPhone pedometer's banked history. Static and store-level so the backfill can run off the
/// main actor with nothing but the store handle.
enum PhoneStepsStore {
    /// Upsert whole-day readings: steps always, distance and floors when the phone reported them.
    static func save(days: [(day: String, reading: PedometerReading)], to store: WhoopStore) async throws {
        var points: [MetricPoint] = []
        for (day, reading) in days {
            points.append(MetricPoint(day: day, key: StepsPrefs.phoneStepsKey, value: Double(reading.steps)))
            if let d = reading.distanceM { points.append(MetricPoint(day: day, key: StepsPrefs.phoneDistanceKey, value: d)) }
            if let f = reading.floorsUp { points.append(MetricPoint(day: day, key: StepsPrefs.phoneFloorsKey, value: Double(f))) }
        }
        guard !points.isEmpty else { return }
        try await store.upsertMetricSeries(points, deviceId: StepsPrefs.phoneDeviceId)
    }

    /// Upsert hour buckets (hour-start unix second, steps).
    static func save(hours: [(ts: Int, steps: Int)], to store: WhoopStore) async throws {
        guard !hours.isEmpty else { return }
        try await store.upsertAppleStepHours(hours, deviceId: StepsPrefs.phoneDeviceId)
    }

    /// Forget everything the phone banked. Apple Health's and the strap's rows are untouched.
    static func deleteAll(from store: WhoopStore) async throws {
        for key in [StepsPrefs.phoneStepsKey, StepsPrefs.phoneDistanceKey, StepsPrefs.phoneFloorsKey] {
            try await store.deleteMetricSeries(deviceId: StepsPrefs.phoneDeviceId, key: key)
        }
        try await store.deleteAppleStepHours(deviceId: StepsPrefs.phoneDeviceId)
    }
}
