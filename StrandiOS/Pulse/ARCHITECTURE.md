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
  cover slots, `NavRouter` requests and Home Screen quick actions.
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
├── Components/               shared views (foundation only; see §6)
├── Shell/                    PulseRootView, PulseTabBar, PulseCoachButton, PulseRoutes,
│                             PulseNavigator, PulseActionSheet, PulseSettingsCard (foundation only)
├── Model/                    PulseModel, PulseSnapshotBuilder, PulseSnapshots, PulseScore,
│                             PulseDialMapping (foundation only; extend, never edit)
├── Screens/<Area>/           one folder per screen group (§3)
└── Debug/                    PulseDemo (launch flags, demo seed), PulseComponentGallery
```

## 3. Ownership map

Each group edits only its own folders. It may add files there, including
`PulseSnapshotBuilder+<Group>.swift` / `PulseSnapshots+<Group>.swift` extension files (§5) and
group-specific components named `Components/<Group>*.swift` if they are reusable within the group. It must
NOT edit Theme/, the shared Components/ files, Shell/ or the Model/ core files. If a group needs a shared
token, component or route that does not exist, it asks the foundation owner.

| Group | Folders | Types (route) |
|---|---|---|
| home | `Screens/Home/` | `PulseHomeView` (Home tab root), `PulseCustomizeDashboardView` (`.customizeDashboard`), `PulseCoachingStack`, `PulseDashboardViews`, `PulseCalibrationTimelineView` (`.calibrationTimeline`) |
| sleep | `Screens/Sleep/` | `PulseSleepDiveView` (`.sleepDive`), `PulseSleepPlannerView` (`.sleepPlanner`) |
| recovery-strain | `Screens/Recovery/`, `Screens/Strain/` | `PulseRecoveryDiveView` (`.recoveryDive`), `PulseStrainDiveView` (`.strainDive`) |
| trends | `Screens/Trends/` | `PulseTrendView` (`.trendView(metric:)`), `PulseTrendsTabView` (Trends tab root), `PulseWeeklyDigestView` (`.weeklyDigest`) |
| activity | `Screens/Activity/` | `PulseActivityDetailView` (`.activityDetail(_:)`), `PulseStartActivityView` (`.startActivity`), `PulseAddActivityView` (`.addActivity`), `PulseActivityPickerView` (`.activityPicker`) |
| health | `Screens/Health/` | `PulseHealthTabView` (Health tab root), `PulseHealthspanView` (`.healthspan`), `PulseHealthMonitorView` (`.healthMonitor`), `PulseStressMonitorView` (`.stressMonitor`) |
| more-profile | `Screens/More/`, `Screens/Profile/` | `PulseMoreView` (More tab root), `PulseAppSettingsView` (`.appSettings`), `PulseDeviceSettingsView` (`.deviceSettings`), `PulseProfileView` (`.profile`), `PulseLevelsView` (`.levels`), `PulseAchievementsView` (`.achievements`), `PulseStreakView` (`.dayStreak`) |
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
  the classic `CoachView`. Replace the body, then delete the old file once nothing uses it.
- `PulseHomeView` and `PulseMoreView` are the current screens, restyled; their groups rebuild them in place.
- The old screens' shared pieces (`PulseStressSection`, `PulseMiniStat`, `PulseDetailLoading`,
  `PulseRow`, `PulseStrainTargetContent`, …) live in `Components/PulseLegacyComponents.swift` so deleting
  one screen file never breaks another. New code uses the catalogue in §6 instead.

## 4. Navigation

### Tabs and the Coach (spec §1.1, §1.2)

- `PulseTab`: `.home`, `.health`, `.trends` (ZENO's replacement for Community), `.more`. The app always
  launches on Home. A tab re-tap refreshes, then pops to root, then scrolls to top (`\.scrollToTopSignal`).
- The capsule and the Coach button show on a tab's ROOT and fade out on push. A pushed screen floats its
  own Coach button or summary pill with `PulseScreenScaffold(coach:)`.
- `@Environment(\.pulseCoach)` gives `availability` (`.off`, `.needsSetup`, `.ready`) and `open(seed)`.
  Off hides every coach surface and stretches the capsule; never read `noop.coachEnabled` yourself.

### Routes (Shell/PulseRoutes.swift)

`PulseRoute` names every destination: the spec's navigation map (§1.8), the ownership map above, every
classic screen (`.classic(PulseClassicDestination)`) and the shared metric routes (`.tab(TabRoute)`).
`PulseRoute.destination` is the single route → view mapping, and `presentation` follows spec §1.6:

| Presentation | Routes |
|---|---|
| `.fullScreen` | customizeDashboard, startActivity, deviceSettings, journal, onboarding, strengthTrainer, yearInReview, dayTimeline, guidedSession |
| `.sheet` | sleepPlanner, addActivity, appSettings, coach, weeklyPlan(editing: true) |
| `.push` | everything else (dives, trendView, monitors, profile pages, classic screens, …) |

Open a route from a screen:

```swift
@Environment(\.pulseNavigator) private var navigator

// A row that IS the link: push routes stay value links (a tab re-tap pops them), modal routes present.
PulseLink(.healthMonitor) { PulseMetricRow(symbol: "waveform.path.ecg", title: "Health Monitor") }
    .buttonStyle(PulsePressStyle())

Button { navigator.open(.sleepPlanner) } label: { … }      // as the spec presents it
navigator.push(.trendView(metric: "hrv"))                   // force a push
navigator.present(.classic(.alarms))                        // force a modal (classic screens get "Done")
navigator.quickAction(.menu)                                // the ＋ menu, or one of its screens
```

A presented route gets its own `NavigationStack` (`PulseModalHost`); its root sees
`\.pulseModalRoot == true`, so `PulseScreenScaffold` shows "✕" instead of "‹". Inside a modal,
`navigator.open` pushes within that modal.

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
| `.addActivity` | Workouts | Home's + ADD ACTIVITY |
| `.strengthTrainer` | Lift Log | ＋ menu |
| `.activityDetail(_:)` | Workout detail | Home and Strain dive workout rows |
| `.dayTimeline` | Full-day chart | Home's ⤢ |
| `.stressMonitor`, `.trendView`, `.weeklyDigest`, `.behaviorInsights`, `.healthspan`, `.healthMonitor`, `.appSettings` | see `classicFallback` | placeholders' "Use it today" links |

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
           PulseScreenScaffold(title: String(localized: "Health Monitor"), coach: .button,
                               ready: snapshot != nil) {
               if let snapshot { … } else { PulseDetailLoading() }
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
   newer refresh or day superseded it, so keep the old snapshot on screen in that case. Reload on
   `model.detailKey` (day-scoped screens) or `model.healthKey` (always-today screens). `PulseRequest`
   carries `days`, `sleeps`, `importedSleep`, `vitalRows`, `prefs`, `profile` and `day` (`offset`, `key`,
   `date`); `repo` is available for anything else.

3. **Use the shared components and tokens** (§6, §7). Put a reusable piece only your group needs in your
   folder; if two groups need it, ask for it in Components/.
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
| `PulseScreenScaffold` | `(title: String? = nil, role: PulseScreenRole = .pushed, trailing: PulseNavTrailing = .none, coach: PulseCoachAccessory = .none, coachSeed: String? = nil, background: PulseBackground.Style = .gradient, showsNavigationBar: Bool = true, spacing: CGFloat = 16, horizontalPadding: CGFloat = 16, topPadding: CGFloat = 8, refresh: (() async -> Void)? = nil, ready: Bool = true) { content }` | Fixed gradient, 16 pt margins, nav header, tab-bar scrim on `.tabRoot`, floating coach on `.pushed`, 80 pt bottom inset under floating chrome, pull to refresh, scroll-to-top, `--pulse-scroll` anchors (`.id("pulse.<anchor>")`) |
| `PulseScreenRole` | `.tabRoot`, `.pushed` | A modal root is detected from `\.pulseModalRoot` |
| `PulseCoachAccessory` | `.none`, `.button`, `.pill(summary: String)` | The pill renders `**bold**` markdown |
| `.pulseNavHeader(_:trailing:)` | `(String?, trailing: PulseNavTrailing = .none)` | Centred caps title, system "‹" (swipe-back kept), "✕" at a modal root |
| `PulseNavTrailing` | `.none`, `.info(action)`, `.achievement(symbol:tint:count:action:)`, `.symbol(name, accessibilityLabel:, action:)` | ⓘ 27.5 pt, achievement chip, ⚙ / clock / ? / ••• |
| `PulseBackground` | `(style: .gradient \| .nearBlack)` | Viewport-fixed; put it behind a scroll view |
| `.pulseTabBarScrim()` | | For a tab root that does not use the scaffold |
| `.pulseScrolledPast(_ isPast: Binding<Bool>, threshold: CGFloat = 0)` | | Sticky headers (one per screen) |
| `PulsePlaceholderScreen` | `(name:symbol:summary:spec:group:links:role:coach:)` | The "being rebuilt" screen |

### Surfaces and text

| Component | Signature | Notes |
|---|---|---|
| `PulseCard` | `(_ style: PulseCardStyle = .standard, padding: CGFloat = 16, radius: CGFloat = 12) { content }` | White 10%, 12 pt circular, no border |
| `PulseCardStyle` | `.standard`, `.detail` (4.5%), `.coaching` (7.5%), `.nested`, `.well` (black 50%), `.banner` (black), `.rowCard`, `.outlined`, `.solid(Color)` | |
| `PulseCardSurface` / `.pulseCardBackground(_:radius:)` | | The fill alone, for rows that are buttons |
| `PulseDivider` | `(leadingInset: CGFloat = 0, trailingInset: CGFloat = 0)` | 1 pt white 10% |
| `PulsePressStyle` | `ButtonStyle` | 70% on press, released over 0.15 s |
| `PulseCardTitle` | `(_ title: String, accessory: .none \| .chevron \| .expand \| .info \| .trailingChevron)` | 12 pt Bold caps +0.7 |
| `PulseSectionHeader` | `(_ title: String, count: Int? = nil, style: PulseTextStyle = .sectionTitle, accessory: .none \| .plus(label, action) \| .customize(action) \| .edit(action) \| .viewAll(action) \| .caption(String))` | 20 pt Semibold Title Case |
| `PulseListSectionHeader` | `(_ title: String)` | "ACCOUNT & SETTINGS" + hairline |
| `PulsePlusButton` | `(accessibilityLabel:action:)` | The white "+" square |
| `PulseLabel` | `(_ text: String, color: Color = .textTertiary)` | 11 pt Bold caps |
| `PulseValueText` | `(value:unit:style:unitStyle:color:unitColor:)` | Number + smaller baseline-aligned unit |
| `PulseChevron` | `(color:size:)` | "›" 13 pt, 50% |

### Dials (spec §2.5)

| Component | Signature | Notes |
|---|---|---|
| `PulseDialContent` | `.percent(label:percent:color:caption:)`, `.strain(label:value:optimalRange:target:color:caption:)`, or the memberwise init | `--` placeholder, band and tick as fractions |
| `PulseScoreDial` | `(content: PulseDialContent, reservesCaption: Bool = false)` | 88 / 6, "LABEL ›" 12 pt below; wrap in a link with `.buttonStyle(PulseDialButtonStyle())` for the press disc |
| `PulseHeroRing` | `(content:diameter:thickness:) { accessory }` | 260 / 15, ZENO mark, 58 + 32 pt score, label, optional accessory (e.g. `PulseMiniSegments`) |
| `PulseMiniRing`, `PulseMiniRingRow` | `PulseMiniRingRow(items: [.init(id:content:action:)])` | 24 / 2 sticky header |
| `PulseRing` | `(fraction:color:diameter:thickness:band:tick:trackColor:)` | Any size; sweeps only on value change |
| `PulseRingSegment`, `PulseRingTick` | `Shape`s | Flat ends rounded by `cornerRadius` |
| `PulseDialData.dialContent(target:label:)` | Model mapping | Band and tick only when Recovery scored for the day |

### Rows, trends, status

| Component | Signature |
|---|---|
| `PulseListRow` | `(symbol: String? = nil, title:, subtitle: String? = nil, trailing: .chevron \| .none \| .value(String) \| .toggle(Binding<Bool>), titleColor:)` |
| `PulseMetricRow` | `(symbol:title:value:unit:trend:baseline:)`; no value = label + "›" |
| `PulseActivityRow` | `(chip: PulseActivityChip, name:, start:, end:, barColor:, dottedBar:)` |
| `PulseActivityChip` | `(kind: .sleep \| .strain \| .recovery \| .unscoredSleep \| .pending \| .preAdded, symbol:, value:)` |
| `PulseSubtitleRowCard` | `(symbol:title:subtitle:)` |
| `PulseTrend` | `(direction: .up \| .down \| .flat, polarity: PulseMetricPolarity)` or `(delta:polarity:)`; `.judgement`, `.color` |
| `PulseMetricPolarity` | `.higherIsBetter`, `.lowerIsBetter`, `.neutral`; `.forMetric(key)` holds the spec's table |
| `PulseTrendGlyph` | `(trend:size:)`: ▲▼ teal/orange by good/bad, grey ● when unchanged |
| `PulseDeltaChip` | `(text:trend:)`: green / amber / grey chips, radius 4 |
| `PulseStatusBadge` | `(_ content: .check \| .alert \| .pending \| .value(String), tint: PulseTheme.Tint, size: 24)` |
| `PulseStatusChip` | `(_ text:, kind: .positive \| .negative \| .neutral)` |
| `PulseTag` | `(_ text:, outlined: Bool = false)` |
| `PulseMiniSegments` | `(active: Int?)` 0 Poor / 1 Sufficient / 2 Optimal; `PulseSleepBand.index(percent:)` maps sleep percents |
| `PulseAchievementChip` | `(symbol:tint:count:)` |
| `PulseFilterChip` | `(title:isSelected:action:)` |
| `PulseStatusBanner` | `(_ kind: .caughtUp(syncedTo:) \| .catchingUp(progress:) \| .offWrist \| .lowBattery(percent:), onDismiss:)` |

### Callouts and controls

| Component | Signature |
|---|---|
| `PulseCallout` | `(notchPosition: CGFloat = 0.5) { rows }`: radial glow, top-lit stroke, 15 × 7 pointer |
| `PulseCalloutRow` | `(symbol:title:value:unit:baseline:trend:segments:)`, 53 pt pitch |
| `PulseLegendWell` | `{ content }`; `PulseLegendTodayVsBaseline(period:)`, `PulseLegendPoorSufficientOptimal()` |
| `PulseNotchedWell` | `(notchPosition:) { PulseNotchedWellRow(swatch:title:value:) }` |
| `PulseNotchedRectangle` | `Shape(cornerRadius:notchWidth:notchHeight:notchPosition:)` |
| `PulseSegmentedControl` | `(options: [Value], selection: Binding<Value>, style: .well \| .underline) { title }` |
| `PulseRange` | `.week`, `.month`, `.sixMonths`, `.year`, `.all` (`title`, `days`) |
| `PulseDayPager` | `(title:canGoBack:canGoForward:onBack:onForward:onTitleTap:)` |
| `PulseRangePager` | `(title:canGoBack:canGoForward:onBack:onForward:)` |
| Buttons | `.buttonStyle(.pulseNested)`, `.pulseOutline(color)`, `.pulseOutlineWhite`, `.pulseFilledWhite`, `.pulseFilledBlue`; `PulseTextCTA(title:tint: .ai \| .color(c), action:)` |

### Charts (Swift Charts, spec §2.7)

| Component | Signature |
|---|---|
| `PulseChartDatum` | `(id:label:sublabel:value:color:valueLabel:)`; `value: nil` is a gap, never zero |
| `PulseChartCard` | `(_ title:, accessory:, style:) { chart }` |
| `PulseBarChart` | `(data:yDomain:gridValues:gridlineCount:showsYAxisLabels:highlightID:barWidth:height:emptyMessage:)` |
| `PulseLineChart` | `(data:color:typicalRange:average:yDomain:gridlineCount:showsYAxisLabels:highlightID:showsArea:showsValueLabels:height:emptyMessage:)` |
| `PulseStackedBarChart` | `(columns: [Column(id:label:sublabel:segments:totalLabel:)], yDomain:, gridlineCount:, highlightID:, barWidth:, height:)` |
| `PulseChartAxis` | `gridValues(_:count:)`, `zeroBased(_:)`, `dynamic(_:)` |
| `PulseHatchedTrack` | `(color:spacing:cornerRadius:)` |

### Shell pieces screens may use

| Component | Signature |
|---|---|
| `PulseLink` | `(_ route: PulseRoute) { label }` |
| `\.pulseNavigator` | `open`, `push`, `present`, `quickAction` |
| `\.pulseCoach` | `availability`, `open(seed)` |
| `PulseCoachButton` | `(size: 64, action:)` |
| `PulseCoachSummaryPill` | `(summary:onExpand:)` |
| `PulseCoachAnalyzingPill` | `()` |
| `PulseCoachAvatar`, `PulseZenoWordmark`, `PulseZenoMonogramShape` | ZENO's own marks |
| `PulseStrapChip(action:)`, `PulseStrapGlyph(connected:)`, `PulseLiveHRChip()` | Live strap leaves |

## 7. Theme tokens

- Page: `PulseTheme.pageStops`, `pageTop`, `pageBottom`, `pageNearBlack`, `barStrip`, `scrim`.
- Surfaces: `card` (white 10%), `detail` (4.5%), `nested`, `well`, `gridOnCard`, `gridOnPage`, `dash`,
  `targetBand`, `pressDisc`, `track`, `divider`, `coachingCard`, `coachingPeek`, `bannerWell`,
  `rowCardTop/Bottom`, `rowIcon`, `rowSubline`, `listSectionHeader`, `achievementChip`, `filterChip`,
  `dialogTop/Bottom`, `chartHighlight`, `pagerPill`, `menuTop/Bottom`, `menuDim`, …
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
  `Onboarding`, `TabBar`, `Coach`.
- Type: `PulseTextStyle` cases `heroScore`, `heroUnit`, `dialValue`, `dialUnit`, `sectionTitle`,
  `subsectionTitle`, `tileValue`, `tileUnit`, `rowValue`, `body`, `pillTitle`, `cardTitle`, `secondary`,
  `navTitle`, `label`, `baseline`, `axis`, `tabLabel`, plus the spec's new sizes (`largeValue`,
  `activityStrain`, `liveStrain`, `preStartHR`, `strengthTimer`, `trendInsight`, `plannerTime`,
  `mediumValue`, `stressValue`, `streakCount`, `pageTitle`, `levelTitle`, `levelTier`, `achievementCount`,
  `weeklyTrendsTitle`, `onboardingTitle`, `journalQuestion`, `rowText`, `cardHeadline`, `impactValue`,
  `coachingTitle`). Use `.pulseText(style)`; `PulseType.font(style)` and `PulseType.numeral(size)` for a
  fixed `Font`. Numerals are Bold condensed with tabular digits except `heroScore` and `stressValue`.
- Layout: `PulseTheme.Space` (4…40), `Radius` (`card` 12, `control` 10, `well` 8, `toggle` 6, `badge` 4,
  `menu` 20, `dialog` 15, `coachButton` 22), `Layout` (`pageMargin` 16, `gridGap` 12, `stackGap` 16,
  `healthStackGap` 24, `cardPadding` 16, `sectionGap` 32, `headerGap` 12, `floatingChromeInset` 80,
  `scrimHeight` 28, `minTapTarget` 44), `Dial`, `TabBarMetrics`, `Row`.
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
| `--pulse-sheet actions\|coach` | Present the ＋ menu or the Coach sheet |
| `--pulse-scroll <anchor>` | Scroll to `.id("pulse.<anchor>")` once loaded (`myday`, `stats`, `stress`, `journal`, `contributors`, `history`, `stages`, `monitor`, `bottom`, `gallery-charts`, …) |
| `--pulse-day N` / `--pulse-night N` / `--pulse-range 7\|30\|90` | Home N days back / the Sleep dive N nights back / the Recovery history range |
| `--pulse-gallery` | Present the component gallery |
| `-noop.coachEnabled NO` | Coach off for this launch (a UserDefaults launch argument) |

Capture script:

```
Tools/zeno/shoot.sh <sim-udid> <out-dir> <app-path> [--fresh] [--wait N] [target ...]
```

A target is a tab (`home`), a route name (`sleep-planner`), `gallery`, `actions` or `coach-sheet`;
quote it to add launch arguments (`"home --pulse-scroll stats"`). Each shot is written as
`<out-dir>/<target>.png` plus a downscaled `.jpg`. Example:

```
Tools/zeno/shoot.sh 3F6D8EB8-27A5-4842-BAA1-AB85CCDF7242 /tmp/shots \
  "build/DD/Build/Products/Debug-iphonesimulator/NOOP Staging.app" --fresh \
  home "home --pulse-scroll stats" health trends more sleep-dive "home -noop.coachEnabled NO"
```

## 9. Deviations from the spec, and housekeeping

Measured on the reference captures, where they disagree with the spec's numbers:

- **Tab capsule height above the screen edge.** The spec says ≈21 pt; reviews/02 (393 × 852 @3x) shows 29 pt
  and a 2026 Pro Max capture 28 pt, both 5–6 pt below the bottom safe-area edge. Pulse follows the captures
  (`TabBarMetrics.bottomOffset(safeAreaBottom:)`).
- **Coach button fill.** The spec's `#171728 → #121A25` reads darker than every capture; Pulse uses the
  sampled `#2C2B3C → #20252F` with an indigo rim (`PulseTheme.Coach.buttonFill`).
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
