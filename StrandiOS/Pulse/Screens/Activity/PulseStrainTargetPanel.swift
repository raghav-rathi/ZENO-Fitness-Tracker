#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The Strain Target panel (WHOOP_UI_SPEC §3.8, §2.6 item 29): the app's one light surface. Collapsed, a
/// white header row (grabber, a small ring showing the target, the target value, STRAIN TARGET, the switch)
/// over the light-grey button area with the blue START ACTIVITY. Drag it up (or tap the header) for the
/// two views of the target: the light ring, whose knob can be dragged to a different target, and the
/// TRAINING STATE chart of the day it would leave.
///
/// The target is the Activity Strain that takes today's Strain to the middle of today's optimal range
/// (`ActivityStrainTarget`, from the range Home's Strain dial draws). Without today's Recovery there is no
/// range, so the panel says so and the switch rests; once today has reached the middle of its range there
/// is nothing left to build, so the panel says where the day stands instead of offering a 0.0 target.
struct PulseStrainTargetPanel: View {
    let snapshot: StartActivitySnapshot?
    @Binding var targetOn: Bool
    @Binding var customTarget: Double?
    @Binding var expanded: Bool
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    let safeBottom: CGFloat
    let onStart: (AppModel) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pulseNavigator) private var navigator
    @State private var page = 0
    @State private var drag: CGFloat = 0
    @State private var showsHelp = false

    private var recommended: Double? { snapshot?.recommendedActivityStrain }
    private var available: Bool { recommended != nil }
    /// Today already reached its target and nothing was dragged: no target to show or start with.
    private var reached: Bool { customTarget == nil && (snapshot?.targetReached ?? false) }
    /// The Activity Strain on show while the switch is on: the dragged one, else the recommendation, none
    /// once today has reached its target.
    private var target: Double? {
        guard targetOn else { return nil }
        if let customTarget { return customTarget }
        return reached ? nil : recommended
    }

    var body: some View {
        // The panel follows the finger while it is dragged (up grows it), then settles open or closed.
        let base = expanded ? expandedHeight : collapsedHeight
        let height = min(expandedHeight, max(collapsedHeight, base + drag))
        VStack(spacing: 0) {
            header
            if expanded {
                expandedBody
                    .transition(.opacity)
            }
            Spacer(minLength: 0)
            PulseStartActivityButton(style: .filled, action: onStart)
                .frame(maxWidth: 273)
                .padding(.top, expanded ? 12 : 39)
                .padding(.bottom, max(40, safeBottom + 6))
        }
        .frame(height: height, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(PulseTheme.Activity.panelBody)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: PulseTheme.Radius.card,
                                          topTrailingRadius: PulseTheme.Radius.card, style: .circular))
        .animation(PulseMotion.resolved(PulseMotion.sheet, reduceMotion: reduceMotion), value: expanded)
        .environment(\.colorScheme, .light)
        // The light panel's rows are laid out for the phone's width; past this they would overlap.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .fullScreenCover(isPresented: $showsHelp) {
            PulseDialogCard(title: String(localized: "Strain Target"),
                            message: String(localized: "Your target is the Activity Strain that takes today's Strain to the middle of your optimal range, set by today's Recovery. Drag the knob to aim higher or lower; the live session marks your target on its ring."),
                            primaryTitle: String(localized: "Got it"),
                            primary: { showsHelp = false },
                            onClose: { showsHelp = false })
                .presentationBackground(.clear)
        }
    }

    // MARK: Header row

    private var header: some View {
        VStack(spacing: 0) {
            Capsule(style: .circular)
                .fill(PulseTheme.Activity.panelGrabber)
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            HStack(spacing: 0) {
                if expanded {
                    Button { showsHelp = true } label: {
                        Text(verbatim: "?")
                            .activityText(.panelHelpGlyph)
                            .foregroundStyle(PulseActivityStyle.panelInkMuted)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(PulseActivityStyle.panelOutline, lineWidth: 1))
                            .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "About Strain Target"))
                    Spacer(minLength: 8)
                    title
                    Spacer(minLength: 8)
                } else {
                    PulseTargetGlyph(fraction: target.map { $0 / 21 })
                        .padding(.leading, 6)
                    collapsedValue
                        .padding(.leading, 18)
                        .frame(minWidth: 56, alignment: .leading)
                    Spacer(minLength: 8)
                    title
                    Spacer(minLength: 8)
                }
                PulseLightToggle(isOn: $targetOn, disabled: !available)
                    .accessibilityLabel(String(localized: "Strain Target"))
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 57)
        }
        .frame(maxWidth: .infinity)
        .background(PulseTheme.Activity.panelHeader)
        .contentShape(Rectangle())
        .onTapGesture { expanded.toggle() }
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in drag = -value.translation.height }
                .onEnded { value in
                    if value.translation.height < -50 { expanded = true }
                    if value.translation.height > 50 { expanded = false }
                    drag = 0
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: expanded ? String(localized: "Collapse") : String(localized: "Expand")) {
            expanded.toggle()
        }
    }

    /// "12.2"; a check once today has reached its target; "---" when off or before today's Recovery (with a
    /// line saying why the switch rests then).
    @ViewBuilder
    private var collapsedValue: some View {
        if let target {
            Text(PulseFormat.oneDecimal(target))
                .font(PulseType.numeral(22))
                .foregroundStyle(PulseActivityStyle.panelInk)
        } else if targetOn && reached {
            Image(systemName: "checkmark")
                .font(.system(size: PulseActivityStyle.Glyph.panelCheck, weight: .bold))
                .foregroundStyle(PulseActivityStyle.panelInk)
                .accessibilityLabel(String(localized: "Strain Target reached"))
        } else {
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "---")
                    .font(PulseType.numeral(22))
                    .foregroundStyle(PulseActivityStyle.panelInk)
                    .accessibilityLabel(String(localized: "No target"))
                if snapshot != nil && !available {
                    Text(String(localized: "After today's Recovery"))
                        .activityText(.panelFootnote)
                        .foregroundStyle(PulseActivityStyle.panelInkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    private var title: some View {
        Text(String(localized: "Strain Target"))
            .activityText(.panelTitle)
            .foregroundStyle(PulseActivityStyle.panelInk)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Expanded views

    @ViewBuilder
    private var expandedBody: some View {
        if let snapshot, available, targetOn {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ScrollView {
                        ringView(snapshot)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .tag(0)
                    ScrollView {
                        PulseTrainingStateView(snapshot: snapshot, activity: target)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 0) {
                    ForEach(0..<2, id: \.self) { i in
                        Button { page = i } label: {
                            Circle()
                                .fill(page == i ? PulseActivityStyle.panelDotOn : PulseActivityStyle.panelDotOff)
                                .frame(width: 7, height: 7)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(i == 0 ? String(localized: "Target ring") : String(localized: "Training state"))
                        .accessibilityAddTraits(page == i ? .isSelected : [])
                    }
                }
            }
            .padding(.top, 8)
            #if DEBUG
            .onAppear { if PulseActivityDebug.panel == "chart" { page = 1 } }
            #endif
        } else {
            VStack(spacing: 14) {
                Image(systemName: "target")
                    .font(.system(size: PulseActivityStyle.Glyph.panelEmpty, weight: .light))
                    .foregroundStyle(PulseActivityStyle.panelInkFaint)
                    .accessibilityHidden(true)
                Text(unavailableSentence)
                    .activityText(.panelBody)
                    .foregroundStyle(PulseActivityStyle.panelInkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 36)
            .padding(.top, 80)
        }
    }

    private var unavailableSentence: String {
        if available {
            return String(localized: "Strain Target is off. Switch it on to aim this activity at today's optimal Strain.")
        }
        if let snapshot, snapshot.recoveryCarried, let pct = snapshot.recoveryPercent {
            // The dial on Home shows an earlier night's Recovery until today's scores: say so, and why no
            // target is drawn from it.
            return String(localized: "Your Strain Target appears once ZENO has scored today's Recovery. The \(pct)% on Home is from an earlier night.")
        }
        return String(localized: "Your Strain Target appears once ZENO has scored today's Recovery.")
    }

    private func ringView(_ s: StartActivitySnapshot) -> some View {
        let shown = target
        let estimated = shown.flatMap { s.estimatedDayStrain(adding: $0) }
        let state: ActivityStrainTarget.TrainingState? = estimated.flatMap { s.trainingState(estimated: $0) }
            ?? (reached ? s.trainingState(estimated: s.dayStrain ?? 0) : nil)
        let optimal: ClosedRange<Double>? = s.optimalRange.flatMap { range in
            guard let lo = s.activityStrain(toReach: range.lowerBound),
                  let hi = s.activityStrain(toReach: range.upperBound), hi > lo else { return nil }
            return lo...hi
        }
        return VStack(spacing: 18) {
            PulseStrainTargetRing(value: shown, optimal: optimal,
                                  state: reached ? (s.pastOptimalRange ? (state?.title ?? "") : String(localized: "Reached"))
                                                 : (state?.title ?? ""),
                                  isCustom: customTarget != nil,
                                  onChange: { customTarget = $0 }, onReset: { customTarget = nil })
                .frame(width: PulseActivityStyle.targetRingFrame, height: PulseActivityStyle.targetRingFrame)
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().strokeBorder(PulseActivityStyle.panelInk, lineWidth: 1.5)
                    PulseZenoMonogramShape()
                        .stroke(PulseActivityStyle.panelInk, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 15, height: 15)
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(sentence(s, value: shown, estimated: estimated, state: state))
                        .activityText(.panelSentence)
                        .foregroundStyle(PulseActivityStyle.panelInk)
                        .fixedSize(horizontal: false, vertical: true)
                    // The guided Live Session, offered here (§3.8 ZENO data): it keeps you in a band instead.
                    Button { navigator.open(.guidedSession) } label: {
                        HStack(spacing: 6) {
                            Text(String(localized: "Guided session (beta)"))
                            Image(systemName: "arrow.right")
                        }
                        .activityText(.panelLink)
                        .foregroundStyle(PulseTheme.Activity.startCapsule)
                        .frame(minHeight: PulseTheme.Layout.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityHint(String(localized: "Opens a session that keeps your heart rate in a band"))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
        }
        .frame(maxWidth: .infinity)
        // Room above the ring for the OPTIMAL label when the range sits near the top.
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    /// The sentence under the ring. The reached cases tell the two apart: a day ABOVE its optimal range is
    /// past it; a day between the target and the top of the range is still optimal.
    private func sentence(_ s: StartActivitySnapshot, value: Double?, estimated: Double?,
                          state: ActivityStrainTarget.TrainingState?) -> String {
        let day = PulseFormat.oneDecimal(s.dayStrain ?? 0)
        guard let value else {
            if s.pastOptimalRange {
                if let pct = s.recoveryPercent {
                    return String(localized: "Today's \(day) Strain is above your optimal range for a \(pct)% Recovery.")
                }
                return String(localized: "Today's \(day) Strain is above your optimal range.")
            }
            let targetDay = PulseFormat.oneDecimal(s.targetDayStrain ?? 0)
            let top = PulseFormat.oneDecimal(s.optimalRange?.upperBound ?? 21)
            return String(localized: "You've reached today's Strain Target of \(targetDay); staying under \(top) keeps today optimal.")
        }
        let shown = PulseFormat.oneDecimal(value)
        if customTarget == nil || PulseFormat.oneDecimal(recommended ?? -1) == shown {
            if let pct = s.recoveryPercent {
                return String(localized: "Based on your \(pct)% Recovery, build a \(shown) Activity Strain to reach your optimal Day Strain.")
            }
            return String(localized: "Build a \(shown) Activity Strain to reach your optimal Day Strain.")
        }
        let after = estimated.map(PulseFormat.oneDecimal) ?? "–"
        switch state {
        case .overreaching:
            return String(localized: "A \(shown) Activity Strain would take today to \(after), above your optimal range.")
        case .restorative:
            return String(localized: "A \(shown) Activity Strain would take today to \(after), below your optimal range.")
        default:
            return String(localized: "A \(shown) Activity Strain would take today to \(after), inside your optimal range.")
        }
    }
}

// MARK: - The small target glyph (collapsed header)

/// The 26 pt ring at the left of the collapsed header: the target as a share of 21, or an empty ring.
struct PulseTargetGlyph: View {
    let fraction: Double?

    var body: some View {
        ZStack {
            Circle().stroke(PulseActivityStyle.panelGlyphTrack, lineWidth: 3)
            if let fraction {
                PulseRingSegment(start: 0, end: max(0.02, min(1, fraction)), thickness: 3, cornerRadius: 0)
                    .fill(AngularGradient(gradient: PulseTheme.Activity.liveRingArc, center: .center,
                                          startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * max(0.02, min(1, fraction)))))
            }
        }
        .frame(width: 26, height: 26)
        .padding(1.5)
        .accessibilityHidden(true)
    }
}

// MARK: - The light ring (§2.5 "Strain Target ring")

/// The light ring (a05: ≈296 pt across, a 16 pt stroke): the light track, the navy → blue arc to the target,
/// a white knob with ZENO's mark at the arc's end that drags the target round the ring, the dashed OPTIMAL
/// arc 13 pt outside it over the activity Strains that keep the day in its optimal range with its label
/// beyond, and in the middle ACTIVITY STRAIN, the value, the training state and a reset to the
/// recommendation. With no target (today reached it) the middle shows a check and the knob rests at the top.
struct PulseStrainTargetRing: View {
    let value: Double?
    let optimal: ClosedRange<Double>?
    let state: String
    let isCustom: Bool
    let onChange: (Double) -> Void
    let onReset: () -> Void

    private let stroke = PulseActivityStyle.targetRingStroke

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - PulseActivityStyle.targetRingInset
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let fraction = max(0.005, min(1, (value ?? 0) / 21))
            ZStack {
                Circle()
                    .stroke(PulseTheme.Activity.panelGrabber, lineWidth: stroke)
                    .frame(width: radius * 2, height: radius * 2)
                if value != nil {
                    PulseRingSegment(start: 0, end: fraction, thickness: stroke, cornerRadius: 0)
                        .fill(AngularGradient(gradient: PulseTheme.Activity.liveRingArc, center: .center,
                                              startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * fraction)))
                        .frame(width: radius * 2 + stroke, height: radius * 2 + stroke)
                }
                if let optimal {
                    optimalArc(optimal, radius: radius + stroke / 2 + PulseActivityStyle.targetArcGap, center: center)
                }
                centreText
                    .frame(maxWidth: radius * 2 - stroke - 24)
                knob
                    .position(point(at: value == nil ? 0 : fraction, radius: radius, center: center))
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // Only the ring's band drags the target, so a swipe from the middle still turns the page.
            .contentShape(PulseAnnulus(inset: PulseActivityStyle.targetRingInset - 22, thickness: 44 + stroke / 2), eoFill: true)
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                let dx = drag.location.x - center.x, dy = drag.location.y - center.y
                guard hypot(dx, dy) > radius * 0.45 else { return }
                var angle = Double(atan2(dx, -dy))
                if angle < 0 { angle += 2 * .pi }
                var next: Double = (angle / (2 * .pi)) * 21
                // No wrapping through the top: past 21 stays at 21, under 0 stays at the floor.
                let current = value ?? 0
                if current > 17 && next < 4 { next = 21 }
                if current < 4 && next > 17 { next = 0.1 }
                onChange(max(0.1, min(21, (next * 10).rounded() / 10)))
            })
            .sensoryFeedback(.selection, trigger: Int(value ?? 0))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Activity Strain target"))
        .accessibilityValue(value.map { "\(PulseFormat.oneDecimal($0)), \(state)" } ?? String(localized: "Reached, \(state)"))
        .accessibilityAdjustableAction { direction in
            let current = value ?? 0
            switch direction {
            case .increment: onChange(min(21, current + 0.5))
            case .decrement: onChange(max(0.1, current - 0.5))
            @unknown default: break
            }
        }
    }

    private var centreText: some View {
        VStack(spacing: 2) {
            Text(value == nil ? String(localized: "Strain Target") : String(localized: "Activity Strain"))
                .activityText(.panelRingLabel)
                .foregroundStyle(PulseActivityStyle.panelInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Group {
                if let value {
                    Text(PulseFormat.oneDecimal(value))
                        .font(PulseType.numeral(76))
                        .contentTransition(.identity)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: PulseActivityStyle.Glyph.ringCheck, weight: .bold))
                        .frame(height: 82)
                }
            }
            .foregroundStyle(PulseActivityStyle.panelInk)
            .padding(.vertical, -4)
            Text(state)
                .activityText(.panelRingLabel)
                .foregroundStyle(PulseActivityStyle.panelInkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: PulseActivityStyle.Glyph.panelReset, weight: .regular))
                    .foregroundStyle(isCustom ? PulseActivityStyle.panelInkMuted : PulseActivityStyle.panelOutlineFaint)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().strokeBorder(isCustom ? PulseActivityStyle.panelOutline : PulseActivityStyle.panelOutlineFaint,
                                                   lineWidth: 1))
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(!isCustom)
            .accessibilityLabel(String(localized: "Back to the recommended target"))
        }
    }

    /// The white knob: a hairline rim against the light track instead of a drop shadow (DR §9).
    private var knob: some View {
        ZStack {
            Circle()
                .fill(PulseActivityStyle.mapMarker)
                .overlay(Circle().strokeBorder(PulseActivityStyle.panelKnobRim, lineWidth: 1))
            PulseZenoMonogramShape()
                .stroke(PulseActivityStyle.panelInk, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: 16, height: 16)
        }
        .frame(width: 44, height: 44)
    }

    /// The dashed OPTIMAL arc and its label, the label curving with the arc, upright either side.
    private func optimalArc(_ range: ClosedRange<Double>, radius: CGFloat, center: CGPoint) -> some View {
        let lo = max(0, min(1, range.lowerBound / 21)), hi = max(0, min(1, range.upperBound / 21))
        let mid = (lo + hi) / 2
        return ZStack {
            Circle()
                .trim(from: lo, to: hi)
                .stroke(PulseActivityStyle.panelArc, style: StrokeStyle(lineWidth: 1.4, dash: [4, 4]))
                .rotationEffect(.degrees(-90))
                .frame(width: radius * 2, height: radius * 2)
            Text(String(localized: "Optimal"))
                .activityText(.panelArcLabel)
                .foregroundStyle(PulseActivityStyle.panelInk)
                .fixedSize()
                .rotationEffect(.radians(mid * 2 * .pi + (mid > 0.25 && mid < 0.75 ? .pi : 0)))
                .position(point(at: mid, radius: radius + PulseActivityStyle.targetArcLabelGap, center: center))
        }
        .accessibilityHidden(true)
    }

    private func point(at fraction: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = fraction * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
    }
}

// MARK: - TRAINING STATE (§3.8 "Chart view", §2.7 "Day-strain bar")

/// "TRAINING STATE: OPTIMAL", the three legend columns (CURRENT DAY STRAIN › ACTIVITY STRAIN › ESTIMATED
/// DAY STRAIN*) and the DAY STRAIN chart: today's Strain solid, the activity hatched on top to the
/// estimate (a black cap and a dashed line), the bar standing over today's Recovery on a red | yellow |
/// green baseline, and OPTIMAL TRAINING across the optimal range. With no target (today reached it) the
/// ACTIVITY STRAIN column reads "---" and the estimate is today's Strain.
struct PulseTrainingStateView: View {
    let snapshot: StartActivitySnapshot
    let activity: Double?

    private var current: Double { snapshot.dayStrain ?? 0 }
    private var estimated: Double { activity.flatMap { snapshot.estimatedDayStrain(adding: $0) } ?? current }
    private var state: ActivityStrainTarget.TrainingState? { snapshot.trainingState(estimated: estimated) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(String(localized: "Training state: \(state?.title ?? "–")"))
                .activityText(.panelHeading)
                .foregroundStyle(PulseActivityStyle.panelInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 4) {
                legend(String(localized: "Current day strain"), PulseFormat.oneDecimal(current), swatch: AnyView(solidSwatch))
                chevron
                legend(String(localized: "Activity strain"), activity.map(PulseFormat.oneDecimal) ?? "---",
                       swatch: AnyView(hatchedSwatch))
                chevron
                legend(String(localized: "Estimated day strain*"), PulseFormat.oneDecimal(estimated),
                       swatch: AnyView(splitSwatch))
            }
            // Columns as tall as the tallest, so the three values share one line however the captions wrap.
            .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Day Strain"))
                    .activityText(.panelChartTitle)
                    .foregroundStyle(PulseActivityStyle.panelInk)
                PulseDayStrainBarChart(current: current, estimated: estimated, recovery: snapshot.recoveryPercent,
                                       optimal: snapshot.optimalRange)
                    .frame(height: 210)
            }
            Text(String(localized: "*If this activity builds the target Strain."))
                .activityText(.panelFootnote)
                .foregroundStyle(PulseActivityStyle.panelInkLegend)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 8)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: PulseActivityStyle.Glyph.legendChevron, weight: .semibold))
            .foregroundStyle(PulseActivityStyle.panelInkMuted)
            .padding(.top, 46)
            .accessibilityHidden(true)
    }

    private func legend(_ title: String, _ value: String, swatch: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            swatch.frame(width: 20, height: 20)
            PulseActivityWordWrap(title, style: .panelLegend)
                .foregroundStyle(PulseActivityStyle.panelInkLegend)
                .frame(maxWidth: .infinity, minHeight: 30, maxHeight: .infinity, alignment: .topLeading)
            Text(value)
                .font(PulseType.numeral(32))
                .foregroundStyle(PulseActivityStyle.panelInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var solidSwatch: some View { Rectangle().fill(PulseTheme.strain) }
    private var hatchedSwatch: some View {
        PulseHatchedTrack(color: PulseActivityStyle.panelHatchStripe, spacing: 4, cornerRadius: 0)
            .background(PulseActivityStyle.panelHatchFill)
    }
    private var splitSwatch: some View {
        ZStack {
            hatchedSwatch
            PulseTriangleCorner().fill(PulseTheme.strain)
        }
    }
}

/// The upper-left half of a square (the ESTIMATED swatch's solid half).
struct PulseTriangleCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The DAY STRAIN chart on the light panel (a06): a line at every whole Strain, the plot split into sixths
/// (so verticals fall on the 33% and 66% Recovery boundaries of the baseline under it), the bar at today's
/// Recovery.
struct PulseDayStrainBarChart: View {
    let current: Double
    let estimated: Double
    let recovery: Int?
    let optimal: ClosedRange<Double>?

    private let ticks: [Double] = [0, 6, 10, 14, 18, 21]
    @ScaledMetric(relativeTo: .caption) private var axisSize: CGFloat = 15

    var body: some View {
        GeometryReader { geo in
            let labelWidth: CGFloat = 40
            let plot = CGRect(x: labelWidth, y: 8, width: geo.size.width - labelWidth, height: geo.size.height - 32)
            let y = { (v: Double) -> CGFloat in plot.maxY - plot.height * CGFloat(max(0, min(21, v)) / 21) }
            let barX = plot.minX + plot.width * CGFloat(Double(recovery ?? 50) / 100)
            ZStack(alignment: .topLeading) {
                Path { p in
                    for s in 0...21 { p.move(to: CGPoint(x: plot.minX, y: y(Double(s)))); p.addLine(to: CGPoint(x: plot.maxX, y: y(Double(s)))) }
                    for q in 0...6 {
                        let x = plot.minX + plot.width * CGFloat(q) / 6
                        p.move(to: CGPoint(x: x, y: plot.minY)); p.addLine(to: CGPoint(x: x, y: plot.maxY))
                    }
                }
                .stroke(PulseActivityStyle.panelGrid, lineWidth: 1)
                ForEach(ticks, id: \.self) { t in
                    Text(String(format: "%.1f", t))
                        .font(PulseType.numeral(min(axisSize, 15 * 1.3)))
                        .foregroundStyle(PulseTheme.strain)
                        .position(x: labelWidth / 2 - 2, y: y(t))
                }
                if let optimal {
                    // Across the optimal range, on the side of the plot the bar leaves free.
                    Text(String(localized: "Optimal training"))
                        .activityText(.panelBandLabel)
                        .foregroundStyle(PulseActivityStyle.panelInkFaint)
                        .fixedSize()
                        .position(x: barX < plot.midX ? plot.minX + plot.width * 0.7 : plot.minX + plot.width * 0.3,
                                  y: y((optimal.lowerBound + optimal.upperBound) / 2))
                }
                // The estimate's dashed line across the plot and its value over the cap.
                Path { p in
                    p.move(to: CGPoint(x: plot.minX, y: y(estimated)))
                    p.addLine(to: CGPoint(x: barX, y: y(estimated)))
                }
                .stroke(PulseActivityStyle.panelDash, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                PulseHatchedTrack(color: PulseActivityStyle.panelHatchStripe, spacing: 5, cornerRadius: 0)
                    .background(PulseActivityStyle.panelHatchFill)
                    .frame(width: 20, height: max(0, y(current) - y(estimated)))
                    .position(x: barX, y: (y(current) + y(estimated)) / 2)
                Rectangle()
                    .fill(PulseTheme.strain)
                    .frame(width: 20, height: max(0, plot.maxY - y(current)))
                    .position(x: barX, y: (plot.maxY + y(current)) / 2)
                Rectangle()
                    .fill(PulseActivityStyle.panelInk)
                    .frame(width: 24, height: 3)
                    .position(x: barX, y: y(estimated))
                Text(PulseFormat.oneDecimal(estimated))
                    .font(PulseType.numeral(20))
                    .foregroundStyle(PulseActivityStyle.panelInk)
                    .position(x: barX, y: y(estimated) - 16)
                // The Recovery baseline: red | yellow | green, today's Recovery under the bar.
                HStack(spacing: 0) {
                    Rectangle().fill(PulseTheme.recoveryLow).frame(width: plot.width * 0.34)
                    Rectangle().fill(PulseTheme.recoveryMid).frame(width: plot.width * 0.33)
                    Rectangle().fill(PulseTheme.recoveryHigh)
                }
                .frame(width: plot.width, height: 3)
                .offset(x: plot.minX, y: plot.maxY - 1)
                if let recovery {
                    Text("\(recovery)%")
                        .font(PulseType.numeral(min(axisSize, 15 * 1.3)))
                        .foregroundStyle(PulseActivityStyle.panelInk)
                        .position(x: barX, y: plot.maxY + 15)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Day Strain"))
        .accessibilityValue(String(localized: "\(PulseFormat.oneDecimal(current)) now, \(PulseFormat.oneDecimal(estimated)) after this activity"))
    }
}

/// A ring band `thickness` deep whose outer edge sits `inset` inside the frame (even-odd fill): the hit area
/// of the light ring's knob.
struct PulseAnnulus: Shape {
    var inset: CGFloat
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let outer = rect.insetBy(dx: max(0, inset), dy: max(0, inset))
        let inner = outer.insetBy(dx: thickness, dy: thickness)
        var p = Path()
        p.addEllipse(in: outer)
        if inner.width > 0 { p.addEllipse(in: inner) }
        return p
    }
}
#endif
