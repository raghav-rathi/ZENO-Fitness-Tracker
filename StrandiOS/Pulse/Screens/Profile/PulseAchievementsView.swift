#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Achievements (WHOOP_UI_SPEC §3.30, profile-community-2026/04, 80, 81), pushed from Profile's VIEW
/// ALL: "‹ ACHIEVEMENTS", the large "All Achievements (n)" title that scrolls under the bar, the filter
/// chips, then a section per family (SLEEP · RECOVERY · STRAIN · HEALTHSPAN · ACTIVITIES), each a caps
/// label with its rule over a three-column grid of badges. A locked badge is a black silhouette with a
/// padlock and "0". Every badge is a local rule over the wearer's own history (`PulseAchievements`).
struct PulseAchievementsView: View {
    static let isRebuilt = true

    @Environment(\.pulseNavigator) private var navigator
    @State private var snapshot: ProfileSnapshot?
    @State private var filter: PulseAchievements.Family?

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Achievements"), spacing: 0, topPadding: 4,
                            ready: snapshot != nil) {
            PulseSectionHeader(String(localized: "All Achievements"), count: snapshot?.unlockedBadges.count,
                               style: .pageTitle)
                .padding(.horizontal, -4)
                .padding(.top, 6)
            chips
                .padding(.top, 20)
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot { sections(snapshot) }
            } skeleton: {
                PulseSkeleton.cards([160, 160])
                    .padding(.top, 40)
            }
        }
        .profileSnapshot($snapshot)
        .pulseAchievementUnlocks(snapshot)
        .onAppear(perform: openDebugPage)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PulseFilterChip(title: String(localized: "All"), isSelected: filter == nil) { filter = nil }
                ForEach(PulseAchievements.Family.allCases, id: \.self) { family in
                    PulseFilterChip(title: Self.familyName(family), isSelected: filter == family) { filter = family }
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .padding(.horizontal, -PulseTheme.Layout.pageMargin)
    }

    private func sections(_ s: ProfileSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(PulseAchievements.Family.allCases.filter { filter == nil || filter == $0 }, id: \.self) { family in
                let badges = s.badges.filter { $0.family == family }
                VStack(alignment: .leading, spacing: 30) {
                    AchievementsRuleLabel(Self.familyName(family))
                    if badges.isEmpty {
                        Text(String(localized: "Log an activity and its badge appears here."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .padding(.horizontal, 4)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                                  alignment: .center, spacing: 36) {
                            ForEach(badges) { badge in
                                Button {
                                    navigator.open(PulseAchievementDetailsRoute(badgeID: badge.id).route)
                                } label: {
                                    ProfileBadgeCell(badge: badge, artSize: 80)
                                }
                                .buttonStyle(PulsePressStyle())
                            }
                        }
                    }
                }
                .padding(.top, 44)
                .id("pulse.family-\(family.rawValue)")
            }
        }
    }

    static func familyName(_ family: PulseAchievements.Family) -> String {
        switch family {
        case .sleep: return String(localized: "Sleep")
        case .recovery: return String(localized: "Recovery")
        case .strain: return String(localized: "Strain")
        case .healthspan: return String(localized: "Healthspan")
        case .activities: return String(localized: "Activities")
        }
    }

    /// DEBUG `--more-open badge:<id>` pushes that badge's details for captures.
    private func openDebugPage() {
        #if DEBUG
        guard let name = PulseMoreDebug.take(prefixes: ["badge:"]) else { return }
        navigator.open(PulseAchievementDetailsRoute(badgeID: String(name.dropFirst("badge:".count))).route)
        #endif
    }
}

/// "SLEEP ———": the 11 pt caps grey label with its hairline (profile-community-2026/04, 80).
private struct AchievementsRuleLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .modifier(MoreLabelText(tracking: 1.4))
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
            Rectangle().fill(PulseTheme.divider).frame(height: 1)
        }
    }
}

// MARK: - Achievement Details

/// Achievement Details (spec §3.30, profile-community-2026/05–08, 82): "‹ ACHIEVEMENT DETAILS" with a
/// share icon (Aug 2026+), the family's wash over the top of a near-black page, the badge hero with its
/// big count (the last milestone reached), the name and the rule, when it unlocked and the total so far
/// (in place of WHOOP's [POP] percentile), the milestone card from the count to the next milestone, and
/// SHARE ACHIEVEMENT. The shared card is rendered on the phone, and only when the wearer asks to share.
struct PulseAchievementDetailsView: View {
    let badgeID: String

    @State private var snapshot: ProfileSnapshot?

    private var badge: PulseAchievements.Badge? { snapshot?.badges.first { $0.id == badgeID } }

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Achievement details"), trailing: shareTrailing,
                            background: .nearBlack, spacing: 0, topPadding: 0, ready: snapshot != nil) {
            if let badge {
                content(badge)
            } else if snapshot != nil {
                Text(String(localized: "This achievement is no longer in your history."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity)
            } else {
                PulseSkeleton.cards([300, 120])
                    .padding(.top, 30)
            }
        }
        .profileSnapshot($snapshot)
    }

    /// The share icon at the bar's right, for a badge there is something to share.
    private var shareTrailing: PulseNavTrailing {
        guard let badge, badge.isUnlocked else { return .none }
        return .symbol("square.and.arrow.up", accessibilityLabel: String(localized: "Share achievement")) {
            share(badge)
        }
    }

    private func content(_ badge: PulseAchievements.Badge) -> some View {
        let info = ProfileBadgeInfo(badge)
        return VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                ProfileBadgeArt(family: badge.family, symbol: info.symbol, stars: badge.stars,
                                locked: !badge.isUnlocked, alarm: info.alarm, size: 230)
                    .padding(.bottom, 64)
                Text(ProfileBadgeInfo.countText(badge))
                    .font(PulseType.numeral(88, weight: .heavy))
                    .foregroundStyle(badge.isUnlocked ? PulseTheme.textPrimary : ProfileArtPalette.lockedGlyph)
                    .shadow(color: Color.black.opacity(0.75), radius: 12, y: 3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.top, 26)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                // From the screen's top edge (under the bar) to ≈45% of its height (profile-community-2026/05).
                AchievementGlowWash(family: badge.family, alarm: info.alarm)
                    .frame(height: 440)
                    .padding(.horizontal, -PulseTheme.Layout.pageMargin)
                    .offset(y: -140)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            Text(info.name)
                .profileFont(22, weight: .semibold, relativeTo: .title2)
                .foregroundStyle(PulseTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
                .accessibilityAddTraits(.isHeader)
            Text(info.criterion)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
            stats(badge)
                .padding(.top, 30)
            if let next = badge.nextMilestone, badge.kind != .event {
                milestoneCard(badge, next: next, info: info)
                    .padding(.top, 30)
            }
            if badge.isUnlocked {
                shareButton(badge)
                    .padding(.top, 16)
            }
        }
    }

    private func stats(_ badge: PulseAchievements.Badge) -> some View {
        HStack(spacing: 0) {
            stat(value: badge.unlockedDay.map(ProfileFormat.day) ?? String(localized: "Not yet"),
                 caption: badge.kind == .event ? String(localized: "Last time") : String(localized: "Unlocked"))
            Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 40)
            stat(value: badge.kind == .value ? String(localized: "\(badge.count) yrs")
                                             : PulseFormat.grouped(Double(badge.count)),
                 caption: badge.kind == .value ? String(localized: "Younger now") : String(localized: "Total so far"))
        }
    }

    private func stat(value: String, caption: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .profileFont(18, weight: .bold, relativeTo: .headline)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// A mini badge with the milestone reached, "27 more" over a blue bar and "until your next
    /// milestone.", and the next milestone's badge, greyed.
    private func milestoneCard(_ badge: PulseAchievements.Badge, next: Int, info: ProfileBadgeInfo) -> some View {
        HStack(spacing: 12) {
            // The count as it stands (1173 on profile-community-2026/05, under a hero showing 1150).
            miniBadge(badge, info: info,
                      value: badge.kind == .value ? ProfileBadgeInfo.countText(badge) : PulseFormat.grouped(Double(badge.count)),
                      locked: !badge.isUnlocked)
            VStack(spacing: 10) {
                Text(String(localized: "\(PulseFormat.grouped(Double(badge.remaining ?? 0))) more"))
                    .pulseText(.coachingTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ProfileArtPalette.milestoneTrack)
                        Capsule().fill(ProfileArtPalette.milestoneBar)
                            .frame(width: max(4, geo.size.width * CGFloat(badge.milestoneFraction ?? 0)))
                    }
                }
                .frame(height: 6)
                Text(String(localized: "until your next milestone."))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            miniBadge(badge, info: info,
                      value: badge.kind == .value ? String(localized: "-\(next) Yrs") : PulseFormat.grouped(Double(next)),
                      locked: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 16, style: .circular).fill(ProfileArtPalette.milestoneCard))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Next milestone \(next)"))
        .accessibilityValue(String(localized: "\(badge.remaining ?? 0) more"))
    }

    private func miniBadge(_ badge: PulseAchievements.Badge, info: ProfileBadgeInfo, value: String,
                           locked: Bool) -> some View {
        ZStack(alignment: .bottom) {
            ProfileBadgeArt(family: badge.family, symbol: info.symbol, stars: 0, locked: locked && !badge.isUnlocked,
                            alarm: info.alarm, size: 56)
                .saturation(locked ? 0 : 1)
                .opacity(locked ? 0.55 : 1)
                .padding(.bottom, 16)
            Text(value)
                .font(PulseType.numeral(26, weight: .heavy))
                .foregroundStyle(PulseTheme.textPrimary)
                .shadow(color: Color.black.opacity(0.6), radius: 4, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(width: 76)
    }

    /// "⇪ SHARE ACHIEVEMENT": hands a portrait card (the badge on black with its glow, the count, the name
    /// and the rule, and ZENO's wordmark) to the share sheet.
    private func shareButton(_ badge: PulseAchievements.Badge) -> some View {
        Button { share(badge) } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .semibold))
                Text(String(localized: "Share achievement")).modifier(MoreLabelText(tracking: 1.4))
            }
            .foregroundStyle(PulseTheme.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(ProfileArtPalette.shareButton))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
    }

    /// Render the card (a 1080 × 1620 px raster) at the moment of the tap, never while the page draws, and
    /// open the share sheet with it.
    private func share(_ badge: PulseAchievements.Badge) {
        let renderer = ImageRenderer(content: AchievementShareCard(badge: badge, info: ProfileBadgeInfo(badge)))
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        ProfileSharePresenter.share([image])
    }
}

/// The family's wash across the top of Achievement Details, fading into the near-black page by ≈45% of the
/// screen (profile-community-2026/05: #393368 at 3% of the height, #312D59 at 15%, #262542 at 25% down the
/// left edge). The foundation's tokens where it has one: activities violet → teal, sleep slate, the red of a
/// Recovery of 5% or less; the other families take their frame's deep colour.
private struct AchievementGlowWash: View {
    let family: PulseAchievements.Family
    let alarm: Bool

    var body: some View {
        fill.mask(LinearGradient(stops: [.init(color: Color.white, location: 0),
                                         .init(color: Color.white.opacity(0.82), location: 0.3),
                                         .init(color: Color.white.opacity(0.55), location: 0.52),
                                         .init(color: Color.white.opacity(0.18), location: 0.8),
                                         .init(color: Color.clear, location: 1)],
                                  startPoint: .top, endPoint: .bottom))
    }

    @ViewBuilder
    private var fill: some View {
        switch family {
        case .activities:
            LinearGradient(gradient: PulseTheme.Gradients.achievementGlowActivity, startPoint: .leading,
                           endPoint: .trailing)
        case .sleep:
            PulseTheme.Gradients.achievementGlowSleep
        case .recovery where alarm:
            PulseTheme.Gradients.achievementGlowOnePercent
        default:
            ProfileArtPalette.detailsWash(family)
        }
    }
}

/// The shared image: 360 × 540 pt, black, the family glow, the badge and its count, the name, the rule.
private struct AchievementShareCard: View {
    let badge: PulseAchievements.Badge
    let info: ProfileBadgeInfo

    var body: some View {
        let glow = ProfileArtPalette.family(badge.family, alarm: info.alarm)
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                ProfileBadgeArt(family: badge.family, symbol: info.symbol, stars: badge.stars, alarm: info.alarm,
                                size: 180)
                    .padding(.bottom, 44)
                Text(ProfileBadgeInfo.countText(badge))
                    .font(PulseType.numeral(64, weight: .heavy))
                    .foregroundStyle(Color.white)
            }
            Text(info.name).font(.system(size: 24, weight: .semibold)).foregroundStyle(Color.white)
            Text(info.criterion).font(.system(size: 15)).foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
            PulseZenoWordmark(color: Color.white.opacity(0.7), width: 60, height: 10)
                .padding(.top, 10)
        }
        .padding(30)
        .frame(width: 360, height: 540)
        .background {
            ZStack {
                Color.black
                RadialGradient(colors: [glow[1].opacity(0.6), Color.clear], center: .top, startRadius: 0,
                               endRadius: 380)
            }
        }
        .environment(\.colorScheme, .dark)
    }
}
#endif
