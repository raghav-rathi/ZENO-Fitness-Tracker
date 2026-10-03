#if os(iOS)
import Foundation
import WhoopStore
import StrandAnalytics

// MARK: - Cycle logs (WHOOP_UI_SPEC §3.24 "Symptoms sheet", [Z] "Add a symptoms and flow log")
//
// The classic tracker stores one thing: a period-start day, as a value-1 metric point under the dedicated
// local source `noop-cycle` (`CycleTrackingStore`), which no import or re-analysis can overwrite. Menstrual
// Cycle Insights adds the day's flow and symptoms to the SAME source, under their own keys, so they get the
// same protections, ride the same backup and are deleted with the same "delete cycle data":
//
//   period_flow        one point per day: 0 no flow, 1 spotting, 2 light, 3 medium, 4 heavy
//   symptom_<id>       one value-1 point per day the symptom was logged (a real delete clears it)
//
// The period START stays the anchor the temperature engine cross-validates against. Logging flow keeps it
// in step: a period day with no start in the 10 days before it becomes a start, one just before the
// current start moves the start back, and clearing the flow on a start day moves the start to the next
// flow day or removes it. So every period-flow day written here has a start at most 9 days before it, and a
// period-flow day without one can only be left over from the classic tracker's deletes, which remove
// starts alone ("Delete all period history" and its per-start delete in `SkinTempCardsView`). Reading
// ignores such a left-over day, so a period the wearer deleted is never drawn again; its symptoms stay,
// because symptoms are not period history and a symptom-only log is legitimate (menopause, or before the
// first period is logged). Nothing here leaves the device.
//
// Android parity: the Android twin of `CycleTrackingStore` reads `period_start` only. A `.noopbak` restored
// on Android carries these rows untouched (the source is backed up whole) but shows period starts only,
// until Android reads `period_flow` and `symptom_<id>` the same way.
enum PulseCycleLog {
    static let flowKey = "period_flow"
    static let symptomPrefix = "symptom_"

    /// The page's mode (§3.24 Settings, [Z] perimenopause and menopause).
    enum Mode: String, CaseIterable, Identifiable {
        case menstruating, perimenopause, menopause

        static let storageKey = "pulse.cycle.mode"
        var id: String { rawValue }

        var title: String {
            switch self {
            case .menstruating: return String(localized: "Menstruating")
            case .perimenopause: return String(localized: "Perimenopause")
            case .menopause: return String(localized: "Menopause")
            }
        }

        var detail: String {
            switch self {
            case .menstruating:
                return String(localized: "Phases, period predictions and symptom patterns from your logged cycles.")
            case .perimenopause:
                return String(localized: "Cycles can become irregular, so predictions use wider windows.")
            case .menopause:
                return String(localized: "No period predictions. Log symptoms and any bleeding to see your patterns.")
            }
        }
    }

    /// Contraception changes what the phases mean: with hormonal contraception there is no natural cycle,
    /// so only the bleeding the wearer logs is laid out, and nothing is predicted.
    enum Contraception: String, CaseIterable, Identifiable {
        case none, hormonal, nonHormonal

        static let storageKey = "pulse.cycle.contraception"
        var id: String { rawValue }

        var title: String {
            switch self {
            case .none: return String(localized: "None")
            case .hormonal: return String(localized: "Hormonal")
            case .nonHormonal: return String(localized: "Non-hormonal")
            }
        }

        var detail: String {
            switch self {
            case .none: return String(localized: "No contraception, or none that affects your cycle.")
            case .hormonal: return String(localized: "Pill, patch, ring, implant, injection or hormonal IUD.")
            case .nonHormonal: return String(localized: "Copper IUD, barrier methods or none of the above.")
            }
        }
    }

    /// Whether phases apply in `mode` with `contraception`.
    static func phasesApply(mode: Mode, contraception: Contraception) -> Bool {
        mode != .menopause && contraception != .hormonal
    }

    /// Whether anything is predicted (a next-period window, an expected bleed, symptoms by cycle day). Not
    /// where there is no natural cycle: in menopause and under hormonal contraception, whose withdrawal or
    /// breakthrough bleeding no logged cycle can forecast.
    static func predicts(mode: Mode, contraception: Contraception) -> Bool {
        phasesApply(mode: mode, contraception: contraception)
    }

    /// A loggable symptom.
    struct Symptom: Identifiable, Hashable {
        let id: String
        let title: String
        let group: Group
    }

    enum Group: String, CaseIterable, Identifiable {
        case pain, body, mood, sleepEnergy
        var id: String { rawValue }

        var title: String {
            switch self {
            case .pain: return String(localized: "Pain")
            case .body: return String(localized: "Body")
            case .mood: return String(localized: "Mood")
            case .sleepEnergy: return String(localized: "Sleep & energy")
            }
        }
    }

    /// Every symptom the log offers, by group. Ids are storage keys: never rename one.
    static let symptoms: [Symptom] = [
        Symptom(id: "cramps", title: String(localized: "Cramps"), group: .pain),
        Symptom(id: "headache", title: String(localized: "Headache"), group: .pain),
        Symptom(id: "backache", title: String(localized: "Backache"), group: .pain),
        Symptom(id: "breastTenderness", title: String(localized: "Breast tenderness"), group: .pain),
        Symptom(id: "jointPain", title: String(localized: "Joint pain"), group: .pain),
        Symptom(id: "bloating", title: String(localized: "Bloating"), group: .body),
        Symptom(id: "acne", title: String(localized: "Acne"), group: .body),
        Symptom(id: "nausea", title: String(localized: "Nausea"), group: .body),
        Symptom(id: "cravings", title: String(localized: "Cravings"), group: .body),
        Symptom(id: "hotFlashes", title: String(localized: "Hot flashes"), group: .body),
        Symptom(id: "nightSweats", title: String(localized: "Night sweats"), group: .body),
        Symptom(id: "anxiety", title: String(localized: "Anxiety"), group: .mood),
        Symptom(id: "irritability", title: String(localized: "Irritability"), group: .mood),
        Symptom(id: "lowMood", title: String(localized: "Low mood"), group: .mood),
        Symptom(id: "moodSwings", title: String(localized: "Mood swings"), group: .mood),
        Symptom(id: "lowEnergy", title: String(localized: "Low energy"), group: .sleepEnergy),
        Symptom(id: "brainFog", title: String(localized: "Brain fog"), group: .sleepEnergy),
        Symptom(id: "poorSleep", title: String(localized: "Poor sleep"), group: .sleepEnergy),
    ]

    static func symptom(_ id: String) -> Symptom? { symptoms.first { $0.id == id } }

    /// The log sheet's PERIOD FLOW rows, in WHOOP's order (help-center/09).
    static let flowOrder: [MenstrualCycleModel.Flow] = [.noFlow, .light, .medium, .heavy, .spotting]

    /// "No Flow", "Light Flow", "Spotting": Title Case, as help-center/09 and 10 print them.
    static func title(_ flow: MenstrualCycleModel.Flow) -> String {
        switch flow {
        case .noFlow: return String(localized: "No Flow")
        case .spotting: return String(localized: "Spotting")
        case .light: return String(localized: "Light Flow")
        case .medium: return String(localized: "Medium Flow")
        case .heavy: return String(localized: "Heavy Flow")
        }
    }

    /// Everything logged, in one read.
    struct Logs: Equatable, Sendable {
        var starts: [String] = []
        var flow: [String: MenstrualCycleModel.Flow] = [:]
        var symptoms: [String: Set<String>] = [:]
    }
}

// MARK: - Reading (off the main actor)

extension PulseCycleLog {
    /// Every key the cycle source holds for Menstrual Cycle Insights.
    static var allKeys: [String] {
        [CycleTrackingStore.periodStartKey, flowKey] + symptoms.map { symptomPrefix + $0.id }
    }

    /// Period starts, flow and symptoms, oldest first. Not isolated to any actor, so the read and the parse
    /// run off the main actor whoever calls it (the snapshot builder, the log sheet).
    static func read(_ store: WhoopStore) async -> Logs {
        let rows = (try? await store.metricSeries(deviceId: CycleTrackingStore.sourceId, keys: allKeys,
                                                  from: CycleTrackingStore.earliestDay,
                                                  to: CycleTrackingStore.latestDay)) ?? []
        return parse(rows)
    }

    /// One day's flow and symptoms (the log sheet's day), with the starts that decide whether its flow is a
    /// left-over.
    static func readDay(_ store: WhoopStore, day: String) async -> (flow: MenstrualCycleModel.Flow?, symptoms: Set<String>) {
        let from = MenstrualCycleModel.shift(day, by: -(MenstrualCycleModel.periodRunMaxDays - 1)) ?? day
        let rows = (try? await store.metricSeries(deviceId: CycleTrackingStore.sourceId, keys: allKeys,
                                                  from: from, to: day)) ?? []
        let logs = parse(rows)
        return (logs.flow[day], logs.symptoms[day] ?? [])
    }

    /// The rows as logs. A period-flow day with no start in the `periodRunMaxDays` before it is a left-over
    /// of a deleted start and is dropped (see the header).
    static func parse(_ rows: [MetricPoint]) -> Logs {
        var logs = Logs()
        var starts = Set<String>()
        for row in rows {
            if row.key == CycleTrackingStore.periodStartKey {
                if row.value >= CycleTrackingStore.loggedValue { starts.insert(row.day) }
            } else if row.key == flowKey {
                if let f = MenstrualCycleModel.Flow(rawValue: Int(row.value.rounded())) { logs.flow[row.day] = f }
            } else if row.key.hasPrefix(symptomPrefix), row.value >= CycleTrackingStore.loggedValue {
                logs.symptoms[row.day, default: []].insert(String(row.key.dropFirst(symptomPrefix.count)))
            }
        }
        logs.starts = starts.sorted()
        logs.flow = logs.flow.filter { day, flow in
            !flow.isPeriod || logs.starts.contains { start in
                start <= day && (MenstrualCycleModel.days(from: start, to: day) ?? .max) < MenstrualCycleModel.periodRunMaxDays
            }
        }
        return logs
    }
}

extension Repository {

    /// Period starts, flow and symptoms, oldest first (read and parsed off the main actor).
    func cycleLogs() async -> PulseCycleLog.Logs {
        guard let store = await storeHandle() else { return PulseCycleLog.Logs() }
        return await PulseCycleLog.read(store)
    }

    /// Log (or clear, with nil) one day's flow, and keep the period starts in step with it.
    func setCycleFlow(_ flow: MenstrualCycleModel.Flow?, day: String) async {
        guard let store = await storeHandle() else { return }
        if let flow {
            _ = try? await store.upsertMetricSeries(
                [MetricPoint(day: day, key: PulseCycleLog.flowKey, value: Double(flow.rawValue))],
                deviceId: CycleTrackingStore.sourceId)
        } else {
            _ = try? await store.deleteMetricSeriesPoint(deviceId: CycleTrackingStore.sourceId, day: day,
                                                          key: PulseCycleLog.flowKey)
        }
        await reconcilePeriodStart(around: day, flow: flow)
        noteCycleTrackingChanged()
    }

    /// Log or clear one symptom on one day.
    func setCycleSymptom(_ id: String, logged: Bool, day: String) async {
        guard let store = await storeHandle() else { return }
        let key = PulseCycleLog.symptomPrefix + id
        if logged {
            _ = try? await store.upsertMetricSeries([MetricPoint(day: day, key: key, value: CycleTrackingStore.loggedValue)],
                                                    deviceId: CycleTrackingStore.sourceId)
        } else {
            _ = try? await store.deleteMetricSeriesPoint(deviceId: CycleTrackingStore.sourceId, day: day, key: key)
        }
        noteCycleTrackingChanged()
    }

    /// Delete every flow and symptom entry and every period start (after an explicit confirmation).
    func deleteAllCycleLogs() async {
        guard let store = await storeHandle() else { return }
        _ = try? await store.deleteMetricSeries(deviceId: CycleTrackingStore.sourceId, key: PulseCycleLog.flowKey)
        for s in PulseCycleLog.symptoms {
            _ = try? await store.deleteMetricSeries(deviceId: CycleTrackingStore.sourceId,
                                                    key: PulseCycleLog.symptomPrefix + s.id)
        }
        await deleteAllPeriodStarts()
    }

    /// Keep the period start (the engine's anchor) consistent with the flow just logged on `day`.
    private func reconcilePeriodStart(around day: String, flow: MenstrualCycleModel.Flow?) async {
        let starts = await periodStarts()
        let maxRun = MenstrualCycleModel.periodRunMaxDays
        if flow?.isPeriod == true {
            // Already inside a logged period: nothing to do.
            if starts.contains(where: { s in
                s <= day && (MenstrualCycleModel.days(from: s, to: day) ?? Int.max) < maxRun
            }) { return }
            // A start just after this day belongs to the same period: move it back to here.
            if let later = starts.first(where: { s in
                s > day && (MenstrualCycleModel.days(from: day, to: s) ?? Int.max) < maxRun
            }) {
                await deletePeriodStart(day: later)
            }
            await logPeriodStart(day: day)
        } else if flow == nil || flow == .noFlow, starts.contains(day) {
            // The start day no longer bleeds: move the start to the next flow day of the run, or drop it.
            let logs = await cycleLogs()
            let next = (1...(MenstrualCycleModel.periodRunGapTolerance + 1)).lazy
                .compactMap { MenstrualCycleModel.shift(day, by: $0) }
                .first { logs.flow[$0]?.isPeriod == true }
            await deletePeriodStart(day: day)
            if let next { await logPeriodStart(day: next) }
        }
    }
}
#endif
