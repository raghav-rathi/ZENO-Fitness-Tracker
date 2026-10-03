#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Daily Outlook / Day in Review (WHOOP_UI_SPEC §3.15)
//
// With a Coach provider configured, My Day's pill opens the Coach sheet seeded with the day (§1.6). Without
// one, or with Coach switched off, ZENO writes the same page itself from the day's own data [Z]: Recovery
// against its 7-day average, last night's sleep, the journal streak, this week's zone minutes, the Strain
// target and tonight's bedtime. A deterministic template, no weather (no network), every number from a
// snapshot; a fact with no data behind it is left out rather than guessed.

enum PulseDailyOutlook {
    /// The page's text: plain sentences with **bold** figures (rendered, never shown raw).
    struct Content: Hashable {
        let evening: Bool
        let greeting: String
        let insights: [String]
        let recommendations: [String]

        /// The same text as one plain block, the Coach sheet's seed.
        var plainText: String {
            let title = evening ? String(localized: "Day in Review") : String(localized: "Daily Outlook")
            let body = ([greeting] + insights + recommendations).map { $0.replacingOccurrences(of: "**", with: "") }
            return ([title] + body).joined(separator: "\n")
        }

        /// Enough to say: under three scored days the outlook would only repeat the dials.
        var isEmpty: Bool { insights.isEmpty && recommendations.isEmpty }
    }

    /// The Day in Review takes over at 18:00 local, or after the day's last activity if later (§3.1 8a).
    static func isEvening(_ home: HomeSnapshot, now: Date = Date()) -> Bool {
        let lastEnd = home.workouts.map { $0.start.addingTimeInterval(TimeInterval($0.durationMin * 60)) }.max()
        let sixPM = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        return now >= max(sixPM, lastEnd ?? sixPM)
    }

    static func compose(home: HomeSnapshot, facts: PulseOutlookFacts?, evening: Bool,
                        now: Date = Date()) -> Content {
        let weekday = now.formatted(.dateTime.weekday(.wide).locale(AppLanguage.activeLocale))
        let greeting = evening ? String(localized: "Here's how your \(weekday) went.")
                               : String(localized: "Happy \(weekday)!")
        var insights: [String] = []
        var recommendations: [String] = []

        // Recovery, against the 7 days before it.
        switch home.recovery.state {
        case .scored:
            if let r = home.recovery.value {
                let shown = PulseDisplay.displayedPercent(r)
                // "7‑day" with a non-breaking hyphen, so a line never ends on "7-".
                if let average = facts?.recoveryAverage7 {
                    if shown > average {
                        insights.append(String(localized: "Your Recovery is **\(shown)%**, above your 7\u{2011}day average of **\(average)%**."))
                    } else if shown < average {
                        insights.append(String(localized: "Your Recovery is **\(shown)%**, below your 7\u{2011}day average of **\(average)%**."))
                    } else {
                        insights.append(String(localized: "Your Recovery is **\(shown)%**, right on your 7\u{2011}day average."))
                    }
                } else {
                    insights.append(String(localized: "Your Recovery is **\(shown)%**."))
                }
            }
        case .calibrating(let nights, let of):
            insights.append(String(localized: "Recovery is still calibrating: **\(nights) of \(of)** nights so far."))
        case .carried, .noData:
            break
        }

        // Last night's sleep, as a duration ("6h 47m"; "6:47" reads as a clock time in prose).
        if let night = home.lastNight {
            let slept = duration(night.asleepMin)
            if let performance = night.performance {
                insights.append(String(localized: "You slept **\(slept)** last night, a Sleep Performance of **\(PulseDisplay.displayedPercent(performance))%**."))
            } else {
                insights.append(String(localized: "You slept **\(slept)** last night."))
            }
        }

        // The journal.
        if let facts {
            if facts.journalStreak >= 2 {
                insights.append(String(localized: "You've logged your journal **\(facts.journalStreak) days** in a row."))
            } else if !facts.journalLoggedToday && evening {
                insights.append(String(localized: "Today's journal is still open."))
            }
            // Zone minutes this week: the HR ZONES (WEEKLY) rows' own totals, over the activities they came from.
            if let zones = facts.zoneMinutesWeek {
                let total = duration(zones)
                let high = duration(facts.highZoneMinutesWeek ?? 0)
                let count = facts.zoneActivitiesWeek
                insights.append(count == 1
                    ? String(localized: "Over the last 7 days you spent **\(total)** in heart-rate zones in **1** activity, **\(high)** of it in zones 4-5.")
                    : String(localized: "Over the last 7 days you spent **\(total)** in heart-rate zones across **\(count)** activities, **\(high)** of it in zones 4-5."))
            }
        }

        // The Strain target, from the day's own Recovery only.
        if let target = home.target, !target.fromCarriedRecovery {
            let goal = PulseFormat.oneDecimal(target.targetValue)
            let range = "\(PulseFormat.oneDecimal(target.range.lowerBound))-\(PulseFormat.oneDecimal(target.range.upperBound))"
            let strain = home.strain.value ?? 0
            let now = PulseFormat.oneDecimal(strain)
            if evening {
                recommendations.append(String(localized: "Today's Strain reached **\(now)** against a target of **\(goal)** (optimal **\(range)**)."))
            } else if strain > target.range.upperBound {
                recommendations.append(String(localized: "Your Strain is already **\(now)**, past your optimal range of **\(range)**. Keep the rest of the day easy."))
            } else if strain >= target.targetValue {
                recommendations.append(String(localized: "You've reached today's Strain target of **\(goal)** at **\(now)**; your optimal range tops out at **\(PulseFormat.oneDecimal(target.range.upperBound))**."))
            } else if strain > 0 {
                recommendations.append(String(localized: "Aim for a Strain of **\(goal)** today, inside your optimal range of **\(range)**. You're at **\(now)** so far."))
            } else {
                recommendations.append(String(localized: "Aim for a Strain of **\(goal)** today, inside your optimal range of **\(range)**."))
            }
        }

        // Tonight's plan, the Sleep Planner's: the time to be asleep by; once the time to get into bed has
        // passed, "now" (as the card and the planner say).
        if let tonight = home.tonight {
            let need = duration(tonight.needMin)
            let wake = PulseFormat.clock(tonight.wake)
            if now >= tonight.inBed {
                recommendations.append(String(localized: "To get as close as you can to the **\(need)** of sleep you need tonight, go to sleep now to wake at **\(wake)**."))
            } else {
                recommendations.append(String(localized: "To get the **\(need)** of sleep you need tonight, be asleep by **\(PulseFormat.clock(tonight.asleepBy))** to wake at **\(wake)**."))
            }
        }
        return Content(evening: evening, greeting: greeting, insights: insights, recommendations: recommendations)
    }

    /// A duration for prose, "9h 26m", held on one line (a no-break space), so it never reads "9h" / "26m".
    private static func duration(_ minutes: Double) -> String {
        PulseFormat.duration(minutes: minutes).replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}

/// The local Daily Outlook as a pushed page.
struct PulseDailyOutlookRoute: PulseScreenRoute {
    let content: PulseDailyOutlook.Content

    var view: some View { PulseDailyOutlookView(content: content) }
}

/// The page (reviews/88): "‹ · DAILY OUTLOOK", the tan → slate → near-black page (indigo in the evening), a
/// message from ZENO's mark with the greeting, Key Insights and Activity Recommendations (15 pt Semibold)
/// as round-bulleted lines with bold figures, a note that it was written on the phone, and, while Coach can
/// answer, the Ask row.
struct PulseDailyOutlookView: View {
    let content: PulseDailyOutlook.Content

    @Environment(\.pulseCoach) private var coach
    @ScaledMetric(relativeTo: .body) private var bulletSize: CGFloat = 5

    /// The page: `Gradients.dailyOutlookPage`, or in the evening the Day in Review pill's indigo over the
    /// page's foot at the same stops.
    private var page: Gradient {
        let outlook = PulseTheme.Gradients.dailyOutlookPage
        guard content.evening else { return outlook }
        let colors = PulseTheme.Gradients.pillEvening.stops.map(\.color) + [PulseTheme.pageBottom]
        return Gradient(stops: zip(colors, outlook.stops.map(\.location)).map { Gradient.Stop(color: $0, location: $1) })
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: PulseTheme.Space.s) {
                PulseCoachAvatar(size: 24, ringWidth: 1, showsOrb: false)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: PulseTheme.Space.s) {
                    Text(content.greeting)
                        .pulseText(.trendInsight)
                        .foregroundStyle(PulseTheme.textPrimary)
                    section(String(localized: "Key Insights"), content.insights)
                    section(String(localized: "Activity Recommendations"), content.recommendations)
                    Text(String(localized: "Written on this iPhone from your own data."))
                        .pulseText(.secondary)
                        .foregroundStyle(PulseTheme.textTertiary)
                        .padding(.top, PulseTheme.Space.xs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
            .padding(.top, PulseTheme.Space.m)
            .padding(.bottom, PulseTheme.Layout.floatingChromeInset)
        }
        .background(LinearGradient(gradient: page, startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .overlay(alignment: .top) { backdrop }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if coach.availability != .off {
                PulseAskRow { coach.open(content.plainText) }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.bottom, PulseTheme.Space.xs)
            }
        }
        .pulseNavHeader(content.evening ? String(localized: "Day in Review") : String(localized: "Daily Outlook"))
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func section(_ title: String, _ lines: [String]) -> some View {
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: PulseTheme.Space.xs) {
                Text(title)
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .firstTextBaseline, spacing: PulseTheme.Space.s) {
                        // A round 5 pt bullet on the line's middle; the hidden "•" lends it the baseline.
                        Text(verbatim: "•")
                            .pulseText(.trendInsight)
                            .hidden()
                            .overlay { Circle().frame(width: bulletSize, height: bulletSize) }
                            .accessibilityHidden(true)
                        Text(Self.markdown(line))
                            .pulseText(.trendInsight)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // Brighter than card prose, as reviews/88 sets it; the figures are white.
                    .foregroundStyle(PulseTheme.textButton)
                    .padding(.leading, PulseTheme.Space.s)
                }
            }
            .padding(.top, PulseTheme.Space.xxs)
        }
    }

    /// The page gradient behind the bar once text scrolls under it, fading below it.
    private var backdrop: some View {
        GeometryReader { geo in
            // The insets are read outside the safe-area-ignoring gradient, which fills the whole screen
            // exactly as the page behind it does.
            LinearGradient(gradient: page, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        Rectangle().frame(height: max(0, geo.safeAreaInsets.top))
                        LinearGradient(colors: [Color.black, Color.black.opacity(0)], startPoint: .top, endPoint: .bottom)
                            .frame(height: PulseTheme.Header.barFade)
                        Spacer(minLength: 0)
                    }
                    .ignoresSafeArea()
                }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// "**44%**" set bold, the rest as written.
    static func markdown(_ line: String) -> AttributedString {
        var attributed = (try? AttributedString(markdown: line)) ?? AttributedString(line)
        for run in attributed.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            attributed[run.range].foregroundColor = PulseTheme.textPrimary
        }
        return attributed
    }
}
#endif
