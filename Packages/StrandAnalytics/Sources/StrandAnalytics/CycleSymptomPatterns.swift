import Foundation

// CycleSymptomPatterns.swift — symptom predictions and summaries from the user's OWN symptom logs. Pure,
// deterministic, UTC day keys.
//
// "Possible symptoms today" are the symptoms the user logged around the same cycle day in most of their
// previous cycles: for each completed cycle in which they logged anything at all, did this symptom appear
// within a day either side of today's cycle day? A symptom is offered once it did in at least half of those
// cycles and in at least two of them. Nothing here is population data, and nothing is a medical statement;
// with too few logged cycles the answer is simply "not yet".
public enum CycleSymptomPatterns {

    /// Completed cycles with any symptom logged before a prediction is offered.
    public static let minCycles = 2
    /// Cycles a symptom must have appeared in.
    public static let minOccurrences = 2
    /// Share of the logging cycles it must have appeared in.
    public static let minShare = 0.5
    /// Days either side of today's cycle day that still count as "around the same day".
    public static let dayWindow = 1

    /// A symptom expected today, and how often it came up.
    public struct Prediction: Equatable, Sendable {
        public let symptom: String
        /// Cycles it appeared in around this cycle day.
        public let cycles: Int
        /// Logging cycles that reached this cycle day.
        public let ofCycles: Int

        public init(symptom: String, cycles: Int, ofCycles: Int) {
            self.symptom = symptom
            self.cycles = cycles
            self.ofCycles = ofCycles
        }

        public var share: Double { ofCycles > 0 ? Double(cycles) / Double(ofCycles) : 0 }
    }

    /// Why there is no prediction list yet.
    public enum Readiness: Equatable, Sendable {
        /// Enough logged cycles: the list (possibly empty) is meaningful.
        case ready
        /// Fewer than `minCycles` completed cycles with symptoms logged (how many so far).
        case needsCycles(logged: Int)
    }

    /// Symptoms likely on `cycleDay`, most frequent first (ties by name).
    ///
    /// - Parameters:
    ///   - symptomDays: logged symptoms by day key.
    ///   - completedCycles: completed cycles (start day key, length in days), any order.
    ///   - cycleDay: today's cycle day (1-based).
    public static func predictions(symptomDays: [String: Set<String>],
                                   completedCycles: [(start: String, length: Int)],
                                   cycleDay: Int) -> (readiness: Readiness, predictions: [Prediction]) {
        // Cycles in which the user logged at least one symptom: only those can say "it did not happen".
        let logging = completedCycles.filter { cycle in
            (0..<cycle.length).contains { offset in
                guard let day = MenstrualCycleModel.shift(cycle.start, by: offset) else { return false }
                return !(symptomDays[day] ?? []).isEmpty
            }
        }
        guard logging.count >= minCycles else { return (.needsCycles(logged: logging.count), []) }

        let lowDay = max(1, cycleDay - dayWindow)
        let highDay = cycleDay + dayWindow
        // Only cycles that lasted long enough to have had today's cycle day.
        let reaching = logging.filter { $0.length >= cycleDay }
        guard !reaching.isEmpty else { return (.ready, []) }

        var counts: [String: Int] = [:]
        for cycle in reaching {
            var seen = Set<String>()
            for cd in lowDay...min(highDay, cycle.length) {
                guard let day = MenstrualCycleModel.shift(cycle.start, by: cd - 1) else { continue }
                seen.formUnion(symptomDays[day] ?? [])
            }
            for s in seen { counts[s, default: 0] += 1 }
        }
        let n = reaching.count
        let out = counts
            .filter { $0.value >= minOccurrences && Double($0.value) / Double(n) >= minShare }
            .map { Prediction(symptom: $0.key, cycles: $0.value, ofCycles: n) }
            .sorted { $0.cycles != $1.cycles ? $0.cycles > $1.cycles : $0.symptom < $1.symptom }
        return (.ready, out)
    }

    /// One logged symptom over a span: how many days it was logged and the phase most of them fell in.
    public struct Summary: Equatable, Sendable {
        public let symptom: String
        public let days: Int
        /// The phase holding the most of those days (nil when none had a phase).
        public let phase: MenstrualCycleModel.Phase?
        /// Days in that phase.
        public let phaseDays: Int

        public init(symptom: String, days: Int, phase: MenstrualCycleModel.Phase?, phaseDays: Int) {
            self.symptom = symptom
            self.days = days
            self.phase = phase
            self.phaseDays = phaseDays
        }
    }

    /// The most-logged symptoms on or after `from` (through `to`), most days first (ties by name), each
    /// with the phase most of its days fell in.
    public static func summary(symptomDays: [String: Set<String>],
                               phaseByDay: [String: MenstrualCycleModel.Phase],
                               from: String, to: String, limit: Int = 5) -> [Summary] {
        var dayCounts: [String: Int] = [:]
        var phaseCounts: [String: [MenstrualCycleModel.Phase: Int]] = [:]
        for (day, symptoms) in symptomDays where day >= from && day <= to {
            for s in symptoms {
                dayCounts[s, default: 0] += 1
                if let p = phaseByDay[day] { phaseCounts[s, default: [:]][p, default: 0] += 1 }
            }
        }
        let order = MenstrualCycleModel.Phase.allCases
        return dayCounts
            .map { symptom, days -> Summary in
                let byPhase = phaseCounts[symptom] ?? [:]
                // Ties go to the earlier phase in cycle order, so the answer is stable.
                let best = order.max { a, b in
                    let ca = byPhase[a] ?? 0, cb = byPhase[b] ?? 0
                    return ca != cb ? ca < cb : (order.firstIndex(of: a)! > order.firstIndex(of: b)!)
                }
                let bestDays = best.map { byPhase[$0] ?? 0 } ?? 0
                return Summary(symptom: symptom, days: days, phase: bestDays > 0 ? best : nil, phaseDays: bestDays)
            }
            .sorted { $0.days != $1.days ? $0.days > $1.days : $0.symptom < $1.symptom }
            .prefix(limit)
            .map { $0 }
    }
}
