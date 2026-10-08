import Foundation
import StrandAnalytics

/// Storage keys and fixed ids for the Steps feature.
enum StepsPrefs {
    /// The daily goal, `@AppStorage`-backed. Default `StepGoal.defaultGoal`; always read through `goal`
    /// (or `StepGoal.clamp`) because a hand-edited default can hold anything.
    static let goalKey = "steps.goal"
    /// The goal-reached notification switch. Default OFF.
    static let goalNotificationKey = "steps.goalNotification"
    /// The day the goal notification last posted for (the once-a-day dedupe).
    static let goalNotifiedDayKey = "steps.goalNotifiedDay"
    /// Unix second up to which the iPhone's hourly buckets are banked as final. The next backfill starts a
    /// little before it rather than re-reading the whole seven days CoreMotion keeps.
    static let phoneWatermarkKey = "steps.phone.backfilledThrough"
    /// Unix second up to which Apple Health's hourly step buckets were last imported (the end of the Health
    /// bridge's last successful hourly read). With `phoneWatermarkKey` it says which hours the phone side has
    /// finished counting, so the band never tops up an hour that is still being counted.
    static let healthHoursThroughKey = "steps.health.hoursImportedThrough"

    /// Fill the hours the phone missed with the band's estimate (`StepsHourMerge`). Default on.
    static let bandFillKey = "steps.bandFill"
    /// The strap's hourly calibration, mirrored by the analysis pass for the Steps calibration sheet: steps per
    /// walking minute (0 until there is one), the carried hours it rests on (or has collected so far), and its
    /// 0-1 confidence.
    static let bandHourPaceKey = "steps.bandHour.stepsPerMinute"
    static let bandHourSampleHoursKey = "steps.bandHour.sampleHours"
    static let bandHourConfidenceKey = "steps.bandHour.confidence"

    static var bandFillEnabled: Bool { UserDefaults.standard.object(forKey: bandFillKey) as? Bool ?? true }
    /// Appended to a day's provenance id when the band filled hours the phone missed, so a readings table
    /// names both ("Apple Health + strap").
    static let bandFillSourceSuffix = "+band"

    /// The instant up to which the phone side has finished counting: the later of the iPhone's banked
    /// watermark and Apple Health's last hourly import, less `settleMargin`. Only hours that end by then can
    /// take the band's estimate. With neither (a Mac, or no phone source at all) that is the start of today, so
    /// only past days can be filled.
    static func phoneSideSettledUntil(todayStart: Int) -> Int {
        let d = UserDefaults.standard
        let phone = d.object(forKey: phoneWatermarkKey) as? Int
        let health = d.object(forKey: healthHoursThroughKey) as? Int
        guard phone != nil || health != nil else { return todayStart }
        return max(phone ?? 0, health ?? 0) - settleMargin
    }

    /// The iPhone's motion coprocessor can post an hour's steps a little late, to itself and to Apple Health,
    /// so the newest hour before either watermark is not treated as final yet.
    static let settleMargin = 3_600

    /// The deviceId the iPhone pedometer's own readings are banked under: daily totals in `metricSeries`
    /// (the generic per-device daily scalar store) and hour buckets in `appleStepHour` (the per-device
    /// hourly step table Apple Health already uses). Distinct from "apple-health" on purpose: Health's
    /// figure already includes these steps, and keeping the two apart is what lets the resolver choose
    /// between them instead of adding them up.
    static let phoneDeviceId = "iphone-pedometer"
    static let phoneStepsKey = "steps"
    static let phoneDistanceKey = "distance_m"
    static let phoneFloorsKey = "floors_up"

    /// How many days of history the Steps surfaces keep resolved in memory: a year and a day, enough for
    /// the 30-day chart, a long streak and a meaningful best day, and cheap to re-read.
    static let historyDays = 366

    /// The stored goal, clamped. `@AppStorage` returns its declared default for a missing key; a bare
    /// `UserDefaults.integer` returns 0, hence the explicit fallback.
    static var goal: Int {
        let stored = UserDefaults.standard.integer(forKey: goalKey)
        return stored == 0 ? StepGoal.defaultGoal : StepGoal.clamp(stored)
    }
}

extension ResolvedStepDay {
    /// The badge name: the source, plus the strap when its estimate added steps for hours the phone missed.
    var sourceLabel: String {
        bandSteps > 0 ? String(localized: "\(source.displayName) + strap") : source.displayName
    }
}

extension StepSource {
    /// The short name a source badge shows.
    var displayName: String {
        switch self {
        case .healthKit: return "Apple Health"
        case .phonePedometer: return "iPhone"
        case .strapCounter: return String(localized: "Strap")
        case .strapEstimate: return String(localized: "Strap estimate")
        }
    }

    /// A longer phrase for VoiceOver and the screen's source line.
    var explanation: String {
        switch self {
        case .healthKit: return String(localized: "From Apple Health, which merges your iPhone and Apple Watch without counting a step twice.")
        case .phonePedometer: return String(localized: "Counted by this iPhone while you carried it.")
        case .strapCounter: return String(localized: "Counted by your strap's step counter.")
        case .strapEstimate: return String(localized: "Estimated from your strap's motion. Approximate.")
        }
    }

    /// SF Symbol for the badge.
    var symbol: String {
        switch self {
        case .healthKit: return "heart.text.square.fill"
        case .phonePedometer: return "iphone"
        case .strapCounter: return "shoeprints.fill"
        case .strapEstimate: return "figure.walk.motion"
        }
    }
}
