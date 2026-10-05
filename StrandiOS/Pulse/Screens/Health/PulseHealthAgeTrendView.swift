#if os(iOS)
import SwiftUI
import StrandAnalytics

/// ZENO AGE TREND's own page (§3.23 item 8), pushed from Healthspan's ZENO AGE TREND › card.
struct HealthAgeTrendRoute: PulseScreenRoute {
    var view: some View { PulseHealthAgeTrendView() }
}

/// The ZENO Age trend over M (five weeks) or 6M (26), laid out as WHOOP's WHOOP AGE TREND page
/// (help-center/112): at the left the selected week's date, its ZENO Age in that week's orb hue over ZENO AGE
/// and the chronological age over CHRONOLOGICAL AGE; at the right M | 6M over a range pager ("‹ AUG 6, 25 -
/// FEB 1, 26 ›") that steps one span through the weeks; then the chart, whose scrub cursor picks the week the
/// header shows (the newest by default). The weeks are Healthspan's own (`healthAgeWeeks`), and its card
/// draws the same 26 weeks as 6M here.
struct PulseHealthAgeTrendView: View {
    enum Span: String, CaseIterable, Hashable {
        case month, sixMonths

        /// The weeks a span shows.
        var weeks: Int { self == .month ? 5 : 26 }
        var title: String { self == .month ? "M" : "6M" }
        var spoken: String { self == .month ? String(localized: "Month") : String(localized: "6 months") }
    }

    @Environment(PulseModel.self) private var model
    @EnvironmentObject private var profile: ProfileStore
    @State private var snapshot: HealthAgeTrendSnapshot?
    @State private var span: Span = .sixMonths
    /// Spans back from the newest.
    @State private var page = 0
    /// The scrubbed week, an index into the weeks shown; nil is the newest.
    @State private var selected: Int?

    var body: some View {
        PulseScreenScaffold(title: String(localized: "ZENO Age trend"), coach: .button, coachSeed: coachSeed,
                            spacing: 0, ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let s = snapshot {
                    content(s)
                }
            } skeleton: {
                PulseSkeleton.cards([150, 260])
                    .padding(.top, 24)
            }
        }
        .task(id: model.healthKey) {
            let dob = profile.dateOfBirth
            if let s = await model.build(dayOffset: 0, { builder, request in
                await builder.healthAgeTrend(request, dateOfBirth: dob)
            }) {
                if snapshot != s { snapshot = s }
            }
        }
    }

    // MARK: Weeks

    /// The weeks of the span `page` spans back from the newest, oldest first.
    private func shownWeeks(_ all: [HealthAgeWeek]) -> [HealthAgeWeek] {
        let end = all.count - page * span.weeks
        guard end > 0 else { return [] }
        return Array(all[max(0, end - span.weeks)..<end])
    }

    private func lastPage(_ all: [HealthAgeWeek]) -> Int {
        max(0, (all.count - 1) / span.weeks)
    }

    /// The week the header shows: the scrubbed one, else the newest shown.
    private func selectedIndex(_ weeks: [HealthAgeWeek]) -> Int {
        min(selected ?? weeks.count - 1, weeks.count - 1)
    }

    // MARK: Page

    @ViewBuilder
    private func content(_ s: HealthAgeTrendSnapshot) -> some View {
        let weeks = shownWeeks(s.weeks)
        if weeks.isEmpty {
            Text(String(localized: "No ZENO Age yet. It is scored once a week."))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .padding(.top, 24)
        } else {
            let index = selectedIndex(weeks)
            VStack(alignment: .leading, spacing: 0) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 10) {
                        values(weeks[index])
                        Spacer(minLength: 0)
                        controls(weeks, s: s)
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        values(weeks[index])
                        controls(weeks, s: s)
                    }
                }
                .padding(.top, 24)
                // The line keeps the newest week's hue, as Healthspan's card draws it.
                HealthAgeTrendChart(weeks: weeks, hue: s.weeks.last?.hue ?? weeks[index].hue, selected: index) { i in
                    selected = i
                }
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: selected = min(weeks.count - 1, index + 1)
                    case .decrement: selected = max(0, index - 1)
                    @unknown default: break
                    }
                }
                .padding(.top, 36)
            }
        }
    }

    /// "SAT, SEP 26", the ZENO Age in its week's hue over ZENO AGE, the chronological age over
    /// CHRONOLOGICAL AGE (help-center/112).
    private func values(_ week: HealthAgeWeek) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PulseFormat.dayLabel(week.id, template: "EEEMMMd"))
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textTertiary)
            Text(PulseFormat.oneDecimal(week.zenoAge))
                .pulseText(.largeValue)
                .foregroundStyle(HealthPalette.orb(week.hue).text)
                .padding(.top, 8)
            Text(String(localized: "ZENO Age"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
            Text(PulseFormat.oneDecimal(week.chronoAge))
                .pulseText(.largeValue)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 14)
            Text(String(localized: "Chronological age"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PulseFormat.dayLabel(week.id, template: "yMMMMd"))
        .accessibilityValue(String(localized: "ZENO Age \(PulseFormat.oneDecimal(week.zenoAge)), chronological age \(PulseFormat.oneDecimal(week.chronoAge))"))
    }

    /// M | 6M over the range pager, as the Trend View sets them.
    private func controls(_ weeks: [HealthAgeWeek], s: HealthAgeTrendSnapshot) -> some View {
        VStack(alignment: .trailing, spacing: 22) {
            PulseTrendSegments(label: String(localized: "Range"), options: Span.allCases, selection: spanBinding,
                               title: { $0.title }, spoken: { $0.spoken })
                .frame(width: PulseTheme.Trends.rangeColumnWidth)
            PulseTrendRangePager(pager: pager(weeks, s: s),
                                 onBack: { page = min(lastPage(s.weeks), page + 1); selected = nil },
                                 onForward: { page = max(0, page - 1); selected = nil })
                .frame(width: PulseTheme.Trends.rangeColumnWidth)
        }
        .padding(.trailing, PulseTheme.Trends.rangeColumnTrailing)
    }

    /// "Aug 6, 25 - Feb 1, 26": the first shown week's start to the last one's end (today while it runs),
    /// worded as the Trend View's pager words a window.
    private func pager(_ weeks: [HealthAgeWeek], s: HealthAgeTrendSnapshot) -> PulseTrendPager {
        let first = weeks.first?.id ?? s.todayKey
        let lastWeek = weeks.last?.id ?? s.todayKey
        let end = min(PulseDisplay.dayKey(lastWeek, offsetBy: 6) ?? lastWeek, s.todayKey)
        let older = page < lastPage(s.weeks)
        let window = PulseTrendMath.Window(start: first, end: max(first, end), page: page,
                                           dayCount: max(1, weeks.count * 7), hasOlder: older)
        return PulseTrendPager(title: PulseTrendPageBuilder.pagerTitle(window), canGoBack: older,
                               canGoForward: page > 0,
                               accessibility: PulseTrendPageBuilder.pagerAccessibility(window))
    }

    private var spanBinding: Binding<Span> {
        Binding(get: { span }, set: { new in
            guard new != span else { return }
            span = new
            page = 0
            selected = nil
        })
    }

    private var coachSeed: String? {
        guard let s = snapshot else { return nil }
        let weeks = shownWeeks(s.weeks)
        guard !weeks.isEmpty else { return nil }
        let week = weeks[selectedIndex(weeks)]
        return String(localized: "ZENO Age trend: the week of \(PulseFormat.dayLabel(week.id, template: "MMMd")), ZENO Age \(PulseFormat.oneDecimal(week.zenoAge)), chronological age \(PulseFormat.oneDecimal(week.chronoAge)).")
    }
}
#endif
