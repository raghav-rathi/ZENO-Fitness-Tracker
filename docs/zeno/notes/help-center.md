# WHOOP iOS app: navigation map from the Help Center, developer docs and public screenshots

Topic: support.whoop.com (Help Center), developer.whoop.com (API docs and the Brand & Design Guidelines PDF), official ECG/IHRN Instructions-for-Use documents, and public screenshots that confirm what the help text describes.
Researched: 2026-10-02. Target: the CURRENT app (the 2025 redesign plus updates through Sep 2026).

Confidence legend
- **[HC]**: stated in a support.whoop.com article (the date is the article's "Last Published Date").
- **[SEEN]**: visually confirmed in a screenshot (the image file is named).
- **[DEV]**: developer.whoop.com docs or the Brand & Design Guidelines PDF.
- **[IFU]**: official ECG/IHRN Instructions for Use (Word docs linked from support.whoop.com).
- **UNCONFIRMED**: plausible but not visually confirmed, or the sources conflict.

All images are in `whoop-reference/images/help-center/` (numbered; index in section 27). Cleaned text of 71 relevant help articles, the 2 IFUs and the developer data-model pages is in `whoop-reference/raw/help-center-articles/`, for exact wording.

---

## 0. How the sources were obtained (so the work can be repeated)

- support.whoop.com is a Salesforce Experience Cloud site, so plain `curl`/WebFetch return only a JS shell. The public sitemap `https://support.whoop.com/s/sitemap.xml` (sub-file `sitemap-topicarticle-1.xml`) lists **187 English articles**. Each was rendered with local headless Chrome (`--headless=new --virtual-time-budget=12000 --dump-dom`). The article body sits between the `>Article Body<` and `>URL Name<` labels. Inline images are public at `https://support.whoop.com/servlet/rtaImage?eid=…&feoid=…&refid=…`.
- The ECG/IHRN IFU links are Salesforce content-delivery pages. Rendering one exposes a ContentVersion id `068…`, and `https://whoop.my.salesforce.com/sfc/dist/version/download/?oid=00DU0000000LnPu&ids=<068id>&d=<distSuffix>` returns the DOCX. The ECG DOCX contains **10 real app screenshots**.
- developer.whoop.com is static (Docusaurus). The Brand PDF is `https://developer.whoop.com/assets/files/WHOOP%20-%20Brand%20&%20Design%20Guidelines-bdea3554e94b4ea09e68695b1e8dc8e7.pdf` (7 slides, text outlined; rendered with PDFKit).
- whoop.com/thelocker returns 403 to curl and to headless Chrome. `https://r.jina.ai/<url>` works.
- App Store: `apps.apple.com/us/app/whoop/id933944389` has 10 iPhone frames; 5 were downloaded at 1290×2796.
- WHOOP Community (`community.whoop.com`, public Discourse) has a JSON API (`/t/<id>.json`, `/search.json?q=… with:images`). Members post real screenshots. About 50 were downloaded, dated May 2025 to May 2026. These are the best evidence for the current layout.

---

## 1. App shell and global navigation

### 1.1 Bottom tab bar (current: about Oct 2025 to 2026) [SEEN 60–68, 87, 92; HC Navigating 11/17/2025, Calibration-Timeline 4/23/2026]
Order, left to right:
1. **Home**: house outline with a small heartbeat/trend line inside. "the tab shaped like a house on the bottom left of the navigation bar" [HC].
2. **Health**: heart outline with a pulse line. "the heart-shaped icon second from the left" [HC].
3. **Community**: three-person group icon.
4. **More**: three horizontal lines (≡). "More (Three Horizontal Lines icon)" [HC].
5. **WHOOP Coach / WHOOP AI button**: a separate floating round button to the right of the tab capsule, showing the white "W" puck mark inside a gradient ring. "You can access Coach directly from the bottom navigation bar… On other app views, the Coach button continues to float in the corner" [HC Coach 9/18/2026]. Some articles call it "the 'W' in the bottom right corner of the app" [HC Recovery-Insights].

Visual spec (measured on a lossless PNG, image 91, and 3x iPhone screenshots 63/64):
- The tab bar is a **floating capsule** (fully rounded ends). It sits about 14–16 pt from the left screen edge and above the home indicator. The background is translucent dark **#222A30**, so content scrolls underneath (a list is visible through it in 63).
- Selected tab: white icon (#FFFFFF), white label, and a soft lighter rounded glow behind the icon. Unselected: icon **#909497**, label **#8E9294**. Labels are sentence case, about 10–11 pt, under the icons.
- The Coach button is a dark rounded square/circle (bg about **#1A2227**), roughly the same height as the capsule. The ring gradient runs from **#59C3FF** (cyan) to **#8174FF** (violet), with a faint glow; the "W" is white. Known bug [SEEN 95, 96]: the floating button covers the "Broadcast Heart Rate" toggle in Device Settings.
- Notification: "a red notification icon will appear beneath the Community tab" for pending team invites [HC Joining-a-WHOOP-Team]. The badge visual is UNCONFIRMED.

Navigation history (to avoid copying an outdated layout):
- 2020: a bottom nav bar was introduced with Home/Overview, a Coaching page (Strain Coach, Sleep Coach, Performance Assessments), WHOOP Live, Community, and More (far right) [Locker "app-update-navigation-bar"].
- 2023: the Home screen got Sleep/Recovery/Strain dials and a **Plan** tab; later that year the Action (+) floating button arrived [Locker home-screen article].
- **May 8, 2025: Plan tab removed** ("removal of the Plan tab", Performance Assessments moved to email; Month in Review replaced MPAs) [HC Viewing-Trends 5/22/2025]. The **Health tab was added** (May 2025) [HC WHOOP-Basics; forum 820].
- June 2025 build [SEEN 69]: a standard full-width tab bar (Home, Health, Community, More, without the floating W) and a **white circular "+" floating at bottom-right** above the bar. The header shows a person-outline profile icon and a date pill "< WED, JUN 4 >".
- July 2025 variant [SEEN 94]: the 4th tab read **"Profile"** (person + list icon) and "MORE" was a pushed screen with a back chevron. Treat this as a short-lived variant or A/B test.
- **Oct–Nov 2025 onward** [SEEN 60–68]: floating capsule (Home, Health, Community, More) plus a floating **W** Coach button. The **Action (+) moved next to the "My Day" header** ("The + sign should be to the right of the 'My Day' section towards the top of the home screen", forum staff 2025-11-04; [HC Navigating 11/17/2025]: "The Action (+) button is now positioned to the right of My Day").
- Some help articles still say "tap the + icon at the bottom right" (old floating position). The current position is the My Day header.
- Feb 2026: a member asked to "swap the Community button with the Plan button on the tab bar, as it was in a previous version" (forum 13849). This confirms there is no Plan tab now.

### 1.2 Screen chrome patterns [SEEN throughout]
- **Pushed detail screens**: back chevron "<" at top-left, a **centered UPPERCASE letter-spaced title** (e.g. HEALTH MONITOR, STRESS MONITOR, SLEEP PLANNER, TREND VIEW, HEART RATE SETTINGS, DEVICE SETTINGS, MY MEMORY, ECG REPORT, HEALTHSPAN, JOURNAL INSIGHTS), and an optional right action: an **(i) info circle**, a **gear** (Stress Monitor, MCI settings), a **calendar** (Sleep Planner), a **history clock** (Coach), "•••" (activity), or an **export/download** icon (Labs).
- **Modal flows** use an **"X"** at top-left instead of "<" (Device Settings, Journal, ECG onboarding, Sleep activity detail, Symptoms sheet).
- **Date navigator pill**: "< TODAY >" (or "< WED, JUN 4 >", "< MAY 9 - MAY 15, 26 >"). The chevrons sit in a dark capsule and the current label sits in a lighter inner capsule. The forward chevron is greyed when there is no future day.
- **Section headers** inside cards are UPPERCASE and tracked (TODAY'S ACTIVITIES, TONIGHT'S SLEEP, HEALTH MONITOR). **Page-level section titles** are large Title-case white text: "My Day", "My Dashboard", "Get Started", "Looking Ahead", "Today's Activities", "Personal Records", "Current Cycle".
- Coaching text cards use a 1 pt **gradient border** (blue→violet, or pink→violet for feature promos) and end in an UPPERCASE CTA with an arrow, e.g. "LEARN MORE WITH COACH →", "EXPLORE YOUR RECOVERY INSIGHTS →", "VIEW YOUR WHOOP COACH ANALYSIS →", "LEARN MORE WITH WHOOP COACH →", "START ACTIVITY →", "SHOW ME AROUND →".

---

## 2. Home tab, top to bottom (current)

Primary evidence: 50 (App Store), 60–68, 83, 91, 101/102; plus [HC Navigating 11/17/2025] and Locker "The WHOOP Home screen".
The Locker gives the official order: *"From top to bottom: WHOOP Streak & device status → Three dials: Sleep, Recovery and Strain → My Day → My Plan → My Dashboard → Stress Monitor trend (Peak/Life) → Menstrual Cycle Insights or Pregnancy & Postpartum Insights (if opted in)."* It also says *"The dials and the My Day and My Plan sections are fixed. My Dashboard is the part you can customize."*

### 2.1 Header row [SEEN 50, 60, 63, 66, 91]
- **Left**: avatar circle (photo, or initials on a coloured disc such as "UN", "NR", "JC") next to a **streak capsule** with a **flame icon + day count** ("355", "234", "1038"). The flame colour changes with streak length [SEEN]: orange/red flame at 22–355 days, red flame with a blue core at 234, **blue flame at 1,038–1,161 days** (101). The exact thresholds are UNCONFIRMED. The Streak counts consecutive days with WHOOP data [HC]. Tapping the avatar opens Profile (section 17).
- **Centre**: date navigator "< TODAY >" [SEEN].
- **Right**: battery % (grey; **red #FF0026 when low**, e.g. "14%" in 91; a ⚡ bolt prefix appears in the App Store render "⚡ 65%" (50), presumably while charging, UNCONFIRMED) plus a **device indicator** (strap outline icon) with a small status dot (green = connected). "Check the WHOOP app for a green circle in the top-right corner, indicating the device is connected and fully synced" [HC Missing-Data]. **Tap → Device Settings** [HC].

### 2.2 Sync banner (conditional) [SEEN 91]
A black rounded bar under the header: "DATA CAUGHT UP" (white, bold, uppercase) on the left; "SYNCED TO" (white) over "7:32AM" (teal **#00F19F**) and a teal ✓ on the right. The help center refers to a "catching up" state [HC Why-is-my-WHOOP-Catching-Up]. Text variants such as "CATCHING UP…" are UNCONFIRMED.

### 2.3 WHOOP wordmark, centred [SEEN]
A thin geometric white wordmark (about 72 pt wide on a 414 pt screen) above the dials.

### 2.4 Three dials: SLEEP (left) | RECOVERY (middle) | STRAIN (right) [SEEN; HC Calibration-Timeline confirms positions]
- Each dial is a ring of about 86 pt outer diameter with about 6 pt stroke (measured at 3x). The **track is #333A3F**, starts at 12 o'clock and fills clockwise.
- Sleep ring **#7BA1BB**, value "80%". Recovery ring by score: **#16EC06 green (67–99), #FFDE00 yellow (34–66), #FF0026 red (1–33)**. Strain ring **#0093E7**, value "14.2" (one decimal; the locale decimal separator applies, e.g. "4,0" in EU locales [SEEN 61]).
- Number font: DIN-style bold, cap height about 19 pt (≈26 pt font); "%" is smaller (≈16–18 pt).
- Labels under the rings: "SLEEP ›", "RECOVERY ›", "STRAIN ›" (uppercase, tracked, bold, with a small grey chevron). **Tap a dial → deep dive** (section 9).
- **Strain ring extras** [SEEN 66, 73, 91]: a **lighter-grey arc segment (#5B6164)** on the track beyond the fill and a **small white tick**. These mark the day's Strain Target / optimal range; the exact semantics are not documented (forum 9033 asks the same question). UNCONFIRMED: the white tick is the target and the grey arc is the optimal band.
- Before data exists: "--%" in grey for Sleep/Recovery [SEEN 61, 68].
- After calibration, the "Colored Recoveries Score" unlocks after 3 recoveries [HC Calibration].
- **Sticky collapsed header** [SEEN 62, 65, 67]: when scrolled, the top shows a compact row of mini rings (about 18 pt) with labels "SLEEP  RECOVERY  STRAIN" side by side.

### 2.5 Coaching / Notification-Center card stack [SEEN 50, 83, 37, 04]
- A stack of rounded cards (bg about #202528 / #2B3033) with a **✓ + count chip** at top-right (e.g. "✓ 2", "✓ 3"). Tap ✓ to dismiss or "complete" the card; the count is how many cards remain. Lower cards peek out underneath.
- Seen and documented examples:
  - "**Optimal Health** – Take advantage of your green Recovery by meeting your Strain target of 15.5…" (50)
  - "**Exercise Trends in Strength Trainer** … SHOW ME AROUND →" (83, purple gradient border)
  - "**Establish your heart health baseline with ECG readings** … TAKE MY FIRST READING →" (magenta CTA #C14BCC) (37) [IFU]
  - "**Turn Off Your Alarm?** You have an alarm scheduled today, but it looks like you're already awake. TURN OFF ALARM →" (blue CTA) (04) [HC]
  - Merge Sleep [HC Cycles], "Process Now" sleep card [HC Auto-detection], "Set up notifications" (IHRN) [IFU], overlapping-activity fix prompts [HC Cycles]: text in HC, visuals UNCONFIRMED.
- Year in Review: "an icon will appear on your Home screen" in December [HC Year-in-Review-2025].

### 2.6 Health Monitor tile | Stress Monitor tile (side by side) [SEEN 50, 60, 63, 66, 68, 91]
Two equal tiles: 16 pt side margins, about 12 pt gutter, about 185 pt wide each on a 414 pt screen, about 90 pt tall, **radius ≈10–12 pt**, bg **#2E3337** (range #2D3135–#303438).
- Title: "HEALTH MONITOR ›" / "STRESS MONITOR ›". White, bold, uppercase, about 11 pt with about 10% tracking. A grey chevron sits at the right.
- Status line: a **24 pt square badge** (radius ≈4 pt), then a coloured uppercase status, then a grey subline.
  - Health Monitor: ✓ badge on dark green (#325048 / #245044), "**WITHIN RANGE**" (green), "5/5 Metrics". Or "–" grey badge "**Pending**" (68). Or **"!" badge on #4C2B34**, "**VERY ELEVATED**" (#FF0026) with the metric name "Skin Temperature" (91). [HC Health Monitor: Green within range / **Orange slight deviation** / **Red significant deviation**.] An orange-state label wording such as "ELEVATED" is UNCONFIRMED.
  - Stress Monitor: the score in a tinted badge ("0.7"), then the level and time. **LOW = Recovery-blue #67AEE6** (badge bg #354550), **MEDIUM = green/teal** (e.g. "1.4 MEDIUM 6:16 AM"), **HIGH = orange/amber** ("2.0 HIGH 19:56"). Observed values: LOW 0.1–0.8, MEDIUM 1.2–1.5, HIGH 2.0. The exact cut-offs are UNCONFIRMED (scale 0–3 [HC]).
- Both are Peak/Life only. On One, health features are "greyed out because you need to upgrade" [HC]. Whether these Home tiles appear greyed or hidden on One is UNCONFIRMED.

### 2.7 "My Day" section [SEEN 60, 63, 64, 66, 91; HC]
- Header: "**My Day**" (large white, about 21–22 pt semibold, Title case, left). At the right is the **Action (+) button**: a **white rounded square** (about 28–30 pt, radius about 8 pt) with a black "+". While open it turns into a **dark rounded square with "✕"** (64). See section 3.
- Row 1, the Daily Outlook entry [SEEN]: a full-width row (about 40 pt tall, radius about 10 pt, bg #2B3033): ☀ sun icon, "**Your Daily Outlook**" (white, about 17 pt), chevron. When **unread** the row has a **warm-to-cool gradient fill** (left about #847C6F beige → right about #384653 slate) and a **gold chevron** (50, 63). Some builds put a **small square W Coach button** at its left (63–65).
- Row 1 alternative for brand-new members [SEEN 61]: a "**Get Started**" header with the card "**Ready to get moving?** Start your first activity and come back to explore your heart rate zones and more on WHOOP. **START ACTIVITY →**" (pink→violet gradient border). Then a **Coach input box** "Ask a question, get support…" with a W icon (the "WHOOP Coach Text-Box that appears on the Overview screen" [HC]).
- **TODAY'S ACTIVITIES card** (bg #2B3033, radius about 12 pt) [SEEN]:
  - Header "TODAY'S ACTIVITIES" (uppercase, tracked, bold, about 11 pt) with an **expand icon (↗↙ diagonal arrows)** at right. **Tap → full-day HR timeline** (106: "< TODAY >", the whole day's HR line with sleep in Sleep-blue and a "RECOVERY 82%" marker at wake time in green, x-axis 04:00 / 08:00 / 12:00).
  - Activity rows (bg **#404447**, radius about 10 pt) [SEEN]:
    - **Left pill** (about 100×40 pt, radius about 8 pt) in the activity's colour: **Sleep = #7BA1BB with a white crescent moon + duration "6:41"**; a strain activity is a **Strain-blue pill with the activity glyph + strain "5.4"** (e.g. "OTHER"); a nap has its own glyph + duration "2:03".
    - Middle: the activity name in UPPERCASE ("SLEEP", "NAP", "OTHER").
    - Right: two right-aligned grey times (**#A0A2A3**), start "[Thu] 11:45 PM" over end "5:38 AM" (the bracketed weekday appears when the start is on a previous day), and a **thin vertical coloured bar** (the activity colour) at the far right.
  - Empty sleep: "**NO SLEEP**" row with an outlined "**ADD SLEEP**" button (68).
  - Footer buttons, side by side (bg #404447, radius about 10 pt): "**＋ ADD ACTIVITY**" and "**⏱ START ACTIVITY**" (stopwatch icon). [HC: "From the Home tab, scroll down to My Day and tap Start Activity."]
  - "View logged workouts, recovery activities, naps, and sleep in Today's Activities on the Home Screen" [HC].
- **TONIGHT'S SLEEP card** [SEEN 01, 61, 91; HC]: header "TONIGHT'S SLEEP ›". Left: sunset icon + "**22:39**" + "RECOMMENDED BEDTIME". A dashed connector. Right: strap-vibrate icon + "**07:30**" + "● ALARM ON" (green) + mode "EXACT TIME", or "ALARM OFF" (orange) with a sunrise icon. New members see a full-width "**SET ALARM**" button (strap icon). **Tap → Sleep Planner** (section 5). "Scroll to 'Tonight's Sleep' below the Today's Activities list" [HC].

### 2.8 My Journal card [HC; SEEN 69 (June 2025 build)]
- June 2025 build: a "✓ MY JOURNAL" row (green check when done) with an "✎ EDIT" pill button, placed between Activities and My Dashboard.
- [HC 9/18/2026] "Home screen: Scroll to the Journal card below your activities." "find the 'Behavior Insights' button under 'My Journal' on your home screen." The exact 2026 card layout is UNCONFIRMED. A forum post (Apr 2026) lists Home sections as "My Day, My Plan, My Journal, Dashboard".

### 2.9 My Plan (Weekly Plan) [HC Weekly-Plan 8/6/2025]
- Unlocks after 7 sleeps. "On the Home screen – Under 'My Plan', you'll see a **progress bar** summarizing your average progress across all your goals for the week." "Tap the progress bar – View your progress on each goal and tap '**View My Plan**' for a detailed breakdown." The card visual is UNCONFIRMED (no screenshot found).
- The older wording "My Week" also appears ("Scroll down and click on 'My Week'"). The current label is "My Plan".

### 2.10 Looking Ahead / Calibration Timeline (new members) [SEEN 61, 62]
"**Looking Ahead**" section title, then the card "**CALIBRATION TIMELINE ›** Wear your WHOOP to bed nightly and check back in here to track your sleeps and discover new insights." with a **progress ring "0/7"** on the right.

### 2.11 My Dashboard (customizable) [SEEN 62, 67, 69; HC]
- Header "**My Dashboard**" (large Title case) with a **pencil icon** at the right of the header (June 2025 label: "**CUSTOMIZE ✎**").
- While calibrating there is no pencil (forum 14836) and a "**Personalization in Progress**" card shows: "As your device calibrates to your unique physiology, you'll gain insight into your trends here." (strap illustration with a blue waveform).
- Tiles are **full-width rows** (bg about #2B3033, radius about 10 pt): an outline icon at left, an UPPERCASE metric name, the value right-aligned (bold), a small grey baseline beneath, and a ▲/▼ trend arrow. Example (69): "STEPS 9,931 ▲ / 8,563", "CALORIES 1,945 ▲ / 1,842", "HEART RATE VARIABILITY 61…". While calibrating: name + chevron only (62/67: HRV, SLEEP PERFORMANCE, STEPS, CALORIES).
- **Edit flow** [HC Navigating]: "1. From the Home screen, scroll down to My Dashboard. 2. Tap the pencil icon on the right side of the section header. 3. Select which metrics you want to display or hide. 4. Drag and drop to reorder the tiles. 5. Tap Save." VO₂ Max article: "Tap Customize next to My Dashboard → Scroll to VO₂ Max and tap the plus (+) icon to add it and click save" (an add/remove list with + buttons). Steps article: "Tap Customize in Key Statistics → Deselect Steps" (older name "Key Statistics").
- **Tile catalog** (from help articles, union of mentions): HRV, Resting Heart Rate, Respiratory Rate, Sleep Performance, Hours of Sleep, Steps, Calories, VO₂ Max, Weight, Lean Body Mass (Body Fat %), Heart Rate Zones 1–3 / 4–5, Strength Activity Time, Day Strain, Recovery, Stress (Total Day / Sleep / Non-Activity), Skin Temp, Blood Oxygen. The full exact catalog is UNCONFIRMED.
- **Tap any tile → Trend View** for that metric (section 8).
- Default tiles for new members (62/67): HRV, SLEEP PERFORMANCE, STEPS, CALORIES.

### 2.12 Stress Monitor graph card (on Home) [SEEN 67; HC]
A full-width card "STRESS MONITOR ›", "Last updated 8:13 PM" (grey) on the left, "MEDIUM **1.2**" on the right, and a mini line graph (0–3.0 axis, activity glyph markers). "The Stress Monitor will also be available on the Home Screen. Scroll down on the Home Screen to find the Stress Monitor." [HC]. Peak/Life only.

### 2.13 Hormonal Insights card(s) (if opted in) [HC]
"Those opted in will see Menstrual Cycle Insights or Pregnancy & Postpartum Insights" on Home. Card visual and position UNCONFIRMED.

### 2.14 Promotional tiles at the very bottom [forum 12800, Dec 2025]
"the stuff at the very bottom of the home screen, Advanced Labs etc." Members called it advertising. Visual UNCONFIRMED; likely similar to the "Discover More" list (17).

---

## 3. Action (+) button menu [SEEN 64; HC]
Tap the white "+" next to "My Day". The rest of the screen **dims and blurs** (sampled #14171C), and a **popover card** (frosted dark, sampled about **#2D333C** with #333C42 / #30363F variation from the blur; radius about 16 pt, UNCONFIRMED) opens **anchored above the + at top-right**, covering the dials area. The + button becomes a **dark rounded square (#25292C) with a white "✕"**. Items, top to bottom (icon + UPPERCASE label, about 13 pt bold tracked):
1. 📷 **CREATE WHOOP LIVE** (camera icon): overlay real-time HR/Strain/Recovery/Sleep onto a photo or video [HC].
2. 📓 **COMPLETE YOUR JOURNAL** (notebook + pen): opens the Journal [HC: "+ > My Journal"].
3. 🏋 **STRENGTH TRAINER** (weightlifter icon) [HC].
4. ＋ **ADD ACTIVITY**: manual log (activity or sleep; choose type and start/end times).
5. ⏱ **START ACTIVITY**: live tracking with Strain Target.

Manual sleep: "+ → choose Sleep from the Activity list → set start and end times → (4.0) specify where you wore WHOOP" [HC Cycles].

---

## 4. Activities: start, add, details, edit [HC]
- **Start Activity flow** [HC Strain-Coach 6/30/2025]: pick the activity type from the list (about 150 types, section 23.4). A **Track Route** toggle appears for GPS types (Running, Walking, Cycling, Hiking, Swimming, Paddleboarding, Rowing, Kayaking, Mountain Biking, Triathlon, Snow Shoveling, Trail Running, Winter Biathlon, Nordic Walking, Ski Touring, Mountaineering, Roller Hockey, Sprint Training, Freediving…). Set the target with a **slider** for ideal activity Strain; the screen shows optimal / overreaching / restorative training state. Live view shows strain building with updates every 10 min; a haptic plus notification fires when the target is reached; end with "**End & Save**". 24 h maximum.
- **Live Activity / Dynamic Island** during an activity [SEEN 20]: green heart + "**137 bpm**"; a blue stopwatch pill "**15:51**"; a **5-segment HR-zone bar** with a white dot and "**ZONE 3**" (zone colour); bottom row "**11.2 mi** DISTANCE | WHOOP wordmark | **23.6 mph** SPEED". The background is dark with a green tint.
- **Activity details screen** [HC Strain-and-Recovery-Details 10/8/2025; SEEN 82]:
  - Header: "<", activity glyph + "**ROWING**" over "18:52 to 19:24", "•••" (top-right → Edit / Delete / for naps "Convert to Sleep").
  - Strain activity sections, top to bottom: HR-zone list **ZONE 5 … ZONE 0**. Each row reads "ZONE 4 162-171 BPM 2%" with the duration right-aligned "0:00:48" (seconds shown smaller). A thin zone-coloured progress bar sits over a hatched typical-range background; tap a zone for ranges and entry times. Then the note "Zone ranges automatically updated on 1/6/26. **View HR Settings**". Then "**KEY STATISTICS** vs. 30 DAY AVERAGE": tiles "CALORIES 214 cals ▲137cals", "AVG HR 126 bpm"… Then the **route map** at the bottom for GPS activities ("swipe left to view the route").
  - The **Coach icon** in Activity Details gives "Activity Insights" (AI explanation plus chat) [HC].
  - Strength Trainer activities add "Total Strain: cardiovascular vs. muscular" and "**Calculate Muscular Load**" (Log Later) [HC].
  - **Recovery-activity details** [HC]: trend summary and advice, a session HR graph, then min/max/avg HR at the bottom, then "Recovery Impacts" at the bottom.
- **Edit** [HC]: open the activity → "•••" top-right → **Edit** → adjust start/end → **Save**. Strength Trainer-linked activities cannot be edited.
- **Sleep activity detail** [SEEN 77]: "✕ ☾ SLEEP 11:24 pm to 6:14 am •••"; "0:29 AWAKE (▼0:52)", "8 WAKE EVENTS (▼14)"; a coach insight card with a blue border, "…Learn more with WHOOP Coach"; the HR graph; "TYPICAL RANGE | DURATION 6:49"; then rows AWAKE/LIGHT/SWS (DEEP)/REM, each with % and duration, drawn as hypnogram-segment bars.

---

## 5. Sleep Planner and Wake Alarm [HC Sleep-Coach-with-Wake-Alarm 10/30/2025, Haptic-Alarm 10/30/2025; SEEN 86 (current), 02/03 (older)]
Access: Home → TONIGHT'S SLEEP → **SLEEP PLANNER**.

Current layout (86, Android, Oct 2025):
1. Header "< SLEEP PLANNER (?)" with a **calendar button** (circle outline) at the right. A small "**OFF**" chip under it shows the schedule state.
2. W logo in a circle, centred.
3. Headline sentence (white, about 20 pt): "**Go to bed at 10:00 PM today to achieve a 91% Sleep Consistency tomorrow.**"
4. "**TOMORROW I WANT TO**" (tiny grey label), then an **outlined white pill** "**OPTIMIZE SLEEP**". Tap it to change the goal. HC options: "**Improve My Sleep**" (consistency-based) or "**Reach My Sleep Need Goal**" (70 / 85 / 100% of Sleep Need; older names Get By / Perform / Peak).
5. Two big DIN numbers: "**22:00** SUGGESTED TIME TO BED" (left) and "**06:30** YOUR WAKE TIME" (right).
6. "**TIME IN BED**" label, a **hatched bar** across with a centred black pill "**8:30**" (white outline), then a dashed bracket below labelled "**RECOMMENDED 22:30 - 07:10**".
7. Bottom panel "**ALARM**" with a strap icon and an on/off toggle, then two tiles: "**ALARM SET TO** OFF" and "**WAKE TIME SET TO** 06:30".

Alarm options [HC]:
- Toggle ON, then choose **Alarm Mode**: **Exact Time** / **Sleep Goal** / **In the Green** (Recovery ≥67%). Then the **Sleep Goal %** (100 / 85 / 70) and the **Latest Wake Time** (picker; older UI 02: wheel picker sheet "Set your latest wake time.", "Alarm will vibrate between 6:20 AM - 7:20 AM", "SAVE & SET ALARM" teal outlined pill).
- Sleep Goal and In the Green use a 1-hour window. The strap vibrates for 30 s. **No snooze.** Double-tap the strap to stop it.
- Schedules: tap the **calendar icon** → "**MY SCHEDULE**" screen (03): a toggle at top-right, an outlined pill "**CREATE SCHEDULE**", and helper text "Create a schedule to customize your wake time by day of the week." Choose days, alarm mode, sleep goal and wake time → Save → turn the scheduler on.
- Warnings: strap battery <20% shows a warning, and an **Alarm banner** appears on the Overview and Sleep Planner pages; low phone battery warning; "**Saving failed**" when the strap is not connected.
- Older (pre-2025) Sleep Planner visual (02): "10:41 PM SUGGESTED TIME TO BED" and "100% SLEEP NEED GOAL" at the top, a hatched teal Time-in-Bed bar with "8:39", an "OPTIMAL 10:45 PM - 8:45 AM" bracket.
- Day in Review (evening Coach) gives a "recommended bedtime range" [HC Coach].

---

## 6. My Plan / Weekly Plan [HC Weekly-Plan 8/6/2025, January-Jumpstart-2026]
- Entry: Home → My Plan progress bar → "**View My Plan**" → **Plan Overview** page. Tap the current plan at the top to **edit / switch / end**. Older text says "Click the pencil icon beside the plan to edit it" [HC First-30-Days].
- Setup: choose a **Preset Plan** (**Boost Fitness**, **Feel Better**, **Sleep Deeper**; January Jumpstart adds resolution presets) or a **Custom Plan** (also "Custom Plan for You", AI-recommended, or co-designed with Coach) → review goals → "**Start Plan**".
- Goal categories (5): 1) Sleep Performance / Sleep Duration (slider); 2) Strain & Training Load (slider); 3) HR Zone time: Zones 1–3 "Moderate" and Zones 4–5 "Vigorous"; 4) Activity goals (toggle activities, days per week); 5) Behavior goals linked to the Journal (Hydration, Protein, Alcohol avoidance, Mindfulness…). Also Steps (daily/weekly; compared with 5K/10K/marathon distances), Sleep Consistency, Hours of Sleep.
- Mon–Sun cadence. Friday check-in notification; Monday recap after journaling. Overall progress is the equal-weighted average of all goals.

---

## 7. My Dashboard
See section 2.11 for the layout, the edit flow (pencil → select/hide → drag to reorder → Save) and the tile catalog. Tapping a tile opens the Trend View (section 8).

---

## 8. Trends / "Trend View" [HC Viewing-Trends 5/22/2025, Navigating, VO2-Max, Steps, Max-HR; SEEN 75, 80, 81]
- **Entry**: tap any My Dashboard tile, or "tap into any metric under My Dashboard, tap **^**, and select the metric". Also from the deep dives (tap a contributor row).
- **Layout** (81, May 2026):
  1. Header "< **TREND VIEW**".
  2. A **metric dropdown pill** (full width, rounded, bg #3A3F43-ish): icon + "HEART RATE VARIABILITY" + "⌄". This is the "^"/dropdown that switches metric ("A dropdown at the top categorizes metrics under Sleep, Recovery, or Strain").
  3. Left: "**AVERAGE**" label, big "**40** ms", and a delta chip "▲ 5% vs. prior week" (green chip). Right: a segmented control **W | M | 6M** (dark capsule; the selected segment is a lighter rounded rectangle).
  4. Date-range navigator "< MAY 9 - MAY 15, 26 >".
  5. Insight sentence ("Your average HRV during this 7-day period was within its typical range (34 - 40) at the time.") or the Voice-of-WHOOP summary.
  6. Legend "▪ TYPICAL RANGE" (shaded band).
  7. **Line chart**: dots with value labels, a typical-range band, x labels "Sat 9 … Fri 15". **Press and drag** on the graph to scrub [HC].
  8. "**LEARN MORE** … **VIEW ALL →**" with video/article cards (a "VIDEO" tag).
- Two-series example "HOURS VS. NEEDED (HOURS)" (80): "9:40 hr ▲19% AVG. NEED" and "6:17 hr ▼10% AVG. HOURS"; the line chart uses a green series (need) and a grey-blue series (hours). There is also a bar-chart variant "HOURS VS. NEEDED (%)" (75).
- Views: **W** (weekly, arrows move between weeks), **M** (monthly, average highlighted), **6M** (month-over-month). The Overview trend plots Strain against Recovery (7-day average) [HC; possibly legacy].
- Trend metrics by pillar [HC]: **Strain**: Day Strain, Average HR, Calories, HR Zones (all / 1–3 / 4–5), VO₂ Max (M and 6M only), Steps, Strength Activity Time. **Sleep**: Performance, Hours vs. Need, Time in Bed, Restorative Sleep, Efficiency (plus Consistency). **Recovery**: Recovery, HRV, RHR, Respiratory Rate. **Stress**: Total Day Stress, Sleep Stress, Non-Activity Stress (with zone toggles). **Body**: Weight, Lean Body Mass. With MCI on, a **cycle overlay** shows on trends ("SHOW CYCLE OVERLAY ON TRENDS" toggle, 11).
- Manual entries inside trends: "**+ ADD MANUAL VO₂ Max VALUE**", "**+ Update Weight**", and weight/LBM/body-fat entry ("Tap Trends View > Select Metric > Enter Data"). The VO₂ Max trend has a "**Cardio Fitness Level**" section with an (i) for personal thresholds [HC].

---

## 9. Deep dives (tap a dial)

### 9.1 Recovery deep dive [SEEN 70, 71; HC WHOOP-Recovery 9/11/2025, Recovery-Insights 3/20/2026]
1. Header "< TODAY (i)" or "< WED, JUN 4 (i)".
2. **Big ring** (about 75% of screen width) in the recovery colour: "**WHOOP**" (small wordmark inside, top), "**31%**" (huge DIN), "**RECOVERY**" (small caps).
3. **Contributors card**, attached to the ring by a small **pointer notch** at top-centre. Rows have an icon + UPPERCASE label, a value right-aligned with a ▲/▼/• arrow, and the 30-day baseline in small grey beneath:
   - HEART RATE VARIABILITY 61 ▼ (76)
   - RESTING HEART RATE 66 ▲ (62)
   - RESPIRATORY RATE 15.0 • (15.0)
   - SLEEP PERFORMANCE 53% ▼ (76%)
   - Footer chip "▲▼ Wed, Jun 4 vs. last 30 days".
   - Arrow colours: green ▲/▼ when favourable, orange when unfavourable (HRV down = orange; RHR up = orange). Partly UNCONFIRMED.
4. **Coach card** (gradient border): "Your HRV (70 ms) is within its typical range of 65 ms to 84 ms, which contributed to a yellow Recovery. Today is a great day to move your body…" + "LEARN MORE WITH COACH →" / "EXPLORE YOUR RECOVERY INSIGHTS →".
5. "**RECOVERY INSIGHTS** / **BEHAVIOR INSIGHTS ›**" row: Behavior Insights (Journal impacts) are reachable "through the Recovery dial" [HC].
6. Other Recovery inputs are listed in HC (SpO₂, Skin Temp) but not in the card. Skin Temp, SpO₂ etc. live in **Health Monitor**.

### 9.2 Strain deep dive [SEEN 72; HC WHOOP-Strain 3/6/2026]
1. "< TODAY (i)".
2. Big blue ring: "WHOOP", "**11.8**", "STRAIN".
3. Contributors card (pointer notch): HEART RATE ZONES 1-3 1:33 ▲ (1:11), HEART RATE ZONES 4-5 0:00 ▼ (0:11), STRENGTH ACTIVITY TIME 0:00 ▼ (0:52), STEPS 2,430 ▼ (11,725); footer "▲▼ Today vs. last 30 days".
4. Coach card: "Your optimal Strain recommendation will be calculated once WHOOP processes your recent Recovery." + "**EXPLORE YOUR STRAIN INSIGHTS →**".
5. "**Today's Activities**" (Title-case section) with the activity list ("Logged activities can be viewed… under Today's Activities when you tap the Strain dial" [HC]).
- Strain scale: Light 0–9, Moderate 10–13, High 14–17, All Out 18–21 [HC].

### 9.3 Sleep deep dive [SEEN 74, 78, 79; HC WHOOP-Sleep 8/6/2025]
1. "< TODAY (i)".
2. "**Last Night's Sleep**" (large) with "**EDIT ✎**" at the right; subline "Today vs. prior 30 days".
3. Card "**HOURS OF SLEEP**" (i): "**8:10** ▲" with the grey baseline "7:58"; sleep HR line chart (y 30–150) from "23:47" to "08:31".
4. "▪ TYPICAL RANGE … DURATION **8:41**".
5. Stage rows. Each has a circle icon, the stage name + % (coloured), duration right-aligned, and a coloured bar over a hatched typical-range background:
   - **AWAKE 5% 0:31** (light grey bar)
   - **LIGHT 57% 4:51** (lavender/periwinkle bar)
   - **SWS (DEEP) 20% 1:45** (pink/magenta bar)
   - **REM 18% 1:34** (violet bar)
6. "▪ **RESTORATIVE SLEEP 3:18 ▼ / 3:22**" (REM + deep).
7. Further sections per HC: Sleep Performance breakdown (Sufficiency "Hours vs. Needed", Consistency, Efficiency, Sleep Stress) with Optimal/Sufficient/Poor colours (**sufficient = grey, poor = orange** [HC]), Respiratory Rate, Wake Events, Sleep Debt, Sleep Need breakdown (Baseline / Recent Strain / Sleep Debt / Recent Naps). The visual order of these lower sections is UNCONFIRMED. The old big "SLEEP EFFICIENCY 94% / ASLEEP / AWAKE / WAKE EVENTS" card was removed in the 2025 redesign (76; forum complaint "30 day ave… wake event removed on new UX").
- Thresholds [HC]: Sleep Performance Optimal ≥85%, Sufficient 70–85%, Poor <70%. Consistency 80/70. Efficiency 90/80. Sleep Stress <1% / 1–5% / >5%.

---

## 10. Stress Monitor [HC Get-to-Know-the-Stress-Monitor 9/3/2025; SEEN 54]
Access: Health tab → Stress Monitor, or the Home tile/card. Peak/Life only.
1. Header "< **STRESS MONITOR** ⚙" (gear = settings/notifications).
2. "< TODAY >" date pill, with an (i) at the right below the header.
3. **Semicircle gauge** (about 240° arc) from 0.0 to 3.0, gradient **blue → green → yellow/orange**, a white needle/tick at the current value; centre "**1.5**" (huge), "**MEDIUM**" (green caps), "Last updated 3:05pm" (grey); labels "0.0" and "3.0" at the arc ends.
4. **24-hour line graph** (0.0–3.0 gridlines). The line is coloured by zone (blue low, green medium, orange high). Icons along the top mark sleep (☾), activities (runner), a recovery/breath icon, and a count bubble ("3"). Shaded vertical bands mark activities. A dashed "now" line with a green dot. A **magnifier (zoom-out) button** at bottom-right. x-axis "3:00am 7:00am 11:00am 3:05pm" with "<" to page back. HC note: "the Today view displays data from the last 24 hours… confirm by tapping the magnifying glass."
5. Coach card (gradient border): "Most of your time was spent in the low stress zone. Your longest period of high stress started at 7:42 AM and lasted for 51 minutes." + "LEARN MORE WITH WHOOP COACH →".
6. Tiles "**TOTAL DAY**" / "**NON-ACTIVITY**" / "**SLEEP**" (stress), e.g. "TOTAL DAY: TUE, JUL 18 VS. TYPICAL TUESDAY" with a 3-segment horizontal bar (blue / green / orange = time in Low / Medium / High). The W/M/6M trends sit below the graph [HC].
7. "**Sessions**" → "**Guided Breathing Exercises**": **Increase Relaxation** / **Increase Alertness**. Customize breathing rate, session duration and number of cycles → "**Start Exercise**". Afterwards, toggle between stress and HR to see the response.
- Notifications: an evening stress summary; adjust in **App Settings > Notifications** [HC].

---

## 11. Health tab and sub-screens

### 11.1 Health tab root [HC Navigating 11/17/2025, WHOOP-Basics 8/13/2026; SEEN 90, 92]
Cards, all on one vertical scroll; membership-locked items appear **greyed out** with upsell [HC]. The current order is UNCONFIRMED. Union of documented cards:
- **Live Heart Rate**: card at the top: "HEART RATE" + blue/teal heart + "**68** BPM" + "Zone 0" with a live line chart ending in a white dot (90, Oct 2025). On Peak/Life, live HR now lives inside Health Monitor ("For One members. Peak and Life members can find live heart rate in the Health Monitor" [HC]; forum 13685: "buried two clicks into the Health tab").
- **Hormonal Insights**: Menstrual Cycle Insights or Pregnancy Insights (all tiers, opt-in).
- **Healthspan** (Peak/Life, 18+): card "HEALTHSPAN" + lock icon "Keep wearing WHOOP consistently. Log 21 sleeps in a month to unlock Healthspan." with a blurred preview and "LIFE | PEAK" (92).
- **Health Monitor** (Peak/Life): card "HEALTH MONITOR ›" with 5 metric icons (**RESP, SpO₂, RHR, HRV, TEMP**), each with a ✓ badge (grey dot = calibrating), then "✓ **4/4 metrics within range**" (92).
- **Stress Monitor** (Peak/Life).
- **Heart Screener** (Life + MG, 22+, region-restricted): card "**HEART SCREENER**" + "**TAKE AN ECG ›**" at the right; "**AFib not Detected**" + green chip "**In the last 24 hours**"; heart illustration; sub-chips "✓ **BACKGROUND SCREENING**" and "✓ **ECG REPORT**" (100). IFU wording: "Heart Screener card" / "Heart Notifications card".
- **Blood Pressure Insights** (Life + MG, 18+).
- **Advanced Labs** (US purchase; free uploads worldwide) → "Manage Advanced Labs".
- **Connect Health Records** (HealthEx) [HC HealthEx].
- A forum post (Aug 2026, new Peak user) counted "5 widgets on the Health tab", 2 being Advanced Labs and Connect your Health Records.

### 11.2 Health Monitor [HC WHOOP-Health-Monitor-Report 7/22/2025; SEEN 87, 88, 89]
1. Header "< **HEALTH MONITOR**".
2. **HEART RATE** section: grey heart, "**--** BPM", "Calibrating…" (or a live value), a gridded chart with a dashed "now" line and white dot.
3. 2-column grid of metric tiles (bg #2E3337–#303539, radius about 12 pt). Each tile: an outline icon + UPPERCASE name (grey); a big value (DIN, about 34 pt) + unit; a **status chip** (bg #245044, text bright green about #00FFAC/#00F19F, ✓). Chip wording seen: "within 12.9 - 13.1", "**near** 95% - 100%", "**low** < 14.7".
   - RESPIRATORY RATE "12.9 rpm"; BLOOD OXYGEN (SPO₂) "98 %"; RHR "51 bpm"; HRV "77 ms"; SKIN TEMP (FROM BASELINE) "+0.1 °C" (or °F).
4. "**SHARE YOUR HEALTH REPORT**" row (share icon) with the caption "Printable report for sharing with your doctor, physician, trainer, or anyone of your choosing." (HC: "Export Health Report" → **30-day and 180-day PDF**.)
- Status colours [HC]: **Green = within normal range, Orange = slight deviation, Red = significant deviation**. Home summary "WITHIN RANGE 5/5 Metrics" / "VERY ELEVATED <metric>" (section 2.6). Shows **today only**; history is in the Health Report. Fully calibrated at 7 recoveries; Health Report at 14.
- BP Insights were "integrated" into Health Monitor for Life [HC Membership], but forum 4247 says BP is a separate Health-tab card.

### 11.3 Healthspan [HC Healthspan 4/21/2026; SEEN 51, 93, 112–115]
1. Header "< **HEALTHSPAN** (i)" with subtitle "Next update in 6 days". Week range "< AUG 19 - AUG 26 >".
2. A **particle orb**: green = younger, amber/orange = older, grey-amber mix. Centre: "**29.9**" + "**WHOOP AGE**" + "2.3 years younger" (green) / "10.0 years older" (amber). "<18" is shown as the lower bound.
3. "**PACE OF AGING**": "◯ Slow … **0.8x** … Fast ◔" over a barcode-like tick scale "-1.0x … 1.0x … 3.0x" with a white marker.
4. An insight card (pointer notch), e.g. "**Steady and Healthy**" / "Maintain Your Gains" / "Small Steps, Big Impact" / "Focus On One Habit" + "**VIEW YOUR WHOOP COACH ANALYSIS →**".
5. Contributor sections "**Sleep**" (with legend "▼ 6 Month avg. ▲ 30 Day avg."), then contributor rows (SLEEP CONSISTENCY, Hours of Sleep, HR Zones 1–3, HR Zones 4–5, Strength Activity Time, Steps, VO₂ Max, RHR, Lean Body Mass). Each has an "**Age Impact**" rating (green positive / grey neutral / amber negative) [HC]. The exact grouping (Sleep / Strain / Fitness) follows HC; the order of rows within each group is UNCONFIRMED.
6. WHOOP Age trend chart with an **M | 6M** toggle and a "WHOOP AGE vs. CHRONOLOGICAL AGE" legend (112).
- Locked state (93): big lock icon, "**21 SLEEPS TO UNLOCK**", "Log 21 sleeps in the last month. Keep wearing your WHOOP 24/7 to get insights.", white pill "**GOT IT**". Updates weekly (Sunday). Hide via Hide Metrics.

### 11.4 Heart Screener: ECG and IHRN [IFU; SEEN 30–38, 100]
- **ECG flow**: Health tab → Heart Screener card (or the Home card "TAKE MY FIRST READING") → onboarding pages ("X" to cancel) → "**Take your first ECG**" → **Continue** → "**Take a New ECG Reading**" → select wrist → "**Take a Reading**" → touch the clasp with thumb and index finger → **30 s** recording (Cancel available) → result.
- **ECG REPORT** screen (30/31): "< **ECG REPORT** (i)"; a timestamp "Oct. 21, 2022, 11:23:12pm - 11:23:42pm"; a gridded waveform in **purple about #A05CE4** (0s/1s axis); a result title "**Normal Sinus Rhythm**"; a 4-row checklist with **green ✓ badges (#1C3831 bg)** or **amber "!" badges (#362E20 bg, #F2AB45 glyph)** or grey "•" badges: "AFib not detected", "High Heart Rate not detected", "Low Heart Rate not detected", "Normal Sinus Rhythm detected". Then explanatory text. Then "**Share Your ECG Report**" (upload icon top-right → PDF), "**Add Symptoms & More**", "**All ECG Reports**", and "**Delete This ECG Report**" at the bottom.
- Result titles: Normal Sinus Rhythm · Possible Atrial Fibrillation · Possible Atrial Fibrillation - High Heart Rate · High Heart Rate (AFib not detected) · High Heart Rate (Unable to check for AFib - Heart Rate too high) · Low Heart Rate · Inconclusive (Unable to check for AFib / Normal Sinus Rhythm not detected / Inconclusive (Possible Arrhythmia)).
- "**ECG Reading Unsuccessful**" (38): amber "!", "This ECG Reading was unsuccessful. Please retake the ECG Reading.", outlined pill "**RETRY**". After 3 failures it suggests retrying in 15 min. Offline readings are queued.
- **IHRN** ("Heart Notifications"): Health tab → card → "Set Up IHRN" / "Turn notifications on" → **Detection History** (day tiles; "Clear all"; share report) → **Settings** with toggles "**Push & in-app notifications**" and "**Irregular rhythm detection**". The widget reads "AFib not detected in past 24 hours" or "Possible AFib detected". At most 1 notification per 24 h.

### 11.5 Blood Pressure Insights (Life + MG) [HC 12/17/2025]
Health tab → Blood Pressure Insights. Onboarding questionnaire (cannot be edited later) → **3 cuff calibration readings** (recalibrate every 30 days) → daily systolic/diastolic **ranges**. Colour bands: **Yellow** = systolic 121–139 or diastolic 80–95; **Orange** = systolic >139 or diastolic >95. W/M/6M trends. Needs at least 5 h in bed. Screen visuals UNCONFIRMED.

### 11.6 Menstrual Cycle Insights / Hormonal Insights [HC MCI 2/3/2026, Hormonal-Symptom-Predictions 2/20/2026; SEEN 09–13, 85]
- Screen (10/12): **purple gradient background**. Header "✕/< **MENSTRUAL CYCLE INSIGHTS** ⚙". "**Cycle Day 28 | Luteal Phase**" (phase name in violet). "Next period in: 1-3 Days". Month nav "< APRIL >".
- Then a **week-row calendar** (MON…SUN): each phase is drawn as a continuous **rounded band** behind the dates. Colours: **Menstrual = coral/red, Follicular = lavender, Ovulatory = teal-blue, Luteal = violet**. Predicted period days use a dashed coral circle; today has a white ring; a white dot = symptoms logged; a small dot = predicted symptoms. Legend below.
- Then "**POSSIBLE SYMPTOMS TODAY ›**" chips (outlined pills: Heavy Flow, Anxiety, Backache, Bloating…), "**LOG PERIOD DATA ⊕**", and "**LUTEAL PHASE COACHING ›**" with M/F/O/L phase tabs.
- **Symptoms sheet** (09): "**SYMPTOMS** ✕", the date "Wed, Oct 08", filter chips "Suggested | Physical Symptoms | Flow | Cerv…", then sections "PERIOD FLOW" (No Flow / Light / Medium / Heavy / Spotting; the selected row has a coral border) and "CERVICAL MUCUS" (Dry / Egg White (Ovulating) / Glue-like… with subtitles).
- **Settings** (11): "< **HORMONAL INSIGHTS**", toggle "HORMONAL INSIGHTS" (green), "MODE ›" (MENSTRUATING), "CONTRACEPTION TYPE ›" (NONE), toggle "**SHOW CYCLE OVERLAY ON TRENDS**", and a Privacy card "LEARN MORE →".
- **Current Cycle chart** (85): chips **SKIN TEMP | RHR | HRV | RECOVERY**, "Smoothed Data" bars (coral menstrual, violet luteal) plus an "Expected Trend" band, a "CYCLE DAYS" axis, and a "**CURRENT | LAST 3 MONTHS**" segmented control.
- Access: Health tab → Menstrual Cycle Insights; toggle via ⚙ or **More > App Settings > Hormonal Insights**.

### 11.7 Pregnancy and Postpartum Insights [HC 10/6/2025; SEEN 14]
"< **PREGNANCY INSIGHTS** ⚙", "< TODAY >", "**Week 5**" + "35 weeks remaining / **1ST TRIMESTER**", chips **RHR | HRV** (selected lavender), a legend "EXPECTED TREND (band) / ROLLING TREND (line)", a chart over weeks 1–13 with a dashed current-week marker and value "65 bpm", a "**CURRENT TRIMESTER | ALL TRIMESTERS**" segmented control, and an insight card with "Learn more". Enable via More > App Settings > Hormonal Insights > Mode > Pregnancy (due date). Disabling it starts a 12-week **Postpartum** mode.

### 11.8 Advanced Labs [HC Advanced-Labs 8/7/2026, Results; SEEN 15, 16, 109, 110]
- "< **ADVANCED LABS**": an info banner (amber) "Add your cycle phase…" + "CONFIRM NOW →", then a **step accordion** with green ✓ circles: Complete Clinical Intake → Schedule Your Lab Visit → Complete Your Lab Visit (DATE / TIME / LOCATION / CONFIRMATION ID / REFERENCE ID; buttons "ADD TO CALENDAR" (white), "CANCEL/RESCHEDULE", "VIEW LAB ORDER") → Processing Lab Tests → Get Your Clinical Report.
- "**LABS SUMMARY**" (109): a dotted ring "62/65 BIOMARKERS" with legend Optimal 44 / Sufficient 7 / Out of Range 11, a coach card "EXPLORE YOUR LABS IN DETAIL →", search "Search for Vitamin D, Cortisol, etc.", "FILTER & SORT ⌄", then the "Out of Range" list (marker on a gradient range bar). CSV export icon at top-right.
- Ranges: **Optimal / Sufficient / Out of range**. Requires MFA.

---

## 12. Journal flow [HC WHOOP-Journal-Overview 9/18/2026; SEEN 05, 105, 53]
- **Enable**: More → App Settings → **Journal** toggle.
- **Entry points**: (1) a morning prompt opens automatically after sleep is processed (defaults to **yesterday**); (2) the Home Journal card; (3) Action **+ → COMPLETE YOUR JOURNAL** (defaults to **today**).
- **Journal screen** (105): **purple gradient** background. Header "✕ **JOURNAL** ✎". A date row "< **MON, MAR 16** >" plus a "**TODAY**" outlined pill at the right. Under it a **horizontal day strip** of capsules (weekday "Mon", date "16", status: ✓ green filled circle = logged, empty circle = not logged); the selected day has a white outline. Swipe back up to 14 days. Then the large question "**What happened on Mon, March 16?**" (or "What's happening today?"). Then the behavior questions (Yes/No with ✓ / ✕ answers, follow-ups such as amount), then **Save**.
- **Calendar icon** → month view (105 top): green day numbers with a green dot = journal filled; grey = not filled; "Today" has a dashed circle; legend "• Journal filled out".
- **Edit behaviors** (pencil): a search bar (exact → fuzzy → synonym matching, e.g. "Coffee"→Caffeine, "Beer"→Alcohol) and category tabs (Sleep, Recovery, Nutrition…). More than 160 behaviors in 9 categories (Drugs & Medication, Health & Symptoms, Hormonal Health, Lifestyle, Mental Wellbeing, Nutrition, Recovery, Sleep & Circadian Health, Supplements; the full list is in the raw article). **Custom behaviors** are created via a WHOOP AI chat (name, unit, daily question → "Add").
- **Behavior Insights / "JOURNAL INSIGHTS"** (53): "< JOURNAL INSIGHTS", "REFRESHED DAILY", "**Recovery Impact Analysis**", "See how behaviors impacted your Recovery over the past 90 days." Axis header "▼ HURTS | % IMPACT | HELPS ▲". Rows (rounded cards): UPPERCASE behavior + signed % (green +, orange −), a **diverging bar** from a centre dot over a hatched track (green right, orange left, grey when negligible), and a "NEW" tag on a highlighted (blue-border) row. Unlock needs **5 yes + 5 no in 90 days**. A **Logging History** 3-month calendar is inside each behavior detail.

---

## 13. WHOOP Coach / WHOOP AI [HC Coach 9/18/2026; SEEN 07, 52, 111]
- **Entry points**: the floating **W** button (tab bar / any screen); the Daily Outlook row; the Home text box "Ask a question, get support…"; the Coach icon in Activity Details; "LEARN MORE WITH COACH" CTAs. Contact Support is via Coach [HC Contact].
- **Chat** (52): "< **WHOOP COACH**" + a "BETA V2.0" chip (V4.0 in Sep 2025) + a history (clock) icon at the right. Bot messages have a W avatar and no bubble; user messages are dark grey rounded bubbles, right-aligned. Bottom: a "new chat" icon + an input pill "**Ask WHOOP anything**" with a gradient border and a send ↑.
- **Daily Outlook** (morning plan; weather-aware; commit to an activity → shown on Overview, earn Kudos), **Day in Review** (evening; bedtime range), **Weekly Wrap**, **Month in Review**.
- **My Memory** (07): "< **MY MEMORY**", toast "✓ Context updated / New information applied to Coach.", headline "Shape your **WHOOP** experience." (WHOOP in blue), an input card "✦ Anything impacting your routine this week?" with [📄] [⌨ TEXT] [🎙 TALK], chips "**Timeline | Goals | Lifestyle | Health condition**" (selected = white pill, black text), a dated timeline ("TODAY", "TUE, MAY 20, 2025") of memory cards with tags "Active" (blue fill) and "Health Condition"/"Lifestyle" (outline), and a "New" badge. Access: the **lightbulb icon** in the chat, or **Profile → Personalization**.
- Settings: **App Settings > AI Settings > Coach ON/OFF** (needed for Year in Review); **App Settings > Coaching Preferences > Coaching Mode**: "Customized with your data" / "Education and Support Only". **More > Privacy Settings > Personalized Product Recommendations**. Coach is English only.

---

## 14. Strength Trainer [HC 5/21/2026; SEEN 08, 84]
- Entry: **+ → STRENGTH TRAINER**. Tabs/sections: **WHOOP Workouts**, **My Workouts** ("Create New Workout"), **Progress** (Exercise Progression), and "Log Automatically" / "**Generate with WHOOP AI** → Get Started" (type or photograph a workout).
- Exercise library filters: Movement Type / Equipment / Targeted Muscles. (i) shows exercise details (84: "EXERCISE DETAILS" with a video "PREVIEW", name "Bench Press - Barbell", description, "EQUIPMENT", "MUSCLE GROUP", and "Exercise Trends Coming Soon"). "Add Custom Exercise". "•••" on a workout → Copy / Share (text or QR).
- Live workout: timer, HR and zones, sets × reps × weight; an **HR Zones tab** (edit Max HR inline).
- **Exercise progress** (08): title "Pull Up"; chips "**Progress | History | Instructions**"; "AVG VOLUME **12** reps" + "▲ 2% past month" chip; an **M | 6M** toggle; "< MAY 25 - JUN 22, 25 >"; a **blue bar chart (#0093E7)**; then "**Personal Records**" rows (gold/silver/bronze medal, "12 reps +10 lbs", date, ⌄).
- Units: lbs/kg in Profile settings.

---

## 15. Community tab [HC Joining-a-WHOOP-Team 10/6/2025, Navigating; SEEN 103, 104]
- Root: "**Pending Invites**" (red dot on the tab icon), **My Teams** list (each team shows your rank on a chosen metric and unread chat counts), "**Recommended Teams**" + "**View All**". **"•••" top-right** → **Create Team** / **Enter Invite Code** (8-digit) / **Explore Teams** (public teams by activity, occupation, journal behaviors, location, pregnancy due dates). Root visuals UNCONFIRMED.
- **Create Team**: name, banner image, logo, leaderboard metrics (Strain / Recovery / Sleep; fixed after creation) → Create Team. Invite by search or share code/link.
- **Team page** (104): a blurred banner photo header with circular back and "•••" buttons and the centred team name. Tabs "**INFO | CHAT | STRAIN | RECOVERY | SLEEP**" (selected = white with underline). A filter button (circle) + segmented "**DAILY | MON - SUN | MONTHLY**" (selected = white outline pill). A metric label in its colour, "DAY STRAIN" (blue) "9,4 avg", with the date range and "Last Updated: 23:00" on the right. Leaderboard rows: avatar with a **progress ring in the metric colour** (blue for strain; green/yellow/red for recovery), "1. Name **11,5**" (value coloured), subline "Walking 11,2 on 06.10", "2 136 Calories". The Recovery board (103) shows "Recovery **75% avg**" (green) and rows "HRV: 91, RHR: 41" + "78%".
- Shared metrics: Strain (activity strain, day strain, calories), Recovery (score, HRV, RHR), Sleep (performance, hours). Team "•••" → Notification Settings (Mute); admins: Options → Manage Teams → Chat toggle. More → Privacy Settings → **Team Invitations** toggle.

---

## 16. More tab: menu tree

### 16.1 Root list [SEEN 94 (Jul 2025, pushed "MORE" screen); HC text for the rest]
Visual: a header bar (bg about #2E3336) with "<" and a centred "MORE", over a dark screen (#171C20 → #101518). The list is **full-width rounded rows** (row bg sampled **#2A2E32**, radius about 10 pt, about 16 pt side margins, about 8 pt vertical gaps). Each has a left outline icon (about 24 pt, grey), an UPPERCASE bold tracked label (about 13 pt), and an optional grey subtitle. Section headers are UPPERCASE grey ("ACCOUNT & SETTINGS", "SUPPORT"). Order seen in Jul 2025 (top partly cut off):
- (above, UNCONFIRMED: Refer a Friend at the very top; HC says "Select **Refer a Friend** at the top of the screen". Probably also profile info and Getting Started.)
- **WHOOP SHOP**: "Shop bands, smart apparel, and batteries" (cart icon)
- **GIFT A MEMBERSHIP**: "Gift a new member or purchase a gift card" (gift icon) [HC also calls it "Gift WHOOP"]
- Section **ACCOUNT & SETTINGS**:
  - **MY ACCOUNT** (person-in-circle)
  - **DIGITAL WHOOP LABS** (flask): research participation
  - **DEVICE SETTINGS** (strap + gear)
  - **APP SETTINGS** (clipboard/list)
  - **PRIVACY SETTINGS** (eye)
- Section **SUPPORT**:
  - **MEMBERSHIP SERVICES**: "Get help or ask a question" (headset)
  - **TUTORIALS** (graduation cap; cut off)
- Also documented in HC as reached from More: **Getting Started** (first-4-days checklist: Track an activity, Join a team, Analyze your Sleep Performance, View your activity details, Set up your personalized alarm, Set up your daily journal), **Notifications** ("go to the More icon… Then, go to Notifications and ensure all toggles are enabled"), track your order (upgrade orders), Year/Month review items. Exact current order UNCONFIRMED.

### 16.2 My Account [HC]
Change Password (current + new → Save); **MFA** toggle (SMS/email); **Membership** / "Membership & Billing" (Create a Family Plan / Add to Family Plan, upgrade, cancel/return flow); **Membership Extensions** (12/24 months); **Payment Method**; FSA/HSA receipts.

### 16.3 Device Settings [HC; SEEN 95–97, 107, 108]
Opened by tapping the **top-right device indicator** on Home, or More → Device Settings. Full-screen modal "**✕ DEVICE SETTINGS (i)**".
- Header block: "**CONNECTED TO**" (teal small caps) over "**WHOOP 5AG0129137 ✎**" (rename up to 15 chars), with "**LAST SYNC 09:21**" + a cloud-✓ icon at the right.
- Tabs "**STATUS | ADVANCED**" (selected underlined).
- **STATUS**: a large strap render; battery "**86 %**" + model "WHOOP 5.0" + a vertical green battery bar; then the row "♥ **BROADCAST HEART RATE** / TO COMPATIBLE APPS & DEVICES" with a toggle [HC: "Under Status, you can enable Heart Rate Broadcast and see your Battery Status"]. "Sync Now" is mentioned in HC.
- **ADVANCED** (97): rows (rounded, icon + UPPERCASE label + grey helper text) **PAIR A DEVICE** ("Pair a WHOOP to the WHOOP app. This will replace any existing WHOOP pairings."), **UNPAIR DEVICE**, **FIRMWARE CHECK** ("Check and install the latest WHOOP firmware."), **REBOOT DEVICE**, **ERASE DEVICE DATA**. Device ID and firmware version are shown here [HC]. "Update Firmware" is also mentioned.
- Pairing flow (107/108): "**CHOOSE A DEVICE**" ("Confirm the serial number on the side or top of the device.") over a strap render with the serial highlighted; a list row "WHOOP 5B00334077"; "**DON'T SEE YOUR DEVICE?**" outlined button; OS permission dialog. Failure: "**CONNECTION FAILED**" with a red ✕ between phone and strap, "To continue, put your device into pairing mode…", and a teal outlined pill "**LET'S GET STARTED**".

### 16.4 App Settings [HC; paths differ slightly by platform]
Items referenced across articles:
- **Hide Metrics** → toggles: Hide **Recovery & Sleep**, Hide **Weight & Lean Body Mass**, Hide **Healthspan** ("Heart rate data still uploads").
- **Data Export** (iOS: App Settings → Data Export; Android: More → Data Export): confirm email → "**Create Export**" → emailed CSV link within 24 h (expires in 7 days). CSVs: Physiological Cycles, Sleeps, Workouts, Journal Entries.
- **Integrations**: Apple Health at the top, then Strava, Peloton, Withings, Clue, Natural Cycles, Cronometer, TrainingPeaks, Hyperice, HealthEx ("Connect with HealthEx"); a "Connected Apps" section with a green ✓ when connected. Android: "Account & Settings > Integrations" with Health Connect.
- **Journal** (on/off).
- **Hormonal Insights** (toggle; Mode: Menstruating / Pregnancy; due date).
- **Activity Settings** → **Activity Detection** (auto-detect toggle) and **Heart Rate Settings** (iOS path More > App Settings > Activity Settings; Android More > Activity Settings). Older text: "Max HR Adjustment".
- **Notifications** (also listed directly under More in some articles).
- **AI Settings** → Coach toggle.
- **Coaching Preferences** → Coaching Mode.
- **Heart Rate Settings screen** (98/99): "< HEART RATE SETTINGS", "Heart Rate Zones" + the description "Calculated using the scientifically validated heart rate reserve formula…", fields "RESTING HR (i) 59 bpm" (read-only) and "MAX HR (i) **191** bpm" (editable), toggle "**Manual Heart Rate Zones**" + explanation, a table **ZONE | ZONE MIN | ZONE MAX** (rows Zone 5→1, each with a zone-colour gradient at the left edge and bpm input boxes), an outlined pill "**SAVE HR ZONES**" (disabled until a change) and "CANCEL".

### 16.5 Privacy Settings [HC]
**Team Invitations** toggle, **Personalized Product Recommendations** toggle, **Privacy & Data Management** (deletion requests; privacy.whoop.com "Take Control").

### 16.6 Membership Services / Support [HC]
In-app help through Coach; email request; phone (Life priority). The Device ID is printed on the sensor or under Device Settings → Advanced.

---

## 17. Profile (tap the avatar) [HC Updating-Your-Profile 10/8/2025, Max-HR; 2020 Locker]
- A performance profile: **WHOOP Levels** by recoveries logged (Beginner 0–29, Bronze 30–99, Silver 100–299, Gold 300–999, Platinum 1000–1999, Diamond 2000+), data streaks, 30-day averages, all-time highs/lows. An "**ALL TIME**" toggle shows Max HR. **Personalization** opens My Memory. Visual UNCONFIRMED (no screenshot).
- **Edit** (pencil, top-right): Email, Name, Birthday, Gender / Physiological Baseline, Location (country/state; it gates ECG/IHRN/GPS), **Units (Imperial vs Metric)**, Weight & Height → Save. Username is not editable in-app.

---

## 18. Hide Metrics and Concealed Mode [HC]
- Hide Metrics (More → App Settings → Hide Metrics) hides Recovery & Sleep, Weight/LBM, and Healthspan. Teams/organisations often enable it.
- **Concealed mode** (research and org accounts) hides vital data while keeping the More tab and functionality.

---

## 19. Units, language, formats [HC + SEEN]
- **Units**: Imperial/Metric in Profile (weight lbs/kg, height, distance mi/km, speed mph). Skin temp shows **°C or °F** (+0.1 °C in 87; -0.1 °F in 89). Strength Trainer lbs/kg follows Profile.
- **Time format** follows the device: 24 h ("22:30", "17:10") or 12 h ("10:00 PM", "6:34 AM").
- **Decimal separator** follows the locale ("4,0", "9,4 avg", "11,5").
- **Languages**: English, French, German, Latin American Spanish, European Portuguese, Italian. iOS: Settings → WHOOP → Preferred Language. German screenshot (116) labels: HEUTE, "Der Schlaf der letzten Nacht", BEARBEITEN, GESCHLAFENE STUNDEN, NORMALBEREICH, DAUER, WACH, LEICHT, SWS (TIEFSCHLAF), REM, ERHOLSAMER SCHLAF. Coach is English only.
- Durations are formatted **h:mm** ("8:10", "0:31"); zone time **h:mm:ss** with small seconds ("0:03:45").

---

## 20. Widgets and Live Activities [HC How-to-Add-the-WHOOP-iOS-Widget 4/27/2026; SEEN 18–21]
- iOS **Home Screen widget "Daily Overview"**: "Displays the current day's Recovery and Strain scores". Concentric rings (outer Strain blue, inner Recovery green) around the W puck, "87%" green bottom-left, "15.6" blue bottom-right, battery "80%" top-right. Sizes vary.
- **Lock Screen widgets**: circular battery ring with a strap icon ("20%"); individual Sleep / Strain / Recovery; charging status.
- **Live Activities / Dynamic Island**: HR, elapsed time, and distance + pace/speed when GPS is on (section 4).
- Android widgets (21): "WHOOP 80%" header, columns "68% RECOVERY" (green), "12.4 STRAIN" (blue), "89% SLEEP" (sleep blue), and a 4-tile variant with battery "70%".

---

## 21. In-app cards, banners, notifications (catalog from HC)
Morning Journal prompt · Recovery/Strain/Sleep daily notifications · evening Stress summary · Friday Weekly-Plan check-in · Monday recap · strain-target reached (haptic + push) · alarm low-battery banner · "Turn Off Your Alarm?" card · Merge Sleep card · "Process Now" (sleep wake detection) · overlapping-activity prompt · firmware update pop-up (re-prompts every 24 h) · ECG/IHRN setup cards · IHRN "Possible AFib" notification + Home "Heart Notifications" card · Health Report ready · Labs results ready · Year in Review icon (Dec) · Month in Review (email) · team invites (red dot) · "DATA CAUGHT UP" sync banner.

---

## 22. Calibration / unlock thresholds [HC Calibration-Timeline 4/23/2026]
| Where | Feature | Unlocks after |
|---|---|---|
| Home | Stress Monitor | 0 recoveries (Peak/Life) |
| Home | Coloured Recovery score | 3 |
| Home | Live HR | 0 |
| Home | Health Monitor | 0 (fully calibrated at 7; Peak/Life) |
| Home | Start/Add Activity, Strength Trainer, Journal | 0 |
| Home | Weekly Plan | 7 |
| Home | Behavior Insights | 10 (5 yes + 5 no in 90 days; full calibration 365) |
| Sleep | Performance, Hours vs Needed, Efficiency | 1 |
| Sleep | Sleep Consistency | 5 consecutive nights (HC Sleep says 3) |
| Sleep | Sleep Stress | 1 (3 for full; Peak/Life) |
| Recovery | RR, SpO₂, RHR, HRV | 1 |
| Recovery | Skin Temp | 7 |
| Strain | Day Strain | 0 |
| Strain | Steps | 0 (5.0/MG) / 1 (4.0) |
| Strain | Calories | 1 (full at 14) |
| Strain | VO₂ Max | 14 sleeps in 21 days (updates Tuesdays) |
| Health | Healthspan | 21 recoveries in 31 days, 18+ (Peak/Life; full at 90 days; updates Sundays) |
| Health | Advanced Labs | 0 (18+, US for purchase) |
| Health | Blood Pressure | 1 + cuff calibration (Life) |
| Health | ECG / IHRN | 0 (22+, region; Life + MG) |
| Health | MCI | 0 (needs last period + cycle length) |
| Health | Health Report | 14 |

---

## 23. Membership gating and reference lists

### 23.1 Tiers [HC Navigating, Membership-Features 5/27/2026]
| Feature | One | Peak | Life |
|---|---|---|---|
| Strain/Recovery/Sleep, Trends, Hormonal Insights, Steps, VO₂ Max, Strain & Sleep targets, WHOOP Live, Strength Trainer & HR Zones, AI coaching, Journal | ✓ | ✓ | ✓ |
| Health Monitor, Stress Monitor, Healthspan / Pace of Aging | – | ✓ | ✓ |
| Blood Pressure Insights, ECG (Heart Screener), IHRN, priority phone support | – | – | ✓ (MG hardware) |
WHOOP One members still get a Health tab with Live HR and opt-in Hormonal Insights. Other cards are greyed out.

### 23.2 Recovery colours and copy [HC]
Green 67–99% "primed", Yellow 34–66%, Red 1–33%.

### 23.3 HR zones (Heart Rate Reserve method) [HC; colours sampled]
Zone 0 Resting · Zone 1 Very Light **#BDD6DF / in-app #ADC0CE** · Zone 2 Light **#4FA9D2 / #44A1CA** · Zone 3 Moderate **#63CBA3 / #54BE9A** · Zone 4 Hard **#FDBF69 / #FAAC59** · Zone 5 Max Effort **#FB6F27 / #FE601F**. (First value from the help-center table graphic 06; second from the in-app HR-settings screenshot 99.)

### 23.4 Activity list
About 150 strain activities (an asterisk marks auto Muscular Strain; ^ marks Healthspan Strength Activity Time), 32 recovery activities (Acupuncture … Warm Bath, incl. "Guided Breathing - Increase Alertness/Relaxation"), and sleep activities (Nap, Sleep). The full list is in `raw/help-center-articles/List-of-WHOOP-Activities.txt`. The API sport-id table (also about 150 entries) is in the developer docs (section 24.1).

---

## 24. Developer platform (developer.whoop.com) [DEV]

### 24.1 Data model (v2 API)
- **Cycle** (physiological day, sleep-to-sleep): `id, user_id, created_at, updated_at, start, end (null while current), timezone_offset, score_state, score{strain, kilojoule, average_heart_rate, max_heart_rate}, step_count (nullable)`.
- **Recovery**: `cycle_id, sleep_id, user_id, created_at, updated_at, score_state, score{user_calibrating, recovery_score, resting_heart_rate, hrv_rmssd_milli, spo2_percentage, skin_temp_celsius}`.
- **Sleep**: `id(uuid), cycle_id, user_id, start, end, timezone_offset, nap(bool), score_state, score{stage_summary{total_in_bed_time_milli, total_awake_time_milli, total_no_data_time_milli, total_light_sleep_time_milli, total_slow_wave_sleep_time_milli, total_rem_sleep_time_milli, sleep_cycle_count, disturbance_count}, sleep_needed{baseline_milli, need_from_sleep_debt_milli, need_from_recent_strain_milli, need_from_recent_nap_milli}, respiratory_rate, sleep_performance_percentage, sleep_consistency_percentage, sleep_efficiency_percentage}`.
- **Workout**: `id, user_id, start, end, timezone_offset, sport_name, score_state, score{strain, average_heart_rate, max_heart_rate, kilojoule, percent_recorded, distance_meter, altitude_gain_meter, altitude_change_meter, zone_durations{zone_zero_milli … zone_five_milli}}, sport_id (legacy)`.
- **User**: profile `{user_id, email, first_name, last_name}`; body `{height_meter, weight_kilogram, max_heart_rate}`.
- `score_state` enum: **SCORED / PENDING_SCORE / UNSCORABLE**. Useful for "Calculating…" / "Not enough data" empty states.
- Sport table (`sport_id → name`): -1 Activity, 0 Running, 1 Cycling, 16 Baseball … 63 Walking, 96 HIIT, 123 Strength Trainer, 233 Sauna … 272 Public Speaking (full list in `raw/help-center-articles/developer-user-data_workout.txt`).

### 24.2 Brand & Design Guidelines PDF (images 40–47)
- **Logos**: "WHOOP" wordmark (primary) and the **"WHOOP Puck"** (W in a circle; app icon/favicon; a solid version is rare). Minimum widths: wordmark 100 px, puck 30 px. Exclusion zone 2x. Attribution lockups: "DATA BY WHOOP", "IMPORTED FROM WHOOP", "DATA BY ⓦ", "POWERED BY ⓦ".
- **Typography**: **Proxima Nova for words**, **DINPro for numbers**. Headlines: Proxima Nova **Bold, UPPERCASE, 10% letter spacing**. Body: Proxima Nova **Semibold**. Numbers: DINPro **Bold**. Fallbacks: platform sans-serif, Helvetica Neue, Helvetica, Arial.
- **Colours**:
  - Black #000000, White #FFFFFF.
  - **Teal #00F19F**: "call to actions, highlights, positive evaluations, and Sleep Need".
  - **Strain #0093E7**: "Activities and other Strain related topics".
  - **Recovery Blue #67AEE6**: recovery-related data without a valuation.
  - **High Recovery #16EC06** (100–67%), **Medium #FFDE00** (66–34%), **Low #FF0026** (33–0%).
  - **Sleep #7BA1BB**.
  - **Background gradient #283339 → #101518**.
- Do/Don't: don't rename WHOOP metrics (e.g. "READINESS"), don't switch focus from score to title, don't use other colours for the main scores, don't contradict WHOOP coaching, keep the logo away from data visualisations.
- Usable data icons (slide 7): Workouts (lifter), Sleep (crescent), Recovery (meditating figure), Physiological Cycle (circular arrows), Profile (person).

---

## 25. Visual language summary (for implementation)

### 25.1 Colours: sampled from a lossless in-app PNG (91) unless noted
| Element | Hex |
|---|---|
| Screen bg, top → mid → bottom | #192024 / #20292E → #14191D / #13181C → #0E1215 (brand: #283339 → #101518) |
| Primary card / row (Daily Outlook, Today's Activities) | #2B3033 |
| Metric tiles (Health/Stress Monitor, Health Monitor grid) | #2E3337 (±2) |
| Tonight's Sleep card | #292E30 |
| Inner rows & secondary buttons (activity row, ADD/START ACTIVITY) | #404447 |
| Dial track | #333A3F |
| Strain target band on the dial | #5B6164 (white tick #FFFFFF) |
| Sleep | #7BA1BB |
| Recovery green / yellow / red | #16EC06 / #FFDE00 / #FF0026 |
| Strain | #0093E7 |
| Recovery blue (neutral, LOW stress) | #67AEE6 |
| Teal positive / CTA / synced | #00F19F |
| Status badge bg: green / red / blue | #325048–#245044 / #4C2B34 / #354550 |
| ECG waveform | about #A05CE4; ECG ✓ badge #1C3831; "!" badge #362E20 with #F2AB45 |
| Primary text / secondary / tertiary | #FFFFFF / #C0C2C3 / #A0A2A3 |
| Tab bar capsule / unselected icon / label | #222A30 / #909497 / #8E9294 |
| Coach W ring gradient | #59C3FF → #8174FF |
| Action + button | #FFFFFF bg, #000000 glyph |
| Journal screen bg (vertical gradient) | #372B6D (top) → #2F265D → #1F1C39 (bottom) (sampled from 105) |
| MCI screen bg | #40295B (top) → #231D31 (about 25% down) → near-black cards (#1A1D20) (sampled from 10) |
| Pregnancy screen bg | #383B54 (top) → #111517 (sampled from 14) |
| Coach My Memory bg | #19283A (top-left, blue) / #372C60 (top-right, violet) → #232729 (sampled from 07) |

### 25.2 Typography (estimates from 3x screenshots; 414 pt-wide iPhone 8 Plus)
- Dial numbers: DIN Bold, about 26 pt (cap height about 19 pt); "%" about 16–18 pt.
- Big deep-dive ring number: DIN Bold, about 60–70 pt.
- Metric values in tiles: DIN Bold, about 32–34 pt with a 14 pt unit.
- Page section titles ("My Day", "My Dashboard"): Proxima Nova Semibold, about 22 pt, Title case.
- Card/tile headers: Proxima Nova Bold, about 11–13 pt, UPPERCASE, about 10% tracking.
- Body/subtitles: Proxima Nova Regular/Semibold, about 13–15 pt, #C0C2C3.
- Screen titles in nav bars: about 13–14 pt Bold UPPERCASE tracked, centred.

### 25.3 Geometry
Page side margin about **16 pt** (14 pt measured on some devices) · tile gutter about **12 pt** · tile/card corner radius about **10–12 pt** · inner row radius about 10 pt · status badge 24 pt square, radius about 4 pt · Action + about 28–30 pt square, radius about 8 pt · dial ring about **86 pt** diameter, **6 pt** stroke · Health/Stress tiles about 90 pt tall · Daily Outlook row about 40 pt tall · activity pill about 100×40 pt.

### 25.4 Component vocabulary
Dial ring · stacked coaching cards with ✓ count · status badge + coloured status text · rows with icon + UPPERCASE label + right-aligned DIN value + grey baseline + ▲▼ arrow · gradient-border AI cards with an UPPERCASE CTA → · hatched "typical range" tracks behind progress bars · W/M/6M segmented control · "< DATE >" pill · centred uppercase nav titles with (i) · floating capsule tab bar + W button · purple-gradient full-screen flows (Journal, MCI, Pregnancy, Coach memory).

---

## 26. Practical mapping notes for the ZENO rebuild (screen inventory)
Screens to reproduce, by tab:
- **Home**: header (avatar + streak, date pill, battery + device dot) → sync banner → WHOOP wordmark → 3 dials (Sleep/Recovery/Strain) → coaching card stack → Health Monitor | Stress Monitor tiles → My Day (+ menu; Daily Outlook row; Today's Activities card with Add/Start; Tonight's Sleep) → My Journal → My Plan → (Looking Ahead / Calibration) → My Dashboard (editable rows) → Stress graph card → Hormonal card → promos.
- **Deep dives**: Sleep (Last Night's Sleep, Hours of Sleep chart, stages, restorative), Recovery (ring, HRV/RHR/RR/Sleep Perf rows, coach card, Behavior Insights), Strain (ring, HR zones 1-3/4-5, strength time, steps, coach card, Today's Activities).
- **Trend View** (dropdown, average + delta, W/M/6M, range nav, chart, learn more).
- **Health tab**: Live HR, Health Monitor grid + Health Report, Stress Monitor (gauge + 24 h graph + breathwork), Healthspan, Heart Screener (ECG/IHRN), BP, MCI/Pregnancy, Labs, Health Records.
- **Community**: teams list, team page (INFO/CHAT/STRAIN/RECOVERY/SLEEP, Daily/Mon-Sun/Monthly).
- **More**: Shop, Gift, My Account, Digital Labs, Device Settings (Status/Advanced), App Settings (Hide Metrics, Data Export, Integrations, Journal, Hormonal, Activity/HR settings, Notifications, AI, Coaching prefs), Privacy, Membership Services, Tutorials, Getting Started, Refer a Friend.
- Modal flows: + menu, Start/Add Activity, Sleep Planner + My Schedule, Journal + calendar + behavior editor, Strength Trainer, Coach chat + My Memory, ECG flow, pairing flow.

---

## 27. Image index (`whoop-reference/images/help-center/`)
Help Center (support.whoop.com inline images):
- 01 Home "My Day": TODAY'S ACTIVITIES (sleep row, + ADD ACTIVITY / START ACTIVITY) and TONIGHT'S SLEEP (22:39 bedtime, 07:30 ALARM ON EXACT TIME).
- 02 Older Sleep Planner with the "Set your latest wake time" picker sheet and SAVE & SET ALARM.
- 03 MY SCHEDULE (CREATE SCHEDULE).
- 04 Home card "Turn Off Your Alarm?" (✓ 3 stack chip).
- 05 Journal date strip "< TODAY >" with day capsules and ✓ circles; "What's happening today?".
- 06 HR zone colour table (Zones 1–5).
- 07 Coach MY MEMORY.
- 08 Strength Trainer exercise Progress + Personal Records.
- 09 MCI Symptoms sheet.
- 10 MCI calendar with POSSIBLE SYMPTOMS TODAY.
- 11 HORMONAL INSIGHTS settings.
- 12 MCI calendar with LOG PERIOD DATA and LUTEAL PHASE COACHING.
- 13 MCI marketing phone.
- 14 PREGNANCY INSIGHTS week view.
- 15 Advanced Labs appointment accordion.
- 16 ADVANCED LABS progress steps.
- 17 "Explore WHOOP Devices" + "Discover More" list (Test with Advanced Labs, Get a WHOOP 5.0 or MG, Explore the WHOOP shop, Give the gift of WHOOP, Get Connected Care).
- 18 iOS widget gallery "Daily Overview".
- 19 iOS lock-screen widget.
- 20 iOS Live Activity (137 bpm, ZONE 3, 11.2 mi, 23.6 mph).
- 21 Android widgets.
- 22–24 Neon icons: Coach W button, email, phone.
- 25–27 Membership cards ONE / PEAK / LIFE (gradient cards with spaced wordmark).

IFU (ECG Instructions for Use, official app screenshots):
- 30–38: ECG REPORT normal sinus; possible AFib; AFib + high HR; high HR (two variants); low HR; inconclusive; Home ECG prompt card; ECG reading unsuccessful (RETRY).

Developer brand guide:
- 40–46: slides (logos, attribution do/don'ts, typography, colour palette ×2, utilizing data do/don'ts, usable data icons).
- 47: original PDF.

App Store (official renders):
- 50 Home 2026 (header, dials, "Optimal Health" card, Health/Stress tiles, My Day +, Daily Outlook, tab bar + W).
- 51 Healthspan.
- 52 Coach chat.
- 53 Journal Insights.
- 54 Stress Monitor.

Community forum (public member screenshots; dates are post dates):
- 60 Android Home with the + next to My Day highlighted (Nov 2025).
- 61 New-member Home: Get Started, Coach input, Tonight's Sleep SET ALARM, Calibration Timeline.
- 62 Scrolled Home: sticky mini-dials, Looking Ahead, My Dashboard calibrating.
- 63 iPhone 8 Plus Home, top to Today's Activities.
- 64 **Action + menu open**.
- 65 Sticky header + Today's Activities.
- 66 Home (user-annotated strain ring request).
- 67 My Dashboard tiles while calibrating + Stress card.
- 68 Home with NO SLEEP / NAP, Health Monitor "Pending".
- 69 June 2025 early-redesign Home (MY JOURNAL, My Dashboard CUSTOMIZE, floating white +).
- 70–71 Recovery deep dive.
- 72 Strain deep dive.
- 73 Strain dial close-up (target tick + grey band).
- 74 Sleep deep dive.
- 75 Sleep trends (Hours vs Needed hours/%).
- 76 Old Sleep Efficiency card (removed).
- 77 Sleep activity detail.
- 78 Last Night's Sleep with Restorative.
- 79 Sleep deep dive (stages, Restorative).
- 80 Trend View Hours vs Needed.
- 81 Trend View HRV.
- 82 Activity detail (Rowing) HR zones + Key Statistics.
- 83 Home with feature card "Exercise Trends in Strength Trainer".
- 84 Strength Trainer exercise details.
- 85 MCI Current Cycle chart.
- 86 **Current Sleep Planner** (Android).
- 87 Health Monitor (within).
- 88 Health Monitor (near).
- 89 Health Monitor (low/near, °F).
- 90 Health tab HEART RATE card.
- 91 **Lossless Home** (DATA CAUGHT UP banner, VERY ELEVATED, LOW stress, tab bar; used for colour sampling).
- 92 May 2025 Health tab (Heart Rate, locked Healthspan, Health Monitor 4/4) + email.
- 93 Healthspan locked.
- 94 **More screen** (Jul 2025, "Profile" tab variant).
- 95–96 Device Settings STATUS (Broadcast HR row hidden by the W button).
- 97 Device Settings ADVANCED.
- 98–99 Heart Rate Settings (auto / manual zones).
- 100 Heart Screener card.
- 101 Blue streak flame (1161).
- 102 Home header.
- 103 Community recovery leaderboard.
- 104 Team page strain leaderboard.
- 105 Journal month calendar + Journal header/day strip.
- 106 Today's Activities expanded HR timeline.
- 107–108 Pairing: choose device / connection failed.
- 109–110 Labs Summary / Test Results.
- 111 Coach chat (Beta V4.0).
- 112 Healthspan WHOOP Age trend.
- 113–115 Healthspan orb colour variants.
- 116 Sleep deep dive in the German locale (labels listed in section 19).

---

## 28. UNCONFIRMED items and gaps
1. **Current (2026) More root list**: the order and items above WHOOP SHOP (Refer a Friend, Getting Started, profile shortcut), and whether "Notifications" is a root item or lives inside App Settings. The only screenshot (94) is from Jul 2025, when the 4th tab was labelled "Profile".
2. **Health tab root order** in 2026 (5 widgets for Peak). No full 2026 screenshot. Live HR moved into Health Monitor for Peak/Life.
3. **Home order below Tonight's Sleep** (My Journal vs My Plan vs Calibration vs My Dashboard vs Stress card vs Hormonal vs promos). The Locker states My Day → My Plan → My Dashboard → Stress Monitor trend → Hormonal. The June 2025 build placed My Journal between Activities and Dashboard.
4. **My Plan card visual** (progress bar) and the **Plan Overview** page: no screenshot.
5. **Strain ring semantics** (white tick vs lighter-grey arc): undocumented. Likely the target and the optimal range.
6. **Stress level cut-offs** for LOW/MEDIUM/HIGH and the Health Monitor **orange** wording.
7. **Profile screen** layout (Levels, averages, Personalization): no screenshot.
8. **Community root** (teams list, recommended teams): no screenshot.
9. **Blood Pressure Insights**, **Connect Health Records**, **Advanced Labs card on Health tab**, and the **Home promo tiles**: no screenshots.
10. Exact **font sizes**: estimated from screenshots (Proxima Nova/DIN per the brand guide); confirm in-app fonts. The app may use custom cuts, e.g. the WHOOP wordmark font.
11. Streak flame colour thresholds (orange → red/blue-core → blue).
12. Whether Home's Health/Stress tiles show as upsell on WHOOP One.
