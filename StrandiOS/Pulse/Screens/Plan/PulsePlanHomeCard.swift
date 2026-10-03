#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Home's My Plan card (WHOOP_UI_SPEC §3.1 item 9, journal-plan-2026/31–34, reviews/r113–r114), for the home
/// group to place under the "My Plan" header in place of `PulsePlanCard`:
///
///     PulseSectionHeader(String(localized: "My Plan"))
///     PulsePlanHomeCard()
///
/// With no plan: "Build Your Best Self", one line, "EXPLORE PLANS →" and ZENO's three dashed rings.
/// With a plan, collapsed: "BOOST FITNESS PLAN" with ⌄, "2 days left", "93% ACCOMPLISHED" over its green
/// bar. Expanded (⌃): the goals, unfinished first in white, a hairline, then finished in green, each with
/// its ring, and VIEW MY PLAN. A week recap waiting, or the Friday check-in, adds one row at the top.
/// It loads its own week through the model (`PulseSnapshotBuilder.planWeek`), so it needs nothing from Home.
struct PulsePlanHomeCard: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var plans = PulsePlanStore.shared
    @State private var snapshot: PlanWeekSnapshot?
    @State private var lastWeekPercent: Int?
    @State private var recapWaiting = false
    @State private var expanded = false

    var body: some View {
        Group {
            if let plan = plans.plan {
                activeCard(plan)
                    .task(id: PlanLoadKey(seq: model.seq, plan: plan)) { await load(plan) }
            } else {
                emptyCard
            }
        }
        #if DEBUG
        .onAppear { if JournalPlanDebug.planExpanded { expanded = true } }
        #endif
    }

    // MARK: Active plan

    private func activeCard(_ plan: PulsePlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(PulseMotion.resolved(PulseMotion.chrome, reduceMotion: reduceMotion)) { expanded.toggle() }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(plan.cardTitle)
                            .pulseText(.capsuleLabel)
                            .foregroundStyle(PulseTheme.textPrimary)
                        Spacer(minLength: 8)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(PulseTheme.JournalPlan.checkGlyph)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .accessibilityHidden(true)
                    }
                    Text(snapshot.map { PlanCopy.daysLeft($0.daysLeft) } ?? " ")
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                    PlanAccomplishedBar(percent: snapshot?.percent)
                        .padding(.top, 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint(expanded ? String(localized: "Hides the goals") : String(localized: "Shows the goals"))
            .accessibilityAddTraits(.isButton)

            if let snapshot {
                if recapWaiting {
                    notice(symbol: "calendar.badge.checkmark",
                           text: String(localized: "Your week recap is ready: \(lastWeekPercent ?? 0)% complete"))
                        .padding(.top, 16)
                } else if checkInDue(plan, snapshot) {
                    notice(symbol: "flag.checkered",
                           text: String(localized: "Friday check-in: \(snapshot.unfinished.count) goals left"))
                        .padding(.top, 16)
                }
                if expanded {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(snapshot.unfinished) { goal in PlanGoalRow(progress: goal) }
                        if !snapshot.unfinished.isEmpty && !snapshot.finished.isEmpty {
                            PulseDivider().padding(.vertical, 8)
                        }
                        ForEach(snapshot.finished) { goal in PlanGoalRow(progress: goal) }
                    }
                    .padding(.top, 16)
                    PulseLink(.weeklyPlan(editing: false)) {
                        Text(String(localized: "View my plan"))
                            .pulseText(.capsuleLabel)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                                .fill(PulseTheme.Plan.viewButton))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .padding(.top, 16)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.dialog, style: .continuous)
            .fill(expanded ? PulseTheme.Plan.expandedCard : PulseTheme.Plan.collapsedCard))
    }

    /// A one-line notice that opens Plan Overview (where the recap or the check-in lives).
    private func notice(symbol: String, text: String) -> some View {
        PulseLink(.weeklyPlan(editing: false)) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(PulseTheme.JournalPlan.checkGlyph)
                    .foregroundStyle(PulseTheme.Plan.progress)
                Text(text)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                PulseChevron(color: PulseTheme.textTertiary, size: 12)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: PulseTheme.Layout.minTapTarget)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .fill(PulseTheme.nested))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }

    private func checkInDue(_ plan: PulsePlan, _ s: PlanWeekSnapshot) -> Bool {
        guard let weekday = WeeklyPlanProgress.isoWeekday(s.today), weekday >= 5 else { return false }
        return plan.checkInSeenWeek != s.weekStart && !s.unfinished.isEmpty
    }

    // MARK: No plan (§3.1 item 9 "Empty state")

    private var emptyCard: some View {
        PulseLink(.weeklyPlan(editing: false)) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Build Your Best Self"))
                        .pulseText(.cardHeadline)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "Set goals, track progress, and turn small actions into long-term wins."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(String(localized: "Explore plans")).pulseText(.label)
                        Image(systemName: "arrow.right").font(PulseTheme.JournalPlan.smallGlyph)
                    }
                    .foregroundStyle(PulseTheme.Plan.exploreCTA)
                    .padding(.top, 4)
                }
                Spacer(minLength: 0)
                PlanEmptyArt()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulseCardBackground(.solid(PulseTheme.Plan.emptyCard))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens the plans"))
    }

    // MARK: Loading

    private func load(_ plan: PulsePlan) async {
        if let s = await model.build(dayOffset: 0, { builder, r in await builder.planWeek(r, plan: plan) }) {
            snapshot = s
            if let lastMonday = PulseDisplay.dayKey(s.weekStart, offsetBy: -7), plan.startedOn < s.weekStart,
               plan.recapSeenWeek != lastMonday,
               let last = await model.build(dayOffset: 0, { builder, r in await builder.planWeek(r, plan: plan, weekOffset: -1) }) {
                lastWeekPercent = last.percent
                recapWaiting = true
            } else {
                recapWaiting = false
            }
        }
    }
}

/// Three dashed green rings holding a moon, a heart and a lifter (ZENO's own art, SF Symbols).
struct PlanEmptyArt: View {
    var body: some View {
        ZStack {
            ring("moon.stars.fill", size: 46).offset(x: 14, y: -16)
            ring("heart.fill", size: 30).offset(x: -26, y: -2)
            ring("figure.strengthtraining.traditional", size: 38).offset(x: 6, y: 26)
        }
        .frame(width: 92, height: 92)
        .accessibilityHidden(true)
    }

    private func ring(_ symbol: String, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(PulseTheme.card)
            Circle().strokeBorder(PulseTheme.Plan.progress, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
            Image(systemName: symbol)
                .font(PulseTheme.JournalPlan.checkGlyph)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .frame(width: size, height: size)
    }
}
#endif
