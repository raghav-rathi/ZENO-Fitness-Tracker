#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

// MARK: - Shared by Profile, Levels, Achievements and Day Streak (WHOOP_UI_SPEC §3.30)

/// The wearer's name, the one profile field ZENO did not store before Edit Profile. Kept beside
/// `ProfileStore`'s own `profile.*` keys so it can move into the store unchanged; local to this iPhone
/// like the rest of the profile.
enum PulseProfileIdentity {
    static let nameKey = "profile.displayName"

    /// The stored name, trimmed; nil when none is set.
    static var storedName: String? {
        let raw = UserDefaults.standard.string(forKey: nameKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (raw?.isEmpty ?? true) ? nil : raw
    }
}

extension View {
    /// Build the profile snapshot for this page (always today), reloading when the store refreshes or a
    /// display preference changes. Keeps the old snapshot on screen while a newer one builds.
    func profileSnapshot(_ snapshot: Binding<ProfileSnapshot?>) -> some View {
        modifier(ProfileSnapshotTask(snapshot: snapshot))
    }
}

private struct ProfileSnapshotTask: ViewModifier {
    @Binding var snapshot: ProfileSnapshot?
    @Environment(PulseModel.self) private var model
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var repo: Repository

    func body(content: Content) -> some View {
        let age = profile.age
        content.task(id: "\(model.healthKey)|\(age)") {
            // Read in the same main-actor turn as the request `build` makes, so the flag describes the
            // day list the build reads.
            let loaded = repo.loaded
            if let built = await model.build(dayOffset: 0, { builder, request in
                await builder.profile(request, calendarAge: age, storeLoaded: loaded)
            }) {
                snapshot = built
            }
        }
    }
}

// MARK: Day keys

enum ProfileFormat {
    /// "Jul 24, 2026" for a day key, at UTC like every day key.
    static func day(_ key: String) -> String { PulseFormat.dayLabel(key, template: "MMMdyyyy") }

    /// "January 2020" for a day key.
    static func month(_ key: String) -> String { PulseFormat.dayLabel(key, template: "MMMMyyyy") }

    /// A whole count with its noun: "1 Recovery", "2,344 Recoveries".
    static func recoveries(_ n: Int) -> String {
        n == 1 ? String(localized: "1 Recovery") : String(localized: "\(PulseFormat.grouped(Double(n))) Recoveries")
    }

    static func days(_ n: Int) -> String {
        n == 1 ? String(localized: "1 Day") : String(localized: "\(PulseFormat.grouped(Double(n))) Days")
    }
}

// MARK: Badge names and art

/// How a badge is named, described and drawn. ZENO's own names (spec §3.30 [Z]: WHOOP's are not reused).
struct ProfileBadgeInfo {
    let name: String
    /// The rule, as one line ("Nights of 85%+ Sleep Performance").
    let criterion: String
    let symbol: String
    /// The red recovery shield (a Recovery of 5% or less).
    var alarm = false

    init(_ badge: PulseAchievements.Badge) {
        if let sport = badge.sport {
            let display = WorkoutSource.displaySport(sport)
            name = String(localized: "\(display) Regular")
            criterion = String(localized: "\(display) activities logged")
            symbol = sportSymbol(sport)
            return
        }
        switch badge.rule {
        case .restfulNights:
            name = String(localized: "Restful Nights")
            criterion = String(localized: "Nights of 85%+ Sleep Performance")
            symbol = "moon.stars.fill"
        case .fullEight:
            name = String(localized: "Full Eight")
            criterion = String(localized: "Nights with 8+ hours asleep")
            symbol = "bed.double.fill"
        case .steadyWeek:
            name = String(localized: "Steady Week")
            criterion = String(localized: "7 nights in a row of 70%+ Sleep Performance")
            symbol = "metronome.fill"
        case .greenLight:
            name = String(localized: "Green Light")
            criterion = String(localized: "Green Recoveries")
            symbol = "mountain.2.fill"
        case .greenStreak:
            name = String(localized: "Green Streak")
            criterion = String(localized: "7 green Recoveries in a row")
            symbol = "chart.bar.fill"
        case .nearPerfect:
            name = String(localized: "Near Perfect")
            criterion = String(localized: "A Recovery of 99% or more")
            symbol = "battery.100percent"
        case .runningOnEmpty:
            name = String(localized: "Running on Empty")
            criterion = String(localized: "A Recovery of 5% or less")
            symbol = "battery.0percent"
            alarm = true
        case .bigDays:
            name = String(localized: "Big Days")
            criterion = String(localized: "Days of 14+ Strain")
            symbol = "flame.fill"
        case .redline:
            name = String(localized: "Redline")
            criterion = String(localized: "A day of 18+ Strain")
            symbol = "gauge.with.dots.needle.100percent"
        case .onTarget:
            name = String(localized: "On Target")
            criterion = String(localized: "Days your Strain finished in its optimal range")
            symbol = "scope"
        case .youngerSelf:
            name = String(localized: "Younger Self")
            criterion = String(localized: "ZENO Age a whole year or more below your age")
            symbol = "hourglass"
        case nil:
            name = String(localized: "Achievement")
            criterion = ""
            symbol = "rosette"
        }
    }

    /// The badge's big number as it is printed: the milestone, or "-4 Yrs" for ZENO Age.
    static func countText(_ badge: PulseAchievements.Badge) -> String {
        if badge.kind == .value && badge.shown > 0 {
            return String(localized: "-\(badge.shown) Yrs")
        }
        return PulseFormat.grouped(Double(badge.shown))
    }
}

/// A badge in the grid or the Profile carousel: the art with its big count over the lower third, the
/// name (13 pt Medium, two lines), and the unlock date (13 pt, 50%) when asked for. Measured on
/// profile-community-2026/80: art ≈70 pt, count digits 22–23 pt tall (≈32 pt Heavy condensed).
struct ProfileBadgeCell: View {
    let badge: PulseAchievements.Badge
    var artSize: CGFloat = 70
    var showsDate = true

    var body: some View {
        let info = ProfileBadgeInfo(badge)
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                ProfileBadgeArt(family: badge.family, symbol: info.symbol, stars: badge.stars,
                                locked: !badge.isUnlocked, alarm: info.alarm, size: artSize)
                    .padding(.bottom, artSize * 0.3)
                Text(ProfileBadgeInfo.countText(badge))
                    .font(PulseType.numeral(artSize * 0.46, weight: .heavy))
                    .foregroundStyle(badge.isUnlocked ? PulseTheme.textPrimary : ProfileArtPalette.lockedGlyph)
                    .shadow(color: Color.black.opacity(0.7), radius: 6, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            // Wrapped between words only: "Weightlifting Regular" never breaks inside "Weightlifting".
            ProfileWordWrapText(info.name, size: 13, weight: .medium, relativeTo: .footnote)
                .foregroundStyle(PulseTheme.textPrimary)
            if showsDate, let day = badge.unlockedDay {
                Text(ProfileFormat.day(day))
                    .pulseText(.rowSubline)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(info.name)
        .accessibilityValue(badge.isUnlocked
            ? String(localized: "\(ProfileBadgeInfo.countText(badge)), \(info.criterion)")
            : String(localized: "Locked, \(info.criterion)"))
        .accessibilityAddTraits(.isButton)
    }
}

/// Achievement Details for one badge (a push from the grid or the Profile carousel).
struct PulseAchievementDetailsRoute: PulseScreenRoute {
    let badgeID: String
    var view: some View { PulseAchievementDetailsView(badgeID: badgeID) }
}

// MARK: Unlock modal

/// The record of which unlocks the wearer has been shown, and the modal that shows a new one (spec §3.30
/// "Unlock modal"). The first look records a baseline silently, so years of history do not announce
/// every badge at once; after that each new milestone (and each badge's first occurrence) shows once, in
/// turn: closing the modal acknowledges only the unlock it showed, and the next pending one follows.
enum ProfileUnlockStore {
    private static let badgesKey = "pulse.achievements.acknowledged"
    private static let streakKey = "pulse.streak.acknowledgedMilestone"

    static var acknowledged: [String: Int]? {
        guard let data = UserDefaults.standard.data(forKey: badgesKey) else { return nil }
        return try? JSONDecoder().decode([String: Int].self, from: data)
    }

    /// The silent baseline: every badge as it stands.
    static func acknowledgeBaseline(_ badges: [PulseAchievements.Badge]) {
        store(PulseAchievements.acknowledging(badges))
    }

    /// The one badge the wearer was shown, merged into the record.
    static func acknowledge(_ badge: PulseAchievements.Badge) {
        store(PulseAchievements.acknowledging(badge, into: acknowledged ?? [:]))
    }

    private static func store(_ record: [String: Int]) {
        if let data = try? JSONEncoder().encode(record) { UserDefaults.standard.set(data, forKey: badgesKey) }
    }

    static var acknowledgedStreakMilestone: Int? {
        UserDefaults.standard.object(forKey: streakKey) as? Int
    }

    /// The streak's silent baseline: the last milestone at or below `days`.
    static func acknowledgeStreak(days: Int) {
        UserDefaults.standard.set(PulseDayStreak.lastMilestone(atOrBelow: days) ?? 0, forKey: streakKey)
    }

    /// The streak milestone the wearer was shown.
    static func acknowledgeStreak(milestone: Int) {
        UserDefaults.standard.set(max(milestone, acknowledgedStreakMilestone ?? 0), forKey: streakKey)
    }
}

/// What the unlock modal shows.
enum ProfileUnlock: Identifiable, Equatable {
    case badge(PulseAchievements.Badge)
    case streak(milestone: Int, days: Int)

    var id: String {
        switch self {
        case .badge(let b): return "badge-\(b.id)-\(b.shown)"
        case .streak(let m, _): return "streak-\(m)"
        }
    }
}

extension View {
    /// Present the unlock modal once a snapshot shows an unlock the wearer has not seen.
    func pulseAchievementUnlocks(_ snapshot: ProfileSnapshot?) -> some View {
        modifier(ProfileUnlockPresenter(snapshot: snapshot))
    }
}

/// Which presenter holds the modal. Profile, Achievements and Day Streak each carry a presenter and can be
/// alive at once (Profile under a pushed Achievements), so one refresh would otherwise present the same
/// unlock twice: the first presenter to claim it shows it, the others wait.
@MainActor
private enum ProfileUnlockGate {
    static var holder: UUID?
    #if DEBUG
    /// `--more-unlock` shows one badge once per launch, not again after every close.
    static var debugShown = false
    #endif
}

private struct ProfileUnlockPresenter: ViewModifier {
    let snapshot: ProfileSnapshot?
    @State private var unlock: ProfileUnlock?
    @State private var id = UUID()
    @Environment(\.pulseNavigator) private var navigator

    func body(content: Content) -> some View {
        content
            // The seq alone can repeat: a build in the turn between the store's load and the model's seq
            // catching up carries the old seq with a loaded store.
            .onChange(of: snapshot.map { "\($0.seq)|\($0.storeLoaded)" }) { _, _ in evaluate() }
            .onAppear(perform: evaluate)
            .onDisappear { release() }
            // Once a modal closes, the next pending unlock (a badge behind a streak milestone, a second
            // badge from the same night) gets its turn.
            .fullScreenCover(item: $unlock, onDismiss: {
                release()
                evaluate()
            }) { unlock in
                PulseUnlockModal(unlock: unlock, onClose: { finish(unlock) }, onView: {
                    finish(unlock)
                    switch unlock {
                    case .badge(let badge): navigator.open(PulseAchievementDetailsRoute(badgeID: badge.id).route)
                    case .streak: navigator.open(.dayStreak)
                    }
                })
                .presentationBackground(.clear)
            }
    }

    private func evaluate() {
        // A build from before the store's first load sees no days at all. Taking it as the first look would
        // record a zero baseline, and the real history would then arrive as a run of "new" unlocks.
        guard let snapshot, snapshot.storeLoaded, unlock == nil else { return }
        guard ProfileUnlockGate.holder == nil || ProfileUnlockGate.holder == id else { return }
        #if DEBUG
        if PulseMoreDebug.flag("--more-unlock") {
            if !ProfileUnlockGate.debugShown, let first = snapshot.unlockedBadges.first {
                ProfileUnlockGate.debugShown = true
                present(.badge(first))
            }
            return
        }
        #endif
        // The day streak first: it is the one WHOOP announces over Home.
        if let milestone = PulseDayStreak.newMilestone(days: snapshot.streak.current,
                                                       acknowledged: ProfileUnlockStore.acknowledgedStreakMilestone) {
            present(.streak(milestone: milestone, days: snapshot.streak.current))
            return
        }
        if ProfileUnlockStore.acknowledgedStreakMilestone == nil {
            ProfileUnlockStore.acknowledgeStreak(days: snapshot.streak.current)
        }
        let known = ProfileUnlockStore.acknowledged
        guard known != nil else {
            ProfileUnlockStore.acknowledgeBaseline(snapshot.badges)      // the first look is a baseline
            return
        }
        if let fresh = PulseAchievements.newUnlocks(snapshot.badges, acknowledged: known).first {
            present(.badge(fresh))
        }
    }

    private func present(_ next: ProfileUnlock) {
        ProfileUnlockGate.holder = id
        unlock = next
    }

    /// Acknowledge exactly what the modal showed, and close it.
    private func finish(_ shown: ProfileUnlock) {
        switch shown {
        case .badge(let badge): ProfileUnlockStore.acknowledge(badge)
        case .streak(let milestone, _): ProfileUnlockStore.acknowledgeStreak(milestone: milestone)
        }
        unlock = nil
    }

    private func release() {
        if unlock == nil, ProfileUnlockGate.holder == id { ProfileUnlockGate.holder = nil }
    }
}

/// The unlock modal: a black 85% scrim, the badge art top-left with its number, the name (26 pt), the
/// criterion (15 pt, 70%; WHOOP's percentile sentence is [POP] and left out), a "Your next milestone"
/// card, and CLOSE (outlined) beside VIEW (white).
struct PulseUnlockModal: View {
    let unlock: ProfileUnlock
    let onClose: () -> Void
    let onView: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            PulseTheme.dialogScrim.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 0)
                hero
                Text(title)
                    .profileFont(26, weight: .semibold, relativeTo: .title)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .pulseText(.subtitle)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let next = nextMilestone {
                    nextCard(next)
                }
                HStack(spacing: 16) {
                    Button(action: onClose) {
                        Text(String(localized: "Close"))
                            .pulseText(.capsuleLabel)
                            .foregroundStyle(PulseTheme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(PulseTheme.textTertiary, lineWidth: 1.5))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    Button(action: onView) {
                        Text(String(localized: "View"))
                            .pulseText(.capsuleLabel)
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .environment(\.colorScheme, .dark)
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private var hero: some View {
        switch unlock {
        case .badge(let badge):
            let info = ProfileBadgeInfo(badge)
            ZStack(alignment: .bottomLeading) {
                ProfileBadgeArt(family: badge.family, symbol: info.symbol, stars: badge.stars, alarm: info.alarm,
                                size: 150)
                    .padding(.bottom, 40)
                Text(ProfileBadgeInfo.countText(badge))
                    .font(PulseType.numeral(72, weight: .heavy))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .shadow(color: Color.black.opacity(0.7), radius: 8, y: 2)
                    .padding(.leading, 24)
            }
        case .streak(_, let days):
            ZStack(alignment: .bottomLeading) {
                ProfileFlameArt(days: days, size: 130)
                Text(PulseFormat.grouped(Double(days)))
                    .font(PulseType.numeral(72, weight: .heavy))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .shadow(color: Color.black.opacity(0.7), radius: 8, y: 2)
                    .padding(.leading, 24)
            }
        }
    }

    private var title: String {
        switch unlock {
        case .badge(let badge): return ProfileBadgeInfo(badge).name
        case .streak: return String(localized: "New Day Streak Unlocked")
        }
    }

    private var message: String {
        switch unlock {
        case .badge(let badge):
            let info = ProfileBadgeInfo(badge)
            switch badge.kind {
            case .cumulative:
                return String(localized: "\(info.criterion): \(PulseFormat.grouped(Double(badge.count))) so far.")
            case .event:
                return badge.shown == 1 ? String(localized: "\(info.criterion), for the first time.")
                                        : String(localized: "\(info.criterion): \(badge.shown) times so far.")
            case .value:
                return String(localized: "Your ZENO Age is now \(badge.shown) years younger than your age.")
            }
        case .streak(let milestone, _):
            return String(localized: "\(milestone) days in a row with a scored Recovery. Keep wearing your strap day and night.")
        }
    }

    /// (target, remaining, fraction) for the next-milestone card.
    private var nextMilestone: (text: String, fraction: Double)? {
        switch unlock {
        case .badge(let badge):
            guard let next = badge.nextMilestone else { return nil }
            if badge.kind == .value {
                return (String(localized: "\(next) Years Younger"), 0)
            }
            return (String(localized: "\(PulseFormat.grouped(Double(next))) · \(badge.remaining ?? 0) more"),
                    badge.milestoneFraction ?? 0)
        case .streak(_, let days):
            let p = PulseDayStreak.milestoneProgress(days: days)
            return (String(localized: "\(p.days)/\(p.next) · \(p.remaining) more days"), p.fraction)
        }
    }

    private func nextCard(_ next: (text: String, fraction: Double)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Your Next Milestone"))
                .pulseText(.coachingTitle)
                .foregroundStyle(PulseTheme.positive)
            Text(next.text)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(PulseTheme.track)
                    Capsule().fill(PulseTheme.positive).frame(width: geo.size.width * CGFloat(next.fraction))
                }
            }
            .frame(height: 4)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(Color.black)
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .strokeBorder(PulseTheme.outlinedBorder, lineWidth: 1)))
    }
}
#endif

#if os(iOS)
// MARK: - A flat profile page

/// A pushed profile page on a flat colour rather than the slate gradient (Levels #1C2125 / #13161B, Day
/// Streak #101518, sampled on profile-community-2026/56, 60, 61 and reviews/r48): Pulse's own bar (or the
/// Levels page's circular back button) over a scroll view, the swipe-back kept.
struct ProfileFlatPage<Content: View>: View {
    let title: String
    var trailing: PulseNavTrailing = .none
    let background: Color
    /// The Levels page's 34 pt outlined circle in place of the thin "‹" (spec §1.6).
    var circularBack = false
    /// A "?" in a 22 pt grey circle right of the title (Levels).
    var onHelp: (() -> Void)?
    /// Whether the content has loaded (gates the DEBUG `--pulse-scroll` jump).
    var ready = true
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.pulseModalRoot) private var modalRoot

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    content()
                }
                .padding(.bottom, PulseTheme.Layout.plainBottomInset)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .pulseDebugScroll(proxy, ready: ready)
        }
        .background(background.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            header
                .background(background.ignoresSafeArea(edges: .top))
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(PulseSwipeBackEnabler())
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var header: some View {
        if circularBack {
            ZStack {
                HStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundStyle(PulseTheme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    if let onHelp {
                        Button(action: onHelp) {
                            Text(verbatim: "?")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(PulseTheme.textTertiary)
                                .frame(width: 22, height: 22)
                                .overlay(Circle().strokeBorder(PulseTheme.textTertiary, lineWidth: 1.2))
                                .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PulsePressStyle())
                        .accessibilityLabel(String(localized: "About levels"))
                    }
                }
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: modalRoot ? "xmark" : "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(PulseTheme.textPrimary)
                            .frame(width: 34, height: 34)
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                            .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(modalRoot ? String(localized: "Close") : String(localized: "Back"))
                    Spacer()
                }
                .padding(.horizontal, PulseTheme.Layout.pageMargin)
            }
            .frame(height: PulseTheme.Header.navBar)
            .padding(.top, PulseTheme.Header.navBarTop)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        } else {
            PulseNavBar(title: title, leading: modalRoot ? .close : .back, trailing: trailing, onLeading: { dismiss() })
        }
    }
}
#endif
