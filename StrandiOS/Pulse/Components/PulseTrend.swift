#if os(iOS)
import SwiftUI

// MARK: - Trend glyphs and delta chips (WHOOP_UI_SPEC §2.6 item 9, §2.7 "Delta chip colours")
//
// The colour of ▲/▼ means GOOD or BAD, never up or down: every non-zero change is coloured by whether it
// is favourable for that metric (teal) or not (orange), even a one-point change. A grey ● replaces the
// arrow when today equals the baseline, and metrics with no good direction (weight) always draw grey.

/// Which direction of a metric is better.
enum PulseMetricPolarity: Equatable {
    case higherIsBetter
    case lowerIsBetter
    /// No good direction: arrows draw grey (weight, calories, and on Trend View chips Recovery and Strain).
    case neutral

    /// The spec's table: HRV↑, RHR↓, RR↓, Sleep Performance↑, Sleep Consistency↑, Hours↑, Restorative↑,
    /// Sleep Needed↓, Sleep Debt↓, Sleep Stress↓, Steps↑, Zones↑, Strength time↑, Recovery↑, VO₂↑.
    /// Keys are the catalog / series keys the app uses; unknown keys are neutral.
    static func forMetric(_ key: String) -> PulseMetricPolarity {
        switch key {
        case "hrv", "avg_hrv", "sleep", "sleep_performance", "sleep_consistency", "consistency", "sleep_hours",
             "hours", "asleep", "restorative", "restorative_sleep", "steps", "hr_zones_1_3", "hr_zones_4_5",
             "zones", "strength_time", "recovery", "vo2max", "vo2max_est", "sleep_efficiency", "efficiency":
            return .higherIsBetter
        case "rhr", "resting_hr", "resp", "resp_rate", "respiratory_rate", "sleep_need", "sleep_needed",
             "sleep_debt", "sleep_stress", "stress":
            return .lowerIsBetter
        default:
            return .neutral
        }
    }
}

/// A change against a reference, and how to read it.
struct PulseTrend: Equatable {
    enum Direction: Equatable { case up, down, flat }
    enum Judgement: Equatable {
        case favourable, unfavourable
        /// A change on a metric with no good direction.
        case neutral
        /// No change: today equals the reference.
        case unchanged
    }

    let direction: Direction
    let polarity: PulseMetricPolarity

    init(direction: Direction, polarity: PulseMetricPolarity) {
        self.direction = direction
        self.polarity = polarity
    }

    /// From a signed difference. Equal PRINTED values should be passed as a zero delta: the dot appears
    /// only when today equals the baseline as shown.
    init(delta: Double, polarity: PulseMetricPolarity) {
        let direction: Direction = delta > 0 ? .up : (delta < 0 ? .down : .flat)
        self.init(direction: direction, polarity: polarity)
    }

    var judgement: Judgement {
        switch (direction, polarity) {
        case (.flat, _): return .unchanged
        case (_, .neutral): return .neutral
        case (.up, .higherIsBetter), (.down, .lowerIsBetter): return .favourable
        default: return .unfavourable
        }
    }

    /// The glyph colour: teal good, orange bad, grey otherwise.
    var color: Color {
        switch judgement {
        case .favourable: return PulseTheme.positive
        case .unfavourable: return PulseTheme.negative
        case .neutral: return PulseTheme.neutral
        case .unchanged: return PulseTheme.baselineDot
        }
    }

    /// Spoken form, e.g. "up, favourable".
    var accessibilityDescription: String {
        let way: String
        switch direction {
        case .up: way = String(localized: "up")
        case .down: way = String(localized: "down")
        case .flat: return String(localized: "no change")
        }
        switch judgement {
        case .favourable: return String(localized: "\(way), favourable")
        case .unfavourable: return String(localized: "\(way), unfavourable")
        default: return way
        }
    }
}

/// A small solid triangle pointing up or down.
struct PulseTriangle: Shape {
    var pointsUp: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        if pointsUp {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        p.closeSubpath()
        return p
    }
}

/// ▲ / ▼ (6 pt) coloured by good / bad, or a grey ● (4 pt) when unchanged.
struct PulseTrendGlyph: View {
    let trend: PulseTrend
    var size: CGFloat = 6

    var body: some View {
        Group {
            switch trend.direction {
            case .flat:
                Circle().fill(trend.color).frame(width: size * 0.7, height: size * 0.7)
            case .up, .down:
                PulseTriangle(pointsUp: trend.direction == .up)
                    .fill(trend.color)
                    .frame(width: size, height: size * 0.82)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(trend.accessibilityDescription)
    }
}

/// A Trend View delta chip: "▲ 12%" in green on dark green, orange on dark amber, or grey on slate
/// (radius 4, 11 pt Bold). Recovery, Day Strain and Calories are grey in every capture: pass a neutral
/// polarity for those.
struct PulseDeltaChip: View {
    let text: String
    let trend: PulseTrend

    private var colors: (text: Color, fill: Color) {
        switch trend.judgement {
        case .favourable: return (PulseTheme.Delta.favourableText, PulseTheme.Delta.favourableFill)
        case .unfavourable: return (PulseTheme.Delta.unfavourableText, PulseTheme.Delta.unfavourableFill)
        case .neutral, .unchanged: return (PulseTheme.Delta.neutralText, PulseTheme.Delta.neutralFill)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            switch trend.direction {
            case .flat:
                Circle().fill(colors.text).frame(width: 5, height: 5)
            case .up, .down:
                PulseTriangle(pointsUp: trend.direction == .up)
                    .fill(colors.text)
                    .frame(width: 7, height: 6)
            }
            Text(text)
                .font(.system(size: 11, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(colors.text)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular).fill(colors.fill))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text), \(trend.accessibilityDescription)")
    }
}
#endif
