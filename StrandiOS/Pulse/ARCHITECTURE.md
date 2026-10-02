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

- **Model/**: `PulseModel` owns the selected day (`dayOffset`) and publishes `home`, `recovery`, `strain`,
  `sleep`, `health`. `PulseSnapshotBuilder` builds them off the main actor, caching history reads per
  refresh. `detailKey` changes whenever a screen should reload (refresh, day, display preferences).
- **Shell/**: the floating tab capsule, the Coach button, one `NavigationStack` per tab, the sheet and
  cover slots, the anchored action (＋) menu, `NavRouter` requests and Home Screen quick actions.
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
├── Components/               shared views (foundation only; see §6), including PulseCards (tiles, pills,
│                             zone rows, impact bars, day circles, goal rings, dialog, error page, wheel
│                             sheet), PulseDayCharts (HR area, 24 h stress, Strain & Recovery),
│                             PulseSkeleton and PulseActionMenu
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
| home | `Screens/Home/` | `PulseHomeView` (Home tab root), `PulseCustomizeDashboardView` (`.customizeDashboard`), `PulseCoachingStack`, `PulseDashboardViews`, `PulseCalibrationTimelineView` (`.calibrationTimeline`). The action menu (§3.2) is the foundation's `PulseActionMenu`; Home places it with `PulseSectionHeader(accessory: .actionMenu)` |
| sleep | `Screens/Sleep/` | `PulseSleepDiveView` (`.sleepDive`), `PulseSleepPlannerView` (`.sleepPlanner`) |
| recovery-strain | `Screens/Recovery/`, `Screens/Strain/` | `PulseRecoveryDiveView` (`.recoveryDive`), `PulseStrainDiveView` (`.strainDive`) |
| trends | `Screens/Trends/` | `PulseTrendView` (`.trendView(metric:)`), `PulseTrendsTabView` (Trends tab root), `PulseWeeklyDigestView` (`.weeklyDigest`), `PulseTrainingLoadView` (`.trainingLoad`) |
| activity | `Screens/Activity/` | `PulseActivityDetailView` (`.activityDetail(_:)`), `PulseStartActivityView` (`.startActivity`), `PulseAddActivityView` (`.addActivity`), `PulseActivityPickerView` (`.activityPicker`) |
| health | `Screens/Health/` | `PulseHealthTabView` (Health tab root), `PulseHealthspanView` (`.healthspan`), `PulseHealthMonitorView` (`.healthMonitor`), `PulseStressMonitorView` (`.stressMonitor`) |
| more-profile | `Screens/More/`, `Screens/Profile/` | `PulseMoreView` (More tab root), `PulseAppSettingsView` (`.appSettings`), `PulseDeviceSettingsView` (`.deviceSettings`), `PulsePrivacyDataView` (`.privacyData`), `PulseReportProblemView` (`.reportProblem`), `PulseFirstWeekView` (`.firstWeek`), `PulseProfileView` (`.profile`), `PulseLevelsView` (`.levels`), `PulseAchievementsView` (`.achievements`), `PulseStreakView` (`.dayStreak`) |
| journal-plan | `Screens/Journal/`, `Screens/Plan/` | `PulseJournalView` (`.journal(dayOffset:)`), `PulseBehaviorInsightsView` (`.behaviorInsights`), `PulseWeeklyPlanView` (`.weeklyPlan(editing:)`) |
| cycle-coach | `Screens/Cycle/`, `Screens/Coach/` | `PulseCycleInsightsView` (`.cycleInsights`), `PulseCoachSheet` (`.coach(seed:)`, the Coach button), `PulseMemoryView` (`.memory`) |
| onboarding-strength | `Screens/Onboarding/`, `Screens/Strength/` | `PulseOnboardingView` (`.onboarding`), `PulseStrengthTrainerView` (`.strengthTrainer`) |
| extras | `Screens/Extras/` | `PulseYearInReviewView` (`.yearInReview`), `PulseChallengesView` (`.challenges`), `PulseDayTimelineView` (`.dayTimeline`) |

What each placeholder does today:

- **New screens** show `PulsePlaceholderScreen`: the spec's title, back or close, a "being rebuilt" card
  naming the spec section and group, and "Use it today" links to the classic screen that does the job now.
- **Screens that already worked keep working**: `PulseSleepDiveView`, `PulseRecoveryDiveView`,
  `PulseStrainDiveView` and `PulseHealthTabView` host the current Pulse screens (`PulseSleepView`,
  `PulseRecoveryView`, `PulseStrainView`, `PulseHealthView`, in the same folders); `PulseCoachSheet` wraps
  the classic `CoachView`. Replace the body, then delete the old file once nothing uses it. The dives
  already have WHOOP's top (custom bar with ⓘ, the 260 pt ring at y≈130, 70 pt score) and float the coach
  summary pill with a local sentence; their groups add the cards below.
- `PulseHomeView` follows the observed 2026 order (header, dials, monitor tiles, My Day with the coach
  pill or Ask row, Today's Activities, Tonight's Sleep and My Journal, My Plan's empty state, My Dashboard
  rows and charts, footer); the home group adds the coaching stack, the Menstrual card, the new-member
  variant and Customize Dashboard. `PulseMoreView` is the current screen, restyled.
- The old screens' shared pieces (`PulseStressSection`, `PulseMiniStat`, `PulseDetailLoading`,
  `PulseRow`, `PulseStrainTargetContent`, …) live in `Components/PulseLegacyComponents.swift` so deleting
  one screen file never breaks another. New code uses the catalogue in §6 instead.

## 4. Navigation

### Tabs and the Coach (spec §1.1, §1.2)

- `PulseTab`: `.home`, `.health`, `.trends` (ZENO's replacement for Community), `.more`. The app always
  launches on Home. A tab re-tap refreshes, then pops to root, then scrolls to top (`\.scrollToTopSignal`).
- The capsule and the Coach button show on a tab's ROOT and fade out on push (spec §1.2: no tab bar on a
  pushed screen). A pushed screen floats its own Coach button or summary pill with
  `PulseScreenScaffold(coach:)`, in exactly the tab root's spot (12 pt from the right edge, its bottom on
  the capsule's line 28 pt above the screen edge), so it never jumps on push.
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
→ view mapping, and `presentation` follows spec §1.6:

| Presentation | Routes |
|---|---|
| `.fullScreen` | customizeDashboard, startActivity, deviceSettings, journal, onboarding, strengthTrainer, yearInReview, dayTimeline, guidedSession |
| `.sheet` | sleepPlanner, addActivity, appSettings, coach, weeklyPlan(editing: true) |
| `.push` | everything else (dives, trendView, monitors, profile pages, privacyData, reportProblem, firstWeek, trainingLoad, classic screens, …) |
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
sheet opens as the modal's own sheet), so a modal is never replaced or blocked by the shell.

`\.pulseNavigator`, `\.pulseCoach` and `\.pulseActionMenu` compare equal across the shell's re-renders
(their closures reach the owner's current state; `identity` names the owner), so reading them does not
invalidate a screen on every push or sheet.

### The action (＋) menu (spec §1.3, §3.2)

My Day's "+" is `PulseSectionHeader(…, accessory: .actionMenu)`: tapping it opens the anchored popover
(`PulseActionMenuHost`, drawn by the shell above the tab bar) with START ACTIVITY (RESUME ACTIVITY while a
workout runs) · ADD ACTIVITY · STRENGTH TRAINER · COMPLETE YOUR JOURNAL, a hairline, then BREATHE · MARK
MOMENT; the "+" morphs into "✕". It drops down, or opens upward with the rows mirrored when the "+" sits
low. Each row runs a `PulseQuickAction`, which opens its route through `forExistingEntryPoint`. The shell's
＋ SHEET (`PulseActionSheet`, the same rows) is kept only for NavRouter's quick-actions request and for a
"+" inside a modal, where no anchor host listens. Intervals, Live HR and the guided session moved to More.

### Existing entry points and `isRebuilt`

The shell's existing entry points (NavRouter requests, Home Screen quick actions, the ＋ menu, Home's
rows) keep opening the classic screen they always opened, through
`PulseRoute.forExistingEntryPoint`. Each placeholder type has `static let isRebuilt = false`; when a group
finishes its screen it sets that to `true` in its own file, and those entry points switch to the rebuilt
route without anyone touching the shell. The fallbacks are in `PulseRoute.classicFallback`:

| Route | Classic fallback | Entry points that use it |
|---|---|---|
| `.sleepPlanner` | Alarms | NavRouter `.alarms`, Home's Tonight's Sleep |
| `.deviceSettings` | Devices | NavRouter `.devices` |
| `.profile` | Settings | Home's avatar |
| `.journal(dayOffset:)` | Journal (InsightsView) | NavRouter `.journal`, quick action, ＋ menu |
| `.startActivity` | Workouts | quick action, ＋ menu, Home's START ACTIVITY |
| `.addActivity` | Workouts | Home's + ADD ACTIVITY, ＋ menu |
| `.strengthTrainer` | Lift Log | ＋ menu |
| `.activityDetail(_:)` | Workout detail | Home and Strain dive workout rows |
| `.dayTimeline` | Full-day chart | Home's ⤢ |
| `.healthMonitor`, `.stressMonitor` | Classic Health / Stress | Home's monitor tiles, the dashboard's STRESS MONITOR card |
| `.behaviorInsights` | What moves you | Home's BEHAVIOR INSIGHTS |
| `.trendView` | the metric's detail | My Dashboard rows (the row's own detail route), STRAIN & RECOVERY |
| `.privacyData`, `.reportProblem`, `.firstWeek`, `.trainingLoad` | Backup & Sync, Test Centre, scoring guide, Trends | placeholders' "Use it today" links |
| `.weeklyDigest`, `.healthspan`, `.appSettings` | see `classicFallback` | placeholders' "Use it today" links |

`PulseRoute.isRebuilt` is an exhaustive switch (no `default`): a new route has to name where its flag
lives, so no entry point can open a "being rebuilt" placeholder while a working classic screen exists.

`PulseTrendsTabView.isRebuilt` also decides whether NavRouter `.trends` pushes the classic Trends screen
onto the Trends tab. NavRouter `.journal` passes `router.pendingJournalDayOffset` into `.journal(dayOffset:)`;
a rebuilt Journal should clear that offset once it has read it.

## 5. Adding or rebuilding a screen

1. **Replace the placeholder body** in your group's file. Keep the type name and the route's parameters.
   Build on `PulseScreenScaffold`:

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
| `PulseNavTrailing` | `.none`, `.info(action)`, `.achievement(symbol:tint:count:action:)`, `.symbol(name, accessibilityLabel:, action:)` | ⓘ 27.5 pt, achievement chip, ⚙ / clock / ? / ••• |
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
| Buttons | `.buttonStyle(.pulseNested)` (40 pt, 44 pt hit, 11 pt label), `.pulseNested(fill:)`, `.pulseOutline(color)`, `.pulseOutlineWhite`, `.pulseFilledWhite`, `.pulseFilledBlue` (15 pt labels); `PulseButtonRow { … }` stacks side-by-side buttons when they no longer fit; `PulseTextCTA(title:tint: .ai \| .color(c), action:)` |

### Charts (Swift Charts, spec §2.7)

| Component | Signature |
|---|---|
| `PulseChartDatum` | `(id:label:sublabel:value:color:valueLabel:)`; `value: nil` is a gap, never zero |
| `PulseChartCard` | `(_ title:, accessory:, style:) { chart }` |
| `PulseBarChart` | `(data:yDomain:gridValues:gridlineCount:showsYAxisLabels:highlightID:barWidth:height:emptyMessage:)` |
| `PulseLineChart` | `(data:color:typicalRange:average:yDomain:gridlineCount:showsYAxisLabels:highlightID:showsArea:showsValueLabels:height:emptyMessage:)` |
| `PulseStackedBarChart` | `(columns: [Column(id:label:sublabel:segments:totalLabel:)], yDomain:, gridlineCount:, highlightID:, barWidth:, height:)` |
| `PulseHRAreaChart` | `(points: [PulseTimeValue], window:, color:, startLabel:, endLabel:, startSymbol:, endSymbol:, yValues:, height:)`: sleep or activity HR |
| `PulseStressChart` | `(points:periods: [PulseChartPeriod], now:, currentLevel:, xLabels:, height:)`: value-coloured 24 h stress |
| `PulseStrainRecoveryChart` | `(days: [Day(id:label:sublabel:strain:recovery:)], highlightID:, height:)`: the dual-axis week |
| `PulseChartAxis` | `gridValues(_:count:)`, `zeroBased(_:)`, `dynamic(_:)` |
| `PulseHatchedTrack` | `(color:spacing:cornerRadius:)` |

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
| `PulseCoachAnalyzingPill` | `()` |

## 7. Theme tokens

- Page: `PulseTheme.pageStops` (sampled on 2026 captures, §9), `pageTop`, `pageBottom`, `pageNearBlack`,
  `barStrip`, `scrim` (black 60% at the capsule's top edge).
- Surfaces: `card` (white 10%), `detail` (4.5%), `nested`, `well`, `gridOnCard`, `gridOnPage`, `dash`,
  `targetBand` (27% as seen) / `targetBandOverTrack` (19%, drawn over the track), `pressDisc`, `track`,
  `divider`, `coachingCard`, `coachingPeek`, `bannerWell`, `rowCardTop/Bottom`, `rowIcon`, `rowSubline`,
  `listSectionHeader`, `achievementChip`, `filterChip`, `dialogTop/Bottom`, `chartHighlight`,
  `pagerCapsule` (5%) / `pagerPill` (+10%), `streakPill`, `avatarFallback`, `skeleton`, `strapOutline`,
  `batteryText`, `preAddedChip`, `tagFill`, `segmentOff`, `typicalBand`, `hatch`, `averageLine`,
  `calloutGlow` / `calloutRim`, `menuTop/Bottom`, `menuDim`, …
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

DEBUG builds read these launch arguments (`Debug/PulseDemo.swift`; nothing ships in Release):

| Flag | Effect |
|---|---|
| `--demo-seed` | Fill the store with deterministic data anchored on today (uninstall first for a fresh seed); skips onboarding gates |
| `--pulse-tab home\|health\|trends\|more` | Select a tab |
| `--pulse-route <name>` | Open any route at launch on its natural tab; names in `PulseRoute.debugCatalog` (`sleep-dive`, `trend-view:rhr`, `classic-settings`, `tab-steps`, …) |
| `--pulse-push recovery\|strain\|sleep` | Push a dive onto Home |
| `--pulse-present <name>` | Present any route modally in its own stack ("✕" at its root), whatever its usual presentation |
| `--pulse-sheet actions\|coach\|menu` | Present the ＋ sheet or the Coach sheet, or open Home's anchored ＋ menu |
| `--pulse-scroll <anchor>` | Scroll to `.id("pulse.<anchor>")` once loaded (Home: `monitors`, `myday`, `activities`, `tonight`, `journal`, `plan`, `dashboard`, `stress`, `strain-recovery`, `bottom`; dives: `contributors`, `history`, `stages`, `build`, `hr`, `zones`; `gallery-dials`, `gallery-header`, `gallery-feature`, `gallery-daycharts`, `gallery-overlays`, …) |
| `--demo-sync` | A connected strap's battery in the Home header, for captures |
| `--pulse-day N` / `--pulse-night N` / `--pulse-range 7\|30\|90` | Home N days back / the Sleep dive N nights back / the Recovery history range |
| `--pulse-gallery` | Present the component gallery |
| `-noop.coachEnabled NO` | Coach off for this launch (a UserDefaults launch argument) |

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
- **Sleep dive nights.** §1.7 [Z] puts a "‹ LAST NIGHT ›" pager under the bar; it pushed the ring 65 pt
  below WHOOP's, so the nights step in the bar's title ("‹ TODAY ›") instead.
- **Coach button fill.** The spec's `#171728 → #121A25` reads darker than every capture; Pulse uses the
  sampled `#2C2B3C → #20252F`, a rim lit from the top-left only, radius 24 and a lit orb inside a 1.33 pt
  ring (`PulseTheme.Coach`).
- **Dial label gap.** The spec's 12–13 pt is to the label's caps; the text frame starts ≈2.5 pt above them,
  so `Dial.labelGap` is 10.

Housekeeping the next wave inherits:

- Pulse's UI strings use `String(localized:)` but are not in `Strand/Resources/Localizable.xcstrings` yet
  (true of the first Pulse screens too), so `python3 Tools/i18n_audit.py --ci <base>` lists them. Seed the
  catalog once the rebuilt screens settle (`Tools/seed-string-catalog.py`, which reads the `.stringsdata`
  a build emits).
- Classic pieces still inside the current screens say Charge / Effort / Rest (the Recovery dive's
  "What shaped it" driver rows, the Coach sheet's subtitle, classic screens behind "Use it today" links).
  The spec's one-vocabulary rule (§0.3) applies to the rebuilt screens.
- The hypnogram and its stage rows still use the Oura stage palette from StrandDesign; the sleep group
  should draw stages in `PulseTheme.Stage` (both together, so the legend never disagrees with the chart).
- The Coach sheet still wraps the classic `CoachView`: its subtitle says "charge, effort, rest", it has a
  green "Save key" button and its provider picker truncates. The cycle-coach group rebuilds it in Pulse's
  look and vocabulary (§0.3).
- The coach summary pills on the dives and the Daily Outlook seed are local template sentences; the
  cycle-coach group replaces them with the Coach's text (`CoachBriefScheduler`) where a provider exists.
- Home's STRESS MONITOR chart draws today's hourly curve (`DaytimeStress`); WHOOP's is finer-grained and
  covers past days. The headline level and the curve come from different models (`StressModel` and the
  hourly proxy), so they can disagree; the health group should give both one source.
- The day streak counts consecutive days with a Recovery score (`StreakCalculator`, the classic Settings
  card's rule). Initials on the avatar need a stored name, which ZENO does not have yet (Edit Profile).
- WHOOP's Health Monitor tile prints "2/5 Metrics" next to OUT OF RANGE; whether that counts the metrics in
  or out of range is unconfirmed. Pulse names the one metric out of range, or "k/n Metrics" out of range.
