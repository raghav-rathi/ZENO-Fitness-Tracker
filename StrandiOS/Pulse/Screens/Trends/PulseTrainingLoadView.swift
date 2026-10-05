#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Training Load (WHOOP_UI_SPEC §1.8, §3.35), pushed from Trends › INSIGHTS: fitness (CTL, the 42-day
/// load), fatigue (ATL, the 7-day load) and form (TSB, the gap between them), laid out like a Trend View:
/// the FORM headline with its range control, a sentence, the two lines and the latest figures.
///
/// The model is the classic Training Load card's (`TrainingLoadEngine` over each day's training load, the
/// heart-rate load Strain is scored from, not the 0–21 Strain), so the two screens cannot disagree, and like
/// the card it is descriptive only: it never changes Recovery. Owned by group "trends".
struct PulseTrainingLoadView: View {
    /// Existing entry points (Trends › TRAINING LOAD) open this screen instead of the classic Trends
    /// screen once it is true (see `PulseRoute.forExistingEntryPoint`).
    static let isRebuilt = true

    @Environment(PulseModel.self) private var model
    @State private var range: PulseTrendMath.Range = .sixMonths
    @State private var snapshot: TrainingLoadSnapshot?
    @ScaledMetric(relativeTo: .footnote) private var footnoteGlyph = PulseTheme.Trends.footnoteGlyph

    init() {
        #if DEBUG
        if let r = PulseTrendDebugLaunch.range { _range = State(initialValue: r) }
        #endif
    }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Training Load"), coach: .button, coachSeed: snapshot?.insight,
                            spacing: 0, ready: snapshot != nil) {
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot { content(snapshot) }
            } skeleton: {
                VStack(alignment: .leading, spacing: 24) {
                    PulseSkeletonBlock(height: 64)
                    PulseSkeletonBlock(height: 44)
                    PulseSkeletonBlock(height: 280)
                }
                .padding(.top, 18)
                .accessibilityElement()
                .accessibilityLabel(String(localized: "Loading"))
            }
        }
        .task(id: "\(model.healthKey)|\(range.rawValue)") {
            let range = self.range
            if let s = await model.build(dayOffset: 0, { builder, request in
                await builder.trainingLoad(request, range: range)
            }) {
                snapshot = s
            }
        }
    }

    private func content(_ s: TrainingLoadSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    headline(s)
                    Spacer(minLength: 0)
                    rangeControl
                }
                VStack(alignment: .leading, spacing: 20) {
                    headline(s)
                    rangeControl
                }
            }
            .padding(.top, 18)
            Text(s.insight)
                .pulseText(.trendInsight)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)
            if s.isAvailable {
                VStack(alignment: .trailing, spacing: 12) {
                    HStack(spacing: 16) {
                        legend(String(localized: "Fitness (CTL)"), PulseTheme.textPrimary)
                        legend(String(localized: "Fatigue (ATL)"), PulseTheme.strain)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    PulseTrendChart(model: s.chart)
                }
                .padding(.top, 24)
                HStack(spacing: 0) {
                    ForEach(s.stats) { stat in
                        VStack(spacing: 4) {
                            Text(stat.value)
                                .pulseText(.rowValue)
                                .foregroundStyle(PulseTheme.textPrimary)
                            Text(stat.title)
                                .pulseText(.label)
                                .foregroundStyle(PulseTheme.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.vertical, 14)
                .pulseCardBackground()
                .padding(.top, 20)
            }
            if let status = s.status, s.isAvailable {
                footnote(status).padding(.top, 14)
            }
            footnote(String(localized: "Fitness and fatigue are 42- and 7-day weighted averages of each day's training load (the heart-rate load your Strain is scored from, not the 0–21 Strain), and form is the gap between them. They describe your training; they never change your Recovery."))
                .padding(.top, 14)
        }
    }

    private func headline(_ s: TrainingLoadSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "Form"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
            Text(s.form)
                .pulseText(.largeValue)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 4)
            if !s.formWord.isEmpty {
                Text(s.formWord)
                    .pulseText(.chipStrong)
                    .foregroundStyle(PulseTheme.Delta.neutralText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.badge, style: .circular)
                        .fill(PulseTheme.Delta.neutralFill))
                    .padding(.top, 10)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
    }

    private var rangeControl: some View {
        PulseTrendSegments(label: String(localized: "Range"), options: PulseTrainingLoadBuilder.ranges,
                           selection: $range, title: { $0.segmentTitle }, spoken: { $0.spokenName })
            .frame(width: 180)
            .padding(.trailing, PulseTheme.Trends.rangeColumnTrailing)
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 7) {
            Capsule().fill(color).frame(width: 14, height: 3)
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    /// "i" then the note, set as the Trend View's footnotes are (deep-dives-2026/45).
    private func footnote(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PulseTheme.Trends.footnoteGap) {
            Image(systemName: "info")
                .font(.system(size: footnoteGlyph, weight: .semibold))
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(width: PulseTheme.Trends.footnoteGlyphColumn)
                .accessibilityHidden(true)
            Text(text)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
