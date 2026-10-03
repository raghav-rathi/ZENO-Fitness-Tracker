#if os(iOS)
import Foundation
import SwiftUI
import StrandAnalytics
import WhoopStore

// MARK: - The rebuilt Recovery deep dive (WHOOP_UI_SPEC §3.4), built off the main actor

extension PulseSnapshotBuilder {

    /// The Recovery dive for the request's day.
    ///
    /// The dial, its source night, the engine's drivers and their confidence come from the foundation's
    /// `recovery(_:)`, the resolver every Recovery surface shares. On top of it: the callout rows against
    /// their 30-day averages (WHOOP's legend; the engine's own baselines stay inside "What shaped it",
    /// labelled as baselines), the week, the behaviour chips and the coach sentence.
    func recoveryDive(_ r: PulseRequest) async -> RecoveryDiveSnapshot? {
        guard let base = await recovery(r) else { return nil }
        let rest = await restSeries()
        // The behaviour chips read what the Insights hub reads: every journal answer on file (fresh each
        // build, since logging an answer does not bump the refresh) and the four outcomes it ranks. Only
        // for a Recovery scored today: the card says the behaviours "may have affected your Recovery
        // score today", which a calibrating, carried or missing score cannot honour.
        let namesBehaviors = r.day.isToday && base.dial.state == .scored
        var journal: [JournalEntry] = []
        var outcomes: [String: [String: Double]] = [:]
        if namesBehaviors {
            journal = await repo.journalEntries()
            outcomes = await behaviorOutcomes(r)
        }
        guard isCurrent(r) else { return nil }

        let days = r.days
        let byDay = Dictionary(days.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
        // The row the dial's number came from (its own, or the carried night's); with no score yet, the
        // day's own row, so a calibrating night still shows what it measured.
        let sourceKey = base.sourceDayKey ?? (byDay[r.day.key] == nil ? nil : r.day.key)
        let source = sourceKey.flatMap { byDay[$0] }
        // While the baseline calibrates the rows show their values alone (§3.4 States): no 30-day
        // average and no arrow, as after a recalibration with weeks of nights still on file.
        var calibrating = false
        if case .calibrating = base.dial.state { calibrating = true }
        func series(_ f: (DailyMetric) -> Double?) -> [(day: String, value: Double)] {
            guard !calibrating else { return [] }
            return days.compactMap { m in f(m).map { (day: m.day, value: $0) } }
        }
        // Sleep performance per day through the dial's resolver: the stored point, else the Rest composite.
        let restByDay = Dictionary(rest.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let sleepKeys = calibrating ? [] : Set(restByDay.keys).union(byDay.keys)
        let sleepHistory: [(day: String, value: Double)] = sleepKeys.compactMap { key in
            let value = restByDay[key] ?? byDay[key].flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
            return value.map { (day: key, value: $0) }
        }

        // No row links anywhere until the Trend View is rebuilt: the classic metric screens behind it say
        // Charge and Rest and resolve their own figures (PulseDiveRoutes.trend).
        let contributors = [
            PulseDiveBaseline.contributor(
                id: "hrv", symbol: "waveform.path.ecg", title: String(localized: "Heart rate variability"),
                value: source?.avgHrv, dayKey: sourceKey, history: series(\.avgHrv), polarity: .higherIsBetter,
                route: PulseDiveRoutes.trend("hrv"), text: PulseFormat.whole,
                spoken: { String(localized: "\(PulseFormat.whole($0)) milliseconds") }),
            PulseDiveBaseline.contributor(
                id: "rhr", symbol: "arrow.down.heart", title: String(localized: "Resting heart rate"),
                value: source?.restingHr.map(Double.init), dayKey: sourceKey,
                history: series { $0.restingHr.map(Double.init) }, polarity: .lowerIsBetter,
                route: PulseDiveRoutes.trend("rhr"), text: PulseFormat.whole,
                spoken: { String(localized: "\(PulseFormat.whole($0)) beats per minute") }),
            PulseDiveBaseline.contributor(
                id: "resp_rate", symbol: "lungs", title: String(localized: "Respiratory rate"),
                value: source?.respRateBpm, dayKey: sourceKey, history: series(\.respRateBpm),
                polarity: .lowerIsBetter, route: PulseDiveRoutes.trend("resp_rate"), text: PulseFormat.oneDecimal,
                spoken: { String(localized: "\(PulseFormat.oneDecimal($0)) breaths per minute") }),
            PulseDiveBaseline.contributor(
                id: "sleep_performance", symbol: "moon", title: String(localized: "Sleep performance"),
                value: sourceKey.flatMap { sleepPerformance(dayKey: $0, rest: rest, days: days) }, dayKey: sourceKey,
                history: sleepHistory, polarity: .higherIsBetter, route: PulseDiveRoutes.trend("sleep_performance"),
                text: { "\(PulseDisplay.displayedPercent($0))%" },
                spoken: { String(localized: "\(PulseDisplay.displayedPercent($0)) percent") }),
        ]

        let keys = PulseDiveWeek.keys(endingOn: r.day.key)
        let week = RecoveryDiveSnapshot.Week(
            recovery: PulseDiveWeek.data(keys, value: { byDay[$0]?.recovery },
                                         color: { PulseTheme.recovery(percent: $0) },
                                         label: { "\(PulseDisplay.displayedPercent($0))%" }),
            hrv: PulseDiveWeek.data(keys, value: { byDay[$0]?.avgHrv }, color: { _ in PulseTheme.recoveryBlue },
                                    label: PulseFormat.whole),
            rhr: PulseDiveWeek.data(keys, value: { byDay[$0]?.restingHr.map(Double.init) },
                                    color: { _ in PulseTheme.recoveryBlue }, label: PulseFormat.whole),
            resp: PulseDiveWeek.data(keys, value: { byDay[$0]?.respRateBpm }, color: { _ in PulseTheme.recoveryBlue },
                                     label: PulseFormat.oneDecimal),
            highlightID: r.day.key)

        var shaped: RecoveryDiveSnapshot.Shaped?
        if let confidence = base.confidence, !base.drivers.isEmpty {
            shaped = RecoveryDiveSnapshot.Shaped(
                confidence: confidence,
                rows: base.drivers.map { Self.shapedRow($0, skinDeviation: source?.skinTempDevC,
                                                        fahrenheit: r.prefs.fahrenheit) })
        }

        var behaviors: [RecoveryDiveSnapshot.Behavior] = []
        if namesBehaviors {
            let answers = journal.map {
                RecoveryBehaviorChips.Answer(day: $0.day, behavior: $0.question, answeredYes: $0.answeredYes)
            }
            let renames = PulseBehaviorNames.renames()
            behaviors = RecoveryBehaviorChips.chips(answers: answers, outcomes: outcomes, dayKey: r.day.key)
                .map { Self.behavior($0, renames: renames) }
        }

        var carried: String?
        if case .carried(let caption) = base.dial.state { carried = caption }
        let text = Self.recoverySentences(dial: base.dial, carried: carried, contributors: contributors,
                                          day: r.day)
        // Why the countdown restarted, read here rather than in the card's body (a defaults read and a
        // date formatter on every pass).
        let restart = calibrating ? ChargeBreakdownFormat.currentCalibrationRestartCause() : nil
        guard isCurrent(r) else { return nil }
        return RecoveryDiveSnapshot(seq: r.seq, day: r.day, dial: base.dial, carriedCaption: carried,
                                    sourceDayKey: sourceKey, contributors: contributors, behaviors: behaviors,
                                    week: week, shaped: shaped, summary: text.summary,
                                    insight: calibrating ? nil : text.insight, calibrationRestart: restart,
                                    coachSeed: text.seed)
    }

    // MARK: Behaviour outcomes

    /// The four outcome series the behaviour chips are ranked against, read as the Insights hub reads them
    /// (`InsightsHubViewModel.load`), so the hub's ranking and the chips are one computation: each stored
    /// series, filled from the merged day rows where it has no value (Recovery, HRV and resting heart
    /// rate; Sleep Performance has no day column and stays stored-only). The stored reads are cached for
    /// the refresh.
    func behaviorOutcomes(_ r: PulseRequest) async -> [String: [String: Double]] {
        let stored: [String: [String: Double]] = await cached("recovery.behaviorOutcomes") {
            var out: [String: [String: Double]] = [:]
            for key in RecoveryBehaviorChips.outcomeKeys {
                let rows = await repo.series(key: key, source: "my-whoop")
                var byDay: [String: Double] = [:]
                for row in rows { byDay[row.day] = row.value }
                out[key] = byDay
            }
            return out
        }
        var outcomes: [String: [String: Double]] = [:]
        for key in RecoveryBehaviorChips.outcomeKeys {
            var byDay = stored[key] ?? [:]
            for d in r.days where byDay[d.day] == nil {
                if let v = Self.dayOutcome(key, d) { byDay[d.day] = v }
            }
            outcomes[key] = byDay
        }
        return outcomes
    }

    /// The day column behind an outcome key, as the hub fills it.
    private static func dayOutcome(_ key: String, _ d: DailyMetric) -> Double? {
        switch key {
        case "recovery": return d.recovery
        case "hrv": return d.avgHrv
        case "rhr": return d.restingHr.map(Double.init)
        default: return nil
        }
    }

    // MARK: What shaped it

    /// One engine driver in this dive's words: the WHOOP names (Sleep performance, not "Sleep quality"),
    /// "rpm" for breaths, and the engine's figures re-printed in the active locale ("14,9 rpm" where the
    /// decimal is a comma). The numbers are the engine's own, read off its texts, so the points and the
    /// figures beside them come from one computation.
    static func shapedRow(_ driver: ChargeDriver, skinDeviation: Double?,
                          fahrenheit: Bool) -> RecoveryDiveSnapshot.Shaped.Row {
        let value = leadingNumber(driver.valueText)
        let baseline = leadingNumber(driver.baselineText)
        let title: String
        let detail: String
        switch driver.label {
        case "Heart rate variability":
            title = String(localized: "Heart rate variability")
            detail = measured(value, baseline, unit: "ms", format: PulseFormat.whole, fallback: driver)
        case "Resting heart rate":
            title = String(localized: "Resting heart rate")
            detail = measured(value, baseline, unit: "bpm", format: PulseFormat.whole, fallback: driver)
        case "Respiratory rate":
            title = String(localized: "Respiratory rate")
            detail = measured(value, baseline, unit: "rpm", format: PulseFormat.oneDecimal, fallback: driver)
        case "Sleep quality":
            // Scored against a fixed good night, not a learned baseline: the value alone.
            title = String(localized: "Sleep performance")
            detail = driver.valueText
        case "Skin temperature":
            title = String(localized: "Skin temperature")
            if let dev = skinDeviation, dev.isFinite {
                detail = skinTemperature(dev, fahrenheit: fahrenheit)
            } else {
                detail = driver.valueText
            }
        default:
            title = driver.label
            detail = [driver.valueText, driver.baselineText].filter { !$0.isEmpty }.joined(separator: " · ")
        }
        let effect: String
        switch driver.deltaPoints {
        case 0: effect = String(localized: "no change to Recovery")
        case 1: effect = String(localized: "added 1 point")
        case -1: effect = String(localized: "took 1 point off")
        default:
            effect = driver.deltaPoints > 0
                ? String(localized: "added \(driver.deltaPoints) points")
                : String(localized: "took \(abs(driver.deltaPoints)) points off")
        }
        return RecoveryDiveSnapshot.Shaped.Row(id: driver.label, title: title, detail: detail,
                                               points: driver.deltaPoints,
                                               spoken: "\(title), \(detail), \(effect)")
    }

    /// "65 ms · baseline 68 ms" from the engine's numbers; the engine's own texts if they do not parse.
    private static func measured(_ value: Double?, _ baseline: Double?, unit: String,
                                 format: (Double) -> String, fallback: ChargeDriver) -> String {
        guard let value else {
            return [fallback.valueText, fallback.baselineText].filter { !$0.isEmpty }.joined(separator: " · ")
        }
        guard let baseline else { return "\(format(value)) \(unit)" }
        return String(localized: "\(format(value)) \(unit) · baseline \(format(baseline)) \(unit)")
    }

    /// The number an engine text starts with (68 from "68 ms baseline", 15.1 from "15.1 br/min"). The
    /// engine writes POSIX numbers, whatever the locale.
    static func leadingNumber(_ text: String) -> Double? {
        guard let token = text.split(separator: " ").first.map(String.init),
              let value = Double(token), value.isFinite else { return nil }
        return value
    }

    /// The night's skin temperature as §3.4 writes it: a live deviation from the personal baseline is
    /// signed, one decimal in the active locale ("+0.4 °C vs baseline", "−0.1 °C vs baseline", and no
    /// sign on a figure that prints as zero); an imported absolute reading is the temperature ("34.2 °C").
    static func skinTemperature(_ value: Double, fahrenheit: Bool) -> String {
        let unit = fahrenheit ? "°F" : "°C"
        switch SkinTempDisplay.kind(of: value) {
        case .absolute:
            return "\(PulseFormat.oneDecimal(fahrenheit ? value * 9 / 5 + 32 : value)) \(unit)"
        case .deviation:
            let signed = signedOneDecimal(fahrenheit ? value * 9 / 5 : value)
            return String(localized: "\(signed) \(unit) vs baseline")
        }
    }

    /// One decimal in the active locale with an explicit sign, "−" (U+2212) for a negative; a figure
    /// that prints as zero carries no sign.
    static func signedOneDecimal(_ value: Double) -> String {
        let magnitude = PulseFormat.oneDecimal(abs(value))
        guard magnitude != PulseFormat.oneDecimal(0) else { return magnitude }
        return (value > 0 ? "+" : "\u{2212}") + magnitude
    }

    // MARK: Behaviours

    private static func behavior(_ chip: RecoveryBehaviorChips.Chip,
                                 renames: [String: String]) -> RecoveryDiveSnapshot.Behavior {
        let title = PulseBehaviorNames.title(for: chip.behavior, renames: renames)
        let effect: PulseBehaviorChip.Effect
        let spoken: String
        switch chip.effect {
        case .helps:
            effect = .helps
            spoken = String(localized: "\(title), has gone with a higher Recovery")
        case .hurts:
            effect = .hurts
            spoken = String(localized: "\(title), has gone with a lower Recovery")
        case .notSignificant:
            effect = .neutral
            spoken = String(localized: "\(title), no clear effect on Recovery")
        }
        return RecoveryDiveSnapshot.Behavior(id: chip.behavior, title: title, effect: effect, spoken: spoken)
    }

    // MARK: Sentences

    /// The coach summary pill's sentence (until the Coach writes one, §1.2 [Z]), the same sentence in
    /// plain text for the inline card shown when the Coach is off (§3.4 item 4 [Z]), and the plain page
    /// context handed to the Coach. Every figure is a row already on the screen.
    static func recoverySentences(dial: PulseDialData, carried: String?,
                                  contributors: [PulseDiveContributor],
                                  day: PulseDay) -> (summary: String, insight: String, seed: String) {
        let hrv = contributors.first { $0.id == "hrv" }
        var summary: String
        switch dial.state {
        case .calibrating(let nights, let of):
            summary = String(localized: "Recovery needs \(of) nights of wear to learn your baseline. \(nights) of \(of) nights recorded.")
        case .noData:
            summary = day.isToday
                ? String(localized: "No Recovery yet today. It scores from a night of sleep with your strap on.")
                : String(localized: "No Recovery was scored for this day.")
        case .scored, .carried:
            let pct = dial.value.map { "\(PulseDisplay.displayedPercent($0))%" } ?? "--"
            if let carried {
                summary = String(localized: "Your latest Recovery is **\(pct)** (\(carried)).")
            } else {
                summary = String(localized: "Recovery is **\(pct)**.")
            }
            if let hrv, let relation = PulseDiveBaseline.relation(hrv), let baseline = hrv.baseline {
                summary += " " + String(localized: "HRV is **\(hrv.value) ms**, \(relation) its 30-day average of \(baseline) ms.")
            }
        }
        let dayName = PulseFormat.navDayTitle(offset: day.offset, date: day.date)
        var seed = String(localized: "Recovery deep dive, \(dayName).")
        if let value = dial.value { seed += " " + String(localized: "Recovery \(PulseDisplay.displayedPercent(value))%.") }
        for row in contributors where row.value != "--" {
            seed += " " + (row.baseline.map { String(localized: "\(row.title) \(row.value) (30-day average \($0)).") }
                           ?? "\(row.title) \(row.value).")
        }
        return (summary, summary.replacingOccurrences(of: "**", with: ""), seed)
    }
}

// MARK: - Behaviour names

/// What a behaviour chip prints (§3.18: "the name in Title Case"): the user's own name for the journal
/// question when they renamed it in the journal catalog, else a Title Case name for the ten starter
/// questions, else the question as stored. The chip's identity stays the stored question, the key the
/// analysis and the journal share.
enum PulseBehaviorNames {
    /// The journal catalog's renames, keyed by the normalised question (the same blob
    /// `JournalCatalogStore` persists; read directly because the store is main-actor bound).
    static func renames(_ defaults: UserDefaults = .standard) -> [String: String] {
        guard let blob = defaults.data(forKey: JournalCatalogBackupKeys.items),
              let items = try? JSONDecoder().decode([JournalCatalogItem].self, from: blob) else { return [:] }
        var out: [String: String] = [:]
        for item in items {
            guard let name = item.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                continue
            }
            out[JournalCatalogStore.norm(item.canonical)] = name
        }
        return out
    }

    /// The name to print for `question`.
    static func title(for question: String, renames: [String: String]) -> String {
        let key = JournalCatalogStore.norm(question)
        if let renamed = renames[key] { return renamed }
        if let starter = starterNames[key] { return starter }
        return question.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Title Case names for `JournalCatalogStore.starterQuestions`, keyed by the normalised question.
    private static let starterNames: [String: String] = [
        "did you drink any alcohol?": String(localized: "Alcohol"),
        "did you have caffeine late in the day?": String(localized: "Late Caffeine"),
        "did you view a screen in bed?": String(localized: "Screen In Bed"),
        "did you eat close to bedtime?": String(localized: "Late Meal"),
        "did you feel stressed?": String(localized: "Felt Stressed"),
        "did you use a sauna?": String(localized: "Sauna"),
        "did you share your bed?": String(localized: "Shared Bed"),
        "did you feel sick or ill?": String(localized: "Felt Sick"),
        "did you take magnesium?": String(localized: "Magnesium"),
        "did you read before bed?": String(localized: "Read Before Bed"),
    ]
}
#endif
