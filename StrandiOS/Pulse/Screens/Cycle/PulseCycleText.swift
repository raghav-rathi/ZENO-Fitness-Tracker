#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - Cycle copy (WHOOP_UI_SPEC §3.24)
//
// Every sentence the cycle page prints about phases. The coaching and chart paragraphs are educational and
// hedged ("many people", "usually"): they describe the textbook physiology, never a claim about this
// wearer, and carry no numbers. The wearer's own numbers come from their logs and nights only.

enum PulseCycleText {

    static func phaseName(_ phase: PulseCyclePhase) -> String {
        switch phase {
        case .menstrual: return String(localized: "Menstrual")
        case .follicular: return String(localized: "Follicular")
        case .ovulatory: return String(localized: "Ovulatory")
        case .luteal: return String(localized: "Luteal")
        }
    }

    /// "Luteal Phase".
    static func phaseTitle(_ phase: PulseCyclePhase) -> String {
        switch phase {
        case .menstrual: return String(localized: "Menstrual Phase")
        case .follicular: return String(localized: "Follicular Phase")
        case .ovulatory: return String(localized: "Ovulatory Phase")
        case .luteal: return String(localized: "Luteal Phase")
        }
    }

    /// The phase bar's letter.
    static func letter(_ phase: PulseCyclePhase) -> String {
        switch phase {
        case .menstrual: return String(localized: "M")
        case .follicular: return String(localized: "F")
        case .ovulatory: return String(localized: "O")
        case .luteal: return String(localized: "L")
        }
    }

    /// The temperature engine's phase on the page's scale (its "around the shift" is the ovulatory span).
    static func phase(_ engine: CyclePhaseEngine.Phase) -> PulseCyclePhase? {
        switch engine {
        case .follicular: return .follicular
        case .periOvulatory: return .ovulatory
        case .luteal: return .luteal
        case .unknown, .learning: return nil
        }
    }

    /// "Next period in: 25–27 Days", "Next period: due within 2 days", "Next period: due today".
    static func nextPeriod(window: MenstrualCycleModel.Window, today: String) -> String {
        let lo = max(0, MenstrualCycleModel.days(from: today, to: window.earliest) ?? 0)
        let hi = max(0, MenstrualCycleModel.days(from: today, to: window.latest) ?? 0)
        if hi == 0 { return String(localized: "Next period: due today") }
        if lo == 0 {
            return hi == 1 ? String(localized: "Next period: due within 1 day")
                           : String(localized: "Next period: due within \(hi) days")
        }
        if lo == hi { return String(localized: "Next period in: \(lo) Days") }
        return String(localized: "Next period in: \(lo)–\(hi) Days")
    }

    /// Where a prediction comes from.
    static func basis(_ basis: MenstrualCycleModel.PredictionBasis) -> String {
        switch basis {
        case .personal(let n):
            return n == 1 ? String(localized: "Based on your last cycle")
                          : String(localized: "Based on your last \(n) cycles")
        case .temperature:
            return String(localized: "Cycle length estimated from your skin temperature")
        case .typical:
            return String(localized: "Estimated from a typical 28-day cycle until you log another period")
        }
    }

    /// The <PHASE> PHASE COACHING paragraph.
    static func coaching(_ phase: PulseCyclePhase) -> String {
        switch phase {
        case .menstrual:
            return String(localized: "Your period has started. Energy and sleep can dip in the first days, and cramps can make hard training feel harder. Go by how you feel: lighter sessions, extra sleep and steady hydration help.")
        case .follicular:
            return String(localized: "After your period, estrogen rises. Many people feel more energetic in this phase and recover well from harder sessions, so it can be a good time to build intensity.")
        case .ovulatory:
            return String(localized: "Energy is often at its highest around ovulation. Your skin temperature usually starts to rise just after it, as the luteal phase begins.")
        case .luteal:
            return String(localized: "After ovulation, progesterone rises. Resting heart rate and skin temperature usually run higher and HRV lower, so Recovery can read lower and hard sessions can feel harder. Prioritise sleep, especially in the days before your period.")
        }
    }

    /// The paragraph under "Your Current Cycle".
    static func currentCycle(_ phase: PulseCyclePhase, phasesApply: Bool) -> String {
        guard phasesApply else {
            return String(localized: "Bars show how far each night sat from your own baseline this cycle. With hormonal contraception there is no natural phase pattern to compare against.")
        }
        switch phase {
        case .menstrual:
            return String(localized: "During your period, skin temperature usually falls back toward your baseline as progesterone drops, and resting heart rate eases.")
        case .follicular:
            return String(localized: "During the follicular phase, skin temperature and resting heart rate usually sit at or below your baseline, and HRV tends to recover.")
        case .ovulatory:
            return String(localized: "Around ovulation, skin temperature is often at its lowest just before it rises into the luteal phase.")
        case .luteal:
            return String(localized: "During the luteal phase, HRV is typically below your baseline, while skin temperature and resting heart rate run above it. These changes can make Recovery read lower or workouts feel harder.")
        }
    }
}

// MARK: - Phase colours (the theme's §2.1 menstrual palette)

extension PulseCyclePhase {
    /// The legend dot and the bright fills (today's circle, chart bars).
    var dot: Color { palette.dot }

    /// The calendar band.
    var band: Color { palette.band }

    /// The band on days still to come (luteal has its own sampled tone; the others are the band, dimmed).
    var futureBand: Color {
        self == .luteal ? PulseTheme.Menstrual.lutealFuture : palette.band.opacity(0.55)
    }

    private var palette: PulseTheme.Menstrual.Phase {
        switch self {
        case .menstrual: return .menstrual
        case .follicular: return .follicular
        case .ovulatory: return .ovulatory
        case .luteal: return .luteal
        }
    }
}
#endif
