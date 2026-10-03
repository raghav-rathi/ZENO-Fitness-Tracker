#if os(iOS) && DEBUG
import Foundation
import WhoopStore
import WhoopProtocol

// MARK: - DEBUG demo heart rate for the day timeline (group "extras")
//
// Stripped from Release (the whole file is DEBUG). `--demo-seed` writes heart rate only from yesterday's
// midnight (`PulseDemo`), so a finished day in the timeline has its night, Recovery and workouts but no
// line under them. With `--demo-seed --pulse-demo-timeline`, the timeline fills the day it shows with
// synthetic heart rate shaped by that day's own seeded night and workouts, so a past day can be captured
// the way WHOOP's tilt view shows one. It writes only to the demo store, only for a window that holds no
// heart rate at all, so it never touches a real install's data.
extension PulseSnapshotBuilder {

    static var demoTimelineRequested: Bool {
        let args = CommandLine.arguments
        return args.contains("--demo-seed") && args.contains("--pulse-demo-timeline")
    }

    /// Fill `window` with a reading every 10 s: asleep over `night`, raised and arched inside each workout,
    /// an ordinary day otherwise. No-op when the window already holds heart rate.
    func seedDemoTimeline(window: (from: Int, to: Int), night: (start: Int, end: Int)?, workouts: [WorkoutRow],
                          expectedWorkouts: Int, now: Date) async {
        let end = min(window.to, Int(now.timeIntervalSince1970))
        // Wait for the demo seed's night and workouts: on a fresh install the first builds can run before they
        // are written, and heart rate written then would never be reshaped (the window would no longer be
        // empty). The day's row says how many workouts the seed gave it.
        guard end > window.from, night != nil, workouts.count >= expectedWorkouts else { return }
        let existing = await repo.hrSamples(from: window.from, to: end, limit: 10)
        guard existing.isEmpty, let store = await repo.storeHandle() else { return }

        var rng: UInt64 = 0xD15EA5E ^ UInt64(window.from)
        func noise() -> Double {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            return Double(rng >> 33) / Double(1 << 31) - 0.5
        }
        let todayStart = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(window.from)))
        var samples: [HRSample] = []
        samples.reserveCapacity((end - window.from) / 10 + 1)
        var drift = 0.0
        var t = window.from
        while t <= end {
            drift = max(-5, min(5, drift + noise() * 0.7))
            let hour = Double(t - Int(todayStart.timeIntervalSince1970)) / 3600
            var base = 72 + 7 * sin(hour / 3) + drift
            if let night, t >= night.start, t <= night.end {
                // Asleep: low and steady, with the brief arousals a night has.
                base = 53 + 3 * sin(Double(t - night.start) / 4_000) + (noise() > 0.495 ? 14 : 0)
            }
            if let w = workouts.first(where: { t >= $0.startTs && t <= $0.endTs }) {
                let span = Double(max(60, w.endTs - w.startTs))
                let progress = Double(t - w.startTs) / span
                let peak = Double(w.maxHr ?? 165)
                base = 112 + (peak - 112) * sin(progress * .pi)
            }
            let bpm = Int((base + noise() * 6).rounded())
            samples.append(HRSample(ts: t, bpm: max(40, min(195, bpm))))
            t += 10
        }
        _ = try? await store.insert(Streams(hr: samples), deviceId: AppleDemoSeeder.whoop)
    }
}
#endif
