#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Profile art (group "more-profile"; WHOOP_UI_SPEC §0, §3.30, §3.32)
//
// ZENO's own drawings for the profile pages, made from shapes and SF Symbols, never WHOOP's medal,
// badge, flame or strap art (spec §0):
//   - `ProfileBadgeArt`: an achievement badge. Its frame shape names the family (sleep hexagon, recovery
//     shield, strain diamond, healthspan blob, activity rosette, spec §3.30 "Badge families"), its stars
//     (0–6) the milestone tier in the spec's metals; a locked badge is a black silhouette with a padlock.
//   - `ProfileLevelMedal` / `ProfileLevelPlaque`: the Levels hero medal and the grid's strap-shaped plaque.
//   - `ProfileFlameArt`: the Day Streak flame in its tier's colour (`PulseTheme.Streak.flame`).
//   - `DeviceStrapArt`: the band silhouette on Device Settings' STATUS tab.
// All of it is static: no ambient motion (DR §8).

/// The colours the profile art is drawn in. Art only: data colours stay `PulseTheme`'s.
enum ProfileArtPalette {
    /// A badge family's frame gradient (light, then deep) and its glow on Achievement Details.
    static func family(_ family: PulseAchievements.Family, alarm: Bool = false) -> [Color] {
        switch family {
        case .sleep: return [Color(hex: "#9AA6F2"), Color(hex: "#5E7FB0")]
        case .recovery:
            return alarm ? [Color(hex: "#FF5A63"), Color(hex: "#B3121F")] : [Color(hex: "#5BEA7E"), Color(hex: "#159C45")]
        case .strain: return [Color(hex: "#56C2FF"), Color(hex: "#0074C2")]
        case .healthspan: return [Color(hex: "#4FF0C4"), Color(hex: "#0C9C7E")]
        case .activities: return [Color(hex: "#A98BFF"), Color(hex: "#4FB4F2")]
        }
    }

    /// The star metal for a cumulative badge's star count (spec §3.30 "Star tiers"): 1 the family's
    /// colour, 2 bronze, 3 silver, 4 gold, 5 platinum, 6 lavender.
    static func starMetal(_ stars: Int, family: PulseAchievements.Family) -> Color {
        switch stars {
        case ..<2: return self.family(family)[0]
        case 2: return Color(hex: "#D39A6A")
        case 3: return Color(hex: "#D9DDE2")
        case 4: return Color(hex: "#F0C462")
        case 5: return Color(hex: "#F6F5F0")
        default: return Color(hex: "#D9CCFF")
        }
    }

    /// A level tier's medal metal (light, then deep).
    static func tier(_ tier: PulseLevels.Tier) -> [Color] {
        switch tier {
        case .beginner: return [Color(hex: "#A3A9AF"), Color(hex: "#4E5359")]
        case .bronze: return [Color(hex: "#ECB088"), Color(hex: "#93552F")]
        case .silver: return [Color(hex: "#F1F3F5"), Color(hex: "#8C939A")]
        case .gold: return [Color(hex: "#F8DC8C"), Color(hex: "#B5862A")]
        case .platinum: return [Color(hex: "#FBFAF6"), Color(hex: "#B4B1A8")]
        case .diamond: return [Color(hex: "#C2F0FF"), Color(hex: "#3E9FD6")]
        }
    }

    /// A level plaque's material (light, then deep).
    static func material(_ material: PulseLevels.Material) -> [Color] {
        switch material {
        case .carbon: return [Color(hex: "#3A3E43"), Color(hex: "#141619")]
        case .iron: return [Color(hex: "#6A7078"), Color(hex: "#3A3F45")]
        case .steel: return [Color(hex: "#9AA1A8"), Color(hex: "#5B6269")]
        case .gunmetal: return [Color(hex: "#787E85"), Color(hex: "#43484E")]
        case .titanium: return [Color(hex: "#B4BAC0"), Color(hex: "#6E747A")]
        case .bronze: return [Color(hex: "#E2A57A"), Color(hex: "#8E5634")]
        case .silver: return [Color(hex: "#ECEFF1"), Color(hex: "#9AA1A8")]
        case .gold: return [Color(hex: "#F6D77F"), Color(hex: "#B08428")]
        case .platinum: return [Color(hex: "#F7F6F1"), Color(hex: "#B9B7AF")]
        case .diamond: return [Color(hex: "#C6F1FF"), Color(hex: "#4FA7D6")]
        }
    }

    /// The badge interior, and the locked silhouette's fill and rim.
    static let badgeInterior = Color(hex: "#0D1013")
    static let lockedFill = Color(hex: "#050607")
    static let lockedRim = Color(hex: "#2C3035")
    static let lockedGlyph = Color(hex: "#5D6166")
    /// The medal's inner disc and its tick ring.
    static let medalDisc = Color(hex: "#15181C")
    /// The plaque's number and the band across its foot.
    static let plaqueInk = Color.white
    static let plaqueBand = Color.black.opacity(0.28)

    // Page surfaces sampled on the captures (profile-community-2026/56, 60, 61; reviews/r48; /05, /07).
    /// The Levels hero and the level grid under it.
    static let levelsHero = Color(hex: "#1C2125")
    static let levelsGrid = Color(hex: "#13161B")
    /// A tier or material name in grey caps ("DIAMOND", "CARBON").
    static let tierLabel = Color(hex: "#6A6E73")
    /// The Day Streak page, flat.
    static let streakPage = Color(hex: "#101518")
    /// The Day Streak and Achievement Details cards, and their milestone bars.
    static let milestoneCard = Color(hex: "#1E2326")
    static let streakBar = Color(hex: "#FF6B2C")
    static let milestoneBar = Color(hex: "#67AEE6")
    static let milestoneTrack = Color(hex: "#34393B")
    /// "⇪ SHARE ACHIEVEMENT".
    static let shareButton = Color(hex: "#292E30")
    /// The Achievement Details page under its family glow.
    static let detailsPage = Color(hex: "#0C1014")
    /// The wash over the top of Achievement Details for the families the foundation has no token for
    /// (recovery's green, strain's blue, healthspan's teal): the frame's deep colour, dimmed.
    static func detailsWash(_ family: PulseAchievements.Family) -> Color {
        Self.family(family)[1].opacity(0.42)
    }

    /// Profile's "Tracking since" pill (spec §3.30 "Member since", `#292E32`).
    static let trackingPill = Color(hex: "#292E32")
    /// NOTABLE STATS' gold scalloped icon: its rim and its glyph (profile-community-2026/22).
    static let notableRim = Color(hex: "#C9A15A")
    static let notableGlyph = Color(hex: "#E8C27A")

    /// WHOOP's settings switch when off: a grey knob on a grey track (profile-community-2026/55, sampled
    /// (143, 142, 147) and (101, 106, 110)).
    static let switchOffKnob = Color(hex: "#8F8E93")
    static let switchOffTrack = Color(hex: "#656A6E")

    /// The phone drawn beside the strap while it is disconnected (onboarding/43a).
    static let phoneBody = Color(hex: "#1E2328")
    /// INTEGRATIONS: the red heart on the health tile, and ZENO's own tile beside it.
    static let healthHeart = Color(hex: "#FF3B5C")
    static let zenoTile = Color(hex: "#20262C")
}

// MARK: - Badge frames

/// A badge family's frame: hexagon, shield, diamond, blob or scalloped rosette.
struct ProfileBadgeShape: Shape {
    let family: PulseAchievements.Family

    func path(in rect: CGRect) -> Path {
        let r = rect
        switch family {
        case .sleep:
            // A pointy-top hexagon.
            let pts = [CGPoint(x: r.midX, y: r.minY),
                       CGPoint(x: r.maxX, y: r.minY + r.height * 0.25),
                       CGPoint(x: r.maxX, y: r.maxY - r.height * 0.25),
                       CGPoint(x: r.midX, y: r.maxY),
                       CGPoint(x: r.minX, y: r.maxY - r.height * 0.25),
                       CGPoint(x: r.minX, y: r.minY + r.height * 0.25)]
            return Self.rounded(pts, radius: r.width * 0.08)
        case .recovery:
            // A shield: a rounded top, straight sides, a curved point at the foot.
            var p = Path()
            let corner = r.width * 0.18
            p.move(to: CGPoint(x: r.minX, y: r.minY + corner))
            p.addQuadCurve(to: CGPoint(x: r.minX + corner, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - corner, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + corner), control: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.52))
            p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                       control1: CGPoint(x: r.maxX, y: r.minY + r.height * 0.80),
                       control2: CGPoint(x: r.midX + r.width * 0.22, y: r.maxY - r.height * 0.05))
            p.addCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.52),
                       control1: CGPoint(x: r.midX - r.width * 0.22, y: r.maxY - r.height * 0.05),
                       control2: CGPoint(x: r.minX, y: r.minY + r.height * 0.80))
            p.closeSubpath()
            return p
        case .strain:
            // A diamond: a square on its point.
            let pts = [CGPoint(x: r.midX, y: r.minY), CGPoint(x: r.maxX, y: r.midY),
                       CGPoint(x: r.midX, y: r.maxY), CGPoint(x: r.minX, y: r.midY)]
            return Self.rounded(pts, radius: r.width * 0.10)
        case .healthspan:
            // An organic blob: a smooth loop through points at uneven radii.
            let radii: [CGFloat] = [1.0, 0.93, 0.99, 0.91, 0.97, 0.94, 1.0, 0.92]
            let pts = radii.enumerated().map { i, k -> CGPoint in
                let a = Double(i) / Double(radii.count) * 2 * .pi - .pi / 2
                return CGPoint(x: r.midX + CGFloat(cos(a)) * r.width / 2 * k,
                               y: r.midY + CGFloat(sin(a)) * r.height / 2 * k)
            }
            return Self.smoothLoop(pts)
        case .activities:
            // A scalloped rosette.
            var p = Path()
            let n = 16
            let outer = min(r.width, r.height) / 2
            let inner = outer * 0.9
            for i in 0..<n {
                let a0 = Double(i) / Double(n) * 2 * .pi - .pi / 2
                let a1 = Double(i + 1) / Double(n) * 2 * .pi - .pi / 2
                let am = (a0 + a1) / 2
                let start = CGPoint(x: r.midX + CGFloat(cos(a0)) * inner, y: r.midY + CGFloat(sin(a0)) * inner)
                let end = CGPoint(x: r.midX + CGFloat(cos(a1)) * inner, y: r.midY + CGFloat(sin(a1)) * inner)
                let control = CGPoint(x: r.midX + CGFloat(cos(am)) * outer * 1.08,
                                      y: r.midY + CGFloat(sin(am)) * outer * 1.08)
                if i == 0 { p.move(to: start) }
                p.addQuadCurve(to: end, control: control)
            }
            p.closeSubpath()
            return p
        }
    }

    /// A polygon whose corners are rounded by `radius`.
    static func rounded(_ points: [CGPoint], radius: CGFloat) -> Path {
        var p = Path()
        guard points.count > 2 else { return p }
        let n = points.count
        let mid = CGPoint(x: (points[n - 1].x + points[0].x) / 2, y: (points[n - 1].y + points[0].y) / 2)
        p.move(to: mid)
        for i in 0..<n {
            p.addArc(tangent1End: points[i], tangent2End: points[(i + 1) % n], radius: radius)
        }
        p.closeSubpath()
        return p
    }

    /// A smooth closed curve through `points` (Catmull-Rom as cubic Béziers).
    static func smoothLoop(_ points: [CGPoint]) -> Path {
        var p = Path()
        let n = points.count
        guard n > 2 else { return p }
        p.move(to: points[0])
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n], p1 = points[i], p2 = points[(i + 1) % n], p3 = points[(i + 2) % n]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            p.addCurve(to: p2, control1: c1, control2: c2)
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Badge

/// An achievement badge: its family frame drawn as three nested strokes over a dark interior lit in the
/// family colour, a pictogram, and up to six stars along the top; or, locked, a black silhouette with a
/// grey padlock. The big count is laid over it by the caller (`ProfileBadgeCell`).
struct ProfileBadgeArt: View {
    let family: PulseAchievements.Family
    let symbol: String
    var stars: Int = 0
    var locked = false
    /// The red recovery shield (a Recovery of 5% or less), WHOOP's "1% Club" colour.
    var alarm = false
    var size: CGFloat = 80

    var body: some View {
        let colors = ProfileArtPalette.family(family, alarm: alarm)
        let shape = ProfileBadgeShape(family: family)
        let width = size * (family == .recovery ? 0.86 : 1)
        ZStack {
            if locked {
                shape.fill(ProfileArtPalette.lockedFill)
                shape.stroke(ProfileArtPalette.lockedRim, lineWidth: max(1, size * 0.015))
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.24, weight: .semibold))
                    .foregroundStyle(ProfileArtPalette.lockedGlyph)
                    .offset(y: -size * 0.08)
            } else {
                shape.fill(RadialGradient(colors: [colors[1].opacity(0.55), ProfileArtPalette.badgeInterior],
                                          center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.75))
                // Three nested outlines, fainter inward: the "line art" frame.
                ForEach(0..<3, id: \.self) { i in
                    shape
                        .stroke(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: i == 0 ? max(1.5, size * 0.035) : max(0.75, size * 0.012))
                        .opacity(i == 0 ? 1 : (i == 1 ? 0.55 : 0.3))
                        .padding(CGFloat(i) * size * 0.07)
                }
                Image(systemName: symbol)
                    .font(.system(size: size * 0.3, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [Color.white.opacity(0.95), Color.white.opacity(0.6)],
                                                    startPoint: .top, endPoint: .bottom))
                    .offset(y: -size * 0.08)
                if stars > 0 {
                    ProfileStarArc(count: stars, color: ProfileArtPalette.starMetal(stars, family: family),
                                   size: size)
                        .offset(y: -size * 0.52)
                }
            }
        }
        .frame(width: width, height: size)
        .accessibilityHidden(true)
    }
}

/// Up to six small stars along an arc, the middle one largest: bowed up over a badge's top edge, or
/// (`smile`) down along a medal's foot.
struct ProfileStarArc: View {
    let count: Int
    let color: Color
    var size: CGFloat = 80
    var smile = false

    var body: some View {
        let n = max(0, min(6, count))
        HStack(alignment: .center, spacing: size * 0.02) {
            ForEach(0..<n, id: \.self) { i in
                let centre = Double(n - 1) / 2
                let distance = abs(Double(i) - centre)
                Image(systemName: "star.fill")
                    .font(.system(size: size * (0.11 - 0.012 * distance), weight: .bold))
                    .foregroundStyle(color)
                    .offset(y: CGFloat(distance * distance) * size * 0.012 * (smile ? -1 : 1))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Level medal and plaque

/// The strap-shaped level plaque: a rounded block in its material with the level number and a darker
/// band across its foot (ZENO's own; no wordmark). 34 × 48 by default; the Levels grid draws WHOOP's
/// narrower 28 × 44 (profile-community-2026/56).
struct ProfileLevelPlaque: View {
    let level: Int
    let material: PulseLevels.Material
    var width: CGFloat = 34
    /// nil keeps the default 34 : 48 proportion.
    var height: CGFloat?

    var body: some View {
        let colors = ProfileArtPalette.material(material)
        let height = self.height ?? width * 48 / 34
        let shape = RoundedRectangle(cornerRadius: width * 0.2, style: .continuous)
        ZStack(alignment: .bottom) {
            shape.fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            Rectangle()
                .fill(ProfileArtPalette.plaqueBand)
                .frame(height: height * 0.2)
            shape.strokeBorder(Color.white.opacity(0.18), lineWidth: max(0.5, width * 0.02))
            Text(verbatim: "\(level)")
                .font(PulseType.numeral(width * 0.62, weight: .heavy))
                .foregroundStyle(ProfileArtPalette.plaqueInk)
                .shadow(color: Color.black.opacity(0.35), radius: 1, y: 1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 2)
                .frame(maxHeight: .infinity)
                .padding(.bottom, height * 0.16)
        }
        .clipShape(shape)
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

/// The Levels hero medal: a metal outer ring, a ring of ticks, a dark disc holding the level's plaque,
/// and the tier's stars across its foot.
struct ProfileLevelMedal: View {
    let level: Int
    var size: CGFloat = 230

    var body: some View {
        let tier = PulseLevels.tier(forLevel: level)
        let metal = ProfileArtPalette.tier(tier)
        let ring = AngularGradient(colors: [metal[0], metal[1], metal[0], metal[1], metal[0]], center: .center)
        ZStack {
            Circle().fill(ProfileArtPalette.medalDisc)
            Circle().strokeBorder(ring, lineWidth: size * 0.035)
            Circle().strokeBorder(ring.opacity(0.6), lineWidth: size * 0.008).padding(size * 0.065)
            ProfileTickRing(count: 72, color: metal[0].opacity(0.55), length: size * 0.035)
                .padding(size * 0.09)
            Circle().strokeBorder(ring.opacity(0.85), lineWidth: size * 0.012).padding(size * 0.17)
            ProfileLaurel(color: metal[0].opacity(0.9), size: size * 0.56)
                .offset(y: size * 0.01)
            ProfileLevelPlaque(level: level, material: PulseLevels.material(forLevel: level), width: size * 0.26)
                .offset(y: -size * 0.03)
            if tier.rawValue > 0 {
                ProfileStarArc(count: tier.rawValue, color: metal[0], size: size * 0.9, smile: true)
                    .offset(y: size * 0.31)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Two laurel branches curving up either side of the medal's plaque: small leaves along an arc, a
/// generic heraldic motif drawn from ellipses.
struct ProfileLaurel: View {
    let color: Color
    var size: CGFloat = 120

    var body: some View {
        Canvas { context, canvas in
            let r = canvas.width / 2
            let c = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
            for side in [-1.0, 1.0] {
                // From the foot (110° off the top) round to the shoulder (25°), leaves shrinking upward.
                for i in 0..<8 {
                    let t = Double(i) / 7
                    let degrees = 165 - t * 130
                    let a = degrees * .pi / 180
                    let point = CGPoint(x: c.x + CGFloat(sin(a) * side) * r, y: c.y - CGFloat(cos(a)) * r)
                    let leaf = CGSize(width: r * 0.17 * (1 - t * 0.3), height: r * 0.4 * (1 - t * 0.3))
                    var ctx = context
                    ctx.translateBy(x: point.x, y: point.y)
                    // Each leaf lies along the branch (the tangent is θ - 90°) and tips 30° outward.
                    ctx.rotate(by: .degrees(side * (degrees - 60)))
                    let rect = CGRect(x: -leaf.width / 2, y: -leaf.height / 2, width: leaf.width, height: leaf.height)
                    ctx.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A ring of short radial ticks.
struct ProfileTickRing: View {
    let count: Int
    let color: Color
    var length: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            let r = min(size.width, size.height) / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var p = Path()
            for i in 0..<count {
                let a = Double(i) / Double(count) * 2 * .pi
                let outer = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                let inner = CGPoint(x: c.x + CGFloat(cos(a)) * (r - length), y: c.y + CGFloat(sin(a)) * (r - length))
                p.move(to: inner)
                p.addLine(to: outer)
            }
            context.stroke(p, with: .color(color), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Flame

/// The Day Streak flame in its tier's colour (`PulseTheme.Streak.flame(days:)`, the Home pill's flame):
/// an outer flame, a lighter inner one and a pale core (blue in the 180–364 day tier), over a soft glow.
struct ProfileFlameArt: View {
    let days: Int
    var size: CGFloat = 200
    var glows = true

    var body: some View {
        let base = PulseTheme.Streak.flame(days: days)
        let tier = PulseDayStreak.tier(days: days)
        let core = tier == .blaze ? PulseTheme.Streak.redTierCore : Color.white
        ZStack {
            if glows {
                Circle()
                    .fill(RadialGradient(colors: [base.opacity(0.28), base.opacity(0)], center: .center,
                                         startRadius: 0, endRadius: size * 0.55))
                    .frame(width: size * 1.2, height: size * 1.2)
            }
            ProfileFlameShape(tongue: true)
                .fill(LinearGradient(colors: [base.opacity(0.9), base], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.54, height: size)
            ProfileFlameShape(tongue: false)
                .fill(LinearGradient(colors: [Color.white.opacity(0.32), Color.white.opacity(0.08)],
                                     startPoint: .top, endPoint: .bottom))
                .blendMode(.plusLighter)
                .frame(width: size * 0.34, height: size * 0.58)
                .offset(y: size * 0.17)
            ProfileFlameShape(tongue: false)
                .fill(LinearGradient(colors: [core.opacity(0.95), core.opacity(0.7)], startPoint: .top,
                                     endPoint: .bottom))
                .frame(width: size * 0.14, height: size * 0.26)
                .offset(y: size * 0.32)
        }
        .frame(width: size * (glows ? 1.2 : 0.54), height: size * (glows ? 1.2 : 1))
        .accessibilityHidden(true)
    }
}

/// A flame: a rounded bowl rising to a point, optionally with a second tongue on its right shoulder.
struct ProfileFlameShape: Shape {
    var tongue = false

    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.5, y: r.minY))
        if tongue {
            // Up the right side to a shoulder tongue, then down into the bowl.
            p.addCurve(to: CGPoint(x: r.minX + w * 0.72, y: r.minY + h * 0.38),
                       control1: CGPoint(x: r.minX + w * 0.58, y: r.minY + h * 0.16),
                       control2: CGPoint(x: r.minX + w * 0.64, y: r.minY + h * 0.3))
            p.addCurve(to: CGPoint(x: r.minX + w * 0.86, y: r.minY + h * 0.22),
                       control1: CGPoint(x: r.minX + w * 0.8, y: r.minY + h * 0.33),
                       control2: CGPoint(x: r.minX + w * 0.84, y: r.minY + h * 0.28))
            p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.68),
                       control1: CGPoint(x: r.minX + w * 0.98, y: r.minY + h * 0.4),
                       control2: CGPoint(x: r.maxX, y: r.minY + h * 0.52))
        } else {
            p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.68),
                       control1: CGPoint(x: r.minX + w * 0.66, y: r.minY + h * 0.24),
                       control2: CGPoint(x: r.maxX, y: r.minY + h * 0.42))
        }
        p.addCurve(to: CGPoint(x: r.minX + w * 0.5, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.minY + h * 0.88),
                   control2: CGPoint(x: r.minX + w * 0.78, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + h * 0.68),
                   control1: CGPoint(x: r.minX + w * 0.22, y: r.maxY),
                   control2: CGPoint(x: r.minX, y: r.minY + h * 0.88))
        p.addCurve(to: CGPoint(x: r.minX + w * 0.5, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + h * 0.42),
                   control2: CGPoint(x: r.minX + w * 0.34, y: r.minY + h * 0.24))
        p.closeSubpath()
        return p
    }
}

// MARK: - Strap

/// The strap on Device Settings' STATUS tab, cropped off the left edge: ZENO's own band glyph
/// (`PulseStrapShape`, the Home header's strap) drawn large and lit, a woven band running through a sensor
/// pod in a brushed-metal frame, tilted. Original art: never a product render or a wordmark.
struct DeviceStrapArt: View {
    var height: CGFloat = 360

    var body: some View {
        let w = height * 0.62
        let metal = LinearGradient(colors: [Color(hex: "#E4E7EA"), Color(hex: "#80878E"), Color(hex: "#CDD1D5"),
                                            Color(hex: "#5E646A")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        let band = RoundedRectangle(cornerRadius: w * 0.12, style: .continuous)
        ZStack {
            // The band, running past the frame at both ends, woven and lit from the top-left.
            band
                .fill(LinearGradient(colors: [Color(hex: "#3A3F45"), Color(hex: "#181B1E"), Color(hex: "#25292D")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(PulseHatchedTrack(color: Color.white.opacity(0.06), spacing: 3, cornerRadius: w * 0.12))
                .overlay(band.strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                .frame(width: w * 0.62, height: height * 1.5)
            // The pod: a dark face in a metal frame, with a soft highlight along its top edge.
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.2, style: .continuous).fill(metal)
                RoundedRectangle(cornerRadius: w * 0.17, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: "#2A2E33"), Color(hex: "#0D0F11")],
                                         startPoint: .top, endPoint: .bottom))
                    .padding(w * 0.035)
                RoundedRectangle(cornerRadius: w * 0.17, style: .continuous)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.22), Color.clear], startPoint: .top,
                                           endPoint: .center), lineWidth: 1.5)
                    .padding(w * 0.035)
            }
            .frame(width: w, height: height * 0.46)
            .shadow(color: Color.black.opacity(0.6), radius: 18, y: 10)
        }
        .rotationEffect(.degrees(-24))
        .frame(width: height * 0.95, height: height)
        .accessibilityHidden(true)
    }
}
#endif
