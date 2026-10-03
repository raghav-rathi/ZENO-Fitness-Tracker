#if os(iOS) && DEBUG
import Foundation
import StrandAnalytics

// MARK: - DEBUG Coach states for captures
//
// `--demo-seed --coach-demo` points the Coach at a local OpenAI-compatible server address (the simulator's
// unsigned build has no Keychain for a cloud key), so the sheet shows the chat rather than setup; puts a short
// conversation in an EMPTY transcript, built from the demo store's own numbers; saves two memories into an
// EMPTY My Memory and files one earlier conversation in an EMPTY history. Nothing is sent anywhere unless a
// question is asked, and then only to that local address. `--coach-open memory|settings|history|memory-detail`
// opens that part of the sheet; `--coach-large` opens it at the large detent; `--coach-ask` sends the first
// suggestion. Never runs without `--demo-seed`; stripped from Release.
enum PulseCoachDemo {
    private static var args: [String] { CommandLine.arguments }

    static var requested: Bool { args.contains("--demo-seed") && args.contains("--coach-demo") }
    static var opensLarge: Bool { args.contains("--coach-large") }
    /// `--coach-ask`: send the first suggestion chip once the sheet is open, so a capture shows what a
    /// question carries (its receipt, the page card's state). It goes to the demo's local address only.
    static var asksFirstSuggestion: Bool { requested && args.contains("--coach-ask") }

    /// `--coach-seed outlook`: open as if from Home's Daily Outlook pill, with the seed Home builds from the
    /// demo store's own day (so a capture shows real numbers, never invented ones). `--coach-seed cycle`: as
    /// if from Menstrual Cycle Insights, with the header the page builds from the logs already in the store
    /// (capture the cycle page with `--cycle-demo` first).
    @MainActor
    static func seedOverride(model: PulseModel) async -> String? {
        guard let i = args.firstIndex(of: "--coach-seed"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "outlook":
            for _ in 0..<40 where model.home == nil {
                try? await Task.sleep(nanoseconds: 150_000_000)
            }
            return model.home.map { PulseDailyOutlook.compose(home: $0, facts: nil, evening: false).plainText }
        case "cycle":
            let today = Repository.localDayKey(Date())
            let snapshot = await model.build(dayOffset: 0) { builder, request -> CycleInsightsSnapshot? in
                var logs = PulseCycleLog.Logs()
                if let store = await builder.repo.storeHandle() { logs = await PulseCycleLog.read(store) }
                guard !logs.starts.isEmpty else { return nil }
                return await builder.cycleInsights(request, inputs: PulseCycleInputs(
                    today: today, logs: logs, engine: nil, mode: .menstruating, contraception: .none))
            }
            return snapshot?.header.accessibility
        default:
            return nil
        }
    }

    static var openTarget: String? {
        guard let i = args.firstIndex(of: "--coach-open"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    @MainActor
    static func prepareIfRequested(coach: AICoachEngine, repo: Repository) async {
        guard requested else { return }
        if !coach.isConfigured {
            coach.provider = .custom
            coach.customBaseURL = "http://localhost:11434/v1"
            coach.setCustomModel("llama3.1-8b")
            coach.customConnected = true
            coach.dataConsent = true
        }
        let memory = PulseMemoryStore.shared
        memory.loadIfNeeded()
        if memory.items.isEmpty {
            let now = Date()
            memory.add("Training for a half marathon in May, running four times a week.", category: .goals,
                       now: now.addingTimeInterval(-6 * 86_400))
            memory.add("Started a desk job with early meetings, so I sleep less on weekdays.", category: .lifestyle,
                       now: now.addingTimeInterval(-3_600))
        }
        let threads = PulseCoachThreadStore.shared
        await threads.loadIfNeeded()
        if threads.threads.isEmpty {
            let earlier = [
                ChatMessage(role: .user, text: PulseCoachEnvelope.wrap("How should I taper before race day?", page: nil,
                                                                       memories: memory.promptItems)),
                ChatMessage(role: .assistant, text: "Cut your weekly volume by about a third in the final ten days and keep two short runs at race pace, so you arrive fresh without losing sharpness."),
            ]
            threads.sync(earlier, now: Date().addingTimeInterval(-2 * 86_400))
        }
        guard coach.messages.isEmpty else { return }
        // A later launch reopens the demo conversation it filed before rather than filing another.
        if let filed = threads.threads.first(where: { $0.title == "How did I recover this week?" }) {
            coach.messages = filed.messages.map {
                ChatMessage(id: $0.id, role: ChatMessage.Role(rawValue: $0.role) ?? .user, text: $0.text)
            }
            return
        }
        // At launch the store may still be loading: give it a few seconds.
        for _ in 0..<40 where repo.days.isEmpty {
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        let days = repo.days.suffix(7)
        guard let today = days.last, let recovery = today.recovery else { return }
        let week = days.compactMap(\.recovery)
        let avg = week.isEmpty ? recovery : week.reduce(0, +) / Double(week.count)
        let strain = days.compactMap(\.strain).map { UnitFormatter.effortValue($0, scale: .whoop) }
        let strainAvg = strain.isEmpty ? 0 : strain.reduce(0, +) / Double(strain.count)
        var reply = "Here's your week at a glance:\n\n"
        reply += "- **Today:** Recovery **\(PulseDisplay.displayedPercent(recovery))%**"
        if let hrv = today.avgHrv { reply += " with HRV **\(Int(hrv.rounded())) ms**" }
        if let rhr = today.restingHr { reply += " and a resting heart rate of **\(rhr) bpm**" }
        reply += ".\n"
        reply += "- **Last 7 days:** Recovery averaged **\(PulseDisplay.displayedPercent(avg))%**"
        reply += " and Strain averaged **\(PulseFormat.oneDecimal(strainAvg))** on the 0–21 scale.\n\n"
        reply += "You're recovering steadily. With your half marathon in May, keep one hard session this week and make the next run an easy Zone 2 run so tomorrow's Recovery has room to climb."
        coach.messages = [
            ChatMessage(role: .user, text: PulseCoachEnvelope.wrap("How did I recover this week?", page: nil,
                                                                   memories: memory.promptItems)),
            ChatMessage(role: .assistant, text: reply),
        ]
        threads.sync(coach.messages)
    }
}
#endif
