#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Behavior Insights (WHOOP_UI_SPEC §3.18), pushed.
///
/// "Recovery Impact Analysis" over the last 90 days: the HURTS · % IMPACT · HELPS legend, then each tested
/// behaviour's card (its name, ✧ when ZENO tracks it from its own data, and the diverging bar with its %
/// impact: green when it helps, orange when it hurts, grey when the difference is not significant), then
/// KEEP LOGGING TO UNLOCK with the outlined cards of behaviours that are not tested yet and their ✕ / ✓
/// counts, and a card into SELECT BEHAVIORS. A behaviour is tested once it has 5 yes and 5 no days that
/// carry a Recovery, and only after 10 Recoveries in all (`BehaviorImpact`). A card opens Behavior Details.
struct PulseBehaviorInsightsView: View {
    /// The rebuilt page: Home's BEHAVIOR INSIGHTS button opens it.
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @StateObject private var catalog = JournalCatalogStore()
    @State private var local = PulseJournalLocalStore.shared
    @State private var snapshot: BehaviorInsightsSnapshot?
    @State private var imported: [String] = []
    @State private var showSelector = false
    #if DEBUG
    @State private var debugDetails: PulseBehaviorDetailsRoute?
    #endif

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Behavior Insights"), coach: .button,
                            coachSeed: String(localized: "Help me understand which of my behaviors move my Recovery."),
                            ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot { content(snapshot) }
            } skeleton: {
                VStack(alignment: .leading, spacing: 12) {
                    PulseSkeletonBlock(height: 26, width: 240, radius: 6)
                    PulseSkeletonBlock(height: 54, radius: 6)
                    PulseSkeleton.cards([68, 68, 68, 68, 68])
                        .padding(.top, 12)
                }
            }
        }
        // An always-today page: it reloads with the data, not with Home's selected day.
        .task(id: model.healthKey) { await load() }
        .sheet(isPresented: $showSelector) {
            PulseSelectBehaviorsView(catalog: catalog, importedQuestions: imported) {
                Task { await load() }
            }
        }
        #if DEBUG
        .navigationDestination(item: $debugDetails) { $0.view }
        #endif
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ s: BehaviorInsightsSnapshot) -> some View {
        let names = BehaviorNames(catalog: catalog, imported: imported, customTitles: local.customTitles,
                                  questions: s.questions)
        let locked = lockedRows(s, names: names)
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "Recovery Impact Analysis"))
                .pulseText(.weeklyTrendsTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(String(localized: "See how behaviors impacted your Recovery over the past 90 days. Tap on a behavior to view more details."))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            if !s.unlocked.isEmpty {
                legend
                    .padding(.top, PulseTheme.JournalPlan.insightsLegendTop)
                VStack(spacing: PulseTheme.JournalPlan.insightsCardGap) {
                    ForEach(s.unlocked) { row in
                        PulseLink(PulseBehaviorDetailsRoute(identity: row.id).route) {
                            unlockedCard(row, title: names.title(row.id), scale: s.scale)
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
                .padding(.top, PulseTheme.JournalPlan.insightsListTop)
            }

            if !locked.isEmpty || s.recoveries < s.recoveriesNeeded {
                Text(String(localized: "Keep logging to unlock"))
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.top, s.unlocked.isEmpty ? 28 : 36)
                    .accessibilityAddTraits(.isHeader)
                Text(keepLoggingBody(s))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                VStack(spacing: PulseTheme.JournalPlan.insightsCardGap) {
                    ForEach(locked, id: \.row.id) { item in
                        PulseLink(PulseBehaviorDetailsRoute(identity: item.row.id).route) {
                            lockedCard(item.row, title: item.title)
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
                .padding(.top, 14)
            }

            exploreCard
                .padding(.top, 24)
        }
        .padding(.top, 8)
        #if DEBUG
        .onAppear { openDebugDetails(s) }
        #endif
    }

    /// ▼ HURTS · % IMPACT · HELPS ▲, each side on its tinted chip.
    private var legend: some View {
        HStack(spacing: 8) {
            legendChip(symbol: "arrowtriangle.down.fill", fill: PulseTheme.Delta.unfavourableFill,
                       color: PulseTheme.Delta.unfavourableText)
            Text(String(localized: "Hurts"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.Delta.unfavourableText)
            Spacer(minLength: 4)
            Text(String(localized: "% Impact"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 4)
            Text(String(localized: "Helps"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.Delta.favourableText)
            legendChip(symbol: "arrowtriangle.up.fill", fill: PulseTheme.Delta.favourableFill,
                       color: PulseTheme.Delta.favourableText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Percent impact on Recovery: behaviors that hurt on the left, that help on the right"))
    }

    /// A 15 pt tinted square with a small 8 pt triangle (journal-plan-2026/20).
    private func legendChip(symbol: String, fill: Color, color: Color) -> some View {
        Image(systemName: symbol)
            .font(PulseTheme.JournalPlan.legendGlyph)
            .foregroundStyle(color)
            .frame(width: PulseTheme.JournalPlan.legendChipSize, height: PulseTheme.JournalPlan.legendChipSize)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular).fill(fill))
    }

    private func unlockedCard(_ row: BehaviorImpactRowData, title: String, scale: Double) -> some View {
        let effect = BehaviorImpactFormat.effect(impact: row.impact, significant: row.significant)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .pulseText(.filter)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if row.isAuto { autoChip }
                Spacer(minLength: 8)
                PulseChevron(color: PulseTheme.textTertiary, size: 14)
            }
            PulseImpactBar(fraction: BehaviorImpactFormat.fraction(row.impact, scale: scale), effect: effect,
                           valueText: row.impact.map(BehaviorImpactFormat.text) ?? "--")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(PulseTheme.JournalPlan.insightsCard))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(spokenImpact(row))
        .accessibilityHint(String(localized: "Opens Behavior Details"))
    }

    /// The ✧ chip after an auto-tracked behaviour's name: a small light-blue sparkle cluster in an 18 pt
    /// square, lighter than the name (journal-plan-2026/20).
    private var autoChip: some View {
        Image(systemName: "sparkles")
            .font(PulseTheme.JournalPlan.autoChipGlyphFont)
            .foregroundStyle(PulseTheme.JournalPlan.autoChipGlyph)
            .frame(width: PulseTheme.JournalPlan.autoChipSize, height: PulseTheme.JournalPlan.autoChipSize)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                .fill(PulseTheme.JournalPlan.autoChip))
            .accessibilityLabel(String(localized: "Tracked automatically"))
    }

    private func lockedCard(_ row: BehaviorImpactRowData, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .pulseText(.filter)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if row.isAuto { autoChip }
                Spacer(minLength: 8)
                PulseChevron(color: PulseTheme.textTertiary, size: 14)
            }
            if let subtitle = lockedSubtitle(row) {
                Text(subtitle)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 14) {
                BehaviorLockedTrack()
                JournalCountBadges(no: row.no, yes: row.yes, enough: BehaviorImpact.minAnswers)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pulseCardBackground(.outlined)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue([lockedSubtitle(row), String(localized: "\(row.yes) yes, \(row.no) no in the last 90 days")]
            .compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(String(localized: "Opens Behavior Details"))
    }

    /// The end card: more behaviours to track, into SELECT BEHAVIORS.
    private var exploreCard: some View {
        Button { showSelector = true } label: {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Track more behaviors"))
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "The more you log, the more ZENO can tell you about what moves your Recovery."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(String(localized: "Select behaviors")).pulseText(.label)
                        Image(systemName: "arrow.right").font(PulseTheme.JournalPlan.smallGlyph)
                    }
                    .foregroundStyle(PulseTheme.Plan.exploreCTA)
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
                Image(systemName: "book.pages")
                    .font(PulseTheme.JournalPlan.rowGlyph)
                    .imageScale(.large)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(PulseTheme.card))
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.JournalPlan.insightsCard))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }

    // MARK: Copy

    private func keepLoggingBody(_ s: BehaviorInsightsSnapshot) -> String {
        if s.recoveries < s.recoveriesNeeded {
            return String(localized: "Behavior Insights start after \(s.recoveriesNeeded) Recoveries; you have \(s.recoveries) so far. Then record at least 5 yes's and no's in your journal to see how behaviors impact your Recovery.")
        }
        return String(localized: "Record at least 5 yes's and no's in your journal to see how behaviors impact your Recovery.")
    }

    /// A locked card's line: none while answers are short (the counts already say so), and ZENO's own
    /// wording when enough answers exist but too few of those days have a Recovery.
    private func lockedSubtitle(_ row: BehaviorImpactRowData) -> String? {
        switch row.lock {
        case .needsRecoveryDays?:
            return String(localized: "Not enough of these days have a Recovery yet. Please keep logging responses.")
        default:
            return nil
        }
    }

    private func spokenImpact(_ row: BehaviorImpactRowData) -> String {
        guard let impact = row.impact else { return "" }
        let text = BehaviorImpactFormat.text(impact)
        return row.significant ? String(localized: "\(text) impact on Recovery")
                               : String(localized: "\(text), not a significant difference")
    }

    // MARK: Rows

    /// The locked rows to show: anything answered in the last 90 days, plus every journal behaviour not
    /// answered yet (it still invites logging), by name.
    private func lockedRows(_ s: BehaviorInsightsSnapshot, names: BehaviorNames) -> [(row: BehaviorImpactRowData, title: String)] {
        var rows = s.locked.filter { $0.yes + $0.no > 0 || names.selected.contains($0.id) }
        let known = Set(s.unlocked.map(\.id) + s.locked.map(\.id))
        for id in names.selected where !known.contains(id) {
            rows.append(BehaviorImpactRowData(BehaviorImpact.Row(behavior: id, yesCount: 0, noCount: 0, effect: nil,
                                                                 lock: s.recoveries < s.recoveriesNeeded ? .calibrating : .needsAnswers),
                                              isAuto: false))
        }
        return rows.map { ($0, names.title($0.id)) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func load() async {
        if let s = await model.build(dayOffset: 0, { builder, r in
            builder.begin(r.seq)        // the questions' cache belongs to this refresh
            let questions = await builder.importedJournalQuestions()
            return await builder.behaviorInsights(r).map { ($0, questions) }
        }) {
            imported = s.1
            snapshot = s.0
        }
    }

    #if DEBUG
    private func openDebugDetails(_ s: BehaviorInsightsSnapshot) {
        guard debugDetails == nil, let id = JournalPlanDebug.detailsIdentity else { return }
        let target = id == "first" ? s.unlocked.first?.id : id
        if let target { debugDetails = PulseBehaviorDetailsRoute(identity: target) }
    }
    #endif
}

// MARK: - Names

/// How the behaviour pages name a behaviour identity: the auto-tracked behaviour's name, the journal's
/// own resolution of its catalog item (a custom name or a rename included), the library's name, or the
/// question itself.
struct BehaviorNames {
    private let byIdentity: [String: PulseBehavior]
    private let questions: [String: String]
    /// The identities of the behaviours currently in the journal.
    let selected: Set<String>

    @MainActor
    init(catalog: JournalCatalogStore, imported: [String], customTitles: [String: String], questions: [String: String]) {
        var map: [String: PulseBehavior] = [:]
        var selected = Set<String>()
        for item in catalog.resolvedItems(imported: imported, includeHidden: true) {
            let b = PulseBehaviorLibrary.behavior(for: item, customTitles: customTitles)
            let id = PulseBehaviorLibrary.identity(for: b.canonical)
            if map[id] == nil || (b.isSelected && map[id]?.isSelected == false) { map[id] = b }
            if b.isSelected { selected.insert(id) }
        }
        byIdentity = map
        self.questions = questions
        self.selected = selected
    }

    func behavior(_ id: String) -> PulseBehavior? { byIdentity[id] }

    func title(_ id: String) -> String {
        if let auto = PulseBehaviorLibrary.Auto(rawValue: id) { return auto.title }
        if let b = byIdentity[id] { return b.title }
        if id.hasPrefix("lib."), let d = PulseBehaviorLibrary.definition(id: String(id.dropFirst(4))) { return d.title }
        return PulseBehaviorLibrary.derivedTitle(questions[id] ?? id)
    }

    func question(_ id: String) -> String? {
        if PulseBehaviorLibrary.Auto(rawValue: id) != nil { return nil }
        if let b = byIdentity[id] { return b.question }
        if id.hasPrefix("lib."), let d = PulseBehaviorLibrary.definition(id: String(id.dropFirst(4))) { return d.question }
        return questions[id]
    }
}

extension BehaviorNames {
    /// Names for behaviours shown outside the page, from the sources their snapshot's build carried.
    @MainActor
    init(catalog: JournalCatalogStore, customTitles: [String: String], sources: BehaviorNameSources) {
        self.init(catalog: catalog, imported: sources.imported, customTitles: customTitles,
                  questions: sources.questions)
    }
}

/// Behavior Details for one behaviour, pushed from Behavior Insights (§1.6: push from Insights).
struct PulseBehaviorDetailsRoute: PulseScreenRoute {
    let identity: String

    var view: some View { PulseBehaviorDetailsView(identity: identity) }
}
#endif
