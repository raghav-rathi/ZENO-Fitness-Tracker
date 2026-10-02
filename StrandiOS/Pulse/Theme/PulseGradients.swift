#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Gradients and feature tokens (WHOOP_UI_SPEC §2.1 "Gradients", "Activity-flow", "Onboarding")
//
// Gradients are only for the time-of-day pills, AI/coach accents, the stress scale and the few feature
// surfaces listed here (DR §9). Each is a `Gradient` so the caller picks the geometry:
// `LinearGradient(gradient: PulseTheme.Gradients.aiText, startPoint: .leading, endPoint: .trailing)`.

extension PulseTheme {

    enum Gradients {
        // AI / Coach. ONLY coach content uses these.

        /// Coach CTA text ("BREAK DOWN MY RECOVERY →"), drawn leading → trailing.
        static let aiText = Gradient(colors: [Color(hex: "#8371FF"), Color(hex: "#6E9AFF"), Color(hex: "#5FB5FE")])
        /// The "→" after a coach CTA.
        static let aiArrow = Color(hex: "#5FB9FF")
        /// The insight card's 1.5 pt border.
        static let aiBorder = Gradient(colors: [Color(hex: "#4D3D8C"), Color(hex: "#31738C")])
        /// The coach composer's border.
        static let aiInputBorder = Gradient(colors: [Color(hex: "#8A62FF"), Color(hex: "#50D3FF")])
        /// The ring around the coach monogram (button, avatar, summary pill).
        static let aiRing = Gradient(colors: [Color(hex: "#8371FF"), Color(hex: "#5FB5FE")])

        // Time-of-day pills (§2.6 item 6), horizontal.

        /// "Your Daily Outlook" (device capture, Sep 2026).
        static let pillMorning = Gradient(colors: [Color(hex: "#887D6F"), Color(hex: "#374957")])
        static let pillMorningChevron = Color(hex: "#E8D3A9")
        /// "Your Day In Review".
        static let pillEvening = Gradient(colors: [Color(hex: "#2D284D"), Color(hex: "#293F52")])
        static let pillEveningChevron = Color(hex: "#7FB3F9")
        /// A pill once opened: a plain card with a white "›".
        static let pillRead = Color(hex: "#2B3033")

        // Feature borders and fills.

        /// "Your Home Has a New Look"-style promo border (1.5 pt) and its CTA text.
        static let promoBorder = Gradient(colors: [Color(hex: "#D876A9"), Color(hex: "#C343DA")])
        static let promoCTA = Color(hex: "#C14BCC")
        /// The first Get Started card: horizontal border, fill and magenta CTA.
        static let getStartedBorder = Gradient(colors: [
            Color(hex: "#FF9C7E"), Color(hex: "#E38CAE"), Color(hex: "#D579C6"), Color(hex: "#C257E5"), Color(hex: "#B132FB"),
        ])
        static let getStartedFill = Gradient(colors: [Color(hex: "#2A2430"), Color(hex: "#251F2D")])
        static let getStartedCTA = Color(hex: "#C452D0")
        /// "You Asked, We Delivered" feature-announcement cards.
        static let featureAnnounceBorder = Gradient(colors: [Color(hex: "#7C64EC"), Color(hex: "#909CDC"), Color(hex: "#88CCE4")])
        static let featureAnnounceFill = Color(hex: "#202424")
        /// "Introducing achievements".
        static let achievementPromoBorder = Gradient(colors: [Color(hex: "#E3ACA5"), Color(hex: "#B47D76"), Color(hex: "#8A63A4")])

        // AI entry cards (Smart log, Create Custom Behaviors, Share something new).

        static let aiEntryFill = Gradient(colors: [Color(hex: "#282C48"), Color(hex: "#243444"), Color(hex: "#203844")])
        static let aiEntryBorder = Color(hex: "#4A427E")
        static let aiEntryTextButton = Color(hex: "#3C4058")
        static let aiEntryTalkButton = Gradient(colors: [Color(hex: "#344060"), Color(hex: "#2C5064")])
        static let aiEntryMic = Color(hex: "#6BADFE")
        static let aiEntrySparkle = Color(hex: "#68B0FC")

        /// Profile's "MY MEMORY" row.
        static let memoryRow = Gradient(colors: [Color(hex: "#242440"), Color(hex: "#202B3D"), Color(hex: "#1D333E")])

        // Page gradients.

        /// The Journal for today: sand, flat from ≈36% of the height down.
        static let journalToday = Gradient(stops: [
            .init(color: Color(hex: "#CEB18F"), location: 0.00),
            .init(color: Color(hex: "#B3A18D"), location: 0.05),
            .init(color: Color(hex: "#949488"), location: 0.10),
            .init(color: Color(hex: "#787A79"), location: 0.15),
            .init(color: Color(hex: "#545D64"), location: 0.20),
            .init(color: Color(hex: "#2C353E"), location: 0.26),
            .init(color: Color(hex: "#1A1D22"), location: 0.31),
            .init(color: Color(hex: "#111518"), location: 0.36),
            .init(color: Color(hex: "#111518"), location: 1.00),
        ])
        /// The Journal for a past day and the morning prompt: purple.
        static let journalPastDay = Gradient(stops: [
            .init(color: Color(hex: "#402D7C"), location: 0.00),
            .init(color: Color(hex: "#372869"), location: 0.08),
            .init(color: Color(hex: "#252048"), location: 0.18),
            .init(color: Color(hex: "#12161F"), location: 0.32),
            .init(color: Color(hex: "#101518"), location: 1.00),
        ])
        /// The Daily Outlook page.
        static let dailyOutlookPage = Gradient(colors: [Color(hex: "#776E61"), Color(hex: "#232D37"), Color(hex: "#111417")])
        /// The Coach sheet: near black with an indigo glow at the top.
        static let coachSheet = Gradient(colors: [Color(hex: "#1C2438"), Color(hex: "#04080C")])
        static let coachUserBubble = Color(hex: "#343850")
        /// The live activity page.
        static let liveSession = Gradient(colors: [Color(hex: "#2D383E"), Color(hex: "#1A2129"), Color(hex: "#0C1013"), Color(hex: "#181F27")])
        /// Healthspan while it is still unlocking.
        static let healthUnlockGlow = Color(hex: "#4B2151")
        static let healthUnlockCard = Color(hex: "#1C1A27")
        static let healthUnlockBorder = Gradient(colors: [Color(hex: "#604844"), Color(hex: "#AC28FC")])
        static let healthUnlockProgress = Color(hex: "#C450D4")
        static let healthUnlockTrack = Color(hex: "#4C4857")
        /// Achievement Details glows.
        static let achievementGlowActivity = Gradient(colors: [Color(hex: "#393266"), Color(hex: "#275364")])
        static let achievementGlowSleep = Color(hex: "#546575")
        static let achievementGlowOnePercent = Color(hex: "#811C24")
        /// Profile header glow, following a teal avatar (other avatar colours are unconfirmed).
        static let profileGlowTeal = Gradient(colors: [Color(hex: "#3C8C8D"), Color(hex: "#245154"), Color(hex: "#121619")])
        /// Year in Review: page, per-slide glows and the year text.
        static let yearInReviewPage = Color(hex: "#07080D")
        static let yearInReviewGlowRed = Color(hex: "#521117")
        static let yearInReviewGlowIndigo = Color(hex: "#3C3B5A")
        static let yearInReviewGlowGreen = Color(hex: "#2A5237")
        static let yearInReviewYear = Gradient(colors: [Color(hex: "#758FFE"), Color(hex: "#5CBEFF")])
    }

    // MARK: Activity flow (§2.1 "Activity-flow tokens", gap-2 §10)

    enum Activity {
        static let preStartHeader = Color(hex: "#0A0D12").opacity(0.85)
        static let preStartBackdrop = Gradient(colors: [Color(hex: "#293239"), Color(hex: "#0D1114")])
        static let preStartCircleStrain = Color(hex: "#1C90DD")
        static let preStartHaloStrain = Color(hex: "#31648F")
        static let preStartCircleRecovery = Color(hex: "#7EB2EB")
        static let preStartHaloRecovery = Color(hex: "#384A60")
        /// The one light surface in the app: the Start Activity bottom panel.
        static let panelHeader = Color(hex: "#FFFFFF")
        static let panelBody = Color(hex: "#F5F5F5")
        static let panelGrabber = Color(hex: "#E5E5E5")
        static let panelToggleKnob = Color(hex: "#000000")
        static let startCapsule = Color(hex: "#0193E8")
        static let liveBand = Color(hex: "#0193E9")
        static let liveRingTrack = Color(hex: "#333740")
        /// The live strain ring's arc, navy at the tail to bright at the head.
        static let liveRingArc = Gradient(colors: [Color(hex: "#132F5F"), Color(hex: "#025DA4"), Color(hex: "#0082D6")])
        static let mapRoute = Color(hex: "#0A8AF0")
        static let mapStatsPanel = Gradient(colors: [Color(hex: "#0E1215"), Color(hex: "#171E26")])
        static let addSheet = Color(hex: "#1D2429")
        static let editSheet = Gradient(colors: [Color(hex: "#232D32"), Color(hex: "#101517")])
        static let infoBannerFill = Color(hex: "#2E404E")
        static let infoBannerText = Color(hex: "#6F93CB")
        static let validationBannerFill = Color(hex: "#352B1A")
        static let validationBannerText = Color(hex: "#D18D20")
        static let timePillIdle = Color(hex: "#303538")
        static let timePillActive = Color(hex: "#00F29E")
        static let formRow = Color(hex: "#373D42")
        static let saveDisabled = Color(hex: "#282A2E")
        static let selectSheet = Gradient(colors: [Color(hex: "#272E36"), Color(hex: "#13181C")])
        static let searchField = Color(hex: "#161B1F")
        static let searchFocusBorder = Color(hex: "#8D949A")
        static let selectRowCard = Color(hex: "#2F3438")
        static let cardioBar = Color(hex: "#00588A")
        static let muscularBar = Color(hex: "#0193E8")
        static let recoveryHRLine = Color(hex: "#83AAD1")
        static let routeShare = Color(hex: "#171717")
        static let strengthStartOutline = Color(hex: "#60E0B0")
        static let strengthStartPressed = Color(hex: "#05ED95")
        static let strengthActiveTimer = Color(hex: "#00EE93")
    }

    // MARK: Onboarding (§2.1 "Onboarding tokens", gap-3)

    enum Onboarding {
        static let page = Gradient(colors: [Color(hex: "#262D33"), Color(hex: "#1F2428"), Color(hex: "#14171C"), Color(hex: "#111518")])
        static let fieldFill = Color(hex: "#0C1013")
        static let fieldBorder = Color(hex: "#2B3034")
        static let fieldLabel = Color(hex: "#C0C1C5")
        static let subtitle = Color(hex: "#BEC0C2")
        static let validationBorder = Color(hex: "#E9AE54")
        static let validationGlyph = Color(hex: "#F5AB3E")
        static let validationText = Color(hex: "#F9AB3F")
        static let ringTrack = Color(hex: "#282D30")
        /// The ring CTA's arc (round caps, angular gradient).
        static let ringArc = Gradient(colors: [Color(hex: "#65BAFD"), Color(hex: "#58A9EB"), Color(hex: "#4697D9")])
        static let ringDisabledLabel = Color(hex: "#4B4F52")
        static let ringDisabledArrow = Color(hex: "#484D50")
        static let commitGreen = Color(hex: "#00F19D")
        static let pairingFailure = Color(hex: "#D7001F")
        static let errorRing = Color(hex: "#FF0026")
    }

    // MARK: Floating tab bar (§1.1; material fallback because iOS 26 glass is unavailable here)

    enum TabBar {
        /// The capsule's vertical fill, opaque: #252A30 → #191E23 (reviews/r02; completeness-critic/13
        /// #262B31 → #1A1F23). At 92% over the near-black strip it read 3–4 levels too dark.
        static let fill = Gradient(colors: [Color(hex: "#252A30"), Color(hex: "#191E23")])
        static let fillOpacity = 1.0
        /// The capsule has no outline rim. Glass lights it from the LEADING end only: a specular
        /// highlight at the left end and along the top-left (white ≈6%), gone by ≈40% of the width,
        /// nothing on the right or bottom (completeness-critic/25: left end #353A3D; top edge +12–15
        /// levels from x 45 to 90 pt, gone by x ≈150).
        static let highlight = Gradient(stops: [
            .init(color: Color.white.opacity(0.06), location: 0.0),
            .init(color: Color.white.opacity(0.03), location: 0.2),
            .init(color: Color.white.opacity(0.0), location: 0.4),
        ])
        /// The soft glow under the selected item, strongest at the capsule's bottom edge.
        static let selectedGlow = Color.white.opacity(0.13)
        static let selected = Color.white
        /// Unselected items: #969A9D–#A0A4A7 on 2026 captures, white ≈55% on the fill.
        static let unselected = Color.white.opacity(0.55)
    }

    // MARK: Coach button, avatar and summary pill (§1.1, §1.2)

    enum Coach {
        /// The squircle's fill, top-leading to bottom-trailing (sampled on 2026 device captures; the
        /// spec's #171728 → #121A25 reads darker than any capture).
        static let buttonFill = Gradient(colors: [Color(hex: "#2C2B3C"), Color(hex: "#20252F")])
        /// The squircle's 1 pt rim, lit from the top-leading corner only (completeness-critic/13: top
        /// #3B3A59, left #3B3960, nothing on the right or bottom).
        static let buttonRim = Gradient(stops: [
            .init(color: Color(hex: "#4A4775"), location: 0.0),
            .init(color: Color(hex: "#3B3A5C").opacity(0.6), location: 0.35),
            .init(color: Color(hex: "#3B3A5C").opacity(0.0), location: 0.62),
        ])
        /// The lit indigo orb inside the monogram ring: lighter at the top, dark at the bottom
        /// (inside-top #303A62–#353E5F, centre #212936–#24293C, inside-bottom #0F141D–#1F2734).
        static let orb = Gradient(colors: [Color(hex: "#353E5F"), Color(hex: "#252B3E"), Color(hex: "#1E2736")])
        /// The faint indigo halo just outside the ring.
        static let halo = Color(hex: "#6E5BFF").opacity(0.16)
        /// The summary pill: a horizontal gradient from the avatar end (#2E2D3F) to #252C34, with a
        /// top rim (#393E51), and no outer glow (deep-dives-2026/56).
        static let pillFill = Gradient(colors: [Color(hex: "#2E2D3F"), Color(hex: "#252C34")])
        static let pillRim = Gradient(colors: [Color(hex: "#393E51"), Color(hex: "#393E51").opacity(0)])
        /// The floating "Ask ZENO anything" composer.
        static let composerFill = Color(hex: "#20202C")
        static let composerPlaceholder = Color(hex: "#9797A1")
        static let composerMic = Color(hex: "#9FB0E4")
    }
}
#endif
