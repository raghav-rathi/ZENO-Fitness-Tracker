import Foundation
import WhoopStore
import StrandAnalytics

// MARK: - Menstrual cycle tracker storage
//
// A logged period start is one value-1 metricSeries point under the dedicated local source
// `noop-cycle`. The source is intentionally separate from strap/import/computed ids so an import or
// re-analysis cannot overwrite sensitive user-entered history. This is the byte-parity twin of Android
// `CycleTrackingStore`: same source id, key, value, local ISO day, ordering, and real-delete semantics.
// No schema change is needed and no data leaves the device.

enum CycleTrackingStore {
    static let sourceId = "noop-cycle"
    static let periodStartKey = "period_start"
    /// A day's logged flow (0 no flow, 1 spotting, 2 light, 3 medium, 4 heavy), which the iPhone's Menstrual
    /// Cycle Insights writes under this same source (`PulseCycleLog.flowKey`). Android reads starts only.
    static let periodFlowKey = "period_flow"
    static let loggedValue = 1.0
    static let earliestDay = "0000-01-01"
    static let latestDay = "9999-12-31"
}

extension Repository {

    /// Logged period-start days, oldest first. A value gate makes reads forward-compatible if another
    /// cycle event kind is ever projected into this source.
    func periodStarts(from: String = CycleTrackingStore.earliestDay,
                      to: String = CycleTrackingStore.latestDay) async -> [String] {
        guard let store = await storeHandle() else { return [] }
        let rows = (try? await store.metricSeries(deviceId: CycleTrackingStore.sourceId,
                                                  key: CycleTrackingStore.periodStartKey,
                                                  from: from, to: to)) ?? []
        return rows.filter { $0.value >= CycleTrackingStore.loggedValue }.map(\.day)
    }

    /// Log (or idempotently re-log) one local calendar day as cycle day 1.
    func logPeriodStart(day: String) async {
        guard let store = await storeHandle() else { return }
        _ = try? await store.upsertMetricSeries(
            [MetricPoint(day: day, key: CycleTrackingStore.periodStartKey,
                         value: CycleTrackingStore.loggedValue)],
            deviceId: CycleTrackingStore.sourceId)
        noteCycleTrackingChanged()
    }

    /// Remove one logged start. This is a physical row delete, not a zero/sentinel marker.
    func deletePeriodStart(day: String) async {
        guard let store = await storeHandle() else { return }
        _ = try? await store.deleteMetricSeriesPoint(deviceId: CycleTrackingStore.sourceId,
                                                      day: day,
                                                      key: CycleTrackingStore.periodStartKey)
        noteCycleTrackingChanged()
    }

    /// Remove one logged start together with the period it opened: the period-flow days (light or
    /// heavier) in the `MenstrualCycleModel.periodRunMaxDays` from `day` that no other logged start still
    /// covers. Deleting the start alone left those days behind, flow with no period to belong to (the
    /// cycle page hides such a day, but it would outlive the delete in every backup). Spotting, "no flow"
    /// and symptoms stay: they are not the period's, and a symptom log stands on its own.
    func deletePeriod(startingOn day: String) async {
        guard let store = await storeHandle() else { return }
        let maxRun = MenstrualCycleModel.periodRunMaxDays
        let rows = (try? await store.metricSeries(
            deviceId: CycleTrackingStore.sourceId,
            keys: [CycleTrackingStore.periodStartKey, CycleTrackingStore.periodFlowKey],
            from: MenstrualCycleModel.shift(day, by: -(maxRun - 1)) ?? day,
            to: MenstrualCycleModel.shift(day, by: maxRun - 1) ?? day)) ?? []
        _ = try? await store.deleteMetricSeriesPoint(deviceId: CycleTrackingStore.sourceId, day: day,
                                                      key: CycleTrackingStore.periodStartKey)
        let otherStarts = rows.filter {
            $0.key == CycleTrackingStore.periodStartKey && $0.value >= CycleTrackingStore.loggedValue && $0.day != day
        }.map(\.day)
        func within(_ start: String, _ flowDay: String) -> Bool {
            start <= flowDay && (MenstrualCycleModel.days(from: start, to: flowDay) ?? .max) < maxRun
        }
        for row in rows where row.key == CycleTrackingStore.periodFlowKey && within(day, row.day) {
            guard MenstrualCycleModel.Flow(rawValue: Int(row.value.rounded()))?.isPeriod == true,
                  !otherStarts.contains(where: { within($0, row.day) }) else { continue }
            _ = try? await store.deleteMetricSeriesPoint(deviceId: CycleTrackingStore.sourceId, day: row.day,
                                                          key: CycleTrackingStore.periodFlowKey)
        }
        noteCycleTrackingChanged()
    }

    /// Delete every logged period start after an explicit user confirmation.
    func deleteAllPeriodStarts() async {
        guard let store = await storeHandle() else { return }
        _ = try? await store.deleteMetricSeries(deviceId: CycleTrackingStore.sourceId,
                                                 key: CycleTrackingStore.periodStartKey)
        noteCycleTrackingChanged()
    }
}
