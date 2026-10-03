#if os(iOS)
import Foundation
import WhoopStore
import StrandAnalytics

/// What the cycle page builds from, read on the main actor in one pass (the logs, the temperature engine's
/// result `AppModel` publishes, the settings and today's local day key).
struct PulseCycleInputs: Sendable {
    /// Today's LOCAL calendar day key: the day a period or symptom logged "today" is filed under (the
    /// classic tracker's rule), not Home's 04:00 logical day.
    let today: String
    let logs: PulseCycleLog.Logs
    /// `CyclePhaseEngine.classify`'s result, when cycle awareness is on and it has run.
    let engine: CyclePhaseEngine.Result?
    let mode: PulseCycleLog.Mode
    let contraception: PulseCycleLog.Contraception
}

// MARK: - Menstrual Cycle Insights (WHOOP_UI_SPEC §3.24)

extension PulseSnapshotBuilder {

    /// The whole page, off the main actor: `MenstrualCycleModel` over the logs is the ONE funnel for the
    /// cycle day, phase, prediction and calendar; the temperature engine only speaks where there are no
    /// usable logs, and its cross-check of a logged date is shown beside them, never instead.
    func cycleInsights(_ r: PulseRequest, inputs: PulseCycleInputs) -> CycleInsightsSnapshot {
        let today = inputs.today
        let logs = inputs.logs
        let menopause = inputs.mode == .menopause
        let phasesApply = PulseCycleLog.phasesApply(mode: inputs.mode, contraception: inputs.contraception)
        let summary = MenstrualCycleModel.summarize(
            periodStarts: logs.starts, flow: logs.flow, today: today,
            temperatureCycleLength: inputs.engine?.cycleLengthDays, phasesApply: phasesApply,
            extraSpread: inputs.mode == .perimenopause ? 2 : 0)
        let active = summary.status == .active && !menopause

        // The calendar's span: the first thing logged (at most a year back, at least two months back)
        // through the end of the month two months ahead.
        let firstLogged = ([logs.starts.min(), logs.flow.keys.min(), logs.symptoms.keys.min()].compactMap { $0 }).min()
        let yearBack = MenstrualCycleModel.shift(today, by: -365) ?? today
        let twoMonthsBack = MenstrualCycleModel.shift(today, by: -62) ?? today
        let rangeStart = PulseCycleDates.monthStart(max(yearBack, min(firstLogged ?? twoMonthsBack, twoMonthsBack)))
        let rangeEnd = PulseCycleDates.monthEnd(PulseCycleDates.monthStart(MenstrualCycleModel.shift(today, by: 62) ?? today))
        var infos = MenstrualCycleModel.calendar(from: rangeStart, to: rangeEnd, summary: summary, flow: logs.flow,
                                                 today: today, phasesApply: phasesApply)
        if menopause {
            // A bleed in menopause is history, never a prediction, and there are no phases to draw.
            infos = infos.map { d in
                MenstrualCycleModel.DayInfo(day: d.day, phase: nil, isPredicted: d.isPredicted,
                                            isLoggedPeriodDay: d.isLoggedPeriodDay, isPredictedPeriodDay: false,
                                            flow: d.flow, cycleDay: nil)
            }
        }
        let engineWindowDays = engineWindow(inputs, summary: summary, menopause: menopause)
        let byDay = Dictionary(uniqueKeysWithValues: infos.map { ($0.day, $0) })

        // Phases of the days that have happened, from what was logged (the coaching card and symptom
        // summaries never read a prediction).
        var pastPhases: [String: PulseCyclePhase] = [:]
        for d in infos where d.day <= today {
            if let p = d.phase { pastPhases[d.day] = p }
        }

        let header = header(summary: summary, inputs: inputs, active: active, phasesApply: phasesApply,
                            todayInfo: byDay[today])
        let months = months(infos: infos, today: today, symptoms: logs.symptoms, engineWindow: engineWindowDays)
        let todayMonth = String(today.prefix(7))

        let completed: [(start: String, length: Int)] = summary.cycles.compactMap { c in
            c.isPlausible ? c.length.map { (c.start, $0) } : nil
        }
        let symptomsToday: CycleInsightsSnapshot.SymptomsToday = {
            guard active, let cd = summary.cycleDay else { return .unavailable }
            let r = CycleSymptomPatterns.predictions(symptomDays: logs.symptoms, completedCycles: completed,
                                                     cycleDay: cd)
            switch r.readiness {
            case .needsCycles: return .notYet
            case .ready:
                let titles = r.predictions.compactMap { PulseCycleLog.symptom($0.symptom)?.title }
                return titles.isEmpty ? .nothingExpected : .predictions(titles)
            }
        }()

        let journal = CycleInsightsSnapshot.Journal(
            flow: logs.flow[today].map(PulseCycleLog.title),
            symptoms: PulseCycleLog.symptoms.filter { (logs.symptoms[today] ?? []).contains($0.id) }.map(\.title))

        let coaching: CycleInsightsSnapshot.Coaching? = {
            guard active, phasesApply, let phase = summary.phase else { return nil }
            return coachingCard(phase: phase, summary: summary, days: r.days, pastPhases: pastPhases)
        }()

        let currentCycle: CycleInsightsSnapshot.CurrentCycle? = {
            guard active, let cd = summary.cycleDay else { return nil }
            return currentCycleChart(r, summary: summary, cycleDay: cd, today: today, phasesApply: phasesApply)
        }()

        let patterns: CycleInsightsSnapshot.Patterns? = menopause
            ? nil : cyclePatterns(summary: summary, byDay: byDay, today: today)

        let summaryRows = CycleSymptomPatterns.summary(
            symptomDays: logs.symptoms, phaseByDay: phasesApply ? pastPhases : [:],
            from: MenstrualCycleModel.shift(today, by: -180) ?? today, to: today, limit: 5)
            .compactMap { row -> CycleInsightsSnapshot.SymptomRow? in
                guard let s = PulseCycleLog.symptom(row.symptom) else { return nil }
                var detail = row.days == 1 ? String(localized: "1 day in the last 6 months")
                                           : String(localized: "\(row.days) days in the last 6 months")
                if let phase = row.phase, row.days >= 3 {
                    detail += " · " + String(localized: "mostly \(PulseCycleText.phaseName(phase))")
                }
                return .init(id: s.id, title: s.title, detail: detail)
            }

        return CycleInsightsSnapshot(
            seq: r.seq, today: today, mode: inputs.mode,
            hasLogs: !logs.starts.isEmpty || !logs.flow.isEmpty || !logs.symptoms.isEmpty,
            earliestLogDay: rangeStart, header: header, months: months,
            initialMonth: months.firstIndex { $0.id == todayMonth } ?? max(0, months.count - 1),
            // The phase legend explains bands, so it shows only when the calendar draws one.
            showsPhaseLegend: phasesApply && infos.contains { $0.phase != nil },
            symptomsToday: symptomsToday, journal: journal, coaching: coaching, currentCycle: currentCycle,
            patterns: patterns, symptomSummary: summaryRows)
    }

    // MARK: Header

    private func header(summary: MenstrualCycleModel.Summary, inputs: PulseCycleInputs, active: Bool,
                        phasesApply: Bool, todayInfo: MenstrualCycleModel.DayInfo?) -> CycleInsightsSnapshot.Header {
        let today = inputs.today
        if inputs.mode == .menopause {
            var subtitle = String(localized: "Symptom tracking")
            let lastBleed = ([inputs.logs.starts.max()] + [inputs.logs.flow.filter { $0.value.isPeriod }.keys.max()])
                .compactMap { $0 }.max()
            if let last = lastBleed, let days = MenstrualCycleModel.days(from: last, to: today), days > 0 {
                subtitle += " • " + (days == 1 ? String(localized: "1 day since your last logged bleed")
                                               : String(localized: "\(days) days since your last logged bleed"))
            }
            return .init(cycleDay: nil, phase: nil, title: String(localized: "Menopause"), subtitle: subtitle,
                         basis: nil, caveat: nil, accessibility: String(localized: "Menopause. \(subtitle)"))
        }

        if active, let cd = summary.cycleDay {
            let dayText = String(localized: "Cycle Day \(cd)")
            let phase = summary.phase
            let title: String? = phasesApply ? phase.map(PulseCycleText.phaseTitle) : nil
            var parts: [String] = []
            if summary.isPeriodDay {
                parts.append(todayInfo?.isLoggedPeriodDay == true ? String(localized: "Logged Period Day")
                                                                   : String(localized: "Predicted Period Day"))
            }
            if let late = summary.daysLate {
                parts.append(late == 1 ? String(localized: "Period is 1 day later than predicted")
                                       : String(localized: "Period is \(late) days later than predicted"))
            } else if let w = summary.nextPeriod {
                parts.append(PulseCycleText.nextPeriod(window: w, today: today))
            }
            let basis: String? = summary.basis.map { basis in
                var text = PulseCycleText.basis(basis)
                if inputs.mode == .perimenopause {
                    text += " · " + String(localized: "wider windows in perimenopause")
                }
                return text
            }
            var caveat: String?
            if inputs.contraception == .hormonal {
                caveat = String(localized: "With hormonal contraception there is no natural cycle to read, so only bleeding is shown.")
            } else if let note = inputs.engine?.note, note.hasPrefix("Your temperature shift came at a different time") {
                // CyclePhaseEngine's cross-check of the latest logged start against the temperature shift.
                caveat = String(localized: "Your skin temperature shifted at a different time than your logged period suggests. Check the date you logged.")
            }
            let subtitle = parts.joined(separator: " • ")
            let spoken = [dayText, title, subtitle, basis].compactMap { $0 }.joined(separator: ". ")
            return .init(cycleDay: dayText, phase: phasesApply ? phase : nil, title: title, subtitle: subtitle,
                         basis: basis, caveat: caveat, accessibility: spoken)
        }

        // No usable logs: the temperature engine, when it reads a phase, is the only voice.
        if phasesApply, let engine = inputs.engine, let phase = PulseCycleText.phase(engine.phase),
           let lo = engine.cycleDayLow, let hi = engine.cycleDayHigh {
            let dayText = lo == hi ? String(localized: "Cycle Day \(lo)") : String(localized: "Cycle Day \(lo)–\(hi)")
            var subtitle = String(localized: "Estimated from your skin temperature")
            if let w = engine.nextPeriodWindow {
                subtitle += " • " + PulseCycleText.nextPeriod(
                    window: MenstrualCycleModel.Window(earliest: w.earliestDay, latest: w.latestDay), today: today)
            }
            let title = PulseCycleText.phaseTitle(phase)
            return .init(cycleDay: dayText, phase: phase, title: title, subtitle: subtitle,
                         basis: String(localized: "Log your period to anchor your cycle day"), caveat: nil,
                         accessibility: "\(dayText). \(title). \(subtitle)")
        }

        let subtitle: String
        if case .stale(let last) = summary.status {
            subtitle = String(localized: "Your last logged period started on \(PulseFormat.dayLabel(last, template: "MMMd")). Log your next period to restart predictions.")
        } else {
            subtitle = String(localized: "Log your period to see your cycle day, phase and predictions.")
        }
        let title = String(localized: "No Phase Predicted")
        return .init(cycleDay: nil, phase: nil, title: title, subtitle: subtitle, basis: nil, caveat: nil,
                     accessibility: "\(title). \(subtitle)")
    }

    /// The engine's next-period window as dashed days, only where the logs predict nothing.
    private func engineWindow(_ inputs: PulseCycleInputs, summary: MenstrualCycleModel.Summary,
                              menopause: Bool) -> Set<String> {
        guard !menopause, summary.status != .active, let w = inputs.engine?.nextPeriodWindow,
              let span = MenstrualCycleModel.days(from: w.earliestDay, to: w.latestDay), span >= 0 else { return [] }
        return Set((0...span).compactMap { MenstrualCycleModel.shift(w.earliestDay, by: $0) })
    }

    // MARK: Calendar

    private func months(infos: [MenstrualCycleModel.DayInfo], today: String, symptoms: [String: Set<String>],
                        engineWindow: Set<String>) -> [CycleInsightsSnapshot.Month] {
        var out: [CycleInsightsSnapshot.Month] = []
        var current: [CycleInsightsSnapshot.Day] = []
        var currentID: String?
        func flush() {
            guard let id = currentID, let first = current.first else { return }
            out.append(.init(id: id, title: PulseCycleDates.monthTitle(first.id, today: today),
                             leadingBlanks: PulseCycleDates.mondayIndex(first.id), days: current))
        }
        for info in infos {
            let monthID = String(info.day.prefix(7))
            if monthID != currentID {
                flush()
                current = []
                currentID = monthID
            }
            let number = Int(info.day.suffix(2)) ?? 0
            let hasSymptoms = !(symptoms[info.day] ?? []).isEmpty
            let predicted = info.isPredictedPeriodDay || (engineWindow.contains(info.day) && info.day > today)
            let spotting = info.flow == .spotting
            var spoken = [PulseFormat.dayLabel(info.day, template: "EEEEMMMMd")]
            if info.day == today { spoken.append(String(localized: "today")) }
            if let p = info.phase { spoken.append(PulseCycleText.phaseTitle(p) + (info.isPredicted ? " " + String(localized: "(predicted)") : "")) }
            if info.isLoggedPeriodDay { spoken.append(String(localized: "period logged")) }
            if predicted { spoken.append(String(localized: "period expected")) }
            if spotting { spoken.append(String(localized: "spotting")) }
            if hasSymptoms { spoken.append(String(localized: "symptoms logged")) }
            current.append(.init(id: info.day, number: number, phase: info.phase, isFuture: info.day > today,
                                 isToday: info.day == today, isLoggedPeriod: info.isLoggedPeriodDay,
                                 isPredictedPeriod: predicted, isSpotting: spotting && !info.isLoggedPeriodDay,
                                 hasSymptoms: hasSymptoms, accessibility: spoken.joined(separator: ", ")))
        }
        flush()
        return out
    }

    // MARK: Phase coaching

    private func coachingCard(phase: PulseCyclePhase, summary: MenstrualCycleModel.Summary, days: [DailyMetric],
                              pastPhases: [String: PulseCyclePhase]) -> CycleInsightsSnapshot.Coaching {
        let bar = MenstrualCycleModel.phaseLengths(cycleLength: summary.modelCycleLength,
                                                   periodLength: summary.modelPeriodLength)
            .map { CycleInsightsSnapshot.Coaching.Segment(phase: $0.phase, days: $0.days) }
        var recovery: [String: Double] = [:], hrv: [String: Double] = [:], rhr: [String: Double] = [:]
        for d in days where pastPhases[d.day] != nil {
            if let v = d.recovery { recovery[d.day] = v }
            if let v = d.avgHrv { hrv[d.day] = v }
            if let v = d.restingHr { rhr[d.day] = Double(v) }
        }
        typealias Metric = CycleInsightsSnapshot.Coaching.Metric
        func metric(id: String, title: String, symbol: String, values: [String: Double], higherIsBetter: Bool,
                    format: (Double) -> String) -> Metric {
            guard let c = CycleMetricPatterns.compare(values: values, phaseByDay: pastPhases, phase: phase) else {
                return Metric(id: id, title: title, symbol: symbol, chip: String(localized: "Calibrating"),
                              kind: .calibrating,
                              detail: String(localized: "Needs more nights logged in this phase"))
            }
            let chip: String
            let kind: Metric.Kind
            switch c.direction {
            case .higher:
                chip = String(localized: "Higher")
                kind = higherIsBetter ? .positive : .negative
            case .lower:
                chip = String(localized: "Lower")
                kind = higherIsBetter ? .negative : .positive
            case .typical:
                chip = String(localized: "Typical")
                kind = .neutral
            }
            return Metric(id: id, title: title, symbol: symbol, chip: chip, kind: kind,
                          detail: String(localized: "\(format(c.phaseMean)) vs \(format(c.overallMean)) across your cycle"))
        }
        let metrics = [
            metric(id: "recovery", title: String(localized: "Recovery"), symbol: "bolt.heart", values: recovery,
                   higherIsBetter: true) { "\(PulseDisplay.displayedPercent($0))%" },
            metric(id: "hrv", title: String(localized: "HRV"), symbol: "waveform.path.ecg", values: hrv,
                   higherIsBetter: true) { String(localized: "\(PulseFormat.whole($0)) ms") },
            metric(id: "rhr", title: String(localized: "Resting HR"), symbol: "heart", values: rhr,
                   higherIsBetter: false) { String(localized: "\(PulseFormat.whole($0)) bpm") },
        ]
        return .init(phase: phase, bar: bar, paragraph: PulseCycleText.coaching(phase), metrics: metrics)
    }

    // MARK: Your Current Cycle

    private func currentCycleChart(_ r: PulseRequest, summary: MenstrualCycleModel.Summary, cycleDay: Int,
                                   today: String, phasesApply: Bool) -> CycleInsightsSnapshot.CurrentCycle {
        let starts = summary.cycles.map(\.start)
        func phase(_ cd: Int) -> PulseCyclePhase? {
            guard phasesApply else {
                return cd <= summary.modelPeriodLength ? .menstrual : nil
            }
            return MenstrualCycleModel.phaseFor(cycleDay: cd, cycleLength: summary.modelCycleLength,
                                                periodLength: summary.modelPeriodLength)
        }
        let fahrenheit = r.prefs.fahrenheit
        var skin: [String: Double] = [:], rhr: [String: Double] = [:], hrv: [String: Double] = [:]
        var recovery: [String: Double] = [:]
        for d in r.days {
            if let v = d.skinTempDevC { skin[d.day] = fahrenheit ? v * 1.8 : v }
            if let v = d.restingHr { rhr[d.day] = Double(v) }
            if let v = d.avgHrv { hrv[d.day] = v }
            if let v = d.recovery { recovery[d.day] = v }
        }
        typealias Series = CycleInsightsSnapshot.CurrentCycle.Series
        typealias Bar = CycleInsightsSnapshot.CurrentCycle.Bar
        func series(id: String, title: String, symbol: String, unit: String, decimals: Int,
                    values: [String: Double], relative: Bool) -> Series {
            let s = CycleMetricPatterns.cycleSeries(values: values, cycleStarts: starts, today: today,
                                                    relativeToZero: relative)
            return Series(id: id, title: title, symbol: symbol, unit: unit, decimals: decimals,
                          current: (s?.current ?? []).map { Bar(cycleDay: $0.cycleDay, value: $0.value, phase: phase($0.cycleDay)) },
                          expected: s?.expected ?? [],
                          average: (s?.expected ?? []).map { Bar(cycleDay: $0.cycleDay, value: $0.value, phase: phase($0.cycleDay)) },
                          previousCycles: s?.previousCycles ?? 0)
        }
        let all = [
            series(id: "skin", title: String(localized: "Skin temp"), symbol: "thermometer.medium",
                   unit: fahrenheit ? "°F" : "°C", decimals: 2, values: skin, relative: true),
            series(id: "rhr", title: String(localized: "RHR"), symbol: "heart", unit: "bpm", decimals: 0,
                   values: rhr, relative: false),
            series(id: "hrv", title: String(localized: "HRV"), symbol: "waveform.path.ecg", unit: "ms", decimals: 0,
                   values: hrv, relative: false),
            series(id: "recovery", title: String(localized: "Recovery"), symbol: "bolt.heart", unit: "%",
                   decimals: 0, values: recovery, relative: false),
        ]
        let lastExpected = all.flatMap(\.expected).map(\.cycleDay).max() ?? 0
        let axisMax = min(45, max(summary.modelCycleLength + 2, cycleDay + 1, lastExpected))
        let nextStart = summary.daysLate == nil ? summary.modelCycleLength + 1 : nil
        return .init(series: all, todayCycleDay: cycleDay, nextStartCycleDay: nextStart, axisMax: axisMax,
                     paragraph: PulseCycleText.currentCycle(summary.phase ?? .follicular, phasesApply: phasesApply))
    }

    // MARK: Your Cycle Patterns

    private func cyclePatterns(summary: MenstrualCycleModel.Summary,
                               byDay: [String: MenstrualCycleModel.DayInfo],
                               today: String) -> CycleInsightsSnapshot.Patterns? {
        guard !summary.cycles.isEmpty else { return nil }
        let t = summary.typical
        typealias Stat = CycleInsightsSnapshot.Patterns.Stat
        let dash = "--"
        let stats = [
            Stat(id: "period", title: String(localized: "Period length"), value: t.periodLength.map(String.init) ?? dash,
                 unit: String(localized: "days")),
            Stat(id: "cycle", title: String(localized: "Cycle length"), value: t.cycleLength.map(String.init) ?? dash,
                 unit: String(localized: "days")),
            Stat(id: "variation", title: String(localized: "Cycle variation"),
                 value: t.cycleVariation.map(String.init) ?? dash, unit: String(localized: "days")),
        ]
        let footnote: String? = {
            if t.cyclesUsed == 0 { return String(localized: "Log your next period to see your typical cycle length.") }
            if t.cyclesUsed == 1 { return String(localized: "Cycle variation needs two complete cycles.") }
            if t.periodLength == nil { return String(localized: "Log your flow each day of your period to see its length.") }
            return nil
        }()

        typealias Row = CycleInsightsSnapshot.Patterns.CycleRow
        typealias Dot = CycleInsightsSnapshot.Patterns.Dot
        func dots(from start: String, count: Int) -> [Dot] {
            (0..<max(0, count)).compactMap { offset in
                guard let day = MenstrualCycleModel.shift(start, by: offset) else { return nil }
                let info = byDay[day]
                return Dot(phase: info?.phase, isFuture: day > today,
                           isPeriod: info?.isLoggedPeriodDay == true || info?.isPredictedPeriodDay == true)
            }
        }
        var rows: [Row] = []
        if summary.status == .active, let current = summary.cycles.last, let cd = summary.cycleDay {
            let title = cd == 1 ? String(localized: "Current Cycle · 1 Day") : String(localized: "Current Cycle · \(cd) Days")
            rows.append(Row(id: current.start, title: title,
                            range: "\(PulseFormat.dayLabel(current.start, template: "MMMd")) – " + String(localized: "Today"),
                            dots: dots(from: current.start, count: min(45, max(cd, summary.modelCycleLength))),
                            note: nil))
        }
        for cycle in summary.cycles.reversed() {
            guard let length = cycle.length, rows.count < 7 else { continue }
            let end = MenstrualCycleModel.shift(cycle.start, by: length - 1) ?? cycle.start
            rows.append(Row(id: cycle.start, title: String(localized: "\(length) Days"),
                            range: "\(PulseFormat.dayLabel(cycle.start, template: "MMMd")) – \(PulseFormat.dayLabel(end, template: "MMMd"))",
                            dots: dots(from: cycle.start, count: min(45, length)),
                            note: cycle.isPlausible ? nil : String(localized: "Not counted in your typical cycle")))
        }
        return .init(typical: stats, footnote: footnote, cycles: rows)
    }
}

// MARK: - Day-key calendar helpers (UTC, like every day key)

enum PulseCycleDates {
    private static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return c
    }()

    /// "2026-10-01" for any day in October 2026.
    static func monthStart(_ day: String) -> String { String(day.prefix(8)) + "01" }

    /// The month's last day key.
    static func monthEnd(_ monthStart: String) -> String {
        guard let date = PulseCycleDates.date(monthStart),
              let range = utc.range(of: .day, in: .month, for: date) else { return monthStart }
        return MenstrualCycleModel.shift(monthStart, by: range.count - 1) ?? monthStart
    }

    /// 0 for Monday … 6 for Sunday.
    static func mondayIndex(_ day: String) -> Int {
        guard let date = date(day) else { return 0 }
        return (utc.component(.weekday, from: date) + 5) % 7
    }

    /// The month's name, with the year when it is not today's year.
    static func monthTitle(_ day: String, today: String) -> String {
        day.prefix(4) == today.prefix(4) ? PulseFormat.dayLabel(day, template: "MMMM")
                                         : PulseFormat.dayLabel(day, template: "MMMMyyyy")
    }

    /// The day key's UTC-midnight instant.
    static func date(_ day: String) -> Date? {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// Monday-first weekday initials in the app language ("MON" … "SUN" once uppercased).
    static var weekdaySymbols: [String] {
        let f = DateFormatter()
        f.locale = AppLanguage.activeLocale
        let symbols = f.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return Array(symbols[1...]) + [symbols[0]]
    }
}
#endif
