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
/// (`ActivityStrainTarget`, from the range Home's Strain dial draws). Without a Recovery today there is no
/// range, so the panel says so and the switch rests.
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
    @State private var page = 0
    @State private var drag: CGFloat = 0
    @State private var showsHelp = false

    private var recommended: Double? { snapshot?.recommendedActivityStrain }
    private var available: Bool { recommended != nil }
    /// The target on show: the dragged one, else the recommendation, while the switch is on.
    private var target: Double? { targetOn ? (customTarget ?? recommended) : nil }

    var body: some View {
        let base = expanded ? expandedHeight : collapsedHeight
        let height = min(expandedHeight, max(collapsedHeight, base - drag))
        VStack(spacing: 0) {
            header
            if expanded {
                expandedBody
                    .transition(.opacity)
            }
            Spacer(minLength: 0)
            PulseStartActivityButton(style: .filled, action: onStart)
                .frame(maxWidth: 273)
                .padding(.top, 39)
                .padding(.bottom, max(40, safeBottom + 6))
        }
        .frame(height: height, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(PulseTheme.Activity.panelBody)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: PulseTheme.Radius.card,
                                          topTrailingRadius: PulseTheme.Radius.card, style: .circular))
        .animation(PulseMotion.resolved(PulseMotion.sheet, reduceMotion: reduceMotion), value: expanded)
        .environment(\.colorScheme, .light)
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
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.45))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.3), lineWidth: 1))
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
                    Text(target.map(PulseFormat.oneDecimal) ?? "---")
                        .font(PulseType.numeral(22))
                        .foregroundStyle(Color.black)
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
            .frame(height: 57)
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

    private var title: some View {
        Text(String(localized: "Strain Target"))
            .font(.system(size: 14, weight: .bold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(Color.black)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Expanded views

    @ViewBuilder
    private var expandedBody: some View {
        if let snapshot, let recommended, targetOn {
            let value = customTarget ?? recommended
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ringView(snapshot, value: value, recommended: recommended).tag(0)
                    PulseTrainingStateView(snapshot: snapshot, activity: value).tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { i in
                        Circle()
                            .fill(Color.black.opacity(page == i ? 0.75 : 0.18))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.top, 6)
                .accessibilityHidden(true)
            }
            .padding(.top, 12)
            #if DEBUG
            .onAppear { if PulseActivityDebug.panel == "chart" { page = 1 } }
            #endif
        } else {
            VStack(spacing: 14) {
                Image(systemName: "target")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.35))
                Text(available ? String(localized: "Strain Target is off. Switch it on to aim this activity at today's optimal Strain.")
                               : String(localized: "Your Strain Target appears once ZENO has scored today's Recovery."))
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 36)
            .padding(.top, 80)
        }
    }

    private func ringView(_ s: StartActivitySnapshot, value: Double, recommended: Double) -> some View {
        let estimated = s.estimatedDayStrain(adding: value)
        let state = estimated.flatMap { s.trainingState(estimated: $0) }
        let optimal: ClosedRange<Double>? = s.optimalRange.flatMap { range in
            guard let lo = s.activityStrain(toReach: range.lowerBound),
                  let hi = s.activityStrain(toReach: range.upperBound), hi > lo else { return nil }
            return lo...hi
        }
        return VStack(spacing: 22) {
            PulseStrainTargetRing(value: value, optimal: optimal, state: state?.title ?? "",
                                  isCustom: customTarget != nil,
                                  onChange: { customTarget = $0 }, onReset: { customTarget = nil })
                .frame(width: 290, height: 290)
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().strokeBorder(Color.black, lineWidth: 1.5)
                    PulseZenoMonogramShape()
                        .stroke(Color.black, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                        .frame(width: 15, height: 15)
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
                Text(sentence(s, value: value, recommended: recommended, estimated: estimated, state: state))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.black)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
        }
    }

    private func sentence(_ s: StartActivitySnapshot, value: Double, recommended: Double, estimated: Double?,
                          state: ActivityStrainTarget.TrainingState?) -> String {
        let shown = PulseFormat.oneDecimal(value)
        if recommended < 0.05, customTarget == nil || PulseFormat.oneDecimal(recommended) == shown {
            // Today is already at or past the middle of its range: there is nothing left to build.
            let day = PulseFormat.oneDecimal(s.dayStrain ?? 0)
            if let pct = s.recoveryPercent {
                return String(localized: "Today's Strain of \(day) is already at or past your optimal range for a \(pct)% Recovery, so your target is 0.0.")
            }
            return String(localized: "Today's Strain of \(day) is already at or past your optimal range, so your target is 0.0.")
        }
        if customTarget == nil || PulseFormat.oneDecimal(recommended) == shown {
            if let pct = s.recoveryPercent {
                return String(localized: "Based on your \(pct)% Recovery, build a \(shown) Activity Strain to reach your optimal Day Strain.")
            }
            return String(localized: "Build a \(shown) Activity Strain to reach your optimal Day Strain.")
        }
        let day = estimated.map(PulseFormat.oneDecimal) ?? "–"
        switch state {
        case .overreaching:
            return String(localized: "A \(shown) Activity Strain would take today to \(day), above your optimal range.")
        case .restorative:
            return String(localized: "A \(shown) Activity Strain would take today to \(day), below your optimal range.")
        default:
            return String(localized: "A \(shown) Activity Strain would take today to \(day), inside your optimal range.")
        }
    }
}

// MARK: - The small target glyph (collapsed header)

/// The 26 pt ring at the left of the collapsed header: the target as a share of 21, or an empty ring.
struct PulseTargetGlyph: View {
    let fraction: Double?

    var body: some View {
        ZStack {
            Circle().stroke(Color.black.opacity(0.1), lineWidth: 3)
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

/// A ≈290 pt ring on the light panel: the light track, the navy → blue arc to the target, a white knob with
/// ZENO's mark at the arc's end that drags the target round the ring, the dashed OPTIMAL arc outside it
/// over the activity Strains that keep the day in its optimal range, and in the middle ACTIVITY STRAIN, the
/// value, the training state and a reset to the recommendation.
struct PulseStrainTargetRing: View {
    let value: Double
    let optimal: ClosedRange<Double>?
    let state: String
    let isCustom: Bool
    let onChange: (Double) -> Void
    let onReset: () -> Void

    private let stroke: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - 26
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let fraction = max(0.005, min(1, value / 21))
            ZStack {
                Circle()
                    .stroke(PulseTheme.Activity.panelGrabber, lineWidth: stroke)
                    .frame(width: radius * 2, height: radius * 2)
                PulseRingSegment(start: 0, end: fraction, thickness: stroke, cornerRadius: 0)
                    .fill(AngularGradient(gradient: PulseTheme.Activity.liveRingArc, center: .center,
                                          startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * fraction)))
                    .frame(width: radius * 2 + stroke, height: radius * 2 + stroke)
                if let optimal {
                    optimalArc(optimal, radius: radius + stroke / 2 + 13, center: center)
                }
                centreText
                knob
                    .position(point(at: fraction, radius: radius, center: center))
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                let dx = drag.location.x - center.x, dy = drag.location.y - center.y
                guard hypot(dx, dy) > radius * 0.45 else { return }
                var angle = Double(atan2(dx, -dy))
                if angle < 0 { angle += 2 * .pi }
                var next: Double = (angle / (2 * .pi)) * 21
                // No wrapping through the top: past 21 stays at 21, under 0 stays at the floor.
                if value > 17 && next < 4 { next = 21 }
                if value < 4 && next > 17 { next = 0.1 }
                onChange(max(0.1, min(21, (next * 10).rounded() / 10)))
            })
            .sensoryFeedback(.selection, trigger: Int(value))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Activity Strain target"))
        .accessibilityValue("\(PulseFormat.oneDecimal(value)), \(state)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onChange(min(21, value + 0.5))
            case .decrement: onChange(max(0.1, value - 0.5))
            @unknown default: break
            }
        }
    }

    private var centreText: some View {
        VStack(spacing: 2) {
            Text(String(localized: "Activity Strain"))
                .font(.system(size: 15, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.black)
            Text(PulseFormat.oneDecimal(value))
                .font(PulseType.numeral(76))
                .foregroundStyle(Color.black)
                .contentTransition(.identity)
                .padding(.vertical, -4)
            Text(state)
                .font(.system(size: 15, weight: .bold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.45))
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.black.opacity(isCustom ? 0.55 : 0.25))
                    .frame(width: 38, height: 38)
                    .overlay(Circle().strokeBorder(Color.black.opacity(isCustom ? 0.3 : 0.15), lineWidth: 1))
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .disabled(!isCustom)
            .accessibilityLabel(String(localized: "Back to the recommended target"))
        }
    }

    private var knob: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.18), radius: 4, y: 1)
            PulseZenoMonogramShape()
                .stroke(Color.black, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: 16, height: 16)
        }
        .frame(width: 44, height: 44)
    }

    /// The dashed OPTIMAL arc and its label.
    private func optimalArc(_ range: ClosedRange<Double>, radius: CGFloat, center: CGPoint) -> some View {
        let lo = max(0, min(1, range.lowerBound / 21)), hi = max(0, min(1, range.upperBound / 21))
        let mid = (lo + hi) / 2
        return ZStack {
            Circle()
                .trim(from: lo, to: hi)
                .stroke(Color.black.opacity(0.75), style: StrokeStyle(lineWidth: 1.4, dash: [4, 4]))
                .rotationEffect(.degrees(-90))
                .frame(width: radius * 2, height: radius * 2)
            Text(String(localized: "Optimal"))
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Color.black)
                .fixedSize()
                .rotationEffect(.radians(mid * 2 * .pi + (mid > 0.25 && mid < 0.75 ? .pi : 0)))
                .position(point(at: mid, radius: radius + 11, center: center))
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
/// green baseline, and OPTIMAL TRAINING across the optimal range.
struct PulseTrainingStateView: View {
    let snapshot: StartActivitySnapshot
    let activity: Double

    private var current: Double { snapshot.dayStrain ?? 0 }
    private var estimated: Double { snapshot.estimatedDayStrain(adding: activity) ?? current }
    private var state: ActivityStrainTarget.TrainingState? { snapshot.trainingState(estimated: estimated) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(String(localized: "Training state: \(state?.title ?? "–")"))
                .font(.system(size: 16, weight: .bold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 4) {
                legend(String(localized: "Current day strain"), current, swatch: AnyView(solidSwatch))
                chevron
                legend(String(localized: "Activity strain"), activity, swatch: AnyView(hatchedSwatch))
                chevron
                legend(String(localized: "Estimated day strain*"), estimated, swatch: AnyView(splitSwatch))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "Day Strain"))
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.black)
                PulseDayStrainBarChart(current: current, estimated: estimated, recovery: snapshot.recoveryPercent,
                                       optimal: snapshot.optimalRange)
                    .frame(height: 190)
            }
            Text(String(localized: "*If this activity builds the target Strain."))
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.5))
        }
        .padding(.horizontal, 22)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.4))
            .padding(.top, 46)
            .accessibilityHidden(true)
    }

    private func legend(_ title: String, _ value: Double, swatch: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            swatch.frame(width: 20, height: 20)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 30, alignment: .topLeading)
            Text(PulseFormat.oneDecimal(value))
                .font(PulseType.numeral(32))
                .foregroundStyle(Color.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var solidSwatch: some View { Rectangle().fill(PulseTheme.strain) }
    private var hatchedSwatch: some View {
        PulseHatchedTrack(color: PulseTheme.strain.opacity(0.55), spacing: 4, cornerRadius: 0)
            .background(PulseTheme.strain.opacity(0.18))
    }
    private var splitSwatch: some View {
        ZStack {
            hatchedSwatch
            PulseTriangleCorner().fill(PulseTheme.strain)
        }
    }
}

/// The lower-left half of a square (the ESTIMATED swatch's solid half).
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

/// The DAY STRAIN chart on the light panel.
struct PulseDayStrainBarChart: View {
    let current: Double
    let estimated: Double
    let recovery: Int?
    let optimal: ClosedRange<Double>?

    private let ticks: [Double] = [0, 6, 10, 14, 18, 21]

    var body: some View {
        GeometryReader { geo in
            let labelWidth: CGFloat = 40
            let plot = CGRect(x: labelWidth, y: 8, width: geo.size.width - labelWidth, height: geo.size.height - 32)
            let y = { (v: Double) -> CGFloat in plot.maxY - plot.height * CGFloat(max(0, min(21, v)) / 21) }
            let barX = plot.minX + plot.width * CGFloat(Double(recovery ?? 50) / 100)
            ZStack(alignment: .topLeading) {
                // Grid: a line at each whole Strain, darker at the labelled ones, and quarter columns.
                Path { p in
                    for s in 0...21 { p.move(to: CGPoint(x: plot.minX, y: y(Double(s)))); p.addLine(to: CGPoint(x: plot.maxX, y: y(Double(s)))) }
                    for q in 0...4 {
                        let x = plot.minX + plot.width * CGFloat(q) / 4
                        p.move(to: CGPoint(x: x, y: plot.minY)); p.addLine(to: CGPoint(x: x, y: plot.maxY))
                    }
                }
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
                ForEach(ticks, id: \.self) { t in
                    Text(String(format: "%.1f", t))
                        .font(PulseType.numeral(15))
                        .foregroundStyle(PulseTheme.strain)
                        .position(x: labelWidth / 2 - 2, y: y(t))
                }
                if let optimal {
                    // Across the optimal range, on the side of the plot the bar leaves free.
                    Text(String(localized: "Optimal training"))
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.black.opacity(0.32))
                        .fixedSize()
                        .position(x: barX < plot.midX ? plot.minX + plot.width * 0.7 : plot.minX + plot.width * 0.3,
                                  y: y((optimal.lowerBound + optimal.upperBound) / 2))
                }
                // The estimate's dashed line across the plot and its value over the cap.
                Path { p in
                    p.move(to: CGPoint(x: plot.minX, y: y(estimated)))
                    p.addLine(to: CGPoint(x: barX, y: y(estimated)))
                }
                .stroke(Color.black.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                PulseHatchedTrack(color: PulseTheme.strain.opacity(0.55), spacing: 5, cornerRadius: 0)
                    .background(PulseTheme.strain.opacity(0.16))
                    .frame(width: 20, height: max(0, y(current) - y(estimated)))
                    .position(x: barX, y: (y(current) + y(estimated)) / 2)
                Rectangle()
                    .fill(PulseTheme.strain)
                    .frame(width: 20, height: max(0, plot.maxY - y(current)))
                    .position(x: barX, y: (plot.maxY + y(current)) / 2)
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 24, height: 3)
                    .position(x: barX, y: y(estimated))
                Text(PulseFormat.oneDecimal(estimated))
                    .font(PulseType.numeral(20))
                    .foregroundStyle(Color.black)
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
                        .font(PulseType.numeral(15))
                        .foregroundStyle(Color.black)
                        .position(x: barX, y: plot.maxY + 15)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Day Strain"))
        .accessibilityValue(String(localized: "\(PulseFormat.oneDecimal(current)) now, \(PulseFormat.oneDecimal(estimated)) after this activity"))
    }
}
#endif
