# ZENO inventory: what the app shows today (2026-10-02)

Scope: the iPhone app in `/Users/raghavrathi/Downloads/Whoop-Apps-Handover/noop` (branch `main`, HEAD `023b5673`,
"pulse: read the unified sleep need, stored consistency and the steps resolver", 2026-09-30), version 11.8.0 (428),
home-screen label **ZENO** (`CFBundleDisplayName: ZENO`; the Xcode product is still "NOOP Staging").
This note is the "our side" of the WHOOP comparison. Nothing in the repo was modified.

How this was built:
- Read every file in `StrandiOS/Pulse/*.swift` in full (Root, Home, Recovery, Strain, Sleep, Health, More, ActionSheet,
  Theme, Components, Snapshots, SnapshotBuilder, Model, Demo, SettingsCard) plus `PulseDisplay.swift` (StrandAnalytics).
- Read/grepped the classic screens Pulse links to (`Strand/Screens/*`, `Strand/Liquid/*`), `Strand/App/TabRoute.swift`,
  `StrandiOS/App/RootTabView.swift`, `StrandiOS/App/StrandiOSApp.swift`, `Strand/Data/MetricCatalog.swift`,
  `Strand/Data/SleepFigures.swift`, `Packages/WhoopStore/.../MetricsCache.swift` (DailyMetric), and the headers of every
  engine in `Packages/StrandAnalytics`.
- Viewed all 17 screenshots in `/Users/raghavrathi/Downloads/Whoop-Apps-Handover/screenshots/` (iPhone 16 Pro simulator,
  1206x2622 px = 402x874 pt at 3x, DEBUG `--demo-seed` data, captured 2026-10-01) and sampled pixels with Pillow.
- "Code-confirmed" below means read in source but not visible in any screenshot. Anything neither seen nor read is
  marked UNCONFIRMED.

Image copies for this topic: `/Users/raghavrathi/Downloads/Whoop-Apps-Handover/whoop-reference/images/zeno-inventory/`
(index in section 12).

---------------------------------------------------------------------------------------------------------------------

## 1. Two interfaces, one data layer

ZENO ships TWO complete iPhone shells over the same repository:

| Shell | Switch | Tabs | Look |
|---|---|---|---|
| **Pulse** ("WHOOP-style interface", default ON) | `@AppStorage("pulse.enabled") = true`. More › Interface › "Classic interface" toggle (with a confirmation dialog), or Settings › Interface › "WHOOP-style interface" | Home · Health · Coach (only when AI Coach is on AND a provider is configured) · More | Always dark (forces `.dark` on the whole window, sheets and system bars included), near-black gradient, `PulseTheme` tokens |
| **Classic** (`RootTabView`) | the same toggle off | Today (Liquid Today by default) · Trends · Sleep · Coach (if enabled) · More | `StrandPalette`/`NoopVisualStyle` tokens, day-cycle sky backdrops, follows System/Light/Dark appearance |

Pulse is a presentation layer only. Every number comes from immutable snapshots (`HomeSnapshot`, `RecoverySnapshot`,
`StrainSnapshot`, `SleepSnapshot`, `HealthSnapshot`) built off the main actor by `PulseSnapshotBuilder` (an actor) and
published by `PulseModel` (@Observable). Rebuild triggers: `Repository.refreshSeq` changes, day change, a display
preference change, the scene becoming active, a sheet closing.

Pulse does NOT fork deep screens. Beyond its own three deep dives it pushes or presents the classic screens, which keep
their classic look (see section 8, inconsistencies).

---------------------------------------------------------------------------------------------------------------------

## 2. Navigation structure (Pulse)

```
TabView (native iOS tab bar, background #000000 opaque, tint #00F19F)
├── Home  (SF "house.fill")            NavigationStack(path) – nav bar hidden at root
│   ├── push PulseRoute.score(.sleep|.recovery|.strain)  → PulseSleepView / PulseRecoveryView / PulseStrainView
│   ├── push PulseRoute.workout(row)   → classic WorkoutDetailView (PulseClassicScreen wrapper)
│   ├── push PulseRoute.alarms         → classic SmartAlarmView  ("Tonight" row)
│   ├── push TabRoute.metric(key) / .metricSourced / .steps(day:) / .stress / .sleep  → classic MetricDetailView, StepsView, StressView, SleepView
│   └── sheet PulseCalendarSheet ("Pick a day", graphical DatePicker, .medium/.large detents)
├── Health (SF "heart.text.square.fill") NavigationStack – nav bar hidden at root
│   ├── push TabRoute.metric(...)  (vital rows, Healthspan tiles) → classic MetricDetailView
│   ├── push TabRoute.stress → classic StressView ; TabRoute.steps(day:) → classic StepsView
│   └── push PulseRoute.labBook → classic LabBookView
├── Coach (SF "sparkles")  only if noop.coachEnabled && AICoachEngine.isConfigured → classic CoachView (nav bar hidden)
└── More  (SF "ellipsis")  NavigationStack – system large title "More", inset-grouped List
    └── push PulseMoreDestination.* → 30 classic screens (list in section 3.8)

Shell-level presentation (one .sheet(item:) so two never race):
  .quick(.menu)      → PulseActionSheet "Start" (+ menu)          (from header +, floating +, Home Screen quick actions)
  .quick(.live)      → LiveView            .quick(.workout) → WorkoutsView     .quick(.liftLog) → LiftLogView
  .quick(.intervals) → IntervalTimerView   .quick(.breathe) → BreathingView    .quick(.journal) → InsightsView
  .devices           → DevicesView (strap chip)               .settings → SettingsView (avatar)
  .pillar(dest)      → InsightsHubView / LabBookView / FusedRecordHost / RhythmHost / TrendsView / CoachView / SmartAlarmView
  fullScreenCover    → LiveSessionView ("Guided session", beta)
  LiftSessionBar     → floats above the tab bar on every tab while a gym session runs; its own sheet LiftSessionView
Each presented screen sits in its own NavigationStack with an inline title, hidden nav-bar background and a "Done"
button (accent #00F19F, top-trailing).
```

Tab behaviours (code-confirmed): re-tapping the selected tab refreshes the repository, then pops the stack to root or,
if already at root, scrolls to top. Router requests (`NavRouter`) map: devices → Devices sheet; insightsHub / labBook /
fusedRecord / rhythm / alarms → pillar sheet; coach → Coach tab (or Coach setup sheet when on but unconfigured, dropped
when off); trends → More tab with Trends pushed; activeWorkout → Live sheet; liveSession → Guided session cover;
journal → Journal sheet. Home Screen quick actions (held until onboarding/terms gates clear): "Live heart rate" →
Live, "Start workout" → Workouts, "Log journal" → Journal, "Breathe" → Breathe.

Gestures: Home pull-to-refresh (asks the strap to sync when history is ready, re-reads the store, rebuilds Home);
Home horizontal flick (>50 pt, 1.5x more horizontal than vertical) changes the day (right = older); Health
pull-to-refresh; More pull-to-refresh. Selection haptic on day change. No tab-swipe gesture in Pulse (the classic
shell has one).

DEBUG-only launch flags (useful for re-capturing screenshots): `--pulse-tab home|health|coach|more`,
`--pulse-day N`, `--pulse-night N`, `--pulse-range 7|30|90`, `--pulse-push recovery|strain|sleep`,
`--pulse-sheet actions`, `--pulse-scroll <anchor>` (anchors: myday, stats, stress, journal, contributors, shaped,
history, build, hr, zones, stages, monitor, healthspan, records, advanced, bottom), `--demo-seed`,
`--demo-screen pulsehome|pulserecovery|pulsestrain|pulsesleep|pulsehealth|pulsemore|steps|steps-mid|steps-end|…`.

---------------------------------------------------------------------------------------------------------------------

## 3. Pulse screens, top to bottom

Measurements are from the 3x screenshots (px ÷ 3 = pt). Colours are sampled (see section 7 for the full table).

### 3.1 Home (Today) — screenshots 01, 02, 03 (+ crops 20, 21)

Page: ScrollView, 16 pt side padding (sampled: cards start at x=48 px), 22 pt between sections, near-black vertical
gradient #101518 → #000000 behind, a #101518 band behind the status bar, nav bar hidden. Room left at the bottom
(76 pt) for the floating +. Sections in this exact order; nothing else is on Home:

1. **Header row** (top, ~4 pt below the status bar)
   - Left: profile avatar button, 36 pt circle on #1F272C with a 1 pt #333A3F ring (sampled). With no photo it shows the
     ZENO/NOOP brand mark (green #03E095 ring with a white dot, seen in screenshot 01). Tap → Settings sheet.
   - Right, in order: "Today" chip (only when browsing a past day; filled #00F19F capsule, dark ink #04140E, caption
     semibold), live-HR chip (only while the strap streams: red heart.fill #FF4A5C + bpm, capsule #1F272C),
     strap chip (capsule 44x32 pt, #1F272C fill, #333A3F hairline; battery glyph + "NN%" when known, green bolt when
     charging, red glyph under 15%, "Syncing" + accent arrows while backfilling, antenna-slash with no text when
     offline — the offline state is what the screenshots show), then a 36 pt "+" circle (#1F272C, white plus) →
     + menu. Tap strap chip → Devices sheet.
2. **Day stepper row**: ‹ chevron (44 pt target; dimmed at the earliest banked day) · centred title "Today" /
   "Yesterday" / weekday name ("Monday") in title3 bold (≈20 pt) with a caption subtitle in tertiary grey ("Thu, Oct 1"
   under Today/Yesterday, "Sep 28" under a weekday; year added when not this year) · › chevron (dimmed on Today).
   Tapping the title opens the calendar sheet ("Pick a day", graphical picker from the earliest banked day to today,
   "Done").
3. **Three score dials**, order **Sleep · Recovery · Strain** (left to right), equal widths, 4 pt spacing.
   - Each dial: outer diameter 102 pt (sampled 305 px), 3 pt full-circle track (white 12%, #272829 on the page), 9 pt
     rounded-cap progress arc starting at 12 o'clock clockwise, number centred: SF Pro **condensed bold, monospaced
     digits ≈34 pt**, unit "%" at 45% size semibold in secondary grey (no unit on Strain).
   - Arc colours: Sleep #7BA1BB (always), Recovery by band (#16EC06 ≥67, #FFDE00 34–66, #FF0026 ≤33), Strain #0093E7.
     Calibrating → grey arc.
   - Label under each dial: UPPERCASE tracked caption semibold, secondary grey: "SLEEP", "RECOVERY", "STRAIN". No "›".
   - Optional caption line under the label (caption2, tertiary, 2 lines max): "Calibrating" or a carried score's
     source ("Last night · <date>" / "Latest sleep · <date>").
   - Centre states: value; "–" (no data); "n/4" over "nights" (Recovery calibrating; baseline needs 4 nights).
   - Arc fills once on appear (0.9 s ease-out) and eases on change (0.35 s); skipped with Reduce Motion.
   - Tap a dial → its deep dive (3.3–3.5).
   - Screenshot 01 values: 97% / 58% / 12.6.
4. **Strain Target card** (only when a Recovery value exists). Card = #161C20 fill, 1 pt #2B3034 border, 18 pt continuous
   corners, 16 pt padding.
   - Row 1: "STRAIN TARGET" (uppercase label, secondary) … trailing "Today 12.6" (today) or "Strain 9.9" (past day).
   - Row 2: intent word in title3 bold coloured by the Recovery band ("Restore" red-text #FF4A5C / "Maintain" #FFDE00 /
     "Push" green) + range in condensed numerals 22 pt ("10.0–14.0"). Bands: Recovery ≥67 → Push 14–18;
     34–66 → Maintain 10–14; <34 → Restore 4–10.
   - Row 3: 0–21 bar, rendered 16 pt tall (sampled 48 px): empty track #32373B, day-so-far fill #0093E7 capsule, white
     knob 16 pt at the current strain, recommended range drawn as strain-blue 30% (#23536F) with a 1 pt #0786CF outline.
   - Row 4: "0" … progress text ("In the range" / "0.1 below the range" / "1.2 above the range" / "No strain logged
     yet") … "21" (caption/caption2 tertiary).
   - Optional: "Based on your last scored Recovery." when the Recovery was carried.
5. **MY DAY** (section label, then one grouped card with 1 pt hairline dividers inset 62 pt). Rows (min 60 pt, 36 pt
   round icon on #1F272C, title subheadline semibold, subtitle caption tertiary, trailing value in condensed 20 pt with
   a caption2 under it, chevron):
   - "Last night's sleep" (past days: "Sleep"), moon.fill #7BA1BB, "11:15 PM – 6:28 AM", value "6h 49m", caption
     "97% Sleep" → Sleep dive.
   - "Nap" rows, powersleep icon, start – end, asleep duration → Sleep dive.
   - Workout rows, sport icon in #0093E7, title = sport name, subtitle "7:12 AM · 45 min", value = workout strain in
     #0093E7 ("8.4"), caption "Strain" → classic WorkoutDetailView. (No workouts in the demo data, not seen.)
   - "Tonight" (today only), bed.double.fill, three-line subtitle "Asleep by 8:24 PM" / "Wake 6:53 AM" (suffix
     " (default)" when no alarm and fewer than 3 recent nights; wake = wind-down alarm time, else the median wake of the
     last 14 nights, else 07:00) / "+1h 58m debt · +32m strain" (also "−Xm nap"; terms under 5 min hidden), value
     "10h 29m", caption "sleep need" → classic Alarms screen.
   - Empty state: "Nothing logged yet" / "Start an activity or wear your strap to sleep" with an accent + icon → + menu.
6. **KEY STATS** (label) with trailing "vs 30-day avg". Two-column grid, 12 pt gaps; an odd last tile spans the full
   width. Tile: #161C20 card, 14 pt padding, min height 148 pt (sampled 444 px), 179 pt wide.
   - Top: tiny SF icon (caption2, tertiary) + UPPERCASE label.
   - Value: condensed bold 30 pt + unit (caption semibold, tertiary).
   - Comparison line: ▲/▼ (8 pt) or "–" + text in caption semibold #C3C4C5: "45%" / "Steady" / "+0.4 Δ°C"; or "So far
     today" (today's steps and calories); or "Building average" (<5 days of history) / "No data".
   - Optional carried caption ("Last night · <date>") when the value is from an earlier night.
   - 22 pt sparkline at the bottom: last 14 calendar days, 1.5 pt line in secondary grey at 70% (#8C8F91), 5 pt dot on
     the latest point.
   - Tiles in order (screenshot 02 values): **HRV** (waveform.path.ecg) "111 ms ▲45%"; **Resting HR** (heart.fill)
     "57 bpm – Steady"; **Respiratory rate** (lungs.fill) "13.6 rpm ▼8%"; **Skin temp** (thermometer.medium) "+0.4 Δ°C
     ▲ +0.4 Δ°C" (deviation from baseline preferred; absolute °C vs its 30-day mean as fallback); **Blood Oxygen**
     (drop.fill; ONLY when a real % exists from an import/Apple Health) "95% ▼1%"; **Steps** (figure.walk) "2,591 So far
     today"; **Calories** (flame.fill; Apple Health active energy first, else on-device HR estimate) "529 kcal So far
     today" (full width).
   - Tap → classic metric detail (`MetricDetailView`) for that metric; Steps → classic Steps screen for that day.
7. **STRESS** (label) with trailing "Today" (today only). Card:
   - "0.2" condensed 36 pt + "/ 3" condensed 16 pt tertiary + band chip "Low" (#1F272C capsule, #C5C7C8 text)
     + chevron → classic StressView. Bands: Low <1.0, Medium <2.0, High ≥2.0.
   - Hourly curve (today only) = the classic `DaytimeLoadLine`: 2.5 pt line whose colour runs along the stress ramp
     (green #07E095 at low, amber #DCAE42 at the peak in the demo), faint green area fill, dashed hairline baseline.
     Empty: "The hourly curve fills in as your strap records heart rate through the day."
   - Full-width "Breathe" button (wind icon): capsule #1F272C fill, #00F19F text, 1 pt accent-35% border (#146D54)
     → Breathe sheet.
   - Past days: shown only if a stored stress value exists, no curve.
8. **JOURNAL** (today only, and only while Settings' journal reminder is on). Card:
   - Row: book.closed.fill (accent) + "Log today's journal" / "Tap a day to catch up" / "Logged today" + chevron → opens
     the journal (classic InsightsView sheet).
   - 7-day strip (oldest → today): bars 43 pt wide x 10 pt tall, radius 3, 6 pt gaps; logged = #00F19F fill; not logged
     = #32373B; today unlogged = track with a 1 pt accent outline; one-letter weekday under each (today white, others
     tertiary). Tapping a bar opens that day's journal.
9. **Floating + button**: 56 pt circle #00F19F, bold plus in #04140E, shadow black 45% r10 y4, centred 10 pt above the
   tab bar, always on top of Home (and Health) content → + menu.
10. **Tab bar**: black (#000000) native bar, items Home / Health / More (+ Coach when configured), selected #00F19F,
    unselected #7C7C7C (sampled). No hairline above the bar was visible.

Loading state: three "–" dials and a spinner. While a newly picked day builds, the old day's content dims to 45%.

### 3.2 Home (a past day) — screenshot 04

Same layout with: "Today" chip in the header (jumps back), title = weekday ("Monday") + "Sep 28", both chevrons active,
dials for that day (93% / 35% / 9.9), Strain Target trailing "Strain 9.9" and "0.1 below the range", My Day row
titled "Sleep" (no Tonight row), no Journal section, no Stress curve. Today's values are never mixed in.

### 3.3 + menu "Start" sheet — screenshot 05

Sheet at .medium (expandable to .large) with a drag indicator, title "Start" (inline), "Done" (accent). The rows are
separate cards (#161C20, 14 pt radius), each a `PulseRow` with a coloured icon and chevron:
1. "Start workout" — "GPS or manual, with live heart rate" (figure.run, #0093E7) → Workouts screen (classic log with a
   "Start workout" button inside, not a direct start).
2. "Lift session" — "Sets, reps and rest on the strap" (dumbbell.fill, blue) → Lift Log.
3. "Intervals" — "Work and rest timer" (timer, blue) → Interval Timer.
4. "Guided session" — "Silent strap coaching against today's Recovery · beta" (shield.lefthalf.filled, blue; hidden when
   the beta switch is off) → full-screen Live Session.
5. "Live HR" — "Your heart rate, beat by beat" (waveform.path.ecg, #FF4A5C) → Live.
6. "Breathe" — "A few slow minutes" (wind, #7BA1BB) → Breathe.
7. "Log journal" — "Today's behaviours and notes" (square.and.pencil, accent) → Journal. (code-confirmed; cut off in
   the screenshot)
8. "Mark moment" — "Pin this minute to your timeline" (mappin.and.ellipse; acts in place, success haptic, becomes
   "Moment marked" / "At 9:41 AM" with a green check). (code-confirmed)

### 3.4 Recovery deep dive — screenshots 06, 07 (+ crops 22, 23)

Pushed page. Nav bar: system back "‹ Back" in #00F19F; centred principal title "Recovery" (headline) with the day
caption under it ("Today, Thu, Oct 1", caption2 tertiary); bar is clear at rest and takes #101518 when content scrolls
under it. Content padding 16 pt, sections 22 pt apart:
1. **Hero**: dial 196 pt (sampled 588 px), 14 pt arc, numeral ≈64 pt condensed bold, "%" smaller; under it a band chip
   ("Green"/"Yellow"/"Red" in band text colour on #1F272C) + a line: "Ready to push" / "Maintain today" / "Prioritise
   recovery". Carried: "No score for this day yet. Showing Last night · <date>." No data: "No Recovery for this day. It
   scores from a night of overnight HRV."
2. **Calibration card** (only while calibrating): "BUILDING YOUR BASELINE", progress headline, 4-segment bar (green),
   explanation ("Recovery compares each night's heart rate variability, resting heart rate and breathing with your own
   baseline. That baseline needs 4 nights of overnight wear before the first score…"), optional restart cause.
3. **CONTRIBUTORS** (trailing = the day the score came from, "Oct 1"). Grouped card, rows (min 60 pt) with title +
   grey caption on the left, condensed 22 pt value + unit and a ▲/▼ % line on the right, chevron → metric detail:
   - "Heart rate variability" 111 ms, "Baseline 77 ms", ▲44% (vs the recovery engine's learned baseline)
   - "Resting heart rate" 57 bpm, "Baseline 56 bpm", ▲2%
   - "Respiratory rate" 13.6 rpm, "Baseline 14.7 rpm", ▼7%
   - "Sleep" 97 %, "30-day avg 93%", ▲4% (no learned baseline → 30-day mean)
   ("Near baseline" replaces the % when the printed figures are equal.)
4. **CONTEXT**: "Skin temperature" +0.4 Δ°C "vs your baseline" (deviation only); "Blood oxygen" % vs 30-day avg (only
   when a real % exists; the row is cut off at the bottom of screenshot 06, code-confirmed).
5. **WHAT SHAPED IT** + confidence chip "Reliable" (accent) / "Estimate" / "Calibrating". Card of the CLASSIC
   `ChargeDriverRow`s, one per engine term: "Heart rate variability", "Resting heart rate", "Sleep quality",
   "Respiratory rate", "Skin temperature". Each: title + points chip ("+1 pt" green #0F9D62 on #152D29, "-1 pt" red
   #C0392B on #2E2022, "0 pts" grey #7D7F88 on #23292D), "57 bpm · 56 bpm baseline", a 16-segment pip bar (filled pink
   #D5A19E / mint for positive, empty #23252C), verdict ("above baseline, limiting recovery", "below baseline,
   supporting recovery", "near baseline"). Hidden when the night cannot honestly score. (Only the RHR/Resp/Skin rows are
   visible in screenshot 07; the header and HRV/Sleep rows are code-confirmed.)
6. **HISTORY**: segmented control "7 days | 30 days | 90 days" (default 30; system segmented style, #2D3137), bar chart
   170 pt tall, one bar per calendar day (gaps for unscored days), bars in band colours (#16EC06/#FFDE00/#FF0026,
   corner radius 2), trailing y axis 0/33/67/100 with hairline grid, date ticks every 2 days/weekly/3 weeks; legend
   dots "67–100", "34–66", "0–33" + "Avg 40%" right-aligned. Empty: "Not enough scored days yet."

### 3.5 Strain deep dive — screenshots 08, 09

Nav: "Back", title "Strain", day caption. Sections:
1. Dial 196 pt / 14 pt arc #0093E7, "12.6" condensed ≈64 pt, caption "of 21" under it.
2. Strain Target card (same as Home).
3. **THROUGH THE DAY**: Swift Charts area+line, 170 pt: cumulative strain every 15 min through the same scorer as the
   headline (monotone, 2.5 pt #0093E7 line, gradient area 35%→2%), target range shaded (strain 14%), dashed rule at the
   day total when the stored day strain runs ahead of the HR curve, caption "Dashed: the day's strain of 12.6, which can
   include load this heart-rate trace does not show, such as a logged workout." Trailing y axis 0/7/14/21; x ticks every
   3 h ("12 AM, 3 AM, 6 AM, 9 AM"). Empty: "Strain builds here as your strap records heart rate through the day."
4. **HEART RATE** (trailing "Peak 158 bpm"): 190 pt chart, 5-minute HR means as a white 1.6 pt line broken at wear gaps,
   five horizontal zone bands shaded at 10% (#7E8A94, #0093E7, #16C47F, #FFB020, #FF4A5C), y labels at the zone lower
   bounds (122, 135, 148, 161, 174 in the demo). Empty: "No heart rate recorded for this day."
5. **TIME IN ZONES**: five rows "Zone 1…Zone 5" (caption semibold) + 8 pt capsule bar scaled to the largest zone +
   duration ("9m", "13m", "23m", "0m", "0m"); footer "Zones from your max heart rate of 187 bpm."
6. Three mini stat cards in a row: "CALORIES 529 kcal", "AVG HR 67 bpm", "PEAK HR 158 bpm" (label + condensed 24 pt).
7. **ACTIVITIES**: workout rows (title, "7:12 AM · 45 min · 412 kcal", strain value in blue) → WorkoutDetailView; empty
   "No activities" / "Logged and auto-detected workouts appear here" (figure.run, tertiary).

### 3.6 Sleep deep dive — screenshots 10, 11

Nav: "Back", title "Sleep", caption "Night ending Thu, Oct 1". Opens on the night that ended on Home's day; ‹ › step
night by night and rebuild everything on the screen.
1. **Night navigator** card (14 pt radius): ‹ · "Latest night" (or "Wednesday, 30 Sep" style for older nights) over
   "11:15 PM – 6:28 AM" · ›.
2. Dial 184 pt / 14 pt arc #7BA1BB, "97%"; line "6h 49m asleep · 7h 2m needed" (subheadline medium, secondary).
3. **CONTRIBUTORS** card, four labelled bars (6 pt, #7BA1BB on track, value in condensed 20 pt):
   "Hours vs needed 97%" ("6h 49m of 7h 2m"), "Efficiency 97%" ("7h 3m in bed"), "Consistency 84%" ("Bed and wake
   times"), "Restorative 46%" ("Deep and REM share").
4. **STAGES** (trailing "7h 3m in bed"): classic `Hypnogram` (150 pt, stage rows Awake/REM/Light/Deep, time axis
   "11:15 PM · 2:46 AM · 6:18 AM") drawn in the Oura stage palette (Awake #EAE3D3, REM #90D0F0, Light #40B0E0, Deep
   #206080), then stage rows with a 12 pt swatch: "Awake 14m 3%", "Light 3h 43m 53%", "Deep 1h 28m 21%", "REM 1h 38m
   23%". Fallbacks: stage rows only; or "This night has no stage data."
5. Three mini stats: "SLEEPING HR 58 bpm", "LOWEST HR 52 bpm", "BREATHING 13.6 rpm".
6. **NAPS** (only when present): rows "Nap", start – end, duration.
7. Full-width outline button "Open the full Sleep screen" (bed.double) → classic SleepView.

### 3.7 Health tab — screenshots 12, 13

Always "now" (ignores Home's selected day). No nav bar; a custom large title "Health" (largeTitle bold ≈34 pt) at the
top of the scroll; pull-to-refresh; floating + at the bottom.
1. **HEALTH MONITOR** (trailing "4 of 5 in range" / "No readings yet"). Grouped card, one row per vital, in this order:
   "Respiratory rate", "Blood oxygen" (only with a real value), "Resting heart rate", "Heart rate variability",
   "Skin temperature". Each row: status icon 36 pt frame (checkmark.circle.fill #00F19F in range;
   exclamationmark.circle.fill #FFDE00 out of range; minus.circle tertiary no data), title (subheadline semibold),
   value condensed 20 pt + unit, a range bar (4 pt track #32373B, typical range white 28% #6A6D70, 12 pt marker dot in
   the status colour with a 2 pt #101518 ring), footer "Your typical range 13.2–16.4" (personal baseline ±k·σ once
   trusted) or "Typical adult range 95–100" + the day label ("Today"), chevron → metric detail. Screenshot: HRV 111 ms is
   flagged yellow (range 51–101).
2. **STRESS** — the same card as Home (today).
3. **HEALTHSPAN** (trailing "Weekly"): 2x2 tiles (min 96 pt): "BODY AGE 30 yrs" (figure.stand), "FITNESS AGE 34 yrs"
   (figure.run; shown with ≤/≥ when clamped), "VO₂ MAX 52.0 ml/kg/min" (lungs.fill), "VITALITY 80 / 100" (sparkles).
   Empty: "–" + "Needs a few weeks of wear". Tap → metric detail.
4. **Menstrual cycle card** (classic `MenstrualCycleHomeCard`, only when the profile applies, cycle awareness is on, or
   period starts were logged): "Menstrual Cycle", "Private, on-device tracking", phase (Follicular / Mid-cycle shift /
   Luteal / No clear pattern / Learning your pattern), "~day N". Not in the screenshots (demo profile does not apply).
5. **RECORDS**: "Steps" — "Today and your trend", value "2,591" (figure.walk, accent) → classic Steps screen; "Lab Book"
   — "Your private health records" (books.vertical.fill, accent) → classic LabBookView.

### 3.8 More tab — screenshot 14 (top only)

System large title "More", `.insetGrouped` List on the Pulse gradient; rows 44 pt on #161C20, SF icon in #00F19F
(28 pt column), body text white, system chevrons. Section headers are Pulse uppercase labels. Full list (code-confirmed;
the screenshot shows down to "Live"):
- **PERFORMANCE**: Trends (chart.line.uptrend.xyaxis) · Weekly digest (calendar) · Report (doc.richtext → sheet
  `TrendsReportSheet`)
- **INSIGHTS**: What moves you (wand.and.sparkles → InsightsHubView) · Explore (square.grid.2x2.fill → MetricExplorer) ·
  Compare (rectangle.split.2x1.fill) · Journal (square.and.pencil → InsightsView) · Set up AI Coach (sparkles; only when
  Coach is on but unconfigured)
- **ACTIVITY**: Workouts (figure.run) · Lift Log (dumbbell.fill) · Live (waveform.path.ecg) · Breathe (wind) ·
  Intervals (timer)
- **STRAP & ALARMS**: Devices (sensor.tag.radiowaves.forward.fill) · Alarms (alarm.fill)
- **DATA**: Data Sources (externaldrive.fill) · Apple Health (heart.fill) · Backup & Sync
  (externaldrive.fill.badge.icloud) · Shortcuts Export (square.and.arrow.up.fill)
- **SETTINGS**: Settings (gearshape.fill)
- **ADVANCED**: Test Centre (stethoscope) · Limitations (list.bullet.rectangle) · Mi Band (figure.walk.motion) · Rhythm
  (waveform.path) · Intelligence (brain.head.profile) · Your Data, Fused (square.stack.3d.up.fill) · Automations
  (wand.and.stars) · Power saving (battery.25) · Siri & Shortcuts (mic.fill) · Classic Health (heart.text.square)
- **INTERFACE**: toggle "Classic interface" (rectangle.stack) → confirmation dialog "Switch to the classic interface?"
  / "Your data and settings stay as they are. You can switch back from Settings." / "Switch" · "Cancel"; footer
  "Switches to the classic tabs. Settings › WHOOP-style interface brings this one back."

Not in the Pulse More list (but defined as destinations): Stress, Lab Book (reached from Home/Health instead). Steps is
under Health › Records. **Hydration and the "Coupled view" have no entry point in Pulse at all** (only the classic
Liquid Today's cards reach them).

### 3.9 Coach tab (conditional, code-confirmed, no screenshot)

Appears only when `noop.coachEnabled` (default true) AND a provider is configured. Renders the classic `CoachView`
(classic chrome, nav bar hidden): chat thread, empty-state suggestions "How's my charge trending?", "What should
today's training look like?", "Analyse my sleep", "Why am I run down?", provider setup ("Connect a provider",
Provider: OpenAI / Anthropic / Google Gemini / Custom (OpenAI-compatible, e.g. Ollama/LM Studio on localhost or LAN),
API key, Model, Server URL, Key header), token estimate, voice input (CoachVoiceInput). Defaults: gpt-5-mini,
claude-sonnet-5-5, gemini-flash-latest.

---------------------------------------------------------------------------------------------------------------------

## 4. Classic screens Pulse reaches (they keep the classic look)

Wrapper: `PulseClassicScreen` / `sheetScreen` = classic canvas `StrandPalette.surfaceBase` (#1D1E23 dark) behind,
inline title, transparent nav bar. Most classic screens draw a day-cycle "liquid sky" band or full-bleed sky behind
their cards (`LiquidSkyStatic`), use `NoopCard`/`NoopPanelSurface` cards (#2A2C34–#30323B gradient, radius 22 pt,
#373A44 border), SF Rounded headline numbers, and the classic accent (mint #69DDB8 by default).

| Screen | Reached from (Pulse) | Sections (top → bottom, from code; screenshot where noted) |
|---|---|---|
| **MetricDetailView** (title = catalog name, e.g. "Heart Rate Variability", "Rest", "VO₂ Max (estimated)") | Key Stats tiles, Recovery contributor/context rows, Health Monitor rows, Healthspan tiles | Range pills W/2W/3W/M/3M/6M/1Y/ALL (longer ranges locked until enough history) · hero (ring gauge for 0–100 scores, else big SF-Rounded value + "as of <date>") · hero chart (line or bar per Trends preference; personal-baseline rule for HRV/RHR once trusted) · optional skin-temp note · stat row Average / Min / Max / Latest / Δ vs previous window · readings table with per-day source · "What correlates" (Pearson scan |r|≥0.30, top 6). Fitness Age empty state has "Refresh Fitness Age". Sky backdrop. |
| **StepsView** "Steps" / "Today" | Key Stats Steps tile, Health › Records › Steps | Screenshots 15–16: ring card "2,591" of 10,000 steps · 25%, source chip "iPhone", Distance 1.9 km / Floors 3 / To goal 7,409 · "BY HOUR" bars ("Busiest 8 AM") · "LAST 7 DAYS" bars with dashed 10k goal ("Avg 9,739") · "LAST 30 DAYS" ("Avg 9,699") · "STREAK 5 days — In a row at your goal" + "BEST DAY 16,069 Aug 12" · "DAILY GOAL 10,000 steps" with −/+ stepper + "Notify me when I reach it" toggle ("Once a day. It can arrive late if ZENO was closed.") · "HOW STEPS ARE COUNTED" explainer. Sampled: page #1D1F24, cards #2C3036–#30343F, ring cyan #3FA8C7, numbers #F7F7FA (SF Rounded). |
| **StressView** "Stress" | Stress card (Home, Health) | Stress monitor gauge 0–3 with LOW/MEDIUM/HIGH + "why" line · "Today" markers (stress, RHR, HRV vs 30-day baseline, calm time) · "Today's Timeline" autonomic load through the day (hours excluded while moving) · "Stress Trend" (ranges) · "Advanced HRV" (Baevsky Stress Index, LF/HF parasympathetic band) · "How this is computed". |
| **SleepView** (classic Sleep tab) | "Open the full Sleep screen" | Hero (hours of sleep, sleep score word Poor/Fair/Good/Optimal, source Whoop/Oura/On-device), stage breakdown (tap a stage to compare with 30-day typical), sleeping HR through the night, movement, "Why this sleep?", edit sleep/wake times, delete + undo, "Add a nap", Sleep marks (tap at bed/wake), then reorderable cards: Body clock, Night detail tiles, Sleep-debt ledger, Stages vs typical, Asleep duration (30 nights). |
| **WorkoutDetailView** (title = sport, "Done") | My Day / Activities workout rows | HEART RATE chart · "Effort" / "This session" (shown on the user's Effort scale, default **0–100**, "of 100") · "HR Zones" · "Heart Rate Recovery" / "After high-intensity effort" (1/2/5 min) · "Route" (GPS map when recorded, export "GPX — Strava, Garmin, most apps" / "FIT — Garmin Connect"). Editing/relabelling lives in the Workouts log (ManualWorkoutSheet), not here. |
| **SmartAlarmView** "Alarms" | My Day "Tonight" row; More › Alarms | Strap wake-alarm ("Wake me with a strap buzz", "Wake at", silent buzz note, "Check what the strap has stored") · "Wind-down nudge" ("Remind me to wind down", "Your usual wake time", "Different wake time per day") · Tonight / Morning / Evening blocks. |
| **LabBookView** "Lab Book" | Health › Records | "A private notebook, not a medical service." · Import readings · Trend · History · "Compare with a signal". |
| **InsightsView** "Insights" (Pulse calls it "Journal") | Home Journal card, + › Log journal, More › Journal | First: Journal log card (yes/no + numeric questions; starter set: alcohol, late caffeine, screen in bed, late meal, stressed, sauna, shared bed, sick, magnesium, read before bed; groups Nutrition/Supplements/Lifestyle/Health/Behaviour/Other), Mind (mood 1–5 check-in), Caffeine log. Then analysis sections "Personal Experiment", "Behaviour Effects" (Cohen's d, significance pills), "Activity Cost" (per-sport Charge dip/bounce-back), "Metric Relationships" (Pearson r) and a "WHAT MOVES YOU ›" link (relative order of the analysis sections not verified). |
| **InsightsHubView** "Insights" (row "What moves you") | More | "What moves your <outcome>" ranked effects · "Dose-response" · "How to read this" ("association, not cause"). |
| **TrendsView** "Trends" | More › Trends | Range W/M/3M/6M/1Y/ALL · hero Charge chart · "Daily signals" (HRV, Resting HR, Effort small multiples) · Charge year heat-strip (Depleted→Peaked) · Training load card (CTL/ATL/TSB) · "Week in review" · "Export trends report". Labels say Charge/Effort/Rest and Effort is 0–100 by default. |
| WeeklyDigestView "Week in review" | More › Weekly digest | Monday–Sunday summary per metric, week-over-week deltas. |
| TrendsReportSheet ("Report") | More › Report | "Metrics" + "What changed" report, exportable. |
| MetricExplorerView "Explore" | More › Explore | Full-day full-resolution HR timeline link (FullDayChartView) on top, then every catalog metric by category (Heart/Charge/Rest/Effort/Health/Nutrition/Mind). |
| CompareView "Compare" | More › Compare | "Metrics" picker (2–4) · "Overlay" normalized chart · "How They Move Together" (Pearson r per pair). |
| WorkoutsView "Workouts" | + › Start workout, More › Workouts | "Start workout" control · summary tiles · "Effort this <range>" · "Active calories" heatmap (13 weeks) · "Activity Breakdown" · "HR Zones" · "Recovery Trend" · "All Sessions" (source badges). |
| LiftLogView "Lift Log" | + › Lift session, More | "Your log book" · Programs (import/edit) · Sessions · "Sets per muscle"; live session view with strap rest timer + Lift Live Activity. |
| LiveView "Live Body Console" | + › Live HR, More › Live | Live HR (smoothed) + ZONE, R-R list, RMSSD, LIVE PHYSIOLOGY, HRV snapshot (spot reading), "Signal Trust", "Session", STRAP LOG, "Manage devices", standard HR mode note. |
| BreathingView "Breathe" | Stress card button, + › Breathe, More | Protocol pills (Relax 4-6, Coherence 5.5, Box, 4-7-8, Buteyko, Wim Hof, Presence…), session length, "Find your resonance pace" (RSA sweep), "Your locked pace", "Calm me", audio cues, live HR/RMSSD, "Coherence estimate", strap haptic pacing (1 buzz inhale, 2 exhale), stress check-in card. |
| IntervalTimerView "Interval Timer" | + › Intervals, More | Configure work/rest/rounds · stage face WORK/REST/DONE · ROUND · session progress · strap buzz cues. |
| LiveSessionView "Live Session" (BETA) | + › Guided session | "SILENT GUARDIAN": one ring, "Guarding your session. Silence means you're on track.", band state In band / Below band / Above band, long-press reveals HR, "Session summary" with "Cues sent" and a verdict line. |
| DevicesView "Devices" | strap chip, More › Devices | Device cards (WHOOP 4.0 / 5.0 / MG, experimental Oura "A locally-adopted Oura ring, in beta."), battery, a capability list per device with "* on-device estimate" footnotes, active-device switching, add-device wizard ("Getting your devices ready"). |
| SettingsView "Settings" (subtitle still says "how NOOP works") | avatar, More › Settings | Profile · Units · Appearance (theme presets Mint/Ocean/Classic/Midnight/Frosted, accent Mint/WHOOP Blue/Custom, chart style, backdrop, app icon) · Interface ("WHOOP-style interface" toggle) · Strap · Live notifications · Streak · Features · Sync · Advanced (Recovery, HRV, Test Centre, Experimental: Liquid Today / Live Sessions / Sleep staging / Blood Oxygen / Oura all-day HR, Diagnostics, Backup & restore) · About. |
| DataSourcesView, AppleHealthView, BackupSyncView, ShortcutExportSettingsView | More › Data | WHOOP CSV export import, Apple Health export import, Nutrition CSV, Mi Band, strap status; Apple Health page (Heart & Vitals, Activity & Energy, Body Composition, Sleep); backup/sync folder; HealthKit-free Shortcuts export. |
| TestCentreView, NoopLimitationsView, XiaomiBandView, RhythmHost, IntelligenceView, FusedRecordHost, AutomationsView, PowerSavingView, SiriShortcutsSettingsView, HealthView ("Classic Health") | More › Advanced | Diagnostics/bug report; 4.0 vs 5.0/MG capability grid; Mi Band import; Rhythm (Poincaré, experimental, non-diagnostic); Intelligence ("Tomorrow's Charge" forecast, "Charge model", "By Day"); multi-source fused record; Automations (double-tap, wear & presence, haptic coaching, inactivity reminder, battery alerts, illness early-warning, cycle awareness, strain-target notification); strap power saving; Siri; classic Health Monitor (live HR hero, Recovery contributors, Fitness Age with readiness checklist, Vitality "Helping most / Holding back", Vital Signs grid, skin-temperature suite: illness heads-up, body clock, cycle awareness, Records & sources, Sync now). |

---------------------------------------------------------------------------------------------------------------------

## 5. Every metric shown in Pulse, and where

| Metric | Pulse location(s) | Format | Source / resolver |
|---|---|---|---|
| Sleep performance (NOOP "Rest") | Home dial "SLEEP"; My Day sleep row caption "97% Sleep"; Recovery › Contributors "Sleep" (vs 30-day avg); Sleep dive dial | 0–100 % | stored `sleep_performance` (WHOOP import wins its day, else the on-device Rest), else `AnalyticsEngine.Rest.composite`; carried on Today with caption |
| Recovery (NOOP "Charge") | Home dial "RECOVERY"; Recovery dive dial + band chip/line; Recovery history bars + Avg; drives Strain Target intent | 0–100 %, bands 67/34 | `DailyMetric.recovery` via `LiquidTodayView.ChargeDisplay` (carry #543, calibrating 4 nights) |
| Day Strain (NOOP "Effort") | Home dial "STRAIN"; Strain Target "Today 12.6"; Strain dive dial "of 21" | 0–21, one decimal (always the WHOOP scale here) | live `StrainScorer` over today's HR floored at the stored row; past days = stored row |
| Strain target | Home card; Strain dive card; band on the through-the-day chart | intent word + range | `CoupledView.optimalStrainRange` (Push 14–18 / Maintain 10–14 / Restore 4–10) |
| Day strain accumulation | Strain dive "THROUGH THE DAY" | curve, 15-min checkpoints | `PulseDisplay.cumulativeStrain` |
| Heart rate (day) | Strain dive "HEART RATE" | 5-min means, zone-shaded | `repo.hrBuckets(300 s)` |
| Time in HR zones 1–5 | Strain dive "TIME IN ZONES" | minutes | `HRZones.timeInZone` with the profile zone set; footer max HR |
| Avg HR / Peak HR (day) | Strain dive mini stats; "Peak N bpm" header | bpm | day-window HR samples |
| Calories (active) | Home Key Stats tile ("So far today"); Strain dive "CALORIES" | kcal | Apple Health active energy first, else on-device `activeKcalEst` |
| Steps | Home Key Stats tile ("So far today"); Health › Records › Steps value | count | `StepsResolver` (Apple Health → iPhone pedometer → strap counter → strap estimate) |
| HRV (RMSSD) | Key Stats tile (vs 30-day avg + 14-day spark); Recovery contributor (vs engine baseline); Health Monitor (typical range); What shaped it (points) | ms | `DailyMetric.avgHrv` (per-field carry on Today) |
| Resting HR | same four places | bpm | `DailyMetric.restingHr` |
| Respiratory rate | Key Stats; Recovery contributor; Health Monitor; What shaped it (as "br/min"); Sleep dive "BREATHING" | rpm, one decimal | `DailyMetric.respRateBpm` |
| Skin temperature | Key Stats (deviation preferred); Recovery › Context; Health Monitor; What shaped it | Δ°C/Δ°F deviation, or °C/°F absolute | `skinTempDevC` / `skinTempC` (bimodal handling) |
| Blood oxygen | Key Stats (conditional); Recovery › Context (conditional); Health Monitor (conditional) | % | `spo2Pct` only when imported/Apple Health (strap estimate stays hidden) |
| Stress | Home Stress card; Health Stress card | 0–3, one decimal + Low/Medium/High + hourly curve (today) | `StressModel` (today), stored `stress` series (past days), `StressDayCurve.today` |
| Last night onset/wake/asleep | My Day sleep row | clock times, h m | merged main-night group (`SleepModel.mergeDay`) |
| Naps | My Day; Sleep dive "NAPS" | times, minutes | blocks outside the main night (≤ nap ceiling) |
| Workouts | My Day rows; Strain dive "ACTIVITIES" | sport, start, duration, strain (0–21), kcal | `repo.workoutRows()` in the day window |
| Tonight's sleep need + breakdown | My Day "Tonight" | total h m + "+debt", "+strain", "−nap"; bedtime; wake + source | `repo.sleepNeedTonight` (baseline + strain + debt − nap credit) |
| Sleep need (that night) | Sleep dive "· 7h 2m needed" | h m | `repo.resolvedNightSleep(day:)` |
| Hours vs needed / Efficiency / Consistency / Restorative | Sleep dive Contributors | % + detail lines | screen's merged night ÷ need; asleep/in-bed; stored consistency; (deep+REM)/asleep |
| Stages | Sleep dive hypnogram + rows | minutes + % share; time in bed | merged night intervals |
| Sleeping HR / Lowest HR | Sleep dive mini stats | bpm | 1-min HR buckets over the night |
| Recovery drivers + confidence | Recovery › What shaped it | ±points, value · baseline, verdict; Reliable/Estimate/Calibrating | `RecoveryScorer.chargeDrivers`, `ScoreConfidence.charge` |
| Recovery calibration | Recovery dial "n/4 nights" + calibration card | count | `RecoveryScorer.calibrationNights` |
| Health Monitor in-range count | Health "4 of 5 in range" | count | `BodyVitalSigns.readings` + `VitalBands` |
| Body Age, Fitness Age, VO₂ max (est.), Vitality | Health › Healthspan tiles | yrs / yrs / ml/kg/min / /100 | weekly `body_age`, `fitness_age`, `vo2max_est`, `vitality` series |
| Menstrual cycle phase / cycle day / next period window | Health (conditional card) | phase word, ~day N | `CyclePhaseEngine` |
| Journal logged days | Home Journal strip (today) | 7 bars | `repo.nativeJournalDays` |
| Strap battery / charging / syncing / connection | Home header strap chip | % + glyph | `LiveState` |
| Live HR | Home header chip (while streaming) | bpm | `LiveState.heartRate` |

---------------------------------------------------------------------------------------------------------------------

## 6. Computed (or stored) but NOT shown in Pulse

| What | Where it is computed | Where it surfaces today (outside Pulse), if anywhere |
|---|---|---|
| Readiness level (Primed / Balanced / Strained / Run down) and its signals (HRV, RHR, resp, ACWR, monotony) | `ReadinessEngine` | classic Liquid Today "SYNTHESIS"; CoupledView (not reachable from Pulse) |
| Training load: CTL / ATL / TSB (form), ACWR, monotony | `TrainingLoadEngine`, `ReadinessEngine` | TrendsView › Training load card (More › Trends) |
| Tomorrow's Charge forecast (± band) | `RecoveryForecast` | IntelligenceView (More › Advanced › Intelligence) |
| Sleep debt balance and 14-night ledger | `SleepDebt`, stored `sleep_debt_min` | classic Sleep "Sleep-debt ledger"; Pulse shows only "+1h 58m debt" inside Tonight |
| Sleep need baseline (base minutes) and need breakdown per past night | `SleepNeed`, stored `sleep_need_baseline_min`, `…_strain_min`, `…_debt_min`, `…_nap_min` | Explore only; Pulse folds them into one total |
| Sleep disturbances count | `DailyMetric.disturbances` | classic night detail (UNCONFIRMED exact card) |
| Sleeping HR curve through the night, overnight movement | HR buckets / motion | classic SleepView |
| Stages vs your 30-day typical; 30-night asleep-duration trend; sleep score word (Poor/Fair/Good/Optimal) | `SleepStageTotals`, SleepModel | classic SleepView |
| Body clock / circadian phase, jet-lag & shift light plan | `CircadianEngine` | classic SleepView "Body clock", classic Health skin-temp suite |
| Illness early-warning ("Heads-up") | `IllnessSignalEngine`, `IllnessDistance` | classic Today `HealthAlertBanner`, classic Health heads-up card, local notification "Early warning: take it easy" (Automations toggle). NOT on Pulse Home. |
| HRV SDNN (nightly 5-min SDNN index) | `DailyMetric.avgSdnn` | not on any Pulse screen |
| Frequency-domain HRV (LF/HF/total power), Baevsky Stress Index | `HRVFreqDomain`, `StressIndex` | StressView "Advanced HRV" |
| Spot HRV reading | `SpotHrvReading` | LiveView HRV snapshot |
| Heart-rate recovery after workouts (1/2/5 min) | `HeartRateRecovery` | WorkoutDetailView / WorkoutsView |
| Activity cost per sport (Charge dip, days to bounce back) | `ActivityCostEngine` | InsightsView "Activity Cost" |
| Behaviour effects, dose-response, metric relationships | `BehaviorInsights`, `EffectRanker`, `DoseResponseEngine`, `CorrelationEngine` | InsightsView / InsightsHubView (More) |
| Weekly digest | `WeeklyDigest` | WeeklyDigestView (More) |
| Mood check-in (1–5) + correlations; caffeine log | `MoodStore`, `CaffeineLog` | InsightsView (Journal) |
| Hydration (goal from sex + strain, fluid log) | `HydrationGoal`, `HydrationStore` | classic Liquid Today card → HydrationView. **Unreachable from Pulse.** |
| "Coupled view" (recovery + strain + sleep on one page, readiness tint) | CoupledView | classic Today card only. **Unreachable from Pulse.** |
| Auto-detected workout suggestion (save / dismiss) | `AutoWorkoutDetector`, `repo.autoDetectCandidate` | classic Today `AutoWorkoutCard`. Not on Pulse Home. |
| Weight, body fat, lean mass, BMI | Apple Health import | classic Key Metrics "Weight" tile, Apple Health page, Explore |
| Nutrition (calories in, protein, carbs, fat) | Nutrition CSV import | Explore/Compare only |
| Mi Band metrics (sleep score, intensity minutes, stress /100…) | Mi Fitness import | Explore/Compare, Mi Band page |
| Streaks (WHOOP-style days in a row) | `StreakCalculator` | Settings "Streak" card; Steps streak on Steps screen |
| Strap battery runtime prediction | `BatteryEstimator` | battery notifications (Automations › "Predictive runtime warning"); not displayed as a number on Devices |
| HRV readiness (Plews/Altini SWC), experimental | `HRVReadiness` | Test Centre only (flag off by default) |
| Raw SpO₂ PPG (red/IR) and SpO₂ candidate % | `spo2Red/spo2Ir`, `spo2_candidate` | experimental / Test Centre |
| Steps estimate from strap motion (WHOOP 4.0) | `StepsEstimateEngine` | behind the steps resolver; Steps source chip |
| Effort on NOOP's 0–100 scale; Charge/Effort/Rest naming | settings + catalog | every classic screen (default scale is 0–100) |
| `exerciseCount`, `sleepHrOnly`, RHR primary-session candidate, HRV R-R overcount | DailyMetric / instrumentation | nowhere user-facing |
| Pre-sleep HR feedback, sleep-vs-wake HR contrast, adaptive energy expenditure (TDEE) | `PreSleepHeartRateFeedback`, `SleepHeartRateContrast`, `AdaptiveExpenditureEngine` | **not wired to any UI** (package only) |
| Daily AI "Coach brief" | `CoachBriefScheduler` | Coach Brief widget + notification only; nothing on Pulse Home |
| Sleep marks (bed/wake taps), "Why this sleep?", sleep edit/delete/add nap | SleepMark, SleepModel | classic SleepView |
| Full-day full-resolution HR timeline | FullDayChartView | More › Explore (top link) |

---------------------------------------------------------------------------------------------------------------------

## 7. Theme tokens in use

### 7.1 PulseTheme (StrandiOS/Pulse/PulseTheme.swift) with sampled verification

| Token | Code value | Sampled on screen (element) |
|---|---|---|
| backgroundTop | #101518 | #101518 status-bar band (01, x=600 y=0–41); gradient #0C1012 just under the island |
| backgroundBottom | #000000 | #000000 tab bar (01, y≥2373); page mid #090A0C, lower #020303 |
| card | #161C20 | #161C20 Strain Target / My Day / tiles / More rows |
| hairline | white 9% | #2B3034 card border on #161C20 (1 pt = 3 px); #333A3F ring on raised chips |
| cardRaised | #1F272C | #1F272C/#20282D strap chip, + button, row icon circles, band chips, Breathe button |
| track | white 12% | #32373B on cards (bars, journal strip), #272829 on page (dial tracks) |
| textPrimary | #FFFFFF | #FFFFFF numerals, titles |
| textSecondary | white 74% | #C3C4C5 comparison lines on cards; #C5C7C8 chip text |
| textTertiary | white 58% | #9DA0A1 row subtitles on cards; #A1A4A6 offline strap glyph |
| recoveryGreen | #16EC06 | not visible (no green day in the demo) |
| recoveryYellow | #FFDE00 | #FFDE00 dial arc, "Maintain", history bars, warning icons |
| recoveryRed | #FF0026 | #FF0026 history bars |
| recoveryRedText | #FF4A5C | (Live HR icon, low-battery glyph; not sampled) |
| strain | #0093E7 | #0093E7 dial arc; #0191E3 target bar fill; #23536F range fill; #0786CF range outline |
| sleep | #7BA1BB | #7BA1BB dial arc, sleep contributor bars |
| accent | #00F19F | #00F19F floating +, selected tab, Back, Breathe text, journal bars, status ticks |
| onAccent | #04140E | #04140E plus glyph on the floating button |
| attention | = recoveryYellow | #FFDE00 out-of-range icon/marker |
| zones 1–5 | #7E8A94, #0093E7, #16C47F, #FFB020, #FF4A5C | #7E8A94, #0093E7, #16C47F zone bars (09) |
| stage() | awake #C9D1D9, light #7BA1BB, deep #4F6BFF, rem #A98BFF | **unused** — the hypnogram and stage rows draw the Oura palette instead (#EAE3D3 / #40B0E0 / #206080 / #90D0F0) |
| Unselected tab | (system) | #7C7C7C |
| BrandMark avatar | (classic) | #03E095 ring + white dot |

Geometry: pagePadding 16 pt (sampled 48 px), cardRadius 18 pt continuous (corner curve sampled ~70 px long, consistent
with 18 pt continuous), cardPadding 16 pt, sectionSpacing 22 pt, minTapTarget 44 pt, Key Stats tiles 179 x ≥148 pt with
12 pt gutters, small cards (+ menu rows, night navigator) radius 14 pt, chips = capsules (10 pt h-padding, 5 pt
v-padding), row min height 60 pt, row icon 36 pt circles, divider inset 62 pt, home dial 102 pt / 9 pt arc / 3 pt track,
detail dial 196 pt (sleep 184 pt) / 14 pt arc, floating + 56 pt, header buttons 36 pt circles, strap chip 44x32 pt.

Type (system SF Pro, Dynamic Type aware):
- Numerals: `.system(size:, weight: .bold).width(.condensed).monospacedDigit()` — SF Pro Condensed Bold. Sizes: home
  dials ≈34 pt (scaled), detail dials ≈64 pt, stress score 36, key stat 30, healthspan 30, mini stats 24, contributor and
  target range 22, row values 20, "/ 3" 16 semibold.
- Labels: caption (12 pt) semibold, UPPERCASED, tracking 1.1 pt, tertiary (or secondary for section headers/dial names).
- Day title title3 bold (20 pt); page title "Health" largeTitle bold (34 pt); nav titles headline (17 pt semibold);
  row titles subheadline semibold (15 pt); subtitles caption (12 pt); small captions caption2 (11 pt).
- Press feedback: dim to 62% opacity while pressed, no animation loops.

Motion: dial fill 0.9 s ease-out on appear, 0.35 s on change; sheet presentation timing curve (0.22, 1, 0.36, 1) 0.42 s;
day-change selection haptic; Reduce Motion respected.

### 7.2 Classic tokens that appear inside Pulse (inconsistency sources)

- Classic canvas #1D1E23 / surfaces #2A2C34–#30323B / border #373A44 / radius 22 / section gap 26 (NoopVisualStyle),
  primary text #F7F7FA, secondary #C3C4CA, tertiary #7D7F88, accent mint #69DDB8 (or WHOOP Blue #60A0E0 / custom).
- Day-cycle sky backdrops (`LiquidSkyStatic`) on MetricDetailView, Settings, Devices, Sleep, etc.
- `ChargeDriverRow` (classic colours #0F9D62 / #C0392B / #D5A19E pip bars, `StrandFont`) inside Recovery › What shaped it.
- `DaytimeLoadLine` (classic stress ramp) inside the Pulse Stress card; `Hypnogram` with the Oura palette in the Sleep dive;
  `MenstrualCycleHomeCard` (classic `NoopCard`) inside the Health tab; `WorkoutTypeIcon`, `ProfileAvatarView`/BrandMark.

### 7.3 Repo's own "WHOOP design language" reference (for cross-checking, not verified by me)

`docs/superpowers/specs/2026-06-22-whoop-design-language.md` claims to be pixel-sampled from 20 real WHOOP iOS
screenshots: canvas #121518, cards #25292C / raised #31363A with NO borders, track #1F252A, divider #1C1F22, text
#FFFFFF / #9AA4AC / #6B7177, links blue #60A0E0 ("never gold"), status green #03E095 / warning #F0A020 / critical
#E0463C, Recovery green #03E095 / yellow #F9DF4A / red #E0463C, Strain #4090E0, Sleep #83A0B8, deep stage purple
#A06CE0; dial labels with "›" ("SLEEP ›"); card titles UPPERCASE with a grey "›" when tappable; two half-width cards
(Health Monitor + Stress Monitor); "My Dashboard" header with blue "CUSTOMIZE ✎"; floating pill tab bar. Pulse departs
from this spec on: borders (Pulse has 1 pt hairlines), card colour (#161C20 vs #25292C), page (gradient to pure black vs
#121518), accent (mint-green #00F19F vs link blue), Recovery green (#16EC06 vs #03E095), strain (#0093E7 vs #4090E0),
sleep (#7BA1BB vs #83A0B8), deep stage (Oura #206080 vs purple), no "›" on dial labels, no two-card row, standard tab bar.
The WHOOP-research agents should confirm or replace these values.

---------------------------------------------------------------------------------------------------------------------

## 8. Visual / UX inconsistencies seen today (matter for the rebuild)

1. **Two design systems on screen.** Every tap below Pulse's own three dives lands on a classic page: different canvas
   (#1D1E23 vs gradient-to-black), lighter cards (#2C3036 vs #161C20), 22 pt vs 18 pt radius, SF Rounded vs SF Condensed
   numerals, mint #69DDB8 vs #00F19F accent, sky backdrops (compare screenshots 13 → 15).
2. **Naming.** Pulse says Recovery / Strain / Sleep; MetricDetailView, Trends, Workouts, Coach and Settings say Charge /
   Effort / Rest (catalog titles "Charge", "Effort", "Rest"). Tapping the Recovery › Sleep row opens a page titled
   "Rest".
3. **Strain scale.** Pulse always shows 0–21; classic screens use the Effort-scale setting whose default is **0–100**, so a
   workout listed as "8.4 Strain" opens a detail that reads "Effort … of 100" by default.
4. **Units.** Respiratory rate is "rpm" in Pulse but "br/min" in What shaped it; skin temperature is "+0.4 Δ°C" in Pulse
   but "+0.4 C vs baseline" (no degree sign) in What shaped it (crop 23).
5. **Two references for one fact.** HRV reads "▲45%" vs 30-day avg on Home and "▲44%" vs baseline on Recovery, with
   different words ("vs 30-day avg" vs "Baseline 77 ms"). The Skin temp tile prints the deviation twice ("+0.4 Δ°C" and
   "▲ +0.4 Δ°C").
6. **Hidden entry points.** Hydration and Coupled view are unreachable in Pulse; illness heads-up, auto-workout
   suggestions, readiness/synthesis and the live-HR card are only on the classic Today.
7. **Two-step workout start.** "+ › Start workout" opens the Workouts log, which then has its own "Start workout" button.
8. **Title placement differs per tab.** Health draws a custom large title inside the scroll; More uses the system large
   title (it sits lower); Home has no title at all.
9. **Brand copy.** App label is ZENO, Steps copy says ZENO, but Settings and other classic copy still say NOOP.
10. `PulseTheme.stage()` colours are defined but unused (dead tokens).
11. The Strain Target bar renders 16 pt tall although the component is written for a 10 pt bar (the 16 pt knob sets the
    height) — measured, not a design decision.

---------------------------------------------------------------------------------------------------------------------

## 9. What ZENO has that WHOOP (probably) lacks — keep these as "extras"

The "WHOOP overlap" column is my best knowledge and must be checked against the WHOOP research notes; anything marked
"verify" is UNCONFIRMED.

| ZENO feature (location) | WHOOP overlap |
|---|---|
| Fully offline / on-device: no account, no subscription, no cloud, data in local SQLite; works with no network | WHOOP needs a membership and its cloud — clear differentiator |
| Bring your WHOOP history: WHOOP CSV export import; Apple Health export import; Nutrition CSV (Cronometer/MacroFactor); Mi Band import; experimental Oura ring BLE; multi-device registry; "Your Data, Fused" (More › Data / Advanced) | WHOOP integrates partners but does not import other wearables' history — verify |
| Data ownership: CSV export, .noopbak backup/restore, folder Backup & Sync, HealthKit-free Shortcuts export, optional self-hosted one-way push (experimental) | WHOOP offers a data export request only — verify |
| Explore (every metric, full-day full-res HR, correlation scan) and Compare (overlay 2–4 metrics + Pearson r) | WHOOP Trends exist but no free-form overlay/correlation explorer — verify |
| Statistical Insights: behaviour effects with Cohen's d + multiple-testing control, dose-response, metric relationships, activity cost per sport, personal experiment, weekly digest, exportable report | WHOOP Monthly/Weekly Performance Assessments + Journal impact overlap partially |
| Strap-haptic HRV breathing biofeedback (1 buzz inhale / 2 exhale), 20+ protocols, resonance-pace sweep, coherence estimate, pre/post RMSSD, haptic stress check-ins (Breathe) | WHOOP breathwork with strap haptics — verify |
| Haptic interval timer (strap buzzes WORK/REST, 3-2-1, finish) | not known in WHOOP — verify |
| Live Session "Silent Guardian": recovery-gated continuous HR band with strap haptic nudges (beta) | WHOOP Strain Coach is a milestone-style analogue (partial overlap) |
| Lift Log: programs (import/edit), sessions, sets/reps, strap rest timer, sets per muscle, Lift Live Activity | WHOOP Strength Trainer overlaps (muscular load) — compare depth |
| AI Coach with your own key (OpenAI / Anthropic / Gemini) or a self-hosted/local OpenAI-compatible model (Ollama, LM Studio), voice input, daily Coach brief widget | WHOOP Coach is built-in cloud AI — ZENO's differs by being optional/private/local-capable |
| Apple Watch app (glance, Breathe, Workout, Intervals) + complications | **Code exists but NOT embedded in this build** (`# - target: NOOPWatch` in project.yml for free signing). WHOOP watch support — verify |
| Live Activities / Dynamic Island for live HR, strap sync and lift session | WHOOP Live Activity for activities — verify. (ZENO Home/Lock widgets — rings, HR, Stress, Coach brief — need an App Group that free signing lacks, so they show placeholders) |
| Siri / App Intents: "Sync Strap", "Mark a Moment", "Buzz Strap", "Ask Coach"; Home Screen quick actions | likely absent in WHOOP — verify |
| Automations (More › Advanced › Automations): strap double-tap → "Buzz back (confirm)" / "Mark a moment" / "Log a sleep mark" / "Buzz the time" / "Run a Shortcut…" (iPhone list; "Lock" is Mac-only); wrist off/on presence Shortcuts; HR-zone coaching buzz; inactivity reminder buzz; Live Session and interval cues; battery alerts + "Predictive runtime warning"; "Notify when optimal strain is reached"; illness early-warning; step-goal notification; wind-down nudge | WHOOP has some alerts; strap double-tap actions — verify |
| Mark moment (timeline pin) from the + menu or the strap | not known in WHOOP |
| Smart alarm armed on the strap firmware + wind-down planner with per-day wake times | WHOOP haptic alarm overlaps |
| Rhythm: Poincaré beat-to-beat visualization (experimental, non-diagnostic) | WHOOP MG ECG Heart Screener is a different, medical feature |
| Lab Book: private notebook for your own lab readings with trends and signal comparison | WHOOP Advanced Labs (paid blood tests) overlaps partially |
| Test Centre diagnostics, Live Body Console (R-R, RMSSD, strap log), raw data collector, power-saving levers | not in WHOOP |
| Hydration tracker (strain-adjusted goal), caffeine log, mood check-in (non-clinical) | WHOOP Journal questions overlap partially |
| Body clock / circadian phase + jet-lag light plan; Tomorrow's Charge forecast; readiness (ACWR, monotony); training load CTL/ATL/TSB; illness early-warning | verify each |
| Steps from iPhone pedometer / Apple Health / strap estimate, goal, streak, best day, goal notification | WHOOP added steps — overlap |
| Cycle awareness from skin temperature (on-device) | WHOOP Menstrual Cycle Insights overlap |
| Deep customisation (classic): theme presets, accent colours, alternate app icon, day-cycle sky or custom background, units incl. Effort 0–100 vs 0–21, reorderable/hideable Today sections and key metric tiles, hosted cards | WHOOP "Customize" dashboard is narrower — verify |
| Two interfaces (WHOOP-style Pulse and Classic) switchable at any time; also macOS (menu bar) and Android apps | n/a |

---------------------------------------------------------------------------------------------------------------------

## 10. Quick structural deltas vs WHOOP (from the App Store images another agent saved)

I viewed `whoop-reference/images/appstore/ios69-01-home-overview.png`, `ios69-03-recovery.png`,
`ios69-05-healthspan.png` and `ios69-10-stress.png` (marketing screenshots, app version unknown) only to orient this
inventory; the WHOOP agents own the detail.

- WHOOP Home top bar: avatar + streak chip ("🔥355") left, a "‹ TODAY ›" pill centred, battery "⚡65%" + strap glyph right,
  "WHOOP" wordmark above the dials. ZENO: avatar left, chips + "+" right, a separate title row below ("‹ Today ›" with a
  date line), no wordmark, no streak.
- WHOOP dial labels carry "›" ("SLEEP ›"); ZENO's do not.
- WHOOP shows an insight card under the dials ("Optimal Health … meeting your Strain target of 15.5 …" with a check and a
  count); ZENO shows a Strain Target range card instead.
- WHOOP Home has half-width "HEALTH MONITOR ›" (Within range 5/5) and "STRESS MONITOR ›" (1.5 Medium, time) cards; ZENO
  has no Health Monitor on Home and a full-width Stress card further down.
- WHOOP "My Day" has a "+" button and a "Daily Outlook" row, then an Activities card; ZENO's My Day is a list
  (sleep, naps, workouts, Tonight) and its + is a floating button.
- WHOOP tab bar is a floating pill (Home, …, Community, More) with a separate round "W" coach button; ZENO uses the
  standard black tab bar Home / Health / (Coach) / More.
- WHOOP Recovery detail: centred "TODAY" caps title + ⓘ; ring with wordmark, "85%" and "RECOVERY" inside; contributor list
  with line icons, UPPERCASE labels, value + coloured ▲ and "Today vs. prior 30 days"; a coach insight card with a
  gradient border and "BREAK DOWN MY RECOVERY →". ZENO: "Back" + title/date, number-only dial, band chip, contributors vs
  baseline, Context, What shaped it, History.
- WHOOP Healthspan: particle sphere "29.9 WHOOP AGE", "2.3 years younger", "PACE OF AGING 0.8x" slider, weekly date
  range; ZENO: four small tiles (Body Age, Fitness Age, VO₂ max, Vitality), no pace of aging.
- WHOOP Stress Monitor: semicircle 0.0–3.0 gauge "1.5 MEDIUM, Last updated 3:05pm", intraday chart with activity icons
  and zoom, coach card, "TOTAL DAY vs typical Tuesday" bars; ZENO's Pulse card is number + chip + small curve + Breathe
  (the classic StressView behind it has a gauge and timeline in classic styling).

---------------------------------------------------------------------------------------------------------------------

## 11. Gaps / UNCONFIRMED

- No screenshot exists of: More below "Live" (Strap & alarms, Data, Settings, Advanced, Interface), Recovery "What
  shaped it" header + HRV/Sleep rows, Recovery calibration and carried states, a green or red Recovery day (#16EC06 never
  seen rendered), Home with workouts or naps, the Journal strip with logged days, the Coach tab, the menstrual cycle card,
  the Strain dive "HEART RATE · Peak" header, Sleep dive naps and older-night titles, the calendar sheet, Live HR chip,
  strap chip with a connected strap, light/dark of classic screens pushed from Pulse other than Steps. All are
  code-confirmed only.
- Screenshots are from the DEBUG demo seed in an iOS simulator (iPhone 16 Pro). On-device rendering (iOS 18 vs iOS 26
  tab bar) was not checked.
- Disturbances: the classic card that shows them was not traced (UNCONFIRMED).
- WHOOP overlap claims in section 9 marked "verify" are not established by this research.
- I did not build or run the app; nothing in `noop/` was changed.

---------------------------------------------------------------------------------------------------------------------

## 12. Image index (`whoop-reference/images/zeno-inventory/`)

| File | What it shows |
|---|---|
| 00-zeno-overview-all-screens.png | contact sheet "ZENO Fitness Tracker — WHOOP-style interface · iPhone 16 Pro simulator · demo data" |
| 01-zeno-home-today-top.png | Home: header, dials 97/58/12.6, Strain Target, My Day |
| 02-zeno-home-key-stats.png | Key Stats grid (7 tiles) |
| 03-zeno-home-stress-journal.png | Stress card + Breathe, Journal strip, floating + |
| 04-zeno-home-past-day.png | Home on Monday Sep 28 with "Today" chip |
| 05-zeno-plus-start-sheet.png | "Start" sheet over Home |
| 06-zeno-recovery-detail-top.png | Recovery hero, Contributors, Context |
| 07-zeno-recovery-what-shaped-it-history.png | What shaped it rows + History 30 days |
| 08-zeno-strain-detail-top.png | Strain hero, target, Through the day |
| 09-zeno-strain-hr-zones-activities.png | HR chart, Time in zones, mini stats, Activities empty |
| 10-zeno-sleep-detail-top.png | Night navigator, dial, Contributors |
| 11-zeno-sleep-stages-hypnogram.png | Stages hypnogram + rows, mini stats, full-screen button |
| 12-zeno-health-tab-monitor.png | Health title, Health Monitor, Stress |
| 13-zeno-health-tab-healthspan-records.png | Stress, Healthspan tiles, Records |
| 14-zeno-more-tab-top.png | More: Performance, Insights, Activity (top) |
| 15-zeno-steps-classic-screen-top.png | classic Steps screen (ring, by hour, last 7 days) |
| 16-zeno-steps-classic-screen-history.png | classic Steps (last 30 days, streak, best day, goal) |
| 20-zeno-crop-home-header-dials.png | full-res crop: header + dials |
| 21-zeno-crop-home-strain-target-myday.png | full-res crop: Strain Target + My Day |
| 22-zeno-crop-recovery-contributors-context.png | full-res crop: Contributors + Context |
| 23-zeno-crop-recovery-what-shaped-it-rows.png | full-res crop: classic driver rows ("br/min", "+0.4 C") |
