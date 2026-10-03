#if os(iOS)
import Foundation
import Observation
import StrandAnalytics

/// A challenge the wearer started (§3.41): its definition, and whether they left it.
struct PulseStoredChallenge: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let definition: ChallengeProgress.Definition
    let createdAt: Date
    /// The day the wearer left it, if they did.
    var leftOn: String?
}

/// The wearer's challenges, kept in UserDefaults on this iPhone (`pulse.challenges.v1`).
///
/// Local by design: a challenge is the wearer's own target, so nothing is synced, and it is not part of the
/// `.noopbak` backup whitelist (a byte-identical contract with Android, which has no challenges).
@MainActor
@Observable
final class PulseChallengeStore {
    static let shared = PulseChallengeStore()

    static let defaultsKey = "pulse.challenges.v1"
    /// At most this many run at once, so the list stays a list.
    static let maximumRunning = 3

    private(set) var challenges: [PulseStoredChallenge]

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([PulseStoredChallenge].self, from: data) {
            challenges = decoded
        } else {
            challenges = []
        }
    }

    /// Start a challenge; returns it, or nil when `maximumRunning` already run.
    @discardableResult
    func start(_ definition: ChallengeProgress.Definition, today: String) -> PulseStoredChallenge? {
        guard runningCount(today: today) < Self.maximumRunning else { return nil }
        let challenge = PulseStoredChallenge(id: UUID().uuidString, definition: definition, createdAt: Date(),
                                             leftOn: nil)
        challenges.append(challenge)
        persist()
        return challenge
    }

    /// Leave a challenge before its end: it moves to the finished list as it stands.
    func leave(_ id: String, today: String) {
        guard let i = challenges.firstIndex(where: { $0.id == id }) else { return }
        challenges[i].leftOn = today
        persist()
    }

    /// Remove a challenge from the list entirely.
    func remove(_ id: String) {
        challenges.removeAll { $0.id == id }
        persist()
    }

    /// Challenges not yet over by date and not left (one that reached its target still counts until its
    /// last day).
    func runningCount(today: String) -> Int {
        challenges.filter { $0.leftOn == nil && $0.definition.endDay >= today }.count
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(challenges) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }

    #if DEBUG
    /// `--pulse-demo-challenges`: with `--demo-seed`, start one challenge of each kind a few days back, so
    /// the list, the in-progress and the complete pages can be captured (simctl cannot tap).
    func seedDemoIfRequested(today: String) {
        guard CommandLine.arguments.contains("--pulse-demo-challenges"), challenges.isEmpty else { return }
        let start = PulseDisplay.dayKey(today, offsetBy: -3) ?? today
        let older = PulseDisplay.dayKey(today, offsetBy: -12) ?? today
        challenges = [
            PulseStoredChallenge(id: "demo-activity", definition: ChallengeProgress.suggested(.activityMinutes, startDay: start),
                                 createdAt: Date(), leftOn: nil),
            PulseStoredChallenge(id: "demo-bedtime", definition: ChallengeProgress.suggested(.bedtime, startDay: start),
                                 createdAt: Date(), leftOn: nil),
            PulseStoredChallenge(id: "demo-steps",
                                 definition: ChallengeProgress.Definition(kind: .steps, target: 40_000, days: 7,
                                                                          startDay: older),
                                 createdAt: Date(), leftOn: nil)
        ]
        persist()
    }
    #endif
}

/// What another screen needs to show a running challenge (§3.41: "while one runs, a Home coaching card"):
/// the running challenges, measured through the same builder as the Challenges pages, so a card and the
/// page it opens (`PulseChallengeDetailRoute(id:)`) cannot disagree.
///
///     let running = await PulseChallengeFeed.running(model)
///     // "Great start!": PulseChallengeText.headline(running[0]), PulseChallengeText.detail(running[0])
@MainActor
enum PulseChallengeFeed {
    static func running(_ model: PulseModel) async -> [ChallengeSnapshot] {
        let today = Repository.localDayKey(Date())
        let stored = PulseChallengeStore.shared.challenges.filter { $0.leftOn == nil && $0.definition.endDay >= today }
        guard !stored.isEmpty,
              let snapshot = await model.build(dayOffset: 0, { builder, request in
                  await builder.challenges(request, stored: stored)
              }) else { return [] }
        return snapshot.items.filter { $0.status.phase == .running }
    }
}
#endif
