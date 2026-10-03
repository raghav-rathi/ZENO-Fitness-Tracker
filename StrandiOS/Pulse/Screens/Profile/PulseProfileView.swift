#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Profile (WHOOP_UI_SPEC §3.30), pushed from the Home avatar and More › PROFILE: the header on a glow in
/// the avatar's colour, "Tracking since", the LEVEL and ZENO AGE cards, DAY STREAK, MY MEMORY, the
/// Achievements carousel, Data Highlights and the Activity Summary (profile-community-2026/10, 21, 22, 23).
///
/// One snapshot feeds this page, Levels, Achievements and Day Streak (`ProfileSnapshot`), so the level,
/// the streak and the badge counts can never disagree between them. Every figure is the wearer's own:
/// WHOOP's percentile lines and member averages are [POP] and left out.
struct PulseProfileView: View {
    /// Rebuilt: the Home avatar opens this screen rather than the classic Settings.
    static let isRebuilt = true

    @Environment(\.pulseNavigator) private var navigator
    @Environment(\.pulseCoach) private var coach
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var appModel: AppModel
    @AppStorage(PulseProfileIdentity.nameKey) private var storedName = ""
    @State private var snapshot: ProfileSnapshot?
    @State private var highlightWindow: ProfileWindow = .all
    @State private var activityWindow: ProfileWindow = .all
    @State private var showsAllSports = false

    var body: some View {
        PulseScreenScaffold(title: String(localized: "Profile"), spacing: 0, topPadding: 8,
                            ready: snapshot != nil) {
            header
            trackingSince
                .padding(.top, 18)
            PulseLoadingGate(isLoading: snapshot == nil) {
                if let snapshot { content(snapshot) }
            } skeleton: {
                PulseSkeleton.cards([150, 54, 54, 180, 320])
                    .padding(.top, 30)
            }
        }
        .pulseAchievementUnlocks(snapshot)
        .profileSnapshot($snapshot)
        .onAppear(perform: openDebugPage)
    }

    // MARK: Header

    private var name: String? {
        let trimmed = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The avatar's colour: its initials disc, or teal (WHOOP's sampled glow) for a photo or none.
    private var glowColor: Color {
        if profile.avatarImageData == nil, let name {
            let initials = name.split(separator: " ").prefix(2).compactMap { $0.first.map { String($0).uppercased() } }.joined()
            if !initials.isEmpty { return PulseAvatar.discColor(for: initials) }
        }
        return Color(hex: "#3C8C8D")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            PulseAvatar(imageData: profile.avatarImageData, name: name, size: 92)
                .accessibilityHidden(true)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name ?? String(localized: "Add your name"))
                        .pulseText(.pageTitle)
                        .foregroundStyle(name == nil ? PulseTheme.textSecondary : PulseTheme.textPrimary)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)
                    Text(subline)
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
                Spacer(minLength: 8)
                PulseLink(PulseEditProfileRoute().route) {
                    HStack(spacing: 7) {
                        Image(systemName: "pencil").font(.system(size: 13, weight: .semibold))
                        Text(String(localized: "Edit")).pulseText(.buttonLabel)
                    }
                    .foregroundStyle(PulseTheme.textPrimary)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 36)
                    .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.control, style: .circular)
                        .fill(Color.white.opacity(0.12)))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .accessibilityLabel(String(localized: "Edit profile"))
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .background(alignment: .top) {
            // The glow behind the header, in the avatar's colour, rising under the bar.
            LinearGradient(stops: [.init(color: glowColor.opacity(0.8), location: 0),
                                   .init(color: glowColor.opacity(0.45), location: 0.4),
                                   .init(color: glowColor.opacity(0.12), location: 0.75),
                                   .init(color: Color.clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 520)
                .padding(.horizontal, -PulseTheme.Layout.pageMargin)
                .offset(y: -170)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// "37 • WHOOP 4.0": age and strap (spec §3.30 [Z]; no username, no country).
    private var subline: String {
        var parts = [String(localized: "\(profile.age) yrs")]
        if let strap = strapName { parts.append(strap) }
        return parts.joined(separator: " • ")
    }

    private var strapName: String? {
        guard let device = appModel.deviceRegistry?.devices.first(where: { $0.status == .active && !$0.isImportSource })
        else { return nil }
        if SourceCoordinator.isWhoop(device), device.model.trimmingCharacters(in: .whitespaces).uppercased() == "WHOOP" {
            return appModel.ble.isWhoop4 ? WhoopModel.whoop4.displayName : WhoopModel.whoop5mg.displayName
        }
        return device.displayName
    }

    /// "Tracking since January 2020" (WHOOP's "Member since", spec §3.30 [Z]).
    private var trackingSince: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().strokeBorder(PulseTheme.textSecondary, lineWidth: 1)
                PulseZenoMonogramShape()
                    .stroke(PulseTheme.textSecondary, style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
                    .frame(width: 9, height: 9)
            }
            .frame(width: 20, height: 20)
            .accessibilityHidden(true)
            Text(String(localized: "Tracking since"))
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
            Text(snapshot?.firstDayKey.map(ProfileFormat.month) ?? (snapshot == nil ? " " : String(localized: "today")))
                .pulseText(.rowSubline)
                .fontWeight(.semibold)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 34)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular).fill(Color(hex: "#292E32").opacity(0.85)))
        .accessibilityElement(children: .combine)
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ s: ProfileSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: PulseTheme.Layout.gridGap) {
                PulseLink(.levels) { levelCard(s.level) }
                    .buttonStyle(PulsePressStyle())
                PulseLink(PulseRoute.healthspan.forExistingEntryPoint) { zenoAgeCard(s.zenoAge) }
                    .buttonStyle(PulsePressStyle())
            }
            .padding(.top, 30)
            PulseLink(.dayStreak) { streakRow(s.streak.current) }
                .buttonStyle(PulsePressStyle())
                .padding(.top, 12)
            if coach.availability != .off {
                PulseLink(.memory) { memoryRow }
                    .buttonStyle(PulsePressStyle())
                    .padding(.top, 12)
            }
            achievements(s)
                .padding(.top, 34)
                .id("pulse.achievements")
            highlights(s)
                .padding(.top, 40)
                .id("pulse.highlights")
            activitySummary(s)
                .padding(.top, 40)
                .id("pulse.activity")
        }
    }

    private func levelCard(_ level: PulseLevels.Progress) -> some View {
        ProfileHalfCard {
            ProfileLevelMedal(level: level.level, size: 74)
        } title: {
            String(localized: "Level \(level.level)")
        } detail: {
            ProfileFormat.recoveries(level.recoveries)
        }
    }

    private func zenoAgeCard(_ age: ProfileZenoAge?) -> some View {
        ProfileHalfCard {
            ProfileZenoOrb(value: age.map { PulseFormat.oneDecimal($0.zenoAge) }, younger: (age?.yearsYounger ?? 0) >= 0,
                           size: 74)
        } title: {
            String(localized: "ZENO Age")
        } detail: {
            guard let age else { return String(localized: "Still calibrating") }
            let years = PulseFormat.oneDecimal(abs(age.yearsYounger))
            return age.yearsYounger >= 0 ? String(localized: "\(years) years younger")
                                         : String(localized: "\(years) years older")
        }
    }

    private func streakRow(_ days: Int) -> some View {
        HStack(spacing: 10) {
            Text(String(localized: "Day streak"))
                .modifier(MoreLabelText())
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            Image(systemName: "flame.fill")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(PulseTheme.Streak.flame(days: days))
            Text(ProfileFormat.days(days))
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            PulseChevron(color: PulseTheme.textTertiary, size: 14)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 56)
        .pulseCardBackground(.rowCard)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var memoryRow: some View {
        HStack(spacing: 16) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(LinearGradient(gradient: PulseTheme.Gradients.aiText, startPoint: .topLeading,
                                                endPoint: .bottomTrailing))
                .accessibilityHidden(true)
            Text(String(localized: "My memory"))
                .modifier(MoreLabelText())
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            PulseChevron(color: PulseTheme.textTertiary, size: 14)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(LinearGradient(gradient: PulseTheme.Gradients.memoryRow, startPoint: .leading, endPoint: .trailing)))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: Achievements

    private func achievements(_ s: ProfileSnapshot) -> some View {
        let unlocked = s.unlockedBadges
        let shown = unlocked.isEmpty ? Array(s.badges.prefix(6)) : Array(unlocked.prefix(12))
        return VStack(alignment: .leading, spacing: 18) {
            ProfileSectionTitle(title: String(localized: "Achievements"), count: unlocked.count) {
                PulseTextAccessory(title: String(localized: "View all"), symbol: "arrow.right") {
                    navigator.open(.achievements)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(shown) { badge in
                        Button { navigator.open(PulseAchievementDetailsRoute(badgeID: badge.id).route) } label: {
                            ProfileBadgeCell(badge: badge, artSize: 76, showsDate: false)
                                .frame(width: 112)
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .padding(.horizontal, -PulseTheme.Layout.pageMargin)
            if unlocked.isEmpty {
                Text(String(localized: "Your first badge unlocks with your first qualifying day."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: Data Highlights

    private func highlights(_ s: ProfileSnapshot) -> some View {
        let h = s.highlights[highlightWindow]
        return VStack(alignment: .leading, spacing: 18) {
            PulseSectionHeader(String(localized: "Data Highlights"), style: .pageTitle)
            VStack(alignment: .leading, spacing: 22) {
                PulseSegmentedControl(options: ProfileWindow.allCases, selection: $highlightWindow) { $0.title }
                if let h, !h.isEmpty {
                    HStack(alignment: .top, spacing: 0) {
                        ProfileHighlightRing(
                            content: .percent(label: String(localized: "Best Sleep"), percent: h.bestSleep,
                                              color: PulseTheme.sleep))
                        ProfileHighlightRing(
                            content: .percent(label: String(localized: "Peak Recovery"), percent: h.peakRecovery,
                                              color: h.peakRecovery.map { PulseTheme.recovery(percent: $0) } ?? PulseTheme.recoveryHigh))
                        ProfileHighlightRing(
                            content: .strain(label: String(localized: "Max Strain"), value: h.maxStrain,
                                             optimalRange: nil, target: nil))
                    }
                    ProfileRuleLabel(String(localized: "Streaks"))
                    HStack(alignment: .top, spacing: 0) {
                        ProfileStreakColumn(family: .sleep, symbol: "moon.fill", days: h.sleepStreak,
                                            caption: String(localized: "70%+ Sleep"))
                        ProfileStreakColumn(family: .recovery, symbol: "figure.mind.and.body", days: h.greenStreak,
                                            caption: String(localized: "Green Recovery"))
                        ProfileStreakColumn(family: .strain, symbol: "figure.strengthtraining.traditional",
                                            days: h.strainStreak, caption: String(localized: "10+ Strain"))
                    }
                    ProfileRuleLabel(String(localized: "Notable stats"))
                    VStack(spacing: 0) {
                        ForEach(Array(notableStats(h).enumerated()), id: \.offset) { i, stat in
                            if i > 0 { PulseDivider() }
                            ProfileNotableRow(symbol: stat.symbol, title: stat.title, value: stat.value, unit: stat.unit)
                        }
                    }
                } else {
                    Text(String(localized: "No scored days in this window yet."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 80)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .circular).fill(PulseTheme.card))
        }
    }

    private func notableStats(_ h: ProfileHighlights) -> [(symbol: String, title: String, value: String, unit: String)] {
        var out: [(String, String, String, String)] = []
        if let v = h.lowestRHR { out.append(("heart.text.square", String(localized: "Lowest RHR"), "\(v)", "bpm")) }
        if let v = h.highestRHR { out.append(("heart.text.square.fill", String(localized: "Highest RHR"), "\(v)", "bpm")) }
        if let v = h.lowestHRV { out.append(("waveform.path.ecg", String(localized: "Lowest HRV"), PulseFormat.whole(v), "ms")) }
        if let v = h.highestHRV { out.append(("waveform.path.ecg.rectangle", String(localized: "Highest HRV"), PulseFormat.whole(v), "ms")) }
        if let v = h.maxHeartRate { out.append(("heart.fill", String(localized: "Max Heart Rate"), "\(v)", "bpm")) }
        if let v = h.longestSleepMin { out.append(("moon.zzz.fill", String(localized: "Longest Sleep"), PulseFormat.hoursMinutes(v), "hr")) }
        if let v = h.lowestRecovery { out.append(("battery.25percent", String(localized: "Lowest Recovery"), PulseFormat.whole(v), "%")) }
        return out.map { (symbol: $0.0, title: $0.1, value: $0.2, unit: $0.3) }
    }

    // MARK: Activity Summary

    private func activitySummary(_ s: ProfileSnapshot) -> some View {
        let summary = s.activity[activityWindow] ?? ProfileActivitySummary(total: 0, sports: [])
        let shown = showsAllSports ? summary.sports : Array(summary.sports.prefix(3))
        let top = summary.sports.first?.count ?? 1
        return VStack(alignment: .leading, spacing: 18) {
            PulseSectionHeader(String(localized: "Activity Summary"), style: .pageTitle)
            VStack(alignment: .leading, spacing: 20) {
                PulseSegmentedControl(options: ProfileWindow.allCases, selection: $activityWindow) { $0.title }
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\(PulseFormat.grouped(Double(summary.total)))x")
                        .font(PulseType.numeral(34, hero: true))
                        .foregroundStyle(PulseTheme.textPrimary)
                    Text(String(localized: "Total activities"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textTertiary)
                }
                .accessibilityElement(children: .combine)
                if summary.sports.isEmpty {
                    Text(String(localized: "No activities logged in this window."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                } else {
                    HStack {
                        Text(String(localized: "Activity | Avg. Strain"))
                        Spacer()
                        Text(String(localized: "Total"))
                    }
                    .pulseText(.label)
                    .foregroundStyle(PulseTheme.textSecondary)
                    VStack(spacing: 0) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { i, sport in
                            if i > 0 { PulseDivider().padding(.vertical, 2) }
                            ProfileSportRow(sport: sport, fraction: Double(sport.count) / Double(max(1, top)))
                        }
                    }
                    if summary.sports.count > 3 {
                        Button { showsAllSports.toggle() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: showsAllSports ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(showsAllSports ? String(localized: "Show less") : String(localized: "Show all"))
                                    .pulseText(.buttonLabel)
                            }
                            .foregroundStyle(PulseTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
                                .fill(PulseTheme.nested))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .circular).fill(PulseTheme.card))
        }
    }

    /// DEBUG `--more-open edit-profile` / `badge:<id>` for captures.
    private func openDebugPage() {
        #if DEBUG
        guard let name = PulseMoreDebug.take(prefixes: ["edit-profile"]) else { return }
        if name == "edit-profile" { navigator.open(PulseEditProfileRoute().route) }
        #endif
    }
}

// MARK: - Pieces

/// A 24 pt section title with its grey count and an accessory at the right ("Achievements (34) VIEW ALL
/// →"). The title is one word that must never break inside itself (DR §2), so at large text sizes the
/// accessory moves under the title instead of squeezing it.
private struct ProfileSectionTitle<Accessory: View>: View {
    let title: String
    var count: Int?
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                titleText
                Spacer(minLength: 8)
                accessory()
            }
            VStack(alignment: .leading, spacing: 4) {
                titleText
                accessory()
            }
        }
        .padding(.horizontal, 4)
    }

    private var titleText: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .pulseText(.pageTitle)
                .foregroundStyle(PulseTheme.textPrimary)
            if let count {
                Text(verbatim: "(\(count))")
                    .pulseText(.pageTitle)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A half-width Profile card (LEVEL, ZENO AGE): art, a caps title and a grey line, "›" at the top-right.
private struct ProfileHalfCard<Art: View>: View {
    @ViewBuilder let art: () -> Art
    let title: () -> String
    let detail: () -> String

    var body: some View {
        VStack(spacing: 10) {
            art()
                .frame(height: 78)
                .padding(.top, 20)
            VStack(spacing: 4) {
                Text(title())
                    .modifier(MoreLabelText(tracking: 1.4))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(detail())
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular).fill(PulseTheme.card))
        .overlay(alignment: .topTrailing) {
            PulseChevron(color: PulseTheme.textTertiary, size: 15)
                .padding(16)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// ZENO Age's mini orb: a green sphere (younger) or amber (older) holding the value; a dormant grey one
/// while it calibrates. ZENO's own drawing, no WHOOP Age art.
struct ProfileZenoOrb: View {
    let value: String?
    var younger = true
    var size: CGFloat = 74

    var body: some View {
        let tint = value == nil ? PulseTheme.Healthspan.unlockingInterior
            : (younger ? PulseTheme.Healthspan.youngerParticles : PulseTheme.negative)
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.55), tint.opacity(0.2), Color.black.opacity(0.6)],
                                     center: .init(x: 0.4, y: 0.35), startRadius: 2, endRadius: size * 0.6))
            Circle()
                .strokeBorder(tint.opacity(value == nil ? 0.35 : 0.8), lineWidth: 1.5)
            Text(value ?? "--")
                .font(PulseType.numeral(size * 0.33, hero: true))
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A highlight ring: an 88 pt dial (6 pt stroke) with its 24 pt value and a 14 pt Semibold label under
/// it ("Best Sleep", spec §2.5 "Profile highlight rings").
private struct ProfileHighlightRing: View {
    let content: PulseDialContent

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                PulseRing(fraction: content.fraction, color: content.color, diameter: 82, thickness: 6)
                PulseValueText(value: content.valueText, unit: content.unitText, style: .mediumValue,
                               unitStyle: .mediumValue, color: content.isPlaceholder ? PulseTheme.textDisabled : PulseTheme.textPrimary,
                               unitColor: PulseTheme.textPrimary)
            }
            .frame(width: 82, height: 82)
            Text(content.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.accessibilityLabel)
    }
}

/// An 11 pt caps label with a hairline running to the right ("STREAKS ———").
private struct ProfileRuleLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        HStack(spacing: 10) {
            // The label takes the width first, so the rule shrinks before the label wraps.
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
            Rectangle().fill(PulseTheme.divider).frame(height: 1)
        }
    }
}

/// One STREAKS column: a scalloped badge glyph in its pillar's hue over "44 Days" and its caption.
private struct ProfileStreakColumn: View {
    let family: PulseAchievements.Family
    let symbol: String
    let days: Int
    let caption: String

    var body: some View {
        let colors = ProfileArtPalette.family(family)
        VStack(spacing: 6) {
            ZStack {
                ProfileBadgeShape(family: .activities)
                    .fill(colors[1].opacity(0.22))
                ProfileBadgeShape(family: .activities)
                    .stroke(colors[0].opacity(0.8), lineWidth: 1.2)
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(colors[0])
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
            Text(ProfileFormat.days(days))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PulseTheme.textPrimary)
            // Two centred lines at large text sizes rather than "Green Recov…".
            Text(caption)
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A NOTABLE STATS row: a gold scalloped icon, the stat's name, the value with its small grey unit.
private struct ProfileNotableRow: View {
    let symbol: String
    let title: String
    let value: String
    let unit: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                ProfileBadgeShape(family: .activities)
                    .stroke(Color(hex: "#C9A15A").opacity(0.85), lineWidth: 1.2)
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#E8C27A"))
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
            Text(title)
                .pulseText(.filter)
                .foregroundStyle(PulseTheme.textPrimary)
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).pulseText(.rowValue).foregroundStyle(PulseTheme.textPrimary)
                Text(unit).pulseText(.legend).foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

/// An Activity Summary row: the sport's glyph and caps name with its average Strain, the count in strain
/// blue at the right, and a full-width blue bar over the hatched track.
private struct ProfileSportRow: View {
    let sport: ProfileActivitySummary.Sport
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: sport.symbol)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(PulseTheme.textSecondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(sport.name)
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                if let strain = sport.averageStrain {
                    Text(PulseFormat.oneDecimal(strain))
                        .font(PulseType.numeral(14))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
                Spacer(minLength: 8)
                Text(verbatim: "\(PulseFormat.grouped(Double(sport.count)))x")
                    .font(PulseType.numeral(17))
                    .foregroundStyle(PulseTheme.strain)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    PulseHatchedTrack(cornerRadius: 3)
                    Capsule().fill(PulseTheme.strain)
                        .frame(width: max(6, geo.size.width * CGFloat(min(1, max(0, fraction)))))
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sport.name)
        .accessibilityValue(sport.averageStrain.map {
            String(localized: "\(sport.count) times, average Strain \(PulseFormat.oneDecimal($0))")
        } ?? String(localized: "\(sport.count) times"))
    }
}
#endif
