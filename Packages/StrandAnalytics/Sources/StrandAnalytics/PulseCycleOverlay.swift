import Foundation

// PulseCycleOverlay.swift - the Trend View's menstrual-cycle strip (WHOOP_UI_SPEC §3.12 item 11), pure.
//
// WHOOP colours the days under a Trend View chart by cycle phase for members who turn on Hormonal
// Insights. ZENO's equivalent opt-in is cycle awareness, and its reading of the cycle is
// `CyclePhaseEngine`: a fused nightly index (skin temperature, corroborated by resting HR and HRV) whose
// elevated runs are the luteal phase and whose rising edges are the mid-cycle shift. This turns that same
// reading into a phase per DAY, so a chart can be read against it:
//
//   - luteal      a night the engine reads as elevated (a one-night dip inside a run stays luteal);
//   - ovulatory   within `CyclePhaseEngine.periOvulatoryHalfWidth` days of a detected shift onset;
//   - menstrual   a period start the wearer logged and the days after it (`menstrualDays`, a stated
//                 estimate: ZENO stores starts only, never a period's end);
//   - follicular  every other night the engine could read.
//
// Nothing is invented: no phases while the engine is still learning or sees no clear pattern, none for a
// night without a reading, and menstrual days only from the wearer's own logs. Awareness only, like the
// engine itself: not a fertility or contraception tool.
//
// Display-only: nothing here is stored or crosses the .noopbak boundary, so there is no Kotlin twin.

public enum PulseCycleOverlay {

    public enum Phase: String, CaseIterable, Equatable, Sendable {
        case menstrual, follicular, ovulatory, luteal
    }

    /// One night's raw readings, as the merged daily rows carry them.
    public struct Reading: Equatable, Sendable {
        public let day: String
        public let skinTempDevC: Double?
        public let restingHR: Double?
        public let hrv: Double?

        public init(day: String, skinTempDevC: Double?, restingHR: Double?, hrv: Double?) {
            self.day = day
            self.skinTempDevC = skinTempDevC
            self.restingHR = restingHR
            self.hrv = hrv
        }
    }

    /// The engine's inputs from raw readings, z-scored against each signal's personal baseline folded over
    /// the whole history: the construction the app's cycle-awareness pass uses, so the strip and the
    /// cycle card read one model. Also returns whether the skin-temperature baseline is usable.
    public static func nights(_ readings: [Reading]) -> (nights: [CyclePhaseEngine.Night], baselineUsable: Bool) {
        guard let tempCfg = Baselines.metricCfg["skin_temp"],
              let rhrCfg = Baselines.metricCfg["resting_hr"],
              let hrvCfg = Baselines.metricCfg["hrv"] else { return ([], false) }
        let sorted = readings.sorted { $0.day < $1.day }
        let skin = Baselines.foldHistory(sorted.map(\.skinTempDevC), cfg: tempCfg)
        let rhr = Baselines.foldHistory(sorted.map(\.restingHR), cfg: rhrCfg)
        let hrv = Baselines.foldHistory(sorted.map(\.hrv), cfg: hrvCfg)
        let nights = sorted.map { r in
            CyclePhaseEngine.Night(
                day: r.day,
                tempZ: r.skinTempDevC.map { skin.usable ? Baselines.deviation($0, state: skin).z : $0 / 0.3 },
                rhrZ: rhr.usable ? r.restingHR.map { Baselines.deviation($0, state: rhr).z } : nil,
                hrvZ: hrv.usable ? r.hrv.map { Baselines.deviation($0, state: hrv).z } : nil)
        }
        return (nights, skin.usable)
    }

    /// A phase for every readable night (and logged menstrual day), or empty when the engine cannot
    /// classify the series (still learning, or no clear pattern).
    public static func phases(nights: [CyclePhaseEngine.Night], baselineUsable: Bool,
                              loggedPeriodStarts: [String] = [], menstrualDays: Int = 5) -> [String: Phase] {
        let sorted = nights.sorted { $0.day < $1.day }
        let result = CyclePhaseEngine.classify(sorted, baselineUsable: baselineUsable,
                                               loggedPeriodStarts: loggedPeriodStarts)
        switch result.phase {
        case .learning, .unknown: return [:]
        case .follicular, .periOvulatory, .luteal: break
        }

        let fused = sorted.map { CyclePhaseEngine.fusedIndex(tempZ: $0.tempZ, rhrZ: $0.rhrZ, hrvZ: $0.hrvZ) }
        // Only nights with a reading take part: an unread night neither ends a run nor starts one.
        let readable = sorted.indices.filter { fused[$0] != nil }
        let values = readable.compactMap { fused[$0] }
        guard !values.isEmpty else { return [:] }
        let center = CyclePhaseEngine.median(values)
        let spread = max(1e-9, CyclePhaseEngine.medianAbsoluteDeviation(values, center: center))
        var elevated = values.map { ($0 - center) >= CyclePhaseEngine.elevationK * spread }
        // A single night below the gate inside an elevated run is noise, not a new phase.
        if elevated.count >= 3 {
            for j in 1..<(elevated.count - 1) where !elevated[j] && elevated[j - 1] && elevated[j + 1] {
                elevated[j] = true
            }
        }

        var out: [String: Phase] = [:]
        for (j, i) in readable.enumerated() {
            out[sorted[i].day] = elevated[j] ? .luteal : .follicular
        }
        // Shift onsets: where an elevated run begins after a night below the gate (a series that opens
        // mid-run has no onset to mark).
        let half = CyclePhaseEngine.periOvulatoryHalfWidth
        for j in elevated.indices where j > 0 && elevated[j] && !elevated[j - 1] {
            for offset in -half...half {
                let day = PulseTrendMath.addDays(sorted[readable[j]].day, offset)
                if out[day] != nil { out[day] = .ovulatory }
            }
        }
        // Logged period starts: the wearer's own record wins its days.
        let first = sorted.first?.day ?? ""
        let last = sorted.last?.day ?? ""
        for start in loggedPeriodStarts where start >= PulseTrendMath.addDays(first, -menstrualDays) && start <= last {
            for offset in 0..<max(1, menstrualDays) {
                let day = PulseTrendMath.addDays(start, offset)
                if day >= first && day <= last { out[day] = .menstrual }
            }
        }
        return out
    }
}
