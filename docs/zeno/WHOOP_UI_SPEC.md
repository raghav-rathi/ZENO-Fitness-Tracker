# WHOOP_UI_SPEC: blueprint for rebuilding ZENO's iPhone UI on the current WHOOP app structure

Revision 2, synthesised 2026-10-02. It draws on:
- the six first-pass notes in `notes/` (appstore, whoop-site, help-center, reviews, design-language, zeno-inventory);
- the six gap-fill notes `notes/gap-1` … `gap-6`:
  - gap-1: deep dives below the fold and Trend Views;
  - gap-2: activity flows;
  - gap-3: onboarding;
  - gap-4: Health tab, More and settings;
  - gap-5: Journal, behaviours and Plan;
  - gap-6: Profile, Community, Year in Review and Coach;
- `DESIGN_RULES.md`;
- about 110 reference images I viewed myself to resolve conflicts. Pixel samples marked "sampled here" are mine.

Target: the WHOOP iOS app as shipped Oct 2025 to Oct 2026 (App Store 5.72.1, 28 Sep 2026). Device frame: 393 × 852 pt (iPhone 15/16/17 Pro), SF Pro, dark only.

All image paths below are relative to `/Users/raghavrathi/Downloads/Whoop-Apps-Handover/whoop-reference/`. They are a private local reference: **never copy them into the git repo.**

How to read the tags:

| Tag | Meaning |
|---|---|
| **[C]** | Confirmed: seen in at least one 2025–26 WHOOP image, and the image is cited. A YouTube storyboard (320 × 180 frames) confirms order and layout only; its wording stays [U]. |
| **[V]** | Variant: seen, but builds differ. The spec picks one and names the other |
| **[U]** | UNCONFIRMED: text-only, inferred, or occluded. Build it as written, but treat it as a guess |
| **[Z]** | ZENO decision: a deliberate deviation, mapping or extra, not a WHOOP fact |
| **[POP]** | Needs WHOOP's population or server data (percentiles, "members like you", other users). Cannot be reproduced offline; ZENO omits it or uses a personal substitute |

Companion files:
- `DESIGN_RULES.md` is the token sheet. Section 2 here restates it compactly and adds every token this synthesis confirmed.
- `METRIC_COMPARISON.md` covers each metric versus ZENO, ZENO's extras and the build order.

### What changed in revision 2 (read this first)
1. **Strain dial overlay corrected (§2.5).**
   - The light band is the **whole optimal strain range, drawn on the track under the blue arc**. The white tick is the **Strain Target, at about the range midpoint**, drawn over the arc. This is what `DESIGN_RULES.md` already said.
   - Four new measurements show the band sitting apart from the arc when today's strain is below the range.
   - The revision-1 rule ("band starts at the arc end, tick = range bottom") is withdrawn.
2. **Sticky header (§1.4).** Captures from Jul–Sep 2026 pin **only the mini-ring row**. The two-row version (header row plus rings) is a variant.
3. **Past-day Home (§2.9, §3.1).** Corrected from a full-page May 2026 capture:
   - the card is titled "ACTIVITIES" and has a single "+ ADD ACTIVITY" button;
   - there are no monitor tiles, coaching stack, coach pill or Tonight's Sleep;
   - **MY JOURNAL, My Plan and My Dashboard stay.**
4. **New-member Home (§3.1).** It has a "Get Started" header with the "+" button, Get Started cards, an "Ask a question, get support…" well, and Looking Ahead.
5. **Sleep deep dive (§3.3).**
   - Four detail cards sit between Last Night's Sleep and Weekly Trends: HOURS VS. NEEDED (with WHOOP's own need breakdown), SLEEP CONSISTENCY, SLEEP EFFICIENCY and SLEEP STRESS.
   - Weekly Trends has seven cards.
   - From about June 2026 the inline insight card gives way to a **floating coach summary pill**.
6. **Recovery and Strain deep dives (§3.4, §3.5).** Both gain Weekly Trends sections, the Behavior Insights card variants, and the **achievement chip** in the nav bar.
7. **Activity flows rewritten from device captures (§3.6–3.9).** Covers Start Activity pre-start, the Strain Target panel, the live pager, Add/Edit Activity and the activity lists. Revision 1 had extrapolated these from a marketing tile.
8. **Journal and Plan screens rewritten to the 2026 device UI (§3.17–3.19).** Covers the Journal, SELECT BEHAVIORS, BEHAVIOR INSIGHTS, BEHAVIOR DETAILS (Logging History), PLAN OVERVIEW and the Behavior Goal editor.
9. **Profile, Community and Coach added or updated (§3.16, §3.30, §3.34).**
   - Profile now covers Edit Profile, the Levels page with WHOOP's 30-level ladder, Achievements and badge families, Achievement Details, the unlock modal and Day Streak tiers.
   - My Memory and the Community root are now documented.
10. **New screens.**
    - Onboarding (§3.38).
    - Year in Review (§3.39).
    - Weekly/monthly review (§3.40). WHOOP has none in-app, so ZENO's Weekly Digest gets its own [Z] definition.
    - Local challenges (§3.41).
11. **Two items reclassified.** The SLEEP DEBT dashboard row and the sleep-need breakdown are **WHOOP features**; revision 1 wrongly listed both as ZENO extras.
12. **Tokens.**
    - The morning pill gradient now comes from device captures.
    - The Last Night's Sleep cards get a dimmer fill.
    - New token sets cover the activity flow, onboarding, Journal themes, AI entry cards and promo borders.

---------------------------------------------------------------------------------------------------

## 0. Guardrails and naming map [Z]

1. **Copy structure, order, proportions and behaviour, not brand assets.**
   - Do not use any of these:
     - the WHOOP wordmark, "W" puck or "WHOOP LIFE/PEAK" lock-ups;
     - 3-D illustrations (heart, house, dartboard, notebook, padlock, strap renders, clay onboarding art);
     - WHOOP Age orb artwork, achievement badge art, level medals, stock photos;
     - Proxima Nova or DIN fonts.
   - Use SF Pro and SF Symbols instead (`DESIGN_RULES.md` §0).
   - The palette hexes come from WHOOP's public developer brand PDF. That is fine for a private build, but never publish ZENO as WHOOP-branded.
2. **Name map.** Wherever WHOOP prints its own name, ZENO prints:

| WHOOP string | ZENO string |
|---|---|
| "WHOOP" wordmark above the dials, inside deep-dive rings, in the footer | ZENO wordmark (own thin geometric text logo, same 72 × 12 pt slot), or nothing inside rings |
| WHOOP Coach / WHOOP AI / "Ask WHOOP anything" | Coach / "Ask ZENO anything" |
| "Smart log with WHOOP AI" | "Smart log with Coach" |
| WHOOP Age | ZENO Age (backed by `VitalityEngine` Body Age) |
| WHOOP Live (photo overlay) | ZENO Live |
| "VIEW YOUR WHOOP COACH ANALYSIS →" | "VIEW YOUR COACH ANALYSIS →" |
| "Wear your WHOOP daily", "Your WHOOP is ready to go." | "Wear your strap daily", "Your strap is ready to go." |
| "I HAVE A WHOOP DEVICE" (onboarding landing) | "PAIR MY STRAP" |
| "WHOOP 2025" (Year in Review lock-up) | "ZENO 2025" |
| "WHOOP MEMBER AVERAGE", "Members Like You", "Top 2% WHOOP", "43% of members achieved this" | omitted [POP]; ZENO uses personal framing ("Your best", "vs your 90-day average") |
| Generic metric and feature names: Recovery, Strain, Sleep, HRV, Strength Trainer, Health Monitor, Stress Monitor, Healthspan, Pace of Aging, Sleep Planner, Trend View, My Day, My Plan, My Dashboard, Behavior Insights, Levels, Achievements | Keep exactly |

3. **One vocabulary.** The rebuilt UI must say Recovery / Strain / Sleep everywhere and show Strain on the 0–21 scale everywhere, including on the classic screens it still links to. ZENO's classic "Charge / Effort (0–100) / Rest" labels must not appear on the WHOOP-style path (`notes/zeno-inventory.md` §8). This includes the live workout screen, which today shows Effort 0–100 by default.

---------------------------------------------------------------------------------------------------

## 1. Global navigation

### 1.1 Bottom bar [C]
Evidence: `images/reviews/02-5kr-home-NEW-layout-oct2025.png`, `images/completeness-critic/16-*` (May 2026, full page), `images/help-center/61..68,91`, `images/reviews/r07,r44`, `images/profile-community-2026/75`.

- **WHOOP (Oct 2025 → Oct 2026):** a floating glass capsule with 4 tabs, **Home · Health · Community · More**, plus a separate floating **AI (Coach) button** to the right of the capsule.
  - Before Oct 2025 the bar was a docked full-width 4-tab bar with a floating white "+" FAB. Do not build that.
  - **[V]** A staged variant docks the bar and replaces More with a **Profile** tab: the avatar is the icon, with a small ≡ badge (`profile-community-2026/78`, Jul 2026; `/41`, Jun 2025). Not copied.
- **Geometry** (DESIGN_RULES §3):
  - Capsule: 64 pt tall, x = 12 → 305 pt (≈293 pt wide), bottom edge ≈21 pt above the screen bottom.
  - Each tab item: a 22 pt outline icon over a 10.5–11 pt Medium Title-Case label.
  - Selected item: white icon and label plus a soft rounded blob behind it (white ≈10%). Unselected items: white 50%.
  - AI button: 64 × 64 pt squircle (radius ≈22, **[U]**), 12 pt gap from the capsule, 12 pt from the right edge.
    - Fill: dark indigo gradient `#171728` → `#121A25`.
    - Ring: ≈32 pt, 1.5–2 pt, gradient `#8371FF` → `#5FB5FE`, around a white monogram.
  - Material: iOS 26 Liquid Glass (`.glassEffect`) when available, else `#252A30` → `#191E23` at 92%.
  - Scrim: content fades to black over the 28 pt above the bar; the strip under the bar is `#010101`.
  - The label "Community" truncates to "Commu…" at large text in WHOOP. ZENO's 3rd label is shorter, so this does not arise.
- **Icons (SF Symbols, `.regular`/`.light`, monochrome):**

| Tab | Icon |
|---|---|
| Home | `house` (WHOOP draws a house with a trend line; an original glyph is fine) |
| Health | `heart.text.square` or `bolt.heart` (WHOOP: heart with ECG line) |
| 3rd slot | see below (WHOOP: three-person group) |
| More | `line.3.horizontal` |

- **ZENO mapping [Z]:**
  - **Home · Health · Trends · More + Coach button.**
  - WHOOP's Community (teams, leaderboards, chat) needs a server and other users, so it cannot work offline.
    - The slot becomes **Trends** (`chart.line.uptrend.xyaxis`), the hub for Trend View and ZENO's analysis extras (§3.35).
    - Community members asked for exactly this swap: "a trends view tab should replace the community tab" (`notes/reviews.md` §5); others asked for Plan in that slot (forum 13182, 13849).
  - **Coach button visibility:**
    - Coach on and a provider configured: the button opens the Coach sheet.
    - Coach on but unconfigured: it opens Coach setup.
    - Coach turned off in Settings: hide the button and stretch the capsule to full width (16 pt margins). WHOOP removed its own Coach off switch in 2026; ZENO keeps one **[Z]**.
  - Remove ZENO's current black native tab bar, the separate Coach tab and the floating mint "+".
- **Behaviour:**
  - WHOOP sometimes opens on the Community tab after an update (a top complaint since Jul 2026). ZENO always launches on Home.
  - Re-tapping the selected tab pops to root, then scrolls to top (keep ZENO's current behaviour).

### 1.2 The AI (Coach) button and coach surfaces elsewhere [C]
Evidence: `images/help-center/71,72,82`, `images/reviews/r119`, `images/deep-dives-2026/19c,56,17c`, `images/activity-flows-2026/e01..e03`.
- **Floating AI button on pushed screens.** WHOOP keeps it on screens without the tab bar: deep dives, Trend View, Healthspan, Health Monitor, Stress Monitor, Activity Details, Strength Trainer, Behavior Insights.
  - Shape: a ≈56–64 pt squircle at 16 pt from the right and bottom safe edges, styled like the tab-bar button.
  - While the AI is generating, the button becomes a **pill** "◎ Analyzing…" (`help-center/82`).
- **Floating coach summary pill (2026)** [C `deep-dives-2026/19c` (Jun 2026), `56` (Sep 2026)]. On deep dives and Activity Details a dark rounded capsule sits above the home indicator, in place of the inline insight card:
  - ≈64 pt tall, radius ≈20, translucent `#2A2D3A`-ish with a soft violet glow;
  - W avatar circle at the left;
  - two lines of 15 pt white text summarising the page, e.g. "Your sleep was strong because the basics lined up: 87% performance…";
  - "⌃" at the right expands it into the Coach sheet.
  - When dismissed, only the round AI button remains. The dismissal rule is **[U]**.
  - WHOOP bug to avoid: raw markdown ("**87% performance**") shows in the pill. ZENO renders the bold properly.
- **"Ask WHOOP anything" floating bar** [V, `deep-dives-2026/17c`, Recovery past day, Aug 2026]: a floating composer (W avatar + placeholder `#9797A1` + mic `#9FB0E4`, fill `#20202C`, radius ≈32) over the bottom of the page.
- A known WHOOP bug: the floating button covers row accessories (the "Broadcast Heart Rate" toggle, the last Strength Trainer row's "•••"). ZENO adds 80 pt of bottom content inset on every screen that shows the button or pill.
- **ZENO [Z]:**
  - Show the summary pill on the Sleep / Recovery / Strain dives and Activity Details. With a configured provider the text comes from the LLM; otherwise it is the local insight sentence (§3.3–3.6).
  - Tap "⌃" → Coach sheet seeded with that page's context.
  - Hide the pill (button only) when Coach is off.

### 1.3 Action (+) button and menu [C]
Evidence: `images/reviews/03-5kr-action-button-menu.png`, `images/help-center/64-forum-2025-11-home-action-menu-open.jpeg`, `images/design-language/22-*.png`.
- **Placement:** a white rounded square on the right of the "My Day" section header (or the "Get Started" header for new members, §3.1), black "+" glyph.
  - Size: 36 pt (DESIGN_RULES), radius 12. The App Store default-size mock measures ≈30 pt and the large-text device ≈36 pt, so it scales with Dynamic Type. ZENO: `@ScaledMetric(relativeTo: .title3)` base 32 pt, minimum 44 pt hit area.
  - It is the only "+" in the app; there is no floating FAB.
- **Open state:**
  - The "+" morphs into an "✕" on a dark rounded square (`#2E3236`, white glyph).
  - A popover card opens: radius ≈20, opaque grey glass with a vertical gradient `#464D56` → `#32383D` (or flat `#40474F`), inset 16 pt from the screen edge, right-aligned to the button.
  - The content behind dims slightly (WHOOP shows a light dim/blur, sampled `#14171C`). **[V]**: the5krunner shows almost no dim.
- **Rows:** ≈50–54 pt pitch, no dividers. Each row: a 28 pt line icon (white 70%) and an UPPERCASE Bold label (≈13 pt default, tracked ≈10%, white).
- **Order** [C]: START ACTIVITY nearest the button.
  - When the popover drops down: **START ACTIVITY · ADD ACTIVITY · STRENGTH TRAINER · COMPLETE YOUR JOURNAL · CREATE WHOOP LIVE**.
  - When it opens upward (button low on screen): the same list mirrored.
  - Icons: stopwatch, plus, weight-lifter, notebook+pencil, camera.
- **[V] legacy (Aug 2025, do not build):** a full-screen dim with right-aligned rows, each a label + white 44 pt circle icon (CREATE WHOOP LIVE · MY JOURNAL · STRENGTH TRAINER · ADD ACTIVITY · START ACTIVITY) and a "−" close circle (`activity-flows-2026/a02`).
- **Animation [U]:** scale and fade from the trigger anchor (`.topTrailing`), 0.2 s (DESIGN_RULES §8).
- **ZENO mapping [Z]:**

| Row | ZENO destination |
|---|---|
| START ACTIVITY | Start Activity pre-start (§3.8). Fixes ZENO's two-step "Start workout → Workouts log → Start" |
| ADD ACTIVITY | Add Activity sheet (§3.9), with an activity list that also offers Sleep and Nap |
| STRENGTH TRAINER | Lift Log restyled as Strength Trainer (§3.29) |
| COMPLETE YOUR JOURNAL | Journal (§3.17) |
| CREATE ZENO LIVE | photo/video overlay (§3.10); hide this row until it is built |

  - After a hairline, at most **two** ZENO extras: **BREATHE** and **MARK MOMENT**.
  - Intervals, Live HR and Guided session move:
    - Intervals becomes an activity mode inside Start Activity.
    - Live HR becomes the Health Monitor heart-rate strip.
    - Guided session goes to More › Tools.
  - More rows would push the upward-opening popover past the header.

### 1.4 Home header elements [C]
Evidence: `images/appstore/ios69-01-home-overview.png`, `images/reviews/02-*.png`, `images/help-center/91-*.png`, `images/completeness-critic/16,24,25,26,02,13`, `images/onboarding/31a`, `images/reviews/r41,r114`.

Positions (y, pt): row centre ≈75 (63–87) on the 852 pt screen. There is no navigation title on Home.

- **Left: avatar plus streak pill.**
  - Avatar: circle 28–32 pt at x = 16. It shows one of:
    - the photo;
    - initials on a coloured disc ("IW" pink, "NR"/"JS" purple, "MO" green);
    - a generic person outline when there is no photo or name (`onboarding/31a`).
  - Streak pill: a dark capsule (≈white 10–12%, h 32) tucked under the avatar's right edge. It holds a flame glyph (≈14 pt) and the day count (13 pt Bold condensed, white).
    - **Hidden on past days**: neither past-day capture shows it (`completeness-critic/16`, `reviews/r57`), while every today capture does (`help-center/91`, `completeness-critic/25, 26`, `reviews/r114`, `onboarding/31a`). Two captures only **[U]**.
  - **Flame colour by streak length** [C `profile-community-2026/60..64`, `reviews/r48`, gap-6 §4.2]:

| Streak (days) | Flame |
|---|---|
| 1 to about 99 | yellow |
| about 100–179 | orange |
| 180–364 | red with a blue core |
| 365–999 | magenta-red |
| 1000–1999 | blue |
| 2000+ | gold |

  - The exact cut-offs for orange and magenta are **[U]**.
  - Tap the avatar → Profile (§3.30). Tap the flame → Day Streak (§3.30). WHOOP's tap targets **[U]**; ZENO splits them like this.
- **Centre: date pager.**
  - Outer capsule (white 10%, ≈143 × 32 pt) holds a white "‹", an inner lighter pill (white ≈18%, ≈84 × 32, radius 12) with the label, and "›".
  - "›" is white 40% and disabled on today; on a past day it is white and enabled (`completeness-critic/16`).
  - Label: "TODAY", or "WED, MAY 27" for past days (11 pt Bold caps, tracked).
  - **[V]** WHOOP shows a range "OCT 14 TO TODAY" when the current physiological cycle began on an earlier date. ZENO is calendar-day based, so it shows "TODAY" **[Z]**.
  - Tapping the inner pill opens the calendar sheet (ZENO extra, keep). Horizontal swipe on Home changes day (ZENO extra, keep).
- **Right: battery and strap icon.**
  - Battery: "65%" (13 pt Bold condensed, white 50–70%). A "⚡" prefix appears while charging ("⚡100%", `completeness-critic/16`). The figure turns red (`#FF4A5C` text) when low ("14%" red in `help-center/91`). ZENO keeps its ≤15% threshold; WHOOP's cut-off is **[U]**.
  - Strap: an outline icon (≈22 pt) with a 6 pt status dot. Teal `#00F19F` = connected and synced; grey = disconnected **[Z]**.
  - Tap → Device Settings (§3.32).
  - ZENO's live-HR chip leaves the header; live HR lives in the Health Monitor strip.
- **Compact sticky header** (pinned once the dials scroll off).
  - **Default** [C, Jul–Sep 2026: `completeness-critic/02`, `/13`, `health-more-2026/04`, `journal-plan-2026/32`]: **only the mini-ring row**, pinned under the status bar. It shows three 24 pt rings (2 pt stroke, DESIGN_RULES §5), each followed inline by its label "SLEEP", "RECOVERY", "STRAIN" (11 pt Bold caps), on the page gradient with no card.
  - **[V]** `reviews/r114` (1 Aug 2026) pins the avatar / date pager / battery row above the mini rings. `help-center/62` (Nov 2025) also shows two rows.
  - Build the mini-ring row only. Tapping a mini ring opens its deep dive **[U]**.

### 1.5 Deep dives (push) and back navigation [C]
Evidence: `images/appstore/ios69-02..04`, `images/help-center/71,72,74`, `images/deep-dives-2026/16,17b,18,57`, `images/design-language/26-*.jpg` (push slide).
- A dial tap shows the **pressed state**: the ring interior fills with a white 40% disc on touch-down (`design-language/25`). Release pushes the deep dive with a standard iOS slide (≈0.4 s, no zoom).
- **Custom nav bar**, no large title:
  - "‹" at left: a thin white chevron, ≈12 × 22 pt glyph, at x≈25.
  - Centred title: UPPERCASE Bold 12 pt, tracked ≈1.2 pt. It reads "TODAY" or the selected day ("WED, JUN 4"), or the screen name ("HEALTH MONITOR").
  - Right: one of the following.
    - An outlined ⓘ circle, 27.5 pt, white 50%, opening an explainer sheet (ZENO: `ScoringGuideView` content). Some ⓘ sheets are **light-themed** (`deep-dives-2026/49`, "✕ STRENGTH ACTIVITY TIME"); ZENO keeps them dark **[Z]**.
    - **(May–Sep 2026, staged rollout) an achievement chip** [C]:
      - a capsule ≈30 pt tall, radius 15, fill `#282D33`;
      - it holds the pillar's mini badge (≈18 pt: sleep hexagon, recovery shield, strain diamond) and a count (15 pt Bold).
      - Seen: Sleep "796" (`deep-dives-2026/18`, May 2026), Recovery "38" (`17b`, Sep 2026) and "307" (Green Monster, `profile-community-2026/83`), Strain "6" (`57`, Jul 2026).
      - Which badge the Sleep and Strain chips count is **[U]**. Tap → Achievement Details **[U]**.
    - ⚙ (Stress Monitor, Menstrual), a history clock (Coach), "?" (Sleep Planner), or "•••" (Activity).
  - The bar is transparent over the fixed gradient. Interactive swipe-back works.
  - **[Z] ZENO:** show the achievement chip once achievements are built (§3.30). The deep-dive explainer then moves to a "HOW IT'S CALCULATED ›" row at the end of the page. Until then, show ⓘ.
- **Modal flows** use "✕" at the top-left instead of "‹":
  - Device Settings, App Settings, AI Settings, Export, Journal, Customize Dashboard;
  - Sleep Planner (iOS 2026), Heart Screener;
  - Activity Details from Home **[V]**, Start Activity, Add/Edit Activity;
  - Strength Trainer, the Symptoms sheet, Year in Review.

### 1.6 Presentation catalogue

| Screen | WHOOP presentation | Close control | Evidence |
|---|---|---|---|
| Sleep / Recovery / Strain deep dive | push | ‹ | appstore/ios69-02..04 |
| Activity Details | modal full screen from Home rows; push from the Strain dive **[V]** | ✕ / ‹ | whoop-site/95, help-center/82 |
| Activity "•••" menu | iOS action sheet Edit / Delete / Cancel (Strength-Trainer-linked: Delete / Cancel) | Cancel | activity-flows-2026/d02, d05, d06 |
| Expanded day HR timeline (⤢) | full screen, landscape-capable | ✕ | help-center/106, activity-flows-2026/e04 |
| Start Activity pre-start | full-screen modal | ✕ | activity-flows-2026/a01, a04, a07 |
| Activity picker (from pre-start) | list dropping down from the header | ⌃ | completeness-critic/05 |
| Strain Target panel | white bottom panel; drag up to expand | drag down | activity-flows-2026/a05, a06 |
| Live activity | full-screen modal, no tab bar, horizontal pager | flag glyph (end) **[U]** | activity-flows-2026/b01–b05 |
| Add Activity | sheet with grabber (swipe-dismissable) | ✕ | activity-flows-2026/c01, s01 |
| SELECT ACTIVITY (add flow) | push | ‹ | activity-flows-2026/s01, s04 (storyboard) |
| SELECT YOUR ACTIVITY (reclassify) | bottom sheet | ‹ | activity-flows-2026/c02–c05 |
| Edit Activity | sheet | ✕ | activity-flows-2026/d03, d04 |
| Trend View | push | ‹ | help-center/81 |
| Customize Dashboard | full-screen modal, pinned bottom SAVE | ✕ | reviews/04 |
| Sleep Planner | modal (iOS) / push (Android) | ✕ / ‹ | reviews/r134, help-center/86 |
| Coach chat | bottom sheet with grabber, medium → large | swipe / grabber | reviews/r123, profile-community-2026/66 |
| Daily Outlook / Day in Review | opens the Coach sheet seeded with the outlook (2025-26); older builds pushed a "DAILY OUTLOOK" page | – | reviews/09, reviews/88 |
| Journal | full-screen modal (sand or purple gradient) | ✕ (+ dismiss dialog when unsaved) | journal-plan-2026/01, 07 |
| SELECT BEHAVIORS | sheet with grabber | ✕ | journal-plan-2026/02, 13, 14 |
| WHOOP AI from the Journal | bottom sheet over the Journal | grabber | journal-plan-2026/04 |
| Behavior Insights | push | ‹ | journal-plan-2026/20 |
| Behavior Details | push from Insights; modal from AI or a push notification | ‹ / ✕ | journal-plan-2026/26, 26a |
| Plan Overview / Behavior Goal | push | ‹ | completeness-critic/23, journal-plan-2026/30 |
| Edit Plan | modal | ✕ | reviews/r11 |
| Health Monitor, Stress Monitor, Healthspan, BP, Menstrual | push from the Health tab or Home tiles | ‹ | various |
| Heart Screener | modal | ✕ | whoop-site/53 |
| Profile, Achievements, Achievement Details, Day Streak, My Memory | push | ‹ | profile-community-2026/10, 04, 05, 15, 27 |
| Levels | push, **circular** outlined back button | (‹) | profile-community-2026/11 |
| Achievement / day-streak unlock | full-screen black scrim (≈85%) | CLOSE / VIEW | profile-community-2026/12, 65 |
| Edit Profile | push; pickers open wheel sheets | ‹ ; CANCEL / CONFIRM | profile-community-2026/77 |
| Device Settings | full-screen modal, tabs STATUS / ADVANCED | ✕ | reviews/r01, help-center/97 |
| App Settings | modal over the visible tab bar | ✕ | health-more-2026/08 |
| Integrations, Integration Details, Apple Health | push | ‹ | health-more-2026/08, 24 |
| Export data, AI Settings | modal | ✕ | health-more-2026/25, profile-community-2026/55 |
| Year in Review | full-screen story | ✕ | completeness-critic/10 |
| Onboarding | full-screen flow, no nav bar | ‹ (error screens: ✕ in a circle) | onboarding/15b, 22d, 13e |
| Error / confirmation dialogs | centred card over black | ✕ / GOT IT / CLOSE | activity-flows-2026/c06, c08 |
| Action menu | popover | ✕ (morphed +) | reviews/03 |
| Calendar day picker | sheet (ZENO extra) | Done | zeno |

### 1.7 Day model [C/Z]
- Home's date pager sets the day for Home and the three deep dives. Deep-dive titles mirror it ("TODAY", "WED, JUN 4").
- Past-day rules for Home are in §2.9.
- The Health tab always shows "now", as in ZENO today. Stress Monitor and Healthspan carry their own pagers ("‹ TODAY ›" / "‹ SUN, AUG 2 ›", "‹ AUG 19 - AUG 26 ›").
- **[Z]** ZENO's Sleep deep dive adds a "‹ LAST NIGHT ›" pager under the nav bar so nights can be stepped without leaving the screen. This is the same component as the Stress Monitor day pager.

### 1.8 ZENO target navigation map [Z] (WHOOP 2026 structure, adapted)
```
Floating capsule: Home · Health · Trends · More    + Coach button (sheet)   + coach summary pill on dives/details
Home (no nav title)
 ├─ header: avatar→Profile · flame→Day Streak · ‹ TODAY › (→ calendar sheet) · battery/strap→Device Settings
 ├─ [banner]  DATA CAUGHT UP / CATCHING UP / OFF-WRIST / LOW STRAP BATTERY
 ├─ SLEEP › / RECOVERY › / STRAIN ›  → Sleep / Recovery / Strain deep dives (push)
 ├─ coaching card stack (✓ n)  → per-card destination
 ├─ HEALTH MONITOR › (→ Health Monitor)  |  STRESS MONITOR › (→ Stress Monitor)
 ├─ My Day [+ → Action menu]        (new member: "Get Started" [+] with Get Started cards instead)
 │    ├─ Your Daily Outlook › / Your Day In Review › (or "Ask a question, get support…" row) → Coach sheet
 │    ├─ TODAY'S ACTIVITIES ⤢ (→ day HR timeline) · rows → Activity Details · + ADD ACTIVITY · ⏱ START ACTIVITY
 │    ├─ TONIGHT'S SLEEP › → Sleep Planner
 │    ├─ MY JOURNAL › → Journal · BEHAVIOR INSIGHTS → Behavior Insights
 │    └─ MENSTRUAL CYCLE INSIGHTS › (opt-in) → Menstrual Cycle Insights
 ├─ My Plan (active card or "Build Your Best Self") → Plan Overview / Edit Plan
 ├─ Looking Ahead (calibration, new members) → calibration timeline
 ├─ My Dashboard  CUSTOMIZE ✎ (→ Customize Dashboard) · rows → Trend View · STRESS MONITOR / STRAIN & RECOVERY charts
 └─ ZENO wordmark footer
Health ("HEALTH")
 ├─ ZENO Age orb (whole at rest, half-sphere when scrolled) → Healthspan
 │    before unlock: dormant orb + "UNLOCK ZENO AGE · N more days" card
 ├─ calibrating banner · PACE OF AGING → Healthspan
 ├─ LAB BOOK (Advanced Labs slot) → Lab Book
 ├─ HEALTH MONITOR → Health Monitor
 ├─ MENSTRUAL CYCLE INSIGHTS (opt-in) → Menstrual Cycle Insights
 ├─ STRESS MONITOR → Stress Monitor (+ Breathe sessions)
 ├─ ZENO extras: RHYTHM (opt-in, non-diagnostic), ILLNESS HEADS-UP, STEPS
 └─ disclaimer
Trends ("TRENDS")  [replaces Community]
 ├─ THIS WEEK summary → Weekly Digest (§3.40)
 ├─ metric rows by pillar → Trend View
 └─ INSIGHTS: What moves you · Explore · Compare · Weekly Digest · Report · Training load · Tomorrow's Recovery
More ("MORE")
 ├─ TOOLS [Z]: Workouts log · Lift Log · Interval timer · Live heart rate · Breathe · Guided session
 ├─ ACCOUNT & SETTINGS: Profile · Device Settings · App Settings (✕ list, §3.33) · Privacy & Data
 ├─ SUPPORT: How ZENO works · What's new · Report a problem · First week with ZENO
 ├─ ADVANCED [Z] · INTERFACE [Z] (Classic interface)
 └─ version line (in place of LOGOUT)
Profile (avatar): Levels · ZENO Age · Day Streak · My Memory · Achievements · Data Highlights · Activity Summary
Coach button → Coach sheet (Memory · history list [Z])
First launch → onboarding (§3.38) → Home in the new-member state
```

---------------------------------------------------------------------------------------------------

## 2. Design tokens
Base values are `DESIGN_RULES.md` (DR) and are restated so this file stands alone. **NEW** marks a token this synthesis confirmed or added, with its evidence.

### 2.1 Colour

**Page.**
- Viewport-fixed vertical gradient. Stops: 0.00 `#283339`, 0.23 `#1E262B`, 0.53 `#13181C`, 0.76 `#101518`, 1.00 `#0E1213` (DR §1.1).
- Bottom scrim under the floating bar: clear → black 95% over 28 pt.
- Never pure black elsewhere, except these:
  - the Healthspan detail and the 2026 Health tab top, which use near-black `#030304`–`#090909` so the age orb's glow reads (`appstore/ios69-05`, `reviews/r44`);
  - the Year in Review story (`#07080D`, §3.39);
  - full-screen error pages and dialog scrims (§3.37);
  - the strip under the tab bar.

**Surfaces (white overlays on the gradient, DR §1.2).**

| Token | Value | Use |
|---|---|---|
| card | white 10% | cards, tiles, rows, dial track, dividers, chart today-band. Weekly Trends cards measure page + ≈9% (`#323941` on `#1C232B`, sampled here on `deep-dives-2026/16`) |
| **detail (NEW)** | white ≈4–5% (`#202427` on `#14171C`, sampled here on `deep-dives-2026/19c`; `#252A2E` on `#1A1F23` on `/18`) | the "Last Night's Sleep" group only: the HOURS OF SLEEP card and the four detail cards (§3.3) |
| nested | +10% on a card | activity rows, in-card buttons, selected segments |
| well | black 50% | legend wells, segmented-control troughs |
| grid | white 5% (on a card) / 8% (on the page) | chart gridlines |
| dash | white 25% | dashed connectors, secondary lines |
| targetBand | white 27% (`#5C6063`–`#6C7073` measured) | strain dial band |
| pressDisc | white 40% | dial press |

- Solid fallbacks: `#2D3236` / `#2B2F33` / `#292C2E`.
- The coaching card is slightly darker than a standard card (≈white 7–8%); the peeking card under it is darker again (`#1B1F22`).
- **Banner well:** pure black at 100%, radius 12, used for the "DATA CAUGHT UP" bar, the status banners and the new-member "Ask a question" well (`help-center/91`, `completeness-critic/24`).

**Text.** primary `#FFFFFF` · button 85% · secondary 70% · tertiary 50% · disabled 40%.

**Semantic data colours** (DR §1.4; one meaning per hue).

| Token | Hex | Meaning |
|---|---|---|
| recoveryHigh | `#16EC06` (renders `#19EC06`) | Recovery 67–100% |
| recoveryMid | `#FFDE00` | Recovery 34–66% |
| recoveryLow | `#FF0026`; text `#FF4A5C` | Recovery 0–33%; "VERY ELEVATED" |
| strain | `#0093E7` | strain, activities |
| sleep | `#7BA1BB` | sleep, sleep chips |
| recoveryBlue | `#67AEE6` | neutral data, outline buttons, LOW stress, light-strain chips |
| **recoveryActivity (NEW)** | `#7EB2EB` circle / `#79ACE1` Home chip | recovery activities (sauna, meditation, breathwork): pre-start HR circle and Home chip (`activity-flows-2026/a07`, `e12`) |
| positive (teal) | `#00F19F` | favourable ▲▼, Optimal, Within range, plan progress, CTA |
| negative (orange) | `#FFA722` | unfavourable ▲▼, Poor, ALARM OFF, HIGH stress, out of range |
| neutral | white 50% (▲ / ●); `#848586` for the "Sufficient" segment | no meaningful change |

**Status tints** (24 pt badge squares and chips):

| Tint | Fill | Pairs with |
|---|---|---|
| teal | `#224A41`–`#245044` (teal 16% on a card) | teal ✓ or number |
| red | `#4C2B34` | red "!" |
| blue (LOW stress) | `#354550` | |
| orange | `#493F2D` (`#4E402F` for a HIGH stress value chip) | orange "!" |
| grey (pending) | white 10% | "–" |

**HR zones (sampled; replaces DR's "zones 4–5 UNCONFIRMED").**

| Zone | Hex | Sample source |
|---|---|---|
| Restorative / Zone 0 | `#FFFFFF` | |
| Zone 1 | `#ADC2CD` | `help-center/82` gives `#AEC2CD`; site table `#ADC2CD` |
| Zone 2 | `#479AC2` | `help-center/82` |
| Zone 3 | `#59B996` | `whoop-site/95`, lossless |
| Zone 4 | `#FCAC5D` | `whoop-site/95` |
| Zone 5 | `#FF6422` | `whoop-site/95` |

ZENO's current zones (`#7E8A94`, `#0093E7`, `#16C47F`, `#FFB020`, `#FF4A5C`) must be replaced. Live zone bars dim the inactive segments to dark tints of these hues (§2.5).

**Sleep stages (sampled from `help-center/79`, `whoop-site/52`, `deep-dives-2026/15`).**

| Stage | Hex |
|---|---|
| Awake | `#CBCBCB` |
| Light | `#A4A3F1` |
| SWS (Deep) | `#FA96F9` |
| REM | `#AC5AED` |
| Restorative swatch | a **diagonally split** square: pink `#FA95FA` top-left / purple `#AC58EC` bottom-right [C `deep-dives-2026/02`, `15`] |

ZENO's Oura palette in the hypnogram and the unused `PulseTheme.stage()` must be replaced.

**Sleep detail-card swatches (NEW, gap-1 §5).**

| Element | Hex |
|---|---|
| Healthy Minimum swatch | `#484C50` |
| Recent Strain swatch | strain blue |
| Sleep Debt swatch | `#C8C8C8` |
| Sleep Latency swatch | `#C8C8C8` |
| Wake Events swatch | `#CCCCCC` |
| Efficiency awake blocks / ticks | `#CACECD` / white |
| Consistency past-night bars | `#606468` |
| Consistency last-night bar | sleep blue |
| Consistency callout pill | fill `#101418`, text sleep blue |
| Optimal bed/wake dashes | `#A1A5A6` |
| Hours bar | gradient card colour → `#4C5C6C` → sleep blue (solid for the last third) |
| Need-breakdown well | `#1C2024` on a card `#2C343C` |
| "= baseline" dot ● | `#8C8C90` |

**Stress scale (sampled along the gauge in `appstore/ios69-10`).**

| Gauge angle | Hex | Note |
|---|---|---|
| −112.5° | `#67AEE6` | LOW (0.0–0.9) |
| −60° | `#5FB3E1` | |
| −20° | `#01F19F` | MEDIUM (1.0–1.9) |
| +20° | `#00F19F` | |
| +60° | `#E0B031` | |
| +112.5° | `#FFA722` | HIGH (2.0–3.0) |

Level words take `#67AEE6` / `#00F19F` / `#FFA722`.

**Gradients.**

| Gradient | Values | Use |
|---|---|---|
| AI text | `#8371FF` → `#6E9AFF` → `#5FB5FE`; arrow `#5FB9FF` | coach CTAs |
| AI border | `#4D3D8C` → `#31738C`, 1.5 pt | insight cards |
| AI input border | `#8A62FF` → `#50D3FF` | coach composer |
| **pillMorning (UPDATED)** | device `#887D6F` → `#374957` (sampled here on `completeness-critic/26`, Sep 2026); reviews notes `#847A6E` → `#374552`; chevron `#E8D3A9` while unread. The revision-1 value `#69655A` → `#283B45` came from a compressed site video and is withdrawn | Daily Outlook |
| pill read state (NEW) | plain card (`#2B3033`, sampled here on `help-center/91`) with a white "›" | Daily Outlook after it was opened |
| pillEvening | `#2D284D` → `#293F52`; chevron `#7FB3F9` | Day in Review |
| promo border | `#D876A9` → `#C343DA`, 1.5 pt; CTA text `#C14BCC` | "Your Home Has a New Look" |
| **Get Started border (NEW)** | 1.3–1.5 pt horizontal `#FF9C7E` → `#E38CAE` → `#D579C6` → `#C257E5` → `#B132FB`; fill `#2A2430` → `#251F2D`; CTA `#C452D0` (`onboarding/31a`) | first Get Started card, "Ready to get moving?" |
| **feature-announce border (NEW)** | `#7C64EC` → `#909CDC` → `#88CCE4`, 1.5–2 pt; fill `#202424`; CTA text violet → blue (`journal-plan-2026/11,15`) | "You Asked, We Delivered" cards |
| achievement promo border (NEW) | rose `#E3ACA5`/`#B47D76` → violet `#8A63A4` | "Introducing achievements" |
| **AI entry card (NEW)** | fill `#282C48` → `#243444` → `#203844`, 1 pt border `#4A427E`; TEXT button `#3C4058`; TALK button `#344060` → `#2C5064`, mic `#6BADFE`; sparkle `#68B0FC` (`journal-plan-2026/16`) | Smart log, Create Custom Behaviors, Share something new |
| My Memory row (NEW) | `#242440` → `#202B3D` → `#1D333E` | Profile "MY MEMORY" |
| **journal today (NEW)** | sand `#CEB18F` → `#B3A18D` → `#949488` → `#787A79` → `#545D64` → `#2C353E` → `#1A1D22` → `#111518` (flat from ≈36% of the height) | Journal for today |
| **journal past day (NEW)** | purple `#402D7C` → `#372869` → `#252048` → `#12161F` → `#101518` | Journal for a past day and the morning prompt |
| Daily Outlook page | `#776E61` → `#232D37` → `#111417` | Daily Outlook |
| Menstrual header | tinted by the **current phase** **[U]**, inferred from three captures | Menstrual Cycle Insights |
| Coach sheet | near-black with an indigo/violet glow at the top (`#1C2438` → `#04080C` behind the Journal); user bubble `#343850` | Coach |
| **live session page (NEW)** | `#2D383E` → `#1A2129` → `#0C1013` → `#181F27` | live activity |
| **Health unlock (NEW)** | page glow `#4B2151`; card fill `#1C1A27`, border `#604844` → `#AC28FC`; progress `#C450D4` on `#4C4857`; dormant orb rim `#C050D0`, speckles `#9854A4` (`health-more-2026/16`) | Healthspan still unlocking |
| achievement detail glow (NEW) | activity `#393266` → `#275364`; sleep `#546575`; 1% Club `#811C24` | Achievement Details |
| profile header glow (NEW) | follows the avatar colour, e.g. teal `#3C8C8D` → `#245154` → `#121619` (other colours **[U]**) | Profile |
| Year in Review (NEW) | page `#07080D` with a glow rising per slide (red `#521117`, indigo `#3C3B5A`, green `#2A5237`); "2025" text `#758FFE` → `#5CBEFF` | §3.39 |
| ECG (not buildable) | trace `#AC59F0`, button `#342D48` | Heart Screener |

Menstrual header by phase:
- menstrual: warm `#693A35` → `#4E2F2C` → `#2A2021` → `#101518` (`appstore/ios69-09`);
- luteal: purple `#40295B` → `#231D31` (`help-center/10,12`, `health-more-2026/07`).

**Menstrual phase colours.**

| Phase | Legend dot | Calendar band |
|---|---|---|
| Menstrual | `#FF7765` | `#BB5B4F` |
| Follicular | `#A4A3F1` | `#5A5C84` |
| Ovulatory | `#479AC2` | `#2C586D` |
| Luteal | `#AC5AED` | `#8047AE` (current), `#5E3882` (future) |

Symptoms are a white dot.

**Healthspan orb** (ZENO must draw its own art):

| Variant | Particles | Rim | Interior |
|---|---|---|---|
| younger: green | `#00ECAE`/`#04F0A3` | `#05B576` | `#005434` → black |
| about zero: teal | – | – | – |
| older: amber/gold | – | – | – |
| still unlocking (NEW) | magenta `#9854A4` | magenta `#C050D0` | grey `#54585B` |

The page-top glow on the Health tab uses the same hue.

**Activity-flow tokens (NEW, gap-2 §10; sampled on device captures).**

| Element | Hex |
|---|---|
| Pre-start header over the map | `#0A0D12` (translucent) |
| Pre-start strap-render backdrop | `#293239` → `#0D1114` |
| Pre-start HR circle (strain sport) | `#1C90DD`, halo `#31648F` |
| Pre-start HR circle (recovery sport) | `#7EB2EB`, mid halo `#384A60` |
| Bottom panel header / button area | `#FFFFFF` / `#F5F5F5` |
| Grabber, toggle track | `#E5E5E5` |
| Toggle knob (on) | `#000000` |
| START ACTIVITY capsule | `#0193E8`, white text |
| Live band | `#0193E9` |
| Live ring track | `#333740` |
| Live ring arc | `#132F5F` → `#025DA4` → `#0082D6` (bright at the head) |
| Map route | `#0A8AF0` |
| Map stats panel | `#0E1215` → `#171E26` |
| Add/Edit sheet | `#1D2429` (Add); `#232D32` → `#101517` (Edit) |
| Info banner | fill `#2E404E`, text `#6F93CB` |
| Validation banner | fill `#352B1A`, text `#D18D20` |
| Time pill | idle `#303538`; active `#00F29E` with dark text |
| Form activity row | `#373D42` |
| SAVE capsule | white; disabled `#282A2E` with dim text |
| Select-activity sheet | `#272E36` → `#13181C` |
| Select-activity search field | `#161B1F`, focus border `#8D949A` |
| Select-activity row card | `#2F3438` |
| Dialog card | `#27343C` → `#1B2228` over `#000000` |
| CARDIO / MUSCULAR bar | `#00588A` / `#0193E8` |
| Recovery-activity HR line | `#83AAD1` |
| Route-card share button and stats panel | `#171717` |
| Strength START SET button | outline `#60E0B0`; pressed fill `#05ED95` |
| Strength ACTIVE timer | ≈`#00EE93` |

**Onboarding tokens (NEW, gap-3 §2–3).**

| Element | Value |
|---|---|
| Page | `#262D33` → `#1F2428` → `#14171C` → `#111518` |
| Text field | fill `#0C1013` (darker than the page), 1 pt border `#25292C`–`#2B3034`, radius 10–12, h 44–45 |
| Field label | 12 pt Bold caps +1.5, `#C0C1C5` |
| Subtitle | 16 pt Regular, `#BEC0C2` |
| Validation | border `#E9AE54`, "!" `#F5AB3E`, message 14 pt `#F9AB3F` |
| Checkbox | 30 pt, radius 8–9, 2 pt white stroke; checked = white fill + black ✓ |
| Ring CTA track | `#282D30` |
| Ring CTA arc | `#65BAFD` → `#58A9EB` → `#4697D9`, round caps |
| Ring CTA disabled label/arrow | `#4B4F52` / `#484D50` |
| Commit / back circle | filled blue, or `#00F19D` green |
| Pairing success line | green with a glowing ✓ circle |
| Pairing failure | red ring `#D7001F`, red end dots |
| ERROR ring | `#FF0026` |

### 2.2 Type (SF Pro; DR §2 plus NEW sizes)
DR tokens:

| Token | Spec |
|---|---|
| heroScore | 58 Bold standard; % 32 |
| dialValue | 28 Bold condensed + monospacedDigit; % 20 |
| sectionTitle | 20 Semibold |
| subsectionTitle | 17 Semibold |
| tileValue | 22 |
| rowValue | 17 |
| body | 14 Medium |
| pillTitle | 14 Semibold |
| cardTitle | 12 Bold caps, +0.7 |
| secondary | 12 Semibold |
| navTitle | 12 Bold caps, +1.2 |
| label | 11 Bold caps, +1.0 |
| baseline | 13–15 Bold condensed, tertiary |
| axis | 11 Bold condensed |
| tabLabel | 10.5–11 Medium |

Minimum size 11 pt.

NEW sizes (default Dynamic Type, estimated from the cited images; all numerals Bold condensed + monospaced unless noted):

| Use | Size | Evidence |
|---|---|---|
| Health Monitor tile value | 34 (unit 14 tertiary) | help-center/87, AP 33 |
| Sleep detail-card value ("60%") | 34 (baseline 13) | deep-dives-2026/15, 18 |
| Activity Strain number (details) | 40, strain colour | whoop-site/95 |
| Live Activity Strain value | ≈70 (label 14 Bold caps; intensity word 13 caps grey) | activity-flows-2026/b01 |
| Live / stats values (HR, AVG HR, MAX HR, CALORIES) | 34 | b01 |
| Pre-start HR in the circle | ≈64 | a01 |
| Strength REST / ACTIVE timer | ≈44 | g07a |
| Trend View "AVERAGE" value | 34 (unit 15) | help-center/81 |
| Trend View insight sentence | 17 Regular (revision 1 said 15 Medium) | gap-1 §4.0 |
| Sleep Planner big times | 32 (AM/PM 15) | help-center/86 |
| Tonight's Sleep times | 24 | reviews/02 |
| Hours of Sleep "8:44" | 24 (baseline 12) | whoop-site/52 |
| Stress gauge value | 52, Bold **standard** width (hero) | appstore/ios69-10 |
| ZENO Age in orb | 40 (Healthspan) / 24 (compact header) | appstore/ios69-05 |
| Day Streak count | 72–80 Heavy | reviews/r48, profile-community-2026/37 |
| Profile highlight rings | 24 | reviews/r73 |
| Profile name / section titles ("Achievements", "Data Highlights") | 24 Semibold | profile-community-2026/21 |
| Levels "LEVEL 29" | 24 Bold caps tracked; tier "DIAMOND" 15 Bold caps grey | profile-community-2026/11 |
| Achievement count | 40–44 Heavy condensed (grid) / 88 (detail) | profile-community-2026/04, 05 |
| Weekly Trends section title | ≈22 Semibold | deep-dives-2026/16 |
| Onboarding step title | ≈25 Semibold, left-aligned | onboarding/15b |
| Journal question title | ≈28 Semibold, 2 lines (Sep 2026 may be 1 line ≈20 **[U]**) | journal-plan-2026/05 |
| Journal row question | 15 Medium | journal-plan-2026/07 |
| Smart log card title | ≈20 Semibold | journal-plan-2026/16 |
| Behavior Details title / impact value | 26–28 Semibold / ≈30 Bold | journal-plan-2026/26 |
| Sleep Planner headline | 20 Semibold, centred | help-center/86 |
| Large page titles ("Recovery Impact Analysis", "Cycle Day 3", "Electrocardiogram (ECG)", "Logging History") | 20–26 Semibold | appstore/ios69-08,09; journal-plan-2026/20 |

### 2.3 Spacing and layout (DR §3)
- Scale: 4 · 8 · 12 · 16 · 24 · 32 · 40.
- Page margin: 16.
- Gaps: 12 between side-by-side cards and stacked tiles/rows; 16 between different cards in a section.
  - The 2026 Health tab stacks its cards **24 pt** apart (measured on `reviews/r44`).
- Card padding: 16.
- Section rhythm: 40 above a section header (cap top); 24 from header baseline to the first card.
- Home dial row: three 88 pt dials, `HStack(spacing: 33)`, centres at x = 75.5 / 196.5 / 317.5. Labels 12 pt below the rings.
- Contributor rows: 53 pt pitch. Gradient pills: 48 pt.
- Monitor tiles: ≈174.5 × 96 pt at default text (138 pt at large text).
- Today's Activities rows: ≈56 pt. Dashboard rows: ≈56–60 pt. Activity chips: ≈93–100 × 38–40 pt.
- **Weekly Trends cards (NEW):**
  - plot ≈197 pt, 5 gridlines 49 pt apart, no y labels;
  - 7 columns on a 48 pt pitch, bars 14 pt;
  - highlight column ≈29 pt wide spanning the plot and the x labels.
- **Row lists (NEW):**

| List | Row height | Gap | Inset | Radius |
|---|---|---|---|---|
| More / settings | 56 pt (64 with a sub-line) | 10 pt | 16–20 pt | 12 |
| Journal behaviour cards | ≈64 pt | 12 | | 12 |
| Behavior Insights cards | ≈68 pt | 8 | | |
| SELECT BEHAVIORS rows | ≈52 pt pitch, no dividers | | | |

- Hit targets ≥ 44 pt; whole cards are tappable.

### 2.4 Radii (DR §4)

| Token | pt | Use |
|---|---|---|
| card | 12, `.circular` | cards, tiles, pills, "+" square, date inner pill, row lists |
| control | 10 | nested buttons, segmented control, onboarding fields |
| well | 8 | legend wells, chips, activity score chips |
| badge | 4 | 24 pt status squares, delta chips |
| journal toggle | 6 | ✕ / ✓ squares, plan day buttons |
| menu | 20 | action popover, Smart log card, coach summary pill, wheel-picker sheet top |
| dialog | 14–16 | centred dialog cards |
| sheet | 12 | top corners of the activity sheets |
| capsule | – | outline primary buttons, tab capsule, Sleep Planner selector, Journal day capsules, "SAVE JOURNAL", START ACTIVITY, onboarding pills |

### 2.5 Dials, rings and gauges

**Score dials (DR §5):**

| | Home | Deep dive | Mini (sticky) |
|---|---|---|---|
| Diameter | 88 | 260 | 24 |
| Stroke (arc = track width) | 6 | 15 | 2 |

- Track: white 10%. Start at 12 o'clock and run clockwise.
- Caps: **flat (butt) ends with ≈1/5-stroke corner rounding**, confirmed at full zoom on `reviews/02` (not round caps).
- Full circle: 100% for Sleep and Recovery, **21** for Strain.
- Colours: Sleep `#7BA1BB`, Recovery by zone, Strain `#0093E7`.
- **[V]** The 2026 marketing collage draws Sleep and Strain arcs with an angular gradient that darkens toward the start (`#004A74` → `#0093E7` over the first 70°). Every device capture is solid, so ZENO draws solid arcs.

**Strain target overlay [C, corrected in revision 2].**

Seven measurements, three of them sampled here:

| Source | Recovery | Strain (arc end) | Light band (on the track) | White tick |
|---|---|---|---|---|
| `help-center/91` (Nov 2025, sampled here) | 51% | 0.2 (3°) | **156°–224° = 9.1–13.1**, apart from the arc | 190° = **11.1** (band midpoint 11.1) |
| `completeness-critic/25` (Aug 2026, sampled here) | 36% | 4.3 (74°) | **142°–210° = 8.3–12.3** | 177.5° = **10.35** (midpoint 10.3) |
| `completeness-critic/16` (past day, May 2026, sampled here) | 81% | 9.8 (168°) | **≈200°–280° = 11.7–16.3** | ≈237° = **13.8** (midpoint 14.0) |
| `reviews/02` (Oct 2025) | – | 9.8 (168°) | visible to 219° (12.8); its start is hidden under the arc | 187° (10.9) |
| `appstore/ios69-01/04` (mock) | 85% | 14.2 (242°) | visible to 277° (16.1) | 251° (14.6); card text says "target 15.5" |
| `reviews/r41` (Sep 2026) | – | 16.8 (288°) | visible to ≈320° (18.7) | ≈267° (15.6), **drawn over the blue arc** |
| `deep-dives-2026/57` (Jul 2026, deep-dive ring) | – | 20.7 (355°) | fully covered | 180° (10.5), drawn over the arc |

The rule, which matches DR §5:
- **Band** = today's optimal Day Strain range [low, high]. Draw it in `targetBand` (white 27%) on the track, **under** the strain arc. Where current strain is above the low end the arc covers that part; when strain is below the range the band floats apart from the arc.
- **Tick** = the Strain Target, observed at the **midpoint of the range**. It is a 1 pt white radial line at full stroke height, drawn **over** the arc.
- **When Recovery is not scored yet**, neither band nor tick is drawn (`completeness-critic/24, 26`, `onboarding/31a`).
- **Range width.** Observed ranges are 4.0–4.7 strain wide and move with Recovery %: 36% → 8.3–12.3, 51% → 9.1–13.1, 81% → 11.7–16.3. These come from different members and are personalised.
- **ZENO [Z]:**
  - The range comes from `CoupledView.optimalStrainRange` (14–18 / 10–14 / 4–10 by Recovery band). Interpolating the range continuously with Recovery % is optional.
  - The tick sits at the range midpoint (16 / 12 / 7).
  - Move the "Strain target reached" automation to fire at the tick, not the range bottom, so the haptic, the coaching card "Strain Target Reached" and the dial agree.

**Pressed dial:** fill the interior disc with white 40% on touch-down, release over 0.15 s.

**Stress gauge (measured on lossless `appstore/ios69-10`; 2026 device `completeness-critic/14,15`).**
- Size: outer diameter **≈212 pt**, bright stroke **3 pt**.
- Sweep: **225° symmetric about 12 o'clock** (−112.5° … +112.5°), running clockwise from LOW to HIGH. The value maps linearly: 0.0 → −112.5°, 3.0 → +112.5°. The 2026 device captures look slightly wider (≈240°) **[V]**.
- The bright gradient stroke (stress scale) has a dimmer inner tinted band of the same hue (≈10–12 pt wide at ≈15% opacity, **[U]**).
- Needle: a white capsule ≈4 × 22 pt pointing inward from the arc, with a fading tail toward the centre.
- End labels "0.0" / "3.0": 11 pt Bold condensed, white 50%, under the arc ends.
- ⓘ (27.5 pt) at the gauge's top-right.
- Centre:
  - the value, 52 pt Bold;
  - the level word, 11 pt Bold caps in the level colour;
  - a time line, 12 pt at 70%: the 2026 device shows the time only ("10:49 PM", `completeness-critic/14`); the App Store mock shows "Last updated 3:05pm".

**Live Activity Strain ring (NEW) [C `activity-flows-2026/b01–b04`].**
- Size: ≈288 pt outer diameter, 16 pt stroke, centred ≈376 pt from the top.
- Track `#333740`. The arc runs from 12 o'clock clockwise with the navy → bright gradient (§2.1), brightest at its head.
- Target knob: a ≈22 pt circle with the user's avatar (photo or initials) and a short white radial tick, sitting on the ring at the activity Strain Target **[U meaning]**.
- Centre: "ACTIVITY STRAIN", the value (≈70 pt), and the intensity word in grey caps. "RESTING" and "MODERATE" are seen; the other words are **[U]**.

**Live HR zone bar (NEW) [C b01, g07a, completeness-critic/27].**
- A full-width bar of **6 segments, Zone 0 → Zone 5**.
- The current segment is lit in its zone colour with a white position dot; the other segments are dark tints of their colours.
- Labels "Zone 0" … "Zone 5" sit under it (11 pt Title Case; the Live Activity uses bold caps "ZONE 0"). The current label is white; the others are dimmed tints.

**Pre-start HR circle (NEW) [C a01, a07].**
- A filled circle ≈181 pt (strain blue `#1C90DD`, or `#7EB2EB` for recovery sports) inside a ≈30 pt translucent halo.
- Content: white heart (22 pt), HR (≈64 pt), and a battery row ("▭ 75%", 14 pt).

**Strain Target ring (light theme, NEW) [C a05].**
- A ≈300 pt ring on `#F5F5F5`: light track and a navy → bright blue arc.
- A white knob with the brand mark at the arc end, which the user drags.
- A dashed "OPTIMAL" arc outside the ring with curved text.
- Centre: "ACTIVITY STRAIN" (black Bold caps), value (black ≈80 pt), "OPTIMAL" (grey caps), and a reset icon in a thin circle.

**Onboarding ring CTA (NEW) [C `onboarding/15b, 22b–d, 20b–d`].**
- A 78 pt control: centreline radius 36 pt, stroke ≈5.6 pt. Its outer edge sits 29 pt from the right screen edge and its centre ≈86 pt above the bottom.
- Track `#282D30`. The progress arc starts at 12 o'clock, runs clockwise with **round caps** and the light-blue angular gradient, and shows **progress through the flow** (Welcome ≈24%, card form ≈46%, Privacy ≈50–55%).
- A white "→" sits inside. The step label is to the left (≈11 pt Bold caps tracked, 15 pt gap), vertically centred.
- **Disabled:** the label and arrow turn grey (`#4B4F52`); the arc still shows.
- **Variants:** a filled ≈72 pt circle for commit steps ("START PAIRING", "GET STARTED") and a green `#00F19D` circle for back or finish actions.

**Levels progress (NEW) [C `profile-community-2026/11, 56`].**
- A 6 pt capsule ≈280 pt wide (fill `#BCBDBF` → `#FCFCFC`, track `#161920`, thin dark outline) between two level plaques.
- Caption "1 more Recovery to Level 30" (14 pt, 70%). At the maximum level the bar is replaced by "Congrats! You've reached the highest level!".

**Pace of Aging ruler (Healthspan) [C].**
- A full-width comb of ≈120 thin vertical ticks (≈1.5 pt × 16 pt, white 25%); major ticks are taller at −1.0x, 1.0x and 3.0x.
- Ticks near the needle are brighter. The needle is a white 2 pt line, 28 pt tall.
- Scale labels under the comb: "-1.0x · 1.0x · 3.0x" (11 pt Bold condensed 50%).
- Above the comb: "○ Slow" left, the value "0.8x" (17 pt Bold) centred over the needle, "Fast ◔" right.

**Plan goal counters [C `reviews/r114`, `journal-plan-2026/34`]:**
- ≈40 pt rings. **Count goals** split into one dashed segment per target day, with completed segments teal; the text inside reads "5/7".
- **Time and value goals** use a solid ring ("0:27", "269.4"). A met ring is green `#0CE8A0` (13 pt Bold condensed text).

**Profile highlight rings [C `reviews/r73`, `completeness-critic/09`]:** ≈88 pt rings with a 6 pt stroke, value 24 pt. Labels below: "Best Sleep", "Peak Recovery", "Max Strain" (14 pt Semibold Title Case), plus the date in the Year in Review card.

### 2.6 Component catalogue (all [C] unless tagged)
1. **Card:** `RoundedRectangle(cornerRadius: 12, style: .circular).fill(.white.opacity(0.10))`. No border, no shadow. The detail variant uses white ≈4.5% (§2.1).
2. **Section header:** 20 pt Semibold Title Case at x = 16. Optional right accessory: the "+" square, "CUSTOMIZE ✎", "EDIT ✎", or "VIEW ALL →" (11 pt Bold caps + 12 pt glyph, white). Profile and Achievements use 24 pt titles with a grey count: "Achievements (34)".
3. **Card title row:** UPPERCASE 12 pt Bold tracked (white) with a "›" (13 pt, white 50%) inline after the title at default text, or at the top-right at large text. Optional right icon ⤢ or ⓘ.
4. **Monitor tile:**
   - 174.5 × 96, padding 16. Title + "›".
   - Status row (12 pt below): 24 pt badge square (radius 4, tint) holding ✓ / "!" / "–" or a value ("1.5", 13 pt Bold condensed in the level colour).
   - Beside the badge: status word (11 pt Bold caps tracked, semantic colour) over a secondary line (12 pt Semibold, 70%).
5. **Coaching card stack:**
   - Card at ≈white 7–8%, radius 12, padding 16.
   - Title: 15 pt Semibold white. Body: 14 pt Medium, 70%, up to 4 lines.
   - Top-right counter chip ≈26 × 36 (white 12%, radius 6) with ✓ (top) and the remaining count (bottom, 12 pt Bold).
   - A peeking second card underneath: inset 16 pt each side, 11–12 pt visible, `#1B1F22`.
   - Feature variant: transparent or tinted fill, a gradient border (§2.1 promo variants), illustration at the right, CTA in gradient or magenta caps "LEARN MORE →", "CREATE NOW →", "VIEW ACHIEVEMENTS →".
   - Error variant: dashed 1 pt border (`#30383C`), amber "!" tile, grey (`#888C90`) text "Couldn't load new notifications. We'll try again later." (`health-more-2026/23`).
6. **Gradient pill:** 48 pt, full width, radius 12, morning or evening gradient. Content: 20 pt line icon (sun / moon) + 14–16 pt Semibold Title Case text + "›" in the tinted chevron colour.
   - Read state: plain card fill with a white "›" (`help-center/91`).
   - Variant label: "<first name>'s Daily Outlook", with the name as typed ("jake's Daily Outlook", `completeness-critic/26`).
7. **Activity row** (inside Today's Activities):
   - Nested fill (white 10% on the card), radius 10, ≈56 pt tall, 12 pt inset.
   - Left chip: ≈96 × 40, radius 8. Chip content: white SF glyph + value, 17 pt Bold condensed (sleep duration "6:41" or strain "5.4").
   - Name: UPPERCASE 12 pt Bold ("SLEEP", "NAP", "ACTIVITY", "CYCLING", "DEDICATED PARENTING"; up to 2 lines).
   - Right: two stacked times, 12 pt, 70% (start "[Wed] 11:03 PM" over end "6:21 AM"), followed by a 2 pt × 24 pt vertical bar in the activity colour (white for sleep rows).
   - **Chip states [C]:**

| State | Chip | Evidence |
|---|---|---|
| Sleep / nap | `#7BA1BB` fill; moon glyph, or reclining-person glyph for NAP | completeness-critic/02 |
| Strain activity | `#0093E7`; sport glyph + one-decimal strain | |
| Recovery activity | `#79ACE1`; glyph + duration "0:20" | activity-flows-2026/e12 |
| Unscored sleep | sleep fill with a moon + **struck-through bar-chart glyph** and no number | completeness-critic/26 |
| Strain pending (just ended) | sport glyph + small bar-chart glyph in place of the number | activity-flows-2026/g24 |
| Pre-added / not yet happened | **outlined** chip (dark fill, thin grey border) with glyph + struck chart glyph; the right bar is **dotted** | reviews/r57 |
| Auto-detected unknown | generic star-jump glyph, name "ACTIVITY" | completeness-critic/16 |

8. **Contributor callout** (deep dives):
   - Pointer triangle 15 × 7 at top centre.
   - Fill: radial glow (white 10% at the pointer → 0 by 190 pt) with a top-lit 1 pt stroke. No flat fill.
   - Rows: 53 pt pitch. Icon 20 pt at x+20 (white 50%). Label (11 pt caps) at x+49.
   - Right side: value 17 pt Bold condensed, with the **30-day baseline** beneath in 12–13 pt Bold condensed 50% [C 2026 `help-center/71,72`, `deep-dives-2026/17b`, `57`; absent in the App Store mocks].
   - Trend glyph (▲/▼ 6 pt, or ● 4 pt) to the right of the value, ending 22 pt from the card edge.
   - Dividers: white 10%, inset 16.
   - Legend well: h 31, radius 8, black 50%, inset 16, 12 pt below the last row.
9. **Trend glyph colour = good/bad, not direction** [C 2026 device rule].
   - Every non-zero difference is coloured by favourability, even a one-point change: "SLEEP PERFORMANCE 74% ▼ / 75%" is orange and "RESPIRATORY RATE 15.8 ▲ / 15.5" is orange (`deep-dives-2026/17b`).
   - A **grey ● replaces the arrow when today equals the baseline** (`#8C8C90`, `deep-dives-2026/02`).
   - Neutral-direction metrics always use a grey ▲/▼: WEIGHT "88.5 ▲ / 88.3" (`journal-plan-2026/32`).
   - **[V]** The 2025 App Store mock draws RR ▲ grey.
   - Favourable direction per metric: HRV↑, RHR↓, RR↓, Sleep Performance↑, Sleep Consistency↑, Hours↑, Restorative↑, Sleep Needed↓, Sleep Debt↓, Sleep Stress↓, Steps↑, Zones↑, Strength time↑, Recovery↑, VO₂↑.
   - **[Z]** ZENO default = this WHOOP rule. An optional "hide small changes" setting may grey |z| < 0.5.
10. **Insight (coach) card:**
    - 16 pt margins, radius 12, 1.5 pt AI border gradient, transparent fill, padding 16.
    - Body: 14 pt Medium white (2–4 lines). 12 pt gap, then the CTA: 11 pt Bold caps tracked, AI text gradient + "→".
    - **Only AI/coach content uses this gradient.**
    - 2026 placement: still inline on the Strain dive, Activity Details and recovery-activity details; replaced by the floating summary pill on the Sleep dive (from ≈Jun 2026) and dropped on the Recovery dive (Sep 2026) **[V]**.
11. **Legend chips / wells:**
    - "▬ Poor ▬ Sufficient ▬ Optimal": dashes 12 × 3 in orange / `#848586` / teal; labels 12 pt, 70%.
    - "▲▼ Today vs. last 30 days": ▲ teal, ▼ orange; "Today" white Semibold.
12. **Mini 3-segment bar:** 3 × (20 × 4 pt), 2 pt gaps, radius 1. The active segment is coloured; the others are white 12%.
13. **Status chips:**
    - teal tint with ✓ ("✓ within 13.8 - 14.8 rpm", "✓ Optimal", "✓ You're on the waitlist.");
    - orange tint with "!" ("! Out of Range", "! low < 95");
    - grey ("• Sufficient", "• no change vs. last week").
    - Pills: radius 6, 11 pt Semibold.
    - **Delta chips:** see the Trend View colour rule in §2.7.
14. **Segmented control:** a black-50% well, radius 10, h 36. The selected segment is white 10%, radius 8.
    - UPPERCASE 12 pt Bold labels: white when selected, otherwise 50% ("W | M | 6M", "1M | 3M | ALL TIME", "STRESS | HEART RATE", "EXERCISES | HR ZONES").
    - "STATUS | ADVANCED" and "LIVE SESSION | EXERCISES" use an underline variant.
15. **Range pager:** "‹ MAY 9 - MAY 15, 26 ›" in 12 pt Bold caps, white "‹", "›" white 40% when disabled.
16. **Buttons:**
    - (a) nested in-card button: white 10% on the card, radius 10, h 40–44, icon + UPPERCASE 12 pt Bold text at 85%;
    - (b) outline capsule: 2 pt `#67AEE6` stroke + `#67AEE6` text (Customize "SAVE"), or a white 1.5 pt outline + white text (Sleep Planner selector, "ADD SLEEP", "RETRY", recovery-sport "START ACTIVITY");
    - (c) white filled capsule with black UPPERCASE text ("SAVE JOURNAL", "SAVE", "GOT IT", "SAVE BEHAVIORS", "RETRY" on 2026 pairing screens);
    - (d) text CTA, UPPERCASE + "→" (AI gradient for coach, `#67AEE6` for "EXPLORE PLANS →", magenta `#C452D0` for Get Started cards);
    - (e) the white 36 pt "+" square;
    - (f) blue filled capsule "START ACTIVITY" (`#0193E8`, ≈273 × 49) on the white Start Activity panel.
17. **Hatched track:** 45° lines, 1 pt, every 4 pt, white 7%. Used for the empty part of zone, stage, stress-level and impact bars, and the efficiency awake track.
    - Typical-range box: two dashed vertical 1 pt lines (white 50%) with a lighter hatch between them.
18. **Zone row card** (own 10% card per zone):
    - "ZONE 4" 12 pt Bold caps, then "162-171 BPM" or "(80-90%)" (12 pt Bold, 70%), then "2%" (12 pt Bold in the zone colour).
    - Right: "0:00:48" with ":48" smaller and 50% grey.
    - Below: zone-coloured rounded bar (h 14, radius 4) over the hatched track, plus the typical-range box.
    - Zero zones are drawn at 40% opacity.
19. **Stage row:**
    - Radio circle (22 pt, 1.5 pt white ring; selected = white dot), then the stage label (12 pt Bold caps), the % in the stage colour, and the duration right (15 pt Bold condensed).
    - Below: a bar in the stage colour over the hatched track with a typical-range box.
    - Selected-stage variant: rows show a **barcode timeline** of when the stage occurred, and the HR chart recolours that stage (`whoop-site/52`, `deep-dives-2026/11`).
20. **Diverging impact bar:**
    - A 4 pt white-core centre dot in a dark ring, on a hatched track (`#44484C` stripes).
    - Bar colours: helps = green bar to the right (`#00F0A0`); hurts = orange to the left (`#FCA420`); not significant = grey `#949498`.
    - Value at the right, ≈17 pt Bold, in the bar colour ("+8%", grey "+2%", "-3%").
    - The Behavior Details version is wider, with a ≈30 pt value. Its thin white "member average" tick is [POP] and is omitted in ZENO.
21. **Journal answer toggles:** two 32 pt squares, radius 6, 7–8 pt apart, ≈15 pt from the card's right edge.
    - ✕ selected = white fill, black ✕.
    - ✓ selected = blue `#67ADE8`–`#78ACE0` fill, near-black ✓.
    - Unselected = translucent grey (`#3D4144` on a dark card; `#594F81` on a purple card), white glyph.
22. **Row list (More / settings):**
    - Separate rounded cards: radius 12, h 56 (64 with a sub-line), 10 pt gaps, fill `#2F3438` (2025) / `#2D3035` → `#292D30` (2026).
    - Each row: a 28 pt outline icon (`#6C7074`) at x≈34, an UPPERCASE 12–13 pt Bold tracked label at x≈82, an optional sub-line (13 pt, `#BCBCC0`) and "›".
    - Section headers: UPPERCASE 12 pt Bold `#C4C4C4` tracked with a trailing hairline rule ("ACCOUNT & SETTINGS", "ADD TO MY DASHBOARD", "MY WORKOUTS").
23. **Achievement chip (NEW):** capsule ≈30 pt, radius 15, `#282D33`, mini badge ≈18 pt + count 15 pt Bold (§1.5).
24. **Floating coach summary pill (NEW):** §1.2.
25. **Row card with subtitle (NEW):** card ≈72 pt (`#282C2C`), leading icon (`#999DA0`), cardTitle, subtitle 15 pt Regular `#C8C9CB`, "›" (Behavior Insights compact row, `deep-dives-2026/17c`).
26. **Notched well (NEW):**
    - An inset card (`#1C2024`, radius ≈10, inset 16 inside its parent card) with a ≈9 pt notch on its top edge pointing up at a value.
    - Rows on a ≈23 pt pitch: 10 pt swatch + mixed-case label (15–17 pt Medium) + value (17 pt Bold condensed).
    - Used for the HOURS VS. NEEDED breakdown (`deep-dives-2026/18`).
27. **Count badges (NEW):** "☒ 51 ☑ 18". Small outlined squares (✕ and ✓, ≈20 pt) followed by a 13 pt Bold count; the badge for the side with few answers is dimmed (`completeness-critic/21`).
28. **Outlined locked card (NEW):** 1 pt grey border, transparent fill, radius 12. It holds the title + "›", a grey subtitle, a flat hatched track with only the centre dot, and count badges (KEEP LOGGING TO UNLOCK).
29. **White bottom panel (NEW, the one light surface):** the Start Activity panel (§3.8). A white header row with a grabber and a light-grey body. Black text and controls.
30. **Dialog card (NEW):**
    - A centred card (gradient `#27343C` → `#1B2228`, radius ≈14) over black or a deep dim, with "✕" at the top-right.
    - Content: a white Bold caps title, grey centred body, and a white filled capsule ("GOT IT", "CLOSE", "LEARN MORE") with an optional outlined second action ("TRY AGAIN").
31. **Full-screen error page (NEW):**
    - Black or dark gradient page with a 95 pt red ring (4.7 pt, `#FF0026`) holding "!".
    - Title "ERROR" or "YOUR ENTRY WAS NOT SAVED" (15–16 pt Bold caps), grey body, an outlined white capsule "RETRY" and a "CLOSE" text button.
32. **Onboarding step template (NEW):** §3.38.
33. **AI entry card (NEW):**
    - A gradient card (§2.1), radius ≈20, ≈108 pt tall.
    - Content: a sparkle + 20 pt title, then two equal buttons "⌨ TEXT" / "mic TALK" (≈160 × 40, radius 12).
    - Optional caption below ("Your answers are saved automatically").
34. **Get Started / feature card (NEW):**
    - ≈140 pt tall, inset 15 pt. Title 17 pt Semibold, body 14 pt 70%, magenta caps CTA + "→".
    - Original illustration at the right. Only the first card carries the gradient border; the rest are plain `#1D2124`.
35. **Filter chips (NEW):** h ≈34, radius ≈12, 8 pt gaps. Selected = white fill with black 15 pt Medium text; unselected = `#363D45` with white text (Achievements, Exercise Details, My Memory, Menstrual chart).
36. **Wheel-picker sheet (NEW):**
    - Bottom sheet (`#182023`, grabber 36 × 4, top radius ≈20) with a 20 pt Semibold title.
    - An iOS wheel with a rounded selection band (`#26292E`).
    - Two buttons, h 52, radius 14: "CANCEL" (outlined) and "CONFIRM" (solid; grey `#424649` when invalid).
37. **Day-circle row (NEW):**
    - MON–SUN caps labels (today white) over ≈28–36 pt circles.
    - Journal: green ✓ filled = logged, ring = not logged, grey fill with a white ring = today pending.
    - Plan: blue ring + blue dot = done, grey "–" = rest/skip, dashed ring = future.

### 2.7 Charts (DR §7 plus NEW)
- **Container:** 10% card, padding 16, UPPERCASE title top-left, ⓘ or "›" top-right. Gridlines are horizontal only (white 5%). Axis labels: 11 pt Bold condensed, 50%.
- **Today highlight:** a white 10% rounded column (radius 6) behind the current x, with its two-line x label ("Thu / 5") in white; the others are 50%.
- **Weekly Trends card chart (NEW) [C `deep-dives-2026/07..10,13,16`]:**
  - 5 gridlines incl. the baseline, **no y labels**;
  - 7 columns, highlight column `#44484C` (≈29 pt, radius 6) behind the last day;
  - value labels above bars in the series colour (one decimal for strain, "%" for percentages, h:mm for durations);
  - x labels "Wed" (13 pt) over "5".
- **Weekly bars** (Sleep Performance, Hours vs Needed %, Recovery, Strain, Steps, Sleep Consistency):
  - Rounded-top bars ≈14 pt wide in the series colour (sleep `#7BA1BB`, strain `#0093E7`, recovery by zone).
  - Value label above each bar: 12 pt Bold condensed in the series colour; percent labels use "%".
- **Stacked bars (NEW):** HR ZONES 1-3 (Zone 1 bottom → 3 top), HR ZONES 4-5 (4 bottom, 5 top), RESTORATIVE SLEEP (REM bottom / Deep top). A white h:mm total sits above each bar; "0:00" on empty days. Stress Trend Views use 100%-stacked HIGH / MEDIUM / LOW bars.
- **Floating range bars (NEW):**
  - TIME IN BED: bed → wake bars on an **inverted** unlabelled time axis, with the bedtime above and the wake time below (12 h, no AM/PM).
  - SLEEP CONSISTENCY card: 5 nights, 14 pt bars on a 49 pt pitch, past nights `#606468` and last night sleep blue. Last night gets callout pills (bedtime above, wake below, 15 pt Bold condensed, fill `#101418`). Two dashed (≈6/4) spline curves `#A1A5A6` mark the optimal bedtime and wake time. Left time labels run in 4–5 h steps ("8PM / 12AM / 4AM / 8AM / 12PM", or 24 h "21:00 / 01:00 …").
- **Barcode tracks (NEW):**
  - Efficiency card: ASLEEP track (sleep-blue segments, thin gaps) over an AWAKE hatched track with white ticks (short wakes) and wider `#CACECD` blocks (long wakes).
  - Stage barcode: when a stage is selected.
- **Two-series line** (Hours vs Needed hours):
  - Series A "HOURS OF SLEEP": `#7BA1BB`-grey line with hollow markers and values below.
  - Series B "SLEEP NEEDED": teal `#00F19F` line with hollow markers and values above.
  - Legend at the top: ○ markers + UPPERCASE labels.
- **Weekly line (NEW)** (HRV, RHR, RR, Sleep Efficiency): a 2 pt line (`#50728D` for HRV) with hollow circle markers (`#79B5E7`), value labels above (13 pt Bold condensed `#7AB5DF`) and a soft area fill. **No typical-range band on the weekly card.**
- **Trend View line:**
  - 2 pt line in the series colour at 70%, hollow 9 pt markers with value labels above.
  - A faint area fill below (series colour 12% → 0%).
  - Typical range: a horizontal white-8% band with a "■ TYPICAL RANGE" legend chip at the top-right.
  - Dynamic y range for HR and HRV; fixed range for percentages.
- **Trend View M (NEW):** daily bars or points plus a **white dashed average line with a white "AVG." pill** (black 11 pt Bold) at the left axis.
- **Trend View 6M (NEW):**
  - dimmed weekly/daily data (≈25–30% opacity) plus **monthly segments**: ≈3 pt lines spanning each month, with the value above (15 pt Bold condensed white) and the % change below;
  - segment colour: white for the first month, teal when the change is favourable, orange when unfavourable (e.g. "+55%" teal, "-38%" orange for zone time).
- **Delta chip colours (NEW, Trend View, radius 4, 11 pt Bold):**
  - favourable: green `#00F9A5` on `#144038`;
  - unfavourable: orange `#F4B04F` on `#3C3424`;
  - grey `#C2C4C6` on `#30383C` for **Recovery, Day Strain and Calories in every capture**, and for "● 0%" (no change).
  - Strain changes are absolute points ("▲ 2.6 vs. prior week").
- **Strain & Recovery dual axis** (`reviews/06`, `completeness-critic/13, 16`):
  - Left axis 0/7/14/21 in strain blue. Right axis 0%/33%/66%/100% coloured red/red/yellow/green.
  - Strain: blue line (50% opacity) with hollow blue markers and blue value labels below.
  - Recovery: white-25% line with markers and labels coloured by zone, above.
  - The selected day's column is highlighted (`Wed 27` on a past day).
  - Missing days are skipped and the line connects across them.
- **HR area (sleep or activity):**
  - 1.5 pt line in the series colour with a vertical gradient fill (35% → 0). Recovery activities use `#83AAD1`.
  - Dashed vertical rules at start and end, each with a 4 pt dot at the bottom; HR outside the activity window is dimmer.
  - Sunset↓ / sunrise↑ glyph + time under each rule (12 pt Bold condensed, 70%).
  - y labels 30/50/70/90 or dynamic.
  - Touching the graph replaces the headline stats with a cursor readout ("132 bpm" over "10:34") and draws a dashed cursor with a dot (`activity-flows-2026/e03`).
- **Stress 24 h:**
  - Value-coloured line (stress scale by y).
  - Activity and sleep periods: `RectangleMark` at 12% with a 3 pt cap bar on the top gridline (sleep `#7BA1BB`, activity `#0093E7`, breathwork `#67AEE6`), and glyphs above (moon, sport, breath, or a count "3" for grouped activities).
  - Dashed white-70% now-line ending in a 6 pt dot in the current level colour.
  - Zoom button: a black rounded square (radius 8) with a magnifier "+" glyph, inside the plot at the bottom-right.
  - "‹" page-back under the left edge. The x labels run as a rolling 24 h ("11:02 PM · 7:00 AM · 3:00 PM · **10:49 PM**").
  - Sleep-stress variant (Sleep dive): the sleep span only, with a moon above and a sleep-blue cap line along 3.0 (§3.3).
- **Day-strain bar (NEW, Strain Target panel):**
  - Blue y labels 0.0 / 6.0 / 10.0 / 14.0 / 18.0 / 21.0, and an "OPTIMAL TRAINING" grey caps label in the band.
  - One bar, solid to the current strain then hatched to the estimate, with a black cap tick and a dashed line.
  - A red | yellow | green baseline with the Recovery % under the bar.
- **Healthspan age trend:** step line for ZENO Age (green gradient stroke) against a flat white line for chronological age. Legend "■ ZENO AGE  □ CHRONOLOGICAL AGE". M | 6M control.
- **Range bars (Healthspan pillars):**
  - A segmented horizontal bar: ≈10 segments running orange (left) → grey (middle) → green (right), or mirrored for lower-is-better metrics. Segment gaps 2 pt, h 8.
  - Markers: ▼ above for the 6-month average (value label above it, e.g. "55 ml/kg/min") and ▲ below for the 30-day average.
  - Ends labelled ("15" / "70", "40bpm" / "80bpm"). Age impact at the right: "-3.2" (17 pt Bold, teal/orange/white) over "years" (11 pt, 50%).
- **Logging History calendar (NEW) [C `completeness-critic/20`]:**
  - three month blocks side by side, each with a month label (grey caps) and a "✓ 10" chip (fill `#202C34`, blue);
  - an "S M T W T F S" header;
  - ≈10 pt day dots: Yes `#78ACE0`, No `#88888C`, Missing = empty ring; today has a thicker white ring.
  - Legend "● Yes (15) ● No (49) ○ Missing (28)".
- **Missing data:** skip the point and never plot zero. Empty charts show a centred 14 pt 70% sentence (ZENO's existing empty copy) or the WHOOP placeholders "--%" / "-:--".

### 2.8 Motion (DR §8)
- Instant press feedback.
- Native push.
- Dial arcs animate 0.6–0.8 s only when the value changes; numbers use `.contentTransition(.numericText())`.
- Action menu scales from its anchor.
- No ambient motion. Skeletons appear after 200 ms and stay at least 400 ms.
- Reduce Motion: no sweeps, cross-fades only.
- The Healthspan orb may twinkle very slowly (≤ 1 particle fade per second) **[U]**. Disable it under Reduce Motion.
- Onboarding ring CTA: whether the arc grows during the push is **[U]**; ZENO animates it 0.3 s.

### 2.9 Global states
| State | WHOOP evidence | ZENO rule |
|---|---|---|
| No score yet | dials "--%" in white 40%, "--" for strain; strain "0.0" with a tiny arc; **no strain band or tick** (`help-center/61,68`, `reviews/r03`, `completeness-critic/24, 26`) | same; "–" glyph replaced with "--" |
| Calibrating | Health Monitor tile "[–] Pending"; Health Monitor "● Calibrating Range" chips and a 7-segment banner; dashboard rows show label + "›" only; "Personalization in Progress" card; "CALIBRATION TIMELINE 0/7"; contributor rows "Calibrating" | Recovery dial shows "--%" + "CALIBRATING" caption under the label **[Z]** (ZENO's "n/4 nights" moves to the Looking Ahead card) |
| Unlock thresholds | from WHOOP's calibration article (4/23/2026), counted in Recoveries (see the table below) | ZENO maps to its own thresholds **[Z]** (Recovery 4 nights) |
| **Past day (corrected)** | `completeness-critic/16`, `reviews/r57` (both May 2026). Details in the list below | same; ZENO's current past-day Home must gain Journal, Plan and Dashboard |
| New member | `completeness-critic/24`, `onboarding/31a`. Details in the list below | same (§3.1 item 11) |
| Week 1 / One-tier member | no monitor tiles; an "Ask a question, get support… ›" row in place of the coach pill (`completeness-critic/25`). Health and Stress Monitor are Peak/Life features, so the cause may be the tier **[U]** | ZENO: tiles always show (no tiers), in their "Pending" state while calibrating; the Ask row shows while no outlook can be generated |
| Unscored night | struck-chart sleep chip; deep-dive values "--" / "-:--" | same |
| Syncing | "CATCHING UP" (Device Settings), "DATA CAUGHT UP · SYNCED TO 7:32AM ✓" banner on Home | banner while backfilling ("CATCHING UP…" + teal progress) and for 8 s after completion |
| Off wrist | black banner "YOUR WHOOP IS OFF-BODY / Wear your WHOOP 24/7 to unlock insights." | "STRAP OFF WRIST / Wear your strap 24/7 to unlock insights." (wear detection exists in ZENO) |
| Error | full-screen "ERROR" / "SOMETHING WENT WRONG" with RETRY; dialogs "REQUEST FAILED", "OVERLAPPING ACTIVITIES"; toast "Failed to load. Please try again."; Home notification-feed error box; "LOOKS LIKE THE SERVER IS TAKING A QUICK NAP" (`reviews/r16`) | ZENO has no server: keep the page and dialog styles for local or BLE failures (§3.37) |
| Locked / upsell | "Upgrade to Access", "More to unlock", greyed cards, "MEMBERSHIP EXPIRED" banner with "No Data Available" tiles | not applicable: everything is unlocked in ZENO |

WHOOP unlock thresholds (calibration article, 4/23/2026; counted in Recoveries):

| Recoveries | Unlocks |
|---|---|
| 1 | sleep metrics |
| 3 | coloured Recovery score |
| 5 consecutive nights | Sleep Consistency |
| 7 | Health Monitor full calibration, Skin temp, Weekly Plan |
| 10 | Behavior Insights (plus 5 yes and 5 no within 90 days) |
| 14 | Health Report, VO₂ Max (14 sleeps in 21 days), Calories full calibration |
| 21 within the last 31 days | Healthspan |

**Past day, WHOOP** (`completeness-critic/16`, `reviews/r57`, both May 2026):
- the pager shows "WED, MAY 27" with a white "›", and the streak pill is hidden;
- dials show that day's values;
- **no** sync banner, coaching stack, monitor tiles, coach pill or Tonight's Sleep;
- the activity card is titled **"ACTIVITIES"**, with a single full-width "+ ADD ACTIVITY" button;
- **MY JOURNAL stays**: the week ends on the selected day, which shows white;
- **My Plan, My Dashboard** (that day's values, including that day's stress chart and the Strain & Recovery week) and Discover More stay;
- deep-dive titles show the date.

**New member, WHOOP** (`completeness-critic/24`, `onboarding/31a`):
- dials "--%" with strain live;
- a **"Get Started"** header + "+" in place of "My Day", followed by Get Started cards, then the "Ask a question, get support…" well and TONIGHT'S SLEEP;
- Looking Ahead › CALIBRATION TIMELINE "0/7";
- My Dashboard › "Personalization in Progress".

---------------------------------------------------------------------------------------------------

## 3. Screens

Each screen section has the same parts:
- **Purpose · Entry · Evidence**
- **Layout**, top to bottom, with component specs
- **States**
- **Interactions**
- **ZENO data**: the source of each number and what is missing. `METRIC_COMPARISON.md` gives the status of each metric.

### 3.1 Home [C]
**Purpose.** A one-scroll daily overview.
- WHOOP's own description (Locker): "Streak & device status → three dials → My Day → My Plan → My Dashboard → Stress Monitor trend → Hormonal insights".
- The **observed 2026 order** differs and is the one to build:
  - header;
  - dials;
  - coaching stack;
  - monitor tiles;
  - My Day: coach pill, Today's Activities, Tonight's Sleep, My Journal, Menstrual card;
  - My Plan;
  - My Dashboard: rows plus the Stress Monitor and Strain & Recovery charts;
  - Discover More;
  - footer.

**Entry.** Home tab, the launch screen.

**Evidence:**
- `appstore/ios69-01-home-overview.png`: default text size, top half.
- `completeness-critic/16`: **the whole page, top to footer** (past day, May 2026).
- `reviews/02-5kr-home-NEW-layout-oct2025.png`: device, tab bar.
- `reviews/05,06,07-5kr-home-scroll-*.png`: lower half.
- `reviews/r41`, `r68`, `r113`, `r114`; `journal-plan-2026/31,32,34`: My Plan.
- `health-more-2026/04,05`: Jul 2026 lower half with the Menstrual card.
- `help-center/60..68,91`, `completeness-critic/24,25,26`, `onboarding/31a`: states.
- `appstore/ipad-01-overview.png`: full order on iPad.

**Layout, top to bottom (393 pt; y values at default text):**
1. **Header row** (§1.4). y ≈59–91.
2. **Status/sync banner** (conditional; 12 pt below the header) [C `help-center/91`, `health-more-2026/23`]:
   - Black well, radius 12, h ≈44, 16 margins.
   - Left: "DATA CAUGHT UP" (11 pt Bold caps, white).
   - Right: two lines, "SYNCED TO" (10 pt Bold caps, white) over "7:32AM" (11 pt Bold, teal `#00EC9C`), then a teal ✓ (16 pt).
   - Other banners use the same well:
     - "CATCHING UP…" with a teal progress line [Z];
     - "STRAP OFF WRIST" (white title, 70% body) [C variant `reviews` §3.1];
     - "LOW STRAP BATTERY · 12%" with an orange "!" square [Z];
     - "FIRMWARE: UPDATE COMPLETE" with a green check square and ✕. WHOOP-only; ZENO has no firmware updates.
3. **Wordmark** (ZENO), centred, 72 × 12 pt slot. y ≈123–134.
4. **Three dials**, Sleep · Recovery · Strain (§2.5).
   - Each value sits inside its ring: "80" + "%" (dialValue / dialUnit). Strain shows one decimal and no unit.
   - Labels below: "SLEEP ›", "RECOVERY ›", "STRAIN ›" (11 pt Bold caps tracked white; the "›" is 50%).
   - The strain ring carries the optimal-range band and the target tick (§2.5); neither is drawn before Recovery is scored.
   - y: rings 159–246, label caps 259–266.
5. **Coaching card stack** (conditional; directly under the dials) [C `ios69-01`, `help-center/04,83`, `journal-plan-2026/15`]:
   - y ≈306–441, plus 12 pt of peek. Component §2.6.5.
   - Example: "Optimal Health" / "Take advantage of your green Recovery by meeting your Strain target of 15.5. Your body is signaling it can take on significant exertion today." with a "✓ 2" chip.
   - In 2026 the same slot carries feature announcements, achievement and challenge cards, and the "Couldn't load new notifications" error box. Details in §3.14.
6. **Monitor tiles** [C]: HEALTH MONITOR › | STRESS MONITOR ›, side by side, 12 pt gap. y ≈468–565.
   - Hidden on past days (`completeness-critic/16`) and for week-1 or One-tier members (`/25`) **[V]**.
   - Health Monitor states:

| State | Badge | Status word | Secondary line |
|---|---|---|---|
| Within range | teal ✓ | "WITHIN RANGE" (teal) | "5/5 Metrics" |
| Out of range | orange "!" | "OUT OF RANGE" (orange) | "2/5 Metrics" |
| Elevated | orange | "ELEVATED" | "<metric name>" |
| Very elevated | red "!" | "VERY ELEVATED" (`#FF4A5C`) | "Skin Temperature" |
| Pending / calibrating | grey "–" | "Pending" (12 pt, 70%, not caps) | – |

   - Stress Monitor: value badge ("1.5", in the level colour on its tint; HIGH uses `#4E402F` with `#FCA820` text), level word ("LOW" blue / "MEDIUM" teal / "HIGH" orange), then the last-update time ("4:31pm", "8:44 AM").
7. **My Day header** [C]: "My Day" at sectionTitle size with the "+" square at the right (§1.3).
   - New members see "**Get Started**" here instead (item 11).
8. **My Day content** (16 pt gaps, all [C]):
   - a. **Coach pill**: "☀ Your Daily Outlook ›" (morning and day) or "☾ Your Day In Review ›" (evening). Component §2.6.6.
     - The switch-over time is **[U]**: captures show the outlook at 4:53 PM and the review at 9:18 PM. ZENO uses 18:00 local or after the last activity, whichever is later.
     - **[V]** Before Oct 2025 a separate 48 pt square AI button sat left of the pill; some Nov 2025 builds still show it (`help-center/64`). ZENO omits it.
     - **[V] Ask row** (`completeness-critic/25`, Aug 2026, week-1 member): in place of the pill, a card row (white 10%, h ≈48, radius 12). It holds an outlined W circle, "Ask a question, get support…" (15 pt, 70%) and "›", and opens the Coach sheet.
       - ZENO shows it whenever no outlook can be produced (no provider and fewer than 3 scored days) **[Z]**.
   - b. **TODAY'S ACTIVITIES** card [C `help-center/91`, `64`, `68`; `whoop-site/11h`; `completeness-critic/02`]:
     - Title row with ⤢ at the top-right; tapping ⤢ opens §3.7.
     - Activity rows (§2.6.7, including every chip state), oldest first, 12 pt apart. There is no row limit: `completeness-critic/02` shows nine rows (SLEEP, DRIVING, HIGH STRESS WORK, DRIVING, NAP, DEDICATED PARENTING, GAMING, STRENGTH TRAINER, WALKING).
     - Footer: two nested buttons side by side (12 pt gap, h 44), "+ ADD ACTIVITY" and "⏱ START ACTIVITY".
     - If there is no activity at all, and on past days, a single full-width "+ ADD ACTIVITY".
     - **Past day:** the title becomes "**ACTIVITIES**" (`completeness-critic/16`, `reviews/r57`).
     - No-sleep row: a sleep chip with only the moon glyph, "NO SLEEP", and an outlined white "ADD SLEEP" button (radius 8, h 36) at the right.
   - c. **TONIGHT'S SLEEP ›** card [C `reviews/02`, `r41`, `help-center/01,61`, `completeness-critic/24,25`]:
     - Title row.
     - Two columns, joined by a dashed connector (white 25%, centred vertically on the times):
       - left: sunset-arrow-down icon (20 pt, 70%) + time ("23:32" / "Now"; 24 pt Bold condensed) over "RECOMMENDED BEDTIME" (11 pt Bold caps, 70%, max 2 lines, never split mid-word);
       - right: sunrise-arrow-up icon (strap-vibrate icon when an alarm is armed) + wake time ("07:30") over "ALARM OFF" (orange caps), or "● ALARM ON" (teal dot + teal caps) over the mode: "EXACT TIME", or "**LATEST ALARM**" when a smart mode is set (`completeness-critic/24`; mapping **[U]**).
     - Full-width nested button: strap-vibrate icon + "SET ALARM", or "✎ EDIT ALARM" when set.
   - **Order rule [C `reviews` §3.1]:** evening = TONIGHT'S SLEEP first, then TODAY'S ACTIVITIES; daytime = TODAY'S ACTIVITIES first.
   - d. **MY JOURNAL ›** card [C `reviews/07`, `r113`, `completeness-critic/16`]:
     - Title row.
     - A 7-day strip with weekday labels over 28 pt status circles. The newest day is rightmost; its label is white and the others are 50%.
       - logged: green `#64F3A6` filled circle with a black ✓;
       - not logged: ring, white 40%;
       - today (or the selected past day) not yet logged: grey `#707478` filled circle with a 2 pt white ring;
       - **[V]** in Oct 2025, consecutive logged days merged into one teal capsule; in 2026 they are separate circles. Use the 2026 style.
     - Full-width nested button `#484C50`: lightbulb icon + "BEHAVIOR INSIGHTS" (2025: "RECOVERY INSIGHTS").
     - **Kept on past days**; the strip then ends on that day (`completeness-critic/16`).
     - **[Z]** Hide the card while the Settings journal is off (as ZENO does today).
   - e. **MENSTRUAL CYCLE INSIGHTS ›** card (opt-in) [C low-res `health-more-2026/04`, Jul 2026; position confirmed after MY JOURNAL, while the Locker text puts it last]:
     - Card ≈220 pt (`#2F3239`).
     - "**Day 21**" (≈24 pt Semibold white), with the phase name under it in the phase colour (lavender for luteal), then one grey prediction sentence. The wording of both is **[U]**.
     - A **dot strip**: one small dot per cycle day (≈28) across the card, coral for menstrual days then lavender. Today is a larger white dot. Small grey day numbers sit under the strip (1 · 7 · 14 · 21 · 28).
     - Full-width grey button "**+ LOG CYCLE**" (≈40 pt, radius 8, `#41444B`).
     - States: "No Phase Predicted" when no period is logged for too long (text, forum 403; visual **[U]**). A **Pregnancy** variant (Week N + trimester bar, no LOG button) was never seen **[U, Z]**.
9. **My Plan** [C `journal-plan-2026/31,32,34`, `reviews/r68,r113,r114`]:
   - **Position:** after the My Day group (after MY JOURNAL / the Menstrual card) and before My Dashboard (`completeness-critic/16` May 2026, `health-more-2026/04` Jul 2026, `journal-plan-2026/32` Aug 2026). **[V]** iOS 5.49.2 (`reviews/r68`, Apr 2026) put the active plan above My Day.
   - Header "My Plan" (sectionTitle).
   - **Collapsed card** (`#2C3034`, radius ≈14): "CUSTOM PLAN" / "BOOST FITNESS PLAN" (cardTitle, 15 pt) with "⌄" at the top-right; "6 days left" (15 pt, 70%); "**27%** ACCOMPLISHED" (number 20 pt Bold + small "%", then the caps word in grey); a 4 pt green `#6CE8A2` progress bar on a `#404448` track.
   - **Expanded** (tap ⌄; the chevron becomes ⌃; fill `#384040`):
     - goal rows (≈20 pt names, no cards), **unfinished goals first in white, a hairline, then finished goals in green**, each with a goal ring at the right (§2.5). Examples: "7,000+ Steps 5/7", "14.0+ Day Strain 6/7", "0:22+ HR Zones 4-5 Time 0:27", "Any Strength Training Activity 4/4", "Weight Goal: 268.6 lbs", "1:30+ Strength Activity Time 2:49";
     - then the nested button "**VIEW MY PLAN**" (`#404848`, radius 10, 15 pt Bold caps).
   - **Empty state** (no active plan) [C `reviews/r113`, `completeness-critic/16`]: card `#303438`, title "Build Your Best Self" (17–20 pt Semibold), body "Set goals, track progress, and turn small actions into long-term wins." (14 pt, 70%), CTA "EXPLORE PLANS →" (12 pt Bold caps `#78AAE4`).
     - Art: three dashed green rings with moon / heart / lifter glyphs at the right. ZENO draws its own with SF Symbols.
10. **Looking Ahead** (new members, while calibrating) [C `help-center/61,62`, `onboarding/32a,32d`]: card "CALIBRATION TIMELINE ›" / "Wear your WHOOP to bed nightly and check back in here to track your sleeps and discover new insights." with a ring counter "0/7" at the right.
    - **[Z]** ZENO's counter is "n/4" nights for Recovery. Show "n/4" until Recovery scores, then "n/7" until the 7-day features unlock.
11. **New-member variant** (before the first Recovery) [C `completeness-critic/24`, `onboarding/31a`, `help-center/61`]:
    - "**Get Started**" replaces the "My Day" header and keeps the white "+".
    - Under it, a vertical list of Get Started cards (§2.6.34). The first card has the gradient border; the rest are plain `#1D2124`. Completed or dismissed cards disappear. Copy seen:
      - "Learn How to Charge" / "Ensure your WHOOP has enough battery to collect data throughout your first day and night." / "VIEW CHARGING TIPS →";
      - "Set Up Your Sleep" / "Input your sleep routine so WHOOP can help you wind down intentionally and wake up gently at the right time." / "CREATE SLEEP SCHEDULE →";
      - "Customize Your Journal" / "The more you share with WHOOP, the more insights you get. Track habits to see their effects so you can make well-informed decisions." / "OPEN JOURNAL →";
      - "Ready to get moving?" / "Start your first activity and come back to explore your heart rate zones and more on WHOOP." / "START ACTIVITY →";
      - "Unlock New Potential" / "Connect WHOOP to Strava and your favorite apps for a seamless experience across platforms." / "EXPLORE APP INTEGRATIONS →";
      - an Advanced Labs upload card.
    - Then the **Ask well**: a black-100% well with a 1 pt grey border, radius 12. It holds the gradient-ring W glyph and the placeholder "Ask a question, get support…". Shown only when Coach is configured **[Z]**.
    - Then TONIGHT'S SLEEP (and TODAY'S ACTIVITIES once something is logged), Looking Ahead, and My Dashboard › "Personalization in Progress".
    - **[Z] ZENO card set** (copy rewritten for ZENO):
      - "Learn How to Charge" → strap charging tips;
      - "Set Up Your Sleep" → Sleep Planner / alarm;
      - "Customize Your Journal" → SELECT BEHAVIORS;
      - "Ready to get moving?" → Start Activity;
      - "Bring Your History" → WHOOP CSV / Apple Health import (ZENO extra, replaces "Unlock New Potential").
    - WHOOP users complain some cards cannot be dismissed; every ZENO card gets a ✕.
12. **My Dashboard** [C `reviews/05..07`, `help-center/62,67`, `appstore/ipad-01`, `completeness-critic/13,16`, `journal-plan-2026/32`]:
    - Header "My Dashboard" + "CUSTOMIZE ✎" at the right. When calibrating, the pencil is hidden and a "Personalization in Progress" card shows: "As your device calibrates to your unique physiology, you'll gain insight into your trends here." with art at the right.
    - Items are reorderable, in a single column, 12 pt gaps:
      - **Metric row** [C]:
        - Card, h ≈56–60. Left: 20 pt line icon (50%) + UPPERCASE label (12 pt Bold).
        - Right: value (tileValue 22 Bold condensed, unit 14 tertiary), a 6 pt trend glyph after it (§2.6.9), and the 30-day baseline below (13 pt Bold condensed, 50%).
        - No data yet: the label plus a "›" only.
        - Row examples seen:

| Row | Value | Glyph | Baseline |
|---|---|---|---|
| DAY STRAIN | 19.6 | ▲ | 14.0 |
| **SLEEP DEBT** | 0:28 | ▲ orange | 0:12 |
| SLEEP NEEDED | 7:42 | ▼ teal | 7:46 |
| SLEEP CONSISTENCY | 56% | ▼ | 76% |
| RECOVERY | 24% | ▼ orange | 57% |
| HEART RATE VARIABILITY | 51 | ▲ teal | 46 |
| RESTING HEART RATE | 60 | ▲ orange | 58 |
| STEPS | 10,325 | ▲ | 7,466 |
| **WEIGHT** | 88.5 | ▲ grey | 88.3 |

   - Rows also seen with no values readable: CALORIES, AVERAGE HEART RATE, RESPIRATORY RATE 18.2, LEAN BODY MASS ›, RESTORATIVE SLEEP (%) 59%, HR ZONES 1-3 (WEEKLY), HR ZONES 4-5 (WEEKLY), VO₂ MAX 41.
      - **STRESS MONITOR chart card** [C `reviews/05`, `completeness-critic/13,16`]:
        - Title + "›".
        - Line 2: "Last updated 10:15 PM" (12 pt, 70%) on the left; "MEDIUM 1.1" (level word in its colour + 17 pt Bold value) on the right.
        - Then the 24 h stress chart (§2.7), 150 pt tall. On a past day it covers that day.
      - **STRAIN & RECOVERY chart card** [C `reviews/06`, `completeness-critic/13,16`]: title + ⓘ, then the 7-day dual-axis chart (§2.7), 200 pt.
      - **Default set for a new member** [C]: HRV, SLEEP PERFORMANCE, STEPS, CALORIES, STRESS MONITOR.
    - Tap a metric row → Trend View (§3.12). Tap the stress card → Stress Monitor. Tap the S&R card → Trend View (Recovery).
13. **Footer:** a centred thin wordmark (WHOOP prints "WHOOP PEAK" / "WHOOP LIFE"). ZENO prints a small ZENO mark at white 50%, 40 pt above the bottom inset. **[U]** Drop it if it looks like padding.
14. **Not copied:** "Discover More" promo rows [C `completeness-critic/16`]. Each row has a square photo, a title, a body and a blue caps CTA:
    - "Test with Advanced Labs … GO TO ADVANCED LABS →";
    - "Upgrade to WHOOP Life … VIEW UPGRADE OPTIONS →";
    - "Explore the WHOOP Shop … GO TO SHOP →";
    - "Give the Gift of WHOOP … CHOOSE A GIFT →".
    - These are commercial and do not apply to ZENO.

**States.**
- Loading: skeleton blocks in white 10% for dials, tiles and cards (DR §8).
- Past day, new member, week 1, unscored, errors: §2.9.
- Pull-to-refresh asks the strap to sync (ZENO behaviour; keep).

**Interactions.**
- Dial → deep dive.
- Monitor tiles → Health Monitor / Stress Monitor.
- Pill or Ask row → Coach sheet with the outlook.
- Activity row → Activity Details. Sleep row → Sleep deep dive (**[U]**: WHOOP opens a "SLEEP" activity detail, `help-center/77`; ZENO opens the Sleep deep dive).
- Tonight's Sleep → Sleep Planner.
- Journal day → Journal for that day. BEHAVIOR INSIGHTS → Behavior Insights.
- Menstrual card → Menstrual Cycle Insights. "+ LOG CYCLE" → the log-period sheet.
- Customize → Customize Dashboard.
- Horizontal swipe changes day (ZENO extra).

**ZENO data.**
- Dials: `HomeSnapshot` (existing).
- Band and tick: `CoupledView.optimalStrainRange` and its midpoint.
- Health tile: `BodyVitalSigns.readings` + `VitalBands`, counted in range. With SpO₂ hidden, the denominator is 4 ("4/4 Metrics", which WHOOP also shows when a metric is off).
- Stress tile: `StressModel` value + level + last-update time.
- Coach pill: `CoachBriefScheduler` (or a local template, §3.15).
- Activities: `repo.workoutRows()` + sleep and naps from `SleepModel`.
- Tonight: `repo.sleepNeedTonight` + `SmartAlarmView` state.
- Journal: `repo.nativeJournalDays`.
- Menstrual card: `CyclePhaseEngine`.
- Dashboard values: `DailyMetric` series vs 30-day mean; SLEEP DEBT from `SleepDebt`; WEIGHT from the Apple Health import.
- Get Started cards: onboarding progress flags.
- Remove ZENO's "STRAIN TARGET" card (it moves onto the dial and into the Strain deep dive) and the "KEY STATS" grid (it becomes My Dashboard rows).
- ZENO's current past-day Home lacks Journal, Plan and Dashboard; add them.

### 3.2 Action (+) menu [C]
See §1.3. Evidence: `reviews/03`, `help-center/64`, `design-language/22`.

States:
- While a live activity runs, START ACTIVITY becomes "RESUME ACTIVITY" **[Z]** (WHOOP's live screen cannot be minimised).
- CREATE ZENO LIVE is hidden until built **[Z]**.

### 3.3 Sleep deep dive [C]
**Entry.** The Home SLEEP dial; the sticky mini ring; the "Sleep" Health-tab metrics.

**Evidence:**
- top: `appstore/ios69-02-sleep.png`, `deep-dives-2026/56, 56b` (Sep 2026);
- Last Night's Sleep: `help-center/74,79`, `whoop-site/52`, `deep-dives-2026/02, 11, 12, 15`;
- detail cards: `deep-dives-2026/01` (full card order, empty state), `18`, `03`, `19`, `19b`, `19c`;
- Weekly Trends: `deep-dives-2026/07, 08, 09, 10, 13, 19d`, `reviews/21`, `help-center/75`.

**Layout:**
1. **Nav:** "‹" · "TODAY" · ⓘ, or the achievement chip (§1.5).
   - **[Z]** Under it, a centred night pager "‹ LAST NIGHT ›" (12 pt Bold caps; the label becomes the wake date "SEP 30") steps nights. WHOOP has none.
2. **Hero ring:** 260 pt, sleep colour.
   - Inside: the ZENO mark (optional), "75" + "%", "SLEEP / PERFORMANCE" (2 lines, label style).
   - A 3-dash level indicator below the label: dashes 16 × 3, gaps 2. The lit dash is orange (Poor) / grey `#848586` (Sufficient) / teal (Optimal).
3. **Contributor callout** (4 rows; each row's right side is a 3-segment bar (§2.6.12) followed by the value):

| Row | Icon (SF) | Value | Example |
|---|---|---|---|
| HOURS VS. NEEDED | `moon.zzz` / `clock` | % | 74% |
| SLEEP CONSISTENCY | `circle.lefthalf.filled` (double-crescent in WHOOP) | % | 45% |
| SLEEP EFFICIENCY | `bed.double` | % | 98% |
| HIGH SLEEP STRESS | `bolt.heart` | % of sleep in high stress | 0% |

   - Thresholds [C help-center §9.3]:

| Contributor | Optimal | Sufficient | Poor |
|---|---|---|---|
| Sleep Performance; also applied to Hours vs Needed **[U]** | ≥85 | 70–85 | <70 |
| Consistency | ≥80 | 70–79 | <70 |
| Efficiency | ≥90 | 80–89 | <80 |
| Sleep Stress | <1% | 1–5% | >5% |

   - Legend well: "▬ Poor ▬ Sufficient ▬ Optimal".
   - A row that cannot be scored yet shows "**Calibrating**" (15 pt Regular, 70%, no bar). Seen on Consistency, which needs 5 consecutive nights (calibration article; `deep-dives-2026/19e`).
4. **Insight placement [V]:**
   - Up to about May 2026 an inline insight card followed the legend. Copy example: "Your Sleep Performance is sufficient, but there's room to improve - Sleep Consistency could use attention to help you get to optimal sleep." CTA "EXPLORE YOUR SLEEP INSIGHTS →" (2025 mock: "DIVE INTO MY SLEEP →").
   - **From about June 2026 the legend is followed directly by "Last Night's Sleep"**, and the **floating coach summary pill** (§1.2) carries the summary (`deep-dives-2026/56, 56b, 19c`).
   - **[Z]** ZENO: the pill when Coach is configured; otherwise the inline card with the local template sentence.
5. **"Last Night's Sleep"** (sectionTitle) with "EDIT ✎" at the right. Subtitle: "**Today** vs. prior 30 days" (12 pt; "Today" white Semibold, the rest 70%).
   - All cards from here to item 7 use the **detail fill** (white ≈4–5%, §2.1) and carry **ⓘ** at the top-right.
6. **HOURS OF SLEEP card:**
   - "8:10" (24 pt Bold condensed) + ▲/▼ glyph; the baseline "7:58" below (12 pt Bold condensed, 50%).
   - Overnight HR chart (§2.7 HR area): 200 pt tall, y labels dynamic (30–150), times "23:47" … "08:31" under the dashed start/end rules.
   - Hairline divider.
   - Row: "▦ TYPICAL RANGE" (hatched-box legend + 11 pt caps 70%) on the left; "DURATION 8:41" (or "TIME IN BED 8:48") on the right (label 11 pt caps 70% + value 15 pt Bold condensed).
   - Four stage rows (§2.6.19): AWAKE 5% 0:31 · LIGHT 57% 4:51 · SWS (DEEP) 20% 1:45 · REM 18% 1:34.
   - Tapping a radio selects that stage: the HR chart recolours the stage's segments in its colour with translucent bands, and the rows show barcode timelines. Tapping again deselects.
   - Hairline, then "▨ RESTORATIVE SLEEP" (split swatch + 11 pt caps) on the left. On the right: "3:18 ▼" (15 pt Bold condensed + glyph) over the baseline "3:54" (13 pt Bold, `#BBBCBC`). A grey ● replaces the glyph when today equals the baseline.
   - **SLEEP LATENCY** (conditional) [C `deep-dives-2026/02, 11`]: a `#C8C8C8` swatch + "SLEEP LATENCY" + "0:03" at the right, with **no baseline**.
     - Shown only when the sleep was started or stopped manually or edited ("If your Whoop auto detects it, you won't see latency").
7. **Detail cards** (NEW in revision 2) [C], in this order. Empty state: each shows only its title and "-:--" or "--%" (`deep-dives-2026/01`).
   - a. **HOURS VS. NEEDED** [C `deep-dives-2026/02, 12, 15, 18`]:
     - Value "60%" (34 pt Bold) + ▼ orange / ▲ teal; baseline "73%" (13 pt Bold).
     - "HOURS OF SLEEP" (11 pt Bold caps `#BBBCBC`, inset ≈8 pt), then the **hours bar**: ≈12 pt, fully rounded, with the hours gradient (§2.1). Its value (15 pt Bold condensed) is right-aligned **to the end of the bar**, e.g. at ≈55% of the width for 60%.
     - The **need bar** sits directly under it on the same horizontal scale: a long grey "minimum" segment, then short segments for strain (blue) and debt (light grey). Segment details are storyboard-only **[U]**.
     - "SLEEP NEEDED" + value "6:17" below the need bar, aligned to its end.
     - **Breakdown well** (§2.6.26), with its notch pointing at the SLEEP NEEDED value:

| Swatch | Label | Value | Note |
|---|---|---|---|
| ■ `#484C50` | Healthy Minimum | 7:42 | label and value dimmed `#C4C5C7` |
| (no swatch) | Recent Naps | -2:07 | only when there were naps |
| ■ strain blue | Recent Strain | +0:35 | |
| ■ `#C8C8C8` | Sleep Debt | +0:07 | |

   - The rows add up to SLEEP NEEDED (7:42 − 2:07 + 0:35 + 0:07 = 6:17).
   - b. **SLEEP CONSISTENCY** [C `deep-dives-2026/03, 04, 05, 18, 19c`]:
     - Value + ▼/▲ + baseline.
     - Legend right-aligned on the baseline row: three dashes `#93979A` + "OPTIMAL BED/WAKETIME" (11 pt Bold caps).
     - Floating range chart (§2.7): 5 nights, inverted time axis, callout pills on last night, two dashed optimal curves, weekday labels (last night white).
     - **[V]** Nov 2025: mixed-case legend and no pills. Build caps + pills.
   - c. **SLEEP EFFICIENCY** [C `deep-dives-2026/19, 18, 19c`]:
     - Value + glyph + baseline.
     - "ASLEEP" with its value right (17 pt Bold condensed), the barcode tracks (§2.7), then "AWAKE" with its value right.
     - Hairline (inset 16), then "■ WAKE EVENTS" (`#CCCCCC` swatch + 11 pt Bold caps white) and the count at the right ("20").
   - d. **SLEEP STRESS** [C `deep-dives-2026/19b, 19c`]:
     - Title "SLEEP STRESS"; the callout row keeps "HIGH SLEEP STRESS".
     - Value "0%" = share of the sleep in high stress, with **▼ teal when lower** than the baseline "5%".
     - Chart ≈150 pt: y labels "0.0 / 1.0 / 2.0 / 3.0"; a moon glyph centred over the sleep span; a sleep-blue cap line along 3.0; the stress line coloured by value; x labels at sleep start, two clock times, and the end time in bold white; a dashed end rule with a dot.
     - Rows in the stage-row style, each with a hatched track and a bar in the level colour: "HIGH 0%" (% in orange) "0:00"; "MEDIUM 8%" (% in teal) "0:34"; "LOW" (% in blue; the LOW row is storyboard-only **[U]**).
8. **"Weekly Trends"** (≈22 pt Semibold) [C]. Cards use the **standard** card fill (§2.7 Weekly Trends chart), each with "TITLE ›" opening Trend View, in this order:

| # | Card | Chart | Labels |
|---|---|---|---|
| 1 | SLEEP PERFORMANCE › | sleep-blue bars | "75%" |
| 2 | HOURS VS. NEEDED (HOURS) › | two lines; legend "○ HOURS OF SLEEP ○ SLEEP NEEDED" | need above (teal), hours below (blue) |
| 3 | HOURS VS. NEEDED (%) › | sleep-blue bars | "65%" |
| 4 | RESTORATIVE SLEEP (HOURS) › | stacked bars, REM bottom / Deep top; legend "■ DEEP SLEEP ■ REM SLEEP" | total "3:51" above, white |
| 5 | SLEEP CONSISTENCY › | sleep-blue bars | "89%" |
| 6 | TIME IN BED › | floating bed → wake bars | "10:28" above, "6:25" below |
| 7 | SLEEP EFFICIENCY › | line with hollow markers | "99%" (seen on Android only) |

   - Nothing after card 7 has been captured **[U]**. No weekly SLEEP DEBT card appears in 2025-10+ captures; revision 1's SLEEP DEBT card is dropped.
9. **[Z] ZENO extras**, after Weekly Trends, each in the standard card style:
   - "NAPS" rows (same activity-row component);
   - a 3-up mini-stat row "SLEEPING HR · LOWEST HR · BREATHING" (label 11 pt caps + value 17 pt);
   - "BODY CLOCK" (optional);
   - the classic "Open the full Sleep screen" link is removed once parity is reached.
   - (Revision 1's "SLEEP NEED breakdown" extra is now WHOOP's item 7a.)

**States:**
- No sleep for the day: ring "--%" and contributors "--"; detail cards show "-:--". The ZENO insight reads "No sleep was recorded for this night. Wear your strap to bed to see your Sleep Performance."
- Calibrating: see item 3.
- Past day: the nav title shows the date ("SAT, DEC 27").

**Interactions:**
- A contributor row → Trend View for that metric.
- ⓘ on a detail card → an explainer sheet.
- EDIT → ZENO's existing sleep edit (bed/wake times, delete, add nap) presented as a sheet.

**ZENO data:**
- Performance: `sleep_performance` / `Rest.composite`.
- Hours vs Needed: merged night ÷ `resolvedNightSleep(day:).need`.
- **Need breakdown:** stored `sleep_need_baseline_min` (Healthy Minimum), `…_nap_min`, `…_strain_min`, `…_debt_min`. Map them to WHOOP's wording.
- Efficiency, Consistency: stored. The Consistency chart uses the last 5 nights' bed/wake times. The optimal bed and wake curves come from each night's planned bedtime (`SleepNeed.suggestedBedtime`) and the wake target.
- Wake events: `DailyMetric.disturbances`. Barcode: awake intervals from the merged night.
- **High Sleep Stress**: new. Apply the `DaytimeStress` per-hour math to 5-minute windows inside the sleep period and take the % of time ≥ 2.0; MEDIUM and LOW come from the same curve.
- Latency: the bed mark (`SleepMark`) to the detected onset, shown only for manually started or edited sleeps.
- Stages: merged night intervals. HR chart: 1-minute buckets. Typical ranges: 30-night p25–p75 per stage. Restorative: deep + REM.

### 3.4 Recovery deep dive [C]
**Entry.** The Home RECOVERY dial.

**Evidence:**
- `appstore/ios69-03`;
- `help-center/70,71` (Mar 2026, with baselines);
- `deep-dives-2026/16, 16b, 17, 17b, 17c, 17d` (Mar–Sep 2026);
- `whoop-site/15,57,11j`;
- `reviews/90`, `11`.

**Layout:**
1. **Nav:** "‹" · "TODAY" · ⓘ, or the achievement chip (Green Monster count, §1.5).
2. **Hero ring** in the zone colour: "85" + "%", "RECOVERY". There is no level indicator.
3. **Contributor callout:**

| Row | Value / unit | Baseline below | Favourable direction |
|---|---|---|---|
| HEART RATE VARIABILITY | 73 (ms is implicit, not printed) | 69 | ↑ |
| RESTING HEART RATE | 37 | 42 | ↓ |
| RESPIRATORY RATE | 13.6 | 13.8 | ↓ |
| SLEEP PERFORMANCE | 87% | 85% | ↑ |

   - Glyph colours follow §2.6.9 (`deep-dives-2026/17b`: "15.8 ▲ / 15.5" orange, "74% ▼ / 75%" orange).
   - Legend: "▲▼ **Today** vs. last 30 days" (App Store mock: "prior 30 days").
4. **Insight card [V]:** present in Mar–Jul 2026 (`help-center/71`, storyboard). It is **absent in both late-Sep 2026 captures**, where the legend is followed directly by Behavior Insights (`deep-dives-2026/17, 17b`).
   - Example: "Your HRV (73 ms) is within its typical range of 55 ms to 77 ms, which contributed to a yellow Recovery. Today is a great day to move your body while still respecting your limits."
   - CTA: "EXPLORE YOUR RECOVERY INSIGHTS →" (2025 mock: "BREAK DOWN MY RECOVERY →").
   - **[Z]** As for Sleep: the pill when Coach is configured, otherwise this inline card.
5. **BEHAVIOR INSIGHTS** card [C], in two variants:
   - **A, compact row** (`deep-dives-2026/17c`, past day; `help-center/71`): row card §2.6.25 with a lightbulb icon, "BEHAVIOR INSIGHTS", the subtitle "See how your behaviors impact your recovery." and "›".
   - **B, expanded** (`17`, `17b`, `17d`, today, Sep 2026):
     - an outlined lightbulb with rays + "BEHAVIOR INSIGHTS" (13 pt Bold caps);
     - body (≈15 pt Regular `#C4C5C7`, 2 lines): "Some of your behaviors from yesterday may have a[ffected] your Recovery score today.";
     - rows of chips (h ≈32, radius 8–10):
       - green-tinted with teal text and a ▲, e.g. "▲ Consistent Bed Time" (text `#18EFAB`);
       - orange-tinted `#443C28` for negative behaviours;
       - grey `#383C40` for neutral ones.
     - Other chip texts are **[U]**.
   - Rule **[U]**: B on today when yesterday's journal has behaviours with measurable impact; A otherwise. Tap → Behavior Insights (§3.18).
6. **"Weekly Trends"** [C `deep-dives-2026/16`]:

| # | Card | Chart |
|---|---|---|
| 1 | RECOVERY › | 7 bars coloured by zone, "%" labels in the bar colour, last column highlighted |
| 2 | HEART RATE VARIABILITY › | line with hollow markers, blue labels above, soft fill, **no typical band** |
| 3 | RESTING HEART RATE › | same line style (body **[U]**) |
| 4 | RESPIRATORY RATE › | storyboard only **[U]** |

   - Anything below is **[U]**.
7. **[Z] ZENO extras**, after Weekly Trends:
   - **"WHAT SHAPED IT"** card: the recovery engine's drivers, restyled to this system. Rows use the contributor-row layout:
     - label (caps);
     - value · baseline (12 pt, 70%);
     - a points chip at the right: "+1 pt" teal tint, "−1 pt" orange tint, "0 pts" grey.
   - Header chip: "RELIABLE" (teal tint) / "ESTIMATE" (grey) / "CALIBRATING" (blue tint).
   - Replace the classic `ChargeDriverRow` pip bars and units ("br/min" → "rpm", "+0.4 C" → "+0.4 °C").
   - "CONTEXT" (skin temp, SpO₂) is dropped here; those live in Health Monitor, as in WHOOP.

**States:**
- Calibrating (fewer than 4 nights): ring "--%" + "CALIBRATING".
- Callout rows show values without arrows.
- Insight: "Recovery needs 4 nights of wear to learn your baseline. 2 of 4 nights recorded."
- Carried score: subtitle under the nav "From last night · Sep 30" (12 pt, 70%) **[Z]**.

**ZENO data:**
- `RecoverySnapshot`.
- Baselines: switch to the **30-day mean** to match WHOOP's legend. The engine baseline stays inside "What shaped it". This removes ZENO's "▲45% vs ▲44%" double-reference inconsistency.
- Behaviour chips: `EffectRanker` over yesterday's journal answers and auto-tracked behaviours. Show a chip only for behaviours already unlocked (§3.18).

### 3.5 Strain deep dive [C]
**Entry.** The Home STRAIN dial.

**Evidence:**
- `appstore/ios69-04`;
- `help-center/72,73`;
- `deep-dives-2026/57` (Jul 2026);
- `deep-dives-2026/41` (storyboard, Weekly Trends);
- `whoop-site/51,11a`;
- `reviews/90`, `08`.

**Layout:**
1. **Nav:** "‹" · "TODAY" · ⓘ, or the achievement chip (strain diamond, `deep-dives-2026/57`).
2. **Hero ring** (strain colour, with the band and tick of §2.5): "14.2" over "STRAIN".
   - **[V]** The App Store mock says "DAY STRAIN". The 2026 device says "STRAIN"; use it.
3. **Contributor callout:**

| Row | Value | Baseline |
|---|---|---|
| HEART RATE ZONES 1-3 | h:mm, e.g. 1:53 | 0:21 |
| HEART RATE ZONES 4-5 | 1:53 | 0:09 |
| STRENGTH ACTIVITY TIME | 2:35 | 0:19 |
| STEPS | 23,451 | 6,273 |

   - **[V]** The site mockup uses "STRENGTH TRAINING TIME" and "AVERAGE HEART RATE"; the 2026 device uses the rows above (`deep-dives-2026/57`).
   - Legend: "▲▼ Today vs. last 30 days".
4. **Insight card** (still inline in Jul 2026 [C `deep-dives-2026/57`]). Copy depends on the strain band (WHOOP text):

| Band | Copy |
|---|---|
| Light 0–9.9 | "Strain between 0 and 9.9 is considered light…" (ZENO wording) |
| Moderate 10–13.9 | "Strain between 10 and 13.9 is considered moderate. Your cardiovascular load is significant but not strenuous." |
| Strenuous 14–17.9 | "Strain between 14.0 and 17.9 is considered strenuous, meaning your cardiovascular system has been working hard." |
| All out 18–21 | "Strain between 18 and 21 represents near maximal cardiovascular load. Dedicate additional time to rest and recovery." |
| **Above the optimal range (NEW)** | "You've worked extra hard today and have exceeded a balanced level of Strain. Reduce fatigue tomorrow by dedicating extra time to rest and recovery." |

   - Before Recovery is scored: "Your optimal Strain recommendation will be calculated once ZENO processes your recent Recovery."
   - CTA "**EXPLORE YOUR STRAIN INSIGHTS →**".
5. **"Today's Activities"** (sectionTitle): activity rows (§2.6.7) inside one card, plus the two Add/Start buttons.
   - Empty: "No activities yet" (14 pt, 70%) + "+ ADD ACTIVITY".
6. **"Weekly Trends"** [C storyboard order `deep-dives-2026/41`, 2026-04]:

| # | Card | Chart | Status |
|---|---|---|---|
| 1 | STRAIN › | strain-blue bars, one-decimal labels, last column highlighted | storyboard |
| 2 | HR ZONES 1-3 › | legend "■ ZONE 1 ■ ZONE 2 ■ ZONE 3"; stacked bars (Zone 1 bottom → 3 top) with h:mm totals, "0:00" on empty days | storyboard |
| 3 | HR ZONES 4-5 › | legend "■ ZONE 4 ■ ZONE 5"; stacked bars with h:mm totals | storyboard |
| 4 | ≈5-letter title with comma-thousands labels, probably STEPS | blue bars | **[U]** |
| 5 | ≈8-letter title, possibly CALORIES | header only | **[U]** |

   - **[Z]** ZENO builds cards 1–3, then STEPS and CALORIES.
7. **[Z] ZENO extras**, after Weekly Trends, restyled:
   - "STRAIN TARGET" card: the intent word ("PUSH" / "MAINTAIN" / "RESTORE", label style in the band colour) + the range "14.0–18.0" + the 0–21 bar + "In the range" text;
   - "THROUGH THE DAY" cumulative strain chart;
   - "HEART RATE" day chart with zone bands (zone colours §2.1);
   - "TIME IN ZONES": zone rows §2.6.18, Zone 5 → 1;
   - mini stats "CALORIES · AVG HR · PEAK HR".

**ZENO data:**
- `StrainSnapshot`.
- Zones 1-3 = sum of `timeInZone` Z1–Z3; Zones 4-5 = Z4+Z5. Weekly stacked bars use the same per-zone minutes.
- Strength Activity Time = Lift Log session minutes + workouts whose sport is strength-type.
- Steps: `StepsResolver`.
- Baselines: 30-day means.

### 3.6 Activity Details [C]
**Entry.** An activity row (Home, the Strain dive), or a notification.

**Evidence:**
- strain activity: `whoop-site/95` (top, lossless), `help-center/82` (2026 rowing, lower half), `activity-flows-2026/d01, h01, f09`;
- recovery activity: `activity-flows-2026/e01, e02, e03, e08–e11`;
- strength: `activity-flows-2026/g12, g15–g18, g24`, `whoop-site/66`;
- route: `activity-flows-2026/f02, f03, f06, f07`;
- menus: `activity-flows-2026/d02, d05, d06`;
- nap and sleep: `reviews/r79`, `help-center/77`, `deep-dives-2026/50`.

**Layout (strain activity):**
1. **Header:** "✕" (modal) or "‹". Then the sport glyph (24 pt, white) + "RUNNING" (navTitle style, left-aligned beside the glyph) over "6:45am to 7:30am" (12 pt, 70%). "•••" at the right.
2. **Source chip** (one slot, 11 pt Bold caps on a dark chip, radius 4): "VIA STRAVA", "GARMIN VIA STRAVA", "AUTO-DETECTED", "RECOMMENDED ACTIVITY".
   - ZENO: "VIA APPLE HEALTH", "AUTO-DETECTED", "MANUAL", "LIVE".
3. **Optional notice card** (WHOOP muscular-load notices; not copied):
   - "Refine Your Muscular Strain" (black card, ✕, "ADD EXERCISES →" in `#009CFF`);
   - "More Credit for Your Effort … VIEW TRENDS →" (`g19`, `g20`).
4. **Headline:** "13.8" (40 pt Bold condensed, strain colour) + a grey delta chip "▲ 9.7" (11 pt on white 20%), then "ACTIVITY STRAIN" (label, 70%).
   - The chip's meaning is **[U]**: likely this sport's typical strain. ZENO uses the 30-day mean strain for the same sport.
   - Some captures add a second stat: "7,141 ▲6,954 ACTIVITY STEPS".
5. **Insight card** (gradient border), e.g. "Spending 23 minutes in your highest heart rate zones made this sparring session too strenuous to help your body recover." + "LEARN MORE WITH COACH →" / "EXPLORE INSIGHTS →". Older builds show a bare 17 pt sentence **[V]**.
6. **"HEART RATE"** (label): HR area chart in strain colour, 180 pt, dashed start/end rules with times below; HR outside the window drawn dimmer.
   - **[U]** The 2026 changelog says Edit opens "by tapping the edit icon above the heart rate graph". No pencil is visible in the Sep 2026 capture (`activity-flows-2026/h01`).
7. **Row:** "▦ TYPICAL RANGE" on the left; "DURATION 45:06" on the right.
8. **Zone rows** (§2.6.18), ZONE 5 → ZONE 1, then "RESTORATIVE (<50%)" (or "ZONE 0 <118 BPM" **[V]**).
   - Labels show either "(90-100%)" or "162-171 BPM" **[V]**; ZENO shows bpm.
9. **Footnote:** "Zone ranges automatically updated on 1/6/26. **View HR Settings**" (12 pt, 70%; underlined link → Heart Rate Settings).
10. **"KEY STATISTICS"** (cardTitle) with "VS. 30 DAY AVERAGE" (label, 50%) at the right.
    - A horizontally scrolling row of 2-up tiles, 160 × 120 (fill ≈`#373C40`): icon + caps label, then value 34 pt + unit, then a delta chip ("▲ 137cals").
    - Tiles: CALORIES, AVG HR, MAX HR, DURATION, STEPS (+ DISTANCE, PACE/SPEED for GPS).
11. **Milestone card** [C `h02`, `g17`]: card radius ≈14; the sport icon in a segmented ring badge; "13/25" (first number blue) + "12 more for next achievement" (or "4 more until your next milestone"); a thin progress bar and "›". Links to the activity's achievement (§3.30).
12. **ROUTE card** (GPS activities) [C `f02`, `f03`]:
    - Apple Maps light standard, ≈394 pt tall, 16 pt margins, radius ≈14.
    - "ROUTE" (black Bold caps) at the top-left; route line `#0A8AF0`, blue start dot with a white ring, checkered finish marker.
    - A near-black stats panel `#171717` overlays the bottom: "DISTANCE | PACE | ELEV. GAIN" (cycling: SPEED; values ≈26 pt with small units).
    - **Share button (Apr 2026+):** a black rounded square (≈31 × 30, `#171717`) with a white share glyph at the top-right. It exports the **shareable snapshot**, a portrait card with no map (`f01`):
      - glow `#3D5D98` → `#131A22` → `#101518`;
      - the route traced as a ≈5 pt strain-blue line, with a white sport pictogram;
      - a wordmark at the top;
      - "**2.0 mi** Distance | **0:19** Duration | **9:46 /mi** Pace" (labels in Title Case).
    - The share-sheet UI (transparent-background option) is **[U]**.
13. **Floating coach summary pill** at the bottom (§1.2).

**Menus.**
- "•••" opens an iOS action sheet: **Edit** · **Delete** · **Cancel**.
- Strength-Trainer-linked activities offer **Delete · Cancel** only ("Activities linked to a Strength Trainer session cannot be edited").
- Nap: Convert to Sleep **[U]**.

**Variants:**
- **Not enough HR data** [C `g24`]: "---" in place of the strain, "There wasn't enough HR data during this activity to calculate your Strain.", an empty graph, and zone rows in % of max ("ZONE 5 (90-100%) 0%" … "RESTORATIVE (<50%) 0%").
- **Recovery activity** (sauna, steam room, contrast therapy, meditation, breathwork) [C `e01–e03`, `e08–e11`]:
  1. Header as above ("STEAM ROOM", "12:37 PM to 12:47 PM").
  2. Two headline stats with **white** values:
     - "0:10:00" (≈40 pt, seconds smaller) + grey chip "▲0:08:12" + "MINUTES";
     - "0.9" + "▲0.9" + "STRESS CHANGE" (negative values occur).
  3. Coach card (1 pt blue→violet border).
     - With history: "You spent 10 minutes on this activity. This is longer than your previous average of 8 minutes."
     - Without history: "Recovery activities are low-intensity activities that promote blood flow to the muscles to help you recover from strain, fatigue, or sore muscles."
     - CTA "EXPLORE INSIGHTS →".
  4. Segmented "**STRESS | HEART RATE**".
  5. Graph:
     - stress tab: y 0.0–3.0, start value + level at the top-left ("1.7 MEDIUM"), end level + value at the top-right;
     - HR tab: `#83AAD1` line;
     - touching shows a cursor readout ("132 bpm" over "10:34").
  6. Milestone card.
  7. "**SESSION METRICS**" · "VS. 30 DAY RANGE": tiles MIN HR / AVG HR / MAX HR ("80 bpm" + chip "● 80bpm").
  8. "**IMPACT ON RECOVERY** --%" card: "Keep logging this activity to receive insights. Once you reach 5 days with and 5 days without this activity, impacts will be unlocked." + 5 progress circles (completed = blue ✓) + "1/5".
- **Strength Trainer activity** [C `g15–g18`, `g12`]:
  - a workout-name chip ("TUES (GLUTES, HAMSTRINGS, BACK)");
  - strain in `#0099FF` + chip + "ACTIVITY STRAIN", with a **CARDIO | MUSCULAR** split bar at the right (`#00588A` / `#0193E8`, white divider tick, "41%" / "59%");
  - segmented "**EXERCISES | HR ZONES**":
    - EXERCISES shows the HR graph, then a summary card: lifter icon, "11 Exercises / 26 Sets" (blue), "**3114** kg TONNAGE", "**368** TOTAL REPS", page dots, "VIEW ALL →";
    - swiping the card shows per-exercise cards with a REPS | WEIGHT | AVG HR table and a gold medal "1" on a PR set;
    - "VIEW ALL" → "‹ EXERCISE SUMMARY" (tonnage | intensity | reps, one card per exercise);
  - KEY STATISTICS: DURATION, INTENSITY, CALORIES.
  - **ZENO** cannot compute muscular load (see the comparison). It shows TONNAGE / SETS / REPS / EST. 1RM from Lift Log and omits the split bar.
- **Nap** (`r79`, `deep-dives-2026/50`): "0:50 ▼1:13 HOURS OF SLEEP", "0:28 ▼0:45 RESTORATIVE SLEEP", insight "This nap reduced your sleep need by 50 minutes.", nap metrics vs 30-day range.
- **Sleep activity** (`help-center/77`): "✕ ☾ SLEEP 11:24 pm to 6:14 am •••", "0:29 AWAKE (▼0:52)", "8 WAKE EVENTS (▼14)", insight card, HR chart, stage rows.

**ZENO extras [Z]:** keep "HEART RATE RECOVERY" (1/2/5 min) as a card after Key Statistics, and the GPX/FIT export in "•••".
- Classic `WorkoutDetailView` shows "Effort of 100". **The rebuilt screen must show 0–21 Activity Strain.**

### 3.7 Expanded day HR timeline and tilt mode [C]
**Entry.** ⤢ on Today's Activities, or rotating the phone to landscape on Home. **[U]** ZENO adds landscape detection on Home only.

**Evidence:** `help-center/106`, `reviews/r132`, `whoop-site/26`, `activity-flows-2026/e04`.

**Layout:**
- Full screen, landscape-first.
- Top bar: "✕" · "HEART RATE" · "‹ TODAY ›" · "Data synced to 07:44" (12 pt, 70%).
- Top bands: a moon band "8:30" over the sleep period (sleep colour cap) and activity bands. A selected activity's window is a lighter column with a top cap line.
- Vertical dashed markers: "RECOVERY 82%" (label in the zone colour, at wake time) and "STRAIN 4.2" (blue).
- HR line: sleep-colour line during sleep, white-50% line awake. y axis 40–200, x labels "04:00 · 08:00 · 12:00". ⊕/⊖ zoom.
- Scrub: a tooltip "**115 bpm / 10:34**" above a white dot on a dashed cursor (`e04`).
- **ZENO data:** `FullDayChartView` (already exists in More › Explore). Restyle it and move it here.

### 3.8 Start Activity: pre-start, Strain Target and live session [C, rewritten in revision 2]
**Entry.** Action menu → START ACTIVITY; the "⏱ START ACTIVITY" button on Today's Activities; "Ready to get moving?".

**Evidence:**
- pre-start: `activity-flows-2026/a01` (WHOOP staff, Aug 2025), `a04`, `a03`, `a07` (Sauna); `s02`, `s04` (2026 storyboards: same layout);
- picker: `completeness-critic/05`;
- Strain Target: `a05`, `a06`;
- live: `b01–b07`; Live Activity: `completeness-critic/27`, `help-center/20`; Apple Watch: `b09`.
- Revision 1 built this section from a marketing collage tile (`whoop-site/11c`, "LIVE SESSION / ACTIVE 01:29"). That tile is the **Strength Trainer** live session (§3.29), not this flow.

**Pre-start screen** (full-screen modal):
1. **Header bar:** translucent near-black (`#0A0D12` over the map), ≈130 pt including the status bar.
   - Left to right: a thin "✕" (≈20 pt); a white sport pictogram (≈28 pt); the activity name in Bold caps with wide tracking (≈15 pt: "RUNNING", "WALKING", "SAUNA", "WEIGHTLIFTING"); "⌄" at the far right.
   - Tapping the name or "⌄" drops the **activity picker** down from the header, and the chevron becomes "⌃" [C `completeness-critic/05`]. The picker is a black translucent full-height list containing:
     - a search field (white 10%, radius 10, magnifier, placeholder "Search");
     - underline tabs **ALL · STRAIN · RECOVERY · SLEEP**;
     - "MOST RECENT" (caps label + hairline), with the current activity highlighted by a white-8% card;
     - "ALL A-Z": rows of white pictogram + **UPPERCASE Bold tracked name**, ≈52 pt pitch, **no dividers**.
   - Text evidence: the Start list has lacked "Strength Training" in some builds; "Sleep" can be started live.
2. **Track Route** (GPS sports only): "Track Route" (grey Title Case ≈13 pt) + a small toggle at the top-right under the header. Off = light track with a white knob; on = blue knob.
3. **Background:**
   - Track Route on: a dimmed Apple Map (standard style, ≈60% darker) centred on the user.
   - Track Route off, or a non-GPS sport: a 3-D strap render on a `#293239` → `#0D1114` gradient. ZENO draws a neutral gradient with concentric halo rings and no strap render **[Z]**.
4. **Live HR circle** (§2.5): strain-blue for strain sports, `#7EB2EB` for recovery sports. Content: heart, HR ("77"), battery row ("▭ 75%").
5. **Bottom panel** (strain sports only; component §2.6.29):
   - Header row: white, top radius 10–12, grabber `#E5E5E5`, ≈83 pt.
     - Left to right: a ≈26 pt ring glyph showing the target; the target value "12.2" (black Bold ≈22 pt); "STRAIN TARGET" (black Bold caps tracked, ≈14 pt); a toggle (track `#E5E5E5`, black knob = on). Off: "◯ --- STRAIN TARGET" with the toggle off.
   - Button area: `#F5F5F5`, holding the blue capsule "**START ACTIVITY**" (`#0193E8`, ≈273 × 49 pt, white Bold caps), ≈45 pt above the bottom edge.
6. **Recovery-sport variant** [C `a07`]:
   - no Strain Target panel and no strap render, just concentric halo rings;
   - the HR circle is `#7EB2EB`;
   - a **white-outline** "START ACTIVITY" capsule on the dark background.

**Strain Target panel, expanded** (drag the bottom panel up) [C `a05`, `a06`; whether the two views are pages of one pager or one scroll is **[U]**]:
- The white header row now has "?" in a thin grey circle at the left, "STRAIN TARGET" and the toggle. The body is `#F5F5F5`.
- **Ring view:** the light-theme ring (§2.5).
  - Footer: the brand mark in a circle + "Based on your 78% Recovery, build a 13.2 Activity Strain to reach your optimal Day Strain." (black ≈20 pt).
- **Chart view:**
  - "TRAINING STATE: OPTIMAL" (black Bold caps).
  - Three legend columns joined by "›":

| Legend square | Label | Value |
|---|---|---|
| solid blue ■ | CURRENT DAY STRAIN | 12.6 |
| hatched light blue ▨ | ACTIVITY STRAIN | 13.2 |
| half solid / half hatched | ESTIMATED DAY STRAIN* | 16.1 |

  - Labels are grey caps; values are black Bold ≈34 pt.
  - The "DAY STRAIN" bar chart (§2.7).
- Text (Strain Coach article):
  - intents are Restorative / Optimal / Overreaching;
  - the target updates every 10 minutes;
  - a haptic and a notification fire at the target;
  - Strain Target activities have a 24 h maximum.

**Live session** (full-screen modal, **no tab bar, cannot be minimised**; a horizontal pager with a footer):
- **Page order:** [Heart Rate] ← [**Activity Strain**] → [Map]. The Map page exists only for GPS / Track Route activities (3 dots vs 2). Whether the pager opens on Activity Strain is **[U]**.
- **Top band:** solid `#0193E9`, ≈143 pt including the status bar, holding a white flag glyph and the elapsed time "00:27:53" (white Bold ≈20 pt), centred.
  - The flag is probably the end control **[U]**; WHOOP text says "Tap End & Save to log your workout".
  - Band history: iOS 2023 red `#FE0026`; Android Sep 2025 red-orange with "❚❚"; 2026 blue on both platforms.
- **"LIVE" button** at the top-right under the band: a ≈36 pt ring with a camera glyph and a small mark, "LIVE" (12 pt Bold caps) beneath. It opens WHOOP Live (§3.10).
- Background: the live page gradient (§2.1).
- **Activity Strain page** [C `b01–b04`]:
  1. The live ring (§2.5): "ACTIVITY STRAIN" / "10.8" / "MODERATE", with the avatar knob at the target.
  2. "HEART RATE" (grey caps ≈12 pt), the live value "142" (34 pt), and the 6-segment zone bar with "Zone 0 … Zone 5" labels.
  3. Stats row: three columns divided by hairlines, each with a grey icon, a grey caps label and a white 34 pt value: heart **AVG HR** · heart-up **MAX HR** · flame **CALORIES**.
  4. Footer: "← Heart Rate" (70%, ≈15 pt) · page dots · "Map →".
- **Map page** [C `b05–b07`]:
  - the same band;
  - a full-bleed **light** Apple Map with the route (`#0A8AF0`, ≈5 pt), the position dot and "Maps Legal";
  - a near-black stats panel (`#0E1215` → `#171E26`) with "→ DISTANCE 3.5mi | walker SPEED 3.6mph | stopwatch DURATION 0:59" (values ≈28 pt + small units);
  - footer "← Activity Strain".
- **Heart Rate page** (**[U]** for iOS 2026; from 2023 iOS and Feb 2026 Android):
  - a black circle "♥ 135 / Zone 1" (or the zone % range);
  - a full-width HR area chart;
  - "AVG HR | STRAIN | CALORIES";
  - footer "Activity Strain →".
- **Pause / resume:** **does not exist in WHOOP** as of Oct 2026 (staff text, 2025; user reports through Aug 2026). WHOOP's roadmap promises it for Nov 2026, with "Moving Time".
  - **[Z] ZENO already has pause** (`ActiveWorkout.pausedAt`). Show "❚❚ / ▶" as a round button left of the timer in the band. This is a deliberate extra.
- **End & Save confirmation and post-save summary:** **[U]**, never captured.
  - **[Z] ZENO:** the flag opens a dialog card (§2.6.30): "END THIS ACTIVITY?" / "This stops recording and saves what's captured so far." with "END & SAVE" (white capsule) and "DISCARD" (text). Then push Activity Details.
- **Lock screen Live Activity** [C `completeness-critic/27`, `help-center/20`]:
  - a heart + "137 bpm" (or "-- bpm" in grey);
  - a dark-blue capsule with a blue stopwatch + elapsed "12:17:37";
  - the 6-segment zone bar with a white knob and bold caps labels "ZONE 0 … ZONE 5" (current white);
  - a wordmark at the bottom.
  - GPS activities add "11.2 mi DISTANCE | 23.6 mph SPEED". Dynamic Island: ♥ bpm + elapsed time.
- **Apple Watch Smart Stack** [C `b09`]: wordmark, "♥ 137" (blue heart), elapsed "4:15", a mini HR sparkline and a zone-coloured bar under hour ticks.

**ZENO data:**
- `LiveWorkoutView` / `WorkoutStartControl` (live HR, zone, `ActiveWorkout.liveStrain`, GPS distance and pace, pause, End confirm).
- Live Activities (exist).
- The Strain Target ring and chart use `optimalStrainRange` + the live strain projection.
- Live Session "Silent Guardian" band → offered as an option on the Strain Target panel.
- **Fix:** show live strain on the 0–21 scale (today it defaults to Effort 0–100).

### 3.9 Add Activity, Edit Activity and the activity lists [C, rewritten in revision 2]
**Evidence:** `activity-flows-2026/c01` (Oct 2025), `s01`, `s04` (2026 storyboards), `c02–c09`, `d02–d06`, `completeness-critic/05`.

**ADD ACTIVITY sheet** (sheet with grabber over a dim; swipe-dismissable):
1. Header: "✕" · "ADD ACTIVITY" (white Bold caps tracked ≈14 pt).
2. **Info banner:** radius 12, fill `#2E404E`, sparkle icon + text `#6F93CB` (≈14 pt): "Your updates will help WHOOP autodetect and classify your future activities more accurately." A 1 pt bright-blue outline appears in 2026 storyboards **[U]**.
   - ZENO: "Your edits help ZENO recognise your activities." **[Z]**
3. **Activity row:** card `#373D42`, radius 12, ≈56 pt, with a grey pictogram + the Bold caps name ("F45 TRAINING") + "›". It reads "SELECT ACTIVITY ›" before a choice.
4. **"TIME"** (grey caps label + hairline). Rows "Start Time" / "End Time" (white ≈16 pt) with a right-aligned value pill:
   - pill fill `#303538`, radius ≈6, Bold condensed ≈14 pt, e.g. "8 Oct at 7:00 AM";
   - the **active pill is filled `#00F29E` with dark text**;
   - tapping a pill opens an **inline wheel** under the rows (date · hour · minute · AM/PM, selection band `#24292E`).
5. **Validation banner** (amber `#352B1A`, "!" + text `#D18D20`): "Invalid duration. Activities cannot start or end in the future." SAVE turns disabled.
6. **"LOCATION"** (caps + hairline): "Where did you wear your WHOOP?" (white ≈16 pt) + a full-width button (`#2B3033`, radius ≈10, ≈50 pt) showing the choice in Bold caps ("**WRIST BAND**"). Tapping it opens an inline 3-row wheel. The option list is **[U]**.
   - **[Z]** ZENO: "Where did you wear your strap?" with WRIST / BICEP / OTHER, stored on the workout.
7. **SAVE:** a full-width white capsule (≈49 pt, black Bold caps), ≈30 pt above the home indicator; disabled = `#282A2E` with dim text.

**SELECT ACTIVITY** (add flow; storyboard **[U wording]**):
- A pushed page "‹ SELECT ACTIVITY": search, 4 tabs, "MOST RECENT" (4–5 rows), "ALL A-Z".
- Its **rows are rounded dark cards**, unlike the borderless pre-start picker.
- Whether ADD ACTIVITY opens the list or the form first is **[V]** (one video shows each). ZENO: form first, with "SELECT ACTIVITY ›".

**SELECT YOUR ACTIVITY** (reclassify, from Edit or an unknown auto-detected activity) [C `c02–c05`]:
- A bottom sheet (`#272E36` → `#13181C`, grabber, top radius 12) with the header "‹ SELECT YOUR ACTIVITY".
- Search "Search for Activities" (field `#161B1F`, radius 10, 1 pt `#8D949A` border when focused, ✕ clear).
- Tabs "ALL · STRAIN · RECOVERY", plus SLEEP in some builds.
- Note line for an unknown activity: "An unknown activity was auto-detected. To improve future detection, please identify which activity you completed."
- "ALL A-Z" + hairline; rows are cards (`#2F3438`, radius 10, ≈56 pt, 8 pt gaps) with a grey pictogram + white Bold caps name.
- An empty search shows nothing. WHOOP's search is literal ("gardening" does not find "YARD WORK/GARDENING"); **[Z]** ZENO also matches words inside names and synonyms.

**EDIT ACTIVITY sheet** [C `d03`, `d04`; storyboard Jun 2026]:
- A sheet from ≈119 pt down (`#232D32` → `#101517`, grabber `#4E565A`).
- Contents: "✕ EDIT ACTIVITY"; the activity row (→ SELECT YOUR ACTIVITY); TIME pills; LOCATION; white SAVE. It is the same component as ADD ACTIVITY without the banner.
- **Edit with an HR-graph scrubber** (iOS, Jun 25 / Jul 1 2026): text only, **[U] visuals**.
  - **[Z] ZENO:** add an HR area chart between the activity row and TIME, with two draggable dashed handles (start/end) that update the pills. Reuse the cursor readout from §2.7.

**Errors** (dialog card §2.6.30):
- "OVERLAPPING ACTIVITIES" / "You added an activity from **8:54 PM to 10:04 PM**. WHOOP has detected the following activities during this time: / **Soccer** - 8:54 PM - 10:04 PM / Please go back and edit your activity or delete the overlapping activities to continue." + white "GOT IT" (`c06`).
- "REQUEST FAILED" / "Check your network connection and try again." + "CLOSE" (`c08`). Not applicable to ZENO.
- "A NETWORK CONNECTION IS REQUIRED" page (`c09`). Not applicable.

**ZENO data:**
- `ManualWorkoutSheet` (sport, start, end, distance) restyled into this sheet.
- `WorkoutTypeClassifier` sports with WHOOP-style categories (strain, recovery, sleep).
- Nap/sleep add from `SleepModel`.
- New: an overlap check against stored workouts and sleeps, and a "most recent" list (last 5 sport types).

### 3.10 ZENO Live (WHOOP Live photo overlay) [U visuals; text-only in WHOOP]
- **Purpose:** overlay real-time HR, Day Strain, Recovery or Sleep onto a photo or video.
- **Entry:** Action menu "CREATE WHOOP LIVE" and the "LIVE" button on the live session (§3.8, `b01`).
- **ZENO [Z]:** pick or take a photo. Choose an overlay template: a corner card with "RECOVERY 82%" in its colour, a strain ring, and HR. Drag to position. Export to Photos / share sheet. Offline only.
- Not on the critical path (build list P3).

### 3.11 Sleep Planner [C]
**Entry.** TONIGHT'S SLEEP card; More › Alarms; a bedtime reminder; the "Set Up Your Sleep" Get Started card.

**Evidence:** `help-center/86` (Oct 2025), `reviews/r134` (May 2026), `r133`, `r135`, `r136`, `whoop-site/31`, `help-center/02,03` (older).

**Layout, two-tone page:**
- The **upper zone** (top ≈45%) is a lighter slate (≈white 6% over the gradient).
- The **lower zone** starts at a 1 pt white-10% horizontal rule.
- A **bottom panel** (card, top radius 20) is pinned at the bottom.

1. **Nav:**
   - "✕" (iOS) / "‹" (Android) · "SLEEP PLANNER" + a "?" in a 16 pt outlined circle (help);
   - right: a 40 pt outlined circle with a calendar-moon glyph (→ My Schedule), with a tiny "OFF" / "ON" chip under it (10 pt Bold caps on white 20%, radius 4).
2. **Mark:** the ZENO mark in a 36 pt outlined circle, centred.
3. **Headline:** 20 pt Semibold, centred, 3 lines max.
   - Examples: "Go to bed at 10:00 PM today to achieve a 91% Sleep Consistency tomorrow." / "Your alarm will go off at 5:00 AM. Get to bed by 5:54 PM to achieve 100% Sleep Need." / "Get to bed by 3:05 AM to help you reach your Weekly Plan sleep goals."
4. **Goal selector:** "TOMORROW I WANT TO" (label, 50%), then a white 1.5 pt outlined capsule (h 44, text 12 pt Bold caps).
   - Values: **REACH MY SLEEP NEED** (sub-choice 70 / 85 / 100% of need) / **IMPROVE MY SLEEP** (consistency) / **REACH MY WEEKLY PLAN GOAL**. Older labels: "OPTIMIZE SLEEP".
   - Tap opens an action sheet.
5. **Lower zone:**
   - Two big times: "22:00" (32 pt; "PM" 15 pt) over "SUGGESTED TIME TO BED" (11 pt caps, 70%, 2 lines) on the left; "06:30" over "YOUR WAKE TIME" on the right.
   - Thin dashed drop-lines from each time down to the bar.
6. **"TIME IN BED"** (label, centred):
   - a full-width hatched bar (h 24) between two white 2 pt end ticks;
   - a centred black capsule badge with a white 1.5 pt outline ("8:30", 17 pt Bold condensed);
   - an alarm pin marker at the wake end when the alarm is on **[C r136]**.
7. **Optimal window:** a dashed rounded bracket under the bar, labelled "RECOMMENDED" / "OPTIMAL" (11 pt Bold caps, `#67AEE6`-grey) over "22:30 - 07:10" (12 pt, 50%).
8. **Bottom panel:**
   - Row: strap-vibrate icon · "ALARM" (label, centred) · a toggle (teal when on).
   - Two tiles (nested 10%, radius 10, h 64):
     - "ALARM SET TO" (11 pt caps, 50%) over "EXACT TIME" / "OFF" / "SLEEP GOAL" / "IN THE GREEN" (13 pt Bold caps white);
     - "WAKE TIME SET TO" over "06:30".
9. **Alarm-mode sheet** **[U]**: built from pre-2025 images (`help-center/02`, `whoop-site/48`).
   - Exact Time;
   - Sleep Goal (wake within a 1 h window once 70/85/100% of need is met);
   - In the Green (wake within the window once Recovery would reach ≥67%);
   - "Latest wake time" wheel + "SAVE & SET ALARM" (outline capsule).
   - Home shows a smart mode as "LATEST ALARM" (§3.1).
10. **My Schedule** **[U visuals]**:
    - "‹ MY SCHEDULE" with a toggle at the top-right;
    - "Create a schedule to customize your wake time by day of the week.";
    - outline capsule "CREATE SCHEDULE";
    - per-day rows.

**States:**
- Strap battery < 20%: warning banner.
- Strap not connected when saving: toast "Saving failed".
- **WHOOP oddities to avoid:** bedtimes like "6:55 PM" (users complained). ZENO clamps the suggestion to after 20:00 unless the user chooses an early wake.

**ZENO data:**
- `repo.sleepNeedTonight`;
- wind-down planner (bedtime);
- `SmartAlarmView` (strap firmware exact-time alarm, per-day wake times);
- Sleep Consistency target = projected `SleepConsistency` from the planned bed/wake times.
- **Sleep Goal / In the Green** need phone-side overnight smart wake. ZENO has it on Android only ("Wake Window"); on iOS mark these modes **BETA** and require the app to stay connected.

### 3.12 Trend View [C]
**Entry:** a My Dashboard row; a deep-dive Weekly Trends card; a contributor row; the Trends tab.

**Evidence:**
- `help-center/81`, `whoop-site/34,96`, `reviews/83`, `help-center/80`, `reviews/r144`, `r14`, `r80`;
- `deep-dives-2026/20–34, 37, 38, 44–48, 51–55` (gap-1 §4: 20+ captures, Oct 2025 – Oct 2026).

**Layout:**
1. **Nav:** "‹" · "TREND VIEW".
2. **Metric dropdown:** a full-width card (h ≈56, radius 12, `#383C40`–`#4C5458`) with the metric icon (20 pt) + "HEART RATE VARIABILITY" (13 pt Bold caps) + "⌄" at the right.
   - **[U]** Tap → a sheet listing metrics grouped "SLEEP · RECOVERY · STRAIN · STRESS · BODY" (section headers in label style). The picker sheet was never captured.
3. **Header block:**
   - Label (11 pt Bold caps, 70%): **"AVERAGE"** (most metrics), **"WEEKLY TOTAL"** (HR zones, W), **"AVG. WEEKLY TOTAL"** (HR zones, 6M), **"AVG. HIGH STRESS"** (stress).
   - Value 34 pt + unit 15 pt ("hr", "ms", "%", "bpm", "rpm", "Cals", "mL/kg/min").
   - Delta chip (§2.7 colours): "▲ 32% vs. prior week" / "▼ 16% vs. prior month" / "▲ 109% vs. prior 6 months" / "▲ 2.6 vs. prior week" (strain, absolute) / "● 0% vs. prior month".
   - **HOURS VS. NEEDED (HOURS)** shows two stacked values: "7:40 hr ▼1% / AVG. NEED" (value teal) and "6:49 hr ▼14% / AVG. HOURS" (value blue), each with a mini chip.
   - Right: segmented control "W | M | 6M" (well `#14181C`, selected `#2C3034`). VO₂ Max and ZENO Age use "M | 6M".
4. **Range pager**, right-aligned under the segmented control: "‹ APR 9 - APR 15, 26 ›" (13 pt Bold caps; disabled chevron grey).
5. **Insight paragraph:** 17 pt Regular, white. Examples:
   - "Your average HRV during this 7-day period was above its typical range (18 - 24) at the time."
   - "Your average Recovery this month was below your previous 30-day average of 73%."
   - "Since Monday, you've averaged a higher Day Strain (18.4) than you did in the previous week. You're tracking towards a week of all out Strain."
   - "Your average steps are down from last month. Add a few more steps each day to see progress."
   - "During this 7-day period, your total time in HR zones 4-5 (0:33) was above your previous 7-day total of 0:25."
6. **Legend:** "■ TYPICAL RANGE" (HRV, RHR) or series legends ("■ SWS (DEEP) ■ REM", "■ ZONE 4 ■ ZONE 5", "■ HIGH ■ MEDIUM ■ LOW") right-aligned.
7. **Chart**, 260 pt, chosen by range and metric (§2.7):
   - **W:** daily bars with labels (Recovery zone-coloured; y labels coloured by zone "100% / 66% / 33% / 0%"), lines with markers and a typical band (HRV, RHR), or stacked bars (zones, restorative, stress).
   - **M:** daily bars or points + the white dashed **AVG.** line and pill.
   - **6M:** dimmed data + monthly segments with values and coloured % change.
   - **[U]** Press-and-drag to scrub: a vertical white rule plus a callout with date and value (not captured on Trend View; the cursor style is from Activity Details).
8. **Footnotes** (13 pt `#B8BABB`, "ⓘ" glyph): "Average does not include today (Apr 20)", "Zone time is derived from logged activities", "The Steps algorithm was updated for 5.0 devices. Some change in average values are expected."
9. **Breakdown block** (per metric): caps title + a stacked horizontal bar + legend rows "■ <count or time> <label>":

| Metric | Title | Rows |
|---|---|---|
| Recovery | "RECOVERY BREAKDOWN (DAYS)" | "■ 11x Green (67-99%)", "■ 17x Yellow (34-66%)", "■ 2x Red (1-33%)" |
| Day Strain | "STRAIN BREAKDOWN (DAYS)" | "■ 1x All Out (>18.0)", "■ 4x Strenuous (14.1-18.0)", "■ 2x Moderate (10.1-14.0)"; a "Light" row **[U]** |
| HR zones | "HR ZONES BREAKDOWN (WEEKLY TOTAL)" / "(AVG. WEEKLY TOTAL)" | "■ 0:30 ZONE 4", "■ 0:03 ZONE 5" (2026: mixed case "Zone 4") |
| Strength time | "STRENGTH ACTIVITY BREAKDOWN (WEEKLY TOTAL)" **[U]** | per-sport rows "■ 3:05:26 Weightlifting" **[U]** |
| Sleep | "SLEEP EFFICIENCY BREAKDOWN (DAYS)", "RESTORATIVE % BREAKDOWN (DAYS)" | "150x HIGH (>45%) · 25x SUFFICIENT (30-45%) · 4x LOW (<30%)", "12x OPTIMAL (>85%) / 16x SUFFICIENT (70-85%)" |

10. **CTA row cards** (`#28282C`, ≈56 pt, Bold caps + "›"):
    - "+ ADD ACTIVITY ›" (zones, strength);
    - "UPDATE YOUR DAILY STEP GOAL ›", renamed "**SET A STEPS GOAL IN WEEKLY PLAN ›**" in Sep 2026;
    - "SET A … GOAL IN WEEKLY PLAN ›" for strength **[U wording]**.
    - Explainer headings like "What is Strength Activity Time?" + paragraph.
11. **Menstrual-cycle overlay** (Hormonal Insights on):
    - phase legend chips "● FOLLICULAR ● LUTEAL ● MENSTRUAL ● OVULATORY";
    - a phase-coloured strip under the x axis;
    - an info card "See patterns in your trends data across your menstrual cycle. You can disable this overlay from Hormonal Insights settings at any time."
12. **"LEARN MORE"** with "VIEW ALL →": WHOOP shows video cards here. **ZENO omits them** [Z] or links to `ScoringGuideView` text.
13. **Metric-specific extras:**
    - VO₂ MAX: "YOUR CARDIO FITNESS LEVEL ⓘ" percentile scale card (§3.28); "+ ADD MANUAL VO₂ MAX VALUE"; "+ Update Weight" **[U sheets]**.
    - Weight / Lean Body Mass: "+ ADD ENTRY" **[U sheet]**.
    - TIME IN BED (M): floating bars plus two white dashed lines with white pills for the average bedtime and wake ("20:32" / "04:36").

**Metrics to support** (WHOOP list, 2026):
- **Sleep:** Sleep Performance, Hours vs Needed (hours and %), Time in Bed, Sleep Consistency (Trend View never captured **[U]**), Restorative Sleep (% and hours), Efficiency, Sleep Debt.
- **Strain:** Day Strain, Strength Activity Time, Calories, Average HR, Steps, HR Zones 1-3, HR Zones 4-5, VO₂ Max (M/6M only).
- **Recovery:** Recovery, RHR, HRV, Respiratory Rate.
- **Stress:** Total Day, Sleep, Non-Activity Stress. These use the "AVG. HIGH STRESS" header and 100%-stacked bars. Example: "You spent an average of 3:37 hours in the high-stress zone this week, which is above your previous 7-day average (2:56). This excludes time spent in Sleep and Strain activities."
- **Body:** Weight, Lean Body Mass.

**[Z] ZENO extras:**
- Add "1Y" and "ALL" segments. WHOOP users explicitly asked for a year view, and ZENO already has the data (`MetricDetailView` ranges).
- Add a "WHAT CORRELATES" card below the chart (the existing Pearson scan) in the standard card style.

**ZENO data:** `MetricDetailView` series + baselines. Typical range = 30-day mean ± 1 SD, or ZENO's personal-baseline band once trusted. Breakdown counts use the same thresholds as the deep dives.

### 3.13 Customize Dashboard [C]
**Entry:** "CUSTOMIZE ✎" on My Dashboard.

**Evidence:** `reviews/04` (iOS, Oct 2025), `reviews/r110` (Android 2026), `completeness-critic/16` (rows in use).

**Layout:**
- Full-screen modal: "✕" · "CUSTOMIZE DASHBOARD" (navTitle).
- **Current items:** rows (card, h 60, radius 12) with a ≡ drag handle at the right; a small bar-chart glyph marks chart items (Stress Monitor, Strain & Recovery); a "–" remove button at the left in edit style **[Z]** (WHOOP users could not find how to remove).
- **"ADD TO MY DASHBOARD"** (section label + trailing hairline): rows of icon + caps label + "+" at the right.
  - Items seen in the add list: AVERAGE HEART RATE, CALORIES, HOURS OF SLEEP, HR ZONES 1-3 (WEEKLY), HR ZONES 4-5 (WEEKLY), HR ZONES ALL (WEEKLY), LEAN BODY MASS, RESPIRATORY RATE, DAY STRAIN, VO₂ MAX, SLEEP PERFORMANCE, STRESS MONITOR, STRAIN & RECOVERY, STRENGTH ACTIVITY TIME.
  - Items seen on dashboards: HRV, RHR, STEPS, SLEEP CONSISTENCY, RECOVERY, SLEEP NEEDED, **SLEEP DEBT**, **WEIGHT**, **RESTORATIVE SLEEP (%)**.
- **Pinned bottom:** an outline capsule "SAVE" (2 pt `#67AEE6`, 322 × 52, 16 pt above the safe area). It is disabled until a change is made **[U]**.

**[Z] ZENO-only items:** SKIN TEMP, BLOOD OXYGEN (when imported), TRAINING LOAD (CTL/ATL/TSB chart card), READINESS, TOMORROW'S RECOVERY FORECAST, HYDRATION, BODY CLOCK. (Revision 1 also listed SLEEP DEBT and WEIGHT here; both are WHOOP items.)

**ZENO data:** reuse the `EditableLayoutList` / `TodayCustomizationSheet` persistence.

### 3.14 Coaching card stack (Home notifications) [C]
**Evidence:** `appstore/ios69-01`, `play-01`; `help-center/04,37,83`; `reviews/r130,r141,r143,r15,r27`; `whoop-site/03,04`; `profile-community-2026/16,19,34,35,39,59`; `journal-plan-2026/11,12,15`; `activity-flows-2026/g21`; `onboarding/33a,33b`; `health-more-2026/23`.

**Behaviour:**
- One card is visible; the next one peeks underneath.
- The counter chip completes or dismisses the top card. It reads "✓ n" (n = cards remaining); some 2026 cards show a different glyph ("◜ 3"), whose meaning is **[U]**. Swipe left/right for the next card **[U]**.
- Tapping the card body or its CTA opens the destination.
- Cards are ordered by priority. The stack hides when empty. If the feed fails to load, the slot shows the dashed error box (§2.6.5).

**WHOOP cards seen:**
- "Optimal Health";
- "Building Fitness Gains" ("You're building fitness by entering your optimal Strain range. Keep pushing yourself towards your target of 15.5 to see even greater results.");
- "Strain Target Reached", "Reaching Optimal Strain", "Recovering from Strain", "Low HRV";
- "Pushing Limits" ("You worked hard today and exceeded your Optimal Strain range…");
- "Newly Red" (mini chart art, "VIEW TREND →" blue);
- "1% Club": "Today might not feel great, but hang in there! You're in good company along with 0.5% of other WHOOP members." + "VIEW TREND →" [POP];
- "99% Club": "A near-perfect recovery means your body is recharged. Lean in and make the most of your energy today.";
- "Zombie Sleeper": "You're on a streak of bad sleep, but you can get through it! Try to treat yourself with extra care today.";
- "Turn Off Your Alarm? / You have an alarm scheduled today, but it looks like you're already awake. TURN OFF ALARM →";
- feature announcements (promo borders, §2.1):
  - "Your Home Has a New Look" (LEARN MORE →);
  - "Coach at Your Fingertips" ("Coach is now in your bottom navigation bar. Tap the "+" button next to My Day to quickly log activities, start Strength Trainer, and more.");
  - "Introducing achievements" ("Get rewarded for your progress and consistency on WHOOP with achievements." VIEW ACHIEVEMENTS →);
  - "You Asked, We Delivered" / "Create your own Journal behaviors" (CREATE NOW →);
  - "More Credit for Strength";
  - "All-In 250 Challenge Starts Today" (GET STARTED →);
  - "Exercise Trends in Strength Trainer … SHOW ME AROUND →";
- error: "Couldn't load new notifications. We'll try again later."

**[Z] ZENO local rule engine.** Cards are generated on-device from snapshots:

| Card | Trigger |
|---|---|
| Optimal Health / Building Fitness Gains / Recovering from Strain | Recovery band × strain progress |
| Strain Target Reached | strain ≥ the target tick |
| Pushing Limits | strain > range top |
| Low HRV | HRV z < −1 |
| Newly Red | Recovery < 34 after a non-red day |
| Lowest in a while (replaces "1% Club") | Recovery ≤ 5%, or the lowest in 90 days ("Your lowest Recovery since Jun 3") |
| 99% day | Recovery ≥ 99% |
| Rough sleep streak (replaces "Zombie Sleeper") | 3+ nights of Sleep Performance < 70% |
| Illness heads-up | `IllnessSignalEngine` (ZENO extra) |
| Auto-detected workout, Save / Dismiss | `AutoWorkoutDetector` (ZENO extra) |
| Turn Off Your Alarm? | awake before the alarm |
| Sleep debt rising | > 2 h |
| Achievement unlocked / Level up | §3.30 |
| Your week in review (Monday) | §3.40 |
| Calibrating n/4 | calibration |
| Strap battery low | battery |
| What's new in ZENO | app update (one card per release) |

### 3.15 Daily Outlook / Day in Review [C]
**Entry:** the My Day coach pill.

**Evidence:** `reviews/09` (sheet), `reviews/88` (Daily Outlook page, BETA V3.0), `whoop-site/37` (BETA V2.0).

**Layout (page variant):**
- Nav: "‹"/"✕" · "DAILY OUTLOOK" + a "BETA V3.0" chip under it (10 pt Bold caps on white 20%) · history clock icon.
- Background: the Daily Outlook gradient (tan → slate → near-black); evening uses the indigo tint **[U]**.
- An assistant message with the 24 pt coach avatar:
  - greeting "Hi Connor, / Happy Tuesday!" plus a weather line;
  - "**Key Insights**" (15 pt Semibold) with bullets, numbers in Bold white: "Your Recovery is currently at **44%**, significantly lower than your average of **69%**…";
  - "**Activity Recommendations**" with bullets, e.g. "**Assault Bike:** A 10-minute session will push your Strain to **10.6**…".
- The composer is pinned at the bottom (§3.16).
- **2025–26 sheet variant:** tapping the pill opens the Coach bottom sheet with this message as the first assistant turn.

**Day in Review** (evening): a recap of the day's metrics and behaviours plus a bedtime range. WHOOP removed the sleep-recommendation UI in Jun 2026; it is now an in-chat card. WHOOP's Sep 2026 roadmap merges Journal, Daily Outlook, check-ins and Day in Review into one "Unified Daily Experience" (text only **[U]**).

**[Z] ZENO:**
- With a configured provider, `CoachBriefScheduler` generates the text.
- Without one, a **deterministic template** fills the same layout from local data:
  - Recovery vs 7-day average;
  - Sleep Performance;
  - journal streaks;
  - zone minutes this week;
  - the strain target;
  - the bedtime from the Sleep Planner.
- No weather (no network).

### 3.16 Coach chat, conversation history and My Memory [C]
**Entry:** the AI button; coach pills; the floating summary pill; insight CTAs; "Ask a question" boxes; the Profile "MY MEMORY" row.

**Evidence:**
- sheet: `reviews/r123` (v6.0, Oct 2026), `profile-community-2026/66` (v6.1, Oct 2026), `/28, /29` (beta v5.3, May 2026), `/03` (2025 Android, history clock), `reviews/09` (v5.0), `appstore/ios69-07`;
- journal writes: `journal-plan-2026/04, 06`;
- AI chart: `profile-community-2026/74`;
- My Memory: `/24–/27`, `/72`, `/73`, `/55`, `help-center/07`, `/111`.

**Sheet layout:**
- **Bottom sheet** (grabber, top radius 24; medium → large detents). Background near-black with an indigo/violet glow at the top.
- **Top bar (v6.x):**
  - left: a pill (white 10%, h 32, radius 16) holding the 24 pt coach avatar ring + version ("v6.1"; 13 pt Semibold);
  - centre: the grabber;
  - right: "**Memory**" (13 pt) + a lightbulb-sparkle icon.
  - **No history clock** in v6.0/v6.1 (`/66`, `reviews/r123`). Beta v5.3 (May 2026) and 2025 builds show the clock (circular arrow + clock hands, 22 pt) at the right. Where history went in v6 is **[U]**.
- **Messages:**
  - assistant: plain text with no bubble, 15–17 pt Regular at white 85%, bold for numbers and metric names, bullets allowed;
  - under each assistant reply: copy / thumbs-up / thumbs-down icons (18 pt, 50%);
  - user: right-aligned bubble (`#343850` in 2026, ≈`#343A3E` in 2025; radius 12–16, padding 12 × 10), white 15–17 pt.
  - **Action receipts** above a reply when the AI wrote data: one grey line with a light-blue ✧, e.g. "✧ Logged Nicotine from Aug 28 through Today", "✧ Updated Nicotine for Aug 27" (`journal-plan-2026/04`).
- **Suggestion chips:** a horizontal scroller above the composer. White filled capsules (h 36) with black 13–15 pt text ("Yes, give me training guidance today", "Explore popular public teams"). 2025 builds showed rows with "↑" instead.
- **Composer:**
  - left: a 44 pt "+" square (fill `#2C2C2C`; new chat / attach);
  - field: h 48, radius 14, 1.5 pt AI input gradient border, placeholder "Ask ZENO anything" (15 pt, 40%), fill `#101828`;
  - inside the field at the right: a mic icon (v6.x) or ↑ send (white when enabled).
  - A floating "↓" scroll-to-bottom bubble appears when scrolled up.
- **Rich cards in chat:**
  - SLEEP RECOMMENDATION: bedtime/wake panels, "TOMORROW'S PREDICTED SCORES 8:25 hr HOURS OF SLEEP / 77% CONSISTENCY", "✎ EDIT SCHEDULE", gradient border;
  - workout suggestion carousel: sport, duration, estimated strain, intensity bar, "COMMIT" / "GENERATE ALTERNATIVES";
  - **AI-generated charts** [C `/74`]: a titled chart card ("STRAIN & RECOVERY — LAST 30 DAYS") in the §2.7 style.
- **Threads:** context-bound. Opening Coach from a sleep or a workout reopens that item's own thread; other threads are free chats.
  - Users cannot name or pin threads (forum 14402). The **history list itself was never captured [U]**.

**My Memory (2026)** [C]:
- **Entry:** the Profile "MY MEMORY" row (§3.30) and the sheet's "Memory" button.
- **First run** (3 full-screen pages on near-black):
  1. Page 1: "✕". Floating glass chips with ✦ icons: "What I'm working toward", "What's limiting my time or energy", "My daily routine and schedule", "Injuries or health changes" (fill `#1B2932`, border `#1A2730`).
     - Title "Your life changes. Your coaching should too." (26 pt Semibold).
     - Body "WHOOP now understands more about what's going on in your life — your goals, routines, and health. / That means smarter check-ins, better timing, and guidance that shows up when it matters most."
     - "GET STARTED" + a 64 pt pink→violet gradient circle with →.
  2. Page 2: "Tell WHOOP what's going on." / "Add updates about your goals, routine, or health at any time. / The more WHOOP understands, the more it can anticipate what you need and guide you in the moment." + "NEXT" + the ring button.
  3. Page 3: a phone mock of Memory Detail. "You're always in control." / "See what WHOOP understands about you and shape it anytime. / Confirm what's right, refine what's not — your coaching evolves with you." + "VIEW MY MEMORY" + a 64 pt green `#00F19D` circle with ✓.
- **Main page, empty** (`/27`):
  - "‹ MY MEMORY";
  - "Shape your WHOOP experience." (26 pt Semibold, left; ZENO: "Shape your ZENO experience."), the avatar (56 pt) at the right, and the sub-line "Help WHOOP understand you better." (13 pt, 80%);
  - an AI entry card (§2.6.33, radius 20): box art, "Share something new" (17 pt Semibold), "The more WHOOP knows, the better your guidance becomes", [⌨ TEXT] [mic TALK] (h 48, radius 12);
  - "HOW DOES WHOOP MEMORY WORK? →" (12 pt Bold caps, gradient text).
- **Main page, populated:**
  - toast "✓ Context updated / New information applied to Coach.";
  - filter chips (§2.6.35). The 2025 render shows "Timeline | Goals | Lifestyle | Health condition". The 2026 categories are text-only: **Goals · Identity · Lifestyle · Preferences · Events · Health History · Mood**. The production chip row is **[U]**.
  - dated sections ("TODAY", "TUE, MAY 20, 2025", 11 pt caps + hairline);
  - memory cards: title + "New" pill + "›", tags "Active" (blue fill) and a category (outlined); the newest card has a violet→cyan border.
- **Memory detail** (`/72`):
  - "‹ MEMORY DETAIL" + a trash icon at the right;
  - title "Has a son" (22 pt Semibold), body (15 pt, 70%), a category tag ("Identity", outlined capsule);
  - a card (radius 14, `#2B3033`): lightbulb + "**Active**" (17 pt Semibold) over "This is actively influencing your coaching." (13 pt, periwinkle `#8F9BFF`), with a toggle tinted `#7888FF` (off = "Inactive" **[U]**);
  - the "Share something new" card;
  - "**Relevant Conversations**" (15 pt Semibold) + bullets "• **May 16, 2026** Has a son named …".
- **Global switch:** in "✕ AI SETTINGS" (`/55`), a row "MEMORY" with a toggle and the helper text "Allow WHOOP to remember details from past conversations to provide personalized guidance. All data is stored securely by WHOOP and never shared with a third party." Then a dashed divider and a "Data privacy … LEARN MORE →" card.

**[Z] ZENO:**
- `CoachView` restyled. Keep provider setup (OpenAI / Anthropic / Gemini / local OpenAI-compatible), voice input, and the Coach on/off switch.
- **History list (ZENO extra):** a clock icon left of "Memory" opens a sheet of local threads. Each row: the title (first user message), a 2-line snippet of the last message, a relative date; swipe to delete.
- My Memory is a local `MemoryStore` (category, title, detail, active flag, created date, source thread ids). Only Active items go into the system prompt.
- Journal writes from chat (§3.17) show the same "✧ Logged …" receipts.
- Coach off → the AI button, pills and Ask rows are hidden.

### 3.17 Journal [C, rewritten in revision 2]
**Entry:** Action menu → COMPLETE YOUR JOURNAL; the Home MY JOURNAL card; the morning prompt; the "Customize Your Journal" Get Started card.

**Evidence:**
- `journal-plan-2026/01` (today, sand, Jun 2026), `07` (purple, Jun 2026, measured), `16` (Smart log card), `05` (Sep 2026, behind the AI sheet), `08` (follow-ups), `09`, `10` (errors), `90`, `91`, `93`, `95` (2025);
- `help-center/105` (date row, calendar); `reviews/89`.
- Storyboard `journal-plan-2026/40–43` (order only).

**Layout** (full-screen modal):
1. **Background:** a fixed gradient (rows scroll over it), from one of two themes [C; the rule is inferred **[U]**]:
   - **today** = warm sand → slate → near-black;
   - **a past day or the morning prompt** = purple → near-black (§2.1).
2. **Nav:** "✕" (44 pt tap target, 16 pt inset) · "JOURNAL" (12–13 pt Bold caps, tracked, centred) · ✎ (→ SELECT BEHAVIORS).
3. **Date row:** "‹ TODAY ›" or "‹ MON, MAR 16 ›" (13 pt Bold caps, centred). The 2025 build had an outlined "☀ INSIGHTS" pill at the right; it is not visible in 2026 frames **[U]**.
4. **Day strip** (swipe back up to 14 days):
   - capsules 56 × 104, radius 28, fill white 12%; the selected capsule has a 2 pt white outline;
   - each holds the weekday "Mon" (13 pt, 70%), the date "16" (20 pt Bold condensed), and a status mark (a small ✓ under logged days).
5. **Question title:** "What's happening today, June 30?" / "What happened on Mon, March 16?" / "What happened yesterday, August 27?" (≈28 pt Semibold, 2 lines, left at 16 pt).
6. **AI entry card "Smart log with WHOOP AI"** (2026) [C `16`, measured; `05`]:
   - component §2.6.33: x 16 → 377, ≈108 pt, radius ≈20;
   - row 1: a three-star sparkle + "Smart log with WHOOP AI" (≈20 pt Semibold);
   - row 2: "⌨ TEXT" and "mic TALK" buttons;
   - under the card, a centred grey caption "**Your answers are saved automatically**" (≈16 pt);
   - it sits **above** the behaviour rows. Users complain it pushes the rows down; ZENO lets it collapse to a single row after first use **[Z]**;
   - tap → the Coach sheet over the Journal, where mentions are logged with "✧ Logged …" receipts. It is not shown on the morning prompt.
7. **Plan section** (only while a Weekly Plan has behaviour goals) [C `05`, `90`, `91`]:
   - label "YOUR CUSTOM PLAN" / "YOUR BOOST FITNESS PLAN" (caps ≈11 pt, white 50%, hairline);
   - one card per plan behaviour: a small progress ring with "0/5" inside, then the question ("Avoided Alcohol?", "Avoided Late Meal?"), then ✕ ✓;
   - follow-ups can hang off ✕ when the question is phrased "Avoided …?" ("When was your last dose?").
8. **Behaviour rows**: every behaviour is its **own rounded card** [C `01`, `07`, `08`]:
   - inset 16, h ≈64 (one-line question), gap ≈12, radius ≈12;
   - fill is translucent over the gradient (`#443A6C` on the purple top, `#303143` mid, `#282C2F` on the dark bottom);
   - the question is white ≈15 pt Medium, phrased as a question ("Took electrolyte supplements?", "Viewed a screen device in bed?");
   - the ✕ / ✓ toggles sit at the right (§2.6.21);
   - rows are **alphabetical by question** within a section;
   - custom behaviours carry an outlined "Custom" chip (§3.17b).
9. **Sections:**
   - Through mid-Sep 2026 the order was **DAYTIME · NIGHTTIME · STATUS** (caps label + hairline, white 50%). A section shows only when it has selected behaviours.
   - STATUS holds "Feeling sick or ill?", "Have an injury or wound?", "Took a vacation day?".
   - **[V]** About 17–19 Sep 2026 WHOOP removed the day/evening split (forum 16282); the replacement order is **[U]**. ZENO keeps the sections **[Z]**.
10. **Follow-ups** (inside the same card, under a hairline, once ✓ is chosen) [C `08`]:
    - **quantity row:** label "For how long (minutes)?" (≈15 pt, indented ≈16 pt) with a right-aligned value capsule (radius ≈8): empty "-- Minutes" / "-- grams" on translucent grey; filled = blue `#78ACE0` with black Bold "15 Minutes";
    - **time row:** "When did you stop?" / "When did this occur?" with the value right-aligned in blue ("18:00") or "--";
    - under it, a **slider**: 4 pt track, blue `#70A8D8` fill left of a white ≈28 pt knob, grey `#6C6C78` remainder.
11. **NOTES:** label "NOTES", then a multi-line field "Add a note..." (darker than the page `#080C10`, 1 pt border `#202428`, radius ≈8, ≈56–64 pt).
12. **"SAVE JOURNAL"**, pinned: white `#F9F9F9` capsule, ≈48 pt, 23–24 pt side margins, black Bold caps ≈14 pt. Content fades out above it.
13. **Morning prompt only (2025):** a "USE PREVIOUS ANSWERS" toggle (caps label + "?" info) under the title. Reported missing in Sep 2026 **[U]**. ZENO keeps it **[Z]**.

**States:**
- **Dismiss confirmation** (✕ with unsaved answers) [storyboard; wording **[U]**]: a dialog card (§2.6.30) with a caps title, a 3-line body, a "don't show again" checkbox, a white capsule and a caps text button.
  - **[Z]** ZENO: "DISCARD CHANGES?" / "Your answers for today haven't been saved." / "SAVE JOURNAL" / "DISCARD".
- **Save failed** [C `09`]: the full-screen error page (§2.6.31) "YOUR ENTRY WAS NOT SAVED" / "Check your network connection and try again." / RETRY / CLOSE. ZENO only needs it for local store errors.
- **Load failed** [C `10`]: "✕", cloud-slash icon, "ERROR", "Please check your internet and try again." Not applicable to ZENO.
- **Calendar** (from the date row): a month grid. Logged days are teal numbers with a teal dot; others are 50% grey. Today has a dashed circle. Legend "• Journal filled out" (`help-center/105`).

**3.17b SELECT BEHAVIORS editor** (replaces revision 1's "Customize Journal" ⊕ sheet, which came from a marketing render) [C `journal-plan-2026/02` (Jun 2026), `13`, `14` (Sep 2026), `92` (2025)]:
1. A full-height sheet with a grabber (gradient `#283840` → `#182028`).
2. Header: "✕" · "SELECT BEHAVIORS" (13 pt Bold caps).
3. **Search** "Search for Behaviors" (h ≈44, radius 10, fill `#10181C`). It matches exact names, then fuzzy ("Hydrtion" → Hydration), then synonyms ("Coffee" → Caffeine).
4. **Category tabs:** a horizontal scroller of caps labels, with the selected tab white plus a 2 pt underline. Order: **ALL · (CUSTOM BEHAVIORS) · DRUGS & MEDICATION · HEALTH & SYMPTOMS · HORMONAL HEALTH · LIFESTYLE · MENTAL WELLBEING · NUTRITION · RECOVERY · SLEEP & CIRCADIAN HEALTH · SUPPLEMENTS**.
5. **CUSTOM BEHAVIORS tab:** a "Create Custom Behaviors" AI entry card ([⌨ TEXT] [mic TALK]). Creating a behaviour is a Coach conversation that proposes a name, unit and daily question, confirmed with "Add" (text; visuals **[U]**).
6. **"CURRENTLY SELECTED"** (caps label + hairline), then rows:
   - title (white ≈16 pt, e.g. "Device (e.g. Phone) In Bed") over the journal question (grey ≈13 pt, "Viewed a screen device in bed?");
   - a 24 pt checkbox at the right (radius 4; checked = blue `#64ACE4` with a dark ✓);
   - an optional third line "Pre-filling compatible via Apple Health. ⓘ";
   - an outlined "Custom" chip on custom rows;
   - a ≈52 pt pitch with no hairlines.
7. **"NOT SELECTED"**: alphabetical rows with empty checkboxes (1.5 pt white outline).
8. **"SAVE BEHAVIORS"**, pinned. The Sep 2026 version is a white filled full-width capsule (Jun 2026 was an outlined ≈60%-width capsule).

**ZENO data:**
- `InsightsView` journal log: yes/no plus numeric questions, custom questions, groups, mood 1–5, caffeine log.
- **Mood and caffeine become questions** in this layout **[Z]**.
- Map ZENO's groups onto WHOOP's nine categories, add the starter set's questions in WHOOP's phrasing, and keep custom questions (no AI needed to create them).
- Apple Health pre-fill: mindful minutes and workouts from the existing import.

### 3.18 Behavior Insights and Behavior Details [C, rewritten in revision 2]
**Entry:**
- the Home MY JOURNAL card's "BEHAVIOR INSIGHTS" button;
- the Recovery dive's Behavior Insights card;
- "EXPLORE YOUR RECOVERY INSIGHTS →";
- Coach.

A centred spinner shows first.

**Evidence:**
- `journal-plan-2026/20` (Apr 2026), `20a` (whole page, German, Jun 2026), `completeness-critic/21` (Aug 2026), `/20` (Logging History);
- `journal-plan-2026/26`, `26a`, `28`, `29` (Behavior Details);
- older variants `21–24a`, `appstore/ios69-08`.

**BEHAVIOR INSIGHTS page:**
1. Nav: "‹" · "**BEHAVIOR INSIGHTS**". The page is a slate gradient (`#242830` at the top).
2. "Recovery Impact Analysis" (white ≈22 pt Semibold, left 16), then the body "See how behaviors impacted your Recovery over the past 90 days. Tap on a behavior to view more details." (grey ≈15 pt, 3 lines).
3. **Legend row:** an orange-tint chip (`#3C3424`) with ▼ + "HURTS" (orange `#EDB157`) at the left; "% IMPACT" (white caps) centred; "HELPS" (green `#05F7A7`) + a green-tint chip (`#184038`) with ▲ at the right. All ≈11 pt Bold caps.
4. **Unlocked behaviour cards** (fill `#303438`, radius 12, ≈68 pt, 8 pt gaps):
   - line 1: the **name in Title Case** (white ≈16 pt: "82%+ Sleep Performance", "Sleep In Own Bed", "9%+ of the Day in High Stress Zone", "Consistent Wake Time"). Auto-tracked behaviours carry a small `#344048` chip with a light-blue ✧ after the name. A grey "›" sits at the top-right; some rows have a blue "!" chip left of it (meaning **[U]**);
   - line 2: the diverging bar (§2.6.20) and the value at the right;
   - sort: most positive first, then the non-significant (grey), then the most negative.
5. **"KEEP LOGGING TO UNLOCK"** (white caps ≈13 pt Bold), then "Record at least 5 yes's and no's in your journal to see how behaviors impact your Recovery." (grey ≈15 pt).
   - Locked behaviours use the outlined card (§2.6.28) with count badges "☒ 51 ☑ 18".
   - **Three subtitle variants:**
     - "Unable to identify a significant impact. Please keep logging responses.";
     - a low-confidence wording (German only; English **[U]**);
     - no subtitle (title, track and counts only).
6. End of the list: a wide card with a 2-line title, a body, a link and notebook art (probably "Explore more behaviors" → SELECT BEHAVIORS **[U]**).
7. **Nothing unlocked yet:** only section 5 shows; whether the header block stays is **[U]**.
   - Unlock rule: 10 Recoveries, then ≥5 yes and ≥5 no within 90 days on days with a Recovery.

**BEHAVIOR DETAILS page** [C `26`, Sep 2026; `28`, `29`; storyboard]:
1. Nav: "‹" (pushed) or "✕" (modal) + "**BEHAVIOR DETAILS**", floating over the hero.
2. **Hero photo** behind the top ≈35–40%, fading into the page `#101418`. Behaviours without art show a large faint watermark circle instead (`26a`).
   - **[Z]** ZENO uses a large SF Symbol on a soft gradient; no stock photos.
3. Name ("Late Workout", 26–28 pt Semibold, left 16).
4. **Impact card** (translucent dark, radius ≈14, inset 16, padding ≈20):
   - a row with "RECOVERY IMPACT" (13 pt Bold caps) and a verdict chip at the right ("**Negative**": fill `#544430`–`#584830`, text `#EAB977`; "Positive": green tint and text; radius 6);
   - "⌃/⌄" when the behaviour has follow-up questions;
   - the wide diverging bar with the value "-6%" (≈30 pt Bold, small "%");
   - **[POP]** a thin white tick at the WHOOP member average and the caption "WHOOP MEMBER AVERAGE: -2%". ZENO omits both **[Z]**;
   - **expanded breakdown** (an inner card `#14181C`), one block per follow-up question:
     - question header (grey caps ≈13 pt: "HOW MANY ALCOHOLIC DRINKS DID YOU HAVE?", "WHEN WAS YOUR LAST DRINK?");
     - rows of bucket labels (white ≈17 pt: "1 Drinks", "2-6 Drinks", "0-2 Hours before bed") with right-aligned impacts ("-6%" orange, "+5%" green, "0%" grey).
5. **Logging History** (journal behaviours only; auto-tracked ones skip it): "Logging History" (≈26 pt Semibold), the pager "‹ MAR '26 - MAY '26 ›", and the 3-month calendar (§2.7).
6. "**Impact of {Behaviour}**" (≈22 pt Semibold) + 2–4 grey paragraphs (`#C5C6CA`, ≈15 pt).
7. **"RECOMMENDATION"** box: card `#202C34`, radius 12, a lightbulb + "RECOMMENDATION" in blue caps (`#8EB4DF`), then body text.
8. Anything below is **[U]**.

**Variant** (`26a`, Apr 2026): "NEGATIVE IMPACT" chip (`#F7AB41` on `#302C1C`) + "-3%".
- The sentence "After accounting for other influences, this behavior has a -3% impact on your Recovery."
- A legend row "▼ HURTS · RECOVERY IMPACT · HELPS ▲", with the inapplicable side dimmed.
- A "**You**" marker (orange) on the bar.
- A logged-count card: the question "Took a rest day?", "# of times this behavior has been logged yes or no in the past 90 days", and two outlined squares "5" (✕) and "11" (✓, blue).

**Older variants (do not copy):**
- an "✕ RECOVERY INSIGHTS" modal with ALL-CAPS names;
- "REFRESHED DAILY. LAST REFRESH: JAN 16, 2026, 08:58." above "Recovery Impact Analysis";
- the App Store mock (`appstore/ios69-08`), "JOURNAL INSIGHTS" with ALL-CAPS cards and a "NEW" chip.

**Behavior Trends** (Mar 2026 text: "Calendar views show when and how often you log each behavior"): no separate screen was found. It is the Logging History block. Treat any other view as **[U]**.

**ZENO data:**
- `BehaviorInsights` / `EffectRanker` (Cohen's d with multiple-testing control).
- **% impact** = (mean Recovery on yes-days − mean on no-days) ÷ the no-day mean. Grey when not significant.
- Auto-tracked behaviours come from ZENO data:
  - "85%+ Sleep Performance";
  - "Consistent Bed Time / Wake Time";
  - "Early / Late Workout" (workout within 3 h of bed);
  - "X%+ of the Day in High Stress Zone";
  - "10+ Strain".
- Bucket breakdown: the same ranking over numeric follow-up bins.
- The explanation and recommendation copy is ZENO-written, one entry per built-in behaviour.
- ZENO's richer statistics (dose-response, metric relationships) stay on the Trends tab under "What moves you".

### 3.19 Weekly Plan: Home card, Plan Overview, Edit Plan, goal editors, recap [C, updated in revision 2]
**Entry:** the Home My Plan card → "VIEW MY PLAN"; the empty state → "EXPLORE PLANS →"; the Sleep Planner goal "REACH MY WEEKLY PLAN GOAL"; Trend View CTA "SET A STEPS GOAL IN WEEKLY PLAN ›".

**Evidence:**
- `completeness-critic/23` (PLAN OVERVIEW, Android, Jun 2026);
- `journal-plan-2026/30` (BEHAVIOR GOAL, Sep 2026), `31–34` (Home card);
- `whoop-site/33` (goal cards), `reviews/r11` (Edit plan), `reviews/r68, r113, r114`;
- `appstore/loc-es|de|fr-10-weekly-plan-*.png` (weekly recap);
- help-center §6 and the Weekly-Plan article (text).

**Home card:** §3.1 item 9.

**PLAN OVERVIEW** [C cards; header **[U]**]:
- Nav: "‹" · "**PLAN OVERVIEW**". Revision 1 guessed "MY PLAN"; that is withdrawn.
- **Header [U]:** help text says "At the top of the Plan Overview page, tap your current plan to edit, switch, or end". A user describes a "% Complete progress ring at the top". Neither is captured.
  - **[Z]** ZENO shows the plan name, "6 days left", the "27% ACCOMPLISHED" bar and "EDIT PLAN ✎".
- Sections are caps grey labels + hairline + "EDIT ✎" at the right: e.g. "HR ZONES 4-5 TRAINING", "SLEEP", "STRAIN", "ACTIVITIES", "BEHAVIORS".
- **Time goal card** (HR Zones 4-5, Strength Activity Time):
  - "HR Zones 4-5 Time" with a ring "0:57" (green outline) at the right;
  - "0:57:01" (orange ≈20 pt) at the left and "0:58:00" (white) at the right of a thick orange progress bar;
  - per-activity lines "0:56:23 runner RUNNING", "0:00:20 swimmer SWIMMING";
  - a footer sentence: "Get 1 min more of Zone 4-5 training during activities this week to hit your goal."
- **Count goal cards** ("Any Strain Activity 5/5", "Any Strength Training Activity 4/3"): a MON–SUN day-circle row (§2.6.37).
- **Metric goal card** (SLEEP, STRAIN; 2025 render `whoop-site/33`, still current **[U]**):
  - title "85%+ SLEEP PERFORMANCE" + "Avg. 82%", plus a check circle when met;
  - MON–SUN status circles;
  - a 7-day bar chart in the metric colour with a dashed "GOAL" line;
  - the footer rule: "Average at least 85%+ Sleep Performance to complete this goal." / "Reach 16.0+ Day Strain at least 4 days this week to complete this weekly goal."
- Behaviour goals: rows with photo backgrounds in 2025 ("Hydration 1/5", "Morning Sunlight 4/7"); their 2026 look is **[U]**. **[Z]** ZENO uses flat cards with an SF Symbol.

**EDIT PLAN / choose a plan** (`reviews/r11`, Feb 2026):
- "✕ EDIT PLAN"; heading "Edit your Weekly Plan"; body "Choose from the list of personalized plans below or create your own. Starting a plan will customize your daily recommendations for the week ahead."
- **CURRENT PLAN**: an AI-built plan card, e.g. "✧ Build Your Aerobic Base / Build endurance and support recovery with 7,700 daily steps and 1 hr of Zone 1-3 cardio each week."
- **CHOOSE A PLAN**: three tinted cards:
  - **Boost Fitness** (orange): HR Zones 4-5, Protein Intake, Strength activity;
  - **Feel Better** (green): Steps, Hydration, Recovery activities;
  - **Sleep Deeper** (blue-grey): Sleep Consistency, Sleep Performance, Avoid Late Meal.
- **CUSTOM**: "Custom Plan / Build your personalized plan by selecting weekly metric, behavior and activity goals."
- Final button: "START PLAN" (outline capsule) **[U]**.

**BEHAVIOR GOAL editor** [C `journal-plan-2026/30`]:
- "‹ BEHAVIOR GOAL" on `#101418`.
- The selected behaviour card (`#2C3438`, radius 12) holds:
  - a checkbox + "AVOID LATE MEAL" (caps);
  - "Days per week" with "**3 DAYS**" (blue caps) at the right;
  - a row of 7 square buttons "1"–"7" (≈36 pt, radius 6; selected = blue `#64ACE4` with dark text).
- **Suggested behaviour cards** (`#282C34`): caps title + ⓘ ("ALCOHOL ⓘ"), the journal question, an impact chip, and an iOS switch.
  - Chip examples: "▼ -13% Members Like You" [POP] and "▲ 7%". **[Z]** ZENO shows only the user's own impact, or none.
- "+ ADD BEHAVIORS" row (→ SELECT BEHAVIORS).
- Footnote "New behaviors will also be added to your Journal for daily tracking."
- "SAVE BEHAVIORS" (white capsule) and a "REMOVE" text button.
- Custom behaviours cannot be chosen in WHOOP yet. **[Z]** ZENO allows it.
- **Other goal editors** (Sleep, Strain, HR zones, Steps, Activities, Weight, Strength Activity Time) were **not seen in 2026 [U]**: sliders for metric goals, a days-per-week row for counts.
  - WHOOP limits users dislike: the zones 4-5 goal is capped at 30 min; steps can only be daily; Day Strain goals are counted out of 7 days. ZENO lifts these **[Z]**.

**Friday check-in** (notification; text only **[U]**) and **Monday "My Week Recap"** (localized App Store art only; English copy **[U]**):
- Centred caps title ("MY WEEK RECAP" **[U]**);
- illustration (ZENO original);
- title "Keep doing what's good for you" **[U]** + body;
- "44% COMPLETE" (value 22 pt + caps word, 70%) + a teal progress bar;
- a notched card listing goals with segmented rings and x/y. Completed goals are in teal text above a divider; remaining goals are white.
- Buttons Continue / Switch / Customize **[U]**.

**[Z] ZENO data:**
- A new local `PlanStore` (goals, week, check-offs).
- Progress per goal from:
  - `DailyMetric` (sleep performance, strain, zone minutes, steps);
  - workouts (activity counts, zone minutes per activity);
  - journal answers (behaviours).
- Overall % = equal-weight average. Friday check-in notification; Monday recap card (§3.14) → §3.40.

### 3.20 Health tab [C 2026, updated in revision 2]
**Entry:** the Health tab.

**Evidence:**
- `reviews/r07` (Jun 2026), `reviews/r44` (Aug 2026, Life), `reviews/35-androidpolice-app-photo-6.jpg`;
- `health-more-2026/02, 03` (Peak, full scroll, Jul 2026, low-res), `16` (new member, Jul 2026, full-res), `00` (May 2026), `13` (BP card bleed-through), `01` (ONE tier, Oct 2025);
- `reviews/r100`, `reviews/84-stuff-healthspan.png`, `help-center/90,92` (2025 version, for reference).

**WHOOP order (2026 best fit; hide what the tier, region or settings exclude):**
```
HEALTH title + ZENO Age orb (whole at rest; half-sphere once scrolled)
[calibrating banner ✕]
PACE OF AGING + GO TO HEALTHSPAN   | before unlock: dormant orb + "UNLOCK HEALTHSPAN · N more days"
ADVANCED LABS (results | promo "GET STARTED →" | waitlist)
HEALTH MONITOR
BLOOD PRESSURE INSIGHTS            Life + MG only
HEART SCREENER                     Life + MG only, after BP
MENSTRUAL CYCLE INSIGHTS           opt-in; directly after Health Monitor when there are no Life cards
STRESS MONITOR
CONNECT HEALTH RECORDS             US 18+; slot [U]
"Upgrade to Access" + upsell card  non-Life members
disclaimer                         (2025 pattern; 2026 [U])
```

**Layout (ZENO build):**
1. **Top:**
   - The page background is near-black, with a soft glow in the orb hue over the top ≈200 pt (green `#0B4E2F`–`#185B3C`).
   - A centred title "HEALTH" (navTitle) stays pinned.
   - At rest the ZENO Age orb is shown **whole** (≈200–240 pt, `health-more-2026/02` frames 94–95). It carries "34.5 / ZENO AGE / 7.2 years younger" (15 pt Semibold white; "x years older" in amber).
   - Scrolling moves it up behind the title, which gives the cropped half-sphere seen in `r07`, `r44`. Revision 1 described only that scrolled state.
   - Tap → Healthspan.
2. **Calibrating banner** (dismissible ✕):
   - a blue-tinted translucent card (`#67AEE6` at 20%, radius 12) with an hourglass icon;
   - text: "Your Healthspan is calibrating, so fluctuations in your ZENO Age are normal. As ZENO collects more data, it will stabilize."
3. **PACE OF AGING card** (tinted by the glow, e.g. `#322615` under amber):
   - title "PACE OF AGING" (cardTitle), with a chip at the right: "▼ slower vs. last week" (teal tint) / "• no change vs. last week" (grey) / "▲ faster vs. last week" (orange);
   - the Pace ruler (§2.5);
   - full-width nested button "GO TO HEALTHSPAN".
   - **Before unlock** [C `16`] this card and the orb are replaced by:
     - a purple page glow and a grey **dormant orb** (magenta speckles, magenta rim);
     - under it a gradient-bordered card (fill `#1C1A27`, open at the top so the orb sits in it) with "UNLOCK HEALTHSPAN" (white Bold caps ≈13 pt), "2 more days to unlock your personal Healthspan." (`#B8B8BC` ≈15 pt; Spanish original, English **[U]**) and a 4 pt magenta progress bar;
     - **[Z]** ZENO: "UNLOCK ZENO AGE · N more days to unlock your personal ZENO Age".
4. **ADVANCED LABS card** (WHOOP) → **ZENO "LAB BOOK" card** [Z], same layout:
   - title "LAB BOOK ›";
   - left column of chips + counts: "✓ Optimal 33", "• Sufficient 10", "! Out of Range 2", "Last updated: Jun 30, 2026";
   - right: a segmented radial ring of ≈60 rounded tick segments coloured teal / `#67AEE6` / orange by status, with "45 / BIOMARKERS ›" in the centre (34 pt + label).
   - Empty state (WHOOP's not-tested promo): a teal-gradient card (`#2B2F32` → `#23735A`), test-tube-in-ring art, "Add your lab results from doctor visits to see them next to your 24/7 data. ADD RESULTS →" (blue CTA).
5. **HEALTH MONITOR card:**
   - title + "›";
   - five equal columns divided by 1 pt white-10% vertical rules: **RESP · SPO₂ · RHR · HRV · TEMP**. Each column: a line icon (24 pt, 70%), a caps label (11 pt), and a 24 pt status square (✓ teal tint / "!" orange or red tint / grey dot while calibrating);
   - footer well (black 50%, radius 8): "✓ 5/5 metrics within range" or "! Heart Rate Variability low".
   - **[Z]** Hide the SPO₂ column when no real SpO₂ exists, giving "4/4 metrics within range".
6. **MENSTRUAL CYCLE INSIGHTS card** (opt-in) [C low-res `health-more-2026/03`]:
   - ≈180 pt;
   - a small caps label over "**Day 21**" (≈22 pt Semibold);
   - at the right a horizontal gradient bar (≈45% of the card width, coral → lavender) ending in a round white marker for today;
   - a full-width grey "+ LOG CYCLE" button (≈40 pt, `#41444B`).
   - (The Home card uses a dot strip instead, §3.1.)
7. **STRESS MONITOR card** [C 2025; C low-res 2026]:
   - title + "›";
   - "TODAY'S HIGH STRESS" (label) over "0:44" (34 pt) + "hrs" (15 pt, 50%);
   - a delta chip: "▼ vs. typical Tue" (teal = less than typical) / "▲ vs. typical Tuesday" (orange);
   - a value-coloured sparkline of the day at the right with a white dot at now; ≈150 pt.
8. **Blood Pressure Insights, Heart Screener, Connect Health Records, clinician consult:** not buildable (§3.25, §3.26; METRIC_COMPARISON F).
   - **[Z]** In the Heart Screener slot ZENO may show a **RHYTHM** card (Poincaré, "non-diagnostic") only if the user enabled it in Advanced.
9. **Not copied:** "Upgrade to Access" (a sentence-case header + a dismissible MG photo card) and the ONE-tier "More to unlock" block. ZENO has no tiers.
   - **[Z]** Its sentence-case header style ("More from ZENO") heads ZENO's extras:
     - **ILLNESS HEADS-UP** card (only when `IllnessSignalEngine` fires; orange tint border);
     - **STEPS** row ("Today and your trend", value) → Steps Trend View;
     - **BODY CLOCK** card (circadian phase, optional).
10. **Disclaimer** (12–15 pt, `#B4B4B8`, after a hairline): "ZENO is not a medical device. Health Monitor, Stress Monitor and Healthspan are wellness estimates and cannot diagnose or manage medical conditions…" WHOOP's 2025 wording is in `notes/gap-4` §1.2 g.

**2025 Health tab (reference only):**
- a HEART RATE live strip at the top: blue heart, "54" (40 pt) + "BPM", "Zone 0", a 5-dash zone indicator, and a live line over a grid with a dashed now-line and white dot;
- then HEALTHSPAN (pace + orb + "2.8 Years Younger vs. Actual Age" notched strip), HEALTH MONITOR, STRESS MONITOR, BLOOD PRESSURE INSIGHTS (BETA V1.0), HEART SCREENER, ADVANCED LABS, disclaimer.
- In 2026 live HR lives inside Health Monitor; users asked for it back on the tab.
- **[Z]** ZENO may put the live HR strip above the orb when the strap is streaming.

**ZENO data:**
- `HealthSnapshot` (vitals, stress);
- `vitality` / `body_age` weekly series for the orb and Pace;
- `LabBookView` data for the labs card;
- `CyclePhaseEngine`.

### 3.21 Health Monitor [C]
**Entry:** the Home tile; the Health tab card.

**Evidence:** `reviews/33-androidpolice-screens-2-may2026.jpg` (2026), `help-center/87,88,89`, `whoop-site/98,65,58`, `reviews/82-stuff`, `r95`, `r105`, `onboarding/32b` (day 1).

**Layout:**
1. **Nav:** "‹" · "HEALTH MONITOR".
2. **Day-1 calibration banner** [C `onboarding/32b`]: a violet banner "Wear WHOOP to sleep 7 more nights to calibrate." with a **7-segment progress bar**. Tiles show "--" + "● Calibrating Range".
3. **HEART RATE** (label) strip, no card:
   - blue heart glyph (`#0093E7`, 20 pt);
   - "77" (40 pt) over "BPM" (11 pt caps, 50%) and "Zone 0" (12 pt, 70%);
   - a 5-dash zone indicator (dashes 16 × 3; the current zone lit in its colour);
   - a live HR line (blue with a glow) running right over a faint grid, a dashed now-line, and a white 8 pt end dot. Chart height 90 pt.
   - Not streaming: "--" + "Calibrating…" or "Not connected" (12 pt, 70%).
4. **Two-column tile grid**, 12 pt gaps:
   - Tile: card, radius 12, h ≈118, padding 12. Icon + caps label (11 pt, 70%; may wrap to 2 lines). Value 34 pt + unit 14 pt (50%).
   - Status chip below (§2.6.13), wording seen:

| Chip | Wording example |
|---|---|
| teal ✓ | "within 13.8 - 14.8 rpm" |
| teal ✓ | "near 95% - 100%" |
| teal ✓ | "low < 14.1" (low but tolerated) |
| orange "!" | "low < 95" (out of range) |
| red "!" | very high / low **[U]** |

   - Tiles in order:

| Tile | Example | Chip |
|---|---|---|
| RESPIRATORY RATE | 15.7 rpm | |
| BLOOD OXYGEN (SPO₂) | 94 % | |
| RHR | 56 bpm | |
| HRV | 34 ms | |
| SKIN TEMP (FROM BASELINE) | -0.2 °C | "within -0.2 to +0.4" |

   - A Blood Pressure tile appears for some MG beta users (text, May 2026). Not buildable.
   - Calibrating banner (blue tint): "Your new strap is recalibrating skin temperature for greater accuracy and will update in 4 days."
5. **SHARE YOUR HEALTH REPORT** row: upload icon + caps label, card h 56. Caption below: "Printable report for sharing with your doctor, physician, trainer, or anyone of your choosing." (12 pt, 70%).
   - Opens a sheet: "30-DAY REPORT" / "180-DAY REPORT" → PDF. It needs 14 Recoveries.

**Rules (WHOOP):**
- Green = within normal range; orange = slight deviation; red = significant deviation.
- Today only; history lives in the report.
- Full calibration at 7 recoveries; the report needs 14.

**[Z] ZENO data:**
- `BodyVitalSigns.readings` + `VitalBands` (personal ±k·σ).
- Chip word: within / near (inside ±1.5σ) / low / high / "very" beyond ±3σ.
- Live HR: `LiveState.heartRate` with a 5-min buffer. Tapping the strip opens the Live Body Console (ZENO extra).
- PDF: reuse `TrendsReportRenderer`, laid out as a white two-chart report (30-day RHR and respiratory-rate charts with 6-month personal bands, matching `whoop-site/80`).

### 3.22 Stress Monitor [C]
**Entry:** the Home tile; the Health tab card; the dashboard chart card.

**Evidence:**
- `completeness-critic/14, 15` (Aug 2026 device, past day and today);
- `appstore/ios69-10-stress.png` (lossless; measured here);
- `reviews/33-androidpolice-screens-2-may2026.jpg`;
- `whoop-site/11m,11n,64,19,20a-c` (2024 flow);
- `reviews/r121`, `91-digitaltrends`.

**Layout:**
1. **Nav:** "‹" · "STRESS MONITOR" · ⚙ (notifications: evening summary, high-stress alerts).
2. **Day pager** "‹ TODAY ›" or "‹ SUN, AUG 2 ›" (centred, 13 pt Bold caps).
3. **Gauge** (§2.5), centred, top 24 pt below the pager. ⓘ at its top-right.
   - Centre: "1.5" / "MEDIUM" / "10:49 PM" (2026: the time only).
4. **24 h chart** (§2.7): 230 pt.
   - y labels 0.0 / 1.0 / 2.0 / 3.0 on the left.
   - x labels as a rolling 24 h: "11:02 PM · 7:00 AM · 3:00 PM · **10:49 PM**".
   - Glyph strip above the plot (moon, runner). Zoom button at the bottom-right inside the plot. "‹" under the left edge pages back.
   - ⓘ text: "The Today view displays data from the last 24 hours."
5. **Explanation:** plain 15 pt white text in 2026 (`completeness-critic/14, 15`); the App Store mock uses an insight card **[V]**. Copy seen:
   - "Your RHR is elevated and HRV is lower than usual, resulting in a medium level of stress. This indicates your body is moderately activated."
   - "You spent 40 min in the high stress zone on this day. This is 39 min lower than a typical Saturday."
   - Mock card: "Most of your time was spent in the low stress zone. Your longest period of high stress started at 7:42 AM and lasted for 51 minutes." + "LEARN MORE WITH COACH →".
6. **TOTAL DAY card** [C `completeness-critic/14, 15`]:
   - gauge icon + "TOTAL DAY" (cardTitle);
   - "SUN, AUG 2 STRESS **VS. TYPICAL SUNDAY**" (12 pt Bold caps; the date part white, the rest 50%);
   - two stacked horizontal bars, 8 pt apart:
     - today: h 12, segments blue / teal / orange proportional to the time in LOW / MEDIUM / HIGH, 2 pt gaps;
     - typical: h 6, the same hues at 50% (`#426885`, `#0E8962`, `#8D6423`);
   - three columns: "7:59" (17 pt Bold) / a grey chip "▼ 11%" / "■ LOW" (11 pt caps with a coloured square), then "4:09 ▼ 16% MEDIUM" and "2:09 ▲ 489% HIGH";
   - footnote: "Stress experienced throughout the day including sleep and activities."
7. **Below TOTAL DAY** (2024 UI; **[U]** for 2026): **NON-ACTIVITY** and **SLEEP** variants of the same card; "SEE TRENDS →" (→ Trend View Stress).
8. **"Sessions"** [U 2026]: guided breathing cards **Increase Relaxation** / **Increase Alertness** → session detail (breathing rate, duration, cycles) → "START EXERCISE".
   - Breathing animation: a ring expanding on inhale, coloured orange inhale / blue exhale, with "Inhale through the nose" text.
   - "FINISH SESSION" → "END & SAVE" / "DISCARD SESSION".
   - **[Z] ZENO:** this is the place for ZENO's **Breathe** (much richer: 20+ protocols, resonance pace, strap haptic pacing, coherence). Present it as cards "RELAX · COHERENCE · BOX · 4-7-8 · ALERTNESS" here, then the existing `BreathingView` restyled.

**[Z] ZENO data:**
- Score: `StressModel`. Curve: `DaytimeStress`, extended to 24 h with sleep windows.
- Time in levels: integrate the 5-min curve. Typical: same-weekday mean over the last 4–8 weeks.
- Longest high period: run-length on the curve.
- Activity bands: workouts. Sleep band: the merged night.

### 3.23 Healthspan [C]
**Entry:** the Health tab orb or Pace card; the Profile ZENO AGE card.

**Evidence:**
- `appstore/ios69-05`, `reviews/29-wareable-healthspan-aug2025.jpg` (detail, sections, trend, sticky header);
- `reviews/r119` (2026), `help-center/112` (trend), `113..115` (orb colours), `whoop-site/27,54,73`, `health-more-2026/16` (unlocking).

**Layout:**
1. **Nav:** "‹" · "HEALTHSPAN" over the subtitle "NEXT UPDATE IN 6 DAYS" (10 pt Bold caps, 50%) · ⓘ.
2. **Week pager:** "‹ JUL 19 - JUL 25 ›" (13 pt Bold caps).
3. **Orb hero**, near-black page:
   - ZENO's own particle-ring visual, ≈300 pt: an organic ring of glowing particles with a dark centre, in the hue green / teal / amber.
   - Centre: "40.7" (40 pt) / "ZENO AGE" (label, 70%) / "9.2 years younger" (15 pt Semibold in the hue; "x years older" in amber `#FFA722`).
   - Lower bound "<18" (WHOOP).
4. **"PACE OF AGING"** (label) and the ruler (§2.5).
5. **Notched insight card** (pointer up toward the needle; callout glow fill):
   - title "Steady And Healthy" / "Good Progress" / "On Your Way There" / "Small Steps, Big Impact" / "Maintain Your Gains" (17 pt Semibold);
   - body (14 pt, 70%);
   - CTA "EXPLORE YOUR WEEKLY INSIGHTS →" or "VIEW YOUR COACH ANALYSIS →" (AI gradient).
   - First run: "You're Trending Younger … DONE" (white button) **[C `reviews/20-wareable-healthspan-may2025.jpg`]**. The feature intro uses the filled "GET STARTED" circle and a green ✓ "DONE" circle (`onboarding/45`).
   - Info card "ZENO Age Is Calibrating" (blue tint, ✕).
6. **Pillar sections** **Sleep · Strain · Fitness** (sectionTitle each), with a legend at the right "▼ 6 Month avg. ▲ 30 Day avg." (11 pt, 70%).
   - Each section is a card of expandable rows (§2.7 range bar). Row header: caps label + "⌄".

| Section | Rows |
|---|---|
| Sleep | SLEEP CONSISTENCY, HOURS OF SLEEP |
| Strain | TIME IN HR ZONES 1-3 (WEEKLY), TIME IN HR ZONES 4-5 (WEEKLY), STRENGTH ACTIVITY TIME, STEPS |
| Fitness | VO₂ MAX, RHR, LEAN BODY MASS |

   - Expanded row adds a verdict title ("Outperforming") + a sentence + "VIEW TREND →" (blue `#67AEE6`).
   - **[U]** "2026 adds linked lab biomarkers per pillar with Optimal / Sufficient / Out of Range chips" is changelog text only, with no image.
7. **"Trend View"** (sectionTitle) → card "WHOOP AGE TREND ›" (ZENO AGE TREND): legend + step chart (§2.7), 200 pt.
   - Also a "PACE OF AGING TREND ›" card [C whoop-site/73]: line from −1.0x to 3.0x with a 1.0x reference line.
8. **Trend detail:**
   - date label "SUN, FEB 1" (12 pt caps, 50%);
   - "43.9" (34 pt in the hue) / "ZENO AGE";
   - "47.3" (34 pt white) / "CHRONOLOGICAL AGE";
   - M | 6M control + range pager + the chart.

**Compact sticky header** (on scroll): left "8.3" (teal 17 pt) / "YEARS YOUNGER"; centre a small orb with the value; right "0.1x" / "PACE OF AGING".

**Locked / unlocking state:**
- 2026: the dormant orb + "UNLOCK HEALTHSPAN · N more days" card on the Health tab (§3.20).
- 2025: a big lock, "21 SLEEPS TO UNLOCK", "Log 21 sleeps in the last month…", "GOT IT".
- **[Z]** ZENO: "UNLOCK ZENO AGE · 9 of 21 nights".

**[Z] ZENO data:**
- ZENO Age = `VitalityEngine` Body Age (hazard-ratio method, the same published basis WHOOP cites).
- Pace = slope of (Body Age − chronological age) over the last 6 months, plus 1.0, clamped −1…3, updated weekly.
- Per-row age impact = the VitalityEngine per-factor log-hazard converted to years.
- Lean body mass comes from Apple Health import (hide the row if absent).
- Old ZENO tiles (Body Age, Fitness Age, VO₂, Vitality) collapse into this page:
  - Fitness Age becomes a line in the VO₂ row's expanded text;
  - Vitality /100 is dropped or kept as a ZENO extra row.

### 3.24 Hormonal Insights: Menstrual Cycle Insights and Pregnancy & Postpartum [C]
**Entry:** the Health tab card; the Home card (after MY JOURNAL, §3.1); More › App Settings › Hormonal Insights.

**Evidence:**
- `appstore/ios69-09`;
- `help-center/09..14,85`;
- `whoop-site/56,11f,78`;
- `reviews/30-tomsguide`;
- `health-more-2026/07` (2026 page sections, low-res), `11` (disclaimer card, full-res).

**Menstrual Cycle Insights layout:**
1. Header gradient **tinted by the current phase** (§2.1). Nav: "✕"/"‹" · "MENSTRUAL CYCLE INSIGHTS" · ⚙.
2. Title: "Cycle Day 3 | Menstrual Phase" (21 pt Semibold; the phase name in the phase colour). Sub: "Predicted Period Day • Next period in: 25-27 Days" (14 pt, 70%).
3. Month pager "‹ APRIL ›"; weekday header MON … SUN (11 pt caps, 50%).
4. **Calendar** (5–6 rows × 7):
   - each phase run is a **continuous rounded band** behind the dates (h 32, phase band colours), with rounded ends at phase changes;
   - logged menstrual days: filled coral circles; predicted: dashed coral circles;
   - today: a white 2 pt ring; future days dimmed;
   - a white dot under a date = symptoms logged; a small dot = predicted symptoms (2026).
5. Legend: ● Menstrual ● Follicular ● Ovulatory ● Luteal ● Symptoms.
6. **Symptom predictions** (2026):
   - **POSSIBLE SYMPTOMS TODAY ›**: outline chips "Heavy Flow", "Anxiety", "Backache", "Bloating".
   - Empty state [C low-res]: a dotted-cluster illustration, "**Your symptom predictions will appear here**", a grey body (≈"Log your symptoms and periods regularly to start seeing predictions of the symptoms you might experience daily") and a full-width button.
7. **"Cycle Journal"** (section header + a right-aligned link): rows with "+" at the right, "Symptoms", "Period", "Ovulation" (labels approximate **[U]**).
   - 2025 equivalent: the **LOG PERIOD DATA** card (h 56: dotted-drop icon + a white circular "+") → Symptoms sheet.
8. **<PHASE> PHASE COACHING ›** card:
   - an M | F | O | L segmented bar (2026: columns with the current phase outlined in purple and drawn as a curve); widths proportional to phase length **[U]**;
   - an explanation paragraph;
   - three columns "SLEEP EFFICIENCY | STRAIN TOLERANCE | STRESS TOLERANCE", each with an amber "Low" / "High" chip.
9. **"Your Current Cycle"**:
   - pill chips "SKIN TEMP | RHR | HRV | RECOVERY" (selected = white);
   - legend "Smoothed Data | Expected Trend";
   - coral/violet bars by cycle day, plus an expected-trend band;
   - a "CYCLE DAYS" axis.
10. **"Your Cycle Patterns"**:
    - "CURRENT | LAST 3 MONTHS";
    - "YOUR TYPICAL CYCLE" with three values (≈"3 days / 22 days / 4 days": period, cycle, …);
    - "CYCLE HISTORY" rows ("Current Cycle 21 days", "28 days"), each with its own dot strip.
11. **"YOUR SYMPTOMS"**: empty state "Start uncovering patterns" + "+ LOG SYMPTOMS".
12. "Learn More" article cards. ZENO omits them **[Z]**.
13. **Disclaimer card** [C `health-more-2026/11`]:
    - card `#1C2023` on `#111518`, radius 12, padding ≈18;
    - "**Important Note**" (20 pt Semibold) / "Menstrual Cycle Insights should not be used for birth control or fertility tracking. The ovulatory phase indicators are estimates only.";
    - a hairline;
    - "**Medical Disclaimer**" / "Menstrual Cycle Insights is not a medical device and cannot diagnose or manage medical conditions. It does not provide medical advice. Always consult your doctor for health concerns and never delay or modify medical care based on its information."

**States** (text, forum 403):
- with no period logged, WHOOP assumes the luteal phase;
- after too long without logs it shows "**No Phase Predicted**";
- predictions stop with no logs in 6 months;
- past cycles can be hidden under "Your Cycles".

**Symptoms sheet:**
- "SYMPTOMS ✕" + the date "Wed, Oct 08";
- filter chips "Suggested | Physical Symptoms | Flow | Cervical…";
- sections "PERIOD FLOW" (No Flow / Light / Medium / Heavy / Spotting; the selected row gets a coral border) and "CERVICAL MUCUS" (Dry / Egg White (Ovulating) / Glue-like…).

**Settings** (`help-center/11`):
- "‹ HORMONAL INSIGHTS";
- toggle "HORMONAL INSIGHTS";
- "MODE ›" (MENSTRUATING / PREGNANCY);
- "CONTRACEPTION TYPE ›";
- toggle "SHOW CYCLE OVERLAY ON TRENDS";
- a privacy card.
- WHOOP's onboarding forces a last-period date (the picker reaches back only ~2 months) and has no menopause mode (forum 13794).
- **[Z]** ZENO adds "PERIMENOPAUSE / MENOPAUSE" modes and allows "I don't know" for the last period.

**Pregnancy & Postpartum Insights** (`help-center/14`; no 2026 card seen):
- "‹ PREGNANCY INSIGHTS ⚙", "‹ TODAY ›";
- "Week 5" + "35 weeks remaining / 1ST TRIMESTER";
- chips RHR | HRV;
- legend "EXPECTED TREND (band) / ROLLING TREND (line)";
- a weekly chart with a dashed current-week marker and value;
- "CURRENT TRIMESTER | ALL TRIMESTERS" segmented control;
- an insight card.

**[Z] ZENO data:**
- `CyclePhaseEngine` (logged period starts + skin-temperature phase estimate).
- Add a symptoms and flow log, predictions (mean cycle length ± SD), a phase calendar, typical-cycle and history summaries, and symptom predictions (frequency of each symptom by cycle day in the user's own logs).
- Pregnancy: weekly RHR/HRV rolling trend. The "expected trend" band needs published reference curves **[U]**; label it "approximate".

### 3.25 Heart Screener / ECG [C] — not buildable
**Evidence:** `whoop-site/53,74,75,11b`, `help-center/30..38,100`, `reviews/95`, `27`, `health-more-2026/14, 15`.
- **Card (2026):** "HEART SCREENER" with "TAKE AN ECG ›", "LAST ECG REPORT", "Normal Sinus Rhythm" (≈20 pt), a green chip "✓ Jan 14, 2024 - 7:42am", and a 3-D heart.
  - 2025 home variant: "AFib not Detected", "In the last 24 hours", "✓ BACKGROUND SCREENING | ✓ ECG REPORT".
- **Page:**
  - "Electrocardiogram (ECG) ⓘ", a purple "+ TAKE A NEW ECG READING", "Your Last ECG Report ›" with a purple trace and four check rows, history rows, "ALL ECG REPORTS ›";
  - "Irregular Heart Rhythm Notifications ⓘ" with a status card "HEART NOTIFICATIONS ACTIVATED / AFib detection runs automatically in the background and notifies you when possible atrial fibrillation is detected."
- **Recording:** a 30 s countdown with a purple progress bar and CANCEL.
- **Failure:** dialog "ECG READING FAILED" / "Something is interfering with your ECG. Try one of these tips:" + 3 numbered tips + white "LEARN MORE" + outlined "TRY AGAIN".
- **ZENO:** WHOOP 4.0 has no ECG electrodes (ECG is WHOOP MG hardware), and the result screens are regulated medical output. Do not build.
  - The **RHYTHM** card (Poincaré, explicitly non-diagnostic) is the optional ZENO extra in this slot (§3.20 item 8).

### 3.26 Blood Pressure Insights [C] — estimate not buildable
**Evidence:** `health-more-2026/10` (BETA V2.0, Apr 2026), `13`, `whoop-site/55,59,83,87`, `design-language/23`, `reviews/13,86`.
- **2026 page (BETA V2.0):**
  - "‹ BLOOD PRESSURE INSIGHTS" + a "BETA V2.0 ⓘ" chip (`#3C4044`);
  - a gauge drawn as **two end arcs** (green `#6CEBA2` left, orange `#F0A846` right) with "126/77" centred (greyed `#60686C` when there is no estimate today);
  - "SYSTOLIC 116-136 mmHg | DIASTOLIC 72-82 mmHg";
  - segmented **W | M** only + "‹ MAR 07 - APR 05, 26 ›";
  - legend "— MANUAL READING ▬ WHOOP ESTIMATE";
  - a range chart: "Highest" (orange `#DCAC70`) and "Lowest" (green `#7CD4A8`) guides, per-day range bars `#2B2F32`, estimate dashes yellow `#FCEC78`, manual readings green `#6CECA4`.
  - A manual reading needs 3 cuff readings (text).
- **2025 page (BETA V1.0):** a 3-segment ≈220–270° gauge with a needle, "TODAY'S ESTIMATE", "118/78", "W | M | 6M", "+ ADD MANUAL READING".
- **ZENO:** the estimate needs WHOOP MG plus a cuff-calibrated proprietary model. Do not build the estimate.
  - Optional **[Z]**: a "BLOOD PRESSURE LOG" (manual cuff readings, or Apple Health import) using the v2.0 range-chart style, inside Lab Book. Never show an estimate.

### 3.27 Advanced Labs [C] — service not buildable; ZENO Lab Book takes the visual slot
**Evidence:** `appstore/ios69-06`, `help-center/15,16,109,110`, `reviews/22,r82a..g,34`, `whoop-site/35,79,94`, `health-more-2026/01, 16`.

**WHOOP:**
- Purchase flow: sunburst hero, "Get A Complete Health Picture", Comprehensive Health Panel card, "SELECT TESTING FREQUENCY" white button, Specialized Panels.
- Appointment steps accordion.
- **LABS SUMMARY:**
  - a segmented ring "62/65 BIOMARKERS" and the legend Optimal 44 / Sufficient 7 / Out of Range 11;
  - a coach card;
  - a search "Search for Vitamin D, Cortisol, etc." and "FILTER & SORT ⌄";
  - "Out of Range" list cards (name ›, value + unit, chip, range bar with a ▼ marker);
  - a CSV export icon at the top-right.
- CLINICAL REPORT and ACTION PLAN cards.
- Health-tab promos: teal-gradient "GET STARTED →" (not tested) and the ONE-tier waitlist card ("✓ You're on the waitlist." + "LEARN MORE").
- MFA is required before uploading results.

**[Z] ZENO Lab Book**, restyled in this format (`LabBookView` data):
- the summary ring computed from the user's own reference ranges;
- the search;
- a status-filtered list;
- per-biomarker detail with a range bar and a history line;
- CSV export (local).
- Never present it as a lab service.

### 3.28 VO₂ Max / Cardio Fitness card [C partial]
**Evidence:** `whoop-site/29`, `appstore/promo-video-key-frames-zoomed.jpg`, `reviews/83`, `r19`, `onboarding/32c`.
- Card "YOUR CARDIO FITNESS LEVEL ⓘ" (or "VO₂ MAX"):
  - the value "44" above a white ▼ marker;
  - a segmented scale with coloured top borders: `<35` grey, `35` `#ADC2CD`, `40` `#67AEE6`, `45` `#A4A3F1`, `50+` purple;
  - the category "Above Average (40-44 mL/kg/min)";
  - the sentence "Your VO₂ Max is in the top (20-40)% for people in your age and biological sex group."
- Lives in the Trend View for VO₂ Max and as a Healthspan Fitness row.
- Before unlock: "VO₂ Max / Log 14 sleeps to unlock" + a thin progress bar (`onboarding/32c`).
- WHOOP updates it weekly on Tuesdays.
- **ZENO:** `vo2max_est` weekly (`FitnessAgeEngine`). Percentile bands from published age/sex norms (FRIEND registry); the scale cut-offs are **[U]**.

### 3.29 Strength Trainer [C, updated in revision 2]
**Entry:** Action menu → STRENGTH TRAINER; Activity Details of a strength activity.

**Evidence:**
- root: `activity-flows-2026/g01` (MY WORKOUTS, May 2026), `g02` (PROGRESS, May 2026);
- live: `g07`, `g07a–c` (Sep 2026), `g10` (Jul 2025);
- in-session: `g08`, `g09`, `g14` (supersets);
- Exercise Details: `g03` (new, Jul 2026), `g04–g06` (old);
- editor: `completeness-critic/07` (workout editor, "START WORKOUT");
- earlier: `whoop-site/36`, `reviews/28,43..45`, `help-center/08,84`.

**Root** (modal):
1. Header: "✕" · "STRENGTH TRAINER" (Bold caps) · ⓘ in a circle.
2. Underline tabs **PROGRESS · MY WORKOUTS · WHOOP WORKOUTS**. The third label is clipped at the edge; the row probably scrolls.
3. **MY WORKOUTS:**
   - a "Generate with WHOOP AI" card with a purple gradient border (top);
   - "**BUILD MANUALLY**" (full-width grey button, radius 12);
   - "MY WORKOUTS" (caps label + hairline);
   - rows: cards ≈56 pt, radius 12, each with a user-chosen emoji icon + a Bold caps name ("RUNNING WARMUP (NO EQ)", "UPPER (DUMBBELLS)") + "•••" (copy / share via QR / delete).
4. **PROGRESS:**
   - "Total Volume Load" (Title Case ≈22 pt);
   - "Ø VOLUME LOAD 5.478 kg" (big value);
   - M | 6M + date pager;
   - a monthly-segment chart (§2.7 6M grammar over a faint line of sessions);
   - "**Personal Records**": card rows with an exercise thumbnail, the name, the best value at the right ("4 reps", "30 kg", "98 kg") and "›".
5. **WHOOP WORKOUTS:** a curated library (photo cards, NOVICE / ADVANCED chips; 2025). The 2026 content is **[U]**. Not buildable (licensed content).

**Workout editor** (`completeness-critic/07`): exercise cards with set rows and a teal "START WORKOUT" capsule.

**Live session:**
1. Header: "•••" (left); the workout name in Bold caps ("UPPER A") over the elapsed time "00:38:26" (grey); "+" (right, add exercise).
2. Underline tabs "LIVE SESSION | EXERCISES".
3. **Ring** (~200 pt):
   - **REST:** a grey/white gradient ring, "REST" (white Bold caps) + "01:15" (≈44 pt), **counting up**;
   - **ACTIVE:** a ring with a blue → teal-green glow, "ACTIVE" (green caps) + "00:00" (green ≈`#00EE93`) counting up.
4. "HEART RATE" + the live value "82" + the 6-segment zone bar (§2.5).
5. **Exercise card** (radius ≈14, `#2B3034`):
   - a thumbnail + "**NEXT**" (green caps, REST only) + the exercise name ("Bicep Curl - Cable") + ⓘ (→ Exercise Details);
   - a stats row "**3/3** SET | **12** REPS | **20** KG" (the current set number green in REST).
6. **Primary button** (full-width capsule ≈50 pt): "START SET" (mint outline and text `#60E0B0`) → pressed fill `#05ED95` → "END SET" (white outline) while ACTIVE.
7. **No live strain**: strain is computed a few minutes after the session ends.
   - Users ask for a rest countdown; `g11` is a **user mockup**, not WHOOP UI.

**EXERCISES tab** (in session):
- exercise cards with a thumbnail, the name, "3 Sets" and a drag handle;
- expanded: a hint line ("Exclude your bodyweight when inputting weight."), "REPS · WEIGHT (KG)" (or "TIME (M:SS) · + WEIGHT (KG)"), numbered rows of two input boxes + a "▶" per set (the active set has a 1 pt green outline), "− +" and a trash icon;
- supersets: an outlined container "⟳ SUPERSET" with a drag handle.

**Exercise Details** (new, May 2026 rollout):
- a full-bleed hero photo under "‹ EXERCISE DETAILS ⓘ";
- the name (≈22 pt Semibold);
- chips "Progress | History | Instructions" (§2.6.35);
- "AVG VOLUME LOAD" + "5,546 lb" (≈32 pt) + an orange chip "▼ 3% vs. prior 6 months";
- M | 6M + the pager;
- the monthly-segment chart;
- "**Personal Records**" expandable cards ("**295** lbs **6** reps, gold medal, August 26, 2025 ⌄").
- Old version: a video preview, description, "EQUIPMENT", "MUSCLE GROUP", "LINKED EXERCISE", and "Exercise Trends Coming Soon".

**Strength activity details:** §3.6 variants.

**Errors:**
- "HEADS UP / We saved your workout locally because of a network error…" + TRY AGAIN / DISMISS;
- "REQUEST FAILED / Please try again later".
- Not applicable to ZENO (always local).

**[Z] ZENO Lift Log mapping:**
- Programs → MY WORKOUTS (QR share → share a JSON/text export).
- Sessions → live session: keep the strap rest-timer buzz and the Lift Live Activity. Add a **rest countdown** with a "− 1:00 +" stepper, which WHOOP users ask for.
- Tonnage, sets per muscle and e1RM (`LiftMetrics`) → PROGRESS / Personal Records / Exercise Details (Progress + History; Instructions as text only).
- New: supersets.
- No WHOOP WORKOUTS content library and no muscular-load split (see the comparison).
- "Generate with AI" only when Coach is configured.

### 3.30 Profile, Edit Profile, Levels, Achievements, Day Streak [C, updated in revision 2]
**Entry:** the Home avatar (Profile) and the flame (Day Streak).

**Evidence:**
- Profile: `profile-community-2026/21, 22, 23` (Apr 2026), `/10` (Aug 2026), `reviews/r73`, `r74`, `completeness-critic/03`;
- Levels: `/11`, `/56`, `/57`, `/43`, `/44`;
- Edit Profile: `/77`;
- Achievements: `/04` (Sep 2026), `/80`, `/81` (Oct 2026), `reviews/r40`, `r140`;
- Achievement Details: `/05–/08`, `/82`; unlock modal: `/12`, `/36`, `/65`; share card: `/58`;
- Day Streak: `reviews/r48`, `/15`, `/37`, `/38`, `/60–/64`.

**Profile** (push from the avatar):
1. Nav "‹" · "PROFILE" · a membership chip at the right ("PEAK" / "LIFE": outlined dark capsule, 11 pt caps, 60% white). **[Z]** ZENO shows the strap model ("WHOOP 4.0") or nothing.
2. **Header** (Apr 2026), on a glow that follows the avatar colour (§2.1):
   - avatar 92 pt (photo, or initials 34 pt Bold black on a colour disc);
   - name (24 pt Semibold), with "@GandW • 56 • GB" below (14 pt, 70%: username • age • country);
   - "**✎ EDIT**" at the right of the name row (radius 10, h ≈36, white ≈12% fill, 12 pt Bold caps). This is the 2026 entry to Edit Profile; in 2025 it was a nav pencil.
   - **[Z]** ZENO: name + "age • strap model".
3. **"Member since" pill** (full width, h ≈36, radius 8, `#292E32`): a circled mark, "Member since" (13 pt, 60%), "January 2020" (13 pt Semibold).
   - **[Z]** ZENO: "Tracking since <first data date>".
4. **Two half-width cards** (radius 12, `#2B3033`–`#353942`, "›" at the top-right, h ≈140):
   - **LEVEL**: medal art (ZENO original), "LEVEL 27" (13 pt Bold caps), "2344 Recoveries" (14 pt, 70%);
   - **ZENO AGE**: mini orb with "44.8", "ZENO AGE", "5.4 years younger".
5. **DAY STREAK** row card (h ≈54): label left; at the right a flame (tier colour) + "372 Days" + "›".
6. **MY MEMORY** row card (Aug 2026; absent Apr 2026): full width, h ≈54, the indigo→teal gradient (§2.1), a violet lightbulb-with-sparkle, "MY MEMORY" (13 pt Bold caps) and "›".
7. **"Achievements (34)"** (24 pt Semibold; count grey) + "VIEW ALL →" (13 pt Bold caps; Aug 2026+):
   - a horizontal carousel of ≈105 pt cells: badge art, the big count overlapping the badge bottom (40 pt Heavy condensed), and the name (15 pt Medium);
   - Oct 2026 adds a percentile line under each name ("Top 0.2%" with a pyramid icon) [POP]. ZENO omits it.
8. **"Data Highlights"** (24 pt Semibold), then one card (radius 16, `#1E2326`):
   - segmented control "1M | 3M | ALL TIME";
   - three highlight rings (§2.5): Best Sleep 100% / Peak Recovery 97% / Max Strain 20.7;
   - **STREAKS** (label + hairline): three columns, each a 40 pt scalloped badge glyph (sleep / recovery / strain hues) over "44 Days" (17 pt Semibold) and "70%+ Sleep" / "Green Recovery" / "10+ Strain" (12 pt, 70%);
   - **NOTABLE STATS** (label + hairline): rows with a 32 pt gold scalloped icon, the name (15 pt Medium) and the value right-aligned (17 pt Bold condensed + unit 12 pt, 50%): Lowest RHR 39 bpm · Highest RHR 50 bpm · Lowest HRV 91 ms · Highest HRV 149 ms · Max Heart Rate 189 bpm · Longest Sleep 8:15 hr · Lowest Recovery 17 %.
9. **"Activity Summary"** [C `/23`, `completeness-critic/03`]:
   - "1M | 3M | ALL TIME";
   - "1010x" (34 pt Bold) over "TOTAL ACTIVITIES";
   - a header row "ACTIVITY | AVG. STRAIN … TOTAL";
   - per-sport rows: icon + "RUNNING" + "11.9" + at the right "698x" in strain blue, with a full-width blue bar (h 6, radius 3) on a hatched track;
   - "⌄ SHOW ALL" / "SHOW LESS" (full width, `#2A2F33`, radius 8).
10. "Referrals" (title only, contents **[U]**). ZENO omits it.

**Edit Profile** [C top half `/77`; rest text]:
- "‹ EDIT PROFILE".
- A vertical form of full-width dark boxes (h ≈48, radius 10, near-black fill, 1 pt dark-grey stroke), each with an 11 pt Bold caps grey label above: birthday, COUNTRY, STATE, CITY.
- Further fields from text: Email, Name, Gender / Physiological Baseline, Units (Imperial / Metric), Weight, Height.
- Pickers open the wheel-picker sheet (§2.6.36), e.g. "Set Your Birthday" with CANCEL / CONFIRM (disabled when the age is under 18).
- "Save" appears only after an edit. The username is not editable. Error: "Error: there was problem updating your profile".
- **[Z]** ZENO: name, birthday, sex/physiological baseline, height, weight, units, max HR override. No email, country is optional.

**Levels page** [C `/11`, `/56`, `/57`]:
1. Nav: a **circular outlined back button** (34 pt, 1.5 pt white), "LEVELS" (15 pt Bold, tracking ≈2), and a "?" in a 22 pt grey circle right of the title (its sheet is **[U]**).
2. **Hero** (`#1C2125`, straight bottom edge at ≈345 pt):
   - medal ≈230 pt (ZENO original art);
   - tier name ("DIAMOND", 15 pt Bold caps grey `#55585D`);
   - "LEVEL 29" (24 pt Bold caps white);
   - the progress row (§2.5) between the current and next level plaques;
   - the caption "1 more Recovery to Level 30" (at max: "Congrats! You've reached the highest level!").
3. **Level grid** (`#13171A`): 3 columns, one cell per level 1→30. Each cell holds:
   - a strap-shaped plaque (≈34 × 48 pt) with the level number, in the material colour;
   - the material name (11 pt Bold caps grey);
   - "LEVEL 1" (15 pt Bold caps white);
   - the threshold line (13 pt, 70%): "Membership starts", "4 Recoveries", …;
   - tier-start cells (L6, and probably L11/16/21/26 **[U]**) get a thin ring and a star.
4. **The 30-level ladder** (resolved; every in-app data point checks: L22 at 1226, L24 at 1724, L25 at 1907, L27 at 2344, "1 more" at 2999). Minimum recoveries per level:

| Tier | Levels: minimum recoveries |
|---|---|
| Beginner | L1 0 ("Membership starts") · L2 4 · L3 7 · L4 14 · L5 21 |
| Bronze | L6 30 · L7 40 · L8 50 · L9 65 · L10 80 |
| Silver | L11 100 · L12 125 · L13 150 · L14 200 · L15 250 |
| Gold | L16 300 · L17 400 · L18 500 · L19 650 · L20 800 |
| Platinum | L21 1000 · L22 1200 · L23 1400 · L24 1600 · L25 1800 |
| Diamond | L26 2000 · L27 2250 · L28 2500 · L29 2750 · **L30 3000 (max)** |

   - Material names: L1 Carbon, L2 Iron, L3 Steel, L4 Gunmetal, L5 Titanium, L6 Bronze. Levels 7–30 by tier name are **[U]**.
   - Medal stars equal the tier index: Bronze 1, Gold 3, Platinum 4, Diamond 5.
   - The count is **scored recoveries**, not wear days.

**Achievements page** [C]:
1. "‹ ACHIEVEMENTS".
2. A large title "All Achievements (33)" (24 pt Semibold; count grey `#8A9095`) that scrolls under the nav.
3. Filter chips (§2.6.35): **All · Sleep · Recovery · Strain · Healthspan · Act…** (the 6th chip is cut off; "Activities" **[U]**).
4. Sections SLEEP · RECOVERY · STRAIN · HEALTHSPAN · (ACTIVITIES **[U]**), each an 11 pt Bold caps grey label + hairline over a 3-column grid. Each cell:
   - badge art ~72–84 pt with the count (40–44 pt Heavy condensed) overlapping its lower third;
   - the name (15 pt Medium, 2 lines);
   - the unlock date ("Jul 18, 2026", 13 pt, 50%), or a percentile line [POP] in one Oct 2026 variant;
   - row gap ≈36 pt.
5. Locked: a black badge silhouette with a grey padlock and "0".
6. Page gradient `#252C34` → `#13181C` → `#0E1213`.

**Badge families** (shape = family; ZENO draws its own art):

| Family | Shape | Colour |
|---|---|---|
| Sleep | hexagon | steel blue / lavender |
| Recovery | shield | green; **red** for "1% Club" |
| Strain | diamond | strain blue (metals when starred) |
| Healthspan | organic blob | teal |
| Activities | scalloped rosette with a white sport pictogram | purple → sky |

**Badges seen** (names are WHOOP's and are **not** reused verbatim **[Z]**):

| Badge | Criterion | Note |
|---|---|---|
| Sleep Specialist | "Total nights of 85%+ Sleep Performance" | |
| Human Metronome | "7-day streak of 90%+ Sleep Consistency and 70%+ Avg Sleep Performance" | |
| Pillow Perfect | **[U]** | |
| Green Monster | "Total green Recoveries" | |
| 1% Club | "Logged 1% Recovery" | |
| 99% Club | 99% Recovery | |
| Green Week | **[U]** | |
| Peak Day | **[U]** | |
| Strain Seeker | **[U]** | |
| All Out Day | **[U]** | |
| Time Traveler | "Your WHOOP Age is now N years younger than your chronological age." | |
| Healthspan Comeback | **[U]** | |
| VO₂ Phenom | **[U]** | |
| Runner's High, Gear Grinder, Ring Ruler, WOD Star, Walk Star, Stride Scholar, Crack Commander, Grit Grinder | "Total ⟨Sport⟩ activities logged" | one rosette per sport |
| Stars & Strides | All-In 250 challenge | sits in STRAIN |

**Star tiers** (new UI, Aug–Oct 2026):
- Only **cumulative-count badges** get stars: **0–6 stars** arced over the frame, in metals 1 family colour · 2 bronze · 3 silver · 4 gold · 5 platinum · 6 lavender.
- Thresholds consistent with every sample: 1★ ≥50, 2★ ≥100, 3★ ≥250, 4★ ≥500, 5★ ≥750, 6★ ≥1000 **[U]**.
- Event and streak badges never get stars.

**Achievement Details** [C `/05–/08`, `/82`]:
1. "‹ ACHIEVEMENT DETAILS" + a share icon at the right (Aug 2026+).
2. A radial glow tinted by the family (§2.1) over near-black.
3. The badge hero (~260 pt) with the big count (88 pt Heavy condensed). The count is the last milestone reached.
4. Name (22 pt Semibold) + criterion (15 pt, 70%).
5. Percentile block [POP]: a pyramid icon + "Top 0.1%" + wordmark. **[Z]** ZENO replaces it with "Unlocked <date>" and "Best: <value>".
6. **Milestone card** (radius 16, `#1E2326`):
   - a mini badge with the current count;
   - "27 more" (14 pt Semibold), a 6 pt progress bar (`#67AEE6` on `#34393B`), "until your next milestone." (13 pt, 70%);
   - a greyed next-milestone badge with its target.
   - The bar spans last milestone → next milestone; above 100 the steps are 50.
7. "⇪ SHARE ACHIEVEMENT" (full width, h 54, `#292E30`, radius 12).

**Unlock modal** [C `/12`, `/65`]:
- A black scrim (≈85%) over Home.
- Badge art top-left (~150 pt) with the metric in huge type ("-4 Yrs").
- The name (26 pt Semibold); the body (15 pt, 70%) + a bold percentile sentence [POP; ZENO omits it].
- A "Your Next Milestone" card (black, 1 pt grey border, radius 12, teal title, thin bar).
- Buttons "CLOSE" (outlined, h 56, radius 14) and "VIEW" (white).
- Day-streak variant: "New Day Streak Unlocked" with a gold bar "2000/2050 · 50 more until your next milestone".

**Share card** (`/58`): a portrait image (black, family glow) with the count, name, criterion and wordmark. ZENO renders it locally.

**Achievement chip** on the deep dives: §1.5.

**Day Streak page** [C]:
- "‹ DAY STREAK ⓘ" (Aug 2026: plus or instead a share icon).
- A large flame illustration in the tier colour (§1.4; ZENO original), then the count "1607" (72–80 pt Heavy).
- "Day Streak" (22 pt Semibold) + "Wear your strap daily" (15 pt, 70%).
- Three stat columns divided by vertical rules: "Feb. 5, 2022 / Streak started" · "Top 2% / WHOOP" [POP] · "1607 / Max streak".
  - **[Z]** ZENO replaces the middle column with "Best / 1607".
- **THIS WEEK** card: MON–SUN with small flames for worn days, ✕ for missed and dashed circles for future days.
- Milestone card: "393 more days to unlock your next milestone" with an orange progress bar between two milestone badges.
  - Ladder: 1 → 7 … 100 → 180 → 365 → 730 → 1000 → 2000 → 4000; from Aug 2026 the steps above 1000 are 50 days.
- **Tier message card** (title 15 pt Semibold + body 14 pt, 70%):
  - "Spark's lit" (yellow);
  - "Stay in the game for long-term gains" (orange);
  - "Every day counts" (red);
  - magenta copy **[U]**;
  - "Legendary consistency" (blue);
  - "Legacy-level dedication" (gold).
  - **[Z]** ZENO writes its own copy.

**[Z] ZENO data:**
- `StreakCalculator` (days with data);
- the 30-level ladder over the scored-recovery count;
- highlights and notable stats from `DailyMetric` min/max per window;
- activity summary from workouts;
- achievements as local rules with ZENO names (e.g. "Consistent Sleeper", "Green Streak") and the star ladder;
- milestone progress and the unlock modal from the same rules.

### 3.31 More tab [C 2026 order; promos not copied]
**Evidence:** `health-more-2026/06, 06b` (Jul 2026, carousel to LOGOUT), `08, 08c` (Sep 2026), `reviews/r05` (new user, Jul 2026), `help-center/94` (2025 list, geometry).

**WHOOP 2026, top to bottom:**
1. A hero promo carousel (photo card, caps title, sub, ›, 4–5 page dots).
2. For new members, a black "FIRST WEEK WITH WHOOP" card with a gradient border and a graduation-cap icon: "Wear your WHOOP to bed nightly and check back in here to track your sleeps and discover new insights."
3. REFER & EARN: an iridescent "GET ONE MONTH FREE" card + an outlined "SHARE A FREE TRIAL" card.
4. **SHOP & GIFT**: list rows (WHOOP SHOP "Shop bands, smart apparel, and batteries"; GIFT A MEMBERSHIP) or horizontal product cards for some users **[V]**.
5. **ACCOUNT & SETTINGS**: MY ACCOUNT · DEVICE SETTINGS · APP SETTINGS · PRIVACY SETTINGS. "DIGITAL WHOOP LABS" is gone in 2026.
6. **SUPPORT**: MEMBERSHIP SERVICES ("Get help or ask a question") · TUTORIALS · a 5-letter row **[U]** · FIRST WEEK WITH WHOOP (a plain row for established members).
7. An outlined "LOGOUT" capsule (≈200 × 40) and "APP VERSION 5.xx.x (BUILD xxxxx)" in small grey caps.
- Rows: §2.6.22. The 2026 root shows no visible nav title.
- **Getting Started** (text, help 8/13/2026) is a checklist of 6 mini-tutorials, opened from More: Track an activity · Join a team in the community · Analyze your Sleep Performance · View your activity details · Set up your personalized alarm · Set up your daily journal. The page visual is **[U]**.

**[Z] ZENO More** (WHOOP's order, ZENO content, no promos):
1. "FIRST WEEK WITH ZENO" card (first 7 days only; Get Started border). It opens a checklist page whose rows have a check state:
   - Track an activity;
   - Analyze your Sleep Performance;
   - View your activity details;
   - Set up your strap alarm;
   - Set up your daily journal;
   - Import your history (instead of "Join a team").
2. **TOOLS** (in WHOOP's SHOP & GIFT slot): WORKOUTS LOG · LIFT LOG (Strength Trainer) · INTERVAL TIMER · LIVE HEART RATE ("Live Body Console") · BREATHE · GUIDED SESSION (BETA).
3. **ACCOUNT & SETTINGS:**
   - PROFILE;
   - DEVICE SETTINGS ("Battery, sync, pairing");
   - APP SETTINGS (§3.33);
   - PRIVACY & DATA ("Everything stays on this iPhone"; backup and restore, delete all data).
4. **SUPPORT:**
   - HOW ZENO WORKS (the Tutorials slot; scoring guide);
   - WHAT'S NEW;
   - REPORT A PROBLEM;
   - FIRST WEEK WITH ZENO (row, after day 7).
5. **ADVANCED:** Test Centre, Limitations, Mi Band, Rhythm, Intelligence, Your Data Fused, Power Saving, Siri & Shortcuts, Classic Health.
6. **INTERFACE:** the "Classic interface" toggle + confirmation dialog (keep ZENO's copy).
7. In place of LOGOUT: "ZENO 11.8.0 (428)" in small grey caps.

### 3.32 Device Settings (+ pairing) [C]
**Entry:** the Home battery/strap icon; More › DEVICE SETTINGS.

**Evidence:** `reviews/r01-2026-10-02-not-syncing.jpg`, `help-center/95,96,97,107,108`, `onboarding/43a, 43b, 41`, `completeness-critic/18`.

**Layout:**
- Modal: "✕" · "DEVICE SETTINGS" · ⓘ.
- **Header block:**
  - left: "CONNECTED TO" (11 pt Bold caps, teal) over the device name "MY WHOOP MG ✎" (17 pt Bold caps tracked; ✎ renames, up to 15 characters);
  - right: "LAST SYNC" (11 pt caps, 70%) over "10:37 AM" (13 pt Bold), plus a cloud-✓ icon. While catching up: "CATCHING UP" over "Oct 1, 7:17 PM" with a cloud-up arrow.
  - Disconnected: "WHOOP DISCONNECTED / Tap 'Pair a Device' below to continue." (`onboarding/43a`).
- **Tabs** "STATUS | ADVANCED" (13 pt Bold caps; the selected tab is white with a 2 pt underline, the other 50%).
- **STATUS:**
  - a large strap render (ZENO: a neutral SF-style illustration or a photo-less silhouette **[Z]**) cropped off the left edge;
  - battery "58 %" (40 pt + 17 pt "%") over the model "WHOOP MG" (12 pt caps, 50%), with a vertical battery level bar (6 × 150 pt, teal fill) at its right;
  - pinned bottom card: heart icon in a dark circle + "BROADCAST HEART RATE" (13 pt Bold caps) over "TO COMPATIBLE APPS & DEVICES" (11 pt caps, 50%), with a toggle.
- **ADVANCED:** rows (card h 60, icon + caps label), each with grey helper text (13 pt, 70%) below the card:
  - PAIR A DEVICE ("Pair a WHOOP to the WHOOP app. This will replace any existing WHOOP pairings.");
  - UNPAIR DEVICE (confirmation "ARE YOU SURE?", `onboarding/43b`);
  - FIRMWARE CHECK ("Check and install the latest WHOOP firmware.");
  - REBOOT DEVICE ("Reboot your WHOOP to restart the device.");
  - ERASE DEVICE DATA ("Erase all heart rate data currently stored on your WHOOP…").
  - FIRMWARE CHECK with nothing to install shows a dialog "NO NEW UPDATES / You have no new firmware updates at the moment." + white "OKAY" (`onboarding/41`).
- **Pairing:** the same screens as onboarding (§3.38):
  - SEARCHING FOR STRAP...;
  - SELECT YOUR DEVICE;
  - CONNECTING;
  - CONNECTED / CONNECTION FAILED;
  - re-pair starts at "Wake up your WHOOP / Slide on the charger to wake up your WHOOP and begin pairing with the app" with the tab bar visible.

**[Z] ZENO data:**
- `DevicesView` + `LiveState`: battery, charging, model, firmware string, last sync, rename (supported), reboot (supported).
- **Broadcast HR:**
  - the toggle drives ZENO's **phone-side re-broadcaster** (`HrBroadcaster`: the app advertises the standard BLE Heart Rate Service 0x180D);
  - the experimental **strap-side** command (`PuffinExperiment`) sits under it as "Broadcast from the strap (experimental)".
  - WHOOP's help article (10 Jun 2025) says WHOOP sensors broadcast through the standard BLE Heart Rate Profile. The 4.0 strap-side effect can therefore be verified on the device with any BLE HR app (e.g. nRF Connect or a gym console).
- FIRMWARE CHECK → the "NO NEW UPDATES"-style dialog showing the current firmware version (no updates).
- ERASE → omit (ZENO deliberately excludes destructive commands).
- Keep ZENO's multi-device list (Oura beta, Mi Band) as a "MY DEVICES" section under ADVANCED.

### 3.33 App Settings subtree [C structure; most pages text-only]
**Evidence:** `health-more-2026/08, 08b` (Sep 2026: ✕ APP SETTINGS with 9 rows, INTEGRATIONS, APPLE HEALTH; low-res), `24` (INTEGRATION DETAILS, full-res), `25` (EXPORT), `profile-community-2026/55` (AI SETTINGS), `help-center` §16.4, `help-center/98,99,11`.

**App Settings root:**
- "✕" at the top-left and "APP SETTINGS" centred. It is presented over the visible floating tab bar.
- **9 single-line row cards** (≈48–52 pt, leading outline icon + caps label, no sections). The labels are illegible; this mapping is from label lengths and help text **[U]**:
  1. ACTIVITY SETTINGS
  2. AI SETTINGS
  3. DATA EXPORT
  4. (a 5-letter row)
  5. INTEGRATIONS (the tutorial taps it)
  6. JOURNAL
  7. NOTIFICATIONS
  8. HORMONAL INSIGHTS
  9. HIDE METRICS

**Pages:**
- **Activity Settings:**
  - Activity Detection (auto toggle);
  - **Heart Rate Settings**:
    - "‹ HEART RATE SETTINGS";
    - "Heart Rate Zones" (20 pt Semibold) + "Calculated using the scientifically validated heart rate reserve formula…";
    - "RESTING HR ⓘ 59 bpm" (read-only) and "MAX HR ⓘ 191 bpm" (editable);
    - a toggle "Manual Heart Rate Zones";
    - a table "ZONE | ZONE MIN | ZONE MAX" (Zone 5 → 1, a zone-colour edge, bpm input boxes);
    - outline "SAVE HR ZONES" (disabled until changed) + "CANCEL".
  - Activity Details links here with "View HR Settings".
  - **ZENO:** max-HR override exists (Karvonen zones). Manual per-zone bounds are new.
- **AI Settings** (`/55`):
  - "✕ AI SETTINGS";
  - a row "MEMORY" + toggle with the helper text;
  - a "Data privacy" card.
  - WHOOP removed its Coach on/off switch in 2026. **[Z]** ZENO keeps COACH on/off and adds PROVIDER and MODEL rows here.
- **Coaching Preferences:** "Coaching Mode": "Customized with your data" vs "Education support" (text). **[Z]** ZENO puts it inside AI Settings.
- **Data Export** (`25`):
  - "✕ EXPORT WHOOP DATA" (≈17 pt Semibold caps) on a lighter grey-blue gradient;
  - body "Export a complete archive of your Sleep, Recovery, Strain, and Journal data by submitting a request below. This is your data, and we take your privacy seriously." + "LEARN MORE →";
  - below the crop (text): confirm the email, then "Create Export". The link arrives within 24 h, once per day.
  - **ZENO** exports locally: CSV, .noopbak backup, Backup & Sync folder, Shortcuts, PDF report. Keep the copy pattern ("Export a complete archive of your Sleep, Recovery, Strain and Journal data. Files stay on this iPhone until you share them.").
- **Integrations:**
  - "‹ INTEGRATIONS";
  - a featured APPLE HEALTH card (dark photo, glyph, "›");
  - a short caps section (probably "CONNECTED") with rows that carry a status mark;
  - a longer section (probably "RECOMMENDED FOR YOU") with partner rows.
  - Partners (text): Strava, Peloton, Withings, Clue, Natural Cycles (5.0/MG only), Cronometer, TrainingPeaks, Hyperice, HealthEx (US). Garmin direct import was removed.
  - **ZENO rows:** APPLE HEALTH, WHOOP CSV IMPORT, MI FITNESS, NUTRITION CSV, OURA (BETA), SHORTCUTS, HEART RATE BROADCAST.
- **Integration Details** [C `24`, Peloton, Sep 2026]:
  - a hero photo fading to `#101518`, with "‹ INTEGRATION DETAILS", the partner glyph, the name (28 pt Semibold), a description (15 pt `#B4B8BC`) and "LEARN MORE →";
  - a hairline, then **per-direction blocks**: "Pull Peloton data into WHOOP" (16 pt Semibold) / "Connected" (15 pt Semibold `#00F0A0`), a 24 pt checkbox square (`#0D372D` + green check) at the right, and a full-width "DISCONNECT" button (`#282C2F`, h 40, radius 8). The second block reads "Share WHOOP data with Peloton".
  - Strava adds the share scope (all activities / chosen types); HealthEx adds REFRESH and "Health Record Analysis".
  - **[Z]** ZENO uses this template for each source: the description; the "Import from <source>" block with "Connected" / last import date and a "RE-IMPORT" or "DISCONNECT" button; the "Share to Apple Health" block where it applies.
- **Apple Health page** (low-res):
  - "‹ APPLE HEALTH";
  - a connection graphic (Health icon → connector → app tile);
  - 5 small data-type tiles;
  - "CONNECT TO APPLE HEALTH", two paragraphs, "LEARN MORE →";
  - a full-width **green pill** "Connect" pinned at the bottom (≈`#00F0A0`). Once permissions have been granted it becomes "Manage Permissions".
  - Imports: workouts, routes, active energy, distance, mindful minutes, weight and height, HR during activities. Exports: workouts, active energy, activity HR, sleep, RHR, respiratory rate, SpO₂, steps.
- **Journal:** on/off and reminder time.
- **Notifications:**
  - per-type rows with frequency and time (e.g. the evening stress summary);
  - Heart (IHRN) notifications live on the Health tab instead;
  - users ask for a "morning recovery" toggle, which WHOOP lacks.
  - **[Z]** ZENO adds it and folds Automations in here.
- **Hormonal Insights:** §3.24 settings.
- **Hide Metrics** (text): toggles Hide **Recovery & Sleep** · Hide **Weight & Lean Body Mass** · Hide **Healthspan**. Users ask for Stress and BP.
  - **[Z]** ZENO adds Hide Stress.
- **[Z] UNITS** (the probable 5-letter row): metric/imperial, °C/°F, 12/24 h.
- **Privacy Settings** (text): Team Invitations, Personalized Product Recommendations, Privacy & Data Management.
  - **ZENO** → PRIVACY & DATA in More (§3.31).

### 3.34 Community [C root and team page] — not buildable offline
**Evidence:** `profile-community-2026/75` (root, Jul 2026, iOS full-res), `/01`, `/02` (2025), `/18` (Apr 2026 storyboard), `/69` (rank sheet), `/86` (INFO tab), `/54`, `/68`, `/70` (team pages), `completeness-critic/01` (CHAT), `help-center/103,104`.

**WHOOP root:**
1. A promo banner card (h ≈63, radius 12, 1.3 pt light outline): hand/paper-plane icon + "SHARE A FREE TRIAL" / "Invite your community to experience WHOOP". Apr 2026: "INVITE A FRIEND".
2. "**Teams**" (28 pt Semibold) + "○○○" at the right. The ••• opens an iOS action sheet: Create Team · Enter Invite Code · Explore Teams · Cancel.
3. "MY TEAMS" (11 pt Bold caps grey) + at the right "MONTHLY STRAIN RANK ⌄" / "DAILY STRAIN RANK ⌄" (12 pt Bold caps).
   - The selector opens a sheet: "DISPLAY RANK AS" [DAY STRAIN | RECOVERY | SLEEP]; "OVER THE COURSE OF" (TODAY / THIS WEEK / THIS MONTH); "APPLY".
4. Team rows (h ≈56, radius 8, `#34393D`, 10 pt gaps):
   - a 40 pt gradient-circle logo with a white glyph;
   - the team name (14 pt Bold caps tracked);
   - at the right the rank "630th" (17 pt Bold) over "of 93.3K" (12 pt, 50%).
   - Members are auto-enrolled in demographic and country teams ("MEN 40-50", "UNITED KINGDOM").
5. "RECOMMENDED TEAMS" + "VIEW ALL →": photo tiles (≈160 × 180, radius 8, 64 pt logo, 20 pt Bold caps name, "56154 MEMBERS").
6. A Pending Invites section with a red dot on the tab icon (text).

**Team page:**
- A blurred banner behind circular back and "•••" buttons.
- Tabs "INFO | CHAT | STRAIN | RECOVERY | SLEEP"; large public teams have no CHAT.
- **INFO:** a 72 pt logo + the name (22 pt Bold caps), "ABOUT" + description. Data sharing and members below are **[U]**.
- **Leaderboards:**
  - "DAILY | MON - SUN | MONTHLY" + a filter button;
  - a metric header "RECOVERY / 65% avg" and "TODAY / Last Updated: 10:02";
  - rows with a 56 pt avatar ringed in the metric colour, "1. Name", the value in the metric colour and a sub-line ("HRV: 46, RHR: 60");
  - the user's own row pinned at the bottom.
- **CHAT:** avatar, name + @handle, time, text, read receipts, image and stat shares, the "SAY SOMETHING" composer, and the WHOOP bot's weekly champions post.
- Invite codes look like "COMM-A73B53".

**Follow friends:** leaked in May 2026 ("SEARCH MEMBERS", ADD buttons; Friends above Teams) and on the Nov 2026 roadmap. **Not shipped** as of 2026-10-02.

**ZENO:** needs a server and other members, so it cannot work offline. The tab slot becomes Trends (§3.35).
- Optional far-future idea **[Z]**: export a "team card" image to share manually.

### 3.35 Trends tab (ZENO replacement for Community) [Z]
**Layout:** the "TRENDS" title (navTitle), then:
1. A "THIS WEEK" summary card: averages for Recovery / Sleep / Strain vs last week, using the three mini rings + delta chips. Tap → Weekly Digest (§3.40).
2. Sections **SLEEP · RECOVERY · STRAIN · STRESS · BODY** (label + hairline). Each holds dashboard-style metric rows (value, ▲▼, 30-day baseline, a tiny 7-day sparkline) → Trend View.
3. **INSIGHTS** (ZENO extras), list rows:
   - WHAT MOVES YOU (ranked effects, dose-response);
   - EXPLORE (all metrics + full-day HR);
   - COMPARE (overlay 2–4 metrics);
   - WEEKLY DIGEST;
   - REPORT (PDF);
   - TRAINING LOAD (CTL / ATL / TSB);
   - TOMORROW'S RECOVERY (forecast).

All of these restyle existing ZENO screens (`InsightsHubView`, `MetricExplorerView`, `CompareView`, `WeeklyDigestView`, `TrendsReportView`, `TrainingLoadCard`, `IntelligenceView`).

### 3.36 Widgets, Live Activities, Apple Watch [C]
**Evidence:** `reviews/r26` (iOS medium widget, May 2025), `help-center/18..21`, `reviews/r24` (Android), `r29`, `14`, `r04`, `completeness-critic/27`, `activity-flows-2026/b09`.
- **Home Screen medium widget** [C `reviews/r26`]:
  - a dark card;
  - battery "86%" + battery glyph at the top-right;
  - **concentric rings** in the centre (outer Strain blue, inner Recovery in its zone colour) around the brand mark;
  - left: "56%" + "RECOVERY" (zone colour), with "HRV" over "40" (grey) below;
  - right: "13.3" + "STRAIN" (blue), with "CALORIES" over "1,969" (grey) below.
- **Small "Daily Overview"**: the concentric rings, "87%" (zone colour) at the bottom-left and "15.6" (blue) at the bottom-right, battery at the top-right.
- **[V]** The large three-column RECOVERY / STRAIN / SLEEP variant is seen on Android only (`help-center/21`, `reviews/r24`).
- **Lock Screen:** a circular battery ring with a strap glyph [C `help-center/19`]. Single-metric Sleep / Recovery / Strain gauges are **[U]** (text only).
- **Live Activity:** §3.8 (zone bar, blue stopwatch pill, ♥ bpm; GPS distance and speed). Dynamic Island: ♥ bpm + elapsed time.
- **Apple Watch Smart Stack:** §3.8 (`b09`).
- **ZENO:**
  - Live Activities exist (live HR, sync, lift).
  - Widgets exist in code but need an App Group, which free signing lacks; they render placeholders. This is a signing limitation, not a design one.
  - Build the medium widget layout above when signing allows.
  - The Smart Stack layout needs the Live Activity's small (watch) family.

### 3.37 Errors, dialogs, toasts, empty copy [C]
**Evidence:** `activity-flows-2026/c06, c08, c09, g22, g23`, `journal-plan-2026/09, 10`, `onboarding/24a, 24b, 13f, 40, 41`, `completeness-critic/12, 18`, `health-more-2026/14, 23`, `reviews/r16`.

| Pattern | WHOOP example | ZENO use |
|---|---|---|
| Full-screen error (§2.6.31) | "ERROR" + RETRY / CLOSE; "SOMETHING WENT WRONG" (grey "!" ring, teal-outline RETRY); "YOUR ENTRY WAS NOT SAVED" | local store or BLE failures |
| Dialog card (§2.6.30) | "OVERLAPPING ACTIVITIES … GOT IT"; "REQUEST FAILED … CLOSE"; "ECG READING FAILED … LEARN MORE / TRY AGAIN"; "NO NEW UPDATES … OKAY"; "UPDATE REQUIRED … UPDATE APP" | overlap check, firmware info, end-activity and discard confirmations |
| Network pages | "A NETWORK CONNECTION IS REQUIRED"; "LOOKS LIKE THE SERVER IS TAKING A QUICK NAP … RELOAD"; "HEADS UP / We saved your workout locally…" | not applicable (no network) |
| Inline feed error | dashed box "Couldn't load new notifications. We'll try again later." | not applicable |
| Toast | bottom capsule (white 14%, radius 22), 14 pt white text, e.g. "Failed to load. Please try again." | store or BLE errors |
| Empty states | one 14 pt 70% sentence plus at most one action button ("No activities yet" + "+ ADD ACTIVITY"); placeholders "--%", "-:--", "---" | same |

### 3.38 Onboarding / first run [C, NEW in revision 2]
**Purpose.** WHOOP's first run, as recorded on a brand-new iOS account (May 2025) and confirmed by 2026 full-resolution screenshots.

**Evidence:**
- `onboarding/` (gap-3): `02a–c` (landing), `03a–c` (log in / e-mail), `05–08` (device tutorial), `09b`, `10f`, `11a–d`, `12d`, `13a–f` (pairing), `15b` (Welcome), `16`–`19` (profile), `20b–d` (card), `22b–d` (Privacy), `24a–b` (ERROR), `26`–`29` (finish), `30`–`33` (first Home, calibration, tours);
- `completeness-critic/04, 12, 17, 18`.

**WHOOP sequence** (the device is paired **before** the account is created; payment comes **before** the terms):

| # | Screen | Notes |
|---|---|---|
| 1 | Landing | Full-bleed lifestyle photo, wordmark, white pill "I HAVE A WHOOP DEVICE", a second option (≈27 characters, probably "I DON'T HAVE A WHOOP DEVICE" **[U]**), a tiny legal link |
| 2 | "Let's Get Started" (2025) / "Enter Your Email" (2026) | log in or "CREATE ACCOUNT" |
| 3 | "Unbox Your Device" | filled-circle CTA |
| 4 | "Put On Your WHOOP" | |
| 5 | "Wake Up Your WHOOP" | charger animation |
| 6 | "Check for Pairing Mode" | pulsing ring on the side LED; filled "START PAIRING" |
| 7 | "SEARCHING FOR STRAP..." | centred caps title, serial highlighted in blue on the strap render, "HELP" pill, outlined "DON'T SEE YOUR DEVICE?" |
| 8 | "CHOOSE A DEVICE" (2025) / "SELECT YOUR DEVICE" (2026) | rows "WHOOP 5B00334077" or the custom name + "›"; "UPGRADED YOUR WHOOP?" / "NEED HELP?" |
| 9 | iOS "Bluetooth Pairing Request" over "CONNECTING" | phone and strap joined by a dotted blue line |
| 10 | "‹NAME› CONNECTED" / "Your WHOOP is ready to go." | green line with a glowing ✓; "CONTINUE" (outlined, or white in Aug 2026) |
| 10x | "CONNECTION FAILED" | red ✕ ring, red dots; 2026: "To continue, select 'Retry' or follow our 'Need More Help' article for advanced steps." + white "RETRY" + outlined "NEED MORE HELP?" |
| 11 | "Create Your Account" | e-mail + password (12+ characters, no spaces) |
| 12 | "Welcome to WHOOP!" / "Tell us your name so we get it right." | FIRST NAME / LAST NAME / USERNAME; "Username taken" error; ring ≈24% |
| 13 | "Where Do You Live?" → "Which State Do You Live In?" | search + rows; the selected row turns white |
| 14 | "Connect To Apple Health" | "SKIP" at the top-right; "CONNECT" + ring |
| 15 | "What's Your Birthday?" | inline wheel |
| 16 | "Choose a Gender" | four stacked buttons; labels **[U]** |
| – | height / weight / units | **[U]**; not seen in first run |
| 17 | "We're Not Charging You Yet" / "Activate Your Membership" | card form; ring ≈46% |
| 18 | "Privacy and Terms of Use" | see the copy below; ring ≈50–55% |
| 19 | "Setting up your Account..." | spinner over a dim; failures "ERROR" with RETRY / CLOSE |
| 20 | Membership plan choice; "Turn on Push Notifications" (pre-permission); referral | |
| 21 | "Welcome to WHOOP" splash | animated straps |
| 22 | "What to Expect Next" | calibration wheel, "NEW FEATURES UNLOCK DAILY"; green filled final circle |
| 23 | First Home | new-member state (§3.1 item 11) |

Privacy and Terms copy (step 18):
- "Agree to the statements below to use our products. Your data is secure, and never sold."
- A "SELECT AND AGREE TO ALL" row card (h 44, `#2B2F32`, radius 12).
- Four checkboxes: health-data processing; Privacy Policy; Terms of Use; marketing opt-in.
- NEXT stays disabled until the required boxes are ticked.

**Shared step template** (§2.1 onboarding tokens):
- a full-screen gradient with **no nav bar**: a "‹" at the top-left and an optional "?" or "SKIP" at the top-right;
- **content bottom-anchored**: a ≈90 pt left-aligned illustration, then the title (≈25 pt Semibold, left, 16 pt margin), the subtitle (16 pt `#BEC0C2`, 14 pt below), then the fields. Everything stacks upward from the CTA row with ≈39–53 pt of gap;
- the **78 pt ring CTA** at the bottom-right (§2.5);
- pairing and status screens instead use centred **caps** titles and full-width pills at the bottom.

**[Z] ZENO first run** (restyle the existing `OnboardingWizard` + `TermsGateView` into this template; no account, card or referral):
1. **Landing:** a full-bleed gradient (no photo), the ZENO wordmark, white "PAIR MY STRAP", outlined "EXPLORE WITH DEMO DATA".
2. **Privacy and data:** the checkbox screen with local-first statements:
   - "I understand ZENO is a wellness app, not a medical device.";
   - "My data stays on this iPhone unless I export it.";
   - "I accept the Terms of Use."
   - Plus "SELECT AND AGREE TO ALL". This replaces `TermsGateView` and goes first, because ZENO must gate before reading health data.
3. **Device sub-flow:** "Put On Your Strap" → "Wake Up Your Strap" (charge it) → "Check for Pairing Mode" (filled "START PAIRING"; the iOS Bluetooth prompt follows) → SEARCHING FOR STRAP... (ZENO's radar scan) → SELECT YOUR DEVICE → CONNECTING → CONNECTED (green ✓, "CONTINUE") / CONNECTION FAILED ("RETRY" / "NEED MORE HELP?" → ZENO's existing help text, e.g. "WHOOP straps don't appear in your iPhone's Bluetooth settings…").
   - "Skip for now" stays available, as ZENO allows today.
4. **Profile**, each step with the ring CTA:
   - "Welcome to ZENO! / Tell us your name so we get it right." (first name only);
   - "Where Do You Live?" (sets the default units; optional);
   - "Connect To Apple Health" ("SKIP" / "CONNECT");
   - "What's Your Birthday?" (wheel);
   - "Choose a Gender" + physiological baseline;
   - **"Height and Weight"** (kept: ZENO needs them when Apple Health has none).
5. **"Bring Your History"** (ZENO extra; the existing Import step): WHOOP CSV / Apple Health export, "SKIP".
6. **"Turn on Push Notifications"** (pre-permission, then the system prompt).
7. **"Welcome to ZENO"** splash, then **"What to Expect Next"**: a calibration wheel with ZENO's real thresholds (Recovery 4 nights, Consistency 5, Health Monitor 7, ZENO Age 21). Then the green ✓ final circle.
8. **Home in the new-member state** with ZENO's Get Started cards (§3.1 item 11) and Looking Ahead.

- The Appearance step is dropped (the WHOOP-style shell is dark only).
- Ring progress = step index ÷ total steps of the profile sub-flow.

### 3.39 Year in Review [C, NEW in revision 2; seasonal]
**Evidence:** `completeness-critic/08, 09, 10, 11`, `profile-community-2026/45–53, 71`, help text `raw/help-center-articles/Year-in-Review-2025.txt`.

**WHOOP 2025:**
- **Availability:** iOS 9 Dec 2025 – 12 Jan 2026.
  - Needs ≥60 Recoveries (1 Dec 2024 – 30 Nov 2025) and Coach on.
  - Entry: "an icon will appear on your Home screen". **No capture shows the icon [U]**.
- **Chrome:**
  - a full-screen story with "✕" at the top-left;
  - a centred lock-up of the wordmark + "**2025**" (italic Bold, gradient `#758FFE` → `#5CBEFF`);
  - a near-black page `#07080D` with a glow rising from the bottom, tinted per slide;
  - a **7-segment progress indicator** at the bottom: done = short white capsules, current = a long track filling white (auto-advance), upcoming = short grey capsules;
  - tap or swipe to move.
- **Slides seen:**
  - intro ("how many days I've worn Whoop"; visual **[U]**);
  - **month highlight**: a tick-ruler scrubber with an orb at the month, "February / Sat, Feb 22", a large badge card ("1% Club"), "43% of members achieved this in 2025" [POP], and a sentence "February brought your longest sleep at 14h on the 22nd — you fully recharged.";
  - a stat slide ("Total Strength Activity Time 144 hrs ▲ vs WHOOP avg of 45 hrs" [POP]);
  - **pillar top performer**: "Sleep / 2025 Top Performer / Top 2% WHOOP" [POP] + a sentence;
  - "Behavior impacts on Recovery": bars, e.g. CAFFEINE +7%, ALCOHOL −13%;
  - "HEALTHSPAN COMPARISON": me vs "Members like you" [POP];
  - **steps**: "808.7k" with a mountain: "You logged 808,735 steps — equivalent to climbing Mt. Everest 8 times. Serious elevation.";
  - **persona card** "The Year You / FOUND FLOW" with an AI-written paragraph, wordmark and "2025";
  - a "message to your future self" step (text **[U]**).
- **Summary share card** (final slide, share button) [C `completeness-critic/09`]:
  - "WHOOP 2025 / Year in Review", the name, the WHOOP Age orb at the top-right;
  - LEVEL 25 / 1907 Recoveries · DAY STREAK 1914 Days;
  - a ring trio with dates (Best Sleep 100% Mar 31 · Peak Recovery 95% Feb 2 · Max Strain 20.6 Oct 12);
  - rows Longest Sleep 9:27 hr (Nov 1) · Lowest Recovery 7% (Oct 14) · Top Activity Running 252x.

**[Z] ZENO "ZENO 2025"** (fully local, no LLM required):
- **Entry:** a My Day promo card "Your 2025 in Review ›" from 1 Dec to 15 Jan, plus a Trends INSIGHTS row.
- **Slides:**
  - days worn and level;
  - three month moments (longest sleep, highest and lowest Recovery, biggest strain);
  - best pillar ("Your strongest pillar: Sleep");
  - behaviour impacts from `EffectRanker`;
  - steps with the Everest equivalence (8,848 m ÷ ≈0.16 m per step);
  - a templated persona paragraph;
  - the summary share card rendered locally.
- Replace every [POP] comparison with "vs your 2024" or "vs your own average".

### 3.40 Weekly and monthly review [Z, NEW in revision 2]
**WHOOP facts:**
- No in-app Weekly or Monthly Performance Assessment exists since May 2025.
- "Month in Review" is an e-mail.
- "Weekly Wrap" is delivered by Coach, with no screenshot **[U]**.
- The plan's "My Week Recap" exists only in DE/ES/FR store art (§3.19).

**ZENO Weekly Digest** (restyles the existing `WeeklyDigestView`):
- **Entry:** Trends › THIS WEEK card, Trends › INSIGHTS › WEEKLY DIGEST, and a Monday coaching card "Your week in review".
- **Layout:**
  1. "‹ WEEKLY DIGEST" + the range pager "‹ SEP 22 - SEP 28 ›" (W | M segmented for the monthly digest).
  2. A three-ring summary: Sleep / Recovery / Strain weekly averages (Home-dial style), each with a delta chip vs the prior week.
  3. A plan block (when a plan exists): "44% COMPLETE" + bar + goal rows with segmented rings (the My Week Recap layout).
  4. Weekly Trends cards reused from the deep dives (RECOVERY, STRAIN, SLEEP PERFORMANCE).
  5. A "Highlights" card in the Notable-stats row style: best Recovery day, max Strain, longest sleep, most zone minutes.
  6. A "Behaviors this week" diverging-bar list (journal behaviours logged that week, with their 90-day impact).
  7. An insight card (Coach when configured; otherwise a template), then "EXPORT REPORT" (nested button → the existing PDF).

### 3.41 Challenges [Z, optional, NEW in revision 2]
**WHOOP** (`profile-community-2026/13, 39, 42, 76, 84, 85`): WHOOP-run timed challenges (e.g. "All-In 250", 250 activity minutes in 7 days). They have four surfaces:
- **Join page:** a tick-mark gauge hero, "Challenge starts June 29, 2026", the title and body, a "WHAT YOU EARN" reward card [commercial], and "JOIN CHALLENGE".
- **In-progress page:** the partly lit gauge, "168/250 MINUTES LOGGED", "4 days left", a "Great start!" sentence, and "ADD ACTIVITY".
- **Complete page:** "460/250", "✓ Complete", and a contributing-activity list grouped by day.
- **Badge:** an unlock modal ("CLOSE" / "SHARE") and a badge in the STRAIN section.

**ZENO:** user-defined local challenges (e.g. "250 zone-2 minutes this week", "7 nights in bed by 23:00") on the same three pages, with no rewards. The entry is a Trends INSIGHTS row and, while one runs, a Home coaching card.

---------------------------------------------------------------------------------------------------

## 4. UNCONFIRMED and inferred items (consolidated, revision 2)

**Resolved since revision 1** (no longer UNCONFIRMED):
- Health and Community tab placement in the capsule.
- The Community root.
- Recovery and Strain Weekly Trends order.
- The Sleep detail cards.
- Plan Overview title.
- Behavior Insights 2026 page and Logging History.
- The Levels formula.
- The Achievements page top.
- Edit Profile entry.
- The Start Activity flow.
- The strain band/tick rule (now consistent across seven captures, though not documented by WHOOP).

**Structure and placement:**
1. **Health tab 2026 for Life members below BLOOD PRESSURE INSIGHTS:** the relative order of Heart Screener, Menstrual and Stress. Also the slot of Connect Health Records, the 2026 disclaimer, and whether anything follows "Upgrade to Access".
2. **More tab 2026:** the 5-letter SUPPORT row, what FIRST WEEK WITH WHOOP opens, and the Getting Started checklist page visual.
3. **App Settings:** the labels and order of the 9 rows (mapping guessed), and the visuals of Notifications, Hide Metrics, Privacy and Coaching Preferences.
4. **Deep dives below the captured cards:**
   - Sleep after the weekly SLEEP EFFICIENCY card;
   - Recovery after RESPIRATORY RATE, whose body is storyboard-only;
   - Strain after HR ZONES 4-5: cards 4 and 5 are probably STEPS and CALORIES.
5. **Insight-card removal rule:** Sleep dropped the inline card from ≈Jun 2026, Recovery by Sep 2026, and Strain still had it in Jul 2026. Whether this is a rollout or a rule is unknown.
6. **Daily Outlook → Day in Review switch time** (between 16:53 and 21:18 in captures; ZENO picks 18:00). The 2026 "Unified Daily Experience" is roadmap text only.
7. **My Plan placement:** after My Journal in May–Aug 2026 captures; above My Day in the Apr 2026 5.49.2 build.
8. **Week-1 Home** without monitor tiles (`completeness-critic/25`): a calibration rule or the One tier.
9. **Home Year in Review entry icon:** text only.

**Dials and gauges:**

10. **Strain band/tick semantics** are measured, not documented (band = optimal range, tick = target ≈ midpoint).
11. **Stress gauge** inner tinted band width and needle size are estimated; the 2026 sweep may be ≈240° rather than 225°.
12. **Live Activity Strain ring:** the avatar knob's meaning (activity Strain Target) and the intensity words beyond RESTING / MODERATE.

**Copy, cut-offs and labels:**

13. Activity Details "▲ 9.7" chip (read as the typical strain for this sport).
14. Streak flame cut-offs (orange, magenta); whether the streak pill is always hidden on past days (two captures); the battery-red threshold; Levels 7–30 material names and tier rings.
15. English wording of: My Week Recap; the UNLOCK HEALTHSPAN card (seen in Spanish); the locked-row "low confidence" subtitle (German); the Journal dismiss dialog; the Day Streak magenta tier message.
16. Menstrual header tint following the current phase; Home Menstrual card labels and prediction sentence; the Pregnancy card (never seen).
17. Achievement criteria for Pillow Perfect, Green Week, Peak Day, Strain Seeker, All Out Day, Healthspan Comeback and VO₂ Phenom; star cut-offs; whether "Achievements (N)" counts unlocked or total.
18. Behavior Insights: the meaning of the blue "!" chip; the header block when nothing is unlocked; the end-of-list card wording; whether the INSIGHTS pill still exists inside the 2026 Journal.

**Interaction and motion:**

19. Action-menu animation, coach-button corner radius, dial sweep on load, haptics, and whether the onboarding ring arc animates.
20. Coaching-stack swipe gesture; what the "✓" does (dismiss vs complete); the "◜ 3" counter glyph.
21. Activity Details modal vs push; Sleep row → Sleep activity detail vs deep dive (ZENO picks the deep dive).
22. Start Activity:
    - which page the live pager opens on;
    - the End & Save confirmation and the post-save summary (never captured);
    - the iOS 2026 Heart Rate page;
    - the Edit Activity HR scrubber and the placement of its edit icon;
    - the Add flow order (list or form first);
    - the "Where did you wear" options.
23. Trend View metric-picker sheet, scrub callout, and the manual-entry sheets (VO₂, weight).
24. Sleep Planner alarm-mode sheet, latest-wake wheel and My Schedule rows (pre-2025 images).
25. Coach conversation-history list (no capture in any version) and where history lives in v6.x; the production My Memory chip row; the Memory "Inactive" state.
26. Stress Monitor below TOTAL DAY (Non-Activity / Sleep cards, Sessions, the ⚙ settings page).

**Not seen at all:**

27. Light mode: none exists; the app is dark-only, apart from the Start Activity panel and some ⓘ sheets.
28. Lock-screen Sleep / Recovery / Strain gauges.
29. Team INFO tab below ABOUT; Pending Invites; member profile pages; the final follow-friends UI.
30. Onboarding:
    - the splash screen;
    - the second landing button's copy;
    - the 2026 password step;
    - the Gender labels;
    - the height/weight steps;
    - the system permission sheets;
    - the "Customize Your WHOOP Experience" tour widget.

**Fonts:**

31. **WHOOP's fonts are Proxima Nova and DINPro** (brand PDF). ZENO uses SF Pro per DR. Sizes here are SF-equivalent estimates (±1 pt).

---------------------------------------------------------------------------------------------------

## 5. Key reference images per screen (open these when building)

| Screen | Best images (relative to `whoop-reference/`) |
|---|---|
| Home top (default size) | `images/appstore/ios69-01-home-overview.png` |
| **Home whole page (past day)** | `images/completeness-critic/16-forum-2026-05-home-full-page-past-day-wed-may27-annotated.jpeg` (8217 px tall; view in slices) |
| Home top (device, tab bar) | `images/reviews/02-5kr-home-NEW-layout-oct2025.png`, `images/help-center/91-…data-caught-up-very-elevated.png`, `images/reviews/r41-2026-09-19-productive-day.jpg` |
| Home new member / week 1 / unscored | `images/completeness-critic/24-…`, `25-…`, `26-…`, `images/onboarding/31a-…` |
| Sticky mini-ring header | `images/completeness-critic/02-…`, `13-…`; variant `images/reviews/r114-2026-08-01-my-plan-weekly.jpg` |
| Home lower (dashboard, journal, plan, Menstrual) | `images/reviews/05..07-*.png`, `images/health-more-2026/04-…`, `05-…`, `images/journal-plan-2026/31-…`, `32-…`, `34-…` |
| Action menu | `images/reviews/03-5kr-action-button-menu.png`, `images/help-center/64-forum-2025-11-home-action-menu-open.jpeg` |
| Customize Dashboard | `images/reviews/04-5kr-home-customise-dashboard-metrics.png` |
| Deep-dive tops | `images/appstore/ios69-02-sleep.png`, `ios69-03-recovery.png`, `ios69-04-strain.png`; `images/deep-dives-2026/17b-…`, `57-…`, `56-…` |
| Sleep detail cards | `images/deep-dives-2026/01-…` (order), `18-…`, `19c-…`, `19-…`, `19b-…`, `03-…`, `02-…`, `15-…` |
| Weekly Trends | `images/deep-dives-2026/07-…`, `08-…`, `10-…`, `13-…`, `16-…`, `19d-…`; storyboard `41-…` (Strain) |
| Strain dial band / tick | `images/help-center/91-…`, `images/completeness-critic/25-…`, `16-…`, `images/reviews/02-…`, `r41-…` |
| Trend View | `images/deep-dives-2026/46-…`, `44-…`, `45-…`, `51-…`, `53-…`, `30-…`, `20-…`; `images/help-center/81-…` |
| Activity Details | `images/whoop-site/95-…`, `images/help-center/82-…`, `images/activity-flows-2026/e03-…`, `g15-…`, `f02-…`, `g24-…` |
| Start Activity / live | `images/activity-flows-2026/a01-…`, `a07-…`, `a05-…`, `a06-…`, `b01-…`, `b05-…`; `images/completeness-critic/05-…`, `27-…` |
| Add / Edit Activity | `images/activity-flows-2026/c01-…`, `c03-…`, `d04-…`, `c06-…` |
| Day HR timeline / tilt | `images/help-center/106-…`, `images/reviews/r132-…`, `images/activity-flows-2026/e04-…` |
| Sleep Planner | `images/help-center/86-forum-2025-10-sleep-planner-android.jpeg`, `images/reviews/r134-2026-05-30-sleep-at-6pm.jpg` |
| Coach / Memory | `images/profile-community-2026/66-…`, `27-…`, `72-…`, `55-…`, `74-…`; `images/reviews/r123-…`; `images/journal-plan-2026/04-…` |
| Journal | `images/journal-plan-2026/01-…`, `07-…`, `16-…`, `08-…`, `09-…`; `images/help-center/105-…` |
| SELECT BEHAVIORS | `images/journal-plan-2026/14-…`, `13-…`, `02-…` |
| Behavior Insights / Details | `images/journal-plan-2026/20-…`, `20a-…`, `26-…`, `28-…`; `images/completeness-critic/21-…`, `20-…` |
| Plan | `images/completeness-critic/23-…`, `images/journal-plan-2026/30-…`, `34-…`, `images/reviews/r11-…` |
| Health tab 2026 | `images/reviews/r07-2026-06-07-health-tab.jpg`, `r44-…`, `images/health-more-2026/02-…`, `03-…`, `16-…` |
| Health Monitor / Stress Monitor (2026) | `images/reviews/33-androidpolice-screens-2-may2026.jpg`; `images/completeness-critic/14-…`, `15-…`; `images/appstore/ios69-10-stress.png` |
| Healthspan | `images/appstore/ios69-05-healthspan.png`, `images/reviews/29-wareable-healthspan-aug2025.jpg`, `r119-…`, `images/help-center/112-…` |
| Menstrual Cycle Insights | `images/appstore/ios69-09-menstrual-cycle-insights.png`, `images/health-more-2026/07-…`, `11-…`, `images/help-center/10-…`, `12-…` |
| BP / Heart Screener (reference only) | `images/health-more-2026/10-…`, `14-…`, `15-…` |
| Strength Trainer | `images/activity-flows-2026/g01-…`, `g02-…`, `g07a-…`, `g07b-…`, `g08-…`, `g03-…` |
| Profile / Levels / Achievements / Day Streak | `images/profile-community-2026/10-…`, `21-…`, `11-…`, `56-…`, `04-…`, `80-…`, `05-…`, `12-…`, `15-…`; `images/reviews/r73-…`, `r48-…` |
| More / App Settings / Integrations | `images/health-more-2026/06b-…`, `08b-…`, `24-…`, `25-…`; `images/reviews/r05-…` |
| Device Settings | `images/reviews/r01-2026-10-02-not-syncing.jpg`, `images/help-center/97-…`, `96-…`, `images/onboarding/43a-…` |
| Community (reference only) | `images/profile-community-2026/75-…`, `01-…`, `86-…`, `68-…` |
| Onboarding | `images/onboarding/15b-…`, `22d-…`, `20d-…`, `13e-…`, `12d-…`, `09b-…`, `31a-…` |
| Year in Review | `images/completeness-critic/09-…`, `10-…`, `08-…`, `11-…`; `images/profile-community-2026/45-…`, `47-…`, `50-…` |
| Widgets | `images/reviews/r26-2025-05-09-rings-widget.jpg`, `images/help-center/18..21` |
| Errors / dialogs | `images/activity-flows-2026/c06-…`, `c08-…`, `images/journal-plan-2026/09-…`, `images/onboarding/24a-…` |
| 2026 component collage | `images/whoop-site/11-whats-new-2026-header-IMG_4459.png` |
| ZENO today (for before/after) | `images/zeno-inventory/00-zeno-overview-all-screens.png` |
