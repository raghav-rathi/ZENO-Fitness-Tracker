#if os(iOS)
import SwiftUI
import StrandAnalytics
import StrandDesign

/// Challenges (WHOOP_UI_SPEC §3.41), pushed from Trends › INSIGHTS.
///
/// WHOOP runs timed challenges for its members with rewards (profile-community-2026/13, 39, 42, 76, 84,
/// 85). ZENO's are the wearer's own (§3.41 [Z]): a target over a run of days, measured from the data every
/// other screen reads, with no reward and nothing leaving the phone. This page lists the ones running,
/// the kinds to start (activity minutes, Zone 2 minutes, steps, bedtime) and the finished ones; each opens
/// WHOOP's two pages: the join page (`PulseChallengeJoinView`) and the in-progress / complete page
/// (`PulseChallengeDetailView`).
///
/// Owned by group "extras".
struct PulseChallengesView: View {
    /// Rebuilt: the route opens this list (it has no classic counterpart).
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @State private var store = PulseChallengeStore.shared
    @State private var snapshot: ChallengesSnapshot?

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Challenges"), coach: .button, ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot { content(snapshot) }
            } skeleton: {
                PulseSkeleton.cards([112, 112, 84, 84, 84])
            }
        }
        .task(id: loadKey) { await load() }
        #if DEBUG
        .task {
            // Once per launch: the list's task runs again whenever it reappears (after popping the route).
            guard !Self.openedDebugRoute else { return }
            Self.openedDebugRoute = true
            openDebugRoute()
        }
        #endif
    }

    #if DEBUG
    @MainActor private static var openedDebugRoute = false
    #endif

    private var loadKey: String { PulseChallengesView.key(model: model, store: store) }

    /// Reload when a refresh lands or a challenge starts, ends or goes.
    static func key(model: PulseModel, store: PulseChallengeStore) -> String {
        "\(model.seq)|\(store.challenges.map { "\($0.id)\($0.leftOn ?? "")" }.joined(separator: ","))"
    }

    private func load() async {
        #if DEBUG
        store.seedDemoIfRequested(today: Repository.localDayKey(Date()))
        #endif
        let stored = store.challenges
        if let s = await model.build(dayOffset: 0, { builder, request in await builder.challenges(request, stored: stored) }) {
            snapshot = s
        }
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ s: ChallengesSnapshot) -> some View {
        let active = s.items.filter { $0.status.phase == .running || $0.status.phase == .upcoming
            || ($0.status.phase == .complete && $0.leftOn == nil && $0.definition.endDay >= s.today) }
        let finished = s.items.filter { item in !active.contains { $0.id == item.id } }
            .sorted { $0.definition.endDay > $1.definition.endDay }

        Text(String(localized: "Set a target and chase it with your own data. No rewards and no leaderboard, just you and your goal."))
            .pulseText(.body)
            .foregroundStyle(PulseTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)

        if !active.isEmpty {
            PulseSectionHeader(String(localized: "Active"), count: active.count)
                .padding(.top, PulseTheme.Layout.sectionGap - PulseTheme.Layout.stackGap)
            ForEach(active) { item in
                PulseLink(PulseChallengeDetailRoute(id: item.id).route) {
                    PulseChallengeCard(item: item)
                }
                .buttonStyle(PulsePressStyle())
            }
        }

        PulseSectionHeader(String(localized: "Start a challenge"))
            .padding(.top, PulseTheme.Layout.sectionGap - PulseTheme.Layout.stackGap)
        let canStart = store.runningCount(today: s.today) < PulseChallengeStore.maximumRunning
        if !canStart {
            Text(String(localized: "Three challenges are running. Finish or leave one to start another."))
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .padding(.horizontal, 4)
        }
        ForEach(ChallengeProgress.Kind.allCases, id: \.self) { kind in
            PulseLink(PulseChallengeJoinRoute(kind: kind).route) {
                PulseChallengeTemplateCard(kind: kind, today: s.today)
            }
            .buttonStyle(PulsePressStyle())
            .disabled(!canStart)
            .opacity(canStart ? 1 : 0.5)
        }

        if !finished.isEmpty {
            PulseSectionHeader(String(localized: "Finished"), count: finished.count)
                .padding(.top, PulseTheme.Layout.sectionGap - PulseTheme.Layout.stackGap)
            ForEach(finished) { item in
                PulseLink(PulseChallengeDetailRoute(id: item.id).route) {
                    PulseChallengeCard(item: item)
                }
                .buttonStyle(PulsePressStyle())
            }
        }
    }

    #if DEBUG
    /// `--pulse-challenge <id>` opens a challenge's page, `--pulse-challenge-join <kind>` a join page and
    /// `--pulse-zeno-live` the ZENO Live composer, so simctl (which cannot tap) can capture them.
    private func openDebugRoute() {
        let args = CommandLine.arguments
        if args.contains("--pulse-zeno-live") {
            navigator.open(PulseZenoLiveRoute().route)
        } else if let i = args.firstIndex(of: "--pulse-challenge"), i + 1 < args.count {
            navigator.push(PulseChallengeDetailRoute(id: args[i + 1]).route)
        } else if let i = args.firstIndex(of: "--pulse-challenge-join"), i + 1 < args.count,
                  let kind = ChallengeProgress.Kind(rawValue: args[i + 1]) {
            navigator.push(PulseChallengeJoinRoute(kind: kind).route)
        }
    }
    #endif
}

// MARK: - List cards

/// A running or finished challenge: its small gauge, title, progress and days left.
private struct PulseChallengeCard: View {
    let item: ChallengeSnapshot

    private typealias C = PulseExtrasTheme.Challenge

    var body: some View {
        let d = item.definition
        PulseCard {
            HStack(spacing: 16) {
                ZStack {
                    PulseChallengeGauge(fraction: item.status.fraction, color: d.kind.color, diameter: C.cardGauge)
                    Image(systemName: d.kind.symbol)
                        .font(.system(size: C.cardGlyphSize, weight: .regular))
                        .foregroundStyle(d.kind.color)
                }
                VStack(alignment: .leading, spacing: 6) {
                    PulseCardTitle(PulseChallengeText.navTitle(d), accessory: .chevron)
                    PulseValueText(value: PulseChallengeCard.logged(item), unit: "/\(PulseChallengeText.target(d))",
                                   style: .tileValue, unitStyle: .tileUnit)
                    status
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    static func logged(_ item: ChallengeSnapshot) -> String {
        let v = item.status.logged
        return item.definition.kind == .steps ? PulseFormat.grouped(v) : "\(Int(v.rounded(.down)))"
    }

    @ViewBuilder
    private var status: some View {
        switch item.status.phase {
        case .complete:
            Label(String(localized: "Complete"), systemImage: "checkmark")
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.positive)
        case .ended:
            Text(String(localized: "Ended \(YearReviewFormat.shortDate(item.leftOn ?? item.definition.endDay))"))
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textTertiary)
        case .running, .upcoming:
            HStack(spacing: 8) {
                PulseChallengeDaysLeft(daysLeft: item.status.daysLeft)
                if item.status.phase == .running && !item.status.isReachable {
                    Text(String(localized: "Out of reach"))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.negative)
                }
            }
        }
    }
}

/// "◷ 4 days left" with "4 days" in bold white over a regular line (WHOOP, profile-community-2026/76: 12 pt,
/// caps 8.4 pt), or "Last day".
private struct PulseChallengeDaysLeft: View {
    let daysLeft: Int

    var body: some View {
        Label {
            if daysLeft == 1 {
                Text(String(localized: "Last day"))
                    .fontWeight(.bold)
                    .foregroundStyle(PulseTheme.textPrimary)
            } else {
                Text(PulseChallengeText.daysLeft(daysLeft))
            }
        } icon: {
            Image(systemName: "clock")
        }
        .pulseText(.legend)
        .foregroundStyle(PulseTheme.textSecondary)
    }
}

/// A kind to start, with its suggested target.
private struct PulseChallengeTemplateCard: View {
    let kind: ChallengeProgress.Kind
    let today: String

    private typealias C = PulseExtrasTheme.Challenge

    var body: some View {
        let suggestion = ChallengeProgress.suggested(kind, startDay: today)
        PulseCard {
            HStack(spacing: 14) {
                Image(systemName: kind.symbol)
                    .font(.system(size: C.cardGlyphSize, weight: .regular))
                    .foregroundStyle(kind.color)
                    .frame(width: C.templateGlyphFrame, height: C.templateGlyphFrame)
                    .background(Circle().fill(kind.color.opacity(C.templateGlyphTint)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(PulseChallengeText.title(suggestion))
                        .pulseText(.coachingTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(kind.name)
                        .pulseText(.legend)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                Spacer(minLength: 8)
                PulseChevron()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Opens the challenge to set it up"))
    }
}

// MARK: - Routes

/// The join page for a kind.
struct PulseChallengeJoinRoute: PulseScreenRoute {
    let kind: ChallengeProgress.Kind
    var view: some View { PulseChallengeJoinView(kind: kind) }
}

/// A challenge's in-progress / complete page.
struct PulseChallengeDetailRoute: PulseScreenRoute {
    let id: String
    var view: some View { PulseChallengeDetailView(id: id) }
}

// MARK: - Shared page pieces

/// The gauge with its number: "168/250" over "MINUTES LOGGED", or the target alone on the join page, under
/// the page's top light.
private struct PulseChallengeHero: View {
    let kind: ChallengeProgress.Kind
    let fraction: Double
    let value: String
    let target: String?
    /// The words under the number (the join page names the goal instead of what was logged).
    var caption: String?
    var style: PulseChallengeGauge.Style = .progress

    private typealias C = PulseExtrasTheme.Challenge

    var body: some View {
        ZStack {
            PulseChallengeGauge(fraction: fraction, color: kind.color, style: style)
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(value)
                        .font(PulseType.numeral(C.valueSize))
                        .foregroundStyle(PulseTheme.textPrimary)
                    if let target {
                        Text(verbatim: "/\(target)")
                            .font(PulseType.numeral(C.targetSize))
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                // 12 pt Bold caps (13: "MINUTES LOGGED" caps 8.3 pt).
                Text(caption ?? kind.unitCaption)
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: C.gaugeDiameter - 2 * (C.tickHead + C.tickTail))
            // WHOOP's number group sits above the circle's centre, clear of the comb's open foot.
            .offset(y: -C.numberLift)
        }
        // The comb ends at 125° either side, so the circle's foot is empty: trim it, as WHOOP sets the
        // days-left line just under the comb's two ends.
        .frame(height: C.gaugeDiameter * C.gaugeVisibleHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) { topLight }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(target.map { String(localized: "\(value) of \($0), \(caption ?? kind.unitCaption)") }
                            ?? "\(value), \(caption ?? kind.unitCaption)")
    }

    /// The page's light at the top: white at the centre, flat for its first third, narrower across than down,
    /// over a wider wash of the challenge's colour that shows at the sides (WHOOP's is its branding).
    private var topLight: some View {
        ZStack(alignment: .top) {
            RadialGradient(colors: [kind.color.opacity(C.topTint), kind.color.opacity(0)], center: .top,
                           startRadius: 0, endRadius: C.topTintRadius)
                .frame(width: C.topTintSize.width, height: C.topTintSize.height)
            EllipticalGradient(stops: [
                .init(color: C.topLight, location: 0),
                .init(color: C.topLight, location: C.topLightSolid),
                .init(color: C.topLight.opacity(0), location: 1)
            ], center: .center)
                .frame(width: C.topLightSize.width, height: C.topLightSize.height)
                .offset(y: -C.topLightSize.height / 2)
        }
        .offset(y: -C.lightCentreAboveGauge)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The bottom button WHOOP pins on a challenge's page ("JOIN CHALLENGE", "ADD ACTIVITY"): a white rounded
/// rectangle with a black 11 pt caps label and no glyph, from 20 pt in to 16 pt short of the floating Coach
/// button, its centre a little above the Coach button's (84: 809.9 against 814.5 pt).
private struct PulseChallengeBottomButton: View {
    let title: String
    var enabled = true
    let action: () -> Void

    @Environment(\.pulseCoach) private var coach
    @Environment(\.pulseChrome) private var chrome

    private typealias C = PulseExtrasTheme.Challenge

    var body: some View {
        let coachShown = coach.availability != .off
        let coachSize = PulseTheme.TabBarMetrics.floatingCoachSize
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: C.buttonCoachGap) {
                Button(action: action) {
                    Text(title)
                        .pulseText(.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(PulseChallengeButtonStyle())
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.4)
                if coachShown { Color.clear.frame(width: coachSize, height: 1) }
            }
            .padding(.leading, C.buttonLeading)
            .padding(.trailing, coachShown ? PulseTheme.TabBarMetrics.floatingCoachInset : C.buttonLeading)
            .padding(.bottom, chrome.barBottomFromScreenBottom + (coachSize - C.buttonHeight) / 2 + C.buttonLift)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

/// White, 8 pt continuous corners, 48 pt tall, black label; 70% while pressed.
private struct PulseChallengeButtonStyle: ButtonStyle {
    private typealias C = PulseExtrasTheme.Challenge

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(C.buttonText)
            .frame(maxWidth: .infinity, minHeight: C.buttonHeight)
            .background(RoundedRectangle(cornerRadius: C.buttonRadius, style: .continuous).fill(C.buttonFill))
            .contentShape(RoundedRectangle(cornerRadius: C.buttonRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(PulseMotion.pressRelease, value: configuration.isPressed)
    }
}

// MARK: - Join

/// WHOOP's join page (profile-community-2026/84): the comb previewed in grey with the goal in it, when it
/// starts, the title and what counts, then ZENO's "YOUR GOAL" card where WHOOP's reward card sits (the wearer
/// sets the target, the length and, for bedtime, the time), and START CHALLENGE. Once started, the page turns
/// into the challenge's in-progress page, as WHOOP's does.
struct PulseChallengeJoinView: View {
    let kind: ChallengeProgress.Kind

    @State private var store = PulseChallengeStore.shared
    @State private var target: Int
    @State private var days: Int
    @State private var bedtime: Int
    @State private var startedID: String?
    @State private var showsMenu = false

    private typealias C = PulseExtrasTheme.Challenge

    init(kind: ChallengeProgress.Kind) {
        self.kind = kind
        let suggestion = ChallengeProgress.suggested(kind, startDay: Repository.localDayKey(Date()))
        _target = State(initialValue: suggestion.target)
        _days = State(initialValue: suggestion.days)
        _bedtime = State(initialValue: suggestion.bedtimeMinute ?? 23 * 60)
    }

    private var today: String { Repository.localDayKey(Date()) }

    private var definition: ChallengeProgress.Definition {
        ChallengeProgress.Definition(kind: kind, target: kind == .bedtime ? min(target, days) : target, days: days,
                                     startDay: today, bedtimeMinute: kind == .bedtime ? bedtime : nil)
    }

    var body: some View {
        if let startedID {
            PulseChallengeDetailView(id: startedID)
        } else {
            join
        }
    }

    private var join: some View {
        let d = definition
        let canStart = store.runningCount(today: today) < PulseChallengeStore.maximumRunning
        return PulseScreenScaffold(title: PulseChallengeText.navTitle(d), coach: .button) {
            VStack(spacing: 0) {
                PulseChallengeHero(kind: kind, fraction: 0, value: PulseChallengeText.target(d), target: nil,
                                   caption: kind.goalCaption, style: .preview)
                    .padding(.top, 8)
                Label(String(localized: "Starts today, ends \(YearReviewFormat.weekdayDate(d.endDay))"),
                      systemImage: "clock")
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, 10)
                VStack(alignment: .leading, spacing: 8) {
                    Text(PulseChallengeText.title(d))
                        .pulseText(.pageTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(PulseChallengeText.body(d))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, C.headlineGap)
                if !canStart {
                    // Above the card, where the pinned button cannot cover it.
                    Text(String(localized: "Three challenges are running. Finish or leave one to start another."))
                        .pulseText(.legend)
                        .foregroundStyle(PulseTheme.negative)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                }
                goalCard
                    .padding(.top, 20)
            }
        }
        .challengeNavTrailing {
            Button { showsMenu = true } label: { PulseChallengeMoreGlyph() }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "More"))
        }
        .confirmationDialog(String(localized: "Challenge"), isPresented: $showsMenu, titleVisibility: .hidden) {
            Button(String(localized: "Reset to Suggested Goal")) { resetGoal() }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
        .overlay {
            PulseChallengeBottomButton(title: String(localized: "Start challenge"), enabled: canStart) {
                if let started = store.start(definition, today: today) { startedID = started.id }
            }
        }
    }

    private func resetGoal() {
        let suggestion = ChallengeProgress.suggested(kind, startDay: today)
        target = suggestion.target
        days = suggestion.days
        bedtime = suggestion.bedtimeMinute ?? 23 * 60
    }

    /// The wearer's goal: the target, the length and (bedtime) the time. Rows sit close (8 pt) so all three
    /// of bedtime's clear the pinned button at the default text size.
    private var goalCard: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 8) {
                PulseCardTitle(String(localized: "Your goal"))
                if kind == .bedtime {
                    stepper(String(localized: "Asleep by"), value: PulseChallengeText.clock(minute: bedtime),
                            canDecrease: bedtime > 20 * 60, canIncrease: bedtime < 24 * 60 + 2 * 60,
                            decrease: { bedtime -= 15 }, increase: { bedtime += 15 })
                    PulseDivider()
                    stepper(String(localized: "Nights on time"),
                            value: String(localized: "\(min(target, days)) of \(days)"),
                            canDecrease: target > 1, canIncrease: target < days,
                            decrease: { target = max(1, min(target, days) - 1) },
                            increase: { target = min(days, target + 1) })
                } else {
                    stepper(kind.name, value: PulseChallengeText.target(definition),
                            canDecrease: target > kind.targetRange.lowerBound,
                            canIncrease: target < kind.targetRange.upperBound,
                            decrease: { target = max(kind.targetRange.lowerBound, target - kind.targetStep) },
                            increase: { target = min(kind.targetRange.upperBound, target + kind.targetStep) })
                }
                PulseDivider()
                stepper(String(localized: "Length"), value: PulseChallengeText.inflected("^[\(days) day](inflect: true)"),
                        canDecrease: days > 3, canIncrease: days < 30,
                        decrease: { days -= 1 }, increase: {
                            days += 1
                            if kind == .bedtime && target == days - 1 { target = days }
                        })
            }
        }
    }

    private func stepper(_ title: String, value: String, canDecrease: Bool, canIncrease: Bool,
                         decrease: @escaping () -> Void, increase: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .pulseText(.rowText)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            stepButton("minus", enabled: canDecrease, label: String(localized: "Less"), action: decrease)
            Text(value)
                .pulseText(.rowValue)
                .foregroundStyle(PulseTheme.textPrimary)
                .frame(minWidth: C.stepValueWidth)
                .multilineTextAlignment(.center)
            stepButton("plus", enabled: canIncrease, label: String(localized: "More"), action: increase)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if canIncrease { increase() }
            case .decrement: if canDecrease { decrease() }
            @unknown default: break
            }
        }
    }

    private func stepButton(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: C.stepGlyphSize, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: C.stepButton, height: C.stepButton)
                .background(Circle().fill(PulseTheme.nested))
                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

// MARK: - In progress / complete

/// WHOOP's in-progress and complete pages (profile-community-2026/76, 13, 42): the gauge lit to the
/// progress with "168/250" in it, the days left or "✓ Complete", a headline and sentence, then what
/// counted, by day, in a card pointing up at the gauge. While it runs, an activity challenge offers ADD
/// ACTIVITY and a Zone 2 one START ACTIVITY (a hand-added activity has no heart rate, so it adds no Zone 2
/// minutes). "ooo" leaves the challenge or removes it.
struct PulseChallengeDetailView: View {
    let id: String

    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.dismiss) private var dismiss
    @State private var store = PulseChallengeStore.shared
    @State private var snapshot: ChallengesSnapshot?
    @State private var showsMenu = false

    private typealias C = PulseExtrasTheme.Challenge

    private var item: ChallengeSnapshot? { snapshot?.items.first { $0.id == id } }

    var body: some View {
        PulseScreenScaffold(title: item.map { PulseChallengeText.navTitle($0.definition) } ?? String(localized: "Challenge"),
                            coach: .button, ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let item { content(item) } else if snapshot != nil { gone }
            } skeleton: {
                PulseSkeleton.cards([228, 64, 160])
            }
        }
        .challengeNavTrailing {
            Button { showsMenu = true } label: { PulseChallengeMoreGlyph() }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "More"))
        }
        .overlay {
            if let item, item.status.phase == .running {
                switch item.definition.kind {
                case .activityMinutes:
                    PulseChallengeBottomButton(title: String(localized: "Add activity")) {
                        navigator.quickAction(.addActivity)
                    }
                case .zoneMinutes:
                    PulseChallengeBottomButton(title: String(localized: "Start activity")) {
                        navigator.quickAction(.workout)
                    }
                case .steps, .bedtime:
                    EmptyView()
                }
            }
        }
        .confirmationDialog(String(localized: "Challenge"), isPresented: $showsMenu, titleVisibility: .hidden) {
            if let item, item.leftOn == nil, item.status.phase == .running {
                Button(String(localized: "Leave Challenge"), role: .destructive) {
                    store.leave(id, today: Repository.localDayKey(Date()))
                }
            }
            Button(String(localized: "Remove from List"), role: .destructive) {
                store.remove(id)
                dismiss()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
        .task(id: PulseChallengesView.key(model: model, store: store)) {
            let stored = store.challenges.filter { $0.id == id }
            if let s = await model.build(dayOffset: 0, { builder, request in await builder.challenges(request, stored: stored) }) {
                snapshot = s
            }
        }
    }

    @ViewBuilder
    private func content(_ item: ChallengeSnapshot) -> some View {
        let d = item.definition
        VStack(spacing: 0) {
            PulseChallengeHero(kind: d.kind, fraction: item.status.fraction, value: PulseChallengeCard.logged(item),
                               target: PulseChallengeText.target(d))
                .padding(.top, 8)
            phaseLine(item)
                .padding(.top, 10)
            VStack(alignment: .leading, spacing: 8) {
                Text(PulseChallengeText.headline(item))
                    .pulseText(.pageTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(PulseChallengeText.detail(item))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, C.headlineGap)
            days(item)
                .padding(.top, 24)
        }
    }

    @ViewBuilder
    private func phaseLine(_ item: ChallengeSnapshot) -> some View {
        switch item.status.phase {
        case .complete:
            Label(String(localized: "Complete"), systemImage: "checkmark")
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textPrimary)
                .labelStyle(PulseCheckLabelStyle())
        case .ended:
            Label(String(localized: "Ended \(YearReviewFormat.shortDate(item.leftOn ?? item.definition.endDay))"),
                  systemImage: "flag.checkered")
                .pulseText(.secondary)
                .foregroundStyle(PulseTheme.textSecondary)
        case .running, .upcoming:
            PulseChallengeDaysLeft(daysLeft: item.status.daysLeft)
        }
    }

    /// What counted, newest day first, in a card that points up at the gauge, lit along its top edge.
    @ViewBuilder
    private func days(_ item: ChallengeSnapshot) -> some View {
        let pointer = C.pointer
        let shape = PulseNotchedRectangle(cornerRadius: PulseTheme.Radius.card, notchWidth: pointer.width,
                                          notchHeight: pointer.height)
        VStack(alignment: .leading, spacing: 12) {
            if item.days.isEmpty {
                Text(emptyText(item))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(item.days) { day in
                PulseListSectionHeader(dayTitle(day.id, today: snapshot?.today ?? day.id))
                ForEach(day.entries) { entry in
                    row(entry)
                }
            }
        }
        .padding(16)
        .padding(.top, pointer.height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(C.listCard))
        .overlay {
            shape.stroke(LinearGradient(colors: [C.listCardRim, C.listCardRim.opacity(0)], startPoint: .top,
                                        endPoint: .center), lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func row(_ entry: ChallengeEntry) -> some View {
        switch entry {
        case .workout(let w, let end):
            PulseLink(PulseRoute.activityDetail(w.route).forExistingEntryPoint) {
                PulseActivityRow(
                    chip: PulseActivityChip(kind: w.strain == nil ? .pending : .strain,
                                            symbol: WorkoutTypeIconography.systemSymbolName(for: w.sport),
                                            value: w.strain.map { PulseFormat.oneDecimal($0) }),
                    name: w.title, start: PulseFormat.clock(w.start), end: PulseFormat.clock(end),
                    barColor: PulseTheme.strain)
            }
            .buttonStyle(PulsePressStyle())
        case .amount(_, let title, let value, let met):
            HStack(spacing: 12) {
                Text(title)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                Spacer(minLength: 8)
                Text(value)
                    .pulseText(.rowValue)
                    .foregroundStyle(PulseTheme.textPrimary)
                if let met {
                    PulseStatusBadge(met ? .check : .alert, tint: met ? .teal : .orange)
                        .accessibilityLabel(met ? String(localized: "On time") : String(localized: "Late"))
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: PulseTheme.Row.activity)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                .fill(PulseTheme.nested))
            .accessibilityElement(children: .combine)
        }
    }

    private func emptyText(_ item: ChallengeSnapshot) -> String {
        switch item.definition.kind {
        case .activityMinutes: return String(localized: "No activity logged yet. Start one or add one and it counts here.")
        case .zoneMinutes: return String(localized: "No Zone 2 time yet. Wear your strap and it counts as it syncs.")
        case .steps: return String(localized: "No steps counted yet.")
        case .bedtime: return String(localized: "No nights yet. Tonight is the first one.")
        }
    }

    /// "TODAY", "YESTERDAY", or "TUE, JUN 30, 2026" (a day key, formatted at UTC).
    private func dayTitle(_ key: String, today: String) -> String {
        if key == today { return String(localized: "Today") }
        if key == PulseDisplay.dayKey(today, offsetBy: -1) { return String(localized: "Yesterday") }
        return PulseFormat.dayLabel(key, template: "EEEMMMdyyyy")
    }

    private var gone: some View {
        Text(String(localized: "This challenge is no longer on your list."))
            .pulseText(.body)
            .foregroundStyle(PulseTheme.textSecondary)
            .padding(.top, 40)
    }
}

/// "✓ Complete" with WHOOP's teal check (profile-community-2026/13).
private struct PulseCheckLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .font(.system(size: PulseExtrasTheme.Challenge.checkSize, weight: .bold))
                .foregroundStyle(PulseTheme.positive)
            configuration.title
        }
    }
}
#endif
