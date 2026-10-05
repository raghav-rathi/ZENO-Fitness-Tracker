import SwiftUI
import StrandDesign

// MARK: - Scoring guide
//
// "How your scores work" — the one honest explainer for NOOP's three daily scores
// (Charge, Effort, Rest) and the confidence labels. Presented as a sheet, mirroring
// WhatsNewView's presentation + dismiss + layout idiom: a fixed header with a close
// button, a scrollable column of cards, and a "Got it" footer. Reachable from
// Settings → About, the ⓘ on each Today score, and the one-time first-run card.
//
// All copy here is the single approved source of truth, shared verbatim across
// macOS / iOS / Android. Each score section is tinted with the SAME Reset accent the
// rest of the app uses for that score's hero ring (Charge = green, Effort = blue
// accent, Rest = restColor slate), so a glance maps a section to its Today ring.
//
// The iPhone's Pulse interface opens this guide as "How ZENO works" and from the dives'
// HOW IT'S CALCULATED, so it carries a second form of its copy (`ScoreVocabulary.pulse`):
// Recovery, Strain on WHOOP's 0-21 scale and Sleep, explained in WHOOP's terms as ZENO's
// own on-device estimates (spec §0.3). It is a rewrite, not a word swap: the classic text
// explains NOOP's 0-100 model and how it differs from WHOOP, which the Pulse path no longer
// shows. The classic copy is untouched, so the Mac and the classic iPhone shell read as before.

/// The three score sections the guide can deep-link to. The raw value is used as the
/// ScrollViewReader anchor id. The Android port mirrors these case names exactly.
enum ScoreSection: String, CaseIterable, Identifiable {
    case charge
    case effort
    case rest

    var id: String { rawValue }

    /// The accent each section uses — the SAME Reset score token its Today hero ring draws with, so a
    /// section reads as that score's colour. No gold / strain / sleep-purple: Charge = chargeColor green,
    /// Effort = effortColor blue accent, Rest = restColor slate (Design Reset, 2026-06-23).
    var accent: Color {
        switch self {
        case .charge: return StrandPalette.chargeColor     // Charge hero ring — green
        case .effort: return StrandPalette.effortColor     // Effort hero ring — blue accent
        case .rest:   return StrandPalette.restColor       // Rest hero ring — slate
        }
    }

    /// A representative sample fraction (0–1) for the section's illustrative gauge — a
    /// "what a strong day looks like" reading, purely decorative in the guide.
    var sampleFraction: Double {
        switch self {
        case .charge: return 0.82
        case .effort: return 0.64
        case .rest:   return 0.88
        }
    }

    /// The number shown inside the sample gauge (the 0–100 score the fraction maps to).
    var sampleNumber: String {
        "\(Int((sampleFraction * 100).rounded()))"
    }

    /// The sample gauge's read-out for a 0-100 `value` in `vocabulary`: the bare 0-100 number in the
    /// classic guide; under Pulse, Recovery and Sleep as percentages and Strain on WHOOP's 0-21 axis,
    /// through the same resolver and formatter every Strain read-out uses.
    func sampleText(_ value: Double, vocabulary: ScoreVocabulary) -> String {
        guard vocabulary == .pulse else { return "\(Int(value.rounded()))" }
        switch self {
        case .effort:
            return UnitFormatter.effortDisplay(value, scale: UnitPrefs.resolveEffortScale("", vocabulary: vocabulary))
        case .charge, .rest:
            return "\(Int(value.rounded()))%"
        }
    }

    /// The SF Symbol for the section header (heart/spark · flame · moon).
    var icon: String {
        switch self {
        case .charge: return "heart.circle.fill"
        case .effort: return "flame.fill"
        case .rest:   return "moon.stars.fill"
        }
    }

    /// Localized display name for the section (the raw value stays the stable anchor id), in the
    /// vocabulary of the interface the app runs.
    var displayName: String { displayName(.current) }

    /// The section's name in `vocabulary`: Charge / Effort / Rest, or Recovery / Strain / Sleep under Pulse.
    func displayName(_ vocabulary: ScoreVocabulary) -> String {
        switch self {
        case .charge: return vocabulary.pick(classic: String(localized: "Charge"), pulse: String(localized: "Recovery"))
        case .effort: return vocabulary.pick(classic: String(localized: "Effort"), pulse: String(localized: "Strain"))
        case .rest:   return vocabulary.pick(classic: String(localized: "Rest"), pulse: String(localized: "Sleep"))
        }
    }
}

struct ScoringGuideView: View {
    /// When set, the guide scrolls to (and briefly highlights) this section on appear —
    /// used by the ⓘ affordances on the Today screen so each opens at its own score.
    var initialSection: ScoreSection? = nil
    let onClose: () -> Void

    /// Drives the brief highlight pulse on the deep-linked section.
    @State private var highlighted: ScoreSection? = nil

    /// The interface's vocabulary, read at render: the classic guide, or its Pulse form (see the header).
    private var vocabulary: ScoreVocabulary { .current }

    var body: some View {
        VStack(spacing: 0) {
            header
                // Design Reset: a FLAT opaque WHOOP-grey title surface — no scenic hero, no bloom, no
                // domain tint. The header reads as a clean raised card edge, matching the Today look.
                .background(NoopChromeSurface())
            Divider().overlay(StrandPalette.hairline)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                        introCard
                        scoreCard(.charge,
                                  headline: vocabulary.pick(
                                    classic: String(localized: "Charge: how recovered are you?"),
                                    pulse: String(localized: "Recovery: how ready is your body today?")),
                                  body: vocabulary.pick(
                                    classic: String(localized: "Led by your heart-rate variability (HRV) measured against your own personal baseline, plus resting heart rate, last night's Rest, breathing rate, and a skin-temperature signal (an early illness or overreach flag). Higher HRV versus your baseline means more Charge. NOOP needs a few nights to learn your baseline first. Until then you'll see “Calibrating”."),
                                    pulse: String(localized: "A daily percentage of how prepared your body is to take on Strain. It is led by your heart-rate variability (HRV) measured against your own baseline, plus resting heart rate, respiratory rate, last night's sleep and a skin-temperature signal (an early illness or overreach flag). HRV above your baseline lifts Recovery. Green is 67% and up, yellow 34 to 66%, red 33% and below. ZENO needs a few nights to learn your baseline first. Until then you'll see “Calibrating”.")),
                                  vsWhoop: vocabulary.pick(
                                    classic: String(localized: "Same core idea as WHOOP's Recovery % (HRV-led recovery), but our weighting and baseline maths are our own, and openly documented."),
                                    pulse: String(localized: "WHOOP's Recovery reads the same kinds of signals, but its weighting is private. ZENO's weighting and baseline maths are its own and openly documented, so the two should agree in direction, not to the percent.")))
                        scoreCard(.effort,
                                  headline: vocabulary.pick(
                                    classic: String(localized: "Effort: how hard did your heart work?"),
                                    pulse: String(localized: "Strain: how much load did your heart take on?")),
                                  body: vocabulary.pick(
                                    classic: String(localized: "Your cardiovascular load. NOOP turns every second of heart rate into a training-impulse using heart-rate-reserve zones (Karvonen), weights time in harder zones more heavily (Edwards by default, or Banister if you choose it in Settings), and places it on a logarithmic 0-100 scale, so easy days sit low and an all-out day approaches 100, which stays genuinely rare. Under the default, time below half your heart-rate reserve adds nothing, so a gentle walk scores little; Banister also credits lighter work."),
                                    pulse: String(localized: "Your cardiovascular load for the day, on WHOOP's 0-21 scale. ZENO turns every second of heart rate into a training impulse using heart-rate-reserve zones (Karvonen), weights time in harder zones more heavily (Edwards by default, or Banister if you choose it in Settings), and places the total on a logarithmic scale, so easy days sit low and an all-out day approaches 21, which stays genuinely rare. Under the default, time below half your heart-rate reserve adds nothing, so a gentle walk scores little; Banister also credits lighter work.")),
                                  vsWhoop: vocabulary.pick(
                                    classic: String(localized: "Same cardiovascular-load idea as WHOOP's Day Strain (0-21). We rescaled the top of the ladder from 21 to 100 so all three scores share one scale. The rungs didn't move, so a 100 is as rare as a 21.0 was."),
                                    pulse: String(localized: "The same cardiovascular-load idea and the same 0-21 scale as WHOOP's Day Strain. ZENO works the load out itself from your heart rate, so its Strain sits close to WHOOP's, not on top of it.")))
                        scoreCard(.rest,
                                  headline: vocabulary.pick(
                                    classic: String(localized: "Rest: how restorative was your sleep?"),
                                    pulse: String(localized: "Sleep: did you get the sleep you needed?")),
                                  body: vocabulary.pick(
                                    classic: String(localized: "A blend of how long you slept versus your sleep need (the biggest factor: your personal baseline, plus extra after a hard day or while you carry sleep debt, less any naps), how efficiently (asleep versus in bed), how much was restorative (deep + REM sleep), and how consistent your sleep and wake timing is (last night's bed and wake times against the four nights before)."),
                                    pulse: String(localized: "Your Sleep Performance, as a percentage. The biggest factor is how long you slept against how much you needed: your personal baseline, plus extra after a high-Strain day or while you carry sleep debt, less any naps. It also counts how efficiently you slept (asleep versus in bed), how much was restorative (deep + REM sleep), and how consistent your sleep and wake timing is (last night's bed and wake times against the four nights before).")),
                                  vsWhoop: vocabulary.pick(
                                    classic: String(localized: "Similar in spirit to WHOOP's Sleep Performance %; our composite is our own."),
                                    pulse: String(localized: "WHOOP's Sleep Performance centres on the hours you slept against the hours you needed. ZENO's starts from that same comparison and folds in efficiency, restorative sleep and consistency, so it is its own number.")))
                        confidenceCard
                        footerNote
                    }
                    .padding(20)
                }
                #if os(iOS)
                // #697/#horizontal-swipe parity, see ScreenScaffold.
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                #endif
                .onAppear { jump(to: initialSection, using: proxy) }
            }
            Divider().overlay(StrandPalette.hairline)
            footerBar
        }
        // Same sizing split as WhatsNewView: a fixed window on macOS, fill the presented
        // sheet on iOS so nothing runs off a narrow phone screen (#185).
        #if os(macOS)
        .frame(width: 560, height: 640)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // A long explainer scroll → open full-height, with a grabber for swipe-to-dismiss.
        .noopSheetPresentation(largeFirst: true)
        #endif
        .background(StrandPalette.surfaceBase)
    }

    // MARK: - Header / footer

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR DAILY SCORES").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textTertiary)
                Text("How your scores work").font(StrandFont.rounded(26, weight: .bold))
                    .foregroundStyle(StrandPalette.textPrimary)
                Text(vocabulary.pick(classic: LocalizedStringKey("Charge · Effort · Rest"),
                                     pulse: LocalizedStringKey("Recovery · Strain · Sleep")))
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(20)
    }

    private var footerBar: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Text("Got it").frame(minWidth: 120).padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(StrandPalette.accent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    // MARK: - Cards

    private var introCard: some View {
        NoopCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("THE THREE SCORES").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textSecondary)
                Text(vocabulary.pick(
                    classic: LocalizedStringKey("NOOP gives you three daily scores (Charge, Effort and Rest), each on a 0-100 scale. They're built from your strap's raw signals using published, peer-reviewed sport science, and computed entirely on your device. They are NOT WHOOP's scores: we don't have WHOOP's private algorithms and don't pretend to. They aim at the same three questions using open science, so they'll usually track WHOOP's in direction, but won't match number-for-number. And that's the point."),
                    pulse: LocalizedStringKey("ZENO gives you three daily scores the way WHOOP does: Recovery (a percentage), Strain (0-21) and Sleep (your Sleep Performance, a percentage). It works all three out itself, on your phone, from your strap's raw signals, using published, peer-reviewed sport science. They are ZENO's own estimates, not WHOOP's numbers: WHOOP's algorithms are private, so ZENO answers the same three questions with open methods. Expect them to move the way WHOOP's would, not to match them number for number.")))
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                // The three accents as a quick legend, echoing the section colours below.
                HStack(spacing: 16) {
                    legendDot(.charge, ScoreSection.charge.displayName(vocabulary))
                    legendDot(.effort, ScoreSection.effort.displayName(vocabulary))
                    legendDot(.rest, ScoreSection.rest.displayName(vocabulary))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func legendDot(_ section: ScoreSection, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(section.accent).frame(width: 8, height: 8)
            Text(label).font(StrandFont.caption).foregroundStyle(StrandPalette.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    /// One colour-accented score section: a FLAT WHOOP-grey card (faintly washed with the section's Reset
    /// accent) carrying a clean sample ring of that score beside an accent-tinted headline, the body, and
    /// an italic "vs WHOOP" line set off by a hairline rule. The ring is illustrative — a "what a strong
    /// day reads like" preview in the section's own colour — so a glance maps a card to its Today ring.
    /// Design Reset: a flat GlowRing (no bloom) replaces the old BevelGauge; the accent is a Reset score
    /// token, never gold / strain / sleep-purple.
    private func scoreCard(_ section: ScoreSection, headline: String, body: String, vsWhoop: String) -> some View {
        NoopCard(tint: section.accent) {
            VStack(alignment: .leading, spacing: 14) {
                // Header row — the flat sample ring sits beside the accent icon + headline.
                HStack(alignment: .center, spacing: 14) {
                    sampleRing(section)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: section.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(section.accent)
                                .accessibilityHidden(true)
                            Text(section.displayName(vocabulary))
                                .font(StrandFont.overline)
                                .tracking(StrandFont.overlineTracking)
                                .textCase(.uppercase)
                                .foregroundStyle(section.accent)
                        }
                        Text(headline).font(StrandFont.headline)
                            .foregroundStyle(StrandPalette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                Text(body)
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Divider().overlay(StrandPalette.hairline)
                HStack(alignment: .top, spacing: 8) {
                    Text("vs WHOOP").font(StrandFont.overline)
                        .tracking(StrandFont.overlineTracking)
                        .textCase(.uppercase)
                        .foregroundStyle(section.accent)
                        .padding(.top, 1)
                    Text(vsWhoop)
                        .font(StrandFont.footnote)
                        .italic()
                        .foregroundStyle(StrandPalette.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Deep-link highlight: a brief accent-tinted ring when arrived at via an ⓘ.
        .overlay(
            RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous)
                .strokeBorder(section.accent, lineWidth: 2)
                .opacity(highlighted == section ? 1 : 0)
        )
        .animation(.easeOut(duration: 0.35), value: highlighted)
        .id(section.id)
    }

    /// The flat illustrative ring for a score section — a clean GlowRing (Design Reset: solid crisp arc,
    /// NO bloom) in the section's Reset accent, with the score name as a small caption below, matching the
    /// Today hero rings. Decorative ("what a strong day looks like"), so it's hidden from VoiceOver by the
    /// caller. Replaces the old per-section BevelGauge(bloomActive: true).
    private func sampleRing(_ section: ScoreSection) -> some View {
        VStack(spacing: 5) {
            GlowRing(
                fraction: section.sampleFraction,
                value: section.sampleFraction * 100,
                // The classic guide's bare 0-100 number; under Pulse a percentage, or Strain on 0-21.
                format: { [vocabulary] in section.sampleText($0, vocabulary: vocabulary) },
                color: section.accent,
                diameter: 76,
                lineWidth: 8
            )
            Text(section.displayName(vocabulary))
                .font(StrandFont.overline)
                .tracking(StrandFont.overlineTracking)
                .textCase(.uppercase)
                .foregroundStyle(StrandPalette.textTertiary)
        }
    }

    private var confidenceCard: some View {
        NoopCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(vocabulary.pick(classic: LocalizedStringKey("How sure is NOOP?  ·  Solid · Building · Calibrating"),
                                     pulse: LocalizedStringKey("How sure is ZENO?  ·  Solid · Building · Calibrating")))
                    .font(StrandFont.headline)
                    .foregroundStyle(StrandPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                // The three labels as the same pills used elsewhere, in their honest order.
                HStack(spacing: 8) {
                    StatePill("Solid", tone: .positive, showsDot: true)
                    StatePill("Building", tone: .warning, showsDot: true)
                    StatePill("Calibrating", tone: .neutral, showsDot: true)
                }
                Text(vocabulary.pick(
                    classic: LocalizedStringKey("Every score carries a small honesty label. Calibrating means NOOP is still learning your baseline, or doesn't have enough data yet. Building means there's enough to show, but it's thin. Solid means full inputs are present. When NOOP can't compute a score honestly, it shows nothing rather than a fake number."),
                    pulse: LocalizedStringKey("Every score carries a small honesty label. Calibrating means ZENO is still learning your baseline, or doesn't have enough data yet. Building means there's enough to show, but it's thin. Solid means full inputs are present. When ZENO can't compute a score honestly, it shows nothing rather than a fake number.")))
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrandPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footerNote: some View {
        Text("These are independent approximations from a consumer strap, built on open science: not medical advice, and not WHOOP's official scores.")
            .font(StrandFont.footnote)
            .foregroundStyle(StrandPalette.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    // MARK: - Deep-link

    /// Scroll to the requested section and pulse its highlight, then fade it.
    private func jump(to section: ScoreSection?, using proxy: ScrollViewProxy) {
        guard let section else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(section.id, anchor: .top)
            }
            highlighted = section
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                if highlighted == section { highlighted = nil }
            }
        }
    }
}

#if DEBUG
#Preview("Scoring guide") {
    ScoringGuideView(initialSection: .effort, onClose: {})
        .preferredColorScheme(.dark)
}
#endif
