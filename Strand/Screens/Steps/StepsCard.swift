import SwiftUI
import StrandDesign
import StrandAnalytics

/// A compact, self-contained steps card: today's ring against the goal, the count, the goal and source, and
/// a small hour-by-hour strip. Drop it into any screen whose environment carries the app's `Repository` (every
/// app root injects it): the card loads its own data through `StepsService`, needs no parameters, and depends
/// on nothing in the screen around it.
///
/// Tapping pushes `StepsView` onto the enclosing `NavigationStack`. A host that routes by value (a tab root
/// whose stack is bound to a `NavigationPath`, so a tab re-tap can pop it) passes `onTap` instead and pushes
/// its own route, e.g. `TabRoute.steps(day: nil)`.
///
/// It reads the same resolved day as the Steps screen and Today's tile, so the three always agree, and it
/// follows the live pedometer total while the app is open.
struct StepsCard: View {
    /// Accent for the ring, bars and surface wash.
    var tint: Color = StrandPalette.metricCyan
    var cornerRadius: CGFloat = 20
    /// 0–1 fade of the card surface (the "Card transparency" setting); content stays opaque.
    var surfaceOpacity: Double = 1
    /// Custom navigation. nil pushes `StepsView` through a `NavigationLink`.
    var onTap: (() -> Void)? = nil

    @EnvironmentObject private var repo: Repository
    @ObservedObject private var service = StepsService.shared
    @AppStorage(StepsPrefs.goalKey) private var goalRaw = StepGoal.defaultGoal

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { content }
                    .buttonStyle(LiquidPressStyle())
            } else {
                NavigationLink { StepsView() } label: { content }
                    .buttonStyle(LiquidPressStyle())
            }
        }
        .task { service.activate(repo: repo) }
    }

    private var content: some View {
        let snapshot = service.snapshot
        let today = snapshot.todayResolved
        let goal = StepGoal.clamp(goalRaw)
        let chart = StepsHourly.chart(daySource: today?.source, dayTotal: today?.steps, hours: snapshot.todayHours,
                                      currentHour: Calendar.current.component(.hour, from: Date()))
        let percent = today.map { StepGoal.percent(steps: $0.steps, goal: goal) }
        return HStack(spacing: 14) {
            GlowRing(fraction: today.map { StepGoal.ringFraction(steps: $0.steps, goal: goal) } ?? 0,
                     value: Double(percent ?? 0),
                     format: { value in percent == nil ? "—" : "\(Int(value.rounded()))%" },
                     color: tint, diameter: 60, lineWidth: 6)
            VStack(alignment: .leading, spacing: 3) {
                Text("Steps").strandOverline()
                Text(today.map { StepsFormat.count($0.steps) } ?? "—")
                    .font(StrandFont.number(26))
                    .foregroundStyle(StrandPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle(today: today, goal: goal))
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 8)
            if let chart {
                StepsMiniHourlyBars(bars: chart.bars, highlightHour: chart.currentHour, tint: tint)
                    .frame(width: 84)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(StrandPalette.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NoopPanelSurface(tint: tint, cornerRadius: cornerRadius, surfaceOpacity: surfaceOpacity))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Steps"))
        .accessibilityValue(spoken(today: today, goal: goal))
        .accessibilityHint(String(localized: "Opens your steps"))
    }

    private func subtitle(today: ResolvedStepDay?, goal: Int) -> String {
        guard let today else {
            return service.phoneAccess == .notDetermined
                ? String(localized: "Tap to count steps with this iPhone")
                : String(localized: "Goal \(StepsFormat.count(goal)) · nothing counted yet")
        }
        return String(localized: "of \(StepsFormat.count(goal)) · \(today.source.displayName)")
    }

    private func spoken(today: ResolvedStepDay?, goal: Int) -> String {
        guard let today else { return subtitle(today: nil, goal: goal) }
        return String(localized: "\(StepsFormat.count(today.steps)) of \(StepsFormat.count(goal)) today, from \(today.source.displayName)")
    }
}
