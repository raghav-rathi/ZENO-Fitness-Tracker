import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Steps charts
//
// Plain SwiftUI bars rather than Swift Charts: the three charts here are fixed 24/7/30-slot strips with one
// goal line, which a stack of shapes draws exactly, identically on iOS and macOS 13, with no axis machinery to
// fight. Every value comes pre-resolved (`StepsHourly.Chart`, `StepsStats.Bar`); these views only render.

/// Labels for day keys and clock hours, in the two time systems the charts mix.
///
/// DAY KEYS are civil dates parsed at UTC midnight (`StepsDayKeys.utcMidnight`), so they are formatted in
/// UTC too; in the device zone a key would print as the previous day anywhere west of UTC. HOURS are real
/// instants (local midnight plus N hours), so they are formatted in the device zone and follow the app's
/// clock setting. Main-actor because only views call it, which keeps the cached formatters single-threaded.
@MainActor
enum StepsLabels {
    private static func utcFormatter(_ template: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = AppLanguage.activeLocale
        f.timeZone = TimeZone(identifier: "UTC")
        f.setLocalizedDateFormatFromTemplate(template)
        return f
    }

    private static let weekdayNarrow: DateFormatter = {
        let f = DateFormatter()
        f.locale = AppLanguage.activeLocale
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "EEEEE"
        return f
    }()
    private static let shortDate = utcFormatter("dMMM")
    private static let weekdayDate = utcFormatter("EEEdMMM")
    private static let fullDate = utcFormatter("EEEEdMMMM")

    /// "M" for a Monday key.
    static func weekdayInitial(_ day: String) -> String {
        StepsDayKeys.utcMidnight(day).map { weekdayNarrow.string(from: $0) } ?? "·"
    }

    /// "28 Sep" / "Sep 28", per locale.
    static func short(_ day: String) -> String {
        StepsDayKeys.utcMidnight(day).map { shortDate.string(from: $0) } ?? day
    }

    /// "Mon 28 Sep".
    static func weekdayShort(_ day: String) -> String {
        StepsDayKeys.utcMidnight(day).map { weekdayDate.string(from: $0) } ?? day
    }

    /// "Monday 28 September", for VoiceOver.
    static func full(_ day: String) -> String {
        StepsDayKeys.utcMidnight(day).map { fullDate.string(from: $0) } ?? day
    }

    /// "Today", "Yesterday" or "Mon 28 Sep" for `day` relative to `today`.
    static func relative(_ day: String, today: String) -> String {
        if day == today { return String(localized: "Today") }
        if day == StepsDayKeys.adding(-1, to: today) { return String(localized: "Yesterday") }
        return weekdayShort(day)
    }

    /// The clock-hour name for an hour axis tick ("6 AM" or "06"), honouring the Clock format setting. Built
    /// from today's local midnight, so it is the wearer's own clock. The formatter is rebuilt only when the
    /// clock locale changes (the setting, or the system 24-hour switch).
    static func hourTick(_ hour: Int) -> String {
        let locale = AppClock.formattingLocale
        if tickFormatter?.localeId != locale.identifier {
            let f = DateFormatter()
            f.locale = locale
            f.setLocalizedDateFormatFromTemplate("j")
            tickFormatter = (locale.identifier, f)
        }
        return tickFormatter?.formatter.string(from: hourInstant(hour)) ?? String(hour)
    }
    private static var tickFormatter: (localeId: String, formatter: DateFormatter)?

    /// "8:00 AM", for VoiceOver.
    static func hourSpoken(_ hour: Int) -> String { AppClock.hourMinute(hourInstant(hour)) }

    private static func hourInstant(_ hour: Int) -> Date {
        let midnight = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .hour, value: hour, to: midnight) ?? midnight
    }
}

/// Twenty-four clock-hour bars, the current hour drawn at full strength.
struct StepsHourlyBarsView: View {
    let bars: [Int]
    let highlightHour: Int?
    let tint: Color
    var height: CGFloat = 112
    var showsAxis = true

    var body: some View {
        let top = CGFloat(max(bars.max() ?? 0, 1))
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(bars.enumerated()), id: \.offset) { hour, value in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(fill(hour: hour, value: value))
                        .frame(height: value > 0 ? max(3, height * CGFloat(value) / top) : 2)
                        .frame(maxWidth: .infinity)
                        .accessibilityElement()
                        .accessibilityLabel(StepsLabels.hourSpoken(hour))
                        .accessibilityValue(String(localized: "\(StepsFormat.count(value)) steps"))
                }
            }
            .frame(height: height, alignment: .bottom)
            if showsAxis { axis }
        }
        .accessibilityElement(children: .contain)
    }

    private func fill(hour: Int, value: Int) -> Color {
        guard value > 0 else { return StrandPalette.textPrimary.opacity(0.10) }
        return hour == highlightHour ? tint : tint.opacity(0.55)
    }

    /// Ticks at 0, 6, 12 and 18, each centred under its bar.
    private var axis: some View {
        GeometryReader { geo in
            let slot = geo.size.width / CGFloat(max(bars.count, 1))
            ForEach([0, 6, 12, 18], id: \.self) { hour in
                Text(StepsLabels.hourTick(hour))
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize()
                    .position(x: min(max(slot * (CGFloat(hour) + 0.5), 18), geo.size.width - 18), y: 7)
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}

/// Daily bars with a dashed goal line. Days at or over the goal are drawn solid, days under it lighter, an
/// estimated day hollow (its count is approximate), and a day nothing counted as an empty stub, not a zero.
struct StepsDailyBarsView: View {
    enum Labels { case weekdays, sparse }

    let bars: [StepsStats.Bar]
    let goal: Int
    let tint: Color
    let highlightDay: String?
    let labels: Labels
    var height: CGFloat = 128

    /// Width of the leading gutter the goal tag sits in, clear of every bar.
    private static let gutter: CGFloat = 30

    var body: some View {
        let ceiling = CGFloat(StepsStats.chartCeiling(values: bars.compactMap(\.steps), goal: goal))
        let goalFrac = CGFloat(StepGoal.clamp(goal)) / max(ceiling, 1)
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                goalTag(fraction: goalFrac)
                    .frame(width: Self.gutter)
                ZStack(alignment: .bottom) {
                    HStack(alignment: .bottom, spacing: labels == .weekdays ? 10 : 3) {
                        ForEach(bars, id: \.day) { bar in
                            barShape(bar, ceiling: ceiling)
                                .frame(maxWidth: .infinity)
                                .accessibilityElement()
                                .accessibilityLabel(StepsLabels.full(bar.day))
                                .accessibilityValue(accessibilityValue(bar))
                        }
                    }
                    goalLine(fraction: goalFrac)
                }
            }
            .frame(height: height)
            axis.padding(.leading, Self.gutter)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func barShape(_ bar: StepsStats.Bar, ceiling: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: labels == .weekdays ? 5 : 2.5, style: .continuous)
        if let steps = bar.steps, steps > 0 {
            let h = max(3, height * CGFloat(steps) / max(ceiling, 1))
            let met = StepGoal.isMet(steps: steps, goal: goal)
            let strength = bar.day == highlightDay ? 1.0 : (met ? 0.85 : 0.45)
            if bar.source == .strapEstimate {
                shape.fill(tint.opacity(0.16))
                    .overlay(shape.stroke(tint.opacity(strength), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2])))
                    .frame(height: h)
            } else {
                shape.fill(tint.opacity(strength)).frame(height: h)
            }
        } else {
            shape.fill(StrandPalette.textPrimary.opacity(0.08)).frame(height: 2)
        }
    }

    private func goalLine(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            let y = geo.size.height * (1 - min(max(fraction, 0), 1))
            Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: geo.size.width, y: y))
            }
            .stroke(StrandPalette.textSecondary.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The goal's value, level with its line, in the gutter left of the bars.
    private func goalTag(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            let y = geo.size.height * (1 - min(max(fraction, 0), 1))
            Text(StepsFormat.compact(StepGoal.clamp(goal)))
                .font(StrandFont.overline)
                .monospacedDigit()
                .foregroundStyle(StrandPalette.textSecondary)
                .fixedSize()
                .position(x: geo.size.width / 2 - 2, y: min(max(y, 6), geo.size.height - 6))
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var axis: some View {
        switch labels {
        case .weekdays:
            HStack(spacing: 10) {
                ForEach(bars, id: \.day) { bar in
                    Text(StepsLabels.weekdayInitial(bar.day))
                        .font(StrandFont.caption)
                        .fontWeight(bar.day == highlightDay ? .semibold : .regular)
                        .foregroundStyle(bar.day == highlightDay ? StrandPalette.textPrimary : StrandPalette.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
        case .sparse:
            GeometryReader { geo in
                let slot = geo.size.width / CGFloat(max(bars.count, 1))
                let ticks = Self.sparseTicks(count: bars.count)
                ForEach(ticks, id: \.self) { index in
                    Text(StepsLabels.short(bars[index].day))
                        .font(StrandFont.caption)
                        .foregroundStyle(StrandPalette.textTertiary)
                        .fixedSize()
                        .position(x: min(max(slot * (CGFloat(index) + 0.5), 20), geo.size.width - 20), y: 7)
                }
            }
            .frame(height: 14)
            .accessibilityHidden(true)
        }
    }

    /// First, last and two evenly spaced ticks between, for a 30-bar strip.
    static func sparseTicks(count: Int) -> [Int] {
        guard count > 1 else { return count == 1 ? [0] : [] }
        let last = count - 1
        return Array(Set([0, last / 3, (2 * last) / 3, last])).sorted()
    }

    private func accessibilityValue(_ bar: StepsStats.Bar) -> String {
        guard let steps = bar.steps else { return String(localized: "No steps recorded") }
        var parts = [String(localized: "\(StepsFormat.count(steps)) steps")]
        if StepGoal.isMet(steps: steps, goal: goal) { parts.append(String(localized: "goal met")) }
        if let source = bar.source { parts.append(source.displayName) }
        return parts.joined(separator: ", ")
    }
}

/// The compact hourly strip on the Steps card. Decorative: the card carries its own spoken summary.
struct StepsMiniHourlyBars: View {
    let bars: [Int]
    let highlightHour: Int?
    let tint: Color

    var body: some View {
        let top = CGFloat(max(bars.max() ?? 0, 1))
        HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(Array(bars.enumerated()), id: \.offset) { hour, value in
                Capsule(style: .continuous)
                    .fill(value > 0 ? (hour == highlightHour ? tint : tint.opacity(0.5))
                                    : StrandPalette.textPrimary.opacity(0.10))
                    .frame(height: value > 0 ? max(2, 26 * CGFloat(value) / top) : 2)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 26, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// Where a count came from, as a small capsule under the number.
struct StepsSourceBadge: View {
    let source: StepSource

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: source.symbol)
                .font(.system(size: 11, weight: .semibold))
            Text(source.displayName)
                .font(StrandFont.caption.weight(.semibold))
        }
        .foregroundStyle(source.isMeasured ? StrandPalette.textSecondary : StrandPalette.statusWarning)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule(style: .continuous).fill(StrandPalette.textPrimary.opacity(0.07)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Source: \(source.displayName)"))
        .accessibilityHint(source.explanation)
    }
}
