#if os(iOS)
import SwiftUI
import UIKit
import StrandAnalytics

// MARK: - Year in Review slides (WHOOP_UI_SPEC §3.39)
//
// WHOOP's story, slide for slide where ZENO has the data, and the wearer's own figures wherever WHOOP
// compares with other members: the month highlight (a month ruler with an orb on the month, a framed badge,
// the highlight's name and a sentence), the pillar top performer, behaviour impacts on Recovery, steps
// with the Everest equivalence, the persona card and the summary share card. A slide only appears when its
// data exists; under two weeks of data there is one honest slide instead.

/// The year's highlight days.
enum YearReviewMoment: Hashable {
    case longestSleep, peakRecovery, maxStrain
}

enum YearReviewSlide: Hashable {
    case intro
    case moment(YearReviewMoment)
    case pillar
    case behaviors
    case steps
    case persona
    case summary
    /// Under two weeks of data: what is missing, instead of a thin story.
    case notEnough

    /// The slides this year's data supports, in WHOOP's order.
    static func slides(for s: YearInReviewSnapshot) -> [YearReviewSlide] {
        let sum = s.summary
        guard sum.hasStory else { return [.notEnough] }
        var out: [YearReviewSlide] = [.intro]
        if sum.longestSleep != nil { out.append(.moment(.longestSleep)) }
        if sum.peakRecovery != nil { out.append(.moment(.peakRecovery)) }
        if sum.maxStrain != nil { out.append(.moment(.maxStrain)) }
        if sum.bestPillar != nil { out.append(.pillar) }
        if !s.behaviors.isEmpty { out.append(.behaviors) }
        if (sum.steps ?? 0) > 0 { out.append(.steps) }
        out.append(.persona)
        out.append(.summary)
        return out
    }

    /// The colour rising from the slide's foot.
    func glow(_ s: YearInReviewSnapshot) -> Color {
        typealias S = PulseExtrasTheme.Story
        switch self {
        case .intro, .summary, .notEnough: return S.glowIndigo
        case .moment(.longestSleep): return S.glowIndigo
        case .moment(.peakRecovery):
            switch s.summary.peakRecovery.map({ PulseDisplay.recoveryBand(percent: $0.value) }) {
            case .green?: return S.glowGreen
            case .red?: return S.glowRed
            default: return S.glowIndigo
            }
        case .moment(.maxStrain): return S.glowBlue
        case .pillar:
            switch s.summary.bestPillar {
            case .recovery?: return S.glowGreen
            case .strain?: return S.glowBlue
            default: return S.glowIndigo
            }
        case .behaviors: return S.glowSlate
        case .steps: return S.glowBlue
        case .persona: return YearReviewPersona(s.summary.persona).glow
        }
    }
}

/// One slide.
struct YearReviewSlideView: View {
    let slide: YearReviewSlide
    let snapshot: YearInReviewSnapshot

    var body: some View {
        switch slide {
        case .intro: YearReviewIntroSlide(snapshot: snapshot)
        case .moment(let moment): YearReviewMomentSlide(content: YearReviewMomentContent(moment, snapshot))
        case .pillar: YearReviewPillarSlide(snapshot: snapshot)
        case .behaviors: YearReviewBehaviorsSlide(snapshot: snapshot)
        case .steps: YearReviewStepsSlide(snapshot: snapshot)
        case .persona: YearReviewPersonaSlide(snapshot: snapshot)
        case .summary: YearReviewSummarySlide(snapshot: snapshot)
        case .notEnough: YearReviewNotEnoughSlide(snapshot: snapshot)
        }
    }
}

// MARK: - Formatting

/// Day keys are formatted at UTC (they name a civil day); counts and durations as everywhere in Pulse.
enum YearReviewFormat {
    /// "February".
    static func month(_ dayKey: String) -> String { PulseFormat.dayLabel(dayKey, template: "MMMM") }
    /// "Sat, Feb 22".
    static func weekdayDate(_ dayKey: String) -> String { PulseFormat.navDayTitle(dayKey: dayKey) }
    /// "Feb 22".
    static func shortDate(_ dayKey: String) -> String { PulseFormat.dayLabel(dayKey, template: "MMMd") }
    /// "22nd".
    static func ordinalDay(_ dayKey: String) -> String {
        let day = Int(dayKey.suffix(2)) ?? 1
        return ordinal.string(from: NSNumber(value: day)) ?? "\(day)"
    }
    /// The month's index, 0 for January.
    static func monthIndex(_ dayKey: String) -> Int {
        let parts = dayKey.split(separator: "-")
        guard parts.count == 3, let m = Int(parts[1]) else { return 0 }
        return min(11, max(0, m - 1))
    }
    /// The day within its month as a fraction, for the ruler.
    static func dayFraction(_ dayKey: String) -> Double {
        let day = Double(Int(dayKey.suffix(2)) ?? 1)
        return (day - 0.5) / 31
    }
    /// "808.7k", "1.4M", "9,214".
    static func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", locale: AppLanguage.activeLocale, Double(n) / 1_000_000) }
        if n >= 10_000 { return String(format: "%.1fk", locale: AppLanguage.activeLocale, Double(n) / 1_000) }
        return PulseFormat.grouped(Double(n))
    }
    /// A whole percent of a share: "62%".
    static func percent(_ share: Double) -> String { "\(Int((share * 100).rounded()))%" }

    private static let ordinal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        f.locale = AppLanguage.activeLocale
        return f
    }()
}

/// A slide's foot sentence: 22 pt Medium, left-aligned at the page margin (/10: caps 15.7 pt on a 29.4 pt
/// pitch).
private struct YearReviewSentence: View {
    let text: String

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        Text(text)
            .extrasFont(S.sentenceSize, weight: .medium, relativeTo: .title2)
            .foregroundStyle(PulseTheme.textPrimary)
            .multilineTextAlignment(.leading)
            .lineSpacing(S.sentenceLineSpacing)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, S.sentenceMargin)
    }
}

// MARK: - Intro

/// How many days the strap scored this year, and over what span.
private struct YearReviewIntroSlide: View {
    let snapshot: YearInReviewSnapshot

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        let sum = snapshot.summary
        VStack(spacing: 0) {
            Spacer(minLength: 24)
            Text(snapshot.isPartial ? String(localized: "Your \(String(snapshot.year)) so far")
                                    : String(localized: "Your \(String(snapshot.year))"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
            Text(verbatim: "\(sum.trackedDays)")
                .font(PulseType.numeral(S.bigNumberSize))
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 6)
            Text(String(localized: "days tracked"))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
            Text(spanText)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
                .padding(.top, 6)
            HStack(alignment: .top, spacing: 0) {
                stat(String(localized: "Nights"), sum.nights)
                stat(String(localized: "Recoveries"), sum.recoveries)
                stat(String(localized: "Activities"), sum.activities)
            }
            .padding(.top, 40)
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            Spacer(minLength: 24)
            YearReviewSentence(text: sentence)
        }
    }

    /// "Jan 1 – Oct 3", from the first day the strap scored when that is later than 1 January.
    private var spanText: String {
        let first = snapshot.summary.firstTrackedDay ?? snapshot.through
        let start = max(first, String(format: "%04d-01-01", snapshot.year))
        return "\(YearReviewFormat.shortDate(start)) – \(YearReviewFormat.shortDate(snapshot.through))"
    }

    private var sentence: String {
        snapshot.isPartial
            ? String(localized: "Here's your year so far, read from your own data on this iPhone.")
            : String(localized: "Here's your year, read from your own data on this iPhone.")
    }

    private func stat(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: PulseFormat.grouped(Double(value)))
                .pulseText(.tileValue)
                .foregroundStyle(PulseTheme.textPrimary)
            PulseLabel(title, color: PulseTheme.textTertiary, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Moments

/// What a highlight slide shows.
struct YearReviewMomentContent {
    let dayKey: String
    let title: String
    let value: String
    let unit: String?
    let color: Color
    let symbol: String
    /// The wearer's own average, where WHOOP printed "43% of members achieved this".
    let caption: String?
    let sentence: String

    init(_ moment: YearReviewMoment, _ s: YearInReviewSnapshot) {
        let sum = s.summary
        switch moment {
        case .longestSleep:
            let m = sum.longestSleep ?? YearInReview.Moment(day: s.through, value: 0)
            dayKey = m.day
            title = String(localized: "Longest Sleep")
            value = PulseFormat.hoursMinutes(m.value)
            unit = String(localized: "hr")
            color = PulseTheme.sleep
            symbol = "moon.fill"
            caption = sum.averageAsleepMinutes.map {
                String(localized: "Your average night: \(PulseFormat.hoursMinutes($0))")
            }
            sentence = String(localized: "\(YearReviewFormat.month(m.day)) brought your longest sleep: \(PulseSnapshotBuilder.spokenDuration(minutes: m.value)) on the \(YearReviewFormat.ordinalDay(m.day)).")
        case .peakRecovery:
            let m = sum.peakRecovery ?? YearInReview.Moment(day: s.through, value: 0)
            let pct = PulseDisplay.displayedPercent(m.value)
            dayKey = m.day
            title = String(localized: "Peak Recovery")
            value = "\(pct)"
            unit = "%"
            color = PulseTheme.recovery(percent: m.value)
            symbol = "heart.fill"
            caption = sum.averageRecovery.map {
                String(localized: "Your average Recovery: \(PulseDisplay.displayedPercent($0))%")
            }
            sentence = String(localized: "\(YearReviewFormat.month(m.day)) brought your highest Recovery: \(pct)% on the \(YearReviewFormat.ordinalDay(m.day)).")
        case .maxStrain:
            let m = sum.maxStrain ?? YearInReview.Moment(day: s.through, value: 0)
            dayKey = m.day
            title = String(localized: "Max Strain")
            value = PulseFormat.oneDecimal(m.value)
            unit = nil
            color = PulseTheme.strain
            symbol = "flame.fill"
            caption = sum.averageStrain.map {
                String(localized: "Your average day: \(PulseFormat.oneDecimal($0)) Strain")
            }
            sentence = String(localized: "\(YearReviewFormat.month(m.day)) brought your biggest day: \(PulseFormat.oneDecimal(m.value)) Strain on the \(YearReviewFormat.ordinalDay(m.day)).")
        }
    }
}

/// The month highlight (completeness-critic/10, profile-community-2026/52): the month ruler with its orb,
/// the month and date, the framed badge (ZENO's: the value under the pillar's glyph), the highlight's
/// name, the wearer's own average, and the sentence.
private struct YearReviewMomentSlide: View {
    let content: YearReviewMomentContent

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        VStack(spacing: 0) {
            YearReviewMonthRuler(dayKey: content.dayKey, color: content.color)
                .padding(.top, 64)
            Text(YearReviewFormat.month(content.dayKey))
                .pulseText(.cardHeadline)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 14)
            Text(YearReviewFormat.weekdayDate(content.dayKey))
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .padding(.top, 2)
            YearReviewBadgeFrame(color: content.color) {
                VStack(spacing: 6) {
                    Image(systemName: content.symbol)
                        .font(.system(size: S.momentGlyphSize, weight: .regular))
                        .foregroundStyle(content.color)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(content.value)
                            .font(PulseType.numeral(S.momentValueSize))
                            .foregroundStyle(PulseTheme.textPrimary)
                        if let unit = content.unit {
                            Text(unit)
                                .font(PulseType.numeral(S.momentValueSize * S.momentUnitScale))
                                .foregroundStyle(PulseTheme.textSecondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
                .padding(.bottom, 26)
            }
            .padding(.top, 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: [content.title, content.value + (content.unit ?? "")].joined(separator: ", ")))
            Text(content.title)
                .extrasFont(S.titleSize, weight: .medium, relativeTo: .title2)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 40)
            if let caption = content.caption {
                Text(caption)
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.top, 10)
            }
            Spacer(minLength: 16)
            YearReviewSentence(text: content.sentence)
        }
    }
}

/// A comb of day ticks across the screen, taller at each month's start, with the orb on the highlight's
/// day at the centre (WHOOP's scrubber; the orb is ZENO's plain ring).
private struct YearReviewMonthRuler: View {
    let dayKey: String
    let color: Color

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        Canvas { context, size in
            let centre = size.width / 2
            let monthWidth = S.rulerMonthWidth
            let ticksPerMonth = S.rulerTicksPerMonth
            let step = monthWidth / CGFloat(ticksPerMonth)
            let month = YearReviewFormat.monthIndex(dayKey)
            // The highlight's day sits at the centre; the year's 12 months run either side of it.
            let yearStart = centre - (CGFloat(month) + CGFloat(YearReviewFormat.dayFraction(dayKey))) * monthWidth
            for m in 0..<12 {
                for t in 0..<ticksPerMonth {
                    let x = yearStart + CGFloat(m) * monthWidth + CGFloat(t) * step
                    guard x > -2, x < size.width + 2, abs(x - centre) > S.orbSize / 2 + 3 else { continue }
                    let major = t == 0
                    let h = major ? S.rulerMajorTickHeight : S.rulerTickHeight
                    let rect = CGRect(x: x - 0.5, y: (size.height - h) / 2, width: 1, height: h)
                    context.fill(Path(rect), with: .color(major ? S.rulerMajorTick : S.rulerTick))
                }
            }
            let orb = CGRect(x: centre - S.orbSize / 2, y: (size.height - S.orbSize) / 2,
                             width: S.orbSize, height: S.orbSize)
            context.fill(Path(ellipseIn: orb), with: .color(S.orbFill))
            context.stroke(Path(ellipseIn: orb.insetBy(dx: 2, dy: 2)), with: .color(S.orbRing), lineWidth: 2)
            let dot = CGRect(x: centre - S.orbDot / 2, y: (size.height - S.orbDot) / 2, width: S.orbDot,
                             height: S.orbDot)
            context.fill(Path(ellipseIn: dot), with: .color(color))
        }
        .frame(height: S.orbSize + 4)
        .accessibilityHidden(true)
    }
}

/// The badge frame: an inset card darker than the page with a top-lit rim and, inside it, a shield stroked in
/// the highlight's colour (rounded top, a deep round foot), brightening toward its lower right, as WHOOP
/// frames its badge art (completeness-critic/10).
private struct YearReviewBadgeFrame<Content: View>: View {
    let color: Color
    @ViewBuilder var content: () -> Content

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        let outer = UnevenRoundedRectangle(topLeadingRadius: S.cardTopRadius, bottomLeadingRadius: S.cardBottomRadius,
                                           bottomTrailingRadius: S.cardBottomRadius, topTrailingRadius: S.cardTopRadius,
                                           style: .continuous)
        let inner = UnevenRoundedRectangle(topLeadingRadius: S.cardTopRadius - S.shieldTopRadiusInset,
                                           bottomLeadingRadius: S.cardBottomRadius - S.shieldInset,
                                           bottomTrailingRadius: S.cardBottomRadius - S.shieldInset,
                                           topTrailingRadius: S.cardTopRadius - S.shieldTopRadiusInset,
                                           style: .continuous)
        ZStack {
            outer.fill(S.cardFill)
            outer.strokeBorder(YearReviewRim.frame, lineWidth: 1)
            inner
                .strokeBorder(YearReviewRim.badge(color), lineWidth: S.shieldStroke)
                .padding(S.shieldInset)
            content()
        }
        .frame(width: S.cardSize.width, height: S.cardSize.height)
    }
}

/// The badges' two strokes: the frame's rim, lit from the top, and the badge's own, in its colour at the top
/// left lightening ≈35% toward white at the lower right (/10: #EA150F at the top, #FF5579 at the foot).
enum YearReviewRim {
    private typealias S = PulseExtrasTheme.Story

    static var frame: LinearGradient {
        LinearGradient(colors: [S.cardRimTop, S.cardRimBottom], startPoint: .top, endPoint: .bottom)
    }

    static func badge(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color.extrasBlend(toward: .white, by: S.rimWhiteMix)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Pillar

/// The pillar top performer (profile-community-2026/45, 46): ZENO's strongest pillar, by how often it
/// reached its optimal mark, with the other two beside it (WHOOP's "Top 2%" is population data).
private struct YearReviewPillarSlide: View {
    let snapshot: YearInReviewSnapshot

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        let sum = snapshot.summary
        let best = sum.bestPillarScore
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            if let best {
                ZStack {
                    YearReviewHexagon(cornerRadius: S.hexCornerRadius)
                        .fill(S.cardFill)
                    YearReviewHexagon(cornerRadius: S.hexCornerRadius)
                        .strokeBorder(YearReviewRim.frame, lineWidth: 1)
                    YearReviewHexagon(cornerRadius: S.hexInnerCornerRadius)
                        .inset(by: S.hexInset)
                        .strokeBorder(YearReviewRim.badge(Self.color(best.pillar)), lineWidth: S.hexStroke)
                    PulseRing(fraction: best.share, color: Self.color(best.pillar), diameter: S.pillarRing,
                              thickness: S.pillarRingStroke)
                    VStack(spacing: 2) {
                        Image(systemName: Self.symbol(best.pillar))
                            .font(.system(size: S.pillarGlyphSize, weight: .regular))
                            .foregroundStyle(Self.color(best.pillar))
                        Text(YearReviewFormat.percent(best.share))
                            .font(PulseType.numeral(S.pillarValueSize))
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                }
                .frame(width: S.hexFrame.width, height: S.hexFrame.height)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "\(Self.name(best.pillar)), \(YearReviewFormat.percent(best.share)) \(Self.markCaption(best.pillar))"))
                Text(Self.name(best.pillar))
                    .extrasFont(S.titleSize, weight: .medium, relativeTo: .title2)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.top, 24)
                Text(String(localized: "Your strongest pillar in \(String(snapshot.year))"))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.top, 6)
                others(sum, best: best.pillar)
                    .padding(.top, 22)
            }
            Spacer(minLength: 16)
            if let best { YearReviewSentence(text: Self.sentence(best)) }
        }
    }

    /// The other two pillars' marks, divided by a hairline (where WHOOP shows the avatar and "Top 2%").
    private func others(_ sum: YearInReview.Summary, best: YearInReview.Pillar) -> some View {
        let rest = sum.pillars.filter { $0.pillar != best }
        return HStack(spacing: 0) {
            ForEach(Array(rest.enumerated()), id: \.element.pillar) { i, score in
                if i > 0 {
                    Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 40)
                }
                VStack(spacing: 3) {
                    Text(YearReviewFormat.percent(score.share))
                        .pulseText(.rowValue)
                        .foregroundStyle(Self.color(score.pillar))
                    Text(Self.markCaption(score.pillar))
                        .pulseText(.legend)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 150)
                .accessibilityElement(children: .combine)
            }
        }
    }

    static func name(_ p: YearInReview.Pillar) -> String {
        switch p {
        case .sleep: return PulseScore.sleep.displayName
        case .recovery: return PulseScore.recovery.displayName
        case .strain: return PulseScore.strain.displayName
        }
    }

    static func color(_ p: YearInReview.Pillar) -> Color {
        switch p {
        case .sleep: return PulseTheme.sleep
        case .recovery: return PulseTheme.recoveryHigh
        case .strain: return PulseTheme.strain
        }
    }

    static func symbol(_ p: YearInReview.Pillar) -> String {
        switch p {
        case .sleep: return PulseScore.sleep.symbol
        case .recovery: return PulseScore.recovery.symbol
        case .strain: return PulseScore.strain.symbol
        }
    }

    /// What the percentage counts.
    static func markCaption(_ p: YearInReview.Pillar) -> String {
        switch p {
        case .sleep: return String(localized: "of nights Optimal")
        case .recovery: return String(localized: "of days green")
        case .strain: return String(localized: "of days in range")
        }
    }

    static func sentence(_ score: YearInReview.PillarScore) -> String {
        let pct = YearReviewFormat.percent(score.share)
        switch score.pillar {
        case .sleep:
            return String(localized: "\(pct) of your nights reached Optimal: 85% Sleep performance or better.")
        case .recovery:
            return String(localized: "Your Recovery was green on \(pct) of your days.")
        case .strain:
            return String(localized: "On \(pct) of days your Strain landed in the range your Recovery called for.")
        }
    }
}

/// A pointy-topped hexagon with rounded corners (WHOOP's pillar badge outline, /45), insettable for the
/// inner stroke.
struct YearReviewHexagon: InsettableShape {
    var cornerRadius: CGFloat = 0
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let radius = min(r.width / sqrt(3), r.height / 2)
        let c = CGPoint(x: r.midX, y: r.midY)
        let corners = (0..<6).map { i -> CGPoint in
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            return CGPoint(x: c.x + radius * cos(angle), y: c.y + radius * sin(angle))
        }
        var p = Path()
        // Start halfway along the last edge, then round each corner on the way round.
        p.move(to: CGPoint(x: (corners[5].x + corners[0].x) / 2, y: (corners[5].y + corners[0].y) / 2))
        for i in 0..<6 {
            p.addArc(tangent1End: corners[i], tangent2End: corners[(i + 1) % 6], radius: cornerRadius)
        }
        p.closeSubpath()
        return p
    }

    func inset(by amount: CGFloat) -> YearReviewHexagon {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

// MARK: - Behaviours

/// Behaviour impacts on Recovery (completeness-critic/11): bars from the left edge, teal for higher
/// Recovery and orange for lower, the larger effects longer, taller and brighter; the percent at the right.
private struct YearReviewBehaviorsSlide: View {
    let snapshot: YearInReviewSnapshot

    private typealias S = PulseExtrasTheme.Story

    /// The ranker's top six, set out as WHOOP's slide sets them (completeness-critic/11): what helped
    /// first, largest first, then what hurt, largest drop first.
    private var rows: [YearReviewBehavior] {
        let top = snapshot.behaviors.prefix(S.behaviorRows)
        return top.filter { $0.percent >= 0 }.sorted { $0.percent > $1.percent }
            + top.filter { $0.percent < 0 }.sorted { $0.percent < $1.percent }
    }

    var body: some View {
        let largest = rows.map { abs($0.percent) }.max() ?? 1
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "Behavior impacts on Recovery"))
                .extrasFont(S.headlineSize, weight: .semibold, relativeTo: .title)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .accessibilityAddTraits(.isHeader)
            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(rows) { row in
                        bar(row, largest: largest, width: geo.size.width)
                    }
                }
            }
            .frame(height: barsHeight(largest: largest))
            .padding(.top, 28)
            Text(footnote)
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .padding(.top, 18)
            Spacer(minLength: 0)
        }
    }

    private func height(_ row: YearReviewBehavior, largest: Double) -> CGFloat {
        abs(row.percent) >= largest * 0.5 ? S.barTall : S.barShort
    }

    private func barsHeight(largest: Double) -> CGFloat {
        rows.reduce(0) { $0 + height($1, largest: largest) } + CGFloat(max(0, rows.count - 1)) * 4
    }

    private func bar(_ row: YearReviewBehavior, largest: Double, width: CGFloat) -> some View {
        let magnitude = largest > 0 ? abs(row.percent) / largest : 0
        let hue = row.percent >= 0 ? PulseTheme.positive : PulseTheme.negative
        // The largest effect is brightest; a result the ranker did not flag significant stays faint.
        let strength = row.significant ? 0.35 + 0.65 * magnitude : 0.22
        let barWidth = width * CGFloat(S.barMinimumWidth + (1 - S.barMinimumWidth) * magnitude)
        let value = "\(row.percent >= 0 ? "+" : "")\(Int(row.percent.rounded()))%"
        return ZStack(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: S.barRadius,
                                   topTrailingRadius: S.barRadius, style: .continuous)
                .fill(hue.opacity(strength))
                .frame(width: barWidth)
            HStack {
                Text(row.title)
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textPrimary.opacity(row.significant ? 1 : 0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 12)
                Text(value)
                    .font(PulseType.numeral(S.barValueSize))
                    .foregroundStyle(PulseTheme.textPrimary.opacity(row.significant ? 1 : 0.7))
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
        }
        .frame(width: width, height: height(row, largest: largest), alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.percent >= 0
            ? String(localized: "\(row.title): Recovery \(Int(abs(row.percent).rounded())) percent higher on days you logged it")
            : String(localized: "\(row.title): Recovery \(Int(abs(row.percent).rounded())) percent lower on days you logged it"))
        .accessibilityValue(row.significant ? String(localized: "A clear difference")
                                            : String(localized: "Not a clear difference yet"))
    }

    private var footnote: String {
        let faint = rows.contains { !$0.significant }
        let base = String(localized: "Your Recovery on days you logged each behavior against days you logged no, in \(String(snapshot.year)). Each needs 5 days of both.")
        return faint ? base + " " + String(localized: "Faint bars are not a clear difference yet.") : base
    }
}

// MARK: - Steps

/// Steps with the Everest equivalence (profile-community-2026/50): the total in big blue numerals over a
/// mountain, and the sentence.
private struct YearReviewStepsSlide: View {
    let snapshot: YearInReviewSnapshot

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        let steps = snapshot.summary.steps ?? 0
        let climbs = YearInReview.everestClimbs(steps: steps)
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                Text(verbatim: YearReviewFormat.compact(steps))
                    .font(PulseType.numeral(S.stepsNumberSize, weight: .heavy))
                    .foregroundStyle(LinearGradient(colors: [S.stepsTop, S.stepsBottom], startPoint: .top,
                                                    endPoint: .bottom))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 12)
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: S.mountainSize, weight: .regular))
                    .foregroundStyle(S.mountain)
                    .padding(.top, 70)
            }
            .padding(.top, 60)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "\(PulseFormat.grouped(Double(steps))) steps"))
            Spacer(minLength: 16)
            YearReviewSentence(text: sentence(steps: steps, climbs: climbs))
        }
    }

    private func sentence(steps: Int, climbs: Double) -> String {
        let count = PulseFormat.grouped(Double(steps))
        let times = climbs >= 10 ? "\(Int(climbs.rounded()))" : PulseFormat.oneDecimal(climbs)
        if climbs >= 1 {
            return String(localized: "You logged \(count) steps. Counted as 16 cm stairs, that's Everest \(times) times over.")
        }
        return String(localized: "You logged \(count) steps. Counted as 16 cm stairs, that's \(Int((climbs * 100).rounded()))% of the way up Everest.")
    }
}

// MARK: - Persona

/// The year's persona, ZENO's own titles and colours.
struct YearReviewPersona {
    let kind: YearInReview.Persona

    init(_ kind: YearInReview.Persona) { self.kind = kind }

    private typealias S = PulseExtrasTheme.Story

    var title: String {
        switch kind {
        case .groundwork: return String(localized: "Laid the Groundwork")
        case .consistency: return String(localized: "Never Missed a Beat")
        case .sleep: return String(localized: "Made Sleep a Priority")
        case .recovery: return String(localized: "Kept the Tank Full")
        case .strain: return String(localized: "Chased the Hard Days")
        }
    }

    var color: Color {
        switch kind {
        case .groundwork: return PulseTheme.recoveryBlue
        case .consistency: return S.personaPurple
        case .sleep: return PulseTheme.sleep
        case .recovery: return S.personaGreen
        case .strain: return PulseTheme.strain
        }
    }

    var glow: Color {
        switch kind {
        case .groundwork, .sleep: return S.glowIndigo
        case .consistency: return S.glowPurple
        case .recovery: return S.glowGreen
        case .strain: return S.glowBlue
        }
    }
}

/// The persona card (profile-community-2026/47–49): "The Year You", the persona in its colour, a paragraph
/// written from the year's own figures by fixed templates (no language model), and the lock-up at the foot.
private struct YearReviewPersonaSlide: View {
    let snapshot: YearInReviewSnapshot

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        let persona = YearReviewPersona(snapshot.summary.persona)
        VStack {
            Spacer(minLength: 12)
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "The Year You"))
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                Text(persona.title)
                    .extrasFont(S.personaTitleSize, weight: .bold, relativeTo: .title2)
                    .tracking(S.personaTitleTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(persona.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                Text(paragraph)
                    .extrasFont(S.personaParagraphSize, weight: .regular, relativeTo: .body)
                    .foregroundStyle(PulseTheme.textButton)
                    .lineSpacing(S.personaLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            .padding(.top, S.personaTextTop)
            .padding(.horizontal, S.personaTextSide)
            .padding(.bottom, S.personaFootReserve)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: S.personaCardHeight, alignment: .topLeading)
            .overlay(alignment: .bottom) {
                HStack(alignment: .lastTextBaseline) {
                    PulseZenoWordmark(width: S.personaWordmark.width, height: S.personaWordmark.height)
                    Spacer()
                    Text(verbatim: String(snapshot.year))
                        .font(.system(size: S.yearSize, weight: .bold).italic())
                        .foregroundStyle(PulseTheme.textPrimary)
                }
                .padding(.horizontal, S.personaTextSide)
                .padding(.bottom, 24)
                .accessibilityHidden(true)
            }
            .background {
                RoundedRectangle(cornerRadius: S.personaCardRadius, style: .continuous)
                    .fill(S.personaCardFill)
                    .overlay {
                        RadialGradient(colors: [persona.glow.opacity(S.personaGlowStrength), persona.glow.opacity(0)],
                                       center: UnitPoint(x: 0.3, y: 0.85), startRadius: 0,
                                       endRadius: S.personaGlowRadius)
                            .clipShape(RoundedRectangle(cornerRadius: S.personaCardRadius, style: .continuous))
                    }
                    .overlay(alignment: .bottom) {
                        YearReviewWaves()
                            .stroke(S.personaWave, lineWidth: 1)
                            .frame(height: S.personaWaveHeight)
                            .clipShape(RoundedRectangle(cornerRadius: S.personaCardRadius, style: .continuous))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: S.personaCardRadius, style: .continuous)
                            .strokeBorder(S.personaCardRim, lineWidth: 1)
                    }
            }
            .padding(.horizontal, S.personaCardMargin)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 12)
        }
    }

    private var paragraph: String {
        let s = snapshot.summary
        let year = String(snapshot.year)
        var parts: [String] = []
        parts.append(snapshot.isPartial
                     ? String(localized: "You wore your strap on \(s.trackedDays) days of \(year) so far.")
                     : String(localized: "You wore your strap on \(s.trackedDays) days of \(year)."))
        if let avg = s.averageAsleepMinutes, s.nights > 0 {
            parts.append(String(localized: "You banked \(s.nights) nights of sleep at \(PulseFormat.duration(minutes: avg)) a night."))
        }
        if let peak = s.peakRecovery {
            parts.append(String(localized: "Your Recovery peaked at \(PulseDisplay.displayedPercent(peak.value))% in \(YearReviewFormat.month(peak.day))."))
        }
        if let max = s.maxStrain {
            parts.append(String(localized: "Your biggest day reached \(PulseFormat.oneDecimal(max.value)) Strain."))
        }
        let share = s.bestPillarScore.map { YearReviewFormat.percent($0.share) } ?? ""
        switch s.persona {
        case .sleep:
            parts.append(String(localized: "Sleep led the way: \(share) of your nights reached Optimal."))
        case .recovery:
            parts.append(String(localized: "You kept your Recovery green on \(share) of your days."))
        case .strain:
            parts.append(String(localized: "Your Strain matched what your Recovery called for on \(share) of days."))
        case .consistency:
            parts.append(String(localized: "You showed up on \(YearReviewFormat.percent(s.coverage)) of the days, and that is the habit everything else is built on."))
        case .groundwork:
            parts.append(String(localized: "The base you built this year sets up everything that follows."))
        }
        return parts.joined(separator: " ")
    }
}

/// Faint wavy lines across the foot of the persona card.
private struct YearReviewWaves: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let waves = 14
        for i in 0..<waves {
            let x0 = rect.minX + CGFloat(i) * rect.width / CGFloat(waves - 1)
            p.move(to: CGPoint(x: x0, y: rect.maxY))
            p.addCurve(to: CGPoint(x: x0 + 6, y: rect.minY),
                       control1: CGPoint(x: x0 + 14, y: rect.maxY - rect.height * 0.35),
                       control2: CGPoint(x: x0 - 8, y: rect.minY + rect.height * 0.35))
        }
        return p
    }
}

// MARK: - Summary

/// The summary share card (completeness-critic/09) and SHARE.
private struct YearReviewSummarySlide: View {
    let snapshot: YearInReviewSnapshot

    @EnvironmentObject private var profile: ProfileStore
    @State private var sharing = false

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                YearReviewSummaryCard(snapshot: snapshot, chronologicalAge: profile.age)
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.top, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            Button {
                share()
            } label: {
                Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.pulseFilledWhite)
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.top, 12)
            .disabled(sharing)
        }
    }

    /// Render the card on its page and offer it through the share sheet. The view is rendered here
    /// (ImageRenderer needs the main actor); the PNG is encoded and written off it, then the sheet is
    /// presented back on it.
    private func share() {
        guard !sharing else { return }
        sharing = true
        let card = YearReviewSummaryCard(snapshot: snapshot, chronologicalAge: profile.age)
            .padding(PulseTheme.Layout.pageMargin)
            .frame(width: S.shareWidth)
            .background(YearReviewBackground(glow: S.glowIndigo))
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: card)
        renderer.scale = S.shareScale
        guard let image = renderer.uiImage else {
            sharing = false
            return
        }
        let name = "ZENO-\(String(snapshot.year))-Year-in-Review.png"
        Task {
            let url = await Task.detached(priority: .userInitiated) { () -> URL? in
                guard let data = image.pngData() else { return nil }
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
                do { try data.write(to: url, options: .atomic) } catch { return nil }
                return url
            }.value
            sharing = false
            if let url { PulseExtrasShareSheet.present(url) }
        }
    }
}

/// The card WHOOP members share: the lock-up with ZENO Age at its right, days tracked and the longest
/// streak, the three best days as rings with their dates, and the longest sleep, lowest Recovery and top
/// activity.
struct YearReviewSummaryCard: View {
    let snapshot: YearInReviewSnapshot
    /// The wearer's age in years, to say how far ZENO Age sits from it.
    let chronologicalAge: Int?

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        let s = snapshot.summary
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    YearReviewLockup(year: snapshot.year)
                    Text(snapshot.isPartial ? String(localized: "Year in Review, so far") : String(localized: "Year in Review"))
                        .pulseText(.cardHeadline)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let age = snapshot.zenoAge {
                    YearReviewAgeBadge(zenoAge: age, chronologicalAge: chronologicalAge)
                }
            }
            HStack(spacing: 0) {
                headline(symbol: "calendar", title: String(localized: "Days tracked"),
                         value: PulseChallengeText.inflected("^[\(s.trackedDays) day](inflect: true)"))
                Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 36)
                headline(symbol: "flame.fill", title: String(localized: "Longest streak"),
                         value: PulseChallengeText.inflected("^[\(s.longestStreak) day](inflect: true)"))
                    .padding(.leading, 16)
            }
            HStack(alignment: .top, spacing: 0) {
                ring(title: String(localized: "Best Sleep"), moment: s.bestSleep, color: PulseTheme.sleep,
                     fraction: { $0 / 100 }, text: { "\(PulseDisplay.displayedPercent($0))" }, unit: "%")
                ring(title: String(localized: "Peak Recovery"), moment: s.peakRecovery,
                     color: s.peakRecovery.map { PulseTheme.recovery(percent: $0.value) } ?? PulseTheme.recoveryHigh,
                     fraction: { $0 / 100 }, text: { "\(PulseDisplay.displayedPercent($0))" }, unit: "%")
                ring(title: String(localized: "Max Strain"), moment: s.maxStrain, color: PulseTheme.strain,
                     fraction: { $0 / 21 }, text: { PulseFormat.oneDecimal($0) }, unit: nil)
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: S.summaryCardRadius, style: .continuous).fill(S.summaryCard))
            .overlay(RoundedRectangle(cornerRadius: S.summaryCardRadius, style: .continuous)
                .strokeBorder(PulseTheme.divider, lineWidth: 1))
            VStack(spacing: 10) {
                if let m = s.longestSleep {
                    row(symbol: "moon.stars.fill", title: String(localized: "Longest Sleep"),
                        detail: YearReviewFormat.shortDate(m.day), value: PulseFormat.hoursMinutes(m.value),
                        unit: String(localized: "hr"))
                }
                if let m = s.lowestRecovery {
                    row(symbol: "heart.slash.fill", title: String(localized: "Lowest Recovery"),
                        detail: YearReviewFormat.shortDate(m.day), value: "\(PulseDisplay.displayedPercent(m.value))",
                        unit: "%")
                }
                if let top = s.topActivity {
                    row(symbol: snapshot.topActivitySymbol ?? "figure.run", title: String(localized: "Top Activity"),
                        detail: top.name, value: PulseFormat.grouped(Double(top.count)), unit: "x", detailFirst: true)
                }
            }
        }
    }

    private func headline(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: S.summaryGlyphSize, weight: .regular))
                .foregroundStyle(S.summaryRowIcon)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).pulseText(.label).foregroundStyle(PulseTheme.textPrimary)
                Text(value).pulseText(.subtitle).foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func ring(title: String, moment: YearInReview.Moment?, color: Color, fraction: (Double) -> Double,
                      text: (Double) -> String, unit: String?) -> some View {
        VStack(spacing: 6) {
            ZStack {
                PulseRing(fraction: moment.map { fraction($0.value) } ?? 0, color: color, diameter: S.summaryRing,
                          thickness: S.summaryRingStroke)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(moment.map { text($0.value) } ?? "--")
                        .font(PulseType.font(.mediumValue))
                        .foregroundStyle(PulseTheme.textPrimary)
                    if let unit, moment != nil {
                        Text(unit).font(PulseType.numeral(S.summaryUnitSize)).foregroundStyle(PulseTheme.textPrimary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, S.summaryRingStroke + 2)
            }
            .frame(width: S.summaryRing, height: S.summaryRing)
            Text(title)
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(moment.map { YearReviewFormat.shortDate($0.day) } ?? " ")
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func row(symbol: String, title: String, detail: String, value: String, unit: String,
                     detailFirst: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: S.summaryGlyphSize, weight: .regular))
                .foregroundStyle(S.summaryRowIcon)
                .frame(width: S.summaryGlyphFrame, height: S.summaryGlyphFrame)
                .background(Circle().strokeBorder(S.summaryRowIconRim, lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                if detailFirst {
                    Text(title).pulseText(.legend).foregroundStyle(PulseTheme.textSecondary)
                    Text(detail).pulseText(.subsectionTitle).foregroundStyle(PulseTheme.textPrimary)
                } else {
                    Text(title).pulseText(.subsectionTitle).foregroundStyle(PulseTheme.textPrimary)
                    Text(detail).pulseText(.legend).foregroundStyle(PulseTheme.textSecondary)
                }
            }
            Spacer(minLength: 8)
            PulseValueText(value: value, unit: unit, style: .tileValue, unitStyle: .tileUnit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: S.summaryRowRadius, style: .continuous).fill(S.summaryRow))
        .overlay(RoundedRectangle(cornerRadius: S.summaryRowRadius, style: .continuous)
            .strokeBorder(PulseTheme.divider, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// ZENO Age where WHOOP's card puts its age orb (/09: "26.2 / WHOOP AGE / 8.6 years younger"): ZENO's own
/// plain disc rather than WHOOP's orb art, in the Healthspan palette's green when younger than the wearer's
/// age and the unfavourable orange when older. ZENO Age is the weekly Body Age the Health tab shows
/// (`VitalityEngine`), the year's last one.
private struct YearReviewAgeBadge: View {
    let zenoAge: Double
    let chronologicalAge: Int?

    private typealias S = PulseExtrasTheme.Story

    /// ZENO Age less the wearer's age, when the age is known.
    private var difference: Double? { chronologicalAge.map { zenoAge - Double($0) } }

    private var tint: Color {
        guard let d = difference, d > S.ageSameBand else { return PulseTheme.Healthspan.youngerParticles }
        return PulseTheme.negative
    }

    private var comparison: String? {
        guard let d = difference else { return nil }
        if abs(d) < S.ageSameBand { return String(localized: "Your own age") }
        let years = PulseFormat.oneDecimal(abs(d))
        return d < 0 ? String(localized: "\(years) years younger") : String(localized: "\(years) years older")
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(PulseFormat.oneDecimal(zenoAge))
                .font(PulseType.font(.mediumValue))
                .foregroundStyle(PulseTheme.textPrimary)
            Text(String(localized: "ZENO Age"))
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let comparison {
                Text(comparison)
                    .pulseText(.chipStrong)
                    .foregroundStyle(tint)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(10)
        .frame(width: S.ageBadge, height: S.ageBadge)
        .background {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(S.ageFillCentre), tint.opacity(S.ageFillEdge)],
                                     center: .center, startRadius: 0, endRadius: S.ageBadge / 2))
                .overlay(Circle().strokeBorder(tint.opacity(S.ageRimStrength), lineWidth: S.ageRim))
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Not enough data

private struct YearReviewNotEnoughSlide: View {
    let snapshot: YearInReviewSnapshot

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: PulseExtrasTheme.Story.notEnoughGlyphSize, weight: .light))
                .foregroundStyle(PulseTheme.textTertiary)
                .accessibilityHidden(true)
            Text(snapshot.isPartial ? String(localized: "Your year is just getting started")
                                    : String(localized: "Not enough of this year to tell"))
                .extrasFont(PulseExtrasTheme.Story.titleSize, weight: .semibold, relativeTo: .title2)
                .foregroundStyle(PulseTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    /// "So far… keep wearing" only while the year is still running; a finished year says what it had.
    private var message: String {
        let days = PulseChallengeText.inflected("^[\(snapshot.summary.trackedDays) scored day](inflect: true)")
        let year = String(snapshot.year)
        return snapshot.isPartial
            ? String(localized: "Year in Review tells its story from two weeks of scored days. You have \(days) in \(year) so far. Keep wearing your strap and it fills in.")
            : String(localized: "Year in Review tells its story from two weeks of scored days, and \(year) has \(days). Next year's fills in as you wear your strap.")
    }
}
#endif
