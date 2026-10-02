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
        // Read fresh every build: logging a journal answer does not bump the refresh.
        let journal: [JournalEntry] = r.day.isToday
            ? await repo.journalEntries(days: RecoveryBehaviorChips.windowDays + 10)
            : []
        guard isCurrent(r) else { return nil }

        let days = r.days
        let byDay = Dictionary(days.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
        // The row the dial's number came from (its own, or the carried night's); with no score yet, the
        // day's own row, so a calibrating night still shows what it measured.
        let sourceKey = base.sourceDayKey ?? (byDay[r.day.key] == nil ? nil : r.day.key)
        let source = sourceKey.flatMap { byDay[$0] }
        func series(_ f: (DailyMetric) -> Double?) -> [(day: String, value: Double)] {
            days.compactMap { m in f(m).map { (day: m.day, value: $0) } }
        }
        // Sleep performance per day through the dial's resolver: the stored point, else the Rest composite.
        let restByDay = Dictionary(rest.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        let sleepKeys = Set(restByDay.keys).union(byDay.keys)
        let sleepHistory: [(day: String, value: Double)] = sleepKeys.compactMap { key in
            let value = restByDay[key] ?? byDay[key].flatMap { AnalyticsEngine.Rest.composite(daily: $0) }
            return value.map { (day: key, value: $0) }
        }

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
        if r.day.isToday {
            let answers = journal.map {
                RecoveryBehaviorChips.Answer(day: $0.day, behavior: $0.question, answeredYes: $0.answeredYes)
            }
            let recoveryByDay = Dictionary(days.compactMap { m in m.recovery.map { (m.day, $0) } },
                                           uniquingKeysWith: { _, last in last })
            behaviors = RecoveryBehaviorChips.chips(answers: answers, recoveryByDay: recoveryByDay,
                                                    dayKey: r.day.key).map(Self.behavior)
        }

        var carried: String?
        if case .carried(let caption) = base.dial.state { carried = caption }
        let text = Self.recoverySentences(dial: base.dial, carried: carried, contributors: contributors,
                                          day: r.day)
        guard isCurrent(r) else { return nil }
        return RecoveryDiveSnapshot(seq: r.seq, day: r.day, dial: base.dial, carriedCaption: carried,
                                    sourceDayKey: sourceKey, contributors: contributors, behaviors: behaviors,
                                    week: week, shaped: shaped, summary: text.summary, coachSeed: text.seed)
    }

    // MARK: What shaped it

    /// One engine driver in this dive's words: the WHOOP names (Sleep performance, not "Sleep quality"),
    /// "rpm" for breaths, and a skin-temperature deviation that keeps its degree sign and never prints a
    /// negative zero. The numbers are the engine's own, read off its texts, so the points and the figures
    /// beside them come from one computation.
    static func shapedRow(_ driver: ChargeDriver, skinDeviation: Double?,
                                      fahrenheit: Bool) -> RecoveryDiveSnapshot.Shaped.Row {
        let value = leadingNumber(driver.valueText)
        let baseline = leadingNumber(driver.baselineText)
        let title: String
        let detail: String
        switch driver.label {
        case "Heart rate variability":
            title = String(localized: "Heart rate variability")
            detail = measured(value, baseline, unit: "ms", fallback: driver)
        case "Resting heart rate":
            title = String(localized: "Resting heart rate")
            detail = measured(value, baseline, unit: "bpm", fallback: driver)
        case "Respiratory rate":
            title = String(localized: "Respiratory rate")
            detail = measured(value, baseline, unit: "rpm", fallback: driver)
        case "Sleep quality":
            // Scored against a fixed good night, not a learned baseline: the value alone.
            title = String(localized: "Sleep performance")
            detail = driver.valueText
        case "Skin temperature":
            title = String(localized: "Skin temperature")
            if let dev = skinDeviation, dev.isFinite {
                let kind = SkinTempDisplay.kind(of: dev)
                let number = SkinTempDisplay.numberString(dev, kind: kind, fahrenheit: fahrenheit)
                let unit = SkinTempDisplay.unitSymbol(kind: kind, fahrenheit: fahrenheit)
                detail = kind == .deviation
                    ? String(localized: "\(number) \(unit) vs baseline")
                    : "\(number) \(unit)"
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
    private static func measured(_ value: String?, _ baseline: String?, unit: String,
                                             fallback: ChargeDriver) -> String {
        guard let value else {
            return [fallback.valueText, fallback.baselineText].filter { !$0.isEmpty }.joined(separator: " · ")
        }
        guard let baseline else { return "\(value) \(unit)" }
        return String(localized: "\(value) \(unit) · baseline \(baseline) \(unit)")
    }

    /// The number an engine text starts with ("68" from "68 ms baseline", "15.1" from "15.1 br/min").
    static func leadingNumber(_ text: String) -> String? {
        guard let token = text.split(separator: " ").first.map(String.init), Double(token) != nil else { return nil }
        return token
    }

    // MARK: Behaviours

    private static func behavior(_ chip: RecoveryBehaviorChips.Chip) -> RecoveryDiveSnapshot.Behavior {
        let effect: PulseBehaviorChip.Effect
        let spoken: String
        switch chip.effect {
        case .helps:
            effect = .helps
            spoken = String(localized: "\(chip.behavior), has gone with a higher Recovery")
        case .hurts:
            effect = .hurts
            spoken = String(localized: "\(chip.behavior), has gone with a lower Recovery")
        case .notSignificant:
            effect = .neutral
            spoken = String(localized: "\(chip.behavior), no clear effect on Recovery")
        }
        return RecoveryDiveSnapshot.Behavior(id: chip.behavior, title: chip.behavior, effect: effect, spoken: spoken)
    }

    // MARK: Sentences

    /// The coach summary pill's sentence (until the Coach writes one, §1.2 [Z]) and the plain page context
    /// handed to the Coach. Every figure is a row already on the screen.
    static func recoverySentences(dial: PulseDialData, carried: String?,
                                              contributors: [PulseDiveContributor],
                                              day: PulseDay) -> (summary: String, seed: String) {
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
        return (summary, seed)
    }
}
#endif
