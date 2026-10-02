# WHOOP visual design language, measured (research notes)

Topic owner: design-language research agent. Date: 2026-10-02.
Companion file with the actionable token sheet: `../DESIGN_RULES.md`.
Images referenced below live in `../images/design-language/` unless another folder is named.
Everything here comes from public sources. Anything I could not confirm by looking at a pixel is marked **UNCONFIRMED**.

---

## 0. Method, sources and four caveats you must read first

### 0.1 What was measured, and how
- Every screenshot I kept was opened and looked at. Colours were sampled with Pillow, using medians over many pixels inside a stroke or fill, never a single anti-aliased pixel. Geometry comes from edge scans, circle fits for the rings, and circle fits for the card corners.
- Real-device screenshots are 1179 × 2556 px, which is an iPhone 14/15/16 Pro at 3x, so **1 pt = 3 px** and the screen is 393 × 852 pt.
- The App Store marketing images (`../images/appstore/ios69-*.png`, 1320 × 2868) contain a phone mock-up. I checked its scale against the real device: the RECOVERY dial label is 7.24 pt cap / 63.6 pt wide in the mock-up against 7.33 / 64.0 on the real device, and dial-diameter/screen-width is 0.221 against 0.224. That confirms a **393 pt-wide device**. Scale factors: home mock-up 760 px across the screen = **1.934 px/pt**; deep-dive mock-ups 1031 px = **2.623 px/pt**.

### 0.2 Caveat A: colour space (important)
- `21-5kr-new-home-oct2025.png` was re-encoded by the blog's CDN without its Display-P3 profile, so its raw pixel values are P3 numbers mislabelled as sRGB. The proof: raw Sleep `#83A0B8` converts P3→sRGB to `#7BA1BB`, the exact brand Sleep colour. Likewise raw yellow `#F9DF4A` → `#FEDE00` (brand `#FFDE00`) and raw strain `#4090E0` → `#0092E7` (brand `#0093E7`).
- The App Store images, the WHOOP site video frames and the5krunner images `reviews/04`, `05` and `06` are sRGB-correct. Their raw values hit the brand hexes exactly: `#0093E7`, `#FF0026`, `#19EC06`, `#FFDE00`, `#00F19F`, `#67AEE6`, `#FFA722`.
- **Conclusion:** the current app still renders the published brand palette exactly. Do not copy desaturated-looking values from un-profiled screenshots.

### 0.3 Caveat B: Dynamic Type
- The5krunner's Oct-2025 phone (`21`, and `reviews/04` to `07`) runs a **larger Dynamic Type setting**. Its text is 1.29–1.5× bigger than the App Store mock-up's. Examples: "My Day" cap 18.7 pt vs 14.0 pt; "TODAY" pill 10.7 vs 7.2; tab label 10.0 vs 7.5. Dial numerals and dial labels are the same size in both, and so is all non-text geometry.
- This also produces WHOOP's own wrapping bug at large sizes ("RECOMMENDE / D BEDTIME").
- **Conclusion:** WHOOP scales card and section text with Dynamic Type and keeps dial numerals fixed. Default text sizes below come from the App Store mock-ups. The large-text values are kept only as evidence.

### 0.4 Caveat C: two backgrounds seen in 2025
- Every screenshot from **July 2025 onward** (BP Insights Jul 2025; home Oct 2025; App Store; site video) shows a **slate gradient** background.
- One the5krunner screenshot labelled "Old Home Screen" (`20-5kr-old-home-2025.png`, before 15 Oct 2025) shows **pure black** (`#05080A` → `#000000`). It also uses deeper hues: strain raw `#0D48BF`, yellow raw `#F3BD11`, sleep raw ≈ `#3A5A7C`. Its cause is **UNCONFIRMED** (an older build or a contrast/accessibility variant). Treat the slate gradient as current.

### 0.5 Caveat D: author annotations
`20`, `21` and `22` carry red hand-drawn circles added by the blog author (`#F13B3B`). Those pixels were excluded from all sampling.

### 0.6 Sources
1. WHOOP Developer **Brand & Design Guidelines** PDF, created 4 Jul 2023 with Acrobat Pro. Linked from https://developer.whoop.com/docs/developing/design-guidelines/ and stored at https://developer.whoop.com/assets/files/WHOOP%20-%20Brand%20&%20Design%20Guidelines-bdea3554e94b4ea09e68695b1e8dc8e7.pdf. Local copy: `00-whoop-brand-design-guidelines.pdf`; page renders `01-brand-guidelines-p1..p7.png`. Vector fill colours were read directly from the PDF drawing operators with PyMuPDF.
2. WHOOP Locker, "The WHOOP Home screen…" (2023 article, updated for the 2025 redesign): https://www.whoop.com/us/en/thelocker/the-all-new-whoop-home-screen/. Header image (3-dial render, 1800 × 1000): `10-marketing-three-dials-header.jpg`. The article's other images were product photos and were discarded.
3. the5krunner, "Whoop Homescreen Gets a Revamp" (15 Oct 2025): https://the5krunner.com/2025/10/15/whoop-homescreen-gets-a-revamp/ → `20`, `21`, `22`.
4. the5krunner WHOOP 5.0/MG review (31 Oct 2025): https://the5krunner.com/2025/10/31/2026-whoop-5-0-mg-review-discount-accuracy-strain-recovery-athletes/ → `23` (Blood Pressure Insights, Jul 2025) and `24` (insight card, Oct 2025). Home-scroll and customise images from the same post were saved by the reviews agent in `../images/reviews/04..07`; I measured them in place.
5. App Store listing screenshots saved by the App Store agent: `../images/appstore/ios69-01..10.png`. These are the default-size reference.
6. WHOOP site 2025 home video and 2026 "what's new" composite, saved by the site agent: `../images/whoop-site/02-home-screen-video.mp4`, frames `03..10` and `11-whats-new-2026-header-IMG_4459.png`. Frames I extracted: `25-site-video-dial-pressed-state.png` and `26-site-video-dial-to-deepdive-push-transition-strip.jpg`.
7. Mobbin public example images (circa 2023, WHOOP 4.0 era): https://mobbin.com/colors/brand/whoop → `30..33`.
8. Bureau Oberhaeuser case study (WHOOP's information-design studio, 2020–21): https://www.behance.net/gallery/100005325/WHOOP-Performance-Optimization-Platform → `40..45`. This is the lineage of the current visual language.
9. Design commentary: 925Studios, "WHOOP Design Breakdown", https://www.925studios.co/blog/whoop-design-breakdown. Secondary only; some of its claims, such as "almost entirely black", are contradicted by these measurements.
10. General guidance (section 13): Apple HIG JSON (dark-mode, charts, charting-data, color, typography, layout, accessibility, motion, tab-bars, materials); Material Design dark theme; Refactoring UI; Anthropic `frontend-design` skill; Vercel Web Interface Guidelines; Vercel "How to prompt v0"; v0 "Design Systems 2.0" docs.

---

## 1. Official brand rules (Developer Brand & Design Guidelines PDF, 7 pages, 1280 × 720 slides)

### 1.1 Colour palette, verbatim with the exact usage text
| Name in PDF | Hex (label) | Hex (actual vector fill) | Usage text in PDF |
|---|---|---|---|
| Black | `#000000` | `#000000` | "Use Black and White for Branding Elements." |
| White | `#FFFFFF` | `#FFFFFF` | (same) |
| TEAL | `#00F19F` | `#00F19F` | "The teal color is used for call to actions, highlights, positive evaluations, and Sleep Need." |
| Strain | `#0093E7` | `#0093E7` | "Use the Strain color for Activities and other Strain related topics." |
| High Recovery (100–67%) | `#16EC06` | **`#19EC06`** | "These three colors should be used for Recovery. Use High Recovery for a Recovery between 100-67%, Medium Recovery for a Recovery between 66-34% and Low Recovery for a Recovery between 33-0%." |
| Medium Recovery (66–34%) | `#FFDE00` | `#FFDE00` | (same) |
| Low Recovery (33–0%) | `#FF0026` | `#FF0026` | (same) |
| Sleep | `#7BA1BB` | `#7BA1BB` | "Use the Sleep color for Sleep related data for example Hours of Sleep," |
| Recovery Blue | `#67AEE6` | `#67AEE6` | "Recovery Blue is used for recovery related data, without a valuation." |
| Background Gradient | `#283339 - #101518` | `#283339`→`#101518` | "Use the background gradients for backgrounds." |

Extra fills in the PDF's dark example panels:
- Panel `#1A2227` (renders `#1A2126`)
- Inner card on the gradient ≈ `#2B3337`–`#3B4950` (a translucent white card)
- List-row card `#30363A`
- Placeholder bars `#596065`–`#747D82`
- Purple `#AC5AED`, used only in a **DON'T** example ("Use different colors for our main scores")

The app's green renders as `#19EC06`/`#19EC07` everywhere I measured, which matches the PDF vector rather than its label.

### 1.2 Typography rules, verbatim
- "Proxima Nova — Prefer to use Proxima Nova for words." "DINPro — Prefer to use DINPro for numbers."
- **Headlines:** "recommended to be used for short, important text such as titles or key text. Headlines are typically displayed in all caps and they hava a letter spacing of 10%." Spec: font Proxima Nova, weight **Bold**, character **10%**, text-transform **Uppercase**.
- **Body:** "spans from a B1 (L) to a B4 (XS) and it's typically used for long-form content." Spec: Proxima Nova, **Semibold**, character auto, no transform.
- **Numbers:** "used to display numerical data within the application. If a number is displayed within a block of text, the number can be styled to match the text it is contained within." Spec: DINPro, **Bold**, auto, none.
- Fallback fonts, in order: default platform sans-serif, Helvetica Neue, Helvetica, Arial. The PDF's text mistakenly says "Circular".
- The system is described as "elevated, open, and premium … simple enough to maintain clarity and consistency, and sophisticated enough to represent complex sets of data."

### 1.3 Logo rules
- The wordmark is the primary mark; the "Puck" icon is the secondary mark for app icons, favicons and small uses. The solid puck is "rarely utilized".
- Minimum sizes: wordmark 100 px, puck 30 px.
- Exclusion zone: x on all sides of the puck; 2x horizontally around the wordmark.
- DON'Ts: no recolouring (black or white only); no distortion or warping; no rotation; no busy backgrounds; never place your own logo next to WHOOP's visualised data.
- Attribution lock-ups: "DATA BY [WHOOP]", "IMPORTED FROM [WHOOP]", "POWERED BY [puck]".
- **ZENO must not use the WHOOP wordmark, puck or any of these lock-ups.**

### 1.4 Data-usage DOs and DON'Ts (page 6)
- **DON'T** rebrand or rename WHOOP metrics (example shown: "READINESS 70%").
- **DON'T** use different colours for the main scores (example shown: purple/blue rings).
- **DON'T** switch focus from score to title (example shown: a large "RECOVERY" with a small 70%). The score must dominate the label.
- **DON'T** use other metrics for the scores, or contradict WHOOP coaching.
- **DO** show "contextual value-added" cards.

Implementation reading: the number is the hero and the label is small. Each score keeps one fixed colour family.

### 1.5 Example visuals inside the PDF, measured
- **Recovery dial example** (page 5): a ring split into three arcs, 100% at the top in green, 66% at the bottom-left in yellow and 33% at the bottom-right in red, with an inner dashed reference circle and white tick dots.
- **CTA example:** an outline capsule button in teal, "CALL TO ACTION".
- **Strain example:** a bar chart in `#0093E7`, plus a list row with a blue rounded score badge "12.8" and the label "TITLE".
- **Sleep example:** range bars in `#7BA1BB` on a 9pm–9am axis.

---

## 2. Current-app palette, measured (2025–2026 builds)

### 2.1 Page background: a viewport-fixed vertical gradient
Sampled at the left and right screen edges. sRGB-correct source: `reviews/04` (Customize Dashboard, no tab bar), 393 × 852 pt.

| y (pt) | 0 | 50 | 100 | 150 | 200 | 250 | 300 | 350 | 400 | 450 | 500 | 550 | 600 | 650 | 700 | 750 | 800 | 850 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| colour | `#283339` | `#252F36` | `#232C32` | `#202A2F` | `#1E262B` | `#1C2328` | `#192125` | `#171D22` | `#151A1E` | `#13181C` | `#13181B` | `#12171A` | `#111619` | `#101518` | `#0F1417` | `#101216` | `#0F1214` | `#0E1213` |

- **Shape:** the colour moves almost linearly from `#283339` at y = 0 to `#13181C` at about 53% of the screen height (450 pt). It eases into `#101518` by about 76% (650 pt) and ends at `#0E1213` at the bottom. Projected onto the brand line, t = 0.43 at 23% height, 0.82 at 47%, 0.89 at 53% and 1.0 at 76%.
- The top is the brand "Background Gradient" start `#283339`; the brand end `#101518` arrives at about 76% of the height.
- **Fixed to the viewport, not the content.** The scrolled screenshots `05`, `06` and `07` still start at `#283238` at y = 0.
- **The home screen adds a bottom scrim** behind the floating tab bar. Content fades to about `#0F1011` over roughly the 28 pt above the tab bar (y ≈ 732 → 760 pt on 852), and the strip under the bar is `#010101`.
- Other screens: the July-2025 BP Insights screen and the App Store deep-dive mock-ups show the same gradient. The App Store home mock-up reaches flat `#101518` from about 285 pt down; that may be a mock-up simplification.
- The 2023 marketing render (`10`) uses the same gradient: `#29343A` at the top → `#13181B` at the bottom.

### 2.2 Surfaces: a translucent white overlay ladder
I compared card pixels against the background at the same y, just outside the card, on three screens and about 20 heights. The result is **α = 0.100 ± 0.003 white** at every height. Cards are translucent white over the fixed gradient, so a card is lighter when it sits near the top of the screen. Example: Strain & Recovery card is `#353C41` at y = 173 pt and `#272B2E` at y = 633 pt.

| Layer | White overlay | Evidence |
|---|---|---|
| Page | 0% | gradient above |
| Chart gridline on a card | ~5% over the card | `#3A4044` on card `#30363A` (1 pt) |
| **Card / tile / list row / dial track / divider / today band** | **10%** | cards (all screens); dial track `#353B3F` on `#1F252A`; callout divider `#3A3E41` on `#23282C`; chart "today" band `#42474B` on `#2E3336` |
| Nested control inside a card ("SET ALARM", "ADD ACTIVITY") | +10% over the card (≈ 20% total) | `#3D4040` on card `#28292C` |
| Dashed connector, Recovery trend line | 25% | `#5E6062` on `#28292C`; line `#606467` on `#30363A` |
| Strain-target band on the dial | ~27% | `#5C6063` on `#1F2429` |
| Dial press highlight | ~40% (disc filling the ring interior) | video frame `#747A7C` on `#1A2125` |
| Dark well (legend pill under contributors) | black ~50% | `#090C0D` on `#12171B` |

Solid fallbacks for the 10% card at typical positions: `#2D3236` (≈300 pt), `#2B2F33` (≈380 pt), `#292C2E` (≈600 pt). Cards have **no shadow**, and home cards have **no border**.

### 2.3 Text and icon colours: an opacity ladder
| Role | Measured | As white-opacity | Examples |
|---|---|---|---|
| Primary | `#FFFFFF` | 100% | numbers, titles, labels |
| Strong button text | `#DEDEDE` on `#3D4040` | ~85% | "SET ALARM" |
| Secondary | `#BFBFC0`–`#C0C1C2` (on card), `#B5B6B6` (on dark well) | **70%** (fits all three) | "5/5 Metrics", "1:00 AM", "RECOMMENDED BEDTIME", "vs. prior 30 days", coach body text |
| Tertiary | `#8D9193`–`#97999B` | **50%** (fits all) | chevrons, battery "97%", baseline values under metrics, axis labels, inactive tabs, section labels ("ADD TO MY DASHBOARD"), the in-ring wordmark |
| Disabled chevron (">" when the next day is unavailable) | `#83878A` | ~40% | date navigator |
| Line icons in rows | `#8D8F91`–`#999C9E` | 50% | row leading icons |

### 2.4 Semantic accent colours (sRGB, verified on sRGB-correct images)
| Token | Hex | Where seen |
|---|---|---|
| Recovery high | `#16EC06` (rendered `#19EC06`) | recovery ring ≥67%, green recovery points/labels |
| Recovery medium | `#FFDE00` | 34–66% |
| Recovery low | `#FF0026` | 0–33% |
| Strain | `#0093E7` | strain ring, strain line/labels, activity badges (`#0090E4`), activity bars in charts |
| Sleep | `#7BA1BB` | sleep ring, sleep activity badge (`#789CB8`), sleep HR chart line |
| Recovery Blue (neutral) | `#67AEE6` | outline buttons ("SAVE"), the cool end of the stress gauge, the 2023 "I HAVE A WHOOP DEVICE" outline |
| Teal (positive / optimal / within range / CTA) | `#00F19F` | "WITHIN RANGE", "MEDIUM" (stress), ▲ favourable trend, "Optimal" segment, positive behaviour bars, live-session text |
| Teal tint fill | teal at 16% over the card ≈ `#244C43` | status badge squares |
| **Orange (unfavourable)** | **`#FFA722`** | ▼/▲ unfavourable trend triangles, "Poor" segment, "ALARM OFF", negative behaviour bars, "Highest" label on BP, stress gauge hot end. **Not in the brand PDF** but used consistently. |
| Trend neutral | `#8D9193` (▲ grey) / grey dot ● | "no meaningful change" |
| AI / coach gradient (text) | `#8371FF` → `#6E9AFF` → `#5FB5FE`; arrow `#5FB9FF` | "BREAK DOWN MY RECOVERY →", "EXPLORE YOUR RECOVERY INSIGHTS →" |
| AI / coach gradient (border) | left `#4D3D8C` → right `#31738C` (≈ violet→cyan at ~55% opacity), ~1.5 pt | insight cards |
| Coach button ring | `#6EB1FE` blue with purple, on dark indigo fill `#171728`→`#121A25` | tab-bar AI button |
| "Your Day In Review" pill | horizontal `#2D284D` (indigo) → `#293F52` (slate-teal) | evening pill |
| "Your Daily Outlook" pill | horizontal `#69655A` (khaki) → `#283B45` (slate) | morning pill |
| Action menu popover | vertical about `#4A5157` → `#33383D` (opaque grey glass) | `22` |
| Streak flame | gold gradient `#ECC46C` → `#F2D89E` (Oct 2025); orange-red in the App Store mock-up | top bar |
| Connected dot on strap icon | **teal `#00F19F`**: raw `#6EEDA5` on the P3 device image converts to `#02F19E`; the App Store mock-up shows the same dot (small, anti-aliased) | top bar |
| HR zones (2026 composite; dimmed panels, **approximate**) | Zone 1 ≈ `#A8C0CC`, Zone 2 ≈ `#3C84A8`, Zone 3 ≈ `#2A5442` (dimmed green), Restorative = white; **Zones 4–5 UNCONFIRMED** | HR zone bars |
| Menstrual calendar (2026 composite) | purples `#5A367E` / `#7E42AE`, coral `#FC7260`, lavender `#8A8ACC` | Health tab |
| WHOOP Age orb | green particle sphere `#004E30`→`#00F19F` sparkles | Healthspan |

Lineage: the brand red `#FF0026` measures about 4.5:1 on a 10% card, borderline for small text. ZENO's current theme already ships a lighter text red `#FF4A5C`, and that is a good practice to keep.

---

## 3. Typography, measured

### 3.1 Faces
- **Words:** a geometric grotesque matching Proxima Nova, as the brand says. Visible traits: single-storey "y", round "o", flat-topped "t".
- **Numbers:** DIN-style bold (DINPro Bold), as the brand says. Square-shouldered digits with straight-sided 0 and 8, and a "%" drawn smaller.
- **The deep-dive hero numbers use a wider DIN than the small numbers.**
  - Ink width/height of single digits in the **big score** (85, 74, 14.2, about 58 pt): 8 = 0.75, 5 = 0.74, 7 = 0.76, 4 = 0.73, 2 = 0.72, 1 = 0.45.
  - In **small numerals** (home dials about 28 pt, list values about 17 pt, "8:00", "10:34", "56%"): 9 = 0.62, 8 = 0.62, 5 = 0.61, 4 = 0.67, 0 = 0.60.
  - So the small numerals are condensed and the hero score is regular width.
- **SF Pro calibration** (system variable font, Bold, ink width/height):
  - Width 100: 8 = 0.78, 5 = 0.76, 4 = 0.83 → close to the **hero** score.
  - Width 60 (SF "Condensed") to 75: 8 = 0.63–0.67, 5 = 0.57–0.63 → close to the **small** numerals.
  - SF named widths: Compressed 47, **Condensed 60**, Semi-Condensed 80, Standard 100, Expanded 132.
  - SF Pro cap height = 0.705 em; digit height = 0.73 em.

### 3.2 Default type scale (App Store mock-ups at default Dynamic Type)
Sizes are converted to SF Pro by cap-height matching (cap ÷ 0.705). The home mock-up resolves ±0.5 pt; the deep-dive mock-ups ±0.3 pt.

| Element (exact text) | Cap/digit height | SF-equivalent size | Weight | Case and tracking | Colour |
|---|---|---|---|---|---|
| Deep-dive score "85" / "74" / "14.2" | 41.2 pt (digits) | **≈58 pt** (fixed) | Bold, regular width | – | white |
| Deep-dive "%" | 22.5 pt | ≈32 pt (0.55× the digits) | Bold | baseline-aligned | white |
| Home dial number "80" / "98" / "9.8" | 19.3–20.2 pt | **≈28 pt** (fixed) | Bold, condensed | – | white |
| Home dial "%" | 14.3 pt (glyph) | ≈20 pt (0.74×) | Bold | baseline-aligned | white |
| Home section header "My Day" / "My Plan" / "My Dashboard" | 14.0 pt | **≈20 pt** | Semibold (stem/cap 0.18) | Title Case, 0 tracking | white |
| Deep-dive section header "Today's Activities" / "Last Night's Sleep" | 11–12.2 pt | ≈16–17 pt | Semibold | Title Case | white |
| Coach card title "Optimal Health", pill title "Daily Outlook" | 9.8 pt | ≈14 pt | Semibold | Title Case | white |
| Coach / insight body ("Your HRV is elevated while…") | 9.8–9.9 pt | ≈14 pt | Medium–Semibold | sentence case | white (deep-dive insight) or 70% (home coach card) |
| Card title "HEALTH MONITOR", "STRESS MONITOR" | 8.3 pt | **≈12 pt** | Bold | UPPER, +0.7 pt (≈6%) | white |
| Secondary line "5/5 Metrics", "4:31pm" | 8.3 pt | ≈12 pt | Semibold | sentence case | 70% |
| Nav title "TODAY" (deep dive) | 8.4 pt | ≈12 pt | Bold | UPPER, ≈+1.2 pt (10%) | white |
| Date pill "TODAY" | 7.2 pt | ≈10–11 pt | Bold | UPPER, ≈+0.6 pt | white |
| Dial label "SLEEP" / "RECOVERY" / "STRAIN" + chevron | 7.24–7.33 pt | **≈10.5–11 pt** (fixed) | Bold | UPPER, **+1.0 pt (≈10%)** | white; chevron 50% |
| Contributor row label "HEART RATE VARIABILITY" | 7.24 pt | ≈10.5–11 pt | Bold | UPPER, +0.9 pt (≈9%) | white |
| Label under score "RECOVERY" / "SLEEP PERFORMANCE" / "DAY STRAIN" | 7.24 pt | ≈10.5–11 pt | Bold | UPPER, tracked | white |
| CTA link "BREAK DOWN MY RECOVERY →", "EDIT" | 7.24 pt | ≈10.5–11 pt | Bold | UPPER, ≈+1 pt | gradient (CTA) / white (EDIT) |
| Status word "WITHIN RANGE", "MEDIUM" | ≈6.7–7.2 pt | ≈10–10.5 pt | Bold | UPPER, tracked | teal |
| Row value "124" / "49" / "14.5" / "74%" | 11.8–12.2 pt | **≈17 pt** | Bold, condensed | – | white |
| Legend "Today vs. prior 30 days" | 8.0 pt (T) | ≈11–12 pt | Semibold ("Today") / Regular (rest) | sentence | white / 70% |
| Tab labels "Home" "Health" "Community" "More" | 7.2–7.8 pt | ≈10.5–11 pt | Medium/Semibold | Title Case | white selected / 50% |
| Streak "355", battery "65%" | 9.3 pt | ≈13 pt | Bold (DIN) | – | white / 70% |
| In-ring wordmark (deep dive) | 9.9 pt tall | – | light geometric wordmark | – | 50% grey (**do not copy**) |

**The same user at a larger Dynamic Type setting** (`21`, `reviews/04..07`) measured as follows. Use these only as evidence that the text scales.
- "My Day" ≈26.5 pt; card titles ≈15 pt (wrapping to two lines); "Your Day In Review" ≈19 pt; secondary ≈15 pt; tab labels ≈14 pt.
- Dashboard tile value "56%" ≈28 pt with baseline ≈15 pt; row labels ≈15 pt; "CUSTOMIZE DASHBOARD" ≈17 pt; section label "ADD TO MY DASHBOARD" ≈14 pt (50% grey); outline button "SAVE" ≈17 pt.
- Default sizes of the dashboard tiles and the customise list are **UNCONFIRMED**. Expect about 0.7–0.77× of these.

### 3.3 Letter-spacing (tracking) calibration
I solved for the extra per-letter tracking SF Pro Bold needs to reproduce WHOOP's measured ink widths:
- Small UPPERCASE labels (10–11 pt): **+0.8–1.0 pt ≈ 8–10% em**. This matches the brand's "10%" rule.
- UPPERCASE card and row titles (12–15 pt): +0.6–1.0 pt ≈ 4–7% em.
- UPPERCASE screen titles (17 pt): ≈ +0.3 pt ≈ 2% em.
- Title-case headers and body: 0.

### 3.4 Number and copy formatting seen
- Percent: digits + a smaller "%" sharing the baseline. Home dials use % at 0.74× the digit height; the deep dive uses 0.55×.
- Strain: one decimal ("9.8", "14.2", "19.6"). Recovery and sleep: integer %.
- Clock times: "8:00", "6:29", "12:51 AM", "7:38 AM", "10:15 PM", "4:31pm". Both "PM" and "pm" appear, so WHOOP is inconsistent.
- Durations: "0:17:41", where the seconds ":41" are smaller and grey; "2:15 hrs", where "hrs" is smaller and grey.
- Metric tiles show the value, a small trend triangle to its right, and the baseline (30-day average) in grey below the value.
- Ranges: "128-148" with the unit "mmHg" on its own smaller grey line.
- Dates: "OCT 14 TO TODAY", "JUN 06 - JUL 0…", "AUG 19 - AUG 26" (uppercase); chart axes use "Mon / 8" on two lines.
- Copy voice:
  - Insights are sentence case and plain ("Your HRV is elevated while your RHR, Respiratory Rate, and Sleep Performance are all typical, resulting in a higher Recovery today.").
  - CTAs are UPPERCASE imperatives with an arrow ("DIVE INTO MY SLEEP →", "EXPLORE MY STRAIN →", "BREAK DOWN MY RECOVERY →").
  - Menu actions are UPPERCASE verbs ("START ACTIVITY", "ADD ACTIVITY", "STRENGTH TRAINER", "COMPLETE YOUR JOURNAL", "CREATE WHOOP LIVE").

---

## 4. Layout and spacing (393 pt-wide device)

### 4.1 Global
- **Horizontal page margin: 16 pt.** Cards span x = 16 → 377 pt (measured 48 px / 1130 px at 3x, and 16.5 pt in the mock-up).
- **Gaps:**
  - Side-by-side cards: 12 pt (36 px; 12.4 pt in the mock-up).
  - Stacked tiles and list rows: 12 pt.
  - Cards stacked inside a section ("Daily Outlook pill" → "Today's Activities"): 16–17 pt.
- **Card inner padding: 16 pt.** Title text starts 17 pt in from the card edge (16 + side-bearing). The top padding to the title cap is about 16 + 3.7 pt.
- **Section rhythm:**
  - About 40–42 pt from the previous card's bottom to the next section header's cap top.
  - 24 pt from the header baseline to the first card (24.3 pt on device; 24.7 pt in the mock-up).

### 4.2 Home, top to bottom (default text, App Store mock-up; device values where text size does not matter)
| Element | y range (pt) | Notes |
|---|---|---|
| Status bar | 0–54 | Dynamic Island device |
| Top bar row | ≈59–91 (centre ≈75) | avatar Ø ≈28–29 pt circle, x 16–44; streak pill (flame + "355") h ≈32; date navigator: an outer capsule (≈30–32 pt tall) holding a white "‹", an inner lighter pill "TODAY" (`white ~18%`, h ≈32, radius ≈12) and a grey "›" (disabled on today); right: bolt + "65%" + strap outline icon with a green connected dot |
| Wordmark | ≈123–134 | 72 × 12 pt, centred. **ZENO uses its own mark here.** |
| Dial row | ring top ≈159, bottom ≈246 | 3 dials of Ø 88 pt; centres at x = 75.5 / 196.5 / 317.5 pt (121 pt pitch); outer ring edges 31.7 pt from the screen edges; 33 pt between rings |
| Dial labels | cap top ≈259, bottom ≈266 | 12.3 pt below the ring |
| Coach card ("Optimal Health" + body, stacked-card look, check icon + "2" pager on the right) | ≈306–441 (+ a peeking second card to ≈466) | 10% white-ish fill (slightly lower, ≈6–8%); time-of-day dependent; may be absent |
| Health / Stress Monitor pair | ≈468–565 (96 pt tall at default; 138 pt at large text) | two cards, 12 pt gap |
| "My Day" header + "+" button | cap top ≈607 | white 36 × 36 pt "+" square, radius ≈12, dark glyph, vertically centred on the header |
| Daily Outlook / Day In Review pill | ≈645–692 (**48 pt tall**, also 48 on device) | full width |
| Today's Activities card | from ≈709 | rows, then "+ ADD ACTIVITY" / "START ACTIVITY" buttons |
| Floating tab bar | device: y 760–824 | see 4.3 |

### 4.3 Floating tab bar (Oct 2025 build, iOS 26 "Liquid Glass" style)
- **Capsule:** x 12 → 305 pt (≈293 pt wide), **64 pt tall**, fully rounded. Fill is translucent dark glass with a vertical gradient `#252A30` → `#191E23` and a faint lighter rim.
- **Items:** Home, Health, Community ("Commu…" truncated at large text), More. Icon about 22 × 21 pt above the label. Selected = white icon + white label + a soft lighter blob behind (`#2D3438`); unselected = 50% grey.
- **Separate AI/coach button:** 64 × 64 pt squircle (radius **UNCONFIRMED**, about 22–26 pt), 12–13 pt to the right of the capsule and 12 pt from the screen edge. Dark indigo fill with a gradient ring (blue `#6EB1FE` → violet) around a W monogram. **Replace the W in ZENO.**
- **Pre-Oct-2025 build** (`20`): a classic full-width tab bar on black, with a floating white circular "+" button at the bottom-right above it.
- Bottom safe area under the bar: black (`#010101`). Content above fades out over about 28 pt.

### 4.4 Corner radii (circular-arc fits)
| Element | Radius | Confidence |
|---|---|---|
| Cards, tiles, list rows (Health/Stress Monitor, Tonight's Sleep, customise rows) | **≈11.3–12 pt** (34–36 px at 3x; arc profile reaches the straight edge by about 31–33 px). Circular, not a continuous squircle. | high |
| Deep-dive insight card (gradient border) | ≈10.5–12 pt | medium (mock-up) |
| "+" square button 36 pt | ≈11.7 pt | high |
| Date "TODAY" inner pill (h ≈32) | ≈12 pt (not a capsule) | medium |
| Legend well / small inner pills | ≈7–8 pt | medium |
| Status badge squares (24 pt) | ≈3–4 pt | medium |
| Outline primary button ("SAVE", h ≈53 pt at large text) | capsule | high |
| Action menu popover | ≈20 pt | low (visual estimate) |
| Mini segment bars (20 × 4 pt) | ≈1 pt | medium |

---

## 5. Score dials and rings (the signature element)

### 5.1 Home dials (real device, 3x)
- **Outer diameter 88 pt; stroke 6 pt (6.8% of the diameter).** The track and the progress arc have the **same width**.
- **Track:** white 10% over the background, measured `#353B3F` at that y (the deep-dive mock-up shows `#2F3539`).
- **Start angle 12 o'clock, clockwise.** The full circle is the full scale:
  - Recovery 0–100%
  - Sleep 0–100%
  - Strain **0–21**. 9.8 → 168°, 14.2 → 243° (measured 241.5°).
- **Caps:** a **flat (butt) end with slightly rounded corners**, corner radius ≈1/5 of the stroke (≈1.2 pt at 6 pt; ≈3 pt on the 15 pt deep-dive ring). Both the start at 12 o'clock and the moving end look like this. The 2023 marketing render (`10`) used fully round caps; the current build does not.
- **Strain extra:** a lighter grey band (white ≈27%, `#5C6063` / `#56595D`) continues clockwise from the end of the blue arc to an upper bound, with a **white tick** (≈1 pt × stroke height) inside the band.
  - Device: blue to 168° (9.8), band to 219° (≈12.8), tick at 186–189° (≈10.9).
  - App Store: blue to 241.5° (14.2), band to 276.5° (≈16.1), tick at 250.5–252° (≈14.6).
  - The visual reading is a strain-target window. Its exact semantics are **UNCONFIRMED**: the App Store home card says "Strain target of 15.5", which matches neither the tick nor the band end.
- **Number:** centred, bold condensed DIN-style about 28 pt, white, "%" at about 0.74× the digit height for Sleep and Recovery. Strain has no unit.
- **Label below:** UPPERCASE Bold about 11 pt, tracked +1 pt, white, followed by a grey chevron "›". The label's cap top sits 12.3 pt below the ring.
- **Press state** (WHOOP site video `25`): on touch-down the ring interior fills with a **white ≈40% disc** (`#747A7C`). On release, the deep dive is pushed.
- **Compact sticky header** when Home scrolls (`reviews/05..07`): three mini rings (**24 pt diameter, 2 pt stroke**) inline with "SLEEP · RECOVERY · STRAIN" labels across the top.

### 5.2 Deep-dive ring (App Store mock-ups at 393 pt)
- **Diameter ≈260 pt** (259.5), **stroke ≈15.2 pt (5.9% of the diameter)**, horizontally centred (centre x = 196.5 pt). Same start, direction, caps and track as the home dial.
- **Inside the ring, top to bottom:**
  1. The in-ring wordmark in 50% grey (≈10 pt tall). **ZENO should use its own small mark or nothing.**
  2. Score ≈58 pt Bold, regular width, with "%" ≈32 pt.
  3. Label ≈11 pt UPPERCASE tracked ("RECOVERY", "SLEEP PERFORMANCE" on two lines, "DAY STRAIN").
  4. Sleep only: a 3-dash indicator below (each dash ≈ 10 × 2 pt; one is teal, the others grey). Meaning **UNCONFIRMED**.
- **Nav bar above:** "‹" back chevron (≈23 pt tall glyph, white), centred title "TODAY" (≈12 pt Bold tracked), and an ⓘ info button (≈28 pt outlined circle with a serif "i", 50% grey).

### 5.3 Other gauges
- **Stress Monitor gauge** (2025–26): an open arc of about 270°, gap at the bottom. Colour runs along the arc from Recovery Blue `#67AEE6` → teal `#00F19F` → yellow → orange `#FFA722`. A white tick/needle sits at the current value. Big number "1.5" with the level word below ("MEDIUM" in teal) and end labels "0.0" / "3.0". "Last updated 3:05pm" is in grey.
- **Blood Pressure Insights gauge** (`23`): a large open arc of about 220°, in segments separated by small dark gaps. Teal-green on the left → yellow at the top → orange on the right, each segment carrying a soft inner gradient. A white glossy marker sits at the estimate. Inside: "TODAY'S ESTIMATE" (grey tracked), "138/88" big white, and two columns "SYSTOLIC 128-148 mmHg" / "DIASTOLIC 83-93 mmHg". A "BETA V1.0 ⓘ" chip sits under the title.
- **Live session ring** (2026 composite): a full ring with a blue→teal gradient glow, "ACTIVE" and "01:29" in teal.
- **WHOOP Age orb** (Healthspan): a green particle sphere with "29.9 / WHOOP AGE / 2.3 years younger". Do not copy the illustration style 1:1; build an original visual for ZENO.

---

## 6. Components (what each looks like, measured)

1. **Monitor card pair (Health Monitor / Stress Monitor).**
   - 12 pt radius, 10% white, 16 pt padding.
   - Title is UPPERCASE Bold ≈12 pt tracked with a "›" grey chevron. At default size the chevron is inline after the title; at large text it sits at the top-right.
   - Status row: a 24 pt square badge (radius ≈3–4, teal 16% fill) holding a teal ✓ or a teal number ("1.5", Bold); beside it the status word ("WITHIN RANGE" / "MEDIUM", teal Bold tracked) above a secondary line ("5/5 Metrics" / "4:31pm", 70%).
2. **Coach / outlook card** ("Optimal Health").
   - Title Case semibold title, 70% body, a check icon plus a pager count "2" in a small rounded rect at the top-right.
   - A second card peeks out underneath, inset about 16 pt per side and 12 pt below, to signal a stack.
3. **Gradient pill row**: "Your Daily Outlook" (morning, khaki → slate) and "Your Day In Review" (evening, indigo → slate-teal). 48 pt tall, sun or moon line icon at the left, Title-Case ≈14 pt text, "›" at the right.
4. **Today's Activities card.**
   - UPPERCASE title plus an expand icon ⤢ (top-right).
   - Rows: a coloured score badge (rounded rect ≈64 × 40 pt, radius ≈8 **UNCONFIRMED**) filled in the activity colour (sleep `#7BA1BB`, strain `#0093E7`), holding a white glyph (moon / sport) and a white DIN value ("8:18", "12.8"). Then the UPPERCASE activity name; then right-aligned start/end times in 50% grey with a thin vertical bar in the activity colour; a "[Wed]" prefix appears when an activity spans midnight.
   - Footer: two nested buttons "+ ADD ACTIVITY" and "◷ START ACTIVITY" (20% white).
5. **Tonight's Sleep card.**
   - Two columns, each an icon plus a big DIN value: "Now" (sunset-arrow-down icon) and "8:00" (sunrise-arrow-up icon), joined by a dashed line (25% white).
   - Labels below: "RECOMMENDED BEDTIME" (70% UPPERCASE) and "ALARM OFF" (orange UPPERCASE).
   - A full-width nested button "SET ALARM" with a strap-vibrate icon (20% white fill, text 85%).
6. **My Journal card**: a weekday strip ("M… TUE WED T… FRI SAT SUN"). Completed days show green filled check circles, consecutive days merge into a green capsule, and empty days show a grey ring. Then a full-width nested button "RECOVERY INSIGHTS" with a lightbulb icon.
7. **My Plan card**: "BOOST FITNESS PLAN" with a ⌄ disclosure; "0 days left" (70%); "100% ACCOMPLISHED", with "100%" in big DIN and the word UPPERCASE; a full-width teal progress bar (≈4 pt).
8. **Dashboard tiles (My Dashboard)**: full-width rows, 12 pt gap, radius 12.
   - Leading line icon (50%), UPPERCASE Bold label.
   - Trailing: big DIN value, a small ▲/▼ triangle (teal favourable / orange unfavourable / grey neutral), and the baseline below in 50% grey ("76%", "53%", "9:12").
   - Header row: "My Dashboard" (Title Case) and a right-side "CUSTOMIZE ✎" (UPPERCASE Bold tracked + pencil).
   - The feed ends with a centred membership wordmark (theirs: "WHOOP LIFE"). Do not copy.
9. **Deep-dive contributors callout.**
   - The card attaches to the ring through a small **upward pointer triangle** (≈15 × 7 pt) at the top centre.
   - The fill is a **radial glow centred on the pointer**. I measured white-overlay % against the page across the card:
     - 4.6 pt below the top: 2.2 / 4.5 / 5.9 / 7.4 / **9.8 (centre)** / 8.9 / 7.6 / 6.1 / 4.5 / 2.9 from left to right.
     - At 86 pt down: ≈6% in the centre and 1–2% at the edges.
     - At 132 pt: ≈4%.
     - At 190 pt: ≈0–2%, i.e. it blends into the page.
   - The edge is a 1 pt stroke that is brighter where the glow is (top-lit glass edge, ≈7% at the top) and fades away toward the bottom.
   - Rows are 53.4 pt pitch with 1 pt dividers (white 10%) inset 16 pt from the card edges. Each row: line icon (≈20 pt, 50% grey) at x = 36 pt, UPPERCASE label at x = 65 pt, then a right-aligned DIN value at ≈17 pt plus a trend glyph.
   - A dark legend well at the bottom (black 50%, radius ≈8, h ≈31 pt): "▲▼ Today vs. prior 30 days" (Recovery/Strain) or "▬ Poor ▬ Sufficient ▬ Optimal" (Sleep).
10. **Sleep contributor mini-bars**: three segments of 20 × 4 pt with 2 pt gaps. The active segment is coloured (orange Poor, grey `#848586` Sufficient, teal Optimal); the others are white 10–12%.
11. **Insight / coach card (deep dive)**: transparent fill, **1.5 pt gradient border** (violet → cyan), radius ≈12, 16 pt padding. White body ≈14 pt. The CTA is UPPERCASE Bold tracked with **gradient text** (violet → sky) plus a blue "→".
12. **Recovery Insights row card**: 10% card, lightbulb line icon, UPPERCASE title, 70% two-line description, "›".
13. **Action (+) menu** (`22`):
    - A large popover anchored at the top-right below the "My Day" header, radius ≈20, opaque grey glass gradient, about 16 pt inset from the screen edge.
    - Five rows, each a 28 pt line icon (white 70%) and an UPPERCASE Bold label tracked ≈10% (white), about 50 pt apart.
    - The trigger "+" turns into a dark rounded-square "✕" close button.
    - The content behind stays visible (no dimming, or very little).
14. **Customize Dashboard** (full-screen modal):
    - "✕" close at the left, then an UPPERCASE Bold title.
    - Section label "ADD TO MY DASHBOARD" (50% grey, tracked) followed by a 1 pt hairline extending to the right edge.
    - Rows of 10% cards, each a line icon, an UPPERCASE label and a white "+" at the right.
    - A pinned **outline capsule button "SAVE"**: 2 pt Recovery Blue `#67AEE6` stroke, same-colour text, ≈322 pt wide.
15. **Buttons, overall**:
    - (a) outline capsule (Recovery Blue, or teal in the brand example);
    - (b) white filled rounded rect with black UPPERCASE text ("SELECT TESTING FREQUENCY", App Store "Advanced Labs");
    - (c) nested 20%-white rounded rect (in-card actions);
    - (d) white 36 pt "+" square;
    - (e) text CTA with arrow.
16. **Chips / tags**:
    - "BETA V1.0" / "BETA V2.0": small rounded rect, 10–20% white, UPPERCASE Bold.
    - "NEW": blue outline tag; its row also gets a blue outline.
    - "✓ Jan 14, 2024 - 7:42am": teal text on a teal-tint chip.
    - "▲ vs. typical Tuesday": orange text on an orange-tint chip.
17. **Segmented control** (BP "W | M"): a dark well (black 50%, radius ≈10) with the selected segment as a 10% white rounded rect. Labels are UPPERCASE Bold, white selected and grey otherwise.
18. **Date-range navigator** (charts): "‹ JUN 06 - JUL 0… ›" UPPERCASE Bold, white chevron left and grey chevron right.
19. **Hatched tracks** (2025–26, HR zones and behaviour impact): the empty part of a bar is drawn as **45° diagonal hatching**, thin lines at about 4 pt spacing in white ≈6–8%, instead of a flat track.
20. **Diverging behaviour bars** (Journal Insights): a white centre dot (≈4 pt) on a hatched track. Positive is a teal bar to the right, negative an orange bar to the left. Label UPPERCASE at the top-left, value "+13%" / "-6%" in the bar's colour at the top-right. The header shows "▼ HURTS | % IMPACT | HELPS ▲".
21. **HR zone rows**: a header "ZONE 2 (60-70%) 16%" (UPPERCASE; the % in the zone colour), a duration "0:17:41" at the right with small grey seconds, and a zone-coloured bar on a hatched track. Each row sits in its own 10% card.
22. **Empty / no-data states**: in charts, missing days are skipped and the line connects across them (Wed 10 and Sat 13 in the Strain & Recovery chart). Other empty states are **UNCONFIRMED** (none captured).

---

## 7. Charts (measured specs)

- **Container:** a 10% card with 16 pt padding, UPPERCASE title at the top-left and an ⓘ outlined info icon (50%) at the top-right.
- **Gridlines:** horizontal only, 1 pt, white ≈5% over the card, at round values (0/7/14/21; 0/1/2/3; 30/50/70/90).
- **Axis labels:** DIN Bold, 50% grey. **Dual-axis colouring**: strain values (left) in strain blue; recovery values (right) in the colour of their zone (0% red, 33% red, 66% yellow, 100% green).
- **Strain & Recovery (weekly)**:
  - Strain line is strain blue at about 50% opacity (`#186794` on the card), ≈2 pt, with **hollow circular markers** (≈8–9 pt) that have a 2 pt strain-blue stroke and a dark fill. Value labels sit above the markers in strain blue DIN Bold.
  - Recovery line is white 25% (`#606467`), ≈2 pt; its markers are stroked in the zone colour and its labels coloured by zone.
  - X axis has two-line labels "Mon / 8". **Today** is highlighted with a white 10% rounded vertical band behind its column and a white label (other labels are 50%).
- **Stress Monitor (24 h)**:
  - A line (≈2 pt) whose **colour follows the value**: cyan/teal (low) → green → yellow → orange (high).
  - Activity periods are drawn as translucent strain-blue vertical bands with a 3 pt strain-blue bar on the top gridline; sleep bands use a sleep-colour bar. Activity glyphs (moon, bike, walker) sit above.
  - A **dotted vertical "now" line** with a dot at the bottom.
  - The x labels show start, middle ticks and the bold white current time "10:15 PM".
  - The header line reads "Last updated 10:15 PM" (70%) on the left and "MEDIUM 1.1" (teal word + white DIN number) on the right.
- **Sleep heart-rate chart**:
  - A sleep-colour line (≈1.5 pt) with a **vertical gradient area fill** (sleep colour about 35% → 0%).
  - Dashed vertical lines at sleep start and end, each with a dot at the bottom, and a sunset/sunrise icon plus time below ("12:19am", "9:04am").
  - Footer: "TYPICAL RANGE" (with a dashed-box legend glyph) and "TIME IN BED 8:48".
- **BP range chart**: grey rounded range bars (≈5 pt wide, white 15–20%) with yellow dashes for estimates and an orange dash for a manual high. Labels "Highest" (orange) and "Lowest" (teal) sit at the top and bottom reference lines. A legend shows "— MANUAL READING ▬ WHOOP ESTIMATE".
- **Historic (Bureau Oberhaeuser 2020, `43`)**: 7-day trend charts. Recovery is a line with zone-coloured dots; Strain uses strain-blue bars with a target marker; Sleep uses slate range bars. Each chart has a stat row underneath (icon + value + label). The language is the same: dark slate, thin grey gridlines, coloured data only.

---

## 8. Iconography

- **Line icons:** about 1.5 pt stroke with rounded caps and joins, in 50% grey for row leading icons and white for active states. Examples: HRV waveform-in-heart, heart-with-down-arrow (RHR), lungs, sleep-arc, clock-arc, scale, strap, lightbulb, sun, moon, sunrise and sunset with arrows.
- **Activity glyphs:** filled white pictograms inside coloured badges and above charts (cycling, functional fitness, walking, meditation).
- **Chevrons:** thin "›" at about 13 pt tall, 50% grey, about 20 pt from the card's right edge.
- **Tab icons:** outline house-with-trend, heart-with-pulse, group of people, three-bar menu. The selected tab turns white; the icons are not filled.
- **Do not copy WHOOP's icons, illustrations (the 3D heart, the WHOOP Age orb), monogram or wordmark.** Use SF Symbols in the same outline-thin style: `heart`, `waveform.path.ecg`, `lungs`, `bed.double`, `moon.fill`, `sun.max`, `sunrise`, `sunset`, `figure.outdoor.cycle`, `figure.strengthtraining.functional`, `lightbulb`, `plus`, `xmark`, `chevron.right`, `info.circle`, `pencil`, `arrow.up.left.and.arrow.down.right`, `house`, `person.3`, `line.3.horizontal`. Render them with `.symbolRenderingMode(.monochrome)`, at `.light` or `.regular` weight to match the thin strokes.

---

## 9. Navigation and screen chrome

- **Tabs:** Home · Health · Community · More, plus the separate AI coach button, all in a floating glass capsule (section 4.3).
- **Home header:** avatar, streak, date navigator ("‹ TODAY ›" / "‹ OCT 14 TO TODAY ›"), battery and strap status. There is no navigation title; the wordmark sits in the content.
- **Deep dives:** a push navigation with a custom bar ("‹", UPPERCASE centred title, ⓘ). The video shows the deep dive sliding in from the right in about 0.4 s (about 5 frames at 12 fps), which is a standard iOS push and not a zoom.
- **Modals:** Customize Dashboard is full-screen with "✕" at the top-left, an UPPERCASE title and a pinned bottom action. The Action menu is a popover with an "✕" close.
- **Section headers in the home feed:** "My Day", "My Plan", "My Dashboard". They are Title Case, large and left-aligned, with an optional right accessory ("+" button or "CUSTOMIZE ✎").

---

## 10. Motion (observed vs UNCONFIRMED)

**Observed:**
- Dial press shows an instant 40%-white disc.
- Deep dives use a standard push slide of about 0.4 s.
- Content scrolls under a sticky compact header with mini rings.
- The background is fixed (no parallax).

**UNCONFIRMED:**
- Whether the dial arcs sweep on load. The video showed already-drawn rings on the deep dive.
- Number count-up effects.
- Haptics.
- The animation of the Action menu.

---

## 11. Lineage: what has stayed constant since 2020

- Bureau Oberhaeuser's 2020 system (`40..45`) already had the slate gradient, DIN numerals, UPPERCASE tracked Proxima labels, zone-coloured recovery rings, outline capsule buttons, a strain scale with LIGHT 0–10 / MODERATE 10–14 / STRENUOUS 14–18 / ALL OUT 18–21, and 7-day trend charts.
- The 2023 Mobbin screens (`30..33`) show the same: outline pill buttons in Recovery Blue, list cards with UPPERCASE titles, and segmented onboarding progress.
- The 2025 redesign changed three things:
  - IA: one scrolling Home plus a Health tab.
  - Thinner, smaller dials (88 pt, 6 pt stroke, butt caps).
  - Translucent 10% cards, gradient-bordered AI/coach cards, hatched tracks, and the floating glass tab bar with a dedicated AI button.

---

## 12. Comparison with ZENO's current "Pulse" theme (read-only review of `noop/StrandiOS/Pulse/PulseTheme.swift` and `PulseComponents.swift`)

| Token | ZENO Pulse today | WHOOP measured | Suggested change |
|---|---|---|---|
| Background | `#101518` → `#000000` | `#283339` → `#13181C` (≈53%) → `#101518` (≈76%) → `#0E1213`; viewport-fixed | Use the slate gradient; black only as the bottom scrim under the tab bar |
| Card | solid `#161C20` + 1 pt hairline border, radius 18 continuous | white 10% overlay, **no border**, radius ≈12 circular, 16 padding | `Color.white.opacity(0.10)`, radius 12, drop the hairline |
| Raised element | `#1F272C` | +10% white over the card | `Color.white.opacity(0.10)` stacked |
| Track | white 12%, 3 pt (thinner than the arc) | white 10%, **same width as the arc** | stroke the track at the arc width |
| Dial | Ø 104, arc 9 pt, round caps | Ø **88**, arc **6 pt**, butt caps with ≈1.2 pt corner rounding | change geometry; drop round caps |
| Section spacing | 22 | ≈40 above section headers, 24 below; 12 grid; 16 stack | adopt |
| Text tertiary | white 58% | white 50% | close enough; keep for contrast |
| Text secondary | white 74% | white 70% | close |
| Label font | caption semibold, tracking 1.1 | Bold UPPERCASE, ≈+1 pt at 11 pt; card titles ≈12 pt Bold +0.7 | use Bold |
| Numerals | SF condensed bold monospaced | small numerals ≈ condensed; **hero score ≈ regular width** | hero score `.width(.standard)` |
| Press style | opacity 0.62 | dial: 40% white disc; rows: **UNCONFIRMED** | dial-specific press disc |
| HR zones | `#7E8A94`, `#0093E7`, `#16C47F`, `#FFB020`, `#FF4A5C` | Z1 ≈ `#A8C0CC`, Z2 ≈ `#3C84A8`, Z3 ≈ green, Z4/Z5 UNCONFIRMED | align Z1–Z3; keep Z4/Z5 as is until confirmed |
| Accent | teal `#00F19F` for interactive chrome | teal = positive/optimal/CTA; **Recovery Blue `#67AEE6` for outline buttons** | add `recoveryBlue` and `negativeOrange #FFA722` |

---

## 13. Public guidance distilled into rules for a premium dark data-dense SwiftUI UI

### 13.1 Apple Human Interface Guidelines (fetched from the HIG JSON, 2026)
- **Dark Mode:**
  - "make sure the contrast ratio between colors is no lower than 4.5:1. For custom foreground and background colors, strive for a contrast ratio of 7:1, especially in small text."
  - "In rare cases, consider using only a dark appearance", which fits an always-dark health app.
  - Test with Increase Contrast and Reduce Transparency both on and off.
  - Prefer semantic or asset-catalogue colours with variants over hard-coded values.
  - Use the system label colour hierarchy (primary/secondary/tertiary). The WHOOP 100/70/50 ladder is the custom equivalent.
- **Typography:**
  - iOS default 17 pt, **minimum 11 pt**. Avoid Ultralight/Thin/Light weights.
  - Support Dynamic Type and keep truncation minimal at large sizes. WHOOP violates this ("RECOMMENDE / D BEDTIME"); ZENO should wrap at word boundaries or scale down.
  - Default ("Large") text styles: Large Title 34/41, Title 1 28/34, Title 2 22/28, Title 3 20/25, Headline 17/22 semibold, Body 17/22, Callout 16/21, Subhead 15/20, Footnote 13/18, Caption 1 12/16, Caption 2 11/13.
  - At xxxLarge, Body is 23 and Caption 2 is 17. This explains the 5kr screenshots.
- **Accessibility:**
  - Text up to 17 pt needs ≥4.5:1 contrast (WCAG AA).
  - Controls default to 44 × 44 pt, minimum 28 × 28.
  - "Convey information with more than color alone": WHOOP adds ▲/▼ and words, and ZENO must too.
  - Respect Reduce Motion: reduce automatic, repeating, zooming and peripheral motion.
- **Charts and charting data:**
  - Keep charts simple and summarise the main message in a title or subtitle.
  - The data is most prominent; axes and gridlines are secondary (light colours).
  - Fixed axis ranges where min/max matter (0–21 strain, 0–100% recovery); dynamic ranges where values vary (HR); avoid a zero baseline for HR.
  - Use familiar tick sequences (0, 7, 14, 21 is acceptable for strain).
  - Combine line + point marks to show trend + individual values (WHOOP's hollow markers).
  - Never require interaction to reveal critical information, and make scrubbing hit areas the whole plot.
  - Provide accessibility labels and Audio Graphs (Swift Charts gives them by default).
  - Align the chart's leading edge with surrounding content.
  - Do not rely solely on colour; add separators between contiguous colour areas (the mini-segment bars use 2 pt gaps).
- **Tab bars (iOS 26 / Liquid Glass):**
  - The tab bar floats above content on Liquid Glass; keep it visible across sections.
  - Use single-word labels, and do not hide or disable tabs.
  - Prefer monochrome tab bars when the content is colourful (WHOOP: white/grey).
  - An accessory can sit inline (`TabViewBottomAccessoryPlacement`). This is a native route for the separate AI button.
- **Motion:**
  - Add motion purposefully; keep feedback brief and precise.
  - Avoid motion on frequent interactions, let people cancel it, and make it optional (pair it with haptics).

### 13.2 Material Design dark theme (useful because WHOOP's surfaces work the same way)
- Use dark grey, not black, for surfaces; express elevation with **semi-transparent white overlays**: 1 dp 5%, 2 dp 7%, 3 dp 8%, 4 dp 9%, 6 dp 11%, 8 dp 12%, 12 dp 14%, 16 dp 15%, 24 dp 16%. WHOOP's single 10% step sits around 6 dp.
- Text emphasis: high 87%, medium 60%, disabled 38% (WHOOP: 100 / 70 / 50).
- Desaturate accents for dark UIs and limit colour to small accents. WHOOP deliberately keeps saturated data colours but uses them only on thin strokes and small text, never on large surfaces.
- Body text on the darkest surface reaches ≥15.8:1.

### 13.3 Refactoring UI (Wathan and Schoger)
- Build hierarchy with **weight and colour**, not size alone. Use 2–3 text colours (primary, secondary, tertiary) and 2 weights (regular/medium plus semibold/bold); avoid weights under 400.
- Do not put grey text on coloured backgrounds. Use white at reduced opacity, or a hand-picked tint of the background hue (this is how WHOOP's gradient pills and teal badges work).
- Use fewer borders: separate with background tone (the 10% cards), spacing, or shadow (rarely, in dark UIs).
- Do not enlarge small icons; enclose them in a shape (WHOOP's 24 pt teal badge squares around a ✓).
- Not every button needs a fill. Keep one primary action per area and make secondary actions outline or text (WHOOP: outline capsule, text CTA with arrow).
- Use accent borders sparingly to add colour (WHOOP's gradient-border insight cards).

### 13.4 Anthropic `frontend-design` skill (github.com/anthropics/skills)
Rules applicable to an app clone:
- **Visual structure is information:** every outline, label, divider and number must encode something.
- **Spend boldness in one place:** here that is the dials and the hero score; keep everything around them quiet.
- **Motion:** use non-user-triggered motion sparingly; "Motion that answers a person's action (opening, expanding, confirming) is welcome when it shows what changed."
- **Quality floor:** respect reduced motion, stay accessible and keep palettes harmonious. Critique your own build from screenshots ("a picture is worth 1000 tokens") and "remove one accessory".
- **Copy:**
  - Use the user's vocabulary.
  - Use active voice, and keep the same name for an action throughout the flow (a button that says "Publish" leads to a toast that says "Published").
  - Errors explain how to fix the problem and do not apologise; an empty screen is an invitation to act.
  - Use sentence case for prose.
- **Conflicts with a WHOOP clone:** the skill warns against all-caps labels and tracked eyebrows as AI "tells". **The brief pins WHOOP's visual direction**, and the skill says "Where the brief pins down a visual direction, follow it exactly". So keep WHOOP's UPPERCASE tracked labels, but only where WHOOP uses them (labels and titles), never in prose.

### 13.5 Vercel Web Interface Guidelines and v0 guidance (framework-agnostic rules that carry over to SwiftUI)
- **Tabular numbers for comparisons** (`.monospacedDigit()`), and redundant status cues (not colour alone).
- **Nested radii:** a child radius ≤ its parent radius, kept concentric. Example: a 12 pt card with 16 pt padding holds nested 8–10 pt controls.
- **Semi-transparent borders** for crisp edges; **interactions increase contrast** (the pressed state is brighter); avoid gradient banding (add dithering or noise if banding shows on the slate gradient).
- **Loading:** a short show-delay (150–300 ms) and a minimum visible time (300–500 ms) for spinners and skeletons; skeletons mirror the final layout exactly.
- **All states designed:** empty, sparse, dense and error. No dead ends.
- **Animations:**
  - Honour reduced motion.
  - Keep them interruptible.
  - Animate only transform and opacity.
  - Animate only when it clarifies cause and effect.
  - Use the correct transform origin, for example a sheet grows from its trigger.
- **Units:** separate numbers from units with a (non-breaking) space ("10 MB"), and use numerals for counts. WHOOP writes "2:15 hrs" this way.
- **Optical alignment:** adjust by ±1 pt when perception beats geometry, for example to centre "%" digits or chevrons.
- **v0 prompting framework (official blog):**
  - Specify the **product surface** (exact components and data), the **context of use** (who, when, what decision) and **constraints and taste** (platform, tone, colour code such as "green on-track, yellow at-risk, red below target").
  - Define the design language up front (palette, radius, spacing, type).
  - v0 grounds itself in real sources: "If a component, prop, or token cannot be verified from the sources, v0 should not use it." The ZENO equivalent: implement only tokens that appear in DESIGN_RULES.md.

---

## 14. Image index (this folder)

| File | What it shows | Source |
|---|---|---|
| `00-whoop-brand-design-guidelines.pdf` | Official developer brand PDF (2023) | developer.whoop.com (URL in 0.6) |
| `01-brand-guidelines-p1..p7.png` | 2560 × 1440 renders of each page: logos, attribution DOs/DON'Ts, typography, colours ×2, data DOs/DON'Ts, usable data | same |
| `10-marketing-three-dials-header.jpg` | 2023 home-dial marketing render (round caps, classic gradient) | WHOOP Locker home-screen article (Contentful) |
| `20-5kr-old-home-2025.png` | Home before 15 Oct 2025: black background variant, classic tab bar, floating "+", "Your Daily Outlook", Today's Activities (red author annotations) | the5krunner 15 Oct 2025 |
| `21-5kr-new-home-oct2025.png` | Home Oct 2025: slate gradient, 3 dials, monitor cards, My Day, Day In Review pill, Tonight's Sleep, floating glass tab bar plus AI button. **P3 raw values; large Dynamic Type; author annotations** | same |
| `22-5kr-action-button-menu.png` | Action (+) popover menu with 5 actions; Daily Outlook pill; Today's Activities buttons | same |
| `23-5kr-blood-pressure-insights-jul2025.png` | BP Insights: segmented arc gauge, W/M segmented control, range chart, "ADD MANUAL READING" | the5krunner 31 Oct 2025 review |
| `24-5kr-insight-card-gradient-border-oct2025.png` | Gradient-border insight card plus gradient CTA text; Recovery Insights row card | same |
| `25-site-video-dial-pressed-state.png` | Pressed sleep dial (40% white disc) | WHOOP site 2025 home video (frame at t = 4.70 s) |
| `26-site-video-dial-to-deepdive-push-transition-strip.jpg` | 12 fps strip: press → push slide into the Sleep deep dive | same |
| `30-mobbin-2023-onboarding-outline-buttons.png` | 2023 onboarding with outline capsule buttons | Mobbin public page |
| `31-mobbin-2023-live-activity-recording.png` | 2023 live activity screen: red recording bar, HR circle, area chart, stat row | same |
| `32-mobbin-2023-list-cards-article-carousel.png` | 2023 list cards with UPPERCASE titles, article carousel, outline CTA | same |
| `33-mobbin-2023-onboarding-progress-segments.png` | Segmented progress bar onboarding | same |
| `40-bureau-oberhaeuser-2020-recovery-zone-dials.jpg` | Recovery zone dials (green/yellow/red) plus the 2020 recovery screen | Behance case study |
| `41-bureau-oberhaeuser-2020-strain-scale.jpg` | Strain scale LIGHT/MODERATE/STRENUOUS/ALL OUT plus the strain screen | same |
| `42-bureau-oberhaeuser-2020-strain-coach.png` | Strain Coach and activity recording | same |
| `43-bureau-oberhaeuser-2020-trends-charts.jpg` | Overview/Strain/Recovery/Sleep weekly trend charts | same |
| `44-bureau-oberhaeuser-2020-sleep-screens.jpg` | Sleep Coach, sleep stats, sleep performance (2020) | same |
| `45-bureau-oberhaeuser-2020-profile.jpg` | Profile and performance assessments | same |

Also measured in place, in other agents' folders:
- `../images/appstore/ios69-01..10.png`: the default text-size reference.
- `../images/reviews/04..07.png`: Customize Dashboard, home scroll with Stress chart, Strain & Recovery chart, dashboard tiles.
- `../images/whoop-site/02-home-screen-video.mp4`, `03..10` frames, `11-whats-new-2026-header-IMG_4459.png` (2026 component composite).

---

## 15. Open questions and UNCONFIRMED items
1. Why the pre-Oct-2025 screenshot is pure black with deeper hues: an older build or an accessibility variant?
2. Exact semantics of the strain dial's grey band and white tick (target window vs current-target marker).
3. HR zone 4/5 colours and sleep-stage (hypnogram) colours in the current build.
4. Default-size heights of dashboard tiles and customise rows. They were measured only at large Dynamic Type (60 / 56 pt).
5. Whether dials animate (sweep or count-up) on load, and any haptics.
6. Coach button corner radius; Action-menu animation; activity badge radius.
7. Empty, error and loading states; light mode (never seen, and probably absent).
8. Meaning of the 3-dash indicator under the Sleep deep-dive score.
