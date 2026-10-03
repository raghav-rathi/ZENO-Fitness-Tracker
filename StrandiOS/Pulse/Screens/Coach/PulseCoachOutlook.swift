#if os(iOS)
import Foundation
import StrandAnalytics

// MARK: - Daily Outlook / Day in Review in the Coach sheet (WHOOP_UI_SPEC §3.15)
//
// Home's coach pill opens the sheet with the day's outlook (the 2025-26 sheet variant). When a provider is
// set up and the scheduled morning brief has already been written for today, the sheet shows that brief as
// the first assistant turn. Otherwise it shows this deterministic template in the spec's layout, built from
// Home's own snapshot, so every figure is the one on Home's dials and pill (one source per fact): a greeting,
// "Key Insights", then one bullet per figure with the numbers in bold. No weather (no network) and nothing
// the wearer has no data for; a missing figure is left out, never shown as zero.
//
// The template is also the page summary that goes with the first question (only while Use my data is on),
// so the card and what the model reads are the same text. The context block keeps each value on one line,
// so the parts are joined with " • " and the card splits them back into lines.

enum PulseCoachOutlook {
    static let separator = " • "

    /// "Daily Outlook • Good morning! Happy Saturday. • Your Recovery is **67%**, … • …" for Home's day.
    static func page(_ home: HomeSnapshot, evening: Bool, now: Date = Date()) -> String {
        var parts = [evening ? String(localized: "Day in Review") : String(localized: "Daily Outlook")]
        parts.append(greeting(evening: evening, now: now))
        parts += evening ? review(home) : outlook(home)
        return parts.joined(separator: separator)
    }

    /// The card's markdown for a page summary `page` wrote: the greeting, "Key Insights" and the bullets.
    /// Nil for any other text (an older summary shows as it is).
    static func markdown(_ page: String) -> String? {
        let parts = page.components(separatedBy: separator)
        guard parts.count >= 3, PulseCoachEnvelope.PageKind(page).isDaySummary else { return nil }
        let bullets = parts.dropFirst(2).map { "- " + $0 }.joined(separator: "\n")
        return parts[1] + "\n\n**" + String(localized: "Key Insights") + "**\n\n" + bullets
    }

    // MARK: Parts

    private static func greeting(evening: Bool, now: Date) -> String {
        let weekday = now.formatted(.dateTime.weekday(.wide))
        if evening { return String(localized: "Good evening! Here's how your \(weekday) went.") }
        let hour = Calendar.current.component(.hour, from: now)
        return hour < 12 ? String(localized: "Good morning! Happy \(weekday).")
                         : String(localized: "Good afternoon! Happy \(weekday).")
    }

    private static func outlook(_ home: HomeSnapshot) -> [String] {
        var lines: [String] = []
        if let recovery = recoveryLine(home) { lines.append(recovery) }
        if case .scored = home.sleep.state, let sleep = home.sleep.value {
            var line = String(localized: "Your Sleep Performance was **\(PulseDisplay.displayedPercent(sleep))%**")
            if let night = home.lastNight {
                line += ", " + String(localized: "with **\(PulseFormat.duration(minutes: night.asleepMin))** of sleep")
            }
            lines.append(line + ".")
        }
        if let target = home.target, !target.fromCarriedRecovery {
            var line = String(localized: "Your Strain target today is **\(PulseFormat.oneDecimal(target.targetValue))**, in an optimal range of **\(target.rangeText)**.")
            if let strain = home.strain.value, strain > 0 {
                line += " " + String(localized: "You're at **\(PulseFormat.oneDecimal(strain))** so far.")
            }
            lines.append(line)
        } else if let strain = home.strain.value, strain > 0 {
            lines.append(String(localized: "Your Strain so far today is **\(PulseFormat.oneDecimal(strain))**."))
        }
        if let tonight = home.tonight { lines.append(bedtimeLine(tonight)) }
        return lines
    }

    private static func review(_ home: HomeSnapshot) -> [String] {
        var lines: [String] = []
        if let strain = home.strain.value {
            var line = String(localized: "You reached a Strain of **\(PulseFormat.oneDecimal(strain))** today")
            if let target = home.target, !target.fromCarriedRecovery {
                if strain < target.range.lowerBound {
                    line += ", " + String(localized: "below your optimal range of **\(target.rangeText)**")
                } else if strain > target.range.upperBound {
                    line += ", " + String(localized: "above your optimal range of **\(target.rangeText)**")
                } else {
                    line += ", " + String(localized: "inside your optimal range of **\(target.rangeText)**")
                }
            }
            lines.append(line + ".")
        }
        if let recovery = recoveryLine(home) { lines.append(recovery) }
        if case .scored = home.sleep.state, let sleep = home.sleep.value {
            lines.append(String(localized: "Last night's Sleep Performance was **\(PulseDisplay.displayedPercent(sleep))%**."))
        }
        if let tonight = home.tonight { lines.append(bedtimeLine(tonight)) }
        return lines
    }

    /// Today's Recovery against the six days before it (Home's Strain & Recovery week), when at least three
    /// of them were scored.
    private static func recoveryLine(_ home: HomeSnapshot) -> String? {
        guard let value = home.recovery.value else {
            if case .calibrating(let nights, let of) = home.recovery.state {
                return String(localized: "Your Recovery is still calibrating: **\(nights)** of **\(of)** nights so far.")
            }
            return nil
        }
        let today = PulseDisplay.displayedPercent(value)
        if case .carried(let caption) = home.recovery.state {
            return String(localized: "Your latest Recovery is **\(today)%** (\(caption)).")
        }
        let prior = home.week.dropLast().compactMap(\.recovery)
        guard prior.count >= 3 else { return String(localized: "Your Recovery is **\(today)%**.") }
        let average = PulseDisplay.displayedPercent(prior.reduce(0, +) / Double(prior.count))
        if abs(today - average) < 5 {
            return String(localized: "Your Recovery is **\(today)%**, in line with your average of **\(average)%** over the past week.")
        }
        return today > average
            ? String(localized: "Your Recovery is **\(today)%**, above your average of **\(average)%** over the past week.")
            : String(localized: "Your Recovery is **\(today)%**, below your average of **\(average)%** over the past week.")
    }

    private static func bedtimeLine(_ tonight: PulseTonight) -> String {
        String(localized: "Aim to be asleep by **\(PulseFormat.clock(tonight.bedtime))** to get the **\(PulseFormat.duration(minutes: tonight.needMin))** of sleep you need tonight.")
    }
}

extension PulseCoachEnvelope.PageKind {
    /// Home's Daily Outlook or Day in Review.
    var isDaySummary: Bool { self == .outlook || self == .review }
}
#endif
