# Pulse architecture

Pulse is ZENO's WHOOP-structured iPhone interface (`@AppStorage("pulse.enabled")`, on by default; the
classic `RootTabView` stays one switch away). It follows `docs/zeno/WHOOP_UI_SPEC.md` (the spec) and
`docs/zeno/DESIGN_RULES.md` (DR). This file is the map for anyone rebuilding a screen: where things live,
who owns what, how to add a screen without touching shared code, and the APIs to build it from.

Everything here is iOS-only (`#if os(iOS)`), Swift 5 language mode, iOS 17 deployment target, built with
Xcode 16.1:

- no iOS 26 APIs (`glassEffect`, `.buttonStyle(.glass)`, `tabBarMinimizeBehavior`, `tabViewBottomAccessory`);
- no trailing commas in parameter or argument lists (Swift 6.1);
- SF Pro and SF Symbols only, never WHOOP's wordmark, badges, illustrations or fonts (spec §0);
- after adding or removing a file, run `xcodegen generate`; never edit `Strand.xcodeproj` by hand.

## 1. How Pulse works

```
Repository ──refreshSeq──▶ PulseModel (@MainActor @Observable) ──PulseRequest──▶ PulseSnapshotBuilder (actor)
                                 ▲                                                      │
                                 └──────────── immutable snapshots (HomeSnapshot, …) ◀──┘
Views read the model's snapshots (or their own, via PulseModel.build) and never query the store.
```

- **Model/**: `PulseModel` owns the selected day (`dayOffset`) and publishes one snapshot, Home's `home`;
  other screens build their own through `PulseModel.build` (§5). `PulseSnapshotBuilder` builds off the
  main actor, caching history reads per refresh. `detailKey` changes whenever a screen should reload: a
  refresh, the day, a display preference, or the profile the builds score with (Effort's HR max, sex, the
  heart-rate zones). `healthKey` is the same without the day, for always-today screens.
- **Shell/**: the floating tab capsule, the Coach button, one `NavigationStack` per tab, the sheet and
  cover slots, the anchored action (＋) menu, `NavRouter` requests, Home Screen quick actions, notification
  taps (`PulseExternalRoutes`) and the running gym session's bar and presenter (`PulseLiftSessionPresenter`).
- **Components/** and **Theme/**: every shared view and token. Screens never write a hex colour, a
  font size or a radius of their own.

Day keys (`"yyyy-MM-dd"`) are parsed at UTC midnight across the app. Any text made from a day key goes
through a UTC formatter (`PulseFormat.dayLabel`, `PulseFormat.navDayTitle(dayKey:)`). Real instants
(sleep onset, a workout start) display in the device zone (`PulseFormat.clock`, `navDayTitle(offset:date:)`).

## 2. Folder layout

```
StrandiOS/Pulse/
├── ARCHITECTURE.md           this file
├── Theme/                    tokens (foundation only)
│   ├── PulseTheme.swift      page, surfaces, text, semantic colours, status tints
│   ├── PulsePalettes.swift   HR zones, sleep stages, stress, menstrual, delta chips, plan, journal, streak
│   ├── PulseGradients.swift  gradients; AI, activity-flow, onboarding, tab-bar and coach tokens
│   ├── PulseType.swift       PulseTextStyle, .pulseText(_:), PulseType.font / numeral
│   ├── PulseLayout.swift     Space, Radius, Layout, Dial, TabBarMetrics, Row
│   └── PulseMotion.swift     PulseMotion, .pulseAnimation(_:value:), .pulseNumericTransition()
├── Components/               shared views (foundation; see §6), including PulseCards (tiles, pills, zone
│                             rows, impact bars, day circles, goal rings, dialog, error page, wheel sheet),
│                             PulseDayCharts (HR area, 24 h stress, Strain & Recovery), PulseSkeleton and
│                             PulseActionMenu; plus the groups' own components (Health*, JournalPlan*,
│                             MoreProfile*, RecoveryStrainDive; §3)
├── Shell/                    PulseRootView, PulseTabBar, PulseCoachButton, PulseRoutes,
│                             PulseNavigator, PulseActionSheet, PulseSettingsCard (foundation only)
├── Model/                    PulseModel, PulseSnapshotBuilder, PulseSnapshots, PulseScore,
│                             PulseDialMapping (foundation only; extend, never edit)
├── Screens/<Area>/           one folder per screen group (§3)
└── Debug/                    PulseDemo (launch flags, demo seed), PulseComponentGallery
```

## 3. Ownership map

Each group edits only its own folders. It may add files there, including
`PulseSnapshotBuilder+<Group>.swift` / `PulseSnapshots+<Group>.swift` extension files (§5),
group-specific components named `Components/<Group>*.swift` if they are reusable within the group, and
its own destinations as `PulseScreenRoute`s (§4, "A group's own destinations"). It must NOT edit Theme/,
the shared Components/ files, Shell/ or the Model/ core files. If a group needs a shared token or
component that does not exist, it asks the foundation owner.

| Group | Folders | Types (route) |
|---|---|---|
| home | `Screens/Home/` | `PulseHomeView` (Home tab root), `PulseCustomizeDashboardView` (`.customizeDashboard`), `PulseCoachingStack`, `PulseDashboardViews`, `PulseCalibrationTimelineView` (`.calibrationTimeline`), `PulseDailyOutlookView` (`PulseDailyOutlookRoute`). The action menu (§3.2) is the foundation's `PulseActionMenu`; Home places it with `PulseSectionHeader(accessory: .actionMenu)` |
| sleep | `Screens/Sleep/` | `PulseSleepDiveView` (`.sleepDive`), `PulseSleepPlannerView` (`.sleepPlanner`) |
| recovery-strain | `Screens/Recovery/`, `Screens/Strain/`, `Components/RecoveryStrainDive.swift` | `PulseRecoveryDiveView` (`.recoveryDive`), `PulseStrainDiveView` (`.strainDive`) |
| trends | `Screens/Trends/` | `PulseTrendView` (`.trendView(metric:)`), `PulseTrendsTabView` (Trends tab root), `PulseWeeklyDigestView` (`.weeklyDigest`), `PulseTrainingLoadView` (`.trainingLoad`) |
| activity | `Screens/Activity/` | `PulseActivityDetailView` (`.activityDetail(_:)`), `PulseStartActivityView` (`.startActivity`), `PulseAddActivityView` (`.addActivity`), `PulseActivityPickerView` (`.activityPicker`) |
| health | `Screens/Health/`, `Components/Health*.swift` | `PulseHealthTabView` (Health tab root), `PulseHealthspanView` (`.healthspan`), `PulseHealthMonitorView` (`.healthMonitor`), `PulseStressMonitorView` (`.stressMonitor`) |
| more-profile | `Screens/More/`, `Screens/Profile/`, `Components/MoreProfile*.swift` | `PulseMoreView` (More tab root), `PulseAppSettingsView` (`.appSettings`), `PulseDeviceSettingsView` (`.deviceSettings`), `PulsePrivacyDataView` (`.privacyData`), `PulseReportProblemView` (`.reportProblem`), `PulseFirstWeekView` (`.firstWeek`), `PulseProfileView` (`.profile`), `PulseLevelsView` (`.levels`), `PulseAchievementsView` (`.achievements`), `PulseStreakView` (`.dayStreak`) |
| journal-plan | `Screens/Journal/`, `Screens/Plan/`, `Components/JournalPlan*.swift` | `PulseJournalView` (`.journal(dayOffset:)`), `PulseBehaviorInsightsView` (`.behaviorInsights`), `PulseWeeklyPlanView` (`.weeklyPlan(editing:)`), `PulsePlanHomeCard` (Home's My Plan card) |
| cycle-coach | `Screens/Cycle/`, `Screens/Coach/` | `PulseCycleInsightsView` (`.cycleInsights`), `PulseCoachSheet` (`.coach(seed:)`, the Coach button), `PulseMemoryView` (`.memory`), `PulseAISettingsView` (`PulseAISettingsRoute`), Hormonal Insights (`PulseCycleSettingsRoute`) |
| onboarding-strength | `Screens/Onboarding/`, `Screens/Strength/` | `PulseOnboardingView` (`.onboarding`, and the first run), `PulseStrengthTrainerView` (`.strengthTrainer`), `PulseStrengthLiveSessionView` (`PulseStrengthLiveRoute`, presented by `PulseLiftSessionPresenter`) |
| extras | `Screens/Extras/` | `PulseYearInReviewView` (`.yearInReview`), `PulseChallengesView` (`.challenges`), `PulseDayTimelineView` (`.dayTimeline`), `PulseZenoLiveView` (`PulseZenoLiveRoute`) |

What the map holds today:

- **Every screen in it is rebuilt** (`isRebuilt` is true on every screen type, §4), so no entry point opens
  `PulsePlaceholderScreen`. It stays for a group's new destination while it is built (the DEBUG
  `screen-sample` route shows it).
- **The dives** build their own snapshots through `model.build` and have WHOOP's top: the 260 pt ring at
  y≈130 with its 70 pt score, and the coach summary pill floating over the page. The Recovery and Strain
  dives carry the pillar's achievement chip in the bar (`PulseDiveAchievement`, which opens Achievement
  Details) and HOW IT'S CALCULATED › at the end of the page (`PulseDiveExplainerRow`); the Sleep dive still
  shows ⓘ.
- `PulseCoachSheet` is the rebuilt Coach over the existing `AICoachEngine`; the classic `CoachView` is only
  `.classic(.coach)`.
- `Components/PulseLegacyComponents.swift` held the first Pulse screens' shared pieces. Only
  `pulseDebugScroll` and `pulsePage` are still used; the rest can go. New code uses the catalogue in §6.

## 4. Navigation

### Tabs and the Coach (spec §1.1, §1.2)

- `PulseTab`: `.home`, `.health`, `.trends` (ZENO's replacement for Community), `.more`. The app always
  launches on Home. A tab re-tap refreshes, then pops to root, then scrolls to top (`\.scrollToTopSignal`).
- The capsule and the Coach button show on a tab's ROOT and fade out on push (spec §1.2: no tab bar on a
  pushed screen). A pushed screen floats its own Coach button or summary pill with
  `PulseScreenScaffold(coach:)`, in exactly the tab root's spot (12 pt from the right edge, its bottom on
  the capsule's line 28 pt above the screen edge), so it never jumps on push. While the Coach writes a
  reply, that floating button turns into the "◎ Analyzing…" pill (`PulseFloatingCoachButton`).
- **Pop-to-root by tab re-tap applies to a tab root only.** Because the capsule is hidden on pushed
  screens, a re-tap can only happen at a root (where it scrolls to top), and switching tabs from a pushed
  screen goes through "‹" first. This is the spec's behaviour and intended; the classic shell's always-on
  bar allowed both. Deep classic stacks (More › Settings › …) need repeated back taps or a swipe-back.
- `@Environment(\.pulseCoach)` gives `availability` (`.off`, `.needsSetup`, `.ready`) and `open(seed)`.
  Off hides every coach surface and stretches the capsule; never read `noop.coachEnabled` yourself.

### Routes (Shell/PulseRoutes.swift)

`PulseRoute` names every destination: the spec's navigation map (§1.8), the ownership map above, every
classic screen (`.classic(PulseClassicDestination)`), the shared metric routes (`.tab(TabRoute)`) and any
group's own destination (`.screen(AnyPulseScreen)`, below). `PulseRoute.destination` is the single route
→ view mapping, and `presentation` follows spec §1.6 (the Sleep Planner as the 2026 iOS app presents it;
App Settings departs from it, §9):

| Presentation | Routes |
|---|---|
| `.fullScreen` | customizeDashboard, startActivity, deviceSettings, journal, onboarding, strengthTrainer, yearInReview, dayTimeline, guidedSession, sleepPlanner |
| `.sheet` | addActivity, coach, weeklyPlan(editing: true) |
| `.push` | everything else (dives, trendView, monitors, profile pages, privacyData, reportProblem, firstWeek, trainingLoad, classic screens, …), and appSettings (pushed from More, so AI Settings / Data Export open over it as sheets) |
| a `.screen` route's own | whatever its `PulseScreenRoute.presentation` says (push by default) |

A `.tab` route is pushed as the raw `TabRoute` (`NavigationPath.appendPulse`, `PulseLink`), which
`tabRouteDestinations()` maps through `TabRoute.destinationView`, the one mapping for those screens.

### A group's own destinations

Sub-screens the map does not name (Edit Profile, Achievement Details, Behavior Details, SELECT BEHAVIORS,
Edit Activity, the live-session pager, Integrations, Export, AI Settings, …) are declared by their group,
in its own folder, as a `PulseScreenRoute`, and opened with `.route`. Nothing in Shell/ changes:

```swift
// Screens/Profile/PulseEditProfileRoute.swift
struct PulseEditProfileRoute: PulseScreenRoute {
    var view: some View { PulseEditProfileView() }          // built on PulseScreenScaffold
}

struct PulseAchievementDetailsRoute: PulseScreenRoute {
    let badge: String                                       // routes are values: Hashable
    var presentation: PulsePresentation { .sheet }          // push by default
    var view: some View { PulseAchievementDetailsView(badge: badge) }
}

PulseLink(PulseEditProfileRoute().route) { PulseListRow(title: String(localized: "Edit profile")) }
    .buttonStyle(PulsePressStyle())
navigator.open(PulseAchievementDetailsRoute(badge: id).route)
```

Equal route values are one destination (the path and the shell's sheet slot compare them), so put
everything that tells two screens apart in the struct.

Open a route from a screen:

```swift
@Environment(\.pulseNavigator) private var navigator

// A row that IS the link: push routes stay value links (a tab re-tap pops them), modal routes present.
PulseLink(.healthMonitor) { PulseMetricRow(symbol: "waveform.path.ecg", title: "Health Monitor") }
    .buttonStyle(PulsePressStyle())

Button { navigator.open(.sleepPlanner) } label: { … }      // as the spec presents it
navigator.push(.trendView(metric: "hrv"))                   // force a push (.coach still opens its sheet)
navigator.present(.classic(.alarms))                        // force a modal (classic screens get "Done")
navigator.quickAction(.addActivity)                         // a ＋ action's screen, or .menu for the sheet
```

A presented route gets its own `NavigationStack` (`PulseModalHost`); its root sees
`\.pulseModalRoot == true`, so `PulseScreenScaffold` shows "✕" instead of "‹". Inside a modal,
`navigator.open` pushes within that modal, and so does a quick action (its screen is pushed there; the ＋
sheet opens as the modal's own sheet), so a modal is never replaced or blocked by the shell. A gym session
started or resumed inside a modal is presented by that modal's host (`PulseLiftSessionPresenter`); with no
modal up, by the shell.

`\.pulseNavigator`, `\.pulseCoach` and `\.pulseActionMenu` compare equal across the shell's re-renders
(their closures reach the owner's current state; `identity` names the owner), so reading them does not
invalidate a screen on every push or sheet.

### The action (＋) menu (spec §1.3, §3.2)

My Day's "+" is `PulseSectionHeader(…, accessory: .actionMenu)`: tapping it opens the anchored popover
(`PulseActionMenuHost`, drawn by the shell above the tab bar) with START ACTIVITY (RESUME ACTIVITY while a
workout runs) · ADD ACTIVITY · STRENGTH TRAINER · COMPLETE YOUR JOURNAL · CREATE ZENO LIVE, a hairline,
then BREATHE · MARK MOMENT; the "+" morphs into "✕". It drops down where it fits, else opens upward with
the rows mirrored; where it fits neither way (seven rows make the card ≈397 pt) it opens toward the larger
room, held 8 pt inside the safe area over the "+", with the "✕" on top. Each row runs a
`PulseQuickAction`, which opens its route through `forExistingEntryPoint`. The shell's
＋ SHEET (`PulseActionSheet`, the same rows) is kept only for NavRouter's quick-actions request and for a
"+" inside a modal, where no anchor host listens. Intervals, Live HR and the guided session moved to More.

### Existing entry points and `isRebuilt`

Entry points that reach another group's screen (NavRouter requests, Home Screen quick actions, the ＋
menu, Home's rows, More's rows) open it through `PulseRoute.forExistingEntryPoint`: the route itself while
its screen type's `static let isRebuilt` is true, else the classic screen in `PulseRoute.classicFallback`.
Every screen type sets it to `true` today, so every entry point opens Pulse; a group can set its flag back
without anyone touching the shell. The fallbacks:

| Route | Classic fallback | Entry points that use it |
|---|---|---|
| `.sleepPlanner` | Alarms | NavRouter `.alarms`, Home's Tonight's Sleep |
| `.deviceSettings` | Devices | NavRouter `.devices`, Home's strap chip, More's row |
| `.profile` | Settings | More's row (Home's avatar opens `.profile` directly) |
| `.journal(dayOffset:)` | Journal (InsightsView) | NavRouter `.journal`, quick action, ＋ menu |
| `.startActivity` | Workouts | quick action, ＋ menu, Home's START ACTIVITY |
| `.addActivity` | Workouts | Home's + ADD ACTIVITY, ＋ menu |
| `.strengthTrainer` | Lift Log | ＋ menu, quick action, More's row |
| `.activityDetail(_:)` | Workout detail | Home and Strain dive workout rows |
| `.dayTimeline` | Full-day chart | Home's ⤢ |
| `.healthMonitor`, `.stressMonitor` | Classic Health / Stress | Home's monitor tiles, the dashboard's STRESS MONITOR card |
| `.behaviorInsights` | What moves you | Home's BEHAVIOR INSIGHTS, the Recovery dive's card |
| `.trendView` | the metric's detail | My Dashboard rows (the row's own detail route), STRAIN & RECOVERY, the Health screens' trend links |
| `.privacyData`, `.reportProblem`, `.firstWeek` | Backup & Sync, Test Centre, scoring guide | More's rows |
| `.trainingLoad`, `.weeklyDigest` | Trends, classic Weekly Digest | the Trends tab's rows; Home's week-in-review card |
| `.healthspan`, `.appSettings` | Classic Health, Settings | Profile's ZENO AGE card; More's App Settings row |

`PulseRoute.isRebuilt` is an exhaustive switch (no `default`): a new route has to name where its flag
lives, so no entry point can open a "being rebuilt" placeholder while a working classic screen exists.

`PulseTrendsTabView.isRebuilt` also decides whether NavRouter `.trends` pushes the classic Trends screen
onto the Trends tab. NavRouter `.journal` passes `router.pendingJournalDayOffset` into `.journal(dayOffset:)`,
and the Journal clears that offset once it has read it.

## 5. Adding or rebuilding a screen

1. **Write the screen's body** in your group's file (a new destination can start as
   `PulsePlaceholderScreen`). Keep the type name and the route's parameters. Build on `PulseScreenScaffold`:

   ```swift
   struct PulseHealthMonitorView: View {
       static let isRebuilt = true
       @Environment(PulseModel.self) private var model
       @State private var snapshot: HealthMonitorSnapshot?

       var body: some View {
           PulseScreenScaffold(title: String(localized: "Health Monitor"), trailing: .info { … },
                               coach: .button, ready: snapshot != nil) {
               // White-10% skeleton blocks after 200 ms, held at least 400 ms; never a spinner (DR §8).
               PulseLoadingGate(isLoading: snapshot == nil) {
                   if let snapshot { … }
               } skeleton: {
                   PulseSkeleton.cards([118, 118, 56])
               }
           }
           .task(id: model.detailKey) {
               if let s = await model.build({ builder, request in await builder.healthMonitor(request) }) {
                   snapshot = s
               }
           }
       }
   }
   ```

2. **Add your data as a snapshot extension** in your folder. Snapshot types are immutable `Equatable`
   values with everything already formatted; the builder method runs off the main actor and reuses the
   core readers:

   ```swift
   // Screens/Health/PulseSnapshots+Health.swift
   struct HealthMonitorSnapshot: Equatable {
       let seq: Int
       let rows: [Row]
       struct Row: Equatable, Identifiable { let id: String; let title: String; let value: String; … }
   }

   // Screens/Health/PulseSnapshotBuilder+Health.swift
   extension PulseSnapshotBuilder {
       func healthMonitor(_ r: PulseRequest) async -> HealthMonitorSnapshot? {
           begin(r.seq)                                   // point the cache at this refresh
           let rest = await restSeries()                  // shared readers: restSeries, workoutRows,
           let groups = await nightGroups(r)              // nightGroups, appleRows, heartRate, dayWindow,
           let notes = await cached("health.notes") {     // chargeDisplay, strainTarget, stressSummary, …
               await repo.someRead()                      // your own per-refresh cached read
           }
           guard isCurrent(r) else { return nil }         // a newer refresh began: stop
           return HealthMonitorSnapshot(seq: r.seq, rows: …)
       }
   }
   ```

   `PulseModel.build(dayOffset:_:)` runs it for Home's day (or any `dayOffset`) and returns nil when a
   newer refresh or day superseded it, so keep the old snapshot on screen in that case. The closure is
   isolated to the builder actor (its first parameter is `isolated PulseSnapshotBuilder`), so all of it,
   synchronous code included, runs off the main actor. Reload on
   `model.detailKey` (day-scoped screens) or `model.healthKey` (always-today screens). `PulseRequest`
   carries `days`, `sleeps`, `importedSleep`, `vitalRows`, `prefs`, `profile` and `day` (`offset`, `key`,
   `date`); `repo` is available for anything else.

3. **Use the shared components and tokens** (§6, §7). Put a reusable piece only your group needs in your
   folder; if two groups need it, ask for it in Components/. A sub-screen of your own is a
   `PulseScreenRoute` (§4).
4. **Flip `isRebuilt`** once the screen replaces its classic fallback.
5. **Capture it** with `Tools/zeno/shoot.sh … <your-route>` and compare against the reference images the
   spec cites in §5 (they live outside the repo, in `whoop-reference/`).

Rules that keep screens honest: one resolver per fact (never show the same number from two sources);
missing data is skipped, never drawn as zero; a value carried from an earlier day says so.

## 6. Component catalogue

All take plain values, never snapshots. Map a snapshot to them in your group (see
`Model/PulseDialMapping.swift` for the dials). `--pulse-gallery` shows every one of them.

### Page and structure

| Component | Signature | Notes |
|---|---|---|
| `PulseScreenScaffold` | `(title: String? = nil, titlePager: PulseNavTitlePager? = nil, role: PulseScreenRole = .pushed, trailing: PulseNavTrailing = .none, coach: PulseCoachAccessory = .none, coachSeed: String? = nil, background: PulseBackground.Style = .gradient, showsNavigationBar: Bool = true, spacing: CGFloat = 16, horizontalPadding: CGFloat = 16, topPadding: CGFloat = 16, refresh: (() async -> Void)? = nil, ready: Bool = true, topBackdrop: PulseTopBackdropStyle = .automatic) { content }` | Fixed gradient, 16 pt margins, Pulse's bar, the page gradient + fade behind it once content scrolls under, tab-bar scrim on `.tabRoot`, floating coach on `.pushed`, 80 pt bottom inset under floating chrome, pull to refresh, scroll-to-top, `--pulse-scroll` anchors (`.id("pulse.<anchor>")`) |
| `PulseScreenRole` | `.tabRoot`, `.pushed` | A modal root is detected from `\.pulseModalRoot` |
| `PulseCoachAccessory` | `.none`, `.button`, `.pill(summary: String)` | The pill renders `**bold**` markdown as bold |
| `.pulseNavHeader(_:titlePager:trailing:showsBack:)` | | Pulse's own 44 pt bar centred 23.5 pt under the safe top: thin "‹" (glyph x = 32) or "✕" at a modal root, centred caps title, one trailing accessory at the right margin; swipe-back kept (`PulseSwipeBackEnabler`) |
| `PulseNavBar` | `(title:titlePager:leading: .none \| .back \| .close, trailing:onLeading:)` | The bar alone |
| `PulseNavTitlePager` | `(title:canGoBack:canGoForward:onBack:onForward:)` | "‹ TODAY ›" in the bar's centre (the Sleep dive's nights) |
| `PulseNavTrailing` | `.none`, `.info(action)`, `.achievement(symbol:tint:count:action:)`, `.symbol(name, accessibilityLabel:, action:)`, `.custom(accessibilityLabel:action:draw:)` | ⓘ 27.5 pt, achievement chip, ⚙ / clock / ? / •••; `.custom` draws a glyph no symbol has (WHOOP's outlined "ooo") with a Canvas closure in the 44 pt slot, in `.foreground` (the bar's white) |
| `PulseTopBackdrop` | `(style:extra:fade:)` | Page gradient to the safe-area edge (+ `extra`), fading over `fade`; the scaffold draws it |
| `PulseTopBackdropStyle` | `.automatic`, `.extended(extra:fade:)` | Home's sticky rings: `.extended` |
| `PulseBackground` | `(style: .gradient \| .nearBlack)` | Viewport-fixed; put it behind a scroll view |
| `.pulseTabBarScrim()` | | For a tab root that does not use the scaffold |
| `.pulseScrolledPast(_ isPast: Binding<Bool>, threshold: CGFloat = 0)` | | Sticky headers (one per screen) |
| `PulsePlaceholderScreen` | `(name:symbol:summary:spec:group:links:role:coach:)` | The "being rebuilt" screen (spec line DEBUG only) |
| `PulseLoadingGate` | `(isLoading:) { content } skeleton: { … }` | Nothing for 200 ms, then the skeleton for at least 400 ms, then a cross-fade |
| `PulseSkeleton`, `PulseSkeletonBlock` | `.dive`, `.cards([heights])`; `(height:width:radius:)` | White 10%, no shimmer; `.pulseSkeleton(isLoading:)` redacts a laid-out view |

### Surfaces and text

| Component | Signature | Notes |
|---|---|---|
| `PulseCard` | `(_ style: PulseCardStyle = .standard, padding: CGFloat = 16, radius: CGFloat = 12) { content }` | White 10%, 12 pt circular, no border |
| `PulseCardStyle` | `.standard`, `.detail` (4.5%), `.coaching` (7.5%), `.nested`, `.well` (black 50%), `.banner` (black), `.rowCard`, `.outlined`, `.solid(Color)` | |
| `PulseCardSurface` / `.pulseCardBackground(_:radius:)` | | The fill alone, for rows that are buttons |
| `PulseDivider` | `(leadingInset: CGFloat = 0, trailingInset: CGFloat = 0)` | 1 pt white 10% |
| `PulsePressStyle` | `ButtonStyle` | 70% on press, released over 0.15 s |
| `PulseCardTitle` | `(_ title: String, accessory: .none \| .chevron \| .expand \| .info \| .trailingChevron)` | 11.5 pt Bold caps +0.7; the accessory never sets the row's height |
| `PulseSectionHeader` | `(_ title: String, count: Int? = nil, style: PulseTextStyle = .sectionTitle, accessory: .none \| .plus(label, action) \| .actionMenu \| .customize(action) \| .edit(action) \| .viewAll(action) \| .caption(String))` | 20 pt Semibold, 20 pt from the screen edges; hugs its title (the accessory overflows), so `sectionGap` / `headerGap` give 40 / 24 |
| `PulseListSectionHeader` | `(_ title: String)` | "ACCOUNT & SETTINGS" + hairline; wraps, never widens the page |
| `PulsePlusButton`, `PulsePlusSquare` | `(accessibilityLabel:action:)`; `(isClose:)` | The white 36 pt "+" (44 pt hit area), and its "✕" morph |
| `PulseLabel` | `(_ text: String, color: Color = .textTertiary, alignment:)` | 11 pt Bold caps, wraps between words |
| `PulseWordWrapText` | `(_ text:, style:, alignment:, lineSpacing:, minimumScale:)` | One line if it fits, else wrapped between words only; an over-long word shrinks with all the others |
| `PulseTextMetrics.width(_:style:size:)` | | A string's width in a style (to pick one size for several labels) |
| `PulseValueText` | `(value:unit:style:unitStyle:color:unitColor:)` | Number + smaller baseline-aligned unit |
| `PulseChevron` | `(color:size:)` | "›" 13 pt, 50% |

### Header and brand

| Component | Signature | Notes |
|---|---|---|
| `PulseAvatar` | `(imageData:name:size:)` | Photo, else initials on a coloured disc, else a person outline on white 10% |
| `PulseStreakPill` | `(days:avatarSize:)` | White-5% capsule under the avatar: tier-coloured flame + 13 pt count |
| `PulseStrapChip(action:)`, `PulseStrapGlyph(connected:)` | | Battery (white 60%, red ≤ 15%) + ZENO's band outline with a 6.5 pt teal / grey dot |
| `PulseStrapShape`, `PulseStrapVibrateGlyph(height:)` | | The band outline alone; with vibration marks (SET ALARM) |
| `PulseLiveHRChip()` | | Live heart rate (not in the Home header: §1.4 moves it to Health Monitor) |
| `PulseCoachAvatar`, `PulseZenoWordmark`, `PulseZenoMonogramShape` | | ZENO's own marks (wordmark white, ink inside its 72 × 12 slot) |

### Dials (spec §2.5)

| Component | Signature | Notes |
|---|---|---|
| `PulseDialContent` | `.percent(label:percent:color:caption:)`, `.strain(label:value:optimalRange:target:color:caption:)`, or the memberwise init; `.spoken(_:)` | `--` placeholder, band and tick as fractions; `accessibilityValue` carries the caption, target and optimal range |
| `PulseScoreDial` | `(content:reservesCaption:diameter:thickness:labelSize:labelWidth:)` | 88 / 6, "LABEL ›" 12 pt below, never wider than its column; wrap in a link with `.buttonStyle(PulseDialButtonStyle())` |
| `PulseDialColumns` | `(contents: [PulseDialContent], routes: [PulseRoute]? = nil)` | Equal columns, ONE label size (`PulseScoreDial.sharedLabelSize`); Home's dial row |
| `PulseHeroRing` | `(content:diameter:thickness:accessoryAccessibility:) { accessory }` | 260 / 15, ZENO mark, 70 + 40 pt score (condensed), 12.5 pt label wrapping at 116 pt; fixed size inside the ring |
| `PulseMiniRing`, `PulseMiniRingRow` | `PulseMiniRingRow(items: [.init(id:content:action:)])` | 24 / 2 sticky header; equal columns, groups ≈12 pt left of centre |
| `PulseRing` | `(fraction:color:diameter:thickness:band:tick:trackColor:)` | Band white 19% over the track (27% on the page); 2 pt tick |
| `PulseRingSegment`, `PulseRingTick` | `Shape`s | Flat ends rounded by `cornerRadius` |
| `PulseDialData.dialContent(target:label:)` | Model mapping | Band and tick only when Recovery scored for the day |

### Rows, tiles, cards

| Component | Signature |
|---|---|
| `PulseListRow` | `(symbol: String? = nil, title:, subtitle: String? = nil, trailing: .chevron \| .none \| .value(String) \| .toggle(Binding<Bool>), titleColor:)` |
| `PulseMetricRow` | `(symbol:title:value:unit:trend:baseline:)`; no value = label + "›" (My Dashboard) |
| `PulseActivityRow` | `(chip: PulseActivityChip, name:, start:, end:, barColor:, dottedBar:)`: condensed times, 2 × 28 bar with white end dots |
| `PulseActivityChip` | `(kind: .sleep \| .strain \| .recovery \| .unscoredSleep \| .pending \| .preAdded, symbol:, value:)` |
| `PulseSubtitleRowCard` | `(symbol:title:subtitle:)` |
| `PulseMonitorTile` | `(title:status: .init(badge:tint:word:wordColor:detail:) \| .pending)` (§2.6.4) |
| `PulseCoachPill` | `(kind: .morning \| .evening, title:, isRead:, action:)`: Daily Outlook / Day In Review (§2.6.6) |
| `PulseAskRow` | `(action:)`: "Ask a question, get support…" |
| `PulseInsightCard` | `(text:cta:action:)`: AI-gradient border, coach content only (§2.6.10) |
| `PulseZoneRowCard` | `(zone:range:share:duration:typical:)` (§2.6.18); `PulseTypicalRangeBox()` |
| `PulseImpactBar` | `(fraction: -1...1, effect: .helps \| .hurts \| .notSignificant, valueText:, large:)` (§2.6.20) |
| `PulseDayCircleRow` | `(days: [.init(id:label:state:isCurrent:)], diameter:, onTap:)`; states `.logged \| .notLogged \| .pending` (Journal), `.done \| .rest \| .future` (Plan) (§2.6.37) |
| `PulseGoalRing` | `(kind: .count(done:target:) \| .value(text:fraction:), diameter:)` (§2.5 plan goals) |
| `PulseDialogCard` | `(title:message:primaryTitle:primary:secondaryTitle:secondary:onClose:)` (§2.6.30) |
| `PulseErrorPage` | `(title:message:retryTitle:onRetry:onClose:)` (§2.6.31) |
| `PulseWheelPickerSheet` | `(title:options:selection:isValid:label:onConfirm:onCancel:)` (§2.6.36) |

### Trends and status

| Component | Signature |
|---|---|
| `PulseTrend` | `(direction: .up \| .down \| .flat, polarity: PulseMetricPolarity)` or `(delta:polarity:)`; `.judgement`, `.color` |
| `PulseMetricPolarity` | `.higherIsBetter`, `.lowerIsBetter`, `.neutral`; `.forMetric(key)` holds the spec's table |
| `PulseTrendGlyph` | `(trend:size:)`: ▲▼ teal/orange by good/bad, grey ● when unchanged |
| `PulseDeltaChip` | `(text:trend:)`: green / amber / grey chips, radius 4 |
| `PulseStatusBadge` | `(_ content: .check \| .alert \| .pending \| .value(String), tint: PulseTheme.Tint, size: 24)` |
| `PulseStatusChip` | `(_ text:, kind: .positive \| .negative \| .neutral)` |
| `PulseTag` | `(_ text:, outlined: Bool = false)` |
| `PulseMiniSegments` | `(active: Int?)` 0 Poor / 1 Sufficient / 2 Optimal; `PulseSleepBand.index(percent:)`, `.name(_:)` |
| `PulseAchievementChip` | `(symbol:tint:count:)` |
| `PulseFilterChip` | `(title:isSelected:action:)` |
| `PulseStatusBanner` | `(_ kind: .caughtUp(syncedTo:) \| .catchingUp(progress:) \| .offWrist \| .lowBattery(percent:), onDismiss:)` |

### Callouts and controls

| Component | Signature |
|---|---|
| `PulseCallout` | `(notchPosition: CGFloat = 0.5) { rows }`: radial glow, top-lit stroke, 15 × 7 pointer |
| `PulseCalloutRow` | `(symbol:title:value:unit:baseline:trend:segments:)`, 66 pt pitch, 21 pt value, the bare baseline under it |
| `PulseLegendWell` | `{ content }`; `PulseLegendTodayVsBaseline(period:)`, `PulseLegendPoorSufficientOptimal()` |
| `PulseNotchedWell` | `(notchPosition:) { PulseNotchedWellRow(swatch:title:value:) }` |
| `PulseNotchedRectangle` | `Shape(cornerRadius:notchWidth:notchHeight:notchPosition:)` |
| `PulseSegmentedControl` | `(options: [Value], selection: Binding<Value>, style: .well \| .underline) { title }` |
| `PulseRange` | `.week`, `.month`, `.sixMonths`, `.year`, `.all` (`title`, `days`) |
| `PulseDayPager` | `(title:canGoBack:canGoForward:onBack:onForward:onTitleTap:)`: 30 pt, white 5% capsule + 10% pill |
| `PulseRangePager` | `(title:canGoBack:canGoForward:onBack:onForward:)` |
| Buttons | `.buttonStyle(.pulseNested)` (40 pt, 44 pt hit, 11 pt label), `.pulseNested(fill:)`, `.pulseOutline(color)`, `.pulseOutlineWhite`, `.pulseFilledWhite`, `.pulseFilledBlue` (15 pt labels); `PulseButtonRow { … }` keeps buttons at equal widths and stacks them full width once a label no longer fits its equal share (a 0.9 allowance for the label's own 0.8 shrink); `PulseTextCTA(title:tint: .ai \| .color(c), action:)` |

### Charts (Swift Charts, spec §2.7)

| Component | Signature |
|---|---|
| `PulseChartDatum` | `(id:label:sublabel:value:color:valueLabel:)`; `value: nil` is a gap, never zero |
| `PulseChartCard` | `(_ title:, accessory:, style:) { chart }` |
| `PulseBarChart` | `(data:yDomain:gridValues:gridlineCount:showsYAxisLabels:highlightID:barWidth:height:emptyMessage:)` |
| `PulseLineChart` | `(data:color:typicalRange:average:yDomain:gridlineCount:showsYAxisLabels:highlightID:showsArea:showsValueLabels:height:emptyMessage:)` |
| `PulseStackedBarChart` | `(columns: [Column(id:label:sublabel:segments:totalLabel:)], yDomain:, gridlineCount:, highlightID:, barWidth:, height:)` |
| `PulseHRAreaChart` | `(points: [PulseTimeValue], window:, color:, startLabel:, endLabel:, startSymbol:, endSymbol:, yValues:, height:)`: sleep or activity HR |
| `PulseStressChart` | `(points:periods: [PulseChartPeriod], now:, currentLevel:, xLabels:, height:)`: value-coloured 24 h stress; a past day (`now: nil`) with no readings draws only "No stress curve for this day" |
| `PulseStrainRecoveryChart` | `(days: [Day(id:label:sublabel:strain:recovery:)], highlightID:, height:)`: the dual-axis week |
| `PulseChartAxis` | `gridValues(_:count:)`, `zeroBased(_:)`, `dynamic(_:)` |
| `PulseHatchedTrack` | `(color:spacing:lineWidth:cornerRadius:)`: 8.5 pt period, stroke 0.35 × the period unless given (§9) |

### Shell pieces screens may use

| Component | Signature |
|---|---|
| `PulseLink` | `(_ route: PulseRoute) { label }` |
| `\.pulseNavigator` | `open`, `push`, `present`, `quickAction` |
| `\.pulseCoach` | `availability`, `open(seed)` |
| `\.pulseActionMenu` | `open(anchor)`; screens use `PulseSectionHeader(accessory: .actionMenu)` / `PulseActionMenuButton()` |
| `PulseScreenRoute`, `AnyPulseScreen` | a group's own destination (§4) |
| `PulseCoachButton` | `(size: 64, action:)` |
| `PulseCoachSummaryPill` | `(summary:onExpand:)` |
| `PulseCoachAnalyzingPill` | `()`: "◎ Analyzing…" at the button's 64 pt height with its 32 pt ring, growing leftward |
| `PulseFloatingCoachButton` | `(action:)`: the floating Coach button, or the Analyzing… pill while the Coach writes |

## 7. Theme tokens

- Page: `PulseTheme.pageStops` (sampled on 2026 captures, §9), `pageTop`, `pageBottom`, `pageNearBlack`,
  `barStrip`, `scrim` (black 60% at the capsule's top edge).
- Surfaces: `card` (white 10%), `detail` (4.5%), `nested`, `well`, `gridOnCard`, `gridOnPage`, `dash`,
  `targetBand` (27% as seen) / `targetBandOverTrack` (19%, drawn over the track), `pressDisc`, `track`,
  `divider`, `coachingCard`, `coachingPeek`, `bannerWell`, `rowCardTop/Bottom`, `rowIcon`, `rowSubline`,
  `listSectionHeader`, `achievementChip`, `filterChip`, `dialogTop/Bottom`, `chartHighlight`,
  `pagerCapsule` (5%) / `pagerPill` (+10%), `streakPill`, `avatarFallback`, `skeleton`, `strapOutline`,
  `batteryText`, `preAddedChip`, `tagFill`, `segmentOff`, `typicalBand`, `typicalBox`, `hatch`,
  `averageLine`, `calloutGlow` / `calloutRim`, `menuTop/Bottom`, `menuDim`, …
- Text: `textPrimary`, `textButton` (85%), `textSecondary` (70%), `textTertiary` (50%), `textDisabled` (40%).
- Data: `recoveryHigh/Mid/Low`, `recoveryLowText`, `strain`, `sleep`, `recoveryBlue`, `recoveryActivity`,
  `positive`, `negative`, `neutral`, `sufficient`, `baselineDot`; `recovery(_ band)`, `recoveryText(_ band)`,
  `recovery(percent:)`. One meaning per hue.
- Status tints: `PulseTheme.Tint.teal/red/blue/orange/orangeHigh/grey` (`fill`, `glyph`).
- Palettes: `Zone` (0–5, `color(_:)`, `dimmed(_:)`), `Stage` (`color(_:)`, restorative split),
  `SleepDetail`, `Stress` (`stops`, `color(for:)`, `Level(value:)`), `Menstrual.Phase`, `Delta`, `Impact`,
  `Plan`, `Journal`, `Streak.flame(days:)`, `Healthspan`, `Levels`.
- Gradients and feature tokens: `Gradients` (`aiText`, `aiBorder`, `aiInputBorder`, `aiRing`,
  `pillMorning/Evening`, `promoBorder`, `getStarted*`, `featureAnnounce*`, `aiEntry*`, `memoryRow`,
  `journalToday`, `journalPastDay`, `dailyOutlookPage`, `coachSheet`, `liveSession`, `healthUnlock*`,
  `achievementGlow*`, `profileGlowTeal`, `yearInReview*`), `Activity` (the activity-flow table),
  `Onboarding`, `TabBar` (opaque fill, leading `highlight`, unselected 55%), `Coach` (`buttonFill`,
  top-leading `buttonRim`, `orb`, `halo`, `pillFill` / `pillRim`).
- Type: `PulseTextStyle` cases `heroScore` (70 condensed), `heroUnit` (40), `heroLabel` (12.5),
  `dialValue`, `dialUnit`, `sectionTitle`, `subsectionTitle`, `tileValue`, `tileUnit`, `rowValue`,
  `calloutValue` (21), `body`, `pillTitle`, `cardTitle` (11.5), `secondary`, `navTitle`, `label`,
  `baseline`, `axis`, `tabLabel` (11, scales to xxxLarge), `buttonLabel` (11), `capsuleLabel` (15), `chip`,
  `chipStrong`, `rowSubline`, `filter`, `subtitle`, `legend`, `headerNumeral`, `sleepTime` (22), plus the
  spec's new sizes (`largeValue`, `activityStrain`, `liveStrain`, `preStartHR`, `strengthTimer`,
  `trendInsight`, `plannerTime`, `mediumValue`, `stressValue`, `streakCount`, `pageTitle`, `levelTitle`,
  `levelTier`, `achievementCount`, `weeklyTrendsTitle`, `onboardingTitle`, `journalQuestion`, `rowText`,
  `cardHeadline`, `impactValue`, `coachingTitle`). Use `.pulseText(style)`; `PulseType.font(style)` and
  `PulseType.numeral(size)` for a fixed `Font`. Numerals are Bold condensed with tabular digits except
  `stressValue`.
- Layout: `PulseTheme.Space` (4…40), `Radius` (`card` 12, `control` 10, `well` 8, `toggle` 6, `badge` 4,
  `menu` 20, `dialog` 15, `coachButton` 24, `coachPill` 22), `Layout` (`pageMargin` 16, `gridGap` 12,
  `stackGap` 16, `healthStackGap` 24, `cardPadding` 16, `sectionGap` 35 and `headerGap` 19 around a
  hugging section header's text frame, i.e. 40 pt above its caps and 24 pt from its baseline,
  `floatingChromeInset` 80, `scrimHeight` 28, `minTapTarget` 44), `Dial` (`tickWidth` 2,
  `heroLabelMaxWidth`), `TabBarMetrics` (`belowSafeArea` 6, `floatingCoachSize` 64, `floatingCoachInset`
  12, `pillSideMargin` 12, `coachRingWidth` 1.33), `Row` (`contributorPitch` 66, `nestedButton` 40),
  `Header` (Home row 32, wordmark top 31, dials top 24, avatar 31, strap trailing 23, nav bar 44 at
  +1.5, back chevron 12 × 22, sticky row centre 19.5, fades 24 / 48).
- Motion: `PulseMotion.valueChange` (0.7 s, value changes only), `pressRelease` (0.15 s), `menu` (0.2 s),
  `chrome`, `crossFade`, `sheet`, `skeletonDelay` (200 ms), `skeletonMinimum` (400 ms);
  `.pulseAnimation(_:value:)` and `.pulseNumericTransition()` honour Reduce Motion. No ambient animation.

## 8. Debug flags and screenshots

DEBUG builds read these launch arguments; nothing ships in Release. The shell's are `PulseDebugLaunch`
(`Debug/PulseDemo.swift`); each group reads its own, documented beside the reader (`PulseHomeDebug`,
`PulseSleepDebug`, `PulseTrendDebugLaunch`, `PulseActivityDebug`, `PulseMoreDebug`, `JournalPlanDebug`,
`PulseCoachDemo`, `PulseCycleDemo`, …). `simctl` cannot tap, swipe or rotate, so these reach every state:

| Flag | Group | Effect |
|---|---|---|
| `--demo-seed` | app | Fill the store with deterministic data anchored on today (uninstall first for a fresh seed); skips the first-run gates. The groups' seeders below need it |
| `--demo-sync` | app | A connected, streaming strap: the battery in the Home header, Device Settings, the Health Monitor's live HR strip |
| `--demo-screen pulsehome\|pulserecovery\|pulsestrain\|pulsesleep\|pulsehealth\|pulsemore` | app | One Pulse screen full-bleed over the seeded store, without the shell |
| `-noop.coachEnabled NO` | app | Coach off for this launch (a UserDefaults launch argument) |
| `--pulse-tab home\|health\|trends\|more` | shell | Select a tab |
| `--pulse-route <name>` | shell | Open any route at launch on its natural tab; names in `PulseRoute.debugCatalog` (`sleep-dive`, `trend-view:rhr`, `zeno-live`, `classic-settings`, `tab-steps`, `tab-metric:<key>`, …) |
| `--pulse-push recovery\|strain\|sleep` | shell | Push a dive onto Home |
| `--pulse-present <name>` | shell | Present any route modally in its own stack ("✕" at its root), whatever its usual presentation |
| `--pulse-sheet actions\|coach\|menu\|session` | shell | Present the ＋ sheet or the Coach sheet, open Home's anchored ＋ menu, or open the gym session a previous launch left running, as its bar does |
| `--pulse-scroll <anchor>` | shell | Scroll to `.id("pulse.<anchor>")` once loaded. Each screen tags its own sections: Home `myday`, `tonight`, `plan`, `dashboard`, `stress`, `bottom`; the dives `contributors`, `weekly`, `hr`, `zones`; Health `monitor`, `stress`; the gallery `gallery-dials`, … |
| `--pulse-day N` | shell | Home N days back (also the Stress Monitor's and the day timeline's day) |
| `--pulse-night N` | sleep | The Sleep dive N nights back |
| `--pulse-gallery` | shell | Present the component gallery |
| `--pulse-coach-analyzing` | shell | The Coach held mid-reply, so the floating button shows "Analyzing…" |
| `--pulse-notification-tap <category>` | shell | A tap on a notification of that category at launch (`zeno.plan.checkIn`) |
| `--pulse-dashboard <id,…>` | home | My Dashboard with these items |
| `--pulse-banner caught-up\|catching-up\|off-wrist\|low-battery` | home | That status banner |
| `--pulse-home-open outlook\|review\|log-cycle` | home | Open the Daily Outlook, the Day in Review or the LOG CYCLE sheet once Home has loaded |
| `--pulse-monitor elevated\|low\|very-elevated\|out` | home | The HEALTH MONITOR tile in that grade |
| `--pulse-home-milestones [streak\|badge\|level]` | home | A milestone coaching card of that kind (all three without one) |
| `--pulse-coaching-top <id prefix>` | home | Lift the coaching cards whose id starts so (`challenge`, `milestone-badge`, `week-review`) to the top |
| `--pulse-week-review` | home | Today counts as Monday for the week-in-review card |
| `--pulse-yir-season` | home | The Year in Review promo in My Day out of its season |
| `--pulse-cycle-demo` | home | A synthetic luteal estimate on the Menstrual card (cycle day 21 of 28) |
| `--sleep-stage awake\|light\|deep\|rem` | sleep | Preselect a stage on the dive |
| `--sleep-computed-need` | sleep | Prefer the computed need and its breakdown on a demo store, whose seed stores a need without parts |
| `--sleep-drop-night` | sleep | Show Home's day on the dive as a night with nothing recorded |
| `--sleep-edit` | sleep | Open EDIT (the night's editor, or adding one) once the dive loads |
| `--sleep-schedule`, `--sleep-sheet goal\|alarm\|wake` | sleep | Open My Schedule, or one of the planner's sheets, over the Sleep Planner |
| `--trend-range w\|m\|6m\|1y\|all`, `--trend-page N` | trends | The Trend View's range, and the page counted back from the latest (also the Weekly Digest's page) |
| `--trend-picker` | trends | Open the Trend View's metric picker |
| `--trend-anchor N` | trends | The Trend View's latest window ending N days back, as a past day's dashboard row opens it |
| `--trend-cycle-demo` | trends | A fixed 28-day phase pattern for the cycle overlay (with Hormonal Insights on) |
| `--digest-mode w\|m` | trends | The Weekly Digest's week or month |
| `--activity-seed` | activity | Three demo activities scored from the demo heart rate (a run, a weightlifting session with its Lift Log session, a sauna) |
| `--activity-workout <latest\|index\|sport>` | activity | Activity Details on that stored workout (0 = newest; part of a sport name) |
| `--activity-menu`, `--activity-edit`, `--activity-delete`, `--activity-export`, `--activity-scrub`, `--activity-zones-tab`, `--activity-heart-rate-tab`, `--activity-view-all`, `--activity-tap-zones`, `--activity-lift-page N` | activity | That state of Activity Details once it has loaded |
| `--activity-wheel`, `--activity-invalid`, `--activity-overlap`, `--activity-reclassify`, `--activity-form-sport <name>` | activity | That state of the Add / Edit form |
| `--activity-sport <name>`, `--activity-picker-open`, `--activity-panel ring\|chart`, `--activity-target <value>`, `--activity-recents <a,b>` | activity | The pre-start screen: its activity, its list dropped down, the Strain Target panel open, a dragged target, the lists' MOST RECENT |
| `--activity-demo-live [min]`, `--activity-no-route`, `--activity-live-page hr\|strain\|map`, `--activity-end-dialog`, `--activity-live-camera`, `--activity-end-save` | activity | A live session N minutes in (default 28) fed demo heart rate: with Track Route off, on that page, with END THIS ACTIVITY?, with ZENO Live pushed over it, or ended and saved |
| `--activity-reset` | activity | Discard a session an earlier launch left running |
| `--pulse-health-calibrating` | health | The Health tab's calibrating note on a settled history |
| `--pulse-health-expand` | health | Every Healthspan pillar row open |
| `--pulse-health-log-cycle` | health | Open the Health tab's LOG CYCLE sheet once |
| `--more-open <page>` | more-profile | Open a sub-screen from the screen that owns it: with `--pulse-route app-settings`, `activity-settings`, `heart-rate-settings`, `ai-settings`, `data-export`, `units`, `integrations`, `apple-health`, `journal-settings`, `notifications`, `hormonal-insights` or `hide-metrics`; with `device-settings`, `device-advanced`; with `profile`, `edit-profile`; with `achievements`, `badge:<id>` |
| `--more-first-week` | more-profile | More's FIRST WEEK card, as for a new member |
| `--more-unlock` | more-profile | An unlock modal (the first unlocked badge) where the unlock presenter is attached; under `--demo-seed` Home presents none without it |
| `--jp-day N`, `--jp-sheet select\|calendar\|amount\|mood\|discard\|error`, `--jp-stage` | journal-plan | The Journal N days back, with that sheet or dialog open, or with a few answers staged |
| `--jp-scroll <anchor>` | journal-plan | The Journal or a Plan screen scrolled to `.id("jp.<anchor>")` once loaded |
| `--jp-seed` | journal-plan | With `--demo-seed`: a week of native journal answers if there are none |
| `--jp-tab <category>`, `--jp-query <text>` | journal-plan | SELECT BEHAVIORS on a tab, or with a search |
| `--jp-details <identity\|first>`, `--jp-expand` | journal-plan | Behavior Insights pushes Behavior Details (`lib.alcohol`, `auto.sleepPerformance`, …), its amount breakdown expanded |
| `--jp-plan boostFitness\|feelBetter\|sleepDeeper\|custom` | journal-plan | Start that plan if none is active |
| `--jp-plan-screen recap\|add\|goal:<section>\|behavior\|homecard\|preview:<template>`, `--jp-plan-week N`, `--jp-plan-expanded` | journal-plan | Plan Overview with that sheet or page, showing the week N weeks from this one; Home's plan card expanded |
| `--cycle-demo [N]` | cycle-coach | With `--demo-seed` and an empty log: four past cycles and a current one on day N (default 3), insights on |
| `--cycle-log` (add `--cycle-log-symptoms`), `--cycle-settings` | cycle-coach | The cycle page's log sheet on today (flow, or symptoms), or Hormonal Insights pushed |
| `--coach-demo` | cycle-coach | With `--demo-seed`: the Coach on a local address, with a short conversation, two memories and an earlier thread |
| `--coach-open memory\|settings\|history\|memory-detail`, `--coach-large`, `--coach-seed outlook\|cycle`, `--coach-ask` | cycle-coach | That part of the Coach sheet, at the large detent, as if opened from the Daily Outlook or the cycle page, or with the first suggestion sent (to the demo's local address only) |
| `--memory-add` | cycle-coach | My Memory's text composer open |
| `--pulse-onboarding-step <step>`, `--pulse-onboarding-first-run`, `--pulse-onboarding-terms`, `--pulse-onboarding-ticked` | onboarding | The flow on a step (`landing`, `privacy`, `putOn`, …, `expectations`), as the first run, with the Terms of Use sheet open, or with every attestation ticked |
| `--pulse-pairing found\|connecting\|connected\|failed\|failed-hint` | onboarding | The pairing screen in that state, with no strap |
| `--demo-lift` | strength | Three workouts and six months of sessions in an empty Lift Log |
| `--pulse-strength-tab progress`, `--pulse-strength-range month` | strength | The Strength Trainer on PROGRESS, on the M range |
| `--pulse-strength-workout <name>`, `--pulse-strength-exercise <prefix>` | strength | Push a workout's page, or an exercise's Exercise Details ("_" for spaces) |
| `--pulse-strength-live warmup\|rest\|active\|exercises\|done`, `--pulse-strength-exercises`, `--pulse-strength-finish` | strength | Start the first workout and walk it to that stage (the live screen opens over the trainer), on its EXERCISES tab, or with FINISH WORKOUT open |
| `--pulse-tilt left\|right`, `--pulse-timeline-zoom`, `--pulse-timeline-cursor F` | extras | The day timeline laid out as if the phone were turned, zoomed, or with its cursor at fraction F of the day |
| `--pulse-demo-timeline` | extras | With `--demo-seed`: synthetic heart rate for a past day, into an empty window only |
| `--pulse-yir-slide N` | extras | Year in Review on slide N (from 0) |
| `--pulse-demo-challenges` | extras | One challenge of each kind, started a few days back, in an empty list |
| `--pulse-challenge <id>`, `--pulse-challenge-join <kind>`, `--pulse-zeno-live` | extras | From the Challenges page (`--pulse-route challenges`): push a challenge, its join page, or ZENO Live |
| `--pulse-zeno-live-sample`, `--pulse-zeno-live-template dials\|recovery\|strain\|heartRate`, `--pulse-zeno-live-share`, `--pulse-zeno-live-state unscored\|calibrating` | extras | ZENO Live with a stand-in photo, that overlay, the share sheet open, or built as on a morning before scoring or a new wearer's second morning |

`PulseDebugLaunch` still parses `--pulse-range 7|30|90`, but nothing reads it since the Recovery dive's
history card gave way to Weekly Trends.

Capture script:

```
Tools/zeno/shoot.sh <sim-udid> <out-dir> <app-path> [--fresh] [--wait N] [target ...]
```

A target is a tab (`home`), a route name (`sleep-planner`), `gallery`, `actions`, `menu` or `coach-sheet`;
quote it to add launch arguments (`"home --pulse-scroll dashboard"`). Each shot is written as
`<out-dir>/<target>.png` plus a downscaled `.jpg`. Example:

```
Tools/zeno/shoot.sh 3F6D8EB8-27A5-4842-BAA1-AB85CCDF7242 /tmp/shots \
  "build/DD/Build/Products/Debug-iphonesimulator/NOOP Staging.app" --fresh \
  "home --demo-sync" "home --pulse-scroll dashboard" health trends more sleep-dive menu \
  "home -noop.coachEnabled NO"
```

## 9. Deviations from the spec, and housekeeping

Measured on the reference captures, where they disagree with the spec's numbers:

- **Tab capsule height above the screen edge.** The spec says ≈21 pt; the 2026 captures (reviews/r02,
  completeness-critic/13) show 28 pt, 6 pt below the bottom safe-area edge (the Oct 2025 reviews/02 shows
  29). Pulse follows the 2026 captures (`TabBarMetrics.bottomOffset(safeAreaBottom:)`), and the floating
  Coach button and summary pill on pushed screens sit on the same line.
- **Page gradient.** DR §1.1's upper half (#283339 → #1E262B) reads 2–3 levels darker and greener than
  every 2026 capture; `pageStops` are sampled on reviews/r02, completeness-critic/13 and 25 and
  deep-dives-2026/56 (#2A3139 → #262D35 → #22282F → #1E2327 → #191E22, then DR's values from 0.53).
- **Hero score.** DR's 58 pt standard-width score measures 19% short of every 2026 capture (cap 49.5 pt);
  `heroScore` is 70 pt Bold condensed (cap 49.3) with a 40 pt "%", so "100%" keeps WHOOP's footprint.
- **Type sizes measured smaller than DR.** `cardTitle` is 11.5 pt (WHOOP's caps 8.0 pt; at 12 pt
  "HEALTH MONITOR" wrapped in its tile) and in-card button labels 11 pt; Tonight's Sleep times are 22 pt
  without AM/PM (the spec's 24 pt measures 15 pt digits, ≈21–22). `.label` stays at DR's 11 pt floor.
- **Contributor pitch.** 66 pt (every 2026 capture), not DR's 53 (the 2025 App Store mock).
- **Bottom scrim.** Clear → black 60%, not 95%: WHOOP's content is still 35–60% bright at the capsule.
- **Hatched track.** The spec's and DR's "45° lines, 1 pt, every 4 pt, white 7%" reads as a faint pinstripe
  beside every 2026 capture. WHOOP draws a bold zebra, its stripes 12.5–13 px every 25.5–26 px at 3x, #35393B
  on a #1E2326 card (deep-dives-2026/14, /15; the impact tracks of /39 and the zone bars of help-center/82
  match). `PulseHatchedTrack` defaults to an 8.5 pt period with a stroke of 0.35 × the period (≈3 pt, light
  and dark about half each along the bar), and `hatch` is white 10%. The typical-range box over a bar is
  a white 10% veil (`typicalBox`) with no stripes of its own, so the track's stripes show through it and
  the bar stays unstriped (help-center/82).
- **Sleep dive nights.** §1.7 [Z] puts a "‹ LAST NIGHT ›" pager under the bar; it pushed the ring 65 pt
  below WHOOP's, so the nights step in the bar's title ("‹ TODAY ›") instead.
- **Coach button fill.** The spec's `#171728 → #121A25` reads darker than every capture; Pulse uses the
  sampled `#2C2B3C → #20252F`, a rim lit from the top-left only, radius 24 and a lit orb inside a 1.33 pt
  ring (`PulseTheme.Coach`).
- **Dial label gap.** The spec's 12–13 pt is to the label's caps; the text frame starts ≈2.5 pt above them,
  so `Dial.labelGap` is 10.
- **Stress time in whole hours.** `DaytimeStress` scores stress by the hour (`bucketSeconds` 3600), and the
  5-minute curve §3.22 [Z] integrates does not exist, so the Health tab's card and TOTAL DAY print "4 h"
  (`HealthFormat.stressHours`), not WHOOP's minute-precise "0:44". A finer curve prints its own fraction.
- **Healthspan's "Sleep regularity".** WHOOP's row is SLEEP CONSISTENCY, but ZENO Age reads
  `VitalityEngine.sleepConsistency`, 1 − the variation of the nightly hours. That is not the timing-based
  Sleep Consistency the Sleep dive shows, so naming the row the same would put two different "consistency"
  figures on two screens.
- **Healthspan's subtitle.** "FINAL IN N DAYS", not WHOOP's "NEXT UPDATE IN N DAYS": the weekly pass refines
  the current week's ZENO Age every day until the week closes, so "next update" would promise a figure that
  holds still.
- **Healthspan's years.** A pillar row prints its years only when the rows add up to the ZENO Age the weekly
  pass stored (`HealthspanBreakdown`, within 0.1 years); otherwise the rows show values without years and
  the page says the breakdown updates with this week's ZENO Age. The seeded demo store's ZENO Age is
  synthetic, so its captures always show the withheld state. TIME IN HR ZONES 1-3 / 4-5 and STRENGTH
  ACTIVITY TIME count the week's workouts (ZENO Age does not use them, so they carry no years); VO₂ MAX
  is a row without years, because the weekly pass leaves it to Fitness Age.
- **Health Monitor footer text.** 11 pt (`.chip`), the floor, where WHOOP's runs ≈10.5 pt (reviews/r100).
- **Strength.** The trainer's ⓘ is the shared `.info` at white 50%, where g01/g03 draw it white. Exercise
  Details' change chip sits beside the M | 6M controls as on g03, and may shrink to 75% to fit there,
  below DR's 11 pt floor.

Deliberate departures [Z] the groups recorded:

- **App Settings is pushed, not presented.** WHOOP presents it with "✕" over the visible tab bar (§1.6,
  §3.33, health-more-2026/08). Pulse pushes it from More, with "‹" and no capsule like every pushed page,
  so that AI Settings and Data Export can open over it as the "✕" sheets they are: the navigator has no
  modal over a modal (a modal's own stack only pushes).
- **"Analyzing…" replaces the floating Coach button only.** On pushed screens and modal roots the button
  turns into the pill while the Coach writes (§1.2); the tab roots' button beside the capsule keeps its
  shape, where a wider pill would squeeze the tabs.
- **The dives' coach pill shows while the Coach is on, set up or not** (it opens setup when not); §3.4 [Z]
  asks for an inline insight card until a provider exists.
- **Time in zones covers the whole Strain day** (the window Strain scores over), not WHOOP's "derived from
  logged activities": ZENO's Strain is all-day and no longer auto-creates workouts.
- **Recovery's Trend View bands** read (67-100%) and (0-33%), not WHOOP's (67-99%) and (1-33%): ZENO's
  Recovery is clamped to 0–100 and can print both ends.
- **Trend View stress.** §3.12's stress views show AVG. HIGH STRESS over 100%-stacked HIGH / MEDIUM / LOW
  bars for Total Day, Sleep and Non-Activity stress. ZENO stores one 0–3 level per day; its hourly
  `DaytimeStress` curve is scored on demand from a day's raw heart rate, R-R and motion, far too heavy for
  every day of a 6M window. So Day Stress charts the daily level as AVERAGE with a STRESS BREAKDOWN (DAYS),
  and Sleep and Non-Activity stress are omitted, as are + ADD ENTRY (Weight, Lean Body Mass) and + ADD
  MANUAL VO₂ MAX VALUE (no dated entry flow exists). Calories print kcal: they are active calories, as Home
  and the Strain dive print them.
- **Sleep Planner alarm modes.** ALARM SET TO shows Sleep Goal and In the Green as unavailable: they need
  a phone watching the night for a light-sleep moment, which ZENO has on Android only. The spec asks for
  BETA modes that need the app to stay connected.
- **The day timeline held upright** keeps a "✕ HEART RATE" bar (it is a modal), the sync line, a plot
  that fits the width, the turn hint and the day's low / average / high, where WHOOP letterboxes the
  landscape chart on black (help-center/106).
- **Year in Review's Everest** counts a step as a 16 cm stair (§3.39 [Z]); WHOOP's /50 implies ≈0.0875 m
  a step, a rule it never states.
- **Onboarding.** The four NOOP attestations are ticked one by one (no "SELECT AND AGREE TO ALL"); the
  landing's second pill is "CONTINUE WITHOUT A STRAP"; What to Expect Next lists the nights each score
  really waits for (Sleep 1, Recovery and Sleep Consistency 4, personal Health Monitor ranges 14) and no
  ZENO Age; the device tutorial's ring counts its own three steps; a step too tall for the screen shrinks,
  then drops, its illustration; status pages stop growing at accessibility1, and the CTA row at xxxLarge.

Housekeeping the next wave inherits:

- Pulse's UI strings use `String(localized:)` but are not in `Strand/Resources/Localizable.xcstrings` yet,
  so `python3 Tools/i18n_audit.py --ci <base>` lists them. Seed the catalog once the rebuilt screens settle
  (`Tools/seed-string-catalog.py`, which reads the `.stringsdata` a build emits).
- Classic screens reachable from Pulse (More's tools, the Lab Book, the classic Settings, …) and the
  widgets and Live Activities still say Charge / Effort / Rest, the widgets with Effort on 0–100. The
  spec's one-vocabulary rule (§0.3) holds on the rebuilt screens, and the Coach engine speaks Recovery /
  Strain / Sleep while Pulse runs (`CoachVocabulary`), with My Memory as its standing system context
  (`AICoachEngine.systemContext`).
- The dives' coach summary pills are local sentences built from each dive's own figures. Home's Daily
  Outlook opens on the scheduled morning brief once one exists for today, else on its template
  (`PulseCoachOutlook`).
- The day streak counts consecutive days with a Recovery score (`StreakCalculator`, the classic Settings
  card's rule).
- WHOOP's Health Monitor tile prints "2/5 Metrics" next to OUT OF RANGE; whether that counts the metrics in
  or out of range is unconfirmed. Pulse names the one metric out of range, or "k/n Metrics" out of range.
- The running gym session's bar is the classic `LiftSessionBar` (`Strand/Screens`, shared with the classic
  shell), not yet in Pulse's tokens; a Pulse twin needs its own connected-gated heart-rate leaf. The Sleep
  dive's EDIT opens the shared `SleepTimeEditor` in its classic look (`NoopCard`, `StrandFont`).
- Outside the `.noopbak` whitelist, so on this iPhone only: the profile name (`profile.displayName`), the
  Weekly Plan (`pulse.plan.v1`), challenges (`pulse.challenges.v1`), the Coach's history and memories
  (`coach-threads.json`, `coach-memory.json`) and Journal notes (journal-plan, below). Adding one is a
  WhoopStore change on both platforms.

Activity group (`Screens/Activity/`), deviations and what the next wave inherits:

- **Recovery activities compare with the 30-day AVERAGE.** WHOOP's recovery variant captions its tiles
  "VS. 30 DAY RANGE" over chips whose meaning is unconfirmed; Pulse's chips print this sport's 30-day mean,
  so the caption says AVERAGE on both variants rather than naming a range it does not draw.
- **STRESS CHANGE and the STRESS tab use the Stress Monitor's own readings** (`DaytimeStress`, an hour of
  heart rate re-read every half hour, 6 AM–10 PM, the lens Settings picks): the change is the reading
  nearest the start against the next one nearest the end, the curve is coarser than WHOOP's minute-level
  one (the chart says so), and the "▲0.9" chip beside WHOOP's value is left out (meaning unconfirmed). No
  reading covering the activity hides both and says why. `activityStress` reads them through the Stress
  Monitor's own resolver (`stressResult`), so the two share one cache.
- **IMPACT ON RECOVERY** counts days in the last 90 with and without the sport, each only when the next
  morning's Recovery scored, and unlocks at five each (WHOOP's rule); the value is `BehaviorInsights`'
  next-day Recovery difference, grey unless it clears the significance rule. The milestone card (§3.6
  item 11) is not built yet; the Achievements it would announce now exist (§3.30).
- **No Strain Target from a carried Recovery.** As the Strain dial draws no band or tick from an earlier
  night's Recovery, the Start panel withholds the target until today's scores and says why. A day already
  at its target shows a check, not a 0.0 target, and starts the session with none.
- **The Start picker has no SLEEP tab** [Z]: ZENO's live engine records workouts; a sleep is detected from
  the strap or added afterwards. Add Activity offers one "Sleep or nap" entry, since both saved the same
  manual sleep and the sleep pipeline itself files it with the night or as a nap.
- **Add Activity's banner** keeps "ZENO scores an activity you add from your strap's heart rate over that
  time." rather than the spec's [Z] "Your edits help ZENO recognise your activities.": the detector is a
  fixed heuristic that learns nothing from edits.
- **"View HR settings"** opens More's HEART RATE SETTINGS (`PulseHeartRateSettingsRoute`), which edits
  the max HR and zones the zone footnote names.
- **After End & Save** Activity Details draws the live session's own samples until the strap's history
  covers 90% of the window, and `Repository.workoutRows` keeps a row saved with its own Avg / Max HR (a
  live session's) until the trace covers 90% of it (`Repository.traceCoversWorkout`).
- Housekeeping: the group's own colours, sizes, radii and type (the light panel's ink, map overlays, the
  route card's 14 pt radius, the panel's text styles) sit in `PulseActivityStyle` until the foundation
  adopts them as `PulseTheme.Activity` tokens; `PulseActivityDialogCard` copies `PulseDialogCard` only to
  add a text second action and an attributed message, and can fold back into it once the card offers
  both; `AppModel.endWorkout` scores with `profile.hrMax` (rounded Tanaka) where the day uses
  `effortHRmax`, so the engine owner should align them (the live ring follows `endWorkout`).

### journal-plan: decisions and hand-offs

Measured against the 2026 captures where they disagree with the spec:

- **Journal section labels have no hairline.** DAYTIME, NIGHTTIME, STATUS, YOUR … PLAN and NOTES are
  plain caps (journal-plan-2026/01, Jun 2026); the spec's "label + hairline" (§3.17 item 9) is the 2025
  build (/95). SELECT BEHAVIORS keeps the hairline after CURRENTLY SELECTED (/13, Sep 2026).
- **The Journal question title is 24 pt Semibold**, not ≈28: help-center/105 measures caps ≈16.5 pt on a
  30 pt line pitch against its own 12 pt "JOURNAL" and 13 pt date, and /90 gives 24–26 against its 15 pt
  rows (`PulseTheme.JournalPlan.questionStyle`).
- **The Journal's page gradient is a fixed ≈520 pt** on both the 956 pt and the 932 pt screen, where
  `Gradients.journalToday` / `journalPastDay` place their stops by screen height
  (`PulseTheme.JournalPlan.pageGradientHeight`).

Left out on purpose [Z]:

- **"X%+ of the Day in High Stress Zone"** (§3.18 ZENO data). ZENO keeps no per-day stress timeline, and
  scoring 90 past days of heart rate, R-R and motion through `DaytimeStress` on each visit costs more than
  Behavior Insights can spend; a cheaper proxy would disagree with the Stress Monitor. It can join
  `AutoBehaviors` once each day's high-stress minutes are stored (health group). "Early Workout" is in:
  an activity that started within 3 h of waking, judged against the next morning's Recovery.
- **The time follow-up and its slider** ("When did you stop? 18:00", /08): a journal row stores one number,
  which the amount already uses. **Apple Health pre-filling** ("Pre-filling compatible via Apple Health ⓘ"):
  ZENO imports no mindful minutes, and no library behaviour is a workout question. **The classic caffeine
  log as a question**: "Consumed caffeine?" with its servings is the behaviour Behavior Insights tests; a
  second caffeine figure would contradict it.
- **TALK on the Journal's Smart log card** stays hidden until the Coach sheet can start in voice; it would
  open the same text composer as TEXT.

Hand-offs:

- **Journal notes are not backed up.** A day's note lives in UserDefaults (`pulse.journal.notes`) because
  the journal table's `notes` column belongs to each answer, not to the day. It is outside the `.noopbak`
  whitelist and Android does not read it; the WhoopStore owner can add it to `BackupSettings` on both
  platforms (it would cross as one JSON string) or give the journal a per-day note.
- **Group tokens.** `Components/JournalPlanTokens.swift` (`PulseTheme.JournalPlan`) holds the colours and
  sizes the shared theme lacks, sampled on the captures; values the theme already has reference its tokens.
  The foundation can hoist them into `PulsePalettes.Journal` / `.Plan` without call sites changing.
