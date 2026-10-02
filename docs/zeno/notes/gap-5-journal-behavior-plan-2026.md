# Gap 5: Journal, behaviour editor, Behavior Insights / Details, Weekly Plan (2026 iOS)

Research date: 2026-10-02. Public sources only (no logins). Every image cited below is in
`whoop-reference/images/journal-plan-2026/` unless another folder is given
(`completeness-critic/…`, `help-center/…`, `reviews/…`, `appstore/…`). These images are a private
local reference and must never be copied into the git repo.

Marking rules used here:
- **SEEN**: read directly off a legible screenshot (file named).
- **STORYBOARD**: visible only in a 320×180 YouTube storyboard frame. The layout and shape are reliable; the text is **not** legible.
- **TEXT-ONLY**: stated in WHOOP copy or a user post, with no legible image.
- **UNCONFIRMED**: not seen; do not build it as fact.

Pixel maths: iPhone screenshots are 3x. 1320 px wide means a 440 pt screen; 1206/1179 px means 402/393 pt.
Colours were sampled with Pillow. JPEG noise is about ±4 per channel.

---------------------------------------------------------------------------------------------------

## 0. Sources used

| Source | What it gave | Date of UI |
|---|---|---|
| YouTube `bl0fB84Nq9M` "How to Use Your WHOOP Journal Feature (2026 UPDATE)", Mr. Whoop, published 2026-07-01, 296 s, 149 storyboard frames at 2 s | full order of Journal → editor → Insights → Details → AI sheet. `maxres1/2/3.jpg` auto-thumbnails (1280×720) are **legible** frames at about 25/50/75 % | recorded 2026-06-30, iOS, 18:29–18:33 |
| YouTube `NrCpf_m75XM` "FULL WHOOP App Walkthrough (2026 Update)", 2026-04-21, storyboard sheets M9–M10 (10 s per frame) | Journal today (sand), SELECT BEHAVIORS, Home My Journal / My Plan cards | recorded 2026-04-15 |
| Reddit r/whoop | most legible 2026 captures | 2026-01 → 2026-10-02 |
| ↳ RSS | only the `journal` query succeeded. The other 10 queries returned HTTP 429 for ~55 minutes because parallel agents were sharing the limit | — |
| ↳ Arctic Shift archive API (public) | a **complete listing of all 7,852 r/whoop posts from 2026-02-15 to 2026-10-02**, filtered locally by keyword plus image; title searches; per-thread comment search (screenshots posted in comments); gallery metadata. Images downloaded from `i.redd.it` | — |
| community.whoop.com search (journal, behavior(s), behavior insights/trends, logging history, journal voice/AI, custom behavior, weekly plan, plan overview, my plan, plan, my week recap, weekly wrap, recap, check in, insights, voice, save journal, trends) + topics 14405, 15747, 13680, 16282, 16137, 6871, 4096, 3223, 4389 | 2025 staff screenshots and 2026 text evidence | 2025-06 → 2026-09 |
| whoop.com Locker via r.jina.ai: "What's new on WHOOP" (2026-08-28), "What's Next — Spring 2026", "The WHOOP Journal" (2026-04-30), "Behavior Insights" (2026-04-30), "Weekly Plan" (2026-02-20) | feature dates and official wording | — |
| Help Center text already in `raw/help-center-articles/`: WHOOP-Journal-Overview (published 2026-09-18), Recovery-Insights (2026-03-20), Weekly-Plan (2025-08-06) | rules and copy | — |

---------------------------------------------------------------------------------------------------

## 1. Timeline: what changed in 2026 (this decides which variant to copy)

| Date | Change | Evidence |
|---|---|---|
| ≤ Jan 2026 | "RECOVERY INSIGHTS" list, opened modally ("✕"), ALL-CAPS behaviour names; or a "Recovery Impact Analysis" page with the eyebrow "REFRESHED DAILY. LAST REFRESH: JAN 16, 2026, 08:58." | 23, 24, completeness-critic/22 |
| 2026-02-16 | Weekly Plan HR Zone 4–5 goal capped at 30 min (user complaint) | TEXT-ONLY: Reddit 1r5wvn0 |
| 2026-02-20 | "Strength Activity Time" goal added to Weekly Plan | TEXT-ONLY: whats-new; SEEN in 31 ("1:30+ Strength Activity Time 2:49") |
| **2026-03-25** | **Behavior Trends + Behavior Insights.** Calendar views per behaviour ("Logging History") and a new "BEHAVIOR INSIGHTS" page. Copy: "Open your Journal or Recovery and tap Insights to start exploring." | TEXT-ONLY: whats-new; SEEN in 20, completeness-critic/20 |
| Apr 2026 | Both list styles in the wild: new (Title Case names + blue ✧ chip for auto-tracked behaviours) and old (ALL CAPS) | 20 vs 21/22 |
| 2026-04-23 | iOS 5.49.2 moved "My Plan" **above** "My Day" on Home | reviews/r68 |
| 2026-04-30 | "Journal entries by voice, smarter behavior suggestions": log via the mic in any WHOOP AI conversation; WHOOP recommends behaviours to add or remove | TEXT-ONLY: whats-new, Locker "The WHOOP Journal" |
| Jun–Aug 2026 | Home order: … My Day → Tonight's Sleep → **MY JOURNAL** card → **My Plan** → My Dashboard | STORYBOARD bl0 f0–f8, f81; SEEN 32 |
| **2026-07-29** | **"Log your Journal by voice or text"**: WHOOP AI opens **from the Journal page**. "Mention behaviors in the conversation and WHOOP logs them for you; ask to add or remove a behavior and WHOOP guides you through the update before saving it. Open the Journal manually to use voice or text entry. This is not available from the daily Journal pop-up." | TEXT-ONLY: whats-new. The "Smart log with WHOOP AI" card is SEEN legibly on **2026-06-07** (16), so some users had it earlier; also SEEN behind the sheet in 05 (Sep 12) |
| 2026-09-03 | WHOOP "Coming Next" post: Custom Journal Behaviors (Sep/Oct); "A Unified Daily Experience" (Journal + Daily Outlook + Check-ins + Day in Review in one flow); "Talk and Text to Journal" | TEXT-ONLY: Reddit 1w690hl (u/whoop_official) |
| 2026-09-11 → 09-29 | **Custom behaviours** rolled out gradually: Home promo cards, a CUSTOM BEHAVIORS tab in SELECT BEHAVIORS, a "Custom" chip on rows | SEEN 11, 12, 13, 15; Reddit 1wddizc, 1wt830x |
| ~2026-09-17/19 | The Journal no longer splits behaviours into day/evening groups ("removing the split grouping for evening behaviours"). The previous-day carry-over option is reported missing | TEXT-ONLY: forum 16282, Reddit 1witu24 |

---------------------------------------------------------------------------------------------------

## 2. (a) Journal page: everything below the date strip

### 2.1 Page chrome (for context; it agrees with WHOOP_UI_SPEC §3.17)
- Full-screen modal. Nav: "✕" (17 pt glyph spanning x≈31–47 pt, i.e. a 44 pt tap target inset 16 pt) · "JOURNAL" (caps, bold, ≈12–13 pt, wide tracking, centred) · ✎ pencil at the right. [SEEN 07, 01; help-center/105]
- Date row, today (2026-09-12): "‹ TODAY ›" centred. Day strip "Sun 6 · Mon 7 · Tue 8 · Wed 9 · Thu 10 · Fri 11 · Sat 12"; today's capsule (Sat 12) has the outline, and a small ✓ sits under days that are logged. [SEEN faintly, 05]
- **Two background themes [SEEN]:** the gradient colour depends on which day the page is about.
  - **Today** ("What's happening today, June 30?") = **warm sand → slate → near-black**. Samples from 93 (2025, 14:16) and 01 (2026-06-30, 18:31):
    `#CEB18F` (very top) → `#C2AA8E` → `#B3A18D` (title row) → `#A29988` → `#949488` → `#858681` → `#787A79` → `#647070` → `#545D64` → `#3E4B53` → `#2C353E` → `#1A1D22` → `#111518` (flat from about 36 % of the screen down).
  - **A past day / the morning prompt** ("What happened on Mon, March 16?", "What happened yesterday, August 27?") = **purple → near-black**. Samples from 07 (2026-06-03, 06:02): `#402D7C` → `#372869` → `#252048` → `#12161F` → `#101518`.
  - Sand theme seen on every capture whose title says "today": 93 (14:16), 94, 95 (11:39) (all 2025), the NrCpf storyboard (Apr 15 2026, ~14:30) and 01 (Jun 30 2026, 18:31).
  - Purple theme seen on every capture whose title (or post) says a past day: help-center/105 (Mar 16), 90/91 ("yesterday"), 08 (filling in the previous day, per the post).
  - Purple with no visible title: 07 (06:02, the morning-prompt hour), reviews/89 (12:34, 2025) and 16 (Smart log card, Jun 2026).
  - Time of day does not explain it (11:39 is sand, 12:34 is purple). The **today = sand / past day = purple** rule is **inferred**; WHOOP never states it.
  - 05 (Sep 12, "today") cannot be judged, because the navy AI sheet covers it.
- The gradient stays fixed while rows scroll over it. In 01 the scrolled rows still sit on the sand top. [SEEN 01, 07]

### 2.2 Below the date strip, top to bottom (2026)
1. **Question title**: "What's happening today, June 30?" / "What's happening today, September 12?" (white, ≈28 pt semibold, 2 lines, left-aligned at 16 pt). [SEEN 93; STORYBOARD 40/43 (2 lines)]
   - In 05 (2026-09-12) the title looks like **one line across the full width**, i.e. smaller type (about 18–20 pt equivalent). That would mean a Sep 2026 restyle, but it is seen only through the sheet overlay. **UNCONFIRMED.**
   - Past day: "What happened on Mon, March 16?" [SEEN help-center/105]; morning prompt: "What happened yesterday, August 27?" [SEEN 90 (2025)].
2. **WHOOP AI entry card: "Smart log with WHOOP AI"**. [SEEN legibly in **16** (2026-06-07, 1179 px = 393 pt, measured); SEEN through the AI sheet in 05 (2026-09-12)]
   - It sits **above the behaviour rows**. A user complains: "It's annoying to have to scroll down further to put my journal answers in because of this pop-up" (Reddit 1tziq59). They found no setting to hide it.
   - It was already live for some users on 2026-06-07, before the Jul 29 "What's new" entry. That entry also says it is "not available from the daily Journal pop-up".
   - Card:
     - x 16 → 377 pt (16 pt margins), **≈108 pt tall**, **corner radius ≈20 pt**.
     - **1 pt gradient border** in violet `#4A427E`–`#4F4782`.
     - **Fill**: horizontal gradient, indigo `#282C48` (left) → `#243444` (mid) → teal `#203844` (right).
   - Row 1: **three-star sparkle icon** (≈18 pt, blue-violet gradient, average `#68B0FC`), then **"Smart log with WHOOP AI"** (white, ≈20 pt semibold).
   - Row 2: two equal buttons, each ≈160 × 40 pt, radius ≈12 pt, gap ≈8 pt:
     - **"⌨ TEXT"**: fill `#3C4058`, 1 pt lighter grey border, white keyboard icon, white bold caps ≈15 pt, tracked.
     - **"🎙 TALK"**: fill gradient `#344060` → `#2C5064`, 1 pt violet border, **blue mic icon `#6BADFE`**, white bold caps.
   - Under the card, centred grey caption **"Your answers are saved automatically"** (≈16 pt, ≈28 pt below the card).
   - The page behind it in 16 is purple-navy `#1C1C38` → `#10141C` (purple theme; whether that day is today or a past day is unknown).
   - The same component (sparkle + TEXT / TALK) is the "Create Custom Behaviors" card in SELECT BEHAVIORS (13).
   - Tap → the WHOOP AI bottom sheet over the Journal (§2.6).
3. **Plan section** (only while a Weekly Plan with behaviour goals is active). [SEEN 05 enhanced, 2026-09-12; SEEN 90/91 (2025)]
   - Section label with a hairline running to the right: "YOUR CUSTOM PLAN" (2026) / "YOUR BOOST FITNESS PLAN" (2025). Caps, ≈11 pt, letter-spaced, white 50 %.
   - One card per plan behaviour. On the left, a small **progress ring with "x/y" inside** ("0/5", "0/4", "1/4"); the arc is green on a grey track (anti-aliased average `#0BC889` in 91; the plan rings elsewhere sample `#0CE8A0`). Then the question, then ✕ ✓.
   - 2026 rows (05): "0/5 Avoided AD(H)D Medication?", "0/5 Avoided Alcohol?", "0/5 Avoided Late Meal?", "0/7 Avoided Nicotine?".
   - On the Nicotine row **✕ is selected**, and its follow-up **"When was your last dose?"** shows. So follow-ups can hang off "No" when the question is phrased as "Avoided …?". Partly legible.
4. **Behaviour rows**: every behaviour is its **own rounded card** in 2026. The 2025 style used hairline rows (reviews/89, 93). [SEEN 01, 07, 08]
   - Card: inset 16 pt left and right, **height ≈64 pt** (one-line question), **gap ≈12 pt**, **corner radius ≈12 pt**.
   - Card fill = translucent white over the gradient: `#443A6C` on the purple top, `#303143` mid, `#282C2F` on the near-black bottom (07). On the sand page the cards read `#A6A297` over `#9F998B` (01).
   - Question: white, ≈15 pt medium, left-aligned 16 pt inside the card. The text is phrased as a question ("Took electrolyte supplements?", "Used an inversion table?", "Viewed a screen device in bed?", "Wore mouth tape while sleeping?").
   - Right side: **✕ and ✓ toggles**, each a **32 × 32 pt square, radius ≈6 pt, 7–8 pt apart, ≈15 pt from the card's right edge**. [measured in 07]
     - Unselected: translucent grey (`#3D4144` on a dark card; `#594F81` on a purple card) with a white glyph.
     - **✕ selected = white `#FFFFFF` fill + black ✕.**
     - **✓ selected = blue `#67ADE8` fill + dark (near-black) ✓.**
   - **Order**: in 07 (Jun 2026), ten consecutive rows are **alphabetical by question text** ("Experienced excessive gas?" → "Felt socially fulfilled?"), apparently within one section, with no header between them. [SEEN]
5. **Sections DAYTIME / NIGHTTIME** (caps label + hairline, white 50 %). [SEEN 01 ("NIGHTTIME", Jun 30 2026); SEEN 93 (2025); STORYBOARD bl0]
   - Removed around mid-Sep 2026 according to forum 16282: "removing the split grouping for evening behaviours… I now need to scroll back and forth". There is no post-September image without the headers, so the exact replacement is **UNCONFIRMED**.
   - **STATUS section** (after NIGHTTIME): caps label "STATUS" + hairline `#303438`. Rows: "Feeling sick or ill?", "Have an injury or wound?", "Took a vacation day?". [SEEN 95 (staff screenshot, 2025-07-21, today/sand); STORYBOARD NrCpf f89/f98 (2026-04-15) shows a third section with "Feeling sick or ill?" (✓ selected) below NIGHTTIME]
   - Section order up to Sep 2026: (plan section) → DAYTIME → NIGHTTIME → STATUS → NOTES → SAVE. A section appears only when it has selected behaviours; in 01 (Jun 2026) NIGHTTIME is followed directly by NOTES.
6. **Follow-up controls** (appear inside the same card under a hairline once ✓ is chosen). [SEEN 08 (2026-08-28), 90/91, reviews/89]
   - Quantity row: label "For how long (minutes)?" (white ≈15 pt, indented ≈16 pt more than the question) with a right-aligned **value capsule**.
     - Empty: "-- Minutes" / "-- grams" / "-- mins" on translucent grey.
     - Filled: **blue `#78ACE0` fill with black bold "15 Minutes"**, rounded ≈8 pt (a rounded rectangle, not a full capsule).
     - On a purple card (08): card `#383458`, idle ✕ `#504C6C`, selected ✓ `#78ACE0`.
   - Time row: "When did you stop?" / "When did this occur?" / "When did your last session end?", with the value right-aligned in **blue** ("18:00"), or "--" when empty.
   - Under it a **slider**: 4 pt track, blue filled part `#70A8D8` left of the knob, grey `#6C6C78` remainder, **white round knob `#FCFCFC` ≈28 pt**.
   - The plan-behaviour variant asks "How many grams?" with "-- grams". [SEEN 91]
7. **NOTES**: label "NOTES" (caps, white 50 %), then a **multi-line field "Add a note..."** (placeholder 50 % white). [SEEN 01 (2026-06-30), 95 (2025)]
   - The field is **darker than the page** (`#080C10`–`#090F0F` on `#101418`) with a **1 pt border `#202428`**.
   - Full width minus 16 pt, radius ≈8 pt, ≈56–64 pt tall.
8. **"SAVE JOURNAL"** (pinned to the bottom, content fades out above it): **white `#F9F9F9` capsule, ≈48 pt tall, ≈23–24 pt side margins**, black bold caps ≈14 pt. It sits ≈5 pt above the home-indicator safe area. [measured in 07]

### 2.3 Morning-prompt-only control (2025; removal in 2026 suspected)
- Below the title, a **"USE PREVIOUS ANSWERS" toggle** (iOS switch, caps label ≈12 pt, plus a "?" info circle). [SEEN 90/91, Aug 2025]
- A WHOOP staff member said it only appears in the morning prompt, not when journalling the current day (forum 6871).
- A 2026-09-17 Reddit post asks "Did whoop remove the option to carry over your responses…" (1witu24). Present state **UNCONFIRMED**.

### 2.4 The INSIGHTS entry inside the Journal
- 2025: a right-aligned outlined pill "☀ INSIGHTS" on the date row, next to "‹ TODAY ›". [SEEN 93]
- In the 2026 storyboard frames the date row shows only "‹ TODAY". Nothing legible sits on the right, and the INSIGHTS pill is not visible.
- WHOOP's Mar 2026 text still says "Open your Journal … and tap Insights". Where that entry sits in 2026 is **UNCONFIRMED**.

### 2.5 Journal states
- **Dismiss confirmation** (tap ✕ with unsaved answers). [STORYBOARD bl0 f76, 2026-06-30]
  - Centred dark card (radius ≈12 pt) with a small "✕" at the top right.
  - Caps title on one line (probably "DISMISS JOURNAL?", **UNCONFIRMED** wording) and a 3-line grey body.
  - A **checkbox row** (rounded square + 2-line label, probably "don't show this again", UNCONFIRMED).
  - A **white filled capsule** (primary) and a **caps text button** below it (secondary).
- **Save failed** [SEEN 09, 2026-09-20]:
  - Red outlined circle (≈66 pt, 2 pt stroke, `#E83038`) with a red "!".
  - **"YOUR ENTRY WAS NOT SAVED"** (white caps, bold, ≈16 pt) and "Check your network connection and try again." (grey ≈15 pt).
  - **"RETRY"** outlined capsule (2 pt white border, ≈48 pt tall) and a **"CLOSE"** caps text button.
  - Background: the dark gradient `#20242C` (top) → `#101418` (bottom).
- **Load failed** [SEEN 10, 2026-09-01]:
  - "✕" at the top left; centred cloud-with-slash outline icon; **"ERROR"** (white caps ≈13 pt bold); "Please check your internet and try again." (grey, 2 lines centred).
  - Plain dark gradient; no gradient theme.
- **Calendar** (from the date row; Apr 2026; already in the spec): green numbers with dots, "• Journal filled out". [help-center/105]

### 2.6 WHOOP AI sheet opened from the Journal (Talk / Text)
[SEEN 04, 06 (2026-09-12, "V6.0"); SEEN 27 ("v6.1"); TEXT whats-new]
- Bottom sheet over the Journal; the Journal stays faintly visible behind it (that is how 05 was recovered).
- Sheet: rounded top corners; dark navy-to-black gradient (`#1C2438` at the top → `#04080C` at the bottom).
- Header row: a **round W logo + "V6.0" capsule** (`#28284C`–`#343454`) at the left; a **grabber** in the centre (≈36 × 5 pt, white 50 %); **"Memory 💡✦"** (text + lightbulb-with-sparkle icon) at the right.
- User messages: right-aligned slate bubbles (`#343850`, radius ≈16 pt, white ≈17 pt text).
- **AI action receipts** above an AI reply, as one grey line: **"✧ Logged Nicotine from Aug 28 through Today"**, **"✧ Updated Nicotine for Aug 27"** (light-blue ✧ + light-grey semibold ≈15 pt text). This is how journal writes are confirmed.
- AI text: white ≈17 pt, left-aligned, no bubble. Below each reply: clipboard (copy), 👍 and 👎 icons (grey outline).
- Suggested replies: horizontally scrolling **white `#FCFCFC` filled capsules with black text** ("Yes, please guide me through the comparison", "Show my…").
- Input bar: a "+" square button (≈44 pt, fill `#2C2C2C`) at the left; a field **"Ask a question …"** (fill `#101828`) with a **mic icon** inside at the right (radius ≈14 pt, a thin lighter blue-violet border, visible but too thin to sample).
- Behaviour SEEN in the user posts: the AI can set yes/no for single past days, but answered "I can't bulk-edit that far back" / "the journal API is hard-blocking me from flipping that many past days at once".

### 2.7 AI behaviour suggestions
- TEXT-ONLY (Apr 30 2026): "WHOOP also recommends behaviors to add or remove based on what you're logging, how often, and how it connects to your data." A user reports a "prompt asking if I wanted to create some custom journal behaviors based upon some medicine that I take" (Reddit 1wl4yjk, 2026-09-20).
- No screenshot found. Placement and wording are **UNCONFIRMED**.
- The only SEEN suggestion-like surfaces are the Home promo cards in §2.8.
- One outcome is SEEN: a user wrote "Whoop suggested I add a rest day option to my journal". The result was the "Rest Day" behaviour with its own Behavior Details page (26a, 2026-04-02).
- WHOOP's reply in that thread: "It's not saying rest days are bad, it's just picking up patterns in your data… correlation, not causation."

### 2.8 Home promo cards for custom behaviours (Sep 2026) [SEEN 11, 12, 15]
- Placement: card directly **under the three dials** on Home (15).
- Border: **1.5–2 pt gradient border, violet `#7C64EC` (left) → `#909CDC` (top middle) → sky blue `#88CCE4` (right)**; fill `#202424`; radius ≈16 pt.
- Copy, variant A: "**You Asked, We Delivered**" (white ≈20 pt semibold) / "Custom Journal behaviors are here. Create and log new behaviors to make your Journal even more personal." (grey ≈17 pt).
- Copy, variant B: "**Create your own Journal behaviors**" / "Share what you want to track, and WHOOP will create a custom behavior for you."
- CTA "**CREATE NOW →**" in caps, gradient-filled text violet → blue.
- Art: a 3-D grey notebook with a W emboss, a blue "+" badge and blue sparkles, on the right.
- Top-right: a **small vertical pill** (grey `#34383C`) with an icon over a number ("◜ 3" in 11/12, "✓ 4" in 15). A second card peeks out below the card in 15, so this is a stacked card deck. The pill's exact meaning is **UNCONFIRMED** (it looks like a stack counter or "done" marker).

---------------------------------------------------------------------------------------------------

## 3. (b) Behaviour editor: "SELECT BEHAVIORS"

Entry: the Journal ✎ (pencil) [STORYBOARD bl0 f42–f44 slides up from the bottom], or "+ ADD BEHAVIORS" in the plan's Behavior Goal editor (§6.4).

**Layout, top to bottom** [SEEN 02 (2026-06-30), 13 + 14 (2026-09-18), 92 (2025 staff)]
1. **Sheet**: full-height card sheet with a grabber (≈36 × 5 pt) at the top. Sheet gradient `#283840` (top, teal-slate) → `#182028` (lower). The page behind shows at the very top (02).
2. Header: **"✕"** at the left (14) · **"SELECT BEHAVIORS"** centred (white caps bold ≈13 pt, tracked). 13 has no ✕, only the grabber; it was probably opened from the plan editor (UNCONFIRMED).
3. **Search field**: "🔍 Search for Behaviors", full width minus 16 pt, ≈44 pt tall, radius ≈10 pt, **fill darker than the sheet `#10181C`**, placeholder grey.
   - Help-center: exact match → fuzzy ("Hydrtion" → Hydration) → synonym ("Coffee" → Caffeine, "Beer" → Alcohol).
4. **Category tabs**: a horizontal, scrolling row of caps labels (≈11 pt bold, grey). The selected tab is white with a **2 pt white underline** under the label width.
   - 2026-06/09 order: **ALL · DRUGS & MEDICATION · HEALTH & SYMPTOMS · HO(RMONAL HEALTH)…** (02, 14, 92).
   - With custom behaviours on: **ALL · CUSTOM BEHAVIORS · DRUGS & MEDIC…** (13). The CUSTOM BEHAVIORS tab sits second.
   - Full category list (help-center): Drugs & Medication, Health & Symptoms, Hormonal Health, Lifestyle, Mental Wellbeing, Nutrition, Recovery, Sleep & Circadian Health, Supplements.
5. **CUSTOM BEHAVIORS tab only: "Create Custom Behaviors" card** [SEEN 13]
   - ✧ sparkle (light blue) + "Create Custom Behaviors" (white ≈17 pt).
   - Two equal buttons: **"⌨ TEXT"** (slate `#444C64`) and **"🎙 TALK"** (blue-teal `#2C5064`); radius ≈8 pt, ≈40 pt tall, caps labels.
   - Card radius ≈12 pt; gradient fill indigo `#343854` → teal `#283C4C`.
   - Per the Help Center, creating a behaviour is a WHOOP AI conversation. The AI proposes the name, unit and daily question, and you confirm with **"Add"**. The AI flow itself is **UNCONFIRMED** visually.
6. Section label **"CURRENTLY SELECTED"** (caps ≈11 pt, white 45 %, hairline to the right). Below it, the selected rows:
   - Row: **title** (white ≈16 pt regular, e.g. "Device (e.g. Phone) In Bed", "Electrolytes") and, under it, the **journal question** in grey ≈13 pt ("Viewed a screen device in bed?").
   - Right: a **checkbox, 24 pt rounded square (radius ≈4 pt), filled blue `#64ACE4` with a dark ✓**.
   - Rows are separated by space only (≈52 pt pitch), with no hairlines.
   - Apple Health pre-fill rows add a third line: "⚭ Pre-filling compatible via Apple Health. ⓘ" (92, 2025).
   - Custom rows carry a **"Custom" outlined chip** (1 pt grey border `#373E44`, grey text, radius ≈6 pt) left of the checkbox. Custom rows keep the user's language ("Batido de proteína / ¿Tomaste un batido de proteína?") (13).
7. Section label **"NOT SELECTED"**, then unselected rows in alphabetical order with an **empty checkbox (1.5 pt white outline)** ("AD(H)D Medication / Took AD(H)D medication?", "AG1 - Foundational Nutritional Supplement / Did you drink AG1?", "Accutane / Took Accutane?"). [SEEN 14]
8. **"SAVE BEHAVIORS"**, pinned at the bottom:
   - 2026-06-30: **outlined capsule** (1.5 pt white border, transparent, white caps), ≈44 pt tall, ≈60 % of the width, centred. [SEEN 02; also 92 in 2025]
   - 2026-09-18: **white filled capsule, full width minus 16 pt, black caps** (13, 14).
   - The September version is the newest.

Behaviour count: Help Center says "160+" behaviours; the Locker says "300+". The NrCpf (Apr 2026) storyboard shows different tab labels that cannot be read.

---------------------------------------------------------------------------------------------------

## 4. (c) Behavior Insights page states and Behavior Trends

Entry points:
- Home **MY JOURNAL** card → full-width "💡 BEHAVIOR INSIGHTS" button. [SEEN reviews/r113 (2026-07-28); STORYBOARD bl0 f0–f8, f81]
  - Card `#34383C` with "MY JOURNAL ›" (grey caps).
  - A 7-column row "WED THU FRI SAT SUN MON TUE" (grey caps; today white). Under each day, a 28 pt circle: logged = green `#64F3A6` filled with a black ✓; today, not yet logged = grey `#707478` filled with a 2 pt white ring.
  - A full-width button `#484C50` (radius ≈10 pt) with a lightbulb icon and "BEHAVIOR INSIGHTS" (white caps).
- The Recovery deep dive coach card link **"EXPLORE YOUR RECOVERY INSIGHTS →"** (caps, violet-blue) [SEEN 25, 2026-04-21].
- WHOOP AI.
- From Home it pushes a page with a centred circular spinner first [STORYBOARD bl0 f82].

### 4.1 State A, unlocked list (2026 design) [SEEN 20 (2026-04-11); STORYBOARD bl0 f83–f106 (2026-06-30)]
1. Nav: "‹" + **"BEHAVIOR INSIGHTS"** (caps, centred). The page background is a slate gradient (`#242830` at the top).
2. **"Recovery Impact Analysis"**: white, ≈22 pt semibold, left 16 pt.
3. Body: "See how behaviors impacted your Recovery over the past 90 days. Tap on a behavior to view more details." (grey `#9A9FA3`, ≈15 pt, 3 lines).
4. **Legend row**:
   - Left: an **orange-tint square chip `#3C3424` with ▼**, then "HURTS" in orange `#EDB157`.
   - Centre: "% IMPACT" in white caps.
   - Right: "HELPS" in green `#05F7A7`, then a **green-tint chip `#184038` with ▲**.
   - All ≈11 pt bold caps.
5. **Behaviour cards** (fill `#303438`, radius ≈12 pt, 16 pt side insets, ≈8 pt gap, ≈68 pt tall):
   - Line 1: **name in Title Case** (white ≈16 pt, e.g. "82%+ Sleep Performance", "Sleep In Own Bed", "9%+ of the Day in High Stress Zone", "Consistent Wake Time").
   - **Auto-tracked behaviours** (metric thresholds, stress, workout timing) get a **small blue-grey square chip `#344048` with a light-blue ✧ sparkle `#85B0D5`** after the name. A Reddit commenter explains it "means that they are tracked automatically" (1sihvyt).
   - A **"›" chevron** (grey `#A1A4A8`) at the top right.
   - Line 2: a **diverging bar**: hatched track (diagonal stripes `#44484C` on `#303438`) with a centre marker (black dot with a white core). The coloured segment runs right (green `#00F0A0`) for "helps" and left (orange `#FCA420`) for "hurts". A non-significant segment is grey `#949498`.
   - The value sits at the right, ≈17 pt bold: "+8%" green, "+2%" grey `#A0A3A6`, "-3%" orange `#F3B04A`.
   - Sort: most positive first, then non-significant, then most negative last.
   - Example order (20): 82%+ Sleep Performance +8%, Sleep In Own Bed +6%, Caffeine +2% (grey), 9%+ of the Day in High Stress Zone +2% (grey), Consistent Wake Time −2% (grey), Stress −3%, Herbal Tea −5%.
   - Example order (bl0 storyboard): Mouth Tape, 85%+ Sleep Performance, Consistent Bed Time, Meditation?, Early Workout, Consistent Wake Time, Late Workout, then the orange ones (7+ Strain?, 5%+ of the Day in High Stress Zone).
6. A blue square **"!" chip** sometimes sits left of the chevron ("Early Workout" in completeness-critic/21). Its meaning is **UNCONFIRMED**.

### 4.2 State B, unlocked + "KEEP LOGGING TO UNLOCK" [SEEN completeness-critic/21 (2026-08-19, scrolled); STORYBOARD bl0 f108–f122]
- After the unlocked cards: section header **"KEEP LOGGING TO UNLOCK"** (white caps ≈13 pt bold, tracked) and body "Record at least 5 yes's and no's in your journal to see how behaviors impact your Recovery." (grey ≈15 pt).
- **Locked cards are outlined, not filled**: 1 pt grey border, transparent fill, radius ≈12 pt.
  - Title (white ≈16 pt) + "›".
  - Grey subtitle "Unable to identify a significant impact. Please keep logging responses."
  - A flat hatched track with only the centre dot.
  - At the right, **two count badges**: "☒ 51" and "☑ 18". These are small outlined squares (✕ and ✓) followed by the count. The ✕ badge dims when its count is 0 ("☒ 0 ☑ 29").
  - In the bl0 storyboard, locked rows show only the title, track and badges, with no subtitle.
- **End of the list** [STORYBOARD bl0 f122]: one wider card with a title (2 lines, probably "Explore more behaviors" — **UNCONFIRMED**), 3 grey lines of body, a short link line, and the **3-D notebook illustration** at the right. It most likely opens SELECT BEHAVIORS (UNCONFIRMED).

### 4.2b Full-page order and locked-row variants [SEEN 20a, German UI, 2026-06-27]
- One unscrolled screenshot shows the whole order:
  - nav "‹ VERHALTENSEINBLICKE";
  - title "Analyse der Auswirkungen auf die Erholung" (Recovery Impact Analysis) and body;
  - legend "▼ SCHADET · % AUSWIRKUNG · HILFT ▲";
  - **one unlocked card** ("Ohrstöpsel" = Earplugs, +5 % green);
  - then **"WEITER DATEN ZUM FREISCHALTEN ERFASSEN"** (= KEEP LOGGING TO UNLOCK) with its body;
  - then the outlined locked cards.
  - So the header + legend block stays even when only one behaviour is unlocked.
- Locked cards come in **three variants**:
  1. Subtitle "Es wurden keine signifikante Auswirkung festgestellt. Bitte trage weiter Antworten ein." (= "Unable to identify a significant impact. Please keep logging responses.", the English seen in completeness-critic/21).
  2. Subtitle "Das Vertrauen in die berechneten Auswirkungen ist zu gering. Bitte trage weiter Antworten ein." (≈ "Confidence in the calculated impact is too low. Please keep logging responses."; English wording **UNCONFIRMED**).
  3. **No subtitle**: only the title, the track and the counters, e.g. "Auto- Oder Zugreisen ✕ 11 ✓ 0", "Ballaststoffe ✕ 2 ✓ 9", "Beziehungsstress ✕ 7 ✓ 4".
- **Count badges**: the badge for the side with few answers (0, 2, 4 here) is dimmed. In completeness-critic/21 a row with ✕ 0 still showed subtitle 1, so subtitle choice does not depend only on the counts.

### 4.3 State C, nothing unlocked yet
- From the rules: unlock needs ≥5 "yes" and ≥5 "no" for a behaviour within 90 days, on days that also have a Recovery.
- Presumably only the "KEEP LOGGING TO UNLOCK" section shows; the header block in that case is **UNCONFIRMED**.
- In completeness-critic/21 (Reddit 1vsytla) every journal behaviour was still locked; only two auto-tracked behaviours were unlocked. The user asked why "nothing" was showing. That makes it the closest SEEN example of this state.

### 4.4 Older variants still in circulation (do not copy, but useful for fallbacks)
- **"✕ RECOVERY INSIGHTS"** modal list with ALL-CAPS names, the same bar component, no legend (23; Jan 2026).
- **"REFRESHED DAILY. LAST REFRESH: JAN 16, 2026, 08:58."** eyebrow (caps grey ≈11 pt) above "Recovery Impact Analysis", with ALL-CAPS cards (24).
- **2026-03-28 capture (24a)**: nav "‹ RECOVERY INSIGHTS" + "REFRESHED DAILY. LAST REFRESH: MAR 22, 2026, 10:17." + "Recovery Impact Analysis" + legend + ALL-CAPS cards (BACK PAIN +5 %, 83%+ SLEEP PERFORMANCE −1 %, 6+ STRAIN −3 %, 4%+ OF THE DAY IN HIGH STRESS ZONE −5 %).
  - This was still the pre-update page three days after the Mar 25 announcement, so the rollout was gradual.
- **"‹ BEHAVIOR INSIGHTS"** with ALL-CAPS names and chevrons (21, 22; Apr 17 2026), e.g. LSD +5 %, MAGNESIUM +4 %, … L-THEANINE −7 %.

### 4.5 "Behavior Trends" (Mar 2026)
- WHOOP's wording: "Calendar views show when and how often you log each behavior, making it easy to spot consistency, streaks, and gaps."
- The Locker adds: "See your Journal Trends… Insights surface automatically from WHOOP AI based on your logging history".
- The only calendar SEEN is the **Logging History** block inside Behavior Details:
  - SEEN completeness-critic/20 (2026-05-04), cropped.
  - STORYBOARD inside the "Mouth Tape" details, bl0 f93–f100.
  - Described in §5.1, item 5.
- **No separate "Behavior Trends" screen, tab or Home card was found.** It may be just this calendar, or an AI-surfaced insight card. **UNCONFIRMED.**
- The help-center wording ("The Logging History is a 3-month calendar view found in Behavior Insights") supports reading it as the calendar.

---------------------------------------------------------------------------------------------------

## 5. (d) Behaviour detail page ("BEHAVIOR DETAILS"): the top part

[SEEN 26 "Late Workout" (2026-09-25); SEEN 28 "Alcohol" (2026-09-13); SEEN 29 "Caffeine" (2026-05-05); STORYBOARD "Mouth Tape" (bl0 f93–f100, 2026-06-30)]

### 5.1 Top to bottom
1. **Nav**: back control + **"BEHAVIOR DETAILS"** (white caps bold ≈13 pt, tracked), floating over the photo.
   - 26 shows **"✕"** (modal; probably opened from WHOOP AI or a push).
   - The storyboard (pushed from the insights list) shows **"‹"**.
2. **Hero photo** behind the top ≈35–40 % of the page: a stock photo of the behaviour (woman running at dusk, cocktail, coffee beans, mouth tape).
   - A dark gradient overlay fades it into the page background **`#101418`**. The photo is full-bleed and also sits under the status bar.
3. **Behaviour name**: white, **≈26–28 pt semibold**, left 16 pt, over the photo ("Late Workout", "Alcohol", "Caffeine", "Mouth Tape").
4. **Impact card** (translucent dark over the photo: `#443C34` sampled where the photo is warm; radius ≈14 pt; inset 16 pt; internal padding ≈20 pt):
   - Row: **"RECOVERY IMPACT"** (white caps bold ≈13 pt, tracked) at the left. At the right, a **verdict chip**:
     - **"Negative"**: amber-tint fill `#544430`–`#584830`, text `#EAB977`, ≈13 pt semibold, radius ≈6 pt.
     - **"Positive"**: green-tint fill, green text.
     - The Help Center says the scale runs "from significant negative to significant positive", so other wordings are likely (UNCONFIRMED).
   - When the behaviour has follow-up questions, a **"⌃ / ⌄" chevron** follows the chip and expands the breakdown (28, 29).
   - **Bar**: the same diverging hatched bar as the list, but wider. The value sits at the right, larger (**≈30 pt bold**, "%" smaller): "-6%" / "-7%" orange `#F0AC44`, "+6%" green.
   - **WHOOP member average tick**: a thin **white vertical line** on the bar at the member-average position. It sits inside the orange segment at −2 % (26), at the far left at −13 % (28), and just right of centre at +1 % (29).
   - Caption: **"WHOOP MEMBER AVERAGE: -2%"** (caps ≈13 pt, white 75 % `#C8C9CD`, tracked).
   - **Expanded breakdown** (inner card, darker `#14181C` inside an outer card of `#202428` where the photo is dark, radius ≈12 pt), one block per follow-up question [SEEN 28, 29]:
     - Question header in grey caps ≈13 pt: "HOW MANY ALCOHOLIC DRINKS DID YOU HAVE?", "WHEN WAS YOUR LAST DRINK?", "HOW MANY SERVINGS OF CAFFEINE DID YOU HAVE?", "WHEN WAS YOUR LAST SERVING?".
     - Rows: bucket label (white ≈17 pt: "1 Drinks", "2-6 Drinks", "0-2 Hours before bed", "3-6 Hours before bed", "1-2 Servings", "3-5 Servings", "2-8 Hours before bed", "9-17 Hours before bed") and a right-aligned value (orange "-6%", green "+5%", grey "-1%" / "0%" when not significant).
5. **Logging History** for journal behaviours only. "Late Workout" (auto-tracked) jumps straight to step 6. [SEEN completeness-critic/20; STORYBOARD bl0 f94]
   - "Logging History": white ≈26 pt semibold.
   - Pager: "‹  MAR '26 - MAY '26  ›" (white caps bold ≈15 pt; "›" disabled grey at the latest range).
   - **Three month blocks side by side**:
     - Month label ("MAR", grey caps) with a **"✓ 10" chip** at the right (fill `#202C34`, blue ✓ and number) = yes-count that month.
     - Weekday header "S M T W T F S" (grey caps).
     - Day dots ≈10 pt: **blue `#78ACE0` = Yes**, **grey `#88888C` = No**, **empty ring = Missing** (future days included); **today = white ring with a thicker outline**. Page background `#101418`.
   - Legend: "● Yes (15)  ● No (49)  ○ Missing (28)" (white label, grey count in brackets).
6. **"Impact of {Behaviour}"**: white ≈22 pt semibold. Then 2–4 paragraphs of grey body text (`#C5C6CA`, ≈15 pt, ≈21 pt line height) explaining the science.
   - 26 copy (legible): "A late workout is defined as exercising within the 3 hours before bedtime. This can help lower stress, boost endorphins, and maximize performance. Research suggests your body may be most primed to take on training from 4:00-8:00 pm." …
7. **"RECOMMENDATION"** box:
   - Card `#202C34` (blue-grey tint), radius ≈12 pt.
   - Header: a lightbulb icon (rays) and "RECOMMENDATION" in **blue caps `#8EB4DF`**, ≈15 pt bold.
   - Body text below (not visible in 26; STORYBOARD shows 5–6 lines).
8. Anything below the Recommendation box is **UNCONFIRMED**.

### 5.2 Variant: no photo + "You" marker + logged-count card [SEEN 26a, 2026-04-02, "Rest Day", a behaviour WHOOP suggested]
- "✕" · "BEHAVIOR DETAILS".
- **No hero photo.** Instead, a **large faint W-in-a-circle watermark** (ring `#1C2024` on a `#101418`-ish dark background) sits behind the title. This looks like the fallback for behaviours without artwork (assumed).
- Title "Rest Day" (white ≈28 pt semibold).
- Row: a **"NEGATIVE IMPACT" chip** (amber caps `#F7AB41` on `#302C1C`, ≈13 pt bold, tracked) on the left; **"-3%"** (orange `#FAAC3B`, ≈30 pt bold, "%" smaller) on the right.
- Sentence (grey ≈17 pt): **"After accounting for other influences, this behavior has a -3% impact on your Recovery."**
- Legend row: "▼ HURTS" (orange + amber chip) · **"RECOVERY IMPACT"** (white caps, centred) · "HELPS ▲" (grey `#94979A` + grey chip `#242828`). The side that does not apply is dimmed.
- **"You"** label (orange) above a **white-ringed marker** at −3 %. An orange segment runs from it to the black centre dot on the hatched track.
- **Logged-count card** (`#1C2020`, radius ≈12 pt):
  - the question "Took a rest day?" (white ≈17 pt);
  - "# of times this behavior has been logged yes or no in the past 90 days" (grey ≈15 pt);
  - at the right, two columns: a **✕ glyph over a white-outlined rounded square "5"** and a **blue ✓ (`#73AFEC`) over a blue-outlined (`#76AFE4`) rounded square "11"**. Squares ≈26 pt, radius ≈6 pt.
- Compared with the Sep 2026 captures (26/28/29), those have a photo, an impact card with a "Negative" / "Positive" chip, and a member-average tick. Which is current for every behaviour is **UNCONFIRMED**; both are 2026.

---------------------------------------------------------------------------------------------------

## 6. (e) Weekly Plan screens

### 6.1 Home "My Plan" card (entry)
- **Empty state** (no active plan) [SEEN reviews/r113, 2026-07-28]:
  - "My Plan" title, then a card `#303438`.
  - Copy: "Build Your Best Self" (white ≈20 pt) / "Set goals, track progress, and turn small actions into long-term wins." (grey) / "EXPLORE PLANS →" (blue caps `#78AAE4`).
  - Art: three circular icon badges (moon, heart, lifter) with green dashed progress rings, on the right.
- **Collapsed** [SEEN 32 (2026-08-05); reviews/r68 (2026-04-23)]:
  - Section title "My Plan" (≈26 pt semibold, like "My Day").
  - Card (fill `#2C3034` on a `#181820` page, radius ≈14 pt) showing:
    - "CUSTOM PLAN" (white caps bold ≈15 pt) with "⌄" at the top right;
    - "5 days left" / "6 days left" (grey ≈15 pt);
    - "**27%** ACCOMPLISHED" (number ≈20 pt bold + "%" smaller + caps label in grey);
    - a **progress bar**: 4 pt, green `#6CE8A2` fill (samples `#70E4A4`/`#68ECA0`) on a `#404448` track.
  - In Aug 2026 "My Dashboard" follows it directly (32). In Apr 2026 (5.49.2) it sat above "My Day" (r68).
- **Expanded** [SEEN 31 (2026-04-16); reviews/r114 (2026-08-01)]: the same header with "⌃", then the goal rows.
  - Each row: name on the left, ≈20 pt; **completed goals in green**, others white. Examples: "7,000+ Steps", "0:22+ HR Zones 4-5 Time", "Any Strength Training Activity", "Running", "Weight Goal: 268.6 lbs", "1:30+ Strength Activity Time".
  - At the right of each row, a **ring ≈40 pt**: dashed or segmented for count goals ("5/7", "4/3", "3/3"), solid for time and value goals ("0:27", "2:49", "269.4"), green `#0CE8A0` when met. The expanded card fill is `#384040`.
  - **Order** [SEEN 34, 2026-08-01]: unfinished goals first (white), then a **hairline divider**, then **finished goals in green**.
    - Example: "14.0+ Day Strain 6/7", "Red Light Therapy 5/7" | ─── | "Ice Bath 3/2", "Dry Sauna 5/4", "Walking 6/5", "8:00+ HR Zones 1-3 Time 11:20", "0:45+ HR Zones 4-5 Time 0:45", "Pickleball 4/4", "Stairmaster 2/2", "Weightlifting 2/2".
    - Count rings are **segmented into one dash per target day** (a 7-target ring has 7 segments), with the met segments green. Time rings are solid.
  - A 9-goal custom plan (33, 2026-04-09): "Avoid Alcohol 3/4", "Hydration 3/4", "Clean Eating 2/3", "Any Recovery Activity 2/4", "Cycling 1/2", "Running 1/2", "3:00+ HR Zones 1-3 Time 1:25", "Any Strength Training Activity 0/2", "Swimming 0/1". None is finished, so all are white.
  - Bottom: "**VIEW MY PLAN**", a full-width grey rounded rectangle (`#404848`, radius ≈10 pt, white caps ≈15 pt bold).

### 6.2 PLAN OVERVIEW [SEEN completeness-critic/23 (Android, 2026-06-19)]
- Nav "‹" · "PLAN OVERVIEW".
- Section headers: caps grey label + hairline + "EDIT ✎" at the right: "HR ZONES 4-5 TRAINING", "ACTIVITIES".
- **Time goal card**:
  - "HR Zones 4-5 Time" with a ring "0:57" (green outline) at the right;
  - "0:57:01" (orange, ≈20 pt) on the left and "0:58:00" (white) on the right of a thick orange progress bar;
  - per-activity lines "0:56:23 🏃 RUNNING", "0:00:20 🏊 SWIMMING", "0:00:18 🏋 WEIGHTLIFTING";
  - footer "Get 1 min more of Zone 4-5 training during activities this week to hit your goal."
- **Count goal cards** ("Any Strain Activity 5/5", "Any Strength Training Activity 4/3"):
  - a MON–SUN row of ≈36 pt circles: blue ring with a blue dot = done; grey filled with "–" = rest or skip; dashed grey ring = future.
- The plan-name header that the help-center describes ("At the top of the Plan Overview page, tap your current plan to edit, switch, or end") was **not visible** in the captures. **UNCONFIRMED** on iOS.
- TEXT-ONLY: a user (Reddit 1tkno4g, 2026-05-22) calls it "the Weekly Plan dashboard (the one that shows your weekly goals with the exact '% Complete' progress ring at the top)". That suggests the header carries a **% complete ring**; not seen.
- TEXT-ONLY limits from users:
  - Day Strain goals show as "X+ Day Strain" counted out of 7 days (34: "14.0+ Day Strain 6/7"). A user could not set fewer days or a weekly average strain, and the AI told them to use the daily strain target (1u6kgpz). Whether the day count can be changed is **UNCONFIRMED**;
  - Steps can only be a daily goal, not weekly (1ufgave);
  - Zone 4–5 goal capped at 30 min (1r5wvn0, Feb 2026);
  - custom behaviours cannot be picked (1wjr6k6).

### 6.3 EDIT PLAN / choose a plan [SEEN reviews/r11 (2026-02-10); TEXT Locker]
- "✕" · "EDIT PLAN"; heading "Edit your Weekly Plan"; body "Choose from the list of personalized plans below or create your own. Starting a plan will customize your daily recommendations for the week ahead."
- **CURRENT PLAN** card: an AI-built plan, e.g. ✧ "Build Your Aerobic Base / Build endurance and support recovery with 7,700 daily steps and 1 hr of Zone 1-3 cardio each week."
- **CHOOSE A PLAN**: Boost Fitness (orange tint), Feel Better (green), Sleep Deeper (blue-grey).
- **CUSTOM**: Custom Plan "Build your personalized plan by selecting weekly metric, behavior and activity goals."
- The Locker says custom plans can be built "with WHOOP AI".

### 6.4 Goal editor: "BEHAVIOR GOAL" [SEEN 30 (2026-09-18)]
- Nav "‹" · **"BEHAVIOR GOAL"** (caps centred). Page background `#101418`.
- **Selected behaviour card** (fill `#2C3438`, radius ≈12 pt):
  - row "☐/☑ AVOID LATE MEAL" (checkbox + caps title);
  - "Days per week" (white ≈17 pt) with "**3 DAYS**" (blue caps) at the right;
  - a row of **7 square buttons "1"–"7"** (≈36 pt, radius ≈6 pt, unselected `#404848`; **selected blue `#64ACE4` with dark text**).
- **Suggested behaviour cards** (fill `#282C34`, radius ≈12 pt), each with:
  - a caps title + ⓘ ("ALCOHOL ⓘ", "CAFFEINE ⓘ", "REST DAY");
  - the journal question in grey ("Have any alcoholic drinks?");
  - an **impact chip**: "▼ -13% Members Like You" (orange text on an amber-tint chip), "▲ 7%" (green on a green tint), "▼ -5%";
  - an **iOS switch** at the right (off: dark track, grey knob `#A4A4A4`).
- "**+ ADD BEHAVIORS**" row card (`#283030`, ≈56 pt) opens SELECT BEHAVIORS (§3).
- Footnote, centred grey ≈15 pt: "New behaviors will also be added to your Journal for daily tracking."
- "**SAVE BEHAVIORS**" white filled capsule (≈48 pt, black caps), then a "**REMOVE**" caps text button underneath.
- Custom behaviours **cannot** be chosen here yet (user request 1wjr6k6; WHOOP replied "passing this along").
- **The other goal editors** (Sleep Performance / Hours sliders, Strain, HR zones, Steps, Activities with day toggles, Weight, Strength Activity Time) were **not seen** in 2026. **UNCONFIRMED**; see the spec §3.19 for the 2025 copy.

### 6.5 Plan in the Journal
- The Journal shows a "YOUR … PLAN" section with the plan behaviours and their week rings (§2.2 item 3). [SEEN 05, 90, 91]

### 6.6 Friday check-in (TEXT-ONLY)
- "Friday check-in – We'll send you a notification summarizing your progress for the week." (Help Center, Aug 2025).
- No screenshot of the notification or of any in-app check-in card. **UNCONFIRMED.**
- The Sep 2026 roadmap's "Check-ins" belong to the Unified Daily Experience; they are a different, daily feature.
- Also different: WHOOP AI **proactive check-ins**, which can be scheduled as SMS ("From Whoop AI SMS Check-in…", Reddit 1vgj4am, 2026-08-05), and in-app AI pushes asking about a specific activity (Reddit 1wd1pex). Neither is the plan's Friday summary.

### 6.7 Monday "My Week Recap"
- TEXT: "Monday recap – After journaling, you'll receive a final weekly summary and the option to continue or adjust your plan for the next week." The Locker gives the options as Continue / Switch / Customize.
- SEEN only in **localized App Store art**: appstore/loc-es-10 "RESUMEN DE MI SEMANA", loc-de-10 "MEIN WOCHENRÜCKBLICK", loc-fr-10 "RÉCAP DE MA SEMAINE".
  - Order: dartboard illustration → "Sigue con lo que es bueno para ti" (= "Keep doing what's good for you") → body → "44 % COMPLETO" + green bar → notched card listing goals with x/y rings, completed ones in green.
- Checked all 12 English App Store storefronts (us, gb, au, ca, in, ie, nz, sg, za, ph, my, ae; v5.72.1, 2026-09-28): **none includes the weekly-plan screenshot**. The English copy is **UNCONFIRMED**.

### 6.8 "Weekly Wrap" card / coach message
- **Not found** in any public source. The only adjacent things are:
  - the legacy Monday Weekly Performance Assessment (2020-era Locker);
  - the Sep 2026 "Unified Daily Experience" roadmap, which mentions "wrap up with a guided evening reflection" (Day in Review), daily rather than weekly.
- **UNCONFIRMED; do not invent.**

---------------------------------------------------------------------------------------------------

## 7. Colour table (sampled)

| Token | Hex | Where |
|---|---|---|
| journal.today.top | `#CEB18F` → `#B3A18D` | sand gradient top / title row (93, 01) |
| journal.today.mid | `#787A79` → `#545D64` → `#2C353E` | sand gradient middle |
| journal.past.top | `#402D7C` → `#372869` → `#252048` | purple gradient (07) |
| journal.bottom | `#101518` / `#111518` | both themes from ≈36–45 % of the height |
| journal.card.dark | `#282C2F` | row card on the dark part (07) |
| journal.toggle.idle | `#3D4144` | ✕/✓ unselected on a dark card |
| journal.toggle.no | `#FFFFFF` + black glyph | ✕ selected |
| journal.toggle.yes | `#67ADE8` (07) / `#78ACE0` (08) + dark glyph | ✓ selected |
| journal.followup.blue | `#78ACE0` capsule, `#70A8D8` slider fill, `#6C6C78` slider rest | follow-ups (08) |
| journal.notes.field | `#080C10`–`#090F0F` fill, `#202428` 1 pt border | Notes field (01, 95) |
| home.journal.card | `#34383C` card, `#64F3A6` ✓ circles, `#707478` today circle, `#484C50` BEHAVIOR INSIGHTS button | Home MY JOURNAL card (reviews/r113) |
| home.plan.empty | `#303438` card, `#78AAE4` "EXPLORE PLANS →" | Home My Plan empty state (reviews/r113) |
| select.sheet | `#283840` → `#182028` | SELECT BEHAVIORS sheet |
| select.search | `#10181C` | search field |
| select.checkbox | `#64ACE4` | checked box |
| ai.card.gradient | Smart log: `#282C48` → `#243444` → `#203844`, 1 pt border `#4A427E`; Create Custom Behaviors: `#343854` → `#283C4C` | AI entry cards (16, 13) |
| ai.btn.text / ai.btn.talk | `#3C4058` (16) or `#444C64` (13) / `#344060` → `#2C5064` | TEXT / TALK buttons |
| ai.icon.blue | `#68B0FC` sparkle, `#6BADFE` mic | Smart log card icons (16) |
| ai.sparkle | `#6E9ECD` / `#85B0D5` | ✧ icons |
| promo.border | `#7C64EC` → `#909CDC` → `#88CCE4` | Home promo card gradient border (11) |
| promo.fill | `#202424` | Home promo card |
| ai.sheet | `#1C2438` → `#04080C`; bubble `#343850`; input `#101828` | WHOOP AI sheet (04, 06) |
| insights.bg.top | `#242830` | Behavior Insights page |
| insights.card | `#303438` | unlocked card |
| insights.hatch | `#44484C` on `#303438` | bar track stripes |
| impact.helps | `#00F0A0` bar / `#02F9A5` text | green |
| impact.hurts | `#FCA420` bar / `#F3B04A` text | orange |
| impact.neutral | `#949498` bar / `#A0A3A6` text | not significant |
| chip.hurts.bg / chip.helps.bg | `#3C3424` / `#184038` | legend chips |
| chip.auto | `#344048` | ✧ auto-tracked chip |
| details.bg | `#101418` | Behavior Details page |
| details.negative.chip | `#544430`–`#584830` fill, `#EAB977` text | "Negative" (Sep 2026) |
| details.negative.impact.chip | `#302C1C` fill, `#F7AB41` text | "NEGATIVE IMPACT" (Apr 2026 variant, 26a) |
| details.counts | card `#1C2020`; ✕ box white outline; ✓ box `#76AFE4` outline | logged-count card (26a) |
| details.breakdown | `#14181C` inner card | sub-question breakdown (28) |
| logging.yes / logging.no / logging.chip | `#78ACE0` / `#88888C` / `#202C34` | Logging History (completeness-critic/20) |
| details.recommendation | `#202C34` card, `#8EB4DF` title | RECOMMENDATION |
| plan.dayselected | `#64ACE4` | Days-per-week selected |
| plan.card / plan.progress / plan.track | `#2C3034` / `#6CE8A2` / `#404448` | Home My Plan card (r68) |
| plan.ring.met | `#0CE8A0` | goal ring met (31) |
| plan.cta.grey | `#404848` | VIEW MY PLAN (31) |
| error.red | `#E83038` | save-error circle (09) |

---------------------------------------------------------------------------------------------------

## 8. Every metric / data item that appears on these screens

- **Journal:**
  - yes/no per behaviour;
  - quantity (minutes, hours, grams, servings, drinks);
  - time of day (slider);
  - free-text note;
  - plan-goal progress x/y per behaviour;
  - day status (logged ✓ / not) in the 7-day strip and the month calendar.
- **Behavior Insights:**
  - % impact on Recovery (signed, 90-day window, refreshed daily);
  - significance (coloured vs grey);
  - auto-tracked flag (✧);
  - locked counts (no-count, yes-count);
  - unlock rule 5 yes + 5 no in 90 days.
- **Behavior Details:**
  - % impact; verdict (Positive / Negative);
  - **WHOOP member average %** (with a tick on the bar);
  - per-follow-up bucket impacts (e.g. 1 drink / 2-6 drinks, hours before bed);
  - Logging History (per-month yes counts; Yes / No / Missing totals over 3 months; pager);
  - explanation text; recommendation.
- **Plan:**
  - % accomplished (equal-weight average of goals); days left;
  - per-goal x/y or value vs target;
  - HR-zone time per activity; daily circles Mon–Sun;
  - behaviour goal days/week;
  - "Members Like You" impact % per suggested behaviour.

---------------------------------------------------------------------------------------------------

## 9. Gaps / UNCONFIRMED (needs a logged-in device or a full-resolution video frame)

1. The Smart log card is now legible (16, Jun 2026). Still missing: one unbroken 2026 screenshot from the date strip down to the first rows, to confirm the title size and the exact spacing around the card (05 suggests a 1-line title in Sep 2026).
2. Journal **after the Sep 2026 custom-behaviour update**: section headers (DAYTIME / NIGHTTIME removed?), the order rule, how a custom row looks inside the Journal, and whether "USE PREVIOUS ANSWERS" survived.
3. Where "Insights" sits inside the 2026 Journal (the 2025 pill is not visible in 2026 frames).
4. The wording of the **dismiss dialog** (layout only, from the storyboard).
5. **AI behaviour-suggestion** UI (add/remove recommendations): no image.
6. The AI flow for **creating a custom behaviour** (name, unit, question, "Add" confirmation): no image.
7. A distinct **"Behavior Trends"** view beyond Logging History: not found.
8. Behavior Insights **all-locked** state header; the meaning of the "!" chip; the wording of the end-of-list notebook card.
9. Behavior Details below RECOMMENDATION; verdict wordings other than Positive / Negative.
10. Plan: the iOS Plan Overview header card, the Sleep / Strain / Steps / Activity goal editors (2026), plan setup after picking a preset, the **Friday check-in** (notification + any card), the **English Monday "My Week Recap"**, and any **"Weekly Wrap"**.
11. The NrCpf (Apr 2026) SELECT BEHAVIORS tab labels differ from the Jun/Sep ones and are unreadable.

## 10. Image index (images/journal-plan-2026/)

| File | Shows |
|---|---|
| 01-yt-bl0-2026-06-30-ios-journal-today-sand-nighttime-rows-notes-save-journal-1280.jpg | Journal (today, sand) rows as cards, NIGHTTIME, NOTES, SAVE JOURNAL |
| 02-yt-bl0-2026-06-30-ios-select-behaviors-sheet-currently-selected-1280.jpg | SELECT BEHAVIORS (Jun), outlined SAVE BEHAVIORS |
| 03-yt-bl0-2026-06-30-ios-home-top-context-1280.jpg | Home top on the same day (context) |
| 04-reddit-2026-09-12-ios-whoop-ai-sheet-over-journal-logged-nicotine-v6.png | WHOOP AI sheet over the Journal; action receipts |
| 05-reddit-2026-09-12-ENHANCED-journal-behind-ai-sheet-smart-log-with-whoop-ai-text-talk-your-custom-plan.jpg | contrast-stretched copy of 04 showing the Journal behind: day strip, title, **Smart log with WHOOP AI / TEXT / TALK**, YOUR CUSTOM PLAN rows (derived image) |
| 06-reddit-2026-09-12-ios-whoop-ai-sheet-journal-bulk-edit-reply-chips-input.png | AI reply chips + "Ask a question …" input with mic |
| 07-reddit-2026-06-03-ios-journal-0602-purple-row-cards-alphabetical-save.jpeg | purple Journal, row cards, toggle states, Save (measured) |
| 08-reddit-2026-08-28-ios-journal-row-sauna-followups-15-minutes-time-slider.jpeg | follow-ups: minutes capsule, time value, slider |
| 09-reddit-2026-09-20-ios-journal-save-error-your-entry-was-not-saved-retry-close.jpeg | save error |
| 10-reddit-2026-09-01-ios-journal-load-error-check-internet.jpeg | load error |
| 11 / 12 / 15 | Home promo cards for custom behaviours (variants; stack counter) |
| **16-reddit-2026-06-07-ios-journal-smart-log-with-whoop-ai-card-text-talk-answers-saved-automatically.jpeg** | **legible "Smart log with WHOOP AI" card + TEXT / TALK + "Your answers are saved automatically" (measured)** |
| 13-reddit-2026-09-18-…-custom-behaviors-tab-create-text-talk-custom-chip.png | CUSTOM BEHAVIORS tab, Create card, Custom chip, filled Save |
| 14-reddit-2026-09-18-…-all-tab-currently-not-selected-save-filled.png | ALL tab with CURRENTLY / NOT SELECTED |
| 20-reddit-2026-04-11-…-recovery-impact-analysis-hurts-helps-sparkle-chips.jpeg | **new Behavior Insights page** (header, legend, Title Case cards, ✧ chips) |
| 20a-reddit-2026-06-27-…-GERMAN-full-page… | whole Behavior Insights page, unscrolled: header, legend, 1 unlocked card, KEEP LOGGING section, 3 locked-row variants (German UI) |
| 21 / 22 (2026-04-17) | ALL-CAPS Behavior Insights variant (positives / negatives) |
| 23 / 24 (2026-01-16) | pre-March RECOVERY INSIGHTS modal + "REFRESHED DAILY. LAST REFRESH" page |
| 24a-reddit-2026-03-28-…-refreshed-daily-mar-22… | "RECOVERY INSIGHTS" page as of Mar 22 2026 (pre-update) |
| 25-reddit-2026-04-21-…-explore-your-recovery-insights-link.jpg | Recovery deep dive with the "EXPLORE YOUR RECOVERY INSIGHTS →" entry |
| 26a-reddit-2026-04-02-…-rest-day-variant… | Behavior Details variant: watermark, NEGATIVE IMPACT chip, explanation sentence, "You" marker, logged-count card |
| 26-reddit-2026-09-25-…-behavior-details-late-workout-…jpg | **Behavior Details top**: ✕ nav, hero, impact card, member average, Impact text, RECOMMENDATION |
| 27-reddit-2026-09-25-…-whoop-ai-v6-1-sheet…jpg | AI sheet v6.1 (header style) |
| 28-reddit-2026-09-13-…-alcohol-impact-card-expanded-subquestion-breakdown.jpeg | expanded breakdown, Negative |
| 29-reddit-2026-05-05-…-caffeine-positive-member-average-tick-breakdown.jpeg | Positive chip, member-average tick |
| 30-reddit-2026-09-18-…-plan-behavior-goal-editor…png | **BEHAVIOR GOAL** editor |
| 31-reddit-2026-04-16-…-home-my-plan-expanded…jpeg | Home My Plan expanded + VIEW MY PLAN |
| 32-forum-2026-08-05-…-home-my-plan-collapsed…jpeg | Home My Plan collapsed, then My Dashboard |
| 33-reddit-2026-04-09-…-my-plan-expanded-9-goals-46pct.jpeg | My Plan expanded, 9 unfinished goals |
| 34-reddit-2026-08-01-…-my-plan-expanded-incomplete-first-divider-completed-green.jpeg | My Plan expanded: unfinished, divider, finished in green; segmented rings |
| 40 / 41 / 42 (bl0) and 44 (NrCpf) | storyboard sheets, **ORDER ONLY** |
| 43-yt-bl0-…-4x-upscaled-structure-only….jpg | 4× upscaled storyboard frames (structure only; text illegible) |
| 90 / 91 (2025-08-28) | Journal "yesterday" (purple) with USE PREVIOUS ANSWERS + plan rows x/4 |
| 92 (2025-07-01) | SELECT BEHAVIORS staff screenshot (Apple Health pre-fill line) |
| 93 / 94 (2025-06) | Journal today (sand) with the INSIGHTS pill, DAYTIME / NIGHTTIME |
| 95 (2025-07-21, staff) | Journal bottom: STATUS section, NOTES field with border, SAVE JOURNAL (sand theme) |

Also relevant elsewhere: completeness-critic/20 (Logging History), /21 (KEEP LOGGING TO UNLOCK), /22 (Android RECOVERY INSIGHTS), /23 (PLAN OVERVIEW), /32 (NrCpf storyboard); help-center/105 (Journal date row + calendar); reviews/r11 (EDIT PLAN), r68 / r113 / r114 (Home My Plan); appstore/loc-*-10 (weekly recap, localized).
