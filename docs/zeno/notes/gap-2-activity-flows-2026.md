# Gap 2: activity flows, 2025-26 iOS

Research date: 2026-10-02. Scope: every activity-flow screen in the current WHOOP iOS app:

- (a) Start Activity pre-start
- (b) live session, pause/resume, end and save, post-save
- (c) Add Activity, its activity list and the "where did you wear" question
- (d) Edit Activity
- (e) recovery-activity details
- (f) GPS route card and shareable snapshot
- (g) Strength Trainer 2026

All images are in `whoop-reference/images/activity-flows-2026/`. That folder is a private local reference only; never copy it into the repo. The file prefix is the flow letter (`a`–`h`, plus `s` for storyboards). §11 lists every file with its post date, page URL and image URL.

**Tags**

| Tag | Meaning |
|---|---|
| **[SEEN]** | Read off a legible screenshot listed in §11. |
| **[TEXT]** | Only official or user text describes it. |
| **[SB]** | Seen only as structure in a blurry YouTube storyboard. |
| **UNCONFIRMED** | Not verified visually. |

**Measurements.** Sizes are in pt at 3x and are estimates. Hex colours were sampled with Pillow from the JPEG/PNG captures, so compression shifts them by about ±3–6 per channel.

---------------------------------------------------------------------------------------------------

## 0. Coverage summary

| Item | Status | Best files |
|---|---|---|
| (a) pre-start: GPS map variant | **SEEN** iOS Aug 2025, Nov 2025; [SB] Apr and Jun 2026 | a01, a04, s02, s04 |
| (a) pre-start: strap-render variant (no map, Track Route off) | **SEEN** iOS Sep 2025 (low-res, composite); [SB] Apr and Jun 2026 | a03, s02 |
| (a) pre-start: recovery-activity variant (Sauna) | **SEEN** iOS Jan 2026 | a07 |
| (a) Strain Target panel, expanded (ring and training-state chart) | **SEEN** iOS Dec 2025 | a05, a06 |
| (a) activity picker sheet | **SEEN** (iOS in completeness-critic/05; Android a09, a10) | a09, a10 |
| (b) live screen, Activity Strain page | **SEEN** iOS Sep 2025, Mar, Apr and Aug 2026 | b01–b04 |
| (b) live screen, Map page | **SEEN** iOS Jan, Feb and May 2026 | b05–b07 |
| (b) live screen, Heart Rate page | iOS 2026 **UNCONFIRMED**; Android Feb 2026 **SEEN** (b08); iOS 2023 in design-language/31 | b08 |
| (b) pause / resume | **Does not exist** in the current app (WHOOP staff text, 2025; user text through Aug 2026; WHOOP says it is coming in Nov 2026) | – |
| (b) End & Save confirmation | **UNCONFIRMED**: no capture found anywhere | – |
| (b) post-save summary | **UNCONFIRMED**: no capture found | – |
| (b) Live Activity on Apple Watch Smart Stack | **SEEN** Apr 2026 | b09 |
| (c) ADD ACTIVITY form | **SEEN** iOS Oct 2025 (small); [SB] Apr and Jun 2026 | c01, s01, s04 |
| (c) activity list for Add/Edit ("SELECT YOUR ACTIVITY" sheet) | **SEEN** iOS Aug 2025, Dec 2025, Jun 2026 | c02–c05 |
| (c) "Where did you wear your WHOOP?" | **SEEN** inside the Add and Edit forms (button "WRIST BAND"). The option list is **UNCONFIRMED**. | d03, d04, c01, s01 |
| (c) errors (overlap, request failed, invalid duration, network) | **SEEN** | c01, c06–c09 |
| (d) Edit Activity, pre-June-2026 form | **SEEN** iOS Jul and Nov 2025; [SB] Jun 2026 | d03, d04, s03 |
| (d) Edit Activity with HR-graph scrubber (iOS, Jun 25 / Jul 1 2026) | **NOT FOUND**, [TEXT] only. Closest visuals: the scrub readout on recovery details (e03) and the landscape day-HR scrub (e04). | e03, e04 |
| (e) recovery-activity details (sauna, steam, contrast therapy, meditation, breathwork) | **SEEN** iOS Jul 2025 – Aug 2026, including "IMPACT ON RECOVERY" | e01–e03, e08–e11 |
| (f) route card with share icon | **SEEN** iOS May and Aug 2026; Android Aug 2026 | f02–f05 |
| (f) shareable snapshot graphic | **SEEN** (the exported image, May 2026) | f01 |
| (f) snapshot sheet UI (transparent-background toggle, share targets) | **UNCONFIRMED**: not captured | – |
| (g) Strength Trainer root tabs | **SEEN** May 2026 (MY WORKOUTS, PROGRESS) | g01, g02 |
| (g) live session (REST / ACTIVE / START SET → END SET) | **SEEN** iOS Jul 2025 and Sep 2026 (GIF) | g07*, g10 |
| (g) live EXERCISES tab | **SEEN** Dec 2025 and Sep 2026 | g08, g09 |
| (g) Exercise Details, new (Progress / History / Instructions + PRs) | **SEEN** Jul 2026 | g03 |
| (g) Exercise Details, old ("Coming Soon") | **SEEN** May–Jul 2026 | g04–g06 |
| (g) Strength Trainer activity details and exercise summary | **SEEN** Feb–Aug 2026 | g12, g15–g18, g24, g26 |
| (g) WHOOP WORKOUTS tab, 2026 | **UNCONFIRMED** (the tab label is SEEN; the content is not) | – |

---------------------------------------------------------------------------------------------------

## 1. Method and sources

### 1.1 YouTube storyboards (structure only)

| Video | Date | Spec |
|---|---|---|
| **GqKZ-NXWn-g**, "How to Log an Activity in WHOOP (2026 Update)", channel *Mr. Whoop* | published 2026-06-01, 260 s | storyboard L3 = 276×180 px tiles, 3×3, 131 frames, 2 s each; phone ≈ 55×120 px |
| **NrCpf_m75XM**, "FULL WHOOP App Walkthrough (2026 Update)", *Mr. Whoop* | 2026-04-21 | L3 = 320×180 px, 10 s per frame; phone ≈ 86×174 px; sheets M8–M9 used |

How the sheets were fetched:

- The sheets come from the `playerStoryboardSpecRenderer` spec (`$L` = 3, `$N` = `M<i>`, plus `&sigh=`).
- The phone was cropped and upscaled ×4 (`s01`–`s04`). Text is unreadable; only order and layout are used.

Other videos checked had no usable UI: `qsYwNkMynro` (2025-08-06) is a text slideshow, and `kQF1LubueeU` (2025-07-05) shows mid-2025 UI with no activity flow.

### 1.2 GqKZ-NXWn-g flow order (frame → time) [SB]

| Time | What the storyboard shows |
|---|---|
| t = 0–38 s | Home (dials → My Day → TODAY'S ACTIVITIES with rows + "+ ADD ACTIVITY" / "⏱ START ACTIVITY") |
| t = 40–52 | "‹ SELECT ACTIVITY" page: search field, tab row, a "MOST RECENT" group of 4 card rows, an "ALL A-Z" label, then card rows (Acupuncture, Air Compression, Air Compression (Normatec)…) |
| t = 54–74 | "✕ ADD ACTIVITY" form: blue-outlined info banner; activity row with "›"; TIME; Start Time / End Time pills; LOCATION; "Where did you wear your WHOOP?" + a full-width button. Tapping that button (t = 62–64) opens an **inline 3-row wheel** under it. A white "SAVE" capsule sits at the bottom. |
| t = 76–86 | back on Home |
| t = 88 | Start Activity pre-start, GPS sport: map + blue HR circle "81" + white bottom panel "11.x STRAIN TARGET [toggle]" + blue "START ACTIVITY" |
| t = 90 | activity picker sheet (black list) dropped down from the header |
| t = 92–106 | pre-start for a strength sport: dark strap render behind the HR circle (80/79/78/77/78/79/80) and the same white panel |
| t = 108 | Home. **The video never starts the live session**, so it shows no live, pause or end screens. |
| t = 112–146 | Activity Details (weightlifting): blue-bordered coach card, "10.x" strain + CARDIO/MUSCULAR bar, HR graph, zone rows, KEY STATISTICS tiles, then a coach chat thread with two suggestion pills |
| t = 150–168 | Activity Details (running): strain + steps, HR graph, coloured zone rows, KEY STATISTICS, ROUTE map card (light map) |
| t = 170–172 | an iOS action sheet rises from the bottom (overflow menu) |
| t = 174–178 | "EDIT ACTIVITY" form (sheet): activity row, Start/End pills, the location question + button, a white SAVE capsule. **This is the pre-scrubber form; the video is dated 1 Jun 2026.** |
| t = 180–262 | back to details and Home |

### 1.3 NrCpf_m75XM M8–M9 [SB]

| Time | What the storyboard shows |
|---|---|
| t = 760 | WEIGHTLIFTING details with a top banner card (blue-violet border, ✕; title probably "Get More from Your Workouts", **UNCONFIRMED**), then strain 12.3 + CARDIO/MUSCULAR bar |
| t = 790–800 | RUNNING details (10.0 strain + 1,037 steps) |
| t = 810 | "‹ SELECT ACTIVITY" (search; 4 tabs; MOST RECENT: Walking, Running, Weightlifting, Swimming?, Functional Fitness; ALL A-Z) |
| t = 820 | "✕ ADD ACTIVITY" (banner; a "SELECT ACTIVITY ›" placeholder row; Start/End pills "Apr 14 at 5:xx PM"; LOCATION; "Where did you wear your WHOOP?"; a button; a disabled SAVE) |
| t = 840 | pre-start WALKING (map, HR 81, 11.2 Strain Target) |
| t = 850 | pre-start WEIGHTLIFTING (strap render, HR 82) |

### 1.4 Reddit

- **RSS** (`/r/whoop/search.rss?q=…&restrict_sr=1&sort=new&limit=50`, UA `zeno-research/1.0 (personal research script)`, ≥ 50 s apart):
  - "start activity" succeeded at 11:34 (50 entries).
  - Every later query got a persistent **HTTP 429** for about 70 minutes. The headers showed `x-ratelimit-remaining: 0` every minute, because sibling agents share the IP.
- **Fallback:** the same 14 queries, plus extra ones, were run through the public **Arctic Shift Reddit archive API** (`arctic-shift.photon-reddit.com/api/posts/search?subreddit=whoop&query=…&after=2025-06-01`). It returns the same r/whoop posts with gallery metadata.
- Images came directly from `i.redd.it`. Some are deleted (404) and were skipped.
- Extra queries:
  - post title searches: edit, graph, trim, finish, save, ended, breathwork, meditation, breathing, zones, summary;
  - full-text searches: "start time", "end time", drag, slider.

### 1.5 Forum

- Source: `community.whoop.com/search.json?q=<term> with:images order:latest`, then `/t/<id>.json`, taking the `/uploads/…/original/…` hrefs.
- Terms: the 14 required terms plus scrub, edit, trim, share, transparent, discard, stop activity, finish activity, end workout, save activity, activity summary, breath, relaxation, recovery activities, steam, live screen and timer.
- Dated text-only searches: "edit after:2026-06-01", "pause activity", "resume activity", "paused".

### 1.6 Official text

- whoop.com "2026 What's New" (via r.jina.ai): Edit Activity HR graph (Jun 25 and Jul 1), shareable snapshot (Apr 3), Exercise Details (May 20), Strava (May 21).
- gadgetsandwearables.com, 2026-09-05: November 2026 "Track Activity" rebuild with pause/resume.
- Help-center texts already saved in `raw/help-center-articles/` (Strain-Coach, Strain-and-Recovery-Details-Screens, Automatic-and-Manual-Activity-Detection, Track-Muscular-Load-with-Strength-Trainer).

---------------------------------------------------------------------------------------------------

## 2. Entry points into the activity flows

- **Home → My Day → TODAY'S ACTIVITIES card** [SEEN in many captures, e.g. b03, c06, g24]:
  - footer buttons "＋ ADD ACTIVITY" and "◷ START ACTIVITY";
  - when there are no activities, or on a past day, only "＋ ADD ACTIVITY" spans the full width. Example: a past day, Dec 11 2025 (community.whoop.com/t/6727/3); that image is not copied here.
- **"+" next to "My Day"**:
  - The **2026 popover menu** is documented in help-center §3 / reviews.
  - The **Aug 2025 variant** (a02) is a full-screen dim with right-aligned rows: label + **white 44 pt circle icon**, in order CREATE WHOOP LIVE (camera) · MY JOURNAL (notebook) · STRENGTH TRAINER (lifter) · ADD ACTIVITY (+) · START ACTIVITY (stopwatch), and a "−" close circle. This is LEGACY for 2026.
- **Activity Details "•••"**: an iOS action sheet with "Edit" (blue, system) / "Delete" (red) / "Cancel" (d02, d06). For Strength-Trainer-linked activities it shows only **Delete / Cancel** (d05).
- **Unknown auto-detected "ACTIVITY"**: tapping its name opens "SELECT YOUR ACTIVITY" with an explanatory line (c02).
- **Siri**: not supported. "Sorry, WHOOP hasn't added support for that with Siri." (reddit 1t8u01h, 2026-05-10)
- **Coach chat** [TEXT, Jun 29 2026]: "Add, edit, or delete an activity just by asking WHOOP in chat."

---------------------------------------------------------------------------------------------------

## 3. (a) Start Activity pre-start [SEEN]

A full-screen modal over Home. Files: a01 (iOS 1284×2778, Aug 2025, posted by WHOOP staff @samdarkwa), a04 (Nov 2025), a03 (Sep 2025 composite, low-res), a07 (Sauna, Jan 2026); storyboards s02 (Jun 2026) and s04 (Apr 2026). The **layout is identical in 2025 and the 2026 storyboards.**

### 3.1 Header bar

- Translucent near-black over the content: **#0A0D12** sampled over the map (a01); #161B1F–#1B2024 over the strap render (a03).
- Height ≈ 130 pt including the status bar (a01: 392 px).
- Row content, left to right:
  - "✕" (white, thin, ~20 pt);
  - white activity pictogram (~28 pt);
  - activity name in **bold caps with wide tracking**, ~15 pt, white ("RUNNING", "WALKING", "SAUNA", "WEIGHTLIFTING");
  - "⌄" chevron at the far right.
- Tapping the name or the chevron drops the activity picker down from the header. The header then shows "⌃" (completeness-critic/05).

### 3.2 Track Route toggle (GPS sports only)

- Label "Track Route" (grey, Title Case, ~13 pt) + a small iOS-style toggle, top-right just under the header.
  - **Off**: light-grey track, white knob (a03).
  - **On**: blue knob (a01, a04: circled by the user).
- **Track Route on** → the background is a **dark-tinted Apple Map** (standard style, dimmed ≈ 60%) centred on the user.
- **Track Route off or non-GPS sport** → the background is a **3D render of the strap/band** (WHOOP 5.0 knit band with the "WHOOP" sensor) on a vertical gradient:
  - a03 ≈ #293239 at the top → #0D1114 at the bottom.

### 3.3 Live HR circle

| Variant | Diameter | Fill | Halo |
|---|---|---|---|
| a01 (GPS/strain) | ≈ 181 pt, centred ≈ 45% down the screen | **#1C90DD / #1B8FDC** | ring ≈ 30 pt wide, **#31648F** (semi-transparent blue) |
| a07 (recovery sport) | – | lighter "recovery blue" **#7EB2EB** | mid ring **#384A60** + faint outer ring |

Content (all variants): white heart glyph (~22 pt) · HR value (white bold condensed, ~64 pt: "77", "82", "127", "66") · strap battery row "▭ 75%" (battery glyph + %, ~14 pt, dark-blue/white tint).

### 3.4 Bottom panel (strain sports only)

The panel is pinned to the bottom of the screen.

1. **Header row**:
   - white **#FFFFFF**, top corners radius ≈ 10–12 pt, top edge ≈ 716 pt from the top on a 926 pt-tall screen;
   - grey grabber **#E5E5E5** (≈ 64×5 pt) centred at the top;
   - row height ≈ 83 pt.
   - Row content, left to right:
     - a ≈ 26 pt **ring glyph** (light track #FDFDFD, blue arc ≈ #0987DC) showing the target;
     - the **target value** "12.2" (black **#000000**, bold, ~22 pt);
     - "**STRAIN TARGET**" (black bold caps, tracked, ~14 pt, centred);
     - a **toggle** (track #E5E5E5, **black knob #000000**; knob on the right = ON).
   - OFF state on Android: "◯ --- STRAIN TARGET [toggle] OFF" (a08).
2. **Button area**:
   - light grey **#F5F5F5**;
   - blue capsule "**START ACTIVITY**": **#0193E8**, white bold caps tracked ~15 pt, ≈ 273×49 pt, centred, ≈ 45 pt above the bottom edge (a01).
3. **Dragging the panel up** expands it into the **Strain Target panel** (§3.6).

### 3.5 Recovery-activity variant (a07, SAUNA, Jan 2026)

- **No Strain Target panel.**
- No strap render: plain concentric halo rings.
- The circle is light blue (#7EB2EB).
- The button is a **white-outline capsule "START ACTIVITY"** (≈ 1.5 pt white stroke, white bold caps) on the dark background (#0D1114).

### 3.6 Strain Target panel, expanded (a05, a06, iOS, Dec 2025)

The panel keeps a white header row:

- "?" in a thin grey circle (left);
- "STRAIN TARGET" (black bold caps);
- the toggle (right).

The body is light grey #F5F5F5. Two views were captured. Whether they are pages of one pager or one scroll is **UNCONFIRMED**.

**View 1 (ring):**

1. Big ring (~300 pt):
   - track light grey;
   - arc gradient **navy → bright blue** (≈ #0D2A5E → #1A9BE6) running clockwise from 12 o'clock;
   - a **white knob with the W logo** at the arc end (drag to set the target).
2. A **dashed arc outside the ring labelled "OPTIMAL"** (text follows the curve) marks the optimal window.
3. Centre text: "ACTIVITY STRAIN" (black bold caps) · "13.2" (black bold ~80 pt) · "OPTIMAL" (grey caps) · a reset icon (circular arrow in a thin grey circle).
4. Footer: W in a circle + "Based on your 78% Recovery, build a 13.2 Activity Strain to reach your optimal Day Strain." (black, ~20 pt).

**View 2 (training-state chart):**

1. "TRAINING STATE: OPTIMAL" (black bold caps).
2. Three columns, each with a legend square and separated by "›":

   | Legend square | Label | Value |
   |---|---|---|
   | solid blue ■ | CURRENT DAY STRAIN | 12.6 |
   | hatched light blue ▨ | ACTIVITY STRAIN | 13.2 |
   | half solid / half hatched | ESTIMATED DAY STRAIN* | 16.1 |

   Labels are grey caps; values black bold ~34 pt.
3. A "DAY STRAIN" bar chart:
   - y-labels in blue (0.0 / 6.0 / 10.0 / 14.0 / 18.0 / 21.0);
   - "OPTIMAL TRAINING" grey caps in the band;
   - one bar: solid blue to 12.6, then hatched to 16.1, with a black cap tick and the label "16.1";
   - a dashed line at 16.1;
   - x baseline split **red | yellow | green** thirds, with the recovery "78%" under the bar.

[TEXT, Strain-Coach]:

- intents are Restorative / Optimal / Overreaching;
- the target updates every 10 min;
- a haptic + notification fires at the target;
- adjusting the target for Recovery activities is Android-only;
- a 24 h maximum duration.

### 3.7 Activity picker (dropdown sheet)

- **iOS** (completeness-critic/05, Sep 2025):
  - black full-height list;
  - search field "Search" (white 10% fill, radius ≈ 10);
  - tabs ALL | STRAIN | RECOVERY | SLEEP (underline);
  - "MOST RECENT" with a highlighted current row (white 8% fill);
  - "ALL A-Z" rows: white pictogram + **bold caps** name, ≈ 52 pt pitch, no cards.
- **Android** (a09, a10): same structure. Android shows the name in Title Case with a caret ("Pilates ▾" / "Weightlifting ▴"). The "Most Recent" group has 4 items (May 2026). The Jan 2026 changelog says "5 most-recent activity types when adding an activity".
- Text evidence:
  - Strength Training was missing from the Start Activity list after the 15 Jul 2026 update but present in Edit (forum 15783).
  - "Why can't I select Strength training from the start activity action, but I have to log it using add activity?" (reddit 1pjhn7y, 2025-12-10)
  - "Sleep" can be started as a live activity (reddit 1vhov6w, Aug 2026).

---------------------------------------------------------------------------------------------------

## 4. (b) Live in-progress screen (iOS) [SEEN]

Files:

- b01: iOS 1206×2622, Sep 2025, Activity Strain page, 3-page pager;
- b02: Mar 2026, user-annotated red text over the screen;
- b03: Apr 2026, 2 pages;
- b04: Aug 2026, after 1 h;
- b05–b07: Map page, Jan / Feb / May 2026.

Old-design reference for the Heart Rate page: design-language/31 (2023, red band).

### 4.1 Global structure

- A full-screen modal. **There is no tab bar and no way to minimize.** From forum 14909 (2026-05-22): "when an activity is active, the app feels locked into that activity screen."
- A horizontal **pager** with a footer.
- **Page order: [Heart Rate] ← [Activity Strain] → [Map].**
  - The Map page exists only for GPS / Track Route activities: 3 dots vs 2 dots.
  - Activity Strain is the middle page (b01: middle of 3 dots; b02/b03: second of 2). Every capture shows this page, but whether the pager **opens** on it is UNCONFIRMED.
- **Top band**:
  - solid **#0193E9** blue, full width, ≈ 143 pt tall including the status bar (b01: 430 px).
  - Band history, all sampled:

    | Platform / date | Band | Glyph |
    |---|---|---|
    | iOS 2023 (design-language/31) | **#FE0026** red | – |
    | Android Sep 2025 (completeness-critic/06) | **#ED2E0D** red-orange | "❚❚" |
    | Android Feb 2026 (b08) | blue **#0193E9** | "❚❚" |
  - Content: a white **flag glyph ⚑** + elapsed time "00:27:53" (white bold, ~20 pt, centred).
  - The flag is the end-activity affordance; this is **UNCONFIRMED** (no capture of the tap result). [TEXT] WHOOP: "Tap End & Save to log your workout".
- **"LIVE" button**: top-right under the band. A ~36 pt ring containing a camera glyph and a small "W", with "LIVE" (white bold caps ~12 pt) under it. This is WHOOP Live, the photo/video overlay.
- **Background**: vertical gradient **#2D383E** (just under the band) → #1A2129 (ring level) → **#0C1013** (≈ 80% down) → slightly lighter **#181F27** at the very bottom.

### 4.2 Activity Strain page (b01–b04)

1. **Ring**:
   - outer diameter ≈ 288–290 pt, centred ≈ 376 pt from the top; stroke ≈ 16 pt;
   - track **#333740**;
   - progress arc from 12 o'clock clockwise with a gradient: **#132F5F (navy) at the start → #025DA4 → #0082D6 (bright) at the arc head**.
2. **Target knob**:
   - a small circle (≈ 22 pt) with the **user's avatar** (photo, or initials on a coloured disc: "KA" orange, "JC" yellow-green) and a **short white radial tick**, sitting on the ring;
   - position examples: ≈ 255° in b01 (≈ 14.9 on 0–21), ≈ 210° in b02, ≈ 200° in b03.
   - Reading it as the **activity Strain Target** (not the current value) is inferred from the arc/knob geometry: **UNCONFIRMED**.
3. **Centre text**:
   - "ACTIVITY STRAIN" (white bold caps, cap height ≈ 10 pt → ~14 pt font);
   - value "10.8" (white bold condensed, digit height ≈ 50 pt → ~70 pt font; the locale decimal comma "4,7" appears in b03);
   - an intensity word in grey caps ~13 pt. Seen: **RESTING** (0.0 / 4.6 / 4.7) and **MODERATE** (10.8). Other words (LIGHT / STRENUOUS / ALL OUT) are **UNCONFIRMED**.
4. **HEART RATE block** (left-aligned, 16 pt inset):
   - "HEART RATE" (grey caps ~12 pt);
   - live value "142" (white bold ~34 pt);
   - a **6-segment zone bar** (Zone 0…Zone 5): the current segment is lit in its zone colour (Zone 2 light blue; Zone 0/1 white/grey) with a **white dot** marking the position; other segments are dark tints of their zone colours;
   - labels "Zone 0 … Zone 5" (Title Case, ~11 pt): the current one is white/coloured, the others dimmed in zone tints.
5. **Stats row**: three equal columns separated by thin vertical hairlines.

   | Icon (grey) | Label (grey caps ~11 pt) | Example value |
   |---|---|---|
   | heart | AVG HR | 151 |
   | heart-with-↑ | MAX HR | 177 |
   | flame | CALORIES | 314 |

   Values are white bold ~34 pt.
6. **Footer**: "← Heart Rate" (white 70%, ~15 pt) at the left · page dots in the centre · "Map →" at the right (GPS only).

### 4.3 Map page (b05–b07)

- Same blue band.
- A full-bleed **Apple Map (light standard style)** with the route as a ~5 pt **blue line (#0A8AF0)** and the current-position dot.
- Apple "Maps / Legal" attribution at the bottom-left of the map.
- **Bottom stats panel**: near-black **#0E1215 → #171E26**, three columns:
  - "→ DISTANCE 3.5mi"
  - "🚶 SPEED 3.6mph" (a walker pictogram in b05; whether it changes per sport is UNCONFIRMED)
  - "⏱ DURATION 0:59"
  - Icons are grey; labels grey caps; values white bold ~28 pt with a smaller unit.
- Footer "← Activity Strain" + dots (3rd active).

### 4.4 Heart Rate page

- **iOS 2026: UNCONFIRMED**, not captured.
- 2023 iOS (design-language/31):
  - black circle "HEART RATE 106 / 50 - 59%";
  - full-width HR area chart;
  - stats AVG HR | STRAIN | CALORIES;
  - footer "Activity Strain →".
- Feb 2026 Android (b08):
  - blue band "❚❚ 00:10:33" with tabs ACTIVITY STRAIN | HEART RATE;
  - black circle "♥ 135 / Zone 1";
  - HR area chart;
  - AVG HR 136 | STRAIN 5.5 | CALORIES 88.
- Expect the 2026 iOS HR page to match this structure, with the blue band.

### 4.5 Pause / resume

**Not available** in the current app (as of Oct 2026).

- WHOOP staff @liv0 (forum 1257, 2025-05-16): "Once you start an activity in the WHOOP app, there's no way to pause it mid-session. But you can always go back and manually edit the activity afterwards to reflect the pause."
- @Durkin (WHOOP, 2025-06-15): "I literally just vibe coded a new view of our Start Activity feature… I need to add a 'Pause' button."
- Users were still asking in May, Jul and Aug 2026 (forum 1257 #7, 15402, 15698, 15930).
- gadgetsandwearables (2026-09-05), quoting WHOOP's "Coming Next" (2026-09-03): November 2026 brings:
  - a rebuilt live workout screen ("progress towards your target, time accumulated in heart rate zones … improved map controls");
  - **pause and resume** (Moving Time vs elapsed);
  - then Activity Details with splits, target performance and Moving Time.
- The "❚❚" glyph in the Android band (b08, completeness-critic/06) does **not** prove a working pause; its function is **UNCONFIRMED**.

### 4.6 End & Save and post-save

- **UNCONFIRMED.** No public capture of the end confirmation, a discard option, or a post-save summary was found.
- Evidence that exists:
  - WHOOP text "Tap End & Save to log your workout";
  - Strain Target text "Activities recorded via Strain Target have a 24-hour duration limit";
  - for Strength Trainer, strain is computed "a couple of minutes after the end of the session" (reddit 1w3guz1, 2026-08-31).
- The Home row while strain is pending shows the sport glyph + a small **bar-chart glyph** instead of the number (g24 right half, Apr 2026: "STRENGTH TRAINER" row).
- If HR is insufficient, Activity Details shows:
  - "---" in place of the strain;
  - "There wasn't enough HR data during this activity to calculate your Strain.";
  - an empty graph;
  - zone rows labelled in **% of max** ("ZONE 5 (90-100%) 0%" … "RESTORATIVE (<50%) 0%").
- A "Live Activity / activity detected and processed" notification exists [TEXT].

### 4.7 Lock screen / Watch

- Lock-screen Live Activity: see completeness-critic/27 and help-center/20 (zone bar, blue stopwatch pill, "WHOOP" wordmark).
- **Apple Watch Smart Stack** (b09, Apr 2026): "WHOOP" wordmark, "♥ 137" (blue heart), elapsed "4:15", a mini HR sparkline and a zone-coloured bar (lavender) under hour ticks 00/06/12/18.

---------------------------------------------------------------------------------------------------

## 5. (c) Add Activity [SEEN, partly SB]

### 5.1 ADD ACTIVITY form

c01 is iOS, Oct 2025, only 348×736 px, so colours are approximate. s01 and s04 are Jun and Apr 2026 [SB]. It is a sheet over a dimmed backdrop (#182226).

1. **Header**: "✕" (left) · "ADD ACTIVITY" (white bold caps tracked, ~14 pt, centred). A grabber is visible in the storyboard.
2. **Info banner**:
   - rounded rect (≈ 12 pt radius), fill **#2E404E**;
   - leading sparkle/flake icon and text in light blue **#6F93CB** (~14 pt): "Your updates will help WHOOP autodetect and classify your future activities more accurately."
   - In the 2026 storyboards the banner has a **bright blue 1 pt outline**. Whether that is a style change or a focus state is **UNCONFIRMED**.
3. **Activity row**:
   - card **#373D42**, radius ≈ 12, height ≈ 56 pt;
   - grey pictogram + name in bold caps ("F45 TRAINING") + "›";
   - before a choice it reads "SELECT ACTIVITY ›" [SB s04].
4. **Section label "TIME"**: grey caps ~11 pt with a hairline to the right edge.
5. **Start Time / End Time rows**:
   - label (white regular ~16 pt, left);
   - value **pill** at the right: fill #303538, radius ≈ 6, white bold condensed ~14 pt, text "8 Oct at 7:00 AM" / "Nov 15 at 1:17 PM" / "Jul 15 at 8:00 AM".
   - The **active pill is filled WHOOP green #00F29E** with dark text.
   - Tapping a pill opens an **inline iOS wheel date picker** under the rows (date column "Wed 8 Oct"/"Today" · hour · minute · AM/PM), with a grey selection band (#24292E).
   - [TEXT] forum 15939 (Aug 2026): "Changing times on workouts – … the only option is scrolling the time … the user swipes down in the wrong place closing/cancelling the edit." So the sheet is swipe-dismissable.
6. **Validation banner**: amber-tinted rounded rect **#352B1A**, "!" + text **#D18D20**: "Invalid duration. Activities cannot start or end in the future." The SAVE button turns disabled.
7. **Section label "LOCATION"** + hairline.
8. "**Where did you wear your WHOOP?**" (white ~16 pt), then a full-width button (fill #2B3033, radius ≈ 10, height ≈ 50 pt) showing the current choice in bold caps ("**WRIST BAND**").
   - Tapping it reveals an **inline 3-row wheel** [SB].
   - The option list (e.g. Bicep Band / WHOOP Body / …) is **UNCONFIRMED**.
   - Help-center Cycles text says the location question is asked for WHOOP 4.0.
9. **SAVE**:
   - full-width **white capsule**, ≈ 49 pt tall, black bold caps "SAVE", pinned ≈ 30 pt above the home indicator;
   - **disabled state: #282A2E fill with dim grey text**.

### 5.2 Activity lists

- **Add flow** [SB s01, s04]:
  - a pushed page "‹ SELECT ACTIVITY": search field, 4 tabs (labels unreadable; probably ALL / STRAIN / RECOVERY / SLEEP), "MOST RECENT" (4–5 rows), "ALL A-Z";
  - **rows are rounded dark cards** (not plain rows);
  - whether ADD ACTIVITY opens the list first or the form first is **UNCONFIRMED**: GqKZ shows the list → form order, and NrCpf shows the form with a "SELECT ACTIVITY ›" placeholder.
- **Reclassify / edit flow** [SEEN c02, c03, c04]: a bottom sheet over Activity Details.

  | Element | Detail |
  |---|---|
  | Sheet | grabber; fill **#272E36 → #13181C** (vertical gradient); top radius ≈ 12 |
  | Header | "‹" + "SELECT YOUR ACTIVITY" (bold caps) |
  | Search field | inner fill **#161B1F**, radius ≈ 10, **1 pt light border (#8D949A) when focused**, magnifier, placeholder "Search for Activities", "✕" clear when typing |
  | Tabs | "ALL · STRAIN · RECOVERY" (underline; no SLEEP tab in this context) |
  | Note line | for an auto-detected generic "ACTIVITY": "An unknown activity was auto-detected. To improve future detection, please identify which activity you completed." (grey ~14 pt) |
  | Section label | "ALL A-Z" + hairline |
  | Rows | **cards #2F3438** (lower: #292A2E), radius ≈ 10, height ≈ 56 pt, gap ≈ 8 pt; grey pictogram + white bold caps name |
  | Empty search | nothing below the search ("Sauna" → blank sheet, c04, Dec 2025) |

- Search examples:
  - "Yard" → one card "YARD WORK/GARDENING" under "ALL A-Z" (c05, Jun 2026, ALL/STRAIN/RECOVERY/SLEEP tabs visible);
  - typing "gardening" does not find it (forum 15184).

### 5.3 Errors and empty states

- **OVERLAPPING ACTIVITIES**: a centred modal card over pure black **#000000**.
  - Card: gradient **#27343C → #1B2228**, radius ≈ 14; "✕" at the top-right.
  - Title "OVERLAPPING ACTIVITIES" (white bold caps).
  - Body (grey, centred): "You added an activity from **8:54 PM to 10:04 PM**. WHOOP has detected the following activities during this time: / **Soccer** - 8:54 PM - 10:04 PM / Please go back and edit your activity or delete the overlapping activities to continue."
  - Button: iOS shows a **white filled capsule "GOT IT"** (c06, May 2026); Android shows a white-outline "GOT IT" over the dimmed "ADD ACTIVITY" sheet (c07, Sep 2026).
  - [TEXT] forum 15306 (Jul 2026): the pop-up offers no inline resolution.
- **REQUEST FAILED** (c08, iOS Sep 2026, while adding an activity): a modal card (same gradient) over black: "✕" · "REQUEST FAILED" · "Check your network connection and try again." · a white capsule "CLOSE".
- **A NETWORK CONNECTION IS REQUIRED** (c09, Jan 2026): a full black page, cloud-slash icon, title in caps, "Ensure your phone has network connectivity to proceed."
- **SOMETHING WENT WRONG. PLEASE TRY AGAIN IN A FEW MINUTES.** + "RETRY" outline capsule, with a red ⓘ circle (forum 14500, Apr 2026, while editing sleep). Already in completeness-critic/18.

---------------------------------------------------------------------------------------------------

## 6. (d) Edit Activity

### 6.1 Overflow sheet

The "•••" (top-right of Activity Details) opens a standard iOS action sheet with **Edit** (blue) / **Delete** (red) in one group and **Cancel** below (d02 Jul 2025, d06 Jul 2025).

- Strength-Trainer-linked activities show **Delete / Cancel only** (d05). [TEXT] "Activities linked to a Strength Trainer session cannot be edited."
- Strength Trainer sessions also cannot be added or edited retroactively. WHOOP @noooor, forum 13202, 2026-01-12: "the session is locked to the day and time it's started".

### 6.2 EDIT ACTIVITY sheet, pre-scrubber (d03 Jul 2025, d04 Nov 2025, s03 Jun 2026)

d04 is 1179×2556 px (393 pt).

- A sheet whose top starts ≈ 119 pt down. Fill gradient #232D32 → #101517. Grabber #4E565A ≈ 36×4 pt.
- Content, top to bottom:
  1. "✕" · "EDIT ACTIVITY"
  2. Activity row card (≈ 56 pt, "RUNNING ›"). Tapping it opens SELECT YOUR ACTIVITY.
  3. TIME: Start Time / End Time pills ("Nov 15 at 1:17 PM")
  4. LOCATION: "Where did you wear your WHOOP?" + "WRIST BAND" button (≈ 50 pt)
  5. White "SAVE" capsule at the bottom (≈ 49 pt)
- It is the same component as ADD ACTIVITY, minus the info banner.
- The floating WHOOP AI button overlaps the bottom-right corner of the sheet (d04).

### 6.3 Edit Activity with HR-graph scrubber (iOS)

**NOT CAPTURED anywhere public.** Text only:

- Jun 25 2026: "On the Edit Activity screen, you can now scrub across your heart rate graph to set the precise start and end of an activity. Trim a warm-up, cut a cool-down, or capture a stretch WHOOP didn't include. Edit from the Activity Details page by tapping the edit icon above the heart rate graph."
- Jul 1 2026: "A heart rate graph is built directly into the Edit Activity screen, so you can scrub through your data to adjust exactly when an activity started and ended… Edit from the Activity Details page by tapping the edit icon."
- **Placement of the edit icon is UNCONFIRMED.** h01 (iOS, 2026-09-16, YOGA, auto-detected) shows **no pencil** between the stats row and the graph, and none on the TYPICAL RANGE row. The entry may be inside "•••", or appear only on some activity types.

**Closest visual references for the scrub interaction (both SEEN):**

- **e03** (recovery-activity details, Aug 2026). Touching the graph:
  - replaces the top stats with the cursor readout "**132 bpm**" (light blue #83AAD1-ish, ~34 pt) over the time "**10:34**";
  - draws a dashed white vertical cursor with a light-blue dot on the line;
  - dims the coach card.
- **e04** (landscape full-day HEART RATE view):
  - header "✕ HEART RATE ‹ TODAY › Data synced to 12:04";
  - the activity window highlighted as a lighter column band with a top cap line;
  - a tooltip "**115 bpm / 10:34**" above a white dot on a dashed cursor;
  - a ⊖ zoom button at the right.
  - [TEXT] forum 15939: the landscape HR graph opens on a slight tilt.

The Activity Details graph itself (SEEN, every details capture):

- dashed white vertical lines with dots mark the start and end, with labels "8:25 AM" / "8:40 AM" under them;
- HR outside the window is drawn dimmer;
- this is what a scrubber would drag (inference).

---------------------------------------------------------------------------------------------------

## 7. (e) Recovery-activity details [SEEN]

Files:

| File | Activity | Date |
|---|---|---|
| e01 | STEAM ROOM | Jun 2026 |
| e02 | DRY SAUNA | Jun 2026 |
| e03 | CONTRAST THERAPY | Aug 2026 |
| e08, e09 | BREATHWORK | Jul 2025 |
| e10 | MEDITATION | Feb 2026 |
| e11 | MEDITATION "ÜBER FOREST" (de) | Sep 2025 |

Top to bottom (template shared by all recovery activities):

1. **Nav**: "‹" · white glyph · name in bold caps ("STEAM ROOM") over "12:37 PM to 12:47 PM" (grey ~13 pt) · "•••".
2. **Two headline stats** (left-aligned pair):

   | Value | Delta chip | Label |
   |---|---|---|
   | "0:10:00" (white bold ~40 pt, seconds smaller) | "▲0:08:12" (grey chip, radius 4) | MINUTES (grey caps) |
   | "0.9" (white bold) | "▲0.9" | STRESS CHANGE |

   **Values are white, not blue.** Negative values occur: "-0,6 STRESSVERÄNDERUNG" in e11.
3. **Coach card**:
   - 1 pt gradient border (blue → violet), radius ≈ 14, ~17 pt text;
   - example: "You spent 10 minutes on this activity. This is longer than your previous average of 8 minutes.";
   - CTA "EXPLORE INSIGHTS →" (2026) or "LEARN MORE WITH WHOOP COACH →" (2025), in violet caps.
   - Generic copy when there is no history (e03): "Recovery activities are low-intensity activities that promote blood flow to the muscles to help you recover from strain, fatigue, or sore muscles."
4. **Segmented control "STRESS | HEART RATE"**: dark track, the selected segment lighter, bold caps ~12 pt.
5. **Graph**:
   - **STRESS tab**: y 0.0–3.0; at the top-left the start value + level ("1.7 MEDIUM", "0.6 LOW", level word coloured green / teal / orange); at the top-right the end level + value ("HIGH 2.9", "MEDIUM 1.5"). The line is coloured by stress level (green → yellow → orange).
   - **HEART RATE tab**: line in light steel blue **#83AAD1** with a faint fill; strain activities use the strain blue (≈ #4390D8 sampled on the line).
   - Both tabs: dashed start/end markers with dots and time labels.
6. **Achievement / milestone card** (e10, h02, g17):
   - card, radius ≈ 14;
   - a sport/meditation icon in a scalloped or segmented ring badge;
   - "13/25" (first number blue) + "12 more for next achievement" (or "4 more until your next milestone"), a thin progress bar and "›".
7. **"SESSION METRICS"** + "VS. 30 DAY RANGE" (grey caps right): horizontally scrolling tiles (radius ≈ 14, fill ≈ #373C40):
   - MIN HR (heart-down icon) / AVG HR / MAX HR (heart-up icon);
   - value "80 bpm" (white bold ~40 pt + unit) and a chip "● 80bpm" / "▲71bpm".
8. **"IMPACT ON RECOVERY"** card (title bold caps, value "--%" at the right):
   - "Keep logging this activity to receive insights. Once you reach 5 days with and 5 days without this activity, impacts will be unlocked.";
   - 5 progress circles (completed = blue check) + "1/5".
   - [TEXT] forum 15915 (Aug 2026): NSDR shows "0.0 stress change and 0% impact on recovery" once unlocked.
9. A coach toast pinned at the bottom (W avatar + one-line summary + "⌃"), as on all 2026 details pages.

**Related screens:**

- **Home rows for recovery activities**: a **light-blue badge (sampled #79ACE1, close to the pre-start circle #7EB2EB) with the duration** ("🧘 0:05", "0:20") instead of a strain number (e12, e13).
- **Activity Insights** (e05):
  - opens as a coach bottom sheet ("Beta v5.1", history icon) starting with "You spent 18 minutes on this activity. This is longer than your previous average of 15 minutes.", then chat.
- **Journal "BEHAVIOR DETAILS"** for Sauna (e06): "Sauna", chip "**NEGATIVE IMPACT**" (amber), "-3%" (amber) and the explanation "After accounting for other influences, this behavior has a -3% impact on your Recovery." A track "▼ HURTS | RECOVERY IMPACT | HELPS ▲" with a "You" marker and "0% WHOOP Average". This is behaviour-based and separate from the activity's IMPACT ON RECOVERY.
- **RECOVERY INSIGHTS list** (e07) contains a "SAUNA -3%" row (amber bar).
- **Pre-start** for recovery sports: §3.5.

---------------------------------------------------------------------------------------------------

## 8. (f) GPS route card and shareable snapshot

### 8.1 ROUTE card on Activity Details (iOS) [SEEN]

- Placement: below KEY STATISTICS. Help text: "swipe left to view the route".
- Card: 361 pt wide (16 pt margins), ≈ 394 pt tall in f02, radius ≈ 14.
- Map: Apple Maps light standard. "ROUTE" label (black bold caps ~13 pt) at the top-left. Route line in WHOOP blue (#0A8AF0-ish), a blue start dot with a white ring, and a **checkered finish marker**.
- **2026 share button** (from Apr 3 2026):
  - a **black rounded square ≈ 31×30 pt (#171717) with a white iOS share glyph** at the card's top-right (≈ 14 pt inset);
  - seen May 2026 (f02) and Aug 2026 (f03, German "STRECKE");
  - **not present** in Jun 2025 / Mar 2026 captures (f06, f07).
- **Stats overlay**: a near-black rounded panel **#171717** across the bottom of the map with three columns: "0.0 km DISTANCE | 816:22 /km PACE | 2 m ELEV. GAIN". Values are white bold ~26 pt with smaller units; labels grey caps. Cycling uses "SPEED (mph)" instead of PACE (f06). Apple "Maps Legal" sits under it.
- Android variant (f04, f05):
  - Google map with the same black share square;
  - stats **below** the map on the page instead of overlaid;
  - also +/− zoom controls.
- Source attribution chips (2026):
  - "GARMIN ÜBER STRAVA" / "Garmin Via Strava" (f08, de);
  - "VIA STRAVA" (f09, Jun 2026) — a small dark chip above the strain number, in the same slot as "RECOMMENDED ACTIVITY" / "AUTO-DETECTED".

### 8.2 Shareable snapshot graphic (f01, posted 2026-05-05) [SEEN, exported image]

- A portrait card (852×1200 as posted ≈ 0.71 ratio) with rounded corners.
- Background, sampled: a radial glow, steel blue **#3D5D98** at the top-centre → **#131A22** mid-height → **#101518** at the bottom.
- "WHOOP" wordmark (white, thin geometric) at the top.
- The **route traced as a thick strain-blue line (sampled #0095E8, ~5 pt) with no map**.
- A white sport pictogram (runner) centred.
- A stats row of 3 columns with thin vertical dividers: "**2.0 mi** Distance | **0:19** Duration | **9:46 /mi** Pace". Values are white bold ~22 pt; labels grey **Title Case** ~18 pt (unlike the in-app caps labels).
- [TEXT] "Share it directly from the app, or export with a transparent background."
- User complaint (May 2026): "if I hit the share button, it gives me the attached image without the map". So **no map background option**.

### 8.3 Share sheet UI

**UNCONFIRMED.** The picker or preview UI (transparent toggle, Instagram/Photos targets) was not captured.

[TEXT] forum 16042 (Aug 2026): sharing stats is limited to GPS activities. There is no stats-only share for Strength Trainer and other non-GPS activities.

Strava sharing [SEEN g26 right, Apr 2026]: WHOOP's Strava upload attaches a **day-overview image**. It is a crop of the day HR graph with:

- "92% RECOVERY" (green dashed line);
- sleep "7:56";
- activity icons;
- "14.9 CALORIN…";
- "183 CALORIES", "158 MAX HR".

---------------------------------------------------------------------------------------------------

## 9. (g) Strength Trainer 2026

### 9.1 Root (g01 May 2026, g02 May 2026 German)

1. Modal header: "✕" · "STRENGTH TRAINER" (bold caps) · "ⓘ" in a circle.
2. **Tabs "PROGRESS · MY WORKOUTS · WHOOP WORKOUTS"**: underline style, bold caps. The third label is clipped at the right edge ("WHOOP WORKOUTS" / "WHOOP-TRAINI…"), so the row is probably horizontally scrollable (inferred).
3. **MY WORKOUTS tab** (g01):
   - first, a card with a purple gradient border (the "Generate with WHOOP AI" card per help text; only its bottom edge is visible);
   - "**BUILD MANUALLY**": full-width grey button, radius ≈ 12, bold caps;
   - section label "MY WORKOUTS" + hairline;
   - rows: cards (≈ 56 pt, radius ≈ 12) with a **user emoji icon** (🏃 / 🏠 / 🛏 / 🟣) + bold caps name ("RUNNING WARMUP (NO EQ)", "UPPER (DUMBBELLS)") + "•••" (copy / share via QR / delete per help text).
   - The floating WHOOP AI button overlaps the last row's "•••" (complaint in reddit 1t9z5f1).
4. **PROGRESS tab** (g02):
   - title "Total Volume Load" (Title Case, ~22 pt; German "Gesamtvolumenlast");
   - "Ø VOLUME LOAD 5.478 kg" (big white value);
   - M | 6M segmented toggle; date range "‹ NOV. 27, 25 – MAI 25, 26 ›";
   - chart of monthly averages: a horizontal segment per month with the value label above (white first, then green or orange by change) and the % change below ("-1%" orange, "+13%" green), over a faint blue line of raw sessions;
   - "**Personal Records**" (Title Case) list: card rows with an exercise photo thumbnail, name, best value at the right ("4 reps", "30 kg", "98 kg") and "›".

### 9.2 Live session (g07 GIF / g07a–c Sep 2026; g10 Jul 2025)

1. **Header**:
   - "•••" (left);
   - workout name in bold caps ("UPPER A", "HYROX DUMBELL (W/ SKIERG+ROW)") over the elapsed time "00:38:26" (grey);
   - "+" (right, add exercise).
2. **Tabs "LIVE SESSION | EXERCISES"**: underline.
3. **Ring** (~200 pt diameter):
   - **REST** state: grey/white gradient ring, "REST" (white bold caps) + "01:15" (white bold ~44 pt). The timer **counts up** (01:15 → 01:22).
   - **ACTIVE** state: ring with a **blue → teal-green gradient glow**, "ACTIVE" (green caps) + "00:00" (green, sampled ≈ **#00EE93–#02F297** on the GIF frame, bold ~44 pt) counting up.
4. "HEART RATE" (grey caps) + live value "82" + the **6-segment zone bar** with "Zone 0…Zone 5" labels (same component as §4.2).
5. **Exercise card** (radius ≈ 14, fill ≈ #2B3034):
   - photo thumbnail + "**NEXT**" (green caps, shown only in REST) + exercise name ("Bicep Curl - Cable") + "ⓘ" (opens Exercise Details);
   - a stats row "**3/3** SET | **12** REPS | **20** KG" (the current set number turns green in REST).
6. **Primary button** (full-width capsule ≈ 50 pt) state machine (g07c):
   - "START SET" (mint-green outline and text, sampled **#60E0B0**)
   - → pressed: bright-green fill **#05ED95**
   - → "SET" (bright-green fill, then darker green fill #085032)
   - → "**END SET**" (white outline, white text) while ACTIVE.
   - Older (Jul 2025): "END SET" white outline under an ACTIVE ring.
7. **No live strain in Strength Trainer** [TEXT] (reddit 1w3guz1, forum 13962): strain appears minutes after the session ends.
8. [TEXT] Rest-timer workflow complaints (forum 14544).
   - g11 (May 2026) shows a REST countdown with a bell icon and a "REST − 01:00 +" stepper. The poster asks "Can we add a simple timer like this", so g11 is a **USER MOCKUP**, not the shipping UI.

### 9.3 EXERCISES tab in session (g08 Sep 2026, g09 Dec 2025)

- A list of exercise cards: thumbnail, name ("Split Squat - Rear Foot Elevated - R - Dumbbell"), "3 Sets", drag handle "═".
- An expanded card shows:
  - a hint line ("If lifting two dumbbells enter the combined weight of both." / "Exclude your bodyweight when inputting weight.");
  - the header "REPS · WEIGHT (KG)" or "TIME (M:SS) · + WEIGHT (KG)";
  - numbered rows of two input boxes + **"▶" play button per set**. The active set row has a **1 pt green outline**: sampled #4B9F76 on the thin line, which is blended with the dark background; the true colour is likely the bright-green family. A running set shows a spinner instead of ▶.
  - Below the rows: "− +" stepper buttons + a trash icon.
- Supersets: a rounded outlined container labelled "⟳ SUPERSET" with a drag handle, holding collapsible exercise cards (g14, Jul 2026). Exercises cannot be dragged into an existing superset (complaint).

### 9.4 Exercise Details

- **New version** (g03, Jul 2026; shipped May 20 2026, rolled out unevenly; poll 1v2ti0h):
  1. Full-bleed hero photo of the exercise under the nav "‹ EXERCISE DETAILS ⓘ".
  2. Name "Back Squat - Barbell" (white Semibold ~22 pt).
  3. **Chip tabs "Progress | History | Instructions"**: the selected chip is a white pill with black text; others are dark grey pills with white text; radius ≈ 10.
  4. "AVG VOLUME LOAD" (grey caps) + "5,546 lb" (white bold ~32 pt) + a chip "▼ 3% vs. prior 6 months" (orange text on a brown-tinted rounded rect).
  5. M | 6M toggle + "‹ DEC 22, 25 – JUN 19, 26 ›".
  6. A chart (y 0 / 5,000 / 10k / 15k, x months) with monthly average segments and labels (6,000 / 4,000 / 6,000 / 6,120 / 6,597) and coloured % changes (−33% orange; +50%, +2%, +8% green). The last point "7,550" has a blue ring marker.
  7. "**Personal Records**" with expandable cards: "**295** lbs  **6** reps  🥇  August 26, 2025  ⌄" / "295 lbs 6 reps 🥈 July 29, 2025 ⌄".
- **Old version** (g04–g06, May–Jul 2026):
  - "‹ EXERCISE DETAILS (ⓘ)";
  - either a **video preview with a "PREVIEW" tag and ▶**, or no media;
  - name; description (or "No description added.");
  - "EQUIPMENT Barbell", "MUSCLE GROUP Chest";
  - an optional "LINKED EXERCISE:" row (thumbnail + name);
  - an empty-state card with a 3D dumbbell: "**Exercise Trends Coming Soon** / View your lift history and explore detailed strength trends over time."

### 9.5 Strength Trainer activity details (g15, g16 Feb 2026; g17 Mar 2026; g26 Apr 2026; g24 Apr 2026; d05)

1. Nav: "‹ [lifter] STRENGTH TRAINER 4:05 PM to 5:27 PM •••".
2. A **workout-name chip** ("TUES (GLUTES, HAMSTRINGS, BACK)", "2026 LOWER 1", "DAY 3": grey rounded-rect chip, caps ~11 pt).
3. Strain row:
   - "15.0" (strain blue **#0099FF**) + chip "▲4.7" + "ACTIVITY STRAIN";
   - at the right, a **CARDIO | MUSCULAR split bar**: labels in white caps above; a single bar of dark blue **#00588A** (cardio) and bright blue **#0193E8** (muscular) with a white divider tick; percentages under it ("41%" / "59%").
4. **Segmented "EXERCISES | HR ZONES"**.
   - The EXERCISES view shows the HR graph, then a **summary card**: lifter icon + "11 Exercises / 26 Sets" (blue), "**3114** kg TONNAGE", "**368** TOTAL REPS", page dots and "VIEW ALL →".
   - Swiping the card shows per-exercise cards: "Crunches ›" with a REPS | WEIGHT | AVG HR table, a **gold medal "1" badge** on a PR set, and "TOTAL 8280 | **82800 kg** (blue)" (g18).
   - HR ZONES shows TYPICAL RANGE / DURATION and the zone rows.
5. KEY STATISTICS ("VS. 30 DAY AVERAGE") tiles: DURATION "1:42:21", INTENSITY "40%", CALORIES.
6. A milestone card ("3/5 · 2 more until your next milestone").
7. **Exercise Summary** page (g12): "‹ EXERCISE SUMMARY"; "0 kg TONNAGE (blue) | 31% INTENSITY | 72 REPS"; a card per exercise (thumbnail, name) with a REPS | WEIGHT | AVG HR table; "TOTAL 72 | 0 kg".
8. Muscular-load notices:
   - **"Refine Your Muscular Strain"** (g19, Feb 2026, functional fitness): pure-black card **#000000**, radius ≈ 14, link icon, "✕", "WHOOP automatically estimates muscular load for strength training. Add exercises to improve accuracy…", CTA "**ADD EXERCISES →**" in **#009CFF**.
   - **"More Credit for Your Effort"** (g20, Apr 2026, rowing): "ⓘ" + "Your Rowing activity strain now includes muscular load, so it may appear higher than usual. **VIEW TRENDS →**".
   - Home feature card **"More Credit for Strength"** (g21, Feb 2026): "Weightlifting, HIIT, Functional Fitness, and other strength workouts now automatically estimate muscular strain - no logging needed." with dumbbell art and a "✓ 3" chip.
   - [TEXT] "Calculate Muscular Load" / "AI links your exercises after you lift" (Mar 5).
9. Errors:
   - "**HEADS UP** / We saved your workout locally because of a network error. Your workout will process when you regain network connection. You can close this screen without losing your data." + "TRY AGAIN" (outline) / "DISMISS" (text), amber "!" ring (g22, Aug 2025).
   - "REQUEST FAILED / Please try again later" + "TRY AGAIN" / "DISMISS", red "!" ring (g23, Aug 2026).
10. WHOOP AI building a workout from a photo: chat ("Beta v5.2"), then "Strength Trainer → Create New Workout" guidance (g25, Feb 2026).

---------------------------------------------------------------------------------------------------

## 10. Shared tokens observed in these flows (sampled hex)

| Element | Hex | Source |
|---|---|---|
| Live-session band | **#0193E9** | b01, b03, b05 |
| Strain-sport HR circle (pre-start) | **#1C90DD** (halo #31648F) | a01 |
| Recovery-sport HR circle / recovery badge | **#7EB2EB** (mid halo #384A60) / badge **#79ACE1** | a07, e12 |
| START ACTIVITY button | **#0193E8** | a01 |
| Pre-start panel / button area | **#FFFFFF** / **#F5F5F5**; grabber/toggle track #E5E5E5; toggle knob #000000 | a01 |
| Pre-start header over map | **#0A0D12** | a01 |
| Live page gradient | #2D383E → #1A2129 → #0C1013 → #181F27 | b01 |
| Live ring track | **#333740** | b01 |
| Live ring arc | #132F5F → #025DA4 → **#0082D6** | b01 |
| Live map route | #0A8AF0 | b05 |
| Live map stats panel | #0E1215 → #171E26 | b05 |
| Add/Edit sheet bg | #1D2429 (Add) / #232D32 → #101517 (Edit) | c01, d04 |
| Info banner | fill **#2E404E**, text **#6F93CB** | c01 |
| Validation banner | fill **#352B1A**, text **#D18D20** | c01 |
| Time pill | idle #303538; active **#00F29E** | c01 |
| Activity row card (forms) | **#373D42** | c01 |
| SAVE disabled | **#282A2E** (enabled = white capsule) | c01, d04 |
| Select-activity sheet | #272E36 → #13181C; search #161B1F (focus border #8D949A); row card #2F3438 | c02, c03 |
| Modal cards (overlap, request failed) | gradient **#27343C → #1B2228** over **#000000** | c06, c08 |
| Activity strain number | **#0099FF** | g19 |
| CARDIO / MUSCULAR bar | **#00588A** / **#0193E8** | g19 |
| Notice card (muscular load) | **#000000**; CTA **#009CFF** | g19, g20 |
| Recovery-activity HR line | **#83AAD1** (strain activities ≈ #4390D8 on the line) | e01, d01 |
| Route card share button / stats panel | **#171717**; map bg #E7E7E7; details page bg #222A2D; stat tile #373C40 | f02 |
| Strength Trainer buttons | START SET outline **#60E0B0**; pressed fill **#05ED95**; SET held #085032; ACTIVE timer ≈ #00EE93 | g07 (GIF palette, approximate) |
| Live band history | iOS 2023 **#FE0026**; Android Sep 2025 **#ED2E0D**; 2025-26 iOS and Android **#0193E9** | design-language/31, completeness-critic/06, b01, b08 |
| Shareable snapshot | glow #3D5D98 → #131A22 → #101518; route #0095E8 | f01 |

**Typography** (all estimates):

- Nav titles and section labels: bold caps with wide tracking (WHOOP's DIN-style face), ~13–15 pt.
- Big numerals: bold condensed (DIN-like): live strain ~70 pt, HR ~34 pt, durations ~40 pt with smaller seconds.
- Coaching and body copy: Proxima-like sans, ~15–17 pt.
- Title Case is used for:
  - "Start Time" / "End Time" / "Where did you wear your WHOOP?";
  - "Personal Records", "Total Volume Load";
  - snapshot labels ("Distance / Duration / Pace").

**Radii:**

| Element | Radius |
|---|---|
| Cards | ≈ 12–14 pt |
| Pills | ≈ 6 pt |
| Chips | ≈ 4 pt |
| Buttons | capsules (full) |
| Sheets | top ≈ 12 pt |

---------------------------------------------------------------------------------------------------

## 11. Image index (post date and source)

All files are in `images/activity-flows-2026/`.

- `community.whoop.com/t/<id>/<post>` = forum post.
- "reddit <id>" = `https://www.reddit.com/r/whoop/comments/<id>/`. Its image is `https://i.redd.it/<media>`, as listed in the last column.

| File | Post date | Page | Image URL |
|---|---|---|---|
| a01 prestart running map HR77 ST 12.2 (WHOOP staff) | 2025-08-18 | community.whoop.com/t/7184/2 | …/original/2X/0/06ba0228021c732e34c9427d972d3b4f199f58b8.jpeg |
| a02 home 2025 FAB action menu | 2025-08-18 | community.whoop.com/t/7184/2 | …/original/2X/a/a123c01e528e28c85a24dbe46e8198b07a39fded.jpeg |
| a03 home + prestart walking strap render | 2025-09-15 | community.whoop.com/t/8249/1 | …/original/2X/c/cfffdf0fbbd7a6d7ee6e9c368289a2b2996a04a9.jpeg |
| a04 prestart running, Track Route toggle | 2025-11-16 | reddit 1oysr1q | i.redd.it/r6ehsr7vtn1g1.jpg |
| a05 Strain Target expanded, ring | 2025-12-21 | reddit 1psebbh | i.redd.it/ksfsxa9svl8g1.jpg |
| a06 Strain Target expanded, chart | 2025-12-21 | reddit 1psebbh | i.redd.it/q8q6za9svl8g1.jpg |
| a07 prestart SAUNA (recovery) | 2026-01-08 | reddit 1q7n36e | i.redd.it/8oag8425r6cg1.jpg |
| a08 Android prestart Pilates | 2025-10-21 | community.whoop.com/t/9857/1 | …/original/2X/e/ec91b58097642a8bd5fbd2a31473a4df9e550ed3.png |
| a09 Android picker STRAIN tab | 2025-10-21 | community.whoop.com/t/9857/1 | …/original/2X/5/569d5565add8aa1cc7ba3f61d5814f8595835846.png |
| a10 Android picker Most Recent | 2026-05-09 | reddit 1t842mt | i.redd.it/hf2yqzl1y30h1.png |
| b01 live strain 10.8 MODERATE, 3 pages | 2025-09-29 | reddit 1ntnuzx | i.redd.it/inpdyjdkz4sf1.jpeg |
| b02 live strain 0.0 (annotated) | 2026-03-31 | community.whoop.com/t/14400/1 | …/original/2X/8/89bffc3ea0257a9652c313382097903de69f66ab.jpeg |
| b03 live strain 4,7, 2 pages | 2026-04-25 | reddit 1sv57hu | i.redd.it/mr0dn6deeaxg1.jpeg |
| b04 live strain 4.6 @01:00:15 | 2026-08-06 | community.whoop.com/t/15793/1 | …/original/2X/5/5369cc1f753cc7e502c18fc35777608288f71653.jpeg |
| b05 live map page | 2026-01-13 | reddit 1qbvu15 | i.redd.it/zlrqa9wv75dg1.jpeg |
| b06 live map page (ski) | 2026-02-06 | reddit 1qxf0be | i.redd.it/1igk9asfzuhg1.jpeg |
| b07 live map page (glitch) | 2026-05-19 | reddit 1thjcj8 | i.redd.it/uwja4thwr22h1.jpeg |
| b08 Android live HR tab | 2026-02-22 | reddit 1rbqbxz | i.redd.it/t8eceyupp2lg1.jpeg |
| b09 Apple Watch Smart Stack | 2026-04-09 | community.whoop.com/t/14488/1 | …/original/2X/5/5982ac175adef0ca496bf7692bbfa9938fc26216.jpeg |
| c01 ADD ACTIVITY form + wheel + error | 2025-10-07 | community.whoop.com/t/9187/1 | …/original/2X/b/bfe0961d70f21f4c7f5642b7e07391888bd96d99.png |
| c02 SELECT YOUR ACTIVITY (unknown activity) | 2025-08-21 | reddit 1mwii0u | i.redd.it/je8x0c4mxekf1.jpeg |
| c03 SELECT YOUR ACTIVITY list cards | 2026-06-02 | reddit 1tv5w6k | i.redd.it/5cpg6vet0y4h1.jpeg |
| c04 SELECT YOUR ACTIVITY, no results | 2025-12-21 | reddit 1psfe3d | i.redd.it/6c4brjot3m8g1.png |
| c05 search "Yard" result | 2026-06-22 | community.whoop.com/t/15184/2 | …/original/2X/6/65c7e475f5fb6fcc3775eef223e831535ed94581.jpeg |
| c06 iOS OVERLAPPING ACTIVITIES | 2026-05-09 | reddit 1t8d9ak | i.redd.it/5cqo7ajaq50h1.jpg |
| c07 Android overlap over ADD ACTIVITY | 2026-09-08 | community.whoop.com/t/16154/1 | …/original/2X/5/5504d9ede86568c6a31ae11c7596fc39c7304f58.jpeg |
| c08 REQUEST FAILED (add) | 2026-09-10 | community.whoop.com/t/16179/1 | …/original/2X/8/8f56eb769b1ea74f38c174255cf28817ee2b3b1f.jpeg |
| c09 NETWORK CONNECTION REQUIRED | 2026-01-22 | reddit 1qk71i8 | i.redd.it/9evsmkwrvyeg1.jpeg |
| d01 details RUNNING (staff) | 2025-07-15 | community.whoop.com/t/5010/2 | …/original/2X/6/6ea937c854964d104cb61e630380d7cf64957a7a.jpeg |
| d02 overflow Edit/Delete/Cancel | 2025-07-15 | community.whoop.com/t/5010/2 | …/original/2X/0/00c71197ac32d5edcc384f01af4f3615a2e6d945.jpeg |
| d03 EDIT ACTIVITY sheet | 2025-07-15 | community.whoop.com/t/5010/2 | …/original/2X/7/724c1e81540540f61e1752d36a4c62897748b3a3.jpeg |
| d04 EDIT ACTIVITY sheet (Nov) | 2025-11-16 | reddit 1oysr1q | i.redd.it/kyg4ov7vtn1g1.png |
| d05 ST-linked overflow Delete only | 2025-08-09 | community.whoop.com/t/6727/1 | …/original/2X/9/95e68522494bbbcbddb3de2d3615e936402904b5.jpeg |
| d06 overflow sheet cycling | 2025-07-09 | community.whoop.com/t/4694/2 | …/original/2X/b/b276cdc53b11c5c5f9311ae8c1498afb595b3f58.jpeg |
| e01 STEAM ROOM details | 2026-06-26 | reddit 1ugizc1 | i.redd.it/18u9y44wyo9h1.jpg |
| e02 DRY SAUNA details | 2026-06-26 | reddit 1ugizc1 | i.redd.it/r8nmm34wyo9h1.jpg |
| e03 CONTRAST THERAPY scrub + IMPACT ON RECOVERY | 2026-08-29 | community.whoop.com/t/16061/1 | …/original/2X/7/7f08539a592ca53453c5a29401a8f329bc11a45f.jpeg |
| e04 landscape day HR scrub | 2026-08-29 | community.whoop.com/t/16061/1 | …/original/2X/b/bc39c7f8ee064fc9f3fc5e45fef0693e9ed624d6.jpeg |
| e05 Activity Insights chat (sauna) | 2026-01-08 | reddit 1q7n36e | i.redd.it/jb86p425r6cg1.jpg |
| e06 BEHAVIOR DETAILS Sauna −3% | 2025-12-16 | reddit 1po7qd1 | i.redd.it/67sir3d2ol7g1.jpeg |
| e07 RECOVERY INSIGHTS list | 2025-09-30 | reddit 1nuenvk | i.redd.it/i7lnb4lwabsf1.jpeg |
| e08 BREATHWORK stress tab | 2025-07-30 | reddit 1md5va0 | i.redd.it/2zapoeh7e0gf1.jpg |
| e09 BREATHWORK HR tab | 2025-07-30 | reddit 1md5va0 | i.redd.it/1kjbrfh7e0gf1.jpg |
| e10 MEDITATION stress + achievement | 2026-02-12 | reddit 1r2ld02 | i.redd.it/k5y29c8q40jg1.jpeg |
| e11 MEDITATION via Forest (de) | 2025-09-14 | reddit 1ngwrh3 | i.redd.it/na4fug3zw5pf1.jpeg |
| e12 Home rows meditation badge | 2025-11-16 | reddit 1oyrdl6 | i.redd.it/wp4e4komkn1g1.jpeg |
| e13 Home rows many meditations | 2025-07-11 | reddit 1lxb13b | i.redd.it/iihi7xj8s9cf1.jpeg |
| f01 shareable snapshot graphic | 2026-05-05 | reddit 1t4iwec | i.redd.it/76iko5fg8czg1.jpeg |
| f02 ROUTE card + share (swim) | 2026-05-20 | reddit 1tibdnl | i.redd.it/aj9u9yoo382h1.jpeg |
| f03 STRECKE card + share (de) | 2026-08-06 | reddit 1vh1ot5 | i.redd.it/ekc8ml1qqqhh1.jpeg |
| f04 Android map + share, stats below | 2026-08-29 | community.whoop.com/t/14630/3 | …/original/2X/9/94858bf9202322b08dc8d006ddcda2405e51530a.jpeg |
| f05 Android map + share | 2026-08-20 | reddit 1vtnwvh | i.redd.it/12rq86pb1kkh1.jpg |
| f06 ROUTE card 2025 (no share) | 2025-06-19 | community.whoop.com/t/3397/3 | …/original/2X/4/42a6f2439a294fad77c3c1c0b682eb5650c10e8b.jpeg |
| f07 ROUTE card Mar 2026 | 2026-03-08 | reddit 1roddf5 | i.redd.it/tp7gs3ovdvng1.jpeg |
| f08 GARMIN VIA STRAVA chip (de) | 2026-05-22 | reddit 1tk9a3a | i.redd.it/9f6bu2ytim2h1.jpeg |
| f09 VIA STRAVA chip | 2026-06-15 | reddit 1u6fi1z | i.redd.it/xjza4lqezf7h1.jpg |
| g01 ST root MY WORKOUTS | 2026-05-11 | reddit 1t9z5f1 | i.redd.it/vcn0fh1shh0h1.jpeg |
| g02 ST PROGRESS tab (de) | 2026-05-25 | reddit 1tnd13o | i.redd.it/3sakyye81b3h1.png |
| g03 Exercise Details new | 2026-07-21 | reddit 1v2ti0h | i.redd.it/mfnng1g82neh1.jpg |
| g04 Exercise Details old | 2026-07-21 | reddit 1v2ti0h | i.redd.it/tjqpk9v52neh1.png |
| g05 Exercise Details preview video | 2026-05-26 | community.whoop.com/t/14937/1 | …/original/2X/a/ada675eb819be0de0c8391a7fdc4bb64398c56b5.jpeg |
| g06 Exercise Details linked exercise | 2026-06-03 | reddit 1tvdnoj | i.redd.it/dx9mymrrnz4h1.png |
| g07 (+a/b/c) live session GIF and frames | 2026-09-04 | community.whoop.com/t/16114/1 | …/original/2X/0/02a480fc5531f92f93f16bec888feb00d0f60a19.gif |
| g08 EXERCISES tab set rows | 2026-09-04 | community.whoop.com/t/16113/1 | …/original/2X/8/836dc4d552fc1f1054ea536e2b2b0d310822150f.jpeg |
| g09 EXERCISES tab timed set | 2025-12-24 | community.whoop.com/t/12797/1 | …/original/2X/1/10d4713d1b5d83760a72fa49aed89abff3ecfe45.jpeg |
| g10 live session ACTIVE + END SET | 2025-07-21 | community.whoop.com/t/5290/3 | …/original/2X/9/941a6f430f14a38c783afc1bf2730f14a2d2849e.jpeg |
| g11 rest timer **USER MOCKUP** | 2026-05-28 | community.whoop.com/t/14959/1 | …/original/2X/d/dc5440f02b467f991b4f449c342272cfbda16fff.jpeg |
| g12 EXERCISE SUMMARY | 2026-02-28 | community.whoop.com/t/14007/1 | …/original/2X/3/31ac421f6547eec76b004f414dd63cb42bd6a350.jpeg |
| g13 editor Push Up sets | 2026-02-28 | community.whoop.com/t/14007/1 | …/original/2X/7/7dd03c78263f6b0a5c8c5a75201b1881be14b218.jpeg |
| g14 SUPERSET block | 2026-07-19 | reddit 1v0wqjr | i.redd.it/svzqdwgk28eh1.png |
| g15 ST details EXERCISES | 2026-02-13 | reddit 1r3kyth | i.redd.it/7pd194ypf8jg1.jpg |
| g16 ST details HR ZONES | 2026-02-13 | reddit 1r3kyth | i.redd.it/xfxtq3ypf8jg1.jpg |
| g17 ST details milestone | 2026-03-24 | reddit 1s2cntt | i.redd.it/kv3s0x4pnzqg1.jpeg |
| g18 exercise card PR medal | 2026-08-28 | reddit 1w0rdca | i.redd.it/1ynwoe9mg4mh1.jpeg |
| g19 Refine Your Muscular Strain | 2026-02-26 | community.whoop.com/t/11029/7 | …/original/2X/7/7297fb9e1913e48ffa69508fa533edc89a3626a3.jpeg |
| g20 More Credit for Your Effort | 2026-04-28 | reddit 1sy1bkj | i.redd.it/b5l8wscvmxxg1.jpeg |
| g21 Home "More Credit for Strength" | 2026-02-16 | reddit 1r69hk7 | i.redd.it/41kyw7a5yujg1.jpeg |
| g22 HEADS UP saved locally | 2025-08-06 | community.whoop.com/t/6052/4 | …/original/2X/6/65eeb7c0de82ad7d1a931fa127bf6bdb5208a347.png |
| g23 REQUEST FAILED (ST) | 2026-08-27 | reddit 1vzpimx | i.redd.it/0offshjq3wlh1.jpeg |
| g24 not enough HR data | 2026-04-15 | reddit 1slqp2c | i.redd.it/afs2qpbw19vg1.jpg |
| g25 WHOOP AI builds workout | 2026-02-07 | community.whoop.com/t/2584/6 | …/original/2X/e/e3ea16cd66dac1013fa2da0c58790c6a129d2922.jpeg |
| g26 ST HR ZONES + Strava image | 2026-04-26 | community.whoop.com/t/14654/1 | …/original/2X/5/5819946021e491fa61e9bb47c9da360b176fc83d.jpeg |
| h01 AUTO-DETECTED chip | 2026-09-16 | reddit 1whn9cd | i.redd.it/879bacwjatph1.jpg |
| h02 milestone card (volleyball) | 2026-06-25 | reddit 1ufcuw4 | i.redd.it/6eucju7i3g9h1.jpg |
| s01–s03 storyboard crops | video 2026-06-01 | youtube.com/watch?v=GqKZ-NXWn-g | i.ytimg.com/sb/GqKZ-NXWn-g/storyboard3_L3/M*.jpg |
| s04 storyboard crops M8–M9 | video 2026-04-21 | youtube.com/watch?v=NrCpf_m75XM | i.ytimg.com/sb/NrCpf_m75XM/storyboard3_L3/M8–M9.jpg |

Forum image URL prefix: `https://canada1.discourse-cdn.com/flex011/uploads/wboston/original/2X/…`

Reddit full post URLs: `https://www.reddit.com/r/whoop/comments/<id>/`.

---------------------------------------------------------------------------------------------------

## 12. Still UNCONFIRMED / not found

1. **Edit Activity with the HR-graph scrubber** (iOS, Jun–Jul 2026): no capture. The edit-icon placement is also unconfirmed (no pencil in the Sep 2026 capture h01).
2. **End & Save confirmation and post-save summary**: no capture. The flag in the blue band is the likely end affordance.
3. **iOS 2026 live Heart Rate page**: inferred from 2023 iOS + 2026 Android.
4. **Pause/resume**: confirmed absent until the November 2026 rebuild. Do not copy a pause UI as "current WHOOP".
5. **Snapshot share sheet** (preview, transparent-background option, share targets): only the exported graphic was seen.
6. **Location options** behind "Where did you wear your WHOOP?" (only "WRIST BAND" seen).
7. The tab labels and the "MOST RECENT" count in the Add-flow "SELECT ACTIVITY" page (storyboard only). Also which comes first, the form or the list.
8. **WHOOP WORKOUTS tab content in 2026**, and the History / Instructions tabs of the new Exercise Details.
9. Exact intensity words on the live ring beyond RESTING / MODERATE.
10. The knob-on-ring meaning (activity Strain Target is inferred).
11. The NrCpf weightlifting banner title ("Get More from Your Workouts"?).
