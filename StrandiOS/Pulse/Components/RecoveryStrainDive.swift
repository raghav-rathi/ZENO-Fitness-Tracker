#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Recovery and Strain deep-dive pieces (group "recovery-strain"; WHOOP_UI_SPEC §3.4, §3.5)
//
// What the two rebuilt dives share and no other group draws: the contributor callout with its
// "Today vs. last 30 days" legend, the Weekly Trends card, the behaviour chips, the points and confidence
// chips of "What shaped it", the carried-score line under the bar, the route helper that links a metric
// to its Trend View only once the trends group has rebuilt it, and the bar's achievement chip with the
// HOW IT'S CALCULATED row it moves the explainer to. Everything takes plain values; the snapshots that
// feed them live in Screens/Recovery and Screens/Strain.

// MARK: Contributor rows

/// One contributor row of a deep dive's callout: the day's value over its 30-day average, with the trend
/// glyph coloured by good / bad (§2.6 items 8 and 9).
struct PulseDiveContributor: Identifiable, Equatable {
    /// The metric's catalog key ("hrv", "steps").
    let id: String
    let symbol: String
    let title: String
    /// As printed: "65", "74%", "1:53", "23,451", or "--" without a value.
    let value: String
    /// The 30-day average as printed ("93", "75%", "0:21"); nil while too few days back it.
    let baseline: String?
    /// nil without a baseline (calibrating, a new metric): the row shows the value alone.
    let trend: PulseTrend?
    /// The metric's Trend View (or the screen that shows it until the Trend View is rebuilt).
    let route: PulseRoute?
    /// The row in words for VoiceOver ("Heart rate variability, 65 milliseconds, 30-day average 93, …").
    let spoken: String
}

/// The deep dive's callout under the ring: the contributor rows and the legend well, placed as the 2026
/// captures measure them (deep-dives-2026/17b, same 402 pt screen): the first row's centre 52 pt under the
/// pointer's tip, a 66 pt pitch with the inset dividers drawn over the row boundary rather than between
/// rows, values and arrows ending 24 pt inside the callout's edge, and the legend 58 pt under the last
/// row. The legend only when some row has an average to compare with (calibrating, or the oldest days,
/// show values alone). A row with a route opens its Trend View.
struct PulseDiveCallout: View {
    let rows: [PulseDiveContributor]
    /// The night the values are from: "Today", the day itself on a past day ("Wed, Aug 19"), or a carried
    /// night's date.
    let dayLabel: String

    var body: some View {
        PulseCallout {
            Color.clear.frame(height: 12)
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                link(row)
                    .padding(.trailing, 6)
                    .overlay(alignment: .bottom) {
                        if index < rows.count - 1 {
                            PulseDivider(leadingInset: 16, trailingInset: 16)
                        }
                    }
            }
            if rows.contains(where: { $0.trend != nil }) {
                PulseLegendWell {
                    PulseDiveLegend(dayLabel: dayLabel)
                }
                .padding(.top, -4)
            }
        }
    }

    @ViewBuilder
    private func link(_ row: PulseDiveContributor) -> some View {
        let content = PulseCalloutRow(symbol: row.symbol, title: row.title, value: row.value,
                                      baseline: row.baseline, trend: row.trend)
            .accessibilityLabel(row.spoken)
        if let route = row.route {
            PulseLink(route) { content }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens the trend"))
        } else {
            content
        }
    }
}

/// "▲▼ Today vs. last 30 days": ▲ teal, ▼ orange, the day white Semibold, the rest 70%. A past day names
/// itself in place of "Today" (deep-dives-2026/17c: "Wed, Aug 19 vs. last 30 days"). The text starts
/// 10 pt after the triangles, as on deep-dives-2026/17b.
struct PulseDiveLegend: View {
    let dayLabel: String

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                PulseTriangle(pointsUp: true).fill(PulseTheme.positive).frame(width: 7, height: 6)
                PulseTriangle(pointsUp: false).fill(PulseTheme.negative).frame(width: 7, height: 6)
            }
            .accessibilityHidden(true)
            (Text(dayLabel).fontWeight(.semibold).foregroundColor(PulseTheme.textPrimary)
             + Text(verbatim: " ")
             + Text(String(localized: "vs. last 30 days")).foregroundColor(PulseTheme.textSecondary))
                .pulseText(.legend)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Under the bar when the dial shows an earlier night's score: "Last night · Sep 30" (12 pt, 70%).
struct PulseDiveCarriedLine: View {
    let text: String

    var body: some View {
        Text(text)
            .pulseText(.secondary)
            .foregroundStyle(PulseTheme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: Weekly Trends

/// A Weekly Trends card (§2.7): the UPPERCASE title with "›" at the right, an optional series legend
/// under it at the right, then the chart. With a route the whole card opens the metric's Trend View;
/// without one it is a plain card and drops the "›".
///
/// Proportions from deep-dives-2026/16 and 16b: the title's caps centred ≈24 pt under the card's top, the
/// plot's top gridline ≈34 pt under them, a 197 pt plot (`PulseWeeklyChart.height` is the chart frame that
/// leaves the plot that tall above its two-line day labels) and ≈18 pt under the labels.
struct PulseWeeklyTrendCard<Chart: View>: View {
    let title: String
    let route: PulseRoute?
    var legend: [PulseWeeklyLegendItem]
    @ViewBuilder var chart: () -> Chart

    init(_ title: String, route: PulseRoute?, legend: [PulseWeeklyLegendItem] = [],
         @ViewBuilder chart: @escaping () -> Chart) {
        self.title = title
        self.route = route
        self.legend = legend
        self.chart = chart
    }

    var body: some View {
        if let route {
            PulseLink(route) { card }
                .buttonStyle(PulsePressStyle())
                .accessibilityHint(String(localized: "Opens the trend"))
        } else {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            PulseCardTitle(title, accessory: route == nil ? .none : .trailingChevron)
            if !legend.isEmpty {
                PulseWeeklyLegend(items: legend)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 10)
            }
            chart()
                .padding(.top, legend.isEmpty ? 27 : 14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground()
        .contentShape(Rectangle())
    }
}

enum PulseWeeklyChart {
    /// The chart frame a Weekly Trends card gives its chart: a 197 pt plot plus the day labels under it.
    static let height: CGFloat = 230
}

/// One series in a Weekly Trends legend ("■ ZONE 1").
struct PulseWeeklyLegendItem: Identifiable, Equatable {
    let title: String
    let color: Color
    var id: String { title }
}

/// "■ ZONE 1 ■ ZONE 2 ■ ZONE 3": 8 pt square swatches and 11 pt caps at 70%; wraps when it cannot fit.
struct PulseWeeklyLegend: View {
    let items: [PulseWeeklyLegendItem]

    var body: some View {
        PulseWordFlow(alignment: .trailing, spacing: 12, lineSpacing: 6) {
            ForEach(items) { item in
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                    Text(item.title)
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The two-line x labels of a week of day keys ("Sat" over "14"), formatted at UTC like every day key.
enum PulseWeekLabels {
    static func weekday(_ key: String) -> String { PulseFormat.dayLabel(key, template: "EEE") }
    static func dayNumber(_ key: String) -> String { PulseFormat.dayLabel(key, template: "d") }
}

// MARK: Routes

enum PulseDiveRoutes {
    /// Where a contributor row or a Weekly Trends card for `metric` leads: the metric's Trend View once the
    /// trends group has rebuilt it (`PulseTrendView.isRebuilt`), until then `fallback`, a screen that reads
    /// the dive's own resolver for the metric (Steps on the day), and otherwise nowhere: the row and the
    /// card are then plain, with no "›".
    ///
    /// Never the Trend View route's classic fallback. Those metric screens resolve their own figures (a
    /// zone or calorie screen with "no data" right after the dive printed 1:13 and 880 kcal) and speak the
    /// classic vocabulary (Charge, Rest, Effort on 0-100), which the WHOOP-style path must never show
    /// (spec §0.3; one resolver per fact).
    static func trend(_ metric: String, fallback: PulseRoute? = nil) -> PulseRoute? {
        let route = PulseRoute.trendView(metric: metric)
        return route.isRebuilt ? route : fallback
    }
}

// MARK: Achievement chip

/// The pillar's achievement chip in a dive's bar (§1.5 [Z]; deep-dives-2026/17b, 57, profile-community-2026/83):
/// the running count of the pillar's cumulative badge, Green Light's green Recoveries on Recovery and Big
/// Days' days of 14+ Strain on Strain, read from the snapshot the Achievements pages read
/// (`ProfileSnapshot.badges`), so the chip and Achievement Details' "Total so far" are one number. It opens
/// that badge's Achievement Details. The explainer it displaces moves to HOW IT'S CALCULATED at the foot of
/// the page (`PulseDiveExplainerRow`); before the badge counts anything the bar keeps ⓘ.
enum PulseDiveAchievement {
    case recovery, strain

    /// The badge the chip counts.
    var rule: PulseAchievements.Rule {
        switch self {
        case .recovery: return .greenLight
        case .strain: return .bigDays
        }
    }

    /// The family's mini badge, as `PulseAchievementChip` draws the families.
    private var symbol: String {
        switch self {
        case .recovery: return "shield.fill"
        case .strain: return "diamond.fill"
        }
    }

    /// The bar's right accessory: nothing while the profile snapshot loads, then the chip, or ⓘ while
    /// the badge has nothing to count. VoiceOver names the badge and what its count counts, in the words of
    /// its Achievement Details ("Green Light: 3 Green Recoveries"), not a bare "3 achievements".
    func trailing(_ profile: ProfileSnapshot?, open: @escaping (PulseRoute) -> Void) -> PulseNavTrailing {
        guard let profile else { return .none }
        guard let badge = profile.badges.first(where: { $0.rule == rule }), badge.count > 0 else {
            return .info { open(.classic(.scoringGuide)) }
        }
        let info = ProfileBadgeInfo(badge)
        return .achievement(symbol: symbol, tint: ProfileArtPalette.family(badge.family)[0], count: badge.count,
                            accessibilityLabel: String(localized: "\(info.name): \(badge.count) \(info.criterion)")) {
            open(PulseAchievementDetailsRoute(badgeID: badge.id).route)
        }
    }
}

/// HOW IT'S CALCULATED › at the foot of a dive (§1.5 [Z]): the explainer the bar's ⓘ opens, kept
/// reachable once the achievement chip takes the bar.
struct PulseDiveExplainerRow: View {
    var body: some View {
        PulseLink(.classic(.scoringGuide)) {
            PulseListRow(symbol: "info.circle", title: String(localized: "How it's calculated"))
        }
        .buttonStyle(PulsePressStyle())
    }
}

// MARK: Chips

/// A behaviour chip on the Recovery dive's BEHAVIOR INSIGHTS card (deep-dives-2026/17b, 17d): teal text
/// and ▲ on a teal tint when it has gone with a higher Recovery, orange and ▼ when with a lower one, grey
/// when no effect stands out. Radius 8, 32 pt tall, 14 pt text; a name too long for the card (a long
/// custom question, large text) wraps between words and the chip grows, never truncating (DR §2).
struct PulseBehaviorChip: View {
    enum Effect: Equatable {
        case helps, hurts, neutral
    }

    let title: String
    let effect: Effect

    private var colors: (text: Color, fill: Color) {
        switch effect {
        case .helps: return (PulseTheme.positive, PulseTheme.Tint.teal.fill)
        case .hurts: return (PulseTheme.negative, PulseTheme.Tint.orange.fill)
        case .neutral: return (PulseTheme.textSecondary, PulseTheme.Tint.grey.fill)
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            if effect != .neutral {
                PulseTriangle(pointsUp: effect == .helps)
                    .fill(colors.text)
                    .frame(width: 9, height: 7.5)
                    .accessibilityHidden(true)
            }
            Text(title)
                .pulseText(.body)
                .foregroundStyle(colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minHeight: 32)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular).fill(colors.fill))
    }
}

/// Chips in rows, left to right: each at its natural width, or the row's full width when longer (it then
/// wraps inside itself, see `PulseBehaviorChip`), the next one on a new row when it does not fit. Unlike
/// `PulseWordFlow`, which shrinks every word when one is too wide, a long chip never squeezes the others.
struct PulseChipFlow: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var out: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let ideal = subviews[index].sizeThatFits(.unspecified)
            let size = ideal.width > maxWidth
                ? subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
                : ideal
            if !row.items.isEmpty && row.width + spacing + size.width > maxWidth {
                out.append(row)
                row = Row()
            }
            row.width = row.items.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.items.append((index, size))
        }
        if !row.items.isEmpty { out.append(row) }
        return out
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let laid = rows(subviews, maxWidth: proposal.width ?? .infinity)
        let height = laid.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, laid.count - 1))
        return CGSize(width: laid.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                                           proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }
}

/// "+4 pts" on a teal tint, "−1 pt" on orange, "0 pts" grey: what one input added to or took from
/// Recovery ("What shaped it").
struct PulsePointsChip: View {
    let points: Int

    private var text: String {
        let size = abs(points)
        if points > 0 {
            return size == 1 ? String(localized: "+1 pt") : String(localized: "+\(size) pts")
        }
        if points < 0 {
            // The minus sign (U+2212) the spec writes and the skin temperature beside it prints.
            return size == 1 ? String(localized: "\u{2212}1 pt") : String(localized: "\u{2212}\(size) pts")
        }
        return String(localized: "0 pts")
    }

    private var tint: PulseTheme.Tint {
        points > 0 ? .teal : (points < 0 ? .orange : .grey)
    }

    var body: some View {
        Text(text)
            .pulseText(.chipStrong)
            .foregroundStyle(points == 0 ? PulseTheme.textSecondary : tint.glyph)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular).fill(tint.fill))
            .accessibilityHidden(true)
    }
}

/// "RELIABLE" (teal), "ESTIMATE" (grey) or "CALIBRATING" (blue): how much the score's baseline can carry.
struct PulseConfidenceChip: View {
    let confidence: ScoreConfidence

    private var title: String {
        switch confidence {
        case .solid: return String(localized: "Reliable")
        case .building: return String(localized: "Estimate")
        case .calibrating: return String(localized: "Calibrating")
        }
    }

    private var tint: PulseTheme.Tint {
        switch confidence {
        case .solid: return .teal
        case .building: return .grey
        case .calibrating: return .blue
        }
    }

    var body: some View {
        Text(title)
            .pulseText(.label)
            .foregroundStyle(confidence == .building ? PulseTheme.textSecondary : tint.glyph)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular).fill(tint.fill))
            .accessibilityLabel(String(localized: "Confidence: \(title)"))
    }
}

// MARK: Insight

/// The dive's inline insight (§2.6 item 10). With the Coach on it is the coach card (AI border, the CTA in
/// the AI gradient); with the Coach switched off it is the same sentence on a plain card with no CTA, so
/// the explanation survives without dressing local copy as the Coach's.
struct PulseDiveInsight: View {
    let text: String
    let cta: String
    let seed: String

    @Environment(\.pulseCoach) private var coach

    var body: some View {
        if coach.availability == .off {
            PulseCard {
                Text(text)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            PulseInsightCard(text: text, cta: cta) { coach.open(seed) }
        }
    }
}
#endif
