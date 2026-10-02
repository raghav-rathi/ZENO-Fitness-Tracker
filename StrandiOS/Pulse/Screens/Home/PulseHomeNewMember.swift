#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - New-member Home (WHOOP_UI_SPEC §3.1 items 10, 11; §2.9 "New member")
//
// Before the first Recovery, "Get Started" takes My Day's place (it keeps the "+"), followed by ZENO's
// Get Started cards [Z], the "Ask a question" well while Coach can answer, and Tonight's Sleep. Looking
// Ahead's CALIBRATION TIMELINE counts the nights until Recovery scores (n/4), then the scored days until
// the weekly features do (n/7).

/// One Get Started card's content (ZENO's set, copy rewritten for ZENO).
struct PulseGetStartedCardModel: Identifiable, Equatable {
    let id: String
    let title: String
    let body: String
    let cta: String
    let symbol: String
    let action: Action

    enum Action: Equatable {
        case route(PulseRoute)
        /// A ＋ action (Start Activity), so it opens exactly as the menu's row does.
        case quickAction(PulseQuickAction)
    }
}

/// The Get Started cards still to do: a card leaves once its step is done or the wearer dismisses it.
struct PulseGetStartedCards: View {
    let facts: PulseGetStartedFacts

    @Environment(\.pulseNavigator) private var navigator
    /// Dismissed cards' ids, comma-separated.
    @AppStorage("pulse.home.getStarted.dismissed") private var dismissed = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cards: [PulseGetStartedCardModel] {
        let gone = Set(dismissed.split(separator: ",").map(String.init))
        var all: [PulseGetStartedCardModel] = [
            .init(id: "charge", title: String(localized: "Learn How to Charge"),
                  body: String(localized: "Keep your strap charged so it can record your first day and night."),
                  cta: String(localized: "Check your strap"), symbol: "battery.100percent.bolt",
                  action: .route(PulseRoute.deviceSettings.forExistingEntryPoint)),
        ]
        if !facts.sleepScheduled {
            all.append(.init(id: "sleep", title: String(localized: "Set Up Your Sleep"),
                             body: String(localized: "Set your wake time so ZENO can help you wind down intentionally and wake up gently at the right time."),
                             cta: String(localized: "Create sleep schedule"), symbol: "alarm",
                             action: .route(PulseRoute.sleepPlanner.forExistingEntryPoint)))
        }
        if !facts.hasJournal {
            all.append(.init(id: "journal", title: String(localized: "Customize Your Journal"),
                             body: String(localized: "Track the habits you want to understand, and see how each one moves your Recovery."),
                             cta: String(localized: "Open journal"), symbol: "square.and.pencil",
                             action: .quickAction(.journal)))
        }
        if !facts.hasWorkout {
            all.append(.init(id: "move", title: String(localized: "Ready to get moving?"),
                             body: String(localized: "Start your first activity and come back to explore your heart rate zones and Strain."),
                             cta: String(localized: "Start activity"), symbol: "figure.run",
                             action: .quickAction(.workout)))
        }
        if !facts.hasHistoryImport {
            all.append(.init(id: "history", title: String(localized: "Bring Your History"),
                             body: String(localized: "Import a WHOOP export or Apple Health data so your trends start with your past, not today."),
                             cta: String(localized: "Import data"), symbol: "tray.and.arrow.down",
                             action: .route(.classic(.dataSources))))
        }
        return all.filter { !gone.contains($0.id) }
    }

    var body: some View {
        let shown = cards
        VStack(spacing: PulseTheme.Layout.stackGap) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, card in
                PulseGetStartedCard(card: card, isFirst: index == 0,
                                    onOpen: { open(card) }, onDismiss: { dismiss(card) })
                    .transition(.opacity)
            }
        }
        .animation(PulseMotion.resolved(PulseMotion.chrome, reduceMotion: reduceMotion), value: shown.map(\.id))
    }

    private func open(_ card: PulseGetStartedCardModel) {
        switch card.action {
        case .route(let route): navigator.open(route)
        case .quickAction(let action): navigator.quickAction(action)
        }
    }

    private func dismiss(_ card: PulseGetStartedCardModel) {
        var ids = dismissed.split(separator: ",").map(String.init)
        if !ids.contains(card.id) { ids.append(card.id) }
        dismissed = ids.joined(separator: ",")
    }
}

/// A Get Started card (onboarding/31a, §2.6 item 34): ≈140 pt, a 17 pt Semibold title, 14 pt body at
/// 70%, a magenta caps CTA with "→" and ZENO's art at the right. The first card carries the gradient
/// border on its tinted fill; the rest are plain #1D2124. Every card has a "✕" (WHOOP's cannot all be
/// dismissed; ZENO's can).
struct PulseGetStartedCard: View {
    let card: PulseGetStartedCardModel
    let isFirst: Bool
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .center, spacing: PulseTheme.Space.s) {
                VStack(alignment: .leading, spacing: PulseTheme.Space.xxs) {
                    Text(card.title)
                        .pulseText(.subsectionTitle)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(card.body)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(card.cta).pulseText(.label)
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(PulseTheme.Gradients.getStartedCTA)
                    .padding(.top, PulseTheme.Space.xs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: card.symbol)
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(width: 76)
                    .accessibilityHidden(true)
            }
            .padding(.leading, PulseTheme.Layout.cardPadding + 6)
            .padding(.trailing, PulseTheme.Layout.cardPadding + 18)
            .padding(.vertical, PulseTheme.Layout.cardPadding + 8)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .background(surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.title)
        .accessibilityValue(card.body)
        .accessibilityHint(card.cta)
        .accessibilityAddTraits(.isButton)
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Dismiss \(card.title)"))
        }
    }

    @ViewBuilder
    private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        if isFirst {
            shape.fill(LinearGradient(gradient: PulseTheme.Gradients.getStartedFill, startPoint: .topLeading,
                                      endPoint: .bottomTrailing))
                .overlay(shape.strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.getStartedBorder,
                                                           startPoint: .leading, endPoint: .trailing),
                                            lineWidth: 1.5))
        } else {
            shape.fill(PulseTheme.getStartedPlain)
        }
    }
}

/// The new member's "Ask a question, get support…" well (completeness-critic/24): pure black with a 1 pt
/// grey border, ZENO's ringed mark and the placeholder at 50%. Shown only while Coach can answer [Z].
struct PulseAskWell: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PulseTheme.Space.s) {
                PulseCoachAvatar(size: 24, ringWidth: 1.2, showsOrb: false)
                Text(String(localized: "Ask a question, get support…"))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, PulseTheme.Space.s)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.pill)
            .background {
                let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                shape.fill(PulseTheme.bannerWell).overlay(shape.strokeBorder(PulseTheme.outlinedBorder, lineWidth: 1))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens Coach"))
    }
}

/// Looking Ahead › CALIBRATION TIMELINE (help-center/61, 62): what to do while calibrating and a ring
/// counting it, "0/4" nights until Recovery scores, then "n/7" scored days.
struct PulseLookingAheadCard: View {
    let progress: PulseGetStartedFacts.Progress

    var body: some View {
        PulseLink(PulseRoute.calibrationTimeline.forExistingEntryPoint) {
            // The title row spans the card ("›" at its right edge); the ring sits under the "›".
            VStack(alignment: .leading, spacing: PulseTheme.Space.xs) {
                PulseCardTitle(String(localized: "Calibration Timeline"), accessory: .trailingChevron)
                HStack(alignment: .center, spacing: PulseTheme.Space.m) {
                    Text(progress.of == Baselines.minNightsSeed
                         ? String(localized: "Wear your strap to bed nightly and check back here: Recovery scores after \(progress.of) nights.")
                         : String(localized: "Wear your strap to bed nightly and check back here to track your sleeps and unlock new insights."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    PulseGoalRing(kind: .count(done: progress.done, target: progress.of), diameter: 54)
                }
            }
            .padding(PulseTheme.Layout.cardPadding + 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pulseCardBackground()
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(String(localized: "\(progress.done) of \(progress.of)"))
    }
}
#endif
