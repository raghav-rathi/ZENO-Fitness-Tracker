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

    /// One reading every 10 s: asleep overnight, a morning tempo run, an ordinary day with a lunchtime
    /// walk, and a hard session late afternoon (today's only if the clock has passed it).
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
            case ..<6.75: base = 54 + 3 * sin(hour)                                  // asleep
            case ..<7.25: base = 64                                                  // waking
            case 7.25..<8.0: base = 126 + 34 * sin((hour - 7.25) / 0.75 * .pi)      // tempo run
            case 12.5..<12.9: base = 104                                             // lunchtime walk
            case 17.5..<18.33: base = 118 + 50 * sin((hour - 17.5) / 0.83 * .pi)    // hard session
            case 23...: base = 58                                                    // falling asleep
            default: base = 74 + 6 * sin(hour / 3)                                   // the day
            }
            let bpm = Int((base + drift + noise() * 6).rounded())
            out.append(HRSample(ts: t, bpm: max(40, min(195, bpm))))
            t += 10
        }
        return out
    }
}

/// DEBUG launch arguments that put the shell in a given state at launch, so every Pulse state can be
/// captured by `simctl` (which cannot tap or swipe):
///   `--pulse-tab home|health|more`     the selected tab
///   `--pulse-day N`                    Home N days back
///   `--pulse-night N`                  the Sleep dive N nights back
///   `--pulse-range 7|30|90`            the Recovery history's range
///   `--pulse-push recovery|strain|sleep`  push a deep dive onto Home
///   `--pulse-sheet actions`            present the ＋ menu
///   `--pulse-scroll <anchor>`          scroll to a section id ("myday", "stats", "stress", "bottom", …)
enum PulseDebugLaunch {
    private static func value(_ flag: String) -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var tab: PulseTab? {
        switch value("--pulse-tab") {
        case "home": return .home
        case "health": return .health
        case "coach": return .coach
        case "more": return .more
        default: return nil
        }
    }

    static var dayOffset: Int? { value("--pulse-day").flatMap(Int.init) }

    /// `--pulse-night N`: open the Sleep dive N nights back from the latest.
    static var nightIndex: Int? { value("--pulse-night").flatMap(Int.init) }

    /// `--pulse-range 7|30|90`: the Recovery history's initial range.
    static var historyRange: Int? {
        value("--pulse-range").flatMap(Int.init).flatMap { [7, 30, 90].contains($0) ? $0 : nil }
    }

    static var push: PulseRoute? {
        switch value("--pulse-push") {
        case "recovery": return .score(.recovery)
        case "strain": return .score(.strain)
        case "sleep": return .score(.sleep)
        default: return nil
        }
    }

    static var showsActions: Bool { value("--pulse-sheet") == "actions" }

    /// The section id to scroll to, prefixed as the views tag them.
    static var scrollAnchor: String? { value("--pulse-scroll").map { "pulse.\($0)" } }
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
