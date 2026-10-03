#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Coaching card stack (WHOOP_UI_SPEC §3.14, §2.6 item 5)
//
// One card shows; the next peeks 12 pt underneath (inset 16 pt each side, #1B1F22). The card is white
// ≈7.5% (a shade under a standard card), radius 12: a 15 pt Semibold title, up to four lines of 14 pt
// Medium body at 70%, an optional blue caps CTA, ZENO's own line art at the right, and the counter chip
// at the top-right (white 12%, radius 6) with ✓ over the number of cards left. Tapping ✓ completes the top
// card for the day and the next one rises; tapping the card opens its destination. Feature cards (the
// week in review, release notes) swap the fill for a gradient border.
//
// The cards come from `HomeCoachingRules` (StrandAnalytics), fed by the day's own data, then the wearer's own
// milestones (`PulseHomeMilestones`, §3.30), running challenges (`PulseChallengeFeed`, §3.41) and, when
// Settings' Auto-detect workouts is on, a workout the strap's heart rate suggests (SAVE / DISMISS instead of a
// CTA): no server feed, so there is no "Couldn't load" state.

/// One card, with its copy and destination resolved.
struct PulseCoachingCardModel: Identifiable, Equatable {
    enum Style: Equatable {
        case standard
        /// A gradient-bordered announcement (§2.1 feature-announce border).
        case feature
    }

    let id: String
    let title: String
    let body: String
    var cta: String?
    /// ZENO's art for the card (an SF Symbol).
    let symbol: String
    var style: Style = .standard
    /// Where tapping the card (or its CTA) goes.
    let route: PulseRoute?
    /// A card that asks for a decision instead of opening a destination (the auto-detected workout's SAVE /
    /// DISMISS): its two caps actions stand where the CTA would, and the card itself opens nothing.
    var decision: Decision?

    struct Decision: Equatable {
        /// The blue action ("Save").
        let accept: String
        /// The grey one beside it ("Dismiss").
        let decline: String
    }
}

/// The stack itself: draws `cards` (most important first) and reports the ✓ on the top card.
struct PulseCoachingStack: View {
    /// The stack is built and placed on Home.
    static let isRebuilt = true

    let cards: [PulseCoachingCardModel]
    let onComplete: (PulseCoachingCardModel) -> Void
    let onOpen: (PulseCoachingCardModel) -> Void
    /// A decision card's action: true for its accept, false for its decline.
    var onDecide: (PulseCoachingCardModel, Bool) -> Void = { _, _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        if let top = cards.first {
            card(top)
                .id(top.id)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .opacity,
                                                                  removal: .opacity.combined(with: .offset(y: -8))))
                // The next card peeks 12 pt below, inset 16 pt each side: only its bottom edge shows, so it
                // never reads through the translucent card above it.
                .background(alignment: .bottom) {
                    if cards.count > 1 {
                        UnevenRoundedRectangle(bottomLeadingRadius: PulseTheme.Radius.card,
                                               bottomTrailingRadius: PulseTheme.Radius.card, style: .circular)
                            .fill(PulseTheme.coachingPeek)
                            .frame(height: Self.peek)
                            .padding(.horizontal, PulseTheme.Space.m)
                            .offset(y: Self.peek)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.bottom, cards.count > 1 ? Self.peek : 0)
                .animation(PulseMotion.resolved(PulseMotion.crossFade, reduceMotion: reduceMotion), value: top.id)
        }
    }

    /// How far the next card shows under the top one.
    private static let peek: CGFloat = 12

    @ViewBuilder
    private func card(_ model: PulseCoachingCardModel) -> some View {
        if let decision = model.decision {
            // Nothing to open: the card holds its two actions, each a button of its own for VoiceOver too.
            layout(model) {
                decisionRow(model, decision)
            }
            .accessibilityElement(children: .contain)
            .overlay(alignment: .topTrailing) { counter(model) }
        } else {
            Button { onOpen(model) } label: {
                layout(model) {
                    if let cta = model.cta {
                        HStack(spacing: 6) {
                            Text(cta).pulseText(.label)
                            Image(systemName: "arrow.right").pulseText(.label)
                        }
                        .foregroundStyle(ctaStyle(model))
                        .padding(.top, PulseTheme.Space.xs)
                        .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.title)
            .accessibilityValue(model.body)
            .accessibilityHint(model.route == nil ? "" : String(localized: "Opens details"))
            .accessibilityAddTraits(.isButton)
            .overlay(alignment: .topTrailing) { counter(model) }
        }
    }

    /// The card's frame: title, body and `actions` (the CTA or a decision's two actions) beside ZENO's art.
    private func layout<Actions: View>(_ model: PulseCoachingCardModel,
                                       @ViewBuilder actions: () -> Actions) -> some View {
        HStack(alignment: .center, spacing: PulseTheme.Space.s) {
            VStack(alignment: .leading, spacing: PulseTheme.Space.xxs) {
                Text(model.title)
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                // Up to four lines at the default sizes (§2.6 item 5); the card grows with larger text.
                Text(model.body)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(typeSize > .xxLarge ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                actions()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: model.symbol)
                .font(PulseHomeGlyph.art(46, weight: .ultraLight))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(width: PulseHomeMetrics.coachingArtWidth)
                .accessibilityHidden(true)
        }
        .padding(.leading, PulseTheme.Layout.cardPadding + 4)
        .padding(.trailing, PulseTheme.Layout.cardPadding + 34)
        .padding(.vertical, PulseTheme.Layout.cardPadding + 6)
        .frame(maxWidth: .infinity, minHeight: PulseHomeMetrics.coachingCardMinHeight, alignment: .leading)
        .background(surface(model))
    }

    /// A decision's two caps actions where the CTA sits: the accept in the CTA's blue, the decline grey, each
    /// a full 44 × 44 pt tap target however short its word (its height stands in for the CTA's top gap, and
    /// the word stays flush with the body above it).
    private func decisionRow(_ model: PulseCoachingCardModel, _ decision: PulseCoachingCardModel.Decision) -> some View {
        HStack(spacing: PulseTheme.Space.l) {
            Button { onDecide(model, true) } label: {
                Text(decision.accept)
                    .pulseText(.label)
                    .foregroundStyle(ctaStyle(model))
                    .frame(minWidth: PulseTheme.Layout.minTapTarget, minHeight: PulseTheme.Layout.minTapTarget,
                           alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            Button { onDecide(model, false) } label: {
                Text(decision.decline)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(minWidth: PulseTheme.Layout.minTapTarget, minHeight: PulseTheme.Layout.minTapTarget,
                           alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }
    }

    /// ✓ over the number of cards left: completes the top card for the day.
    private func counter(_ model: PulseCoachingCardModel) -> some View {
        Button { onComplete(model) } label: {
            // 24 × 46 pt, 8 pt in from the card's top-right corner (profile-community-2026/34).
            VStack(spacing: 7) {
                Image(systemName: "checkmark").pulseHomeGlyph(.counterCheck)
                Text(verbatim: "\(cards.count)")
                    .font(PulseType.numeral(14))
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            .foregroundStyle(PulseTheme.textPrimary)
            .frame(width: PulseHomeMetrics.counterChip.width, height: PulseHomeMetrics.counterChip.height)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.toggle, style: .circular)
                .fill(PulseTheme.tagFill))
            .padding(PulseTheme.Space.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(String(localized: "Done with this card"))
        .accessibilityValue(String(localized: "\(cards.count) cards"))
    }

    @ViewBuilder
    private func surface(_ model: PulseCoachingCardModel) -> some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        switch model.style {
        case .standard:
            shape.fill(PulseTheme.coachingCard)
        case .feature:
            shape.fill(PulseTheme.Gradients.featureAnnounceFill)
                .overlay(shape.strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.featureAnnounceBorder,
                                                           startPoint: .leading, endPoint: .trailing),
                                            lineWidth: 1.5))
        }
    }

    private func ctaStyle(_ model: PulseCoachingCardModel) -> AnyShapeStyle {
        switch model.style {
        case .standard: return AnyShapeStyle(PulseTheme.recoveryBlue)
        case .feature:
            return AnyShapeStyle(LinearGradient(gradient: PulseTheme.Gradients.featureAnnounceBorder,
                                                startPoint: .leading, endPoint: .trailing))
        }
    }
}

// MARK: - Host

/// Places the stack on Home, with the monitor tiles under it (their gap follows whether a card shows):
/// evaluates the rules from the day's inputs plus the app state they need (the illness heads-up, unseen
/// release notes, the current minute for this morning's alarm), adds today's milestones, the running
/// challenges and the opt-in auto-detected workout, drops the cards completed today, and opens a card's
/// destination or saves or dismisses the workout. Its own leaf because the illness flag lives on `AppModel`,
/// which publishes every heart-rate tick: the content below only redraws when its inputs change.
struct PulseCoachingStackHost: View {
    let base: HomeCoachingRules.Inputs
    let home: HomeSnapshot
    /// The monitor tiles' inputs (see `PulseMonitorTiles`).
    let grades: PulseMonitorGrades?
    let stress: PulseStressSummary?
    let stressUpdated: String?
    /// Today's profile figures: the snapshot Home's unlock modal is evaluated with, so a milestone card
    /// and the modal read one source.
    let profile: ProfileSnapshot?

    @EnvironmentObject private var app: AppModel
    @Environment(PulseModel.self) private var model
    /// The day-streak milestone the unlock modal last announced, with its day (`PulseHomeView` stores it).
    @AppStorage(PulseHomeMilestones.announcedStreakKey) private var announcedStreak = ""
    /// The challenges running today, measured by the builder the Challenges pages use, so a card and the
    /// page it opens state the same progress.
    @State private var challenges: [ChallengeSnapshot] = []
    /// Settings' Auto-detect workouts (opt-in, off by default): the workout card is offered only while it is on.
    @AppStorage(PuffinExperiment.autoDetectWorkoutsKey) private var autoDetect = false
    /// The workout the detector suggests, while one is pending (`homeDetectedWorkout`).
    @State private var detected: DetectedWorkout?
    /// Windows saved or dismissed in this session (their start): a scan that began before the save landed
    /// cannot bring one back.
    @State private var handled: Set<Int> = []

    private var milestones: [PulseHomeMilestones.Card] {
        #if DEBUG
        if let forced = PulseHomeMilestones.debugCards(profile) { return forced }
        #endif
        return PulseHomeMilestones.cards(profile, acknowledgedStreak: ProfileUnlockStore.acknowledgedStreakMilestone,
                                         announcedStreak: announcedStreak)
    }

    var body: some View {
        PulseCoachingStackContent(base: base, home: home, grades: grades, stress: stress, stressUpdated: stressUpdated,
                                  illness: app.healthAlert.map { localizedHealthAlertCopy($0) },
                                  milestones: milestones, challenges: challenges,
                                  detected: autoDetect ? detected : nil,
                                  onSaveWorkout: save, onDismissWorkout: dismiss)
            .equatable()
            // The Challenges page's own reload key: a refresh, or a challenge started, left or removed.
            .task(id: PulseChallengesView.key(model: model, store: PulseChallengeStore.shared)) {
                #if DEBUG
                PulseChallengeStore.shared.seedDemoIfRequested(today: Repository.localDayKey(Date()))
                #endif
                challenges = await PulseChallengeFeed.running(model)
            }
            // Scanned again on every refresh (a sync brings new heart rate), and when the setting is switched.
            .task(id: "\(model.healthKey)|\(autoDetect)") {
                await loadDetected()
            }
    }

    private func loadDetected() async {
        guard autoDetect else {
            detected = nil
            return
        }
        if let found = await model.build(dayOffset: 0, { builder, request in
            await builder.homeDetectedWorkout(request)
        }) {
            detected = found.workout.flatMap { handled.contains($0.startSec) ? nil : $0 }
        }
    }

    /// SAVE: the window becomes a "Workout" saved as a hand-entered one is (`Repository.saveDetectedWorkout`),
    /// then the store is re-read, so Today's Activities shows it and the detector no longer suggests it.
    private func save(_ workout: DetectedWorkout) {
        handled.insert(workout.startSec)
        detected = nil
        let repo = app.repo
        Task {
            _ = await repo.saveDetectedWorkout(workout)
            await repo.refresh()
        }
    }

    /// DISMISS: the window is recorded so it is never suggested again (`Repository.dismissDetectedSuggestion`).
    private func dismiss(_ workout: DetectedWorkout) {
        handled.insert(workout.startSec)
        detected = nil
        app.repo.dismissDetectedSuggestion(workout)
    }
}

private struct PulseCoachingStackContent: View, Equatable {
    let base: HomeCoachingRules.Inputs
    let home: HomeSnapshot
    let grades: PulseMonitorGrades?
    let stress: PulseStressSummary?
    let stressUpdated: String?
    /// The illness heads-up's copy while it is raised.
    let illness: String?
    /// Today's achievements, day-streak milestone and level-up (§3.30).
    let milestones: [PulseHomeMilestones.Card]
    /// The challenges running today (§3.41).
    let challenges: [ChallengeSnapshot]
    /// The auto-detected workout to save or dismiss, while Settings' Auto-detect workouts is on (§3.14 [Z]).
    let detected: DetectedWorkout?
    let onSaveWorkout: (DetectedWorkout) -> Void
    let onDismissWorkout: (DetectedWorkout) -> Void

    @Environment(\.pulseNavigator) private var navigator
    /// Cards completed with ✓, as "yyyy-MM-dd:id" (only today's are kept).
    @AppStorage("pulse.home.coaching.done") private var completed = ""
    /// The release whose notes the What's New card already showed.
    @AppStorage("pulse.home.whatsNewSeen") private var whatsNewSeen = ""
    /// The release the app's own What's New sheet last showed (it pops by itself after an update), so the
    /// card only stands in when that sheet has not been seen.
    @AppStorage("noop.lastSeenChangelogVersion") private var lastSeenChangelog = ""

    static func == (lhs: PulseCoachingStackContent, rhs: PulseCoachingStackContent) -> Bool {
        lhs.base == rhs.base && lhs.home == rhs.home && lhs.grades == rhs.grades && lhs.stress == rhs.stress
            && lhs.stressUpdated == rhs.stressUpdated && lhs.illness == rhs.illness
            && lhs.milestones == rhs.milestones && lhs.challenges == rhs.challenges && lhs.detected == rhs.detected
    }

    var body: some View {
        let cards = models
        VStack(alignment: .leading, spacing: 0) {
            if !cards.isEmpty {
                PulseCoachingStack(cards: cards, onComplete: complete, onOpen: open, onDecide: decide)
                    .padding(.top, PulseHomeSpacing.stackTop)
                    .id("pulse.coaching")
            }
            PulseMonitorTiles(grades: grades, stress: stress, stressUpdated: stressUpdated)
                .padding(.top, cards.isEmpty ? PulseHomeSpacing.tilesTop : PulseHomeSpacing.tilesAfterStack)
                .id("pulse.monitors")
        }
        .pulseAnimation(PulseMotion.chrome, value: cards.map(\.id))
    }

    /// The heads-ups that cannot wait (the illness heads-up, an alarm still to come), the auto-detected
    /// workout to save or dismiss (it is about the last two days, so it goes stale), today's milestones, the
    /// rest of the rules' cards for the day, the running challenges, then the announcements (the week in
    /// review, release notes), less the ones completed today.
    private var models: [PulseCoachingCardModel] {
        var inputs = base
        inputs.illness = illness != nil
        inputs.alarm = alarmNow
        let release = AppChangelog.currentVersion
        inputs.whatsNew = !release.isEmpty && whatsNewSeen != release && lastSeenChangelog != release
        let rules = HomeCoachingRules.cards(inputs)
        let urgent = rules.filter(Self.isUrgent).map(model)
        let rest = rules.filter { !Self.isUrgent($0) }.map(model)
        let day = rest.filter { $0.style != .feature }
        let announcements = rest.filter { $0.style == .feature }
        let done = completedToday
        let workout = detected.map { [model($0)] } ?? []
        let cards = (urgent + workout + milestones.map(model) + day + challenges.map(model) + announcements)
            .filter { !done.contains($0.id) }
        #if DEBUG
        if let top = PulseHomeDebug.coachingTop {
            return cards.filter { $0.id.hasPrefix(top) } + cards.filter { !$0.id.hasPrefix(top) }
        }
        #endif
        return cards
    }

    private static func isUrgent(_ card: HomeCoachingRules.Card) -> Bool {
        switch card {
        case .illness, .alarmWhileAwake: return true
        default: return false
        }
    }

    /// This morning's alarm as the builder resolved it (the strap's own arming resolver), checked against
    /// the current minute, so the card leaves once the alarm's time has come.
    private var alarmNow: HomeCoachingRules.AlarmCheck? {
        guard let alarm = base.alarm else { return nil }
        let n = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return HomeCoachingRules.AlarmCheck(alarmMinute: alarm.alarmMinute, wokeMinute: alarm.wokeMinute,
                                            nowMinute: (n.hour ?? 0) * 60 + (n.minute ?? 0))
    }

    private var completedToday: Set<String> {
        let prefix = base.dayKey + ":"
        return Set(completed.split(separator: ",").map(String.init).filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) })
    }

    private func complete(_ card: PulseCoachingCardModel) {
        if card.id == "whats-new" { whatsNewSeen = AppChangelog.currentVersion }
        let prefix = base.dayKey + ":"
        var kept = completed.split(separator: ",").map(String.init).filter { $0.hasPrefix(prefix) }
        kept.append(prefix + card.id)
        completed = kept.joined(separator: ",")
    }

    private func open(_ card: PulseCoachingCardModel) {
        if card.id == "whats-new" { whatsNewSeen = AppChangelog.currentVersion }
        if let route = card.route { navigator.open(route) }
    }

    /// SAVE or DISMISS on the auto-detected workout's card.
    private func decide(_ card: PulseCoachingCardModel, accepted: Bool) {
        guard let workout = detected, card.id == Self.detectedID(workout) else { return }
        if accepted {
            onSaveWorkout(workout)
        } else {
            onDismissWorkout(workout)
        }
    }

    // MARK: Copy

    private func model(_ card: HomeCoachingRules.Card) -> PulseCoachingCardModel {
        let trend = PulseRoute.trendView(metric: "recovery").forExistingEntryPoint
        let planner = PulseRoute.sleepPlanner.forExistingEntryPoint
        func one(_ v: Double) -> String { PulseFormat.oneDecimal(v) }
        switch card {
        case .illness:
            return .init(id: card.id, title: String(localized: "Your Body Looks Strained"),
                         body: illness ?? "", cta: String(localized: "Open Health Monitor"),
                         symbol: "waveform.path.ecg.rectangle", route: PulseRoute.healthMonitor.forExistingEntryPoint)
        case .alarmWhileAwake(let minute):
            return .init(id: card.id, title: String(localized: "Turn Off Your Alarm?"),
                         body: String(localized: "You have an alarm set for \(clock(minute)) this morning, but it looks like you're already awake."),
                         cta: String(localized: "Review alarm"), symbol: "alarm", route: planner)
        case .calibrating(let nights, let of):
            return .init(id: card.id, title: String(localized: "Calibrating"),
                         body: String(localized: "Recovery scores once your strap has learned \(of) nights of your sleep. \(nights) of \(of) so far: wear it to bed tonight."),
                         cta: String(localized: "View calibration timeline"), symbol: "calendar.badge.clock",
                         route: PulseRoute.calibrationTimeline.forExistingEntryPoint)
        case .lowestInAWhile(let recovery, let since, let inWindow):
            let body: String
            if !inWindow {
                body = String(localized: "Your Recovery is down to \(recovery)% today. Go easy and give your body room to recharge.")
            } else if let since {
                body = String(localized: "At \(recovery)%, this is your lowest Recovery since \(PulseFormat.dayLabel(since)). Today might not feel great, but rest now helps it rebound.")
            } else {
                body = String(localized: "At \(recovery)%, this is the lowest Recovery you've recorded. Today might not feel great, but rest now helps it rebound.")
            }
            return .init(id: card.id, title: String(localized: "Lowest in a While"), body: body,
                         cta: String(localized: "View trend"), symbol: "chart.line.downtrend.xyaxis", route: trend)
        case .newlyRed(let recovery, let previous):
            // The rule fires only against yesterday's score, so "the day before" is literal.
            return .init(id: card.id, title: String(localized: "Newly Red"),
                         body: String(localized: "Your Recovery dropped to \(recovery)% after \(previous)% the day before. A lighter day helps it bounce back."),
                         cta: String(localized: "View trend"), symbol: "arrow.down.heart", route: trend)
        case .nearPerfect(let recovery):
            return .init(id: card.id, title: String(localized: "Near-Perfect Recovery"),
                         body: String(localized: "A \(recovery)% Recovery means your body is recharged. Lean in and make the most of your energy today."),
                         symbol: "sparkles", route: .recoveryDive)
        case .lowHRV(let hrv, let baseline):
            // The Recovery engine's baseline, named as such: the HRV dashboard row's baseline is the 30-day
            // mean, a different figure.
            return .init(id: card.id, title: String(localized: "Low HRV"),
                         body: String(localized: "Your HRV was \(hrv) ms last night, well under your Recovery baseline of \(baseline) ms. Consider keeping today's Strain light."),
                         symbol: "waveform.path.ecg", route: .recoveryDive)
        case .roughSleepStreak(let nights):
            return .init(id: card.id, title: String(localized: "Rough Sleep Streak"),
                         body: String(localized: "Your Sleep Performance has been under 70% for \(nights) nights in a row. Try to give yourself extra time in bed tonight."),
                         cta: String(localized: "Plan tonight"), symbol: "moon.zzz", route: planner)
        case .pushingLimits(_, let high):
            return .init(id: card.id, title: String(localized: "Pushing Limits"),
                         body: String(localized: "You worked hard today and went past the top of your optimal Strain range (\(one(high))). Make recovery the priority tonight."),
                         symbol: "flame", route: .strainDive)
        case .strainTargetReached(let target):
            return .init(id: card.id, title: String(localized: "Strain Target Reached"),
                         body: String(localized: "You reached today's Strain target of \(one(target)). Anything more takes you toward the top of your optimal range."),
                         symbol: "target", route: .strainDive)
        case .buildingFitness(let target):
            return .init(id: card.id, title: String(localized: "Building Fitness Gains"),
                         body: String(localized: "You're building fitness by entering your optimal Strain range. Keep pushing toward your target of \(one(target)) to see greater results."),
                         symbol: "figure.run", route: .strainDive)
        case .optimalHealth(let target):
            return .init(id: card.id, title: String(localized: "Optimal Health"),
                         body: String(localized: "Take advantage of your green Recovery by meeting your Strain target of \(one(target)). Your body is signaling it can take on significant exertion today."),
                         symbol: "bolt.heart", route: .strainDive)
        case .recoveringFromStrain(let high):
            return .init(id: card.id, title: String(localized: "Recovering from Strain"),
                         body: String(localized: "Your Recovery is in the red. Keeping today's Strain under \(one(high)) gives your body room to catch up."),
                         symbol: "bed.double", route: .strainDive)
        case .sleepDebtRising(let minutes):
            return .init(id: card.id, title: String(localized: "Sleep Debt Rising"),
                         body: String(localized: "You're carrying \(PulseFormat.hoursMinutes(Double(minutes))) of sleep debt into tonight. An earlier bedtime helps pay it back."),
                         cta: String(localized: "Plan tonight"), symbol: "moon.stars", route: planner)
        case .weekInReview:
            return .init(id: card.id, title: String(localized: "Your Week in Review"),
                         body: String(localized: "See how last week's Recovery, Strain and Sleep added up."),
                         cta: String(localized: "View week"), symbol: "calendar", style: .feature,
                         route: PulseWeeklyDigestRoute(page: 1).route)
        case .whatsNew:
            return .init(id: card.id, title: String(localized: "What's New in ZENO"),
                         body: String(localized: "See what changed in this version of ZENO."),
                         cta: String(localized: "Learn more"), symbol: "sparkles.rectangle.stack", style: .feature,
                         route: .classic(.whatsNew))
        }
    }

    /// A milestone in the unlock modal's own words (`PulseUnlockModal`): the badge's name and rule, the
    /// streak's milestone, and the level with the Levels page's own count to the next.
    private func model(_ milestone: PulseHomeMilestones.Card) -> PulseCoachingCardModel {
        switch milestone {
        case .streak(let days):
            let run = String(AttributedString(localized: "^[\(days) day](inflect: true)").characters)
            return .init(id: milestone.id, title: String(localized: "New Day Streak Unlocked"),
                         body: String(localized: "Your day streak reached \(run), a scored Recovery every day. Keep wearing your strap day and night."),
                         cta: String(localized: "View streak"), symbol: "flame", route: .dayStreak)
        case .badge(let badge):
            let info = ProfileBadgeInfo(badge)
            let body: String
            switch badge.kind {
            case .cumulative:
                body = String(localized: "\(info.criterion): \(PulseFormat.grouped(Double(badge.count))) so far.")
            case .event:
                body = badge.shown == 1 ? String(localized: "\(info.criterion), for the first time.")
                                        : String(localized: "\(info.criterion): \(badge.shown) times so far.")
            case .value:
                body = String(localized: "Your ZENO Age is now \(badge.shown) years younger than your age.")
            }
            return .init(id: milestone.id, title: String(localized: "Achievement Unlocked: \(info.name)"),
                         body: body, cta: String(localized: "View achievement"), symbol: info.symbol,
                         route: PulseAchievementDetailsRoute(badgeID: badge.id).route)
        case .level(let progress):
            let level = progress.level
            let count = ProfileFormat.recoveries(progress.recoveries)
            let body: String
            if let next = progress.nextLevel, let remaining = progress.remaining {
                body = remaining == 1
                    ? String(localized: "You reached Level \(level) with \(count). 1 more Recovery to Level \(next).")
                    : String(localized: "You reached Level \(level) with \(count). \(remaining) more Recoveries to Level \(next).")
            } else {
                body = String(localized: "You reached Level \(level) with \(count), the highest level.")
            }
            return .init(id: milestone.id, title: String(localized: "Level Up"), body: body,
                         cta: String(localized: "View levels"), symbol: "medal", route: .levels)
        }
    }

    /// A running challenge in its page's own words (`PulseChallengeText`): its name and the page's
    /// headline, the page's sentence on where it stands, and the page itself behind it.
    private func model(_ challenge: ChallengeSnapshot) -> PulseCoachingCardModel {
        .init(id: "challenge-\(challenge.id)",
              title: String(localized: "\(PulseChallengeText.navTitle(challenge.definition)): \(PulseChallengeText.headline(challenge))"),
              body: PulseChallengeText.detail(challenge), cta: String(localized: "View challenge"),
              symbol: challenge.definition.kind.symbol, route: PulseChallengeDetailRoute(id: challenge.id).route)
    }

    /// The card's id: the window, so ✓ hides this suggestion for the day and a different one still shows.
    private static func detectedID(_ workout: DetectedWorkout) -> String {
        "auto-workout-\(workout.startSec)-\(workout.endSec)"
    }

    /// The auto-detected workout (§3.14 [Z]) in the classic Today card's terms: the window, its average heart
    /// rate and length, today, yesterday or dated, with SAVE and DISMISS instead of a CTA.
    private func model(_ workout: DetectedWorkout) -> PulseCoachingCardModel {
        let start = Date(timeIntervalSince1970: TimeInterval(workout.startSec))
        let from = PulseFormat.clock(start)
        let to = PulseFormat.clock(Date(timeIntervalSince1970: TimeInterval(workout.endSec)))
        let length = PulseFormat.duration(minutes: Double(workout.durationMin))
        let cal = Calendar.current
        let body: String
        if cal.isDateInToday(start) {
            body = String(localized: "Your heart rate stayed up from \(from) to \(to), \(length) at an average of \(workout.avgBpm) bpm. Save it as a workout?")
        } else if cal.isDateInYesterday(start) {
            body = String(localized: "Your heart rate stayed up yesterday from \(from) to \(to), \(length) at an average of \(workout.avgBpm) bpm. Save it as a workout?")
        } else {
            let day = start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()
                .locale(AppLanguage.activeLocale))
            body = String(localized: "Your heart rate stayed up on \(day) from \(from) to \(to), \(length) at an average of \(workout.avgBpm) bpm. Save it as a workout?")
        }
        return .init(id: Self.detectedID(workout), title: String(localized: "Workout Detected"), body: body,
                     symbol: "figure.run", route: nil,
                     decision: .init(accept: String(localized: "Save"), decline: String(localized: "Dismiss")))
    }

    /// A minutes-after-midnight time in the device's clock format.
    private func clock(_ minute: Int) -> String {
        let start = Calendar.current.startOfDay(for: Date())
        return PulseFormat.clock(start.addingTimeInterval(TimeInterval(minute * 60)))
    }
}
#endif
