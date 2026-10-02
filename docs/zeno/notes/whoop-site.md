# WHOOP official website, The Locker blog and press pages: current (2025-2026) iOS app UI reference

Topic owner: "whoop-site" research agent. Research date: 2026-10-02.
Images: `/Users/raghavrathi/Downloads/Whoop-Apps-Handover/whoop-reference/images/whoop-site/` (all private local reference, never commit).
Scope: whoop.com product pages (Home, Membership, One, Peak, Life), The Locker articles, the 2026 "What's new" changelog, the 2025 year-in-review, and press-center releases. The third-party images (files `90-92`, the5krunner.com) are the only ones not from WHOOP, and are flagged where used. I added them because no WHOOP page shows the bottom tab bar.

How to read this file
- Measurements: "pt" means iOS points on a 390 pt wide iPhone 13/14 frame. The WHOOP product-page phone mockups (`50-56`) are 2600x3796 px images whose screen spans x 177-2421 px and starts at y 118 px, so 1 pt = 5.754 px. All pt numbers come from pixel measurement of those files unless I say otherwise. Treat them as +/-1 pt.
- Colours are hex values sampled with Pillow, followed by the file they came from. Exact values come from lossless PNG/WebP marketing renders. Video and JPEG samples can be off by a few units.
- Labels: CONFIRMED means I saw it in a WHOOP image or video. TEXT-ONLY means WHOOP describes it in words but I found no image. UNCONFIRMED means it is inferred or conflicting. LEGACY means the UI predates the May 2025 redesign; it is kept for contrast only.

---------------------------------------------------------------------------------------------------

## 0. Source map (what each WHOOP page gave us)

| Source (public) | Date on page | What it shows | Saved files |
|---|---|---|---|
| thelocker/the-all-new-whoop-home-screen | updated 2026 (orig. 2023-06-21) | Text: Home order (Streak/device → 3 dials → My Day → My Plan → My Dashboard → Stress Monitor trend → Hormonal insights), Health tab contents. **10 s MP4** of the 2025 Home + Sleep deep dive | 01, 02 (mp4), 03-10 (frames) |
| thelocker/2026-whats-new (live, published 2026-08-28) | Jan-Aug 2026 | Full dated changelog (section 9). Header = UI collage IMG_4459 | 11, 11a-11o (tile crops) |
| whoop.com/us/en/ (homepage) + /membership /one /peak /life | live 2026 | **Full-resolution phone mockups** of Home, Strain, Sleep, Heart Screener, Healthspan, BP Insights, Menstrual Cycle Insights; tier composites (Health Monitor, Stress Monitor); lifestyle overlays; feature icons | 50-71l |
| thelocker/how-does-whoop-recovery-work-101 | 2026-01-30 | Recovery deep dive ring + contributors; Home "Optimal Health" card; Strain & Recovery weekly chart; recovery zone dials | 13-17 |
| thelocker/introducing-stress-monitor… | 2023 (GIF 2024-01) | Stress Score scale; 36 s GIF of the **2024** Stress Monitor and breathwork flow | 18-20d |
| thelocker/how-well-whoop-measures-sleep | 2026-01-23 | Sleep stage bars (Awake/Light/SWS/REM) | 32 |
| thelocker/how-much-sleep-do-i-need | 2026-02-12 | Sleep Planner "Tomorrow I want to" sheet | 31 |
| thelocker/healthspan, Healthspan-Data-Meets-Longevity | 2025-05 / 2026-04 | WHOOP Age orb + Pace of Aging scale; Pace of Aging trend | 27, 73 |
| thelocker/a-new-way-to-see-insights… (Behavior Insights) | 2026-04-30 | Impact bars | 28, 77 (Locker index thumbnail) |
| thelocker/estimate-your-vo-max-with-whoop- | 2026-05-29 | VO2 Max percentile scale card | 29 |
| thelocker/heart-screener | 2025-05-08 | Heart Screener card, ECG list, ECG reading countdown | 30, 74, 75 |
| thelocker/set-and-reach-your-goals-with-weekly-plan | 2026-02-20 | Weekly Plan goal cards | 33 |
| thelocker/start-tracking-steps-with-whoop | 2024-10 | Trend View, Steps | 34 |
| thelocker/specialized-panels, press Advanced Labs uploads | 2026-04 / 2025-11 | Biomarker status chips, 60+ biomarker ring | 35, 79, 94 |
| thelocker/introducing-strength-trainer… | 2026-05-20 | Strength Trainer live session, tonnage, cardio/muscular split | 36 |
| thelocker/new-ai-guidance-from-whoop | 2026-04-30 | Daily Outlook (beta v2.0) AI screen | 37 |
| thelocker/my-memory-whoop | 2026-05-01 | Proactive AI push notification | 38 |
| thelocker/which-membership-is-right-for-you | 2025-05-08 | Activity chips, Healthspan card, "Take a new ECG reading" | 39-41 |
| thelocker/max-heart-rate-training-zones | 2026-03-31 | **Activity Details** (Running, Via Strava, HR chart, zone rows) | 95 |
| thelocker/what-is-restorative-sleep | (live) | Trend View, Restorative Sleep 6M | 96 |
| thelocker/whoop-features-support-reproductive-health… | 2025 | Customize Journal sheet | 97 |
| thelocker/metric-blood-oxygen-monitoring | (live) | Health Monitor 2025 tiles | 98 |
| thelocker/7-ways-to-use-whoop-coach, health-monitor-feature | 2024-26 | WHOOP Coach chat (beta) photo | 72, 72b |
| thelocker/introducing-whoop-5-0-and-whoop-mg | 2025-05-08 | Same app mockups as product pages | 84-87 |
| press-center/whoop-expands-health-platform… | 2026-05-08 | Text: clinician access, EHR (HealthEx), My Memory, Proactive Check-ins, redesigned Journal. Header = same collage as 11 | (dup of 11) |
| thelocker/10-whoop-features-you-need-to-know | 2026-01-30 | Text: navigation paths. Header: landscape "tilt mode" HR graph | 26 |
| thelocker/monthly-performance-assessment, new-feature-weekly-performance-assessment, new-whoop-4-0-feature-sleep-coach…, strain-coach, app-update-navigation-bar (2020) | 2018-2022 | LEGACY screens | 44, 46-48, 81, 82 |
| **3rd party** the5krunner.com 2025-10-15 | Oct 2025 | Real screenshots: Home with the **Liquid-Glass bottom tab bar** and WHOOP AI button; mid-2025 Home with the 4-tab bar and + FAB; Action (+) popover menu | 90, 91, 92 |

---------------------------------------------------------------------------------------------------

## 1. Global design language

### 1.1 Colour tokens (sampled)

Backgrounds and surfaces (dark theme only; no light theme exists on any WHOOP page except legacy screens and the PDF report):
| Token | Hex | Where sampled |
|---|---|---|
| Home top gradient, screen top (behind status bar and dials) | `#283238` → `#242F34` (y≈40 pt) → `#1F272D` (127 pt) → `#1B2125` (197 pt) → `#171D22` (249 pt) → `#15191C` (284 pt) | 50 (Dashboard mockup), vertical scan at x≈4 pt |
| Page background below the hero | `#14181B` → `#13171A` (bottom) | 50, 51 |
| Deep-dive page bg | `#14181B` / `#15191C` (top also gradient from `#29313…`) | 51, 53 |
| Video (May 2025) home bg | top `#222D34` → `#1A2528` → `#12181A`; My Day area `#0F1417`/`#101618` | 03, 06 |
| mid-2025 3p screenshot | **true black** `#000000`-`#060709` page, tiles `#090A0C` | 91 (UNCONFIRMED whether a setting or an older build) |
| Oct-2025 3p screenshot | top `#272E34` → mid `#1A1F23` → `#14171C` | 90 |
| Primary card (Optimal Health card on Home) | `#1F2628` | 50 |
| Stacked "next card" peeking under it | `#1B1F22` (visible ~11 pt, inset) | 50 |
| Contributor card (deep dives) | `#212528` top → `#191D20` bottom (subtle vertical gradient); video `#1B2123` | 51, 08 |
| Contributor row separator | `#363A3D` / `#393D41`, 1 pt, inset 16 pt from card edge | 51 |
| Today's Activities card | outer `#262C2E` / `#2B2F33`; activity row `#3B4142`; buttons `#3A3F42` | 06, 50 |
| Sleep "Hours of Sleep" card | `#23272C` (high-res) / `#1A2022` (video) | 52, 10 |
| My Dashboard metric row card | `#1F2123` (dimmed collage) | 11k |
| ECG / last-report card | `#252B30`; inner results card `#191D20` | 53 |
| Coach insight card fill | transparent / same as page (`#11161A`) | 57 |
| Date pill (Home) outer / selected segment | `#2E383E` / `#434B4F` | 50 |
| W (AI) square button on Home | `#292D30` / `#272B2E` | 50 |
| Segmented control (W/M/6M) | bg `#24282C`, selected segment lighter (~`#3A3F43`) | 55, 34 |
| Popover menu (Action +) | `#40474F` | 92 (3p) |

Text:
| Use | Hex |
|---|---|
| Primary text / numbers | `#FFFFFF` (`#FAFAFA`-`#FDFFFF` measured) |
| Body copy in cards | `#BCC0C1` (50), `#B7BDBF` (53) |
| Secondary label / units / axis / disabled chevron | `#919798`, `#8B8D90`, `#6F7577` (chevron after dial label) |
| Battery % text | grey `#919598` |
| Weak/baseline values (e.g. "148" under HRV) | `#565757` (dimmed collage), "7:46" under 8:44 |

Core metric colours (identical across all WHOOP renders):
| Metric | Hex | Notes |
|---|---|---|
| Sleep | `#7BA1BB` (`#7AA1BB`, video `#789FB9`) | steel blue; also sleep activity chip, sleep HR line |
| Recovery green (67-99%) | `#19EC06` (`#19EC05`) | from lossless 14 |
| Recovery yellow (34-66%) | `#FFDE00` | 14 |
| Recovery red (1-33%) | `#FF0026` | 14; red axis label `#E4072A` in 17 |
| Strain / activity blue | `#0094E8` (`#0093E7`) | dial, strain chart, bars, step bars, tonnage bars |
| Light-strain activity chip | `#67AEE6` | stretching chip (39); same value as Stress LOW and VO2 "40" |
| Dial track | `#2E353A`-`#343A3F` (home), `#2A2D30`/`#212326` (deep dive, fades to `#191A1C` near 12 o'clock) | |
| Strain-to-target arc (lighter grey) | `#5A5E61` (`#575D5F`) | then a white tick `#DCDEDF`-`#E5E9EA` at the target |
| Positive / "Optimal" / good-direction arrow | `#00F1A0` (`#00F19F`, `#00EF9D`) | teal-mint: arrows, 3rd segment, check chips, device dot, "Medium" stress text |
| Warning / "Poor" / bad-direction arrow | `#FFA722` (`#FFA721`, `#FBA522`) | orange |
| Neutral arrow / "Sufficient" | `#818385`-`#888A8D` grey |
| Inactive segment | `#363C3E` |

Sleep stages (32, 52):
- Awake `#C8C8C8`
- Light `#A4A3F1`
- SWS (Deep) `#FA96F9` (`#FAA0FA` in the header render)
- REM `#AC5AED`
- Bar track is diagonal hatching alternating `#363D43`/`#1F272C`.

HR zones (in-app Activity Details 95, plus the table in 42):
- Zone 5 (90-100%) `#FF6422`
- Zone 4 (80-90%) `#FCAC5D`
- Zone 3 (70-80%) `#59B996`
- Zone 2 (60-70%) `#479AC2` (table; `#3C82A4` in the dimmed collage)
- Zone 1 (50-60%) `#ADC2CD`
- Restorative (<50%) `#FFFFFF`

Stress (19, 11m, 58):
- LOW 0.0-0.9 `#67AEE6`
- MEDIUM 1.0-1.9 `#00F19F`
- HIGH 2.0-3.0 `#FFA722`
- The gauge arc is a continuous gradient blue → green → yellow-green → orange.
- The intraday line is coloured by level with the same gradient.

Menstrual Cycle Insights (56, 11f):
- Menstrual day circle `#FF7765`, menstrual band `#B95A51`
- Follicular band `#7978B1`; "today" disc `#A4A3F1`
- Ovulatory `#377291`
- Luteal `#9551CC` / `#7D45AC`; future days muted `#5D3882`
- Header gradient purple `#302445` → `#1D1B27` → page
- Phase title text ("Luteal Phase") `#AB5BEA`

Other accents:
- ECG / Heart Screener purple: trace `#AB5BEC`; "Take a new ECG reading" button bg `#342D48` with plus/label in purple-tinted white.
- Healthspan orb green: particles `#04F0A3`, rim `#05B576`, dark interior `#005434` → black.
- BP gauge: green `#00F1A0`, yellow `#FFEB63`, orange `#FFA721`.
- VO2 percentile scale tops (29): `<35` grey, `35` `#ADC2CD`, `40` `#67AEE6`, `45` `#A4A3F1`, `50+` purple (text ~`#AB5BEC`).
- AI / coach link gradient ("LEARN MORE WITH COACH →", "VIEW YOUR PLAN →"): `#7F7CFF` (left) → `#768AFE` → `#5EB8FF` (right). Arrow `#7095FE`.
- Coach insight card border gradient: `#4C3F8C` (left) → `#41568C` → `#34708C` (right), about 1.5 pt stroke (57, 09).
- "Your Home Has a New Look" onboarding card border: salmon-pink `#D876A9` (top-left) → magenta `#C343DA` (right) (03, 04).
- Daily Outlook pill gradient (morning): warm taupe `#6D655B` (left) → slate `#434C53` → teal-slate `#283B45` (right); chevron tinted pale gold `#E8D3A9` (brightest pixel, 06).
- Day In Review pill gradient (evening): indigo `#2E2B50` (left) → teal `#294350` (right); chevron blue (90, 11g).
- W/AI glyph ring: gradient purple → `#5DB3FD` blue (06).

### 1.2 Typography (visual match; family UNCONFIRMED)
- **Numerals** (dial values, stats): a DIN-style bold with flat terminals and a smaller "%" glyph, e.g. "74%". The closest bundled iOS font is `DINAlternate-Bold`. The "%" sits at about 70% of the digit height, baseline-aligned.
- **Labels**: geometric grotesk in ALL CAPS, bold, tracked about +1 pt (+0.1 em), e.g. SLEEP, RECOVERY, TODAY'S ACTIVITIES, HEART RATE ZONES 1-3. It resembles Proxima Nova Bold. A practical stand-in is SF Pro Text Semibold or Avenir Next Demi Bold with tracking.
- **Titles and body**: same grotesk in sentence case ("My Day", "Last Night's Sleep", "Optimal Health").
- Measured sizes (pt, iPhone 390 wide):

| Element | Measured | Estimated font |
|---|---|---|
| Home dial value "74%" | cap height 19.7 | ~28 pt DIN bold |
| Home dial label "SLEEP" | cap 7.3, width 35.5 | ~10-10.5 pt bold caps, tracking ~1 pt |
| Home date pill "TODAY" | cap 7.3 | ~10.5 pt bold caps |
| WHOOP wordmark above dials | 71 x 11.5 pt | logo asset, thin geometric |
| Battery "65%" | cap 9.0 | ~13 pt medium, grey |
| Card title "Optimal Health" | 98.7 wide, 12.7 tall (with descender) | ~15-16 pt medium/semibold |
| Card body | 15 pt regular, line pitch ~20 pt | `#BCC0C1` |
| Section header "My Day", "Last Night's Sleep", "Sleep" (Healthspan) | 17.7-18.1 tall | ~22 pt semibold |
| "Your Daily Outlook" | 124 pt wide | ~16 pt medium |
| "TODAY'S ACTIVITIES", "HOURS OF SLEEP", "PACE OF AGING" | cap 8.0 | ~11-12 pt bold caps, tracking 1.2-1.5 pt |
| Deep-dive nav title "TODAY", "HEART SCREENER" | cap 8.7 | ~12 pt bold caps |
| Deep-dive big value "14.2" | cap 49.2 | ~68-70 pt DIN bold |
| Deep-dive ring label "DAY STRAIN" | cap 8.7 | ~12 pt bold caps |
| Contributor label "HEART RATE ZONES 1-3" | cap 7.5 | ~10.5-11 pt bold caps |
| Contributor value "1:05" | cap 12.0 | ~17 pt DIN bold |
| "8:44" (Hours of Sleep) | cap 17 | ~24 pt DIN bold; sub-value "7:46" ~11 pt bold grey |
| Stage row "0:34", "TIME IN BED 8:48" value | cap 10.6 | ~15 pt DIN bold |
| Chart axis labels (90/70/50/30, 12:19am) | cap 7-7.8 | ~10-11 pt bold grey |
| "Electrocardiogram (ECG)" | 18.2 tall | ~22 pt regular/medium |
| Button caps label "TAKE A NEW ECG READING" | cap 8.7 | ~12 pt bold, tracking ~2 pt |
| Healthspan "29.9" in header orb | cap 16.9 | ~24 pt DIN bold |
| Healthspan "4.7" / "0.8x" | cap 11.8-12.2 | ~17 pt DIN bold |

### 1.3 Geometry and spacing
- **Screen side margin**: cards and sections start at **15 pt** from each edge (card x 15.0 → 374.5 on 390). Text inside cards is inset about 16-20 pt (card title at x 35.5). Section headers ("My Day", "Electrocardiogram") sit at x ≈ 18.4-20.5 pt.
  - The May-2025 video frame suggests about 11-12 pt margins. UNCONFIRMED; use 16 pt as a safe value.
- **Card corner radius**: about **12 pt**. Fitting the corner curve of the Optimal Health card gives r≈12 pt; the contributor card is the same.
- The W button (48x48), Daily Outlook pill (300x48) and date pager (143x32) were measured by corner-curve fit at about **11-12 pt radius** (10-12 for the pager). So they are rounded rectangles, not full capsules; the same ~12 pt radius applies to the whole UI. Status chips use about 4-6 pt radius.
- **Home vertical rhythm** (pt from top of an 844 pt screen):

| Element | y (pt) |
|---|---|
| Status bar | 0-47 |
| Top row centre (avatar 32 pt, date pill 32 pt tall x 143 pt wide with an 84 pt selected segment, battery) | 74 |
| WHOOP wordmark | 122-134 |
| Dial centres (outer Ø **88 pt**, stroke **6 pt**) | **202**; x = 74.4 / 194.6 / 314.9 (120 pt apart) |
| Dial labels (cap) | 258-266 (≈12 pt below the ring) |
| Coaching card | 293-432 (139 pt) |
| "My Day" header | 484-502 |
| W button 48x48 + Daily Outlook pill 300x48 (12 pt gap) | 520-567 |
| Today's Activities card starts | 584 |

- **Deep-dive vertical rhythm** (Strain):

| Element | y (pt) |
|---|---|
| Nav row centre (back chevron 12x22 at x 25; title; (i) 27.5 pt circle at x 343) | 74 |
| Ring outer (Ø **≈260 pt**, stroke **≈15.5 pt**, centre 195/252) | 122-382 |
| "WHOOP" wordmark in ring, 86 pt wide, grey `#81888A` | 193-206 |
| Value | 226-275 |
| Label | 295-304 |
| Contributor card: notch tip at 401, card top ≈409, rows **53 pt** pitch, 1 pt separators | from 401 |

- **Activity row** (Today's Activities, from the video): row ≈57 pt tall. Coloured chip ≈93x38 pt with radius ≈8, holding an icon and the value. Time range right-aligned on two lines with a 2 pt vertical accent bar in the activity colour at the far right. ADD/START buttons ≈40 pt tall, two columns.

### 1.4 Iconography
- Thin outline glyphs (≈1.5-2 pt stroke, rounded caps), white or `#8B8D90` grey. Seen examples:
  - moon (sleep), cyclist, runner, lifter (Strength Trainer), dumbbell ("Strength training time")
  - heart with lines (zones 1-3), heart with peaks (zones 4-5), plain heart (avg HR), heart with down-arrow (RHR), ECG-in-heart (HRV), lungs (respiratory rate), droplet with bubbles (SpO2), thermometer (skin temp)
  - clock-moon (hours vs needed), bed with clock (consistency), bed with circle (efficiency), gauge (sleep stress), sunset/sunrise with arrows (sleep start/end)
  - strap/band outline with a status dot (device), stopwatch (start activity), camera (WHOOP Live), notebook-pencil (Journal), gear (settings), history-clock (Daily Outlook history), expand arrows ↗↙ (expand a card), pencil (EDIT)
- **Feature icons** on the membership pages (white line art on black, 71-71l): Health tab heart-pulse; ECG pulse in a rounded square; heart pulse; heart with up arrow (max HR); droplet in a dotted circle (menstrual cycle); speedometer (perform); shoe (steps); stress gauge arc; lungs with arrows (VO2 max); rosette/flower (WHOOP Age); strap vibrating (haptics); heart-gauge (blood pressure).
- **Bottom tab icons** (3p, 90/91):
  - Home: house containing a line chart
  - Health: heart with a pulse line
  - Community: three people
  - More: three horizontal lines
  - WHOOP AI: the "W" monogram inside a gradient ring
- Behavior icons in the Journal and Insights are larger line pictograms (champagne glass, open book, cat; 28).

### 1.5 Chart styles
- **Dial ring**: starts at 12 o'clock and fills clockwise with a round cap; the track is a darker grey full circle.
  - Sweep = score/100×360° for Sleep and Recovery. Strain uses value/21×360° (14.2 → about 244°).
  - Strain dials add a **lighter grey arc from the current strain up to the Strain Target**, ending in a short **white tick** (target 15.5 → tick at about 276°).
  - The 2026 collage renders Sleep and Strain progress with an **angular gradient** that darkens toward the start: `#004A74` → `#0093E7` over the first ~70°. Recovery stays solid. Other renders are solid. Either is acceptable; solid is the majority.
  - Some WHOOP home mockups draw 85% Recovery with the same sweep as 74% Sleep (≈267°), which is a mockup artifact. The 2026 render draws 85% ≈ 306°.
- **3-segment quality bar** (Sleep contributors; under the big Sleep Performance number): three short rounded dashes (~16x3 pt each, 2 pt gaps). One segment is lit: 1st = Poor (orange), 2nd = Sufficient (grey), 3rd = Optimal (teal). The others are `#363C3E`. A legend pill "▬ Poor ▬ Sufficient ▬ Optimal" sits on a darker `#06090B` capsule.
- **Trend arrows**: small solid triangles ▲▼ after values. Teal = good direction, orange = bad direction, grey = neutral. A grey dot • means no change.
- **HR line charts** (Hours of Sleep, Activity Details): 1.5 pt line in the metric colour (sleep blue or strain blue).
  - The area under the line has a vertical gradient fading to transparent.
  - Dashed vertical lines with dot ends mark start and end. Sunset↓ and sunrise↑ icons with times sit under the axis.
  - Y axis labels 30/50/70/90 (sleep) or 40-100 (activity) are bold grey. No gridlines.
  - "TYPICAL RANGE" legend uses a dashed-square icon.
- **Stage highlight**: selecting a stage (radio circle) in Last Night's Sleep recolours that stage's segments of the HR line in the stage colour and draws translucent vertical bands down to the axis (52). Each stage row shows a **barcode timeline** of when that stage occurred over a hatched track: grey when unselected, stage colour when selected.
- **Bars over hatched tracks** (HR zones, sleep stages, behavior impact): rounded fill bar plus a diagonal-hatched remainder. The typical-range band is drawn with two dashed vertical lines and a lighter hatch between them.
- **Impact bars** (Behavior Insights): a centre "zero" knob (dark circle, white dot). Green fill grows right (+%), orange fills left (−%), grey for small effects. The % label at top-right is in the same colour.
- **Weekly bar charts** (Steps, Weekly Plan, Recovery): rounded-top bars with **value labels above each bar** in the bar colour. Day labels "Thu 28" sit below; the current day has a lighter column highlight. Weekly Plan adds a dashed "GOAL" line with a white "GOAL" tag.
- **Strain & Recovery chart** (17): dual axis. Left 0/7/14/21 is blue; right 0%/33%/66%/100% uses the zone colours. Blue strain line with hollow blue rings and value labels. Grey recovery line with rings coloured by zone (green/yellow/red) and coloured % labels. Selected day = lighter rounded column. Title "STRAIN & RECOVERY" with (i).
- **Gauges**: Stress Monitor and BP are ~270° arcs with gradient or segment fills. The needle is a short white capsule with a soft shadow, placed at the current value.

### 1.6 Recurring components (exact wording where visible)
- **Date pager**: "< TODAY >" capsule. The left chevron is white; the right chevron is grey/disabled on today. When viewing past days it shows a range, e.g. "< OCT 14 TO TODAY >" (90, 3p).
- **Deep-dive nav bar**: "‹" (white, 22 pt tall) · centred caps title ("TODAY", "HEALTHSPAN" + sub "Next update in 6 days", "BLOOD PRESSURE INSIGHTS" + "BETA V1.0 (i)" pill) · "(i)" outlined circle 27.5 pt or a gear.
- **Modal nav**: "✕" · caps title · optional right icon (gear for Menstrual Cycle Insights and Stress Monitor; history clock for Daily Outlook).
- **Contributor card with a notch**: a 12 pt triangle notch on the top edge, centred under the ring and pointing at it ("speech bubble"). Rows: icon (18 pt) · CAPS label · value right-aligned · trend arrow or dot.
- **Coach insight card**: gradient hairline border (indigo → teal), transparent fill, 17 pt body text, then a caps gradient link "LEARN MORE WITH COACH →". Healthspan uses "VIEW YOUR PLAN →". The 2024 Stress Monitor used "Learn more with WHOOP Coach".
- **Stacked coaching card** on Home: title + body. The top-right "✓ / 2" pill (check over a count, `#343A3C` bg, 9.7x13 pt) marks the card read and shows how many remain. A second card peeks underneath. Examples:
  - "Optimal Health — Take advantage of your green Recovery by meeting your Strain target of 15.5. Your body is signaling it can take on significant exertion today."
  - "Your Home Has a New Look — Tap Sleep, Recovery, or Strain above to learn more about your core daily metrics." (gradient border and a 3D house illustration)
- **Section header + action**: "Last Night's Sleep" (22 pt) with right "EDIT ✏" (caps 10 pt + pencil). "My Dashboard" has a pencil/"Customize" control (text says "Tap the pencil icon on the right of the section header" or "Customize").
- **Status chips**:
  - "✓ within 13.8 - 14.8 rpm" (green text on dark green `#1D443A`/`#2E5042`)
  - "! Out of Range" (orange on dark amber)
  - "• Sufficient" (grey on dark grey)
  - "✓ Optimal" (green)
  - "▲ 8% past week", "▲ 6% past 6-months" (grey pill)
  - "▼ vs. typical Tue" (green chip = lower stress than typical)
  - "+ vs. typical Tuesday" (amber chip, 11n)
- **Segmented control**: "W | M | 6M", 3 equal segments on `#24282C`, selected segment lighter, caps bold labels.
- **Range pager**: "< OCT 28 - NOV 3, 24 >", "< MAR 1 - MAR 7, 25 >", "< AUG 19 - AUG 26 >" in caps bold with chevrons.
- **Primary CTA buttons**:
  - "TAKE A NEW ECG READING" with a purple "+" on `#342D48`, full width, 48 pt tall, r≈12
  - Today's Activities "+ ADD ACTIVITY" / "⏱ START ACTIVITY", two columns on `#3A3F42`
  - Legacy: "START EXERCISE", "END & SAVE" outlined teal capsules; "SET ALARM" with a strap-vibration icon on `#303133`
- **Check / X journal buttons** (2026): question rows with a gradient border, ✕ dark square, ✓ filled blue square (`~#5FA8E8`), "Custom" outlined chip (76).

---------------------------------------------------------------------------------------------------

## 2. Navigation and information architecture (2025-2026)

**Bottom tab bar** (no WHOOP-site image; 3p screenshots):
- **Oct 2025 onward** (90, the5krunner, "new app version"): a floating rounded "glass" capsule tab bar (iOS-26 style) with **Home · Health · Community · More**. Selected = white icon and label; others grey. To its right is a separate **floating round WHOOP AI button**: dark tile with the "W" monogram in a glowing purple-blue ring.
  - The **Action (+) button moved to the right of the "My Day" header** as a white rounded square with a black "+" (≈38 pt).
  - the5krunner: "The Action button is now more prominent and placed centrally, whereas the Coach button … new position in the right-hand corner of the bottom menu bar."
  - WHOOP's text: "The Action (+) button in the bottom navigation bar, to the right of My Day…; WHOOP AI is also in the bottom navigation bar."
- **Mid-2025** (91): standard opaque 4-tab bar (Home, Health, Community, More), with a **floating white circular "+" FAB** above the bar at bottom-right. The W/AI entry was the round "W" button next to "Your Daily Outlook".
- **Action (+) menu** (92, Oct 2025): the + turns into "✕" and opens a popover card (`#40474F`, r≈16) anchored under it, listing:
  1. ⏱ START ACTIVITY
  2. + ADD ACTIVITY
  3. 🏋 STRENGTH TRAINER
  4. 📓 COMPLETE YOUR JOURNAL
  5. 📷 CREATE WHOOP LIVE

  Caps bold labels, about 54 pt rows, no separators.
- "Plan" tab: the Weekly Plan article (2026-02-20) says "Open the WHOOP App → Tap the **Plan** tab". The Home article says My Plan sits on Home, and the 3p tab bar shows no Plan tab. **UNCONFIRMED/conflicting.** Most likely Weekly Plan is reached from the My Plan section on Home.

**Home top bar**: profile avatar (photo, or a black circle with the white W logo when there is no photo), a **streak flame + day count** (e.g. "🔥15") next to it, the centre date pager, and on the right the battery "65%" with a strap outline icon. The strap icon has a status dot: green `#00F1A0` = connected; orange up-arrow = charging (91; UNCONFIRMED meaning). Tapping the device opens device settings (battery, firmware).

**Paths stated on whoop.com** (TEXT-ONLY unless noted):
- Profile (tap avatar):
  - "Data Highlights": total activities, max HR, peak day Strain, top activities, HRV and RHR ranges
  - Streaks (tap the flame): Day Streaks, start date, max streak
  - **My Memory** ("Open My Memory from your profile")
  - Profile highlights WHOOP Age, levels and streaks (2025 recap)
- More → App Settings → **Integrations** (Strava, HealthEx EHR), **Hormonal Insights** (toggle), **Hide Metrics**, Activity Settings → **Heart Rate Settings** (max HR, zone bounds).
- Settings → Device Settings → **Broadcast heart rate** (Peloton, Strava, Zwift, Concept2, Wahoo, TrainerRoad, RunKeeper, some Garmin).
- Community tab → "…" → create a team (see each other's Sleep, Strain, Recovery; chat).
- Health tab → Heart Screener; Blood Pressure Insights; Healthspan; Health Monitor (→ share a **PDF Health Report**, 30- and 180-day changes); Stress Monitor; Hormonal insights; Live HR (WHOOP One).
- Journal: morning prompt after sleep processes; Journal card on Home; Action (+) → Complete your Journal; **Insights** button in the Journal (and in Recovery) → Behavior Insights / Impacts; Journal Trends (calendar views).
- Sleep Planner: Home "TONIGHT'S SLEEP" card; tap "Time In Bed" for the sleep-need calculation.
- My Dashboard: tap a tile → its Trend View (weekly, monthly, 6-month). "Customize" / pencil → choose metrics → drag to reorder → Save.
- VO2 Max:
  - Add to My Dashboard via Customize; updates **weekly on Tuesdays**
  - Trends screen → "Add manual measurement"; "+ Update Weight" in the VO2 trend view
  - Needs 14 recoveries in 21 days, otherwise the trend shows "recoveries left until available"
- Activity Details:
  - Edit icon (above the HR graph) → Edit Activity with a **scrubbable HR graph** for start/end (iOS, June/July 2026)
  - Share icon on the activity map → shareable GPS snapshot (transparent background option)
  - Source attribution such as "Garmin Via Strava" or "VIA STRAVA"
- Rotate the phone 90° ("tilt mode") → landscape all-day HR graph with Sleep/Strain/Recovery at a glance (26 shows "OVERVIEW HR | Today", a sleep block "60% 5:38", and a yellow "34% RECOVERY" marker line).

---------------------------------------------------------------------------------------------------

## 3. Screens

### 3.1 Home (2025 redesign, still current in 2026). CONFIRMED (02-06, 50, 62, 90, 91, 16)
Top to bottom:
1. Status bar.
2. Top row:
   - Avatar (32 pt circle) + flame streak count
   - Centred date pager "‹ TODAY ›" (32 pt tall capsule)
   - Battery "65%" + strap icon with status dot
3. "WHOOP" wordmark, centred, thin, white.
4. **Three dials** in a row: **SLEEP (74%) · RECOVERY (85%) · STRAIN (14.2)**.
   - Values inside the rings; caps labels below with a small grey "›" chevron (chevrons appear in the live app and video; marketing mockup 50 omits them).
   - Tapping a dial opens its deep dive. A tap ripple circle is shown in the video (f010).
5. **Coaching card stack** (one visible card plus a peeking card), e.g. "Optimal Health …" or the one-time "Your Home Has a New Look" card. "✓/2" counter pill.
6. **Health Monitor / Stress Monitor tiles** (Peak/Life members; video 04 and 3p 90/91): two equal tiles about 174 pt wide with a 12 pt gap and r≈12.
   - "HEALTH MONITOR ›": green check square + "WITHIN RANGE" (green caps) + "5/5 Metrics" (grey).
   - "STRESS MONITOR ›": a green square containing the score "1.6" + "MEDIUM" (green caps) + time "1:00 AM".
   - WHOOP's 2026 text places a "Stress Monitor trend" lower on Home and lists Health Monitor and Stress Monitor in the Health tab. Both placements exist; UNCONFIRMED whether the tiles remain at the top for all members.
7. **"My Day"** (22 pt header). In Oct 2025 it has a white "+" Action button at the right.
   - A row with the **W AI button** (48 pt square, gradient-ring W) and the **"☀ Your Daily Outlook ›"** gradient pill in the morning, or **"☾ Your Day In Review ›"** in the evening (90, 11g). In Oct 2025 the separate W square was gone; the pill was full width (90).
   - **"TONIGHT'S SLEEP ›" card** (3p 90):
     - "Now" (or a time) "RECOMMENDED BEDTIME" with a sunset icon
     - dashed connector
     - "8:00" with a sunrise icon and "ALARM OFF" (orange) or "● ALARM ON / EXACT TIME" (green, 67)
     - full-width "SET ALARM" button with a strap-vibration icon
   - **"TODAY'S ACTIVITIES"** card (caps title, expand ↗↙ icon at right). Rows:
     - [moon chip `#7BA1BB` "8:18"] SLEEP, "[Wed] 10:08pm / 6:50am"
     - [cyclist chip `#0094E8` "12.8"] CYCLING, "8:00am / 8:45am"
     - Low-strain activities use a lighter chip `#67AEE6` (Stretching "0:20", 39)
     - Then two buttons: "+ ADD ACTIVITY" and "⏱ START ACTIVITY" (in 62 both show "+")
8. **"My Plan"**: progress toward Weekly Plan goals (TEXT-ONLY on Home; card visuals in 3.19).
9. **"My Dashboard"**: user-chosen metric tiles with long-term trends.
   - Row style (11k): rounded row card, outline icon, CAPS label (e.g. HEART RATE VARIABILITY, SLEEP PERFORMANCE), value bold right ("152", "89%"), teal ▲, and a small grey baseline beneath ("148", "84%").
   - Pencil/Customize on the header. Tapping a tile opens its Trend View.
10. **Stress Monitor trend** (Peak/Life) and **Menstrual Cycle / Pregnancy insights** card (if opted in). TEXT-ONLY.
11. Journal card (TEXT-ONLY: "Home Screen: Scroll down to the Journal card").
12. Bottom bar (section 2).

Metrics on Home: Sleep Performance %, Recovery %, Day Strain (0-21), Strain target (in coaching text), battery %, streak days, Health Monitor X/5 within range, Stress score (0-3) with level and time, activities (sleep duration h:mm; activity strain plus start/end times), recommended bedtime, alarm time and state, and Dashboard metrics. Dashboard options seen in WHOOP text: HRV, Sleep Performance, Steps, VO2 Max, RHR, etc.

Hide option: More → App Settings → Hide Metrics hides the Recovery and Sleep scores.

### 3.2 Sleep deep dive (tap SLEEP dial). CONFIRMED (07-10, 52, 57, 11l)
1. Nav: "‹ TODAY (i)".
2. Big ring (sleep blue): "WHOOP" wordmark (grey), "**74%**" (huge), "SLEEP / PERFORMANCE" (two-line caps), then a 3-segment quality bar (3rd lit teal = Optimal).
3. Notched contributor card, 4 rows, each with icon · CAPS label · 3-segment bar · % value:
   - ⏱ **HOURS VS. NEEDED** 84% (Optimal)
   - **SLEEP CONSISTENCY** 73% (Poor, orange 1st segment)
   - **SLEEP EFFICIENCY** 94% (Optimal)
   - **SLEEP STRESS** 1% (Sufficient, grey middle segment)
   - Legend capsule: "▬ Poor ▬ Sufficient ▬ Optimal".
4. Coach insight card: "On nights where you get at least 7 hours of sleep, you see increased Sleep Performance and a 10% boost to your Recovery. Try going to bed by 10pm to make sure you hit your mark. LEARN MORE WITH COACH →".
5. "**Last Night's Sleep**" + "EDIT ✏". Sub: "**Today** vs. prior 30 Days" ("Today" white, rest grey).
6. Card "**HOURS OF SLEEP**" with (i) (video) or "›" (2025 mockup). Big "8:44" + teal ▲, grey "7:46" beneath (30-day average).
   - HR chart over the night (y 30-90 bpm), sunset↓ "12:19am" … "9:04am" sunrise↑.
   - Divider, then "⬚ TYPICAL RANGE" legend and "TIME IN BED **8:48**".
7. Sleep stage list (52):
   - ○ AWAKE 6% … 0:34
   - ○ LIGHT 53% … 4:32
   - ● SWS (DEEP) 24% … 2:07
   - ○ REM 17% … 1:31
   - Each row has a barcode timeline under it. Selecting a stage recolours the HR chart (see 1.5).
   - The alternative compact style (32) shows filled proportion bars with typical-range dashed bands.
8. Lower content (UNCONFIRMED): the 2025 Locker text adds "new bedtime recommendations". The sleep trend views (Sleep Performance, Hours vs. Need, Time in Bed, Sleep Consistency, Restorative Sleep %/hours, Efficiency, Sleep Debt) are reached by scrolling down: "head to the Sleep, Strain, or Recovery section… scroll down to view your weekly trends".

Sleep Performance (2025 definition) combines **sufficiency (Hours vs. Needed), consistency (vs previous 4 days), efficiency, and sleep stress**. Sleep Need inputs: baseline, recent strain, sleep debt, recent naps.

### 3.3 Recovery deep dive. CONFIRMED (15, 57, 11j, 14)
1. Nav "‹ TODAY (i)".
2. Ring in the zone colour: "WHOOP", "85%", "RECOVERY".
3. Notched contributor card:
   - ⚡ **HEART RATE VARIABILITY** 124 ▲ (teal)
   - ♡↓ **RESTING HEART RATE** 49 ▲ (**orange**: up is bad)
   - 🫁 **RESPIRATORY RATE** 14.5 ▲ (grey)
   - ☾ **SLEEP PERFORMANCE** 74% • (grey dot = unchanged) or ▲ teal
4. Coach insight card ("…elevated while your RHR, … and Sleep Performance are all…", text cut off in 57).
5. Lower section UNCONFIRMED. WHOOP shows a weekly **"STRAIN & RECOVERY"** chart (17) and Recovery weekly bars (68). Recovery → "Insights" opens Behavior Insights (2026).

Zones: GREEN 67-99%, YELLOW 34-66%, RED 1-33% (14 shows dials with "67-99 %", "34-66 %", "1-33 %"). Inputs: HRV, RHR, respiratory rate, sleep; SpO2 and skin temp are in Health Monitor.

### 3.4 Strain deep dive. CONFIRMED (51, 57, 11a)
1. Nav "‹ TODAY (i)".
2. Ring: blue progress, lighter target arc, white target tick; "WHOOP", "**14.2**", "**DAY STRAIN**".
3. Notched contributor card:
   - **HEART RATE ZONES 1-3** 1:05 ▲ teal
   - **HEART RATE ZONES 4-5** 0:23 ▲ teal
   - **STRENGTH TRAINING TIME** 0:35 ▼ orange
   - **AVERAGE HEART RATE** 91 ▲ grey
4. Coach insight card: "Strain between 14 and 17.9 is considered strenuous, meaning your cardiovascular system has been working hard. LEARN MORE WITH COACH →".
5. "**Today's Activities**" (title case, 22 pt) list.
6. Lower content UNCONFIRMED (trend views: Day Strain, Strength Activity Time, Calories, Avg HR, Steps, HR Zones 1-3 and 4-5, VO2 Max).

Strain scale text: Light 0-9, Moderate 10-13, High 14-17, All Out 18-21. Average member ≈11.0. Day Strain resets at midnight. Strain Target intents: **Restorative / Maintenance (default) / Overreaching**.

### 3.5 Activity Details (workout). CONFIRMED (95, 66)
1. "✕" · activity icon + "RUNNING" + "6:45am to 7:30am" · "•••".
2. Source chip "VIA STRAVA".
3. "**13.8**" in strain blue (~40 pt) + "▲ 9.7" grey chip; caps "ACTIVITY STRAIN".
4. Insight sentence (17 pt): "Spending 23 minutes in your highest heart rate zones made this sparring session too strenuous to help your body recover."
5. "HEART RATE" chart (blue line, gradient fill, y 40-100, start/end dashed lines "6:45am … 7:16am").
6. "⬚ TYPICAL RANGE" … "DURATION 45:06".
7. Zone rows (each its own rounded row card):
   - "ZONE 5 (90-100%) 3%" "0:01:02" (seconds smaller and grey)
   - ZONE 4 (80-90%) 9% 0:03:15
   - ZONE 3 (70-80%) 42% 0:09:08
   - ZONE 2 (60-70%)
   - ZONE 1 (50-60%)
   - RESTORATIVE (<50%)
   - The fill bar is in the zone colour and has a typical-range band.
8. Lower content (TEXT-ONLY, 2026): Strength Trainer exercises and muscular load; cardio vs muscular split "CARDIO 25% / MUSCULAR 75%" (66); GPS map with share icon; edit icon above the HR graph.

Overlay variant (66): "10.8" blue + "▲ 9.8"; "ACTIVITY STRAIN"; a CARDIO/MUSCULAR split bar (two blues with a white divider) and percentages.

### 3.6 Start Activity / live session / Strain Target. PARTIAL
- 2026 collage tile (11c): "**LIVE SESSION**" title, a ring with a blue → teal-green gradient glow, "**ACTIVE**" (green caps) and timer "**01:29**" (big, green). UNCONFIRMED which flow this is (start-activity live tracking or Strength Trainer live session).
- Strain Target sheet (81, white sheet, LEGACY, still embedded in the 2026 Strain Target article):
  - "STRAIN TARGET" with a toggle
  - Draggable ring "ACTIVITY STRAIN 10.3 OVERREACHING" with a "W" knob, reset icon, and dashed "OPTIMAL" range outside the ring
  - Coaching text, "TRAINING STATE: OVERREACHING", red "START ACTIVITY"
- Live Activities (TEXT-ONLY): lock-screen and Dynamic Island show live HR, HR zone, duration, distance, speed/pace during an activity started with "+"; WHOOP Live overlays HR, Day Strain, Recovery or Sleep on photos and videos.

### 3.7 Daily Outlook / Day in Review (AI). CONFIRMED for Daily Outlook (37), pills (06, 90)
- Full-screen sheet with a warm-grey → slate gradient background.
- Header: "✕" · "DAILY OUTLOOK" + "BETA V2.0" pill · history (clock-arrow) icon.
- Message from the W avatar (gradient ring):
  > "Good morning, Kristen! It's a great day to focus on your fitness goals. **Key Insights:** • Your **87% Recovery** is above your **7-day average of 81%**, supported by your **79% Sleep Performance** and no alcohol last night. • You're on a **5-day streak** of avoiding Device in Bed! This has a **Recovery Impact**… • Of your **131 active minutes** this week… were in **Zones 1-3**, **45%** were in… **Recommendations:** Functional Fitness…"

  Bold is used for numbers and metric names.
- Day in Review (TEXT-ONLY content): an end-of-day recap of key metrics and behaviors, plus bedtime guidance.

### 3.8 WHOOP AI (Coach) chat, My Memory, proactive check-ins
- Chat (72b, 2024-25 "WHOOP COACH · BETA"):
  - Header title with a new-chat icon (speech bubble) at top-right
  - User message in a grey rounded bubble
  - AI answer as plain text with bullets (e.g. "Cycling for 24 minutes, Swimming for 12 minutes, Functional Fitness for 18 minutes")
  - Horizontal **suggestion chips** above the composer ("Can you explain the concept of zone 2 training?", "How can I…")
  - Composer: "+" new-chat button at left, and an "Ask me anything" rounded field with an ↑ send button
  - Old-overview text field: "Ask WHOOP anything" (20d)
- 2026 additions (TEXT-ONLY):
  - Microphone icon in the text field (voice logging)
  - Trend charts generated in chat ("make it 90 days", "group it by week")
  - Add, edit or delete activities from chat
  - Jet-lag push ("welcome to the city")
  - In-context "ask" entry points on every screen
- **My Memory** (TEXT-ONLY): opened from the profile. Seven categories: **Goals, Identity, Lifestyle, Preferences, Events, Health History, Mood**. View, add, edit, remove; turn memory off.
- Proactive notification (38): iOS banner with the WHOOP app icon (black W tile). Bold title "Stay ahead of today's work day", timestamp "18:44 PM", body "You shared that work has been stressful, Taylor. Take a few minutes now—meditation or a light walk—to stay steady and focused. 💼".

### 3.9 Health tab (overview). TEXT-ONLY; layout UNCONFIRMED
Contents by membership:
- Live heart rate (One)
- Hormonal Insights (all, opt-in)
- Healthspan (Peak/Life, 18+)
- Stress Monitor and Health Monitor (Peak/Life)
- Blood Pressure Insights and Heart Screener (Life; Heart Screener region-limited)

Locked features appear **greyed out**. Card styles likely mirror the Heart Screener card (11b/30: "HEART SCREENER · TAKE AN ECG ›", "LAST ECG REPORT", "Normal Sinus Rhythm", green date chip "✓ Jan 14, 2024 - 7:42am", 3D heart illustration at right) and the Healthspan card (40: "HEALTHSPAN / PACE OF AGING 0.8x / ▼ slower vs. last week" + orb "29.9 WHOOP AGE" + notched strip "4.7 Years Younger vs. Actual Age").

### 3.10 Health Monitor. CONFIRMED (58 left phone, 98, 65, 82 legacy, 80)
1. "‹ HEALTH MONITOR".
2. "HEART RATE" section: blue heart icon, "**89** BPM", "Zone 0", a 5-dash zone indicator, and a live HR line with blue glow on a faint grid.
3. 2-column grid of metric tiles (r≈12, bg `#2D3134`/`#292D30`; heart icon `#0094E8`). Each tile: icon + caps label (may wrap to 2 lines) + big value + small unit + status chip.

| Tile | Value | Chip |
|---|---|---|
| RESPIRATORY RATE | 14.1 rpm | "✓ within 13.8 - 14.8 rpm" |
| BLOOD OXYGEN | 96 % | "✓ within 94…" |
| RHR | 58 bpm | "✓ within 48 - 74 bpm" |
| HRV | 72 ms | "✓ within 68…" |
| SKIN TEMP (FROM BASELINE) | -0.7°F | "✓ within -0.8 - 0.6°F" |

4. Share Health Report (legacy 82 shows "SHARE YOUR HEALTH REPORT →"). The PDF (80) is white with "JOHN DOE · 30 DAY HEALTH REPORT" and respiratory-rate and resting-HR charts with a 6-month personal range band.

Rules: green check = within or near the typical range; orange or red "!" = outside the range (65 shows TEMP with an orange "!" square). Compact summary row (65): RESP · SPO2 · RHR · HRV · TEMP, each with a ✓ or ! square.

### 3.11 Stress Monitor. CONFIRMED (58 right phone, 11m, 11n, 64, 19); flow detail LEGACY 2024 (20a-c)
1. "STRESS MONITOR" + gear; "‹ TODAY ›".
2. Gauge (0.0-3.0) with a white needle; "**1.5**" big; "**MEDIUM**" teal; "Last updated 3:05pm"; (i).
3. Intraday chart:
   - Line coloured by level
   - Vertical blue translucent bands for activities, with activity icons on top (runner, gauge/timer, a numeric "3")
   - A green dot at "now" with a dashed now-line
   - Zoom-out magnifier button
   - X axis "7:00am … 11:00am … 3:05pm" (3:05pm bold)
4. Coach card ("…signaling low stress. This indicates …cular system is stable, calm, and … state. … WHOOP Coach").
5. LEGACY 2024 lower sections, likely still present:
   - "TOTAL DAY — FRI, JAN 5 STRESS VS. TYPICAL FRIDAY" stacked bar, then Low / Medium / High time totals with ▲▼ % chips
   - "SLEEP STRESS" explainer
   - "SEE TRENDS →"
   - "SESSIONS WITH DR. ANDREW HUBERMAN" cards (Increase Relaxation / Increase Alertness, "Guided Breathing") → session details (Breathing rate BASIC, Duration 1 min, video preview) → "START EXERCISE"
   - Breathing animation: orange ring on inhale ("Inhale through the nose"), blue on exhale ("Exhale slowly through the mouth and empty your lungs")
   - "FINISH SESSION" → "END & SAVE" / "DISCARD SESSION" → "SAVED ✓"
   - "HOW IT WORKS · HIDE ✕" education cards

Home tile: "STRESS MONITOR ›" with "TODAY'S HIGH STRESS 2:15 hrs" and a chip "▼ vs. typical Tue" (64) or "+ vs. typical Tuesday" (11n), plus a mini gradient line.

### 3.12 Healthspan. CONFIRMED (54, 58, 59, 60, 61, 73, 27, 40, 11e)
1. "‹ HEALTHSPAN" with sub "Next update in 6 days"; (i).
2. Week pager "‹ AUG 19 - AUG 26 ›".
3. **WHOOP Age orb**: a large circle (~230 pt) of glowing green particles on black, with a thin green rim. Inside: "**29.9**" / "WHOOP AGE" (grey caps) / "**4.7** years younger" (green).
   - Scrolled/compact header variant: a small orb centred between "4.7 / YEARS YOUNGER" (left, green value) and "0.8x / PACE OF AGING" (right).
4. "PACE OF AGING" scale:
   - "○ Slow" (smooth blob icon) … "Fast" (spiky blob icon)
   - Value above the indicator (e.g. "0.8x")
   - Dense vertical tick "comb" from -1.0x through 1.0x to 3.0x; ticks brighten near the white indicator line
5. Notched insight card: "**Steady and Healthy** — Your WHOOP Age is younger and your Pace of Aging is slow, thanks to your VO2 Max. You're doing well, continue your current habits to keep this steady Pace of Aging. **VIEW YOUR PLAN →**".
6. "**Sleep**" section (22 pt) with legend "▼ 6 Month avg. | ▲ Age Impact".
   - Expandable "SLEEP CONSISTENCY ⌄" card ("68%")
   - Then Strain and Fitness pillars (TEXT-ONLY)
   - Nine metrics: sleep consistency, hours of sleep, steps, time in HR zones 1-3, time in zones 4-5, strength activity time, VO2 Max, RHR, lean body mass
7. "PACE OF AGING TREND ›" card (73): line chart -1.0x…3.0x with a 1.0x reference line and the current point labelled "0.8x". Caption: "Your Pace of Aging slowed, which means the habits you're building are boosting your healthy years."
8. 2026: each pillar lists the related **Advanced Labs biomarkers** with Optimal / Sufficient / Out of Range status and last-updated date. Markers expire after 90 days.

Unlocks after 21 recoveries in 31 days; updates weekly.

### 3.13 Heart Screener (ECG). CONFIRMED (53, 74, 75, 11b, 41, 63)
1. "✕ HEART SCREENER".
2. "**Electrocardiogram (ECG)**" (22 pt) + (i). Grey body: "Take an ECG reading any time as part of a routine heart health check-in or if you experience symptoms."
3. Purple button "**+ TAKE A NEW ECG READING**".
4. Card "✅ Your Last ECG Report ›" with sub "Normal Sinus Rhythm - 2 hours ago" and a purple ECG trace over dashed gridlines that fades out at the right.
   - Inner darker list with green check squares: "AFib not detected", "High Heart Rate not detected", "Low Heart Rate not detected", "Normal Sinus Rhythm detected".
5. History rows: "✓ Normal Sinus Rhythm · Jan 14, 2024 - 7:42am ›". 63 adds an "ALL REPORTS ›" row.
6. ECG reading screen (75):
   - Title "ECG READING", grid background
   - Purple heart "**86** bpm"
   - Illustration of fingers pinching the band clasp
   - Countdown "**30** SEC"
   - Progress bar with a purple fill

### 3.14 Blood Pressure Insights. CONFIRMED (55, 59, 83, 87)
1. "‹ BLOOD PRESSURE INSIGHTS" + "BETA V1.0 (i)" pill.
2. Three-segment arc gauge (green / yellow / orange) with a white needle.
   - "TODAY'S READING" (2025) or "TODAY'S ESTIMATE" (2026), then "**118/78**"
   - "SYSTOLIC 108–128 mmHg" and "DIASTOLIC 73–83 mmHg" (later 92-103)
3. "W | M | 6M" segmented control + "‹ MAR 1 - MAR 7, 25 ›".
4. Legend: "— MANUAL VALUE/READING" and "WHOOP ESTIMATE" (capsule icon).
5. Chart:
   - "Highest" (orange) and "Lowest" (green) labels
   - Per-day vertical grey range capsules with coloured tick marks (green or yellow)
   - Days "Sat 3 … Wed 7"

Calibration: log a cuff reading in-app to unlock. Daily morning estimate.

### 3.15 Hormonal Insights: Menstrual Cycle Insights / Pregnancy. CONFIRMED (56, 85, 11f, 78, 99)
1. Purple gradient header area. "✕ MENSTRUAL CYCLE INSIGHTS" with a gear.
2. "**Cycle Day 23** | **Luteal Phase**" (phase in purple). Sub "Next period in: 5-7 Days".
3. Month pager "‹ APRIL ›"; weekday header "MON … SUN".
4. Calendar rows as continuous phase-coloured bands with rounded ends at phase changes:
   - Menstrual days have coral circles on a darker coral band
   - Today has a white ring outline
   - Future days are dimmed
   - White dots below dates = symptoms
5. Legend: ● Menstrual · ● Follicular · ● Ovulatory · ● Luteal · ● Symptoms.

2026 additions (TEXT-ONLY):
- Symptom Insights and Predictions (Feb)
- Cycle-phase lab reference ranges (Mar)
- Natural Cycles connection (Aug)

Pregnancy Insights (TEXT-ONLY): weekly guidance, HRV and RHR trends, postpartum, due-month Community team.

Enable via Home, the Health tab, or More → App Settings → Hormonal Insights.

### 3.16 Sleep Planner / Tonight's Sleep / haptic alarm. CONFIRMED (31, 67, 90); LEGACY 48
Planner sheet (31):
- "TOMORROW I WANT TO:" with an outlined pill selector "**IMPROVE MY SLEEP**" (other goals: Peak 100% / Perform 85% / Get by 70%, TEXT-ONLY; legacy radios in 48)
- "**11:15** pm / SUGGESTED TIME TO BED" and "**7:05** am / YOUR SET WAKE TIME"
- "TIME IN BED" bar: hatched segment between white ticks, with a centre capsule "8:25" (black with white outline)
- Dashed bracket "OPTIMAL 11:30 pm - 7:30 am" in blue-grey
- Behind it: an "ALARM" row with a green toggle

Alarm modes (TEXT, legacy screens 48): **Exact Time**, **Sleep Goal**, **In the Green**. Haptic wake; "SAVE & SET ALARM".

Home summary card: see 3.1 (TONIGHT'S SLEEP).

### 3.17 Trend View (generic). CONFIRMED (34, 96)
1. "✕ TREND VIEW" (or plain title).
2. Metric dropdown card "[icon] STEPS ⌄".
3. "AVERAGE" caps + big value ("12,156", "54 %") + chip "▲ 8% past week".
4. "W | M | 6M" segmented control + range pager.
5. Insight sentence ("You've met your step goal for the last two days, keep crushing it.").
6. Chart:
   - Weekly: bars with value labels
   - 6M: faint daily line plus monthly-average horizontal segments with labels (55%, 51% "-7%" orange, "+8%" green)
7. Breakdown, e.g. "RESTORATIVE % BREAKDOWN (DAYS)" stacked bar with legend "150x HIGH (>45%) · 25x SUFFICIENT (30-45%) · 4x LOW (<30%)".

Metrics with Trend Views (WHOOP list, 2026):
- **Sleep**: Sleep Performance, Hours vs. Need, Time in Bed, Sleep Consistency, Restorative Sleep (%), Restorative Sleep (Hours), Efficiency, Sleep Debt
- **Strain**: Day Strain, Strength Activity Time, Calories Burned, Average HR, Steps, HR Zones 1-3, HR Zones 4-5, VO2 Max
- **Recovery**: Recovery Score, RHR, HRV, Respiratory Rate
- **Other**: Exercise Progress (Strength Trainer), Body Composition, Weight, Total Day Stress, Sleep Stress, Non-Activity Stress

### 3.18 Weekly Plan / My Plan. CONFIRMED (33)
Sections "SLEEP", "STRAIN", "ACTIVITIES", "BEHAVIORS", each with a right-aligned "EDIT ✏". Goal cards:
- "**85%+ SLEEP PERFORMANCE**" with "Avg. 82%" and a check circle
  - Day row MON-SUN with status circles: completed = blue check, missed = ✕, neutral = –, future = dashed circle
  - Bar chart of daily values (sleep blue; below-goal days dimmer) with value labels and a dashed "GOAL" line with a white "GOAL" tag
  - The current day column is highlighted
  - Footer: "Average at least 85%+ Sleep Performance to complete this goal."
- "**16.0+ DAY STRAIN**" with "Avg. 19.5": blue bars; "Reach 16.0+ Day Strain at least 4 days this week to complete this weekly goal."
- Activities rows ("Meditation 2/4", "Running 1/4", "Cycling 2/4") with day circles.
- Behaviors rows with photo backgrounds ("Hydration 1/5", "Morning Sunlight 4/7").

Presets: **Sleep Deeper** (Sleep Consistency, Sleep Performance, Avoid Late Meal), **Boost Fitness** (HR Zones 4-5, Protein Intake, Strength activity), **Feel Better** (Steps, Hydration, Recovery activities), or a Custom Plan built with WHOOP AI. 2026 adds a Strength Activity Time goal. Weekly summary at the end of each week: Continue / Switch / Customize.

### 3.19 Journal + Behavior Insights / Trends. CONFIRMED (76, 77, 28, 97, 43, 11i)
- Daily questions (76, 2026): rows on a dark translucent card with a gradient border. Question text ("Did you keep your wind-down phone free?", "Slept in a dark room?"), an optional "Custom" chip, and ✕ / ✓ buttons (✓ filled blue when selected).
- Customize Journal bottom sheet (97):
  - Grabber, "CUSTOMIZE JOURNAL" with ✓ (done)
  - Horizontal caps category tabs with an underline: RECOVERY, REPRODUCTIVE HEALTH, SLEEP, STATUS, SU…
  - Items: title + grey question, with a ⊕ outline add button or a filled teal check circle when added. Some show a toggle preview ("Nursing / Not Nursing").
- 300+ behaviors; Time and Quantity fields; voice and text logging via WHOOP AI (2026); AI suggests behaviors to add or remove.
- **Behavior Insights / Impacts** (77):
  - Header row "▼ **HURTS**" (orange chip) · "% IMPACT" · "**HELPS** ▲" (green chip)
  - Rows (CAPS label + coloured %): READ IN BED +12%, 81%+ SLEEP PERFORMANCE +9%, WORK LATE 0%, CAFFEINE -9%, ALCOHOL -13%
  - Each row has a centred-zero impact bar
  - Unlocks after 5 "yes" + 5 "no" in 90 days
- Behavior Trends (TEXT-ONLY): calendar views of when and how often each behavior is logged; streaks and gaps.

### 3.20 Strength Trainer. CONFIRMED (36); 2026 features TEXT-ONLY
- Live workout:
  - Title "MORNING ROUTINE" + elapsed "00:12:34"
  - Tabs "LIVE SESSION | EXERCISES" (underline on the selected tab)
  - Exercise cards with photo thumbnail, name ("Bench Press - Barbell"), "3 Sets", drag handle "="
  - Expanded set table "SET · REPS · WEIGHT (lbs)" with input boxes; the active set is in teal with a left accent bar; "− +" buttons; trash icon
- Overlays:
  - "Bench Press - Barbell / 3 Sets (teal) / 4,876 lbs TONNAGE · 24 REPS"
  - "TONNAGE BY SET" blue bar chart, "TOTAL TONNAGE 19,076 lbs"
  - "CARDIO 25% | MUSCULAR 75%" split bar
- 2026 (TEXT-ONLY): Exercise Details page (volume, history, personal records); AI workout generation; AI exercise linking; passive muscular load for 25+ activities; Strava export with muscle map.

### 3.21 VO2 Max. PARTIAL (29)
Card "VO₂ MAX" with the value "64" above a white ▼ marker. Segmented percentile scale: grey `<35`, 35, 40, 45, 50+ (coloured top borders and labels). Category text "…ior (>49 mL/kg/min)" (likely "Superior"). Age and sex percentile. Weekly (Tuesday) update. Manual lab entry. Weight update.

### 3.22 Steps. CONFIRMED in Trend View (34)
Steps appear as a My Dashboard tile. Daily, weekly, monthly and 6-month trends. A step goal can be set in Weekly Plan.

### 3.23 HR Zones. CONFIRMED (95, 11d, 42)
Zone rows as in 3.5. Zones use Heart Rate Reserve (2024). Manual max-HR and zone-bound edits under More → App Settings → Activity Settings → Heart Rate Settings.

### 3.24 Advanced Labs. CONFIRMED marketing tiles (35, 79, 94)
- Segmented ring "60+ / BIOMARKERS TESTED": tick segments green (optimal), grey (sufficient), orange (out of range).
- Counts row: "48 ✓ Optimal · 5 ✓ Sufficient · 7 ! Out of Range".
- Biomarker rows: name ("High-sensitivity C-reactive protein (hsCRP)"), value + unit ("3.2 mg/L"), status chip.
- 2026 (TEXT-ONLY): Specialized Panels ($299: Heart Health, Performance, Metabolic, Women's Health, Men's Health); Galleri test; labs without a wearable; clinician review; cycle-phase reference ranges.

### 3.25 Profile / More / Settings. TEXT-ONLY (no WHOOP image)
See section 2. Legacy 2020 text: "performance profile… data streaks, 30-day averages, all-time highs and lows… by clicking on your profile photo in the upper-left corner of the home screen. All other menu options… under More."

### 3.26 Widgets and Live Activities. TEXT-ONLY
Three iOS widget types: Home Screen, Lock Screen and Live Activities.
- Lock Screen shows Sleep, Recovery, Strain and battery.
- Live Activities show HR, HR zone, duration, distance and pace on the Lock Screen and Dynamic Island when an activity is started from "+".
- The 2025 recap mentions "Enhanced iOS widgets put your key metrics — Sleep, Recovery, and Strain — right on your lock screen".

### 3.27 Performance Assessments. LEGACY
The in-app Weekly and Monthly Performance Assessments were reached via the old Plan/Coaching tab (2020-2024). The search snippet from support.whoop.com says they were removed in May 2025 and the MPA is now emailed (UNCONFIRMED on whoop.com). Legacy charts: 46 (light-theme report), 47.

---------------------------------------------------------------------------------------------------

## 4. 2026 "What's new" changelog (live page, published 2026-08-28; verbatim headings)

- **Aug 2026**
  - Galleri® multi-cancer early-detection test in Advanced Labs (Jul 30)
  - WHOOP connects with **Natural Cycles** (Aug 4)
  - Advanced Labs available **without a wearable** (Aug 18)
- **Jul 2026**
  - "Ask WHOOP for a chart of your trends" (Jul 29, AI-generated charts in chat)
  - "Log your Journal by voice or text" from the Journal page (Jul 29)
  - New HR algorithm; Strain may shift (Jul 6)
  - Edit activity timing on an HR graph, iOS (Jul 1)
- **Jun 2026**
  - Manage activities from chat (Jun 29)
  - Scrub the HR graph on Edit Activity (Jun 25)
  - Auto-merge fragmented activities within 60 min (Jun 23)
  - Connect health records with **HealthEx**; "Health Record Analysis" (Jun 17; More > App Settings > Integrations)
- **May 2026**
  - Deeper Strava integration (import and export; "Garmin Via Strava" attribution) (May 21)
  - Better auto-detect and auto-classify (May 20)
  - Strength Trainer per-exercise volume, history and PRs; Exercise Details page (May 20)
  - **Coaching that remembers / My Memory** (May 1)
- **Apr 2026**
  - Journal entries by voice and smarter behavior suggestions (Apr 30)
  - Muscular load for 14 outdoor activities (Apr 22)
  - Specialized Panels (Apr 16)
  - Shareable GPS activity snapshot (Apr 3)
- **Mar 2026**
  - Behavior Trends and Behavior Insights ("Open your Journal or Recovery and tap Insights") (Mar 25)
  - Labs with cycle-phase ranges (Mar 4)
  - AI links exercises after you lift (Mar 5)
  - Jet-lag coaching push (Mar 13)
- **Feb 2026**
  - Symptom Insights and Predictions (Feb 6)
  - AI meets Strength Trainer (Feb 10-18)
  - Strength Activity Time trend view and Weekly Plan goal (Feb 20)
  - HR accuracy (Feb 25)
- **Jan 2026**
  - Bloodwork linked to Healthspan pillars (Jan 15)
  - Passive muscular load for rucking and Solidcore (Jan 8)
  - 5 most-recent activity types when adding an activity; minimum auto-detect lowered to 10 min

Press 2026-05-08 (whoop.com press center):
- On-demand **clinician video consults** in-app (US, summer 2026)
- EHR sync (HealthEx)
- My Memory + **Proactive Check-Ins**
- Journal redesigned (voice/text, Behavior Trends)
- Roadmap: deeper integrations, HR algorithm, auto-detection, Strength Trainer trends and PRs

2025 launches (Locker year-in-review):
- Hardware and plans: WHOOP 5.0 / MG; One / Peak / Life tiers
- Health features: Advanced Labs (+ free lab uploads, Nov 2025); Healthspan; Heart Screener (ECG); Blood Pressure Insights; Women's Hormonal Insights; VO2 Max
- Coaching: new AI guidance (Daily Outlook, Day in Review)
- App: **redesigned Home + Health tab**; Sleep Performance with sleep stress; new staging algorithm; HR Reserve zones; Journal same-day entries; 140+ activities
- Profile and widgets: Profile (WHOOP Age, levels, streaks); enhanced iOS lock-screen widgets
- Training: Strength Trainer improvements; revamped Weekly Plan

---------------------------------------------------------------------------------------------------

## 5. Legacy UI seen on WHOOP pages (do NOT copy; for contrast)
- 2024 "Overview" home (20d):
  - Top tabs OVERVIEW / SLEEP / RECOVERY / STRAIN
  - Single central "W" ring with Recovery 81% (green, left), Strain 4.2 (blue, right), HRV 113, Sleep 65%
  - "Ask WHOOP anything" bar; Health Monitor row "5/5 METRICS WITHIN RANGE ✓"
  - Today's Activities; "KEY STATISTICS · CUSTOMIZE ✏"
  - Bottom tabs: Home, Plan, Community, More + floating "+"
- 2022 Strain screen (21), 2021-22 Activity Strain live screen (44), 2021 Health Monitor (82), 2021 Sleep Planner (48), 2018 WPA (47), MPA report (46), white Strain Target sheet (81).

---------------------------------------------------------------------------------------------------

## 6. Gaps / UNCONFIRMED
1. No WHOOP-owned image shows the **bottom tab bar**, the **Health tab overview**, **More/Settings**, **Profile**, the **My Memory** screen, the **Community** tab, **widgets / Live Activities**, the **WHOOP AI chat in its 2025-26 form**, **Day in Review** contents, the **Journal main screen**, **Pregnancy** UI, **Steps tile**, **VO2 full screen**, or the **My Plan card on Home**. The tab bar is known only from third-party screenshots (90-92).
2. Whether Weekly Plan still has a dedicated "Plan" tab (one article says yes; tab-bar screenshots say no).
3. Exact fonts. They look like Proxima Nova (text) and DIN (numerals); WHOOP does not state this.
4. Health Monitor and Stress Monitor tiles directly under the dials (video and 3p) versus WHOOP's text listing them in the Health tab and a "Stress Monitor trend" lower on Home.
5. Angular gradient on dial progress (2026 render only) versus solid (all other renders).
6. Exact Recovery lower-section layout; Sleep and Strain screens below the first fold; empty states (no data, still calibrating, strap disconnected). Only text: "Health Monitor appears once there's enough data for a baseline"; VO2 "shows how many recoveries are left until available"; Healthspan "unlocks after 21 recoveries in 31 days"; locked features "greyed out".
7. The Live Session ring tile (11c): which flow it belongs to.
8. True-black vs dark-slate background (91 vs 50/90).

## 7. Source URLs (public)
- https://www.whoop.com/us/en/thelocker/the-all-new-whoop-home-screen/ (+ video //videos.ctfassets.net/rbzqg6pelgqa/2T8bCp220SC5XJOWUPTQ82/…/WHOOP_AllNewHomeScreen_1000x1000_v3__1_.mp4)
- https://www.whoop.com/us/en/thelocker/2026-whats-new/
- https://www.whoop.com/us/en/thelocker/everything-whoop-launched-in-2025/
- https://www.whoop.com/us/en/ , /us/en/membership/ , /us/en/one/ , /us/en/peak/ , /us/en/life/
- https://www.whoop.com/us/en/thelocker/how-does-whoop-recovery-work-101/
- https://www.whoop.com/us/en/thelocker/how-does-whoop-strain-work-101/
- https://www.whoop.com/us/en/thelocker/strain-coach/
- https://www.whoop.com/us/en/thelocker/how-well-whoop-measures-sleep/
- https://www.whoop.com/us/en/thelocker/how-much-sleep-do-i-need/
- https://www.whoop.com/us/en/thelocker/healthspan/ , /thelocker/Healthspan-Data-Meets-Longevity/
- https://www.whoop.com/us/en/thelocker/introducing-stress-monitor-a-new-way-to-monitor-manage-stress/
- https://www.whoop.com/us/en/thelocker/introducing-strength-trainer-a-new-way-to-quantify-the-impact-of-your-strength-training/
- https://www.whoop.com/us/en/thelocker/how-whoop-measures-muscular-load/
- https://www.whoop.com/us/en/thelocker/the-whoop-journal/
- https://www.whoop.com/us/en/thelocker/a-new-way-to-see-insights-on-which-behaviors-affect-your-recovery/
- https://www.whoop.com/us/en/thelocker/my-memory-whoop/
- https://www.whoop.com/us/en/thelocker/new-ai-guidance-from-whoop/
- https://www.whoop.com/us/en/thelocker/set-and-reach-your-goals-with-weekly-plan/
- https://www.whoop.com/us/en/thelocker/track-progress-with-new-trend-views/
- https://www.whoop.com/us/en/thelocker/estimate-your-vo-max-with-whoop-/
- https://www.whoop.com/us/en/thelocker/start-tracking-steps-with-whoop/
- https://www.whoop.com/us/en/thelocker/max-heart-rate-training-zones/ , /more-personalized-heart-rate-zones-with-whoop/
- https://www.whoop.com/us/en/thelocker/health-monitor-feature/ , /metric-blood-oxygen-monitoring/
- https://www.whoop.com/us/en/thelocker/heart-screener/ , /blood-pressure-insights/
- https://www.whoop.com/us/en/thelocker/whoop-feature-menstrual-cycle-coaching/ , /whoop-features-support-reproductive-health-through-all-life-stages/
- https://www.whoop.com/us/en/thelocker/specialized-panels/ , /whoop-advanced-labs/
- https://www.whoop.com/us/en/thelocker/which-membership-is-right-for-you/ , /introducing-whoop-5-0-and-whoop-mg/
- https://www.whoop.com/us/en/thelocker/10-whoop-features-you-need-to-know/
- https://www.whoop.com/us/en/thelocker/what-is-restorative-sleep/
- https://www.whoop.com/us/en/press-center/whoop-expands-health-platform-with-on-demand-clinician-access-and-new-ai-features/
- https://www.whoop.com/us/en/press-center/whoop-launches-advanced-labs-uploads-us/
- Legacy: /thelocker/app-update-navigation-bar/ (2020), /monthly-performance-assessment/, /new-feature-weekly-performance-assessment/, /new-whoop-4-0-feature-sleep-coach-with-haptic-alerts/
- Third party (tab bar only): https://the5krunner.com/2025/10/15/whoop-homescreen-gets-a-revamp/

Fetch method note: whoop.com returns Cloudflare 403 to curl/WebFetch. Pages were read through `r.jina.ai` (markdown and HTML) or the Wayback Machine `web.archive.org/web/2027id_/<url>` (raw HTML; the latest snapshots are June 2026, so the live jina markdown was used for anything newer). In-article assets came from the Next.js flight data ("embedded-asset-block" nodes) and were downloaded directly from images/videos/downloads.ctfassets.net.
