#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Calibration Timeline (WHOOP_UI_SPEC §3.1 item 10), pushed from Looking Ahead: what unlocks as the strap
/// learns the wearer, counted from their own data. ZENO's thresholds [Z], not WHOOP's table: Recovery
/// scores after 4 nights of HRV (`Baselines.minNightsSeed`), My Dashboard's baselines and the weekly views
/// fill in over the first 7 scored days, and personal ranges are trusted after 14 (`Baselines.minNightsTrust`,
/// the Health Monitor's "Your typical range").
///
/// Owned by group "home".
struct PulseCalibrationTimelineView: View {
    /// Rebuilt: Looking Ahead opens this.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model

    private struct Milestone: Identifiable {
        let id: String
        let title: String
        let body: String
        let done: Int
        let of: Int
    }

    private var milestones: [Milestone] {
        guard let home = model.home else { return [] }
        let scored = home.scoredDays
        let nights: Int
        if case .calibrating(let n, _) = home.recovery.state {
            nights = n
        } else {
            nights = scored > 0 ? Baselines.minNightsSeed : 0
        }
        return [
            Milestone(id: "recovery", title: String(localized: "Recovery"),
                      body: String(localized: "Your first Recovery score, once your strap has learned your heart rate variability over \(Baselines.minNightsSeed) nights."),
                      done: min(nights, Baselines.minNightsSeed), of: Baselines.minNightsSeed),
            Milestone(id: "week", title: String(localized: "Your first week"),
                      body: String(localized: "My Dashboard's 30-day baselines, Strain & Recovery and the week in review fill in as your first 7 days score."),
                      done: min(scored, 7), of: 7),
            Milestone(id: "trusted", title: String(localized: "Personal ranges"),
                      body: String(localized: "After \(Baselines.minNightsTrust) scored nights, the Health Monitor judges your vitals against your own typical range."),
                      done: min(scored, Baselines.minNightsTrust), of: Baselines.minNightsTrust),
        ]
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Calibration Timeline"), coach: .button,
                            ready: model.home != nil) {
            Text(String(localized: "Wear your strap to bed every night. Each night teaches ZENO more about your normal, and these unlock along the way."))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
            ForEach(milestones) { milestone in
                HStack(alignment: .center, spacing: PulseTheme.Space.m) {
                    VStack(alignment: .leading, spacing: PulseTheme.Space.xs) {
                        HStack(spacing: PulseTheme.Space.xs) {
                            PulseCardTitle(milestone.title)
                            if milestone.done >= milestone.of {
                                PulseStatusChip(String(localized: "Unlocked"), kind: .positive)
                                    .fixedSize()
                            }
                        }
                        Text(milestone.body)
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    PulseGoalRing(kind: .count(done: milestone.done, target: milestone.of), diameter: 54)
                }
                .padding(PulseTheme.Layout.cardPadding + 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .pulseCardBackground()
                .accessibilityElement(children: .combine)
                .accessibilityValue(String(localized: "\(milestone.done) of \(milestone.of)"))
            }
        }
    }
}
#endif
