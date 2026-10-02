#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Snapshot → dial content
//
// The ONE place a score dial's snapshot becomes what the dial components draw, so the Home dials, the
// sticky mini rings and the deep-dive rings can never show one score two ways.

extension PulseDialData {
    /// The dial's content. `target` adds the Strain dial's optimal-range band and its midpoint tick, and is
    /// ignored unless Recovery scored for the day itself (WHOOP draws neither before Recovery scores, and
    /// a band from an earlier night's Recovery would imply a target the day never had).
    func dialContent(target: PulseStrainTarget? = nil, label: String? = nil) -> PulseDialContent {
        let name = label ?? score.displayName
        switch state {
        case .calibrating:
            // §2.9: "--%" with CALIBRATING under the label; the nights count lives in Looking Ahead.
            return .percent(label: name, percent: nil, color: PulseTheme.textTertiary,
                            caption: String(localized: "Calibrating").uppercased())
        case .noData:
            return score == .strain
                ? .strain(label: name, value: nil, optimalRange: nil, target: nil)
                : .percent(label: name, percent: nil, color: color)
        case .scored, .carried:
            let caption = self.caption
            if score == .strain {
                let ownTarget = target.flatMap { $0.fromCarriedRecovery ? nil : $0 }
                return .strain(label: name, value: value, optimalRange: ownTarget?.range,
                               target: ownTarget?.targetValue, caption: caption)
            }
            return .percent(label: name, percent: value, color: color, caption: caption)
        }
    }
}

extension PulseStrainTarget {
    /// The Strain Target WHOOP marks with the dial's white tick: the middle of the optimal range
    /// (7 / 12 / 16 for ZENO's Restore / Maintain / Push ranges).
    var targetValue: Double { (range.lowerBound + range.upperBound) / 2 }
}

/// Sleep's Poor / Sufficient / Optimal reading, as `PulseMiniSegments` lights it.
enum PulseSleepBand {
    /// The reading's word, as VoiceOver says it.
    static func name(_ index: Int) -> String {
        switch index {
        case 0: return String(localized: "Poor")
        case 1: return String(localized: "Sufficient")
        default: return String(localized: "Optimal")
        }
    }

    /// 0 Poor (under 70%), 1 Sufficient (70–84%), 2 Optimal (85% and up), judged on the whole percent
    /// printed; nil without a value.
    static func index(percent: Double?) -> Int? {
        guard let percent else { return nil }
        let shown = PulseDisplay.displayedPercent(percent)
        if shown >= 85 { return 2 }
        if shown >= 70 { return 1 }
        return 0
    }
}

extension PulseSleepContributor {
    /// The contributor's Poor / Sufficient / Optimal reading.
    var performanceBand: Int? { PulseSleepBand.index(percent: percent) }
}
#endif
