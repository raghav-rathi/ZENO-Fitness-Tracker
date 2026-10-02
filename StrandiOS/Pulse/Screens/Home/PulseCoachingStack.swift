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
// The cards come from `HomeCoachingRules` (StrandAnalytics), fed by the day's own data: no server feed, so
// there is no "Couldn't load" state.

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
}

/// The stack itself: draws `cards` (most important first) and reports the ✓ on the top card.
struct PulseCoachingStack: View {
    /// The stack is built and placed on Home.
    static let isRebuilt = true

    let cards: [PulseCoachingCardModel]
    let onComplete: (PulseCoachingCardModel) -> Void
    let onOpen: (PulseCoachingCardModel) -> Void

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

    private func card(_ model: PulseCoachingCardModel) -> some View {
        Button { onOpen(model) } label: {
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
                    if let cta = model.cta {
                        HStack(spacing: 6) {
                            Text(cta).pulseText(.label)
                            Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(ctaStyle(model))
                        .padding(.top, PulseTheme.Space.xs)
                        .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: model.symbol)
                    .font(.system(size: 46, weight: .ultraLight))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(width: 72)
                    .accessibilityHidden(true)
            }
            .padding(.leading, PulseTheme.Layout.cardPadding + 4)
            .padding(.trailing, PulseTheme.Layout.cardPadding + 34)
            .padding(.vertical, PulseTheme.Layout.cardPadding + 6)
            .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
            .background(surface(model))
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

    /// ✓ over the number of cards left: completes the top card for the day.
    private func counter(_ model: PulseCoachingCardModel) -> some View {
        Button { onComplete(model) } label: {
            // 24 × 46 pt, 8 pt in from the card's top-right corner (profile-community-2026/34).
            VStack(spacing: 7) {
                Image(systemName: "checkmark").font(.system(size: 15, weight: .semibold))
                Text(verbatim: "\(cards.count)")
                    .font(PulseType.numeral(14))
                    .foregroundStyle(PulseTheme.textTertiary)
            }
            .foregroundStyle(PulseTheme.textPrimary)
            .frame(width: 24, height: 46)
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
/// evaluates the rules from the day's inputs plus the app state they need (the illness heads-up, this
/// morning's strap alarm, unseen release notes), drops the cards completed today, and opens a card's
/// destination. Its own leaf because the illness flag lives on `AppModel`, which
/// publishes every heart-rate tick: the content below only redraws when its inputs change.
struct PulseCoachingStackHost: View {
    let base: HomeCoachingRules.Inputs
    let home: HomeSnapshot

    @EnvironmentObject private var app: AppModel

    var body: some View {
        PulseCoachingStackContent(base: base, home: home,
                                  illness: app.healthAlert.map { localizedHealthAlertCopy($0) })
            .equatable()
    }
}

private struct PulseCoachingStackContent: View, Equatable {
    let base: HomeCoachingRules.Inputs
    let home: HomeSnapshot
    /// The illness heads-up's copy while it is raised.
    let illness: String?

    @Environment(\.pulseNavigator) private var navigator
    /// Cards completed with ✓, as "yyyy-MM-dd:id" (only today's are kept).
    @AppStorage("pulse.home.coaching.done") private var completed = ""
    /// The release whose notes the What's New card already showed.
    @AppStorage("pulse.home.whatsNewSeen") private var whatsNewSeen = ""
    /// The release the app's own What's New sheet last showed (it pops by itself after an update), so the
    /// card only stands in when that sheet has not been seen.
    @AppStorage("noop.lastSeenChangelogVersion") private var lastSeenChangelog = ""
    // The strap alarm's own keys (BehaviorStore): this morning's alarm for the "already awake" card.
    @AppStorage("behavior.smartAlarmEnabled") private var alarmOn = false
    @AppStorage("behavior.smartAlarmMinutes") private var alarmMinutes = 7 * 60

    static func == (lhs: PulseCoachingStackContent, rhs: PulseCoachingStackContent) -> Bool {
        lhs.base == rhs.base && lhs.home == rhs.home && lhs.illness == rhs.illness
    }

    var body: some View {
        let cards = models
        VStack(alignment: .leading, spacing: 0) {
            if !cards.isEmpty {
                PulseCoachingStack(cards: cards, onComplete: complete, onOpen: open)
                    .padding(.top, PulseHomeSpacing.stackTop)
                    .id("pulse.coaching")
            }
            PulseMonitorTiles(home: home)
                .padding(.top, cards.isEmpty ? PulseHomeSpacing.tilesTop : PulseHomeSpacing.tilesAfterStack)
                .id("pulse.monitors")
        }
        .pulseAnimation(PulseMotion.chrome, value: cards.map(\.id))
    }

    // TODO(achievement-card): group "more-profile" adds "Achievement unlocked" / "Level up" (§3.30) once
    // achievements exist; feed them in here as cards like the rest (they are app state, not store data).
    // TODO(auto-workout-card): the opt-in auto-detected workout (Save / Dismiss, §3.14 [Z]) needs
    // `Repository.autoDetectCandidate()` split so its detection can run off the main actor first.
    private var models: [PulseCoachingCardModel] {
        var inputs = base
        inputs.illness = illness != nil
        inputs.alarm = alarmCheck
        let release = AppChangelog.currentVersion
        inputs.whatsNew = !release.isEmpty && whatsNewSeen != release && lastSeenChangelog != release
        let done = completedToday
        return HomeCoachingRules.cards(inputs)
            .filter { !done.contains($0.id) }
            .map(model)
    }

    /// This morning's alarm against when last night ended (exact-time alarms: the smart window is retired).
    private var alarmCheck: HomeCoachingRules.AlarmCheck? {
        guard alarmOn else { return nil }
        let now = Date()
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: now)
        // An empty weekday set means every day (BehaviorStore's default).
        let weekdays = UserDefaults.standard.array(forKey: "behavior.smartAlarmWeekdays") as? [Int] ?? []
        guard weekdays.isEmpty || weekdays.contains(weekday) else { return nil }
        let woke = home.lastNight.flatMap { night -> Int? in
            guard cal.isDate(night.wake, inSameDayAs: now) else { return nil }
            let c = cal.dateComponents([.hour, .minute], from: night.wake)
            return (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
        let n = cal.dateComponents([.hour, .minute], from: now)
        return HomeCoachingRules.AlarmCheck(alarmMinute: alarmMinutes, wokeMinute: woke,
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
            return .init(id: card.id, title: String(localized: "Newly Red"),
                         body: String(localized: "Your Recovery dropped to \(recovery)% after \(previous)% the day before. A lighter day helps it bounce back."),
                         cta: String(localized: "View trend"), symbol: "arrow.down.heart", route: trend)
        case .nearPerfect(let recovery):
            return .init(id: card.id, title: String(localized: "Near-Perfect Recovery"),
                         body: String(localized: "A \(recovery)% Recovery means your body is recharged. Lean in and make the most of your energy today."),
                         symbol: "sparkles", route: .recoveryDive)
        case .lowHRV(let hrv, let baseline):
            return .init(id: card.id, title: String(localized: "Low HRV"),
                         body: String(localized: "Your HRV was \(hrv) ms last night, well under your baseline of \(baseline) ms. Consider keeping today's Strain light."),
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
                         route: PulseRoute.weeklyDigest.forExistingEntryPoint)
        case .whatsNew:
            return .init(id: card.id, title: String(localized: "What's New in ZENO"),
                         body: String(localized: "See what changed in this version of ZENO."),
                         cta: String(localized: "Learn more"), symbol: "sparkles.rectangle.stack", style: .feature,
                         route: .classic(.whatsNew))
        }
    }

    /// A minutes-after-midnight time in the device's clock format.
    private func clock(_ minute: Int) -> String {
        let start = Calendar.current.startOfDay(for: Date())
        return PulseFormat.clock(start.addingTimeInterval(TimeInterval(minute * 60)))
    }
}
#endif
