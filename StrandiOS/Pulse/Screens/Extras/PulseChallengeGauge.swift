#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - The challenge gauge and how each kind reads (WHOOP_UI_SPEC §3.41)

/// WHOOP's challenge gauge (profile-community-2026/13, 42, 76): a comb of radial ticks sweeping 270° from
/// the lower left to the lower right, lit from the start in proportion to the progress (all of it once
/// the target is reached), the lit ticks brightening toward white at the head; unlit ticks grey, fading
/// toward the centre. Static: it only changes when the progress does.
struct PulseChallengeGauge: View {
    /// Progress, 0…1 (anything above 1 lights the whole comb).
    let fraction: Double
    let color: Color
    var diameter: CGFloat = PulseExtrasTheme.Challenge.gaugeDiameter

    private typealias C = PulseExtrasTheme.Challenge

    var body: some View {
        Canvas { context, size in
            let scale = size.width / C.gaugeDiameter
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = size.width / 2
            let inner = outer - C.tickLength * scale
            let lit = Int((min(max(fraction, 0), 1) * Double(C.tickCount)).rounded(.up))
            for i in 0..<C.tickCount {
                let t = Double(i) / Double(C.tickCount - 1)
                let angle = Angle.degrees(-C.gaugeSweep / 2 + t * C.gaugeSweep)
                let dx = CGFloat(sin(angle.radians)), dy = CGFloat(-cos(angle.radians))
                let a = CGPoint(x: centre.x + dx * inner, y: centre.y + dy * inner)
                let b = CGPoint(x: centre.x + dx * outer, y: centre.y + dy * outer)
                var tick = Path()
                tick.move(to: a)
                tick.addLine(to: b)
                let shading: GraphicsContext.Shading
                if i < lit {
                    // From the challenge's colour at the start to near white at the head.
                    let head = lit > 1 ? Double(i) / Double(lit - 1) : 1
                    let tip = color.mix(with: .white, by: 0.15 + 0.7 * head)
                    shading = .linearGradient(Gradient(colors: [tip.opacity(0.35), tip]), startPoint: a, endPoint: b)
                } else {
                    shading = .linearGradient(Gradient(colors: [C.unlitTickInner, C.unlitTick]), startPoint: a,
                                              endPoint: b)
                }
                context.stroke(tick, with: shading, style: StrokeStyle(lineWidth: C.tickWidth * scale, lineCap: .butt))
            }
        }
        .frame(width: diameter, height: diameter)
        .background {
            RadialGradient(colors: [C.gaugeGlow, C.gaugeGlow.opacity(0)], center: .center, startRadius: 0,
                           endRadius: diameter / 2)
        }
        .accessibilityHidden(true)
    }
}

private extension Color {
    /// This colour blended toward `other` by `amount` (0…1), in sRGB.
    func mix(with other: Color, by amount: Double) -> Color {
        let a = UIColor(self).rgba, b = UIColor(other).rgba
        let t = min(max(amount, 0), 1)
        return Color(.sRGB, red: a.r + (b.r - a.r) * t, green: a.g + (b.g - a.g) * t,
                     blue: a.b + (b.b - a.b) * t, opacity: a.a + (b.a - a.a) * t)
    }
}

private extension UIColor {
    var rgba: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}

/// How each kind of challenge reads on screen.
extension ChallengeProgress.Kind {
    var name: String {
        switch self {
        case .activityMinutes: return String(localized: "Activity minutes")
        case .zoneMinutes: return String(localized: "Zone 2 minutes")
        case .steps: return String(localized: "Steps")
        case .bedtime: return String(localized: "Bedtime")
        }
    }

    var symbol: String {
        switch self {
        case .activityMinutes: return "figure.run"
        case .zoneMinutes: return "heart.circle"
        case .steps: return "figure.walk"
        case .bedtime: return "moon.zzz.fill"
        }
    }

    /// The pillar colour it counts toward: activity Strain blue, Zone 2's own zone colour, steps the
    /// favourable teal, bedtime Sleep's blue-grey.
    var color: Color {
        switch self {
        case .activityMinutes: return PulseTheme.strain
        case .zoneMinutes: return PulseTheme.Zone.color(2)
        case .steps: return PulseTheme.positive
        case .bedtime: return PulseTheme.sleep
        }
    }

    /// What the gauge's number counts: "MINUTES LOGGED".
    var unitCaption: String {
        switch self {
        case .activityMinutes: return String(localized: "Minutes logged")
        case .zoneMinutes: return String(localized: "Zone 2 minutes")
        case .steps: return String(localized: "Steps taken")
        case .bedtime: return String(localized: "Nights on time")
        }
    }

    /// What the join page's number is: "MINUTE GOAL".
    var goalCaption: String {
        switch self {
        case .activityMinutes: return String(localized: "Minute goal")
        case .zoneMinutes: return String(localized: "Zone 2 minute goal")
        case .steps: return String(localized: "Step goal")
        case .bedtime: return String(localized: "Night goal")
        }
    }

    /// A target step for the goal stepper, and its range.
    var targetStep: Int {
        switch self {
        case .activityMinutes: return 25
        case .zoneMinutes: return 10
        case .steps: return 5_000
        case .bedtime: return 1
        }
    }

    var targetRange: ClosedRange<Int> {
        switch self {
        case .activityMinutes: return 25...2_000
        case .zoneMinutes: return 10...1_000
        case .steps: return 5_000...500_000
        case .bedtime: return 1...30
        }
    }
}

/// The words a challenge is described with.
enum PulseChallengeText {
    /// "11:00 PM" for a minute after midnight, honouring the clock setting.
    static func clock(minute: Int) -> String {
        let start = Calendar.current.startOfDay(for: Date())
        return PulseFormat.clock(start.addingTimeInterval(TimeInterval(minute * 60)))
    }

    static func target(_ d: ChallengeProgress.Definition) -> String {
        d.kind == .steps ? PulseFormat.grouped(Double(d.target)) : "\(d.target)"
    }

    /// "250 Activity Minutes in 7 Days".
    static func title(_ d: ChallengeProgress.Definition) -> String {
        switch d.kind {
        case .activityMinutes:
            return String(localized: "\(target(d)) Activity Minutes in \(d.days) Days")
        case .zoneMinutes:
            return String(localized: "\(target(d)) Zone 2 Minutes in \(d.days) Days")
        case .steps:
            return String(localized: "\(target(d)) Steps in \(d.days) Days")
        case .bedtime:
            let time = clock(minute: d.bedtimeMinute ?? 23 * 60)
            return d.target == d.days
                ? String(localized: "Asleep by \(time) for \(d.days) Nights")
                : String(localized: "Asleep by \(time) on \(d.target) of \(d.days) Nights")
        }
    }

    /// The bar's title: "250 MINUTE CHALLENGE" (WHOOP: "ALL-IN 250 CHALLENGE").
    static func navTitle(_ d: ChallengeProgress.Definition) -> String {
        switch d.kind {
        case .activityMinutes: return String(localized: "\(target(d)) Minute Challenge")
        case .zoneMinutes: return String(localized: "Zone 2 Challenge")
        case .steps: return String(localized: "Steps Challenge")
        case .bedtime: return String(localized: "Bedtime Challenge")
        }
    }

    /// What counts, in a sentence.
    static func body(_ d: ChallengeProgress.Definition) -> String {
        switch d.kind {
        case .activityMinutes:
            return String(localized: "Log \(target(d)) minutes of activity in \(d.days) days. Every workout counts: ones you start here, add by hand or bring in from Apple Health.")
        case .zoneMinutes:
            return String(localized: "Spend \(target(d)) minutes in heart-rate Zone 2 over \(d.days) days, counted from your strap's heart rate, in a workout or not.")
        case .steps:
            return String(localized: "Take \(target(d)) steps over \(d.days) days, counted from the same steps every ZENO screen shows.")
        case .bedtime:
            return String(localized: "Be asleep by \(clock(minute: d.bedtimeMinute ?? 23 * 60)) on \(d.target) of the next \(d.days) nights. The time your strap saw you fall asleep is the one that counts.")
        }
    }

    /// The amount in the kind's words: "168 minutes", "3 nights", "41,200 steps".
    static func amount(_ value: Double, kind: ChallengeProgress.Kind) -> String {
        let n = Int(value.rounded(.down))
        switch kind {
        case .activityMinutes, .zoneMinutes: return String(localized: "\(n) minutes")
        case .steps: return String(localized: "\(PulseFormat.grouped(Double(n))) steps")
        case .bedtime: return n == 1 ? String(localized: "1 night") : String(localized: "\(n) nights")
        }
    }

    /// The headline under the gauge.
    static func headline(_ s: ChallengeSnapshot) -> String {
        switch s.status.phase {
        case .complete: return String(localized: "Challenge complete")
        case .ended: return String(localized: "Challenge ended")
        case .upcoming: return String(localized: "Starting soon")
        case .running:
            switch s.status.fraction {
            case ..<0.01: return String(localized: "Just getting started")
            case ..<0.5: return String(localized: "Great start!")
            case ..<0.75: return String(localized: "Halfway there")
            default: return String(localized: "Almost there")
            }
        }
    }

    /// The sentence under the headline.
    static func detail(_ s: ChallengeSnapshot) -> String {
        let kind = s.definition.kind
        let logged = amount(s.status.logged, kind: kind)
        let goal = amount(Double(s.definition.target), kind: kind)
        switch s.status.phase {
        case .complete:
            let on = s.status.completedOn.map { YearReviewFormat.shortDate($0) } ?? ""
            return String(localized: "You reached \(goal) on \(on). Strong work, and it keeps counting until the last day.")
        case .ended:
            return String(localized: "You logged \(logged) of \(goal).")
        case .upcoming:
            return String(localized: "It starts on \(YearReviewFormat.shortDate(s.definition.startDay)).")
        case .running:
            let n = Int(s.status.remaining.rounded(.up))
            switch kind {
            case .bedtime:
                return n == 1
                    ? String(localized: "You've been asleep on time for \(logged). 1 more night to go.")
                    : String(localized: "You've been asleep on time for \(logged). \(n) more nights to go.")
            case .steps:
                return String(localized: "You've taken \(logged). \(PulseFormat.grouped(Double(n))) more steps to reach your goal.")
            case .activityMinutes, .zoneMinutes:
                return String(localized: "You've logged \(logged). Log \(n) more minutes to reach your goal.")
            }
        }
    }
}
#endif
