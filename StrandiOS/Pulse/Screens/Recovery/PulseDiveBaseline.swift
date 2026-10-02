#if os(iOS)
import Foundation
import SwiftUI
import StrandAnalytics

// MARK: - What the Recovery and Strain dive builds share (group "recovery-strain")
//
// Both dives print each contributor against its mean over the 30 days before the day ("▲▼ Today vs. last
// 30 days", WHOOP_UI_SPEC §3.4 item 3, §3.5 item 3), and both draw a week of day-keyed values. These are
// the one place that rule lives, so the two screens cannot drift apart.

enum PulseDiveBaseline {
    /// Days of history a 30-day average needs before a row prints one (and its arrow).
    static let minimumDays = 5

    /// A callout row: `value` against its mean over the 30 days before `dayKey`.
    ///
    /// The arrow follows the PRINTED figures (§2.6 item 9): any difference that shows is coloured good or
    /// bad, and a grey dot appears only when the value and the average print the same. With fewer than
    /// `minimumDays` days of history the row shows its value alone: no baseline, no arrow.
    ///
    /// - Parameters:
    ///   - text: how the value and the average print ("65", "74%", "1:53").
    ///   - spoken: the same figure for VoiceOver ("65 milliseconds", "1 hour 53 minutes").
    static func contributor(id: String, symbol: String, title: String, value: Double?, dayKey: String?,
                            history: [(day: String, value: Double)], polarity: PulseMetricPolarity,
                            route: PulseRoute?, text: (Double) -> String,
                            spoken: (Double) -> String) -> PulseDiveContributor {
        guard let value, value.isFinite else {
            return PulseDiveContributor(id: id, symbol: symbol, title: title, value: "--", baseline: nil,
                                        trend: nil, route: route,
                                        spoken: String(localized: "\(title), no data"))
        }
        let shown = text(value)
        let mean = dayKey.flatMap { key in
            PulseDisplay.compare(value: value, history: history, dayKey: key, windowDays: 30,
                                 minSamples: minimumDays)?.reference
        }
        guard let mean else {
            return PulseDiveContributor(id: id, symbol: symbol, title: title, value: shown, baseline: nil,
                                        trend: nil, route: route,
                                        spoken: String(localized: "\(title), \(spoken(value))"))
        }
        let printedMean = text(mean)
        let direction: PulseTrend.Direction = shown == printedMean ? .flat : (value > mean ? .up : .down)
        let trend = PulseTrend(direction: direction, polarity: polarity)
        return PulseDiveContributor(
            id: id, symbol: symbol, title: title, value: shown, baseline: printedMean, trend: trend, route: route,
            spoken: String(localized: "\(title), \(spoken(value)), 30-day average \(spoken(mean)), \(trend.accessibilityDescription)"))
    }

    /// "above" / "below" / "in line with": how a row's value reads against its 30-day average, for a
    /// sentence. nil without an average.
    static func relation(_ row: PulseDiveContributor) -> String? {
        guard let trend = row.trend else { return nil }
        switch trend.direction {
        case .up: return String(localized: "above")
        case .down: return String(localized: "below")
        case .flat: return String(localized: "in line with")
        }
    }

    /// A duration in minutes as VoiceOver should say it: "1 hour 53 minutes", "9 minutes".
    static func spokenDuration(_ minutes: Double) -> String {
        let total = max(0, Int(minutes.rounded()))
        let h = total / 60
        let m = total % 60
        if h == 0 { return String(localized: "\(m) minutes") }
        if m == 0 { return h == 1 ? String(localized: "1 hour") : String(localized: "\(h) hours") }
        return h == 1 ? String(localized: "1 hour \(m) minutes") : String(localized: "\(h) hours \(m) minutes")
    }
}

/// A week of day keys ending on the dive's day, and the chart data drawn from it.
enum PulseDiveWeek {
    /// The seven day keys ending on `dayKey`, oldest first.
    static func keys(endingOn dayKey: String) -> [String] {
        PulseDisplay.trailingDayKeys(endingOn: dayKey, count: 7)
    }

    /// One bar or point per day; a day without a value is a gap, never a zero.
    static func data(_ keys: [String], value: (String) -> Double?, color: (Double) -> Color,
                     label: (Double) -> String) -> [PulseChartDatum] {
        keys.map { key in
            let v = value(key)
            return PulseChartDatum(id: key, label: PulseWeekLabels.weekday(key), sublabel: PulseWeekLabels.dayNumber(key),
                                   value: v, color: v.map(color) ?? PulseTheme.strain, valueLabel: v.map(label))
        }
    }
}
#endif
