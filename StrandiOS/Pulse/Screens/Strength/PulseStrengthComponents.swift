#if os(iOS)
import SwiftUI
import Charts
import Observation
import StrandDesign

// MARK: - Strength Trainer pieces (WHOOP_UI_SPEC §3.29, §2.6, §2.7; activity-flows-2026/g01–g10)
//
// Shared by the Strength Trainer's root, the workout page, Exercise Details and the live session.

/// The Strength Trainer's colours beyond the shared token set (§2.1 "Activity-flow tokens" holds the
/// START SET outline, its pressed fill and the ACTIVE timer; these are the rest, sampled on g01/g07).
enum PulseStrengthColors {
    /// The workout rows and BUILD MANUALLY's fill (g01: #2E3237 on the page).
    static let rowFill = Color(hex: "#2C3035")
    /// The live session's exercise card (g07a: #2B3034), its divider and the stats row's rules.
    static let exerciseCard = Color(hex: "#2B3034")
    static let exerciseCardTop = Color(hex: "#30353A")
    /// The set inputs on the EXERCISES tab (g08: #16191C fields with a faint rim).
    static let inputFill = Color(hex: "#15181B")
    static let inputBorder = Color(hex: "#2E3338")
    /// The ACTIVE ring's rim, clockwise from 12 o'clock, sampled at the rim's peak on g07b (ring centre
    /// (200, 330.5), radius 116–118): blue at the top, bright green from 3 to 6 o'clock, navy at 9.
    static let activeRim = Gradient(stops: [
        .init(color: Color(hex: "#0E86D2"), location: 0),
        .init(color: Color(hex: "#2BBDD6"), location: 30.0 / 360),
        .init(color: Color(hex: "#21BDAF"), location: 60.0 / 360),
        .init(color: Color(hex: "#0FE897"), location: 90.0 / 360),
        .init(color: Color(hex: "#19E699"), location: 180.0 / 360),
        .init(color: Color(hex: "#32AD98"), location: 210.0 / 360),
        .init(color: Color(hex: "#0F6574"), location: 240.0 / 360),
        .init(color: Color(hex: "#0F3562"), location: 270.0 / 360),
        .init(color: Color(hex: "#195385"), location: 300.0 / 360),
        .init(color: Color(hex: "#1970B3"), location: 330.0 / 360),
        .init(color: Color(hex: "#0E86D2"), location: 1)
    ])
    /// The ACTIVE band is the rim's colours, dimmed (g07b: navy-tinted on the left, green on the right).
    static let activeBandOpacity = 0.2
    /// The REST ring's rim, lit from the bottom-left (g07a): #42474B at 12 o'clock, brightest at 8.
    static let restRim = Gradient(stops: [
        .init(color: Color(hex: "#42474B"), location: 0),
        .init(color: Color(hex: "#52575B"), location: 90.0 / 360),
        .init(color: Color(hex: "#828387"), location: 180.0 / 360),
        .init(color: Color(hex: "#A7ABAE"), location: 240.0 / 360),
        .init(color: Color(hex: "#757A7D"), location: 300.0 / 360),
        .init(color: Color(hex: "#42474B"), location: 1)
    ])
    /// The REST band is the rim's greys, dimmed (g07a: #2A2D32–#3D4144 on the page).
    static let restBandOpacity = 0.25
    /// The thumbnail tile's backdrop (ZENO has no exercise photos; a dark stage with a glyph stands in).
    static let thumbTop = Color(hex: "#25313A")
    static let thumbBottom = Color(hex: "#13181C")
    /// Medal tints for the top three sets (SF Symbols, not badge art).
    static let gold = Color(hex: "#E2B657")
    static let silver = Color(hex: "#C4C8CC")
    static let bronze = Color(hex: "#C08457")
}

/// Bumped whenever the Lift Log changes outside a repository refresh (a program edited, a session saved
/// or deleted), so every Strength screen reloads: they live in different presentations, so a shared
/// counter rather than a view's state.
@MainActor
@Observable
final class PulseStrengthVersion {
    static let shared = PulseStrengthVersion()
    private(set) var value = 0

    func bump() { value &+= 1 }
}

// MARK: Tabs

/// The underline tabs ("PROGRESS · MY WORKOUTS", "LIVE SESSION | EXERCISES"): bold caps, white with a 2 pt
/// underline when selected, 50% otherwise, on a hairline (g01, g07a).
struct PulseStrengthTabs<Tab: Hashable>: View {
    let tabs: [Tab]
    @Binding var selection: Tab
    var centred = false
    let title: (Tab) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var underline

    var body: some View {
        HStack(spacing: 28) {
            if centred { Spacer(minLength: 0) }
            ForEach(tabs, id: \.self) { tab in
                let selected = tab == selection
                Button {
                    selection = tab
                } label: {
                    Text(title(tab))
                        .pulseText(.menuLabel)
                        .foregroundStyle(selected ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        // The underline is exactly as wide as the label.
                        .overlay(alignment: .bottom) {
                            if selected {
                                Rectangle()
                                    .fill(PulseTheme.textPrimary)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "underline", in: underline)
                            }
                        }
                        .frame(minHeight: PulseTheme.Layout.minTapTarget, alignment: .bottom)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
            }
            Spacer(minLength: 0)
        }
        // Chrome, capped like the shared nav bar: at the largest sizes two labels would not fit a phone.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(PulseMotion.resolved(PulseMotion.menu, reduceMotion: reduceMotion), value: selection)
    }
}

// MARK: Thumbnail

/// An exercise's thumbnail: WHOOP shows a photo; ZENO has none, so a dark stage with the dumbbell glyph.
struct PulseStrengthThumbnail: View {
    var width: CGFloat = 64
    var height: CGFloat = 48

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [PulseStrengthColors.thumbTop, PulseStrengthColors.thumbBottom],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: height * 0.34, weight: .semibold))
                    .foregroundStyle(PulseTheme.textTertiary))
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

// MARK: Buttons

/// The set button: "START SET" in a mint outline (pressed: a bright mint fill), "END SET" in a white
/// outline, and the white "FINISH WORKOUT" once every set is done (g07c).
struct PulseStrengthSetButtonStyle: ButtonStyle {
    enum Kind { case start, end, finish }
    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .pulseText(.capsuleLabel)
            .foregroundStyle(foreground(pressed))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(background(pressed))
            .contentShape(Capsule())
            .animation(pressed ? nil : PulseMotion.pressRelease, value: pressed)
    }

    private func foreground(_ pressed: Bool) -> Color {
        switch kind {
        case .start: return pressed ? Color(hex: "#062417") : PulseTheme.Activity.strengthStartOutline
        case .end: return PulseTheme.textPrimary
        case .finish: return Color.black
        }
    }

    @ViewBuilder
    private func background(_ pressed: Bool) -> some View {
        switch kind {
        case .start:
            if pressed {
                Capsule(style: .continuous).fill(PulseTheme.Activity.strengthStartPressed)
            } else {
                Capsule(style: .continuous).strokeBorder(PulseTheme.Activity.strengthStartOutline, lineWidth: 2)
            }
        case .end:
            Capsule(style: .continuous).strokeBorder(Color.white, lineWidth: 2)
                .opacity(pressed ? 0.7 : 1)
        case .finish:
            Capsule(style: .continuous).fill(Color.white).opacity(pressed ? 0.8 : 1)
        }
    }
}

/// BUILD MANUALLY: the full-width grey rounded button with a bold caps label (g01).
struct PulseStrengthWideButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pulseText(.navTitle)
            .foregroundStyle(PulseTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseStrengthColors.rowFill))
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(configuration.isPressed ? nil : PulseMotion.pressRelease, value: configuration.isPressed)
    }
}

// MARK: The volume chart

/// The PROGRESS / Exercise Details chart (§2.7 "Trend View 6M"): each session's volume as a faint blue
/// line, the per-month (or per-week) averages as 3 pt segments with their value above, white for the
/// first and teal or orange after it by the direction of the change printed below, on three gridlines
/// with left-hand labels. Missing buckets are gaps, never zeros.
struct PulseStrengthVolumeChart: View {
    let chart: StrengthVolumeChart
    var height: CGFloat = 290

    var body: some View {
        Chart {
            ForEach(chart.points) { point in
                LineMark(x: .value("Day", point.date), y: .value("Volume", point.value), series: .value("Series", "sessions"))
                    .foregroundStyle(PulseTheme.strain.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1.2, lineJoin: .round))
                    .interpolationMethod(.linear)
            }
            ForEach(chart.segments) { segment in
                RuleMark(xStart: .value("From", segment.from), xEnd: .value("To", segment.to),
                         y: .value("Average", segment.value))
                    .foregroundStyle(color(segment.tone))
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .annotation(position: .top, alignment: .center, spacing: 4) {
                        Text(segment.valueText)
                            .font(PulseType.numeral(15))
                            .foregroundStyle(segment.tone == .first ? PulseTheme.textPrimary : color(segment.tone))
                            .fixedSize()
                    }
                    .annotation(position: .bottom, alignment: .center, spacing: 4) {
                        if let change = segment.changeText {
                            Text(change)
                                .font(PulseType.numeral(14))
                                .foregroundStyle(color(segment.tone))
                                .fixedSize()
                        }
                    }
            }
        }
        .chartYScale(domain: 0...chart.yMax)
        .chartXScale(domain: chart.start...chart.end)
        .chartYAxis {
            AxisMarks(position: .leading, values: chart.yTicks) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(PulseTheme.gridOnPage)
                AxisValueLabel {
                    if let number = value.as(Double.self) {
                        Text(Self.axisLabel(number))
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: chart.xTicks) { value in
                AxisValueLabel(centered: chart.monthLabels) {
                    if let date = value.as(Date.self) {
                        Text(chart.monthLabels ? date.formatted(.dateTime.month(.abbreviated))
                                               : date.formatted(.dateTime.day()))
                            .font(PulseType.font(.axis))
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            plot.padding(.top, 22).padding(.bottom, 20)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Volume load chart"))
        .accessibilityValue(accessibilitySummary)
    }

    private func color(_ tone: StrengthVolumeChart.Tone) -> Color {
        switch tone {
        case .first: return PulseTheme.textPrimary
        case .up: return PulseTheme.positive
        case .down: return PulseTheme.negative
        case .flat: return PulseTheme.neutral
        }
    }

    /// "15k", "10k", "5,000", "0", as the captures label the axis.
    static func axisLabel(_ value: Double) -> String {
        if value >= 10_000 {
            let thousands = value / 1_000
            return thousands == thousands.rounded() ? "\(Int(thousands))k" : String(format: "%.1fk", thousands)
        }
        return Int(value.rounded()).formatted(.number)
    }

    private var accessibilitySummary: String {
        guard !chart.segments.isEmpty else { return String(localized: "No sessions in this period") }
        return chart.segments.map { segment in
            let month = segment.from.formatted(.dateTime.month(.wide).day())
            if let change = segment.changeText {
                return String(localized: "From \(month): average \(segment.valueText), \(change)")
            }
            return String(localized: "From \(month): average \(segment.valueText)")
        }.joined(separator: ". ")
    }
}

/// "Ø VOLUME LOAD" / "AVG VOLUME LOAD" over its value, with the range control and pager at the right.
struct PulseStrengthChartHeader: View {
    let label: String
    let value: String?
    let unit: String
    @Binding var range: StrengthRange
    let pager: StrengthPager
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                valueBlock
                Spacer(minLength: 8)
                controls.frame(width: 196)
            }
            VStack(alignment: .leading, spacing: 14) {
                valueBlock
                controls
            }
        }
    }

    private var valueBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
            PulseValueText(value: value ?? "--", unit: value == nil ? nil : unit, style: .largeValue,
                           unitStyle: .tileUnit, color: value == nil ? PulseTheme.textDisabled : PulseTheme.textPrimary,
                           unitColor: PulseTheme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            PulseSegmentedControl(options: StrengthRange.allCases, selection: $range) { $0.title }
            HStack(spacing: 0) {
                chevron("chevron.left", enabled: pager.canGoBack, label: String(localized: "Previous"), action: onBack)
                // Two lines rather than a cut-off date (g02: "NOV. 27, 25 - MAI / 25, 26").
                Text(pager.title)
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
                chevron("chevron.right", enabled: pager.canGoForward, label: String(localized: "Next"), action: onForward)
            }
        }
    }

    private func chevron(_ symbol: String, enabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: 28, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

// MARK: Live zone bar

/// The live heart-rate zone bar (§2.5): six segments, Zone 0 → Zone 5, the current one lit in its zone
/// colour with a white dot at the heart rate's place in it, the rest dark tints of theirs; labels below,
/// the current one white.
struct PulseStrengthZoneBar: View {
    /// 0…5, nil when there is no heart rate.
    let zone: Int?
    /// Where in the current zone the heart rate sits, 0…1.
    let position: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let gap: CGFloat = 2
                let width = (geo.size.width - gap * 5) / 6
                ZStack(alignment: .leading) {
                    HStack(spacing: gap) {
                        ForEach(0..<6, id: \.self) { index in
                            Capsule(style: .continuous)
                                .fill(index == zone ? PulseTheme.Zone.color(index) : PulseTheme.Zone.dimmed(index))
                                .frame(width: width, height: 5)
                        }
                    }
                    if let zone {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 11, height: 11)
                            .shadow(color: .black.opacity(0.4), radius: 2)
                            .offset(x: CGFloat(zone) * (width + gap) + width * CGFloat(min(1, max(0, position))) - 5.5)
                    }
                }
                .frame(height: 11)
            }
            .frame(height: 11)
            HStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { index in
                    Text(String(localized: "Zone \(index)"))
                        .pulseText(index == zone ? .chipStrong : .chip)
                        .foregroundStyle(index == zone ? PulseTheme.textPrimary : PulseTheme.Zone.dimmed(index))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
            }
            // Six labels share one row; the element reads its zone to VoiceOver as a whole.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart-rate zone"))
        .accessibilityValue(zone.map { String(localized: "Zone \($0)") } ?? String(localized: "No reading"))
    }
}

// MARK: Keyboard

extension View {
    /// A white "Done" above the decimal pad (which has no return key).
    func pulseKeyboardDone<Value: Hashable>(_ focus: FocusState<Value?>.Binding) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done")) { focus.wrappedValue = nil }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PulseTheme.textPrimary)
            }
        }
    }
}
#endif
