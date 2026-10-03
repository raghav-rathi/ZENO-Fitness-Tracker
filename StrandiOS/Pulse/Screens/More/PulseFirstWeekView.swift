#if os(iOS)
import SwiftUI
import StrandAnalytics

/// First Week with ZENO (WHOOP_UI_SPEC §3.31 [Z]), pushed from the FIRST WEEK card (the first seven
/// days) or its SUPPORT row: six first steps, each a row with its check state (WHOOP's "Getting Started"
/// checklist, with "Import your history" in place of joining a team).
///
/// A step is checked only by what the store shows (an activity logged, an alarm armed, a journal entry,
/// imported history) or, for the two "look at" steps, by the wearer opening them from here. Nothing is
/// checked to make the list look finished.
struct PulseFirstWeekView: View {
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @EnvironmentObject private var repo: Repository
    @AppStorage("behavior.smartAlarmEnabled") private var strapAlarmOn = false
    @AppStorage("windDown.enabled") private var windDownOn = false
    @AppStorage("pulse.firstWeek.sleepOpened") private var sleepOpened = false
    @AppStorage("pulse.firstWeek.activityOpened") private var activityOpened = false
    @State private var snapshot: FirstWeekSnapshot?

    private var steps: [Step] {
        [Step(id: "activity", symbol: "figure.run", title: String(localized: "Track an activity"),
              subtitle: String(localized: "Start one, or log one you did"), done: snapshot?.hasActivity ?? false),
         Step(id: "sleep", symbol: "moon.zzz", title: String(localized: "Analyze your Sleep Performance"),
              subtitle: String(localized: "What last night's score is made of"), done: sleepOpened),
         Step(id: "details", symbol: "chart.xyaxis.line", title: String(localized: "View your activity details"),
              subtitle: String(localized: "Heart rate and Strain for one session"), done: activityOpened),
         Step(id: "alarm", symbol: "alarm", title: String(localized: "Set up your strap alarm"),
              subtitle: String(localized: "A silent buzz to wake you"), done: strapAlarmOn || windDownOn),
         Step(id: "journal", symbol: "book.closed", title: String(localized: "Set up your daily journal"),
              subtitle: String(localized: "Answer today's questions once"), done: snapshot?.hasJournal ?? false),
         Step(id: "import", symbol: "square.and.arrow.down", title: String(localized: "Import your history"),
              subtitle: String(localized: "A WHOOP export or Apple Health"),
              done: repo.freshness.importedDays > 0 || repo.freshness.appleDays > 0)]
    }

    var body: some View {
        let steps = steps
        let done = steps.filter(\.done).count
        PulseScreenScaffold(title: String(localized: "First week"), spacing: 0, topPadding: 8) {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(localized: "First Week with ZENO"))
                    .pulseText(.pageTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(String(localized: "Six short steps to get the most from your strap while your baselines learn you."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "\(done) of \(steps.count) done"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(PulseTheme.track)
                        Capsule().fill(PulseTheme.positive)
                            .frame(width: geo.size.width * CGFloat(done) / CGFloat(max(1, steps.count)))
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 4)
            .padding(.top, 24)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "\(done) of \(steps.count) steps done"))
            VStack(spacing: PulseTheme.Row.listGap) {
                ForEach(steps) { step in
                    MoreButtonRow(symbol: step.symbol, title: step.title, subtitle: step.subtitle,
                                  trailing: .check(step.done)) { open(step) }
                }
            }
            .padding(.top, 24)
        }
        .task(id: model.healthKey) {
            if let built = await model.build(dayOffset: 0, { builder, request in await builder.firstWeek(request) }) {
                snapshot = built
            }
        }
    }

    private func open(_ step: Step) {
        switch step.id {
        case "activity": navigator.quickAction(.workout)
        case "sleep":
            sleepOpened = true
            navigator.open(.sleepDive)
        case "details":
            activityOpened = true
            navigator.open(.classic(.workouts))
        case "alarm": navigator.open(PulseRoute.sleepPlanner.forExistingEntryPoint)
        case "journal": navigator.open(PulseRoute.journal(dayOffset: nil).forExistingEntryPoint)
        default: navigator.open(.classic(.dataSources))
        }
    }

    private struct Step: Identifiable {
        let id: String
        let symbol: String
        let title: String
        let subtitle: String
        let done: Bool
    }
}

#endif
