#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

// MARK: - Snapshots
//
// Immutable values a Pulse screen renders from. `PulseSnapshotBuilder` builds them off the main actor
// from one `PulseRequest`; `PulseModel` publishes them. A view holding a snapshot has everything it
// draws, already resolved and formatted, so a body pass does no store reads and no history scans.
//
// Dates come in two kinds and the types keep them apart. A DAY KEY ("yyyy-MM-dd") names a calendar day
// and is only ever turned into text through `PulseFormat.dayLabel`, which formats at UTC midnight the
// way the key was parsed. A real INSTANT (sleep onset, a workout start, an HR sample) is a `Date` and is
// shown in the device zone. Mixing the two is how a label reads the previous day west of UTC.

/// The day Home is showing.
struct PulseDay: Equatable, Hashable {
    /// Days back from today's logical day (0 = today).
    let offset: Int
    /// The day's key, as `DailyMetric.day` stores it.
    let key: String
    /// A real instant on that logical day (the logical "now" shifted back `offset` days), for titles.
    let date: Date

    var isToday: Bool { offset == 0 }

    /// A day is its offset and key. `date` is only the instant a title is formatted from and moves with
    /// the clock between builds, so it must not make two builds of the same day compare unequal.
    static func == (lhs: PulseDay, rhs: PulseDay) -> Bool {
        lhs.offset == rhs.offset && lhs.key == rhs.key
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(offset)
        hasher.combine(key)
    }
}

/// A score dial's content, fully resolved.
struct PulseDialData: Equatable {
    enum State: Equatable {
        /// The day scored its own value.
        case scored
        /// No score for the day; showing a real earlier value, stamped with whose it is.
        case carried(caption: String)
        /// Recovery's baseline is still learning: `nights` of `of` banked.
        case calibrating(nights: Int, of: Int)
        /// Nothing honest to show.
        case noData
    }

    let score: PulseScore
    /// On the dial's own axis: percent for Sleep and Recovery, 0-21 for Strain. nil = no value.
    let value: Double?
    let state: State
    /// Recovery only: the discrete band the value falls in.
    var band: PulseDisplay.RecoveryBand? = nil

    /// Arc fill, 0...1.
    var progress: Double {
        switch state {
        case .calibrating(let nights, let of): return of > 0 ? Double(nights) / Double(of) : 0
        default:
            guard let value else { return 0 }
            let span = score == .strain ? 21.0 : 100.0
            return max(0, min(1, value / span))
        }
    }

    /// The centred number.
    var valueText: String {
        guard let value else { return "–" }
        return score == .strain
            ? PulseFormat.oneDecimal(value)
            : "\(PulseDisplay.displayedPercent(value))"
    }

    /// The unit printed small beside the number.
    var unitText: String? {
        guard value != nil else { return nil }
        return score == .strain ? nil : "%"
    }

    /// The state line under the dial's name: whose night a carried value is, or "Calibrating".
    var caption: String? {
        switch state {
        case .carried(let caption): return caption
        case .calibrating: return String(localized: "Calibrating")
        case .noData, .scored: return nil
        }
    }

    /// The arc colour.
    var color: Color {
        if case .calibrating = state { return PulseTheme.textTertiary }
        if score == .recovery, let band { return PulseTheme.recovery(band) }
        return score.tint
    }

    /// VoiceOver phrasing: the score, its value and its state in one sentence.
    var accessibilityLabel: String {
        let name = score.displayName
        switch state {
        case .noData:
            return String(localized: "\(name), no data")
        case .calibrating(let nights, let of):
            return String(localized: "\(name), calibrating, \(nights) of \(of) nights")
        case .scored, .carried:
            let spoken: String
            if score == .strain {
                spoken = String(localized: "\(valueText) out of 21")
            } else {
                spoken = String(localized: "\(valueText) percent")
            }
            if case .carried(let caption) = state {
                return String(localized: "\(name), \(spoken), \(caption)")
            }
            return String(localized: "\(name), \(spoken)")
        }
    }
}

/// Today's recommended strain range, from the day's recovery.
struct PulseStrainTarget: Equatable {
    /// On the 0-21 axis, from `CoupledView.optimalStrainRange`.
    let range: ClosedRange<Double>
    let intent: PulseDisplay.StrainIntent
    let band: PulseDisplay.RecoveryBand
    /// The day's strain so far, 0-21, or nil when there is none.
    let current: Double?
    /// True when the recovery behind the target was carried from an earlier night.
    let fromCarriedRecovery: Bool
    /// The target is for today (still accruing), not a finished past day.
    let isToday: Bool

    /// "Today 7.0" while the day is live, "Strain 4.9" for a finished day.
    var currentLabel: String? {
        guard let current else { return nil }
        let value = PulseFormat.oneDecimal(current)
        return isToday ? String(localized: "Today \(value)") : "\(PulseScore.strain.displayName) \(value)"
    }

    var intentTitle: String {
        switch intent {
        case .restore: return String(localized: "Restore")
        case .maintain: return String(localized: "Maintain")
        case .push: return String(localized: "Push")
        }
    }

    var rangeText: String {
        "\(PulseFormat.oneDecimal(range.lowerBound))–\(PulseFormat.oneDecimal(range.upperBound))"
    }

    /// One line on where the day stands against the range.
    var progressText: String {
        guard let current else { return String(localized: "No strain logged yet") }
        if current < range.lowerBound {
            return String(localized: "\(PulseFormat.oneDecimal(range.lowerBound - current)) below the range")
        }
        if current > range.upperBound {
            return String(localized: "\(PulseFormat.oneDecimal(current - range.upperBound)) above the range")
        }
        return String(localized: "In the range")
    }
}

/// Last night's main sleep, for My Day.
struct PulseNightSummary: Equatable {
    let onset: Date
    let wake: Date
    let asleepMin: Double
    let inBedMin: Double
    /// The Sleep dial's value for the same night, so the row and the dial agree.
    let performance: Double?
}

/// A nap: a sleep block outside the main night.
struct PulseNap: Identifiable, Equatable {
    let id: Int
    let start: Date
    let end: Date
    let asleepMin: Double
}

/// Tonight's plan as the Sleep Planner resolves it (`PulseSleepPlan`) for the goal chosen there, so Home's
/// TONIGHT'S SLEEP card and the planner it opens state the same night (`PulseSnapshotBuilder.tonightPlan`).
struct PulseTonight: Equatable {
    /// Tonight's need: baseline + strain + debt − nap credit (`SleepNeedBreakdown.totalMin`), minutes.
    let needMin: Double
    /// When to get into bed, allowing the time it takes to fall asleep: the card's RECOMMENDED BEDTIME and
    /// the planner's suggested time to bed.
    let inBed: Date
    /// When to be asleep by to meet the need.
    let asleepBy: Date
    let wake: Date
    /// What named the wake: the strap alarm only when it will actually buzz that morning.
    let wakeSource: TonightSleepPlan.WakeSource
    /// The sleep the plan allows for, as a share of `needMin`, 0-100 (`PulseSleepPlan.coveragePercent`): under
    /// 100 for a goal short of the whole need, or a bedtime held at the earliest the planner suggests.
    let coveragePercent: Int

    /// The strap alarm buzzes at `wake`: "● ALARM ON · EXACT TIME".
    var alarmOn: Bool { wakeSource == .strapAlarm }
}

/// A workout on the selected day.
struct PulseWorkoutItem: Identifiable, Equatable {
    let id: String
    let title: String
    /// The raw sport string, for the icon.
    let sport: String
    let start: Date
    let durationMin: Int
    /// On the 0-21 axis.
    let strain: Double?
    let kcal: Double?
    let route: PulseWorkoutRoute
}

/// A pushable reference to one workout row. `WorkoutRow` is only `Equatable`; the path needs `Hashable`.
struct PulseWorkoutRoute: Hashable {
    let row: WorkoutRow

    static func == (lhs: PulseWorkoutRoute, rhs: PulseWorkoutRoute) -> Bool { lhs.row == rhs.row }

    func hash(into hasher: inout Hasher) {
        hasher.combine(row.startTs)
        hasher.combine(row.endTs)
        hasher.combine(row.sport)
        hasher.combine(row.source)
    }
}

/// How a value compares with its recent average, as drawn under a stat.
struct PulseComparison: Equatable {
    let direction: PulseDisplay.Direction
    /// The magnitude, e.g. "8%" or "0.3°".
    let text: String
    /// What it is compared against, e.g. "vs 30-day avg".
    let caption: String
    /// Spoken form.
    let accessibility: String
}

/// One Key Stats tile.
struct PulseKeyStat: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let value: String
    let unit: String
    let caption: String?
    let comparison: PulseComparison?
    /// Trailing values ending on the displayed day, oldest first.
    let spark: [Double]
    let route: TabRoute
    /// Today's still-accumulating count (steps, calories): shown as "So far today" in place of a
    /// comparison, since a partial day against full-day averages would always read as a drop.
    var isRunningTotal: Bool = false
    /// The 30-day average the comparison is against, formatted as the value is ("46", "7,466"), for the
    /// My Dashboard row's baseline line; nil while there is no average or no comparison.
    var baseline: String? = nil
    /// Value minus that average, zero when the two PRINT the same (§2.6 item 9: any difference that shows
    /// is coloured good / bad; a grey dot only when the figures match).
    var baselineDelta: Double? = nil
}

/// One day of the STRAIN & RECOVERY chart: Strain on 0–21 and Recovery in percent, either missing.
struct PulseWeekDay: Identifiable, Equatable {
    /// The day key.
    let id: String
    let strain: Double?
    let recovery: Double?
}

/// The day's stress as Home's STRESS MONITOR tile and dashboard card show it: the Stress Monitor's own day
/// (`PulseSnapshotBuilder.stressDay`), so the three can never print different levels or times. Home's
/// extras carry it (`HomeExtrasSnapshot.stress`), never `HomeSnapshot`: scoring a day's stress reads its
/// heart rate, R-R and motion, which the dials must not wait for.
struct PulseStressSummary: Equatable {
    /// The gauge's level, 0-3: the curve's latest reading, else the day's daily score; nil with neither.
    /// Print it as `shown`, never directly.
    let score: Double?
    /// When the reading was taken (the end of its hour, at most the build's now); nil when `score` is the
    /// daily score rather than a reading.
    let at: Date?
    /// The day the stress is for, to tell a reading from the evening before.
    let dayKey: String
    /// The Stress Monitor's chart: its points over the 24 hours it covers (nil values are gaps), and where
    /// they end (now today, the last reading on a past day, nil on a past day without one).
    let points: [PulseTimeValue]
    let chartEnd: Date?
    /// The day's own scored hours.
    let hours: [DaytimeStress.HourPoint]
    let maskedHours: Int
    let isToday: Bool

    /// The level as the Stress Monitor's gauge prints it: cut to one decimal (`HealthStressGauge.printed`),
    /// so a level word taken from it always matches the figure beside it.
    @MainActor var shown: Double? { score.map(HealthStressGauge.printed) }
    @MainActor var scoreText: String { shown.map { PulseFormat.oneDecimal($0) } ?? "–" }
    @MainActor var bandTitle: String? { shown.map { StressBand(score: $0).title } }
    var hasCurve: Bool { hours.contains { $0.level != nil } }
}

/// The journal prompt: the last seven local days, oldest first, and which carry an entry.
///
/// The same data and taps as the classic `JournalReminderCard`, read by the builder instead of by the
/// card itself. That card loads in a `.task` attached to a `Group` that is empty until the load lands,
/// and SwiftUI never starts a task on an empty `Group`, so it can never appear (verified in the
/// simulator); Pulse does not depend on it.
struct PulseJournalStrip: Equatable {
    struct Day: Equatable, Identifiable {
        let key: String
        /// Days back from today (0 = today), the offset `NavRouter.openJournal(day:)` takes.
        let offset: Int
        let logged: Bool
        var id: String { key }
    }

    let days: [Day]

    var todayLogged: Bool { days.last?.logged ?? false }
    var hasMissed: Bool { days.dropLast().contains { !$0.logged } }
}

/// Everything Home draws for one day.
struct HomeSnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    let sleep: PulseDialData
    let recovery: PulseDialData
    let strain: PulseDialData
    let target: PulseStrainTarget?
    let lastNight: PulseNightSummary?
    let naps: [PulseNap]
    let workouts: [PulseWorkoutItem]
    let tonight: PulseTonight?
    /// The values My Dashboard's rows show (HRV, resting HR, …), each against its 30-day average.
    let stats: [PulseKeyStat]
    /// The seven days ending on the selected one, while the journal reminder is switched on.
    let journal: PulseJournalStrip?
    /// Today's day streak (consecutive days with a Recovery score); nil on a past day.
    let streak: Int?
    /// The seven days ending on the selected one, oldest first, for STRAIN & RECOVERY.
    let week: [PulseWeekDay]
    /// The mean scored Recovery over the 7 days before the selected one (3 scored days at least), whole
    /// percent: the Daily Outlook's 7-day average, kept here so that every outlook made from this snapshot
    /// (the Coach sheet's too) can print the one figure.
    let recoveryAverage7: Int?
    /// Days with a Recovery score in the history: under 3 and no Coach provider, no outlook can be made,
    /// so My Day shows the Ask row instead of the coach pill.
    let scoredDays: Int

    var dials: [PulseDialData] { [sleep, recovery, strain] }
}

// MARK: - Deep dives

/// A contributor row: a value against its 30-day average.
struct PulseContributor: Identifiable, Equatable {
    let id: String
    let title: String
    let value: String
    let unit: String
    /// The baseline under the value: the bare number ("79", "75%"), or a short caption ("vs your baseline").
    let averageText: String?
    let comparison: PulseComparison?
    let route: TabRoute?
}

/// One bar of a day-keyed history chart. Its axis label is formatted from the key, at UTC.
struct PulseDayBar: Identifiable, Equatable {
    /// The day key.
    let id: String
    let value: Double
    let band: PulseDisplay.RecoveryBand?
}

/// The Recovery deep dive for one day.
struct RecoverySnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    let dial: PulseDialData
    /// The day whose row the dial shows (its own, or the carried night's).
    let sourceDayKey: String?
    let contributors: [PulseContributor]
    let context: [PulseContributor]
    let drivers: [ChargeDriver]
    let confidence: ScoreConfidence?
    /// Up to 90 days ending on the selected day, oldest first.
    let history: [PulseDayBar]
}

/// A timestamped value (the cumulative strain curve).
struct PulseTimePoint: Identifiable, Equatable {
    let date: Date
    let value: Double
    var id: Date { date }
}

/// One bucket of the day's heart rate.
struct PulseHRPoint: Identifiable, Equatable {
    let date: Date
    let bpm: Double
    /// Contiguous-run identity, so a gap in wear is drawn as a gap rather than a straight line.
    let segment: String
    var id: Date { date }
}

/// One heart-rate zone's bounds.
struct PulseZoneBand: Identifiable, Equatable {
    let number: Int
    let lower: Double
    let upper: Double
    var id: Int { number }
}

/// The Strain deep dive for one day.
struct StrainSnapshot: Equatable {
    let seq: Int
    let day: PulseDay
    let dial: PulseDialData
    let target: PulseStrainTarget?
    let curve: [PulseTimePoint]
    let hr: [PulseHRPoint]
    let window: ClosedRange<Date>
    let zones: [PulseZoneBand]
    /// Minutes in zones 1-5.
    let zoneMinutes: [Double]
    let calories: Double?
    let averageHR: Int?
    let peakHR: Int?
    let workouts: [PulseWorkoutItem]
}

// MARK: - Formatting

enum PulseFormat {
    static func oneDecimal(_ v: Double) -> String {
        String(format: "%.1f", locale: AppLanguage.activeLocale, v)
    }

    static func whole(_ v: Double) -> String { "\(Int(v.rounded()))" }

    /// A number with its unit: "%" binds tight ("94%"), every other unit takes a space ("81 ms").
    static func withUnit(_ number: String, _ unit: String) -> String {
        guard !unit.isEmpty else { return number }
        return unit == "%" ? number + unit : "\(number) \(unit)"
    }

    static func grouped(_ v: Double) -> String {
        groupedFormatter.string(from: NSNumber(value: Int(v.rounded()))) ?? whole(v)
    }

    private static let groupedFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = AppLanguage.activeLocale
        return f
    }()

    /// "7h 12m" from minutes.
    static func duration(minutes: Double) -> String {
        let total = max(0, Int(minutes.rounded()))
        let h = total / 60, m = total % 60
        if h == 0 { return String(localized: "\(m)m") }
        return String(localized: "\(h)h \(m)m")
    }

    /// "6:41" from minutes: the activity chip's duration.
    static func hoursMinutes(_ minutes: Double) -> String {
        let total = max(0, Int(minutes.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// A row's start time, prefixed with its weekday when it began on an earlier day than `end`
    /// ("[Wed] 11:03 PM"). Real instants, device zone.
    static func activityTime(_ start: Date, relativeTo end: Date) -> String {
        guard !Calendar.current.isDate(start, inSameDayAs: end) else { return clock(start) }
        let weekday = start.formatted(.dateTime.weekday(.abbreviated).locale(AppLanguage.activeLocale))
        return "[\(weekday)] \(clock(start))"
    }

    /// A clock time for a real instant, in the device zone, honouring the Clock format setting, with a full
    /// space before AM / PM as WHOOP prints it ("6:21 AM", help-center/91, deep-dives-2026/12).
    static func clock(_ date: Date) -> String { wordSpaced(AppClock.hourMinute(date)) }

    /// `time` with the narrow no-break space iOS puts before AM / PM (U+202F, which reads "6:21AM" in the
    /// condensed numerals) widened to a full one (U+00A0), so a time still never wraps before its AM / PM.
    /// `AppClock` keeps the narrow space for the classic and macOS screens.
    static func wordSpaced(_ time: String) -> String {
        time.replacingOccurrences(of: "\u{202F}", with: "\u{00A0}")
    }

    /// The same clock time without its AM / PM ("9:32", "23:32"), for the big Tonight's Sleep times
    /// (WHOOP prints none; VoiceOver still hears `clock(_:)`).
    static func clockNoMeridiem(_ date: Date) -> String {
        lock.lock(); defer { lock.unlock() }
        let use24 = AppClock.uses24Hour
        if let cached = noMeridiemFormatter, cached.uses24 == use24 {
            return cached.formatter.string(from: date)
        }
        let f = DateFormatter()
        f.locale = AppClock.formattingLocale
        f.setLocalizedDateFormatFromTemplate(use24 ? "Hmm" : "hmm")
        // Drop the day-period field and the space around it.
        f.dateFormat = f.dateFormat
            .replacingOccurrences(of: "a", with: "")
            .replacingOccurrences(of: "B", with: "")
            .trimmingCharacters(in: .whitespaces)
        noMeridiemFormatter = (use24, f)
        return f.string(from: date)
    }

    private static var noMeridiemFormatter: (uses24: Bool, formatter: DateFormatter)?

    /// A short label for a DAY KEY ("12 Jul"), formatted at UTC midnight, the instant the key was parsed
    /// at, so it names the key's own day in every time zone.
    static func dayLabel(_ key: String, template: String = "dMMM") -> String {
        guard let date = dayKeyParser.date(from: key) else { return key }
        return dayFormatter(template).string(from: date)
    }

    private static let dayKeyParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static var dayFormatters: [String: DateFormatter] = [:]
    private static let lock = NSLock()

    private static func dayFormatter(_ template: String) -> DateFormatter {
        lock.lock(); defer { lock.unlock() }
        if let f = dayFormatters[template] { return f }
        let f = DateFormatter()
        f.locale = AppLanguage.activeLocale
        f.setLocalizedDateFormatFromTemplate(template)
        f.timeZone = TimeZone(identifier: "UTC")
        dayFormatters[template] = f
        return f
    }

    /// A navigation-bar or pager title for a Home day: "Today", else "Wed, Jun 4" (the text style
    /// uppercases it). `date` is a real instant on that logical day, so it is formatted in the device zone.
    static func navDayTitle(offset: Int, date: Date) -> String {
        guard offset > 0 else { return String(localized: "Today") }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()
            .locale(AppLanguage.activeLocale))
    }

    /// The same title for a DAY KEY, formatted at UTC like every day key: "Wed, Sep 30".
    static func navDayTitle(dayKey: String) -> String {
        dayLabel(dayKey, template: "EEEMMMd")
    }

    /// "Today" / "Yesterday" / the weekday for a Home day. `date` is a real instant on that logical day
    /// (the logical now shifted back), so it is formatted in the device zone, the zone it was made in.
    static func dayTitle(offset: Int, date: Date) -> String {
        switch offset {
        case 0: return String(localized: "Today")
        case 1: return String(localized: "Yesterday")
        default: return date.formatted(.dateTime.weekday(.wide).locale(AppLanguage.activeLocale))
        }
    }

    /// The line under the day title, device zone (see `dayTitle`): "Wed, 30 Sep" under Today and
    /// Yesterday; just "28 Sep" under a weekday title, which already names the day; the year once it
    /// is not this year's.
    static func daySubtitle(offset: Int, date: Date) -> String {
        let locale = AppLanguage.activeLocale
        let sameYear = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
        if !sameYear {
            return date.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
        }
        if offset >= 2 {
            return date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
        }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(locale))
    }
}
#endif
