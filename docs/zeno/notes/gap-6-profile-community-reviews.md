# Gap 6: Profile sub-screens, Community, Year in Review 2025, Coach history and My Memory

Research date: 2026-10-02. Public sources only: Reddit RSS (search and per-post comment feeds), the WHOOP community forum (Discourse JSON, partly through the r.jina.ai reader because of rate limits), gadgetsandwearables.com, whoop.com Locker, WHOOP help-centre texts already saved in `raw/help-center-articles/`, and YouTube storyboards of `NrCpf_m75XM` (structure only).

Images are in `images/profile-community-2026/` (86 files, numbered 01–86). A file name is referred to here by its number, for example `/56`. Older folders are referred to by their full path, for example `reviews/r40`.

**Legend**
- **[SEEN]**: visible in a saved screenshot.
- **[TEXT]**: stated in official text (help centre, Locker, an official Reddit post) but not seen.
- **UNCONFIRMED**: neither seen nor stated officially; inference or third-party claim.
- **[POP]**: needs population or server data (percentiles, "members like you", other users, leaderboards). ZENO is offline and single-user, so it cannot reproduce these truthfully (see §8).

Colours are Pillow samples from JPEG screenshots (±3 units). Sizes are pt estimates (pixels ÷ 3 on 3× captures, ±1–2 pt).

---------------------------------------------------------------------------------------------------

## 0. Summary of what was resolved

| Gap asked | Result |
|---|---|
| Levels page (tap LEVEL card) | **Resolved [SEEN]** `/11` (L29), `/56` (L30 + grid), `/57` (2024 build, L18 + progress + grid). |
| How the level number is derived | **Resolved.** Levels 1–30 from the cumulative count of recoveries. There are 6 tiers of 5 levels each. Thresholds are in §2.4: L24 = 1600–1799, so 1724 → L24; L25 = 1800–1999, so 1907 → L25. Every data point checks out (§2.5). |
| Edit Profile + 2026 entry point | **Resolved.** Entry point [SEEN] `/21`: an "✎ EDIT" button beside the name in the 2026 profile header. Form [SEEN, partial] `/77`: "EDIT PROFILE" with labelled dark boxes (birthday, COUNTRY, STATE, CITY) and a "Set Your Birthday" wheel sheet. The other fields come from text (§1.4). |
| Achievements page top section | **Resolved [SEEN]**. `/04` (September, old UI): "All Achievements (24)" + chips. `/80` `/81` (October new UI): "All Achievements (33)/(30)" + chips "All · Sleep · Recovery · Strain · Healthspan · Act…". |
| Every badge family, Ring Ruler, star tiers | **Mostly resolved.** There are 5 shape families (§3.3) and 25+ badge names (§3.4). Ring Ruler is the boxing activity badge. Star tiers run from **0 up to 6 stars**, not 1–5: `reviews/r140` Green Monster 1050 has 6 lavender stars. They come with metal colours (§3.5). Stars exist only in the Aug–Oct 2026 "new achievement UI". |
| Achievement detail page | **Resolved [SEEN]** `/05–/08`, `/82`. |
| Community tab root | **Resolved [SEEN]** `/01` (2025 iOS, full res), **`/75` (July 2026 iOS, full res)**, `/02` (••• action sheet), `/18` (April 2026 storyboard frame), `/69` (rank settings sheet). |
| Team INFO tab | **Top half resolved [SEEN]** `/86` (August 2025): the banner photo behind the tabs, the logo + team name row, then "ABOUT" + description. The lower part (data sharing, members) is **UNCONFIRMED**; the legacy 2019 equivalent is `/31` (About, Data sharing, Members). INFO is the first tab in every team capture (`/54`, `/68`, `/70`). |
| Late-2026 follow friends | May 2026 leaked "SEARCH MEMBERS" page (`reviews/r67`) plus the official November 2026 roadmap text (§5.6). It had **not shipped** by 2026-10-02. |
| YIR 2025 remaining slides + Home icon | **Slides largely resolved** (§6): 7-segment story, slide types and copy. **Home entry icon: UNCONFIRMED visually.** Text only: "an icon will appear on your Home screen". |
| Coach conversation history | **Partly.** The clock icon is seen (`/03`, `/29`). The **list itself is UNCONFIRMED.** In v6.0/6.1 (Jul–Oct 2026) the header shows "Memory 💡" and **no clock** (`/66`). |
| 2026 My Memory (7 categories, toggle) | **Resolved [SEEN] + [TEXT]** (§7): onboarding `/24–/26`, main page `/27`, memory detail `/72`, AI Settings memory toggle `/55`, category list [TEXT]. |

---------------------------------------------------------------------------------------------------

## 1. Profile (2026)

### 1.1 Entry and navigation
- Tap the Home avatar to push "PROFILE" (back chevron). [SEEN] across 2025–26.
- **Tab-bar variants with a Profile tab**: a staged or A/B variant replaces "More" with a **Profile** tab that uses the avatar as its icon with a small ≡ badge, so the tab doubles as the More menu.
  - Seen in June 2025 (`/41`, with a shop cart at the top left) and July 2026 (`/78`, docked full-width bar, Coach "W" button inline in My Day, floating "+").
  - The standard 2026 bar keeps Home · Health · Community · More.
- The Community and teammate leaderboards also open **other members' profiles** (forum: "on some Whoop user profiles there's now an 'Achievements' section…"; `/33` was "taken from a friend's" profile). Viewing other users is [POP].

### 1.2 Layout top-to-bottom (April 2026 build, `/21` `/22` `/23`; August 2026 build `/10`)
1. **Nav bar**: "‹" · "PROFILE" (13 pt Bold, tracked caps) · membership chip at the right ("PEAK" or "LIFE"; outlined dark capsule with 11 pt caps letter-spaced at 60 % white).
2. **Header block** (`/21`, April 2026) on a **teal glow** that fades from the top of the screen (#3C8C8D near the status bar → #245154 → page #121619). The glow hue appears to follow the avatar colour (teal avatar) — **UNCONFIRMED** for other avatar colours.
   - Avatar: 92 pt circle; initials "MM" 34 pt Bold black on teal #44DBD6–#65E5E6 (or the photo).
   - Name "Marko Maslakovic" (24 pt Semibold white), below it "@GandW • 56 • GB" (14 pt, 70 % white; **username • age • country**).
   - **"✎ EDIT" button** right-aligned with the name row: rounded rect (radius ≈ 10, h ≈ 36), fill white ≈12 % over teal (#375659), pencil + "EDIT" 12 pt Bold caps. **This is the 2026 Edit Profile entry point.** In 2025 it was a pencil icon at the top right of the nav [TEXT, forum and help centre].
3. **"Member since" pill** (`/21`, `/10`): full width, h ≈ 36, radius ≈ 8, fill #15272B (April) / #292E32 (August). Contents: a circled W logo, "Member since" (13 pt, 60 %), then "November 2022" (13 pt Semibold white).
4. **Two half-width cards** (radius ≈ 12, fill #2B3033–#353942, "›" top-right):
   - **LEVEL**: medal art (§2.3), "LEVEL 22" (13 pt Bold caps), "1226 Recoveries" (14 pt, 70 %).
   - **WHOOP AGE**: green orb "52.4", "WHOOP AGE", "4.0 years younger".
5. **DAY STREAK row card** (h ≈ 54, fill #2A2E31–#2C2F34): "DAY STREAK" left; flame icon (colour by tier, §4) + "1245 Days" + "›" right.
6. **MY MEMORY row card** (August 2026 `/10`; **absent in April 2026** `/21`, added in May 2026 per the official 5/8 post "You can access Memory in your Profile"):
   - full width, h ≈ 54;
   - fill is a horizontal gradient from indigo #242440 through #202B3D to teal #1D333E;
   - left icon: violet lightbulb with sparkle (≈20 pt);
   - "MY MEMORY" in 13 pt Bold caps, then "›".
   - The help centre calls the Profile entry "Personalization".
7. **"Achievements (N)" carousel** (section title 24 pt Semibold; the count is grey (#8B9094-ish)):
   - "VIEW ALL →" (13 pt Bold caps) at the right from **August 2026**. The April build (`/21`) shows no VIEW ALL; tapping a badge opens it.
   - Horizontal scroll of ~105 pt badge cells. Each cell: badge art, the big count overlapping the badge bottom (40 pt Heavy condensed), then the name (15 pt Medium).
   - October 2026 (`reviews/r140`) adds a percentile line under each name: violet pyramid icon + "Top 0.2%" (14 pt, 70 %) **[POP]**.
   - The March 2026 build showed "Achievements" with no count (`/33`). A Spanish build: "Logros (8)" (`/14`).
8. **"Data Highlights"** (24 pt Semibold), then one card (radius 16, fill #1E2326):
   - segmented control "1M | 3M | ALL TIME" (selected chip #3A3F44);
   - three 88 pt rings: Best Sleep / Peak Recovery / Max Strain;
   - **STREAKS** (11 pt caps label + hairline): 3 columns with scalloped-circle icons. Labels "70%+ Sleep" (sleep blue), "Green Recovery" (green), "10+ Strain" (strain blue); values "44 Days" / "7 Days" / "12 Days";
   - **NOTABLE STATS** rows, 32 pt gold scalloped icon + name + value: Lowest RHR, Highest RHR, Lowest HRV, Highest HRV, Max Heart Rate, Longest Sleep, Lowest Recovery.
   - Already in spec §3.30; `/22` `/23` confirm it for April 2026.
9. **"Activity Summary"** (24 pt Semibold), card:
   - "1M | 3M | ALL TIME";
   - "1010x" (34 pt Bold) over "TOTAL ACTIVITIES" (11 pt caps);
   - header row "ACTIVITY | AVG. STRAIN … TOTAL";
   - per-sport rows: icon + "RUNNING" + "11.9" + right "698x" in strain blue #2D8CF0-ish, with a full-width blue bar (h 6, radius 3) on a hatched track;
   - "⌄ SHOW ALL" button (full width, #2A2F33, radius 8). Expanded state: "SHOW LESS" (`completeness-critic/03`).
10. **"Referrals"** section title at the bottom (`/23`). Contents **UNCONFIRMED**. ZENO omits it.

### 1.3 April 2026 launch onboarding for achievements
- **Home coaching card** "Introducing achievements" (`/19`):
  - body "Get rewarded for your progress and consistency on WHOOP with achievements." and a "VIEW ACHIEVEMENTS →" link (12 pt Bold caps, pink→violet gradient text);
  - hexagon sleep-badge art at the right; "✓ 1" stack chip;
  - card border is a 1.5 pt gradient from rose #E3ACA5/#B47D76 (left) to violet #8A63A4 (top right).
- **Coach-mark on Profile** (`/20`):
  - full-screen dim (black ≈80 %) with a spotlight on the achievements carousel;
  - title "Introducing achievements" (24 pt Semibold);
  - body "Your profile contains all the achievements you've earned since joining WHOOP. Tap into each to learn more and track your progress!";
  - "GOT IT" outlined capsule (h 40) with a pink→violet gradient stroke.

### 1.4 Edit Profile (form): partly SEEN (`/77`, June 2026, dimmed behind a sheet)

**Page:**
- "‹ EDIT PROFILE" (13 pt Bold caps).
- A vertical form of **full-width dark input boxes** (h ≈ 48, radius 10, near-black fill with a 1 pt dark-grey stroke), each with a small caps label above it (11 pt Bold caps, grey):
  - birthday box ("May 24, 2008"), with its label above the scroll position;
  - "COUNTRY" → "United States";
  - "STATE" → "Florida";
  - "CITY" → empty.
- Further fields are below the fold: units, weight, height, gender. **UNCONFIRMED** visually; listed in [TEXT].

**Birthday sheet** ("Set Your Birthday"):
- bottom sheet with a grabber (36 × 4, #4B5054), fill #182023, top radius ≈ 20;
- title 20 pt Semibold;
- iOS wheel picker with three columns (Month | Day | Year) and a rounded selection band (#26292E, radius 10);
- two buttons side by side, h ≈ 52, radius 14: "CANCEL" (outlined, white text) and "CONFIRM" (solid). CONFIRM is **disabled** (grey #424649, dim text) when the chosen year makes the member too young; here a 2012 birth year was selected.
- The same wheel style probably serves height and weight. **UNCONFIRMED**.

**Text sources**: [TEXT] from the help centre ("Updating Your Profile Information", 10/8/2025) and forum staff replies (2025-06, 2025-09):
- Fields: Email, Name, Birthday, Gender / Physiological Baseline, Location (country, state), Units (Imperial vs Metric), Weight & height.
- "Tap Save to confirm" — "the Save button will only show up after you make an edit".
- The username is not editable in-app.
- The birth-year picker in account setup stops at **2008**, so members must be about 18 or older (forum 16386, 2026-10-01).
- Changing country from the profile sometimes fails (forum 14199).
- Error copy: "Error: there was problem updating your profile".
- **ZENO**: build it as a pushed form with labelled dark input boxes, wheel-picker sheets with CANCEL / CONFIRM, and a Save button that appears only when something has changed.

---------------------------------------------------------------------------------------------------

## 2. Levels page

### 2.1 Evidence
- `/11`: Diamond L29, September 2026, hero only.
- `/56`: Diamond L30, May 2026, hero plus the first grid rows.
- `/57`: Gold L18, September 2024 build with a "Plan" tab. The **same design**, so the page is long-lived.
- Data points: `reviews/r74` (L24, 1724), `completeness-critic/09` (L25, 1907), `/10` (L27, 2344), `/21` (L22, 1226), `/40` (2024 YIR: L25, 1848 days worn).
- `/43`: a user-made table of "recoveries to next level", Reddit comment 2026-08-15. Third-party, but it matches every in-app threshold seen.

### 2.2 Layout top-to-bottom
1. **Nav**:
   - left: a **circular back button** (34 pt circle, 1.5 pt white stroke, "‹" inside), unlike the bare chevron elsewhere;
   - centre: "LEVELS" (15 pt Bold, tracking ≈2);
   - **immediately right of the title**: a "?" in a 22 pt outlined grey circle (an info sheet, contents **UNCONFIRMED**).
2. **Hero section**: fill #1C2125 (2026) / #192028 (2024). Its lower edge meets the darker grid section #13171A in a straight horizontal line (no radius) at ~y 345 pt.
   - Medal ≈ 230 pt diameter, centred (art §2.3).
   - Tier name: "DIAMOND" / "GOLD" (15 pt Bold caps, tracked, grey #55585D).
   - "LEVEL 29" (24 pt Bold caps, tracked, white).
   - **Progress row**:
     - left: a small current-level plaque icon (20 pt, the medal's material, e.g. a diamond with "29");
     - centre: a 6 pt-high capsule bar (fill light grey-white gradient #BCBDBF→#FCFCFC, track #161920, thin dark outline), ≈ 280 pt wide;
     - right: the next-level plaque ("30").
   - Caption under it (14 pt, 70 % #9BA0A4): "1 more Recovery to Level 30" / "14 more Recoveries to Level 14". The 2024 caption has a bug: it says 14, not 19.
   - **At max level** (`/56`): no progress bar; caption "Congrats! You've reached the highest level!"
3. **Level grid** (fill #13171A), 3 columns, one cell per level 1→30 (only 1–6 seen; the rest **UNCONFIRMED** but implied by scrolling). Each cell, centred:
   - a strap-shaped **plaque icon** (≈34 × 48 pt) with the level number. Material colours seen:
     - Carbon: black #333;
     - Iron, Steel, Gunmetal, Titanium: graded greys;
     - Bronze: #CF9E75;
   - material name (11 pt Bold caps, grey #55585D);
   - "LEVEL 1" (15 pt Bold caps white);
   - threshold line (13 pt, 70 %): "Membership starts" / "4 Recoveries" / "7 Recoveries" / "14 Recoveries" / "21 Recoveries" / "30 Recoveries".
   - **Tier-start cells** (Level 6 Bronze) carry a thin circular outline ring (≈64 pt) around the plaque and one small star under it. Expected the same for L11 Silver, L16 Gold, L21 Platinum, L26 Diamond: **UNCONFIRMED**.

### 2.3 Medal art (hero, profile card, YIR summary)
- **Round medal**: an outer ring of repeated "WVWVW" (WHOOP W) glyphs, inner laurel wreath, centre emblem with the level number, and a row of **stars at the bottom = tier index**.
- **Stars per tier**:
  - Gold L18: 3 stars, gold metal, strap-plaque emblem;
  - Platinum L22/L24/L25: 4 stars, white/platinum, strap plaque with a "WHOOP" footer;
  - Diamond L27/L29/L30: 5 stars, ice-blue diamond gem emblem, small hexagon gems on the ring.
  - Bronze has 1 star (L6 grid cell). Silver has 2: **UNCONFIRMED**.
- Comparison crop: `/44`.
- **ZENO**: draw its own medal (SF Symbols laurel + gem/shield). Do not copy the art (DESIGN_RULES §0).

### 2.4 Derivation of the level number (recoveries → level)
A **recovery** is a scored night ("WHOOP Levels are based on the number of recoveries (nights of sleep) logged", help centre). Levels are a step function of the cumulative count:

| Tier (help centre) | Level: min recoveries |
|---|---|
| Beginner 0–29 | L1 0 ("Membership starts") · L2 4 · L3 7 · L4 14 · L5 21 |
| Bronze 30–99 | L6 30 · L7 40 · L8 50 · L9 65 · L10 80 |
| Silver 100–299 | L11 100 · L12 125 · L13 150 · L14 200 · L15 250 |
| Gold 300–999 | L16 300 · L17 400 · L18 500 · L19 650 · L20 800 |
| Platinum 1000–1999 | L21 1000 · L22 1200 · L23 1400 · L24 1600 · L25 1800 |
| Diamond 2000+ | L26 2000 · L27 2250 · L28 2500 · L29 2750 · **L30 3000 (max)** |

- **Per-level material names**: L1 Carbon, L2 Iron, L3 Steel, L4 Gunmetal, L5 Titanium, L6 Bronze, L18 Gold, L29–L30 Diamond.
- **Assumed** (pattern, UNCONFIRMED): levels 6–10 "Bronze", 11–15 "Silver", 16–20 "Gold", 21–25 "Platinum", 26–30 "Diamond".

### 2.5 Checks
- L22 at 1226 ✓.
- L24 at 1724 ✓.
- L25 at 1907 ✓. The 2024 YIR shows L25 for "1,848 days worn" ✓; days worn approximate recoveries.
- L27 at 2344 ✓.
- L29 with "1 more Recovery to Level 30" means 2999 ✓.
- "Level 23 … 52 nights from 24" by a user with 1548 recoveries (1850 − 302 in the same thread) gives 1548 + 52 = 1600 ✓.
- "3000 Recovery Club" → Level 30 "highest level" ✓. A commenter on the L29 post adds: "I don't see anything higher" than Level 30.
- Help-centre example "Bronze, Level 9, 66 recoveries" ✓ (65–79).
- "8 years and 2 months to level 30" ≈ 2980 days ✓.

**Algorithm for ZENO**:
```
let mins = [0,4,7,14,21, 30,40,50,65,80, 100,125,150,200,250,
            300,400,500,650,800, 1000,1200,1400,1600,1800, 2000,2250,2500,2750,3000]
level = mins.lastIndex(where: { $0 <= count }) + 1
```
Then:
- the tier is `(level-1)/5` → Beginner, Bronze, Silver, Gold, Platinum, Diamond;
- remaining = `mins[level] - count`, with "Recovery" singular when it is 1.

The count must be **scored recoveries**, not wear days. ZENO's spec §3.30 already mentions the tier table but not the 30-level ladder; use this one.

---------------------------------------------------------------------------------------------------

## 3. Achievements

### 3.1 Timeline
- Launched in app **5.3**, staged rollout, about April 2026. Support email on the forum, 2026-04-09: "the recent 5.3 release that includes Achievements".
- **Retroactive**: unlock dates go back before launch ("Peak Day 1 · Jul 6, 2025", `/04`; "1% Club · Feb 8, 2025", `/80`).
- The rollout was very slow. In July 2026 many iOS 5.0 users still had no Achievements section ("only 1 person in my Whoop group has achievements"), and a WHOOP 4.0 user also lacked it (Reddit 1v06he5 comments).
- A **"New Achievement UI"** (metallic tiers, stars, percentile line, VIEW ALL, share) appears from **August 2026** (`/10`) and was common by October 2026 (`reviews/r40`, `r140`). The September 2026 capture `/04` still shows the older flat style. This is an A/B or staged rollout.

### 3.2 Achievements page (`/04` September 2026, old UI; **`/80` `/81` October 2026, new UI, top fully visible**; `reviews/r40` October 2026)

**October 2026 new UI** (`/80`, `/81`, both posted 2026-10-01):
- The same top structure: "‹ ACHIEVEMENTS" · "All Achievements (33)" / "(30)" · chips **"All | Sleep | Recovery | Strain | Healthspan | Act…"**. The 6th chip is cut at "Act…"; "Activities" is likely, but the full word is **UNCONFIRMED**.
- Chip geometry: h ≈ 34, radius ≈ 12, gap 8.
- Grid cells come in two variants on the same day:
  - `/80` shows the unlock date under the name ("Sep 2, 2026");
  - `/81` shows a **percentile line** instead: a pyramid icon + "Top 0.5%" (15 pt, 70 %). The pyramid is violet for most values but **gold** for "Top 13%" (Green Week), so the icon colour encodes a rarity bucket; the thresholds are **UNCONFIRMED** [POP].
- A **challenge badge** sits in the STRAIN section: "**Stars & Strides**", the All-In 250 challenge (July 2026). It has a red-white-blue line-art hexagon, 5 white stars on top and a big 3-D "250" emblem, with no count and no percentile.

**Layout, top to bottom:**
1. Nav "‹ ACHIEVEMENTS" (13 pt Bold caps).
2. **Large title "All Achievements (24)"**: 24 pt Semibold white; the count is grey #8A9095. It scrolls under the nav (in `/04` it is half faded behind the nav).
   - Whether (N) counts unlocked or total: **UNCONFIRMED**. The Profile header counts "Achievements (10/28/34)" look like *unlocked* counts.
3. **Filter chips** (horizontal scroll, 16 pt side inset, 8 pt gaps):
   - "All" selected: white #FFFFFF fill, black 15 pt Medium;
   - "Sleep" · "Recovery" · "Strain" · "Healthspa(n)…" unselected: fill #363D45–#3C3F44, white text;
   - chip h ≈ 34 pt, radius ≈ 12 pt (near capsule); "All" is ≈ 41 pt wide;
   - a 6th chip after Healthspan is cut off. In `/81` it begins "Act…" (probably "Activities", **UNCONFIRMED**).
   - The October 2026 new-UI capture (`reviews/r40`) still shows the bottom edges of the same five-chip row under the nav, with the first chip lighter (selected), so the top structure is unchanged in the new UI.
4. **Sections** in order SLEEP · RECOVERY · STRAIN · HEALTHSPAN · (activities **UNCONFIRMED**). Each has an 11 pt Bold caps grey label (#8B9094) + a hairline (#323941) running to the right edge.
5. **3-column grid** per section. Cell:
   - badge art ~72 pt (old UI) / ~84 pt (new UI);
   - big count (40–44 pt Heavy condensed white) overlapping the badge's lower third;
   - name (15 pt Medium white, wraps to 2 lines);
   - unlock date "Jul 18, 2026" (13 pt, 50 % #8A8F93);
   - row gap ≈ 36 pt.
6. **Locked**: black badge silhouette (same shape) with a grey padlock and a grey "0". No date.
7. Page background is a vertical gradient: #252C34 at the top → #13181C → #0E1213 at the bottom.

### 3.3 Badge families (shape = family)

| Family | Shape | Colour (new UI) | Seen |
|---|---|---|---|
| Sleep | **hexagon** frame of nested iridescent lines + moon/metronome/pillow emblem | steel-blue / lavender (#546575 glow on detail) | Sleep Specialist, Human Metronome, Pillow Perfect (locked) |
| Recovery | **shield** (flat top, rounded bottom point) | green for Green Monster / Green Week / 99% Club; **red** for 1% Club (skull coin) | Green Monster, Green Week, Peak Day, 1% Club, 99% Club |
| Strain | **diamond / rhombus** | strain blue (gold or silver metals when starred) | Strain Seeker (crown + heart coin), All Out Day ("20+" strap emblem); special: Stars & Strides (red-white-blue hexagon) |
| Healthspan | **organic blob** (wobbly circle) of teal lines around a speckled orb or hourglass | teal #2FD3C2-ish | (Healthspan) Time Traveler "-3"/"-6"/"-4 Yrs", Healthspan Comeback "+1", VO₂ Phenom "-6yrs" |
| Activities | **rosette** (scalloped / wavy circle, 20+ lobes) of purple→blue gradient lines, white sport pictogram | purple #9C8CF0 → sky #6EC3F0 | Runner's High, Gear Grinder, Ring Ruler, WOD Star, Walk Star, Stride Scholar, Crack Commander, Grit Grinder, "Realeza de la cancha" (ES) |

### 3.4 Badge names, criteria and examples (exact copy where seen)

**SLEEP**
- **Sleep Specialist**: "Total nights of 85%+ Sleep Performance" [SEEN `/07`]. Counts seen 25, 50, 1950.
- **Human Metronome**: "7-day streak of 90%+ Sleep Consistency and 70%+ Avg Sleep Performance" [SEEN `/06`]. Counts 1, 23.
- **Pillow Perfect**: criterion **UNCONFIRMED**; probably 100 % Sleep Performance nights. Pillow emblem. Counts 2, 196.

**RECOVERY**
- **Green Monster**: "Total green Recoveries" [SEEN `/58`]. Counts 10, 50, 150, 200, 550, 950, 1050.
- **1% Club**: "**Logged 1% Recovery**" [SEEN `/82`]. Skull (red eyes) on a red shield. Counts 2, 17. The detail page has a red top glow (#811C24). YIR: "43% of members achieved this in 2025" [POP].
- **99% Club**: 99 % recovery. Green shield with "99%". Count 7.
- **Green Week**: probably 7 consecutive green recoveries, **UNCONFIRMED**. Green shield with a bar-chart emblem. Count 10.
- **Peak Day**: criterion **UNCONFIRMED**. Emblem: a pyramid "peak" with a halo ring; green shield. Counts 1, 132, 302.

**STRAIN**
- **Strain Seeker**: criterion **UNCONFIRMED**; probably days ≥ 10 strain, matching the "10+ Strain" streak. Counts 50, 400.
- **All Out Day**: criterion **UNCONFIRMED**. Emblem: a WHOOP strap with a "20+" dial; blue diamond. Counts 4, 59, 299, 301.
- **Stars & Strides**: All-In 250 challenge badge (July 2026), placed in STRAIN (`/81`).
- **Grit Grinder**: rosette with a figure on a machine (`/79`, 100). The sport is **UNCONFIRMED**.

**HEALTHSPAN**
- **Time Traveler / "Healthspan Time Traveler"**: "Your WHOOP Age is now N years younger than your chronological age." Count shown as "-3", "-4 Yrs", "-6", "-10 Jahre".
- **Healthspan Comeback**: "+1". Criterion **UNCONFIRMED**; probably WHOOP Age improved by 1 year.
- **VO₂ Phenom**: hourglass-blob badge, value "-6yrs" (`/79`). Probably the VO₂ Max contribution to WHOOP Age; **UNCONFIRMED**.

**ACTIVITIES** ("Total ⟨Sport⟩ activities logged")
- Runner's High: running ("Total Running activities logged" [SEEN `/08`]).
- Gear Grinder: cycling ("Total Cycling activities logged" [SEEN `/05`]).
- **Ring Ruler**: boxing; boxer pictogram (`reviews/r140`, 250).
- WOD Star: functional fitness / CrossFit; pull-up pictogram (`/10`, 500).
- Walk Star: walking (`/33`, 10).
- Stride Scholar: elliptical (`/32`, 200).
- Crack Commander: chiropractic ("This one is for chiropractor sessions", `/09`, 5).
- Spanish "Realeza de la cancha": soccer kick pictogram (`/14`). The English name is **UNCONFIRMED**.
- Users complain that activity badges count sessions, not time ("feels like a participation trophy").
- **Pattern**: one rosette badge per WHOOP sport the user has logged. Names are puns.

**Challenge achievements**:
- completing a WHOOP challenge offers "VIEW ACHIEVEMENT" (`/13`);
- the badge is "Stars & Strides" (`/81`, `/85`): a red-white-blue hexagon with 5 stars and a "250" emblem, listed under STRAIN.

**Not achievements, but similar** (Home coaching cards with badge art):
- "1% Club": "Today might not feel great, but hang in there! You're in good company along with 0.5% of other WHOOP members." + "VIEW TREND →" [POP] (`/35`, `/59`);
- "99% Club": "A near-perfect recovery means your body is recharged. Lean in and make the most of your energy today." (`/16`);
- "Zombie Sleeper": "You're on a streak of bad sleep, but you can get through it! Try to treat yourself with extra care today." (`/34`);
- "Pushing Limits": "You worked hard today and exceeded your Optimal Strain range…" (Dec 2025 home capture).

### 3.5 Tier stars and metals (new UI only, Aug–Oct 2026)
- A row of small stars sits on top of the badge frame, arced along its upper edge. Star fill matches the metal.

| Count seen (badge) | Stars | Metal / stroke colour |
|---|---|---|
| 50 (Sleep Specialist, Strain Seeker) | 1 | family colour (steel blue / strain blue) |
| 150 (Green Monster) | 2 | **bronze / copper** |
| 250 (Ring Ruler), 400 (Strain Seeker) | 3 | **silver** (white-grey) |
| 500 (WOD Star) | 4 | **gold** |
| 950 (Green Monster) | 5 | **platinum** (bright white) |
| 1050 (Green Monster) | **6** | **amethyst / lavender** (stars #D9CCFF-ish) |
| 1–10 (1% Club, 99% Club, Green Week, Peak Day) | 0 | fixed special colour (red / green) |

- More samples from October 2026 (`/80`, `/81`):
  - Sleep Specialist 1350 → 6★ and 2300 → 6★ (lavender);
  - Green Monster 800 → 5★ (platinum white) and 1350 → 6★ (lavender);
  - Strain Seeker 650 → 4★ (gold).
- **Event and streak badges never get stars**, even at high counts. They keep a fixed family colour:
  - Pillow Perfect 196 and Human Metronome 82: steel-blue hexagon, 0★;
  - Peak Day 302, Green Week 31, 99% Club 18: green shield, 0★;
  - 1% Club 17: red shield, 0★;
  - All Out Day 59: blue diamond, 0★.
- So stars apply only to **cumulative-count badges** (Sleep Specialist, Green Monster, Strain Seeker, activity badges such as Ring Ruler and WOD Star).
- So the star ladder is **0–6, not 1–5**.
- Thresholds consistent with all samples: 1★ ≥ 50 · 2★ ≥ 100 · 3★ ≥ 250 · 4★ ≥ 500 · 5★ ≥ 750 · 6★ ≥ 1000. The exact cut-offs are **UNCONFIRMED**.
- Whether every badge uses the same ladder (streak badges such as Human Metronome reach only ~23) is **UNCONFIRMED**.

### 3.6 Achievement detail page (`/05` `/06` `/07` `/08`)
1. Nav "‹ ACHIEVEMENT DETAILS". **Share icon** (square + up arrow) at the right from August 2026 (absent in the April/May 2026 captures `/07`, `/08`).
2. **Background**: a radial glow at the top tinted by the badge family, fading into near-black (#0C1014 mid, #111619 low).
   - activity: violet #393266 top-left → teal-blue #275364 top-right;
   - sleep: steel blue-grey #546575.
3. **Badge hero** (~260 pt), centred, with animated-looking concentric line art. **Big count** (88 pt Heavy condensed white) overlapping the bottom ⅓ of the badge.
4. Name, e.g. "Gear Grinder" (22 pt Semibold), then the criterion line "Total Cycling activities logged" (15 pt, 70 %).
5. **Percentile block** [POP]:
   - pyramid icon (from August 2026): 4 stacked grey layers with the **top layer lit violet** (#877AC0) and a glow, so it reads as a rarity tier. In the October grid a **gold** pyramid appears for "Top 13%", which suggests the lit layer or colour changes with the bucket (**UNCONFIRMED**);
   - "Top 0.1%" (15 pt Bold);
   - "WHOOP" wordmark (grey, 13 pt) beneath;
   - the locale decimal is respected ("Top 0,04%").
6. **Milestone card** (radius 16, fill #1E2326):
   - left: mini badge (≈56 pt) with the **current count**;
   - centre: "27 more" (14 pt Semibold), a progress bar (6 pt, fill #67AEE6, track #34393B) and "until your next milestone." (13 pt, 70 %);
   - right: greyed next-milestone badge + target count.
   - The bar spans **last milestone → next milestone**: Gear Grinder 1150→1200 at 1173 = 46 % ✓.
7. "⇪ SHARE ACHIEVEMENT" button (full width, h 54, fill #292E30, radius 12, 13 pt Bold caps) from August 2026.

**Big number semantics**: the badge shows the count at which the **last milestone was unlocked** (Gear Grinder hero 1150 while the current count is 1173). The grid shows the same number plus its unlock date.

**Milestone steps seen**:
- activity counts: 100 → 150 → … → 1150 → 1200 (steps of 50 above 100);
- Sleep Specialist: 1950 → 2000.

### 3.7 Unlock modal (`/12` English June 2026, `/36` German July 2026; day-streak variant `/65`)
- A full-screen black scrim (≈85 %) over Home.
- Content, top to bottom:
  - badge art at top-left (~150 pt) with the metric in huge type ("-4 Yrs");
  - the name, e.g. "Healthspan Time Traveler" (26 pt Semibold);
  - body (15 pt, 70 %) "Your WHOOP Age is now 4 years younger than your chronological age." followed by a **bold** percentile sentence "Only 35% of members hit this!" [POP];
  - "Your Next Milestone" card (black, 1 pt grey border, radius 12): mini badge, teal title "Your Next Milestone", "5 Years Younger" and a thin progress bar.
- Buttons at the bottom: "CLOSE" (outlined, h 56, radius 14) and "VIEW" (solid white, black text).
- Day-streak variant: "New Day Streak Unlocked / You're on fire—and now in the top 0.6% of all WHOOP members." plus "2000/2050 · 50 more until your next milestone" with a gold bar.

### 3.7b Achievement chip on deep-dive pages (`/83`, July 2026)
- On the **Recovery deep dive**, the right side of the nav ("‹ TODAY …") shows a **capsule chip** in place of the ⓘ:
  - fill #282D33, h ≈ 30, radius 15;
  - a mini Green Monster shield badge (≈18 pt) + "**307**" (15 pt Bold);
  - this is the user's green-recovery count, linking the metric page to its achievement.
- The May 2026 capture of the same page shows ⓘ instead.
- Equivalent chips on the Sleep page (Sleep Specialist) and Strain page (Strain Seeker): **UNCONFIRMED**.
- **ZENO**: worth copying. It is fully local.

### 3.8 Share card (`/58`)
- A portrait image: black background, green glow behind the shield badge;
- "950" (60 pt Heavy), "Green Monster" (24 pt Semibold), "Total green Recoveries", "Top 0.4%" + the WHOOP wordmark.

### 3.9 Challenges (supporting context)
- In-app challenges exist: "December streak challenge" (2025), "January Jumpstart" ("wraps in the app on 2/1"), and "All-In 250 Challenge" (July 2026).
- **Join page** (`/84`, before the start):
  - nav "‹ ALL-IN 250 CHALLENGE •••";
  - hero: the tick-mark gauge with the "ALL-IN 250 CHALLENGE" logo art in the centre, and "🕐 Challenge starts June 29, 2026" under it;
  - title "Go All-In: 250 Minutes in 7 Days" (22 pt Semibold);
  - body "Hit 250 minutes of activity in 7 days. Every workout moves you closer, no matter how small.";
  - a "**WHAT YOU EARN**" card (radius 14, fill #323844, 1 pt gradient border violet #2C2E3B → red #382B32): shopping-bag art + "25% OFF YOUR NEXT ORDER" (13 pt Bold caps) + "Only valid on accessories and apparel" [POP / commerce];
  - a white "**JOIN CHALLENGE**" button pinned at the bottom next to the Coach button.
- **Completion modal** (`/85`, Android): a black scrim over Home, the "Stars & Strides" badge art, the title "Stars & Strides", "You completed 250 minutes, a strong week of effort to complete the challenge. Check your email for your discount reward!", and buttons "CLOSE" (outlined) + "**SHARE**" (white). This is the unlock-modal template with SHARE in place of VIEW.
- Home card (`/39`):
  - "All-In 250 Challenge Starts Today / Kick off your 7-day challenge today! Get moving to celebrate America's 250th. GET STARTED →";
  - "250 CHALLENGE" art, gradient border.
- In-progress state (`/76`):
  - the gauge is only partly lit (violet ticks up to the value, grey after);
  - "168/250 MINUTES LOGGED";
  - a clock icon with "**4 days** left";
  - "Great start! / You've logged 168 minutes. Log 82 more minutes to reach your goal.";
  - the white bottom button reads "ADD ACTIVITY" instead of VIEW ACHIEVEMENT.
- A referral push seen in the same period: "Leonardo joined WHOOP! Your friend Leonardo just joined WHOOP, which means you'll unlock 2 free months soon. Invite more friends to never pay membership fees again." [POP]
- Challenge page (`/13`, `/42`):
  - nav "‹ ALL-IN 250 CHALLENGE •••";
  - a tick-mark radial gauge (≈ 120 ticks, colour ramp violet → white → red) with "460/250" (64 pt + 24 pt) and "MINUTES LOGGED";
  - "✓ Complete" (green check);
  - "Challenge complete / You've reached 250 minutes. Strong work – way to finish what you started.";
  - a contributing-activity list grouped by day (TODAY, YESTERDAY, THU, JUL 2, 2026) using standard activity rows;
  - a white "VIEW ACHIEVEMENT" button pinned at the bottom next to the Coach button.
- ZENO: a personal challenge (e.g. "250 zone minutes in 7 days") is buildable offline.

---------------------------------------------------------------------------------------------------

## 4. Day Streak details (Profile → DAY STREAK; adds to spec §3.30)

### 4.1 Layout
- "‹ DAY STREAK ⓘ". In August 2026 builds the ⓘ is replaced or joined by a **share** icon (`/15`).
- Flame hero, count (72 pt Heavy), "Day Streak / Wear your WHOOP daily".
- Stats row: start date · "Top N% WHOOP" [POP] · max streak.
- THIS WEEK: day flames, ✕ for missed days.
- Milestone card.
- A **tier message card** at the bottom (title 15 pt Semibold + body 14 pt, 70 %).

### 4.2 Flame colour by streak length [SEEN]

| Streak | Flame | Tier message title / body |
|---|---|---|
| 1–? | small **yellow** (`/60`) | "Spark's lit": "You've started a streak! Keep the flame going by wearing WHOOP day and night to unlock insights about your body." |
| ~100–179 | **orange** (`/61`, `/38`) | "Stay in the game for long-term gains": "You've made WHOOP part of your routine, and it shows. Consistent wear is linked to better sleep, more movement, and a lower resting heart rate…". 2025 build: "Holding the flame: Just keep tending to the habit - day by day. That's how fires last." |
| 180–364 | **red**, blue core (`/62`) | "Every day counts": "Your streak is strong! Continuous data like this helps you train smarter, recover better, and know your body like never before." |
| 365–999 | **magenta-red** (`/63`) | **UNCONFIRMED** |
| 1000–1999 | **blue** (`reviews/r48`, `/15`) | "Legendary consistency": "You've built one of the most consistent streaks on WHOOP. Congrats! This level of continuous data gives you a clearer picture of your body and helps you train smarter, recover faster, and stay healthier over time." |
| 2000+ | **gold** (`/37`, `/64`) | "Legacy-level dedication": "Your streak shows you are one of the most dedicated WHOOP members. Long-term continuous data like this gives you the clearest view of your health and performance. Keep it going!" |

### 4.3 Milestone ladder seen
- 1 → 7, …, 100 → 180 → 365 → 730 → 1000 → 2000 → 4000.
- From August 2026 the steps above 1000 are **50 days** (1300 → 1350, 2000 → 2050).

### 4.4 Other details
- Percentiles seen [POP]: Top 50 % (101 d), Top 20 % (364/365), Top 3 % (1304), Top 2 % (1337–1682), Top 0.8 % (1851), Top 0.6 % (2000), Top 0.4 % (2046), Top 0.1 % (2370, 2500).
- **ZENO**: replace "Top N% WHOOP" with "Best streak" or "Longest ever" (local). Keep the tier colours and messages in ZENO's own words.

---------------------------------------------------------------------------------------------------

## 5. Community

### 5.1 Community tab root (`/01` June 2025 iOS, full res; **`/75` July 2026 iOS, full res**; `/18` April 2026 storyboard frame 110; `/02` ••• sheet)

**July 2026 capture** (`/75`): the same structure as 2025 inside the floating-capsule tab bar.
- "Teams •••" sits under the banner (scrolled off the top).
- "MY TEAMS" (#8B9094) with "MONTHLY STRAIN RANK ⌄" at the right.
- **8 team rows**, each 56 pt tall with a 10 pt gap and fill #34393D–#353D40. Logos are 40 pt gradient circles with a white glyph:
  - orange #F87229 beer glyph: "CHEERS TO WHOOP" 630th / of 93.3K;
  - pink with a UK flag: "GREAT BRITAIN" 388th / of 77.8K;
  - violet people glyph: "MEMBERS 50-60" 23rd / of 1.8K;
  - blue people glyph: "MEN 40-50" 498th / of 108.5K; "MEN 50-60" 299th / of 42.4K;
  - "UNITED KINGDOM" 34th / of 5.1K;
  - green cricket glyph: "WHOOP CRICKETERS" 54th / of 6K;
  - blue skater glyph: "WHOOP SKATEBOARDERS" 11th / of 1.1K.
- "RECOMMENDED TEAMS · VIEW ALL →" tiles below.
- Page colour runs from #242B33 at the top to #101518.
- WHOOP auto-enrols members in **demographic and country teams** (age band, sex, country); this is [POP].

Top to bottom:
1. **Promo banner card** (full width, h ≈ 63, radius 12):
   - 1.3 pt light warm-grey outline (#CCD4C9 sampled), fill = page (#212A2F);
   - left: line icon of a hand + paper-plane (24 pt);
   - title "SHARE A FREE TRIAL" (13 pt Bold caps) over "Invite your community to experience WHOOP" (13 pt, 70 %).
   - In April 2026 it reads "**INVITE A FRIEND**" with a smaller subtitle (illegible at storyboard resolution).
2. **"Teams"** large title (28 pt Semibold) left; "○○○" (three outlined dots, 20 pt) right.
   - The ••• opens an **iOS action sheet**: "Create Team" · "Enter Invite Code" · "Explore Teams" · "Cancel" (`/02`).
3. **"MY TEAMS"** (11 pt Bold caps, #8B9094) left. Right: "**DAILY STRAIN RANK** ⌄" (12 pt Bold caps white + chevron) opens the **Leaderboard settings sheet** (`/69`):
   - "DISPLAY RANK AS …" with a capsule segmented control [DAY STRAIN | RECOVERY | SLEEP];
   - "OVER THE COURSE OF …" radio rows: TODAY / THIS WEEK 10/06 TO 10/12 / THIS MONTH (OCTOBER);
   - an outlined "APPLY" capsule.
   - The Android 2025 sheet was white with a red APPLY. The iOS styling is **UNCONFIRMED**.
   - The rank label follows the choice (e.g. "Monthly Sleep Rank" mentioned on the forum).
4. **Team rows** (full width, h ≈ 55, radius 8, fill #34393D, 8–10 pt gaps):
   - 40 pt circular team logo (WHOOP W on black, flag photo, coloured glyph);
   - team name (14 pt Bold caps, tracked);
   - right-aligned rank: "322nd" (17 pt Bold) over "of 13.4K" (12 pt, 50 %); "1st / of 2"; "4,149th / of 146.6K". Some rows have no rank, e.g. a team without the chosen metric;
   - per the help centre, rows also show **unread chat counts**: visual **UNCONFIRMED**;
   - public demographic teams appear automatically ("MASSACHUSETTS", "MEN 30-40") [POP].
5. **"RECOMMENDED TEAMS"** (11 pt caps) + "VIEW ALL →". Horizontal carousel of photo **tiles** (≈160 × 180 pt, radius 8):
   - darkened photo;
   - a 64 pt circular gradient logo (orange "Cheers to WHOOP", amber "Team Caffeine", violet "Road Runners");
   - team name 20 pt Bold caps;
   - "56154 MEMBERS" (11 pt caps, 70 %).
6. **Pending Invites** section (above My Teams) with a **red dot on the Community tab icon** [TEXT, help centre]. Visual **UNCONFIRMED**.
7. Tab bar: docked in 2025 (`/01`), floating capsule + Coach button in 2026 (`/18`).
- Colours (`/01`): page #252E33 → #111419 near the tab bar.

### 5.2 Team page (`completeness-critic/01`, `help-center/104`, `/54`, `/68`, `/70`)
- **Header**:
  - a blurred team banner photo behind the status bar and nav;
  - a circular back button (outlined) at the left and a circular "•••" at the right (Android: ← and ⋮);
  - centred team name in 15 pt Bold caps.
- **Tabs**:
  - "INFO | CHAT | STRAIN | RECOVERY | SLEEP" (12 pt Bold caps; selected = white + 2 pt underline, others ≈ 50 %);
  - **large public teams have no CHAT** ("INFO | STRAIN | RECOVERY | SLEEP", `/68` "WOMEN 40-50", `/70` "JIU JITSU").
- **Leaderboard tabs**:
  - a filter circle button (36 pt) + capsule segmented "DAILY | MON - SUN | MONTHLY" (selected = outlined white capsule). In the past it was "BACK TO TODAY" (`/70`);
  - metric header: "RECOVERY / 65% avg" in the metric colour (left) [POP]; "TODAY / Last Updated: 10:02" (right);
  - rows: 56 pt avatar with a progress ring in the metric colour, "1. Olesya Vorontsova" + value in the metric colour "99%", sub-line "HRV: 46, RHR: 60". Strain rows: "Walking 11,2 on 06.10 / 2 136 Calories". Sleep rows: "10:39 hours of sleep";
  - **the user's own row is pinned at the bottom** in a darker band when out of view ("290. … 98%") [POP].
- **CHAT tab**: message rows with an avatar, a name + @handle line, a timestamp, plain text, and read receipts ("2 ✓✓").
  - Composer: "SAY SOMETHING" (iOS, `completeness-critic/01`).
  - **WHOOP bot weekly champions post** (`/54`): "WHOOP 🤖 3:29 pm / 👑 Congratulations to last week's champions! (9/29 - 10/5) / @Barker31 — Avg. Strain of 12 💪 / @Barker31 — Avg. Recovery of 79% 🎯 / @Keyleigh — Avg. Sleep Performance of 85% 😴", with a "6 days ago" grey pill.
- **Invite codes** in 2026 look like **"COMM-A73B53"** (prefix COMM- + 6 hex). The help centre still says "8-digit code".
  - The system share text reads "Hey, join my team MENTAL HEALTH MEDS on WHOOP! COMM-2799AD" (Reddit 1uofbax).
  - Creators describe "chat enabled" teams, which matches the admin Chat toggle. Team creation offers an **enable-chat** option ("there was a feature of enabling chat, i turned that on", Reddit 1se2ans, April 2026).
- **Team chat** can send **images and "share stats"** cards. A red "!" marks a failed send (Reddit 1wkpn08, September 2026; `completeness-critic/01`). The stat-card layout is **UNCONFIRMED**.
- The Referrals page has an "invite interface" listing invitees by name (Reddit 1wftl3e). Visual **UNCONFIRMED** [POP].
- Tapping a member shows their summary or profile [TEXT, forum 5814]. Layout **UNCONFIRMED**.
- Team ••• → Notification Settings (Mute); admins: Options → Manage Teams → Chat toggle [TEXT].

### 5.3 Team INFO tab: top half SEEN (`/86`, August 2025 iOS); lower half UNCONFIRMED
**Seen in `/86`:**
- The **team banner photo** fills the top ~40 % of the screen behind the circular back button, the "•••" circle and the tab row, then fades to the page colour #0D1215.
- Tabs over the banner: "**INFO**" (selected, white + 2 pt underline) | CHAT | STRAIN | RECOVERY | SLEEP (dim #7B817F).
- **Identity row**: team logo in a 72 pt circle (left) + team name "GRIND2FIND" (22 pt Bold caps, tracked, white).
- "**ABOUT**" (13 pt Bold caps, grey #535959-ish over the dark), then the free-text description (15 pt, #AAAEB1, multi-line, emoji allowed: "Gym 💪 | Study 📚 | Work 👨‍⚕️ / The journey from A levels to Doctor / #Grind2Find / Currently: …").
- The large "Join our Whoop team : COMM-FFDBE9" text in the fade zone uses a condensed font unlike WHOOP's UI. It is **probably a user-added overlay** (UNCONFIRMED). Do not copy it as UI.
- Below ABOUT: cut off. Expected to be DATA SHARING + MEMBERS, as in legacy `/31` (**UNCONFIRMED**).

**Earlier note:** apart from `/86`, no public 2025–26 capture shows the INFO tab selected.
- **Legacy 2019 structure** (`/31`, from the Locker "Join and Create Teams" GIF), likely still the template:
  - team logo circle + name;
  - **ABOUT** (description);
  - **DATA SHARING** (Strain / Recovery / Sleep icons);
  - **N MEMBER(S)** + "ADD MEMBERS" + a member list with an "ADMIN" tag;
  - owner edit pencil.
- Help-centre text adds: invite by search or by share code/link; team averages; Mute; admin Chat toggle.
- `/30` shows the legacy create-team flow: 01 WHAT'S YOUR TEAM NAME → 02 CHOOSE YOUR BANNER (swipe / UPLOAD YOUR OWN) → 03 CHOOSE YOUR LOGO → team page → member search with ⊕ → "REFER A FRIEND / INVITE A FRIEND".

### 5.4 Coach link to Community
- Coach suggestion chip "Explore popular public teams" (`/67`, September 2026).

### 5.5 Known complaints (design implications)
- Since July 2026 the app sometimes **opens on the Community tab** by default (reviews notes).
- Users asked to swap Community for Plan in the tab bar (forum 13182, 13849).
- Requests: steps in teams, rolling 7/30-day leaderboards, cooperative mode, minimum nights for monthly sleep rank.

### 5.6 Follow friends (late 2026)
- **May 2026 leak** (`reviews/r67`, Reddit "They're releasing a way to follow your friends"):
  - "‹ SEARCH MEMBERS" with a search field (h 48, radius 12, 1 pt grey border, ⓧ clear);
  - rows: 40 pt avatar (photo or initials on a colour), name (15 pt Semibold), @handle (13 pt, 60 %), and a dark "ADD" button (#3A3F44, radius 8, 12 pt Bold caps);
  - a toast "Failed to load. Please try again." with a W logo.
  - G&W report (2026-05-06, citing the Reddit post): "**Friends appeared above Teams**, pushing the Teams section lower and removing the quick daily ranking view from the main screen"; adding friends returned an "employees only" message.
  - The forum (2026-09-24) confirms the feature appeared, then vanished on refresh.
  - The original poster's own words (1t4okrp): "You can add friends by searching or you can share a unique link. The annoying part is the UI for your friends is now **above your teams** and at a glance at the teams section **it no longer shows your daily ranking**… you need an extra click into the team first."
  - Another user: "I've got it in **NZ**. They sent an email about NZ getting it first as a beta."
- **Official roadmap** (r/whoop "Coming Next…", 2026-09-03), November 2026 "Improved Community" [TEXT]:
  - "**Follow friends and family**: Connect directly without creating a team, then quickly view the Sleep, Recovery, Strain, and activities they choose to share. Connections from small teams… carry over automatically."
  - "**Encourage each other**: React to and comment on shared updates…"
  - "**Capture Moments**: Add a photo and note to an activity… Moments will be saved to your profile and can appear for the people who follow you."
- **Not shipped as of 2026-10-02.** No UI beyond the leak.

---------------------------------------------------------------------------------------------------

## 6. Year in Review 2025

### 6.1 Availability and entry [TEXT]
- iOS from Dec 9, Android from Dec 11 2025; open until **Jan 12, 2026**.
- Eligibility: ≥ 60 recoveries Dec 1 2024 – Nov 30 2025. Data runs through about Dec 2. Requires Coach ON ("powered by WHOOP Coach").
- **Entry**: "an icon will appear on your Home screen — tap it anytime" (help centre). **No screenshot found.**
  - Home captures from Dec 14, Dec 29 and Jan 1 (header and My Day visible) show **no extra header icon**.
  - The Coach answered "Home → My Day → 'Year in Review' card/button" (AI answer, unreliable).
  - So the entry is **UNCONFIRMED**. ZENO: a My Day row / promo card "Your 2025 in Review ›" in the Dec–Jan window.
- **Intro splash** with a "dive" button: "I hit dive and it replays the intro splash page". Copy is probably "DIVE IN" **UNCONFIRMED**. The first screen shows "how many days I've worn Whoop".
- "It asks you to write a **message to your future self**" [user report]. Visual **UNCONFIRMED**.

### 6.2 Chrome (all slides) [SEEN]
- Full-screen story. Top bar:
  - "✕" (20 pt, left);
  - centred lock-up "WHOOP" (white thin wordmark) + "**2025**" in italic bold with a gradient from periwinkle #758FFE (left) to sky blue #5CBEFF (right).
- Background: #07080D near-black at the top, with a per-slide glow rising from the bottom:
  - deep red #521117 (1% Club month slide; shield rim #F10F13);
  - indigo #3C3B5A (Sleep top performer);
  - green #2A5237 ("Found Flow" persona).
- **Progress indicator** at the bottom: **7 segments**:
  - completed = short white capsules (≈14 × 5 pt);
  - current = a long track that fills white (auto-advance timer);
  - upcoming = short grey capsules (white 25 %).
- Navigation is tap/swipe (users found swiping "went back a page").
- Backgrounds change per slide:
  - deep red (1% Club month slide);
  - indigo-violet (Sleep top performer);
  - navy-blue (steps);
  - green or violet (persona card);
  - black (comparisons).

### 6.3 Slide inventory (position from the 7-segment bar where visible)

| # | Slide | Copy / visuals | Evidence |
|---|---|---|---|
| 1 | Intro / days worn | "how many days I've worn Whoop". The 2024 equivalent: "WHOOP / ANDREW'S 2024 YEAR IN REVIEW ✕", huge "1848", strap render, "You've been a WHOOP member for 5 years, and you've worn your WHOOP for 1,848 days total." + medal "Level 25". **2025 visual UNCONFIRMED** | text; `/40` (2024) |
| 2 | **Month timeline highlight** | Top: a horizontal tick-mark scrubber with a speckled orb at the current month; "February / Sat, Feb 22" (or "April / Sun, Apr 6"); a large badge card (shield with a red glowing rim, skull coin); "1% Club"; "43% of members achieved this in 2025" [POP]; a sentence, e.g. "February brought your longest sleep at 14h on the 22nd — you fully recharged." / "Even with a 1% Recovery day in April, you focused on hydration and kept progressing." Bottom-right: a ✦ sparkle | `completeness-critic/10`, `/52` |
| 3 | UNCONFIRMED | possibly the "Total Strength Activity Time 144 hrs ▲ vs WHOOP avg of 45 hrs" stat slide ([POP] average). Green delta chip on dark | `/51` (crop) |
| 4 | **Pillar Top Performer** | Hexagon sleep badge art (lavender line-art, moon); "Sleep" (22 pt Semibold); "2025 Top Performer"; avatar + name; divider; pyramid icon "Top 2% / WHOOP" [POP]; sentence "Earlier bedtimes and consistent wake-ups turned your evenings into a reliable reset, not an afterthought." | `/45`, `/46` |
| 5 | UNCONFIRMED | probably "Behavior impacts on Recovery" (bars: CAFFEINE +7%, DEVICE (E.G. PHONE) IN BED +7%, OUTDOOR TIME +4%, ALCOHOL −13%, CREATINE −4%, VITAMIN D −4%) or "HEALTHSPAN COMPARISON" (Me vs **Members like you**: rows Hours of Sleep, Steps, Lean Body Mass, Resting Heart Rate, Sleep Consistency, VO₂ Max, Strength Activity Time, Time in HR Zones 1-3, Time in HR Zones 4-5, total "-6.4 Years" vs "-0.7 Years"; "members like you = same age range and gender" — official reply) [POP] | `completeness-critic/08`, `/11`, `/53`, `/71` |
| 6 | **Steps / elevation** | "808.7k" giant blue numerals behind a grey 3-D mountain with a blue flag; "You logged 808,735 steps — equivalent to climbing Mt. Everest 8 times. Serious elevation." | `/50` |
| 7 | **"The Year You …" persona card** | A share-style card (radius 20, 1 pt light border, tinted glass); "The Year You" (15 pt) over a coloured title ("FOUND FLOW" green caps / "Kept Showing Up" violet / "BUILT FROM THE GROUND UP" blue caps); a 6–8 line AI-written paragraph ("Four years on WHOOP. In 2025, you balanced big Strain with smart recovery — 351 hours in HR zones and 261 strong sleep nights around 7h 48m…"); footer "WHOOP" (left) and italic "2025" (right) over a wavy-line pattern | `/47`, `/48`, `/49` |
| final | **Summary share card** | "WHOOP 2025 / Year in Review", name, big WHOOP Age orb top-right, LEVEL 25 / 1907 Recoveries · DAY STREAK 1914 Days, ring trio with dates, Longest Sleep / Lowest Recovery / Top Activity rows. Shared "by selecting the share button on the final screen" [TEXT] | `completeness-critic/09` |

- Variation: the "Healthspan Comparison" header appears both as caps ("HEALTHSPAN COMPARISON", `completeness-critic/08`) and Title Case (`/71`).
- Slide order beyond the indicator positions above is **UNCONFIRMED**, and probably varies per member (badges and months differ).
- Global stats (official Reddit post, not in-app): Finland top sleeper, Gen Z 423.8 min/night, "Weightlifting +122%", top behaviours.

**ZENO**: a "Year in Review" story is buildable from local data:
- days worn, level, top month moments (lowest or highest recovery, longest sleep), best pillar, steps, Everest equivalence (8,848 m ÷ about 0.16 m per step), behaviour impacts from ZENO's own regressions, and a templated persona paragraph (no LLM needed);
- replace [POP] comparisons with "vs your 2024" or "vs your own average".

---------------------------------------------------------------------------------------------------

## 7. Coach: conversation history and My Memory

### 7.1 Conversation history
- **2025 (Android, v4-era)** `/03`: "‹ WHOOP COACH" header with a **history clock icon** (circular arrow + clock hands, 22 pt) at the top right; empty body; a new-chat speech-bubble "+" icon at bottom-left; "Ask WHOOP anything" field with a violet→blue gradient border and ↑.
- **May 2026 beta v5.3** `/28`, `/29`: the sheet top bar has a "W Beta v5.3" pill (left), a grabber (centre) and the **history clock** (right).
- **v6.0 / v6.1 (Jul–Oct 2026)** `/66`, `/74`, `reviews/r123`: the right of the top bar is "**Memory**" + lightbulb-sparkle icon. **No clock is visible.** Where history moved is **UNCONFIRMED**. Possibilities: the "+" button, a swipe, or a long-press of the version pill.
- **The list screen itself: UNCONFIRMED (no public capture).**
  - Indirect [TEXT]: users cannot name or pin threads and identify a thread "by the wording of the latest response" (forum 14402, 2026-03-31). So rows are probably keyed by the last message snippet with no title.
  - Oct 2025: "couldn't find chat history. It resets every time" (forum 9875).
  - Threads are **context-bound**: opening Coach from a sleep or a workout reopens that item's own conversation ("If I click on say my sleep or a workout it brings up a workout I did 4 days ago and the subsequent conversation…", Reddit 1s4clvx, March 2026). Users also describe separate "Outlook chat" and "chat appended to a specific activity" threads (Reddit 1viywao). So history holds per-context threads plus free chats.
- **ZENO**: a history sheet listing local threads (title = first user message, a 2-line last-message snippet, relative date, swipe to delete), opened from a clock icon beside "Memory". This makes it an [EXTRA] that WHOOP v6 lacks.

### 7.2 My Memory (2026)

**Entry points**:
- the Profile "MY MEMORY" row (`/10`);
- the Coach "Memory 💡" button ("Top right of ai coach window. it lists 'memories'…", Reddit 1t71hle, 2026-05-08, the day of the "New Whoop Feature – Memories" push notification);
- help centre: "Tap the Lightbulb icon in your conversation with Coach, or Tap Personalization in your Profile page".

**First-run onboarding** (beta v5.3, `/24` `/25` `/26`): 3 full-screen pages on near-black with a soft vertical gradient.
- **Page 1**:
  - "✕" top-left;
  - floating glass chips with ✦ icons: "What I'm working toward", "What's limiting my time or energy", "My daily routine and schedule", "Injuries or health changes" (staggered, varied opacity, 1 pt border #1A2730, fill #1B2932);
  - title "Your life changes. Your coaching should too." (26 pt Semibold);
  - body "WHOOP now understands more about what's going on in your life — your goals, routines, and health. / That means smarter check-ins, better timing, and guidance that shows up when it matters most.";
  - bottom-right "GET STARTED" + a 64 pt pink→violet gradient circle with →.
- **Page 2**:
  - "‹";
  - 3-D hourglass art with a "Low grade fever · Inactive" memory chip and a voice waveform;
  - "Tell WHOOP what's going on." / "Add updates about your goals, routine, or health at any time. / The more WHOOP understands, the more it can anticipate what you need and guide you in the moment.";
  - "NEXT" + a ring-progress circle button.
- **Page 3**:
  - a phone mock of MEMORY DETAIL;
  - "You're always in control." / "See what WHOOP understands about you and shape it anytime. / Confirm what's right, refine what's not — your coaching evolves with you.";
  - "VIEW MY MEMORY" + a 64 pt **green #00F19D** circle with ✓.

**Main page — empty** (`/27`):
- "‹ MY MEMORY";
- headline "Shape your WHOOP experience." (26 pt Semibold, left), user avatar (56 pt) right, sub "Help WHOOP understand you better." (13 pt, 80 %);
- input card (radius 20, gradient fill #2C2B4A top-left → #293946 right, 1 pt border #2A2D4C):
  - 3-D box art;
  - "Share something new" (17 pt Semibold);
  - "The more WHOOP knows, the better your guidance becomes" (15 pt, 70 %);
  - two buttons [⌨ TEXT] (#414659) and [🎙 TALK] (#384162, blue tint), h 48, radius 12;
  - link "HOW DOES WHOOP MEMORY WORK? →" (12 pt Bold caps, gradient text violet #8880CB → blue).
- Coach button bottom-right.

**Main page — populated**:
- Marketing render (`help-center/07`): the toast "✓ Context updated / New information applied to Coach.", the headline with **"WHOOP" in blue**, the input card "✦ Anything impacting your routine this week?" [📄][⌨ TEXT][🎙 TALK].
- **Filter chips**: "Timeline" (selected white) | "Goals" | "Lifestyle" | "Health condition" … (scroll).
- Dated sections ("TODAY", "TUE, MAY 20, 2025" in 11 pt caps + hairline).
- Memory cards: title + "New" white pill + "›"; tags "Active" (blue fill) and a category (outlined). The newest card has a violet→cyan gradient border.
- In-app "What's new" card art (`/73`) shows the same cards: "Taylor has an important work presentation coming up on Friday. [Active] [Lifestyle]".
- **Production chip list with all 7 categories: UNCONFIRMED.**
- Categories [TEXT, Locker 2026-05-01]: **Goals · Identity · Lifestyle · Preferences · Events · Health History · Mood**.
- Tags seen: "Identity", "Lifestyle", "Health Condition".

**Memory detail** (`/72` production, `/26` mock):
1. "‹ MEMORY DETAIL 🗑" (trash top-right).
2. Title "Has a son" (22 pt Semibold), body "You have a son named …" (15 pt, 70 %), category tag "Identity" (outlined capsule, 11 pt).
3. Card (radius 14, #2B3033): 💡 icon + "**Active**" (17 pt Semibold) over "This is actively influencing your coaching." (13 pt, **periwinkle** #8F9BFF-ish), with an iOS toggle tinted **#7888FF** when on. Off state shows "Inactive" in the chip mock.
4. "✦ Share something new" card with [TEXT] [TALK].
5. "**Relevant Conversations**" (15 pt Semibold) + bullets "• **May 16, 2026** Has a son named …".

**Memory on/off (global)** (`/55`, June 2026): "✕ AI SETTINGS"
- row "MEMORY" (13 pt Bold caps) with a toggle (off: track #656A6E);
- helper "Allow WHOOP to remember details from past conversations to provide personalized guidance. All data is stored securely by WHOOP and never shared with a third party.";
- dashed divider;
- card "Data privacy / We exist to improve your life, not invade it. You control your personal data. Read more about our commitment to Data Privacy. LEARN MORE →".
- (The Coach on/off toggle was not present for that user; staff: "WHOOP Coach cannot be disabled" — June 2026.)

**Behaviour [TEXT]**:
- view, add (text or voice), edit, remove; turn memory off entirely;
- temporary items (past sickness) are remembered but not actively coached;
- memory drives proactive check-ins (push, e.g. "Stay ahead of today's work day…") and Daily Outlook.
- Users report that Daily Outlook ignores memory preferences (forum 15543, 15909).

**ZENO**: a local MemoryStore (category, title, detail, active flag, createdAt, source conversation ids).
- Inject only Active items into the system prompt.
- "Relevant Conversations" links to local threads.
- A global Memory toggle in Coach settings.

---------------------------------------------------------------------------------------------------

## 8. Population-dependent elements [POP] (ZENO cannot reproduce offline)

| Element | Where | ZENO substitute |
|---|---|---|
| "Top 0.2%" under achievement names; "Top 0.1% / WHOOP" on detail; "Only 35% of members hit this!"; "now in the top 0.6% of all WHOOP members" | Achievements, unlock modal | Personal framing: "Your best year", "Personal record", or omit |
| "Top 2% WHOOP" on Day Streak | Day Streak stats | "Best streak N days" |
| "You're in good company along with 0.5% of other WHOOP members" | 1% Club card | "Your lowest since ⟨date⟩" |
| Level counts are personal: OK. Medal art is OK (own art) | Levels | Fully local |
| Team ranks "322nd of 13.4K", recommended/public teams, member counts, leaderboards, chat, WHOOP-bot champions, invites, follow friends | Community | Not buildable offline. Trends tab replaces Community (spec §3.35). Optional: local "rivals" against your own past self (this week vs best week) |
| YIR "43% of members achieved this in 2025", "Top 2% WHOOP" top performer, "vs WHOOP avg of 45 hrs", **Healthspan Comparison vs "Members like you"** (same age range and gender), global stats | Year in Review | Compare with your own previous year or 90-day baseline |
| Data Highlights, Notable Stats, Activity Summary, streaks, levels, milestones | Profile | Fully local |
| Coach memory, history | Coach | Local store (better privacy) |
| Challenge rewards ("25% OFF YOUR NEXT ORDER"), WHOOP-run challenges with fixed dates, referral rewards and invitee lists | Challenges, Referrals | Personal challenges with local goals and dates; no rewards |
| Rarity pyramid colour (violet vs gold) on achievement cells | Achievements (October 2026) | Use ZENO's own star tiers only |

---------------------------------------------------------------------------------------------------

## 9. Build notes for ZENO (what to copy; SF Pro and SF Symbols, no WHOOP art)

1. **Profile header 2026**: avatar + name + "@handle • age • country" (ZENO: name + "age • strap model"), "✎ EDIT", "Member since ⟨first data date⟩" pill.
2. **LEVEL card → Levels page** exactly as §2.2. Use the 30-level ladder (§2.4) and ZENO-drawn medal and plaque art. Use material names as text (Carbon … Diamond).
3. **MY MEMORY row** with the indigo→teal gradient (§1.2.6).
4. **Achievements** (also add the **achievement chip** on the Recovery / Sleep / Strain deep-dive navs, §3.7b):
   - carousel + page + chips + sections by family shape;
   - detail page with the milestone card, a share sheet (local image render) and the unlock modal;
   - stars 0–6 with ZENO's own metals;
   - criteria: use those confirmed in §3.4 and define ZENO-original rules for UNCONFIRMED ones.
   - Activity badges per sport with ZENO's own pun names. Do not reuse WHOOP's names verbatim except as inspiration.
5. **Day Streak** tiers by length (§4) in ZENO copy.
6. **Community** slot → Trends (already decided). Keep a "Share card" export.
7. **Year in Review**: optional seasonal story (Dec–Jan) with a 7-segment progress bar, local stats only.
7b. **Challenges**: local, user-defined challenges built on the same join / in-progress / complete pages (§3.9). An [EXTRA] works offline: "250 zone-2 minutes this week".
8. **Coach**: history list (clock) + Memory button; My Memory onboarding (3 pages), main page, detail, global toggle.

---------------------------------------------------------------------------------------------------

## 10. Still UNCONFIRMED

1. **Edit Profile form below CITY** (units, weight, height, gender rows; Save button placement). The top half is seen in `/77`.
2. **Levels "?" info sheet** contents; grid cells for L7–L30; their material names and tier-start ring markers.
3. Achievements page **6th filter chip**: only "Act…" is visible (probably "Activities"). The section after HEALTHSPAN; whether the (N) count means unlocked or total; full badge catalogue and criteria for Pillow Perfect, Green Week, Peak Day, Strain Seeker, All Out Day, Healthspan Comeback; the exact star cut-offs.
4. **Team INFO tab below ABOUT** (data sharing, member list, admin controls); Pending Invites row style; unread chat badges on team rows; Explore Teams / VIEW ALL list; member profile screen; Create Team flow (2025–26).
5. **Follow-friends final UI** (shipping November 2026 per roadmap); the Friends section on the Community root (only described in text).
6. **YIR Home entry icon**; intro splash; the "message to your future self" step; slides 1, 3 and 5 identity and order; the share-button screen.
7. **Coach conversation-history list** (any version), and how history is reached in v6.x.
8. **Production My Memory list** with all 7 category chips, and the memory "Inactive" state on the detail page.

---------------------------------------------------------------------------------------------------

## 11. Image index (`images/profile-community-2026/`)

| # | What it shows | Date / source |
|---|---|---|
| 01 | Community root: SHARE A FREE TRIAL banner, Teams •••, MY TEAMS + DAILY STRAIN RANK ⌄, 4 team rows with ranks, RECOMMENDED TEAMS tiles, docked tab bar | 2025-06 forum (staff) |
| 02 | Same with iOS action sheet: Create Team / Enter Invite Code / Explore Teams / Cancel | 2025-06 forum |
| 03 | WHOOP COACH (Android) empty: history clock top-right, new-chat icon, gradient field | 2025-10 forum |
| 04 | Achievements page top: "All Achievements (24)", chips All/Sleep/Recovery/Strain/Healthspa…, SLEEP/RECOVERY/STRAIN grid, HEALTHSPAN label | 2026-09-05 Reddit |
| 05 | Achievement Details Gear Grinder 1150: share icon, Top 0.1%, milestone 1173→1200, SHARE ACHIEVEMENT (Android) | 2026-08-31 Reddit |
| 06 | Achievement Details Human Metronome 23 with criterion and pyramid "Top 0.02%" | 2026-08-12 Reddit |
| 07 | Achievement Details Sleep Specialist 1950 → 2000 (no share; April build) | 2026-04-28 Reddit |
| 08 | Achievement Details Runner's High 101 → 150, Top 9% | 2026-05-28 Reddit |
| 09 | Crack Commander rosette badge 5 (chiropractic) | 2026-10-02 Reddit |
| 10 | Profile August 2026: Member since, LEVEL 27 diamond 2344, WHOOP AGE, DAY STREAK 372, **MY MEMORY row**, Achievements (34) + VIEW ALL with stars | 2026-08-12 Reddit |
| 11 | **Levels page** Diamond L29, progress, "1 more Recovery to Level 30" | 2026-09-21 Reddit |
| 12 | Unlock modal "Healthspan Time Traveler -4 Yrs", Next Milestone, CLOSE / VIEW | 2026-06-21 Reddit |
| 13 | Challenge page ALL-IN 250 (460/250), VIEW ACHIEVEMENT | 2026-07-04 Reddit |
| 14 | Profile achievements carousel (Spanish "Logros (8)") + Data Highlights | 2026-06-12 Reddit |
| 15 | Day Streak 1337 blue flame, share icon, 1300→1350, Legendary consistency | 2026-08-20 Reddit |
| 16 | Home "99% Club" coaching card | 2026-07-26 Reddit |
| 17 | YouTube storyboard L3 sheet M12 (frames 108–116) | NrCpf_m75XM (2026-04) |
| 18 | Upscaled frame 110: 2026 Community root (INVITE A FRIEND, Teams, 3 team rows, TEAM CAFFEINE / ROAD RUNNERS tiles, floating tab bar) | NrCpf_m75XM |
| 19 | Home "Introducing achievements" card | 2026-04 gadgetsandwearables |
| 20 | Profile coach-mark "Introducing achievements / GOT IT" | 2026-04 G&W |
| 21 | **Profile top April 2026**: avatar, name, @handle • age • country, **✎ EDIT**, Member since, LEVEL 22, WHOOP AGE, DAY STREAK, Achievements (10) | 2026-04 G&W |
| 22 | Profile Data Highlights, Streaks, Notable Stats | 2026-04 G&W |
| 23 | Profile Notable Stats end, Activity Summary (1010x, rows, SHOW ALL), Referrals title | 2026-04 G&W |
| 24 | My Memory onboarding 1 "Your life changes…" GET STARTED | 2026-05 G&W (beta 5.3) |
| 25 | Onboarding 2 "Tell WHOOP what's going on." NEXT | 2026-05 G&W |
| 26 | Onboarding 3 "You're always in control." with MEMORY DETAIL mock + Active toggle, VIEW MY MEMORY | 2026-05 G&W |
| 27 | MY MEMORY empty state (Share something new, TEXT / TALK, HOW DOES WHOOP MEMORY WORK?) | 2026-05 G&W |
| 28 | MY MEMORY with Coach sheet (Beta v5.3, history clock) | 2026-05 G&W |
| 29 | Coach sheet Beta v5.3 full: history clock, suggestion chips, dictation bar | 2026-05 G&W |
| 30 | LEGACY 2019 create-team flow frames | whoop.com Locker GIF |
| 31 | LEGACY 2019 team About / Data sharing / Members page (INFO-tab precursor) | Locker GIF frame 150 |
| 32 | Profile Achievements (8): Healthspan Comeback +1, Stride Scholar 200, Green Monster 200 (Android) | 2026-04-09 Reddit |
| 33 | A friend's profile: "Achievements" (no count): Time Traveler -3, Walk Star 10… | 2026-03-13 Reddit |
| 34 | Home "Zombie Sleeper" card | 2026-02-09 Reddit |
| 35 | Home "1% Club" card (0.5% of members) Android | 2026-07-20 Reddit |
| 36 | Unlock modal (German) Healthspan-Zeitreisender -10 Jahre | 2026-07-19 Reddit |
| 37 | Day Streak 2046 gold flame, 2000→4000, Legacy-level dedication | 2026-01-05 Reddit |
| 38 | Day Streak 148 orange (2025), "Holding the flame" | 2025-06-11 Reddit |
| 39 | Home "All-In 250 Challenge Starts Today" card | 2026-06-29 Reddit |
| 40 | LEGACY 2024 Year in Review story: 1848 days, Level 25 | 2024-12-15 Reddit |
| 41 | 2025 Home variant with shop cart and a Profile tab in the tab bar | 2025-06-06 Reddit |
| 42 | Challenge ALL-IN 250 (276/250) | 2026-07-05 Reddit |
| 43 | User-made table: recoveries to next level, L1→L30 | 2026-08-15 Reddit comment |
| 44 | Crops: level medals Platinum L22/L24/L25 vs Diamond L27/L29 | derived |
| 45 | YIR 2025 slide 4/7 "Sleep / 2025 Top Performer / Top 2%" | 2025-12-22 Reddit comment |
| 46 | Same slide, avatar + name variant, Top 3% | 2025-12-22 Reddit comment |
| 47 | YIR slide 7/7 persona "The Year You FOUND FLOW" | 2025-12-24 Reddit comment |
| 48 | YIR persona "The Year You Kept Showing Up" | 2025-12-23 Reddit comment |
| 49 | YIR persona "The Year You BUILT FROM THE GROUND UP" | 2025-12-23 Reddit comment |
| 50 | YIR slide 6/7 "808.7k" steps, Everest ×8 (+ an unrelated Trend View) | 2025-12-28 Reddit comment |
| 51 | YIR "Total Strength Activity Time 144 hrs ▲ vs WHOOP avg of 45 hrs" (crop) | 2025-12-22 Reddit comment |
| 52 | YIR month slide "April / 1% Club" (inset crop) | 2025-12-22 Reddit comment |
| 53 | YIR Healthspan Comparison variant (-7.8 vs -0.7 years) | 2025-12-23 Reddit comment |
| 54 | Team CHAT tab (Android): WHOOP bot weekly champions | 2025-10 forum |
| 55 | AI SETTINGS: MEMORY toggle + Data privacy card | 2026-06 forum |
| 56 | **Levels page** L30 "highest level" + grid Carbon / Iron / Steel / Gunmetal / Titanium / Bronze | 2026-05-04 Reddit |
| 57 | Levels page 2024 build: Gold L18, progress bar, grid | 2024-09-08 Reddit |
| 58 | Achievement share card Green Monster 950 Top 0.4% | 2026-05-13 Reddit |
| 59 | Home "1% Club" card (iOS) | 2026-09-03 Reddit |
| 60 | Day Streak 1 yellow "Spark's lit" | 2026-03-07 Reddit |
| 61 | Day Streak 101 orange, Top 50% | 2026-03-03 Reddit |
| 62 | Day Streak 364 red, "Every day counts" | 2026-04-08 Reddit |
| 63 | Day Streak 365 magenta, 365→730 | 2026-03-14 Reddit |
| 64 | Day Streak 2370 gold, Top 0.1% | 2026-03-29 Reddit |
| 65 | "New Day Streak Unlocked" modal 2000/2050 | 2026-08-19 Reddit |
| 66 | Coach v6.1 sheet: "Memory 💡", no clock, chips, + and mic | 2026-10-01 forum |
| 67 | Coach chip "Explore popular public teams" | 2026-09-06 forum |
| 68 | Public team "WOMEN 40-50" recovery leaderboard, no CHAT tab, own rank pinned (#290) | 2026-07-13 Reddit |
| 69 | Leaderboard settings sheet: DISPLAY RANK AS / OVER THE COURSE OF / APPLY (Android) | 2025-10-06 Reddit |
| 70 | Team "JIU JITSU" sleep leaderboard, BACK TO TODAY, settings sheet peeking (Android) | 2025-09-30 Reddit |
| 71 | YIR Healthspan Comparison, Title Case header variant | 2025-12-16 Reddit |
| 72 | **MEMORY DETAIL** (production): Identity tag, Active toggle, Share something new, Relevant Conversations | 2026-05-20 Reddit |
| 73 | In-app "What's new": memory cards with Active / Lifestyle tags | 2026-05-10 Reddit |
| 74 | Coach v6.0 AI chart "STRAIN & RECOVERY — LAST 30 DAYS" | 2026-07-30 Reddit |
| 75 | **Community root 2026** (iOS, floating tab bar): MY TEAMS, MONTHLY STRAIN RANK, 8 rows with ranks, RECOMMENDED TEAMS | 2026-07-07 Reddit |
| 76 | Challenge ALL-IN 250 in progress: 168/250, "4 days left", "Great start!", ADD ACTIVITY | 2026-07-03 Reddit |
| 77 | **EDIT PROFILE** with the "Set Your Birthday" wheel sheet (CANCEL / CONFIRM disabled); fields behind it: birthday, COUNTRY, STATE, CITY | 2026-06-23 Reddit |
| 78 | Home variant: docked tab bar Home · Health · Community · **Profile** (avatar with a ≡ badge; replaces More); Coach "W" inline in My Day; floating "+" | 2026-07-24 Reddit |
| 79 | Profile carousel: All Out Day 299 (no art), Grit Grinder 100, VO₂ Phenom -6yrs | 2026-09-03 Reddit |
| 80 | **New achievements page (October 2026)** top: "All Achievements (33)", chips, dates under names, 6★ Sleep Specialist and Green Monster | 2026-10-01 Reddit comment |
| 81 | **New achievements page (October 2026)**: "(30)", chips "…Healthspan · Act…", percentile lines with violet or gold pyramids, Stars & Strides 250 | 2026-10-01 Reddit comment |
| 82 | Achievement Details 1% Club 17 "Logged 1% Recovery", red glow, layered pyramid "Top 0.4%" | 2026-10-01 Reddit comment |
| 83 | Recovery deep dive with an **achievement chip** (Green Monster mini-badge + 307) at the nav right | 2026-07-10 Reddit |
| 84 | Challenge **join page**: Go All-In: 250 Minutes in 7 Days, WHAT YOU EARN, JOIN CHALLENGE | 2026-06-22 Reddit |
| 85 | Challenge badge unlock modal "Stars & Strides" with CLOSE / SHARE (Android) | 2026-07-01 Reddit |
| 86 | **Team INFO tab** (iOS): banner behind tabs, logo + "GRIND2FIND", ABOUT + description (large invite-code text is probably a user overlay) | 2025-08-20 Reddit |
