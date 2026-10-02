# Gap 3: WHOOP first-run / onboarding sequence (2025–26)

Researched 2026-10-02 from public sources only (no logins): YouTube storyboards and public thumbnails, community.whoop.com
topic JSON plus original uploads, Reddit RSS plus i.redd.it originals, Mobbin's public flow page, and the help-center
article texts already saved in `raw/help-center-articles/`.

Images are in `images/onboarding/`. File numbers follow the flow order used below.

## How to read this note

- **Status tags**
  - **[SEEN-HI]**: read from a full-resolution screenshot. Copy is verbatim. Colours were sampled with Pillow.
  - **[SEEN-SB]**: seen in a YouTube storyboard (320×180 frames, upscaled 4×). Layout and order are reliable. Headings are mostly legible. Body copy is usually **not** legible, so it is paraphrased and marked *(approx.)*.
  - **[TEXT]**: stated in a help article, a forum post or a Reddit post, not seen as UI.
  - **UNCONFIRMED**: not seen. Do not build it as WHOOP-exact.
- **Pixel → pt conversion**: 3× unless noted. Screenshot widths map as 1170 → 390 pt, 1179 → 393, 1206 → 402, 1290 → 430, 1320 → 440.
- **Copy formatting**: verbatim copy is in "quotes". UPPERCASE labels are shown exactly as rendered.

---

## 1. Summary: the ordered sequence

The most complete evidence is **YouTube DKVm1OmWkdk** ("How To Pair Whoop MG To App", 2025-05-11). It records a **brand-new
account on iOS from landing to first Home**, about 2 s per storyboard frame. **oVQ3B3gxfSg** (2025-06-26) repeats the
device part and the tail end. WHOOP's own **RskQ9qQEt3U** (2026-08-06) shows the current pairing path. High-resolution
2026 forum screenshots confirm the account screens that still exist and their exact copy.

Two things in this order are not what most people would guess:

- **The device is paired before the account is created.** In the first-run flow, the strap tutorial and pairing come right after the user taps "CREATE ACCOUNT", and the e-mail/password step comes after "CONNECTED".
- **Payment comes before the terms.** The card form comes first, then Privacy & Terms, then "Setting up your Account…".

| # | Screen (title as rendered) | Purpose / inputs | Primary control | Evidence |
|---|---|---|---|---|
| 0 | Splash (WHOOP wordmark / W logo on black) | launch | – | 2024 Mobbin only (90-00, 90-05); 2025–26 **UNCONFIRMED** |
| 1 | **Landing**: lifestyle photo + "WHOOP" wordmark | choose path | white filled pill "I HAVE A WHOOP DEVICE"; dark outlined second pill (copy **UNCONFIRMED**); tiny text link | [SEEN-SB] 02a (2025-05), 02b (2025-06), 02c (2026-08; label text confirmed by WHOOP's caption) |
| 2a | **"Let's Get Started"** (2025) | log in **or** "CREATE ACCOUNT" | grey full-width "LOG IN" pill (disabled until filled); outlined "CREATE ACCOUNT"; text link | [SEEN-SB] 03a, 03b |
| 2b | **"Enter Your Email"** (2026, e-mail-first) | e-mail | "NEXT" + blue circle | [SEEN-SB] 03c (WHOOP official, 2026-08) |
| 3 | "Your WHOOP is on the way!" (only if the device has not arrived) | pre-delivery hub | outlined pill "PAIR …" (approx.) | [SEEN-SB] 04 (2025-06); 2024 version legible (90-04) |
| 4 | **"Unbox Your Device"** | tutorial | label + **filled** teal/blue circle (first step) | [SEEN-SB] 05a, 05b |
| 5 | **"Put On Your WHOOP"** | tutorial + "learn more"/video link | "NEXT" + ring | [SEEN-SB] 06a, 06b |
| 6 | **"Wake Up Your WHOOP"** (animated charger slides onto the sensor) | tutorial | "NEXT" + ring (~¼) | [SEEN-SB] 07a, 07b; in-app re-pair version 07c [SEEN-HI] |
| 7 | **"Check for Pairing Mode"** (side LED highlighted by a pulsing blue ring) | confirm blue light | "START PAIRING" + **filled** blue circle | [SEEN-SB] 08a–c |
| 8 | **"SEARCHING FOR STRAP..."** | BLE scan | outlined "DON'T SEE YOUR DEVICE?"; "HELP" pill top-right | [SEEN-HI] 09b (2025-06); [SEEN-SB] 09a |
| 9 | **"CHOOSE A DEVICE"** (2025) / **"SELECT YOUR DEVICE"** (2026-06) | pick a serial row | tap row; "DON'T SEE YOUR DEVICE?" (2025) or "UPGRADED YOUR WHOOP?" + "NEED HELP?" (2026) | [SEEN-HI] 10f; [SEEN-SB] 10a–e |
| 10 | iOS alert **"Bluetooth Pairing Request"** over **"CONNECTING"** | system bond | Cancel / Pair | [SEEN-SB] 11a–d |
| 11 | **"WHOOP ‹serial or name› CONNECTED"** / "Your WHOOP is ready to go." | success | outlined "CONTINUE" (2025–Jun 2026); white filled pill (Aug 2026 WHOOP video) | [SEEN-HI] 12d; [SEEN-SB] 12a–c |
| 11x | Failure: **"CONNECTION FAILED"** | retry / help | 2025: "LET'S GET STARTED" + "HELP"; 2026: white "RETRY" + dark "NEED MORE HELP?" | [SEEN-HI] 13a–e |
| 12 | **"Create Your Account"** | e-mail + password (12+ characters) | "NEXT" + ring | [SEEN-SB] 14; password rules [SEEN-HI] 14b |
| 13 | **"Welcome to WHOOP!"**: "Tell us your name so we get it right." | first name, last name, username | "NEXT" + ring (**≈24 %**) | [SEEN-HI] 15b (2026-05); [SEEN-SB] 15a |
| 14 | **"Where Do You Live?"** → (US) **"Which State Do You Live In?"** | country (search + list) → state | "NEXT" + ring | [SEEN-SB] 16a–c |
| 15 | **"Connect To Apple Health"** | optional Health link | "SKIP" (top-right); "CONNECT" + ring (~40 %) | [SEEN-SB] 17 |
| 16 | **"What's Your Birthday?"** | iOS wheel date picker (Month / Day / Year) | "NEXT" + ring (~40 %) | [SEEN-SB] 18 |
| 17 | **"Choose a Gender"** | 4 stacked option buttons | tap an option (no ring seen) | [SEEN-SB] 19 |
| 17x | Height / weight / units | – | – | **UNCONFIRMED** (not in the 2025-05 run, which had just connected Apple Health) |
| 18 | **"We're Not Charging You Yet"** / **"Activate Your Membership"** | card number, expiry, CVV, ZIP | "ACTIVATE YOUR MEMBERSHIP" + ring (**≈46 %** in 2026) | [SEEN-HI] 20b–d; [SEEN-SB] 20a |
| 18x | "Family Plan Not Activated" (blocking) | – | "RE-ENTER YOUR EMAIL" + filled green circle (←) | [SEEN-HI] 21 |
| 19 | **"Privacy and Terms of Use"** | 4 consent checkboxes (+ "SELECT AND AGREE TO ALL" row in some builds) | "NEXT" + ring (**≈50–55 %**), disabled until required boxes are ticked | [SEEN-HI] 22b–d; [SEEN-SB] 22a |
| 20 | **"Setting up your Account..."** (approx. wording; W in a spinning ring over the dimmed previous screen) | backend activation | – | [SEEN-SB] 23 |
| 20x | Failure: **"ERROR"** (red ring) "RETRY / CLOSE"; **"SOMETHING WENT WRONG"** | – | – | [SEEN-HI] 24a–b, 13f |
| 21 | Membership offer: hero photo + 2 plan cards, "1 MONTH FREE $0" vs "JOIN TODAY $199" (US, 2025) | choose plan | "NEXT" + ring (~90 %) | [SEEN-SB] 25; [TEXT] 2026 US: $219 upfront vs $239 after the trial |
| 22 | **"Turn on Push Notifications"** (custom pre-permission screen) | → iOS prompt (system prompt not seen) | "NEXT" + ring | [SEEN-SB] 26 |
| 23 | "Gift up to 2 friends a WHOOP …" (referral, with a picker) | optional | label + circle (copy **UNCONFIRMED**) | [SEEN-SB] 27 |
| 24 | **"Welcome to WHOOP"** splash (animated colourful straps) | celebration | "NEXT" + ring | [SEEN-SB] 28 |
| 25 | **"What to Expect Next"** (calibration wheel: "NEW FEATURES UNLOCK DAILY", approx.) | expectations | final control: ring (2025-05) / **filled green** circle (2025-06) | [SEEN-SB] 29a–b |
| 26 | **First Home**: "Welcome to WHOOP, ‹first name›" / "Wear your WHOOP and keep exploring" + Strain dial only (2025); 3 dials at "--%" (2025-11 onwards) + **"Get Started"** cards | – | – | [SEEN-SB] 30a; [SEEN-HI] 30b, 31a–e |

**Not part of first-run in any recording:**
- a **firmware-update** screen (§5.8);
- **journal/behaviour setup** (it is a post-run Get Started card, "Customize Your Journal … OPEN JOURNAL →");
- **coach marks / spotlight overlays** (WHOOP uses dismissible Home "tour" cards with a ✓-counter instead, §5.11);
- a **location (GPS)** permission;
- an iOS **Bluetooth-access** permission prompt (UNCONFIRMED: may appear at first scan).

### Order evidence beyond the videos

- [TEXT] forum 15461 / 15480 / 15317 (Jul 2026):
  - "after it asked me accept all terms and conditions, I am unable to login … showing error";
  - "when I need to click next. it say I can not activate my account".
  - The account is activated when NEXT is tapped on Privacy & Terms.
- [TEXT] Reddit 1u7ga1p (2026-06-16): "during the setup process, after entering my credit card information and accepting the Terms & Conditions, I keep getting … 'Something went wrong'". So the card form comes before the terms.
- [TEXT] forum 16367 (2026-09): "After pairing, the app didn't recognize the included membership. It only offered a 1-month trial … and asked for card details." So the membership/card step comes after pairing.
- [TEXT] forum 15455 (2026-07-13). Title: "…when I am adding my bank's debit card the arrow is not turning white from grey…". Body: "During the onboarding process after the gender selection, they are asking for card details."
  - This confirms the **Choose a Gender → card form** order in the 2026 build.
  - It also confirms the disabled→enabled behaviour of the ring arrow (grey → white).
- [TEXT] help "Gifting a WHOOP Membership": "Membership activation begins upon the recipient pairing their WHOOP device or automatically 90 days after shipment."
- [TEXT] help "Apple Health Integration" (4/16/2026): "WHOOP members can also enable Apple Health integration during the onboarding process when setting up their device."
- [TEXT] forum 114 (2025-05): "You'll need a valid email to create your account, and then WHOOP will prompt you to enter some basic personal details like height, weight, and date of birth … After that … pair your WHOOP strap." This is a user's recollection. It conflicts with the 2025-05 video order (pairing came first in the video) and is probably an older flow.
- [TEXT] help "Family Membership": "Admin Onboards First – The admin logs in using the same email and password used at checkout. Other Members Onboard Next…". This is why non-admins can hit the screen in step 18x.

---

## 2. The shared onboarding screen template (measured)

All account and setup steps share one template. These measurements come from the 2026 hi-res screenshots (15b, 22b–d, 20b–d):

- **Background**: a full-screen vertical gradient. There is no navigation bar, title or tab bar.

  | Position (from top) | Welcome screen (15b) | Privacy (22b) / card form (20d) |
  |---|---|---|
  | top | `#262D33` | `#262F36` / `#242D32` |
  | ~20 % | `#1F2428` | – |
  | ~45 % | `#14171C` | – |
  | mid | – | `#13181C` |
  | bottom | `#111518` | `#101518` |

- **Top bar**:
  - Back chevron "‹" (white, ≈23 pt tall glyph, x ≈ 32 pt, centred ≈ 70 pt from the top).
  - Login and e-mail screens add a **"?" in a circle** at the top-right ([SEEN-SB] 03a–c).
  - Optional steps show **"SKIP"** at the top-right as small white caps ([SEEN-SB] 17).
  - Error/modal-style screens use a **✕ in a 36 pt circle** at the top-left instead of "‹" (13a–e).
- **Vertical layout rule: content is bottom-anchored.**
  - The illustration, title, subtitle and inputs form one block that stacks upward from the CTA row. The empty space
    is at the top, below the back chevron.
  - The gap from the last content to the top of the ring is ≈ 39–53 pt. Measured: Welcome 39 pt, Privacy 43 pt,
    Family Plan 53 pt. The long card form gets only 22 pt.
  - So the title's position moves with the amount of content: y ≈ 31 % on the card form, 37 % on Welcome, 50 % on
    Privacy, 68 % on Family Plan.
  - The illustration bottom sits ≈ 40–45 pt above the title.
- **Illustration**:
  - A single grey "clay" 3-D render with one blue accent, ≈ 90 pt tall, **left-aligned** at the text margin.
  - Seen:
    - high-five hands with blue spark lines (Welcome);
    - a padlock with a blue keyhole `#049AF1` (Privacy, Family Plan);
    - a key with a W tag (password);
    - an orb/globe with sparkles (Let's Get Started / Create Your Account);
    - a globe (Where Do You Live?);
    - an ID badge on a lanyard (Birthday, Gender);
    - Health tile → W tile → app bubbles (Apple Health);
    - a phone with stacked notification cards (Push);
    - a calibration wheel (What to Expect Next).
  - Device steps use **large photoreal strap renders** instead, often bleeding off the edge.
- **Title**:
  - Title Case, white `#FFFFFF`, ≈ 25 pt. Cap height 54 px on 1170-wide = 18 pt, so the font is ≈ 25 pt, medium/semibold.
  - Left-aligned at a **16 pt margin** (48 px @1170; 21 pt on 440-pt phones).
  - Pairing/status screens instead use **UPPERCASE, bold, letter-spaced, centred** titles: "SEARCHING FOR STRAP...", "CHOOSE A DEVICE", "CONNECTING", "CONNECTION FAILED", "SOMETHING WENT WRONG", "ERROR".
- **Subtitle**:
  - ≈ 16 pt regular, grey `#BEC0C2`–`#C3C4C8`, 1–3 lines. Line pitch ≈ 21.7 pt (65 px).
  - 14 pt gap below the title.
- **Field labels**: UPPERCASE bold, tracked ≈ +1.5, ≈ 12 pt, `#C0C1C5`. They sit 10 pt above the field and are inset 4–5 pt from the field edge.
- **Text fields**:
  - Height ≈ **44–45 pt**, full width (16 pt margins).
  - Fill `#0C1013`–`#0D1114`, which is **darker than the background**, giving an inset look.
  - 1 pt border `#25292C`–`#2B3034`. Corner radius ≈ **10–12 pt** (circular).
  - Value text white ≈ 17 pt. Placeholder `#8A8B8E` ("MM/YY").
  - Spacing: field bottom to the next label ≈ 34 pt.
- **Validation error**:
  - The border turns amber (`#E9AE54` / `#DAB26C`).
  - An amber **"!"** (`#F5AB3E`) appears at the right inside the field.
  - The message below is ≈ 14 pt amber `#F9AB3F`, e.g. "Username taken".
- **Checkbox**:
  - 30 × 30 pt rounded square, radius ≈ 8–9 pt.
  - Unchecked: 2 pt white stroke. Checked: **white fill with a black ✓**.
  - The row text is white `#FFFFFF` when checked and grey `#C0C1C4` when unchecked. Links are white and underlined ("Privacy Policy", "Terms of Use", "Learn more").
  - Rows have a 60 pt pitch. The box spans x ≈ 35–65 pt and the text starts at x ≈ 83 pt, an 18 pt gap.
- **Primary step control**: bottom-right, see §3. On pairing/status screens it is a full-width pill at the bottom instead:
  - 2025: outlined capsule ≈ 47–50 pt tall, 2 pt white stroke; Android used teal `#00F1A1`.
  - 2026: white filled rounded rect ≈ 50 pt tall, radius ≈ 19 pt, black label, plus a secondary dark button with fill `#0B1013` and a 1 pt `#3D4144` border.
  - Labels are UPPERCASE bold tracked ≈ 13 pt.

---

## 3. The circular NEXT button: how it advances between steps

**Geometry and colours, measured identically on the 1170-, 1179-, 1206-, 1290- and 1320-px screenshots:**
- **Ring**:
  - centreline radius **36 pt** (108.4 px @3×), stroke **≈ 5.6 pt** (16.7 px), outer diameter **≈ 78 pt**;
  - outer edge **29 pt from the right screen edge**; with the keyboard hidden, the centre is ≈ 86 pt above the bottom
    screen edge. The same pixel size appears on every 3× phone, so it is a fixed 78 pt control.
- **Track**: `#282D30` (full circle). The centre is transparent, showing the background.
- **Progress arc**:
  - starts at **12 o'clock** and runs **clockwise** with **round caps**;
  - **angular gradient**: light `#65BAFD` at the start → `#58A9EB` at 90° → `#4697D9` near 200°. Sampled on 22b and 20d. The Welcome arc samples lighter, `#7CB6F8`→`#6CA8E6`.
  - Android MFA (42) uses **green** `#6DECA6`.
  - The 2025-06 device steps look **teal/cyan** [SEEN-SB]; colour not sampled.
- **Glyph and label**:
  - White "→" arrow inside the ring.
  - The step label sits to the **left of the ring** with a ≈ 15 pt gap (44 px).
  - Label style: UPPERCASE bold, letter-spaced. Cap height 22–24 px ≈ 7.7 pt, so the font is ≈ 11 pt.
  - Label widths: "NEXT" ≈ 33 pt; "ACTIVATE YOUR MEMBERSHIP" ≈ 196 pt.
  - The label is vertically centred on the ring.
- **Disabled state** (required input missing):
  - Privacy: until the required boxes are ticked. Rows 1–3 are probably required and row 4 (marketing) optional; this is inferred, because rows 2–3 unticked = disabled and all four ticked = enabled.
  - Card form: until the card is valid.
  - Appearance: label `#4B4F52`, arrow `#484D50`. **The arc is still drawn**, so progress shows even while disabled.
- **Enabled state**: label and arrow `#FFFFFF`.

**What the arc means:** it shows **progress through the account-setup flow**. Each NEXT pushes the next step, and that step
shows a longer arc. Whether the arc animates (grows) during the transition is **UNCONFIRMED** (no video frames that close
together). The cap-corrected arc length is span − 2 × 4.4° cap overhang.

| Step | Build | Arc (cap-corrected) | Source |
|---|---|---|---|
| Welcome to WHOOP! (name/username) | 2026-05 | ≈ 86° ≈ **24 %** | 15b [SEEN-HI] |
| Card form ("ACTIVATE YOUR MEMBERSHIP") | 2026-07 ×2, 2026-09 | ≈ 165° ≈ **46 %** (identical on 3 users) | 20b–d [SEEN-HI] |
| Privacy and Terms (with SELECT AND AGREE TO ALL) | 2026-07 | ≈ 181° ≈ **50 %** | 22d [SEEN-HI] |
| Privacy and Terms (no select-all row) | 2026-05 | ≈ 197° ≈ **55 %** (identical on 2 users) | 22b–c [SEEN-HI] |
| Android "SETUP MFA" (separate 3-step flow) | 2026-06 | ≈ 120° ≈ **33 %** (green) | 42 [SEEN-HI] |
| Wake Up Your WHOOP (device sub-flow) | 2025-06 | ~25 % | 07b [SEEN-SB], ±10 % |
| Where Do You Live? / Which State | 2025-05 | ~25 % | 16a–b [SEEN-SB] |
| Connect To Apple Health / Birthday | 2025-05 | ~40 % | 17, 18 [SEEN-SB] |
| We're Not Charging You Yet | 2025-05 | ~60–65 % | 20a [SEEN-SB] |
| Privacy and Terms | 2025-05 | ~80 % | 22a [SEEN-SB] |
| Membership offer | 2025-05 | ~90 % | 25 [SEEN-SB] |

**Filled-circle variants** use the same position and a ≈ 72 pt diameter. They replace the ring on special steps:
- **first step or "commit" step**:
  - "Unbox Your Device" (teal/blue, label approx. "GET STARTED");
  - "Check for Pairing Mode" ("START PAIRING", blue);
  - "Introducing Healthspan" ("GET STARTED", pink) in feature-intro flows (45).
- **final step**: green filled circle with ✓ and a label like "DONE" (Healthspan "Trending Faster"; "What to Expect Next" on 2025-06).
- **back action**: "Family Plan Not Activated", label "RE-ENTER YOUR EMAIL", fill **`#00F19D`** with a dark "←" arrow.
- **WHOOP's Aug-2026 video**: every step it shows ("Enter Your Email", "Unbox Your Device", "Check for Pairing Mode") uses a **solid blue circle**. It is unclear whether this is a newer design or a simplified mock (**UNCONFIRMED**).

**Label wording seen:**
- "NEXT" (default);
- "CONNECT" (Apple Health);
- "ACTIVATE YOUR MEMBERSHIP" (card form);
- "START PAIRING";
- "RE-ENTER YOUR EMAIL";
- "GET STARTED" (feature intros);
- final "DONE"/"FINISH" (**UNCONFIRMED** which).

The same control (ring plus label, grey when disabled) is reused outside onboarding: MFA setup, Healthspan intro and the
Blood-pressure questionnaire (wS84 storyboard).

The **2024 flow** (Mobbin, 90-07…09) used a **segmented 10-dash progress bar** under the text, plus outlined capsules.
The circular progress button replaced it by 2025.

---

## 4. Variants by entry path

| Path | What differs | Evidence |
|---|---|---|
| New member, device in hand (iOS) | full sequence of §1 | DKVm (2025-05) |
| Existing account logs in (2025) | Let's Get Started → LOG IN → device tutorial → pairing → "Where Do You Live?" → "What to Expect Next" → Home | oVQ3 (2025-06) |
| Existing account, e-mail-first (2026) | "Enter Your Email" → (password, UNCONFIRMED) → Unbox → Check for Pairing Mode → device list → Connecting → Connected | RskQ (WHOOP 2026-08) |
| Device not yet delivered | "Your WHOOP is on the way!" hub with order tracking, referral, WHOOP basics and a "PAIR …" pill | oVQ3 04; 2024 90-04 |
| Re-pair / new phone (from the app) | More › Device Settings ("WHOOP DISCONNECTED / Tap 'Pair a Device' below to continue." + "PAIR A DEVICE" row) → "Wake up your WHOOP" ("Slide on the charger to wake up your WHOOP and begin pairing with the app", with the tab bar still visible) → device list → Connected | 43a, 07c, 46a/46a2, 11d |
| Upgrade (4.0 → 5.0/MG) | the device list shows both straps; after pairing an "add payment method" popup or a "Gift your 4.0, get $50" trade-in screen | 10e, 1bX storyboard; Reddit 1ug1l5u [TEXT] |
| Family plan member before admin | blocked on "Family Plan Not Activated" | 21 |
| Upcycled / gifted strap (Android) | after the connected illustration: "Join with 1 month free / WHOOP detects an upcycled Strap" + white "START FREE TRIAL" | 44a |
| Lapsed member | Home shows a "MEMBERSHIP EXPIRED / Click here to reactivate your membership" banner and a "REJOIN WHOOP / No one on WHOOP is quite like you" sheet with lifetime stats + gradient "EXPLORE OPTIONS" | 44b–e |

---

## 5. Step details

### 5.1 Landing (1) [SEEN-SB, 02a–c]

**Layout:**
1. Full-bleed lifestyle photo over the top ≈ 60 % of the screen:
   - 2025-05: an arm with a strap, blue/teal light;
   - 2025-06 and 2026-08: a warm-toned bed scene with a strap on the wrist.
2. A dark gradient fade into the bottom.
3. The **"WHOOP" wordmark** (white, centred, with ®) at ≈ 65 % of the height.
4. Three stacked controls:
   - a **white filled capsule**, full width minus ≈ 16 pt, label "I HAVE A WHOOP DEVICE" (dark text). Confirmed by WHOOP's own caption "1. In the WHOOP app, select [I HAVE A WHOOP DEVICE] and enter your email to log into your account";
   - a **second, white-text option**: a dark capsule in 2025; it looks borderless (text-only) in WHOOP's 2026 video.
     - Its label is **1.29–1.36× wider** than "I HAVE A WHOOP DEVICE" (measured on 8× upscales of both videos). That
       fits about 27–28 characters, i.e. the 2024 wording "I DO NOT HAVE A WHOOP DEVICE" or "I DON'T HAVE A WHOOP
       DEVICE".
     - Exact copy **UNCONFIRMED**.
   - a tiny centred line with a small leading icon, probably a legal/terms link (**UNCONFIRMED**).

**2024 legacy (90-01):**
- "A WHOOP DEVICE IS REQUIRED" (top);
- "WHOOP" + "UNLOCK YOURSELF";
- blue-outlined "I HAVE A WHOOP DEVICE";
- white-outlined "I DO NOT HAVE A WHOOP DEVICE".

The box's inner flap carries "GET STARTED / SCAN TO OPEN THE WHOOP APP" + a QR code, plus "UNLOCK YOURSELF" (RskQ storyboard).

### 5.2 Log in / create (2a, 2b)

**2025 "Let's Get Started"** [SEEN-SB 03a–b]:
- "‹" and "?" icons at the top;
- orb illustration;
- title "Let's Get Started";
- subtitle "Log in or create an account." *(approx.)*;
- "EMAIL ADDRESS" field and "PASSWORD" field;
- blue "FORGOT PASSWORD?" link;
- full-width **grey filled "LOG IN"** (disabled until both fields are filled);
- a line of text, *approx.* "Have a WHOOP but don't have an account yet?";
- outlined **"CREATE ACCOUNT"** capsule;
- a bottom text link, *approx.* "SET UP INSTRUCTIONS".

**2024 legible version (90-02/03):**
- underline-style fields "EMAIL ADDRESS" / "PASSWORD";
- "FORGOT YOUR PASSWORD?";
- outlined "LOG IN" that turns **teal** when enabled;
- "Have a WHOOP but don't have an account yet?";
- "CREATE ACCOUNT";
- "SETUP INSTRUCTIONS";
- "CAN'T LOG IN? EMAIL SUPPORT".

**2026 "Enter Your Email"** [SEEN-SB 03c]:
- "‹" and "?" at the top;
- a small card/envelope illustration at the left;
- title "Enter Your Email";
- 2-line subtitle (**UNCONFIRMED** copy);
- one field label + field;
- bottom-right "NEXT" + blue filled circle.

The password step that follows is not shown in WHOOP's video (**UNCONFIRMED**).

**[TEXT] forum 15895:** password managers ("Apple and Bitwarden") don't autofill in the app.

**Password rules** [SEEN-HI 14b, Android, French, 2026-07, reset flow]:
- key illustration;
- "NOUVEAU MOT DE PASSE" field with an eye toggle;
- live rule checklist with **green checkbox ticks**: "Le mot de passe ne peut pas contenir d'espaces" (cannot contain spaces) and "Le mot de passe doit contenir au moins 12 caractères" (at least **12 characters**);
- full-width grey button showing a **W spinner** while busy.

### 5.3 Device tutorial and pairing (4–11) [SEEN-SB + SEEN-HI]

- **"Unbox Your Device"** (05a–b):
  - photoreal sensor/band and charger (PowerPack, or the basic charger on a cable) side by side;
  - 2-line body;
  - label + **filled circle**.
- **"Put On Your WHOOP"** (06a–b):
  - big strap render;
  - 3-line body *(approx. "Slide your WHOOP on so that your band feels snug but comfortable. Adjust the tightness by opening the clasp & pulling the loose end of the band.")*;
  - a blue link line (approx. "LEARN MORE" or a video link);
  - "NEXT" + ring.
- **"Wake Up Your WHOOP"** (07a–b):
  - animated: the charger drops onto the sensor, then the LED lights;
  - body *approx.* "Slide on the charger to start pairing your device.";
  - "NEXT" + ring.
  - The in-app re-pair copy [SEEN-HI 07c] is sentence case: "Wake up your WHOOP" / "Slide on the charger to wake up your WHOOP and begin pairing with the app".
- **"Check for Pairing Mode"** (08a–c):
  - sensor render whose **side LED is circled by a pulsing blue ring**;
  - body *approx.* "A blinking blue light on your WHOOP means it's ready to pair with the app.";
  - a blue link (approx. "Not seeing a blue light?", **UNCONFIRMED**);
  - **"START PAIRING"** + filled blue circle.
- **"SEARCHING FOR STRAP..."** [SEEN-HI 09b, 2025-06]:
  - centred caps title; "Ensure your WHOOP strap is in range and discoverable.";
  - an open-clasp render with the serial **"W // 5A12345000" highlighted in blue `#258ACB`** and a dotted leader line and dot;
  - top-right **"HELP" outlined pill**: 80 × 30 pt, `#118DD6` outline and text;
  - bottom **"DON'T SEE YOUR DEVICE?"** white-outlined capsule, 50 pt tall, ≈ 14 pt side margins.
- **"CHOOSE A DEVICE"** [SEEN-HI 10f, Android 2025-09]:
  - "Confirm the serial number on the side or top of the device.";
  - the same render;
  - list row(s) "WHOOP 5B00334077": translucent rounded rows, white bold caps, chevron on iOS;
  - "DON'T SEE YOUR DEVICE?";
  - a "?" circle at the top-right (Android).
  - With two straps nearby, two rows are listed (10a, 10e).
- **2026-06 rename** (10d):
  - **"SELECT YOUR DEVICE"** with a 3-line subtitle;
  - a row showing the user's **custom device name + "›"**;
  - two stacked dark buttons, "**UPGRADED YOUR WHOOP?**" and "**NEED HELP?**".
  - WHOOP's Aug-2026 video (10c) looks Title-Case ("Choose a Device"). **UNCONFIRMED.**
- **iOS "Bluetooth Pairing Request"** (11a–d): system alert, "'WHOOP 5AG0451784' would like to pair with your iPhone." Cancel / Pair. It sits over **"CONNECTING" / "Pairing with WHOOP ‹serial›"**.
  - Illustration:
    - left: a black phone with a white W;
    - right: the strap;
    - joined by a **dotted blue line with blue end dots**.
- **"‹NAME› CONNECTED"** [SEEN-HI 12d]:
  - "NATE'S WHOOP MG / CONNECTED" (2 lines, caps, centred) / "Your WHOOP is ready to go." / white-outlined capsule **"CONTINUE"**;
  - the line becomes **solid green** with a glowing **green ✓ circle** in the middle.
  - Aug-2026 WHOOP video: the continue button is a **white filled pill** (12c).
- **Failure** (13a–e):
  - same illustration, with a **red ✕ in a dark circle with a red ring `#D7001F`** and red end dots;
  - "CONNECTION FAILED";
  - 2025 body: "To continue, put your device into pairing mode using the following steps." + "LET'S GET STARTED" (white outline iOS, teal Android) + "HELP" pill;
  - 2026 body: "To continue, select 'Retry' or follow our 'Need More Help' article for advanced steps." + white filled **"RETRY"** + dark outlined **"NEED MORE HELP?"** (both ≈ 50 pt tall, radius ≈ 19 pt).
- **Account lookup failure** (13f, 2025-12):
  - teal-slate gradient (`#32444E` → `#0A0F12`);
  - grey ring "!" icon (59 pt, `#4D5558`);
  - "SOMETHING WENT WRONG" / "There was an issue looking up your account. Please try again. If this issue persists, contact support.";
  - teal `#00F1A1` outlined "RETRY".
- **WHOOP's physical instructions:**
  - 2025-05 (46a): "Remove WHOOP from wrist." / "Make sure the green sensor LEDs turn off." / "Rapidly tap the top of your device until the blue light pulses." / "Open the WHOOP app > Menu > Device Settings." / "Select Pair a Device and tap your WHOOP when it appears." / "When the blue lights stop, WHOOP is connected."
  - 2026-08 (46b): "Firmly and rapidly tap the top of your device until the blue light on the side of the sensor pulses." / "Locate and confirm your WHOOP Device ID on the side of your WHOOP sensor." / "4. In the app, select [START PAIRING] Select your Device ID to pair your WHOOP."

### 5.4 Account and profile (12–17)

- **"Create Your Account"** [SEEN-SB 14]: orb illustration; 1-line subtitle (approx., mentions the 12-character password rule); "EMAIL ADDRESS" and "PASSWORD" fields; a small consent/legal line under the fields (**UNCONFIRMED** copy); "NEXT" + ring.
- **"Welcome to WHOOP!"** [SEEN-HI 15b]:
  - copy: "Tell us your name so we get it right." / "FIRST NAME" / "LAST NAME" / "USERNAME";
  - username error: "Username taken" (amber border, "!" icon, amber helper text);
  - NEXT ring ≈ 24 %;
  - geometry: title at y 315 pt; fields 44–46 pt tall; field pitch ≈ 95 pt.
- **"Where Do You Live?"** [SEEN-SB 16a, 16c]:
  - globe icon; 2-line body (**UNCONFIRMED**);
  - search field (magnifier + placeholder);
  - list of country rows: flag + name, rounded grey rows;
  - typing filters the list (e.g. "Un…" showed the United … rows);
  - the **selected row turns white with dark text**;
  - "NEXT" + ring.
- **"Which State Do You Live In?"** (US only) [SEEN-SB 16b]: search + alphabetical state rows (Alabama, Alaska, …), "NEXT" + ring.
- **"Connect To Apple Health"** [SEEN-SB 17]:
  - Health heart tile → blue arrow → grey W tile → 5 grey app-icon bubbles;
  - 2-line body *approx.* "Sync your Apple Health data with WHOOP to get the full picture of your health and performance.";
  - blue "LEARN MORE" link;
  - small **"SKIP"** at the top-right;
  - **"CONNECT"** + ring. The iOS Health permission sheet that follows is not visible (**UNCONFIRMED**).
- **"What's Your Birthday?"** [SEEN-SB 18]: ID-badge illustration; 2-line body (**UNCONFIRMED**; probably about age-group benchmarks); **iOS inline wheel picker** (Month | Day | Year) with a highlighted selection band; "NEXT" + ring.
- **"Choose a Gender"** [SEEN-SB 19]:
  - ID-badge illustration; 1-line body (**UNCONFIRMED**);
  - **four stacked full-width grey rounded buttons** with centred caps labels.
  - Labels are illegible; lengths suggest approx. "WOMAN"/"FEMALE", "MAN"/"MALE", "NON-BINARY", "I PREFER NOT TO SAY" (**UNCONFIRMED**).
  - Tapping an option appears to advance; no ring was visible.
  - The profile editor calls this field "Gender / Physiological Baseline" [TEXT], so the physiological-baseline question may follow for non-binary or undisclosed answers (**UNCONFIRMED**).
- **Height / weight / units**: not seen in first-run.
  - The profile editor holds "Email, Name, Birthday, Gender / Physiological Baseline, Location (e.g. Country, State), Units (Imperial vs Metric), Weight & height" [TEXT].
  - Apple Health "syncs height and weight" [TEXT], which may be why the 2025-05 run skipped them.
  - **UNCONFIRMED** as onboarding screens.

### 5.5 Membership activation (18, 21)

Three copy variants of the card step [SEEN-HI]. All share:
- card-brand logos (VISA, Mastercard, Discover, Diners, AMEX), 20 pt tall;
- "CARD NUMBER" (full width), "EXPIRATION DATE" (placeholder "MM/YY") and "CVV" (half width each), "ZIP CODE" / "ZIP CODE (OPTIONAL)";
- a numeric keypad sheet when a field is focused (20b);
- fine print in `#BDBFC1`;
- **"ACTIVATE YOUR MEMBERSHIP"** + ring. While the card is invalid the label shows in **disabled grey `#43484B`**.

| Variant | Title + body | Fine print | Source |
|---|---|---|---|
| Trial (2026-09) | "We're Not Charging You Yet" / "We need payment info for when your membership starts. You'll have the option to start with 1 month free or join today with our lowest offer yet." | "After your trial ends on 25 October 2026, we'll renew it for ₹23,990 annually." | 20d |
| Prepaid (2026-07) | "Activate Your Membership" / "Details required for setting up your account. You will not be billed until your renewal date of 14 July 2027 and you will be notified 30 days prior to being charged. Update your payment or cancel any time." | "After your WHOOP membership ends on 14 July 2027, we'll renew it for ₹23,990 annually. Cancel before your billing date." | 20c |
| US, keypad open (2026-07) | header scrolled off | "After your WHOOP membership ends on August 21, 2026, we'll renew it for $239 + tax annually. Cancel before your billing date." | 20b |

The 2025-05 US trial version (20a) had the same title, and fine print *approx.* "After your trial ends on July 11, 2025, we'll renew it for $239 + tax annually."

**Plan choice** [SEEN-SB 25, 2025-05]:
- full-bleed hero photo (two people outdoors);
- a W-in-circle badge; small caps line + "WHOOP"; 2-line body;
- **two selectable plan cards**:
  - "1 MONTH FREE" ($0, with a subline);
  - "JOIN TODAY" ($199, with a subline). It is selected by default: white outline, a small tag at its top-left, a ✓ badge at the top-right;
- fine print about renewal;
- "NEXT" + ring.
- [TEXT] 2026 US: "During setup, I chose the option to pay $239 after the trial instead of paying the $219 upfront offer." (Reddit 1whppro).
- [TEXT] Reddit 1vwhrpr (2026-08): "Since WHOOP memberships remain dormant until the new hardware is paired for the first time … will the system keep blocking me with a 'Select a Membership Plan' screen until the physical band is paired?" The plan-choice screen may be titled "Select a Membership Plan" (user's wording, **UNCONFIRMED**).
- [TEXT] Reddit 1pow2g3 (2025-12): the 4.0 → 5.0 upgrade "gives basically no walkthrough, no demo, no clear 'here's what changed / here's what to try.'" Re-pairing or upgrading skips any tour.
- [TEXT] AU trial terms mention a $13.99 return-shipping fee.

**"Family Plan Not Activated"** [SEEN-HI 21]:
- lock illustration;
- body: "The person who purchased the Family Plan (admin) must complete the activation process in order for you to continue. If you are the admin, go back and enter the email you used to purchase the plan.";
- "RE-ENTER YOUR EMAIL" + **filled green `#00F19D` circle with ←**, 72 pt.

### 5.6 Privacy and Terms of Use (19) [SEEN-HI 22b–d]

**Copy (verbatim):**
- "Privacy and Terms of Use"
- "Agree to the statements below to use our products. Your data is secure, and never sold."
- ☐ "I consent to the processing of data concerning my health in the United States."
- ☐ "I have read and accept the WHOOP Privacy Policy." (link)
- ☐ "I have read and accept the WHOOP Terms of Use." (link)
- ☐ "Be first to hear about new features, studies, and other member exclusives. Learn more" (link; marketing opt-in)

**Other variants:**
- **2026-07 and 2025-05** builds add a top row card **"SELECT AND AGREE TO ALL"**: 44 pt tall, fill `#2B2F32`, radius ≈ 12 pt, inset ≈ 19 pt, with its own checkbox and white bold caps label. The 2026-05 build lacked it (A/B test or regional, **UNCONFIRMED**).
- On both May-2026 screenshots rows 1 and 4 are ticked and rows 2–3 are not, because of a bug that made rows 2–3 untappable. **Default tick states are UNCONFIRMED.**
- NEXT stays disabled (grey) until the required boxes are ticked. Tapping it shows **"Setting up your Account..."**: a W inside a spinning ring over the dimmed screen, with a "do not close the app" style subline (**UNCONFIRMED** copy).

**Failures:** "ERROR" (24a–b) [SEEN-HI].
- Pure black `#000000` background.
- **Red ring `#FF0026`**: 95 pt diameter, 4.7 pt stroke, with a red "!" inside.
- "ERROR": caps, ≈ 15 pt bold white.
- **"RETRY"**: white-outlined capsule, 308 × 39 pt, 2 pt stroke.
- **"CLOSE"**: text button.
- Seen on login and activation through May–Sep 2026.

**Android server outage** (24c): "LOOKS LIKE THE SERVER IS TAKING A QUICK NAP / Server connection failed. / Wait a few moments, then try reloading." + "RELOAD" + a 3-D "Zz" illustration.

### 5.7 Permissions and extras (22, 23)

- **"Turn on Push Notifications"** [SEEN-SB 26]: grey 3-D phone with stacked notification cards; 3-line body (**UNCONFIRMED** copy; about getting updates without opening the app and managing them in Settings); "NEXT" + ring. The iOS system prompt is not visible.
- **Referral** [SEEN-SB 27]:
  - hero photo; title *approx.* "Gift up to 2 friends a WHOOP free trial";
  - a question line + a small wheel/number picker;
  - a blue-tinted info banner;
  - bottom-right label + circle (copy **UNCONFIRMED**).
- **Bluetooth**: only the bonding alert "Bluetooth Pairing Request" was seen. The "WHOOP would like to use Bluetooth" access prompt is **UNCONFIRMED**.
- **Location**: no GPS prompt in first-run. Country/state are picked manually (§5.4). **UNCONFIRMED** when GPS is requested; probably on the first GPS activity.
- **Background reminder** (r152 elsewhere): local notification "Open WHOOP — Keep the WHOOP app running so your data can stay up to date."

### 5.8 Firmware [TEXT + SEEN-HI]

No firmware screen appears in any onboarding recording.

[TEXT] help "How to Update Your Product's Firmware" (6/10/2025):
- "When a firmware update becomes available, you will receive a pop-up notification in the WHOOP app. If you choose to delay the update, the app will prompt you again in 24 hours."
- Manual path: Device Settings › Advanced › **FIRMWARE CHECK** → "Update Now".
- Requirements: ≥ 20 % battery; within 10 ft; up to 10 min; the sensor may disconnect for up to 1 min.
- "If both your WHOOP app and firmware need updates, always update the app first."

**"NO NEW UPDATES"** [SEEN-HI 41, 2026-01]:
- modal card 352 × 231 pt, fill `#21282E`, radius ≈ 10 pt, ✕ at the top-right, over a near-black scrim `#050505`;
- "NO NEW UPDATES" / "You have no new firmware updates at the moment.";
- white filled **"OKAY"**, 314 × 44 pt.

The "update available" pop-up itself is **UNCONFIRMED**.

**App gate** [SEEN-HI 40, 2026-07]: modal card "UPDATE REQUIRED / The WHOOP app is out of date. An update is required to enjoy the latest features and performance improvements." + white-outlined capsule "UPDATE APP".

### 5.9 Finish (24, 25)

- **"Welcome to WHOOP"** splash [SEEN-SB 28]: dark background; four colourful 3-D straps animate in (teal/lime, white knit, gold/orange, silver); then the centred title fades in ("Welcome to" small, the "WHOOP" wordmark large); "NEXT" + ring.
- **"What to Expect Next"** [SEEN-SB 29a–b]:
  - a large **calibration wheel**: a dark circular track with small icon dots at 8 positions and a **blue/cyan highlighted arc segment** at the top-right holding mini icons; a strap render in the centre; a 2-line caps caption (*approx.* "NEW FEATURES UNLOCK DAILY");
  - title + 3-line body (**UNCONFIRMED**; about the next week of calibration);
  - final control (2025-06): **filled green circle**.

### 5.10 First Home and calibration states

- **2025-05 Day-1 Home** [SEEN-HI 30b, thumbnail]:
  - header: avatar, "‹ TODAY ›", battery;
  - "WHOOP" wordmark;
  - big left-aligned **"Wear your WHOOP and keep exploring"** with **only the Strain dial** ("6.3", "STRAIN ›") on the right;
  - "Get Started" with a coach row ("Ask a question, get support…");
  - TODAY'S ACTIVITIES ("DOG WALKING 6.1", "+ ADD ACTIVITY", "START ACTIVITY");
  - "TONIGHT'S SLEEP" ("Now / RECOMMENDED BEDTIME", "05:30 / WAKE TIME (ALARM OFF)");
  - "Looking Ahead" › "FIRST WEEK WITH WHOOP";
  - floating "+".
  - Another 2025-05 run greeted by name: **"Welcome to WHOOP, ‹first name›"** + Strain dial (30a).
  - **2025-05 "Looking Ahead" card** [SEEN-HI 32d]:
    - card fill `#33363D` on `#222931`;
    - a pink graduation-cap icon `#CD76BB` + "FIRST WEEK WITH WHOOP ›";
    - copy: "Wear your WHOOP to bed nightly and check back in here to track your sleeps and discover new insights.";
    - "SLEEPS LOGGED 0/7" over **seven numbered outlined circles 1–7**;
    - below it, "My Dashboard" › "Personalization in Progress".
    - By 2025-11 this became "CALIBRATION TIMELINE ›" with a "0/7" ring (32a).
- **2025-11 → 2026 Day-1 Home** (31a–e, 32a):
  - three dials, Sleep "--%", Recovery "--%", Strain live;
  - **"Get Started"** section title + white "+" square;
  - a promo card with a gradient border;
  - "Ask a question, get support…" coach row;
  - TONIGHT'S SLEEP;
  - "Looking Ahead" › "CALIBRATION TIMELINE ›" ("Wear your WHOOP to bed nightly and check back in here to track your sleeps and discover new insights." + "0/7" ring);
  - "My Dashboard" › "Personalization in Progress" ("As your device calibrates to your unique physiology, you'll gain insight into your trends here.").
- **Get Started cards, verbatim** [SEEN-HI]:
  - "Learn How to Charge" / "Ensure your WHOOP has enough battery to collect data throughout your first day and night." / "VIEW CHARGING TIPS →" (31a, 2026-09)
  - "Set Up Your Sleep" / "Input your sleep routine so WHOOP can help you wind down intentionally and wake up gently at the right time." / "CREATE SLEEP SCHEDULE →"
  - "Customize Your Journal" / "The more you share with WHOOP, the more insights you get. Track habits to see their effects so you can make well-informed decisions." / "OPEN JOURNAL →". **This is the only journal/behaviour setup touchpoint.**
  - (partial) Advanced Labs: "…Upload previous lab results to get a 360 view of your health and track trends"
  - "Ready to get moving?" / "Start your first activity and come back to explore your heart rate zones and more on WHOOP." / "START ACTIVITY →" (31c–e)
  - "Unlock New Potential" / "Connect WHOOP to Strava and your favorite apps for a seamless experience across platforms." / "EXPLORE APP INTEGRATIONS →" (31b, 31d)
- **Card styling** (31a, measured):
  - **first card**: 1.3–1.5 pt **horizontal gradient border**, peach `#FF9C7E` (left) → `#E38CAE` → `#D579C6` → `#C257E5` → violet `#B132FB` (right). Fill is a faint violet wash, `#2A2430` → `#251F2D`.
  - **other cards**: fill `#1D2124`, no border.
  - CTA text: magenta **`#C452D0`**, caps, with "→".
  - Each card has a grey 3-D illustration with a magenta accent on the right.
  - Cards are 15 pt inset and ≈ 140 pt tall.
- **Calibration states:**
  - Health Monitor on day 1 (32b): a violet banner "Wear WHOOP to sleep 7 more nights to calibrate." with a **7-segment progress bar**; tiles show "--" + "● Calibrating Range".
  - "Beyond First 7 Days" (32c): card "VO₂ Max / Log 14 sleeps to unlock" + a thin progress bar + ⓘ.
  - Health tab around day 20 (32e, 2026-09):
    - top card with a peach→violet gradient border and a magenta speckled "locked" orb;
    - copy: "UNLOCK HEALTHSPAN" / "1 more day to unlock your personal Healthspan.";
    - a thin **magenta progress bar `#CB4FD6`** on a `#4C4859` track;
    - below it, an "ADVANCED LABS" promo card ("Get deeper health insights, adding your lab results from doctor visits with your 24/7 WHOOP data. GET STARTED →").
  - Unlock thresholds are in `raw/help-center-articles/Calibration-Timeline.txt`.
- **"Your First 4 Days"** [TEXT, help 8/13/2026]: "a checklist of mini-tutorials":
  - "Track an activity"
  - "Join a team in the community"
  - "Analyze your Sleep Performance"
  - "View your activity details"
  - "Set up your personalized alarm"
  - "Set up your daily journal"

  "In the WHOOP app, navigate to the More tab … Tap on Getting Started." The checklist UI is **UNCONFIRMED**. The 2025-05 More tab (30c) shows a bordered "FIRST WEEK WITH WHOOP" card at the top, and the Home "Looking Ahead" row uses the same name.

### 5.11 Tours and coach marks

- **No spotlight / tooltip coach marks** were seen in any 2025–26 source.
- Instead, WHOOP announces features with **stacked Home cards** carrying a "✓ n" counter pill (marks the card read; n = cards remaining):
  - "**Your Home Has a New Look** / Tap Sleep, Recovery, or Strain above to learn more about your core daily metrics." (33a: gradient border, 3-D house; counter "✓ 2");
  - "**Coach at Your Fingertips** / Coach is now in your bottom navigation bar. Tap the "+" button next to My Day to quickly log activities, start Strength Trainer, and more." (33b: blue-violet border; counter "✓ 4").
- A post-setup overlay in Device Settings: "Never run out of battery" + a gradient-outlined pill (30c, **UNCONFIRMED** copy).
- [TEXT] forum 15895 (2026-08): "Very annoying all the rings need to jump through to clear prompts and some, like build a community, never closes/ no X out of." So some Get Started cards have no dismiss.
- [TEXT] forum 8956 (2025-10, several new members):
  - "I can't get rid of the 'Customize Your WHOOP Experience' widget from the Get Started tutorial. The order of the cards is messed up: instead of going from steps 1 to 6, it goes 1 → 4 → 5–6 → 2–3."
  - "Just go through the first 2 nights and it will get pushed away by new notifications."
  - So in late 2025 the Home "Get Started" area held a **6-step tutorial widget titled "Customize Your WHOOP Experience"**. It steps through cards in order and disappears after about two nights.
  - Its visuals are **UNCONFIRMED**. The six steps probably match the "Your First 4 Days" tasks: activity, team, sleep performance, activity details, alarm, journal.

### 5.12 MFA (optional, not first-run) [SEEN-HI 42]

MFA is required only for Advanced Labs [TEXT help 5/26/2026].

**Screen (Android):**
- nav title "SETUP MFA" with "‹" and a headset (support) icon;
- "Confirm your email address" / "We will send a code using your registered WHOOP account email. To change your email used for MFA, you must change your WHOOP account email.";
- blue "CHANGE ACCOUNT EMAIL →";
- field with a lock icon;
- outlined "USE MY PHONE NUMBER INSTEAD";
- "NEXT" + **green** ring at 33 %.

---

## 6. Change log: 2024 → 2025 → 2026

| Element | 2024 (Mobbin, 90-xx) | 2025 | 2026 |
|---|---|---|---|
| Landing | runner photo, "UNLOCK YOURSELF", blue/white outline capsules | lifestyle photo, white filled + dark outlined capsules | same, re-shot photo (bed scene) |
| Auth | e-mail + password on one screen, underline fields | "Let's Get Started" (log in or create) | e-mail-first "Enter Your Email" |
| Tutorial progress | 10-dash segmented bar, outlined "GET STARTED" / "PAIR MY DEVICE" | circular NEXT ring + filled start/commit circles | same (blue filled circles in WHOOP's video) |
| Device list title | "CHOOSE A DEVICE" | "CHOOSE A DEVICE" | "SELECT YOUR DEVICE" + "UPGRADED YOUR WHOOP?" / "NEED HELP?" |
| Failure | – | outlined "LET'S GET STARTED" + "HELP" | white "RETRY" + "NEED MORE HELP?" |
| Privacy | – | with "SELECT AND AGREE TO ALL" | May: without it; Jul: with it |
| Day-1 Home | "Your 4.0 is on the way!" hub | headline + Strain-only dial ("Wear your WHOOP and keep exploring") | 3 dials at "--%" + Get Started cards |

---

## 7. UNCONFIRMED / not found

- 2025–26 splash/launch screen.
- The second landing button's copy and the tiny landing link.
- The password step after "Enter Your Email" (2026).
- Body copy of:
  - "Let's Get Started";
  - "Enter Your Email";
  - "Unbox Your Device";
  - "Create Your Account";
  - "Where Do You Live?";
  - "What's Your Birthday?";
  - "Choose a Gender";
  - "Turn on Push Notifications";
  - the referral screen;
  - "What to Expect Next";
  - the membership-offer cards.
- Labels of the Gender options; whether a separate "physiological baseline" question follows.
- Height / weight / units screens in first-run.
- iOS Bluetooth-access, notification and Health permission sheets as rendered. The custom pre-permission screens are confirmed.
- Any location/GPS permission in first-run.
- A firmware "update available" pop-up during or after setup.
- The journal/behaviour setup screen itself (only the Get Started entry card is confirmed).
- The "Getting Started" / "Your First 4 Days" checklist UI under More.
- The Home "Customize Your WHOOP Experience" 6-step Get Started tutorial widget (2025-10; text-only evidence).
- Exact push transition and arc-growth animation timing.
- The final-step label ("DONE" vs "FINISH").
- Default tick state of Privacy rows 1 and 4.
- Android differences beyond those noted: back arrow "←", teal pills, "?" icon on the device list.

---

## 8. Build notes for ZENO (recommendations, not WHOOP facts)

ZENO has no account, server or membership. To mirror WHOOP's first-run **structure** with honest content:

1. **Landing**: photo + wordmark + white "I HAVE A WHOOP DEVICE" + outlined "EXPLORE WITHOUT A STRAP" (demo data).
2. **Device sub-flow**, cloned 1:1: Unbox (filled circle "GET STARTED") → Put On (ring) → Wake Up (charger animation, ring) → Check for Pairing Mode (LED pulse, filled "START PAIRING") → SEARCHING FOR STRAP... → SELECT YOUR DEVICE (rows show the serial or custom name) → CONNECTING (dotted blue line) → CONNECTED (green ✓, "CONTINUE") / CONNECTION FAILED (white "RETRY" + "NEED MORE HELP?"). ZENO's existing add-device wizard is the engine.
3. **Profile**, as WHOOP-template steps with the ring: Welcome (first name; username not needed) → Where Do You Live? (country → units default; state optional) → Connect To Apple Health ("SKIP" / "CONNECT") → What's Your Birthday? (wheel) → Choose a Gender + physiological baseline → **height and weight**. Keep these even though WHOOP's 2025 run skipped them: ZENO needs them for strain and calories when Apple Health has none.
4. **Privacy & data**: reuse the checkbox screen with local-first statements (e.g. "My data stays on this iPhone"). Keep "SELECT AND AGREE TO ALL" and the white/grey checked/unchecked text rule.
5. Skip the card form, membership offer and referral. Optionally show a "Setting up your Account..." spinner while the first sync runs.
6. Turn on Push Notifications (pre-permission) → Welcome splash → What to Expect Next (calibration wheel tied to ZENO's real calibration thresholds) → Home in Day-1 state ("--%" dials + Get Started cards: charge, sleep schedule → Alarms, journal, first activity, integrations).
7. Use the measured ring spec (§3): progress = step index / total steps of the profile sub-flow.

---

## 9. Image index (`images/onboarding/`)

| File(s) | What |
|---|---|
| 02a/02b/02c | Landing (2025-05, 2025-06, WHOOP 2026-08) |
| 03a/03b | "Let's Get Started" login (2025) |
| 03c | "Enter Your Email" (2026) |
| 04 | Pre-delivery "Your WHOOP is on the way!" (2025) |
| 05a/05b | Unbox Your Device |
| 06a/06b | Put On Your WHOOP |
| 07a/07b | Wake Up Your WHOOP (onboarding) |
| 07c | "Wake up your WHOOP" (in-app re-pair, hi-res) |
| 08a–c | Check for Pairing Mode |
| 09a/09b | SEARCHING FOR STRAP... (09b hi-res) |
| 10a–f | CHOOSE A DEVICE / SELECT YOUR DEVICE (10f hi-res) |
| 11a–d | Bluetooth Pairing Request + CONNECTING |
| 12a–d | CONNECTED (12d clear thumbnail) |
| 13a–e | CONNECTION FAILED 2025 → 2026 (hi-res) |
| 13f | SOMETHING WENT WRONG |
| 14 | Create Your Account |
| 14b | Password rules (Android FR) |
| 15a/15b | Welcome to WHOOP! (15b hi-res, username taken) |
| 16a–c | Where Do You Live? / Which State |
| 17 | Connect To Apple Health |
| 18 | What's Your Birthday? |
| 19 | Choose a Gender |
| 20a–d | Card form (20b–d hi-res, 3 copy variants) |
| 21 | Family Plan Not Activated (green filled circle) |
| 22a–d | Privacy and Terms of Use (22b–d hi-res; 22d with SELECT AND AGREE TO ALL) |
| 23 | Setting up your Account... |
| 24a–c | ERROR / RETRY / CLOSE; Android server nap |
| 25 | Membership offer (1 MONTH FREE vs JOIN TODAY) |
| 26 | Turn on Push Notifications |
| 27 | Gift friends referral |
| 28 | Welcome to WHOOP splash |
| 29a/29b | What to Expect Next |
| 30a–c | First Home 2025, Day-1 Home thumbnail, More/Device Settings after setup |
| 31a–e | Get Started cards 2025-11 → 2026-09 |
| 32a–e | Calibration states (32d: 2025-05 "FIRST WEEK WITH WHOOP", "SLEEPS LOGGED 0/7"; 32e: "UNLOCK HEALTHSPAN" day-20 bar) |
| 33a/33b | Tour cards (New Look, Coach at Your Fingertips) |
| 40 | UPDATE REQUIRED |
| 41 | Firmware NO NEW UPDATES |
| 42 | MFA setup |
| 43a/43b | Device Settings disconnected → PAIR A DEVICE; unpair "ARE YOU SURE?" |
| 44a–e | Upcycle trial, REJOIN WHOOP, MEMBERSHIP EXPIRED states |
| 45 | Feature-intro button system (GET STARTED filled → NEXT ring → green ✓) |
| 46a/46a2/46b | WHOOP official pairing instruction sheets (2025-05, 2026-08) |
| 90-00 … 90-14 | Legacy 2024 Mobbin onboarding flow (15 screens, legible copy) |

Files named "copy-of-…" duplicate images already found by other agents (completeness-critic, help-center, reviews,
whoop-site), so this folder holds the whole sequence in one place.

---

## 10. Sources

**YouTube** (storyboards via playerStoryboardSpecRenderer; thumbnails via i.ytimg.com):

| Video | Date | Content | Used? |
|---|---|---|---|
| https://www.youtube.com/watch?v=DKVm1OmWkdk | 2025-05-11 | **full new-account flow** | yes |
| https://www.youtube.com/watch?v=oVQ3B3gxfSg | 2025-06-26 | login → tutorial → pairing → location → What to Expect Next | yes |
| https://www.youtube.com/watch?v=RskQ9qQEt3U | WHOOP, 2026-08-06 | "How to Pair Your WHOOP Device" | yes |
| https://www.youtube.com/watch?v=-kBbgM5IIxo | WHOOP, 2025-05-12 | "How to Wake Up and Pair Your WHOOP Device with the App" | yes |
| https://www.youtube.com/watch?v=1bXFMHXz8rE | 2025-08-02 | existing member pairs via Device Settings; trade-in screen | yes |
| https://www.youtube.com/watch?v=_ECWfsHaiu0 | 2026-06-04 | SELECT YOUR DEVICE, unpair, connected thumbnail | yes |
| https://www.youtube.com/watch?v=wS84PwWWx9c | 2025-05-22 | upgrade pairing; Healthspan/BP intro button system | yes |
| https://www.youtube.com/watch?v=fycJc11foBI | 2025-05-29 | Day-1 Home | yes |
| https://www.youtube.com/watch?v=NrCpf_m75XM | – | sheet M0 starts on an already set-up Home | no onboarding shown |
| Pk0iiaE57Ho, kQF1LubueeU, mlKWSoUsBcs | – | stock footage / general tutorial / text slides | nothing usable |

**community.whoop.com topics** (`/t/ID.json`, original uploads): 8956 ("Customize Your WHOOP Experience" tutorial),
15455 (gender → card order), 114, 1085, 2370, 7434, 7679, 7892, 8408, 9193, 9287,
10053, 10405, 10666, 11209, 11350, 11997 (Amazfit screen, not WHOOP), 12915, 13341, 13573, 14323, 14409, 14714, 14811,
14859, 14863, 14870, 14874, 14917, 15101, 15105, 15134, 15270, 15311, 15317, 15382, 15461, 15464, 15480, 15488, 15550,
15563, 15568, 15570, 15572, 15705, 15771, 15773, 15886, 15895, 15949, 16100, 16126, 16367, 16370, 517, 854.

**Reddit** (RSS `q=first day | new user | just got my whoop | setup | pairing`; i.redd.it originals):
- 1wid73f (Get Started cards);
- 1u6qptl (Unlock New Potential);
- 1vryrl3 (first day, Health Monitor);
- 1wikv1y (VO₂ Max unlock);
- 1ul7ddi (UPDATE REQUIRED);
- 1ug1l5u (membership expired after setup);
- 1u7ga1p (setup error after card + terms);
- 1whppro (trial pricing choice);
- 1uppd0g (free-trial cancel);
- 1t5w35d (sign-out unlinks device);
- 1kiml3v (2025-05 "FIRST WEEK WITH WHOOP" card);
- 1vwhrpr ("Select a Membership Plan", dormant membership);
- 1pow2g3 (upgrade has no walkthrough);
- 1i87z05 (2025-01 profile and card asked again);
- 1w82b80 (day-20 "UNLOCK HEALTHSPAN").

The second batch (`q=onboarding`, then get started, activate, free trial, calibrating, firmware, apple health,
username, terms, notifications) was still being throttled when this note was written. Only "onboarding" and
"get started" returned in time.

The "pairing" query returned an empty feed. Reddit RSS was heavily rate-limited (HTTP 429, at best 1 request per
~3 min).

**Mobbin** (public flow page, published 2024-04-09): https://mobbin.com/explore/flows/06390f2f-8598-4b94-88f5-0bcb7b65ece4

**Help-center texts** (`raw/help-center-articles/`):
- Your-First-4-Days (8/13/2026);
- Calibration-Timeline (4/23/2026);
- Updating-Your-Profile-Information (10/8/2025);
- Multi-Factor-Authentication-MFA (5/26/2026);
- WHOOP-3-0-and-4-0-How-to-Update-Your-Product-s-Firmware (6/10/2025);
- Apple-Health-Integration (4/16/2026);
- Gifting-a-WHOOP-Membership;
- Family-Membership;
- Resolving-WHOOP-App-Errors-Crashes;
- WHOOP-App-Minimum-Software-Requirements (8/25/2026).
