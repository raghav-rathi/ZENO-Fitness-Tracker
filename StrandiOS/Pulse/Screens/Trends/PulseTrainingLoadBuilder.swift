#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The Training Load page from `TrainingLoadEngine` (the classic card's model, CTL / ATL / TSB): pure, so it
/// runs inside the snapshot builder's actor. Descriptive only, as the engine is: none of it feeds Recovery.
enum PulseTrainingLoadBuilder {

    static let ranges: [PulseTrendMath.Range] = [.month, .sixMonths, .year, .all]

    static func snapshot(seq: Int, result: TrainingLoadEngine.Result, today: String,
                         range requested: PulseTrendMath.Range) -> TrainingLoadSnapshot {
        let range = ranges.contains(requested) ? requested : .month
        let config = TrainingLoadEngine.Configuration.standard
        let points = result.points.filter { $0.day <= today }
        let byDay = Dictionary(points.map { ($0.day, $0) }, uniquingKeysWith: { _, last in last })
        let anchor = points.last?.day ?? today
        let window = PulseTrendMath.window(range, anchor: anchor, earliest: points.first?.day)
            ?? PulseTrendMath.Window(start: anchor, end: anchor, page: 0, dayCount: 1, hasOlder: false)
        let keys = window.dayKeys
        let columns: [PulseTrendChartModel.Column] = keys.map { k in
            let p = byDay[k]
            return PulseTrendChartModel.Column(id: k, value: p?.chronicLoad, secondary: p?.acuteLoad,
                                               color: PulseTheme.textPrimary)
        }
        let values = columns.compactMap(\.value) + columns.compactMap(\.secondary)
        let (domain, ticks) = scale(values)
        let latest = points.last
        let status: String?
        switch result.state {
        case .unavailable:
            status = String(localized: "Training load needs \(config.minimumDays) days in a row with a Strain to begin; \(result.contiguousDays) so far.")
        case .building:
            status = String(localized: "Building: \(result.contiguousDays) of \(config.establishedDays) days. Fitness settles once six weeks are in.")
        case .established:
            status = nil
        }
        let form = latest.map { signed($0.balance) } ?? "--"
        let word: String
        if let b = latest?.balance {
            word = abs(b) < 0.5 ? String(localized: "Balanced")
                : (b > 0 ? String(localized: "Fitness above fatigue") : String(localized: "Fatigue above fitness"))
        } else {
            word = ""
        }
        let insight: String
        if let latest {
            let ctl = PulseFormat.oneDecimal(latest.chronicLoad), atl = PulseFormat.oneDecimal(latest.acuteLoad)
            if latest.balance < -0.5 {
                insight = String(localized: "Your 7-day fatigue (\(atl)) is above your 42-day fitness (\(ctl)): you are carrying more recent load than you are used to.")
            } else if latest.balance > 0.5 {
                insight = String(localized: "Your 42-day fitness (\(ctl)) is above your 7-day fatigue (\(atl)): your recent load is lighter than you are used to.")
            } else {
                insight = String(localized: "Your 42-day fitness (\(ctl)) and 7-day fatigue (\(atl)) are level: your recent load matches what you are used to.")
            }
        } else {
            insight = status ?? ""
        }
        let labels: [PulseTrendChartModel.XLabel]
        if range == .month {
            labels = keys.enumerated().compactMap { i, k in
                (keys.count - 1 - i) % 7 == 0
                    ? .init(index: i, line1: PulseFormat.dayLabel(k, template: "MMM"), line2: PulseFormat.dayLabel(k, template: "d"))
                    : nil
            }
        } else {
            let all = keys.enumerated().compactMap { i, k -> PulseTrendChartModel.XLabel? in
                k.hasSuffix("-01") && i > 0 ? .init(index: i, line1: PulseFormat.dayLabel(k, template: "MMM")) : nil
            }
            let step = all.count > 7 ? Int((Double(all.count) / 7).rounded(.up)) : 1
            labels = all.enumerated().compactMap { $0.offset % step == 0 ? $0.element : nil }
        }
        let chart = PulseTrendChartModel(
            mode: .dualLine, columns: columns, yDomain: domain, yTicks: ticks, xLabels: labels, barWidth: 7,
            lineColor: PulseTheme.textPrimary, secondaryColor: PulseTheme.strain,
            dimmed: false, showsMarkers: false, marksLastPointOnly: false,
            emptyMessage: columns.contains { $0.value != nil } ? nil : String(localized: "No training load yet"),
            accessibilitySummary: latest.map {
                String(localized: "Training load. Fitness \(PulseFormat.oneDecimal($0.chronicLoad)), fatigue \(PulseFormat.oneDecimal($0.acuteLoad)), form \(signed($0.balance))")
            } ?? String(localized: "Training load, not enough days yet"))
        let stats: [TrainingLoadSnapshot.Stat] = [
            .init(id: "ctl", title: String(localized: "Fitness (CTL)"), value: latest.map { PulseFormat.oneDecimal($0.chronicLoad) } ?? "--"),
            .init(id: "atl", title: String(localized: "Fatigue (ATL)"), value: latest.map { PulseFormat.oneDecimal($0.acuteLoad) } ?? "--"),
            .init(id: "days", title: String(localized: "Days modelled"), value: "\(result.contiguousDays)")
        ]
        return TrainingLoadSnapshot(seq: seq, range: range, isAvailable: result.isAvailable, status: status,
                                    form: form, formWord: word, insight: insight, chart: chart, stats: stats)
    }

    static func signed(_ v: Double) -> String {
        let text = PulseFormat.oneDecimal(abs(v))
        if text == PulseFormat.oneDecimal(0) { return text }
        return (v > 0 ? "+" : "-") + text
    }

    /// Around both lines, four even whole-number intervals from 0 or just under the lowest value.
    private static func scale(_ values: [Double]) -> (ClosedRange<Double>, [PulseTrendChartModel.Tick]) {
        guard let lo = values.min(), let hi = values.max() else { return (0...1, []) }
        let span = max(hi - lo, 4)
        let bottom = max(0, ((lo - span * 0.25)).rounded(.down))
        let step = max(1, ((hi + span * 0.25 - bottom) / 4).rounded(.up))
        let ticks = (0...4).map { bottom + Double($0) * step }
        return (bottom...(bottom + 4 * step), ticks.map { .init(value: $0, label: PulseFormat.whole($0)) })
    }
}
#endif
