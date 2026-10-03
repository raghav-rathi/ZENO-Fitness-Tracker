#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Behavior Details (WHOOP_UI_SPEC §3.18), pushed from Behavior Insights.
///
/// "‹ BEHAVIOR DETAILS" over a hero (ZENO draws the behaviour's symbol on a soft glow; no stock photos [Z]),
/// the behaviour's name, then the RECOVERY IMPACT card: its verdict chip, the wide diverging bar with the
/// % impact, and, for a behaviour with a logged amount, the expandable breakdown by amount ("1 Drink",
/// "2-6 Drinks"). WHOOP's member-average tick and caption are population data and are left out [POP].
/// Then the 90-day yes / no counts, Logging History (three months of yes / no / missing days; journal
/// behaviours only), "Impact of …" in ZENO's own words with the wearer's own numbers, and a
/// RECOMMENDATION. Every figure comes from the same analysis Behavior Insights shows.
struct PulseBehaviorDetailsView: View {
    let identity: String

    @Environment(PulseModel.self) private var model
    @StateObject private var catalog = JournalCatalogStore()
    @State private var local = PulseJournalLocalStore.shared
    @State private var snapshot: BehaviorDetailsSnapshot?
    @State private var names: BehaviorNames?
    @State private var expanded = false
    @State private var historyPage = 0
    @State private var scrolled = false
    @State private var restTop: CGFloat?

    private var isAuto: Bool { PulseBehaviorLibrary.Auto(rawValue: identity) != nil }
    private var definition: PulseBehaviorDefinition? {
        identity.hasPrefix("lib.") ? PulseBehaviorLibrary.definition(id: String(identity.dropFirst(4))) : nil
    }
    private var title: String { names?.title(identity) ?? PulseBehaviorLibrary.Auto(rawValue: identity)?.title ?? definition?.title ?? "" }
    private var symbol: String {
        PulseBehaviorLibrary.Auto(rawValue: identity)?.symbol ?? names?.behavior(identity)?.symbol ?? definition?.symbol ?? "circle.dashed"
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                JournalPlanScrollMarker()
                Text(title)
                    .pulseText(.journalQuestion)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 110)
                PulseLoadingGate(isLoading: snapshot == nil) {
                    if let snapshot { content(snapshot) }
                } skeleton: {
                    PulseSkeleton.cards([150, 90, 220])
                        .padding(.top, 20)
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.bottom, PulseTheme.Layout.floatingChromeInset + 16)
        }
        .pulseDebugScroll(proxy, ready: snapshot != nil)
        .journalPlanTrackScroll($scrolled, rest: $restTop)
        }
        .background(hero.ignoresSafeArea())
        .overlay(alignment: .top) {
            JournalPlanScrollBackdrop(color: PulseTheme.JournalPlan.detailsPage)
                .opacity(scrolled ? 1 : 0)
                .animation(PulseMotion.chrome, value: scrolled)
        }
        .pulseNavHeader(String(localized: "Behavior Details"))
        .overlay { PulseFloatingCoach(accessory: .button, seed: coachSeed) }
        .environment(\.colorScheme, .dark)
        .task(id: model.detailKey) { await load() }
    }

    // MARK: Hero

    /// The behaviour's symbol, large and faint, on a soft glow that fades into the page.
    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            PulseTheme.JournalPlan.detailsPage
            RadialGradient(colors: [PulseTheme.JournalPlan.heroGlow, PulseTheme.JournalPlan.detailsPage],
                           center: .topTrailing, startRadius: 10, endRadius: PulseTheme.JournalPlan.heroHeight * 1.3)
                .frame(height: PulseTheme.JournalPlan.heroHeight * 1.4)
                .frame(maxHeight: .infinity, alignment: .top)
            Image(systemName: symbol)
                .font(PulseTheme.JournalPlan.heroSymbolFont)
                .foregroundStyle(PulseTheme.JournalPlan.heroSymbol)
                .padding(.top, 70)
                .padding(.trailing, 6)
        }
        .accessibilityHidden(true)
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ s: BehaviorDetailsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            impactCard(s)
                .padding(.top, 20)
            if !isAuto, let row = s.row {
                countCard(row, question: names?.question(identity) ?? s.question)
                    .padding(.top, 16)
            }
            if !isAuto {
                loggingHistory(s)
                    .padding(.top, 36)
                    .id("pulse.history")
            }
            impactOf(s)
                .padding(.top, 36)
                .id("pulse.about")
            recommendation(s)
                .padding(.top, 24)
        }
    }

    // MARK: Impact card

    private func impactCard(_ s: BehaviorDetailsSnapshot) -> some View {
        let row = s.row
        let tested = row?.impact != nil
        let effect = BehaviorImpactFormat.effect(impact: row?.impact, significant: row?.significant ?? false)
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                Text(String(localized: "Recovery Impact"))
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(2)
                Spacer(minLength: 6)
                if tested {
                    BehaviorVerdictChip(verdict: effect == .helps ? .positive : (effect == .hurts ? .negative : .neutral))
                        .layoutPriority(1)
                }
                if !s.buckets.isEmpty {
                    Button { expanded.toggle() } label: {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(PulseTheme.JournalPlan.checkGlyph)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .frame(width: 24, height: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle().inset(by: -10))
                    }
                    .buttonStyle(PulsePressStyle())
                    .padding(.vertical, -10)
                    .accessibilityLabel(expanded ? String(localized: "Hide the breakdown") : String(localized: "Show the breakdown"))
                }
            }
            if let impact = row?.impact {
                HStack(alignment: .center, spacing: 14) {
                    wideBar(fraction: BehaviorImpactFormat.fraction(impact, scale: s.scale), effect: effect)
                    BehaviorImpactValue(impact: impact, color: BehaviorImpactFormat.color(effect))
                }
                Text(impactSentence(row!))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                BehaviorLockedTrack()
                Text(lockedSentence(row))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if expanded, !s.buckets.isEmpty {
                breakdown(s)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.dialog, style: .continuous)
            .fill(PulseTheme.JournalPlan.detailsImpactCard))
    }

    /// The Behavior Details bar: wider and taller than a list row's, the value beside it.
    private func wideBar(fraction: Double, effect: PulseImpactBar.Effect) -> some View {
        GeometryReader { geo in
            let half = geo.size.width / 2
            let length = half * CGFloat(min(1, abs(fraction)))
            ZStack {
                PulseHatchedTrack(color: PulseTheme.Impact.hatch, cornerRadius: PulseTheme.Radius.badge)
                RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                    .fill(BehaviorImpactFormat.color(effect))
                    .frame(width: length, height: geo.size.height)
                    .offset(x: fraction >= 0 ? length / 2 : -length / 2)
                Circle()
                    .fill(Color.white)
                    .frame(width: 5, height: 5)
                    .padding(3.5)
                    .background(Circle().fill(PulseTheme.Impact.dotRing))
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }

    private func breakdown(_ s: BehaviorDetailsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let header = s.breakdownTitle {
                Text(header)
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(s.buckets.filter { $0.days > 0 }) { bucket in
                HStack {
                    Text(bucket.label)
                        .pulseText(.subsectionTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Spacer(minLength: 8)
                    if let impact = bucket.impact {
                        let effect = BehaviorImpactFormat.effect(impact: impact, significant: bucket.significant)
                        Text(BehaviorImpactFormat.text(impact))
                            .font(PulseType.font(.rowValue))
                            .foregroundStyle(BehaviorImpactFormat.color(effect))
                    } else {
                        Text(bucket.days == 1 ? String(localized: "1 day so far") : String(localized: "\(bucket.days) days so far"))
                            .pulseText(.secondary)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            Text(String(localized: "Each amount is compared with the days you logged no. An amount needs 5 days before it is measured."))
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .continuous)
            .fill(PulseTheme.JournalPlan.detailsBreakdown))
    }

    // MARK: Counts (journal-plan-2026/26a)

    private func countCard(_ row: BehaviorImpactRowData, question: String?) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                if let question {
                    Text(question)
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(String(localized: "# of times this behavior has been logged yes or no in the past 90 days"))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            countSquare(symbol: "xmark", count: row.no, color: PulseTheme.textPrimary)
            countSquare(symbol: "checkmark", count: row.yes, color: PulseTheme.Journal.historyYes)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular).fill(PulseTheme.card))
        .accessibilityElement(children: .combine)
    }

    private func countSquare(symbol: String, count: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(PulseTheme.JournalPlan.checkGlyph)
                .foregroundStyle(color)
            Text(verbatim: "\(count)")
                .font(PulseType.font(.rowValue))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                    .strokeBorder(color, lineWidth: 1.5))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(symbol == "checkmark" ? String(localized: "\(count) yes") : String(localized: "\(count) no"))
    }

    // MARK: Logging History (§2.7)

    private func loggingHistory(_ s: BehaviorDetailsSnapshot) -> some View {
        let months = BehaviorLoggingHistory.months(endingAt: s.today, count: 3, pagesBack: historyPage)
            .map { BehaviorLoggingHistory.month(year: $0.year, month: $0.month, yes: s.yesDays, no: s.noDays, today: s.today) }
        let earliest = (s.yesDays.union(s.noDays)).min() ?? s.today
        let canGoBack = (months.first.map { String(format: "%04d-%02d-01", $0.year, $0.month) } ?? "") > earliest
        return VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Logging History"))
                .pulseText(.pageTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            PulseRangePager(title: pagerTitle(months), canGoBack: canGoBack, canGoForward: historyPage > 0,
                            onBack: { historyPage += 1 }, onForward: { historyPage = max(0, historyPage - 1) })
                .frame(maxWidth: 260)
            HStack(alignment: .top, spacing: 12) {
                ForEach(months, id: \.month) { m in monthBlock(m, today: s.today) }
            }
            HStack(spacing: 14) {
                legendDot(fill: PulseTheme.Journal.historyYes, text: String(localized: "Yes (\(months.map(\.yesCount).reduce(0, +)))"))
                legendDot(fill: PulseTheme.Journal.historyNo, text: String(localized: "No (\(months.map(\.noCount).reduce(0, +)))"))
                legendDot(fill: nil, text: String(localized: "Missing (\(months.map(\.missingCount).reduce(0, +)))"))
            }
        }
    }

    private func monthBlock(_ m: BehaviorLoggingHistory.Month, today: String) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text(PulseFormat.dayLabel(String(format: "%04d-%02d-01", m.year, m.month), template: "MMM"))
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textTertiary)
                Spacer(minLength: 0)
                if m.yesCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark").font(PulseTheme.JournalPlan.smallGlyph)
                        Text(verbatim: "\(m.yesCount)").font(PulseTheme.JournalPlan.countNumber)
                    }
                    .foregroundStyle(PulseTheme.Journal.historyYes)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                        .fill(PulseTheme.Journal.historyChip))
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(Self.weekInitials.enumerated()), id: \.offset) { _, initial in
                    Text(initial)
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                ForEach(0..<m.leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 11) }
                ForEach(Array(m.marks.enumerated()), id: \.offset) { index, mark in
                    let key = String(format: "%04d-%02d-%02d", m.year, m.month, index + 1)
                    historyDot(mark, isToday: key == today)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(PulseFormat.dayLabel(String(format: "%04d-%02d-01", m.year, m.month), template: "MMMMyyyy"))
        .accessibilityValue(String(localized: "\(m.yesCount) yes, \(m.noCount) no, \(m.missingCount) missing"))
    }

    private func historyDot(_ mark: BehaviorLoggingHistory.Mark, isToday: Bool) -> some View {
        ZStack {
            switch mark {
            case .yes: Circle().fill(PulseTheme.Journal.historyYes)
            case .no: Circle().fill(PulseTheme.Journal.historyNo)
            case .missing: Circle().strokeBorder(PulseTheme.Journal.historyNo, lineWidth: 1)
            case .future: Circle().strokeBorder(PulseTheme.JournalPlan.calendarFuture, lineWidth: 1)
            }
            if isToday { Circle().strokeBorder(Color.white, lineWidth: 1.5).padding(-2.5) }
        }
        .frame(width: 10, height: 10)
        .frame(height: 11)
    }

    private func legendDot(fill: Color?, text: String) -> some View {
        HStack(spacing: 6) {
            if let fill {
                Circle().fill(fill).frame(width: 10, height: 10)
            } else {
                Circle().strokeBorder(PulseTheme.Journal.historyNo, lineWidth: 1).frame(width: 10, height: 10)
            }
            Text(text)
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textSecondary)
        }
    }

    /// "MAR '26 - MAY '26".
    private func pagerTitle(_ months: [BehaviorLoggingHistory.Month]) -> String {
        func label(_ m: BehaviorLoggingHistory.Month) -> String {
            let key = String(format: "%04d-%02d-01", m.year, m.month)
            return "\(PulseFormat.dayLabel(key, template: "MMM")) '\(String(format: "%02d", m.year % 100))"
        }
        guard let first = months.first, let last = months.last else { return "" }
        return "\(label(first)) - \(label(last))"
    }

    private static var weekInitials: [String] {
        // A Sunday-first week's initials in the app's language (2026-03-01 was a Sunday).
        (0..<7).map { PulseFormat.dayLabel(String(format: "2026-03-%02d", $0 + 1), template: "EEEEE") }
    }

    // MARK: Impact of … and RECOMMENDATION

    private func impactOf(_ s: BehaviorDetailsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Impact of \(title)"))
                .pulseText(.weeklyTrendsTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(aboutParagraphs(s).enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.JournalPlan.detailsBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func recommendation(_ s: BehaviorDetailsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(PulseTheme.JournalPlan.rowGlyph)
                Text(String(localized: "Recommendation"))
                    .pulseText(.menuLabel)
            }
            .foregroundStyle(PulseTheme.JournalPlan.recommendationText)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text(recommendationText(s))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.JournalPlan.recommendationBox))
    }

    // MARK: Copy

    private func impactSentence(_ row: BehaviorImpactRowData) -> String {
        guard let impact = row.impact else { return "" }
        let size = "\(abs(Int(impact.rounded())))%"
        let higher = impact >= 0
        if row.significant {
            return higher
                ? String(localized: "On days with it, your Recovery was \(size) higher than on days without.")
                : String(localized: "On days with it, your Recovery was \(size) lower than on days without.")
        }
        return higher
            ? String(localized: "Your Recovery was \(size) higher on days with it, a difference that is still within your normal day-to-day variation.")
            : String(localized: "Your Recovery was \(size) lower on days with it, a difference that is still within your normal day-to-day variation.")
    }

    private func lockedSentence(_ row: BehaviorImpactRowData?) -> String {
        switch row?.lock {
        case .calibrating?:
            return String(localized: "Behavior Insights start after \(BehaviorImpact.recoveriesToUnlock) Recoveries. Keep wearing your strap and logging your journal.")
        case .needsRecoveryDays?:
            return String(localized: "Not enough of these days have a Recovery yet. Please keep logging responses.")
        default:
            return isAuto
                ? String(localized: "ZENO needs at least 5 days with this behavior and 5 without, each with a Recovery, to measure it.")
                : String(localized: "Record at least 5 yes's and no's in your journal to see how this behavior impacts your Recovery.")
        }
    }

    /// The library's explanation, then the wearer's own numbers.
    private func aboutParagraphs(_ s: BehaviorDetailsSnapshot) -> [String] {
        var out = PulseBehaviorLibrary.Auto(rawValue: identity)?.about ?? definition?.about ?? []
        if out.isEmpty {
            out.append(String(localized: "ZENO compares your Recovery on the days you answered yes with the days you answered no, so you can see whether this behavior lines up with how you recover."))
        }
        if let row = s.row, let with = row.meanWith, let without = row.meanWithout {
            out.append(String(localized: "Over the past 90 days your Recovery averaged \(Int(with.rounded()))% on \(row.nWith) days with it and \(Int(without.rounded()))% on \(row.nWithout) days without. This is an association in your own data, not proof of cause."))
        }
        return out
    }

    private func recommendationText(_ s: BehaviorDetailsSnapshot) -> String {
        let tip = PulseBehaviorLibrary.Auto(rawValue: identity)?.tip ?? definition?.tip
        guard let row = s.row, let impact = row.impact else {
            if isAuto {
                return [String(localized: "ZENO measures this once it has 5 days with it and 5 without, each with a Recovery."), tip]
                    .compactMap { $0 }.joined(separator: " ")
            }
            return tip.map { String(localized: "Keep answering yes and no so ZENO can measure it. \($0)") }
                ?? String(localized: "Answer this question yes or no every day for a while. ZENO needs at least 5 of each, on days with a Recovery, to measure it.")
        }
        switch BehaviorImpactFormat.effect(impact: impact, significant: row.significant) {
        case .hurts:
            return [String(localized: "Your own data links \(title) with a lower Recovery."), tip].compactMap { $0 }.joined(separator: " ")
        case .helps:
            return String(localized: "Your own data links \(title) with a higher Recovery. Keep it up, and consider making it a behavior goal in your Weekly Plan.")
        case .notSignificant:
            return isAuto
                ? String(localized: "There's no clear link between \(title) and your Recovery yet. ZENO checks again every day as your data grows.")
                : String(localized: "There's no clear link between \(title) and your Recovery yet. Keep logging it honestly, yes and no; ZENO checks again every day.")
        }
    }

    private var coachSeed: String {
        String(localized: "Explain how \(title) relates to my Recovery.")
    }

    // MARK: Loading

    private func load() async {
        let id = identity
        let edges = definition?.followUp?.bucketEdges
        // A custom numeric behaviour's own unit ("mg"), for its breakdown's labels.
        let unit = catalog.resolvedItems(imported: [], includeHidden: true)
            .first { PulseBehaviorLibrary.identity(for: $0.canonical) == id }?.kind.unitLabel
        if let s = await model.build(dayOffset: 0, { builder, r in
            let questions = await builder.importedJournalQuestions()
            return await builder.behaviorDetails(r, identity: id, followUpEdges: edges, customUnit: unit)
                .map { ($0, questions) }
        }) {
            names = BehaviorNames(catalog: catalog, imported: s.1, customTitles: local.customTitles,
                                  questions: s.0.question.map { [identity: $0] } ?? [:])
            snapshot = s.0
            #if DEBUG
            if JournalPlanDebug.detailsExpanded { expanded = true }
            #endif
        }
    }
}
#endif
