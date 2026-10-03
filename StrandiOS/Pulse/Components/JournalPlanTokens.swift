#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Journal and Plan tokens (WHOOP_UI_SPEC §3.17–3.19)
//
// The values the journal-plan group's screens draw with that the shared theme does not carry. They live in
// the group's own file so the screens never write a hex value, a font size or a radius of their own; the
// foundation can hoist any of them into Theme/ without a call site changing (`PulseTheme.JournalPlan.…`).
//
// Every colour was sampled on the 2026 device captures the spec cites (journal-plan-2026/07, 95, 20, 26,
// 28, 29; completeness-critic/21, 23; reviews/r11), and every size measured on them.

extension PulseTheme {

    enum JournalPlan {

        // MARK: Journal page (§3.17)

        /// The Journal's backgrounds are a fixed ≈520 pt gradient that ends in `pageBottom`, whatever the
        /// screen's height: journal-plan-2026/07 (956 pt tall) and /95 (932 pt) both reach #101518 at
        /// 520 pt. `Gradients.journalToday` / `journalPastDay` place their stops as fractions of the height
        /// (the sand flat from 36%), which ends it ≈200 pt early on a 16 Pro, so these keep the colours and
        /// move the stops to where the captures put them.
        static let pageGradientHeight: CGFloat = 520
        static let pageBottom = Color(hex: "#101518")
        /// Today: warm sand → slate → near black (journal-plan-2026/95, sampled every 20 pt).
        static let todayStops: [Gradient.Stop] = [
            .init(color: Color(hex: "#CEB18F"), location: 0.00),
            .init(color: Color(hex: "#BCA78C"), location: 60 / 520),
            .init(color: Color(hex: "#AE9F8C"), location: 100 / 520),
            .init(color: Color(hex: "#949188"), location: 160 / 520),
            .init(color: Color(hex: "#848580"), location: 200 / 520),
            .init(color: Color(hex: "#747877"), location: 240 / 520),
            .init(color: Color(hex: "#626A6D"), location: 280 / 520),
            .init(color: Color(hex: "#525D63"), location: 320 / 520),
            .init(color: Color(hex: "#424F57"), location: 360 / 520),
            .init(color: Color(hex: "#354046"), location: 400 / 520),
            .init(color: Color(hex: "#293237"), location: 440 / 520),
            .init(color: Color(hex: "#1B2326"), location: 480 / 520),
            .init(color: Color(hex: "#101518"), location: 1.00),
        ]
        /// A past day: purple → near black (journal-plan-2026/07).
        static let pastDayStops: [Gradient.Stop] = [
            .init(color: Color(hex: "#402D7C"), location: 0.00),
            .init(color: Color(hex: "#3C2B72"), location: 60 / 520),
            .init(color: Color(hex: "#342866"), location: 120 / 520),
            .init(color: Color(hex: "#2E2459"), location: 180 / 520),
            .init(color: Color(hex: "#27224B"), location: 240 / 520),
            .init(color: Color(hex: "#221E3F"), location: 300 / 520),
            .init(color: Color(hex: "#1C1C38"), location: 360 / 520),
            .init(color: Color(hex: "#18192B"), location: 420 / 520),
            .init(color: Color(hex: "#13161F"), location: 480 / 520),
            .init(color: Color(hex: "#101518"), location: 1.00),
        ]

        /// A behaviour row card: white 10% over the page (#443C6F on the purple top, #282C2F at the bottom).
        static let rowCard = Color.white.opacity(0.10)
        /// A behaviour row: 64 pt with a one-line question, 12 pt apart (rows sit on a 76 pt pitch).
        static let rowHeight: CGFloat = 64
        static let rowGap: CGFloat = 12
        /// The ✕ / ✓ squares: 32 pt, 8 pt apart, 16 pt from the card's right edge.
        static let toggleSize: CGFloat = 32
        static let toggleGap: CGFloat = 8
        /// An unselected square: another ≈10% white on the card, so it follows the theme under it.
        static let toggleIdle = Color.white.opacity(0.10)
        /// ✕ selected: a white square with a black ✕. ✓ selected: `Journal.toggleYes` with a near-black ✓.
        static let toggleNo = Color.white
        static let toggleGlyphOnSelected = Color(hex: "#0B0E10")
        /// A follow-up's value capsule: idle on translucent grey, filled blue with black bold text
        /// (journal-plan-2026/08).
        static let followUpIdle = Color.white.opacity(0.12)
        static let followUpFilled = Color(hex: "#78ACE0")
        /// "Add a note…": darker than the page, a 1 pt border.
        static let notesFill = Color(hex: "#080C10")
        static let notesBorder = Color(hex: "#202428")
        /// SAVE JOURNAL: an off-white capsule, 48 pt, 23.5 pt from the screen edges, its bottom 39 pt above
        /// the screen's (journal-plan-2026/07); content fades out over the 40 pt above it.
        static let saveCapsule = Color(hex: "#F9F9F9")
        static let saveHeight: CGFloat = 48
        static let saveSideMargin: CGFloat = 23.5
        static let saveFade: CGFloat = 40
        /// The day strip's capsules (white 12%; the selected one ringed 2 pt white) and the date row's
        /// outlined "TODAY" pill.
        static let dayCapsule = Color.white.opacity(0.12)
        static let dayCapsuleHeight: CGFloat = 84
        static let dayCapsuleGap: CGFloat = 8
        static let todayPillBorder = Color.white.opacity(0.35)
        /// "DAYTIME", "NOTES", "YOUR CUSTOM PLAN": white 50% caps and their hairline.
        static let sectionLabel = Color.white.opacity(0.50)
        static let sectionRule = Color.white.opacity(0.12)
        /// The calendar sheet (help-center/105: #1D2226) and its days still to come.
        static let calendarSheet = Color(hex: "#1D2226")
        static let calendarFuture = Color.white.opacity(0.2)
        /// The "USE PREVIOUS ANSWERS" switch's on tint.
        static let switchOn = Color(hex: "#67ADE8")

        // MARK: SELECT BEHAVIORS (§3.17b)

        /// The full-height sheet's gradient, its search field and the checkbox.
        static let selectSheetTop = Color(hex: "#283840")
        static let selectSheetBottom = Color(hex: "#182028")
        static let searchField = Color(hex: "#10181C")
        static let checkbox = Color(hex: "#64ACE4")
        static let checkboxGlyph = Color(hex: "#0E1A24")
        static let checkboxSize: CGFloat = 24
        /// The outlined "Custom" chip.
        static let customChipBorder = Color.white.opacity(0.55)

        // MARK: Behavior Insights and Details (§3.18)

        /// A tested behaviour's card (completeness-critic/21: #303438), and the ✧ chip after an
        /// auto-tracked name (#344048).
        static let insightsCard = Color(hex: "#303438")
        static let insightsCardGap: CGFloat = 8
        static let autoChip = Color(hex: "#344048")
        static let autoChipGlyph = Color(hex: "#8CC4F2")
        /// Behavior Details: the page under the hero (#101418), the impact card over it, the expanded
        /// breakdown's inner card (#14181C), the grey body copy and the RECOMMENDATION box.
        static let detailsPage = Color(hex: "#101418")
        static let detailsImpactCard = Color.white.opacity(0.08)
        static let detailsBreakdown = Color(hex: "#14181C")
        static let detailsBody = Color(hex: "#C5C6CA")
        static let recommendationBox = Color(hex: "#202C34")
        static let recommendationText = Color(hex: "#8EB4DF")
        /// Verdict chips: "Negative" (#584830 / #EAB977), "Positive" (green tint), "Not significant".
        static let verdictNegativeFill = Color(hex: "#584830")
        static let verdictNegativeText = Color(hex: "#EAB977")
        static let verdictPositiveFill = Color(hex: "#2C4A3E")
        static let verdictPositiveText = Color(hex: "#6EE7B0")
        static let verdictNeutralFill = Color.white.opacity(0.10)
        static let verdictNeutralText = Color.white.opacity(0.70)
        /// The hero behind a behaviour's name: a soft glow fading into the page (no stock photos, [Z]).
        static let heroGlow = Color(hex: "#2F4150")
        static let heroSymbol = Color.white.opacity(0.10)
        static let heroHeight: CGFloat = 300
        /// The "✕ 5 / ✓ 11" count squares and the KEEP LOGGING count badges.
        static let countBorder = Color.white.opacity(0.9)
        static let countBorderDim = Color.white.opacity(0.35)

        // MARK: Plan (§3.19, §3.1 item 9)

        /// Plan Overview's section labels (#A0A5A8) and its goal cards.
        static let planSectionLabel = Color(hex: "#A0A5A8")
        static let planCard = Color(hex: "#30363A")
        /// Edit Plan's template cards: a tint lit from the top-right corner over a dark base (reviews/r11).
        static let templateBase = Color(hex: "#202427")
        static let boostFitnessTint = Color(hex: "#4B3025")
        static let boostFitnessTitle = Color(hex: "#F96B24")
        static let feelBetterTint = Color(hex: "#2E413D")
        static let feelBetterTitle = Color(hex: "#66B796")
        static let sleepDeeperTint = Color(hex: "#333D46")
        static let sleepDeeperTitle = Color(hex: "#7A9CB7")
        static let currentPlanCard = Color(hex: "#34393D")
        static let customPlanCard = Color(hex: "#2A2E31")
        /// The BEHAVIOR GOAL editor (journal-plan-2026/30): its page, the selected card, suggestion cards,
        /// and the 1–7 day buttons (selected blue with dark text).
        static let editorPage = Color(hex: "#101418")
        static let editorSelectedCard = Color(hex: "#2C3438")
        static let editorSuggestionCard = Color(hex: "#282C34")
        static let dayButton = Color.white.opacity(0.10)
        static let dayButtonSelected = Color(hex: "#64ACE4")
        static let dayButtonSize: CGFloat = 36
        /// A metric goal's dashed GOAL line and its pill.
        static let goalLine = Color.white.opacity(0.85)
        /// MY WEEK RECAP's notched card.
        static let recapCard = Color(hex: "#1E2327")

        // MARK: Type the shared scale does not carry

        /// The day strip's date number: 20 pt Bold condensed (fixed, it lives in a fixed capsule).
        static let dayNumber = PulseType.numeral(20)
        /// A follow-up capsule's filled value ("15 Minutes"), 15 pt Bold condensed.
        static let followUpValue = PulseType.numeral(15)
        /// The impact value's small "%" beside a 30 pt number.
        static let impactUnit = PulseType.numeral(17)
        /// A count square's number ("51") and a recap's "44" headline.
        static let countNumber = PulseType.numeral(13)
        static let recapPercent = PulseType.numeral(22)
        /// A plan goal card's progress figures ("0:57:01").
        static let goalFigure = PulseType.numeral(20)
        /// The hero's watermark glyph on Behavior Details, and MY WEEK RECAP's target art.
        static let heroSymbolFont = Font.system(size: 150, weight: .ultraLight)
        static let recapArtFont = Font.system(size: 44, weight: .light)
        static let recapArtSize: CGFloat = 150
        /// A metric goal chart's value labels and its GOAL pill's corners.
        static let chartValue = PulseType.numeral(12)
        static let goalPillRadius: CGFloat = 3
        /// The ✕ / ✓ glyphs in a 32 pt square.
        static let toggleGlyph = Font.system(size: 13, weight: .bold)
        static let checkGlyph = Font.system(size: 13, weight: .bold)
        static let smallGlyph = Font.system(size: 11, weight: .bold)
        static let rowGlyph = Font.system(size: 20, weight: .light)
    }
}
#endif
