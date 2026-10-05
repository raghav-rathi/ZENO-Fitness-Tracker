#if os(iOS)
import SwiftUI

// MARK: - VO₂ max card (WHOOP_UI_SPEC §3.28; whoop-site/29, onboarding/32c)

/// "VO₂ MAX ⓘ": the latest weekly VO₂ max above a white ▼ on a five-band scale whose bands carry coloured
/// top borders (<35 grey, 35 #ADC2CD, 40 #67AEE6, 45 #A4A3F1, 50+ purple), the band holding the value lit,
/// then the band in words and a personal line. ZENO has no age and sex norms, so it never names a
/// population category or percentile ([POP]); it compares the value with your own history instead.
///
/// Locked: "Log N more sleeps to unlock" with a thin progress bar, or, once the sleeps are there and no
/// estimate exists yet, what is missing. The VO₂ Max Trend View draws it under its chart as YOUR CARDIO
/// FITNESS LEVEL (§3.28, reviews/83); Healthspan shows VO₂ max as a Fitness row instead (reviews/29). The ⓘ
/// opens what the estimate is and what it reads (onboarding/32c shows it), unless the caller handles it
/// with `onInfo`.
struct HealthVO2MaxCard: View {
    enum State: Equatable {
        /// The latest value (mL/kg/min), when it was estimated, and a line comparing it with your history.
        case value(Double, updated: String?, note: String?)
        /// Fewer than `needed` sleeps logged.
        case locked(nights: Int, needed: Int)
        /// Enough sleeps, but no estimate: the reason, in a sentence.
        case missing(String)
    }

    let state: State
    /// The card's caps title: "VO₂ MAX", or the Trend View's "YOUR CARDIO FITNESS LEVEL".
    var title: String = String(localized: "VO₂ Max")
    /// Handles the ⓘ itself; nil opens the card's own explainer.
    var onInfo: (() -> Void)?
    var style: PulseCardStyle = .standard

    @SwiftUI.State private var showsInfo = false

    var body: some View {
        PulseCard(style) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    PulseCardTitle(title)
                    Button {
                        if let onInfo { onInfo() } else { showsInfo = true }
                    } label: {
                        Image(systemName: "info.circle")
                            .healthGlyph(.info)
                            .foregroundStyle(PulseTheme.textTertiary)
                            .frame(width: PulseTheme.Layout.minTapTarget, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "About VO₂ max"))
                }
                switch state {
                case .value(let v, let updated, let note):
                    HealthVO2Scale(value: v)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bandLine(v))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textPrimary)
                        if let note {
                            Text(note)
                                .pulseText(.body)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let updated {
                            Text(updated)
                                .pulseText(.secondary)
                                .foregroundStyle(PulseTheme.textTertiary)
                        }
                    }
                case .locked(let nights, let needed):
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Log \(max(0, needed - nights)) more sleeps to unlock"))
                            .pulseText(.subtitle)
                            .foregroundStyle(PulseTheme.textSecondary)
                        HealthProgressBar(fraction: needed > 0 ? Double(nights) / Double(needed) : 0,
                                          fill: PulseTheme.textSecondary, track: PulseTheme.track)
                    }
                    .accessibilityElement(children: .combine)
                case .missing(let reason):
                    Text(reason)
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .sheet(isPresented: $showsInfo) {
            HealthInfoSheet(title: String(localized: "About VO₂ max"), paragraphs: Self.infoParagraphs)
        }
    }

    static let infoParagraphs: [String] = [
        String(localized: "VO₂ max is the most oxygen your body can use during hard exercise, in millilitres per kilogram of body weight per minute (mL/kg/min). Higher is fitter."),
        String(localized: "ZENO estimates it once a week from the last seven days: your resting heart rate, age, biological sex and recent activity, plus your waist measurement when your profile has one (a published non-exercise formula). Without a waist it uses a simpler heart-rate ratio, which is rougher."),
        String(localized: "It is an estimate from your own data, not a lab test, so read it as a trend. ZENO has no population data, so it compares the value with your own history rather than with other people."),
    ]

    /// "In the 40–44 mL/kg/min band": the scale's own band, no population label.
    private func bandLine(_ v: Double) -> String {
        let cuts = HealthPalette.vo2CutOffs
        let whole = Int(v.rounded())
        if let first = cuts.first, v < first {
            return String(localized: "\(whole) mL/kg/min, under \(Int(first))")
        }
        if let last = cuts.last, v >= last {
            return String(localized: "\(whole) mL/kg/min, \(Int(last)) and above")
        }
        for i in 0..<(cuts.count - 1) where v >= cuts[i] && v < cuts[i + 1] {
            return String(localized: "\(whole) mL/kg/min, in the \(Int(cuts[i]))–\(Int(cuts[i + 1]) - 1) band")
        }
        return String(localized: "\(whole) mL/kg/min")
    }
}

/// The five-band scale with the value above its ▼.
struct HealthVO2Scale: View {
    let value: Double

    /// The band index the value falls in (0…4) and where in it (0…1).
    private var position: (band: Int, fraction: Double) {
        let cuts = HealthPalette.vo2CutOffs
        // The open-ended bands get a nominal 5 mL/kg/min of width so the marker still moves inside them.
        let edges = [cuts[0] - 5] + cuts + [cuts[cuts.count - 1] + 5]
        for i in 0..<(edges.count - 1) where value < edges[i + 1] || i == edges.count - 2 {
            let f = (value - edges[i]) / (edges[i + 1] - edges[i])
            return (i, min(1, max(0, f)))
        }
        return (0, 0)
    }

    var body: some View {
        let pos = position
        let colors = HealthPalette.vo2Segments
        GeometryReader { geo in
            let gap: CGFloat = 2
            let count = CGFloat(colors.count)
            let width = (geo.size.width - gap * (count - 1)) / count
            let x = CGFloat(pos.band) * (width + gap) + width * CGFloat(pos.fraction)
            ZStack(alignment: .topLeading) {
                VStack(spacing: 2) {
                    Text(PulseFormat.whole(value))
                        .font(PulseType.font(.calloutValue))
                        .foregroundStyle(PulseTheme.textPrimary)
                        .fixedSize()
                    PulseTriangle(pointsUp: false)
                        .fill(Color.white)
                        .frame(width: 11, height: 8)
                }
                .position(x: min(max(x, 14), geo.size.width - 14), y: 15)
                HStack(spacing: gap) {
                    ForEach(0..<colors.count, id: \.self) { i in
                        ZStack(alignment: .top) {
                            Rectangle()
                                .fill(i == pos.band ? colors[i].opacity(0.32) : HealthPalette.vo2SegmentWell)
                            Rectangle()
                                .fill(colors[i])
                                .frame(height: 2)
                            Text(label(i))
                                .font(PulseType.font(.axis))
                                .foregroundStyle(i == pos.band ? PulseTheme.textPrimary : colors[i])
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .padding(.leading, 6)
                        }
                        .frame(width: width, height: 26)
                    }
                }
                .offset(y: 34)
            }
        }
        .frame(height: 60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "VO₂ max"))
        .accessibilityValue(String(localized: "\(PulseFormat.whole(value)) millilitres per kilogram per minute"))
    }

    private func label(_ i: Int) -> String {
        let cuts = HealthPalette.vo2CutOffs
        if i == 0 { return "<\(Int(cuts[0]))" }
        if i == cuts.count { return "\(Int(cuts[cuts.count - 1]))+" }
        return "\(Int(cuts[i - 1]))"
    }
}

/// A thin rounded progress bar (4 pt): the unlock cards and the VO₂ lock.
struct HealthProgressBar: View {
    let fraction: Double
    var fill: Color = PulseTheme.Gradients.healthUnlockProgress
    var track: Color = PulseTheme.Gradients.healthUnlockTrack
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .circular).fill(track)
                Capsule(style: .circular)
                    .fill(fill)
                    .frame(width: geo.size.width * CGFloat(min(1, max(0, fraction))))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
#endif
