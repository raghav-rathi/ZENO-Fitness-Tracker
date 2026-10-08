# ZENO UI research

The research behind ZENO's WHOOP-style iPhone interface. It is a study of the current WHOOP app's screen
structure, arrangement and visual language, from public sources, and of how ZENO's data maps onto it.

| File | What it is |
|---|---|
| [WHOOP_UI_SPEC.md](WHOOP_UI_SPEC.md) | Screen-by-screen blueprint: navigation, design tokens, every screen's section order, components and states |
| [METRIC_COMPARISON.md](METRIC_COMPARISON.md) | Every WHOOP metric and feature against ZENO: have, partial, buildable offline, or not possible, plus ZENO's extras and the build order |
| [DESIGN_RULES.md](DESIGN_RULES.md) | Token sheet for SwiftUI implementers: colours, type scale, spacing, radii, dial and chart geometry, motion |
| [STEPS.md](STEPS.md) | How ZENO counts steps: the phone-side sources, the hour-by-hour fill from the strap's motion, and the tools that check it |
| [notes/](notes/) | The research notes the spec was synthesised from |

**Reference images are not in this repository.** The spec and notes cite about 970 screenshots (WHOOP's
App Store listing, its website and blog, help pages and independent reviews) by path under
`whoop-reference/images/`, a private folder kept on the development Mac. They are WHOOP's copyrighted
material, so they stay local.

**Guardrails:** ZENO copies structure, order, proportions and behaviour, never WHOOP's brand assets. No
WHOOP logo, illustrations, badge art or licensed fonts (Proxima Nova, DIN); SF Pro and SF Symbols
instead. See the spec's section 0. Not affiliated with WHOOP, Inc.
