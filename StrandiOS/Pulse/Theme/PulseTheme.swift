#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Pulse theme
//
// Pulse is ZENO's WHOOP-structured iPhone interface. Every colour, size, radius and timing it draws with
// is a token in Theme/, taken from docs/zeno/WHOOP_UI_SPEC.md §2 and docs/zeno/DESIGN_RULES.md (DR):
//
//   PulseTheme.swift     page, surfaces, text, semantic data colours, status tints (this file)
//   PulsePalettes.swift  HR zones, sleep stages, stress scale, menstrual phases, delta chips, plan,
//                        journal, streak and sleep-detail swatches
//   PulseGradients.swift gradients plus the AI, activity-flow, onboarding, tab-bar and coach tokens
//   PulseType.swift      the type scale (SF Pro; numerals bold condensed with tabular digits)
//   PulseLayout.swift    spacing, radii, dial and bar geometry
//   PulseMotion.swift    animation timings and the Reduce Motion rule
//
// The tokens are Pulse's own on purpose: the classic shell keeps `StrandPalette`, and a shared token
// changed here would silently re-colour every classic screen too. Screens and components never write a
// hex value or a font size of their own; when a value is missing, it is added here first.
//
// Pulse is dark only. Depth comes from WHITE overlays on a fixed slate gradient (a card is white 10%, a
// button inside it another 10%), never from solid greys, borders or shadows.

enum PulseTheme {

    // MARK: Page (§2.1 "Page", DR §1.1)

    /// The page gradient, top to bottom. It is viewport-fixed: draw it BEHIND a scroll view
    /// (`PulseBackground`), never inside one, so cards lighten toward the top exactly as WHOOP's do.
    ///
    /// The stops are sampled on 2026 device captures (reviews/r02, completeness-critic/13 and 25,
    /// deep-dives-2026/56: the same values within a level). DR §1.1's #283339 → #1E262B upper half reads
    /// 2–3 levels darker and greener than every 2026 capture; from 0.53 down the two agree. See
    /// ARCHITECTURE.md §9.
    static let pageStops: [Gradient.Stop] = [
        .init(color: Color(hex: "#2A3139"), location: 0.00),
        .init(color: Color(hex: "#262D35"), location: 0.10),
        .init(color: Color(hex: "#22282F"), location: 0.20),
        .init(color: Color(hex: "#1E2327"), location: 0.30),
        .init(color: Color(hex: "#191E22"), location: 0.40),
        .init(color: Color(hex: "#15181D"), location: 0.53),
        .init(color: Color(hex: "#111518"), location: 0.76),
        .init(color: Color(hex: "#0E1213"), location: 1.00),
    ]
    /// The gradient's first stop.
    static let pageTop = Color(hex: "#2A3139")
    /// The gradient's last stop.
    static let pageBottom = Color(hex: "#0E1213")
    /// The near-black page of the Healthspan detail and the 2026 Health tab top, where the age orb's
    /// glow has to read (§2.1 exceptions).
    static let pageNearBlack = Color(hex: "#060607")
    /// The strip under the floating tab bar: the one place a tab root goes (almost) pure black.
    static let barStrip = Color(hex: "#010101")
    /// The bottom scrim's end colour: content fades to this over the `PulseTheme.Layout.scrimHeight`
    /// above the floating tab bar. WHOOP's content is still 35–60% bright at the capsule's top edge
    /// (reviews/r02, completeness-critic/13), so the fade stops at black 60%, not the spec's 95%.
    static let scrim = Color.black.opacity(0.6)

    // MARK: Surfaces (§2.1 "Surfaces", DR §1.2)

    /// Cards, tiles, rows, the dial track, dividers, the chart "today" band.
    static let card = Color.white.opacity(0.10)
    /// The dimmer "Last Night's Sleep" fill: the HOURS OF SLEEP card and its four detail cards only.
    static let detail = Color.white.opacity(0.045)
    /// A surface inside a card (in-card buttons, activity rows, a selected segment): another 10%.
    static let nested = Color.white.opacity(0.10)
    /// Legend wells and segmented-control troughs.
    static let well = Color.black.opacity(0.50)
    /// Chart gridlines drawn on a card.
    static let gridOnCard = Color.white.opacity(0.05)
    /// Chart gridlines drawn straight on the page.
    static let gridOnPage = Color.white.opacity(0.08)
    /// Dashed connectors and secondary series lines.
    static let dash = Color.white.opacity(0.25)
    /// The Strain dial's optimal-range band as it reads on the page: white 27% (#5C6063–#6C7073).
    static let targetBand = Color.white.opacity(0.27)
    /// The band's own fill, drawn OVER the 10% track so the two composite to `targetBand`:
    /// 1 − (1 − 0.10)(1 − 0.19) ≈ 0.27.
    static let targetBandOverTrack = Color.white.opacity(0.19)
    /// The disc a dial's interior fills with while it is pressed.
    static let pressDisc = Color.white.opacity(0.40)
    /// A dial's full-circle track and the empty part of a bar. Same width as the arc it sits under.
    static let track = Color.white.opacity(0.10)
    /// Row dividers and hairlines (1 pt).
    static let divider = Color.white.opacity(0.10)
    /// The coaching card, a shade darker than a standard card.
    static let coachingCard = Color.white.opacity(0.075)
    /// The second coaching card peeking out under the first.
    static let coachingPeek = Color(hex: "#1B1F22")
    /// The pure-black well behind the status banners and the new-member "Ask a question" well.
    static let bannerWell = Color.black
    /// Opaque fallbacks for a card, only where an overlay is impossible (top / middle / lower third).
    static let cardSolidTop = Color(hex: "#2D3236")
    static let cardSolidMiddle = Color(hex: "#2B2F33")
    static let cardSolidBottom = Color(hex: "#292C2E")

    // MARK: Lists and chrome surfaces (§2.6 items 22, 23, 30, 35, 36)

    /// More / settings row cards (2026), top and bottom of their vertical gradient.
    static let rowCardTop = Color(hex: "#2D3035")
    static let rowCardBottom = Color(hex: "#292D30")
    /// The 28 pt outline icon at the left of a More row.
    static let rowIcon = Color(hex: "#6C7074")
    /// A More row's optional sub-line.
    static let rowSubline = Color(hex: "#BCBCC0")
    /// UPPERCASE list section headers ("ACCOUNT & SETTINGS").
    static let listSectionHeader = Color(hex: "#C4C4C4")
    /// The row card with a subtitle (Behavior Insights compact row).
    static let subtitleRowCard = Color(hex: "#282C2C")
    static let subtitleRowIcon = Color(hex: "#999DA0")
    static let subtitleRowText = Color(hex: "#C8C9CB")
    /// The deep-dive achievement chip: a capsule darker than the page behind the bar (WHOOP's samples #1A1F23
    /// on a #262D35 page, deep-dives-2026/17b, /57).
    static let achievementChip = Color(hex: "#1A1F23")
    /// A pre-added activity's outlined chip: a faint fill and a thin grey border.
    static let preAddedChip = Color.white.opacity(0.04)
    static let preAddedChipBorder = Color.white.opacity(0.30)
    /// A small tag's fill ("BETA", "NEW").
    static let tagFill = Color.white.opacity(0.12)
    /// The inactive segments of the Poor / Sufficient / Optimal mini bar.
    static let segmentOff = Color.white.opacity(0.12)
    /// The typical-range band behind a Trend View line and its legend swatch.
    static let typicalBand = Color.white.opacity(0.08)
    static let typicalSwatch = Color.white.opacity(0.25)
    /// The typical-range box over a zone, stage or level bar: a white 10% veil over bar and track alike
    /// (help-center/82: #479AC2 → #5AA4C7 on the bar; deep-dives-2026/15: the stripes show through).
    static let typicalBox = Color.white.opacity(0.10)
    /// The hatched track's stripes (the empty part of zone, stage and stress-level bars): white 10% over the
    /// card, as WHOOP's #35393B stripes on its #1E2326 card (deep-dives-2026/14, /15), not the spec's 7%.
    static let hatch = Color.white.opacity(0.10)
    /// A chart's dashed average line and the "AVG." pill.
    static let averageLine = Color.white.opacity(0.8)
    /// The contributor callout's radial glow at its pointer and its top-lit 1 pt rim.
    static let calloutGlow = Color.white.opacity(0.10)
    static let calloutRim = Color.white.opacity(0.08)
    /// Filter chips: unselected fill (selected is white with black text).
    static let filterChip = Color(hex: "#363D45")
    /// The wheel-picker sheet and its selection band; a CONFIRM button while invalid.
    static let wheelSheet = Color(hex: "#182023")
    static let wheelBand = Color(hex: "#26292E")
    static let buttonInvalid = Color(hex: "#424649")
    /// Centred dialog cards, top and bottom of their gradient, over black (85%: the unlock scrim's).
    static let dialogTop = Color(hex: "#27343C")
    static let dialogBottom = Color(hex: "#1B2228")
    static let dialogScrim = Color.black.opacity(0.85)
    /// The dashed border of the coaching stack's error box and its grey text.
    static let errorBoxBorder = Color(hex: "#30383C")
    static let errorBoxText = Color(hex: "#888C90")
    /// The 1 pt border of an outlined (locked) card.
    static let outlinedBorder = Color.white.opacity(0.18)
    /// The plain Get Started card (every card after the first, gradient-bordered one).
    static let getStartedPlain = Color(hex: "#1D2124")
    /// The date pager's outer capsule: white ≈5% on the page (#30383B on the page top, reviews/r41).
    static let pagerCapsule = Color.white.opacity(0.05)
    /// The date pager's inner pill, drawn ON the outer capsule: another 10%, ≈14.5% in all (#454C54).
    static let pagerPill = Color.white.opacity(0.10)
    /// The Home streak pill under the avatar: the same white 5% as the pager's capsule (#30383B).
    static let streakPill = Color.white.opacity(0.05)
    /// The avatar's fallback disc when there is no photo and no name (a person outline on it).
    static let avatarFallback = Color.white.opacity(0.10)
    /// Skeleton blocks while a screen loads (DR §8): white 10%, no shimmer.
    static let skeleton = Color.white.opacity(0.10)
    /// The white 1.5 pt strap outline in the Home header and its status dot's teal.
    static let strapOutline = Color.white
    /// The battery figure beside the strap glyph: white ≈60% (#AAAFB3 on reviews/r41).
    static let batteryText = Color.white.opacity(0.60)
    /// The "✕" square the action-menu "+" morphs into.
    static let menuCloseSquare = Color(hex: "#2E3236")
    /// The Weekly Trends highlight column behind the latest day.
    static let chartHighlight = Color(hex: "#44484C")
    /// "SYNCED TO 7:32AM" and its check in the DATA CAUGHT UP banner.
    static let syncedTeal = Color(hex: "#00EC9C")
    /// The action popover, top and bottom of its vertical gradient, and the dim behind it.
    static let menuTop = Color(hex: "#464D56")
    static let menuBottom = Color(hex: "#32383D")
    static let menuDim = Color(hex: "#14171C").opacity(0.55)

    // MARK: Text (§2.1 "Text", DR §1.3)

    static let textPrimary = Color.white
    /// Text on in-card buttons.
    static let textButton = Color.white.opacity(0.85)
    static let textSecondary = Color.white.opacity(0.70)
    /// Chevrons, baselines, axis labels, inactive tabs.
    static let textTertiary = Color.white.opacity(0.50)
    static let textDisabled = Color.white.opacity(0.40)

    // MARK: Semantic data colours (§2.1, DR §1.4). One meaning per hue; data only, never large surfaces.

    /// Recovery 67–100%.
    static let recoveryHigh = Color(hex: "#16EC06")
    /// Recovery 34–66%.
    static let recoveryMid = Color(hex: "#FFDE00")
    /// Recovery 0–33% on arcs and bars.
    static let recoveryLow = Color(hex: "#FF0026")
    /// Recovery-red TEXT and "VERY ELEVATED": the brand red fails 4.5:1 on a card, this passes.
    static let recoveryLowText = Color(hex: "#FF4A5C")
    /// Strain and activities.
    static let strain = Color(hex: "#0093E7")
    /// Sleep, sleep chips, the Sleep dial.
    static let sleep = Color(hex: "#7BA1BB")
    /// Neutral data, outline buttons, LOW stress, light-strain chips.
    static let recoveryBlue = Color(hex: "#67AEE6")
    /// Recovery activities (sauna, meditation, breathwork): the pre-start HR circle.
    static let recoveryActivity = Color(hex: "#7EB2EB")
    /// Recovery activities: the Home activity chip.
    static let recoveryActivityChip = Color(hex: "#79ACE1")
    /// Favourable: ▲▼ that are good, Optimal, Within range, plan progress, primary CTA.
    static let positive = Color(hex: "#00F19F")
    /// Unfavourable: ▲▼ that are bad, Poor, ALARM OFF, HIGH stress, out of range.
    static let negative = Color(hex: "#FFA722")
    /// No meaningful change: grey ▲ / ●.
    static let neutral = Color.white.opacity(0.50)
    /// The "Sufficient" segment and dash.
    static let sufficient = Color(hex: "#848586")
    /// The grey ● that replaces an arrow when today equals the baseline.
    static let baselineDot = Color(hex: "#8C8C90")

    /// A Recovery band's colour for arcs, bars and fills.
    static func recovery(_ band: PulseDisplay.RecoveryBand) -> Color {
        switch band {
        case .green: return recoveryHigh
        case .yellow: return recoveryMid
        case .red: return recoveryLow
        }
    }

    /// A Recovery band's colour for TEXT (red swaps to its legible variant).
    static func recoveryText(_ band: PulseDisplay.RecoveryBand) -> Color {
        band == .red ? recoveryLowText : recovery(band)
    }

    /// The colour of a Recovery percentage, judged on the whole percent a dial prints.
    static func recovery(percent: Double) -> Color {
        recovery(PulseDisplay.recoveryBand(percent: percent))
    }

    // MARK: Status tints (§2.1 "Status tints": 24 pt badge squares and chips)

    /// A status badge or chip's fill and the glyph colour it pairs with.
    enum Tint: CaseIterable {
        case teal, red, blue, orange, orangeHigh, grey

        /// The square's or chip's fill.
        var fill: Color {
            switch self {
            case .teal: return Color(hex: "#224A41")
            case .red: return Color(hex: "#4C2B34")
            case .blue: return Color(hex: "#354550")
            case .orange: return Color(hex: "#493F2D")
            case .orangeHigh: return Color(hex: "#4E402F")
            case .grey: return Color.white.opacity(0.10)
            }
        }

        /// The ✓, "!", "–" or number drawn on it.
        var glyph: Color {
            switch self {
            case .teal: return PulseTheme.positive
            case .red: return PulseTheme.recoveryLowText
            case .blue: return PulseTheme.recoveryBlue
            case .orange: return PulseTheme.negative
            case .orangeHigh: return Color(hex: "#FCA820")
            case .grey: return PulseTheme.textTertiary
            }
        }
    }

    // MARK: Interface chrome

    /// The tint for system controls inside Pulse (back chevrons, default buttons): white, like WHOOP's.
    static let chromeTint = Color.white
    /// Interactive emphasis in data contexts (the primary CTA colour). Same hue as `positive`.
    static let accent = positive
    /// Ink placed ON an `accent` fill.
    static let onAccent = Color(hex: "#04140E")

    // MARK: Compatibility names
    //
    // The first Pulse screens were written against these names. They now resolve to the tokens above so
    // those screens restyle with the theme; new code uses the names above.

    static let backgroundTop = pageTop
    static let backgroundBottom = pageBottom
    static let cardRaised = nested
    static let hairline = divider
    static let recoveryGreen = recoveryHigh
    static let recoveryYellow = recoveryMid
    static let recoveryRed = recoveryLow
    static let recoveryRedText = recoveryLowText
    /// A value outside its typical range (orange, the spec's "out of range").
    static let attention = negative
}
#endif
