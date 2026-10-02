# WHOOP iOS app 2025–2026: what independent reviews and community screenshots show

Topic: independent reviews (the5krunner, Wareable, Stuff, Tom's Guide, TechRadar, Digital Trends, TechGearLab, Android Police, TechBuzz Ireland, DC Rainmaker) and r/whoop community posts with screenshots.
Covered period: WHOOP 5.0 / MG launch (May 2025) to 2 Oct 2026.
Images: `/Users/raghavrathi/Downloads/Whoop-Apps-Handover/whoop-reference/images/reviews/` (187 files, private reference only, never commit).
Everything below is what I saw in those images or read in those articles. Anything not visually confirmed is marked **UNCONFIRMED**.

How measurements were done:
- Sizes come from full-resolution 3x screenshots: 1179 px wide = 393 pt (iPhone 15/16/17 Pro) and 1320 px wide = 440 pt (Pro Max). pt = px / 3.
- Colours are pixel samples (Pillow). Many iPhone screenshots are saved in **Display P3** and the publisher stripped the profile, so the raw numbers look "washed out". I converted those samples back to sRGB. The converted values match WHOOP's classic brand palette exactly, which is good evidence that the conversion is right (details in §2.2).
- Font families are **UNCONFIRMED**. Visually: condensed, squared DIN-style numerals for scores and times, and a geometric grotesk (Proxima-Nova-like) for labels and body text. Sizes are estimated from cap heights (cap ≈ 0.70 × font size).

---------------------------------------------------------------------------------------------------

## 0. Timeline of app layout changes (2025 → Oct 2026), assembled from dated posts and reviews

| When | Change | Evidence |
|---|---|---|
| 3–8 May 2025 (5.0/MG launch) | New Home: three separate rings (Sleep / Recovery / Strain) replace the single classic recovery/strain dial. Health/Stress Monitor tiles. "My Day". A new **Health** tab replaces the old "Plan" tab. The Overview tab and MPA/WPA (monthly/weekly performance assessments) are removed (MPA becomes email-only). For a few days some users saw a transitional build with OVERVIEW / SLEEP / RECOVERY / STRAIN tabs on top of the classic dial. | r30, r31, r32, r104, r141, r98, r101, r100; Reddit "New UI", "Not a fan of this new Home Screen", "Overview and Insights Page, MPA and WPA removed" |
| 28 May 2025 | Health-tab upgrade modals can be dismissed with an X for One/Peak members | official r/whoop post "Latest WHOOP Updates (5/28)" |
| Jun 2025 | Day-streak flame pill appears next to the avatar on Home ("The little flame animates on the full screen") | Reddit "Day Streak" (2025-06-09); "Another L for Whoop (recovery streak)" complains about it |
| 18 Jul 2025 | "Day in Review" end-of-day coaching card added; Daily Outlook integrates Healthspan | official "WHOOP Coach Update (7/18)" |
| Aug 2025 | Profile redesigned (milestones, achievements, Data Highlights) | "Updated Profile Tab" (2025-08-19), official "WHOOP Updates (1/8)" |
| Sep 2025 | Coach memory; Advanced Labs launch | official "WHOOP Coach Update (9/19)"; 12-5kr-coach-memory |
| early–mid Oct 2025 (Reddit "New app layout" 4 Oct, possibly a staged rollout; Reddit "moved the activity button" 14 Oct; 5kr article 15 Oct says "this morning the new app version changed…") | **Navigation re-layout.** Tab bar becomes a floating rounded pill (Home / Health / Community / More) plus a separate round-cornered **Coach "W" button** at the right. The "+" action button moves from a floating FAB to a white square next to "My Day". The "W" button that sat left of "Daily Outlook" is removed. Home onboarding card: "Coach at Your Fingertips". | 01 vs 02, r130; Reddit "New app layout" (2025-10-04): "dreadful… feels cluttered"; "Whoop moved the activity button so you muscle memory press it's AI Coach" (2025-10-14) |
| Oct 2025 | Contextual chat entry points on Sleep/Recovery/Strain pages; "proactive conversations" announced | official "[Megathread] WHOOP update: New AI guidance…" (2025-10-16) |
| Dec 2025 | 2025 Year in Review inside the app; "Discover More" promo cards at the bottom of Home | r13; official post 2025-12-09 |
| Feb 2026 | Strength Trainer: "Generate with WHOOP AI", PROGRESS tab (Total Volume Load, Personal Records); coach Beta v5.2 | 28-wareable-strength-trainer-2026 |
| Mar 2026 | WHOOP AI v5.3: suggested-question chips, revamped chat, Goals & Plans | r72 |
| Apr 2026 (iOS v5.49.2) | "My Plan" moved **above** "My Day" on Home; the user found it "way more cluttered" | r68 |
| May 2026 | Memory moves to Profile; voice/text journaling; strength PRs; a friends/follow feature briefly leaks | official "WHOOP Updates (5/8)"; r67 |
| by Jun 2026 | **Health tab redesign**: a large glowing WHOOP-Age "planet" at the top, Pace-of-Aging ruler card, Advanced Labs card, Health Monitor… | r07, r44, AP photo 6 |
| Jun 2026 | Sleep-recommendation UI removed from Day in Review ("It's just a bunch of text"). The sleep recommendation now appears as a card inside coach chat. | r58, 32-androidpolice |
| Sep 2026 | Roadmap: custom journal behaviours; a unified daily flow (Journal + Daily Outlook + Check-ins + Day in Review); follow friends (Nov); rebuilt live activity tracking with splits and pause (Nov); one-rep max (Nov) | official "Coming Next…" (2026-09-03) |
| Oct 2026 | New **Achievements** UI (badges, animations). Coach shows "v6.0" with a "Memory" button. | r40, r140, r123 |

---------------------------------------------------------------------------------------------------

## 1. Information architecture (current, Oct 2025 → Oct 2026)

- **Bottom navigation.** A floating rounded pill holds four tabs: **Home · Health · Community · More**. A separate square-ish **Coach button** (W logo in a purple→blue gradient ring) sits to its right. On iPhone 393 pt the label "Community" is truncated to "Commu…" (02, 05–07).
  - May–Sep 2025: classic full-width bottom bar with the same four tabs and no coach button; a white circular "+" FAB floats bottom-right above the bar.
  - Pre-May 2025 (legacy, r18 Mobbin, for contrast only): Home · Plan · Community · More, with top segmented tabs OVERVIEW / SLEEP / RECOVERY / STRAIN.
- **Coach access points.** The tab-bar W button opens a bottom-sheet chat. "Daily Outlook" / "Day in Review" bars open on Home. Coach insight cards with gradient borders sit inside the Sleep, Recovery and Strain pages ("EXPLORE YOUR … INSIGHTS →"). On detail screens without a tab bar, a **floating circular W button** sits bottom-right (r66, r119, AP screens, r75 Android). An Android user complained it covered the "Broadcast Heart Rate" toggle (r75, "Move the chat button").
- **"+" (Action) menu.** A popover anchored to the "+" next to My Day, with items START ACTIVITY · ADD ACTIVITY · STRENGTH TRAINER · COMPLETE YOUR JOURNAL · CREATE WHOOP LIVE. The "+" turns into an X close button in a dark rounded square (03).
- **Ring taps.** Tapping a ring opens its Sleep / Recovery / Strain detail page (title "TODAY", back chevron, ⓘ).
- **Header taps.** The device icon opens Device Settings; the avatar opens Profile.
- **Tilt mode.** Rotating the phone to landscape opens a full-day heart-rate chart (r132; "TIL you can just tilt your phone…", 2026-07-16; WHOOP Locker calls it "tilt mode").

---------------------------------------------------------------------------------------------------

## 2. Global visual language

### 2.1 Page background
A vertical gradient from cool slate-blue at the top to near-black at the bottom. Samples taken at the left edge, as a fraction of screen height:

| Build | 3% | 15% | 30% | 50% | 70% | 85% |
|---|---|---|---|---|---|---|
| 2025 (r31, r104, r20, 80, 84) | `#263137` | `#222931` | `#1B1F28` / `#1A2126` | `#13181C` | `#101518` | `#0E1215` |
| 2026 (r12, r03, r46, r02, r40) | `#293038` | `#232A32` | `#1E2327` / `#1F2428` | `#15181D` / `#16191E` | `#121619` | `#101417` |
| Oct 2025, 5kr 02, by y in pt | 0 pt `#29323A` | 100 pt `#22292E` | 200 pt `#1D2227` | 400 pt `#14181C` | 700 pt `#101215` | under the floating tab bar ≈ `#030304` (black fade) |

- Full-screen pushed pages such as Day Streak use a flat `#101518` (r48).
- The 2026 Health tab starts **near-black** (`#090909` at the top) behind a coloured glow from the WHOOP-Age sphere, then returns to `#14191D` in the middle (r44).
- Outlier: the5krunner's "old home" capture (01) is almost pure black (`#050709` → `#010101`) and its colours look warm-shifted. Treat it as a capture anomaly; no other 2025 or 2026 capture looks like this.

### 2.2 Colour palette (sRGB, measured)
These are the classic WHOOP brand colours. The P3-encoded captures convert back to them exactly.

| Role | sRGB | Seen as P3-raw | Where measured |
|---|---|---|---|
| Recovery green (≥67%) | `#16EC06` / `#19EC06` | `#6EE947` (raw `#6FE64A`) | Stuff 80 ring; 05 chart "100%"; r41 ring |
| Recovery yellow (34–66%) | `#FFDE00` (sampled `#FFDE03`, `#FBDB00`) | `#F9DF4A` | 02 ring; r12, r31 rings; 05 chart |
| Recovery red (≤33%) | `#FF0026` | `#EA3334` (raw `#EE3135`) | 06 chart; r46 ring; r54 ring `#F60527` |
| Strain blue | `#0093E7` (`#0092E7`) | `#4090E0` | every strain ring, activity badge, S&R chart, HR line |
| Sleep steel-blue | `#7BA1BB` (also `#77A3C0`) | `#83A0B8` | sleep ring, sleep badge, sleep bands |
| WHOOP teal-green ("positive / optimal / within range / MEDIUM stress / up-good") | `#00F19F` (`#02F19E`) | `#6EEDA6` | "WITHIN RANGE", "MEDIUM", ▲ good arrows, plan progress bar, "Lowest" BP label, optimal chips, ECG checks |
| Warning orange ("poor / negative trend / ALARM OFF / HIGH stress / out of range / Highest") | `#FFA722` (`#FEA622`) | `#F1AA45` | ALARM OFF, ▼ bad arrows, BP gauge end, chips |
| Light blue ("LOW stress", "x Years Younger", selected journal check) | `#67AEE6` | raw `#77ACE1` in the P3-tagged 81 | 81, 84, 89 |
| Red alert text (stronger out-of-range, CARD EXPIRED, low battery) | ≈ `#F61331` / `#D83536` (JPEG) | `#E2363B` | r02, r42, r63, r46 |
| Coach gradient (border, input outline, CTA text, W ring) | purple `#8B65FF` → blue `#67BFFF` (input border `#8B62FF` → `#52D3FF`) | `#8567F6` → `#7DBDFA` | 08, 10, 11, 88, 02 |

Neutrals (identical in sRGB and P3):
- Text: primary `#FFFFFF`; secondary `#C0C1C2`; tertiary / meta `#959799`–`#989A9C`; inactive tab label `#868889`–`#8D9092`.
- Chevrons `#8D9092`–`#97999B`.
- Ring track `#33373B`–`#373D41`; empty-state ring `#373F42`; empty placeholder "--" `#4B5054`.
- Hairline dividers `#3C3F40`–`#474A4E`; chart gridlines `#42474C`.

Surfaces and cards (opaque greys on the gradient):
- Monitor tiles and Health-tab cards: `#2E3135`–`#32383D`.
- Dashboard / My Day cards: `#282C2E`–`#2C3134`.
- Activity rows inside a card: `#414649`–`#42464A`.
- Inner buttons inside cards ("SET ALARM", "ADD ACTIVITY"): `#323435`–`#43474A`.
- Coach insight card: darker `#1C2126` with a gradient border.
- Sleep-contributor legend box: `#0D1012`.

Tinted chips and tiles:
- Green chip/tile background `#224A40`–`#275047` (text `#00F19F`).
- Orange chip/tile background `#493F2D`–`#4B4231` (text `#FFA722`).
- Teal "Sufficient" chip background `#35444B` (text `#6EB9B7`).
- Stress "LOW" badge has a blue-grey tile.

Gradient bars (Home):
- Day In Review: indigo `#2E2B50` → slate-teal `#2B4351`, chevron blue `#7FB3F9`.
- Daily Outlook: warm tan `#847A6E` → slate `#374552`.

Promo and feature cards: gradient **border** from peach/coral `#E7865C` to purple `#C043C7`; CTA text magenta-purple ("UPGRADE NOW →", "LEARN MORE →", "LET'S GO →", "START ACTIVITY →").

Referral card: iridescent pastel fill (mint `#BDC4B4` → lilac `#B6ACBE`) with dark text (r05).

Journal sheet: purple gradient header `#402D7B` → `#1D1C37` → `#101518` (Stuff 89, Jun 2025). One TGL capture shows a tan header instead (56). **UNCONFIRMED** whether the header colour depends on time of day.

Daily Outlook chat page: tan `#776E61` at the top → slate `#232D37` → `#111417`.

### 2.3 Shape, spacing and type (measured on the 393 pt home, 02)

**Layout**
- Screen side margin **16 pt**. Gap between two-up tiles **12 pt**.
- Card corner radius ≈ **12 pt** (continuous corners; the curve settles ~33 px / 11 pt from the edge).
- Section spacing: a 16 pt gap between the Daily Outlook / Day-in-Review bar and the next card.

**Rings**
- Each ring is **88 pt** in diameter with a **6 pt** stroke. Centres are 121 pt apart, the first at x = 75.5 pt.
- The arc starts at 12 o'clock and runs clockwise, with round caps and a small visible gap at the top.
- **Strain ring extras:** a lighter-grey **target-range band** (`#5C6063`) on the track plus a **white tick** marking the optimal strain target.

**Header**
- Avatar ≈ 32 pt circle.
- Streak pill ≈ 32 pt tall.
- Date navigator: inner pill ≈ 31 pt tall × 174 pt wide; outer capsule ≈ 28 pt tall.
- Battery % and strap icon sit at the right.
- These header pills are translucent, overlapping "glass" capsules (iOS 26 look).
- WHOOP wordmark: thin outline-style logotype, ≈ 12 pt tall × 69 pt wide, centred.

**Monitor tiles:** 174.7 × 138 pt.

**My Day row**
- "+" button: **36 × 36 pt** white rounded square with a black glyph.
- Day-In-Review bar: full width × **48 pt**.

**Tab bar (Oct 2025+)**
- Pill ≈ **292 × 64 pt**, left margin ≈ 13 pt, background `#1E2328`–`#20262B` (translucent).
- Coach button ≈ **63 × 63 pt** rounded square, background `#151527`, W ring ≈ 32 pt.
- Tab icons ≈ 21 pt; labels ≈ 14 pt semibold. Active = white, inactive = `#8D9092`.

**Lists (Stuff 80, 440 pt device)**
- Activity rows: **56 pt** tall, 12 pt gaps, 12 pt inset inside the card.
- Strain/sleep badge ≈ **95 × 40 pt**, filled (blue `#0093E7` or sleep `#7BA1BB`), white icon plus a bold value.
- A 2 pt vertical time bar sits at the far right of each row.
- Dashboard metric rows: **60 pt** tall with 12 pt gaps (06).

**Type (approximate pt)**

| Element | Size | Style |
|---|---|---|
| Ring score "98" | ≈ 26–27 pt | bold condensed numerals |
| "%" sign | ≈ 19 pt | same baseline as the score |
| Ring labels "SLEEP ›" | ≈ 10–11 pt | bold, uppercase, wide tracking |
| Section titles "My Day", "My Plan", "My Dashboard" | ≈ 26 pt | semibold/medium, sentence case |
| Card titles "HEALTH MONITOR", "TONIGHT'S SLEEP" | ≈ 15 pt | bold, uppercase, tracked ~1.5 pt; may wrap to two lines in tiles |
| Status words "WITHIN RANGE", "MEDIUM" | ≈ 14–15 pt | bold, uppercase, coloured |
| Sub-text "5/5 Metrics", "1:00 AM" | ≈ 15 pt | regular, `#C0C1C2` |
| Big times "Now", "8:00" | ≈ 27 pt | bold numerals |
| Labels "RECOMMENDED BEDTIME" | ≈ 12 pt | bold uppercase, grey |
| "Your Day In Review" | ≈ 19 pt | medium |
| Date text "OCT 14 TO TODAY" | ≈ 14 pt | bold uppercase |

**Icons**
- Thin-line monochrome glyphs: heart-with-pulse = Health, house with trend line = Home, three people = Community, three lines = More.
- Metric icons: lungs = RESP, droplet = SpO₂, heart-arrow = RHR, pulse wave = HRV, thermometer = TEMP, footprint = steps, flame = calories, crescent = sleep.
- Activity pictograms are solid white silhouettes inside the badges.

**Charts**
- Dark plot area, thin grid lines, small grey axis labels, and a dashed vertical "now" line ending in a white dot.
- The selected day column is a lighter vertical band (`#3D3F41`) with white bold axis text.
- Values sit next to the points in the series colour.
- Coloured bands across the top of a chart mark sleep, activity and naps; icons above the plot mark activity types.

---------------------------------------------------------------------------------------------------

## 3. Screens, top to bottom

### 3.1 HOME — current layout (Oct 2025 → Oct 2026)
Images: 02 (Oct 2025), 05/06/07 (scrolled), r02, r03, r12, r41, r42, r43, r45, r46, r50, r52–r56, r59, r63, r70, r71, r122, r130, r143, r13 (bottom), r15, r114, r68 (Apr 2026 order), 35-androidpolice-app-photo-1.

1. **Header row**
   - Avatar: photo, default person-outline icon, or initials on a pastel circle ("EL" lavender `#D2A5FA`, "MO" mint, "RN"/"SC"/"JN" pink/purple, "NC" orange).
   - Streak pill: flame + count, e.g. 5, 15, 72, 105, 337, 445. Flame colour shifts with streak length: gold/yellow when small, orange/red, pink-red; the Day Streak page shows a **blue** flame at 1607. Thresholds **UNCONFIRMED**.
   - Date capsule: `‹ [ TODAY ] ›`. The inner lighter pill text is TODAY, "MON, JUN 16", "WED, MAY 27", or a range such as "OCT 14 TO TODAY" / "SEP 5 TO TODAY" when the cycle spans days. The right chevron is dimmed when on today.
   - Right side: battery "97%" in grey (red "11%" / "12%" when low) plus a strap outline icon with a status dot (green = connected; orange charging arrow in Jun 2025).
2. **WHOOP wordmark**, centred.
3. **Three rings**: SLEEP › (percent), RECOVERY › (percent, zone colour), STRAIN › (0.0–21.0).
   - Empty/new user: grey tracks with "--%" / "--" (r03), or strain "0.0" with only a tiny arc (r06).
4. **Conditional banner** (black or very dark card, full width):
   - "CARD EXPIRED" — red title, red "!" square, grey body "To keep your membership active, update your payment method prior to 10/18.", chevron (r02). One user called it non-dismissible.
   - "YOUR WHOOP IS OFF-BODY / Wear your WHOOP 24/7 to unlock insights." (r56, r89, 94).
   - "MEMBERSHIP EXPIRED / Click here to reactivate your membership" (r77).
   - "FIRMWARE: UPDATE COMPLETE / You're all set. Your firmware is now updated to the latest version from WHOOP." — green check square, green title, X (r116).
5. **Insight / notification card stack** (conditional). Dark card, title (≈17 pt semibold white) and body (≈15 pt grey). Top right: a small rounded chip with ✓ over a count ("✓ 2"); a second card peeks underneath (stack). Examples:
   - "Strain Target Reached", "Reaching Optimal Strain", "Pushing Limits", "Recovering from Strain", "Low HRV".
   - "Newly Red" (mini bar-chart illustration, "VIEW TREND →" in blue).
   - "1% Club" (skull-coin illustration, "VIEW TREND →").
   - "Your Home Has a New Look" (house illustration, "LEARN MORE →").
   - "Coach at Your Fingertips" (r130).
   - "Advanced Labs Unlocked" (r15), "Get the All-New WHOOP" (r27).

   Feature/promo cards use the peach→purple gradient border and a magenta CTA.
   Error state (Jan 2026): a dashed-outline card reading "Couldn't load new notifications. We'll try again later." with an orange info glyph (r12).
6. **Monitors row** (two tiles; Peak/Life only):
   - **HEALTH MONITOR ›**: [✓ in a green tile] **WITHIN RANGE** (teal-green) / "5/5 Metrics". Alternatives:
     - [! orange tile] **OUT OF RANGE** "2/5 Metrics" (orange in r46, red in r42).
     - "3/5 Metrics" in red (r63, r143).
     - **ELEVATED** "Respiratory Rate" / "RHR" (orange).
     - [● grey] "Calibrating" (r12).
     - "4/4 Metrics" when skin temp is disabled (r100).
   - **STRESS MONITOR ›**: [value badge e.g. "1.6"] **MEDIUM** (teal-green) / "1:00 AM". Levels: LOW (light blue, blue-grey badge), MEDIUM (green badge `#2F4C44`), HIGH (orange, brown badge `#4E4639`).
7. *(From iOS 5.49.2, Apr 2026: the **My Plan** section can appear here, above My Day — r68.)*
8. **"My Day"** title (left) + white **"+"** square (right).
9. **Coach bar**, full width, 48 pt, rounded.
   - Morning/day: "☀ Your Daily Outlook" or "<First name>'s Daily Outlook" — tan → slate gradient, white chevron (r02, r15, r130).
   - Evening: "☾ Your Day In Review" — indigo → teal-slate gradient, blue chevron (02, r41, r46).
   - New users: "Ⓦ Ask a question, get support…" on a plain card (r12).
   - May–Sep 2025: a separate square W button sat to the left of a "Daily Outlook" bar (r31, r103, r89).
10. **Card order follows the time of day.** Evening: TONIGHT'S SLEEP comes first, then TODAY'S ACTIVITIES (02, r41, r42, r46). Day: TODAY'S ACTIVITIES first (r12, r43, r50).
11. **TODAY'S ACTIVITIES** card (title uppercase + expand icon ↗↙ top right; older builds say "ACTIVITIES"):
    - Rows: [badge] NAME (uppercase bold) … start/end time stacked right ("[Sun] 23:44 / 7:14", "12:51 AM / 7:38 AM") … thin vertical bar.
    - Badge types:
      - sleep: steel-blue fill, moon + duration "6:29";
      - nap: steel-blue fill, reclining-person icon + "1:15";
      - strain activity: blue fill, sport pictogram + strain "10.3";
      - functional fitness / planned activity: **outlined** badge with icon + a bar-chart glyph, dotted time bar (r57).
    - Buttons at the bottom: "+ ADD ACTIVITY" | "⏱ START ACTIVITY" (two equal buttons, 2025–26). When there are no activities only "+ ADD ACTIVITY" spans the full width (r03, r20).
12. **TONIGHT'S SLEEP ›** card:
    - Left: sunset-with-arrow icon + big time ("Now", "23:12", "12:36") over "RECOMMENDED BEDTIME".
    - Middle: a dashed connector.
    - Right: haptic-band or sunrise icon + wake time ("8:00", "06:30") over "ALARM OFF" (orange) or "● ALARM ON" + "EXACT TIME" / "LATEST ALARM" (green dot).
    - Full-width button "(band icon) SET ALARM" or "✎ EDIT ALARM".
13. **MY JOURNAL ›** card (after Oct 2025):
    - A 7-day strip of weekday initials (M… T… FRI SAT SUN). Each day is a filled teal-green check circle (completed), an empty ring circle (not done), or a pill spanning consecutive days.
    - Grey button "💡 RECOVERY INSIGHTS" (Oct 2025), renamed "BEHAVIOR INSIGHTS" by Jul 2026 (r113).
    - May–Aug 2025 variant: a single row "(✓) MY JOURNAL" + a "✎ FILL OUT" / "EDIT" button (r20, 23).
14. **"My Plan"** title + plan card:
    - Collapsed: "BOOST FITNESS PLAN" / "0 days left" / "**100%** ACCOMPLISHED" + teal-green progress bar + chevron ⌄ (07, r03 "BUILD BETTER RECOVERY PLAN 51%").
    - Expanded (r114): goal rows with circular progress counters ("7,000+ Steps 5/7", "0:22+ HR Zones 4-5 Time 0:27", "Any Strength Training Activity 4/4", "Running 3/3") and a "VIEW MY PLAN" button.
    - Empty: "Build Your Best Self / Set goals, track progress, and turn small actions into long-term wins. / EXPLORE PLANS →" with an illustration of three dashed green rings holding moon / heart / lifter icons (r20, r113).
15. **"My Dashboard"** title + "CUSTOMIZE ✎". Once the big rings scroll off, the title greys out (`#BFC1C3`) under a sticky mini-ring bar. Dashboard items (customisable, reorderable):
    - **STRESS MONITOR** chart card: "Last updated 10:15 PM", level + value ("MEDIUM 1.1"), 24-h line chart 0–3.0, the line coloured on a teal (`#56C6D0`) → yellow gradient by level, a sleep band (steel blue) and activity bands with pictograms (moon, recliner, cyclists, walker) across the top, and a dashed now-line.
    - **Metric rows**: icon + LABEL + big value + trend triangle + baseline value beneath. Rows seen: DAY STRAIN 19.6 ▲ 14.0, SLEEP CONSISTENCY 56% ▼ 76%, RECOVERY 4% ▼ 53%, SLEEP NEEDED 10:34 ▲ 9:12, HEART RATE VARIABILITY 151 ▲ 122, RESTING HEART RATE 48 ▼ 54, STEPS 10,325 ▲ 7,466, HR ZONES 1-3 (WEEKLY) 5:30, HR ZONES 4-5 (WEEKLY) 0:10, VO₂ MAX 53, CALORIES 3,337.
    - Triangle colour shows whether the change is **good or bad**, not its direction: RHR ▼ is green, steps ▼ is orange, neutral is grey.
    - Rows with no data show "›" instead of a value (r03).
    - **STRAIN & RECOVERY** chart card (ⓘ): 7-day dual-axis chart. Left axis 0/7/14/21 in blue, right axis 0%/33%/66%/100% in red/yellow/green. The strain line and points are blue; recovery points are coloured by zone on a grey connecting line; the selected day ("Sun 14") is highlighted.
16. **"Discover More"** promo cards (Dec 2025+, r13): thumbnail left + title + description + blue CTA, e.g. "GO TO ADVANCED LABS →", "VIEW UPGRADE OPTIONS →", "GO TO SHOP →", "CHOOSE A GIFT →".
17. **Footer**: tier wordmark "WHOOP LIFE" / "WHOOP PEAK" (thin logotype).
18. **Floating tab bar + Coach button.**

**Sticky collapsed header** (05–07, r13, r111, r112): a row of three small rings (≈20 pt) with labels "SLEEP · RECOVERY · STRAIN" on the dark top gradient. In r114 (Aug 2026) the date/avatar row is also visible above the mini rings — **UNCONFIRMED** whether the whole header pins.

### 3.2 HOME — May–Sep 2025 variant (for reference)
Images: 80, r27, r28, r30, r31, r102, r103, r104, r141, 91, 94, r89, r20, 23 (Wareable).

Same top half as §3.1. Differences:
- Monitors directly under the rings (r104, 91).
- My Day row = [Ⓦ square button] + [sunrise icon "Daily Outlook" ›].
- No "+" next to My Day; the white circular FAB "+" floats above the bottom-right of the tab bar.
- Classic full-width tab bar with a hairline top border `#3C3F40`, background `#151A1F`. Active label white, inactive `#868889`.
- In the first days of May 2025 the bar read Home · Plan · Community · More (r31, r103, r141).

### 3.3 "+" Action menu (03, Oct 2025)
- Rounded popover (≈ 20 pt corners **UNCONFIRMED**), vertical gradient `#464D56` → `#32383D`, layered over a dimmed My Day.
- Items: thin grey line icons (`#A2A5A9`) + white bold uppercase labels, ≈ 17 pt, wide tracking: **START ACTIVITY** (stopwatch), **ADD ACTIVITY** (+), **STRENGTH TRAINER** (lifter), **COMPLETE YOUR JOURNAL** (notebook + pencil), **CREATE WHOOP LIVE** (camera).
- The "+" becomes an X in a `#2E3236` rounded square.

### 3.4 Customize Dashboard (04 Oct 2025, r110 Jun 2026 Android)
- Full-screen sheet with X and "CUSTOMIZE DASHBOARD" centred.
- Current widgets list: rows with a ≡ drag handle; a bar-chart glyph marks rows that render as charts (Stress Monitor, Strain & Recovery).
- Section "ADD TO MY DASHBOARD" with a hairline rule.
- Addable rows (icon + uppercase label + "+"): AVERAGE HEART RATE, CALORIES, HOURS OF SLEEP, HR ZONES 1-3 (WEEKLY), HR ZONES 4-5 (WEEKLY), HR ZONES ALL (WEEKLY), LEAN BODY MASS, RESPIRATORY RATE, DAY STRAIN, VO₂ MAX, SLEEP PERFORMANCE, STRESS MONITOR, STRAIN & RECOVERY, STRENGTH ACTIVITY TIME… Rows are `#2D3133`-ish rounded rectangles, 60 pt tall.
- Bottom button: iOS 2025 = outlined capsule "SAVE" with a light-blue border; Android 2026 = white filled capsule "SAVE".
- Complaints: no obvious way to remove a widget (r110); "Customize Dashboard to show charts for certain data?" (r112); "Adjust the Dashboard indicators to take into account time of day" (r111).

### 3.5 SLEEP detail (Wareable 21 May 2025, TGL 47–53, 10, r66 May 2026, 31 Tom's Guide, AP photo 4 May 2026, r144)
1. Nav: ‹ "TODAY" ⓘ.
2. Large ring, ≈ 60% of the width, steel blue: centred WHOOP wordmark, "97%" big, "SLEEP PERFORMANCE" two-line uppercase, and a tiny 3-segment indicator (grey-grey-green = Optimal).
3. A rounded card directly under the ring, with a small notch/pointer pointing up at it. Contributor rows (icon + uppercase label + 3-segment bar + value): HOURS VS. NEEDED 99%, SLEEP CONSISTENCY 87%, SLEEP EFFICIENCY 96%, HIGH SLEEP STRESS 0%. Each bar is three short dashes; the active segment is coloured (orange Poor / grey Sufficient / green Optimal).
4. Legend box (`#0D1012`): "– Poor  – Sufficient  – Optimal".
5. Coach card with gradient border: "Your Sleep Performance is optimal. You're getting enough sleep, maintaining strong consistency, and keeping stress in check. Keep up the great work!" CTA "LEARN MORE WITH WHOOP COACH →" (May 2025) → "EXPLORE YOUR SLEEP INSIGHTS →" (Oct 2025+).
6. "Last Night's Sleep" (≈ 20 pt semibold) + "EDIT ✎"; subtitle "Today vs. prior 30 days".
7. HOURS OF SLEEP card (ⓘ): "8:44 ▲" over "7:46", then a full-night HR line chart (y 30–110) with bed/wake icons and times at both ends.
8. "TYPICAL RANGE (hatched swatch) … TIME IN BED 8:48 / DURATION 7:05".
9. Stage rows, each a radio-circle + label + % + duration, with a bar over a hatched typical-range track. Colours sampled from TGL crop 50 (WebP, so approximate):
   - AWAKE 6% 0:34 (white/light grey);
   - LIGHT 53% 4:32 (lavender `#A6A3ED`);
   - SWS (DEEP) 24% 2:07 (pink `#ED9AF3`);
   - REM 17% 1:31 (purple `#A35DE6`).

   Choosing a radio highlights that stage across the hypnogram barcode and the HR chart (31).
10. "RESTORATIVE SLEEP 3:38 ▲ 3:15" (purple swatch `#A15DE4`).
11. Further cards in "Weekly Trends": SLEEP PERFORMANCE (7-day bars with % labels), HOURS VS. NEEDED (HOURS) (two-line chart, Hours of sleep vs Sleep needed in green), HOURS VS. NEEDED (%), SLEEP CONSISTENCY (bed/wake bars with "Optimal Bed/Waketime" dashed lines), SLEEP EFFICIENCY (ASLEEP/AWAKE barcode + "WAKE EVENTS 21"), TIME IN BED, plus sleep debt and restorative sleep.

TechGearLab counted "17 unique dashboards" on the sleep page. A Reddit post complained "The new Sleep Tab has 15 individual cards. 15!" (May 2025).

Stage colours come from a compressed review crop: treat them as **approximate** (±10 per channel).

### 3.6 RECOVERY detail (TechRadar 90, 11, TGL)
1. ‹ TODAY ⓘ.
2. Big ring in the zone colour with WHOOP wordmark, "75%" and "RECOVERY".
3. Contributor card under the ring (pointer notch):
   - HEART RATE VARIABILITY 63 ▲ / 56
   - RESTING HEART RATE 56 ▼ / 62
   - RESPIRATORY RATE 15.2 ▲(orange) / 14.7
   - SLEEP PERFORMANCE 81% ▲ / 74%
4. Legend row: "▲▼ Today vs. last 30 days".
5. Coach card: "Your HRV is 13% higher than usual. A high HRV indicates your nervous system is ready to handle stress, your body is in balance, and you are ready to take on strain." + "EXPLORE YOUR RECOVERY INSIGHTS →".
6. "RECOVERY INSIGHTS / See how your behaviors impact your recovery. ›" card with a bulb icon (11).

Rest of the page **UNCONFIRMED** (likely trends: HRV / RHR / recovery charts).

### 3.7 STRAIN detail (TechRadar 90, AP photo 2 May 2026, 08)
1. ‹ TODAY ⓘ.
2. Big blue ring: WHOOP wordmark, "13.2", "STRAIN". The ring shows the light-grey target band with a white tick.
3. Contributor card:
   - HEART RATE ZONES 1-3 1:09 ▲ / 0:07
   - HEART RATE ZONES 4-5 0:00 ● / 0:00
   - STRENGTH ACTIVITY TIME 0:48 ▲ / 0:03
   - STEPS 16,719 ▲ / 8,236
4. Legend: "▲▼ Fri., Aug. 15 vs. last 30 days".
5. Coach card: "Strain between 10 and 13.9 is considered moderate. Your cardiovascular load is significant but not strenuous." (Oct 2025: "Strain between 18 and 21 represents near maximal cardiovascular load. Dedicate additional time to rest and recovery. EXPLORE YOUR STRAIN INSIGHTS →").
6. "Today's Activities" list (≈ 26 pt title) with activity rows (08).

### 3.8 ACTIVITY detail (Wareable 23–26 May 2025, Digital Trends 92, r94, TGL 40, AP)
1. Nav: ‹ [sport pictogram] "RUNNING" / "14:49 to 15:59" … "•••" menu.
2. Headline stats: **15.4** ▲14.5 "ACTIVITY STRAIN" (blue) + **7,141** ▲6,954 "ACTIVITY STEPS".
3. Coach card: "Building aerobic capacity. You spent 26 minutes in HR Zone 4. This is 10 more minutes than you typically spend in this zone during Running." "LEARN MORE WITH WHOOP COACH →".
4. HR chart: blue line on a dark area with a gradient fill below, dashed start/end markers, time labels.
5. "TYPICAL RANGE … DURATION 0:43:39".
6. HR zone rows ZONE 5 → ZONE 0, each a dark card: "ZONE 4 167-180 BPM 62%" + time "0:26:29" (seconds in smaller text) + a horizontal bar on a hatched track, with a white marker for the typical amount. Zone colours (approximate, JPEG):
   - Z5 burnt orange `#CC734A`
   - Z4 light orange `#F8B36D`
   - Z3 green `#59B996`
   - Z2 blue `#57A2C5`
   - Z1 light steel `#B0BEC8`
   - Z0 white (r94)

   These were sampled from the Wareable composite 26 (downscaled JPEG, so approximate). Zone card background `#2A2F33`; hatched track `#363A3D`. Percent text uses each zone's colour.
   
   Note: "Zone ranges automatically updated on 03/05/2025. View HR Settings".
7. "KEY STATISTICS … VS. 30 DAY AVERAGE": horizontally scrolling tiles (AVG HR 159 bpm ▲155bpm, MAX HR 185 bpm ▲180bpm, DURATION, CALORIES 102 cals ▼143cals…).

**Strength Trainer activity** (23 middle):
- A muscle-group chip ("LOWER BACK BODY + CORE").
- "12.8 ▲12.0 ACTIVITY STRAIN" + a CARDIO 31% / MUSCULAR 69% split bar.
- Coach card; segmented "EXERCISES | HR ZONES"; HR chart with set markers.
- Exercise carousel ("Romanian Deadlift – Single Leg – R – Dumbbell, 3 Sets", "540 kg TONNAGE", "36 TOTAL REPS", page dots, "VIEW ALL →").

**Nap detail** (r79): "NAP 7:53 AM to 8:50 AM", "0:50 ▼1:13 HOURS OF SLEEP", "0:28 ▼0:45 RESTORATIVE SLEEP", coach card "This nap reduced your sleep need by 50 minutes. EXPLORE INSIGHTS →", HR chart.

Post-activity AI insight on Activity Details was announced in an official megathread. Its layout is **UNCONFIRMED** beyond the coach card.

### 3.9 SLEEP PLANNER (r136 Jun 2025 Android, r133 Oct 2025, r135 Jan 2026, r134 May 2026)
Reached from Tonight's Sleep › (and from bedtime reminders).
1. Nav: X (iOS) or ‹ (Android) · "SLEEP PLANNER ⓘ" · a circular calendar-moon icon at the right, with a small "OFF" chip below it.
2. Upper zone (lighter slate):
   - Circled W logo.
   - Centred headline ≈ 20 pt white, e.g. "Get to bed by 3:05 AM to help you reach your Weekly Plan sleep goals." / "Go to bed at 11:25 PM today to achieve a 77% Sleep Consistency tomorrow." / "Your alarm will go off at 5:00 AM. Get to bed by 5:54 PM to achieve 100% Sleep Need."
   - "TOMORROW I WANT TO" (small caps, grey) + an outlined white capsule selector: **REACH MY SLEEP NEED / IMPROVE MY SLEEP / REACH MY WEEKLY PLAN GOAL**.
3. Lower darker zone: big times "3:05AM — SUGGESTED TIME TO BED" (left) and "7:45AM — YOUR WAKE TIME" (right); "TIME IN BED" with a hatched horizontal bar between dotted drop lines; a capsule badge with the duration ("4:40") centred on the bar; an alarm pin marker at the wake end when the alarm is on; a dashed bracket below "OPTIMAL / RECOMMENDED 3:35 AM – 10:00 AM".
4. Bottom sheet card: band icon · "ALARM" · toggle (green when on). Two buttons: "ALARM SET TO / EXACT TIME | OFF" and "WAKE TIME SET TO / 7:45 AM".

Community complaints: absurd suggestions ("wind down at 4:30PM", "sleep at 6pm", "3am–7:45am"), "What gives on the sleep planner?", and after Aug 2026 "recommended bedtime no longer working properly".

### 3.10 STRESS MONITOR detail (Digital Trends 91 May 2025, AP 33 May 2026, r121 Feb 2026, 97)
1. ‹ "STRESS MONITOR" ⚙.
2. Date nav "‹ TODAY ›".
3. A 270° arc gauge running blue → teal → green → yellow → orange from 0.0 to 3.0, with a white needle and ⓘ. Big value "1.5", level word "MEDIUM" (green) / "LOW" (blue), timestamp.
4. 24-h line chart (0–3.0), the line coloured by level, sleep band (moon) shaded, activity markers on top, magnifier zoom button.
5. Explanation text ("Your RHR is elevated and HRV is lower than usual, resulting in a medium level of stress…") or a coach card.
6. "TOTAL DAY" card: "FRI, MAY 15 STRESS vs. TYPICAL FRIDAY". A stacked horizontal bar (blue LOW / green MEDIUM / orange HIGH) sits above a thinner "typical" bar. Then three columns "8:04 ▲50% LOW | 1:19 ▼70% MEDIUM | 0:09 ▲162% HIGH".

The Health-tab card version shows "TODAY'S HIGH STRESS 0:35 hrs" + a "▼ vs. typical Tue" chip + a sparkline.

### 3.11 HEALTH MONITOR detail (Stuff 82 Jun 2025, r105 May 2025, AP 33 May 2026, r95)
1. ‹ HEALTH MONITOR.
2. HEART RATE live header: blue heart, big "79" + "BPM", "Zone 0", a 5-segment zone indicator, and a live blue line chart with a dashed now-line and white end dot. (May 2025 variant: "LAST NIGHT" tab with a big circular "68 BPM" badge.)
3. 2-column tile grid (tiles ≈ 198 × 128 pt on 440 pt; `#32383D`; 12 pt gaps). Each tile: icon + label uppercase grey + big value + unit, and a chip below:
   - RESPIRATORY RATE 16.5 rpm [✓ within 16.5 - 16.9]
   - BLOOD OXYGEN (SPO₂) 95 % [✓ within 95% - 100%]
   - RHR 58 bpm [✓ within 50 - 58]
   - HRV 95 ms [! low < 95] (orange chip)
   - SKIN TEMP (FROM BASELINE) +0.2 °C [✓ within -0.6 to +0.5]
4. "⇪ SHARE YOUR HEALTH REPORT" row + caption "Printable report for sharing with your doctor, physician, trainer, or anyone of your choosing."

Calibrating state: "Calibrating…" under HR and a blue info banner "Your new strap is recalibrating skin temperature for greater accuracy and will update in 4 days" (r95).

### 3.12 HEALTH tab — Jun 2025 → early 2026 (Stuff 84/85, Digital Trends 92, r100, r91, r82f, r21, r81)
Title "HEALTH" (centred, small caps, no back button). Top to bottom:
1. HEART RATE live strip (as in §3.11, without a card).
2. **HEALTHSPAN ›** card: "PACE OF AGING 2.0x" + chip ("▲ faster vs. last week" orange / "• no change vs. last week" grey); a WHOOP-Age blob at the right ("20.2 WHOOP AGE", speckled 3-D blob); a row below: "2.8 Years Younger" in light blue (or "10.1 Years Older" in orange) "vs. Actual Age".
   - Locked state: "Keep wearing WHOOP consistently. Log 21 sleeps in a month to unlock Healthspan." with blurred content and "LIFE | PEAK" labels.
3. **HEALTH MONITOR ›** card: five columns RESP | SPO₂ | RHR | HRV | TEMP, each icon + label + a check tile (green ✓ or orange !), separated by thin vertical dividers. Footer row "✓ 5/5 metrics within range" or "! Heart Rate Variability low".
4. **BLOOD PRESSURE INSIGHTS** [BETA V1.0] ›: "TODAY'S READING 129/73" + a mini range chart.
5. **HEART SCREENER** — "TAKE AN ECG ›": "AFib not Detected" + green chip "In the last 24 hours"; a 3-D grey heart illustration; a two-cell row "✓ BACKGROUND SCREENING | ✓ ECG REPORT".
6. **STRESS MONITOR ›**: "TODAY'S HIGH STRESS 0:35 hrs" + "▼ vs. typical Tue" + a sparkline.
7. **ADVANCED LABS** (from Sep 2025): Optimal 53 / Sufficient 8 / Out of Range 4 chips + a segmented ring "65/65 BIOMARKERS" + "Last updated".
8. Disclaimer paragraph ("The Heart Screener features — ECG and IHRN — are medically regulated features. Healthspan, Health Monitor, Blood Pressure Insights, and Stress Monitor are not medical devices…").

**WHOOP One** members see only the Heart Rate strip + the disclaimer (r21), or "More to unlock" upsell cards (r81, r92).

### 3.13 HEALTH tab — 2026 redesign (r07 Jun 2026, r44 Aug 2026, AP photo 6 May 2026)
1. "HEALTH" title over a **large glowing WHOOP-Age sphere**, cropped as a half-planet at the top centre. It shows "WHOOP AGE" and "2.6 years younger" / "0.2 years older" in white on the sphere, with speckled particles.

   The sphere and the page-top glow change colour:
   - green (younger)
   - teal / cyan (around zero)
   - **amber / gold** (r44)

   The background above the cards is near-black (`#090909`) so the glow shows.
2. Dismissible info banner (blue-tinted translucent card, hourglass icon, X): "Your Healthspan is calibrating, so fluctuations in your WHOOP Age are normal. As WHOOP collects more data, it will stabilize."
3. **PACE OF AGING** card (tinted by the glow, e.g. `#322615` under amber):
   - chip "▼ slower vs. last week" (green) / "• no change vs. last week";
   - "● Slow … 1.2x … Fast ◐";
   - a dense **tick-ruler** scale −1.0x … 1.0x … 3.0x with a white marker line;
   - full-width grey button "GO TO HEALTHSPAN".
4. **ADVANCED LABS ›** card: left column chips "✓ Optimal 33", "● Sufficient 10", "! Out of Range 2", "Last updated: Jun 30, 2026"; right a segmented radial ring (green / teal / orange tick segments) "45 BIOMARKERS ›".
   - Not yet tested: a promo variant "Get deeper health insights, adding your lab results from doctor visits with your 24/7 WHOOP data. GET STARTED →" with a test-tube-in-ring illustration on a teal gradient.
5. **HEALTH MONITOR ›** card (as before).
6. Further cards (BP, Heart Screener, Stress Monitor) presumably follow — **UNCONFIRMED**, not visible in 2026 captures.

Floating glass tab bar with **Health** active, plus the coach button.

### 3.14 HEALTHSPAN detail (Wareable 20 May 2025 / 29 Aug 2025, r90, r119, r120, 61, r91)
1. ‹ "HEALTHSPAN" / "NEXT UPDATE IN 6 DAYS" ⓘ; week nav "‹ AUG 3 - AUG 9 ›".
2. A huge speckled blob (green / teal / gold) with "22.0" (≈ 34 pt bold) "WHOOP AGE" "8.3 years younger" (green) / "15.9 years older" (orange). First run: "You're Trending Younger … DONE" white button.
3. PACE OF AGING ruler (−1.0x / 1.0x / 3.0x, "Slow" / "Fast" ends, value "0.1x").
4. Summary card with an upward pointer: "Good Progress / Steady And Healthy / On Your Way There / Small Steps, Big Impact" + body + CTA "VIEW YOUR WHOOP COACH ANALYSIS →" / "EXPLORE YOUR WEEKLY INSIGHTS →". Optional blue info card "WHOOP Age Is Calibrating" with X.
5. Collapsed sticky header: a small blob in the centre with "8.3 YEARS YOUNGER" (left) and "0.1x PACE OF AGING" (right).
6. Category sections — **Sleep / Strain / Fitness** — with a legend "▼ 6 Month avg. ▲ 30 Day avg.". Expandable rows (⌄), each with a coloured range bar (orange → grey → green segments, numeric ends such as 15 / 70, 40bpm / 80bpm, 60% / 90%), markers for the 6-month (▼) and 30-day (▲) values, and the impact in years at the right ("-2.8 years", "0.0 years"). Rows: SLEEP CONSISTENCY, HOURS OF SLEEP, TIME IN HR ZONES 1-3 (WEEKLY), TIME IN HR ZONES 4-5 (WEEKLY), STRENGTH ACTIVITY TIME, STEPS, VO₂ MAX, RHR, LEAN BODY MASS. Expanded: "Outperforming / Your daily Sleep Consistency is looking good… VIEW TREND →".
7. "Trend View": WHOOP AGE TREND chart (Your WHOOP Age vs Chronological Age lines).

### 3.15 BLOOD PRESSURE INSIGHTS (13 Jul 2025, Stuff 86 Jun 2025)
1. ‹ "BLOOD PRESSURE INSIGHTS"; "BETA V1.0 ⓘ" chip.
2. A 270° gauge: green (`#00F09E`) → yellow (`#FEEA61`) → orange (`#FEA522`) segments with faded tails, a white needle. Inside: "MON, JUN 16" / "TODAY'S ESTIMATE", "156/88" (≈ 34 pt), "SYSTOLIC 146-166 mmHg" | "DIASTOLIC 83-93 mmHg".
3. Segmented control W | M (selected `#2E3236`) + "‹ JUN 11 - JUN 17, 25 ›".
4. Legend "— MANUAL READING  ▬ WHOOP ESTIMATE".
5. A range chart between a "Highest" (orange) and a "Lowest" (green) guide line. Grey vertical range bars per day carry yellow/orange estimate dashes; the selected day is bright orange with a dashed now-line.
6. "+ ADD MANUAL READING" full-width row.

### 3.16 HEART SCREENER / ECG (AP 34 May 2026, 95 ECG details, 27 recording photo, Stuff 85)
- **Heart Screener page**:
  - "Electrocardiogram (ECG) ⓘ" + a purple-tinted row "+ TAKE A NEW ECG READING";
  - last reading card "✓ Normal Sinus Rhythm / 5 days ago ›" with a purple trace and four check rows (AFib not detected; High Heart Rate not detected; Low Heart Rate not detected; Normal Sinus Rhythm detected);
  - "ALL ECG REPORTS ›";
  - section "Irregular Heart Rhythm Notifications ⓘ" + text + "✓ AFIB NOT DETECTED / Never detected on WHOOP" + "DETECTION HISTORY ›".
- **ECG DETAILS** (95): X · "ECG DETAILS" · ⓘ; timestamp "Aug 2, 2025 7:45:14 p.m. - 7:45:43 p.m."; grid chart with a **purple trace** (sampled `#AC59F0`) and 0s/1s labels; "Normal Sinus Rhythm" (≈ 22 pt) + four green check rows; a paragraph of explanation.
- **Recording** (27 photo): black screen, purple live trace, big "23 sec" countdown, "ECG reading in progress", a purple progress bar, an outlined "CANCEL" capsule.

### 3.17 ADVANCED LABS (Wareable 22, r82a–g Sep 2025, AP 34 May 2026, r44)
- **LAB RESULTS / TEST RESULTS**: a segmented radial ring (dozens of rounded tick segments coloured green / teal / orange / grey) around "65/65 BIOMARKERS" or "60 BIOMARKERS TESTED"; counts "48 ✓Optimal | 5 ✓Sufficient | 7 !Out of Range" with chips; a coach card ("Most of your biomarkers are looking good, but you have several out of range biomarkers in the Cardiovascular Health category. LEARN MORE →"); search field "Search for Vitamin D, Cortisol, etc."; "Out of Range — 4 Biomarkers" list cards (name ›, big value + unit, "! Out of Range" chip, a range bar with a ▼ marker).
- **CLINICAL REPORT**: "Your report was updated on Sep 21, 2025…"; INSIGHTS card "Reviewed by <MD>" + a list of insight titles with status squares + "OPEN KEY INSIGHTS".
- **ACTION PLAN** card: "Made for <name>" + checklist rows with "+" + "OPEN ACTION PLAN".
- **INSIGHTS** article page: long-form text, "DIVE DEEPER INTO THIS INSIGHT".
- Waitlist / upload state (AP 34): teal gradient header, "Add Lab Results" card with a white "UPLOAD RESULTS" button, "You're on the waitlist", "Everything You Unlock with Advanced Labs".

### 3.18 COACH chat (08–12, 88, r08, r19, r64, r98, r99, r101, r123, 32, 66–68, 28)
- Presented as a **bottom sheet** (grabber, rounded top) over Home, or full screen.
- Top bar:
  - left: a W-in-ring avatar pill with a version — "Beta v2.5" (May 2025), "BETA V3.0/V3.1" (Jun–Aug 2025), "Beta v5.0" (Oct 2025), "BETA V5.2" (Feb–Apr 2026), "Beta v5.3" (May 2026), "v6.0" (Oct 2026);
  - right: a history clock icon, plus a "Memory" lightbulb in v6.0.
- Background: dark with a subtle purple/indigo glow at the top. Assistant messages are plain text with bold numbers, bullet lists and emoji headings ("🌙 Tonight's Focus"); user messages are dark grey bubbles aligned right.
- Under each answer: copy / 👍 / 👎 icons. Suggested-prompt rows with ↑ arrows (2025) or pill chips (2026).
- Input: "Ask WHOOP anything" / "Ask a question …" field with a **purple→blue gradient border**, a mic icon (2026), a "+" or new-chat icon at the left, and a ↓ scroll-to-bottom bubble.
- In-chat rich cards: SLEEP RECOMMENDATION card (bedtime / wake time panels, "TOMORROW'S PREDICTED SCORES 8:25 hr HOURS OF SLEEP / 77% CONSISTENCY", "✎ EDIT SCHEDULE", gradient border); workout suggestion carousel ("Running, Duration 50 min, Estimated Strain 13.6, Intensity Level Low/Medium/High bar, COMMIT, GENERATE ALTERNATIVES").
- **Daily Outlook page** (88): title "DAILY OUTLOOK" + "BETA V3.0" pill on a tan → slate gradient; greeting "Hi Connor, Happy Tuesday!…" with weather, then "Key Insights" bullets and "Activity Recommendations".
- **Coach memory** promo card: "Introducing Coach Memory … TRY IT NOW →" (12).

### 3.19 TREND VIEW (Stuff 83 VO₂, r23 HRV, r14 HRV 6M, r80 Resp 6M, r144 Sleep Performance M)
1. ‹ "TREND VIEW".
2. Metric dropdown card (icon + "VO₂ MAX" ⌄).
3. "AVERAGE" + "52 mL/kg/min" (big), a % chip ("▲ 33% past week" green / "▼ 5% vs. prior 6 months" orange), a segmented control W | M | 6M, and "‹ MAY 19 - JUN 17, 25 ›".
4. Explanation sentence or coach card ("EXPLORE WHY →").
5. Chart: line + points with value labels (week/month), or bars with an "AVG." dashed line and label. In 6M the chart groups by month with per-month average segments and % change labels.
6. Typical-range band for HRV.
7. Extra cards: "Complete a 15+ minute GPS-tracked run…" info row; "YOUR CARDIO FITNESS LEVEL ⓘ"; "SLEEP BREAKDOWN (DAYS)" stacked bar "12x OPTIMAL (>85%) / 16x SUFFICIENT (70-85%)"; "LEARN MORE … VIEW ALL →" article/video cards.

Complaint: no 1-year view (r80).

### 3.20 PROFILE / ACHIEVEMENTS / STREAK (r73 Mar 2026, r74 Jan 2026, 97 Sep 2025, r40 + r140 Oct 2026, r48)
- **PROFILE**: ‹ "PROFILE" + tier chip ("PEAK" / "LIFE").
  - Top cards: "LEVEL 24 / 1724 Recoveries" (laurel medal) and "WHOOP AGE 32.1 / 7.7 years younger" (blob); "DAY STREAK … 💧0 Days ›".
  - "Data Highlights" with a 1M | 3M | ALL TIME segmented control: three mini rings Best Sleep 88% / Peak Recovery 95% / Max Strain 20.6.
  - STREAKS: 11 Days 70%+ Sleep, 5 Days Green Recovery, 4 Days 10+ Strain (circular icons).
  - NOTABLE STATS rows with gold-outline icons: Lowest RHR 39 bpm, Highest RHR, Lowest HRV, Highest HRV, Max Heart Rate 189 bpm, Longest Sleep 8:15 hr, Lowest Recovery 17%.
  - "Activity Summary" (1M | 3M | ALL TIME; "103x TOTAL ACTIVITIES"; per-sport rows "YOGA 11.9 … 60x" with blue bars; "SHOW LESS"); "Referrals".
  - **Achievements (28)** carousel with "VIEW ALL →" (r140): 3-D badges with big counts (1050, 250, 10, 400), names (Green Monster, Ring Ruler, Green Week, Strain Seeker), "▲ Top 0.2%".
- **ACHIEVEMENTS page** (r40): sections SLEEP / RECOVERY / STRAIN (grey small caps + hairline). A grid of badge shapes:
  - hexagon = sleep, shield = recovery, diamond = strain;
  - unlocked: metallic texture + count + date ("Sleep Specialist 50, Jul 18, 2026", "Green Monster 150", "1% Club 2" red, "Strain Seeker 50" blue);
  - locked: black with a padlock and "0" (Human Metronome, Pillow Perfect, Green Week, Peak Day, All Out Day).
- **DAY STREAK page** (r48): ‹ "DAY STREAK" ⓘ; a huge blue flame + "1607"; "Day Streak / Wear your WHOOP daily"; stats "Feb. 5, 2022 Streak started | Top 2% WHOOP | 1607 Max streak"; "THIS WEEK" with day flames; milestone progress "393 more days to unlock your next milestone" (1000 → 2000 badges).

### 3.21 MORE tab (r05 Jul 2026, r76, r92, r13)
- Hero carousel with page dots (photo card "EXTEND MEMBERSHIP / Save up to 16% per month…" ›).
- "FIRST WEEK WITH WHOOP" card (black, gradient border).
- "REFER & EARN": "GET ONE MONTH FREE" (iridescent card) and "SHARE A FREE TRIAL" (outlined card).
- "SHOP & GIFT" horizontal product cards (Wireless PowerPack, 5.0 SportFlex Band…).
- Settings and device entries below — **UNCONFIRMED** (not captured).
- The More icon shows a small gift badge when promos exist (r13).
- Reviewers and users: "'More' tab is there to also upsell you" (Reddit "90 Day Review").

### 3.22 MEMBERSHIP & BILLING (r10 Mar 2026), DEVICE SETTINGS (r01 Oct 2026, r75)
- **Membership**: "Your Membership" card ("WHOOP PEAK" logotype + initials avatar; RENEWAL ₹23,990/yr | BILLED Annually "You're saving 33%" | NEXT RENEWAL 04-May-2027). "Membership Options" rows: MANAGE MEMBERSHIP, CREATE FAMILY PLAN, SWITCH BILLING PLAN. "Available Upgrade" hero (MG photo, "WHOOP LIFE").
- **Device Settings**: X · "DEVICE SETTINGS" · ⓘ; "CONNECTED TO" (green) "WHOOP <serial>"; "CATCHING UP / Oct 1, 7:17 PM" with a cloud-upload icon; tabs STATUS | ADVANCED; a large 3-D band render; battery "58 % WHOOP MG" with a vertical green level bar; bottom card "♥ BROADCAST HEART RATE / TO COMPATIBLE APPS & DEVICES" + toggle.

### 3.23 Other surfaces
- **Journal** (Stuff 89, TGL 56–60):
  - X · "JOURNAL" · ✎; "‹ TODAY ›" + an "INSIGHTS" pill; "What's happening today, June 19?"; DAYTIME / NIGHTTIME sections.
  - Question rows with a pair of square toggles [✕][✓]: the selected ✓ is light blue `#67AEE6` with a dark check; the selected ✕ is white; unselected is translucent.
  - Follow-ups: steppers (– 5 +), value pills ("-- Minutes", "15 Minutes"), time sliders with a white knob.
  - White full-width "SAVE JOURNAL" capsule.
- **Menstrual Cycle Insights** (30, Tom's Guide):
  - purple gradient header; "Cycle Day 28  Luteal Phase"; calendar with phase-coloured pills (Menstrual red, Follicular lavender, Ovulatory teal, Luteal purple) and dashed predicted days;
  - "LOG PERIOD DATA +"; "LUTEAL PHASE GUIDANCE" with an M/F/O/L phase chart;
  - "SLEEP EFFICIENCY / STRAIN TOLERANCE / STRESS TOLERANCE ! low";
  - "Current Cycle" chips (SKIN TEMP / RHR / HRV / RECOVERY).
- **Strength Trainer** (TGL 43–45, 28):
  - X · "STRENGTH TRAINER" · ⓘ; tabs PROGRESS / MY WORKOUTS / WHOOP WORKOUTS; workout cards with photos and NOVICE/ADVANCED chips;
  - workout page "Bodyweight Strength Endurance / By WHOOP / 35 min EST DURATION, 8 EXERCISES, 24 TOTAL SETS";
  - set logging (REPS / WEIGHT (lbs) fields); "Generate with WHOOP AI" card; "Exercise Trends Coming Soon".
- **Edit Weekly Plan** (r11): "Edit your Weekly Plan"; CURRENT PLAN; CHOOSE A PLAN cards with tinted gradients (Boost Fitness orange, Feel Better green, Sleep Deeper blue-grey); CUSTOM "Custom Plan".
- **Activity picker** (AP photo 7): a search field, tabs ALL / STRAIN / RECOVERY / SLEEP, "MOST RECENT", "ALL A-Z" alphabetical list with white pictograms (Acupuncture, Air Compression, American Football, Archery, Assault Bike…).
- **Landscape HR / tilt mode** (r132):
  - X "HEART RATE" · "‹ TODAY ›" · "Data synced to 07:44";
  - a moon band "7:29" over the sleep period;
  - vertical dashed markers labelled "RECOVERY 65%" (yellow) and "STRAIN 4.2" (blue);
  - steel-blue HR line for sleep, grey after; y 40–200; ⊕ zoom.
- **Errors**: "LOOKS LIKE THE SERVER IS TAKING A QUICK NAP / Server connection failed. / Wait a few moments, then try reloading." + outlined "RELOAD" capsule + "CHECK STATUS →" + a 3-D "Zz" illustration (r16). Toast "Failed to load. Please try again." (r67).
- **Onboarding / new user Home**: a "Get Started" section with cards "Ready to get moving? … START ACTIVITY →" (gradient border, shoe-on-bike illustration) and "Unlock New Potential … EXPLORE APP INTEGRATIONS →" (r06). "Wake up your WHOOP / Slide on the charger…" (r76).
- **Membership expired sheet** (r77): "REJOIN WHOOP / No one on WHOOP is quite like you"; stats 20.7 PEAK DAY STRAIN, 9:35 LONGEST HOURS OF SLEEP, 561 NUMBER OF ACTIVITIES; iridescent "CHECK OUT NEW DEVICES" button; "EXPLORE OPTIONS →".
- **Widgets / Live Activity**:
  - large widget: WHOOP logotype, battery, 45% RECOVERY (yellow), 5.2 STRAIN (blue), 84% SLEEP (steel) — r24;
  - medium widget: the classic **dual ring** (recovery inner, strain outer, W centre) with HRV and Calories (r26, r29). Users noted "Old 'rings' UI is still available as a widget";
  - Lock-screen Live Activity: elapsed time, W logo, ♥ bpm, a Zone 1–5 coloured bar, distance, pace (14, 2024);
  - Dynamic Island: ♥ "--" + elapsed time "1:34:48" (r04).
- **Push notifications** (r115): "Recovery climbed overnight", "Soccer impact on recovery", "A dip in recovery" — short AI copy with emoji. Android: "Green means go — Your Recovery is green, indicating peak readiness…" (65). iOS system nag: "Open WHOOP — Keep the WHOOP app running so your data can stay up to date." (r152).
- **Strava / share graphic** (r151, auto-posted to Strava): dark panel with a sleep band (moon, "6:31"), a green dashed "76% RECOVERY" divider, an activity pictogram on a blue line, big blue "12.6 STRAIN", "928 CALORIES", "158 MAX HR", and a steel-blue → blue HR trace. A user asked how to see this view inside the app; there was no answer that it exists in-app.

---------------------------------------------------------------------------------------------------

## 4. Every metric and label seen (for the metric comparison)

- **Core scores**: Sleep (Sleep Performance %), Recovery %, Strain (0–21; Day Strain, Activity Strain), target / optimal strain range, sleep need.
- **Sleep**:
  - Hours vs. Needed (%), Sleep Consistency %, Sleep Efficiency %, High Sleep Stress %;
  - Hours of Sleep, Time in Bed, Restorative Sleep, Awake / Light / SWS (Deep) / REM (time and %), Wake Events, Sleep Debt;
  - Sleep Needed, Recommended Bedtime, wake time / alarm (exact / latest), predicted Hours of Sleep and Consistency (planner).
- **Recovery**: HRV (ms), RHR (bpm), Respiratory Rate (rpm), Sleep Performance; "vs. last 30 days".
- **Strain contributors**: HR Zones 1-3, HR Zones 4-5 (day and weekly), Strength Activity Time, Steps, Calories, Cardio vs Muscular %, tonnage, total reps.
- **Activity**: duration, avg HR, max HR, HR zone 0–5 time and %, steps, distance / pace (GPS), calories.
- **Health Monitor**: live HR + zone, Respiratory Rate, SpO₂ %, RHR, HRV, Skin Temp (from baseline, °C/°F), within-range intervals.
- **Stress Monitor**: score 0–3 (Low / Medium / High), today's high-stress hours, Low / Medium / High durations vs. typical weekday.
- **Healthspan**: WHOOP Age, years younger/older vs actual age, Pace of Aging (−1x to 3x). Contributors: Sleep Consistency, Hours of Sleep, Time in HR Zones 1-3 and 4-5 (weekly), Strength Activity Time, Steps, VO₂ Max, RHR, Lean Body Mass.
- **Fitness**: VO₂ Max (mL/kg/min, WHOOP estimate vs manual entry, cardio fitness level), Lean Body Mass.
- **MG / Life**: Blood Pressure estimate (sys/dia ranges, manual readings), ECG (Normal Sinus Rhythm, AFib, high/low HR), IHRN.
- **Labs**: biomarker counts (Optimal / Sufficient / Out of Range), individual biomarker values.
- **Other**: day streak; level / recoveries count; achievements; notable stats (lowest/highest RHR and HRV, max HR, longest sleep, lowest recovery, best sleep, peak recovery, max strain); journal behaviours; plan goal progress; menstrual cycle phase and day.
- **Device**: battery % (strap), connection / sync status, firmware.

---------------------------------------------------------------------------------------------------

## 5. Reviewer and community verdicts on layout and readability

### Praise
- the5krunner (Oct 2025 review, updated 2026):
  - "It's now excellent in most respects, and key, glanceable information is on the main screen."
  - "you will use the HOME one 95% of the time"
  - "looks good, is mostly bug-free, and presents information in a modern, insightful way… a considerably better experience than Strava or Garmin Connect."
- DC Rainmaker (Sep 2025): "their app is excellent at surfacing information in easy-to-understand ways." The "wear and forget" auto-detection is fundamental.
- Wareable (May 2025): app "very easy to navigate… redesigned… additional Health tab"; "noticeably zippier"; sync delays of 30–60 s gone.
- TechGearLab: "one of the most intuitive and detailed apps… presentation of data, interlaced with tips and coaching, is fantastic"; liked the explanations of terms and the learning videos.
- Android Police (May 2026): "Well-designed app has lots of data"; "glanceable"; "good at explaining why recovery is high or low".
- Reddit: "New UI is their best yet!… Much easier to find all my metrics" (May 2025); "Pleasing UI design" (May 2026); "I love the whoop app ui" (Aug 2026); "Lowkey is one of the best app features" on the new Achievements (Oct 2026).

### Complaints (design-relevant)
- **Density / overwhelm.**
  - the5krunner: "the information and features are densely presented… it takes time to discover all of its nuances, nooks, and crannies."
  - Tom's Guide (Jun 2026): "incredibly granular… unless you really know what you're looking for… it can be pretty overwhelming."
  - Android Police: "Casual exercisers may be overwhelmed."
  - Reddit: "The new Sleep Tab has 15 individual cards. 15!"
- **Clutter and ugliness.**
  - "The Whoop app is really ugly, it's cluttered, and nothing stands out… take a cue from Bevel… fully customize the home screen… all that advertising at the bottom of the page is just clutter… Who cares about the sleep section? You set it once" (Sep 2026).
  - "UI/UX designers worst nightmare" (Jul 2026).
  - "feel really lost in the UI all the time… team page… so buried" (Apr 2026).
  - "Bevel is now winning" (Oct 2026); "Please… support light mode!!" (Jun 2026).
- **Ads and upsells everywhere.**
  - Promo cards on Home ("How long will this take up the majority of my screen?", "Does the home screen have a no ads version?", "Can I remove the AL square from my home tab?").
  - "Too much marketing… you see it on every tab. Perhaps all marketing should be in the 'more' tab".
  - The non-dismissible "CARD EXPIRED" banner ("very greedy"); the app jumping to an extend-membership page ("Greed").
  - Health tab upgrade modals (fixed with a dismiss X, May 2025).
- **Navigation changes.**
  - Oct 2025 re-layout: "dreadful… feels cluttered"; the "+" moved and the Coach took its old place ("subversive design changes").
  - Apr 2026: My Plan moved above My Day ("way more cluttered").
  - "Most of the app is dead space… 4 tabs… condense it down to two or three tabs"; "a trends view tab should replace the community tab" (Jul 2025).
  - Truncated "Commu…" tab label (visible in 02/05–07).
  - Jul and Oct 2026: the app opens on the **Community** tab instead of Home ("Being Driven Mad By The New App Default"; "Whoop App keeps opening on Community Tab"). The in-app coach reportedly said Home can no longer be set as the default. Users asked for Home to stay the default.
- **Discoverability.**
  - Tilt mode, Trend View, Recovery/behaviour insights ("press recovery, scroll down to recovery insights"), where to remove dashboard items, where the alarm lives (TechGearLab: "We struggled to remember where in the app to adjust this alarm, as it's not intuitive").
  - No current HR on Home ("How to see current heart rate?").
  - 5.0 onboarding "too minimal".
- **Coach and AI.** "AI has taken a turn for the worst", hallucinations, Day in Review "just a bunch of text", requests to opt out of AI.
- **Feature gaps.** Year view in Trend View; dashboard charts; time-of-day-aware dashboard indicators; desktop/web experience; Strength Trainer UX ("clunky form", keyboard covers buttons); offline use.

---------------------------------------------------------------------------------------------------

## 6. UNCONFIRMED / gaps

- Font families; exact sizes beyond the measured cap heights.
- Exact corner radii of popovers and sheets; blur amount of the floating tab bar (it looks like translucent "glass" over the gradient).
- Rules for:
  - streak-flame colour thresholds;
  - Healthspan sphere/blob colour mapping (observed: green = years younger, teal = near zero, gold/amber = years older);
  - orange vs red "OUT OF RANGE" (seen orange at 2/5 and red at 2/5 and 3/5; probably severity).
- Lower part of the 2026 Health tab (BP / Heart Screener / Stress cards after Health Monitor), and the Community tab (no 2025–26 screenshot found).
- Full Recovery-detail page below the coach card, and Strain-detail trends.
- More tab below SHOP & GIFT (settings list).
- Light mode: none observed. Users request it in Jun 2026, so the app is dark-only.
- Whether the header row (avatar / date / battery) stays pinned with the mini-ring bar.
- The Verge's review ("Whoop MG review: a big whoop for a small crowd", 3 Jul 2025) could not be read: the site blocks automated access. No Android Central review exists, only news. DC Rainmaker has published no full 5.0 review, only a backlog note plus comparison comments.

---------------------------------------------------------------------------------------------------

## 7. Sources

### Reviews and articles
- the5krunner — WHOOP 5.0 / MG review (31 Oct 2025, updated 2026): https://the5krunner.com/2025/10/31/2026-whoop-5-0-mg-review-discount-accuracy-strain-recovery-athletes/
- the5krunner — "Whoop Homescreen Gets a Revamp" (15 Oct 2025): https://the5krunner.com/2025/10/15/whoop-homescreen-gets-a-revamp/
- Wareable — Whoop 5.0 review: https://www.wareable.com/wearable-tech/whoop-5-review
- Wareable — Strength Trainer update (Feb 2026): https://www.wareable.com/fitness-trackers/whoop-coach-ai-strength-trainer-workout-builder-update
- Wareable — summer 2025 features: https://www.wareable.com/wearable-tech/whoop-summer-features-rollout-update-healthspan-advanced-labs
- Stuff — Whoop MG review (Jun 2025): https://www.stuff.tv/review/whoop-mg-review/
- Tom's Guide — Whoop 5.0 review: https://www.tomsguide.com/wellness/fitness-trackers/whoop-5-0-review-should-you-give-a-whoop-about-this-new-tracker
- Tom's Guide — Fitbit Air vs Whoop (Jun 2026): https://www.tomsguide.com/wellness/fitness-trackers/i-tested-fitbit-air-vs-whoop-side-by-side-heres-the-screenless-fitness-tracker-id-buy
- Tom's Guide — Apple Watch vs Whoop MG sleep: https://www.tomsguide.com/wellness/sleep-tech/apple-watch-vs-whoop-mg-sleep-tracker-comparison
- TechRadar — Whoop MG review: https://www.techradar.com/health-fitness/fitness-trackers/whoop-mg-review
- Digital Trends — Whoop 5.0 review: https://www.digitaltrends.com/wearables/whoop-5-0-review/
- TechGearLab — Whoop 5.0 review: https://www.techgearlab.com/reviews/health-fitness/fitness-tracker/whoop-5-0
- Android Police — Whoop MG review (17 May 2026): https://www.androidpolice.com/whoop-5-mg-review/
- TechBuzz Ireland — Whoop 5.0 MG review: https://techbuzzireland.com/2025/09/29/whoop-5-0-mg-review/
- DC Rainmaker — 2025 backlog: https://www.dcrainmaker.com/2025/12/backlog-product-reviews.html
- DC Rainmaker — Polar Loop first thoughts (Whoop app quote): https://www.dcrainmaker.com/2025/09/polar-loop-first-thoughts-actually-competitor.html

### Reddit (r/whoop)
Each image filename `rNN-YYYY-MM-DD-…` carries the post date. Post permalinks are listed in §9. The data was collected through public search RSS: `https://www.reddit.com/r/whoop/search.rss?q=…`.

---------------------------------------------------------------------------------------------------

## 8. Image index (`images/reviews/`)

### the5krunner
| File | What it shows |
|---|---|
| 01 | Old home (pre-Oct 2025, near-black capture anomaly) |
| 02 | NEW home, Oct 2025 (best measurement source) |
| 03 | "+" action menu |
| 04 | Customize dashboard |
| 05–07 | Home scrolled (stress chart, Day Strain, Strain & Recovery, Sleep Consistency / Recovery / Sleep Needed, My Journal, My Plan, WHOOP LIFE footer) |
| 08 | Coach strain insight + Today's Activities |
| 09 | Coach sheet over My Day |
| 10 | Sleep contributors + coach card |
| 11 | Recovery coach card + Recovery Insights |
| 12 | Coach Memory card |
| 13 | BP insights (M view) |
| 14 | Live Activity lock screen (2024) |
| 15 | Tier table |

### Wareable, Tom's Guide, Android Police
| File | What it shows |
|---|---|
| 20 | Healthspan intro / detail / coach |
| 21 | Sleep detail / weekly trends / coach |
| 22 | Advanced Labs results |
| 23 | Home May 2025 / Strength Trainer activity / Running activity |
| 24–26 | Activity HR zones (WHOOP on the right of each composite) |
| 27 | ECG recording photo |
| 28 | Strength Trainer 2026 |
| 29 | Healthspan Aug 2025 |
| 30 | Tom's Guide: Menstrual Cycle Insights |
| 31 | Tom's Guide: sleep stages (2026) |
| 32–34 | Android Police May 2026: coach v5.3, health monitor, stress monitor, heart screener, Advanced Labs |
| 35-* | Android Police photos: home, strain detail, sleep detail, Health tab 2026, activity picker |

### TechGearLab (40–69)
| File | What it shows |
|---|---|
| 43–45 | Strength Trainer |
| 47–53 | Sleep crops |
| 55 | Health monitor photo |
| 56–60 | Journal |
| 61–62 | Healthspan and Health Monitor cards |
| 65 | Android notification |
| 66–68 | Coach |
| 69 | Rings + Strain Target card |

### Stuff (Jun 2025)
| File | What it shows |
|---|---|
| 80 | Home |
| 81 | Dashboard |
| 82 | Health Monitor |
| 83 | VO₂ trend |
| 84 | Health tab |
| 85 | Heart screener / stress |
| 86 | BP |
| 88 | Daily Outlook |
| 89 | Journal |

### Other reviews
| File | What it shows |
|---|---|
| 90 | TechRadar: Sleep / Recovery / Strain detail tops |
| 91–92 | Digital Trends: home, stress, health monitor, dashboard, Health tab, walking activity |
| 94 | Digital Trends: photo, off-body banner |
| 95 | ECG details |
| 97 | TechBuzz: profile / activity summary / dashboard / steps trend / stress |

### Reddit (2026)
| File | What it shows |
|---|---|
| r01 | Device Settings, Oct 2026 |
| r02 | Card Expired home |
| r03 | Empty home |
| r04 | Dynamic Island |
| r05 | More tab |
| r06 | Get Started home |
| r07 | Health tab 2026 |
| r08 | Coach v5.2 |
| r10 | Membership |
| r11 | Edit plan |
| r12 | Notifications error, calibrating |
| r40 / r140 | Achievements |
| r41–r46 | Home variants (green / red / sick) |
| r47 | Spanish "Descubre más" |
| r48 | Day streak |
| r50–r59 | Home variants (alarm on / exact time, activities) |
| r57 | Pre-added activity |
| r58 | Sleep Recommendation card |
| r62a | Key stats tiles |
| r63, r69–r71 | Home and 1% Club |
| r64 | Coach |
| r66 | Sleep detail 2026 |
| r67 | Friends search |
| r68 | My Plan above My Day |
| r72 | AI v5.3 notes |
| r73–r74 | Profile |
| r75 | Device settings with floating coach button |
| r110 | Customize dashboard (Android) |
| r111–r112 | Dashboard |
| r113 | Behavior Insights + plan empty state |
| r114 | Plan expanded |
| r115 | Notifications |
| r116 | Firmware banner |
| r119–r121 | Healthspan / stress |
| r122 | Home |
| r123 | Coach v6.0 |
| r130 | Coach-at-your-fingertips home |
| r132 | Tilt mode |
| r133–r136 | Sleep planner |
| r143 | 1% Club card / red out-of-range |
| r151 | Strava share graphic (Nov 2025) |
| r152 | "Keep the WHOOP app running" notification |

### Reddit (2025)
| File | What it shows |
|---|---|
| r13 | Discover More |
| r14 | HRV 6M trend |
| r15 | Advanced Labs Unlocked home card |
| r16 | Server error |
| r18 | LEGACY pre-2025 Mobbin |
| r19 | Coach |
| r20 | Home Aug 2025 (journal fill-out, plan empty) |
| r21 | Health tab ONE |
| r22 | Landscape bug |
| r23 | HRV trend |
| r24, r26, r29 | Widgets |
| r25 | Android dashboard |
| r27, r28, r30, r31 | Home May 2025 |
| r32 | TRANSITIONAL tabs |
| r76 | Wake up your WHOOP |
| r77 | Rejoin sheet |
| r78 | Home + journal week |
| r79 | Nap detail |
| r80 | Resp trend 6M |
| r81 | Health tab ONE upsell |
| r82a–g | Advanced Labs beta |
| r89 | Off-body home |
| r90, r91 | Healthspan gold |
| r92 | Upgrade modals |
| r94 | Activity zones |
| r95 | HM calibrating |
| r97 | Tab bar crop May 2025 |
| r98, r99, r101 | Coach v2.5 |
| r100 | Health tab May 2025 |
| r102–r105 | May 2025 home / HM |
| r141 | Home with "New Look" card |
| r144 | Trend view |

---------------------------------------------------------------------------------------------------

## 9. Reddit permalinks for saved images

| Image | Post date | Post title | URL |
|---|---|---|---|
| r01 | 2026-10-02 | Help! Whoop not syncing... | https://www.reddit.com/r/whoop/comments/1wvg7io/help_whoop_not_syncing/ |
| r02 | 2026-09-19 | Please don’t be this greedy | https://www.reddit.com/r/whoop/comments/1wkh77x/please_dont_be_this_greedy/ |
| r03 | 2026-08-09 | Whoop barely works now | https://www.reddit.com/r/whoop/comments/1vjexly/whoop_barely_works_now/ |
| r04 | 2026-08-08 | Whoop Latest Update Messed Up Widgets | https://www.reddit.com/r/whoop/comments/1vj7lu7/whoop_latest_update_messed_up_widgets/ |
| r05 | 2026-07-17 | Greed | https://www.reddit.com/r/whoop/comments/1uyze0r/greed/ |
| r06 | 2026-07-01 | How do I get back and view the "Get Started guides" again? | https://www.reddit.com/r/whoop/comments/1ukrs97/how_do_i_get_back_and_view_the_get_started_guides/ |
| r07 | 2026-06-07 | Issue: can’t scroll the health tab. Screen freezes | https://www.reddit.com/r/whoop/comments/1tz2xwu/issue_cant_scroll_the_health_tab_screen_freezes/ |
| r08 | 2026-04-29 | Work Travel impact | https://www.reddit.com/r/whoop/comments/1sze2gq/work_travel_impact/ |
| r10 | 2026-03-02 | Upgrade | https://www.reddit.com/r/whoop/comments/1rixy72/upgrade/ |
| r11 | 2026-02-10 | Whoop Training plans? | https://www.reddit.com/r/whoop/comments/1r17n33/whoop_training_plans/ |
| r12 | 2026-01-06 | Missing Onboarding Hints and Notifications? | https://www.reddit.com/r/whoop/comments/1q5u0by/missing_onboarding_hints_and_notifications/ |
| r13 | 2025-12-14 | Does the home screen have a no adds version? | https://www.reddit.com/r/whoop/comments/1pms1oy/does_the_home_screen_have_a_no_adds_version/ |
| r14 | 2025-11-27 | Stats Since ACL Surgery: 4 Weeks Post Op & Thankful for My First Day of Green Recovery! | https://www.reddit.com/r/whoop/comments/1p88ln6/stats_since_acl_surgery_4_weeks_post_op_thankful/ |
| r15 | 2025-10-31 | Can I remove the AL square from my home tab? | https://www.reddit.com/r/whoop/comments/1okut4e/can_i_remove_the_al_square_from_my_home_tab/ |
| r16 | 2025-10-11 | How do I get a refund? | https://www.reddit.com/r/whoop/comments/1o3zknx/how_do_i_get_a_refund/ |
| r18 | 2025-08-23 | Whoop Sleep, Strain, Recovery | https://www.reddit.com/r/whoop/comments/1my7chc/whoop_sleep_strain_recovery/ |
| r19 | 2025-08-21 | Show off the hard work! | https://www.reddit.com/r/whoop/comments/1mvzxwo/show_off_the_hard_work/ |
| r20 | 2025-08-17 | Alarm not showing on main screen | https://www.reddit.com/r/whoop/comments/1msg45k/alarm_not_showing_on_main_screen/ |
| r21 | 2025-08-16 | Whoop health screen | https://www.reddit.com/r/whoop/comments/1mrtf5u/whoop_health_screen/ |
| r22 | 2025-08-14 | How is this bug still not fixed? | https://www.reddit.com/r/whoop/comments/1mq59a5/how_is_this_bug_still_not_fixed/ |
| r23 | 2025-07-06 | HRV still not making sense to me | https://www.reddit.com/r/whoop/comments/1lt3qf8/hrv_still_not_making_sense_to_me/ |
| r24 | 2025-05-23 | Let's get steps added to the big widget! | https://www.reddit.com/r/whoop/comments/1ktuii4/lets_get_steps_added_to_the_big_widget/ |
| r25 | 2025-05-14 | How am I getting 14 strain in a meeting? | https://www.reddit.com/r/whoop/comments/1kmnepu/how_am_i_getting_14_strain_in_a_meeting/ |
| r26 | 2025-05-09 | Old “rings” UI is still available as a widget on iOS | https://www.reddit.com/r/whoop/comments/1kiw9aq/old_rings_ui_is_still_available_as_a_widget_on_ios/ |
| r27 | 2025-05-08 | How long will this take up the majority of my screen? | https://www.reddit.com/r/whoop/comments/1ki3qh2/how_long_will_this_take_up_the_majority_of_my/ |
| r28 | 2025-05-07 | Strain Not Showing | https://www.reddit.com/r/whoop/comments/1kgkeqj/strain_not_showing/ |
| r29 | 2025-05-06 | Classic circle | https://www.reddit.com/r/whoop/comments/1kg58zg/classic_circle/ |
| r30 | 2025-05-05 | Not a fan of this new Home Screen :( | https://www.reddit.com/r/whoop/comments/1kfl655/not_a_fan_of_this_new_home_screen/ |
| r31 | 2025-05-05 | Whoop Home Screen | https://www.reddit.com/r/whoop/comments/1kfpax7/whoop_home_screen/ |
| r32 | 2025-05-05 | Pretty happy with this | https://www.reddit.com/r/whoop/comments/1kfp7nx/pretty_happy_with_this/ |
| r40 | 2026-10-01 | New Achievement UI | https://www.reddit.com/r/whoop/comments/1wuyifb/new_achievement_ui/ |
| r41 | 2026-09-19 | A productive day | https://www.reddit.com/r/whoop/comments/1wk9pff/a_productive_day/ |
| r42 | 2026-09-06 | Has anyone ever got a worse recovery to strain ratio? | https://www.reddit.com/r/whoop/comments/1w8rkye/has_anyone_ever_got_a_worse_recovery_to_strain/ |
| r43 | 2026-09-06 | IDEAL STRAIN FOR MUSCLE BUILDING? | https://www.reddit.com/r/whoop/comments/1w949aa/ideal_strain_for_muscle_building/ |
| r44 | 2026-08-26 | Whoop app constantly freezing? | https://www.reddit.com/r/whoop/comments/1vz88ib/whoop_app_constantly_freezing/ |
| r45 | 2026-08-10 | Today I have did something only I imagined before start of my whoop journey | https://www.reddit.com/r/whoop/comments/1vkosi5/today_i_have_did_something_only_i_imagined_before/ |
| r46 | 2026-08-02 | Is it this bad for everyone when you’re sick? | https://www.reddit.com/r/whoop/comments/1vdndv5/is_it_this_bad_for_everyone_when_youre_sick/ |
| r47 | 2026-07-27 | Too much marketing | https://www.reddit.com/r/whoop/comments/1v83n7s/too_much_marketing/ |
| r48 | 2026-07-02 | WHOOP Honest use case is after 1607 streak | https://www.reddit.com/r/whoop/comments/1ulyd94/whoop_honest_use_case_is_after_1607_streak/ |
| r50 | 2026-06-23 | Strain | https://www.reddit.com/r/whoop/comments/1udquns/strain/ |
| r52 | 2026-06-14 | 18 strain without any activity? | https://www.reddit.com/r/whoop/comments/1u5t6gc/18_strain_without_any_activity/ |
| r53 | 2026-06-14 | Wanted to achieve 21 :) | https://www.reddit.com/r/whoop/comments/1u5dtcp/wanted_to_achieve_21/ |
| r54 | 2026-06-14 | 20.6 strain with a red recovery | https://www.reddit.com/r/whoop/comments/1u5asn5/206_strain_with_a_red_recovery/ |
| r55 | 2026-06-13 | Woah - I wonder how long this will last before needing to charge again.. | https://www.reddit.com/r/whoop/comments/1u4drln/woah_i_wonder_how_long_this_will_last_before/ |
| r56 | 2026-06-03 | Feels impossible to max out strain | https://www.reddit.com/r/whoop/comments/1tvx7wo/feels_impossible_to_max_out_strain/ |
| r57 | 2026-06-02 | Pre-adding activities to the My Day view | https://www.reddit.com/r/whoop/comments/1tuam78/preadding_activities_to_the_my_day_view/ |
| r58 | 2026-06-02 | When did they remove the sleep recommendation UI? | https://www.reddit.com/r/whoop/comments/1tv7ni8/when_did_they_remove_the_sleep_recommendation_ui/ |
| r59 | 2026-05-25 | Personal achievements yay | https://www.reddit.com/r/whoop/comments/1tn8kg2/personal_achievements_yay/ |
| r62a | 2026-05-21 | I’ve seen a lot of negative reviews about this product, but I wanted to share my positive  | https://www.reddit.com/r/whoop/comments/1tjsthc/ive_seen_a_lot_of_negative_reviews_about_this/ |
| r63 | 2026-05-17 | 1% and almost 20 strain | https://www.reddit.com/r/whoop/comments/1tg5boa/1_and_almost_20_strain/ |
| r64 | 2026-05-14 | Whoop coach needs sorting out | https://www.reddit.com/r/whoop/comments/1tdbqkt/whoop_coach_needs_sorting_out/ |
| r66 | 2026-05-09 | Time awake while sleeping | https://www.reddit.com/r/whoop/comments/1t8bvy3/time_awake_while_sleeping/ |
| r67 | 2026-05-05 | They're releasing a way to follow your friends | https://www.reddit.com/r/whoop/comments/1t4okrp/theyre_releasing_a_way_to_follow_your_friends/ |
| r68 | 2026-04-23 | [iOS] App Update 5.49.2 – Did they move the "My Plan" section? | https://www.reddit.com/r/whoop/comments/1st5tbx/ios_app_update_5492_did_they_move_the_my_plan/ |
| r69 | 2026-04-15 | Sick As A Dog! | https://www.reddit.com/r/whoop/comments/1slraxr/sick_as_a_dog/ |
| r70 | 2026-04-14 | Peak Strain PR | https://www.reddit.com/r/whoop/comments/1sl6ala/peak_strain_pr/ |
| r71 | 2026-04-07 | Not ideal | https://www.reddit.com/r/whoop/comments/1sepq02/not_ideal/ |
| r72 | 2026-03-19 | 5.3 Beta | https://www.reddit.com/r/whoop/comments/1rxqfx9/53_beta/ |
| r73 | 2026-03-13 | STATS | https://www.reddit.com/r/whoop/comments/1rs8pbh/stats/ |
| r74 | 2026-01-14 | 4+ year user Review | https://www.reddit.com/r/whoop/comments/1qcqc2s/4_year_user_review/ |
| r75 | 2026-01-12 | Move the chat button | https://www.reddit.com/r/whoop/comments/1qao4gr/move_the_chat_button/ |
| r76 | 2025-12-30 | is whoop complete dog... | https://www.reddit.com/r/whoop/comments/1pz2jnf/is_whoop_complete_dog/ |
| r77 | 2025-12-28 | Whoop experience comes to an end after 1 year | https://www.reddit.com/r/whoop/comments/1pxsrl1/whoop_experience_comes_to_an_end_after_1_year/ |
| r78 | 2025-11-23 | UI bugs after coming back from Asia | https://www.reddit.com/r/whoop/comments/1p4c7k5/ui_bugs_after_coming_back_from_asia/ |
| r79 | 2025-10-28 | UI Issue: I can't click on the 3 dots on the top right to edit my nap. What can I do about | https://www.reddit.com/r/whoop/comments/1oibpow/ui_issue_i_cant_click_on_the_3_dots_on_the_top/ |
| r80 | 2025-10-17 | We need a YEAR timeline added to Trend Views | https://www.reddit.com/r/whoop/comments/1o8pedx/we_need_a_year_timeline_added_to_trend_views/ |
| r81 | 2025-10-01 | Real time hr gone for One members? | https://www.reddit.com/r/whoop/comments/1nuyvy3/real_time_hr_gone_for_one_members/ |
| r82 | 2025-09-30 | I was a part of the Whooop Advanced Labs BETA AMA | https://www.reddit.com/r/whoop/comments/1nultsf/i_was_a_part_of_the_whooop_advanced_labs_beta_ama/ |
| r89 | 2025-09-27 | False strain score when sick | https://www.reddit.com/r/whoop/comments/1nriku3/false_strain_score_when_sick/ |
| r90 | 2025-08-06 | Whoop Age | https://www.reddit.com/r/whoop/comments/1mizg7z/whoop_age/ |
| r91 | 2025-07-01 | The Healthspan thing hurt my feelings | https://www.reddit.com/r/whoop/comments/1lp6tsk/the_healthspan_thing_hurt_my_feelings/ |
| r92 | 2025-06-03 | Annoying "Upgrade" tab | https://www.reddit.com/r/whoop/comments/1l2dckk/annoying_upgrade_tab/ |
| r94 | 2025-05-21 | Heart Rate watching Spurs in Europa League Final | https://www.reddit.com/r/whoop/comments/1ksbtgz/heart_rate_watching_spurs_in_europa_league_final/ |
| r95 | 2025-05-18 | Heart rate stuck on calibrating | https://www.reddit.com/r/whoop/comments/1kpnrk9/heart_rate_stuck_on_calibrating/ |
| r97 | 2025-05-11 | Where are the insights? | https://www.reddit.com/r/whoop/comments/1kk1htv/where_are_the_insights/ |
| r98 | 2025-05-10 | MPA No Longer Accessible | https://www.reddit.com/r/whoop/comments/1kjb139/mpa_no_longer_accessible/ |
| r99 | 2025-05-09 | Thank you whoop for the extra ads added in the new update! | https://www.reddit.com/r/whoop/comments/1kiekvd/thank_you_whoop_for_the_extra_ads_added_in_the/ |
| r100 | 2025-05-08 | New health tab in the app | https://www.reddit.com/r/whoop/comments/1kho11h/new_health_tab_in_the_app/ |
| r101 | 2025-05-08 | Overview and Insights Page, MPA and WPA removed | https://www.reddit.com/r/whoop/comments/1khqdz3/overview_and_insights_page_mpa_and_wpa_removed/ |
| r102 | 2025-05-07 | HRV not on new dashboard | https://www.reddit.com/r/whoop/comments/1khbklv/hrv_not_on_new_dashboard/ |
| r103 | 2025-05-06 | NEW UI | https://www.reddit.com/r/whoop/comments/1kg84ew/new_ui/ |
| r104 | 2025-05-05 | New UI? | https://www.reddit.com/r/whoop/comments/1kfes44/new_ui/ |
| r105 | 2025-05-03 | Health Monitor UI Redone | https://www.reddit.com/r/whoop/comments/1kdjj5t/health_monitor_ui_redone/ |
| r110 | 2026-06-10 | Dashboard customization | https://www.reddit.com/r/whoop/comments/1u2excv/dashboard_customization/ |
| r111 | 2026-03-06 | Feature Request: Adjust the Dashboard indicators to take into account time of day | https://www.reddit.com/r/whoop/comments/1rmix9h/feature_request_adjust_the_dashboard_indicators/ |
| r112 | 2026-02-14 | Customize Dashboard to show charts for certain data? | https://www.reddit.com/r/whoop/comments/1r4dk81/customize_dashboard_to_show_charts_for_certain/ |
| r113 | 2026-07-28 | Anyway to remove “My Plan” ? | https://www.reddit.com/r/whoop/comments/1v9d4zs/anyway_to_remove_my_plan/ |
| r114 | 2026-08-01 | Who else uses “My Plan” to motivate them for the week? | https://www.reddit.com/r/whoop/comments/1vckrra/who_else_uses_my_plan_to_motivate_them_for_the/ |
| r115 | 2026-09-19 | Daily recovery updates not wanted | https://www.reddit.com/r/whoop/comments/1wkf5pq/daily_recovery_updates_not_wanted/ |
| r116 | 2026-08-06 | Just got the update, haven’t noticed anything new | https://www.reddit.com/r/whoop/comments/1vhfqj8/just_got_the_update_havent_noticed_anything_new/ |
| r119 | 2026-07-19 | Sunday healthspan update… | https://www.reddit.com/r/whoop/comments/1v0il5v/sunday_healthspan_update/ |
| r120 | 2026-01-18 | Healthspan update - 9.3 yrs older | https://www.reddit.com/r/whoop/comments/1qg7t3w/healthspan_update_93_yrs_older/ |
| r121 | 2026-02-27 | I don’t understand what these numbers above my stress monitor graph mean. | https://www.reddit.com/r/whoop/comments/1rglan6/i_dont_understand_what_these_numbers_above_my/ |
| r122 | 2026-09-30 | Joined the 1% Club | https://www.reddit.com/r/whoop/comments/1wtwmdn/joined_the_1_club/ |
| r123 | 2026-10-01 | Whoop is constantly wrong | https://www.reddit.com/r/whoop/comments/1wuvxlr/whoop_is_constantly_wrong/ |
| r130 | 2025-10-14 | Whoop moved the activity button so you muscle memory press it's AI Coach. How do I move it | https://www.reddit.com/r/whoop/comments/1o6ivy3/whoop_moved_the_activity_button_so_you_muscle/ |
| r132 | 2025-09-19 | New iOS App update - tilt-mode now fixed, for me (iOS 26) 🎉 | https://www.reddit.com/r/whoop/comments/1nkwhyc/new_ios_app_update_tiltmode_now_fixed_for_me_ios/ |
| r133 | 2025-10-22 | I fear this is an unreasonable amount of time | https://www.reddit.com/r/whoop/comments/1odjkkz/i_fear_this_is_an_unreasonable_amount_of_time/ |
| r134 | 2026-05-30 | Whoop wants me to sleep at 6pm | https://www.reddit.com/r/whoop/comments/1trk4pr/whoop_wants_me_to_sleep_at_6pm/ |
| r135 | 2026-01-16 | I think my whoop wants me to get zero sleep and die lol. Why 3am-745am 🙈 anyone else getti | https://www.reddit.com/r/whoop/comments/1qe5czp/i_think_my_whoop_wants_me_to_get_zero_sleep_and/ |
| r136 | 2025-06-11 | Why does this show two different recommendation for a suggested time to bed? | https://www.reddit.com/r/whoop/comments/1l92st4/why_does_this_show_two_different_recommendation/ |
| r140 | 2026-10-01 | New Achievements! | https://www.reddit.com/r/whoop/comments/1wun77o/new_achievements/ |
| r141 | 2025-05-06 | I absolutely hate this new look, is it only me? | https://www.reddit.com/r/whoop/comments/1kgbp5f/i_absolutely_hate_this_new_look_is_it_only_me/ |
| r143 | 2026-07-02 | First time seeing that icon. That sums up how I feel… | https://www.reddit.com/r/whoop/comments/1uli8qq/first_time_seeing_that_icon_that_sums_up_how_i/ |
| r144 | 2025-07-02 | Is there any way to select custom dates on Whoop's trend view? | https://www.reddit.com/r/whoop/comments/1lppxxj/is_there_any_way_to_select_custom_dates_on_whoops/ |
| r151 | 2025-11-04 | How to find this view in Whoop App? | https://www.reddit.com/r/whoop/comments/1oog5fs/how_to_find_this_view_in_whoop_app/ |
| r152 | 2026-05-18 | New to Whoop, app question | https://www.reddit.com/r/whoop/comments/1tgn9xl/new_to_whoop_app_question/ |

Other posts quoted, text only:
- 2026-09-26 The Whoop app is really ugly. — https://www.reddit.com/r/whoop/comments/1wqlnf0/the_whoop_app_is_really_ugly/
- 2026-10-01 Whoop App keeps opening on Community Tab — https://www.reddit.com/r/whoop/comments/1wuxurn/whoop_app_keeps_opening_on_community_tab/
- 2026-05-07 90 Day Review - Constructive Feedback — https://www.reddit.com/r/whoop/comments/1t5yx2x/90_day_review_constructive_feedback/
- 2025-05-06 New Sleep Tab — https://www.reddit.com/r/whoop/comments/1kfy0z9/new_sleep_tab/
- 2025-05-28 Latest WHOOP Updates (5/28): Upgrade Modals & iPhone Battery Drain Fix — https://www.reddit.com/r/whoop/comments/1kxmdan/latest_whoop_updates_528_upgrade_modals_iphone/
- 2025-10-16 [Megathread] WHOOP update: New AI guidance connects every part of your health — https://www.reddit.com/r/whoop/comments/1o89sry/megathread_whoop_update_new_ai_guidance_connects/
- 2025-08-19 Updated Profile Tab — https://www.reddit.com/r/whoop/comments/1muo60i/updated_profile_tab/
- 2026-09-03 Coming Next: A More Personal Journal, a New Community, and Smarter Training Tools — https://www.reddit.com/r/whoop/comments/1w690hl/coming_next_a_more_personal_journal_a_new/
- 2025-07-18 WHOOP Coach Update (7/18) — https://www.reddit.com/r/whoop/comments/1m368x3/whoop_coach_update_718/
- 2026-04-27 Anyone else think Whoop's UI is terrible/social features are bad? — https://www.reddit.com/r/whoop/comments/1swo1ho/anyone_else_think_whoops_ui_is_terriblesocial/
- 2026-07-19 Best alternative UI / app? — https://www.reddit.com/r/whoop/comments/1v0j5cd/best_alternative_ui_app/
- 2025-05-08 New UI is their best yet! — https://www.reddit.com/r/whoop/comments/1khuuiv/new_ui_is_their_best_yet/
- 2026-10-02 Why can’t whoop continue to progress? Bevel is now winning — https://www.reddit.com/r/whoop/comments/1wvrwyr/why_cant_whoop_continue_to_progress_bevel_is_now/
- 2025-10-04 New app layout — https://www.reddit.com/r/whoop/comments/1ny3vx0/new_app_layout/
- 2025-10-14 Whoop moved the activity button so you muscle memory press it's AI Coach. How do I move it back? — https://www.reddit.com/r/whoop/comments/1o6ivy3/whoop_moved_the_activity_button_so_you_muscle/
- 2026-06-01 Light Mode — https://www.reddit.com/r/whoop/comments/1ttluy2/light_mode/
- 2026-07-15 Being Driven Mad By The New App Default — https://www.reddit.com/r/whoop/comments/1uxf46m/being_driven_mad_by_the_new_app_default/
- 2025-07-22 Hot take: a trends view tab should replace the community tab in the nav bar… — https://www.reddit.com/r/whoop/comments/1m62rb6/hot_take_a_trends_view_tab_should_replace_the/
