#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Data palettes (WHOOP_UI_SPEC §2.1)
//
// Each palette is a namespace on `PulseTheme`, so a call site reads as the thing it colours:
// `PulseTheme.Zone.color(3)`, `PulseTheme.Stage.color(.rem)`, `PulseTheme.Stress.color(for: 1.4)`.

extension PulseTheme {

    // MARK: Heart-rate zones (sampled; replaces ZENO's old zone colours)

    enum Zone {
        /// Zone 0 (restorative) to Zone 5, in order.
        static let all: [Color] = [
            Color(hex: "#FFFFFF"),
            Color(hex: "#ADC2CD"),
            Color(hex: "#479AC2"),
            Color(hex: "#59B996"),
            Color(hex: "#FCAC5D"),
            Color(hex: "#FF6422"),
        ]

        /// The colour of zone `number`, clamped to 0...5.
        static func color(_ number: Int) -> Color {
            all[max(0, min(5, number))]
        }

        /// The dark tint an inactive segment of a live zone bar takes (§2.5 "Live HR zone bar").
        static func dimmed(_ number: Int) -> Color {
            color(number).opacity(0.28)
        }
    }

    /// Zone 1 to 5 (the order the first Pulse screens index from).
    static var zones: [Color] { Array(Zone.all.dropFirst()) }

    /// The colour of zone `number` (0...5).
    static func zone(_ number: Int) -> Color { Zone.color(number) }

    // MARK: Sleep stages (sampled from help-center/79, whoop-site/52, deep-dives-2026/15)

    enum Stage {
        static let awake = Color(hex: "#CBCBCB")
        static let light = Color(hex: "#A4A3F1")
        /// SWS (deep).
        static let deep = Color(hex: "#FA96F9")
        static let rem = Color(hex: "#AC5AED")
        /// The "Restorative" swatch is a diagonally split square: this pink top-left…
        static let restorativePink = Color(hex: "#FA95FA")
        /// …and this purple bottom-right.
        static let restorativePurple = Color(hex: "#AC58EC")

        static func color(_ stage: SleepStage) -> Color {
            switch stage {
            case .awake: return awake
            case .light: return light
            case .deep: return deep
            case .rem: return rem
            }
        }
    }

    /// A sleep stage's colour.
    static func stage(_ stage: SleepStage) -> Color { Stage.color(stage) }

    // MARK: Sleep detail cards (gap-1 §5)

    enum SleepDetail {
        static let healthyMinimum = Color(hex: "#484C50")
        static let recentStrain = PulseTheme.strain
        static let sleepDebt = Color(hex: "#C8C8C8")
        static let latency = Color(hex: "#C8C8C8")
        static let wakeEvents = Color(hex: "#CCCCCC")
        /// Efficiency card: long awake blocks (short wakes are white ticks).
        static let awakeBlock = Color(hex: "#CACECD")
        /// Consistency card: past nights' bars; last night's bar is `PulseTheme.sleep`.
        static let consistencyPast = Color(hex: "#606468")
        /// Consistency callout pill fill (its text is sleep blue).
        static let consistencyCallout = Color(hex: "#101418")
        /// The optimal bed- and wake-time dashed curves.
        static let optimalDash = Color(hex: "#A1A5A6")
        /// The hours bar runs card colour → this → sleep blue (solid for the last third).
        static let hoursBarMid = Color(hex: "#4C5C6C")
        /// The need-breakdown notched well, and the card it sits in.
        static let needWell = Color(hex: "#1C2024")
        static let needWellCard = Color(hex: "#2C343C")
    }

    // MARK: Stress (sampled along the gauge in appstore/ios69-10)

    enum Stress {
        /// The scale's stops, LOW (0.0) to HIGH (3.0), at their positions along the 0–3 axis.
        static let stops: [Gradient.Stop] = [
            .init(color: Color(hex: "#67AEE6"), location: 0.00),
            .init(color: Color(hex: "#5FB3E1"), location: 0.27),
            .init(color: Color(hex: "#01F19F"), location: 0.41),
            .init(color: Color(hex: "#00F19F"), location: 0.59),
            .init(color: Color(hex: "#E0B031"), location: 0.77),
            .init(color: Color(hex: "#FFA722"), location: 1.00),
        ]
        static let low = Color(hex: "#67AEE6")
        static let medium = Color(hex: "#00F19F")
        static let high = Color(hex: "#FFA722")
        /// The HIGH value chip's fill and text (§3.1 item 6).
        static let highChipFill = Color(hex: "#4E402F")
        static let highChipText = Color(hex: "#FCA820")

        /// The bottom-to-top gradient a value-coloured stress line uses (colour follows y).
        static var verticalGradient: LinearGradient {
            LinearGradient(stops: stops, startPoint: .bottom, endPoint: .top)
        }

        enum Level: CaseIterable {
            case low, medium, high

            /// LOW 0.0–0.9, MEDIUM 1.0–1.9, HIGH 2.0–3.0.
            init(value: Double) {
                if value >= 2.0 { self = .high } else if value >= 1.0 { self = .medium } else { self = .low }
            }

            /// The level word's colour.
            var color: Color {
                switch self {
                case .low: return Stress.low
                case .medium: return Stress.medium
                case .high: return Stress.high
                }
            }

            /// The value chip's tint on the Stress Monitor tile.
            var tint: PulseTheme.Tint {
                switch self {
                case .low: return .blue
                case .medium: return .teal
                case .high: return .orangeHigh
                }
            }
        }

        /// The scale's colour at `value` (0...3), interpolated between the sampled stops.
        static func color(for value: Double) -> Color {
            let t = max(0, min(1, value / 3.0))
            let hexes: [(Double, (Double, Double, Double))] = [
                (0.00, (0x67, 0xAE, 0xE6)), (0.27, (0x5F, 0xB3, 0xE1)), (0.41, (0x01, 0xF1, 0x9F)),
                (0.59, (0x00, 0xF1, 0x9F)), (0.77, (0xE0, 0xB0, 0x31)), (1.00, (0xFF, 0xA7, 0x22)),
            ]
            for i in 1..<hexes.count where t <= hexes[i].0 {
                let (t0, a) = hexes[i - 1]
                let (t1, b) = hexes[i]
                let f = t1 > t0 ? (t - t0) / (t1 - t0) : 0
                return Color(.sRGB,
                             red: (a.0 + (b.0 - a.0) * f) / 255,
                             green: (a.1 + (b.1 - a.1) * f) / 255,
                             blue: (a.2 + (b.2 - a.2) * f) / 255,
                             opacity: 1)
            }
            return high
        }
    }

    // MARK: Menstrual phases (§2.1 "Menstrual phase colours"); symptoms are a white dot

    enum Menstrual {
        enum Phase: CaseIterable {
            case menstrual, follicular, ovulatory, luteal

            var dot: Color {
                switch self {
                case .menstrual: return Color(hex: "#FF7765")
                case .follicular: return Color(hex: "#A4A3F1")
                case .ovulatory: return Color(hex: "#479AC2")
                case .luteal: return Color(hex: "#AC5AED")
                }
            }

            /// The calendar band for the current cycle (luteal's future days use `lutealFuture`).
            var band: Color {
                switch self {
                case .menstrual: return Color(hex: "#BB5B4F")
                case .follicular: return Color(hex: "#5A5C84")
                case .ovulatory: return Color(hex: "#2C586D")
                case .luteal: return Color(hex: "#8047AE")
                }
            }
        }

        static let lutealFuture = Color(hex: "#5E3882")
        /// The page header tint during the menstrual phase, top to bottom.
        static let headerMenstrual: [Color] = [
            Color(hex: "#693A35"), Color(hex: "#4E2F2C"), Color(hex: "#2A2021"), Color(hex: "#101518"),
        ]
        /// The page header tint during the luteal phase.
        static let headerLuteal: [Color] = [Color(hex: "#40295B"), Color(hex: "#231D31")]
        /// The Home card's fill and its "+ LOG CYCLE" button.
        static let homeCard = Color(hex: "#2F3239")
        static let logButton = Color(hex: "#41444B")
    }

    // MARK: Trend View delta chips (§2.7 "Delta chip colours"; radius 4, 11 pt Bold)

    enum Delta {
        static let favourableText = Color(hex: "#00F9A5")
        static let favourableFill = Color(hex: "#144038")
        static let unfavourableText = Color(hex: "#F4B04F")
        static let unfavourableFill = Color(hex: "#3C3424")
        /// Recovery, Day Strain and Calories in every capture, and "● 0%".
        static let neutralText = Color(hex: "#C2C4C6")
        static let neutralFill = Color(hex: "#30383C")
    }

    // MARK: Impact bars (§2.6 item 20)

    enum Impact {
        static let helps = Color(hex: "#00F0A0")
        static let hurts = Color(hex: "#FCA420")
        static let notSignificant = Color(hex: "#949498")
        /// The hatched track's stripes behind the bar.
        static let hatch = Color(hex: "#44484C")
    }

    // MARK: My Plan (§3.1 item 9, §2.5 "Plan goal counters")

    enum Plan {
        static let collapsedCard = Color(hex: "#2C3034")
        static let expandedCard = Color(hex: "#384040")
        static let emptyCard = Color(hex: "#303438")
        static let viewButton = Color(hex: "#404848")
        static let progress = Color(hex: "#6CE8A2")
        static let progressTrack = Color(hex: "#404448")
        /// A met goal ring.
        static let goalMet = Color(hex: "#0CE8A0")
        /// "EXPLORE PLANS →".
        static let exploreCTA = Color(hex: "#78AAE4")
    }

    // MARK: Journal (§3.1 item 8d, §2.6 item 21, §2.7 "Logging History")

    enum Journal {
        /// Logged day: filled circle with a black ✓.
        static let logged = Color(hex: "#64F3A6")
        /// Today (or the selected past day) not logged yet: filled circle with a 2 pt white ring.
        static let todayPending = Color(hex: "#707478")
        /// Not logged: a white-40% ring.
        static let notLogged = Color.white.opacity(0.40)
        /// The full-width "BEHAVIOR INSIGHTS" button.
        static let insightsButton = Color(hex: "#484C50")
        /// Answer toggles: ✓ selected fill, unselected fill on a dark card and on a purple card.
        static let toggleYes = Color(hex: "#67ADE8")
        static let toggleUnselected = Color(hex: "#3D4144")
        static let toggleUnselectedOnPurple = Color(hex: "#594F81")
        /// Logging History dots and the month "✓ n" chip.
        static let historyYes = Color(hex: "#78ACE0")
        static let historyNo = Color(hex: "#88888C")
        static let historyChip = Color(hex: "#202C34")
    }

    // MARK: Day streak flame (§1.4; the orange and magenta cut-offs are unconfirmed)

    enum Streak {
        /// The flame's colour for a streak of `days`.
        static func flame(days: Int) -> Color {
            switch days {
            case ..<100: return Color(hex: "#FFC93C")
            case ..<180: return Color(hex: "#FF8A2A")
            case ..<365: return Color(hex: "#FF3B30")
            case ..<1000: return Color(hex: "#F0306E")
            case ..<2000: return Color(hex: "#3D8BFF")
            default: return Color(hex: "#E8C25A")
            }
        }

        /// The blue core of the 180–364 day flame.
        static let redTierCore = Color(hex: "#3D8BFF")
    }

    // MARK: Healthspan orb (§2.1 "Healthspan orb"; ZENO draws its own art)

    enum Healthspan {
        static let youngerParticles = Color(hex: "#00ECAE")
        static let youngerRim = Color(hex: "#05B576")
        static let youngerInterior = Color(hex: "#005434")
        static let unlockingParticles = Color(hex: "#9854A4")
        static let unlockingRim = Color(hex: "#C050D0")
        static let unlockingInterior = Color(hex: "#54585B")
    }

    // MARK: Levels (§2.5 "Levels progress")

    enum Levels {
        static let barStart = Color(hex: "#BCBDBF")
        static let barEnd = Color(hex: "#FCFCFC")
        static let barTrack = Color(hex: "#161920")
    }
}
#endif
