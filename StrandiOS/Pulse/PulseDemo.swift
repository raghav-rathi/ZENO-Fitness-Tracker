#if os(iOS) && DEBUG
import SwiftUI
import WhoopStore
import WhoopProtocol

// MARK: - DEBUG demo support
//
// Stripped from Release (the whole file is DEBUG). `--demo-seed` fills the store with daily rows, sleeps
// and workouts but no heart-rate samples, which leaves the Strain dive's curve, heart-rate chart and zone
// minutes empty. This adds a deterministic synthetic day of heart rate so those screens can be verified
// in the simulator. It only runs with `--demo-seed`, and only when the store holds no heart rate for the
// last day, so it never touches a real install's data.
enum PulseDemo {

    /// Seed yesterday-midnight → now with synthetic heart rate. Returns true when it wrote anything.
    @MainActor
    static func seedHeartRateIfRequested(repo: Repository) async -> Bool {
        guard CommandLine.arguments.contains("--demo-seed") else { return false }
        let now = Int(Date().timeIntervalSince1970)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return false }
        let from = Int(yesterday.timeIntervalSince1970)
        if let fp = await repo.hrFingerprint(from: now - 86_400, to: now), fp.count > 0 { return false }
        guard let store = await repo.storeHandle() else { return false }

        let samples = synthesize(from: from, to: now, todayStart: Int(today.timeIntervalSince1970))
        do {
            _ = try await store.insert(Streams(hr: samples), deviceId: AppleDemoSeeder.whoop)
            NSLog("PulseDemo: seeded \(samples.count) synthetic heart-rate samples.")
            return true
        } catch {
            NSLog("PulseDemo: heart-rate seed failed: \(error)")
            return false
        }
    }

    /// One reading every 10 s: asleep overnight, an ordinary day, a morning walk, and a hard session
    /// late afternoon (today's only if the clock has passed it).
    private static func synthesize(from: Int, to: Int, todayStart: Int) -> [HRSample] {
        var rng: UInt64 = 0x5EED_1234
        func noise() -> Double {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            return Double(rng >> 33) / Double(1 << 31) - 0.5   // [-0.5, 0.5)
        }
        var out: [HRSample] = []
        out.reserveCapacity((to - from) / 10 + 1)
        var drift = 0.0
        var t = from
        while t <= to {
            let secOfDay = ((t - todayStart) % 86_400 + 86_400) % 86_400
            let hour = Double(secOfDay) / 3600
            drift = max(-6, min(6, drift + noise() * 0.8))
            let base: Double
            switch hour {
            case ..<6.75: base = 54 + 3 * sin(hour)                        // asleep
            case ..<7.5: base = 64                                         // waking
            case 7.5..<8.25: base = 102                                    // walk
            case 17.5..<18.33: base = 118 + 50 * sin((hour - 17.5) / 0.83 * .pi)   // hard session
            case 23...: base = 58                                          // falling asleep
            default: base = 74 + 6 * sin(hour / 3)                         // the day
            }
            let bpm = Int((base + drift + noise() * 6).rounded())
            out.append(HRSample(ts: t, bpm: max(40, min(195, bpm))))
            t += 10
        }
        return out
    }
}

/// `--demo-screen pulse…` renders one Pulse screen full-bleed over the seeded store.
struct PulseDemoScreen: View {
    enum Kind: String {
        case home, recovery, strain, sleep, health, more
    }

    let kind: Kind
    @State private var model = PulseModel()

    var body: some View {
        content
            .pulseDestinations()
            .environment(model)
            .background(PulseAttacher(model: model))
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .home: PulseHomeView(onAction: { _ in }, onSettings: {})
        case .recovery: PulseRecoveryView()
        case .strain: PulseStrainView()
        case .sleep: PulseSleepView()
        case .health: PulseHealthView(onAction: { _ in })
        case .more: PulseMoreView(showsCoachSetup: false)
        }
    }
}
#endif
