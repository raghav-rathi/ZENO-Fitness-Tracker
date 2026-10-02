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
                if let average = facts?.recoveryAverage7 {
                    if shown > average {
                        insights.append(String(localized: "Your Recovery is **\(shown)%**, above your 7-day average of **\(average)%**."))
                    } else if shown < average {
                        insights.append(String(localized: "Your Recovery is **\(shown)%**, below your 7-day average of **\(average)%**."))
                    } else {
                        insights.append(String(localized: "Your Recovery is **\(shown)%**, right on your 7-day average."))
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

        // Last night's sleep.
        if let night = home.lastNight {
            let slept = PulseFormat.hoursMinutes(night.asleepMin)
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
            // Zone minutes this week.
            if let zones = facts.zoneMinutesWeek {
                let high = facts.highZoneMinutesWeek ?? 0
                insights.append(String(localized: "Over the last 7 days you spent **\(PulseFormat.hoursMinutes(zones))** in heart-rate zones across **\(facts.activitiesThisWeek)** activities, **\(PulseFormat.hoursMinutes(high))** of it in zones 4-5."))
            }
        }

        // The Strain target, from the day's own Recovery only.
        if let target = home.target, !target.fromCarriedRecovery {
            let goal = PulseFormat.oneDecimal(target.targetValue)
            let range = "\(PulseFormat.oneDecimal(target.range.lowerBound))-\(PulseFormat.oneDecimal(target.range.upperBound))"
            if evening, let strain = home.strain.value {
                recommendations.append(String(localized: "Today's Strain reached **\(PulseFormat.oneDecimal(strain))** against a target of **\(goal)** (optimal **\(range)**)."))
            } else {
                var line = String(localized: "Aim for a Strain of **\(goal)** today, inside your optimal range of **\(range)**.")
                if let strain = home.strain.value, strain > 0 {
                    line += " " + String(localized: "You're at **\(PulseFormat.oneDecimal(strain))** so far.")
                }
                recommendations.append(line)
            }
        }

        // Tonight's bedtime, from the Sleep Planner's need.
        if let tonight = home.tonight {
            recommendations.append(String(localized: "To get the **\(PulseFormat.duration(minutes: tonight.needMin))** of sleep you need tonight, be asleep by **\(PulseFormat.clock(tonight.bedtime))** to wake at **\(PulseFormat.clock(tonight.wake))**."))
        }
        return Content(evening: evening, greeting: greeting, insights: insights, recommendations: recommendations)
    }
}

/// The local Daily Outlook as a pushed page.
struct PulseDailyOutlookRoute: PulseScreenRoute {
    let content: PulseDailyOutlook.Content

    var view: some View { PulseDailyOutlookView(content: content) }
}

/// The page (reviews/88): "‹ · DAILY OUTLOOK", the tan → slate → near-black page (indigo in the evening), a
/// message from ZENO's mark with the greeting, Key Insights and Activity Recommendations as bullets with
/// bold figures, a note that it was written on the phone, and, while Coach can answer, the Ask row.
struct PulseDailyOutlookView: View {
    let content: PulseDailyOutlook.Content

    @Environment(\.pulseCoach) private var coach

    private var page: Gradient {
        content.evening
            ? Gradient(colors: PulseTheme.Gradients.pillEvening.stops.map(\.color) + [PulseTheme.pageBottom])
            : PulseTheme.Gradients.dailyOutlookPage
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
                    .pulseText(.subsectionTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .firstTextBaseline, spacing: PulseTheme.Space.s) {
                        Text(verbatim: "•")
                            .pulseText(.trendInsight)
                            .accessibilityHidden(true)
                        Text(Self.markdown(line))
                            .pulseText(.trendInsight)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(PulseTheme.textSecondary)
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
