#if os(iOS)
import SwiftUI
import StrandAnalytics

/// Levels (WHOOP_UI_SPEC §3.30, profile-community-2026/11, 56, 57), pushed from Profile's LEVEL card:
/// the circular back button and "LEVELS ?", a hero on #1C2125 with the medal, its tier and level, the
/// progress between the two levels' plaques and how many Recoveries remain, then the 30-level grid on
/// #13161B. A level is earned by scored Recoveries (`PulseLevels`), the same count Profile prints.
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
            ProfileLevelMedal(level: level.level, size: 230)
                .padding(.top, 22)
            Text(tierName(level.tier))
                .pulseText(.levelTier)
                .foregroundStyle(ProfileArtPalette.tierLabel)
                .padding(.top, 26)
            Text(String(localized: "Level \(level.level)"))
                .pulseText(.levelTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)
            if level.isMax {
                Text(String(localized: "You've reached the highest level."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, 40)
            } else {
                progressRow(level)
                    .padding(.top, 20)
                Text(remainingText(level))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 38)
        .background(ProfileArtPalette.levelsHero)
        .accessibilityElement(children: .combine)
    }

    /// The level's plaque, a 6 pt capsule from #BCBDBF to #FCFCFC on a #161920 track, the next plaque.
    private func progressRow(_ level: PulseLevels.Progress) -> some View {
        HStack(spacing: 12) {
            ProfileLevelPlaque(level: level.level, material: PulseLevels.material(forLevel: level.level), width: 22)
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
                ProfileLevelPlaque(level: next, material: PulseLevels.material(forLevel: next), width: 22)
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
        // 8 pt between columns, so neighbouring cells' lines never run together at large sizes.
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 46) {
            ForEach(1...PulseLevels.maxLevel, id: \.self) { n in
                LevelCell(level: n, reached: n <= level.level, current: n == level.level)
                    .id("pulse.level-\(n)")
            }
        }
        .id("pulse.grid")
        .padding(.top, 42)
        .padding(.bottom, 30)
        .padding(.horizontal, 8)
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
                        .frame(width: 92, height: 92)
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ProfileArtPalette.tier(tier)[0])
                        .padding(.horizontal, 4)
                        .background(ProfileArtPalette.levelsGrid)
                        .offset(y: 46)
                }
                ProfileLevelPlaque(level: level, material: material, width: 40)
            }
            .frame(height: 96)
            // Each line stays whole in its column, shrinking rather than wrapping into the next cell.
            Text(materialName(material))
                .pulseText(.label)
                .foregroundStyle(ProfileArtPalette.tierLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 22)
            Text(String(localized: "Level \(level)"))
                .profileFont(15, weight: .bold, relativeTo: .subheadline, tracking: 1.6, uppercase: true)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 4)
            Text(threshold)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 4)
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
