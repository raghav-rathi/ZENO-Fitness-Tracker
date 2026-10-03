#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Levels (WHOOP_UI_SPEC §3.30, profile-community-2026/11, 56, 57), pushed from Profile's LEVEL card:
/// the circular back button and "LEVELS ?", a hero on #1C2125 with the medal, its tier and level, the
/// progress between the two levels' plaques and how many Recoveries remain, then the 30-level grid on
/// #13161B. A level is earned by scored Recoveries (`PulseLevels`), the same count Profile prints.
///
/// Proportions are measured on the 2026 captures (/56 and /11 at 3x), which run smaller than the spec's
/// numbers: a 174 pt medal 43 pt under the bar's centre, the tier in 12 pt caps, "LEVEL 29" in 17 pt
/// tracked caps, 28 × 44 pt plaques on a 165 pt row pitch.
struct PulseLevelsView: View {
    static let isRebuilt = true

    @State private var snapshot: ProfileSnapshot?
    @State private var showHelp = false

    var body: some View {
        ProfileFlatPage(title: String(localized: "Levels"), background: ProfileArtPalette.levelsHero,
                        circularBack: true, onHelp: { showHelp = true }, ready: snapshot != nil) {
            if let level = snapshot?.level {
                hero(level)
                grid(level)
            } else {
                hero(PulseLevels.progress(recoveries: 0))
                    .redacted(reason: .placeholder)
                    .opacity(0.5)
                    .accessibilityHidden(true)
            }
        }
        .profileSnapshot($snapshot)
        .sheet(isPresented: $showHelp) { LevelsHelpSheet() }
    }

    // MARK: Hero

    private func hero(_ level: PulseLevels.Progress) -> some View {
        VStack(spacing: 0) {
            ProfileLevelMedal(level: level.level, size: 174)
                .padding(.top, 22)
            Text(tierName(level.tier))
                .profileFont(12, weight: .bold, relativeTo: .caption, tracking: 1.0, uppercase: true)
                .foregroundStyle(ProfileArtPalette.tierLabel)
                .padding(.top, 11)
            Text(String(localized: "Level \(level.level)"))
                .profileFont(17, weight: .bold, relativeTo: .headline, tracking: 1.8, uppercase: true)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 5)
                .accessibilityAddTraits(.isHeader)
            if level.isMax {
                Text(String(localized: "You've reached the highest level."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, 22)
            } else {
                progressRow(level)
                    .padding(.top, 4)
                Text(remainingText(level))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 18)
        .background(ProfileArtPalette.levelsHero)
        .accessibilityElement(children: .combine)
    }

    /// The level's plaque, a 6 pt capsule from #BCBDBF to #FCFCFC on a #161920 track, the next plaque.
    private func progressRow(_ level: PulseLevels.Progress) -> some View {
        HStack(spacing: 12) {
            ProfileLevelPlaque(level: level.level, material: PulseLevels.material(forLevel: level.level), width: 18)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(PulseTheme.Levels.barTrack)
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.6), lineWidth: 1))
                    Capsule()
                        .fill(LinearGradient(colors: [PulseTheme.Levels.barStart, PulseTheme.Levels.barEnd],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geo.size.width * CGFloat(level.fraction)))
                        .padding(1)
                }
            }
            .frame(height: 8)
            if let next = level.nextLevel {
                ProfileLevelPlaque(level: next, material: PulseLevels.material(forLevel: next), width: 18)
            }
        }
        .padding(.horizontal, 30)
        .accessibilityHidden(true)
    }

    private func remainingText(_ level: PulseLevels.Progress) -> String {
        guard let remaining = level.remaining, let next = level.nextLevel else { return "" }
        return remaining == 1 ? String(localized: "1 more Recovery to Level \(next)")
                              : String(localized: "\(remaining) more Recoveries to Level \(next)")
    }

    // MARK: Grid

    private func grid(_ level: PulseLevels.Progress) -> some View {
        // 8 pt between columns, so neighbouring cells' lines never run together at large sizes; rows on a
        // 165 pt pitch (profile-community-2026/56).
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 34) {
            ForEach(1...PulseLevels.maxLevel, id: \.self) { n in
                LevelCell(level: n, reached: n <= level.level, current: n == level.level)
                    .id("pulse.level-\(n)")
            }
        }
        .id("pulse.grid")
        .padding(.top, 19)
        .padding(.bottom, 30)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(ProfileArtPalette.levelsGrid.padding(.bottom, -600))
    }

    private func tierName(_ tier: PulseLevels.Tier) -> String {
        switch tier {
        case .beginner: return String(localized: "Beginner")
        case .bronze: return String(localized: "Bronze")
        case .silver: return String(localized: "Silver")
        case .gold: return String(localized: "Gold")
        case .platinum: return String(localized: "Platinum")
        case .diamond: return String(localized: "Diamond")
        }
    }
}

/// One level in the grid: its plaque (ringed with a star at the start of each tier), the material name,
/// "LEVEL n" and the Recoveries it needs. Levels not reached yet are dimmed.
private struct LevelCell: View {
    let level: Int
    let reached: Bool
    let current: Bool

    var body: some View {
        let material = PulseLevels.material(forLevel: level)
        let tier = PulseLevels.tier(forLevel: level)
        VStack(spacing: 0) {
            ZStack {
                if PulseLevels.isTierStart(level) {
                    Circle()
                        .strokeBorder(ProfileArtPalette.tier(tier)[1].opacity(0.85), lineWidth: 1.2)
                        .frame(width: 70, height: 70)
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ProfileArtPalette.tier(tier)[0])
                        .padding(.horizontal, 4)
                        .background(ProfileArtPalette.levelsGrid)
                        .offset(y: 35)
                }
                ProfileLevelPlaque(level: level, material: material, width: 28, height: 44)
            }
            .frame(height: 70)
            // Each line stays whole in its column, shrinking rather than wrapping into the next cell.
            // /56 at 3x: the material's caps 7.3 pt tall (≈10.5 pt, tracked), "LEVEL n" 9 pt (≈12.5 pt),
            // the threshold ≈11 pt.
            Text(materialName(material))
                .profileFont(11, weight: .bold, relativeTo: .caption2, tracking: 1.2, uppercase: true)
                .foregroundStyle(ProfileArtPalette.tierLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            Text(String(localized: "Level \(level)"))
                .profileFont(12.5, weight: .bold, relativeTo: .caption, tracking: 1.2, uppercase: true)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)
            Text(threshold)
                .profileFont(11.5, weight: .medium, relativeTo: .caption)
                .foregroundStyle(PulseTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)
        }
        .opacity(reached ? 1 : 0.45)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityValue(current ? String(localized: "Your level") : (reached ? String(localized: "Reached") : ""))
    }

    private var threshold: String {
        let minimum = PulseLevels.minimum(forLevel: level) ?? 0
        return minimum == 0 ? String(localized: "Day one") : ProfileFormat.recoveries(minimum)
    }

    private func materialName(_ m: PulseLevels.Material) -> String {
        switch m {
        case .carbon: return String(localized: "Carbon")
        case .iron: return String(localized: "Iron")
        case .steel: return String(localized: "Steel")
        case .gunmetal: return String(localized: "Gunmetal")
        case .titanium: return String(localized: "Titanium")
        case .bronze: return String(localized: "Bronze")
        case .silver: return String(localized: "Silver")
        case .gold: return String(localized: "Gold")
        case .platinum: return String(localized: "Platinum")
        case .diamond: return String(localized: "Diamond")
        }
    }
}

/// "?": how levels work, in a sheet.
private struct LevelsHelpSheet: View {
    var body: some View {
        NavigationStack {
            PulseScreenScaffold(title: String(localized: "About levels")) {
                Text(String(localized: "Every day with a scored Recovery counts once. There are 30 levels in six tiers, from Beginner to Diamond, and level 30 takes 3,000 Recoveries."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(localized: "A night without a score, such as one off the wrist, does not count, and nothing is ever taken away."))
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .environment(\.pulseModalRoot, true)
        }
        .presentationDetents([.medium])
    }
}
#endif
