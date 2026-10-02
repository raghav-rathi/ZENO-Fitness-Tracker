# ZENO design rules: a WHOOP-matched dark UI for SwiftUI

This is the token sheet to build from. Every value was measured from public WHOOP material: the developer brand PDF, App Store screenshots, real-device screenshots and the official site video. Evidence, method and caveats are in `notes/design-language.md`. Values marked **UNCONFIRMED** are best guesses.

Reference device: 393 × 852 pt (iPhone 15/16 Pro). Colours are sRGB hex; `Color(hex:)` already exists in the app.

## 0. Guardrails

- **Do not ship WHOOP's assets.** That means no WHOOP wordmark, "W" puck/monogram, "WHOOP LIFE" lock-up, icons or illustrations (3D heart, WHOOP Age orb), and no Proxima Nova or DIN Pro fonts.
  - Wherever WHOOP shows its wordmark (above the dials, inside the deep-dive ring, end of feed, AI button), use ZENO's own mark.
- **Use SF Pro.**
  - Words: SF Pro (default width).
  - Small numerals: SF Pro Bold `.width(.condensed)` + `.monospacedDigit()`.
  - Hero score: SF Pro Bold, standard width.
  - DIN Alternate ships with iOS but is deliberately not used, so ZENO stays visually distinct from WHOOP's DINPro.
- **The palette hexes are from WHOOP's public developer guidelines.** This build is private, which is fine. Do not publish it as WHOOP-branded.
- **Copy the structure and proportions, and use original symbols** (SF Symbols).

## 1. Colour tokens

### 1.1 Page background
The background is a **viewport-fixed** vertical gradient. Put it behind the `ScrollView`, never inside it.

| Stop | 0.00 | 0.23 | 0.53 | 0.76 | 1.00 |
|---|---|---|---|---|---|
| colour | `#283339` | `#1E262B` | `#13181C` | `#101518` | `#0E1213` |

- Tab-root screens add a **bottom scrim**: clear → `#000000` at 95% over the 28 pt above the floating tab bar, and solid black below the bar.
- Never use pure black anywhere else.

### 1.2 Surfaces: white overlays on top of the gradient
Do not use solid greys. Overlays let cards lighten near the top exactly as WHOOP's do.

| Token | Value | Use |
|---|---|---|
| `surfaceCard` | `white 10%` | cards, tiles, list rows, dial track, dividers, chart "today" band |
| `surfaceNested` | `white 10%` on top of a card (≈20% total) | in-card buttons ("SET ALARM", "ADD ACTIVITY"), selected segment |
| `surfaceWell` | `black 50%` | legend wells, segmented-control trough |
| `lineGrid` | `white 5%` (on a card) / `white 8%` (on the page) | chart gridlines, 1 pt |
| `lineDash` | `white 25%` | dashed connectors, secondary series lines |
| `bandTarget` | `white 27%` | strain-target band on the dial |
| `pressDisc` | `white 40%` | pressed dial interior |

Solid fallbacks, only if overlays are impossible: card ≈ `#2D3236` (top third), `#2B2F33` (middle), `#292C2E` (lower).

### 1.3 Text and icons
| Token | Value |
|---|---|
| `textPrimary` | `#FFFFFF` |
| `textButton` | white 85% |
| `textSecondary` | **white 70%** |
| `textTertiary` | **white 50%** (chevrons, baselines, axis labels, inactive tabs, section labels) |
| `textDisabled` | white 40% |

### 1.4 Semantic data colours
One meaning per hue. Use them only for data, never for large surfaces.

| Token | Hex | Meaning |
|---|---|---|
| `recoveryHigh` | `#16EC06` | Recovery 67–100% |
| `recoveryMid` | `#FFDE00` | Recovery 34–66% |
| `recoveryLow` | `#FF0026` | Recovery 0–33% (dial/arc). For **text** use `#FF4A5C`, which passes 4.5:1. |
| `strain` | `#0093E7` | Strain, activities, workout badges |
| `sleep` | `#7BA1BB` | Sleep, hours of sleep, sleep badges |
| `recoveryBlue` | `#67AEE6` | Neutral recovery data; **outline buttons** |
| `positive` | `#00F19F` | Favourable trend ▲, "Optimal", "Within range", positive impact bars, primary CTA |
| `negative` | `#FFA722` | Unfavourable trend, "Poor", "Alarm off", negative impact bars, "Highest" |
| `neutralTrend` | white 50% | No meaningful change (grey ▲ or ●), "Sufficient" (`#848586`) |
| `positiveTint` | `#00F19F` at 16% on the card | status badge squares |
| `aiGradient` | `#8371FF` → `#6E9AFF` → `#5FB5FE` | AI/coach CTA text; border at ≈55% opacity (`#4D3D8C` → `#31738C`), 1.5 pt |
| `pillMorning` | `#69655A` → `#283B45` (horizontal) | "Daily Outlook" pill |
| `pillEvening` | `#2D284D` → `#293F52` (horizontal) | "Day in Review" pill |
| `stressScale` | `#67AEE6` → `#00F19F` → `#FFDE00` → `#FFA722` | stress gauge and stress line |
| `zone1`, `zone2`, `zone3` | `#A8C0CC`, `#3C84A8`, green | HR zones. Approximate; **zones 4–5 UNCONFIRMED** |

## 2. Typography (SF Pro, matched to WHOOP's cap heights at default Dynamic Type)

| Token | Size | Weight | Width | Case | Tracking | Colour | Dynamic Type |
|---|---|---|---|---|---|---|---|
| `heroScore` | 58 | Bold | standard | – | 0 | primary | fixed |
| `heroUnit` (the %) | 32 | Bold | standard | – | 0 | primary | fixed |
| `dialValue` | 28 | Bold | **condensed** + monospacedDigit | – | 0 | primary | fixed |
| `dialUnit` (the %) | 20 | Bold | condensed | – | 0 | primary | fixed |
| `sectionTitle` ("My Day") | 20 | Semibold | standard | Title Case | 0 | primary | relative to `.title3` |
| `subsectionTitle` ("Today's Activities") | 17 | Semibold | standard | Title Case | 0 | primary | `.headline` |
| `tileValue` (dashboard tiles) | 22 (**UNCONFIRMED**) | Bold | condensed + mono | – | 0 | primary | `.title2` |
| `rowValue` (contributors) | 17 | Bold | condensed + mono | – | 0 | primary | `.headline` |
| `body` (insights, coach) | 14 | Medium | standard | sentence | 0 | primary or secondary | `.subheadline` |
| `pillTitle` ("Your Daily Outlook") | 14 | Semibold | standard | Title Case | 0 | primary | `.subheadline` |
| `cardTitle` ("HEALTH MONITOR") | 12 | Bold | standard | UPPER | +0.7 | primary | `.caption` |
| `secondary` ("5/5 Metrics", "4:31pm") | 12 | Semibold | standard | sentence | 0 | secondary | `.caption` |
| `navTitle` ("TODAY") | 12 | Bold | standard | UPPER | +1.2 | primary | `.caption` |
| `label` (dial labels, row labels, CTA, "EDIT", status words) | **11** | Bold | standard | UPPER | **+1.0** (≈10%) | primary, or semantic for status | `.caption2` |
| `baseline` (30-day value under a metric) | 13–15 | Bold | condensed + mono | – | 0 | tertiary | `.footnote` |
| `axis` | 11 | Bold | condensed + mono | – | 0 | tertiary (or semantic on dual axes) | `.caption2` |
| `tabLabel` | 10.5–11 | Medium | standard | Title Case | 0 | white / tertiary | `.caption2` |

Rules:
- **Words.** Use bold UPPERCASE with tracking for labels and titles, Title Case semibold for section headers, and sentence case medium for prose. Never write prose in all caps.
- **Numbers.** Draw numbers bold and condensed, with digits from `.monospacedDigit()`. The hero score is the only standard-width number. Set units (`%`, `hrs`, `mmHg`, small seconds) **smaller** and baseline-aligned with the digits:
  - `%` on a dial is 0.72× the value size.
  - `%` on the hero score is 0.55×.
  - Text units are tertiary colour.
- **Dynamic Type and wrapping.**
  - Dials and hero numbers stay fixed; all other text scales.
  - Cards grow with their text. Cap growth with `.dynamicTypeSize(...DynamicTypeSize.accessibility2)` where layouts break.
  - Never break a word mid-wrap (WHOOP does: "RECOMMENDE / D BEDTIME"). Use `.lineLimit(2)` with `.minimumScaleFactor(0.85)`.
- **Minimum size is 11 pt.** WHOOP's status words are about 10 pt; ZENO uses 11.

```swift
extension Font {
    static func zNumeral(_ size: CGFloat, hero: Bool = false) -> Font {
        .system(size: size, weight: .bold).width(hero ? .standard : .condensed).monospacedDigit()
    }
}
// UPPERCASE label that scales with Dynamic Type
struct ZLabel: View {
    let text: String
    var color: Color = .white
    @ScaledMetric(relativeTo: .caption2) private var size: CGFloat = 11
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .bold))
            .tracking(size * 0.09)
            .foregroundStyle(color)
    }
}
```

## 3. Spacing and layout

- **Scale:** 4 · 8 · 12 · 16 · 24 · 32 · 40.
- **Page margin:** 16 on both sides. Cards span the full width minus margins.
- **Grid gap:** 12 between side-by-side cards and between stacked tiles or rows.
- **Stack gap:** 16 between different cards inside one section.
- **Card padding:** 16 on all sides. The title starts at the card's 16 pt inset.
- **Sections:** 40 above a section header (previous block → header cap top), 24 from header baseline → first card. A header may carry a right accessory: a 36 pt white "+" square, or "CUSTOMIZE ✎".
- **Home dial row:** three 88 pt dials with `HStack(spacing: 33)` (side margins ≈31.5), 24 pt below the wordmark slot. Labels sit 12 pt under the rings, and about 30–40 pt separates the labels from the first card.
- **Contributor rows** (deep dive): 53 pt pitch, 1 pt `surfaceCard` dividers inset 16 pt. Icon at 20 pt from the card edge, label at 49 pt from the card edge. The value and its trend glyph are right-aligned, and the glyph ends about 22 pt from the card edge, just inside the divider's 16 pt inset.
- **Gradient pill row:** 48 pt tall.
- **Floating tab bar:**
  - Glass capsule, 64 pt tall, 12 pt from the left edge, about 293 pt wide. Use `.glassEffect` / iOS 26 material if available, otherwise `#252A30` → `#191E23` at 92%.
  - Separate 64 × 64 AI button, 12 pt gap, 12 pt from the right edge.
  - Selected item: white plus a soft white-10% blob; unselected items are tertiary.
- **Hit targets:** ≥ 44 × 44 pt. The whole card is tappable, not just the chevron.

## 4. Radii

Nest radii: a child radius is ≤ its parent's, and nested shapes stay concentric.

| Token | pt | Use |
|---|---|---|
| `rCard` | **12** (use `style: .circular`, which matches WHOOP's measured arc) | cards, tiles, rows, insight cards, 48 pt pills, 36 pt "+" square, date pill |
| `rControl` | 10 | nested buttons inside cards, segmented control |
| `rWell` | 8 | legend wells, small chips, activity score badges (**UNCONFIRMED**) |
| `rBadge` | 4 | 24 pt status squares |
| `rMenu` | 20 | action-menu popover (approximate) |
| capsule | h/2 | outline primary button, tab-bar capsule |

## 5. Dials and rings

| Spec | Home dial | Deep-dive ring | Sticky mini ring |
|---|---|---|---|
| Outer diameter | **88** | **260** | 24 |
| Stroke (arc = track) | **6** (6.8%) | **15** (5.9%) | 2 |
| Track | `surfaceCard` (white 10%) | same | same |
| Start / direction | 12 o'clock, clockwise | same | same |
| Full circle = | 100% (Sleep, Recovery) / **21** (Strain) | same | same |
| Caps | **butt**, with ≈1/5-stroke corner rounding (≈1.2 pt) | butt, ≈3 pt corner rounding | butt |
| Centre content | `dialValue` 28 + `dialUnit` 20 | small brand mark slot (ZENO), then `heroScore` 58 + `heroUnit` 32, then `label` ("RECOVERY") | – |
| Below | `label` + tertiary "›", 12 pt gap | – | inline label |

Colours: Recovery takes its zone colour; Sleep is `sleep`; Strain is `strain`.

**Strain target overlay:** draw `bandTarget` from the current strain to the target-range top, and a 1 pt white tick (full stroke height) at the target. WHOOP's exact semantics are UNCONFIRMED; ZENO defines it as band = optimal range, tick = target.

**Pressed state:** fill the ring interior with `pressDisc` (white 40%) while touched, then push the deep dive.

**Deep-dive header:** "‹" back, UPPERCASE `navTitle` (e.g. "TODAY"), ⓘ button. The callout card under the ring attaches to it with a 15 × 7 pt pointer triangle.

```swift
struct ZDial: View {
    var progress: Double            // 0...1 (strain = value / 21)
    var color: Color
    var diameter: CGFloat = 88
    var lineWidth: CGFloat = 6
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.10), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)                 // outer edge lands exactly on `diameter`
        .frame(width: diameter, height: diameter)
    }
}
```

`.butt` reproduces WHOOP within about 1 pt. For the exact rounded corners, fill an annular-sector `Shape` and stroke the same path with `lineJoin: .round` at 2 × the corner radius, inset by that radius.

## 6. Components (quick specs)

- **Card:** `RoundedRectangle(cornerRadius: 12, style: .circular).fill(.white.opacity(0.10))`. No border and no shadow.
  - Exception: the deep-dive callout card. Its fill is a radial glow centred on the pointer, with no flat fill underneath:
    - `RadialGradient(colors: [.white.opacity(0.10), .white.opacity(0.0)], center: .top, startRadius: 0, endRadius: ≈220)`.
    - Measured falloff: ≈10% at the top centre, 2–3% at the top corners, ≈4% at 130 pt down, ≈0% by 190 pt.
    - It has a 1 pt top-lit stroke (white ≈7% near the pointer, fading to 0%).
- **Monitor card:** UPPERCASE `cardTitle` + "›". Below it, a 24 pt `positiveTint` square holding a ✓ or a number (Bold, `positive`), then a status `label` in a semantic colour over a `secondary` line.
- **Metric tile:** line icon (tertiary) + UPPERCASE `label`. On the right, `tileValue` + trend triangle (▲/▼, 6 pt, `positive`/`negative`/tertiary), with the `baseline` in tertiary underneath.
- **Contributor row:** icon + UPPERCASE label + `rowValue` + trend glyph. Rows are separated by dividers. The legend well at the bottom reads "▲▼ Today vs. prior 30 days" ("Today" in primary semibold, the rest secondary).
- **Insight card:** transparent fill, 1.5 pt `aiGradient` border, 16 padding, `body` text, and a CTA as an UPPERCASE `label` with gradient text + "→". **Only AI/coach content uses the gradient.**
- **Buttons:**
  - Primary on dark: outline capsule, 2 pt `recoveryBlue` stroke, `recoveryBlue` text, `label` at 15–17 pt.
  - In-card: `surfaceNested`, `rControl`, icon + UPPERCASE text in `textButton`.
  - Emphasised one-off: white fill, black UPPERCASE text, `rControl`.
  - Text CTA: UPPERCASE + "→".
- **Gradient pill:** 48 pt, `pillMorning` or `pillEvening`, line icon + `pillTitle` + "›".
- **Activity row:** a coloured score badge in the activity colour (white glyph + white numeral), UPPERCASE name, and right-aligned start/end times (tertiary) with a 2 pt vertical bar in the activity colour.
- **Hatched track:** 45° lines, 1 pt wide, every 4 pt, white 7%. Use it as the empty part of zone bars and impact bars.
- **Mini segments** (Poor / Sufficient / Optimal): 3 × (20 × 4 pt), gap 2. The active segment is coloured; inactive segments are white 12%.
- **Diverging impact bar:** a 4 pt white centre dot; `positive` extends right and `negative` extends left, on a hatched track. The value text takes the bar's colour.
- **Chips:**
  - "BETA", "NEW": `rWell`, white 10–20% fill or a 1 pt `recoveryBlue` outline, UPPERCASE `label`.
  - Semantic chip: the colour at 16% fill with text in the colour.

## 7. Charts (Swift Charts)

- **Plot area:** inside a card with 16 padding. The UPPERCASE title sits at the top-left and ⓘ (tertiary) at the top-right.
- **Gridlines:** horizontal only, 1 pt `lineGrid`, at round ticks: strain 0/7/14/21, recovery 0/33/66/100, stress 0–3, HR 30/50/70/90. There are no vertical gridlines; use bands for vertical emphasis.
- **Axes:** `axis` style in tertiary. On dual-axis charts, colour each axis label by its series: strain-blue left; recovery right, coloured by zone.
- **Ranges:**
  - Fixed: strain 0–21, recovery and sleep 0–100%.
  - Dynamic: heart rate and HRV. Do not start these at zero.
- **Lines:** 2 pt, `.interpolationMethod(.linear)`.
  - Primary series line: series colour at 50% opacity.
  - Markers: hollow circles, 8–9 pt, with a 2 pt stroke in the semantic colour and a card-coloured fill.
  - Value labels: Bold condensed, coloured, placed above or below so they don't collide.
  - Secondary series line: `lineDash` (white 25%), with markers coloured per point (zone colours).
- **Today:** a `RectangleMark` band in white 10% (radius 6) behind the current x, and a primary-colour x label. Other x labels are tertiary, two lines ("Mon" over "8").
- **Area charts** (sleep HR): a 1.5 pt line plus a vertical gradient from the series colour at 35% to 0%. Mark sleep start and end with dashed vertical rules, each with a dot at the bottom.
- **Value-coloured lines** (stress): `LineMark(...).foregroundStyle(.linearGradient(stressScale, startPoint: .bottom, endPoint: .top))`, so colour follows the y value.
- **Activity periods:** `RectangleMark` in the series colour at 12%, with a 3 pt bar along the top gridline. Glyphs go above the plot.
- **Now:** a dotted 1 pt vertical rule (white 70%) ending in a 4 pt dot. The current time label is primary Bold.
- **Missing data:** skip the point and connect the line across the gap. Never plot zeros for missing days.
- **Accessibility:** give every chart a title and a one-line summary, `.accessibilityLabel` on marks, and tap-or-scrub across the whole plot. Never require interaction to see the key number.

## 8. Motion

- **Press feedback:** instant on touch-down (dial: white 40% disc; rows: content to 70% opacity), released over 0.15 s ease-out. Add `.sensoryFeedback(.selection, …)` on navigation taps (WHOOP's haptics are UNCONFIRMED).
- **Navigation:** native `NavigationStack` push into deep dives. WHOOP's is a standard slide of about 0.4 s. Don't invent zoom transitions.
- **Data changes:**
  - Dial arcs animate from the old value to the new one over 0.6–0.8 s ease-out, **only when the value changes** (not on every appear). Whether WHOOP sweeps its dials is UNCONFIRMED.
  - Numbers use `.contentTransition(.numericText())`.
- **Menus and sheets:** use the system presentations. The action menu scales and fades from its "+" trigger (anchor `.topTrailing`, 0.2 s).
- **Background:** the gradient never moves. No parallax, no looping or ambient animation, no shimmer except skeletons.
- **Loading:** skeleton blocks in white 10% that mirror the final layout. Wait 200 ms before showing them, then keep them visible for at least 400 ms.
- **Reduce Motion:** dials jump straight to their value, there is no numeric roll, and every transition becomes a cross-fade.
- **Interruptibility:** every animation can be interrupted, and you animate only opacity, transform and trim.

## 9. Do and don't

**Do**
- Make the number the hero: big bold numeral, small tracked label, the score colour on the arc only.
- Keep each hue to a single meaning across every screen: green/yellow/red only for recovery bands; blue for strain/activities; slate for sleep; teal for good/optimal; orange for unfavourable.
- Pair colour with a shape or word: ▲/▼, ●, "WITHIN RANGE", "Poor/Sufficient/Optimal".
- Show context for every metric: today's value, the 30-day baseline in grey underneath, and a trend triangle.
- Build depth only with white overlays (10% card, +10% nested) over the fixed slate gradient.
- Use title-case section headers to break the feed into "My Day / My Plan / My Dashboard"-style groups. Use UPPERCASE card titles inside them.
- Keep layouts aligned to the 16 pt margin and the 12/16 pt gaps, with whole cards tappable and 44 pt targets.
- Support Dynamic Type for text and keep dials fixed; check at xxxLarge (WHOOP's own large-text bugs show what to avoid).
- Test contrast: body text ≥ 4.5:1 on the card. Use `#FF4A5C` for red text.

**Don't**
- Don't use WHOOP's wordmark, monogram, fonts, icons or illustrations.
- Don't use pure black backgrounds (except under the tab bar), solid grey cards, borders on home cards, or drop shadows.
- Don't use round caps or thin tracks on the dials. The track has the same width as the arc.
- Don't paint large areas with saturated data colours. Gradients are only for the time-of-day pills, AI/coach accents and the stress scale.
- Don't put grey text on coloured fills; use white at 70% instead.
- Don't use more than one emphasised CTA per card, or all-caps prose, or text below 11 pt.
- Don't add gratuitous animation: no looping, no parallax, no animating every appear.
- Don't truncate labels mid-word, and don't plot missing days as zero.

## 10. Verification checklist (run against the reference screenshots)

1. Screenshot ZENO Home on an iPhone 16 Pro simulator (393 pt).
   - Dial outer diameter = 264 px @3x.
   - Stroke = 18 px.
   - Dial centres at x = 226 / 589 / 952 px.
   - Cards at x = 48 → 1130 px.
2. Sample the background at y = 0 (≈ `#283339`), 450 pt (≈ `#13181C`) and 650 pt (≈ `#101518`). Check that cards = background + 10% white.
3. Compare type: the dial label cap height should be about 22 px @3x, and the "My Day"-equivalent cap about 42 px @3x, at default Dynamic Type.
4. Compare with `whoop-reference/images/appstore/ios69-01..04` (default size) and `images/design-language/21-…` (geometry). Note that `21` is Display-P3 without a profile and was captured at large text, so check only its geometry.
