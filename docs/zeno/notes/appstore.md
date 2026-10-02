# WHOOP official app: store listings research (App Store + Google Play)

Researched 2026-10-02 from public pages only (no logins). Everything below was measured or read off the
downloaded store images. Anything that is inferred and not visible is marked **UNCONFIRMED**.

Local images: `/Users/raghavrathi/Downloads/Whoop-Apps-Handover/whoop-reference/images/appstore/`
(private reference only; never commit these into the ZENO/NOOP repo).

---

## 0. TL;DR for the ZENO rebuild

1. **The look:** dark, near-black slate UI. Screen background is a vertical gradient from `#263137` at the top to
   `#101518` from mid-screen down. Cards are flat `#202528`–`#2C3034` rounded rects (about 12 pt radius) with no
   visible borders. White text, with grey `#8E9093`/`#BCBFC1` for secondary copy. Labels are ALL-CAPS bold and
   letter-spaced. Numbers use a tall condensed "DIN-like" face.
2. **Signature colours (sampled):** Recovery green `#19EC06`, Sleep steel-blue `#7BA1BB`, Strain blue `#0093E7`.
   Status colours are "good" teal-green `#00F19F`, "warning" orange `#FFA722` and "low/calm" light blue `#67AEE6`.
   The AI/Coach accent is a purple to cyan gradient, `#8272FF`/`#8A62FF` to `#59C3FF`/`#50D3FF`.
3. **Home (current iOS build in the App Store):**
   - The top bar has an avatar and a 🔥 streak pill, then a `‹ TODAY ›` date pill, then ⚡ battery % with a strap icon.
   - Below it sits the "WHOOP" wordmark and **3 equal ring dials: SLEEP %, RECOVERY %, STRAIN**, each labelled `LABEL ›`.
   - Then a stacked insight card ("Optimal Health" plus a ✓2 badge), and 2 half-width tiles: **HEALTH MONITOR**
     ("WITHIN RANGE 5/5 Metrics") and **STRESS MONITOR** ("1.5 MEDIUM 4:31pm").
   - Then **My Day** with a [+] button: a "Your Daily Outlook" gradient row, a **TODAY'S ACTIVITIES** card
     (activity chips plus "+ ADD ACTIVITY" and "⏱ START ACTIVITY") and **My Dashboard** with "CUSTOMIZE ✎"
     (metric rows: value, trend triangle and baseline).
   - The bottom bar is a **floating capsule** ("Community", "More" visible; the left items are hidden by the product
     render) plus a separate **floating W "Coach" button**.
   - The older build (Google Play and localized screenshots) shows a **docked 4-tab bar: Home · Health · Community · More**.
4. **Detail screens (Sleep / Recovery / Strain) all share one template:**
   - Nav bar: `‹`, `TODAY` and ⓘ.
   - A large ring with "WHOOP" + a huge value + an ALL-CAPS label.
   - A "speech-bubble" card (notch pointing up at the ring) listing 4 contributors (icon, CAPS label, value,
     trend/level) with a legend strip.
   - A gradient-bordered insight card with a gradient CTA ("DIVE INTO MY SLEEP →" and so on).
   - A section header ("Last Night's Sleep · EDIT ✎" or "Today's Activities").
5. **Other screens in the listing:** Healthspan / WHOOP Age, Advanced Labs, WHOOP Coach chat, Journal Insights
   (Recovery Impact Analysis), Menstrual Cycle Insights, Stress Monitor and Weekly Plan (localized listings only).
   The Play promo video also shows a "+" quick-action menu, Tonight's Sleep, Cardio Fitness/VO₂ Max and HR Zones.

---

## 1. Sources & listing metadata

### 1.1 Apple App Store (US)
- URL: https://apps.apple.com/us/app/whoop/id933944389 (developer page https://apps.apple.com/us/developer/whoop/id933944388)
- Name **WHOOP**, seller "Whoop Incorporated", bundle id `com.whoop.iphone`, adamId 933944389
- Category Health & Fitness (+ Lifestyle). The lockup subtitle reads "Health & Fitness", so no marketing subtitle is set.
- **Version 5.72.1, released Mon Sep 28 2026.** First release 2015-09-02.
- Size 517.4 MB. Requires iOS 17.0 or later. iPhone + iPad ("iosUniversal").
- Rating **4.8 ★ (83,256 ratings)**. Age 13+ (lookup API says 12+). Chart **#56 Health & Fitness**. Badge **"Medical Device · See Details"**.
- Languages: EN + 5 more (FR, DE, IT, PT, ES).
- Screenshot sets served:
  - iPhone 6.9" (1320×2868, 10 frames)
  - iPhone 6.5" (1242×2688 / 1284×2778, 10 frames, **same content** as 6.9")
  - iPad 13" (2752×2064, 1 frame)
  - No App Preview video on the App Store listing.
- English storefronts (us, gb, au, ca, in, ae, jp) all serve the identical EN set.
- Localized sets (DE, FR, ES, IT, PT-BR) differ in composition:
  - S1 shows the **older Home** with a docked tab bar.
  - There is no Advanced Labs frame.
  - S10 shows the **Weekly Plan / "My week recap"** screen, which is not in the EN set.

### 1.2 Google Play (US)
- URL: https://play.google.com/store/apps/details?id=com.whoop.android
- Short description: **"Your personalized fitness and health coach"**
- Rating **4.7 ★, 29.8K reviews (29,783), 1M+ downloads (1,257,463)**, "Teen" rating.
- Version string "5.471.0", updated **Sep 25, 2026**.
- 8 phone screenshots (1080×1920) and a feature graphic (1024×500, product shot of 5 bands, no UI).
- Promo video: YouTube `p9OWVHuTcNU`, title "App Store 2025", by WHOOP, 24 s. Its storyboard frames are saved (§5.14).

### 1.3 "What's New" / version history (App Store)
- Current: **Version 5.72.1, Sep 28 2026: "Various bug fixes and performance improvements"**
- All 25 entries in the visible history (5.50.0, Apr 27 2026, through 5.72.1) carry the same generic text
  ("…improvement" on 5.55.0). Cadence is weekly releases (5.72.1, 5.71.0, 5.70.0, 5.69.1, 5.68.2, 5.68.1, 5.67.0,
  5.66.0, 5.65.1, 5.64.0, 5.63.0, 5.62.0, 5.61.0, 5.60.0, 5.59.0, 5.58.0, 5.57.0, 5.56.0, 5.55.1, 5.55.0, 5.54.0,
  5.53.0, 5.52.0, 5.51.0, 5.50.0).
- Google Play "What's new": "Various bug fixes and performance improvements".

---

## 2. Image inventory (all viewed)

| Local file | Source | What it shows |
|---|---|---|
| `ios69-01-home-overview.png` | mzstatic `EN-iOS-6.9-1320x2868-Vertical-Frame-01.jpg` | **Home (current)**, headline "Better health starts with WHOOP" |
| `ios69-02-sleep.png` | `iOS-6.9-…Frame_02-SLEEP.png` | Sleep detail, "Understand your Sleep" |
| `ios69-03-recovery.png` | `…Frame_03-RECOVERY.png` | Recovery detail, "Understand your Recovery" |
| `ios69-04-strain.png` | `…Frame_04-STRAIN.png` | Strain detail, "Understand your Strain" |
| `ios69-05-healthspan.png` | `…Frame_05-HEALTHSPAN.png` | Healthspan / WHOOP Age, "Learn how daily habits impact your long-term health" + "*Some availability restrictions apply." |
| `ios69-06-advanced-labs.png` | `Frame_11_-_ADVANCE_LABS.jpg` | Advanced Labs, "Know yourself at the molecular level" |
| `ios69-07-coach.png` | `…Frame_06-COACH.png` | WHOOP Coach chat, "Get personalized answers to your health & fitness questions" |
| `ios69-08-journal.png` | `…Frame_07-JOURNAL.png` | Journal Insights, "Learn how your behaviors affect your Recovery" |
| `ios69-09-menstrual-cycle-insights.png` | `…Frame_08-MCI.png` | Menstrual Cycle Insights, "Go beyond period tracking" |
| `ios69-10-stress.png` | `…Frame_09-STRESS.png` | Stress Monitor, "Monitor and manage your stress" |
| `ios-01…ios-10-*.png` | 6.5" set (1242×2688 / 1284×2778) | Same 10 frames, slightly different scale (verified on a contact sheet) |
| `ipad-01-overview.png` | `EN-iPad-2752x2064-Horizontal-Frame-01.jpg` | **iPad Home**, the most complete Home view (My Dashboard visible) |
| `play-01.png` | Play screenshot 1 | **Home (older variant)**, "Unlock your potential with WHOOP", docked tab bar Home/Health/Com… |
| `play-02…08.png` | Play screenshots 2–8 | Sleep, Recovery, Strain, Healthspan, Coach, Journal Insights, MCI (same as iOS) |
| `play-feature-graphic.png` | Play feature graphic | 5 WHOOP bands (teal/yellow, white, black, grey knit, tan leather + gold), no UI |
| `loc-es-10-…`, `loc-de-10-…`, `loc-fr-10-…` | Localized App Store S10 | **Weekly Plan / weekly recap** screen (ES/DE/FR text) |
| `promo-video-storyboard-1..3.jpg`, `promo-video-key-frames-zoomed.jpg`, `promo-video-thumbnail.jpg` | YouTube storyboard of Play promo video | Low-res (320×180) frames: + menu, Tonight's Sleep, Cardio Fitness, HR Zones, etc. |
| `app-icon-1024.png` | App icon | Black square, thin white circle, white stylized "W" made of slanted strokes |

All iOS frames are **marketing composites**: a dark blue-grey gradient canvas, a white bold 2–3-line headline,
and a phone mock. In frames 02–10 the mock has **no status bar** and is cropped at the bottom. In frame 01 and the
iPad frame, product renders overlap parts of the UI (the tab bar's left side, the Daily Outlook icon and the
Stress tile).

---

## 3. Measurement method & scale
- Colours come from `Image.getpixel` on the lossless PNG downloads. Values are the median of a small region, or
  the most saturated pixel for thin strokes and text.
- Point conversion assumes a **393 pt-wide phone screen** (iPhone 15/16 class). This is confirmed on frame 01:
  the phone screen is 760 px wide and the status-bar "9:41" cap height is 23 px, both of which give 1.93 px/pt.
  - Frames 02–10 (6.9" set): phone screen x = 144…1174, i.e. 1031 px, so **1 pt ≈ 2.62 px**. These frames have no
    status bar, so the 393 pt assumption is **UNCONFIRMED** for them. If the mock were 430/440 pt wide, multiply
    every pt value by about 1.1.
  - Frame 01 (Home): **1 pt ≈ 1.93 px**. Play-01: 1 pt ≈ 1.29 px. iPad (13", 1032 pt wide): 1 pt ≈ 0.96 px.
- Font size is estimated as cap height ÷ 0.69, so it is approximate (±1 pt).
- Corner radius is a circular fit to the anti-aliased corner. iOS continuous corners make the curve look slightly
  longer.

---

## 4. Global design language

### 4.1 Colour palette (sampled hex → where)
| Role | Hex | Sampled from |
|---|---|---|
| Screen bg, top (gradient start) | `#263137` (`#273137`, `#283339`) | top of Sleep/Recovery/Coach/Home screens |
| Screen bg, upper-mid | `#1F282D` | Home, between top bar and wordmark |
| Screen bg, main (most of screen) | `#101518` – `#14191D` (`#111619`) | Home below dials; detail screens below the fold |
| Healthspan bg (darker, near-black) | `#030304` – `#060708` | Healthspan above/around orb |
| Card, standard (tiles/rows) | `#292D30` / `#2C3034` / `#282C2F` / `#2A2E31` | Home tiles, Journal rows, Activities card, Labs card |
| Card, darker (insight/coaching) | `#202528`, `#1C2124`, `#1D2225` | Home insight card, MCI coaching card, Stress "Total Day" card |
| "Contributors" card | gradient `#282C30` (top) → `#14191C` (bottom) | Recovery/Sleep/Strain bubble card |
| Legend strip / inset well | `#090C0D` – `#090B0D` | Sleep/Recovery/Strain legend strip |
| Hairline divider | `#3B3F42` (rows), `#2A2F32` (section rule) | Sleep rows, Labs "SPECIALIZED PANELS" rule |
| Ring track (unfilled) | `#353C40` (detail), `#2E353B` – `#32373B` (home dials) | Recovery/Strain/Sleep rings |
| **Recovery green** (ring) | **`#19EC06`** (`#18EB06`) | Recovery rings (home + detail) |
| **Sleep steel-blue** (ring) | **`#7BA1BB`** (`#7BA0BB`) | Sleep rings, sleep activity chip `#7CA1BB`, sleep band in stress chart |
| **Strain blue** (ring) | **`#0093E7`** (`#0092E7`) | Strain rings, strength activity chip `#0193E8`, activity band |
| Strain target band (track) | `#565A5D` – `#585D5F`, tick `#FFFFFF` | Strain rings |
| **Good / optimal / helps** | **`#00F19F`** (`#00F2A0`, `#01F19E`) | Sleep "Optimal" bars, HRV ▲, "HELPS", "+24%", "MEDIUM", WITHIN RANGE, stress line mid |
| **Warning / poor / hurts** | **`#FFA722`** (`#FFA721`, `#FFA922`) | "Poor" bars, RHR ▲, "HURTS", "-6%", high stress |
| Low / calm (stress low) | `#67AEE6` | stress gauge left end, low-stress line, "NEW" chip text/border |
| Neutral / sufficient | `#848586` (bar), `#8A8D8F` (▲), `#898B8D` (●) | Sleep "Sufficient", neutral trend markers |
| Inactive segment | `#3A3E41`, `#43474A` | 3-segment bars and indicators |
| Positive tile icon bg | `#224A41` (green-tinted square) | Home ✓ square and "1.5" chip |
| Hurts chip bg / Helps chip bg | `#39301F` / `#133B32` | Journal legend chips |
| Text primary | `#FFFFFF` | |
| Text secondary (body) | `#BCBEBF` – `#BFC0C4` | card body copy, coach replies `#BCBFC1` |
| Text tertiary (captions/eyebrows) | `#8D9093` – `#8F9396`, `#838484` | "REFRESHED DAILY", "Next update in 6 days", "Last updated 3:05pm" `#8A8C8E` |
| Disabled chevron | `#4E5559` – `#586063`, `#38393A` | date-nav ">" when on today |
| Wordmark grey (inside rings) | `#8E9194` | "WHOOP" above hero value |
| AI gradient: CTA text | `#8272FF` → `#59C3FF` (`#7290FF` → `#57C6FF`) | "DIVE INTO MY SLEEP →" etc. |
| AI gradient: insight card stroke (dimmed) | `#4D3D8C` → `#346F8C` | 1.5 pt border of insight cards |
| AI gradient: input border (full) | `#8A62FF` → `#50D3FF` (`#6C9CFF` mid) | Coach "Ask WHOOP anything" field |
| Coach avatar ring | `#68A5FF`/purple → `#59C2FF` | W avatar in chat |
| Coach button (Home) | bg `#3F3D54` → `#1C2A35`, ring `#7B7FFE` → `#5EB6FD`, inner `#23314C` | floating W button |
| Tab capsule | `#323C45` (top) → `#232A30` (bottom); labels/icons `#94979C` | floating tab bar |
| Docked tab bar (older) | bg `#13171B`, selected `#FFFFFF` + glowing top line, unselected `#898B8E` | Play-01 |
| Date pill | outer `#2D363B`, inner selected `#414A4F` | Home top |
| Streak flame | `#F8703E` | Home 🔥 |
| Strap-connected dot | `#00BC7A` | Home strap icon |
| Daily Outlook row | gradient `#505558`/`#726E65` (warm grey, left) → `#33414C`/`#394B59` (slate, right); chevron `#EFD299` | Home "Your Daily Outlook" |
| Primary button | `#FFFFFF` fill, `#000000` text | Labs "SELECT TESTING FREQUENCY" |
| Secondary button | `#414649` | iPad "+ ADD ACTIVITY" / "START ACTIVITY" |
| Chip "BETA V2.0" | `#50575C` bg, white text | Coach |
| Chip "Recommended" | `#314351` – `#37374F` bg, W icon ring `#59C1FE` | Labs |
| Chip "NEW" | bg `#33414D`, text + card border `#67AEE6` | Journal |
| Healthspan orb | particles `#00ECAE`, text `#05F0A2`, centre `#000305` | Healthspan |
| Advanced Labs glow | `#1D745F` (top-right teal glow), sunburst bars `#2D3238` – `#375458` | Labs |
| MCI header gradient | `#693A35` (top) → `#4E2F2C` → `#2A2021` → `#101518` | Menstrual Cycle Insights |
| MCI phase colours (legend) | Menstrual `#FF7765`, Follicular `#A4A3F1`, Ovulatory `#479AC2`, Luteal `#AC5AED` | MCI legend dots |
| MCI calendar strips | Menstrual `#BB5B4F`, Follicular `#5A5C84`, Ovulatory `#2C586D`, Luteal `#8047AE` (current) / `#5E3882` (future) | MCI calendar |
| Stress gauge | blue `#67AEE6` → green `#00F19F`/`#2CE58A` → orange `#FFA721`; inner tint e.g. `#1A5043` | Stress Monitor |
| Stress "typical" bars (dim) | `#426885`, `#0E8962`, `#8D6423` | Stress Total Day |
| Chart gridlines | `#2C3033` | Stress chart |

### 4.2 Typography (visual estimates)
- Families: running text is **visually consistent with Proxima Nova**: geometric-humanist, single-storey "y",
  2-storey "a". Numerals and score values look like **DIN-style condensed** (DIN Pro / DIN Next-like: flat
  terminals, narrow "1", tall digits). Both families are **UNCONFIRMED**. The "WHOOP" wordmark is a custom
  logotype (thin, wide, with the stylized slashed W).
- ALL-CAPS labels are bold/semibold with wide tracking (about +0.1 em; e.g. "HOURS VS. NEEDED" is 119 pt wide at
  about 11 pt).

| Style | Est. size (pt) | Weight | Case | Example |
|---|---|---|---|---|
| Hero score (detail ring) | 64–71 | Bold condensed numerals; "%" about 60 % of digit height | – | "75%", "85%", "14.2" |
| Gauge value (stress) | ~53 | Bold numerals | – | "1.5" |
| WHOOP Age value | ~41 | Bold numerals | – | "29.9" |
| Home dial value | ~29–30 | Bold numerals, smaller "%" | – | "80%", "14.2" |
| Large title (screen section) | ~20–21 | Semibold | Title Case | "Recovery Impact Analysis", "Get A Complete Health Picture", "Cycle Day 3" |
| Section header | ~20 (Home "My Day"), ~16–17 (detail "Last Night's Sleep") | Semibold | Title Case | "My Day", "My Dashboard", "Today's Activities" |
| Card title | ~15–19 | Semibold | Title Case | "Optimal Health", "Steady and Healthy" |
| Body copy | ~15 | Regular | Sentence | insight text, coach messages, user bubbles |
| Row metric value | ~15–17 | Bold numerals | – | "74%", "124", "+24%", "12,459" |
| Nav title | ~13 | Bold | CAPS tracked | "TODAY", "STRESS MONITOR", "JOURNAL INSIGHTS" |
| Row label / tile title | ~11–12 | Bold | CAPS tracked | "HEART RATE VARIABILITY", "HEALTH MONITOR", "HYDRATION" |
| CTA link | ~11 | Bold | CAPS tracked, gradient fill + → | "BREAK DOWN MY RECOVERY →" |
| Dial label | ~11 | Bold | CAPS tracked + "›" | "SLEEP ›" |
| Eyebrow / caption | ~10 | Bold | CAPS tracked, grey | "REFRESHED DAILY", "BETA V2.0" |
| Small caption | ~10.5–11 | Regular | Sentence, grey | "Next update in 6 days", "Last updated 3:05pm" |
| Chart axis labels | ~10–12.5 | Bold numerals, grey (current-time label white) | – | "3.0", "3:05pm" |
| Tab label | ~11 | Medium | Title Case | "Home", "Health", "Community", "More" |

### 4.3 Shapes, radii, spacing (at 393 pt width)
- Side margin: **16 pt**, on every screen (cards start 42 px in at 2.62 px/pt).
- Card radius: **about 12 pt** (fitted 12.0–12.4 pt on Journal rows, Labs card, MCI cards, Coach bubbles). Home
  tiles 11.7 pt, Home insight card about 12–15 pt. The legend strip is about 9–9.5 pt (30 pt tall).
- Buttons and chips:
  - White primary button: about 7 pt radius, 40 pt tall, full card width.
  - "Recommended" chip: about 8.5 pt radius.
  - "BIOMARKERS ›" pill: about 12 pt radius, 40 pt tall.
  - Home "+" button: about 31 pt square, about 6–7 pt radius.
  - Journal legend chips: about 4 pt radius.
  - Stress zoom button: about 8 pt radius.
- Insight card: **1.5 pt gradient stroke** (purple → teal, left → right), about 10 pt radius, no fill (shows the bg).
- Contributor card: about 12 pt radius with an **upward triangular notch** (about 16 pt wide) centred under the
  ring. It is a speech-bubble shape, filled with a top-to-bottom gradient (lighter top).
- Rings:
  - Detail hero ring: outer diameter about **260 pt**, stroke about **15 pt**, round caps; the arc starts at 12 o'clock and runs clockwise.
  - Home dials: diameter about **88 pt**, stroke about **5.7 pt**, centres 119 pt apart (about 31 pt gap).
  - iPad dials: about 114 pt diameter, centres about 326 pt apart.
  - The ring value scale is linear: 80 % ends at 289°, 85 % at 307°, Strain 14.2 of 21 at 242°.
- Row heights:
  - Contributor rows about 53 pt, separated by hairlines (inset 16 pt).
  - Journal behaviour cards about 55 pt with about 8 pt gaps.
  - MCI "Log period" card about 56 pt.
  - Home Daily Outlook row about 47 pt; Home tiles about 97 pt.
- Floating tab capsule: about **64 pt** tall, bottom about 21 pt above the screen edge. The Coach button is about
  **62 × 64 pt** (rounded square) with a gap of about 14.5 pt; its W ring is about 34 pt.

### 4.4 Recurring components
1. **Score ring (dial)**: the track is `#353C40`; the coloured arc has round caps.
   - Home: value only (+ small %), with "LABEL ›" below.
   - Detail: "WHOOP" wordmark (grey) above the value and the CAPS label below. Sleep adds a **3-segment level
     indicator** below the label (Poor/Sufficient/Optimal; the middle segment is lit for "sufficient").
   - The Strain ring has a lighter-grey **target band** on the track right after the arc end (≈14.1 → 15.8–16.2 of
     21) and a **white radial tick** at ≈14.6–14.7. Read as a Strain Target indicator: **UNCONFIRMED**
     (the Home card says "Strain target of 15.5").
2. **Contributor bubble card**: 4 rows of [line icon] + CAPS label + right-aligned value + indicator. The indicator
   is either a **3-segment level bar** (Sleep) or a **trend triangle ▲/▼ or ●** (Recovery/Strain). Under the rows
   sits a black legend strip, either "▬ Poor ▬ Sufficient ▬ Optimal" or "▲▼ **Today** vs. prior 30 days".
3. **Insight card ("Coach insight")**: gradient-stroke rounded rect holding 2–3 lines of white body text and a CAPS
   gradient CTA with "→" ("DIVE INTO MY SLEEP", "BREAK DOWN MY RECOVERY", "EXPLORE MY STRAIN", "VIEW YOUR WHOOP COACH
   ANALYSIS", "LEARN MORE WITH WHOOP COACH").
4. **Home insight card (stacked)**: solid `#202528` card with a title and grey body. At the top-right is a rounded
   badge (`#363B3E`) showing ✓ and the count "2". A second card peeks out beneath, so the cards are stacked or
   swipeable (**UNCONFIRMED** interaction).
5. **Half-width tiles**: CAPS title + "›". Beneath it, a ~22 pt rounded-square status icon (green-tinted bg
   `#224A41`) holding ✓ or the number "1.5", a CAPS green status word, and a grey sub-line.
6. **Section header row**: Title Case semibold on the left; on the right a white rounded-square "+" button
   (My Day), or "CUSTOMIZE ✎" / "EDIT ✎" as CAPS text with a pencil.
7. **Activity row chip**: a rounded-rect chip filled with the activity colour (sleep `#7BA1BB`, strength
   `#0093E7`) holding a white glyph and a bold value ("8:40", "13.3"). Then the CAPS activity name, then
   right-aligned start/end times stacked ("12:02 AM / 9:11 AM") with a thin vertical colour bar.
8. **Dashboard metric row** (iPad): [icon] CAPS name … a big value with a ▲/▼ coloured triangle and a smaller grey
   baseline value below it (e.g. "82 ▲ / 80").
9. **Date navigator pill**: `‹ [TODAY] ›`. The selected label sits in a lighter inner pill and the forward chevron
   is dimmed when on today. Detail screens use the plain form "‹ TODAY ›" or "‹ AUG 19 - AUG 26 ›".
10. **Chips**: "BETA V2.0" (grey), "(W) Recommended" (navy), "NEW" (blue text on navy, card gets a blue 1 pt border).
11. **Diverging impact bar** (Journal): hatched diagonal-stripe track with a centre dot (white dot in a black ring)
    at 0, and a coloured bar extending right (green, helps) or left (orange, hurts); grey when not significant.
12. **Tab bar**:
    - (a) **current**: a floating translucent capsule with icon + label items plus a separate floating
      rounded-square W Coach button with a purple-to-blue gradient ring (iOS 26 "Liquid Glass"-style).
    - (b) **older**: docked full-width bar `#13171B` with 4 items; the selected item is white with a short glowing
      line on the bar's top edge.

### 4.5 Iconography
Thin-stroke (about 1.5 pt) outline icons in grey `#8E9092`:
- Recovery contributors: HRV (pulse-line glyph), RHR (heart with a down arrow), Respiratory rate (lungs), Sleep
  performance (moon with bars).
- Sleep contributors: Hours vs. needed (moon + clock), Consistency (double crescent), Efficiency (bed with bars),
  High sleep stress (moon + lightning).
- Strain contributors: HR zones 1-3 / 4-5 (heart with fill levels), Strength (dumbbell), Steps (shoe).
- Navigation and controls: back `‹` (thin, white), ⓘ in a circle (grey outline), gear (settings), history (clock with
  a counter-clockwise arrow), and tab icons (house with a trend line, heart with ECG, three people, ☰).
- Activity glyphs on chips are filled white: moon (sleep), weightlifter (strength).

### 4.6 Navigation patterns seen
- Root: a tab bar (Home, Health, Community, More), with Coach on a dedicated floating button in the current build.
- Home dials have "›", so tapping one opens the matching detail screen (Sleep/Recovery/Strain detail, nav title "TODAY").
- Detail screens use a push navigation bar: `‹` back on the left, a centred CAPS title, and an optional right action
  (ⓘ info / ⚙ settings / ⟲ history). There are **no large titles**.
- Day paging uses the `‹ TODAY ›` pill (Home, Stress) and `‹ AUG 19 - AUG 26 ›` for weekly Healthspan.
- Home "+" (My Day) opens a **quick-action menu** (promo video): CREATE WHOOP LIVE · MY JOURNAL · STRENGTH BUILDER ·
  ADD ACTIVITY · START ACTIVITY, closed with "−".

---

## 5. Screen-by-screen

### 5.1 Home: current iOS build (App Store frame 01, 6.9" & 6.5")
Marketing headline: "Better health starts with WHOOP". Positions are pt from the top of an 852 pt screen.
1. Status bar 9:41.
2. **Top bar (y≈63–87 pt)**:
   - Left: a round avatar photo (about 28 pt), overlapped by a dark capsule (`#2F383D`) holding an orange flame
     🔥 `#F8703E` and **"355"** (streak/count; meaning **UNCONFIRMED**).
   - Centre: the **date pill** "‹ [TODAY] ›" (outer `#2D363B`, inner `#414A4F`; "TODAY" about 11 pt bold CAPS; the
     right chevron is dimmed).
   - Right: **"⚡ 65%"** and an outlined **strap icon with a green dot** `#00BC7A` (battery and connection).
3. **"WHOOP" wordmark** centred (white, about 12 pt cap height), y≈129 pt.
4. **Three dials** in a row (centres y≈202 pt; 88 pt diameter):
   - **80%** with **SLEEP ›** (arc `#7BA1BB`)
   - **85%** with **RECOVERY ›** (arc `#19EC06`)
   - **14.2** with **STRAIN ›** (arc `#0093E7`, target band and white tick at about 8 o'clock)
   - Labels are white, about 11 pt bold CAPS, tracked, with a small "›".
5. **Insight card** (y≈305–438 pt incl. stack): title **"Optimal Health"**, body *"Take advantage of your green
   Recovery by meeting your Strain target of 15.5. Your body is signaling it can take on significant exertion
   today."* At the top-right is a ✓ badge with "2"; a second card edge shows beneath.
6. **Two tiles** (y≈466–563 pt, 12 pt gap):
   - **HEALTH MONITOR ›**: ✓ in a green-tinted square, "WITHIN RANGE" in green CAPS, "5/5 Metrics" in grey.
   - **STRESS MONITOR ›**: "1.5" in a green-tinted square, "MEDIUM" in green CAPS, "4:31pm" in grey.
7. **"My Day"** header (about 20 pt semibold) with a white rounded-square **[+]** on the right (y≈595–626 pt).
8. **"Daily Outlook"** row (y≈643–690 pt). It has a warm-grey→slate horizontal gradient, a gold chevron "›", and a
   left icon hidden by the product render (a ☀ sun in the other variants). The visible text is "Daily Outlook";
   other variants say "Your Daily Outlook".
9. **"…VITIES"** card = **TODAY'S ACTIVITIES** (y≈707 pt+), with an expand icon ⤢ at the top-right and partial
   rows with times "10:0…", "6:5…", "8:20pm".
10. **Bottom bar**: a floating capsule (y≈767–831 pt) with "Community" (people icon) and "More" (☰). The left items
    are hidden by the product render; they are likely "Home" and "Health" (**UNCONFIRMED**, inferred from the item
    spacing and the Play variant). A separate floating **W Coach button** sits at the right (rounded square with a
    purple-blue glow ring).

### 5.2 Home: previous variant (Google Play frame 01; localized S1 frames)
Headline: "Unlock your potential with WHOOP".
1. Top bar: avatar (**no** streak pill) · "‹ [TODAY] ›" · "65%" + strap icon (**no** ⚡).
2. "WHOOP" wordmark.
3. Dials **75% SLEEP / 85% RECOVERY / 14.2 STRAIN** (labels **without** "›").
4. Insight card **"Building Fitness Gains"**: *"You're building fitness by entering your optimal Strain range. Keep
   pushing yourself towards your target of 15.5 to see even greater results."* with the ✓/2 badge and the stack
   effect.
5. Tiles HEALTH MONITOR › ("WITHIN RANGE 5/5 Metrics") and STRESS … (hidden).
6. **"My Day"** header; the next row has a **separate square W (Coach) button on the left** followed by
   "☀ Your Dai[ly Outlook] ›".
7. **TODAY'S ACTIVITIES** ⤢: Sleep chip "🌙 6:18" with "SLEEP" and "11:08pm / 5:34am".
8. **Docked tab bar** (about 56 pt + home indicator, bg `#13171B`):
   - **Home** (house with trend-line icon, white, with a glowing indicator line at the bar's top edge)
   - **Health** (heart with ECG icon, grey)
   - **Com[munity]** (hidden)
   - 4th item ☰ (More, partly visible)

### 5.3 Home: iPad (App Store iPad frame)
1. Status bar "9:39 AM Tue Aug 12".
2. Top: centred date pill **"‹ TUE, AUG 12 ›"** (date format "TUE, AUG 12"); right side "65%" + strap icon. No
   avatar is visible on the left.
3. "WHOOP" wordmark; dials **89% SLEEP › · 83% RECOVERY › · 14.2 STRAIN ›** spread across the width.
4. **My Day [+]**, then **"☀ Your Daily Outlook ›"** (gradient row).
5. **TODAY'S ACTIVITIES ⤢** card (`#32393F`):
   - Row 1: "🌙 8:40" chip (`#7CA1BB`), **SLEEP**, "12:02 AM / 9:11 AM", with a blue-grey bar.
   - Row 2: "🏋 13.3" chip (`#0193E8`), **STRENGTH TRAINING**, "10:18 AM / 11:21 AM", with a blue bar.
   - Two buttons: **"+ ADD ACTIVITY"** and **"⏱ START ACTIVITY"** (grey `#414649`, half width each).
6. **"My Dashboard"** header with **"CUSTOMIZE ✎"**. The rows (card `#2C2F34`):
   - **HEART RATE VARIABILITY 82 ▲(green) / 80**
   - **RESTING HEART RATE 50 ▲(orange) / 49**
   - [name hidden] **2,714 ▼(orange) / 11,444** (probably Steps or Calories; **UNCONFIRMED**)
   - [name hidden, ends "…Y)"] **1:57 ▼(orange) / 2:26** (**UNCONFIRMED**)
   - a 5th row "0:1…" partly hidden.
7. Floating capsule (… Community, More) plus the floating W button. The bottom-left is hidden by a band.

### 5.4 Sleep detail (frame 02)
1. Nav: `‹` · **TODAY** · ⓘ.
2. Hero ring (sleep blue, 75 % arc). Inside: "WHOOP" (grey), **75%**, **SLEEP / PERFORMANCE** (2 lines CAPS),
   and a 3-segment indicator (middle lit `#848586`).
3. Bubble card with 4 rows (icon, CAPS label, 3-segment bar, value):
   - HOURS VS. NEEDED: [▭ ▬grey ▭] **74%**
   - SLEEP CONSISTENCY: [▬orange ▭ ▭] **45%**
   - SLEEP EFFICIENCY: [▭ ▭ ▬green] **98%**
   - HIGH SLEEP STRESS: [▭ ▭ ▬green] **0%**
   - Legend strip: "▬ Poor ▬ Sufficient ▬ Optimal" (orange/grey/green).
4. Insight card: *"Your Sleep Performance is sufficient, but there's room to improve - Sleep Consistency could use
   attention to help you get to optimal sleep."* CTA **DIVE INTO MY SLEEP →**.
5. **"Last Night's Sleep"** header with **"EDIT ✎"**. The promo video shows a card below it, **"HOURS OF SLEEP
   8:44"** with ⓘ (low-res).

### 5.5 Recovery detail (frame 03)
1. Nav: `‹` · **TODAY** · ⓘ.
2. Ring (green, 85 %): "WHOOP", **85%**, **RECOVERY**. There is no level indicator.
3. Bubble card:
   - HEART RATE VARIABILITY **124 ▲green**
   - RESTING HEART RATE **49 ▲orange**
   - RESPIRATORY RATE **14.5 ▲grey**
   - SLEEP PERFORMANCE **74% ●grey**
   - Legend: "▲▼ **Today** vs. prior 30 days".
4. Insight: *"Your HRV is elevated while your RHR, Respiratory Rate, and Sleep Performance are all typical, resulting
   in a higher Recovery today."* CTA **BREAK DOWN MY RECOVERY →**.
5. Header **"Today's Activities"**.

The triangle colour means good or bad direction (a rise in RHR is orange), and grey means within the normal range.

### 5.6 Strain detail (frame 04)
1. Nav: `‹` · **TODAY** · ⓘ.
2. Ring (blue to 242°): "WHOOP", **14.2**, **DAY STRAIN**. The lighter band covers 242°→278° and the white tick sits
   at about 251°.
3. Bubble card:
   - HEART RATE ZONES 1-3 **1:05 ▲green**
   - HEART RATE ZONES 4-5 **0:23 ▲green**
   - STRENGTH ACTIVITY TIME **0:35 ▼orange**
   - STEPS **12,459 ▲green**
   - Legend: "Today vs. prior 30 days".
4. Insight: *"Strain between 14.0 and 17.9 is considered strenuous, meaning your cardiovascular system has been
   working hard."* CTA **EXPLORE MY STRAIN →**.
5. Header **"Today's Activities"**.

### 5.7 Healthspan / WHOOP Age (frame 05)
1. Nav: `‹` · **HEALTHSPAN** with the subtitle "Next update in 6 days" (grey, about 10.5 pt) · ⓘ.
2. Week navigator **"‹ AUG 19 - AUG 26 ›"** (the forward chevron is dimmed).
3. Background is near-black (`#030304`).
4. **Particle orb**: about 320 pt circle, a thin teal rim, and bokeh particles `#00ECAE` dense near the rim with a
   dark centre. Centre text: **29.9** (about 41 pt), **WHOOP AGE** (CAPS, `#B3B2B3`), **"2.3 years younger"**
   (green `#05F0A2`, the number bold).
5. **PACE OF AGING** (CAPS label). Below it a row: "◯ Slow" (grey dot, left), **0.8x** (centre, bold), and
   "Fast" with a blob icon (right).
6. Tick-mark scale: dense vertical ticks (`#404446`) with a white needle at 0.8x; the ticks near the needle are
   brighter. Labels "-1.0x · 1.0x · 3.0x".
7. Bubble card (notch up toward the needle): **"Steady and Healthy"** / *"Your Pace of Aging slowed by 0.4x this
   week, mostly due to positive changes in your VO₂ Max. Continue your current habits to keep lowering your WHOOP
   Age."* CTA **VIEW YOUR WHOOP COACH ANALYSIS →**.

### 5.8 Advanced Labs (frame 06; EN only)
1. Nav: `‹` · **ADVANCED LABS** (no right action).
2. Teal glow in the top-right (`#1D745F`) over a dark bg.
3. A radial **sunburst of about 72 short bars** around a centre that reads "WHOOP" / "ADVANCED LABS" (light CAPS)
   with the pill button **"BIOMARKERS ›"**.
4. Heading **"Get A Complete Health Picture"**, body *"Baseline your health with the Comprehensive Health Panel, or
   explore health domains with Specialized Panels. Up to 122+ biomarkers. HSA/FSA eligible."*
5. Card `#2A2E31`:
   - About 64 pt square thumbnail (red abstract art with a test-tube label).
   - Chip **"(W) Recommended"**, title **"Comprehensive Health Panel"**, sub *"75-biomarker foundational health
     check. Starting at $150/test."*
   - Full-width white button **SELECT TESTING FREQUENCY**.
6. Section rule **"SPECIALIZED PANELS"** followed by a hairline.
7. List row: thumbnail (pink/blue art), **"Female Health Panel"**, *"Get in-depth insights into your body — from
   hormones and fertility to bone health and libido."*, **"$299 | 81 biomarkers tested"**, and "›".

### 5.9 WHOOP Coach (frame 07)
1. Nav: `‹` · **WHOOP COACH** with chip **BETA V2.0** · history icon ⟲.
2. Chat layout:
   - Assistant messages: a 24 pt W avatar (gradient ring) and **unbubbled** grey text (`#BCBFC1`, about 15 pt).
   - User messages: right-aligned **grey bubbles** (`#343A3E`, about 12 pt radius) with white text.
3. Messages:
   - Coach: "How can WHOOP help?"
   - User: "How can I improve my VO₂ Max?"
   - Coach (2 paragraphs): *"You're already on the right track. VO₂ Max is improved by increasing your body's ability
     to utilize oxygen. … Your March 10 run—41 minutes at 11.6 strain, mostly in HR zones 3-4—was exactly the kind
     of effort that boosts VO₂ Max."* and *"To keep moving the needle, mix in interval sessions (like 4 x 4 min hard
     efforts) once or twice a week and keep up those steady 30-45 min runs in zones 3–4."*
   - User: "Anything else I should focus on?"
   - Coach: *"Recovery is key. Prioritize sleep, hydration, and nutrition so your body adapts to the training. You're
     already consistent—just keep mixing in intensity and giving yourself time."*
4. Composer: a "new chat" icon (speech bubble with +) on the left, then a rounded field with a **gradient border**
   (`#8A62FF`→`#50D3FF`), placeholder "Ask WHOOP anything" (`#585C5E`), and a grey ↑ send arrow.

### 5.10 Journal Insights: Recovery Impact Analysis (frame 08)
1. Nav: `‹` · **JOURNAL INSIGHTS**.
2. Eyebrow **REFRESHED DAILY** (grey), title **"Recovery Impact Analysis"**, body *"See how behaviors impacted your
   Recovery over the past 90 days. Tap a behavior to view more details."*
3. Legend row: [▼ in orange chip] **HURTS** (orange) · **% IMPACT** (white, centred) · **HELPS** (green)
   [▲ in green chip].
4. Behaviour cards (CAPS name on the left, % on the right, diverging bar below):
   - HYDRATION **+24%**
   - 81%+ SLEEP PERFORMANCE **+21%**
   - READ IN BED **+13%**
   - DEVICE IN BED **+2%**
   - [**NEW**] CONSUME MEAT **+1%** (grey, card has a blue border)
   - 12+ STRAIN **+1%** (grey bar drawn to the left)
   - CAT IN BEDROOM **−1%**
   - WORK LATE **−6%**
   - CAFFEINE **−9%**

### 5.11 Menstrual Cycle Insights (frame 09)
1. Warm brick-red header gradient. Nav: `‹` · **MENSTRUAL CYCLE INSIGHTS** · ⚙.
2. **"Cycle Day 3 | Menstrual Phase"** ("Menstrual Phase" in coral `#FF7765`), then *"Predicted Period Day • Next
   period in: 25-27 Days"*.
3. Month nav **"‹ APRIL ›"**, weekday header **MON TUE WED THU FRI SAT SUN** (grey CAPS).
4. Calendar: days sit on continuous rounded **phase strips**:
   - 1–3 luteal (purple).
   - 4–5 logged menstrual (coral filled circles on a coral strip), with a white dot under 5 = symptoms.
   - 6 selected (white ring) around a predicted dashed-coral circle; 7 and 8 also predicted dashed circles.
   - 9–15 follicular (lavender), 16–17 ovulatory (teal), 18–30 luteal (purple, dimmer for the future).
5. Legend: Menstrual · Follicular · Ovulatory · Luteal pills, then "• Symptoms".
6. Card **"LOG PERIOD DATA"** with a dotted-circle drop icon on the left and a white circle **+** button on the
   right.
7. Card **"MENSTRUAL PHASE COACHING ›"** with a segmented phase bar **M | F | O | L**. M is selected: white border,
   dark-red fill, coral letter. The widths look proportional to phase length (**UNCONFIRMED**).

### 5.12 Stress Monitor (frame 10)
1. Nav: `‹` · **STRESS MONITOR** · ⚙. Day nav "‹ TODAY ›".
2. ⓘ at the top-right of the gauge.
3. **Horseshoe gauge**: about 218° sweep, diameter about 215 pt, stroke about 3.5 pt.
   - The gradient runs blue (0) → green (top) → orange (3), with a dim tinted inner band.
   - A white needle at the top has a fading tail.
   - Centre text: **1.5** (about 53 pt), **MEDIUM** (green CAPS), "Last updated 3:05pm". End labels "0.0" / "3.0".
4. **Day chart**:
   - Y axis 0.0–3.0 with gridlines `#2C3033`; X axis "3:00am · 7:00am · 11:00am · **3:05pm**" (the current time
     bold white), with a "‹" page-back on the left.
   - The line is coloured by value (blue <1, green 1–2, orange >2).
   - Shaded vertical activity bands have coloured caps on top and icons above: 🌙 sleep (cap `#7BA1BB`),
     🏃 activity (cap `#0093E7`), a breath/stress icon (cap `#67AEE6`), and a "3" label (grouped activities, cap
     `#0093E7`; meaning **UNCONFIRMED**).
   - A dashed "now" line ends in a green dot. A zoom-out 🔍− button sits in a black rounded square.
5. Insight: *"Most of your time was spent in the low stress zone. Your longest period of high stress started at 7:42
   AM and lasted for 51 minutes."* CTA **LEARN MORE WITH WHOOP COACH →**.
6. Card with a ◔ icon, **TOTAL DAY**, and **"TUE, JUL 18 VS. TYPICAL TUESDAY"**.
   - A segmented bar for today (blue/green/orange) sits above a dimmer one for typical.
   - Numbers below are cut off (**UNCONFIRMED**).

### 5.13 Weekly Plan / weekly recap (localized S10 only: ES "RESUMEN DE MI SEMANA", DE "MEIN WOCHENRÜCKBLICK", FR "RÉCAP DE MA SEMAINE")
English wording is **UNCONFIRMED**; the store description calls the feature "Weekly Plan".
1. Centred CAPS nav title (no back button visible).
2. A 3D grey dartboard with darts; one dart has green glowing flights.
3. Title (ES) "Sigue con lo que es bueno para ti" (DE "Werde weiter immer besser") with a grey body line.
4. **"44 % COMPLETO"** and a thin green progress bar (`#00F19F` on a dark track).
5. A bubble card (notch up) of goals, each with a **segmented circular progress ring** and "x/y":
   - Completed goals shown in green text: "Evitar el alcohol 5/5", "Ducha fría 3/3"
   - Then a divider, then the remaining goals in white: "85 %+ Calificación del sueño 7/5" (DE "5/7"),
     "5,000+ steps 4/5", "Meditation 2/7".

### 5.14 Extra UI glimpsed in the Play promo video (YouTube p9OWVHuTcNU, storyboard 320×180, low-res)
- **"+" quick menu**: a big white circular "+" FAB. The expanded menu is right-aligned: CAPS label + white circle
  icon for each item:
  - CREATE WHOOP LIVE (camera)
  - MY JOURNAL (journal)
  - STRENGTH BUILDER (lifter)
  - ADD ACTIVITY (+)
  - START ACTIVITY (stopwatch)
  - The menu is closed with "−".
- **TONIGHT'S SLEEP ›** card: "☾ 9:34PM RECOMMENDED BEDTIME" ···· a dimmed "⏰ 3:28AM, ALARM ON EXACT TIME" (Sleep
  Planner).
- **YOUR CARDIO FITNESS LEVEL ⓘ**:
  - A marker "44 ▼" on a segmented gradient bar (ticks about 15 / 35 / 40 / 45 / 50+).
  - "Above Average (40-44mL/kg/min)" / "Your VO₂ Max is in the top (20-40)% for people in your age and biological
    sex group."
- **HEART RATE ZONES** card: ZONE 5…ZONE 1 + RESTORATIVE with coloured horizontal bars (red-orange, orange, green,
  blue, grey, white).
- "…NG HEART RATE" card (probably RESTING HEART RATE) with a segmented range control and a chart (**UNCONFIRMED**).
- Floating activity chip "13.3 PILATES" with times.
- A big single dashboard row "👟 STEPS 6,373" (`#1E2A44`-ish dark navy card with a gradient).
- Dials card variants: 67/78/12.6 and 71/82/14.3. A sleep detail at 77 % with contributors 86/73/94/0 %.

---

## 6. Metric / label inventory (everything visible in store assets)
- **Scores:**
  - Sleep (Sleep Performance %), Recovery %, Strain / Day Strain (0–21)
  - Stress (0.0–3.0, LOW/MEDIUM/HIGH)
  - WHOOP Age (years, "x years younger")
  - Pace of Aging (×, -1.0x…3.0x)
  - Health Monitor ("WITHIN RANGE", n/5 Metrics)
- **Sleep contributors:** Hours vs. Needed %, Sleep Consistency %, Sleep Efficiency %, High Sleep Stress %. The
  promo video adds Hours of Sleep (h:mm), Recommended Bedtime, and Alarm (exact time / Sleep Planner).
- **Recovery contributors:** Heart Rate Variability (ms), Resting Heart Rate (bpm), Respiratory Rate (rpm), Sleep
  Performance %. Trends are shown "Today vs. prior 30 days".
- **Strain contributors:** Heart Rate Zones 1-3 (h:mm), Heart Rate Zones 4-5 (h:mm), Strength Activity Time (h:mm),
  Steps.
- **Activities:** Sleep (duration chip, start/end), Strength Training (strain chip, start/end), Pilates. Add
  Activity / Start Activity.
- **Dashboard (customizable):** HRV, RHR, plus rows whose names are hidden (Steps? Calories? durations).
- **Cardio Fitness:** VO₂ Max (mL/kg/min) with a percentile band. HR Zones 1–5 + Restorative.
- **Stress:** live value, time-in-zone bars (today vs typical weekday), activity bands.
- **Journal:** behaviour % impact on Recovery (90 days). Examples: Hydration, 81%+ Sleep Performance, Read in bed,
  Device in bed, Consume meat, 12+ Strain, Cat in bedroom, Work late, Caffeine.
- **Menstrual cycle:** cycle day, phase, predicted period window, symptoms, phase coaching.
- **Advanced Labs:** biomarker panels (75 / 81 / "122+" biomarkers), price, testing frequency.
- **Weekly Plan:** % complete, per-habit x/y completions.
- **Header extras:** streak count (🔥355), strap battery %, strap connection dot.

## 7. Store copy (App Store; Play is identical except for the bullets)
> WHOOP is the leading wearable that turns comprehensive health insights into daily action. By capturing dozens of
> data points every second, WHOOP delivers personalized Sleep, Strain, Recovery, Stress, and health insights—24/7. …
> WHOOP is screenless, so all your data lives in the WHOOP app… The WHOOP app requires a WHOOP wearable.

"How it works" feature list:
- **Healthspan\***: quantify your age and slow your Pace of Aging.
- **Sleep**: Sleep score 0–100 %, Sleep Planner, Haptic Alarm (wake when fully rested or at a specific time).
- **Recovery**: HRV, RHR, sleep, respiratory rate, giving a daily Recovery score of 1–99 % (green / yellow / red).
- **Strain**: cardiovascular + muscular exertion, Strain score 0–21, Strain Target (optimal range from Recovery).
- **Stress**: real-time stress score 0–3, plus breathwork sessions (alertness or relaxation).
- **Behaviors**: 160+ habits tracked, weekly guidance, **Journal** and **Weekly Plan**.
- **WHOOP Coach**: generative-AI answers grounded in biometrics.
- **Menstrual Cycle Insights**.

"What else":
- **Dig into the details**: HR zones, VO₂ Max, steps, trends over time.
- **Join a team** (iOS only): team chat, coach view.
- **Apple Health** integration (Play says **Health Connect**).

Footnotes: "*Some availability restrictions apply." and a general-wellness disclaimer.

## 8. Navigation map (as far as store assets show)
```
Tab bar:  Home | Health | Community | More      (+ floating W = WHOOP Coach, current iOS)
Home
 ├─ ‹ TODAY › day pager
 ├─ SLEEP ›    → Sleep detail (TODAY, ⓘ) → Last Night's Sleep [EDIT]
 ├─ RECOVERY › → Recovery detail (TODAY, ⓘ) → Today's Activities
 ├─ STRAIN ›   → Strain detail (TODAY, ⓘ) → Today's Activities
 ├─ insight card (stacked, ✓ n)
 ├─ HEALTH MONITOR › (→ Health Monitor; UNCONFIRMED screen)
 ├─ STRESS MONITOR › → Stress Monitor (⚙, ‹ TODAY ›)
 ├─ My Day [+] → quick menu: Create WHOOP Live · My Journal · Strength Builder · Add Activity · Start Activity
 ├─ Your Daily Outlook ›   (destination UNCONFIRMED)
 ├─ TODAY'S ACTIVITIES ⤢  (+ ADD ACTIVITY / START ACTIVITY)
 └─ My Dashboard [CUSTOMIZE ✎]
Health tab: (contents UNCONFIRMED; likely Healthspan, Advanced Labs, Health Monitor, Cardio Fitness, HR Zones, MCI, Journal Insights)
Coach: WHOOP COACH chat (BETA V2.0, history ⟲, new chat)
```

## 9. Gaps / UNCONFIRMED
- The left tab items in the current floating capsule are hidden by product renders (Home/Health inferred).
- The **Health** tab's own layout, the **Community** and **More** screens, Profile/Settings, Health Monitor detail,
  Daily Outlook detail, the full Sleep detail below "Last Night's Sleep", Strain/Recovery below "Today's
  Activities", and Activity detail do not appear in any store asset.
- The meaning of the Strain ring's light band and the white tick (target range?) and of "🔥355" (streak?).
- Font families (Proxima Nova + DIN-like) are inferred visually.
- The pt sizes assume a 393 pt mock for frames 02–10.
- Weekly Plan English wording; iPad dashboard row names 3–5; Stress "Total Day" numbers.
- The promo-video UI is 320×180 storyboard only, so its text is partially illegible.

## 10. Notes for the ZENO implementation (non-binding)
- Reproduce **structure, ordering and component patterns**, not WHOOP brand assets. Replace the "WHOOP" wordmark
  inside rings, the W logo, "WHOOP Coach" naming and WHOOP marketing copy with ZENO equivalents; these are
  trademarks and copyrighted text.
- Suggested design tokens are in §4.1 (bg gradient `#263137`→`#101518`, card `#292D30`, ring colours, status
  colours, AI gradient). Radii: 12 pt cards, 7 pt buttons, 16 pt margins.
- Highest-fidelity references:
  - `ios69-*` frames for detail screens.
  - `ipad-01-overview.png` for the full Home order: dials → My Day → Activities → My Dashboard.
  - `play-01.png` for the docked tab bar labels and icons.
