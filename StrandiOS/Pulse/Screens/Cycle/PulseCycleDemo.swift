#if os(iOS) && DEBUG
import Foundation
import StrandAnalytics

// MARK: - DEBUG cycle logs for captures
//
// `--demo-seed --cycle-demo [N]` fills an EMPTY cycle log with four past cycles (29, 27, 28 and 30 days,
// each with logged flow and a few symptoms) and a current cycle on day N (default 3), and switches the
// insights on, so the page can be captured in the simulator. It never runs without `--demo-seed`, and never
// over a log that already holds anything, so it cannot touch a real install's history. Stripped from Release.
enum PulseCycleDemo {
    static var requested: Bool {
        let args = CommandLine.arguments
        return args.contains("--demo-seed") && args.contains("--cycle-demo")
    }

    static var cycleDay: Int {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--cycle-demo"), i + 1 < args.count, let n = Int(args[i + 1]) else { return 3 }
        return max(1, min(40, n))
    }

    /// Seed the logs once. Returns true when it wrote anything.
    @MainActor
    static func seedIfRequested(repo: Repository, today: String) async -> Bool {
        guard requested else { return false }
        let existing = await repo.cycleLogs()
        guard existing.starts.isEmpty, existing.flow.isEmpty, existing.symptoms.isEmpty else { return false }
        UserDefaults.standard.set(true, forKey: AppModel.cycleAwarenessKey)

        guard let current = MenstrualCycleModel.shift(today, by: -(cycleDay - 1)) else { return false }
        var starts = [current]
        for length in [30, 28, 27, 29] {
            guard let previous = MenstrualCycleModel.shift(starts[0], by: -length) else { break }
            starts.insert(previous, at: 0)
        }
        func day(_ start: String, _ offset: Int) -> String? { MenstrualCycleModel.shift(start, by: offset) }
        let pattern: [MenstrualCycleModel.Flow] = [.medium, .heavy, .medium, .light, .spotting]
        for (index, start) in starts.enumerated() {
            let isCurrent = index == starts.count - 1
            for (offset, flow) in pattern.enumerated() {
                guard let d = day(start, offset), d <= today else { continue }
                if isCurrent && offset >= cycleDay { continue }
                await repo.setCycleFlow(flow, day: d)
            }
            // Cramps on days 1-2, low energy on days 2-3, backache on day 3 every other cycle,
            // bloating and cravings late in the luteal phase.
            var symptoms: [(Int, String)] = [(0, "cramps"), (1, "cramps"), (1, "lowEnergy"), (2, "lowEnergy"),
                                             (23, "bloating"), (24, "bloating"), (24, "cravings")]
            if index % 2 == 0 { symptoms.append((2, "backache")) }
            if index == 1 { symptoms.append((0, "headache")) }
            for (offset, id) in symptoms {
                guard let d = day(start, offset), d <= today else { continue }
                await repo.setCycleSymptom(id, logged: true, day: d)
            }
        }
        return true
    }
}
#endif
