#if os(iOS)
import SwiftUI
import StrandDesign
import StrandAnalytics

/// Pulse Home (WHOOP_UI_SPEC §3.1), in the observed 2026 order: the header, a status banner when there is
/// one, ZENO's wordmark, the three dials, the coaching card stack, the HEALTH MONITOR | STRESS MONITOR
/// tiles, My Day (the Daily Outlook pill or Ask row, Today's Activities, Tonight's Sleep, My Journal, the
/// Menstrual card), My Plan, Looking Ahead while calibrating, My Dashboard (the wearer's rows and charts)
/// and the wordmark footer.
///
/// Three variants (§2.9): today; a past day (ACTIVITIES with a single ADD, no banner, coaching, tiles, pill
/// or Tonight's Sleep; Journal, Plan and Dashboard stay); and the new member before the first Recovery
/// (straight from the dials to "Get Started" with its cards and the Ask well in My Day's place, then
/// Tonight's Sleep, Looking Ahead and a personalizing dashboard).
///
/// Owned by group "home". The dials, activities and vitals render `model.home`, built off the main actor;
/// Home's own facts (dashboard rows, coaching inputs, the outlook) come from `homeExtras`, built beside it
/// for the same day. Swiping sideways changes the day, as do the header's pager and calendar. Once the
/// dials scroll off, the mini-ring row pins under the status bar.
struct PulseHomeView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.pulseNavigator) private var navigator
    @AppStorage(PulseDashboardLayout.storageKey) private var dashboardLayout = ""
    @State private var dialsScrolledOff = false
    @State private var extras: HomeExtrasSnapshot?
    /// The last extras built for today, kept while another day is on screen: stepping back to today
    /// shows them until today's next build lands, so the coaching card does not pop in above the tiles.
    @State private var todayExtras: HomeExtrasSnapshot?
    /// Bumped whenever `model.home` is replaced, so Home's own facts rebuild beside it.
    @State private var homeVersion = 0

    /// The sticky row's 44 pt hit area, centred 19.5 pt under the safe-area top.
    private static let stickyRowTop = PulseTheme.Header.stickyRowCentre - PulseTheme.Layout.minTapTarget / 2

    private var dashboardItems: [PulseDashboardItem] { PulseHomeDebug.dashboard ?? PulseDashboardLayout.decode(dashboardLayout) }

    /// The extras for the day on screen, never another day's.
    private var currentExtras: HomeExtrasSnapshot? {
        guard let home = model.home else { return nil }
        return PulseHomeSections.extras(for: home, latest: extras, today: todayExtras)
    }

    var body: some View {
        PulseScreenScaffold(role: .tabRoot, showsNavigationBar: false, spacing: 0, topPadding: 0,
                            refresh: { await model.pullToRefresh() }, ready: model.home != nil && currentExtras != nil,
                            topBackdrop: dialsScrolledOff
                                ? .extended(extra: Self.stickyRowTop + PulseTheme.Layout.minTapTarget + 12,
                                            fade: PulseTheme.Header.stickyFade)
                                : .automatic) {
            PulseHomeHeader()
            if model.dayOffset == 0 {
                PulseHomeStatusBanner()
            }
            PulseZenoWordmark()
                .frame(maxWidth: .infinity)
                .padding(.top, PulseTheme.Header.wordmarkTop)
            PulseDialsRow(home: model.home)
                .padding(.top, PulseTheme.Header.dialsTop)
                .pulseScrolledPast($dialsScrolledOff, threshold: 8)
            PulseHomeContent(extras: extras, todayExtras: todayExtras, dashboardItems: dashboardItems)
        }
        .overlay(alignment: .top) {
            if dialsScrolledOff, let home = model.home {
                PulseMiniRingRow(items: home.dials.map { dial in
                    PulseMiniRingRow.Item(id: dial.score.rawValue,
                                          content: dial.dialContent(target: home.target),
                                          action: { navigator.open(.dive(dial.score)) })
                })
                .padding(.top, Self.stickyRowTop)
                .transition(.opacity)
            }
        }
        .animation(PulseMotion.chrome, value: dialsScrolledOff)
        .simultaneousGesture(daySwipe)
        .sensoryFeedback(.selection, trigger: model.dayOffset)
        .onChange(of: model.home) { _, _ in homeVersion &+= 1 }
        .task(id: "\(model.detailKey)|\(homeVersion)|\(dashboardItems.map(\.rawValue).joined(separator: ","))") {
            await loadExtras()
        }
        #if DEBUG
        .task(id: currentExtras != nil) { PulseHomeDebug.openOnce(home: model.home, extras: currentExtras, navigator: navigator) }
        #endif
    }

    /// Build Home's own facts for the snapshot on screen (off the main actor), keeping the last ones when
    /// a newer refresh or another day superseded the build.
    private func loadExtras() async {
        guard let home = model.home, home.day.offset == model.dayOffset else { return }
        let items = dashboardItems
        if let built = await model.build(dayOffset: home.day.offset, { builder, request in
            await builder.homeExtras(request, home: home, items: items)
        }) {
            extras = built
            if built.day.isToday { todayExtras = built }
        }
    }

    /// A decisive horizontal flick changes the day: right is older, left is newer
    /// (`TodayView.daySwipeDelta`, the direction both platforms pin).
    private var daySwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width, dy = value.translation.height
                guard abs(dx) > abs(dy) * 1.5, abs(dx) > 50 else { return }
                model.stepDay(TodayView.daySwipeDelta(dx: dx))
            }
    }
}

// MARK: - Dials

/// Sleep · Recovery · Strain (§2.5), each opening its deep dive, in three equal columns between the page
/// margins with one label size (`PulseDialColumns`). The same row shows the loading state, so the arcs
/// sweep once when the first snapshot lands and never again on the way back from a dive.
struct PulseDialsRow: View {
    let home: HomeSnapshot?

    private var contents: [(score: PulseScore, content: PulseDialContent)] {
        guard let home else {
            return PulseScore.allCases.map { score in
                let empty = score == .strain
                    ? PulseDialContent.strain(label: score.displayName, value: nil, optimalRange: nil, target: nil)
                    : PulseDialContent.percent(label: score.displayName, percent: nil, color: score.tint)
                return (score, empty)
            }
        }
        return home.dials.map { ($0.score, $0.dialContent(target: home.target)) }
    }

    var body: some View {
        let dials = contents
        PulseDialColumns(contents: dials.map(\.content), routes: dials.map { PulseRoute.dive($0.score) })
    }
}

// MARK: - Content

/// Everything below the dials, rendered from `model.home` and Home's own facts: white-10% skeleton blocks
/// while the first of both builds (after 200 ms, for at least 400 ms), never a spinner, so the coaching
/// card never pops in above the tiles after launch.
struct PulseHomeContent: View {
    /// The latest extras built, possibly for the previous day while a new day builds.
    let extras: HomeExtrasSnapshot?
    /// The last extras built for today (see `PulseHomeView.todayExtras`).
    let todayExtras: HomeExtrasSnapshot?
    let dashboardItems: [PulseDashboardItem]

    @Environment(PulseModel.self) private var model

    var body: some View {
        PulseLoadingGate(isLoading: model.home == nil || extras == nil) {
            if let home = model.home {
                PulseHomeSections(home: home, extras: extras, todayExtras: todayExtras, dashboardItems: dashboardItems)
                    // While a newly selected day builds, the previous day's numbers dim rather than pass for it.
                    .opacity(model.homeIsStale ? 0.45 : 1)
                    .animation(.easeOut(duration: 0.15), value: model.homeIsStale)
            }
        } skeleton: {
            PulseSkeleton.cards([88, 48, 180, 150])
                .padding(.top, 30)
        }
    }
}

/// The sections in WHOOP's 2026 order, for today, a past day or a new member.
struct PulseHomeSections: View {
    let home: HomeSnapshot
    /// Home's own facts. While a newly selected day's are still building these are the previous day's:
    /// only the dashboard rows read them then, dimmed (`extrasStale`); everything day-specific reads
    /// `current`.
    let extras: HomeExtrasSnapshot?
    /// The last extras built for today: back on today they stand in until today's next build lands.
    let todayExtras: HomeExtrasSnapshot?
    let dashboardItems: [PulseDashboardItem]

    /// The extras for the day on screen, never another day's.
    private var current: HomeExtrasSnapshot? { Self.extras(for: home, latest: extras, today: todayExtras) }
    private var extrasStale: Bool { extras != nil && current == nil }

    /// The newest extras built for `home`'s day: the latest build, else (on today) today's last one.
    static func extras(for home: HomeSnapshot, latest: HomeExtrasSnapshot?,
                       today: HomeExtrasSnapshot?) -> HomeExtrasSnapshot? {
        if let latest, latest.day == home.day { return latest }
        if let today, today.day == home.day { return today }
        return nil
    }

    @Environment(\.pulseCoach) private var coach

    private var isToday: Bool { home.day.isToday }
    /// Before the first Recovery: read off the HomeSnapshot itself, so the variant never flips once the
    /// extras land.
    private var isNewMember: Bool { isToday && home.scoredDays == 0 }

    var body: some View {
        // The stress reading's update time, resolved once with one clock for the tile and the card.
        let stressUpdated = PulseHomeStress.updated(home.stress, now: Date())
        VStack(alignment: .leading, spacing: 0) {
            // The new member's Home goes straight from the dials to Get Started (onboarding/31a,
            // completeness-critic/24): no coaching card and no monitor tiles yet.
            if isToday && !isNewMember {
                if let base = current?.coaching {
                    // The stack, when a card is due, then the tiles 22 pt under its peek.
                    PulseCoachingStackHost(base: base, home: home, grades: current?.monitor,
                                           stressUpdated: stressUpdated)
                } else {
                    PulseMonitorTiles(home: home, grades: current?.monitor, stressUpdated: stressUpdated)
                        .padding(.top, PulseHomeSpacing.tilesTop)
                        .id("pulse.monitors")
                }
            }

            PulseSectionHeader(isNewMember ? String(localized: "Get Started") : String(localized: "My Day"),
                               accessory: .actionMenu)
                .padding(.top, PulseTheme.Layout.sectionGap)
                .id("pulse.myday")
            VStack(spacing: PulseTheme.Layout.stackGap) {
                if isNewMember {
                    newMemberDay(current?.start)
                } else {
                    myDay
                }
            }
            .padding(.top, PulseTheme.Layout.headerGap)

            if !isNewMember {
                PulseSectionHeader(String(localized: "My Plan"))
                    .padding(.top, PulseTheme.Layout.sectionGap)
                    .id("pulse.plan")
                PulsePlanCard()
                    .padding(.top, PulseTheme.Layout.headerGap)
            }

            if let progress = current?.start.calibration {
                PulseSectionHeader(String(localized: "Looking Ahead"))
                    .padding(.top, PulseTheme.Layout.sectionGap)
                    .id("pulse.looking-ahead")
                PulseLookingAheadCard(progress: progress)
                    .padding(.top, PulseTheme.Layout.headerGap)
            }

            PulseDashboardViews.Section(home: home, extras: current ?? extras, items: dashboardItems,
                                        personalizing: current?.start.personalizing ?? false,
                                        extrasStale: extrasStale, stressUpdated: stressUpdated)
                .padding(.top, PulseTheme.Layout.sectionGap)

            // The footer: a small ZENO mark at white 50%, 40 pt above the bottom inset.
            PulseZenoWordmark(color: PulseTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, PulseTheme.Space.xxl)
                .accessibilityHidden(true)
        }
    }

    /// My Day for an established member: the coach pill (today), then Today's Activities and Tonight's
    /// Sleep (Tonight's first in the evening, §3.1 order rule), My Journal and the Menstrual card.
    @ViewBuilder
    private var myDay: some View {
        if isToday {
            PulseHomeCoachEntry(home: home, facts: current?.outlook)
        }
        if isToday && PulseDailyOutlook.isEvening(home), let tonight = home.tonight {
            PulseTonightsSleepCard(tonight: tonight)
            PulseTodaysActivitiesCard(home: home)
        } else {
            PulseTodaysActivitiesCard(home: home)
            if isToday, let tonight = home.tonight {
                PulseTonightsSleepCard(tonight: tonight)
            }
        }
        if let journal = home.journal {
            PulseJournalCard(strip: journal)
                .id("pulse.journal")
        }
        if isToday {
            PulseMenstrualCardHost()
        }
    }

    /// The new member's day: the Get Started cards (once their done-signals are read), the Ask well while
    /// Coach can answer, Tonight's Sleep, and Today's Activities once something is logged.
    @ViewBuilder
    private func newMemberDay(_ start: PulseGetStartedFacts?) -> some View {
        if let start {
            PulseGetStartedCards(facts: start)
        }
        if coach.availability == .ready {
            PulseAskWell { coach.open(nil) }
        }
        if let tonight = home.tonight {
            PulseTonightsSleepCard(tonight: tonight)
        }
        if home.lastNight != nil || !home.naps.isEmpty || !home.workouts.isEmpty {
            PulseTodaysActivitiesCard(home: home, showsMissingSleep: false)
        }
    }
}

/// Home's vertical rhythm below the dials, measured on the 2026 captures.
enum PulseHomeSpacing {
    /// From the dial labels to the coaching stack (profile-community-2026/34, journal-plan-2026/15).
    static let stackTop: CGFloat = 26
    /// From the dial labels to the monitor tiles when no card is due (reviews/r41).
    static let tilesTop: CGFloat = 26
    /// From the stack's peek to the monitor tiles (profile-community-2026/34: 20.5 pt).
    static let tilesAfterStack: CGFloat = 20
}

// MARK: - DEBUG

/// DEBUG `--pulse-dashboard <id,id,…>`: show these dashboard items, for a capture, without touching the
/// stored layout. `--pulse-home-open outlook|review`: open the local Daily Outlook or Day in Review once
/// Home has loaded. No-op in Release.
enum PulseHomeDebug {
    #if DEBUG
    private static var opened = false

    @MainActor
    static func openOnce(home: HomeSnapshot?, extras: HomeExtrasSnapshot?, navigator: PulseNavigator) {
        let args = CommandLine.arguments
        guard !opened, let home, let extras, let i = args.firstIndex(of: "--pulse-home-open"), i + 1 < args.count else {
            return
        }
        opened = true
        switch args[i + 1] {
        case "outlook", "review":
            let content = PulseDailyOutlook.compose(home: home, facts: extras.outlook, evening: args[i + 1] == "review")
            navigator.open(PulseDailyOutlookRoute(content: content).route)
        default:
            break
        }
    }
    #endif

    static var dashboard: [PulseDashboardItem]? {
        #if DEBUG
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--pulse-dashboard"), i + 1 < args.count else { return nil }
        let items = args[i + 1].split(separator: ",").compactMap { PulseDashboardItem(rawValue: String($0)) }
        return items.isEmpty ? nil : items
        #else
        return nil
        #endif
    }
}
#endif
