import Foundation
import StrandAnalytics
import WhoopStore

/// The in-memory half of `StepsHourMotionCache`, kept across analysis passes, seeded once per process from
/// UserDefaults. The key is deliberately absent from the backup whitelists (see `StepsHourMotionCache`).
@MainActor
enum BandStepHoursCacheStore {
    static let defaultsKey = "analyzeRecent.stepsHourMotionCache.v1"
    static var entries: [String: StepsHourMotionCache.Entry] = [:]
    static var loaded = false
    /// The payload last read or written, so a pass that changed nothing skips the write.
    static var persisted = ""
}

/// The band's hourly step estimate (`StepsHourMerge`), refreshed by every analysis pass.
///
/// Each day of the calibration window has its stored motion split by clock hour (re-split only when that day's
/// gravity changed, reusing the daily fold's key). The steps-per-motion factor is then learned from the hours
/// the phone was clearly carried, and the band's estimate for every hour of the window is written to
/// `appleStepHour` under the computed id. The read side (`Repository.stepInputs`) merges those hours with the
/// phone's and Apple Health's, so a day the phone missed part of gets the band's estimate for exactly those
/// hours. Days the phone counted nothing at all take the sum of their band hours as their estimate, so their
/// hour chart adds up to their total.
extension IntelligenceEngine {

    struct BandStepHoursOutcome: Sendable {
        var cache: [String: StepsHourMotionCache.Entry]
        var calibration: StepsHourMerge.Calibration?
        var carriedHours: Int
        var usualRows: Int
        var hoursWritten: Int
        var estimateByDay: [String: Int]
        var reused: Int
        var split: Int
    }

    /// Refresh the band's hourly estimate. `dayWitness` is the daily motion cache after this pass's gather
    /// (`StepsMotionCache` entries by day); `estimateDays` are the scored days the phone counted nothing on,
    /// whose `steps_est` takes the band's hourly sum once the hourly fit exists.
    func refreshBandStepHours(store: WhoopStore, strapId: String, computedId: String, windowDays: Int,
                              nowLocalMidnight: Int, tzOffset: Int, now: Int,
                              dayWitness: [String: (key: String, motion: Double)],
                              passSleep: [CachedSleepSession], estimateDays: [String],
                              manualOverride: Double?, trace: Bool) async {
        if !BandStepHoursCacheStore.loaded {
            BandStepHoursCacheStore.loaded = true
            if let raw = UserDefaults.standard.string(forKey: BandStepHoursCacheStore.defaultsKey) {
                BandStepHoursCacheStore.entries = StepsHourMotionCache.deserialize(raw)
                BandStepHoursCacheStore.persisted = raw
            }
        }
        let inCache = BandStepHoursCacheStore.entries
        let settledUntil = StepsPrefs.phoneSideSettledUntil(todayStart: nowLocalMidnight)
        let windowStart = Self.midnightLocal(nowLocalMidnight - (windowDays - 1) * 86_400, offsetSec: tzOffset)
        let sleepFromPass = passSleep.map { (start: $0.effectiveStartTs, end: $0.endTs) }
        let healthId = Repository.appleHealthSource

        let outcome: BandStepHoursOutcome = await Task.detached(priority: .utility) {
            // 1. The band's motion per clock hour across the window.
            var cache = inCache
            var reused = 0
            var split = 0
            var hourly: [Int: StepsHourMerge.HourMotion] = [:]
            var window: Set<String> = []
            for off in 0..<windowDays {
                let dayMid = Self.midnightLocal(nowLocalMidnight - off * 86_400, offsetSec: tzOffset)
                let dayEnd = dayMid + 86_400 - 1
                let dayKey = AnalyticsEngine.dayString(dayMid, offsetSec: tzOffset)
                window.insert(dayKey)
                guard let witness = dayWitness[dayKey] else { continue }
                let hours: [Int: StepsHourMerge.HourMotion]
                if let cached = cache[dayKey], cached.key == witness.key {
                    hours = cached.hours
                    reused += 1
                } else {
                    guard let owner = StepsHourMotionCache.owner(fromCacheKey: witness.key),
                          let grav = try? await store.gravitySamples(deviceId: owner, from: dayMid, to: dayEnd,
                                                                     limit: 200_000) else { continue }
                    hours = StepsHourMerge.hourlyMotion(grav, offsetSec: tzOffset)
                    cache[dayKey] = (key: witness.key, hours: hours)
                    split += 1
                }
                for (hour, motion) in hours { hourly[hour] = motion }
            }
            cache = cache.filter { window.contains($0.key) }

            // 2. The phone side per hour: the larger of the iPhone's and Apple Health's count.
            var phone: [Int: Int] = [:]
            for id in [StepsPrefs.phoneDeviceId, healthId] {
                for row in (try? await store.appleStepHours(deviceId: id, fromTs: windowStart, toTs: now)) ?? [] {
                    let hour = StepsHourMerge.hourStart(row.ts, offsetSec: tzOffset)
                    phone[hour] = max(phone[hour] ?? 0, row.steps)
                }
            }

            // 3. Time the band's motion is not footfalls: sleep, and workouts with no footfalls.
            var blocked = sleepFromPass
            let storedSleep = (try? await store.sleepSessions(deviceId: computedId, from: windowStart - 86_400,
                                                              to: now, limit: 10_000)) ?? []
            blocked += storedSleep.map { (start: $0.effectiveStartTs, end: $0.endTs) }
            for id in [strapId, healthId] {
                let rows = (try? await store.workouts(deviceId: id, from: windowStart - 86_400, to: now,
                                                      limit: 100_000)) ?? []
                blocked += rows.filter { StepsHourMerge.isNoFootfallSport($0.sport) }
                    .map { (start: $0.startTs, end: $0.endTs) }
            }

            // 4. Learn the factor from carried hours the phone has finished counting.
            let usualRows = StepsHourMerge.usualRows(Array(hourly.values))
            let minRows = StepsHourMerge.minCarriedRows(usualRows: usualRows)
            var carried: [StepsHourMerge.CalibrationHour] = []
            var openFraction: [Int: Double] = [:]
            for (hour, motion) in hourly {
                let open = 1 - StepsHourMerge.coveredFraction(hourStart: hour, intervals: blocked)
                openFraction[hour] = open
                guard hour + 3_600 <= settledUntil else { continue }
                if StepsHourMerge.isCarried(phoneSteps: phone[hour] ?? 0, motion: motion, minRows: minRows,
                                            blockedFraction: 1 - open) {
                    carried.append(.init(motion: motion.motion, steps: Double(phone[hour] ?? 0)))
                }
            }
            let calibration = StepsHourMerge.calibrate(carried, manualOverride: manualOverride)

            // 5. The band's estimate for every hour, written under the computed id.
            var rows: [(ts: Int, steps: Int)] = []
            var estimateByDay: [String: Int] = [:]
            if let calibration {
                for hour in hourly.keys.sorted() {
                    guard let motion = hourly[hour] else { continue }
                    let steps = StepsHourMerge.estimate(motion: motion.motion, coefficient: calibration.coefficient,
                                                        openFraction: openFraction[hour] ?? 1)
                    guard steps > 0 else { continue }
                    rows.append((ts: hour, steps: steps))
                    estimateByDay[AnalyticsEngine.dayString(hour, offsetSec: tzOffset), default: 0] += steps
                }
            }
            // With no band motion in the window at all there is nothing to say about any hour, so the stored
            // hours are left as they are rather than cleared.
            var written = 0
            if !hourly.isEmpty {
                written = await Self.writeBandHours(rows, store: store, deviceId: computedId,
                                                    fromTs: windowStart, toTs: now)
            }
            return BandStepHoursOutcome(cache: cache, calibration: calibration, carriedHours: carried.count,
                                        usualRows: usualRows, hoursWritten: written,
                                        estimateByDay: estimateByDay, reused: reused, split: split)
        }.value

        BandStepHoursCacheStore.entries = outcome.cache
        let payload = StepsHourMotionCache.serialize(outcome.cache)
        if payload != BandStepHoursCacheStore.persisted {
            BandStepHoursCacheStore.persisted = payload
            UserDefaults.standard.set(payload, forKey: BandStepHoursCacheStore.defaultsKey)
        }

        // The calibration sheet's read-out.
        let defaults = UserDefaults.standard
        defaults.set(outcome.calibration?.coefficient ?? 0, forKey: StepsPrefs.bandHourCoefficientKey)
        defaults.set(outcome.calibration?.sampleHours ?? outcome.carriedHours, forKey: StepsPrefs.bandHourSampleHoursKey)
        defaults.set(outcome.calibration?.confidence ?? 0, forKey: StepsPrefs.bandHourConfidenceKey)

        // A day the phone counted nothing takes the sum of its band hours, so its chart adds up to its total.
        if outcome.calibration != nil {
            let points = estimateDays.compactMap { day -> MetricPoint? in
                guard let steps = outcome.estimateByDay[day], steps > 0 else { return nil }
                return MetricPoint(day: day, key: "steps_est", value: Double(steps))
            }
            if !points.isEmpty { _ = try? await store.upsertMetricSeries(points, deviceId: computedId) }
        }

        diagnosticSink?("analyzeRecent stepsHours reused=\(outcome.reused)/\(outcome.reused + outcome.split) "
            + "written=\(outcome.hoursWritten)", nil)
        if trace {
            let cal = outcome.calibration
            diagnosticSink?("stepsHourCal carried=\(outcome.carriedHours) usualRows=\(outcome.usualRows) "
                + "k=\(cal.map { String(format: "%.2f", $0.coefficient) } ?? "none") "
                + "confidence=\(cal.map { String(format: "%.2f", $0.confidence) } ?? "none") "
                + "manual=\(cal?.manual ?? false)", .steps)
            for day in estimateDays.sorted() {
                guard let steps = outcome.estimateByDay[day] else { continue }
                diagnosticSink?("stepsHourEst day=\(day) steps=\(steps) (band hours)", .steps)
            }
        }
    }

    /// Replace the band's hourly rows in `[fromTs, toTs]` with `rows`, writing only what changed. Returns
    /// how many rows were written.
    nonisolated static func writeBandHours(_ rows: [(ts: Int, steps: Int)], store: WhoopStore, deviceId: String,
                                           fromTs: Int, toTs: Int) async -> Int {
        let existing = (try? await store.appleStepHours(deviceId: deviceId, fromTs: fromTs, toTs: toTs)) ?? []
        var old: [Int: Int] = [:]
        for row in existing { old[row.ts] = row.steps }
        var fresh: [Int: Int] = [:]
        for row in rows { fresh[row.ts] = row.steps }
        if old.keys.contains(where: { fresh[$0] == nil }) {
            _ = try? await store.deleteAppleStepHours(deviceId: deviceId, fromTs: fromTs, toTs: toTs)
            guard !rows.isEmpty else { return 0 }
            return (try? await store.upsertAppleStepHours(rows, deviceId: deviceId)) ?? 0
        }
        let changed = rows.filter { old[$0.ts] != $0.steps }
        guard !changed.isEmpty else { return 0 }
        return (try? await store.upsertAppleStepHours(changed, deviceId: deviceId)) ?? 0
    }
}
