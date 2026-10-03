#if os(iOS)
import SwiftUI

// MARK: - The strength variant's EXERCISES pane and EXERCISE SUMMARY (WHOOP_UI_SPEC §3.6 "Strength Trainer
// activity", g15, g18, g12)
//
// ZENO's strength sessions are Lift Log sessions: tonnage, sets, reps and estimated 1RM, never WHOOP's
// muscular load or INTENSITY (the comparison notes: not computable on-device), so neither appears here.

/// The EXERCISES pane: a pager whose first card is the session's summary (g15: the lifter tile and
/// "5 Exercises / 16 Sets" on a lighter top band, then TONNAGE and TOTAL REPS) and whose next cards are one
/// per exercise (g18: its sets as REPS | WEIGHT | AVG HR, then the totals); the page dots and VIEW ALL →
/// sit under the card, outside it.
struct PulseActivityLiftPager: View {
    let lift: ActivityLiftSummary
    /// The activity's title, for the summary page's bar.
    let title: String

    @State private var page: Int? = 0
    /// Each page's own height: the pager takes the settled page's, so the compact summary card has the
    /// dots right under it (g15) and a taller exercise card is shown whole.
    @State private var heights: [Int: CGFloat] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pageCount: Int { lift.exercises.count + 1 }

    var body: some View {
        let current = heights[page ?? 0]
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    pageView(0) { PulseActivityLiftSummaryCard(lift: lift) }
                    ForEach(Array(lift.exercises.enumerated()), id: \.element.id) { index, exercise in
                        pageView(index + 1) { PulseActivityExerciseCard(exercise: exercise, massUnit: lift.massUnit) }
                    }
                }
                // As tall as the settled page, every page from the top: a taller neighbour is cut at the
                // bottom while it slides in, and shown whole once it settles.
                .frame(height: current, alignment: .top)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $page)
            .scrollIndicators(.hidden)
            .frame(height: current)
            .animation(PulseMotion.resolved(PulseMotion.chrome, reduceMotion: reduceMotion), value: page)
            .onPreferenceChange(PulseLiftPageHeights.self) { measured in
                heights.merge(measured) { _, new in new }
            }
            .padding(.horizontal, -PulseTheme.Layout.pageMargin)
            #if DEBUG
            .task {
                // `--activity-lift-page N`: that page of the pager, for captures (simctl cannot swipe).
                if let n = PulseActivityDebug.value("--activity-lift-page").flatMap(Int.init) {
                    try? await Task.sleep(for: .milliseconds(600))
                    page = min(n, pageCount - 1)
                }
            }
            #endif
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Circle()
                            .fill(i == (page ?? 0) ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "Page \((page ?? 0) + 1) of \(pageCount)"))
                Spacer(minLength: 12)
                PulseLink(PulseActivitySessionSummaryRoute(lift: lift).route) {
                    HStack(spacing: 8) {
                        Text(String(localized: "View all"))
                            .pulseText(.label)
                        Image(systemName: "arrow.right")
                            .font(.system(size: PulseActivityStyle.Glyph.arrow, weight: .semibold))
                    }
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(minHeight: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens every exercise in this session"))
            }
        }
        .id("pulse.activity-lift")
    }

    /// One page: the card at its own height, within the page margins, a page wide.
    private func pageView<Card: View>(_ index: Int, @ViewBuilder card: () -> Card) -> some View {
        card()
            .fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { geo in
                Color.clear.preference(key: PulseLiftPageHeights.self, value: [index: geo.size.height])
            })
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .containerRelativeFrame(.horizontal)
            .id(index)
    }
}

/// The lift pager's page heights, by page.
private struct PulseLiftPageHeights: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// The session's summary card (g15): the top band, a shade lighter, holds the lifter tile and
/// "5 Exercises" over "16 Sets" in strain blue; under it TONNAGE and TOTAL REPS. No divider.
struct PulseActivityLiftSummaryCard: View {
    let lift: ActivityLiftSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                PulseActivityLiftTile()
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "\(lift.exercises.count) Exercises"))
                        .pulseText(.rowText)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "\(lift.workingSets) Sets"))
                        .pulseText(.rowText)
                        .foregroundStyle(PulseTheme.strain)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(UnevenRoundedRectangle(topLeadingRadius: PulseTheme.Radius.card,
                                               topTrailingRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.nested))
            HStack(alignment: .top, spacing: 40) {
                if let tonnage = lift.tonnage {
                    figure(tonnage, unit: lift.massUnit, title: String(localized: "Tonnage"))
                }
                figure("\(lift.totalReps)", unit: nil, title: String(localized: "Total reps"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .accessibilityElement(children: .combine)
    }

    private func figure(_ value: String, unit: String?, title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            PulseValueText(value: value, unit: unit, style: .mediumValue, unitStyle: .tileUnit)
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
        }
    }
}

/// The lifter glyph on its own lighter tile, at the left of a card's top band.
struct PulseActivityLiftTile: View {
    var body: some View {
        Image(systemName: "figure.strengthtraining.traditional")
            .font(.system(size: PulseActivityStyle.Glyph.liftIcon, weight: .regular))
            .foregroundStyle(PulseTheme.textPrimary)
            .frame(width: 66, height: 58)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .fill(PulseTheme.nested))
            .accessibilityHidden(true)
    }
}

/// One exercise (g18): its name on the lighter top band with its estimated 1RM, then every set as
/// REPS | WEIGHT (| AVG HR when the sets carry their times), a dashed rule, and the totals (reps; tonnage
/// in strain blue). Warm-up sets are dimmed and left out of the totals, as the Lift Log counts them.
struct PulseActivityExerciseCard: View {
    let exercise: ActivityLiftSummary.Exercise
    let massUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                PulseActivityLiftTile()
                Text(exercise.name)
                    .pulseText(.rowText)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(2)
                Spacer(minLength: 8)
                if let e1rm = exercise.estimatedOneRepMax {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(e1rm)
                            .font(PulseType.font(.rowValue))
                            .foregroundStyle(PulseTheme.textPrimary)
                        Text(String(localized: "Est. 1RM"))
                            .pulseText(.label)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(8)
            .background(UnevenRoundedRectangle(topLeadingRadius: PulseTheme.Radius.card,
                                               topTrailingRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.nested))
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    column(String(localized: "Reps"))
                    column(String(localized: "Weight"))
                    if exercise.hasSetHeartRate { column(String(localized: "Avg HR")) }
                }
                ForEach(exercise.sets) { set in
                    GridRow {
                        Text(set.reps)
                            .font(PulseType.font(.calloutValue))
                        value(set.weight, unit: set.weight == nil ? nil : massUnit)
                        if exercise.hasSetHeartRate {
                            value(set.avgHR.map { "\($0)" }, unit: set.avgHR == nil ? nil : String(localized: "bpm"))
                        }
                    }
                    .foregroundStyle(set.isWarmup ? PulseTheme.textTertiary : PulseTheme.textPrimary)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            Line()
                .stroke(PulseTheme.dash, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Total"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                HStack(alignment: .firstTextBaseline, spacing: 40) {
                    Text("\(exercise.totalReps)")
                        .font(PulseType.font(.calloutValue))
                        .foregroundStyle(PulseTheme.textPrimary)
                    if let tonnage = exercise.tonnage {
                        PulseValueText(value: tonnage, unit: massUnit, style: .calloutValue, unitStyle: .tileUnit,
                                       color: PulseTheme.strain, unitColor: PulseTheme.strain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            if exercise.sets.contains(where: \.isWarmup) {
                Text(String(localized: "Warm-up sets are dimmed and left out of the totals."))
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
    }

    private func column(_ title: String) -> some View {
        Text(title)
            .pulseText(.label)
            .foregroundStyle(PulseTheme.textTertiary)
    }

    @ViewBuilder
    private func value(_ text: String?, unit: String?) -> some View {
        if let text {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(text).font(PulseType.font(.calloutValue))
                if let unit { Text(unit).pulseText(.tileUnit) }
            }
        } else {
            Text(verbatim: "–").font(PulseType.font(.calloutValue)).foregroundStyle(PulseTheme.textTertiary)
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return p
        }
    }
}

// MARK: - EXERCISE SUMMARY (g12)

/// VIEW ALL's destination: this session's exercises, one card each, under its totals. A route value, so it
/// carries the session it shows.
struct PulseActivitySessionSummaryRoute: PulseScreenRoute {
    let lift: ActivityLiftSummary

    var view: some View { PulseActivitySessionSummaryView(lift: lift) }
}

/// "‹ EXERCISE SUMMARY": TONNAGE (strain blue) | SETS | REPS, then every exercise's card.
struct PulseActivitySessionSummaryView: View {
    let lift: ActivityLiftSummary

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Exercise Summary"), coach: .button, spacing: 12) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    PulseValueText(value: lift.tonnage ?? "–", unit: lift.tonnage == nil ? nil : lift.massUnit,
                                   style: .largeValue, unitStyle: .tileUnit, color: PulseTheme.strain,
                                   unitColor: PulseTheme.strain)
                    Text(String(localized: "Tonnage"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                .padding(.trailing, 20)
                Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 58)
                summaryFigure("\(lift.workingSets)", title: String(localized: "Sets"))
                    .padding(.leading, 20)
                summaryFigure("\(lift.totalReps)", title: String(localized: "Reps"))
                    .padding(.leading, 28)
                Spacer(minLength: 0)
            }
            .padding(.leading, 4)
            .padding(.bottom, 8)
            .accessibilityElement(children: .combine)
            ForEach(lift.exercises) { exercise in
                PulseActivityExerciseCard(exercise: exercise, massUnit: lift.massUnit)
            }
        }
    }

    private func summaryFigure(_ value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(PulseType.font(.largeValue))
                .foregroundStyle(PulseTheme.textPrimary)
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
        }
    }
}
#endif
