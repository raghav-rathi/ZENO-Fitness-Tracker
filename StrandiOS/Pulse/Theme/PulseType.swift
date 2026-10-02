#if os(iOS)
import SwiftUI

// MARK: - Type scale (WHOOP_UI_SPEC §2.2, DR §2)
//
// SF Pro only (no Proxima Nova, no DIN). Words use the standard width; numerals are Bold CONDENSED with
// tabular digits, except the hero score and the stress value, which stay standard width. Units are set
// smaller and baseline-aligned with their number (the dial's % is 0.72× the value, the hero's 0.55×).
//
// Two ways to use a style:
//   Text("HEALTH MONITOR").pulseText(.cardTitle)   // scales with Dynamic Type, applies case + tracking
//   Text("80").font(PulseType.font(.dialValue))     // a fixed Font, for Text concatenation or Canvas
//
// Dials, hero numbers and every other large numeral are FIXED (they live inside rings that cannot grow);
// all other text scales relative to the text style named in `relativeTo`. Minimum size is 11 pt.

/// A named text style from the spec.
enum PulseTextStyle: CaseIterable {
    // DR tokens
    /// 58 Bold, standard width: the deep-dive score.
    case heroScore
    /// 32 Bold: the deep-dive score's "%".
    case heroUnit
    /// 28 Bold condensed: a Home dial's value.
    case dialValue
    /// 20 Bold condensed: a Home dial's "%".
    case dialUnit
    /// 20 Semibold Title Case: "My Day", "My Dashboard".
    case sectionTitle
    /// 17 Semibold Title Case: "Today's Activities".
    case subsectionTitle
    /// 22 Bold condensed: dashboard row values.
    case tileValue
    /// 14 Semibold, tertiary: a tile value's unit.
    case tileUnit
    /// 17 Bold condensed: contributor values.
    case rowValue
    /// 14 Medium: insights, coach copy, card prose.
    case body
    /// 14 Semibold: "Your Daily Outlook".
    case pillTitle
    /// 12 Bold UPPERCASE +0.7: "HEALTH MONITOR".
    case cardTitle
    /// 12 Semibold: "5/5 Metrics", "4:31pm".
    case secondary
    /// 12 Bold UPPERCASE +1.2: "TODAY" in a navigation bar.
    case navTitle
    /// 11 Bold UPPERCASE +1.0: dial labels, row labels, CTAs, status words.
    case label
    /// 13 Bold condensed: the 30-day baseline under a value.
    case baseline
    /// 11 Bold condensed: chart axis labels.
    case axis
    /// 10.5 Medium Title Case: the tab bar's labels.
    case tabLabel

    // NEW sizes (§2.2 table)
    /// 34 Bold condensed: Health Monitor tile and Sleep detail-card values, Trend View "AVERAGE", live stats.
    case largeValue
    /// 40 Bold condensed: an activity's Strain on Activity Details; ZENO Age in the Healthspan orb.
    case activityStrain
    /// 70 Bold condensed: the live activity's Strain.
    case liveStrain
    /// 64 Bold condensed: the pre-start heart rate in its circle.
    case preStartHR
    /// 44 Bold condensed: the Strength Trainer REST / ACTIVE timer.
    case strengthTimer
    /// 17 Regular: the Trend View insight sentence.
    case trendInsight
    /// 32 Bold condensed: Sleep Planner times.
    case plannerTime
    /// 24 Bold condensed: Tonight's Sleep times, Hours of Sleep, profile highlight rings, compact ZENO Age.
    case mediumValue
    /// 52 Bold, standard width: the stress gauge value.
    case stressValue
    /// 76 Heavy condensed: the Day Streak count.
    case streakCount
    /// 24 Semibold: Profile name, "Achievements", "Data Highlights", large page titles.
    case pageTitle
    /// 24 Bold UPPERCASE tracked: "LEVEL 29".
    case levelTitle
    /// 15 Bold UPPERCASE: the level tier ("DIAMOND").
    case levelTier
    /// 42 Heavy condensed: an achievement count in the grid.
    case achievementCount
    /// 22 Semibold: "Weekly Trends".
    case weeklyTrendsTitle
    /// 25 Semibold: an onboarding step title.
    case onboardingTitle
    /// 28 Semibold: a Journal question title.
    case journalQuestion
    /// 15 Medium: a Journal row question; the coach summary pill's text.
    case rowText
    /// 20 Semibold: the Smart log card, the Sleep Planner headline.
    case cardHeadline
    /// 30 Bold condensed: a Behavior Details impact value.
    case impactValue
    /// 15 Semibold: the coaching card title.
    case coachingTitle

    /// Everything that defines a style.
    struct Spec {
        let size: CGFloat
        let weight: Font.Weight
        /// Bold condensed numerals (SF Pro Condensed); words stay standard width.
        let condensed: Bool
        /// Tabular digits, so numbers never jiggle as they change.
        let monospacedDigits: Bool
        let uppercase: Bool
        /// Tracking in points at `size`; scaled with the text.
        let tracking: CGFloat
        /// The Dynamic Type style this scales with, or nil for a fixed size.
        let relativeTo: Font.TextStyle?
    }

    var spec: Spec {
        switch self {
        case .heroScore: return Spec(size: 58, weight: .bold, condensed: false, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .heroUnit: return Spec(size: 32, weight: .bold, condensed: false, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .dialValue: return Spec(size: 28, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .dialUnit: return Spec(size: 20, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .sectionTitle: return Spec(size: 20, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .title3)
        case .subsectionTitle: return Spec(size: 17, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .headline)
        case .tileValue: return Spec(size: 22, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: .title2)
        case .tileUnit: return Spec(size: 14, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .subheadline)
        case .rowValue: return Spec(size: 17, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: .headline)
        case .body: return Spec(size: 14, weight: .medium, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .subheadline)
        case .pillTitle: return Spec(size: 14, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .subheadline)
        case .cardTitle: return Spec(size: 12, weight: .bold, condensed: false, monospacedDigits: false, uppercase: true, tracking: 0.7, relativeTo: .caption)
        case .secondary: return Spec(size: 12, weight: .semibold, condensed: false, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: .caption)
        case .navTitle: return Spec(size: 12, weight: .bold, condensed: false, monospacedDigits: false, uppercase: true, tracking: 1.2, relativeTo: .caption)
        case .label: return Spec(size: 11, weight: .bold, condensed: false, monospacedDigits: false, uppercase: true, tracking: 1.0, relativeTo: .caption2)
        case .baseline: return Spec(size: 13, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: .footnote)
        case .axis: return Spec(size: 11, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: .caption2)
        case .tabLabel: return Spec(size: 10.5, weight: .medium, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: nil)
        case .largeValue: return Spec(size: 34, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .activityStrain: return Spec(size: 40, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .liveStrain: return Spec(size: 70, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .preStartHR: return Spec(size: 64, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .strengthTimer: return Spec(size: 44, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .trendInsight: return Spec(size: 17, weight: .regular, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .body)
        case .plannerTime: return Spec(size: 32, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .mediumValue: return Spec(size: 24, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .stressValue: return Spec(size: 52, weight: .bold, condensed: false, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .streakCount: return Spec(size: 76, weight: .heavy, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .pageTitle: return Spec(size: 24, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .title2)
        case .levelTitle: return Spec(size: 24, weight: .bold, condensed: false, monospacedDigits: true, uppercase: true, tracking: 1.6, relativeTo: .title2)
        case .levelTier: return Spec(size: 15, weight: .bold, condensed: false, monospacedDigits: false, uppercase: true, tracking: 1.0, relativeTo: .subheadline)
        case .achievementCount: return Spec(size: 42, weight: .heavy, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .weeklyTrendsTitle: return Spec(size: 22, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .title2)
        case .onboardingTitle: return Spec(size: 25, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .title2)
        case .journalQuestion: return Spec(size: 28, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .title)
        case .rowText: return Spec(size: 15, weight: .medium, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .subheadline)
        case .cardHeadline: return Spec(size: 20, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .title3)
        case .impactValue: return Spec(size: 30, weight: .bold, condensed: true, monospacedDigits: true, uppercase: false, tracking: 0, relativeTo: nil)
        case .coachingTitle: return Spec(size: 15, weight: .semibold, condensed: false, monospacedDigits: false, uppercase: false, tracking: 0, relativeTo: .subheadline)
        }
    }
}

extension PulseTextStyle.Spec {
    /// The SF Pro font for this style at `size`.
    func font(size: CGFloat) -> Font {
        var font = Font.system(size: size, weight: weight)
        if condensed { font = font.width(.condensed) }
        if monospacedDigits { font = font.monospacedDigit() }
        return font
    }
}

/// Fixed fonts for the styles, for places that need a `Font` value rather than a modifier.
enum PulseType {
    /// The style's font at its base size (no Dynamic Type scaling).
    static func font(_ style: PulseTextStyle) -> Font {
        let spec = style.spec
        return spec.font(size: spec.size)
    }

    /// A Bold condensed numeral with tabular digits at any size (`hero: true` keeps the standard width).
    static func numeral(_ size: CGFloat, weight: Font.Weight = .bold, hero: Bool = false) -> Font {
        let base = Font.system(size: size, weight: weight)
        return (hero ? base : base.width(.condensed)).monospacedDigit()
    }
}

/// Applies a `PulseTextStyle`: font (scaled when the style follows Dynamic Type), case and tracking.
struct PulseTextModifier: ViewModifier {
    private let spec: PulseTextStyle.Spec
    @ScaledMetric private var scaledSize: CGFloat

    init(_ style: PulseTextStyle) {
        let spec = style.spec
        self.spec = spec
        _scaledSize = ScaledMetric(wrappedValue: spec.size, relativeTo: spec.relativeTo ?? .body)
    }

    func body(content: Content) -> some View {
        let size = spec.relativeTo == nil ? spec.size : max(11, scaledSize)
        content
            .font(spec.font(size: size))
            .tracking(spec.tracking * size / spec.size)
            .textCase(spec.uppercase ? .uppercase : nil)
    }
}

extension View {
    /// Style text with a Pulse type token (font, Dynamic Type scaling, case and tracking).
    func pulseText(_ style: PulseTextStyle) -> some View {
        modifier(PulseTextModifier(style))
    }
}

extension PulseTheme {
    /// A Bold condensed numeral with tabular digits (the first Pulse screens' helper).
    static func numeral(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        PulseType.numeral(size, weight: weight)
    }
}
#endif
