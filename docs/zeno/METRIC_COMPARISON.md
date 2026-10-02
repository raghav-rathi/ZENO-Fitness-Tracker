# METRIC_COMPARISON: every WHOOP (2025–26) metric and feature vs ZENO 11.8.0

Revision 2, 2026-10-02. It follows `WHOOP_UI_SPEC.md` revision 2.

**Scope.**
- **WHOOP side:** the current iOS app as described in `WHOOP_UI_SPEC.md` and the research notes, including the six gap-fill notes:
  - deep dives below the fold;
  - activity flows;
  - onboarding;
  - Health tab and settings;
  - Journal, behaviours and Plan;
  - Profile, Community and Year in Review.
- **ZENO side:** the Pulse ("WHOOP-style") interface plus the classic screens it links to.
  - Source: `notes/zeno-inventory.md`, plus read-only code checks in `noop/` on 2026-10-02.
  - Revision 2 added these checks:
    - `OnboardingWizard` (12 steps) and `TermsGateView`;
    - `LiveWorkoutView` / `ActiveWorkout` (pause, End confirm, live strain on the Effort scale, GPS distance and pace);
    - `HrBroadcaster` (phone-side BLE HR re-broadcast);
    - `ManualWorkoutSheet` (no overlap check);
    - Lift Log (no supersets, no PR list);
    - sleep latency (dev tools only).
- **Hardware assumed:** the user's **WHOOP 4.0** strap with ZENO's on-device processing (no WHOOP account, no cloud).

**Status legend.**

| Status | Meaning |
|---|---|
| **HAVE** | ZENO computes it and shows it today. The look may differ; restyling is covered by the spec. |
| **PARTIAL** | ZENO has the data or a near-equivalent, but something specific is missing (stated). |
| **BUILDABLE** | Missing today, but it can be built fully offline from data ZENO already has (source stated). |
| **NOT POSSIBLE** | Cannot be done offline with a 4.0 strap. The reason is stated: server, other users ([POP]), missing hardware, regulated medical output, or proprietary model/content. |
| **N/A** | WHOOP commercial or account surface (shop, membership, referrals, sign-in). Deliberately not cloned. |

- "Where in ZENO" names the current screen, or the engine/file when nothing is on screen.
- Rows marked **(new)** were added in revision 2.

---------------------------------------------------------------------------------------------------

## A. App shell and Home header

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| A1 | Floating glass tab capsule Home · Health · Community · More + separate AI button | global | PARTIAL | Native black tab bar Home · Health · (Coach) · More, plus a floating mint "+". Missing: capsule, AI button, Community slot | Build in `PulseRootView`. Community slot becomes Trends (L1 is not possible) |
| A2 | Avatar → Profile | Home header | PARTIAL | Avatar opens Settings; there is no Profile page | Profile is BUILDABLE (section J) |
| A3 | Day-streak flame + count, six colour tiers by length (yellow → orange → red → magenta → blue → gold) | Home header | PARTIAL | `StreakCalculator` exists; only a Settings "Streak" card and the Steps streak show it | `StreakCalculator` |
| A4 | Date pager "‹ TODAY ›" / "‹ WED, MAY 27 ›" | Home header | HAVE | Day stepper row "‹ Today ›" + calendar sheet + swipe | restyle into the pill |
| A5 | Physiological-cycle label "OCT 14 TO TODAY" | Home header | BUILDABLE (optional) | ZENO is calendar-day based | `DayOwnerResolver`; spec keeps "TODAY" [Z] |
| A6 | Strap battery % (+ charging bolt, red when low) | Home header | HAVE | Strap chip (battery, bolt, red < 15%) | `LiveState` |
| A7 | Strap connection dot; tap → Device Settings | Home header | HAVE | Strap chip → Devices sheet | `LiveState` |
| A8 | Sync banner "DATA CAUGHT UP · SYNCED TO 7:32AM" / "CATCHING UP" | Home | PARTIAL | Chip shows "Syncing"; no banner, no "synced to" time | `LiveState` backfill progress + last-sync time |
| A9 | "Off-body" banner | Home | BUILDABLE | Wear detection exists (`WristWearRecovery`, presence automations) but is not on Home | wear-state from strap |
| A10 | "Firmware update complete" banner | Home | NOT POSSIBLE | ZENO cannot update firmware (proprietary signed images from WHOOP's cloud) | – |
| A11 | Card-expired / membership banners | Home | N/A | – | commercial |
| A12 | Brand wordmark above the dials | Home | BUILDABLE | None today | ZENO's own mark (guardrail: never the WHOOP logo) |
| A13 | Sticky compact header: mini-ring row (2026 default); header-row variant | Home | BUILDABLE | None | existing dial values |
| A14 | Tilt mode: landscape full-day HR with sleep, Recovery and Strain markers, scrub tooltip | Home | PARTIAL | `FullDayChartView` exists, buried in More › Explore; no rotation trigger | HR store + `FullDayChartView` |
| A15 | Floating coach summary pill on deep dives and Activity Details (new) | dives, details | BUILDABLE | None | Local insight templates; the LLM when a provider is configured |
| A16 | Achievement chip in the deep-dive nav (pillar badge + count) (new) | dives | BUILDABLE | None | Local counts: green recoveries, 85%+ sleeps, strain days |

## B. Home: dials, cards, My Day, My Plan, My Dashboard

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| B1 | Sleep Performance dial (%) | Home | HAVE | Home dial "SLEEP" | `sleep_performance` / `Rest.composite` |
| B2 | Recovery dial (%) in green/yellow/red | Home | HAVE | Home dial "RECOVERY" | `DailyMetric.recovery` |
| B3 | Day Strain dial (0–21, 1 dp) | Home | HAVE | Home dial "STRAIN" | `StrainScorer` |
| B4 | Strain dial overlay: optimal-range band under the arc + target tick at the range midpoint | Home, Strain dive | PARTIAL | Range is shown on a separate "STRAIN TARGET" card, not on the dial | `CoupledView.optimalStrainRange` (+ midpoint) |
| B5 | Dial look: 88 pt / 6 pt, butt caps, "LABEL ›", pressed disc | Home | PARTIAL | 102 pt / 9 pt arc on a 3 pt track, round caps, no chevrons | theme only |
| B6 | Empty "--%" and calibrating states; no band before Recovery | Home | HAVE | "–", "n/4 nights", "Calibrating" captions | – |
| B7 | Coaching/notification card stack with "✓ n" (Optimal Health, Strain Target Reached, Low HRV, Newly Red, 99% day, rough-sleep streak, alarm prompt, feature cards…) | Home | BUILDABLE | None on Pulse Home | Local rules over snapshots + `IllnessSignalEngine`, `AutoWorkoutDetector`, `SleepDebt` |
| B8 | HEALTH MONITOR tile: WITHIN RANGE n/5, ELEVATED / VERY ELEVATED <metric>, Pending; hidden on past days | Home | PARTIAL | Health tab shows "4 of 5 in range"; nothing on Home; no status words | `BodyVitalSigns` + `VitalBands` |
| B9 | STRESS MONITOR tile: score badge, LOW/MEDIUM/HIGH, last-update time | Home | PARTIAL | Full-width Stress card with value + band chip; no time; different layout | `StressModel` |
| B10 | "My Day" header + white "+" Action button | Home | PARTIAL | Header "+" circle and floating "+" open a "Start" sheet with different items | §1.3 of the spec |
| B11 | "Your Daily Outlook" / "Your Day In Review" pill (AI), with a read state | Home | PARTIAL | `CoachBriefScheduler` makes a daily brief for widget/notification only; no pill or page | Template from local data; LLM only if configured |
| B12 | TODAY'S ACTIVITIES card: colour chips (sleep duration / activity strain), names, start/end, "+ ADD ACTIVITY", "⏱ START ACTIVITY" | Home | PARTIAL | My Day list rows (sleep, naps, workouts) with values; no chips, no Add/Start buttons in the card | `repo.workoutRows()`, `SleepModel` |
| B13 | "⤢" expand → full-day HR timeline | Home | PARTIAL | `FullDayChartView` exists elsewhere | – |
| B14 | "NO SLEEP" row + "ADD SLEEP" | Home | PARTIAL | Add nap / edit sleep exist in classic `SleepView`; no Home entry | `SleepModel` |
| B15 | TONIGHT'S SLEEP card: recommended bedtime, alarm on/off + mode (EXACT TIME / LATEST ALARM), SET/EDIT ALARM | Home | PARTIAL | "Tonight" row: asleep-by, wake, sleep need breakdown → Alarms. Missing alarm state/mode and card layout | `repo.sleepNeedTonight`, `SmartAlarmView` |
| B16 | MY JOURNAL card: 7-day check circles + BEHAVIOR INSIGHTS button; kept on past days | Home | PARTIAL | Journal card with a 7-day bar strip, today only; insights only in More | `repo.nativeJournalDays` |
| B17 | My Plan card (name, days left, % accomplished, unfinished-first goal list with segmented rings, VIEW MY PLAN; empty "Build Your Best Self") | Home | BUILDABLE | No weekly plan | New `PlanStore` over `DailyMetric`, workouts, journal |
| B18 | Looking Ahead / CALIBRATION TIMELINE 0/7 | Home | PARTIAL | Calibration card only inside the Recovery dive ("n/4") | `RecoveryScorer.calibrationNights` |
| B19 | My Dashboard rows: value, good/bad ▲▼ (grey ● when equal, grey for neutral metrics), 30-day baseline | Home | PARTIAL | "KEY STATS" 2-column tiles: value, ▲▼ %, sparkline; fixed set of 7 | `DailyMetric` series |
| B20 | Customize Dashboard: add/remove/reorder, SAVE | Home | PARTIAL | Classic `TodayCustomizationSheet` / `EditableLayoutList`; the Pulse grid is fixed | reuse persistence |
| B21 | Dashboard STRESS MONITOR chart card (24 h line, sleep and activity bands; past-day version) | Home | PARTIAL | Home Stress card curve (waking hours, today only) | `DaytimeStress`, `StressDayCurve` |
| B22 | Dashboard STRAIN & RECOVERY 7-day dual-axis chart | Home | BUILDABLE | None | `DailyMetric` strain + recovery |
| B23 | Dashboard tile catalogue (list below) | Home | PARTIAL | All of these have data in ZENO, but only 7 Key Stats tiles render | `MetricCatalog` series |
| B24 | "Discover More" promos, tier wordmark footer | Home | N/A | – | commercial |
| B25 | Past-day Home (new): "ACTIVITIES" + single ADD; no tiles, stack, pill or Tonight; Journal, Plan and Dashboard kept | Home | PARTIAL | ZENO past day shows a "Today" chip, weekday title, dials, Strain Target and a "Sleep" row. It has no Journal, no Stress curve and no dashboard | existing per-day snapshots |
| B26 | Home MENSTRUAL CYCLE INSIGHTS card: Day N, phase, prediction, dot strip, "+ LOG CYCLE" (new) | Home | PARTIAL | Classic `MenstrualCycleHomeCard` exists on the Health tab only; no Home card, dot strip or log button | `CyclePhaseEngine` |
| B27 | New-member "Get Started" header + cards: charge tips, sleep schedule, journal, first activity, integrations (new) | Home | BUILDABLE | None | onboarding progress flags |
| B28 | "Ask a question, get support…" coach row / well (new) | Home | PARTIAL | Coach exists as a tab; no Home entry | `CoachView` |
| B29 | Activity chip states: unscored (struck chart glyph), strain pending, pre-added outline + dotted bar, recovery-activity duration chip, nap glyph (new) | Home | BUILDABLE | ZENO rows show values only | workout and sleep processing state |
| B30 | Home notification-feed error box (new) | Home | N/A | – | WHOOP server state; ZENO feeds are local |

B23 catalogue:
- Day Strain, Recovery.
- Sleep Performance, Sleep Consistency, Sleep Needed, **Sleep Debt**, Hours of Sleep, **Restorative Sleep (%)**.
- HRV, RHR, Respiratory Rate.
- Steps, Calories, Avg HR, HR Zones 1-3 / 4-5 / All (weekly), Strength Activity Time, VO₂ Max.
- **Weight**, Lean Body Mass (both only via Apple Health import).

Revision 1 wrongly listed Sleep Debt and Weight as ZENO-only.

## C. Sleep

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| C1 | Sleep Performance % | Sleep dive | HAVE | Sleep dive dial | stored / `Rest.composite` |
| C2 | Poor / Sufficient / Optimal level (3-dash under the score + per contributor) | Sleep dive | BUILDABLE | Plain bars, no levels | Thresholds: performance 85/70, consistency 80/70, efficiency 90/80, stress 1/5% |
| C3 | Hours vs. Needed % | Sleep dive | HAVE | Contributors "Hours vs needed" | merged night ÷ need |
| C4 | Sleep Consistency % | Sleep dive | HAVE | Contributors "Consistency" | `SleepConsistency` (stored) |
| C5 | Sleep Efficiency % | Sleep dive | HAVE | Contributors "Efficiency" | asleep ÷ in-bed |
| C6 | High Sleep Stress % (time in high stress while asleep) | Sleep dive | BUILDABLE | Not computed | Apply `DaytimeStress` math to 5-min windows in the sleep period (HR + R-R are stored); % of time ≥ 2.0 |
| C7 | Hours of sleep vs 30-day baseline (▲▼) | Sleep dive | PARTIAL | "6h 49m asleep · 7h 2m needed"; no baseline or arrow | asleep-minutes series |
| C8 | Overnight HR chart with bed/wake markers | Sleep dive | PARTIAL | Classic `SleepView` "sleeping HR through the night"; Pulse shows only mini-stats | 1-min HR buckets |
| C9 | Time in bed / Duration | Sleep dive | HAVE | "STAGES 7h 3m in bed" | – |
| C10 | Stage durations and % (Awake / Light / SWS (Deep) / REM) | Sleep dive | HAVE | Hypnogram + stage rows. Needs the WHOOP palette instead of Oura's | merged night intervals |
| C11 | Per-stage typical range (30-day) on hatched bars | Sleep dive | PARTIAL | Classic "Stages vs typical" card | `SleepStageTotals` 30-night p25–p75 |
| C12 | Stage selection: barcode timeline + HR-chart highlight | Sleep dive | BUILDABLE | Static hypnogram only | stage intervals |
| C13 | Restorative Sleep (h:mm) vs baseline (grey ● when equal) | Sleep dive | PARTIAL | "Restorative 46%" share only | deep + REM minutes |
| C14 | Weekly Trends, 7 cards: SP bars, Hours vs Needed (hours lines, % bars), Restorative hours (stacked SWS/REM), Consistency bars, Time in Bed (floating bars), Efficiency line | Sleep dive | PARTIAL | Each metric exists in `MetricDetailView`; no weekly cards in the dive | metric series |
| C15 | Sleep need tonight + breakdown | Home / Sleep Planner | HAVE | "Tonight" row "+debt · +strain · −nap" | `repo.sleepNeedTonight` |
| C16 | Sleep debt | Trend View / dashboard | HAVE | Pulse "+1h 58m debt"; classic Sleep-debt ledger | `SleepDebt` |
| C17 | Wake events count | Efficiency card / sleep activity | PARTIAL | Stored `disturbances`; shown only on a classic night card | `DailyMetric.disturbances` |
| C18 | Respiratory rate during sleep | Recovery / Health Monitor | HAVE | Sleep dive "BREATHING", Key Stats | `respRateBpm` |
| C19 | Nap detail (hours, restorative, sleep-need reduction, vs 30-day range) | Activity Details | PARTIAL | Nap rows with times and duration; no detail or need-credit line | nap credit already in `SleepNeed` |
| C20 | Edit sleep / add sleep / delete | Sleep dive EDIT | HAVE | Classic `SleepView` (edit, delete + undo, add nap) | – |
| C21 | Sleep insight sentence / summary pill | Sleep dive | BUILDABLE | None | template over contributors |
| C22 | Sleep Planner: goal, suggested bedtime, wake time, time-in-bed bar, optimal window, consistency projection | Sleep Planner | PARTIAL | "Tonight" row + wind-down nudge in Alarms; no planner screen and no consistency projection | `sleepNeedTonight`, `SleepConsistency` |
| C23 | Haptic wake alarm, exact time | Sleep Planner | HAVE | `SmartAlarmView` (strap firmware alarm) | – |
| C24 | Smart alarm modes: Sleep Goal / In the Green (1 h window) | Sleep Planner | PARTIAL | iOS exact-time only; the phone-side "Wake Window" smart wake exists in ZENO **Android** | iOS: buildable as BETA, needs an overnight BLE connection and background execution |
| C25 | Alarm schedule by weekday | My Schedule | HAVE | "Different wake time per day" | – |
| C26 | Recommended bedtime on Home | Home | HAVE | "Asleep by 8:24 PM" | – |
| C27 | Bedtime reminder | notification | HAVE | Wind-down nudge | – |
| C28 | SLEEP LATENCY row (only for manually started or edited sleeps) (new) | Sleep dive | BUILDABLE | Latency is computed only in dev tools (`Tools/SleepPSG`); the app assumes 15 min | `SleepMark` bed tap → detected onset |
| C29 | HOURS VS. NEEDED card: hours bar vs need bar + breakdown "Healthy Minimum / Recent Naps / Recent Strain / Sleep Debt" (new) | Sleep dive | PARTIAL | The per-night breakdown is stored (`sleep_need_baseline_min`, `…_nap_min`, `…_strain_min`, `…_debt_min`) but Pulse shows one total; no card | stored breakdown fields |
| C30 | SLEEP CONSISTENCY card: 5-night bed→wake bars, callout pills, dashed optimal bed/wake curves (new) | Sleep dive | BUILDABLE | Consistency % only | nightly bed/wake times + `SleepNeed.suggestedBedtime` per night |
| C31 | SLEEP EFFICIENCY card: asleep/awake barcode tracks + WAKE EVENTS (new) | Sleep dive | PARTIAL | Efficiency % and `disturbances` stored; no card | awake intervals from the merged night |
| C32 | SLEEP STRESS card: overnight stress chart + HIGH / MEDIUM / LOW time and % (new) | Sleep dive | BUILDABLE | Not computed | as C6 |
| C33 | Per-contributor "Calibrating" state (Consistency needs 5 consecutive nights) (new) | Sleep dive | PARTIAL | Recovery has calibrating captions; other contributors show values or "–" | stored history length |

## D. Recovery

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| D1 | Recovery % + zones 67/34 | Recovery dive | HAVE | Hero dial + band chip | `RecoveryScorer` |
| D2 | HRV (ms) | Recovery dive | HAVE | Contributors | `avgHrv` |
| D3 | Resting HR (bpm) | Recovery dive | HAVE | Contributors | `restingHr` |
| D4 | Respiratory rate (rpm) | Recovery dive | HAVE | Contributors | `respRateBpm` |
| D5 | Sleep Performance as a contributor | Recovery dive | HAVE | Contributors "Sleep" | – |
| D6 | 30-day baseline under each value; ▲▼ coloured by favourability for any change, grey ● when equal | Recovery dive | PARTIAL | Baseline is the engine's learned baseline with a % change; arrows are not coloured by good/bad | 30-day means; direction table in spec §2.6 item 9 |
| D7 | "Today vs. last 30 days" legend | Recovery dive | BUILDABLE | – | – |
| D8 | Recovery insight text / summary pill ("HRV within its typical range of 55–77 ms…") | Recovery dive | BUILDABLE | Only a band line ("Maintain today") | template; ranges from `VitalBands` |
| D9 | Behavior Insights entry (compact row card) | Recovery dive | PARTIAL | `InsightsView` reachable from More / Journal only | link |
| D10 | Calibration before the first Recovery | Recovery dive / Home | HAVE | 4-night calibration card (WHOOP: 3 recoveries) | – |
| D11 | Recovery Weekly Trends: RECOVERY zone bars, HRV line, RHR line, RR line | Recovery dive / Trend View | PARTIAL | HISTORY 7/30/90 bar chart | series |
| D12 | SpO₂ (Health Monitor input) | Health Monitor | PARTIAL | Shown only when imported (Apple Health or WHOOP CSV). The strap's raw red/IR PPG SpO₂ is experimental and hidden | 4.0 hardware has the sensor; ZENO's estimate is not validated |
| D13 | Skin temperature deviation | Health Monitor | HAVE | Key Stats, Recovery › Context, Health Monitor | `skinTempDevC` |
| D14 | Behavior Insights card with yesterday's behaviour chips ("▲ Consistent Bed Time") (new) | Recovery dive | BUILDABLE | None | `EffectRanker` over yesterday's journal and auto-tracked behaviours |

## E. Strain, activities, strength

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| E1 | Day Strain 0–21 | Strain dive | HAVE | dial "of 21" | `StrainScorer` |
| E2 | Optimal strain range from Recovery (Strain Target) | Strain dive / Home | HAVE | Push 14–18 / Maintain 10–14 / Restore 4–10 | `optimalStrainRange` |
| E3 | Time in HR Zones 1-3 (day, vs 30-day) | Strain dive | PARTIAL | "TIME IN ZONES" Zone 1–5 minutes; no 1-3 sum or baseline | sum of `HRZones.timeInZone` |
| E4 | Time in HR Zones 4-5 | Strain dive | PARTIAL | same as E3 | same as E3 |
| E5 | Strength Activity Time | Strain dive / Healthspan | BUILDABLE | Not aggregated | Lift Log session minutes + strength-type workouts |
| E6 | Steps (vs 30-day) | Strain dive / dashboard | HAVE | Key Stats "So far today"; Steps screen | `StepsResolver` |
| E7 | Average HR (day) | dashboard / Trend View | HAVE | Strain dive "AVG HR" | day HR samples |
| E8 | Calories | dashboard | HAVE | Key Stats, Strain dive | Apple Health active energy or on-device estimate |
| E9 | Strain-band insight text (Light / Moderate / Strenuous / All out / above range) | Strain dive | BUILDABLE | None | thresholds 10 / 14 / 18 + range top |
| E10 | Today's Activities list in the Strain dive | Strain dive | HAVE | "ACTIVITIES" rows | workouts |
| E11 | "Strain target reached" haptic + notification | live | HAVE | Automations › "Notify when optimal strain is reached" (fires at the range bottom; spec moves it to the tick) | – |
| E12 | Activity Strain per workout (0–21) | Activity Details, live screen | PARTIAL | Pulse rows show 0–21. The classic `WorkoutDetailView` and `LiveWorkoutView` show Effort on a 0–100 scale by default | `workout.strain` |
| E13 | Activity strain delta chip (vs typical for this sport) | Activity Details | BUILDABLE | None | per-sport 30-day mean |
| E14 | Activity insight sentence | Activity Details | BUILDABLE | None | template (zone minutes vs typical) |
| E15 | Activity HR chart with start/end markers | Activity Details | HAVE | `WorkoutDetailView` HEART RATE | – |
| E16 | Zone rows Z5→Z0 with bpm ranges, %, h:mm:ss, typical-range box | Activity Details | PARTIAL | HR zones present; no typical range; classic style | `HRZones` + per-sport typical |
| E17 | Key Statistics vs 30-day average (calories, avg HR, max HR, duration, steps) | Activity Details | PARTIAL | Some values present; no "vs 30-day" chips | workout history |
| E18 | GPS route map, distance, pace/speed | Activity Details | HAVE | Route map + GPX/FIT export | – |
| E19 | Shareable route snapshot (route line, no map, sport glyph, Distance / Duration / Pace) | Activity Details | BUILDABLE | Export files only | route coordinates; local image render |
| E20 | Source attribution chip ("VIA STRAVA", "AUTO-DETECTED") | Activity Details | PARTIAL | Source badges in the Workouts log | source field |
| E21 | Edit start/end (2026: scrub on the HR graph), delete, nap → sleep; ••• action sheet | Activity Details | PARTIAL | `ManualWorkoutSheet` edit; no HR-scrub; delete exists | – |
| E22 | Auto activity detection + save/dismiss suggestion | Home card | PARTIAL | `AutoWorkoutDetector` + classic `AutoWorkoutCard`; not on Pulse Home | → coaching card |
| E23 | Activity lists: picker dropping from the pre-start header (ALL/STRAIN/RECOVERY/SLEEP, MOST RECENT, caps rows), SELECT ACTIVITY card list, SELECT YOUR ACTIVITY reclassify sheet, ~150 strain + 32 recovery types | Start / Add / Edit | PARTIAL | Sport list in `WorkoutTypeClassifier` / ManualWorkoutSheet; no categories, recents or reclassify sheet | extend the list |
| E24 | Start Activity pre-start: header with activity dropdown, Track Route toggle, map or backdrop, live HR circle with battery | Start Activity | PARTIAL | `WorkoutStartControl` is a two-step start; live HR exists; no pre-start screen | `LiveWorkoutView`, GPS recorder |
| E25 | Live Activity / Dynamic Island (HR, zone, time, distance, speed) | system | HAVE | Live Activities for live HR, sync, lift session (layout differs, M6) | – |
| E26 | Cardio vs Muscular strain split; muscular load | Activity Details / Strength Trainer | NOT POSSIBLE | `LiftMetrics` deliberately excludes it | WHOOP's muscular load is a proprietary IMU model with no public validated method; ZENO shows tonnage instead |
| E27 | Strength Trainer live set logging (sets × reps × weight), my workouts / programs | Strength Trainer | HAVE | Lift Log (programs, sessions, strap rest timer, Lift Live Activity) | – |
| E28 | Tonnage, total reps, per-exercise volume | Strength Trainer | PARTIAL | Tonnage, sets per muscle, e1RM (`LiftMetrics`); no per-workout summary card on Activity Details | `LiftMetrics` |
| E29 | WHOOP Workouts library (curated workouts, videos, NOVICE/ADVANCED) | Strength Trainer | NOT POSSIBLE | WHOOP's licensed video/content service | ZENO can bundle its own small template library (BUILDABLE) |
| E30 | AI-generated workouts / "Generate with AI" | Strength Trainer | PARTIAL | Needs the user's LLM provider in Coach | – |
| E31 | WHOOP Live photo/video overlay | Action menu, live screen | BUILDABLE | None | local photo + rendered overlay |
| E32 | Strain Target panel: toggle + target on the pre-start; expanded ring with draggable target and OPTIMAL arc; training-state chart (current / activity / estimated day strain) (new) | Start Activity | BUILDABLE | Live Session "Silent Guardian" band only | `optimalStrainRange` + `StrainScorer` projection |
| E33 | Live pager (new): Activity Strain ring with target knob and intensity word; HR + 6-segment zone bar; AVG HR / MAX HR / CALORIES; Map page; Heart Rate page | live | PARTIAL | `LiveWorkoutView` shows live HR, a zone rail, live strain on the Effort scale, and GPS distance + pace in one scroll. It has no pager, ring or map page | `ActiveWorkout`, GPS recorder |
| E34 | Recovery-activity pre-start (no Strain Target, light-blue circle, outline START) (new) | Start Activity | BUILDABLE | – | sport category |
| E35 | Recovery-activity details (new): MINUTES + STRESS CHANGE, STRESS / HEART RATE graph tabs, SESSION METRICS vs 30-day range, IMPACT ON RECOVERY (5 with / 5 without) | Activity Details | BUILDABLE | Breathe records pre/post RMSSD; no recovery-activity detail | stress curve, HR, `EffectRanker` on activity days |
| E36 | Activity milestone card ("13/25 · 12 more for next achievement") (new) | Activity Details | BUILDABLE | – | per-sport counts |
| E37 | ADD ACTIVITY sheet (new): banner, activity row, Start/End pills with inline wheel, LOCATION question, SAVE; invalid-duration validation | Add Activity | PARTIAL | `ManualWorkoutSheet` (sport, start, end, distance); no location question | – |
| E38 | Overlapping-activities check on manual add (new) | Add Activity | BUILDABLE | No overlap check in `ManualWorkoutSheet` | stored workouts and sleeps |
| E39 | "Not enough HR data" activity state ("---") (new) | Activity Details | BUILDABLE | – | sample coverage |
| E40 | Strength Trainer root (new): PROGRESS / MY WORKOUTS tabs, BUILD MANUALLY, workout rows with ••• (copy / share / delete) | Strength Trainer | PARTIAL | Lift Log programs (import/edit); different layout; no share | Lift Log store |
| E41 | Strength live session (new): REST / ACTIVE ring with count-up timers, NEXT exercise card, START SET → END SET, EXERCISES tab with per-set ▶ | Strength Trainer | PARTIAL | Lift Log live session + strap rest timer + Lift Live Activity; different flow | – |
| E42 | Total Volume Load trend (M/6M), Personal Records list, Exercise Details (Progress / History) (new) | Strength Trainer | PARTIAL | Tonnage and e1RM computed (`LiftMetrics`); no trend, PR list or exercise detail UI | `LiftMetrics` |
| E43 | Exercise instructions with photos and videos (new) | Exercise Details | NOT POSSIBLE | – | WHOOP's licensed media; ZENO can show text instructions only |
| E44 | Supersets (new) | Strength Trainer | BUILDABLE | Not supported in Lift Log | – |
| E45 | Strength activity details (new): workout chip, EXERCISES / HR ZONES, summary card (exercises, sets, tonnage, reps), per-exercise tables with PR medal, Exercise Summary | Activity Details | PARTIAL | A session summary exists in Lift Log; not on Activity Details | `LiftMetrics` |

## F. Health tab and health features

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| F1 | Live heart rate (BPM, zone, live line) | Health Monitor top | HAVE | Header live-HR chip; `LiveView` | `LiveState.heartRate` |
| F2 | Health Monitor vitals: RR, SpO₂, RHR, HRV, Skin temp with personal ranges | Health Monitor | HAVE | Health tab › HEALTH MONITOR rows with range bars (SpO₂ only when imported) | `BodyVitalSigns`, `VitalBands` |
| F3 | Status wording (within / near / low / elevated / very elevated) + "n/5 metrics within range" | Health Monitor / Home | PARTIAL | Icon + "4 of 5 in range"; no wording chips | z-bands |
| F4 | Health Report PDF (30 / 180 days, vitals with 6-month band) | Health Monitor | PARTIAL | `TrendsReportRenderer` makes a PDF trends report, not this format | reuse renderer |
| F5 | Stress score 0–3 + LOW/MEDIUM/HIGH | Stress Monitor | HAVE | Stress card + classic `StressView` gauge | `StressModel` |
| F6 | Last-updated time | Stress Monitor | BUILDABLE | Not shown | – |
| F7 | 24 h stress line incl. sleep, activity bands, now marker, zoom; day pager | Stress Monitor | PARTIAL | Waking-hours hourly curve for today; classic "Today's Timeline" | `DaytimeStress` extended to 24 h |
| F8 | TOTAL DAY time in LOW / MEDIUM / HIGH vs typical same weekday (+ % chips) | Stress Monitor | BUILDABLE | None | integrate the curve; same-weekday mean |
| F9 | Today's high-stress hours vs typical (Health-tab card) | Health tab | BUILDABLE | None | same as F8 |
| F10 | Stress explanation sentences ("You spent 40 min in the high stress zone on this day…", longest high-stress period) | Stress Monitor | BUILDABLE | None | run-length and totals on the curve |
| F11 | Non-activity and Sleep stress trends | Trend View | BUILDABLE | Daily stress series only | curve masks |
| F12 | Guided breathing sessions | Stress Monitor › Sessions | HAVE | Breathe (20+ protocols, strap haptic pacing; richer than WHOOP) | – |
| F13 | Stress notifications | Stress settings | PARTIAL | `StressOnsetDetector` breathing cue (ZENO extra); no evening summary | – |
| F14 | WHOOP Age | Healthspan | PARTIAL | Health › Healthspan "BODY AGE 30 yrs" tile | `VitalityEngine` (same published hazard-ratio basis) |
| F15 | Years younger / older vs chronological age | Healthspan | BUILDABLE | Not shown | Body Age − age |
| F16 | Pace of Aging (−1.0x … 3.0x) + weekly change chip | Healthspan / Health tab | BUILDABLE | Not computed | slope of the weekly Body-Age series |
| F17 | Pillar rows with 6-month / 30-day markers and years of age impact | Healthspan | PARTIAL | Inputs exist inside `VitalityEngine`; no per-row UI. LBM only via Apple Health | per-factor log-hazard → years |
| F18 | Age trend vs chronological; Pace of Aging trend | Healthspan | BUILDABLE | None | weekly series |
| F19 | Weekly update + "Next update in N days" | Healthspan | PARTIAL | Weekly series exist; no countdown | – |
| F20 | Healthspan unlocking state: dormant orb + "UNLOCK … N more days" progress card | Health tab | PARTIAL | "Needs a few weeks of wear" text | nights of data |
| F21 | VO₂ Max estimate (weekly) | Trend View / dashboard | HAVE | Healthspan tile "VO₂ MAX 52.0" | `vo2max_est` (`FitnessAgeEngine`) |
| F22 | Cardio fitness level + age/sex percentile scale | VO₂ card | BUILDABLE | None | published norms (FRIEND) |
| F23 | Manual VO₂ entry; "+ Update weight" | Trend View | PARTIAL | Weight via Apple Health import; no manual VO₂ entry | local entry |
| F24 | Menstrual cycle: cycle day, phase, next-period window | Menstrual Cycle Insights | PARTIAL | Health card (phase, "~day N") + "Log period start" (classic) | `CyclePhaseEngine` |
| F25 | Phase calendar with continuous bands, predictions, today ring | Menstrual Cycle Insights | BUILDABLE | None | logged starts + mean cycle length |
| F26 | Symptom / flow / cervical-mucus logging + symptom predictions | Menstrual Cycle Insights | BUILDABLE | None | new local log; predictions from the user's own symptom history |
| F27 | Phase coaching (sleep efficiency / strain / stress tolerance) | Menstrual Cycle Insights | BUILDABLE | None | rule text by phase |
| F28 | Current-cycle chart (skin temp, RHR, HRV, Recovery by cycle day) + cycle overlay on trends | Menstrual Cycle Insights / Trend View | BUILDABLE | None | existing series |
| F29 | Pregnancy & Postpartum insights (weekly RHR/HRV vs expected band) | Pregnancy Insights | BUILDABLE (approximate) | None | the expected band needs published reference curves; label it approximate |
| F30 | ECG (Heart Screener) readings, reports, failure tips | Heart Screener | NOT POSSIBLE | – | WHOOP 4.0 has no ECG electrodes (MG hardware); FDA-cleared algorithm |
| F31 | Irregular Heart Rhythm Notifications (AFib) | Heart Screener | NOT POSSIBLE | ZENO "Rhythm" (Poincaré) is explicitly non-diagnostic | regulated medical feature |
| F32 | Blood-pressure estimate (daily sys/dia range; BETA V2.0 page) | BP Insights | NOT POSSIBLE | – | needs WHOOP MG plus a cuff-calibrated proprietary model; no validated 4.0 path |
| F33 | Manual cuff-reading log with range chart | BP Insights | BUILDABLE | Lab Book can hold readings | Lab Book / Apple Health import |
| F34 | Advanced Labs: buy tests, appointments, clinician-reviewed report, action plan | Advanced Labs | NOT POSSIBLE | – | paid lab service + server |
| F35 | Lab results summary: biomarker ring, Optimal / Sufficient / Out-of-range counts, search, range bars, CSV | Advanced Labs | PARTIAL | Lab Book: private notebook (import readings, trend, history, compare with a signal) | user-entered reference ranges |
| F36 | Connect Health Records / Health Record Analysis (HealthEx, US) | Health tab / Integrations | NOT POSSIBLE | – | cloud OAuth service. Apple Health clinical records would need a HealthKit entitlement (UNCONFIRMED for this build) |
| F37 | Clinician video consults | Health (2026) | NOT POSSIBLE | – | paid service; no in-app entry seen |
| F38 | Health tab layout: orb whole at rest, half-sphere on scroll; 2026 card order (new) | Health tab | BUILDABLE | Different order; static tiles | layout only |
| F39 | Health Monitor day-1 banner ("…7 more nights to calibrate", 7-segment bar) + "Calibrating Range" chips (new) | Health Monitor | BUILDABLE | Calibrating text only | nights recorded |
| F40 | Menstrual 2026 page (new): Cycle Journal rows, Your Cycle Patterns (typical cycle, cycle history dot strips), YOUR SYMPTOMS, disclaimer card, "No Phase Predicted" | Menstrual Cycle Insights | BUILDABLE | None | logged cycles |
| F41 | Natural Cycles temperature sharing (new) | Integrations | NOT POSSIBLE | – | WHOOP 5.0/MG only (4.0 incompatible) and a partner cloud |
| F42 | Tier upsells on the Health tab ("Upgrade to Access", "More to unlock") (new) | Health tab | N/A | – | commercial |

## G. Coach and AI

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| G1 | AI chat grounded in your data | Coach sheet | PARTIAL | `CoachView` with the user's own key (OpenAI / Anthropic / Gemini) or a local OpenAI-compatible model; no built-in model | – |
| G2 | Daily Outlook (morning) | Coach / Home pill | PARTIAL | `CoachBriefScheduler` (widget + notification) | template fallback is BUILDABLE offline |
| G3 | Day in Review (evening recap + bedtime range) | Coach / Home pill | BUILDABLE | None | template from local data |
| G4 | Weekly Wrap (Coach) / Month in Review (e-mail); WHOOP has no in-app weekly or monthly screen | Coach / e-mail | HAVE | Weekly digest screen + PDF report (spec §3.40 restyles it) | `WeeklyDigest` |
| G5 | My Memory 2026: 3-page intro, empty/populated page, categories, memory detail with Active toggle + Relevant Conversations, global toggle | Profile › My Memory | BUILDABLE | None | local store injected into the prompt |
| G6 | Proactive check-ins (push, SMS) | notifications | PARTIAL | Coach brief notification; automations. SMS is not possible offline | – |
| G7 | Suggestion chips | Coach | HAVE | Empty-state suggestions | – |
| G8 | Voice input | Coach | HAVE | `CoachVoiceInput` | – |
| G9 | Contextual "EXPLORE YOUR … INSIGHTS →" entry from every dive | dives | BUILDABLE | None | opens Coach with context, or a local explainer when Coach is off |
| G10 | Charts generated in chat; manage activities from chat | Coach (2026) | BUILDABLE | None | tool calls → local charts and store writes (needs a provider) |
| G11 | Post-activity "Analyzing…" insights | Activity Details | BUILDABLE | None | template, or LLM if configured |
| G12 | v6 sheet header (version pill, Memory button) and action receipts ("✧ Logged Nicotine…") (new) | Coach sheet | BUILDABLE | Different header; no receipts | tool-call log |
| G13 | Conversation history list (WHOOP v5.3 clock; hidden in v6) (new) | Coach sheet | BUILDABLE | Not exposed | local thread store |
| G14 | Journal logging by text or voice through Coach ("Smart log" card) (new) | Journal | BUILDABLE | None | journal tool calls (needs a provider) |
| G15 | Coaching mode (Customized with your data / Education support) (new) | AI Settings | BUILDABLE | None | prompt switch |
| G16 | Reminders created in chat (new) | Coach | BUILDABLE | None | local notifications via a tool call (needs a provider) |

## H. Journal, behaviours, plan

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| H1 | Daily yes/no questions with follow-ups (amount, time) | Journal | HAVE | `InsightsView` journal log (yes/no + numeric) | – |
| H2 | Custom behaviours | Journal | HAVE | Custom questions, hide built-ins | – |
| H3 | Large catalogue (160–300+ behaviours, 9 categories) with fuzzy and synonym search | SELECT BEHAVIORS | PARTIAL | Starter set + groups | extend the list |
| H4 | Morning journal prompt after sleep processes ("USE PREVIOUS ANSWERS") | Journal | PARTIAL | Journal reminder card and notification | – |
| H5 | Journal calendar (month) + day strip | Journal | BUILDABLE | 7-day strip only | `nativeJournalDays` |
| H6 | Behaviour % impact on Recovery (hurts / helps, 90 days, significance) | Behavior Insights | PARTIAL | "Behaviour Effects" (Cohen's d, significance) in Insights; not expressed as % impact bars | `BehaviorInsights` / `EffectRanker` |
| H7 | Logging History 3-month calendar (Yes / No / Missing, monthly ✓ counts) | Behavior Details | BUILDABLE | None | journal history |
| H8 | Voice / text journaling via AI | Journal (2026) | PARTIAL | Needs a provider (see G14) | – |
| H9 | Weekly Plan: presets (Boost Fitness / Feel Better / Sleep Deeper), AI-built or custom goals | Edit Plan | BUILDABLE | None | new `PlanStore` |
| H10 | Plan progress %, goal counters, Friday check-in, Monday recap | My Plan | BUILDABLE | None | `DailyMetric` + journal + workouts |
| H11 | Mood and caffeine logging | (WHOOP: journal behaviours) | HAVE | Mood 1–5 check-in, caffeine log | – |
| H12 | 2026 Journal page (new): sand/purple themes, card rows, ✕/✓ toggles, follow-up capsules + time slider, NOTES, SAVE JOURNAL, DAYTIME/NIGHTTIME/STATUS | Journal | PARTIAL | `InsightsView` journal log in the classic look | – |
| H13 | Plan section inside the Journal ("YOUR … PLAN" with x/y rings) (new) | Journal | BUILDABLE | None | `PlanStore` |
| H14 | SELECT BEHAVIORS editor (new): category tabs, CURRENTLY / NOT SELECTED with question subtitles, Apple Health pre-fill line, Custom chip, SAVE BEHAVIORS | Journal | PARTIAL | Custom questions and hide built-ins in a different editor | – |
| H15 | Auto-tracked behaviours (✧) (new): 85%+ Sleep Performance, consistent bed/wake time, early/late workout, high-stress share, 10+ strain | Behavior Insights | BUILDABLE | None | `DailyMetric`, workouts, stress curve |
| H16 | KEEP LOGGING TO UNLOCK section (new): outlined locked cards with ☒/☑ counts and subtitles | Behavior Insights | BUILDABLE | Locked effects are not listed | journal counts |
| H17 | Behavior Details (new): impact card with verdict chip, follow-up bucket breakdown, Logging History, explanation + RECOMMENDATION | Behavior Details | BUILDABLE | None | `EffectRanker` + ZENO-written copy |
| H18 | WHOOP member average / "Members Like You" impact (new) | Behavior Details, Behavior Goal | NOT POSSIBLE | – | [POP] needs WHOOP's member population |
| H19 | Journal dismiss confirmation and save-error page (new) | Journal | BUILDABLE | – | local |
| H20 | PLAN OVERVIEW (new): time-goal card with per-activity zone minutes; day-circle count goals; metric goal cards | Plan Overview | BUILDABLE | None | `PlanStore` + workouts |
| H21 | Behavior Goal editor (new): days per week 1–7, suggested behaviours, ADD BEHAVIORS | Plan | BUILDABLE | None | `PlanStore`; without the [POP] chips |
| H22 | AI behaviour suggestions (add/remove) and AI-created custom behaviours (new) | Journal | BUILDABLE | None | offline suggestions from `EffectRanker` statistics; AI creation needs a provider |

## I. Trends

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| I1 | Trend View for every metric with W / M / 6M | Trend View | HAVE | `MetricDetailView` (W / 2W / 3W / M / 3M / 6M / 1Y / ALL), classic look | – |
| I2 | Header label variants (AVERAGE / WEEKLY TOTAL / AVG. WEEKLY TOTAL / AVG. HIGH STRESS; two-value Hours vs Needed) + delta chip (green / orange; grey for Recovery, Strain, Calories, 0%) | Trend View | PARTIAL | Stat row Average / Min / Max / Latest / Δ | – |
| I3 | Typical-range band | Trend View | PARTIAL | Personal-baseline rule for HRV / RHR once trusted | mean ± SD |
| I4 | One-line insight sentence | Trend View | BUILDABLE | None | template |
| I5 | Breakdown blocks (RECOVERY / STRAIN / HR ZONES / SLEEP EFFICIENCY / RESTORATIVE (DAYS or totals)) | Trend View | BUILDABLE | None | thresholds |
| I6 | Metric dropdown switcher | Trend View | PARTIAL | Explore lists every metric; no in-screen switcher | – |
| I7 | Year / all-time ranges | (WHOOP lacks; users ask for it) | HAVE (ZENO extra) | 1Y / ALL | – |
| I8 | "LEARN MORE" video library | Trend View | N/A | – | WHOOP content |
| I9 | M view: dashed average line with "AVG." pill. 6M view: dimmed data + monthly segments with coloured % change (new) | Trend View | BUILDABLE | Plain line or bars | series |
| I10 | Footnotes and CTA rows ("+ ADD ACTIVITY", "SET A STEPS GOAL IN WEEKLY PLAN") (new) | Trend View | BUILDABLE | – | – |
| I11 | Stacked-bar Trend Views (HR zones, restorative SWS/REM, stress HIGH/MEDIUM/LOW) (new) | Trend View | BUILDABLE | – | per-zone minutes, stage minutes, stress curve |

## J. Profile and gamification

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| J1 | Level by recoveries: 30-level ladder (Beginner → Diamond), Levels page with medal, progress caption and level grid | Profile › Levels | BUILDABLE | None | scored-recovery count; ladder in spec §3.30 |
| J2 | WHOOP Age card on Profile | Profile | BUILDABLE | – | `VitalityEngine` |
| J3 | Day Streak page: count, start date, max streak, this week, milestones (50-day steps above 1000), tier colours and messages | Day Streak | PARTIAL | `StreakCalculator` result in Settings only | `StreakCalculator` |
| J4 | Data Highlights: Best Sleep / Peak Recovery / Max Strain (1M / 3M / All time) | Profile | BUILDABLE | None | `DailyMetric` max |
| J5 | Streaks: 70%+ Sleep, Green Recovery, 10+ Strain | Profile | BUILDABLE | None | `StreakCalculator` variants |
| J6 | Notable stats: lowest / highest RHR and HRV, max HR, longest sleep, lowest recovery | Profile | BUILDABLE | None | `DailyMetric` min/max |
| J7 | Activity Summary (total activities, per-sport counts and avg strain, SHOW ALL) | Profile | PARTIAL | Workouts "Activity Breakdown" | workouts |
| J8 | Achievements: 5 badge families, grid with dates, filter chips, 0–6 star tiers for cumulative badges | Achievements | BUILDABLE | None | local rules; original badge art |
| J9 | Population comparisons ("Top 2% WHOOP", "Top 0.2%", rarity pyramid, "Only 35% of members hit this!") | Day Streak / Achievements | NOT POSSIBLE | – | [POP] needs WHOOP's population data (server) |
| J10 | Achievement Details (hero, criterion, milestone card, share), unlock modal (CLOSE / VIEW), share card (new) | Achievements | BUILDABLE | None | local rules; image render |
| J11 | Profile header (new): avatar, name, age • country, "✎ EDIT", "Member since" pill | Profile | PARTIAL | Settings › Profile holds the fields; there is no profile page | profile store |
| J12 | Edit Profile form with wheel-picker sheets; Save appears on change (new) | Edit Profile | PARTIAL | Settings › Profile and Units in the classic look | profile store |
| J13 | MY MEMORY row on Profile (new) | Profile | BUILDABLE | None | `MemoryStore` (G5) |
| J14 | Local challenges (new): join, in-progress and complete pages, plus a badge | Challenges | BUILDABLE | None | local goals over workouts and zone minutes |
| J15 | WHOOP-run challenges with fixed dates and rewards ("25% OFF YOUR NEXT ORDER") (new) | Challenges | NOT POSSIBLE | – | server-run events and commerce |

## K. Device, settings, data

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| K1 | Device status: connected-to name, battery, model, last sync / catching up | Device Settings | HAVE | `DevicesView` + strap chip | `LiveState` |
| K2 | Rename strap | Device Settings | HAVE | Supported (strap reboots to apply) | BLE |
| K3 | Broadcast heart rate toggle | Device Settings | PARTIAL | See the K3 note below the table | BLE |
| K4 | Pair / unpair | Device Settings | HAVE | Add-device wizard, device switching | – |
| K5 | Firmware check and update ("NO NEW UPDATES" dialog) | Device Settings | NOT POSSIBLE (update); PARTIAL (version read) | Firmware string is read | updates are WHOOP-signed images from its cloud |
| K6 | Reboot device | Device Settings | PARTIAL | `BLEManager.rebootStrap()` exists (rename also reboots); a user-facing Reboot button is UNCONFIRMED | BLE |
| K7 | Erase device data | Device Settings | NOT POSSIBLE (by design) | ZENO deliberately excludes destructive commands | safety |
| K8 | Heart-rate settings: max HR (edit), manual zone bounds, "View HR Settings" link | App Settings | PARTIAL | Max-HR override (Karvonen zones); no manual per-zone bounds | profile |
| K9 | Activity auto-detection toggle | App Settings | PARTIAL | Detector exists; settings toggle placement **UNCONFIRMED** | – |
| K10 | Hide Metrics (Recovery & Sleep, Weight/LBM, Healthspan) | App Settings | BUILDABLE | None | – |
| K11 | Units (imperial / metric), °C / °F | Edit Profile / App Settings | HAVE | Settings › Units | – |
| K12 | Data export (CSV by e-mail, once a day) | App Settings › Data Export | HAVE | Better than WHOOP: local CSV, .noopbak backup, Backup & Sync folder, Shortcuts export | – |
| K13 | Apple Health integration (Connect / Manage Permissions; import and export lists) | Integrations › Apple Health | HAVE | Apple Health page + import (classic look) | – |
| K14 | Partner integrations (Strava, Peloton, TrainingPeaks, Withings, Clue, Natural Cycles, Cronometer, Hyperice, HealthEx…) | Integrations | NOT POSSIBLE (live sync) | File imports exist for some sources (nutrition CSV, Mi Fitness, WHOOP CSV) | OAuth / cloud APIs |
| K15 | Notification settings (per type, frequency, time) | App Settings | HAVE | Notification settings + Automations | – |
| K16 | Account, MFA, membership & billing, family plan, extension | My Account | N/A | – | commercial / cloud |
| K17 | "✕ APP SETTINGS" root: 9 single-line rows (new) | More | PARTIAL | Settings holds the same items in sections, classic look | layout only |
| K18 | Integration Details template (new): hero, description, per-direction blocks with "Connected" + DISCONNECT | Integrations | PARTIAL | Data Sources pages exist in a different layout | import state per source |
| K19 | AI Settings with a Memory toggle (WHOOP 2026 has no Coach off switch) (new) | App Settings | PARTIAL | Coach on/off + provider setup; no memory toggle | `MemoryStore` |
| K20 | Device Settings states (new): "WHOOP DISCONNECTED" prompt, unpair "ARE YOU SURE?", pairing screens | Device Settings | PARTIAL | `DevicesView` states in the classic look | – |
| K21 | Research studies ("STUDY DETAILS", consent form) (new) | (Home / More) | N/A | – | WHOOP research programme |
| K22 | Privacy settings: team invitations, personalized product recommendations (new) | More | N/A | – | account / server |

**K3 Broadcast heart rate, detail:**
- **Phone re-broadcast (HAVE):** ZENO's `HrBroadcaster` re-broadcasts live HR from the phone as a standard BLE Heart Rate peripheral (Data Sources toggle, opt-in).
- **Strap-direct broadcast (PARTIAL):** the 4.0 command (`PuffinExperiment`) is experimental and its effect is unverified.
- **How to verify:** WHOOP's help article (10 Jun 2025) says WHOOP sensors broadcast through the standard BLE Heart Rate Profile. The 4.0 effect can therefore be tested on the device with any BLE HR app (e.g. nRF Connect or a gym console).

## L. Community and commerce

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| L1 | Teams root (banner, Teams •••, MY TEAMS with rank selector sheet, team rows with ranks, RECOMMENDED TEAMS), team pages (INFO / CHAT / STRAIN / RECOVERY / SLEEP leaderboards), invites, explore | Community tab | NOT POSSIBLE | – | needs a server and other members |
| L2 | Follow friends (leaked May 2026; roadmap Nov 2026; not shipped) | Community | NOT POSSIBLE | – | server |
| L3 | Shop, gift, refer & earn, extend membership, Discover More | More, Home | N/A | – | commercial |

## M. Widgets, Live Activities, notifications

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| M1 | Home Screen widgets: small (concentric rings, Recovery % + Strain); medium (rings + RECOVERY & HRV left, STRAIN & CALORIES right, battery) | widgets | PARTIAL | Widget code exists (rings, HR, Stress, Coach brief) but renders placeholders: free signing has no App Group | signing limitation, not a data limitation |
| M2 | Lock Screen widgets (battery ring seen; Sleep / Recovery / Strain gauges text-only) | widgets | PARTIAL | same as M1 | same as M1 |
| M3 | Live Activities | system | HAVE | live HR, sync, lift | – |
| M4 | Daily Recovery / Sleep notifications ("Recovery climbed overnight…") | notifications | PARTIAL | Coach brief notification | – |
| M5 | Low strap battery alerts | notifications | HAVE | Battery alerts + predictive runtime warning (extra) | – |
| M6 | Live Activity layout: ♥ bpm, blue stopwatch pill, 6-segment zone bar with labels (new) | system | PARTIAL | Live HR Live Activity exists; different layout | `LiveState` |
| M7 | Apple Watch Smart Stack layout (♥ bpm, elapsed, mini HR line, zone bar) (new) | watchOS | BUILDABLE | Live Activities mirror to the watch automatically, without a custom small layout | Live Activity small family |

## N. Onboarding and first run (new section)

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| N1 | Landing: photo, wordmark, "I HAVE A WHOOP DEVICE" + second option | onboarding | PARTIAL | `OnboardingWizard` Welcome step ("all your data, none of the cloud") in the classic look | restyle (spec §3.38) |
| N2 | Account: log in, create account, e-mail-first sign-in, password rules, MFA | onboarding | N/A | No account by design | – |
| N3 | Device tutorial: Unbox, Put On, Wake Up, Check for Pairing Mode | onboarding | PARTIAL | Bluetooth-priming and Wear steps | – |
| N4 | Pairing: SEARCHING FOR STRAP..., SELECT YOUR DEVICE, bonding over CONNECTING, CONNECTED, CONNECTION FAILED (RETRY / NEED MORE HELP?) | onboarding, Device Settings | PARTIAL | Scan step (radar) + Bonded celebration + add-device wizard; no success/failure screens in this style | – |
| N5 | Profile steps: name, country/state, Apple Health connect, birthday wheel, gender (+ physiological baseline) | onboarding | PARTIAL | One Profile step (age, sex, weight, height, units); no name or country | profile store |
| N6 | Membership card form, plan choice, referral, family-plan block | onboarding | N/A | – | commercial |
| N7 | Privacy and Terms checkboxes with SELECT AND AGREE TO ALL; NEXT disabled until required | onboarding | PARTIAL | `TermsGateView` (confirm each statement + "Accept & Continue") | restyle |
| N8 | "Setting up your Account..." spinner and account errors | onboarding | N/A | – | server |
| N9 | Push-notification pre-permission screen | onboarding | HAVE | Notifications step | – |
| N10 | "Welcome to WHOOP" splash + "What to Expect Next" calibration wheel | onboarding | PARTIAL | Expectations step + Done ("Your thread starts here.") | ZENO thresholds |
| N11 | Step template: bottom-anchored content, 78 pt ring CTA with a progress arc, filled commit circles | onboarding | BUILDABLE | Bottom "thread" progress + CTA | – |
| N12 | Day-1 Home: Get Started cards, Ask well, Looking Ahead, "Personalization in Progress" | Home | PARTIAL | see B18, B27, B28 | – |
| N13 | Calibration timeline with unlock thresholds per feature | help / Home | PARTIAL | ZENO has its own thresholds but no unified timeline view | engine thresholds |
| N14 | Getting Started checklist under More (6 mini-tutorials) | More | BUILDABLE | None | progress flags |
| N15 | Feature tours: Home tour cards with "✓ n" and one spotlight coach-mark ("Introducing achievements") | Home, Profile | BUILDABLE | None | – |

## O. Errors, dialogs and system states (new section)

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| O1 | Full-screen error page (red ring "!", "ERROR" / "YOUR ENTRY WAS NOT SAVED", RETRY / CLOSE) | global | BUILDABLE | Classic alerts | style for local store / BLE errors |
| O2 | Dialog cards ("OVERLAPPING ACTIVITIES … GOT IT", "NO NEW UPDATES … OKAY", "ECG READING FAILED") | global | BUILDABLE | System alerts | – |
| O3 | Network-required page, "server nap" page, "REQUEST FAILED", "HEADS UP saved locally" | global | N/A | – | ZENO has no network dependency |
| O4 | Toast "Failed to load. Please try again." | global | BUILDABLE | – | – |
| O5 | Inline validation banner ("Invalid duration. Activities cannot start or end in the future.") | Add Activity | BUILDABLE | – | – |
| O6 | Empty placeholders "--%", "-:--", "---", "No activities yet" | global | HAVE | "–" placeholders and empty copy | – |
| O7 | Membership expired banner, "No Data Available" tiles, "UPDATE REQUIRED" app gate | global | N/A | – | commercial / server |

## P. Year in Review and seasonal (new section)

| # | WHOOP metric / feature | WHOOP screen | Status | Where in ZENO / what's missing | Offline source or reason |
|---|---|---|---|---|---|
| P1 | Seasonal availability (Dec–Jan) + Home entry | Home | BUILDABLE | None | local calendar |
| P2 | Story chrome: ✕, "2025" lock-up, 7-segment progress, per-slide glow, tap/swipe | YIR | BUILDABLE | None | – |
| P3 | Days worn, level and membership length | YIR | BUILDABLE | Weekly digest only | `StreakCalculator`, recovery count |
| P4 | Month highlight slides (tick-ruler scrubber, month moment + badge) | YIR | BUILDABLE | None | `DailyMetric` extremes + local badges |
| P5 | Behaviour impacts on Recovery (year) | YIR | BUILDABLE | Insights has effects | `EffectRanker` |
| P6 | Steps total + Everest equivalence | YIR | BUILDABLE | Steps history exists | `StepsResolver` |
| P7 | "The Year You …" persona paragraph | YIR | BUILDABLE | None | template; LLM optional |
| P8 | Summary share card (age orb, level, streak, best sleep / peak recovery / max strain with dates, longest sleep, lowest recovery, top activity) | YIR | BUILDABLE | Exportable report exists | local image render |
| P9 | "Message to your future self" | YIR | BUILDABLE | None | local note (visual UNCONFIRMED) |
| P10 | Top-performer percentiles, "% of members achieved this", "vs WHOOP avg", Healthspan Comparison vs "Members like you" | YIR | NOT POSSIBLE | – | [POP] population data; ZENO compares with the user's own previous year |

---------------------------------------------------------------------------------------------------

## Summary counts (rows above)

| Status | Rows | Share |
|---|---|---|
| HAVE | 63 | 20% |
| PARTIAL | 105 | 34% |
| BUILDABLE | 106 | 34% |
| NOT POSSIBLE | 20 | 6% |
| N/A | 14 | 5% |
| **Total** | **308** | |

By section:

| Section | HAVE | PARTIAL | BUILDABLE | NOT POSSIBLE | N/A |
|---|---|---|---|---|---|
| A Shell & header | 3 | 5 | 6 | 1 | 1 |
| B Home cards, plan & dashboard | 4 | 19 | 5 | 0 | 2 |
| C Sleep | 14 | 12 | 7 | 0 | 0 |
| D Recovery | 7 | 4 | 3 | 0 | 0 |
| E Strain, activities, strength | 11 | 18 | 13 | 3 | 0 |
| F Health tab & health features | 5 | 11 | 18 | 7 | 1 |
| G Coach & AI | 3 | 3 | 10 | 0 | 0 |
| H Journal, behaviours, plan | 3 | 6 | 12 | 1 | 0 |
| I Trends | 2 | 3 | 5 | 0 | 1 |
| J Profile & gamification | 0 | 4 | 9 | 2 | 0 |
| K Device, settings, data | 7 | 8 | 1 | 3 | 3 |
| L Community & commerce | 0 | 0 | 0 | 2 | 1 |
| M Widgets & notifications | 2 | 4 | 1 | 0 | 0 |
| N Onboarding & first run (new) | 1 | 8 | 3 | 0 | 3 |
| O Errors & system states (new) | 1 | 0 | 4 | 0 | 2 |
| P Year in Review (new) | 0 | 0 | 9 | 1 | 0 |

Revision 1 counted 210 rows (60 / 78 / 52 / 15 / 5). The growth is mostly BUILDABLE screens from the gap-fill research, plus the new N, O and P sections.

**Reading of this:**
- Most WHOOP metrics already exist in ZENO's data layer, so the work is largely **presentation**: most PARTIAL rows are UI gaps over data ZENO already computes.
- Revision 2 adds many rows. Most are BUILDABLE screens (detail cards, activity flows, Journal 2026, Levels, Achievements, onboarding template, Year in Review) built from existing data.
- The genuinely new computations are few and all offline:
  - High Sleep Stress and the overnight stress card;
  - Pace of Aging / years younger;
  - stress time-in-levels vs typical weekday;
  - Strength Activity Time;
  - HR Zones 1-3 / 4-5 aggregates;
  - 30-day baselines with good/bad arrows;
  - the coaching-card rules;
  - Weekly Plan;
  - auto-tracked behaviours;
  - Profile highlights, the 30-level ladder and achievements;
  - the menstrual calendar, symptoms and predictions;
  - the strain-target midpoint tick;
  - sleep latency from bed marks.
- The NOT POSSIBLE set is fixed by:
  - hardware (ECG, BP estimate, Natural Cycles needing 5.0);
  - regulation (AFib notifications);
  - servers and other members (Community, Labs, HealthEx, clinicians, partner sync, WHOOP-run challenges);
  - population data ([POP] percentiles and "members like you");
  - WHOOP-only content (workout videos, exercise media);
  - proprietary models (muscular load);
  - firmware updates.

---------------------------------------------------------------------------------------------------

## ZENO-only extras worth keeping (and where they go in the WHOOP structure)

| # | ZENO extra | Today | Place in the new structure | Why keep |
|---|---|---|---|---|
| X1 | Fully offline, no account or subscription; data in local SQLite | global | Privacy line in More; "Everything stays on this iPhone" | Core differentiator |
| X2 | Bring-your-history imports: WHOOP CSV, Apple Health export, Mi Fitness, nutrition CSV, Oura ring (beta), multi-device registry, "Your Data, Fused" | More › Data | App Settings › Integrations; onboarding "Bring Your History" step | WHOOP cannot import other wearables |
| X3 | Data ownership: local CSV export, .noopbak backup/restore, Backup & Sync folder, Shortcuts export, PDF report | More › Data | App Settings › Data Export; More › Privacy & Data | Better than WHOOP's once-a-day e-mailed export (which even lacks steps) |
| X4 | Explore (every metric, full-res full-day HR), Compare (overlay 2–4 metrics + Pearson r) | More › Insights | Trends tab › INSIGHTS | No WHOOP equivalent |
| X5 | What moves you: ranked behaviour effects with Cohen's d and multiple-testing control, dose-response, metric relationships, activity cost per sport, personal experiment | Insights | Trends tab › WHAT MOVES YOU; Behavior Insights shows the simple % view | Deeper than WHOOP's % impact |
| X6 | Training load (CTL / ATL / TSB), readiness (ACWR, monotony) | Trends, classic Today | Trends tab card; optional dashboard item | Athlete-grade metrics WHOOP lacks |
| X7 | Tomorrow's Recovery forecast (± band) | Intelligence | Trends tab; coaching card "Tomorrow looks…" | Unique |
| X8 | Illness early-warning (skin temp + HR/HRV) | classic Today, Health | Coaching card + Health tab card + notification | Health value |
| X9 | Body clock / circadian phase, jet-lag and shift light plan | classic Sleep, Health | Optional Health-tab card; Sleep dive extra | Unique |
| X10 | Breathe: 20+ protocols, resonance-pace sweep, strap haptic pacing, coherence estimate, pre/post RMSSD | Breathe | Stress Monitor › SESSIONS; Action menu "BREATHE" | Far richer than WHOOP's two sessions |
| X11 | Haptic interval timer (strap buzzes WORK / REST) | Intervals | Start Activity › "Intervals" mode | Unique |
| X12 | Live Session "Silent Guardian" (recovery-gated HR band with strap nudges) | Guided session | Strain Target panel option; More › Tools | Unique |
| X13 | Mark moment (from "+" or strap double-tap) | Start sheet | Action menu "MARK MOMENT" | Unique |
| X14 | Strap automations: double-tap actions, inactivity buzz, HR-zone buzz, wrist on/off Shortcuts, battery prediction | Automations | App Settings › Notifications | Unique |
| X15 | Heart-rate recovery after workouts (1 / 2 / 5 min) | Workout detail | Activity Details card | Useful fitness marker |
| X16 | GPX / FIT export of GPS workouts | Workout detail | Activity Details ••• | Strava/Garmin interoperability without a server |
| X17 | Live Body Console (R-R list, RMSSD, signal trust), spot HRV reading | Live | Tap the Health Monitor HR strip; More › Tools | Power users |
| X18 | Rhythm (Poincaré, non-diagnostic) | More › Advanced | Optional Health-tab card in the Heart Screener slot | Closest legal analogue to ECG |
| X19 | Hydration tracker (strain-adjusted goal), caffeine log, mood check-in | classic Today, Journal | Journal questions + optional dashboard rows | Behaviour context |
| X20 | 1Y / ALL trend ranges, "What correlates" per metric | Metric detail | Trend View segments + card | WHOOP users ask for a year view |
| X21 | Fitness Age | Healthspan tile | Healthspan VO₂ row detail | Complements ZENO Age |
| X22 | Steps detail: goal, streak, best day, by-hour, goal notification | Steps | Steps Trend View extras | Richer than WHOOP |
| X23 | Lift Log programs (import/edit), e1RM, sets per muscle, strap rest timer | Lift Log | Strength Trainer (MY WORKOUTS, PROGRESS) | Real strength tooling |
| X24 | Bring-your-own or local AI coach, daily brief widget | Coach | Coach sheet; Daily Outlook | Private / local option |
| X25 | Siri / App Intents (Sync Strap, Mark a Moment, Buzz Strap, Ask Coach), Home Screen quick actions | system | keep (WHOOP has no Siri support) | Platform integration |
| X26 | Day swipe + calendar day picker | Home | keep on the date pager | Faster history browsing |
| X27 | Classic interface switch, Test Centre, power saving, diagnostics | More | More › INTERFACE / ADVANCED | Fallback and support |
| X28 | Apple Watch app (code present, not embedded) | – | future | Needs paid signing |
| X29 | **Pause / resume during a live workout** (`ActiveWorkout.pausedAt`) | Live workout | Live band "❚❚ / ▶" (spec §3.8) | WHOOP has no pause until its Nov 2026 rebuild |
| X30 | **End-workout confirmation** ("This stops recording and saves what's captured so far.") with discard | Live workout | End & Save dialog (spec §3.8) | WHOOP's flow is unconfirmed; users fear accidental ends |
| X31 | **Phone-side BLE heart-rate re-broadcast** (`HrBroadcaster`) to treadmills, Zwift, bike computers | Data Sources | Device Settings › Broadcast heart rate | Works whatever the strap firmware allows |
| X32 | **Coach conversation history list** with local threads | (new view over existing chat storage) | Coach sheet clock icon | WHOOP v6 hides history; users cannot find old threads |
| X33 | **Coach can be switched off** entirely | Settings | App Settings › AI Settings | WHOOP removed its off switch in 2026; users complained |
| X34 | **Weekly Digest screen** | Weekly digest | Trends › THIS WEEK (spec §3.40) | WHOOP has no in-app weekly or monthly review |
| X35 | **Pre-account onboarding import** of WHOOP / Apple Health history | Onboarding Import step | onboarding "Bring Your History" | Day-1 insights instead of a 4-week wait |

## Extras to add (cheap, offline; WHOOP users ask for these)

| # | Extra | Where | Evidence that users want it |
|---|---|---|---|
| Y1 | A toggle for the daily morning-recovery notification | App Settings › Notifications | Users cannot turn it off in WHOOP (Reddit, Sep 2026) |
| Y2 | Hide Stress (and Healthspan) in Hide Metrics | App Settings › Hide Metrics | Forum 2174, 16189 |
| Y3 | Perimenopause / menopause mode; "I don't know" for the last period | Hormonal Insights settings | Forum 13794 |
| Y4 | Rest countdown with a "− 1:00 +" stepper in Strength Trainer | Strength live session | Forum 14544, user mock-up `activity-flows-2026/g11` |
| Y5 | A ✕ on every Get Started / promo card, and reorderable Health-tab cards | Home, Health | Forum 15895, 15753 |
| Y6 | Custom behaviours as plan goals; weekly steps goals; no 30-min cap on zone goals; fewer-than-7-day strain goals | Weekly Plan | Reddit 1wjr6k6, 1ufgave, 1r5wvn0, 1u6kgpz |
| Y7 | Name and pin Coach threads | Coach history | Forum 14402 |
| Y8 | Steps and Strength Trainer detail in the data export | Data Export | Forum 14416 |
| Y9 | A Sleep Consistency Trend View with bed/wake-target history | Trend View | Forum 14787 |
| Y10 | Activity search that matches words inside names and synonyms ("gardening") | Activity lists | Forum 15184 |
| Y11 | Live HR strip back on the Health tab (optional) | Health tab | Forum 15753 |

---------------------------------------------------------------------------------------------------

## Recommended build list, ordered by visual impact

Effort: S ≈ under 1 day, M ≈ 1–3 days, L ≈ 3+ days for one engineer.
Files are in `noop/StrandiOS/Pulse/` unless noted.
Each step ends with a simulator screenshot compared against the cited reference images (DESIGN_RULES §10 checklist and `WHOOP_UI_SPEC.md` §5).

### P0: the shell and Home (what the user sees first)

| # | Item | Spec | Touches | Effort |
|---|---|---|---|---|
| 1 | **Theme rewrite.** Covers: viewport-fixed slate gradient; white-10% cards with no borders, plus the 4.5% detail fill; radius 12; type scale; semantic, HR-zone, sleep-stage and stress palettes; journal themes, AI-card, promo-border, activity-flow and onboarding tokens; label/numeral styles | §2 | `PulseTheme.swift`, `PulseComponents.swift` | M |
| 2 | **Floating glass tab capsule** Home · Health · Trends · More + Coach button + floating coach summary pill. Remove the floating "+" and the Coach tab. Add the bottom scrim and the 80 pt inset rule | §1.1–1.2 | `PulseRootView.swift` | M |
| 3 | **Home header**: avatar + streak pill (6 flame tiers), "‹ TODAY ›" pill pager, battery + strap dot; ZENO wordmark; sync/status banner; **sticky mini-ring row** | §1.4, §3.1 items 1–3 | `PulseHomeView.swift`, `PulseSnapshots` | M |
| 4 | **Dials**: 88 / 6 butt caps, "LABEL ›", press disc, **optimal-range band under the arc + midpoint target tick**; 260 / 15 deep-dive ring; mini rings | §2.5 | `PulseComponents.swift`, `PulseHomeView.swift` | M |
| 5 | **Monitor tiles** (Health / Stress) with status words and badges | §3.1 item 6 | `PulseHomeView.swift`, snapshot builder | S |
| 6 | **My Day.** Includes: the "+" square + Action popover (5 WHOOP items + Breathe + Mark moment); coach pill (template text) or the Ask row; TODAY'S ACTIVITIES with every chip state and Add/Start; TONIGHT'S SLEEP; MY JOURNAL; the **Menstrual card** | §1.3, §3.1 item 8 | `PulseHomeView.swift`, `PulseActionSheet.swift` | L |
| 7 | **My Plan card + My Dashboard.** Metric rows (value, good/bad ▲▼, 30-day baseline, including Sleep Debt and Weight), the Stress chart card, the Strain & Recovery chart, and **Customize Dashboard** | §3.1 items 9, 12; §3.13 | new `PulseDashboard*.swift`; reuse `EditableLayoutList` | L |
| 8 | **Past-day and new-member Home variants**: ACTIVITIES + single ADD, Journal/Plan/Dashboard kept; "Get Started" header and cards; Looking Ahead | §2.9, §3.1 items 10–11 | `PulseHomeView.swift` | M |

### P1: the three deep dives and their shared screens

| # | Item | Spec | Touches | Effort |
|---|---|---|---|---|
| 9 | **Deep-dive template.** Custom nav ("‹ TODAY ⓘ" with an achievement-chip slot), hero ring, notched callout with 30-day baselines and the WHOOP glyph rule, legend well. The summary pill, or the inline insight card when Coach is off. A local insight-text engine | §3.3–3.5, §2.6 | new shared view; `PulseRecoveryView`, `PulseStrainView`, `PulseSleepView` | M |
| 10 | **Sleep dive.** Covers: 3-segment levels; **new High Sleep Stress**; Last Night's Sleep (HR chart, WHOOP stage rows, selection, restorative, latency); the **four detail cards** (Hours vs Needed with WHOOP's need breakdown, Consistency, Efficiency, Sleep Stress); **7 Weekly Trends cards** | §3.3 | `PulseSleepView.swift`; StrandAnalytics (sleep-stress helper) | L |
| 11 | **Recovery dive**: Behavior Insights card (row and chip variants), Weekly Trends (Recovery, HRV, RHR, RR), restyled "What shaped it" (rpm / °C units fixed) | §3.4 | `PulseRecoveryView.swift` | M |
| 12 | **Strain dive**: Zones 1-3 / 4-5, Strength Activity Time, Steps contributors; above-range insight copy; Today's Activities; Weekly Trends (strain bars, stacked zone bars); restyled ZENO extras | §3.5 | `PulseStrainView.swift` | M |
| 13 | **Trend View**, one reusable screen. Covers: dropdown; header variants; delta chips with the grey rule; W / M / 6M / 1Y / ALL; AVG pill and monthly segments; range pager; typical band; breakdown blocks; footnotes; CTA rows; cycle overlay. Replaces pushes to the classic `MetricDetailView` | §3.12 | new `PulseTrendView.swift` | L |
| 14 | **Activity Details.** Covers: **0–21 Activity Strain**; zone rows; Key Statistics vs 30-day; milestone card; route card + share snapshot; HR recovery; the recovery-activity, strength and not-enough-HR variants | §3.6 | new view over the `WorkoutDetailView` data | L |
| 15 | **Start Activity flow.** Covers: pre-start with header picker and Track Route; Strain Target panel (ring + chart); live pager (strain ring, zone bar, stats, map, HR page) on the 0–21 scale; **pause**; End & Save dialog; Live Activity layout | §3.8 | `LiveWorkoutView` successor, `WorkoutStartControl` | L |
| 16 | **Add / Edit Activity sheets** + activity lists (picker, SELECT ACTIVITY, SELECT YOUR ACTIVITY) + overlap check + HR-scrub edit | §3.9 | `ManualWorkoutSheet` successor | M |

### P2: Health tab and the monitors

| # | Item | Spec | Touches | Effort |
|---|---|---|---|---|
| 17 | **Health tab 2026 layout.** Covers: ZENO Age orb (whole → half on scroll) or the unlock card; Pace of Aging; Lab Book card; 5-column Health Monitor card; Menstrual card; Stress card; extras; disclaimer | §3.20 | `PulseHealthView.swift` | M |
| 18 | **Pace of Aging + years younger** computation (weekly Body-Age slope) and Healthspan detail (orb, ruler, pillars with years impact, age trend) | §3.23 | StrandAnalytics (`VitalityEngine` helpers); new view | L |
| 19 | **Health Monitor detail** (calibration banner, live HR strip, tiles with within/near/low chips, Health Report PDF) | §3.21 | new view; `TrendsReportRenderer` | M |
| 20 | **Stress Monitor detail** (gauge, 24 h chart with day pager, explanation sentences, TOTAL DAY vs typical weekday, Sessions → Breathe) | §3.22 | new view; `DaytimeStress` 24 h | L |
| 21 | **Sleep Planner** (goal selector, suggested bedtime, time-in-bed bar, optimal window, alarm panel, schedule) | §3.11 | new view over `SmartAlarmView` logic | M |
| 22 | **Menstrual Cycle Insights 2026** (calendar, symptom predictions, Cycle Journal, phase coaching, current cycle, cycle patterns, disclaimer) + symptoms sheet + settings with a menopause mode | §3.24 | `CyclePhaseEngine` + new views | L |

### P3: secondary flows, engagement and polish

| # | Item | Spec | Touches | Effort |
|---|---|---|---|---|
| 23 | **Journal 2026** (themes, Smart log card, plan section, card rows, follow-ups, notes, SAVE JOURNAL, dismiss dialog, calendar) + **SELECT BEHAVIORS** | §3.17 | `InsightsView` data, new views | L |
| 24 | **Behavior Insights + Behavior Details** (auto-tracked behaviours, KEEP LOGGING TO UNLOCK, bucket breakdown, Logging History, recommendation copy) | §3.18 | `EffectRanker`, new views | L |
| 25 | **Weekly Plan** (store, Home card, PLAN OVERVIEW, Edit Plan, Behavior Goal and other goal editors, Friday check-in, Monday recap) | §3.19 | new store + views | L |
| 26 | **Coaching card stack** rules engine (all §3.14 cards) | §3.14 | new model + view | M |
| 27 | **Coach sheet v6** (version pill, Memory, chips, gradient composer, action receipts) + **history list** + **My Memory 2026** + AI Settings | §3.16, §3.33 | `CoachView` wrapper, new `MemoryStore` | M |
| 28 | **Profile, Levels (30-level ladder), Achievements (families, stars, details, unlock modal, share card), Day Streak tiers, Edit Profile**, achievement chip on the dives | §3.30, §1.5 | new views; `StreakCalculator` | L |
| 29 | **More tab** (WHOOP order, ZENO content, First Week checklist) + **✕ App Settings** subtree (Integrations, Integration Details, Data Export, Hide Metrics, Notifications, Units) + **Device Settings** (STATUS / ADVANCED, broadcast, NO NEW UPDATES dialog) | §3.31–3.33 | `PulseMoreView.swift`, `DevicesView` wrapper | M |
| 30 | **Onboarding restyle** (step template, ring CTA, device tutorial, pairing screens, profile steps incl. height/weight, privacy checkboxes, What to Expect Next, Day-1 Home) | §3.38 | `OnboardingWizard`, `TermsGateView` | L |
| 31 | **Strength Trainer restyle** (PROGRESS / MY WORKOUTS tabs, REST/ACTIVE ring, set state machine, rest countdown, PRs, Exercise Details, supersets) | §3.29 | Lift Log views | L |
| 32 | **Trends tab** hub content + **Weekly Digest** screen | §3.35, §3.40 | new views | M |
| 33 | Seasonal and optional: **Year in Review**, **local challenges**, ZENO Live overlay, expanded day HR timeline + tilt mode, widget restyle (blocked by signing) | §3.39, §3.41, §3.10, §3.7, §3.36 | new views, `FullDayChartView` | M each |

**Cross-cutting rule.**
- Every classic screen still reachable from the new UI must either:
  - be re-implemented in this design system (preferred: items 13–16, 19–20, 21, 23); or
  - be wrapped so it uses the slate gradient, white-10% cards, SF Pro condensed numerals, WHOOP vocabulary and the 0–21 strain scale.
- This fixes the "two design systems" and "Charge / Effort / Rest" inconsistencies listed in `notes/zeno-inventory.md` §8.
- It explicitly includes the live workout screen, which today shows Effort on a 0–100 scale.
