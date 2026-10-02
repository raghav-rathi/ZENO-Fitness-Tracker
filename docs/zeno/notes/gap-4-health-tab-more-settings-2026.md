# GAP 4: 2026 Health tab below HEALTH MONITOR, the Home Menstrual/Pregnancy card, and the 2026 More tab with the App Settings subtree

Research date: 2026-10-02. Gap-fill agent "health-tab-more-settings-2026".
Images are in `../images/health-more-2026/` and are a private local reference only; never commit them.

Read these first: `reviews.md` §3.12–3.13 and §3.21, `help-center.md` §11 and §16, and `WHOOP_UI_SPEC.md` §3.20, §3.24–3.26, §3.31 and §3.33. This file adds only what those leave open.

## Evidence labels

| Label | Meaning |
|---|---|
| **CONFIRMED** | Seen in a full-resolution 2026 screenshot. |
| **LOW-RES** | Seen only in YouTube storyboard frames (83×180 px portrait screen recording, or a ≈75×170 px phone inset). Layout, order, colour blocks and label lengths are reliable. Individual words are read only where they match a known WHOOP label. Exact digits are not reliable. |
| **TEXT** | Described by WHOOP or by users in words; not seen. |
| **UNCONFIRMED** | Inferred or conflicting. Do not treat it as fact. |

Scale: "pt" means iOS points on a 393 pt wide iPhone. 3x screenshots are divided by 3. One storyboard pixel is about 4.7 pt.

## Summary

1. **Health tab below HEALTH MONITOR, 2026.**
   - Peak (Jul 2026, LOW-RES): HM → **MENSTRUAL CYCLE INSIGHTS** → **STRESS MONITOR** → **"Upgrade to Access"** upsell (MG photo card with ✕).
   - Life/MG (Aug 2026, CONFIRMED by `r44` bleed-through): HM → **BLOOD PRESSURE INSIGHTS** → … → **HEART SCREENER** (ECG). Users report freezing "below blood pressure" before reaching ECG.
   - US Peak new user (Aug 2026, TEXT): 5 cards incl. Advanced Labs and **Connect your Health Records**.
   - Health Record Analysis exists (Locker: four categories; Integration Details has refresh and disconnect) but no screenshot is public.
   - The clinician consult has no public sighting.
   - At scroll 0 the orb is shown **whole**; the half-sphere is the scrolled state.
   - New-member **"UNLOCK HEALTHSPAN · N more days"** card with a purple dormant orb (CONFIRMED, image `16`).
2. **Home Menstrual card.**
   - LOW-RES, Jul 2026: it sits **after MY JOURNAL and before My Plan**, not last as the WHOOP Locker text says.
   - Layout: "Day N", phase name in lavender, a prediction line, a coral→purple **dot strip** with today larger, and "+ LOG CYCLE".
   - The Health-tab version uses a gradient bar instead of the dot strip.
   - No Pregnancy card was seen; the product name is now "Pregnancy & Postpartum Insights".
3. **More tab, 2026.**
   - Order: carousel → REFER card(s) → SHOP & GIFT (list rows, or product cards for some users) → ACCOUNT & SETTINGS (MY ACCOUNT, DEVICE SETTINGS, APP SETTINGS, PRIVACY SETTINGS) → SUPPORT (MEMBERSHIP SERVICES, TUTORIALS, a 5-letter row, FIRST WEEK WITH WHOOP) → outlined LOGOUT → app version.
   - "DIGITAL WHOOP LABS" is gone.
   - App Settings is a "✕" page of 9 single-line rows (labels illegible; see the candidate mapping).
   - Integrations: Apple Health featured card, then connected and recommended lists → a partner **INTEGRATION DETAILS** page (Peloton, CONFIRMED) → Apple Health page with a green Connect button.
   - EXPORT WHOOP DATA modal (CONFIRMED top); Membership & Billing and Setup MFA (CONFIRMED).
   - Hide Metrics, Notifications, AI Settings (the Coach can no longer be disabled), Coaching Mode, Privacy, Tutorials: text only.
   - Getting Started checklist: 6 tasks (HC 2026-08-13).

---------------------------------------------------------------------------------------------------

## 0. Sources and what each one gave

| # | Source (all public, no login) | Date | Gave |
|---|---|---|---|
| A | **YouTube `V3rewDUPcjo`** "Whoop 5.0 app screen recording 2026 summer" (BarefootBasil). Full-screen portrait screen recording, 4:08. Storyboard L3 is 126 frames of 83×180 px, one every 2 s. | published 2026-07-23 | **The key source.** It shows a full Health tab scroll including the lower cards, Home's lower half including the Menstrual card, the Menstrual Cycle Insights page, and the More tab down to LOGOUT and the app version. The account is WHOOP 5.0 on **Peak** (no Life cards; it shows a Life upsell) with Menstrual Cycle Insights on. The region is probably not the US: there is no Health Records card. That is **UNCONFIRMED**. |
| B | **YouTube `Cn-VsRG9gYM`** "HOW TO CONNECT WHOOP TO APPLE HEALTH 2026!" (GuidePulse). A phone screen inset over a desktop video. Storyboard: 51 frames at 1 s. | published 2026-09-13 | More tab top and middle (Sept 2026), the **App Settings** list (9 rows), **Integrations**, and the **Apple Health** connect page. LOW-RES. Static frames were averaged (frames 16–19, 24–27, 30–32, 35–38, 40–45) to reduce noise. |
| C | **YouTube `NrCpf_m75XM`** "FULL WHOOP App Walkthrough (2026 Update)". All 14 L3 sheets were checked, not only M11–M13. | ≈May 2026 | Sheets M11–M13 show the Health tab **top only**: the orb "23.1 WHOOP AGE" as a **full** green blob, PACE OF AGING with GO TO HEALTHSPAN, and the ADVANCED LABS promo card with a test-tube ring. Sheet M12 also shows Community › Teams. The video never scrolls below Advanced Labs and never opens More or settings. |
| D | Reddit r/whoop RSS search: health tab, heart screener, blood pressure, health records, healthex, cycle insights, period, pregnancy, more tab, settings, notifications, integrations, natural cycles, hide metrics, export, menstrual, ECG, "upgrade to access". The shared rate limit (many agents on one IP) kept answering 429, so "hormonal", "stress monitor", "clinician", "app settings", "pregnancy insights", "tutorials" and "first week" could not all be fetched; see §7. | — | `r44` bleed-through, the BP v2.0 page, the EXPORT WHOOP DATA page, Peloton INTEGRATION DETAILS, the MCI disclaimer card, and many dated user statements (quoted below). |
| E | WHOOP Community forum (`community.whoop.com` search.json with images and order:latest, plus t/ID.json) | — | Membership & Billing (Sept 2026), SETUP MFA (Apr 2026), Home notification-feed error (May 2026), the "5 widgets" statement, AI-settings and Hide-Metrics statements, and the 2025 More list (geometry calibration). |
| F | Already in the repo: `raw/help-center-articles/HealthEx-Integration.txt` (published 2026-05-28), `reviews/r05`, `r07`, `r44`, `r06`, `r47`, `r115`, and `whoop-site/11b`, `59` | — | Wording for HealthEx; the More-tab top for a new user; the Health tab top. |
| G | HealthEx press page, the WHOOP Locker Natural Cycles article (via r.jina.ai), and Android Authority / tbreak Natural Cycles articles | Jun–Aug 2026 | Text only. Their images are logos or the **Natural Cycles** app (not WHOOP UI), so none were kept. |

Searched with nothing usable found: YouTube `f_AzJnnB53c`, `uS6BrQrBiGo` (phone too small), `QonEp82rbNI` (slideshow), `rVW4EXkHoyw` (desktop dashboards), `0fKn3IjIrVU`, `9A7wjAgac40` (Device Settings only), `6KzScHrpbQk` (podcast), `dB_D5jWr7Mo` (Jan 2025, old UI). As instructed, support.whoop.com articles were skipped: they render with JS and have no inline UI images.

---------------------------------------------------------------------------------------------------

## 1. Health tab (2026) below HEALTH MONITOR

### 1.1 Observed orders

**Variant A: Peak, WHOOP 5.0, Menstrual Cycle Insights on, July 2026.** LOW-RES; source A, frames 94–121. Images `02`, `03`.

1. "HEALTH" (centred caps nav title). It stays pinned while scrolling, over a **green glow** (sampled from the low-res frames as `#0B4E2F`–`#185B3C` at the top; the orb is green at "34.5 WHOOP AGE").
   - **New detail:** at scroll 0 the WHOOP-Age orb is shown **whole**: a full irregular speckled blob about 200 pt wide holding "34.5 / WHOOP AGE / 7.x years younger" (frames 94 and 95, and sheet M11 of source C).
   - It moves up behind the title as you scroll, which gives the cropped "half-planet" look seen in `r07`, `r44` and the Android Police photo (frame 107).
   - So the half-sphere in `WHOOP_UI_SPEC.md` §3.20 is a **scrolled** state.
2. PACE OF AGING card. The chip at the right is orange here. Full-width "GO TO HEALTHSPAN".
3. ADVANCED LABS card (results variant: three counts, a ring "44 BIOMARKERS ›", and a last-updated line).
4. HEALTH MONITOR card (RESP · SPO₂ · RHR · HRV · TEMP, then "5/5 metrics within range").
5. **MENSTRUAL CYCLE INSIGHTS card** (§1.2a). It sits directly under Health Monitor.
6. **STRESS MONITOR card** (§1.2b).
7. **"Upgrade to Access"**: a sentence-case section header, then a dismissible upsell photo card (§1.3).
8. Anything below this was not captured. The recording jumps to Community at frame 122. Whether a disclaimer follows is **UNCONFIRMED**.

**Variant B: Life with MG, probably US, Aug 2026.** CONFIRMED: `reviews/r44` plus the enhanced crop `13-…`.

- Order: …ADVANCED LABS → HEALTH MONITOR → **BLOOD PRESSURE INSIGHTS**. That card's caps title shows through the frosted tab bar right under the Health Monitor card (image `13`).
- TEXT, Reddit 2026-02-18, new MG user: "I am unable to get to the **ECG section** on the health tab as it freezes any time I try to **scroll past the blood pressure option**." So **Heart Screener comes after Blood Pressure Insights**.
- TEXT, Reddit 2026-06-07, MG: "can't scroll past a certain post". This matches the same freeze.
- TEXT, forum topic 10961 "App freezes on specific page", Nov 2025 → Jul 2026. This is the same long-running iOS bug, and it confirms the order again:
  - "I cannot scroll **below blood pressure** on the Health tab" (2026-02-18);
  - "the Health page and cannot scroll down to the **ECG section**" (2026-05-18, "app version 5.52.0 build 595097");
  - the first reporter (Nov 2025, WHOOP 5.0) was "enrolled in this **blood pressure study**", so 5.0 users in the BP study also get the BP card.

**Variant C: Peak, new user, Aug 2026.** TEXT, forum topic 15753, "40% of the Health tab feels like bloat", 2026-08-05.

> "New user here (5 nights in) and I find it unproductive to have 2 of the 5 widgets on the Health tab to be additional services (advanced labs and connect your health records). We should have the ability to remove these or move them to the bottom. … pull Live Heart Rate out of Health Monitor…"

- So this tier has **5 cards**: Healthspan/Pace, Advanced Labs, Health Monitor, Stress Monitor, and **Connect your Health Records**. The fifth is inferred, since Peak has no BP or ECG.
- "Move them to the bottom" implies **Connect Health Records is not last**. Its exact slot is **UNCONFIRMED**.
- Live HR is **not** a root card for Peak and Life in 2026. It sits inside Health Monitor.

**Variant D: WHOOP ONE.**
- TEXT, Reddit 2026-07-10: "…when I go through the actual health tab from the bottom, **the page says that I don't have access to this feature**." Yet the Home "health monitor calibrated" card still opens Health Monitor.
- The last full screenshot of a ONE Health tab is from Oct 2025 (image `01`). It reads, top to bottom:
  - "HEALTH" nav title;
  - **"More to unlock"** (sentence-case white header, about 22 pt semibold);
  - an Advanced Labs card: lifestyle photo with the segmented ring and "WHOOP" in it, the "WHOOP ADVANCED LABS" lockup, a hairline, a centred grey body, a green chip "✓ You're on the waitlist.", and a grey "LEARN MORE" button;
  - a hairline, then the disclaimer paragraph.

**Best-fit 2026 model** (UNCONFIRMED where variants do not overlap). Use this order and hide cards the member's tier, region or settings exclude:

```
HEALTH title + orb (full at rest, collapses on scroll)
[Healthspan calibrating banner ✕]                      (r07, AP photo)
PACE OF AGING  + GO TO HEALTHSPAN     | or, before unlock: purple dormant orb +
                                      |  "UNLOCK HEALTHSPAN · N more days" progress card (image 16)
ADVANCED LABS  (results | promo "GET STARTED →" | waitlist)
HEALTH MONITOR
BLOOD PRESSURE INSIGHTS          Life + MG only (r44)
HEART SCREENER                   Life + MG only, after BP (Reddit Feb 2026)
MENSTRUAL CYCLE INSIGHTS / PREGNANCY & POSTPARTUM INSIGHTS   if Hormonal Insights is on
                                 (directly after HM when no Life cards; its
                                  position relative to BP/ECG is UNCONFIRMED)
STRESS MONITOR
CONNECT HEALTH RECORDS / HEALTH RECORD ANALYSIS   US 18+; slot UNCONFIRMED
"Upgrade to Access" + upsell card(s)               non-Life members (A)
disclaimer paragraph                               (2025 pattern; 2026 UNCONFIRMED)
```

### 1.2 Card specifications

**a) MENSTRUAL CYCLE INSIGHTS card (Health tab).** LOW-RES; frames 119–121; image `03`.
- Card about 180 pt tall. Background about `#2A2E31`–`#2E3138` (sampled low-res). Standard radius (≈12 pt).
- Header row: "MENSTRUAL CYCLE INSIGHTS" (card-title caps) and "›" at the right.
- Left: a small caps label (unreadable; probably the phase or "CYCLE DAY") over **"Day 21"** (≈22 pt semibold white).
- Right, at the height of "Day 21": a **horizontal gradient bar** about 45% of the card wide. It runs from muted coral through lavender (sampled low-res `#776E89`, `#65638B`) to a **round white end-marker** for today. A tiny green/white tick sits under the marker.
- Footer: a full-width grey button **"+ LOG CYCLE"** (centred caps; ≈40 pt tall; background ≈`#41444B`).
- This differs from the Home version (§2), which uses a dot strip.

**b) STRESS MONITOR card (Health tab).** LOW-RES; frame 121.
- Same structure as the 2025 card.
- Left column:
  - title "STRESS MONITOR ›";
  - a caps label of about 18 characters (fits "TODAY'S HIGH STRESS");
  - a large **h:mm** value (reads "0:44" or "8:44"; digits not reliable) with a small unit;
  - below that, an **orange** delta chip ("▲ vs. typical …"; wording not readable).
- Right half: a spiky 24-hour stress sparkline in teal-green with a **white dot** at "now".
- Height ≈ 150 pt.

**c) BLOOD PRESSURE INSIGHTS card (Health tab, 2026).**
- The title is CONFIRMED (r44). The body is **not seen in 2026**.
- 2025 card for reference: "BLOOD PRESSURE INSIGHTS [BETA V1.0] ›", "TODAY'S READING 129/73", a mini range chart.
- The BP **page** in 2026 is "**BETA V2.0**". CONFIRMED in image `10`, 2026-04-05:
  - nav "‹ BLOOD PRESSURE INSIGHTS";
  - a "BETA V2.0 ⓘ" chip (`#3C4044`);
  - a gauge drawn only as **two end arcs**: green at the left (`#6CEBA2`) and orange at the right (`#F0A846`);
  - the centre value **greyed** (`#60686C`) when there is no estimate today, "126/77";
  - "SYSTOLIC 116-136 mmHg | DIASTOLIC 72-82 mmHg": labels `#B8BCC0`, values `#FCFCFC`, unit `#8C9094`;
  - a segmented control **W | M only** (container `#121619`, selected segment `#2A2E31`) and the pager "‹ MAR 07 - APR 05, 26 ›";
  - legend "— MANUAL READING ▬ WHOOP ESTIMATE";
  - the chart: "Highest" (orange text `#DCAC70`) and "Lowest" (green text `#7CD4A8`) guide lines; per-day range bars `#2B2F32` on `#15181D`; WHOOP estimate dashes yellow `#FCEC78`; manual readings green `#6CECA4`.
  - Page gradient: `#252C34` at the top, `#181D21` mid, `#111516` at the bottom.
- TEXT, forum 16290, 2026-09-21: saving a manual BP reading **requires 3 readings**.
- TEXT, Reddit 2026-05-08: "a **Blood Pressure tile in the health monitor**" appeared for some MG users (beta).
- TEXT, forum 16189, 2026-09-10: users ask to hide BP. Hide Metrics has **no BP option**.

**d) HEART SCREENER card (2026 look).** From WHOOP's 2026 "What's new" collage (`whoop-site/11b`):
- "HEART SCREENER" with "TAKE AN ECG ›" at the right;
- "LAST ECG REPORT" (caps, grey);
- "Normal Sinus Rhythm" (≈20 pt white);
- a green chip "✓ Jan 14, 2024 - 7:42am";
- a grey 3-D heart illustration at the right.

The 2025 home-feed variant ("AFib not Detected · In the last 24 hours · ✓ BACKGROUND SCREENING | ✓ ECG REPORT") is in `help-center/100`. Its 2026 position is after BP (§1.1 B).

Heart Screener sub-screens seen in this pass:
- **Page, Dec 2025** (image `15`): "‹ HEART SCREENER", "Electrocardiogram (ECG) ⓘ", a purple "+ TAKE A NEW ECG READING" row, the last-report card with trace and four ✓ rows, "ALL ECG REPORTS ›", then "Irregular Heart Rhythm Notifications ⓘ" with body text and a new status card "**HEART NOTIFICATIONS ACTIVATED** / AFib detection runs automatically in the background and notifies you when possible atrial fibrillation is detected." (grey dot tile at the left).
- **"ECG READING FAILED" modal, 2026** (image `14`, Jul 2026; the same modal appears in Reddit posts of Apr and May 2026):
  - a centred dialog card, fill `#283339`, radius ≈16 pt, over the recording screen dimmed to ≈`#030406`;
  - title in white bold caps; body `#BCC0C4` "Something is interfering with your ECG. Try one of these tips:", then three numbered tips (seated and relaxed with arms on a table; quiet, still place; no hair, jewellery or clothing under the electrode);
  - a white filled capsule "LEARN MORE" (black text), then an outlined capsule "TRY AGAIN" (border `#484C50`);
  - behind it, the screen's own outlined "RETRY" capsule.

**e) CONNECT HEALTH RECORDS / HEALTH RECORD ANALYSIS (HealthEx).** TEXT only; no screenshot anywhere.
- Entry wording, from the HC article 2026-05-28:
  - Health tab card: "**Connect Health Records**";
  - settings path: More › App Settings › Integrations › HealthEx › "**Connect with HealthEx**", with "Connect Records" also used.
- Flow:
  1. A secure redirect to HealthEx (web).
  2. Optional **CLEAR** identity check (government ID plus selfie), or a manual provider search.
  3. The member picks providers and grants permission.
  4. The last button reads **"Share my records"** (Reddit 2026-06-11: "on last screen on pressing 'Share my records' nothing happens").
  5. Records sync in 10–30 min. The member gets an **in-app WHOOP notification**, and HealthEx emails a PDF.
- Afterwards:
  - WHOOP shows a "**Health Record Analysis**", a snapshot of the record data now in the coaching context (WHOOP and HealthEx press, 2026-06-17);
  - manual refresh **once per day**; automatic refresh every 30 days; disconnect any time.
- Rollout: "Healthex rolling out … Was able to connect today" (Reddit 2026-06-10).
- Eligibility: US members, 18+, WHOOP 4.0, 5.0 or MG, every tier (One, Peak, Life).
- WHOOP Locker "How to connect and use your medical records in the WHOOP app" (2026-06-17, read via r.jina.ai; text only, no images):
  - "The integration lives in the **integrations tab in the App Settings section** … HealthEx listed as an available connection."
  - "WHOOP builds your **Health Record Analysis**: a snapshot of the health record information now available to your coaching context. The **Integration Details** screen shows what's connected, lets you **refresh** to get the latest records, and gives you the option to **disconnect**."
  - "The Health Record Analysis screen in the app shows exactly what came through", in **four categories**: **Conditions and diagnoses**; **Medications** (current and historical, with prescribed dates); **Procedures**; **Lab results** (bloodwork from provider visits).
  - The records also feed **WHOOP AI** answers and **My Memory**.
  - So the partner detail page (§4.3 template) gains a REFRESH action next to DISCONNECT, plus a link or section into Health Record Analysis.
- Card visuals (icon, copy, connected state) and the Health Record Analysis layout: **UNCONFIRMED**. No screenshot exists publicly as of 2026-10-02.

**f) Clinician consult entry.** **NOT FOUND.**
- Announced 2026-05-08 (WHOOP press and the Reddit "WHOOP Updates (5/8)" post): "a new paid add-on service: on-demand video consultations with a clinician fluent in your sleep, activity, bloodwork, and medical records", launching in the US "this summer".
- No 2026 screenshot, Reddit post or forum post up to 2026-10-02 shows an in-app entry. Whether it has launched, and where its entry sits, is **UNCONFIRMED**.

**g) Disclaimer.**
- 2025, CONFIRMED (image `01`): a hairline `#28282C`, then a left-aligned paragraph about 15 pt in `#B4B4B8`, bottom of the scroll. The ONE-tier wording: "Health Monitor, and Stress Monitor are not medical devices and cannot diagnose or manage medical conditions. These features do not provide medical advice. Always consult your doctor for health concerns and never delay or modify medical care based on these features."
- The Life wording begins "The Heart Screener features — ECG and IHRN — are medically regulated features. Healthspan, Health Monitor, Blood Pressure Insights, and Stress Monitor are not medical devices…" (`reviews.md` §3.12).
- 2026: not captured. Assume the same pattern (**UNCONFIRMED**).

### 1.3 Locked and upsell variants

| Variant | Evidence | Look |
|---|---|---|
| **"Upgrade to Access"** (Peak, non-Life) | LOW-RES, frame 121, Jul 2026 | A section header in sentence case, left-aligned, ≈22 pt semibold white (same style as "My Day", "My Plan" and "More to unlock"). Below it a large **photo card** (≈360×250 pt, radius ≈12) with a dark close-up of the **WHOOP MG sensor** (green LEDs), a small **✕** dismiss at top-right, and a text block at the bottom (unreadable). Probably the Life upsell (Heart Screener / BP). Whether it is a carousel is UNCONFIRMED. |
| **"More to unlock"** (ONE) | CONFIRMED, Oct 2025, image `01` | Described in §1.1 D. Chip background `#0E362D` with text `#00F0A0`. LEARN MORE button `#282C2F` with white caps text. Card body `#13161B`–`#0F1417`. Body text `#B4B8BC`. |
| ONE in 2026 | TEXT, Jul 2026 | "the page says that I don't have access to this feature". Wording and visual UNCONFIRMED. |
| **Healthspan still unlocking (2026)** | CONFIRMED, image `16`, Reddit 2026-07-16 (Spanish UI, 20-day trial member) | The page top gets a **purple glow** (top-right `#4B2151`, top-left `#0A0A0C`). The orb is a **grey "dormant" blob** (interior `#54585B`) with magenta speckles (`#9854A4`) and a **magenta rim** (`#C050D0`); the "years younger/older" text is absent. Under the orb, a card (fill `#1C1A27`, gradient border warm `#604844` at the left to violet `#AC28FC` at the right, open/faded at the top so the orb sits in it) carries "**DESBLOQUEA HEALTHSPAN**" (= "UNLOCK HEALTHSPAN", white bold caps ≈13 pt), "2 días más para desbloquear tu Healthspan personal." (= "2 more days to unlock your personal Healthspan."; `#B8B8BC` ≈15 pt), and a **progress bar** (≈4 pt, rounded, magenta `#C450D4` fill on `#4C4857` track). There is no PACE OF AGING card. Next comes the ADVANCED LABS promo (gradient `#2B2F32`→`#23735A`, CTA "EMPEZAR →" `#64ACE8`), then HEALTH MONITOR. English strings are translations (UNCONFIRMED). |
| Healthspan locked (fewer than 21 sleeps in a month) | 2025, `reviews.md` §3.12 | "Keep wearing WHOOP consistently. Log 21 sleeps in a month to unlock Healthspan." with blurred content and "LIFE \| PEAK" labels. Superseded in 2026 by the unlocking card above. |
| Advanced Labs not tested | `r07`, AP photo 6 | Teal-gradient promo "Get deeper health insights, adding your lab results from doctor visits with your 24/7 WHOOP data. GET STARTED →" with a test-tube-in-ring illustration. |
| Calibrating | `r07` | Blue translucent banner with hourglass and ✕ (`WHOOP_UI_SPEC.md` §3.20 item 2). |
| Membership expired (Home, for context) | Reddit 2026-06-26 (not saved; Home scope) | A red "! MEMBERSHIP EXPIRED / Click here to reactivate your membership ›" banner card. The Home HEALTH MONITOR and STRESS MONITOR tiles show a grey placeholder icon and "No Data Available". |

---------------------------------------------------------------------------------------------------

## 2. Home Menstrual / Pregnancy card

### 2.1 Position. **WHOOP's text and the 2026 capture disagree.**
- The WHOOP Locker "WHOOP Home screen: what's on it and how to customize it" (`thelocker/the-all-new-whoop-home-screen`, current text read via r.jina.ai on 2026-10-02) lists "from top to bottom":
  - Streak and device status;
  - three dials;
  - My Day;
  - My Plan;
  - My Dashboard;
  - "**Stress Monitor trend:** On memberships that include Stress Monitor";
  - "**Menstrual Cycle Insights or Pregnancy & Postpartum Insights:** If you have opted in. These are available on every membership" (last).
- Note the 2026 product name "**Pregnancy & Postpartum Insights**".
- The same article says "If you are on WHOOP One or Peak, features outside your membership appear **greyed out** in the Health tab". That matches the "Upgrade to Access" block (§1.3).
- **Observed in Jul 2026** (LOW-RES; source A, frames 63–65, 81, 85–93):

```
… TODAY'S ACTIVITIES card (ADD ACTIVITY | START ACTIVITY)
→ TONIGHT'S SLEEP card
→ MY JOURNAL card
→ MENSTRUAL CYCLE INSIGHTS card          ← here, NOT at the end
→ "My Plan" header + "Build Your Best Self" plan card
→ "My Dashboard" header + CUSTOMIZE ✎ → metric rows (HRV 43, SLEEP PERFORMANCE 92%, STEPS 11,431, CALORIES…)
→ STRESS MONITOR chart card → STRAIN & RECOVERY weekly chart card
→ more rows (RESPIRATORY RATE 18.2, LEAN BODY MASS ›, RESTORATIVE SLEEP (%) 59%, VO₂ MAX 41)
→ "Discover More" header + 4 promo rows → small centred "WHOOP" footer wordmark
```

- The "Discover More" rows match `reviews/r47` (Spanish "Descubre más"). Each row has a square photo thumbnail, a title, a grey body, and a blue caps CTA with an arrow. r47 Spanish, with literal translations; the **English strings are UNCONFIRMED**:
  - "Realiza pruebas con Advanced Labs … IR A ADVANCED LABS →" (≈ go to Advanced Labs);
  - "Actualizar a WHOOP Life … VER OPCIONES DE ACTUALIZACIÓN →" (≈ see upgrade options);
  - "Explorar la tienda de WHOOP … IR A LA TIENDA →" (≈ go to the store);
  - "Regala WHOOP … ELEGIR UN REGALO →" (≈ choose a gift).
  - The English row titles in source A read approximately "Test with Advanced Labs", "Upgrade to WHOOP Life", "Explore the WHOOP Store" and "Give the Gift of WHOOP" (LOW-RES).
- **ZENO choice:** put the Hormonal card after My Journal, as observed in 2026. The Locker order is older text.

### 2.2 Menstrual card layout (Home)
LOW-RES; frames 64, 65, 81; image `04`.
- Card about 220 pt tall, background ≈`#2F3239`.
- Header "MENSTRUAL CYCLE INSIGHTS" with "›".
- **"Day 21"** (≈24 pt semibold white). Under it the **phase name in lavender** (small, e.g. "Luteal Phase"; wording UNCONFIRMED).
- One grey sentence line (prediction text, e.g. "period expected in …"; unreadable).
- A **dot strip**:
  - one small dot per cycle day (≈28) across the card;
  - the first dots coral/red (menstrual days), then lavender/purple;
  - today is a larger white dot;
  - under the strip, 7 small grey day numbers spaced evenly (like 1 · 7 · 14 · 21 · 28).
- Full-width grey button "**+ LOG CYCLE**" (≈40 pt, radius ≈8, background ≈`#41444B`).
- Tapping the card opens the MENSTRUAL CYCLE INSIGHTS page (§2.4).

### 2.3 Pregnancy card
**NOT SEEN** on Home or on the Health tab in any 2026 source.
- TEXT, Reddit 2026-08-04: "WHOOP's pregnancy coaching … acknowledges you're pregnant and shows you rhr/hrv but that's about it. No real week-by-week tracking, nothing useful for symptoms."
- The page itself is known (`help-center/14`: "‹ PREGNANCY INSIGHTS ⚙", "Week 5 / 35 weeks remaining / 1ST TRIMESTER", RHR | HRV chips, expected vs rolling trend).
- **ZENO:** reuse the Menstrual card shell with "Week N" in place of "Day N", a trimester progress bar in place of the dot strip, and no LOG button (UNCONFIRMED design).

### 2.4 MENSTRUAL CYCLE INSIGHTS page (2026 additions over `WHOOP_UI_SPEC.md` §3.24)
LOW-RES; frames 66–80; image `07`.
- Nav "‹ MENSTRUAL CYCLE INSIGHTS ⚙" on a purple gradient.
- "Cycle Day 21 | Luteal Phase" (phase name in lavender) with a grey sub-line.
- Month pager, weekday header, and a calendar of phase bands with a legend.
- **Symptom-predictions empty state:** a dotted-cluster illustration, "**Your symptom predictions will appear here**", a grey body ("Log your symptoms and periods regularly to start seeing predictions of the symptoms you might experience daily", read approximately), and a full-width button.
- **"Cycle Journal"** section header with a right-aligned link, then rows with **"+"** at the right: "Symptoms", "Period", "Ovulation" (labels approximate).
- **"<PHASE> PHASE …" card:** M | F | O | L columns with the current phase outlined in purple and drawn as a curve, an explanation paragraph, and three columns "SLEEP EFFICIENCY | STRAIN TOLERANCE | STRESS TOLERANCE", each with an amber "Low/High" chip.
- **"Your Current Cycle":** pill chips SKIN TEMP | RHR | HRV | RECOVERY (first one selected, white); legend "Smoothed Data | Expected Trend"; a coral/purple bar chart.
- **"Your Cycle Patterns":** "CURRENT | LAST 3 MONTHS"; "YOUR TYPICAL CYCLE" with three values (≈"3 days / 22 days / 4 days"); "CYCLE HISTORY" rows ("Current Cycle 21 days", a past "28 days") each with its own dot strip.
- **"YOUR SYMPTOMS"** empty state "Start uncovering patterns" with "+ LOG SYMPTOMS".
- "Learn More" article cards.
- **Bottom disclaimer card.** CONFIRMED, image `11`, 2026-07-15:
  - card `#1C2023` on page `#111518`, radius ≈12 pt (36 px at 3x), padding ≈18 pt;
  - "**Important Note**" (≈20 pt semibold `#FCFCFC`) / "Menstrual Cycle Insights should not be used for birth control or fertility tracking. The ovulatory phase indicators are estimates only." (≈16 pt `#B8B8BC`);
  - a hairline (`#1C2020` on the card);
  - "**Medical Disclaimer**" / "Menstrual Cycle Insights is not a medical device and cannot diagnose or manage medical conditions. It does not provide medical advice. Always consult your doctor for health concerns and never delay or modify medical care based on its information."
- States (TEXT; forum 403, WHOOP-community answer, 2025):
  - with no period logged, WHOOP assumes the luteal phase;
  - after too long it shows "**No Phase Predicted**" until new data arrives;
  - past cycles can be hidden in a "**Your Cycles**" section;
  - periods can be logged from the MCI page or the Journal.
  - The Home and Health cards therefore need a "No Phase Predicted" variant (UNCONFIRMED visual).
- Hormonal onboarding (TEXT; forum 13794, May 2026):
  - choosing "hormone issue" (perimenopause) as the reason still **forces a last-period date**;
  - the picker will **not go back more than ~2 months**;
  - there is no menopause mode ("There needs to be a way to turn off the menstruating or pregnant feature").

---------------------------------------------------------------------------------------------------

## 3. More tab (2026), full list

### 3.1 Established user, July 2026 (source A, frames 123–125; LOW-RES; image `06`)

```
[hero carousel card: photo + caps title + sub + ›]  · · · · ·  (5 page dots)
[iridescent "REFER A FRIEND" card, single, no outlined twin in this capture]
SHOP & GIFT                                  ← section label (caps, grey)
  ▸ WHOOP ACCESSORIES?  (row; ≈17-char label, reading uncertain)
  ▸ GIFT A MEMBERSHIP   (+ grey sub-line)
ACCOUNT & SETTINGS
  ▸ MY ACCOUNT
  ▸ DEVICE SETTINGS
  ▸ APP SETTINGS
  ▸ PRIVACY SETTINGS
SUPPORT
  ▸ MEMBERSHIP SERVICES (+ "Get help or ask a question")
  ▸ TUTORIALS
  ▸ ABOUT?              (5-letter label, reading uncertain)
  ▸ FIRST WEEK WITH WHOOP   ← a plain list row here, not the promo card
( LOGOUT )                   ← centred outlined capsule, ≈200×40 pt
APP VERSION 5.xx.x (BUILD xxxxx)   ← small centred caps grey text
```

- No "DIGITAL WHOOP LABS" row appears between MY ACCOUNT and DEVICE SETTINGS. It was in the July 2025 list.
- The tab bar shows "More" selected (hamburger icon), with the purple W coach button at the right.

### 3.2 Sept 2026 (source B, frames 16–27; LOW-RES; image `08`)
- Hero carousel: photo card "GIVE THE GIFT OF WHOOP"-like caps title, sub and ›, with 4 dots.
- "REFER & EARN": iridescent "GET ONE MONTH FREE" card, then outlined "SHARE A FREE TRIAL" card (as in `r05`).
- "SHOP & GIFT" as **list rows**: "WHOOP SHOP" plus sub ("Shop bands, smart apparel, and batteries" in 2025), and "GIFT A MEMBERSHIP" plus sub ("Gift a new member or purchase a gift card" in 2025).
- "ACCOUNT & SETTINGS": MY ACCOUNT, DEVICE SETTINGS, **APP SETTINGS**, PRIVACY SETTINGS (4 rows).
- "SUPPORT": MEMBERSHIP SERVICES…

### 3.3 New user, July 2026 (`reviews/r05`; CONFIRMED top only)
- Hero "EXTEND MEMBERSHIP" card with 4 dots.
- A black **"FIRST WEEK WITH WHOOP"** card with a gradient border, graduation-cap icon, and "Wear your WHOOP to bed nightly and check back in here to track your sleeps and discover new insights."
- "REFER & EARN" (two cards).
- "SHOP & GIFT" as **horizontal product cards** (Wireless PowerPack, 5.0 SportFlex Band, 5.0 Su…).
- So FIRST WEEK is a **promo card at the top for new members** and a **plain SUPPORT row later**. SHOP & GIFT has two presentations: product carousel or list rows. The trigger (region, tenure or rollout) is **UNCONFIRMED**.

### 3.4 Row geometry and colours
Calibrated on the full-resolution 2025 More list (forum topic 4736, 1179×2556). That list matches the 2026 rows in the low-res frames.
- Rows are separate rounded cards.
- Inset 20 pt left and right (16 pt in 2026 settings pages). Gap 10 pt.
- Height 56 pt for single-line rows; ≈64 pt with a sub-line.
- Radius ≈12 pt. Fill `#2F3438` (2025); 2026 settings pages use `#2D3035`→`#292D30`.
- 28 pt outline icon in `#6C7074` at x≈34 pt.
- Label from x 82 pt: ≈12–13 pt Bold caps with about 1.5 pt tracking, `#FCFCFC`, cap height 8.7 pt.
- Sub-line about 12–13 pt regular, `#BCBCC0`.
- Section labels: ≈12–13 pt Bold caps tracked, `#C4C4C4`, 20 pt from the left, ≈24 pt above the first row.
- Page background `#182023` at the top, falling to `#101417`.
- The nav title "MORE" appeared in 2025 (with back chevron in the Profile-tab variant). The 2026 root has no visible title in the captures.

---------------------------------------------------------------------------------------------------

## 4. App Settings subtree

### 4.1 App Settings root (Sept 2026; source B, frames 30–33; LOW-RES)
- Presented with **"✕" at the top-left** and the centred caps title "APP SETTINGS". The floating tab bar **stays visible** under it.
- **9 single-line rows**, each a full-width rounded card (≈48–52 pt tall) with a leading outline icon and a caps label. No section labels and no sub-lines.
- The labels are not legible. The estimated label lengths (≈9 pt per caps character, calibrated on "MANAGE MEMBERSHIP") are:

| Row | ≈ characters | Most likely item (UNCONFIRMED) |
|---|---|---|
| 1 | 14–17 | ACTIVITY SETTINGS |
| 2 | 11–12 | AI SETTINGS |
| 3 | 10–11 | DATA EXPORT |
| 4 | 5 | short label (UNITS? / HELP?) |
| 5 | 11–12 | **INTEGRATIONS** (the tutorial's red arrow taps it, and it opens "INTEGRATIONS") |
| 6 | 7 | JOURNAL |
| 7 | 12–13 | NOTIFICATIONS |
| 8 | 16–17 | HORMONAL INSIGHTS |
| 9 | 11–12 | HIDE METRICS |

- What the list contains (help-center text; order unknown):
  - Hide Metrics, Data Export, Integrations, Journal, Hormonal Insights;
  - Activity Settings (holds Activity Detection and Heart Rate Settings);
  - Notifications, AI Settings, Coaching Preferences.
  - That is 9 items, which matches the 9 rows. COACHING PREFERENCES (20 characters) does not fit any measured row, so the list in 2026 may differ.
- TEXT path confirmations, 2026:
  - "More - 3 vertical lines button on the bottom, **App Settings, Data Export** … You can do this once per day" (Reddit 2026-05-07);
  - "More (•••) > **App Settings > Integrations > Apple Health**" (support text quoted on Reddit 2026-08-07);
  - "More tab → App Settings → **Hide Metrics**" (forum 2174).

### 4.2 INTEGRATIONS (Sept 2026; source B, frames 35–38; LOW-RES)
- Nav "‹ INTEGRATIONS".
- A **featured card for APPLE HEALTH** at the top: a dark photo background, Apple-Health glyph, "APPLE HEALTH", a "›"/toggle-like control at the right.
- A short caps section label (≈9 characters, probably "CONNECTED"). Under it 2 rows with a circular status mark at the right: a ≈6-character label (likely **STRAVA**), and a ≈12–14-character label with a red/pink icon (HEALTHEX? NATURAL CYCLES? UNCONFIRMED).
- A longer caps section label (≈18 characters, e.g. "RECOMMENDED FOR YOU", UNCONFIRMED). Under it 4 rows of about 13, 7 (with a sub-line), 8 and 10–11 characters. Plausible: TRAININGPEAKS, PELOTON, WITHINGS or HYPERICE, CRONOMETER.
- Known partner list (help-center text): Apple Health (Health Connect on Android), Strava, Peloton, Withings, Clue, **Natural Cycles** (Aug 2026), Cronometer, TrainingPeaks, Hyperice, **HealthEx** (Jun 2026, US).
- Garmin direct import is gone (Reddit 2026-09-16; the coach v6.0 says "WHOOP doesn't currently pull full activity details (like workouts) from Garmin anymore").

### 4.3 INTEGRATION DETAILS (partner page)
CONFIRMED; image `24`, Peloton, 2026-09-22; 1179×2556 at 3x.
- **Hero:** a full-bleed lifestyle photo fading to the page colour `#101518` by about y 330 pt. Over it:
  - nav "‹" (white chevron, x 40) and "INTEGRATION DETAILS" (centred caps ≈13 pt semibold, tracked);
  - partner glyph (white, ≈24 pt) at x 20, y 155;
  - partner name "**Peloton**" (≈28 pt semibold `#FCFCFC`) at y≈204;
  - description (≈15 pt `#B4B8BC`, 4–5 lines): "Connect Peloton with WHOOP to automatically sync your activities and enrich your workout details in WHOOP, while sharing your Sleep, Strain, Recovery, and activity data with Peloton for a more connected and personalized experience.";
  - "**LEARN MORE →**" (≈12–13 pt bold caps tracked, white).
- **Hairline** at y≈423 (`#24282C`, inset 16 pt).
- **Per-direction permission blocks**, repeated:
  - title "**Pull Peloton data into WHOOP**" (≈16 pt semibold white);
  - status "**Connected**" (≈15 pt semibold `#00F0A0`);
  - at the right, a **24 pt checkbox square** (fill `#0D372D`, green check);
  - under it a full-width button "**DISCONNECT**": background `#282C2F`, height ≈40 pt, radius ≈8 pt, inset 16 pt, white bold caps ≈12 pt;
  - a hairline, then the second block "**Share WHOOP data with Peloton** / Connected" with its own DISCONNECT.
- Bottom page colour `#101518`.
- Use this template for every partner: Strava, Withings, Natural Cycles, HealthEx and so on.
- Peloton's two-way sync is new in Sept 2026 (Reddit 2026-09-22 and 2026-09-24).
- **Strava page contents.** TEXT; WHOOP Locker "How WHOOP and Strava Work Together", 2026-05-21:
  - path: "More > App Settings > Integrations and select Strava";
  - "Once connected, **activity import is on by default**. You can turn it off any time on the Strava integration page";
  - "In the Strava integration settings page, you can choose to have **all activities** shared to Strava, **specific activity types** shared, or … share one-off via the Activity Details page";
  - Strength Trainer sessions can be shared with their full structure.
  - So the Strava page adds a share-scope choice (All activities / chosen types) to the import/export blocks.
  - Imported activities show "**Garmin Via Strava**"-style source attribution on Activity Details.
- **HealthEx page:** the same template plus a **refresh** action and a route into **Health Record Analysis** (§1.2 e).

### 4.4 APPLE HEALTH page (Sept 2026; source B, frames 40–45; LOW-RES)
- Nav "‹ APPLE HEALTH".
- A **connection graphic**: the white Apple Health icon (pink heart), a connector line, then a dark WHOOP app tile (sampled ≈`#40182C`; low-res).
- A row of **5 small grey data-type tiles** (≈32 pt; workouts, mindful minutes, steps, sleep, heart rate, by icon shape; UNCONFIRMED).
- "**CONNECT TO APPLE HEALTH**" (caps title), two grey paragraphs, and a small "LEARN MORE →"-like link.
- A full-width **green pill button** pinned at the bottom (≈`#24BC80` in the low-res sample; probably the WHOOP green `#00F0A0` before scaling). Its label is "Connect" per the support text.
- TEXT, 2026-08-07: once permissions have been seen, "the green 'Connect' button is hidden. Instead, tap 'Apple Health', then choose '**Manage Permissions**'".
- What it imports and exports (WHOOP support text, quoted on Reddit 2026-07-06):
  - **Imported from Apple Health:** Workouts, Workout routes, Active Energy, Distance, Mindful Minutes, Weight & Height, Heart Rate during activities.
  - **Exported to Apple Health:** Workouts (auto-detected), Active Energy, Heart Rate during activities, Sleep, RHR, Respiratory Rate, SpO₂, Steps ("if enabled in WHOOP settings").
  - "WHOOP MG does not currently export ECG nor Blood Pressure Insights to Apple Health."

### 4.5 Natural Cycles (Aug 4, 2026). TEXT.
- Requires WHOOP 5.0 or MG worn on the wrist (**4.0 is not compatible**) and age 18+.
- Overnight skin temperature syncs to the NC° app after sleep processes. NC data is **not** shared back.
- "**The WHOOP app shows only that your data has synced.**" Fertility status lives only in NC.
- Expect an Integration Details page like §4.3 with a single "Share … with Natural Cycles" direction (UNCONFIRMED).

### 4.6 Data Export. CONFIRMED partial: image `25`, 2026-03-19, the top of the page.
- Modal: "**✕**" at the top-left and the centred caps title "**EXPORT WHOOP DATA**" (≈17 pt semibold, tracked). The background is a grey-blue gradient, lighter than the main pages.
- Body (≈17 pt grey): "Export a complete archive of your Sleep, Recovery, Strain, and Journal data by submitting a request below. This is your data, and we take your privacy seriously."
- "**LEARN MORE →**" (white bold caps).
- "Your export will be sent to your account email …"; the rest is cropped.
- Below the crop, per the HC "How to Export Your Data" (2025-11-17): "**Confirm your email address** (update it if necessary). Select **Create Export**." The link arrives within 24 h and expires after 7 days. iOS path: More › App Settings › Data Export; Android: More › Data Export. Expect an email row/field, then a primary "CREATE EXPORT" button (visual UNCONFIRMED).
- Deletion of regulated MG data (ECG, IHRN, BP) goes through More › Settings › **Privacy & Data Management** and "may be retained per compliance rules".
- TEXT facts:
  - about 20 minutes to 24 hours; **once per day**; delivered by email;
  - CSVs: physiological_cycles, sleeps, workouts, journal_entries;
  - **no steps** (forum 2026-09-13 and 14416); no Strength Trainer detail; no Labs history ("Labs Summary download just gives the latest").
- The Labs Summary page has its own **CSV export icon** at the top-right (forum 10674, Nov 2025).

### 4.7 Hide Metrics. TEXT only.
- Path: More → App Settings → Hide Metrics (forum 2174, 2025, still valid in 2026).
- Toggles: Hide **Recovery & Sleep**, Hide **Weight & Lean Body Mass**, Hide **Healthspan**. Data still records in the background.
- No Stress Monitor or BP toggle (2026 requests in forum 2174 #4 and 16189).
- Visual: not found. Use toggle rows in the §3.4 card style.

### 4.8 Notifications. TEXT only.
- In App Settings (help-center). The HC Stress Monitor article: the evening **stress summary** notification's "frequency and timing" are adjusted "in App Settings > Notifications". So the page has per-notification rows with frequency and time controls (visual UNCONFIRMED).
- Heart (IHRN) notifications are **not** here. They are toggled on the Health tab's **Heart Notification card** ("Heart Notifications" switch, green = on, grey = off; HC IHRN best-practices).
- 2026 user reports:
  - "I can't find anything about it in the settings" to turn off the **daily morning recovery** push only (Reddit 2026-09-19). The pushes look like "Recovery climbed overnight / After yesterday's dip, your body bounced back this morning 📈" (`reviews/r115`).
  - "Muting Whoop notifications made me much happier" (Reddit 2026-08-06).
  - The AI support bot claimed toggles "Voice of WHOOP" and "Coach" under More → Settings → Notifications; the user says these do not exist (forum 13911 #5, 2026-05-29). **Treat as UNCONFIRMED.**
- Custom reminders are created **in Coach chat** (v6.0), for example "remind me to take [a] shot every month" → "B12 shot on the 1st of each month at 8:00 a.m. … Keep push notifications enabled" (Reddit 2026-08-06). There is no settings UI for them.
- The Home **notification feed** sits as a slot between the dials and the Health/Stress tiles (CONFIRMED, image `23`, May 2026). Its error state is a dashed-border box (`#30383C`) with an amber "!" tile and grey (`#888C90`) text: "Couldn't load new notifications. We'll try again later."

### 4.9 AI Settings and Coaching Preferences. TEXT only.
- "There used to be an option to turn off the coach but I no longer see it in the **ai settings**" (forum 13911, 2026-02-21).
- WHOOP support, 2026-03: "With the most recent WHOOP app update, the WHOOP Coach feature **can no longer be disabled** within the app."
- So in 2026 AI Settings exists, but the Coach on/off toggle has gone.
- Coaching Preferences offers a "Coaching Mode". HC "How to Use the AI-Powered WHOOP Coach": "To change the Coaching Mode (e.g., **Customized with your data** vs. **Education support**): From App Settings, go to Coaching Preferences. Select Coaching Mode." That gives a two-option picker. The full text of forum 13911 #5 (an AI support reply, May 2026) names the second mode "**Education & Support Only**" under "More → Settings (gear) → Coaching Preferences". That reply also describes a gear icon and notification toggles users could not find, so treat its labels and paths as UNCONFIRMED.
- **My Memory** is reached from Profile, not settings (Reddit "WHOOP Updates 5/8").

### 4.10 Hormonal Insights settings
See `help-center/11`: "‹ HORMONAL INSIGHTS", a toggle, MODE (MENSTRUATING / PREGNANCY), CONTRACEPTION TYPE, SHOW CYCLE OVERLAY ON TRENDS, and a privacy card. Nothing new seen in 2026.

### 4.11 Activity Settings and Heart Rate Settings
See `help-center/98,99`. New in 2026 (Reddit 2026-09-24 screenshot): activity details show "Zone ranges automatically updated on 8/16/26. **View HR Settings**", an underlined link into HR Settings.

### 4.12 Privacy Settings. TEXT only.
- Help-center items: Team Invitations, Personalized Product Recommendations, Privacy & Data Management.
- A 2026-01 user: "offers 'Privacy' but not 'Data Mgmt' under settings". The data-export entry moved to App Settings › Data Export.
- Visual: not found.

### 4.13 MY ACCOUNT children (2026), CONFIRMED

**MEMBERSHIP & BILLING** (image `21`, 2026-09-23; image `22`, 2026-09-28):
- Nav "‹ MEMBERSHIP & BILLING".
- "Your Membership" (≈22 pt semibold white, sentence case) over a membership card (`#383D43`, radius ≈12):
  - "WHOOP PEAK" wordmark with the avatar at the right;
  - a hairline;
  - three columns: RENEWAL "£229/yr" / "Plus tax"; BILLED "Annually" / "You're saving 29%"; NEXT RENEWAL "Oct 20, 2027". Labels `#C0C4C4`, values white ≈17 pt bold.
- "Membership Options": rows 64 pt tall, radius ≈12, fill `#2D3035`→`#292D30`, inset 16 pt; icons `#686C70`; titles white bold caps; subs `#C0C0C4`:
  - MANAGE MEMBERSHIP / "Explore membership options";
  - CREATE FAMILY PLAN / "Switch to Family Plan—2-6 members, one bill";
  - SWITCH BILLING PLAN / "You're saving 29%".
- "Available Upgrade": a large MG photo card with the "WHOOP LIFE" lockup.
- Page gradient `#272E34` → `#14171C` → `#111518`.

**SETUP MFA** (image `20`, 2026-04-24; under My Account › Advanced Security):
- Nav "‹ SETUP MFA" with a support **headset** icon at the right.
- "Confirm your email address" (≈20 pt semibold white) and grey body `#B8B8BC`.
- A read-only email field: fill `#0C1013`, 1 pt border, lock icon, grey text `#848488`.
- Error banner: fill `#34131A`, red "!" and red text `#FC0024` "Something went wrong. Please try again."
- An outlined white capsule "USE MY PHONE NUMBER INSTEAD".
- At the bottom right, "NEXT" and a **ring button**: a progress arc `#0090E8` over track `#28282C`, holding a circular arrow.
- MFA is required before uploading lab results.

### 4.14 TUTORIALS
A row under SUPPORT (2025 and 2026). Its destination was **not seen**. In Jul 2025 the bug report "click Tutorials → my profile shows up" shows it is a pushed page. UNCONFIRMED content.

### 4.15 FIRST WEEK WITH WHOOP, Getting Started, Get Started guides
- More: a promo card for new members (`r05`). For established members it is a SUPPORT row (§3.1). What the row opens is **not seen**.
- **The checklist contents.** TEXT; HC "Your First 4 Days", last published 2026-08-13:
  - "In your first 4 days, complete a **checklist of mini-tutorials** … In the WHOOP app, navigate to the **More** tab … Tap on **Getting Started**."
  - Tasks, in this order:
    1. **Track an activity**
    2. **Join a team in the community**
    3. **Analyze your Sleep Performance**
    4. **View your activity details**
    5. **Set up your personalized alarm**
    6. **Set up your daily journal**
  - "Tapping on a task will provide you with a walkthrough of how to complete it or provide you with a helpful resource."
  - This replaces the older list in `WHOOP_UI_SPEC.md` §3.31 (Track an activity · Analyze your Sleep · Set up your alarm · Set up your journal · Explore Trends).
  - The page visual (rows with check states?) is UNCONFIRMED.
- Home for new users: a "**Get Started**" section with a white "+" button and gradient-border cards (`reviews/r06`):
  - "Ready to get moving? … START ACTIVITY →" (shoe illustration, orange→purple border);
  - "Unlock New Potential / Connect WHOOP to Strava and your favorite apps … **EXPLORE APP INTEGRATIONS →**" (W-chip-with-wires illustration).
- That card stays until the user has connected apps (Reddit 2026-06-15, "How to remove this?").
- Onboarding "Customize Your WHOOP Experience" 6-step tutorial card (forum 8956, Oct 2025).
- Get Started guides can be dismissed and cannot be recalled (Reddit 2026-07-01).

### 4.16 LOGOUT and version
At the very bottom of More (§3.1): a centred outlined capsule "LOGOUT" (white 1 pt border, about 200×40 pt), then "APP VERSION 5.xx.x (BUILD xxxxx)" in small grey caps. App versions seen: 5.57.0 in Jun 2026 (forum 15101), 5.52.0 build 595097 in May 2026 (forum 10961), and 5.32.1 in Dec 2025.

### 4.17 Tangential: research studies
CONFIRMED, image `12`, 2026-08-14.
- "‹ STUDY DETAILS •••" over a hero photo.
- A frosted glass row with a W-clipboard icon, "RESEARCH CONSENT FORM ›".
- "About This Study" and "Compensation" (≈20 pt semibold white headings, ≈17 pt `#B8B8BC` body).
- Its entry point (Home card or More) is UNCONFIRMED.

---------------------------------------------------------------------------------------------------

## 5. Colour and geometry tokens measured here

| Token | Hex / value | Source |
|---|---|---|
| Settings page gradient | `#272E34` → `#14171C` → `#111518` | Membership `21` |
| Partner detail page background | `#101518` | `24` |
| Settings row card (2026) | `#2D3035` → `#292D30`, 64 pt (two-line), radius ≈12–13 pt, inset 16 pt | `21` |
| More list row (2025 calibration) | `#2F3438`, 56 pt, radius ≈12–13 pt, inset 20 pt, gap 10 pt | forum 4736 |
| Row icon | `#686C70`–`#6C7074` outline, ≈28 pt | `21`, 4736 |
| Row title | `#FCFCFC` bold caps ≈12–13 pt tracked | — |
| Row sub-line | `#BCBCC0`–`#C0C0C4` ≈13 pt | — |
| Section label | `#C4C4C4` bold caps tracked | 4736 |
| Secondary button | `#282C2F`, h 40 pt, radius 8 pt, white bold caps ≈12 pt | `24`, `01` |
| Connected / positive text | `#00F0A0` | `24`, `01`, `23` |
| Positive chip background | `#0D372D`–`#0E362D` | `24`, `01` |
| Error banner | `#34131A` fill, `#FC0024` text | `20` |
| Progress-ring CTA | arc `#0090E8`, track `#28282C` | `20` |
| Membership card | `#383D43` | `21` |
| Disclaimer text | `#B4B4B8` ≈15 pt; hairline `#28282C` | `01` |
| MCI disclaimer card | `#1C2023` on `#111518`, radius ≈12 pt, body `#B8B8BC` | `11` |
| BP v2.0 tokens | see §1.2 c | `10` |
| Home MCI card | card ≈`#2F3239`, LOG CYCLE button ≈`#41444B` (low-res) | A |
| Health tab glow (green orb) | ≈`#0B4E2F`–`#185B3C` at top (low-res) | A |
| Health tab card stack | card fill `#2B2E33` (Labs `#272A2F`, HM `#2A2D32`) on page `#14171C`/`#13161B`; inset 16 pt; radius ≈12 pt; **vertical gap 24 pt**; Advanced Labs card height ≈220 pt | `reviews/r44` (measured, 1290 px = 430 pt) |
| Notification feed error | dashed `#30383C`, text `#888C90`, icon amber `#F8A420` | `23` |
| Home sync banner | `#000000` fill, time `#00EC9C` | `23` |
| Home Health Monitor / Stress tiles | `#2A2E31`; stress value chip `#4E402F` with "2.0", HIGH `#FCA820` | `23` |
| More "FIRST WEEK WITH WHOOP" promo card | fill `#070707`; 1 pt gradient border, warm `#9C6058`/`#D4846C` (left and top) to magenta `#B854B0` (right) | `reviews/r05` |
| More "REFER & EARN" iridescent card | `#BBC1B7` (left) → `#D1D2CA` → `#BBAEBF` (right), dark text; outlined twin border `#BCC0B8` | `reviews/r05` |
| More section label / page | label `#C0C0C4`; page `#1B1E23` (top) → `#111518` | `reviews/r05` |
| Health "UNLOCK HEALTHSPAN" card | fill `#1C1A27`; border `#604844` → `#AC28FC`; progress `#C450D4` on `#4C4857`; orb rim `#C050D0` | `16` |
| ECG failure dialog | card `#283339`; dim `#030406`; primary white capsule with black text; secondary outline `#484C50` | `14` |

---------------------------------------------------------------------------------------------------

## 6. What this means for ZENO (WHOOP 4.0, offline)

- **Health tab order:** use the best-fit model in §1.1.
- **Before ZENO Age has enough history,** copy WHOOP's 2026 unlocking state (image `16`): a grey dormant orb with a magenta rim, then a gradient-bordered card "UNLOCK ZENO AGE · N more days to unlock your personal ZENO Age" with a magenta progress bar. This beats a blank or blurred card.
- **Do not build** (needs WHOOP MG, cuff calibration, US EHR access or a paid clinician service): Blood Pressure Insights, Heart Screener, Connect Health Records / Health Record Analysis, the clinician consult.
  - ZENO's optional RHYTHM card can take the Heart Screener slot.
  - A manual "BLOOD PRESSURE LOG" can use the BP v2.0 range-chart style (§1.2 c), but must never show an estimate.
- **Menstrual card:** same component on both tabs; Home after My Journal; Health tab right after Health Monitor. Fields: Day N, phase name in the phase colour, a prediction sentence, a dot strip (Home) or gradient bar (Health), and "+ LOG CYCLE". The data comes from `CyclePhaseEngine`.
- **"Upgrade to Access" and "More to unlock":** ZENO has no tiers, so skip them. The sentence-case section header style is still the pattern for ZENO's own extras section ("More from ZENO").
- **More tab:** copy the order SHOP & GIFT → ACCOUNT & SETTINGS → SUPPORT → LOGOUT → version, but swap the content.
  - SHOP & GIFT and REFER are dropped.
  - ACCOUNT & SETTINGS: PROFILE, DEVICE SETTINGS, APP SETTINGS, PRIVACY & DATA.
  - SUPPORT: HOW ZENO WORKS (tutorials), WHAT'S NEW, FIRST WEEK WITH ZENO (row; card only for the first 7 days).
  - Replace LOGOUT with the version text only, or "Classic interface".
- **App Settings:** keep the WHOOP "✕ APP SETTINGS" list of single-line rows.
  - ACTIVITY SETTINGS (auto-detect + HR settings);
  - DATA EXPORT (local CSV/JSON, which beats WHOOP's email; keep the "Export a complete archive…" copy pattern);
  - INTEGRATIONS (Apple Health, WHOOP CSV import, Mi Fitness, Shortcuts);
  - JOURNAL; NOTIFICATIONS (per-type toggles, including a "morning recovery" toggle WHOOP users ask for);
  - HORMONAL INSIGHTS (add a perimenopause/menopause mode);
  - HIDE METRICS (add Stress and Healthspan);
  - UNITS.
  - Use the Integration Details template (§4.3) for each source, with "Connected" and DISCONNECT.

---------------------------------------------------------------------------------------------------

## 7. Still UNCONFIRMED after this pass

1. The Health tab card order for **Life** members below BLOOD PRESSURE INSIGHTS: where Heart Screener, Menstrual and Stress sit relative to each other. Only "BP → … → ECG" is known.
2. The slot of **Connect Health Records** and its card visuals. The Health Record Analysis page is unseen.
3. The **clinician consult** entry; it may not have launched by 2026-10-02.
4. The 2026 Health tab **disclaimer** text and position, and whether anything follows "Upgrade to Access".
5. The contents of the "Upgrade to Access" card and whether it pages horizontally.
6. Stress card label wording and value digits; the Menstrual card's small labels and prediction sentence.
7. The **Pregnancy** card on Home or the Health tab.
8. App Settings row **labels and order** (9 rows measured; mapping in §4.1 is a guess). Visuals of Notifications, AI Settings, Coaching Preferences, Hide Metrics, Privacy Settings and Tutorials.
9. Integrations page section labels and partner rows; the Apple Health page copy.
10. The trigger for SHOP & GIFT as product cards (`r05`) versus list rows (sources A and B); the July "WHOOP ACCESSORIES?" label; the 5-letter SUPPORT row ("ABOUT?"); and what "FIRST WEEK WITH WHOOP" opens.
11. Natural Cycles and HealthEx Integration Details pages; there is no screenshot of either.
12. The visual of the **Getting Started** checklist page (the 6 tasks are known from the HC), the Data Export page below the fold (email field, CREATE EXPORT), and the English strings of the "UNLOCK HEALTHSPAN" card (seen only in Spanish).
13. Reddit RSS queries "hormonal", "stress monitor", "clinician", "tutorials" and "first week" were rate-limited (HTTP 429 from many agents sharing the IP) and may have missed posts. Re-run them later with ≥50 s spacing.

---------------------------------------------------------------------------------------------------

## 8. Image index (`../images/health-more-2026/`)

| File | What it shows |
|---|---|
| `00-yt-NrCpf_m75XM-storyboard-health-tab-top-orb-pace-labs-promo-teams-x5.jpg` | Source C, ≈May 2026. Health tab top with the full orb "23.1", Pace, Advanced Labs promo; Healthspan detail; Community Teams. Upscaled 5x, structure only. |
| `01-reddit-2025-10-01-health-tab-one-member-more-to-unlock-labs-waitlist-disclaimer.jpeg` | ONE-tier Health tab (Oct 2025, old tab bar). "More to unlock", Advanced Labs waitlist card, disclaimer. Full resolution. |
| `02-yt-V3rewDUPcjo-2026-07-health-tab-scroll-orb-pace-labs-monitor-mci-stress-upgrade-to-access-x4.jpg` | Source A frames 94, 107, 118–121. Full Health tab scroll (orb at rest and scrolled, Pace, Labs, Health Monitor, Menstrual, Stress, "Upgrade to Access"). |
| `03-yt-V3rewDUPcjo-2026-07-health-tab-lower-monitor-mci-card-stress-card-upgrade-to-access-x7.jpg` | Frames 119–121 at 7x. The lower Health tab cards. |
| `04-yt-V3rewDUPcjo-2026-07-home-tonights-sleep-journal-mci-card-my-plan-dashboard-x7.jpg` | Frames 64, 65, 81 at 7x. Home: Tonight's Sleep → My Journal → **Menstrual Cycle Insights card** → My Plan → My Dashboard. |
| `05-yt-V3rewDUPcjo-2026-07-home-lower-activities-dashboard-stress-strain-recovery-chart-discover-more-x4.jpg` | Frames 63, 85, 87, 88, 92, 93. Home lower half down to "Discover More" and the footer. |
| `06-yt-V3rewDUPcjo-2026-07-more-tab-carousel-refer-shop-gift-account-settings-support-logout-x5.jpg` | Frames 122–125. Community Teams, then the More tab from the carousel to LOGOUT and the app version. |
| `07-yt-V3rewDUPcjo-2026-07-mci-page-calendar-symptom-predictions-cycle-journal-phase-card-current-cycle-patterns-x3.jpg` | Frames 66–80. Menstrual Cycle Insights page sections. |
| `08-yt-Cn-VsRG9gYM-2026-09-more-tab-app-settings-modal-integrations-apple-health-connect-x6.jpg` | Source B. More top and middle, ✕ APP SETTINGS (9 rows), INTEGRATIONS, APPLE HEALTH connect page with the green button. |
| `06b-yt-V3rewDUPcjo-2026-07-more-tab-frames-123-125-sharpened-x8.jpg` | More frames 123–125, 8x bicubic and sharpened (best low-res read of the list). |
| `08b-yt-Cn-VsRG9gYM-2026-09-app-settings-9-rows-and-integrations-averaged-x8.jpg` | App Settings (9 rows) and Integrations. Static frames averaged, 8x. |
| `08c-yt-Cn-VsRG9gYM-2026-09-more-top-mid-and-apple-health-page-averaged-x8.jpg` | More top and middle, and the Apple Health page. Averaged, 8x. |
| `09a-…contact-frames-0-79.jpg`, `09b-…contact-frames-80-125.jpg` | Every frame of source A as a contact sheet, with timestamps. |
| `10-reddit-2026-04-05-blood-pressure-insights-beta-v2-month-view.jpeg` | BP Insights page, BETA V2.0, month view. Full resolution. |
| `11-reddit-2026-07-15-mci-important-note-medical-disclaimer-card.jpeg` | Menstrual Cycle Insights bottom disclaimer card. Full resolution. |
| `12-reddit-2026-08-14-study-details-research-consent-row-on-photo.jpeg` | STUDY DETAILS page (research consent). Full resolution. |
| `13-reddit-r44-2026-08-26-tabbar-bleedthrough-blood-pressure-insights-is-next-card-enhanced.jpg` | Brightened crop of `r44`. "BLOOD PRESSURE INSIGHTS" title under the glass tab bar. |
| `14-forum-2026-07-05-heart-screener-ecg-reading-failed-modal-learn-more-try-again.jpeg` | "ECG READING FAILED" modal (2026). |
| `15-forum-2025-12-09-heart-screener-page-heart-notifications-activated-annotated.jpeg` | HEART SCREENER page (Dec 2025) with the "HEART NOTIFICATIONS ACTIVATED" card. The user drew a red annotation on it. |
| `16-reddit-2026-07-16-health-tab-es-unlock-healthspan-progress-purple-orb-labs-promo-monitor.jpeg` | Health tab (Spanish) for a new member: purple dormant orb, "DESBLOQUEA HEALTHSPAN" progress card, Advanced Labs promo, Health Monitor. Full resolution. |
| `20-forum-2026-04-24-my-account-setup-mfa-confirm-email-error-next-ring.jpeg` | SETUP MFA page. |
| `21-forum-2026-09-23-my-account-membership-billing-options-available-upgrade.jpeg` | MEMBERSHIP & BILLING page. |
| `22-forum-2026-09-28-membership-billing-variant-sar.jpeg` | The same page with SAR pricing. |
| `23-forum-2026-05-19-home-notifications-feed-error-dashed-card-data-caught-up.jpeg` | Home: DATA CAUGHT UP banner, dials, notification-feed error box, Health/Stress tiles, My Day "Ask a question…" row. |
| `24-reddit-2026-09-22-integration-details-peloton-pull-share-connected-disconnect.jpeg` | INTEGRATION DETAILS (Peloton). Full resolution. |
| `25-reddit-2026-03-19-export-whoop-data-modal-annotated.png` | ✕ EXPORT WHOOP DATA (top part; the user added a red annotation). |

---------------------------------------------------------------------------------------------------

## 9. Source URLs

- YouTube (storyboards only):
  - https://www.youtube.com/watch?v=V3rewDUPcjo
  - https://www.youtube.com/watch?v=Cn-VsRG9gYM
  - https://www.youtube.com/watch?v=NrCpf_m75XM
- Reddit:
  - r44: https://www.reddit.com/r/whoop/comments/1vz88ib/
  - health tab freezes / ECG: https://www.reddit.com/r/whoop/comments/1r8j16b/
  - ONE plan access: https://www.reddit.com/r/whoop/comments/1us9wgk/
  - BP v2: https://www.reddit.com/r/whoop/comments/1sd70kj/
  - BP tile in Health Monitor: https://www.reddit.com/r/whoop/comments/1t7b6wx/
  - export page: https://www.reddit.com/r/whoop/comments/1rxx4az/
  - export path: https://www.reddit.com/r/whoop/comments/1t6b83a/
  - Apple Health path: https://www.reddit.com/r/whoop/comments/1vi0h6b/
  - Peloton details: https://www.reddit.com/r/whoop/comments/1wn6gfl/
  - Peloton activity: https://www.reddit.com/r/whoop/comments/1wp9c9i/
  - MCI disclaimer: https://www.reddit.com/r/whoop/comments/1uxgmqb/
  - study: https://www.reddit.com/r/whoop/comments/1voa2iw/
  - HealthEx: https://www.reddit.com/r/whoop/comments/1u27q3d/, https://www.reddit.com/r/whoop/comments/1u2tnjn/
  - updates 5/8: https://www.reddit.com/r/whoop/comments/1t7aivg/
  - coming next 9/3: https://www.reddit.com/r/whoop/comments/1w690hl/
  - recovery notifications: https://www.reddit.com/r/whoop/comments/1wkf5pq/
  - reminders: https://www.reddit.com/r/whoop/comments/1vgu61q/
  - Garmin: https://www.reddit.com/r/whoop/comments/1wi9d99/
  - pregnancy coaching: https://www.reddit.com/r/whoop/comments/1vfjc5d/
  - Get Started card: https://www.reddit.com/r/whoop/comments/1u6qptl/, https://www.reddit.com/r/whoop/comments/1ukrs97/
  - ONE 2025: https://www.reddit.com/r/whoop/comments/1nuyvy3/
  - unlock Healthspan: https://www.reddit.com/r/whoop/comments/1uyfxx1/
  - ECG failed modal: https://www.reddit.com/r/whoop/comments/1t77kex/, https://www.reddit.com/r/whoop/comments/1siu3mh/
  - Community as default tab: https://www.reddit.com/r/whoop/comments/1uxf46m/
- Forum (`https://www.community.whoop.com/t/<id>`):
  - 15753 (5 widgets);
  - 16290, 16189 (BP);
  - 13911 (AI settings);
  - 2174 (Hide Metrics);
  - 4226, 14416, 16226, 10674 (export);
  - 13794 (menopause);
  - 14645, 15076, 15101 (MFA);
  - 16323, 16370 (Membership & Billing);
  - 14877, 15449, 14037 (notification feed);
  - 4736 (2025 More list);
  - 8956 (Get Started tutorial);
  - 10961, 15113 (Health tab freeze below BP / ECG);
  - 15330, 12261 (ECG modal / page);
  - 403 (No Phase Predicted).
- WHOOP Locker (via r.jina.ai):
  - https://www.whoop.com/us/en/thelocker/healthex-integration/
  - https://www.whoop.com/us/en/thelocker/the-all-new-whoop-home-screen/
  - https://www.whoop.com/us/en/thelocker/how-whoop-and-strava-work-together/
- WHOOP and partners:
  - https://www.whoop.com/us/en/press-center/whoop-and-healthex-partner-to-connect-medical-records-and-biometric-data-to-deliver-more-personalized-health-insights/
  - https://www.healthex.io/press/healthex-whoop-launch
  - https://www.whoop.com/us/en/press-center/whoop-expands-health-platform-with-on-demand-clinician-access-and-new-ai-features/
  - https://www.whoop.com/us/en/thelocker/using-whoop-temperature-data-with-the-natural-cycles-app/ (via r.jina.ai)
